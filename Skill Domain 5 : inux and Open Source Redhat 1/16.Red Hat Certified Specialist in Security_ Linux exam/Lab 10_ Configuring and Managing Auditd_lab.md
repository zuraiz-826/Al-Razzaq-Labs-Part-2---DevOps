Lab 10: Configuring and Managing Auditd
Objectives
By the end of this lab, you will be able to:

Install and configure the Linux audit daemon (auditd) for system monitoring
Create and manage audit rules using auditctl to track specific system activities
Generate comprehensive audit reports using ausearch and aureport tools
Understand the importance of system auditing for security compliance and forensic analysis
Implement best practices for audit log management and analysis
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with file permissions and system administration concepts
Knowledge of text editors like vi/vim or nano
Understanding of Linux system processes and services
Basic knowledge of log file management
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
All necessary audit packages pre-installed
Network connectivity for package management
Sufficient disk space for audit logs
Task 1: Install and Configure Auditd
Subtask 1.1: Verify Auditd Installation
First, let's check if auditd is already installed on your system.

# Check if auditd is installed
rpm -qa | grep audit

# Check the status of auditd service
systemctl status auditd
Subtask 1.2: Install Auditd (if not present)
If auditd is not installed, install it using the package manager:

# Install audit packages
sudo yum install -y audit audit-libs

# For Ubuntu/Debian systems, use:
# sudo apt-get update && sudo apt-get install -y auditd audispd-plugins
Subtask 1.3: Configure Auditd Main Configuration
Navigate to the audit configuration directory and examine the main configuration file:

# Navigate to audit configuration directory
cd /etc/audit

# List all audit configuration files
ls -la

# Backup the original configuration
sudo cp auditd.conf auditd.conf.backup

# View the current configuration
sudo cat auditd.conf
Subtask 1.4: Modify Auditd Configuration
Edit the main configuration file to optimize settings:

# Edit the auditd configuration file
sudo vi /etc/audit/auditd.conf
Key configuration parameters to modify:

# Maximum log file size (in MB)
max_log_file = 50

# Number of log files to keep
num_logs = 10

# Action when disk space is low
space_left_action = email

# Action when disk is full
disk_full_action = suspend

# Log format
log_format = RAW

# Flush audit records to disk
flush = incremental_async
Subtask 1.5: Start and Enable Auditd Service
# Start the auditd service
sudo systemctl start auditd

# Enable auditd to start at boot
sudo systemctl enable auditd

# Verify the service is running
sudo systemctl status auditd

# Check if auditd is listening
sudo netstat -tulpn | grep audit
Task 2: Set Audit Rules Using Auditctl
Subtask 2.1: View Current Audit Rules
Before adding new rules, let's examine the current audit configuration:

# List all current audit rules
sudo auditctl -l

# Check audit status
sudo auditctl -s

# View audit rule statistics
sudo auditctl -R /etc/audit/rules.d/audit.rules
Subtask 2.2: Create File and Directory Monitoring Rules
Create rules to monitor critical system files and directories:

# Monitor /etc/passwd file for any changes
sudo auditctl -w /etc/passwd -p wa -k passwd_changes

# Monitor /etc/shadow file
sudo auditctl -w /etc/shadow -p wa -k shadow_changes

# Monitor /etc/group file
sudo auditctl -w /etc/group -p wa -k group_changes

# Monitor /etc/sudoers file
sudo auditctl -w /etc/sudoers -p wa -k sudoers_changes

# Monitor /var/log directory
sudo auditctl -w /var/log -p wa -k log_changes

# Monitor /etc/ssh/sshd_config
sudo auditctl -w /etc/ssh/sshd_config -p wa -k ssh_config_changes
Subtask 2.3: Create System Call Monitoring Rules
Add rules to monitor specific system calls:

# Monitor file deletion attempts
sudo auditctl -a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete

# Monitor file permission changes
sudo auditctl -a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k perm_mod

# Monitor file ownership changes
sudo auditctl -a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -k ownership_changes

# Monitor network connections
sudo auditctl -a always,exit -F arch=b64 -S socket -k network_connections
Subtask 2.4: Create User and Process Monitoring Rules
# Monitor user login/logout events
sudo auditctl -w /var/log/lastlog -p wa -k user_login

# Monitor failed login attempts
sudo auditctl -w /var/log/faillog -p wa -k failed_logins

# Monitor sudo usage
sudo auditctl -w /var/log/sudo.log -p wa -k sudo_usage

