const fs = require('fs');
const readline = require('readline');
const path = require('path');

const inputFile = path.join(__dirname, '../supabase-migration.sql');
const outputFile = path.join(__dirname, '../migration-inserts.sql');

async function convert() {
  console.log('🔄 Converting COPY to INSERT...');

  const fileStream = fs.createReadStream(inputFile);
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });

  const outStream = fs.createWriteStream(outputFile);

  let isCopyMode = false;
  let insertPrefix = '';
  let columns = [];
  let tableName = '';

  for await (let line of rl) {
    if (isCopyMode) {
      if (line.trim() === '\\.') {
        isCopyMode = false;
        outStream.write('-- End of Data\n\n');
        continue;
      }

      // Parse data line
      // Format: text (tab separated, \N is null)
      // We need to escape values and quote strings
      const values = line.split('\t').map(val => {
        if (val === '\\N') return 'NULL';
        // Check if number
        if (!isNaN(val) && val.trim() !== '') return val;
        // Check if boolean
        if (val === 't') return 'TRUE';
        if (val === 'f') return 'FALSE';
        // Assume string/json - escape single quotes
        return `'${val.replace(/'/g, "''")}'`;
      });

      const insertStmt = `${insertPrefix} (${values.join(', ')});\n`;
      outStream.write(insertStmt);

    } else {
        // Rewrite schema
        line = line.replace(/public\./g, 'project_management_tool.');

      if (line.startsWith('COPY ')) {
        // Parse COPY command to get table and columns
        // COPY public.action (id, card_id, ...) FROM stdin;
        const match = line.match(/COPY ([\w\._]+) \((.+)\) FROM stdin;/);
        if (match) {
          tableName = match[1];
          // ensure schema if missing in regex match (handled by replace above)
          columns = match[2].split(',').map(c => c.trim());
          insertPrefix = `INSERT INTO ${tableName} (${columns.join(', ')}) VALUES`;

          isCopyMode = true;
          outStream.write(`\n-- Converted data for ${tableName}\n`);
        } else {
          // Fallback or error?
          console.warn('⚠️  Could not parse COPY line:', line);
          outStream.write(`-- SKIPPED COPY: ${line}\n`);
        }
      } else {
        // Regular SQL
        outStream.write(line + '\n');
      }
    }
  }

  outStream.end();
  console.log(`✅ Conversion complete: ${outputFile}`);
}

convert();
