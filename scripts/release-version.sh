#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: scripts/release-version.sh <major|minor|patch> [--write]
EOF
  exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi

BUMP_TYPE="$1"
WRITE_CHANGES="false"

case "$BUMP_TYPE" in
  major|minor|patch) ;;
  *) usage ;;
 esac

if [[ $# -eq 2 ]]; then
  if [[ "$2" != "--write" ]]; then
    usage
  fi
  WRITE_CHANGES="true"
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/project.yml"
PLIST_FILE="$ROOT_DIR/Notatod/Info.plist"

RELEASE_VALUES="$(python3 - "$PROJECT_FILE" "$PLIST_FILE" "$BUMP_TYPE" "$WRITE_CHANGES" <<'PY'
from pathlib import Path
import plistlib
import re
import sys

project_path = Path(sys.argv[1])
plist_path = Path(sys.argv[2])
bump_type = sys.argv[3]
write_changes = sys.argv[4] == "true"

project_text = project_path.read_text()
version_match = re.search(r'^(\s*MARKETING_VERSION:\s*)(\d+)\.(\d+)\.(\d+)(\s*)$', project_text, re.MULTILINE)
build_match = re.search(r'^(\s*CURRENT_PROJECT_VERSION:\s*)(\d+)(\s*)$', project_text, re.MULTILINE)

if version_match is None:
    raise SystemExit("MARKETING_VERSION not found in project.yml")
if build_match is None:
    raise SystemExit("CURRENT_PROJECT_VERSION not found in project.yml")

major, minor, patch = map(int, version_match.group(2, 3, 4))
current_version = f"{major}.{minor}.{patch}"
current_build = int(build_match.group(2))

if bump_type == "major":
    next_version = f"{major + 1}.0.0"
elif bump_type == "minor":
    next_version = f"{major}.{minor + 1}.0"
else:
    next_version = f"{major}.{minor}.{patch + 1}"

next_build = current_build + 1

if write_changes:
    project_text = re.sub(
        r'^(\s*MARKETING_VERSION:\s*)\d+\.\d+\.\d+(\s*)$',
        lambda match: f"{match.group(1)}{next_version}{match.group(2)}",
        project_text,
        count=1,
        flags=re.MULTILINE,
    )
    project_text = re.sub(
        r'^(\s*CURRENT_PROJECT_VERSION:\s*)\d+(\s*)$',
        lambda match: f"{match.group(1)}{next_build}{match.group(2)}",
        project_text,
        count=1,
        flags=re.MULTILINE,
    )
    project_path.write_text(project_text)

    with plist_path.open("rb") as handle:
        plist = plistlib.load(handle)
    plist["CFBundleShortVersionString"] = next_version
    plist["CFBundleVersion"] = str(next_build)
    with plist_path.open("wb") as handle:
        plistlib.dump(plist, handle, sort_keys=False)

print(current_version)
print(current_build)
print(next_version)
print(next_build)
PY
)"

CURRENT_VERSION="$(printf '%s\n' "$RELEASE_VALUES" | sed -n '1p')"
CURRENT_BUILD="$(printf '%s\n' "$RELEASE_VALUES" | sed -n '2p')"
NEXT_VERSION="$(printf '%s\n' "$RELEASE_VALUES" | sed -n '3p')"
NEXT_BUILD="$(printf '%s\n' "$RELEASE_VALUES" | sed -n '4p')"

printf 'CURRENT_VERSION=%s\n' "$CURRENT_VERSION"
printf 'CURRENT_BUILD=%s\n' "$CURRENT_BUILD"
printf 'NEXT_VERSION=%s\n' "$NEXT_VERSION"
printf 'NEXT_BUILD=%s\n' "$NEXT_BUILD"