# Monitor process execution
sudo auditctl -a always,exit -F arch=b64 -S execve -k process_execution
Subtask 2.5: Make Audit Rules Persistent
To ensure rules persist after reboot, add them to the rules file:

# Create a custom rules file
sudo vi /etc/audit/rules.d/custom.rules
Add the following content to the file:

# Custom Audit Rules

# File monitoring rules
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /var/log -p wa -k log_changes
-w /etc/ssh/sshd_config -p wa -k ssh_config_changes

# System call monitoring
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -k ownership_changes

# User activity monitoring
-w /var/log/lastlog -p wa -k user_login
-w /var/log/faillog -p wa -k failed_logins

# Make configuration immutable (add at the end)
-e 2
Subtask 2.6: Load and Verify Rules
# Reload audit rules
sudo auditctl -R /etc/audit/rules.d/custom.rules

# Verify all rules are loaded
sudo auditctl -l

# Check audit status
sudo auditctl -s
Task 3: Generate Audit Reports Using Ausearch and Aureport
Subtask 3.1: Generate Test Audit Events
Before creating reports, let's generate some audit events for analysis:

# Create test events
sudo touch /tmp/test_audit_file
sudo chmod 755 /tmp/test_audit_file
sudo chown nobody:nobody /tmp/test_audit_file
sudo rm /tmp/test_audit_file

# Attempt to modify a monitored file
sudo echo "test entry" >> /etc/passwd
sudo sed -i '$d' /etc/passwd  # Remove the test entry

# Create a failed login attempt (optional)
su - nonexistentuser
Subtask 3.2: Basic Ausearch Commands
Use ausearch to search for specific audit events:

# Search for all events in the last hour
sudo ausearch -ts recent

# Search for events related to passwd file
sudo ausearch -k passwd_changes

# Search for file deletion events
sudo ausearch -k delete

# Search for permission modification events
sudo ausearch -k perm_mod

# Search for events by specific user
sudo ausearch -ua root

# Search for failed events
sudo ausearch -m USER_LOGIN --success no
Subtask 3.3: Advanced Ausearch Filtering
# Search for events in a specific time range
sudo ausearch -ts today -te now

# Search for events by process ID
sudo ausearch -p 1234

# Search for events by executable
sudo ausearch -x /bin/chmod

# Search for events with specific system call
sudo ausearch -sc chmod

# Search for events by file path
sudo ausearch -f /etc/passwd

# Combine multiple search criteria
sudo ausearch -k passwd_changes -ts today -ua root
Subtask 3.4: Generate Summary Reports with Aureport
Create comprehensive audit reports using aureport:

# Generate summary report of all audit events
sudo aureport

# Generate authentication report
sudo aureport -au

# Generate login report
sudo aureport -l

# Generate file access report
sudo aureport -f

# Generate system call report
sudo aureport -s

# Generate process report
sudo aureport -p

# Generate user report
sudo aureport -u
Subtask 3.5: Generate Detailed Reports
# Generate detailed authentication report
sudo aureport -au --summary

# Generate failed login attempts report
sudo aureport -l --failed --summary

# Generate file modification report for today
sudo aureport -f -ts today

# Generate executable report
sudo aureport -x --summary

# Generate network connection report
sudo aureport -n

# Generate time-based report
sudo aureport -t
Subtask 3.6: Export and Format Reports
# Create reports directory
mkdir -p ~/audit_reports

# Generate formatted reports
sudo aureport --summary > ~/audit_reports/audit_summary.txt
sudo aureport -au > ~/audit_reports/authentication_report.txt
sudo aureport -f > ~/audit_reports/file_access_report.txt
sudo aureport -l --failed > ~/audit_reports/failed_logins.txt

# Generate CSV format reports
sudo aureport -au --format csv > ~/audit_reports/auth_report.csv
sudo aureport -f --format csv > ~/audit_reports/file_report.csv

# View generated reports
ls -la ~/audit_reports/
head ~/audit_reports/audit_summary.txt
Subtask 3.7: Create Custom Audit Analysis Script
Create a script to automate audit analysis:

# Create audit analysis script
vi ~/audit_analysis.sh
Add the following content:

#!/bin/bash

# Audit Analysis Script
REPORT_DIR="$HOME/audit_reports"
DATE=$(date +%Y%m%d_%H%M%S)

# Create report directory
mkdir -p "$REPORT_DIR"

echo "=== Audit Analysis Report - $DATE ===" > "$REPORT_DIR/daily_audit_$DATE.txt"
echo "" >> "$REPORT_DIR/daily_audit_$DATE.txt"

