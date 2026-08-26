# =============================================================================
# Day 03 - Cleanup Script (PowerShell)
# =============================================================================
# This script removes everything created by setup-day-03.ps1
# Use this after demos or to reset for a fresh start.
#
# Usage: .\cleanup-day-03.ps1
#
# What This Script Removes:
# -------------------------
# • platform-gitops-repo\ - Entire GitOps repository directory
#   ├── All Git history and commits
#   ├── All configuration files (.gitignore, .yamllint.yml, etc.)
#   ├── All documentation (README.md, artifacts\)
#   ├── All GitHub configuration (.github\)
#   ├── All folder structures (apps\, infrastructure\)
#   └── Everything under platform-gitops-repo\
#
# Safety Features:
# ----------------
# • Interactive confirmation prompt
# • Shows exactly what will be deleted
# • Can be run multiple times safely
# • No action if directory doesn't exist
# =============================================================================

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Header {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "==> " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

# =============================================================================
# Check if repository exists
# =============================================================================
function Test-RepoExists {
    if (-not (Test-Path "platform-gitops-repo")) {
        Write-Warning-Custom "platform-gitops-repo directory not found"
        Write-Host ""
        Write-Host "Nothing to clean up. Directory doesn't exist."
        Write-Host ""
        Write-Host "Current location: $(Get-Location)"
        Write-Host ""
        exit 0
    }
}

# =============================================================================
# Show what will be deleted
# =============================================================================
function Show-DeletionSummary {
    Write-Host ""
    Write-Header "================================================================"
    Write-Header "                    CLEANUP SUMMARY"
    Write-Header "================================================================"
    Write-Host ""

    Write-Warning-Custom "The following will be PERMANENTLY DELETED:"
    Write-Host ""

    Write-Host "📁 Location: $(Get-Location)\platform-gitops-repo"
    Write-Host ""

    if (Test-Path "platform-gitops-repo\.git") {
        Push-Location "platform-gitops-repo"
        try {
            $commitCount = (git rev-list --count HEAD 2>$null)
            $branchName = (git branch --show-current 2>$null)
            if (-not $branchName) { $branchName = "unknown" }
            if (-not $commitCount) { $commitCount = "0" }

            Write-Host "  Git Repository:"
            Write-Host "    • Branch: $branchName"
            Write-Host "    • Commits: $commitCount"
            Write-Host "    • History: Will be lost"
            Write-Host ""
        }
        catch {
            Write-Host "  Git Repository: Present (details unavailable)"
            Write-Host ""
        }
        finally {
            Pop-Location
        }
    }

    Write-Host "  Directories:"
    Write-Host "    • apps\ (with dev, staging, prod)"
    Write-Host "    • infrastructure\ (with argocd, crossplane, backstage)"
    Write-Host "    • artifacts\section-00\"
    Write-Host "    • .github\ (workflows, templates)"
    Write-Host ""

    Write-Host "  Configuration Files:"
    Write-Host "    • .gitignore"
    Write-Host "    • .yamllint.yml"
    Write-Host "    • .commitlintrc.json"
    Write-Host ""

    Write-Host "  Documentation:"
    Write-Host "    • README.md"
    Write-Host "    • CODEOWNERS"
    Write-Host "    • COMMIT_CONVENTION.md"
    Write-Host "    • PULL_REQUEST_TEMPLATE.md"
    Write-Host "    • All strategy and protection docs"
    Write-Host ""

    # Count files and directories
    $fileCount = (Get-ChildItem -Path "platform-gitops-repo" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $dirCount = (Get-ChildItem -Path "platform-gitops-repo" -Recurse -Directory -ErrorAction SilentlyContinue | Measure-Object).Count

    Write-Host "  📊 Statistics:"
    Write-Host "    • Total files: $fileCount"
    Write-Host "    • Total directories: $dirCount"
    Write-Host ""

    Write-Header "================================================================"
    Write-Host ""
}

# =============================================================================
# Confirm deletion
# =============================================================================
function Confirm-Deletion {
    Write-Warning-Custom "⚠️  WARNING: This action CANNOT be undone!"
    Write-Host ""

    Write-Host "Type " -NoNewline
    Write-Host "'DELETE'" -ForegroundColor Red -NoNewline
    Write-Host " to confirm, or anything else to cancel: " -ForegroundColor Yellow -NoNewline
    $confirmation = Read-Host

    Write-Host ""

    if ($confirmation -ne "DELETE") {
        Write-Info "Cleanup cancelled. Nothing was deleted."
        Write-Host ""
        exit 0
    }
}

# =============================================================================
# Perform cleanup
# =============================================================================
function Invoke-Cleanup {
    Write-Step "Starting cleanup..."
    Write-Host ""

    # Remove the directory
    Write-Step "Removing platform-gitops-repo\..."

    try {
        Remove-Item -Path "platform-gitops-repo" -Recurse -Force -ErrorAction Stop
        Write-Success "Successfully removed platform-gitops-repo\"
    }
    catch {
        Write-Error-Custom "Failed to remove platform-gitops-repo\"
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Success "Cleanup completed!"
    Write-Host ""
}

# =============================================================================
# Show completion summary
# =============================================================================
function Show-CompletionSummary {
    Write-Header "================================================================"
    Write-Header "                    CLEANUP COMPLETE"
    Write-Header "================================================================"
    Write-Host ""

    Write-Success "All demo files have been removed"
    Write-Host ""

    Write-Host "✓ platform-gitops-repo\ deleted"
    Write-Host "✓ All Git history removed"
    Write-Host "✓ All configuration files removed"
    Write-Host "✓ All documentation removed"
    Write-Host ""

    Write-Info "Ready for a fresh setup!"
    Write-Host ""

    Write-Host "To recreate the repository:"
    Write-Host "  PS> .\setup-day-03.ps1"
    Write-Host ""

    Write-Header "================================================================"
    Write-Host ""
}

# =============================================================================
# Backup option (optional feature)
# =============================================================================
function Offer-Backup {
    Write-Host ""
    Write-Host "Would you like to create a backup before deleting? " -ForegroundColor Blue -NoNewline
    Write-Host "[y/N]" -ForegroundColor Yellow -NoNewline
    Write-Host ": " -NoNewline
    $backupChoice = Read-Host

    if ($backupChoice -match '^[Yy]$') {
        $backupName = "platform-gitops-repo-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"

        Write-Step "Creating backup: $backupName"

        try {
            # Compress the directory
            Compress-Archive -Path "platform-gitops-repo" -DestinationPath $backupName -Force
            Write-Success "Backup created: $backupName"
            Write-Host ""
            Write-Info "You can restore it later with: Expand-Archive $backupName"
            Write-Host ""
        }
        catch {
            Write-Warning-Custom "Backup failed, but continuing with cleanup..."
            Write-Host ""
        }
    }
}

# =============================================================================
# Main execution
# =============================================================================
function Main {
    Clear-Host

    Write-Host ""
    Write-Header "================================================================"
    Write-Header "   Day 03 - Repository Cleanup Script"
    Write-Header "================================================================"
    Write-Host ""

    try {
        # Check if repository exists
        Test-RepoExists

        # Show what will be deleted
        Show-DeletionSummary

        # Offer backup option
        Offer-Backup

        # Confirm deletion
        Confirm-Deletion

        # Perform cleanup
        Invoke-Cleanup

        # Show completion summary
        Show-CompletionSummary
    }
    catch {
        Write-Host ""
        Write-Error-Custom "An error occurred during cleanup"
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Stack trace:" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        Write-Host ""
        exit 1
    }
}

# Handle Ctrl+C gracefully
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-Host ""
    Write-Warning "Cleanup cancelled by user"
    Write-Host ""
}

# Run main function
Main
