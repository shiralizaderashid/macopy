#!/bin/bash
# Macopy DMG paket yaradır — başqalarına göndərmək üçün.
# İstifadə: bash package.sh
set -e

APP="Macopy"
VERSION="1.0"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUNDLE="${ROOT}/.build/${APP}.app"
STAGING="/tmp/macopy_pkg_$$"
DMG_OUT="${ROOT}/${APP}-${VERSION}.dmg"

# ── 1. Build ──────────────────────────────────────────────────────────────────
bash "${ROOT}/build.sh"

# ── 2. Ad-hoc imzala ──────────────────────────────────────────────────────────
#    İmzasız app macOS-da "xarab fayldır" xətası verir.
#    Ad-hoc imza (-) pulsuz alternativdir; "naməlum developer" xəbərdarlığı
#    göstərir amma açılır.
echo "🔏  Ad-hoc imzalanır..."
codesign --deep --force --sign - "${BUNDLE}"

# ── 3. Staging ────────────────────────────────────────────────────────────────
rm -rf "${STAGING}"
mkdir -p "${STAGING}"

# App-ı köçür
cp -r "${BUNDLE}" "${STAGING}/${APP}.app"

# Applications simvolu — sürüklə-bırak üçün
ln -s /Applications "${STAGING}/Applications"

# ── 4. DMG yarat ──────────────────────────────────────────────────────────────
echo "📦  DMG yaradılır..."
rm -f "${DMG_OUT}"
hdiutil create \
    -volname "${APP} ${VERSION}" \
    -srcfolder "${STAGING}" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "${DMG_OUT}"

rm -rf "${STAGING}"

# ── 5. Nəticə ─────────────────────────────────────────────────────────────────
SIZE=$(du -sh "${DMG_OUT}" | cut -f1)
echo ""
echo "✅  DMG hazırdır: $(basename "${DMG_OUT}") (${SIZE})"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Alıcıya bu mesajı göndər:"
echo ""
echo "  1. DMG faylını aç"
echo "  2. Macopy ikonunu Applications qovluğuna sürüşdür"
echo "  3. Applications-da Macopy-ni TAP — ÜZƏRİNƏ SAĞ KLİK et → 'Aç'"
echo "     (İki dəfə klik etmə, sağ klik et!)"
echo "  4. 'Naməlum developer' xəbərdarlığında 'Aç' düyməsinə bas"
echo "  5. Menu bar-da 📋 görünəcək"
echo "  6. System Settings → Privacy & Security → Accessibility → Macopy ✓"
echo "  7. Macopy-ni yenidən başlat → ⌘⇧V ilə istifadə et"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
