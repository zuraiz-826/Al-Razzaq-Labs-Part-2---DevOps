Lab 20: Advanced Troubleshooting and System Recovery
Objectives
By the end of this lab, students will be able to:

• Analyze system logs using journalctl and traditional log files to identify issues • Use advanced system diagnostic tools to troubleshoot performance and service problems • Access and navigate systemd rescue mode for system recovery • Restore failed system services and repair configuration files • Implement system recovery procedures for common failure scenarios • Apply best practices for system maintenance and preventive troubleshooting

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with systemd service management • Knowledge of file system navigation and text editing • Understanding of user permissions and sudo usage • Completion of previous labs covering basic system administration

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes: • CentOS/RHEL 8 or 9 system with full administrative access • Pre-installed troubleshooting tools and utilities • Simulated system issues for hands-on practice • All necessary log files and system configurations

Task 1: Perform Advanced Troubleshooting Using Logs and System Tools
Subtask 1.1: Analyze System Logs with journalctl
Step 1: Access your lab environment and open a terminal session.

Step 2: Check the overall system journal for recent entries:

sudo journalctl -n 50
This command shows the last 50 journal entries. The journal contains all system messages, service logs, and kernel messages.

Step 3: Filter logs by priority level to find critical issues:

sudo journalctl -p err
Step 4: Check logs for a specific time period (last 2 hours):

sudo journalctl --since "2 hours ago"
Step 5: Monitor logs in real-time to observe system behavior:

sudo journalctl -f
Press Ctrl+C to stop the real-time monitoring.

Subtask 1.2: Examine Traditional Log Files
Step 1: Navigate to the system log directory:

cd /var/log
ls -la
Step 2: Check the main system log for errors:

sudo tail -50 /var/log/messages
Step 3: Examine authentication logs for security issues:

sudo tail -30 /var/log/secure
Step 4: Search for specific error patterns in logs:

sudo grep -i "error\|fail\|critical" /var/log/messages | tail -20
Subtask 1.3: Use System Diagnostic Tools
Step 1: Check system resource usage:

top
Press q to quit top. Look for processes consuming high CPU or memory.

Step 2: Examine disk usage and identify space issues:

