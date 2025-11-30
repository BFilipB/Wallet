# ?? Quick Visual Setup Guide

**Perfect for:** People who prefer pictures and diagrams over text.

---

## ?? Setup Overview

```
Step 1: Install Software (20 mins)
    ?
Step 2: Download Code (2 mins)
    ?
Step 3: Start Services (3 mins)
    ?
Step 4: Setup Database (2 mins)
    ?
Step 5: Start Application (2 mins)
    ?
Step 6: Test (5 mins)
    ?
? DONE!
```

**Total Time:** 30-35 minutes

---

## ?? Step 1: Install Software

### 1.1 .NET 9 SDK

```
Visit: https://dotnet.microsoft.com/download/dotnet/9.0
    ?
Download SDK
    ?
Run Installer
    ?
Verify: dotnet --version
```

? **Success:** You see version `9.0.x`

---

### 1.2 Docker Desktop

```
Visit: https://www.docker.com/products/docker-desktop
    ?
Download for Windows
    ?
Run Installer
    ?
Restart Computer
    ?
Open Docker Desktop
    ?
Wait for green whale icon
```

? **Success:** Docker Desktop shows "Engine running"

---

## ?? Step 2: Get the Code

### Option A: Git Clone

```cmd
cd Desktop
git clone https://github.com/BFilipB/Wallet.git
cd Wallet
```

### Option B: Download ZIP

```
GitHub ? Code ? Download ZIP
    ?
Extract to Desktop
    ?
cd Desktop\Wallet-main
```

---

## ?? Step 3: Start Services

### The Easy Way

```
Double-click: ultimate-lazy-setup.bat
    ?
Wait 2-3 minutes
    ?
? All services running!
```

### What's Running?

| Service | Port | Purpose |
|---------|------|---------|
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Cache |
| Kafka | 9092 | Messages |
| Zookeeper | 2181 | Kafka helper |

---

## ??? Step 4: Setup Database

### Quick Method

```
Double-click: setup-and-run.bat
    ?
Wait for "Database setup complete!"
```

### What Was Created?

```
Database: wallet
    ??? Wallets table
    ??? WalletTransactions table
    ??? Outbox table
    ??? PoisonMessages table
```

---

## ?? Step 5: Start Application

### Terminal 1: API

```cmd
cd src\Wallet.Api
dotnet run
```

Wait for: **"Now listening on: http://localhost:5000"**

---

### Terminal 2: Consumer

```cmd
cd src\Wallet.Consumer
dotnet run
```

Wait for: **"Kafka consumer started. Listening for messages..."**

---

## ? Step 6: Test

### Health Check

**Browser:** Go to http://localhost:5000/health

**PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing
```

? **Success:** You see "Healthy"

---

### First Top-Up

**PowerShell:**
```powershell
$body = @{
    playerId = "player-001"
    amount = 100.00
    externalRef = "test-001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

**Expected Response:**
```json
{
  "playerId": "player-001",
  "amount": 100.00,
  "newBalance": 100.00,
  "idempotent": false
}
```

? **Success:** You see the balance!

---

### Check Balance

**Browser:** http://localhost:5000/wallet/player-001/balance

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/wallet/player-001/balance"
```

**Expected Response:**
```json
{
  "playerId": "player-001",
  "balance": 100.00
}
```

---

## ?? You're Done!

```
? Software installed
? Services running
? Database created
? Application started
? Tests passing

? You have a working wallet service!
```

---

## ?? System Status

### ? Healthy System

```
Docker Desktop: ? Green whale icon
PostgreSQL:     ? Running (green)
Redis:          ? Running (green)
Kafka:          ? Running (green)
Zookeeper:      ? Running (green)
API:            ? Listening on :5000
Consumer:       ? Listening for messages
```

---

## ?? Daily Usage

### Starting Everything

```
1. Open Docker Desktop
2. Double-click: quick-start.bat
3. Wait 1-2 minutes
4. ? Ready!
```

### Stopping Everything

```
1. Press Ctrl+C in API window
2. Press Ctrl+C in Consumer window
3. Double-click: quick-stop.bat
4. ? Stopped!
```

---

## ?? Quick Troubleshooting

### Problem: Docker not running

```
Solution:
  1. Open Docker Desktop
  2. Wait for green whale
  3. Try again
```

---

### Problem: Port 5000 in use

```
Solution:
  netstat -ano | findstr :5000
  taskkill /PID <NUMBER> /F
```

---

### Problem: Database connection failed

```
Solution:
  docker restart wallet-postgres
  Wait 10 seconds
  Try again
```

---

## ?? Project Structure

```
WalletProject/
??? src/
?   ??? Wallet.Api/          ? REST API (Port 5000)
?   ??? Wallet.Consumer/     ? Kafka Consumer
?   ??? Wallet.Infrastructure/ ? Business Logic
?   ??? Wallet.Shared/       ? Models
??? database/
?   ??? schema.sql           ? Database Setup
??? docs/                    ? Documentation
??? docker-compose.yml       ? Docker Config
??? quick-start.bat          ? Start All
??? quick-stop.bat           ? Stop All
??? ultimate-lazy-setup.bat  ? Full Setup
```

---

## ?? Key Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Check if API is alive |
| `/wallet/topup` | POST | Add money to wallet |
| `/wallet/{playerId}/balance` | GET | Get current balance |
| `/wallet/{playerId}/history` | GET | Get transaction history |
| `/admin/poison-messages` | GET | View failed messages |

---

## ?? Pro Tips

1. **Always start Docker first!**
2. Keep terminal windows open
3. Use the batch scripts (quick-start.bat, etc.)
4. Check Docker Desktop to see if containers are healthy
5. Read the error messages - they tell you what's wrong

---

## ?? What You Built

```
???????????????????????????????????????????
?           CLIENT REQUESTS               ?
?         (Browser / PowerShell)          ?
???????????????????????????????????????????
                ? HTTP
                ?
???????????????????????????????????????????
?          WALLET.API (Port 5000)         ?
?  ????????????      ???????????????     ?
?  ?Endpoints ? ???? ? TopUpService?     ?
?  ????????????      ???????????????     ?
???????????????????????????????????????????
     ?                  ?
     ?                  ?
????????????      ????????????
?PostgreSQL?      ?  Redis   ?
?(Database)?      ? (Cache)  ?
????????????      ????????????
     ?
????????????????????????????????????????
?    Outbox Table (Events)             ?
????????????????????????????????????????
       ? Published every 5 seconds
       ?
????????????????????????????????????????
?         Kafka (Message Queue)        ?
?       Topic: wallet-events           ?
????????????????????????????????????????
       ? Consumed by
       ?
????????????????????????????????????????
?      WALLET.CONSUMER                 ?
?   (Background Worker Service)        ?
?  Processes wallet-topup-requests     ?
????????????????????????????????????????
```

---

## ? Checklist: Am I Ready?

After setup, you should have:

- [x] Docker Desktop running (green whale)
- [x] 4 containers running (postgres, redis, kafka, zookeeper)
- [x] Database with 4 tables created
- [x] API running on port 5000
- [x] Consumer running and listening
- [x] Health check returns "Healthy"
- [x] Top-up request returns balance

**All checked?** ? You're ready to develop! ??

---

## ?? Next Steps

1. **Try More Requests:**
   - Create multiple players
   - Test different amounts
   - Check transaction history

2. **Learn the Code:**
   - Open in Visual Studio
   - Explore `Wallet.Api/Endpoints/`
   - Read `docs/DESIGN_DECISIONS.md`

3. **Make Changes:**
   - Modify an endpoint
   - Add validation rules
   - Test your changes

---

## ?? Additional Resources

- [SETUP_GUIDE_BEGINNERS.md](SETUP_GUIDE_BEGINNERS.md) - Detailed text guide
- [QUICKSTART.md](QUICKSTART.md) - 5-minute Docker guide
- [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md) - Common issues
- [README.md](README.md) - Project overview
- [docs/](docs/) - Technical documentation

---

**Congratulations! You've successfully set up a production-grade microservice!** ??
