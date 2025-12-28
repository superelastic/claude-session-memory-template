# Investigation Documentation Protocol

## When to Create an Investigation Document

Create a structured investigation doc when:
- ✓ A hypothesis has been tested and conclusion reached
- ✓ An API/system has been investigated and behavior documented
- ✓ A technical decision has been made with clear rationale
- ✓ An approach was tried, failed, and lessons learned
- ✓ A performance issue was diagnosed and solution found
- ✓ A complex bug was traced to root cause

Do NOT create for:
- ✗ Routine feature implementation
- ✗ Simple bug fixes
- ✗ Incomplete investigations (wait until concluded)
- ✗ Work in progress (update scratchpad instead)

## How Investigation Documents Are Created

**Not automatic** - User prompts Claude:

```
User: "Create investigation doc for [topic] following the template"
```

or

```
User: "We completed the rate limiting investigation. Document it."
```

or

```
User: "Document this investigation in docs/investigations/"
```

## Claude's Process

1. **Read the template:**
   ```bash
   cat docs/investigations/INVESTIGATION_TEMPLATE.md
   ```

2. **Review session work** (from context - Claude has full session in memory)

3. **Extract key elements:**
   - What hypothesis/question prompted investigation?
   - What experiments were conducted?
   - What were the results?
   - What conclusion was reached?
   - What decisions were made?

4. **Structure according to template:**
   - Frontmatter with metadata
   - Context section
   - Hypothesis section
   - Experiments with results
   - Findings and conclusions
   - Implementation decisions
   - Next steps

5. **Create file:**
   ```
   docs/investigations/[descriptive_name].md
   ```

6. **Update index:**
   Add entry to `docs/investigations/INDEX.md`

## Investigation Document Structure

### Frontmatter (Required)

```yaml
---
type: investigation
source_sessions:
  - .session_logs/YYYY-MM/DD_HHMM_raw.jsonl
  - .session_logs/YYYY-MM/DD_HHMM_raw.jsonl
date: YYYY-MM-DD
status: concluded  # or: in-progress, blocked, abandoned
tags: [tag1, tag2, tag3]
related_investigations:
  - other_investigation.md
---
```

**Fields:**
- `type`: Always "investigation"
- `source_sessions`: Array of session log paths (creates traceability)
- `date`: When investigation concluded (or last updated)
- `status`: concluded | in-progress | blocked | abandoned
- `tags`: Relevant keywords for searching
- `related_investigations`: Links to related docs (optional)

### Content Sections

**1. Context**
- Why was this investigated?
- What prompted it?
- What was the situation?

**2. Hypothesis**
- What did we think was true?
- What were we trying to prove/disprove?
- What question were we answering?

**3. Experiments**

For each experiment:
```markdown
### Experiment N: [Name]
**Approach:** What we tried
**Expected:** What we thought would happen
**Actual:** What actually happened
**Timestamp:** HH:MM (reference to session log)
**Code/Commands:**
```bash
# Commands or code used
```
```

**4. Findings**

```markdown
### Key Discoveries
- Discovery 1: Description
- Discovery 2: Description

### Unexpected Results
- What surprised us and why

### Failed Approaches
- What didn't work
- Why it failed
- What we learned
```

**5. Conclusion**

Clear statement of what was learned and decided.

**6. Implementation Decisions**

```markdown
Based on findings, we decided:
1. **Decision 1:** Description with rationale
2. **Decision 2:** Description with rationale
```

**7. Recommendations**

```markdown
### For This Project
- Recommendation 1
- Recommendation 2

### For Future Similar Situations
- Lesson learned 1
- Lesson learned 2
```

**8. Next Steps**

```markdown
- [ ] If in-progress: Remaining work
- [ ] Follow-up investigations needed
- [ ] Implementation tasks
```

## Naming Conventions

**Good names (descriptive):**
- `rate_limit_analysis.md`
- `oauth_implementation_strategy.md`
- `websocket_reconnection_patterns.md`
- `database_connection_pool_tuning.md`

**Bad names (vague):**
- `api_stuff.md`
- `investigation1.md`
- `notes.md`
- `temp.md`

**Format:** lowercase, underscore-separated, descriptive

## Tagging Strategy

**Use specific, searchable tags:**

**Technology tags:**
- `api`, `database`, `websocket`, `oauth`, `jwt`

**Domain tags:**
- `rate-limiting`, `authentication`, `error-handling`, `performance`

