-- ============================================================
-- Consolidated Supabase SQL — Authentication & RBAC Platform
-- Repository: saramd690/sara-mohammed-
-- Branch: feature/person-1-platform
-- Generated from the 15 ordered migration files in this branch.
--
-- IMPORTANT:
-- This is a reference/export bundle, NOT a fresh-install script.
-- The migrations are incremental and include later corrections to
-- earlier functions and policies. The target Supabase project already
-- has these migrations applied. Do NOT execute this whole file again
-- against that project; doing so can fail on existing objects/policies.
-- For a new project, use the original ordered files in supabase/migrations
-- through Supabase CLI migration workflow, after reviewing project config.
-- ============================================================



-- ============================================================
-- MIGRATION 01 / 15
-- Source: supabase/migrations/20261104133910_platform_auth_rbac_foundation.sql
-- ============================================================

create extension if not exists pgcrypto with schema extensions;
create table public.users(id uuid primary key references auth.users(id) on delete cascade,display_name text,avatar_url text,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),constraint users_display_name_length check(display_name is null or char_length(display_name) between 1 and 120));
create table public.roles(id uuid primary key default gen_random_uuid(),name text not null unique check(name in('candidate','company','recruiter','admin')),description text,created_at timestamptz not null default now());
create table public.permissions(id uuid primary key default gen_random_uuid(),key text not null unique,description text not null,created_at timestamptz not null default now());
create table public.user_roles(user_id uuid not null references auth.users(id) on delete cascade,role_id uuid not null references public.roles(id) on delete restrict,assigned_at timestamptz not null default now(),assigned_by uuid references auth.users(id) on delete set null,primary key(user_id,role_id));
create table public.role_permissions(role_id uuid not null references public.roles(id) on delete cascade,permission_id uuid not null references public.permissions(id) on delete cascade,created_at timestamptz not null default now(),primary key(role_id,permission_id));
create table public.sessions(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,auth_session_id uuid,ip_address inet,user_agent text,created_at timestamptz not null default now(),last_active_at timestamptz not null default now(),expires_at timestamptz,revoked_at timestamptz,revoke_reason text);
create table public.refresh_tokens(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,session_id uuid references public.sessions(id) on delete set null,token_hash text not null unique,created_at timestamptz not null default now(),expires_at timestamptz not null,revoked_at timestamptz,replaced_by_id uuid references public.refresh_tokens(id) on delete set null,constraint refresh_tokens_hash_length check(char_length(token_hash)>=32));
create table public.auth_attempts(id bigint generated always as identity primary key,identifier_hash text not null,user_id uuid references auth.users(id) on delete set null,ip_address inet,user_agent text,succeeded boolean not null default false,failure_reason text,attempted_at timestamptz not null default now());
create index users_updated_at_idx on public.users(updated_at);create index user_roles_role_id_idx on public.user_roles(role_id);create index user_roles_assigned_by_idx on public.user_roles(assigned_by);create index role_permissions_permission_id_idx on public.role_permissions(permission_id);create index sessions_user_active_idx on public.sessions(user_id,last_active_at desc) where revoked_at is null;create index sessions_expires_at_idx on public.sessions(expires_at) where revoked_at is null;create index refresh_tokens_user_active_idx on public.refresh_tokens(user_id,expires_at) where revoked_at is null;create index refresh_tokens_session_id_idx on public.refresh_tokens(session_id);create index refresh_tokens_replaced_by_id_idx on public.refresh_tokens(replaced_by_id);create index auth_attempts_identifier_time_idx on public.auth_attempts(identifier_hash,attempted_at desc);create index auth_attempts_ip_time_idx on public.auth_attempts(ip_address,attempted_at desc);create index auth_attempts_user_id_idx on public.auth_attempts(user_id);
insert into public.roles(name,description) values('candidate','باحث عن فرصة عمل'),('company','شركة أو جهة توظيف'),('recruiter','مسؤول توظيف'),('admin','مدير المنصة') on conflict(name) do nothing;
insert into public.permissions(key,description) values('profile:read:self','قراءة الملف الشخصي'),('profile:update:self','تعديل الملف الشخصي'),('jobs:read','عرض الوظائف'),('applications:create','إنشاء طلب توظيف'),('applications:read:self','عرض الطلبات الشخصية'),('company:profile:manage','إدارة ملف الشركة'),('jobs:create','إنشاء الوظائف'),('jobs:update:own','تعديل وظائف الشركة'),('applications:read:company','عرض طلبات الشركة'),('candidates:read','عرض المرشحين'),('applications:manage','إدارة الطلبات'),('users:read','عرض المستخدمين'),('users:manage','إدارة المستخدمين'),('roles:assign','إسناد الأدوار'),('roles:manage','إدارة الأدوار'),('sessions:manage:self','إدارة الجلسات الشخصية'),('audit:read','قراءة سجلات التدقيق') on conflict(key) do nothing;
insert into public.role_permissions(role_id,permission_id) select r.id,p.id from public.roles r cross join public.permissions p where (r.name='candidate' and p.key in('profile:read:self','profile:update:self','jobs:read','applications:create','applications:read:self','sessions:manage:self')) or (r.name='company' and p.key in('profile:read:self','profile:update:self','jobs:read','company:profile:manage','jobs:create','jobs:update:own','applications:read:company','sessions:manage:self')) or (r.name='recruiter' and p.key in('profile:read:self','profile:update:self','jobs:read','candidates:read','applications:read:company','applications:manage','sessions:manage:self')) or r.name='admin' on conflict do nothing;
create function public.set_updated_at() returns trigger language plpgsql set search_path='' as $$ begin new.updated_at=now();return new;end;$$;
create trigger users_set_updated_at before update on public.users for each row execute function public.set_updated_at();
create function public.handle_new_auth_user() returns trigger language plpgsql security definer set search_path='' as $$ declare default_role_id uuid;begin insert into public.users(id,display_name,avatar_url) values(new.id,nullif(left(coalesce(new.raw_user_meta_data->>'full_name',''),120),''),nullif(new.raw_user_meta_data->>'avatar_url','')) on conflict(id) do nothing;select id into default_role_id from public.roles where name='candidate';if default_role_id is not null then insert into public.user_roles(user_id,role_id) values(new.id,default_role_id) on conflict do nothing;end if;return new;end;$$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_auth_user();
alter table public.users enable row level security;alter table public.roles enable row level security;alter table public.permissions enable row level security;alter table public.user_roles enable row level security;alter table public.role_permissions enable row level security;alter table public.sessions enable row level security;alter table public.refresh_tokens enable row level security;alter table public.auth_attempts enable row level security;
create policy users_select_self on public.users for select to authenticated using((select auth.uid())=id);create policy users_update_self on public.users for update to authenticated using((select auth.uid())=id) with check((select auth.uid())=id);create policy roles_read_authenticated on public.roles for select to authenticated using(true);create policy permissions_read_authenticated on public.permissions for select to authenticated using(true);create policy role_permissions_read_authenticated on public.role_permissions for select to authenticated using(true);create policy user_roles_read_self on public.user_roles for select to authenticated using((select auth.uid())=user_id);create policy sessions_read_self on public.sessions for select to authenticated using((select auth.uid())=user_id);
grant select,update on public.users to authenticated;grant select on public.roles,public.permissions,public.role_permissions,public.user_roles,public.sessions to authenticated;revoke all on public.refresh_tokens,public.auth_attempts from anon,authenticated;revoke insert,update,delete on public.users from anon,authenticated;revoke insert,update,delete on public.user_roles,public.sessions,public.role_permissions,public.roles,public.permissions from anon,authenticated;revoke all on function public.handle_new_auth_user() from public,anon,authenticated;grant execute on function public.handle_new_auth_user() to supabase_auth_admin;


