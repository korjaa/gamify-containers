#!/bin/bash

# Stop on error
set -e

# Create temp Xkey
TFILE="$(mktemp)"
test "$(stat -c %a "$TFILE")" = "600"  # Make sure it's only readable by me
xauth list | awk '{print $NF}' | head -1 > "$TFILE"  # Add Key

# Get video group number
VID="$(getent group video | cut -d: -f3)"
test -n "$VID"

# Check for gamify volume
if ! docker volume ls | grep --q gamify; then
	docker volume create gamify
fi

# Launch docker
docker run -it --rm \
	--gpus all \
	--env DISPLAY \
	--env XDG_RUNTIME_DIR="/tmp" \
	--env XDG_SESSION_TYPE="X11" \
	--device /dev/nvidia-modeset \
	-v gamify:/home/user \
	-v "$TFILE":/home/user/.Xkey:ro \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v /tmp/pulse-socket:/tmp/pulse-socket \
	-v "$HOME/.config/pulse/cookie":/home/user/.config/pulse/cookie:ro \
	gamify "$UID" "$@"

rm "$TFILE"
