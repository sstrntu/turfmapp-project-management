const fs = require('fs');

const backupPath = '/Users/sirasasitorn/Desktop/turfmapp-backups/backup_20260121_063414.sql';
const outputPath = '/Users/sirasasitorn/Documents/VScode/turfmapp/supabase-restore.sql';

console.log('📖 Reading backup file...');
let content = fs.readFileSync(backupPath, 'utf8');

console.log('🔄 Converting schema from public to project_management_tool...\n');

// Replace schema references
content = content.replace(/SCHEMA public/g, 'SCHEMA project_management_tool');
content = content.replace(/public\./g, 'project_management_tool.');
content = content.replace(/SET search_path = public/g, 'SET search_path = project_management_tool');

// Remove restrictive commands
content = content.replace(/\\restrict.*\n/g, '');
content = content.replace(/ALTER .* OWNER TO .*;/g, '');
content = content.replace(/COMMENT ON SCHEMA .* IS '';/g, '');

// Add header
const header = `-- Supabase Migration Script
-- Generated from: backup_20260121_063414.sql
-- Target schema: project_management_tool

-- Create schema
CREATE SCHEMA IF NOT EXISTS project_management_tool;

-- Set search path
SET search_path TO project_management_tool, public;

`;

content = header + content;

console.log('💾 Writing Supabase-ready SQL file...');
fs.writeFileSync(outputPath, content, 'utf8');

const stats = fs.statSync(outputPath);
console.log(`\n✅ Created: ${outputPath}`);
console.log(`   Size: ${(stats.size / 1024).toFixed(1)} KB`);
console.log(`   Lines: ${content.split('\n').length.toLocaleString()}`);

console.log('\n📋 Next Steps:');
console.log('═'.repeat(60));
console.log('\n1. Open Supabase SQL Editor:');
console.log('   https://supabase.com/dashboard → Your Project → SQL Editor\n');
console.log('2. Drop existing schema (run this first):');
console.log('   DROP SCHEMA IF EXISTS project_management_tool CASCADE;');
console.log('   CREATE SCHEMA project_management_tool;\n');
console.log('3. Copy the entire contents of:');
console.log(`   ${outputPath}`);
console.log('\n4. Paste into SQL Editor and click "Run"\n');
console.log('5. Wait for completion (may take 1-2 minutes)\n');
console.log('═'.repeat(60));
console.log('\n✨ The SQL file is ready for Supabase!\n');
