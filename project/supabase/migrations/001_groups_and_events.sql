-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- For location-based queries

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE group_role AS ENUM ('organizer', 'co_organizer', 'member');
CREATE TYPE group_visibility AS ENUM ('public', 'private', 'invite_only');
CREATE TYPE membership_status AS ENUM ('pending', 'active', 'banned', 'left');
CREATE TYPE event_status AS ENUM ('draft', 'published', 'cancelled', 'completed');
CREATE TYPE rsvp_status AS ENUM ('attending', 'maybe', 'declined', 'waitlisted');
CREATE TYPE experience_level AS ENUM ('beginner', 'intermediate', 'advanced', 'all_levels');
CREATE TYPE location_type AS ENUM ('home', 'game_store', 'library', 'community_center', 'online', 'other');

-- ============================================================
-- GROUPS TABLE
-- ============================================================

CREATE TABLE groups (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name              VARCHAR(100) NOT NULL,
  slug              VARCHAR(120) UNIQUE NOT NULL,
  description       TEXT,
  short_description VARCHAR(255),

  -- Location
  city              VARCHAR(100),
  state_province    VARCHAR(100),
  country           VARCHAR(100),
  latitude          DECIMAL(10, 8),
  longitude         DECIMAL(11, 8),
  location_point    GEOMETRY(POINT, 4326),  -- PostGIS point for geo queries

  -- Group settings
  visibility        group_visibility NOT NULL DEFAULT 'public',
  max_members       INTEGER CHECK (max_members > 0),
  is_active         BOOLEAN NOT NULL DEFAULT true,

  -- Gaming focus
  primary_game_types  TEXT[],   -- e.g. ['strategy', 'rpg', 'card_games']
  featured_games      TEXT[],   -- BGG game IDs or names
  experience_levels   experience_level[] DEFAULT ARRAY['all_levels']::experience_level[],

  -- Media
  banner_image_url    VARCHAR(500),
  avatar_image_url    VARCHAR(500),

  -- Social / metadata
  website_url         VARCHAR(500),
  discord_url         VARCHAR(500),
  rules               TEXT,       -- Group rules / code of conduct
  tags                TEXT[],

  -- Ownership
  created_by          UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,

  -- Timestamps
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for groups
CREATE INDEX idx_groups_slug          ON groups(slug);
CREATE INDEX idx_groups_created_by    ON groups(created_by);
CREATE INDEX idx_groups_visibility    ON groups(visibility);
CREATE INDEX idx_groups_is_active     ON groups(is_active);
CREATE INDEX idx_groups_location      ON groups USING GIST(location_point);
CREATE INDEX idx_groups_game_types    ON groups USING GIN(primary_game_types);
CREATE INDEX idx_groups_tags          ON groups USING GIN(tags);
CREATE INDEX idx_groups_featured_games ON groups USING GIN(featured_games);

-- ============================================================
-- GROUP MEMBERSHIPS TABLE
-- ============================================================

CREATE TABLE group_memberships (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id    UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role        group_role NOT NULL DEFAULT 'member',
  status      membership_status NOT NULL DEFAULT 'active',

  -- Metadata
  invited_by  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  joined_at   TIMESTAMPTZ,
  left_at     TIMESTAMPTZ,
  ban_reason  TEXT,
  notes       TEXT,   -- Organizer notes about this member

  -- Timestamps
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Each user can only have one membership record per group
  UNIQUE(group_id, user_id)
);

-- Indexes for group_memberships
CREATE INDEX idx_group_memberships_group_id   ON group_memberships(group_id);
CREATE INDEX idx_group_memberships_user_id    ON group_memberships(user_id);
CREATE INDEX idx_group_memberships_role       ON group_memberships(role);
CREATE INDEX idx_group_memberships_status     ON group_memberships(status);
CREATE INDEX idx_group_memberships_active     ON group_memberships(group_id, user_id) WHERE status = 'active';

-- ============================================================
-- EVENTS TABLE
-- ============================================================

CREATE TABLE events (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id              UUID REFERENCES groups(id) ON DELETE SET NULL,  -- NULL = standalone event
  created_by            UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,

  -- Basic info
  title                 VARCHAR(200) NOT NULL,
  slug                  VARCHAR(220) UNIQUE NOT NULL,
  description           TEXT,
  status                event_status NOT NULL DEFAULT 'draft',

  -- Scheduling
  starts_at             TIMESTAMPTZ NOT NULL,
  ends_at               TIMESTAMPTZ,
  timezone              VARCHAR(100) NOT NULL DEFAULT 'UTC',
  is_recurring          BOOLEAN NOT NULL DEFAULT false,
  recurrence_rule       TEXT,   -- RRULE string (RFC 5545) for recurring events
  parent_event_id       UUID REFERENCES events(id) ON DELETE SET NULL,  -- For recurring instances

  -- Location
  location_type         location_type NOT NULL DEFAULT 'other',
  location_name         VARCHAR(200),
  address_line1         VARCHAR(255),
  address_line2         VARCHAR(255),
  city                  VARCHAR(100),
  state_province        VARCHAR(100),
  country               VARCHAR(100),
  postal_code           VARCHAR(20),
  latitude              DECIMAL(10, 8),
  longitude             DECIMAL(11, 8),
  location_point        GEOMETRY(POINT, 4326),
  location_notes        TEXT,   -- e.g. "Ring buzzer 2B", "Meet at the board game section"
  online_url            VARCHAR(500),  -- For virtual events (Tabletop Simulator, etc.)

  -- Capacity
  min_players           INTEGER CHECK (min_players > 0),
  max_players           INTEGER CHECK (max_players > 0),
  current_attendees     INTEGER NOT NULL DEFAULT 0,  -- Denormalized count
  waitlist_enabled      BOOLEAN NOT NULL DEFAULT false,
  waitlist_max          INTEGER CHECK (waitlist_max > 0),

  -- Game details
  game_title            VARCHAR(200),
  bgg_game_id           VARCHAR(50),    -- BoardGameGeek ID
  game_description      TEXT,
  experience_level      experience_level NOT NULL DEFAULT 'all_levels',
  is_teach_session      BOOLEAN NOT NULL DEFAULT false,  -- Teaching new players

  -- Requirements & details
  cost_per_person       DECIMAL(10, 2) CHECK (cost_per_person >= 0),
  cost_currency         CHAR(3) DEFAULT 'USD',
  supplies_needed       TEXT[],   -- e.g. ['dice', 'pencils', 'character sheets']
  rules_summary         TEXT,     -- Quick rules overview
  what_to_bring         TEXT,
  age_requirement       INTEGER CHECK (age_requirement >= 0),

  -- Media
  cover_image_url       VARCHAR(500),
  image_urls            TEXT[],

  -- Visibility
  is_public             BOOLEAN NOT NULL DEFAULT true,
  requires_approval     BOOLEAN NOT NULL DEFAULT false,  -- Organizer must approve RSVPs

  -- Timestamps
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  published_at          TIMESTAMPTZ,
  cancelled_at          TIMESTAMPTZ,
  cancellation_reason   TEXT,

  -- Constraints
  CHECK (ends_at IS NULL OR ends_at > starts_at),
  CHECK (max_players IS NULL OR min_players IS NULL OR max_players >= min_players)
);

-- Indexes for events
CREATE INDEX idx_events_group_id         ON events(group_id);
CREATE INDEX idx_events_created_by       ON events(created_by);
CREATE INDEX idx_events_status           ON events(status);
CREATE INDEX idx_events_starts_at        ON events(starts_at);
CREATE INDEX idx_events_ends_at          ON events(ends_at);
CREATE INDEX idx_events_slug             ON events(slug);
CREATE INDEX idx_events_location         ON events USING GIST(location_point);
CREATE INDEX idx_events_is_public        ON events(is_public);
CREATE INDEX idx_events_bgg_game_id      ON events(bgg_game_id);
CREATE INDEX idx_events_experience_level ON events(experience_level);
CREATE INDEX idx_events_parent_event     ON events(parent_event_id);
-- Composite index for common query: upcoming public events
CREATE INDEX idx_events_upcoming_public  ON events(starts_at, status) WHERE is_public = true AND status = 'published';

-- ============================================================
-- EVENT RSVPs TABLE
-- ============================================================

CREATE TABLE event_rsvps (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id          UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status            rsvp_status NOT NULL DEFAULT 'attending',

  -- Additional info
  guests_count      INTEGER NOT NULL DEFAULT 0 CHECK (guests_count >= 0),  -- Extra people bringing
  note              TEXT,   -- Note from attendee to organizer
  waitlist_position INTEGER CHECK (waitlist_position > 0),  -- Position in waitlist if waitlisted

  -- Approval flow (when event requires_approval = true)
  approved_by       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_at       TIMESTAMPTZ,
  rejection_reason  TEXT,

  -- Check-in
  checked_in_at     TIMESTAMPTZ,
  checked_in_by     UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Timestamps
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One RSVP per user per event
  UNIQUE(event_id, user_id)
);

-- Indexes for event_rsvps
CREATE INDEX idx_event_rsvps_event_id         ON event_rsvps(event_id);
CREATE INDEX idx_event_rsvps_user_id          ON event_rsvps(user_id);
CREATE INDEX idx_event_rsvps_status           ON event_rsvps(status);
CREATE INDEX idx_event_rsvps_waitlist_pos     ON event_rsvps(event_id, waitlist_position) WHERE status = 'waitlisted';
-- Composite index for attendee count queries
CREATE INDEX idx_event_rsvps_attending        ON event_rsvps(event_id) WHERE status = 'attending';

-- ============================================================
-- GROUP DISCUSSION THREADS
-- ============================================================

CREATE TABLE group_threads (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id    UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  created_by  UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  event_id    UUID REFERENCES events(id) ON DELETE CASCADE,  -- Optional: thread tied to event

  title       VARCHAR(300) NOT NULL,
  body        TEXT NOT NULL,
  is_pinned   BOOLEAN NOT NULL DEFAULT false,
  is_locked   BOOLEAN NOT NULL DEFAULT false,  -- Prevents new replies
  reply_count INTEGER NOT NULL DEFAULT 0,      -- Denormalized

  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_reply_at TIMESTAMPTZ
);

CREATE INDEX idx_group_threads_group_id   ON group_threads(group_id);
CREATE INDEX idx_group_threads_event_id   ON group_threads(event_id);
CREATE INDEX idx_group_threads_created_by ON group_threads(created_by);
CREATE INDEX idx_group_threads_pinned     ON group_threads(group_id, is_pinned, last_reply_at DESC);

-- ============================================================
-- GROUP THREAD REPLIES
-- ============================================================

CREATE TABLE group_thread_replies (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  thread_id   UUID NOT NULL REFERENCES group_threads(id) ON DELETE CASCADE,
  created_by  UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  parent_reply_id UUID REFERENCES group_thread_replies(id) ON DELETE SET NULL,  -- Nested replies

  body        TEXT NOT NULL,
  is_deleted  BOOLEAN NOT NULL DEFAULT false,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_thread_replies_thread_id  ON group_thread_replies(thread_id);
CREATE INDEX idx_thread_replies_created_by ON group_thread_replies(created_by);
CREATE INDEX idx_thread_replies_parent     ON group_thread_replies(parent_reply_id);

-- ============================================================
-- RECURRING EVENT TEMPLATES
-- ============================================================

CREATE TABLE event_templates (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id            UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  created_by          UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,

  name                VARCHAR(200) NOT NULL,
  description         TEXT,

  -- Template defaults (mirrors events table structure)
  default_title       VARCHAR(200) NOT NULL,
  default_description TEXT,
  default_duration_minutes INTEGER CHECK (default_duration_minutes > 0),
  default_location_type    location_type,
  default_location_name    VARCHAR(200),
  default_address_line1    VARCHAR(255),
  default_city             VARCHAR(100),
  default_state_province   VARCHAR(100),
  default_country          VARCHAR(100),
  default_max_players      INTEGER CHECK (default_max_players > 0),
  default_game_title       VARCHAR(200),
  default_bgg_game_id      VARCHAR(50),
  default_experience_level experience_level DEFAULT 'all_levels',
  default_cost_per_person  DECIMAL(10, 2),
  default_what_to_bring    TEXT,
  default_supplies_needed  TEXT[],

  -- Recurrence settings
  recurrence_rule     TEXT NOT NULL,  -- RRULE string
  is_active           BOOLEAN NOT NULL DEFAULT true,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_event_templates_group_id   ON event_templates(group_id);
CREATE INDEX idx_event_templates_created_by ON event_templates(created_by);
CREATE INDEX idx_event_templates_active     ON event_templates(group_id) WHERE is_active = true;

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER trigger_groups_updated_at
  BEFORE UPDATE ON groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_group_memberships_updated_at
  BEFORE UPDATE ON group_memberships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_event_rsvps_updated_at
  BEFORE UPDATE ON event_rsvps
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_group_threads_updated_at
  BEFORE UPDATE ON group_threads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_group_thread_replies_updated_at
  BEFORE UPDATE ON group_thread_replies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_event_templates_updated_at
  BEFORE UPDATE ON event_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- --------------------------------------------------------
-- Function: Sync location_point from lat/lng on groups
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION sync_groups_location_point()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location_point = ST_SetSRID(
      ST_MakePoint(NEW.longitude, NEW.latitude),
      4326
    );
  ELSE
    NEW.location_point = NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_groups_sync_location
  BEFORE INSERT OR UPDATE OF latitude, longitude ON groups
  FOR EACH ROW EXECUTE FUNCTION sync_groups_location_point();

-- --------------------------------------------------------
-- Function: Sync location_point from lat/lng on events
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION sync_events_location_point()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location_point = ST_SetSRID(
      ST_MakePoint(NEW.longitude, NEW.latitude),
      4326
    );
  ELSE
    NEW.location_point = NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_events_sync_location
  BEFORE INSERT OR UPDATE OF latitude, longitude ON events
  FOR EACH ROW EXECUTE FUNCTION sync_events_location_point();

-- --------------------------------------------------------
-- Function: Maintain current_attendees count on events
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION update_event_attendee_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'attending' THEN
      UPDATE events SET current_attendees = current_attendees + 1
      WHERE id = NEW.event_id;
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    -- Attendee confirmed
    IF OLD.status != 'attending' AND NEW.status = 'attending' THEN
      UPDATE events SET current_attendees = current_attendees + 1
      WHERE id = NEW.event_id;
    END IF;
    -- Attendee unconfirmed
    IF OLD.status = 'attending' AND NEW.status != 'attending' THEN
      UPDATE events SET current_attendees = GREATEST(0, current_attendees - 1)
      WHERE id = NEW.event_id;
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.status = 'attending' THEN
      UPDATE events SET current_attendees = GREATEST(0, current_attendees - 1)
      WHERE id = OLD.event_id;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_rsvp_attendee_count
  AFTER INSERT OR UPDATE OF status OR DELETE ON event_rsvps
  FOR EACH ROW EXECUTE FUNCTION update_event_attendee_count();

-- --------------------------------------------------------
-- Function: Auto-assign waitlist position
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION assign_waitlist_position()
RETURNS TRIGGER AS $$
DECLARE
  next_position INTEGER;
BEGIN
  IF NEW.status = 'waitlisted' AND (OLD IS NULL OR OLD.status != 'waitlisted') THEN
    SELECT COALESCE(MAX(waitlist_position), 0) + 1
    INTO next_position
    FROM event_rsvps
    WHERE event_id = NEW.event_id AND status = 'waitlisted';

    NEW.waitlist_position = next_position;

  ELSIF NEW.status != 'waitlisted' AND OLD IS NOT NULL AND OLD.status = 'waitlisted' THEN
    -- Removing from waitlist: shift others up
    UPDATE event_rsvps
    SET waitlist_position = waitlist_position - 1
    WHERE event_id = NEW.event_id
      AND status = 'waitlisted'
      AND waitlist_position > OLD.waitlist_position;

    NEW.waitlist_position = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_rsvp_waitlist_position
  BEFORE INSERT OR UPDATE OF status ON event_rsvps
  FOR EACH ROW EXECUTE FUNCTION assign_waitlist_position();

-- --------------------------------------------------------
-- Function: Maintain reply_count on group_threads
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION update_thread_reply_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NOT NEW.is_deleted THEN
    UPDATE group_threads
    SET reply_count = reply_count + 1,
        last_reply_at = NOW()
    WHERE id = NEW.thread_id;

  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.is_deleted = false AND NEW.is_deleted = true THEN
      UPDATE group_threads
      SET reply_count = GREATEST(0, reply_count - 1)
      WHERE id = NEW.thread_id;
    ELSIF OLD.is_deleted = true AND NEW.is_deleted = false THEN
      UPDATE group_threads
      SET reply_count = reply_count + 1,
          last_reply_at = NOW()
      WHERE id = NEW.thread_id;
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    IF NOT OLD.is_deleted THEN
      UPDATE group_threads
      SET reply_count = GREATEST(0, reply_count - 1)
      WHERE id = OLD.thread_id;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_thread_reply_count
  AFTER INSERT OR UPDATE OF is_deleted OR DELETE ON group_thread_replies
  FOR EACH ROW EXECUTE FUNCTION update_thread_reply_count();

-- --------------------------------------------------------
-- Function: Auto-set membership joined_at
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION set_membership_dates()
RETURNS TRIGGER AS $$
BEGIN
  -- Set joined_at when status becomes active
  IF NEW.status = 'active' AND (OLD IS NULL OR OLD.status != 'active') THEN
    NEW.joined_at = COALESCE(NEW.joined_at, NOW());
  END IF;

  -- Set left_at when member leaves or is banned
  IF NEW.status IN ('left', 'banned') AND (OLD IS NULL OR OLD.status NOT IN ('left', 'banned')) THEN
    NEW.left_at = COALESCE(NEW.left_at, NOW());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_membership_dates
  BEFORE INSERT OR UPDATE OF status ON group_memberships
  FOR EACH ROW EXECUTE FUNCTION set_membership_dates();

-- --------------------------------------------------------
-- Function: Set published_at when event is published
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION set_event_published_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'published' AND (OLD IS NULL OR OLD.status != 'published') THEN
    NEW.published_at = COALESCE(NEW.published_at, NOW());
  END IF;

  IF NEW.status = 'cancelled' AND (OLD IS NULL OR OLD.status != 'cancelled') THEN
    NEW.cancelled_at = COALESCE(NEW.cancelled_at, NOW());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_event_publish_dates
  BEFORE INSERT OR UPDATE OF status ON events
  FOR EACH ROW EXECUTE FUNCTION set_event_published_at();

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_rsvps ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_thread_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_templates ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------
-- Groups RLS
-- --------------------------------------------------------

-- Public groups are readable by everyone (including anonymous)
CREATE POLICY "groups_select_public"
  ON groups FOR SELECT
  USING (visibility = 'public' AND is_active = true);

-- Private groups are visible to members
CREATE POLICY "groups_select_member"
  ON groups FOR SELECT
  USING (
    visibility IN ('private', 'invite_only')
    AND id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );

-- Organizers can view their inactive groups too
CREATE POLICY "groups_select_organizer"
  ON groups FOR SELECT
  USING (
    created_by = auth.uid()
    OR id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND role IN ('organizer', 'co_organizer') AND status = 'active'
    )
  );

-- Any authenticated user can create a group
CREATE POLICY "groups_insert_authenticated"
  ON groups FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND created_by = auth.uid());

-- Organizers and co-organizers can update group
CREATE POLICY "groups_update_organizer"
  ON groups FOR UPDATE
  USING (
    created_by = auth.uid()
    OR id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND role IN ('organizer', 'co_organizer') AND status = 'active'
    )
  );

