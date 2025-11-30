# ?? Daily Workflow Without Docker

**Quick reference for running Wallet Service without Docker**

---

## ? Super Quick Start (if services already installed)

### 1. Start Background Services

**If installed as Windows services (automatic):**
```cmd
# PostgreSQL and Redis should auto-start
# Just check they're running:
check-no-docker-services.bat
```

**If Kafka needs manual start:**
```cmd
# Terminal 1 - Zookeeper:
cd C:\kafka
bin\windows\zookeeper-server-start.bat config\zookeeper.properties

# Terminal 2 - Kafka:
cd C:\kafka
bin\windows\kafka-server-start.bat config\server.properties
```

### 2. Start Wallet Service

**Option A - Automated:**
```cmd
start-api-and-consumer-no-docker.bat
```

**Option B - Manual:**
```cmd
# Terminal 3 - API:
cd src\Wallet.Api
dotnet run

# Terminal 4 - Consumer:
cd src\Wallet.Consumer
dotnet run
```

### 3. Test
```cmd
curl http://localhost:5000/health
```

---

## ?? Detailed Daily Startup

### Morning Routine (First Start of the Day)

**Step 1: Verify Services (30 seconds)**
```cmd
check-no-docker-services.bat
```

**Step 2: Start What's Not Running**

**PostgreSQL:**
```cmd
# Check:
sc query | findstr postgresql

# Start if needed:
net start postgresql-x64-14
```

**Redis:**
```cmd
# Check:
redis-cli ping

# Start if needed (if not a service):
redis-server

# Or as service:
net start Redis
```

**Kafka (always manual):**
```cmd
# Terminal 1 - Zookeeper:
cd C:\kafka
bin\windows\zookeeper-server-start.bat config\zookeeper.properties

# Terminal 2 - Kafka (wait 10 seconds after Zookeeper):
cd C:\kafka
bin\windows\kafka-server-start.bat config\server.properties
```

**Step 3: Start Wallet Service (5 seconds)**
```cmd
start-api-and-consumer-no-docker.bat
```

**Step 4: Verify Everything Works**
```cmd
# Health check:
curl http://localhost:5000/health

# Test top-up:
curl -X POST http://localhost:5000/wallet/topup ^
  -H "Content-Type: application/json" ^
  -d "{\"playerId\":\"test-001\",\"amount\":100.0,\"externalRef\":\"test-ref-001\"}"
```

**Total time: ~2 minutes** ?

---

## ?? Development Workflow

### Making Code Changes

1. **Keep services running** (PostgreSQL, Redis, Kafka)
2. **Stop API/Consumer** (Ctrl+C in their windows)
3. **Make your changes**
4. **Restart:**
   ```cmd
   start-api-and-consumer-no-docker.bat
   ```

**No need to restart PostgreSQL, Redis, or Kafka!** ?

---

## ?? Stopping Everything

### End of Day Shutdown

**Step 1: Stop Wallet Service**
```cmd
# Close the API and Consumer terminal windows
# Or press Ctrl+C in each
```

**Step 2: Stop Kafka**
```cmd
# In Kafka terminal: Ctrl+C
# In Zookeeper terminal: Ctrl+C
```

**Step 3: Keep Services Running (Recommended)**
```cmd
# Leave PostgreSQL and Redis running
# They use minimal resources when idle
```

**Optional - Stop Everything:**
```cmd
net stop Redis
net stop postgresql-x64-14
```

---

## ??? Windows Setup (One-Time Configuration)

### Make Services Auto-Start on Boot

**PostgreSQL (usually default):**
```cmd
# Check:
sc qc postgresql-x64-14

# Set to auto-start:
sc config postgresql-x64-14 start=auto
```

**Redis:**
```cmd
# Install as service:
redis-server --service-install

# Set to auto-start:
redis-server --service-start
sc config Redis start=auto
```

