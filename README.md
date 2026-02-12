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