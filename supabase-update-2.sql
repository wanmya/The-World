-- 追加の設定（2）：乗り物の種類（船・潜水艦・航空機）を保存できるようにする
-- すでに supabase-setup.sql を実行したプロジェクトで、1 回だけ実行してください。
alter table public.props drop constraint if exists props_cat_check;
alter table public.props add constraint props_cat_check
  check (cat in ('building', 'plant', 'prop', 'car', 'ship', 'sub', 'plane'));
