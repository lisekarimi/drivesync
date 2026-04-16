param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
# =============================================================================
# DRIVESYNC - ONEDRIVE CLEANUP SCRIPT
# =============================================================================
# PURPOSE: Remove folders/files from OneDrive that match the ignore lists
# WHY: /MIR + /XD in drivesync.ps1 won't delete items that were already
#      synced to OneDrive before being added to the exclusion list.
# USAGE:
#   powershell -ExecutionPolicy Bypass -File cleanup_onedrive.ps1 -DryRun
#   powershell -ExecutionPolicy Bypass -File cleanup_onedrive.ps1
# =============================================================================

# Load configuration (same config.ps1 as drivesync.ps1)
$configPath = Join-Path $PSScriptRoot "config.ps1"
if (Test-Path $configPath) {
    . $configPath
    Write-Host "Configuration loaded from config.ps1"
} else {
    Write-Host "ERROR: config.ps1 not found!"
    exit 1
}

# Load the ignore lists from drivesync.ps1 so there is ONE source of truth.
# We dot-source it inside a scriptblock so we only grab the variables, not run Start-Sync.
# Simpler approach: redefine the lists here. If you prefer a single source,
# move $targetNames and $extensions into config.ps1.

$targetNames = @(
  ".env", ".git", ".ruff_cache", "node_modules", "memory", "logs",
  "build", ".ipynb_checkpoints", ".pytest_cache", "__pycache__",
  ".idea", ".coverage", ".gitlab-ci-local", "htmlcov", "temp_data",
  "mlruns", "ghforks", "datasets", "data", ".venv", ".venv-windows",
  "mlartifacts", "models", ".cache", "site", ".claude", ".vscode",
  ".next", ".open-next", ".playwright-mcp", ".wrangler", ".playwright",
  ".npm", ".yarn", "tsconfig.tsbuildinfo", "next-env.d.ts"
)

# File-name patterns (wildcards supported)
$filePatterns = @("*key.json*")

$extensions = @(
  ".pkl", ".joblib", ".h5", ".npz", ".csv", ".parquet",
  ".feather", ".log", ".tmp", ".bak", ".spec", ".db"
)

# =============================================================================
# LOGGING
# =============================================================================
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage

    $logDir = Split-Path $LogPath -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $LogPath -Value $logMessage
}

# =============================================================================
# MAIN CLEANUP
# =============================================================================
function Start-Cleanup {
    $mode = if ($DryRun) { "DRY RUN (nothing will be deleted)" } else { "LIVE (items will be deleted)" }
    Write-Log "=== Starting OneDrive Cleanup - $mode ==="
    Write-Log "Target: $OneDrivePath"

    if (!(Test-Path $OneDrivePath)) {
        Write-Log "ERROR: OneDrive path does not exist: $OneDrivePath"
        return
    }

    $deletedCount = 0
    $freedBytes = 0

    # --- Delete matching DIRECTORIES by exact name ---
    Write-Log "Scanning for directories to delete..."
    foreach ($name in $targetNames) {
        # -Directory restricts to folders; some names (tsconfig.tsbuildinfo, next-env.d.ts)
        # are files in reality but we also handle them below as files.
        $matches = Get-ChildItem -Path $OneDrivePath -Recurse -Force -Directory -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -eq $name }

        foreach ($item in $matches) {
            $size = (Get-ChildItem -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            if (-not $size) { $size = 0 }

            if ($DryRun) {
                Write-Log "[DRY RUN] Would delete DIR: $($item.FullName) ($([math]::Round($size/1MB,2)) MB)"
            } else {
                try {
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                    Write-Log "Deleted DIR: $($item.FullName) ($([math]::Round($size/1MB,2)) MB)"
                    $freedBytes += $size
                } catch {
                    Write-Log "FAILED to delete DIR $($item.FullName): $($_.Exception.Message)"
                    continue
                }
            }
            $deletedCount++
        }
    }

    # --- Delete matching FILES by exact name (catches tsconfig.tsbuildinfo etc.) ---
    Write-Log "Scanning for files to delete (by exact name)..."
    foreach ($name in $targetNames) {
        $matches = Get-ChildItem -Path $OneDrivePath -Recurse -Force -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -eq $name }

        foreach ($item in $matches) {
            if ($DryRun) {
                Write-Log "[DRY RUN] Would delete FILE: $($item.FullName) ($([math]::Round($item.Length/1KB,2)) KB)"
            } else {
                try {
                    Remove-Item -Path $item.FullName -Force -ErrorAction Stop
                    Write-Log "Deleted FILE: $($item.FullName) ($([math]::Round($item.Length/1KB,2)) KB)"
                    $freedBytes += $item.Length
                } catch {
                    Write-Log "FAILED to delete FILE $($item.FullName): $($_.Exception.Message)"
                    continue
                }
            }
            $deletedCount++
        }
    }

    # --- Delete matching FILES by wildcard pattern (e.g. *key.json*) ---
    Write-Log "Scanning for files to delete (by pattern)..."
    foreach ($pattern in $filePatterns) {
        $matches = Get-ChildItem -Path $OneDrivePath -Recurse -Force -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -like $pattern }

        foreach ($item in $matches) {
            if ($DryRun) {
                Write-Log "[DRY RUN] Would delete FILE: $($item.FullName) (pattern: $pattern)"
            } else {
                try {
                    Remove-Item -Path $item.FullName -Force -ErrorAction Stop
                    Write-Log "Deleted FILE: $($item.FullName) (pattern: $pattern)"
                    $freedBytes += $item.Length
                } catch {
                    Write-Log "FAILED to delete FILE $($item.FullName): $($_.Exception.Message)"
                    continue
                }
            }
            $deletedCount++
        }
    }

    # --- Delete matching FILES by extension ---
    Write-Log "Scanning for files to delete (by extension)..."
    foreach ($ext in $extensions) {
        $matches = Get-ChildItem -Path $OneDrivePath -Recurse -Force -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Extension -eq $ext }

        foreach ($item in $matches) {
            if ($DryRun) {
                Write-Log "[DRY RUN] Would delete FILE: $($item.FullName) ($([math]::Round($item.Length/1KB,2)) KB)"
            } else {
                try {
                    Remove-Item -Path $item.FullName -Force -ErrorAction Stop
                    Write-Log "Deleted FILE: $($item.FullName) ($([math]::Round($item.Length/1KB,2)) KB)"
                    $freedBytes += $item.Length
                } catch {
                    Write-Log "FAILED to delete FILE $($item.FullName): $($_.Exception.Message)"
                    continue
                }
            }
            $deletedCount++
        }
    }

    $freedMB = [math]::Round($freedBytes / 1MB, 2)
    if ($DryRun) {
        Write-Log "=== DRY RUN complete: $deletedCount item(s) would be deleted ==="
        Write-Log "Run again WITHOUT -DryRun to actually delete them."
    } else {
        Write-Log "=== Cleanup complete: $deletedCount item(s) deleted, $freedMB MB freed ==="
    }
}

Write-Host "DriveSync OneDrive Cleanup"
Write-Host "Target: $OneDrivePath"
Write-Host "Log:    $LogPath"
Write-Host ""

Start-Cleanup
