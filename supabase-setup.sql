-- ワールド用の Supabase 設定
-- Supabase の「SQL Editor」に全部貼って「Run」を押してください（1 回だけ）。

-- 1. 置いた物の一覧（場所と種類）。形のファイルは下の保存場所に入れる
create table if not exists public.props (
  id uuid primary key,
  name text not null check (char_length(name) between 1 and 40),
  cat text not null check (cat in ('building', 'plant', 'prop', 'car', 'ship', 'sub', 'plane')),
  x double precision not null check (x between -100 and 100),
  z double precision not null check (z between -100 and 100),
  rot double precision not null default 0 check (rot between -100 and 100),
  bytes integer not null check (bytes between 1 and 1572864),
  by text check (char_length(by) <= 40),
  created_at timestamptz not null default now()
);

-- ログインなしの人（anon）でも、見る・置く・動かす・片付けるができるようにする
alter table public.props enable row level security;
drop policy if exists "props read" on public.props;
drop policy if exists "props add" on public.props;
drop policy if exists "props move" on public.props;
drop policy if exists "props remove" on public.props;
create policy "props read" on public.props for select to anon, authenticated using (true);
create policy "props add" on public.props for insert to anon, authenticated with check (true);
create policy "props move" on public.props for update to anon, authenticated using (true) with check (true);
create policy "props remove" on public.props for delete to anon, authenticated using (true);

-- 動かせるのは場所と向きだけ（名前や種類は書き換えられない）
revoke update on public.props from anon, authenticated;
grant update (x, z, rot) on public.props to anon, authenticated;

-- 置ける数は全部で 200 個まで
create or replace function public.props_limit() returns trigger language plpgsql as $$
begin
  if (select count(*) from public.props) >= 200 then
    raise exception 'world is full';
  end if;
  return new;
end $$;
drop trigger if exists props_limit on public.props;
create trigger props_limit before insert on public.props for each row execute function public.props_limit();

-- 置いた・動いた・消えたを、開いている全員にすぐ知らせる
do $$ begin
  alter publication supabase_realtime add table public.props;
exception when duplicate_object then null;
end $$;

-- 2. 形のファイル（.glb）の保存場所。1 個 1.5MB まで
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('props', 'props', true, 1572864, array['model/gltf-binary', 'application/octet-stream'])
on conflict (id) do update set public = true, file_size_limit = 1572864,
  allowed_mime_types = array['model/gltf-binary', 'application/octet-stream'];

drop policy if exists "props files read" on storage.objects;
drop policy if exists "props files add" on storage.objects;
drop policy if exists "props files remove" on storage.objects;
create policy "props files read" on storage.objects for select to anon, authenticated
  using (bucket_id = 'props');
create policy "props files add" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'props' and name ~ '^[0-9a-f-]{36}\.glb$');
create policy "props files remove" on storage.objects for delete to anon, authenticated
  using (bucket_id = 'props');
