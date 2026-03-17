-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE experience_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert');
CREATE TYPE game_genre AS ENUM (
  'strategy',
  'worker_placement',
  'deck_building',
  'cooperative',
  'competitive',
  'party',
  'roleplaying',
  'wargame',
  'abstract',
  'family',
  'euro',
  'ameritrash',
  'trivia',
  'dexterity',
  'legacy'
);
CREATE TYPE availability_day AS ENUM (
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday'
);
CREATE TYPE group_role AS ENUM ('owner', 'organizer', 'member');
CREATE TYPE event_status AS ENUM ('draft', 'published', 'cancelled', 'completed');
CREATE TYPE rsvp_status AS ENUM ('going', 'maybe', 'not_going', 'waitlisted');
CREATE TYPE message_type AS ENUM ('direct', 'group', 'event');
CREATE TYPE collection_status AS ENUM ('owned', 'wishlist', 'previously_owned', 'for_trade');
CREATE TYPE notification_type AS ENUM (
  'event_invite',
  'event_reminder',
  'message_received',
  'group_invite',
  'rsvp_update',
  'review_received',
  'session_cancelled',
  'waitlist_promoted'
);

-- ============================================================
-- PROFILES TABLE
-- Extends Supabase auth.users with app-specific profile data
-- ============================================================

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  website TEXT,

  -- Location fields
  city TEXT,
  state_province TEXT,
  country TEXT DEFAULT 'US',
  postal_code TEXT,
  -- PostGIS point for geo queries (longitude, latitude)
  location GEOGRAPHY(POINT, 4326),
  location_public BOOLEAN DEFAULT true,
  search_radius_km INTEGER DEFAULT 50,

  -- Profile metadata
  is_public BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  onboarding_completed BOOLEAN DEFAULT false,
  last_seen_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Constraints
  CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
  CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_-]+$'),
  CONSTRAINT display_name_length CHECK (char_length(display_name) >= 1 AND char_length(display_name) <= 100),
  CONSTRAINT bio_length CHECK (char_length(bio) <= 500)
);

COMMENT ON TABLE profiles IS 'User profile data extending Supabase auth.users';
COMMENT ON COLUMN profiles.location IS 'PostGIS geography point (longitude, latitude) for proximity searches';
COMMENT ON COLUMN profiles.search_radius_km IS 'Default radius in km for local player/event discovery';

-- ============================================================
-- GAMING PREFERENCES TABLE
-- Stores gaming preferences per user
-- ============================================================

CREATE TABLE gaming_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  experience_level experience_level DEFAULT 'beginner' NOT NULL,
  preferred_player_count_min INTEGER DEFAULT 2,
  preferred_player_count_max INTEGER DEFAULT 6,
  preferred_session_length_hours NUMERIC(4, 1),

  -- Availability represented as time slots per day
  available_days availability_day[],
  available_time_start TIME,
  available_time_end TIME,

  -- Free-text notes about preferences/playstyle
  playstyle_notes TEXT,
  looking_for_group BOOLEAN DEFAULT false,
  willing_to_teach BOOLEAN DEFAULT true,
  willing_to_travel BOOLEAN DEFAULT true,

  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT unique_user_preferences UNIQUE (user_id),
  CONSTRAINT player_count_valid CHECK (
    preferred_player_count_min >= 1
    AND preferred_player_count_max >= preferred_player_count_min
    AND preferred_player_count_max <= 20
  ),
  CONSTRAINT session_length_valid CHECK (
    preferred_session_length_hours IS NULL
    OR (preferred_session_length_hours >= 0.5 AND preferred_session_length_hours <= 24)
  )
);

COMMENT ON TABLE gaming_preferences IS 'User gaming preferences and availability settings';

-- ============================================================
-- USER PREFERRED GENRES (junction table)
-- ============================================================

CREATE TABLE user_preferred_genres (
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  genre game_genre NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  PRIMARY KEY (user_id, genre)
);

COMMENT ON TABLE user_preferred_genres IS 'Preferred game genres per user (many-to-many)';

