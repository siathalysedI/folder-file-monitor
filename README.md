# Enhanced Folder File Monitor - Complete Edition

Automatic monitoring of **Enhanced Complete Edition** - Now with comprehensive folder tracking, nested folder detection, real-time monitoring, and automatic compressed backups for professional file and folder monitoring on macOS.both files AND folders** in multiple directories on macOS. Runs as a background service and logs all changes with timestamps, statistics, and CSV export. Now with **enhanced folder tracking**, **nested folder detection**, and **real-time monitoring**.

## 🚀 Enhanced Features

- **Automatic startup** on login with enhanced error recovery
- **Real-time monitoring** of multiple directories (0.1s latency)
- **Complete folder tracking** - detects folder creation, modification, deletion
- **Nested folder detection** - tracks multi-level folder creation (e.g., `project/slides/assets`)
- **Enhanced SQLite database** with folder/file indicators and compressed backups
- **Advanced event filtering** - filter by single or multiple event types with pipe separator
- **Enhanced logging** - [FOLDER]/[FILE] prefixes with full paths and timestamps
- **All file types included** - monitors .key files and all extensions (excludes only .DS_Store and .git)
- **Advanced time filtering** - status shows last 7 days, recent accepts any hour value
- **Detailed statistics** by file/folder type with complete event breakdown
- **Automatic database backups** - compressed .tar.gz backups during updates
- **Enhanced CSV export** with folder/file type indicators
- **Smart real-time detection** - prevents duplicate entries with intelligent timing

## Installation

### Option 1: Enhanced Automatic Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/install_folder_file_monitor.sh | bash
```

**You will be asked to specify which directories you want to monitor. You can add multiple directories.**

### Option 2: Installation with Specific Directory

```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/install_folder_file_monitor.sh | bash -s "/path/to/your/directory"
```

### Option 3: Manual Enhanced Installation

1. **Install dependencies:**
   ```bash
   brew install fswatch
   ```

2. **Create directories:**
   ```bash
   mkdir -p ~/Scripts ~/Logs ~/Library/LaunchAgents
   ```

3. **Download enhanced script with folder tracking:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/your-repo/folder_file_monitor.sh -o ~/Scripts/folder_file_monitor.sh
   chmod +x ~/Scripts/folder_file_monitor.sh
   ```

4. **Configure directories to monitor:**
   ```bash
   echo "/path/directory1" > ~/.folder_monitor_config
   echo "/path/directory2" >> ~/.folder_monitor_config
   ```

5. **Create LaunchAgent for automatic startup:**
   ```bash
   cat > ~/Library/LaunchAgents/com.user.folder.filemonitor.plist << 'EOF'
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.user.folder.filemonitor</string>
       <key>ProgramArguments</key>
       <array>
           <string>/Users/USERNAME/Scripts/folder_file_monitor.sh</string>
           <string>daemon</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>KeepAlive</key>
       <dict>
           <key>SuccessfulExit</key>
           <false/>
       </dict>
       <key>StandardOutPath</key>
       <string>/Users/USERNAME/Logs/folder_launchd.log</string>
       <key>StandardErrorPath</key>
       <string>/Users/USERNAME/Logs/folder_launchd_error.log</string>
       <key>WorkingDirectory</key>
       <string>/Users/USERNAME</string>
       <key>EnvironmentVariables</key>
       <dict>
           <key>PATH</key>
           <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
           <key>HOME</key>
           <string>/Users/USERNAME</string>
       </dict>
       <key>ProcessType</key>
       <string>Background</string>
       <key>LowPriorityIO</key>
       <true/>
       <key>ThrottleInterval</key>
       <integer>1</integer>
   </dict>
   </plist>
   EOF
   ```
   
   **Important:** Replace `USERNAME` with your actual username.

6. **Activate enhanced service:**
   ```bash
   launchctl load ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
   ```

7. **Verify enhanced functionality:**
   ```bash
   ~/Scripts/folder_file_monitor.sh status
   ```

