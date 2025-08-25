#!/bin/bash

# Reinstallation Script - Folder File Monitor
# Run with: bash reinstall_folder_file_monitor.sh

set -e  # Stop on any error

echo "Reinstalling Folder File Monitor with Enhanced Features..."
echo "=========================================================="

# Enhanced logging with timestamp
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Variables
SCRIPT_FILE="$HOME/Scripts/folder_file_monitor.sh"
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.folder.filemonitor.plist"
GITHUB_SCRIPT_URL="https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor.sh"
CONFIG_FILE="$HOME/.folder_monitor_config"

# Check arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [DIRECTORY_TO_MONITOR]"
    echo ""
    echo "Options:"
    echo "  DIRECTORY_TO_MONITOR   New directory to monitor (optional)"
    echo "  --help, -h             Show this help"
    echo ""
    echo "Enhanced Features:"
    echo "  ✅ Full file paths in all displays"
    echo "  ✅ Enhanced date/time error logging"
    echo "  ✅ Status shows last 7 days by default"
    echo "  ✅ Recent command with hours parameter"
    echo ""
    echo "Examples:"
    echo "  $0 /Users/$(whoami)/Documents/my-project"
    echo "  $0 ~/work/documents"
    echo "  $0                     # Maintains current configuration"
    exit 0
fi

log_with_timestamp "Starting enhanced reinstallation"

# Handle configuration
if [ -n "$1" ]; then
    log_with_timestamp "Updating configuration with new directory: $1"
    # Expand ~ if used
    NEW_DIR="${1/#\~/$HOME}"
    
    # Verify directory exists
    if [ ! -d "$NEW_DIR" ]; then
        echo "Directory does not exist: $NEW_DIR"
        read -p "Do you want to create it? (y/N): " create_dir
        if [[ $create_dir =~ ^[Yy]$ ]]; then
            mkdir -p "$NEW_DIR"
            log_with_timestamp "Directory created: $NEW_DIR"
        else
            echo "❌ ERROR: Required directory does not exist"
            exit 1
        fi
    fi
    
    # Backup old configuration
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        log_with_timestamp "Old configuration backed up"
    fi
    
    # Update configuration
    echo "$NEW_DIR" > "$CONFIG_FILE"
    log_with_timestamp "Configuration updated with: $NEW_DIR"
    echo ""
else
    log_with_timestamp "Maintaining existing configuration"
    if [ -f "$CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
        echo "Currently configured directories:"
        cat -n "$CONFIG_FILE"
    else
        echo "No existing configuration."
        echo "Monitor will ask for directories when run for the first time."
    fi
    echo ""
fi

# 1. Check current installation
echo "Step 1: Checking current installation..."
if [ ! -f "$SCRIPT_FILE" ]; then
    echo "❌ ERROR: Folder File Monitor is not installed"
    echo "   Run first: install_folder_file_monitor.sh"
    exit 1
fi
log_with_timestamp "Installation found"

# 2. Stop current service
echo "Step 2: Stopping current service..."
"$SCRIPT_FILE" stop 2>/dev/null || true
launchctl unload "$PLIST_FILE" 2>/dev/null || true
sleep 2
log_with_timestamp "Service stopped"

# 3. Backup current script
echo "Step 3: Creating backup..."
cp "$SCRIPT_FILE" "$SCRIPT_FILE.backup.$(date +%Y%m%d_%H%M%S)"
log_with_timestamp "Backup created"

# 4. Download new version with enhanced features
echo "Step 4: Downloading enhanced version..."
if ! curl -fsSL "$GITHUB_SCRIPT_URL" -o "$SCRIPT_FILE"; then
    echo "❌ ERROR: Could not download new version"
    echo "   Check your internet connection and repository URL"
    exit 1
fi
chmod +x "$SCRIPT_FILE"
log_with_timestamp "Enhanced version installed"

# 5. Restart service
echo "Step 5: Restarting service..."
launchctl load "$PLIST_FILE"
sleep 3
log_with_timestamp "Service restarted"

# 6. Verify functionality
echo "Step 6: Verifying enhanced functionality..."
"$SCRIPT_FILE" status

echo ""
echo "ENHANCED REINSTALLATION COMPLETED"
echo "================================="
echo ""
echo "Folder File Monitor successfully reinstalled with enhanced features:"
echo ""
echo "✅ Full file paths displayed in all commands"
echo "✅ Enhanced date/time error logging with timestamps"
echo "✅ Status command shows last 7 days by default"
echo "✅ Recent command now accepts hours parameter"
echo "✅ Complete event tracking: CREATED, MODIFIED, DELETED"
echo "✅ Advanced event filtering with pipe separator (created|modified|deleted)"
echo "✅ Improved database indexing for better performance"
echo ""
echo "Service running automatically"
echo ""
if [ -f "$CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
    echo "Current configuration:"
    cat -n "$CONFIG_FILE"
else
    echo "No configuration - monitor will ask for directories when starting"
fi
echo ""
echo "Configuration file: $CONFIG_FILE"
echo ""
echo "Enhanced command examples:"
echo "   $SCRIPT_FILE status                    - View status (last 7 days, all events)"
echo "   $SCRIPT_FILE status modified          - View only modified files (last 7 days)"
echo "   $SCRIPT_FILE status created|deleted   - View created and deleted (last 7 days)"
echo "   $SCRIPT_FILE recent                   - View last 24 hours (all events)"
echo "   $SCRIPT_FILE recent 6                 - View last 6 hours (all events)"
echo "   $SCRIPT_FILE recent 6 created         - View last 6 hours (created only)"
echo "   $SCRIPT_FILE recent 6 modified|deleted - View last 6 hours (modified and deleted)"
echo "   $SCRIPT_FILE add                      - Add more directories"
echo "   $SCRIPT_FILE list                     - View configured directories"
echo "   $SCRIPT_FILE export                   - Export data with full paths"
echo ""
echo "Test the enhanced features:"
echo "   1. Modify some file in the configured directories"
echo "   2. Wait a few seconds"
echo "   3. Run: $SCRIPT_FILE recent 1"
echo "   4. Notice the full file paths and precise timestamps"
echo "   5. Test filtering: $SCRIPT_FILE recent 1 modified"
echo "   6. Test combination: $SCRIPT_FILE recent 1 created|modified"
echo ""
log_with_timestamp "Enhanced reinstallation completed successfully"
