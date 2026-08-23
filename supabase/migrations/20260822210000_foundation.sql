-- GOV TOTAL — foundation: tenancy, RBAC, processes, versioning and audit.
-- This migration intentionally does not persist DFD/ETP/Risks/Prices/TR content yet.

begin;

create extension if not exists pgcrypto with schema extensions;

create type public.record_status as enum ('active', 'inactive', 'archived');
create type public.member_status as enum ('invited', 'active', 'inactive', 'suspended');
create type public.information_classification as enum ('public', 'internal', 'restricted', 'personal_sensitive');
create type public.process_status as enum ('draft', 'in_planning', 'ready_for_approval', 'approved', 'cancelled', 'archived');
create type public.document_type as enum ('demand', 'dfd', 'etp', 'price_research', 'term_reference');
create type public.version_status as enum ('draft', 'concluded', 'approved', 'superseded', 'cancelled');

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete restrict,
  display_name text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_length check (display_name is null or char_length(display_name) between 2 and 160)
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  legal_name text,
  document_number text,
  organization_type text not null default 'municipality',
  slug text not null,
  status public.record_status not null default 'active',
  default_classification public.information_classification not null default 'internal',
  archived_at timestamptz,
  archived_by uuid references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete restrict,
  constraint organizations_name_length check (char_length(name) between 2 and 200),
  constraint organizations_slug_format check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint organizations_archive_consistency check ((status = 'archived') = (archived_at is not null))
);
create unique index organizations_slug_uq on public.organizations (lower(slug));
create unique index organizations_document_number_uq on public.organizations (document_number) where document_number is not null;

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  parent_id uuid,
  name text not null,
  code text,
  department_type text not null default 'department',
  status public.record_status not null default 'active',
  archived_at timestamptz,
  archived_by uuid references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete restrict,
  constraint departments_id_organization_uq unique (organization_id, id),
  constraint departments_parent_fk foreign key (organization_id, parent_id)
    references public.departments(organization_id, id) on delete restrict,
  constraint departments_name_length check (char_length(name) between 2 and 200),
  constraint departments_archive_consistency check ((status = 'archived') = (archived_at is not null))
);
create unique index departments_name_uq on public.departments (organization_id, lower(name)) where status <> 'archived';
create unique index departments_code_uq on public.departments (organization_id, lower(code)) where code is not null and status <> 'archived';
create index departments_parent_idx on public.departments (organization_id, parent_id);

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete restrict,
  default_department_id uuid,
  status public.member_status not null default 'invited',
  valid_from timestamptz not null default now(),
  valid_until timestamptz,
  invited_at timestamptz,
  activated_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete restrict,
  constraint organization_members_id_org_uq unique (organization_id, id),
  constraint organization_members_user_uq unique (organization_id, user_id),
  constraint organization_members_department_fk foreign key (organization_id, default_department_id)
    references public.departments(organization_id, id) on delete restrict,
  constraint organization_members_validity check (valid_until is null or valid_until > valid_from),
  constraint organization_members_archive_consistency check ((status = 'inactive' and archived_at is not null) or archived_at is null)
);
create index organization_members_user_idx on public.organization_members (user_id, organization_id, status);
create index organization_members_department_idx on public.organization_members (organization_id, default_department_id);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  role_key text not null,
  name text not null,
  description text,
  is_system_seed boolean not null default false,
  status public.record_status not null default 'active',
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete restrict,
  constraint roles_id_org_uq unique (organization_id, id),
  constraint roles_key_uq unique (organization_id, role_key),
  constraint roles_key_format check (role_key ~ '^[a-z][a-z0-9_]*$')
);
create index roles_active_idx on public.roles (organization_id, status);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  permission_key text not null unique,
  resource text not null,
  action text not null,
  description text not null,
  created_at timestamptz not null default now(),
  constraint permissions_key_format check (permission_key ~ '^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$'),
  constraint permissions_resource_action_uq unique (resource, action)
);

