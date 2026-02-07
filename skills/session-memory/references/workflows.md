# Session Memory Workflows

## Session Lifecycle

### Automatic Flow (with hooks enabled)

1. **SessionEnd hook** runs `archive-session.sh`:
   - Finds latest unarchived JSONL in `~/.claude/projects/`
   - Converts to readable markdown via `convert_session.py`
   - Saves to `.session_logs/pending/` and `.session_logs/YYYY-MM/`
   - Updates `.manifest` for idempotency

2. **SessionStart hook** injects context:
   - Shows scratchpad contents
   - Lists pending session files
   - Shows last session summary

3. **SessionStart agent** processes pending:
   - Reads each file in `.session_logs/pending/`
   - Creates focused summary in `sessions/YYYY-MM-DD-topic.md`
   - Deletes processed pending files

### Manual Flow

```bash
# At session end - archive current session
${CLAUDE_PLUGIN_ROOT}/scripts/archive-session.sh

# At session start - use /session-memory:startup command
```

## Creating Session Summaries

Format for `sessions/YYYY-MM-DD-topic.md`:

```markdown
# Session: [Brief Topic]

[2-3 paragraph summary covering what was accomplished,
key decisions made, and problems solved]

Key points:
- What was worked on
- Decisions made and rationale
- Problems encountered and solutions
- Open questions or concerns

**Next steps:** [What to pick up in the next session]
```

## Creating Investigation Documents

Promote insights to `docs/investigations/` when:
- Research spans multiple sessions
- Findings have lasting value for the team
- Topic warrants hypothesis-driven documentation

Investigation structure:
```markdown
# Investigation: [Title]

**Status:** active | concluded | abandoned
**Sessions:** [links to source sessions]

## Hypothesis
[What you're testing]

## Experiments
### Experiment 1: [Name]
- Setup: [what you did]
- Result: [what happened]
- Conclusion: [what it means]

## Conclusion
[Final findings and recommendations]
```

## Searching Past Work

1. **Quick keyword search**: `rg -l "term" sessions/ docs/`
2. **Semantic search**: `python ${CLAUDE_PLUGIN_ROOT}/scripts/semantic_filter.py "query"`
3. **Trace to source**: Follow session references back to `.session_logs/` for full context

## Directory Initialization

On first use, the plugin creates these directories in the host project:
```bash
mkdir -p .session_logs/pending sessions docs/investigations docs/decisions docs/reference
```

The `scratchpad.md` file is created on first write.
