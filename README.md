# Folder File Monitor - Enhanced Edition

Automatic monitoring of file changes in multiple directories on macOS. Runs as a background service and logs all changes with timestamps, statistics, and CSV export. Now with enhanced features including full file paths, advanced time filtering, and improved error logging.

## Enhanced Features

- **Automatic startup** on login
- **Real-time monitoring** of multiple directories simultaneously
- **SQLite database** with complete history and enhanced indexing
- **Full file path tracking** from root directory
- **Enhanced date/time error logging** with timestamps
- **Advanced time filtering** - status shows last 7 days, recent accepts hours parameter
- **Detailed statistics** by file and date with complete timestamps
- **CSV export** for analysis with full paths
- **Smart filters** (excludes .git, .DS_Store, temporary files)
- **Persistent configuration** in config file
- **Complete control** via enhanced commands

## Installation

### Option 1: Automatic Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/install_folder_file_monitor.sh | bash
```

**You will be asked to specify which directories you want to monitor. You can add multiple directories.**

### Option 2: Installation with Specific Directory

```bash
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/install_folder_file_monitor.sh | bash -s "/path/to/your/directory"
```

### Option 3: Manual Installation

1. **Install dependencies:**
   ```bash
   brew install fswatch
   ```

2. **Create directories:**
   ```bash
   mkdir -p ~/Scripts ~/Logs ~/Library/LaunchAgents
   ```

3. **Download enhanced script:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor.sh -o ~/Scripts/folder_file_monitor.sh
   chmod +x ~/Scripts/folder_file_monitor.sh
   ```

4. **Configure directories to monitor:**
   ```bash
   echo "/path/directory1" > ~/.folder_monitor_config
   echo "/path/directory2" >> ~/.folder_monitor_config
   ```

5. **Create LaunchAgent:**
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

6. **Activate service:**
   ```bash
   launchctl load ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
   ```

7. **Verify:**
   ```bash
   ~/Scripts/folder_file_monitor.sh status
   ```

## Quick Update (If you already have it installed)

```bash
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor_update.sh | bash
```

**Automatically updates to enhanced version with full path tracking and advanced time filtering.**

## Complete Reinstallation (Change directory or upgrade to enhanced features)

To update to the latest enhanced version and/or change the directory to monitor:

```bash
# Download enhanced reinstallation script
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/reinstall_folder_file_monitor.sh -o reinstall_folder_file_monitor.sh
chmod +x reinstall_folder_file_monitor.sh

# Reinstall with enhanced features
./reinstall_folder_file_monitor.sh /new/path/to/monitor

# Or run without parameters to maintain current configuration
./reinstall_folder_file_monitor.sh
```

## Enhanced Usage Commands

### Basic Commands

```bash
# View enhanced status with full paths (last 7 days)
~/Scripts/folder_file_monitor.sh status

# View recent changes with time parameter
~/Scripts/folder_file_monitor.sh recent          # Last 24 hours (default)
~/Scripts/folder_file_monitor.sh recent 6       # Last 6 hours
~/Scripts/folder_file_monitor.sh recent 168     # Last 7 days (168 hours)

# View latest log lines with timestamps
~/Scripts/folder_file_monitor.sh logs

# Export all data with full paths to CSV
~/Scripts/folder_file_monitor.sh export
```

### Service Control

```bash
# Start monitor manually
~/Scripts/folder_file_monitor.sh start

# Stop monitor
~/Scripts/folder_file_monitor.sh stop

# Restart monitor
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

## Advanced Queries with Full Paths

### Direct SQL Queries

```bash
# View all changes with full paths from specific time period
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT timestamp, filepath, event_type, file_size 
FROM file_changes 
WHERE datetime(timestamp) >= datetime('now', '-24 hours') 
ORDER BY timestamp DESC;"

# Most modified files with full paths
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT filepath, COUNT(*) as modifications, MAX(timestamp) as last_modified
FROM file_changes 
GROUP BY filepath 
ORDER BY modifications DESC, last_modified DESC
LIMIT 10;"

