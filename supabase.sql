-- ============================================================
--  Carnet de Fête — script Supabase (version 3)
--
--  À coller en entier dans : Supabase > SQL Editor > New query > Run
--  • Nouveau projet : crée tout.
--  • Projet existant : met à jour SANS effacer les données
--    (étapes, verres, dépenses, photos… sont conservés).
--  Peut être relancé autant de fois que nécessaire.
-- ============================================================


-- 1. Les tables ------------------------------------------------

create table if not exists public.party_config (
  id         int primary key default 1 check (id = 1),
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
alter table public.places add column if not exists device_id text default '';

create table if not exists public.drinks (
  device_id  text primary key,
  name       text default '',
  counts     jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now()
);

create table if not exists public.members (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 40),
  created_at timestamptz default now()
);
alter table public.members add column if not exists device_id text default '';

create table if not exists public.expenses (
  id         uuid primary key default gen_random_uuid(),
  label      text default '',
  cents      int  not null check (cents > 0),
  payer      uuid not null references public.members(id) on delete restrict,
  for_ids    uuid[] not null,
  added_by   text default '',
  created_at timestamptz default now()
);
alter table public.expenses add column if not exists device_id text default '';
alter table public.expenses add column if not exists kind text not null default 'expense';  -- 'expense' ou 'refund'

create table if not exists public.photos (
  id         uuid primary key default gen_random_uuid(),
  path       text not null,
  caption    text default '',
  added_by   text default '',
  device_id  text default '',
  created_at timestamptz default now()
);
alter table public.photos add column if not exists place_id uuid references public.places(id) on delete set null;

create table if not exists public.people (
  device_id  text primary key,
  name       text not null default '',
  is_captain boolean not null default false,
  ride_with  text,
  home_at    timestamptz,
  updated_at timestamptz default now()
);

create table if not exists public.votes (
  place_id   uuid not null references public.places(id) on delete cascade,
  device_id  text not null,
  created_at timestamptz default now(),
  primary key (place_id, device_id)
);


-- 2. Le code de soirée -----------------------------------------
--  Invisible depuis le site : seule la fonction ci-dessous le lit.
--  Vide = pas de code (tout le monde peut modifier avec le lien).

create table if not exists public.fete_secret (
  id   int primary key default 1 check (id = 1),
  code text not null default ''
);
insert into public.fete_secret (id) values (1) on conflict (id) do nothing;
alter table public.fete_secret enable row level security;
revoke all on public.fete_secret from anon, authenticated;

create or replace function public.check_code(p_code text)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select coalesce((select code from public.fete_secret where id = 1), '') = ''
      or lower(trim(coalesce(p_code, ''))) = lower(trim((select code from public.fete_secret where id = 1)));
$$;


-- 3. Toutes les modifications passent par cette fonction -------
--  Elle vérifie le code, n'accepte que les tables du site
--  et ne modifie une ligne que par sa clé.

create or replace function public.fete_write(
  p_code  text,
  p_table text,
  p_kind  text,
  p_data  jsonb default null,
  p_match jsonb default null
) returns void
language plpgsql security definer
set search_path = public
as $$
declare
  pk    text[];
  cols  text[];
  clist text;
  sets  text;
  wh    text;
  k     text;
