#!/bin/bash

# Simple update for users who already have the monitor running
# Run with: bash folder_file_monitor_update.sh

echo "Updating Folder File Monitor..."
echo "==============================="

# Restart with new configuration
~/Scripts/folder_file_monitor.sh stop
sleep 2

# Update script with new version
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor.sh -o ~/Scripts/folder_file_monitor.sh
chmod +x ~/Scripts/folder_file_monitor.sh

# Restart automatic service
launchctl unload ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
launchctl load ~/Library/LaunchAgents/com.user.folder.filemonitor.plist

# Verify it works
sleep 3
~/Scripts/folder_file_monitor.sh status

echo ""
echo "UPDATE COMPLETED"
echo "================"
echo "Monitor has been updated and restarted"
echo "Configured directories are maintained in: ~/.folder_monitor_config"
