-- Fix call_invites RLS - run this in Supabase SQL Editor
-- Option A: Use create_call_invite RPC (recommended - bypasses RLS for inserts)
-- The app now uses create_call_invite() instead of direct insert.
-- Run the migration 20250113000000_call_invites_create_rpc.sql, or run below:

create or replace function public.create_call_invite(
  match_id uuid,
  caller_id text,
  callee_id text,
  channel_name text,
  call_type text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_uid text;
begin
  v_uid := coalesce(auth.uid()::text, '');
  if v_uid = '' or v_uid is null then
    raise exception 'Not authenticated';
  end if;
  if lower(trim(v_uid)) != lower(trim(create_call_invite.caller_id)) then
    raise exception 'caller_id must match authenticated user';
  end if;
  if not exists (
    select 1 from public.matches m
    where m.id = create_call_invite.match_id
      and (lower(m.user1_id::text) = lower(trim(create_call_invite.caller_id)) or lower(m.user2_id::text) = lower(trim(create_call_invite.caller_id)))
  ) then
    raise exception 'Caller must be in the match';
  end if;
  insert into public.call_invites (match_id, caller_id, callee_id, channel_name, call_type, status)
  values (create_call_invite.match_id, trim(create_call_invite.caller_id), trim(create_call_invite.callee_id), create_call_invite.channel_name, create_call_invite.call_type, 'ringing')
  returning id into v_id;
  return v_id;
end;
$$;

-- Option B: If you prefer RLS policies instead of RPC, run the policy block below:
-- (Only needed if reverting to direct insert)

-- ALTER TABLE public.call_invites ENABLE ROW LEVEL SECURITY;
-- DROP POLICY IF EXISTS "call_invites_read" ON public.call_invites;
-- DROP POLICY IF EXISTS "call_invites_insert" ON public.call_invites;
-- DROP POLICY IF EXISTS "call_invites_update" ON public.call_invites;
-- DROP POLICY IF EXISTS "call_invites_select" ON public.call_invites;
-- DROP POLICY IF EXISTS "Caller can create call invite" ON public.call_invites;
-- DROP POLICY IF EXISTS "Caller and callee can view call invites" ON public.call_invites;
-- DROP POLICY IF EXISTS "Caller and callee can update call invites" ON public.call_invites;
-- CREATE POLICY "call_invites_select" ON public.call_invites FOR SELECT USING (auth.uid()::text = caller_id OR auth.uid()::text = callee_id);
-- CREATE POLICY "call_invites_insert" ON public.call_invites FOR INSERT WITH CHECK (auth.uid()::text = caller_id);
-- CREATE POLICY "call_invites_update" ON public.call_invites FOR UPDATE USING (auth.uid()::text = caller_id OR auth.uid()::text = callee_id);
