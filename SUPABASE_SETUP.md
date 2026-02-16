# Supabase Setup Instructions

## ✅ Your Supabase Configuration

- **Host**: `db.pwxhgvuyaxgavommtqpr.supabase.co`
- **Database**: `postgres`
- **Schema**: `project_management_tool`
- **Connection String**: `postgresql://postgres:Tzt0bkistz7Hi2af@db.pwxhgvuyaxgavommtqpr.supabase.co:5432/postgres`

---

## 📋 Step 1: Run the SQL File in Supabase

### Option A: Using Supabase SQL Editor (Recommended)

1. Go to your Supabase project: https://supabase.com/dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**
4. Open the file: `supabase-schema.sql` (in your turfmapp directory)
5. Copy the entire contents (911 lines)
6. Paste into the Supabase SQL Editor
7. Click **Run** (or press Cmd/Ctrl + Enter)

### Option B: Using Command Line

```bash
cd /Users/sirasasitorn/Documents/VScode/turfmapp

psql "postgresql://postgres:Tzt0bkistz7Hi2af@db.pwxhgvuyaxgavommtqpr.supabase.co:5432/postgres" -f supabase-schema.sql
```

---

## ✅ Step 2: Verify the Schema

Run these queries in Supabase SQL Editor to verify:

```sql
-- Check schema exists
SELECT schema_name FROM information_schema.schemata
WHERE schema_name = 'project_management_tool';

-- Count tables (should be 17)
SELECT COUNT(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'project_management_tool';

-- Test ID generation
SELECT project_management_tool.next_id() as test_id;
```

Expected results:
- Schema: `project_management_tool` ✓
- Tables: `17` ✓
- Test ID: A large number (e.g., `9876543210123`) ✓

---

## 📝 Step 3: Update Application Configuration

### Update `docker-compose.yml`

Replace the database configuration:

```yaml
services:
  turfmapp-server:
    environment:
      # Update this line:
      - DATABASE_URL=postgresql://postgres:Tzt0bkistz7Hi2af@db.pwxhgvuyaxgavommtqpr.supabase.co:5432/postgres

      # Add this line:
      - KNEX_REJECT_UNAUTHORIZED_SSL_CERTIFICATE=false

      # Keep all other environment variables...

    # Remove these lines:
    # depends_on:
    #   postgres:
    #     condition: service_healthy

# Remove the entire postgres service section
# Remove db-data from volumes
```

### Update `server/db/knexfile.js`

Add these two lines:

```javascript
module.exports = {
  client: 'pg',
  connection: {
    connectionString: process.env.DATABASE_URL,
    ssl: buildSSLConfig(),
  },
  searchPath: ['project_management_tool', 'public'], // ADD THIS
  migrations: {
    tableName: 'migration',
    directory: path.join(__dirname, 'migrations'),
    schemaName: 'project_management_tool', // ADD THIS
  },
  // ... rest of config
};
```

### Update `server/config/datastores.js`

Add schema configuration:

```javascript
module.exports.datastores = {
  default: {
    adapter: 'sails-postgresql',
    url: process.env.DATABASE_URL,
    schema: true, // ADD THIS
    options: {  // ADD THIS
      searchPath: 'project_management_tool,public',
    },
  },
};
```

---

## 🚀 Step 4: Test the Application

```bash
cd /Users/sirasasitorn/Documents/VScode/turfmapp
docker-compose down
docker-compose up -d
docker logs -f turfmapp-server
```

Look for successful database connection messages!

---

## 📊 What Was Created

The SQL file created:

✅ **Schema**: `project_management_tool`
✅ **Tables**: 17 (user_account, project, board, list, card, task, etc.)
✅ **Function**: `next_id()` for ID generation
✅ **Sequences**: 3 (next_id_seq, migration_id_seq, migration_lock_index_seq)
✅ **Indexes**: 30+ for performance
✅ **Constraints**: All CHECK, UNIQUE, and EXCLUDE constraints

---

## 🔧 Troubleshooting

**If you get connection errors:**
- Verify your IP is allowed in Supabase Network settings
- Check that SSL is enabled in the connection string

**If you get "schema not found" errors:**
- Make sure the SQL file ran successfully
- Check that `searchPath` is set in both config files

**If you get "function not found" errors:**
- Verify the `next_id()` function was created
- Run the verification queries above

---

## 📁 File Location

The SQL file is ready at:
```
/Users/sirasasitorn/Documents/VScode/turfmapp/supabase-schema.sql
```

You can now run it in Supabase! 🎉
