const fs = require('fs');
const path = require('path');

const backupPath = '/Users/sirasasitorn/Desktop/turfmapp-backups/backup_20260121_063414.sql';
const outputPath = '/Users/sirasasitorn/Documents/VScode/turfmapp/supabase-migration.sql';

console.log('Reading backup file...');
let content = fs.readFileSync(backupPath, 'utf8');

console.log('Processing SQL backup...');

// Replace all schema references from public to project_management_tool
content = content.replace(/SCHEMA public/g, 'SCHEMA project_management_tool');
content = content.replace(/public\./g, 'project_management_tool.');
content = content.replace(/search_path = public/g, 'search_path = project_management_tool');

// Add schema creation at the beginning if not exists
const schemaSetup = `-- Migration script for Supabase
-- Generated from production backup: backup_20260121_063414.sql

-- Set schema to project_management_tool
SET search_path TO project_management_tool, public;

-- Ensure schema exists
CREATE SCHEMA IF NOT EXISTS project_management_tool;

`;

// Remove restrictive commands that might cause issues
content = content.replace(/\\restrict.*\n/g, '');
content = content.replace(/SET statement_timeout = 0;/g, '');
content = content.replace(/SET lock_timeout = 0;/g, '');
content = content.replace(/SET idle_in_transaction_session_timeout = 0;/g, '');
content = content.replace(/SELECT pg_catalog\.set_config\('search_path', '', false\);/g, '');

// Remove owner assignments that might fail
content = content.replace(/ALTER .* OWNER TO .*;/g, '');

// Remove schema comments that might fail
content = content.replace(/COMMENT ON SCHEMA project_management_tool IS '';/g, '');

// Add SET search_path after the encoding setup
const lines = content.split('\n');
const processedLines = [];
let addedSearchPath = false;

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];

  // Add search path after the encoding settings
  if (!addedSearchPath && line.includes('SET client_encoding')) {
    processedLines.push(line);
    processedLines.push('SET search_path TO project_management_tool, public;');
    addedSearchPath = true;
  } else {
    processedLines.push(line);
  }
}

content = schemaSetup + processedLines.join('\n');

// Write the modified SQL
console.log('Writing migration file...');
fs.writeFileSync(outputPath, content, 'utf8');

console.log('\n✅ Migration file created successfully!');
console.log(`📄 Location: ${outputPath}`);
console.log('\nNext steps:');
console.log('1. Review the migration file if needed');
console.log('2. Run: node migrate-to-supabase.js');
console.log('   This will execute the migration against your Supabase database');