## Quick Enhanced Update

```bash
bash folder_file_monitor_update.sh
```

**Automatically updates to enhanced version with compressed database backup, folder tracking, and real-time detection.**

## 🔧 Database Migration (Automatic)

All enhanced scripts now include **automatic database migration**:

- ✅ **Seamless upgrades** - Existing databases are automatically migrated
- ✅ **No data loss** - All existing records are preserved  
- ✅ **Schema enhancement** - Adds `is_directory` and `parent_directory` columns
- ✅ **Index optimization** - Creates enhanced indexes for better performance
- ✅ **Backup protection** - Creates backups before any migration

### Migration Details

When you run any enhanced script, it will:

1. **Detect existing database** and check schema version
2. **Create backup** (compressed .tar.gz format) 
3. **Add missing columns** (`is_directory`, `parent_directory`)
4. **Create enhanced indexes** for folder tracking
5. **Verify migration** success and log results

### Manual Migration Check

```bash
# Check if your database needs migration
sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA table_info(file_changes);"

# Look for these columns:
# is_directory|INTEGER|0||0
# parent_directory|TEXT|0||0

# If missing, run any enhanced script to auto-migrate
~/Scripts/folder_file_monitor.sh restart
```

## 🎯 Enhanced Usage Commands

### Basic Commands with Advanced Filtering

```bash
# View enhanced status with folder/file breakdown (last 7 days, all events)
~/Scripts/folder_file_monitor.sh status

# Filter by single event type (last 7 days)
~/Scripts/folder_file_monitor.sh status created     # Only created files/folders
~/Scripts/folder_file_monitor.sh status modified   # Only modified files/folders
~/Scripts/folder_file_monitor.sh status deleted    # Only deleted files/folders

# Filter by multiple event types (last 7 days)
~/Scripts/folder_file_monitor.sh status created|modified    # Created and modified
~/Scripts/folder_file_monitor.sh status modified|deleted   # Modified and deleted
~/Scripts/folder_file_monitor.sh status created|deleted    # Created and deleted

# View recent changes with enhanced time and event filtering
~/Scripts/folder_file_monitor.sh recent                     # Last 24 hours, all events
~/Scripts/folder_file_monitor.sh recent 1                   # Last 1 hour, all events
~/Scripts/folder_file_monitor.sh recent 1 created          # Last 1 hour, created only
~/Scripts/folder_file_monitor.sh recent 1 modified         # Last 1 hour, modified only
~/Scripts/folder_file_monitor.sh recent 1 created|modified # Last 1 hour, created and modified
~/Scripts/folder_file_monitor.sh recent 168                # Last 7 days (168 hours), all events
~/Scripts/folder_file_monitor.sh recent 168 deleted        # Last 7 days, deleted only

# View latest log lines with enhanced timestamps
~/Scripts/folder_file_monitor.sh logs

# Export all data with folder/file type indicators to CSV
~/Scripts/folder_file_monitor.sh export
```

### Enhanced Service Control

```bash
# Start enhanced monitor manually
~/Scripts/folder_file_monitor.sh start

# Stop monitor
~/Scripts/folder_file_monitor.sh stop

# Restart enhanced monitor
~/Scripts/folder_file_monitor.sh restart
```

### LaunchAgent Control

```bash
# Stop automatic service
launchctl unload ~/Library/LaunchAgents/com.user.folder.filemonitor.plist

# Start automatic service
launchctl load ~/Library/LaunchAgents/com.user.folder.filemonitor.plist

# View service status
launchctl list | grep folder.filemonitor
```

### Advanced Queries with Enhanced Folder/File Filtering

