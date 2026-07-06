-- Pandoku geri bildirim tablosu
-- Supabase Dashboard → SQL Editor'da çalıştırın.

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
