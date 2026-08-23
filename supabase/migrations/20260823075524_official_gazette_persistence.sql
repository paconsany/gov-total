-- GOV TOTAL — persistent Official Gazette archive (POC Deodápolis cycle 3).
-- Public reads are limited to published/revoked editions. Administrative writes
-- remain tenant-scoped and publication is an authenticated atomic operation.

begin;

create type public.gazette_edition_status as enum ('draft', 'ready', 'published', 'revoked');
create type public.gazette_act_status as enum ('draft', 'approved', 'published', 'revoked');
create type public.gazette_edition_type as enum ('ordinary', 'extraordinary');
create type public.gazette_file_status as enum ('staged', 'published');

insert into public.permissions (permission_key, resource, action, description) values
  ('gazette.read', 'gazette', 'read', 'Read the organization Official Gazette workspace'),
  ('gazette.manage', 'gazette', 'manage', 'Manage Official Gazette drafts and files'),
  ('gazette.publish', 'gazette', 'publish', 'Publish immutable Official Gazette editions')
on conflict (permission_key) do nothing;

create table public.official_gazette_editions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  edition_number integer not null check (edition_number > 0),
  edition_year integer not null check (edition_year between 2000 and 2200),
  edition_type public.gazette_edition_type not null default 'ordinary',
  publication_date date not null,
  title text not null default 'Diário Oficial',
  public_slug text not null,
  status public.gazette_edition_status not null default 'draft',
  content_hash text,
  published_at timestamptz,
  published_by uuid references auth.users(id) on delete restrict,
  revoked_at timestamptz,
  revoked_by uuid references auth.users(id) on delete restrict,
  revocation_reason text,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete restrict,
  lock_version integer not null default 1,
  constraint official_gazette_editions_org_id_uq unique (organization_id, id),
  constraint official_gazette_editions_number_uq unique (organization_id, edition_year, edition_number),
  constraint official_gazette_editions_slug_uq unique (public_slug),
  constraint official_gazette_editions_slug_format check (public_slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint official_gazette_editions_hash_format check (content_hash is null or content_hash ~ '^[0-9a-f]{64}$'),
  constraint official_gazette_editions_publish_consistency check (
    (status in ('published', 'revoked')) = (published_at is not null and published_by is not null and content_hash is not null)
  ),
  constraint official_gazette_editions_revoke_consistency check (
    (status = 'revoked') = (revoked_at is not null and revoked_by is not null and nullif(trim(revocation_reason), '') is not null)
  )
);

create index official_gazette_editions_public_idx
  on public.official_gazette_editions (publication_date desc, edition_year desc, edition_number desc)
  where status in ('published', 'revoked');
create index official_gazette_editions_org_status_idx
  on public.official_gazette_editions (organization_id, status, publication_date desc);

create table public.official_gazette_acts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  department_id uuid,
  act_type text not null,
  act_number text not null,
  act_year integer not null check (act_year between 2000 and 2200),
  issued_on date not null,
  department_name text not null,
  section_name text not null,
  subsection_name text not null,
  title text not null,
  summary text not null default '',
  content text not null,
  status public.gazette_act_status not null default 'draft',
  content_hash text not null,
  related_act_id uuid,
  approved_at timestamptz,
  approved_by uuid references auth.users(id) on delete restrict,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete restrict,
  lock_version integer not null default 1,
  constraint official_gazette_acts_org_id_uq unique (organization_id, id),
  constraint official_gazette_acts_department_fk foreign key (organization_id, department_id)
    references public.departments(organization_id, id) on delete restrict,
  constraint official_gazette_acts_related_fk foreign key (organization_id, related_act_id)
    references public.official_gazette_acts(organization_id, id) on delete restrict,
  constraint official_gazette_acts_hash_format check (content_hash ~ '^[0-9a-f]{64}$'),
  constraint official_gazette_acts_content check (char_length(trim(title)) >= 3 and char_length(trim(content)) >= 3),
  constraint official_gazette_acts_publish_consistency check ((status in ('published', 'revoked')) = (published_at is not null))
);

create index official_gazette_acts_org_status_idx
  on public.official_gazette_acts (organization_id, status, issued_on desc);
create index official_gazette_acts_search_idx
  on public.official_gazette_acts using gin (
    to_tsvector('portuguese', coalesce(title, '') || ' ' || coalesce(summary, '') || ' ' || coalesce(content, ''))
  );

