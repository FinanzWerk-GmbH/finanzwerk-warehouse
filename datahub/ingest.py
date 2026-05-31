import subprocess
import sys
from pathlib import Path

RECIPES = [
    "postgres_recipe.yaml",
    "dbt_recipe.yaml",
]

DATAHUB_URL = "http://localhost:9002"
RECIPE_DIR = Path(__file__).parent


def run_ingestion(recipe: str) -> bool:
    path = RECIPE_DIR / recipe
    print(f"\n--- ingesting {recipe} ---")
    result = subprocess.run(
        ["datahub", "ingest", "-c", str(path)],
        capture_output=False,
        text=True,
    )
    if result.returncode != 0:
        print(f"failed: {recipe}", file=sys.stderr)
        return False
    return True


if __name__ == "__main__":
    recipes = sys.argv[1:] if len(sys.argv) > 1 else RECIPES
    failed = []
    for r in recipes:
        if not run_ingestion(r):
            failed.append(r)

    if failed:
        print(f"\nfailed recipes: {failed}", file=sys.stderr)
        sys.exit(1)
    print("\nall ingestion complete")
