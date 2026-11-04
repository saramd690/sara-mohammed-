create index if not exists sessions_auth_session_id_idx on public.sessions(auth_session_id);
create policy sessions_insert_self on public.sessions for insert to authenticated with check((select auth.uid())=user_id);
create policy sessions_update_self on public.sessions for update to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
grant insert,update on public.sessions to authenticated;
