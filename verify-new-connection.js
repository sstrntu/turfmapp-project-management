const { Client } = require('pg');

const config = {
  user: 'postgres.pwxhgvuyaxgavommtqpr',
  password: 'Tzt0bkistz7Hi2af',
  host: 'aws-1-ap-southeast-1.pooler.supabase.com',
  port: 5432,
  database: 'postgres',
  ssl: { rejectUnauthorized: false },
};

async function testConnection() {
  console.log(`Connecting to ${config.host}:${config.port}...`);
  const client = new Client(config);

  try {
    await client.connect();
    console.log('✅ Connection successful!');

    // Check if schema exists
    const schemaName = 'product-management-tool';
    console.log(`Checking for schema: "${schemaName}"...`);
    const res = await client.query(`SELECT schema_name FROM information_schema.schemata WHERE schema_name = $1`, [schemaName]);

    if (res.rows.length > 0) {
      console.log(`✅ Schema "${schemaName}" found.`);

      // Test creating a table in that schema to verify permissions/quoting
      try {
        await client.query(`CREATE TABLE IF NOT EXISTS "${schemaName}"._connection_test (id serial primary key)`);
        console.log(`✅ Successfully created test table in "${schemaName}".`);
        await client.query(`DROP TABLE "${schemaName}"._connection_test`);
        console.log(`✅ Successfully cleaned up test table.`);
      } catch (err) {
        console.log(`⚠️  Schema exists but could not create table: ${err.message}`);
      }

    } else {
      console.log(`❌ Schema "${schemaName}" NOT found.`);
      console.log('Existing schemas:', (await client.query('SELECT schema_name FROM information_schema.schemata')).rows.map(r => r.schema_name));
    }

  } catch (err) {
    console.error('❌ Connection failed:', err.message);
  } finally {
    await client.end();
  }
}

testConnection();
