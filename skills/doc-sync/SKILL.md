---
name: doc-sync
description: >
  Generates and updates project documentation (CHANGELOG, README, ADRs, OpenAPI stubs) after code changes are completed.
  Trigger: When sdd-archive is executed, or when any code change is completed outside SDD workflow.
license: MIT
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Purpose

Automate documentation as a natural byproduct of the SDD workflow. Zero manual effort. The agent analyzes what changed and generates the appropriate documentation artifacts.

---

## When to Use

- **After `sdd-archive` completes** — primary trigger
- **After any code merge/commit** — if git hooks are configured
- **Manual invocation** — `/doc-sync` to regenerate docs for current state
- **After `sdd-verify` reports success** — lightweight docs for quick fixes

---

## Decision Tree: Two-Track System

### Step 1: Detect Track

| Condition | Track |
|-----------|-------|
| Change has `proposal.md` + `specs/` + `design.md` + `tasks.md` | **Full SDD** |
| No SDD artifacts present | **Lightweight** |

### Step 2: Analyze Change Type

Within each track, further classify:

| Change Type | Indicators | Docs to Generate |
|-------------|-----------|------------------|
| **New Feature** | proposal.md describes new capability, new modules/files added | CHANGELOG + README section + ADR (if architectural) + OpenAPI stub (if API) |
| **Refactor** | design.md mentions architecture change, files reorganized, no new behavior | CHANGELOG + ADR (if pattern changed) |
| **Bug Fix** | verify-report mentions bug, small diff, no new files | CHANGELOG "Fix:" entry |
| **Config Change** | Only config files changed (.env, yaml, toml, json) | docs/config.md update + CHANGELOG if user-facing |
| **Dependency Update** | package.json, go.mod, requirements.txt changed | CHANGELOG + ADR if breaking change or major version bump |
| **Typo/Style** | String/message changes only, formatting | CHANGELOG minimal entry (skip if trivial) |
| **Hotfix** | Urgent label, bypass of normal workflow | Lightweight CHANGELOG, full docs deferred |

---

## Full SDD Track Execution

### Input

- `proposal.md` — business context, why this change
- `specs/**/*.md` — behavioral requirements (GIVEN/WHEN/THEN)
- `design.md` — technical decisions, trade-offs
- `tasks.md` — what was implemented (check off list)
- `verify-report` — what was validated
- Git diff of changed files (if available)

### Steps

1. **Read all SDD artifacts** — understand what was planned vs what was delivered
2. **Read git diff** (if available) — understand actual code changes
3. **Classify change type** using the table above
4. **Generate documentation** based on change type (see Output Format below)
5. **Propose docs as separate commit** — "docs: update docs for <change-name>"
6. **Do NOT archive yet** — let the orchestrator complete the archive after docs are committed

### CHANGELOG Entry (Full SDD)

Format (Keep a Changelog convention):

```markdown
## [Unreleased]

### Added
- <Feature name from proposal.md> — <one-line description from tasks.md completion>

### Changed
- <What changed from design.md decisions>

### Fixed
- <Bugs fixed from verify-report>
```

### README Section (if new feature)

Add to the appropriate section of README.md:

```markdown
## Features

### <Feature Name>
<Description from proposal.md>
- **Added:** <date from archive>
- **Specs:** `openspec/specs/<capability>/spec.md`
- **Design:** `openspec/changes/archive/<name>/design.md`
```

### ADR Generation (if architectural decision)

Create `docs/adr/NNN-<slug>.md` using MADR template:

```markdown
# ADR-NNN: <Decision Title>

**Status:** Accepted
**Date:** YYYY-MM-DD
**Context:** <From design.md — what problem required a decision>
**Options Considered:**
- <Option A> — <why rejected>
- <Option B> — <why rejected>
**Decision:** <What was chosen and why, from design.md>
**Consequences:**
- ✅ <Positive outcome>
- ⚠️ <Trade-off or cost>
**Related:** `openspec/changes/archive/<name>/design.md`
```

ADR numbering: Read existing ADRs in `docs/adr/`, find highest NNN, increment by 1. If no ADRs exist, start with 001.

### OpenAPI Stub (if new/changed API)

If new endpoints detected in code diff or specs:

```yaml
# Append to docs/api/openapi.yaml
paths:
  /new-endpoint:
    post:
      summary: <From proposal.md or spec scenario>
      description: <From design.md technical approach>
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/<NewModel>'
      responses:
        '201':
          description: Created
        '400':
          description: Bad Request
```

If `openapi.yaml` doesn't exist yet, create a minimal scaffold:

```yaml
openapi: "3.0.3"
info:
  title: <Project name from proposal.md or README>
  version: "0.1.0"
  description: <From README or proposal>
paths: {}
components:
  schemas: {}
```

