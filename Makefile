# =====================================
# 🔄 DriveSync - D: Drive to OneDrive Sync
# =====================================

sync: ## Run sync from D: to OneDrive
	powershell -ExecutionPolicy Bypass -File drivesync.ps1

log: ## View sync log
	powershell -Command "Get-Content 'D:\Logs\drivesync_log.txt' -Tail 20"

schedule: ## Setup 4x daily auto-sync
	powershell -ExecutionPolicy Bypass -File setup_drivesync_scheduler.ps1

cleanup-preview: ## Preview what cleanup would delete from OneDrive (safe, no deletion)
	powershell -ExecutionPolicy Bypass -File cleanup_onedrive.ps1 -DryRun

cleanup: ## Delete excluded folders/files from OneDrive (irreversible)
	powershell -ExecutionPolicy Bypass -File cleanup_onedrive.ps1

# =====================================
# 📚 Documentation & Help
# =====================================

help: ## Show this help message
	@echo Available commands:
	@echo.
	@python -c "import re; lines=open('Makefile', encoding='utf-8').readlines(); targets=[re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$',l) for l in lines]; [print(f'  make {m.group(1):<20} {m.group(2)}') for m in targets if m]"

# =====================================
# 🧹 Phony Targets
# =====================================
.PHONY: sync log schedule cleanup-preview cleanup help
