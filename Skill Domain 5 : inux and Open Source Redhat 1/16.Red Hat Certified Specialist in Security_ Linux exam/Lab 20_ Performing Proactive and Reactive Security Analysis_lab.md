Lab 20: Performing Proactive and Reactive Security Analysis
Objectives
By the end of this lab, students will be able to:

Configure and use auditctl to monitor specific system activities and security events
Analyze audit logs using ausearch and aureport to identify potential security threats
Investigate system logs using journalctl and traditional log files in /var/log/
Implement reactive security measures based on detected threats
Configure proactive monitoring systems to prevent future security incidents
Understand the difference between proactive and reactive security analysis approaches
Prerequisites
Before starting this lab, students should have:

Basic knowledge of Linux command line operations
Understanding of file permissions and user management in Linux
Familiarity with text editors like vi or nano
Basic understanding of system processes and services
Knowledge of log file formats and structure
Lab Environment
Al Nafi provides Linux-based cloud machines - simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software. Your lab machine comes with all necessary tools pre-installed.

Task 1: Configure and Use auditctl for System Monitoring
Subtask 1.1: Understanding the Linux Audit System
The Linux Audit system provides detailed logging of system calls, file access, and security-related events. It consists of three main components:

auditctl: Command-line utility to configure audit rules
ausearch: Tool to search audit logs
aureport: Tool to generate summary reports from audit logs
First, let's check if the audit service is running:

sudo systemctl status auditd
If the service is not running, start it:

sudo systemctl start auditd
sudo systemctl enable auditd
Subtask 1.2: Configuring Basic Audit Rules
Let's start by viewing current audit rules:

sudo auditctl -l
Now, let's add some basic monitoring rules. We'll monitor file access to sensitive directories:

# Monitor access to /etc/passwd file
sudo auditctl -w /etc/passwd -p rwxa -k passwd_changes

# Monitor access to /etc/shadow file
sudo auditctl -w /etc/shadow -p rwxa -k shadow_changes

# Monitor the /tmp directory for file creation and deletion
sudo auditctl -w /tmp -p wa -k tmp_activity

# Monitor sudo usage
sudo auditctl -w /var/log/sudo.log -p wa -k sudo_usage
Explanation of parameters:

-w: Specifies the file or directory to watch
-p: Specifies permissions to monitor (r=read, w=write, x=execute, a=attribute change)
-k: Assigns a key name for easier searching
Subtask 1.3: Advanced Audit Rules for Security Monitoring
Let's add more sophisticated rules to monitor security-critical activities:

# Monitor system calls for privilege escalation
sudo auditctl -a always,exit -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -k privilege_escalation

# Monitor network connections
sudo auditctl -a always,exit -F arch=b64 -S socket -S connect -S accept -k network_activity

# Monitor file deletion attempts
sudo auditctl -a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k file_deletion

# Monitor changes to system time
sudo auditctl -a always,exit -F arch=b64 -S adjtimex -S settimeofday -S stime -k time_change
Verify all rules are active:

sudo auditctl -l
Subtask 1.4: Creating Test Activities for Analysis
Now let's generate some activities that will trigger our audit rules:

# Create test activities
echo "Test entry" | sudo tee -a /etc/hosts
ls -la /etc/passwd
touch /tmp/test_file
rm /tmp/test_file
sudo ls /etc/shadow
Task 2: Analyze Audit Logs with ausearch and aureport
Subtask 2.1: Using ausearch for Detailed Log Analysis
ausearch allows you to search audit logs based on various criteria. Let's explore different search options:

# Search for all events with the key "passwd_changes"
sudo ausearch -k passwd_changes

# Search for events in the last 10 minutes
sudo ausearch -ts recent

# Search for events by a specific user (replace 'username' with actual username)
sudo ausearch -ui $(id -u)

# Search for failed events
sudo ausearch -m AVC,USER_AUTH,USER_ACCT,USER_CMD -sv no

# Search for file access events
sudo ausearch -k tmp_activity
Let's create a more detailed search for security analysis:

# Search for privilege escalation attempts
sudo ausearch -k privilege_escalation -i

# Search for network activity
sudo ausearch -k network_activity -i

# Search for file deletion events
sudo ausearch -k file_deletion -i
The -i flag interprets numeric values into human-readable format.

Subtask 2.2: Using aureport for Summary Analysis
aureport provides summary reports of audit log data:

# Generate a summary report of all audit events
sudo aureport

# Report on authentication attempts
sudo aureport -au

# Report on failed events
sudo aureport -f

# Report on file access events
sudo aureport -f

# Report on system calls
sudo aureport -s

