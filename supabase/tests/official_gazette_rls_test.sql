begin;

create or replace function pg_temp.assert_true(condition boolean, message text)
returns void language plpgsql as $$
begin
  if not coalesce(condition, false) then raise exception 'ASSERTION FAILED: %', message; end if;
end;
$$;

create or replace function pg_temp.expect_failure(statement text, message text)
returns void language plpgsql as $$
begin
  execute statement;
  raise exception 'ASSERTION FAILED: expected failure — %', message;
exception
  when others then
    if sqlerrm like 'ASSERTION FAILED:%' then raise; end if;
end;
$$;

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('11000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'gazette-a@test.local', '', now(), '{}', '{}', now(), now()),
  ('11000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'gazette-b@test.local', '', now(), '{}', '{}', now(), now());

insert into public.organizations (id, name, slug) values
  ('21000000-0000-0000-0000-000000000001', 'Prefeitura Gazette A', 'prefeitura-gazette-a'),
  ('21000000-0000-0000-0000-000000000002', 'Prefeitura Gazette B', 'prefeitura-gazette-b');

insert into public.organization_members (id, organization_id, user_id, status, activated_at) values
  ('41000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000001', '11000000-0000-0000-0000-000000000001', 'active', now()),
  ('41000000-0000-0000-0000-000000000002', '21000000-0000-0000-0000-000000000002', '11000000-0000-0000-0000-000000000002', 'active', now());

insert into public.roles (id, organization_id, role_key, name) values
  ('51000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000001', 'gazette_manager', 'Gestor do Diário A'),
  ('51000000-0000-0000-0000-000000000002', '21000000-0000-0000-0000-000000000002', 'gazette_manager', 'Gestor do Diário B');

insert into public.role_permissions (organization_id, role_id, permission_id)
select '21000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000001', id
from public.permissions where permission_key in ('gazette.read', 'gazette.manage', 'gazette.publish', 'audit.read');
insert into public.role_permissions (organization_id, role_id, permission_id)
select '21000000-0000-0000-0000-000000000002', '51000000-0000-0000-0000-000000000002', id
from public.permissions where permission_key in ('gazette.read', 'gazette.manage', 'gazette.publish', 'audit.read');

insert into public.member_role_assignments (organization_id, member_id, role_id) values
  ('21000000-0000-0000-0000-000000000001', '41000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000001'),
  ('21000000-0000-0000-0000-000000000002', '41000000-0000-0000-0000-000000000002', '51000000-0000-0000-0000-000000000002');

set local role authenticated;
select set_config('request.jwt.claim.sub', '11000000-0000-0000-0000-000000000001', true);

insert into public.official_gazette_editions
  (id, organization_id, edition_number, edition_year, publication_date, public_slug, status, created_by)
values
  ('61000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000001', 1, 2026, '2026-08-23', 'gazette-a-2026-000001', 'ready', '11000000-0000-0000-0000-000000000001');

insert into public.official_gazette_acts
  (id, organization_id, act_type, act_number, act_year, issued_on, department_name, section_name, subsection_name, title, summary, content, status, content_hash, created_by)
values
  ('71000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000001', 'Decreto', '101', 2026, '2026-08-23', 'Gabinete', 'Poder Executivo', 'Atos do Prefeito', 'Decreto persistente', 'Ementa', 'Conteúdo integral preservado.', 'approved', repeat('0', 64), '11000000-0000-0000-0000-000000000001');

insert into public.official_gazette_edition_acts
  (id, organization_id, edition_id, act_id, position, created_by)
values
  ('81000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000001', '61000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000001', 1, '11000000-0000-0000-0000-000000000001');

insert into public.official_gazette_files
  (id, organization_id, edition_id, object_path, original_name, mime_type, size_bytes, sha256, created_by)
values
  ('91000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000001', '61000000-0000-0000-0000-000000000001',
   '21000000-0000-0000-0000-000000000001/61000000-0000-0000-0000-000000000001/diario.html',
   'diario-2026-000001.html', 'text/html', 128, repeat('a', 64), '11000000-0000-0000-0000-000000000001');

insert into storage.objects (bucket_id, name, owner_id)
values ('official-gazette', '21000000-0000-0000-0000-000000000001/61000000-0000-0000-0000-000000000001/diario.html', '11000000-0000-0000-0000-000000000001');

select pg_temp.assert_true((select count(*) = 1 from public.official_gazette_editions), 'tenant A reads its draft');
select pg_temp.assert_true(not exists (
  select 1 from public.official_gazette_editions where organization_id = '21000000-0000-0000-0000-000000000002'
), 'tenant A cannot read tenant B');

select public.publish_official_gazette('61000000-0000-0000-0000-000000000001');
select pg_temp.assert_true((select status = 'published' and content_hash ~ '^[0-9a-f]{64}$' from public.official_gazette_editions where id = '61000000-0000-0000-0000-000000000001'), 'publication records immutable hash');
select pg_temp.assert_true((select count(*) >= 4 from public.audit_events where organization_id = '21000000-0000-0000-0000-000000000001'), 'publication writes audit trail');
reset role;

set local role anon;
select pg_temp.assert_true((select count(*) = 1 from public.official_gazette_editions), 'anonymous public reads published edition');
select pg_temp.assert_true((select count(*) = 1 from public.official_gazette_acts), 'anonymous public reads only published act');
select pg_temp.assert_true((select count(*) = 1 from public.official_gazette_files), 'anonymous public reads published file metadata');
select pg_temp.expect_failure(
  $$update public.official_gazette_editions set title = 'Tentativa pública' where true$$,
  'anonymous user cannot write editions'
);
reset role;

select pg_temp.expect_failure(
  $$update public.official_gazette_editions set title = 'Overwrite destrutivo' where id = '61000000-0000-0000-0000-000000000001'$$,
  'published edition cannot be overwritten even by a privileged direct query'
);
select pg_temp.expect_failure(
  $$delete from public.official_gazette_editions where id = '61000000-0000-0000-0000-000000000001'$$,
  'published edition cannot be deleted'
);
select pg_temp.expect_failure(
  $$delete from public.official_gazette_edition_acts where edition_id = '61000000-0000-0000-0000-000000000001'$$,
  'published edition composition cannot be deleted'
);

rollback;
