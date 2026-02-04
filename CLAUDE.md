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
- Add `Player.total_active_chances` class method for UI indicator

## Known Issues & Bugs

### Fixed
- ✅ `charity.sample` → `charities.sample` in game.rb:122
- ✅ Simplified team naming - removed `prefix`/`suffix` columns, keeping only `location` and `display_location`
- ✅ Color form modal autofocuses the 'name' field
- ✅ Replaced List.js with Ransack + Pagy for teams table (server-side search/sort)
- ✅ Teams export missing `womens_name` and `brand_info` fields - added to `rake seeds:export` and `rake seeds:import`

### Pending
- (See milestone tables for tracked work items)

## Blockers - Do First

These issues must be resolved before any other development work. Do not proceed with milestone tasks until this section is empty.

| Issue | Description |
|-------|-------------|
| *(none)* | All blockers resolved |

## Next Session Priority

**Deploy 2026-02-04**: Push current commits (runtime inline styles, probability heat map) then freeze until Monday 2026-02-10 (after Super Bowl).

**#1 Priority - R2 Infrastructure** (required before football season, now effectively required for beta):
1. **Litestream backups** - Continuous SQLite replication to R2
2. **Production-as-source workflow** - Daily R2 sync (`r2:push`, `r2:pull` tasks)

### Resolved Blockers
- ✅ **Gitignore team stylesheets** - Done: `app/assets/stylesheets/teams/` and `teams.scss` removed from git, added to `.gitignore`. New `bin/generate-team-styles` script generates stylesheets from `teams.yml` at Docker build time (before asset precompilation).
- ✅ **Seed data corruption** - Fixed: Removed team definitions from `seeds.rb`, teams now sourced only from `db/seeds/teams.yml` via `rake seeds:import`. Duplicate teams cleaned up by deleting those with zero affiliations.
- ✅ **Player export/import** - Done: `rake players:export` and `rake players:import` tasks created. Exports exclude encrypted emails (must be re-entered after import).

## Architecture Patterns

### Service Objects
- Base class: `ApplicationService`
- Scraper hierarchy: `BaseScraper` → `EspnScraper`, `SrCfbScraper`
- Main orchestrator: `ScoreboardService::ScoreScraper`

### ESPN Scraping Constraints
- **Obfuscated CSS classes**: ESPN uses randomized class names that change periodically to prevent scraping
- **Position-dependent parsing**: Must rely on DOM structure (row/cell order) rather than class names
- **Context inference**: Parser must infer what data it's looking at based on position, not labels
- **No stable selectors**: Avoid `.class-name` selectors; use structural navigation (nth-child, table positions)
- **Fragile by design**: ESPN is intentionally hostile to scrapers - expect maintenance burden

### ESPN JSON API (Discovered 2026-01-29)
Undocumented but stable API that powers ESPN's own apps - far superior to HTML scraping.

**Endpoint pattern**:
```
https://site.api.espn.com/apis/site/v2/sports/{sport}/{league}/summary?event={gameId}
```

