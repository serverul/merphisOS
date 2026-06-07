#!/usr/bin/env bash
# Hybrido — Switch Mode Script
# Comută între modul macOS și Windows
set -euo pipefail

MODE="${1:-}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hybrido"
MODE_FILE="${CONFIG_DIR}/mode.conf"

# Detectează modul curent
if [ -z "$MODE" ]; then
    if [ -f "$MODE_FILE" ]; then
        CURRENT_MODE=$(cat "$MODE_FILE")
        if [ "$CURRENT_MODE" = "macos" ]; then
            MODE="windows"
        else
            MODE="macos"
        fi
    else
        MODE="macos"  # Default
    fi
fi

# Validare
if [ "$MODE" != "macos" ] && [ "$MODE" != "windows" ]; then
    echo "Usage: $0 [macos|windows]"
    exit 1
fi

echo "==> Switching Hybrido to ${MODE} mode..."

mkdir -p "$CONFIG_DIR"
echo "$MODE" > "$MODE_FILE"

case "$MODE" in
    macos)
        echo "   → Applying macOS theme..."
        # Setează tema globală
        plasma-apply-desktoptheme hybrido-macos 2>/dev/null || true
        # Setează decorațiuni ferestre (butoane stânga)
        kwriteconfig5 --file ~/.config/kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.hybrido-macos" 2>/dev/null || true
        # Reîncarcă panel layout macOS
        # (layout-urile se aplică prin fișiere .plasmoid în ~/.local/share/plasma/layouts/)
        echo "   → Panel: macOS layout"
        # Keyboard shortcuts macOS-style
        kwriteconfig5 --file ~/.config/kcminputrc --group "Keyboard" --key "Layout" "macos" 2>/dev/null || true
        ;;

    windows)
        echo "   → Applying Windows theme..."
        plasma-apply-desktoptheme hybrido-windows 2>/dev/null || true
        kwriteconfig5 --file ~/.config/kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.hybrido-windows" 2>/dev/null || true
        echo "   → Panel: Windows layout"
        kwriteconfig5 --file ~/.config/kcminputrc --group "Keyboard" --key "Layout" "windows" 2>/dev/null || true
        ;;
esac

# Reîncarcă KWin pentru a aplica schimbările
kwin_x11 --replace &>/dev/null || kwin_wayland --replace &>/dev/null || true

# Reîncarcă shell-ul Plasma
killall -HUP plasmashell 2>/dev/null || true

echo "✅ Hybrido switched to ${MODE} mode!"
notify-send "Hybrido" "Mod schimbat în ${MODE} mode" --icon=preferences-desktop-theme 2>/dev/null || true
