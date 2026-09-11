---
name: u59-production
description: Inspect and verify services on a configured production server. Use for Docker Compose status/logs, safe health checks, deployment watching, and production diagnosis.
---

# Production Server

Use this skill for safe production inspection and verification on the configured
production server.
Assume production access is powerful: inspect first, change only when the user
or repo-local deployment docs clearly authorize it.

## Access

- Before connecting, source `~/.rc/infrastructure.env`. It must set
  `PROD_SSH_TARGET` and `PROD_HEALTH_HOST`. If either is absent, ask the user
  rather than guessing.
- Prefer non-interactive, narrowly scoped commands:

```bash
ssh "$PROD_SSH_TARGET" "hostname && pwd"
```

- Do not print secrets, environment files, tokens, private keys, or credential
  values. If a command might expose them, filter or summarize locally.

## Safety Rules

- Start with read-only inspection: `docker ps`, `docker compose ps`, logs,
  health endpoints, disk usage, service status.
- Avoid destructive commands such as volume removal, database mutation,
  `docker system prune`, broad `rm`, or service restarts unless explicitly
  requested or required by a repo-local deploy procedure.
- Touch only the project resources relevant to the current task.
- Prefer the project's repo-local `just deploy`, `docker-compose.prod.yml`,
  README, `AGENTS.md`, or `CLAUDE.md` instructions over generic commands.
- When credentials are needed, read them only on the server or from the
  repo-approved secret store; never echo secret values into chat.

## Discover A Deployment

Use narrow discovery instead of assuming paths:

```bash
ssh "$PROD_SSH_TARGET" "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'"
ssh "$PROD_SSH_TARGET" "find ~ -maxdepth 3 -name docker-compose.prod.yml -o -name compose.prod.yml 2>/dev/null"
```

For a known project directory:

```bash
ssh "$PROD_SSH_TARGET" "cd /path/to/project && git status --short && docker compose -f docker-compose.prod.yml ps"
```

## Verify Production

Use the narrowest check that proves the deployed behavior:

```bash
ssh "$PROD_SSH_TARGET" "docker ps --filter name=PROJECT --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
curl -fsS "http://$PROD_HEALTH_HOST:PORT/health"
curl -fsS "http://$PROD_HEALTH_HOST:PORT/api/health"
```

If an authenticated check is required, source or read credentials without
printing them, then print only status codes or redacted summaries.

## Logs And Diagnosis

For Docker Compose deployments:

```bash
ssh "$PROD_SSH_TARGET" "cd /path/to/project && docker compose -f docker-compose.prod.yml logs --tail=200 SERVICE"
```

For containers discovered by name:

```bash
ssh "$PROD_SSH_TARGET" "docker logs --tail=200 CONTAINER"
```

Use timestamps and bounded tails for logs. Do not paste large logs into final
answers; summarize the relevant error lines.

## Deploy Or Restart

Deploy only via the project-approved path, typically one of:

```bash
ssh "$PROD_SSH_TARGET" "cd /path/to/project && just deploy"
ssh "$PROD_SSH_TARGET" "cd /path/to/project && docker compose -f docker-compose.prod.yml up -d --build"
```

Before deploying, confirm the intended project directory, current branch or
commit, and repo-local deployment instructions. After deploying, verify
containers and the relevant HTTP/API behavior.

## Project Hints

- Prefer watching CI/deploy runs before connecting when the project uses a
  self-hosted runner.
- Discover service ports and deployment commands from the repository's
  `README`, `justfile`, compose files, CI, `AGENTS.md`, or `CLAUDE.md`.
