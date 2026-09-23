#!/usr/bin/env python3
"""Validates stringtable.xml against the code that uses it.

Arma never errors on a missing stringtable key: localize just returns an empty
string (or the raw key), so a typo'd or deleted key only shows up as a blank
card or a raw "STR_TIA_..." in the middle of a round. This catches that before
merge, along with the translation mistakes that also fail silently in-game:

- stringtable.xml parses, and no Key ID appears twice
- every key has <Original> and <English>
- every translation keeps exactly the %1, %2, ... placeholders of <English>
  (a dropped %2 shifts every later argument; an extra one prints garbage)
- no text has leading/trailing whitespace (the loader may trim it)
- every STR_TIA_ key the mission references in .sqf/.hpp/.ext exists
- every key built at runtime from a role/direction name exists (these never
  appear literally in code, so the scan above can't see them)
"""

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STRINGTABLE = ROOT / "stringtable.xml"
PREFIX = "STR_TIA_"

# Keys assembled at runtime ("STR_TIA_Role_" + _role, ...).
ROLES = ["Traitor", "Detective", "Jester", "Innocent"]
DYNAMIC_KEYS = (
    [f"STR_TIA_Role_{r}" for r in ROLES]
    + [f"STR_TIA_Role_{r}_Letter" for r in ROLES]
    + [f"STR_TIA_Dir_{d}" for d in ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]]
)

PLACEHOLDER = re.compile(r"%\d+")
KEY_REF = re.compile(r"\$?(" + PREFIX + r"[A-Za-z0-9_]+)")


def placeholders(text):
    return sorted(PLACEHOLDER.findall(text or ""))


def main():
    errors = []
    try:
        tree = ET.parse(STRINGTABLE)
    except (ET.ParseError, OSError) as exc:
        print(f"stringtable.xml: {exc}")
        return 1

    defined = {}
    for key in tree.getroot().iter("Key"):
        kid = key.get("ID", "")
        if kid in defined:
            errors.append(f"duplicate key {kid}")
        langs = {child.tag: (child.text or "") for child in key}
        defined[kid] = langs
        english = langs.get("English")
        if "Original" not in langs or english is None:
            errors.append(f"{kid}: missing <Original> or <English>")
            continue
        want = placeholders(english)
        for lang, text in langs.items():
            if placeholders(text) != want:
                errors.append(f"{kid} <{lang}>: placeholders {placeholders(text)} != English {want}")
            if text != text.strip():
                errors.append(f"{kid} <{lang}>: leading/trailing whitespace")

    referenced = {}
    for path in sorted(ROOT.rglob("*")):
        if path.suffix.lower() not in (".sqf", ".hpp", ".ext") or ".git" in path.parts:
            continue
        for lineno, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
            for match in KEY_REF.finditer(line):
                key = match.group(1)
                # A trailing underscore is a prefix being concatenated at
                # runtime ("STR_TIA_Role_" + _role) - covered by DYNAMIC_KEYS.
                if not key.endswith("_"):
                    referenced.setdefault(key, f"{path.relative_to(ROOT)}:{lineno}")

    for key, where in sorted(referenced.items()):
        if key not in defined:
            errors.append(f"{where}: {key} is not in stringtable.xml")
    for key in DYNAMIC_KEYS:
        if key not in defined:
            errors.append(f"runtime key {key} is not in stringtable.xml")

    print("Validating stringtable.xml")
    print("------")
    print(f"{len(defined)} keys defined, {len(referenced)} referenced")
    for error in errors:
        print(f"ERROR: {error}")
    print(f"Errors detected: {len(errors)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
