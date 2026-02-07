-- Allow users to create/update matches they are part of (needed when mutual like occurs)
create policy "Users can create matches they are part of"
  on public.matches for insert
  with check (auth.uid() = user1_id or auth.uid() = user2_id);

create policy "Users can update matches they are part of"
  on public.matches for update
  using (auth.uid() = user1_id or auth.uid() = user2_id);
