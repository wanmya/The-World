-- 追加の設定（14）：世界を 50km×50km に広げたので（2026-11-14）、置ける場所の範囲を広げる
-- すでに supabase-setup.sql を実行したプロジェクトで、1 回だけ実行してください。
-- 実行しないと、まん中の 10km の外（みなみ野空港・きた島など）に置いた物は自分の画面だけに置かれます。
alter table public.props drop constraint if exists props_x_check;
alter table public.props drop constraint if exists props_z_check;
alter table public.props add constraint props_x_check check (x between -25000 and 25000);
alter table public.props add constraint props_z_check check (z between -25000 and 25000);
