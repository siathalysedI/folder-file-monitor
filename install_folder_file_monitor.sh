#!/bin/bash

# Automatic Installer - Enhanced File and Folder Monitor for Multiple Directories
# Run with: bash install_folder_file_monitor.sh

set -e  # Stop on any error

echo "Installing Enhanced Folder File Monitor..."
echo "========================================="

# Configuration variables
SCRIPT_DIR="$HOME/Scripts"
LOG_DIR="$HOME/Logs"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
SCRIPT_FILE="$SCRIPT_DIR/folder_file_monitor.sh"
PLIST_FILE="$LAUNCH_AGENTS_DIR/com.user.folder.filemonitor.plist"
CONFIG_FILE="$HOME/.folder_monitor_config"

# Function to add directory to configuration
add_directory() {
    local dir="$1"
    # Expand ~ if used
    dir="${dir/#\~/$HOME}"
    
    # Verify directory exists
    if [ ! -d "$dir" ]; then
        echo "Directory does not exist: $dir"
        read -p "Do you want to create it? (y/N): " create_dir
        if [[ $create_dir =~ ^[Yy]$ ]]; then
            mkdir -p "$dir"
            echo "Directory created: $dir"
        else
            return 1
        fi
    fi
    
    # Verify it's not already in configuration
    if [ -f "$CONFIG_FILE" ] && grep -Fxq "$dir" "$CONFIG_FILE"; then
        echo "Directory is already configured: $dir"
        return 0
    fi
    
    # Add to configuration
    echo "$dir" >> "$CONFIG_FILE"
    echo "Directory added: $dir"
    return 0
}

# Function to configure directories
setup_directories() {
    if [ -n "$1" ]; then
        # If a directory was passed as parameter
        add_directory "$1"
    else
        # Request directories interactively
        echo ""
        echo "Directory configuration to monitor"
        echo "You can add multiple directories."
        echo ""
        
        while true; do
            read -p "Directory to monitor (Enter to finish): " dir
            if [ -z "$dir" ]; then
                break
            fi
            add_directory "$dir"
        done
    fi
    
    # Verify at least one was configured
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        echo "ERROR: You must configure at least one directory"
        exit 1
    fi
    
    echo ""
    echo "Configured directories:"
    cat -n "$CONFIG_FILE"
}

# Check help arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [DIRECTORY]"
    echo ""
    echo "Options:"
    echo "  DIRECTORY   Directory to monitor (optional)"
    echo "  --help, -h  Show this help"
    echo ""
    echo "Enhanced Features:"
    echo "  ✅ Monitors BOTH files AND folders"
    echo "  ✅ Real-time detection with 0.1s latency"
    echo "  ✅ Tracks nested folder creation
