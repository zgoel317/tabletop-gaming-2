-- ============================================================
-- AUTHENTICATION TRIGGERS
-- Automatically create profile on user signup
-- ============================================================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  base_username TEXT;
  final_username TEXT;
  counter INTEGER := 0;
BEGIN
  -- Derive a base username from email or metadata
  base_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    LOWER(REGEXP_REPLACE(
      SPLIT_PART(NEW.email, '@', 1),
      '[^a-zA-Z0-9_-]',
      '_',
      'g'
    ))
  );

  -- Ensure username meets minimum length
  IF char_length(base_username) < 3 THEN
    base_username := base_username || '_user';
  END IF;

  -- Truncate to leave room for suffix
  base_username := LEFT(base_username, 25);

  -- Find a unique username
  final_username := base_username;
  WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = final_username) LOOP
    counter := counter + 1;
    final_username := base_username || counter::TEXT;
  END LOOP;

  -- Insert the new profile
  INSERT INTO public.profiles (
    id,
    username,
    display_name,
    avatar_url,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    final_username,
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      final_username
    ),
    NEW.raw_user_meta_data->>'avatar_url',
    NOW(),
    NOW()
  );

  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Log error but don't block user creation
    RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION handle_new_user() IS 'Automatically creates a profile row when a new auth user is registered';

-- Trigger on auth.users insert
CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- FUNCTION: Handle user deletion cleanup
-- Cascades are defined in schema, but this handles additional cleanup
-- ============================================================

CREATE OR REPLACE FUNCTION handle_user_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- Profile deletion cascades automatically via FK
  -- Additional cleanup can be added here (e.g., storage cleanup)
  RAISE LOG 'User % deleted at %', OLD.id, NOW();
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION handle_user_deletion() IS 'Handles cleanup when a user account is deleted';

CREATE TRIGGER trg_on_auth_user_deleted
  BEFORE DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_user_deletion();

-- ============================================================
-- FUNCTION: Get nearby players using PostGIS
-- ============================================================

CREATE OR REPLACE FUNCTION get_nearby_players(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 50,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  experience_level experience_level,
  is_looking_for_group BOOLEAN,
  distance_km DOUBLE PRECISION,
  average_rating NUMERIC,
  city TEXT,
  state TEXT,
  country TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    p.experience_level,
    p.is_looking_for_group,
    ROUND(
      (ST_Distance(
        p.location_point,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::GEOGRAPHY
      ) / 1000)::NUMERIC,
      2
    ) AS distance_km,
    ps.average_rating,
    p.city,
    p.state,
    p.country
  FROM profiles p
  LEFT JOIN profile_stats ps ON ps.profile_id = p.id
  WHERE
    p.is_public = true
    AND p.location_point IS NOT NULL
    AND p.location_public = true
    AND ST_DWithin(
      p.location_point,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::GEOGRAPHY,
      radius_km * 1000
    )
  ORDER BY distance_km ASC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION get_nearby_players IS 'Find players within a radius using PostGIS spatial queries';

-- ============================================================
-- FUNCTION: Search players by username/display name
-- ============================================================

CREATE OR REPLACE FUNCTION search_players(
  search_query TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  experience_level experience_level,
  is_looking_for_group BOOLEAN,
  similarity_score REAL,
  average_rating NUMERIC,
  city TEXT,
  state TEXT,
  country TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    p.experience_level,
    p.is_looking_for_group,
    GREATEST(
      similarity(p.username, search_query),
      similarity(COALESCE(p.display_name, ''), search_query)
    ) AS similarity_score,
    ps.average_rating,
    p.city,
    p.state,
    p.country
  FROM profiles p
  LEFT JOIN profile_stats ps ON ps.profile_id = p.id
  WHERE
    p.is_public = true
    AND (
      p.username ILIKE '%' || search_query || '%' OR
      p.display_name ILIKE '%' || search_query || '%' OR
      similarity(p.username, search_query) > 0.2 OR
      similarity(COALESCE(p.display_name, ''), search_query) > 0.2
    )
  ORDER BY similarity_score DESC, p.username ASC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION search_players IS 'Full-text and fuzzy search for players by username or display name';

-- ============================================================
-- FUNCTION: Get full profile with all related data
-- ============================================================

CREATE OR REPLACE FUNCTION get_profile_with_details(target_profile_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
  requesting_user_id UUID;
  is_own_profile BOOLEAN;
BEGIN
  requesting_user_id := auth.uid();
  is_own_profile := requesting_user_id = target_profile_id;

  SELECT json_build_object(
    'profile', row_to_json(p.*),
    'stats', row_to_json(ps.*),
    'gaming_preferences', (
      SELECT json_agg(row_to_json(gp.*))
      FROM gaming_preferences gp
      WHERE gp.profile_id = target_profile_id
      ORDER BY gp.preference_weight DESC, gp.genre ASC
    ),
    'favorite_games', (
      SELECT json_agg(
        json_build_object(
          'id', fg.id,
          'display_order', fg.display_order,
          'game', row_to_json(g.*)
        ) ORDER BY fg.display_order ASC
      )
      FROM favorite_games fg
      JOIN games g ON g.id = fg.game_id
      WHERE fg.profile_id = target_profile_id
    ),
    'availability', (
      SELECT json_agg(row_to_json(ua.*))
      FROM user_availability ua
      WHERE ua.profile_id = target_profile_id
      ORDER BY ua.day_of_week, ua.time_of_day
    ),
    'recent_ratings', (
      SELECT json_agg(
        json_build_object(
          'id', ur.id,
          'rating', ur.rating,
          'review', ur.review,
          'created_at', ur.created_at,
          'rater', json_build_object(
            'id', rater.id,
            'username', rater.username,
            'display_name', rater.display_name,
            'avatar_url', rater.avatar_url
          )
        )
      )
      FROM user_ratings ur
      JOIN profiles rater ON rater.id = ur.rater_id
      WHERE ur.rated_id = target_profile_id
        AND ur.is_public = true
      ORDER BY ur.created_at DESC
      LIMIT 5
    )
  ) INTO result
  FROM profiles p
  LEFT JOIN profile_stats ps ON ps.profile_id = p.id
  WHERE
    p.id = target_profile_id
    AND (p.is_public = true OR is_own_profile);

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION get_profile_with_details IS 'Returns a complete profile with all related data as JSON';
