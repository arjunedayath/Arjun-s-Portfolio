-- ==============================================================================
-- SUPABASE PORTFOLIO SETUP & PERMISSIONS SCRIPT
-- Project URL: https://bgmbvtjrbfqelouaofci.supabase.co
-- Admin UUID:  07307e48-e020-4389-a474-89ab52f22237
-- Run this in the Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Ensure the portfolio table exists
create table if not exists public.portfolio_content (
    id integer primary key check (id = 1),
    data jsonb not null,
    updated_at timestamptz default now()
);

-- 2. CRITICAL: Grant table permissions to anon (visitors) and authenticated (admin)
-- Without these lines, PostgreSQL denies access with: "permission denied for table portfolio_content"
grant usage on schema public to anon, authenticated;
grant select on table public.portfolio_content to anon, authenticated;
grant all on table public.portfolio_content to authenticated;

-- 3. Enable row level security
alter table public.portfolio_content enable row level security;

-- 4. Remove existing policies first to avoid duplicate errors
drop policy if exists "Public can read portfolio" on public.portfolio_content;
drop policy if exists "Public can view portfolio_content" on public.portfolio_content;
drop policy if exists "Admin can insert portfolio" on public.portfolio_content;
drop policy if exists "Admin can insert portfolio_content" on public.portfolio_content;
drop policy if exists "Admin can update portfolio" on public.portfolio_content;
drop policy if exists "Admin can update portfolio_content" on public.portfolio_content;
drop policy if exists "Admin can delete portfolio_content" on public.portfolio_content;

-- 5. Public visitors can read portfolio content
create policy "Public can read portfolio"
on public.portfolio_content
for select
to anon, authenticated
using (true);

-- Only your admin account can insert
create policy "Admin can insert portfolio"
on public.portfolio_content
for insert
to authenticated
with check (
    auth.uid() = '07307e48-e020-4389-a474-89ab52f22237'::uuid
);

-- Only your admin account can update
create policy "Admin can update portfolio"
on public.portfolio_content
for update
to authenticated
using (
    auth.uid() = '07307e48-e020-4389-a474-89ab52f22237'::uuid
)
with check (
    auth.uid() = '07307e48-e020-4389-a474-89ab52f22237'::uuid
);

-- 6. Enable Supabase Realtime (so changes appear on the portfolio without refreshing)
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' 
      and schemaname = 'public' 
      and tablename = 'portfolio_content'
  ) then
    alter publication supabase_realtime add table public.portfolio_content;
  end if;
end $$;

-- 7. Ensure Storage Bucket exists and is public for image uploads
insert into storage.buckets (id, name, public)
values ('portfolio-images', 'portfolio-images', true)
on conflict (id) do update set public = true;

-- 8. Remove existing storage policies to avoid duplicates
drop policy if exists "Public can view portfolio images" on storage.objects;
drop policy if exists "Admin can upload portfolio images" on storage.objects;
drop policy if exists "Admin can update portfolio images" on storage.objects;
drop policy if exists "Admin can delete portfolio images" on storage.objects;

-- Public can view images
create policy "Public can view portfolio images"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'portfolio-images');

-- Only admin can upload
create policy "Admin can upload portfolio images"
on storage.objects
for insert
to authenticated
with check (
    bucket_id = 'portfolio-images'
    and auth.uid() = '07307e48-e020-4389-a474-89ab52f22237'::uuid
);

-- Only admin can update
create policy "Admin can update portfolio images"
on storage.objects
for update
to authenticated
using (
    bucket_id = 'portfolio-images'
    and auth.uid() = '07307e48-e020-4389-a474-89ab52f22237'::uuid
)
with check (
    bucket_id = 'portfolio-images'
    and auth.uid() = '07307e48-e020-4389-a474-89ab52f22237'::uuid
);

-- Only admin can delete
create policy "Admin can delete portfolio images"
on storage.objects
for delete
to authenticated
using (
    bucket_id = 'portfolio-images'
    and auth.uid() = '07307e48-e020-4389-a474-89ab52f22237'::uuid
);
