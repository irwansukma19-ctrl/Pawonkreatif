-- PAWON KREATIF - DIAGNOSTIC ORDERS
-- Jalankan setelah supabase-schema.sql jika ingin memastikan tabel/policy orders benar.

select column_name, data_type, is_nullable
from information_schema.columns
where table_schema='public' and table_name='orders'
order by ordinal_position;

select schemaname, tablename, policyname, cmd, roles
from pg_policies
where schemaname='public' and tablename='orders'
order by policyname;

select id, name, wa, budget, status, created_at
from public.orders
order by created_at desc
limit 10;
