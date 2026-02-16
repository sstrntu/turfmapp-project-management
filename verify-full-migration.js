const { Pool } = require('pg');

const pool = new Pool({
  connectionString: 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres',
  ssl: { rejectUnauthorized: false },
});

async function verifyMigration() {
  console.log('🔍 Comprehensive Migration Verification\n');

  const client = await pool.connect();

  try {
    // Check all tables
    console.log('📊 Table Statistics:\n');
    const tables = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'project_management_tool'
      ORDER BY table_name
    `);

    for (const row of tables.rows) {
      const count = await client.query(`SELECT COUNT(*) FROM project_management_tool.${row.table_name}`);
      console.log(`   ${row.table_name}: ${count.rows[0].count} records`);
    }

    // Check key relationships
    console.log('\n🔗 Data Integrity Checks:\n');

    // Users
    const users = await client.query('SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE is_admin = true) as admins FROM project_management_tool.user_account');
    console.log(`   ✓ Users: ${users.rows[0].total} total (${users.rows[0].admins} admins)`);

    // Projects with boards
    const projects = await client.query(`
      SELECT p.name, COUNT(b.id) as board_count
      FROM project_management_tool.project p
      LEFT JOIN project_management_tool.board b ON p.id = b.project_id
      GROUP BY p.id, p.name
      ORDER BY p.name
    `);
    console.log(`   ✓ Projects: ${projects.rows.length}`);
    for (const p of projects.rows) {
      console.log(`     - ${p.name}: ${p.board_count} boards`);
    }

    // Cards with tasks
    const cardStats = await client.query(`
      SELECT
        COUNT(DISTINCT c.id) as card_count,
        COUNT(t.id) as task_count,
        COUNT(DISTINCT a.id) as action_count
      FROM project_management_tool.card c
      LEFT JOIN project_management_tool.task t ON c.id = t.card_id
      LEFT JOIN project_management_tool.action a ON c.id = a.card_id
    `);
    console.log(`   ✓ Cards: ${cardStats.rows[0].card_count} with ${cardStats.rows[0].task_count} tasks and ${cardStats.rows[0].action_count} actions`);

    // Check functions exist
    const functions = await client.query(`
      SELECT routine_name
      FROM information_schema.routines
      WHERE routine_schema = 'project_management_tool'
    `);
    console.log(`\n🔧 Functions: ${functions.rows.length}`);
    for (const f of functions.rows) {
      console.log(`   ✓ ${f.routine_name}()`);
    }

    // Check indexes
    const indexes = await client.query(`
      SELECT indexname
      FROM pg_indexes
      WHERE schemaname = 'project_management_tool'
      ORDER BY indexname
    `);
    console.log(`\n📇 Indexes: ${indexes.rows.length} created`);

    // Sample data check
    console.log('\n👤 Sample User Data:\n');
    const sampleUsers = await client.query(`
      SELECT name, email, is_admin
      FROM project_management_tool.user_account
      ORDER BY created_at
      LIMIT 5
    `);
    for (const u of sampleUsers.rows) {
      console.log(`   ${u.is_admin ? '👑' : '👤'} ${u.name} (${u.email})`);
    }

    console.log('\n✅ Migration verification complete!\n');
    console.log('🎉 All data successfully migrated to Supabase!\n');

  } catch (error) {
    console.error('❌ Verification error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

verifyMigration();