begin
  if not public.check_code(p_code) then
    raise exception 'code_soiree_invalide' using errcode = '28000';
  end if;

  pk := case p_table
    when 'party_config' then array['id']
    when 'places'       then array['id']
    when 'drinks'       then array['device_id']
    when 'members'      then array['id']
    when 'expenses'     then array['id']
    when 'photos'       then array['id']
    when 'people'       then array['device_id']
    when 'votes'        then array['place_id', 'device_id']
    else null end;
  if pk is null then raise exception 'table_interdite: %', p_table; end if;

  -- remise à zéro du « Bien rentré »
  if p_kind = 'reset_home' then
    if p_table <> 'people' then raise exception 'operation_invalide'; end if;
    update public.people set home_at = null where home_at is not null;
    return;
  end if;

  -- création ou remplacement (sert aussi aux renvois après une coupure réseau)
  if p_kind = 'upsert' then
    if p_data is null or jsonb_typeof(p_data) <> 'object' then raise exception 'donnees_invalides'; end if;
    select array_agg(key) into cols
      from jsonb_object_keys(p_data) as key
      where exists (select 1 from information_schema.columns c
                    where c.table_schema = 'public' and c.table_name = p_table and c.column_name = key);
    if cols is null then raise exception 'donnees_invalides'; end if;
    foreach k in array pk loop
      if not (k = any(cols)) then raise exception 'cle_manquante: %', k; end if;
    end loop;
    select string_agg(format('%I', c), ', ') into clist from unnest(cols) as c;
    select string_agg(format('%I = excluded.%I', c, c), ', ') into sets from unnest(cols) as c where not (c = any(pk));
    execute format(
      'insert into public.%I (%s) select %s from jsonb_populate_record(null::public.%I, $1) on conflict (%s) do %s',
      p_table, clist, clist, p_table,
      (select string_agg(format('%I', c), ', ') from unnest(pk) as c),
      case when sets is null then 'nothing' else 'update set ' || sets end
    ) using p_data;
    return;
  end if;

  -- modification ou suppression : uniquement par la clé
  if p_match is null or jsonb_typeof(p_match) <> 'object' then raise exception 'cle_manquante'; end if;
  foreach k in array pk loop
    if not (p_match ? k) then raise exception 'cle_manquante: %', k; end if;
  end loop;
  select string_agg(format('%I::text = %L', c, p_match ->> c), ' and ') into wh from unnest(pk) as c;

  if p_kind = 'update' then
    if p_data is null or jsonb_typeof(p_data) <> 'object' then raise exception 'donnees_invalides'; end if;
    select array_agg(key) into cols
      from jsonb_object_keys(p_data) as key
      where not (key = any(pk))
        and exists (select 1 from information_schema.columns c
                    where c.table_schema = 'public' and c.table_name = p_table and c.column_name = key);
    if cols is null then return; end if;
    select string_agg(format('%I', c), ', ') into clist from unnest(cols) as c;
    execute format(
      'update public.%I set (%s) = (select %s from jsonb_populate_record(null::public.%I, $1)) where %s',
      p_table, clist, clist, p_table, wh
    ) using p_data;
    return;
  end if;

  if p_kind = 'delete' then
    execute format('delete from public.%I where %s', p_table, wh);
    return;
  end if;

  raise exception 'operation_invalide: %', p_kind;
end;
$$;

revoke all on function public.fete_write(text, text, text, jsonb, jsonb) from public;
grant execute on function public.fete_write(text, text, text, jsonb, jsonb) to anon, authenticated;
grant execute on function public.check_code(text) to anon, authenticated;


-- 4. Accès : lecture pour qui a le lien, écriture uniquement via fete_write

do $$
declare t text;
begin
  foreach t in array array['party_config','places','drinks','members','expenses','photos','people','votes'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "fete_all" on public.%I', t);
    execute format('drop policy if exists "fete_read" on public.%I', t);
    execute format('create policy "fete_read" on public.%I for select to anon, authenticated using (true)', t);
  end loop;
end $$;


-- 5. Mises à jour en direct (realtime) --------------------------

do $$
declare t text;
begin
  foreach t in array array['party_config','places','drinks','members','expenses','photos','people','votes'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;


-- 6. Stockage des photos ----------------------------------------
--  Envoi et lecture possibles avec le lien. Plus de suppression de
--  fichiers depuis le site : retirer une photo la masque seulement.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', true, 10485760, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public = true;

drop policy if exists "fete_photos_read"   on storage.objects;
drop policy if exists "fete_photos_add"    on storage.objects;
drop policy if exists "fete_photos_delete" on storage.objects;
create policy "fete_photos_read" on storage.objects for select to anon, authenticated using (bucket_id = 'photos');
create policy "fete_photos_add"  on storage.objects for insert to anon, authenticated with check (bucket_id = 'photos');


-- 7. (Optionnel) Choisir le code de la soirée --------------------
--  Retirez les deux tirets au début de la ligne suivante, remplacez
--  MonCode par le code voulu, puis cliquez sur Run.
--  Pour supprimer le code : mettez '' (deux apostrophes).

-- update public.fete_secret set code = 'MonCode' where id = 1;


-- Terminé. Vous devez voir "Success. No rows returned".
