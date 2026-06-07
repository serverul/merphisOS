#!/usr/bin/env bash
# Hybrido — First Run Setup
# Se execută la primul login al utilizatorului live
# Configurează panel-urile și setările inițiale

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hybrido"
PANEL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"

# Configurare inițială: mod macOS (default)
echo "==> Hybrido First Run - Setting up macOS mode..."

mkdir -p "$CONFIG_DIR/panels"

# === macOS Panel Layout (top bar) ===
cat > "$CONFIG_DIR/panels/macos.conf" << 'PANEL_MACOS'
[Containments][1]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.plasma.folder
screen=0
wallpaperplugin=org.kde.plasma.image

[Containments][1][Applets][34]
immutability=1
plugin=org.kde.plasma.kickoff
title=Kickoff Application Launcher

[Containments][1][Applets][35]
immutability=1
plugin=org.kde.plasma.appmenu
title=Global Menu

[Containments][1][Applets][37]
immutability=1
plugin=org.kde.plasma.systemtray
title=System Tray

[Containments][1][Applets][38]
immutability=1
plugin=org.kde.plasma.digitalclock
title=Digital Clock

[Containments][1][General]
alignment=1
floating=true
hiding=0
offset=0
screenSpacing=0
showOnlyOnCurrent=true

[Containments][2]
formfactor=2
location=4
plugin=org.kde.plasma.private.grouping

[Containments][2][Applets][42]
immutability=1
plugin=org.kde.plasma.mediacontroller
title=Media Player
PANEL_MACOS

# === Windows Panel Layout (bottom taskbar) ===
cat > "$CONFIG_DIR/panels/windows.conf" << 'PANEL_WIN'
[Containments][1]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=3
plugin=org.kde.plasma.folder
screen=0
wallpaperplugin=org.kde.plasma.image

[Containments][1][Applets][34]
immutability=1
plugin=org.kde.plasma.kickoff
title=Application Launcher

[Containments][1][Applets][35]
immutability=1
plugin=org.kde.plasma.icontasks
title=Task Manager

[Containments][1][Applets][37]
immutability=1
plugin=org.kde.plasma.systemtray
title=System Tray

[Containments][1][Applets][38]
immutability=1
plugin=org.kde.plasma.digitalclock
title=Digital Clock

[Containments][1][General]
alignment=0
floating=false
hiding=2
offset=0
screenSpacing=0
showOnlyOnCurrent=true
PANEL_WIN

# Aplică layout-ul macOS ca default
cp "$CONFIG_DIR/panels/macos.conf" "$PANEL_CONFIG"

# Setează modul curent
echo "macos" > "$CONFIG_DIR/mode.conf"

echo "✅ Hybrido configured - macOS mode (default)"
echo "ℹ️  Run 'switch-mode.sh' or 'switch-mode windows' to change"
