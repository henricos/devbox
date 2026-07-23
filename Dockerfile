FROM ubuntu:24.04

ARG IMAGE_VERSION=dev
ARG BUILD_DATE

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=pt_BR.UTF-8 \
    LC_ALL=pt_BR.UTF-8 \
    NVM_DIR=/home/developer/.nvm \
    PWTEST_CLI_HEADLESS=1

# BUILD_DATE changes on every release, invalidating this layer and — through
# Docker's layer cache cascade — every layer that follows (yq, uv/yt-dlp,
# Docker CLI, gh, nvm/npm), so every release rebuilds these tools from
# scratch instead of reusing stale @latest versions from the Buildx/GHA cache.
RUN echo "cache-bust: ${BUILD_DATE}"

# System packages — changes rarely, kept first for cache efficiency
RUN apt-get update && apt-get install -y \
    curl wget git ca-certificates gnupg \
    openssh-server \
    python3 python3-pip python3-venv \
    postgresql-client \
    tmux htop nano jq build-essential \
    locales \
    && locale-gen pt_BR.UTF-8 \
    && update-locale LANG=pt_BR.UTF-8 LC_ALL=pt_BR.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# yq — YAML processor
RUN wget -qO /usr/local/bin/yq \
    https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

# uv + yt-dlp via pip (--break-system-packages required on Ubuntu 24.04 / PEP 668)
RUN pip3 install uv yt-dlp --break-system-packages

# Docker CLI — connects to host daemon via socket volume mount
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu noble stable" \
    > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y docker-ce-cli \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# gh CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli.gpg] \
    https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Non-root user — rename the ubuntu user (UID 1000) to developer, a neutral name
# not tied to any specific AI tool, since none is preinstalled in this image
RUN usermod -l developer ubuntu && \
    usermod -d /home/developer -m developer && \
    groupmod -n developer ubuntu

# Switch to developer to install nvm, Node and global npm packages
USER developer
WORKDIR /home/developer

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install 22 \
    && nvm alias default 22 \
    && npm install -g playwright@latest \
    && playwright install chromium

# Make nvm available in login shells; SSH sessions load .profile
RUN echo 'export NVM_DIR="/home/developer/.nvm"' >> /home/developer/.profile \
    && echo '. "$NVM_DIR/nvm.sh"' >> /home/developer/.profile

# Show the persistent tmux session picker on SSH login
RUN echo 'if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then exec tmux-menu; fi' \
    >> /home/developer/.profile

# SSH configuration requires root
USER root
COPY tmux-menu /usr/local/bin/tmux-menu
RUN chmod +x /usr/local/bin/tmux-menu
RUN . /home/developer/.nvm/nvm.sh \
    && playwright install-deps chromium \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && mkdir -p /home/developer/.ssh \
    && chmod 700 /home/developer/.ssh \
    && chown developer:developer /home/developer/.ssh

LABEL org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/henricos/devbox"

EXPOSE 22
ENTRYPOINT ["/usr/sbin/sshd", "-D"]