create table public.role_permissions (
  organization_id uuid not null references public.organizations(id) on delete restrict,
  role_id uuid not null,
  permission_id uuid not null references public.permissions(id) on delete restrict,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete restrict,
  primary key (role_id, permission_id),
  constraint role_permissions_role_fk foreign key (organization_id, role_id)
    references public.roles(organization_id, id) on delete restrict
);
create index role_permissions_org_idx on public.role_permissions (organization_id, role_id);

create table public.member_role_assignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  member_id uuid not null,
  role_id uuid not null,
  department_id uuid,
  valid_from timestamptz not null default now(),
  valid_until timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete restrict,
  constraint member_role_assignments_member_fk foreign key (organization_id, member_id)
    references public.organization_members(organization_id, id) on delete restrict,
  constraint member_role_assignments_role_fk foreign key (organization_id, role_id)
    references public.roles(organization_id, id) on delete restrict,
  constraint member_role_assignments_department_fk foreign key (organization_id, department_id)
    references public.departments(organization_id, id) on delete restrict,
  constraint member_role_assignments_validity check (valid_until is null or valid_until > valid_from),
  constraint member_role_assignments_scope_uq unique nulls not distinct (member_id, role_id, department_id)
);
create index member_role_assignments_lookup_idx on public.member_role_assignments (organization_id, member_id, department_id, valid_until);

create table public.process_number_counters (
  organization_id uuid not null references public.organizations(id) on delete restrict,
  process_year integer not null,
  last_value bigint not null default 0,
  updated_at timestamptz not null default now(),
  primary key (organization_id, process_year),
  constraint process_number_counters_year check (process_year between 2000 and 9999),
  constraint process_number_counters_value check (last_value >= 0)
);

create table public.procurement_processes (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  process_year integer not null,
  sequence_number bigint not null,
  public_number text generated always as (lpad(sequence_number::text, 6, '0') || '/' || process_year::text) stored,
  title text not null,
  object text not null,
  requesting_department_id uuid not null,
  requester_member_id uuid not null,
  process_type text not null default 'procurement',
  priority text not null default 'normal',
  current_stage text not null default 'demand',
  status public.process_status not null default 'draft',
  information_classification public.information_classification not null default 'internal',
  desired_date date,
  preliminary_value numeric(19, 4),
  pca_planned boolean not null default false,
  pca_item text,
  lock_version bigint not null default 1,
  archived_at timestamptz,
  archived_by uuid references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid not null references auth.users(id) on delete restrict,
  constraint procurement_processes_id_org_uq unique (organization_id, id),
  constraint procurement_processes_number_uq unique (organization_id, process_year, sequence_number),
  constraint procurement_processes_public_number_uq unique (organization_id, public_number),
  constraint procurement_processes_department_fk foreign key (organization_id, requesting_department_id)
    references public.departments(organization_id, id) on delete restrict,
  constraint procurement_processes_requester_fk foreign key (organization_id, requester_member_id)
    references public.organization_members(organization_id, id) on delete restrict,
  constraint procurement_processes_year check (process_year between 2000 and 9999),
  constraint procurement_processes_sequence check (sequence_number > 0),
  constraint procurement_processes_title check (char_length(title) between 3 and 300),
  constraint procurement_processes_object check (char_length(object) between 3 and 4000),
  constraint procurement_processes_value check (preliminary_value is null or preliminary_value >= 0),
  constraint procurement_processes_pca check (not pca_planned or nullif(btrim(pca_item), '') is not null),
  constraint procurement_processes_archive_consistency check ((status = 'archived') = (archived_at is not null))
);
create index procurement_processes_list_idx on public.procurement_processes (organization_id, status, process_year desc, sequence_number desc);
create index procurement_processes_department_idx on public.procurement_processes (organization_id, requesting_department_id, status);
create index procurement_processes_requester_idx on public.procurement_processes (organization_id, requester_member_id);

