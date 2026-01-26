Lab 17: Automating Security Scans with cron
Objectives
By the end of this lab, students will be able to:

Configure and schedule automated security scans using cron jobs
Implement OpenSCAP compliance scanning with automated scheduling
Set up periodic system hardening checks using custom scripts
Configure email notifications for security scan results
Understand best practices for automated security monitoring
Troubleshoot common issues with scheduled security tasks
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with file permissions and ownership concepts
Knowledge of basic shell scripting
Understanding of system administration fundamentals
Experience with text editors like nano or vim
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
Pre-installed OpenSCAP tools
Mail system configured for local delivery
Sample security policies and benchmarks
Task 1: Schedule OpenSCAP Scans for Compliance Using Cron Jobs
Subtask 1.1: Install and Verify OpenSCAP Tools
First, let's ensure all necessary OpenSCAP components are installed and working properly.

Check if OpenSCAP is installed:
rpm -qa | grep scap
Install OpenSCAP if not present:
sudo dnf install -y openscap-scanner scap-security-guide
Verify installation by checking available profiles:
oscap info /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml
Subtask 1.2: Create OpenSCAP Scan Script
Create a directory for security scripts:
sudo mkdir -p /opt/security-scripts
sudo mkdir -p /var/log/security-scans
Create the OpenSCAP scan script:
sudo nano /opt/security-scripts/oscap-scan.sh
Add the following content to the script:
#!/bin/bash

# OpenSCAP Automated Security Scan Script
# Created for Lab 17: Automating Security Scans

# Variables
SCAN_DATE=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="/var/log/security-scans"
REPORT_DIR="/var/log/security-scans/reports"
PROFILE="xccdf_org.ssgproject.content_profile_cis"
CONTENT_FILE="/usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml"

# Create report directory if it doesn't exist
mkdir -p $REPORT_DIR

# Log start of scan
echo "$(date): Starting OpenSCAP security scan" >> $LOG_DIR/oscap-scan.log

# Run OpenSCAP scan
oscap xccdf eval \
    --profile $PROFILE \
    --results $REPORT_DIR/oscap-results-$SCAN_DATE.xml \
    --report $REPORT_DIR/oscap-report-$SCAN_DATE.html \
    $CONTENT_FILE >> $LOG_DIR/oscap-scan.log 2>&1

# Check scan completion
if [ $? -eq 0 ] || [ $? -eq 2 ]; then
    echo "$(date): OpenSCAP scan completed successfully" >> $LOG_DIR/oscap-scan.log
    SCAN_STATUS="SUCCESS"
else
    echo "$(date): OpenSCAP scan failed with error code $?" >> $LOG_DIR/oscap-scan.log
    SCAN_STATUS="FAILED"
fi

# Generate summary
FAILED_RULES=$(grep -c "result=\"fail\"" $REPORT_DIR/oscap-results-$SCAN_DATE.xml 2>/dev/null || echo "0")
PASSED_RULES=$(grep -c "result=\"pass\"" $REPORT_DIR/oscap-results-$SCAN_DATE.xml 2>/dev/null || echo "0")

# Create summary report
cat > $REPORT_DIR/scan-summary-$SCAN_DATE.txt << EOF
OpenSCAP Security Scan Summary
==============================
Date: $(date)
Status: $SCAN_STATUS
Profile: $PROFILE
Failed Rules: $FAILED_RULES
Passed Rules: $PASSED_RULES
Report Location: $REPORT_DIR/oscap-report-$SCAN_DATE.html
Results Location: $REPORT_DIR/oscap-results-$SCAN_DATE.xml
EOF

