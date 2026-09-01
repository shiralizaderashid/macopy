#!/bin/bash
# Build, install to Applications, and launch

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"

bash "${ROOT}/build.sh"

APP="${ROOT}/.build/Macopy.app"

echo "📦  Copying to /Applications..."
cp -rf "${APP}" /Applications/Macopy.app

echo "▶  Launching..."
open /Applications/Macopy.app

echo ""
echo "✅  Macopy is running!"
echo "   Look for the 📋 icon in the menu bar."
echo "   Open history with: ⌘ + ⇧ + V"

# Add login item (macOS 13+)
osascript -e '
tell application "System Events"
    if not (exists login item "Macopy") then
        make login item at end with properties {path:"/Applications/Macopy.app", hidden:false}
        log "Login item added."
    end if
end tell' 2>/dev/null && echo "   Will launch automatically at login ✓" || true