-- ============================================================
-- MIGRATION 02 / 15
-- Source: supabase/migrations/20261104133937_platform_auth_foreign_key_indexes.sql
-- ============================================================

-- Supporting indexes for foreign-key joins and auth/session lookup paths.
create index if not exists user_roles_role_id_idx on public.user_roles(role_id);
create index if not exists user_roles_assigned_by_idx on public.user_roles(assigned_by);
create index if not exists role_permissions_permission_id_idx on public.role_permissions(permission_id);
create index if not exists sessions_user_active_idx on public.sessions(user_id,last_active_at desc) where revoked_at is null;
create index if not exists sessions_expires_at_idx on public.sessions(expires_at) where revoked_at is null;
create index if not exists refresh_tokens_user_active_idx on public.refresh_tokens(user_id,expires_at) where revoked_at is null;
create index if not exists refresh_tokens_session_id_idx on public.refresh_tokens(session_id);
create index if not exists refresh_tokens_replaced_by_id_idx on public.refresh_tokens(replaced_by_id);
create index if not exists auth_attempts_identifier_time_idx on public.auth_attempts(identifier_hash,attempted_at desc);
create index if not exists auth_attempts_ip_time_idx on public.auth_attempts(ip_address,attempted_at desc);
create index if not exists auth_attempts_user_id_idx on public.auth_attempts(user_id);
create index if not exists users_updated_at_idx on public.users(updated_at);


