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
