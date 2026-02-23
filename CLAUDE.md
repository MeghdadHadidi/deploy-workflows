# Deploy Workflows — CLAUDE.md

## What This Is
Shared reusable GitHub Actions workflows for all Mockiato apps. No application code.

## Tech Stack
GitHub Actions YAML workflows

## Git Rules (MANDATORY — NO EXCEPTIONS)
1. ALWAYS branch from `dev`: `git checkout dev && git pull origin dev && git checkout -b feat/...`
2. ALWAYS PR to `dev`: `gh pr create --base dev`
3. NEVER push to or PR against `main`
4. Workflow files (.github/workflows/*.yml) may be pushed directly to dev

## Skills
Read these before working:
- SDLC + git flow: ~/shared-skills/sdlc-engine/SKILL.md (REQUIRED)
- Deploy/CI: ~/shared-skills/deploy-pipeline/SKILL.md

## Key Paths
- Workflows: .github/workflows/

## Workflow Inputs
Required:
- `app_name`: Application name for deployment

Optional:
- `app_port`: Port the app runs on
- `docker_build_args`: Additional Docker build arguments
- `spa_mode`: Single-page app mode flag
- `skip_release`: Skip release creation
- `environment`: Target environment

## Required Secrets
- `DEPLOY_SSH_KEY`: SSH key for deployment server (required)
- `DEPLOY_HOST`: Deployment host address (required)