-- ============================================================
-- GAMES TABLE
-- Local cache / reference for board games (syncs with BGG API)
-- ============================================================

CREATE TABLE games (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bgg_id INTEGER UNIQUE,                -- BoardGameGeek game ID
  name TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  image_url TEXT,
  min_players INTEGER,
  max_players INTEGER,
  min_playtime_minutes INTEGER,
  max_playtime_minutes INTEGER,
  min_age INTEGER,
  complexity_rating NUMERIC(3, 2),      -- BGG weight 1.0-5.0
  average_rating NUMERIC(3, 2),         -- BGG average rating 1.0-10.0
  year_published INTEGER,
  publisher TEXT,
  designer TEXT,
  genres game_genre[],
  bgg_rank INTEGER,
  bgg_last_synced_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT players_valid CHECK (
    min_players IS NULL OR max_players IS NULL
    OR min_players <= max_players
  ),
  CONSTRAINT playtime_valid CHECK (
    min_playtime_minutes IS NULL OR max_playtime_minutes IS NULL
    OR min_playtime_minutes <= max_playtime_minutes
  )
);

COMMENT ON TABLE games IS 'Board game catalogue, partially synced from BoardGameGeek API';
COMMENT ON COLUMN games.bgg_id IS 'BoardGameGeek unique identifier for API sync';

CREATE INDEX idx_games_bgg_id ON games(bgg_id);
CREATE INDEX idx_games_name_trgm ON games USING GIN (name gin_trgm_ops);

-- ============================================================
-- USER GAME COLLECTION TABLE
-- ============================================================

CREATE TABLE user_game_collection (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  status collection_status NOT NULL DEFAULT 'owned',
  notes TEXT,
  condition TEXT,
  willing_to_lend BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT unique_user_game_status UNIQUE (user_id, game_id, status)
);

COMMENT ON TABLE user_game_collection IS 'Games owned, wishlisted, or available for trade by a user';

CREATE INDEX idx_user_game_collection_user ON user_game_collection(user_id);
CREATE INDEX idx_user_game_collection_game ON user_game_collection(game_id);
CREATE INDEX idx_user_game_collection_status ON user_game_collection(status);

-- ============================================================
-- USER RATINGS / REVIEWS TABLE
-- ============================================================

CREATE TABLE user_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reviewer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reviewee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL,
  review_text TEXT,
  session_id UUID,                      -- optional: linked game session (FK added later)
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT no_self_review CHECK (reviewer_id <> reviewee_id),
  CONSTRAINT rating_range CHECK (rating >= 1 AND rating <= 5),
  CONSTRAINT unique_review_per_session UNIQUE (reviewer_id, reviewee_id, session_id)
);

COMMENT ON TABLE user_reviews IS 'Player-to-player ratings and reviews after game sessions';

CREATE INDEX idx_user_reviews_reviewee ON user_reviews(reviewee_id);
CREATE INDEX idx_user_reviews_reviewer ON user_reviews(reviewer_id);

-- ============================================================
-- GROUPS TABLE
-- ============================================================

CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  avatar_url TEXT,
  banner_url TEXT,

  -- Location
  city TEXT,
  state_province TEXT,
  country TEXT DEFAULT 'US',
  location GEOGRAPHY(POINT, 4326),

  -- Settings
  is_public BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  max_members INTEGER,
  requires_approval BOOLEAN DEFAULT false,
  member_count INTEGER DEFAULT 0,

  -- Metadata
  created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT name_length CHECK (char_length(name) >= 2 AND char_length(name) <= 100),
  CONSTRAINT slug_format CHECK (slug ~ '^[a-z0-9-]+$'),
  CONSTRAINT max_members_valid CHECK (max_members IS NULL OR max_members >= 2)
);

COMMENT ON TABLE groups IS 'Gaming groups/clubs that users can join';

