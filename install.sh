#!/usr/bin/env bash
# install.sh — установка темы Fly «Astra 1.8 Fly Dark» и автосмены день/ночь
# в профиль пользователя (без root), для Astra Linux 1.8 / Fly.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$CONFIG_HOME/autostart"

THEMES="Astra18FlyDark Astra18FlyLight"
CONFIG_FILE="$CONFIG_HOME/fly-theme-switch.conf"
SWITCH="$BIN_DIR/fly-theme-switch"
X11="$BIN_DIR/fly-theme-x11"
PIDFILE="$STATE_HOME/fly-theme-switch/pid"
APPLY="$BIN_DIR/fly-theme-apply"
BACKUP_DIR="$STATE_HOME/fly-theme-switch/backup"


stop_daemon() {
  if [ -f "$PIDFILE" ]; then
    local pid
    pid="$(cat "$PIDFILE" 2>/dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        kill -0 "$pid" 2>/dev/null || return 0
        sleep 0.3
      done
      kill -KILL "$pid" 2>/dev/null || true
    fi
    rm -f "$PIDFILE"
  fi
}

info() { printf '%s\n' "$*"; }
warn() { printf 'ПРЕДУПРЕЖДЕНИЕ: %s\n' "$*" >&2; }

if [ "${XDG_CURRENT_DESKTOP:-}" != "fly" ] && [ "${XDG_CURRENT_DESKTOP:-}" != "Fly" ]; then
  warn "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-<пусто>} — установка рассчитана на Fly (Astra Linux 1.8)"
fi
for c in fly-select-theme fly-wmfunc fly-wm; do
  command -v "$c" >/dev/null 2>&1 || warn "не найдена команда $c — проверьте, что это сессия Fly"
done

info "Установка тем: $THEMES ..."
install -d "$DATA_HOME/flythemes" "$DATA_HOME/color-schemes" \
          "$BIN_DIR" "$AUTOSTART_DIR" "$BACKUP_DIR"

# --- темы и цветовые схемы ---
for theme_id in $THEMES; do
  theme_dir="$DATA_HOME/flythemes/$theme_id"
  scheme_file="$DATA_HOME/color-schemes/$theme_id.colors"
  rm -rf "$theme_dir"
  cp -a "$HERE/src/themes/$theme_id" "$theme_dir"
  python3 - "$theme_dir/theme/themerc" "$scheme_file" <<'PY'
import sys
path, scheme = sys.argv[1:3]
text = open(path, encoding='utf-8').read()
text = text.replace('@SCHEME_PATH@', scheme)
open(path, 'w', encoding='utf-8').write(text)
PY
  install -m 644 "$HERE/src/colors/$theme_id.colors" "$scheme_file"
done

# --- скрипты ---
install -m 755 "$HERE/src/fly-theme-apply" "$APPLY"
install -m 755 "$HERE/src/fly-theme-switch" "$SWITCH"
install -m 755 "$HERE/src/fly-theme-x11" "$X11"

# --- конфиг ---
if [ -f "$CONFIG_FILE" ]; then
  info "Конфиг уже есть, оставляю: $CONFIG_FILE"
else
  install -m 644 "$HERE/src/fly-theme-switch.conf" "$CONFIG_FILE"
  info "Создан конфиг: $CONFIG_FILE"
fi

# --- автозапуск ---
sed "s|/usr/bin/|$BIN_DIR/|g" "$HERE/packaging/fly-theme-switch.desktop" \
  >"$AUTOSTART_DIR/fly-theme-switch.desktop"
chmod 644 "$AUTOSTART_DIR/fly-theme-switch.desktop"

# --- бэкап текущего оформления (для uninstall) ---
if [ ! -f "$BACKUP_DIR/fly-admin-themerc" ]; then
  cp "$CONFIG_HOME/fly-admin-themerc" "$BACKUP_DIR/fly-admin-themerc" 2>/dev/null || true
  cp "$HOME/.fly/paletterc" "$BACKUP_DIR/paletterc" 2>/dev/null || true
  sed -n 's/^CurrentTheme=//p' "$CONFIG_HOME/fly-admin-themerc" 2>/dev/null | head -1 \
    >"$BACKUP_DIR/current-theme" || true
  info "Сохранён бэкап исходного оформления: $BACKUP_DIR"
fi

# --- применить тему по текущему времени суток ---
if [ -n "${DISPLAY:-}" ]; then
  "$SWITCH" --apply auto || warn "не удалось применить тему автоматически"
  stop_daemon
  started=0
  for _ in 1 2 3 4 5; do
    setsid nohup "$SWITCH" --daemon >/dev/null 2>&1 &
    sleep 1.5
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
      started=1
      break
    fi
  done
  [ "$started" = 1 ] || warn "демон автосмены не запустился (см. ~/.local/state/fly-theme-switch/log)"
else
  warn "нет DISPLAY — тема применится при входе в сеанс"
fi

cat <<EOF
Готово.
  Темы:        $DATA_HOME/flythemes/{Astra18FlyDark,Astra18FlyLight}
  Схемы:       $DATA_HOME/color-schemes/{Astra18FlyDark,Astra18FlyLight}.colors
  Скрипты:     $APPLY, $SWITCH, $X11
  Конфиг:      $CONFIG_FILE
  Автозапуск:  $AUTOSTART_DIR/fly-theme-switch.desktop
  Статус:      $SWITCH --status
  Вручную:     $SWITCH --apply day|night|auto
  Удалить:     $HERE/uninstall.sh
EOF
