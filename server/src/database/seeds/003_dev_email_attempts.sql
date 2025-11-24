DO $$
DECLARE
    sent_email_id INTEGER;
    failed_email_id INTEGER;
BEGIN
    -- Get a sent email ID
    SELECT id INTO sent_email_id 
    FROM scheduled_emails 
    WHERE status = 'sent' 
    LIMIT 1;

    -- Get a failed email ID
    SELECT id INTO failed_email_id 
    FROM scheduled_emails 
    WHERE status = 'failed' 
    LIMIT 1;

    -- Successful attempt for sent email
    IF sent_email_id IS NOT NULL THEN
        INSERT INTO email_attempts (
            scheduled_email_id,
            attempt_number,
            status,
            smtp_response,
            smtp_code,
            attempted_at,
            duration_ms
        ) VALUES
        (
            sent_email_id,
            1,
            'success',
            '250 2.0.0 OK',
            '250',
            CURRENT_TIMESTAMP - INTERVAL '2 days',
            1250
        );
    END IF;

    -- Multiple failed attempts for failed email
    IF failed_email_id IS NOT NULL THEN
        INSERT INTO email_attempts (
            scheduled_email_id,
            attempt_number,
            status,
            error_message,
            smtp_response,
            smtp_code,
            attempted_at,
            duration_ms
        ) VALUES
        (
            failed_email_id,
            1,
            'failed',
            'Connection timeout',
            'Connection timeout after 30000ms',
            NULL,
            CURRENT_TIMESTAMP - INTERVAL '1 hour',
            30000
        ),
        (
            failed_email_id,
            2,
            'failed',
            'Connection refused',
            'ECONNREFUSED',
            NULL,
            CURRENT_TIMESTAMP - INTERVAL '55 minutes',
            5000
        ),
        (
            failed_email_id,
            3,
            'failed',
            'SMTP server unavailable',
            '421 Service not available',
            '421',
            CURRENT_TIMESTAMP - INTERVAL '50 minutes',
            8000
        );
    END IF;

END $$;
