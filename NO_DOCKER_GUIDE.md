# ?? Running Wallet Service WITHOUT Docker

## Why Skip Docker?

You might prefer not to use Docker if you:
- Want to learn how services work natively
- Already have PostgreSQL, Redis, and Kafka installed
- Have limited system resources
- Prefer direct control over each service
- Are on a system where Docker is restricted

**Good news:** The Wallet Service works perfectly without Docker! ?

---

## ?? What You'll Need

Instead of Docker running everything, you'll install these services directly:

1. **PostgreSQL** (Database)
2. **Redis** (Cache)
3. **Kafka** (Message Queue)
4. **.NET 9 SDK** (Application Runtime)

---

## ?? Complete No-Docker Setup

### Step 1: Install PostgreSQL

**Windows:**
```powershell
# Download from: https://www.postgresql.org/download/windows/
# Or use Chocolatey:
choco install postgresql

# Start PostgreSQL service
net start postgresql-x64-14

# Or through Services app: Win+R ? services.msc ? PostgreSQL ? Start
```

**Verify:**
```cmd
psql --version
# Should show: psql (PostgreSQL) 14.x
```

**Create Database:**
```cmd
# Connect as postgres user
psql -U postgres

# Create database and user
CREATE DATABASE wallet;
CREATE USER gameuser WITH PASSWORD 'gamepass123';
GRANT ALL PRIVILEGES ON DATABASE wallet TO gameuser;
\q

# Run schema
psql -U gameuser -d wallet -f database/schema.sql
```

---

### Step 2: Install Redis

**Windows:**
```powershell
# Download from: https://github.com/microsoftarchive/redis/releases
# Or use Chocolatey:
choco install redis-64

# Start Redis
redis-server

# Or install as Windows service:
redis-server --service-install
redis-server --service-start
```

**Verify:**
```cmd
redis-cli ping
# Should return: PONG
```

---

### Step 3: Install Kafka

**Windows/Mac/Linux:**

1. **Download Kafka:**
   ```cmd
   # Download from: https://kafka.apache.org/downloads
   # Extract to C:\kafka (or any folder)
   ```

2. **Start Zookeeper (Required for Kafka):**
   ```cmd
   cd C:\kafka
   
   # Windows:
   bin\windows\zookeeper-server-start.bat config\zookeeper.properties
   
   # Mac/Linux:
   bin/zookeeper-server-start.sh config/zookeeper.properties
   ```

3. **Start Kafka (in new terminal):**
   ```cmd
   cd C:\kafka
   
   # Windows:
   bin\windows\kafka-server-start.bat config\server.properties
   
   # Mac/Linux:
   bin/kafka-server-start.sh config/server.properties
   ```

4. **Create Topics:**
   ```cmd
   # Create wallet-topup-requests topic
   bin\windows\kafka-topics.bat --create ^
     --bootstrap-server localhost:9092 ^
     --topic wallet-topup-requests ^
     --partitions 12 ^
     --replication-factor 1
   
   # Create wallet-events topic
   bin\windows\kafka-topics.bat --create ^
     --bootstrap-server localhost:9092 ^
     --topic wallet-events ^
     --partitions 12 ^
     --replication-factor 1
   ```

**Verify:**
```cmd
bin\windows\kafka-topics.bat --list --bootstrap-server localhost:9092
# Should show both topics
```

---

### Step 4: Install .NET 9 SDK

```cmd
# Download from: https://dotnet.microsoft.com/download/dotnet/9.0

# Verify:
dotnet --version
# Should show: 9.0.x
```

---

## ? Your Configuration is Already Set!

Good news! Your `appsettings.json` files are already configured for local (non-Docker) services:

**src/Wallet.Api/appsettings.json:**
```json
{
  "ConnectionStrings": {
    "PostgreSQL": "Host=localhost;Port=5432;Database=wallet;Username=gameuser;Password=gamepass123",
    "Redis": "localhost:6379"
  },
  "Kafka": {
    "BootstrapServers": "localhost:9092"
  }
}
```

**No changes needed!** ?

---

## ?? Starting the Wallet Service (No Docker)

### Terminal 1: PostgreSQL (if not running as service)
```cmd
# Should already be running as Windows service
# Check: services.msc ? PostgreSQL

# Or start manually:
pg_ctl -D "C:\Program Files\PostgreSQL\14\data" start
```

