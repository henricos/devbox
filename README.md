<div align="center">

# devbox

A Docker image with a complete set of development tools, serving as a persistent, SSH-accessible personal workstation.

[![Build](https://github.com/henricos/devbox/actions/workflows/release-ghcr.yml/badge.svg)](https://github.com/henricos/devbox/actions/workflows/release-ghcr.yml)
[![Version](https://img.shields.io/github/v/release/henricos/devbox)](https://github.com/henricos/devbox/releases)
[![Image size](https://ghcr-badge.egpl.dev/henricos/devbox/size)](https://github.com/henricos/devbox/pkgs/container/devbox)
[![License](https://img.shields.io/github/license/henricos/devbox)](LICENSE)

</div>

## Quick start

```bash
docker pull ghcr.io/henricos/devbox:latest

cp compose.example.yml compose.yml   # adjust volume paths for your environment
docker compose up -d
ssh -p 2222 developer@<host>
```

See [how to run the image](docs/how-to-run.md) for what needs to be prepared before the first start (SSH keys, volumes).

**Platform:** `linux/amd64` only — the image bundles an amd64-specific `yq` binary and is built as single-arch. It has not been tested (and likely will not run without emulation) on ARM hosts such as Apple Silicon or Raspberry Pi.

## Included tools

| Category | Tools |
|---|---|
| Shell and system | bash, tmux, htop, nano, sudo |
| Version control | git, gh (GitHub CLI) |
| Node.js | nvm (Node 22 LTS) |
| Python | python3, pip, venv, uv |
| Database | psql (Postgres client) |
| Data tools | jq, yq, bc |
| Secrets | age, sops |
| Containers | docker CLI |
| Media | yt-dlp |
| Browser automation | playwright |

The container runs as a non-root user (`developer`, UID 1000) with passwordless `sudo` — this is a single-user personal workstation, so there is no multi-tenant boundary to protect behind a password prompt — and exposes port 22 internally, with the external mapping defined in Compose. **No AI application comes pre-installed in the image**: installing and logging in to tools like Claude Code is left to whoever runs the container, done manually after the first boot.

## Configuration

The container is stateless by design — the image can be updated at any time without data loss. All persistent state (SSH keys, your repositories, and optionally the state of any AI tool you install manually) lives in volumes on the host. Before starting the container for the first time, these directories need to be prepared with the correct permissions, especially `.ssh`, which the SSH daemon refuses if permissions are too open.

See [how to run the image](docs/how-to-run.md) for the full list of volumes and what needs to be prepared.

## Publishing a new image version

The release flow uses the `VERSION` file as the source of truth. GitHub Actions validates that the file's content matches the tag before publishing — the `Build and Release` workflow is triggered by creating a GitHub Release and publishes to GHCR with the version tag and `latest`.

See [release guide](docs/release.md) for the complete steps, including preconditions, the local smoke test (`test/smoke.sh`), and validating the external chain.
