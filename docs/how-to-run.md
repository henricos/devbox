# How to run the image

High-level guidance on what needs to be prepared to start the container. `compose.example.yml` is the deployment reference.

## Volumes

| Volume | Required | Description |
|---|---|---|
| `.ssh` → `/home/developer/.ssh` | yes | A single directory for two purposes: inbound SSH (`authorized_keys`) and outbound SSH (own key for GitHub: `id_github` + `config`). Must be owned by UID 1000 with strict permissions (directory `700`, files `600`) — sshd refuses the connection if they are more open than that. |
| `github` → `/home/developer/github` | yes | Your code repositories. |
| `.claude` → `/home/developer/.claude` | optional | AI tool state (session, config, memory, logs) written at runtime by Claude Code. Mount it so this state survives container recreations instead of resetting each time. Add similar mounts for other AI tools you install manually. |
| `docker.sock` → `/var/run/docker.sock` | optional | Access to the host's Docker daemon, equivalent to root on the machine. Only mount it if you need the container to build or run containers. On startup, the entrypoint reads the socket's GID and adds `developer` to a group with that GID (creating `docker-host` if none exists), so `docker` works without `sudo`. If the socket is owned by GID 0, it is left alone and `sudo docker` is required. |

No environment variable is required.

## Preparing the `.ssh` volume (first access)

```bash
mkdir -p /opt/devbox/.ssh

# inbound: generate a key pair and put the public key in authorized_keys
ssh-keygen -t ed25519 -f /tmp/id_devbox -C devbox
cp /tmp/id_devbox.pub /opt/devbox/.ssh/authorized_keys

# outbound: the container's own key for GitHub
ssh-keygen -t ed25519 -f /opt/devbox/.ssh/id_github -C devbox-github
cat > /opt/devbox/.ssh/config <<'EOF'
Host github.com
  IdentityFile ~/.ssh/id_github
  IdentitiesOnly yes
EOF
# register id_github.pub at github.com/settings/keys, then:

chown -R 1000:1000 /opt/devbox/.ssh && chmod 700 /opt/devbox/.ssh
chmod 600 /opt/devbox/.ssh/authorized_keys /opt/devbox/.ssh/id_github /opt/devbox/.ssh/config
```

Transfer the generated private key (`/tmp/id_devbox`) to your machine before starting the container — it does not stay in the volume.

## Starting and connecting

```bash
cp compose.example.yml compose.yml   # adjust the volume paths
docker compose up -d
ssh -p 2222 developer@<host>         # or configure a Host in your ~/.ssh/config
```

On login, the container offers a picker for up to 5 persistent tmux sessions (`term-01`..`term-05`).

## Basic verification

- `ssh -T git@github.com` — outbound key registered on GitHub.
- `gh auth status` — GitHub CLI authentication.
- `ls ~/github` — projects volume mounted.
- `docker ps` (only with `docker.sock` enabled) — access to the host daemon.

## AI tools

None come pre-installed. Install them manually after the first access.
