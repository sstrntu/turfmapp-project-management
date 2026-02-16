const { Pool } = require('pg');
const fs = require('fs');

// Connection configuration (matching the pattern from turfmapp-ai-agent)
const connectionString = 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres';

// Create connection pool (similar to asyncpg.create_pool)
const pool = new Pool({
  connectionString,
  ssl: {
    rejectUnauthorized: false, // Similar to ssl_context.verify_mode = ssl.CERT_NONE
  },
  max: 10, // max_size=10
  min: 1,  // min_size=1
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 60000,
});

async function executeMigration() {
  console.log('🔌 Connecting to Supabase with connection pool...');
  console.log('   Host: aws-1-ap-southeast-1.pooler.supabase.com');
  console.log('   Schema: project_management_tool\n');

  const client = await pool.connect();

  try {
    console.log('✅ Connected to Supabase!\n');

    // Clean and prepare schema
    console.log('🗑️  Preparing schema...');
    await client.query('DROP SCHEMA IF EXISTS project_management_tool CASCADE;');
    console.log('   ✓ Dropped existing schema');

    await client.query('CREATE SCHEMA project_management_tool;');
    console.log('   ✓ Created fresh schema');

    await client.query('SET search_path TO project_management_tool, public;');
    console.log('   ✓ Set search path\n');

    // Read the SQL file (using INSERT statements version)
    const sqlFile = '/Users/sirasasitorn/Documents/VScode/turfmapp/migration-inserts.sql';
    console.log('📖 Reading SQL file with INSERT statements...');
    const sqlContent = fs.readFileSync(sqlFile, 'utf8');

    // Split into statements while preserving COPY blocks
    console.log('📝 Parsing SQL statements...');
    const statements = parseSqlStatements(sqlContent);
    console.log(`   ✓ Found ${statements.length} statements\n`);

    // Execute statements one by one
    console.log('🚀 Executing migration...');
    console.log('   (This may take a few minutes)\n');

    let executed = 0;
    let skipped = 0;

    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];

      // Skip empty or comment-only statements
      if (!statement.trim() || statement.trim().startsWith('--')) {
        continue;
      }

      try {
        await client.query(statement);
        executed++;

        // Show progress and key statements
        if (statement.includes('CREATE TABLE') || statement.includes('CREATE FUNCTION')) {
          const match = statement.match(/CREATE (?:TABLE|FUNCTION) (?:project_management_tool\.)?(\w+)/);
          if (match) {
            console.log(`   ✓ Created: ${match[1]}`);
          }
        } else if (executed % 100 === 0) {
          console.log(`   Progress: ${executed} statements executed...`);
        }
      } catch (error) {
        // Ignore expected errors
        if (error.message.includes('already exists') ||
            (error.message.includes('does not exist') && statement.includes('DROP'))) {
          skipped++;
        } else {
          // For critical errors, show detailed message
          if (statement.includes('CREATE TABLE') || statement.includes('CREATE FUNCTION') || statement.includes('CREATE SEQUENCE')) {
            console.error(`\n❌ CRITICAL Error in statement ${i + 1}:`);
            console.error(`      ${error.message.split('\n')[0]}`);
            console.error(`      Statement: ${statement.substring(0, 150)}...`);
          } else {
            console.error(`\n   ⚠️  Error in statement ${i + 1}:`);
            console.error(`      ${error.message.split('\n')[0]}`);
            console.error(`      Statement: ${statement.substring(0, 100)}...`);
          }

          // Don't stop on individual statement errors, continue
          if (!error.message.includes('syntax error')) {
            skipped++;
          }
        }
      }
    }

    console.log(`\n   ✓ Executed ${executed} statements (${skipped} skipped)\n`);

    // Verify migration
    console.log('🔍 Verifying migration...');

    const tableCount = await client.query(`
      SELECT COUNT(*) as count
      FROM information_schema.tables
      WHERE table_schema = 'project_management_tool';
    `);
    console.log(`   ✓ Tables created: ${tableCount.rows[0].count}`);

    // Check data in key tables
    const tables = ['user_account', 'project', 'board', 'card', 'task'];
    for (const table of tables) {
      try {
        const result = await client.query(`SELECT COUNT(*) as count FROM project_management_tool.${table};`);
        console.log(`   ✓ ${table}: ${result.rows[0].count} records`);
      } catch (e) {
        console.log(`   ⚠️  ${table}: ${e.message}`);
      }
    }

    console.log('\n🎉 Migration completed successfully!');
    console.log('\nNext steps:');
    console.log('1. Extract and restore attachment files');
    console.log('2. Test your application connection');
    console.log('3. Verify all data is accessible\n');

  } catch (error) {
    console.error('\n❌ Migration failed!');
    console.error('Error:', error.message);
    console.error('\nStack:', error.stack);
    throw error;
  } finally {
    client.release();
    await pool.end();
    console.log('📪 Connection pool closed');
  }
}

function parseSqlStatements(sql) {
  const statements = [];
  let current = '';
  let inDollarQuote = false;
  let dollarTag = '';

  const lines = sql.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Check for dollar-quoted strings (like $$...$$)
    const dollarMatch = line.match(/\$([a-zA-Z0-9_]*)\$/);
    if (dollarMatch) {
      const tag = dollarMatch[0];
      if (!inDollarQuote) {
        inDollarQuote = true;
        dollarTag = tag;
      } else if (tag === dollarTag) {
        inDollarQuote = false;
        dollarTag = '';
      }
    }

    // Add line to current statement
    current += line + '\n';

    // Statement complete (ends with ; and not in dollar quote)
    if (line.trim().endsWith(';') && !inDollarQuote) {
      const stmt = current.trim();
      if (stmt && !stmt.startsWith('--')) {
        statements.push(stmt);
      }
      current = '';
    }
  }

  // Add any remaining statement
  if (current.trim()) {
    statements.push(current.trim());
  }

  return statements;
}

// Run migration
executeMigration().catch((error) => {
  console.error('Fatal error:', error.message);
  process.exit(1);
});
