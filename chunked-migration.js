const { Pool } = require('pg');
const fs = require('fs');

const pool = new Pool({
  connectionString: 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres',
  ssl: { rejectUnauthorized: false },
  max: 1,  // Use single connection to avoid pooler issues
  connectionTimeoutMillis: 30000,
  query_timeout: 60000,
});

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function executeWithRetry(client, sql, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await client.query(sql);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      console.log(`   ⚠️  Retry ${i + 1}/${maxRetries}: ${error.message.substring(0, 50)}`);
      await sleep(2000);
    }
  }
}

async function runMigration() {
  console.log('🔌 Connecting to Supabase (chunked migration mode)...\n');

  let client;
  try {
    client = await pool.connect();
    console.log('✅ Connected!\n');

    // Clean schema
    console.log('🗑️  Cleaning schema...');
    await executeWithRetry(client, 'DROP SCHEMA IF EXISTS project_management_tool CASCADE');
    await executeWithRetry(client, 'CREATE SCHEMA project_management_tool');
    await executeWithRetry(client, 'SET search_path = project_management_tool, public');
    console.log('   ✓ Schema ready\n');

    // Read and parse the INSERT version
    console.log('📖 Reading migration-inserts.sql...');
    const sql = fs.readFileSync('migration-inserts.sql', 'utf8');

    // Simple line-by-line parser
    console.log('📝 Parsing SQL...');
    const statements = [];
    let current = '';
    let lineCount = 0;

    for (const line of sql.split('\n')) {
      lineCount++;
      current += line + '\n';

      if (line.trim().endsWith(';')) {
        const stmt = current.trim();
        if (stmt && !stmt.startsWith('--') && stmt.length > 10) {
          statements.push(stmt);
        }
        current = '';
      }

      // Show progress
      if (lineCount % 1000 === 0) {
        process.stdout.write('.');
      }
    }

    console.log(`\n   ✓ Found ${statements.length} statements\n`);

    // Execute in small batches with delays
    console.log('🚀 Executing migration in chunks...\n');

    let executed = 0;
    let errors = 0;
    const batchSize = 50;  // Small batches

    for (let i = 0; i < statements.length; i++) {
      const stmt = statements[i];

      try {
        await client.query(stmt);
        executed++;

        // Show progress for key operations
        if (stmt.includes('CREATE TABLE')) {
          const match = stmt.match(/CREATE TABLE (\w+)/);
          if (match) console.log(`   ✓ Table: ${match[1]}`);
        } else if (stmt.includes('CREATE FUNCTION')) {
          console.log(`   ✓ Function created`);
        } else if (stmt.includes('CREATE SEQUENCE')) {
          console.log(`   ✓ Sequence created`);
        }

        // Batch progress
        if (executed % batchSize === 0) {
          console.log(`   Progress: ${executed}/${statements.length} statements...`);
          await sleep(100);  // Small delay between batches
        }

      } catch (error) {
        errors++;

        // Stop on critical errors
        if (stmt.includes('CREATE TABLE') || stmt.includes('CREATE SEQUENCE')) {
          console.error(`\n❌ CRITICAL: ${error.message.substring(0, 100)}`);
          console.error(`   Statement: ${stmt.substring(0, 100)}...\n`);
          // Continue anyway to see all errors
        }

        // Too many errors, something is wrong
        if (errors > 100 && executed < 50) {
          throw new Error('Too many errors in early statements');
        }
      }
    }

    console.log(`\n   ✓ Executed: ${executed}, Errors: ${errors}\n`);

    // Verify
    console.log('🔍 Verifying...\n');
    const tableCount = await client.query(`
      SELECT COUNT(*) as count FROM information_schema.tables
      WHERE table_schema = 'project_management_tool'
    `);
    console.log(`   Tables: ${tableCount.rows[0].count}`);

    if (tableCount.rows[0].count > 0) {
      const tables = await client.query(`
        SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'project_management_tool'
        ORDER BY table_name
      `);

      for (const row of tables.rows) {
        try {
          const count = await client.query(`SELECT COUNT(*) FROM project_management_tool.${row.table_name}`);
          console.log(`   ✓ ${row.table_name}: ${count.rows[0].count}`);
        } catch (e) {
          console.log(`   ⚠️  ${row.table_name}: ${e.message.substring(0, 50)}`);
        }
      }
    }

    console.log('\n🎉 Migration complete!\n');

  } catch (error) {
    console.error('\n❌ Fatal error:', error.message);
    console.error(error.stack);
  } finally {
    if (client) client.release();
    await pool.end();
  }
}

runMigration();