**Kafka (can't auto-start easily):**
- Create desktop shortcuts for Zookeeper and Kafka
- Or use Task Scheduler (advanced)

---

## ?? Windows Terminal Setup (Recommended)

### Create a Profile for Wallet Service

**Windows Terminal settings.json:**
```json
{
  "profiles": {
    "list": [
      {
        "name": "Zookeeper",
        "commandline": "cmd.exe /k \"cd C:\\kafka && bin\\windows\\zookeeper-server-start.bat config\\zookeeper.properties\"",
        "icon": "??"
      },
      {
        "name": "Kafka",
        "commandline": "cmd.exe /k \"cd C:\\kafka && bin\\windows\\kafka-server-start.bat config\\server.properties\"",
        "icon": "??"
      },
      {
        "name": "Wallet API",
        "commandline": "cmd.exe /k \"cd C:\\Users\\Filip\\Desktop\\WalletProject\\src\\Wallet.Api && dotnet run\"",
        "icon": "??"
      },
      {
        "name": "Wallet Consumer",
        "commandline": "cmd.exe /k \"cd C:\\Users\\Filip\\Desktop\\WalletProject\\src\\Wallet.Consumer && dotnet run\"",
        "icon": "??"
      }
    ]
  }
}
```

**Then:**
1. Open Windows Terminal
2. Open 4 tabs (Ctrl+Shift+T)
3. Select profile for each tab
4. Done! ?

---

## ?? Quick Commands Reference

### Check Status
```cmd
# All services:
check-no-docker-services.bat

# PostgreSQL:
psql -U gameuser -d wallet -c "SELECT 1"

# Redis:
redis-cli ping

# Kafka topics:
cd C:\kafka && bin\windows\kafka-topics.bat --list --bootstrap-server localhost:9092

# API:
curl http://localhost:5000/health
```

### Start Services
```cmd
# PostgreSQL:
net start postgresql-x64-14

# Redis:
net start Redis
# Or: redis-server

# Kafka:
# See startup section above

# Wallet Service:
start-api-and-consumer-no-docker.bat
```

### Stop Services
```cmd
# PostgreSQL:
net stop postgresql-x64-14

# Redis:
net stop Redis

# Kafka:
# Ctrl+C in terminal windows

# Wallet Service:
# Ctrl+C in terminal windows
```

---

## ?? Common Issues

### Issue: PostgreSQL won't start

**Solution:**
```cmd
# Check logs:
notepad "C:\Program Files\PostgreSQL\14\data\log\postgresql-*.log"

# Or restart:
net stop postgresql-x64-14
net start postgresql-x64-14
```

### Issue: Redis connection refused

**Solution:**
```cmd
# Start Redis:
redis-server

# Or as service:
redis-server --service-start
```

### Issue: Kafka won't start

**Solution:**
```cmd
# Make sure Zookeeper started first
# Wait 10-15 seconds after starting Zookeeper
# Then start Kafka

# Check ports:
netstat -ano | findstr :2181  # Zookeeper
netstat -ano | findstr :9092  # Kafka
```

### Issue: API port 5000 in use

**Solution:**
```cmd
# Find what's using it:
netstat -ano | findstr :5000

# Kill that process:
taskkill /PID <PID> /F

# Or change port in appsettings.json
```

---

## ?? Resource Usage (No Docker)

Typical resource usage on Windows:

| Service | RAM Usage | CPU Usage (idle) |
|---------|-----------|------------------|
| PostgreSQL | ~50 MB | <1% |
| Redis | ~5 MB | <1% |
| Zookeeper | ~100 MB | <1% |
| Kafka | ~150 MB | <1% |
| Wallet API | ~80 MB | <1% |
| Wallet Consumer | ~80 MB | <1% |
| **Total** | **~465 MB** | **<5%** |

**Compare to Docker:**
- Docker Desktop: ~2 GB just for Docker
- Total with Docker: ~2.5-3 GB

**No-Docker uses 6x less memory!** ?

---

## ?? Pro Tips

1. **Create Desktop Shortcuts:**
   - Right-click desktop ? New ? Shortcut
   - Point to `.bat` files
   - Rename for clarity

2. **Use Task Manager:**
   - Pin to taskbar
   - Monitor resource usage
   - Quick kill if needed

3. **Keep PostgreSQL & Redis Running:**
   - They use almost no resources when idle
   - Faster startup next time

4. **Bookmark Health Check:**
   - Browser bookmark: http://localhost:5000/health
   - Quick way to check if API is up

5. **Learn the Services:**
   - No Docker = better understanding
   - Direct control over each component
   - Easier troubleshooting

---

## ?? Learning Benefits

Running without Docker teaches you:

- ? How PostgreSQL works
- ? How Redis works  
- ? How Kafka works
- ? Network port management
- ? Windows services
- ? Process management
- ? Resource monitoring

**Better understanding = Better developer!** ??

---

## ?? Checklist for New Day

**Morning (2 minutes):**
- [ ] Run `check-no-docker-services.bat`
- [ ] Start Kafka if not running (2 terminals)
- [ ] Run `start-api-and-consumer-no-docker.bat`
- [ ] Test: `curl http://localhost:5000/health`

**During Work:**
- [ ] Keep services running
- [ ] Restart only API/Consumer when making code changes

**Evening:**
- [ ] Stop API/Consumer (Ctrl+C)
- [ ] Stop Kafka (Ctrl+C)
- [ ] Leave PostgreSQL & Redis running (optional)

---

## ?? When to Use Docker Instead

**Use Docker if:**
- ? You're tired of managing 4-6 terminal windows
- ? Setup takes too long each time
- ? You want easier cleanup
- ? You're deploying to production (Docker is better)

**Use No-Docker if:**
- ? You want to learn how services work
- ? You have limited RAM
- ? Docker is restricted on your system
- ? You prefer direct control

**Both work great!** Choose what fits your needs. ?

---

## ?? Summary

**No-Docker workflow:**
1. One-time: Install PostgreSQL, Redis, Kafka
2. First start: Check services ? Start Kafka ? Start Wallet Service (2 min)
3. Daily: Services auto-start ? Start Kafka ? Start Wallet Service (1 min)
4. Development: Keep services running, restart only API/Consumer

**Tools to help:**
- `check-no-docker-services.bat` - Check what's running
- `start-api-and-consumer-no-docker.bat` - Start Wallet Service
- [NO_DOCKER_GUIDE.md](NO_DOCKER_GUIDE.md) - Complete setup guide
- [docs/MANUAL_TESTING.md](docs/MANUAL_TESTING.md) - Detailed instructions

**You're all set for no-Docker development!** ??
