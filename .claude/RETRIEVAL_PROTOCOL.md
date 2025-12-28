# Context Retrieval Protocol

## Goal
Efficiently find relevant past work without overwhelming context window.

## Step-by-Step Process

### Step 1: Identify What to Search

Extract key search terms from user query:

**Examples:**
- "How did we handle rate limiting?" → `rate limit`
- "What was our OAuth approach?" → `oauth authentication`
- "API connection issues" → `api connection`
- "authentication strategies" → `authentication strategy`

### Step 2: Run Grep Search

```bash
# Search investigation docs
rg -l "search_term" docs/investigations/

# Case-insensitive
rg -li "search_term" docs/investigations/

# Multiple terms (OR)
rg -l "oauth|jwt|authentication" docs/investigations/

# Multiple terms (AND) - pipe through grep
rg -l "api" docs/investigations/ | xargs rg -l "authentication"
```

**Grep is fast** - Use it as first pass.

### Step 3: Evaluate Result Count

```
If result_count == 0:
    No past work found
    
Else if result_count < 20:
    Read all files into context
    
Else if result_count >= 20:
    Use semantic_filter (if available)
    
Else if result_count > 100:
    Ask user to narrow scope
```

### Step 4a: Direct Read (< 20 files)

```bash
# Read all matching files
cat docs/investigations/rate_limit_analysis.md
cat docs/investigations/api_throttling.md
# ... etc
```

Claude reads all results and synthesizes answer.

### Step 4b: Semantic Filtering (>= 20 files)

```bash
# Get file list from grep
FILES=$(rg -l "search_term" docs/investigations/)

# Run semantic filter
python scripts/semantic_filter.py "user's full question or refined query" $FILES

# This returns top 5 most relevant files
```

**Then read only top 5 files.**

### Step 5: Respond to User

- Synthesize answer from investigation docs
- Cite which investigations were referenced
- If user needs more detail, check frontmatter for source_sessions
- Offer to read raw session logs if deeper context needed

## Scoping Strategies

### Strategy 1: Tag-Based Scoping

```bash
# Find docs with specific tags
rg -l "tags:.*performance" docs/investigations/

# Combine tags
rg -l "tags:.*api" docs/investigations/ | xargs rg -l "tags:.*authentication"
```

### Strategy 2: Date-Based Scoping

```bash
# Recent work only (last 30 days)
find docs/investigations/ -name "*.md" -mtime -30 | xargs rg -l "search_term"

# Specific month
rg -l "date: 2025-12" docs/investigations/ | xargs rg -l "search_term"
```

### Strategy 3: Status-Based Scoping

```bash
# Only concluded investigations
rg -l "status: concluded" docs/investigations/ | xargs rg -l "search_term"

# In-progress investigations
rg -l "status: in-progress" docs/investigations/
```

## Using Semantic Search

### When to Use

- Grep returns > 20 files
- Need conceptual matching ("authentication" should match "OAuth", "JWT", "API keys")
- Broad queries across many topics
- Want ranked results by relevance

### How to Use

```bash
python scripts/semantic_filter.py "detailed question or search query"
```

**Query tips:**
- Be specific: "API authentication strategies with OAuth 2.0"
- Not generic: "API"
- Include context: "WebSocket reconnection with exponential backoff"
- Use full sentences: "How did we handle rate limiting in the ThetaData API?"

### Understanding Results

```
  0.876 - docs/investigations/oauth_implementation.md    # Very relevant
  0.831 - docs/investigations/jwt_strategy.md            # Highly relevant
  0.782 - docs/investigations/api_key_management.md      # Relevant
  0.654 - docs/investigations/token_refresh.md           # Somewhat relevant
  0.621 - docs/investigations/session_handling.md        # Marginally relevant
```

**Relevance scores:**
- 0.8-1.0: Very relevant, definitely read
- 0.6-0.8: Relevant, probably read
- 0.4-0.6: Possibly relevant, skim
- 0.0-0.4: Likely not relevant

## Tracing to Source Sessions

When user wants full context:

**1. Read investigation doc frontmatter:**
```yaml
source_sessions:
  - .session_logs/2025-12/26_1430_raw.jsonl
  - .session_logs/2025-12/26_1830_raw.jsonl
```

**2. Read relevant session logs:**
```bash
cat .session_logs/2025-12/26_1430_raw.md
```

**3. Locate specific timestamps:**

Look for timestamps mentioned in investigation doc:
```markdown
### Experiment 1
**Timestamp:** 14:35
```

Find in session log:
```markdown
## 14:35 User
Try hitting API with 100 requests
...
```

**4. Provide detailed context:**

```
"At 14:35 on Dec 26, you suggested testing with 100 requests.
 The test showed 429 errors starting at request #61.
 At 14:42, we checked response headers and confirmed 60/min limit.
 At 14:50, we decided to implement exponential backoff.
 
 Full session available at: .session_logs/2025-12/26_1430_raw.md"
```