# Report on executables run
sudo aureport -x

# Generate report for specific time period (last hour)
sudo aureport --start recent
Create a comprehensive security report:

# Generate detailed security report
sudo aureport --summary
sudo aureport -au --summary
sudo aureport -f --summary
sudo aureport -k --summary
Subtask 2.3: Creating Custom Analysis Scripts
Let's create a script to automate security analysis:

nano security_analysis.sh
Add the following content:

#!/bin/bash

echo "=== Security Analysis Report ==="
echo "Generated on: $(date)"
echo ""

echo "=== Failed Authentication Attempts ==="
sudo ausearch -m USER_AUTH -sv no --start today 2>/dev/null | grep -c "type=USER_AUTH" || echo "No failed authentication attempts found"

echo ""
echo "=== Privilege Escalation Attempts ==="
sudo ausearch -k privilege_escalation --start today 2>/dev/null | wc -l

echo ""
echo "=== File Deletion Events ==="
sudo ausearch -k file_deletion --start today 2>/dev/null | wc -l

echo ""
echo "=== Network Activity Summary ==="
sudo ausearch -k network_activity --start today 2>/dev/null | wc -l

echo ""
echo "=== Recent Sudo Usage ==="
sudo ausearch -k sudo_usage --start today 2>/dev/null | tail -10

echo ""
echo "=== System File Changes ==="
sudo ausearch -k passwd_changes -k shadow_changes --start today 2>/dev/null
Make the script executable and run it:

