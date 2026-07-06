-- Pandoku: eksik izinleri ve policy'leri düzelt
-- Tablolar var ama veri yazılamıyorsa bu dosyayı SQL Editor'da çalıştırın.

-- Tablolar yoksa önce setup_all.sql çalıştırın.

-- ---------------------------------------------------------------------------
-- GRANT (anon rolüne tablo erişimi)
-- ---------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;

grant select, insert, update, delete on public.feedback to anon, authenticated;
grant select, insert, update, delete on public.profiles to anon, authenticated;
grant select, insert, update, delete on public.game_scores to anon, authenticated;

-- ---------------------------------------------------------------------------
-- feedback policies
-- ---------------------------------------------------------------------------
alter table public.feedback enable row level security;

drop policy if exists "Anyone can submit feedback" on public.feedback;

create policy "Anyone can submit feedback"
  on public.feedback
  for insert
  to anon, authenticated
  with check (true);

-- ---------------------------------------------------------------------------
-- profiles policies
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists "Anyone can register a profile" on public.profiles;
drop policy if exists "Anyone can read profiles" on public.profiles;
drop policy if exists "Anyone can update profiles" on public.profiles;

create policy "Anyone can register a profile"
  on public.profiles for insert to anon, authenticated with check (true);

create policy "Anyone can read profiles"
  on public.profiles for select to anon, authenticated using (true);

create policy "Anyone can update profiles"
  on public.profiles for update to anon, authenticated using (true) with check (true);

-- ---------------------------------------------------------------------------
-- game_scores policies
-- ---------------------------------------------------------------------------
alter table public.game_scores enable row level security;

drop policy if exists "Anyone can insert game scores" on public.game_scores;
drop policy if exists "Anyone can read game scores" on public.game_scores;
drop policy if exists "Anyone can update game scores" on public.game_scores;
drop policy if exists "Anyone can delete game scores" on public.game_scores;

create policy "Anyone can insert game scores"
  on public.game_scores for insert to anon, authenticated with check (true);

create policy "Anyone can read game scores"
  on public.game_scores for select to anon, authenticated using (true);

create policy "Anyone can update game scores"
  on public.game_scores for update to anon, authenticated using (true) with check (true);

create policy "Anyone can delete game scores"
  on public.game_scores for delete to anon, authenticated using (true);