### Terminal 2: Redis (if not running as service)
```cmd
redis-server
```

### Terminal 3: Zookeeper
```cmd
cd C:\kafka
bin\windows\zookeeper-server-start.bat config\zookeeper.properties
```

### Terminal 4: Kafka
```cmd
cd C:\kafka
bin\windows\kafka-server-start.bat config\server.properties
```

### Terminal 5: Wallet API
```cmd
cd C:\Users\Filip\Desktop\WalletProject\src\Wallet.Api
dotnet run
```

### Terminal 6: Wallet Consumer
```cmd
cd C:\Users\Filip\Desktop\WalletProject\src\Wallet.Consumer
dotnet run
```

---

## ?? Create Helper Scripts for No-Docker Setup

Let me create scripts specifically for your no-Docker setup:

### start-services-no-docker.bat
```batch
@echo off
echo Starting services (No Docker)...

REM Check if services are already running
sc query | findstr "PostgreSQL" >nul
if %ERRORLEVEL% EQU 0 (
    echo PostgreSQL: Already running
) else (
    echo Starting PostgreSQL...
    net start postgresql-x64-14
)

sc query | findstr "Redis" >nul
if %ERRORLEVEL% EQU 0 (
    echo Redis: Already running
) else (
    echo Starting Redis...
    net start Redis
)

echo.
echo Services Status:
echo - PostgreSQL: Running on localhost:5432
echo - Redis: Running on localhost:6379
echo.
echo Kafka needs to be started manually:
echo 1. Terminal 1: cd C:\kafka ^&^& bin\windows\zookeeper-server-start.bat config\zookeeper.properties
echo 2. Terminal 2: cd C:\kafka ^&^& bin\windows\kafka-server-start.bat config\server.properties
echo.
pause
```

### start-api-and-consumer.bat
```batch
@echo off
echo Starting Wallet Service...

REM Start API in new window
start "Wallet API" cmd /k "cd /d %~dp0src\Wallet.Api && dotnet run"

REM Wait 5 seconds for API to start
timeout /t 5 /nobreak

REM Start Consumer in new window
start "Wallet Consumer" cmd /k "cd /d %~dp0src\Wallet.Consumer && dotnet run"

echo.
echo Services started in separate windows!
echo - API: http://localhost:5000
echo - Consumer: Listening for Kafka messages
echo.
pause
```

---

## ? Quick Start Guide (No Docker)

### First Time Setup:

1. **Install Everything:**
   ```cmd
   # Install PostgreSQL, Redis, Kafka, .NET 9
   # (See detailed steps above)
   ```

2. **Setup Database:**
   ```cmd
   psql -U postgres
   CREATE DATABASE wallet;
   CREATE USER gameuser WITH PASSWORD 'gamepass123';
   GRANT ALL PRIVILEGES ON DATABASE wallet TO gameuser;
   \q
   
   psql -U gameuser -d wallet -f database/schema.sql
   ```

3. **Create Kafka Topics:**
   ```cmd
   cd C:\kafka
   bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-topup-requests --partitions 12 --replication-factor 1
   bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-events --partitions 12 --replication-factor 1
   ```

### Daily Usage:

1. **Start Background Services:**
   ```cmd
   # PostgreSQL & Redis should auto-start (Windows services)
   # If not: net start postgresql-x64-14 && net start Redis
   
   # Start Kafka (2 terminals):
   # Terminal 1: Zookeeper
   cd C:\kafka
   bin\windows\zookeeper-server-start.bat config\zookeeper.properties
   
   # Terminal 2: Kafka
   cd C:\kafka
   bin\windows\kafka-server-start.bat config\server.properties
   ```

2. **Start Application:**
   ```cmd
   # Run start-api-and-consumer.bat
   # Or manually:
   
   # Terminal 3: API
   cd src\Wallet.Api
   dotnet run
   
   # Terminal 4: Consumer
   cd src\Wallet.Consumer
   dotnet run
   ```

3. **Test:**
   ```cmd
   curl http://localhost:5000/health
   ```

---

## ?? Docker vs No-Docker Comparison

