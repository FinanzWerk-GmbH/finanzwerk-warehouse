# Performance Notes — Window Functions & Index Optimisation

## Setup

Run migrations in order before measuring:

```bash
cd finanzwerk-warehouse
python3 migrate.py           # applies 001, 002, 003 in sequence
```

---

## EXPLAIN ANALYZE — Rolling 30-Day Query (before indexes)

Run **before** applying `002_indexes.sql`:

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    incident_id,
    service_name,
    occurred_at,
    severity,
    clients_affected_count,
    COUNT(*) OVER (
        PARTITION BY service_name
        ORDER BY occurred_at
        RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
    ) AS rolling_30d_count
FROM ict_incidents
ORDER BY service_name, occurred_at;
```

**Sample output (fill in your real numbers after running):**

```
WindowAgg  (cost=6842.74..7342.74 rows=50000 width=72)
           (actual time=148.231..189.447 rows=50000 loops=1)
  ->  Sort  (cost=6842.74..6967.74 rows=50000 width=64)
            (actual time=148.210..157.623 rows=50000 loops=1)
        Sort Key: service_name, occurred_at
        Sort Method: external merge  Disk: 4256kB
        ->  Seq Scan on ict_incidents
                       (cost=0.00..1347.00 rows=50000 width=64)
                       (actual time=0.018..31.004 rows=50000 loops=1)
Planning Time:   0.3 ms
Execution Time: TODO ms          ← replace with real value
```

**What to note:** `Seq Scan` reads every row. The `Sort` may spill to disk
(`external merge`) for large tables. Window aggregate runs on top of the sort.

---

## EXPLAIN ANALYZE — Rolling 30-Day Query (after indexes)

After `002_indexes.sql` is applied the planner switches to an index scan
because `idx_ict_incidents_service_occurred` on `(service_name, occurred_at)`
already stores rows in the order the window function needs.

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    incident_id,
    service_name,
    occurred_at,
    severity,
    clients_affected_count,
    COUNT(*) OVER (
        PARTITION BY service_name
        ORDER BY occurred_at
        RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
    ) AS rolling_30d_count
FROM ict_incidents
ORDER BY service_name, occurred_at;
```

**Sample output:**

```
WindowAgg  (cost=0.42..2097.42 rows=50000 width=72)
           (actual time=0.063..18.914 rows=50000 loops=1)
  ->  Index Scan using idx_ict_incidents_service_occurred on ict_incidents
                       (cost=0.42..1597.42 rows=50000 width=64)
                       (actual time=0.041..8.372 rows=50000 loops=1)
Planning Time:   0.5 ms
Execution Time: TODO ms          ← replace with real value
```

**What changed:** `Seq Scan` → `Index Scan`. The sort step disappears entirely
because the index already provides rows in `(service_name, occurred_at)` order.

---

## Before / After Timing Summary

| Metric                  | Before index | After index | Improvement |
|-------------------------|-------------|-------------|-------------|
| Execution time          | TODO ms     | TODO ms     | TODO×       |
| Seq Scan / Index Scan   | Seq Scan    | Index Scan  | —           |
| Sort step               | Yes (disk)  | Eliminated  | —           |

> Fill in the TODO cells from your `EXPLAIN ANALYZE` output.
> On ~50 k rows expect roughly 150 ms → 15 ms (≈10× improvement).
> On 10 M rows the gap widens to several seconds vs. single-digit milliseconds.

---

## Partial Index — NIS2 High/Critical Filter

`idx_ict_incidents_occurred_high_critical` is only ~30–40 % the size of a full
`occurred_at` index (assuming high/critical are a minority of rows). Verify it
is picked up by query 12:

```sql
EXPLAIN (ANALYZE, FORMAT TEXT)
SELECT i.incident_id, i.occurred_at, n.sent_at
FROM ict_incidents i
LEFT JOIN notification_log n ON n.incident_id = i.incident_id
WHERE i.severity IN ('high', 'critical')
ORDER BY i.occurred_at DESC;
```

Look for `Index Scan using idx_ict_incidents_occurred_high_critical`.

---

## Materialized View — Staleness vs. Performance

```sql
-- Read (sub-millisecond — pre-computed rows, no live query):
SELECT * FROM compliance.mv_quarterly_summary;

-- Refresh (runs the full CTE chain, locks the view momentarily):
REFRESH MATERIALIZED VIEW compliance.mv_quarterly_summary;

-- Refresh without blocking reads (requires the unique index on vendor_id):
REFRESH MATERIALIZED VIEW CONCURRENTLY compliance.mv_quarterly_summary;
```

| Approach              | Read latency | Data freshness        | Lock behaviour        |
|-----------------------|--------------|-----------------------|-----------------------|
| Live query (13)       | TODO ms      | Real-time             | No lock               |
| Materialized view     | < 1 ms       | As of last REFRESH    | Full lock (non-CONCURRENTLY) |
| CONCURRENTLY refresh  | < 1 ms       | As of last REFRESH    | Reads allowed during refresh |

**Decision rule:** use the materialized view for dashboards and scheduled
reports that can tolerate data up to 24 h old. Use the live CTE query when
regulators or auditors need point-in-time accuracy.
