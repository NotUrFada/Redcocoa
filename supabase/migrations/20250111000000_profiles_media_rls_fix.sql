-- Fix "new row violates row-level security policy" when uploading profile photos
-- Run this in Supabase Dashboard > SQL Editor if migrations aren't applied

-- 1. Profiles: ensure INSERT and UPDATE policies allow own profile updates
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Also handle legacy policy names from initial schema
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles
  FOR SELECT USING (true);

-- 2. Storage avatars: ensure upload policy allows inserts to user folder
-- Path format: userId/timestamp.jpg or userId/videos/timestamp.mp4
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND lower((string_to_array(name, '/'))[1]) = lower(auth.uid()::text)
  );

-- Allow UPDATE (overwrite) in case client overwrites
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND lower((string_to_array(name, '/'))[1]) = lower(auth.uid()::text)
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND lower((string_to_array(name, '/'))[1]) = lower(auth.uid()::text)
  );

-- Allow users to delete their own avatar files (required for account deletion)
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND lower((string_to_array(name, '/'))[1]) = lower(auth.uid()::text)
  );
