#!/bin/bash

# Folder File Monitor Daemon - DEFINITIVE VERSION
# Automatic file monitoring for any folder

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

# Initialize SQLite database
init_database() {
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS file_changes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    filepath TEXT NOT NULL,
    filename TEXT NOT NULL,
    event_type TEXT NOT NULL,
    file_size INTEGER,
    file_hash TEXT,
    session_id TEXT
);

CREATE TABLE IF NOT EXISTS monitor_sessions (
    session_id TEXT PRIMARY KEY,
    start_time TEXT NOT NULL,
    end_time TEXT,
    files_monitored INTEGER DEFAULT 0,
    computer_name TEXT
);

CREATE INDEX IF NOT EXISTS idx_timestamp ON file_changes(timestamp);
CREATE INDEX IF NOT EXISTS idx_filename ON file_changes(filename);
CREATE INDEX IF NOT EXISTS idx_session ON file_changes(session_id);
CREATE INDEX IF NOT EXISTS idx_filepath ON file_changes(filepath);
EOF
}

# Unique session ID
SESSION_ID="session_$(date +%Y%m%d_%H%M%S)_$$"
COMPUTER_NAME=$(scutil --get ComputerName 2>/dev/null || echo "Unknown")

# Cleanup function on close
cleanup() {
    log_message "Stopping Folder File Monitor (Session: $SESSION_ID)"
    
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

# Enhanced file change logging with full paths
log_file_change() {
    local filepath="$1"
    local event="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local filename=$(basename "$filepath")
    local size=0
    local hash="deleted"
    
    if [ -f "$filepath" ]; then
        size=$(stat -f%z "$filepath" 2>/dev/null || echo "0")
        hash=$(shasum -a 256 "$filepath" 2>/dev/null | cut -d' ' -f1 || echo "error")
    fi
    
    # Enhanced log with full path
    log_message "$event: $filepath ($size bytes)"
    
    # Insert into database with error handling
    sqlite3 "$DB_FILE" <<EOF 2>/dev/null || log_error "Failed to insert file change record"
INSERT INTO file_changes (timestamp, filepath, filename, event_type, file_size, file_hash, session_id)
VALUES ('$timestamp', '$filepath', '$filename', '$event', $size, '$hash', '$SESSION_ID');
EOF
}

# Main daemon function
start_daemon() {
    check_running
    echo $$ > "$PID_FILE"
    
    # Configure signals for cleanup
    trap cleanup SIGTERM SIGINT SIGQUIT EXIT
    
    # Initialize
    init_database
    log_message "Starting Folder File Monitor (Session: $SESSION_ID)"
    log_message "💻 Computer: $COMPUTER_NAME"
    
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
        log_message "📂 Directory: $dir"
    done
    
    log_message "✅ Folder File Monitor started successfully (PID: $$)"
    
    # Main monitoring - ALL files except specific exclusions
    # Use all configured directories
    fswatch -r \
        --event Created \
        --event Updated \
        --event Removed \
        --exclude='.git' \
        --exclude='.DS_Store' \
        --exclude='~$' \
        --exclude='\.swp$' \
        --exclude='\.tmp$' \
        --exclude='\.temp$' \
        "${WATCH_DIRS[@]}" 2>/dev/null | while read filepath
    do
        # Exclude temporary and system files
        if [[ ! "$filepath" =~ /\.git/|\.DS_Store|~\$|\.swp$|\.tmp$|\.temp$ ]]; then
            if [ -f "$filepath" ]; then
                log_file_change "$filepath" "MODIFIED"
            elif [ ! -e "$filepath" ]; then
                log_file_change "$filepath" "DELETED"
            fi
        fi
    done
}

# Enhanced status display with full paths and 7-day default
show_status() {
    echo "📊 Folder File Monitor Status"
    echo "============================="
    
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
                        MAX(timestamp) as last_change
                    FROM file_changes 
                    WHERE date(timestamp) >= date('now', '-7 days');
                " 2>/dev/null || echo "Database error"
                
                echo ""
                echo "🔥 Most modified files (Last 7 days):"
                sqlite3 -header -column "$DB_FILE" "
                    SELECT 
                        filepath as full_path,
                        COUNT(*) as modifications,
                        MAX(timestamp) as last_modified
                    FROM file_changes 
                    WHERE date(timestamp) >= date('now', '-7 days')
                    GROUP BY filepath 
                    ORDER BY modifications DESC, last_modified DESC
                    LIMIT 10;
                " 2>/dev/null || echo "Database error"
                
                echo ""
                echo "📅 Recent activity (Last 7 days):"
                sqlite3 -header -column "$DB_FILE" "
                    SELECT 
                        timestamp as date_time,
                        filepath as full_path,
                        event_type as event,
                        CASE 
                            WHEN file_size < 1024 THEN file_size || ' B'
                            WHEN file_size < 1048576 THEN ROUND(file_size/1024.0, 1) || ' KB'
                            ELSE ROUND(file_size/1048576.0, 1) || ' MB'
                        END as size
                    FROM file_changes 
                    WHERE date(timestamp) >= date('now', '-7 days')
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

# Enhanced recent history with hours parameter and full paths
show_recent() {
    local hours=${1:-24}  # Default to 24 hours if no parameter provided
    
    if [ -f "$DB_FILE" ]; then
        echo "📋 File changes in the last $hours hours:"
        echo "======================================="
        sqlite3 -header -column "$DB_FILE" "
            SELECT 
                timestamp as date_time,
                filepath as full_path,
                event_type as event,
                CASE 
                    WHEN file_size < 1024 THEN file_size || ' B'
                    WHEN file_size < 1048576 THEN ROUND(file_size/1024.0, 1) || ' KB'
                    ELSE ROUND(file_size/1048576.0, 1) || ' MB'
                END as size
            FROM file_changes 
            WHERE datetime(timestamp) >= datetime('now', '-$hours hours')
            ORDER BY timestamp DESC;
        " 2>/dev/null || echo "❌ Database error"
        
        echo ""
        echo "📊 Summary for last $hours hours:"
        sqlite3 -header -column "$DB_FILE" "
            SELECT 
                COUNT(*) as total_changes,
                COUNT(DISTINCT filepath) as unique_files,
                MIN(timestamp) as first_change,
                MAX(timestamp) as last_change
            FROM file_changes 
            WHERE datetime(timestamp) >= datetime('now', '-$hours hours');
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
                session_id
            FROM file_changes 
            ORDER BY timestamp DESC;
        " > "$export_file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "📊 Data exported to: $export_file"
            echo "📍 Location: $(pwd)/$export_file"
            echo "📈 Total records: $(wc -l < "$export_file" | tr -d ' ')"
        else
            log_error "Failed to export data"
            echo "❌ Export failed - check database"
        fi
    else
        echo "❌ No database to export"
    fi
}

# Main - Command handling
case "$1" in
    "daemon")
        start_daemon
        ;;
    "start")
        start_daemon &
        echo "🚀 Folder File Monitor started in background"
        sleep 2
        show_status
        ;;
    "stop")
        stop_daemon
        ;;
    "status")
        show_status
        ;;
    "recent")
        show_recent "$2"
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
        echo "🔄 Folder File Monitor restarted"
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
        echo "🛠️ Folder File Monitor - Available commands:"
        echo "============================================"
        echo "  daemon           - Run as daemon (internal use)"
        echo "  start            - Start monitor in background"
        echo "  stop             - Stop monitor"
        echo "  status           - View status and statistics (last 7 days)"
        echo "  recent [HOURS]   - Show changes in last N hours (default: 24)"
        echo "  export           - Export data to CSV"
        echo "  add              - Add directory to monitoring"
        echo "  list             - List configured directories"
        echo "  restart          - Restart monitor"
        echo "  logs             - View latest log lines"
        echo ""
        echo "Examples:"
        echo "  $0 recent        - Show last 24 hours"
        echo "  $0 recent 6      - Show last 6 hours"
        echo "  $0 recent 168    - Show last 7 days"
        echo ""
        echo "💡 Monitor starts automatically on login"
        ;;
esac
