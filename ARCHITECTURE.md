# Architecture

## Overview

This system provides persistent, git-versioned memory for Claude Code development sessions through a three-layer architecture combined with on-demand semantic search.

## The Core Problem

During experimental development:
- Context is lost between Claude Code sessions
- Successful and failed experiments aren't documented
- No way to search past investigations
- Repeated work wastes time

## The Solution

A lightweight memory system with four key components:

1. **Layer 1: Raw Session Logs** - Complete temporal record
2. **Layer 2: Session Summaries** - AI-generated concise summaries
3. **Layer 3: Curated Documentation** - Investigations, decisions, references
4. **On-Demand Semantic Search** - Efficient retrieval

## The Pending Queue Pattern

The core innovation is the **pending queue pattern** that separates capture from summarization:

```
SessionEnd → archive-session.sh → .session_logs/pending/*.md (verbose)
SessionStart → agent hook → sessions/*.md (summarized) + delete pending
```

**Why this pattern?**
- **Reliability**: Sessions are captured immediately when they end (command hook)
- **Quality**: Summaries are created intelligently at next start (agent hook)
- **Idempotency**: Manifest tracks processed sessions, no duplicates
- **Resume safety**: Pending files survive if session ends abruptly

## Layer 1: Raw Session Logs

### Purpose
Complete audit trail of all work done in Claude Code sessions.

### Location
```
.session_logs/
└── YYYY-MM/
    ├── DD_HHMM_raw.jsonl  # Original JSONL from Claude
    └── DD_HHMM_raw.md     # Human-readable conversion
```

### Source
Claude Code automatically stores sessions at:
```
~/.claude/projects/[encoded-project-path]/
├── <uuid>.jsonl           # Main conversation
└── agent-<uuid>.jsonl     # Subagent sessions
```

Where `/home/user/projects/my-project` becomes `-home-user-projects-my-project`.

### How It's Created

**Automatic:** Claude Code writes JSONL as you work

**Archived:** At session end, you run:
```bash
./scripts/archive-session.sh
```

This copies the latest session from `~/.claude/projects/...` to `.session_logs/`

### What It Contains

- Every user message
- Every Claude response  
- All tool calls (bash, file operations, etc.)
- Command outputs
- Timestamps
- Errors and debugging information

### Why JSONL + Markdown?

**JSONL (primary):**
- Complete machine-readable record
- Can be parsed programmatically
- Exact original from Claude

**Markdown (converted):**
- Human-readable
- Easy to skim
- Better for git diffs
- Created by `convert_session.py`

### Benefits

✅ **Complete history** - Nothing is lost, even failed experiments
✅ **Context restoration** - Claude can read previous sessions
✅ **Traceable** - Link from conclusions back to exact work
✅ **Git-versioned** - History travels with code
✅ **Audit trail** - Know exactly what was tried and when

## Layer 2: Structured Investigations

### Purpose
Curated knowledge organized by topic/conclusion rather than chronologically.

### Location
```
docs/investigations/
├── INDEX.md                      # Categorized listing
├── INVESTIGATION_TEMPLATE.md     # Template to follow
├── rate_limit_analysis.md       # Example investigation
└── connection_pooling.md         # Example investigation
```

### Structure

Each investigation follows hypothesis-driven format:

```markdown
---
type: investigation
source_sessions:
  - .session_logs/2025-12/28_1430_raw.jsonl
  - .session_logs/2025-12/28_1700_raw.jsonl
date: 2025-12-28
status: concluded
tags: [api, rate-limiting, thetadata]
---

# Investigation Title

## Context
Why was this investigated?

## Hypothesis  
What did we think was true?

## Experiments
What we tried, what happened

## Conclusion
What we learned

## Implementation Decisions
What we decided to do

## Next Steps
What's remaining
```

### How It's Created

**Not automatic** - You prompt Claude:

```
You: "Create investigation doc for [topic] following the template"

Claude: [reads INVESTIGATION_TEMPLATE.md]
Claude: [reviews session work from context]
Claude: [writes structured markdown]
```

### Frontmatter

Links back to Layer 1:
```yaml
source_sessions:
  - .session_logs/2025-12/28_1430_raw.jsonl
```

This creates **bidirectional traceability**:
- Investigation → Session logs (via frontmatter)
- Session logs → Investigation (search by date/topic)

