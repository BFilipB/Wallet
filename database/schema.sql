-- Database Schema for Wallet Service
-- PostgreSQL 14+

-- Wallets table
CREATE TABLE IF NOT EXISTS Wallets (
    PlayerId VARCHAR(100) PRIMARY KEY,
    Balance DECIMAL(18, 2) NOT NULL DEFAULT 0,
    CreatedAt TIMESTAMP NOT NULL DEFAULT NOW(),
    UpdatedAt TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Wallet Transactions table
CREATE TABLE IF NOT EXISTS WalletTransactions (
    TransactionId UUID PRIMARY KEY,
    PlayerId VARCHAR(100) NOT NULL,
    Amount DECIMAL(18, 2) NOT NULL,
    NewBalance DECIMAL(18, 2) NOT NULL,
    ExternalRef VARCHAR(200) NOT NULL UNIQUE,
    ProcessedAt TIMESTAMP NOT NULL,
    TransactionType VARCHAR(50) NOT NULL,
    CreatedAt TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT FK_WalletTransactions_Wallets FOREIGN KEY (PlayerId) REFERENCES Wallets(PlayerId)
);

-- Outbox table for reliable event publishing
CREATE TABLE IF NOT EXISTS Outbox (
    Id UUID PRIMARY KEY,
    EventType VARCHAR(200) NOT NULL,
    Payload JSONB NOT NULL,
    CreatedAt TIMESTAMP NOT NULL DEFAULT NOW(),
    Published BOOLEAN NOT NULL DEFAULT FALSE,
    PublishedAt TIMESTAMP NULL
);

-- Poison Messages table for failed message tracking
CREATE TABLE IF NOT EXISTS PoisonMessages (
    Id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    Topic VARCHAR(200) NOT NULL,
    Partition INT NOT NULL,
    Offset BIGINT NOT NULL,
    MessageKey VARCHAR(500),
    MessageValue TEXT NOT NULL,
    ErrorMessage TEXT,
    FailedAt TIMESTAMP NOT NULL DEFAULT NOW(),
    RetryCount INT NOT NULL DEFAULT 0,
    LastRetryAt TIMESTAMP NULL
);

-- ==========================================
-- PERFORMANCE INDEXES
-- ==========================================

-- Index for idempotency check (most critical - used on every request)
CREATE INDEX IF NOT EXISTS IX_WalletTransactions_ExternalRef 
ON WalletTransactions(ExternalRef);

-- Index for history queries (player lookup with ordering)
CREATE INDEX IF NOT EXISTS IX_WalletTransactions_PlayerId_CreatedAt 
ON WalletTransactions(PlayerId, CreatedAt DESC);

-- Index for outbox processing
CREATE INDEX IF NOT EXISTS IX_Outbox_Published_CreatedAt 
ON Outbox(Published, CreatedAt) 
WHERE Published = FALSE;

-- Index for poison message tracking
CREATE INDEX IF NOT EXISTS IX_PoisonMessages_FailedAt 
ON PoisonMessages(FailedAt DESC);

-- ==========================================
-- SAMPLE DATA (Optional - for testing)
-- ==========================================

-- Insert test player wallets
-- INSERT INTO Wallets (PlayerId, Balance, CreatedAt, UpdatedAt)
-- VALUES 
--     ('player-001', 100.00, NOW(), NOW()),
--     ('player-002', 250.50, NOW(), NOW()),
--     ('player-003', 0.00, NOW(), NOW());
