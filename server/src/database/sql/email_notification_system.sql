DROP TABLE IF EXISTS email_attempts CASCADE;
DROP TABLE IF EXISTS scheduled_emails CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TYPE IF EXISTS email_status CASCADE;
DROP TYPE IF EXISTS email_priority CASCADE;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE email_status AS ENUM (
    'pending',
    'processing',
    'sent',
    'failed',
    'cancelled'
);

CREATE TYPE email_priority AS ENUM (
    'low',
    'normal',
    'high',
    'urgent'
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    
    -- Email verification
    is_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(255),
    verification_token_expires TIMESTAMP,
    
    -- Password reset
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP,
    
    -- Refresh tokens
    refresh_token_hash VARCHAR(255),
    
    -- Account status
    is_active BOOLEAN DEFAULT TRUE,
    is_locked BOOLEAN DEFAULT FALSE,
    failed_login_attempts INTEGER DEFAULT 0,
    last_failed_login TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    
    -- Constraints
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT password_not_empty CHECK (password_hash != '')
);

CREATE TABLE scheduled_emails (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Email details
    recipient_email VARCHAR(255) NOT NULL,
    cc_emails TEXT[],
    bcc_emails TEXT[],
    
    subject VARCHAR(500) NOT NULL,
    body TEXT NOT NULL,
    html_body TEXT,
    
    -- Scheduling
    scheduled_time TIMESTAMP NOT NULL,
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Status tracking
    status email_status DEFAULT 'pending',
    priority email_priority DEFAULT 'normal',
    
    -- Retry logic
    max_attempts INTEGER DEFAULT 3,
    current_attempts INTEGER DEFAULT 0,
    
    -- Completion tracking
    sent_at TIMESTAMP,
    failed_at TIMESTAMP,
    error_message TEXT,
    
    -- Additional data
    metadata JSONB DEFAULT '{}',
    attachments JSONB DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT recipient_email_format CHECK (
        recipient_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    ),
    CONSTRAINT subject_not_empty CHECK (subject != ''),
    CONSTRAINT body_not_empty CHECK (body != ''),
    CONSTRAINT scheduled_time_valid CHECK (scheduled_time > created_at),
    CONSTRAINT attempts_valid CHECK (current_attempts <= max_attempts)
);

CREATE TABLE email_attempts (
    id SERIAL PRIMARY KEY,
    scheduled_email_id INTEGER NOT NULL REFERENCES scheduled_emails(id) ON DELETE CASCADE,
    
    -- Attempt details
    attempt_number INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL,
    
    -- Response details
    error_message TEXT,
    smtp_response TEXT,
    smtp_code VARCHAR(10),
    
    -- Metadata
    ip_address INET,
    user_agent TEXT,
    
    -- Timing
    attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    duration_ms INTEGER,
    
    -- Additional info
    metadata JSONB DEFAULT '{}',
    
    -- Constraints
    CONSTRAINT attempt_number_positive CHECK (attempt_number > 0),
    CONSTRAINT status_not_empty CHECK (status != '')
);

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_verification_token ON users(verification_token);
CREATE INDEX idx_users_password_reset_token ON users(password_reset_token);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_active_email ON users(email) 
    WHERE is_active = TRUE AND is_verified = TRUE;

-- Scheduled emails indexes
CREATE INDEX idx_scheduled_emails_user_id ON scheduled_emails(user_id);
CREATE INDEX idx_scheduled_emails_status ON scheduled_emails(status);
CREATE INDEX idx_scheduled_emails_scheduled_time ON scheduled_emails(scheduled_time);
CREATE INDEX idx_scheduled_emails_priority ON scheduled_emails(priority);
CREATE INDEX idx_scheduled_emails_created_at ON scheduled_emails(created_at);

-- Composite indexes
CREATE INDEX idx_scheduled_emails_status_time ON scheduled_emails(status, scheduled_time);
CREATE INDEX idx_scheduled_emails_user_status ON scheduled_emails(user_id, status);
CREATE INDEX idx_scheduled_emails_pending_ready ON scheduled_emails(status, scheduled_time) 
    WHERE status = 'pending';

-- JSONB indexes
CREATE INDEX idx_scheduled_emails_metadata ON scheduled_emails USING GIN (metadata);

-- Full text search indexes (optional)
CREATE INDEX idx_scheduled_emails_subject_search ON scheduled_emails 
    USING GIN (to_tsvector('english', subject));
CREATE INDEX idx_scheduled_emails_body_search ON scheduled_emails 
    USING GIN (to_tsvector('english', body));

-- Email attempts indexes
CREATE INDEX idx_email_attempts_scheduled_email_id ON email_attempts(scheduled_email_id);
CREATE INDEX idx_email_attempts_status ON email_attempts(status);
CREATE INDEX idx_email_attempts_attempted_at ON email_attempts(attempted_at);
CREATE INDEX idx_email_attempts_email_attempt ON email_attempts(scheduled_email_id, attempt_number);


-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scheduled_emails_updated_at
    BEFORE UPDATE ON scheduled_emails
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to get user email statistics
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

-- Function to clean up old emails
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


-- Active users with email count
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

-- Email queue summary
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

-- Failed emails
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

-- Recent email activity
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



COMMENT ON TABLE users IS 'User accounts with authentication';
COMMENT ON TABLE scheduled_emails IS 'Emails scheduled for future delivery';
COMMENT ON TABLE email_attempts IS 'Audit trail of email sending attempts';

COMMENT ON COLUMN users.is_verified IS 'Whether user has verified their email';
COMMENT ON COLUMN users.is_locked IS 'Account locked due to security reasons';
COMMENT ON COLUMN scheduled_emails.metadata IS 'Additional metadata in JSON format';
COMMENT ON COLUMN scheduled_emails.priority IS 'Email priority (low, normal, high, urgent)';


DO $$
BEGIN
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Database schema created successfully!';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Tables created:';
    RAISE NOTICE '  - users';
    RAISE NOTICE '  - scheduled_emails';
    RAISE NOTICE '  - email_attempts';
    RAISE NOTICE '';
    RAISE NOTICE 'Views created:';
    RAISE NOTICE '  - v_active_users';
    RAISE NOTICE '  - v_email_queue_summary';
    RAISE NOTICE '  - v_failed_emails';
    RAISE NOTICE '  - v_recent_email_activity';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions created:';
    RAISE NOTICE '  - get_user_email_stats()';
    RAISE NOTICE '  - cleanup_old_emails()';
    RAISE NOTICE '  - get_pending_emails_ready()';
    RAISE NOTICE '===========================================';
END $$;