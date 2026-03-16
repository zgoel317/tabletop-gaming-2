-- Create user ratings table
CREATE TABLE user_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reviewed_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  session_id UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CHECK (reviewer_id != reviewed_id),
  UNIQUE(reviewer_id, reviewed_id, session_id)
);

-- Enable RLS
ALTER TABLE user_ratings ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "User ratings are viewable by everyone"
  ON user_ratings FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own ratings"
  ON user_ratings FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reviewer_id);

CREATE POLICY "Users can update their own ratings"
  ON user_ratings FOR UPDATE
  TO authenticated
  USING (auth.uid() = reviewer_id);

CREATE POLICY "Users can delete their own ratings"
  ON user_ratings FOR DELETE
  TO authenticated
  USING (auth.uid() = reviewer_id);

-- Attach updated_at trigger
CREATE TRIGGER update_user_ratings_updated_at
  BEFORE UPDATE ON user_ratings
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- Create indexes
CREATE INDEX idx_user_ratings_reviewed_id ON user_ratings(reviewed_id);
CREATE INDEX idx_user_ratings_reviewer_id ON user_ratings(reviewer_id);
