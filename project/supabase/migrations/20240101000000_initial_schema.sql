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
  'experienced',
  'expert'
);

CREATE TYPE game_genre AS ENUM (
  'strategy',
  'worker_placement',
  'deck_building',
  'cooperative',
  'competitive',
  'party',
  'role_playing',
  'war_game',
  'euro_game',
  'thematic',
  'abstract',
  'family',
  'trivia',
  'dexterity',
  'social_deduction',
  'legacy',
  'dungeon_crawl',
  'engine_building',
  'area_control',
  'push_your_luck'
);

CREATE TYPE collection_status AS ENUM (
  'owned',
  'wishlist',
  'previously_owned',
  'want_to_play'
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
-- Core user profile data, linked to Supabase auth.users
-- ============================================================

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  website_url TEXT,

  -- Location fields
  city TEXT,
  state_province TEXT,
  country TEXT DEFAULT 'US',
  postal_code TEXT,
  -- Spatial point for distance-based queries (longitude, latitude)
  location GEOGRAPHY(POINT, 4326),
  -- Max distance user is willing to travel (in km)
  max_travel_distance_km INTEGER DEFAULT 25,
  -- Whether to show precise location or just city/region
  show_exact_location BOOLEAN DEFAULT FALSE,

  -- Gaming info
  experience_level experience_level DEFAULT 'casual',
  years_gaming INTEGER,
  languages TEXT[] DEFAULT ARRAY['en'],

  -- Social links
  bgg_username TEXT,
  discord_username TEXT,

  -- Preferences
  is_profile_public BOOLEAN DEFAULT TRUE,
  is_looking_for_group BOOLEAN DEFAULT FALSE,
  allow_messages_from TEXT DEFAULT 'all' CHECK (allow_messages_from IN ('all', 'connections', 'none')),
  notification_email BOOLEAN DEFAULT TRUE,
  notification_push BOOLEAN DEFAULT TRUE,
  notification_in_app BOOLEAN DEFAULT TRUE,

  -- Metadata
  last_active_at TIMESTAMPTZ,
  onboarding_completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE profiles IS 'User profile data extending Supabase auth.users';
COMMENT ON COLUMN profiles.location IS 'PostGIS geography point (longitude, latitude) for spatial queries';
COMMENT ON COLUMN profiles.max_travel_distance_km IS 'Maximum distance in kilometers user is willing to travel for games';
COMMENT ON COLUMN profiles.bgg_username IS 'BoardGameGeek username for game collection import';

-- ============================================================
-- GAMING PREFERENCES TABLE
-- Separate table for normalized gaming preferences
-- ============================================================

CREATE TABLE gaming_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Preferred genres (array of enum values)
  preferred_genres game_genre[] DEFAULT ARRAY[]::game_genre[],

  -- Player count preferences
  min_players_preferred INTEGER DEFAULT 2 CHECK (min_players_preferred >= 1),
  max_players_preferred INTEGER DEFAULT 6 CHECK (max_players_preferred >= 1),

  -- Session preferences
  preferred_session_length_min INTEGER, -- in minutes
  preferred_session_length_max INTEGER, -- in minutes
  preferred_frequency TEXT CHECK (preferred_frequency IN (
    'daily', 'multiple_per_week', 'weekly', 'biweekly', 'monthly', 'occasional'
  )),

  -- Game complexity preference (1-5 scale)
  min_complexity INTEGER DEFAULT 1 CHECK (min_complexity BETWEEN 1 AND 5),
  max_complexity INTEGER DEFAULT 5 CHECK (max_complexity BETWEEN 1 AND 5),

  -- Play style preferences
  prefers_competitive BOOLEAN DEFAULT TRUE,
  prefers_cooperative BOOLEAN DEFAULT TRUE,
  prefers_team_games BOOLEAN DEFAULT TRUE,
  prefers_solo_capable BOOLEAN DEFAULT FALSE,
  open_to_teaching BOOLEAN DEFAULT TRUE,
  open_to_being_taught BOOLEAN DEFAULT TRUE,

  -- Content preferences
  comfortable_with_mature_themes BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE(profile_id)
);

