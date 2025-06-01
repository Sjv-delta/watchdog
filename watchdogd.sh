#!/data/data/com.termux/files/usr/bin/bash

WDIR="$HOME/.watchdog"
DAEMON="$WDIR/watchdogd.sh"
LOGFILE="$HOME/storage/downloads/comp_check_live.txt"
REPO_RAW_BASE="https://raw.githubusercontent.com/Sjv-delta/watchdog/main"

echo "🐺 WATCHDOG DAEMON STARTED $(date)" >> "$LOGFILE"

while true; do
    echo -e "\n🔍 [$(date)] Running aggressive scan..." >> "$LOGFILE"

    # Kill suspicious processes aggressively
    for proc in "tcpdump" "keylog" "spy" "ncat" "nc" "sniff" "metasploit" "backdoor" "ssh" "telnet" "perl" "python" "ruby"; do
        if pgrep -f "$proc" >/dev/null 2>&1; then
            echo "[!] Killed suspicious process: $proc" >> "$LOGFILE"
            pkill -9 "$proc"
        fi
    done

    # Detect rogue 'su' binaries outside system dirs
    find / -type f -name "su" 2>/dev/null | grep -v "/system/bin/su" | grep -v "/system/xbin/su" | while read -r rogue_su; do
        echo "[!] Rogue 'su' binary removed: $rogue_su" >> "$LOGFILE"
        rm -f "$rogue_su"
    done

    # Suspicious writable files (777 or 666 perms)
    find /data -type f \( -perm 0777 -o -perm 0666 \) 2>/dev/null | while read -r file; do
        echo "[!] Suspicious writable file: $file" >> "$LOGFILE"
    done

    # Hidden files in /data/local/tmp and /sdcard
    find /data/local/tmp /sdcard -name ".*" 2>/dev/null | while read -r hidden; do
        echo "[!] Hidden file/folder detected: $hidden" >> "$LOGFILE"
    done

    # Active non-localhost network connections
    netstat -tunp 2>/dev/null | grep -vE "(127\.0\.0\.1|::1|localhost)" | grep -v "LISTEN" | while read -r conn; do
        echo "[!] Active network connection: $conn" >> "$LOGFILE"
    done

    # Suspicious cron jobs with curl/wget/bash/sh
    crontab -l 2>/dev/null | grep -E "(wget|curl|bash|sh)" >> "$LOGFILE" 2>/dev/null

    # Check for rootkit signs — example with common suspicious filenames
    rootkit_files=(
        "/usr/bin/.etc" "/usr/bin/.sshd" "/usr/bin/.lib" "/tmp/.x" "/dev/.lib"
    )
    for f in "${rootkit_files[@]}"; do
        if [ -f "$f" ]; then
            echo "[!!!] Possible rootkit file detected: $f" >> "$LOGFILE"
            rm -f "$f" && echo "[!!!] Rootkit file $f deleted" >> "$LOGFILE"
        fi
    done

    # Auto-update: fetch latest watchdogd.sh and restart if changed
    TMPFILE="$WDIR/watchdogd.sh.tmp"
    curl -s "$REPO_RAW_BASE/watchdogd.sh" -o "$TMPFILE"
    if ! cmp -s "$TMPFILE" "$DAEMON"; then
        echo "[+] New version found — updating watchdog daemon..." >> "$LOGFILE"
        mv "$TMPFILE" "$DAEMON"
        chmod +x "$DAEMON"
        echo "[+] Restarting watchdog daemon..." >> "$LOGFILE"
        exec bash "$DAEMON"
        exit 0
    else
        rm "$TMPFILE"
    fi

    echo "[+] Scan complete. Sleeping 3 minutes..." >> "$LOGFILE"
    sleep 180
done
