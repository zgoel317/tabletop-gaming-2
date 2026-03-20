-- ============================================================
-- Migration: 00002_groups_and_events.sql
-- Description: Gaming groups, events/sessions, and RSVP system
-- ============================================================

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE group_member_role AS ENUM (
  'owner',
  'organizer',
  'member'
);

CREATE TYPE group_visibility AS ENUM (
  'public',   -- Anyone can find and join
  'private',  -- Invite only
  'unlisted'  -- Joinable by link but not searchable
);

CREATE TYPE event_status AS ENUM (
  'draft',
  'published',
  'cancelled',
  'completed'
);

CREATE TYPE rsvp_status AS ENUM (
  'attending',
  'maybe',
  'declined',
  'waitlist'
);

CREATE TYPE location_type AS ENUM (
  'home',
  'game_store',
  'library',
  'community_center',
  'online',
  'other'
);

-- ============================================================
-- GROUPS TABLE
-- ============================================================

CREATE TABLE groups (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name              TEXT NOT NULL,
  description       TEXT,
  avatar_url        TEXT,
  banner_url        TEXT,

  -- Created by
  owner_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,

  visibility        group_visibility DEFAULT 'public',

  -- Location (city-level, not precise)
  city              TEXT,
  state_province    TEXT,
  country           TEXT DEFAULT 'US',
  location          GEOGRAPHY(POINT, 4326),

  -- Gaming focus
  primary_genre     game_genre,
  experience_level  experience_level,

  -- Limits
  max_members       INTEGER CHECK (max_members > 0),

  -- Stats (denormalized)
  member_count      INTEGER DEFAULT 1 CHECK (member_count >= 0),
  event_count       INTEGER DEFAULT 0 CHECK (event_count >= 0),

  -- Join settings
  requires_approval BOOLEAN DEFAULT FALSE,

  is_active         BOOLEAN DEFAULT TRUE,

  created_at        TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at        TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT group_name_length CHECK (char_length(name) >= 2 AND char_length(name) <= 100),
  CONSTRAINT group_desc_length CHECK (char_length(description) <= 2000)
);

COMMENT ON TABLE groups IS 'Gaming groups that users can create and join';

-- ============================================================
-- GROUP MEMBERS TABLE
-- ============================================================

CREATE TABLE group_members (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id    UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role        group_member_role DEFAULT 'member',
  -- Pending approval for private groups
  is_approved BOOLEAN DEFAULT TRUE,

  joined_at   TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE (group_id, profile_id)
);

COMMENT ON TABLE group_members IS 'Membership records for groups';

-- ============================================================
-- GROUP GAMES TABLE
-- Games that a group typically plays
-- ============================================================

CREATE TABLE group_games (
  group_id    UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  game_id     UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  added_by    UUID REFERENCES profiles(id) ON DELETE SET NULL,
  added_at    TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  PRIMARY KEY (group_id, game_id)
);

COMMENT ON TABLE group_games IS 'Games associated with a gaming group';

-- ============================================================
-- EVENTS / SESSIONS TABLE
-- ============================================================

CREATE TABLE events (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Creator of the event
  host_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  -- Optional: event belongs to a group
  group_id          UUID REFERENCES groups(id) ON DELETE SET NULL,
  -- Optional: the main game being played
  game_id           UUID REFERENCES games(id) ON DELETE SET NULL,

  title             TEXT NOT NULL,
  description       TEXT,

  -- Scheduling
  starts_at         TIMESTAMPTZ NOT NULL,
  ends_at           TIMESTAMPTZ,
  -- Timezone of the event
  timezone          TEXT DEFAULT 'UTC',

  -- Location
  location_type     location_type DEFAULT 'other',
  location_name     TEXT,     -- Venue name or "John's House"
  address_line1     TEXT,
  address_line2     TEXT,
  city              TEXT,
  state_province    TEXT,
  country           TEXT DEFAULT 'US',
  postal_code       TEXT,
  location          GEOGRAPHY(POINT, 4326),
  -- Hide exact address until RSVP confirmed
  location_private  BOOLEAN DEFAULT FALSE,
  -- Online meeting link (e.g., Tabletop Simulator, Roll20)
  online_url        TEXT,

  -- Player requirements
  min_players       SMALLINT DEFAULT 2 CHECK (min_players >= 1),
  max_players       SMALLINT CHECK (max_players >= 1),
  experience_level  experience_level,

  -- Requirements text (e.g., "Bring dice", "Know the rules")
  requirements      TEXT,

  status            event_status DEFAULT 'published',

  -- Stats (denormalized)
  attendee_count    INTEGER DEFAULT 0 CHECK (attendee_count >= 0),
  waitlist_count    INTEGER DEFAULT 0 CHECK (waitlist_count >= 0),

  -- Recurring session support
  is_recurring      BOOLEAN DEFAULT FALSE,
  recurrence_rule   TEXT, -- iCal RRULE format

  created_at        TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at        TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT event_title_length CHECK (char_length(title) >= 2 AND char_length(title) <= 200),
  CONSTRAINT event_players_order CHECK (min_players <= COALESCE(max_players, min_players)),
  CONSTRAINT event_time_order CHECK (ends_at IS NULL OR ends_at > starts_at)
);

