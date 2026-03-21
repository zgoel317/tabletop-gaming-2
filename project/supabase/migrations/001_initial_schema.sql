-- Migration: 001_initial_schema.sql
-- Description: Creates all core tables, enums, indexes, constraints, and triggers
-- for the Tabletop Gaming Networking App MVP

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE experience_level AS ENUM (
  'beginner',
  'intermediate',
  'advanced',
  'expert'
);

CREATE TYPE player_count_preference AS ENUM (
  'solo',
  'small_group',
  'medium_group',
  'large_group'
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

CREATE TYPE game_collection_status AS ENUM (
  'owned',
  'wishlist',
  'previously_owned'
);

CREATE TYPE session_status AS ENUM (
  'scheduled',
  'cancelled',
  'completed'
);

CREATE TYPE rsvp_status AS ENUM (
  'going',
  'maybe',
  'not_going',
  'waitlisted'
);

CREATE TYPE group_role AS ENUM (
  'organizer',
  'moderator',
  'member'
);

CREATE TYPE message_type AS ENUM (
  'direct',
  'group',
  'event'
);

-- ============================================================
-- TABLE: profiles
-- Extends Supabase auth.users with app-specific profile data
-- ============================================================

CREATE TABLE profiles (
  id                   UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username             TEXT UNIQUE NOT NULL,
  display_name         TEXT NOT NULL,
  bio                  TEXT,
  avatar_url           TEXT,
  location_name        TEXT,
  latitude             DECIMAL(9,6),
  longitude            DECIMAL(9,6),
  is_location_public   BOOLEAN DEFAULT true,
  experience_level     experience_level DEFAULT 'beginner',
  is_looking_for_group BOOLEAN DEFAULT false,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]{3,30}$'),
  CONSTRAINT bio_length CHECK (char_length(bio) <= 500)
);

COMMENT ON TABLE profiles IS 'User profile data extending Supabase auth.users';
COMMENT ON COLUMN profiles.username IS 'Unique username (3-30 chars, alphanumeric + underscore)';
COMMENT ON COLUMN profiles.location_name IS 'Human-readable location string (city, region, etc.)';
COMMENT ON COLUMN profiles.is_looking_for_group IS 'Whether the user is actively seeking a gaming group';

-- ============================================================
-- TABLE: game_genres
-- Lookup table for board game genres/categories
-- ============================================================

