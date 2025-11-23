require('dotenv').config();
const redisConfig = require('./redis.config');

module.exports = {
    // Redis connection for Bull
    redis: {
        host: redisConfig.host,
        port: redisConfig.port,
        password: redisConfig.password,
        db: redisConfig.db,
    },
  
    // Queue settings
    concurrency: process.env.QUEUE_CONCURRENCY || 5,
  
    // Default job options
    defaultJobOptions: {
        attempts: process.env.QUEUE_ATTEMPTS || 3,
        backoff: {
            type: process.env.QUEUE_BACKOFF_TYPE || 'exponential',
            delay: process.env.QUEUE_BACKOFF_DELAY || 5000, // 5 seconds
        },
        removeOnComplete: 100, // Keep last 100 completed jobs
        removeOnFail: 500, // Keep last 500 failed jobs
        timeout: 60000, // 60 seconds
    },

    // Queue names
    queues: {
        email: 'email-queue',
        scheduled: 'scheduled-email-queue',
    },

    // Job types and priorities
    jobs: {
        sendEmail: {
            name: 'send-email',
            priority: 1,
        },
        sendScheduledEmail: {
            name: 'send-scheduled-email',
            priority: 2,
        },
        checkScheduledEmails: {
            name: 'check-scheduled-emails',
            priority: 3,
        },
        sendVerificationEmail: {
            name: 'send-verification-email',
            priority: 0, // Highest priority
        },
    },

    // Scheduler configuration
    scheduler: {
        enabled: process.env.CRON_ENABLED !== 'false',
        interval: process.env.EMAIL_CHECK_INTERVAL || 60000, // 1 minute
        batchSize: process.env.CRON_BATCH_SIZE || 50,
    },

    // Queue settings
    settings: {
        lockDuration: 30000, // 30 seconds
        stalledInterval: 30000,
        maxStalledCount: 1,
        guardInterval: 5000,
        retryProcessDelay: 5000,
    },
};