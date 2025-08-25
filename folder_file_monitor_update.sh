#!/bin/bash

# Enhanced update for users who already have the monitor running
# Run with: bash folder_file_monitor_update.sh

echo "Updating to Enhanced Folder File Monitor..."
echo "==========================================="

# Enhanced logging with timestamp
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_with_timestamp "Starting enhanced update process"

# Check if monitor is installed
if [ ! -f ~/Scripts/folder_file_monitor.sh ]; then
    echo "❌ ERROR: Folder File Monitor not found"
    echo "   Install first using: install_folder_file_monitor.sh"
    exit 1
fi

# Backup current configuration and database
if [ -f ~/.folder_monitor_config ]; then
    cp ~/.folder_monitor_config ~/.folder_monitor_config.backup.$(date +%Y%m%d_%H%M%S)
    log_with_timestamp "Configuration backed up"
fi

if [ -f ~/Logs/folder_file_monitor.db ]; then
    cp ~/Logs/folder_file_monitor.db ~/Logs/folder_file_monitor.db.backup.$(date +%Y%m%d_%H%M%S)
    log_with_timestamp "Database backed up"
fi

# Stop current instance
log_with_timestamp "Stopping current monitor"
~/Scripts/folder_file_monitor.sh stop 2>/dev/null || true
sleep 3

# Download and update script with enhanced directory monitoring
log_with_timestamp "Downloading enhanced script with directory monitoring"
if ! curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor.sh -o ~/Scripts/folder_file_monitor.sh; then
    echo "❌ ERROR: Could not download enhanced update"
    echo "   Check internet connection and try again"
    exit 1
fi

chmod +x ~/Scripts/folder_file_monitor.sh
log_with_timestamp "Enhanced script updated successfully"

# Update LaunchAgent for better performance
log_with_timestamp "Updating LaunchAgent configuration"
if [ -f ~/Library/LaunchAgents/com.user.folder.filemonitor.plist ]; then
    # Add Nice priority for better performance
    if ! grep -q "<key>Nice</key>" ~/Library/LaunchAgents/com.user.folder.filemonitor.plist; then
        # Create enhanced plist
        cat > ~/Library/LaunchAgents/com.user.folder.filemonitor.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.folder.filemonitor</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/Users/USER_HOME/Scripts/folder_file_monitor.sh</string>
        <string>daemon</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    
    <key>StandardOutPath</key>
    <string>/Users/USER_HOME/Logs/folder_launchd.log</string>
    
    <key>StandardErrorPath</key>
    <string>/Users/USER_HOME/Logs/folder_launchd_error.log</string>
    
    <key>WorkingDirectory</key>
    <string>/Users/USER_HOME</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key>
        <string>/Users/USER_HOME</string>
    </dict>
    
    <key>ProcessType</key>
    <string>Background</string>
    
    <key>LowPriorityIO</key>
    <true/>
    
    <key>ThrottleInterval</key>
    <integer>1</integer>
    
    <key>Nice</key>
    <integer>1</integer>
</dict>
</plist>
EOF
        
        # Replace USER_HOME with actual home directory
        sed -i '' "s|USER_HOME|$(whoami)|g" ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
        log_with_timestamp "LaunchAgent configuration enhanced"
    fi
fi

# Restart enhanced service
log_with_timestamp "Restarting enhanced service"
launchctl unload ~/Library/LaunchAgents/com.user.folder.filemonitor.plist 2>/dev/null || true
sleep 1
launchctl load ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
sleep 3

# Verify enhanced functionality
log_with_timestamp "Verifying enhanced installation"
~/Scripts/folder_file_monitor.sh status

echo ""
echo "ENHANCED UPDATE COMPLETED"
echo "========================="
echo "Monitor has been updated with enhanced directory monitoring features:"
echo ""
echo "✅ Full file and directory paths in logs and status displays"
echo "✅ Enhanced date/time error logging"
echo "✅ Status shows last 7 days by default"
echo "✅ Recent command now accepts hours parameter"
echo "✅ Complete event tracking: CREATED, MODIFIED, DELETED"
echo "✅ Advanced event filtering with pipe separator (|)"
echo "✅ Directory monitoring with nested folder creation support"
echo "✅ All file types including .key, .pem, .crt, and other extensions"
echo "✅ Real-time updates with instant event detection (0.1s latency)"
echo "✅ Enhanced database schema with file_type tracking"
echo "✅ Improved LaunchAgent configuration for better performance"
echo ""
echo "🎯 New enhanced command examples:"
echo "   ~/Scripts/folder_file_monitor.sh status                    # Last 7 days, all events"
echo "   ~/Scripts/folder_file_monitor.sh status modified          # Last 7 days, modified only"  
echo "   ~/Scripts/folder_file_monitor.sh status created|deleted   # Last 7 days, created and deleted"
echo "   ~/Scripts/folder_file_monitor.sh recent                   # Last 24 hours, all events"
echo "   ~/Scripts/folder_file_monitor.sh recent 6                 # Last 6 hours, all events"
echo "   ~/Scripts/folder_file_monitor.sh recent 6 created         # Last 6 hours, created only"
echo "   ~/Scripts/folder_file_monitor.sh recent 6 modified|deleted # Last 6 hours, modified and deleted"
echo ""
echo "🧪 Test enhanced features:"
echo "   1. mkdir ~/test_update && echo 'test' > ~/test_update/file.key"
echo "   2. mkdir ~/test_update/nested/deep"
echo "   3. ~/Scripts/folder_file_monitor.sh recent 1"
echo "   4. Notice 📁 for directories and 📄 for files"
echo "   5. ~/Scripts/folder_file_monitor.sh recent 1 created"
echo ""
echo "Configured directories maintained in: ~/.folder_monitor_config"
log_with_timestamp "Enhanced update process completed successfully"
