# Project Scratchpad

Last updated: 2026-05-21

## Currently Working On

- Plugin maintenance: version bumps, PR cleanup, pending-summary backlog processing

## Recent Changes

- Fixed underscore-path encoding in `archive-session.sh` (PR #1, merged as `f79aab6`, v1.1.1)
- Made pending-summary queue impossible to ignore at SessionStart (PR #2, merged as `36442af`, v1.1.0)
- Cleared pending-summary backlog (5 files) and committed promoted `sessions/` summaries
- Added reference docs: `quick-start.md`, `co-located-transcripts-as-vcs-primitive.md`

## Open Items

- [ ] Consider removing `disable-model-invocation: true` from `session-end.md` (Claude can't discover it, suggests wrong name)
- [ ] Verify v1.1.1 propagates: `claude plugin update` in a project with underscores in its path, confirm sessions get archived

## Known Issues

- SessionEnd hooks are best-effort — may not fire on abrupt session close (mitigated by SessionStart catchup)
- `/plugin` UI "Update now" sometimes doesn't fetch the latest from the marketplace; workaround is remove + re-add

## Notes

- Plugin now at v1.1.1 in `.claude-plugin/plugin.json` and `marketplace.json`
- After updating the plugin, restart Claude Code so new hooks load
- Sanity check: `grep -q "ACTION REQUIRED" ~/.claude/plugins/cache/session-memory/session-memory/*/scripts/session-start-hook.sh`
- `claude --plugin-dir . -p "prompt"` for quick plugin testing
