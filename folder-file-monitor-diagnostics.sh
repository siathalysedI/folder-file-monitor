#!/bin/bash

# ENHANCED DIAGNOSTICS - FOLDER FILE MONITOR
# Run these commands to find problems with enhanced details
# Translated to English with full path support and enhanced logging

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

log_diagnostic "Starting enhanced diagnostic scan"

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
echo "3️⃣ Enhanced database verification:"
echo "==================================="
if [ -f ~/Logs/folder_file_monitor.db ]; then
    echo "📊 Database statistics:"
    sqlite3 ~/Logs/folder_file_monitor.db "
        SELECT 
            COUNT(*) as total_records,
            COUNT(DISTINCT filepath) as unique_files,
            MIN(timestamp) as oldest_record,
            MAX(timestamp) as newest_record,
            COUNT(DISTINCT date(timestamp)) as days_tracked
        FROM file_changes;" 2>/dev/null || echo "❌ Database query failed"
    
    echo ""
    echo "📅 Recent activity summary (last 24 hours):"
    sqlite3 ~/Logs/folder_file_monitor.db "
        SELECT 
            COUNT(*) as changes_24h,
            COUNT(DISTINCT filepath) as files_24h,
            MIN(timestamp) as first_change_24h,
            MAX(timestamp) as last_change_24h
        FROM file_changes 
        WHERE datetime(timestamp) >= datetime('now', '-24 hours');" 2>/dev/null || echo "❌ Recent activity query failed"
    
    echo ""
    echo "🔥 Most active files with event breakdown (last 7 days):"
    sqlite3 -header -column ~/Logs/folder_file_monitor.db "
        SELECT 
            filepath as full_path,
            COUNT(*) as total_changes,
            MAX(timestamp) as last_change,
            SUM(CASE WHEN event_type = 'CREATED' THEN 1 ELSE 0 END) as created,
            SUM(CASE WHEN event_type = 'MODIFIED' THEN 1 ELSE 0 END) as modified,
            SUM(CASE WHEN event_type = 'DELETED' THEN 1 ELSE 0 END) as deleted
        FROM file_changes 
        WHERE datetime(timestamp) >= datetime('now', '-7 days')
        GROUP BY filepath 
        ORDER BY total_changes DESC, last_change DESC
        LIMIT 5;" 2>/dev/null || echo "❌ Activity analysis failed"

    echo ""
    echo "📊 Event type distribution (last 7 days):"
    sqlite3 -header -column ~/Logs/folder_file_monitor.db "
        SELECT 
            event_type,
            COUNT(*) as count,
            ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM file_changes WHERE datetime(timestamp) >= datetime('now', '-7 days')), 2) as percentage
        FROM file_changes 
        WHERE datetime(timestamp) >= datetime('now', '-7 days')
        GROUP BY event_type 
        ORDER BY count DESC;" 2>/dev/null || echo "❌ Event distribution analysis failed"

    echo ""
    echo "🗄️ Database integrity check:"
    sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA integrity_check;" 2>/dev/null || echo "❌ Integrity check failed"
    
    echo ""
    echo "📋 Database schema verification:"
    sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA table_info(file_changes);" 2>/dev/null || echo "❌ Schema check failed"
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
echo "=============================="
if [ -f ~/Scripts/folder_file_monitor.sh ]; then
    echo "📊 Testing recent command (last 1 hour, all events):"
    ~/Scripts/folder_file_monitor.sh recent 1 2>/dev/null || echo "❌ Recent command failed"
    
    echo ""
    echo "🔍 Testing event filtering (last 1 hour, modified only):"
    ~/Scripts/folder_file_monitor.sh recent 1 modified 2>/dev/null || echo "❌ Event filtering failed"
    
    echo ""
    echo "📋 Testing status with event filtering (modified events only):"
    ~/Scripts/folder_file_monitor.sh status modified 2>/dev/null || echo "❌ Status filtering failed"
    
    echo ""
    echo "📋 Testing list command:"
    ~/Scripts/folder_file_monitor.sh list 2>/dev/null || echo "❌ List command failed"
    
    echo ""
    echo "🧪 Testing event filter parsing:"
    # Test if the script accepts pipe-separated event filters
    echo "   Testing: created|modified filter"
    ~/Scripts/folder_file_monitor.sh recent 1 "created|modified" >/dev/null 2>&1 && echo "   ✅ Pipe filtering works" || echo "   ❌ Pipe filtering failed"
else
    echo "❌ Cannot perform functionality tests - script missing"
fi

echo ""
echo "📊 DIAGNOSTIC SUMMARY"
echo "====================="
log_diagnostic "Diagnostic scan completed"

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

if [ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All systems operational"
elif [ $ISSUES -eq 0 ]; then
    echo "⚠️ $WARNINGS warning(s) found - system mostly functional"
else
    echo "🚨 $ISSUES critical issue(s) and $WARNINGS warning(s) found"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Run: curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/install_folder_file_monitor.sh | bash"
    echo "   2. Or reinstall: curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/reinstall_folder_file_monitor.sh | bash"
fi

echo ""
log_diagnostic "Enhanced diagnostics completed with $ISSUES critical issues and $WARNINGS warnings"
echo ""
echo "🎯 ENHANCED FEATURES VERIFICATION:"
echo "================================="
if [ -f ~/Scripts/folder_file_monitor.sh ]; then
    echo "✅ Enhanced script with event filtering available"
    if grep -q "parse_event_filter" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Event filtering functionality detected"
    else
        echo "⚠️  Event filtering functionality may not be available"
    fi
    
    if grep -q "CREATED.*MODIFIED.*DELETED" ~/Scripts/folder_file_monitor.sh 2>/dev/null; then
        echo "✅ Complete event tracking (CREATED, MODIFIED, DELETED) detected"
    else
        echo "⚠️  Complete event tracking may not be available"
    fi
    
    if [ -f ~/Logs/folder_file_monitor.db ]; then
        # Check if database has event_type index
        if sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA index_list(file_changes);" 2>/dev/null | grep -q "idx_event_type"; then
            echo "✅ Enhanced database indexing (event_type) detected"
        else
            echo "⚠️  Enhanced database indexing may need update"
        fi
    fi
else
    echo "❌ Enhanced script not available"
fi

echo ""
echo "🚀 RECOMMENDED ACTIONS:"
echo "======================"
if [ $ISSUES -gt 0 ]; then
    echo "🔧 Critical issues found - run reinstallation:"
    echo "   curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/reinstall_folder_file_monitor.sh | bash"
elif [ $WARNINGS -gt 0 ]; then
    echo "⚡ Minor issues found - run update:"
    echo "   curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor_update.sh | bash"
else
    echo "✨ System optimal - try the new enhanced features:"
    echo "   ~/Scripts/folder_file_monitor.sh status modified"
    echo "   ~/Scripts/folder_file_monitor.sh recent 6 created|modified"
    echo "   ~/Scripts/folder_file_monitor.sh recent 1 deleted"
fi
