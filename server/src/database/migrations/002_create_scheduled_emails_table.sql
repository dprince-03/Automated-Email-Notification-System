-- Create enum for email status
CREATE TYPE email_status AS ENUM (
    'pending',
    'processing',
    'sent',
    'failed',
    'cancelled'
);

-- Create enum for email priority
CREATE TYPE email_priority AS ENUM (
    'low',
    'normal',
    'high',
    'urgent'
);

-- Create scheduled_emails table
CREATE TABLE IF NOT EXISTS scheduled_emails (
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
    
    -- Attachments info (store references, not actual files)
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

-- Indexes for performance
CREATE INDEX idx_scheduled_emails_user_id ON scheduled_emails(user_id);
CREATE INDEX idx_scheduled_emails_status ON scheduled_emails(status);
CREATE INDEX idx_scheduled_emails_scheduled_time ON scheduled_emails(scheduled_time);
CREATE INDEX idx_scheduled_emails_priority ON scheduled_emails(priority);
CREATE INDEX idx_scheduled_emails_created_at ON scheduled_emails(created_at);

-- Composite indexes for common queries
CREATE INDEX idx_scheduled_emails_status_time ON scheduled_emails(status, scheduled_time);
CREATE INDEX idx_scheduled_emails_user_status ON scheduled_emails(user_id, status);
CREATE INDEX idx_scheduled_emails_pending_ready ON scheduled_emails(status, scheduled_time) 
    WHERE status = 'pending';

-- Trigger for updated_at
CREATE TRIGGER update_scheduled_emails_updated_at
    BEFORE UPDATE ON scheduled_emails
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE scheduled_emails IS 'Emails scheduled for future delivery';
COMMENT ON COLUMN scheduled_emails.status IS 'Current status of the email';
COMMENT ON COLUMN scheduled_emails.priority IS 'Email priority level';
COMMENT ON COLUMN scheduled_emails.metadata IS 'Additional metadata in JSON format';
COMMENT ON COLUMN scheduled_emails.attachments IS 'Attachment information in JSON format';