create table public.official_gazette_edition_acts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  edition_id uuid not null,
  act_id uuid not null,
  position integer not null check (position > 0),
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete restrict,
  constraint official_gazette_edition_acts_org_id_uq unique (organization_id, id),
  constraint official_gazette_edition_acts_edition_fk foreign key (organization_id, edition_id)
    references public.official_gazette_editions(organization_id, id) on delete restrict,
  constraint official_gazette_edition_acts_act_fk foreign key (organization_id, act_id)
    references public.official_gazette_acts(organization_id, id) on delete restrict,
  constraint official_gazette_edition_acts_act_uq unique (organization_id, act_id),
  constraint official_gazette_edition_acts_position_uq unique (organization_id, edition_id, position)
);

create index official_gazette_edition_acts_edition_idx
  on public.official_gazette_edition_acts (organization_id, edition_id, position);

create table public.official_gazette_files (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  edition_id uuid not null,
  bucket_id text not null default 'official-gazette' check (bucket_id = 'official-gazette'),
  object_path text not null,
  original_name text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes > 0 and size_bytes <= 52428800),
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  status public.gazette_file_status not null default 'staged',
  published_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete restrict,
  constraint official_gazette_files_org_id_uq unique (organization_id, id),
  constraint official_gazette_files_edition_fk foreign key (organization_id, edition_id)
    references public.official_gazette_editions(organization_id, id) on delete restrict,
  constraint official_gazette_files_path_uq unique (bucket_id, object_path),
  constraint official_gazette_files_path_scope check (object_path like organization_id::text || '/' || edition_id::text || '/%'),
  constraint official_gazette_files_publish_consistency check ((status = 'published') = (published_at is not null))
);

create index official_gazette_files_edition_idx
  on public.official_gazette_files (organization_id, edition_id, status);

insert into storage.buckets (id, name, public)
values ('official-gazette', 'official-gazette', false)
on conflict (id) do update set public = false;

create or replace function public.set_official_gazette_act_hash()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public, extensions
as $$
begin
  new.content_hash := encode(
    extensions.digest(
      convert_to(concat_ws('|', new.act_type, new.act_number, new.act_year, new.issued_on, new.department_name,
        new.section_name, new.subsection_name, new.title, new.summary, new.content), 'UTF8'),
      'sha256'
    ),
    'hex'
  );
  return new;
end;
$$;

create or replace function public.prevent_published_gazette_mutation()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
begin
  if old.status::text in ('published', 'revoked') then
    raise exception 'published Official Gazette records are immutable; create a rectification or revocation'
      using errcode = '55000';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create or replace function public.prevent_published_edition_structure_mutation()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
declare
  v_edition_id uuid := case when tg_op = 'DELETE' then old.edition_id else new.edition_id end;
begin
  if exists (
    select 1 from public.official_gazette_editions e
    where e.id = v_edition_id and e.status in ('published', 'revoked')
  ) then
    raise exception 'the structure of a published Official Gazette edition is immutable'
      using errcode = '55000';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create trigger official_gazette_acts_hash
  before insert or update of act_type, act_number, act_year, issued_on, department_name,
    section_name, subsection_name, title, summary, content
  on public.official_gazette_acts
  for each row execute function public.set_official_gazette_act_hash();

create trigger official_gazette_editions_updated before update on public.official_gazette_editions
  for each row execute function public.set_update_metadata();
create trigger official_gazette_acts_updated before update on public.official_gazette_acts
  for each row execute function public.set_update_metadata();

create trigger official_gazette_editions_tenant_immutable before update on public.official_gazette_editions
  for each row execute function public.prevent_organization_id_change();
create trigger official_gazette_acts_tenant_immutable before update on public.official_gazette_acts
  for each row execute function public.prevent_organization_id_change();
create trigger official_gazette_edition_acts_tenant_immutable before update on public.official_gazette_edition_acts
  for each row execute function public.prevent_organization_id_change();
create trigger official_gazette_files_tenant_immutable before update on public.official_gazette_files
  for each row execute function public.prevent_organization_id_change();

create trigger official_gazette_editions_immutable before update or delete on public.official_gazette_editions
  for each row execute function public.prevent_published_gazette_mutation();
create trigger official_gazette_acts_immutable before update or delete on public.official_gazette_acts
  for each row execute function public.prevent_published_gazette_mutation();
create trigger official_gazette_files_immutable before update or delete on public.official_gazette_files
  for each row execute function public.prevent_published_gazette_mutation();
create trigger official_gazette_edition_acts_immutable before insert or update or delete on public.official_gazette_edition_acts
  for each row execute function public.prevent_published_edition_structure_mutation();

create trigger official_gazette_editions_audit after insert or update or delete on public.official_gazette_editions
  for each row execute function public.write_audit_event();
