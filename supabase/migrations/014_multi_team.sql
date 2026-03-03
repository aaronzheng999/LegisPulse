-- ============================================================
-- Multi-team support + Team rename
-- 1) Removes single-team constraint from join_team_by_code
-- 2) Simplifies accept_my_team_invites (no longer leaves existing teams)
-- 3) Adds rename_team RPC (owner only)
-- Run in Supabase SQL Editor.
-- ============================================================

-- 1) Replace join_team_by_code: allow user to be in multiple teams
create or replace function public.join_team_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_team_id uuid;
  v_email   text;
  v_already boolean;
begin
  -- Find the team (case-insensitive)
  select id into v_team_id
  from public.teams
  where upper(team_code) = upper(trim(p_code));

  if v_team_id is null then
    raise exception 'No team found with that code.';
  end if;

  -- Check if caller is already in THIS team
  select exists(
    select 1 from public.team_members
    where team_id = v_team_id
      and user_id = auth.uid()
      and status  = 'active'
  ) into v_already;

  if v_already then
    raise exception 'You are already a member of this team.';
  end if;

  -- Get the user's email
  select email into v_email from auth.users where id = auth.uid();

  -- Insert as active member
  insert into public.team_members (team_id, user_id, email, role, status)
  values (v_team_id, auth.uid(), v_email, 'member', 'active');

  return v_team_id;
end;
$$;

-- 2) Replace accept_my_team_invites: just activate pending invites
--    without leaving existing teams
create or replace function public.accept_my_team_invites()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Activate all pending invites for this email address
  update public.team_members
  set    user_id = auth.uid(),
         status  = 'active'
  where  status  = 'pending'
    and  lower(email) = lower(
           (select email from auth.users where id = auth.uid())
         );
end;
$$;

-- 3) Rename team (owner only)
create or replace function public.rename_team(p_team_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Verify caller is the team owner
  if not exists(
    select 1 from public.teams
    where id = p_team_id and created_by = auth.uid()
  ) then
    raise exception 'Only the team owner can rename the team.';
  end if;

  if trim(p_name) = '' then
    raise exception 'Team name cannot be empty.';
  end if;

  update public.teams
  set name = trim(p_name)
  where id = p_team_id;
end;
$$;
