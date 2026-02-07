---
description: Initialize session memory in the current project
disable-model-invocation: true
---

# Session Memory Setup

Initialize session memory directories and add instructions to this project's CLAUDE.md.

## Steps

1. Create the storage directories:
   ```bash
   mkdir -p .session_logs/pending sessions docs/investigations docs/decisions docs/reference
   ```

2. Create `scratchpad.md` if it doesn't exist:
   ```markdown
   # Project Scratchpad

   ## Currently Working On

   (Nothing yet)

   ## Open Items

   (None yet)
   ```

3. Create `.session_logs/.manifest` if it doesn't exist (empty file)

4. Append the session memory section to the project's `CLAUDE.md`. Read the snippet from:
   !`echo ${CLAUDE_PLUGIN_ROOT}/docs/claude-session-memory.md`

   If CLAUDE.md already contains "Session Memory", skip this step.

5. Add to `.gitignore` if not already present:
   ```
   .venv
   __pycache__/
   ```

6. Tell the user what was set up and suggest committing the changes.
