#!/bin/bash

set -e  # Exit on error

CONN_STRING="postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres"
BACKUP_FILE="/Users/sirasasitorn/Desktop/turfmapp-backups/backup_20260121_063414.sql"
TEMP_FILE="/tmp/supabase-migration-$$.sql"

echo "🔌 Preparing migration..."

# Transform the SQL file
echo "📝 Transforming backup for Supabase..."
cat "$BACKUP_FILE" | \
  sed 's/SCHEMA public/SCHEMA project_management_tool/g' | \
  sed 's/public\./project_management_tool./g' | \
  sed 's/search_path = public/search_path = project_management_tool/g' | \
  sed '/^\\\\restrict/d' | \
  sed '/ALTER .* OWNER TO/d' > "$TEMP_FILE"

# Add schema setup at the beginning
cat > "/tmp/header-$$.sql" <<'EOF'
-- Drop and recreate schema
DROP SCHEMA IF EXISTS project_management_tool CASCADE;
CREATE SCHEMA project_management_tool;
SET search_path = project_management_tool, public;

EOF

cat "/tmp/header-$$.sql" "$TEMP_FILE" > "/tmp/final-migration-$$.sql"

echo "✅ Migration file prepared"
echo ""

# Run with psql
echo "🚀 Executing migration via psql..."
echo "   (This will take a few minutes)"
echo ""

PGOPTIONS='--client-min-messages=warning' psql "$CONN_STRING" -f "/tmp/final-migration-$$.sql" -v ON_ERROR_STOP=0 2>&1 | grep -v "^$" | head -100

# Verify
echo ""
echo "🔍 Verifying migration..."
psql "$CONN_STRING" -t -c "SELECT COUNT(*) || ' tables' FROM information_schema.tables WHERE table_schema = 'project_management_tool';"
psql "$CONN_STRING" -t -c "SELECT COUNT(*) || ' users' FROM project_management_tool.user_account;" 2>&1 | grep -v "does not exist" || echo "   ⚠️  user_account table not found"
psql "$CONN_STRING" -t -c "SELECT COUNT(*) || ' projects' FROM project_management_tool.project;" 2>&1 | grep -v "does not exist" || echo "   ⚠️  project table not found"

# Cleanup
rm -f "/tmp/header-$$.sql" "$TEMP_FILE" "/tmp/final-migration-$$.sql"

echo ""
echo "✅ Migration complete!"
