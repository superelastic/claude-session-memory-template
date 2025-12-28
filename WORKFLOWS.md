# Workflows

Step-by-step guides for common scenarios.

## Workflow 1: Experimental Investigation

### Scenario
You need to investigate how something works (API behavior, library feature, etc.)

### Steps

**1. Start Session**
```bash
claude-code .
```

```
You: "Read .claude/STARTUP_PROTOCOL.md and check what we were working on"

Claude: [reads last session, checks scratchpad]
Claude: "Last session: [...]. Ready to continue or start new work?"
```

**2. Define Investigation**
```
You: "Let's investigate the ThetaData API rate limits. Documentation says 100 req/min but I'm suspicious."

Claude: "Let's test this systematically..."
```

**3. Work Together**
- Design experiments
- Run tests
- Observe results  
- Try different approaches
- Hit dead ends
- Find the answer

*All automatically captured by Claude Code*

**4. Archive Session**
```bash
./scripts/archive-session.sh
```

**5. Create Investigation Document**
```
You: "We completed the rate limit investigation. Create investigation doc following the template."

Claude: [reads docs/investigations/INVESTIGATION_TEMPLATE.md]
Claude: [creates docs/investigations/rate_limit_analysis.md]
Claude: "Investigation documented"
```

**6. Review and Commit**
```bash
# Review investigation doc
cat docs/investigations/rate_limit_analysis.md

# Check what's staged
git status

# Commit
git add .session_logs/ docs/investigations/
git commit -m "Investigation: Rate limit analysis - actual limit is 60/min not 100"
```

### Timeline Example

```
14:30 - Start session, define investigation
14:45 - First experiment (100 req/min) → fails at 61
15:00 - Check response headers → find limit is 60
15:15 - Verify with different test patterns
15:30 - Archive session, create investigation doc
15:40 - Review and commit
```

---

## Workflow 2: Feature Implementation

### Scenario
Building a new feature, want to document design rationale

### Steps

**1. Start Session**
```bash
claude-code .
```

**2. Implement Feature**
```
You: "Let's add connection pooling to the API client"

Claude: [implements feature with you]
```

**3. Archive Session**
```bash
./scripts/archive-session.sh
```

**4. Document Rationale (Optional)**

**Option A: Separate design doc**
```
You: "Create a design doc explaining why we added connection pooling and the trade-offs"

Claude: [creates docs/decisions/connection_pooling.md]
```

**Option B: Code comments**
```
You: "Add comprehensive docstring to ApiClient explaining the connection pooling design"

Claude: [adds detailed docstring to code]
```

**5. Commit**
```bash
git add .session_logs/ src/
git commit -m "Feature: Add connection pooling to API client"

# If created design doc
git add docs/decisions/
git commit -m "Design: Connection pooling rationale"
```

---

## Workflow 3: Multi-Session Investigation

### Scenario
Investigation spans multiple days/sessions

### Day 1

**Work**
```
You: "Let's start investigating WebSocket reconnection strategies"

Claude: [initial exploration]
```

**Archive**
```bash
./scripts/archive-session.sh
```

**Update Scratchpad**
```bash
vim scratchpad.md
```

```markdown
## Open Items
- [ ] Test exponential backoff approach
- [ ] Compare with linear backoff
- [ ] Measure connection stability

## Notes
- Initial tests show exponential better
- Need more data points
```

**Commit**
```bash
git add .session_logs/ scratchpad.md
git commit -m "Session: WebSocket reconnection - initial exploration"
```

### Day 2

**Resume**
```
You: "Continue session, check startup protocol"

Claude: [reads yesterday's session]
Claude: "Yesterday: Started WebSocket reconnection investigation. 
         From scratchpad: Need to test exponential backoff. Continue?"
```

**Work**
```
You: "Yes, let's test exponential backoff"

Claude: [continues investigation]
```

**Archive**
```bash
./scripts/archive-session.sh
```

**Update Scratchpad**
```bash
vim scratchpad.md
```

**Commit**
```bash
git add .session_logs/ scratchpad.md
git commit -m "Session: WebSocket reconnection - tested exponential backoff"
```

### Day 3

**Conclude**
```
You: "We've found the optimal strategy. Create investigation doc."

Claude: [creates docs/investigations/websocket_reconnection.md]
```

