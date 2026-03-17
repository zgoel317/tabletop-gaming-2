-- ============================================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all relevant tables

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_gaming_preferences_updated_at
  BEFORE UPDATE ON gaming_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_games_updated_at
  BEFORE UPDATE ON games
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_user_game_collection_updated_at
  BEFORE UPDATE ON user_game_collection
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_user_reviews_updated_at
  BEFORE UPDATE ON user_reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_groups_updated_at
  BEFORE UPDATE ON groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_event_rsvps_updated_at
  BEFORE UPDATE ON event_rsvps
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_lfg_posts_updated_at
  BEFORE UPDATE ON lfg_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_messages_updated_at
  BEFORE UPDATE ON messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- AUTO-CREATE PROFILE ON AUTH USER SIGNUP
-- ============================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  generated_username TEXT;
  counter INTEGER := 0;
BEGIN
  -- Generate a base username from email or metadata
  generated_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    split_part(NEW.email, '@', 1)
  );

  -- Sanitize: keep only alphanumeric, underscore, hyphen; truncate to 25 chars
  generated_username := regexp_replace(generated_username, '[^a-zA-Z0-9_-]', '', 'g');
  generated_username := left(generated_username, 25);

  -- Fallback if sanitization produces empty string
  IF generated_username = '' THEN
    generated_username := 'user';
  END IF;

  -- Ensure username uniqueness by appending a counter if necessary
  WHILE EXISTS (SELECT 1 FROM profiles WHERE username = generated_username) LOOP
    counter := counter + 1;
    generated_username := left(split_part(
      COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
      '@', 1
    ), 20) || counter::TEXT;
    generated_username := regexp_replace(generated_username, '[^a-zA-Z0-9_-]', '', 'g');
  END LOOP;

  -- Insert the new profile
  INSERT INTO profiles (
    id,
    username,
    display_name,
    avatar_url,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    generated_username,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      generated_username
    ),
    NEW.raw_user_meta_data->>'avatar_url',
    NOW(),
    NOW()
  );

  -- Create default gaming preferences row
  INSERT INTO gaming_preferences (user_id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- GROUP MEMBER COUNT MAINTENANCE
-- ============================================================

CREATE OR REPLACE FUNCTION update_group_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE groups SET member_count = member_count + 1 WHERE id = NEW.group_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE groups SET member_count = GREATEST(0, member_count - 1) WHERE id = OLD.group_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_group_members_count
  AFTER INSERT OR DELETE ON group_members
  FOR EACH ROW EXECUTE FUNCTION update_group_member_count();

-- ============================================================
-- EVENT PLAYER COUNT MAINTENANCE
-- ============================================================

CREATE OR REPLACE FUNCTION update_event_player_count()
RETURNS TRIGGER AS $$
DECLARE
  v_event_id UUID;
BEGIN
  -- Determine which event to update
  IF TG_OP = 'DELETE' THEN
    v_event_id := OLD.event_id;
  ELSE
    v_event_id := NEW.event_id;
  END IF;

  UPDATE events
  SET
    current_player_count = (
      SELECT COUNT(*) FROM event_rsvps
      WHERE event_id = v_event_id AND status = 'going'
    ),
    waitlist_count = (
      SELECT COUNT(*) FROM event_rsvps
      WHERE event_id = v_event_id AND status = 'waitlisted'
    )
  WHERE id = v_event_id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_event_rsvp_count
  AFTER INSERT OR UPDATE OR DELETE ON event_rsvps
  FOR EACH ROW EXECUTE FUNCTION update_event_player_count();

-- ============================================================
-- CONVERSATION LAST MESSAGE TIMESTAMP
-- ============================================================

CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_message_updates_conversation
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_last_message();

-- ============================================================
-- WAITLIST AUTO-PROMOTION
-- When a 'going' RSVP is deleted or set to 'not_going', promote
-- the first waitlisted user automatically.
-- ============================================================

CREATE OR REPLACE FUNCTION promote_waitlist_user()
RETURNS TRIGGER AS $$
DECLARE
  v_event_record events%ROWTYPE;
  v_next_waitlist event_rsvps%ROWTYPE;
BEGIN
  -- Only act when a 'going' rsvp is removed or set to not_going/maybe
  IF NOT (
    (TG_OP = 'DELETE' AND OLD.status = 'going')
    OR (TG_OP = 'UPDATE' AND OLD.status = 'going' AND NEW.status <> 'going')
  ) THEN
    RETURN NULL;
  END IF;

  -- Fetch event details
  SELECT * INTO v_event_record FROM events WHERE id = OLD.event_id;

  -- Only promote if there's a max_players cap
  IF v_event_record.max_players IS NULL THEN
    RETURN NULL;
  END IF;

  -- Check if there's a free spot now
  IF v_event_record.current_player_count < v_event_record.max_players THEN
    -- Find the first person on the waitlist
    SELECT * INTO v_next_waitlist
    FROM event_rsvps
    WHERE event_id = OLD.event_id
      AND status = 'waitlisted'
    ORDER BY waitlist_position ASC
    LIMIT 1;

    IF FOUND THEN
      -- Promote them to 'going'
      UPDATE event_rsvps
      SET
        status = 'going',
        waitlist_position = NULL,
        updated_at = NOW()
      WHERE id = v_next_waitlist.id;

      -- Shift remaining waitlist positions down
      UPDATE event_rsvps
      SET waitlist_position = waitlist_position - 1
      WHERE event_id = OLD.event_id
        AND status = 'waitlisted'
        AND waitlist_position > v_next_waitlist.waitlist_position;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_promote_waitlist
  AFTER UPDATE OR DELETE ON event_rsvps
  FOR EACH ROW EXECUTE FUNCTION promote_waitlist_user();

-- ============================================================
-- PREVENT RSVP WHEN EVENT IS FULL
-- Sets status to 'waitlisted' instead of 'going' when at capacity
-- ============================================================

CREATE OR REPLACE FUNCTION handle_rsvp_capacity()
RETURNS TRIGGER AS $$
DECLARE
  v_event events%ROWTYPE;
  v_going_count INTEGER;
  v_max_waitlist_pos INTEGER;
BEGIN
  -- Only applies when status = 'going'
  IF NEW.status <> 'going' THEN
    RETURN NEW;
  END IF;

  SELECT * INTO v_event FROM events WHERE id = NEW.event_id;

  -- No cap, allow directly
  IF v_event.max_players IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COUNT(*) INTO v_going_count
  FROM event_rsvps
  WHERE event_id = NEW.event_id AND status = 'going';

  IF v_going_count >= v_event.max_players THEN
    IF NOT v_event.waitlist_enabled THEN
      RAISE EXCEPTION 'Event is full and waitlist is not enabled';
    END IF;

    SELECT COALESCE(MAX(waitlist_position), 0) INTO v_max_waitlist_pos
    FROM event_rsvps
    WHERE event_id = NEW.event_id AND status = 'waitlisted';

    NEW.status := 'waitlisted';
    NEW.waitlist_position := v_max_waitlist_pos + 1;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rsvp_capacity_check
  BEFORE INSERT ON event_rsvps
  FOR EACH ROW EXECUTE FUNCTION handle_rsvp_capacity();

-- ============================================================
-- UTILITY FUNCTION: Find nearby users
-- ============================================================

CREATE OR REPLACE FUNCTION find_nearby_users(
  p_user_id UUID,
  p_radius_km NUMERIC DEFAULT 50
)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  distance_km NUMERIC
) AS $$
DECLARE
  v_user_location GEOGRAPHY;
