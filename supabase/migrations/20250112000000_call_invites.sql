-- Call invites for in-app voice/video signaling
create table if not exists public.call_invites (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  channel_name text not null,
  caller_id text not null,
  callee_id text not null,
  call_type text not null check (call_type in ('voice', 'video')),
  status text not null default 'ringing' check (status in ('ringing', 'active', 'ended', 'missed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.update_call_invites_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger call_invites_updated_at
  before update on public.call_invites
  for each row execute procedure public.update_call_invites_updated_at();

create index if not exists idx_call_invites_callee on public.call_invites(callee_id);
create index if not exists idx_call_invites_match on public.call_invites(match_id);

-- Enable realtime for incoming call notifications
alter publication supabase_realtime add table public.call_invites;

-- RLS
alter table public.call_invites enable row level security;

-- Caller and callee can read their invites
create policy "call_invites_read" on public.call_invites
  for select using (
    auth.uid()::text = caller_id or auth.uid()::text = callee_id
  );

-- Authenticated users can create (as caller)
create policy "call_invites_insert" on public.call_invites
  for insert with check (auth.uid()::text = caller_id);

-- Caller and callee can update (answer, end)
create policy "call_invites_update" on public.call_invites
  for update using (
    auth.uid()::text = caller_id or auth.uid()::text = callee_id
  );
