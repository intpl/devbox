FROM quay.io/podman/stable:latest

RUN dnf install -y \
    tree \
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
    procps-ng \
    npx \
    elixir \
    postgresql-contrib \
    ripgrep \
    pandoc \
    python3 \
    ffmpeg-free \
    dejavu-sans-fonts \
    && dnf clean all

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN curl -fsSL https://bun.com/install | bash
RUN curl -fsSL https://opencode.ai/install | bash
RUN curl -fsSL https://omp.sh/install | sh

# Git identity for everything committed inside the container.
# Machine authorship is visible in history; no credentials exist here.
RUN git config --system user.name "bartek ai" \
    && git config --system user.email "bartek ai" \
    && git config --system init.defaultBranch main \
    && git config --system safe.directory "*" \
    && git config --global alias.st status

RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | bash

RUN mkdir -p /root/.agents/
RUN ln -s /home/b/dev/skills /root/.agents/skills

COPY config.fish /root/.config/fish/config.fish

# hack for opencode
RUN touch /usr/local/bin/xdg-open; chmod +x /usr/local/bin/xdg-open

RUN dnf upgrade -y

WORKDIR /home/b/dev/
CMD ["sleep", "infinity"]
