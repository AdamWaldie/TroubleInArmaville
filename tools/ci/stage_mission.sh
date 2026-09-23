#!/usr/bin/env bash
# Stages the mission for release, by ALLOWLIST.
#
# A mission .pbo should contain the mission and nothing else. This repo also holds
# the crest art generator, the CI checkers and their Python, none of which belong in
# a shipped mission - so rather than blocklisting what to drop (which silently ships
# anything new that nobody remembered to exclude), only known mission content is
# copied in, and anything unrecognised at the top level is a hard failure.
#
# LICENSE and README are the two deliberate non-mission exceptions.
set -euo pipefail

# Replaces an rsync --exclude blocklist, which is the whole point: a blocklist
# silently ships anything new that nobody remembered to exclude. tools/, steam/ and
# the crest-art generator's .py/.png files were all already slipping through it.
STAGE="${1:?usage: stage_mission.sh <target-dir>}"

# Extensions Arma actually needs at runtime, plus the two allowed documents.
ALLOWED_EXT="sqf sqm ext hpp paa jpg jpeg ogg ogv wss wav p3d rvmat"
# Matched on BASENAME, so a README beside the code it documents is fine too.
# stringtable.xml is named rather than allowing .xml outright: it's the one XML
# file Arma reads at runtime (localisation), and it must sit at the mission root.
ALLOWED_FILES="LICENSE LICENSE.md LICENSE.txt README README.md stringtable.xml"
# Top-level entries that are development-only and must never ship.
# Development-only top-level directories. wiki/ and steam/ are documentation and
# store assets, terrains/ is source terrain material - none are loaded by the
# mission at runtime.
EXCLUDE_DIRS=".git .github tools release dist stage .qa wiki steam terrains docs"

rm -rf "$STAGE"; mkdir -p "$STAGE"

is_allowed_ext() {
  local ext="${1##*.}"
  [[ "$1" == *.* ]] || return 1
  for a in $ALLOWED_EXT; do [[ "${ext,,}" == "$a" ]] && return 0; done
  return 1
}
is_allowed_file() {
  local base="${1##*/}"
  for a in $ALLOWED_FILES; do [[ "$base" == "$a" ]] && return 0; done
  return 1
}

unexpected=()
while IFS= read -r -d '' path; do
  rel="${path#./}"
  top="${rel%%/*}"
  case " $EXCLUDE_DIRS " in *" $top "*) continue;; esac
  # Dotfiles at the top level are tooling config, never mission content.
  [[ "$rel" == .* ]] && continue

  if is_allowed_ext "$rel" || is_allowed_file "$rel"; then
    mkdir -p "$STAGE/$(dirname "$rel")"
    cp "$path" "$STAGE/$rel"
  else
    unexpected+=("$rel")
  fi
done < <(find . -type f -not -path './.git/*' -print0)

if ((${#unexpected[@]})); then
  echo "::error::Refusing to build: files are neither mission content nor an allowed document."
  echo "Add the extension to ALLOWED_EXT, name it in ALLOWED_FILES, or move it under a"
  echo "development-only directory (${EXCLUDE_DIRS// /, }):"
  printf '  %s\n' "${unexpected[@]}"
  exit 1
fi

# mission.sqm and description.ext are what make this a mission at all, and every
# player-facing string lives in stringtable.xml (a missing one shows raw keys).
for required in mission.sqm description.ext stringtable.xml; do
  [[ -f "$STAGE/$required" ]] || { echo "::error::$required missing from the staged mission"; exit 1; }
done

echo "Staged $(find "$STAGE" -type f | wc -l) mission files into $STAGE"
