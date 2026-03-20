-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE user_role AS ENUM ('user', 'admin', 'moderator');

CREATE TYPE experience_level AS ENUM (
  'newcomer',
  'beginner',
  'intermediate',
  'advanced',
  'expert'
);

CREATE TYPE game_genre AS ENUM (
  'strategy',
  'euro',
  'thematic',
  'abstract',
  'party',
  'cooperative',
  'deck_building',
  'worker_placement',
  'area_control',
  'roll_and_write',
  'push_your_luck',
  'social_deduction',
  'legacy',
  'wargame',
  'rpg',
  'other'
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

CREATE TYPE collection_status AS ENUM (
  'owned',
  'wishlist',
  'previously_owned',
  'want_to_play'
);

-- ============================================================
-- PROFILES TABLE
-- Extends Supabase auth.users with application-specific data
-- ============================================================

CREATE TABLE public.profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username         TEXT UNIQUE NOT NULL,
  display_name     TEXT,
  bio              TEXT,
  avatar_url       TEXT,
  website_url      TEXT,

  -- Location fields
  city             TEXT,
  state_province   TEXT,
  country          TEXT DEFAULT 'US',
  postal_code      TEXT,
  -- PostGIS geography point for spatial queries
  location         GEOGRAPHY(POINT, 4326),
  location_public  BOOLEAN NOT NULL DEFAULT TRUE,

  -- Gaming identity
  experience_level experience_level NOT NULL DEFAULT 'beginner',
  preferred_player_count_min  INTEGER CHECK (preferred_player_count_min >= 1),
  preferred_player_count_max  INTEGER CHECK (preferred_player_count_max <= 20),

  -- Availability
  available_days   availability_day[],
  available_times  availability_time[],

  -- Social
  is_looking_for_group BOOLEAN NOT NULL DEFAULT FALSE,
  is_open_to_teach     BOOLEAN NOT NULL DEFAULT FALSE,
  is_open_to_learn     BOOLEAN NOT NULL DEFAULT FALSE,

  -- Account
  role             user_role NOT NULL DEFAULT 'user',
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,

  -- Stats (denormalized for performance)
  total_sessions_played INTEGER NOT NULL DEFAULT 0,
  total_sessions_hosted INTEGER NOT NULL DEFAULT 0,
  average_rating        NUMERIC(3, 2) CHECK (average_rating >= 0 AND average_rating <= 5),
  total_ratings         INTEGER NOT NULL DEFAULT 0,

  -- Timestamps
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
  CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_-]+$'),
  CONSTRAINT player_count_range CHECK (
    preferred_player_count_min IS NULL OR
    preferred_player_count_max IS NULL OR
    preferred_player_count_min <= preferred_player_count_max
  )
);

COMMENT ON TABLE public.profiles IS 'User profile information extending Supabase auth.users';
COMMENT ON COLUMN public.profiles.location IS 'PostGIS geography point (longitude, latitude) for spatial queries';
COMMENT ON COLUMN public.profiles.average_rating IS 'Denormalized average rating from user_ratings table';

-- ============================================================
-- GAMING PREFERENCES TABLE
-- Stores favorite game genres and preferences
-- ============================================================

CREATE TABLE public.gaming_preferences (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  genre            game_genre NOT NULL,
  preference_level INTEGER NOT NULL DEFAULT 3 CHECK (preference_level >= 1 AND preference_level <= 5),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(profile_id, genre)
);

COMMENT ON TABLE public.gaming_preferences IS 'User genre preferences with a 1-5 preference level';
COMMENT ON COLUMN public.gaming_preferences.preference_level IS '1 = dislike, 3 = neutral, 5 = love';

-- ============================================================
-- GAMES TABLE
-- Board game catalog (seeded from BoardGameGeek API)
-- ============================================================

