Lab 17: Using journalctl for Log Analysis
Objectives
By the end of this lab, students will be able to:

• Understand the systemd journal and its advantages over traditional log files • Use journalctl to view and navigate system logs effectively • Filter logs based on time ranges, priority levels, and specific services • Configure persistent log storage for long-term log retention • Apply log analysis techniques for system troubleshooting and monitoring

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Familiarity with systemd services and units • Knowledge of basic Linux system administration concepts • Understanding of log levels and system monitoring principles

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes: • CentOS/RHEL 8 or 9 system with systemd • Full root access for system configuration • Pre-installed journalctl and systemd tools • Sample log entries for practice

Task 1: View Logs with journalctl
Subtask 1.1: Understanding the systemd Journal
The systemd journal is a centralized logging system that collects and stores log data from various sources including kernel messages, system services, and applications.

Step 1: Access your lab environment and open a terminal as root user.

sudo su -
Step 2: View the basic journal help to understand available options.

journalctl --help | head -20
Step 3: Display all journal entries (this may produce a lot of output).

journalctl
Note: Use q to quit the pager when viewing logs.

Subtask 1.2: Basic Log Viewing Commands
Step 1: View the most recent log entries (last 10 lines by default).

journalctl -n
Step 2: View the last 20 log entries.

journalctl -n 20
Step 3: Follow the journal in real-time (similar to tail -f).

journalctl -f
Note: Press Ctrl+C to stop following the logs.

Step 4: View logs in reverse chronological order (newest first).

journalctl -r
Step 5: Display logs without paging (useful for scripting).

journalctl --no-pager -n 5
Subtask 1.3: Viewing Logs with Different Output Formats
Step 1: View logs in JSON format for structured analysis.

journalctl -o json -n 3
Step 2: View logs in a more verbose format showing all available fields.

journalctl -o verbose -n 2
Step 3: View logs in short format (default human-readable format).

journalctl -o short -n 5
Task 2: Filter Logs Based on Time, Priority, and Unit
Subtask 2.1: Time-Based Filtering
Step 1: View logs from today only.

journalctl --since today
Step 2: View logs from yesterday.

journalctl --since yesterday --until today
Step 3: View logs from the last hour.

journalctl --since "1 hour ago"
Step 4: View logs from a specific date and time range.

journalctl --since "2024-01-01 00:00:00" --until "2024-01-01 23:59:59"
Step 5: View logs from the last 30 minutes.

journalctl --since "30 minutes ago"
Subtask 2.2: Priority-Based Filtering
Understanding log priorities (from highest to lowest): • emerg (0): System is unusable • alert (1): Action must be taken immediately • crit (2): Critical conditions • err (3): Error conditions • warning (4): Warning conditions • notice (5): Normal but significant conditions • info (6): Informational messages • debug (7): Debug-level messages

Step 1: View only error messages and above (emerg, alert, crit, err).

journalctl -p err
Step 2: View only warning messages and above.

journalctl -p warning
Step 3: View only critical messages and above.

journalctl -p crit
Step 4: Generate some test log entries to practice filtering.

logger -p user.err "This is a test error message"
logger -p user.warning "This is a test warning message"
logger -p user.info "This is a test info message"
Step 5: Verify the test messages were logged.

journalctl -p info --since "1 minute ago" | grep "test"
Subtask 2.3: Unit-Based Filtering
Step 1: List all available systemd units that have logged messages.

journalctl -F _SYSTEMD_UNIT | head -10
Step 2: View logs for the SSH service only.

journalctl -u sshd
Step 3: View logs for the NetworkManager service.

journalctl -u NetworkManager
Step 4: View logs for multiple units simultaneously.

journalctl -u sshd -u NetworkManager --since today
Step 5: View logs for the kernel.

journalctl -k
Step 6: View logs for a specific process ID (replace XXXX with an actual PID).

# First, find a running process PID
ps aux | grep systemd | head -1
# Then view logs for that PID (replace 1 with actual PID)
journalctl _PID=1 -n 5
Subtask 2.4: Combining Filters
Step 1: View SSH service errors from today.

journalctl -u sshd -p err --since today
Step 2: View all warning and error messages from the last 2 hours.

journalctl -p warning --since "2 hours ago"
Step 3: View NetworkManager logs from yesterday with info level and above.

journalctl -u NetworkManager -p info --since yesterday --until today
Task 3: Set Up Persistent Log Storage
Subtask 3.1: Understanding Journal Storage
Step 1: Check current journal storage configuration.

journalctl --disk-usage
Step 2: View journal configuration file.

cat /etc/systemd/journald.conf
Step 3: Check if persistent storage is currently enabled.

ls -la /var/log/journal/
Note: If the directory doesn't exist, logs are stored in volatile memory only.

Subtask 3.2: Enable Persistent Storage
Step 1: Create the journal directory for persistent storage.

mkdir -p /var/log/journal
Step 2: Set proper ownership and permissions.

chown root:systemd-journal /var/log/journal
chmod 2755 /var/log/journal
Step 3: Create a backup of the journal configuration file.

cp /etc/systemd/journald.conf /etc/systemd/journald.conf.backup
Step 4: Edit the journal configuration to enable persistent storage.

cat > /etc/systemd/journald.conf << 'EOF'
[Journal]
Storage=persistent
Compress=yes
SyncIntervalSec=5m
RateLimitInterval=30s
RateLimitBurst=1000
SystemMaxUse=500M
SystemKeepFree=1G
SystemMaxFileSize=50M
MaxRetentionSec=1month
MaxFileSec=1week
ForwardToSyslog=no
ForwardToKMsg=no
ForwardToConsole=no
ForwardToWall=yes
EOF
Step 5: Restart the systemd-journald service to apply changes.