```markdown
---
source_sessions:
  - .session_logs/2025-12/26_1430_raw.jsonl  # Day 1
  - .session_logs/2025-12/27_0900_raw.jsonl  # Day 2
  - .session_logs/2025-12/28_1000_raw.jsonl  # Day 3
---
```

**Commit**
```bash
./scripts/archive-session.sh
git add .session_logs/ docs/investigations/ scratchpad.md
git commit -m "Investigation: WebSocket reconnection - exponential backoff optimal"
```

---

## Workflow 4: Bug Investigation

### Scenario
Tracking down a bug, want to document root cause

### Steps

**1. Start Session**
```bash
claude-code .
```

**2. Investigate Bug**
```
You: "Users reporting API timeouts. Let's investigate."

Claude: [helps debug]
```

**3. Find Root Cause**
```
Claude: "Found it - connection pool wasn't releasing connections properly."
```

**4. Fix**
```
You: "Fix it and add detailed comments explaining the bug"

Claude: [fixes code, adds comments]
```

**5. Archive**
```bash
./scripts/archive-session.sh
```

**6. Document (Choose One)**

**Option A: In code comments (simple bugs)**
```python
# Fixed bug where connections weren't released
# Root cause: __exit__ wasn't being called in exception cases
# Solution: Use try/finally to ensure cleanup
# See session: .session_logs/2025-12/28_1430_raw.jsonl
```

**Option B: Investigation doc (complex bugs)**
```
You: "Create investigation doc for this bug"

Claude: [creates docs/investigations/connection_pool_leak.md]
```

**7. Commit**
```bash
git add .session_logs/ src/
git commit -m "Bug fix: Connection pool leak in error cases"
```

---

## Workflow 5: Searching Past Work

### Scenario
New project needs solution you implemented before

### Steps

**1. Simple Grep Search**
```bash
rg -l "authentication" docs/investigations/
```

**Output:**
```
docs/investigations/oauth_implementation.md
docs/investigations/jwt_strategy.md
```

**2. Read Relevant Docs**
```bash
cat docs/investigations/oauth_implementation.md
```

**3. If Need Full Details**

Check frontmatter for source sessions:
```yaml
source_sessions:
  - .session_logs/2025-11/15_1430_raw.jsonl
```

Read the raw session:
```bash
cat .session_logs/2025-11/15_1430_raw.md
```

### Alternative: Semantic Search

**If grep returns too many results:**
```bash
python scripts/semantic_filter.py "API authentication with OAuth and JWT tokens"
```

**Output:**
```
Loading model...
Embedding 25 documents...
  0.876 - docs/investigations/oauth_implementation.md
  0.831 - docs/investigations/jwt_strategy.md  
  0.782 - docs/investigations/api_key_management.md
  0.654 - docs/investigations/token_refresh.md
  0.621 - docs/investigations/session_handling.md
```

**Read top results:**
```bash
cat docs/investigations/oauth_implementation.md
```

---

## Workflow 6: Weekly Review

### Scenario
End of week, want to review progress

### Steps

**1. Review Session Logs**
```bash
# List this week's sessions
ls -lh .session_logs/2025-12/

# Count sessions
ls .session_logs/2025-12/*.jsonl | wc -l
```

**2. Review Investigations**
```bash
# List investigations
ls -lh docs/investigations/

# Recently updated
ls -lt docs/investigations/*.md | head -5
```

**3. Check Investigation Status**
```bash
# Find in-progress investigations
rg "status: in-progress" docs/investigations/

# Find concluded this week
find docs/investigations/ -name "*.md" -mtime -7
```

**4. Update Scratchpad**
```bash
vim scratchpad.md
```

Archive completed items:
```markdown
## This Week Completed
- ✓ Rate limit investigation
- ✓ Connection pooling implementation
- ✓ OAuth integration

## Next Week
- [ ] WebSocket reconnection strategy
- [ ] Error handling improvements
```

**5. Commit Weekly Summary**
```bash
git add scratchpad.md
git commit -m "Weekly review: 2025-12-28"
```

---

## Workflow 7: Onboarding New Team Member

### Scenario
New developer joining project, needs context

### Steps

