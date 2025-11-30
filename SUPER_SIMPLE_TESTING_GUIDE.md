# ?? Super Simple Testing Guide - No Experience Needed!

**Don't worry if you've never done this before - just follow these steps exactly!** ?

---

## ?? Step 1: Check If Everything Is Installed (2 minutes)

Open **PowerShell** (search for it in Windows Start menu) and run:

```powershell
# Check these one by one:
dotnet --version
# Should show: 9.0.x - if you see this, ? you're good!

psql --version
# Should show PostgreSQL version - ? good!

redis-cli ping
# Should say: PONG - ? good!
```

**If any of these fail**, use the quick installer:
```powershell
# Run this (it installs everything):
.\ultimate-lazy-setup.bat
```

---

## ?? Step 2: Start Everything (3 easy steps!)

### Option A: Super Easy Way (Recommended) ?

Just double-click these files in order:

1. **`quick-start.bat`** - Starts all services (Docker)
2. **`start-api-and-consumer-no-docker.bat`** - Starts the application

Wait 1-2 minutes and you're done! ?

---

### Option B: Manual Way (if Docker doesn't work)

**Terminal 1 - Start Zookeeper:**
```cmd
cd C:\kafka
bin\windows\zookeeper-server-start.bat config\zookeeper.properties
```
*Leave this window open!*

**Terminal 2 - Start Kafka:**
```cmd
cd C:\kafka
bin\windows\kafka-server-start.bat config\server.properties
```
*Leave this window open!*

**Terminal 3 - Start API:**
```cmd
cd C:\Users\Filip\Desktop\WalletProject\src\Wallet.Api
dotnet run
```
*You should see: "Now listening on: http://localhost:5000"*

**Terminal 4 - Start Consumer:**
```cmd
cd C:\Users\Filip\Desktop\WalletProject\src\Wallet.Consumer
dotnet run
```
*You should see: "Kafka consumer started. Listening for messages..."*

---

## ?? Step 3: Test It's Working! (Super Easy Tests)

### Test 1: Health Check ?

**In your browser, open:**
```
http://localhost:5000/health
```

**You should see:** `Healthy`

? If you see "Healthy" - it's working!

---

### Test 2: Your First Top-Up ??

**Open PowerShell and run:**

