-- ============================================================
-- Migration: 00001_initial_schema.sql
-- Description: Initial database schema for Tabletop Gaming
--              Networking App - users, profiles, gaming
--              preferences, and authentication setup
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";  -- for location/geo queries
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- for fuzzy text search

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE experience_level AS ENUM (
  'beginner',
  'casual',
  'intermediate',
  'experienced',
  'expert'
);

CREATE TYPE game_genre AS ENUM (
  'strategy',
  'worker_placement',
  'deck_building',
  'cooperative',
  'social_deduction',
  'roll_and_write',
  'engine_building',
  'area_control',
  'dungeon_crawl',
  'legacy',
  'party',
  'abstract',
  'wargame',
  'eurogame',
  'ameritrash',
  'rpg',
  'trivia',
  'push_your_luck',
  'auction_bidding',
  'tile_placement'
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

CREATE TYPE availability_time AS ENUM (
  'morning',    -- 6am - 12pm
  'afternoon',  -- 12pm - 5pm
  'evening',    -- 5pm - 9pm
  'night'       -- 9pm - 12am
);

CREATE TYPE user_role AS ENUM (
  'user',
  'moderator',
  'admin'
);

CREATE TYPE collection_status AS ENUM (
  'owned',
  'wishlist',
  'previously_owned',
  'want_to_play'
);

CREATE TYPE friendship_status AS ENUM (
  'pending',
  'accepted',
  'blocked'
);

-- ============================================================
-- PROFILES TABLE
-- Core user profile data, extends Supabase auth.users
-- ============================================================

CREATE TABLE profiles (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username            TEXT UNIQUE NOT NULL,
  display_name        TEXT,
  bio                 TEXT,
  avatar_url          TEXT,
  website_url         TEXT,

  -- Location fields
  city                TEXT,
  state_province      TEXT,
  country             TEXT DEFAULT 'US',
  postal_code         TEXT,
  -- PostGIS geography point for geo queries (longitude, latitude)
  location            GEOGRAPHY(POINT, 4326),
  -- Max distance willing to travel (in km)
  search_radius_km    INTEGER DEFAULT 50 CHECK (search_radius_km > 0 AND search_radius_km <= 500),
  -- Whether to show exact location or just city/region
  location_public     BOOLEAN DEFAULT FALSE,

  -- Experience & preferences
  experience_level    experience_level DEFAULT 'casual',
  -- Preferred player count range
  min_players_pref    SMALLINT DEFAULT 2 CHECK (min_players_pref >= 1),
  max_players_pref    SMALLINT DEFAULT 6 CHECK (max_players_pref >= 1),
  -- Average session length preference in minutes
  session_length_pref INTEGER CHECK (session_length_pref > 0),

  -- Profile stats (denormalized for performance)
  games_played_count  INTEGER DEFAULT 0 CHECK (games_played_count >= 0),
  rating_average      NUMERIC(3, 2) DEFAULT 0 CHECK (rating_average >= 0 AND rating_average <= 5),
  rating_count        INTEGER DEFAULT 0 CHECK (rating_count >= 0),

  -- Account status
  role                user_role DEFAULT 'user',
  is_active           BOOLEAN DEFAULT TRUE,
  is_verified         BOOLEAN DEFAULT FALSE,
  onboarding_complete BOOLEAN DEFAULT FALSE,

  -- Notification preferences
  notify_messages     BOOLEAN DEFAULT TRUE,
  notify_event_invite BOOLEAN DEFAULT TRUE,
  notify_event_remind BOOLEAN DEFAULT TRUE,
  notify_group_invite BOOLEAN DEFAULT TRUE,
  notify_new_follower BOOLEAN DEFAULT TRUE,

  -- Timestamps
  created_at          TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at          TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  last_seen_at        TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
  CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_-]+$'),
  CONSTRAINT display_name_length CHECK (char_length(display_name) <= 100),
  CONSTRAINT bio_length CHECK (char_length(bio) <= 1000),
  CONSTRAINT players_pref_order CHECK (min_players_pref <= max_players_pref)
);

