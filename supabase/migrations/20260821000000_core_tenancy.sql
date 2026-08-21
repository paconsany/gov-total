-- Fundação de tenancy e RBAC. Validar com testes de RLS antes de produção.
create extension if not exists pgcrypto;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null check (char_length(legal_name) between 2 and 200),
  display_name text not null check (char_length(display_name) between 2 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  status text not null default 'active' check (status in ('active', 'suspended', 'archived')),
  settings jsonb not null default '{}'::jsonb check (jsonb_typeof(settings) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete restrict,
  status text not null default 'active' check (status in ('invited', 'active', 'suspended')),
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  unique (organization_id, user_id),
  unique (organization_id, id)
);

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  parent_id uuid,
  name text not null check (char_length(name) between 2 and 160),
  code text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, id),
  unique nulls not distinct (organization_id, code),
  foreign key (organization_id, parent_id)
    references public.departments (organization_id, id) on delete restrict
);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  key text not null unique check (key ~ '^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$'),
  description text not null,
  created_at timestamptz not null default now()
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete restrict,
  key text not null check (key ~ '^[a-z][a-z0-9_]*$'),
  name text not null,
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  check ((is_system and organization_id is null) or (not is_system and organization_id is not null))
);
create unique index roles_system_key_unique on public.roles (key) where organization_id is null;
create unique index roles_tenant_key_unique on public.roles (organization_id, key) where organization_id is not null;

create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);

create table public.member_roles (
  organization_id uuid not null references public.organizations(id) on delete restrict,
  member_id uuid not null,
  role_id uuid not null references public.roles(id) on delete restrict,
  assigned_by uuid references auth.users(id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key (organization_id, member_id, role_id),
  foreign key (organization_id, member_id)
    references public.organization_members (organization_id, id) on delete cascade
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  occurred_at timestamptz not null default now(),
  actor_user_id uuid references auth.users(id) on delete set null,
  actor_type text not null check (actor_type in ('user', 'system', 'integration')),
  action text not null,
  resource_type text not null,
  resource_id uuid,
  request_id uuid,
  correlation_id uuid,
  before_state jsonb,
  after_state jsonb,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object')
);

create index organization_members_user_idx
  on public.organization_members (user_id, organization_id) where status = 'active';
create index departments_organization_idx on public.departments (organization_id);
create index member_roles_member_idx on public.member_roles (organization_id, member_id);
create index audit_events_tenant_time_idx on public.audit_events (organization_id, occurred_at desc);

create or replace function private.is_active_member(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.organization_members membership
    where membership.organization_id = target_organization_id
      and membership.user_id = auth.uid()
      and membership.status = 'active'
  );
$$;

revoke all on function private.is_active_member(uuid) from public;
grant usage on schema private to authenticated;
grant execute on function private.is_active_member(uuid) to authenticated;

alter table public.organizations enable row level security;
alter table public.organizations force row level security;
alter table public.organization_members enable row level security;
alter table public.organization_members force row level security;
alter table public.departments enable row level security;
alter table public.departments force row level security;
alter table public.permissions enable row level security;
alter table public.permissions force row level security;
alter table public.roles enable row level security;
alter table public.roles force row level security;
alter table public.role_permissions enable row level security;
alter table public.role_permissions force row level security;
alter table public.member_roles enable row level security;
alter table public.member_roles force row level security;
alter table public.audit_events enable row level security;
alter table public.audit_events force row level security;

create policy organizations_read_for_members on public.organizations
  for select to authenticated
  using (private.is_active_member(id));

create policy memberships_read_same_tenant on public.organization_members
  for select to authenticated
  using (private.is_active_member(organization_id));

create policy departments_read_same_tenant on public.departments
  for select to authenticated
  using (private.is_active_member(organization_id));

create policy system_permissions_read on public.permissions
  for select to authenticated using (true);

create policy roles_read_available on public.roles
  for select to authenticated
  using (organization_id is null or private.is_active_member(organization_id));

create policy role_permissions_read_available on public.role_permissions
  for select to authenticated
  using (
    exists (
      select 1 from public.roles role
      where role.id = role_id
        and (role.organization_id is null or private.is_active_member(role.organization_id))
    )
  );

create policy member_roles_read_same_tenant on public.member_roles
  for select to authenticated
  using (private.is_active_member(organization_id));

-- Nenhuma policy de INSERT/UPDATE/DELETE é concedida nesta fundação.
-- Mutações futuras passarão por funções transacionais com checagem de permissão.

revoke insert, update, delete, truncate on public.audit_events from anon, authenticated;
revoke insert, update, delete on public.organizations, public.organization_members,
  public.departments, public.permissions, public.roles, public.role_permissions,
  public.member_roles from anon, authenticated;

comment on table public.audit_events is
  'Trilha administrativa append-only; conteúdo sensível e documentos não devem ser armazenados.';
