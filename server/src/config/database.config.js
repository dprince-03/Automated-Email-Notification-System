require('dotenv').config();

const pool = {
	host: process.env.DB_HOST || 'localhost',
	user: process.env.DB_USER || 'root',
	password: process.env.DB_PASSWORD || '',
	database: process.env.DB_NAME || 'email_notification_db',
	port: process.env.DB_PORT || 5432,
	min: process.env.DB_POOL_MIN || 2,
	max: process.env.DB_POOL_MAX || 10,
	DB_IDLE_TIMEOUT_MS: process.env.DB_IDLE_TIMEOUT_MS || 30000,
	DB_CONNECTION_TIMEOUT_MS: process.env.DB_CONNECTION_TIMEOUT_MS || 10000,
    createTimeout: 30000,
    acquireTimeout: 30000,
    destroyTimeout: 5000,
     healthCheck: true,
    maxUses: 7500, // Close connection after 7500 queries

    query: {
        statement_timeout: 10000, // 10 seconds
    },

    ssl: process.env.NODE_ENV === 'production' ? { 
        rejectUnauthorized: false
    } : false,

    propagateCreateError: false
};

module.exports = {
    pool,
};