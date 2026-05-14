# ClickHouse vs PostgreSQL — Query Timing Comparison

## Setup

Both databases loaded with the same `ict_incidents` dataset.
Queries run against the quarterly DORA report (Q13 / `quarterly_report.sql`).
Hardware: Minikube single-node (4 vCPU, 8 GB RAM, SSD-backed storage).

---

## The query

Quarterly DORA report: group incidents by year/quarter, compute major incident count,
notification compliance %, average critical duration, client impact, vendor concentration.
Uses two CTEs + a join. In PostgreSQL it is query 13; in ClickHouse it is `quarterly_report.sql`.

---

## Results

| Row count | PostgreSQL (ms) | ClickHouse (ms) | Speedup |
|-----------|-----------------|-----------------|---------|
| 10 K      | ~18             | ~12             | 1.5×    |
| 100 K     | ~140            | ~25             | 5.6×    |
| 1 M       | ~1 400          | ~80             | 17.5×   |
| 10 M      | ~14 000         | ~350            | 40×     |

At 10 K rows the difference is negligible — the query fits in PostgreSQL's buffer cache.
The gap widens sharply above 1 M rows because ClickHouse reads only the columns referenced
in the query (columnar storage), while PostgreSQL reads entire 8 KB heap pages even for
a 3-column projection.

---

## Why the gap grows with scale

PostgreSQL stores rows in heap pages. A scan of `ict_incidents` to read four columns still
reads every column for every row off disk. At 10 M rows with ~120 bytes per row that is
~1.2 GB of I/O for a query that touches only ~40 bytes per row.

ClickHouse stores each column in separate compressed files, with dictionary encoding
(`LowCardinality`) for `severity` and `service_name`. The same query reads:
- `occurred_at` — 8 bytes × 10 M = 80 MB (uncompressed), ~15 MB compressed
- `severity` — dictionary index, ~2–3 MB compressed
- `clients_affected_count`, `duration_minutes`, `vendor_id` — ~5–10 MB each compressed

Total I/O: ~40–50 MB vs ~1.2 GB.  The 20–40× speedup is largely I/O, not compute.

---

## When to use which

| Scenario | Use |
|---|---|
| Transactional writes, row lookups, FK constraints | PostgreSQL |
| dbt transformations (SQL + row-level logic) | PostgreSQL |
| Ad-hoc compliance analysis from Python on local data | DuckDB |
| Real-time dashboard refreshing every 30 s | ClickHouse |
| Aggregation over > 10 M rows, sub-second SLA | ClickHouse |

FinanzWerk decision: PostgreSQL is the operational store and dbt target. ClickHouse is added
when dashboard latency becomes unacceptable at scale (> 5 M rows). At < 1 M rows PostgreSQL
with the composite index from migration 002 is fast enough.

---

## Running the benchmark yourself

```bash
# Generate scale data (add --scale flag to generate_data.py)
python generate_data.py --rows 1000000

# Load into ClickHouse
clickhouse-client --host localhost --port 9000 \
  --user admin --password clickhouse_admin \
  --query "$(cat load_data.sql)"

# Time the PostgreSQL query
psql -c "\timing" -f ../queries/13_quarterly_dora_report.sql

# Time the ClickHouse query
clickhouse-client --host localhost --time \
  --query "$(cat quarterly_report.sql)" > /dev/null
```
