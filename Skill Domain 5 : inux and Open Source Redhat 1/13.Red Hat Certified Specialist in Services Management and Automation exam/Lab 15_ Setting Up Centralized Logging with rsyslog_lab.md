Lab 15: Setting Up Centralized Logging with rsyslog
Objectives
By the end of this lab, students will be able to:

Install and configure rsyslog for centralized logging
Set up a remote log server to collect logs from multiple systems
Configure log forwarding from client systems to a central server
Implement log rotation policies to manage disk space
Verify remote log collection and troubleshoot common issues
Understand the importance of centralized logging in system administration
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with text editors (nano, vim, or gedit)
Knowledge of basic networking concepts (IP addresses, ports)
Understanding of system services and systemctl commands
Basic knowledge of file permissions and ownership
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machines.

Lab Setup: You will have access to two CentOS/RHEL-based systems:

Server Machine: Acts as the centralized log server
Client Machine: Sends logs to the central server
Task 1: Install and Configure rsyslog Server
Subtask 1.1: Verify rsyslog Installation
First, let's check if rsyslog is already installed on both systems.

Connect to the Server Machine and check rsyslog status:
# Check if rsyslog is installed
rpm -qa | grep rsyslog

# Check rsyslog service status
systemctl status rsyslog
If rsyslog is not installed, install it:
# Install rsyslog package
sudo yum install rsyslog -y

# For newer systems using dnf
sudo dnf install rsyslog -y
Subtask 1.2: Configure rsyslog Server
Now we'll configure the server to receive logs from remote clients.

Create a backup of the original configuration:
sudo cp /etc/rsyslog.conf /etc/rsyslog.conf.backup
Edit the rsyslog configuration file:
sudo nano /etc/rsyslog.conf
Uncomment and modify the following lines to enable UDP and TCP reception:
# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514
$UDPServerAddress 0.0.0.0

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514
$InputTCPServerAddress 0.0.0.0
Add remote log storage configuration at the end of the file:
# Remote log storage
$template RemoteLogs,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& stop
Create the remote logs directory:
sudo mkdir -p /var/log/remote
sudo chown syslog:adm /var/log/remote
sudo chmod 755 /var/log/remote
Subtask 1.3: Configure Firewall and Start Services
Configure firewall to allow syslog traffic:
# Open UDP port 514
sudo firewall-cmd --permanent --add-port=514/udp

# Open TCP port 514
sudo firewall-cmd --permanent --add-port=514/tcp

# Reload firewall configuration
sudo firewall-cmd --reload

# Verify firewall rules
sudo firewall-cmd --list-ports
Restart and enable rsyslog service:
# Restart rsyslog service
sudo systemctl restart rsyslog

# Enable rsyslog to start at boot
sudo systemctl enable rsyslog

# Verify service status
sudo systemctl status rsyslog
Verify rsyslog is listening on port 514:
# Check listening ports
sudo netstat -tulnp | grep 514

# Alternative command using ss
sudo ss -tulnp | grep 514
Task 2: Configure rsyslog Client
Subtask 2.1: Configure Client to Forward Logs
Now switch to the Client Machine and configure it to send logs to the server.

