#!/data/data/com.termux/files/usr/bin/bash

WDIR="$HOME/.watchdog"
DAEMON="$WDIR/watchdogd.sh"
LOGFILE="$HOME/storage/downloads/comp_check_live.txt"
REPO_RAW_BASE="https://raw.githubusercontent.com/Sjv-delta/watchdog/main"

termux-setup-storage

mkdir -p "$WDIR"

pkg update -y
pkg install -y tsu curl grep findutils net-tools lsof coreutils

# Download latest watchdogd.sh from GitHub
curl -s "$REPO_RAW_BASE/watchdogd.sh" -o "$DAEMON"

chmod +x "$DAEMON"

# Start watchdog daemon (kill any old first)
pkill -f watchdogd.sh >/dev/null 2>&1 || true
nohup bash "$DAEMON" >/dev/null 2>&1 &

echo "✅ Watchdog installed and running!"
echo "Logs saved to: $LOGFILE"
echo "Run 'tail -f $LOGFILE' to watch live logs."
