# Pin the base image by digest (step 4.2). quay.io/podman/stable is the
# Podman team's purpose-built Podman-in-Podman image (multi-arch, has amd64).
FROM quay.io/podman/stable:latest

# Pin OpenCode. Set to the current release from
# https://github.com/sst/opencode/releases  (without this the build fails —
# deliberately, so the version is always a conscious choice).
ARG OPENCODE_VERSION=1.18.5

RUN dnf install -y \
    git \
    podman-compose \
    curl \
    ca-certificates \
    unzip \
    fish \
    eza \
    vim \
    glibc-langpack-en \
    net-tools \
    && dnf clean all

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# OpenCode: prebuilt standalone binary, linux/amd64, pinned version.
RUN curl -fsSL \
      "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-x64.tar.gz" \
      -o /tmp/opencode.tar.gz \
    && cd /tmp \
    && tar -xzf opencode.tar.gz \
    && install -m 0755 opencode /usr/local/bin/opencode \
    && rm -f /tmp/opencode.tar.gz /tmp/opencode

# Git identity for everything committed inside the container.
# Machine authorship is visible in history; no credentials exist here.
RUN git config --system user.name "bartek ai" \
    && git config --system user.email "bartek ai" \
    && git config --system init.defaultBranch main \
    && git config --system safe.directory "*"

RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | bash

RUN mkdir -p /root/.agents/
RUN ln -s /home/b/dev/skills /root/.agents/skills

COPY config.fish /root/.config/fish/config.fish

# hack for opencode
RUN touch /usr/local/bin/xdg-open; chmod +x /usr/local/bin/xdg-open

WORKDIR /home/b/dev/community_calendar
CMD ["opencode", "web", "--port", "4009", "--hostname", "0.0.0.0"]
