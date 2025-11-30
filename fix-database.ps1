# Quick Fix Script
Write-Host "Fixing database permissions and creating tables..." -ForegroundColor Yellow

$walletProjectPath = "C:\Users\Filip\Desktop\WalletProject"

# Get postgres password from user
$postgresPassword = Read-Host "Enter your PostgreSQL admin (postgres) password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($postgresPassword)
$pgPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$env:PGPASSWORD = $pgPass

# Grant permissions
Write-Host "Granting permissions to gameuser..." -ForegroundColor Yellow
& 'C:\Program Files\PostgreSQL\15\bin\psql.exe' -U postgres -h localhost -p 5432 -d wallet -c "ALTER SCHEMA public OWNER TO gameuser;"

# Create tables as postgres
Write-Host "Creating tables..." -ForegroundColor Yellow
& 'C:\Program Files\PostgreSQL\15\bin\psql.exe' -U postgres -h localhost -p 5432 -d wallet -f "$walletProjectPath\database\schema.sql"

# Grant all future permissions
& 'C:\Program Files\PostgreSQL\15\bin\psql.exe' -U postgres -h localhost -p 5432 -d wallet -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO gameuser;"

Write-Host "Done! Tables created successfully." -ForegroundColor Green

$env:PGPASSWORD = ""

Read-Host "Press Enter to continue"
