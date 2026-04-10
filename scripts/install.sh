#!/usr/bin/env bash
# doc-sync skill installer — Linux / macOS
# Installs the doc-sync custom skill for all supported AI agents.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<org>/doc-sync-skill/main/scripts/install.sh | bash
#
# Or download and run locally:
#   chmod +x install.sh && ./install.sh

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────

SKILL_NAME="doc-sync"
REPO_OWNER="${REPO_OWNER:-ander8a}"
REPO_NAME="${REPO_NAME:-doc-sync-skill}"
BRANCH="${BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# User-level skill directories (one per supported agent)
USER_SKILL_DIRS=(
    "$HOME/.gemini/skills"
    "$HOME/.claude/skills"
    "$HOME/.config/opencode/skills"
    "$HOME/.cursor/skills"
    "$HOME/.copilot/skills"
)

# Project-level skill directory (if running inside a project)
PROJECT_SKILL_DIR=".agent/skills"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── Functions ──────────────────────────────────────────────────────────────

info()    { echo -e "${CYAN}ℹ  $1${NC}"; }
success() { echo -e "${GREEN}✓  $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠  $1${NC}"; }
error()   { echo -e "${RED}✗  $1${NC}" >&2; }

check_dependencies() {
    local missing=()

    if ! command -v curl &>/dev/null; then
        missing+=("curl")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing[*]}"
        exit 1
    fi

    success "Dependencies satisfied"
}

detect_project_context() {
    # Check if we're inside a project that uses Gentle-AI or OpenSpec
    if [ -d "openspec" ] || [ -d ".agent" ] || [ -d ".gemini" ] || [ -d ".atl" ]; then
        return 0
    fi

    # Check for common project markers
    if [ -f "package.json" ] || [ -f "go.mod" ] || [ -f "Cargo.toml" ] \
       || [ -f "pyproject.toml" ] || [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        return 0
    fi

    return 1
}

install_skill_to_dir() {
    local target_dir="$1"
    local skill_dir="${target_dir}/${SKILL_NAME}"

    # Create target directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi

    # Create skill directory
    mkdir -p "${skill_dir}"
    mkdir -p "${skill_dir}/assets"

    # Download SKILL.md
    if curl -fSL -o "${skill_dir}/SKILL.md" "${RAW_BASE}/skills/${SKILL_NAME}/SKILL.md"; then
        success "Installed SKILL.md → ${skill_dir}/"
    else
        error "Failed to download SKILL.md from ${RAW_BASE}/skills/${SKILL_NAME}/SKILL.md"
        return 1
    fi

    # Download assets (non-critical — continue if any fail)
    local assets=("adr-template.md" "changelog-header.md" "readme-section-template.md" "openapi-scaffold.yaml")
    for asset in "${assets[@]}"; do
        if curl -fSL -o "${skill_dir}/assets/${asset}" "${RAW_BASE}/skills/${SKILL_NAME}/assets/${asset}" 2>/dev/null; then
            success "Installed asset ${asset}"
        else
            warn "Could not download asset ${asset} (may not exist in repo)"
        fi
    done
}

check_gentle_ai_installed() {
    # Check for any sign of Gentle-AI
    if command -v gentle-ai &>/dev/null; then
        return 0
    fi
    if [ -d "$HOME/.gentle-ai" ]; then
        return 0
    fi
    if [ -d "$HOME/.gemini/antigravity" ]; then
        return 0
    fi

    return 1
}

# ── Main ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   doc-sync skill installer                   ║${NC}"
echo -e "${CYAN}║   Automated documentation for Gentle-AI      ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Check dependencies
info "Checking dependencies..."
check_dependencies

# Step 2: Check Gentle-AI (warning, not blocking)
info "Checking for Gentle-AI..."
if check_gentle_ai_installed; then
    success "Gentle-AI detected"
else
    warn "Gentle-AI not detected"
    info "The skill will still install, but you need Gentle-AI to use it."
    info "Install from: github.com/Gentleman-Programming/gentle-ai"
    echo ""
    read -rp "Continue anyway? [y/N] " -n 1
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Installation cancelled."
        exit 0
    fi
fi

# Step 3: Install to user-level directories
info "Installing skill to user-level directories..."
installed_count=0
failed_count=0

for dir in "${USER_SKILL_DIRS[@]}"; do
    # Normalize path (expand ~)
    dir="${dir/#\~/$HOME}"

    # Only install if the parent directory exists (agent is installed)
    parent="$(dirname "$dir")"
    if [ -d "$parent" ]; then
        if install_skill_to_dir "$dir"; then
            ((installed_count++))
        else
            ((failed_count++))
        fi
    fi
done

info "Installed in ${installed_count} user-level location(s), ${failed_count} failed"

# Step 4: Install to project-level if applicable
if detect_project_context; then
    info "Project context detected — installing to ${PROJECT_SKILL_DIR}/"
    if install_skill_to_dir "${PROJECT_SKILL_DIR}"; then
        success "Project-level skill installed"
    else
        error "Failed to install project-level skill"
    fi
else
    info "No project context detected. Run this script inside a project to install project-level."
fi

# Step 5: Next steps
echo ""
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Open your project in your AI agent"
echo "  2. Run: /sdd-init artifact_store: openspec"
echo "     (or 'hybrid' if you also want Engram memory)"
echo "  3. The doc-sync skill will be auto-registered"
echo ""
echo "  Then use SDD normally:"
echo "    /sdd-new \"<feature description>\""
echo ""
echo "  Documentation will generate automatically on archive."
echo ""
echo "  Manual invocation:"
echo "    /doc-sync"
echo ""
