#!/bin/bash

# Folder File Monitor Daemon - ENHANCED VERSION WITH FOLDER TRACKING
# Automatic file and folder monitoring for any directory

# Configuration - CONSISTENT NAMES
CONFIG_FILE="$HOME/.folder_monitor_config"
LOG_FILE="$HOME/Logs/folder_file_monitor.log"
DB_FILE="$HOME/Logs/folder_file_monitor.db"
PID_FILE="$HOME/Logs/folder_file_monitor.pid"

# Function to read directories from config file
read_config() {
    if [ -f "$CONFIG_FILE" ]; then
        WATCH_DIRS=()
        while IFS= read -r line; do
            if [ -n "$line" ] && [ "${line:0:1}" != "#" ]; then
                WATCH_DIRS+=("$line")
            fi
        done < "$CONFIG_FILE"
    else
        WATCH_DIRS=()
    fi
}

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
        echo "Directory is already being monitored: $dir"
        return 0
    fi
    
    # Add to configuration
    echo "$dir" >> "$CONFIG_FILE"
    echo "Directory added to monitoring: $dir"
    return 0
}

# Function to request directories if no configuration
setup_directories() {
    echo ""
    echo "No directories configured for monitoring."
    echo "You can add multiple directories."
    echo ""
    
    while true; do
        read -p "Directory to monitor (Enter to finish): " dir
        if [ -z "$dir" ]; then
            break
        fi
        add_directory "$dir"
    done
    
    # Verify at least one was added
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        echo "ERROR: You must configure at least one directory"
        exit 1
    fi
}

# Read existing configuration
read_config

# If no directories configured, request them
if [ ${#WATCH_DIRS[@]} -eq 0 ]; then
    setup_directories
    read_config
fi

# Create directories if they don't exist
mkdir -p "$HOME/Logs"

# Enhanced logging function with timestamp and error handling
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Enhanced error logging function
log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $1" | tee -a "$LOG_FILE"
}

# Initialize SQLite database with enhanced schema and migration
init_database() {
    # Check if database exists and needs migration
    local needs_migration=0
    
    if [ -f "$DB_FILE" ]; then
        # Check if is_directory column exists
        if ! sqlite3 "$DB_FILE" "PRAGMA table_info(file_changes);" | grep -q "is_directory"; then
            log_message "Database migration needed - adding enhanced columns"
            needs_migration=1
        fi
    fi
    
    # Create tables with enhanced schema
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS file_changes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    filepath TEXT NOT NULL,
    filename TEXT NOT NULL,
    event_type TEXT NOT NULL,
    file_size INTEGER,
    file_hash TEXT,
    session_id TEXT,
    is_directory INTEGER DEFAULT 0,
    parent_directory TEXT
);

CREATE TABLE IF NOT EXISTS monitor_sessions (
    session_id TEXT PRIMARY KEY,
    start_time TEXT NOT NULL,
    end_time TEXT,
    files_monitored INTEGER DEFAULT 0,
    computer_name TEXT
);
EOF

    # Add new columns if migration is needed
    if [ $needs_migration -eq 1 ]; then
        log_message "Migrating database schema..."
        sqlite3 "$DB_FILE" <<EOF 2>/dev/null || true
ALTER TABLE file_changes ADD COLUMN is_directory INTEGER DEFAULT 0;
ALTER TABLE file_changes ADD COLUMN parent_directory TEXT;
EOF
    fi
    
    # Create indexes (will be ignored if they already exist)
    sqlite3 "$DB_FILE" <<EOF 2>/dev/null || true
CREATE INDEX IF NOT EXISTS idx_timestamp ON file_changes(timestamp);
CREATE INDEX IF NOT EXISTS idx_filename ON file_changes(filename);
CREATE INDEX IF NOT EXISTS idx_session ON file_changes(session_id);
CREATE INDEX IF NOT EXISTS idx_filepath ON file_changes(filepath);
CREATE INDEX IF NOT EXISTS idx_event_type ON file_changes(event_type);
CREATE INDEX IF NOT EXISTS idx_is_directory ON file_changes(is_directory);
CREATE INDEX IF NOT EXISTS idx_parent_directory ON file_changes(parent_directory);
EOF
    
    if [ $needs_migration -eq 1 ]; then
        log_message "Database migration completed successfully"
    fi
}

# Unique session ID
SESSION_ID="session_$(date +%Y%m%d_%H%M%S)_$$"
COMPUTER_NAME=$(scutil --get ComputerName 2>/dev/null || echo "Unknown")

