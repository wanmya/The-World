-- 追加の設定（4）：世界を 1km×1km に広げたので、置ける場所の範囲を広げる
-- すでに supabase-setup.sql を実行したプロジェクトで、1 回だけ実行してください。
alter table public.props drop constraint if exists props_x_check;
alter table public.props drop constraint if exists props_z_check;
alter table public.props add constraint props_x_check check (x between -500 and 500);
alter table public.props add constraint props_z_check check (z between -900 and 100);
