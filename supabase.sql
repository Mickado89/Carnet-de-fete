-- ============================================================
--  Carnet de Fête — script d'installation Supabase
--  À coller en entier dans : Supabase > SQL Editor > New query > Run
--  Peut être relancé sans risque (il ne supprime aucune donnée).
-- ============================================================

-- 1. Les tables -------------------------------------------------

create table if not exists public.party_config (
  id         int primary key default 1 check (id = 1),   -- une seule ligne
  title      text default '',
  goal       int  default 50,
  updated_at timestamptz default now()
);
insert into public.party_config (id) values (1) on conflict (id) do nothing;

create table if not exists public.places (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 80),
  address    text default '',
  lat        double precision,
  lng        double precision,
  visited    boolean default false,
  position   double precision not null default extract(epoch from now()),
  added_by   text default '',
  created_at timestamptz default now()
);

create table if not exists public.drinks (
  device_id  text primary key,              -- un téléphone = une ligne
  name       text default '',
  counts     jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now()
);

create table if not exists public.members (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 40),
  created_at timestamptz default now()
);

create table if not exists public.expenses (
  id         uuid primary key default gen_random_uuid(),
  label      text default '',
  cents      int  not null check (cents > 0),
  payer      uuid not null references public.members(id) on delete restrict,
  for_ids    uuid[] not null,
  added_by   text default '',
  created_at timestamptz default now()
);

create table if not exists public.photos (
  id         uuid primary key default gen_random_uuid(),
  path       text not null,                 -- chemin dans le stockage "photos"
  caption    text default '',
  added_by   text default '',
  device_id  text default '',
  created_at timestamptz default now()
);

-- 2. Accès : toute personne qui a le lien du site peut lire et écrire ---

do $$
declare t text;
begin
  foreach t in array array['party_config','places','drinks','members','expenses','photos'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "fete_all" on public.%I', t);
    execute format('create policy "fete_all" on public.%I for all to anon, authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- 3. Mises à jour en direct (realtime) ---------------------------

do $$
declare t text;
begin
  foreach t in array array['party_config','places','drinks','members','expenses','photos'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- 4. Stockage des photos -----------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', true, 10485760, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public = true;

drop policy if exists "fete_photos_read"   on storage.objects;
drop policy if exists "fete_photos_add"    on storage.objects;
drop policy if exists "fete_photos_delete" on storage.objects;

create policy "fete_photos_read"   on storage.objects for select to anon, authenticated using (bucket_id = 'photos');
create policy "fete_photos_add"    on storage.objects for insert to anon, authenticated with check (bucket_id = 'photos');
create policy "fete_photos_delete" on storage.objects for delete to anon, authenticated using (bucket_id = 'photos');

-- Terminé. Vous devez voir "Success. No rows returned".
