-- PAWON KREATIF — SUPABASE SCHEMA FINAL / FRESH + EXISTING DATABASE SAFE
-- Bisa dijalankan di Supabase SQL Editor pada project baru maupun project lama.
create extension if not exists pgcrypto;

-- ============================================================
-- 1. SITE SETTINGS
-- ============================================================
create table if not exists public.site_settings (
  id text primary key,
  "brandName" text,
  tagline text,
  "waNumber" text,
  email text,
  address text,
  "jamKerja" text,
  "heroTitle" text,
  "heroHighlight" text,
  "heroDesc" text,
  "heroBadge" text,
  "seoTitle" text,
  "seoDescription" text,
  "processTitle" text,
  "ctaTitle" text,
  "ctaDesc" text,
  "primaryColor" text,
  "accentColor" text,
  "bgType" text,
  "logoUrl" text,
  "faviconUrl" text,
  "mapsUrl" text,
  ig text,
  fb text,
  tiktok text,
  updated_at timestamptz not null default now()
);

-- Migrasi aman untuk database lama yang sebelumnya membuat camelCase
-- tanpa tanda kutip, sehingga PostgreSQL menyimpannya sebagai lowercase.
do $$
declare
  pairs text[][] := array[
    array['brandname','brandName'],
    array['wanumber','waNumber'],
    array['jamkerja','jamKerja'],
    array['herotitle','heroTitle'],
    array['herohighlight','heroHighlight'],
    array['herodesc','heroDesc'],
    array['herobadge','heroBadge'],
    array['seotitle','seoTitle'],
    array['seodescription','seoDescription'],
    array['processtitle','processTitle'],
    array['ctatitle','ctaTitle'],
    array['ctadesc','ctaDesc'],
    array['primarycolor','primaryColor'],
    array['accentcolor','accentColor'],
    array['bgtype','bgType'],
    array['logourl','logoUrl'],
    array['faviconurl','faviconUrl'],
    array['mapsurl','mapsUrl']
  ];
  p text[];
  old_exists boolean;
  new_exists boolean;
begin
  foreach p slice 1 in array pairs loop
    select exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='site_settings' and column_name=p[1]
    ) into old_exists;
    select exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='site_settings' and column_name=p[2]
    ) into new_exists;

    if old_exists and not new_exists then
      execute format('alter table public.site_settings rename column %I to %I', p[1], p[2]);
    elsif not old_exists and not new_exists then
      execute format('alter table public.site_settings add column %I text', p[2]);
    end if;
  end loop;
end $$;

-- Pastikan kolom tambahan tersedia bila tabel lama berasal dari versi yang lebih awal.
alter table public.site_settings add column if not exists "jamKerja" text;
alter table public.site_settings add column if not exists "logoUrl" text;
alter table public.site_settings add column if not exists "faviconUrl" text;
alter table public.site_settings add column if not exists "mapsUrl" text;
alter table public.site_settings add column if not exists ig text;
alter table public.site_settings add column if not exists fb text;
alter table public.site_settings add column if not exists tiktok text;
alter table public.site_settings add column if not exists "processTitle" text;

-- Pastikan juga kolom dasar yang mungkin tidak ada pada tabel lama.
alter table public.site_settings add column if not exists "tagline" text;
alter table public.site_settings add column if not exists email text;
alter table public.site_settings add column if not exists address text;
alter table public.site_settings add column if not exists updated_at timestamptz not null default now();