-- ============================================================
-- MIGRATION 03 / 15
-- Source: supabase/migrations/20261104134958_session_tracking_policies.sql
-- ============================================================

create index if not exists sessions_auth_session_id_idx on public.sessions(auth_session_id);
create policy sessions_insert_self on public.sessions for insert to authenticated with check((select auth.uid())=user_id);
create policy sessions_update_self on public.sessions for update to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
grant insert,update on public.sessions to authenticated;


-- ============================================================
-- MIGRATION 04 / 15
-- Source: supabase/migrations/20261104141229_auth_attempt_rate_limit.sql
-- ============================================================

alter table public.auth_attempts add column if not exists ip_hash text;
create index if not exists auth_attempts_ip_hash_time_idx on public.auth_attempts(ip_hash,attempted_at desc);


-- ============================================================
-- MIGRATION 05 / 15
-- Source: supabase/migrations/20261104141238_atomic_auth_attempt_rate_limit.sql
-- ============================================================

create or replace function public.begin_auth_attempt(p_identifier_hash text,p_ip_hash text,p_ip_address inet default null,p_user_agent text default null) returns table(allowed boolean,attempt_id bigint,retry_after_seconds integer) language plpgsql security definer set search_path='' as $$ declare v_id_count integer;v_ip_count integer;v_id bigint;v_oldest timestamptz;begin if p_identifier_hash is null or length(p_identifier_hash)<>64 or p_ip_hash is null or length(p_ip_hash)<>64 then raise exception 'Invalid fingerprint';end if;perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('identifier:'||p_identifier_hash,0));perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('ip:'||p_ip_hash,0));select count(*) into v_id_count from public.auth_attempts where identifier_hash=p_identifier_hash and attempted_at>now()-interval '15 minutes' and succeeded=false;select count(*) into v_ip_count from public.auth_attempts where ip_hash=p_ip_hash and attempted_at>now()-interval '15 minutes' and succeeded=false;if v_id_count>=5 or v_ip_count>=20 then select min(attempted_at) into v_oldest from public.auth_attempts where (identifier_hash=p_identifier_hash or ip_hash=p_ip_hash) and attempted_at>now()-interval '15 minutes' and succeeded=false;return query select false,null::bigint,greatest(1,ceil(extract(epoch from(v_oldest+interval '15 minutes'-now())))::integer);return;end if;insert into public.auth_attempts(identifier_hash,ip_hash,ip_address,user_agent,succeeded) values(p_identifier_hash,p_ip_hash,p_ip_address,left(p_user_agent,1000),false) returning id into v_id;return query select true,v_id,0;end;$$;revoke all on function public.begin_auth_attempt(text,text,inet,text) from public,anon,authenticated;grant execute on function public.begin_auth_attempt(text,text,inet,text) to service_role;


-- ============================================================
-- MIGRATION 06 / 15
-- Source: supabase/migrations/20261104141251_complete_successful_auth_attempt.sql
-- ============================================================

create or replace function public.complete_auth_attempt(p_attempt_id bigint,p_user_id uuid) returns boolean language plpgsql security definer set search_path='' as $$ begin if auth.uid() is null or auth.uid()<>p_user_id then return false;end if;update public.auth_attempts set succeeded=true,user_id=auth.uid(),failure_reason=null where id=p_attempt_id and succeeded=false and user_id is null and attempted_at>now()-interval '5 minutes';return found;end;$$;
revoke all on function public.complete_auth_attempt(bigint,uuid) from public;grant execute on function public.complete_auth_attempt(bigint,uuid) to authenticated;


