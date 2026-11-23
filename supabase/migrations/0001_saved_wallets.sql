-- Cloud copy of the wallets a user saved.
--
-- The app keeps Isar as its offline cache and treats this table as the shared
-- source of truth across machines. Run this in the Supabase SQL editor (or via
-- `supabase db push`) once per project.

create table if not exists public.saved_wallets (
  id uuid primary key default gen_random_uuid(),
  -- Defaulting to `auth.uid()` means the client never has to send user_id,
  -- and cannot send someone else's id (RLS would reject that anyway).
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
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