COMMENT ON TABLE profiles IS 'User profile data extending Supabase auth.users';
COMMENT ON COLUMN profiles.id IS 'References auth.users - same UUID';
COMMENT ON COLUMN profiles.location IS 'PostGIS geography point (longitude, latitude)';
COMMENT ON COLUMN profiles.search_radius_km IS 'Max distance user is willing to travel to games';

-- ============================================================
-- GAMING PREFERENCES TABLE
-- Preferred game genres per user
-- ============================================================

CREATE TABLE profile_preferred_genres (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  genre       game_genre NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE (profile_id, genre)
);

COMMENT ON TABLE profile_preferred_genres IS 'Game genres a user enjoys playing';

-- ============================================================
-- AVAILABILITY TABLE
-- When users are generally available to play
-- ============================================================

CREATE TABLE profile_availability (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  day_of_week availability_day NOT NULL,
  time_of_day availability_time NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE (profile_id, day_of_week, time_of_day)
);

COMMENT ON TABLE profile_availability IS 'General weekly availability windows for playing games';

-- ============================================================
-- GAMES TABLE
-- Master list of board games (seeded from BoardGameGeek API)
-- ============================================================

CREATE TABLE games (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- BoardGameGeek ID for API integration
  bgg_id          INTEGER UNIQUE,
  name            TEXT NOT NULL,
  description     TEXT,
  thumbnail_url   TEXT,
  image_url       TEXT,

  -- Game metadata
  min_players     SMALLINT CHECK (min_players >= 1),
  max_players     SMALLINT CHECK (max_players >= 1),
  -- Play time in minutes
  min_play_time   INTEGER CHECK (min_play_time > 0),
  max_play_time   INTEGER CHECK (max_play_time > 0),
  -- Recommended minimum age
  min_age         SMALLINT CHECK (min_age >= 0),
  -- BGG complexity rating 1-5
  complexity      NUMERIC(3, 2) CHECK (complexity >= 1 AND complexity <= 5),
  -- BGG average rating
  bgg_rating      NUMERIC(3, 2) CHECK (bgg_rating >= 0 AND bgg_rating <= 10),
  bgg_rank        INTEGER CHECK (bgg_rank > 0),

  year_published  SMALLINT,
  publisher       TEXT,
  designer        TEXT,

  -- Cached timestamp for BGG data freshness
  bgg_synced_at   TIMESTAMPTZ,

  created_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT players_order CHECK (min_players <= max_players),
  CONSTRAINT play_time_order CHECK (min_play_time <= max_play_time)
);

COMMENT ON TABLE games IS 'Master board game catalog, synced with BoardGameGeek API';
COMMENT ON COLUMN games.bgg_id IS 'BoardGameGeek game ID for API integration';
COMMENT ON COLUMN games.complexity IS 'BGG weight/complexity rating on a 1-5 scale';

-- ============================================================
-- GAME GENRES JUNCTION TABLE
-- Many-to-many: games <-> genres
-- ============================================================

CREATE TABLE game_genres (
  game_id     UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  genre       game_genre NOT NULL,

  PRIMARY KEY (game_id, genre)
);

COMMENT ON TABLE game_genres IS 'Game genre classifications (many-to-many)';

-- ============================================================
-- USER GAME COLLECTION TABLE
-- Games users own, want, or have played
-- ============================================================

CREATE TABLE user_game_collection (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id     UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  status      collection_status NOT NULL DEFAULT 'owned',
  -- Personal notes about the game
  notes       TEXT,
  -- User's personal rating for this game
  user_rating SMALLINT CHECK (user_rating >= 1 AND user_rating <= 10),
  play_count  INTEGER DEFAULT 0 CHECK (play_count >= 0),

  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE (profile_id, game_id, status)
);

COMMENT ON TABLE user_game_collection IS 'Games in a user''s collection with ownership status';

-- ============================================================
-- FAVORITE GAMES TABLE
-- Games explicitly marked as favorites (for quick matching)
-- ============================================================

CREATE TABLE profile_favorite_games (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id     UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  -- Display order for favorites list
  sort_order  SMALLINT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE (profile_id, game_id)
);

