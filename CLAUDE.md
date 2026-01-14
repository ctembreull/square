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

### Pending
- Add validation: active player chances must sum to ≤100
- Adapt PostgreSQL virtual column syntax to SQLite3 (teams.search_index)
- Document rake tasks more clearly: `sports:generate_seeds` (Ruby seeds.rb), `seeds:export`/`seeds:import` (YAML with colors/styles), `styles:regenerate_all` (SCSS files) - clarify when each should be used

## Architecture Patterns

### Service Objects
- Base class: `ApplicationService`
- Scraper hierarchy: `BaseScraper` → `EspnScraper`, `SrCfbScraper`
- Main orchestrator: `ScoreboardService::ScoreScraper`

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

## Next Steps (Priority Order)

1. ✅ **Finalize unified schema.rb** - Reconcile old schema with new requirements
2. ✅ **Integrate Falcon SASS** - Theme fully integrated with working JavaScript
3. ✅ **Sports Admin CRUD** - Complete CRUD for Leagues, Conferences, Teams
4. **Status/Health Endpoint** - JSON API with database counts for smoke testing (Events, Games, Leagues, Conferences, Teams, Colors, Styles)
5. **Deploy to Fly.io** - Configure and deploy application
6. Fix grid generation bug (charity → charities)
7. Implement grid validation (Player.total_active_chances)
8. Build seed data for all D1 teams
9. Set up ActionMailer for Fly.io
10. Implement post editor with game list sidebar

## Post-Release Features

- Filter box for game list in post editor
- ESPN scraper improvements (WinnerCalculator service, better error handling)
- Transaction wrapper for score processing
- Scraper registry pattern

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

---

**Last Updated**: 2026-01-12