#!/bin/bash

# ENHANCED DIAGNOSTICS - FOLDER FILE MONITOR
# Run these commands to find problems with enhanced folder tracking details
# Enhanced version with folder tracking verification

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

log_diagnostic "Starting enhanced diagnostic scan with folder tracking verification"

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
    
    # Check for enhanced features
    echo ""
    echo "🔍 Enhanced features verification:"
    if grep -q "is_directory.*INTEGER.*DEFAULT.*0" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Enhanced database schema with folder tracking detected"
    else
        echo "❌ Enhanced database schema missing - needs update"
    fi
    
    if grep -q "handle_nested_folders" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Nested folder handling function detected"
    else
        echo "❌ Nested folder handling missing - needs update"
    fi
    
    if grep -q "latency=0.1" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Real-time monitoring (0.1s latency) detected"
    else
        echo "❌ Real-time monitoring configuration missing"
    fi
    
    if grep -q '\[FOLDER\].*\[FILE\]' ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Enhanced logging with [FOLDER]/[FILE] prefixes detected"
    else
        echo "❌ Enhanced logging prefixes missing"
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
    
    # Check for compressed backups
    echo ""
    echo "📦 Database backups:"
    backup_count=$(find ~/Logs -name "folder_file_monitor_backup_*.tar.gz" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$backup_count" -gt 0 ]; then
        echo "✅ Found $backup_count compressed backup(s):"
        find ~/Logs -name "folder_file_monitor_backup_*.tar.gz" -exec ls -lh {} \;
    else
        echo "⚠️  No compressed backups found"
    fi
else
    echo "❌ Database file NOT found"
fi

echo ""
echo "📁 Log files:"
for logfile in ~/Logs/folder_file_monitor.log ~/Logs/folder_launchd.log ~/Logs/folder_launchd_error.log; do
    if [ -f "$logfile" ]; then
        echo "✅ $(basename "$logfile"): $(ls -lh "$logfile" | awk '{print $5, $6, $7, $8}')"
    else
        echo "❌ $(basename "$logfile"): NOT found"
    fi
done

echo ""
echo "3️⃣ Enhanced database verification with folder tracking:"
echo "======================================================="
if [ -f ~/Logs/folder_file_monitor.db ]; then
    echo "📊 Database statistics:"
    sqlite3 ~/Logs/folder_file_monitor.db "
        SELECT 
            COUNT(*) as total_records,
            COUNT(DISTINCT filepath) as unique_paths,
            MIN(timestamp) as oldest_record,
            MAX(timestamp) as newest_record,
            COUNT(DISTINCT date(timestamp)) as days_tracked,
            SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folder_records,
            SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as file_records
        FROM file_changes;" 2>/dev/null || echo "❌ Database query failed"
    
    echo ""
    echo "📅 Recent activity summary with folder/file breakdown (last 24 hours):"
    sqlite3 ~/Logs/folder_file_monitor.db "
        SELECT 
            COUNT(*) as changes_24h,
            COUNT(DISTINCT filepath) as paths_24h,
            MIN(timestamp) as first_change_24h,
            MAX(timestamp) as last_change_24h,
            SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folders_24h,
            SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as files_24h
        FROM file_changes 
        WHERE datetime(timestamp) >= datetime('now', '-24 hours');" 2>/dev/null || echo "❌ Recent activity query failed"
    
    echo ""
    echo "🔥 Most active paths with folder/file indicators (last 7 days):"
    sqlite3 -header -column ~/Logs/folder_file_monitor.db "
        SELECT 
            CASE WHEN is_directory = 1 THEN '[FOLDER] ' || filepath ELSE '[FILE] ' || filepath END as path_type,
            COUNT(*) as total_changes,
            MAX(timestamp) as last_change,
            SUM(CASE WHEN event_type = 'CREATED' THEN 1 ELSE 0 END) as created,
            SUM(CASE WHEN event_type = 'MODIFIED' THEN 1 ELSE 0 END) as modified,
            SUM(CASE WHEN event_type = 'DELETED' THEN 1 ELSE 0 END) as deleted
        FROM file_changes 
        WHERE datetime(timestamp) >= datetime('now', '-7 days')
        GROUP BY filepath, is_directory 
        ORDER BY total_changes DESC, last_change DESC
        LIMIT 5;" 2>/dev/null || echo "❌ Activity analysis failed"

    echo ""
    echo "📊 Event type distribution with folder/file breakdown (last 7 days):"
    sqlite3 -header -column ~/Logs/folder_file_monitor.db "
        SELECT 
            event_type,
            COUNT(*) as total_count,
            SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folder_count,
            SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as file_count,
            ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM file_changes WHERE datetime(timestamp) >= datetime('now', '-7 days')), 2) as percentage
        FROM file_changes 
        WHERE datetime(timestamp) >= datetime('now', '-7 days')
        GROUP BY event_type 
        ORDER BY total_count DESC;" 2>/dev/null || echo "❌ Event distribution analysis failed"

    echo ""
    echo "🗄️ Database integrity check:"
    sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA integrity_check;" 2>/dev/null || echo "❌ Integrity check failed"
    
    echo ""
    echo "📋 Enhanced database schema verification:"
    echo "Schema for file_changes table:"
    sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA table_info(file_changes);" 2>/dev/null || echo "❌ Schema check failed"
    
    echo ""
    echo "🔍 Index verification:"
    sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA index_list(file_changes);" 2>/dev/null || echo "❌ Index check failed"
    
    # Check for enhanced indexes
    if sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA index_list(file_changes);" 2>/dev/null | grep -q "idx_is_directory"; then
        echo "✅ Enhanced folder tracking index (idx_is_directory) found"
    else
        echo "⚠️  Enhanced folder tracking index missing - database needs update"
    fi
    
    if sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA index_list(file_changes);" 2>/dev/null | grep -q "idx_parent_directory"; then
        echo "✅ Parent directory index (idx_parent_directory) found"
    else
        echo "⚠️  Parent directory index missing - database needs update"
    fi
