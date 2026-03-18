-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================
-- Enable RLS on all tables

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE gaming_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE availability_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_game_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorite_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_views ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- HELPER FUNCTIONS FOR RLS
-- ============================================================

-- Check if the current user's profile is public
CREATE OR REPLACE FUNCTION is_profile_public(profile_id UUID)
RETURNS BOOLEAN AS $$
  SELECT is_profile_public
  FROM profiles
  WHERE id = profile_id;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Check if the current user is connected to another user
CREATE OR REPLACE FUNCTION is_connected_to(other_user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1
    FROM user_connections
    WHERE (
      (follower_id = auth.uid() AND following_id = other_user_id) OR
      (follower_id = other_user_id AND following_id = auth.uid())
    )
    AND status != 'blocked'
  );
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Check if user is blocked
CREATE OR REPLACE FUNCTION is_blocked_by(other_user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1
    FROM user_connections
    WHERE follower_id = other_user_id
      AND following_id = auth.uid()
      AND status = 'blocked'
  );
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ============================================================
-- PROFILES POLICIES
-- ============================================================

-- Anyone (including anonymous) can view public profiles
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles
  FOR SELECT
  USING (is_profile_public = TRUE);

-- Authenticated users can view their own profile even if private
CREATE POLICY "Users can view their own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Users can only insert their own profile (handled by trigger, but safety net)
CREATE POLICY "Users can insert their own profile"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users cannot delete profiles (soft delete pattern preferred)
-- Admin role would handle deletions via service role key

-- ============================================================
-- GAMING PREFERENCES POLICIES
-- ============================================================

-- Gaming preferences are visible if the linked profile is public
CREATE POLICY "Gaming preferences visible for public profiles"
  ON gaming_preferences
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = gaming_preferences.profile_id
        AND profiles.is_profile_public = TRUE
    )
  );

-- Users can view their own gaming preferences
CREATE POLICY "Users can view their own gaming preferences"
  ON gaming_preferences
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

-- Users can insert their own gaming preferences
CREATE POLICY "Users can insert their own gaming preferences"
  ON gaming_preferences
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

-- Users can update their own gaming preferences
CREATE POLICY "Users can update their own gaming preferences"
  ON gaming_preferences
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- Users can delete their own gaming preferences
CREATE POLICY "Users can delete their own gaming preferences"
  ON gaming_preferences
  FOR DELETE
  TO authenticated
  USING (auth.uid() = profile_id);

-- ============================================================
-- AVAILABILITY SLOTS POLICIES
-- ============================================================

-- Availability visible for public profiles
CREATE POLICY "Availability visible for public profiles"
  ON availability_slots
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = availability_slots.profile_id
        AND profiles.is_profile_public = TRUE
    )
  );

-- Users can view their own availability
CREATE POLICY "Users can view their own availability"
  ON availability_slots
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

-- Users can manage their own availability
CREATE POLICY "Users can insert their own availability"
  ON availability_slots
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update their own availability"
  ON availability_slots
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can delete their own availability"
  ON availability_slots
  FOR DELETE
  TO authenticated
  USING (auth.uid() = profile_id);

-- ============================================================
-- GAMES POLICIES
-- ============================================================

-- Games catalog is publicly readable (it's reference data)
CREATE POLICY "Games are publicly viewable"
  ON games
  FOR SELECT
  USING (TRUE);

-- Only service role can insert/update games (BGG sync)
-- No insert/update/delete policies for regular users
-- The service role key bypasses RLS by default

-- ============================================================
-- USER GAME COLLECTIONS POLICIES
-- ============================================================

-- Collections are visible if the linked profile is public
CREATE POLICY "Collections visible for public profiles"
  ON user_game_collections
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = user_game_collections.profile_id
        AND profiles.is_profile_public = TRUE
    )
  );

-- Users can view their own collection
CREATE POLICY "Users can view their own collection"
  ON user_game_collections
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

-- Users can manage their own collection
CREATE POLICY "Users can insert into their own collection"
  ON user_game_collections
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update their own collection"
  ON user_game_collections
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can delete from their own collection"
  ON user_game_collections
  FOR DELETE
  TO authenticated
  USING (auth.uid() = profile_id);

-- ============================================================
-- USER FAVORITE GAMES POLICIES
-- ============================================================

-- Favorites visible for public profiles
CREATE POLICY "Favorites visible for public profiles"
  ON user_favorite_games
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = user_favorite_games.profile_id
        AND profiles.is_profile_public = TRUE
    )
  );

-- Users can view their own favorites
CREATE POLICY "Users can view their own favorites"
  ON user_favorite_games
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

-- Users can manage their own favorites
CREATE POLICY "Users can insert their own favorites"
  ON user_favorite_games
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can delete their own favorites"
  ON user_favorite_games
  FOR DELETE
  TO authenticated
  USING (auth.uid() = profile_id);

-- ============================================================
-- USER RATINGS POLICIES
-- ============================================================

-- Public ratings are visible to everyone
CREATE POLICY "Public ratings are viewable by everyone"
  ON user_ratings
  FOR SELECT
  USING (is_public = TRUE);

-- Users can view all ratings they gave or received
CREATE POLICY "Users can view their own ratings"
  ON user_ratings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = rater_id OR auth.uid() = rated_id);

-- Users can create ratings (but not rate themselves - enforced by CHECK constraint)
CREATE POLICY "Authenticated users can create ratings"
  ON user_ratings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = rater_id AND auth.uid() != rated_id);

-- Users can update their own ratings
CREATE POLICY "Users can update their own ratings"
  ON user_ratings
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = rater_id)
  WITH CHECK (auth.uid() = rater_id);

-- Users can delete their own ratings
CREATE POLICY "Users can delete their own ratings"
  ON user_ratings
  FOR DELETE
  TO authenticated
  USING (auth.uid() = rater_id);

-- ============================================================
-- USER CONNECTIONS POLICIES
-- ============================================================

-- Connections are visible to the users involved
CREATE POLICY "Users can view their own connections"
  ON user_connections
  FOR SELECT
  TO authenticated
  USING (auth.uid() = follower_id OR auth.uid() = following_id);

-- Anyone can see non-blocked connections (for mutual connection checks)
CREATE POLICY "Non-blocked connections visible to authenticated users"
  ON user_connections
  FOR SELECT
  TO authenticated
  USING (status != 'blocked');

-- Users can create connections where they are the follower
CREATE POLICY "Users can create connections"
  ON user_connections
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = follower_id AND auth.uid() != following_id);

-- Users can update connections they own
CREATE POLICY "Users can update their connections"
  ON user_connections
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = follower_id)
  WITH CHECK (auth.uid() = follower_id);

-- Users can delete connections they created
CREATE POLICY "Users can delete their connections"
  ON user_connections
  FOR DELETE
  TO authenticated
  USING (auth.uid() = follower_id);

-- ============================================================
-- PROFILE VIEWS POLICIES
-- ============================================================

-- Profile owners can see who viewed their profile
CREATE POLICY "Profile owners can view their profile views"
  ON profile_views
  FOR SELECT
  TO authenticated
  USING (auth.uid() = viewed_profile_id);

-- Authenticated users can log profile views
CREATE POLICY "Authenticated users can log profile views"
  ON profile_views
  FOR INSERT
  TO authenticated
  WITH CHECK (TRUE);

-- Anonymous users can also log profile views (for public profiles)
CREATE POLICY "Anonymous users can log profile views"
  ON profile_views
  FOR INSERT
  TO anon
  WITH CHECK (viewer_id IS NULL);