BEGIN
  SELECT location INTO v_user_location FROM profiles WHERE id = p_user_id;

  IF v_user_location IS NULL THEN
    RAISE EXCEPTION 'User location not set';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    ROUND((ST_Distance(p.location, v_user_location) / 1000)::NUMERIC, 2) AS distance_km
  FROM profiles p
  WHERE
    p.id <> p_user_id
    AND p.is_active = true
    AND p.is_public = true
    AND p.location IS NOT NULL
    AND p.location_public = true
    AND ST_DWithin(p.location, v_user_location, p_radius_km * 1000)
    AND NOT EXISTS (
      SELECT 1 FROM user_blocks
      WHERE (blocker_id = p_user_id AND blocked_id = p.id)
        OR (blocker_id = p.id AND blocked_id = p_user_id)
    )
  ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- UTILITY FUNCTION: Find nearby events
-- ============================================================

CREATE OR REPLACE FUNCTION find_nearby_events(
  p_user_id UUID,
  p_radius_km NUMERIC DEFAULT 50,
  p_from_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
  event_id UUID,
  title TEXT,
  starts_at TIMESTAMPTZ,
  game_name TEXT,
  organizer_display_name TEXT,
  current_players INTEGER,
  max_players INTEGER,
  distance_km NUMERIC
) AS $$
DECLARE
  v_user_location GEOGRAPHY;
BEGIN
  SELECT location INTO v_user_location FROM profiles WHERE id = p_user_id;

  RETURN QUERY
  SELECT
    e.id,
    e.title,
    e.starts_at,
    COALESCE(g.name, e.game_name) AS game_name,
    p.display_name AS organizer_display_name,
    e.current_player_count,
    e.max_players,
    CASE
      WHEN v_user_location IS NOT NULL AND e.location IS NOT NULL
      THEN ROUND((ST_Distance(e.location, v_user_location) / 1000)::NUMERIC, 2)
      ELSE NULL
    END AS distance_km
  FROM events e
  JOIN profiles p ON p.id = e.organizer_id
  LEFT JOIN games g ON g.id = e.game_id
  WHERE
    e.status = 'published'
    AND e.starts_at >= p_from_date
    AND e.is_online = false
    AND e.location IS NOT NULL
    AND (
      v_user_location IS NULL
      OR ST_DWithin(e.location, v_user_location, p_radius_km * 1000)
    )
  ORDER BY
    CASE WHEN v_user_location IS NOT NULL THEN ST_Distance(e.location, v_user_location) ELSE 0 END ASC,
    e.starts_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- UTILITY FUNCTION: Get user stats summary
-- ============================================================

CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'games_owned',      (SELECT COUNT(*) FROM user_game_collection WHERE user_id = p_user_id AND status = 'owned'),
    'games_wishlist',   (SELECT COUNT(*) FROM user_game_collection WHERE user_id = p_user_id AND status = 'wishlist'),
    'events_hosted',    (SELECT COUNT(*) FROM events WHERE organizer_id = p_user_id AND status = 'completed'),
    'events_attended',  (SELECT COUNT(*) FROM event_rsvps WHERE user_id = p_user_id AND status = 'going'),
    'groups_joined',    (SELECT COUNT(*) FROM group_members WHERE user_id = p_user_id),
    'avg_rating',       (SELECT ROUND(AVG(rating)::NUMERIC, 2) FROM user_reviews WHERE reviewee_id = p_user_id),
    'review_count',     (SELECT COUNT(*) FROM user_reviews WHERE reviewee_id = p_user_id),
    'connections',      (SELECT COUNT(*) FROM user_connections
                         WHERE (requester_id = p_user_id OR addressee_id = p_user_id) AND is_accepted = true)
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
