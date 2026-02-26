# LegisPulse

LegisPulse tracks Georgia legislative bills and provides AI-generated bill analysis. Built for Georgia legislative staff and advocates to monitor bill activity, track legislation of interest, share bills with teammates, and get instant AI summaries of bill changes.

## Current Capabilities

- **User accounts** — register, log in, and log out with email/password (powered by Supabase Auth)
- **Per-user data** — tracked bills, email lists, and notifications are stored in a cloud database, tied to your account
- **Team collaboration** — create a team, invite colleagues by email, share bills across the team
- Sync Georgia bills from LegiScan (full session, 4000+ bills via paginated fetch)
- Auto-sync on first load when no bills are in the database
- Show newest bills first (higher bill number first)
- Search by bill number/text with improved exact matching (e.g. `HB10` and `HB 10`)
- Track/untrack bills — persisted to your account across devices
- Add/remove bills to your team's shared list
- Open direct bill PDFs (uses LegiScan `getBillText` flow when available)
- Fetch and display sponsor lists (cards + details)
- Generate and regenerate AI summaries from bill text context (`summary` + `changes_analysis`)
- Instant tab navigation — data is cached in memory so switching pages does not reload from the server
- Scroll position and "load more" count are remembered when navigating away from Dashboard

## Team Feature

Each user belongs to exactly one team. The owner can invite other registered users by email.

### Flow

1. **Owner** goes to the **Team** tab → sees their team name, member list, and invite form
2. **Owner** invites a colleague by entering their email and clicking **Invite**
3. **Invited user** goes to the **Team** tab → sees a **"Team Invitation"** screen with Accept / Decline buttons
4. After accepting, the invited user sees the owner's team and all shared bills
5. Owner can remove any member using the trash icon
6. Members can leave the team via the **Leave Team** button

### Database tables

- `teams` — one row per team (`id`, `name`, `created_by`)
- `team_members` — join table (`team_id`, `user_id`, `email`, `role`, `status`)
- `team_bills` — shared bills (`team_id`, `bill_number`)

### RPC functions (security definer — bypass RLS)

| Function                            | Purpose                                                                 |
| ----------------------------------- | ----------------------------------------------------------------------- |
| `my_team_ids()`                     | Returns team IDs the caller owns or is active in (used in RLS policies) |
| `get_my_pending_invites()`          | Returns pending invites for the caller's email                          |
| `accept_my_team_invites()`          | Accepts all pending invites for the caller                              |
| `decline_my_team_invite(invite_id)` | Declines a specific pending invite                                      |
| `remove_team_member(member_id)`     | Owner removes a member from their team                                  |
| `leave_my_team(p_team_id)`          | Member leaves a team they joined                                        |

## Tech Stack

- React 18 + Vite
- Tailwind CSS + Radix UI (shadcn/ui components)
- **Supabase** — PostgreSQL database + Row Level Security + Auth
- **@tanstack/react-query** — client-side data caching (5-minute stale time, shared cache keys)
- `src/api/apiClient.js` — unified data layer over Supabase

## Environment Variables

Create a local `.env` file (gitignored):

```env
VITE_LEGISCAN_API_KEY=your_legiscan_key
VITE_OPENAI_API_KEY=your_openai_key
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key

# Optional
VITE_OPENAI_MODEL=gpt-4o-mini
VITE_OPENAI_BASE_URL=https://api.openai.com/v1
```