-- ============================================================
-- 2. CONTENT
-- ============================================================
create table if not exists public.content_items (
  id text primary key,
  collection text not null,
  sort_order integer not null default 0,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
do $$
declare
  c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.content_items'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%collection%'
  loop
    execute format('alter table public.content_items drop constraint if exists %I', c.conname);
  end loop;
end $$;

alter table public.content_items add constraint content_items_collection_check
  check (collection in ('services','portfolio','pricing','testimonials','faq','team'));
create index if not exists content_items_collection_idx on public.content_items(collection, sort_order);

-- ============================================================
-- 2B. TEAM
-- Team disimpan di content_items dengan collection = 'team'.
-- Contoh data dapat ditambahkan dari CMS Admin > Tim Pawon Kreatif.

-- ============================================================
-- 3. ORDERS
-- ============================================================
create table if not exists public.orders (
  id text primary key,
  name text not null,
  wa text not null,
  service text,
  paket text,
  detail text not null,
  deadline date,
  budget text,
  notes text,
  attachment_url text,
  status text not null default 'Baru' check (status in ('Baru','Diproses','Menunggu Pembayaran','Sedang Dikerjakan','Revisi','Selesai','Dibatalkan')),
  date timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists orders_created_idx on public.orders(created_at desc);

-- ============================================================
-- 4. ADMIN USERS
-- ============================================================
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
drop policy if exists "Admins can read own admin row" on public.admin_users;
create policy "Admins can read own admin row"
on public.admin_users for select to authenticated
using (user_id = auth.uid());

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.admin_users where user_id = auth.uid()
  );
$$;

-- ============================================================
-- 5. RLS
-- ============================================================
alter table public.site_settings enable row level security;
alter table public.content_items enable row level security;
alter table public.orders enable row level security;

drop policy if exists "Public can read site settings" on public.site_settings;
create policy "Public can read site settings"
on public.site_settings for select using (true);

drop policy if exists "Admins manage site settings" on public.site_settings;
create policy "Admins manage site settings"
on public.site_settings for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Public can read content" on public.content_items;
create policy "Public can read content"
on public.content_items for select using (true);

drop policy if exists "Admins manage content" on public.content_items;
create policy "Admins manage content"
on public.content_items for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Public can create orders" on public.orders;
create policy "Public can create orders"
on public.orders for insert to anon, authenticated
with check (true);

drop policy if exists "Admins manage orders" on public.orders;
create policy "Admins manage orders"
on public.orders for all to authenticated
using (public.is_admin()) with check (public.is_admin());

-- ============================================================
-- 6. DEFAULT SETTINGS
-- ============================================================
insert into public.site_settings (
  id, "brandName", "tagline", "waNumber", email, address,
  "heroTitle", "heroHighlight", "heroDesc", "heroBadge",
  "seoTitle", "seoDescription", "ctaTitle", "ctaDesc",
  "primaryColor", "accentColor", "bgType"
)
values (
  'main',
  'PAWON KREATIF',
  'IDE MU. DESAIN KAMI.',
  '6285956309009',
  'hello@pawonkreatif.com',
  'Desa Lendang Tampel, Kecamatan Batukliang, Kabupaten Lombok Tengah',
  'Solusi Desain Kreatif, Buat Brand Anda Lebih',
  'Berkelas',
  'Kami membantu membuat berbagai kebutuhan desain digital dengan tampilan profesional, modern, dan sesuai karakter brand Anda.',
  'STUDIO DESAIN DIGITAL • LOMBOK',
  'Pawon Kreatif | Jasa Desain Digital Premium',
  'Jasa desain digital profesional untuk branding, sosial media, undangan, banner, dan kebutuhan visual bisnis.',
  'Siap membuat brand Anda terlihat lebih profesional?',
  'Ceritakan kebutuhan desain Anda. Kami bantu dari ide sampai file siap digunakan.',
  '#3b82f6',
  '#8b5cf6',
  'image'
)
on conflict (id) do update set
  "brandName" = excluded."brandName",
  "tagline" = excluded."tagline",
  "waNumber" = excluded."waNumber",
  email = excluded.email,
  address = excluded.address,
  "heroTitle" = excluded."heroTitle",
  "heroHighlight" = excluded."heroHighlight",
  "heroDesc" = excluded."heroDesc",
  "heroBadge" = excluded."heroBadge",
  "seoTitle" = excluded."seoTitle",
  "seoDescription" = excluded."seoDescription",
  "ctaTitle" = excluded."ctaTitle",
  "ctaDesc" = excluded."ctaDesc",
  "primaryColor" = excluded."primaryColor",
  "accentColor" = excluded."accentColor",
  "bgType" = excluded."bgType",
  updated_at = now();

-- ============================================================
-- 7. STORAGE
-- ============================================================
insert into storage.buckets (id, name, public)
values ('pawon-assets', 'pawon-assets', true)
on conflict (id) do update set public = true;

drop policy if exists "Public read Pawon assets" on storage.objects;
create policy "Public read Pawon assets"
on storage.objects for select
using (bucket_id = 'pawon-assets');

drop policy if exists "Authenticated upload Pawon assets" on storage.objects;
drop policy if exists "Public upload Pawon order assets" on storage.objects;
create policy "Public upload Pawon order assets"
on storage.objects for insert to anon, authenticated
with check (bucket_id = 'pawon-assets');

drop policy if exists "Authenticated update Pawon assets" on storage.objects;
create policy "Authenticated update Pawon assets"
on storage.objects for update to authenticated
using (bucket_id = 'pawon-assets') with check (bucket_id = 'pawon-assets');

drop policy if exists "Authenticated delete Pawon assets" on storage.objects;
create policy "Authenticated delete Pawon assets"
on storage.objects for delete to authenticated
using (bucket_id = 'pawon-assets');

-- ============================================================
-- 8. ADMIN SETUP
-- ============================================================
-- Setelah akun admin dibuat di Supabase Authentication > Users,
-- ambil UUID user tersebut lalu jalankan contoh berikut SATU KALI:
-- insert into public.admin_users (user_id, email)
-- values ('UUID_USER_ADMIN', 'email-admin@anda.com')
-- on conflict (user_id) do update set email = excluded.email;