### Benefits

✅ **Curated knowledge** - Only important findings, no noise
✅ **Searchable** - Organized by topic, not time
✅ **Efficient** - Summarizes hours of work into pages
✅ **Context-preserving** - Links to full details in Layer 1
✅ **Team-shareable** - Clear documentation for others

## Information Flow

```
Session Work
    ↓
Layer 1: Raw Logs (.session_logs/)
    ↓ (after conclusion)
Layer 2: Investigations (docs/investigations/)
    ↓ (when searching)
Retrieval (grep or semantic search)
```

### Example Flow

**Day 1:**
```
Work investigating API rate limits
    ↓
archive-session.sh
    ↓
.session_logs/2025-12/28_1430_raw.jsonl created
    ↓
git commit
```

**Day 2:**
```
Continue investigation, find answer
    ↓
archive-session.sh
    ↓
.session_logs/2025-12/29_0900_raw.jsonl created
    ↓
Prompt: "Create investigation doc"
    ↓
docs/investigations/rate_limit_analysis.md created
(includes links to both session logs)
    ↓
git commit
```

**Week later:**
```
New project needs rate limiting info
    ↓
rg -l "rate limit" docs/investigations/
    ↓
Read rate_limit_analysis.md
    ↓
If need full detail, check source_sessions
    ↓
Read .session_logs/2025-12/28_1430_raw.md
```

## On-Demand Semantic Search

### The Problem

When searching past work:
- **Grep finds 50+ files** → Can't read all into context
- **Need semantic matching** → "authentication" should match "OAuth", "JWT", "API keys"

### The Solution

**Only vectorize when needed:**

```
1. Run grep: rg -l "search term" docs/investigations/
   → Returns 50 files (too many)

2. Trigger semantic filter:
   python scripts/semantic_filter.py "search query"
   
3. Semantic filter:
   - Reads all 50 files
   - Generates embeddings (outside Claude's context)
   - Computes similarity to query
   - Returns top 5 most relevant

4. Claude reads only top 5 files
   → Semantic search without context bloat
```

### Why Not Persistent Vector DB?

**Persistent vector DB:**
- ❌ Infrastructure to maintain
- ❌ Sync issues (stale index)
- ❌ Setup complexity
- ✅ Fast repeated searches

**On-demand approach:**
- ✅ No infrastructure
- ✅ Always fresh (reads current files)
- ✅ Zero setup
- ⚠️ Slower for repeated searches (~3-5 seconds)

**Trade-off:** For projects with <300 docs, on-demand is simpler and sufficient.

### How It Works

```python
# semantic_filter.py (simplified)

# 1. Read files from disk
docs = [open(path).read() for path in file_paths]

# 2. Generate embeddings (outside Claude's context)
model = SentenceTransformer('BAAI/bge-large-en-v1.5')
doc_embeddings = model.encode(docs)
query_embedding = model.encode([query])

# 3. Compute similarity
similarities = cosine_similarity(query_embedding, doc_embeddings)

# 4. Return top-k paths
top_k_paths = get_top_k(similarities, file_paths, k=5)

# Claude then reads only these 5 files
```

### Local Embeddings

Uses `sentence-transformers` with `BAAI/bge-large-en-v1.5`:
- ✅ Runs locally (no API costs)
- ✅ Good quality (~90% of OpenAI)
- ✅ Privacy (data never leaves machine)
- ⚠️ Requires torch (~2GB install)
- ⚠️ First run downloads model (~400MB)

### Performance

**Small project (<100 docs):**
- Grep: <1 second
- Semantic search: 2-5 seconds
- **Use grep primarily**

**Medium project (100-300 docs):**
- Grep often returns 20+ results
- Semantic search: 3-8 seconds
- **Use semantic search regularly**

**Large project (300+ docs):**
- Grep always returns many results
- Semantic search: 10-30 seconds
- **Consider persistent vector DB**

## Protocol Documents

Located in `.claude/`, these guide Claude's behavior.

### STARTUP_PROTOCOL.md

**Claude reads this at session start:**
1. Read last raw session log
2. Check scratchpad for open items
3. Summarize context for user
4. If user references past work, search investigations

### SESSION_END_PROTOCOL.md

**Guides session archiving:**
1. Run `archive-session.sh` (always)
2. Update scratchpad if needed
3. Create investigation doc if concluded
4. Commit to git

