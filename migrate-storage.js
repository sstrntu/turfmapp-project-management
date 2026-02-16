const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
require('dotenv').config({ path: path.join(__dirname, 'server', '.env') });

// Configuration
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://pwxhgvuyaxgavommtqpr.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
const BACKUP_DIR = '/Users/sirasasitorn/Desktop/turfmapp-backups';

if (!SUPABASE_SERVICE_KEY) {
  console.error('❌ Error: SUPABASE_SERVICE_KEY is missing from environment variables.');
  console.error('   Please add it to server/.env or export it in your terminal.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

const MAPPINGS = [
  {
    archive: 'attachments_20260121_063527.tar.gz',
    bucket: 'attachments',
    extractDir: 'attachments_temp'
  },
  {
    archive: 'user-avatars_20260121_063504.tar.gz',
    bucket: 'user-avatars',
    extractDir: 'user_avatars_temp'
  },
  {
    archive: 'project-background-images_20260121_063521.tar.gz',
    bucket: 'project-background-images',
    extractDir: 'project_backgrounds_temp'
  }
];

async function migrateStorage() {
  console.log('🚀 Starting Storage Migration...');

  for (const mapping of MAPPINGS) {
    const archivePath = path.join(BACKUP_DIR, mapping.archive);
    const extractPath = path.join(__dirname, mapping.extractDir);

    if (!fs.existsSync(archivePath)) {
      console.warn(`⚠️  Archive not found: ${mapping.archive} (skipping)`);
      continue;
    }

    console.log(`\n📦 Processing ${mapping.bucket}...`);

    // Create temp dir
    if (!fs.existsSync(extractPath)) {
      fs.mkdirSync(extractPath);
    }

    // Extract archive
    console.log(`   Extracting ${mapping.archive}...`);
    try {
      execSync(`tar -xzf "${archivePath}" -C "${extractPath}"`);
    } catch (e) {
      console.error(`   ❌ Failed to extract ${mapping.archive}:`, e.message);
      continue;
    }

    // Upload files
    const files = getFilesRecursive(extractPath);
    console.log(`   Found ${files.length} files to upload.`);

    for (const filePath of files) {
      const relativePath = path.relative(extractPath, filePath);
      const fileBuffer = fs.readFileSync(filePath);

      // Determine content type (simple version)
      let contentType = 'application/octet-stream';
      if (filePath.endsWith('.png')) contentType = 'image/png';
      if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) contentType = 'image/jpeg';
      if (filePath.endsWith('.gif')) contentType = 'image/gif';
      if (filePath.endsWith('.pdf')) contentType = 'application/pdf';

      // Upload with upsert
      const { error } = await supabase.storage
        .from(mapping.bucket)
        .upload(relativePath, fileBuffer, {
          contentType,
          upsert: true
        });

      if (error) {
        console.error(`   ❌ Failed to upload ${relativePath}:`, error.message);
      } else {
        console.log(`   ✅ Uploaded: ${relativePath}`);
      }
    }

    // Cleanup
    fs.rmSync(extractPath, { recursive: true, force: true });
  }

  console.log('\n🎉 Storage migration completed!');
}

function getFilesRecursive(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(getFilesRecursive(file));
    } else {
      results.push(file);
    }
  });
  return results;
}

migrateStorage();
