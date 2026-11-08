-- MyMoney – cloud schema for offline-first sync.
--
-- Every row belongs to one auth user and is protected by Row Level Security.
-- The client writes `updated_at` (its local edit time) and the server writes
-- `synced_at` (its own clock), which clients use as an incremental pull cursor.

-- ---------------------------------------------------------------------------
-- Shared trigger: last-write-wins + server cursor
-- ---------------------------------------------------------------------------
create or replace function public.sync_before_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    if new.user_id is distinct from old.user_id then
      raise exception 'user_id cannot be changed';
    end if;
    -- A stale device must never overwrite a newer version: skip the update.
    if new.updated_at < old.updated_at then
      return null;
    end if;
  end if;
  -- clock_timestamp() (not now()) so rows in one bulk upsert get distinct cursors.
  new.synced_at := clock_timestamp();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- transactions
-- ---------------------------------------------------------------------------
create table public.transactions (
  id          uuid primary key,
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  amount      numeric(12, 2) not null,
  merchant    text not null default '',
  date        timestamptz not null,
  category    text not null,
  card        text not null,
  notes       text not null default '',
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  synced_at   timestamptz not null default clock_timestamp()
);

comment on table public.transactions is 'Credit-card transactions. Soft-deleted via deleted_at so deletions sync.';

create index transactions_user_synced_idx on public.transactions (user_id, synced_at);

create trigger transactions_sync_before_write
  before insert or update on public.transactions
  for each row execute function public.sync_before_write();

-- ---------------------------------------------------------------------------
-- savings_goals (one per user; id = user_id)
-- ---------------------------------------------------------------------------
create table public.savings_goals (
  id                      uuid primary key,
  user_id                 uuid not null unique default auth.uid() references auth.users (id) on delete cascade,
  monthly_income          numeric(12, 2) not null check (monthly_income >= 0),
  savings_target_percent  numeric(5, 4) not null check (savings_target_percent between 0 and 1),
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  synced_at               timestamptz not null default clock_timestamp(),
  constraint savings_goals_id_is_user check (id = user_id)
);

create trigger savings_goals_sync_before_write
  before insert or update on public.savings_goals
  for each row execute function public.sync_before_write();

-- ---------------------------------------------------------------------------
-- Row Level Security – a user can only ever see and change their own rows
-- ---------------------------------------------------------------------------
alter table public.transactions  enable row level security;
alter table public.savings_goals enable row level security;

create policy "Users read own transactions"   on public.transactions for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users insert own transactions" on public.transactions for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users update own transactions" on public.transactions for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users delete own transactions" on public.transactions for delete to authenticated using ((select auth.uid()) = user_id);

create policy "Users read own goal"   on public.savings_goals for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users insert own goal" on public.savings_goals for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users update own goal" on public.savings_goals for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users delete own goal" on public.savings_goals for delete to authenticated using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.transactions  to authenticated;
grant select, insert, update, delete on public.savings_goals to authenticated;
revoke all on public.transactions, public.savings_goals from anon;
