-- Pandoku: arkadaş kodu + arkadaşlık tablosu
-- Mevcut Supabase projesinde SQL Editor'da çalıştırın.
-- (Yeni kurulum için setup_all.sql / setup_user_tables.sql güncellendi.)

-- ---------------------------------------------------------------------------
-- profiles.friend_code (6 haneli, benzersiz)
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists friend_code text;

-- Mevcut oyunculara benzersiz 6 haneli kod ata
do $$
declare
  r record;
  new_code text;
begin
  for r in
    select id from public.profiles
    where friend_code is null or friend_code = ''
  loop
    loop
      new_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
      exit when not exists (
        select 1 from public.profiles where friend_code = new_code
      );
    end loop;
    update public.profiles
    set friend_code = new_code
    where id = r.id;
  end loop;
end $$;

alter table public.profiles
  alter column friend_code set not null;

create unique index if not exists idx_profiles_friend_code
  on public.profiles (friend_code);

-- ---------------------------------------------------------------------------
-- friendships
-- ---------------------------------------------------------------------------
create table if not exists public.friendships (
  id text primary key,
  requester_id text not null references public.profiles (id) on delete cascade,
  addressee_id text not null references public.profiles (id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  requester_seen_at timestamptz,
  addressee_seen_at timestamptz,
  constraint friendships_no_self check (requester_id <> addressee_id)
);

-- Daha önce arkadaş olmuş çiftleri koru; yeni kayıtlar istek olarak başlasın.
alter table public.friendships
  add column if not exists status text;
alter table public.friendships
  add column if not exists responded_at timestamptz;
alter table public.friendships
  add column if not exists requester_seen_at timestamptz;
alter table public.friendships
  add column if not exists addressee_seen_at timestamptz;

update public.friendships
set
  status = 'accepted',
  responded_at = coalesce(responded_at, created_at),
  requester_seen_at = coalesce(requester_seen_at, created_at),
  addressee_seen_at = coalesce(addressee_seen_at, created_at)
where status is null;

alter table public.friendships
  alter column status set default 'pending';
alter table public.friendships
  alter column status set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'friendships_status_check'
      and conrelid = 'public.friendships'::regclass
  ) then
    alter table public.friendships
      add constraint friendships_status_check
      check (status in ('pending', 'accepted'));
  end if;
end $$;

-- Aynı çift iki kez eklenmesin (yön fark etmeksizin)
create unique index if not exists friendships_pair_uidx
  on public.friendships (
    least(requester_id, addressee_id),
    greatest(requester_id, addressee_id)
  );

create index if not exists idx_friendships_requester
  on public.friendships (requester_id);

create index if not exists idx_friendships_addressee
  on public.friendships (addressee_id);

alter table public.friendships enable row level security;

drop policy if exists "Anyone can insert friendships" on public.friendships;
drop policy if exists "Anyone can read friendships" on public.friendships;
drop policy if exists "Anyone can update friendships" on public.friendships;
drop policy if exists "Anyone can delete friendships" on public.friendships;

create policy "Anyone can insert friendships"
  on public.friendships for insert to anon, authenticated with check (true);

create policy "Anyone can read friendships"
  on public.friendships for select to anon, authenticated using (true);

create policy "Anyone can update friendships"
  on public.friendships for update to anon, authenticated
  using (true) with check (true);

create policy "Anyone can delete friendships"
  on public.friendships for delete to anon, authenticated using (true);

grant select, insert, update, delete on public.friendships to anon, authenticated;

-- PostgREST şema önbelleğini yenile (PGRST205 önlemek için)
notify pgrst, 'reload schema';