Get your Supabase URL and anon key from **Project Settings → API** in the [Supabase dashboard](https://supabase.com/dashboard).

## Database Setup

### Step 1 — Run the migration

Run `supabase/migrations/001_initial_schema.sql` once in your Supabase project's **SQL Editor**. This creates:

- `profiles` — one row per user, stores `tracked_bill_ids` (jsonb array)
- `bills` — full bill records synced from LegiScan
- `teams`, `team_members`, `team_bills` — team collaboration tables
- `email_lists`, `notifications`, `tweets` — supporting tables
- Row Level Security policies so users only access their own data
- Trigger to auto-create a profile row when a new user registers

### Step 2 — Create RPC functions

Run the following in your Supabase **SQL Editor** to create the security definer functions needed for team features:

```sql
-- Breaks RLS recursion between teams ↔ team_members
create or replace function public.my_team_ids()
returns setof uuid language sql security definer stable as $$
  select id from public.teams where created_by = auth.uid()
  union
  select team_id from public.team_members where user_id = auth.uid()
$$;

-- Pending invite helpers
drop function if exists public.get_my_pending_invites();
create or replace function public.get_my_pending_invites()
returns table(id uuid, team_id uuid, invite_email text, role text, status text, team_name text)
language plpgsql security definer as $$
begin
  return query
    select tm.id, tm.team_id, tm.email, tm.role, tm.status, t.name
    from public.team_members tm
    join public.teams t on t.id = tm.team_id
    where lower(tm.email) = lower((select u.email from auth.users u where u.id = auth.uid()))
      and tm.status = 'pending';
end;
$$;

create or replace function public.accept_my_team_invites()
returns void language plpgsql security definer as $$
begin
  update public.team_members
  set user_id = auth.uid(), status = 'active'
  where lower(email) = lower((select email from auth.users where id = auth.uid()))
    and status = 'pending';
end;
$$;

create or replace function public.decline_my_team_invite(invite_id uuid)
returns void language plpgsql security definer as $$
begin
  delete from public.team_members
  where id = invite_id
    and lower(email) = lower((select email from auth.users where id = auth.uid()))
    and status = 'pending';
end;
$$;

create or replace function public.remove_team_member(member_id uuid)
returns void language plpgsql security definer as $$
begin
  delete from public.team_members
  where id = member_id
    and team_id in (select id from public.teams where created_by = auth.uid());
end;
$$;

create or replace function public.leave_my_team(p_team_id uuid)
returns void language plpgsql security definer as $$
begin
  delete from public.team_members
  where team_id = p_team_id
    and user_id = auth.uid()
    and role = 'member';
end;
$$;
```

## Local Development

```bash
npm install
npm run dev
```

Other scripts:

```bash
npm run build
npm run preview
npm run lint
npm run lint:fix
npm run typecheck
```

## Deploying

This is a static Vite build — deploy to **Vercel**, **Netlify**, or **Render**.

Add these environment variables in your hosting dashboard:

- `VITE_LEGISCAN_API_KEY`
- `VITE_OPENAI_API_KEY`
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- optional `VITE_OPENAI_MODEL`
- optional `VITE_OPENAI_BASE_URL`

## Security Warning (Important)

Because this is a Vite client app, all `VITE_*` variables are bundled into the client bundle and visible to end users. Supabase Row Level Security ensures each user can only read and write their own data even if the anon key is exposed. For the OpenAI key, consider moving AI calls to a backend/serverless function for production use.

## Project Structure (high level)

```
src/
  pages/
    Dashboard.jsx        – main bill list, search, filter, track toggle, add to team
    TrackedBills.jsx     – bills the user is tracking
    Team.jsx             – team management: members, invite, shared bills, leave team
    Login.jsx            – login form
    Register.jsx         – registration form
    Settings.jsx         – user settings
    EmailLists.jsx       – email list management
  components/
    bills/
      BillCard.jsx       – bill card with track + add-to-team buttons
      BillDetailsModal   – bill details + AI analysis + track/team actions
      BillSyncButton     – LegiScan sync action (auto-syncs when DB is empty)
      BillFilters        – filter UI
  services/
    legiscan.js          – LegiScan API fetch/parsing helpers
  api/
    apiClient.js         – all data ops (Supabase CRUD + RPC calls + OpenAI)
  lib/
    supabase.js          – Supabase client instance
    AuthContext.jsx      – global auth state (session, login, register, logout)
    query-client.js      – React Query client (5-min stale time)
```
