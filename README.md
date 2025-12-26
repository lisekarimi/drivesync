# DriveSync - Local to OneDrive Sync

Automatically sync local folders to OneDrive while skipping cache and large files.

## 🚀 Quick Start

1. **Configure paths in `config.ps1`:**
   ```powershell
   $SourcePath = "D:\workspace"
   $OneDrivePath = "C:\Users\YourUsername\OneDrive\YourBackupFolder"
   $LogPath = "D:\Logs\drivesync_log.txt"
   ```

2. **Run manual sync:**
   ```bash
   make sync
   ```

3. **Setup automatic scheduling:**
   ```bash
   # Run PowerShell as Administrator
   .\setup_drivesync_scheduler.ps1
   ```

## 📁 Files

- **`drivesync.ps1`** - Main sync script
- **`config.ps1`** - Your personal paths
- **`setup_drivesync_scheduler.ps1`** - Creates Windows scheduled tasks
- **`Makefile`** - Simple commands (`make sync`, `make log`, `make schedule`, `make help`)

## ⏰ Schedule

Default: Runs automatically 4 times daily at 11:00 AM, 3:00 PM, 6:00 PM, 8:00 PM.

**To customize times:** Edit the trigger times in `setup_drivesync_scheduler.ps1` before running:
```powershell
$trigger1 = New-ScheduledTaskTrigger -Daily -At "09:00"  # Change to your preferred time
$trigger2 = New-ScheduledTaskTrigger -Daily -At "13:00"  # Change to your preferred time
# etc.
```

## 📋 Commands

```bash
make sync      # Run sync now
make log       # View last 20 log entries
make schedule  # Setup automatic scheduling (requires Admin)
make help      # Show all commands
```

## 📊 Monitoring

- **Sync logs:** `D:\Logs\drivesync_log.txt`
- **Task status:** `Get-ScheduledTask -TaskName 'DriveSync*'`
- **Task history:** Task Scheduler GUI (`taskschd.msc`)

## ⚠️ Requirements

- Windows PowerShell
- OneDrive desktop app installed
- Administrative privileges (for scheduler setup only)

---

**Your workspace is now automatically backed up to OneDrive!**
