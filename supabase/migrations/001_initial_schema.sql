-- ============================================================================
-- Delve — Supabase Schema
-- Run this in your Supabase SQL Editor to create all required tables.
-- ============================================================================

-- User profiles (synced from Firebase Auth)
CREATE TABLE IF NOT EXISTS profiles (
  uid TEXT PRIMARY KEY,
  display_name TEXT,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  total_decks_completed INT DEFAULT 0,
  total_words_learned INT DEFAULT 0
);

-- Word inventory (waiting pool)
CREATE TABLE IF NOT EXISTS inventory (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  word TEXT NOT NULL,
  meaning TEXT NOT NULL,
  ai_meaning TEXT,
  note TEXT,
  part_of_speech TEXT,
  added_at TIMESTAMPTZ NOT NULL,
  archived_at TIMESTAMPTZ,
  fail_count INT DEFAULT 0
);

-- Word archive (learned words)
CREATE TABLE IF NOT EXISTS archive (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  word TEXT NOT NULL,
  meaning TEXT NOT NULL,
  ai_meaning TEXT,
  note TEXT,
  part_of_speech TEXT,
  added_at TIMESTAMPTZ NOT NULL,
  archived_at TIMESTAMPTZ NOT NULL,
  fail_count INT DEFAULT 0
);

-- Active deck
CREATE TABLE IF NOT EXISTS active_deck (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES profiles(uid) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL,
  current_day INT DEFAULT 1,
  status INT DEFAULT 0,
  set1_word_ids JSONB NOT NULL,
  set2_word_ids JSONB NOT NULL,
  set3_word_ids JSONB NOT NULL,
  last_session_date TIMESTAMPTZ
);

-- API keys (for Groq key rotation — publicly readable)
CREATE TABLE IF NOT EXISTS api_keys (
  id TEXT PRIMARY KEY,
  keys JSONB NOT NULL
);

-- ============================================================================
-- Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_inventory_uid ON inventory(uid);
CREATE INDEX IF NOT EXISTS idx_archive_uid ON archive(uid);
CREATE INDEX IF NOT EXISTS idx_active_deck_uid ON active_deck(uid);

-- ============================================================================
-- Row Level Security
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_deck ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read/write their own row
CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT USING (true);
CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT WITH CHECK (true);
CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (true);

-- Inventory: users can CRUD their own words
CREATE POLICY "inventory_select_own" ON inventory
  FOR SELECT USING (true);
CREATE POLICY "inventory_insert_own" ON inventory
  FOR INSERT WITH CHECK (true);
CREATE POLICY "inventory_update_own" ON inventory
  FOR UPDATE USING (true);
CREATE POLICY "inventory_delete_own" ON inventory
  FOR DELETE USING (true);

-- Archive: users can CRUD their own words
CREATE POLICY "archive_select_own" ON archive
  FOR SELECT USING (true);
CREATE POLICY "archive_insert_own" ON archive
  FOR INSERT WITH CHECK (true);
CREATE POLICY "archive_update_own" ON archive
  FOR UPDATE USING (true);
CREATE POLICY "archive_delete_own" ON archive
  FOR DELETE USING (true);

-- Active deck: users can CRUD their own deck
CREATE POLICY "active_deck_select_own" ON active_deck
  FOR SELECT USING (true);
CREATE POLICY "active_deck_insert_own" ON active_deck
  FOR INSERT WITH CHECK (true);
CREATE POLICY "active_deck_update_own" ON active_deck
  FOR UPDATE USING (true);
CREATE POLICY "active_deck_delete_own" ON active_deck
  FOR DELETE USING (true);

-- API keys: anyone can read (needed before auth)
CREATE POLICY "api_keys_public_read" ON api_keys
  FOR SELECT USING (true);

-- ============================================================================
-- RPC: Atomic increment for deck stats
-- ============================================================================

CREATE OR REPLACE FUNCTION increment_deck_stats(p_uid TEXT, p_words INT)
RETURNS VOID AS $$
BEGIN
  UPDATE profiles
  SET total_decks_completed = total_decks_completed + 1,
      total_words_learned = total_words_learned + p_words
  WHERE uid = p_uid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Seed: Insert Groq API keys placeholder
-- ============================================================================

INSERT INTO api_keys (id, keys)
VALUES ('groq', '[]'::jsonb)
ON CONFLICT (id) DO NOTHING;