**Project tags:**
- `thetadata`, `market-scanner`, `portfolio-tracker`

**Outcome tags:**
- `optimization`, `bug-fix`, `security`, `scalability`

**Format:** lowercase, hyphen-separated

**Typical tag count:** 5-10 tags per investigation

## Status Values

**concluded:**
- Investigation complete
- Conclusions solid
- Decisions made
- Implementation may or may not be done

**in-progress:**
- Active investigation
- Not yet complete
- More experiments needed
- Update scratchpad for current state

**blocked:**
- Cannot proceed
- Waiting on external factor (API access, third-party response, etc.)
- Document blocker in notes

**abandoned:**
- Decided not to pursue further
- Document why it was abandoned
- May be useful reference later

## Adding to Index

After creating investigation, update `docs/investigations/INDEX.md`:

**Add to appropriate category:**
```markdown
### API Integration
- [Rate Limit Analysis](rate_limit_analysis.md) - 2025-12-28 - concluded
- [OAuth Implementation](oauth_implementation.md) - 2025-12-20 - concluded
```

**Add to chronological list:**
```markdown
## All Investigations (Chronological)

### 2025-12
- 2025-12-28: [Rate Limit Analysis](rate_limit_analysis.md) - concluded
- 2025-12-20: [OAuth Implementation](oauth_implementation.md) - concluded
```

**Add to status tracking:**
```markdown
## By Status

### Concluded
- [Rate Limit Analysis](rate_limit_analysis.md) - 2025-12-28
```

## Multi-Session Investigations

If investigation spans multiple sessions:

**Each session:** Archive session, update scratchpad

**Final session:** Create investigation doc with all source sessions:

```yaml
---
source_sessions:
  - .session_logs/2025-12/26_1430_raw.jsonl  # Initial exploration
  - .session_logs/2025-12/27_0900_raw.jsonl  # Continued testing
  - .session_logs/2025-12/28_1000_raw.jsonl  # Concluded
---
```

## Quality Checklist

Before finalizing investigation doc:

- [ ] Frontmatter complete with all required fields
- [ ] Source sessions referenced correctly
- [ ] Clear hypothesis stated
- [ ] All experiments described with results
- [ ] Conclusion clearly stated
- [ ] Implementation decisions documented
- [ ] Next steps identified (if applicable)
- [ ] Tags added (5-10 relevant tags)
- [ ] Added to INDEX.md in appropriate categories
- [ ] Reviewed for accuracy
- [ ] Committed to git

## Examples of Good Investigations

**Example 1: API Rate Limiting**
```markdown
---
type: investigation
source_sessions:
  - .session_logs/2025-12/28_1430_raw.jsonl
date: 2025-12-28
status: concluded
tags: [api, rate-limiting, thetadata, performance]
---

# Rate Limit Analysis

## Context
ThetaData API documentation stated 100 req/min limit, but observed 429 errors 
suggested actual limit was lower.

## Hypothesis
Actual rate limit is lower than documented 100 req/min.

## Experiments

### Experiment 1: Test at Documented Limit
**Approach:** Send 100 requests in 60 seconds
**Expected:** All requests succeed
**Actual:** Requests 1-60 succeeded, 61-100 returned 429 errors
**Timestamp:** 14:35

### Experiment 2: Check Response Headers
**Approach:** Examine X-RateLimit-* headers
**Expected:** Find actual limit
**Actual:** X-RateLimit-Limit: 60, X-RateLimit-Remaining: 0
**Timestamp:** 14:42

## Conclusion
Actual rate limit is 60 req/min, not 100 as documented. Documentation is outdated.

## Implementation Decisions
1. Set throttle to 60 req/min with exponential backoff
2. Monitor X-RateLimit-Remaining header for dynamic adjustment
3. Use 50 req/min safety margin in production

## Next Steps
- [x] Implement rate limiter class
- [ ] Add integration tests
- [ ] Update configuration documentation
```

## Integration with Other Protocols

This protocol works with:
- **SESSION_END_PROTOCOL.md** - Investigation docs created at session end
- **STARTUP_PROTOCOL.md** - Investigations are found during startup search
- **RETRIEVAL_PROTOCOL.md** - Investigations are primary search target

## Notes

- Investigation docs are the "memory" of your project
- They're more valuable than raw session logs for quick retrieval
- But they link back to session logs for full context
- Quality > Quantity - only document significant investigations
- Keep them concise but complete
- Use the template consistently