CREATE TABLE game_genres (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT UNIQUE NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE game_genres IS 'Lookup table for board game genres and categories';

-- ============================================================
-- TABLE: games
-- Game catalog with BoardGameGeek integration support
-- ============================================================

CREATE TABLE games (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bgg_id                   INTEGER UNIQUE,
  name                     TEXT NOT NULL,
  description              TEXT,
  min_players              INTEGER,
  max_players              INTEGER,
  average_playtime_minutes INTEGER,
  image_url                TEXT,
  thumbnail_url            TEXT,
  year_published           INTEGER,
  created_at               TIMESTAMPTZ DEFAULT NOW(),
  updated_at               TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE games IS 'Board game catalog, optionally synced with BoardGameGeek API';
COMMENT ON COLUMN games.bgg_id IS 'BoardGameGeek numeric ID for API synchronization';

-- ============================================================
-- TABLE: game_genre_mappings
-- Join table linking games to their genres (many-to-many)
-- ============================================================

CREATE TABLE game_genre_mappings (
  game_id  UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  genre_id UUID NOT NULL REFERENCES game_genres(id) ON DELETE CASCADE,

  PRIMARY KEY (game_id, genre_id)
);

COMMENT ON TABLE game_genre_mappings IS 'Many-to-many relationship between games and genres';

-- ============================================================
-- TABLE: user_favorite_games
-- Games that users have marked as favorites
-- ============================================================

CREATE TABLE user_favorite_games (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id    UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (user_id, game_id)
);

COMMENT ON TABLE user_favorite_games IS 'Games marked as favorites by users';

-- ============================================================
-- TABLE: user_favorite_genres
-- Game genres that users prefer
-- ============================================================

CREATE TABLE user_favorite_genres (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  genre_id UUID NOT NULL REFERENCES game_genres(id) ON DELETE CASCADE,

  UNIQUE (user_id, genre_id)
);

COMMENT ON TABLE user_favorite_genres IS 'Game genres preferred by users';

-- ============================================================
-- TABLE: user_availability
-- Weekly recurring availability windows for each user
-- ============================================================

CREATE TABLE user_availability (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  day_of_week availability_day NOT NULL,
  start_time  TIME NOT NULL,
  end_time    TIME NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (user_id, day_of_week, start_time),
  CONSTRAINT end_after_start CHECK (end_time > start_time)
);

COMMENT ON TABLE user_availability IS 'User weekly recurring availability for gaming sessions';

-- ============================================================
-- TABLE: game_collections
-- Games in a user's personal collection (owned, wishlist, etc.)
-- ============================================================

CREATE TABLE game_collections (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id    UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  status     game_collection_status NOT NULL DEFAULT 'owned',
  notes      TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (user_id, game_id, status)
);

COMMENT ON TABLE game_collections IS 'User game collections including owned, wishlist, and previously owned';

-- ============================================================
-- TABLE: user_ratings
-- Player-to-player ratings and reviews
-- ============================================================

CREATE TABLE user_ratings (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rater_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rated_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating        INTEGER NOT NULL,
  review        TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (rater_id, rated_user_id),
  CONSTRAINT rating_range CHECK (rating >= 1 AND rating <= 5),
  CONSTRAINT no_self_rating CHECK (rater_id != rated_user_id)
);

COMMENT ON TABLE user_ratings IS 'Player ratings and reviews between users after gaming sessions';

-- ============================================================
-- INDEXES
-- ============================================================

-- Profile lookup and discovery indexes
CREATE INDEX idx_profiles_username
  ON profiles(username);

CREATE INDEX idx_profiles_location
  ON profiles(latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

CREATE INDEX idx_profiles_lfg
  ON profiles(is_looking_for_group)
  WHERE is_looking_for_group = true;

-- Game lookup indexes
CREATE INDEX idx_games_bgg_id
  ON games(bgg_id);

CREATE INDEX idx_games_name
  ON games USING gin(to_tsvector('english', name));

-- User favorites indexes
CREATE INDEX idx_user_favorite_games_user_id
  ON user_favorite_games(user_id);

-- Game collection indexes
CREATE INDEX idx_game_collections_user_id
  ON game_collections(user_id);

-- Rating indexes
CREATE INDEX idx_user_ratings_rated_user
  ON user_ratings(rated_user_id);

-- ============================================================
-- TRIGGER FUNCTION: handle_updated_at
-- Automatically updates the updated_at timestamp on row changes
-- ============================================================

CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION handle_updated_at() IS 'Trigger function to auto-update updated_at timestamp';

-- Apply updated_at trigger to all relevant tables

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER trg_games_updated_at
  BEFORE UPDATE ON games
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER trg_game_collections_updated_at
  BEFORE UPDATE ON game_collections
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER trg_user_ratings_updated_at
  BEFORE UPDATE ON user_ratings
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- ============================================================
-- TRIGGER FUNCTION: handle_new_user
-- Automatically creates a profile row when a new auth user signs up.
--
-- NOTE: When calling supabase.auth.signUp() from the frontend,
-- pass the following in the options.data object to pre-populate
-- the profile:
--   {
--     username: 'desired_username',
--     display_name: 'Full Name',
--     avatar_url: 'https://...'
--   }
-- If not provided, a placeholder username is generated from the
-- user's UUID and the email is used as display_name.
-- ============================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'username',
      'user_' || LEFT(NEW.id::TEXT, 8)
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.email
    ),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION handle_new_user() IS
  'Trigger function that auto-creates a profile row when a new Supabase Auth user is created. '
  'Uses SECURITY DEFINER to bypass RLS since the user session does not exist yet at trigger time.';

-- Attach handle_new_user to auth.users inserts
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
