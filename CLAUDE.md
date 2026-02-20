# Family Squares Game - Claude Context

## Project Overview

A Rails 8.1.1 application for managing family sports squares games across NCAA basketball tournaments. Players buy chances on a 10x10 grid, and winners are determined by final digit scores at each period/quarter.

## Tech Stack

- **Framework**: Rails 8.1.1
- **Database**: SQLite3
- **Background Jobs**: Solid Queue (Rails 8 built-in)
- **Frontend**: Bootstrap 5 via cssbundling-rails, Stimulus, Importmap
- **Admin Theme**: Falcon v3.23.0 (selective integration - Option B)
- **Web Scraping**: HTTParty + Nokogiri (ESPN scoreboard data)
- **Deployment**: Fly.io

## Core Domain Concepts

### Grid System
- 100 squares (10x10): away team score (0-9) × home team score (0-9)
- Grid format: serialized as `"a0h0:player_id;a0h1:player_id;..."`
- **Immutable once created** - no preview to prevent "fishing" for favorable boards
- Players weighted by `chances` field (active players only)
- Charity players fill unfilled squares if total chances < 100

### Player System
- Active players: participate in new games (have chances > 0)
- Charity players: fallback for unfilled squares
- Family structure: self-referential (`family_id` references Player)
- **Email addresses encrypted** (Rails `encrypts`), never displayed in UI

### Score Tracking
- Stores both period scores AND cumulative totals:
  - `away`, `home`: period-specific scores
  - `away_total`, `home_total`: running totals
- Sentinel value: `-1` indicates period not yet played
- **Destroy/recreate pattern**: ensures canonical score per period
- Overtime compressed into final regulation period
- Women's basketball: `non_scoring` flag for Q1/Q3 (only award at halves)

### Grid Validation Strategy
- **Fail-fast approach**:
  1. Total chances > 100: Error, require adjustment
  2. Total chances < 100 with no charities: Error, require code edit
  3. Total chances < 100 with charities: Fill with random charities
- `Player.total_active_chances` class method for UI indicator

## Architecture Patterns

### Service Objects
- Base class: `ApplicationService`
- Scraper: `ScoreboardService::ScoreScraper` orchestrates `EspnApiScraper` (primary) with `EspnHtmlScraper` fallback

### ESPN Scraping Constraints
- **Obfuscated CSS classes**: ESPN uses randomized class names that change periodically to prevent scraping
- **Position-dependent parsing**: Must rely on DOM structure (row/cell order) rather than class names
- **No stable selectors**: Avoid `.class-name` selectors; use structural navigation (nth-child, table positions)
- **Fragile by design**: ESPN is intentionally hostile to scrapers - expect maintenance burden

### ESPN JSON API
Undocumented but stable API that powers ESPN's own apps - far superior to HTML scraping.

**Endpoint pattern**:
```
https://site.api.espn.com/apis/site/v2/sports/{sport}/{league}/summary?event={gameId}
```

**Available data** (partial list):
- Teams: names, abbreviations, records, ESPN IDs
- Colors: primary/secondary hex values
- Logos: URLs to official team logo images
- Game: status, start time, venue, broadcast info
- Scores: period-by-period, final, live updates

**Usage guidelines**:
- Cache aggressively - scores don't change faster than every few minutes
- Respect 429 rate limit responses if they occur
- Keep HTML scraper as fallback if API becomes unavailable
- Low-volume use (family game app) is negligible traffic

### Scripts vs Rake Tasks
- **`lib/tasks/*.rake`** - Regular maintenance tasks, part of app operations. Run via `bin/rails taskname`. Rails environment loaded automatically.
- **`scripts/`** - Occasional one-off tools, related but not critical to app. Run directly.

**Script boilerplate** (gems only, no Rails):
```ruby
#!/usr/bin/env ruby
require 'bundler/setup'
require 'httparty'
require 'json'
```

**Script boilerplate** (with Rails/ActiveRecord):
```ruby
#!/usr/bin/env ruby
require 'bundler/setup'
require_relative '../config/environment'
# Now have access to models, app config, etc.
```

### Accountability
- ActivityLog table: track deletions and admin actions
- Require `reason` field when deleting games
- Single audit log table (not per-model)

## Sports Coverage

### Current
- NCAA Men's Basketball (March Madness)
- NCAA Women's Basketball (March Madness)
- 397 teams (365 college + 32 pro), 1023 affiliations across MBB/WBB/FBS/FCS/NFL
- All teams have ESPN IDs/slugs

### Team Data Structure
- Sport-agnostic core: name, location, mascot
- Sport-specific affiliations: basketball_conference, football_conference
- Handles multi-sport schools and conference differences

### Colors & Styles System
- **Colors**: `hex`, `name`, `primary` (boolean), `team_id`
- **Styles**: `css`, `name`, `default` (boolean), `runtime_style` (boolean), `team_id`
  - Applied to grid headers via class names (e.g., `lou-louisville-cardinals`)
  - `runtime_style: true` renders as inline CSS immediately (no redeploy needed)
- Grid rendering flow: Team → Colors → Styles → CSS class on grid headers

## Falcon Theme Integration

