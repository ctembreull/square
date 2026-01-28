# Puppeteer/Grover PDF Generation on Fly.io - Troubleshooting Plan

**Created**: 2026-01-28
**Status**: Research complete, implementation pending
**Problem**: PDF generation via Grover/Puppeteer works locally but crashes silently on Fly.io

---

## Background

The Family Squares app uses the Grover gem (a Ruby wrapper around Puppeteer) to generate PDF exports of event grids. This works perfectly in local development but fails silently on Fly.io, even with 1GB RAM allocated.

### Current Behavior
- Local: PDFs generate correctly
- Fly.io: Silent failure, no error messages in logs
- Workaround: Generate PDFs locally before deployment

### Architecture
- Grover gem → shells out to Node.js → runs Puppeteer → controls headless Chromium
- Puppeteer fetches the page via `localhost:PORT` to render HTML with stylesheets
- Chromium renders the page and outputs PDF

---

## Research Findings

### Source 1: Fly.io Community - "How can I run Puppeteer on Fly.io"
**URL**: https://community.fly.io/t/how-can-i-run-puppeteer-on-fly-io/5435/6

**Key Insight**: Use a purpose-built Docker base image that bundles Chromium and Node.js together, rather than installing them separately.

**Recommended Approach**:
```dockerfile
FROM zenika/alpine-chrome:89-with-node-14

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy application code
COPY . .

# CRITICAL: Tell Puppeteer where to find the pre-installed browser
ENV PUPPETEER_EXECUTABLE_PATH='/usr/bin/chromium-browser'

EXPOSE 8080
CMD ["node", "app.js"]
```

**Why This Works**:
- The `zenika/alpine-chrome` image is specifically designed for Puppeteer workloads
- Chromium is pre-installed and configured for headless operation
- Node.js is included and properly pathed
- Eliminates dependency mismatch between dev and prod environments

**Critical Configuration**: The `PUPPETEER_EXECUTABLE_PATH` environment variable MUST be set explicitly. Without it, Puppeteer tries to find/download its own Chromium and fails.

---

### Source 2: Fly.io Community - "Error when executing Puppeteer"
**URL**: https://community.fly.io/t/error-when-executing-puppeteer/10395

**Initial Error Message**:
```
Could not find Chromium (rev. 1083080). This can occur if either:
1. you did not perform an installation before running the script (e.g. `npm install`)
2. your cache path is incorrectly configured
```

**Root Cause**: Chromium wasn't installed in the deployment container, and Puppeteer couldn't download it automatically (network restrictions, permissions, or missing dependencies).

**Failed Attempts**:
1. Using `zenika/alpine-chrome:with-node` without proper env vars - didn't work
2. Setting `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1` without providing executable path - Docker build error about missing `/app/bin/*`

**Working Solution for Node.js Apps**:
```dockerfile
FROM node:slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gnupg \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Add Google Chrome repository and install
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Critical environment variables
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV GROVER_NO_SANDBOX=true
```

**Grover-Specific Discovery (November 2024)**:
A later deployment attempt revealed that Grover couldn't locate Node.js in the final container stage of a multi-stage Docker build.

**The Fix**: Copy Node.js from the build stage and update PATH:
```dockerfile
# In final stage
COPY --from=build /usr/local/node /usr/local/node
ENV PATH="/usr/local/node/bin:$PATH"
```

**This is likely our issue** - Grover needs Node.js available at runtime to shell out to Puppeteer, and in a multi-stage Rails Dockerfile, Node.js might only exist in the build stage (for asset compilation) but not in the final runtime stage.

---

## Required Environment Variables

Based on the research, these environment variables should be set:

| Variable | Value | Purpose |
|----------|-------|---------|
| `GROVER_NO_SANDBOX=true` | `true` | Disables Chrome sandbox (required in containers without proper permissions) |
| `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` | `true` | Prevents Puppeteer from trying to download Chromium at runtime |
| `PUPPETEER_EXECUTABLE_PATH` | `/usr/bin/chromium` or `/usr/bin/chromium-browser` or `/usr/bin/google-chrome` | Tells Puppeteer where the browser executable is located |

---

## Likely Root Causes for Our Silent Failure

### Theory 1: Node.js Not Available in Runtime Container (HIGH PROBABILITY)
Rails multi-stage Dockerfiles typically:
1. Use a Node.js-enabled image for the BUILD stage (asset compilation)
2. Use a slim Ruby image for the RUNTIME stage (no Node.js)

Grover needs to shell out to Node.js to run Puppeteer. If Node.js isn't in the final image, Grover fails silently.

**Diagnostic**: SSH into Fly.io container and run `which node` or `node --version`