```bash
# View all CREATED files and folders with full paths from last 24 hours
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    timestamp, 
    CASE WHEN is_directory = 1 THEN '[FOLDER] ' || filepath ELSE '[FILE] ' || filepath END as path_type, 
    event_type, 
    file_size 
FROM file_changes 
WHERE datetime(timestamp) >= datetime('now', '-24 hours') 
  AND event_type = 'CREATED'
ORDER BY timestamp DESC;"

# Most active paths by event type with folder/file indicators
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    CASE WHEN is_directory = 1 THEN '[FOLDER] ' || filepath ELSE '[FILE] ' || filepath END as path_type,
    event_type,
    COUNT(*) as occurrences, 
    MAX(timestamp) as last_occurrence
FROM file_changes 
WHERE event_type IN ('CREATED', 'MODIFIED', 'DELETED')
GROUP BY filepath, event_type, is_directory
ORDER BY occurrences DESC, last_occurrence DESC
LIMIT 15;"

# Daily statistics with enhanced folder/file breakdown
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    date(timestamp) as date, 
    COUNT(*) as total_changes,
    COUNT(DISTINCT filepath) as unique_paths,
    SUM(CASE WHEN event_type = 'CREATED' THEN 1 ELSE 0 END) as created,
    SUM(CASE WHEN event_type = 'MODIFIED' THEN 1 ELSE 0 END) as modified,
    SUM(CASE WHEN event_type = 'DELETED' THEN 1 ELSE 0 END) as deleted,
    SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folders,
    SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as files,
    MIN(timestamp) as first_change,
    MAX(timestamp) as last_change
FROM file_changes 
GROUP BY date(timestamp) 
ORDER BY date DESC 
LIMIT 7;"

# Nested folder creation tracking
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    timestamp,
    '[FOLDER] ' || filepath as folder_path,
    parent_directory,
    'CREATED' as event_type
FROM file_changes 
WHERE is_directory = 1 
  AND event_type = 'CREATED'
  AND datetime(timestamp) >= datetime('now', '-24 hours')
ORDER BY timestamp DESC;"

# Files created inside specific folders
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT DISTINCT 
    c.timestamp as created_at,
    '[FILE] ' || c.filepath as file_path,
    '[FOLDER] ' || c.parent_directory as parent_folder
FROM file_changes c
WHERE c.event_type = 'CREATED' 
  AND c.is_directory = 0
  AND datetime(c.timestamp) >= datetime('now', '-24 hours')
ORDER BY c.timestamp DESC;"
```

## 🔍 Enhanced Status Output Example

```
📊 Enhanced Folder File Monitor Status
=====================================
✅ Status: RUNNING (PID: 1234)
Config file: /Users/username/.folder_monitor_config
📄 Log: /Users/username/Logs/folder_file_monitor.log
🗄️ Database: /Users/username/Logs/folder_file_monitor.db

Monitored directories:
  - /Users/username/Documents/projects
  - /Users/username/work/code

📈 Statistics (Last 7 days):
total_changes  unique_files  unique_paths  last_change          created  modified  deleted  folders  files
-------------  ------------  ------------  -------------------  -------  --------  -------  -------  -----
142            28            31            2025-08-25 14:32:15  45       78        19       12       130

🔥 Most active paths (Last 7 days):
path_type                                     total_changes  last_change          created  modified  deleted
------------------------------------------   -------------  -------------------  -------  --------  -------
[FILE] /Users/username/Documents/projects/app.py     15     2025-08-25 14:32:15    1       14        0
[FOLDER] /Users/username/work/code/new-feature        8     2025-08-25 13:45:22    1        7        0
[FILE] /Users/username/Documents/projects/README.md  6     2025-08-25 12:10:33    1        5        0

📅 Recent activity (Last 7 days):
date_time           path_type                                    event     size
-------------------  ----------------------------------------   --------  ------
2025-08-25 14:32:15  [FILE] /Users/username/Documents/projects/app.py    MODIFIED  2.1 KB
2025-08-25 14:30:12  [FOLDER] /Users/username/work/code/new-feature      CREATED   folder
2025-08-25 14:28:45  [FILE] /Users/username/Documents/test.key           CREATED   1.5 KB
```