CREATE INDEX idx_groups_slug ON groups(slug);
CREATE INDEX idx_groups_created_by ON groups(created_by);
CREATE INDEX idx_groups_location ON groups USING GIST (location);
CREATE INDEX idx_groups_name_trgm ON groups USING GIN (name gin_trgm_ops);

-- ============================================================
-- GROUP MEMBERS TABLE
-- ============================================================

CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role group_role NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  invited_by UUID REFERENCES profiles(id) ON DELETE SET NULL,

  CONSTRAINT unique_group_member UNIQUE (group_id, user_id)
);

COMMENT ON TABLE group_members IS 'Users who belong to a gaming group with their roles';

CREATE INDEX idx_group_members_group ON group_members(group_id);
CREATE INDEX idx_group_members_user ON group_members(user_id);
CREATE INDEX idx_group_members_role ON group_members(role);

-- ============================================================
-- EVENTS (GAME SESSIONS) TABLE
-- ============================================================

CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  status event_status DEFAULT 'draft' NOT NULL,

  -- Organizer / Group
  organizer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  group_id UUID REFERENCES groups(id) ON DELETE SET NULL,

  -- Game being played
  game_id UUID REFERENCES games(id) ON DELETE SET NULL,
  game_name TEXT,                        -- fallback if game not in DB

  -- Scheduling
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  timezone TEXT DEFAULT 'UTC',
  is_recurring BOOLEAN DEFAULT false,
  recurrence_rule TEXT,                  -- iCal RRULE string

  -- Capacity
  min_players INTEGER DEFAULT 2,
  max_players INTEGER,
  current_player_count INTEGER DEFAULT 0,
  waitlist_enabled BOOLEAN DEFAULT true,
  waitlist_count INTEGER DEFAULT 0,

  -- Location
  venue_name TEXT,
  venue_address TEXT,
  city TEXT,
  state_province TEXT,
  country TEXT DEFAULT 'US',
  location GEOGRAPHY(POINT, 4326),
  is_online BOOLEAN DEFAULT false,
  online_platform TEXT,
  meeting_url TEXT,

  -- Requirements
  experience_required experience_level,
  cost_per_player NUMERIC(10, 2) DEFAULT 0,
  supplies_needed TEXT,
  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT title_length CHECK (char_length(title) >= 2 AND char_length(title) <= 200),
  CONSTRAINT players_valid CHECK (
    min_players >= 1
    AND (max_players IS NULL OR max_players >= min_players)
  ),
  CONSTRAINT date_valid CHECK (ends_at IS NULL OR ends_at > starts_at),
  CONSTRAINT cost_valid CHECK (cost_per_player >= 0)
);

COMMENT ON TABLE events IS 'Game session events that users can create and attend';

CREATE INDEX idx_events_organizer ON events(organizer_id);
CREATE INDEX idx_events_group ON events(group_id);
CREATE INDEX idx_events_game ON events(game_id);
CREATE INDEX idx_events_starts_at ON events(starts_at);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_location ON events USING GIST (location);

-- ============================================================
-- EVENT RSVPs TABLE
-- ============================================================

CREATE TABLE event_rsvps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status rsvp_status NOT NULL DEFAULT 'going',
  waitlist_position INTEGER,
  notes TEXT,
  responded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT unique_event_rsvp UNIQUE (event_id, user_id),
  CONSTRAINT waitlist_position_valid CHECK (
    (status = 'waitlisted' AND waitlist_position IS NOT NULL AND waitlist_position > 0)
    OR (status <> 'waitlisted' AND waitlist_position IS NULL)
  )
);

COMMENT ON TABLE event_rsvps IS 'User RSVPs to game session events, including waitlist management';

CREATE INDEX idx_event_rsvps_event ON event_rsvps(event_id);
CREATE INDEX idx_event_rsvps_user ON event_rsvps(user_id);
CREATE INDEX idx_event_rsvps_status ON event_rsvps(status);

-- Add deferred FK from user_reviews.session_id to events
ALTER TABLE user_reviews
  ADD CONSTRAINT fk_review_session
  FOREIGN KEY (session_id) REFERENCES events(id) ON DELETE SET NULL;

