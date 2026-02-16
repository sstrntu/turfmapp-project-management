const { Client } = require('pg');

const connectionString = 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres';

async function verify() {
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false },
  });

  try {
    await client.connect();
    console.log('🔍 Verifying migration to project_management_tool schema...\n');

    // Check tables
    const tables = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'project_management_tool'
      ORDER BY table_name;
    `);
    console.log(`✓ Tables (${tables.rows.length}):`);
    tables.rows.forEach(row => console.log(`  - ${row.table_name}`));

    // Check data counts
    console.log('\n📊 Data counts:');

    const counts = [
      'user_account',
      'project',
      'board',
      'list',
      'card',
      'task',
      'action',
      'attachment',
      'label',
      'notification',
      'session',
      'board_membership',
      'card_membership',
      'project_manager'
    ];

    for (const table of counts) {
      try {
        const result = await client.query(`SELECT COUNT(*) FROM project_management_tool.${table}`);
        console.log(`  ${table}: ${result.rows[0].count}`);
      } catch (e) {
        console.log(`  ${table}: ⚠ ${e.message}`);
      }
    }

    console.log('\n✅ Migration verification complete!\n');

  } catch (error) {
    console.error('❌ Verification failed:', error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

verify();
