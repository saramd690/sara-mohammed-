alter table public.auth_attempts add column if not exists ip_hash text;
create index if not exists auth_attempts_ip_hash_time_idx on public.auth_attempts(ip_hash,attempted_at desc);
