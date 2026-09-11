---
name: home-assistant
description: Operate a configured Home Assistant instance over SSH. Use for Home Assistant YAML/configuration, automations, scenes, entity registry entries, recorder state, and Supervisor/API operations.
---

# Home Assistant

Operate the configured Home Assistant instance safely over SSH.
All paths and commands below are on the remote machine unless explicitly
marked as local.

## Access

- Before connecting, source `~/.rc/infrastructure.env`. It must set
  `HA_SSH_TARGET`; it may set `HA_SSH_KEY` when a key needs loading. If the
  file or target is absent, ask the user rather than guessing.
- If `HA_SSH_KEY` is set and its passphrase is stored in the macOS Keychain,
  load it non-interactively with:

  ```bash
  ssh-add --apple-use-keychain "$HA_SSH_KEY"
  ```

  A plain `ssh-add` may prompt for the passphrase instead.
- When running commands from the local machine, wrap remote commands:

```bash
ssh "$HA_SSH_TARGET" "cat /homeassistant/configuration.yaml"
```

- The SSH session lands inside the "Advanced SSH & Web Terminal" addon
  container, not the HA core container or bare host.
- `/homeassistant/*.yaml` is owned by `root:root` and requires `sudo` to
  write on this installation:

  ```bash
  cat /tmp/automations.yaml | ssh "$HA_SSH_TARGET" "sudo tee /homeassistant/automations.yaml > /dev/null"
  ```

## Scope

- Config root: `/homeassistant/`
- Main config files: `configuration.yaml`, `automations.yaml`, `scenes.yaml`
- Recorder DB: `/homeassistant/home-assistant_v2.db`
- Entity registry: `/homeassistant/.storage/core.entity_registry`

## Safety Rules

- Prefer non-destructive operations.
- Never print secrets, tokens, or raw sensitive config values in chat output.
- Validate file changes before reloads or restarts.
- Prefer targeted service reloads over full Home Assistant restarts.
- Verify entity IDs against the entity registry before wiring automations.
- **Non-negotiable for storage-mode Lovelace dashboards:** make every normal
  dashboard change through the Lovelace WebSocket API. Never mutate
  `/homeassistant/.storage/lovelace*` files directly, including as a shortcut
  for a small JSON change. The only exceptions are a recovery operation while
  Home Assistant Core is stopped, or an explicit user instruction to use that
  exceptional workflow.

## Validate And Reload

