-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all public tables
ALTER TABLE public.profiles               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gaming_preferences     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_game_collection   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_ratings           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_follows        ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- HELPER: is current user an admin/moderator?
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role IN ('admin', 'moderator')
  );
$$;

-- ============================================================
-- PROFILES POLICIES
-- ============================================================

-- Anyone (including anonymous) can view active public profiles
CREATE POLICY "profiles_select_public"
  ON public.profiles
  FOR SELECT
  USING (is_active = TRUE);

-- Authenticated users can insert their own profile
-- (also handled by the handle_new_user trigger, but kept for safety)
CREATE POLICY "profiles_insert_own"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update only their own profile
CREATE POLICY "profiles_update_own"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users cannot hard-delete profiles; admins can
CREATE POLICY "profiles_delete_admin"
  ON public.profiles
  FOR DELETE
  USING (public.is_admin());

-- ============================================================
-- GAMING PREFERENCES POLICIES
-- ============================================================

-- Anyone can view gaming preferences (they accompany public profiles)
CREATE POLICY "gaming_preferences_select_public"
  ON public.gaming_preferences
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = gaming_preferences.profile_id
        AND p.is_active = TRUE
    )
  );

-- Users manage only their own preferences
CREATE POLICY "gaming_preferences_insert_own"
  ON public.gaming_preferences
  FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "gaming_preferences_update_own"
  ON public.gaming_preferences
  FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "gaming_preferences_delete_own"
  ON public.gaming_preferences
  FOR DELETE
  USING (auth.uid() = profile_id);

-- ============================================================
-- GAMES POLICIES (public catalog, admin-managed)
-- ============================================================

-- All users (incl. anon) can read games
CREATE POLICY "games_select_all"
  ON public.games
  FOR SELECT
  USING (TRUE);

-- Only admins can insert/update/delete games
CREATE POLICY "games_insert_admin"
  ON public.games
  FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "games_update_admin"
  ON public.games
  FOR UPDATE
  USING (public.is_admin());

CREATE POLICY "games_delete_admin"
  ON public.games
  FOR DELETE
  USING (public.is_admin());

-- ============================================================
-- USER GAME COLLECTION POLICIES
-- ============================================================

-- Anyone can view collections (they're part of a public profile)
CREATE POLICY "user_game_collection_select_public"
  ON public.user_game_collection
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_game_collection.profile_id
        AND p.is_active = TRUE
    )
  );

-- Users manage only their own collection
CREATE POLICY "user_game_collection_insert_own"
  ON public.user_game_collection
  FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "user_game_collection_update_own"
  ON public.user_game_collection
  FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "user_game_collection_delete_own"
  ON public.user_game_collection
  FOR DELETE
  USING (auth.uid() = profile_id);

-- ============================================================
-- USER RATINGS POLICIES
-- ============================================================

-- Anyone can view ratings for active users
CREATE POLICY "user_ratings_select_public"
  ON public.user_ratings
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_ratings.rated_id
        AND p.is_active = TRUE
    )
  );

-- Authenticated users can submit ratings (rater must be themselves)
CREATE POLICY "user_ratings_insert_own"
  ON public.user_ratings
  FOR INSERT
  WITH CHECK (auth.uid() = rater_id);

-- Raters can update their own submitted ratings
CREATE POLICY "user_ratings_update_own"
  ON public.user_ratings
  FOR UPDATE
  USING (auth.uid() = rater_id)
  WITH CHECK (auth.uid() = rater_id);

-- Raters can delete their own ratings; admins can delete any
CREATE POLICY "user_ratings_delete_own_or_admin"
  ON public.user_ratings
  FOR DELETE
  USING (auth.uid() = rater_id OR public.is_admin());

-- ============================================================
-- PROFILE FOLLOWS POLICIES
-- ============================================================

-- Anyone can see follow relationships
CREATE POLICY "profile_follows_select_public"
  ON public.profile_follows
  FOR SELECT
  USING (TRUE);

-- Authenticated users can follow others (they must be the follower)
CREATE POLICY "profile_follows_insert_own"
  ON public.profile_follows
  FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

-- Users can unfollow (delete their own follow rows)
CREATE POLICY "profile_follows_delete_own"
  ON public.profile_follows
  FOR DELETE
  USING (auth.uid() = follower_id);
