-- ============================================================
-- Join-by-code now requires owner approval
-- 1) join_team_by_code inserts as 'pending_approval'
-- 2) approve_join_request: owner activates a pending request
-- 3) decline_join_request: owner removes a pending request
-- Run in Supabase SQL Editor.
-- ============================================================

-- 1) Replace join_team_by_code: insert as pending_approval instead of active
create or replace function public.join_team_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_team_id uuid;
  v_email   text;
  v_existing text;
begin
  -- Find the team (case-insensitive)
  select id into v_team_id
  from public.teams
  where upper(team_code) = upper(trim(p_code));

  if v_team_id is null then
    raise exception 'No team found with that code.';
  end if;

  -- Check if caller already has a relationship with this team
  select status into v_existing
  from public.team_members
  where team_id = v_team_id
    and user_id = auth.uid()
  limit 1;

  if v_existing = 'active' then
    raise exception 'You are already a member of this team.';
  end if;

  if v_existing = 'pending_approval' then
    raise exception 'Your join request is already pending approval.';
  end if;

  -- Get the user's email
  select email into v_email from auth.users where id = auth.uid();

  -- Insert as pending_approval (owner must approve)
  insert into public.team_members (team_id, user_id, email, role, status)
  values (v_team_id, auth.uid(), v_email, 'member', 'pending_approval');

  return v_team_id;
end;
$$;

-- 2) Approve a join request (owner only)
create or replace function public.approve_join_request(p_member_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_team_id uuid;
begin
  -- Get the team_id from the pending request
  select team_id into v_team_id
  from public.team_members
  where id = p_member_id
    and status = 'pending_approval';

  if v_team_id is null then
    raise exception 'Join request not found or already processed.';
  end if;

  -- Verify caller is the team owner
  if not exists(
    select 1 from public.teams
    where id = v_team_id and created_by = auth.uid()
  ) then
    raise exception 'Only the team owner can approve join requests.';
  end if;

  -- Activate the member
  update public.team_members
  set status = 'active', joined_at = now()
  where id = p_member_id;
end;
$$;

-- 3) Decline a join request (owner only)
create or replace function public.decline_join_request(p_member_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_team_id uuid;
begin
  -- Get the team_id from the pending request
  select team_id into v_team_id
  from public.team_members
  where id = p_member_id
    and status = 'pending_approval';

  if v_team_id is null then
    raise exception 'Join request not found or already processed.';
  end if;

  -- Verify caller is the team owner
  if not exists(
    select 1 from public.teams
    where id = v_team_id and created_by = auth.uid()
  ) then
    raise exception 'Only the team owner can decline join requests.';
  end if;

  -- Remove the request
  delete from public.team_members
  where id = p_member_id;
end;
$$;
