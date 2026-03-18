-- ============================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE gaming_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_game_collection ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ratings ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Check if the requesting user owns the profile
CREATE OR REPLACE FUNCTION auth_owns_profile(profile_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN auth.uid() = profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if a profile is public
CREATE OR REPLACE FUNCTION profile_is_public(profile_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = profile_id AND is_public = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================
-- PROFILES POLICIES
-- ============================================================

-- Anyone can view public profiles
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (is_public = true OR auth.uid() = id);

-- Users can only insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can only delete their own profile
CREATE POLICY "Users can delete their own profile"
  ON profiles FOR DELETE
  USING (auth.uid() = id);

-- ============================================================
-- GAMING PREFERENCES POLICIES
-- ============================================================

-- View: public if profile is public, or own preferences
CREATE POLICY "Gaming preferences viewable if profile is public or own"
  ON gaming_preferences FOR SELECT
  USING (
    profile_id = auth.uid() OR
    profile_is_public(profile_id)
  );

-- Insert: only own preferences
CREATE POLICY "Users can insert their own gaming preferences"
  ON gaming_preferences FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- Update: only own preferences
CREATE POLICY "Users can update their own gaming preferences"
  ON gaming_preferences FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- Delete: only own preferences
CREATE POLICY "Users can delete their own gaming preferences"
  ON gaming_preferences FOR DELETE
  USING (auth.uid() = profile_id);

-- ============================================================
-- GAMES POLICIES
-- Games are a shared reference table - read by all, write by system
-- ============================================================

-- Anyone can view games (public reference data)
CREATE POLICY "Games are viewable by everyone"
  ON games FOR SELECT
  USING (true);

-- Authenticated users can suggest new games
CREATE POLICY "Authenticated users can insert games"
  ON games FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Only service role can update/delete games (BGG sync)
-- No UPDATE/DELETE policy means only service_role can modify

-- ============================================================
-- USER GAME COLLECTION POLICIES
-- ============================================================

-- View: public collections if profile is public, or own collection
CREATE POLICY "Collections viewable if profile is public or own"
  ON user_game_collection FOR SELECT
  USING (
    profile_id = auth.uid() OR
    profile_is_public(profile_id)
  );

-- Insert: only own collection
CREATE POLICY "Users can insert into their own collection"
  ON user_game_collection FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- Update: only own collection entries
CREATE POLICY "Users can update their own collection entries"
  ON user_game_collection FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- Delete: only own collection entries
CREATE POLICY "Users can delete their own collection entries"
  ON user_game_collection FOR DELETE
  USING (auth.uid() = profile_id);

-- ============================================================
-- FAVORITE GAMES POLICIES
-- ============================================================

-- View: public if profile is public, or own favorites
CREATE POLICY "Favorites viewable if profile is public or own"
  ON favorite_games FOR SELECT
  USING (
    profile_id = auth.uid() OR
    profile_is_public(profile_id)
  );

-- Insert: only own favorites
CREATE POLICY "Users can insert their own favorites"
  ON favorite_games FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- Update: only own favorites
CREATE POLICY "Users can update their own favorites"
  ON favorite_games FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- Delete: only own favorites
CREATE POLICY "Users can delete their own favorites"
  ON favorite_games FOR DELETE
  USING (auth.uid() = profile_id);

-- ============================================================
-- USER AVAILABILITY POLICIES
-- ============================================================

-- View: public if profile is public, or own availability
CREATE POLICY "Availability viewable if profile is public or own"
  ON user_availability FOR SELECT
  USING (
    profile_id = auth.uid() OR
    profile_is_public(profile_id)
  );

-- Insert: only own availability
CREATE POLICY "Users can insert their own availability"
  ON user_availability FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- Update: only own availability
CREATE POLICY "Users can update their own availability"
  ON user_availability FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- Delete: only own availability
CREATE POLICY "Users can delete their own availability"
  ON user_availability FOR DELETE
  USING (auth.uid() = profile_id);

-- ============================================================
-- USER RATINGS POLICIES
-- ============================================================

-- View: public ratings visible to all; private ratings only to rater/rated
CREATE POLICY "Public ratings are viewable by everyone"
  ON user_ratings FOR SELECT
  USING (
    is_public = true OR
    auth.uid() = rater_id OR
    auth.uid() = rated_id
  );

-- Insert: authenticated users can rate others (not themselves)
CREATE POLICY "Authenticated users can submit ratings"
  ON user_ratings FOR INSERT
  WITH CHECK (
    auth.uid() = rater_id AND
    auth.uid() != rated_id
  );

-- Update: raters can update their own ratings
CREATE POLICY "Raters can update their own ratings"
  ON user_ratings FOR UPDATE
  USING (auth.uid() = rater_id)
  WITH CHECK (auth.uid() = rater_id);

-- Delete: raters can remove their own ratings
CREATE POLICY "Raters can delete their own ratings"
  ON user_ratings FOR DELETE
  USING (auth.uid() = rater_id);
