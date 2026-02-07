---
name: session-memory
description: >
  Manages persistent git-versioned session memory. Processes pending session
  summaries at startup, archives sessions at end, searches past work, and
  promotes insights to curated docs. Activates when starting or ending sessions,
  when the user references previous work or decisions, or when searching past
  sessions.
---

# Session Memory

This project uses git-versioned session memory with three layers:

1. **Raw logs** (`.session_logs/`) — Full session archives
2. **Summaries** (`sessions/`) — Concise AI-generated session summaries
3. **Curated docs** (`docs/`) — Investigations, decisions, reference material

## At Session Start: Process Pending Sessions

The startup hook injects context showing pending sessions. When you see pending files listed, process them:

1. Read each file in `.session_logs/pending/`
2. Write a summary to `sessions/YYYY-MM-DD-[topic].md` using this format:

```markdown
# Session: [Brief Topic]

[2-3 paragraphs: what was accomplished, key decisions, problems solved]

Key points:
- What was worked on
- Decisions made and rationale
- Problems encountered and solutions

**Next steps:** [What to pick up next]
```

3. Delete the processed pending file
4. Read the most recent summary from `sessions/` to understand where we left off
5. Check `scratchpad.md` for open TODOs
6. Briefly tell the user what was restored

**Example context restoration:**
```
Last session (Jan 15): Investigated ThetaData API rate limits.
Found actual limit is 60 req/min (not 100 as documented).

From scratchpad:
- TODO: Implement rate limiter with exponential backoff
- TODO: Add rate limit header monitoring

Ready to continue on rate limiter implementation?
```

### Efficiency rules

- Only read the last 1-2 session summaries unless asked for more
- Summarize, don't paste — provide concise context
- Always clear the pending queue before other work
- Skip context loading if user says "fresh start" or starts an unrelated task

## Searching Past Work

When the user references previous work ("how did we handle X?", "what did we decide about Y?"):

1. **Keyword search first** (fast):
   ```bash
   rg -l "search_term" sessions/ docs/
   ```

2. **Semantic search if too many results** (>20 matches) or query is conceptual:
   ```bash
   python scripts/semantic_filter.py "the user's question"
   ```
   Note: Requires `sentence-transformers` (`pip install -r scripts/requirements.txt`).

3. Read the most relevant results and summarize findings

Search scoping:
- `sessions/` — session summaries (start here)
- `docs/` — curated investigations, decisions, references
- `.session_logs/` — full raw archives (last resort, verbose)

## Promoting Insights to Docs

Create investigation docs in `docs/investigations/` when:
- Research spans multiple sessions
- Findings have lasting value for the team
- The topic warrants hypothesis-driven documentation

Structure: hypothesis, experiments (setup/result/conclusion), final conclusions. Link back to source sessions.

Create decision records in `docs/decisions/` for architecture choices worth preserving.

## At Session End

The end hook archives automatically. For manual archiving:
```bash
./scripts/archive-session.sh
```

Update `scratchpad.md` with any open items before ending.

## Reference

- [Architecture details](references/architecture.md) — Three-layer design, pending queue, search strategy
- [Workflow details](references/workflows.md) — Session lifecycle, summary format, directory initialization
