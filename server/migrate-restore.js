const { Client } = require('pg');
const { from: copyFrom } = require('pg-copy-streams');
const fs = require('fs');
const readline = require('readline');
const path = require('path');
require('dotenv').config();

const migrationFile = path.join(__dirname, '../supabase-migration.sql');

// Use the working pooler connection
const connectionString =
  process.env.DATABASE_URL ||
  'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres';

async function migrate() {
  console.log('🚀 Starting Robust Migration...');
  console.log(`   Target: ${connectionString.split('@')[1]}`);

  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false },
  });

  try {
    await client.connect();
    console.log('✅ Connected to DB');

    // Reset Schema
    console.log('🗑️  Resetting schema...');
    await client.query('DROP SCHEMA IF EXISTS project_management_tool CASCADE');
    await client.query('CREATE SCHEMA project_management_tool');
    // Ensure search_path is set for the session so implicit references work too
    await client.query('SET search_path TO project_management_tool, public');

    const fileStream = fs.createReadStream(migrationFile);
    const rl = readline.createInterface({
      input: fileStream,
      crlfDelay: Infinity,
    });

    let sqlBuffer = '';
    let isCopyMode = false;
    let copyStream = null;
    let copyPromise = null;

    for await (let line of rl) {
      // FIX 1: Replace schema 'public.' with 'project_management_tool.'
      // This forces all CREATE TABLE and COPY commands to use the new schema
      line = line.replace(/public\./g, 'project_management_tool.');

      if (isCopyMode) {
        if (line.trim() === '\\.') {
          // End of COPY
          if (copyStream) {
            copyStream.end();
            await copyPromise;
            console.log('   ✓ Copy complete');
          }
          isCopyMode = false;
          copyStream = null;
          copyPromise = null;
        } else {
          // Write data to stream
          if (copyStream && !copyStream.write(`${line}\n`)) {
            // Handle backpressure
            await new Promise((resolve) => copyStream.once('drain', resolve));
          }
        }
      } else {
        // SQL Mode
        if (line.startsWith('COPY ')) {
          // Flush pending SQL buffer first
          if (sqlBuffer.trim()) {
            await client.query(sqlBuffer);
            sqlBuffer = '';
          }

          // Start COPY
          // FIX 2: pg-copy-streams usually expects the command WITHOUT the semicolon for 'copy-to',
          // but for 'copy-from' (STDIN), it sends the query to server.
          // The server expects valid SQL. Standard SQL requires semicolon.
          // However, some libraries wrap it. pg-copy-streams passes it to `client.query(new CopyStreamQuery(text))`.
          // If the previous error was syntax error at position 107, it might be the semicolon or something else.
          // Let's try removing semicolon just in case it treats it as end of query before data stream starts?
          // Actually, COPY FROM STDIN; is correct.
          // But let's removing it to match `pg-copy-streams` examples often used without it if it appends.
          // Wait, the syntax error `42601` might be due to `public.` references if schema didn't exist? No, `42P01`.
          // Let's keep it safe: remove semicolon carefully.
          const copyCommand = line.replace(';', '');

          console.log(`📦 Starting COPY: ${copyCommand}`);
          isCopyMode = true;
          copyStream = client.query(copyFrom(copyCommand));
          copyPromise = new Promise((resolve, reject) => {
            copyStream.on('finish', resolve);
            copyStream.on('error', reject);
          });
        } else {
          // Accumulate SQL
          // Skip comments and empty lines
          if (line.trim().startsWith('--') || !line.trim()) {
            continue;
          }

          sqlBuffer += `${line}\n`;

          if (line.trim().endsWith(';')) {
            await client.query(sqlBuffer);
            sqlBuffer = '';
          }
        }
      }
    }

    // flushing final buffer
    if (sqlBuffer.trim()) {
      await client.query(sqlBuffer);
    }

    console.log('✅ Migration executed successfully!');

    // Verification
    const tables = await client.query(`
      SELECT table_name FROM information_schema.tables
      WHERE table_schema = 'project_management_tool'
    `);
    console.log(`📊 Found ${tables.rowCount} tables.`);
  } catch (err) {
    console.error('❌ Migration Failed details:');
    if (err.position) {
      console.error(`   Position: ${err.position}`);
    }
    console.error(err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

migrate();
