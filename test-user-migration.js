const { Pool } = require('pg');

const pool = new Pool({
  connectionString: 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres',
  ssl: { rejectUnauthorized: false },
  max: 2,
  connectionTimeoutMillis: 30000,
});

async function testUserMigration() {
  console.log('🧪 Testing user_account table migration...\n');

  const client = await pool.connect();

  try {
    console.log('✅ Connected to Supabase!\n');

    // Step 1: Prepare schema
    console.log('🗑️  Cleaning schema...');
    await client.query('DROP SCHEMA IF EXISTS project_management_tool CASCADE');
    await client.query('CREATE SCHEMA project_management_tool');
    await client.query('SET search_path = project_management_tool, public');
    console.log('   ✓ Schema ready\n');

    // Step 2: Create sequence for next_id
    console.log('📦 Creating sequence...');
    await client.query(`
      CREATE SEQUENCE project_management_tool.next_id_seq
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 9223372036854775807
      START 1
      CACHE 1
      NO CYCLE;
    `);
    console.log('   ✓ Sequence created\n');

    // Step 3: Create next_id function
    console.log('🔧 Creating next_id function...');
    await client.query(`
      CREATE FUNCTION project_management_tool.next_id(OUT id bigint) RETURNS bigint
      LANGUAGE plpgsql
      AS $$
        DECLARE
          shard INT := 1;
          epoch BIGINT := 1567191600000;
          sequence BIGINT;
          milliseconds BIGINT;
        BEGIN
          SELECT nextval('next_id_seq') % 1024 INTO sequence;
          SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO milliseconds;
          id := (milliseconds - epoch) << 23;
          id := id | (shard << 10);
          id := id | (sequence);
        END;
      $$;
    `);
    console.log('   ✓ Function created\n');

    // Step 4: Create user_account table
    console.log('📋 Creating user_account table...');
    await client.query(`
      CREATE TABLE project_management_tool.user_account (
        id bigint DEFAULT project_management_tool.next_id() NOT NULL,
        email text NOT NULL,
        password text,
        is_admin boolean NOT NULL,
        name text NOT NULL,
        username text,
        phone text,
        organization text,
        subscribe_to_own_cards boolean NOT NULL,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        deleted_at timestamp without time zone,
        language text,
        password_changed_at timestamp without time zone,
        avatar jsonb,
        is_sso boolean NOT NULL
      );
    `);
    console.log('   ✓ Table created\n');

    // Step 5: Add primary key
    console.log('🔑 Adding primary key...');
    await client.query(`
      ALTER TABLE project_management_tool.user_account
      ADD CONSTRAINT user_account_pkey PRIMARY KEY (id);
    `);
    console.log('   ✓ Primary key added\n');

    // Step 6: Insert users
    console.log('👥 Inserting users...');

    const users = [
      [1433297069220562376, 'trisikh@turfmapp.com', '$2b$10$Faa0XpKZJvKO0ciUGCpnrO2ISYqKmGJ9U.l6CeGkOSJME/kLE8qh.', true, 'Trisikh', null, null, null, false, '2025-01-28 08:45:25.332', '2025-01-28 08:45:28.391', null, null, null, null, false],
      [1430525186381186093, 'apiwat@turfmapp.com', '$2b$10$/9iTfl4oMjTHCVcbcEVEuOtD4bHh1GatVZpB4.JKOhB5p8v/o4HaO', true, 'Sharp', null, null, null, false, '2025-01-24 12:58:11.148', '2025-01-30 07:29:37.919', null, 'en-US', '2025-01-30 07:29:37', null, false],
      [1435352068222093091, 'bam@turfmapp.com', '$2b$10$V1.c46PiLBBm4QXZoHGJnORf.W3qn9GT51.ANaDHL4n7KTXWgGtxm', false, 'Bam', null, null, null, false, '2025-01-31 04:48:20.304', null, null, null, null, null, false],
      [1430501158790628357, 'sira@turfmapp.com', '$2b$10$wF9.Hqo9V5/KFAjBThFFyels2tWyClQIbdUZXI6s6apfQDWU/rExW', true, 'Sira (Tu)', null, null, null, true, '2025-01-24 12:10:26.837', '2025-01-25 02:57:25.741', null, null, '2025-01-25 02:57:09', null, false],
      [1433172478670144855, 'chanyanut@turfmapp.com', '$2b$10$V6Ahzn3Bu060ffV5VeK7.O66ZV6QA82coHJMpNvLFKE/aBa9wbifO', true, 'Lookchin', null, null, null, false, '2025-01-28 04:37:52.983', '2025-01-28 04:48:59.24', null, null, null, null, false],
      [1433171377464018261, 'pattarawadee@turfmapp.com', '$2b$10$Ts8g3SWbIc8LUA9jJSZWyeAmYpsw.Q5saK119TXhH3.SEJlraViPi', true, 'Pin', null, null, null, false, '2025-01-28 04:35:41.708', '2025-01-28 04:49:11.932', null, null, null, null, false],
      [1432141375276582075, 'tri@turfmapp.com', '$2b$10$sHz/4GIVUP/YzTRYwQ.ABO2Pf/qF1AefFTIisY54.oJ7re0DtrTAe', true, 'Tri', null, null, null, false, '2025-01-26 18:29:15.879', '2025-01-28 07:34:38.145', null, null, null, null, false],
      [1433261799410501042, 'phyopyae@turfmapp.com', '$2b$10$YEgWGOckQmJ7bN4c5L930exQvUNWbUMZ.z76G3.sMiEMwSGMpLRle', false, 'Phyo', null, null, null, false, '2025-01-28 07:35:20.843', null, null, null, null, null, false],
      [1430534043199341650, 'wisuwat@turfmapp.com', '$2b$10$2qbhWeXitOkj86skOadTC.JJe6KOmMID3PiCee63LFGV9qjW9nBPy', true, 'Wisuwat', null, null, null, false, '2025-01-24 13:15:46.964', '2025-01-28 08:22:16.343', null, null, '2025-01-28 08:22:16', null, false],
      [1440527451150092120, 'natthawut@turfmapp.com', '$2b$10$PozMgG6FjP4vVOrpWf/ZlunHE/PAJ0SEWqm25XfUoHOANbWAGDFO.', false, 'Natthawut', null, null, null, false, '2025-02-07 08:10:54.026', null, null, null, null, null, false],
    ];

    for (const user of users) {
      await client.query(`
        INSERT INTO project_management_tool.user_account
        (id, email, password, is_admin, name, username, phone, organization, subscribe_to_own_cards,
         created_at, updated_at, deleted_at, language, password_changed_at, avatar, is_sso)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
      `, user);
      console.log(`   ✓ ${user[4]} (${user[1]})`);
    }

    console.log(`\n   ✓ Inserted ${users.length} users\n`);

    // Step 7: Verify
    console.log('🔍 Verifying...');
    const count = await client.query('SELECT COUNT(*) FROM project_management_tool.user_account');
    console.log(`   ✓ Total users in database: ${count.rows[0].count}`);

    const adminCount = await client.query('SELECT COUNT(*) FROM project_management_tool.user_account WHERE is_admin = true');
    console.log(`   ✓ Admin users: ${adminCount.rows[0].count}`);

    const sampleUser = await client.query('SELECT id, name, email FROM project_management_tool.user_account LIMIT 1');
    console.log(`   ✓ Sample user: ${sampleUser.rows[0].name} (${sampleUser.rows[0].email})`);

    console.log('\n🎉 Test migration successful!\n');
    console.log('✅ Ready to run full migration');

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    console.error(error.stack);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

testUserMigration();