-- Only creator can delete a group
CREATE POLICY "groups_delete_creator"
  ON groups FOR DELETE
  USING (created_by = auth.uid());

-- --------------------------------------------------------
-- Group Memberships RLS
-- --------------------------------------------------------

-- Members can see all memberships within their groups
CREATE POLICY "memberships_select_member"
  ON group_memberships FOR SELECT
  USING (
    user_id = auth.uid()
    OR group_id IN (
      SELECT group_id FROM group_memberships gm2
      WHERE gm2.user_id = auth.uid() AND gm2.status = 'active'
    )
  );

-- Authenticated users can request to join (insert their own record)
CREATE POLICY "memberships_insert_self"
  ON group_memberships FOR INSERT
  WITH CHECK (user_id = auth.uid() AND role = 'member');

-- Organizers can insert memberships (invites)
CREATE POLICY "memberships_insert_organizer"
  ON group_memberships FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND role IN ('organizer', 'co_organizer') AND status = 'active'
    )
  );

-- Users can update their own membership (e.g., leave group)
CREATE POLICY "memberships_update_self"
  ON group_memberships FOR UPDATE
  USING (user_id = auth.uid());

-- Organizers can update any membership in their group
CREATE POLICY "memberships_update_organizer"
  ON group_memberships FOR UPDATE
  USING (
    group_id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND role IN ('organizer', 'co_organizer') AND status = 'active'
    )
  );

