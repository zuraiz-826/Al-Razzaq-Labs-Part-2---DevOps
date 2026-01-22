Lab 12: Automating Tasks with Cron and systemd Timers
Objectives
By the end of this lab, students will be able to:

• Understand the differences between cron and systemd timers for task automation • Create and configure cron jobs using crontab syntax • Set up systemd timers and service units for scheduled tasks • Test and verify automated tasks are running correctly • Debug common issues with scheduled tasks • Monitor and manage automated jobs effectively • Apply best practices for task automation in Linux environments

Prerequisites
Before starting this lab, students should have:

• Basic Linux command-line knowledge • Understanding of file permissions and ownership • Familiarity with text editors (nano, vim, or gedit) • Knowledge of basic shell scripting • Understanding of Linux services and processes • Access to a Linux system with root or sudo privileges

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your lab environment includes: • CentOS/RHEL 8 or 9 system with full root access • Pre-installed cron and systemd services • Text editors and basic utilities • Sample scripts and log directories

Task 1: Understanding and Creating Cron Jobs
Subtask 1.1: Exploring the Cron System
First, let's understand how cron works and examine the current cron configuration.

Check if cron service is running:
sudo systemctl status crond
If cron is not running, start and enable it:
sudo systemctl start crond
sudo systemctl enable crond
View current user's crontab:
crontab -l
Check system-wide cron directories:
ls -la /etc/cron*
Examine the main cron configuration:
cat /etc/crontab
Subtask 1.2: Understanding Cron Syntax
The cron syntax follows this format:

* * * * * command
│ │ │ │ │
│ │ │ │ └── Day of week (0-7, Sunday = 0 or 7)
│ │ │ └──── Month (1-12)
│ │ └────── Day of month (1-31)
│ └──────── Hour (0-23)
└────────── Minute (0-59)
Common Examples: • 0 2 * * * - Run at 2:00 AM every day • */15 * * * * - Run every 15 minutes • 0 9 * * 1-5 - Run at 9:00 AM Monday through Friday • 30 14 1 * * - Run at 2:30 PM on the 1st of every month

Subtask 1.3: Creating Your First Cron Job
Create a simple script to automate:
mkdir -p ~/scripts
cat > ~/scripts/system_info.sh << 'EOF'
#!/bin/bash
# System Information Script
echo "=== System Information Report ===" >> ~/system_reports.log
echo "Date: $(date)" >> ~/system_reports.log
echo "Uptime: $(uptime)" >> ~/system_reports.log
echo "Disk Usage:" >> ~/system_reports.log
df -h >> ~/system_reports.log
echo "Memory Usage:" >> ~/system_reports.log
free -h >> ~/system_reports.log
echo "=================================" >> ~/system_reports.log
echo "" >> ~/system_reports.log
EOF
Make the script executable:
chmod +x ~/scripts/system_info.sh
Test the script manually:
~/scripts/system_info.sh
cat ~/system_reports.log
Open crontab for editing:
crontab -e
Add a cron job to run every 5 minutes:
*/5 * * * * /home/$(whoami)/scripts/system_info.sh
Save and exit the editor, then verify the crontab:
crontab -l
Subtask 1.4: Creating More Complex Cron Jobs
Create a backup script:
cat > ~/scripts/daily_backup.sh << 'EOF'
#!/bin/bash
# Daily Backup Script
BACKUP_DIR="/tmp/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Backup important directories
tar -czf $BACKUP_DIR/home_backup_$DATE.tar.gz ~/scripts ~/system_reports.log 2>/dev/null

# Keep only last 7 days of backups
find $BACKUP_DIR -name "home_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed at $(date)" >> ~/backup.log
EOF
Make the backup script executable:
chmod +x ~/scripts/daily_backup.sh
Add multiple cron jobs:
crontab -e
Add these lines:

# System info every 5 minutes
*/5 * * * * /home/$(whoami)/scripts/system_info.sh

# Daily backup at 2:30 AM
30 2 * * * /home/$(whoami)/scripts/daily_backup.sh

# Weekly cleanup on Sundays at 3:00 AM
0 3 * * 0 find /tmp -name "*.tmp" -mtime +7 -delete
Subtask 1.5: Managing Cron Jobs with Logging
Create a script with proper logging:
cat > ~/scripts/log_monitor.sh << 'EOF'
#!/bin/bash
# Log Monitor Script with proper logging
LOG_FILE=~/cron_monitor.log

