drop policy if exists sessions_insert_self on public.sessions;
drop policy if exists sessions_update_self on public.sessions;
create policy sessions_insert_self on public.sessions for insert to authenticated with check((select auth.uid())=user_id and auth_session_id=((select auth.jwt())->>'session_id')::uuid);
create policy sessions_update_self on public.sessions for update to authenticated using((select auth.uid())=user_id and auth_session_id=((select auth.jwt())->>'session_id')::uuid) with check((select auth.uid())=user_id and auth_session_id=((select auth.jwt())->>'session_id')::uuid);
revoke insert,update on public.sessions from authenticated;
grant insert(user_id,auth_session_id,ip_address,user_agent) on public.sessions to authenticated;
grant update(last_active_at,ip_address,user_agent,revoked_at,revoke_reason) on public.sessions to authenticated;
