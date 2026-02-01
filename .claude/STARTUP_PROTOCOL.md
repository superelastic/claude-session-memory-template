# Session Startup Protocol

## Automatic Actions at Session Start

When starting a new Claude Code session in this project, the agent hook performs these steps automatically:

### 1. Process Pending Session Summaries

Check for pending session files in `.session_logs/pending/`:

```bash
ls .session_logs/pending/*.md 2>/dev/null
```

If pending files exist:
1. Read each pending markdown file (these are verbose session transcripts)
2. Create a focused summary (2-3 paragraphs) capturing:
   - What was worked on
   - Key decisions made
   - Problems encountered and solutions
   - Open questions or next steps
3. Write the summary to `sessions/YYYY-MM-DD-topic.md`
4. Delete the processed pending file

**Example summary format:**
```markdown
# Session: API Rate Limiting Investigation

Investigated the actual rate limits for ThetaData API. Documentation claimed 100 req/min
but testing revealed the actual limit is 60 req/min with a 429 response after exceeding.

Implemented a basic rate limiter class with token bucket algorithm. Tests passing but
exponential backoff for retry logic is still needed.

**Next steps:** Add exponential backoff, monitor rate limit headers in responses.
```

### 2. Read Last Session Summary

After processing pending files, read the most recent session summary:

```bash
ls -t sessions/*.md 2>/dev/null | head -1
```

Understand:
- What was being worked on
- What was completed
- Where we left off

### 3. Check Scratchpad

Read `scratchpad.md` for:
- Open items / TODOs
- Known issues
- Reminders
- Blocked items

### 4. Restore Context for User

Provide a brief summary:
- Last session's focus
- Current status of work
- Pending items from scratchpad
- Offer to continue or start new work

**Example:**
```
"Last session (Dec 27): Investigated ThetaData API rate limits.
 Found actual limit is 60 req/min (not 100 as documented).

 From scratchpad:
 - TODO: Implement rate limiter class with exponential backoff
 - TODO: Add rate limit header monitoring

 Ready to continue on rate limiter implementation?"
```

## If User References Past Work

When user says things like:
- "How did we handle X before?"
- "What was the solution to Y?"
- "Continue where we left off"
- "What did we decide about Z?"

Search session summaries and docs:

```bash
# Quick keyword search
rg -l "search_term" sessions/ docs/

# If too many results (>20), use semantic search
python scripts/semantic_filter.py "user's question"
```

## When NOT to Read Logs

Don't automatically read logs if:
- User explicitly says "fresh start" or "ignore previous work"
- User is clearly starting a completely unrelated task
- It's the very first session (no logs exist yet)

## Efficiency Guidelines

- **Only read last 1-2 session summaries** unless user asks for more
- **Summarize, don't paste** - Provide concise context, not full session text
- **Keep context lean** - Only bring in what's directly relevant
- **Process pending files first** - Always clear the pending queue

## The Pending Queue Pattern

```
SessionEnd → archive-session.sh → .session_logs/pending/*.md (verbose)
SessionStart → agent hook → sessions/*.md (summarized) + delete pending
```

This pattern ensures:
1. Sessions are captured immediately at end (command hook)
2. Summaries are created intelligently at start (agent hook)
3. No duplicate processing (pending files deleted after summary)

## Integration with Other Protocols

- **SESSION_END_PROTOCOL.md** - Archives sessions to pending queue
- **RETRIEVAL_PROTOCOL.md** - Search procedures for past work
- **INVESTIGATION_PROTOCOL.md** - When to create detailed investigations

## Notes

- Session logs are stored by Claude Code at `~/.claude/projects/[encoded-path]/`
- `archive-session.sh` copies them to `.session_logs/` and creates pending markdown
- The agent hook processes pending files into concise summaries
- Always respect user's explicit instructions over protocol defaults
