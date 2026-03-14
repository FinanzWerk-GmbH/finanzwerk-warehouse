import random
import uuid
from datetime import timedelta

from faker import Faker
from psycopg2.extras import execute_values

from db import get_connection

fake = Faker()

SEVERITIES = ["low", "medium", "high", "critical"]
SERVICE_CATEGORIES = [
    "Cloud Infrastructure",
    "Payment Processing",
    "Data Storage",
    "Networking",
    "Cybersecurity",
    "SaaS Platform",
]
NOTIFICATION_TYPES = ["email", "sms", "api_webhook", "portal"]
SCHEMA_VERSION = "1.0.0"


def _vendor_rows(n: int) -> list[tuple]:
    rows = []
    for _ in range(n):
        rows.append((
            str(uuid.uuid4()),
            fake.company(),
            random.choice(SERVICE_CATEGORIES),
            round(random.uniform(1.0, 10.0), 1),
            f"CONTRACT-{fake.bothify('??####').upper()}",
            fake.date_time_between(start_date="-3y", end_date="-1y"),
        ))
    return rows


def _incident_rows(vendor_ids: list[str], n: int) -> list[tuple]:
    rows = []
    for _ in range(n):
        occurred_at = fake.date_time_between(start_date="-2y", end_date="now")
        severity = random.choice(SEVERITIES)
        notified_at = (
            occurred_at + timedelta(hours=random.randint(1, 72))
            if severity in ("high", "critical") or random.random() < 0.3
            else None
        )
        rows.append((
            str(uuid.uuid4()),
            occurred_at,
            fake.bs().title(),
            severity,
            random.randint(0, 5000),
            random.randint(1, 1440),
            random.choice(vendor_ids) if random.random() > 0.05 else None,
            notified_at,
            occurred_at + timedelta(minutes=random.randint(0, 60)),
        ))
    return rows


def _notification_rows(incident_ids: list[str], fraction: float = 0.6) -> list[tuple]:
    selected = random.sample(incident_ids, int(len(incident_ids) * fraction))
    return [
        (
            incident_id,
            random.choice(NOTIFICATION_TYPES),
            fake.date_time_between(start_date="-2y", end_date="now"),
            SCHEMA_VERSION,
        )
        for incident_id in selected
    ]


def main() -> None:
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            vendor_rows = _vendor_rows(50)
            execute_values(
                cur,
                """
                INSERT INTO vendors
                    (vendor_id, vendor_name, service_category, risk_score,
                     contract_reference, created_at)
                VALUES %s
                """,
                vendor_rows,
            )
            vendor_ids = [r[0] for r in vendor_rows]

            incident_rows = _incident_rows(vendor_ids, 10_000)
            execute_values(
                cur,
                """
                INSERT INTO ict_incidents
                    (incident_id, occurred_at, service_name, severity,
                     clients_affected_count, duration_minutes, vendor_id,
                     notified_at, created_at)
                VALUES %s
                """,
                incident_rows,
            )
            incident_ids = [r[0] for r in incident_rows]

            notif_rows = _notification_rows(incident_ids, fraction=0.6)
            execute_values(
                cur,
                """
                INSERT INTO notification_log
                    (incident_id, notification_type, sent_at, schema_version)
                VALUES %s
                """,
                notif_rows,
            )

        conn.commit()
        print(
            f"Inserted: {len(vendor_rows)} vendors, "
            f"{len(incident_rows)} incidents, "
            f"{len(notif_rows)} notifications"
        )
    finally:
        conn.close()


if __name__ == "__main__":
    main()
