-- SECURITY DEFINER function to create call invites (bypasses RLS)
-- Fixes: "new row violates row-level security policy for table 'call_invites'"
-- auth.uid() is still validated inside the function; this avoids RLS policy issues

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
  -- Verify caller matches authenticated user (case-insensitive)
  if lower(trim(v_uid)) != lower(trim(create_call_invite.caller_id)) then
    raise exception 'caller_id must match authenticated user';
  end if;
  -- Verify caller is in the match
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
