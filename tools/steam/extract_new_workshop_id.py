#!/usr/bin/env python3
"""Best-effort extraction of a newly-created Workshop item's published file
ID from a steamcmd workshop_build_item log.

steamcmd's console output for a successful create isn't a single stable,
documented format across versions/platforms, so this tries several known
shapes rather than betting on one exact regex - and prints nothing (exit 1)
rather than guessing, when none of them match, so publish_workshop.sh falls
back to telling the user to read the log and record the ID by hand instead
of silently recording a wrong one.

Usage: extract_new_workshop_id.py <steamcmd-log-file>
Prints the ID to stdout and exits 0 on a match; exits 1 with nothing printed
otherwise.
"""
import re
import sys
from pathlib import Path

# Ordered by how strong a signal each one is - a URL or an explicit
# publishedfileid field is essentially unambiguous, "item id"/"workshop
# item" phrasing is a looser fallback.
PATTERNS = [
    re.compile(r"sharedfiles/filedetails/\?id=(\d{6,})"),
    re.compile(r'"?publishedfileid"?\s*[:=]\s*"?(\d{6,})"?', re.IGNORECASE),
    re.compile(r"item\s*id\D{0,5}(\d{6,})", re.IGNORECASE),
    re.compile(r"workshop item\D{0,15}(\d{6,})", re.IGNORECASE),
]


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: extract_new_workshop_id.py <steamcmd-log-file>", file=sys.stderr)
        return 2

    text = Path(sys.argv[1]).read_text(errors="replace")
    for pattern in PATTERNS:
        match = pattern.search(text)
        if match:
            print(match.group(1))
            return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