COMMENT ON TABLE gaming_preferences IS 'Normalized gaming preference data for matching algorithms';
COMMENT ON COLUMN gaming_preferences.preferred_frequency IS 'How often the user wants to play games';

-- ============================================================
-- AVAILABILITY TABLE
-- User's weekly recurring availability schedule
-- ============================================================

CREATE TABLE availability_slots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  day_of_week availability_day NOT NULL,
  time_of_day availability_time NOT NULL,
  is_available BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE(profile_id, day_of_week, time_of_day)
);

COMMENT ON TABLE availability_slots IS 'Recurring weekly availability schedule for each user';

-- ============================================================
-- GAME CATALOG TABLE
-- Local cache/extension of BoardGameGeek game data
-- ============================================================

CREATE TABLE games (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bgg_id INTEGER UNIQUE,

  name TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  image_url TEXT,

  -- Game metadata from BGG
  year_published INTEGER,
  min_players INTEGER,
  max_players INTEGER,
  min_playtime INTEGER, -- in minutes
  max_playtime INTEGER, -- in minutes
  min_age INTEGER,
  -- BGG complexity rating (1.0 - 5.0)
  complexity_rating DECIMAL(3,2),
  -- BGG average rating (1.0 - 10.0)
  average_rating DECIMAL(4,2),

  genres game_genre[] DEFAULT ARRAY[]::game_genre[],
  categories TEXT[],
  mechanics TEXT[],
  designers TEXT[],
  publishers TEXT[],

  is_expansion BOOLEAN DEFAULT FALSE,
  base_game_id UUID REFERENCES games(id),

  -- Search vector for full text search
  search_vector TSVECTOR,

  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE games IS 'Game catalog, optionally synced from BoardGameGeek API';
COMMENT ON COLUMN games.bgg_id IS 'BoardGameGeek game ID for API integration';
COMMENT ON COLUMN games.complexity_rating IS 'BGG weight/complexity rating from 1.0 (light) to 5.0 (heavy)';

-- ============================================================
-- USER GAME COLLECTION TABLE
-- Tracks games users own, want, etc.
-- ============================================================

CREATE TABLE user_game_collections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,

  status collection_status NOT NULL DEFAULT 'owned',
  user_rating INTEGER CHECK (user_rating BETWEEN 1 AND 10),
  review TEXT,
  play_count INTEGER DEFAULT 0,
  willing_to_bring BOOLEAN DEFAULT TRUE,
  willing_to_teach BOOLEAN DEFAULT FALSE,
  notes TEXT,

  acquired_at DATE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE(profile_id, game_id, status)
);

COMMENT ON TABLE user_game_collections IS 'User game collections including owned, wishlist, and previously owned games';
COMMENT ON COLUMN user_game_collections.willing_to_bring IS 'Whether the user is willing to bring this game to events';
COMMENT ON COLUMN user_game_collections.willing_to_teach IS 'Whether the user is willing to teach this game to others';

-- ============================================================
-- FAVORITE GAMES TABLE (denormalized for quick access)
-- ============================================================

CREATE TABLE user_favorite_games (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  sort_order INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE(profile_id, game_id)
);

COMMENT ON TABLE user_favorite_games IS 'User favorite games for profile display, limited to top favorites';

-- ============================================================
-- USER RATINGS TABLE
-- Players rating each other after game sessions
-- ============================================================

CREATE TABLE user_ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rater_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rated_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Overall rating 1-5
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review TEXT,

  -- Specific rating dimensions
  reliability_rating INTEGER CHECK (reliability_rating BETWEEN 1 AND 5),
  sportsmanship_rating INTEGER CHECK (sportsmanship_rating BETWEEN 1 AND 5),
  rules_knowledge_rating INTEGER CHECK (rules_knowledge_rating BETWEEN 1 AND 5),
  fun_factor_rating INTEGER CHECK (fun_factor_rating BETWEEN 1 AND 5),

  -- Context for the rating
  event_id UUID, -- Will be FK'd after events table is created
  is_public BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- One rating per rater per rated user (can update)
  UNIQUE(rater_id, rated_id),
  -- Users cannot rate themselves
  CHECK (rater_id != rated_id)
);

