-- 追加の設定（13）：置ける glTF（.glb）の大きさの上限を 1.5MB → 10MB にする
-- すでに supabase-setup.sql を実行したプロジェクトで、1 回だけ実行してください。
-- 実行しないと、1.5MB をこえる物は自分の画面だけに置かれます。

-- 1. 物の表の「大きさ」チェックを 10MB までにする
alter table public.props drop constraint if exists props_bytes_check;
alter table public.props add constraint props_bytes_check check (bytes between 1 and 10485760);

-- 2. ファイルの保存場所（props バケット）の上限を 10MB にする
update storage.buckets set file_size_limit = 10485760 where id = 'props';
