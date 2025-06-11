<?php
// Always call openlog() to set the identifier and facility
// for logs sent via syslog() in this script's execution.
$ident = 'my_php_app';
$facility = LOG_LOCAL0;
openlog($ident, LOG_PID | LOG_NDELAY, $facility);

// Log an informational message
syslog(LOG_INFO, "Container PHP Log Test: Script executed at " . date('Y-m-d H:i:s'));

// Log a warning message (will also go to the same file)
syslog(LOG_WARNING, "Container PHP Log Test: A warning occurred at " . date('Y-m-d H:i:s'));

// Log an error message (will also go to the same file)
syslog(LOG_ERR, "Container PHP Log Test: An error occurred at " . date('Y-m-d H:i:s'));

// Log an emergency message (will also go to the same file)
syslog(LOG_EMERG, "Container PHP Log Test: An emergency occurred at " . date('Y-m-d H:i:s'));


// Close the syslog connection (good practice for short-lived scripts)
closelog();

echo "Log messages sent to syslog. Please check /var/log/php_logs/my_php_script.log inside the container.\n";

// Using error_log to demonstrate it goes to web server logs by default (unless php.ini is set to syslog)
error_log("This is an error_log message, typically goes to Apache/PHP error log (if not configured to syslog).");