**Strategy: Option B (Selective Integration)**
- Import only needed components: Choices.js, Flatpickr, DataTables
- Skip: charts, maps, calendar, kanban, chat
- Wrap each library in Stimulus controllers

## Development Workflow

### Git Integration
- Commits managed by Claude
- Backlog tracked in [GitHub Issues](https://github.com/ctembreull/square/issues) with milestones and labels
- TodoWrite for session-level task tracking
- Branch strategy: feature branches, PRs to main

### Testing Workflow
- Claude: server logs, tests, syntax validation
- Human: UX testing, visual feedback, browser console errors
- Screenshots/error logs shared back to Claude for fixes

### Security
- Brakeman 7.1.2 + bundler-audit pass clean
- 4 reviewed/ignored warnings documented in `config/brakeman.ignore`
- Run `bundle exec brakeman` to verify

## Important File Locations

- Grid logic: `app/models/game.rb` (build_grid method)
- Score scraping: `app/services/scoreboard_service/`
- Brakeman ignore: `config/brakeman.ignore`

## Established Patterns & UX Understanding

The following patterns have been validated through implementation and should be followed for consistency:

### Admin UI Patterns (Falcon Theme)
- **Index pages**: Card-based tables with active/inactive sections, action dropdowns, breadcrumbs
- **Show pages**: Header card with title/status, main content area (left), sidebar with details/quick actions (right)
- **Forms**: Card wrapper, horizontal labels, validation feedback, cancel/submit buttons
- **Soft delete**: Use active/inactive flags rather than deletion to preserve data integrity for scoring history

### STI Workarounds (Player/Individual/Charity/Family)
- Explicit path helpers: `player_path(record)` not `polymorphic_path(record)`
- Form params: `scope: :player` regardless of subclass
- Form URLs: Explicit `url: player_path(record)` for edit forms
- Controller: Single PlayersController handles all types via `type` param

### Model Status Patterns
- Status helper methods in models (`upcoming?`, `in_progress?`, `completed?`)
- Scopes for filtering by status (`active`, `inactive`, `upcoming`, `in_progress`, `completed`)
- Manual action methods for state transitions (`end_event!`, `deactivate!`)

### Navigation Patterns
- Dynamic dropdowns populated from scopes (e.g., `Event.active.current`)
- Home route redirects to current item or falls back to index
- "Older..." link convention for accessing full index from dropdown

### Barebones Model Strategy
- When a feature depends on an unbuilt model, create minimal version with just associations
- Prevents rabbit holes while unblocking dependent features
- Document that model needs expansion when its feature is built

### Mobile Support Policy
- **PUBLIC pages only**: Event show, game show (read-only views for family members)
- **NEVER admin pages**: Game creation, score entry, player management, team CRUD - desktop only, period
- If user mentions "admin mobile" or "mobile admin", remind them of this policy and refuse. Mock them gently for forgetting. They asked for this.

## Fly.io Deployment

**Live at**: famsquares.net (sjc region)

**Configuration:**
- Port 8080 (non-root container requires high port)
- `HTTP_PORT=8080` env var for Thruster
- SQLite with WAL mode for better concurrency
- `min_machines_running=1` to prevent autostop
- 1GB RAM (shared-cpu-1x)

**Useful Commands:**
```bash
fly deploy                    # Deploy new version
fly logs --app family-squares # View logs
fly ssh console              # Shell access (requires WireGuard)
fly machine restart          # Restart the machine
```

**Backup Before Deploy:**
```bash
fly ssh sftp get /rails/storage/production.sqlite3 ./backup-$(date +%Y%m%d).sqlite3
```

**Email**: Resend SMTP, domain verified (SPF, DKIM, DMARC)

**Backups**: Litestream continuous replication to Cloudflare R2 (10-second sync for main DB). Daily YAML export via `R2PushJob` at 3am. `rake r2:pull` syncs dev from prod.

### PDF Generation
- Grover gem (Puppeteer-based) generates landscape Letter PDFs
- Requires `GROVER_NO_SANDBOX=true` env var
- Async job avoids 60s proxy timeout
- Uses `localhost:PORT` for Puppeteer to fetch stylesheets
- Stale detection via game/score `updated_at`

## Status Endpoint

**Route**: `GET /status.json`
- Returns model counts (events, games, leagues, conferences, teams, colors, styles)
- Queue heartbeat monitoring: returns 503 when stale (>10 min), triggering Fly.io auto-restart
- No authentication required

## Ongoing Monitoring

| Item | Notes |
|------|-------|
| **Query performance on events#show** | Currently 42 queries (~114ms) for a small event. Dense events (70+ games) may need further optimization. |
| **SolidQueue database locks** | Using `processes: 0` in dev. Monitor production for lock contention under load. |
| **PDF generation reliability** | Intermittent blank PDFs observed once (Super Bowl 2026). Monitor during NCAA Tournament. |
| **ActivityLog table growth** | Monitor SQLite size as logs accumulate. Archival strategy planned (see GitHub Issues). |

---

**Backlog**: See [GitHub Issues](https://github.com/ctembreull/square/issues) for all planned work, organized by milestone (1.0, Post-1.0, Future).

**Last Updated**: 2026-02-20
