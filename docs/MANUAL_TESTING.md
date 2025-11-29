# Manual Testing Guide (No Docker Required)

This guide helps you test the Wallet Service **without Docker**, using locally installed PostgreSQL, Redis, and Kafka.

---

## Prerequisites

Install these locally on your machine:

### 1. PostgreSQL 14+
**Windows:**
```powershell
# Download from: https://www.postgresql.org/download/windows/
# Or use Chocolatey:
choco install postgresql
```

**Mac:**
```bash
brew install postgresql@16
brew services start postgresql@16
```

**Ubuntu:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### 2. Redis 6+
**Windows:**
```powershell
# Download from: https://github.com/microsoftarchive/redis/releases
# Or use Chocolatey:
choco install redis-64
redis-server
```

**Mac:**
```bash
brew install redis
brew services start redis
```

**Ubuntu:**
```bash
sudo apt install redis-server
sudo systemctl start redis
```

### 3. Apache Kafka 3.0+
**Windows/Mac/Linux:**
```bash
# Download from: https://kafka.apache.org/downloads
# Extract and run:
cd kafka_2.13-3.6.0

# Start Zookeeper (Terminal 1)
bin/zookeeper-server-start.sh config/zookeeper.properties  # Mac/Linux
bin\windows\zookeeper-server-start.bat config\zookeeper.properties  # Windows

# Start Kafka (Terminal 2)
bin/kafka-server-start.sh config/server.properties  # Mac/Linux
bin\windows\kafka-server-start.bat config\server.properties  # Windows
```

### 4. .NET 9 SDK
```bash
# Download from: https://dotnet.microsoft.com/download/dotnet/9.0
dotnet --version  # Verify installation (should show 9.x.x)
```

---

## Step 1: Setup Database

### Create Database
```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE wallet;

# Connect to wallet database
\c wallet

# Run schema (paste content from database/schema.sql)
# Or run from file:
\i C:/path/to/database/schema.sql  # Windows
\i /path/to/database/schema.sql    # Mac/Linux

# Verify tables created
\dt

# Expected output:
#  Schema |      Name          | Type  |  Owner
# --------+--------------------+-------+----------
#  public | wallets            | table | postgres
#  public | wallettransactions | table | postgres
#  public | outbox             | table | postgres
#  public | poisonmessages     | table | postgres

# Exit
\q
```

**Troubleshooting:**
If psql is not in PATH, find it:
- Windows: `C:\Program Files\PostgreSQL\16\bin\psql.exe`
- Mac: `/opt/homebrew/opt/postgresql@16/bin/psql`

### Verify Database Connection
```bash
psql -U postgres -d wallet -c "SELECT COUNT(*) FROM Wallets;"
# Expected: 0 (empty table)
```

---

## Step 2: Setup Redis

### Start Redis Server
```bash
redis-server
# Should show: "Ready to accept connections"
```

### Verify Redis Connection
```bash
redis-cli ping
# Expected: PONG
```

### Test Redis Operations
```bash
redis-cli

# Set a test value
SET test:key "hello"

# Get the value
GET test:key
# Expected: "hello"

# Exit
exit
```

---

## Step 3: Setup Kafka

### Create Required Topics
```bash
# Navigate to Kafka directory
cd kafka_2.13-3.6.0

# Create wallet-topup-requests topic (for consumer)
bin/kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic wallet-topup-requests \
  --partitions 12 \
  --replication-factor 1

# Create wallet-events topic (for outbox publisher)
bin/kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic wallet-events \
  --partitions 12 \
  --replication-factor 1

# Verify topics created
bin/kafka-topics.sh --list --bootstrap-server localhost:9092
# Expected:
# wallet-topup-requests
# wallet-events
```

**Windows:**
Replace `.sh` with `.bat` and use `bin\windows\` directory

---

## Step 4: Configure Application

### Update Connection Strings

**src/Wallet.Api/appsettings.json:**
```json
{
  "ConnectionStrings": {
    "PostgreSQL": "Host=localhost;Port=5432;Database=wallet;Username=postgres;Password=YOUR_PASSWORD",
    "Redis": "localhost:6379"
  },
  "Kafka": {
    "BootstrapServers": "localhost:9092"
  }
}
```

**src/Wallet.Consumer/appsettings.json:**
```json
{
  "ConnectionStrings": {
    "PostgreSQL": "Host=localhost;Port=5432;Database=wallet;Username=postgres;Password=YOUR_PASSWORD",
    "Redis": "localhost:6379"
  },
  "Kafka": {
    "BootstrapServers": "localhost:9092",
    "GroupId": "wallet-consumer-group"
  }
}
```

**Important:** Replace `YOUR_PASSWORD` with your PostgreSQL password

---

## Step 5: Build the Solution

```bash
# Navigate to solution directory
cd C:\Users\Filip\Desktop\WalletProject

