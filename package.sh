#!/bin/bash
# Create a Macopy DMG for distribution.
# Usage: bash package.sh
set -e

APP="Macopy"
VERSION="1.0"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUNDLE="${ROOT}/.build/${APP}.app"
STAGING="/tmp/macopy_pkg_$$"
DMG_OUT="${ROOT}/${APP}-${VERSION}.dmg"

# ── 1. Build ──────────────────────────────────────────────────────────────────
bash "${ROOT}/build.sh"

# ── 2. Ad-hoc sign ────────────────────────────────────────────────────────────
#    Unsigned apps trigger "damaged file" errors on macOS.
#    Ad-hoc signing (-) is free; shows "unidentified developer" but opens fine.
echo "🔏  Ad-hoc signing..."
codesign --deep --force --sign - "${BUNDLE}"

# ── 3. Staging ────────────────────────────────────────────────────────────────
rm -rf "${STAGING}"
mkdir -p "${STAGING}"

cp -r "${BUNDLE}" "${STAGING}/${APP}.app"

# Applications symlink for drag-and-drop install
ln -s /Applications "${STAGING}/Applications"

# ── 4. Create DMG ─────────────────────────────────────────────────────────────
echo "📦  Creating DMG..."
rm -f "${DMG_OUT}"
hdiutil create \
    -volname "${APP} ${VERSION}" \
    -srcfolder "${STAGING}" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "${DMG_OUT}"

rm -rf "${STAGING}"

# ── 5. Result ─────────────────────────────────────────────────────────────────
SIZE=$(du -sh "${DMG_OUT}" | cut -f1)
echo ""
echo "✅  DMG ready: $(basename "${DMG_OUT}") (${SIZE})"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Share these instructions with recipients:"
echo ""
echo "  1. Open the DMG file"
echo "  2. Drag Macopy into the Applications folder"
echo "  3. In Applications, RIGHT-CLICK Macopy → Open"
echo "     (Do not double-click — right-click!)"
echo "  4. Click Open on the 'unidentified developer' warning"
echo "  5. Look for 📋 in the menu bar"
echo "  6. System Settings → Privacy & Security → Accessibility → Macopy ✓"
echo "  7. Restart Macopy → use with ⌘⇧V"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