else
    echo "❌ Database NOT available for analysis"
fi

echo ""
echo "4️⃣ Enhanced log analysis:"
echo "=========================="
if [ -f ~/Logs/folder_file_monitor.log ]; then
    echo "📄 Main log - Last 10 entries with folder/file detection:"
    tail -10 ~/Logs/folder_file_monitor.log | while read line; do
        echo "  $line"
    done
    
    echo ""
    echo "📊 Enhanced log statistics (last 100 lines):"
    echo "  Total entries: $(wc -l < ~/Logs/folder_file_monitor.log)"
    echo "  Recent errors: $(tail -100 ~/Logs/folder_file_monitor.log | grep -c "ERROR" || echo "0")"
    echo "  Recent starts: $(tail -100 ~/Logs/folder_file_monitor.log | grep -c "Starting.*Enhanced" || echo "0")"
    echo "  Recent stops: $(tail -100 ~/Logs/folder_file_monitor.log | grep -c "Stopping Folder" || echo "0")"
    echo "  Folder events: $(tail -100 ~/Logs/folder_file_monitor.log | grep -c "\[FOLDER\]" || echo "0")"
    echo "  File events: $(tail -100 ~/Logs/folder_file_monitor.log | grep -c "\[FILE\]" || echo "0")"
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
                echo "     Folders: $(find "$line" -type d 2>/dev/null | wc -l | tr -d ' ')"
                echo "     Size: $(du -sh "$line" 2>/dev/null | cut -f1 || echo "unknown")"
                
                # Check for .key files specifically
                key_files=$(find "$line" -name "*.key" -type f 2>/dev/null | wc -l | tr -d ' ')
                if [ "$key_files" -gt 0 ]; then
                    echo "     .key files: $key_files found"
                fi
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
launchctl list | grep folder.filemonitor || echo "❌ LaunchAgent NOT registered"

echo ""
echo "📄 LaunchAgent file:"
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.folder.filemonitor.plist"
if [ -f "$PLIST_FILE" ]; then
    echo "✅ LaunchAgent plist exists"
    ls -la "$PLIST_FILE"
    echo ""
    echo "LaunchAgent configuration check:"
    plutil -lint "$PLIST_FILE" 2>/dev/null && echo "✅ Plist format valid" || echo "❌ Plist format invalid"
else
    echo "❌ LaunchAgent plist NOT found"
fi

echo ""
echo "7️⃣ System verification:"
echo "======================="
echo "🔧 fswatch availability:"
if command -v fswatch &> /dev/null; then
    echo "✅ fswatch found: $(which fswatch)"
    echo "   Version: $(fswatch --version 2>&1 | head -1)"
    
    # Test fswatch with enhanced parameters
    echo ""
    echo "🧪 Testing fswatch with enhanced parameters:"
    timeout 2s fswatch --latency=0.1 --exclude='\.DS_Store$' --exclude='/\.git/' "$HOME" >/dev/null 2>&1 && echo "✅ fswatch enhanced parameters work" || echo "⚠️  fswatch enhanced parameters may have issues"
else
    echo "❌ fswatch NOT found"
fi

echo ""
echo "🖥️ System information:"
echo "  macOS version: $(sw_vers -productVersion)"
echo "  Computer name: $(scutil --get ComputerName 2>/dev/null || echo "Unknown")"
echo "  Current user: $(whoami)"
echo "  Home directory: $HOME"
echo "  Current time: $(date '+%Y-%m-%d %H:%M:%S')"

