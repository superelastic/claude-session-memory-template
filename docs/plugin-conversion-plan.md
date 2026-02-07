# Plugin Conversion Plan: claude-session-memory-template → Claude Code Plugin

## Background

Research conversation in claude.ai (Feb 2026) evaluated the current template repo against existing Claude Code memory solutions and determined the best path forward is converting the template into a proper Claude Code plugin while preserving its unique architectural advantages.

## Competitive Landscape

### Existing solutions evaluated:
- **obra/episodic-memory** — SQLite + vector search, MCP server, Haiku subagent for context management. Most mature. Plugin install via `/plugin marketplace add obra/episodic-memory`.
- **claude-mem (thedotmack)** — Auto-captures tool usage, AI compression via agent-sdk, 5 MCP tools, web viewer. Plugin install.
- **claude-code-vector-memory** — Lighter-weight, indexes session summaries, global search command.
- **meta_skill (Dicklesworthstone)** — Rust CLI, hybrid search, mines sessions into reusable skills. Most ambitious.
- **Claude native Auto-Memory** — Built-in `~/.claude/projects/<project>/memory/MEMORY.md` + topic files. 200-line limit on auto-load.
- **Claude native Session Memory** — Built-in summaries at `~/.claude/projects/<project-hash>/<session-id>/session-memory/summary.md`. Auto-injects at session start.

### What we have that they don't:
1. **Git-versioned storage** — Sessions travel with the repo. Everyone else uses machine-local DBs. This is the killer feature for professional/team contexts.
2. **Three-layer architecture** (raw logs → AI summaries → curated docs) — Human-in-the-loop curation via `docs/` layer.
3. **Pending queue pattern** — Defers summarization to SessionStart (reliable) instead of SessionEnd (may not complete).
4. **Local embeddings (BGE-large)** — No API calls needed for search. Fully offline.

### What they do better (gaps to close):
1. **MCP integration** — Claude can autonomously search past sessions. Our search requires manual `python scripts/semantic_filter.py` invocation.
2. **Auto context injection** — Relevant past context surfaces automatically without slash commands.
3. **One-command install** — `/plugin marketplace add` vs. cloning a template.

## Conversion Goals

### Must have:
- [ ] Restructure as a Claude Code plugin (installable via `/plugin marketplace add` or `/plugin add`)
- [ ] Write SKILL.md with proper frontmatter (name, description) teaching Claude when/how to use the memory system
- [ ] MCP server wrapper around `semantic_filter.py` so Claude can search sessions autonomously
- [ ] Plugin creates/manages `sessions/`, `.session_logs/`, `docs/` directories inside any host project
- [ ] Preserve git-versioned storage (sessions committed to project repo)
- [ ] Preserve three-layer architecture
- [ ] Preserve pending queue pattern (SessionEnd → pending, SessionStart → summarize)

### Should have:
- [ ] Slash commands migrated to skill-based invocation (`/startup`, `/session-end`)
- [ ] Hook definitions bundled in plugin settings
- [ ] CLAUDE.md content injected or merged into host project's CLAUDE.md
- [ ] Works on both WSL and native Linux/macOS

### Nice to have:
- [ ] Composability with episodic-memory (use their MCP search alongside our git-versioned storage)
- [ ] Skill for curating `docs/` layer (promoting session insights to permanent docs)
- [ ] Token-aware context injection (don't blow up the context window)

## Key Architectural Decision

**The template currently assumes it IS the project root.** The plugin must instead install INTO an existing project. This means:

- Scripts, hooks, and commands install into `<project>/.claude/` structure
- Storage directories (`sessions/`, `.session_logs/`, `docs/`) are created in the project root
- CLAUDE.md content is appended/merged, not replaced
- `scratchpad.md` becomes project-local

## Plugin Directory Structure (Target)

```
claude-session-memory/                  # Plugin root (GitHub repo)
├── plugin.json                         # Plugin manifest
├── skills/
│   └── session-memory/
│       ├── SKILL.md                    # Core skill: teaches Claude the memory system
│       ├── scripts/
│       │   ├── archive-session.sh      # SessionEnd archival
│       │   ├── convert-jsonl.py        # JSONL → markdown conversion
│       │   ├── semantic_filter.py      # Embedding-based search
│       │   └── requirements.txt
│       └── references/
│           ├── architecture.md         # How the 3-layer system works
│           └── workflows.md            # Session lifecycle docs
├── commands/
│   ├── startup.md                      # /session-memory:startup
│   ├── session-end.md                  # /session-memory:session-end
│   └── search.md                       # /session-memory:search <query>
├── hooks/                              # Hook definitions
│   └── session-hooks.json
└── mcp/                                # MCP server for autonomous search
    ├── server.py                       # MCP server wrapping semantic_filter
    └── package.json
```

## SKILL.md Draft Outline

```yaml
---
name: session-memory
description: >
  Persistent git-versioned session memory system. Manages three-layer memory:
  raw session logs, AI-generated summaries, and curated documentation.
  Use when starting a new session (to restore context), ending a session
  (to archive work), searching past sessions, or when the user references
  previous work, decisions, or investigations.
---
```

Body should cover:
- How to process pending sessions at startup
- How to archive sessions at end
- When and how to search past sessions via MCP tools
- How to promote insights to `docs/` layer
- Directory structure and file conventions

## Reference Material

Read these before starting implementation:

- Anthropic skill authoring docs: https://code.claude.com/docs/en/skills
- Skill best practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Plugin structure: https://code.claude.com/docs/en/skills (plugin section)
- Reference implementation: https://github.com/obra/episodic-memory (plugin + MCP pattern)
- Agent Skills spec: https://agentskills.io
- Anthropic official skills repo: https://github.com/anthropics/skills (see skill-creator/SKILL.md for meta-patterns)

## Migration Steps (Suggested Order)

1. **Read the skill/plugin docs** — Understand frontmatter, progressive disclosure, plugin.json format
2. **Scaffold the plugin directory structure** — Create the target layout above
3. **Write SKILL.md** — This is the most important file; get the description and instructions right
4. **Migrate scripts** — Move archive-session.sh, convert-jsonl.py, semantic_filter.py into skill's scripts/
5. **Migrate hooks** — Convert .claude/settings.json hook definitions to plugin format
6. **Migrate commands** — Convert slash commands to plugin-namespaced commands
7. **Build MCP server** — Wrap semantic_filter.py as an MCP server exposing search/view tools
8. **Test end-to-end** — Install plugin in a test project, verify full lifecycle
9. **Update CLAUDE.md injection** — Ensure host project gets memory system instructions
10. **Publish** — Push to GitHub, test `/plugin marketplace add`
