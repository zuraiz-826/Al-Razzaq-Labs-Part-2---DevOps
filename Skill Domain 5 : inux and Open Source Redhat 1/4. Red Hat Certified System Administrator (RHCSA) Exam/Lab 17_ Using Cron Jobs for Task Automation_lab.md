Lab 17: Using Cron Jobs for Task Automation
Objectives
By the end of this lab, you will be able to:

Understand the purpose and functionality of cron jobs for task automation
Create and configure cron jobs using the crontab command
Schedule one-time tasks using the at command
Monitor and verify cron job execution
Troubleshoot common cron job issues
Implement practical automation scenarios for system administration
Prerequisites
Before starting this lab, you should have:

Basic knowledge of Linux command line operations
Understanding of file permissions and ownership
Familiarity with text editors like nano or vi
Basic understanding of shell scripting concepts
Knowledge of system processes and services
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machine or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
Pre-installed cron service
Text editors (nano, vi)
Standard system utilities
Task 1: Understanding and Creating Cron Jobs
Subtask 1.1: Verify Cron Service Status
First, let's check if the cron service is running on your system.

# Check if crond service is active
systemctl status crond

# If not running, start the service
sudo systemctl start crond

# Enable the service to start at boot
sudo systemctl enable crond
Subtask 1.2: Understanding Cron Syntax
The cron syntax follows this format:

* * * * * command-to-execute
| | | | |
| | | | +-- Day of week (0-7, Sunday = 0 or 7)
| | | +---- Month (1-12)
| | +------ Day of month (1-31)
| +-------- Hour (0-23)
+---------- Minute (0-59)
Common Examples:

0 2 * * * - Run at 2:00 AM every day
30 14 * * 1 - Run at 2:30 PM every Monday
0 0 1 * * - Run at midnight on the 1st of every month
*/15 * * * * - Run every 15 minutes
Subtask 1.3: Create Your First Cron Job
Let's create a simple cron job that logs system information every 5 minutes.

# Open the crontab editor for the current user
crontab -e
If prompted to choose an editor, select nano (option 1) for beginners.

Add the following line to create your first cron job:

# Log system uptime every 5 minutes
*/5 * * * * echo "$(date): System uptime: $(uptime)" >> /home/$(whoami)/system_log.txt
Save and exit the editor:

In nano: Press Ctrl+X, then Y, then Enter
In vi: Press Esc, type :wq, then Enter
Subtask 1.4: Create a Backup Script and Schedule It
Create a script that backs up important files:

# Create a backup directory
mkdir -p /home/$(whoami)/backups

# Create a backup script
cat > /home/$(whoami)/backup_script.sh << 'EOF'
#!/bin/bash

# Backup script for important files
BACKUP_DIR="/home/$(whoami)/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_$DATE.tar.gz"

# Create backup of home directory (excluding backups folder)
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    --exclude="$BACKUP_DIR" \
    /home/$(whoami)/ 2>/dev/null

# Keep only the last 5 backups
cd "$BACKUP_DIR"
ls -t backup_*.tar.gz | tail -n +6 | xargs -r rm

echo "$(date): Backup completed - $BACKUP_FILE" >> /home/$(whoami)/backup_log.txt
EOF

# Make the script executable
chmod +x /home/$(whoami)/backup_script.sh
Now schedule this backup script to run daily at 3:00 AM:

# Edit crontab
crontab -e

# Add this line to run backup daily at 3:00 AM
0 3 * * * /home/$(whoami)/backup_script.sh
Subtask 1.5: Create a System Monitoring Cron Job
Create a script that monitors disk usage and sends alerts:

# Create monitoring script
cat > /home/$(whoami)/disk_monitor.sh << 'EOF'
#!/bin/bash

# Disk usage monitoring script
THRESHOLD=80
LOG_FILE="/home/$(whoami)/disk_monitor.log"

# Check disk usage for root partition
USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ "$USAGE" -gt "$THRESHOLD" ]; then
    echo "$(date): WARNING - Disk usage is ${USAGE}% (threshold: ${THRESHOLD}%)" >> "$LOG_FILE"
    # In a real environment, you might send an email or notification here
else
    echo "$(date): OK - Disk usage is ${USAGE}%" >> "$LOG_FILE"
fi
EOF

# Make executable
chmod +x /home/$(whoami)/disk_monitor.sh
Schedule this to run every hour:

# Edit crontab
crontab -e

# Add this line to check disk usage every hour
0 * * * * /home/$(whoami)/disk_monitor.sh
Task 2: Using the 'at' Command for One-Time Tasks
Subtask 2.1: Install and Configure 'at' Service
# Check if at service is installed and running
systemctl status atd

# If not installed (on some minimal systems)
sudo yum install at -y  # For RHEL/CentOS
# or
sudo apt install at -y  # For Ubuntu/Debian

# Start and enable the at service
sudo systemctl start atd
sudo systemctl enable atd
Subtask 2.2: Schedule One-Time Tasks with 'at'
Let's schedule various one-time tasks:

