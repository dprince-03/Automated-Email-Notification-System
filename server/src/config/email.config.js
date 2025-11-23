require('dotenv').config();

module.exports = {
    // SMTP Configuration
  smtp: {
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT || 587,
    secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASSWORD
    },
    // Connection pool
    pool: true,
    maxConnections: 5,
    maxMessages: 100,
    rateDelta: 1000,
    rateLimit: 10
  },
  
  // Email defaults
  from: {
    name: process.env.EMAIL_FROM_NAME || 'Email Notification System',
    address: process.env.EMAIL_FROM_ADDRESS || 'noreply@yourdomain.com'
  },
  
  replyTo: process.env.EMAIL_REPLY_TO || 'support@yourdomain.com',
  
  // Retry configuration
  retry: {
    attempts: process.env.EMAIL_RETRY_ATTEMPTS || 3,
    delay: process.env.EMAIL_RETRY_DELAY || 300000, // 5 minutes
    maxRetries: process.env.EMAIL_MAX_RETRIES || 3
  },
  
  // Email validation
  validation: {
    maxRecipients: 10,
    maxCCRecipients: 10,
    maxBCCRecipients: 10,
    maxSubjectLength: 500,
    maxBodyLength: 50000 // ~50KB
  },
  
  // Templates path (if using templates)
  templatesPath: './src/templates/emails',
  
  // Preview mode (development)
  preview: process.env.NODE_ENV === 'development'
};