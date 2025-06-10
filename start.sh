#!/bin/bash

# Start rsyslog in the background
# In a standard Docker container, systemd isn't the init system.
# rsyslogd needs to be started manually and will listen on /dev/log.
/usr/sbin/rsyslogd -n &

# Start Apache in the foreground
# This keeps the container running
exec apache2ctl -D FOREGROUND