# ワールド

海と陸地の 200m の箱の世界。ログインなしで、みんなで歩いたり、がっち号を運転したり、glTF（.glb）を置いたりできます。

- 画面：`index.html` 1 ファイル（Three.js 0.160）
- 通信：Supabase（位置とひとことは Realtime、置いた物は `props` テーブルと `props` 保存場所）
- 公開：GitHub Pages

## はじめの設定（1 回だけ）

1. Supabase の「SQL Editor」に `supabase-setup.sql` を全部貼って「Run」
2. `index.html` の上のほうにある `WORLD_CONFIG` に、Supabase の **Project URL** と **anon public キー** を入れる
   （service_role キーは絶対に入れないこと）
3. GitHub のリポジトリの Settings → Pages で、Branch を `main`、フォルダを `/ (root)` にして Save

設定が空のままだと、ひとりで遊ぶだけになります。

## 決まりごと

- 置ける物は全部で 200 個まで、1 個 1.5MB・3 万三角形まで
- URL を知っている人なら誰でも置いたり片付けたりできます（ログインなし）
- 自動車の作り方は「自動車のつくりかた」のルールのまま（ボディ＋タイヤ 4 つ）