# System summary
echo "SYSTEM AUDIT SUMMARY:" >> "$REPORT_DIR/daily_audit_$DATE.txt"
sudo aureport --summary >> "$REPORT_DIR/daily_audit_$DATE.txt"
echo "" >> "$REPORT_DIR/daily_audit_$DATE.txt"

# Authentication events
echo "AUTHENTICATION EVENTS:" >> "$REPORT_DIR/daily_audit_$DATE.txt"
sudo aureport -au --summary >> "$REPORT_DIR/daily_audit_$DATE.txt"
echo "" >> "$REPORT_DIR/daily_audit_$DATE.txt"

# Failed login attempts
echo "FAILED LOGIN ATTEMPTS:" >> "$REPORT_DIR/daily_audit_$DATE.txt"
sudo aureport -l --failed >> "$REPORT_DIR/daily_audit_$DATE.txt"
echo "" >> "$REPORT_DIR/daily_audit_$DATE.txt"

# File access events
echo "FILE ACCESS EVENTS:" >> "$REPORT_DIR/daily_audit_$DATE.txt"
sudo aureport -f -ts today >> "$REPORT_DIR/daily_audit_$DATE.txt"
echo "" >> "$REPORT_DIR/daily_audit_$DATE.txt"

# Critical file changes
echo "CRITICAL FILE CHANGES:" >> "$REPORT_DIR/daily_audit_$DATE.txt"
sudo ausearch -k passwd_changes -ts today >> "$REPORT_DIR/daily_audit_$DATE.txt" 2>/dev/null
sudo ausearch -k shadow_changes -ts today >> "$REPORT_DIR/daily_audit_$DATE.txt" 2>/dev/null
sudo ausearch -k sudoers_changes -ts today >> "$REPORT_DIR/daily_audit_$DATE.txt" 2>/dev/null

echo "Report generated: $REPORT_DIR/daily_audit_$DATE.txt"
Make the script executable and run it:

# Make script executable
chmod +x ~/audit_analysis.sh

# Run the analysis script
./audit_analysis.sh

# View the generated report
ls -la ~/audit_reports/
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Auditd service fails to start

# Check audit configuration syntax
sudo auditctl -R /etc/audit/rules.d/audit.rules

# Check system logs for errors
sudo journalctl -u auditd -f

# Verify disk space
df -h /var/log/audit
Issue 2: Audit rules not persisting after reboot

# Ensure rules are in the correct directory
ls -la /etc/audit/rules.d/

# Check if auditd is enabled
sudo systemctl is-enabled auditd

# Verify rule file syntax
sudo auditctl -R /etc/audit/rules.d/custom.rules
Issue 3: Too many audit events filling disk space

# Check current log size
sudo du -sh /var/log/audit/

# Adjust log rotation settings
sudo vi /etc/audit/auditd.conf

# Manually rotate logs if needed
sudo service auditd rotate
Issue 4: Cannot search audit logs

# Check if audit logs exist
ls -la /var/log/audit/

# Verify ausearch permissions
sudo ausearch -ts recent

# Check audit daemon status
sudo systemctl status auditd
Best Practices
Regular Monitoring: Schedule daily audit report generation
Log Rotation: Configure appropriate log rotation to prevent disk space issues
Rule Optimization: Only monitor necessary files and events to reduce overhead
Backup: Regularly backup audit logs for compliance and forensic purposes
Testing: Regularly test audit rules to ensure they capture required events
Conclusion
In this lab, you have successfully:

Installed and configured auditd to monitor system activities and maintain security compliance
Created comprehensive audit rules using auditctl to track file access, system calls, and user activities
Generated detailed audit reports using ausearch and aureport tools for security analysis and compliance reporting
Implemented persistent audit configurations that survive system reboots
Developed automated reporting scripts for regular audit analysis
Why This Matters: System auditing is crucial for:

Security Compliance: Meeting regulatory requirements like PCI-DSS, HIPAA, and SOX
Forensic Analysis: Investigating security incidents and unauthorized access
Change Tracking: Monitoring critical system file modifications
User Activity Monitoring: Tracking user actions for accountability
Intrusion Detection: Identifying potential security breaches
The skills you've learned in this lab are essential for Linux system administrators and security professionals, particularly for those pursuing Red Hat Certified Specialist in Security certifications. Regular audit monitoring and analysis help maintain system security, ensure compliance, and provide valuable insights into system usage patterns.

Remember to regularly review and update your audit rules based on your organization's security requirements and compliance needs. The audit system is a powerful tool that, when properly configured, provides comprehensive visibility into system activities and helps maintain a secure computing environment.
