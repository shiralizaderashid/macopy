#!/bin/bash
# Build + Applications qovluğuna install et + başlat

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"

bash "${ROOT}/build.sh"

APP="${ROOT}/.build/Macopy.app"

echo "📦  /Applications qovluğuna kopyalanır..."
cp -rf "${APP}" /Applications/Macopy.app

echo "▶  Başladılır..."
open /Applications/Macopy.app

echo ""
echo "✅  Macopy işə salındı!"
echo "   Menu bar-da 📋 ikonasına baxın."
echo "   Tarixi açmaq üçün: ⌘ + ⇧ + V"

# Login item olaraq əlavə et (macOS 13+)
osascript -e '
tell application "System Events"
    if not (exists login item "Macopy") then
        make login item at end with properties {path:"/Applications/Macopy.app", hidden:false}
        log "Login item əlavə edildi."
    end if
end tell' 2>/dev/null && echo "   Kompüter açıldıqda avtomatik işə başlayacaq ✓" || true