# Statistics by day with enhanced details
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    date(timestamp) as date, 
    COUNT(*) as changes,
    COUNT(DISTINCT filepath) as unique_files,
    MIN(timestamp) as first_change,
    MAX(timestamp) as last_change
FROM file_changes 
GROUP BY date(timestamp) 
ORDER BY date DESC 
LIMIT 7;"
```

## Enhanced Status Output Example

```
📊 Folder File Monitor Status
=============================
✅ Status: RUNNING (PID: 1234)
Config file: /Users/username/.folder_monitor_config
📄 Log: /Users/username/Logs/folder_file_monitor.log
🗄️ Database: /Users/username/Logs/folder_file_monitor.db

Monitored directories:
  - /Users/username/Documents/projects
  - /Users/username/work/code

📈 Statistics (Last 7 days):
total_changes  unique_files  unique_paths  last_change
-------------  ------------  ------------  -------------------
142            28            31            2025-08-25 14:32:15

🔥 Most modified files (Last 7 days):
full_path                                    modifications  last_modified
-----------                                  -------------  -------------------
/Users/username/Documents/projects/app.py   15             2025-08-25 14:32:15
/Users/username/work/code/main.js           12             2025-08-25 13:45:22
/Users/username/Documents/projects/README.md 8             2025-08-25 12:10:33

📅 Recent activity (Last 7 days):
date_time           full_path                               event     size
-------------------  ------------------------------------   --------  ------
2025-08-25 14:32:15  /Users/username/Documents/projects/app.py  MODIFIED  2.1 KB
2025-08-25 14:30:12  /Users/username/work/code/main.js      MODIFIED  5.8 KB
2025-08-25 14:28:45  /Users/username/Documents/README.md    MODIFIED  1.2 KB
```

## Recent Command Examples

```bash
# Show last 24 hours (default)
~/Scripts/folder_file_monitor.sh recent

📋 File changes in the last 24 hours:
=====================================
date_time           full_path                               event     size
-------------------  ------------------------------------   --------  ------
2025-08-25 14:32:15  /Users/username/Documents/projects/app.py  MODIFIED  2.1 KB
2025-08-25 14:30:12  /Users/username/work/code/main.js      MODIFIED  5.8 KB

# Show last 6 hours
~/Scripts/folder_file_monitor.sh recent 6

# Show last 7 days (168 hours)
~/Scripts/folder_file_monitor.sh recent 168
```

## File Locations

| File | Location | Description |
|------|----------|-------------|
| **Enhanced script** | `~/Scripts/folder_file_monitor.sh` | Main executable with full path support |
| **Database** | `~/Logs/folder_file_monitor.db` | SQLite with history and enhanced indexing |
| **Enhanced log** | `~/Logs/folder_file_monitor.log` | Monitor log with timestamps and full paths |
| **System log** | `~/Logs/folder_launchd.log` | LaunchAgent log |
| **Error log** | `~/Logs/folder_launchd_error.log` | Enhanced error log with timestamps |
| **Service** | `~/Library/LaunchAgents/com.user.folder.filemonitor.plist` | Service configuration |
| **Config** | `~/.folder_monitor_config` | Directory configuration |

## Enhanced Maintenance

### Clean Old Records with Verification

```bash
# Check database size before cleanup
du -h ~/Logs/folder_file_monitor.db
sqlite3 ~/Logs/folder_file_monitor.db "SELECT COUNT(*) as total_records FROM file_changes;"

# Delete records older than 90 days
sqlite3 ~/Logs/folder_file_monitor.db "
DELETE FROM file_changes 
WHERE datetime(timestamp) < datetime('now', '-90 days');"

# Optimize database with enhanced indexing
sqlite3 ~/Logs/folder_file_monitor.db "VACUUM;"

