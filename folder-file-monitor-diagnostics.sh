#!/bin/bash

# ENHANCED DIAGNOSTICS - FOLDER FILE MONITOR with DIRECTORY SUPPORT
# Run these commands to find problems with enhanced details
# Includes directory monitoring verification and instant detection testing

echo "🔍 ENHANCED FOLDER FILE MONITOR DIAGNOSTICS"
echo "============================================"
echo "Diagnostic started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "System: $(uname -s) $(uname -r)"
echo "User: $(whoami)"
echo "Home: $HOME"
echo ""

# Enhanced logging function
log_diagnostic() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_diagnostic "Starting enhanced diagnostic scan with directory support verification"

# 1. Check service status with enhanced details
echo "1️⃣ Enhanced service status check:"
echo "=================================="
if [ -f ~/Scripts/folder_file_monitor.sh ]; then
    ~/Scripts/folder_file_monitor.sh status
    echo ""
    log_diagnostic "Service status command completed"
else
    echo "❌ Script not found at ~/Scripts/folder_file_monitor.sh"
    log_diagnostic "ERROR: Main script missing"
fi

echo ""
echo "2️⃣ Enhanced file verification:"
echo "==============================="
echo "📄 Script file:"
if [ -f ~/Scripts/folder_file_monitor.sh ]; then
    ls -la ~/Scripts/folder_file_monitor.sh
    echo "✅ Script exists and permissions:"
    stat ~/Scripts/folder_file_monitor.sh | grep -E "(Access|Modify)"
    
    # Check for directory monitoring features
    echo ""
    echo "🔍 Directory monitoring features check:"
    if grep -q "file_type.*DIRECTORY" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Directory monitoring support detected"
    else
        echo "❌ Directory monitoring support missing"
    fi
    
    if grep -q "handle_nested_directory_creation" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Nested directory creation support detected"
    else
        echo "❌ Nested directory creation support missing"
    fi
    
    if grep -q "latency.*0\.1" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Instant detection (0.1s latency) configured"
    else
        echo "⚠️  Standard latency configured (may affect instant detection)"
    fi
else
    echo "❌ Script file NOT found"
fi

echo ""
echo "📊 Database files:"
if [ -f ~/Logs/folder_file_monitor.db ]; then
    ls -la ~/Logs/folder_file_monitor.db
    echo "Database size: $(du -h ~/Logs/folder_file_monitor.db | cut -f1)"
    echo "Database permissions:"
    stat ~/Logs/folder_file_monitor.db | grep -E "(Access|Modify)"
    
    # Check for backup files
    echo ""
    echo "💾 Database backups:"
    if ls ~/Logs/folder_file_monitor_*.backup.tar.gz 2>/dev/null; then
        echo "✅ Backup files found:"
        ls -lht ~/Logs/folder_file_monitor_*.backup.tar.gz | head -3
    else
        echo "ℹ️  No backup files found (will be created during next reinstall)"
    fi
else
    echo "❌ Database file NOT found"
fi

echo ""
echo "📝 Log files:"
for logfile in ~/Logs/folder_file_monitor.log ~/Logs/folder_launchd.log ~/Logs/folder_launchd_error.log; do
    if [ -f "$logfile" ]; then
        echo "✅ $(basename "$logfile"): $(ls -lh "$logfile" | awk '{print $5, $6, $7, $8}')"
    else
        echo "❌ $(basename "$logfile"): NOT found"
    fi
done

echo ""
echo "3️⃣ Enhanced database verification with directory support:"
echo "=========================================================="
if [ -f ~/Logs/folder_file_monitor.db ]; then
    echo "📊 Database statistics:"
    sqlite3 ~/Logs/folder_file_monitor.db "
        SELECT 
            COUNT(*) as total_records,
            COUNT(DISTINCT filepath) as unique_items,
            MIN(timestamp) as oldest_record,
            MAX(timestamp) as newest_record,
            COUNT(DISTINCT date(timestamp)) as days_tracked,
            SUM(CASE WHEN file_type = 'FILE' THEN 1 ELSE 0 END) as files,
            SUM(CASE WHEN file_type = 'DIRECTORY' THEN 1 ELSE 0 END) as directories
        FROM file_changes;" 2>/dev/null || echo "❌ Database query failed"
    
    echo ""
    echo "📈 Event type distribution:"
    sqlite3 -header -column ~/Logs/folder_file_monitor.db "
        SELECT 
            event_type,
            file_type,
            COUNT(*) as count,
            ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM file_changes), 2) as percentage
        FROM file_changes 
        GROUP BY event_type, file_type 
        ORDER BY count DESC;" 2>/dev/null || echo "❌ Event distribution analysis failed"
    
    echo ""
    echo "📅 Recent activity summary (last 24 hours):"
    sqlite3 ~/Logs/folder_file_monitor.db "
        SELECT 
            COUNT(*) as changes_24h,
            COUNT(DISTINCT filepath) as items_24h,
            MIN(timestamp) as first_change_24h,
            MAX(timestamp) as last_change_24h,
            SUM(CASE WHEN file_type = 'DIRECTORY' THEN 1 ELSE 0 END) as directories_24h,
            SUM(CASE WHEN file_type = 'FILE' THEN 1 ELSE 0 END) as files_24h
        FROM file_changes 
        WHERE datetime(timestamp) >= datetime('now', '-24 hours');" 2>/dev/null || echo "❌ Recent activity query failed"
    
    echo ""
    echo "🔥 Most active items with event breakdown (last 7 days):"
    sqlite3 -header -column ~/Logs/folder_file_monitor.db "
        SELECT 
            CASE WHEN file_type = 'DIRECTORY' THEN '📁 ' || filepath ELSE '📄 ' || filepath END as item,
            COUNT(*) as total_changes,
            MAX(timestamp) as last_change,
            SUM(CASE WHEN event_type = 'CREATED' THEN 1 ELSE 0 END) as created,
            SUM(CASE WHEN event_type = 'MODIFIED' THEN 1 ELSE 0 END) as modified,
            SUM(CASE WHEN event_type = 'DELETED' THEN 1 ELSE 0 END) as deleted
        FROM file_changes 
        WHERE datetime(timestamp) >= datetime('now', '-7 days')
        GROUP BY filepath, file_type
        ORDER BY total_changes DESC, last_change DESC
        LIMIT 5;" 2>/dev/null || echo "❌ Activity analysis failed"

    echo ""
    echo "🗄️ Database integrity check:"
    sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA integrity_check;" 2>/dev/null || echo "❌ Integrity check failed"
    
    echo ""
    echo "📋 Enhanced database schema verification:"
    echo "Checking for file_type column support:"
    if sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA table_info(file_changes);" 2>/dev/null | grep -q "file_type"; then
        echo "✅ file_type column exists (directory support enabled)"
    else
        echo "❌ file_type column missing (needs database update)"
    fi
    
    echo "Checking indexes:"
    sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA index_list(file_changes);" 2>/dev/null | while read index_info; do
        index_name=$(echo "$index_info" | cut -d'|' -f2)
        if [[ "$index_name" =~ idx_ ]]; then
            echo "✅ Index found: $index_name"
        fi
    done
