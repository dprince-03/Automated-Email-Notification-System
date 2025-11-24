-- View: Active users with email count
CREATE OR REPLACE VIEW v_active_users AS
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.created_at,
    u.last_login_at,
    COUNT(se.id) as total_emails,
    COUNT(se.id) FILTER (WHERE se.status = 'pending') as pending_emails,
    COUNT(se.id) FILTER (WHERE se.status = 'sent') as sent_emails,
    COUNT(se.id) FILTER (WHERE se.status = 'failed') as failed_emails
FROM users u
LEFT JOIN scheduled_emails se ON u.id = se.user_id
WHERE u.is_active = TRUE
GROUP BY u.id, u.email, u.first_name, u.last_name, u.created_at, u.last_login_at;

-- View: Email queue summary
CREATE OR REPLACE VIEW v_email_queue_summary AS
SELECT 
    status,
    priority,
    COUNT(*) as count,
    MIN(scheduled_time) as earliest_scheduled,
    MAX(scheduled_time) as latest_scheduled
FROM scheduled_emails
WHERE status IN ('pending', 'processing')
GROUP BY status, priority
ORDER BY priority DESC;

-- View: Failed emails requiring attention
CREATE OR REPLACE VIEW v_failed_emails AS
SELECT 
    se.id,
    se.user_id,
    u.email as user_email,
    se.recipient_email,
    se.subject,
    se.current_attempts,
    se.max_attempts,
    se.error_message,
    se.failed_at,
    se.created_at
FROM scheduled_emails se
JOIN users u ON se.user_id = u.id
WHERE se.status = 'failed'
ORDER BY se.failed_at DESC;

-- View: Recent email activity
CREATE OR REPLACE VIEW v_recent_email_activity AS
SELECT 
    se.id,
    se.user_id,
    u.email as user_email,
    se.recipient_email,
    se.subject,
    se.status,
    se.scheduled_time,
    se.sent_at,
    se.created_at,
    COALESCE(se.sent_at, se.failed_at, se.updated_at) as last_activity
FROM scheduled_emails se
JOIN users u ON se.user_id = u.id
ORDER BY last_activity DESC
LIMIT 100;

-- Comments on views
COMMENT ON VIEW v_active_users IS 'Active users with their email statistics';
COMMENT ON VIEW v_email_queue_summary IS 'Summary of email queue by status and priority';
COMMENT ON VIEW v_failed_emails IS 'Failed emails that may need attention';
COMMENT ON VIEW v_recent_email_activity IS 'Most recent email activity across all users';