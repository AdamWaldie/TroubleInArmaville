#!/usr/bin/env bash
# Publishes one or more terrain missions to the Steam Workshop (Arma 3,
# appid 107410), via steamcmd's `workshop_build_item`. Run this locally -
# it's a developer tool, not CI: a Workshop publish is a one-way, public
# action against your real Steam account, and shouldn't be something a
# pushed commit or a CI trigger can set off.
#
# *** UNVERIFIED FOR ARMA 3 MISSIONS - TEST ON ONE TERRAIN FIRST ***
# Bohemia's own docs (community.bistudio.com/wiki/Arma_3_Publisher) state
# that scenarios/missions "are published directly from Eden Editor and
# can't be published by Publisher" - Publisher being the GUI wrapper around
# the same generic Steamworks content-upload mechanism this script's
# steamcmd call uses. Mods/addons/terrains go through that generic path
# fine; missions may not, or may upload without error but not show up as a
# subscribable scenario in-game. No confirmed report of workshop_build_item
# successfully publishing an Arma 3 mission was found when this script was
# written. Run this once against a single terrain with --visibility private
# and verify in-game (subscribe to it, does it appear as a scenario and
# load correctly) before trusting it for the rest. If it doesn't work, the
# confirmed-working path is Eden Editor's own Scenario menu > Publish to
# Steam Workshop, run once per terrain by hand.
#
# Requires steamcmd on PATH. Install it yourself (e.g. the steamcmd package
# on your distro, or https://developer.valvesoftware.com/wiki/SteamCMD) -
# this script doesn't fetch or manage it for you.
#
# Content is built the same way release.yml builds it for a tagged release
# (staged, SQF/config validated, terrain-specific mission.sqm resolution),
# but left as an unpacked folder rather than zipped/pbo'd: Steam Workshop
# content items are generally the unpacked folder, not a .pbo.
#
# Workshop items are created once and updated after that - see
# steam/workshop_ids.json. A terrain still at 0 there gets a brand-new item
# on its first publish; this script captures the ID steamcmd assigns it
# straight out of the steamcmd log and writes it into
# steam/workshop_ids.json for you (falling back to printing manual
# instructions if it can't confidently parse the log - steamcmd's output
# format for this isn't a stable, documented contract). Either way, commit
# steam/workshop_ids.json afterward, or the next run creates a second,
# duplicate item instead of updating the one just created.
#
# An update only ever sends description, changenote, and the mission
# content itself - never title, preview image, or visibility, which are
# only set at creation. So a title, cover image, or visibility you've since
# changed by hand on the Workshop page survives every later update.
#
# Usage:
#   tools/steam/publish_workshop.sh [options]
#
# Options:
#   --terrains "Altis Tanoa ..."   Terrains to publish (default: all of Altis Tanoa Stratis Enoch Malden)
#   --visibility public|friends-only|private   Workshop visibility for any item CREATED this run - ignored for terrains being updated (default: private)
#   --changenote "text"            Workshop changenote for this update (default: "Manual update via publish_workshop.sh")
#   --username NAME                Steam username (default: prompted)
#
# The Steam password and Steam Guard codes are always prompted for
# interactively (hidden input) - never a flag or env var, which would leave
# them in your shell history. A fresh Guard code is prompted for before
# each steamcmd login this script makes (existing items being updated are
# batched under one login; each newly-created item logs in separately so
# its result can be attributed unambiguously - see below).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

TERRAINS="Altis Tanoa Stratis Enoch Malden"
VISIBILITY="private"
CHANGENOTE="Manual update via publish_workshop.sh"
STEAM_USERNAME="${STEAM_USERNAME:-}"
IDS_FILE="$REPO_ROOT/steam/workshop_ids.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --terrains) TERRAINS="$2"; shift 2 ;;
    --visibility) VISIBILITY="$2"; shift 2 ;;
    --changenote) CHANGENOTE="$2"; shift 2 ;;
    --username) STEAM_USERNAME="$2"; shift 2 ;;
    -h|--help) sed -n '2,61p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

command -v steamcmd >/dev/null 2>&1 || {
  echo "Error: steamcmd not found on PATH. Install it first (see the top of this script)." >&2
  exit 1
}

case "$VISIBILITY" in
  public) VIS=0 ;;
  friends-only) VIS=1 ;;
  private) VIS=2 ;;
  *) echo "Error: --visibility must be public, friends-only, or private" >&2; exit 1 ;;
esac

published_id_for() {
  python3 - "$1" <<'PY'
import json, sys
from pathlib import Path
terrain = sys.argv[1]
ids = json.loads(Path("steam/workshop_ids.json").read_text())
if terrain not in ids:
    print(f"Error: no entry for terrain '{terrain}' in steam/workshop_ids.json", file=sys.stderr)
    sys.exit(1)
print(ids[terrain])
PY
}

if [[ -z "$STEAM_USERNAME" ]]; then
  read -r -p "Steam username: " STEAM_USERNAME
fi
read -r -s -p "Steam password: " STEAM_PASSWORD
echo