# Cleanup function with hybrid monitoring cleanup
cleanup() {
    log_message "Stopping Folder File Monitor (Session: $SESSION_ID)"
    
    # Stop hybrid monitoring if running
    if [ ! -z "$HYBRID_PID" ]; then
        kill $HYBRID_PID 2>/dev/null || true
        log_message "Hybrid monitoring stopped"
    fi
    
    # Update session in DB
    sqlite3 "$DB_FILE" <<EOF 2>/dev/null || true
UPDATE monitor_sessions 
SET end_time = '$(date '+%Y-%m-%d %H:%M:%S')',
    files_monitored = (SELECT COUNT(*) FROM file_changes WHERE session_id = '$SESSION_ID')
WHERE session_id = '$SESSION_ID';
EOF
    
    rm -f "$PID_FILE"
    exit 0
}

# Check if already running
check_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            log_error "Folder File Monitor is already running (PID: $pid)"
            exit 1
        else
            rm -f "$PID_FILE"
        fi
    fi
}

# Enhanced file/folder change logging with real-time detection and path validation
log_file_change() {
    local filepath="$1"
    local event="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local filename=$(basename "$filepath")
    local parent_dir=$(dirname "$filepath")
    local size=0
    local hash="deleted"
    local is_directory=0
    
    # Path length validation and truncation for very long paths
    local path_length=${#filepath}
    local display_path="$filepath"
    if [ "$path_length" -gt 200 ]; then
        display_path="${filepath:0:100}...${filepath: -50}"
        log_message "📏 Path truncated for display (original length: ${path_length} chars)"
    fi
    
    # Check if it's a directory
    if [ -d "$filepath" ]; then
        is_directory=1
        size=0
        hash="directory"
    elif [ -f "$filepath" ]; then
        # For very large files, skip hash calculation to improve performance
        size=$(stat -f%z "$filepath" 2>/dev/null || echo "0")
        if [ "$size" -lt 10485760 ]; then  # Less than 10MB
            hash=$(shasum -a 256 "$filepath" 2>/dev/null | cut -d' ' -f1 || echo "error")
        else
            hash="large_file_skipped"
        fi
    fi
    
    # Enhanced log with full path and type indication
    if [ $is_directory -eq 1 ]; then
        log_message "$event: [FOLDER] $display_path"
    else
        if [ "$size" -gt 1048576 ]; then  # > 1MB
            local size_mb=$(echo "scale=1; $size / 1048576" | bc 2>/dev/null || echo "$(($size / 1048576))")
            log_message "$event: [FILE] $display_path (${size_mb}MB)"
        else
            log_message "$event: [FILE] $display_path ($size bytes)"
        fi
    fi
    
    # Insert into database with enhanced error handling and path validation
    # Use parameter substitution to handle special characters in paths
    local safe_filepath=$(printf '%q' "$filepath")
    local safe_filename=$(printf '%q' "$filename")
    local safe_parent_dir=$(printf '%q' "$parent_dir")
    local safe_hash=$(printf '%q' "$hash")
    
    sqlite3 "$DB_FILE" <<EOF 2>/dev/null || log_error "Failed to insert file change record for: $display_path"
INSERT INTO file_changes (timestamp, filepath, filename, event_type, file_size, file_hash, session_id, is_directory, parent_directory)
VALUES ('$timestamp', $safe_filepath, $safe_filename, '$event', $size, $safe_hash, '$SESSION_ID', $is_directory, $safe_parent_dir);
EOF
}

# Function to handle nested folder creation with path validation
handle_nested_folders() {
    local target_path="$1"
    local event_type="$2"
    
    # Validate path length
    local path_length=${#target_path}
    if [ "$path_length" -gt 255 ]; then
        log_message "⚠️  Processing very long path (${path_length} chars) for $event_type"
    fi
    
    # Start from the target path and work backwards to find the deepest existing parent
    local current_path="$target_path"
    local paths_to_log=()
    
    # If it's a creation event, we need to find which folders are new
    if [ "$event_type" = "CREATED" ]; then
        local depth_count=0
        while [ ! -z "$current_path" ] && [ "$current_path" != "/" ] && [ "$current_path" != "." ]; do
            # Safety limit for very deep structures
            depth_count=$((depth_count + 1))
            if [ "$depth_count" -gt 50 ]; then
                log_message "⚠️  Reached maximum depth limit (50) for path analysis"
                break
            fi
            
            # More lenient recent check for nested folder detection
            local recent_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM file_changes WHERE filepath = '$current_path' AND datetime(timestamp) >= datetime('now', '-5 seconds');" 2>/dev/null || echo "0")
            
            if [ "$recent_count" -eq 0 ] && [ -d "$current_path" ]; then
                # Check if any of our monitored directories contains this path
                local is_under_monitored=0
                for monitored_dir in "${WATCH_DIRS[@]}"; do
                    if [[ "$current_path" == "$monitored_dir"* ]]; then
                        is_under_monitored=1
                        break
                    fi
                done
                
                if [ $is_under_monitored -eq 1 ]; then
                    paths_to_log=("$current_path" "${paths_to_log[@]}")
                fi
            fi
            current_path=$(dirname "$current_path")
        done
    else
        # For non-creation events, just log the target
        paths_to_log=("$target_path")
    fi
    
    # Log each path that needs to be logged
    for path_to_log in "${paths_to_log[@]}"; do
        log_file_change "$path_to_log" "$event_type"
    done
}

# Main daemon function with enhanced folder and file detection for long paths
start_daemon() {
    check_running
    echo $ > "$PID_FILE"
    
    # Configure signals for cleanup
    trap cleanup SIGTERM SIGINT SIGQUIT EXIT
    
    # Initialize
    init_database
    log_message "Starting Enhanced Folder File Monitor (Session: $SESSION_ID)"
    log_message "🖥️ Computer: $COMPUTER_NAME"
    
    # Register new session
    sqlite3 "$DB_FILE" <<EOF 2>/dev/null || log_error "Failed to register session"
INSERT INTO monitor_sessions (session_id, start_time, computer_name)
VALUES ('$SESSION_ID', '$(date '+%Y-%m-%d %H:%M:%S')', '$COMPUTER_NAME');
EOF
    
    # Pre-checks
    if ! command -v fswatch &> /dev/null; then
        log_error "fswatch not installed"
        exit 1
    fi
    
    # Verify all directories exist
    for dir in "${WATCH_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            log_message "Directory does not exist: $dir"
            log_message "📁 Creating directory..."
            mkdir -p "$dir" || log_error "Failed to create directory: $dir"
        fi
        log_message "📂 Monitoring: $dir"
        
        # Check for very deep directory structures
        local max_depth=$(find "$dir" -type d 2>/dev/null | awk -F'/' '{print NF}' | sort -nr | head -1)
        if [ "$max_depth" -gt 20 ]; then
            log_message "⚠️  Very deep directory structure detected (depth: $max_depth levels)"
            log_message "📝 Using enhanced monitoring for deep paths"
        fi
    done
    
    log_message "✅ Enhanced Folder File Monitor started successfully (PID: $)"
    log_message "🔍 Monitoring folders AND files with real-time detection (optimized for long paths)"
    
    # Enhanced monitoring with optimizations for long paths
    fswatch -r \
        --event Created \
        --event Updated \
        --event Removed \
        --event MovedFrom \
        --event MovedTo \
        --latency=0.3 \
        --batch-marker \
        --exclude='\.DS_Store

# Function to parse event type filter with improved logic
parse_event_filter() {
    local filter="$1"
    if [ -z "$filter" ]; then
        echo "('CREATED', 'MODIFIED', 'DELETED')"
    else
        # Convert pipe-separated values to SQL IN clause
        local sql_filter=""
        IFS='|' read -ra EVENTS <<< "$filter"
        for event in "${EVENTS[@]}"; do
            event=$(echo "$event" | tr '[:lower:]' '[:upper:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [[ "$event" =~ ^(CREATED|MODIFIED|DELETED)$ ]]; then
                if [ -n "$sql_filter" ]; then
                    sql_filter="$sql_filter, "
                fi
                sql_filter="$sql_filter'$event'"
            fi
        done
        if [ -n "$sql_filter" ]; then
            echo "($sql_filter)"
        else
            echo "('CREATED', 'MODIFIED', 'DELETED')"
        fi
    fi
}

# Enhanced status display with event filtering and 7-day default
show_status() {
    local event_filter="$1"
    local filter_clause=$(parse_event_filter "$event_filter")
    
    echo "📊 Enhanced Folder File Monitor Status"
    if [ -n "$event_filter" ]; then
        echo "Filter: $event_filter events only"
    fi
    echo "====================================="
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            echo "✅ Status: RUNNING (PID: $pid)"
            echo "Config file: $CONFIG_FILE"
            echo "📄 Log: $LOG_FILE"
            echo "🗄️ Database: $DB_FILE"
            
            if [ -f "$CONFIG_FILE" ]; then
                echo ""
                echo "Monitored directories:"
                while IFS= read -r line; do
                    if [ -n "$line" ] && [ "${line:0:1}" != "#" ]; then
                        echo "  - $line"
                    fi
                done < "$CONFIG_FILE"
            fi
            
            if [ -f "$DB_FILE" ]; then
                echo ""
                echo "📈 Statistics (Last 7 days):"
                sqlite3 -header -column "$DB_FILE" "
                    SELECT 
                        COUNT(*) as total_changes,
                        COUNT(DISTINCT filename) as unique_files,
                        COUNT(DISTINCT filepath) as unique_paths,
                        MAX(timestamp) as last_change,
                        SUM(CASE WHEN event_type = 'CREATED' THEN 1 ELSE 0 END) as created,
                        SUM(CASE WHEN event_type = 'MODIFIED' THEN 1 ELSE 0 END) as modified,
                        SUM(CASE WHEN event_type = 'DELETED' THEN 1 ELSE 0 END) as deleted,
                        SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folders,
                        SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as files
                    FROM file_changes 
                    WHERE date(timestamp) >= date('now', '-7 days')
                      AND event_type IN $filter_clause;
                " 2>/dev/null || echo "Database error"
                
                echo ""
                echo "🔥 Most active paths (Last 7 days):"
                sqlite3 -header -column "$DB_FILE" "
                    SELECT 
                        CASE WHEN is_directory = 1 THEN '[FOLDER] ' || filepath ELSE '[FILE] ' || filepath END as path_type,
                        COUNT(*) as total_changes,
                        MAX(timestamp) as last_change,
                        SUM(CASE WHEN event_type = 'CREATED' THEN 1 ELSE 0 END) as created,
                        SUM(CASE WHEN event_type = 'MODIFIED' THEN 1 ELSE 0 END) as modified,
                        SUM(CASE WHEN event_type = 'DELETED' THEN 1 ELSE 0 END) as deleted
                    FROM file_changes 
                    WHERE date(timestamp) >= date('now', '-7 days')
                      AND event_type IN $filter_clause
                    GROUP BY filepath, is_directory 
                    ORDER BY total_changes DESC, last_change DESC
                    LIMIT 10;
                " 2>/dev/null || echo "Database error"
                
                echo ""
                echo "📅 Recent activity (Last 7 days):"
                sqlite3 -header -column "$DB_FILE" "
                    SELECT 
                        timestamp as date_time,
                        CASE WHEN is_directory = 1 THEN '[FOLDER] ' || filepath ELSE '[FILE] ' || filepath END as path_type,
                        event_type as event,
                        CASE 
                            WHEN is_directory = 1 THEN 'folder'
                            WHEN file_size < 1024 THEN file_size || ' B'
                            WHEN file_size < 1048576 THEN ROUND(file_size/1024.0, 1) || ' KB'
                            ELSE ROUND(file_size/1048576.0, 1) || ' MB'
                        END as size
                    FROM file_changes 
                    WHERE date(timestamp) >= date('now', '-7 days')
                      AND event_type IN $filter_clause
                    ORDER BY timestamp DESC 
                    LIMIT 20;
                " 2>/dev/null || echo "Database error"
            fi
        else
            echo "❌ Status: STOPPED (obsolete PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "❌ Status: STOPPED"
    fi
}

# Function to add more directories
add_directory_interactive() {
    echo "Add directory to monitoring"
    echo "=========================="
    read -p "Directory path: " dir
    if [ -n "$dir" ]; then
        if add_directory "$dir"; then
            echo "Directory added. Restart monitor for it to take effect:"
            echo "  $0 restart"
        fi
    fi
}

# Function to list configured directories
list_directories() {
    echo "Directories configured for monitoring:"
    echo "===================================="
    if [ -f "$CONFIG_FILE" ]; then
        cat -n "$CONFIG_FILE"
    else
        echo "No directories configured"
    fi
}

# Stop service
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            log_message "🛑 Stopping Folder File Monitor (PID: $pid)"
            kill $pid
            sleep 3
            if ps -p $pid > /dev/null 2>&1; then
                kill -9 $pid
                log_message "🔪 Forced stop"
            fi
            rm -f "$PID_FILE"
            echo "✅ Folder File Monitor stopped"
        else
            echo "⚠️ Folder File Monitor was not running"
            rm -f "$PID_FILE"
        fi
    else
        echo "⚠️ Folder File Monitor is not running"
    fi
}

# Enhanced recent history with hours parameter, event filtering, and full paths
show_recent() {
    local hours=${1:-24}  # Default to 24 hours if no parameter provided
    local event_filter="$2"
    local filter_clause=$(parse_event_filter "$event_filter")
    
    if [ -f "$DB_FILE" ]; then
        echo "📋 File and folder changes in the last $hours hours:"
        if [ -n "$event_filter" ]; then
            echo "Filter: $event_filter events only"
        fi
        echo "==============================================="
        sqlite3 -header -column "$DB_FILE" "
            SELECT 
                timestamp as date_time,
                CASE WHEN is_directory = 1 THEN '[FOLDER] ' || filepath ELSE '[FILE] ' || filepath END as path_type,
                event_type as event,
                CASE 
                    WHEN is_directory = 1 THEN 'folder'
                    WHEN file_size < 1024 THEN file_size || ' B'
                    WHEN file_size < 1048576 THEN ROUND(file_size/1024.0, 1) || ' KB'
                    ELSE ROUND(file_size/1048576.0, 1) || ' MB'
                END as size
            FROM file_changes 
            WHERE datetime(timestamp) >= datetime('now', '-$hours hours')
              AND event_type IN $filter_clause
            ORDER BY timestamp DESC;
        " 2>/dev/null || echo "❌ Database error"
        
        echo ""
        echo "📊 Summary for last $hours hours:"
        sqlite3 -header -column "$DB_FILE" "
            SELECT 
                COUNT(*) as total_changes,
                COUNT(DISTINCT filepath) as unique_paths,
                MIN(timestamp) as first_change,
                MAX(timestamp) as last_change,
                SUM(CASE WHEN event_type = 'CREATED' THEN 1 ELSE 0 END) as created,
                SUM(CASE WHEN event_type = 'MODIFIED' THEN 1 ELSE 0 END) as modified,
                SUM(CASE WHEN event_type = 'DELETED' THEN 1 ELSE 0 END) as deleted,
                SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folders,
                SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as files
            FROM file_changes 
            WHERE datetime(timestamp) >= datetime('now', '-$hours hours')
              AND event_type IN $filter_clause;
        " 2>/dev/null || echo "❌ Database error"
    else
        echo "❌ No database available"
    fi
}

# Export data
export_data() {
    local export_file="folder_file_changes_$(date +%Y%m%d_%H%M%S).csv"
    if [ -f "$DB_FILE" ]; then
        sqlite3 -header -csv "$DB_FILE" "
            SELECT 
                timestamp,
                filepath,
                filename,
                event_type,
                file_size,
                substr(file_hash, 1, 8) as hash_short,
                session_id,
                CASE WHEN is_directory = 1 THEN 'folder' ELSE 'file' END as type,
                parent_directory
            FROM file_changes 
            ORDER BY timestamp DESC;
        " > "$export_file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "📊 Data exported to: $export_file"
            echo "📁 Location: $(pwd)/$export_file"
            echo "📈 Total records: $(wc -l < "$export_file" | tr -d ' ')"
        else
            log_error "Failed to export data"
            echo "❌ Export failed - check database"
        fi
    else
        echo "❌ No database to export"
    fi
}

# Main - Command handling with enhanced argument parsing
case "$1" in
    "daemon")
        start_daemon
        ;;
    "start")
        start_daemon &
        echo "🚀 Enhanced Folder File Monitor started in background"
        sleep 2
        show_status
        ;;
    "stop")
        stop_daemon
        ;;
    "status")
        show_status "$2"
        ;;
    "recent")
        show_recent "$2" "$3"
        ;;
    "export")
        export_data
        ;;
    "add")
        add_directory_interactive
        ;;
    "list")
        list_directories
        ;;
    "restart")
        stop_daemon
        sleep 2
        start_daemon &
        echo "🔄 Enhanced Folder File Monitor restarted"
        ;;
    "logs")
        if [ -f "$LOG_FILE" ]; then
            echo "📄 Last 50 log lines:"
            tail -50 "$LOG_FILE"
        else
            echo "❌ No log file"
        fi
        ;;
    *)
        echo "🛠️ Enhanced Folder File Monitor - Available commands:"
        echo "=================================================="
        echo "  daemon                    - Run as daemon (internal use)"
        echo "  start                     - Start monitor in background"
        echo "  stop                      - Stop monitor"
        echo "  status [FILTER]           - View status and statistics (last 7 days)"
        echo "  recent [HOURS] [FILTER]   - Show changes in last N hours (default: 24)"
        echo "  export                    - Export data to CSV"
        echo "  add                       - Add directory to monitoring"
        echo "  list                      - List configured directories"
        echo "  restart                   - Restart monitor"
        echo "  logs                      - View latest log lines"
        echo ""
        echo "Event Filtering (FILTER can be):"
        echo "  created                   - Show only CREATED events"
        echo "  modified                  - Show only MODIFIED events"
        echo "  deleted                   - Show only DELETED events"
        echo "  created|modified          - Show CREATED and MODIFIED events"
        echo "  modified|deleted          - Show MODIFIED and DELETED events"
        echo "  created|deleted           - Show CREATED and DELETED events"
        echo "  (no filter)               - Show all events (CREATED, MODIFIED, DELETED)"
        echo ""
        echo "Examples:"
        echo "  $0 status                 - Show all events (last 7 days)"
        echo "  $0 status modified        - Show only modified files (last 7 days)"
        echo "  $0 status created|deleted - Show created and deleted files (last 7 days)"
        echo "  $0 recent                 - Show all events (last 24 hours)"
        echo "  $0 recent 6               - Show all events (last 6 hours)"
        echo "  $0 recent 6 created       - Show only created files (last 6 hours)"
        echo "  $0 recent 6 modified|deleted - Show modified and deleted (last 6 hours)"
        echo ""
        echo "💡 Monitor tracks BOTH files AND folders with real-time detection"
        echo "🔍 Includes .key files and all file types except .DS_Store and .git internals"
        ;;
