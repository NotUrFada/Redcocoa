-- Onboarding & consent
alter table public.profiles
  add column if not exists humor_preference text,  -- 'love' | 'sometimes' | 'not_for_me'
  add column if not exists tone_vibe text;         -- 'playful' | 'dry' | 'soft' | 'serious'

-- Profile features
alter table public.profiles
  add column if not exists prompt_responses jsonb default '{}',  -- { promptId: response }
  add column if not exists badges text[] default '{}',             -- 1-2 max
  add column if not exists debunked_lines text[] default '{}',   -- 1-3 short lines
  add column if not exists not_here_for jsonb default '{}';       -- { "explain": "", "dont_message": "", "red_flag": "" }

-- Preferences for discovery filters
alter table public.preferences
  add column if not exists filter_enjoys_humor boolean,
  add column if not exists filter_likes_banter boolean,
  add column if not exists filter_culture_aware boolean,
  add column if not exists filter_tone text[] default '{}',
  add column if not exists filter_dating_intentionally boolean,
  add column if not exists filter_emotionally_available boolean,
  add column if not exists filter_here_for_real boolean;
