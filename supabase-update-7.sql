-- 追加の設定（7）：プレイヤーの会社（事業）を、みんなの画面に出す
-- すでに supabase-setup.sql を実行したプロジェクトで、1 回だけ実行してください。

-- 1. 会社の一覧（1 人 1 社）。きのうの売り上げ・利益は新聞と会社の一覧に出す
create table if not exists public.businesses (
  by text primary key check (char_length(by) between 1 and 40),
  name text not null check (char_length(name) between 1 and 16),
  form text not null check (form in ('sole', 'llc', 'kk')),
  day integer not null default 0,
  rev bigint not null default 0,
  prof bigint not null default 0,
  lots integer not null default 0 check (lots between 0 and 50),
  updated_at timestamptz not null default now()
);

-- 2. 会社が使っている土地（1 つの土地は 1 社だけ）。建物の種類とできあがる時刻（ゲームの日）
create table if not exists public.biz_lots (
  lot_id integer primary key check (lot_id between 0 and 5000),
  by text not null check (char_length(by) between 1 and 40),
  biz text not null check (char_length(biz) between 1 and 16),
  own boolean not null default false,
  bld text check (bld in ('prefab', 'shop', 'super', 'diner', 'ware', 'apt', 'farm')),
  done double precision,
  gltf boolean not null default false,   -- 自分の glTF の社屋（形はその glTF）
  updated_at timestamptz not null default now()
);

-- ログインなしの人（anon）でも、見る・書く・消すができるようにする
alter table public.businesses enable row level security;
alter table public.biz_lots enable row level security;
drop policy if exists "biz read" on public.businesses;
drop policy if exists "biz add" on public.businesses;
drop policy if exists "biz change" on public.businesses;
drop policy if exists "biz remove" on public.businesses;
create policy "biz read" on public.businesses for select to anon, authenticated using (true);
create policy "biz add" on public.businesses for insert to anon, authenticated with check (true);
create policy "biz change" on public.businesses for update to anon, authenticated using (true) with check (true);
create policy "biz remove" on public.businesses for delete to anon, authenticated using (true);
drop policy if exists "lots read" on public.biz_lots;
drop policy if exists "lots add" on public.biz_lots;
drop policy if exists "lots change" on public.biz_lots;
drop policy if exists "lots remove" on public.biz_lots;
create policy "lots read" on public.biz_lots for select to anon, authenticated using (true);
create policy "lots add" on public.biz_lots for insert to anon, authenticated with check (true);
create policy "lots change" on public.biz_lots for update to anon, authenticated using (true) with check (true);
create policy "lots remove" on public.biz_lots for delete to anon, authenticated using (true);

-- 土地の持ち主（by）はあとから変えられない（建物と名前だけ変えられる）
revoke update on public.biz_lots from anon, authenticated;
grant update (biz, own, bld, done, gltf, updated_at) on public.biz_lots to anon, authenticated;

-- 数の上限：会社 200 社、土地 600 か所
create or replace function public.biz_limit() returns trigger language plpgsql as $$
begin
  if tg_table_name = 'businesses' and (select count(*) from public.businesses) >= 200 then raise exception 'too many businesses'; end if;
  if tg_table_name = 'biz_lots' and (select count(*) from public.biz_lots) >= 600 then raise exception 'too many lots'; end if;
  return new;
end $$;
drop trigger if exists biz_limit on public.businesses;
create trigger biz_limit before insert on public.businesses for each row execute function public.biz_limit();
drop trigger if exists biz_lots_limit on public.biz_lots;
create trigger biz_lots_limit before insert on public.biz_lots for each row execute function public.biz_limit();

-- 変わったら、開いている全員にすぐ知らせる
do $$ begin
  alter publication supabase_realtime add table public.businesses;
exception when duplicate_object then null;
end $$;
do $$ begin
  alter publication supabase_realtime add table public.biz_lots;
exception when duplicate_object then null;
end $$;
-- 消したときに、どの土地か分かるように
alter table public.biz_lots replica identity full;
alter table public.businesses replica identity full;
