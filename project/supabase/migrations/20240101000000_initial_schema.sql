-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE experience_level AS ENUM (
  'beginner',
  'casual',
  'intermediate',
  'advanced',
  'expert'
);

CREATE TYPE game_genre AS ENUM (
  'strategy',
  'worker_placement',
  'deck_building',
  'cooperative',
  'competitive',
  'party',
  'rpg',
  'war_game',
  'euro_game',
  'ameritrash',
  'abstract',
  'trivia',
  'social_deduction',
  'dungeon_crawler',
  'legacy',
  'puzzle',
  'family',
  'filler',
  'thematic',
  'train_game'
);

CREATE TYPE collection_status AS ENUM (
  'own',
  'wishlist',
  'previously_owned',
  'want_to_play',
  'for_trade'
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
  'morning',
  'afternoon',
  'evening',
  'night'
);

-- ============================================================
-- PROFILES TABLE
-- Core user profile extending Supabase auth.users
-- ============================================================

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  banner_url TEXT,

  -- Location fields
  city TEXT,
  state TEXT,
  country TEXT,
  postal_code TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  location_point GEOGRAPHY(POINT, 4326),
  location_public BOOLEAN NOT NULL DEFAULT true,

  -- Gaming identity
  experience_level experience_level NOT NULL DEFAULT 'casual',
  preferred_player_count_min INTEGER CHECK (preferred_player_count_min >= 1),
  preferred_player_count_max INTEGER CHECK (preferred_player_count_max >= 1),
  preferred_session_length_hours NUMERIC(4, 1),

  -- Profile settings
  is_public BOOLEAN NOT NULL DEFAULT true,
  is_looking_for_group BOOLEAN NOT NULL DEFAULT false,
  show_email BOOLEAN NOT NULL DEFAULT false,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
  CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_-]+$'),
  CONSTRAINT bio_length CHECK (char_length(bio) <= 1000),
  CONSTRAINT player_count_range CHECK (
    preferred_player_count_max IS NULL OR
    preferred_player_count_min IS NULL OR
    preferred_player_count_max >= preferred_player_count_min
  )
);

COMMENT ON TABLE profiles IS 'User profiles extending Supabase auth.users with gaming-specific data';
COMMENT ON COLUMN profiles.location_point IS 'PostGIS geography point for spatial queries';
COMMENT ON COLUMN profiles.is_looking_for_group IS 'Whether the user is actively seeking gaming partners';

-- ============================================================
-- GAMING PREFERENCES TABLE
-- Stores genre and game-type preferences for matching
-- ============================================================

CREATE TABLE gaming_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  genre game_genre NOT NULL,
  preference_weight INTEGER NOT NULL DEFAULT 3 CHECK (preference_weight BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(profile_id, genre)
);

COMMENT ON TABLE gaming_preferences IS 'User genre preferences with weighting for matching algorithm';
COMMENT ON COLUMN gaming_preferences.preference_weight IS '1=dislike, 2=neutral, 3=like, 4=love, 5=must-have';

-- ============================================================
-- GAMES TABLE
-- Local cache / reference for boardgame data (BGG integration)
-- ============================================================

CREATE TABLE games (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bgg_id INTEGER UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  image_url TEXT,
  min_players INTEGER CHECK (min_players >= 1),
  max_players INTEGER CHECK (max_players >= 1),
  min_playtime_minutes INTEGER CHECK (min_playtime_minutes >= 0),
  max_playtime_minutes INTEGER CHECK (max_playtime_minutes >= 0),
  min_age INTEGER CHECK (min_age >= 0),
  complexity_rating NUMERIC(3, 2) CHECK (complexity_rating BETWEEN 1.0 AND 5.0),
  bgg_rating NUMERIC(4, 2) CHECK (bgg_rating BETWEEN 1.0 AND 10.0),
  year_published INTEGER,
  is_expansion BOOLEAN NOT NULL DEFAULT false,
  categories TEXT[],
  mechanics TEXT[],
  designers TEXT[],
  publishers TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT player_count_range CHECK (
    max_players IS NULL OR min_players IS NULL OR max_players >= min_players
  ),
  CONSTRAINT playtime_range CHECK (
    max_playtime_minutes IS NULL OR min_playtime_minutes IS NULL OR
    max_playtime_minutes >= min_playtime_minutes
  )
);

COMMENT ON TABLE games IS 'Board game catalog, populated from BoardGameGeek API and user additions';
COMMENT ON COLUMN games.bgg_id IS 'BoardGameGeek game ID for API integration';

-- ============================================================
-- USER GAME COLLECTION TABLE
-- Tracks games users own, want, etc.
-- ============================================================

CREATE TABLE user_game_collection (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  status collection_status NOT NULL DEFAULT 'own',
  personal_rating INTEGER CHECK (personal_rating BETWEEN 1 AND 10),
  play_count INTEGER NOT NULL DEFAULT 0 CHECK (play_count >= 0),
  notes TEXT,
  acquired_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(profile_id, game_id, status)
);

COMMENT ON TABLE user_game_collection IS 'User''s personal game collection with ownership status and ratings';

-- ============================================================
-- FAVORITE GAMES TABLE
-- Explicit favorites for profile display and matching
-- ============================================================

CREATE TABLE favorite_games (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(profile_id, game_id)
);

