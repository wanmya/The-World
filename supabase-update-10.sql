-- 追加の設定（10）：glTF の自動車の「種類」（乗用車・バス・トラック・ダンプ・ミキサー車・タンクローリー・重機・農機など）を保存する
-- すでに supabase-setup.sql を実行したプロジェクトで、1 回だけ実行してください。
-- 実行しなくても置けます（そのときは、ほかの人の画面では .glb のカスタムプロパティ「種類」や形から種類を決めます）。

alter table public.props add column if not exists kind text;
alter table public.props drop constraint if exists props_kind_check;
alter table public.props add constraint props_kind_check check (kind is null or kind ~ '^[a-z]{2,12}$');