# Restore packages
dotnet restore

# Build
dotnet build

# Verify no errors
# Expected: Build succeeded. 0 Warning(s). 0 Error(s).
```

---

## Step 6: Start the Services

### Terminal 1: Start API
```bash
cd src/Wallet.Api
dotnet run

# Expected output:
# info: Microsoft.Hosting.Lifetime[14]
#       Now listening on: http://localhost:5000
#       Now listening on: https://localhost:5001
# info: Wallet.Infrastructure.OutboxWorker[0]
#       Outbox Worker started. Polling interval: 5s
```

**API is now running at:** `http://localhost:5000`

### Terminal 2: Start Consumer
```bash
cd src/Wallet.Consumer
dotnet run

# Expected output:
# info: Wallet.Consumer.Worker[0]
#       Kafka consumer started. Listening for messages...
```

**Keep both terminals running!**

---

## Step 7: Test the API

### Test 1: Health Check
```bash
curl http://localhost:5000/health

# Expected: Healthy
```

**Windows PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing
```

### Test 2: First Top-Up Request
```bash
curl -X POST http://localhost:5000/wallet/topup \
  -H "Content-Type: application/json" \
  -d '{
    "playerId": "player-001",
    "amount": 100.00,
    "externalRef": "payment-12345"
  }'

