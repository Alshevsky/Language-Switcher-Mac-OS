#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
APP_NAME="Switcher"
APP_DIR="$BUILD_DIR/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"
SRC_DIR="$ROOT/Sources/Switcher"

echo "→ Сборка ${APP_NAME}.app (arm64)…"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swiftc \
  -O \
  -target arm64-apple-macosx13.0 \
  -framework AppKit \
  -framework Carbon \
  -framework ServiceManagement \
  -framework ApplicationServices \
  -o "$MACOS_DIR/$APP_NAME" \
  "$SRC_DIR/main.swift" \
  "$SRC_DIR/AppDelegate.swift" \
  "$SRC_DIR/InputSourceManager.swift" \
  "$SRC_DIR/HotkeyMonitor.swift" \
  "$SRC_DIR/LaunchAtLogin.swift"

cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

# PkgInfo
echo -n "APPL????" > "$CONTENTS/PkgInfo"

ENTITLEMENTS="$ROOT/Resources/Switcher.entitlements"

# Подпись: Hardened Runtime.
# Если задан SWITCHER_SIGN_IDENTITY (Developer ID Application: …) — подпись этим сертификатом.
# Иначе — ad-hoc (-). Notarization: после сборки с Developer ID выполните
#   xcrun notarytool submit … && xcrun stapler staple "$APP_DIR"
SIGN_IDENTITY="${SWITCHER_SIGN_IDENTITY:--}"
echo "→ Подпись: ${SIGN_IDENTITY} (Hardened Runtime)"

CODESIGN_ARGS=(
  --force
  --deep
  --options runtime
  --entitlements "$ENTITLEMENTS"
  --sign "$SIGN_IDENTITY"
)
# Secure timestamp только с Developer ID (ad-hoc его не поддерживает)
if [[ "$SIGN_IDENTITY" != "-" ]]; then
  CODESIGN_ARGS+=(--timestamp)
fi

codesign "${CODESIGN_ARGS[@]}" "$APP_DIR"
codesign --verify --verbose=2 "$APP_DIR"

echo "✓ Готово: $APP_DIR"
echo ""
echo "Установка:"
echo "  cp -R \"$APP_DIR\" /Applications/"
echo "  open /Applications/${APP_NAME}.app"
