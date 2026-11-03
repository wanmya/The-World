-- 追加の設定（12）：ほかのプレイヤーの会社に入る（プレイヤー社員）・毎日の給与
-- すでに supabase-update-11.sql を実行したプロジェクトで、1 回だけ実行してください。
-- 実行するまでは、ほかのプレイヤーの会社に入れません（自分の事業はいままでどおりできます）。

-- 1. 給与の知らせ：会社の持ち主が書き、はたらいている人が読んで手持ちの P に入れてから消す（biz_trades に 'wage' をふやす）
alter table public.biz_trades drop constraint if exists biz_trades_kind_check;
alter table public.biz_trades add constraint biz_trades_kind_check check (kind in ('proc', 'haul', 'wage'));

-- 2. だれが、だれの どの会社に入っているか（入る人が書く。やめるときは 本人か会社の持ち主が消す）
create table if not exists public.biz_members (
  member text not null check (char_length(member) between 1 and 40),
  owner text not null check (char_length(owner) between 1 and 40),
  co text not null check (char_length(co) between 1 and 16),
  member_name text not null default '' check (char_length(member_name) <= 24),
  co_name text not null default '' check (char_length(co_name) <= 16),
  day integer not null default 0 check (day between 0 and 100000000),
  created_at timestamptz not null default now(),
  primary key (member, co),
  check (member <> owner)
);
alter table public.biz_members enable row level security;
drop policy if exists "members read" on public.biz_members;
drop policy if exists "members add" on public.biz_members;
drop policy if exists "members remove" on public.biz_members;
create policy "members read" on public.biz_members for select to anon, authenticated using (true);
create policy "members add" on public.biz_members for insert to anon, authenticated with check (true);
create policy "members remove" on public.biz_members for delete to anon, authenticated using (true);

-- 数の上限：ぜんぶで 2000 人・1 人 3 社まで
create or replace function public.biz_members_limit() returns trigger language plpgsql as $$
begin
  if (select count(*) from public.biz_members) >= 2000 then raise exception 'too many members'; end if;
  if (select count(*) from public.biz_members where member = new.member) >= 3 then raise exception 'too many jobs'; end if;
  return new;
end $$;
drop trigger if exists biz_members_limit on public.biz_members;
create trigger biz_members_limit before insert on public.biz_members for each row execute function public.biz_members_limit();

-- 入った・やめたを すぐ知らせる（やめたときも だれが・どの会社か わかるように）
alter table public.biz_members replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.biz_members;
exception when duplicate_object then null;
end $$;