-- --------------------------------------------------------
-- Events RLS
-- --------------------------------------------------------

-- Public published events are viewable by all
CREATE POLICY "events_select_public"
  ON events FOR SELECT
  USING (is_public = true AND status = 'published');

-- Group members can see group events
CREATE POLICY "events_select_group_member"
  ON events FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );

-- Event creators can see their own events
CREATE POLICY "events_select_creator"
  ON events FOR SELECT
  USING (created_by = auth.uid());

-- Authenticated users can create events
CREATE POLICY "events_insert_authenticated"
  ON events FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND created_by = auth.uid());

-- Event creators and group organizers can update events
CREATE POLICY "events_update_creator_or_organizer"
  ON events FOR UPDATE
  USING (
    created_by = auth.uid()
    OR (
      group_id IS NOT NULL
      AND group_id IN (
        SELECT group_id FROM group_memberships
        WHERE user_id = auth.uid() AND role IN ('organizer', 'co_organizer') AND status = 'active'
      )
    )
  );

-- Only creator can delete event
CREATE POLICY "events_delete_creator"
  ON events FOR DELETE
  USING (created_by = auth.uid());

-- --------------------------------------------------------
-- Event RSVPs RLS
-- --------------------------------------------------------

-- Users can see RSVPs for events they can see
CREATE POLICY "rsvps_select_event_attendee"
  ON event_rsvps FOR SELECT
  USING (
    user_id = auth.uid()
    OR event_id IN (
      SELECT id FROM events
      WHERE is_public = true AND status = 'published'
    )
    OR event_id IN (
      SELECT e.id FROM events e
      INNER JOIN group_memberships gm ON gm.group_id = e.group_id
      WHERE gm.user_id = auth.uid() AND gm.status = 'active'
    )
  );