Create a backup of the client configuration:
sudo cp /etc/rsyslog.conf /etc/rsyslog.conf.backup
Edit the rsyslog configuration on the client:
sudo nano /etc/rsyslog.conf
Add the following lines at the end of the file (replace SERVER_IP with your server's IP address):
# Forward all logs to remote server
*.* @@SERVER_IP:514

# Alternative: Forward only specific facilities
# mail.* @@SERVER_IP:514
# kern.* @@SERVER_IP:514
# auth.* @@SERVER_IP:514
Note: Use @@ for TCP transmission or @ for UDP transmission.

Find your server's IP address if you don't know it:
# On the server machine, run:
ip addr show | grep inet
Subtask 2.2: Create Custom Log Configuration
Create a custom rsyslog configuration file for specific applications:
sudo nano /etc/rsyslog.d/50-remote.conf
Add the following content:
# Custom remote logging configuration
# Send all authentication logs to remote server
auth,authpriv.* @@SERVER_IP:514

# Send all mail logs to remote server
mail.* @@SERVER_IP:514

# Send all kernel logs to remote server
kern.* @@SERVER_IP:514

# Local logging (keep local copies)
auth,authpriv.* /var/log/auth.log
mail.* /var/log/mail.log
kern.* /var/log/kern.log
Restart rsyslog on the client:
sudo systemctl restart rsyslog
sudo systemctl status rsyslog
Task 3: Configure Log Rotation Policies
Subtask 3.1: Configure logrotate for Remote Logs
Create a logrotate configuration for remote logs on the server:
sudo nano /etc/logrotate.d/remote-logs
Add the following configuration:
/var/log/remote/*/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 syslog adm
    postrotate
        /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
    endscript
}
Subtask 3.2: Configure Local Log Rotation
Create logrotate configuration for local logs on both client and server:
sudo nano /etc/logrotate.d/custom-logs
Add the following content:
/var/log/auth.log
/var/log/mail.log
/var/log/kern.log {
    weekly
    missingok
    rotate 12
    compress
    delaycompress
    notifempty
    create 644 syslog adm
    postrotate
        /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
    endscript
}
Test logrotate configuration:
# Test the configuration without actually rotating
sudo logrotate -d /etc/logrotate.d/remote-logs

# Force rotation for testing
sudo logrotate -f /etc/logrotate.d/remote-logs
Subtask 3.3: Set Up Automated Log Cleanup
Create a cleanup script for old logs:
sudo nano /usr/local/bin/log-cleanup.sh
Add the following script content:
#!/bin/bash
# Log cleanup script

LOG_DIR="/var/log/remote"
DAYS_TO_KEEP=30

# Find and remove logs older than specified days
find $LOG_DIR -name "*.log" -type f -mtime +$DAYS_TO_KEEP -delete

# Find and remove empty directories
find $LOG_DIR -type d -empty -delete

# Log cleanup activity
echo "$(date): Log cleanup completed" >> /var/log/log-cleanup.log
Make the script executable:
sudo chmod +x /usr/local/bin/log-cleanup.sh
Add to crontab for automated execution:
# Edit root's crontab
sudo crontab -e

# Add the following line to run cleanup daily at 2 AM
0 2 * * * /usr/local/bin/log-cleanup.sh
Task 4: Verify Remote Log Collection
Subtask 4.1: Generate Test Log Messages
On the client machine, generate test log messages:
# Generate authentication log
sudo logger -p auth.info "Test authentication message from client"

# Generate mail log
sudo logger -p mail.info "Test mail message from client"

# Generate kernel log
sudo logger -p kern.info "Test kernel message from client"

# Generate general system log
sudo logger "General test message from client"
Generate logs using different facilities:
# Generate different priority levels
sudo logger -p auth.debug "Debug level auth message"
sudo logger -p auth.warning "Warning level auth message"
sudo logger -p auth.err "Error level auth message"
sudo logger -p auth.crit "Critical level auth message"
Subtask 4.2: Verify Logs on Server
Check if logs are being received on the server:
# Check remote log directory
ls -la /var/log/remote/

# Check for client hostname directory
ls -la /var/log/remote/CLIENT_HOSTNAME/

# View recent log entries
tail -f /var/log/remote/CLIENT_HOSTNAME/logger.log
Monitor real-time log reception:
# Monitor all remote logs
sudo tail -f /var/log/remote/*/*.log

# Monitor specific log file
sudo tail -f /var/log/remote/CLIENT_HOSTNAME/logger.log
Check rsyslog statistics:
# View rsyslog statistics
sudo rsyslogd -N1 -f /etc/rsyslog.conf

# Check for any errors in rsyslog
sudo journalctl -u rsyslog -f
Subtask 4.3: Verify Log Forwarding
Create a comprehensive test script on the client:
nano ~/test-logging.sh
Add the following content:
#!/bin/bash
# Comprehensive logging test script

echo "Starting logging tests..."

# Test different facilities and priorities
facilities=("auth" "mail" "daemon" "kern" "user" "local0")
priorities=("debug" "info" "notice" "warning" "err" "crit")

for facility in "${facilities[@]}"; do
    for priority in "${priorities[@]}"; do
        logger -p "$facility.$priority" "Test message: $facility.$priority from $(hostname)"
        sleep 1
    done
done

echo "Logging tests completed"
Make the script executable and run it:
chmod +x ~/test-logging.sh
./test-logging.sh
Verify the test results on the server:
# Check for new log files
find /var/log/remote/ -name "*.log" -newer /tmp/test_start 2>/dev/null

# Count log entries
grep -r "Test message" /var/log/remote/ | wc -l
Troubleshooting Common Issues
Issue 1: Logs Not Appearing on Server
Symptoms: Client logs are not showing up on the server

Solutions:

Check network connectivity:
# Test connectivity to server
telnet SERVER_IP 514

# Check if port is open
nmap -p 514 SERVER_IP
Verify firewall settings:
# Check firewall status
sudo firewall-cmd --list-all

# Temporarily disable firewall for testing
sudo systemctl stop firewalld
Check rsyslog configuration:
# Test configuration syntax
sudo rsyslogd -N1 -f /etc/rsyslog.conf

# Check for configuration errors
sudo journalctl -u rsyslog | grep -i error
Issue 2: Permission Denied Errors
Symptoms: Cannot write to log directories

Solutions:

Fix directory permissions:
sudo chown -R syslog:adm /var/log/remote/
sudo chmod -R 755 /var/log/remote/
Check SELinux context (if SELinux is enabled):
# Check SELinux status
sestatus

# Set correct SELinux context
sudo setsebool -P rsyslog_can_network on
sudo semanage port -a -t syslogd_port_t -p tcp 514
sudo semanage port -a -t syslogd_port_t -p udp 514
Issue 3: Log Rotation Not Working
Symptoms: Log files growing too large

Solutions:

Test logrotate manually:
# Test configuration
sudo logrotate -d /etc/logrotate.d/remote-logs

# Force rotation
sudo logrotate -f /etc/logrotate.d/remote-logs
Check logrotate status:
# View logrotate status
cat /var/lib/logrotate/status

# Check for errors
sudo journalctl | grep logrotate
Advanced Configuration
Setting Up TLS Encryption
For production environments, consider encrypting log transmission:

Install rsyslog-gnutls:
sudo yum install rsyslog-gnutls -y
Generate certificates (simplified for lab):
# Create certificate directory
sudo mkdir -p /etc/rsyslog-certs

# Generate self-signed certificate (for testing only)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/rsyslog-certs/server-key.pem \
    -out /etc/rsyslog-certs/server-cert.pem
Configure TLS on server:
# Add to rsyslog.conf
$DefaultNetstreamDriver gtls
$DefaultNetstreamDriverCAFile /etc/rsyslog-certs/server-cert.pem
$DefaultNetstreamDriverCertFile /etc/rsyslog-certs/server-cert.pem
$DefaultNetstreamDriverKeyFile /etc/rsyslog-certs/server-key.pem
$ModLoad imtcp
$InputTCPServerStreamDriverMode 1
$InputTCPServerStreamDriverAuthMode anon
$InputTCPServerRun 6514
Performance Monitoring
Monitor rsyslog Performance
Create monitoring script:
sudo nano /usr/local/bin/rsyslog-monitor.sh
Add monitoring content:
#!/bin/bash
# rsyslog performance monitoring

echo "=== rsyslog Performance Report ==="
echo "Date: $(date)"
echo

# Check service status
echo "Service Status:"
systemctl is-active rsyslog
echo

# Check memory usage
echo "Memory Usage:"
ps aux | grep rsyslog | grep -v grep
echo

# Check log file sizes
echo "Log Directory Sizes:"
du -sh /var/log/remote/* 2>/dev/null | head -10
echo

# Check recent errors
echo "Recent Errors:"
journalctl -u rsyslog --since "1 hour ago" | grep -i error | tail -5
Make executable and run:
sudo chmod +x /usr/local/bin/rsyslog-monitor.sh
sudo /usr/local/bin/rsyslog-monitor.sh
Conclusion
Congratulations! You have successfully completed Lab 15: Setting Up Centralized Logging with rsyslog.

What You Accomplished
In this lab, you have:

Installed and configured rsyslog on both server and client systems
Set up centralized logging to collect logs from multiple systems in one location
Configured log forwarding from client systems to a central server
Implemented log rotation policies to manage disk space and maintain system performance
Verified remote log collection and learned troubleshooting techniques
Created monitoring and maintenance scripts for ongoing log management
Why This Matters
Centralized logging is crucial in modern IT environments because it:

Simplifies log management across multiple systems
Improves security monitoring by consolidating security events
Enables better troubleshooting with centralized log analysis
Supports compliance requirements for log retention and auditing
Reduces administrative overhead by managing logs from a single location
Provides better visibility into system and application behavior
Next Steps
To further enhance your centralized logging setup, consider:

Implementing log analysis tools like ELK Stack (Elasticsearch, Logstash, Kibana)
Setting up log alerting for critical events
Configuring log parsing and filtering for better organization
Implementing log backup and archival strategies
Exploring advanced rsyslog features like templates and rulesets
This knowledge is essential for the Red Hat Certified Specialist in Services Management and Automation exam and will serve you well in real-world system administration scenarios.
