-- =====================================================================
-- Mi Gym — plan personalizado automático (rutina + alimentación)
-- Corré esto en el SQL Editor de tu proyecto Supabase de Mi Gym.
-- =====================================================================
alter table profiles add column if not exists experience_level text check (experience_level in ('beginner','intermediate','advanced'));
alter table profiles add column if not exists days_per_week int check (days_per_week between 2 and 6);
alter table profiles add column if not exists equipment text check (equipment in ('gym','home_dumbbells','bodyweight'));
alter table profiles add column if not exists program_started_at timestamptz;
