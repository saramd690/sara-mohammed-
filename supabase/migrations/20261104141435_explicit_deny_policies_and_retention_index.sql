create policy auth_attempts_deny_client_access on public.auth_attempts for all to anon,authenticated using(false) with check(false);
create policy refresh_tokens_deny_client_access on public.refresh_tokens for all to anon,authenticated using(false) with check(false);
create index if not exists auth_attempts_retention_idx on public.auth_attempts(attempted_at);
