const { Client } = require('pg');
const { spawn } = require('child_process');
const fs = require('fs');

const connectionString = 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres';
const sqlFile = '/Users/sirasasitorn/Documents/VScode/turfmapp/supabase-restore.sql';

async function runMigration() {
  console.log('🔌 Connecting to Supabase...');
  console.log('   Host: aws-1-ap-southeast-1.pooler.supabase.com');
  console.log('   Schema: project_management_tool\n');

  // First, connect to verify access and clean schema
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 60000,
  });

  try {
    await client.connect();
    console.log('✅ Connected to Supabase!\n');

    console.log('🗑️  Cleaning existing schema...');
    await client.query('DROP SCHEMA IF EXISTS project_management_tool CASCADE;');
    console.log('   ✓ Dropped existing schema');

    await client.query('CREATE SCHEMA project_management_tool;');
    console.log('   ✓ Created fresh schema\n');

    await client.end();
    console.log('📪 Disconnected (will reconnect via psql)\n');

  } catch (error) {
    console.error('❌ Failed to prepare schema:', error.message);
    process.exit(1);
  }

  // Now use psql to run the SQL file (handles COPY commands correctly)
  console.log('🚀 Executing migration via psql...');
  console.log('   (This may take a few minutes)\n');

  return new Promise((resolve, reject) => {
    const psql = spawn('psql', [connectionString, '-f', sqlFile], {
      stdio: ['inherit', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';

    psql.stdout.on('data', (data) => {
      const output = data.toString();
      stdout += output;
      // Show progress for important messages
      if (output.includes('CREATE') || output.includes('INSERT') || output.includes('COPY')) {
        process.stdout.write('.');
      }
    });

    psql.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    psql.on('close', async (code) => {
      console.log('\n');

      if (code !== 0) {
        console.error('❌ Migration failed!');
        console.error('Error output:', stderr.substring(0, 500));
        reject(new Error(`psql exited with code ${code}`));
        return;
      }

      console.log('✅ Migration executed successfully!\n');

      // Verify the migration
      console.log('🔍 Verifying migration...');
      const verifyClient = new Client({
        connectionString,
        ssl: { rejectUnauthorized: false },
      });

      try {
        await verifyClient.connect();

        const tableCount = await verifyClient.query(`
          SELECT COUNT(*) as count
          FROM information_schema.tables
          WHERE table_schema = 'project_management_tool';
        `);
        console.log(`   ✓ Tables created: ${tableCount.rows[0].count}`);

        const userCount = await verifyClient.query(`
          SELECT COUNT(*) as count FROM project_management_tool.user_account;
        `);
        console.log(`   ✓ Users migrated: ${userCount.rows[0].count}`);

        const projectCount = await verifyClient.query(`
          SELECT COUNT(*) as count FROM project_management_tool.project;
        `);
        console.log(`   ✓ Projects migrated: ${projectCount.rows[0].count}`);

        const cardCount = await verifyClient.query(`
          SELECT COUNT(*) as count FROM project_management_tool.card;
        `);
        console.log(`   ✓ Cards migrated: ${cardCount.rows[0].count}`);

        const taskCount = await verifyClient.query(`
          SELECT COUNT(*) as count FROM project_management_tool.task;
        `);
        console.log(`   ✓ Tasks migrated: ${taskCount.rows[0].count}`);

        await verifyClient.end();

        console.log('\n🎉 Migration completed successfully!');
        console.log('\nNext steps:');
        console.log('1. Extract and restore attachment files');
        console.log('2. Test your application connection');
        console.log('3. Verify all data is accessible\n');

        resolve();
      } catch (error) {
        console.error('⚠️  Verification error:', error.message);
        reject(error);
      }
    });
  });
}

// Check if psql is available
const { execSync } = require('child_process');
try {
  execSync('which psql', { stdio: 'ignore' });
} catch (error) {
  console.error('❌ psql command not found!');
  console.error('   Please install PostgreSQL client tools.');
  console.error('   On macOS: brew install postgresql');
  process.exit(1);
}

// Check if SQL file exists
if (!fs.existsSync(sqlFile)) {
  console.error('❌ SQL file not found:', sqlFile);
  process.exit(1);
}

runMigration().catch((error) => {
  console.error('Migration failed:', error.message);
  process.exit(1);
});
