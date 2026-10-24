create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null,
  price numeric(12, 2) not null default 0 check (price >= 0),
  unit text not null check (unit in ('par_jour', 'par_nuit', 'forfait', 'sur_devis')),
  image_url text,
  image_path text,
  created_at timestamptz not null default now()
);

create table if not exists public.gallery (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  caption text not null default '',
  image_url text not null,
  image_path text not null,
  created_at timestamptz not null default now()
);

alter table public.services enable row level security;
alter table public.gallery enable row level security;

create policy "Admins manage services"
  on public.services for all
  to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'ADMIN')
  with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'ADMIN');

create policy "Admins manage gallery"
  on public.gallery for all
  to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'ADMIN')
  with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'ADMIN');

insert into storage.buckets (id, name, public)
values ('services', 'services', true), ('gallery', 'gallery', true)
on conflict (id) do update set public = excluded.public;

create policy "Public reads admin images"
  on storage.objects for select
  to public
  using (bucket_id in ('services', 'gallery'));

create policy "Admins upload service and gallery images"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id in ('services', 'gallery')
    and (auth.jwt() -> 'app_metadata' ->> 'role') = 'ADMIN'
  );

create policy "Admins update service and gallery images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id in ('services', 'gallery')
    and (auth.jwt() -> 'app_metadata' ->> 'role') = 'ADMIN'
  )
  with check (
    bucket_id in ('services', 'gallery')
    and (auth.jwt() -> 'app_metadata' ->> 'role') = 'ADMIN'
  );

create policy "Admins delete service and gallery images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id in ('services', 'gallery')
    and (auth.jwt() -> 'app_metadata' ->> 'role') = 'ADMIN'
  );