# Schedule a task to run in 2 minutes
echo "echo 'Hello from at command!' >> /home/$(whoami)/at_test.txt" | at now + 2 minutes

# Schedule a task for a specific time today
echo "echo 'Scheduled task executed at $(date)' >> /home/$(whoami)/scheduled_task.txt" | at 16:30

# Schedule a task for tomorrow
echo "echo 'Tomorrow task: $(date)' >> /home/$(whoami)/tomorrow_task.txt" | at 10:00 tomorrow

# Schedule a system information collection task
at now + 1 minute << 'EOF'
echo "=== System Information Report ===" > /home/$(whoami)/system_report.txt
echo "Date: $(date)" >> /home/$(whoami)/system_report.txt
echo "Uptime: $(uptime)" >> /home/$(whoami)/system_report.txt
echo "Memory Usage:" >> /home/$(whoami)/system_report.txt
free -h >> /home/$(whoami)/system_report.txt
echo "Disk Usage:" >> /home/$(whoami)/system_report.txt
df -h >> /home/$(whoami)/system_report.txt
EOF
Subtask 2.3: Manage 'at' Jobs
# List all pending at jobs
atq

# View details of a specific job (replace 1 with actual job number)
at -c 1

# Remove a specific at job (replace 1 with actual job number)
atrm 1

# Remove all at jobs for current user
atq | awk '{print $1}' | xargs -r atrm
Task 3: Monitor and Verify Cron Job Execution
Subtask 3.1: View Current Cron Jobs
# List cron jobs for current user
crontab -l

# List cron jobs for root user (requires sudo)
sudo crontab -l

# List cron jobs for a specific user (requires appropriate permissions)
sudo crontab -u username -l
Subtask 3.2: Monitor Cron Job Execution
# Check system cron logs
sudo tail -f /var/log/cron

# Check for cron-related messages in system log
sudo grep CRON /var/log/messages | tail -10

# On systems using journald
sudo journalctl -u crond -f
Subtask 3.3: Create a Cron Job Testing Script
Create a comprehensive script to test cron job functionality:

cat > /home/$(whoami)/cron_test.sh << 'EOF'
#!/bin/bash

# Cron job testing script
LOG_FILE="/home/$(whoami)/cron_test.log"
TEST_FILE="/home/$(whoami)/cron_test_output.txt"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
}

# Test basic functionality
log_message "Cron test script started"

# Test environment variables
log_message "USER: $USER"
log_message "HOME: $HOME"
log_message "PATH: $PATH"
log_message "PWD: $PWD"

# Test file operations
echo "Cron test executed at $(date)" >> "$TEST_FILE"

# Test command execution
UPTIME_INFO=$(uptime)
log_message "System uptime: $UPTIME_INFO"

# Test error handling
if [ -w "$LOG_FILE" ]; then
    log_message "Log file is writable - OK"
else
    log_message "ERROR: Cannot write to log file"
fi

log_message "Cron test script completed"
EOF

chmod +x /home/$(whoami)/cron_test.sh
Schedule this test script to run every 2 minutes:

crontab -e

# Add this line
*/2 * * * * /home/$(whoami)/cron_test.sh
Subtask 3.4: Create a Cron Job Status Dashboard
Create a script that provides an overview of cron job status:

cat > /home/$(whoami)/cron_dashboard.sh << 'EOF'
#!/bin/bash

# Cron Job Status Dashboard
echo "=================================="
echo "    CRON JOB STATUS DASHBOARD"
echo "=================================="
echo "Generated on: $(date)"
echo

# Show current user's cron jobs
echo "Current User Cron Jobs:"
echo "----------------------"
crontab -l 2>/dev/null || echo "No cron jobs found for current user"
echo

# Show recent cron activity
echo "Recent Cron Activity (last 10 entries):"
echo "---------------------------------------"
sudo grep CRON /var/log/messages 2>/dev/null | tail -10 || \
sudo journalctl -u crond --no-pager -n 10 2>/dev/null || \
echo "Unable to access cron logs"
echo

# Show at jobs
echo "Pending 'at' Jobs:"
echo "------------------"
atq 2>/dev/null || echo "No pending at jobs"
echo

# Show cron service status
echo "Cron Service Status:"
echo "-------------------"
systemctl is-active crond 2>/dev/null || echo "Unable to check service status"
echo

# Check for common cron files
echo "System Cron Files:"
echo "-----------------"
ls -la /etc/cron* 2>/dev/null | head -10
echo

echo "Dashboard generation completed."
EOF

chmod +x /home/$(whoami)/cron_dashboard.sh
Run the dashboard:

./cron_dashboard.sh
Subtask 3.5: Verify Cron Job Execution
Wait a few minutes and then verify that your cron jobs are working:

# Check if the system log file was created and updated
ls -la /home/$(whoami)/system_log.txt
tail -5 /home/$(whoami)/system_log.txt

# Check the cron test log
ls -la /home/$(whoami)/cron_test.log
tail -10 /home/$(whoami)/cron_test.log

