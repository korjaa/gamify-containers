#!/bin/bash

# Entrypoint arguments
USER_ID="$1"
shift

# Host mounted files
#  Docker -v creates missing folders with root permissions
chown "$USER_ID":"$USER_ID" /home/user
chown "$USER_ID":"$USER_ID" /home/user/.config
chown "$USER_ID":"$USER_ID" /home/user/.config/pulse

# Create a new user with matching id to runner
useradd --home-dir /home/user/ --shell=/bin/bash user --uid="$USER_ID"
if [ ! -f /home/user/.profile ]; then
	su user -c "cp /etc/skel/.* /home/user/" 2>/dev/null
	cat >>/home/user/.profile <<-EOF

	# Add lutris path
	PATH="\$PATH:/usr/games"
	EOF
fi

# Set timezone
TZ=${TZ:-UTC}
ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

# Generate .Xauthority using xauth with .Xkey sourced from host
su user -c "touch /home/user/.Xauthority"
su user -c "xauth add \"$DISPLAY\" . \"$(</home/user/.Xkey)\""

# Copy group permissions of GPU for lutris user to enable rendering in some cases
#usermod -a -G $(stat -c %g /dev/dri/card* | head -1) user

# Switch to non-root user
echo "$@"
cd /home/user || exit
exec gosu user "$@"
