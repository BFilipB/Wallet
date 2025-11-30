# ?? Complete Setup Guide for Beginners

Welcome! This guide will help you set up and run the Wallet Service, even if you've never worked with .NET, Docker, or databases before.

---

## ?? What You'll Learn

By following this guide, you'll:
1. Install all required software
2. Set up the database
3. Start all services
4. Test that everything works

**Time Required:** 30-45 minutes (first time)

---

## ? Prerequisites Checklist

Before you start, you'll need to install these programs. Check the boxes as you complete each step:

- [ ] Windows 10 or 11 (64-bit)
- [ ] Administrator access on your computer
- [ ] At least 8GB of RAM
- [ ] At least 10GB of free disk space

---

## ?? Step 1: Install Required Software

### 1.1 Install .NET 9 SDK

**What is it?** The .NET SDK lets you run and build .NET applications.

**How to install:**

1. Go to: https://dotnet.microsoft.com/download/dotnet/9.0
2. Click **"Download .NET 9.0 SDK"** (the big blue button)
3. Run the downloaded installer
4. Click **Next** ? **Next** ? **Install**
5. Wait for installation to complete
6. Click **Finish**

**Verify it worked:**
1. Open **Command Prompt** (search for "cmd" in Start menu)
2. Type: `dotnet --version`
3. You should see something like: `9.0.x`

? If you see a version number, you're good to go!

---

### 1.2 Install Docker Desktop

**What is it?** Docker runs PostgreSQL, Redis, and Kafka in isolated containers (like virtual machines).

**How to install:**

1. Go to: https://www.docker.com/products/docker-desktop
2. Click **"Download for Windows"**
3. Run the downloaded installer
4. Click **OK** to use WSL 2 (default)
5. Wait for installation (this takes 5-10 minutes)
6. Restart your computer when prompted

