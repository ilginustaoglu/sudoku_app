-- Pandoku — tüm Supabase tabloları
-- Supabase Dashboard → SQL Editor'da tek seferde çalıştırın.

-- Geri bildirim
create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  message text not null,
  sender_email text,
  sender_name text,
  created_at timestamptz not null default now()
);

alter table public.feedback enable row level security;

create policy "Anyone can submit feedback"
  on public.feedback
  for insert
  to anon, authenticated
  with check (true);

-- Kullanıcı profilleri
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
  password_hash text not null,
  friend_code text not null
);

create index if not exists idx_profiles_email on public.profiles (email);
create unique index if not exists idx_profiles_friend_code
  on public.profiles (friend_code);

-- Oyun skorları
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

-- Arkadaşlıklar
create table if not exists public.friendships (
  id text primary key,
  requester_id text not null references public.profiles (id) on delete cascade,
  addressee_id text not null references public.profiles (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  requester_seen_at timestamptz,
  addressee_seen_at timestamptz,
  constraint friendships_no_self check (requester_id <> addressee_id)
);

create unique index if not exists friendships_pair_uidx
  on public.friendships (
    least(requester_id, addressee_id),
    greatest(requester_id, addressee_id)
  );

create index if not exists idx_friendships_requester
  on public.friendships (requester_id);

create index if not exists idx_friendships_addressee
  on public.friendships (addressee_id);

alter table public.profiles enable row level security;
alter table public.game_scores enable row level security;
alter table public.friendships enable row level security;

create policy "Anyone can register a profile"
  on public.profiles for insert to anon, authenticated with check (true);

create policy "Anyone can read profiles"
  on public.profiles for select to anon, authenticated using (true);

create policy "Anyone can update profiles"
  on public.profiles for update to anon, authenticated using (true) with check (true);

create policy "Anyone can insert game scores"
  on public.game_scores for insert to anon, authenticated with check (true);

create policy "Anyone can read game scores"
  on public.game_scores for select to anon, authenticated using (true);

create policy "Anyone can update game scores"
  on public.game_scores for update to anon, authenticated using (true) with check (true);

create policy "Anyone can delete game scores"
  on public.game_scores for delete to anon, authenticated using (true);

create policy "Anyone can insert friendships"
  on public.friendships for insert to anon, authenticated with check (true);

create policy "Anyone can read friendships"
  on public.friendships for select to anon, authenticated using (true);

create policy "Anyone can update friendships"
  on public.friendships for update to anon, authenticated
  using (true) with check (true);

create policy "Anyone can delete friendships"
  on public.friendships for delete to anon, authenticated using (true);
