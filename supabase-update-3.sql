-- 追加の設定（3）：世界を 500m×500m に広げたので、置ける場所の範囲を広げる
-- すでに supabase-setup.sql を実行したプロジェクトで、1 回だけ実行してください。
alter table public.props drop constraint if exists props_x_check;
alter table public.props drop constraint if exists props_z_check;
alter table public.props add constraint props_x_check check (x between -250 and 250);
alter table public.props add constraint props_z_check check (z between -400 and 100);
