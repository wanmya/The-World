-- 追加の設定（9）：自動車販売店（自分で作った glTF の車を、ほかのプレイヤーに売る）と田んぼ
-- すでに supabase-setup.sql と supabase-update-7.sql を実行したプロジェクトで、1 回だけ実行してください。

-- 1. 建物の種類に「車の販売店（dealer）」と「田んぼ（paddy）」をふやす
alter table public.biz_lots drop constraint if exists biz_lots_bld_check;
alter table public.biz_lots add constraint biz_lots_bld_check
  check (bld in ('prefab', 'shop', 'super', 'diner', 'ware', 'apt', 'farm', 'paddy', 'dealer'));

-- 2. 販売店の建て方（階数:広さ:つくり。例 "2:m:rc"）。ほかの人の画面でも同じ形に建つ
alter table public.biz_lots add column if not exists cfg text check (cfg is null or char_length(cfg) <= 20);
grant update (biz, own, bld, done, gltf, cfg, updated_at) on public.biz_lots to anon, authenticated;

-- 3. 会社が売っている車種の一覧（名前・値段・種類・輪の数・大きさ・最高速度・スペック表）。8 車種まで
alter table public.businesses add column if not exists cars jsonb;
do $$ begin
  alter table public.businesses add constraint businesses_cars_check
    check (cars is null or (jsonb_typeof(cars) = 'array' and jsonb_array_length(cars) <= 8 and pg_column_size(cars) <= 16000));
exception when duplicate_object then null;
end $$;

-- 4. 車が売れた知らせ（買った人が書き、売った人が読んで決算に入れてから消す）
create table if not exists public.car_sales (
  id uuid primary key,
  seller text not null check (char_length(seller) between 1 and 40),
  buyer text not null check (char_length(buyer) between 1 and 40),
  buyer_name text not null default '' check (char_length(buyer_name) <= 24),
  model uuid not null,
  name text not null check (char_length(name) between 1 and 24),
  price bigint not null check (price between 0 and 1000000000),
  created_at timestamptz not null default now()
);
alter table public.car_sales enable row level security;
drop policy if exists "sales read" on public.car_sales;
drop policy if exists "sales add" on public.car_sales;
drop policy if exists "sales remove" on public.car_sales;
create policy "sales read" on public.car_sales for select to anon, authenticated using (true);
create policy "sales add" on public.car_sales for insert to anon, authenticated with check (true);
create policy "sales remove" on public.car_sales for delete to anon, authenticated using (true);

-- 数の上限：500 件（ふつうは売った人がすぐ消すので、たまらない）
create or replace function public.car_sales_limit() returns trigger language plpgsql as $$
begin
  if (select count(*) from public.car_sales) >= 500 then raise exception 'too many sales'; end if;
  return new;
end $$;
drop trigger if exists car_sales_limit on public.car_sales;
create trigger car_sales_limit before insert on public.car_sales for each row execute function public.car_sales_limit();

-- 売れたら、売った人にすぐ知らせる
do $$ begin
  alter publication supabase_realtime add table public.car_sales;
exception when duplicate_object then null;
end $$;
