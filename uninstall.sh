#!/usr/bin/env bash
# uninstall.sh — удалить тему «Astra 1.8 Fly Dark», автосмену и вернуть
# оформление, которое было до установки (из бэкапа).
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
STATE_DIR="$STATE_HOME/fly-theme-switch"
BACKUP_DIR="$STATE_DIR/backup"


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

stop_daemon

info "Удаление тем и скриптов..."
for theme_id in $THEMES; do
  rm -rf "$DATA_HOME/flythemes/$theme_id"
  rm -f "$DATA_HOME/color-schemes/$theme_id.colors"
done
rm -f "$SWITCH" "$APPLY" "$X11" \
      "$AUTOSTART_DIR/fly-theme-switch.desktop" \
      "$CONFIG_FILE"

# --- вернуть исходное оформление ---
if [ -f "$BACKUP_DIR/fly-admin-themerc" ]; then
  info "Восстановление исходной темы из бэкапа..."
  cp "$BACKUP_DIR/fly-admin-themerc" "$CONFIG_HOME/fly-admin-themerc"
  if [ -f "$BACKUP_DIR/paletterc" ]; then
    cp "$BACKUP_DIR/paletterc" "$HOME/.fly/paletterc"
  fi
  SAVED_THEME="$(cat "$BACKUP_DIR/current-theme" 2>/dev/null || true)"
  if [ -n "$SAVED_THEME" ] && [ -d "$DATA_HOME/flythemes/$SAVED_THEME" -o -d "/usr/share/flythemes/$SAVED_THEME" ]; then
    if command -v fly-select-theme >/dev/null 2>&1; then
      fly-select-theme "$SAVED_THEME" >/dev/null 2>&1 || true
    fi
  fi
  if [ -z "${DISPLAY:-}" ] || ! command -v fly-wmfunc >/dev/null 2>&1; then
    warn "нет DISPLAY/fly-wmfunc — тема применится при входе в сеанс"
  else
    # fly-select-theme обычно применяет на лету; если нет — перезапускаем WM
    sleep 1
    ACTIVE="$(sed -n 's/^CurrentTheme=//p' "$CONFIG_HOME/fly-admin-themerc" 2>/dev/null | head -1)"
    if [ "$ACTIVE" != "$SAVED_THEME" ]; then
      fly-wmfunc FLYWM_RESTART >/dev/null 2>&1 || true
      sleep 6
    fi
    if ! pgrep -x picom >/dev/null 2>&1 && ! pgrep -x compton >/dev/null 2>&1; then
      setsid /usr/bin/compton -b >/dev/null 2>&1 &
      sleep 1
    fi
  fi
  info "Исходная тема восстановлена: ${SAVED_THEME:-<неизвестно>}"
else
  warn "бэкап исходной темы не найден — текущую тему не меняю"
fi

rm -rf "$STATE_DIR"
info "Готово: тема и автосмена удалены."
