const { Client } = require('pg');

async function test() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
      console.error("DATABASE_URL is missing!");
      process.exit(1);
  }

  console.log("Using DATABASE_URL:", connectionString.replace(/:[^:@]+@/, ':***@'));

  // We need to permit self-signed certs because of Supavisor
  const config = {
      connectionString,
      ssl: { rejectUnauthorized: false }
  };

  const client = new Client(config);

  try {
    await client.connect();
    console.log("✅ Connection successful!");

    const res = await client.query('SELECT version()');
    console.log("Version:", res.rows[0].version);

    await client.end();
  } catch (err) {
    console.error("❌ Connection failed:", err.message);
    if (err.message.includes("Tenant or user")) {
        console.error("DEBUG: The username parsed from URL might be wrong or project refused connection.");
    }
  }
}

test();