create table public.process_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  process_id uuid not null,
  document_type public.document_type not null,
  version_number integer not null,
  schema_version integer not null default 1,
  status public.version_status not null default 'draft',
  information_classification public.information_classification not null default 'internal',
  content jsonb not null default '{}'::jsonb,
  change_summary text,
  content_hash text,
  lock_version bigint not null default 1,
  concluded_at timestamptz,
  concluded_by uuid references auth.users(id) on delete restrict,
  approved_at timestamptz,
  approved_by uuid references auth.users(id) on delete restrict,
  archived_at timestamptz,
  archived_by uuid references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid not null references auth.users(id) on delete restrict,
  constraint process_versions_process_fk foreign key (organization_id, process_id)
    references public.procurement_processes(organization_id, id) on delete restrict,
  constraint process_versions_number_uq unique (process_id, document_type, version_number),
  constraint process_versions_version check (version_number > 0 and schema_version > 0),
  constraint process_versions_content_object check (jsonb_typeof(content) = 'object'),
  constraint process_versions_concluded_consistency check ((status in ('concluded', 'approved', 'superseded')) = (concluded_at is not null)),
  constraint process_versions_approved_consistency check ((status in ('approved', 'superseded')) = (approved_at is not null))
);
create index process_versions_lookup_idx on public.process_versions (organization_id, process_id, document_type, version_number desc);
create unique index process_versions_one_draft_uq on public.process_versions (process_id, document_type) where status = 'draft';

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  actor_user_id uuid references auth.users(id) on delete restrict,
  action text not null,
  entity_type text not null,
  entity_id uuid not null,
  occurred_at timestamptz not null default clock_timestamp(),
  correlation_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  constraint audit_events_action_format check (action ~ '^[a-z][a-z0-9_.-]*$'),
  constraint audit_events_entity_type_format check (entity_type ~ '^[a-z][a-z0-9_.-]*$'),
  constraint audit_events_metadata_object check (jsonb_typeof(metadata) = 'object')
);
create index audit_events_org_time_idx on public.audit_events (organization_id, occurred_at desc);
create index audit_events_entity_idx on public.audit_events (organization_id, entity_type, entity_id, occurred_at desc);
create index audit_events_actor_idx on public.audit_events (organization_id, actor_user_id, occurred_at desc);

-- Atomic permissions. Roles are tenant-owned and receive permissions through role_permissions.
insert into public.permissions (permission_key, resource, action, description) values
  ('organization.read', 'organization', 'read', 'Read organization metadata'),
  ('organization.manage', 'organization', 'manage', 'Manage organization metadata'),
  ('department.read', 'department', 'read', 'Read departments'),
  ('department.manage', 'department', 'manage', 'Manage departments'),
  ('member.read', 'member', 'read', 'Read organization members'),
  ('member.manage', 'member', 'manage', 'Manage organization members'),
  ('role.manage', 'role', 'manage', 'Manage roles and permission assignments'),
  ('process.read', 'process', 'read', 'Read procurement processes'),
  ('process.create', 'process', 'create', 'Create procurement processes'),
  ('process.update', 'process', 'update', 'Update procurement process drafts'),
  ('process.archive', 'process', 'archive', 'Archive procurement processes'),
  ('audit.read', 'audit', 'read', 'Read audit events');

-- Security helpers. SECURITY DEFINER is used only to read authorization tables under RLS.
create or replace function public.is_active_organization_member(p_organization_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = p_organization_id
      and m.user_id = p_user_id
      and m.status = 'active'
      and m.valid_from <= now()
      and (m.valid_until is null or m.valid_until > now())
      and m.archived_at is null
  );
$$;

create or replace function public.has_permission(
  p_organization_id uuid,
  p_permission_key text,
  p_department_id uuid default null,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.organization_members m
    join public.member_role_assignments a
      on a.organization_id = m.organization_id and a.member_id = m.id
    join public.roles r
      on r.organization_id = a.organization_id and r.id = a.role_id and r.status = 'active'
    join public.role_permissions rp
      on rp.organization_id = r.organization_id and rp.role_id = r.id
    join public.permissions p on p.id = rp.permission_id
    where m.organization_id = p_organization_id
      and m.user_id = p_user_id
      and m.status = 'active'
      and m.valid_from <= now()
      and (m.valid_until is null or m.valid_until > now())
      and m.archived_at is null
      and a.valid_from <= now()
      and (a.valid_until is null or a.valid_until > now())
      and p.permission_key = p_permission_key
      and (a.department_id is null or (p_department_id is not null and a.department_id = p_department_id))
  );