create trigger official_gazette_acts_audit after insert or update or delete on public.official_gazette_acts
  for each row execute function public.write_audit_event();
create trigger official_gazette_edition_acts_audit after insert or update or delete on public.official_gazette_edition_acts
  for each row execute function public.write_audit_event();
create trigger official_gazette_files_audit after insert or update or delete on public.official_gazette_files
  for each row execute function public.write_audit_event();

create or replace function public.publish_official_gazette(p_edition_id uuid)
returns public.official_gazette_editions
language plpgsql
security definer
set search_path = pg_catalog, public, storage, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_edition public.official_gazette_editions;
  v_hash_source text;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  select * into v_edition
  from public.official_gazette_editions
  where id = p_edition_id
  for update;

  if not found then raise exception 'edition not found' using errcode = 'P0002'; end if;
  if v_edition.status <> 'ready' then raise exception 'edition must be ready before publication' using errcode = '23514'; end if;
  if not public.has_permission(v_edition.organization_id, 'gazette.publish', null, v_user_id) then
    raise exception 'missing gazette.publish permission' using errcode = '42501';
  end if;
  if not exists (select 1 from public.official_gazette_edition_acts x where x.edition_id = p_edition_id) then
    raise exception 'edition has no acts' using errcode = '23514';
  end if;
  if not exists (
    select 1
    from public.official_gazette_files f
    join storage.objects o on o.bucket_id = f.bucket_id and o.name = f.object_path
    where f.edition_id = p_edition_id and f.status = 'staged'
  ) then
    raise exception 'edition has no uploaded electronic file' using errcode = '23514';
  end if;

  select string_agg(x.position::text || ':' || a.id::text || ':' || a.content_hash, '|' order by x.position)
  into v_hash_source
  from public.official_gazette_edition_acts x
  join public.official_gazette_acts a on a.organization_id = x.organization_id and a.id = x.act_id
  where x.edition_id = p_edition_id;

  update public.official_gazette_acts a
  set status = 'published', published_at = clock_timestamp(), updated_by = v_user_id
  from public.official_gazette_edition_acts x
  where x.edition_id = p_edition_id and x.act_id = a.id and x.organization_id = a.organization_id;

  update public.official_gazette_files
  set status = 'published', published_at = clock_timestamp()
  where edition_id = p_edition_id and status = 'staged';

  update public.official_gazette_editions
  set status = 'published',
      published_at = clock_timestamp(),
      published_by = v_user_id,
      content_hash = encode(extensions.digest(convert_to(v_hash_source, 'UTF8'), 'sha256'), 'hex'),
      updated_by = v_user_id
  where id = p_edition_id
  returning * into v_edition;

  return v_edition;
end;
$$;

revoke all on function public.publish_official_gazette(uuid) from public, anon;
grant execute on function public.publish_official_gazette(uuid) to authenticated;

alter table public.official_gazette_editions enable row level security;
alter table public.official_gazette_acts enable row level security;
alter table public.official_gazette_edition_acts enable row level security;
alter table public.official_gazette_files enable row level security;
alter table public.official_gazette_editions force row level security;
alter table public.official_gazette_acts force row level security;
alter table public.official_gazette_edition_acts force row level security;
alter table public.official_gazette_files force row level security;

create policy official_gazette_editions_public_read on public.official_gazette_editions
  for select to anon, authenticated using (status in ('published', 'revoked'));
create policy official_gazette_editions_admin_read on public.official_gazette_editions
  for select to authenticated using (public.has_permission(organization_id, 'gazette.read', null, auth.uid()));
create policy official_gazette_editions_admin_insert on public.official_gazette_editions
  for insert to authenticated with check (
    status = 'draft' and public.has_permission(organization_id, 'gazette.manage', null, auth.uid())
  );
create policy official_gazette_editions_admin_update on public.official_gazette_editions
  for update to authenticated
  using (status in ('draft', 'ready') and public.has_permission(organization_id, 'gazette.manage', null, auth.uid()))
  with check (status in ('draft', 'ready') and public.has_permission(organization_id, 'gazette.manage', null, auth.uid()));

create policy official_gazette_acts_public_read on public.official_gazette_acts
  for select to anon, authenticated using (exists (
    select 1 from public.official_gazette_edition_acts x
    join public.official_gazette_editions e on e.organization_id = x.organization_id and e.id = x.edition_id
    where x.organization_id = official_gazette_acts.organization_id and x.act_id = official_gazette_acts.id
      and e.status in ('published', 'revoked')
  ));