# Check disk monitoring log
ls -la /home/$(whoami)/disk_monitor.log
tail -5 /home/$(whoami)/disk_monitor.log

# Check at command results
ls -la /home/$(whoami)/at_test.txt
cat /home/$(whoami)/at_test.txt 2>/dev/null || echo "At test file not found yet"
Advanced Cron Job Examples
Example 1: Log Rotation Cron Job
cat > /home/$(whoami)/log_rotation.sh << 'EOF'
#!/bin/bash

# Simple log rotation script
LOG_DIR="/home/$(whoami)"
MAX_SIZE=1048576  # 1MB in bytes

for log_file in "$LOG_DIR"/*.log; do
    if [ -f "$log_file" ] && [ $(stat -c%s "$log_file") -gt $MAX_SIZE ]; then
        mv "$log_file" "${log_file}.old"
        touch "$log_file"
        echo "$(date): Rotated $log_file" >> "$LOG_DIR/rotation.log"
    fi
done
EOF

chmod +x /home/$(whoami)/log_rotation.sh

# Schedule to run daily at midnight
# Add to crontab: 0 0 * * * /home/$(whoami)/log_rotation.sh
Example 2: System Health Check
cat > /home/$(whoami)/health_check.sh << 'EOF'
#!/bin/bash

# System health check script
HEALTH_LOG="/home/$(whoami)/health_check.log"

echo "=== Health Check - $(date) ===" >> "$HEALTH_LOG"

# Check CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
echo "CPU Usage: ${CPU_USAGE}%" >> "$HEALTH_LOG"

# Check memory usage
MEM_USAGE=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
echo "Memory Usage: ${MEM_USAGE}%" >> "$HEALTH_LOG"

# Check disk usage
DISK_USAGE=$(df / | awk 'NR==2 {print $5}')
echo "Disk Usage: $DISK_USAGE" >> "$HEALTH_LOG"

# Check load average
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')
echo "Load Average:$LOAD_AVG" >> "$HEALTH_LOG"

echo "Health check completed" >> "$HEALTH_LOG"
echo "" >> "$HEALTH_LOG"
EOF

chmod +x /home/$(whoami)/health_check.sh

# Schedule to run every 30 minutes
# Add to crontab: */30 * * * * /home/$(whoami)/health_check.sh
Troubleshooting Common Issues
Issue 1: Cron Job Not Running
Symptoms: Cron job appears in crontab but doesn't execute

Solutions:

# Check if cron service is running
systemctl status crond

# Check cron logs for errors
sudo tail -f /var/log/cron

# Verify script permissions
ls -la /path/to/your/script.sh

# Test script manually
/path/to/your/script.sh
Issue 2: Environment Variables Not Available
Symptoms: Script works manually but fails in cron

Solutions:

# Add environment variables to crontab
crontab -e

# Add these lines at the top
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
HOME=/home/yourusername

# Or source the environment in your script
#!/bin/bash
source /etc/environment
source ~/.bashrc
Issue 3: Permission Denied Errors
Symptoms: Cron job fails with permission errors

Solutions:

# Make script executable
chmod +x /path/to/script.sh

# Check file ownership
ls -la /path/to/script.sh

# Fix ownership if needed
chown username:username /path/to/script.sh
Best Practices for Cron Jobs
1. Always Use Full Paths
# Good
0 2 * * * /usr/bin/python3 /home/user/script.py

# Avoid
0 2 * * * python3 script.py
2. Redirect Output Appropriately
# Redirect both stdout and stderr
0 2 * * * /path/to/script.sh >> /var/log/script.log 2>&1

# Discard output if not needed
0 2 * * * /path/to/script.sh > /dev/null 2>&1
3. Test Scripts Before Scheduling
# Always test manually first
./your_script.sh

# Test with the same environment cron uses
env -i /bin/bash --noprofile --norc -c './your_script.sh'
4. Use Proper Error Handling
#!/bin/bash
set -e  # Exit on any error

# Your script content here
if ! command_that_might_fail; then
    echo "Error occurred" >> /var/log/error.log
    exit 1
fi
Conclusion
In this lab, you have successfully learned how to:

Automate repetitive tasks using cron jobs, which is essential for system administration and maintenance
Create and schedule cron jobs using the crontab command with proper syntax and timing
Use the 'at' command to schedule one-time tasks for specific future execution
Monitor and verify cron job execution through logs and testing scripts
Troubleshoot common issues that arise with automated task scheduling
Implement best practices for reliable and maintainable automation
Why This Matters: Task automation is crucial for system administrators because it:

Reduces manual workload and human error
Ensures consistent execution of maintenance tasks
Enables 24/7 system monitoring and maintenance
Improves system reliability and uptime
Allows administrators to focus on more strategic tasks
The skills you've learned in this lab are directly applicable to the Red Hat Certified System Administrator (RHCSA) exam and real-world system administration scenarios. You can now confidently automate backups, system monitoring, log rotation, and other critical system maintenance tasks.

Remember to always test your scripts manually before scheduling them, use full paths in your cron jobs, and monitor the execution logs to ensure your automation is working as expected.
