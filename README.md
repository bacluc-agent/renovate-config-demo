# renovate-config-demo

Demonstrates the shared [`github>bacluc-agent/renovate-config`](https://github.com/bacluc-agent/renovate-config) preset via `extends`, detecting versions in a YAML file, a shell script and a Dockerfile:

| File | Dep |
|---|---|
| `versions.yaml` | `ghcr.io/bacluc/prettier-image/prettier-image` |
| `scripts/install.sh` | `opencode-ai` |
| `Dockerfile` | `alpine` |
| `scripts/update-renovate-snapshot.sh` | `renovate/renovate` |

## Check / update the snapshot

`.github/renovate-snapshot.json` holds one `{file, depName, currentValue}` entry per detected dependency. Regenerate and compare it with:

```bash
./scripts/update-renovate-snapshot.sh --check   # regenerate, assert all four pairs, fail on diff
./scripts/update-renovate-snapshot.sh --update  # regenerate and commit the result
```

## When Renovate bumps `RENOVATE_VERSION`

The `verify-renovate` workflow goes red (`--check` sees a snapshot diff). Run it manually with `workflow_dispatch` and `update_snapshot=true` to commit the updated snapshot; the updated script version then triggers the check again.
