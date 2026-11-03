-- 追加の設定（11）：果樹園・加工工場、1 人で会社をいくつも、会社どうしの取り引き（加工・運送の委託）
-- すでに supabase-setup.sql・supabase-update-7.sql・supabase-update-9.sql を実行したプロジェクトで、1 回だけ実行してください。
-- 実行するまでは、果樹園は「畑」、工場は「倉庫」としてみんなの画面に出ます。ほかのプレイヤーの会社には加工・運送をたのめません。

-- 1. 建物の種類に「果樹園（みかん）」「果樹園（もも・ぶどう・りんご）」「加工工場」をふやす
alter table public.biz_lots drop constraint if exists biz_lots_bld_check;
alter table public.biz_lots add constraint biz_lots_bld_check
  check (bld in ('prefab', 'shop', 'super', 'diner', 'ware', 'apt', 'farm', 'paddy', 'dealer', 'orchard_m', 'orchard_a', 'factory'));

-- 2. その人の会社の一覧（会社ごとの名前・場所・受ける加工の値段と量・運送の値段と量）。10 社まで
alter table public.businesses add column if not exists grp jsonb;
do $$ begin
  alter table public.businesses add constraint businesses_grp_check
    check (grp is null or (jsonb_typeof(grp) = 'array' and jsonb_array_length(grp) <= 10 and pg_column_size(grp) <= 12000));
exception when duplicate_object then null;
end $$;

-- 3. 加工・運送をたのんだ代金の知らせ（たのんだ人が書き、受けた人が読んで決算に入れてから消す）
create table if not exists public.biz_trades (
  id uuid primary key,
  payer text not null check (char_length(payer) between 1 and 40),
  payee text not null check (char_length(payee) between 1 and 40),
  co text not null check (char_length(co) between 1 and 16),
  payer_name text not null default '' check (char_length(payer_name) <= 24),
  payer_co text not null default '' check (char_length(payer_co) <= 16),
  kind text not null check (kind in ('proc', 'haul')),
  what text not null default '' check (char_length(what) <= 16),
  kg integer not null default 0 check (kg between 0 and 10000000),
  amt bigint not null check (amt between 0 and 1000000000),
  cost bigint not null default 0 check (cost between 0 and 1000000000),
  created_at timestamptz not null default now()
);
alter table public.biz_trades enable row level security;
drop policy if exists "trades read" on public.biz_trades;
drop policy if exists "trades add" on public.biz_trades;
drop policy if exists "trades remove" on public.biz_trades;
create policy "trades read" on public.biz_trades for select to anon, authenticated using (true);
create policy "trades add" on public.biz_trades for insert to anon, authenticated with check (true);
create policy "trades remove" on public.biz_trades for delete to anon, authenticated using (true);

-- 数の上限：2000 件（ふつうは受けた人がすぐ消すので、たまらない）
create or replace function public.biz_trades_limit() returns trigger language plpgsql as $$
begin
  if (select count(*) from public.biz_trades) >= 2000 then raise exception 'too many trades'; end if;
  return new;
end $$;
drop trigger if exists biz_trades_limit on public.biz_trades;
create trigger biz_trades_limit before insert on public.biz_trades for each row execute function public.biz_trades_limit();

-- たのまれたら、受けた人にすぐ知らせる
do $$ begin
  alter publication supabase_realtime add table public.biz_trades;
exception when duplicate_object then null;
end $$;
