# doc-sync

**Automated documentation generation for AI-assisted development.**

A custom skill for [Gentle-AI](https://github.com/Gentleman-Programming/gentle-ai) that generates and updates project documentation (CHANGELOG, ADRs, README sections, OpenAPI stubs) automatically after code changes. Zero manual effort.

---

## The Problem

You use SDD (Spec-Driven Development) to plan and build features. You write specs, designs, tasks. You implement code. You verify. You archive. And then...

- Your CHANGELOG is outdated
- Your README doesn't mention the new feature
- Your architectural decisions live only in the AI's memory
- Your API consumers have no updated reference

**doc-sync** fixes this by generating documentation as a natural byproduct of your workflow.

---

## Features

| Feature | Description |
|---------|-------------|
| **Auto CHANGELOG** | Entries generated after every change, formatted as [Keep a Changelog](https://keepachangelog.com/) |
| **ADR Generation** | Architecture Decision Records created automatically when decisions are detected |
| **README Updates** | New features get documented in your README automatically |
| **OpenAPI Stubs** | New endpoints generate OpenAPI 3.0.3 stubs |
| **Two-Track System** | Full SDD for features, lightweight for fixes — right level of docs for every change |
| **Agent-Agnostic** | Works with Gemini CLI, Antigravity, OpenCode, Claude Code, Cursor, Copilot, and more |
| **No Hard Dependencies** | Works without Engram, without git, without CI/CD. Those are nice-to-haves |
| **Survives Updates** | Installed in user-level path, never overwritten by Gentle-AI updates |

---

## Quick Start

### Prerequisites

- **Gentle-AI** installed ([install guide](https://github.com/Gentleman-Programming/gentle-ai))
- Any AI coding assistant configured with Gentle-AI (Gemini CLI, Claude Code, Cursor, etc.)

### Installation

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/ander8a/doc-sync-skill/main/scripts/install.sh | bash
```

**Windows:**
```powershell
irm https://raw.githubusercontent.com/ander8a/doc-sync-skill/main/scripts/install.ps1 | iex
```

> Replace `ander8a` with your GitHub org or username.

### Per-Project Setup

```
# Inside your project, run:
/sdd-init artifact_store: openspec
# or 'hybrid' if you also want Engram memory
```

That's it. The skill auto-registers.

---

## Usage

### Automatic (Primary Workflow)

Use SDD normally:

```
/sdd-new "add user authentication"
# → sdd-apply
# → sdd-verify
# → sdd-archive { ← doc-sync fires here automatically }
#   → CHANGELOG updated
#   → ADR created (if architectural decision)
#   → README updated (if new feature)
#   → OpenAPI stub generated (if new endpoint)
```

### Manual Invocation

| Command | What it does |
|---------|-------------|
| `/doc-sync` | Generate docs for current state |
| `/doc-sync --dry-run` | Preview what would be generated |
| `/doc-sync --track full` | Force Full SDD documentation |
| `/doc-sync --track light` | Force Lightweight documentation |
| `/doc-sync --type adr` | Generate only an ADR |
| `/doc-sync --type changelog` | Generate only a CHANGELOG entry |
| `/doc-sync --type openapi` | Generate only OpenAPI updates |

---

## How It Works

### Two-Track System

| Track | When | What it generates |
|-------|------|-------------------|
| **Full SDD** | Change has proposal + specs + design + tasks | CHANGELOG + README section + ADR (if applicable) + OpenAPI (if API) |
| **Lightweight** | No SDD artifacts (fix, config, typo, dependency) | Minimal CHANGELOG entry, ADR only if significant |

### Decision Flow

```
sdd-archive triggered
    │
    ├─ Has SDD artifacts? → YES → Full SDD track
    │   ├─ Read proposal, specs, design, tasks
    │   ├─ Classify: feature / refactor / bug fix
    │   ├─ Generate CHANGELOG + README + ADR + OpenAPI
    │   └─ Propose as separate commit
    │
    └─ Has SDD artifacts? → NO → Lightweight track
        ├─ Analyze file diff
        ├─ Generate minimal CHANGELOG
        └─ ADR only if breaking change
```

### What Gets Documented Where

| Change Type | CHANGELOG | README | ADR | OpenAPI |
|-------------|-----------|--------|-----|---------|
| New feature | ✅ Detailed | ✅ New section | ✅ If architectural | ✅ If API |
| Refactor | ✅ Summary | ❌ | ✅ If pattern changed | ❌ |
| Bug fix | ✅ "Fix:" entry | ❌ | ❌ | ❌ |
| Config change | ✅ If user-facing | ❌ | ❌ | ❌ |
| Dependency bump | ✅ Version info | ❌ | ✅ If breaking | ❌ |
| Typo/whitespace | ❌ Skipped | ❌ | ❌ | ❌ |

---

## Supported AI Agents

| Agent | Supported | Setup |
|-------|-----------|-------|
| **Gemini CLI** | ✅ | Skill auto-installed to `~/.gemini/skills/` |
| **Antigravity** | ✅ | Same as Gemini CLI |
| **Qwen Code** | ✅ | Synced from Gemini skills |
| **OpenCode** | ✅ | Skill installed to `~/.config/opencode/skills/` |
| **Claude Code** | ✅ | Skill installed to `~/.claude/skills/` |
| **Cursor** | ✅ | Skill installed to `.cursor/skills/` (project) |
| **Copilot** | ✅ | Skill installed to `~/.copilot/skills/` |

The installer detects which agents you have and installs to all of them.

---

## Architecture

```
doc-sync-skill/
├── SKILL.md              ← Core skill logic (Markdown, ~10KB)
├── assets/
│   ├── adr-template.md   ← MADR (Minimalist ADR) template
│   ├── changelog-header.md
│   ├── readme-section-template.md
│   └── openapi-scaffold.yaml
└── scripts/
    ├── install.sh        ← Linux/macOS installer
    └── install.ps1       ← Windows installer
```

### Artifact Paths

| Generated Doc | Path |
|---|---|
| CHANGELOG | `CHANGELOG.md` (project root) |
| ADRs | `docs/adr/NNN-<slug>.md` |
| OpenAPI | `docs/api/openapi.yaml` |
| Config docs | `docs/config.md` |
| README sections | `README.md` (in place) |

---

## Configuration

### Artifact Store

Configure when running `/sdd-init`:

| Mode | Persistence | Needs MCP? | Human-readable? |
|------|-------------|------------|-----------------|
| `openspec` | Files in `openspec/` | ❌ | ✅ Yes (Markdown) |
| `engram` | Engram MCP (SQLite) | ✅ | ❌ No |
| `hybrid` | Both | ✅ | ✅ Yes |
| `none` | Inline only | ❌ | ❌ No |

**Recommendation:** `openspec` or `hybrid`. Engram-only mode loses docs if you switch machines.

### Without OpenSpec

If you don't use OpenSpec, the skill falls back to Lightweight track (CHANGELOG-only). For full documentation, use OpenSpec alongside your SDD workflow.

---

## Contributing

### Adding to a Project

```bash
# Clone this repo
git clone https://github.com/ander8a/doc-sync-skill.git

# Or just copy the skill files to your project
mkdir -p .agent/skills/doc-sync
cp doc-sync-skill/skills/doc-sync/* .agent/skills/doc-sync/
```

### Updating

Run the same install command — it overwrites the old version:

```bash
curl -fsSL https://raw.githubusercontent.com/ander8a/doc-sync-skill/main/scripts/install.sh | bash
```

---

## Roadmap

| Feature | Status |
|---------|--------|
| CHANGELOG generation | ✅ Done |
| ADR generation (MADR) | ✅ Done |
| README section updates | ✅ Done |
| OpenAPI stub generation | ✅ Done |
| Two-track system | ✅ Done |
| Multi-agent support | ✅ Done |
| C4 diagram generation | 🔄 Planned |
| GitHub Actions CI/CD | 🔄 Planned |
| OpenAPI diff/migration guides | 🔄 Planned |
| Inline docstring generation | 📋 Backlog |

---

## License

MIT — see [LICENSE](LICENSE).

---

## Acknowledgments

- Built on top of [Gentle-AI](https://github.com/Gentleman-Programming/gentle-ai) SDD orchestrator
- Uses [OpenSpec](https://github.com/Fission-AI/OpenSpec) as artifact store
- ADR format based on [MADR](https://adr.github.io/madr/)
- CHANGELOG format follows [Keep a Changelog](https://keepachangelog.com/)
