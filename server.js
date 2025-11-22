require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const helmet = require('helmet');
const morgan = require('morgan');
// const rateLimit = require("express-rate-limit");
const session = require("express-session");

const app = express();
const PORT = process.env.PORT || 5000;

app.set('trust proxy', 1);

// =====================
// Secret validation
// =====================

// =====================
// Middlewares
// =====================
const corsConfig = {
    origin: process.env.CORS_ORIGINS ? process.env.CORS_ORIGINS.split(',') : ['http://localhost:5000', 'http://localhost:5080'],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    credentials: true,
    optionsSuccessStatus: 200,
};

const helmetConfig = {
	contentSecurityPolicy: {
		directives: {
			defaultSrc: ["'self'"],
			styleSrc: ["'self'", "https:", "'unsafe-inline'"],
			scriptSrc: ["'self'", "https:", "'unsafe-inline'"],
			imgSrc: ["'self'", "data:", "https:"],
			connectSrc: ["'self'", "https:"],
			fontSrc: ["'self'", "https:", "data:"],
			objectSrc: ["'none'"],
			upgradeInsecureRequests: [],
		},
	},
};

const sessionConfig = {
	secret: process.env.SESSION_SECRET || "your_session_secret",
	resave: false,
	saveUninitialized: false,
	cookie: {
		secure: process.env.NODE_ENV === "development" && process.env.NODE_PROD_ENV === "production",
		httpOnly: true,
		maxAge: 24 * 60 * 60 * 1000, // 24 hours
	},
};

const morganConfig = function (tokens, req, res) {
    const prefix = ':remote-addr :remote-user [:date[web]]';
    return [
        tokens.method(req, res),
        tokens.url(req, res),
        tokens.status(req, res),
        tokens.res(req, res, 'content-length'), '-',
        tokens['response-time'](req, res), 'ms'
    ].join(' ');
}

app.use(helmet(helmetConfig));
app.use(cors(corsConfig));
app.use(express.json({ limit: '10mb'}));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(session(sessionConfig));
app.use(cookieParser());
app.use(morgan(morganConfig));

// =====================
// Request logger middleware
// =====================

// =====================
// Security header middleware
// =====================
app.use((req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
    next();
});

// =====================
// Routes
// =====================
app.get('/', (req, res) => {
    return res.status(200).json({
        success: true,
        message: 'Root endpoint is working fine bro!',
    });
});

app.get('/health', (req, res) => {
    return res.status(200).json({
        success: true,
        status: 'healthy',
        message: 'Automated Email Notification System is running smoothly!',
        timeStamp: new Date().toISOString(),
        uptime: process.uptime(),
    });
});

// =====================
// Error handling middleware
// =====================

// =====================
// Start the server
// =====================
const startServer = async () => {
    try {
        console.log('Starting server...');
    
        // Validate secrets
    
        // Initialize database connection
    
        // Start cron jobs
        
        const server = app.listen(PORT, () => {
            console.log(`Server is running on port: ${PORT}`);
            console.log(`Api url: http://localhost:${PORT}`);
    
            // Log environment info to file
    
        });
    
        const shutdown = async(signal) => {
            console.log(`Received ${signal}. Shutting down server...`);
    
            server.close(async () => {
                console.log('Server closed.');
    
                // Close database connection
                console.log('Database connection closed.');
    
                console.log('Shutdown complete. Exiting process.');
    
                // Log shutdown event to file
    
                process.exit(0);
            });
    
            setTimeout(() => {
                console.error('Forced shutdown due to timeout.');
    
                // Log forced shutdown event to file
    
                process.exit(1);
            }, 10000);
        };
    
        // Handle shutdown signals
        process.on('SIGTERM', () => shutdown('SIGTERM'));
        process.on('SIGINT', () => shutdown('SIGINT'));
    
        // Handle uncaught exceptions
        process.on('uncaughtException', (err) => {
            console.error(`Uncaught Exception: ${err}`);
    
            // Log uncaught exception to file
    
            shutdown('uncaughtException');        
        });
    
        // Handle unhandled promise rejections
        process.on('unhandledRejection', (reason, promise) => {
            console.error(`Unhandled Rejection at: ${promise},\n reason: ${reason}`);
    
            // Log unhandled rejection to file
    
            shutdown('unhandledRejection');
        });
        
    } catch (error) {
        console.error('Failed to start server');
        console.error(`Error: ${error.message}\n Stack: ${error.stack}`);
    
        // Log startup failure to file
    
        process.exit(1);
    }
};

startServer();

module.exports = app;