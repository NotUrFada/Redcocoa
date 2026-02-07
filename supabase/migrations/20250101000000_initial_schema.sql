-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Profiles (extends auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  birth_date date,
  bio text,
  location text,
  latitude float,
  longitude float,
  height text,
  zodiac_sign text,
  education text,
  job text,
  intent text default 'Long-term',
  drinking text,
  smoking text,
  interests text[],
  photo_urls text[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Discovery preferences
create table public.preferences (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles on delete cascade unique,
  age_min int default 18,
  age_max int default 60,
  max_distance_miles int default 25,
  interested_in text[] default array['Everyone']
);

-- Likes (who liked whom)
create table public.likes (
  id uuid default uuid_generate_v4() primary key,
  from_user_id uuid references public.profiles on delete cascade not null,
  to_user_id uuid references public.profiles on delete cascade not null,
  created_at timestamptz default now(),
  unique(from_user_id, to_user_id)
);

-- Matches (mutual likes)
create table public.matches (
  id uuid default uuid_generate_v4() primary key,
  user1_id uuid references public.profiles on delete cascade not null,
  user2_id uuid references public.profiles on delete cascade not null,
  created_at timestamptz default now(),
  unique(user1_id, user2_id)
);

-- Messages
create table public.messages (
  id uuid default uuid_generate_v4() primary key,
  match_id uuid references public.matches on delete cascade not null,
  sender_id uuid references public.profiles on delete cascade not null,
  content text not null,
  read_at timestamptz,
  created_at timestamptz default now()
);

-- Blocked users
create table public.blocked_users (
  id uuid default uuid_generate_v4() primary key,
  blocker_id uuid references public.profiles on delete cascade not null,
  blocked_id uuid references public.profiles on delete cascade not null,
  created_at timestamptz default now(),
  unique(blocker_id, blocked_id)
);

-- Reports
create table public.reports (
  id uuid default uuid_generate_v4() primary key,
  reporter_id uuid references public.profiles on delete cascade not null,
  reported_id uuid references public.profiles on delete cascade not null,
  reason text,
  details text,
  status text default 'pending',
  created_at timestamptz default now()
);

-- RLS policies
alter table public.profiles enable row level security;
alter table public.preferences enable row level security;
alter table public.likes enable row level security;
alter table public.matches enable row level security;
alter table public.messages enable row level security;
alter table public.blocked_users enable row level security;
alter table public.reports enable row level security;

-- Profiles: users can read all, update own
create policy "Profiles are viewable by everyone" on public.profiles for select using (true);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

-- Preferences
create policy "Users can manage own preferences" on public.preferences for all using (auth.uid() = user_id);

-- Likes
create policy "Users can manage own likes" on public.likes for all using (auth.uid() = from_user_id);
create policy "Users can see likes to them" on public.likes for select using (auth.uid() = to_user_id or auth.uid() = from_user_id);

-- Matches
create policy "Users can see own matches" on public.matches for select using (auth.uid() = user1_id or auth.uid() = user2_id);

-- Messages
create policy "Users can see messages in their matches" on public.messages for select using (
  exists (
    select 1 from public.matches m
    where m.id = match_id and (m.user1_id = auth.uid() or m.user2_id = auth.uid())
  )
);
create policy "Users can send messages in their matches" on public.messages for insert with check (
  auth.uid() = sender_id and exists (
    select 1 from public.matches m
    where m.id = match_id and (m.user1_id = auth.uid() or m.user2_id = auth.uid())
  )
);

-- Blocked
create policy "Users can manage own blocks" on public.blocked_users for all using (auth.uid() = blocker_id);

-- Reports
create policy "Users can create reports" on public.reports for insert with check (auth.uid() = reporter_id);

-- Trigger to create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', 'User'));
  insert into public.preferences (user_id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
