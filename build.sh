#!/bin/bash
set -e

APP="Macopy"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="${ROOT}/.build"
BUNDLE="${BUILD}/${APP}.app"
MACOS="${BUNDLE}/Contents/MacOS"
RESOURCES="${BUNDLE}/Contents/Resources"

echo "🔨  Building ${APP}..."

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
echo "✅  Done: ${BUNDLE}"
echo ""
echo "▶  To launch:"
echo "   open '${BUNDLE}'"
echo ""
echo "📦  To install to Applications:"
echo "   cp -r '${BUNDLE}' /Applications/"
