-- PostgreSQL schema / migration for Big Sister Notes
-- Canonical identities:
--   person1 = داداش کوچیکه ۱
--   person2 = آبجی بزرگه
--   person3 = داداش کوچیکه ۲
-- Legacy roles (me/sister/guest) are migrated when the canonical role is not already present.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(8) UNIQUE NOT NULL,
  room_key VARCHAR(128),
  pair_pin VARCHAR(6) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revision BIGINT NOT NULL DEFAULT 0
);

ALTER TABLE rooms ADD COLUMN IF NOT EXISTS room_key VARCHAR(128);
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS pair_pin VARCHAR(6);
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS revision BIGINT NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS uq_rooms_room_key
  ON rooms(room_key) WHERE room_key IS NOT NULL;

CREATE TABLE IF NOT EXISTS devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  role VARCHAR(32) NOT NULL,
  label VARCHAR(64) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  client_key VARCHAR(128)
);

ALTER TABLE devices ADD COLUMN IF NOT EXISTS label VARCHAR(64);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE devices ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE devices ADD COLUMN IF NOT EXISTS client_key VARCHAR(128);

-- IMPORTANT:
-- Do not re-add a restrictive role CHECK here. The API validates canonical roles,
-- while removing the DB CHECK keeps old installations/migrations from crashing.
ALTER TABLE devices DROP CONSTRAINT IF EXISTS devices_role_check;
DROP INDEX IF EXISTS uq_devices_client_key;
CREATE UNIQUE INDEX IF NOT EXISTS uq_devices_client_key
  ON devices(client_key) WHERE client_key IS NOT NULL;

-- Migrate old role names only where the canonical row does not already exist.
UPDATE devices d
SET role = 'person1'
WHERE d.role IN ('me', 'little_brother', 'brother')
  AND NOT EXISTS (
    SELECT 1 FROM devices x
    WHERE x.room_id = d.room_id AND x.role = 'person1'
  );

UPDATE devices d
SET role = 'person2'
WHERE d.role IN ('sister', 'big_sister')
  AND NOT EXISTS (
    SELECT 1 FROM devices x
    WHERE x.room_id = d.room_id AND x.role = 'person2'
  );

UPDATE devices d
SET role = 'person3'
WHERE d.role IN ('guest', 'little_brother_2', 'brother2')
  AND NOT EXISTS (
    SELECT 1 FROM devices x
    WHERE x.room_id = d.room_id AND x.role = 'person3'
  );

CREATE UNIQUE INDEX IF NOT EXISTS uq_devices_room_role
  ON devices(room_id, role);

CREATE TABLE IF NOT EXISTS room_snapshots (
  room_id UUID PRIMARY KEY REFERENCES rooms(id) ON DELETE CASCADE,
  payload JSONB NOT NULL DEFAULT '{"version":1,"notes":[]}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revision BIGINT NOT NULL DEFAULT 0,
  updated_by UUID REFERENCES devices(id) ON DELETE SET NULL
);

ALTER TABLE room_snapshots ADD COLUMN IF NOT EXISTS payload JSONB NOT NULL DEFAULT '{"version":1,"notes":[]}'::jsonb;
ALTER TABLE room_snapshots ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE room_snapshots ADD COLUMN IF NOT EXISTS revision BIGINT NOT NULL DEFAULT 0;
ALTER TABLE room_snapshots ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES devices(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  type VARCHAR(16) NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  attachment_id UUID,
  attachment_name TEXT,
  reply_to UUID REFERENCES messages(id) ON DELETE SET NULL,
  reaction VARCHAR(16),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ
);

ALTER TABLE messages ADD COLUMN IF NOT EXISTS attachment_name TEXT;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_type_check;
ALTER TABLE messages ADD CONSTRAINT messages_type_check
  CHECK (type IN ('text','image','video','audio','file'));

CREATE INDEX IF NOT EXISTS idx_messages_room_created
  ON messages(room_id, created_at DESC);

CREATE TABLE IF NOT EXISTS media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  uploader_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  kind VARCHAR(16) NOT NULL,
  original_name TEXT NOT NULL,
  mime TEXT NOT NULL,
  bytes BIGINT NOT NULL,
  disk_name TEXT NOT NULL,
  content_hash TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE media ADD COLUMN IF NOT EXISTS content_hash TEXT;
ALTER TABLE media DROP CONSTRAINT IF EXISTS media_kind_check;
ALTER TABLE media ADD CONSTRAINT media_kind_check
  CHECK (kind IN ('image','video','audio','file'));

CREATE INDEX IF NOT EXISTS idx_media_room ON media(room_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_media_room_hash
  ON media(room_id, content_hash) WHERE content_hash IS NOT NULL;

CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  role VARCHAR(32) NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE accounts ADD COLUMN IF NOT EXISTS password_hash TEXT;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE accounts DROP CONSTRAINT IF EXISTS accounts_role_check;

UPDATE accounts a
SET role = 'person1'
WHERE a.role IN ('me', 'little_brother', 'brother')
  AND NOT EXISTS (
    SELECT 1 FROM accounts x
    WHERE x.room_id = a.room_id AND x.role = 'person1'
  );

UPDATE accounts a
SET role = 'person2'
WHERE a.role IN ('sister', 'big_sister')
  AND NOT EXISTS (
    SELECT 1 FROM accounts x
    WHERE x.room_id = a.room_id AND x.role = 'person2'
  );

UPDATE accounts a
SET role = 'person3'
WHERE a.role IN ('guest', 'little_brother_2', 'brother2')
  AND NOT EXISTS (
    SELECT 1 FROM accounts x
    WHERE x.room_id = a.room_id AND x.role = 'person3'
  );

CREATE UNIQUE INDEX IF NOT EXISTS uq_accounts_room_role
  ON accounts(room_id, role);

CREATE TABLE IF NOT EXISTS letters (
  id UUID PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_letters_room_created
  ON letters(room_id, created_at ASC);

CREATE TABLE IF NOT EXISTS mood_checkins (
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  mood VARCHAR(32) NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (room_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_mood_checkins_room ON mood_checkins(room_id);

CREATE TABLE IF NOT EXISTS need_checkins (
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  needs JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (room_id, device_id)
);

CREATE TABLE IF NOT EXISTS draw_choices (
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  choice VARCHAR(8) NOT NULL CHECK (choice IN ('yes','no')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (room_id, device_id)
);
