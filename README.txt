# 1. Edit your Containerfile
vim ~/devbox/Containerfile

# 2. Rebuild the image (this overwrites the old 'latest' tag)
podman build -t localhost/devbox:latest ~/devbox

# 3. Restart the container to apply the new image
# (Quadlet automatically detects the new image and recreates the container)
systemctl --user restart dev

# 4. Verify it's running with the new image
podman ps
