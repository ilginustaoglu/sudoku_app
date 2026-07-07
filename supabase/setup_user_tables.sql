-- Pandoku kullanıcı ve skor tabloları
-- Supabase Dashboard → SQL Editor'da çalıştırın.
-- (setup_feedback.sql çalıştırıldıysa bu dosyayı ayrıca çalıştırmanız yeterli.)

-- ---------------------------------------------------------------------------
-- profiles: Pandaccount kullanıcı bilgileri
-- SQLite şemasıyla uyumlu; kolon adları snake_case.
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id text primary key,
  email text not null unique,
  first_name text not null,
  last_name text not null,
  birth_date timestamptz not null,
  avatar_path text,
  cover_image_path text,
  display_name text,
  avatar_color bigint,
  cover_image_color bigint,
  created_at timestamptz not null default now(),
  last_played_at timestamptz,
  email_verified boolean not null default false,
  password_hash text not null
);

create index if not exists idx_profiles_email on public.profiles (email);

-- ---------------------------------------------------------------------------
-- game_scores: oyun skorları
-- ---------------------------------------------------------------------------
create table if not exists public.game_scores (
  id text primary key,
  profile_id text not null references public.profiles (id) on delete cascade,
  difficulty text not null,
  score integer not null,
  elapsed_seconds integer not null,
  completed_at timestamptz not null default now(),
  is_daily_game boolean not null default false
);

create index if not exists idx_game_scores_profile_id
  on public.game_scores (profile_id);

create index if not exists idx_game_scores_completed_at
  on public.game_scores (completed_at);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- Not: Uygulama şu an özel giriş (email + şifre hash) kullanıyor.
-- Supabase Auth'a geçildiğinde bu policy'ler sıkılaştırılmalıdır.
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.game_scores enable row level security;

-- profiles
create policy "Anyone can register a profile"
  on public.profiles
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can read profiles"
  on public.profiles
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can update profiles"
  on public.profiles
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete profiles"
  on public.profiles
  for delete
  to anon, authenticated
  using (true);

-- game_scores
create policy "Anyone can insert game scores"
  on public.game_scores
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can read game scores"
  on public.game_scores
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can update game scores"
  on public.game_scores
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete game scores"
  on public.game_scores
  for delete
  to anon, authenticated
  using (true);
