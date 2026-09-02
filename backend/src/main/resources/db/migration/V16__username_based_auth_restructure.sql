-- ============================================================
-- V16__username_based_auth_restructure.sql
-- ProValuer Commercial — Username-Based Auth & Identity Restructure
-- ============================================================

-- 1. Add username column
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(100);

-- 2. Migrate existing accounts to dedicated target usernames and standard roles
UPDATE users 
   SET username = 'admin', 
       role = 'SUPER_ADMIN',
       full_name = 'Master System Administrator'
 WHERE email = 'superadmin@provaluer.com' OR role = 'SUPER_ADMIN' OR username = 'admin';

UPDATE users 
   SET username = 'poojitha', 
       role = 'PA',
       full_name = 'Poojitha Property Analyst'
 WHERE email = 'pa@provaluer.com' AND username IS NULL;

UPDATE users 
   SET username = 'divya', 
       role = 'SPA',
       full_name = 'Divya Senior Property Analyst'
 WHERE email = 'spa@provaluer.com' AND username IS NULL;

UPDATE users 
   SET username = 'naga', 
       role = 'CLIENT',
       full_name = 'Naga Client'
 WHERE email = 'client@provaluer.com' AND username IS NULL;

-- 3. Fallback for any other user record created dynamically
UPDATE users 
   SET username = LOWER(SPLIT_PART(email, '@', 1)) 
 WHERE username IS NULL;

-- 4. Enforce NOT NULL and UNIQUE constraint on username
ALTER TABLE users ALTER COLUMN username SET NOT NULL;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_users_username') THEN 
        ALTER TABLE users ADD CONSTRAINT uq_users_username UNIQUE (username); 
    END IF; 
END $$;

CREATE INDEX IF NOT EXISTS idx_users_username_lower ON users (LOWER(username));

-- 5. Relax email constraint to optional contact field
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

-- 6. Ensure Master Account 'admin' and initial users exist if missing
INSERT INTO users (username, email, password, role, full_name, mobile_number, accepted_tc_version, is_locked, is_deleted, created_at, updated_at)
VALUES ('admin', 'admin@provaluer.com', '$2a$10$9VXqoCiZgs72jN/tf0xlsOSASqvnSAkqbaqApUWORvxP7WQxHQMQy', 'SUPER_ADMIN', 'Master System Administrator', '9000000000', 'v1.0', FALSE, FALSE, NOW(), NOW())
ON CONFLICT (username) DO UPDATE SET role = 'SUPER_ADMIN', is_locked = FALSE, is_deleted = FALSE;

INSERT INTO users (username, email, password, role, full_name, mobile_number, accepted_tc_version, is_locked, is_deleted, created_at, updated_at)
VALUES 
('poojitha', 'poojitha@provaluer.com', '$2a$10$9VXqoCiZgs72jN/tf0xlsOSASqvnSAkqbaqApUWORvxP7WQxHQMQy', 'PA', 'Poojitha Property Analyst', '9876543211', 'v1.0', FALSE, FALSE, NOW(), NOW()),
('divya',    'divya@provaluer.com',    '$2a$10$9VXqoCiZgs72jN/tf0xlsOSASqvnSAkqbaqApUWORvxP7WQxHQMQy', 'SPA', 'Divya Senior Property Analyst', '9876543212', 'v1.0', FALSE, FALSE, NOW(), NOW()),
('naga',     'naga@provaluer.com',     '$2a$10$9VXqoCiZgs72jN/tf0xlsOSASqvnSAkqbaqApUWORvxP7WQxHQMQy', 'CLIENT', 'Naga Client', '9876543213', 'v1.0', FALSE, FALSE, NOW(), NOW())
ON CONFLICT (username) DO NOTHING;
