#!/bin/bash
set -eu

IMAGE_TAG="devbox:smoke"
CONTAINER_NAME="devbox-smoke-test"

STATUS=0

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
pass() { printf '  OK  %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; STATUS=1; }

cleanup() {
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

check_cmd() {
    local desc="$1" user="$2" cmd="$3"
    if docker exec -u "$user" "$CONTAINER_NAME" bash -lc "$cmd" >/dev/null 2>&1; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

log "Building local image ($IMAGE_TAG)..."
docker build -t "$IMAGE_TAG" .

log "Starting test container ($CONTAINER_NAME)..."
cleanup
docker run -d --name "$CONTAINER_NAME" "$IMAGE_TAG" >/dev/null

log "Waiting for sshd to start..."
for _ in $(seq 1 20); do
    if docker exec "$CONTAINER_NAME" pgrep -x sshd >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

log "Validating container runtime..."

if [ "$(docker exec "$CONTAINER_NAME" id -u developer 2>/dev/null || echo '')" = "1000" ]; then
    pass "developer user exists with UID 1000"
else
    fail "developer user exists with UID 1000"
fi

check_cmd "sshd running"                root "pgrep -x sshd"
check_cmd "python3 --version"            root "python3 --version"
check_cmd "git --version"                root "git --version"
check_cmd "gh --version"                 root "gh --version"
check_cmd "docker --version"             root "docker --version"
check_cmd "jq --version"                 root "jq --version"
check_cmd "yq --version"                 root "yq --version"
check_cmd "bc --version"                 root "bc --version"
check_cmd "age --version"                root "age --version"
check_cmd "sops --version"               root "sops --version"
check_cmd "tmux -V"                      root "tmux -V"
check_cmd "psql --version"               root "psql --version"
check_cmd "uv --version"                 root "uv --version"
check_cmd "yt-dlp --version"             root "yt-dlp --version"
check_cmd "tmux-menu present and executable" root "test -x /usr/local/bin/tmux-menu"
check_cmd "node --version"               developer "node --version"
check_cmd "npm --version"                developer "npm --version"
check_cmd "playwright --version"         developer "playwright --version"
check_cmd "developer has passwordless sudo" developer "sudo -n true"

log ""
if [ "$STATUS" -eq 0 ]; then
    log "Smoke test: all checks passed."
else
    log "Smoke test: failed — see checks above."
fi

exit "$STATUS"
