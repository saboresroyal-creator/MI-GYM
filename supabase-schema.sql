-- =====================================================================
-- GymApp — esquema inicial de Supabase
-- Corré esto en el SQL Editor de tu proyecto Supabase nuevo (uno solo,
-- de punta a punta). Todas las tablas están protegidas por RLS: cada
-- usuario autenticado sólo puede ver y escribir sus propias filas.
-- =====================================================================

-- ---------- PERFIL (datos personales + objetivo) ----------
create table if not exists profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  sex           text check (sex in ('m','f')),
  birth_date    date,
  height_cm     numeric,
  weight_kg     numeric,
  activity_level text check (activity_level in ('sedentary','light','moderate','active','very_active')),
  goal          text check (goal in ('cut','maintain','bulk')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create or replace function set_profiles_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
drop trigger if exists trg_profiles_updated_at on profiles;
create trigger trg_profiles_updated_at
  before update on profiles
  for each row execute function set_profiles_updated_at();

-- ---------- PESO CORPORAL (progreso) ----------
create table if not exists body_weight_logs (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  weight_kg  numeric not null,
  logged_at  date not null default current_date
);
create index if not exists bwl_user_date_idx on body_weight_logs(user_id, logged_at desc);

-- ---------- RUTINAS ----------
create table if not exists routines (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  name       text not null,
  created_at timestamptz not null default now()
);

create table if not exists routine_exercises (
  id            bigint generated always as identity primary key,
  routine_id    bigint not null references routines(id) on delete cascade,
  exercise_id   text not null,
  exercise_name text not null,
  target_sets   int,
  target_reps   text,
  order_index   int not null default 0
);
create index if not exists re_routine_idx on routine_exercises(routine_id, order_index);

-- ---------- SESIONES DE ENTRENAMIENTO (historial real) ----------
create table if not exists workout_sessions (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  routine_id  bigint references routines(id) on delete set null,
  routine_name text,
  started_at  timestamptz not null default now(),
  finished_at timestamptz
);

create table if not exists session_sets (
  id            bigint generated always as identity primary key,
  session_id    bigint not null references workout_sessions(id) on delete cascade,
  exercise_id   text not null,
  exercise_name text not null,
  set_number    int not null,
  reps          int,
  weight_kg     numeric,
  logged_at     timestamptz not null default now()
);
create index if not exists ss_session_idx on session_sets(session_id);

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
alter table profiles           enable row level security;
alter table body_weight_logs   enable row level security;
alter table routines           enable row level security;
alter table routine_exercises  enable row level security;
alter table workout_sessions   enable row level security;
alter table session_sets       enable row level security;

drop policy if exists "own profile" on profiles;
create policy "own profile" on profiles for all
  using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "own weight logs" on body_weight_logs;
create policy "own weight logs" on body_weight_logs for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own routines" on routines;
create policy "own routines" on routines for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own routine exercises" on routine_exercises;
create policy "own routine exercises" on routine_exercises for all
  using (exists (select 1 from routines r where r.id = routine_id and r.user_id = auth.uid()))
  with check (exists (select 1 from routines r where r.id = routine_id and r.user_id = auth.uid()));

drop policy if exists "own sessions" on workout_sessions;
create policy "own sessions" on workout_sessions for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own session sets" on session_sets;
create policy "own session sets" on session_sets for all
  using (exists (select 1 from workout_sessions s where s.id = session_id and s.user_id = auth.uid()))
  with check (exists (select 1 from workout_sessions s where s.id = session_id and s.user_id = auth.uid()));