$$;

revoke all on function public.is_active_organization_member(uuid, uuid) from public, anon;
revoke all on function public.has_permission(uuid, text, uuid, uuid) from public, anon;
grant execute on function public.is_active_organization_member(uuid, uuid) to authenticated;
grant execute on function public.has_permission(uuid, text, uuid, uuid) to authenticated;

create or replace function public.prevent_organization_id_change()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
begin
  if new.organization_id is distinct from old.organization_id then
    raise exception 'organization_id is immutable' using errcode = '42501';
  end if;
  return new;
end;
$$;

create or replace function public.prevent_final_version_mutation()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
begin
  if old.status in ('concluded', 'approved', 'superseded') then
    raise exception 'final document versions are immutable' using errcode = '55000';
  end if;
  return new;
end;
$$;

create or replace function public.set_update_metadata()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
begin
  new.updated_at := clock_timestamp();
  if auth.uid() is not null then new.updated_by := auth.uid(); end if;
  if to_jsonb(new) ? 'lock_version' then new.lock_version := coalesce(old.lock_version, 0) + 1; end if;
  return new;
end;
$$;

create or replace function public.write_audit_event()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_row jsonb := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  v_org uuid := coalesce((v_row ->> 'organization_id')::uuid, (v_row ->> 'id')::uuid);
  v_id uuid := (v_row ->> 'id')::uuid;
  v_correlation text := nullif(current_setting('app.correlation_id', true), '');
begin
  insert into public.audit_events (
    organization_id, actor_user_id, action, entity_type, entity_id, correlation_id, metadata
  ) values (
    v_org,
    auth.uid(),
    lower(tg_op),
    tg_table_name,
    v_id,
    case when v_correlation is null then null else v_correlation::uuid end,
    jsonb_build_object('source', 'database_trigger')
  );
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;
revoke all on function public.write_audit_event() from public, anon, authenticated;

create trigger organizations_updated before update on public.organizations for each row execute function public.set_update_metadata();
create trigger departments_updated before update on public.departments for each row execute function public.set_update_metadata();
create trigger members_updated before update on public.organization_members for each row execute function public.set_update_metadata();
create trigger roles_updated before update on public.roles for each row execute function public.set_update_metadata();
create trigger processes_updated before update on public.procurement_processes for each row execute function public.set_update_metadata();
create trigger versions_updated before update on public.process_versions for each row execute function public.set_update_metadata();

create trigger departments_tenant_immutable before update on public.departments for each row execute function public.prevent_organization_id_change();
create trigger members_tenant_immutable before update on public.organization_members for each row execute function public.prevent_organization_id_change();
create trigger roles_tenant_immutable before update on public.roles for each row execute function public.prevent_organization_id_change();
create trigger role_permissions_tenant_immutable before update on public.role_permissions for each row execute function public.prevent_organization_id_change();
create trigger assignments_tenant_immutable before update on public.member_role_assignments for each row execute function public.prevent_organization_id_change();
create trigger processes_tenant_immutable before update on public.procurement_processes for each row execute function public.prevent_organization_id_change();
create trigger versions_tenant_immutable before update on public.process_versions for each row execute function public.prevent_organization_id_change();
create trigger final_version_immutable before update or delete on public.process_versions for each row execute function public.prevent_final_version_mutation();

create trigger organizations_audit after insert or update or delete on public.organizations for each row execute function public.write_audit_event();
create trigger departments_audit after insert or update or delete on public.departments for each row execute function public.write_audit_event();
create trigger members_audit after insert or update or delete on public.organization_members for each row execute function public.write_audit_event();
create trigger roles_audit after insert or update or delete on public.roles for each row execute function public.write_audit_event();
create trigger assignments_audit after insert or update or delete on public.member_role_assignments for each row execute function public.write_audit_event();
create trigger processes_audit after insert or update or delete on public.procurement_processes for each row execute function public.write_audit_event();
create trigger versions_audit after insert or update or delete on public.process_versions for each row execute function public.write_audit_event();

