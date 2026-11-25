-- Cloud copy of the wallets a user saved.
--
-- The app keeps Isar as its offline cache and treats this table as the shared
-- source of truth across machines. Apply with:
--   neon psql production -- -f neon/migrations/0001_saved_wallets.sql

create table if not exists public.saved_wallets (
  id uuid primary key default gen_random_uuid(),
  -- Defaulting to auth.uid() means the client never has to send user_id,
  -- and cannot send someone else's id (RLS would reject that anyway).
  -- Neon Auth keeps users in neon_auth."user", not Supabase's auth.users.
  user_id uuid not null default auth.uid()
    references neon_auth."user" (id) on delete cascade,
  -- Stored lowercase so the same wallet in different casing collides.
  address text not null,
  label text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint saved_wallets_address_lowercase check (address = lower(address)),
  -- One row per wallet per user. Makes upsert (on conflict) possible.
  constraint saved_wallets_user_address_key unique (user_id, address)
);

create index if not exists saved_wallets_user_id_idx
  on public.saved_wallets (user_id);

-- Row Level Security: the database itself enforces ownership.
--
-- Without these policies a signed-in user could read every row. With them, the
-- `user_id = auth.uid()` check is applied by Postgres on every query, so a
-- forgotten `where` clause in Dart cannot leak another user's wallets.
alter table public.saved_wallets enable row level security;

drop policy if exists "Users read their own saved wallets" on public.saved_wallets;
create policy "Users read their own saved wallets"
  on public.saved_wallets for select
  using (auth.uid() = user_id);

drop policy if exists "Users insert their own saved wallets" on public.saved_wallets;
create policy "Users insert their own saved wallets"
  on public.saved_wallets for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users update their own saved wallets" on public.saved_wallets;
create policy "Users update their own saved wallets"
  on public.saved_wallets for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users delete their own saved wallets" on public.saved_wallets;
create policy "Users delete their own saved wallets"
  on public.saved_wallets for delete
  using (auth.uid() = user_id);

-- Keep `updated_at` honest so future sync code can use it for last-write-wins.
create or replace function public.touch_saved_wallet_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists saved_wallets_touch_updated_at on public.saved_wallets;
create trigger saved_wallets_touch_updated_at
  before update on public.saved_wallets
  for each row execute function public.touch_saved_wallet_updated_at();

-- Realtime change feed.
--
-- Realtime refuses queries that touch a table with RLS enabled, so the app
-- cannot subscribe to saved_wallets directly. This append-only table carries
-- only "something changed for this user" signals; the app then re-reads the
-- real rows through the Data API, which still enforces RLS.
--
-- It deliberately has no API grants: only the `api` function (table owner)
-- reads it, and that function filters by the verified user_id before sealing
-- a subscription. That keeps per-user isolation in the sealed query.
create table if not exists public.saved_wallets_events (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  saved_wallet_id uuid not null,
  op text not null check (op in ('insert', 'update', 'delete')),
  changed_at timestamptz not null default now()
);

create index if not exists saved_wallets_events_user_id_idx
  on public.saved_wallets_events (user_id, id);

create or replace function public.log_saved_wallet_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    insert into public.saved_wallets_events (user_id, saved_wallet_id, op)
    values (old.user_id, old.id, 'delete');
    return old;
  end if;

  insert into public.saved_wallets_events (user_id, saved_wallet_id, op)
  values (new.user_id, new.id, lower(tg_op));
  return new;
end;
$$;

drop trigger if exists saved_wallets_log_event on public.saved_wallets;
create trigger saved_wallets_log_event
  after insert or update or delete on public.saved_wallets
  for each row execute function public.log_saved_wallet_event();

-- Data API uses the standard PostgREST roles. `authenticated` is what a
-- request with a valid Neon Auth JWT runs as; RLS then scopes it per user.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.saved_wallets to authenticated;

-- The change feed is server-only. New tables grant nothing to PUBLIC by
-- default; revoking explicitly documents that and survives future defaults.
revoke all on public.saved_wallets_events from anonymous, authenticated;