-- Authenticated users can create their own RSVPs
CREATE POLICY "rsvps_insert_self"
  ON event_rsvps FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());

-- Users can update their own RSVPs; organizers can update any in their event
CREATE POLICY "rsvps_update_self"
  ON event_rsvps FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "rsvps_update_organizer"
  ON event_rsvps FOR UPDATE
  USING (
    event_id IN (
      SELECT e.id FROM events e
      WHERE e.created_by = auth.uid()
    )
    OR event_id IN (
      SELECT e.id FROM events e
      INNER JOIN group_memberships gm ON gm.group_id = e.group_id
      WHERE gm.user_id = auth.uid() AND gm.role IN ('organizer', 'co_organizer') AND gm.status = 'active'
    )
  );

-- Users can delete their own RSVPs
CREATE POLICY "rsvps_delete_self"
  ON event_rsvps FOR DELETE
  USING (user_id = auth.uid());

-- --------------------------------------------------------
-- Group Threads RLS
-- --------------------------------------------------------

-- Group members can read threads
CREATE POLICY "threads_select_member"
  ON group_threads FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );

-- Group members can create threads
CREATE POLICY "threads_insert_member"
  ON group_threads FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND created_by = auth.uid()
    AND group_id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );

-- Authors and organizers can update threads
CREATE POLICY "threads_update_author_or_organizer"
  ON group_threads FOR UPDATE
  USING (
    created_by = auth.uid()
    OR group_id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND role IN ('organizer', 'co_organizer') AND status = 'active'
    )
  );