-- Critical operation: tenant-checked, permission-checked and atomically numbered.
create or replace function public.create_procurement_process(
  p_organization_id uuid,
  p_process_year integer,
  p_title text,
  p_object text,
  p_requesting_department_id uuid,
  p_priority text default 'normal',
  p_desired_date date default null,
  p_preliminary_value numeric default null,
  p_pca_planned boolean default false,
  p_pca_item text default null,
  p_information_classification public.information_classification default 'internal'
)
returns public.procurement_processes
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_member public.organization_members;
  v_sequence bigint;
  v_process public.procurement_processes;
begin
  if v_user_id is null then raise exception 'authentication required' using errcode = '28000'; end if;
  if p_process_year < 2000 or p_process_year > 9999 then raise exception 'invalid process year' using errcode = '22023'; end if;

  select * into v_member
  from public.organization_members m
  where m.organization_id = p_organization_id
    and m.user_id = v_user_id
    and m.status = 'active'
    and m.valid_from <= now()
    and (m.valid_until is null or m.valid_until > now())
    and m.archived_at is null;
  if not found then raise exception 'active organization membership required' using errcode = '42501'; end if;

  if not public.has_permission(p_organization_id, 'process.create', p_requesting_department_id, v_user_id) then
    raise exception 'process.create permission required' using errcode = '42501';
  end if;

  perform 1 from public.departments d
  where d.organization_id = p_organization_id and d.id = p_requesting_department_id and d.status = 'active';
  if not found then raise exception 'active department not found in organization' using errcode = '23503'; end if;

  insert into public.process_number_counters (organization_id, process_year, last_value)
  values (p_organization_id, p_process_year, 1)
  on conflict (organization_id, process_year)
  do update set last_value = public.process_number_counters.last_value + 1, updated_at = clock_timestamp()
  returning last_value into v_sequence;

  insert into public.procurement_processes (
    organization_id, process_year, sequence_number, title, object,
    requesting_department_id, requester_member_id, priority, desired_date,
    preliminary_value, pca_planned, pca_item, information_classification,
    created_by, updated_by
  ) values (
    p_organization_id, p_process_year, v_sequence, p_title, p_object,
    p_requesting_department_id, v_member.id, p_priority, p_desired_date,
    p_preliminary_value, p_pca_planned, p_pca_item, p_information_classification,
    v_user_id, v_user_id
  ) returning * into v_process;

  return v_process;
end;
$$;
revoke all on function public.create_procurement_process(uuid, integer, text, text, uuid, text, date, numeric, boolean, text, public.information_classification) from public, anon;
grant execute on function public.create_procurement_process(uuid, integer, text, text, uuid, text, date, numeric, boolean, text, public.information_classification) to authenticated;

-- RLS deny-by-default: every exposed table enables and forces RLS.
alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.departments enable row level security;
alter table public.organization_members enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.member_role_assignments enable row level security;
alter table public.process_number_counters enable row level security;
alter table public.procurement_processes enable row level security;
alter table public.process_versions enable row level security;
alter table public.audit_events enable row level security;

alter table public.profiles force row level security;
alter table public.organizations force row level security;
alter table public.departments force row level security;
alter table public.organization_members force row level security;
alter table public.roles force row level security;
alter table public.permissions force row level security;
alter table public.role_permissions force row level security;
alter table public.member_role_assignments force row level security;
alter table public.process_number_counters force row level security;
alter table public.procurement_processes force row level security;
alter table public.process_versions force row level security;
alter table public.audit_events force row level security;

create policy profiles_self_read on public.profiles for select to authenticated using (user_id = auth.uid());
create policy profiles_self_update on public.profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy organizations_read on public.organizations for select to authenticated
  using (public.has_permission(id, 'organization.read', null, auth.uid()));
create policy organizations_update on public.organizations for update to authenticated
  using (public.has_permission(id, 'organization.manage', null, auth.uid()))
  with check (public.has_permission(id, 'organization.manage', null, auth.uid()));

create policy departments_read on public.departments for select to authenticated
  using (public.has_permission(organization_id, 'department.read', id, auth.uid()));
