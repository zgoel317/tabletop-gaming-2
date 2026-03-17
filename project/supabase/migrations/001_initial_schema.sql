-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create custom types
CREATE TYPE experience_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert');
CREATE TYPE availability_status AS ENUM ('available', 'busy', 'away');

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    location TEXT,
    location_coords POINT,
    phone TEXT,
    date_of_birth DATE,
    is_active BOOLEAN DEFAULT true,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Gaming preferences
CREATE TABLE public.gaming_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    favorite_genres TEXT[],
    experience_level experience_level DEFAULT 'beginner',
    preferred_game_duration INTEGER, -- minutes
    max_travel_distance INTEGER, -- km
    preferred_group_size_min INTEGER DEFAULT 2,
    preferred_group_size_max INTEGER DEFAULT 8,
    availability_status availability_status DEFAULT 'available',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User availability schedule
CREATE TABLE public.user_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, day_of_week, start_time, end_time)
);

-- Games catalog
CREATE TABLE public.games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bgg_id INTEGER UNIQUE, -- BoardGameGeek ID
    name TEXT NOT NULL,
    description TEXT,
    min_players INTEGER NOT NULL DEFAULT 1,
    max_players INTEGER NOT NULL DEFAULT 1,
    min_age INTEGER,
    playing_time INTEGER, -- minutes
    complexity_rating DECIMAL(3,2), -- 1.00 to 5.00
    year_published INTEGER,
    image_url TEXT,
    categories TEXT[],
    mechanics TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User game collection
CREATE TABLE public.user_games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    game_id UUID REFERENCES public.games(id) ON DELETE CASCADE,
    ownership_status TEXT NOT NULL CHECK (ownership_status IN ('owned', 'wishlist', 'previously_owned')),
    rating INTEGER CHECK (rating >= 1 AND rating <= 10),
    plays_count INTEGER DEFAULT 0,
    notes TEXT,
    acquired_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, game_id)
);

-- User ratings and reviews
CREATE TABLE public.user_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reviewer_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    reviewee_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    session_id UUID, -- Reference to game session if applicable
    is_anonymous BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (reviewer_id != reviewee_id)
);

-- Create indexes for better performance
CREATE INDEX idx_users_location ON public.users USING GIST (location_coords);
CREATE INDEX idx_users_username ON public.users (username);
CREATE INDEX idx_users_active ON public.users (is_active);
CREATE INDEX idx_gaming_preferences_user ON public.gaming_preferences (user_id);
CREATE INDEX idx_user_availability_user_day ON public.user_availability (user_id, day_of_week);
CREATE INDEX idx_games_bgg_id ON public.games (bgg_id);
CREATE INDEX idx_games_name ON public.games (name);
CREATE INDEX idx_user_games_user ON public.user_games (user_id);
CREATE INDEX idx_user_games_game ON public.user_games (game_id);
CREATE INDEX idx_user_games_ownership ON public.user_games (ownership_status);
CREATE INDEX idx_user_reviews_reviewer ON public.user_reviews (reviewer_id);
CREATE INDEX idx_user_reviews_reviewee ON public.user_reviews (reviewee_id);

-- Row Level Security (RLS) policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gaming_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reviews ENABLE ROW LEVEL SECURITY;

-- Users can read their own data and public profiles of others
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can view public profiles" ON public.users
    FOR SELECT USING (is_active = true);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Gaming preferences policies
CREATE POLICY "Users can manage own gaming preferences" ON public.gaming_preferences
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view others' gaming preferences" ON public.gaming_preferences
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM public.users u 
        WHERE u.id = user_id AND u.is_active = true
    ));

-- User availability policies
CREATE POLICY "Users can manage own availability" ON public.user_availability
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view others' availability" ON public.user_availability
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM public.users u 
        WHERE u.id = user_id AND u.is_active = true
    ));

-- Games table is public read
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Games are publicly readable" ON public.games
    FOR SELECT TO authenticated USING (true);

-- User games policies
CREATE POLICY "Users can manage own game collection" ON public.user_games
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view others' game collections" ON public.user_games
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM public.users u 
        WHERE u.id = user_id AND u.is_active = true
    ));

-- User reviews policies
CREATE POLICY "Users can create reviews" ON public.user_reviews
    FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

CREATE POLICY "Users can view reviews" ON public.user_reviews
    FOR SELECT USING (true); -- Reviews are public

CREATE POLICY "Users can update own reviews" ON public.user_reviews
    FOR UPDATE USING (auth.uid() = reviewer_id);

CREATE POLICY "Users can delete own reviews" ON public.user_reviews
    FOR DELETE USING (auth.uid() = reviewer_id);

-- Functions
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
        NEW.raw_user_meta_data->>'avatar_url'
    );
    
    -- Create default gaming preferences
    INSERT INTO public.gaming_preferences (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_gaming_preferences_updated_at
    BEFORE UPDATE ON public.gaming_preferences
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_games_updated_at
    BEFORE UPDATE ON public.games
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_games_updated_at
    BEFORE UPDATE ON public.user_games
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_reviews_updated_at
    BEFORE UPDATE ON public.user_reviews
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();