{
    echo "=== Log Monitor Started at $(date) ==="
    
    # Check system load
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    echo "Current system load: $LOAD"
    
    # Check disk space
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "Root disk usage: $DISK_USAGE%"
    
    if [ $DISK_USAGE -gt 80 ]; then
        echo "WARNING: Disk usage is above 80%"
    fi
    
    echo "=== Log Monitor Completed at $(date) ==="
    echo ""
} >> $LOG_FILE 2>&1
EOF
Make it executable:
chmod +x ~/scripts/log_monitor.sh
Update crontab with logging:
crontab -e
Add:

# Log monitor every 10 minutes
*/10 * * * * /home/$(whoami)/scripts/log_monitor.sh
Task 2: Setting Up systemd Timers
Subtask 2.1: Understanding systemd Timers
systemd timers are a modern alternative to cron jobs, offering more flexibility and better integration with the systemd ecosystem.

Check existing systemd timers:
systemctl list-timers
View timer status:
systemctl status *.timer
Explore systemd timer directories:
ls -la /etc/systemd/system/*.timer
ls -la /usr/lib/systemd/system/*.timer
Subtask 2.2: Creating Your First systemd Timer
Create a service unit file:
sudo tee /etc/systemd/system/system-status.service << 'EOF'
[Unit]
Description=System Status Reporter
Wants=system-status.timer

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/system-status.sh

[Install]
WantedBy=multi-user.target
EOF
Create the script for the service:
sudo tee /usr/local/bin/system-status.sh << 'EOF'
#!/bin/bash
# System Status Script for systemd
LOG_FILE="/var/log/system-status.log"

{
    echo "=== System Status Report - $(date) ==="
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Load Average: $(cat /proc/loadavg)"
    echo "Memory Info:"
    free -h
    echo "Top 5 Processes by CPU:"
    ps aux --sort=-%cpu | head -6
    echo "================================="
    echo ""
} >> $LOG_FILE
EOF
Make the script executable:
sudo chmod +x /usr/local/bin/system-status.sh
Create the timer unit file:
sudo tee /etc/systemd/system/system-status.timer << 'EOF'
[Unit]
Description=Run system-status.service every 15 minutes
Requires=system-status.service

[Timer]
OnCalendar=*:0/15
Persistent=true

[Install]
WantedBy=timers.target
EOF
Subtask 2.3: Managing systemd Timers
Reload systemd configuration:
sudo systemctl daemon-reload
Enable and start the timer:
sudo systemctl enable system-status.timer
sudo systemctl start system-status.timer
Check timer status:
sudo systemctl status system-status.timer
List all timers to see your new timer:
systemctl list-timers --all
View the timer's next run time:
systemctl list-timers system-status.timer
Subtask 2.4: Creating Advanced systemd Timers
Create a cleanup service:
sudo tee /etc/systemd/system/temp-cleanup.service << 'EOF'
[Unit]
Description=Temporary Files Cleanup Service
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/temp-cleanup.sh
User=root
EOF
Create the cleanup script:
sudo tee /usr/local/bin/temp-cleanup.sh << 'EOF'
#!/bin/bash
# Temporary Files Cleanup Script
LOG_FILE="/var/log/temp-cleanup.log"

{
    echo "=== Temp Cleanup Started - $(date) ==="
    
    # Clean /tmp files older than 7 days
    DELETED_COUNT=$(find /tmp -type f -mtime +7 -delete -print | wc -l)
    echo "Deleted $DELETED_COUNT files from /tmp"
    
    # Clean log files older than 30 days
    find /var/log -name "*.log" -mtime +30 -size +100M -exec truncate -s 0 {} \;
    echo "Truncated large old log files"
    
    # Clean package cache
    if command -v dnf &> /dev/null; then
        dnf clean packages -q
        echo "Cleaned DNF package cache"
    elif command -v yum &> /dev/null; then
        yum clean packages -q
        echo "Cleaned YUM package cache"
    fi
    
    echo "=== Temp Cleanup Completed - $(date) ==="
    echo ""
} >> $LOG_FILE 2>&1
EOF
Make the cleanup script executable:
sudo chmod +x /usr/local/bin/temp-cleanup.sh
Create a weekly timer:
sudo tee /etc/systemd/system/temp-cleanup.timer << 'EOF'
[Unit]
Description=Weekly temporary files cleanup
Requires=temp-cleanup.service

[Timer]
OnCalendar=weekly
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF
Enable and start the weekly cleanup timer:
sudo systemctl daemon-reload
sudo systemctl enable temp-cleanup.timer
sudo systemctl start temp-cleanup.timer
Subtask 2.5: Creating User-Level systemd Timers
Create user systemd directory:
mkdir -p ~/.config/systemd/user
Create a user service:
tee ~/.config/systemd/user/personal-backup.service << 'EOF'
[Unit]
Description=Personal Backup Service

[Service]
Type=oneshot
ExecStart=%h/scripts/personal-backup.sh
EOF
Create the personal backup script:
cat > ~/scripts/personal-backup.sh << 'EOF'
#!/bin/bash
# Personal Backup Script
BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup documents and scripts
tar -czf $BACKUP_DIR/personal_backup_$DATE.tar.gz ~/scripts ~/Documents 2>/dev/null

# Keep only last 5 backups
ls -t $BACKUP_DIR/personal_backup_*.tar.gz | tail -n +6 | xargs -r rm

echo "Personal backup completed at $(date)" >> ~/personal_backup.log
EOF
Make the script executable:
chmod +x ~/scripts/personal-backup.sh
Create a user timer:
tee ~/.config/systemd/user/personal-backup.timer << 'EOF'
[Unit]
Description=Daily personal backup
Requires=personal-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
Enable user timers:
systemctl --user daemon-reload
systemctl --user enable personal-backup.timer
systemctl --user start personal-backup.timer
Check user timers:
systemctl --user list-timers
Task 3: Testing and Debugging Cron and systemd Jobs
Subtask 3.1: Testing Cron Jobs
Check cron service logs:
sudo journalctl -u crond -f
Monitor cron execution in real-time:
sudo tail -f /var/log/cron
Test a cron job manually:
# Run the system info script manually
~/scripts/system_info.sh

# Check if the output file was created
ls -la ~/system_reports.log
tail ~/system_reports.log
Create a test cron job that runs every minute:
crontab -e
Add:

# Test job - runs every minute
* * * * * echo "Test cron job executed at $(date)" >> ~/cron_test.log
Wait a few minutes and check the results:
tail -f ~/cron_test.log
Remove the test job after verification:
crontab -e
# Remove or comment out the test line
Subtask 3.2: Debugging Common Cron Issues
Check for common cron problems:
# Verify cron service is running
sudo systemctl status crond

# Check cron logs for errors
sudo grep CRON /var/log/messages
sudo journalctl -u crond --since "1 hour ago"
Create a script to test environment variables:
cat > ~/scripts/env_test.sh << 'EOF'
#!/bin/bash
# Environment Test Script
{
    echo "=== Environment Test - $(date) ==="
    echo "PATH: $PATH"
    echo "HOME: $HOME"
    echo "USER: $USER"
    echo "PWD: $PWD"
    echo "Shell: $SHELL"
    echo "=== End Environment Test ==="
    echo ""
} >> ~/env_test.log
EOF
Make it executable and add to cron:
chmod +x ~/scripts/env_test.sh
crontab -e
Add:

# Environment test
*/2 * * * * /home/$(whoami)/scripts/env_test.sh
Check the environment output:
tail ~/env_test.log
Subtask 3.3: Testing systemd Timers
Check systemd timer logs:
sudo journalctl -u system-status.timer -f
View service execution logs:
sudo journalctl -u system-status.service --since "1 hour ago"
Manually trigger a systemd service:
sudo systemctl start system-status.service
Check the service output:
sudo tail /var/log/system-status.log
Test timer accuracy:
# Check when the timer will run next
systemctl list-timers system-status.timer

