from datetime import date, timedelta
import sys

from psycopg2.extras import execute_values

from db import get_connection


def load_dim_date(cur):
    rows = []
    d = date(2020, 1, 1)
    while d <= date(2030, 12, 31):
        rows.append((
            int(d.strftime("%Y%m%d")),
            d,
            d.strftime("%A"),
            d.isocalendar()[1],
            (d.month - 1) // 3 + 1,
            d.year,
            d.weekday() >= 5,
        ))
        d += timedelta(days=1)

    execute_values(cur, """
        INSERT INTO compliance.dim_date
            (date_key, full_date, day_of_week, week_number, quarter, year, is_weekend)
        VALUES %s
        ON CONFLICT (date_key) DO NOTHING
    """, rows)
    print(f"dim_date: {len(rows)} rows")


def load_dim_vendor(cur):
    cur.execute("""
        INSERT INTO compliance.dim_vendor
            (vendor_id, vendor_name, service_category, risk_score, valid_from, valid_to)
        SELECT vendor_id, vendor_name, service_category, risk_score, created_at, NULL
        FROM vendors
        WHERE vendor_id NOT IN (SELECT vendor_id FROM compliance.dim_vendor)
    """)
    print(f"dim_vendor: {cur.rowcount} rows")


def load_dim_service(cur):
    cur.execute("""
        INSERT INTO compliance.dim_service (service_name, service_tier)
        SELECT DISTINCT service_name, 'standard'
        FROM ict_incidents
        ON CONFLICT (service_name) DO NOTHING
    """)
    print(f"dim_service: {cur.rowcount} rows")


def load_fact_incidents(cur):
    cur.execute("""
        INSERT INTO compliance.fact_ict_incidents
            (incident_id, date_key, vendor_key, service_key,
             severity, duration_minutes, clients_affected_count,
             is_major_incident, is_notified_within_24h)
        SELECT
            i.incident_id,
            TO_CHAR(i.occurred_at, 'YYYYMMDD')::int,
            dv.vendor_key,
            ds.service_key,
            i.severity,
            i.duration_minutes,
            i.clients_affected_count,
            (i.severity IN ('high', 'critical') OR i.clients_affected_count > 1000),
            (i.notified_at IS NOT NULL AND i.notified_at - i.occurred_at <= INTERVAL '24 hours')
        FROM ict_incidents i
        LEFT JOIN compliance.dim_vendor dv
            ON dv.vendor_id = i.vendor_id AND dv.valid_to IS NULL
        JOIN compliance.dim_service ds
            ON ds.service_name = i.service_name
        ON CONFLICT (incident_id) DO NOTHING
    """)
    print(f"fact_ict_incidents: {cur.rowcount} rows")


def load_hub_vendor(cur):
    cur.execute("""
        INSERT INTO compliance.hub_vendor (vendor_id, load_timestamp, record_source)
        SELECT vendor_id, created_at, 'finanzwerk-warehouse/vendors'
        FROM vendors
        ON CONFLICT (vendor_id) DO NOTHING
    """)
    print(f"hub_vendor: {cur.rowcount} rows")


def load_sat_vendor_details(cur):
    cur.execute("""
        INSERT INTO compliance.sat_vendor_details
            (hub_vendor_key, load_timestamp, vendor_name, service_category,
             risk_score, contract_reference, is_current)
        SELECT hv.hub_vendor_key, v.created_at, v.vendor_name,
               v.service_category, v.risk_score, v.contract_reference, true
        FROM vendors v
        JOIN compliance.hub_vendor hv ON hv.vendor_id = v.vendor_id
        ON CONFLICT (hub_vendor_key, load_timestamp) DO NOTHING
    """)
    print(f"sat_vendor_details: {cur.rowcount} rows")


def load_lnk_vendor_incident(cur):
    cur.execute("""
        INSERT INTO compliance.lnk_vendor_incident (hub_vendor_key, incident_id, load_timestamp)
        SELECT hv.hub_vendor_key, i.incident_id, i.created_at
        FROM ict_incidents i
        JOIN compliance.hub_vendor hv ON hv.vendor_id = i.vendor_id
        ON CONFLICT (hub_vendor_key, incident_id) DO NOTHING
    """)
    print(f"lnk_vendor_incident: {cur.rowcount} rows")


def main():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            print("--- star schema ---")
            load_dim_date(cur)
            load_dim_vendor(cur)
            load_dim_service(cur)
            load_fact_incidents(cur)

            print("--- data vault ---")
            load_hub_vendor(cur)
            load_sat_vendor_details(cur)
            load_lnk_vendor_incident(cur)

        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    main()
