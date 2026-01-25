Lab 16: Using journalctl for System Logs
Objectives
By the end of this lab, you will be able to:

Navigate and filter system logs using journalctl commands
Configure persistent log storage for long-term log retention
Analyze system logs to identify and troubleshoot common system issues
Use advanced journalctl filtering options to locate specific log entries
Understand the systemd journal structure and log levels
Implement log rotation and storage management best practices
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line interface
Familiarity with systemd services and system administration concepts
Knowledge of basic text editing using vi/vim or nano
Understanding of file permissions and directory structures
Basic troubleshooting mindset and analytical thinking skills
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install any software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with systemd
Full root access for system configuration
Pre-installed journalctl and systemd tools
Sample log data for practice exercises
Task 1: View and Filter Logs Using journalctl
Subtask 1.1: Basic journalctl Commands
First, let's explore the basic functionality of journalctl to view system logs.

Step 1: Access your system and check the journal service status

# Check if systemd-journald is running
sudo systemctl status systemd-journald

# View basic system information
hostnamectl
Step 2: Display recent system logs

# View the most recent log entries (last 10 lines by default)
sudo journalctl

# View logs in real-time (similar to tail -f)
sudo journalctl -f

# Press Ctrl+C to stop the real-time view
Step 3: Navigate through log entries

# View logs with paging (use arrow keys, Page Up/Down, q to quit)
sudo journalctl --no-pager

# Show specific number of recent entries
sudo journalctl -n 20

# Show logs from the beginning
sudo journalctl --no-pager | head -50
Subtask 1.2: Time-Based Filtering
Learn to filter logs based on time periods to focus on specific timeframes.

Step 1: View logs from specific time periods

# Show logs from today
sudo journalctl --since today

# Show logs from yesterday
sudo journalctl --since yesterday

# Show logs from the last hour
sudo journalctl --since "1 hour ago"

# Show logs from a specific date and time
sudo journalctl --since "2024-01-01 00:00:00"
Step 2: Use time ranges for targeted analysis

# Show logs between specific times
sudo journalctl --since "2024-01-01" --until "2024-01-02"

# Show logs from the last 30 minutes
sudo journalctl --since "30 minutes ago"

# Show logs from boot time to 1 hour ago
sudo journalctl --until "1 hour ago"
Subtask 1.3: Service and Unit Filtering
Filter logs by specific services and systemd units.

Step 1: View logs for specific services

# View SSH service logs
sudo journalctl -u sshd

# View NetworkManager logs
sudo journalctl -u NetworkManager

# View all systemd service logs
sudo journalctl -u "*.service"
Step 2: Combine service filtering with time filtering

# View SSH logs from today
sudo journalctl -u sshd --since today

# View multiple services
sudo journalctl -u sshd -u NetworkManager --since "1 hour ago"

# View service logs with follow mode
sudo journalctl -u sshd -f
Subtask 1.4: Priority and Log Level Filtering
Filter logs based on severity levels to focus on critical issues.

Step 1: Understand log priority levels

# View only error messages and above (emerg, alert, crit, err)
sudo journalctl -p err

# View warning messages and above
sudo journalctl -p warning

# View info messages and above
sudo journalctl -p info

# View debug messages (most verbose)
sudo journalctl -p debug
Step 2: Combine priority filtering with other filters

# View SSH errors from today
sudo journalctl -u sshd -p err --since today

# View all critical system errors
sudo journalctl -p crit --since "24 hours ago"
Task 2: Configure Persistent Log Storage
Subtask 2.1: Check Current Journal Configuration
Examine the current journal storage configuration and understand the default settings.

Step 1: Check journal storage status

# Check current journal configuration
sudo journalctl --disk-usage

# View journal configuration file
sudo cat /etc/systemd/journald.conf

# Check if persistent storage is enabled
ls -la /var/log/journal/
Step 2: Examine journal storage locations

# Check runtime journal location (temporary)
ls -la /run/log/journal/

