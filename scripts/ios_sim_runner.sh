#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${PROJECT_PATH:-$ROOT_DIR/DreamSpend.xcodeproj}"
SCHEME_NAME="${SCHEME_NAME:-DreamSpend}"
DEVICE_NAME="${DEVICE_NAME:-iPhone 17}"
ACTION="${1:-test}"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Project not found: $PROJECT_PATH" >&2
  exit 1
fi

DESTINATIONS="$(xcodebuild -showdestinations -project "$PROJECT_PATH" -scheme "$SCHEME_NAME")"

DEVICE_ID="$(printf '%s\n' "$DESTINATIONS" | awk -v device="$DEVICE_NAME" '
  /platform:iOS Simulator/ && index($0, "name:" device " }") {
    if (match($0, /id:[^,]+/)) {
      id = substr($0, RSTART + 3, RLENGTH - 3)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
      print id
      exit
    }
  }
')"

if [[ -z "$DEVICE_ID" ]]; then
  echo "Could not find simulator destination for '$DEVICE_NAME'." >&2
  echo "Available iOS Simulator destinations:" >&2
  printf '%s\n' "$DESTINATIONS" \
    | sed -nE 's/.*platform:iOS Simulator, .*OS:([^,]+), name:([^}]+).*/  - \2 (iOS \1)/p' >&2
  exit 1
fi

DESTINATION="id=$DEVICE_ID"

echo "Using simulator: $DEVICE_NAME ($DESTINATION)"

case "$ACTION" in
  build)
    exec xcodebuild \
      -project "$PROJECT_PATH" \
      -scheme "$SCHEME_NAME" \
      -destination "$DESTINATION" \
      -sdk iphonesimulator \
      build
    ;;
  test)
    exec xcodebuild \
      -project "$PROJECT_PATH" \
      -scheme "$SCHEME_NAME" \
      -destination "$DESTINATION" \
      test
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    echo "Usage: $(basename "$0") [build|test]" >&2
    exit 2
    ;;
esac
