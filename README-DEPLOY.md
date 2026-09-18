# PAWON KREATIF — PRO V2 MAX FIXED

Versi ini memperbaiki masalah halaman kosong/background-only pada V2 MAX sebelumnya. `index.html` lengkap dan ditutup dengan React mount yang benar.

## Isi
- index.html — website publik + admin CMS
- config.js — konfigurasi Supabase (isi URL + anon key jika ingin cloud)
- supabase-schema.sql — database, RLS, admin_users, storage
- config.example.js — contoh konfigurasi

## Deploy
1. Upload semua file ke hosting/static hosting.
2. Jika memakai Supabase, buka `config.js` dan isi `supabaseUrl` serta `supabaseAnonKey`.
3. Jalankan `supabase-schema.sql` sekali di SQL Editor Supabase.
4. Buat akun admin di Supabase Auth, lalu masukkan UUID-nya ke `public.admin_users` sesuai komentar di SQL.
5. Buka website. Mode publik tetap bisa berjalan tanpa Supabase; CMS admin sengaja dinonaktifkan sampai Supabase dikonfigurasi dan akun admin terdaftar.
6. Pastikan bucket `pawon-assets` dibuat oleh SQL. Referensi gambar pesanan akan diunggah ke Storage dan URL-nya disimpan di `orders.attachment_url`.

## Fitur yang diperbaiki
- React render lengkap, tidak terpotong.
- Sinkronisasi settings/content/orders ke Supabase.
- Pesanan baru benar-benar di-upsert ke tabel `orders`.
- CRUD layanan, portfolio, harga, testimoni, FAQ ke `content_items`.
- RLS admin memakai `admin_users` + `is_admin()`, termasuk verifikasi admin saat login.
- Upload referensi pesanan ke Supabase Storage (bukan base64 di database).
- Konfigurasi brand, WhatsApp, email, alamat, jam kerja, logo, favicon, sosial media, Google Maps.
- SEO title/description dinamis.
- Fallback LocalStorage jika Supabase belum dikonfigurasi.

Catatan keamanan: jangan pernah menaruh Supabase service-role key di browser. Gunakan hanya anon/publishable key. Jangan mengaktifkan kredensial demo/hardcoded password untuk produksi.
