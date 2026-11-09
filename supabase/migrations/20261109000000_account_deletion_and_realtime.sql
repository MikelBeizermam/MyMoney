-- Lets a signed-in user permanently delete their own account.
-- Their transactions and savings goal are removed by `on delete cascade`.
-- Required by App Store Review Guideline 5.1.1(v) for apps that support account creation.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- Broadcast row changes so the web app and other devices update live.
-- Realtime respects the RLS policies, so users only receive their own rows.
alter publication supabase_realtime add table public.transactions, public.savings_goals;
