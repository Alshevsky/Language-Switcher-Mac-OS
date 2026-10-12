#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_SRC="$ROOT/build/Switcher.app"
APP_DST="/Applications/Switcher.app"

if [[ ! -d "$APP_SRC" ]]; then
  echo "Сначала соберите приложение: ./Scripts/build.sh"
  exit 1
fi

# Закрыть предыдущий экземпляр
pkill -x Switcher 2>/dev/null || true

rm -rf "$APP_DST"
cp -R "$APP_SRC" "$APP_DST"
# Сохраняем Hardened Runtime при копировании
ENTITLEMENTS="$ROOT/Resources/Switcher.entitlements"
SIGN_IDENTITY="${SWITCHER_SIGN_IDENTITY:--}"
CODESIGN_ARGS=(
  --force
  --deep
  --options runtime
  --entitlements "$ENTITLEMENTS"
  --sign "$SIGN_IDENTITY"
)
if [[ "$SIGN_IDENTITY" != "-" ]]; then
  CODESIGN_ARGS+=(--timestamp)
fi
codesign "${CODESIGN_ARGS[@]}" "$APP_DST" >/dev/null
open "$APP_DST"

echo "✓ Установлено в $APP_DST и запущено"
echo "  Выдайте Accessibility: Системные настройки → Конфиденциальность → Универсальный доступ"
