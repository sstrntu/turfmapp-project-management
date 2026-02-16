const { S3Client, ListObjectsV2Command } = require('@aws-sdk/client-s3');

const s3 = new S3Client({
  region: 'auto',
  endpoint: 'https://769c64a7e39c6ea5f51513b8e2ed9c5b.r2.cloudflarestorage.com',
  credentials: {
    accessKeyId: '9f3ce3b3548bead7a9ce8f7da8f3a71c',
    secretAccessKey: '8a144d9d6b3b79bfb107693c35db5d861842f37b8c968f39f817403850341ad4',
  },
});

async function checkR2() {
  console.log('🔍 Checking Cloudflare R2 Storage\n');

  try {
    // List all objects
    const command = new ListObjectsV2Command({
      Bucket: 'project-management-tool',
    });

    const response = await s3.send(command);
    const files = response.Contents || [];

    console.log(`📦 Total files in R2: ${files.length}\n`);

    if (files.length === 0) {
      console.log('   ❌ R2 bucket is empty');
      return;
    }

    // Group by type
    const attachments = files.filter(f => f.Key.includes('attachments/'));
    const avatars = files.filter(f => f.Key.includes('user-avatars/'));
    const backgrounds = files.filter(f => f.Key.includes('project-background'));

    console.log(`🖼️  Attachments: ${attachments.length} files`);
    if (attachments.length > 0) {
      attachments.slice(0, 3).forEach(f => {
        console.log(`   - ${f.Key}`);
      });
      if (attachments.length > 3) {
        console.log(`   ... and ${attachments.length - 3} more`);
      }
    }

    console.log(`\n👤 User Avatars: ${avatars.length} files`);
    console.log(`\n🌄 Project Backgrounds: ${backgrounds.length} files`);

    // Total size
    const totalSize = files.reduce((sum, f) => sum + f.Size, 0);
    console.log(`\n📊 Total size: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);

    // List all files by prefix
    console.log(`\n📋 All files by category:\n`);

    const categories = {};
    files.forEach(f => {
      const prefix = f.Key.split('/')[0] || 'root';
      if (!categories[prefix]) categories[prefix] = [];
      categories[prefix].push(f);
    });

    Object.entries(categories).forEach(([cat, items]) => {
      console.log(`   ${cat}: ${items.length} items`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkR2();
