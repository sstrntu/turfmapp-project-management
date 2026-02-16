const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configure R2
const s3 = new S3Client({
  region: 'auto',
  endpoint: 'https://769c64a7e39c6ea5f51513b8e2ed9c5b.r2.cloudflarestorage.com',
  credentials: {
    accessKeyId: '9f3ce3b3548bead7a9ce8f7da8f3a71c',
    secretAccessKey: '8a144d9d6b3b79bfb107693c35db5d861842f37b8c968f39f817403850341ad4',
  },
});

const BACKUP_DIR = '/Users/sirasasitorn/Desktop/turfmapp-backups';

const MAPPINGS = [
  {
    archive: 'attachments_20260121_063527.tar.gz',
    bucket: 'project-management-tool',
    prefix: 'private/attachments',
    extractDir: 'attachments_temp'
  },
  {
    archive: 'user-avatars_20260121_063504.tar.gz',
    bucket: 'project-management-tool',
    prefix: 'public/user-avatars',
    extractDir: 'user_avatars_temp'
  },
  {
    archive: 'project-background-images_20260121_063521.tar.gz',
    bucket: 'project-management-tool',
    prefix: 'public/project-background-images',
    extractDir: 'project_backgrounds_temp'
  }
];

function getContentType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const types = {
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.pdf': 'application/pdf',
    '.webp': 'image/webp',
  };
  return types[ext] || 'application/octet-stream';
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

async function migrateStorage() {
  console.log('🚀 Starting Cloudflare R2 Storage Migration...\n');

  let totalUploaded = 0;
  let totalFailed = 0;

  for (const mapping of MAPPINGS) {
    const archivePath = path.join(BACKUP_DIR, mapping.archive);
    const extractPath = path.join(__dirname, mapping.extractDir);

    if (!fs.existsSync(archivePath)) {
      console.warn(`⚠️  Archive not found: ${mapping.archive} (skipping)`);
      continue;
    }

    console.log(`📦 Processing ${mapping.archive}...`);

    // Create temp dir
    if (!fs.existsSync(extractPath)) {
      fs.mkdirSync(extractPath, { recursive: true });
    }

    // Extract archive
    console.log(`   Extracting...`);
    try {
      execSync(`tar -xzf "${archivePath}" -C "${extractPath}"`, { stdio: 'pipe' });
    } catch (e) {
      console.error(`   ❌ Failed to extract:`, e.message);
      continue;
    }

    // Upload files
    const files = getFilesRecursive(extractPath);
    console.log(`   Found ${files.length} files to upload\n`);

    for (const filePath of files) {
      const relativePath = path.relative(extractPath, filePath);
      const s3Key = `${mapping.prefix}/${relativePath}`;

      try {
        const fileBuffer = fs.readFileSync(filePath);
        const contentType = getContentType(filePath);

        // Upload to R2 (will overwrite if exists)
        await s3.send(new PutObjectCommand({
          Bucket: mapping.bucket,
          Key: s3Key,
          Body: fileBuffer,
          ContentType: contentType,
        }));

        console.log(`   ✅ ${relativePath}`);
        totalUploaded++;
      } catch (error) {
        console.error(`   ❌ Failed to upload ${relativePath}:`, error.message);
        totalFailed++;
      }
    }

    // Cleanup
    console.log(`\n   Cleaning up temporary files...`);
    fs.rmSync(extractPath, { recursive: true, force: true });
    console.log();
  }

  console.log('📊 Migration Summary:');
  console.log(`   ✅ Successfully uploaded: ${totalUploaded} files`);
  if (totalFailed > 0) {
    console.log(`   ❌ Failed uploads: ${totalFailed} files`);
  }
  console.log('\n🎉 Storage migration to R2 completed!\n');
}

migrateStorage().catch(error => {
  console.error('Fatal error:', error.message);
  process.exit(1);
});
