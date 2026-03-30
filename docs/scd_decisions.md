# SCD Type Decisions — FinanzWerk

## Decision table

| Entity | SCD Type | Reason |
|---|---|---|
| Service display names | Type 1 | Typo corrections and rebranding — no regulatory significance, old name has no audit value |
| Vendor risk scores (source) | Type 3 | DORA needs to see current vs. previous in a single query for red-flag detection; full history is in the Data Vault satellite |
| Vendor register (warehouse) | Type 2 | Full history required — fact rows need to point to the vendor state that existed at incident time, not the current state |
| Compliance configuration | Type 4 | Auditors need to know which thresholds were active during any given incident, but day-to-day lookups should be fast without filtering `is_current` |

## Why not Type 2 for everything

Type 2 is the most complete option and the safest default for compliance data, but it has a real query cost: every query that needs current data must filter `WHERE valid_to IS NULL` or `WHERE is_current`. At low scale that's fine. At high scale, or when the dimension is read hundreds of times per minute by a dashboard, that filter adds up.

Type 4 solves this by splitting the concern: `config_current` is a single-row-per-key table with no filtering needed, `config_history` handles the audit trail separately. The write path is slightly more complex (`update_config` writes to both tables), but the read paths are both simple.

## Type 3 limitations

`previous_risk_score` on `vendors` only tracks one change. If a vendor goes 6 → 8 → 5, after the second change `previous_risk_score = 8` and the original 6 is gone. That's intentional for this use case — the DORA red-flag query (`risk_score - previous_risk_score > 2`) only cares about the most recent movement. Deep history lives in the Data Vault satellite.

If you ever need to answer "what was this vendor's risk score 6 months ago", use the Data Vault, not the Type 3 columns.

## Point-in-time config reconstruction

Query 16 answers: "what were our compliance thresholds during incident X?"

```sql
SELECT DISTINCT ON (key) key, value, changed_at
FROM compliance.config_history
WHERE changed_at <= '<incident_occurred_at>'
ORDER BY key, changed_at DESC;
```

`DISTINCT ON (key)` picks the most recent row per key at or before the target timestamp. This pattern works for any point-in-time question against an append-only history table.

## Interview reference

When asked "how do you handle slowly changing dimensions":
1. Lead with the question back: "what's the business requirement — do you need history, current-vs-previous comparison, or just the latest value?"
2. Type 1 if history has no value (corrections, display labels)
3. Type 2 if you need full point-in-time accuracy (regulatory, financial reporting)
4. Type 3 if you only need one level of before/after (trend detection, alerts)
5. Type 4 if you need both fast current lookups and a separate audit trail
6. Data Vault if the data comes from multiple sources and changes frequently — satellites give you Type 2 history with cleaner multi-source handling
