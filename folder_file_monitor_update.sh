#!/bin/bash

# Simple update for users who already have the monitor running
# Run with: bash folder_file_monitor_update.sh

echo "Updating Folder File Monitor..."
echo "==============================="

# Enhanced logging with timestamp
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_with_timestamp "Starting update process"

# Check if monitor is installed
if [ ! -f ~/Scripts/folder_file_monitor.sh ]; then
    echo "❌ ERROR: Folder File Monitor not found"
    echo "   Install first using: install_folder_file_monitor.sh"
    exit 1
fi

# Backup current configuration
if [ -f ~/.folder_monitor_config ]; then
    cp ~/.folder_monitor_config ~/.folder_monitor_config.backup.$(date +%Y%m%d_%H%M%S)
    log_with_timestamp "Configuration backed up"
fi

# Stop current instance
log_with_timestamp "Stopping current monitor"
~/Scripts/folder_file_monitor.sh stop 2>/dev/null || true
sleep 2

# Download and update script with enhanced features
log_with_timestamp "Downloading updated script"
if ! curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor.sh -o ~/Scripts/folder_file_monitor.sh; then
    echo "❌ ERROR: Could not download update"
    echo "   Check internet connection and try again"
    exit 1
fi

chmod +x ~/Scripts/folder_file_monitor.sh
log_with_timestamp "Script updated successfully"

# Restart automatic service
log_with_timestamp "Restarting service"
launchctl unload ~/Library/LaunchAgents/com.user.folder.filemonitor.plist 2>/dev/null || true
sleep 1
launchctl load ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
sleep 3

# Verify it works
log_with_timestamp "Verifying installation"
~/Scripts/folder_file_monitor.sh status

echo ""
echo "UPDATE COMPLETED"
echo "================"
echo "Monitor has been updated with enhanced features:"
echo ""
echo "✅ Full file paths in logs and status displays"
echo "✅ Enhanced date/time error logging"
echo "✅ Status shows last 7 days by default"
echo "✅ Recent command now accepts hours parameter"
echo "✅ Complete event tracking: CREATED, MODIFIED, DELETED"
echo "✅ Advanced event filtering with pipe separator (|)"
echo ""
echo "New command examples:"
echo "   ~/Scripts/folder_file_monitor.sh status                    # Last 7 days, all events"
echo "   ~/Scripts/folder_file_monitor.sh status modified          # Last 7 days, modified only"  
echo "   ~/Scripts/folder_file_monitor.sh status created|deleted   # Last 7 days, created and deleted"
echo "   ~/Scripts/folder_file_monitor.sh recent                   # Last 24 hours, all events"
echo "   ~/Scripts/folder_file_monitor.sh recent 6                 # Last 6 hours, all events"
echo "   ~/Scripts/folder_file_monitor.sh recent 6 created         # Last 6 hours, created only"
echo "   ~/Scripts/folder_file_monitor.sh recent 6 modified|deleted # Last 6 hours, modified and deleted"
echo ""
echo "Configured directories maintained in: ~/.folder_monitor_config"
log_with_timestamp "Update process completed successfully"
