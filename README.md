# README

## Backup & Sync

### Continuous Database Backups (Litestream)

Production database is continuously replicated to Cloudflare R2 every 10 seconds.

**To restore from backup:**
```bash
litestream restore -config config/litestream.yml -o restored.sqlite3 /rails/storage/production.sqlite3
```

### Production-as-Source Workflow

Production is the canonical source of truth for team data (colors, styles, players).

**Pull latest data from production:**
```bash
rake r2:pull              # Download YAMLs from R2
rake structure:import     # Import leagues, conferences
rake seeds:import         # Import teams, colors, styles
rake players:import       # Import players
rake affiliations:import  # Import team affiliations
```

**Push data to R2** (production only, runs daily at 3am):
```bash
rake r2:push  # Exports all data and uploads to R2
```

## Disaster Recovery

### Understanding Your Backups

The app maintains **two complementary backup systems** in the same R2 bucket:

1. **Litestream** (`litestream/` prefix) - Real-time database replication
   - Captures every write to production database within 10 seconds
   - Enables point-in-time recovery to any moment in the last 7 days
   - Includes ALL data: events, games, scores, players, teams, everything
   - Binary SQLite format (not human-readable)

2. **YAML Exports** (`seeds/` prefix) - Daily snapshots
   - Human-readable team/player data exported at 3am daily
   - Used for dev sync and cross-environment portability
   - Does NOT include events/games/scores (operational data)
   - Version-controllable seed files

**Choose your recovery method:**
- Database corruption/loss → **Use Litestream** (complete recovery)
- Dev environment sync → **Use YAML exports** (team data only)
- Accidental deletion mid-event → **Use Litestream** (point-in-time)

### Scenario 1: Complete Database Loss

**Situation:** Production database file deleted/corrupted, need full recovery.

**Recovery steps:**

1. **SSH into production container:**
   ```bash
   fly ssh console --app family-squares
   ```

2. **Stop the Rails server** (prevents new writes during recovery):
   ```bash
   # Find the Rails process
   ps aux | grep puma
   # Kill it (container will restart automatically)
   kill <PID>
   ```

3. **Restore from Litestream** (gets latest backup):
   ```bash
   cd /rails
   litestream restore -config config/litestream.yml \
     -o storage/production.sqlite3 \
     /rails/storage/production.sqlite3
   ```

4. **Exit and restart the container:**
   ```bash
   exit
   fly machine restart
   ```

5. **Verify recovery:**
   - Visit https://famsquares.net/status.json
   - Check event/game counts match expectations
   - Log in and spot-check recent data

**Expected downtime:** 2-5 minutes

### Scenario 2: Point-in-Time Recovery (Oops, I Deleted Something)

**Situation:** Admin accidentally deleted a game/event, need to restore to before deletion.

**Recovery steps:**

1. **Determine the timestamp** you want to restore to:
   - Check recent git commits for timing context
   - Check Fly.io logs: `fly logs --app family-squares` (look for timestamps)
   - Go back slightly before the mistake (e.g., 5 minutes before deletion)

2. **SSH into production and stop Rails:**
   ```bash
   fly ssh console --app family-squares
   ps aux | grep puma
   kill <PID>
   ```

3. **Restore to specific timestamp:**
   ```bash
   cd /rails
   litestream restore -config config/litestream.yml \
     -timestamp 2026-02-09T18:30:00Z \
     -o storage/production.sqlite3 \
     /rails/storage/production.sqlite3
   ```

4. **Restart and verify:**
   ```bash
   exit
   fly machine restart
   ```

**Important:** This restores the ENTIRE database to that point in time. Any changes made AFTER that timestamp will be lost (scores, new games, etc.). Use with caution during active events.

### Scenario 3: Corrupted Team Data (Colors/Styles)

**Situation:** Team styles broken, colors wrong, need to restore just team data without touching events/games.

**Use YAML exports instead of Litestream:**

1. **Pull latest YAML exports locally:**
   ```bash
   rake r2:pull
   ```

2. **Inspect the files** to verify data is correct:
   ```bash
   cat db/seeds/teams.yml | grep "Seahawks" -A 10
   ```