-- ============================================================
-- MIGRATION 07 / 15
-- Source: supabase/migrations/20261104141307_secure_session_tracking_rpcs.sql
-- ============================================================

create unique index if not exists sessions_auth_session_id_unique_idx on public.sessions(auth_session_id) where auth_session_id is not null;
create or replace function public.record_current_session(p_ip_address inet default null,p_user_agent text default null) returns uuid language plpgsql security definer set search_path='' as $$ declare v_uid uuid;v_sid uuid;v_id uuid;begin v_uid:=auth.uid();begin v_sid:=(auth.jwt()->>'session_id')::uuid;exception when others then v_sid:=null;end;if v_uid is null or v_sid is null then raise exception 'Authenticated session required';end if;insert into public.sessions(user_id,auth_session_id,ip_address,user_agent) values(v_uid,v_sid,p_ip_address,left(p_user_agent,1000)) on conflict(auth_session_id) where auth_session_id is not null do update set last_active_at=now(),ip_address=excluded.ip_address,user_agent=excluded.user_agent,revoked_at=null,revoke_reason=null returning id into v_id;return v_id;end;$$;
create or replace function public.touch_current_session() returns boolean language plpgsql security definer set search_path='' as $$ declare v_sid uuid;begin begin v_sid:=(auth.jwt()->>'session_id')::uuid;exception when others then return false;end;if auth.uid() is null or v_sid is null then return false;end if;update public.sessions set last_active_at=now() where user_id=auth.uid() and auth_session_id=v_sid and revoked_at is null and(expires_at is null or expires_at>now());return found;end;$$;
create or replace function public.revoke_current_session(p_reason text default 'user_logout') returns boolean language plpgsql security definer set search_path='' as $$ declare v_sid uuid;begin begin v_sid:=(auth.jwt()->>'session_id')::uuid;exception when others then return false;end;if auth.uid() is null or v_sid is null then return false;end if;update public.sessions set revoked_at=now(),revoke_reason=left(p_reason,120) where user_id=auth.uid() and auth_session_id=v_sid and revoked_at is null;return found;end;$$;
revoke all on function public.record_current_session(inet,text) from public;revoke all on function public.touch_current_session() from public;revoke all on function public.revoke_current_session(text) from public;grant execute on function public.record_current_session(inet,text) to authenticated;grant execute on function public.touch_current_session() to authenticated;grant execute on function public.revoke_current_session(text) to authenticated;


-- ============================================================
-- MIGRATION 08 / 15
-- Source: supabase/migrations/20261104141318_admin_role_assignment_rpcs.sql
-- ============================================================

create or replace function public.assign_user_role(p_user_id uuid,p_role_name text) returns boolean language plpgsql security definer set search_path='' as $$ declare v_role_id uuid;begin if auth.uid() is null or not exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id join public.role_permissions rp on rp.role_id=r.id join public.permissions p on p.id=rp.permission_id where ur.user_id=auth.uid() and p.key='roles:assign') then raise exception 'Forbidden';end if;select id into v_role_id from public.roles where name=p_role_name;if v_role_id is null then raise exception 'Unknown role';end if;insert into public.user_roles(user_id,role_id,assigned_by) values(p_user_id,v_role_id,auth.uid()) on conflict(user_id,role_id) do nothing;return true;end;$$;
create or replace function public.remove_user_role(p_user_id uuid,p_role_name text) returns boolean language plpgsql security definer set search_path='' as $$ declare v_role_id uuid;v_admin_count integer;begin if auth.uid() is null or not exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id join public.role_permissions rp on rp.role_id=r.id join public.permissions p on p.id=rp.permission_id where ur.user_id=auth.uid() and p.key='roles:assign') then raise exception 'Forbidden';end if;select id into v_role_id from public.roles where name=p_role_name;if v_role_id is null then raise exception 'Unknown role';end if;if p_role_name='admin' then select count(*) into v_admin_count from public.user_roles ur join public.roles r on r.id=ur.role_id where r.name='admin';if v_admin_count<=1 and exists(select 1 from public.user_roles where user_id=p_user_id and role_id=v_role_id) then raise exception 'Cannot remove last administrator';end if;end if;delete from public.user_roles where user_id=p_user_id and role_id=v_role_id;return found;end;$$;
revoke all on function public.assign_user_role(uuid,text) from public;revoke all on function public.remove_user_role(uuid,text) from public;grant execute on function public.assign_user_role(uuid,text) to authenticated;grant execute on function public.remove_user_role(uuid,text) to authenticated;


