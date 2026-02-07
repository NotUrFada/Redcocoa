-- Typing indicators: ephemeral table for real-time typing status
create table if not exists public.typing_indicators (
  match_id uuid references public.matches on delete cascade not null,
  user_id uuid references public.profiles on delete cascade not null,
  updated_at timestamptz default now(),
  primary key (match_id, user_id)
);

alter table public.typing_indicators enable row level security;

-- Users can insert/update/delete their own typing indicator
create policy "Users can manage own typing" on public.typing_indicators
  for all using (auth.uid() = user_id);

-- Users can see typing indicators in their matches
create policy "Users can view typing in own matches" on public.typing_indicators
  for select using (
    exists (
      select 1 from public.matches m
      where m.id = match_id and (m.user1_id = auth.uid() or m.user2_id = auth.uid())
    )
  );

-- Enable realtime for typing_indicators
alter publication supabase_realtime add table public.typing_indicators;

-- Allow users to update read_at on messages they received (sender_id != auth.uid())
create policy "Users can mark received messages as read" on public.messages
  for update using (
    auth.uid() != sender_id
    and exists (
      select 1 from public.matches m
      where m.id = match_id and (m.user1_id = auth.uid() or m.user2_id = auth.uid())
    )
  )
  with check (true);