| Aspect | With Docker | Without Docker |
|--------|-------------|----------------|
| **Setup Time** | 5 minutes | 30-60 minutes (first time) |
| **Daily Start** | 1 command | 4-6 terminals |
| **Resource Usage** | Higher (Docker overhead) | Lower (native) |
| **Learning** | Docker abstraction | Understand each service |
| **Control** | Less direct | Full control |
| **Portability** | Easier (same everywhere) | More complex |
| **Troubleshooting** | Docker logs | Direct logs |

---

## ?? Recommended Approach

### If You're Learning:
? **Use No-Docker** - Better understanding of how services work

### If You're Developing:
? **Use Docker** - Faster setup, easier management

### If You Have Docker Issues:
? **Use No-Docker** - No Docker dependency

### If You're Deploying:
?? **Use Docker** - Easier deployment and scaling

---

## ?? Service Check Commands (No Docker)

### Check PostgreSQL:
```cmd
psql -U gameuser -d wallet -c "SELECT COUNT(*) FROM Wallets;"
```

### Check Redis:
```cmd
redis-cli ping
```

### Check Kafka:
```cmd
cd C:\kafka
bin\windows\kafka-topics.bat --list --bootstrap-server localhost:9092
```

### Check API:
```cmd
curl http://localhost:5000/health
```

---

## ?? Troubleshooting No-Docker Setup

### PostgreSQL Won't Start:
```cmd
# Check Windows services
services.msc

# Or command line:
sc query postgresql-x64-14

# Restart:
net stop postgresql-x64-14
net start postgresql-x64-14
```

### Redis Connection Failed:
```cmd
# Check if running:
redis-cli ping

# If not, start:
redis-server

# Or as service:
net start Redis
```

### Kafka Issues:
```cmd
# Check Zookeeper is running first
netstat -ano | findstr :2181

# Check Kafka
netstat -ano | findstr :9092

# Restart both if needed
```

### Port Conflicts:
```cmd
# Find what's using a port:
netstat -ano | findstr :5432  # PostgreSQL
netstat -ano | findstr :6379  # Redis
netstat -ano | findstr :9092  # Kafka

# Kill process:
taskkill /PID <PID> /F
```

---

## ?? Pro Tips for No-Docker Setup

1. **Install Services as Windows Services:**
   - PostgreSQL: Installs as service by default ?
   - Redis: Use `redis-server --service-install` ?
   - Kafka: No native Windows service (needs terminals)

2. **Create Shortcuts:**
   - Desktop shortcuts to start Zookeeper & Kafka
   - Taskbar pins for quick access

3. **Use Windows Terminal:**
   - Open all terminals in one window
   - Split panes for better view

4. **Auto-Start on Boot:**
   - PostgreSQL & Redis: Set to auto-start in services.msc
   - Kafka: Create startup script in Task Scheduler

5. **Monitor Resources:**
   - Task Manager ? Performance
   - See actual resource usage (no Docker overhead)

---

## ?? Summary

**You already have everything configured for no-Docker!** ?

Your `appsettings.json` files point to `localhost`, which works perfectly with locally installed services.

**Steps to use no-Docker:**
1. Install PostgreSQL, Redis, Kafka locally
2. Setup database with `schema.sql`
3. Create Kafka topics
4. Start services (4-6 terminals)
5. Run API and Consumer

**Documentation that helps:**
- ? [MANUAL_TESTING.md](docs/MANUAL_TESTING.md) - Complete no-Docker guide
- ? Your current `appsettings.json` - Already configured!
- ? [SETUP_GUIDE_BEGINNERS.md](SETUP_GUIDE_BEGINNERS.md) - Includes no-Docker steps

---

## ?? Quick Decision Guide

**Choose Docker if:**
- You want fast setup (5 min)
- You're okay with Docker Desktop
- You want easy cleanup

**Choose No-Docker if:**
- You want to learn how services work
- You already have services installed
- You have limited resources
- Docker is restricted on your system

**Both work perfectly!** Your code supports both approaches. ?

---

## ?? Ready to Go?

Follow the detailed no-Docker setup in: [MANUAL_TESTING.md](docs/MANUAL_TESTING.md)

Or use Docker with: [QUICKSTART.md](QUICKSTART.md)

**Your choice!** Both approaches are fully supported and documented. ?