echo "$(date): Scan summary created at $REPORT_DIR/scan-summary-$SCAN_DATE.txt" >> $LOG_DIR/oscap-scan.log
Make the script executable:
sudo chmod +x /opt/security-scripts/oscap-scan.sh
Test the script manually:
sudo /opt/security-scripts/oscap-scan.sh
Subtask 1.3: Schedule OpenSCAP Scans with Cron
Open the root crontab for editing:
sudo crontab -e
Add the following cron job to run daily at 2:00 AM:
# OpenSCAP Security Scan - Daily at 2:00 AM
0 2 * * * /opt/security-scripts/oscap-scan.sh
Add a weekly comprehensive scan on Sundays at 3:00 AM:
# Weekly comprehensive OpenSCAP scan - Sundays at 3:00 AM
0 3 * * 0 /opt/security-scripts/oscap-scan.sh
Verify the cron job is scheduled:
sudo crontab -l
Task 2: Automate Periodic System Hardening Checks
Subtask 2.1: Create System Hardening Check Script
Create a comprehensive system hardening check script:
sudo nano /opt/security-scripts/system-hardening-check.sh
Add the following content:
#!/bin/bash

# System Hardening Check Script
# Performs various security checks on the system

# Variables
CHECK_DATE=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="/var/log/security-scans"
REPORT_FILE="$LOG_DIR/hardening-check-$CHECK_DATE.txt"

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR

# Initialize report
cat > $REPORT_FILE << EOF
System Hardening Security Check Report
======================================
Date: $(date)
Hostname: $(hostname)
System: $(uname -a)

EOF

echo "Starting system hardening checks..." >> $REPORT_FILE

# Check 1: Password Policy
echo "=== PASSWORD POLICY CHECKS ===" >> $REPORT_FILE
echo "Checking /etc/login.defs for password aging..." >> $REPORT_FILE
grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE" /etc/login.defs >> $REPORT_FILE 2>&1

# Check 2: SSH Configuration
echo -e "\n=== SSH CONFIGURATION CHECKS ===" >> $REPORT_FILE
echo "Checking SSH security settings..." >> $REPORT_FILE
if [ -f /etc/ssh/sshd_config ]; then
    echo "Root login setting:" >> $REPORT_FILE
    grep -i "PermitRootLogin" /etc/ssh/sshd_config >> $REPORT_FILE 2>&1
    echo "Password authentication setting:" >> $REPORT_FILE
    grep -i "PasswordAuthentication" /etc/ssh/sshd_config >> $REPORT_FILE 2>&1
    echo "Protocol version:" >> $REPORT_FILE
    grep -i "Protocol" /etc/ssh/sshd_config >> $REPORT_FILE 2>&1
fi

# Check 3: Firewall Status
echo -e "\n=== FIREWALL STATUS ===" >> $REPORT_FILE
echo "Checking firewall status..." >> $REPORT_FILE
systemctl is-active firewalld >> $REPORT_FILE 2>&1
if systemctl is-active --quiet firewalld; then
    echo "Active firewall zones:" >> $REPORT_FILE
    firewall-cmd --list-all-zones >> $REPORT_FILE 2>&1
fi

# Check 4: Failed Login Attempts
echo -e "\n=== FAILED LOGIN ATTEMPTS ===" >> $REPORT_FILE
echo "Recent failed login attempts (last 10):" >> $REPORT_FILE
lastb -n 10 >> $REPORT_FILE 2>&1

# Check 5: World-Writable Files
echo -e "\n=== WORLD-WRITABLE FILES CHECK ===" >> $REPORT_FILE
echo "Searching for world-writable files in critical directories..." >> $REPORT_FILE
find /etc /bin /sbin /usr/bin /usr/sbin -type f -perm -002 2>/dev/null >> $REPORT_FILE

# Check 6: SUID/SGID Files
echo -e "\n=== SUID/SGID FILES ===" >> $REPORT_FILE
echo "SUID files:" >> $REPORT_FILE
find / -type f -perm -4000 2>/dev/null | head -20 >> $REPORT_FILE
echo "SGID files:" >> $REPORT_FILE
find / -type f -perm -2000 2>/dev/null | head -20 >> $REPORT_FILE

# Check 7: System Updates
echo -e "\n=== SYSTEM UPDATES ===" >> $REPORT_FILE
echo "Available security updates:" >> $REPORT_FILE
dnf check-update --security 2>/dev/null | tail -10 >> $REPORT_FILE

