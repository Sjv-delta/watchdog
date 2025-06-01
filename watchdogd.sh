#!/data/data/com.termux/files/usr/bin/bash

WDIR="$HOME/.watchdog"
DAEMON="$WDIR/watchdogd.sh"
LOGFILE="$HOME/storage/downloads/comp_check_live.txt"
REPO_RAW_BASE="https://raw.githubusercontent.com/Sjv-delta/watchdog/main"

echo "🐺 WATCHDOG DAEMON STARTED $(date)" >> "$LOGFILE"

cleanup_and_harden() {
    echo "[*] Starting cleanup and hardening at $(date)" >> "$LOGFILE"

    # Kill suspicious processes
    for proc in "tcpdump" "keylog" "spy" "ncat" "nc" "sniff" "metasploit" "backdoor" "ssh" "telnet" "perl" "python" "ruby"; do
        if pgrep -f "$proc" >/dev/null 2>&1; then
            echo "[!] Killed suspicious process: $proc" >> "$LOGFILE"
            pkill -9 "$proc"
        fi
    done

    # Remove rogue su binaries outside legit dirs
    find / -type f -name "su" 2>/dev/null | grep -vE "/system/(bin|xbin)/su" | while read -r rogue_su; do
        echo "[!] Removing rogue su binary: $rogue_su" >> "$LOGFILE"
        rm -f "$rogue_su"
    done

    # Reset suspicious permissions (777, 666) in /data
    find /data -type f \( -perm 0777 -o -perm 0666 \) 2>/dev/null | while read -r file; do
        echo "[!] Resetting permissions for: $file" >> "$LOGFILE"
        chmod 644 "$file"
    done

    # Remove hidden suspicious files in tmp & sdcard
    find /data/local/tmp /sdcard -name ".*" 2>/dev/null | while read -r hidden; do
        echo "[!] Removing hidden file/folder: $hidden" >> "$LOGFILE"
        rm -rf "$hidden"
    done

    # Close all non-localhost network connections forcibly
    netstat -tunp 2>/dev/null | grep -vE "(127\.0\.0\.1|::1|localhost)" | awk '{print $7}' | grep -E "[0-9]+/.*" | cut -d'/' -f1 | while read -r pid; do
        echo "[!] Killing process with network connection: PID $pid" >> "$LOGFILE"
        kill -9 "$pid"
    done

    # Remove suspicious cron jobs with curl/wget/bash/sh
    crontab -l 2>/dev/null | grep -E "(wget|curl|bash|sh)" | while read -r job; do
        echo "[!] Removing suspicious cron job: $job" >> "$LOGFILE"
        (crontab -l | grep -vF "$job") | crontab -
    done

    # Remove known rootkit files
    rootkit_files=(
        "/usr/bin/.etc" "/usr/bin/.sshd" "/usr/bin/.lib" "/tmp/.x" "/dev/.lib"
    )
    for f in "${rootkit_files[@]}"; do
        if [ -f "$f" ]; then
            echo "[!!!] Removing rootkit file: $f" >> "$LOGFILE"
            rm -f "$f"
        fi
    done

    echo "[*] Cleanup and hardening complete at $(date)" >> "$LOGFILE"
}

aggressive_scan() {
    echo "[*] Running aggressive scan at $(date)" >> "$LOGFILE"

    # Check suspicious writable files
    find /data -type f \( -perm 0777 -o -perm 0666 \) 2>/dev/null | while read -r file; do
        echo "[!] Suspicious writable file detected: $file" >> "$LOGFILE"
    done

    # Hidden files in tmp & sdcard
    find /data/local/tmp /sdcard -name ".*" 2>/dev/null | while read -r hidden; do
        echo "[!] Hidden file/folder detected: $hidden" >> "$LOGFILE"
    done

    # Active non-localhost connections
    netstat -tunp 2>/dev/null | grep -vE "(127\.0\.0\.1|::1|localhost)" | grep -v "LISTEN" | while read -r conn; do
        echo "[!] Active suspicious network connection: $conn" >> "$LOGFILE"
    done

    # Check cron jobs
    crontab -l 2>/dev/null | grep -E "(wget|curl|bash|sh)" >> "$LOGFILE" 2>/dev/null

    echo "[*] Aggressive scan complete at $(date)" >> "$LOGFILE"
}

auto_update() {
    echo "[*] Checking for updates at $(date)" >> "$LOGFILE"
    TMPFILE="$WDIR/watchdogd.sh.tmp"
    curl -s "$REPO_RAW_BASE/watchdogd.sh" -o "$TMPFILE"
    if ! cmp -s "$TMPFILE" "$DAEMON"; then
        echo "[+] New version detected — updating..." >> "$LOGFILE"
        mv "$TMPFILE" "$DAEMON"
        chmod +x "$DAEMON"
        echo "[+] Restarting daemon..." >> "$LOGFILE"
        exec bash "$DAEMON"
        exit 0
    else
        rm "$TMPFILE"
    fi
}

while true; do
    cleanup_and_harden
    aggressive_scan
    auto_update
    echo "[*] Sleeping 3 minutes at $(date)" >> "$LOGFILE"
    sleep 180
done