-- ============================================================
-- MIGRATION 09 / 15
-- Source: supabase/migrations/20261104141350_restrict_rate_limit_rpcs_to_service_role.sql
-- ============================================================

revoke all on function public.begin_auth_attempt(text,text,inet,text) from anon,authenticated,public;grant execute on function public.begin_auth_attempt(text,text,inet,text) to service_role;revoke all on function public.complete_auth_attempt(bigint,uuid) from anon,authenticated,public;grant execute on function public.complete_auth_attempt(bigint,uuid) to service_role;


-- ============================================================
-- MIGRATION 10 / 15
-- Source: supabase/migrations/20261104141400_serialize_rate_limit_buckets.sql
-- ============================================================

create or replace function public.begin_auth_attempt(p_identifier_hash text,p_ip_hash text,p_ip_address inet default null,p_user_agent text default null) returns table(allowed boolean,attempt_id bigint,retry_after_seconds integer) language plpgsql security definer set search_path='' as $$ declare v_id_count integer;v_ip_count integer;v_id bigint;v_oldest timestamptz;begin if p_identifier_hash is null or length(p_identifier_hash)<>64 or p_ip_hash is null or length(p_ip_hash)<>64 then raise exception 'Invalid fingerprint';end if;perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('identifier:'||p_identifier_hash,0));perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('ip:'||p_ip_hash,0));select count(*) into v_id_count from public.auth_attempts where identifier_hash=p_identifier_hash and attempted_at>now()-interval '15 minutes' and succeeded=false;select count(*) into v_ip_count from public.auth_attempts where ip_hash=p_ip_hash and attempted_at>now()-interval '15 minutes' and succeeded=false;if v_id_count>=5 or v_ip_count>=20 then select min(attempted_at) into v_oldest from public.auth_attempts where (identifier_hash=p_identifier_hash or ip_hash=p_ip_hash) and attempted_at>now()-interval '15 minutes' and succeeded=false;return query select false,null::bigint,greatest(1,ceil(extract(epoch from(v_oldest+interval '15 minutes'-now())))::integer);return;end if;insert into public.auth_attempts(identifier_hash,ip_hash,ip_address,user_agent,succeeded) values(p_identifier_hash,p_ip_hash,p_ip_address,left(p_user_agent,1000),false) returning id into v_id;return query select true,v_id,0;end;$$;revoke all on function public.begin_auth_attempt(text,text,inet,text) from public,anon,authenticated;grant execute on function public.begin_auth_attempt(text,text,inet,text) to service_role;


-- ============================================================
-- MIGRATION 11 / 15
-- Source: supabase/migrations/20261104141629_allow_server_to_complete_login_attempt.sql
-- ============================================================

create or replace function public.complete_auth_attempt(p_attempt_id bigint,p_user_id uuid) returns boolean language plpgsql security definer set search_path='' as $$ begin if coalesce(auth.jwt()->>'role','')<>'service_role' then raise exception 'Service role required';end if;update public.auth_attempts set succeeded=true,user_id=p_user_id,failure_reason=null where id=p_attempt_id and succeeded=false and user_id is null and attempted_at>now()-interval '5 minutes';return found;end;$$;revoke all on function public.complete_auth_attempt(bigint,uuid) from public,anon,authenticated;grant execute on function public.complete_auth_attempt(bigint,uuid) to service_role;


-- ============================================================
-- MIGRATION 12 / 15
-- Source: supabase/migrations/20261104142011_explicit_deny_policies_and_retention_index.sql
-- ============================================================