# Check 8: Running Services
echo -e "\n=== RUNNING SERVICES ===" >> $REPORT_FILE
echo "Currently running services:" >> $REPORT_FILE
systemctl list-units --type=service --state=running >> $REPORT_FILE

# Check 9: Network Connections
echo -e "\n=== NETWORK CONNECTIONS ===" >> $REPORT_FILE
echo "Active network connections:" >> $REPORT_FILE
netstat -tuln >> $REPORT_FILE 2>&1

# Check 10: User Accounts
echo -e "\n=== USER ACCOUNTS ===" >> $REPORT_FILE
echo "User accounts with login shells:" >> $REPORT_FILE
grep -v "/sbin/nologin\|/bin/false" /etc/passwd >> $REPORT_FILE

# Summary
echo -e "\n=== SUMMARY ===" >> $REPORT_FILE
echo "Hardening check completed at $(date)" >> $REPORT_FILE
echo "Report saved to: $REPORT_FILE" >> $REPORT_FILE

# Log completion
echo "$(date): System hardening check completed - Report: $REPORT_FILE" >> $LOG_DIR/hardening-check.log
Make the script executable:
sudo chmod +x /opt/security-scripts/system-hardening-check.sh
Test the script:
sudo /opt/security-scripts/system-hardening-check.sh
Subtask 2.2: Schedule System Hardening Checks
Add hardening checks to crontab:
sudo crontab -e
Add the following entries:
# System hardening check - Daily at 1:00 AM
0 1 * * * /opt/security-scripts/system-hardening-check.sh

# Weekly comprehensive hardening check - Saturdays at 4:00 AM
0 4 * * 6 /opt/security-scripts/system-hardening-check.sh
Task 3: Configure Email Alerts for Scan Results
Subtask 3.1: Install and Configure Mail System
Install mail utilities:
sudo dnf install -y mailx postfix
Start and enable postfix:
sudo systemctl start postfix
sudo systemctl enable postfix
Test local mail delivery:
echo "Test email from security lab" | mail -s "Test Subject" root
Check if mail was delivered:
sudo mail
Subtask 3.2: Create Email Alert Script
Create an email notification script:
sudo nano /opt/security-scripts/email-alerts.sh
Add the following content:
#!/bin/bash

# Email Alert Script for Security Scans
# Sends email notifications based on scan results

# Variables
ADMIN_EMAIL="root@localhost"
HOSTNAME=$(hostname)
LOG_DIR="/var/log/security-scans"
REPORT_DIR="/var/log/security-scans/reports"

# Function to send email
send_alert() {
    local subject="$1"
    local body="$2"
    local attachment="$3"
    
    if [ -n "$attachment" ] && [ -f "$attachment" ]; then
        echo "$body" | mail -s "$subject" -a "$attachment" "$ADMIN_EMAIL"
    else
        echo "$body" | mail -s "$subject" "$ADMIN_EMAIL"
    fi
}

# Check for recent OpenSCAP scan results
check_oscap_results() {
    local latest_summary=$(ls -t $REPORT_DIR/scan-summary-*.txt 2>/dev/null | head -1)
    
    if [ -f "$latest_summary" ]; then
        local failed_count=$(grep "Failed Rules:" "$latest_summary" | awk '{print $3}')
        local scan_status=$(grep "Status:" "$latest_summary" | awk '{print $2}')
        
        if [ "$scan_status" = "FAILED" ]; then
            local subject="[CRITICAL] OpenSCAP Scan Failed on $HOSTNAME"
            local body="OpenSCAP security scan failed on $HOSTNAME.
            
Please check the system immediately.

Summary:
$(cat $latest_summary)"
            send_alert "$subject" "$body" "$latest_summary"
            
        elif [ "$failed_count" -gt 10 ]; then
            local subject="[WARNING] High Number of Failed Security Rules on $HOSTNAME"
            local body="OpenSCAP scan completed but found $failed_count failed security rules.

This exceeds the threshold of 10 failed rules.

Summary:
$(cat $latest_summary)"
            send_alert "$subject" "$body" "$latest_summary"
        fi
    fi
}