COMMENT ON TABLE profile_favorite_games IS 'Games a user has explicitly marked as favorites';

-- ============================================================
-- USER RATINGS TABLE
-- Players rating each other after game sessions
-- ============================================================

CREATE TABLE user_ratings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- The user who gave the rating
  rater_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- The user being rated
  rated_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Optional: the session this rating is tied to
  session_id      UUID, -- FK added after sessions table is created
  rating          SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text     TEXT,

  created_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- One rating per rater/rated pair per session
  UNIQUE (rater_id, rated_id, session_id),
  -- Cannot rate yourself
  CONSTRAINT no_self_rating CHECK (rater_id != rated_id)
);

COMMENT ON TABLE user_ratings IS 'Player-to-player ratings after game sessions';

-- ============================================================
-- FRIENDSHIPS / CONNECTIONS TABLE
-- ============================================================

CREATE TABLE friendships (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  addressee_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status        friendship_status NOT NULL DEFAULT 'pending',

  created_at    TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at    TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Prevent duplicate pairs regardless of direction
  UNIQUE (requester_id, addressee_id),
  -- Cannot friend yourself
  CONSTRAINT no_self_friendship CHECK (requester_id != addressee_id)
);

COMMENT ON TABLE friendships IS 'Friend/connection relationships between users';

-- ============================================================
-- INDEXES
-- ============================================================

-- Profiles
CREATE INDEX idx_profiles_username       ON profiles USING btree (username);
CREATE INDEX idx_profiles_location       ON profiles USING gist (location);
CREATE INDEX idx_profiles_experience     ON profiles USING btree (experience_level);
CREATE INDEX idx_profiles_is_active      ON profiles USING btree (is_active) WHERE is_active = TRUE;
CREATE INDEX idx_profiles_last_seen      ON profiles USING btree (last_seen_at DESC);
-- Full-text search on username and display_name
CREATE INDEX idx_profiles_search         ON profiles USING gin (
  to_tsvector('english', coalesce(username, '') || ' ' || coalesce(display_name, '') || ' ' || coalesce(bio, ''))
);
-- Trigram index for partial username search
CREATE INDEX idx_profiles_username_trgm  ON profiles USING gin (username gin_trgm_ops);
CREATE INDEX idx_profiles_display_trgm   ON profiles USING gin (display_name gin_trgm_ops);

-- Preferred genres
CREATE INDEX idx_genres_profile_id       ON profile_preferred_genres USING btree (profile_id);
CREATE INDEX idx_genres_genre            ON profile_preferred_genres USING btree (genre);

-- Availability
CREATE INDEX idx_availability_profile_id ON profile_availability USING btree (profile_id);
CREATE INDEX idx_availability_day        ON profile_availability USING btree (day_of_week);

-- Games
CREATE INDEX idx_games_bgg_id            ON games USING btree (bgg_id);
CREATE INDEX idx_games_name_trgm         ON games USING gin (name gin_trgm_ops);
CREATE INDEX idx_games_name_fts          ON games USING gin (to_tsvector('english', name || ' ' || coalesce(description, '')));
CREATE INDEX idx_games_complexity        ON games USING btree (complexity);
CREATE INDEX idx_games_bgg_rating        ON games USING btree (bgg_rating DESC NULLS LAST);
CREATE INDEX idx_games_bgg_rank          ON games USING btree (bgg_rank ASC NULLS LAST);

-- Game genres
CREATE INDEX idx_game_genres_game_id     ON game_genres USING btree (game_id);
CREATE INDEX idx_game_genres_genre       ON game_genres USING btree (genre);

-- Game collection
CREATE INDEX idx_collection_profile_id  ON user_game_collection USING btree (profile_id);
CREATE INDEX idx_collection_game_id     ON user_game_collection USING btree (game_id);
CREATE INDEX idx_collection_status      ON user_game_collection USING btree (status);

-- Favorite games
CREATE INDEX idx_favorites_profile_id   ON profile_favorite_games USING btree (profile_id);
CREATE INDEX idx_favorites_game_id      ON profile_favorite_games USING btree (game_id);

