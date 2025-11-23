require('dotenv').config();

const jwt_config = {
	secret: process.env.JWT_SECRET || (() => {
        throw new Error('JWT_SECRET must be defined in production');
        
    })(),
	expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
    algorithm: 'HS256',
    issuer: 'email-notification-system',
    audience: 'email-notification-users',
};

const session_config = {
	secret: process.env.SESSION_SECRET,
	maxAge: 24 * 60 * 60 * 1000 || process.env.SESSION_MAX_AGE, // 24 hours
	name: process.env.SESSION_NAME || "email_notification_session",
	secure: process.env.NODE_ENV === "production",
	httpOnly: true,
	sameSite: process.env.NODE_ENV === "production" ? "Strict" : "Lax",
};

const password = {
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS) || 12,
    minLength: 8,
    maxLength: 64,
    requireUppercase: true,
    requireLowercase: true,
    requireNumbers: true,
    requireSpecialChars: true,
};

const verification = {
	tokenLength: process.env.VERIFICATION_TOKEN_LENGTH || 32,
    expiryHours: 24, // 24 hours
};

const password_reset = {
    tokenLength: 32,
    expiryHours: 1, // 1 hour
};

const cookies_config = {
    name: 'refreshToken',
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: process.env.NODE_ENV === 'production' ? 'Strict' : 'Lax',
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    path: '/',
};

module.exports = {
    jwt: jwt_config,
    session: session_config,
    password,
    verification,
    password_reset,
    cookies: cookies_config,
};