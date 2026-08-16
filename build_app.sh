#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-release}"

echo "==> Building StickyPal ($MODE)..."
if [ "$MODE" = "release" ]; then
    swift build -c release 2>&1
    BINARY=".build/release/StickyPal"
else
    swift build 2>&1
    BINARY=".build/debug/StickyPal"
fi

APP_DIR="$SCRIPT_DIR/build/StickyPal.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Packaging StickyPal.app..."
mkdir -p "$MACOS_DIR" "$RESOURCES"

cp "$BINARY" "$MACOS_DIR/StickyPal"
cp "$SCRIPT_DIR/Info.plist" "$CONTENTS/Info.plist"

# Ad-hoc sign the bundle
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true

echo "==> Done! App bundle at: $APP_DIR"
echo "To install, drag StickyPal.app to /Applications, or run:"
echo "    open "$APP_DIR""