CREATE TABLE public.games (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bgg_id           INTEGER UNIQUE,                    -- BoardGameGeek ID
  name             TEXT NOT NULL,
  description      TEXT,
  thumbnail_url    TEXT,
  image_url        TEXT,

  -- Game metadata
  min_players      INTEGER CHECK (min_players >= 1),
  max_players      INTEGER CHECK (max_players >= 1),
  min_playtime     INTEGER CHECK (min_playtime >= 0), -- minutes
  max_playtime     INTEGER CHECK (max_playtime >= 0), -- minutes
  min_age          INTEGER CHECK (min_age >= 0),
  complexity_rating NUMERIC(3, 2) CHECK (complexity_rating >= 1 AND complexity_rating <= 5),
  bgg_rating       NUMERIC(4, 2) CHECK (bgg_rating >= 0 AND bgg_rating <= 10),
  year_published   INTEGER,

  -- Categorization
  genres           game_genre[],
  categories       TEXT[],
  mechanics        TEXT[],
  designers        TEXT[],
  publishers       TEXT[],

  -- Flags
  is_expansion     BOOLEAN NOT NULL DEFAULT FALSE,
  base_game_id     UUID REFERENCES public.games(id),

  -- Timestamps
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT player_count_valid CHECK (
    min_players IS NULL OR
    max_players IS NULL OR
    min_players <= max_players
  ),
  CONSTRAINT playtime_valid CHECK (
    min_playtime IS NULL OR
    max_playtime IS NULL OR
    min_playtime <= max_playtime
  )
);

COMMENT ON TABLE public.games IS 'Board game catalog, optionally synced with BoardGameGeek API';
COMMENT ON COLUMN public.games.bgg_id IS 'BoardGameGeek.com game identifier for API sync';

-- ============================================================
-- USER GAME COLLECTION TABLE
-- Tracks games users own, want, or have played
-- ============================================================

CREATE TABLE public.user_game_collection (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  game_id          UUID NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
  status           collection_status NOT NULL DEFAULT 'owned',
  personal_rating  INTEGER CHECK (personal_rating >= 1 AND personal_rating <= 10),
  notes            TEXT,
  times_played     INTEGER NOT NULL DEFAULT 0 CHECK (times_played >= 0),
  willing_to_bring  BOOLEAN NOT NULL DEFAULT TRUE,  -- will bring to sessions
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(profile_id, game_id, status)
);

COMMENT ON TABLE public.user_game_collection IS 'Games associated with a user profile by ownership/interest status';
COMMENT ON COLUMN public.user_game_collection.willing_to_bring IS 'Whether the user is willing to bring this game to in-person sessions';

-- ============================================================
-- USER RATINGS TABLE
-- Peer ratings after game sessions
-- ============================================================

CREATE TABLE public.user_ratings (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rater_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rated_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  session_id       UUID,                              -- FK added after sessions table exists
  rating           INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment          TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT no_self_rating CHECK (rater_id != rated_id),
  UNIQUE(rater_id, rated_id, session_id)
);

COMMENT ON TABLE public.user_ratings IS 'User-to-user ratings submitted after game sessions';

-- ============================================================
-- PROFILE FOLLOWS TABLE
-- Social graph between users
-- ============================================================

CREATE TABLE public.profile_follows (
  follower_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (follower_id, following_id),
  CONSTRAINT no_self_follow CHECK (follower_id != following_id)
);

COMMENT ON TABLE public.profile_follows IS 'Social follow relationships between user profiles';

-- ============================================================
-- INDEXES
-- ============================================================

-- Profiles
CREATE INDEX idx_profiles_username ON public.profiles USING btree (username);
CREATE INDEX idx_profiles_location ON public.profiles USING GIST (location);
CREATE INDEX idx_profiles_experience_level ON public.profiles USING btree (experience_level);
CREATE INDEX idx_profiles_looking_for_group ON public.profiles USING btree (is_looking_for_group) WHERE is_looking_for_group = TRUE;
CREATE INDEX idx_profiles_active ON public.profiles USING btree (is_active) WHERE is_active = TRUE;
CREATE INDEX idx_profiles_country_state ON public.profiles USING btree (country, state_province);
CREATE INDEX idx_profiles_username_trgm ON public.profiles USING GIN (username gin_trgm_ops);
CREATE INDEX idx_profiles_display_name_trgm ON public.profiles USING GIN (display_name gin_trgm_ops);

-- Gaming preferences
CREATE INDEX idx_gaming_preferences_profile ON public.gaming_preferences USING btree (profile_id);
CREATE INDEX idx_gaming_preferences_genre ON public.gaming_preferences USING btree (genre);

