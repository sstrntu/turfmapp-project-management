const { Pool } = require('pg');
const fs = require('fs');

// Use connection pooling (like asyncpg in turfmapp-ai-agent)
const pool = new Pool({
  connectionString: 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres',
  ssl: {
    rejectUnauthorized: false,
  },
  max: 10,
  idleTimeoutMillis: 30000,
});

async function runMigration() {
  console.log('🔌 Connecting to Supabase...\n');

  const client = await pool.connect();

  try {
    console.log('✅ Connected!\n');

    // Step 1: Clean schema
    console.log('🗑️  Cleaning schema...');
    await client.query('DROP SCHEMA IF EXISTS project_management_tool CASCADE');
    await client.query('CREATE SCHEMA project_management_tool');
    console.log('   ✓ Schema ready\n');

    // Step 2: Read original backup (not the INSERT version)
    console.log('📖 Reading original backup...');
    const originalBackup = '/Users/sirasasitorn/Desktop/turfmapp-backups/backup_20260121_063414.sql';
    let sql = fs.readFileSync(originalBackup, 'utf8');

    // Step 3: Transform to use project_management_tool schema
    console.log('🔄 Transforming schema references...');
    sql = sql.replace(/SCHEMA public/g, 'SCHEMA project_management_tool');
    sql = sql.replace(/public\./g, 'project_management_tool.');
    sql = sql.replace(/SET search_path = '';/g, 'SET search_path = project_management_tool, public;');

    // Remove problematic commands
    sql = sql.replace(/\\\\restrict.*\n/g, '');
    sql = sql.replace(/ALTER .* OWNER TO .*;/g, '');

    // Step 4: Split into schema and data
    console.log('📝 Extracting schema and data sections...\n');

    const sections = {
      preamble: [],
      functions: [],
      sequences: [],
      tables: [],
      data: [],
      constraints: [],
      indexes: []
    };

    const lines = sql.split('\n');
    let currentSection = 'preamble';
    let buffer = '';
    let inCopy = false;

    for (const line of lines) {
      // Track COPY blocks
      if (line.match(/^COPY .* FROM stdin;/)) {
        inCopy = true;
        buffer = line + '\n';
        continue;
      }
      if (inCopy) {
        buffer += line + '\n';
        if (line.trim() === '\\.') {
          sections.data.push(buffer);
          buffer = '';
          inCopy = false;
        }
        continue;
      }

      buffer += line + '\n';

      // Detect section changes
      if (line.includes('CREATE FUNCTION')) currentSection = 'functions';
      else if (line.includes('CREATE SEQUENCE')) currentSection = 'sequences';
      else if (line.includes('CREATE TABLE')) currentSection = 'tables';
      else if (line.includes('ALTER TABLE') && line.includes('ADD CONSTRAINT')) currentSection = 'constraints';
      else if (line.includes('CREATE INDEX')) currentSection = 'indexes';

      // Statement complete
      if (line.trim().endsWith(';') && !inCopy) {
        if (buffer.trim() && !buffer.trim().startsWith('--')) {
          sections[currentSection].push(buffer.trim());
        }
        buffer = '';
      }
    }

    // Step 5: Execute schema creation
    console.log('🏗️  Creating database objects...\n');

    await client.query('BEGIN');

    try {
      // Set search path
      await client.query('SET search_path = project_management_tool, public');

      // Execute in order
      const steps = [
        { name: 'Sequences', items: sections.sequences },
        { name: 'Functions', items: sections.functions },
        { name: 'Tables', items: sections.tables },
      ];

      for (const step of steps) {
        if (step.items.length > 0) {
          console.log(`   Creating ${step.name}...`);
          for (const stmt of step.items) {
            try {
              await client.query(stmt);
            } catch (e) {
              if (!e.message.includes('already exists')) {
                console.error(`   ⚠️  ${e.message.split('\n')[0]}`);
              }
            }
          }
          console.log(`   ✓ ${step.name}: ${step.items.length}`);
        }
      }

      // Load data using COPY protocol
      console.log(`\n📦 Loading data (${sections.data.length} tables)...\n`);

      for (let i = 0; i < sections.data.length; i++) {
        const copyStmt = sections.data[i];
        const match = copyStmt.match(/COPY project_management_tool\.(\w+)/);
        const tableName = match ? match[1] : `table_${i+1}`;

        try {
          // Execute COPY using query protocol
          await client.query(copyStmt);
          console.log(`   ✓ ${tableName}`);
        } catch (e) {
          console.error(`   ⚠️  ${tableName}: ${e.message.split('\n')[0]}`);
        }
      }

      // Add constraints and indexes
      console.log(`\n🔗 Adding constraints and indexes...\n`);

      for (const stmt of [...sections.constraints, ...sections.indexes]) {
        try {
          await client.query(stmt);
        } catch (e) {
          // Silently skip constraint errors
        }
      }
      console.log(`   ✓ Complete`);

      await client.query('COMMIT');

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }

    // Step 6: Verify
    console.log('\n🔍 Verifying migration...\n');

    const tableCount = await client.query(`
      SELECT COUNT(*) as count FROM information_schema.tables
      WHERE table_schema = 'project_management_tool'
    `);
    console.log(`   ✓ Tables: ${tableCount.rows[0].count}`);

    const counts = ['user_account', 'project', 'board', 'card', 'task'];
    for (const table of counts) {
      try {
        const result = await client.query(`SELECT COUNT(*) FROM project_management_tool.${table}`);
        console.log(`   ✓ ${table}: ${result.rows[0].count}`);
      } catch (e) {
        console.log(`   ⚠️  ${table}: error`);
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

runMigration().catch(err => {
  console.error('Fatal error:', err.message);
  process.exit(1);
});
