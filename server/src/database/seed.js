const fs = require("node:fs").promises;
const path = require("node:path");
const { query, transaction } = require("./connection");

const SEEDS_DIR = path.join(__dirname, "seeds");

// Run single seed file
const runSeed = async (filename) => {
	const filepath = path.join(SEEDS_DIR, filename);
	const sql = await fs.readFile(filepath, "utf-8");

	console.log(`Running seed: ${filename}`);

	await query(sql);

	console.log(`Seed completed: ${filename}`);
};

// Run all seeds
const runSeeds = async () => {
	console.log("Starting database seeding...\n");

	try {
		const files = await fs.readdir(SEEDS_DIR);
		const seeds = files.filter((file) => file.endsWith(".sql")).sort();

		if (seeds.length === 0) {
			console.log("No seed files found");
			return;
		}

		console.log(`Found ${seeds.length} seed file(s)\n`);

		for (const seed of seeds) {
			await runSeed(seed);
		}

		console.log(`\nAll seeds completed successfully!`);
	} catch (error) {
		console.error("\nSeeding failed:", error.message);
		throw error;
	}
};

// Clear all data (be careful!)
const clearAllData = async () => {
	console.log("Clearing all data...");

	const tables = ["email_attempts", "scheduled_emails", "users"];

	for (const table of tables) {
		await query(`TRUNCATE TABLE ${table} RESTART IDENTITY CASCADE`);
		console.log(`Cleared: ${table}`);
	}

	console.log("All data cleared");
};

module.exports = {
	runSeeds,
	clearAllData,
};

// Run seeds if called directly
if (require.main === module) {
	runSeeds()
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error);
			process.exit(1);
		});
}