-- ============================================================
-- LFG POSTS (Looking for Group)
-- ============================================================

CREATE TABLE lfg_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  game_id UUID REFERENCES games(id) ON DELETE SET NULL,
  game_name TEXT,
  experience_required experience_level,
  players_needed INTEGER DEFAULT 1,
  preferred_days availability_day[],
  city TEXT,
  state_province TEXT,
  country TEXT DEFAULT 'US',
  location GEOGRAPHY(POINT, 4326),
  is_online BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT title_length CHECK (char_length(title) >= 2 AND char_length(title) <= 200),
  CONSTRAINT players_needed_valid CHECK (players_needed >= 1 AND players_needed <= 20)
);

COMMENT ON TABLE lfg_posts IS 'Looking for Group posts where users seek players for games';

CREATE INDEX idx_lfg_posts_user ON lfg_posts(user_id);
CREATE INDEX idx_lfg_posts_game ON lfg_posts(game_id);
CREATE INDEX idx_lfg_posts_location ON lfg_posts USING GIST (location);
CREATE INDEX idx_lfg_posts_active ON lfg_posts(is_active);

-- ============================================================
-- CONVERSATIONS TABLE
-- ============================================================

CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type message_type NOT NULL DEFAULT 'direct',
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  title TEXT,
  created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT type_context_valid CHECK (
    (type = 'direct' AND group_id IS NULL AND event_id IS NULL)
    OR (type = 'group' AND group_id IS NOT NULL AND event_id IS NULL)
    OR (type = 'event' AND event_id IS NOT NULL AND group_id IS NULL)
  )
);

COMMENT ON TABLE conversations IS 'Messaging conversations (direct, group, or event-linked)';

CREATE INDEX idx_conversations_group ON conversations(group_id);
CREATE INDEX idx_conversations_event ON conversations(event_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC);

-- ============================================================
-- CONVERSATION PARTICIPANTS TABLE
-- ============================================================

CREATE TABLE conversation_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  last_read_at TIMESTAMPTZ,
  is_muted BOOLEAN DEFAULT false,
  joined_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT unique_participant UNIQUE (conversation_id, user_id)
);

COMMENT ON TABLE conversation_participants IS 'Users who are part of a conversation';

CREATE INDEX idx_conv_participants_conv ON conversation_participants(conversation_id);
CREATE INDEX idx_conv_participants_user ON conversation_participants(user_id);

-- ============================================================
-- MESSAGES TABLE
-- ============================================================

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  content TEXT NOT NULL,
  is_edited BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT content_not_empty CHECK (char_length(trim(content)) > 0),
  CONSTRAINT content_length CHECK (char_length(content) <= 10000)
);

COMMENT ON TABLE messages IS 'Individual messages within conversations';

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);

-- ============================================================
-- NOTIFICATIONS TABLE
-- ============================================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE notifications IS 'In-app notifications for users';

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;

-- ============================================================
-- USER BLOCKS TABLE
-- ============================================================

CREATE TABLE user_blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT no_self_block CHECK (blocker_id <> blocked_id),
  CONSTRAINT unique_block UNIQUE (blocker_id, blocked_id)
);

COMMENT ON TABLE user_blocks IS 'User block relationships to prevent unwanted contact';

CREATE INDEX idx_user_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX idx_user_blocks_blocked ON user_blocks(blocked_id);

-- ============================================================
-- USER CONNECTIONS (Friends / Network)
-- ============================================================

CREATE TABLE user_connections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_accepted BOOLEAN DEFAULT false,
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT no_self_connection CHECK (requester_id <> addressee_id),
  CONSTRAINT unique_connection UNIQUE (requester_id, addressee_id)
);

COMMENT ON TABLE user_connections IS 'Friend/connection requests between users';

CREATE INDEX idx_connections_requester ON user_connections(requester_id);
CREATE INDEX idx_connections_addressee ON user_connections(addressee_id);
CREATE INDEX idx_connections_accepted ON user_connections(is_accepted);
