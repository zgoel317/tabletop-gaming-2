-- Create game genre enum
CREATE TYPE game_genre AS ENUM (
  'strategy',
  'cooperative',
  'party',
  'rpg',
  'deck_building',
  'miniatures',
  'war_games',
  'card_games',
  'dice_games',
  'word_games',
  'trivia',
  'other'
);

-- Create play style enum
CREATE TYPE play_style AS ENUM ('casual', 'competitive', 'narrative', 'social');

-- Create gaming preferences table
CREATE TABLE gaming_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  favorite_genres game_genre[] DEFAULT '{}',
  preferred_play_styles play_style[] DEFAULT '{}',
  min_players INTEGER,
  max_players INTEGER,
  preferred_session_length_minutes INTEGER,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE gaming_preferences ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Gaming preferences are viewable by everyone"
  ON gaming_preferences FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own preferences"
  ON gaming_preferences FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences"
  ON gaming_preferences FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own preferences"
  ON gaming_preferences FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Attach updated_at trigger
CREATE TRIGGER update_gaming_preferences_updated_at
  BEFORE UPDATE ON gaming_preferences
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();