systemctl restart systemd-journald
Step 6: Verify the service restarted successfully.

systemctl status systemd-journald
Subtask 3.3: Verify Persistent Storage Configuration
Step 1: Check that persistent storage is now active.

ls -la /var/log/journal/
Step 2: Verify journal files are being created.

ls -la /var/log/journal/*/
Step 3: Check current disk usage after enabling persistence.

journalctl --disk-usage
Step 4: Generate some test log entries.

for i in {1..10}; do
    logger "Test persistent log entry $i"
done
Step 5: Verify the test entries are stored persistently.

journalctl --since "1 minute ago" | grep "Test persistent"
Step 6: Reboot the system to test persistence (optional - only if instructor permits).

# Only run if instructor allows system reboot
# systemctl reboot
Subtask 3.4: Managing Journal Storage
Step 1: View detailed journal statistics.

journalctl --disk-usage
journalctl --verify
Step 2: Manually clean old journal files (keep only last 2 days).

journalctl --vacuum-time=2d
Step 3: Limit journal size to 100MB.

journalctl --vacuum-size=100M
Step 4: Keep only the most recent 50 journal files.

journalctl --vacuum-files=50
Step 5: View the current journal configuration in effect.

systemctl show systemd-journald | grep -E "(Storage|MaxUse|KeepFree)"
Advanced Filtering and Analysis
Subtask 4.1: Advanced Query Techniques
Step 1: Search for specific text patterns in logs.

journalctl | grep -i "error"
Step 2: Use journalctl's built-in grep functionality.

journalctl -g "failed"
Step 3: View logs for a specific user.

journalctl _UID=0 -n 10
Step 4: View logs from a specific boot.

journalctl --list-boots
journalctl -b 0  # Current boot
journalctl -b -1 # Previous boot
Step 5: Export logs to a file for analysis.

journalctl --since today --output=json > /tmp/today_logs.json
Subtask 4.2: Monitoring and Alerting
Step 1: Create a simple script to monitor for critical errors.

cat > /usr/local/bin/log_monitor.sh << 'EOF'
#!/bin/bash
# Simple log monitoring script

LOGFILE="/var/log/critical_alerts.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Check for critical errors in the last 5 minutes
CRITICAL_COUNT=$(journalctl -p crit --since "5 minutes ago" --no-pager | wc -l)

if [ $CRITICAL_COUNT -gt 0 ]; then
    echo "[$TIMESTAMP] ALERT: $CRITICAL_COUNT critical errors found in the last 5 minutes" >> $LOGFILE
    journalctl -p crit --since "5 minutes ago" --no-pager >> $LOGFILE
fi
EOF
Step 2: Make the script executable.

chmod +x /usr/local/bin/log_monitor.sh
Step 3: Test the monitoring script.

/usr/local/bin/log_monitor.sh
Step 4: Generate a critical error to test the script.

logger -p user.crit "Test critical error for monitoring"
/usr/local/bin/log_monitor.sh
cat /var/log/critical_alerts.log
Troubleshooting Common Issues
Issue 1: Journal Not Persisting After Reboot
Solution: Ensure the journal directory exists and has correct permissions.

mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal
systemctl restart systemd-journald
Issue 2: Journal Taking Too Much Disk Space
Solution: Configure size limits and clean old logs.

journalctl --disk-usage
journalctl --vacuum-size=200M
Issue 3: Cannot View Logs for Specific Service
Solution: Verify the service name and check if it's generating logs.

systemctl list-units --type=service | grep servicename
journalctl -u servicename.service --since today
Verification and Testing
Step 1: Verify all configurations are working correctly.

# Check journal status
systemctl status systemd-journald

# Verify persistent storage
ls -la /var/log/journal/

# Check disk usage
journalctl --disk-usage

# Test filtering
journalctl -p warning --since "1 hour ago" -n 5
Step 2: Create a comprehensive test to verify all functionality.

# Generate test logs
logger -p user.info "Lab 17 verification: Info message"
logger -p user.warning "Lab 17 verification: Warning message"
logger -p user.err "Lab 17 verification: Error message"

# Verify filtering works
echo "=== Testing priority filtering ==="
journalctl -p warning --since "1 minute ago" | grep "Lab 17"

echo "=== Testing time filtering ==="
journalctl --since "1 minute ago" | grep "Lab 17"

echo "=== Testing persistent storage ==="
ls -la /var/log/journal/*/system.journal
Conclusion
In this lab, you have successfully learned how to use journalctl for comprehensive log analysis on Linux systems. You accomplished the following key tasks:

• Mastered basic log viewing: You learned how to view, navigate, and format system logs using various journalctl commands and options.

• Implemented advanced filtering: You practiced filtering logs based on time ranges, priority levels, and specific system units, enabling targeted troubleshooting and analysis.

• Configured persistent storage: You set up persistent log storage to ensure logs survive system reboots, configured storage limits, and implemented log rotation policies.

• Applied practical skills: You created monitoring scripts and learned troubleshooting techniques that are essential for real-world system administration.

Why This Matters: The systemd journal is a powerful centralized logging system that provides structured, searchable, and reliable log data. These skills are crucial for:

System troubleshooting: Quickly identifying and resolving system issues
Security monitoring: Detecting suspicious activities and security breaches
Performance analysis: Understanding system behavior and resource usage
Compliance requirements: Maintaining audit trails and log retention policies
Red Hat certification: These journalctl skills are essential for RHCSA certification success
The techniques you've learned in this lab form the foundation for effective Linux system monitoring and are directly applicable to enterprise environments where reliable logging and analysis are critical for maintaining system health and security.
