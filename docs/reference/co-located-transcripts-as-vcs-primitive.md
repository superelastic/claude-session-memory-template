# Co-located LLM Transcripts as a VCS Primitive

**Source:** Twitter thread by Jarred Sumner (@jarredsumner), Feb 12, 2026
**Context:** Discussion on git worktrees, LLM workflows, and what replaces git

## Core Argument

Traditional version control captures *what* changed (diffs) and *why* in a terse commit message. When code is written with LLMs, the full session transcript — the back-and-forth reasoning, decisions, dead ends, context — is far richer than any commit message. Sumner proposes that transcripts should be **co-located with code** as a first-class artifact, not discarded after the session ends.

He argues this is the feature of a version control system that *replaces* git, not something to bolt on top of it.

## Zoom Levels Metaphor

Sumner describes commits and tags as "zoom levels for context":

- **Full transcript** = maximum context (complete LLM conversation)
- **Commit** = medium zoom (snapshot summary of a change)
- **Tag** = wide zoom (milestone label)

A next-gen VCS should natively understand these layers.

## Key Positions from the Thread

- **Sumner:** "LLM session transcripts provide far richer context about changes than a commit message. Put them with the code." He doesn't love git worktrees for parallel LLM work and thinks PRs/CI as a step independent from local dev doesn't make sense anymore.
- **Sumner:** "I don't think this should be built on top of git. It should be its own thing. Probably needs to have an adapter for git or you get 0 users."
- **@dejavucoder:** Reading/reviewing LLM-assisted code is painful due to volume. Co-located transcripts could help reviewers understand *how* code was produced.
- **@doodlestein:** Advocates for agent coordination systems (file reservations, message passing) over worktrees for parallel agent work.

## Relevance to session-memory Plugin

This plugin implements exactly what Sumner describes, using git as the transport layer:

| Sumner's Vision | session-memory Implementation |
|---|---|
| Co-located LLM transcripts | `.session_logs/*.jsonl` — raw transcripts in the repo |
| Commit-level summaries | `sessions/*.md` — AI-generated session summaries |
| Richer context than commit messages | Summaries capture reasoning, decisions, dead ends |
| Zoom levels for context | Three-layer architecture: raw logs, summaries, curated docs |
| Part of the VCS | Git-versioned, travels with the repo |

The plugin's three-layer memory maps directly to the zoom levels:

1. **Raw JSONL** = full transcript (max detail)
2. **Session summaries** = commit-message level (condensed reasoning)
3. **Curated docs** = tag level (distilled decisions and patterns)

## Divergences and Open Questions

**Git as substrate vs. new primitive:** Sumner wants a new system; this plugin takes the pragmatic adapter approach he acknowledges is necessary for adoption. Git is the transport; the plugin adds the semantic layer.

**PR integration:** If transcripts travel with code, reviewers could read the *session* that produced a PR, not just the diff. The plugin already stores this context — surfacing it in PR descriptions is a natural extension.

**Multi-agent coordination:** The thread touches on parallel agent work (worktrees, file reservations). That's orthogonal to this plugin's focus on *memory persistence* rather than *concurrent orchestration*.

**Structured vs. flat storage:** The main design question is whether transcript storage should stay as flat files in git or move to something more structured — searchable, linkable, diffable at the semantic level. The MCP server with semantic search is already a step toward a richer query layer on top of flat files.