# Check timer status
sudo systemctl status system-status.timer
Subtask 3.4: Advanced Debugging Techniques
Create a debugging script for cron:
cat > ~/scripts/debug_cron.sh << 'EOF'
#!/bin/bash
# Cron Debug Script
DEBUG_LOG=~/cron_debug.log

{
    echo "=== Cron Debug Session - $(date) ==="
    echo "Script executed from: $PWD"
    echo "Script path: $0"
    echo "Arguments: $@"
    echo "Environment variables:"
    env | sort
    echo "=== End Debug Session ==="
    echo ""
} >> $DEBUG_LOG 2>&1
EOF
Make it executable and test:
chmod +x ~/scripts/debug_cron.sh
crontab -e
Add:

# Debug cron job
*/3 * * * * /home/$(whoami)/scripts/debug_cron.sh arg1 arg2
Monitor the debug output:
tail -f ~/cron_debug.log
Create a systemd service debugging script:
sudo tee /usr/local/bin/debug-systemd.sh << 'EOF'
#!/bin/bash
# systemd Debug Script
DEBUG_LOG="/var/log/systemd-debug.log"

{
    echo "=== systemd Debug Session - $(date) ==="
    echo "Service: $1"
    echo "Working directory: $PWD"
    echo "User: $(whoami)"
    echo "Groups: $(groups)"
    echo "Environment:"
    env | sort
    echo "=== End systemd Debug Session ==="
    echo ""
} >> $DEBUG_LOG 2>&1
EOF
Make it executable:
sudo chmod +x /usr/local/bin/debug-systemd.sh
Subtask 3.5: Monitoring and Maintenance
Create a monitoring script for all automated tasks:
cat > ~/scripts/monitor_automation.sh << 'EOF'
#!/bin/bash
# Automation Monitor Script
REPORT_FILE=~/automation_report.log

