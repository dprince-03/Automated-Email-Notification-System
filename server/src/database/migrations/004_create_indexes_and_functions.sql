-- Function to get user's email statistics
CREATE OR REPLACE FUNCTION get_user_email_stats(p_user_id INTEGER)
RETURNS TABLE (
    total_scheduled BIGINT,
    total_sent BIGINT,
    total_failed BIGINT,
    total_pending BIGINT,
    success_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_scheduled,
        COUNT(*) FILTER (WHERE status = 'sent') as total_sent,
        COUNT(*) FILTER (WHERE status = 'failed') as total_failed,
        COUNT(*) FILTER (WHERE status = 'pending') as total_pending,
        CASE 
            WHEN COUNT(*) > 0 THEN 
                ROUND((COUNT(*) FILTER (WHERE status = 'sent')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
            ELSE 0 
        END as success_rate
    FROM scheduled_emails
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old completed emails (data retention)
CREATE OR REPLACE FUNCTION cleanup_old_emails(days_old INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM scheduled_emails
    WHERE status IN ('sent', 'failed')
    AND updated_at < CURRENT_TIMESTAMP - (days_old || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get pending emails ready to send
CREATE OR REPLACE FUNCTION get_pending_emails_ready(batch_size INTEGER DEFAULT 50)
RETURNS TABLE (
    id INTEGER,
    user_id INTEGER,
    recipient_email VARCHAR,
    subject VARCHAR,
    scheduled_time TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        se.id,
        se.user_id,
        se.recipient_email,
        se.subject,
        se.scheduled_time
    FROM scheduled_emails se
    WHERE se.status = 'pending'
    AND se.scheduled_time <= CURRENT_TIMESTAMP
    ORDER BY se.priority DESC, se.scheduled_time ASC
    LIMIT batch_size;
END;
$$ LANGUAGE plpgsql;

-- Partial index for active users only (optimization)
CREATE INDEX idx_users_active_email ON users(email) 
    WHERE is_active = TRUE AND is_verified = TRUE;

-- GIN index for JSONB metadata searching
CREATE INDEX idx_scheduled_emails_metadata ON scheduled_emails USING GIN (metadata);

-- Text search index for email content (optional but useful)
CREATE INDEX idx_scheduled_emails_subject_search ON scheduled_emails 
    USING GIN (to_tsvector('english', subject));
CREATE INDEX idx_scheduled_emails_body_search ON scheduled_emails 
    USING GIN (to_tsvector('english', body));