echo "Validating SQF..."
python3 tools/ci/sqf_validator.py
echo "Validating config..."
python3 tools/ci/config_style_checker.py

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "Staging the mission..."
./tools/ci/stage_mission.sh "$WORK/stage_mission"

mkdir -p "$WORK/content" "$WORK/vdf"
NEW_TERRAINS=()
UPDATE_TERRAINS=()
for TERRAIN in $TERRAINS; do
  NAME="TroubleInArmaville.${TERRAIN}"
  DEST="$WORK/content/$NAME"
  cp -r "$WORK/stage_mission" "$DEST"

  OVERRIDE="terrains/${TERRAIN}/mission.sqm"
  ANCHOR=$(python3 .github/scripts/terrain_anchor.py "$TERRAIN" .github/terrains.json)

  if [[ -f "$OVERRIDE" ]]; then
    echo "$TERRAIN: using the supplied, in-editor-verified mission.sqm"
    cp "$OVERRIDE" "$DEST/mission.sqm"
  elif [[ -n "$ANCHOR" ]]; then
    echo "$TERRAIN: recentring player positions onto researched anchor ($ANCHOR)"
    python3 .github/scripts/patch_mission_positions.py "$DEST/mission.sqm" $ANCHOR
  else
    echo "$TERRAIN: shipping mission.sqm as authored (only known-correct for Altis)"
  fi

  python3 tools/steam/generate_workshop_vdf.py \
    --terrain "$TERRAIN" \
    --content-folder "$DEST" \
    --preview-file "$REPO_ROOT/steam/workshop_preview.png" \
    --description-file "$REPO_ROOT/steam/workshop_description.md" \
    --ids-file "$IDS_FILE" \
    --changenote "$CHANGENOTE" \
    --visibility "$VIS" \
    --out "$WORK/vdf/${TERRAIN}.vdf"

  if [[ "$(published_id_for "$TERRAIN")" == "0" ]]; then
    NEW_TERRAINS+=("$TERRAIN")
  else
    UPDATE_TERRAINS+=("$TERRAIN")
  fi
done

run_steamcmd_login() {
  # $1: log file to tee output to. $2..: VDF paths to build in that one login session.
  local logfile="$1"; shift
  read -r -s -p "Steam Guard code (leave blank if not required): " code
  echo
  local args=(+login "$STEAM_USERNAME" "$STEAM_PASSWORD")
  [[ -n "$code" ]] && args+=("$code")
  for vdf in "$@"; do
    args+=(+workshop_build_item "$vdf")
  done
  args+=(+quit)
  steamcmd "${args[@]}" | tee "$logfile"
}

if ((${#UPDATE_TERRAINS[@]})); then
  echo
  echo "Updating ${#UPDATE_TERRAINS[@]} existing Workshop item(s): ${UPDATE_TERRAINS[*]}"
  VDFS=()
  for TERRAIN in "${UPDATE_TERRAINS[@]}"; do
    VDFS+=("$WORK/vdf/${TERRAIN}.vdf")
  done
  run_steamcmd_login "$WORK/log-updates.txt" "${VDFS[@]}"
fi

UNRECORDED_TERRAINS=()
for TERRAIN in "${NEW_TERRAINS[@]}"; do
  echo
  echo "Creating a new Workshop item for $TERRAIN..."
  LOG="$WORK/log-new-${TERRAIN}.txt"
  run_steamcmd_login "$LOG" "$WORK/vdf/${TERRAIN}.vdf"

  if NEW_ID="$(python3 tools/steam/extract_new_workshop_id.py "$LOG")"; then
    python3 tools/steam/record_workshop_id.py --ids-file "$IDS_FILE" --terrain "$TERRAIN" --id "$NEW_ID"
  else
    echo "Could not automatically detect the new Workshop ID for $TERRAIN from the steamcmd log."
    echo "Check $LOG by hand (look for a 'publishedfileid' line or a workshop URL), then run:"
    echo "  python3 tools/steam/record_workshop_id.py --ids-file steam/workshop_ids.json --terrain $TERRAIN --id <ID>"
    UNRECORDED_TERRAINS+=("$TERRAIN")
  fi
done

echo
echo "Workshop links:"
for TERRAIN in $TERRAINS; do
  ID="$(published_id_for "$TERRAIN")"
  if [[ "$ID" != "0" ]]; then
    echo "  $TERRAIN: https://steamcommunity.com/sharedfiles/filedetails/?id=$ID"
  else
    echo "  $TERRAIN: not recorded - see the message above for how to record it by hand"
  fi
done

if ((${#UNRECORDED_TERRAINS[@]})); then
  echo
  echo "${#UNRECORDED_TERRAINS[@]} terrain(s) still need their ID recorded by hand: ${UNRECORDED_TERRAINS[*]}"
fi

if ((${#NEW_TERRAINS[@]})); then
  echo
  echo "steam/workshop_ids.json was updated in your working tree for any newly created item(s)."
  echo "Commit it now, or the next run will create a duplicate Workshop item instead of updating the one just created."
fi