{
    echo "=== Automation Status Report - $(date) ==="
    
    echo "--- Cron Jobs Status ---"
    echo "Active crontab entries:"
    crontab -l | grep -v '^#' | grep -v '^$' | wc -l
    
    echo "Recent cron executions:"
    sudo grep "$(whoami)" /var/log/cron | tail -5
    
    echo "--- systemd Timers Status ---"
    echo "Active timers:"
    systemctl list-timers --no-pager | grep -c "timer"
    
    echo "Recent timer executions:"
    sudo journalctl -u "*.timer" --since "1 hour ago" --no-pager | tail -5
    
    echo "--- Log File Sizes ---"
    ls -lh ~/system_reports.log ~/cron_monitor.log ~/backup.log 2>/dev/null
    
    echo "=== End Automation Report ==="
    echo ""
} >> $REPORT_FILE 2>&1
EOF
Make it executable:
chmod +x ~/scripts/monitor_automation.sh
Run the monitoring script:
~/scripts/monitor_automation.sh
cat ~/automation_report.log
Clean up test cron jobs:
crontab -e
# Remove test entries, keep only the ones you want to maintain
Troubleshooting Common Issues
Cron Troubleshooting
Issue: Cron job not executing

Check if crond service is running: sudo systemctl status crond
Verify cron syntax: Use online cron validators
Check file permissions: Ensure scripts are executable
Review logs: sudo tail /var/log/cron
Issue: Script works manually but not in cron

Use absolute paths in scripts
Set environment variables explicitly
Check PATH variable in cron environment
Issue: No output from cron job

Redirect output to a file: command >> /path/to/logfile 2>&1
Check if the user has write permissions to the output location
systemd Timer Troubleshooting
Issue: Timer not starting

Check syntax: sudo systemd-analyze verify /etc/systemd/system/your-timer.timer
Reload systemd: sudo systemctl daemon-reload
Check dependencies: Ensure the service file exists
Issue: Service fails to execute

Check service logs: sudo journalctl -u your-service.service
Verify script permissions and paths
Test service manually: sudo systemctl start your-service.service
Issue: Timer runs but service fails

Check service status: sudo systemctl status your-service.service
Review service configuration for correct paths and permissions
Ensure all dependencies are met
Conclusion
In this comprehensive lab, you have successfully learned to automate tasks using both traditional cron jobs and modern systemd timers. Here's what you accomplished:

Key Achievements:

• Mastered Cron Jobs: You created various cron jobs ranging from simple system monitoring to complex backup scripts, understanding the cron syntax and scheduling flexibility.

• Implemented systemd Timers: You set up both system-wide and user-level systemd timers, learning their advantages over traditional cron jobs including better logging and integration with the systemd ecosystem.

• Developed Automation Scripts: You created practical scripts for system monitoring, backup operations, and maintenance tasks that can be used in real-world scenarios.

• Learned Debugging Techniques: You gained valuable skills in troubleshooting automated tasks, monitoring their execution, and resolving common issues.

• Applied Best Practices: You implemented proper logging, error handling, and maintenance procedures for automated tasks.

Why This Matters:

Task automation is crucial for system administrators because it:

Reduces manual workload and human error
Ensures consistent execution of routine tasks
Improves system reliability and maintenance
Provides better resource utilization
Enables proactive system monitoring and maintenance
Real-World Applications:

The skills you've learned are directly applicable to:

Automated system backups and maintenance
Log rotation and cleanup procedures
System monitoring and alerting
Software updates and patch management
Performance data collection
Security scanning and compliance checks
Next Steps:

To further enhance your automation skills, consider:

Exploring advanced systemd features like dependencies and conditions
Learning configuration management tools like Ansible
Implementing centralized logging and monitoring solutions
Studying container orchestration and automation
Developing custom monitoring and alerting systems
You now have the foundational knowledge to implement robust task automation in enterprise Linux environments, a critical skill for the Red Hat Certified System Administrator certification and professional system administration roles.