create policy departments_manage on public.departments for all to authenticated
  using (public.has_permission(organization_id, 'department.manage', id, auth.uid()))
  with check (public.has_permission(organization_id, 'department.manage', id, auth.uid()));

create policy members_read on public.organization_members for select to authenticated
  using (user_id = auth.uid() or public.has_permission(organization_id, 'member.read', default_department_id, auth.uid()));
create policy members_manage on public.organization_members for all to authenticated
  using (public.has_permission(organization_id, 'member.manage', default_department_id, auth.uid()))
  with check (public.has_permission(organization_id, 'member.manage', default_department_id, auth.uid()));

create policy roles_read on public.roles for select to authenticated
  using (public.is_active_organization_member(organization_id, auth.uid()));
create policy roles_manage on public.roles for all to authenticated
  using (public.has_permission(organization_id, 'role.manage', null, auth.uid()))
  with check (public.has_permission(organization_id, 'role.manage', null, auth.uid()));

create policy permissions_read on public.permissions for select to authenticated
  using (exists (select 1 from public.organization_members m where m.user_id = auth.uid() and m.status = 'active' and m.archived_at is null));

create policy role_permissions_read on public.role_permissions for select to authenticated
  using (public.is_active_organization_member(organization_id, auth.uid()));
create policy role_permissions_manage on public.role_permissions for all to authenticated
  using (public.has_permission(organization_id, 'role.manage', null, auth.uid()))
  with check (public.has_permission(organization_id, 'role.manage', null, auth.uid()));

create policy assignments_read on public.member_role_assignments for select to authenticated
  using (public.has_permission(organization_id, 'member.read', department_id, auth.uid()) or public.has_permission(organization_id, 'role.manage', department_id, auth.uid()));
create policy assignments_manage on public.member_role_assignments for all to authenticated
  using (public.has_permission(organization_id, 'role.manage', department_id, auth.uid()))
  with check (public.has_permission(organization_id, 'role.manage', department_id, auth.uid()));

-- No policies or client grants for counters: only the secure RPC may mutate them.
create policy processes_read on public.procurement_processes for select to authenticated
  using (public.has_permission(organization_id, 'process.read', requesting_department_id, auth.uid()));
create policy processes_update on public.procurement_processes for update to authenticated
  using (status <> 'archived' and public.has_permission(organization_id, 'process.update', requesting_department_id, auth.uid()))
  with check (status <> 'archived' and public.has_permission(organization_id, 'process.update', requesting_department_id, auth.uid()));

create policy versions_read on public.process_versions for select to authenticated
  using (exists (
    select 1 from public.procurement_processes p
    where p.organization_id = process_versions.organization_id
      and p.id = process_versions.process_id
      and public.has_permission(p.organization_id, 'process.read', p.requesting_department_id, auth.uid())
  ));
create policy versions_update_draft on public.process_versions for update to authenticated
  using (status = 'draft' and exists (
    select 1 from public.procurement_processes p
    where p.organization_id = process_versions.organization_id
      and p.id = process_versions.process_id
      and public.has_permission(p.organization_id, 'process.update', p.requesting_department_id, auth.uid())
  ))
  with check (status in ('draft', 'concluded') and exists (
    select 1 from public.procurement_processes p
    where p.organization_id = process_versions.organization_id
      and p.id = process_versions.process_id
      and public.has_permission(p.organization_id, 'process.update', p.requesting_department_id, auth.uid())
  ));

create policy audit_read on public.audit_events for select to authenticated
  using (public.has_permission(organization_id, 'audit.read', null, auth.uid()));

-- Explicit grants. RLS still applies. Critical inserts are RPC-only.
revoke all on all tables in schema public from anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select, update on public.organizations to authenticated;
grant select, insert, update on public.departments to authenticated;
grant select, insert, update on public.organization_members to authenticated;
grant select, insert, update on public.roles to authenticated;
grant select on public.permissions to authenticated;
grant select, insert, update, delete on public.role_permissions to authenticated;
grant select, insert, update, delete on public.member_role_assignments to authenticated;
grant select, update on public.procurement_processes to authenticated;
grant select, update on public.process_versions to authenticated;
grant select on public.audit_events to authenticated;

commit;
