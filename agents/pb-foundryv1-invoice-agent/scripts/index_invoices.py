from __future__ import annotations

from pathlib import Path
import sys

ROOT_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT_DIR / "src"))

from foundry_invoice_agent.runtime.index import index_invoices  # type: ignore[import-not-found]  # noqa: E402


def main() -> None:
    vector_store_id = index_invoices()
    print(f"Vector store ready: {vector_store_id}")


if __name__ == "__main__":
    main()
