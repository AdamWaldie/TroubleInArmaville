#!/usr/bin/env python3
"""Validate completeness markers, screenshots, and RPT cleanliness."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def validate(run_root: Path) -> list[str]:
    manifest_path = run_root / "audit_manifest.json"
    if not manifest_path.is_file():
        return [f"missing manifest: {manifest_path}"]
    # Windows PowerShell 5's `Set-Content -Encoding utf8` writes a BOM. Accept
    # that launcher-produced JSON as well as ordinary BOM-less UTF-8.
    manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    errors: list[str] = []
    capture_ids = [item["id"] for item in manifest["captures"]]
    for language in manifest["languages"]:
        root = run_root / language
        rpt_path = root / "arma3.rpt"
        if not rpt_path.is_file():
            errors.append(f"{language}: missing arma3.rpt")
            continue
        rpt = rpt_path.read_text(encoding="utf-8", errors="replace")
        for marker in ("TTT QA UI COMPLETE:", "TTT QA ROUND COMPLETE:"):
            if marker not in rpt:
                errors.append(f"{language}: missing marker {marker}")
        if "TTT QA PASS: localisation-keys-resolve" not in rpt:
            errors.append(f"{language}: stringtable keys did not receive a runtime-resolution pass")
        for check in manifest["roundChecks"]:
            if f"TTT QA PASS: {check}" not in rpt:
                errors.append(f"{language}: missing round pass {check}")
        for pattern in manifest["rptErrorPatterns"]:
            if re.search(pattern, rpt, flags=re.IGNORECASE):
                errors.append(f"{language}: RPT matched error pattern {pattern!r}")
        for capture_id in capture_ids:
            image = root / "screenshots" / f"{capture_id}.png"
            if not image.is_file() or image.stat().st_size < 10_000:
                errors.append(f"{language}: missing/empty capture {capture_id}")
    return errors


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-root", type=Path, required=True)
    args = parser.parse_args()
    errors = validate(args.run_root.resolve())
    if errors:
        print("Audit validation failed:")
        print("\n".join(f"- {error}" for error in errors))
        sys.exit(1)
    print("Audit validation passed for every language, capture, round check, and RPT gate.")


if __name__ == "__main__":
    main()
