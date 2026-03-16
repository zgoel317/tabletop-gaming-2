-- Create day of week enum
CREATE TYPE day_of_week AS ENUM (
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday'
);

-- Create availability table
CREATE TABLE availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  day_of_week day_of_week,
  specific_date DATE,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_recurring BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CHECK (day_of_week IS NOT NULL OR specific_date IS NOT NULL)
);

-- Enable RLS
ALTER TABLE availability ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Availability is viewable by everyone"
  ON availability FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own availability"
  ON availability FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own availability"
  ON availability FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own availability"
  ON availability FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Attach updated_at trigger
CREATE TRIGGER update_availability_updated_at
  BEFORE UPDATE ON availability
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- Create indexes
CREATE INDEX idx_availability_user_id ON availability(user_id);
CREATE INDEX idx_availability_day_of_week ON availability(day_of_week);
