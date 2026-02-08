-- Run this in Supabase SQL Editor (Dashboard > SQL Editor) to fix RLS and profile creation

-- 1. Ensure profiles table exists and has correct structure
-- (Skip if you already have profiles from migrations)

-- 2. Create profile on signup (run if you don't have this trigger)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Profiles RLS (fixes "new row violates row-level security policy" on photo upload)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 4. Storage avatars bucket - allow authenticated users to upload to their folder
-- First ensure the bucket exists (run in Supabase Dashboard > Storage if needed)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'avatars') THEN
    INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
  END IF;
END $$;

DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND lower((string_to_array(name, '/'))[1]) = lower(auth.uid()::text)
  );

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

DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND lower((string_to_array(name, '/'))[1]) = lower(auth.uid()::text)
  );

DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

-- 5. Matches RLS - users can read/write matches they're part of
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own matches" ON public.matches;
CREATE POLICY "Users can view own matches" ON public.matches
  FOR SELECT USING (
    auth.uid()::text = user1_id OR auth.uid()::text = user2_id
  );

DROP POLICY IF EXISTS "Users can insert matches" ON public.matches;
CREATE POLICY "Users can insert matches" ON public.matches
  FOR INSERT WITH CHECK (
    auth.uid()::text = user1_id OR auth.uid()::text = user2_id
  );

-- 6. Messages RLS - users in a match can read/write messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view messages in their matches" ON public.messages;
CREATE POLICY "Users can view messages in their matches" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = match_id
      AND (auth.uid()::text = m.user1_id OR auth.uid()::text = m.user2_id)
    )
  );

DROP POLICY IF EXISTS "Users can send messages in their matches" ON public.messages;
CREATE POLICY "Users can send messages in their matches" ON public.messages
  FOR INSERT WITH CHECK (
    auth.uid()::text = sender_id
    AND EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = match_id
      AND (auth.uid()::text = m.user1_id OR auth.uid()::text = m.user2_id)
    )
  );

-- 6b. Call invites RLS - caller/callee in a match can manage call invites
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'call_invites') THEN
    ALTER TABLE public.call_invites ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Caller can create call invite" ON public.call_invites;
    CREATE POLICY "Caller can create call invite" ON public.call_invites
      FOR INSERT WITH CHECK (
        auth.uid()::text = caller_id::text
        AND EXISTS (
          SELECT 1 FROM public.matches m
          WHERE m.id::text = match_id::text
          AND (auth.uid()::text = m.user1_id::text OR auth.uid()::text = m.user2_id::text)
        )
      );
    DROP POLICY IF EXISTS "Caller and callee can view call invites" ON public.call_invites;
    CREATE POLICY "Caller and callee can view call invites" ON public.call_invites
      FOR SELECT USING (
        auth.uid()::text = caller_id::text OR auth.uid()::text = callee_id::text
      );
    DROP POLICY IF EXISTS "Caller and callee can update call invites" ON public.call_invites;
    CREATE POLICY "Caller and callee can update call invites" ON public.call_invites
      FOR UPDATE USING (
        auth.uid()::text = caller_id::text OR auth.uid()::text = callee_id::text
      );
  END IF;
END $$;

-- 7. Likes, passed_users, blocked_users (if tables exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'likes') THEN
    ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Users can manage own likes" ON public.likes;
    CREATE POLICY "Users can manage own likes" ON public.likes
      FOR ALL USING (auth.uid()::text = from_user_id);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'passed_users') THEN
    ALTER TABLE public.passed_users ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Users can manage own passes" ON public.passed_users;
    CREATE POLICY "Users can manage own passes" ON public.passed_users
      FOR ALL USING (auth.uid()::text = user_id);
  END IF;
END $$;