```powershell
# Add $100 to player-001's wallet
$body = @{
    playerId = "player-001"
    amount = 100.00
    externalRef = "my-first-test"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

**You should see something like:**
```json
{
  "playerId": "player-001",
  "amount": 100.00,
  "newBalance": 100.00,
  "transactionId": "some-long-id",
  "idempotent": false
}
```

? **Success!** You just added money to a wallet!

---

### Test 3: Check the Balance ??

**In your browser, open:**
```
http://localhost:5000/wallet/player-001/balance
```

**You should see:**
```json
{
  "playerId": "player-001",
  "balance": 100.00
}
```

? Balance shows $100 - it worked!

---

### Test 4: Check Transaction History ??

**In your browser, open:**
```
http://localhost:5000/wallet/player-001/history
```

**You should see:**
```json
[
  {
    "transactionId": "...",
    "playerId": "player-001",
    "amount": 100.00,
    "newBalance": 100.00,
    "externalRef": "my-first-test",
    "processedAt": "2024-01-15T10:30:00Z",
    "transactionType": "TopUp"
  }
]
```

? Your transaction is there!

---

### Test 5: Test Idempotency (Same Request Twice) ??

**Run the SAME top-up command again:**

```powershell
# Same request as before
$body = @{
    playerId = "player-001"
    amount = 100.00
    externalRef = "my-first-test"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

**Notice:**
- Balance is still **$100** (not $200!)
- `"idempotent": true` in the response
- Same transaction ID as before

? **This proves idempotency works!** Same request = same result, no duplicate money!

---

## ?? Kafka UI Tools (See Your Messages!)

Since you asked about Kafka UI - here are 3 easy options:

### Option 1: Kafka UI (Easiest) ?

**Install with Docker:**
```powershell
docker run -p 8080:8080 `
  -e KAFKA_CLUSTERS_0_NAME=local `
  -e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=host.docker.internal:9092 `
  provectuslabs/kafka-ui:latest
```

**Then open:** http://localhost:8080

You'll see:
- ? All topics (wallet-topup-requests, wallet-events)
- ? Messages in each topic
- ? Consumer groups
- ? Easy to browse and search

---

### Option 2: Offset Explorer (Desktop App)

**Download:** https://www.kafkatool.com/download.html

**Setup:**
1. Install and open
2. Click "Add New Connection"
3. Enter:
   - Name: `Local Kafka`
   - Zookeeper Host: `localhost`
   - Zookeeper Port: `2181`
4. Click "Test" then "Add"

**You can now:**
- ? Browse topics
- ? View messages
- ? Search messages
- ? See consumer lag

---

### Option 3: Conduktor (Professional)

**Download:** https://www.conduktor.io/download/

**Free for local development!**

Features:
- ? Beautiful UI
- ? Real-time monitoring
- ? Consumer lag tracking
- ? Message viewer

---

## ?? What to Look For While Testing

### In the API Terminal (Terminal 3):

You should see logs like:
```
info: Wallet.Api[0]
      Processing TopUp for player-001, amount: 100.00
info: Wallet.Api[0]
      TopUp completed, new balance: 100.00
```

? These logs show requests being processed

---

### In the Consumer Terminal (Terminal 4):

You should see logs like:
```
info: Wallet.Consumer[0]
      Received message: player-001 at offset [wallet-topup-requests, 0] @0
info: Wallet.Consumer[0]
      Message processed successfully
```

? These logs show Kafka messages being consumed

---

### In Kafka UI:

**Topic: `wallet-topup-requests`**
- You should see messages when you send top-up requests via Kafka
- Each message has: playerId, amount, externalRef

**Topic: `wallet-events`**
- You should see `WalletTopUpCompleted` events
- Published after each successful top-up
- Contains: transactionId, playerId, amount, newBalance

---

## ?? More Fun Tests to Try

### Test 6: Add Money to Multiple Players

```powershell
# Player 2
$body = @{
    playerId = "player-002"
    amount = 50.00
    externalRef = "test-player2"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" -Method Post -ContentType "application/json" -Body $body

# Player 3
$body = @{
    playerId = "player-003"
    amount = 75.00
    externalRef = "test-player3"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" -Method Post -ContentType "application/json" -Body $body
```

**Check their balances:**
- http://localhost:5000/wallet/player-002/balance
- http://localhost:5000/wallet/player-003/balance

---

### Test 7: Add More Money to Existing Player

```powershell
# Add another $50 to player-001 (different externalRef!)
$body = @{
    playerId = "player-001"
    amount = 50.00
    externalRef = "second-topup"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" -Method Post -ContentType "application/json" -Body $body
```

**Check balance:**
```
http://localhost:5000/wallet/player-001/balance
```
Should now be **$150** (100 + 50) ?

---

### Test 8: Test Validation (Bad Requests)

**Try to add negative amount:**
```powershell
$body = @{
    playerId = "player-001"
    amount = -100.00
    externalRef = "test-negative"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" -Method Post -ContentType "application/json" -Body $body
```

**You should get error:** "Amount must be greater than zero" ?

---

### Test 9: Test Empty Player ID

```powershell
$body = @{
    playerId = ""
    amount = 100.00
    externalRef = "test-empty"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" -Method Post -ContentType "application/json" -Body $body
```

**You should get error:** "PlayerId is required" ?

---

## ??? View Database Directly (Optional)

**Connect to PostgreSQL:**
```cmd
psql -U gameuser -d wallet
```

**View all wallets:**
```sql
SELECT * FROM Wallets;
```

**View all transactions:**
```sql
SELECT * FROM WalletTransactions ORDER BY CreatedAt DESC;
```

**View pending outbox events:**
```sql
SELECT * FROM Outbox WHERE Published = false;
```

**View poison messages (failed):**
```sql
SELECT * FROM PoisonMessages;
```

**Exit:**
```sql
\q
```

---

## ?? Quick Test Checklist

Run through this checklist to verify everything works:

- [ ] Health check returns "Healthy"
- [ ] Can add money to wallet (top-up)
- [ ] Balance shows correct amount
- [ ] Transaction history shows transactions
- [ ] Same request twice = same result (idempotency)
- [ ] Different externalRef = new transaction
- [ ] Validation catches bad inputs (negative, empty)
- [ ] Multiple players can have separate wallets
- [ ] Kafka UI shows messages (if installed)
- [ ] Database shows correct data

**All checked?** ? Everything is working perfectly!

---

## ?? How to Stop Everything

### If Using Docker:
```cmd
quick-stop.bat
```

### If Manual:
1. Press **Ctrl+C** in each terminal window
2. Close the windows

---

## ?? Common Issues

### Issue: Port 5000 already in use

**Fix:**
```cmd
# Find what's using it
netstat -ano | findstr :5000

# Kill that process
taskkill /PID <PID> /F
```

---

### Issue: Can't connect to database

**Fix:**
```cmd
# Restart PostgreSQL
net restart postgresql-x64-14

# Or restart Docker
docker restart wallet-postgres
```

---

### Issue: Kafka not working

**Fix:**
```cmd
# Make sure Zookeeper started BEFORE Kafka
# Wait 10 seconds after starting Zookeeper
# Then start Kafka
```

---

## ?? What You Just Tested

Congratulations! You just tested:

? **REST API** - HTTP requests to endpoints  
? **Database** - PostgreSQL storing wallet data  
? **Caching** - Redis caching balances  
? **Messaging** - Kafka event publishing  
? **Idempotency** - No duplicate processing  
? **Validation** - Input checking  
? **Error Handling** - Bad request handling  
? **Observability** - Health checks  

**You're now a wallet service tester!** ??

---

## ?? Understanding What Happened

When you sent that first top-up request:

1. **API received request** ? Validated input
2. **Checked database** ? Is this externalRef already processed?
3. **Created transaction** ? Added $100 to wallet
4. **Saved to database** ? In a single transaction (all-or-nothing)
5. **Stored event in outbox** ? For reliable Kafka publishing
6. **Updated Redis cache** ? Balance cached for fast reads
7. **Returned response** ? You got the result
8. **Background worker** ? Published event to Kafka (after 5 seconds)
9. **Consumer received event** ? Processed by Wallet.Consumer

**All of this happened in milliseconds!** ?

---

## ?? Pro Testing Tips

1. **Use Postman** (optional)
   - Download: https://www.postman.com/downloads/
   - Import API endpoints
   - Easier than PowerShell commands

2. **Use Kafka UI** (recommended)
   - See messages in real-time
   - Debug consumer issues
   - Monitor lag

3. **Check logs often**
   - API logs show what's happening
   - Consumer logs show Kafka messages
   - Error logs show problems

4. **Test edge cases**
   - Large amounts (999,999.99)
   - Many concurrent requests
   - Same externalRef multiple times

---

## ?? You Did It!

You successfully:
- ? Started a microservices application
- ? Tested REST API endpoints
- ? Verified database storage
- ? Checked Redis caching
- ? Observed Kafka messaging
- ? Confirmed idempotency

**You're not an idiot - you're a tester!** ??

---

## ?? Need More Help?

- **Can't start services?** ? Check [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)
- **Want detailed testing?** ? See [docs/MANUAL_TESTING.md](docs/MANUAL_TESTING.md)
- **Need setup help?** ? Read [SETUP_GUIDE_BEGINNERS.md](SETUP_GUIDE_BEGINNERS.md)

**Happy Testing!** ??
