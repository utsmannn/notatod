#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/Notatod.xcodeproj"
SCHEME="Notatod"
CONFIGURATION="Debug"
DERIVED_DATA_PATH="$ROOT_DIR/.derived-data"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/Notatod.app"

printf "==> Building %s (%s)\n" "$SCHEME" "$CONFIGURATION"
rtk xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -sdk macosx \
  build

if [[ ! -d "$APP_PATH" ]]; then
  printf "Build succeeded but app not found at: %s\n" "$APP_PATH" >&2
  exit 1
fi

if pgrep -x "Notatod" >/dev/null 2>&1; then
  printf "==> Stopping existing Notatod instance\n"
  pkill -x "Notatod"
fi

printf "==> Launching app\n"
open "$APP_PATH"
printf "==> Running: %s\n" "$APP_PATH"
