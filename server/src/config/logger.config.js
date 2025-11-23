require("dotenv").config();
const path = require("node:path");

module.exports = {
	level: process.env.LOG_LEVEL || "info",

	// Log file settings
	file: {
		path: process.env.LOG_FILE_PATH || "./logs",
		datePattern: process.env.LOG_DATE_PATTERN || "YYYY-MM-DD",
		maxFiles: process.env.LOG_MAX_FILES || "14d",
		maxSize: process.env.LOG_MAX_SIZE || "20m",
		zippedArchive: true,
	},

	// Log format
	format: {
		timestamp: true,
		json: true,
		colorize: process.env.NODE_ENV !== "production",
	},

	// Console logging
	console: {
		enabled: process.env.NODE_ENV !== "production",
		colorize: true,
		prettyPrint: true,
	},

	// Error logging
	errors: {
		file: "error.log",
		level: "error",
	},

	// Combined logging
	combined: {
		file: "combined.log",
		level: "info",
	},

	// Exception handling
	exceptions: {
		file: "exceptions.log",
		handleExceptions: true,
		handleRejections: true,
	},

	// Log metadata
	defaultMeta: {
		service: "email-notification-api",
		environment: process.env.NODE_ENV || "development",
		version: process.env.npm_package_version || "1.0.0",
	},
};