# Check system journal statistics
sudo systemctl status systemd-journald

# View journal verification
sudo journalctl --verify
Subtask 2.2: Enable Persistent Journal Storage
Configure the system to store logs persistently across reboots.

Step 1: Create persistent storage directory

# Create the journal directory for persistent storage
sudo mkdir -p /var/log/journal

# Set proper ownership and permissions
sudo chown root:systemd-journal /var/log/journal
sudo chmod 2755 /var/log/journal
Step 2: Configure journald for persistent storage

# Backup the original configuration
sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.backup

# Edit the journal configuration
sudo nano /etc/systemd/journald.conf
Add or modify the following lines in the configuration file:

[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=1G
SystemKeepFree=500M
SystemMaxFileSize=100M
MaxRetentionSec=1month
Step 3: Apply the configuration changes

# Restart the journald service
sudo systemctl restart systemd-journald

# Verify the service is running
sudo systemctl status systemd-journald

# Check that persistent storage is now active
ls -la /var/log/journal/
sudo journalctl --disk-usage
Subtask 2.3: Configure Log Rotation and Retention
Set up proper log rotation to manage disk space effectively.

Step 1: Configure size-based rotation

# Edit the journald configuration for rotation settings
sudo nano /etc/systemd/journald.conf
Ensure these settings are configured:

[Journal]
SystemMaxUse=2G
SystemKeepFree=1G
SystemMaxFileSize=200M
SystemMaxFiles=10
RuntimeMaxUse=500M
RuntimeKeepFree=100M
Step 2: Configure time-based retention

# Add time-based retention settings
MaxRetentionSec=2month
MaxFileSec=1week
Step 3: Apply and verify rotation settings

# Restart journald to apply changes
sudo systemctl restart systemd-journald

# Force log rotation for testing
sudo systemctl kill --signal=SIGUSR2 systemd-journald

# Verify current disk usage
sudo journalctl --disk-usage

# Check journal files
ls -lh /var/log/journal/*/
Task 3: Investigate Logs to Diagnose System Errors
Subtask 3.1: Identify Common System Issues
Learn to recognize and investigate common system problems through log analysis.

Step 1: Generate test log entries for practice

# Generate some test log entries
logger -p user.info "Test info message for lab practice"
logger -p user.warning "Test warning message for lab practice"
logger -p user.err "Test error message for lab practice"

# Create a failed service attempt
sudo systemctl start nonexistent-service 2>/dev/null || true
Step 2: Search for authentication issues

# Look for failed login attempts
sudo journalctl -u sshd | grep -i "failed\|error\|denied"

# Search for authentication failures
sudo journalctl | grep -i "authentication failure"

# Look for sudo usage
sudo journalctl | grep -i sudo
Step 3: Investigate boot issues

# View boot messages
sudo journalctl -b

# View previous boot logs (if available)
sudo journalctl -b -1

# List all available boots
sudo journalctl --list-boots

# View kernel messages
sudo journalctl -k
Subtask 3.2: Advanced Log Analysis Techniques
Use advanced journalctl features for comprehensive system analysis.

Step 1: Use JSON output for detailed analysis

# Output logs in JSON format for detailed analysis
sudo journalctl -u sshd -o json | head -5

# Use JSON-pretty format for readable output
sudo journalctl -u sshd -o json-pretty -n 3
Step 2: Search and filter with grep and other tools

# Search for specific error patterns
sudo journalctl --since "1 hour ago" | grep -i "error\|fail\|critical"

# Count error occurrences
sudo journalctl --since today | grep -c -i error

# Find unique error messages
sudo journalctl -p err --since today | grep -o "error.*" | sort | uniq -c
Step 3: Analyze system performance issues

# Look for memory-related issues
sudo journalctl | grep -i "out of memory\|oom\|memory"

# Search for disk space issues
sudo journalctl | grep -i "no space\|disk full\|filesystem"

# Check for network-related problems
sudo journalctl -u NetworkManager --since "1 hour ago"
Subtask 3.3: Create a System Health Report
Generate a comprehensive system health report using journalctl.

Step 1: Create a log analysis script

# Create a system health check script
sudo nano /usr/local/bin/system-health-check.sh
Add the following content to the script:

#!/bin/bash

echo "=== System Health Report ==="
echo "Generated on: $(date)"
echo "Hostname: $(hostname)"
echo ""

echo "=== Disk Usage for Journal ==="
sudo journalctl --disk-usage
echo ""

echo "=== Recent Critical Errors ==="
sudo journalctl -p crit --since "24 hours ago" --no-pager
echo ""

echo "=== Failed Services ==="
sudo systemctl --failed
echo ""

echo "=== Recent Boot Information ==="
sudo journalctl -b --no-pager | head -20
echo ""

echo "=== Authentication Failures (Last 24 Hours) ==="
sudo journalctl --since "24 hours ago" | grep -i "authentication failure" | tail -10
echo ""

echo "=== System Resource Warnings ==="
sudo journalctl --since "24 hours ago" | grep -i "memory\|disk\|cpu" | grep -i "warning\|error" | tail -10
echo ""

echo "=== Report Complete ==="
Step 2: Make the script executable and run it

# Make the script executable
sudo chmod +x /usr/local/bin/system-health-check.sh

# Run the health check
sudo /usr/local/bin/system-health-check.sh
Step 3: Schedule regular health checks

# Create a cron job for daily health checks
echo "0 6 * * * /usr/local/bin/system-health-check.sh > /var/log/daily-health-report.log 2>&1" | sudo crontab -

# Verify the cron job
sudo crontab -l
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Journal logs not persisting after reboot

Solution: Ensure /var/log/journal directory exists with proper permissions
Command: sudo mkdir -p /var/log/journal && sudo chown root:systemd-journal /var/log/journal
Issue 2: Journal consuming too much disk space

Solution: Configure SystemMaxUse in /etc/systemd/journald.conf
Command: sudo journalctl --vacuum-size=1G to clean up immediately
Issue 3: Cannot view logs due to permission issues

Solution: Add user to systemd-journal group or use sudo
Command: sudo usermod -a -G systemd-journal username
Issue 4: Logs are not showing recent entries

Solution: Restart journald service and check system time
Command: sudo systemctl restart systemd-journald && timedatectl status
Verification Commands
Use these commands to verify your lab completion:

# Verify persistent storage is working
sudo journalctl --disk-usage
ls -la /var/log/journal/

# Verify configuration changes
sudo systemctl status systemd-journald
cat /etc/systemd/journald.conf | grep -v "^#" | grep -v "^$"

# Test log filtering capabilities
sudo journalctl -p err --since "1 hour ago" -n 5

# Verify health check script
ls -la /usr/local/bin/system-health-check.sh
sudo /usr/local/bin/system-health-check.sh | head -20
Conclusion
In this lab, you have successfully learned to use journalctl for comprehensive system log management and analysis. You accomplished the following key objectives:

What You Learned:

Mastered basic and advanced journalctl commands for viewing and filtering system logs
Configured persistent log storage to retain logs across system reboots
Implemented log rotation and retention policies for efficient disk space management
Developed skills to investigate and diagnose system issues through log analysis
Created automated health check scripts for proactive system monitoring
Why This Matters: System log analysis is a critical skill for system administrators and is essential for the RHCSA certification. The journalctl tool provides powerful capabilities for troubleshooting system issues, monitoring system health, and maintaining system security. By mastering these skills, you can:

Quickly identify and resolve system problems
Maintain system security by monitoring authentication attempts
Optimize system performance through proactive monitoring
Meet compliance requirements for log retention
Prepare effectively for the RHCSA exam
Next Steps: Continue practicing with journalctl in different scenarios, explore integration with monitoring tools, and consider learning about centralized logging solutions for enterprise environments. These skills form the foundation for advanced system administration and DevOps practices.