echo ""
echo "8️⃣ Process verification:"
echo "========================"
echo "🔍 Related processes:"
ps aux | grep -E "(folder_file_monitor|fswatch)" | grep -v grep || echo "❌ No related processes found"

echo ""
echo "💾 Memory and disk usage:"
echo "  Available disk space: $(df -h ~ | tail -1 | awk '{print $4}')"
echo "  System load: $(uptime | awk -F'load average:' '{print $2}')"

echo ""
echo "9️⃣ Network and connectivity:"
echo "============================"
echo "🌐 Testing GitHub connectivity:"
if curl -s --connect-timeout 5 https://github.com > /dev/null; then
    echo "✅ GitHub accessible"
else
    echo "❌ GitHub not accessible (may affect updates)"
fi

echo ""
echo "🔟 Enhanced functionality test:"
echo "==============================="
if [ -f ~/Scripts/folder_file_monitor.sh ]; then
    echo "📊 Testing recent command with folder/file filtering (last 1 hour, all events):"
    ~/Scripts/folder_file_monitor.sh recent 1 2>/dev/null || echo "❌ Recent command failed"
    
    echo ""
    echo "📁 Testing folder-specific filtering (last 1 hour, created only):"
    ~/Scripts/folder_file_monitor.sh recent 1 created 2>/dev/null || echo "❌ Event filtering failed"
    
    echo ""
    echo "📋 Testing status with event filtering (created events only):"
    ~/Scripts/folder_file_monitor.sh status created 2>/dev/null || echo "❌ Status filtering failed"
    
    echo ""
    echo "📋 Testing list command:"
    ~/Scripts/folder_file_monitor.sh list 2>/dev/null || echo "❌ List command failed"
    
    echo ""
    echo "🧪 Testing enhanced event filter parsing:"
    # Test if the script accepts pipe-separated event filters
    echo "   Testing: created|modified filter"
    ~/Scripts/folder_file_monitor.sh recent 1 "created|modified" >/dev/null 2>&1 && echo "   ✅ Pipe filtering works" || echo "   ❌ Pipe filtering failed"
    
    echo "   Testing: folder detection capability"
    if grep -q "is_directory.*=.*1" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "   ✅ Folder detection capability present"
    else
        echo "   ❌ Folder detection capability missing"
    fi
    
    echo "   Testing: .key file inclusion"
    if grep -q -v "exclude.*key" ~/Scripts/folder_file_monitor.sh 2>/dev/null && ! grep -q "exclude.*\\.key" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "   ✅ .key files should be included (not excluded)"
    else
        echo "   ⚠️  .key files may be excluded - check configuration"
    fi
else
    echo "❌ Cannot perform functionality tests - script missing"
fi

echo ""
echo "📊 ENHANCED DIAGNOSTIC SUMMARY"
echo "=============================="
log_diagnostic "Enhanced diagnostic scan completed"

# Generate summary
ISSUES=0
WARNINGS=0

echo ""
if [ ! -f ~/Scripts/folder_file_monitor.sh ]; then
    echo "🚨 CRITICAL: Main script missing"
    ISSUES=$((ISSUES + 1))
fi

if [ ! -f ~/Logs/folder_file_monitor.db ]; then
    echo "⚠️ WARNING: Database file missing"
    WARNINGS=$((WARNINGS + 1))
fi

if ! command -v fswatch &> /dev/null; then
    echo "🚨 CRITICAL: fswatch not installed"
    ISSUES=$((ISSUES + 1))
fi

if ! launchctl list | grep -q folder.filemonitor; then
    echo "⚠️ WARNING: LaunchAgent not registered"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for enhanced features
if [ -f ~/Scripts/folder_file_monitor.sh ]; then
    if ! grep -q "is_directory.*INTEGER.*DEFAULT.*0" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "⚠️ WARNING: Enhanced folder tracking missing"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if ! grep -q "handle_nested_folders" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "⚠️ WARNING: Nested folder handling missing"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if ! grep -q "latency=0.1" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "⚠️ WARNING: Real-time monitoring not configured"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

