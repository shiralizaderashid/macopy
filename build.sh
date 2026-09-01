#!/bin/bash
set -e

APP="Macopy"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="${ROOT}/.build"
BUNDLE="${BUILD}/${APP}.app"
MACOS="${BUNDLE}/Contents/MacOS"
RESOURCES="${BUNDLE}/Contents/Resources"

echo "🔨  ${APP} build edilir..."

mkdir -p "${MACOS}" "${RESOURCES}"

swiftc \
    "${ROOT}/Sources/"*.swift \
    -framework AppKit \
    -framework Carbon \
    -framework SwiftUI \
    -framework Combine \
    -target arm64-apple-macosx13.0 \
    -O \
    -o "${MACOS}/${APP}"

cp "${ROOT}/Info.plist" "${BUNDLE}/Contents/Info.plist"

echo ""
echo "✅  Hazırdır: ${BUNDLE}"
echo ""
echo "▶  Başlatmaq üçün:"
echo "   open '${BUNDLE}'"
echo ""
echo "📦  Applications-a köçürmək üçün:"
echo "   cp -r '${BUNDLE}' /Applications/"
