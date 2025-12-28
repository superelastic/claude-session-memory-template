# Investigation Index

## About

This directory contains structured documentation of investigations, experiments, and technical decisions made during development.

Each investigation follows the template in `INVESTIGATION_TEMPLATE.md` and includes:
- Hypothesis that was tested
- Experiments performed with results
- Findings and conclusions
- Implementation decisions made
- Traceable links to source session logs

## Quick Find

### By Status

**In Progress:**
(None yet - add investigations as they're created)

**Recently Concluded:**
(None yet)

### By Topic

#### Setup & Configuration
(Investigations will be added here)

#### API Integration
(Investigations will be added here)

#### Performance & Optimization
(Investigations will be added here)

#### Bug Fixes & Debugging
(Investigations will be added here)

## All Investigations (Chronological)

### 2025-12

(Investigations will be listed here as they're created)

### 2025-11

(Earlier investigations)

---

## Searching Investigations

### Keyword Search (Fast)

```bash
# Find by keyword
rg -l "authentication" docs/investigations/

# Find by tag
rg -l "tags:.*api" docs/investigations/

# Find concluded investigations
rg -l "status: concluded" docs/investigations/
```

### Semantic Search (Comprehensive)

```bash
# When you have many investigations or need conceptual matching
python scripts/semantic_filter.py "detailed search query here"
```

## Adding New Investigations

When creating a new investigation:

1. **Use the template:** `cp INVESTIGATION_TEMPLATE.md your_topic.md`
2. **Fill in all sections** with your findings
3. **Add to this INDEX** in appropriate categories
4. **Commit to git** with investigation doc and session logs

## Investigation Quality Guidelines

Good investigations:
- ✓ Have clear hypothesis and conclusion
- ✓ Document what was tried (including failures)
- ✓ Link to source session logs
- ✓ Include implementation decisions
- ✓ Use descriptive filenames and tags

Avoid:
- ✗ Incomplete experiments
- ✗ Missing conclusions
- ✗ No traceability to sessions
- ✗ Vague descriptions
