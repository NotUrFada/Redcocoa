-- Add ethnicity and hair_color to profiles
alter table public.profiles
  add column if not exists ethnicity text,
  add column if not exists hair_color text;

-- Add discovery preferences for ethnicity and hair color
alter table public.preferences
  add column if not exists preferred_ethnicities text[] default '{}',
  add column if not exists preferred_hair_colors text[] default '{}';
