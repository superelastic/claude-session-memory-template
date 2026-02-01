# Session End (Manual)

Create a session summary before ending the session.

This is an alternative to the automatic SessionEnd hook. Use this when you want more control over the summary content.

## Steps

1. Run the archive script to capture the current session:
   ```bash
   ./scripts/archive-session.sh
   ```

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

4. Delete the pending file after creating the summary:
   ```bash
   rm .session_logs/pending/*.md
   ```

## Why Manual?

The automatic SessionEnd hook archives the session but the agent hook on SessionStart handles summarization. Use this manual command when:
- You want to write the summary yourself with specific details
- You're ending a particularly complex session
- You want to capture context before a long break
