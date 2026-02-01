# Session End Protocol

## Automatic Behavior (With Hooks Enabled)

When you exit Claude Code, the **SessionEnd hook** automatically:
1. Runs `archive-session.sh`
2. Copies session JSONL to `.session_logs/YYYY-MM/`
3. Creates verbose markdown in `.session_logs/pending/`
4. Records session UUID in manifest for idempotency

The **next SessionStart** will then:
1. Agent hook reads pending files
2. Creates focused summaries in `sessions/`
3. Deletes processed pending files

**You don't need to do anything manually** if hooks are enabled.

## Manual Session End (Without Hooks)

### Step 1: Archive Session

```bash
./scripts/archive-session.sh
```

This copies the session and creates a pending markdown file.

### Step 2: Update Scratchpad (Optional)

If you have open items to track:

```markdown
## Open Items
- [ ] Add integration tests
- [ ] Update documentation

## Next Steps
- Continue implementing feature X
```

### Step 3: Commit

```bash
git add .session_logs/ scratchpad.md
git commit -m "Session: [brief description]"
```

## The Pending Queue Pattern

```
SessionEnd → archive-session.sh → .session_logs/pending/*.md (verbose)
SessionStart → agent hook → sessions/*.md (summarized) + delete pending
```

**Why this pattern?**
- Sessions are captured immediately when they end (reliability)
- Summaries are created intelligently at next start (quality)
- Agent hook has time to create meaningful summaries
- No duplicate processing (manifest tracks what's been processed)

## If Investigation Was Completed

After concluding an investigation, you can:

1. Let the automatic summary capture it
2. Or manually create a detailed investigation doc:

```
User: "Create investigation doc for [topic]"
```

Claude will create `docs/investigations/[topic].md` with:
- Hypothesis, experiments, conclusions
- Links to source sessions
- Tags for searchability

## Quick Session End Commands

```bash
# Archive only (automatic on exit with hooks)
./scripts/archive-session.sh

# Archive and commit
./scripts/archive-session.sh && git add .session_logs/ && git commit -m "Session: [description]"
```

## Shell Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias archive='./scripts/archive-session.sh'
alias session='./scripts/archive-session.sh && git add .session_logs/ && git commit -m'
# Usage: session "Implemented rate limiter"
```

## What Gets Archived

The session log includes:
- All user messages
- All Claude responses
- Tool calls and outputs
- Error messages
- Timestamps

## Notes

- With hooks enabled, archiving is automatic
- The pending queue ensures no sessions are lost
- Summaries are created at next session start
- Manual `/session-end` command available for more control