**Fix**: Copy Node.js binary from build stage to runtime stage, or install Node.js in runtime stage.

### Theory 2: Missing GROVER_NO_SANDBOX Environment Variable (MEDIUM PROBABILITY)
Chrome's sandbox requires specific kernel capabilities that may not be available in Fly.io's container environment. Without `GROVER_NO_SANDBOX=true`, Chrome may crash immediately on launch.

**Diagnostic**: Check if this env var is set in fly.toml or Dockerfile

**Fix**: Add `GROVER_NO_SANDBOX=true` to environment

### Theory 3: PUPPETEER_EXECUTABLE_PATH Not Set or Wrong (MEDIUM PROBABILITY)
If Puppeteer can't find Chrome/Chromium, it either tries to download it (fails) or crashes.

**Diagnostic**:
- Check if env var is set
- SSH in and verify the path exists: `ls -la /usr/bin/chromium*` or `ls -la /usr/bin/google-chrome*`

**Fix**: Set correct path based on what's actually installed

### Theory 4: Chromium Not Actually Installed (LOW PROBABILITY)
The Dockerfile may have Chromium installation commands that fail silently or are in the wrong build stage.

**Diagnostic**: SSH in and try to run `chromium --version` or `google-chrome --version`

**Fix**: Ensure Chromium installation happens in the final runtime stage, not just build stage

### Theory 5: Memory/OOM Issues (LOW PROBABILITY - Already Have 1GB)
Chromium can be memory-hungry, but 1GB should be sufficient for single-page PDF generation.

**Diagnostic**: Check Fly.io metrics/logs for OOM kills

**Fix**: Increase memory if needed, or add Chromium launch args to limit memory usage

---

## Implementation Plan

### Phase 1: Diagnostics (Do First)
1. SSH into Fly.io container: `fly ssh console`
2. Check Node.js availability: `which node && node --version`
3. Check Chromium availability: `which chromium || which chromium-browser || which google-chrome`
4. Check environment variables: `env | grep -i "grover\|puppeteer"`
5. Try running Chromium manually: `chromium --headless --disable-gpu --dump-dom https://example.com`

### Phase 2: Quick Fixes (Try These First)
1. Add missing environment variables to `fly.toml`:
   ```toml
   [env]
     GROVER_NO_SANDBOX = "true"
     PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = "true"
     PUPPETEER_EXECUTABLE_PATH = "/usr/bin/chromium"  # verify path first
   ```

2. If Node.js is missing, add to Dockerfile's final stage:
   ```dockerfile
   # Copy Node.js from build stage (adjust paths as needed)
   COPY --from=build /usr/local/node /usr/local/node
   ENV PATH="/usr/local/node/bin:$PATH"
   ```

### Phase 3: Dockerfile Overhaul (If Quick Fixes Don't Work)
If the above doesn't work, consider restructuring the Dockerfile to ensure all Puppeteer dependencies are in the runtime stage:

1. Review current Dockerfile structure
2. Ensure Chromium is installed in final stage (not just build stage)
3. Ensure Node.js is available in final stage
4. Set all required environment variables
5. Consider using `zenika/alpine-chrome` as base or reference

### Phase 4: Alternative Approaches (If All Else Fails)
1. **DocRaptor**: Cloud-based PDF generation service. Same HTML input, different backend. Has test mode for prototyping. Trade-off: external dependency, potential cost.

2. **Pre-generate PDFs locally**: Current workaround. Generate before deploy, cache in Active Storage.

3. **Separate PDF microservice**: Deploy a dedicated Puppeteer container on Fly.io that the Rails app calls via HTTP. Isolates the complexity.

---

## Useful Commands

```bash
# SSH into Fly.io container
fly ssh console --app family-squares

# Check logs for errors
fly logs --app family-squares

# Set environment variables
fly secrets set GROVER_NO_SANDBOX=true --app family-squares

# Check current secrets/env
fly secrets list --app family-squares

# Restart after changes
fly machine restart --app family-squares

# Check memory usage
fly machine status --app family-squares
```

---

## References

- Fly.io Community: [How can I run Puppeteer on Fly.io](https://community.fly.io/t/how-can-i-run-puppeteer-on-fly-io/5435/6)
- Fly.io Community: [Error when executing Puppeteer](https://community.fly.io/t/error-when-executing-puppeteer/10395)
- Grover gem: https://github.com/Studiosity/grover
- Puppeteer troubleshooting: https://pptr.dev/troubleshooting

---

## Success Criteria

PDF generation is working on Fly.io when:
1. Event PDF export button generates and downloads a PDF
2. No silent failures or timeouts
3. Logs show successful Chromium/Puppeteer execution
4. Works consistently across deploys
