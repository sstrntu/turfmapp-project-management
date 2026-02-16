# 🐳 Complete Docker Setup

## ✅ Now Everything Runs with One Command!

```bash
docker compose up --build
```

That's it! This will start:
- ✅ **Frontend** (React) on http://localhost:3000
- ✅ **Backend** (API) on http://localhost:9000
- ✅ **Database** connection to Supabase

---

## 🚀 Quick Start

### Start Everything
```bash
docker compose up --build
```

### Start in Background (Detached)
```bash
docker compose up --build -d
```

### View Logs
```bash
# All services
docker compose logs -f

# Just frontend
docker compose logs -f turfmapp-client

# Just backend
docker compose logs -f turfmapp-server
```

### Stop Everything
```bash
docker compose down
```

---

## 📋 What Changed?

**Before:**
- ❌ Only backend in Docker
- ❌ Had to run frontend separately with `npm start`
- ❌ Two terminal windows needed

**After:**
- ✅ Both frontend and backend in Docker
- ✅ One command to start everything
- ✅ Single terminal window

---

## 🔧 Services Overview

### Frontend (turfmapp-client)
- **Container:** `turfmapp-client`
- **Port:** 3000
- **URL:** http://localhost:3000
- **Source:** `./client` directory
- **Hot Reload:** Enabled (code changes auto-refresh)

### Backend (turfmapp-server)
- **Container:** `turfmapp-server`
- **Port:** 9000 (maps to 1337 inside container)
- **URL:** http://localhost:9000
- **Source:** `./server` directory
- **Database:** Supabase (configured)

---

## 🌐 Access Points

| Service | URL |
|---------|-----|
| **Main App (Frontend)** | http://localhost:3000 |
| **API (Backend)** | http://localhost:9000 |
| **API Health Check** | http://localhost:9000/api/users/me |

---

## 🔄 Development Workflow

1. **Make code changes** in `./client` or `./server`
2. Changes are **automatically synced** to containers (via volumes)
3. **Frontend auto-reloads** (hot reload enabled)
4. **Backend** may need restart:
   ```bash
   docker compose restart turfmapp-server
   ```

---

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Stop any local services using ports 3000 or 9000
lsof -ti:3000 | xargs kill -9
lsof -ti:9000 | xargs kill -9

# Then restart
docker compose up --build
```

### Clean Rebuild
```bash
# Stop and remove everything
docker compose down -v

# Remove images
docker rmi turfmapp-client turfmapp-server:latest

# Rebuild from scratch
docker compose up --build
```

### View Container Status
```bash
docker compose ps
```

### Access Container Shell
```bash
# Frontend
docker exec -it turfmapp-client sh

# Backend
docker exec -it turfmapp-server sh
```

---

## 📦 File Structure

```
turfmapp/
├── client/                  # Frontend React app
│   ├── Dockerfile          # Frontend Docker config
│   ├── package.json
│   └── src/
├── server/                  # Backend API
│   ├── app.js
│   ├── package.json
│   └── api/
├── docker-compose.yml       # Both services defined here
└── DOCKER_SETUP.md         # This file
```

---

## 💡 Tips

1. **Always use `--build`** when starting to ensure latest code is used:
   ```bash
   docker compose up --build
   ```

2. **Use detached mode** (`-d`) for background running:
   ```bash
   docker compose up --build -d
   ```

3. **View real-time logs** while running in background:
   ```bash
   docker compose logs -f
   ```

4. **Restart individual services**:
   ```bash
   docker compose restart turfmapp-client
   docker compose restart turfmapp-server
   ```

---

## ✅ Verification

After starting with `docker compose up --build`, verify everything works:

1. **Check containers are running:**
   ```bash
   docker compose ps
   ```
   Should show both `turfmapp-client` and `turfmapp-server` as "Up"

2. **Access frontend:**
   Open http://localhost:3000

3. **Check backend API:**
   ```bash
   curl http://localhost:9000/api/users/me
   ```
   Should return: `{"code":"E_UNAUTHORIZED",...}` (means API is working)

4. **Try logging in:**
   Use credentials from your migrated database (e.g., `sira@turfmapp.com`)

---

## 🎉 You're All Set!

Now you can develop, test, and deploy everything using Docker!

```bash
docker compose up --build
```

Open http://localhost:3000 and start using TURFMAPP! 🚀
