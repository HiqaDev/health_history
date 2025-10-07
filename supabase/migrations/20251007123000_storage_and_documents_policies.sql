-- Ensure bucket and policies exist for authenticated uploads to storage
begin;

-- Create bucket 'medical-documents' if it does not exist
do $$
begin
  if not exists (select 1 from storage.buckets where id = 'medical-documents') then
    perform storage.create_bucket('medical-documents', false);
  end if;
end$$;

-- Storage policies: allow authenticated users to manage objects under their own folder
drop policy if exists "Allow authenticated uploads to own folder" on storage.objects;
create policy "Allow authenticated uploads to own folder"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'medical-documents'
  and (name like auth.uid()::text || '/%')
);

drop policy if exists "Allow authenticated read of own objects" on storage.objects;
create policy "Allow authenticated read of own objects"
on storage.objects for select to authenticated
using (
  bucket_id = 'medical-documents'
  and (name like auth.uid()::text || '/%')
);

drop policy if exists "Allow authenticated update of own objects" on storage.objects;
create policy "Allow authenticated update of own objects"
on storage.objects for update to authenticated
using (
  bucket_id = 'medical-documents'
  and (name like auth.uid()::text || '/%')
)
with check (
  bucket_id = 'medical-documents'
  and (name like auth.uid()::text || '/%')
);

drop policy if exists "Allow authenticated delete of own objects" on storage.objects;
create policy "Allow authenticated delete of own objects"
on storage.objects for delete to authenticated
using (
  bucket_id = 'medical-documents'
  and (name like auth.uid()::text || '/%')
);

-- Medical documents table RLS policies (own-row access)
-- Note: Only create policies if table exists
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'medical_documents') then
    -- Select own
    execute 'drop policy if exists "Allow select own medical documents" on public.medical_documents';
    execute 'create policy "Allow select own medical documents" on public.medical_documents for select to authenticated using (user_id = auth.uid())';

    -- Insert own
    execute 'drop policy if exists "Allow insert own medical documents" on public.medical_documents';
    execute 'create policy "Allow insert own medical documents" on public.medical_documents for insert to authenticated with check (user_id = auth.uid())';

    -- Update own
    execute 'drop policy if exists "Allow update own medical documents" on public.medical_documents';
    execute 'create policy "Allow update own medical documents" on public.medical_documents for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid())';

    -- Delete own
    execute 'drop policy if exists "Allow delete own medical documents" on public.medical_documents';
    execute 'create policy "Allow delete own medical documents" on public.medical_documents for delete to authenticated using (user_id = auth.uid())';
  end if;
end$$;

commit;