-- ============================================================
-- STORAGE BUCKETS FOR USER MEDIA
-- ============================================================

-- Avatars bucket for profile pictures
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  TRUE, -- Public bucket so avatars can be accessed without auth
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
);

-- Game images bucket (for custom game images)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'game-images',
  'game-images',
  TRUE,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
);

-- ============================================================
-- STORAGE RLS POLICIES
-- ============================================================

-- AVATARS BUCKET

-- Anyone can view avatars (public bucket)
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'avatars');

-- Users can upload their own avatar
-- File path must be: {user_id}/{filename}
CREATE POLICY "Users can upload their own avatar"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- Users can update their own avatar
CREATE POLICY "Users can update their own avatar"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- Users can delete their own avatar
CREATE POLICY "Users can delete their own avatar"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- GAME IMAGES BUCKET

-- Anyone can view game images (public bucket)
CREATE POLICY "Game images are publicly accessible"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'game-images');

-- Authenticated users can upload game images
CREATE POLICY "Authenticated users can upload game images"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'game-images');

-- Users can update game images they uploaded
CREATE POLICY "Users can update their own game images"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'game-images'
    AND owner = auth.uid()
  );

-- Users can delete game images they uploaded
CREATE POLICY "Users can delete their own game images"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'game-images'
    AND owner = auth.uid()
  );