-- --------------------------------------------------------
-- Group Thread Replies RLS
-- --------------------------------------------------------

-- Group members can read replies
CREATE POLICY "replies_select_member"
  ON group_thread_replies FOR SELECT
  USING (
    thread_id IN (
      SELECT t.id FROM group_threads t
      INNER JOIN group_memberships gm ON gm.group_id = t.group_id
      WHERE gm.user_id = auth.uid() AND gm.status = 'active'
    )
  );

-- Group members can post replies to non-locked threads
CREATE POLICY "replies_insert_member"
  ON group_thread_replies FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND created_by = auth.uid()
    AND thread_id IN (
      SELECT t.id FROM group_threads t
      INNER JOIN group_memberships gm ON gm.group_id = t.group_id
      WHERE gm.user_id = auth.uid() AND gm.status = 'active' AND t.is_locked = false
    )
  );

-- Authors can update/soft-delete their replies
CREATE POLICY "replies_update_author"
  ON group_thread_replies FOR UPDATE
  USING (created_by = auth.uid());

-- --------------------------------------------------------
-- Event Templates RLS
-- --------------------------------------------------------

-- Group members can view templates
CREATE POLICY "templates_select_member"
  ON event_templates FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );

-- Organizers can manage templates
CREATE POLICY "templates_insert_organizer"
  ON event_templates FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND created_by = auth.uid()
    AND group_id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND role IN ('organizer', 'co_organizer') AND status = 'active'
    )
  );

