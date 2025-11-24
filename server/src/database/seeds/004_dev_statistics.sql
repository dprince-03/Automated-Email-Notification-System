-- Update some timestamps for realistic data
UPDATE scheduled_emails 
SET created_at = CURRENT_TIMESTAMP - INTERVAL '7 days'
WHERE status = 'sent';

UPDATE scheduled_emails 
SET created_at = CURRENT_TIMESTAMP - INTERVAL '1 day'
WHERE status IN ('pending', 'failed');

-- Add some variation to scheduled times
UPDATE scheduled_emails 
SET scheduled_time = scheduled_time + (RANDOM() * INTERVAL '2 hours')
WHERE status = 'pending' AND scheduled_time > CURRENT_TIMESTAMP;

-- Print summary
DO $$
DECLARE
    total_users INTEGER;
    total_emails INTEGER;
    pending_count INTEGER;
    sent_count INTEGER;
    failed_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_users FROM users;
    SELECT COUNT(*) INTO total_emails FROM scheduled_emails;
    SELECT COUNT(*) INTO pending_count FROM scheduled_emails WHERE status = 'pending';
    SELECT COUNT(*) INTO sent_count FROM scheduled_emails WHERE status = 'sent';
    SELECT COUNT(*) INTO failed_count FROM scheduled_emails WHERE status = 'failed';

    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Database Seeding Summary';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Total Users: %', total_users;
    RAISE NOTICE 'Total Emails: %', total_emails;
    RAISE NOTICE '  - Pending: %', pending_count;
    RAISE NOTICE '  - Sent: %', sent_count;
    RAISE NOTICE '  - Failed: %', failed_count;
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Test Login Credentials:';
    RAISE NOTICE 'Email: admin@test.com';
    RAISE NOTICE 'Password: Password123!';
    RAISE NOTICE '===========================================';
END $$;