COMMENT ON TABLE user_ratings IS 'Peer ratings between users after gaming sessions';
COMMENT ON COLUMN user_ratings.rater_id IS 'The user giving the rating';
COMMENT ON COLUMN user_ratings.rated_id IS 'The user being rated';

-- ============================================================
-- PROFILE CONNECTIONS / FOLLOWS TABLE
-- Social graph for following other users
-- ============================================================

CREATE TABLE user_connections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Can be 'following' for one-way or 'connected' for mutual
  status TEXT DEFAULT 'following' CHECK (status IN ('following', 'connected', 'blocked')),

  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

COMMENT ON TABLE user_connections IS 'Social connections between users (follows, mutual connections, blocks)';

-- ============================================================
-- PROFILE VIEWS TABLE
-- Track profile view analytics
-- ============================================================

CREATE TABLE profile_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  viewed_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  viewer_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- NULL for anonymous views
  viewer_ip_hash TEXT, -- Hashed IP for anonymous view deduplication

  viewed_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE profile_views IS 'Analytics table tracking profile page views';

-- ============================================================
-- INDEXES
-- ============================================================

-- Profiles
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_profiles_location ON profiles USING GIST(location);
CREATE INDEX idx_profiles_experience_level ON profiles(experience_level);
CREATE INDEX idx_profiles_is_looking_for_group ON profiles(is_looking_for_group) WHERE is_looking_for_group = TRUE;
CREATE INDEX idx_profiles_is_profile_public ON profiles(is_profile_public) WHERE is_profile_public = TRUE;
CREATE INDEX idx_profiles_last_active_at ON profiles(last_active_at DESC);
CREATE INDEX idx_profiles_created_at ON profiles(created_at DESC);
-- Text search on display_name and username
CREATE INDEX idx_profiles_display_name_trgm ON profiles USING GIN(display_name gin_trgm_ops);
CREATE INDEX idx_profiles_username_trgm ON profiles USING GIN(username gin_trgm_ops);

-- Gaming preferences
CREATE INDEX idx_gaming_preferences_profile_id ON gaming_preferences(profile_id);
CREATE INDEX idx_gaming_preferences_genres ON gaming_preferences USING GIN(preferred_genres);

-- Availability
CREATE INDEX idx_availability_slots_profile_id ON availability_slots(profile_id);
CREATE INDEX idx_availability_slots_day ON availability_slots(day_of_week);

-- Games
CREATE INDEX idx_games_bgg_id ON games(bgg_id) WHERE bgg_id IS NOT NULL;
CREATE INDEX idx_games_name ON games(name);
CREATE INDEX idx_games_name_trgm ON games USING GIN(name gin_trgm_ops);
CREATE INDEX idx_games_search_vector ON games USING GIN(search_vector);
CREATE INDEX idx_games_genres ON games USING GIN(genres);
CREATE INDEX idx_games_complexity ON games(complexity_rating);
CREATE INDEX idx_games_rating ON games(average_rating DESC);

-- User game collections
CREATE INDEX idx_user_game_collections_profile_id ON user_game_collections(profile_id);
CREATE INDEX idx_user_game_collections_game_id ON user_game_collections(game_id);
CREATE INDEX idx_user_game_collections_status ON user_game_collections(status);
CREATE INDEX idx_user_game_collections_willing_to_bring ON user_game_collections(willing_to_bring) WHERE willing_to_bring = TRUE;

-- Favorite games
CREATE INDEX idx_user_favorite_games_profile_id ON user_favorite_games(profile_id);

-- User ratings
CREATE INDEX idx_user_ratings_rated_id ON user_ratings(rated_id);
CREATE INDEX idx_user_ratings_rater_id ON user_ratings(rater_id);

-- Connections
CREATE INDEX idx_user_connections_follower_id ON user_connections(follower_id);
CREATE INDEX idx_user_connections_following_id ON user_connections(following_id);
CREATE INDEX idx_user_connections_status ON user_connections(status);

-- Profile views
CREATE INDEX idx_profile_views_viewed_profile_id ON profile_views(viewed_profile_id);
CREATE INDEX idx_profile_views_viewed_at ON profile_views(viewed_at DESC);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-create profile and gaming preferences on new user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  _username TEXT;
  _display_name TEXT;
