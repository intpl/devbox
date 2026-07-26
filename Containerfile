# Pin the base image by digest (step 4.2). quay.io/podman/stable is the
# Podman team's purpose-built Podman-in-Podman image (multi-arch, has arm64).
FROM quay.io/podman/stable@sha256:83c718f797a42f399d608a888f8e4d2aa1eb3bc98aed8d888dbbcf43f955fc2b

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
    && dnf clean all

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# OpenCode: prebuilt standalone binary, linux/arm64, pinned version.
RUN curl -fsSL \
      "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-arm64.tar.gz" \
      -o /tmp/opencode.tar.gz \
    && cd /tmp \
    && tar -xzf opencode.tar.gz \
    && install -m 0755 opencode /usr/local/bin/opencode \
    && rm -f /tmp/opencode.tar.gz /tmp/opencode

# Git identity for everything committed inside the container.
# Machine authorship is visible in history; no credentials exist here.
RUN git config --system user.name "opencode-ai" \
    && git config --system user.email "ai@gladecki.pl" \
    && git config --system init.defaultBranch main \
    && git config --system safe.directory "*"

RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | bash

RUN mkdir -p /root/.agents/
RUN ln -s /home/b/dev/skills /root/.agents/skills

COPY config.fish /root/.config/fish/config.fish

WORKDIR /home/b/dev
CMD ["sleep", "infinity"]