## Enhanced Recent Command Examples

```bash
# Show last 24 hours with folder/file breakdown (default)
~/Scripts/folder_file_monitor.sh recent

📋 File and folder changes in the last 24 hours:
===============================================
date_time           path_type                                    event     size
-------------------  ----------------------------------------   --------  ------
2025-08-25 14:32:15  [FILE] /Users/username/Documents/projects/app.py    MODIFIED  2.1 KB
2025-08-25 14:30:12  [FOLDER] /Users/username/work/code/new-feature      CREATED   folder
2025-08-25 14:28:45  [FILE] /Users/username/Documents/test.key           CREATED   1.5 KB

📊 Summary for last 24 hours:
total_changes  unique_paths  first_change         last_change          created  modified  deleted  folders  files
-------------  ------------  -------------------  -------------------  -------  --------  -------  -------  -----
48             23            2025-08-24 15:30:10  2025-08-25 14:32:15  12       28        8        5        43

# Show last 6 hours
~/Scripts/folder_file_monitor.sh recent 6

# Show last 1 hour with created items only
~/Scripts/folder_file_monitor.sh recent 1 created
```

## File Locations

| File | Location | Description |
|------|----------|-------------|
| **Enhanced script** | `~/Scripts/folder_file_monitor.sh` | Main executable with folder tracking |
| **Database** | `~/Logs/folder_file_monitor.db` | SQLite with enhanced schema |
| **Database backups** | `~/Logs/folder_file_monitor_backup_*.tar.gz` | Compressed automatic backups |
| **Enhanced log** | `~/Logs/folder_file_monitor.log` | Monitor log with [FOLDER]/[FILE] prefixes |
| **System log** | `~/Logs/folder_launchd.log` | LaunchAgent log |
| **Error log** | `~/Logs/folder_launchd_error.log` | Enhanced error log |
| **Service** | `~/Library/LaunchAgents/com.user.folder.filemonitor.plist` | Service configuration |
| **Config** | `~/.folder_monitor_config` | Directory configuration |

## 🧪 Testing Enhanced Folder Tracking with Auto-Migration

### Quick Test After Installation/Update

```bash
# The system automatically migrates your database
# Test folder creation detection:
mkdir -p ~/test-enhanced-$(date +%s)/subfolder
touch ~/test-enhanced-*/subfolder/presentation.key
touch ~/test-enhanced-*/subfolder/document.txt

# Check results (should show folders and files with [FOLDER]/[FILE] prefixes)
~/Scripts/folder_file_monitor.sh recent 1 created
```

**Expected output after migration:**
```
📋 File and folder changes in the last 1 hours:
===============================================
date_time           path_type                                           event     size
-------------------  ------------------------------------------------   --------  ------
2025-08-25 14:32:15  [FOLDER] /Users/dragon/test-enhanced-1756121721          CREATED   folder
2025-08-25 14:32:15  [FOLDER] /Users/dragon/test-enhanced-1756121721/subfolder CREATED   folder
2025-08-25 14:32:16  [FILE] /Users/dragon/test-enhanced-1756121721/subfolder/presentation.key CREATED   1.5 KB
2025-08-25 14:32:16  [FILE] /Users/dragon/test-enhanced-1756121721/subfolder/document.txt     CREATED   245 B

📊 Summary for last 1 hours:
total_changes  unique_paths  created  folders  files
-------------  ------------  -------  -------  -----
4              4             4        2        2
```

### Test Database Migration Status

```bash
# Check if migration was successful
~/Scripts/folder_file_monitor.sh status

# Should show statistics without "Database error"
# If you see statistics with folder/file breakdown, migration worked!
```

### Test Enhanced Filtering

