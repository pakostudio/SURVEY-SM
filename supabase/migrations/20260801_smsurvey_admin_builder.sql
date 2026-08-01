-- SMSURVEY: administración autenticada, creación de encuestas y respuestas privadas.
create schema if not exists private;

create table if not exists public.sm_survey_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null default 'Administrador',
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.sm_survey_admins enable row level security;

insert into public.sm_survey_admins (user_id, nombre)
select id, 'Pako Ayala'
from auth.users
where lower(email) = 'pako@sportcstudio.com'
on conflict (user_id) do update set activo = true;

create or replace function private.is_smsurvey_admin()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select auth.uid() is not null
    and exists (
      select 1 from public.sm_survey_admins a
      where a.user_id = auth.uid() and a.activo = true
    );
$$;

revoke all on function private.is_smsurvey_admin() from public;
grant usage on schema private to authenticated;
grant execute on function private.is_smsurvey_admin() to authenticated;

drop policy if exists admins_select on public.sm_admins;
revoke all on public.sm_admins from anon, authenticated;

drop policy if exists sm_survey_admins_self on public.sm_survey_admins;
create policy sm_survey_admins_self on public.sm_survey_admins
for select to authenticated
using (user_id = (select auth.uid()) and activo = true);

drop policy if exists encuestas_publicas on public.sm_encuestas;
drop policy if exists encuestas_admin_select on public.sm_encuestas;
drop policy if exists encuestas_admin_insert on public.sm_encuestas;
drop policy if exists encuestas_admin_update on public.sm_encuestas;
drop policy if exists encuestas_admin_delete on public.sm_encuestas;
create policy encuestas_publicas on public.sm_encuestas
for select to anon using (activa = true);
create policy encuestas_admin_select on public.sm_encuestas
for select to authenticated using ((select private.is_smsurvey_admin()));
create policy encuestas_admin_insert on public.sm_encuestas
for insert to authenticated with check ((select private.is_smsurvey_admin()));
create policy encuestas_admin_update on public.sm_encuestas
for update to authenticated using ((select private.is_smsurvey_admin())) with check ((select private.is_smsurvey_admin()));
create policy encuestas_admin_delete on public.sm_encuestas
for delete to authenticated using ((select private.is_smsurvey_admin()));

drop policy if exists preguntas_publicas on public.sm_preguntas;
drop policy if exists preguntas_admin_select on public.sm_preguntas;
drop policy if exists preguntas_admin_insert on public.sm_preguntas;
drop policy if exists preguntas_admin_update on public.sm_preguntas;
drop policy if exists preguntas_admin_delete on public.sm_preguntas;
create policy preguntas_publicas on public.sm_preguntas
for select to anon using (exists (select 1 from public.sm_encuestas e where e.id = encuesta_id and e.activa = true));
create policy preguntas_admin_select on public.sm_preguntas
for select to authenticated using ((select private.is_smsurvey_admin()));
create policy preguntas_admin_insert on public.sm_preguntas
for insert to authenticated with check ((select private.is_smsurvey_admin()));
create policy preguntas_admin_update on public.sm_preguntas
for update to authenticated using ((select private.is_smsurvey_admin())) with check ((select private.is_smsurvey_admin()));
create policy preguntas_admin_delete on public.sm_preguntas
for delete to authenticated using ((select private.is_smsurvey_admin()));

drop policy if exists respuestas_insertar on public.sm_respuestas;
drop policy if exists respuestas_leer on public.sm_respuestas;
drop policy if exists respuestas_admin_select on public.sm_respuestas;
drop policy if exists respuestas_admin_delete on public.sm_respuestas;
create policy respuestas_insertar on public.sm_respuestas
for insert to anon with check (
  completada = true
  and jsonb_typeof(respuestas) = 'object'
  and exists (select 1 from public.sm_encuestas e where e.id = encuesta_id and e.activa = true)
);
create policy respuestas_admin_select on public.sm_respuestas
for select to authenticated using ((select private.is_smsurvey_admin()));
create policy respuestas_admin_delete on public.sm_respuestas
for delete to authenticated using ((select private.is_smsurvey_admin()));

grant select on public.sm_encuestas, public.sm_preguntas to anon;
grant insert on public.sm_respuestas to anon;
grant select, insert, update, delete on public.sm_encuestas, public.sm_preguntas to authenticated;
grant select, delete on public.sm_respuestas to authenticated;
grant select on public.sm_survey_admins to authenticated;

-- Los índices idx_sm_preguntas_encuesta e idx_sm_respuestas_encuesta ya existen.
drop index if exists public.sm_preguntas_encuesta_orden_idx;
drop index if exists public.sm_respuestas_encuesta_created_idx;
