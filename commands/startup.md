---
description: Load context from previous sessions and process pending summaries
disable-model-invocation: true
---

# Session Startup

Load context from previous sessions to maintain continuity.

## Steps

1. Check for pending session files in `.session_logs/pending/`
   - If found, read each pending file and create focused summaries
   - Write summaries to `sessions/YYYY-MM-DD-topic.md`
   - Delete processed pending files

2. List files in `sessions/` to find the most recent session summary

3. Read the most recent session summary to understand:
   - What was accomplished
   - What decisions were made
   - What open threads remain

4. Check `scratchpad.md` for current TODOs and reminders

5. Briefly summarize the restored context for the user

## Summary Format

```markdown
# Session: [Brief Topic]

[2-3 paragraphs: what was accomplished, key decisions, problems solved]

Key points:
- What was worked on
- Decisions made and rationale
- Problems encountered and solutions

**Next steps:** [What to pick up next]
```
