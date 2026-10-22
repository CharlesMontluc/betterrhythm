-- BetterRhythm project database. Runs once, when the postgres_data volume is first created.
-- Same structure as the Google Sheets tabs, seeded with the 5-day demo history.

CREATE TABLE profile (
  id             SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  peak_hours     TEXT NOT NULL DEFAULT '9-12',
  time_factor    NUMERIC(4,2) NOT NULL DEFAULT 1.00 CHECK (time_factor BETWEEN 0.5 AND 3),
  recent_energy  TEXT NOT NULL DEFAULT 'normal' CHECK (recent_energy IN ('low','normal','high')),
  last_plan_json JSONB,
  blocked_hours  TEXT,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE tasks (
  id            SERIAL PRIMARY KEY,
  date          DATE NOT NULL,
  task          TEXT NOT NULL,
  category      TEXT NOT NULL CHECK (category IN ('deep','light','outdoor')),
  planned_start TIME,
  planned_end   TIME,
  planned_min   INTEGER,
  actual_start  TIME,
  actual_end    TIME,
  actual_min    INTEGER,
  status        TEXT NOT NULL CHECK (status IN ('planned','done','skipped'))
);
CREATE INDEX tasks_date_idx ON tasks (date);

CREATE TABLE signals (
  id         SERIAL PRIMARY KEY,
  date       DATE NOT NULL,
  cmd        TEXT NOT NULL,
  energy     TEXT,
  raw_text   TEXT,
  weather_ok BOOLEAN
);

CREATE TABLE errors (
  id         SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  node       TEXT,
  error      TEXT,
  chat_id    TEXT
);

INSERT INTO profile (peak_hours, time_factor, recent_energy, blocked_hours) VALUES ('9-12', 1.24, 'normal', '12:00-14:00');

INSERT INTO tasks (date, task, category, planned_start, planned_end, planned_min, actual_start, actual_end, actual_min, status) VALUES
  ('2026-10-08', 'report draft', 'deep', '09:00', '11:00', '120', '09:00', '11:30', '150', 'done'),
  ('2026-10-08', 'emails', 'light', '11:15', '11:45', '30', '11:30', '12:10', '40', 'done'),
  ('2026-10-08', 'statistics revision', 'deep', '14:00', '16:00', '120', '14:30', '17:00', '150', 'done'),
  ('2026-10-08', 'gym', 'outdoor', '17:00', '18:00', '60', '17:00', '18:00', '60', 'done'),
  ('2026-10-09', 'project slides', 'deep', '09:00', '11:00', '120', '09:15', '11:45', '150', 'done'),
  ('2026-10-09', 'groceries', 'light', '12:00', '12:30', '30', '12:00', '12:40', '40', 'done'),
  ('2026-10-09', 'reading', 'deep', '15:00', '16:30', '90', '15:30', '17:30', '120', 'done'),
  ('2026-10-09', 'run', 'outdoor', '18:00', '18:45', '45', NULL, NULL, NULL, 'skipped'),
  ('2026-10-10', 'report draft', 'deep', '10:00', '12:00', '120', '10:00', '12:30', '150', 'done'),
  ('2026-10-10', 'laundry', 'light', '13:00', '13:30', '30', '13:00', '13:30', '30', 'done'),
  ('2026-10-10', 'walk', 'outdoor', '16:00', '17:00', '60', '16:00', '17:00', '60', 'done'),
  ('2026-10-11', 'statistics exercises', 'deep', '09:30', '11:30', '120', '09:30', '12:00', '150', 'done'),
  ('2026-10-11', 'coding assignment', 'deep', '14:00', '16:00', '120', '14:00', '17:00', '180', 'done'),
  ('2026-10-11', 'call parents', 'light', '18:00', '18:30', '30', '18:00', '18:45', '45', 'done'),
  ('2026-10-12', 'report final', 'deep', '09:00', '11:00', '120', '09:00', '11:20', '140', 'done'),
  ('2026-10-12', 'emails', 'light', '11:30', '12:00', '30', '11:30', '12:00', '30', 'done'),
  ('2026-10-12', 'meeting prep', 'light', '15:00', '15:30', '30', '15:00', '15:45', '45', 'done'),
  ('2026-10-12', 'gym', 'outdoor', '17:30', '18:30', '60', '17:30', '18:30', '60', 'done');

INSERT INTO signals (date, cmd, energy, raw_text, weather_ok) VALUES
  ('2026-10-08', 'plan', 'normal', 'report draft, emails, statistics revision, gym 17:00', true),
  ('2026-10-09', 'plan', 'normal', 'project slides, groceries, reading, run 18:00', true),
  ('2026-10-10', 'plan', 'low', 'report draft, laundry, walk, slept badly', true),
  ('2026-10-11', 'plan', 'normal', 'statistics exercises, coding assignment, call parents 18:00', true),
  ('2026-10-12', 'plan', 'normal', 'report final, emails, meeting prep 15:00, gym', true);
