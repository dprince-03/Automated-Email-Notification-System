require('dotenv').config();
const { pool } = require('pg');
const dbConfig = require('../config/database.config');

const connectionPool = new pool(dbConfig.pool);

connectionPool.on('error', (err) => {
    console.error('Unexpected error on idle client', err);
    // Log the error to file and db

    if (process.env.NODE_ENV !== 'production') {
        process.exit(-1);
    }
});

connectionPool.on('connect', (client) => {
    if (process.env.NODE_ENV === 'development') {
        console.log('Database client connected');
        // Log to file and db
    }
});

connectionPool.on('remove', (client) => {
    if (process.env.NODE_ENV === 'development') {
        console.log('Database client removed');
        // Log to file and db
    }
});

const testConnection = async () => {
    try {
        const client = await connectionPool.connect();
        const result = await client.query('SELECT NOW()');
        client.release();
        console.log('Database connection test successful', result.rows[0].now);
        return true;
    } catch (error) {
        console.error('Database connection test failed', error.message);
        return false;
    }
};

const closePool = async () => {
    try {
        await connectionPool.end();
        console.log('Database connection pool closed');
    } catch (error) {
        console.error('Error closing database connection pool', error.message);
        throw error;
    }
};

const query = async (text, params) => {
    const start = Date.now();
    try {
        const result = await connectionPool.query(text, params);
        const duration = Date.now() - start;
        
        if (process.env.NODE_ENV === 'development') {
            console.log('Executed query', { text, duration: `${duration}ms`, rows: result.rowCount });
        }

        return result;
    } catch (error) {
        console.error('Error executing query', { text, error: error.message });
        throw error;
    }
};

const transaction = async (callback) => {
    const client = await connectionPool.connect();

    try {
        await client.query('BEGIN');
        const result = await callback(client);
        await client.query('COMMIT');
        return result;
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Transaction failed, rolled back', error.message);
        throw error;
    } finally {
        client.release();
    }
};

module.exports = {
    pool: connectionPool,
    query,
    transaction,
    testConnection,
    closePool,
};