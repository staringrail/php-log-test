# Use an official Ubuntu base image
FROM ubuntu:22.04

# Set environment variables for non-interactive apt operations (No prompts)
ENV DEBIAN_FRONTEND=noninteractive

# Update apt, install necessary packages
RUN apt update && \
    apt install -y \
    apache2 \
    php8.1 \
    libapache2-mod-php8.1 \
    php8.1-cli \
    rsyslog \
    logrotate \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Copy custom rsyslog configuration
COPY 50-my-php-app.conf /etc/rsyslog.d/50-my-php-app.conf

# Copy custom logrotate configuration
COPY my_php_script_log.conf /etc/logrotate.d/my_php_script_log.conf

# Create the log file and set initial permissions
# rsyslogd-rotate needs /var/log/ to be writable by syslog group
RUN mkdir -p /var/log/php_logs && \
    touch /var/log/php_logs/my_php_script.log && \
    chown syslog:adm /var/log/php_logs/my_php_script.log && \
    chmod 664 /var/log/php_logs/my_php_script.log

# Enable Apache PHP module
RUN a2enmod php8.1

# Remove default Apache index.html
RUN rm /var/www/html/index.html

# Copy your PHP test script
COPY my_app_test.php /var/www/html/my_app_test.php

# Create a startup script to ensure services are running
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose port 80 for Apache
EXPOSE 80

# Command to run when the container starts
CMD ["/usr/local/bin/start.sh"]

