-- ============================================================
-- Migration: 00004_utility_functions.sql
-- Description: Helper functions, views, and stored procedures
--              for common application queries
-- ============================================================

-- ============================================================
-- FUNCTION: get_nearby_profiles
-- Find active users within a given radius
-- ============================================================

CREATE OR REPLACE FUNCTION get_nearby_profiles(
  p_latitude    FLOAT,
  p_longitude   FLOAT,
  p_radius_km   FLOAT DEFAULT 50,
  p_limit       INTEGER DEFAULT 20,
  p_offset      INTEGER DEFAULT 0
)
RETURNS TABLE (
  id              UUID,
  username        TEXT,
  display_name    TEXT,
  avatar_url      TEXT,
  city            TEXT,
  experience_level experience_level,
  rating_average  NUMERIC,
  rating_count    INTEGER,
  distance_km     FLOAT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    p.city,
    p.experience_level,
    p.rating_average,
    p.rating_count,
    ROUND(
      (ST_Distance(
        p.location::geography,
        ST_MakePoint(p_longitude, p_latitude)::geography
      ) / 1000)::NUMERIC,
      2
    )::FLOAT AS distance_km
  FROM profiles p
  WHERE
    p.is_active = TRUE
    AND p.location IS NOT NULL
    AND p.id != auth.uid()  -- Exclude the calling user
    AND ST_DWithin(
      p.location::geography,
      ST_MakePoint(p_longitude, p_latitude)::geography,
      p_radius_km * 1000  -- Convert km to meters
    )
  ORDER BY distance_km ASC
  LIMIT p_limit
  OFFSET p_offset;
$$;

COMMENT ON FUNCTION get_nearby_profiles IS
  'Returns active user profiles within a given radius (km) of a geographic point';

-- ============================================================
-- FUNCTION: get_nearby_events
-- Find upcoming published events near a location
-- ============================================================

CREATE OR REPLACE FUNCTION get_nearby_events(
  p_latitude    FLOAT,
  p_longitude   FLOAT,
  p_radius_km   FLOAT DEFAULT 50,
  p_limit       INTEGER DEFAULT 20,
  p_offset      INTEGER DEFAULT 0
)
RETURNS TABLE (
  id            UUID,
  title         TEXT,
  starts_at     TIMESTAMPTZ,
  location_type location_type,
  city          TEXT,
  host_id       UUID,
  game_id       UUID,
  attendee_count INTEGER,
  max_players   SMALLINT,
  distance_km   FLOAT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    e.id,
    e.title,
    e.starts_at,
    e.location_type,
    e.city,
    e.host_id,
    e.game_id,
    e.attendee_count,
    e.max_players,
    ROUND(
      (ST_Distance(
        e.location::geography,
        ST_MakePoint(p_longitude, p_latitude)::geography
      ) / 1000)::NUMERIC,
      2
    )::FLOAT AS distance_km
  FROM events e
  WHERE
    e.status = 'published'
    AND e.starts_at > NOW()
    AND e.location IS NOT NULL
    AND ST_DWithin(
      e.location::geography,
      ST_MakePoint(p_longitude, p_latitude)::geography,
      p_radius_km * 1000
    )
  ORDER BY e.starts_at ASC, distance_km ASC
  LIMIT p_limit
  OFFSET p_offset;
$$;

COMMENT ON FUNCTION get_nearby_events IS
  'Returns upcoming published events within a given radius (km) of a geographic point';

-- ============================================================
-- FUNCTION: search_profiles
-- Full-text + trigram search for user profiles
-- ============================================================

CREATE OR REPLACE FUNCTION search_profiles(
  p_query           TEXT,
  p_experience      experience_level DEFAULT NULL,
  p_genre           game_genre DEFAULT NULL,
  p_limit           INTEGER DEFAULT 20,
  p_offset          INTEGER DEFAULT 0
)
RETURNS TABLE (
  id               UUID,
  username         TEXT,
  display_name     TEXT,
  avatar_url       TEXT,
  city             TEXT,
  experience_level experience_level,
  rating_average   NUMERIC,
  rank             FLOAT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT DISTINCT
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    p.city,
    p.experience_level,
    p.rating_average,
    ts_rank(
      to_tsvector('english',
        coalesce(p.username, '') || ' ' ||
        coalesce(p.display_name, '') || ' ' ||
        coalesce(p.bio, '')
      ),
      plainto_tsquery('english', p_query)
    ) AS rank
  FROM profiles p
  LEFT JOIN profile_preferred_genres ppg ON ppg.profile_id = p.id
  WHERE
    p.is_active = TRUE
    AND (
      p_query IS NULL OR p_query = ''
      OR to_tsvector('english',
           coalesce(p.username, '') || ' ' ||
           coalesce(p.display_name, '') || ' ' ||
           coalesce(p.bio, '')
         ) @@ plainto_tsquery('english', p_query)
      OR p.username ILIKE '%' || p_query || '%'
    )
    AND (p_experience IS NULL OR p.experience_level = p_experience)
    AND (p_genre IS NULL OR ppg.genre = p_genre)
  ORDER BY rank DESC, p.rating_average DESC
  LIMIT p_limit
  OFFSET p_offset;
$$;

COMMENT ON FUNCTION search_profiles IS
  'Full-text search for user profiles with optional filters';

-- ============================================================
-- FUNCTION: search_games
-- Search the game catalog by name
-- ============================================================

CREATE OR REPLACE FUNCTION search_games(
  p_query     TEXT,
  p_genre     game_genre DEFAULT NULL,
  p_min_age   SMALLINT DEFAULT NULL,
  p_max_complexity NUMERIC DEFAULT NULL,
  p_limit     INTEGER DEFAULT 20,
  p_offset    INTEGER DEFAULT 0
)
RETURNS TABLE (
  id            UUID,
  bgg_id        INTEGER,
  name          TEXT,
  thumbnail_url TEXT,
  min_players   SMALLINT,
  max_players   SMALLINT,
  min_play_time INTEGER,
  max_play_time INTEGER,
  complexity    NUMERIC,
  bgg_rating    NUMERIC,
  rank          FLOAT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT DISTINCT
    g.id,
    g.bgg_id,
    g.name,
    g.thumbnail_url,
    g.min_players,
    g.max_players,
    g.min_play_time,
    g.max_play_time,
    g.complexity,
    g.bgg_rating,
    ts_rank(
      to_tsvector('english', g.name || ' ' || coalesce(g.description, '')),
      plainto_tsquery('english', p_query)
    ) AS rank
  FROM games g
  LEFT JOIN game_genres gg ON gg.game_id = g.id
  WHERE
    (
      p_query IS NULL OR p_query = ''
      OR to_tsvector('english', g.name || ' ' || coalesce(g.description, ''))
         @@ plainto_tsquery('english', p_query)
      OR g.name ILIKE '%' || p_query || '%'
    )
    AND (p_genre IS NULL OR gg.genre = p_genre)
    AND (p_min_age IS NULL OR g.min_age IS NULL OR g.min_age >= p_min_age)
    AND (p_max_complexity IS NULL OR g.complexity IS NULL OR g.complexity <= p_max_complexity)
  ORDER BY rank DESC, g.bgg_rank ASC NULLS LAST
  LIMIT p_limit
  OFFSET p_offset;
$$;

COMMENT ON FUNCTION search_games IS
  'Full-text search for board games with optional filters';

-- ============================================================
-- FUNCTION: get_or_create_direct_conversation
-- Returns existing DM conversation or creates a new one
-- ============================================================

CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(
  p_other_user_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_conversation_id UUID;
  v_current_user_id UUID := auth.uid();
BEGIN
  IF v_current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_current_user_id = p_other_user_id THEN
    RAISE EXCEPTION 'Cannot create conversation with yourself';
  END IF;

  -- Look for an existing direct conversation between both users
  SELECT cp1.conversation_id INTO v_conversation_id
  FROM conversation_participants cp1
  JOIN conversation_participants cp2
    ON cp2.conversation_id = cp1.conversation_id
    AND cp2.profile_id = p_other_user_id
  JOIN conversations c
    ON c.id = cp1.conversation_id
    AND c.type = 'direct'
  WHERE cp1.profile_id = v_current_user_id
  LIMIT 1;

  -- Create new conversation if none exists
  IF v_conversation_id IS NULL THEN
    INSERT INTO conversations (type, created_by)
    VALUES ('direct', v_current_user_id)
    RETURNING id INTO v_conversation_id;

    -- Add both participants
    INSERT INTO conversation_participants (conversation_id, profile_id)
    VALUES
      (v_conversation_id, v_current_user_id),
      (v_conversation_id, p_other_user_id);
  END IF;

  RETURN v_conversation_id;
END;
$$;

COMMENT ON FUNCTION get_or_create_direct_conversation IS
  'Returns existing DM conversation ID or creates a new one between two users';

-- ============================================================
-- FUNCTION: get_user_unread_counts
-- Returns unread message counts per conversation for the
-- current user
-- ============================================================

CREATE OR REPLACE FUNCTION get_user_unread_counts()
RETURNS TABLE (
  conversation_id   UUID,
  unread_count      BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    cp.conversation_id,
    COUNT(m.id) AS unread_count
  FROM conversation_participants cp
  JOIN messages m ON m.conversation_id = cp.conversation_id
  WHERE
    cp.profile_id = auth.uid()
    AND cp.left_at IS NULL
    AND m.is_deleted = FALSE
    AND m.sender_id != auth.uid()
    AND (cp.last_read_at IS NULL OR m.created_at > cp.last_read_at)
  GROUP BY cp.conversation_id;
$$;

COMMENT ON FUNCTION get_user_unread_counts IS
  'Returns unread message counts per conversation for the current authenticated user';

-- ============================================================
-- FUNCTION: mark_conversation_read
-- Updates last_read_at for the current user in a conversation
-- ============================================================

CREATE OR REPLACE FUNCTION mark_conversation_read(
  p_conversation_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE conversation_participants
  SET last_read_at = NOW()
  WHERE
    conversation_id = p_conversation_id
    AND profile_id = auth.uid();
END;
$$;

COMMENT ON FUNCTION mark_conversation_read IS
  'Marks all messages in a conversation as read for the current user';

-- ============================================================
-- VIEW: profile_with_stats
-- Convenience view joining profile with computed stats
-- ============================================================

CREATE OR REPLACE VIEW profile_with_stats AS
SELECT
  p.*,
  -- Preferred genres as an array
  COALESCE(
    ARRAY_AGG(DISTINCT ppg.genre) FILTER (WHERE ppg.genre IS NOT NULL),
    '{}'::game_genre[]
  ) AS preferred_genres,
  -- Available days as an array
  COALESCE(
    ARRAY_AGG(DISTINCT pa.day_of_week) FILTER (WHERE pa.day_of_week IS NOT NULL),
    '{}'::availability_day[]
  ) AS available_days,
  -- Number of favorite games
  COUNT(DISTINCT pfg.game_id) AS favorite_games_count,
  -- Number of owned games
  COUNT(DISTINCT ugc.game_id) FILTER (WHERE ugc.status = 'owned') AS owned_games_count
FROM profiles p
LEFT JOIN profile_preferred_genres ppg ON ppg.profile_id = p.id
LEFT JOIN profile_availability pa ON pa.profile_id = p.id
LEFT JOIN profile_favorite_games pfg ON pfg.profile_id = p.id
LEFT JOIN user_game_collection ugc ON ugc.profile_id = p.id
GROUP BY p.id;

COMMENT ON VIEW profile_with_stats IS
  'User profile with aggregated genre preferences, availability, and collection stats';

-- ============================================================
-- VIEW: event_with_details
-- Convenience view for event cards
-- ============================================================

CREATE OR REPLACE VIEW event_with_details AS
SELECT
  e.*,
  -- Host info
  hp.username        AS host_username,
  hp.display_name    AS host_display_name,
  hp.avatar_url      AS host_avatar_url,
  hp.rating_average  AS host_rating,
  -- Game info
  g.name             AS game_name,
  g.thumbnail_url    AS game_thumbnail_url,
  g.min_players      AS game_min_players,
  g.max_players      AS game_max_players,
  g.complexity       AS game_complexity,
  -- Group info
  grp.name           AS group_name,
  grp.avatar_url     AS group_avatar_url,
  -- Availability
  CASE
    WHEN e.max_players IS NULL THEN TRUE
    ELSE e.attendee_count < e.max_players
  END AS has_spots_available
FROM events e
LEFT JOIN profiles hp  ON hp.id = e.host_id
LEFT JOIN games g      ON g.id  = e.game_id
LEFT JOIN groups grp   ON grp.id = e.group_id;

COMMENT ON VIEW event_with_details IS
  'Events with joined host, game, and group information for display cards';

-- ============================================================
-- VIEW: conversation_with_preview
-- Conversations with latest message preview for inbox
-- ============================================================

CREATE OR REPLACE VIEW conversation_with_preview AS
SELECT
  c.id,
  c.type,
  c.name,
  c.avatar_url,
  c.group_id,
  c.event_id,
  c.last_message_at,
  -- Latest message preview
  m.content         AS last_message_content,
  m.type            AS last_message_type,
  m.sender_id       AS last_message_sender_id,
  sp.username       AS last_message_sender_username,
  sp.avatar_url     AS last_message_sender_avatar
FROM conversations c
LEFT JOIN messages m  ON m.id = c.last_message_id
LEFT JOIN profiles sp ON sp.id = m.sender_id;

COMMENT ON VIEW conversation_with_preview IS
  'Conversations with the latest message preview for rendering inbox/chat list';

-- ============================================================
-- FUNCTION: cleanup_expired_lfg_posts
-- Mark expired LFG posts as 'expired' (run via pg_cron)
-- ============================================================

CREATE OR REPLACE FUNCTION cleanup_expired_lfg_posts()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated INTEGER;
BEGIN
  UPDATE lfg_posts
  SET status = 'expired', updated_at = NOW()
  WHERE
    status = 'open'
    AND expires_at IS NOT NULL
    AND expires_at < NOW();

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated;
END;
$$;

COMMENT ON FUNCTION cleanup_expired_lfg_posts IS
  'Marks expired LFG posts as expired; intended to be run on a schedule via pg_cron';
