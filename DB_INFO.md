# SQLite Database Information

## Database Details

**Database Name:** `sudoku_profiles.db`

**Database Version:** 4

**Bundle ID:** `com.ilgin.sudoku`

## Database Location

### iOS Simulator
```
~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/sudoku_profiles.db
```

### macOS
```
~/Library/Application Support/com.ilgin.sudoku/sudoku_profiles.db
```

### Android
```
/data/data/com.ilgin.sudoku/databases/sudoku_profiles.db
```

## Database Schema

### Table: `profiles`
- `id` (TEXT PRIMARY KEY)
- `email` (TEXT NOT NULL UNIQUE)
- `firstName` (TEXT NOT NULL)
- `lastName` (TEXT NOT NULL)
- `birthDate` (TEXT NOT NULL)
- `avatarPath` (TEXT)
- `avatarColor` (INTEGER)
- `createdAt` (TEXT NOT NULL)
- `lastPlayedAt` (TEXT)
- `emailVerified` (INTEGER NOT NULL DEFAULT 0)
- `passwordHash` (TEXT NOT NULL)

### Table: `game_scores`
- `id` (TEXT PRIMARY KEY)
- `profileId` (TEXT NOT NULL)
- `difficulty` (TEXT NOT NULL)
- `score` (INTEGER NOT NULL)
- `elapsedSeconds` (INTEGER NOT NULL)
- `completedAt` (TEXT NOT NULL)
- `isDailyGame` (INTEGER NOT NULL DEFAULT 0)
- FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE

## Indexes
- `idx_profile_scores` on `game_scores(profileId)`
- `idx_score_date` on `game_scores(completedAt)`
- `idx_email` on `profiles(email)`

## How to Find Database Path

### Method 1: Using the App
1. Run the app
2. Go to Settings
3. Tap "Database Info"
4. Copy the path shown

### Method 2: Using Terminal (iOS Simulator)
```bash
# Find the database file
find ~/Library/Developer/CoreSimulator -name "sudoku_profiles.db" 2>/dev/null

# Or find by bundle ID
xcrun simctl get_app_container booted com.ilgin.sudoku data
```

### Method 3: Using Terminal (macOS)
```bash
# Database should be in Application Support
ls ~/Library/Application\ Support/com.ilgin.sudoku/sudoku_profiles.db
```

## Connect to TablePlus

1. Open TablePlus
2. Click "Create a new connection"
3. Select "SQLite"
4. Paste the database path (from Method 1 or 2)
5. Click "Connect"

## Admin User Creation

To create an admin user manually in TablePlus:

1. Open the `profiles` table
2. Insert a new row with:
   - `email`: `admin@pandoku.com` (or your preferred email)
   - `firstName`: `Admin`
   - `lastName`: `User`
   - `birthDate`: `2000-01-01T00:00:00.000`
   - `emailVerified`: `1`
   - `passwordHash`: `240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9` (SHA-256 hash of "admin123")
   - `createdAt`: Current timestamp
   - `id`: Generate a unique ID (e.g., timestamp)

## Password Hash Generation

The password hash is SHA-256. To generate a hash for a password:

```bash
# Using openssl
echo -n "yourpassword" | openssl dgst -sha256

# Or using Python
python3 -c "import hashlib; print(hashlib.sha256('yourpassword'.encode()).hexdigest())"
```

Example: Password "admin123" hashes to:
`240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9`
