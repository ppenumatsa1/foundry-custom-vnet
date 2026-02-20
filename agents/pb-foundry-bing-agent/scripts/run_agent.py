from __future__ import annotations

import argparse
from pathlib import Path
import sys

ROOT_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT_DIR / 'src'))

from foundry_bing_agent.runtime.run import ask_question  # type: ignore[import-not-found]  # noqa: E402


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description='Ask questions to a Foundry Bing agent (no M365 channel).')
    parser.add_argument('question', nargs='?', default=None, help='Single question to ask')
    parser.add_argument('--conversation-id', default=None, help='Optional Foundry conversation id to continue')
    return parser


def interactive_loop(initial_question: str | None, conversation_id: str | None) -> None:
    current_conversation = conversation_id

    if initial_question:
        result = ask_question(initial_question, current_conversation)
        current_conversation = result.foundry_conversation_id
        print(f'Assistant: {result.response_text}')
        print(f'Conversation ID: {current_conversation}')

    while True:
        try:
            user_input = input('You: ').strip()
        except (EOFError, KeyboardInterrupt):
            print('')
            return

        if not user_input:
            continue
        if user_input.lower() in {'exit', 'quit'}:
            return

        result = ask_question(user_input, current_conversation)
        current_conversation = result.foundry_conversation_id
        print(f'Assistant: {result.response_text}')
        print(f'Conversation ID: {current_conversation}')


def main() -> None:
    args = build_arg_parser().parse_args()
    interactive_loop(args.question, args.conversation_id)


if __name__ == '__main__':
    main()
