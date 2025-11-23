require('dotenv').config();

const pool = {
	host: process.env.REDIS_HOST || "localhost",
	port: process.env.REDIS_PORT || 6379,
	password: process.env.REDIS_PASSWORD || null,
	db: process.env.REDIS_DB || 0,
	REDIS_MAX_RETRIES: process.env.REDIS_MAX_RETRIES || 3,
	enableReadyCheck: true,
	enableOfflineQueue: true,
    connectTimeout: 10000,
    lazyConnect: true,
    retryDelayOnFailover: 100,
    retryDelayOnClusterDown: 100,
    retryDelayOnTryAgain: 100,

	retryStrategy: (times) => {
		const delay = Math.min(times * 50, 2000);
		return delay;
	},

	tls: process.env.NODE_ENV === "production" && process.env.REDIS_TLS === 'true' ? {} : undefined,

    prefixes: {
        session: 'sessions:',
        cache: 'cache:',
        queue: 'queue:',
        rateLimit: 'rate_limit:',
    },

    ttl: {
        session: 900, // 15 minutes
        cache: 3600, // 1 hour
        rateLimit: 900, // 15 minutes
        shortCache: 300, // 5 minutes
        longCache: 86400 // 24 hours
    },

    keepAlive: 30000,
    name: 'email-notification-api', // Identify in Redis monitor
};

module.exports = {
    pool,
};