# Check for system hardening issues
check_hardening_results() {
    local latest_hardening=$(ls -t $LOG_DIR/hardening-check-*.txt 2>/dev/null | head -1)
    
    if [ -f "$latest_hardening" ]; then
        # Check for critical issues
        local world_writable=$(grep -A 10 "WORLD-WRITABLE FILES" "$latest_hardening" | wc -l)
        local failed_logins=$(grep -A 10 "FAILED LOGIN ATTEMPTS" "$latest_hardening" | grep -v "^$" | wc -l)
        
        if [ "$world_writable" -gt 5 ] || [ "$failed_logins" -gt 15 ]; then
            local subject="[WARNING] System Hardening Issues Detected on $HOSTNAME"
            local body="System hardening check detected potential security issues:

- World-writable files found: $world_writable
- Recent failed login attempts: $failed_logins

Please review the attached report.

Report excerpt:
$(head -50 $latest_hardening)"
            send_alert "$subject" "$body" "$latest_hardening"
        fi
    fi
}

# Main execution
echo "$(date): Starting email alert checks" >> $LOG_DIR/email-alerts.log

check_oscap_results
check_hardening_results

echo "$(date): Email alert checks completed" >> $LOG_DIR/email-alerts.log
Make the script executable:
sudo chmod +x /opt/security-scripts/email-alerts.sh
Subtask 3.3: Schedule Email Alerts
Add email alert scheduling to crontab:
sudo crontab -e
Add the following entry to run alerts 30 minutes after scans:
# Email alerts for security scans - 30 minutes after daily scans
30 1 * * * /opt/security-scripts/email-alerts.sh
30 2 * * * /opt/security-scripts/email-alerts.sh
Subtask 3.4: Create Master Security Automation Script
Create a comprehensive automation script:
sudo nano /opt/security-scripts/security-automation-master.sh
Add the following content:
#!/bin/bash

# Master Security Automation Script
# Coordinates all security scanning and alerting

# Variables
SCRIPT_DIR="/opt/security-scripts"
LOG_DIR="/var/log/security-scans"
MASTER_LOG="$LOG_DIR/security-automation.log"

# Ensure log directory exists
mkdir -p $LOG_DIR

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> $MASTER_LOG
}

# Function to run script with error handling
run_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [ -f "$script_path" ] && [ -x "$script_path" ]; then
        log_message "Starting $script_name"
        $script_path
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            log_message "$script_name completed successfully"
        else
            log_message "$script_name failed with exit code $exit_code"
        fi
        return $exit_code
    else
        log_message "Script $script_name not found or not executable"
        return 1
    fi
}

# Main execution
log_message "=== Starting Security Automation Suite ==="

# Run system hardening check first
run_script "system-hardening-check.sh"

# Wait a moment, then run OpenSCAP scan
sleep 60
run_script "oscap-scan.sh"

# Wait for scans to complete, then check for alerts
sleep 300
run_script "email-alerts.sh"

log_message "=== Security Automation Suite Completed ==="

# Clean up old reports (keep last 30 days)
find $LOG_DIR -name "*.txt" -mtime +30 -delete 2>/dev/null
find $LOG_DIR -name "*.xml" -mtime +30 -delete 2>/dev/null
find $LOG_DIR -name "*.html" -mtime +30 -delete 2>/dev/null

log_message "Old reports cleaned up"
Make the script executable:
sudo chmod +x /opt/security-scripts/security-automation-master.sh
Update crontab to use the master script:
sudo crontab -e
Replace previous entries with:
# Master Security Automation - Daily at 1:00 AM
0 1 * * * /opt/security-scripts/security-automation-master.sh