create policy auth_attempts_deny_client_access on public.auth_attempts for all to anon,authenticated using(false) with check(false);
create policy refresh_tokens_deny_client_access on public.refresh_tokens for all to anon,authenticated using(false) with check(false);
create index if not exists auth_attempts_retention_idx on public.auth_attempts(attempted_at);


-- ============================================================
-- MIGRATION 13 / 15
-- Source: supabase/migrations/20261104142314_tighten_security_definer_function_grants.sql
-- ============================================================

create or replace function public.record_current_session(p_ip_address inet default null,p_user_agent text default null) returns uuid language plpgsql security invoker set search_path='' as $$ declare v_uid uuid;v_sid uuid;v_id uuid;begin v_uid:=auth.uid();begin v_sid:=(auth.jwt()->>'session_id')::uuid;exception when others then v_sid:=null;end;if v_uid is null or v_sid is null then raise exception 'Authenticated session required';end if;insert into public.sessions(user_id,auth_session_id,ip_address,user_agent) values(v_uid,v_sid,p_ip_address,left(p_user_agent,1000)) on conflict(auth_session_id) where auth_session_id is not null do update set last_active_at=now(),ip_address=excluded.ip_address,user_agent=excluded.user_agent,revoked_at=null,revoke_reason=null returning id into v_id;return v_id;end;$$;
create or replace function public.touch_current_session() returns boolean language plpgsql security invoker set search_path='' as $$ declare v_sid uuid;begin begin v_sid:=(auth.jwt()->>'session_id')::uuid;exception when others then return false;end;if auth.uid() is null or v_sid is null then return false;end if;update public.sessions set last_active_at=now() where user_id=auth.uid() and auth_session_id=v_sid and revoked_at is null and(expires_at is null or expires_at>now());return found;end;$$;
create or replace function public.revoke_current_session(p_reason text default 'user_logout') returns boolean language plpgsql security invoker set search_path='' as $$ declare v_sid uuid;begin begin v_sid:=(auth.jwt()->>'session_id')::uuid;exception when others then return false;end;if auth.uid() is null or v_sid is null then return false;end if;update public.sessions set revoked_at=now(),revoke_reason=left(p_reason,120) where user_id=auth.uid() and auth_session_id=v_sid and revoked_at is null;return found;end;$$;
drop policy if exists sessions_insert_self on public.sessions;drop policy if exists sessions_update_self on public.sessions;
create policy sessions_insert_self on public.sessions for insert to authenticated with check((select auth.uid())=user_id);
create policy sessions_update_self on public.sessions for update to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
grant insert,update on public.sessions to authenticated;
revoke all on function public.record_current_session(inet,text) from public,anon;grant execute on function public.record_current_session(inet,text) to authenticated;
revoke all on function public.touch_current_session() from public,anon;grant execute on function public.touch_current_session() to authenticated;
revoke all on function public.revoke_current_session(text) from public,anon;grant execute on function public.revoke_current_session(text) to authenticated;
create or replace function public.assign_user_role(p_actor_id uuid,p_user_id uuid,p_role_name text) returns boolean language plpgsql security definer set search_path='' as $$ declare v_role_id uuid;begin if coalesce(auth.jwt()->>'role','')<>'service_role' then raise exception 'Service role required';end if;if not exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id join public.role_permissions rp on rp.role_id=r.id join public.permissions p on p.id=rp.permission_id where ur.user_id=p_actor_id and p.key='roles:assign') then raise exception 'Forbidden';end if;select id into v_role_id from public.roles where name=p_role_name;if v_role_id is null then raise exception 'Unknown role';end if;insert into public.user_roles(user_id,role_id,assigned_by) values(p_user_id,v_role_id,p_actor_id) on conflict(user_id,role_id) do nothing;return true;end;$$;
create or replace function public.remove_user_role(p_actor_id uuid,p_user_id uuid,p_role_name text) returns boolean language plpgsql security definer set search_path='' as $$ declare v_role_id uuid;v_admin_count integer;begin if coalesce(auth.jwt()->>'role','')<>'service_role' then raise exception 'Service role required';end if;if not exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id join public.role_permissions rp on rp.role_id=r.id join public.permissions p on p.id=rp.permission_id where ur.user_id=p_actor_id and p.key='roles:assign') then raise exception 'Forbidden';end if;select id into v_role_id from public.roles where name=p_role_name;if v_role_id is null then raise exception 'Unknown role';end if;if p_role_name='admin' then select count(*) into v_admin_count from public.user_roles ur join public.roles r on r.id=ur.role_id where r.name='admin';if v_admin_count<=1 and exists(select 1 from public.user_roles where user_id=p_user_id and role_id=v_role_id) then raise exception 'Cannot remove last administrator';end if;end if;delete from public.user_roles where user_id=p_user_id and role_id=v_role_id;return found;end;$$;
revoke all on function public.assign_user_role(uuid,uuid,text) from public,anon,authenticated;grant execute on function public.assign_user_role(uuid,uuid,text) to service_role;
revoke all on function public.remove_user_role(uuid,uuid,text) from public,anon,authenticated;grant execute on function public.remove_user_role(uuid,uuid,text) to service_role;
revoke all on function public.assign_user_role(uuid,text) from public,anon,authenticated,service_role;
revoke all on function public.remove_user_role(uuid,text) from public,anon,authenticated,service_role;


