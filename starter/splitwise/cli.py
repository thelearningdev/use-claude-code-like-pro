"""Command line entry point.

Task 1 ships the skeleton only. Subcommands arrive with tasks 2 onward.
"""

import argparse

from . import __version__


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="splitwise")
    parser.add_argument("--version", action="version", version=__version__)
    parser.set_defaults(func=None)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.func is None:
        parser.print_help()
        return 0
    return args.func(args)
