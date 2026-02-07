-- Add phone to profiles for reliable storage
alter table public.profiles
  add column if not exists phone text;
