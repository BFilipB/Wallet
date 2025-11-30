# ?? Quick Fix - Start PostgreSQL on Windows

## Problem: PostgreSQL Not Started

Your connection string shows localhost, which means PostgreSQL should be installed but not running.

---

## ? Super Easy Fix (2 Steps)

### Step 1: Start PostgreSQL

**Double-click this file:**
```
start-postgresql.bat
```

**Or run manually:**
```cmd
net start postgresql-x64-14
```

*Note: Your version might be different (15, 16, etc.)*

---

### Step 2: Setup Database

**Double-click this file:**
```
setup-database.bat
```

**Or run manually:**
```cmd
psql -U postgres -c "CREATE USER gameuser WITH PASSWORD 'gamepass123';"
psql -U postgres -c "CREATE DATABASE wallet OWNER gameuser;"
psql -U gameuser -d wallet -f database\schema.sql
```

---

## ?? How to Find Your PostgreSQL Service

If the scripts don't work, find your service name:

### Option 1: Services GUI
1. Press `Win + R`
2. Type: `services.msc`
3. Press Enter
4. Find "postgresql" in the list
5. Right-click ? Start

### Option 2: Command Line
```cmd
sc query | findstr postgres
```

You'll see something like:
- `postgresql-x64-16` (PostgreSQL 16)
- `postgresql-x64-15` (PostgreSQL 15)
- `postgresql-x64-14` (PostgreSQL 14)

Then start it:
```cmd
net start postgresql-x64-16
```
*(Replace with your version)*

---

## ? Verify PostgreSQL is Running

### Test 1: Check Service
```cmd
sc query postgresql-x64-14
```

Should show: **STATE: 4 RUNNING**

### Test 2: Connect
```cmd
psql -U postgres
```

Should show PostgreSQL prompt: `postgres=#`

Type `\q` to exit.

---

## ??? Common PostgreSQL Locations

If `psql` command not found, add to PATH or use full path:

**Default installation paths:**
- `C:\Program Files\PostgreSQL\16\bin\psql.exe`
- `C:\Program Files\PostgreSQL\15\bin\psql.exe`
- `C:\Program Files\PostgreSQL\14\bin\psql.exe`

**Use directly:**
```cmd
"C:\Program Files\PostgreSQL\14\bin\psql.exe" -U postgres
```

---

## ?? Alternative: Quick PowerShell Fix

**Open PowerShell as Administrator:**

```powershell
# Find PostgreSQL service
Get-Service | Where-Object {$_.Name -like "*postgre*"}

# Start it (replace with your service name)
Start-Service postgresql-x64-14

# Verify
Get-Service postgresql-x64-14
```

---

## ?? Setup Database (After PostgreSQL Starts)

Once PostgreSQL is running, create the database:

```cmd
# Connect as postgres user (default admin)
psql -U postgres

# In psql prompt, run:
CREATE USER gameuser WITH PASSWORD 'gamepass123';
CREATE DATABASE wallet OWNER gameuser;
\q

# Run schema
psql -U gameuser -d wallet -f database\schema.sql
```

**Or just run:**
```cmd
setup-database.bat
```

---

## ? Verify Database Created

```cmd
psql -U gameuser -d wallet
```

In psql:
```sql
\dt
```

You should see:
- wallets
- wallettransactions
- outbox
- poisonmessages

Type `\q` to exit.

---

## ?? Now Start Your Application

### Terminal 1: API
```cmd
cd src\Wallet.Api
dotnet run
```

### Terminal 2: Consumer
```cmd
cd src\Wallet.Consumer
dotnet run
```

---

## ?? Troubleshooting

### Error: "role 'postgres' does not exist"

Your PostgreSQL might use a different superuser.

**Fix:**
```cmd
# Find your username
whoami

# Use that username instead
psql -U YourWindowsUsername -d postgres
```

---

### Error: "password authentication failed"

**Reset postgres password:**
```cmd
# Edit pg_hba.conf to allow trust authentication temporarily
# Location: C:\Program Files\PostgreSQL\14\data\pg_hba.conf

# Change this line:
host    all             all             127.0.0.1/32            md5

# To:
host    all             all             127.0.0.1/32            trust

# Restart PostgreSQL:
net stop postgresql-x64-14
net start postgresql-x64-14

# Connect without password:
psql -U postgres

# Set new password:
ALTER USER postgres PASSWORD 'newpassword';

# Revert pg_hba.conf back to 'md5'
# Restart PostgreSQL again
```

---

### Error: "database already exists"

Good! It means database was created before.

**Just verify tables:**
```cmd
psql -U gameuser -d wallet -c "\dt"
```

**If no tables, run schema:**
```cmd
psql -U gameuser -d wallet -f database\schema.sql
```

---

### Error: "connection refused"

PostgreSQL not running.

**Check:**
```cmd
sc query postgresql-x64-14
```

**Start:**
```cmd
net start postgresql-x64-14
```

**If service doesn't exist:**
1. PostgreSQL not installed properly
2. Install from: https://www.postgresql.org/download/windows/

---

## ?? Quick Checklist

- [ ] PostgreSQL service started
- [ ] Can connect: `psql -U postgres`
- [ ] Database 'wallet' created
- [ ] User 'gameuser' created
- [ ] Tables created (run schema.sql)
- [ ] Tables verified: `\dt` shows 4 tables

**All checked?** ? You're ready to run the application!

---

## ?? One-Line Setup (After PostgreSQL Started)

```cmd
start-postgresql.bat && setup-database.bat
```

---

## ?? Pro Tip: Auto-Start PostgreSQL

Make PostgreSQL start automatically with Windows:

1. Press `Win + R`
2. Type: `services.msc`
3. Find PostgreSQL service
4. Right-click ? Properties
5. Startup type: **Automatic**
6. Click Apply

Now it starts automatically when Windows boots! ?

---

## ?? Need More Help?

If still having issues:

1. **Check PostgreSQL installation:**
   - Control Panel ? Programs ? PostgreSQL
   - Should show version (14, 15, or 16)

2. **Reinstall if needed:**
   - Download: https://www.postgresql.org/download/windows/
   - Install with default settings
   - Remember the password you set!

3. **Check documentation:**
   - [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)
   - [SETUP_GUIDE_BEGINNERS.md](SETUP_GUIDE_BEGINNERS.md)

---

**You got this!** ??
