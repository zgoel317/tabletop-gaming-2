-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
-- Configure Supabase Storage buckets for avatar images.
-- Supabase Storage is managed through the API or dashboard;
-- the SQL below uses the internal storage schema helpers
-- available in self-hosted and cloud Supabase instances.

-- Avatar images bucket (public read, authenticated write)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  TRUE,                                     -- public bucket: no signed URLs needed
  2097152,                                  -- 2 MB limit per file
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Game images bucket (public read, admin write only)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'game-images',
  'game-images',
  TRUE,
  5242880,                                  -- 5 MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STORAGE RLS POLICIES
-- ============================================================

-- AVATARS
-- Anyone can view avatar images (bucket is public but policies still apply to API)
CREATE POLICY "avatars_select_public"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'avatars');

-- Authenticated users can upload to their own folder: avatars/<user_id>/*
CREATE POLICY "avatars_insert_own"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- Users can update their own avatars
CREATE POLICY "avatars_update_own"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- Users can delete their own avatars
CREATE POLICY "avatars_delete_own"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- GAME IMAGES
-- Anyone can view game images
CREATE POLICY "game_images_select_public"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'game-images');

-- Only admins can upload/modify game images
CREATE POLICY "game_images_insert_admin"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'game-images'
    AND public.is_admin()
  );

CREATE POLICY "game_images_update_admin"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'game-images'
    AND public.is_admin()
  );

CREATE POLICY "game_images_delete_admin"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'game-images'
    AND public.is_admin()
  );
