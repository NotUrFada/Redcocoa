-- Add video_urls to profiles for video support
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS video_urls text[] DEFAULT '{}';
