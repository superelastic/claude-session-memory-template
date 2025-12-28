# Session End Protocol

## Every Session (Always)

### Step 1: Archive Session

**CRITICAL: Always run this, even for "simple" sessions**

```bash
./scripts/archive-session.sh
```

This copies the complete session from Claude's storage to `.session_logs/YYYY-MM/`.

**What it does:**
1. Finds latest session in `~/.claude/projects/[encoded-path]/`
2. Copies to `.session_logs/YYYY-MM/DD_HHMM_raw.jsonl`
3. Converts to `.session_logs/YYYY-MM/DD_HHMM_raw.md` for readability
4. Stages files for git commit

**Why always:**
- Even "simple" sessions often have valuable context
- Creates consistent timeline of project work
- Disk space is cheap (~100-500KB per session)
- You never know when you'll need it later

### Step 2: Update Scratchpad (If Needed)

Open `scratchpad.md` and update:

**Completed items:**
```markdown
## Completed This Session
- ✓ Implemented rate limiter class
- ✓ Added unit tests
```

**New open items:**
```markdown
## Open Items
- [ ] Add integration tests for rate limiter
- [ ] Update API client to use rate limiter
- [ ] Document configuration options
```

**Known issues:**
```markdown
## Known Issues
- Rate limiter doesn't handle burst traffic well
  Status: needs investigation
  Context: See session 2025-12-28_1430
```

**Next steps:**
```markdown
## Next Steps
- Implement adaptive rate limiting
- Test with production traffic patterns
```

## If Investigation Was Completed

### Step 3: Create Investigation Document

**When to create:**
- ✓ Hypothesis was tested and conclusion reached
- ✓ System/API behavior was investigated and documented
- ✓ Technical decision was made with clear rationale
- ✓ Problem was debugged and root cause found
- ✓ Performance issue was diagnosed and solution identified

**When NOT to create:**
- ✗ Simple feature implementation (unless complex decisions)
- ✗ Routine bug fixes
- ✗ Incomplete investigations (wait until concluded)
- ✗ Work in progress

**How to create:**

```
User: "Create investigation doc for [topic] following the template"
```

or

```
User: "We completed the rate limiting investigation. Document it."
```

**Claude will:**
1. Read `docs/investigations/INVESTIGATION_TEMPLATE.md`
2. Review the session work (from context)
3. Extract: hypothesis, experiments, findings, conclusions
4. Create structured markdown at `docs/investigations/[topic].md`
5. Include frontmatter with:
   - `source_sessions:` links to session logs
   - `tags:` relevant keywords
   - `status:` concluded/in-progress/blocked
   - `date:` when investigation concluded
6. Update `docs/investigations/INDEX.md`

**Review the generated document:**
- Check experiments are accurate
- Verify conclusions are correct
- Adjust next steps if needed
- Add any missing context

## If Significant Code/Design Work

### Step 3: Document Rationale (Optional)

**Option A: Ask Claude to create design doc**
```
User: "Create a design doc explaining why we chose [approach] and the trade-offs"
```

Claude creates `docs/decisions/[topic].md` with:
- Context / problem being solved
- Decision made
- Alternatives considered
- Trade-offs
- Implementation notes

**Option B: Ask Claude to add code documentation**
```
User: "Add comprehensive docstring to [class/module] explaining the design decisions"
```

Claude adds detailed documentation directly in code.

**Option C: Simple code comment**

For straightforward decisions, a comment is sufficient:

```python
# Using connection pool (max=20) based on load testing
# See: docs/investigations/connection_pooling.md
# Tested with 1000 concurrent requests, 20 provides best performance/memory trade-off
```

## Final Step: Commit

### Commit Session Log (Always)

```bash
git status  # Review what's staged
git add .session_logs/
git commit -m "Session: [brief description of what was done]"
```

**Good commit messages:**
```bash
git commit -m "Session: Rate limit investigation - found actual limit is 60/min"
git commit -m "Session: Implemented connection pooling with configurable pool size"
git commit -m "Session: Debug WebSocket reconnection issues"
```

