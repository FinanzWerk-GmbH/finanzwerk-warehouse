# finanzwerk-warehouse

> PostgreSQL compliance data warehouse — schema, migrations, SQL query library, and semantic search for DORA/NIS2 reporting.

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![dbt](https://img.shields.io/badge/dbt-FF694B?logo=dbt&logoColor=white)

Schema and queries live here. Python pipelines (finanzwerk-airflow) and dbt models (finanzwerk-dbt) write to and read from the structures defined in this repo.

## Projects in this repo

| # | Project | Stack | Doc |
|---|---------|-------|-----|
| 2 | First Compliance Queries — schema + synthetic data | PostgreSQL · Python · Faker | [→](docs/project-02-compliance-queries.md) |
| 3 | Window Functions, CTEs, Query Optimisation | PostgreSQL · EXPLAIN ANALYZE | [→](docs/project-03-window-functions.md) |
| 4+5 | Star Schema, Data Vault, and SCD Types | PostgreSQL | [→](docs/project-04-star-schema-scd.md) |
| 6 | Batch Ingestion — schema and pipeline state | PostgreSQL · Pydantic | [→](docs/project-06-batch-ingestion.md) |
| 13 | dbt Transformation Layer | dbt · PostgreSQL | [→](docs/project-13-dbt-layer.md) |
| 24 | ClickHouse OLAP Analytics Layer | ClickHouse · PostgreSQL | [→](docs/project-24-clickhouse.md) |
| 32 | pgvector Semantic Search | pgvector · PostgreSQL · Python | [→](docs/project-32-pgvector.md) |
