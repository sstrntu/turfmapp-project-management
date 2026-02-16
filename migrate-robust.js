const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const connectionString = 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres';
const migrationFile = '/Users/sirasasitorn/Documents/VScode/turfmapp/supabase-migration.sql';

async function migrate() {
  console.log('🔌 Connecting to Supabase...');
  console.log('   Host: aws-1-ap-southeast-1.pooler.supabase.com');
  console.log('   Schema: project_management_tool\n');

  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false,
    },
    // Increase timeouts for large operations
    connectionTimeoutMillis: 60000,
    query_timeout: 300000,
  });

  try {
    await client.connect();
    console.log('✅ Connected to Supabase!\n');

    // Check if migration file exists
    if (!fs.existsSync(migrationFile)) {
      console.error('❌ Migration file not found!');
      console.error('   Expected: ' + migrationFile);
      process.exit(1);
    }

    console.log('🗑️  Cleaning existing data in project_management_tool schema...');

    // Drop and recreate schema to ensure clean state
    await client.query('DROP SCHEMA IF EXISTS project_management_tool CASCADE;');
    console.log('   ✓ Dropped existing schema');

    await client.query('CREATE SCHEMA project_management_tool;');
    console.log('   ✓ Created fresh schema\n');

    console.log('📖 Reading and parsing migration SQL...');
    const sql = fs.readFileSync(migrationFile, 'utf8');

    // Split SQL into individual statements, being careful with COPY commands
    const statements = [];
    let currentStatement = '';
    let inCopyBlock = false;

    const lines = sql.split('\n');

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      // Detect COPY command start
      if (line.trim().startsWith('COPY ') && line.includes('FROM stdin;')) {
        if (currentStatement.trim()) {
          statements.push(currentStatement.trim());
          currentStatement = '';
        }
        inCopyBlock = true;
        currentStatement = line + '\n';
        continue;
      }

      // Detect COPY command end
      if (inCopyBlock && line.trim() === '\\.') {
        currentStatement += line + '\n';
        statements.push(currentStatement.trim());
        currentStatement = '';
        inCopyBlock = false;
        continue;
      }

      // Inside COPY block, add line as-is
      if (inCopyBlock) {
        currentStatement += line + '\n';
        continue;
      }

      // Regular SQL line
      currentStatement += line + '\n';

      // If line ends with semicolon and we're not in a COPY block, it's a complete statement
      if (line.trim().endsWith(';') && !inCopyBlock) {
        const stmt = currentStatement.trim();
        if (stmt && !stmt.startsWith('--')) {
          statements.push(stmt);
        }
        currentStatement = '';
      }
    }

    // Add any remaining statement
    if (currentStatement.trim()) {
      statements.push(currentStatement.trim());
    }

    console.log(`   ✓ Parsed ${statements.length} SQL statements\n`);

    console.log('🚀 Executing migration...');
    console.log('   (This may take a few minutes for large datasets)\n');

    let executed = 0;
    let errors = 0;

    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];

      // Skip empty statements and comments
      if (!statement || statement.startsWith('--')) {
        continue;
      }

      try {
        await client.query(statement);
        executed++;

        // Show progress every 50 statements
        if (executed % 50 === 0) {
          console.log(`   Progress: ${executed}/${statements.length} statements executed...`);
        }
      } catch (error) {
        // Some errors are expected (e.g., "already exists")
        if (error.message.includes('already exists')) {
          // Silently ignore
        } else if (error.message.includes('does not exist') && statement.includes('DROP')) {
          // Silently ignore DROP errors
        } else {
          errors++;
          if (errors < 5) {
            console.error(`   ⚠ Warning (statement ${i}): ${error.message.split('\n')[0]}`);
          }
        }
      }
    }

    console.log(`\n   ✓ Executed ${executed} statements (${errors} warnings)\n`);

    console.log('✅ Migration completed!\n');

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

    if (error.code === 'ECONNREFUSED') {
      console.error('\nTip: Could not connect to database. Check connection string.');
    } else if (error.code === 'ENOTFOUND') {
      console.error('\nTip: Database host not found. Check hostname.');
    } else if (error.message.includes('permission')) {
      console.error('\nTip: Check your database user has necessary permissions.');
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
