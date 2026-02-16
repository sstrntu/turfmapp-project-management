#!/bin/bash

# Migration script using psql for better compatibility
# This handles COPY commands and large data imports better than pg client

CONNECTION_STRING="postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres"
MIGRATION_FILE="/Users/sirasasitorn/Documents/VScode/turfmapp/supabase-migration.sql"

echo "🔌 Connecting to Supabase..."
echo "   Host: aws-1-ap-southeast-1.pooler.supabase.com"
echo "   Schema: project_management_tool"
echo ""

echo "🗑️  Cleaning existing data..."
psql "$CONNECTION_STRING" -c "DROP SCHEMA IF EXISTS project_management_tool CASCADE;" 2>&1
if [ $? -eq 0 ]; then
  echo "   ✓ Dropped existing schema"
else
  echo "   ⚠ Schema may not have existed (this is OK)"
fi

psql "$CONNECTION_STRING" -c "CREATE SCHEMA project_management_tool;" 2>&1
if [ $? -eq 0 ]; then
  echo "   ✓ Created fresh schema"
  echo ""
else
  echo "   ✗ Failed to create schema"
  exit 1
fi

echo "🚀 Executing migration (this may take a moment)..."
echo ""

psql "$CONNECTION_STRING" -f "$MIGRATION_FILE" 2>&1

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Migration executed successfully!"
  echo ""

  echo "🔍 Verifying migration..."

  TABLE_COUNT=$(psql "$CONNECTION_STRING" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'project_management_tool';")
  echo "   ✓ Tables created: $TABLE_COUNT"

  USER_COUNT=$(psql "$CONNECTION_STRING" -t -c "SELECT COUNT(*) FROM project_management_tool.user_account;")
  echo "   ✓ Users migrated: $USER_COUNT"

  PROJECT_COUNT=$(psql "$CONNECTION_STRING" -t -c "SELECT COUNT(*) FROM project_management_tool.project;")
  echo "   ✓ Projects migrated: $PROJECT_COUNT"

  CARD_COUNT=$(psql "$CONNECTION_STRING" -t -c "SELECT COUNT(*) FROM project_management_tool.card;")
  echo "   ✓ Cards migrated: $CARD_COUNT"

  echo ""
  echo "🎉 Migration completed successfully!"
  echo ""
  echo "Next steps:"
  echo "1. Test your application connection"
  echo "2. Migrate attachment files if needed"
  echo "3. Verify all data is accessible"
  echo ""
else
  echo ""
  echo "❌ Migration failed!"
  echo "Check the error messages above for details."
  exit 1
fi