**Example** (men's college basketball):
```
https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/summary?event=401825479
```

**Available data** (partial list):
- Teams: names, abbreviations, records, ESPN IDs
- Colors: primary/secondary hex values
- Logos: URLs to official team logo images
- Game: status, start time, venue, broadcast info
- Scores: period-by-period, final, live updates
- Odds, venue, attendance, etc.

**Reference**: See `artifacts/espn_api_sample.json` for full response structure.

**Usage guidelines**:
- Cache aggressively - scores don't change faster than every few minutes
- Respect 429 rate limit responses if they occur
- Keep HTML scraper as fallback if API becomes unavailable
- Low-volume use (family game app) is negligible traffic

**Data fetch strategy** (for ESPN ID reconciliation):
1. Scrape ESPN standings pages → extract team links with IDs, grouped by conference/league
2. Hit API for each team ID → full team JSON
3. Store as local JSON files in `scripts/data/` → one-time archive
4. Build importers against cached files → parse at leisure, no rate limit pressure

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

### Initial Release (Tournament Test)
- NCAA Men's Basketball (March Madness)
- NCAA Women's Basketball (March Madness)
- **Seed ALL D1 teams** (~350 teams)
  - Tests UX at scale
  - Ready for any Cinderella team
  - Football overlap (most D1 basketball = D1 football)

### Team Data Structure
- Sport-agnostic core: name, location, mascot
- Sport-specific affiliations: basketball_conference, football_conference
- Handles multi-sport schools and conference differences

### Colors & Styles System
Tables exist in schema, models not yet built:
- **Colors**: `hex`, `name`, `primary` (boolean), `team_id`
  - Teams have multiple colors (primary, secondary, etc.)
  - Used to generate CSS styles for grid display
- **Styles**: `css`, `name`, `default` (boolean), `team_id`
  - Contains actual CSS rules for team branding
  - Applied to grid headers via class names (e.g., `lou-louisville-cardinals`)
  - `default` flag indicates which style to use when rendering

Grid rendering flow: Team → Colors → Styles → CSS class on grid headers

### Welcome Widgets (artifacts/welcome/)
Reusable components for game display, ready to wire to models:
- **Cards**: `_standard_card`, `_flex_card` (generic wrappers)
- **Game display**: `_game_card`, `_game_card_empty`, `_upcoming_game_list_item`
- **Grid components**: `_grid_grid` (10x10 board), `_grid_scores` (period scores), `_grid_winners` (prize/winner table)
- **Demo layout**: `demo.html.erb` shows full game page composition
- Reference: `artifacts/Bowls_Round_2.pdf` shows existing game output format

## Falcon Theme Integration

**Strategy: Option B (Selective Integration)**
- Import only needed components: Choices.js, Flatpickr, DataTables
- Skip: charts, maps, calendar, kanban, chat
- Wrap each library in Stimulus controllers
- Phased approach: SASS first → core JS → per-feature components

## Development Workflow

### Git Integration
- Commits managed by Claude
- Use both GitHub Issues (milestones) and TodoWrite (session tasks)
- Branch strategy: feature branches, PRs to main

### Testing Workflow
- Claude: server logs, tests, syntax validation
- Human: UX testing, visual feedback, browser console errors
- Screenshots/error logs shared back to Claude for fixes

## Important File Locations

- Grid logic: `app/models/game.rb` (build_grid method)
- Score scraping: `app/services/scoreboard_service/`
- Old schema reference: `artifacts/schema.rb` (PostgreSQL, needs migration)
- UI mockup: `artifacts/Bowls_Round_2.pdf`
- Writing guide: `artifacts/Chris's Sports Writing Style Guide v2.pdf`

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

## Completed

- ✅ **Finalize unified schema.rb** - Reconcile old schema with new requirements
- ✅ **Integrate Falcon SASS** - Theme fully integrated with working JavaScript
- ✅ **Sports Admin CRUD** - Complete CRUD for Leagues, Conferences, Teams
- ✅ **Admin Authentication** - Session-based auth with has_secure_password, public/admin route separation
- ✅ **SolidQueue Score Refresh** - Automatic score scraping every 5 minutes for in-progress games, auto-completion on "Final" detection

## Milestone: Testing Deployment - March 15, 2026

Target: NCAA Tournament testing on Fly.io

| Item | Notes |
|------|-------|
| ~~Status/Health Endpoint~~ | ✅ Done - `/status.json` returns model counts |
| ~~**Grid export button (admin)**~~ | ✅ Done - TSV to clipboard via Stimulus controller |
| ~~**Scores export button (admin)**~~ | ✅ Done - TSV to clipboard via Stimulus controller |
| ~~**Manual score input modal (admin)**~~ | ✅ Done - Team colors, OT checkbox, mark-as-final |
| ~~**WinnerCalculator service**~~ | ✅ Done - `aggregate_winners` helper in EventsHelper |
| ~~**Public/Admin View Separation**~~ | ✅ Moot - unified UX approach works for both roles |
| ~~**Deploy to Fly.io**~~ | ✅ Done - App live at family-squares.fly.dev. See deployment notes below. |
| ~~Set up ActionMailer + PostMailer~~ | ✅ Done - Letter Opener for dev, Send dropdown with optional PDF attachment. Resend SMTP configured. |
| ~~Build seed data for all D1 teams~~ | ✅ Done - 397 teams (365 college + 32 pro), 1023 affiliations across MBB/WBB/FBS/FCS/NFL. ESPN IDs on all teams. ~135 teams still need colors/styles. |
| ~~**Winners worksheet mode**~~ | ✅ Done - Simplified check-writing view: family-grouped names + amounts, prominent checkboxes, progress bar, grayed strikethrough on checked items, localStorage persistence |
| ~~**Debug Grover PDF on Fly.io**~~ | ✅ Done - Fixed with `GROVER_NO_SANDBOX=true` env var + async job to avoid 60s proxy timeout |
| ~~Grid validation (Player.total_active_chances)~~ | ✅ Done - Game creation blocked if chances >100 or <100 with no charities |
| ~~Query optimization on leagues/show~~ | ✅ Done - Eager loading + Ruby sorting reduced 335 queries to 4 |
| ~~Active player chances validation~~ | ✅ Done - Player model validates sum ≤100 on save |
| ~~**Event PDF Export**~~ | ✅ Done - Grover/Puppeteer generates landscape Letter PDFs with grid, scores, winners |
| ~~**Player export/import**~~ | ✅ Done - `rake players:export` and `rake players:import` tasks (emails excluded, must re-enter) |
| ~~**Affiliations export/import**~~ | ✅ Done - `rake affiliations:export` and `rake affiliations:import` tasks using natural keys (scss_slug, league abbr, conference abbr) |
| ~~**Affiliations UI (Conference show)**~~ | ✅ Done - Inline team list with delete buttons, Choices.js searchable dropdown for adding teams (filtered by league level). Turbo Stream updates without page reload. |
| ~~**Full Dockerization**~~ | ✅ Done - Chromium + Node.js for Grover PDF generation, docker-compose.yml with SQLite volume, entrypoint runs seeds/imports, admin user via env vars, health check on /status.json |
| ~~**Admin toolbar toggle**~~ | ✅ Done - Session-based toggle in user dropdown, defaults to showing for admins |
| ~~**Basic Users CRUD**~~ | ✅ Done - UsersController with full CRUD. Manage Users in dropdown. Password match validation via Stimulus. |
| ~~Posts UI: active post styling~~ | ✅ Done - Chevron icon + highlight on active post, Stimulus controller tracks selection |
| ~~Broadcast logger for job visibility~~ | ✅ Moot - SolidQueue in-process mode (`processes: 0` in dev) outputs to Puma logs |
| ~~Winners table period display~~ | ✅ Done - Reformat individual winning periods column for better scannability |
| ~~**Remove Event `active` flag**~~ | ✅ Done - Removed column, scopes, form toggle, controller actions, and routes. Visibility is purely status-based. |
| ~~**Team game history**~~ | ✅ Done - Team show page displays game history table. Game form shows calendar icon with last-used tooltip per team. |
| ~~Email template styling~~ | ✅ Done - Removed boxes, simplified to plain paragraphs with signature. Feels like a personal note now. |
| ~~Event game list team links~~ | ✅ Done - Team names in event game items should link to game, but invisibly (no underline/color change). |
| ~~Grid highlighter after Turbo refresh~~ | ✅ Done - Switched winners rows to use Stimulus actions instead of manual listeners |
| ~~Query optimization on events/show~~ | ✅ Done - Eager load games, teams, leagues, scores; partition by status in Ruby; preload posts |
| ~~**Tippy.js tooltips**~~ | ✅ Done - Replaced Bootstrap tooltips with Tippy.js. Stimulus controller auto-initializes tooltips via `data-tippy-content` attribute. |
| ~~**Teams table sorting**~~ | ✅ Done - Affiliations/Colors/Styles columns now sortable via Ransack. Click header to sort ascending (zeros first) to find incomplete teams. |
| ~~**(Stretch) Auto-populate game from ESPN URL**~~ | ✅ Done - Paste ESPN URL → fetch button hits JSON API → auto-fills date, time, timezone, broadcast, league, teams with styles. Focuses title field for quick entry. |

### Fly.io Deployment Notes

**Deployed 2026-01-27** to family-squares.fly.dev (sjc region)

**Configuration:**
- Port 8080 (non-root container requires high port)
- `HTTP_PORT=8080` env var for Thruster
- SQLite with WAL mode for better concurrency
- `min_machines_running=1` to prevent autostop
- 1GB RAM (shared-cpu-1x)

**Working:**
- ✅ App serves requests
- ✅ Login/authentication
- ✅ Players auto-imported from `db/seeds/players.yml`
- ✅ Live scoring jobs (SolidQueue in Puma)
- ✅ Health check at `/up` and `/status.json`

**PDF Generation:**
- ✅ Working with `GROVER_NO_SANDBOX=true` env var and async job (avoids 60s proxy timeout)
- Background job generates PDF, attaches to Event via Active Storage
- Turbo Stream broadcasts UI update when generation completes
- Stale detection shows "Update" button when games/scores change

**Useful Commands:**
```bash
fly deploy                    # Deploy new version
fly logs --app family-squares # View logs
fly ssh console              # Shell access (requires WireGuard)
fly machine restart          # Restart the machine
fly scale vm shared-cpu-1x --memory 512  # Adjust memory
```

**Backup Before Deploy:**
```bash
fly ssh sftp get /rails/storage/production.sqlite3 ./backup-$(date +%Y%m%d).sqlite3
```

**Custom Domain:**
- ✅ famsquares.net configured with A/AAAA records pointing to Fly.io
- ✅ www.famsquares.net CNAME configured
- ✅ SSL certificate provisioned via Fly.io

**Email (Resend SMTP):**
- ✅ `SMTP_HOST`, `SMTP_USERNAME`, `SMTP_PASSWORD` secrets configured
- ✅ `APP_HOST=famsquares.net` and `MAIL_FROM` secrets set
- ✅ Domain verified in Resend (SPF on `send` subdomain, DKIM, DMARC)
- ✅ Email with PDF attachment tested end-to-end

**Backup Strategy:**
- Before each deploy: `fly ssh sftp get /rails/storage/production.sqlite3 ./backup-$(date +%Y%m%d).sqlite3`

## Milestone: Full 1.0 Release - August 15, 2026

Target: Ready for football season

| Item | Notes |
|------|-------|
| ~~**Runtime inline styles (public pages)**~~ | ✅ Done - Styles created via UI get `runtime_style: true` flag and render as inline CSS immediately. YAML-imported styles use compiled CSS. Query: `runtime_style = true OR updated_at > DEPLOY_TIMESTAMP`. **Workflow to promote**: Export from container (`rake seeds:export`), copy to host (`docker compose cp` or `fly ssh sftp get`), commit, redeploy. Runtime styles accumulate until this workflow is run - acceptable for emergency mid-event changes, but highlights the "production as canonical source" problem. |
| **Email sending page** | Replace simple dropdown with dedicated page. Left: email preview (like letter_opener). Right: checkbox tree of players grouped by families (no charities), all checked by default with "Uncheck all" control. Allows selective resending to specific players who didn't receive email. Include PDF staleness indicator with "Regenerate PDF" button before sending - better UX than modal warning. |
| ~~**Conference show page redesign**~~ | ✅ Done - Two-column layout: left shows colorized team affiliations list with team styles applied, right shows games grouped by event. Teams display with their default style class. Delete button uses white icon with text-shadow and drop-shadow for visibility against any team color. Controller loads games with eager loading, groups by event. |
| ESPN scraper improvements | Better error handling |
| ~~Transaction wrapper for score processing~~ | ✅ Done - Wrapped `ScoreboardService::ScoreScraper#process_score` and `GamesController#manual_scores` in `ActiveRecord::Base.transaction` blocks. Ensures all period scores update atomically - either all succeed or none do, preventing partial data on failure. |
| **ActivityLog accountability system** | Single audit log table for admin actions and system events. Log: (1) Score updates - automated scraping and manual entry with before/after state, (2) Transaction failures/rollbacks - capture errors with full context for debugging, (3) Game deletions - require `reason` field in UI, store who/when/why, (4) Manual score corrections - log old vs new values for each period, (5) Status changes - track game state transitions (start!, complete!). Simple schema: `user_id`, `action`, `loggable` (polymorphic), `details` (JSON), `created_at`. Provides visibility and accountability without per-model complexity. |
| Scraper registry pattern | Cleaner architecture |
| ~~Document rake tasks~~ | ✅ Done - README documents all export/import tasks and rebuild order |
| **Job queue monitoring** | Email/SMS alerts to admins when Solid Queue worker stalls or queue backs up |
| ~~**Square win probability display**~~ | ✅ Done - Heat map on game#new for football (meaningful digit variation: 7s at 14.6%, 2s at 2.3%). Basketball shows "???" (uniform ~10% each). Dynamically updates when league changes. `SquareProbabilityService` accepts custom frequencies for future extensibility. |
| ~~**Game locking**~~ | ❌ Won't fix - Adds admin overhead (lock step that gets forgotten anyway) and friction for legitimate corrections. Confirmation dialogs + visible status + authenticated admins already prevent fat-finger edits. Manual score entry requires showing admin tools, clicking "manual scores", and entering bad data - already difficult to do accidentally. If admin is careless enough to edit completed game, they'd forget to lock it anyway. |
| **Litestream backups** | Continuous SQLite replication to Cloudflare R2. Replaces manual pre-deploy backups with automatic streaming. Near real-time recovery, point-in-time restore capability. |
| ~~**PDF caching**~~ | ✅ Done - PDFs cached in Active Storage, served if fresh. Stale detection via game/score `updated_at`. `rake storage:purge_unattached` cleans orphaned blobs. |
| **Security audit** | Run Brakeman + bundler-audit. Check: CSRF protection, param filtering, SQL injection, auth bypass, mass assignment. Review Fly.io secrets exposure. Low-value target but protect family fun from griefers. |
| ~~**Query optimization on events#winners**~~ | ✅ Done - Load scores directly with includes for game and league associations |
| **Mobile views (public only)** | (Maybe) Rails request variants for mobile device detection. Event show: vertical stack of game score cards. Game show: score card + player-filtered "your squares" list (dropdown sets cookie for server-side filtering) + stacked winners. Replaces 10x10 grid with simple list view. **⚠️ PUBLIC PAGES ONLY - NO ADMIN MOBILE EVER.** |
| **Production-as-source workflow** | **Philosophy**: Prod database is the source of truth for team data. Repo contains deployment machinery, not canonical data. This is the cost of running a live-event app where style fixes can't wait for deploys (or for you to be at a laptop). Accept it. **Implementation**: Daily R2 sync archives prod state. `rake r2:push` (daily SolidQueue job) runs existing export tasks then uploads YAMLs to R2. `rake r2:pull` downloads to `db/seeds/` for dev sync. Uses `aws-sdk-s3` (R2 is S3-compatible). Same bucket as Litestream. **Safety**: `r2:push` MUST gate on `ENV["FLY_APP_NAME"].present? && Rails.env.production?` - abort with error if either check fails. This prevents accidentally overwriting canonical prod data from dev. **Workflow**: Always pull before modifying team data locally. Never create team/style data in dev - only modify what came from prod. |

### Event PDF Export (Implemented)

- Grover gem (Puppeteer-based) generates landscape Letter PDFs
- Layout: Grid (full-width top), linescores (bottom-left), winners (bottom-right)
- Sort order: Upcoming games (earliest first) → Past games (latest first)
- **Deployment note**: Uses `localhost:PORT` for Puppeteer to fetch stylesheets since Puppeteer runs server-side and can't resolve external hostnames. Verify port routing in Docker/Fly.io.

## Status Endpoint Specification

**Route**: `GET /status.json`

**Purpose**: Quick smoke test for database state, especially useful for mobile verification after deployments

**Response Format**:
```json
{
  "events": 5,
  "games": 42,
  "leagues": 4,
  "conferences": 32,
  "teams": 350,
  "colors": 700,
  "styles": 350
}
```

**Implementation**: StatusController with single JSON action, no authentication required

## Post-1.0 / Future

| Item | Notes |
|------|-------|
| **Fallback platform plan** | Alternative hosting strategy for outage resilience (multi-cloud, static export). Note: Render blocked SMTP on free tier (Sept 2025), limiting viability unless using paid tier or HTTP-based email APIs. |
| **Public Docker release** | Package as self-hosted one-click deploy for offices/groups to run their own squares games. Sidesteps SaaS complexity and gambling compliance - users handle their own local rules. Test on TrueNAS first. |
| **Draft mode for grid selection** | Alternative to random grid: players claim specific squares (office-style pools). Could be first-come-first-served or structured draft order. Note: Chris has patent on automated fantasy drafts - potential IP leverage. |
| **Full data export/import** | Production is canonical source of truth. Need complete export/import for: (1) **Sport structure** (leagues, conferences, teams, affiliations, colors, styles) → version-controlled seed files, (2) **Game operations** (events, games, scores, players) → disaster recovery if redeploying mid-event. Challenge: grid stores player IDs that differ between systems. Solution: `legacy_id` field + ID translation on import. Export tasks already exist for teams/affiliations/players; need events/games/scores export. |
| **Historical game import** | Import games from old system (Google Sheets era). Complex: player list translation between systems, team/league mapping, missing `start_time` data, grid player ID reconciliation. Many unknowns - needs discovery phase before implementation. |
| **Auto-calculate optimal chances** | Algorithm to find best-fit integer chance values given player counts. Constraints: sum to 100, individuals > families (shared winnings), configurable charity allocation. Constrained integer optimization problem. |
| **Double-stroke text styling** | Layered outlines (e.g., Kennesaw State black/gold). Clean approach: `-webkit-text-stroke` for inner stroke, `text-shadow` for outer stroke. This separation allows conditionally disabling only the outer stroke at small font sizes while preserving the inner stroke for readability. Double-stroked text should also get `letter-spacing` adjustment to prevent crowding. |
| **ESPN API full integration** | Audit all places we scrape ESPN HTML and migrate to JSON API where possible. ~~**Migration**: Add `espn_id`, `espn_mens_slug`, `espn_womens_slug` to Teams.~~ ✅ Done - all 397 teams have ESPN IDs/slugs. **Scraper registry**: `EspnApiScraper` as primary, `EspnHtmlScraper` as fallback, same interface. **Potential wins**: (1) Score scraper via API, (2) Team colors/logos from API, (3) Cleaner game status. Document rate limits and caching strategy. See `artifacts/espn_api_sample.json`. |
| **Team logos as local assets** | Build logo directory indexed by `css_slug`. Seed initially from ESPN API URLs, maintain locally. Self-hosted, no runtime external dependency. |
| **External asset storage** | Configure Rails to serve assets from external storage (S3, Cloudflare R2, etc.) to avoid disk bloat on Fly.io. Active Storage supports multiple backends. Logos (~350 teams × ~50KB) would be ~17MB initially but plan for growth and multiple sports. |
| **Conference realignment detection** | Scrape ESPN standings pages to detect conference membership changes. Compare against current affiliations, generate diff report showing teams that moved. Dry-run mode previews changes; `--apply` updates affiliations. Useful for annual realignment (e.g., Mountain West → Pac-12 migrations for 2026 football). Infrastructure already exists: `script/data/*.json` standings files contain team-to-conference mappings via ESPN IDs. |
| **Gradient/animated text styles** | Team branding (e.g., Seahawks iridescent green). CSS gradients on text, possibly animated. |
| **Text-stroke lightness slider** | HSL adjustment for readability tuning. Fine-tune stroke color relative to background. |
| **Family-selected charities** | (Governance proposal pending) Allow each family/single to choose a favorite charity. Charities would be associated with families and have `chances` based on selection count (e.g., if two families pick World Central Kitchen, it gets double chances). Would require rethinking current Charity model where chances=0 and family_id=null. |
| **Historical digit frequency computation** | Replace hardcoded probability data with frequencies computed from our own game history. Job runs on event completion: tallies final score digits by sport, stores computed frequencies (JSON column or dedicated table). Need 100+ games per sport for statistical significance. Could offer toggle between "published averages" and "our history" once sample size is meaningful. |

## Ongoing Monitoring

Items that are "done" but need periodic attention as the app scales or usage patterns change.

| Item | Notes |
|------|-------|
| **Query performance on events#show** | Currently 42 queries (~114ms) for a small event. Dense events (70+ games like football season) may need further optimization. Watch for: `_game_score_card` per-period queries, partial rendering overhead. |
| **SolidQueue database locks** | Fixed with `processes: 0` in dev. Monitor production for any lock contention under load. |
| **Admin toolbar toggle** | Fixed multiple times (button_to → link_to with Turbo method). Bootstrap dropdown + form interaction causes click handler issues. If multi-click problem recurs, may need to move outside dropdown or use custom JavaScript. |

## Small Fixes (No Milestone)

| Item | Notes |
|------|-------|
| ✅ Team stylesheet `!important` override | Add `!important` to `background-color` and `color` in generated styles to override Falcon theme table styles |
| ✅ **Game status transitions via ActionCable** | Done - `broadcast_status_change` in Game model calls `Turbo::StreamsChannel.broadcast_refresh_to` on `start!` and `complete!`. Page auto-refreshes on status transitions. |
| ~~Tabs controller Turbo cache issue~~ | ✅ Resolved - No recurrence observed, likely fixed by other Turbo/Stimulus changes |
| ✅ Action Text links load in frame | Fixed - Stimulus controller `action_text_links_controller.js` adds `data-turbo-frame="_top"` to all links on connect |
| ✅ Posts UI: add edit links | Edit button in post content header, cancel returns to event#posts |
| ✅ Posts UI: active post styling | Done - Chevron icon + highlight on active post, Stimulus controller tracks selection |
| ✅ Winners table period display | Done - Individual winning periods column is hard to read. Consider reformatting (badges, commas, grouping by game) for better scannability. Tooltip added to show game title and period identifier. |
| ✅ **Player form: Charity type handling** | Done - Stimulus controller disables Family dropdown and sets Chances to 0 when Charity type selected. Note: May need revisiting if governance approves family-selected charities proposal. |
| ✅ **Unique Games by score_url** | Done - Added unique index on `games.score_url` and model validation. Prevents duplicate game creation from same ESPN URL. |
| ✅ **Admin toolbar toggle UX** | Done - Changed from `button_to` (form) to `link_to` with Turbo method. Forms inside Bootstrap dropdowns had click handler interference. Now works on first click. |
| ✅ **Team field labels as links** | Done - Away/Home team labels dynamically link to team show page when team selected. Added `updateTeamLabel` method in game_form controller, clears on league change. |
| ~~**Team dropdown tab order**~~ | **Not fixable** - Choices.js fundamentally doesn't support keyboard tab navigation. Investigated tabindex on container, focus forwarding to input, and exposing hidden select. All approaches failed. Would require replacing Choices.js with different library or native selects. Accepting limitation - users can click or use mouse to access dropdowns. |
| ✅ **Events dropdown structure** | Done - Active/in-progress events at top (ordered by start_date DESC), separator, 10 most recent completed events (ordered by end_date DESC), "Older..." link at bottom. Clean, scannable structure. |
| ✅ **Conference links on League show** | Done - Conference names in card headers now link to Conference#show page. Simple one-line change wrapping display_name in link_to. |
| ✅ **schema.yaml sync** | Done - Updated to match current db/schema.rb. Removed DIVISION model, updated TEAM (removed prefix/suffix, changed brand_url→brand_info, added display_location/espn fields), added LEAGUE fields (sport/espn_slug/periods), updated STYLE (added name/runtime_style). **Note**: Update this file when making schema changes. |
| ✅ **Orphan CSS cleanup** | Done - Added to `rake styles:regenerate_all` as final cleanup step. Deletes any `_*.scss` files in teams/ that don't match a current team's `css_slug`. |
| ~~**Color/Style edit deployment warning**~~ | ✅ Moot - Runtime inline styles feature makes changes visible immediately. No warning needed. |
| ✅ **Hide PDF button if no games** | Done - Wrapped PDF status partial content in `event.games.any?` check. No PDF UI shown if event has no games. |
| ✅ **Delete button for scoreless games** | Done - Added delete button on Game#edit page (in header alongside "Swap Teams"). Only shows if `@game.scores.empty?`. Confirmation dialog prevents accidental deletion. |

---

**Last Updated**: 2026-02-04