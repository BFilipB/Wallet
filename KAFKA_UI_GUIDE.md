# ?? Kafka UI Setup - See Your Messages Visually!

**3 Easy Options to View Kafka Messages with a Nice UI**

---

## ?? Option 1: Kafka UI (Easiest - Recommended) ?

### What is it?
Free, open-source web UI for Kafka. Works perfectly with your project!

### Quick Start (Docker)

**Just run this command:**
```powershell
docker run -d -p 8080:8080 `
  -e DYNAMIC_CONFIG_ENABLED=true `
  -e KAFKA_CLUSTERS_0_NAME=local `
  -e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=localhost:9092 `
  --name kafka-ui `
  provectuslabs/kafka-ui:latest
```

**Then open in browser:**
```
http://localhost:8080
```

### What You'll See:
- ? **Topics:** wallet-topup-requests, wallet-events
- ? **Messages:** All messages with timestamps
- ? **Consumer Groups:** wallet-consumer-group
- ? **Lag:** How far behind consumers are
- ? **Search:** Find specific messages

### Features:
- ?? Real-time monitoring
- ?? Message search and filtering
- ?? View message details (JSON formatted)
- ?? Consumer lag charts
- ?? Topic management

---

## ?? Option 2: Offset Explorer (Desktop App)

### What is it?
Free desktop application for Kafka (formerly Kafka Tool).

### Download & Install:
1. Go to: https://www.kafkatool.com/download.html
2. Download Windows installer
3. Install (default settings)

### Setup:
1. **Open Offset Explorer**
2. **Click:** File ? Add New Connection
3. **Enter:**
   - **Cluster name:** Local Kafka
   - **Kafka Cluster Version:** 3.0
   - **Zookeeper Host:** localhost
   - **Zookeeper Port:** 2181
4. **Advanced Tab:**
   - **Bootstrap servers:** localhost:9092
5. **Click:** Test ? Should say "Connected successfully"
6. **Click:** Add

### What You Can Do:
- ? Browse topics
- ? View all messages
- ? Filter by key, value
- ? See consumer group details
- ? Export messages to CSV
- ? View schema registry (if you add it)

---

## ?? Option 3: Conduktor (Professional - Free Tier)

### What is it?
Professional Kafka desktop client. Free for local development!

### Download & Install:
1. Go to: https://www.conduktor.io/download/
2. Download for Windows
3. Install
4. Create free account (required)

### Setup:
1. **Open Conduktor**
2. **Click:** Add Cluster
3. **Enter:**
   - **Name:** Local Kafka
   - **Bootstrap servers:** localhost:9092
4. **Click:** Test Connection
5. **Click:** Save

### Features (Free):
- ? Beautiful modern UI
- ? Real-time monitoring
- ? Consumer lag tracking
- ? Message viewer with syntax highlighting
- ? Producer tool (send test messages)
- ? Schema Registry support
- ? Topic configuration

---

## ?? Comparison Table

| Feature | Kafka UI | Offset Explorer | Conduktor |
|---------|----------|-----------------|-----------|
| **Type** | Web (Browser) | Desktop | Desktop |
| **Price** | Free | Free | Free tier |
| **Setup** | 1 command | Download + Install | Download + Account |
| **UI** | Modern | Classic | Very Modern |
| **Real-time** | Yes | Yes | Yes |
| **Message Search** | Yes | Yes | Yes |
| **Consumer Lag** | Yes | Yes | Yes |
| **Best For** | Quick start | Power users | Professional dev |

**My Recommendation:** Start with **Kafka UI** (easiest!)

---

## ?? How to Use Kafka UI (Step-by-Step)

### 1. Start Kafka UI
```powershell
docker run -d -p 8080:8080 `
  -e DYNAMIC_CONFIG_ENABLED=true `
  -e KAFKA_CLUSTERS_0_NAME=local `
  -e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=host.docker.internal:9092 `
  --name kafka-ui `
  provectuslabs/kafka-ui:latest
```

### 2. Open in Browser
```
http://localhost:8080
```

### 3. View Topics
1. Click **"Topics"** in left menu
2. You'll see:
   - `wallet-topup-requests` - Top-up requests
   - `wallet-events` - Completed events

### 4. View Messages in a Topic
1. Click on **`wallet-topup-requests`**
2. Click **"Messages"** tab
3. You'll see all messages:
   ```json
   {
     "playerId": "player-001",
     "amount": 100.00,
     "externalRef": "test-1"
   }
   ```

### 5. View Consumer Groups
1. Click **"Consumers"** in left menu
2. Click on **`wallet-consumer-group`**
3. You'll see:
   - Current offset (where consumer is)
   - End offset (latest message)
   - Lag (how far behind)

### 6. Search Messages
1. In any topic, click **"Messages"**
2. Click **"Filters"**
3. Add filter:
   - **Field:** `playerId`
   - **Value:** `player-001`
4. Click **"Search"**

---

## ?? Testing with Kafka UI

### Test 1: Send a Top-Up Request