---

## Lightweight Track Execution

### Input

- Git diff of changed files (primary input)
- If no git diff available: list of modified files
- No SDD artifacts to read

### Steps

1. **Identify change type** from file patterns and diff content
2. **Generate minimal documentation** based on type
3. **Propose as separate commit** if git is available

### CHANGELOG Entry (Lightweight)

```markdown
## [Unreleased]

### Fixed
- <Brief description of fix from commit message or file diff>

### Changed
- <Config change description> — <variable name and purpose>

### Updated
- Dependency <name> bumped from <old> to <new>
```

### Lightweight ADR (only for significant decisions)

If config or infra change implies a lasting decision:

```markdown
# ADR-NNN: <Decision Title>

**Status:** Accepted
**Date:** YYYY-MM-DD
**Decision:** <One sentence>
**Rationale:** <One paragraph from commit message or config comment>
**Consequences:** <One bullet>
```

---

## Critical Rules

1. **NEVER block the archive** — if doc generation fails or times out, let the archive proceed. Log the failure.
2. **Docs are separate commits** — never mix doc changes with code changes in the same commit.
3. **Prefer links over duplication** — link to `openspec/changes/archive/<name>/design.md` instead of copying design decisions into ADRs.
4. **Do not generate docs for trivial changes** — typos, formatting, whitespace. Skip CHANGELOG for these.
5. **Always check for existing ADRs** before creating a new one — if a similar decision already has an ADR, update it instead.
6. **CHANGELOG format is Keep a Changelog** — Added, Changed, Deprecated, Removed, Fixed, Security sections under `[Unreleased]`.
7. **ADRs use MADR template** — Minimalist Architecture Decision Record format.
8. **Ask before overwriting** — if README or existing docs would be significantly modified, present a diff for approval first.
9. **Lightweight is the default outside SDD** — if there's no active SDD change, assume Lightweight track.

---

## Workflow: Integration with sdd-archive

```
sdd-archive receives control
    │
    ├─ 1. Orchestrator validates verify-report passed
    ├─ 2. doc-sync skill loads (auto-triggered by sdd-archive context)
    ├─ 3. doc-sync reads SDD artifacts (proposal, specs, design, tasks)
    ├─ 4. doc-sync reads git diff of change
    ├─ 5. doc-sync classifies change (Full SDD vs Lightweight)
    ├─ 6. doc-sync generates documentation artifacts
    ├─ 7. doc-sync proposes commit: "docs: update docs for <change-name>"
    ├─ 8. User reviews and approves commit (or auto-commits if configured)
    ├─ 9. Orchestrator completes archive
    └─ 10. mem_save with learnings (including what docs were generated)
```

---

## Commands

| Command | Description |
|---------|-------------|
| `/doc-sync` | Manually trigger doc generation for current state |
| `/doc-sync --dry-run` | Show what docs would be generated without writing files |
| `/doc-sync --track full` | Force Full SDD track (even without SDD artifacts) |
| `/doc-sync --track light` | Force Lightweight track |
| `/doc-sync --type adr` | Generate only an ADR for the last change |
| `/doc-sync --type changelog` | Generate only a CHANGELOG entry |
| `/doc-sync --type openapi` | Generate only OpenAPI updates |

---

## Resources

- **CHANGELOG format:** Keep a Changelog convention (Added, Changed, Deprecated, Removed, Fixed, Security)
- **ADR template:** MADR (Minimalist ADR) — see `assets/adr-template.md`
- **OpenAPI spec:** 3.0.3 — see `assets/openapi-scaffold.yaml`
- **SDD artifacts:** `openspec/changes/<name>/` — proposal.md, specs/, design.md, tasks.md
- **ADRs location:** `docs/adr/NNN-<slug>.md`
- **Config docs:** `docs/config.md` — maintain manually + AI assist for changes

---

## Skill Resolution Feedback

After completing documentation generation, report in the `skill_resolution` field of the return envelope:

| Value | Meaning |
|-------|---------|
| `injected` | All docs generated successfully |
| `fallback-partial` | Some docs generated, others skipped (log which) |
| `fallback-none` | No docs generated (input unavailable or generation failed) |

---

## Return Envelope

When invoked as part of sdd-archive, return:

```yaml
status: success | partial | failed
executive_summary: |
  One sentence: what docs were generated and where
artifacts:
  - path: CHANGELOG.md
    action: updated
  - path: docs/adr/003-use-postgresql.md
    action: created
  - path: docs/api/openapi.yaml
    action: created
next_recommended: "Review generated docs and approve commit"
risks:
  - "README section may conflict with existing content — review before merging"
skill_resolution: injected | fallback-partial | fallback-none
```