create policy official_gazette_acts_admin_read on public.official_gazette_acts
  for select to authenticated using (public.has_permission(organization_id, 'gazette.read', department_id, auth.uid()));
create policy official_gazette_acts_admin_insert on public.official_gazette_acts
  for insert to authenticated with check (
    status = 'draft' and public.has_permission(organization_id, 'gazette.manage', department_id, auth.uid())
  );
create policy official_gazette_acts_admin_update on public.official_gazette_acts
  for update to authenticated
  using (status in ('draft', 'approved') and public.has_permission(organization_id, 'gazette.manage', department_id, auth.uid()))
  with check (status in ('draft', 'approved') and public.has_permission(organization_id, 'gazette.manage', department_id, auth.uid()));

create policy official_gazette_edition_acts_public_read on public.official_gazette_edition_acts
  for select to anon, authenticated using (exists (
    select 1 from public.official_gazette_editions e
    where e.organization_id = official_gazette_edition_acts.organization_id
      and e.id = official_gazette_edition_acts.edition_id and e.status in ('published', 'revoked')
  ));
create policy official_gazette_edition_acts_admin_read on public.official_gazette_edition_acts
  for select to authenticated using (public.has_permission(organization_id, 'gazette.read', null, auth.uid()));
create policy official_gazette_edition_acts_admin_insert on public.official_gazette_edition_acts
  for insert to authenticated with check (public.has_permission(organization_id, 'gazette.manage', null, auth.uid()));
create policy official_gazette_edition_acts_admin_update on public.official_gazette_edition_acts
  for update to authenticated
  using (public.has_permission(organization_id, 'gazette.manage', null, auth.uid()))
  with check (public.has_permission(organization_id, 'gazette.manage', null, auth.uid()));
create policy official_gazette_edition_acts_admin_delete on public.official_gazette_edition_acts
  for delete to authenticated using (public.has_permission(organization_id, 'gazette.manage', null, auth.uid()));

create policy official_gazette_files_public_read on public.official_gazette_files
  for select to anon, authenticated using (status = 'published' and exists (
    select 1 from public.official_gazette_editions e
    where e.organization_id = official_gazette_files.organization_id
      and e.id = official_gazette_files.edition_id and e.status in ('published', 'revoked')
  ));
create policy official_gazette_files_admin_read on public.official_gazette_files
  for select to authenticated using (public.has_permission(organization_id, 'gazette.read', null, auth.uid()));
create policy official_gazette_files_admin_insert on public.official_gazette_files
  for insert to authenticated with check (
    status = 'staged' and public.has_permission(organization_id, 'gazette.manage', null, auth.uid())
  );
create policy official_gazette_files_admin_delete_staged on public.official_gazette_files
  for delete to authenticated using (
    status = 'staged' and public.has_permission(organization_id, 'gazette.manage', null, auth.uid())
  );

create policy official_gazette_storage_public_download on storage.objects
  for select to anon, authenticated using (
    bucket_id = 'official-gazette' and exists (
      select 1 from public.official_gazette_files f
      join public.official_gazette_editions e on e.organization_id = f.organization_id and e.id = f.edition_id
      where f.bucket_id = storage.objects.bucket_id and f.object_path = storage.objects.name
        and f.status = 'published' and e.status in ('published', 'revoked')
    )
  );
create policy official_gazette_storage_admin_upload on storage.objects
  for insert to authenticated with check (
    bucket_id = 'official-gazette' and exists (
      select 1 from public.official_gazette_files f
      where f.bucket_id = storage.objects.bucket_id and f.object_path = storage.objects.name
        and f.status = 'staged'
        and public.has_permission(f.organization_id, 'gazette.manage', null, auth.uid())
    )
  );
create policy official_gazette_storage_admin_delete_staged on storage.objects
  for delete to authenticated using (
    bucket_id = 'official-gazette' and exists (
      select 1 from public.official_gazette_files f
      where f.bucket_id = storage.objects.bucket_id and f.object_path = storage.objects.name
        and f.status = 'staged'
        and public.has_permission(f.organization_id, 'gazette.manage', null, auth.uid())
    )
  );

revoke all on public.official_gazette_editions, public.official_gazette_acts,
  public.official_gazette_edition_acts, public.official_gazette_files from anon, authenticated;
grant select on public.official_gazette_editions, public.official_gazette_acts,
  public.official_gazette_edition_acts, public.official_gazette_files to anon;
grant select, insert, update on public.official_gazette_editions, public.official_gazette_acts to authenticated;
grant select, insert, update, delete on public.official_gazette_edition_acts to authenticated;
grant select, insert, delete on public.official_gazette_files to authenticated;

commit;
