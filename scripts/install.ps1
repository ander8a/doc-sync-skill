# doc-sync skill installer — Windows PowerShell
# Installs the doc-sync custom skill for all supported AI agents.
#
# Usage:
#   irm https://raw.githubusercontent.com/<org>/doc-sync-skill/main/scripts/install.ps1 | iex
#
# Or download and run locally:
#   .\install.ps1

#Requires -Version 5.1

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ── Configuration ──────────────────────────────────────────────────────────

$SkillName = "doc-sync"
$RepoOwner = if ($env:REPO_OWNER) { $env:REPO_OWNER } else { "ander8a" }
$RepoName = if ($env:REPO_NAME) { $env:REPO_NAME } else { "doc-sync-skill" }
$Branch = $env:BRANCH -or "main"
$RawBase = "https://raw.githubusercontent.com/${RepoOwner}/${RepoName}/${Branch}"

# User-level skill directories (one per supported agent)
$UserSkillDirs = @(
    "$HOME\.gemini\skills"
    "$HOME\.claude\skills"
    "$HOME\.config\opencode\skills"
    "$HOME\.cursor\skills"
    "$HOME\.copilot\skills"
)

# Project-level skill directory (if running inside a project)
$ProjectSkillDir = ".agent\skills"

# ── Functions ──────────────────────────────────────────────────────────────

function Write-Info    { param($msg) Write-Host "ℹ  $msg" -ForegroundColor Cyan }
function Write-Ok     { param($msg) Write-Host "✓  $msg" -ForegroundColor Green }
function Write-Warn   { param($msg) Write-Host "⚠  $msg" -ForegroundColor Yellow }
function Write-Err    { param($msg) Write-Host "✗  $msg" -ForegroundColor Red -ErrorAction Continue }

function Test-GentleAiInstalled {
    # Check for gentle-ai in PATH
    if (Get-Command "gentle-ai" -ErrorAction SilentlyContinue) { return $true }
    # Check for common installation paths
    if (Test-Path "$HOME\.gentle-ai") { return $true }
    if (Test-Path "$HOME\.gemini\antigravity") { return $true }
    return $false
}

function Test-ProjectContext {
    # Check for Gentle-AI / OpenSpec markers
    if (Test-Path "openspec") { return $true }
    if (Test-Path ".agent") { return $true }
    if (Test-Path ".gemini") { return $true }
    if (Test-Path ".atl") { return $true }
    # Check for common project markers
    if (Test-Path "package.json" -or (Test-Path "go.mod") -or (Test-Path "Cargo.toml") `
        -or (Test-Path "pyproject.toml") -or (Test-Path "pom.xml") -or (Test-Path "build.gradle")) {
        return $true
    }
    return $false
}

function Install-SkillToDir {
    param([string]$TargetDir)

    $SkillDir = Join-Path $TargetDir $SkillName
    $AssetsDir = Join-Path $SkillDir "assets"

    # Create directories
    if (-not (Test-Path $SkillDir)) {
        New-Item -ItemType Directory -Path $SkillDir -Force | Out-Null
    }
    if (-not (Test-Path $AssetsDir)) {
        New-Item -ItemType Directory -Path $AssetsDir -Force | Out-Null
    }

    # Download SKILL.md
    $SkillUrl = "${RawBase}/skills/${SkillName}/SKILL.md"
    $SkillPath = Join-Path $SkillDir "SKILL.md"

    try {
        Invoke-WebRequest -Uri $SkillUrl -OutFile $SkillPath -UseBasicParsing -ErrorAction Stop
        Write-Ok "Installed SKILL.md → $SkillDir\"
    }
    catch {
        Write-Err "Failed to download SKILL.md from $SkillUrl"
        Write-Err $_.Exception.Message
        return $false
    }

    # Download assets (non-critical)
    $Assets = @("adr-template.md", "changelog-header.md", "readme-section-template.md", "openapi-scaffold.yaml")
    foreach ($asset in $Assets) {
        $AssetUrl = "${RawBase}/skills/${SkillName}/assets/${asset}"
        $AssetPath = Join-Path $AssetsDir $asset
        try {
            Invoke-WebRequest -Uri $AssetUrl -OutFile $AssetPath -UseBasicParsing -ErrorAction Stop | Out-Null
            Write-Ok "Installed asset $asset"
        }
        catch {
            Write-Warn "Could not download asset $asset (may not exist in repo)"
        }
    }

    return $true
}

# ── Main ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   doc-sync skill installer                   ║" -ForegroundColor Cyan
Write-Host "║   Automated documentation for Gentle-AI      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Gentle-AI (warning, not blocking)
Write-Info "Checking for Gentle-AI..."
if (Test-GentleAiInstalled) {
    Write-Ok "Gentle-AI detected"
}
else {
    Write-Warn "Gentle-AI not detected"
    Write-Info "The skill will still install, but you need Gentle-AI to use it."
    Write-Info "Install from: github.com/Gentleman-Programming/gentle-ai"
    Write-Host ""
    $confirm = Read-Host "Continue anyway? [y/N]"
    if ($confirm -notmatch "^[yY]") {
        Write-Info "Installation cancelled."
        return
    }
}

# Step 2: Install to user-level directories
Write-Info "Installing skill to user-level directories..."
$InstalledCount = 0
$FailedCount = 0

foreach ($dir in $UserSkillDirs) {
    # Only install if the parent directory exists (agent is installed)
    $Parent = Split-Path $dir -Parent
    if (Test-Path $Parent) {
        if (Install-SkillToDir $dir) {
            $InstalledCount++
        }
        else {
            $FailedCount++
        }
    }
}

Write-Info "Installed in $InstalledCount user-level location(s), $FailedCount failed"

# Step 3: Install to project-level if applicable
if (Test-ProjectContext) {
    Write-Info "Project context detected — installing to $ProjectSkillDir\"
    if (Install-SkillToDir $ProjectSkillDir) {
        Write-Ok "Project-level skill installed"
    }
    else {
        Write-Err "Failed to install project-level skill"
    }
}
else {
    Write-Info "No project context detected. Run this script inside a project to install project-level."
}

# Step 4: Next steps
Write-Host ""
Write-Host "══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host ""
Write-Host "  1. Open your project in your AI agent"
Write-Host "  2. Run: /sdd-init artifact_store: openspec"
Write-Host "     (or 'hybrid' if you also want Engram memory)"
Write-Host "  3. The doc-sync skill will be auto-registered"
Write-Host ""
Write-Host "  Then use SDD normally:"
Write-Host "    /sdd-new `"<feature description>`""
Write-Host ""
Write-Host "  Documentation will generate automatically on archive."
Write-Host ""
Write-Host "  Manual invocation:"
Write-Host "    /doc-sync"
Write-Host ""