chmod +x security_analysis.sh
./security_analysis.sh
Task 3: Investigate System Logs with journalctl and /var/log/*
Subtask 3.1: Using journalctl for System Log Analysis
journalctl is the primary tool for viewing systemd logs. Let's explore various analysis techniques:

# View recent system logs
sudo journalctl -n 50

# View logs from the last hour
sudo journalctl --since "1 hour ago"

# View logs for a specific service
sudo journalctl -u sshd

# View authentication logs
sudo journalctl -u systemd-logind

# View kernel messages
sudo journalctl -k

# Follow logs in real-time
sudo journalctl -f
Subtask 3.2: Advanced journalctl Analysis
Let's perform more targeted security analysis:

# Search for failed login attempts
sudo journalctl --since "24 hours ago" | grep -i "failed\|failure\|invalid"

# Search for privilege escalation
sudo journalctl --since "24 hours ago" | grep -i "sudo\|su\|privilege"

# Search for network-related events
sudo journalctl --since "24 hours ago" | grep -i "network\|connection\|ssh"

# Search for error messages
sudo journalctl -p err --since "24 hours ago"

# Search for critical messages
sudo journalctl -p crit --since "24 hours ago"
Create a comprehensive log analysis:

# Generate security-focused log report
echo "=== Security Log Analysis ===" > security_log_report.txt
echo "Generated: $(date)" >> security_log_report.txt
echo "" >> security_log_report.txt

echo "=== Failed SSH Attempts ===" >> security_log_report.txt
sudo journalctl -u sshd --since "24 hours ago" | grep -i "failed\|invalid" >> security_log_report.txt

echo "" >> security_log_report.txt
echo "=== Sudo Usage ===" >> security_log_report.txt
sudo journalctl --since "24 hours ago" | grep -i "sudo" >> security_log_report.txt

echo "" >> security_log_report.txt
echo "=== System Errors ===" >> security_log_report.txt
sudo journalctl -p err --since "24 hours ago" >> security_log_report.txt

cat security_log_report.txt
Subtask 3.3: Analyzing Traditional Log Files in /var/log/
Let's examine traditional log files for security analysis:

# List available log files
ls -la /var/log/

# Analyze authentication logs
sudo tail -50 /var/log/auth.log 2>/dev/null || sudo tail -50 /var/log/secure

# Analyze system messages
sudo tail -50 /var/log/messages 2>/dev/null || sudo tail -50 /var/log/syslog

# Check for failed login attempts
sudo grep -i "failed\|failure" /var/log/auth.log 2>/dev/null || sudo grep -i "failed\|failure" /var/log/secure

# Check for root access attempts
sudo grep -i "root" /var/log/auth.log 2>/dev/null || sudo grep -i "root" /var/log/secure

# Analyze mail logs for suspicious activity
sudo tail -20 /var/log/mail.log 2>/dev/null || echo "Mail log not available"
Create a script to analyze multiple log files:

nano log_analyzer.sh
Add the following content:

#!/bin/bash

echo "=== Comprehensive Log Analysis ==="
echo "Analysis Date: $(date)"
echo ""

# Function to check if file exists and analyze
analyze_log() {
    local logfile=$1
    local description=$2
    
    if [ -f "$logfile" ]; then
        echo "=== $description ==="
        echo "File: $logfile"
        echo "Last modified: $(stat -c %y $logfile)"
        echo "Size: $(stat -c %s $logfile) bytes"
        echo ""
        echo "Recent entries:"
        sudo tail -10 "$logfile"
        echo ""
    else
        echo "$description: Log file not found ($logfile)"
        echo ""
    fi
}

# Analyze different log files
analyze_log "/var/log/auth.log" "Authentication Log"
analyze_log "/var/log/secure" "Security Log (RHEL/CentOS)"
analyze_log "/var/log/syslog" "System Log"
analyze_log "/var/log/messages" "System Messages"
analyze_log "/var/log/kern.log" "Kernel Log"

echo "=== Security-Specific Analysis ==="
echo "Failed login attempts in the last 24 hours:"
sudo grep -i "failed\|failure" /var/log/auth.log 2>/dev/null | tail -10 || sudo grep -i "failed\|failure" /var/log/secure 2>/dev/null | tail -10

echo ""
echo "Root access attempts:"
sudo grep -i "root" /var/log/auth.log 2>/dev/null | tail -5 || sudo grep -i "root" /var/log/secure 2>/dev/null | tail -5
Make it executable and run:

chmod +x log_analyzer.sh
./log_analyzer.sh
Task 4: Respond to Detected Threats and Configure Further Monitoring
Subtask 4.1: Threat Response Procedures
Based on our analysis, let's implement response procedures for common threats:

Create a threat response script:

nano threat_response.sh
Add the following content:

#!/bin/bash

echo "=== Automated Threat Response System ==="
echo "Scan initiated: $(date)"
echo ""

# Function to block suspicious IP addresses
block_suspicious_ips() {
    echo "=== Checking for suspicious IP addresses ==="
    
    # Extract failed SSH attempts and get IP addresses
    SUSPICIOUS_IPS=$(sudo journalctl -u sshd --since "1 hour ago" | grep -i "failed" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort | uniq -c | sort -nr | head -5)
    
    if [ ! -z "$SUSPICIOUS_IPS" ]; then
        echo "Suspicious IP addresses found:"
        echo "$SUSPICIOUS_IPS"
        echo ""
        
        # Note: In a real environment, you might want to automatically block these IPs
        echo "Recommended action: Review and consider blocking these IPs"
    else
        echo "No suspicious IP addresses detected"
    fi
    echo ""
}

# Function to check for privilege escalation
check_privilege_escalation() {
    echo "=== Checking for privilege escalation attempts ==="
    
    PRIV_ESC=$(sudo ausearch -k privilege_escalation --start today 2>/dev/null | wc -l)
    
    if [ "$PRIV_ESC" -gt 0 ]; then
        echo "WARNING: $PRIV_ESC privilege escalation attempts detected!"
        echo "Recent attempts:"
        sudo ausearch -k privilege_escalation --start today 2>/dev/null | tail -5
    else
        echo "No privilege escalation attempts detected"
    fi
    echo ""
}

# Function to check file integrity
check_file_integrity() {
    echo "=== Checking critical file changes ==="
    
    PASSWD_CHANGES=$(sudo ausearch -k passwd_changes --start today 2>/dev/null | wc -l)
    SHADOW_CHANGES=$(sudo ausearch -k shadow_changes --start today 2>/dev/null | wc -l)
    
    if [ "$PASSWD_CHANGES" -gt 0 ] || [ "$SHADOW_CHANGES" -gt 0 ]; then
        echo "WARNING: Critical system files have been modified!"
        echo "Password file changes: $PASSWD_CHANGES"
        echo "Shadow file changes: $SHADOW_CHANGES"
        
        if [ "$PASSWD_CHANGES" -gt 0 ]; then
            echo "Recent passwd changes:"
            sudo ausearch -k passwd_changes --start today 2>/dev/null | tail -3
        fi
    else
        echo "No unauthorized changes to critical files detected"
    fi
    echo ""
}

# Execute all checks
block_suspicious_ips
check_privilege_escalation
check_file_integrity

echo "=== Threat Response Complete ==="
echo "Scan completed: $(date)"
Make it executable and run:

chmod +x threat_response.sh
./threat_response.sh
Subtask 4.2: Implementing Proactive Monitoring
Let's set up proactive monitoring to prevent future incidents:

Create an enhanced monitoring configuration:

# Add more comprehensive audit rules
sudo auditctl -w /etc/sudoers -p wa -k sudoers_changes
sudo auditctl -w /etc/ssh/sshd_config -p wa -k ssh_config_changes
sudo auditctl -w /etc/hosts -p wa -k hosts_changes
sudo auditctl -w /bin/su -p x -k su_usage
sudo auditctl -w /usr/bin/sudo -p x -k sudo_execution

# Monitor process execution
sudo auditctl -a always,exit -F arch=b64 -S execve -k process_execution

# Monitor file permission changes
sudo auditctl -a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k permission_changes
Create a monitoring daemon script:

nano security_monitor.sh
Add the following content:

#!/bin/bash

LOGFILE="/var/log/security_monitor.log"
ALERT_THRESHOLD=5

log_message() {
    echo "$(date): $1" | sudo tee -a "$LOGFILE"
}

# Function to monitor failed login attempts
monitor_failed_logins() {
    FAILED_LOGINS=$(sudo journalctl -u sshd --since "5 minutes ago" | grep -c "Failed password" 2>/dev/null || echo 0)
    
    if [ "$FAILED_LOGINS" -gt "$ALERT_THRESHOLD" ]; then
        log_message "ALERT: $FAILED_LOGINS failed login attempts in the last 5 minutes"
        
        # Extract and log suspicious IPs
        SUSPICIOUS_IPS=$(sudo journalctl -u sshd --since "5 minutes ago" | grep "Failed password" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort | uniq)
        log_message "Suspicious IPs: $SUSPICIOUS_IPS"
    fi
}

# Function to monitor audit events
monitor_audit_events() {
    # Check for recent privilege escalation attempts
    PRIV_ESC=$(sudo ausearch -k privilege_escalation --start "5 minutes ago" 2>/dev/null | wc -l)
    if [ "$PRIV_ESC" -gt 0 ]; then
        log_message "ALERT: $PRIV_ESC privilege escalation attempts detected"
    fi
    
    # Check for file changes
    FILE_CHANGES=$(sudo ausearch -k passwd_changes -k shadow_changes -k sudoers_changes --start "5 minutes ago" 2>/dev/null | wc -l)
    if [ "$FILE_CHANGES" -gt 0 ]; then
        log_message "ALERT: $FILE_CHANGES critical file changes detected"
    fi
}

# Main monitoring loop
log_message "Security monitoring started"

while true; do
    monitor_failed_logins
    monitor_audit_events
    sleep 300  # Check every 5 minutes
done
Subtask 4.3: Creating Automated Alerts and Reports
Create a daily security report generator:

nano daily_security_report.sh
Add the following content:

#!/bin/bash

REPORT_FILE="/tmp/daily_security_report_$(date +%Y%m%d).txt"

generate_report() {
    echo "=== Daily Security Report ===" > "$REPORT_FILE"
    echo "Report Date: $(date)" >> "$REPORT_FILE"
    echo "System: $(hostname)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "=== Authentication Summary ===" >> "$REPORT_FILE"
    echo "Successful logins: $(sudo journalctl --since "24 hours ago" | grep -c "Accepted" 2>/dev/null || echo 0)" >> "$REPORT_FILE"
    echo "Failed login attempts: $(sudo journalctl --since "24 hours ago" | grep -c "Failed" 2>/dev/null || echo 0)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "=== Audit Event Summary ===" >> "$REPORT_FILE"
    echo "Total audit events: $(sudo ausearch --start today 2>/dev/null | wc -l)" >> "$REPORT_FILE"
    echo "Privilege escalation attempts: $(sudo ausearch -k privilege_escalation --start today 2>/dev/null | wc -l)" >> "$REPORT_FILE"
    echo "File deletion events: $(sudo ausearch -k file_deletion --start today 2>/dev/null | wc -l)" >> "$REPORT_FILE"
    echo "Network activity events: $(sudo ausearch -k network_activity --start today 2>/dev/null | wc -l)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "=== System Health ===" >> "$REPORT_FILE"
    echo "System uptime: $(uptime)" >> "$REPORT_FILE"
    echo "Disk usage: $(df -h / | tail -1)" >> "$REPORT_FILE"
    echo "Memory usage: $(free -h | grep Mem)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "=== Top 10 Most Active Users ===" >> "$REPORT_FILE"
    sudo ausearch --start today 2>/dev/null | grep -o "uid=[0-9]*" | sort | uniq -c | sort -nr | head -10 >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "=== Recommendations ===" >> "$REPORT_FILE"
    
    # Check for high failed login attempts
    FAILED_COUNT=$(sudo journalctl --since "24 hours ago" | grep -c "Failed" 2>/dev/null || echo 0)
    if [ "$FAILED_COUNT" -gt 10 ]; then
        echo "- Consider implementing fail2ban to block suspicious IPs" >> "$REPORT_FILE"
    fi
    
    # Check for privilege escalation
    PRIV_COUNT=$(sudo ausearch -k privilege_escalation --start today 2>/dev/null | wc -l)
    if [ "$PRIV_COUNT" -gt 0 ]; then
        echo "- Review privilege escalation attempts and verify legitimacy" >> "$REPORT_FILE"
    fi
    
    echo "- Regularly update system packages" >> "$REPORT_FILE"
    echo "- Review and rotate log files" >> "$REPORT_FILE"
    echo "- Backup critical system configurations" >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    echo "Report generated by: $(whoami)" >> "$REPORT_FILE"
    echo "Report location: $REPORT_FILE" >> "$REPORT_FILE"
}

# Generate the report
generate_report

echo "Daily security report generated: $REPORT_FILE"
echo ""
echo "Report summary:"
cat "$REPORT_FILE"
Make it executable and run:

chmod +x daily_security_report.sh
./daily_security_report.sh
Subtask 4.4: Setting Up Persistent Monitoring
To make our audit rules persistent across reboots, we need to add them to the audit configuration file:

# Backup the current audit rules
sudo cp /etc/audit/rules.d/audit.rules /etc/audit/rules.d/audit.rules.backup

# Create our custom security rules file
sudo nano /etc/audit/rules.d/security-monitoring.rules
Add the following content:

# Security Monitoring Rules
# File access monitoring
-w /etc/passwd -p rwxa -k passwd_changes
-w /etc/shadow -p rwxa -k shadow_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/ssh/sshd_config -p wa -k ssh_config_changes
-w /etc/hosts -p wa -k hosts_changes
-w /tmp -p wa -k tmp_activity

# Process monitoring
-w /bin/su -p x -k su_usage
-w /usr/bin/sudo -p x -k sudo_execution

# System call monitoring
-a always,exit -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -k privilege_escalation
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k file_deletion
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k permission_changes
-a always,exit -F arch=b64 -S execve -k process_execution

# Network monitoring
-a always,exit -F arch=b64 -S socket -S connect -S accept -k network_activity

# Time change monitoring
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S stime -k time_change
Restart the audit service to apply the new rules:

sudo systemctl restart auditd
Verify the rules are loaded:

sudo auditctl -l
Troubleshooting Tips
Common Issues and Solutions
Audit service not starting

# Check service status
sudo systemctl status auditd

# Check for configuration errors
sudo auditctl -R /etc/audit/rules.d/audit.rules
No audit events being generated

# Verify audit rules are active
sudo auditctl -l

# Check audit daemon status
sudo systemctl status auditd

# Generate test events
touch /tmp/test_audit_file
Log files not accessible

# Check file permissions
ls -la /var/log/audit/

# Ensure you're using sudo for privileged operations
sudo ausearch -k passwd_changes
journalctl showing no results

# Check if systemd-journald is running
sudo systemctl status systemd-journald

# Verify journal files exist
ls -la /var/log/journal/
Conclusion
In this comprehensive lab, you have successfully learned to perform both proactive and reactive security analysis on Linux systems. Here's what you accomplished:

Key Achievements
Configured Advanced Audit Monitoring: You set up comprehensive audit rules using auditctl to monitor file access, system calls, and security-critical activities.

Mastered Log Analysis Tools: You learned to use ausearch and aureport to analyze audit logs and generate detailed security reports.

Investigated System Logs: You explored journalctl and traditional log files in /var/log/ to identify security events and system anomalies.

Implemented Threat Response: You created automated scripts to detect and respond to security threats in real-time.

Established Proactive Monitoring: You configured persistent monitoring rules and automated reporting systems to prevent future security incidents.

Why This Matters
Security analysis is crucial in today's threat landscape because:

Early Detection: Proactive monitoring helps identify threats before they cause damage
Incident Response: Reactive analysis enables quick response to security breaches
Compliance: Many regulations require comprehensive audit logging and analysis
Forensics: Detailed logs provide evidence for investigating security incidents
Continuous Improvement: Regular analysis helps strengthen security posture over time
Next Steps
To further enhance your security analysis skills:

Practice with different types of security events and attack scenarios
Learn to integrate these tools with SIEM (Security Information and Event Management) systems
Explore advanced threat hunting techniques
Study incident response procedures and playbooks
Consider pursuing additional certifications like the Red Hat Certified Specialist in Security: Linux exam
The skills you've developed in this lab form the foundation for professional security analysis and are essential for maintaining secure Linux environments in enterprise settings.
