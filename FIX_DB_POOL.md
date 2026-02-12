# Fix Database Connection Pool Exhaustion

## Problem

**Development**: ActiveJob :async adapter creates 4-10 worker threads + 3 Puma threads = 7-13 threads competing for connections

**Production**: SolidQueue runs inside Puma (SOLID_QUEUE_IN_PUMA=true), sharing the same connection pool:
- 3 Puma worker threads
- 2-3 SolidQueue workers
- Long-running PDF generation jobs
= Pool exhaustion and "database is locked" errors

## Solution

### 1. Updated database.yml (✅ Done)

**Development**: Now uses `pool: 15` for primary and queue databases

**Production**: Now defaults to `pool: 10` (configurable via `DB_POOL` env var)

This gives us:
- 3 Puma threads
- 2-3 SolidQueue workers
- 2-4 buffer connections
= 10 total (safe margin)

### 2. Restart development server
```bash
# Kill the server and restart to pick up new connection pool size
bin/dev
```

### 3. Deploy to production with retry logic
The GenerateEventPdfJob now has:
- Job-level retry: `retry_on ActiveRecord::StatementTimeout, wait: 5.seconds, attempts: 3`
- Log-level retry: `log_with_retry` helper with exponential backoff
- Graceful degradation: Logging failures don't fail the job

```bash
fly deploy
fly logs --app family-squares
```

Watch for successful PDF generation without database lock errors.

### 4. Optional: Override pool size on Fly.io
If you still see issues, increase further:
```bash
fly secrets set DB_POOL=15
```

## Alternative: Separate SolidQueue Process
If problems persist, consider running SolidQueue in a separate process:
1. Remove `SOLID_QUEUE_IN_PUMA` from fly.toml
2. Add a separate `[processes]` section for workers
3. Scale workers independently

This is more complex but provides better isolation for production at scale.