-- Ratings
CREATE INDEX idx_ratings_rated_id       ON user_ratings USING btree (rated_id);
CREATE INDEX idx_ratings_rater_id       ON user_ratings USING btree (rater_id);

-- Friendships
CREATE INDEX idx_friendships_requester  ON friendships USING btree (requester_id);
CREATE INDEX idx_friendships_addressee  ON friendships USING btree (addressee_id);
CREATE INDEX idx_friendships_status     ON friendships USING btree (status);

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
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_games_updated_at
  BEFORE UPDATE ON games
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_collection_updated_at
  BEFORE UPDATE ON user_game_collection
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_ratings_updated_at
  BEFORE UPDATE ON user_ratings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_friendships_updated_at
  BEFORE UPDATE ON friendships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------
-- Auto-create profile when a new auth.users record is inserted
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_username TEXT;
  v_counter  INTEGER := 0;
  v_base     TEXT;
BEGIN
  -- Derive base username from email (everything before @)
  v_base := regexp_replace(
    lower(split_part(NEW.email, '@', 1)),
    '[^a-z0-9_-]', '_', 'g'
  );
  -- Ensure minimum 3 chars
  IF char_length(v_base) < 3 THEN
    v_base := v_base || '_usr';
  END IF;
  -- Truncate to 25 chars to leave room for suffix
  v_base := left(v_base, 25);

  v_username := v_base;

  -- Resolve username conflicts by appending an incrementing number
  WHILE EXISTS (SELECT 1 FROM profiles WHERE username = v_username) LOOP
    v_counter := v_counter + 1;
    v_username := v_base || '_' || v_counter;
  END LOOP;

  INSERT INTO profiles (id, username, display_name)
  VALUES (
    NEW.id,
    v_username,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NULL)
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ----------------------------------------------------------------
-- Recalculate rating_average and rating_count on profiles
-- whenever a rating is inserted, updated, or deleted
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_profile_rating()
RETURNS TRIGGER AS $$
DECLARE
  v_target_id UUID;
BEGIN
  -- Determine which profile to update
  IF TG_OP = 'DELETE' THEN
    v_target_id := OLD.rated_id;
  ELSE
    v_target_id := NEW.rated_id;
  END IF;

  UPDATE profiles
  SET
    rating_average = COALESCE((
      SELECT ROUND(AVG(rating)::NUMERIC, 2)
      FROM user_ratings
      WHERE rated_id = v_target_id
    ), 0),
    rating_count = (
      SELECT COUNT(*)
      FROM user_ratings
      WHERE rated_id = v_target_id
    )
  WHERE id = v_target_id;

  RETURN NULL; -- result ignored for AFTER trigger
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rating_insert
  AFTER INSERT ON user_ratings
  FOR EACH ROW EXECUTE FUNCTION update_profile_rating();

CREATE TRIGGER trg_rating_update
  AFTER UPDATE OF rating ON user_ratings
  FOR EACH ROW EXECUTE FUNCTION update_profile_rating();

CREATE TRIGGER trg_rating_delete
  AFTER DELETE ON user_ratings
  FOR EACH ROW EXECUTE FUNCTION update_profile_rating();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all user-facing tables
ALTER TABLE profiles                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_preferred_genres ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_availability     ENABLE ROW LEVEL SECURITY;
ALTER TABLE games                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_genres              ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_game_collection     ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_favorite_games   ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ratings             ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships              ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------
-- profiles policies
-- ----------------------------------------------------------------

-- Anyone can view active profiles (public discovery)
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (is_active = TRUE);

-- Users can insert their own profile (handled by trigger, but allow direct too)
CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update only their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can delete their own profile (cascades to auth.users via FK)
CREATE POLICY "Users can delete their own profile"
  ON profiles FOR DELETE
  USING (auth.uid() = id);

-- ----------------------------------------------------------------
-- profile_preferred_genres policies
-- ----------------------------------------------------------------

CREATE POLICY "Genres are viewable by everyone"
  ON profile_preferred_genres FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = profile_preferred_genres.profile_id
        AND profiles.is_active = TRUE
    )
  );