CREATE POLICY "templates_update_organizer"
  ON event_templates FOR UPDATE
  USING (
    group_id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND role IN ('organizer', 'co_organizer') AND status = 'active'
    )
  );

CREATE POLICY "templates_delete_organizer"
  ON event_templates FOR DELETE
  USING (
    group_id IN (
      SELECT group_id FROM group_memberships
      WHERE user_id = auth.uid() AND role IN ('organizer', 'co_organizer') AND status = 'active'
    )
  );

-- ============================================================
-- HELPER VIEWS
-- ============================================================

-- View: Groups with member counts and upcoming event counts
CREATE VIEW groups_summary AS
SELECT
  g.*,
  COUNT(DISTINCT gm.user_id) FILTER (WHERE gm.status = 'active')           AS member_count,
  COUNT(DISTINCT gm.user_id) FILTER (WHERE gm.role = 'organizer' AND gm.status = 'active') AS organizer_count,
  COUNT(DISTINCT e.id) FILTER (WHERE e.status = 'published' AND e.starts_at > NOW()) AS upcoming_event_count,
  COUNT(DISTINCT e.id) FILTER (WHERE e.status = 'completed')                AS completed_event_count
FROM groups g
LEFT JOIN group_memberships gm ON gm.group_id = g.id
LEFT JOIN events e ON e.group_id = g.id
GROUP BY g.id;