BEGIN
  -- Generate username from email (before the @)
  _username := LOWER(SPLIT_PART(NEW.email, '@', 1));
  -- Append random suffix if username might conflict
  _username := _username || '_' || SUBSTR(NEW.id::TEXT, 1, 8);

  -- Use full name from metadata if available, else email prefix
  _display_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    SPLIT_PART(NEW.email, '@', 1)
  );

  -- Create profile
  INSERT INTO public.profiles (
    id,
    username,
    display_name,
    avatar_url,
    last_active_at
  ) VALUES (
    NEW.id,
    _username,
    _display_name,
    NEW.raw_user_meta_data->>'avatar_url',
    NOW()
  );

  -- Create default gaming preferences
  INSERT INTO public.gaming_preferences (profile_id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update game search vector on insert/update
CREATE OR REPLACE FUNCTION update_game_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    SETWEIGHT(TO_TSVECTOR('english', COALESCE(NEW.name, '')), 'A') ||
    SETWEIGHT(TO_TSVECTOR('english', COALESCE(NEW.description, '')), 'B') ||
    SETWEIGHT(TO_TSVECTOR('english', COALESCE(ARRAY_TO_STRING(NEW.categories, ' '), '')), 'C') ||
    SETWEIGHT(TO_TSVECTOR('english', COALESCE(ARRAY_TO_STRING(NEW.mechanics, ' '), '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Get user's average rating
CREATE OR REPLACE FUNCTION get_user_average_rating(user_id UUID)
RETURNS DECIMAL AS $$
  SELECT ROUND(AVG(rating)::DECIMAL, 2)
  FROM user_ratings
  WHERE rated_id = user_id
    AND is_public = TRUE;
$$ LANGUAGE SQL STABLE;

-- Get user's rating count
CREATE OR REPLACE FUNCTION get_user_rating_count(user_id UUID)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER
  FROM user_ratings
  WHERE rated_id = user_id
    AND is_public = TRUE;
$$ LANGUAGE SQL STABLE;

-- Find nearby profiles within a given distance
CREATE OR REPLACE FUNCTION find_nearby_profiles(
  lat FLOAT,
  lng FLOAT,
  radius_km FLOAT DEFAULT 25,
  limit_count INTEGER DEFAULT 20,
  offset_count INTEGER DEFAULT 0
)
RETURNS TABLE(
  profile_id UUID,
  distance_km FLOAT
) AS $$
  SELECT
    p.id AS profile_id,
    ST_Distance(p.location, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::GEOGRAPHY) / 1000 AS distance_km
  FROM profiles p
  WHERE
    p.is_profile_public = TRUE
    AND p.location IS NOT NULL
    AND ST_DWithin(
      p.location,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::GEOGRAPHY,
      radius_km * 1000 -- Convert km to meters
    )
  ORDER BY distance_km ASC
  LIMIT limit_count
  OFFSET offset_count;
$$ LANGUAGE SQL STABLE;

-- Update user last_active_at
CREATE OR REPLACE FUNCTION update_user_last_active(user_id UUID)
RETURNS VOID AS $$
  UPDATE profiles
  SET last_active_at = NOW()
  WHERE id = user_id;
$$ LANGUAGE SQL;

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-update updated_at on profiles
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Auto-update updated_at on gaming_preferences
CREATE TRIGGER gaming_preferences_updated_at
  BEFORE UPDATE ON gaming_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Auto-update updated_at on availability_slots
CREATE TRIGGER availability_slots_updated_at
  BEFORE UPDATE ON availability_slots
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Auto-update updated_at on games
CREATE TRIGGER games_updated_at
  BEFORE UPDATE ON games
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Auto-update updated_at on user_game_collections
CREATE TRIGGER user_game_collections_updated_at
  BEFORE UPDATE ON user_game_collections
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Auto-update updated_at on user_ratings
CREATE TRIGGER user_ratings_updated_at
  BEFORE UPDATE ON user_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Auto-create profile on auth user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Auto-update game search vector
CREATE TRIGGER games_search_vector_update
  BEFORE INSERT OR UPDATE OF name, description, categories, mechanics ON games
  FOR EACH ROW
  EXECUTE FUNCTION update_game_search_vector();
