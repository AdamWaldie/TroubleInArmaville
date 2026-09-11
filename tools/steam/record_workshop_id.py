#!/usr/bin/env python3
"""Writes one terrain's Steam Workshop published file ID into
steam/workshop_ids.json, leaving every other entry (and the _comment key)
untouched.

Called by publish_workshop.sh right after steamcmd reports a newly created
item's ID, so the ID gets recorded automatically instead of relying on
someone to copy it out of the steamcmd log by hand.
"""
import argparse
import json
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ids-file", required=True)
    parser.add_argument("--terrain", required=True)
    parser.add_argument("--id", required=True, type=int)
    args = parser.parse_args()

    path = Path(args.ids_file)
    ids = json.loads(path.read_text())
    previous = ids.get(args.terrain)
    if previous:
        print(
            f"Warning: {args.terrain} already had ID {previous} in {args.ids_file}; "
            f"overwriting with {args.id}.",
            file=sys.stderr,
        )
    ids[args.terrain] = args.id
    path.write_text(json.dumps(ids, indent=2) + "\n")
    print(f"Recorded {args.terrain} = {args.id} in {args.ids_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
