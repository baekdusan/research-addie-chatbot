# PDF RAG Ingestion (Local Skeleton)

This folder contains a local, offline skeleton for building a PDF RAG cache
backed by FAISS (vectors) and SQLite (metadata). It is intentionally minimal
and designed to be swapped to a managed vector DB later.

## Goals
- Extract structured text from PDFs (layout-aware)
- Normalize and chunk text
- Generate embeddings
- Store metadata in SQLite
- Store vectors in FAISS

## Files
- `ingest_pdf.py`: End-to-end ingestion CLI (skeleton)
- `schema.sql`: SQLite schema for chunk metadata

## Default Artifacts
- `data/rag/resource_cache.sqlite`
- `data/rag/resource_index.faiss`

## Recommended Preprocessing Steps
1. Layout-aware PDF parsing (avoid column bleed)
2. Cleanup (headers/footers/page numbers)
3. Section-aware chunking
4. Embedding
5. Persist chunks + vectors

## Running (after implementation)
```bash
python "scripts/rag/ingest_pdf.py" \
  --input "instructionalDesignSource.pdf" \
  --sqlite "data/rag/resource_cache.sqlite" \
  --faiss "data/rag/resource_index.faiss"
```

## Notes
- This is a local pipeline to move fast now; it can be migrated to Firestore
  or another managed vector DB later.
- Keep `source_id` stable across re-ingestions to allow cache reuse.