esac \
        --exclude='/\.git/' \
        "${WATCH_DIRS[@]}" 2>/dev/null | while IFS= read -r filepath
    do
        # Skip batch markers
        [ "$filepath" = "NoOp" ] && continue
        
        # Path length validation for very long paths
        local path_length=${#filepath}
        if [ "$path_length" -gt 255 ]; then
            log_message "⚠️  Very long path detected (${path_length} chars): ${filepath:0:100}..."
        fi
        
        # Skip only .DS_Store and .git internals - include everything else including .key files
        if [[ ! "$filepath" =~ \.DS_Store$|/\.git/ ]]; then
            # More lenient duplicate detection for long paths
            local very_recent=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM file_changes WHERE filepath = '$filepath' AND datetime(timestamp) >= datetime('now', '-3 seconds');" 2>/dev/null || echo "0")
            
            if [ "$very_recent" -eq 0 ]; then
                # Determine the actual event type based on current state
                if [ -e "$filepath" ]; then
                    # Path exists - could be created or modified
                    local historical_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM file_changes WHERE filepath = '$filepath';" 2>/dev/null || echo "0")
                    
                    if [ "$historical_count" -eq 0 ]; then
                        # Never seen before - it's created
                        if [ -d "$filepath" ]; then
                            handle_nested_folders "$filepath" "CREATED"
                        else
                            log_file_change "$filepath" "CREATED"
                        fi
                    else
                        # Existed before - it's modified
                        log_file_change "$filepath" "MODIFIED"
                    fi
                else
                    # Path doesn't exist - it was deleted
                    log_file_change "$filepath" "DELETED"
                fi
            fi
        fi
    done
}

