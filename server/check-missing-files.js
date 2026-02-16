const { S3Client, ListObjectsV2Command } = require('@aws-sdk/client-s3');
const { Pool } = require('pg');

const s3 = new S3Client({
  region: 'auto',
  endpoint: 'https://769c64a7e39c6ea5f51513b8e2ed9c5b.r2.cloudflarestorage.com',
  credentials: {
    accessKeyId: '9f3ce3b3548bead7a9ce8f7da8f3a71c',
    secretAccessKey: '8a144d9d6b3b79bfb107693c35db5d861842f37b8c968f39f817403850341ad4',
  },
});

const pool = new Pool({
  connectionString: 'postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres',
  ssl: { rejectUnauthorized: false },
});

async function checkMissing() {
  console.log('🔍 Comparing Database vs R2 Storage\n');

  const dbClient = await pool.connect();
  
  try {
    // Get all attachments from DB
    const dbAttachments = await dbClient.query(`
      SELECT id, name, dirname
      FROM project_management_tool.attachment
      ORDER BY id
    `);

    // Get files from R2
    const s3Command = new ListObjectsV2Command({
      Bucket: 'project-management-tool',
    });
    const s3Response = await s3.send(s3Command);
    const s3Files = (s3Response.Contents || []).map(f => f.Key);

    console.log(`📊 Database: ${dbAttachments.rows.length} attachments`);
    console.log(`📦 R2 Storage: ${s3Files.length} files\n`);

    // Find missing files
    const missing = [];
    dbAttachments.rows.forEach(att => {
      // Check if directory exists in R2
      const dirInR2 = s3Files.some(f => f.includes(`${att.dirname}/`));
      if (!dirInR2) {
        missing.push({ id: att.id, name: att.name, dirname: att.dirname });
      }
    });

    if (missing.length === 0) {
      console.log('✅ All attachment files are in R2!\n');
      return;
    }

    console.log(`❌ Missing from R2: ${missing.length} attachments\n`);
    console.log('Missing files:\n');
    missing.forEach(att => {
      console.log(`   ID: ${att.id}`);
      console.log(`   Name: ${att.name}`);
      console.log(`   Directory: ${att.dirname}\n`);
    });

    console.log(`\n💡 You need to migrate ${missing.length} files from backup`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    dbClient.release();
    await pool.end();
  }
}

checkMissing();
