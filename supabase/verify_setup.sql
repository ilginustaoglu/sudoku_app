-- Pandoku Supabase kurulum kontrolü
-- SQL Editor'da çalıştırın; sonuçları aşağıda yorum satırlarında açıklanır.

-- 1) Tablolar var mı?
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('feedback', 'profiles', 'game_scores', 'friendships')
order by table_name;
-- Beklenen: 4 satır (feedback, friendships, game_scores, profiles)

-- 2) Her tabloda kaç kayıt var?
select 'feedback' as table_name, count(*) as row_count from public.feedback
union all
select 'profiles', count(*) from public.profiles
union all
select 'game_scores', count(*) from public.game_scores
union all
select 'friendships', count(*) from public.friendships;

-- 3) friend_code kolonu ve doluluk
select
  count(*) as profiles_total,
  count(friend_code) as with_friend_code,
  count(*) filter (where friend_code is null or friend_code = '') as missing_friend_code
from public.profiles;

-- 4) RLS açık mı?
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('feedback', 'profiles', 'game_scores', 'friendships');

-- 5) Policy'ler tanımlı mı?
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
  and tablename in ('feedback', 'profiles', 'game_scores', 'friendships')
order by tablename, policyname;
