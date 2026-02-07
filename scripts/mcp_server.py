#!/usr/bin/env python3
"""
MCP server for session-memory plugin.

Exposes session search and document reading as MCP tools so Claude can
autonomously search past sessions without slash commands or bash invocations.

Tools:
  - search_sessions: keyword search across sessions and docs
  - semantic_search: vector search (requires sentence-transformers)
  - read_document: read a specific session/doc file
  - list_sessions: list available session summaries
"""

import os
import re
import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("session-memory")


def get_project_root() -> Path:
    """Resolve the host project directory."""
    env_dir = os.environ.get("CLAUDE_PROJECT_DIR")
    if env_dir:
        return Path(env_dir)
    return Path.cwd()


# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------


@mcp.tool()
def search_sessions(query: str, top_k: int = 10) -> str:
    """Search past sessions and documentation using keyword matching.

    Searches across sessions/, docs/, and .session_logs/ for files
    containing the query terms. Returns matching file paths with
    context snippets.

    Args:
        query: Search terms to look for
        top_k: Maximum number of results to return (default 10)
    """
    project = get_project_root()
    search_dirs = ["sessions", "docs", ".session_logs"]
    results = []

    # Split query into terms for matching
    terms = query.lower().split()

    for dir_name in search_dirs:
        dir_path = project / dir_name
        if not dir_path.exists():
            continue
        for md_file in dir_path.rglob("*.md"):
            if "pending" in str(md_file):
                continue
            try:
                content = md_file.read_text(encoding="utf-8")
                content_lower = content.lower()
                # Score: count of matching terms
                score = sum(1 for t in terms if t in content_lower)
                if score > 0:
                    # Extract first matching snippet
                    snippet = _extract_snippet(content, terms)
                    rel = md_file.relative_to(project)
                    results.append((score, str(rel), snippet))
            except Exception:
                continue

    results.sort(key=lambda x: -x[0])
    results = results[:top_k]

    if not results:
        return f"No results found for '{query}' in sessions/, docs/, or .session_logs/."

    lines = [f"Found {len(results)} result(s) for '{query}':\n"]
    for score, path, snippet in results:
        lines.append(f"**{path}** (matched {score}/{len(terms)} terms)")
        if snippet:
            lines.append(f"  > {snippet}")
        lines.append("")

    return "\n".join(lines)


@mcp.tool()
def semantic_search(query: str, top_k: int = 5) -> str:
    """Search past sessions using vector embeddings for semantic similarity.

    More powerful than keyword search for conceptual queries like
    "how did we handle authentication?" Requires sentence-transformers.

    Args:
        query: Natural language search query
        top_k: Number of results to return (default 5)
    """
    try:
        # Import from sibling module
        script_dir = Path(__file__).parent
        sys.path.insert(0, str(script_dir))
        from semantic_filter import search, find_project_root

        results = search(query, top_k=top_k, show_snippets=True)

        if not results:
            return f"No semantic results for '{query}'. Try keyword search instead."

        lines = [f"Semantic search results for '{query}':\n"]
        for r in results:
            lines.append(f"**{r['path']}** (relevance: {r['score']:.3f})")
            if r.get("snippet"):
                snippet = r["snippet"].replace("\n", " ")[:150]
                lines.append(f"  > {snippet}...")
            lines.append("")

        return "\n".join(lines)

    except ImportError as e:
        return (
            f"Semantic search unavailable: {e}\n"
            "Install with: pip install sentence-transformers torch\n"
            "Falling back: use the search_sessions tool for keyword search."
        )


@mcp.tool()
def read_document(path: str) -> str:
    """Read a session summary, investigation, or other document.

    Args:
        path: Relative path from project root (e.g. 'sessions/2025-01-15-api.md')
    """
    project = get_project_root()
    file_path = project / path

    # Security: ensure path stays within project
    try:
        file_path.resolve().relative_to(project.resolve())
    except ValueError:
        return f"Error: path '{path}' is outside the project directory."

    if not file_path.exists():
        return f"File not found: {path}"

    if not file_path.suffix == ".md":
        return f"Only markdown files can be read. Got: {path}"

    try:
        content = file_path.read_text(encoding="utf-8")
        if len(content) > 50000:
            content = content[:50000] + "\n\n... (truncated, file exceeds 50KB)"
        return content
    except Exception as e:
        return f"Error reading {path}: {e}"


@mcp.tool()
def list_sessions(include_pending: bool = False) -> str:
    """List available session summaries and their dates.

    Args:
        include_pending: Also list pending (unsummarized) sessions
    """
    project = get_project_root()
    lines = []

    # Session summaries
    sessions_dir = project / "sessions"
    if sessions_dir.exists():
        summaries = sorted(sessions_dir.glob("*.md"), reverse=True)
        if summaries:
            lines.append(f"## Session Summaries ({len(summaries)} files)\n")
            for f in summaries[:20]:
                size = f.stat().st_size
                lines.append(f"- {f.name} ({size // 1024}KB)")
        else:
            lines.append("## Session Summaries\n\n(none yet)")
    else:
        lines.append("## Session Summaries\n\n(sessions/ directory not found)")

    # Pending sessions
    if include_pending:
        pending_dir = project / ".session_logs" / "pending"
        if pending_dir.exists():
            pending = sorted(pending_dir.glob("*.md"), reverse=True)
            lines.append(f"\n## Pending ({len(pending)} files)\n")
            for f in pending:
                lines.append(f"- {f.name}")

    # Curated docs
    docs_dir = project / "docs"
    if docs_dir.exists():
        docs = list(docs_dir.rglob("*.md"))
        if docs:
            lines.append(f"\n## Curated Docs ({len(docs)} files)\n")
            for f in sorted(docs):
                rel = f.relative_to(project)
                lines.append(f"- {rel}")

    return "\n".join(lines) if lines else "No session memory files found."


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _extract_snippet(content: str, terms: list[str], context: int = 80) -> str:
    """Extract a short snippet around the first matching term."""
    content_lower = content.lower()
    for term in terms:
        idx = content_lower.find(term)
        if idx >= 0:
            start = max(0, idx - context)
            end = min(len(content), idx + len(term) + context)
            snippet = content[start:end].replace("\n", " ").strip()
            if start > 0:
                snippet = "..." + snippet
            if end < len(content):
                snippet = snippet + "..."
            return snippet
    return ""


if __name__ == "__main__":
    mcp.run()