# Expected response:
{
  "playerId": "player-001",
  "amount": 100.00,
  "newBalance": 100.00,
  "externalRef": "payment-12345",
  "transactionId": "550e8400-e29b-41d4-a716-446655440000",
  "processedAt": "2024-01-15T10:30:00Z",
  "idempotent": false
}
```

**Windows PowerShell:**
```powershell
$body = @{
    playerId = "player-001"
    amount = 100.00
    externalRef = "payment-12345"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

### Test 3: Idempotency (Same Request)
```bash
# Send EXACTLY the same request again
curl -X POST http://localhost:5000/wallet/topup \
  -H "Content-Type: application/json" \
  -d '{
    "playerId": "player-001",
    "amount": 100.00,
    "externalRef": "payment-12345"
  }'

# Expected: Same response with "idempotent": true
# Balance should still be 100.00 (not 200.00!)
```

### Test 4: Second Top-Up (Different ExternalRef)
```bash
curl -X POST http://localhost:5000/wallet/topup \
  -H "Content-Type: application/json" \
  -d '{
    "playerId": "player-001",
    "amount": 50.00,
    "externalRef": "payment-67890"
  }'

# Expected:
# "newBalance": 150.00  (100 + 50)
# "idempotent": false
```

### Test 5: Get Balance
```bash
curl http://localhost:5000/wallet/player-001/balance

# Expected:
{
  "playerId": "player-001",
  "balance": 150.00
}
```

### Test 6: Get Transaction History
```bash
curl http://localhost:5000/wallet/player-001/history

# Expected: Array of transactions
[
  {
    "transactionId": "...",
    "playerId": "player-001",
    "amount": 50.00,
    "newBalance": 150.00,
    "externalRef": "payment-67890",
    "processedAt": "2024-01-15T10:35:00Z",
    "transactionType": "TopUp",
    "createdAt": "2024-01-15T10:35:00Z"
  },
  {
    "transactionId": "...",
    "playerId": "player-001",
    "amount": 100.00,
    "newBalance": 100.00,
    "externalRef": "payment-12345",
    "processedAt": "2024-01-15T10:30:00Z",
    "transactionType": "TopUp",
    "createdAt": "2024-01-15T10:30:00Z"
  }
]
```

---

## Step 8: Test Kafka Consumer

### Send Message to Kafka
```bash
cd kafka_2.13-3.6.0

# Send a message via Kafka console producer
bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic wallet-topup-requests

# Paste this JSON and press Enter:
{"playerId":"player-002","amount":75.00,"externalRef":"kafka-payment-001"}

# Press Ctrl+C to exit producer
```

**Windows:**
```cmd
bin\windows\kafka-console-producer.bat --bootstrap-server localhost:9092 --topic wallet-topup-requests
```

### Check Consumer Logs
Go to Terminal 2 (Consumer), you should see:
```
info: Wallet.Consumer.Worker[0]
      Received message: null at offset [wallet-topup-requests, 0] @0
info: Wallet.Consumer.Worker[0]
      Message processed successfully: null
```

### Verify in Database
```bash
psql -U postgres -d wallet

SELECT * FROM Wallets WHERE PlayerId = 'player-002';
# Expected: balance = 75.00

SELECT * FROM WalletTransactions WHERE PlayerId = 'player-002';
# Expected: 1 row with amount = 75.00

\q
```

---

## Step 9: Test Cache

### Test Cache Hit
```bash
# First request (cache miss)
curl http://localhost:5000/wallet/player-001/history

# Check API logs - should show database query

# Second request within 2 minutes (cache hit)
curl http://localhost:5000/wallet/player-001/history

# Check API logs - should NOT show database query (served from cache)
```

### Verify Redis Cache
```bash
redis-cli

# Check balance cache
GET wallet:balance:player-001
# Expected: "150.00"

# Check history cache
GET wallet:history:player-001
# Expected: JSON array of transactions

exit
```

### Test Cache Invalidation
```bash
# Top up player-001 again
curl -X POST http://localhost:5000/wallet/topup \
  -H "Content-Type: application/json" \
  -d '{
    "playerId": "player-001",
    "amount": 25.00,
    "externalRef": "payment-99999"
  }'

# Check Redis - history cache should be deleted
redis-cli GET wallet:history:player-001
# Expected: (nil)

# But balance cache should be updated
redis-cli GET wallet:balance:player-001
# Expected: "175.00"
```

---

## Step 10: Test Outbox Pattern

### Check Outbox Table (Before Processing)
```bash
psql -U postgres -d wallet

SELECT * FROM Outbox WHERE Published = false;
# Should show unpublished events (if any)

\q
```

### Wait for OutboxWorker (5 seconds)
The API has a background worker that polls every 5 seconds.

### Check Outbox Table (After Processing)
```bash
psql -U postgres -d wallet

SELECT * FROM Outbox WHERE Published = true ORDER BY PublishedAt DESC LIMIT 5;
# Should show events with PublishedAt timestamp

\q
```

### Verify Events in Kafka
```bash
cd kafka_2.13-3.6.0

# Read messages from wallet-events topic
bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic wallet-events \
  --from-beginning

# Expected: JSON events for each top-up
{"TransactionId":"...","PlayerId":"player-001",...}

# Press Ctrl+C to exit
```

---

## Step 11: Test Poison Messages

### Send Invalid JSON to Kafka
```bash
cd kafka_2.13-3.6.0

bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic wallet-topup-requests

# Send invalid JSON:
this is not valid json

# Press Ctrl+C to exit
```

### Check Consumer Logs
Terminal 2 should show:
```
error: Wallet.Consumer.Worker[0]
       Invalid JSON format, saving to poison messages table
```

### Verify Poison Message Saved
```bash
psql -U postgres -d wallet

SELECT * FROM PoisonMessages ORDER BY FailedAt DESC LIMIT 1;
# Should show the invalid message

\q
```

### View Poison Messages via API
```bash
curl http://localhost:5000/admin/poison-messages

# Expected: Array with the poison message
[
  {
    "id": "...",
    "topic": "wallet-topup-requests",
    "partition": 0,
    "offset": 1,
    "messageKey": null,
    "messageValue": "this is not valid json",
    "errorMessage": "JSON parsing error: ...",
    "failedAt": "2024-01-15T10:45:00Z",
    "retryCount": 0,
    "lastRetryAt": "2024-01-15T10:45:00Z"
  }
]
```

---

## Step 12: Test Validation

### Test Missing PlayerId
```bash
curl -X POST http://localhost:5000/wallet/topup \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.00,
    "externalRef": "payment-00000"
  }'

# Expected: 400 Bad Request
{
  "error": "PlayerId is required"
}
```

### Test Negative Amount
```bash
curl -X POST http://localhost:5000/wallet/topup \
  -H "Content-Type: application/json" \
  -d '{
    "playerId": "player-003",
    "amount": -50.00,
    "externalRef": "payment-11111"
  }'

# Expected: 400 Bad Request
{
  "error": "Amount must be greater than zero"
}
```

### Test Missing ExternalRef
```bash
curl -X POST http://localhost:5000/wallet/topup \
  -H "Content-Type: application/json" \
  -d '{
    "playerId": "player-003",
    "amount": 100.00
  }'

# Expected: 400 Bad Request
{
  "error": "ExternalRef is required"
}
```

---

## Step 13: Test Performance

### Query Performance (With Indexes)
```bash
psql -U postgres -d wallet

# Enable timing
\timing

# Test history query
SELECT * FROM WalletTransactions 
WHERE PlayerId = 'player-001' 
ORDER BY CreatedAt DESC 
LIMIT 100;

# Expected: Time: < 50ms (with index)

# Check query plan
EXPLAIN ANALYZE 
SELECT * FROM WalletTransactions 
WHERE PlayerId = 'player-001' 
ORDER BY CreatedAt DESC 
LIMIT 100;

# Should show "Index Scan" (not "Seq Scan")

\q
```

### Load Test (Optional - Apache Bench)
If you have Apache Bench (`ab`) installed:

```bash
# Create request file
echo '{"playerId":"player-load-test","amount":10.00,"externalRef":"load-REF"}' > request.json

# Run 100 requests with 10 concurrent
ab -n 100 -c 10 -p request.json -T application/json http://localhost:5000/wallet/topup

# Expected:
# Requests per second: > 100 req/sec
# Time per request (mean): < 100ms
```

---

## Troubleshooting

### API Won't Start

**Error: "Address already in use"**
```bash
# Find process using port 5000
netstat -ano | findstr :5000  # Windows
lsof -i :5000                  # Mac/Linux

# Kill the process
taskkill /PID <PID> /F  # Windows
kill -9 <PID>           # Mac/Linux
```

### Database Connection Failed

**Error: "connection refused"**
```bash
# Check PostgreSQL is running
# Windows:
net start postgresql-x64-16

# Mac:
brew services restart postgresql@16

# Linux:
sudo systemctl status postgresql
sudo systemctl restart postgresql
```

**Error: "password authentication failed"**
- Update `appsettings.json` with correct password
- Or reset password:
```bash
psql -U postgres
ALTER USER postgres PASSWORD 'newpassword';
\q
```

### Redis Connection Failed

**Error: "No connection is available"**
```bash
# Check Redis is running
redis-cli ping

# If not running:
redis-server
```

### Kafka Connection Failed

**Error: "Connection refused"**
```bash
# Make sure both Zookeeper and Kafka are running
# Check ports:
netstat -ano | findstr :2181  # Zookeeper (Windows)
netstat -ano | findstr :9092  # Kafka (Windows)

lsof -i :2181  # Zookeeper (Mac/Linux)
lsof -i :9092  # Kafka (Mac/Linux)
```

### Consumer Not Processing Messages

**Check consumer group:**
```bash
cd kafka_2.13-3.6.0

# List consumer groups
bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list

# Check lag
bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group wallet-consumer-group \
  --describe

# Should show LAG = 0 if caught up
```

---

## Monitoring During Testing

### PostgreSQL
```bash
# Watch active connections
psql -U postgres -d wallet

SELECT count(*) FROM pg_stat_activity WHERE datname = 'wallet';

# Watch table sizes
SELECT 
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

\q
```

### Redis
```bash
redis-cli

# Monitor all commands in real-time
MONITOR

# Get memory usage
INFO memory

# Count keys
DBSIZE

exit
```

### Kafka
```bash
cd kafka_2.13-3.6.0

# Monitor topic
bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group wallet-consumer-group \
  --describe

# Should show current offset and lag
```

---

## Clean Up

### Reset Database
```bash
psql -U postgres -d wallet

TRUNCATE TABLE WalletTransactions CASCADE;
TRUNCATE TABLE Wallets CASCADE;
TRUNCATE TABLE Outbox CASCADE;
TRUNCATE TABLE PoisonMessages CASCADE;

\q
```

### Clear Redis Cache
```bash
redis-cli FLUSHDB
```

### Delete Kafka Topics
```bash
cd kafka_2.13-3.6.0

bin/kafka-topics.sh --delete \
  --bootstrap-server localhost:9092 \
  --topic wallet-topup-requests

bin/kafka-topics.sh --delete \
  --bootstrap-server localhost:9092 \
  --topic wallet-events
```

---

## Next Steps

1. ? All basic functionality tested
2. ? Idempotency verified
3. ? Cache working
4. ? Kafka consumer processing
5. ? Poison message handling
6. ? Outbox pattern working

**You're ready for production!** ??

For advanced topics, see:
- `docs/DESIGN_DECISIONS.md` - Why things are built this way
- `docs/PERFORMANCE.md` - Optimization strategies
- `REQUIREMENTS_FULFILLMENT.md` - Requirement checklist
