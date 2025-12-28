# Session Startup Protocol

## Automatic Actions at Session Start

When starting a new Claude Code session in this project, perform these steps:

### 1. Read Last Session Log

```bash
# Find most recent session log
ls -t .session_logs/*/*.md 2>/dev/null | head -1
```

If session logs exist, read the most recent one to understand:
- What was being worked on
- What was completed
- What issues were encountered
- Where we left off

### 2. Check Scratchpad

Read `scratchpad.md` for:
- Open items / TODOs
- Known issues
- Next steps
- Reminders
- Blocked items

### 3. Restore Context for User

Provide a brief summary:
- Last session's focus
- Current status of work
- Pending items from scratchpad
- Offer to continue or start new work

**Example:**
```
"Last session (Dec 27, 2:30 PM): Investigated ThetaData API rate limits.
 Found actual limit is 60 req/min (not 100 as documented).
 
 From scratchpad:
 - TODO: Implement rate limiter class with exponential backoff
 - TODO: Add rate limit header monitoring
 
 Ready to continue on rate limiter implementation?"
```

### 4. If User References Past Work

When user says things like:
- "How did we handle X before?"
- "What was the solution to Y?"
- "Continue where we left off"
- "What did we decide about Z?"

Then search `docs/investigations/`:

```bash
# Quick keyword search
rg -l "search_term" docs/investigations/

# If too many results (>20), use semantic filter
python scripts/semantic_filter.py "user's question"
```

### 5. Provide Relevant Context

If past work is found:
- Summarize the key findings
- Reference the investigation document
- Offer to provide more detail if needed
- If user needs full context, check frontmatter for source_sessions

## When NOT to Read Logs

Don't automatically read logs if:
- User explicitly says "fresh start" or "ignore previous work"
- User is clearly starting a completely unrelated task
- It's the very first session in a brand new project (no logs exist yet)

## Efficiency Guidelines

- **Only read last 1-2 session logs** unless user asks for more history
- **Summarize, don't paste** - Provide concise context, not full session text
- **Use grep/search efficiently** - Don't read all investigations unless necessary
- **Keep context lean** - Only bring in what's directly relevant

## Example Startup Sequences

### First Session (No History)
```
Claude: "This appears to be a new project. I don't see any previous session logs.
         What would you like to work on?"
```

### Resume After Recent Work
```
Claude: "Reading last session from yesterday...

         Last session: Implemented connection pooling for the API client.
         Code changes in src/api_client.py. Tests passing.
         
         From scratchpad: No open items.
         
         What would you like to work on today?"
```

### Resume After Investigation
```
Claude: "Reading last session...

         Last session: Completed rate limit investigation.
         Key finding: Actual limit is 60 req/min, not 100.
         Investigation documented in docs/investigations/rate_limit_analysis.md
         
         From scratchpad:
         - TODO: Implement rate limiter class
         
         Shall we implement the rate limiter based on those findings?"
```

### User References Past Work
```
User: "How did we authenticate with the API?"

Claude: [searches investigations]
Claude: "Checking past work on API authentication...

         Found: docs/investigations/oauth_implementation.md
         
         We implemented OAuth 2.0 with PKCE flow:
         - Authorization code flow with PKCE
         - 1-hour access token lifetime
         - Automatic refresh token handling
         - Credentials stored in environment variables
         
         Would you like to see the full investigation or discuss implementation details?"
```

## Integration with Other Protocols

This protocol works with:
- **SESSION_END_PROTOCOL.md** - Ensures sessions are archived for next startup
- **INVESTIGATION_PROTOCOL.md** - Investigations are found during startup
- **RETRIEVAL_PROTOCOL.md** - Detailed search procedures when needed

## Notes

- Session logs are automatically created by Claude Code at `~/.claude/projects/[encoded-path]/`
- They're archived to `.session_logs/` at session end via `archive-session.sh`
- Always respect user's explicit instructions over protocol defaults
- Keep startup summary brief - expand only if user asks for details
