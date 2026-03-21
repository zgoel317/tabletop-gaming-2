-- Migration: 001_initial_schema
-- Description: Creates core tables for the Tabletop Gaming Networking App
-- Tables: profiles, gaming_preferences, game_collections, player_ratings
-- Includes RLS policies and trigger functions

-- ============================================================
-- TRIGGER FUNCTION: handle_updated_at
-- Automatically updates the updated_at timestamp on row update
-- ============================================================
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TABLE: profiles
-- Extends auth.users with public-facing profile information
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id                UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username          TEXT UNIQUE NOT NULL,
  full_name         TEXT,
  bio               TEXT,
  avatar_url        TEXT,
  location_city     TEXT,
  location_state    TEXT,
  location_country  TEXT DEFAULT 'US',
  location_lat      DECIMAL(9,6),
  location_lng      DECIMAL(9,6),
  is_public         BOOLEAN DEFAULT true,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- TABLE: gaming_preferences
-- Stores per-user gaming preferences and availability info
-- ============================================================
CREATE TABLE IF NOT EXISTS gaming_preferences (
  id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                         UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  experience_level                TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced', 'expert')) DEFAULT 'beginner',
  preferred_genres                TEXT[] DEFAULT '{}',
  favorite_games                  TEXT[] DEFAULT '{}',
  preferred_player_count_min      INT DEFAULT 2,
  preferred_player_count_max      INT DEFAULT 6,
  preferred_session_length_hours  DECIMAL(4,1),
  availability_notes              TEXT,
  willing_to_teach                BOOLEAN DEFAULT false,
  willing_to_travel_miles         INT DEFAULT 10,
  created_at                      TIMESTAMPTZ DEFAULT now(),
  updated_at                      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- TABLE: game_collections
-- Tracks games a user owns, wants, has played, or is selling
-- ============================================================
CREATE TABLE IF NOT EXISTS game_collections (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  bgg_game_id      INT,
  game_name        TEXT NOT NULL,
  game_image_url   TEXT,
  collection_type  TEXT CHECK (collection_type IN ('owned', 'wishlist', 'played', 'selling')) NOT NULL,
  user_rating      INT CHECK (user_rating BETWEEN 1 AND 10),
  notes            TEXT,
  created_at       TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, bgg_game_id, collection_type)
);

-- ============================================================
-- TABLE: player_ratings
-- Stores ratings and reviews users give each other
-- ============================================================
CREATE TABLE IF NOT EXISTS player_ratings (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rater_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rated_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating       INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text  TEXT,
  session_id   UUID,  -- nullable; will reference future events table
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE(rater_id, rated_id),
  CHECK (rater_id != rated_id)
);

-- ============================================================
-- UPDATED_AT TRIGGERS
-- Automatically maintain the updated_at column on mutations
-- ============================================================
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER gaming_preferences_updated_at
  BEFORE UPDATE ON gaming_preferences
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER player_ratings_updated_at
  BEFORE UPDATE ON player_ratings
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- ============================================================
-- TRIGGER FUNCTION: handle_new_user
-- Auto-creates a profile and default gaming_preferences row
-- when a new user signs up via Supabase Auth.
--
-- NOTE FOR DEVELOPERS: Because this trigger runs on auth.users
-- INSERT, the frontend should NOT manually insert into profiles
-- after signup. Instead, call updateProfile() to fill optional
-- fields after the user completes onboarding.
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  base_username TEXT;
  final_username TEXT;
  counter        INT := 0;
BEGIN
  -- Derive a base username from the email address (part before @)
  base_username := LOWER(SPLIT_PART(NEW.email, '@', 1));
  -- Remove any characters that are not alphanumeric or underscores
  base_username := REGEXP_REPLACE(base_username, '[^a-z0-9_]', '_', 'g');
  -- Truncate to 30 characters to leave room for numeric suffix
  base_username := LEFT(base_username, 30);
  final_username := base_username;

  -- Ensure uniqueness by appending an incrementing counter if needed
  WHILE EXISTS (SELECT 1 FROM profiles WHERE username = final_username) LOOP
    counter := counter + 1;
    final_username := base_username || '_' || counter::TEXT;
  END LOOP;

  -- Insert the base profile record
  INSERT INTO profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    final_username,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );

  -- Insert default gaming preferences for the new user
  INSERT INTO gaming_preferences (user_id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach the new-user trigger to auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- ROW LEVEL SECURITY
-- Enable RLS on all tables before defining policies
-- ============================================================
ALTER TABLE profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE gaming_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_ratings   ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- RLS POLICIES: profiles
-- ------------------------------------------------------------

-- Anyone can view public profiles; users can always view their own
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (is_public = true OR auth.uid() = id);

-- Users can only insert their own profile row
CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can only update their own profile row
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ------------------------------------------------------------
-- RLS POLICIES: gaming_preferences
-- ------------------------------------------------------------

-- Users can view their own preferences; others can view if profile is public
CREATE POLICY "Gaming preferences viewable based on profile visibility"
  ON gaming_preferences FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = gaming_preferences.user_id
        AND profiles.is_public = true
    )
  );

-- Users can only insert their own preferences
CREATE POLICY "Users can insert own gaming preferences"
  ON gaming_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only update their own preferences
CREATE POLICY "Users can update own gaming preferences"
  ON gaming_preferences FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ------------------------------------------------------------
-- RLS POLICIES: game_collections
-- ------------------------------------------------------------

-- Users can view their own collection; others can view if profile is public
CREATE POLICY "Game collections viewable based on profile visibility"
  ON game_collections FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = game_collections.user_id
        AND profiles.is_public = true
    )
  );

-- Users can only insert into their own collection
CREATE POLICY "Users can insert into own collection"
  ON game_collections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only update their own collection entries
CREATE POLICY "Users can update own collection"
  ON game_collections FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own collection entries
CREATE POLICY "Users can delete from own collection"
  ON game_collections FOR DELETE
  USING (auth.uid() = user_id);

-- ------------------------------------------------------------
-- RLS POLICIES: player_ratings
-- ------------------------------------------------------------

-- All authenticated users can view ratings (transparency in the community)
CREATE POLICY "Authenticated users can view ratings"
  ON player_ratings FOR SELECT
  USING (auth.role() = 'authenticated');

-- Users can only insert ratings where they are the rater
CREATE POLICY "Users can insert ratings they give"
  ON player_ratings FOR INSERT
  WITH CHECK (auth.uid() = rater_id);

-- Users can only update ratings they originally gave
CREATE POLICY "Users can update ratings they gave"
  ON player_ratings FOR UPDATE
  USING (auth.uid() = rater_id)
  WITH CHECK (auth.uid() = rater_id);

-- Users can only delete ratings they originally gave
CREATE POLICY "Users can delete ratings they gave"
  ON player_ratings FOR DELETE
  USING (auth.uid() = rater_id);