COMMENT ON TABLE events IS 'Game sessions/events that users can create and RSVP to';
COMMENT ON COLUMN events.recurrence_rule IS 'iCal RRULE string for recurring events';
COMMENT ON COLUMN events.location_private IS 'Hide exact address until RSVP is confirmed';

-- ============================================================
-- EVENT RSVPs TABLE
-- ============================================================

CREATE TABLE event_rsvps (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id    UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status      rsvp_status NOT NULL DEFAULT 'attending',
  -- Position in waitlist (NULL if not on waitlist)
  waitlist_position INTEGER CHECK (waitlist_position > 0),
  -- Guest count (attending + guests)
  guests      SMALLINT DEFAULT 0 CHECK (guests >= 0),
  notes       TEXT,

  responded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at   TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE (event_id, profile_id)
);

COMMENT ON TABLE event_rsvps IS 'RSVP records for events including waitlist tracking';

-- ============================================================
-- EVENT GAMES TABLE
-- Additional games that might be played at an event
-- ============================================================

CREATE TABLE event_games (
  event_id    UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  game_id     UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  is_primary  BOOLEAN DEFAULT FALSE,
  added_by    UUID REFERENCES profiles(id) ON DELETE SET NULL,

  PRIMARY KEY (event_id, game_id)
);

COMMENT ON TABLE event_games IS 'Games planned for a specific event';

-- ============================================================
-- LFG POSTS (Looking For Group)
-- ============================================================

CREATE TYPE lfg_status AS ENUM (
  'open',
  'filled',
  'closed',
  'expired'
);

CREATE TABLE lfg_posts (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id           UUID REFERENCES games(id) ON DELETE SET NULL,

  title             TEXT NOT NULL,
  description       TEXT,

  -- When they want to play
  desired_date      TIMESTAMPTZ,
  flexible_date     BOOLEAN DEFAULT TRUE,

  -- Location preference
  location_type     location_type DEFAULT 'other',
  city              TEXT,
  state_province    TEXT,
  country           TEXT DEFAULT 'US',
  location          GEOGRAPHY(POINT, 4326),

  -- Player requirements
  players_needed    SMALLINT DEFAULT 1 CHECK (players_needed >= 1),
  players_joined    SMALLINT DEFAULT 0 CHECK (players_joined >= 0),
  experience_level  experience_level,

  status            lfg_status DEFAULT 'open',
  -- Auto-expire after this date
  expires_at        TIMESTAMPTZ,

  created_at        TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at        TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT lfg_title_length CHECK (char_length(title) >= 3 AND char_length(title) <= 200)
);

COMMENT ON TABLE lfg_posts IS 'Looking For Group posts for players seeking others to play with';

-- ============================================================
-- Add session_id FK to user_ratings (references events)
-- ============================================================

ALTER TABLE user_ratings
  ADD CONSTRAINT fk_ratings_session
  FOREIGN KEY (session_id) REFERENCES events(id) ON DELETE SET NULL;

-- ============================================================
-- TRIGGERS: member_count and event_count maintenance
-- ============================================================