Neither the `ha` CLI (`/usr/bin/ha`) nor `hass-cli-ha` work from an
interactive SSH session in this addon container without an explicit API
token (`ha core check` fails with `unauthorized: missing or invalid API
token`, and `hass-cli-ha` isn't even on PATH). Use the Supervisor HTTP API
directly instead, reading the token from the container's env file:

**Do not attempt validation or reloads with `ha` or `hass-cli-ha` on this
installation.** Their failures do not mean the Supervisor token is invalid;
use the commands below.

```bash
ssh "$HA_SSH_TARGET" 'SUPERVISOR_TOKEN=$(cat /run/s6/container_environment/SUPERVISOR_TOKEN);
curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" -X POST http://supervisor/core/api/config/core/check_config'
```

Reload automations:

```bash
ssh "$HA_SSH_TARGET" 'SUPERVISOR_TOKEN=$(cat /run/s6/container_environment/SUPERVISOR_TOKEN);
curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" -X POST http://supervisor/core/api/services/automation/reload'
```

Reload scenes:

```bash
ssh "$HA_SSH_TARGET" 'SUPERVISOR_TOKEN=$(cat /run/s6/container_environment/SUPERVISOR_TOKEN);
curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" -X POST http://supervisor/core/api/services/scene/reload'
```

Reload template entities after changing template configuration:

```bash
ssh "$HA_SSH_TARGET" 'SUPERVISOR_TOKEN=$(cat /run/s6/container_environment/SUPERVISOR_TOKEN);
curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" -H "Content-Type: application/json" -d "{}" http://supervisor/core/api/services/template/reload'
```

Never echo `$SUPERVISOR_TOKEN` itself to output — only use it inline in the
`curl` call.

## Edit Remote Files

Pull the remote file locally, edit, push it back with `sudo tee` (the files
are root-owned), validate, then reload:

```bash
ssh "$HA_SSH_TARGET" "cat /homeassistant/automations.yaml" > /tmp/automations.yaml
# edit /tmp/automations.yaml
cat /tmp/automations.yaml | ssh "$HA_SSH_TARGET" "sudo tee /homeassistant/automations.yaml > /dev/null"
ssh "$HA_SSH_TARGET" 'SUPERVISOR_TOKEN=$(cat /run/s6/container_environment/SUPERVISOR_TOKEN);
curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" -X POST http://supervisor/core/api/config/core/check_config &&
curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" -X POST http://supervisor/core/api/services/automation/reload'
```

For scene edits, reload scenes instead of automations.

## Storage-Mode Lovelace Dashboards

**WebSocket is mandatory for dashboard mutations.** Do **not** edit
`/homeassistant/.storage/lovelace*` directly for ordinary dashboard changes,
even if the intended edit is a small or mechanical JSON change. Home Assistant
caches storage-mode dashboards in memory, so an on-disk edit bypasses the live
configuration and requires a Core restart to take effect. Direct storage edits
are reserved only for recovery while Core is stopped or when the user
explicitly requests that exceptional workflow.

Use the Lovelace WebSocket API instead. It updates the live config, persists
it safely, and avoids a Core restart:

1. Find the dashboard `url_path` in
   `/homeassistant/.storage/lovelace_dashboards` when it is not already known.
   This is not necessarily the same as a view's `path`.
2. Connect a WebSocket client through the Supervisor proxy. From the local
   machine, a temporary SSH tunnel can expose the endpoint:

   ```bash
   ssh -N -L 127.0.0.1:18123:supervisor:80 "$HA_SSH_TARGET"
   # WebSocket URL: ws://127.0.0.1:18123/core/api/websocket
   ```

   Authenticate with the Supervisor token read privately from
   `/run/s6/container_environment/SUPERVISOR_TOKEN`; never print, persist, or
   place the token in a command argument.
3. Fetch the current configuration immediately before changing it:

   ```json
   {"id": 1, "type": "lovelace/config", "url_path": "dashboard-office"}
   ```

4. Modify only the requested card/view in the returned JSON, then save the
   complete updated config:

   ```json
   {"id": 2, "type": "lovelace/config/save", "url_path": "dashboard-office", "config": {"views": []}}
   ```

5. Fetch `lovelace/config` again and verify the intended card is present (or
   absent for a removal). A browser or dashboard-client refresh may still be
   needed to render the new layout, but do not restart Home Assistant merely
   to load the configuration.

Keep the WebSocket tunnel temporary and close it after the operation. Make a
focused rollback through the same API if verification fails.

### Visual verification

After changing a dashboard, verify the live rendered result in an authenticated
browser session whenever browser control is available. Refresh the target view,
inspect it at the viewport used by that dashboard when known, and confirm that
the changed content is visible, aligned, and usable. Check the browser console
for new errors related to the change. Treat visible configuration errors,
missing cards or media, overlaps, clipping, unexpected empty space, and stale or
unknown values as findings to resolve or report; a successful WebSocket save
alone does not establish that the dashboard is correct.

For responsive dashboards or dedicated wall panels, also inspect the relevant
device-size viewport when practical. Do not activate controls that cause real
home actions merely to test appearance unless the user asked for that behavior
test.

## Automation Workflow

1. Confirm the target entity exists in the entity registry.
2. Pull and edit `automations.yaml`.
3. Push the edited file back.
4. Run the Supervisor `check_config` API call documented above.
5. Reload automations through the Supervisor service API.
6. Verify the behavior via entity state or recorder DB.

## Entity Discovery

Prefer the entity registry for canonical entity IDs:

```bash
ssh "$HA_SSH_TARGET" "python3 - <<'PY'
import json
with open('/homeassistant/.storage/core.entity_registry') as f:
    data = json.load(f)
for e in data['data']['entities']:
    eid = e.get('entity_id') or ''
    if 'KEYWORD' in eid.lower():
        print(eid)
PY"
```

## Recorder State

This installation uses the newer recorder schema, `states` plus `states_meta`.
Use `metadata_id` joins for latest state lookups:

```bash
ssh "$HA_SSH_TARGET" "python3 - <<'PY'
import datetime
import sqlite3

entity = 'sensor.ENTITY_ID_HERE'
conn = sqlite3.connect('/homeassistant/home-assistant_v2.db', timeout=5)
row = conn.execute('''
SELECT s.state, s.last_updated_ts
FROM states s
JOIN states_meta sm ON s.metadata_id = sm.metadata_id
WHERE sm.entity_id = ?
ORDER BY s.last_updated_ts DESC
LIMIT 1
''', (entity,)).fetchone()
if row:
    ts = datetime.datetime.fromtimestamp(row[1]).strftime('%Y-%m-%d %H:%M:%S')
    print(f'{entity}: {row[0]} at {ts}')
else:
    print('No state rows found')
conn.close()
PY"
```

## Pitfalls

- The `ha` CLI and `hass-cli-ha` are not usable for validate/reload from this
  SSH session (no API token wired up, and `hass-cli-ha` isn't on PATH) — use
  the Supervisor HTTP API with `SUPERVISOR_TOKEN` as shown above.
- Direct `http://localhost:8123/api/...` calls with long-lived tokens may
  return 401; use the Supervisor proxy, `http://supervisor/core`, instead.
- Some legacy YAML entities may no longer exist in the registry; verify first.
- `/homeassistant/*.yaml` files are root-owned; write them with `sudo tee`,
  not a plain redirect (plain `cat > file` over SSH fails with "Permission
  denied").
- Scene entries can use `entities: []` (empty list) to mean "do nothing on
  activation" even though HA's config check logs a non-fatal warning. Keep
  that form when it matches the requested behavior rather than switching to
  `entities: {}`.
