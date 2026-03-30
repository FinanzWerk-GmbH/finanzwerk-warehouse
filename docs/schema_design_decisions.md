# Schema Design Decisions — Project 4

## Why two modelling approaches

FinanzWerk uses both Data Vault and star schema because the data falls into two categories with different requirements.

**Vendor register → Data Vault**

Vendors change. A vendor changes their name, gets acquired, updates their contract, or adjusts their risk classification. DORA requires you to prove what you knew about a vendor at the time of an incident — "we rated this vendor as medium risk when the incident occurred" must be auditable even if that vendor is now rated high risk. Data Vault's append-only satellite captures every state without ever overwriting or deleting history.

The three-table structure also handles multi-source loading well. If vendor data arrives from two different source systems, each hub row tracks `record_source` and satellites can be added per source independently without conflicts.

**Incident reporting → Star schema**

ICT incidents don't change after they're recorded. Once an incident is logged with a severity, duration, and client count, that's the historical fact. There's no "incident attribute history" to preserve. The priority is query speed and BI-tool compatibility — compliance officers need fast slices by quarter, vendor, and service, not a full audit log.

The star schema delivers that: `dim_date.quarter` and `dim_vendor.vendor_name` are a simple JOIN away, no lateral queries or MAX(load_timestamp) subqueries needed.

## The cost of Data Vault queries

To read current vendor details from the Data Vault:

```sql
SELECT s.vendor_name, s.risk_score
FROM compliance.hub_vendor h
JOIN compliance.sat_vendor_details s
    ON s.hub_vendor_key = h.hub_vendor_key
   AND s.is_current
WHERE h.vendor_id = '<uuid>';
```

To read a vendor's state as of a specific date (the point-in-time query):

```sql
SELECT s.vendor_name, s.risk_score
FROM compliance.hub_vendor h
JOIN compliance.sat_vendor_details s
    ON s.hub_vendor_key = h.hub_vendor_key
WHERE h.vendor_id = '<uuid>'
  AND s.load_timestamp = (
      SELECT MAX(load_timestamp)
      FROM compliance.sat_vendor_details
      WHERE hub_vendor_key = h.hub_vendor_key
        AND load_timestamp <= '<incident_occurred_at>'
  );
```

This is more complex than a star schema join. The complexity is the tradeoff — it's the price of the audit trail.

## SCD Type 2 in dim_vendor

The star schema `dim_vendor` uses SCD Type 2 (Slowly Changing Dimension): when a vendor changes, the old row gets a `valid_to` timestamp and a new row is inserted with `valid_to = NULL`. The fact table's `vendor_key` always points to the specific historical snapshot of the vendor that existed when the incident occurred.

This means a report can correctly say "this incident happened while Vendor X had a risk score of 6.0" even if Vendor X is now rated 8.5.

The partial unique index `WHERE valid_to IS NULL` enforces that only one current row exists per `vendor_id`.

## Surrogate keys

`vendor_key` (SERIAL integer) in the fact table instead of `vendor_id` (UUID):

- Integer joins are faster than UUID joins, especially at scale
- Decouples the warehouse from source system ID changes — if the source system re-generates a vendor's UUID, only the dimension ETL needs to handle it, not every downstream table
- Enables SCD Type 2 naturally — the same `vendor_id` can map to multiple `vendor_key` values (one per historical version)

## Comparing query 13 vs query 14

Query 13 (CTE chain on raw tables): ~50 lines, four named steps, CASE expressions, date_trunc() arithmetic.

Query 14 (star schema): ~25 lines, no CTEs, no CASE expressions, `WHERE dd.quarter = ...` instead of date range arithmetic.

The complexity didn't disappear — it moved from the query into the ETL layer (`load_star_schema.py`). The `is_major_incident` boolean is computed once on load; every report that needs it reads a pre-computed column instead of re-evaluating the DORA rule each time.

This is the fundamental star schema trade-off: queries become dumber (faster, simpler) because the schema becomes smarter (requires ETL logic and a load step).