else
    echo "❌ Database NOT available for analysis"
fi

echo ""
echo "4️⃣ Enhanced log analysis:"
echo "=========================="
if [ -f ~/Logs/folder_file_monitor.log ]; then
    echo "📄 Main log - Last 10 entries with full timestamps:"
    tail -10 ~/Logs/folder_file_monitor.log | while read line; do
        echo "  $line"
    done
    
    echo ""
    echo "📊 Log statistics (last 100 lines):"
    echo "  Total entries: $(wc -l < ~/Logs/folder_file_monitor.log)"
    echo "  Recent errors: $(tail -100 ~/Logs/folder_file_monitor.log | grep -c "ERROR" || echo "0")"
    echo "  Recent starts: $(tail -100 ~/Logs/folder_file_monitor.log | grep -c "Starting Folder" || echo "0")"
    echo "  Recent stops: $(tail -100 ~/Logs/folder_file_monitor.log | grep -c "Stopping Folder" || echo "0")"
    echo "  Directory events: $(tail -100 ~/Logs/folder_file_monitor.log | grep -c "DIRECTORY" || echo "0")"
    echo "  File events: $(tail -100 ~/Logs/folder_file_monitor.log | grep -c "FILE" || echo "0")"
else
    echo "❌ Main log NOT available"
fi

echo ""
if [ -f ~/Logs/folder_launchd_error.log ]; then
    echo "⚠️ LaunchAgent error log - Last 5 entries:"
    tail -5 ~/Logs/folder_launchd_error.log | while read line; do
        echo "  $line"
    done
    
    echo ""
    echo "Error log size: $(wc -l < ~/Logs/folder_launchd_error.log) lines"
else
    echo "✅ No LaunchAgent error log (this is good)"
fi

echo ""
echo "5️⃣ Configuration verification:"
echo "==============================="
CONFIG_FILE="$HOME/.folder_monitor_config"
if [ -f "$CONFIG_FILE" ]; then
    echo "📁 Configured directories:"
    while IFS= read -r line; do
        if [ -n "$line" ] && [ "${line:0:1}" != "#" ]; then
            if [ -d "$line" ]; then
                echo "  ✅ $line (exists)"
                echo "     Files: $(find "$line" -type f 2>/dev/null | wc -l | tr -d ' ')"
                echo "     Directories: $(find "$line" -type d 2>/dev/null | wc -l | tr -d ' ')"
                echo "     Size: $(du -sh "$line" 2>/dev/null | cut -f1 || echo "unknown")"
            else
                echo "  ❌ $line (MISSING)"
            fi
        fi
    done < "$CONFIG_FILE"
else
    echo "❌ Configuration file NOT found at $CONFIG_FILE"
fi

echo ""
echo "6️⃣ LaunchAgent status:"
echo "======================"
echo "📋 LaunchAgent registration:"
launchctl list | grep folder.filemonitor && echo "✅ Service registered" || echo "❌ LaunchAgent NOT registered"

echo ""
echo "📄 LaunchAgent file:"
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.folder.filemonitor.plist"
if [ -f "$PLIST_FILE" ]; then
    echo "✅ LaunchAgent plist exists"
    ls -la "$PLIST_FILE"
    echo ""
    echo "LaunchAgent configuration check:"
    plutil -lint "$PLIST_FILE" 2>/dev/null && echo "✅ Plist format valid" || echo "❌ Plist format invalid"
    
    # Check for enhanced configuration
    if grep -q "<key>Nice</key>" "$PLIST_FILE" 2>/dev/null; then
        echo "✅ Enhanced LaunchAgent configuration (Nice priority)"
    else
        echo "⚠️  Standard LaunchAgent configuration (may need update)"
    fi
else
    echo "❌ LaunchAgent plist NOT found"
fi

echo ""
echo "7️⃣ System verification:"
echo "======================="
echo "🔧 fswatch availability:"
if command -v fswatch &> /dev/null; then
