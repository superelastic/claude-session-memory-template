---
description: Migrate a project from the old session-memory template to the plugin
disable-model-invocation: true
---

# Migrate from Session Memory Template

This project is using the old session-memory **template** (files in `.claude/commands/`, `.claude/hooks/`, `.claude/*_PROTOCOL.md`, `scripts/`). Migrate it to use the **plugin** instead.

## Important

- **Data is preserved**: `sessions/`, `.session_logs/`, `docs/`, and `scratchpad.md` are NOT touched
- The plugin provides the same functionality via skills, hooks, and MCP tools
- This is safe to run multiple times (idempotent)

## Steps

1. First, do a **dry run** to preview what will change:
   ```bash
   bash !`echo ${CLAUDE_PLUGIN_ROOT}/scripts/migrate-from-template.sh` --dry-run
   ```

2. Show the user the dry-run output and ask them to confirm before proceeding.

3. If confirmed, run the actual migration:
   ```bash
   bash !`echo ${CLAUDE_PLUGIN_ROOT}/scripts/migrate-from-template.sh`
   ```

4. Show the user the results, then suggest:
   - Review changes with `git diff` and `git status`
   - Commit: `git add -A && git commit -m "Migrate to session-memory plugin"`
   - Test: `/session-memory:startup`
