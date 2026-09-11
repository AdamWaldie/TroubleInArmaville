#!/usr/bin/env python3
"""Fails if any tracked (or staged) file looks like it contains a hardcoded
credential - the Steam account password/Guard code publish_workshop.sh
prompts for interactively, an API key, a private key, etc.

Zero dependencies, deliberately: this runs both in CI (tools/ci/secret_scanner.py
is called from the SQFValidation workflow) and as a local git pre-commit hook
(tools/git-hooks/pre-commit), and a hook that needs `pip install` before it
can run is a hook nobody keeps enabled.

Not a substitute for care - this catches the common, careless case (a
credential typed straight into a script, a config file, or a .env someone
forgot was tracked), not a determined leak. publish_workshop.sh's own
safeguard is structural: it never accepts the Steam password or Guard code
as a flag or env var, only an interactive hidden prompt, so there is no
"paste it in a script" path for it to catch in the first place - this
scanner is the backstop for everything else.

Usage:
  tools/ci/secret_scanner.py            # scans every git-tracked text file
  tools/ci/secret_scanner.py --staged   # scans only staged (about-to-commit) files, for the pre-commit hook

A line that is a deliberate, known-safe false positive (example code,
documentation, this file's own pattern list) can be excluded with a
trailing `# secret-scanner: allow` comment.
"""
import re
import subprocess
import sys
from pathlib import Path

ALLOW_MARKER = "secret-scanner: allow"

# Extensions worth scanning as text. Binary/asset formats (paa, p3d, png,
# ogg...) can't meaningfully contain a hardcoded credential string and are
# skipped rather than risk a decode error.
TEXT_EXTENSIONS = {
    ".py", ".sh", ".bash", ".yml", ".yaml", ".json", ".md", ".txt",
    ".sqf", ".hpp", ".ext", ".cfg", ".ini", ".env", ".ps1", ".bat",
}

PLACEHOLDER_VALUES = {
    "", "changeme", "change_me", "your_password_here", "yourpassword",
    "xxx", "xxxxx", "todo", "fixme", "example", "placeholder", "password",
    "secret", "token", "test", "redacted", "none", "null", "n/a",
}

# (name, pattern, note) - pattern must have exactly one capturing group
# around the secret-looking value where applicable, used only for the
# allow-marker check; the match as a whole is what gets reported.
PATTERNS = [
    (
        "AWS access key ID",
        re.compile(r"AKIA[0-9A-Z]{16}"),
    ),
    (
        "Private key block",
        re.compile(r"-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----"),
    ),
    (
        "steamcmd login with a literal (non-variable) password",
        # +login user password - flags only when neither token starts with
        # a shell/env variable sigil, so publish_workshop.sh's own
        # `+login "$STEAM_USERNAME" "$STEAM_PASSWORD"` never matches.
        re.compile(r'\+login\s+"?[^\s"$]+"?\s+"?[^\s"$]{4,}"?'),
    ),
    (
        "hardcoded credential-looking assignment",
        re.compile(
            # No leading \b: real names are usually PREFIXED (STEAM_PASSWORD,
            # DB_SECRET), and "_" is a word character so \b would never fire
            # between it and the keyword - matching the keyword as a
            # substring of the identifier is what we actually want here.
            r'(?i)(password|passwd|pwd|secret|api[_-]?key|access[_-]?key|'
            r'auth[_-]?token|steam[_-]?guard|steamguard)[a-z0-9_]*\s*[:=]\s*'
            r'["\']?([^\s"\';,]{4,})["\']?'
        ),
    ),
]


def is_placeholder(value: str) -> bool:
    stripped = value.strip("'\" ")
    if stripped.lower() in PLACEHOLDER_VALUES:
        return True
    # A reference to an env var / shell var / template expansion is the
    # thing we want scripts to use instead of a literal - never flag it.
    return bool(re.match(r'^\$|^\{\{|^os\.environ|^process\.env', stripped))


def tracked_files(staged: bool) -> list[str]:
    cmd = ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"] if staged else ["git", "ls-files"]
    out = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    return [line for line in out.splitlines() if line]


def scan_file(path: Path) -> list[str]:
    findings = []
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return findings

    for lineno, line in enumerate(text.splitlines(), start=1):
        if ALLOW_MARKER in line:
            continue
        for name, pattern in PATTERNS:
            match = pattern.search(line)
            if not match:
                continue
            if name == "hardcoded credential-looking assignment" and is_placeholder(match.group(2)):
                continue
            findings.append(f"{path}:{lineno}: possible {name}: {line.strip()}")
    return findings


def main() -> int:
    staged = "--staged" in sys.argv[1:]
    files = tracked_files(staged)

    findings = []
    for rel_path in files:
        path = Path(rel_path)
        if not path.is_file() or path.suffix.lower() not in TEXT_EXTENSIONS:
            continue
        findings.extend(scan_file(path))

    print(f"Scanned {len(files)} tracked file(s){' (staged only)' if staged else ''}")
    if findings:
        print("\nPossible hardcoded credentials found:\n")
        for finding in findings:
            print(f"  {finding}")
        print(
            "\nIf this is a false positive, either fix the value (use an env var or an "
            f"interactive prompt instead of a literal) or add '# {ALLOW_MARKER}' at the "
            "end of the line."
        )
        return 1

    print("No hardcoded credentials found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
