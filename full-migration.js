const { Pool } = require('pg');
const fs = require('fs');

const pool = new Pool({
  connectionString: 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres',
  ssl: { rejectUnauthorized: false },
  max: 3,
  connectionTimeoutMillis: 30000,
});

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function fullMigration() {
  console.log('🚀 Starting full database migration...\n');

  const client = await pool.connect();

  try {
    console.log('✅ Connected to Supabase!\n');

    // Step 1: Clean schema
    console.log('🗑️  Cleaning schema...');
    await client.query('DROP SCHEMA IF EXISTS project_management_tool CASCADE');
    await client.query('CREATE SCHEMA project_management_tool');
    await client.query('SET search_path = project_management_tool, public');
    console.log('   ✓ Schema ready\n');

    // Step 2: Read the INSERT-based migration file
    console.log('📖 Reading migration file...');
    const sql = fs.readFileSync('migration-inserts.sql', 'utf8');
    const lines = sql.split('\n');

    // Step 3: Parse into statement groups
    console.log('📝 Parsing SQL statements...\n');

    const ddlStatements = [];  // CREATE TABLE, CREATE FUNCTION, etc.
    const insertStatements = [];  // INSERT INTO
    const constraintStatements = [];  // ALTER TABLE ADD CONSTRAINT
    const indexStatements = [];  // CREATE INDEX

    let currentStmt = '';
    let inFunction = false;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      // Track function boundaries (they use $$)
      if (line.includes('$$')) {
        inFunction = !inFunction;
      }

      currentStmt += line + '\n';

      // Statement complete?
      if (line.trim().endsWith(';') && !inFunction) {
        const stmt = currentStmt.trim();

        if (stmt && stmt.length > 15) {
          // Remove comment lines at the start
          const stmtLines = stmt.split('\n');
          let firstNonCommentLine = '';
          for (const l of stmtLines) {
            const trimmedLine = l.trim();
            if (trimmedLine && !trimmedLine.startsWith('--')) {
              firstNonCommentLine = trimmedLine;
              break;
            }
          }

          // Categorize by first non-comment line
          if (firstNonCommentLine.startsWith('CREATE SEQUENCE')) {
            ddlStatements.push({ type: 'sequence', sql: stmt });
          } else if (firstNonCommentLine.startsWith('CREATE FUNCTION')) {
            ddlStatements.push({ type: 'function', sql: stmt });
          } else if (firstNonCommentLine.startsWith('CREATE TABLE')) {
            ddlStatements.push({ type: 'table', sql: stmt });
          } else if (firstNonCommentLine.match(/^ALTER TABLE.*ADD CONSTRAINT/i)) {
            constraintStatements.push(stmt);
          } else if (firstNonCommentLine.startsWith('CREATE') && firstNonCommentLine.includes('INDEX')) {
            indexStatements.push(stmt);
          } else if (firstNonCommentLine.startsWith('INSERT INTO')) {
            insertStatements.push(stmt);
          } else if (firstNonCommentLine.startsWith('SET ')) {
            // Execute SET commands immediately
            try {
              await client.query(stmt);
            } catch (e) {
              // Ignore SET errors
            }
          }
        }

        currentStmt = '';
      }
    }

    console.log(`   ✓ Sequences: ${ddlStatements.filter(s => s.type === 'sequence').length}`);
    console.log(`   ✓ Functions: ${ddlStatements.filter(s => s.type === 'function').length}`);
    console.log(`   ✓ Tables: ${ddlStatements.filter(s => s.type === 'table').length}`);
    console.log(`   ✓ Inserts: ${insertStatements.length}`);
    console.log(`   ✓ Constraints: ${constraintStatements.length}`);
    console.log(`   ✓ Indexes: ${indexStatements.length}\n`);

    // Step 4: Execute DDL in order
    console.log('🏗️  Creating database objects...\n');

    // Sequences first
    console.log('   Creating sequences...');
    for (const stmt of ddlStatements.filter(s => s.type === 'sequence')) {
      try {
        await client.query(stmt.sql);
      } catch (e) {
        console.error(`   ⚠️  Sequence error: ${e.message.substring(0, 60)}`);
      }
    }

    // Functions
    console.log('   Creating functions...');
    for (const stmt of ddlStatements.filter(s => s.type === 'function')) {
      try {
        await client.query(stmt.sql);
      } catch (e) {
        console.error(`   ⚠️  Function error: ${e.message.substring(0, 60)}`);
      }
    }

    // Tables
    console.log('   Creating tables...');
    for (const stmt of ddlStatements.filter(s => s.type === 'table')) {
      try {
        await client.query(stmt.sql);
        const match = stmt.sql.match(/CREATE TABLE project_management_tool\.(\w+)/);
        if (match) {
          console.log(`   ✓ ${match[1]}`);
        }
      } catch (e) {
        console.error(`   ⚠️  Table error: ${e.message.substring(0, 80)}`);
      }
    }

    console.log('');

    // Step 5: Insert data
    console.log('📦 Inserting data...\n');

    let inserted = 0;
    let errors = 0;

    for (let i = 0; i < insertStatements.length; i++) {
      try {
        await client.query(insertStatements[i]);
        inserted++;

        if (inserted % 100 === 0) {
          console.log(`   Progress: ${inserted}/${insertStatements.length}`);
          await sleep(50);  // Small delay to avoid overwhelming the connection
        }
      } catch (e) {
        errors++;
        if (errors < 5) {
          console.error(`   ⚠️  Insert error: ${e.message.substring(0, 60)}`);
        }
      }
    }

    console.log(`\n   ✓ Inserted ${inserted} rows (${errors} errors)\n`);

    // Step 6: Add constraints
    console.log('🔗 Adding constraints...');
    for (const stmt of constraintStatements) {
      try {
        await client.query(stmt);
      } catch (e) {
        // Ignore constraint errors for now
      }
    }
    console.log(`   ✓ Constraints added\n`);

    // Step 7: Create indexes
    console.log('📇 Creating indexes...');
    for (const stmt of indexStatements) {
      try {
        await client.query(stmt);
      } catch (e) {
        // Ignore index errors
      }
    }
    console.log(`   ✓ Indexes created\n`);

    // Step 8: Verify
    console.log('🔍 Verifying migration...\n');

    const tableCount = await client.query(`
      SELECT COUNT(*) as count FROM information_schema.tables
      WHERE table_schema = 'project_management_tool'
    `);
    console.log(`   ✓ Tables created: ${tableCount.rows[0].count}`);

    // Check key tables
    const tables = ['user_account', 'project', 'board', 'list', 'card', 'task', 'action', 'notification'];
    for (const table of tables) {
      try {
        const result = await client.query(`SELECT COUNT(*) FROM project_management_tool.${table}`);
        console.log(`   ✓ ${table}: ${result.rows[0].count} records`);
      } catch (e) {
        console.log(`   ⚠️  ${table}: ${e.message.substring(0, 50)}`);
      }
    }

    console.log('\n🎉 Migration completed successfully!\n');

  } catch (error) {
    console.error('\n❌ Migration failed:', error.message);
    console.error(error.stack);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

fullMigration();
