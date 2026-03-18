-- ============================================================
-- ADDITIONAL PERFORMANCE INDEXES
-- ============================================================

-- Profiles: frequent lookups by location for nearby user discovery
CREATE INDEX IF NOT EXISTS idx_profiles_location_gist
  ON profiles USING GIST (location)
  WHERE location IS NOT NULL AND is_public = true AND is_active = true;

-- Profiles: full-text search
CREATE INDEX IF NOT EXISTS idx_profiles_display_name_trgm
  ON profiles USING GIN (display_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_profiles_username_trgm
  ON profiles USING GIN (username gin_trgm_ops);

-- Profiles: looking for group filter
CREATE INDEX IF NOT EXISTS idx_gaming_prefs_lfg
  ON gaming_preferences (user_id)
  WHERE looking_for_group = true;

-- Events: location + date composite for nearby upcoming events
CREATE INDEX IF NOT EXISTS idx_events_location_date
  ON events USING GIST (location)
  WHERE status = 'published' AND location IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_events_published_upcoming
  ON events (starts_at ASC)
  WHERE status = 'published';

-- Events: group_id + starts_at for group event feeds
CREATE INDEX IF NOT EXISTS idx_events_group_starts_at
  ON events (group_id, starts_at ASC)
  WHERE status = 'published' AND group_id IS NOT NULL;

-- Messages: pagination friendly index
CREATE INDEX IF NOT EXISTS idx_messages_conv_created_desc
  ON messages (conversation_id, created_at DESC)
  WHERE is_deleted = false;

-- Notifications: unread count queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON notifications (user_id, created_at DESC)
  WHERE is_read = false;

-- User reviews: calculate average rating efficiently
CREATE INDEX IF NOT EXISTS idx_reviews_reviewee_public
  ON user_reviews (reviewee_id, rating)
  WHERE is_public = true;

-- User connections: mutual connections lookup
CREATE INDEX IF NOT EXISTS idx_connections_both_accepted
  ON user_connections (requester_id, addressee_id)
  WHERE is_accepted = true;

-- LFG posts: location-based discovery
CREATE INDEX IF NOT EXISTS idx_lfg_location_active
  ON lfg_posts USING GIST (location)
  WHERE is_active = true AND location IS NOT NULL;

-- ============================================================
-- PARTIAL INDEXES FOR COMMON FILTER PATTERNS
-- ============================================================

-- Active groups with location
CREATE INDEX IF NOT EXISTS idx_groups_active_location
  ON groups USING GIST (location)
  WHERE is_active = true AND is_public = true AND location IS NOT NULL;

-- Event RSVPs: going users for a specific event (for capacity checks)
CREATE INDEX IF NOT EXISTS idx_rsvps_event_going
  ON event_rsvps (event_id, user_id)
  WHERE status = 'going';

-- Waitlist ordering
CREATE INDEX IF NOT EXISTS idx_rsvps_waitlist_position
  ON event_rsvps (event_id, waitlist_position ASC)
  WHERE status = 'waitlisted';

-- ============================================================
-- COMPOSITE INDEXES FOR JOIN PERFORMANCE
-- ============================================================

-- Group members: user's groups with role
CREATE INDEX IF NOT EXISTS idx_group_members_user_role
  ON group_members (user_id, role);

-- Collection: user's lendable games
CREATE INDEX IF NOT EXISTS idx_collection_user_lendable
  ON user_game_collection (user_id, game_id)
  WHERE willing_to_lend = true AND status = 'owned';

-- ============================================================
-- TABLE STATISTICS CONFIGURATION
-- Help the query planner with skewed data distributions
-- ============================================================

ALTER TABLE events ALTER COLUMN status SET STATISTICS 200;
ALTER TABLE event_rsvps ALTER COLUMN status SET STATISTICS 200;
ALTER TABLE profiles ALTER COLUMN is_active SET STATISTICS 100;
ALTER TABLE profiles ALTER COLUMN is_public SET STATISTICS 100;
