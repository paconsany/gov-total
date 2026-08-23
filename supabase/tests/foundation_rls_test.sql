-- Run after migrations with: supabase test db
-- Pure PostgreSQL assertions; all fixtures are rolled back.

begin;

create or replace function pg_temp.assert_true(p_condition boolean, p_message text)
returns void language plpgsql as $$
begin
  if not coalesce(p_condition, false) then raise exception 'ASSERTION FAILED: %', p_message; end if;
end;
$$;

create or replace function pg_temp.expect_failure(p_sql text, p_message text)
returns void language plpgsql as $$
begin
  begin
    execute p_sql;
    raise exception 'ASSERTION FAILED: expected failure: %', p_message;
  exception
    when insufficient_privilege or foreign_key_violation or check_violation or raise_exception then
      if sqlerrm like 'ASSERTION FAILED:%' then raise; end if;
  end;
end;
$$;

-- Stable fixture IDs.
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
 ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'a@test.local', '', now(), '{}', '{}', now(), now()),
 ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'b@test.local', '', now(), '{}', '{}', now(), now()),
 ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'none@test.local', '', now(), '{}', '{}', now(), now()),
 ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'inactive@test.local', '', now(), '{}', '{}', now(), now()),
 ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'nopermission@test.local', '', now(), '{}', '{}', now(), now());

insert into public.organizations (id, name, slug) values
 ('20000000-0000-0000-0000-000000000001', 'Prefeitura A', 'prefeitura-a'),
 ('20000000-0000-0000-0000-000000000002', 'Prefeitura B', 'prefeitura-b');

insert into public.departments (id, organization_id, name) values
 ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Administração A'),
 ('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'Administração B');

insert into public.organization_members (id, organization_id, user_id, default_department_id, status, activated_at) values
 ('40000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'active', now()),
 ('40000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', 'active', now()),
 ('40000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000001', 'inactive', null),
 ('40000000-0000-0000-0000-000000000005', '20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000001', 'active', now());

insert into public.roles (id, organization_id, role_key, name) values
 ('50000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'process_manager', 'Gestor de Processos A'),
 ('50000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'process_manager', 'Gestor de Processos B'),
 ('50000000-0000-0000-0000-000000000005', '20000000-0000-0000-0000-000000000001', 'no_permissions', 'Sem permissões');

insert into public.role_permissions (organization_id, role_id, permission_id)
select '20000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', id
from public.permissions where permission_key in ('organization.read','department.read','process.read','process.create','process.update','audit.read');
insert into public.role_permissions (organization_id, role_id, permission_id)
select '20000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000002', id
from public.permissions where permission_key in ('organization.read','department.read','process.read','process.create','process.update','audit.read');

insert into public.member_role_assignments (organization_id, member_id, role_id, department_id) values
 ('20000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', null),
 ('20000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000002', null),
 ('20000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000005', null);

-- User A context.
set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
select pg_temp.assert_true((select count(*) = 1 from public.organizations), 'A reads exactly organization A');
select pg_temp.assert_true(not exists(select 1 from public.organizations where id = '20000000-0000-0000-0000-000000000002'), 'A cannot read B');
select pg_temp.assert_true((select count(*) = 1 from public.departments), 'A reads only its department');

-- A cannot create in B through the critical RPC.
select pg_temp.expect_failure(
  $$select public.create_procurement_process('20000000-0000-0000-0000-000000000002', 2026, 'Processo indevido', 'Objeto indevido', '30000000-0000-0000-0000-000000000002')$$,
  'A cannot create a process in B'
);

-- Authorized creation in A and atomic sequential numbering.
select public.create_procurement_process('20000000-0000-0000-0000-000000000001', 2026, 'Processo A1', 'Objeto do processo A1', '30000000-0000-0000-0000-000000000001');
select public.create_procurement_process('20000000-0000-0000-0000-000000000001', 2026, 'Processo A2', 'Objeto do processo A2', '30000000-0000-0000-0000-000000000001');
select pg_temp.assert_true((select array_agg(public_number order by sequence_number) = array['000001/2026','000002/2026'] from public.procurement_processes), 'sequential public numbering works');
select pg_temp.assert_true((select count(*) >= 2 from public.audit_events where entity_type = 'procurement_processes' and action = 'insert'), 'process creation generates audit events');

-- Even if A guesses B's ID, update affects no row under RLS.
update public.procurement_processes set title = 'Cross tenant update' where organization_id = '20000000-0000-0000-0000-000000000002';
select pg_temp.assert_true(not exists(select 1 from public.procurement_processes where title = 'Cross tenant update'), 'A cannot update B');

-- organization_id is immutable, including for a user linked to more than one tenant.
select pg_temp.expect_failure(
  $$update public.procurement_processes set organization_id = '20000000-0000-0000-0000-000000000002' where public_number = '000001/2026'$$,
  'organization_id cannot be changed'
);

-- Common users cannot mutate append-only audit events.
select pg_temp.expect_failure(
  $$update public.audit_events set metadata = '{"tampered":true}' where true$$,
  'common user cannot update audit events'
);
reset role;

-- User with no membership sees nothing.
set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000003', true);
select pg_temp.assert_true((select count(*) = 0 from public.organizations), 'user without membership reads no organization');
reset role;

-- Inactive membership sees nothing.
set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000004', true);
select pg_temp.assert_true((select count(*) = 0 from public.organizations), 'inactive member reads no organization');
reset role;

-- Active membership without permission cannot create a process.
set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000005', true);
select pg_temp.expect_failure(
  $$select public.create_procurement_process('20000000-0000-0000-0000-000000000001', 2026, 'Sem permissão', 'Não deve criar', '30000000-0000-0000-0000-000000000001')$$,
  'member without process.create cannot create'
);
reset role;

rollback;