# Weekly comprehensive security check - Sundays at 2:00 AM
0 2 * * 0 /opt/security-scripts/security-automation-master.sh
Verification and Testing
Test the Complete Automation
Verify all scripts are in place:
ls -la /opt/security-scripts/
Check cron jobs are scheduled:
sudo crontab -l
Test the master script manually:
sudo /opt/security-scripts/security-automation-master.sh
Check generated reports:
ls -la /var/log/security-scans/
ls -la /var/log/security-scans/reports/
Verify email functionality:
sudo mail
Monitor Automation
Check automation logs:
sudo tail -f /var/log/security-scans/security-automation.log
Monitor cron execution:
sudo tail -f /var/log/cron
View recent scan summaries:
sudo cat /var/log/security-scans/reports/scan-summary-*.txt | tail -20
Troubleshooting Common Issues
Issue 1: OpenSCAP Scan Fails
Problem: OpenSCAP scan returns error codes

Solution:

# Check if content file exists
ls -la /usr/share/xml/scap/ssg/content/

# Verify available profiles
oscap info /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml | grep Profile

# Test with a different profile
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_standard /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml
Issue 2: Email Alerts Not Working
Problem: Email notifications are not being sent

Solution:

# Check postfix status
sudo systemctl status postfix

# Test mail command
echo "Test" | mail -s "Test" root

# Check mail logs
sudo tail -f /var/log/maillog
Issue 3: Cron Jobs Not Running
Problem: Scheduled tasks are not executing

Solution:

# Check cron service
sudo systemctl status crond

# Verify cron jobs
sudo crontab -l

# Check cron logs
sudo tail -f /var/log/cron

# Ensure scripts have proper permissions
sudo chmod +x /opt/security-scripts/*.sh
Issue 4: Permission Denied Errors
Problem: Scripts fail due to permission issues

Solution:

# Fix script permissions
sudo chmod +x /opt/security-scripts/*.sh

# Fix directory permissions
sudo chmod 755 /opt/security-scripts/
sudo chmod 755 /var/log/security-scans/

# Ensure scripts run as root
sudo crontab -l
Best Practices for Security Automation
Security Considerations
Secure Script Storage:
# Set proper ownership and permissions
sudo chown root:root /opt/security-scripts/*.sh
sudo chmod 750 /opt/security-scripts/*.sh
Log Rotation:
# Create logrotate configuration
sudo nano /etc/logrotate.d/security-scans
Add:

/var/log/security-scans/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
Backup Important Reports:
# Create backup script
sudo nano /opt/security-scripts/backup-reports.sh
Performance Optimization
Schedule During Off-Peak Hours: Run intensive scans during low-usage periods
Stagger Scan Times: Avoid running all scans simultaneously
Monitor System Resources: Ensure scans don't impact system performance
Conclusion
In this lab, you have successfully implemented a comprehensive automated security scanning system using cron jobs and open-source tools. You have accomplished the following:

Key Achievements:

Automated OpenSCAP Compliance Scanning: Set up scheduled security compliance scans using OpenSCAP with the CIS benchmark profile, generating detailed HTML reports and XML results files.

System Hardening Monitoring: Created comprehensive system hardening checks that monitor password policies, SSH configuration, firewall status, failed login attempts, file permissions, and system updates.

Intelligent Email Alerting: Implemented smart email notification system that sends alerts based on scan results, including critical failures and security threshold violations.

Centralized Automation: Developed a master automation script that coordinates all security tasks, handles error logging, and maintains report retention policies.

Why This Matters:

Proactive Security: Automated scanning helps identify security issues before they can be exploited
Compliance Assurance: Regular OpenSCAP scans ensure ongoing compliance with security standards
Operational Efficiency: Automation reduces manual effort while maintaining consistent security monitoring
Rapid Response: Email alerts enable quick response to security incidents
Audit Trail: Comprehensive logging provides evidence of security monitoring activities
Real-World Applications:

This automation framework is essential for:

Enterprise security operations centers (SOCs)
Compliance reporting for audits
DevSecOps integration
Managed security service providers
Government and regulated industry environments
The skills you've developed in this lab are directly applicable to the Red Hat Certified Specialist in Security: Linux exam and are highly valued in cybersecurity and system administration roles. You now have the foundation to build more sophisticated security automation systems and integrate them with enterprise security tools.
