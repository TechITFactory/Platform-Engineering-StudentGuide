#!/bin/bash

# =============================================================================
# Day 03 - Cleanup Script
# =============================================================================
# This script removes everything created by setup-day-03.sh
# Use this after demos or to reset for a fresh start.
#
# Usage: bash cleanup-day-03.sh
#
# What This Script Removes:
# -------------------------
# • platform-gitops-repo/ - Entire GitOps repository directory
#   ├── All Git history and commits
#   ├── All configuration files (.gitignore, .yamllint.yml, etc.)
#   ├── All documentation (README.md, artifacts/)
#   ├── All GitHub configuration (.github/)
#   ├── All folder structures (apps/, infrastructure/)
#   └── Everything under platform-gitops-repo/
#
# Safety Features:
# ----------------
# • Interactive confirmation prompt
# • Shows exactly what will be deleted
# • Can be run multiple times safely
# • No action if directory doesn't exist
# =============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${CYAN}${1}${NC}"
}

print_step() {
    echo -e "${BLUE}==>${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} ${1}"
}

print_error() {
    echo -e "${RED}✗${NC} ${1}"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} ${1}"
}

# =============================================================================
# Check if repository exists
# =============================================================================
check_repo_exists() {
    if [ ! -d "platform-gitops-repo" ]; then
        print_warning "platform-gitops-repo directory not found"
        echo ""
        echo "Nothing to clean up. Directory doesn't exist."
        echo ""
        echo "Current location: $(pwd)"
        echo ""
        exit 0
    fi
}

# =============================================================================
# Show what will be deleted
# =============================================================================
show_deletion_summary() {
    echo ""
    print_header "================================================================"
    print_header "                    CLEANUP SUMMARY"
    print_header "================================================================"
    echo ""

    print_warning "The following will be PERMANENTLY DELETED:"
    echo ""

    echo "📁 Location: $(pwd)/platform-gitops-repo"
    echo ""

    if [ -d "platform-gitops-repo/.git" ]; then
        cd platform-gitops-repo
        local commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        local branch_name=$(git branch --show-current 2>/dev/null || echo "unknown")
        cd ..

        echo "  Git Repository:"
        echo "    • Branch: $branch_name"
        echo "    • Commits: $commit_count"
        echo "    • History: Will be lost"
        echo ""
    fi

    echo "  Directories:"
    echo "    • apps/ (with dev, staging, prod)"
    echo "    • infrastructure/ (with argocd, crossplane, backstage)"
    echo "    • artifacts/section-00/"
    echo "    • .github/ (workflows, templates)"
    echo ""

    echo "  Configuration Files:"
    echo "    • .gitignore"
    echo "    • .yamllint.yml"
    echo "    • .commitlintrc.json"
    echo ""

    echo "  Documentation:"
    echo "    • README.md"
    echo "    • CODEOWNERS"
    echo "    • COMMIT_CONVENTION.md"
    echo "    • PULL_REQUEST_TEMPLATE.md"
    echo "    • All strategy and protection docs"
    echo ""

    # Count files
    local file_count=$(find platform-gitops-repo -type f 2>/dev/null | wc -l)
    local dir_count=$(find platform-gitops-repo -type d 2>/dev/null | wc -l)

    echo "  📊 Statistics:"
    echo "    • Total files: $file_count"
    echo "    • Total directories: $dir_count"
    echo ""

    print_header "================================================================"
    echo ""
}

# =============================================================================
# Confirm deletion
# =============================================================================
confirm_deletion() {
    print_warning "⚠️  WARNING: This action CANNOT be undone!"
    echo ""

    read -p "$(echo -e ${YELLOW}Type ${RED}\'DELETE\'${YELLOW} to confirm, or anything else to cancel: ${NC})" confirmation

    echo ""

    if [ "$confirmation" != "DELETE" ]; then
        print_info "Cleanup cancelled. Nothing was deleted."
        echo ""
        exit 0
    fi
}

# =============================================================================
# Perform cleanup
# =============================================================================
perform_cleanup() {
    print_step "Starting cleanup..."
    echo ""

    # Remove the directory
    print_step "Removing platform-gitops-repo/..."

    if rm -rf platform-gitops-repo; then
        print_success "Successfully removed platform-gitops-repo/"
    else
        print_error "Failed to remove platform-gitops-repo/"
        exit 1
    fi

    echo ""
    print_success "Cleanup completed!"
    echo ""
}

# =============================================================================
# Show completion summary
# =============================================================================
show_completion_summary() {
    print_header "================================================================"
    print_header "                    CLEANUP COMPLETE"
    print_header "================================================================"
    echo ""

    print_success "All demo files have been removed"
    echo ""

    echo "✓ platform-gitops-repo/ deleted"
    echo "✓ All Git history removed"
    echo "✓ All configuration files removed"
    echo "✓ All documentation removed"
    echo ""

    print_info "Ready for a fresh setup!"
    echo ""

    echo "To recreate the repository:"
    echo "  $ bash setup-day-03.sh"
    echo ""

    print_header "================================================================"
    echo ""
}

# =============================================================================
# Backup option (optional feature)
# =============================================================================
offer_backup() {
    echo ""
    read -p "$(echo -e ${BLUE}Would you like to create a backup before deleting? ${YELLOW}[y/N]${NC}: )" backup_choice

    if [[ "$backup_choice" =~ ^[Yy]$ ]]; then
        local backup_name="platform-gitops-repo-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

        print_step "Creating backup: $backup_name"

        if tar -czf "$backup_name" platform-gitops-repo 2>/dev/null; then
            print_success "Backup created: $backup_name"
            echo ""
            print_info "You can restore it later with: tar -xzf $backup_name"
            echo ""
        else
            print_warning "Backup failed, but continuing with cleanup..."
            echo ""
        fi
    fi
}

# =============================================================================
# Main execution
# =============================================================================
main() {
    clear

    echo ""
    print_header "================================================================"
    print_header "   Day 03 - Repository Cleanup Script"
    print_header "================================================================"
    echo ""

    # Check if repository exists
    check_repo_exists

    # Show what will be deleted
    show_deletion_summary

    # Offer backup option
    offer_backup

    # Confirm deletion
    confirm_deletion

    # Perform cleanup
    perform_cleanup

    # Show completion summary
    show_completion_summary
}

# Handle Ctrl+C gracefully
trap 'echo ""; print_warning "Cleanup cancelled by user"; echo ""; exit 130' INT

# Run main function
main "$@"