if [ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All enhanced systems operational"
elif [ $ISSUES -eq 0 ]; then
    echo "⚠️ $WARNINGS warning(s) found - enhanced system mostly functional"
else
    echo "🚨 $ISSUES critical issue(s) and $WARNINGS warning(s) found"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Run enhanced install: curl -fsSL https://raw.githubusercontent.com/your-repo/install_folder_file_monitor.sh | bash"
    echo "   2. Or enhanced reinstall: bash reinstall_folder_file_monitor.sh"
    echo "   3. Or enhanced update: bash folder_file_monitor_update.sh"
fi

echo ""
log_diagnostic "Enhanced diagnostics completed with $ISSUES critical issues and $WARNINGS warnings"
echo ""
echo "🎯 ENHANCED FEATURES VERIFICATION:"
echo "================================="
if [ -f ~/Scripts/folder_file_monitor.sh ]; then
    echo "✅ Enhanced script with folder tracking available"
    
    if grep -q "handle_nested_folders" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Nested folder creation handling detected"
    else
        echo "⚠️  Nested folder creation handling may not be available"
    fi
    
    if grep -q "is_directory.*INTEGER.*DEFAULT.*0" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Enhanced database schema with folder tracking detected"
    else
        echo "⚠️  Enhanced database schema may not be available"
    fi
    
    if grep -q "latency=0.1" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Real-time monitoring (0.1s latency) detected"
    else
        echo "⚠️  Real-time monitoring configuration may need update"
    fi
    
    if grep -q '\[FOLDER\].*\[FILE\]' ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Enhanced logging with [FOLDER]/[FILE] prefixes detected"
    else
        echo "⚠️  Enhanced logging prefixes may not be available"
    fi
    
    if [ -f ~/Logs/folder_file_monitor.db ]; then
        # Check if database has enhanced indexes
        if sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA index_list(file_changes);" 2>/dev/null | grep -q "idx_is_directory"; then
            echo "✅ Enhanced database indexing (folder tracking) detected"
        else
            echo "⚠️  Enhanced database indexing may need update"
        fi
        
        # Check if database has folder records
        folder_count=$(sqlite3 ~/Logs/folder_file_monitor.db "SELECT COUNT(*) FROM file_changes WHERE is_directory = 1;" 2>/dev/null || echo "0")
        if [ "$folder_count" -gt 0 ]; then
            echo "✅ Database contains $folder_count folder tracking records"
        else
            echo "⚠️  No folder tracking records found - create some folders to test"
        fi
    fi
    
    # Check for .key file support (should NOT be excluded)
    if ! grep -q "exclude.*\\.key" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ .key files are included (not excluded from monitoring)"
    else
        echo "❌ .key files are being excluded - configuration error"
    fi
else
    echo "❌ Enhanced script not available"
fi

echo ""
echo "🚀 RECOMMENDED ACTIONS:"
echo "======================"
if [ $ISSUES -gt 0 ]; then
    echo "🔧 Critical issues found - run enhanced reinstallation:"
    echo "   bash reinstall_folder_file_monitor.sh"
elif [ $WARNINGS -gt 0 ]; then
    echo "⚡ Minor issues found - run enhanced update:"
    echo "   bash folder_file_monitor_update.sh"
else
    echo "✨ System optimal - try the enhanced folder tracking features:"
    echo "   ~/Scripts/folder_file_monitor.sh status created"
    echo "   ~/Scripts/folder_file_monitor.sh recent 1 created|modified"
    echo "   ~/Scripts/folder_file_monitor.sh recent 1 deleted"
    echo ""
    echo "🧪 Test folder tracking by creating nested folders:"
    echo "   mkdir -p ~/test-monitor/level1/level2"
    echo "   touch ~/test-monitor/level1/level2/test.key"
    echo "   ~/Scripts/folder_file_monitor.sh recent 1 created"
    echo "   # Should show [FOLDER] and [FILE] entries for all created items"
fi

echo ""
echo "📦 BACKUP VERIFICATION:"
echo "======================"
backup_count=$(find ~/Logs -name "folder_file_monitor_backup_*.tar.gz" 2>/dev/null | wc -l | tr -d ' ')
if [ "$backup_count" -gt 0 ]; then
    echo "✅ Found $backup_count compressed database backup(s):"
    find ~/Logs -name "folder_file_monitor_backup_*.tar.gz" -exec ls -lh {} \; | tail -3
    echo "💡 Backups are automatically created during reinstalls and updates"
else
    echo "⚠️  No compressed backups found"
    echo "💡 Run reinstall or update to create automatic backups"
fi

echo ""
echo "🎯 QUICK TEST COMMANDS:"
echo "======================"
echo "Test enhanced folder tracking immediately:"
echo "  1. mkdir ~/test-folder-$(date +%s)"
echo "  2. mkdir ~/test-folder-$(date +%s)/nested"
echo "  3. touch ~/test-folder-$(date +%s)/nested/file.key"
echo "  4. ~/Scripts/folder_file_monitor.sh recent 1 created"
echo "  5. Should see [FOLDER] and [FILE] entries with full paths"
echo ""
echo "Test enhanced filtering:"
echo "  • ~/Scripts/folder_file_monitor.sh status created       # Only created items"
echo "  • ~/Scripts/folder_file_monitor.sh status modified      # Only modified items"
echo "  • ~/Scripts/folder_file_monitor.sh recent 1 created|modified  # Multiple events"