# Function to parse event type filter with improved logic
parse_event_filter() {
    local filter="$1"
    if [ -z "$filter" ]; then
        echo "('CREATED', 'MODIFIED', 'DELETED')"
    else
        # Convert pipe-separated values to SQL IN clause
        local sql_filter=""
        IFS='|' read -ra EVENTS <<< "$filter"
        for event in "${EVENTS[@]}"; do
            event=$(echo "$event" | tr '[:lower:]' '[:upper:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [[ "$event" =~ ^(CREATED|MODIFIED|DELETED)$ ]]; then
                if [ -n "$sql_filter" ]; then
                    sql_filter="$sql_filter, "
                fi
                sql_filter="$sql_filter'$event'"
            fi
        done
        if [ -n "$sql_filter" ]; then
            echo "($sql_filter)"
        else
            echo "('CREATED', 'MODIFIED', 'DELETED')"
        fi
    fi
}

# Enhanced status display with event filtering and 7-day default
show_status() {
    local event_filter="$1"
    local filter_clause=$(parse_event_filter "$event_filter")
    
    echo "📊 Enhanced Folder File Monitor Status"
    if [ -n "$event_filter" ]; then
        echo "Filter: $event_filter events only"
    fi
    echo "====================================="
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            echo "✅ Status: RUNNING (PID: $pid)"
            echo "Config file: $CONFIG_FILE"
            echo "📄 Log: $LOG_FILE"
            echo "🗄️ Database: $DB_FILE"
            
            if [ -f "$CONFIG_FILE" ]; then
                echo ""
                echo "Monitored directories:"
                while IFS= read -r line; do
                    if [ -n "$line" ] && [ "${line:0:1}" != "#" ]; then
                        echo "  - $line"
                    fi
                done < "$CONFIG_FILE"
            fi
            
            if [ -f "$DB_FILE" ]; then
                echo ""
                echo "📈 Statistics (Last 7 days):"
                sqlite3 -header -column "$DB_FILE" "
                    SELECT 
                        COUNT(*) as total_changes,
                        COUNT(DISTINCT filename) as unique_files,
                        COUNT(DISTINCT filepath) as unique_paths,
                        MAX(timestamp) as last_change,
                        SUM(CASE WHEN event_type = 'CREATED' THEN 1 ELSE 0 END) as created,
                        SUM(CASE WHEN event_type = 'MODIFIED' THEN 1 ELSE 0 END) as modified,
                        SUM(CASE WHEN event_type = 'DELETED' THEN 1 ELSE 0 END) as deleted,
                        SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folders,
                        SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as files
                    FROM file_changes 
                    WHERE date(timestamp) >= date('now', '-7 days')
                      AND event_type IN $filter_clause;
                " 2>/dev/null || echo "Database error"
                
                echo ""
                echo "🔥 Most active paths (Last 7 days):"
                sqlite3 -header -column "$DB_FILE" "
                    SELECT 
                        CASE WHEN is_directory = 1 THEN '[FOLDER] ' || filepath ELSE '[FILE] ' || filepath END as path_type,
                        COUNT(*) as total_changes,
                        MAX(timestamp) as last_change,
                        SUM(CASE WHEN event_type = 'CREATED' THEN 1 ELSE 0 END) as created,
                        SUM(CASE WHEN event_type = 'MODIFIED' THEN 1 ELSE 0 END) as modified,
                        SUM(CASE WHEN event_type = 'DELETED' THEN 1 ELSE 0 END) as deleted
                    FROM file_changes 
                    WHERE date(timestamp) >= date('now', '-7 days')
                      AND event_type IN $filter_clause
                    GROUP BY filepath, is_directory 
                    ORDER BY total_changes DESC, last_change DESC
                    LIMIT 10;
                " 2>/dev/null || echo "Database error"
                
                echo ""
                echo "📅 Recent activity (Last 7 days):"
                sqlite3 -header -column "$DB_FILE" "
                    SELECT 
                        timestamp as date_time,
                        CASE WHEN is_directory = 1 THEN '[FOLDER] ' || filepath ELSE '[FILE] ' || filepath END as path_type,
                        event_type as event,
                        CASE 
                            WHEN is_directory = 1 THEN 'folder'
                            WHEN file_size < 1024 THEN file_size || ' B'
                            WHEN file_size < 1048576 THEN ROUND(file_size/1024.0, 1) || ' KB'
                            ELSE ROUND(file_size/1048576.0, 1) || ' MB'
                        END as size
                    FROM file_changes 
                    WHERE date(timestamp) >= date('now', '-7 days')
                      AND event_type IN $filter_clause
                    ORDER BY timestamp DESC 
                    LIMIT 20;
                " 2>/dev/null || echo "Database error"
            fi
        else
            echo "❌ Status: STOPPED (obsolete PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "❌ Status: STOPPED"
    fi
}

# Function to add more directories
add_directory_interactive() {
    echo "Add directory to monitoring"
    echo "=========================="
    read -p "Directory path: " dir
    if [ -n "$dir" ]; then
        if add_directory "$dir"; then
            echo "Directory added. Restart monitor for it to take effect:"
            echo "  $0 restart"
        fi
    fi
}

# Function to list configured directories
list_directories() {
    echo "Directories configured for monitoring:"
    echo "===================================="
    if [ -f "$CONFIG_FILE" ]; then
        cat -n "$CONFIG_FILE"
    else
        echo "No directories configured"
    fi
}

# Stop service
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            log_message "🛑 Stopping Folder File Monitor (PID: $pid)"
            kill $pid
            sleep 3
            if ps -p $pid > /dev/null 2>&1; then
                kill -9 $pid
                log_message "🔪 Forced stop"
            fi
            rm -f "$PID_FILE"
            echo "✅ Folder File Monitor stopped"
        else
            echo "⚠️ Folder File Monitor was not running"
            rm -f "$PID_FILE"
        fi
    else
        echo "⚠️ Folder File Monitor is not running"
    fi
}

