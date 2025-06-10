# PHP Syslog Logging with Rsyslog and Logrotate in Docker

This project demonstrates a robust logging setup for PHP applications within a Dockerized Ubuntu environment. It shows how to send PHP logs via `syslog()`, route them to a custom file using `rsyslog`, and manage that log file's size and retention with `logrotate`. A key focus is on correctly configuring `logrotate`'s `postrotate` script to work reliably in a Docker container.

## Features

* **PHP `syslog()` Integration**: Logs messages from a PHP script directly to the system's syslog daemon.
* **Custom Rsyslog Routing**: Configures `rsyslog` to filter logs based on a custom identifier (`programname`) and direct them to a dedicated log file.
* **Logrotate Management**: Sets up `logrotate` to automatically rotate, compress, and retain log files, preventing unlimited growth.
* **Docker Containerization**: Provides an isolated, reproducible Ubuntu environment for testing the entire logging pipeline.
* **Docker-friendly `postrotate`**: Includes the crucial fix for `logrotate`'s `postrotate` script to ensure `rsyslogd` reloads its log files correctly in a Docker context.

---

## Prerequisites

* **Docker Desktop** (or Docker Engine) installed and running on your local machine.

---

## Project Structure
```
php-log-test/
├── Dockerfile                  # Defines the Docker image
├── my_app_test.php             # The PHP script to generate logs
├── 50-my-php-app.conf          # Custom rsyslog configuration
├── my_php_script_log           # Custom logrotate configuration
└── start.sh                    # Entrypoint script for the Docker container
```

---

## Test and Verify

Follow these steps to confirm that your logging pipeline is working correctly.

1.  **Access the container's shell:**
    Open a new terminal window and connect to your running container:
    ```bash
    docker exec -it php-logger /bin/bash
    ```
    You are now inside the container.

2.  **Verify `rsyslogd` is running:**
    ```bash
    ps aux | grep rsyslogd
    ```
    You should see the `rsyslogd` process running.

3.  **Watch your custom log file (in container shell):**
    Keep this terminal window open to monitor the log in real-time:
    ```bash
    tail -f /var/log/php_logs/my_php_script.log
    ```

4.  **Trigger the PHP script (from your host machine's browser):**
    Open your web browser and navigate to:
    `http://localhost:8080/my_app_test.php`

    * **Verification:** You should immediately see the "Container PHP Log Test" messages appear in the `tail -f` output in your container's terminal.
    * (Optional) Check Apache's error log inside the container to see the `error_log` message:
        ```bash
        tail /var/log/apache2/error.log
        ```

5.  **Test Log Rotation (from container shell):**

    * **Force a rotation:** In the container's shell (the one where you ran `tail -f`, or a new `docker exec` session), run the `logrotate` command directly:
        ```bash
            logrotate -f /etc/logrotate.d/my_php_script_log
        ```
        *This command forces `logrotate` to run the rotation regardless of size/time conditions.*

    * **Verify rotated files:**
        ```bash
        ls -l /var/log/php_logs/
        ```
        You should now see:
        * `my_php_script.log` (a new, empty file)
        * `my_php_script.log.1` (the previously active log file, now renamed)
        * (If `logrotate`'s daily cron has run since this file was created, you might see `my_php_script.log.1.gz` compressed, or `my_php_script.log.1` and `my_php_script.log.2.gz` etc. depending on `delaycompress` and prior runs).

    * **Trigger the PHP script again (from your host machine's browser):**
        Refresh `http://localhost:8080/my_app_test.php`

    * **Crucial Verification (in `tail -f` output):**
        Observe your `tail -f /var/log/php_logs/my_php_script.log` output. The new log messages should now appear in the *newly created* `my_php_script.log` file, confirming that `rsyslogd` correctly re-opened its file handle after the `pkill -HUP rsyslogd` command executed in the `postrotate` script. The `my_php_script.log.1` file should *not* receive any new messages.

---

## Cleanup

When you're finished testing, stop and remove the container:

```bash
docker stop php-logger
docker rm php-logger
```

## Notes and Explanations

* **`openlog()` and `programname`**: The `openlog("my_php_app", ...)` call in `my_app_test.php` sets the `ident` string to "**my\_php\_app**." `rsyslog` picks this up as the `programname` property, allowing `50-my-php-app.conf` to specifically route these logs.
* **`syslog()` vs. `error_log()`**: `openlog()` and `syslog()` are specifically for sending messages to the system's syslog daemon. `error_log()` generally writes to PHP's error log (often the web server's error log) unless explicitly configured in `php.ini` to go to `syslog`.
* **`journald` in Docker**: In a standard Docker container, `systemd-journald` isn't typically running as the primary init system. `rsyslogd` in this setup is configured to listen directly to the `/dev/log` socket via its `imuxsock` module, so `syslog()` calls from PHP still reach `rsyslogd` directly, bypassing the `journald` step common on full OS installations.
* **`postrotate` Criticality**: The `pkill -HUP rsyslogd` command in `logrotate`'s `postrotate` script is vital. Without it, `rsyslogd` would continue writing to the old (renamed) log file after rotation, filling up disk space on old files. `SIGHUP` tells `rsyslogd` to gracefully reload its configuration and re-open all log files, ensuring it writes to the newly created `my_php_script.log`.
* **Permissions**: The `create 0664 syslog adm` directive in `logrotate` ensures the newly created log file has the correct permissions and ownership for `rsyslogd` (which runs as `syslog` user, often in the `adm` group) to write to it.