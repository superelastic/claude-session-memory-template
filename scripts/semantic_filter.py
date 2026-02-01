#!/usr/bin/env python3
"""
semantic_filter.py - Vector-based semantic search across project documents

Features:
- Auto-discovers search directories (sessions/, docs/, .session_logs/)
- Document chunking with overlap for better retrieval
- Deduplication by document
- Explicit file paths as fallback

Usage:
    python semantic_filter.py "search query"
    python semantic_filter.py "search query" --top-k 10
    python semantic_filter.py "search query" --snippets
    python semantic_filter.py "search query" file1.md file2.md  # explicit files
"""

import argparse
import sys
from pathlib import Path

# Global model (lazy-loaded)
MODEL = None


def get_model():
    """Lazy-load the embedding model."""
    global MODEL
    if MODEL is None:
        try:
            from sentence_transformers import SentenceTransformer
            print("Loading embedding model...", file=sys.stderr)
            MODEL = SentenceTransformer("BAAI/bge-large-en-v1.5")
        except ImportError:
            print("Error: sentence-transformers not installed", file=sys.stderr)
            print("Install with: pip install sentence-transformers torch", file=sys.stderr)
            sys.exit(1)
    return MODEL


def find_project_root():
    """Find project root by looking for CLAUDE.md or .git."""
    current = Path(__file__).resolve().parent
    while current != current.parent:
        if (current / "CLAUDE.md").exists() or (current / ".git").exists():
            return current
        current = current.parent
    # Fallback to script's parent directory
    return Path(__file__).resolve().parent.parent


def gather_documents(project_root, explicit_paths=None):
    """Gather markdown documents from search directories or explicit paths."""
    documents = []

    if explicit_paths:
        # Use explicit file paths
        for path_str in explicit_paths:
            path = Path(path_str)
            if path.exists() and path.is_file():
                try:
                    content = path.read_text(encoding="utf-8")
                    if len(content) >= 50:
                        documents.append({
                            "path": path,
                            "relative_path": path.name,
                            "content": content
                        })
                except Exception as e:
                    print(f"Warning: Could not read {path}: {e}", file=sys.stderr)
            else:
                # Try as glob pattern
                parent = path.parent if path.parent.exists() else Path(".")
                for match in parent.glob(path.name):
                    if match.is_file():
                        try:
                            content = match.read_text(encoding="utf-8")
                            if len(content) >= 50:
                                documents.append({
                                    "path": match,
                                    "relative_path": match.name,
                                    "content": content
                                })
                        except Exception:
                            pass
    else:
        # Auto-discover from standard directories
        search_dirs = ["sessions", "docs", ".session_logs"]

        for dir_name in search_dirs:
            dir_path = project_root / dir_name
            if not dir_path.exists():
                continue

            for md_file in dir_path.rglob("*.md"):
                # Skip pending files (not yet summarized)
                if "pending" in str(md_file):
                    continue
                try:
                    content = md_file.read_text(encoding="utf-8")
                    if len(content) < 50:
                        continue
                    documents.append({
                        "path": md_file,
                        "relative_path": md_file.relative_to(project_root),
                        "content": content
                    })
                except Exception as e:
                    print(f"Warning: Could not read {md_file}: {e}", file=sys.stderr)

    return documents


def chunk_document(content, chunk_size=1000, overlap=200):
    """Split document into overlapping chunks for better retrieval."""
    chunks = []
    start = 0
    while start < len(content):
        end = start + chunk_size
        chunk = content[start:end]
        if chunk.strip():
            chunks.append(chunk)
        start = end - overlap
        if start < 0:
            break
    return chunks if chunks else [content]


def search(query, top_k=5, show_snippets=False, explicit_paths=None):
    """Perform semantic search and return ranked results."""
    import numpy as np

    project_root = find_project_root()
    documents = gather_documents(project_root, explicit_paths)

    if not documents:
        print("No documents found to search.", file=sys.stderr)
        return []

    print(f"Searching {len(documents)} documents...", file=sys.stderr)

    # Load model
    model = get_model()

    # Build chunks with document references
    all_chunks = []
    chunk_to_doc = []
    for doc_idx, doc in enumerate(documents):
        chunks = chunk_document(doc["content"])
        for chunk in chunks:
            all_chunks.append(chunk)
            chunk_to_doc.append(doc_idx)

    print(f"Indexing {len(all_chunks)} chunks...", file=sys.stderr)

    # Encode query and chunks
    query_embedding = model.encode([query], normalize_embeddings=True)[0]
    chunk_embeddings = model.encode(all_chunks, normalize_embeddings=True, show_progress_bar=False)

    # Calculate similarities
    similarities = np.dot(chunk_embeddings, query_embedding)

    # Get top chunks
    top_indices = np.argsort(similarities)[::-1]

    # Deduplicate by document
    seen_docs = set()
    results = []

    for idx in top_indices:
        doc_idx = chunk_to_doc[idx]
        if doc_idx in seen_docs:
            continue
        seen_docs.add(doc_idx)

        doc = documents[doc_idx]
        score = float(similarities[idx])
        results.append({
            "path": doc["relative_path"],
            "score": score,
            "snippet": all_chunks[idx][:200] if show_snippets else None
        })

        if len(results) >= top_k:
            break

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Semantic search across project documents"
    )
    parser.add_argument("query", help="Search query")
    parser.add_argument("files", nargs="*", help="Optional: specific files to search")
    parser.add_argument("--top-k", type=int, default=5, help="Number of results (default: 5)")
    parser.add_argument("--snippets", action="store_true", help="Show matching snippets")

    args = parser.parse_args()

    explicit_paths = args.files if args.files else None
    results = search(args.query, top_k=args.top_k, show_snippets=args.snippets, explicit_paths=explicit_paths)

    if not results:
        print("No results found.", file=sys.stderr)
        sys.exit(1)

    # Print results
    print("\nResults:", file=sys.stderr)
    print("-" * 40, file=sys.stderr)

    for i, result in enumerate(results, 1):
        print(f"{i}. {result['path']} (score: {result['score']:.3f})", file=sys.stderr)
        if result.get("snippet"):
            snippet = result["snippet"].replace("\n", " ")[:100]
            print(f"   {snippet}...", file=sys.stderr)

    print("-" * 40, file=sys.stderr)

    # Print just paths to stdout (for piping)
    for result in results:
        print(result["path"])


if __name__ == "__main__":
    main()
