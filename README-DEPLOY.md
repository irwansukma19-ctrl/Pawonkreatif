# PAWON KREATIF — FINAL CLEAN FIX

Versi ini mempertahankan fitur yang sudah ada dan fokus memperbaiki:
- pengiriman pesanan setelah deploy
- konfigurasi website yang benar-benar tersimpan dan tampil
- upload logo/favicon langsung ke Supabase Storage
- schema SQL yang aman untuk database lama
- fitur foto Tim Pawon Kreatif
- error pesanan sekarang menampilkan penyebab dari Supabase di console/toast

## 1. WAJIB: isi config.js

Buka `config.js`:

```js
window.PAWON_CONFIG = {
  supabaseUrl: 'https://PROJECT-ANDA.supabase.co',
  supabaseAnonKey: 'ANON/PUBLISHABLE-KEY-ANDA',
  storageBucket: 'pawon-assets'
};
```

Gunakan **Project URL** dan **anon/publishable key**, bukan service_role key.

Catatan: file ZIP yang dibagikan di sini sengaja tidak berisi kredensial Supabase Anda. Jadi dua nilai tersebut harus diisi dengan kredensial project Anda sebelum deploy.

## 2. Jalankan SQL

1. Buka Supabase > SQL Editor.
2. Buat query baru.
3. Salin seluruh isi `supabase-schema.sql`.
4. Klik Run.
5. Setelah selesai, buka Table Editor dan pastikan ada:
   - `site_settings`
   - `content_items`
   - `orders`
   - `admin_users`
6. Buka Storage dan pastikan bucket `pawon-assets` ada dan Public.

SQL ini juga melakukan migrasi kolom camelCase yang pernah bermasalah dan memperluas collection `content_items` agar mendukung `team`.

## 3. Daftarkan admin

Setelah membuat user di Authentication > Users, salin UUID user tersebut.

Jalankan:

```sql
insert into public.admin_users (user_id, email)
values ('UUID-USER-ANDA', 'email-anda@example.com')
on conflict (user_id) do update
set email = excluded.email;
```

## 4. Jika pesanan masih gagal

Versi ini sengaja tidak lagi menyembunyikan error Supabase di balik pesan umum. Jika gagal, toast akan menjelaskan bagian yang gagal.

Untuk memeriksa tabel orders:

```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'orders'
order by ordinal_position;
```

Pastikan minimal ada:
`id, name, wa, service, paket, detail, deadline, budget, notes, attachment_url, status, date, created_at, updated_at`.

Periksa RLS:

```sql
select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in ('orders','site_settings','content_items')
order by tablename, policyname;
```

Harus ada policy `Public can create orders` pada `orders` untuk INSERT.

## 5. Konfigurasi Website

Masuk Admin > Konfigurasi Web.

Yang diperbaiki:
- Nama brand
- tagline
- WhatsApp
- email
- alamat
- jam kerja
- Google Maps
- logo
- favicon
- Instagram
- Facebook
- TikTok

Instagram/Facebook/TikTok boleh diisi `@username` atau URL. Sistem akan mengubah username menjadi URL yang valid.

Logo dan favicon sekarang menggunakan upload file ke Storage. Setelah upload, klik **Simpan Pengaturan**.

## 6. Tim Pawon Kreatif

Masuk Admin > Tim Pawon Kreatif:
- Tambah nama
- Jabatan/peran
- Bio
- Foto
- Urutan

Foto tim akan tampil sebagai section **Tim Kami** di website publik.

## 7. Deploy

Upload:
- `index.html`
- `config.js`
- file pendukung yang ada di ZIP

Jangan mengganti `index.html` dengan versi lama.

Jika menggunakan Vercel/GitHub, setelah mengubah `config.js`, lakukan commit/push lalu tunggu deployment baru.

## Catatan

Supabase anon/publishable key boleh berada di frontend. Jangan pernah memasukkan `service_role` key ke `config.js` atau `index.html`.

## KONFIGURASI WEBSITE — CARA PAKAI

Setelah login sebagai admin, buka **Admin > Konfigurasi Website**. Kolom konfigurasi website **tidak perlu diisi manual satu per satu di SQL**. Form admin akan menyimpan isinya ke tabel `public.site_settings` di Supabase ketika tombol **Simpan Pengaturan** ditekan.

Yang disimpan ke Supabase antara lain: nama brand, tagline, WhatsApp, email, alamat, jam kerja, Google Maps, Instagram, Facebook, TikTok, logo, favicon, hero, CTA, SEO, dan warna.

File `config.js` hanya untuk **koneksi Supabase**:
- `supabaseUrl` = URL project Supabase
- `supabaseAnonKey` = anon/publishable key
- `storageBucket` = `pawon-assets`

### Logo/Favicon
Logo dan favicon di-upload langsung dari Admin > Konfigurasi Website. File masuk ke Supabase Storage bucket `pawon-assets`, lalu URL publiknya otomatis disimpan ke `site_settings`.

Jika database lama sudah pernah dibuat dengan schema versi sebelumnya, jalankan `FIX-CONFIGURATION.sql` sekali di Supabase SQL Editor.

### Jika browser masih menampilkan error `dataUrlBlob is not defined`
Deploy ulang ZIP versi terbaru ini. Error tersebut berasal dari typo pada fungsi konversi gambar; versi ini sudah menggunakan `dataUrlToBlob` secara konsisten.
