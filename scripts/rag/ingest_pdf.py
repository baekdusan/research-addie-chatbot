import argparse
import datetime
import os
import uuid


def extract_text(input_path):
    """Extract text from PDF with layout awareness using PyMuPDF."""
    import fitz  # PyMuPDF

    doc = fitz.open(input_path)
    pages = []

    for page_num, page in enumerate(doc, start=1):
        # Extract text blocks with position data
        # Format: (x0, y0, x1, y1, text, block_no, block_type)
        blocks = page.get_text("blocks")

        # Filter out non-text blocks (type 0 = text) and sort by vertical position
        text_blocks = [
            block[4] for block in blocks
            if block[6] == 0  # 0 = text block
        ]

        page_text = "\n".join(text_blocks)
        pages.append({
            "page_number": page_num,
            "text": page_text
        })

    doc.close()
    return pages


def normalize_pages(pages):
    """Remove headers, footers, page numbers and excessive whitespace."""
    import re

    normalized = []

    for page in pages:
        text = page["text"]

        # Remove common headers/footers patterns
        text = re.sub(r'Page \d+ of \d+', '', text, flags=re.IGNORECASE)
        text = re.sub(r'^\d+\s*$', '', text, flags=re.MULTILINE)  # Standalone page numbers

        # Remove excessive whitespace
        text = re.sub(r'\n{3,}', '\n\n', text)
        text = text.strip()

        if text:  # Only keep non-empty pages
            normalized.append({
                "page_number": page["page_number"],
                "text": text
            })

    return normalized


def chunk_pages(pages, chunk_tokens, chunk_overlap):
    """Section-aware chunking with token-based splitting."""
    import tiktoken

    encoder = tiktoken.get_encoding("cl100k_base")  # GPT-4 tokenizer
    chunks = []

    for page in pages:
        text = page["text"]
        page_num = page["page_number"]

        # Detect section headers (lines ending with ":" or starting with "##")
        lines = text.split('\n')
        current_section = None
        current_text = []

        for line in lines:
            # Simple heuristic for section headers
            if line.strip().endswith(':') or line.strip().startswith('##'):
                current_section = line.strip()
            current_text.append(line)

        # Token-based chunking
        full_text = '\n'.join(current_text)
        tokens = encoder.encode(full_text)

        for i in range(0, len(tokens), chunk_tokens - chunk_overlap):
            chunk_tokens_list = tokens[i:i + chunk_tokens]
            chunk_text = encoder.decode(chunk_tokens_list)

            chunks.append({
                "content": chunk_text,
                "page_number": page_num,
                "section_header": current_section,
                "token_count": len(chunk_tokens_list)
            })

    return chunks


def embed_chunks(chunks, embedding_model):
    """Generate embeddings using Vertex AI text-embedding-004."""
    from google.cloud import aiplatform
    from vertexai.language_models import TextEmbeddingModel
    import numpy as np

    # Initialize Vertex AI
    aiplatform.init(project="research-addie-chatbot", location="us-central1")

    # Load embedding model
    model = TextEmbeddingModel.from_pretrained(embedding_model)

    # Batch embedding for efficiency (max 5 per request for text-embedding-004)
    batch_size = 5
    embeddings = []

    for i in range(0, len(chunks), batch_size):
        batch = chunks[i:i + batch_size]
        texts = [chunk["content"] for chunk in batch]

        # Call Vertex AI Embedding API
        batch_embeddings = model.get_embeddings(texts)

        for emb in batch_embeddings:
            embeddings.append(np.array(emb.values))

    return np.array(embeddings, dtype='float32')


def persist_sqlite(chunks, sqlite_path, source_id):
    """Store chunk metadata in SQLite database."""
    import sqlite3
    import os

    conn = sqlite3.connect(sqlite_path)
    cursor = conn.cursor()

    # Create table from schema.sql
    schema_path = os.path.join(os.path.dirname(__file__), 'schema.sql')
    with open(schema_path, 'r') as f:
        schema = f.read()
        cursor.executescript(schema)

    # Insert chunks
    for chunk in chunks:
        cursor.execute('''
            INSERT INTO chunks (id, source_id, source_file, page_number,
                                section_header, content, token_count, vector_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            chunk['id'],
            chunk['source_id'],
            chunk['source_file'],
            chunk['page_number'],
            chunk['section_header'],
            chunk['content'],
            chunk['token_count'],
            chunk['vector_id'],
            chunk['created_at']
        ))

    conn.commit()
    conn.close()


def persist_faiss(embeddings, faiss_path):
    """Store embeddings in FAISS index."""
    import faiss

    dimension = embeddings.shape[1]  # 768 for text-embedding-004

    # Use IndexFlatIP for inner product (cosine similarity with normalized vectors)
    index = faiss.IndexFlatIP(dimension)

    # Normalize embeddings for cosine similarity
    faiss.normalize_L2(embeddings)

    # Add vectors to index
    index.add(embeddings)

    # Save to disk
    faiss.write_index(index, faiss_path)

    print(f"FAISS index saved with {index.ntotal} vectors")


def build_chunks_payload(chunks, source_id, source_file):
    created_at = datetime.datetime.utcnow().isoformat()
    payload = []
    for index, chunk in enumerate(chunks):
        payload.append(
            {
                "id": str(uuid.uuid4()),
                "source_id": source_id,
                "source_file": source_file,
                "page_number": chunk.get("page_number"),
                "section_header": chunk.get("section_header"),
                "content": chunk["content"],
                "token_count": chunk.get("token_count"),
                "vector_id": index,
                "created_at": created_at,
            }
        )
    return payload


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--sqlite", required=True)
    parser.add_argument("--faiss", required=True)
    parser.add_argument("--source-id", default="instructional_design_pdf")
    parser.add_argument("--chunk-tokens", type=int, default=512)
    parser.add_argument("--chunk-overlap", type=int, default=64)
    parser.add_argument("--embedding-model", default="gemini-embedding")
    return parser.parse_args()


def ensure_output_paths(sqlite_path, faiss_path):
    sqlite_dir = os.path.dirname(sqlite_path)
    faiss_dir = os.path.dirname(faiss_path)
    if sqlite_dir:
        os.makedirs(sqlite_dir, exist_ok=True)
    if faiss_dir:
        os.makedirs(faiss_dir, exist_ok=True)


def main():
    args = parse_args()
    ensure_output_paths(args.sqlite, args.faiss)

    pages = extract_text(args.input)
    normalized = normalize_pages(pages)
    chunks = chunk_pages(normalized, args.chunk_tokens, args.chunk_overlap)
    embeddings = embed_chunks(chunks, args.embedding_model)
    payload = build_chunks_payload(chunks, args.source_id, args.input)

    persist_sqlite(payload, args.sqlite, args.source_id)
    persist_faiss(embeddings, args.faiss)

    print(
        "Ingestion completed. chunks=%s sqlite=%s faiss=%s"
        % (len(payload), args.sqlite, args.faiss)
    )


if __name__ == "__main__":
    main()
