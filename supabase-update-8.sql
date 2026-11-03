-- 追加の設定（8）：glTF の乗り物を「持ち主だけ」か「みんな使える」か選べるようにする
-- すでに supabase-setup.sql を実行したプロジェクトで、1 回だけ実行してください。

-- 乗り物をほかの人も運転できるか（はじめは false = 置いた本人だけ）
alter table public.props add column if not exists share boolean not null default false;

-- 場所・向きに加えて、この切りかえも書きかえられるようにする
grant update (x, z, rot, share) on public.props to anon, authenticated;