# Enhanced recent history with hours parameter, event filtering, and full paths
show_recent() {
    local hours=${1:-24}  # Default to 24 hours if no parameter provided
    local event_filter="$2"
    local filter_clause=$(parse_event_filter "$event_filter")
    
    if [ -f "$DB_FILE" ]; then
        echo "📋 File and folder changes in the last $hours hours:"
        if [ -n "$event_filter" ]; then
            echo "Filter: $event_filter events only"
        fi
        echo "==============================================="
        sqlite3 -header -column "$DB_FILE" "
            SELECT 
                timestamp as date_time,
                CASE WHEN is_directory = 1 THEN '[FOLDER] ' || filepath ELSE '[FILE] ' || filepath END as path_type,
                event_type as event,
                CASE 
                    WHEN is_directory = 1 THEN 'folder'
                    WHEN file_size < 1024 THEN file_size || ' B'
                    WHEN file_size < 1048576 THEN ROUND(file_size/1024.0, 1) || ' KB'
                    ELSE ROUND(file_size/1048576.0, 1) || ' MB'
                END as size
            FROM file_changes 
            WHERE datetime(timestamp) >= datetime('now', '-$hours hours')
              AND event_type IN $filter_clause
            ORDER BY timestamp DESC;
        " 2>/dev/null || echo "❌ Database error"
        
        echo ""
        echo "📊 Summary for last $hours hours:"
        sqlite3 -header -column "$DB_FILE" "
            SELECT 
                COUNT(*) as total_changes,
                COUNT(DISTINCT filepath) as unique_paths,
                MIN(timestamp) as first_change,
                MAX(timestamp) as last_change,
                SUM(CASE WHEN event_type = 'CREATED' THEN 1 ELSE 0 END) as created,
                SUM(CASE WHEN event_type = 'MODIFIED' THEN 1 ELSE 0 END) as modified,
                SUM(CASE WHEN event_type = 'DELETED' THEN 1 ELSE 0 END) as deleted,
                SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folders,
                SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as files
            FROM file_changes 
            WHERE datetime(timestamp) >= datetime('now', '-$hours hours')
              AND event_type IN $filter_clause;
        " 2>/dev/null || echo "❌ Database error"
    else
        echo "❌ No database available"
    fi
}