```bash
# Test single event filtering
~/Scripts/folder_file_monitor.sh status created
~/Scripts/folder_file_monitor.sh status modified

# Test multiple event filtering  
~/Scripts/folder_file_monitor.sh recent 1 created|modified
~/Scripts/folder_file_monitor.sh recent 1 modified|deleted

# Test time-specific filtering
~/Scripts/folder_file_monitor.sh recent 1 created     # Last hour, created only
~/Scripts/folder_file_monitor.sh recent 6 modified    # Last 6 hours, modified only
```

## Enhanced Maintenance

### Clean Old Records with Enhanced Verification

```bash
# Check database size and record count before cleanup
du -h ~/Logs/folder_file_monitor.db
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folder_records,
    SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as file_records
FROM file_changes;"

# Create backup before cleanup
cp ~/Logs/folder_file_monitor.db ~/Logs/folder_file_monitor_manual_backup_$(date +%Y%m%d_%H%M%S).db
tar -czf ~/Logs/folder_file_monitor_manual_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C ~/Logs folder_file_monitor_manual_backup_*.db
rm ~/Logs/folder_file_monitor_manual_backup_*.db

# Delete records older than 90 days
sqlite3 ~/Logs/folder_file_monitor.db "
DELETE FROM file_changes 
WHERE datetime(timestamp) < datetime('now', '-90 days');"

# Optimize database with enhanced indexing
sqlite3 ~/Logs/folder_file_monitor.db "VACUUM;"

# Verify cleanup
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    COUNT(*) as remaining_records,
    SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as remaining_folders,
    SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as remaining_files
FROM file_changes;"
```

### Enhanced Database Analysis

```bash
# View enhanced database statistics with folder/file breakdown
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT filepath) as unique_paths,
    MIN(timestamp) as oldest_record,
    MAX(timestamp) as newest_record,
    COUNT(DISTINCT date(timestamp)) as days_tracked,
    SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folder_records,
    SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as file_records
FROM file_changes;"

# Top directories by activity with folder/file indicators
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    substr(filepath, 1, instr(filepath || '/', '/', instr(filepath, '/', 2) + 1) - 1) as directory,
    COUNT(*) as total_changes,
    SUM(CASE WHEN is_directory = 1 THEN 1 ELSE 0 END) as folder_changes,
    SUM(CASE WHEN is_directory = 0 THEN 1 ELSE 0 END) as file_changes
FROM file_changes 
WHERE datetime(timestamp) >= datetime('now', '-7 days')
GROUP BY directory 
ORDER BY total_changes DESC 
LIMIT 10;"

# Folder creation patterns
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    date(timestamp) as date,
    COUNT(*) as folders_created,
    COUNT(DISTINCT parent_directory) as unique_parent_dirs
FROM file_changes 
WHERE is_directory = 1 
  AND event_type = 'CREATED'
  AND datetime(timestamp) >= datetime('now', '-7 days')
GROUP BY date(timestamp)
ORDER BY date DESC;"
```

## Enhanced Troubleshooting

### Database Migration Issues

If you see "Database error" in status:

1. **Check database schema:**
   ```bash
   sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA table_info(file_changes);"
   ```
   
   Look for these columns:
   - `is_directory|INTEGER|0||0`
   - `parent_directory|TEXT|0||0`

2. **Force migration by restarting:**
   ```bash
   ~/Scripts/folder_file_monitor.sh stop
   ~/Scripts/folder_file_monitor.sh start
   ```

3. **Check migration logs:**
   ```bash
   ~/Scripts/folder_file_monitor.sh logs | grep -i migration
   ```

### Monitor doesn't detect folder creation

1. **Verify enhanced features are active:**
   ```bash
   # Check for folder tracking capability
   grep -E "(handle_nested_folders|is_directory)" ~/Scripts/folder_file_monitor.sh
   
   # Should return multiple matches if enhanced version is installed
   ```

2. **Test with simple folder creation:**
   ```bash
   mkdir ~/test-folder-$(date +%s)
   ~/Scripts/folder_file_monitor.sh recent 1 created
   ```

