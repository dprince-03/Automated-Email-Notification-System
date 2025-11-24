const fs = require("node:fs").promises;
const path = require("node:path");
const { pool, query } = require("./connection");

const MIGRATIONS_DIR = path.join(__dirname, "migrations");
const MIGRATIONS_TABLE = "schema_migrations";

// Create migrations tracking table
const createMigrationsTable = async () => {
	const sql = `
    CREATE TABLE IF NOT EXISTS ${MIGRATIONS_TABLE} (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) UNIQUE NOT NULL,
      executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;
	await query(sql);
};

// Get executed migrations
const getExecutedMigrations = async () => {
	try {
		const result = await query(
			`SELECT name FROM ${MIGRATIONS_TABLE} ORDER BY name ASC`
		);
		return result.rows.map((row) => row.name);
	} catch (error) {
		return [];
	}
};

// Get pending migrations
const getPendingMigrations = async () => {
	const executed = await getExecutedMigrations();
	const files = await fs.readdir(MIGRATIONS_DIR);

	const migrations = files.filter((file) => file.endsWith(".sql")).sort();

	return migrations.filter((migration) => !executed.includes(migration));
};

// Run single migration
const runMigration = async (filename) => {
	const filepath = path.join(MIGRATIONS_DIR, filename);
	const sql = await fs.readFile(filepath, "utf-8");

	console.log(`Running migration: ${filename}`);

	await query(sql);
	await query(`INSERT INTO ${MIGRATIONS_TABLE} (name) VALUES ($1)`, [filename]);

	console.log(`Migration completed: ${filename}`);
};

// Run all pending migrations
const runMigrations = async () => {
	console.log("Starting database migrations...\n");

	try {
		await createMigrationsTable();
		const pending = await getPendingMigrations();

		if (pending.length === 0) {
			console.log("No pending migrations");
			return;
		}

		console.log(`Found ${pending.length} pending migration(s)\n`);

		for (const migration of pending) {
			await runMigration(migration);
		}

		console.log(`\nAll migrations completed successfully!`);
	} catch (error) {
		console.error("\nMigration failed:", error.message);
		throw error;
	}
};

// Rollback last migration (optional)
const rollbackLastMigration = async () => {
	const result = await query(
		`SELECT name FROM ${MIGRATIONS_TABLE} ORDER BY id DESC LIMIT 1`
	);

	if (result.rows.length === 0) {
		console.log("No migrations to rollback");
		return;
	}

	const lastMigration = result.rows[0].name;
	console.log(`Rolling back: ${lastMigration}`);

	// You would need to create rollback files for this to work
	await query(`DELETE FROM ${MIGRATIONS_TABLE} WHERE name = $1`, [
		lastMigration,
	]);

	console.log(`Rollback completed: ${lastMigration}`);
};

module.exports = {
	runMigrations,
	rollbackLastMigration,
};

// Run migrations if called directly
if (require.main === module) {
	runMigrations()
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error);
			process.exit(1);
		});
}