CREATE POLICY "Users can manage their own genres"
  ON profile_preferred_genres FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can delete their own genres"
  ON profile_preferred_genres FOR DELETE
  USING (auth.uid() = profile_id);

-- ----------------------------------------------------------------
-- profile_availability policies
-- ----------------------------------------------------------------

CREATE POLICY "Availability is viewable by everyone"
  ON profile_availability FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = profile_availability.profile_id
        AND profiles.is_active = TRUE
    )
  );

CREATE POLICY "Users can manage their own availability"
  ON profile_availability FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can delete their own availability"
  ON profile_availability FOR DELETE
  USING (auth.uid() = profile_id);

-- ----------------------------------------------------------------
-- games policies (read-only for regular users)
-- ----------------------------------------------------------------

CREATE POLICY "Games are viewable by everyone"
  ON games FOR SELECT
  USING (TRUE);

-- Only service role / admin can insert/update games (BGG sync)
CREATE POLICY "Only admins can insert games"
  ON games FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'moderator')
    )
  );

CREATE POLICY "Only admins can update games"
  ON games FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'moderator')
    )
  );

-- ----------------------------------------------------------------
-- game_genres policies
-- ----------------------------------------------------------------

CREATE POLICY "Game genres are viewable by everyone"
  ON game_genres FOR SELECT
  USING (TRUE);

-- ----------------------------------------------------------------
-- user_game_collection policies
-- ----------------------------------------------------------------

CREATE POLICY "Collections are viewable by everyone"
  ON user_game_collection FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = user_game_collection.profile_id
        AND profiles.is_active = TRUE
    )
  );

CREATE POLICY "Users can insert into their own collection"
  ON user_game_collection FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update their own collection"
  ON user_game_collection FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can delete from their own collection"
  ON user_game_collection FOR DELETE
  USING (auth.uid() = profile_id);

-- ----------------------------------------------------------------
-- profile_favorite_games policies
-- ----------------------------------------------------------------

CREATE POLICY "Favorites are viewable by everyone"
  ON profile_favorite_games FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = profile_favorite_games.profile_id
        AND profiles.is_active = TRUE
    )
  );

CREATE POLICY "Users can insert their own favorites"
  ON profile_favorite_games FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update their own favorites"
  ON profile_favorite_games FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can delete their own favorites"
  ON profile_favorite_games FOR DELETE
  USING (auth.uid() = profile_id);

-- ----------------------------------------------------------------
-- user_ratings policies
-- ----------------------------------------------------------------

CREATE POLICY "Ratings are viewable by everyone"
  ON user_ratings FOR SELECT
  USING (TRUE);

CREATE POLICY "Authenticated users can insert ratings"
  ON user_ratings FOR INSERT
  WITH CHECK (auth.uid() = rater_id);

CREATE POLICY "Users can update their own ratings"
  ON user_ratings FOR UPDATE
  USING (auth.uid() = rater_id)
  WITH CHECK (auth.uid() = rater_id);

CREATE POLICY "Users can delete their own ratings"
  ON user_ratings FOR DELETE
  USING (auth.uid() = rater_id);

-- ----------------------------------------------------------------
-- friendships policies
-- ----------------------------------------------------------------

-- Users can see their own friendship records
CREATE POLICY "Users can view their own friendships"
  ON friendships FOR SELECT
  USING (
    auth.uid() = requester_id OR
    auth.uid() = addressee_id
  );

-- Users can send friend requests
CREATE POLICY "Users can send friend requests"
  ON friendships FOR INSERT
  WITH CHECK (auth.uid() = requester_id);

-- Either party can update (accept/block)
CREATE POLICY "Users can update friendships they are part of"
  ON friendships FOR UPDATE
  USING (
    auth.uid() = requester_id OR
    auth.uid() = addressee_id
  );

-- Either party can remove the friendship
CREATE POLICY "Users can delete friendships they are part of"
  ON friendships FOR DELETE
  USING (
    auth.uid() = requester_id OR
    auth.uid() = addressee_id
  );
