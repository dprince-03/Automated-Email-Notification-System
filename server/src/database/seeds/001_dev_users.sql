INSERT INTO users (
    email, 
    password_hash, 
    first_name, 
    last_name, 
    is_verified, 
    is_active
) VALUES
(
    'admin@test.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7qKQ/NQfHK',
    'Admin',
    'User',
    TRUE,
    TRUE
),
(
    'john.doe@test.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7qKQ/NQfHK',
    'John',
    'Doe',
    TRUE,
    TRUE
),
(
    'jane.smith@test.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7qKQ/NQfHK',
    'Jane',
    'Smith',
    TRUE,
    TRUE
),
(
    'test.user@test.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7qKQ/NQfHK',
    'Test',
    'User',
    TRUE,
    TRUE
),
(
    'unverified@test.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7qKQ/NQfHK',
    'Unverified',
    'User',
    FALSE,
    TRUE
)
ON CONFLICT (email) DO NOTHING;

-- Update last login for some users
UPDATE users 
SET last_login_at = CURRENT_TIMESTAMP - INTERVAL '2 hours'
WHERE email IN ('admin@test.com', 'john.doe@test.com');

-- Add verification token for unverified user
UPDATE users 
SET 
    verification_token = 'test_verification_token_123456789',
    verification_token_expires = CURRENT_TIMESTAMP + INTERVAL '24 hours'
WHERE email = 'unverified@test.com';

