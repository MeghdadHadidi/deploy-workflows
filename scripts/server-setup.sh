#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# One-time server setup for the deploy workflow
# Run this on the app server (root@188.245.45.64)
# ──────────────────────────────────────────────────────────
set -euo pipefail

echo "═══ Server Setup for Deploy Workflows ═══"

# ── 1. Ensure Docker is installed ────────────────────────
if ! command -v docker &>/dev/null; then
  echo "→ Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
else
  echo "✓ Docker is installed ($(docker --version))"
fi

# ── 2. Ensure the app network exists ────────────────────
NETWORK="coolify"
if docker network ls --format '{{.Name}}' | grep -q "^${NETWORK}$"; then
  echo "✓ Docker network '${NETWORK}' exists"
else
  echo "→ Creating Docker network '${NETWORK}'..."
  docker network create "$NETWORK"
fi

# ── 3. Ensure Caddy Docker Proxy is running ─────────────
CADDY_CONTAINER="coolify-proxy"
if docker ps --format '{{.Names}}' | grep -q "^${CADDY_CONTAINER}$"; then
  echo "✓ Caddy Docker Proxy is running"
else
  echo "→ Starting Caddy Docker Proxy..."
  docker run -d \
    --name "$CADDY_CONTAINER" \
    --network "$NETWORK" \
    --restart unless-stopped \
    -p 80:80 \
    -p 443:443 \
    -p 443:443/udp \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v caddy_data:/data \
    lucaslorentz/caddy-docker-proxy:2.8-alpine
  echo "✓ Caddy Docker Proxy started"
fi

# ── 4. Create deploy directories ────────────────────────
mkdir -p /opt/deploys
echo "✓ Deploy directory /opt/deploys exists"

# ── 5. Verify SSH key access ────────────────────────────
echo ""
echo "═══ Setup Complete ═══"
echo ""
echo "Next steps:"
echo "  1. Generate a deploy SSH key (if not done):"
echo "     ssh-keygen -t ed25519 -f deploy_key -N '' -C 'github-deploy'"
echo ""
echo "  2. Add the PUBLIC key to this server:"
echo "     cat deploy_key.pub >> ~/.ssh/authorized_keys"
echo ""
echo "  3. Add these secrets to your GitHub repos (or org):"
echo "     DEPLOY_SSH_KEY  = contents of deploy_key (private key)"
echo "     DEPLOY_HOST     = $(hostname -I | awk '{print $1}')"
echo ""
echo "  4. Add the caller workflow to your repo:"
echo "     cp templates/caller.yml your-repo/.github/workflows/deploy.yml"
echo ""
