-- Create email_attempts table
CREATE TABLE IF NOT EXISTS email_attempts (
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

-- Indexes
CREATE INDEX idx_email_attempts_scheduled_email_id ON email_attempts(scheduled_email_id);
CREATE INDEX idx_email_attempts_status ON email_attempts(status);
CREATE INDEX idx_email_attempts_attempted_at ON email_attempts(attempted_at);

-- Composite index for audit queries
CREATE INDEX idx_email_attempts_email_attempt ON email_attempts(scheduled_email_id, attempt_number);

-- Comments
COMMENT ON TABLE email_attempts IS 'Audit trail of email sending attempts';
COMMENT ON COLUMN email_attempts.attempt_number IS 'Which attempt this was (1, 2, 3, etc.)';
COMMENT ON COLUMN email_attempts.smtp_response IS 'Response from SMTP server';