# Verify cleanup
sqlite3 ~/Logs/folder_file_monitor.db "SELECT COUNT(*) as remaining_records FROM file_changes;"
```

### Enhanced Database Analysis

```bash
# View database statistics
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT filepath) as unique_files,
    MIN(timestamp) as oldest_record,
    MAX(timestamp) as newest_record,
    COUNT(DISTINCT date(timestamp)) as days_tracked
FROM file_changes;"

# Top directories by activity
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT 
    substr(filepath, 1, instr(filepath || '/', '/', instr(filepath, '/', 2) + 1) - 1) as directory,
    COUNT(*) as changes
FROM file_changes 
WHERE datetime(timestamp) >= datetime('now', '-7 days')
GROUP BY directory 
ORDER BY changes DESC 
LIMIT 10;"
```

## Enhanced Troubleshooting

### Monitor doesn't detect changes

1. **Check enhanced status with full diagnostics:**
   ```bash
   ~/Scripts/folder_file_monitor.sh status
   ```

2. **Check enhanced logs with timestamps:**
   ```bash
   ~/Scripts/folder_file_monitor.sh logs
   tail -f ~/Logs/folder_launchd_error.log
   ```

3. **Test with time-specific recent command:**
   ```bash
   ~/Scripts/folder_file_monitor.sh recent 1    # Last hour only
   ```

4. **Restart service:**
   ```bash
   ~/Scripts/folder_file_monitor.sh restart
   ```

### Enhanced Diagnostics Script

Run the enhanced diagnostics script to troubleshoot issues:

```bash
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder-file-monitor-diagnostics.sh | bash
```

### Permission or Database Issues

```bash
# Check script permissions
ls -la ~/Scripts/folder_file_monitor.sh
chmod +x ~/Scripts/folder_file_monitor.sh

# Check database permissions and integrity
sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA integrity_check;"
sqlite3 ~/Logs/folder_file_monitor.db "PRAGMA table_info(file_changes);"

# Check log file permissions
ls -la ~/Logs/folder_file_monitor.log
```

## Uninstallation

```bash
# 1. Stop and unload service
launchctl unload ~/Library/LaunchAgents/com.user.folder.filemonitor.plist

# 2. Remove all files
rm -f ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
rm -f ~/Scripts/folder_file_monitor.sh
rm -f ~/.folder_monitor_config
rm -f ~/Logs/folder_file_monitor.*
rm -f ~/Logs/folder_launchd.*

# 3. Clean empty directories
rmdir ~/Scripts 2>/dev/null || true
rmdir ~/Logs 2>/dev/null || true
```

## Enhanced Features Summary

- **✅ Full file paths** - Complete paths from root in all outputs
- **✅ Enhanced logging** - Timestamps on all log entries including errors
- **✅ Advanced time filtering** - Status shows 7 days, recent accepts hours parameter
- **✅ Improved database** - Better indexing and performance
- **✅ Detailed statistics** - More comprehensive file tracking
- **✅ Better error handling** - Enhanced error logging with timestamps
- **✅ Flexible time ranges** - Query any time period with precision

## Notes

- **Enhanced monitoring:** All files tracked with complete paths from root
- **Improved logging:** All log entries include full timestamps and detailed error information
- **Advanced filtering:** Status shows last 7 days by default, recent command accepts any hour value
- **Database optimization:** Enhanced indexing for better performance with large datasets
- **Automatic startup:** Activates on each login with enhanced error recovery
- **Performance:** Uses `LowPriorityIO` to not impact system performance
- **Database:** SQLite with enhanced schema for better queries and reliability
- **Compatibility:** macOS with Homebrew, optimized for macOS Sequoia

## Contributing

1. Fork the repository
2. Create your branch (`git checkout -b feature/enhanced-functionality`)
3. Commit your changes (`git commit -am 'Add enhanced functionality'`)
4. Push to the branch (`git push origin feature/enhanced-functionality`)
5. Create a Pull Request

## License

MIT License - see LICENSE file for details.

---

**Enhanced Edition** - Now with full file path tracking, advanced time filtering, and improved error logging for professional file monitoring on macOS.
