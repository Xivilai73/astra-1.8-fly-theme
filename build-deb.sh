#!/usr/bin/env bash
# build-deb.sh — собрать .deb для Astra Linux 1.8 (без root, через dpkg-deb).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="astra-1.8-fly-theme"
VER="1.0.0-1"
ARCH="all"
THEME_ID="Astra18FlyDark"
OUT="$HERE/dist"
BUILD="$OUT/build"
ROOT="$BUILD/root"
SCHEME_DST="/usr/share/color-schemes/$THEME_ID.colors"

rm -rf "$BUILD"
install -d "$ROOT/DEBIAN" \
           "$ROOT/usr/share/flythemes/$THEME_ID/theme" \
           "$ROOT/usr/share/color-schemes" \
           "$ROOT/usr/bin" \
           "$ROOT/etc/xdg/autostart" \
           "$ROOT/usr/share/doc/$PKG"

# тема
cp -a "$HERE/src/themes/$THEME_ID/." "$ROOT/usr/share/flythemes/$THEME_ID/"
python3 - "$ROOT/usr/share/flythemes/$THEME_ID/theme/themerc" "$SCHEME_DST" <<'PY'
import sys
path, scheme = sys.argv[1:3]
text = open(path, encoding='utf-8').read().replace('@SCHEME_PATH@', scheme)
open(path, 'w', encoding='utf-8').write(text)
PY

# цветовая схема
install -m 644 "$HERE/src/colors/$THEME_ID.colors" "$ROOT$SCHEME_DST"

# скрипты
install -m 755 "$HERE/src/fly-theme-apply" "$ROOT/usr/bin/fly-theme-apply"
install -m 755 "$HERE/src/fly-theme-switch" "$ROOT/usr/bin/fly-theme-switch"

# автозапуск и конфиг по умолчанию
install -m 644 "$HERE/packaging/fly-theme-switch.desktop" \
  "$ROOT/etc/xdg/autostart/fly-theme-switch.desktop"
install -m 644 "$HERE/src/fly-theme-switch.conf" "$ROOT/etc/xdg/fly-theme-switch.conf"

# документация
install -m 644 "$HERE/README.md" "$ROOT/usr/share/doc/$PKG/README.md"
install -m 644 "$HERE/LICENSE" "$ROOT/usr/share/doc/$PKG/copyright"

sed "s/@VERSION@/$VER/" "$HERE/packaging/control" >"$ROOT/DEBIAN/control"

DEB="$OUT/${PKG}_${VER}_${ARCH}.deb"
dpkg-deb --root-owner-group --build "$ROOT" "$DEB"

echo
echo "Собрано: $DEB"
dpkg-deb --info "$DEB"
echo
echo "Содержимое:"
dpkg-deb --contents "$DEB" | sed 's|^|  |'