-- View: Upcoming public events with RSVP summary
CREATE VIEW upcoming_events_summary AS
SELECT
  e.*,
  g.name AS group_name,
  g.slug AS group_slug,
  COUNT(r.id) FILTER (WHERE r.status = 'attending') AS confirmed_attendees,
  COUNT(r.id) FILTER (WHERE r.status = 'maybe')     AS maybe_attendees,
  COUNT(r.id) FILTER (WHERE r.status = 'waitlisted') AS waitlisted_count,
  CASE
    WHEN e.max_players IS NULL THEN false
    ELSE e.current_attendees >= e.max_players
  END AS is_full
FROM events e
LEFT JOIN groups g ON g.id = e.group_id
LEFT JOIN event_rsvps r ON r.event_id = e.id
WHERE e.status = 'published'
  AND e.starts_at > NOW()
GROUP BY e.id, g.name, g.slug;

-- View: User's group memberships with group details
CREATE VIEW user_group_memberships AS
SELECT
  gm.user_id,
  gm.role,
  gm.status,
  gm.joined_at,
  g.id AS group_id,
  g.name AS group_name,
  g.slug AS group_slug,
  g.avatar_image_url,
  g.visibility,
  g.primary_game_types
FROM group_memberships gm
INNER JOIN groups g ON g.id = gm.group_id
WHERE g.is_active = true;

-- ============================================================
-- SEED DATA (Example data for development)
-- ============================================================

-- Note: In production, groups/events are user-created.
-- This is just illustrative structure for testing.

COMMENT ON TABLE groups IS 'Gaming groups that players can create and join';
COMMENT ON TABLE group_memberships IS 'Tracks user membership, roles, and status within groups';
COMMENT ON TABLE events IS 'Game sessions and events, optionally associated with a group';
COMMENT ON TABLE event_rsvps IS 'Player RSVPs for events, including waitlist management';
COMMENT ON TABLE group_threads IS 'Discussion threads within group forums';
COMMENT ON TABLE group_thread_replies IS 'Replies to group discussion threads';
COMMENT ON TABLE event_templates IS 'Recurring event templates for consistent session scheduling';

COMMENT ON COLUMN events.recurrence_rule IS 'RFC 5545 RRULE string defining recurrence pattern, e.g. FREQ=WEEKLY;BYDAY=SA';
COMMENT ON COLUMN events.bgg_game_id IS 'BoardGameGeek game ID for API integration';
COMMENT ON COLUMN event_rsvps.guests_count IS 'Number of additional guests the user is bringing (not counted in max_players separately)';
COMMENT ON COLUMN group_memberships.status IS 'pending=awaiting approval, active=full member, banned=removed, left=voluntarily left';
