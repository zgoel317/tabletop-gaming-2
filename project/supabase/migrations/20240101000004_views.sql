-- ============================================================
-- DATABASE VIEWS FOR COMMON QUERIES
-- ============================================================

-- Full profile view with computed stats
CREATE OR REPLACE VIEW profile_summaries AS
SELECT
  p.id,
  p.username,
  p.display_name,
  p.bio,
  p.avatar_url,
  p.city,
  p.state_province,
  p.country,
  p.experience_level,
  p.is_looking_for_group,
  p.last_active_at,
  p.created_at,
  -- Rating stats
  COALESCE(r.average_rating, 0)::DECIMAL(3,2) AS average_rating,
  COALESCE(r.rating_count, 0)::INTEGER AS rating_count,
  -- Collection stats
  COALESCE(c.owned_count, 0)::INTEGER AS owned_games_count,
  COALESCE(c.wishlist_count, 0)::INTEGER AS wishlist_games_count,
  -- Connection stats
  COALESCE(conn.follower_count, 0)::INTEGER AS follower_count,
  COALESCE(conn.following_count, 0)::INTEGER AS following_count
FROM profiles p
LEFT JOIN (
  SELECT
    rated_id,
    ROUND(AVG(rating)::DECIMAL, 2) AS average_rating,
    COUNT(*) AS rating_count
  FROM user_ratings
  WHERE is_public = TRUE
  GROUP BY rated_id
) r ON p.id = r.rated_id
LEFT JOIN (
  SELECT
    profile_id,
    COUNT(*) FILTER (WHERE status = 'owned') AS owned_count,
    COUNT(*) FILTER (WHERE status = 'wishlist') AS wishlist_count
  FROM user_game_collections
  GROUP BY profile_id
) c ON p.id = c.profile_id
LEFT JOIN (
  SELECT
    following_id AS profile_id,
    COUNT(*) AS follower_count
  FROM user_connections
  WHERE status != 'blocked'
  GROUP BY following_id
) conn ON p.id = conn.profile_id
LEFT JOIN (
  SELECT
    follower_id AS profile_id,
    COUNT(*) AS following_count
  FROM user_connections
  WHERE status != 'blocked'
  GROUP BY follower_id
) fconn ON p.id = fconn.profile_id
WHERE p.is_profile_public = TRUE;

COMMENT ON VIEW profile_summaries IS 'Public profile summaries with computed stats for listing pages';

-- View for games with collection counts
CREATE OR REPLACE VIEW game_popularity AS
SELECT
  g.id,
  g.bgg_id,
  g.name,
  g.thumbnail_url,
  g.year_published,
  g.min_players,
  g.max_players,
  g.min_playtime,
  g.max_playtime,
  g.complexity_rating,
  g.average_rating,
  g.genres,
  -- Community stats
  COALESCE(c.owner_count, 0)::INTEGER AS owner_count,
  COALESCE(c.wishlist_count, 0)::INTEGER AS wishlist_count,
  COALESCE(c.want_to_play_count, 0)::INTEGER AS want_to_play_count,
  COALESCE(f.favorite_count, 0)::INTEGER AS favorite_count,
  COALESCE(c.avg_user_rating, 0)::DECIMAL(4,2) AS avg_user_rating
FROM games g
LEFT JOIN (
  SELECT
    game_id,
    COUNT(*) FILTER (WHERE status = 'owned') AS owner_count,
    COUNT(*) FILTER (WHERE status = 'wishlist') AS wishlist_count,
    COUNT(*) FILTER (WHERE status = 'want_to_play') AS want_to_play_count,
    ROUND(AVG(user_rating) FILTER (WHERE user_rating IS NOT NULL)::DECIMAL, 2) AS avg_user_rating
  FROM user_game_collections
  GROUP BY game_id
) c ON g.id = c.game_id
LEFT JOIN (
  SELECT game_id, COUNT(*) AS favorite_count
  FROM user_favorite_games
  GROUP BY game_id
) f ON g.id = f.game_id;

COMMENT ON VIEW game_popularity IS 'Games with community popularity metrics';

-- View for user availability summary
CREATE OR REPLACE VIEW user_availability_summary AS
SELECT
  p.id AS profile_id,
  p.username,
  p.display_name,
  -- Aggregate availability into arrays of available slots
  ARRAY_AGG(
    DISTINCT a.day_of_week::TEXT
    ORDER BY a.day_of_week::TEXT
  ) FILTER (WHERE a.is_available = TRUE) AS available_days,
  ARRAY_AGG(
    DISTINCT a.time_of_day::TEXT
    ORDER BY a.time_of_day::TEXT
  ) FILTER (WHERE a.is_available = TRUE) AS available_times,
  -- Count of available slots
  COUNT(a.id) FILTER (WHERE a.is_available = TRUE) AS available_slot_count
FROM profiles p
LEFT JOIN availability_slots a ON p.id = a.profile_id
WHERE p.is_profile_public = TRUE
GROUP BY p.id, p.username, p.display_name;

COMMENT ON VIEW user_availability_summary IS 'Summarized user availability for matching and display';

-- View for user gaming preferences with genre details
CREATE OR REPLACE VIEW user_gaming_profile AS
SELECT
  p.id AS profile_id,
  p.username,
  p.display_name,
  p.experience_level,
  gp.preferred_genres,
  gp.min_players_preferred,
  gp.max_players_preferred,
  gp.preferred_session_length_min,
  gp.preferred_session_length_max,
  gp.preferred_frequency,
  gp.min_complexity,
  gp.max_complexity,
  gp.prefers_competitive,
  gp.prefers_cooperative,
  gp.open_to_teaching,
  gp.open_to_being_taught,
  -- Favorite games (up to 5)
  ARRAY(
    SELECT g.name
    FROM user_favorite_games ufg
    JOIN games g ON ufg.game_id = g.id
    WHERE ufg.profile_id = p.id
    ORDER BY ufg.sort_order
    LIMIT 5
  ) AS favorite_game_names
FROM profiles p
LEFT JOIN gaming_preferences gp ON p.id = gp.profile_id
WHERE p.is_profile_public = TRUE;

COMMENT ON VIEW user_gaming_profile IS 'Combined gaming preferences and profile data for matching';
