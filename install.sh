#!/data/data/com.termux/files/usr/bin/bash

# Paths
WDIR="$HOME/.watchdog"
DAEMON="$WDIR/watchdogd.sh"
LOGFILE="$HOME/storage/downloads/comp_check_live.txt"

# Setup storage access so script can write to Downloads
termux-setup-storage

# Create watchdog folder
mkdir -p "$WDIR"

# Update and install required packages
pkg update -y
pkg install -y tsu curl grep findutils net-tools lsof

# Write watchdog daemon script
cat > "$DAEMON" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

LOGFILE="$HOME/storage/downloads/comp_check_live.txt"

echo "🐺 WATCHDOG DAEMON STARTED $(date)" >> "$LOGFILE"

while true; do
    echo -e "\n🔍 [$(date)] Running scan..." >> "$LOGFILE"

    # Kill common suspicious processes immediately
    for proc in "tcpdump" "keylog" "spy" "ncat" "nc" "sniff" "metasploit" "backdoor"; do
        if pgrep -f "$proc" >/dev/null 2>&1; then
            echo "[!] Found & killed suspicious process: $proc" >> "$LOGFILE"
            pkill -9 "$proc"
        fi
    done

    # Detect and remove rogue 'su' binaries outside system dirs
    find / -type f -name "su" 2>/dev/null | grep -v "/system/bin/su" | grep -v "/system/xbin/su" | while read -r rogue_su; do
        echo "[!] Rogue 'su' binary detected & removed: $rogue_su" >> "$LOGFILE"
        rm -f "$rogue_su"
    done

    # Check for suspicious writable files (777 or 666 permissions)
    find /data -type f \( -perm 0777 -o -perm 0666 \) 2>/dev/null | while read -r suspicious_file; do
        echo "[!] Suspicious writable file found: $suspicious_file" >> "$LOGFILE"
    done

    # Hidden files/folders in /data/local/tmp and /sdcard
    find /data/local/tmp /sdcard -name ".*" 2>/dev/null | while read -r hidden_file; do
        echo "[!] Hidden file/folder detected: $hidden_file" >> "$LOGFILE"
    done

    # Active network connections except localhost
    netstat -tunp 2>/dev/null | grep -vE "(127\.0\.0\.1|::1|localhost)" | grep -v "LISTEN" | while read -r conn; do
        echo "[!] Active network connection: $conn" >> "$LOGFILE"
    done

    # Suspicious crontab entries with wget, curl, bash, sh
    crontab -l 2>/dev/null | grep -E "(wget|curl|bash|sh)" >> "$LOGFILE" 2>/dev/null

    echo "[+] Sleeping 3 minutes..." >> "$LOGFILE"
    sleep 180
done
EOF

# Make watchdog executable
chmod +x "$DAEMON"

# Start watchdog in background
nohup bash "$DAEMON" >/dev/null 2>&1 &

echo "✅ Watchdog installed and running!"
echo "Logs saved to: $LOGFILE"
echo "Use 'tail -f $LOGFILE' to watch live logs."
