-- Migration: 002_indexes
-- Description: Performance indexes for commonly queried columns
-- Depends on: 001_initial_schema (all tables must exist)

-- ============================================================
-- INDEXES: profiles
-- ============================================================

-- Composite location index for geo-based player search
CREATE INDEX IF NOT EXISTS idx_profiles_location
  ON profiles(location_city, location_state, location_country);

-- Username lookup index (also used for uniqueness checks)
CREATE INDEX IF NOT EXISTS idx_profiles_username
  ON profiles(username);

-- Index for filtering public profiles efficiently
CREATE INDEX IF NOT EXISTS idx_profiles_is_public
  ON profiles(is_public);

-- ============================================================
-- INDEXES: game_collections
-- ============================================================

-- Primary lookup: all collection entries for a given user
CREATE INDEX IF NOT EXISTS idx_game_collections_user_id
  ON game_collections(user_id);

-- Look up users who own / have played a specific BGG game
CREATE INDEX IF NOT EXISTS idx_game_collections_bgg_id
  ON game_collections(bgg_game_id);

-- Filter collections by type (owned, wishlist, played, selling)
CREATE INDEX IF NOT EXISTS idx_game_collections_type
  ON game_collections(collection_type);

-- ============================================================
-- INDEXES: player_ratings
-- ============================================================

-- Fetch all ratings a user has received
CREATE INDEX IF NOT EXISTS idx_player_ratings_rated_id
  ON player_ratings(rated_id);

-- Fetch all ratings a user has given
CREATE INDEX IF NOT EXISTS idx_player_ratings_rater_id
  ON player_ratings(rater_id);

-- ============================================================
-- INDEXES: gaming_preferences
-- ============================================================

-- Primary lookup: preferences for a given user
CREATE INDEX IF NOT EXISTS idx_gaming_preferences_user_id
  ON gaming_preferences(user_id);

-- GIN index on preferred_genres array for contains-query filtering
-- e.g. WHERE preferred_genres @> ARRAY['Strategy']
CREATE INDEX IF NOT EXISTS idx_gaming_prefs_genres
  ON gaming_preferences USING GIN(preferred_genres);

-- GIN index on favorite_games array for contains-query filtering
-- e.g. WHERE favorite_games @> ARRAY['Catan']
CREATE INDEX IF NOT EXISTS idx_gaming_prefs_games
  ON gaming_preferences USING GIN(favorite_games);