-- Games
CREATE INDEX idx_games_bgg_id ON public.games USING btree (bgg_id);
CREATE INDEX idx_games_name_trgm ON public.games USING GIN (name gin_trgm_ops);
CREATE INDEX idx_games_genres ON public.games USING GIN (genres);
CREATE INDEX idx_games_categories ON public.games USING GIN (categories);
CREATE INDEX idx_games_mechanics ON public.games USING GIN (mechanics);
CREATE INDEX idx_games_complexity ON public.games USING btree (complexity_rating);
CREATE INDEX idx_games_bgg_rating ON public.games USING btree (bgg_rating DESC);
CREATE INDEX idx_games_year ON public.games USING btree (year_published DESC);

-- User game collection
CREATE INDEX idx_user_game_collection_profile ON public.user_game_collection USING btree (profile_id);
CREATE INDEX idx_user_game_collection_game ON public.user_game_collection USING btree (game_id);
CREATE INDEX idx_user_game_collection_status ON public.user_game_collection USING btree (profile_id, status);
CREATE INDEX idx_user_game_collection_bring ON public.user_game_collection USING btree (profile_id, willing_to_bring) WHERE willing_to_bring = TRUE;

-- User ratings
CREATE INDEX idx_user_ratings_rater ON public.user_ratings USING btree (rater_id);
CREATE INDEX idx_user_ratings_rated ON public.user_ratings USING btree (rated_id);
CREATE INDEX idx_user_ratings_session ON public.user_ratings USING btree (session_id);

-- Profile follows
CREATE INDEX idx_profile_follows_follower ON public.profile_follows USING btree (follower_id);
CREATE INDEX idx_profile_follows_following ON public.profile_follows USING btree (following_id);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_games_updated_at
  BEFORE UPDATE ON public.games
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_user_game_collection_updated_at
  BEFORE UPDATE ON public.user_game_collection
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_user_ratings_updated_at
  BEFORE UPDATE ON public.user_ratings
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Auto-create profile when a new auth user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_username TEXT;
  v_counter  INTEGER := 0;
  v_base     TEXT;
BEGIN
  -- Derive a base username from email or metadata
  v_base := COALESCE(
    NEW.raw_user_meta_data->>'username',
    LOWER(SPLIT_PART(NEW.email, '@', 1))
  );

  -- Sanitize: keep only alphanumeric, underscore, hyphen; truncate to 25 chars
  v_base := REGEXP_REPLACE(v_base, '[^a-zA-Z0-9_-]', '_', 'g');
  v_base := LEFT(v_base, 25);

  -- Ensure minimum length
  IF LENGTH(v_base) < 3 THEN
    v_base := 'user_' || v_base;
  END IF;

  v_username := v_base;

  -- Resolve username collisions
  LOOP
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username);
    v_counter  := v_counter + 1;
    v_username := v_base || '_' || v_counter;
  END LOOP;

  INSERT INTO public.profiles (
    id,
    username,
    display_name,
    avatar_url
  ) VALUES (
    NEW.id,
    v_username,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      v_username
    ),
    NEW.raw_user_meta_data->>'avatar_url'
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Recalculate average rating on insert/update/delete of user_ratings
CREATE OR REPLACE FUNCTION public.refresh_user_average_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_target_id UUID;
BEGIN
  -- Determine which profile was affected
  IF TG_OP = 'DELETE' THEN
    v_target_id := OLD.rated_id;
  ELSE
    v_target_id := NEW.rated_id;
  END IF;

  UPDATE public.profiles
  SET
    average_rating = (
      SELECT AVG(rating)::NUMERIC(3,2)
      FROM public.user_ratings
      WHERE rated_id = v_target_id
    ),
    total_ratings = (
      SELECT COUNT(*)
      FROM public.user_ratings
      WHERE rated_id = v_target_id
    )
  WHERE id = v_target_id;

  RETURN NULL;
END;
$$;

CREATE TRIGGER trg_refresh_user_rating_insert
  AFTER INSERT ON public.user_ratings
  FOR EACH ROW EXECUTE FUNCTION public.refresh_user_average_rating();

CREATE TRIGGER trg_refresh_user_rating_update
  AFTER UPDATE ON public.user_ratings
  FOR EACH ROW EXECUTE FUNCTION public.refresh_user_average_rating();

CREATE TRIGGER trg_refresh_user_rating_delete
  AFTER DELETE ON public.user_ratings
  FOR EACH ROW EXECUTE FUNCTION public.refresh_user_average_rating();
