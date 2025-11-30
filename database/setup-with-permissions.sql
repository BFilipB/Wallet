-- Grant full permissions to gameuser and create all tables

-- Grant schema ownership
ALTER DATABASE wallet OWNER TO gameuser;
ALTER SCHEMA public OWNER TO gameuser;

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
    "Offset" BIGINT NOT NULL,
    MessageKey VARCHAR(500),
    MessageValue TEXT NOT NULL,
    ErrorMessage TEXT,
    FailedAt TIMESTAMP NOT NULL DEFAULT NOW(),
    RetryCount INT NOT NULL DEFAULT 0,
    LastRetryAt TIMESTAMP NULL
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS IX_WalletTransactions_ExternalRef ON WalletTransactions(ExternalRef);
CREATE INDEX IF NOT EXISTS IX_WalletTransactions_PlayerId_CreatedAt ON WalletTransactions(PlayerId, CreatedAt DESC);
CREATE INDEX IF NOT EXISTS IX_Outbox_Published_CreatedAt ON Outbox(Published, CreatedAt) WHERE Published = FALSE;
CREATE INDEX IF NOT EXISTS IX_PoisonMessages_FailedAt ON PoisonMessages(FailedAt DESC);

-- Grant all permissions to gameuser
GRANT ALL ON ALL TABLES IN SCHEMA public TO gameuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO gameuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO gameuser;