-- ============================================================
-- MIGRATION 14 / 15
-- Source: supabase/migrations/20261104143154_restrict_session_row_mutation.sql
-- ============================================================

drop policy if exists sessions_insert_self on public.sessions;
drop policy if exists sessions_update_self on public.sessions;
create policy sessions_insert_self on public.sessions for insert to authenticated with check((select auth.uid())=user_id and auth_session_id=((select auth.jwt())->>'session_id')::uuid);
create policy sessions_update_self on public.sessions for update to authenticated using((select auth.uid())=user_id and auth_session_id=((select auth.jwt())->>'session_id')::uuid) with check((select auth.uid())=user_id and auth_session_id=((select auth.jwt())->>'session_id')::uuid);
revoke insert,update on public.sessions from authenticated;
grant insert(user_id,auth_session_id,ip_address,user_agent) on public.sessions to authenticated;
grant update(last_active_at,ip_address,user_agent,revoked_at,revoke_reason) on public.sessions to authenticated;


-- ============================================================
-- MIGRATION 15 / 15
-- Source: supabase/migrations/20261104143304_fix_rate_limit_retry_window.sql
-- ============================================================

create or replace function public.begin_auth_attempt(p_identifier_hash text,p_ip_hash text,p_ip_address inet default null,p_user_agent text default null) returns table(allowed boolean,attempt_id bigint,retry_after_seconds integer) language plpgsql security definer set search_path='' as $$ declare v_id_count integer;v_ip_count integer;v_id bigint;v_id_oldest timestamptz;v_ip_oldest timestamptz;v_retry integer:=0;begin if p_identifier_hash is null or length(p_identifier_hash)<>64 or p_ip_hash is null or length(p_ip_hash)<>64 then raise exception 'Invalid fingerprint';end if;perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('identifier:'||p_identifier_hash,0));perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('ip:'||p_ip_hash,0));select count(*),min(attempted_at) into v_id_count,v_id_oldest from public.auth_attempts where identifier_hash=p_identifier_hash and attempted_at>now()-interval '15 minutes' and succeeded=false;select count(*),min(attempted_at) into v_ip_count,v_ip_oldest from public.auth_attempts where ip_hash=p_ip_hash and attempted_at>now()-interval '15 minutes' and succeeded=false;if v_id_count>=5 then v_retry:=greatest(v_retry,ceil(extract(epoch from(v_id_oldest+interval '15 minutes'-now())))::integer);end if;if v_ip_count>=20 then v_retry:=greatest(v_retry,ceil(extract(epoch from(v_ip_oldest+interval '15 minutes'-now())))::integer);end if;if v_id_count>=5 or v_ip_count>=20 then return query select false,null::bigint,greatest(1,v_retry);return;end if;insert into public.auth_attempts(identifier_hash,ip_hash,ip_address,user_agent,succeeded) values(p_identifier_hash,p_ip_hash,p_ip_address,left(p_user_agent,1000),false) returning id into v_id;return query select true,v_id,0;end;$$;revoke all on function public.begin_auth_attempt(text,text,inet,text) from public,anon,authenticated;grant execute on function public.begin_auth_attempt(text,text,inet,text) to service_role;
