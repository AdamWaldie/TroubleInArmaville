#!/usr/bin/env bash
# Publishes one or more terrain missions to the Steam Workshop (Arma 3,
# appid 107410), via steamcmd's `workshop_build_item`. Run this locally -
# it's a developer tool, not CI: a Workshop publish is a one-way, public
# action against your real Steam account, and shouldn't be something a
# pushed commit or a CI trigger can set off.
#
# Requires steamcmd on PATH. Install it yourself (e.g. the steamcmd package
# on your distro, or https://developer.valvesoftware.com/wiki/SteamCMD) -
# this script doesn't fetch or manage it for you.
#
# Content is built the same way release.yml builds it for a tagged release
# (staged, SQF/config validated, terrain-specific mission.sqm resolution),
# but left as an unpacked folder rather than zipped/pbo'd: Steam Workshop
# mission items are the unpacked mission folder, not a .pbo.
#
# Workshop items are created once and updated after that - see
# steam/workshop_ids.json. A terrain still at 0 there gets a brand-new item
# on its first publish; steamcmd prints the ID it was assigned, which you
# then need to copy into steam/workshop_ids.json and commit, or the next
# run creates a second, duplicate item instead of updating the first.
#
# Usage:
#   tools/steam/publish_workshop.sh [options]
#
# Options:
#   --terrains "Altis Tanoa ..."   Terrains to publish (default: all of Altis Tanoa Stratis Enoch Malden)
#   --visibility public|friends-only|private   Workshop visibility for any item created this run (default: private)
#   --changenote "text"            Workshop changenote for this update (default: "Manual update via publish_workshop.sh")
#   --username NAME                Steam username (default: prompted)
#
# The Steam password and, if your account needs one, a Steam Guard code are
# always prompted for interactively (hidden input) - never pass them as
# flags or env vars, which would leave them in your shell history.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

TERRAINS="Altis Tanoa Stratis Enoch Malden"
VISIBILITY="private"
CHANGENOTE="Manual update via publish_workshop.sh"
STEAM_USERNAME="${STEAM_USERNAME:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --terrains) TERRAINS="$2"; shift 2 ;;
    --visibility) VISIBILITY="$2"; shift 2 ;;
    --changenote) CHANGENOTE="$2"; shift 2 ;;
    --username) STEAM_USERNAME="$2"; shift 2 ;;
    -h|--help) sed -n '2,33p' "$0"; exit 0 ;;
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

if [[ -z "$STEAM_USERNAME" ]]; then
  read -r -p "Steam username: " STEAM_USERNAME
fi
read -r -s -p "Steam password: " STEAM_PASSWORD
echo
read -r -s -p "Steam Guard code (leave blank if not required): " STEAMGUARD_CODE
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
    --ids-file "$REPO_ROOT/steam/workshop_ids.json" \
    --changenote "$CHANGENOTE" \
    --visibility "$VIS" \
    --out "$WORK/vdf/${TERRAIN}.vdf"
done

STEAMCMD_ARGS=(+login "$STEAM_USERNAME" "$STEAM_PASSWORD")
if [[ -n "$STEAMGUARD_CODE" ]]; then
  STEAMCMD_ARGS+=("$STEAMGUARD_CODE")
fi
for TERRAIN in $TERRAINS; do
  STEAMCMD_ARGS+=(+workshop_build_item "$WORK/vdf/${TERRAIN}.vdf")
done
STEAMCMD_ARGS+=(+quit)

steamcmd "${STEAMCMD_ARGS[@]}"

echo
echo "If any terrain above was published for the first time (publishedfileid=NEW in the"
echo "generate_workshop_vdf.py output further up), find its assigned ID in the steamcmd"
echo "output above and copy it into steam/workshop_ids.json, then commit - otherwise the"
echo "next run creates a duplicate Workshop item for that terrain instead of updating this one."
