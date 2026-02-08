-- Device tokens for push notifications (lock screen, etc.)
create table if not exists public.user_device_tokens (
  user_id uuid primary key references auth.users(id) on delete cascade,
  token text not null,
  updated_at timestamptz not null default now()
);

alter table public.user_device_tokens enable row level security;

create policy "Users can manage own device token" on public.user_device_tokens
  for all using (auth.uid() = user_id);
