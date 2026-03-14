from pathlib import Path

from db import get_connection

MIGRATIONS_DIR = Path(__file__).parent / "migrations"


def main() -> None:
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            for sql_file in sorted(MIGRATIONS_DIR.glob("*.sql")):
                print(f"Running {sql_file.name}...")
                cur.execute(sql_file.read_text())
        conn.commit()
        print("Done.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
