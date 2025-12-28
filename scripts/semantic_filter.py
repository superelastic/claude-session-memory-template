#!/usr/bin/env python3
"""
semantic_filter.py - Semantic search over investigation documents

Usage:
    python semantic_filter.py "search query" [file1.md file2.md ...]
    python semantic_filter.py --top-k=10 "search query" docs/investigations/*.md
"""

import sys
import numpy as np
from pathlib import Path

# Global model (lazy-loaded)
MODEL = None

def get_model():
    """Lazy-load the embedding model."""
    global MODEL
    if MODEL is None:
        try:
            from sentence_transformers import SentenceTransformer
            print("Loading embedding model (first run downloads ~400MB)...", file=sys.stderr)
            MODEL = SentenceTransformer('BAAI/bge-large-en-v1.5')
            print("Model loaded successfully", file=sys.stderr)
        except ImportError:
            print("Error: sentence-transformers not installed", file=sys.stderr)
            print("Install with: pip install sentence-transformers torch", file=sys.stderr)
            sys.exit(1)
    return MODEL

def semantic_filter(file_paths, query, top_k=5):
    """
    Filter file paths by semantic similarity to query.
    
    Args:
        file_paths: List of file paths to rank
        query: Search query to match against
        top_k: Number of top results to return
        
    Returns:
        List of (path, score) tuples for top-k most relevant files
    """
    model = get_model()
    
    # Read all files
    documents = []
    valid_paths = []
    
    print(f"Reading {len(file_paths)} documents...", file=sys.stderr)
    
    for path in file_paths:
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
                # Skip empty or very short files
                if len(content) < 50:
                    continue
                documents.append(content)
                valid_paths.append(path)
        except Exception as e:
            print(f"Warning: Could not read {path}: {e}", file=sys.stderr)
    
    if not documents:
        print("Error: No readable documents found", file=sys.stderr)
        return []
    
    print(f"Embedding {len(documents)} documents...", file=sys.stderr)
    
    # Generate embeddings
    doc_embeddings = model.encode(documents, show_progress_bar=False)
    query_embedding = model.encode([query])[0]
    
    # Normalize embeddings for cosine similarity
    doc_embeddings = doc_embeddings / np.linalg.norm(doc_embeddings, axis=1, keepdims=True)
    query_embedding = query_embedding / np.linalg.norm(query_embedding)
    
    # Compute cosine similarity (dot product of normalized vectors)
    similarities = np.dot(doc_embeddings, query_embedding)
    
    # Get top-k indices
    top_k = min(top_k, len(valid_paths))
    top_indices = np.argsort(similarities)[-top_k:][::-1]
    
    # Return ranked results
    results = []
    for i in top_indices:
        results.append((valid_paths[i], float(similarities[i])))
        print(f"  {similarities[i]:.3f} - {valid_paths[i]}", file=sys.stderr)
    
    return results

def main():
    # Parse arguments
    args = sys.argv[1:]
    
    if len(args) < 2:
        print("Usage: semantic_filter.py [--top-k=N] <query> <file1> <file2> ...", file=sys.stderr)
        print("Example: semantic_filter.py 'API authentication' docs/investigations/*.md", file=sys.stderr)
        sys.exit(1)
    
    top_k = 5
    query = None
    file_paths = []
    
    for arg in args:
        if arg.startswith('--top-k='):
            try:
                top_k = int(arg.split('=')[1])
            except ValueError:
                print(f"Error: Invalid --top-k value: {arg}", file=sys.stderr)
                sys.exit(1)
        elif query is None:
            query = arg
        else:
            # Expand glob patterns if needed
            path = Path(arg)
            if path.exists() and path.is_file():
                file_paths.append(str(path))
            else:
                # Try as glob pattern
                parent = path.parent if path.parent.exists() else Path('.')
                pattern = path.name
                matches = list(parent.glob(pattern))
                file_paths.extend([str(m) for m in matches if m.is_file()])
    
    if not query:
        print("Error: No query provided", file=sys.stderr)
        sys.exit(1)
    
    if not file_paths:
        print("Error: No files to search", file=sys.stderr)
        sys.exit(1)
    
    # Remove duplicates
    file_paths = list(set(file_paths))
    
    # Run semantic filter
    results = semantic_filter(file_paths, query, top_k)
    
    if not results:
        print("No results found", file=sys.stderr)
        sys.exit(1)
    
    # Output just the paths (one per line) for easy piping
    for path, score in results:
        print(path)

if __name__ == '__main__':
    main()