**Bad commit messages:**
```bash
git commit -m "session"
git commit -m "updates"
git commit -m "work"
```

### Commit Investigation/Design Docs (If Created)

```bash
git add docs/investigations/
git commit -m "Investigation: [topic] - [key finding]"

# Or combine with session commit
git add .session_logs/ docs/investigations/
git commit -m "Investigation: Rate limiting - actual limit is 60/min not 100"
```

### Commit Scratchpad Changes

```bash
git add scratchpad.md
git commit -m "Update scratchpad: [what changed]"

# Or combine with session commit
git add .session_logs/ scratchpad.md
git commit -m "Session: Rate limiter implementation (in progress)"
```

## Session End Checklist

Before closing Claude Code, verify:

- [ ] Ran `./scripts/archive-session.sh`
- [ ] Updated `scratchpad.md` (if applicable)
- [ ] Created investigation doc (if investigation concluded)
- [ ] Created design doc or code documentation (if significant decisions)
- [ ] Committed session log to git
- [ ] Committed investigation/design docs to git (if created)
- [ ] Committed scratchpad changes (if updated)

## Multi-Session Investigations

If investigation spans multiple sessions:

**Each session end:**
```bash
./scripts/archive-session.sh
# Update scratchpad with progress
git add .session_logs/ scratchpad.md
git commit -m "Session: [investigation topic] - [progress made]"
```

**When investigation concludes:**
```
User: "Create investigation doc"

Claude: [creates doc referencing all session logs]
```

```yaml
---
source_sessions:
  - .session_logs/2025-12/26_1430_raw.jsonl  # Day 1
  - .session_logs/2025-12/27_0900_raw.jsonl  # Day 2
  - .session_logs/2025-12/28_1000_raw.jsonl  # Day 3 (concluded)
```

## Dealing with Interruptions

If session is interrupted before proper end:

**Quick archive:**
```bash
./scripts/archive-session.sh
```

**Quick scratchpad note:**
```bash
echo "## Interrupted $(date)" >> scratchpad.md
echo "- Was working on: [brief description]" >> scratchpad.md
echo "- Next: [what to do next]" >> scratchpad.md
```

**Quick commit:**
```bash
git add .session_logs/ scratchpad.md
git commit -m "Session: WIP - [description]"
```

**Resume later:** Startup protocol will restore context

## Automation Tips

**Shell alias:**
```bash
# Add to ~/.bashrc or ~/.zshrc
alias archive='./scripts/archive-session.sh'
```

**Git alias:**
```bash
# Add to ~/.gitconfig
[alias]
    session = "!f() { git add .session_logs/ && git commit -m \"Session: $*\"; }; f"
    
# Usage:
git session "Implemented rate limiter"
```

**VS Code task:**
```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Archive Session",
      "type": "shell",
      "command": "./scripts/archive-session.sh",
      "problemMatcher": []
    }
  ]
}
```

## What Gets Archived

The session log includes:
- All user messages
- All Claude responses
- Tool calls (bash commands, file operations, etc.)
- Command outputs
- Error messages
- Timestamps
- File paths and changes

**It does NOT include:**
- Claude's internal reasoning
- Memory/context window management details
- System prompts

## File Sizes

Typical session log sizes:
- Short session (30 min): ~50-100KB
- Medium session (1-2 hours): ~200-500KB
- Long session (3+ hours): ~500KB-2MB

These are text files and compress well in git.

## Notes

- Always archive sessions - it's the foundation of the memory system
- Investigation docs are optional - only for concluded investigations
- Design docs are optional - only for significant architectural decisions
- Code comments are often sufficient for simple decisions
- When in doubt, archive and commit - storage is cheap, lost context is expensive

## Integration with Other Protocols

This protocol works with:
- **STARTUP_PROTOCOL.md** - Next session will read this session's log
- **INVESTIGATION_PROTOCOL.md** - Provides source sessions for investigations
- **RETRIEVAL_PROTOCOL.md** - Makes sessions searchable for future work