df -h
du -sh /var/log/*
Step 3: Check system load and uptime:

uptime
w
Step 4: Analyze network connectivity:

ping -c 4 8.8.8.8
netstat -tuln | head -20
Step 5: Check system hardware information:

lscpu
free -h
lsblk
Task 2: Recover from System Failure Using systemd and Rescue Mode
Subtask 2.1: Simulate a System Issue
Step 1: Create a problematic service to simulate a failure:

sudo tee /etc/systemd/system/problem-service.service > /dev/null << 'EOF'
[Unit]
Description=Problem Service for Testing
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c "while true; do echo 'Service running'; sleep 30; done"
ExecStop=/bin/bash -c "exit 1"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
Step 2: Enable and start the problematic service:

sudo systemctl daemon-reload
sudo systemctl enable problem-service.service
sudo systemctl start problem-service.service
Step 3: Verify the service is running:

sudo systemctl status problem-service.service
Subtask 2.2: Access Rescue Mode
Step 1: Switch to rescue mode (single-user mode):

sudo systemctl rescue
Note: In a real scenario, you might need to boot into rescue mode from the GRUB menu. In our lab environment, we'll simulate this process.

Step 2: Check the current target:

systemctl get-default
systemctl list-units --type=target
Step 3: Examine what services are running in rescue mode:

systemctl list-units --state=active
Subtask 2.3: Diagnose Issues in Rescue Mode
Step 1: Check for failed services:

systemctl --failed
Step 2: Examine the problematic service:

systemctl status problem-service.service
journalctl -u problem-service.service -n 20
Step 3: Check system dependencies:

systemctl list-dependencies rescue.target
Task 3: Restore System Services and Configurations
Subtask 3.1: Fix Service Configuration Issues
Step 1: Stop the problematic service:

sudo systemctl stop problem-service.service
Step 2: Edit the service configuration to fix the issue:

sudo tee /etc/systemd/system/problem-service.service > /dev/null << 'EOF'
[Unit]
Description=Fixed Problem Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c "while true; do echo 'Service running properly'; sleep 30; done"
ExecStop=/bin/kill -TERM $MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
Step 3: Reload systemd configuration:

sudo systemctl daemon-reload
Step 4: Start the fixed service:

sudo systemctl start problem-service.service
sudo systemctl status problem-service.service
Subtask 3.2: Restore System to Normal Operation
Step 1: Return to multi-user target (normal operation):

sudo systemctl default
Step 2: Verify all essential services are running:

systemctl list-units --type=service --state=active | grep -E "(ssh|network|systemd)"
Step 3: Check system logs for any remaining issues:

sudo journalctl -p warning --since "10 minutes ago"
Subtask 3.3: Implement System Recovery Best Practices
Step 1: Create a system backup script for critical configurations:

sudo tee /usr/local/bin/backup-configs.sh > /dev/null << 'EOF'
#!/bin/bash
# System Configuration Backup Script

BACKUP_DIR="/var/backups/system-configs"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup critical configuration files
tar -czf "$BACKUP_DIR/system-configs-$DATE.tar.gz" \
    /etc/systemd/system/ \
    /etc/fstab \
    /etc/hosts \
    /etc/resolv.conf \
    /etc/ssh/sshd_config \
    2>/dev/null

echo "System configuration backup completed: $BACKUP_DIR/system-configs-$DATE.tar.gz"

# Keep only last 5 backups
cd "$BACKUP_DIR"
ls -t system-configs-*.tar.gz | tail -n +6 | xargs -r rm

echo "Backup cleanup completed"
EOF
Step 2: Make the backup script executable:

sudo chmod +x /usr/local/bin/backup-configs.sh
Step 3: Test the backup script:

sudo /usr/local/bin/backup-configs.sh
Step 4: Create a systemd timer for automated backups:

sudo tee /etc/systemd/system/backup-configs.service > /dev/null << 'EOF'
[Unit]
Description=System Configuration Backup
Wants=backup-configs.timer

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-configs.sh

[Install]
WantedBy=multi-user.target
EOF
Step 5: Create the timer configuration:

sudo tee /etc/systemd/system/backup-configs.timer > /dev/null << 'EOF'
[Unit]
Description=Run backup-configs daily
Requires=backup-configs.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
Step 6: Enable and start the backup timer:

sudo systemctl daemon-reload
sudo systemctl enable backup-configs.timer
sudo systemctl start backup-configs.timer
sudo systemctl status backup-configs.timer
Subtask 3.4: Verify System Recovery
Step 1: Check all critical services are operational:

sudo systemctl status sshd
sudo systemctl status NetworkManager
sudo systemctl status problem-service.service
Step 2: Verify system logs show no critical errors:

sudo journalctl -p err --since "30 minutes ago"
Step 3: Test system functionality:

# Test network connectivity
ping -c 3 google.com

# Test disk space
df -h

# Test service management
sudo systemctl restart problem-service.service
sudo systemctl status problem-service.service
Step 4: Document the recovery process:

sudo tee /var/log/recovery-log-$(date +%Y%m%d).txt > /dev/null << EOF
System Recovery Log - $(date)
================================

Issues Identified:
- Problematic service configuration causing restart loops
- Service dependencies not properly configured

Actions Taken:
1. Accessed rescue mode for safe troubleshooting
2. Identified failed service using systemctl --failed
3. Fixed service configuration file
4. Reloaded systemd daemon
5. Restored system to normal operation
6. Implemented backup procedures

System Status: RECOVERED
All critical services operational
Backup procedures implemented

Recovery completed by: $(whoami)
EOF
Troubleshooting Tips
Common Issues and Solutions
Issue: Cannot access rescue mode Solution:

# Alternative method to isolate rescue target
sudo systemctl isolate rescue.target
Issue: Service fails to start after configuration changes Solution:

# Check service syntax
sudo systemd-analyze verify /etc/systemd/system/service-name.service
# Check service dependencies
systemctl list-dependencies service-name.service
Issue: System logs are too large to analyze Solution:

# Limit journal size
sudo journalctl --vacuum-size=100M
# Focus on specific time periods
sudo journalctl --since "1 hour ago" --until "30 minutes ago"
Issue: Cannot determine root cause of system issues Solution:

# Use systemd-analyze for boot performance
systemd-analyze blame
systemd-analyze critical-chain
# Check for hardware issues
dmesg | grep -i error
Conclusion
In this lab, you have successfully completed advanced troubleshooting and system recovery procedures that are essential for maintaining Linux systems in production environments. You learned to:

• Analyze system logs effectively using both journalctl and traditional log files to identify and diagnose system issues • Navigate rescue mode safely to perform system recovery without risking further damage • Restore failed services by identifying configuration problems and implementing proper fixes • Implement preventive measures through automated backup procedures and system monitoring

These skills are crucial for Red Hat Certified System Administrators who need to maintain system uptime and quickly resolve issues in enterprise environments. The troubleshooting methodologies you practiced - from log analysis to service restoration - form the foundation of professional Linux system administration.

Key Takeaways:

Always check logs first when troubleshooting system issues
Use rescue mode as a safe environment for system recovery
Document your recovery procedures for future reference
Implement preventive measures to avoid similar issues
Test your fixes thoroughly before returning to normal operation
The techniques you've mastered in this lab will serve you well in real-world scenarios where quick and effective system recovery is critical to business operations.
