#!/usr/bin/env python3
"""Builds a steamcmd `workshop_build_item` control file (VDF) for one terrain.

steamcmd's VDF description field is a single quoted string - no file
reference syntax exists for it - so this reads steam/workshop_description.md
and inlines it, escaping the characters VDF's quoted-string parser treats
specially (backslash, double quote) and turning real newlines into literal
"\n" escapes, which is the form steamcmd/Steamworks accepts for a
multi-line description.

publishedfileid "0" is not a placeholder value to steamcmd - it is the
documented signal to create a brand-new Workshop item instead of updating an
existing one. Passing a terrain's real ID here (from steam/workshop_ids.json)
updates that item in place; passing 0 creates a new one and steamcmd prints
the assigned ID in its output, which must then be recorded and committed
before the next run.
"""
import argparse
import json
import sys
from pathlib import Path

APP_ID = "107410"  # Arma 3


def escape_vdf_string(text: str) -> str:
    text = text.replace("\\", "\\\\").replace('"', '\\"')
    return text.replace("\r\n", "\n").replace("\n", "\\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--terrain", required=True)
    parser.add_argument("--content-folder", required=True, help="Absolute path to the unpacked mission folder")
    parser.add_argument("--preview-file", required=True, help="Absolute path to the Workshop preview image")
    parser.add_argument("--description-file", required=True, help="Path to steam/workshop_description.md")
    parser.add_argument("--ids-file", required=True, help="Path to steam/workshop_ids.json")
    parser.add_argument("--changenote", required=True)
    parser.add_argument("--out", required=True, help="Where to write the generated .vdf")
    parser.add_argument("--visibility", default="2", choices=["0", "1", "2"],
                         help="0=public 1=friends-only 2=private (default: private, so a first run never goes live by accident)")
    args = parser.parse_args()

    ids = json.loads(Path(args.ids_file).read_text())
    if args.terrain not in ids:
        print(f"::error::No entry for terrain '{args.terrain}' in {args.ids_file}", file=sys.stderr)
        return 1
    published_file_id = ids[args.terrain]

    description = Path(args.description_file).read_text()
    title = f"Trouble In Armaville - {args.terrain}"

    lines = [
        '"workshopitem"',
        "{",
        f'\t"appid"\t\t"{APP_ID}"',
        f'\t"contentfolder"\t"{args.content_folder}"',
        f'\t"previewfile"\t"{args.preview_file}"',
        f'\t"visibility"\t"{args.visibility}"',
        f'\t"title"\t\t"{escape_vdf_string(title)}"',
        f'\t"description"\t"{escape_vdf_string(description)}"',
        f'\t"changenote"\t"{escape_vdf_string(args.changenote)}"',
    ]
    # publishedfileid "0" (create-new) is the one case where the key must be
    # omitted rather than written as 0 - some steamcmd builds create a new
    # item either way, but older ones only do so when the key is absent.
    if published_file_id:
        lines.append(f'\t"publishedfileid"\t"{published_file_id}"')
    lines.append("}")

    Path(args.out).write_text("\n".join(lines) + "\n")
    print(f"Wrote {args.out} for {args.terrain} (publishedfileid={published_file_id or 'NEW'})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