### INVESTIGATION_PROTOCOL.md

**Guides investigation documentation:**
- When to create investigation docs
- How to structure them
- What to include/exclude
- How to link to source sessions

### RETRIEVAL_PROTOCOL.md

**Guides searching past work:**
- When to use grep vs semantic search
- How to scope searches
- How to trace back to raw logs
- What to do if nothing found

## Key Design Decisions

### Why Two Layers?

**Layer 1 alone:**
- ❌ Too much to read (hours of dialogue)
- ❌ Hard to find specific findings
- ❌ Noise mixed with signal

**Layer 2 alone:**
- ❌ Loses context
- ❌ Can't trace back to exact moments
- ❌ Might miss important details

**Both together:**
- ✅ Quick retrieval (Layer 2)
- ✅ Full context available (Layer 1)
- ✅ Traceable (frontmatter links)

### Why Git-Versioned?

**Alternatives:**
- Database (SQLite, Postgres)
- External tool (Notion, Obsidian)
- Cloud service

**Git wins because:**
- ✅ Already using git for code
- ✅ History travels with project
- ✅ Team can access
- ✅ No external dependencies
- ✅ Works offline
- ✅ Familiar workflow

### Why Markdown?

**Alternatives:**
- JSON/YAML (machine-readable)
- PDF (formatted)
- Wiki (linked)

**Markdown wins because:**
- ✅ Human-readable
- ✅ Git-friendly diffs
- ✅ Universal tools support
- ✅ Easy to write/edit
- ✅ Can include code blocks
- ✅ Converts to other formats

### Why Per-Project Search?

**Alternative: Cross-project vector DB**

**Per-project wins for:**
- ✅ Simplicity (no central database)
- ✅ No project path management
- ✅ Each project independent
- ✅ No shared state to corrupt

**Cross-project needed when:**
- 5+ related projects
- Want to find patterns across projects
- Institutional knowledge building

**Start simple, upgrade if needed.**

## Scaling Path

### Small (<100 docs)
- Grep only
- Layer 1 + Layer 2
- No semantic search needed

### Medium (100-300 docs)
- Grep + on-demand semantic search
- Layer 1 + Layer 2
- Current template handles this

### Large (300-1000 docs)
- Semantic search primary
- Consider caching embeddings
- Maybe persistent vector DB

### Very Large (1000+ docs)
- Persistent vector DB required
- Cross-project search
- May need mcp-memory-service

**Key:** Start simple, only add complexity when needed.

## Benefits Summary

**For Claude:**
- ✅ Context restoration between sessions
- ✅ No repeated failed experiments
- ✅ Clear understanding of past decisions
- ✅ Efficient context usage

**For Developers:**
- ✅ Project knowledge persists
- ✅ Onboarding documentation built-in
- ✅ Audit trail of investigations
- ✅ Easy to share with team

**For Teams:**
- ✅ Institutional knowledge captured
- ✅ New members can catch up quickly
- ✅ Consistent investigation methodology
- ✅ Historical decisions documented

## Comparison to Alternatives

### vs. Manual Note-Taking
- ❌ Easy to forget details
- ❌ Doesn't capture failed attempts
- ❌ Time-consuming to maintain
- ✅ This system: Automatic Layer 1

### vs. Claude's Global Transcripts Only
- ❌ Not organized by project
- ❌ Eventually cleaned up
- ❌ Not git-versioned
- ✅ This system: Project-specific archives

### vs. Full Vector DB from Start
- ❌ Over-engineering for small projects
- ❌ Infrastructure to maintain
- ❌ Sync complexity
- ✅ This system: Simple, scales gradually

### vs. Tools Like Notion/Obsidian
- ❌ External dependency
- ❌ Doesn't capture exact sessions
- ❌ Not code-adjacent
- ✅ This system: Git-versioned, code-adjacent

## Future Enhancements

Possible additions (not in template):

1. **Automatic checkpointing** - Archive session every 60 min
2. **MCP integration** - Tighter Claude Code integration
3. **Web UI** - Browse investigations visually
4. **Cross-project search** - Central knowledge base
5. **Export formats** - PDF, HTML generation
6. **Analytics** - Track investigation patterns

**Philosophy:** Start simple, add features when proven necessary.
