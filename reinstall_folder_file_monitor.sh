#!/bin/bash

# Reinstallation Script - Folder File Monitor with Database Backup
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
DB_FILE="$HOME/Logs/folder_file_monitor.db"

# Function to create database backup
create_database_backup() {
    if [ -f "$DB_FILE" ]; then
        local backup_timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_name="folder_file_monitor_${backup_timestamp}.backup"
        local backup_file="$HOME/Logs/${backup_name}"
        local compressed_backup="$HOME/Logs/${backup_name}.tar.gz"
        
        log_with_timestamp "Creating database backup"
        
        # Copy database to backup file
        cp "$DB_FILE" "$backup_file"
        
        # Compress the backup
        tar -czf "$compressed_backup" -C "$HOME/Logs" "$backup_name"
        
        # Remove uncompressed backup
        rm -f "$backup_file"
        
        if [ -f "$compressed_backup" ]; then
            log_with_timestamp "Database backup created: $compressed_backup"
            echo "✅ Database backup: $compressed_backup"
            echo "📊 Backup size: $(du -h "$compressed_backup" | cut -f1)"
            return 0
        else
            log_with_timestamp "ERROR: Failed to create database backup"
            echo "❌ Failed to create database backup"
            return 1
        fi
    else
        log_with_timestamp "No existing database found, skipping backup"
        echo "ℹ️  No existing database found, skipping backup"
        return 0
    fi
}

# Check arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [DIRECTORY_TO_MONITOR]"
    echo ""
    echo "Options:"
    echo "  DIRECTORY_TO_MONITOR   New directory to monitor (optional)"
    echo "  --help, -h             Show this help"
    echo ""
    echo "Enhanced Features:"
    echo "  ✅ Full file and directory paths in all displays"
    echo "  ✅ Enhanced date/time error logging"
    echo "  ✅ Status shows last 7 days by default"
    echo "  ✅ Recent command with hours parameter"
    echo "  ✅ Complete event tracking: CREATED, MODIFIED, DELETED"
    echo "  ✅ Directory monitoring with nested folder support"
    echo "  ✅ All file types including .key files"
    echo "  ✅ Real-time updates with instant event detection"
    echo "  ✅ Automatic database backup during reinstall"
    echo ""
    echo "Examples:"
    echo "  $0 /Users/$(whoami)/Documents/my-project"
    echo "
