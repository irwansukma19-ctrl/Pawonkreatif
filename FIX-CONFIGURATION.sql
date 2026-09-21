-- PAWON KREATIF — FIX KONFIGURASI WEBSITE
-- Jalankan SEKALI di Supabase SQL Editor.
-- Tidak menghapus data lama.

-- 1) Pastikan semua kolom konfigurasi website tersedia.
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "brandName" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "tagline" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "waNumber" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "jamKerja" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "mapsUrl" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS ig TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS fb TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS tiktok TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "logoUrl" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "faviconUrl" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "heroTitle" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "heroHighlight" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "heroDesc" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "heroBadge" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "seoTitle" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "seoDescription" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "processTitle" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "ctaTitle" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "ctaDesc" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "primaryColor" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "accentColor" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS "bgType" TEXT;
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 2) Pastikan row utama tersedia.
INSERT INTO public.site_settings (id, "brandName", "waNumber", "jamKerja", "bgType", updated_at)
VALUES ('main', 'PAWON KREATIF', '6285956309009', 'Senin–Sabtu, 08.00–21.00 WITA', 'image', NOW())
ON CONFLICT (id) DO NOTHING;

-- 3) Pastikan bucket upload logo/favicon tersedia dan publik untuk dibaca website.
INSERT INTO storage.buckets (id, name, public)
VALUES ('pawon-assets', 'pawon-assets', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 4) Pengunjung boleh upload file pesanan; admin juga boleh upload logo/favicon.
DROP POLICY IF EXISTS "Public upload Pawon order assets" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload Pawon assets" ON storage.objects;
CREATE POLICY "Public upload Pawon order assets"
ON storage.objects FOR INSERT TO anon, authenticated
WITH CHECK (bucket_id = 'pawon-assets');

DROP POLICY IF EXISTS "Public read Pawon assets" ON storage.objects;
CREATE POLICY "Public read Pawon assets"
ON storage.objects FOR SELECT
USING (bucket_id = 'pawon-assets');

DROP POLICY IF EXISTS "Authenticated update Pawon assets" ON storage.objects;
CREATE POLICY "Authenticated update Pawon assets"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'pawon-assets')
WITH CHECK (bucket_id = 'pawon-assets');

DROP POLICY IF EXISTS "Authenticated delete Pawon assets" ON storage.objects;
CREATE POLICY "Authenticated delete Pawon assets"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'pawon-assets');

-- 5) Pastikan PostgREST membaca struktur terbaru.
NOTIFY pgrst, 'reload schema';

-- 6) Pemeriksaan hasil.
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'site_settings'
ORDER BY ordinal_position;