COMMENT ON TABLE favorite_games IS 'User''s explicitly marked favorite games, shown prominently on profile';

-- ============================================================
-- AVAILABILITY TABLE
-- When users are typically available to play
-- ============================================================

CREATE TABLE user_availability (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  day_of_week availability_day NOT NULL,
  time_of_day availability_time NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(profile_id, day_of_week, time_of_day)
);

COMMENT ON TABLE user_availability IS 'User''s typical weekly availability for game sessions';

-- ============================================================
-- USER RATINGS TABLE
-- Player-to-player ratings after game sessions
-- ============================================================

CREATE TABLE user_ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rater_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rated_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review TEXT,
  is_public BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(rater_id, rated_id),
  CONSTRAINT no_self_rating CHECK (rater_id != rated_id),
  CONSTRAINT review_length CHECK (char_length(review) <= 500)
);

COMMENT ON TABLE user_ratings IS 'Peer ratings between users after gaming sessions';

-- ============================================================
-- PROFILE STATS VIEW
-- Aggregated profile statistics for display
-- ============================================================

CREATE VIEW profile_stats AS
SELECT
  p.id AS profile_id,
  COUNT(DISTINCT ugc.id) FILTER (WHERE ugc.status = 'own') AS games_owned,
  COUNT(DISTINCT ugc.id) FILTER (WHERE ugc.status = 'wishlist') AS games_wishlisted,
  COUNT(DISTINCT fg.id) AS favorite_games_count,
  ROUND(AVG(ur.rating)::NUMERIC, 2) AS average_rating,
  COUNT(DISTINCT ur.id) AS total_ratings_received,
  COUNT(DISTINCT gp.id) AS genre_preferences_count
FROM profiles p
LEFT JOIN user_game_collection ugc ON ugc.profile_id = p.id
LEFT JOIN favorite_games fg ON fg.profile_id = p.id
LEFT JOIN user_ratings ur ON ur.rated_id = p.id AND ur.is_public = true
LEFT JOIN gaming_preferences gp ON gp.profile_id = p.id
GROUP BY p.id;

COMMENT ON VIEW profile_stats IS 'Aggregated statistics for user profiles';

-- ============================================================
-- INDEXES
-- ============================================================

-- Profiles
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_profiles_location_point ON profiles USING GIST(location_point);
CREATE INDEX idx_profiles_is_looking_for_group ON profiles(is_looking_for_group) WHERE is_looking_for_group = true;
CREATE INDEX idx_profiles_experience_level ON profiles(experience_level);
CREATE INDEX idx_profiles_is_public ON profiles(is_public) WHERE is_public = true;
CREATE INDEX idx_profiles_created_at ON profiles(created_at);

-- Username search with trigram
CREATE INDEX idx_profiles_username_trgm ON profiles USING GIN(username gin_trgm_ops);
CREATE INDEX idx_profiles_display_name_trgm ON profiles USING GIN(display_name gin_trgm_ops);

-- Gaming preferences
CREATE INDEX idx_gaming_preferences_profile_id ON gaming_preferences(profile_id);
CREATE INDEX idx_gaming_preferences_genre ON gaming_preferences(genre);

-- Games
CREATE INDEX idx_games_bgg_id ON games(bgg_id) WHERE bgg_id IS NOT NULL;
CREATE INDEX idx_games_name ON games(name);
CREATE INDEX idx_games_name_trgm ON games USING GIN(name gin_trgm_ops);
CREATE INDEX idx_games_categories ON games USING GIN(categories);
CREATE INDEX idx_games_mechanics ON games USING GIN(mechanics);

-- User game collection
CREATE INDEX idx_ugc_profile_id ON user_game_collection(profile_id);
CREATE INDEX idx_ugc_game_id ON user_game_collection(game_id);
CREATE INDEX idx_ugc_status ON user_game_collection(status);
CREATE INDEX idx_ugc_profile_status ON user_game_collection(profile_id, status);

-- Favorite games
CREATE INDEX idx_favorite_games_profile_id ON favorite_games(profile_id);
CREATE INDEX idx_favorite_games_game_id ON favorite_games(game_id);

-- Availability
CREATE INDEX idx_user_availability_profile_id ON user_availability(profile_id);
CREATE INDEX idx_user_availability_day ON user_availability(day_of_week);

-- Ratings
CREATE INDEX idx_user_ratings_rater_id ON user_ratings(rater_id);
CREATE INDEX idx_user_ratings_rated_id ON user_ratings(rated_id);
CREATE INDEX idx_user_ratings_public ON user_ratings(rated_id, is_public) WHERE is_public = true;

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

-- Apply updated_at triggers
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_games_updated_at
  BEFORE UPDATE ON games
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_ugc_updated_at
  BEFORE UPDATE ON user_game_collection
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_user_ratings_updated_at
  BEFORE UPDATE ON user_ratings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- LOCATION SYNC TRIGGER
-- Keeps location_point in sync with lat/lng columns
-- ============================================================

CREATE OR REPLACE FUNCTION sync_location_point()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location_point = ST_SetSRID(
      ST_MakePoint(NEW.longitude, NEW.latitude),
      4326
    )::GEOGRAPHY;
  ELSE
    NEW.location_point = NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_sync_location
  BEFORE INSERT OR UPDATE OF latitude, longitude ON profiles
  FOR EACH ROW EXECUTE FUNCTION sync_location_point();
