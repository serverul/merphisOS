#!/usr/bin/env bash
# Hybrido — Switch Mode Script v2 (Plasma 6 / Wayland)
# Comută între modul macOS și Windows
set -euo pipefail

MODE="${1:-}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hybrido"
MODE_FILE="${CONFIG_DIR}/mode.conf"
PANEL_BACKUP="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
PANEL_MACOS="${CONFIG_DIR}/panels/macos.conf"
PANEL_WINDOWS="${CONFIG_DIR}/panels/windows.conf"

# Culoare: redefinește echo cu culori
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII art pentru mod
show_art() {
    local mode="$1"
    if [ "$mode" = "macos" ]; then
        echo -e "${CYAN}"
        echo "  ╭──────────────────────────╮"
        echo "  │    macOS Mode          │"
        echo "  ╰──────────────────────────╯"
        echo -e "${NC}"
    else
        echo -e "${GREEN}"
        echo "  ╭──────────────────────────╮"
        echo "  │    Windows Mode        │"
        echo "  ╰──────────────────────────╯"
        echo -e "${NC}"
    fi
}

# Detectează modul curent dacă nu s-a specificat unul
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
    echo ""
    echo "  Fără argument: comută între moduri (toggle)"
    echo "  $0 macos   → mod macOS"
    echo "  $0 windows → mod Windows"
    exit 1
fi

show_art "$MODE"
echo -e " Switching Hybrido to ${CYN}${MODE}${NC} mode..."
echo ""

mkdir -p "$CONFIG_DIR/panels"
echo "$MODE" > "$MODE_FILE"

# Verifică ce tools avem disponibile
HAS_KWRITE6=$(command -v kwriteconfig6 &>/dev/null && echo "yes" || echo "no")
HAS_QDBUS=$(command -v qdbus6 &>/dev/null && echo "yes" || echo "no")

case "$MODE" in
    macos)
        echo "   → Applying macOS theme..."

        # Tema desktop
        plasma-apply-desktoptheme hybrido-macos 2>/dev/null || \
            echo "   ⚠️  Theme 'hybrido-macos' not found, skipping"

        # Decorațiuni ferestre (butoane în stânga — macOS style)
        if [ "$HAS_KWRITE6" = "yes" ]; then
            kwriteconfig6 --file ~/.config/kwinrc \
                --group "org.kde.kdecoration2" \
                --key "library" "org.kde.hybrido-macos" 2>/dev/null || true
            # Butoane în stânga ca macOS
            kwriteconfig6 --file ~/.config/kwinrc \
                --group "org.kde.kdecoration2" \
                --key "CloseOnLeft" "false" 2>/dev/null || true
            kwriteconfig6 --file ~/.config/kwinrc \
                --group "org.kde.kdecoration2" \
                --key "BorderlessMaximizedWindows" "false" 2>/dev/null || true
        fi

        # Layout panel macOS (top bar + dock)
        echo "   → Applying macOS panel layout (top bar + dock)..."
        if [ -f "$PANEL_MACOS" ]; then
            cp "$PANEL_MACOS" "$PANEL_BACKUP"
        else
            echo "   ⚠️  macOS panel layout not found at $PANEL_MACOS"
            echo "   → Using default macOS panel via kwriteconfig6"
            if [ "$HAS_KWRITE6" = "yes" ]; then
                # Configurează panel-ul de sus
                kwriteconfig6 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
                    --group "Containments" --group "1" \
                    --key "formfactor" "2" 2>/dev/null || true
                kwriteconfig6 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
                    --group "Containments" --group "1" \
                    --key "location" "4" 2>/dev/null || true  # 4 = top
                kwriteconfig6 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
                    --group "Containments" --group "1" \
                    --key "alignment" "1" 2>/dev/null || true  # center
            fi
        fi

        # Keyboard shortcuts macOS-style
        if [ "$HAS_KWRITE6" = "yes" ]; then
            kwriteconfig6 --file ~/.config/kdeglobals \
                --group "General" \
                --key "ModifierOnlyShortcuts" "Meta" 2>/dev/null || true
        fi

        echo -e "   ${GREEN}✅${NC} macOS theme applied"
        echo "   Tip: Cmd+Space = Spotlight (KRunner)"
        echo "   Tip: Butoanele ferestrelor sunt în stânga (● ● ●)"
        ;;

    windows)
        echo "   → Applying Windows theme..."

        # Tema desktop
        plasma-apply-desktoptheme hybrido-windows 2>/dev/null || \
            echo "   ⚠️  Theme 'hybrido-windows' not found, skipping"

        # Decorațiuni ferestre (butoane în dreapta — Windows style)
        if [ "$HAS_KWRITE6" = "yes" ]; then
            kwriteconfig6 --file ~/.config/kwinrc \
                --group "org.kde.kdecoration2" \
                --key "library" "org.kde.hybrido-windows" 2>/dev/null || true
            # Butoane în dreapta ca Windows
            kwriteconfig6 --file ~/.config/kwinrc \
                --group "org.kde.kdecoration2" \
                --key "CloseOnLeft" "false" 2>/dev/null || true
            kwriteconfig6 --file ~/.config/kwinrc \
                --group "org.kde.kdecoration2" \
                --key "BorderlessMaximizedWindows" "true" 2>/dev/null || true
        fi

        # Layout panel Windows (bottom taskbar)
        echo "   → Applying Windows panel layout (bottom taskbar)..."
        if [ -f "$PANEL_WINDOWS" ]; then
            cp "$PANEL_WINDOWS" "$PANEL_BACKUP"
        else
            echo "   ⚠️  Windows panel layout not found at $PANEL_WINDOWS"
            if [ "$HAS_KWRITE6" = "yes" ]; then
                kwriteconfig6 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
                    --group "Containments" --group "1" \
                    --key "formfactor" "2" 2>/dev/null || true
                kwriteconfig6 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
                    --group "Containments" --group "1" \
                    --key "location" "3" 2>/dev/null || true  # 3 = bottom
                kwriteconfig6 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
                    --group "Containments" --group "1" \
                    --key "alignment" "0" 2>/dev/null || true  # left
            fi
        fi

        echo -e "   ${GREEN}✅${NC} Windows theme applied"
        echo "   Tip: Win = Start Menu"
        echo "   Tip: Win+E = Nemo (File Explorer)"
        ;;

esac

# Reîncarcă KWin (Wayland safe)
if [ "$HAS_QDBUS" = "yes" ]; then
    echo "   → Reloading KWin via DBus..."
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
else
    # Fallback: repornește KWin în background
    echo "   → Reloading KWin (Wayland)..."
    kwin_wayway --replace 2>/dev/null &
    disown
fi

# Reîncarcă shell-ul Plasma
echo "   → Restarting Plasma shell..."
plasmashell --replace 2>/dev/null &
disown
sleep 1

# Notificare
echo ""
echo -e " ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " ${GREEN}✅${NC} Hybrido switched to ${CYN}${MODE}${NC} mode!"
echo -e " ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

notify-send "Hybrido" "Mode switched to ${MODE}" \
    --icon=preferences-desktop-theme \
    --urgency=low 2>/dev/null || true
