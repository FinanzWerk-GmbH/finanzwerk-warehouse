"""
SCD behaviour tests. Requires a live DB with all migrations applied.
Run: python3 test_scd.py
"""

from db import get_connection
from scd import update_service_display_name, update_config


def test_type1_overwrites():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO compliance.dim_service (service_name, display_name)
                VALUES ('_test_svc', 'Old Name')
                RETURNING service_key
            """)
            key = cur.fetchone()[0]

            update_service_display_name(cur, key, 'New Name')

            cur.execute(
                "SELECT display_name FROM compliance.dim_service WHERE service_key = %s", (key,)
            )
            name = cur.fetchone()[0]

            # Type 1: old value is gone, no history row exists anywhere
            assert name == 'New Name', f"got {name!r}"

    finally:
        conn.rollback()   # never commit test data
        conn.close()

    print("test_type1_overwrites ok")


def test_type4_config_history():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            update_config(cur, '_test_key', '24', 'test')
            update_config(cur, '_test_key', '48', 'test')
            update_config(cur, '_test_key', '72', 'test')

            cur.execute(
                "SELECT value FROM compliance.config_current WHERE key = %s", ('_test_key',)
            )
            assert cur.fetchone()[0] == '72'

            cur.execute(
                "SELECT COUNT(*) FROM compliance.config_history WHERE key = %s", ('_test_key',)
            )
            # first call produces no history (nothing to archive), next two do
            assert cur.fetchone()[0] == 2

    finally:
        conn.rollback()
        conn.close()

    print("test_type4_config_history ok")


if __name__ == "__main__":
    test_type1_overwrites()
    test_type4_config_history()
