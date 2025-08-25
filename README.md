# Folder File Monitor

Automatic monitoring of file changes in multiple directories on macOS. Runs as a background service and logs all changes with timestamps, statistics, and CSV export.

## Features

- **Automatic startup** on login
- **Real-time monitoring** of multiple directories simultaneously
- **SQLite database** with complete history
- **Detailed statistics** by file and date
- **CSV export** for analysis
- **Smart filters** (excludes .git, .DS_Store, temporary files)
- **Persistent configuration** in config file
- **Complete control** via commands

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

3. **Download main script:**
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

**You will be asked to specify which directory you want to monitor if not configured.**

## Complete Reinstallation (Change directory)

To update to the latest version and/or change the directory to monitor:

```bash
# Download reinstallation script
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/reinstall_folder_file_monitor.sh -o reinstall_folder_file_monitor.sh
chmod +x reinstall_folder_file_monitor.sh

# Reinstall specifying new directory
./reinstall_folder_file_monitor.sh /new/path/to/monitor

# Or run without parameters to be prompted for directory
./reinstall_folder_file_monitor.sh
```

## Usage Commands

### Basic Commands

```bash
# View monitor status
~/Scripts/folder_file_monitor.sh status

# View today's recent changes
~/Scripts/folder_file_monitor.sh recent

# View latest log lines
~/Scripts/folder_file_monitor.sh logs

# Export all data to CSV
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

## Advanced Queries

### Direct SQL Queries

```bash
# View all today's changes
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT timestamp, filename, event_type, file_size 
FROM file_changes 
WHERE date(timestamp) = date('now') 
ORDER BY timestamp DESC;"

# Most modified files
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT filename, COUNT(*) as modifications 
FROM file_changes 
GROUP BY filename 
ORDER BY modifications DESC 
LIMIT 10;"

# Statistics by day
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT date(timestamp) as date, COUNT(*) as changes 
FROM file_changes 
GROUP BY date(timestamp) 
ORDER BY date DESC 
LIMIT 7;"
```

## File Locations

| File | Location | Description |
|------|----------|-------------|
| **Main script** | `~/Scripts/folder_file_monitor.sh` | Main executable |
| **Database** | `~/Logs/folder_file_monitor.db` | SQLite with history |
| **Main log** | `~/Logs/folder_file_monitor.log` | Monitor log |
| **System log** | `~/Logs/folder_launchd.log` | LaunchAgent log |
| **Service** | `~/Library/LaunchAgents/com.user.folder.filemonitor.plist` | Service configuration |

## Maintenance

### Clean Old Records

```bash
# Delete records older than 90 days
sqlite3 ~/Logs/folder_file_monitor.db "
DELETE FROM file_changes 
WHERE date(timestamp) < date('now', '-90 days');"

# Optimize database
sqlite3 ~/Logs/folder_file_monitor.db "VACUUM;"
```

### View Database Size

```bash
du -h ~/Logs/folder_file_monitor.db
sqlite3 ~/Logs/folder_file_monitor.db "SELECT COUNT(*) FROM file_changes;"
```

## Uninstallation

```bash
# 1. Stop and unload service
launchctl unload ~/Library/LaunchAgents/com.user.folder.filemonitor.plist

# 2. Remove files
rm -f ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
rm -f ~/Scripts/folder_file_monitor.sh
rm -f ~/Logs/folder_file_monitor.*
rm -f ~/Logs/folder_launchd.*

# 3. Clean empty directories
rmdir ~/Scripts 2>/dev/null || true
rmdir ~/Logs 2>/dev/null || true
```

## Troubleshooting

### Monitor doesn't detect changes

1. **Verify it's running:**
   ```bash
   ~/Scripts/folder_file_monitor.sh status
   ```

2. **Check logs:**
   ```bash
   ~/Scripts/folder_file_monitor.sh logs
   tail -f ~/Logs/folder_launchd_error.log
   ```

3. **Restart service:**
   ```bash
   ~/Scripts/folder_file_monitor.sh restart
   ```

### Permission error

```bash
# Check script permissions
ls -la ~/Scripts/folder_file_monitor.sh
chmod +x ~/Scripts/folder_file_monitor.sh
```

### Fswatch not found

```bash
# Install fswatch
brew install fswatch

# Verify installation
which fswatch
fswatch --version
```

## Notes

- **Monitored files:** All except `.git/`, `.DS_Store`, temporary files (`~$`, `.swp`, `.tmp`)
- **Automatic startup:** Activates on each login
- **Performance:** Uses `LowPriorityIO` to not impact system
- **Database:** SQLite for fast queries and reliability
- **Compatibility:** macOS with Homebrew

## Contributing

1. Fork the repository
2. Create your branch (`git checkout -b feature/new-functionality`)
3. Commit your changes (`git commit -am 'Add new functionality'`)
4. Push to the branch (`git push origin feature/new-functionality`)
5. Create a Pull Request

## License

MIT License - see LICENSE file for details.
