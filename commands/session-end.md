---
description: Archive current session and create a summary before ending
disable-model-invocation: true
---

# Session End (Manual)

Create a session summary before ending. Use when you want more control than the automatic hook provides.

Archive script: !`echo ${CLAUDE_PLUGIN_ROOT}/scripts/archive-session.sh`

## Steps

1. Run the archive script shown above to capture the current session

2. If a pending file was created in `.session_logs/pending/`, read it

3. Write a focused summary to `sessions/YYYY-MM-DD-[topic].md`:

```markdown
# Session: [Brief Topic]

[2-3 paragraph summary of what was accomplished]

Key points:
- What was worked on
- Decisions made
- Problems encountered and solutions
- Open questions

**Next steps:** [What to pick up in the next session]
```

4. Delete the pending file after creating the summary

5. Update `scratchpad.md` with any open items or reminders
