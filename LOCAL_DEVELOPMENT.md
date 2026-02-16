# Running TURFMAPP Locally (Development Mode)

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn

## Setup Steps

### 1. Navigate to Server Directory

```bash
cd server
```

### 2. Install Dependencies (if not already installed)

```bash
npm install
```

### 3. Create Environment File

Create a `.env` file in the `server/` directory:

```bash
cp .env.sample .env
```

Then edit `server/.env` with these settings:

```env
# Base URL for your local development
BASE_URL=http://localhost:1337

# Supabase Database Connection
DATABASE_URL=postgresql://postgres.pwxhgvuyaxgavommtqpr:Tzt0bkistz7Hi2af@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres?options=-c%20search_path%3Dproject_management_tool%2Cpublic

# Secret key (use the same one from docker-compose.yml)
SECRET_KEY=NL6mKqSUrjwmvN2ew0xlEHysFft6R2pQNPTduKJXhxuJ9TfMKtcQ2oBsPNXu

# Trust proxy for local development
TRUST_PROXY=0

# SSL Configuration
KNEX_REJECT_UNAUTHORIZED_SSL_CERTIFICATE=false
NODE_TLS_REJECT_UNAUTHORIZED=0

# Default Admin (optional - only needed for first-time setup)
DEFAULT_ADMIN_EMAIL=admin@turfmapp.com
DEFAULT_ADMIN_PASSWORD=admin123
DEFAULT_ADMIN_NAME=Admin User
DEFAULT_ADMIN_USERNAME=admin
```

### 4. Run Database Migrations (Optional)

If you need to run migrations:

```bash
npm run db:migrate
```

**Note:** Since you've already migrated data to Supabase, you may not need this step.

### 5. Start the Application

**Development mode with auto-reload:**
```bash
npm start
```

**Production mode:**
```bash
npm run start:prod
```

The application will start on: **http://localhost:1337**

## Accessing the Application

- **Frontend**: http://localhost:1337
- **API**: http://localhost:1337/api

## Testing the Connection

Test if the API is working:

```bash
curl http://localhost:1337/api/users/me
```

You should get:
```json
{"code":"E_UNAUTHORIZED","message":"Access token is missing, invalid or expired"}
```

This means the API is working correctly!

## Stopping the Application

Press `Ctrl + C` in the terminal where the app is running.

---

## Current Setup (Docker vs Local)

### Docker (Production-like)
- Port: **9000** → Container port 1337
- Command: `docker compose up -d`
- Logs: `docker logs -f turfmapp-server`

### Local Development
- Port: **1337** (default)
- Command: `cd server && npm start`
- Direct access to code for development

---

## Troubleshooting

### Port Already in Use

If port 1337 is in use, you can change it by setting:

```env
PORT=3000
```

Or run on a different port:
```bash
PORT=3000 npm start
```

### Database Connection Issues

Make sure:
1. Your Supabase database is accessible
2. The search_path parameter is in the DATABASE_URL
3. SSL settings are configured (NODE_TLS_REJECT_UNAUTHORIZED=0)

### Files and Uploads

For local development, uploaded files will be stored in:
- `server/public/user-avatars/`
- `server/public/project-background-images/`
- `server/private/attachments/`

Make sure these directories exist or the app will create them automatically.

---

## Development Tips

1. **Auto-reload**: Use `npm start` (uses nodemon) for automatic restarts when you edit code

2. **Database Console**:
   ```bash
   npm run console
   ```

3. **Linting**:
   ```bash
   npm run lint
   ```

4. **Running Tests**:
   ```bash
   npm test
   ```

---

## Switching Between Docker and Local

**Stop Docker:**
```bash
docker compose down
```

**Start Local:**
```bash
cd server && npm start
```

**Note:** Both use the same Supabase database, so your data is consistent across both environments!
