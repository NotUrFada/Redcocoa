-- Passed users (discovery pass/skip)
create table public.passed_users (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  passed_id uuid references public.profiles on delete cascade not null,
  created_at timestamptz default now(),
  unique(user_id, passed_id)
);

alter table public.passed_users enable row level security;

create policy "Users can manage own passed" on public.passed_users for all using (auth.uid() = user_id);

-- Storage bucket for profile photos
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Allow authenticated users to upload their own photos
create policy "Users can upload own avatar"
on storage.objects for insert
with check (
  bucket_id = 'avatars' and
  auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Avatar images are publicly readable"
on storage.objects for select
using (bucket_id = 'avatars');

create policy "Users can update own avatar"
on storage.objects for update
using (auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can delete own avatar"
on storage.objects for delete
using (auth.uid()::text = (storage.foldername(name))[1]);