3. **Import to local dev** and test:
   ```bash
   rake seeds:import
   ```

4. **If good, commit to git and deploy** (safest path):
   ```bash
   git add db/seeds/teams.yml
   git commit -m "Restore team data from R2 backup"
   fly deploy
   ```

**Alternative (production import)** if you can't wait for deploy:
```bash
fly ssh console --app family-squares
cd /rails
bin/rails r2:pull
bin/rails seeds:import
```

### Scenario 4: Total Infrastructure Loss (Fly.io Down, R2 Inaccessible)

**Situation:** Complete platform failure, need to rebuild from scratch.

**Prerequisites (maintain these):**
- Local git clone with latest code
- Copy of `.env` with all secrets (R2 credentials, etc.)
- Recent database backup (manual SFTP download recommended weekly)

**Recovery steps:**

1. **Get production database** (if R2 unavailable, use local backup):
   ```bash
   # From R2 (if accessible):
   litestream restore -config config/litestream.yml -o backup.sqlite3 /rails/storage/production.sqlite3

   # Or use manual backup:
   cp ~/backups/production-20260209.sqlite3 ./backup.sqlite3
   ```

2. **Spin up new infrastructure** (Fly.io or alternative):
   ```bash
   # Deploy to new app
   fly deploy --app family-squares-recovery
   ```

3. **Upload database to new environment:**
   ```bash
   fly ssh sftp shell --app family-squares-recovery
   put backup.sqlite3 /rails/storage/production.sqlite3
   ```

4. **Update DNS** to point to new infrastructure
5. **Restart and verify**

**Expected downtime:** 15-30 minutes (depends on DNS propagation)

### Backup Best Practices

**Automated (already configured):**
- ✅ Litestream replicates every 10 seconds
- ✅ Daily YAML export at 3am
- ✅ 7-day retention on main database
- ✅ 1-day retention on cache/queue databases

**Manual (recommended):**
- **Weekly database download** (defense in depth):
  ```bash
  fly ssh sftp get /rails/storage/production.sqlite3 backup-$(date +%Y%m%d).sqlite3
  ```

- **Before major changes** (pre-deploy backup):
  ```bash
  fly ssh sftp get /rails/storage/production.sqlite3 pre-deploy-backup.sqlite3
  ```

- **Backup your backups** (keep local copies):
  - Store weekly downloads in `~/backups/family-squares/`
  - Keep `.env` file in password manager
  - Document R2 bucket name and account ID

**Test recovery quarterly:**
- Spin up local container
- Restore from Litestream to local file
- Verify data integrity
- Practice makes perfect when disaster strikes

### R2 Bucket Structure

```
squares-backups/
├── litestream/
│   ├── production/           # Main database (7-day retention)
│   ├── production_cache/     # Cache (1-day retention)
│   └── production_queue/     # Job queue (1-day retention)
└── seeds/
    ├── structure.yml         # Leagues, conferences
    ├── teams.yml             # Teams, colors, styles
    ├── players.yml           # Players (no emails)
    ├── affiliations.yml      # Team-conference links
    └── timestamp.json        # Last sync metadata
```

### Getting Help

If disaster strikes and this documentation isn't enough:
1. Check Litestream docs: https://litestream.io/reference/restore/
2. Check Fly.io status: https://status.flyio.net/
3. Check Cloudflare R2 status: https://www.cloudflarestatus.com/
4. GitHub issues: https://github.com/anthropics/claude-code/issues (for Claude Code questions)

## Data Export/Import Tasks

```
rake structure:export      Export Leagues/Conferences → db/seeds/structure.yml
rake structure:import      Import from structure.yml
rake seeds:export          Export Teams/Colors/Styles → db/seeds/teams.yml
rake seeds:import          Import from teams.yml
rake affiliations:export   Export Team-Conference links → db/seeds/affiliations.yml
rake affiliations:import   Import from affiliations.yml
rake players:export        Export Players → db/seeds/players.yml
rake players:import        Import from players.yml
```

## Full Rebuild Order

1. `rake db:seed` - Calls structure:import and seeds:import automatically
2. `rake affiliations:import` - Team-Conference affiliations
3. `rake players:import` - Players (emails need manual re-entry)