## Handling Edge Cases

### No Results Found

```
Claude: "I didn't find any past investigations on [topic].
         Would you like me to search raw session logs?
         Or shall we treat this as a new investigation?"
```

**Options:**
1. Search session logs (slower, more comprehensive)
2. Start new investigation
3. Refine search terms

### Too Many Results Even After Filtering

```
Claude: "Found 50+ relevant documents even after filtering.
         Can you narrow the scope?
         - Which specific aspect interests you?
         - Recent work or historical?
         - Specific technology (OAuth vs JWT vs API keys)?"
```

### Ambiguous Query

```
User: "What did we decide about that API thing?"

Claude: "I found several API-related investigations:
         - Rate limiting (ThetaData API)
         - Authentication (OAuth implementation)
         - Connection pooling (performance optimization)
         
         Which topic are you asking about?"
```

### Conflicting Information

If multiple investigations have different conclusions:

```
Claude: "I found two related investigations with different approaches:
         
         1. oauth_implementation.md (Dec 2025): Recommends OAuth 2.0 with PKCE
         2. api_authentication_v1.md (Nov 2025): Used API keys
         
         The OAuth implementation is more recent and superseded the API key approach.
         Would you like details on why we switched?"
```

## Performance Considerations

**Fast path (< 1 second):**
- Grep finds < 20 files
- Read directly into context
- Answer immediately

**Medium path (2-5 seconds):**
- Grep finds 20-100 files
- Semantic filter to top 5
- Read filtered results
- Answer with confidence

**Slow path (> 5 seconds):**
- Grep finds 100+ files
- Ask user to narrow scope
- Or use aggressive filtering (tags, dates, status)

## Quality Checks

Before responding with retrieved information:

- [ ] Information is relevant to user's question
- [ ] Sources are cited (file names)
- [ ] If multiple sources, synthesized coherently
- [ ] If uncertain, acknowledged
- [ ] Offered to provide more detail if needed
- [ ] Noted if information might be outdated

## Example Retrieval Flows

### Example 1: Simple Grep

```
User: "How did we implement OAuth?"

Claude: [runs grep]
$ rg -l "oauth" docs/investigations/
→ oauth_implementation.md

Claude: [reads file]
Claude: "We implemented OAuth 2.0 with PKCE flow in December 2025.
         Key decisions:
         - Authorization code flow with PKCE for security
         - 1-hour access token lifetime
         - Automatic refresh token handling
         - Credentials stored in environment variables
         
         See: docs/investigations/oauth_implementation.md"
```

### Example 2: Semantic Search

```
User: "What approaches have we used for API authentication across all projects?"

Claude: [runs grep]
$ rg -l "authentication" docs/investigations/
→ 25 files (too many)

Claude: [runs semantic filter]
$ python scripts/semantic_filter.py "API authentication strategies and implementations"
→ Top 5: oauth_implementation.md, jwt_strategy.md, api_key_management.md, ...

Claude: [reads top 5]
Claude: "We've used three main authentication approaches:
         
         1. OAuth 2.0 with PKCE (oauth_implementation.md)
            - Most secure, used for user-facing APIs
            - Handles token refresh automatically
            
         2. JWT tokens (jwt_strategy.md)
            - Used for service-to-service auth
            - Short-lived (15 min) with refresh capability
            
         3. API keys with HMAC (api_key_management.md)
            - Simple, used for internal tools
            - Keys rotated quarterly
         
         Which approach interests you for this project?"
```

### Example 3: Tracing to Source

```
User: "Tell me exactly how we figured out the rate limit"

Claude: [reads rate_limit_analysis.md]
Claude: [checks frontmatter for source_sessions]
Claude: [reads .session_logs/2025-12/26_1430_raw.md]

Claude: "Here's the detailed timeline:
         
         14:30 - Started investigation
         14:35 - You suggested testing with 100 req/min
         14:40 - Test ran: first 60 succeeded, 61+ failed with 429
         14:42 - Examined headers: X-RateLimit-Limit showed 60
         14:45 - Verified with multiple test patterns
         14:50 - Decided on 60 req/min with exponential backoff
         
         Full session: .session_logs/2025-12/26_1430_raw.md"
```

## Integration with Other Protocols

This protocol works with:
- **STARTUP_PROTOCOL.md** - Retrieval used during session startup
- **INVESTIGATION_PROTOCOL.md** - Retrieves existing investigations
- **SESSION_END_PROTOCOL.md** - Makes sessions available for retrieval

## Notes

- Grep is fast, use it first
- Semantic search for complex/broad queries
- Always cite sources
- Offer deeper detail via source sessions
- Don't hallucinate - if not found, say so
- Keep answers synthesized, not just quoted