**1. Share Repository**
```bash
git clone https://github.com/team/project.git
cd project
pip install -r scripts/requirements.txt
```

**2. Review Investigation Index**
```bash
cat docs/investigations/INDEX.md
```

**3. Read Key Investigations**
```
New dev reads:
- docs/investigations/architecture_decisions.md
- docs/investigations/api_integration.md  
- docs/investigations/rate_limiting.md
```

**4. Reference Session Logs**

If questions about "why did we do it this way?":
```markdown
# In investigation doc
source_sessions:
  - .session_logs/2025-11/15_1430_raw.jsonl
```

New dev can read exact conversation:
```bash
cat .session_logs/2025-11/15_1430_raw.md
```

**5. Start Contributing**

New dev uses same workflow:
```bash
claude-code .
# Work, archive sessions, create investigation docs
```

---

## Workflow 8: Code Review

### Scenario
PR includes complex changes, need context

### Steps

**1. Check PR Description**

PR description should include:
```markdown
## Investigation
See docs/investigations/connection_pooling.md

## Session Logs
- .session_logs/2025-12/26_1430_raw.jsonl
```

**2. Read Investigation Doc**
```bash
cat docs/investigations/connection_pooling.md
```

Understand:
- Why change was made
- What alternatives were considered
- What experiments were run

**3. If Need More Detail**

Read source session:
```bash
cat .session_logs/2025-12/26_1430_raw.md
```

See exact conversation, commands, outputs

**4. Review Code**

With full context:
- Understand rationale
- Check if implementation matches investigation
- Verify edge cases from experiments

---

## Workflow 9: Dealing with Interruptions

### Scenario
Working session interrupted, need to resume later

### Steps

**1. Immediate Archive**
```bash
./scripts/archive-session.sh
```

**2. Quick Scratchpad Note**
```bash
echo "## Interrupted $(date)" >> scratchpad.md
echo "- Was working on: [description]" >> scratchpad.md
echo "- Next: [what to do next]" >> scratchpad.md
```

**3. Quick Commit**
```bash
git add .session_logs/ scratchpad.md
git commit -m "Session: WIP - [description]"
```

**4. Resume Later**
```bash
claude-code .
```

```
You: "Check startup protocol and scratchpad"

Claude: [reads last session and scratchpad]
Claude: "You were interrupted while working on [X]. 
         From scratchpad: Next step is [Y]. Continue?"
```

---

## Workflow 10: Refactoring with Documentation

### Scenario
Major refactor, want to document decisions

### Steps

**1. Before Refactor**

Create investigation doc for current state:
```
You: "Document the current architecture's problems and why we're refactoring"

Claude: [creates docs/investigations/refactor_rationale.md]
```

**2. Refactor**
```
You: "Let's refactor the connection handling"

Claude: [refactors with you]
```

**3. Document New Approach**
```
You: "Update the investigation doc with the new architecture"

Claude: [updates docs/investigations/refactor_rationale.md]
```

**4. Archive and Commit**
```bash
./scripts/archive-session.sh
git add .session_logs/ docs/investigations/ src/
git commit -m "Refactor: Connection handling architecture"
```

---

## Tips for All Workflows

### Always Archive Sessions

Even "simple" sessions. You never know when you'll need context later.

```bash
# Make it a habit
./scripts/archive-session.sh
```

### Keep Scratchpad Current

Update it during the session, not just at end:

```
You: "Add to scratchpad: TODO - implement retry logic"

Claude: [updates scratchpad.md]
```

### Use Descriptive Commit Messages

Bad:
```bash
git commit -m "session"
git commit -m "updates"
```

Good:
```bash
git commit -m "Session: Rate limit investigation - found actual limit"
git commit -m "Investigation: OAuth implementation - decided on PKCE flow"
```

### Link Investigations to Code

In code comments, reference investigation docs:

```python
# Connection pool configuration based on investigation
# See: docs/investigations/connection_pooling.md
POOL_SIZE = 20
```

### Review Investigations Periodically

Monthly:
```bash
# What did we learn this month?
find docs/investigations/ -name "*.md" -mtime -30
```

### Don't Over-Document

Not everything needs an investigation doc:
- ✓ Investigations, complex decisions
- ✗ Simple bug fixes, routine features
- ✗ Obvious implementations

Use judgment.
