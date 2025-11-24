-- Get user IDs (for foreign key references)
DO $$
DECLARE
    admin_id INTEGER;
    john_id INTEGER;
    jane_id INTEGER;
BEGIN
    SELECT id INTO admin_id FROM users WHERE email = 'admin@test.com';
    SELECT id INTO john_id FROM users WHERE email = 'john.doe@test.com';
    SELECT id INTO jane_id FROM users WHERE email = 'jane.smith@test.com';

    -- Pending emails (ready to send)
    INSERT INTO scheduled_emails (
        user_id,
        recipient_email,
        subject,
        body,
        html_body,
        scheduled_time,
        status,
        priority
    ) VALUES
    (
        admin_id,
        'recipient1@example.com',
        'Welcome to Our Service',
        'Hello! Welcome to our email notification service. We are glad to have you.',
        '<h1>Welcome!</h1><p>Hello! Welcome to our email notification service.</p>',
        CURRENT_TIMESTAMP - INTERVAL '5 minutes',
        'pending',
        'normal'
    ),
    (
        john_id,
        'recipient2@example.com',
        'Meeting Reminder',
        'This is a reminder about tomorrow meeting at 10 AM.',
        '<h2>Meeting Reminder</h2><p>This is a reminder about tomorrow meeting at 10 AM.</p>',
        CURRENT_TIMESTAMP - INTERVAL '2 minutes',
        'pending',
        'high'
    ),
    (
        jane_id,
        'recipient3@example.com',
        'Weekly Newsletter',
        'Here is your weekly newsletter with the latest updates.',
        '<h2>Weekly Newsletter</h2><p>Latest updates and news...</p>',
        CURRENT_TIMESTAMP - INTERVAL '1 minute',
        'pending',
        'low'
    );

    -- Future scheduled emails
    INSERT INTO scheduled_emails (
        user_id,
        recipient_email,
        subject,
        body,
        scheduled_time,
        status,
        priority
    ) VALUES
    (
        admin_id,
        'future1@example.com',
        'Upcoming Event Notification',
        'Reminder about the upcoming event next week.',
        CURRENT_TIMESTAMP + INTERVAL '2 days',
        'pending',
        'normal'
    ),
    (
        john_id,
        'future2@example.com',
        'Monthly Report',
        'Your monthly report will be ready soon.',
        CURRENT_TIMESTAMP + INTERVAL '7 days',
        'pending',
        'normal'
    );

    -- Sent emails (historical)
    INSERT INTO scheduled_emails (
        user_id,
        recipient_email,
        subject,
        body,
        scheduled_time,
        status,
        sent_at,
        current_attempts
    ) VALUES
    (
        admin_id,
        'sent1@example.com',
        'Password Reset Request',
        'Your password has been successfully reset.',
        CURRENT_TIMESTAMP - INTERVAL '2 days',
        'sent',
        CURRENT_TIMESTAMP - INTERVAL '2 days',
        1
    ),
    (
        john_id,
        'sent2@example.com',
        'Order Confirmation',
        'Thank you for your order. Order ID: #12345',
        CURRENT_TIMESTAMP - INTERVAL '1 day',
        'sent',
        CURRENT_TIMESTAMP - INTERVAL '1 day',
        1
    ),
    (
        jane_id,
        'sent3@example.com',
        'Account Verification',
        'Please verify your email address.',
        CURRENT_TIMESTAMP - INTERVAL '3 days',
        'sent',
        CURRENT_TIMESTAMP - INTERVAL '3 days',
        1
    );

    -- Failed emails
    INSERT INTO scheduled_emails (
        user_id,
        recipient_email,
        subject,
        body,
        scheduled_time,
        status,
        failed_at,
        current_attempts,
        max_attempts,
        error_message
    ) VALUES
    (
        admin_id,
        'invalid@invalid@test.com',
        'Test Failed Email',
        'This email will fail due to invalid recipient.',
        CURRENT_TIMESTAMP - INTERVAL '1 hour',
        'failed',
        CURRENT_TIMESTAMP - INTERVAL '1 hour',
        3,
        3,
        'Invalid recipient email address'
    ),
    (
        john_id,
        'failed@test.com',
        'SMTP Connection Failed',
        'This email failed due to SMTP connection issue.',
        CURRENT_TIMESTAMP - INTERVAL '30 minutes',
        'failed',
        CURRENT_TIMESTAMP - INTERVAL '30 minutes',
        3,
        3,
        'SMTP connection timeout'
    );

    -- Email with CC and BCC
    INSERT INTO scheduled_emails (
        user_id,
        recipient_email,
        cc_emails,
        bcc_emails,
        subject,
        body,
        scheduled_time,
        status,
        priority
    ) VALUES
    (
        admin_id,
        'primary@example.com',
        ARRAY['cc1@example.com', 'cc2@example.com'],
        ARRAY['bcc1@example.com'],
        'Team Update',
        'Important team update for everyone.',
        CURRENT_TIMESTAMP + INTERVAL '1 hour',
        'pending',
        'urgent'
    );

    -- Email with metadata
    INSERT INTO scheduled_emails (
        user_id,
        recipient_email,
        subject,
        body,
        scheduled_time,
        status,
        metadata
    ) VALUES
    (
        jane_id,
        'metadata@example.com',
        'Email with Custom Data',
        'This email has custom metadata.',
        CURRENT_TIMESTAMP + INTERVAL '3 hours',
        'pending',
        '{"campaign": "spring_sale", "category": "marketing", "tracking_id": "ABC123"}'::jsonb
    );

END $$;