-- Update group member_count on membership change
CREATE OR REPLACE FUNCTION update_group_member_count()
RETURNS TRIGGER AS $$
DECLARE
  v_group_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_group_id := OLD.group_id;
  ELSE
    v_group_id := NEW.group_id;
  END IF;

  UPDATE groups
  SET member_count = (
    SELECT COUNT(*) FROM group_members
    WHERE group_id = v_group_id AND is_approved = TRUE
  )
  WHERE id = v_group_id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_group_member_count
  AFTER INSERT OR UPDATE OR DELETE ON group_members
  FOR EACH ROW EXECUTE FUNCTION update_group_member_count();

-- Update event attendee_count and waitlist_count on RSVP change
CREATE OR REPLACE FUNCTION update_event_rsvp_counts()
RETURNS TRIGGER AS $$
DECLARE
  v_event_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_event_id := OLD.event_id;
  ELSE
    v_event_id := NEW.event_id;
  END IF;

  UPDATE events
  SET
    attendee_count = (
      SELECT COUNT(*) FROM event_rsvps
      WHERE event_id = v_event_id AND status = 'attending'
    ),
    waitlist_count = (
      SELECT COUNT(*) FROM event_rsvps
      WHERE event_id = v_event_id AND status = 'waitlist'
    )
  WHERE id = v_event_id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_event_rsvp_counts
  AFTER INSERT OR UPDATE OR DELETE ON event_rsvps
  FOR EACH ROW EXECUTE FUNCTION update_event_rsvp_counts();

-- Auto-update updated_at
CREATE TRIGGER trg_groups_updated_at
  BEFORE UPDATE ON groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_group_members_updated_at
  BEFORE UPDATE ON group_members
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

-- ============================================================
-- INDEXES
-- ============================================================

-- Groups
CREATE INDEX idx_groups_owner_id      ON groups USING btree (owner_id);
CREATE INDEX idx_groups_location      ON groups USING gist (location);
CREATE INDEX idx_groups_visibility    ON groups USING btree (visibility) WHERE is_active = TRUE;
CREATE INDEX idx_groups_genre         ON groups USING btree (primary_genre);
CREATE INDEX idx_groups_name_trgm     ON groups USING gin (name gin_trgm_ops);
CREATE INDEX idx_groups_name_fts      ON groups USING gin (
  to_tsvector('english', name || ' ' || coalesce(description, ''))
);

-- Group members
CREATE INDEX idx_group_members_group  ON group_members USING btree (group_id);
CREATE INDEX idx_group_members_user   ON group_members USING btree (profile_id);
CREATE INDEX idx_group_members_role   ON group_members USING btree (role);

-- Events
CREATE INDEX idx_events_host_id       ON events USING btree (host_id);
CREATE INDEX idx_events_group_id      ON events USING btree (group_id);
CREATE INDEX idx_events_game_id       ON events USING btree (game_id);
CREATE INDEX idx_events_starts_at     ON events USING btree (starts_at);
CREATE INDEX idx_events_status        ON events USING btree (status);
CREATE INDEX idx_events_location      ON events USING gist (location);
CREATE INDEX idx_events_upcoming      ON events USING btree (starts_at)
  WHERE status = 'published' AND starts_at > NOW();

-- RSVPs
CREATE INDEX idx_rsvps_event_id       ON event_rsvps USING btree (event_id);
CREATE INDEX idx_rsvps_profile_id     ON event_rsvps USING btree (profile_id);
CREATE INDEX idx_rsvps_status         ON event_rsvps USING btree (status);

-- LFG posts
CREATE INDEX idx_lfg_author_id        ON lfg_posts USING btree (author_id);
CREATE INDEX idx_lfg_status           ON lfg_posts USING btree (status);
CREATE INDEX idx_lfg_location         ON lfg_posts USING gist (location);
CREATE INDEX idx_lfg_game_id          ON lfg_posts USING btree (game_id);
CREATE INDEX idx_lfg_expires_at       ON lfg_posts USING btree (expires_at) WHERE status = 'open';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE groups         ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members  ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_games    ENABLE ROW LEVEL SECURITY;
ALTER TABLE events         ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_rsvps    ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_games    ENABLE ROW LEVEL SECURITY;
ALTER TABLE lfg_posts      ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------
-- groups policies
-- ----------------------------------------------------------------

CREATE POLICY "Public groups are viewable by everyone"
  ON groups FOR SELECT
  USING (visibility != 'private' OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = groups.id
        AND group_members.profile_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create groups"
  ON groups FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Group owners and organizers can update groups"
  ON groups FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = groups.id
        AND group_members.profile_id = auth.uid()
        AND group_members.role IN ('owner', 'organizer')
    )
  );

