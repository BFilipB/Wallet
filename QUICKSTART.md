# Quick Start Guide

## Prerequisites

- .NET 10 SDK
- Docker & Docker Compose
- (Optional) PostgreSQL client for manual queries

## Step 1: Start Infrastructure

```bash
# Start PostgreSQL, Redis, Kafka, and Jaeger
docker-compose up -d

# Wait for services to be healthy (30-60 seconds)
docker-compose ps
```

Services will be available at:
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`
- Kafka: `localhost:9092`
- Jaeger UI: `http://localhost:16686`

## Step 2: Verify Database

The database schema is automatically initialized via docker-compose.

```bash
# Connect to PostgreSQL (optional verification)
docker exec -it wallet-postgres psql -U postgres -d wallet

# List tables
\dt

# Expected output:
# wallets
# wallettransactions
# outbox
# poisonmessages
```

## Step 3: Start the API

```bash
cd src/Wallet.Api
dotnet restore
dotnet run
```

API will start at: `https://localhost:5001` (or `http://localhost:5000`)

## Step 4: Start the Consumer

Open a new terminal:

```bash
cd src/Wallet.Consumer
dotnet restore
dotnet run
```

Consumer will start processing messages from Kafka topic `wallet-topup-requests`

## Step 5: Test the System

### Test 1: Direct API Call

```bash
# Send a top-up request
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

### Test 2: Idempotency

```bash
# Send the SAME request again
curl -X POST http://localhost:5000/wallet/topup \
  -H "Content-Type: application/json" \
  -d '{
    "playerId": "player-001",
    "amount": 100.00,
    "externalRef": "payment-12345"
  }'

# Expected: Same response with "idempotent": true
```

### Test 3: Get History

```bash
# Get wallet history
curl http://localhost:5000/wallet/player-001/history

# Expected: Array of transactions
[
  {
    "transactionId": "550e8400-e29b-41d4-a716-446655440000",
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

### Test 4: Send Message via Kafka (Consumer Test)

```bash
# Install kcat (kafka CLI tool) if needed
# On macOS: brew install kcat
# On Ubuntu: apt-get install kafkacat

# Send a message to Kafka
echo '{
  "playerId": "player-002",
  "amount": 50.00,
  "externalRef": "kafka-payment-001"
}' | kcat -b localhost:9092 -t wallet-topup-requests -P

# Check consumer logs - should see:
# "Received message: ... at offset ..."
# "Message processed successfully: ..."
```

### Test 5: View Traces in Jaeger

1. Open Jaeger UI: `http://localhost:16686`
2. Select service: `Wallet.Api` or `Wallet.Consumer`
3. Click "Find Traces"
4. See distributed traces with timing and tags

### Test 6: Health Check

```bash
curl http://localhost:5000/health

# Expected: Healthy
```

## Step 6: Verify Cache

```bash
# Connect to Redis
docker exec -it wallet-redis redis-cli

# Check cached balance
GET wallet:balance:player-001

# Check cached history
GET wallet:history:player-001

# Exit
exit
```

## Step 7: Query Database

```bash
# Connect to PostgreSQL
docker exec -it wallet-postgres psql -U postgres -d wallet

# View wallets
SELECT * FROM Wallets;

# View transactions
SELECT * FROM WalletTransactions ORDER BY ProcessedAt DESC LIMIT 10;

# View outbox (should be published = true)
SELECT * FROM Outbox ORDER BY CreatedAt DESC LIMIT 10;

# View poison messages (should be empty if all tests passed)
SELECT * FROM PoisonMessages;
```

## Step 8: Load Testing (Optional)

### Using Apache Bench

```bash
# Install ab (Apache Bench)
# On macOS: Included with Apache
# On Ubuntu: apt-get install apache2-utils

# Send 1000 requests with 10 concurrent connections
ab -n 1000 -c 10 -T 'application/json' -p request.json http://localhost:5000/wallet/topup

# Create request.json first:
cat > request.json << EOF
{
  "playerId": "player-load-test",
  "amount": 10.00,
  "externalRef": "load-test-REF"
}
EOF
```

### Expected Results
- Throughput: >500 req/sec (single API instance)
- Latency (p95): <200ms
- Error rate: 0% (except duplicate externalRef)

## Troubleshooting

### Issue: API won't start

**Check port availability:**
```bash
lsof -i :5000
lsof -i :5001
```

**Solution:** Kill process or change port in `launchSettings.json`

### Issue: Consumer not processing messages

**Check Kafka topic exists:**
```bash
docker exec wallet-kafka kafka-topics --list --bootstrap-server localhost:9092
```

**Create topic manually if needed:**
```bash
docker exec wallet-kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic wallet-topup-requests \
  --partitions 12 \
  --replication-factor 1
```

### Issue: Database connection failed

**Check PostgreSQL is running:**
```bash
docker-compose ps postgres
```

**Recreate if needed:**
```bash
docker-compose down
docker-compose up -d postgres
```

### Issue: Redis connection failed

**Check Redis is running:**
```bash
docker exec wallet-redis redis-cli ping
```

**Expected:** PONG

## Cleanup

```bash
# Stop all services
docker-compose down

# Remove volumes (CAUTION: Deletes all data)
docker-compose down -v
```

## Next Steps

1. Review `README.md` for architecture details
2. Review `REQUIREMENTS_FULFILLMENT.md` for implementation details
3. Review `docs/PERFORMANCE.md` for optimization strategies
4. Add unit and integration tests
5. Configure production monitoring (Prometheus, Grafana)
6. Set up CI/CD pipeline
7. Configure backup and disaster recovery

## Production Checklist

Before deploying to production:

- [ ] Change default passwords in connection strings
- [ ] Configure TLS/SSL for PostgreSQL, Redis, Kafka
- [ ] Set up database backups
- [ ] Configure log aggregation (ELK, Splunk)
- [ ] Set up alerting (PagerDuty, OpsGenie)
- [ ] Configure resource limits and auto-scaling
- [ ] Implement authentication/authorization
- [ ] Set up rate limiting
- [ ] Configure CORS policies
- [ ] Enable HTTPS only
- [ ] Set up database migrations
- [ ] Configure monitoring dashboards
- [ ] Perform load testing at scale
- [ ] Set up disaster recovery plan
- [ ] Document runbooks for operations

## Support

For issues or questions:
1. Check logs in console output
2. Check Jaeger for trace details
3. Check database for data integrity
4. Review `REQUIREMENTS_FULFILLMENT.md` for implementation details
