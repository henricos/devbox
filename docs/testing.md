# Testing strategy

This repository has no application code: the artifact is the Docker image itself. There are no unit or integration tests in the traditional sense — functional validation happens against the built image, via a smoke test.

## Smoke test (`test/smoke.sh`)

Builds the image locally (tag `devbox:smoke`, without publishing), starts a container from it and validates, via `docker exec`:

- the non-root user (`developer`) exists and has UID 1000, is not root;
- `sshd` is running;
- the expected tools are present and respond to `--version` (or equivalent): `node`, `npm`, `python3`, `git`, `gh`, `docker`, `jq`, `yq`, `bc`, `age`, `sops`, `tmux`, `uv`, `yt-dlp`, `psql`, `playwright`;
- the `tmux-menu` script is present and executable at `/usr/local/bin`;
- `developer` has passwordless `sudo` (checked with `sudo -n true`).

At the end, the container is torn down and removed, whether or not the result was published.

## When to run it

Running `bash test/smoke.sh` is a mandatory precondition of the local gate of the release flow (`docs/release.md`, "Local gate" step). It can also be run at any time during development, without needing a GitHub Release or a GHCR publish — it only needs local Docker.

## Out of scope

The smoke test does not validate volumes, persistence across restarts, or the login of tools installed manually post-boot.
