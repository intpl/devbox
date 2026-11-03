# What you're looking at

That file is a **Quadlet** — a declarative unit file that tells `systemd` how to run a Podman container. Instead of writing a 30-line `.service` file with `ExecStart=podman run ...`, you write a short `.container` file and a generator compiles it into a real systemd unit behind the scenes.

- Directory `~/.config/containers/systemd/` = **user-level (rootless)** Quadlets. The system-wide equivalent is `/etc/containers/systemd/`.
- `dev.container` → becomes `dev.service` after `systemctl --user daemon-reload`.
- `webnet.network` → defines a podman network other containers can join via `Network=webnet.network`.
- `caddy.container`, `syncthing.container` → same pattern.
- The `@` in `dev.container@` means it's a **template unit** (instantiable, like `dev@foo.service`).

The container itself is a "devbox" — a privileged-but-rootless container that can run its *own* podman inside (nested containers). The privilege is safe because rootless podman never gets real uid 0 on the host.

---

# Keywords to research (in rough order)

| Keyword | Why it matters |
|---|---|
| **Podman** | Daemonless container engine (Docker CLI compatible) |
| **Quadlet** | The generator that turns `.container` files into `.service` files |
| **`podman-system-generator`** | The actual binary behind Quadlet |
| **systemd** | Service manager that actually runs/starts/restarts everything |
| **systemd user services** | Running systemd as your non-root user (`systemctl --user`) |
| **`loginctl enable-linger`** | Lets user services run *before* login → essential for "start on boot" |
| **`default.target`** | User session equivalent of `multi-user.target` |
| **Rootless containers** | Containers running without root, using user namespaces |
| **subuid / subgid** | The UID/GID ranges allocated to your user for rootless containers |
| **`/etc/subuid` `/etc/subgid`** | Files defining those ranges |
| **Podman volumes** | Named volumes (`Volume=inner-storage:/path`) vs bind mounts (`Volume=%h/dev:/path`) |
| **`%h` specifier** | systemd shortcut for `$HOME` |
| **`podman auto-update`** | Built-in mechanism to refresh images and recreate containers |
| **`io.containers.autoupdate` label** | Opt-in label that marks a container as auto-updatable |
| **systemd timers** | Used to schedule `podman auto-update` periodically |
| **`Restart=` policies** | `no / on-failure / always / on-abnormal` |
| **`RestartSec=` `StartLimitBurst=` `StartLimitIntervalSec=`** | Restart pacing/back-off |
| **`systemctl --user daemon-reload`** | Required after creating/editing a Quadlet |
| **`journalctl --user -u dev`** | Logs for the container's service |
| **`podman ps -a` / `podman logs` / `podman exec`** | Day-to-day inspection |
| **`quadlet -dryrun`** (or `/usr/libexec/podman/quadlet -dryrun`) | Preview the generated `.service` without installing |

---

# Creating a new container that auto-starts on boot

Drop a file at `~/.config/containers/systemd/NAME.container`. Example — a fresh Gitea instance on the `webnet` network:

```ini
# ~/.config/containers/systemd/gitea.container
[Unit]
Description=Gitea git server
After=network-online.target
Wants=network-online.target

[Container]
Image=docker.io/gitea/gitea:latest
ContainerName=gitea
HostName=gitea
Network=webnet.network
PublishPort=127.0.0.1:3000:3000
PublishPort=127.0.0.1:2222:22
Volume=%h/gitea/data:/data
# Pull a fresh image at service start if available:
AutoUpdate=registry
Environment=USER_UID=1000
Environment=USER_GID=1000

[Service]
Restart=always
RestartSec=5s
# Stop spamming if it crashes in a loop:
StartLimitBurst=5
StartLimitIntervalSec=60

[Install]
WantedBy=default.target
```

Then:

```bash
systemctl --user daemon-reload
systemctl --user start gitea.service
systemctl --user enable gitea.service
loginctl enable-linger $USER      # CRUCIAL for "start on boot"
```

The last command is the trick most people miss: **without linger, user systemd only runs while you're logged in.** With it, your containers come up at boot, no SSH needed.

Verify the generator worked:

```bash
/usr/libexec/podman/quadlet -dryrun -user
# shows the compiled .service file
systemctl --user status gitea.service
```

---

# Keeping containers updated automatically

Two layers, both recommended:

**1. Mark each container as auto-updatable.** Either:
```ini
AutoUpdate=registry
```
in the `[Container]` section (Quadlet directive), or label the image at build time with `io.containers.autoupdate=registry`.

**2. Schedule `podman auto-update`.** Most distros ship:
- `/usr/lib/systemd/system/podman-auto-update.service` (system-wide)
- `/usr/lib/systemd/system/podman-auto-update.timer`

Enable it weekly (or write your own user timer for finer control):
```bash
sudo systemctl enable --now podman-auto-update.timer
```

What it does on each run:
1. Pulls the new image for every container with the autoupdate label.
2. If the image changed, **stops the old container, recreates it with the same name/volumes/ports**, and starts it.
3. Logs results to the journal (`journalctl -u podman-auto-update`).

Preview without doing anything:
```bash
podman auto-update --dryrun
```

For rootless containers, you'll want a **user timer** instead (the system one runs as root). Create `~/.config/systemd/user/podman-auto-update.timer` + `.service`, or just use a cron-like user timer that runs `podman auto-update`.

---

# Auto-restart when things go wrong

This is pure systemd — Podman isn't involved once the unit is generated. The knobs:

```ini
[Service]
Restart=always                 # also restarts on clean exit
RestartSec=5s                  # wait between restarts
StartLimitBurst=5              # max 5 restarts...
StartLimitIntervalSec=60       # ...within 60s, then give up
TimeoutStartSec=120            # consider startup failed after 2 min
```

- `Restart=always` → covers crashes, OOM kills, and `podman` exiting.
- `Restart=on-failure` → only on non-zero exit (lets you stop it cleanly without surprise restarts).
- `StartLimitBurst` is what saves you from a crash loop burning CPU forever. After the burst, the unit goes to `failed` and you investigate with `journalctl --user -u NAME`.

For graceful shutdowns of the container itself (e.g. letting Gitea flush), systemd sends `SIGTERM` and waits `TimeoutStopSec=` before `SIGKILL`. Podman handles that signal correctly by default.

---

# Mental model to take away

1. **Quadlet** = declaration ("I want this container").
2. **systemd** = lifecycle (start at boot, restart on crash, stop cleanly).
3. **Podman** = runtime (pull image, create cgroup/namespace, exec).
4. **`loginctl enable-linger`** = the bridge that lets (2) work as your user before you log in.
5. **`podman auto-update` + systemd timer** = the bridge that lets (3) refresh images while (2) keeps the service alive.

Read the man pages: `man podman-systemd.unit` (the Quadlet reference — your bible here), `man podman-auto-update`, `man systemd.service`, `man systemd.timer`, `man loginctl`.
