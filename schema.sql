-- ============================================
-- SLOT SCHEDULER — SUPABASE SCHEMA
-- Paste this entire file into Supabase SQL Editor
-- and click Run
-- ============================================

-- 1. USERS TABLE
-- Stores all app users (admin + regular users)
create table if not exists public.users (
  username      text primary key,
  password_hash text not null,
  is_admin      boolean default false,
  created_at    timestamptz default now(),
  last_login    timestamptz
);

-- 2. SUPPORT PERSONS TABLE
-- Stores the list of support persons for booking
create table if not exists public.support_persons (
  id         serial primary key,
  name       text not null unique,
  created_at timestamptz default now()
);

-- 3. BOOKINGS TABLE
-- Stores all slot bookings
create table if not exists public.bookings (
  id           text primary key,        -- format: date_time_supportname
  time_key     text not null,           -- format: YYYY-MM-DD_HHMM
  booked_by    text not null references public.users(username) on delete cascade,
  company      text not null,
  round        text not null,           -- L1, L2, Final
  support      text not null references public.support_persons(name) on delete cascade,
  duration     integer not null,        -- in minutes
  status       text default 'pending',  -- pending, approved, rejected
  booked_at    timestamptz default now()
);

-- 4. LAST LOGIN TABLE
-- Tracks previous login time per user (for "Last login" display)
create table if not exists public.last_logins (
  username   text primary key references public.users(username) on delete cascade,
  login_time timestamptz default now()
);

-- ============================================
-- SEED DATA — Default users and support persons
-- ============================================

-- Default users (passwords are SHA-256 hashed)
-- ADMIN  password: admin
-- DADDY  password: tell
-- MOMMY  password: happy
insert into public.users (username, password_hash, is_admin) values
  ('ADMIN', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', true),
  ('DADDY', '879915cfdc2cb4852ed05241911d8de5ca6e2cc4085746c14f13ad304157e264', false),
  ('MOMMY', '489f719cadf919094ddb38e7654de153ac33c02febb5de91e5345cbe372cf4a0', false)
on conflict (username) do nothing;

-- Default support persons
insert into public.support_persons (name) values
  ('Sumanth'), ('Surya'), ('Veer'), ('Sunil'), ('Raghuveer')
on conflict (name) do nothing;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- Allow all reads and writes from the app
-- (The anon key is used client-side — this
--  allows open access. Fine for internal tools.
--  For public apps, tighten these policies.)
-- ============================================

alter table public.users           enable row level security;
alter table public.support_persons enable row level security;
alter table public.bookings        enable row level security;
alter table public.last_logins     enable row level security;

-- Allow everything via anon key (internal tool)
create policy "allow all" on public.users           for all using (true) with check (true);
create policy "allow all" on public.support_persons for all using (true) with check (true);
create policy "allow all" on public.bookings        for all using (true) with check (true);
create policy "allow all" on public.last_logins     for all using (true) with check (true);
