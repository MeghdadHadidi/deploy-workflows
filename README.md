# deploy-workflows

Reusable GitHub Actions workflow for deploying Docker containers to a Hetzner app server with automatic Caddy reverse proxy configuration.

## How It Works

```
Push to main  →  Build on server  →  Deploy to {app}.meghd.space
Open PR        →  Build on server  →  Deploy to {app}-pr-{n}.meghd.space
Close PR       →  Remove preview container
```

1. Source code is copied to the server via SSH (tar + pipe)
2. Docker image is built directly on the server
3. Container runs with Caddy Docker Proxy labels for automatic HTTPS routing
4. Old containers and images are cleaned up automatically

## Quick Start

### 1. Add secrets to your repo (or GitHub org)

| Secret | Value |
|--------|-------|
| `DEPLOY_SSH_KEY` | SSH private key for the app server |
| `DEPLOY_HOST` | `188.245.45.64` |

### 2. Add the workflow to your repo

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize, closed]

jobs:
  deploy:
    uses: MeghdadHadidi/deploy-workflows/.github/workflows/deploy.yml@main
    with:
      app_name: myapp
    secrets: inherit
```

### 3. Ensure your repo has a Dockerfile

That's it. Push to main and it deploys.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `app_name` | Yes | — | Subdomain name (`mocket` → `mocket.meghd.space`) |
| `app_port` | No | `80` | Port your app listens on inside the container |
| `domain` | No | `meghd.space` | Base domain |
| `dockerfile_path` | No | `./Dockerfile` | Path to Dockerfile |
| `docker_build_args` | No | — | Newline-separated `KEY=VALUE` build args |
| `docker_run_args` | No | — | Extra `docker run` flags |
| `spa_mode` | No | `true` | Enable `try_files` fallback for SPAs |

## Deployment URLs

| Trigger | URL Pattern | Container Name |
|---------|-------------|----------------|
| Push to main | `https://{app_name}.meghd.space` | `{app_name}` |
| PR opened/updated | `https://{app_name}-pr-{n}.meghd.space` | `{app_name}-pr-{n}` |

Preview URLs are automatically commented on the PR.

## Examples

### Basic SPA (React/Next.js)

```yaml
jobs:
  deploy:
    uses: MeghdadHadidi/deploy-workflows/.github/workflows/deploy.yml@main
    with:
      app_name: myapp
    secrets: inherit
```

### Node.js API server

```yaml
jobs:
  deploy:
    uses: MeghdadHadidi/deploy-workflows/.github/workflows/deploy.yml@main
    with:
      app_name: myapi
      app_port: '3000'
      spa_mode: false
    secrets: inherit
```

### With build args

```yaml
jobs:
  deploy:
    uses: MeghdadHadidi/deploy-workflows/.github/workflows/deploy.yml@main
    with:
      app_name: myapp
      docker_build_args: |
        NODE_ENV=production
        NEXT_PUBLIC_API_URL=https://api.example.com
    secrets: inherit
```

## Environment Variables

For runtime env vars, create an `.env` file on the server at:

```
/opt/deploys/{app_name}/.env
```

If present, it's automatically loaded via `--env-file`.

## Server Setup

Run the setup script on a fresh server:

```bash
bash scripts/server-setup.sh
```

This ensures Docker, the `coolify` network, and Caddy Docker Proxy are ready.

## Architecture

```
GitHub Actions Runner          App Server (Hetzner)
┌──────────────────┐          ┌────────────────────────────────┐
│  Checkout repo   │          │                                │
│  tar + SSH pipe  │────────→ │  /opt/deploys/{app}/src/       │
│                  │          │  docker build → docker run     │
└──────────────────┘          │                                │
                              │  Caddy Docker Proxy            │
                              │  (auto-discovers containers    │
                              │   via Docker labels)           │
                              │       ↓                        │
                              │  https://{app}.meghd.space     │
                              └────────────────────────────────┘
```

## Concurrency

Deploys are serialized per app + environment. If a new deploy starts while one is in progress, the old one is cancelled. This prevents race conditions during Docker build/run.

## Cleanup

- Old Docker images are pruned after each deploy (keeps last 3)
- Preview containers are removed when PRs are closed
- Build sources live at `/opt/deploys/{app}/src/` and are overwritten each deploy
