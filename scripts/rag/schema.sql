CREATE TABLE IF NOT EXISTS chunks (
  id TEXT PRIMARY KEY,
  source_id TEXT NOT NULL,
  source_file TEXT NOT NULL,
  page_number INTEGER,
  section_header TEXT,
  content TEXT NOT NULL,
  token_count INTEGER,
  vector_id INTEGER NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_chunks_source_id ON chunks (source_id);
CREATE INDEX IF NOT EXISTS idx_chunks_source_file ON chunks (source_file);

-- Educational content table for Wikidata/OpenStax resources
CREATE TABLE IF NOT EXISTS educational_content (
  id TEXT PRIMARY KEY,
  source TEXT NOT NULL,           -- 'wikidata' or 'openstax'
  content_type TEXT NOT NULL,     -- 'concept', 'chapter', 'exercise'
  subject TEXT NOT NULL,
  topic TEXT NOT NULL,
  content_text TEXT NOT NULL,
  reference TEXT,
  vector_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_edu_source ON educational_content (source);
CREATE INDEX IF NOT EXISTS idx_edu_subject_topic ON educational_content (subject, topic);
