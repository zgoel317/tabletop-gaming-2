-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Find profiles near a lat/lng point within a radius (km)
CREATE OR REPLACE FUNCTION public.find_nearby_profiles(
  p_latitude   FLOAT,
  p_longitude  FLOAT,
  p_radius_km  FLOAT DEFAULT 50,
  p_limit      INTEGER DEFAULT 20,
  p_offset     INTEGER DEFAULT 0
)
RETURNS TABLE (
  id               UUID,
  username         TEXT,
  display_name     TEXT,
  avatar_url       TEXT,
  bio              TEXT,
  experience_level experience_level,
  is_looking_for_group BOOLEAN,
  distance_km      FLOAT,
  average_rating   NUMERIC,
  total_ratings    INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    p.bio,
    p.experience_level,
    p.is_looking_for_group,
    ROUND(
      (ST_Distance(
        p.location,
        ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
      ) / 1000.0)::NUMERIC,
      2
    )::FLOAT AS distance_km,
    p.average_rating,
    p.total_ratings
  FROM public.profiles p
  WHERE
    p.is_active = TRUE
    AND p.location IS NOT NULL
    AND p.location_public = TRUE
    AND p.id != COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    AND ST_DWithin(
      p.location,
      ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_km * 1000  -- ST_DWithin uses metres
    )
  ORDER BY distance_km ASC
  LIMIT  p_limit
  OFFSET p_offset;
$$;

COMMENT ON FUNCTION public.find_nearby_profiles IS
  'Returns profiles within p_radius_km kilometres of the given coordinates, ordered by distance.';

-- --------------------------------------------------------
-- Update a profile's location from lat/lng values
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_profile_location(
  p_profile_id UUID,
  p_latitude   FLOAT,
  p_longitude  FLOAT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() != p_profile_id AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: cannot update another user''s location';
  END IF;

  UPDATE public.profiles
  SET
    location   = ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
    updated_at = NOW()
  WHERE id = p_profile_id;
END;
$$;

COMMENT ON FUNCTION public.set_profile_location IS
  'Sets the PostGIS geography point for a profile from latitude/longitude values.';

-- --------------------------------------------------------
-- Search profiles by username / display name (fuzzy)
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.search_profiles(
  p_query  TEXT,
  p_limit  INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id           UUID,
  username     TEXT,
  display_name TEXT,
  avatar_url   TEXT,
  similarity   FLOAT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    GREATEST(
      similarity(p.username,     p_query),
      similarity(COALESCE(p.display_name, ''), p_query)
    ) AS similarity
  FROM public.profiles p
  WHERE
    p.is_active = TRUE
    AND (
      p.username     ILIKE '%' || p_query || '%'
      OR p.display_name ILIKE '%' || p_query || '%'
    )
  ORDER BY similarity DESC, p.username ASC
  LIMIT  p_limit
  OFFSET p_offset;
$$;

COMMENT ON FUNCTION public.search_profiles IS
  'Fuzzy search profiles by username or display name.';

-- --------------------------------------------------------
-- Get follower / following counts for a profile
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_follow_counts(p_profile_id UUID)
RETURNS TABLE (followers BIGINT, following BIGINT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    (SELECT COUNT(*) FROM public.profile_follows WHERE following_id = p_profile_id) AS followers,
    (SELECT COUNT(*) FROM public.profile_follows WHERE follower_id  = p_profile_id) AS following;
$$;

-- --------------------------------------------------------
-- Upsert a game genre preference for the current user
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.upsert_gaming_preference(
  p_genre            game_genre,
  p_preference_level INTEGER DEFAULT 3
)
RETURNS public.gaming_preferences
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result public.gaming_preferences;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.gaming_preferences (profile_id, genre, preference_level)
  VALUES (auth.uid(), p_genre, p_preference_level)
  ON CONFLICT (profile_id, genre)
  DO UPDATE SET preference_level = EXCLUDED.preference_level
  RETURNING * INTO v_result;

  RETURN v_result;
END;
$$;

-- ============================================================
-- VIEWS
-- ============================================================

-- Public profile summary (safe for anonymous access)
CREATE OR REPLACE VIEW public.profile_summaries AS
SELECT
  p.id,
  p.username,
  p.display_name,
  p.avatar_url,
  p.bio,
  p.city,
  p.state_province,
  p.country,
  p.experience_level,
  p.is_looking_for_group,
  p.is_open_to_teach,
  p.is_open_to_learn,
  p.available_days,
  p.available_times,
  p.total_sessions_played,
  p.total_sessions_hosted,
  p.average_rating,
  p.total_ratings,
  p.created_at,
  -- Aggregate preferred genres
  ARRAY(
    SELECT gp.genre
    FROM public.gaming_preferences gp
    WHERE gp.profile_id = p.id
    ORDER BY gp.preference_level DESC
  ) AS preferred_genres
FROM public.profiles p
WHERE p.is_active = TRUE;

COMMENT ON VIEW public.profile_summaries IS
  'Safe public summary of user profiles, excluding sensitive fields like exact location.';

-- Current user's full profile (includes private fields)
CREATE OR REPLACE VIEW public.my_profile AS
SELECT
  p.*,
  ARRAY(
    SELECT gp.genre
    FROM public.gaming_preferences gp
    WHERE gp.profile_id = p.id
    ORDER BY gp.preference_level DESC
  ) AS preferred_genres
FROM public.profiles p
WHERE p.id = auth.uid();

COMMENT ON VIEW public.my_profile IS
  'Full profile data for the currently authenticated user.';

-- Game collection with game details
CREATE OR REPLACE VIEW public.user_collection_details AS
SELECT
  ugc.id,
  ugc.profile_id,
  ugc.status,
  ugc.personal_rating,
  ugc.notes,
  ugc.times_played,
  ugc.willing_to_bring,
  ugc.created_at,
  ugc.updated_at,
  -- Game fields
  g.id            AS game_id,
  g.bgg_id,
  g.name          AS game_name,
  g.thumbnail_url,
  g.min_players,
  g.max_players,
  g.min_playtime,
  g.max_playtime,
  g.complexity_rating,
  g.bgg_rating,
  g.genres        AS game_genres
FROM public.user_game_collection ugc
JOIN public.games g ON g.id = ugc.game_id;

COMMENT ON VIEW public.user_collection_details IS
  'User game collection entries joined with full game metadata.';
