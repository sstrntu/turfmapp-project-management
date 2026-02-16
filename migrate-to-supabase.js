const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, 'server', '.env') });

const migrationFile = path.join(__dirname, 'migration-inserts.sql');

async function migrate() {
  const connectionString = process.env.DATABASE_URL || 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres';

  console.log('🔌 Connecting to Supabase...');
  console.log(`   Host: aws-1-ap-southeast-1.pooler.supabase.com`);
  console.log(`   Schema: project_management_tool\n`);

  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false,
    },
  });

  try {
    await client.connect();
    console.log('✅ Connected to Supabase!\n');

    // Check if migration file exists
    if (!fs.existsSync(migrationFile)) {
      console.error('❌ Migration file not found!');
      console.error('   Run: node migrate-backup.js first\n');
      process.exit(1);
    }

    console.log('📖 Reading migration SQL...');
    const sql = fs.readFileSync(migrationFile, 'utf8');

    console.log('🗑️  Cleaning existing data in project_management_tool schema...');

    // Drop and recreate schema to ensure clean state
    await client.query('DROP SCHEMA IF EXISTS project_management_tool CASCADE;');
    console.log('   ✓ Dropped existing schema');

    await client.query('CREATE SCHEMA project_management_tool;');
    console.log('   ✓ Created fresh schema\n');

    console.log('🚀 Executing migration (this may take a moment)...');

    // Execute the migration SQL
    await client.query(sql);

    console.log('✅ Migration executed successfully!\n');

    // Verify the migration
    console.log('🔍 Verifying migration...');

    const tableCountResult = await client.query(`
      SELECT COUNT(*) as table_count
      FROM information_schema.tables
      WHERE table_schema = 'project_management_tool';
    `);
    console.log(`   ✓ Tables created: ${tableCountResult.rows[0].table_count}`);

    const userCountResult = await client.query(`
      SELECT COUNT(*) as user_count
      FROM project_management_tool.user_account;
    `);
    console.log(`   ✓ Users migrated: ${userCountResult.rows[0].user_count}`);

    const projectCountResult = await client.query(`
      SELECT COUNT(*) as project_count
      FROM project_management_tool.project;
    `);
    console.log(`   ✓ Projects migrated: ${projectCountResult.rows[0].project_count}`);

    const cardCountResult = await client.query(`
      SELECT COUNT(*) as card_count
      FROM project_management_tool.card;
    `);
    console.log(`   ✓ Cards migrated: ${cardCountResult.rows[0].card_count}`);

    console.log('\n🎉 Migration completed successfully!');
    console.log('\nNext steps:');
    console.log('1. Test your application connection');
    console.log('2. Migrate attachment files if needed');
    console.log('3. Verify all data is accessible\n');

  } catch (error) {
    console.error('\n❌ Migration failed!');
    console.error('Error:', error.message);

    if (error.message.includes('already exists')) {
      console.error('\nTip: Some objects already exist. This is usually safe to ignore.');
    } else if (error.message.includes('permission')) {
      console.error('\nTip: Check your database user has CREATE permissions on the schema.');
    } else {
      console.error('\nFull error details:');
      console.error(error);
    }

    process.exit(1);
  } finally {
    await client.end();
    console.log('📪 Disconnected from database');
  }
}

migrate();