CREATE POLICY "Only group owners can delete groups"
  ON groups FOR DELETE
  USING (owner_id = auth.uid());

-- ----------------------------------------------------------------
-- group_members policies
-- ----------------------------------------------------------------

CREATE POLICY "Group members are viewable by group members"
  ON group_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = group_members.group_id
        AND gm.profile_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM groups g
      WHERE g.id = group_members.group_id
        AND g.visibility = 'public'
    )
  );

CREATE POLICY "Users can join groups"
  ON group_members FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Organizers can update member roles"
  ON group_members FOR UPDATE
  USING (
    auth.uid() = profile_id
    OR EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = group_members.group_id
        AND gm.profile_id = auth.uid()
        AND gm.role IN ('owner', 'organizer')
    )
  );

CREATE POLICY "Members can leave or be removed by organizers"
  ON group_members FOR DELETE
  USING (
    auth.uid() = profile_id
    OR EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = group_members.group_id
        AND gm.profile_id = auth.uid()
        AND gm.role IN ('owner', 'organizer')
    )
  );

-- ----------------------------------------------------------------
-- group_games policies
-- ----------------------------------------------------------------

CREATE POLICY "Group games viewable by everyone"
  ON group_games FOR SELECT
  USING (TRUE);

CREATE POLICY "Group members can add games"
  ON group_games FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_games.group_id
        AND group_members.profile_id = auth.uid()
        AND group_members.is_approved = TRUE
    )
  );

CREATE POLICY "Group organizers can remove games"
  ON group_games FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_games.group_id
        AND group_members.profile_id = auth.uid()
        AND group_members.role IN ('owner', 'organizer')
    )
  );

-- ----------------------------------------------------------------
-- events policies
-- ----------------------------------------------------------------

CREATE POLICY "Published events are viewable by everyone"
  ON events FOR SELECT
  USING (
    status = 'published'
    OR host_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = events.group_id
        AND group_members.profile_id = auth.uid()
        AND group_members.role IN ('owner', 'organizer')
    )
  );

CREATE POLICY "Authenticated users can create events"
  ON events FOR INSERT
  WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Hosts can update their events"
  ON events FOR UPDATE
  USING (
    auth.uid() = host_id
    OR EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = events.group_id
        AND group_members.profile_id = auth.uid()
        AND group_members.role IN ('owner', 'organizer')
    )
  );

CREATE POLICY "Hosts can delete their events"
  ON events FOR DELETE
  USING (auth.uid() = host_id);

-- ----------------------------------------------------------------
-- event_rsvps policies
-- ----------------------------------------------------------------

CREATE POLICY "RSVPs viewable by event participants"
  ON event_rsvps FOR SELECT
  USING (
    auth.uid() = profile_id
    OR EXISTS (
      SELECT 1 FROM events
      WHERE events.id = event_rsvps.event_id
        AND events.host_id = auth.uid()
    )
  );

CREATE POLICY "Users can RSVP to events"
  ON event_rsvps FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update their own RSVP"
  ON event_rsvps FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can cancel their own RSVP"
  ON event_rsvps FOR DELETE
  USING (
    auth.uid() = profile_id
    OR EXISTS (
      SELECT 1 FROM events
      WHERE events.id = event_rsvps.event_id
        AND events.host_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------
-- event_games policies
-- ----------------------------------------------------------------

CREATE POLICY "Event games viewable by everyone"
  ON event_games FOR SELECT
  USING (TRUE);

CREATE POLICY "Event hosts can manage event games"
  ON event_games FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.id = event_games.event_id
        AND events.host_id = auth.uid()
    )
  );

CREATE POLICY "Event hosts can remove event games"
  ON event_games FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.id = event_games.event_id
        AND events.host_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------
-- lfg_posts policies
-- ----------------------------------------------------------------

CREATE POLICY "Open LFG posts viewable by everyone"
  ON lfg_posts FOR SELECT
  USING (status IN ('open', 'filled'));

CREATE POLICY "Authenticated users can create LFG posts"
  ON lfg_posts FOR INSERT
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update their LFG posts"
  ON lfg_posts FOR UPDATE
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can delete their LFG posts"
  ON lfg_posts FOR DELETE
  USING (auth.uid() = author_id);
