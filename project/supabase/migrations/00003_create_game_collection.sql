-- Create collection status enum
CREATE TYPE collection_status AS ENUM ('owned', 'wishlist', 'previously_owned', 'want_to_play');

-- Create game collection table
CREATE TABLE game_collection (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_name TEXT NOT NULL,
  bgg_id INTEGER,
  status collection_status DEFAULT 'owned',
  rating INTEGER CHECK (rating >= 1 AND rating <= 10),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, game_name)
);

-- Enable RLS
ALTER TABLE game_collection ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Game collections are viewable by everyone"
  ON game_collection FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own collection items"
  ON game_collection FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own collection items"
  ON game_collection FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own collection items"
  ON game_collection FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Attach updated_at trigger
CREATE TRIGGER update_game_collection_updated_at
  BEFORE UPDATE ON game_collection
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- Create indexes
CREATE INDEX idx_game_collection_user_id ON game_collection(user_id);
CREATE INDEX idx_game_collection_bgg_id ON game_collection(bgg_id);
