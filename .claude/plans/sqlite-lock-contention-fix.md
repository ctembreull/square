# Fix: SQLite Lock Contention in Score Refresh Jobs

## Problem

`RefreshActiveGamesJob` fans out one `RefreshGameScoresJob` per active game via `perform_later`. With 2+ concurrent games, the individual jobs run in parallel (3 threads in `config/queue.yml`) and their database transactions collide, producing `SQLite3::BusyException` despite the 10-second `busy_timeout`.

Observed twice in dev with games 25 & 26 on 2026-02-19. Will get worse during March Madness (8+ simultaneous games) and football season (16+ games on a Sunday).

## Root Cause

All jobs share one worker pool (`queues: "*"`, `threads: 3`). When multiple `RefreshGameScoresJob` instances run concurrently, each one:
1. Calls `ScoreScraper.call(game)` which does HTTP fetch + score processing inside a transaction
2. The transaction includes destroy/recreate of Score records + ActivityLog writes
3. SQLite allows only one writer at a time — concurrent transactions queue behind the write lock
4. With enough contention, `busy_timeout` is exceeded

## Fix: Dedicated `scoring` Queue with 1 Thread

### Step 1: Add queue declaration to RefreshGameScoresJob

**File**: `app/jobs/refresh_game_scores_job.rb`

Change line 2:
```ruby
# Before
queue_as :default

# After
queue_as :scoring
```

That's it for the job. `RefreshActiveGamesJob` stays on `:default` — it just enqueues work, no DB contention.

### Step 2: Update queue.yml

**File**: `config/queue.yml`

```yaml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "default"
      threads: 3
      processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>
      polling_interval: 0.1
    - queues: "scoring"
      threads: 1
      processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>
      polling_interval: 0.1

development:
  <<: *default
  workers:
    - queues: "default"
      threads: 3
      processes: 0
      polling_interval: 0.1
    - queues: "scoring"
      threads: 1
      processes: 0
      polling_interval: 0.1

test:
  <<: *default

production:
  <<: *default
  workers:
    - queues: "default"
      threads: 3
      processes: 0
      polling_interval: 0.1
    - queues: "scoring"
      threads: 1
      processes: 0
      polling_interval: 0.1
```

### Why `processes: 0` in production

On Fly.io (1GB RAM, shared-cpu-1x), forking separate worker processes for each queue would roughly double worker memory. Using `processes: 0` runs both worker pools **in-process with Puma** — same as the current dev setup.

The serial write guarantee comes from `threads: 1` on the scoring queue, not from process isolation. One thread = one job at a time = no concurrent DB writes from score scraping. This works regardless of whether the worker is forked or in-process.

**Trade-off**: A slow score scrape (network timeout, ESPN latency) briefly occupies one of Puma's threads. At our traffic level (family app, single admin) this is negligible. If traffic ever warranted it, we could switch production to `processes: 1` and accept the memory cost.

### Why `processes: 0` in development

Same as current behavior — avoids SQLite lock issues with forked processes accessing the same database file. Already proven stable.

### Why the default block keeps `processes: 1`

The `default` block with `JOB_CONCURRENCY` env var serves as documentation and a fallback for any future environments. Dev and production both override it explicitly.

## What NOT to change

- `RefreshActiveGamesJob` stays on `:default` — it's a fast fan-out job with no write contention
- `QueueHeartbeatJob` stays on `:default` — lightweight cache write, no DB contention
- `R2PushJob` stays on `:default` — runs at 3am, no overlap with live scoring
- No changes to `busy_timeout`, retry logic, or scraper code

## Verification

After deploying:
1. Create 2+ games with valid ESPN URLs and overlapping start times
2. Watch logs for `[RefreshGameScoresJob] Completed scrape` messages — they should appear sequentially (one finishes before the next starts), not interleaved
3. No `SQLite3::BusyException` in logs
4. Confirm heartbeat still works (`/status.json` returns 200)
5. Confirm default queue jobs still process (e.g., `R2PushJob`, `QueueHeartbeatJob`)

## Rollback

If the fix causes issues, revert both files:
1. `config/queue.yml` — restore `queues: "*"` single worker pool
2. `app/jobs/refresh_game_scores_job.rb` — change back to `queue_as :default`

The old behavior (occasional `BusyException` with retry) is degraded but functional — better than broken scoring.
