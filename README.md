# Enhanced Folder File Monitor - Complete Edition

Automatic monitoring of file and directory changes in multiple directories on macOS. Runs as a background service with real-time detection and logs all changes with timestamps, statistics, and CSV export. Now with complete directory monitoring, nested folder support, and instant event detection.

## Enhanced Features

- **Automatic startup** on login
- **Real-time monitoring** of files AND directories simultaneously
- **Nested directory creation** - tracks every level of folder creation
- **All file types supported** - including .key, .pem, .crt, and all other extensions
- **Instant event detection** - 0.1 second latency for immediate updates
- **SQLite database** with complete history and enhanced indexing
- **Full file path tracking** from root directory
- **Enhanced date/time error logging** with timestamps
- **Complete event tracking** - CREATED, MODIFIED, DELETED events
- **Advanced event filtering** - filter by single or multiple event types
- **Advanced time filtering** - status shows last 7 days, recent accepts hours parameter
- **Detailed statistics** by file and date with complete timestamps and event breakdown
- **CSV export** for analysis with full paths and event types
- **Smart filters** (excludes only .DS_Store, .git/, temp files)
- **Persistent configuration** in config file
- **Database backup system** - automatic compressed backups during reinstalls
- **Complete control** via enhanced commands with filtering

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
       <key>Nice</key>
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

**Automatically updates to enhanced version with complete directory monitoring and instant detection.**

## Complete Reinstallation (With Database Backup)

To update to the latest enhanced version and/or change directories (includes automatic database backup):

```bash
# Download enhanced reinstallation script with backup feature
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/reinstall_folder_file_monitor.sh -o reinstall_folder_file_monitor.sh
chmod +x reinstall_folder_file_monitor.sh

# Reinstall with enhanced features (creates compressed database backup)
./reinstall_folder_file_monitor.sh /new/path/to/monitor

# Or run without parameters to maintain current configuration
./reinstall_folder_