**Send via API:**
```powershell
$body = @{
    playerId = "player-ui-test"
    amount = 250.00
    externalRef = "ui-test-1"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

**In Kafka UI:**
1. Go to Topics ? `wallet-events`
2. Click "Messages"
3. You should see a new message:
   ```json
   {
     "TransactionId": "...",
     "PlayerId": "player-ui-test",
     "Amount": 250.00,
     "NewBalance": 250.00,
     "ExternalRef": "ui-test-1",
     "ProcessedAt": "2024-01-15T10:30:00Z"
   }
   ```

? **You can see the event in real-time!**

---

### Test 2: Monitor Consumer Lag

**In Kafka UI:**
1. Go to **Consumers** ? `wallet-consumer-group`
2. You'll see a table showing:
   - Topic: `wallet-topup-requests`
   - Partition: 0-11
   - Current Offset: 5 (example)
   - End Offset: 5
   - Lag: 0 ? (caught up!)

**If lag is > 0:**
- ? Consumer is behind
- Check Consumer terminal for errors

**If lag is 0:**
- ? Consumer is processing in real-time

---

### Test 3: View Message Timeline

**In Kafka UI:**
1. Go to Topics ? `wallet-events`
2. Click "Messages"
3. You'll see messages in order:
   - Latest at top
   - Timestamp for each
   - Click to expand full JSON

**You can:**
- See when each event was published
- Track message flow
- Debug issues

---

## ?? Alternative: Command-Line Tools

If you prefer command-line (no UI needed):

### List Topics:
```cmd
cd C:\kafka
bin\windows\kafka-topics.bat --list --bootstrap-server localhost:9092
```

### View Messages:
```cmd
bin\windows\kafka-console-consumer.bat --bootstrap-server localhost:9092 --topic wallet-events --from-beginning
```

### Check Consumer Group:
```cmd
bin\windows\kafka-consumer-groups.bat --bootstrap-server localhost:9092 --group wallet-consumer-group --describe
```

---

## ?? Kafka UI Screenshots Guide

### What You'll See:

**Dashboard:**
- Cluster overview
- Topic count
- Consumer groups
- Brokers status

**Topics Page:**
- List of all topics
- Message count per topic
- Partition count
- Replication factor

**Messages Page:**
- Individual messages
- JSON formatting
- Timestamps
- Key/Value display
- Offset numbers

**Consumers Page:**
- Consumer group name
- Member count
- Partition assignment
- Lag per partition
- Offset positions

---

## ?? Configuration Options

### For Kafka UI:

**Stop Kafka UI:**
```powershell
docker stop kafka-ui
docker rm kafka-ui
```

**Start with different port:**
```powershell
docker run -d -p 9000:8080 `
  -e KAFKA_CLUSTERS_0_NAME=local `
  -e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=host.docker.internal:9092 `
  --name kafka-ui `
  provectuslabs/kafka-ui:latest
```
Now access at: http://localhost:9000

---

## ?? Troubleshooting

### Issue: Can't connect to Kafka

**In Kafka UI:**
1. Check connection string
2. For Docker Kafka: Use `host.docker.internal:9092`
3. For native Kafka: Use `localhost:9092`

**In Offset Explorer:**
1. Make sure Zookeeper is running
2. Test connection before saving
3. Check firewall settings

---

### Issue: No messages visible

**Possible causes:**
1. Messages not sent yet ? Send a test message
2. Wrong topic selected ? Check topic name
3. Offset at end ? Change to "beginning" in UI

**Fix:**
```powershell
# Send a test message
$body = @{
    playerId = "test-ui"
    amount = 10.00
    externalRef = "ui-debug"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/wallet/topup" -Method Post -ContentType "application/json" -Body $body
```

---

### Issue: Consumer lag increasing

**In Kafka UI, if you see lag growing:**
1. Check Consumer terminal for errors
2. Restart consumer: Close terminal and start again
3. Check database is responding
4. Verify Redis is running

---

## ?? Pro Tips

### 1. Use Kafka UI for Development
- Quick visual feedback
- Easy to debug
- No installation needed

### 2. Use Offset Explorer for Deep Analysis
- Export messages to CSV
- Complex filtering
- Schema registry integration

### 3. Use Conduktor for Production-Like Testing
- Professional monitoring
- Performance insights
- Team collaboration

### 4. Bookmark Kafka UI
- Keep it running during development
- Refresh to see new messages
- Great for demos!

---

## ?? Quick Setup Summary

**Fastest way (1 minute):**
```powershell
# Start Kafka UI
docker run -d -p 8080:8080 `
  -e KAFKA_CLUSTERS_0_NAME=local `
  -e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=host.docker.internal:9092 `
  --name kafka-ui `
  provectuslabs/kafka-ui:latest

# Open browser
start http://localhost:8080
```

**That's it!** You now have a beautiful UI for Kafka. ?

---

## ?? What You Can Do Now

With Kafka UI, you can:
- ? See all wallet top-up requests
- ? View wallet events in real-time
- ? Monitor consumer progress
- ? Debug message processing
- ? Search specific transactions
- ? Track system health

**You're no longer blind - you can SEE what's happening!** ??

---

## ?? Resources

- **Kafka UI:** https://github.com/provectus/kafka-ui
- **Offset Explorer:** https://www.kafkatool.com/
- **Conduktor:** https://www.conduktor.io/

**Happy Kafka Viewing!** ??