3. **Check database has folder tracking:**
   ```bash
   sqlite3 ~/Logs/folder_file_monitor.db "SELECT COUNT(*) FROM file_changes WHERE is_directory = 1;"
   ```

### Enhanced Diagnostics Script

Run the enhanced diagnostics script to troubleshoot migration and folder tracking:

```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/folder-file-monitor-diagnostics.sh | bash
```

This will check:
- ✅ Database schema migration status
- ✅ Enhanced folder tracking capabilities  
- ✅ Nested folder detection functions
- ✅ .key file inclusion verification
- ✅ Real-time monitoring configuration
- ✅ Compressed backup availability

### Permission or Database Issues

```bash
# Check script permissions and enhanced features
ls -la ~/Scripts/folder_file_monitor.sh
grep -E "(handle_nested_folders|is_directory)" ~/Scripts/folder_file_monitor.sh

# Check database permissions and enhanced schema
sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA integrity_check;"
sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA table_info(file_changes);"
sqlite3 ~/Logs/folder_file_monitor.db "SELECT COUNT(*) FROM file_changes WHERE is_directory = 1;"

# Check log file permissions and folder events
ls -la ~/Logs/folder_file_monitor.log
tail -20 ~/Logs/folder_file_monitor.log | grep -E "\[FOLDER\]|\[FILE\]"
```

## Uninstallation

```bash
# 1. Stop and unload enhanced service
launchctl unload ~/Library/LaunchAgents/com.user.folder.filemonitor.plist

# 2. Remove all files (preserving compressed backups)
rm -f ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
rm -f ~/Scripts/folder_file_monitor.sh
rm -f ~/.folder_monitor_config
rm -f ~/Logs/folder_file_monitor.*
rm -f ~/Logs/folder_launchd.*

# 3. Keep compressed backups (optional - remove if not needed)
# find ~/Logs -name "folder_file_monitor_backup_*.tar.gz" -delete

# 4. Clean empty directories
rmdir ~/Scripts 2>/dev/null || true
rmdir ~/Logs 2>/dev/null || true
```

## 🚀 Enhanced Features Summary

- **✅ Complete folder tracking** - Monitors folder creation, modification, deletion
- **✅ Nested folder detection** - Tracks multi-level folder structures automatically
- **✅ Real-time monitoring** - 0.1s latency for instant change detection
- **✅ Enhanced database schema** - Folder/file indicators with comprehensive indexing
- **✅ Advanced event filtering** - Single or multiple events with pipe separator (created|modified|deleted)
- **✅ Enhanced logging** - [FOLDER]/[FILE] prefixes with full timestamps
- **✅ All file types included** - Monitors .key files and all extensions
- **✅ Automatic compressed backups** - Database backups in .tar.gz format
- **✅ Enhanced statistics** - Complete folder/file breakdowns in all reports
- **✅ Intelligent duplicate prevention** - Smart timing to avoid duplicate entries
- **✅ Advanced time filtering** - Precise hour-based queries with event combinations

## Notes

- **Enhanced monitoring:** Files AND folders tracked with complete paths and type indicators
- **Improved performance:** Real-time detection with 0.1s latency and enhanced database indexing
- **Advanced filtering:** Supports complex event combinations and precise time ranges
- **Automatic backups:** Compressed database backups created during updates and reinstalls
- **Folder hierarchy:** Tracks nested folder creation at every level
- **All file types:** Includes .key files and all extensions except .DS_Store and .git internals
- **Enhanced logging:** [FOLDER]/[FILE] prefixes make it easy to distinguish between types
- **Database optimization:** Enhanced schema with folder indicators and parent directory tracking

## Contributing

1. Fork the repository
2. Create your enhanced branch (`git checkout -b feature/enhanced-folder-tracking`)
3. Commit your changes (`git commit -am 'Add enhanced folder tracking'`)
4. Push to the branch (`git push origin feature/enhanced-folder-tracking`)
5. Create a Pull Request

## License

MIT License - see LICENSE file for details.

---

**
