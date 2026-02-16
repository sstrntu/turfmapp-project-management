const fs = require('fs');

console.log('📖 Reading migration file...');
const sql = fs.readFileSync('migration-inserts.sql', 'utf8');

const lines = sql.split('\n');
const schemaLines = [];
const dataLines = [];

let inInsertSection = false;

// First pass: separate schema DDL from data DML
for (let i = 0; i < lines.length; i++) {
  const line = lines[i];

  // Once we hit INSERT statements, everything after is data
  if (line.trim().startsWith('INSERT INTO')) {
    inInsertSection = true;
  }

  // Skip these in data section - they're schema setup
  if (line.includes('CREATE SEQUENCE') ||
      line.includes('ALTER TABLE') ||
      line.includes('ADD CONSTRAINT') ||
      line.includes('CREATE INDEX')) {
    inInsertSection = false;
  }

  if (inInsertSection) {
    dataLines.push(line);
  } else {
    schemaLines.push(line);
  }
}

// Write schema file
console.log('📝 Writing schema file...');
fs.writeFileSync('migration-schema.sql', schemaLines.join('\n'), 'utf8');

// Write data file
console.log('📝 Writing data file...');
fs.writeFileSync('migration-data.sql', dataLines.join('\n'), 'utf8');

console.log(`\n✅ Split complete!`);
console.log(`   Schema: migration-schema.sql (${schemaLines.length} lines)`);
console.log(`   Data: migration-data.sql (${dataLines.length} lines)`);
console.log('\n💡 Now run: node run-split-migration.js');
