-- Migration: 002_rls_policies.sql
-- Description: Enables Row Level Security (RLS) on all tables and defines
-- granular access control policies for the Tabletop Gaming Networking App.
--
-- Policy design principles:
--   - Read access is generally public (anyone can browse profiles, games, etc.)
--   - Write access is restricted to the authenticated owner of the data
--   - auth.uid() is used to identify the currently authenticated user
--   - auth.role() is used to check authentication status for shared resources

-- ============================================================
-- TABLE: profiles
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Anyone (including anonymous users) can view profiles
CREATE POLICY profiles_select_public
  ON profiles
  FOR SELECT
  USING (true);

-- Users can only insert their own profile row (id must match auth.uid())
CREATE POLICY profiles_insert_own
  ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY profiles_update_own
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Users can only delete their own profile
CREATE POLICY profiles_delete_own
  ON profiles
  FOR DELETE
  USING (auth.uid() = id);

-- ============================================================
-- TABLE: games
-- ============================================================

ALTER TABLE games ENABLE ROW LEVEL SECURITY;

-- Anyone can view games (public game catalog)
CREATE POLICY games_select_all
  ON games
  FOR SELECT
  USING (true);

-- Any authenticated user can add games (supports BGG API sync from client)
CREATE POLICY games_insert_authenticated
  ON games
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Any authenticated user can update game data (supports BGG sync updates)
CREATE POLICY games_update_authenticated
  ON games
  FOR UPDATE
  USING (auth.role() = 'authenticated');

-- ============================================================
-- TABLE: game_genres
-- ============================================================

ALTER TABLE game_genres ENABLE ROW LEVEL SECURITY;

-- Anyone can view game genres (reference data)
CREATE POLICY game_genres_select_all
  ON game_genres
  FOR SELECT
  USING (true);

-- ============================================================
-- TABLE: game_genre_mappings
-- ============================================================

ALTER TABLE game_genre_mappings ENABLE ROW LEVEL SECURITY;

-- Anyone can view game-genre relationships
CREATE POLICY game_genre_mappings_select_all
  ON game_genre_mappings
  FOR SELECT
  USING (true);

-- ============================================================
-- TABLE: user_favorite_games
-- ============================================================

ALTER TABLE user_favorite_games ENABLE ROW LEVEL SECURITY;

-- Anyone can view user favorite games (public profile data)
CREATE POLICY user_favorite_games_select_public
  ON user_favorite_games
  FOR SELECT
  USING (true);

-- Users can only add favorites for themselves
CREATE POLICY user_favorite_games_insert_own
  ON user_favorite_games
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only remove their own favorites
CREATE POLICY user_favorite_games_delete_own
  ON user_favorite_games
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- TABLE: user_favorite_genres
-- ============================================================

ALTER TABLE user_favorite_genres ENABLE ROW LEVEL SECURITY;

-- Anyone can view user favorite genres (public profile data)
CREATE POLICY user_favorite_genres_select_public
  ON user_favorite_genres
  FOR SELECT
  USING (true);

-- Users can only add their own genre preferences
CREATE POLICY user_favorite_genres_insert_own
  ON user_favorite_genres
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only remove their own genre preferences
CREATE POLICY user_favorite_genres_delete_own
  ON user_favorite_genres
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- TABLE: user_availability
-- ============================================================

ALTER TABLE user_availability ENABLE ROW LEVEL SECURITY;

-- Anyone can view user availability (supports player discovery/matching)
CREATE POLICY user_availability_select_public
  ON user_availability
  FOR SELECT
  USING (true);

-- Users can only add their own availability slots
CREATE POLICY user_availability_insert_own
  ON user_availability
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only update their own availability slots
CREATE POLICY user_availability_update_own
  ON user_availability
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can only delete their own availability slots
CREATE POLICY user_availability_delete_own
  ON user_availability
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- TABLE: game_collections
-- ============================================================

ALTER TABLE game_collections ENABLE ROW LEVEL SECURITY;

-- Anyone can view game collections (supports browsing who owns what)
CREATE POLICY game_collections_select_public
  ON game_collections
  FOR SELECT
  USING (true);

-- Users can only add games to their own collection
CREATE POLICY game_collections_insert_own
  ON game_collections
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only update their own collection entries
CREATE POLICY game_collections_update_own
  ON game_collections
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can only delete their own collection entries
CREATE POLICY game_collections_delete_own
  ON game_collections
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- TABLE: user_ratings
-- ============================================================

ALTER TABLE user_ratings ENABLE ROW LEVEL SECURITY;

-- Anyone can view ratings (public reputation system)
CREATE POLICY user_ratings_select_public
  ON user_ratings
  FOR SELECT
  USING (true);

-- Users can only submit ratings as themselves (rater_id must be auth.uid())
CREATE POLICY user_ratings_insert_own
  ON user_ratings
  FOR INSERT
  WITH CHECK (auth.uid() = rater_id);

-- Users can only edit ratings they submitted
CREATE POLICY user_ratings_update_own
  ON user_ratings
  FOR UPDATE
  USING (auth.uid() = rater_id);

-- Users can only delete ratings they submitted
CREATE POLICY user_ratings_delete_own
  ON user_ratings
  FOR DELETE
  USING (auth.uid() = rater_id);
