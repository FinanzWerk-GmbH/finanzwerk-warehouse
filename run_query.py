import sys
from pathlib import Path

from db import get_connection


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: python run_query.py queries/<file>.sql")
        sys.exit(1)

    sql_file = Path(sys.argv[1])
    if not sql_file.exists():
        print(f"File not found: {sql_file}")
        sys.exit(1)

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql_file.read_text())
            if cur.description is None:
                print("Query executed (no rows returned).")
                return

            headers = [col.name for col in cur.description]
            rows = cur.fetchall()

            col_widths = [
                max(len(str(h)), max((len(str(r[i])) for r in rows), default=0))
                for i, h in enumerate(headers)
            ]

            def fmt_row(values):
                return "  ".join(str(v).ljust(w) for v, w in zip(values, col_widths))

            separator = "  ".join("-" * w for w in col_widths)
            print(fmt_row(headers))
            print(separator)
            for row in rows:
                print(fmt_row(row))
            print(f"\n{len(rows)} row(s)")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
