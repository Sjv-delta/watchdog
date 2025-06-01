#!/data/data/com.termux/files/usr/bin/bash

LOGFILE="$HOME/storage/downloads/comp_check_live.txt"

echo "🐺 WATCHDOG DAEMON STARTED $(date)" >> "$LOGFILE"

while true; do
    echo -e "\n🔍 [$(date)] Running scan..." >> "$LOGFILE"

    # Kill common sketchy processes
    for proc in "tcpdump" "keylog" "spy" "ncat" "nc" "sniff"; do
        if pgrep -f "$proc" >/dev/null 2>&1; then
            echo "[!] Found & killed: $proc" >> "$LOGFILE"
            pkill -9 "$proc"
        fi
    done

    # Remove rogue 'su' binaries outside system dirs
    find / -type f -name "su" 2>/dev/null | grep -v "/system/bin/su" | while read line; do
        echo "[!] Rogue su binary detected & removed: $line" >> "$LOGFILE"
        rm -f "$line"
    done

    echo "[+] Sleeping 5 minutes..." >> "$LOGFILE"
    sleep 300
done