**First-time setup:**
1. Open **Docker Desktop** from Start menu
2. Accept the service agreement
3. Skip the survey (or fill it out if you want)
4. Wait for Docker to start (you'll see a green whale icon in the system tray)

**Verify it worked:**
1. Open **Command Prompt**
2. Type: `docker --version`
3. You should see something like: `Docker version 24.x.x`

? If you see a version number, Docker is installed!

---

### 1.3 Install Git (Optional but Recommended)

**What is it?** Git helps you download and manage code.

**How to install:**

1. Go to: https://git-scm.com/download/win
2. Download the installer (64-bit recommended)
3. Run the installer
4. Click **Next** through all options (defaults are fine)
5. Click **Install** and wait
6. Click **Finish**

**Verify it worked:**
1. Open **Command Prompt**
2. Type: `git --version`
3. You should see something like: `git version 2.x.x`

? If you see a version number, Git is installed!

---

## ?? Step 2: Get the Code

You have two options:

### Option A: Using Git (Recommended)

1. Open **Command Prompt**
2. Navigate to where you want the project (e.g., Desktop):
   ```cmd
   cd Desktop
   ```
3. Clone the repository:
   ```cmd
   git clone https://github.com/BFilipB/Wallet.git
   ```
4. Go into the project folder:
   ```cmd
   cd Wallet
   ```

### Option B: Download ZIP

1. Go to: https://github.com/BFilipB/Wallet
2. Click the green **"Code"** button
3. Click **"Download ZIP"**
4. Extract the ZIP file to your Desktop
5. Open **Command Prompt** and navigate to the folder:
   ```cmd
   cd Desktop\Wallet-main
   ```

---

## ??? Step 3: Start the Database and Services

**What's happening?** This step starts PostgreSQL (database), Redis (cache), and Kafka (message queue) using Docker.

### 3.1 Start Docker Desktop

1. Open **Docker Desktop** from the Start menu
2. Wait until you see a green whale icon in the system tray
3. The bottom-left should say "Engine running"

? Docker is ready when the engine is running!

---

### 3.2 Start All Services

**Easy Way (Recommended):**

1. In the project folder, find and double-click: **`ultimate-lazy-setup.bat`**
2. A black window will open showing progress
3. Wait 2-3 minutes while everything starts
4. You'll see messages like "Creating network..." and "Creating wallet-postgres..."

**Manual Way:**

1. Open **Command Prompt** in the project folder
2. Type:
   ```cmd
   docker-compose up -d
   ```
3. Wait for all containers to start

**What's running?**
- PostgreSQL on port 5432 (database)
- Redis on port 6379 (cache)
- Kafka on port 9092 (messages)
- Zookeeper on port 2181 (Kafka helper)

---

### 3.3 Verify Services are Running

**Check in Docker Desktop:**
1. Open **Docker Desktop**
2. Click **"Containers"** on the left
3. You should see 4 containers running:
   - `wallet-postgres` (green)
   - `wallet-redis` (green)
   - `wallet-kafka` (green)
   - `wallet-zookeeper` (green)

**Check in Command Prompt:**
```cmd
docker ps
```

You should see all 4 containers listed.

? All services are running when you see 4 green containers!

---

## ??? Step 4: Set Up the Database

**What's happening?** This creates the tables and indexes that the application needs.

### 4.1 Run the Database Setup Script

**Easy Way:**
1. Double-click: **`setup-and-run.bat`**
2. Wait for "Database setup complete!" message

**Manual Way:**

1. Open **Command Prompt** in the project folder
2. Type:
   ```cmd
   docker exec -i wallet-postgres psql -U gameuser -d wallet -f /docker-entrypoint-initdb.d/schema.sql
   ```

**Alternative (if file path doesn't work):**
1. Copy the contents of `database/schema.sql`
2. Run:
   ```cmd
   docker exec -i wallet-postgres psql -U gameuser -d wallet
   ```
3. Paste the SQL content and press Enter

---

### 4.2 Verify Database Setup

**Check that tables were created:**

1. Connect to the database:
   ```cmd
   docker exec -it wallet-postgres psql -U gameuser -d wallet
   ```

2. List tables:
   ```sql
   \dt
   ```

3. You should see:
   - `wallets`
   - `wallettransactions`
   - `outbox`
   - `poisonmessages`

4. Exit:
   ```sql
   \q
   ```

? Database is ready when you see all 4 tables!

---

## ?? Step 5: Start the Application

### 5.1 Start the API

**What is it?** The API is the web service that handles wallet top-up requests.

1. Open a **new Command Prompt** window
2. Navigate to the API folder:
   ```cmd
   cd Desktop\Wallet\src\Wallet.Api
   ```
3. Start the API:
   ```cmd
   dotnet run
   ```
4. Wait for the message: **"Now listening on: http://localhost:5000"**

? Keep this window open! The API is running.

---

### 5.2 Start the Consumer

**What is it?** The Consumer processes wallet messages from Kafka.

1. Open **another new Command Prompt** window
2. Navigate to the Consumer folder:
   ```cmd
   cd Desktop\Wallet\src\Wallet.Consumer
   ```
3. Start the Consumer:
   ```cmd
   dotnet run
   ```
4. Wait for the message: **"Kafka consumer started. Listening for messages..."**

? Keep this window open! The Consumer is running.

---

## ?? Step 6: Test Everything Works

### 6.1 Health Check

**Check that the API is responding:**

**Using PowerShell:**
1. Open **PowerShell**
2. Run:
   ```powershell
   Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing
   ```
3. You should see: **"Healthy"**

**Using your browser:**
1. Open Chrome, Edge, or Firefox
2. Go to: http://localhost:5000/health
3. You should see: **"Healthy"**

? API is working if you see "Healthy"!

---

### 6.2 Test a Wallet Top-Up

**Send your first top-up request:**

**Using PowerShell:**
```powershell
$body = @{
    playerId = "player-001"
    amount = 100.00
    externalRef = "test-payment-001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" -Method Post -ContentType "application/json" -Body $body
```

**Expected response:**
```json
{
  "playerId": "player-001",
  "amount": 100.00,
  "newBalance": 100.00,
  "externalRef": "test-payment-001",
  "transactionId": "550e8400-e29b-41d4-a716-446655440000",
  "processedAt": "2024-01-15T10:30:00Z",
  "idempotent": false
}
```

? It works if you see a response with the player's new balance!

---

### 6.3 Check the Balance

**Query the player's balance:**

**Using PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/wallet/player-001/balance" -UseBasicParsing
```

**Using your browser:**
Go to: http://localhost:5000/wallet/player-001/balance

**Expected response:**
```json
{
  "playerId": "player-001",
  "balance": 100.00
}
```

? Balance is correct!

---

### 6.4 Test Idempotency

**Send the SAME request again:**

```powershell
$body = @{
    playerId = "player-001"
    amount = 100.00
    externalRef = "test-payment-001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" -Method Post -ContentType "application/json" -Body $body
```

**Expected response:**
```json
{
  "playerId": "player-001",
  "amount": 100.00,
  "newBalance": 100.00,
  "externalRef": "test-payment-001",
  "transactionId": "550e8400-e29b-41d4-a716-446655440000",
  "processedAt": "2024-01-15T10:30:00Z",
  "idempotent": true
}
```

**Notice:**
- Balance is still **100.00** (not 200.00!)
- `"idempotent": true` means it was already processed

? Idempotency works! Duplicate requests are safely ignored.

---

## ?? Success!

Congratulations! You now have a fully working wallet service!

**What you've accomplished:**
- ? Installed all required software
- ? Started database and services
- ? Ran the application
- ? Tested wallet top-ups
- ? Verified idempotency

---

## ?? What's Running?

Here's what you should have open:

| Window | What It Does | Port |
|--------|-------------|------|
| Docker Desktop | Runs PostgreSQL, Redis, Kafka | Multiple |
| Command Prompt #1 | API (receives requests) | 5000 |
| Command Prompt #2 | Consumer (processes messages) | - |

**Tip:** Don't close these windows while using the application!

---

## ?? How to Stop Everything

### Stop the Applications

1. In the API Command Prompt window, press **Ctrl+C**
2. In the Consumer Command Prompt window, press **Ctrl+C**
3. Wait for both to shut down gracefully

### Stop Docker Services

**Easy Way:**
1. Double-click: **`quick-stop.bat`**

**Manual Way:**
```cmd
docker-compose down
```

---

## ?? How to Start Again (Next Time)

**Quick Start (Everything):**
1. Open **Docker Desktop** (wait for it to start)
2. Double-click: **`quick-start.bat`**
3. Wait 1-2 minutes
4. Everything is running!

**Manual Start:**
1. Start Docker Desktop
2. Run: `docker-compose up -d`
3. Start API: `cd src\Wallet.Api && dotnet run`
4. Start Consumer: `cd src\Wallet.Consumer && dotnet run`

---

## ?? Troubleshooting

### Problem: "Docker is not running"

**Solution:**
1. Open **Docker Desktop**
2. Wait for the whale icon to turn green
3. Try again

---

### Problem: "Port 5000 is already in use"

**Solution:**
1. Find what's using the port:
   ```cmd
   netstat -ano | findstr :5000
   ```
2. Kill that process:
   ```cmd
   taskkill /PID <PID_NUMBER> /F
   ```
3. Start the API again

---

### Problem: "Cannot connect to PostgreSQL"

**Solution:**
1. Check Docker containers are running:
   ```cmd
   docker ps
   ```
2. Restart the database:
   ```cmd
   docker restart wallet-postgres
   ```
3. Wait 10 seconds and try again

---

### Problem: "Database tables not found"

**Solution:**
1. Run the setup script again:
   ```cmd
   docker exec -i wallet-postgres psql -U gameuser -d wallet < database/schema.sql
   ```
2. Verify tables exist:
   ```cmd
   docker exec -it wallet-postgres psql -U gameuser -d wallet -c "\dt"
   ```

---

### Problem: Build errors when starting API/Consumer

**Solution:**
1. Clean and rebuild:
   ```cmd
   dotnet clean
   dotnet build
   ```
2. If still failing, restore packages:
   ```cmd
   dotnet restore
   ```
3. Try starting again

---

## ?? Next Steps

Now that everything is working, you can:

1. **Explore the API:**
   - Try different top-up amounts
   - Create multiple players
   - Check transaction history

2. **Learn More:**
   - Read [QUICKSTART.md](QUICKSTART.md) for advanced usage
   - Read [docs/DESIGN_DECISIONS.md](docs/DESIGN_DECISIONS.md) to understand the architecture
   - Read [docs/MANUAL_TESTING.md](docs/MANUAL_TESTING.md) for more test scenarios

3. **Develop:**
   - Open the project in Visual Studio or VS Code
   - Make changes to the code
   - Restart the API/Consumer to see your changes

---

## ?? Understanding What You Built

### The Wallet Service

This is a **production-grade microservice** that:
- Processes wallet top-ups for players
- Prevents duplicate payments (idempotency)
- Handles 50,000+ transactions per minute
- Caches data in Redis for speed
- Publishes events to Kafka
- Monitors everything with OpenTelemetry

### The Components

| Component | Purpose |
|-----------|---------|
| **Wallet.Api** | REST API that receives requests |
| **Wallet.Consumer** | Background service that processes Kafka messages |
| **PostgreSQL** | Database that stores wallet data |
| **Redis** | Cache that speeds up reads |
| **Kafka** | Message queue for async events |

---

## ?? Tips for Success

1. **Always start Docker first** - Nothing works without it!
2. **Keep terminal windows open** - Closing them stops the service
3. **Check Docker Desktop** - It shows if containers are healthy
4. **Use the quick-start scripts** - They save time
5. **Read the logs** - They tell you what's happening

---

## ?? Need Help?

If you're stuck:

1. Check the [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)
2. Look at the error message carefully
3. Search for the error on Google
4. Check the GitHub Issues page

---

## ? Quick Reference

### Common Commands

```cmd
# Check .NET version
dotnet --version

# Check Docker version
docker --version

# See running containers
docker ps

# See all containers (including stopped)
docker ps -a

# View API logs
docker logs wallet-postgres

# Connect to database
docker exec -it wallet-postgres psql -U gameuser -d wallet

# Restart a container
docker restart wallet-postgres
```

### File Locations

```
WalletProject/
??? src/
?   ??? Wallet.Api/         ? REST API
?   ??? Wallet.Consumer/    ? Kafka consumer
?   ??? Wallet.Infrastructure/ ? Business logic
??? database/
?   ??? schema.sql          ? Database setup
??? docker-compose.yml      ? Docker configuration
??? quick-start.bat         ? Start everything
```

---

**You did it! Welcome to the world of microservices!** ??

For more detailed information, check out the [README.md](README.md) or the documentation in the `docs/` folder.
