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
- (See milestone tables for tracked work items)

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
- Scopes for filtering by status (`active`, `inactive`, `current`)
- Manual action methods for state transitions (`end_event!`, `deactivate!`)

### Navigation Patterns
- Dynamic dropdowns populated from scopes (e.g., `Event.active.current`)
- Home route redirects to current item or falls back to index
- "Older..." link convention for accessing full index from dropdown

### Barebones Model Strategy
- When a feature depends on an unbuilt model, create minimal version with just associations
- Prevents rabbit holes while unblocking dependent features
- Document that model needs expansion when its feature is built

## Completed

- ✅ **Finalize unified schema.rb** - Reconcile old schema with new requirements
- ✅ **Integrate Falcon SASS** - Theme fully integrated with working JavaScript
- ✅ **Sports Admin CRUD** - Complete CRUD for Leagues, Conferences, Teams

## Milestone: Testing Deployment - March 15, 2026

Target: NCAA Tournament testing on Fly.io

| Item | Notes |
|------|-------|
| Status/Health Endpoint | JSON API for smoke testing after deploy |
| Deploy to Fly.io | Infrastructure setup and configuration |
| Set up ActionMailer | Email delivery via Resend |
| Build seed data for all D1 teams | ~350 teams ready for any matchup |
| Grid validation (Player.total_active_chances) | Prevent bad game creation |
| Query optimization on leagues/show | Performance fix (eager loading/caching) |
| Active player chances validation | Sum must be ≤100 |
| **Posts feature** | Event emails with game list sidebar (resilience: manual email fallback) |
| **Event PDF Export** | Printable grids for family (see spec below) |
| **Full Dockerization** | Ensure app runs locally with production data as fallback |
| **Grid export button (admin)** | 10x10 player names in TSV format → clipboard for Apple Numbers |
| **Scores export button (admin)** | Period scores in TSV format → clipboard for Apple Numbers |
| **Manual score input modal (admin)** | Direct score entry/creation when ESPN or fallback scrapers fail |
| **WinnerCalculator service** | Determine winners from scraped scores |
| **Public/Admin View Separation** | Fun public UI vs Falcon admin (plan: `.claude/plans/mighty-greeting-cosmos.md`) |

## Milestone: Full 1.0 Release - August 15, 2026

Target: Ready for football season

| Item | Notes |
|------|-------|
| ESPN scraper improvements | Better error handling |
| Transaction wrapper for score processing | Data integrity |
| Scraper registry pattern | Cleaner architecture |
| Document rake tasks | Clarify generate_seeds vs export/import vs regenerate_all |
| Replace h1 headers with hero cards | Visual polish |
| Gradient/animated text styles | Team branding (e.g., Seahawks iridescent green) |
| Text-stroke lightness slider | HSL adjustment for readability tuning |
| **Job queue monitoring** | Email/SMS alerts to admins when Solid Queue worker stalls or queue backs up |

### Event PDF Export Spec

- Generate printable PDF of all games in an event
- Layout: Grid (full-width top), linescores (bottom-left), winners (bottom-right)
- Sort order: Upcoming games (earliest first) → Past games (latest first)
- Distribution: Download button on event page + optional attachment on Post emails
- Use HTML-to-PDF approach (WickedPDF or Grover) to reuse existing grid partials
- Serves tech-hesitant family members who prefer familiar PDF/email format

### Public/Admin View Separation Spec

- Same routes, different views based on user role
- Admin: Falcon-styled management interface
- Public: Fun game-focused interface using welcome widgets
- Admin preview mode (`?preview=true`) to see public view

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
| **Fallback platform plan** | Alternative hosting strategy for outage resilience (multi-cloud, static export) |

---

**Last Updated**: 2026-01-17