# Export data
export_data() {
    local export_file="folder_file_changes_$(date +%Y%m%d_%H%M%S).csv"
    if [ -f "$DB_FILE" ]; then
        sqlite3 -header -csv "$DB_FILE" "
            SELECT 
                timestamp,
                filepath,
                filename,
                event_type,
                file_size,
                substr(file_hash, 1, 8) as hash_short,
                session_id,
                CASE WHEN is_directory = 1 THEN 'folder' ELSE 'file' END as type,
                parent_directory
            FROM file_changes 
            ORDER BY timestamp DESC;
        " > "$export_file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "📊 Data exported to: $export_file"
            echo "📁 Location: $(pwd)/$export_file"
            echo "📈 Total records: $(wc -l < "$export_file" | tr -d ' ')"
        else
            log_error "Failed to export data"
            echo "❌ Export failed - check database"
        fi
    else
        echo "❌ No database to export"
    fi
}

# Main - Command handling with enhanced argument parsing
case "$1" in
    "daemon")
        start_daemon
        ;;
    "start")
        start_daemon &
        echo "🚀 Enhanced Folder File Monitor started in background"
        sleep 2
        show_status
        ;;
    "stop")
        stop_daemon
        ;;
    "status")
        show_status "$2"
        ;;
    "recent")
        show_recent "$2" "$3"
        ;;
    "export")
        export_data
        ;;
    "add")
        add_directory_interactive
        ;;
    "list")
        list_directories
        ;;
    "restart")
        stop_daemon
        sleep 2
        start_daemon &
        echo "🔄 Enhanced Folder File Monitor restarted"
        ;;
    "logs")
        if [ -f "$LOG_FILE" ]; then
            echo "📄 Last 50 log lines:"
            tail -50 "$LOG_FILE"
        else
            echo "❌ No log file"
        fi
        ;;
    *)
        echo "🛠️ Enhanced Folder File Monitor - Available commands:"
        echo "=================================================="
        echo "  daemon                    - Run as daemon (internal use)"
        echo "  start                     - Start monitor in background"
        echo "  stop                      - Stop monitor"
        echo "  status [FILTER]           - View status and statistics (last 7 days)"
        echo "  recent [HOURS] [FILTER]   - Show changes in last N hours (default: 24)"
        echo "  export                    - Export data to CSV"
        echo "  add                       - Add directory to monitoring"
        echo "  list                      - List configured directories"
        echo "  restart                   - Restart monitor"
        echo "  logs                      - View latest log lines"
        echo ""
        echo "Event Filtering (FILTER can be):"
        echo "  created                   - Show only CREATED events"
        echo "  modified                  - Show only MODIFIED events"
        echo "  deleted                   - Show only DELETED events"
        echo "  created|modified          - Show CREATED and MODIFIED events"
        echo "  modified|deleted          - Show MODIFIED and DELETED events"
        echo "  created|deleted           - Show CREATED and DELETED events"
        echo "  (no filter)               - Show all events (CREATED, MODIFIED, DELETED)"
        echo ""
        echo "Examples:"
        echo "  $0 status                 - Show all events (last 7 days)"
        echo "  $0 status modified        - Show only modified files (last 7 days)"
        echo "  $0 status created|deleted - Show created and deleted files (last 7 days)"
        echo "  $0 recent                 - Show all events (last 24 hours)"
        echo "  $0 recent 6               - Show all events (last 6 hours)"
        echo "  $0 recent 6 created       - Show only created files (last 6 hours)"
        echo "  $0 recent 6 modified|deleted - Show modified and deleted (last 6 hours)"
        echo ""
        echo "💡 Monitor tracks BOTH files AND folders with real-time detection"
        echo "🔍 Includes .key files and all file types except .DS_Store and .git internals"
        ;;
esac
