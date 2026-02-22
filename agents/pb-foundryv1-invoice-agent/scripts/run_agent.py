from __future__ import annotations

import argparse
from pathlib import Path
import sys

ROOT_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT_DIR / "src"))

from foundry_invoice_agent.runtime.run import ask_question  # type: ignore[import-not-found]  # noqa: E402


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Ask questions to a Foundry v1 invoice assistant."
    )
    parser.add_argument(
        "question", nargs="?", default=None, help="Single question to ask"
    )
    return parser


def interactive_loop(initial_question: str | None) -> None:
    if initial_question:
        result = ask_question(initial_question)
        print(f"Assistant: {result.response_text}")

    while True:
        try:
            user_input = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("")
            return

        if not user_input:
            continue
        if user_input.lower() in {"exit", "quit"}:
            return

        result = ask_question(user_input)
        print(f"Assistant: {result.response_text}")


def main() -> None:
    args = build_arg_parser().parse_args()
    interactive_loop(args.question)


if __name__ == "__main__":
    main()
