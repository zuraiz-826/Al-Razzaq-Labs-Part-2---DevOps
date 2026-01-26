Lab 11: Automating Security Checks with Bash Scripts
Objectives
By the end of this lab, students will be able to:

Create bash scripts to automate system hardening tasks including disabling unused ports and applying security patches
Implement automated security checks for common vulnerabilities
Schedule security scripts using cron for regular execution
Understand the importance of automation in maintaining system security
Apply security best practices through scripted solutions
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with bash scripting fundamentals
Knowledge of file permissions and ownership concepts
Understanding of network services and ports
Basic knowledge of system administration tasks
Lab Environment
Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL-based Linux system
Root access for system administration tasks
Pre-installed security tools and utilities
Network connectivity for package updates
Task 1: Creating System Hardening Scripts
Subtask 1.1: Create a Port Security Script
First, we'll create a script to identify and disable unused network ports.

Create the script directory and file:
mkdir -p /opt/security-scripts
cd /opt/security-scripts
touch port_security.sh
chmod +x port_security.sh
Edit the port security script:
nano port_security.sh
Add the following content to the script:
#!/bin/bash

# Port Security Hardening Script
# Description: Identifies open ports and disables unused services

LOG_FILE="/var/log/port_security.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "[$DATE] $1" | tee -a "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "ERROR: This script must be run as root"
        exit 1
    fi
}

# Function to scan open ports
scan_ports() {
    log_message "Starting port scan..."
    
    # Get listening ports
    netstat -tuln > /tmp/open_ports.txt
    
    # Display current listening ports
    log_message "Current listening ports:"
    cat /tmp/open_ports.txt | grep LISTEN | tee -a "$LOG_FILE"
}

# Function to disable common unused services
disable_unused_services() {
    log_message "Checking for unused services to disable..."
    
    # List of commonly unused services
    SERVICES=("telnet" "rsh" "rlogin" "vsftpd" "xinetd")
    
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_message "Disabling service: $service"
            systemctl stop "$service"
            systemctl disable "$service"
        else
            log_message "Service $service is already inactive"
        fi
    done
}

# Function to configure firewall rules
configure_firewall() {
    log_message "Configuring firewall rules..."
    
    # Ensure firewalld is running
    systemctl start firewalld
    systemctl enable firewalld
    
    # Remove unnecessary services from public zone
    REMOVE_SERVICES=("dhcpv6-client" "cockpit")
    
    for service in "${REMOVE_SERVICES[@]}"; do
        if firewall-cmd --list-services | grep -q "$service"; then
            log_message "Removing $service from firewall"
            firewall-cmd --permanent --remove-service="$service"
        fi
    done
    
    # Reload firewall
    firewall-cmd --reload
    log_message "Firewall configuration updated"
}

# Main execution
main() {
    log_message "=== Port Security Script Started ==="
    check_root
    scan_ports
    disable_unused_services
    configure_firewall
    log_message "=== Port Security Script Completed ==="
}

# Execute main function
main
Test the port security script:
./port_security.sh
Review the log file:
cat /var/log/port_security.log
Subtask 1.2: Create a Security Patch Management Script
Now we'll create a script to automate security patch installation.

Create the patch management script:
touch patch_management.sh
chmod +x patch_management.sh
Edit the script:
nano patch_management.sh
Add the following content:
#!/bin/bash

# Security Patch Management Script
# Description: Automates security patch installation and system updates

LOG_FILE="/var/log/patch_management.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
REBOOT_REQUIRED=false

# Function to log messages
log_message() {
    echo "[$DATE] $1" | tee -a "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "ERROR: This script must be run as root"
        exit 1
    fi
}

# Function to backup important files before patching
backup_system() {
    log_message "Creating system backup..."
    
    BACKUP_DIR="/backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup critical configuration files
    cp -r /etc/passwd /etc/shadow /etc/group "$BACKUP_DIR/" 2>/dev/null
    cp -r /etc/ssh/ "$BACKUP_DIR/" 2>/dev/null
    
    log_message "Backup created in $BACKUP_DIR"
}

# Function to update package repositories
update_repositories() {
    log_message "Updating package repositories..."
    
    if command -v yum >/dev/null 2>&1; then
        yum clean all
        yum makecache
    elif command -v dnf >/dev/null 2>&1; then
        dnf clean all
        dnf makecache
    elif command -v apt >/dev/null 2>&1; then
        apt update
    fi
    
    log_message "Package repositories updated"
}

# Function to install security updates
install_security_updates() {
    log_message "Installing security updates..."
    
    if command -v yum >/dev/null 2>&1; then
        # For RHEL/CentOS systems
        yum update --security -y | tee -a "$LOG_FILE"
        
        # Check if kernel was updated
        if yum history list | head -2 | grep -q kernel; then
            REBOOT_REQUIRED=true
        fi
        
    elif command -v dnf >/dev/null 2>&1; then
        # For Fedora systems
        dnf upgrade --security -y | tee -a "$LOG_FILE"
        
        # Check if kernel was updated
        if dnf history list | head -2 | grep -q kernel; then
            REBOOT_REQUIRED=true
        fi
        
    elif command -v apt >/dev/null 2>&1; then
        # For Debian/Ubuntu systems
        apt upgrade -y | tee -a "$LOG_FILE"
        
        # Check if reboot is required
        if [ -f /var/run/reboot-required ]; then
            REBOOT_REQUIRED=true
        fi
    fi
    
    log_message "Security updates installation completed"
}

# Function to verify installed patches
verify_patches() {
    log_message "Verifying installed patches..."
    
    if command -v yum >/dev/null 2>&1; then
        yum history list | head -5 | tee -a "$LOG_FILE"
    elif command -v dnf >/dev/null 2>&1; then
        dnf history list | head -5 | tee -a "$LOG_FILE"
    elif command -v apt >/dev/null 2>&1; then
        apt list --upgradable | tee -a "$LOG_FILE"
    fi
}

# Function to clean up after patching
cleanup_system() {
    log_message "Cleaning up system..."
    
    if command -v yum >/dev/null 2>&1; then
        yum clean all
    elif command -v dnf >/dev/null 2>&1; then
        dnf clean all
    elif command -v apt >/dev/null 2>&1; then
        apt autoremove -y
        apt autoclean
    fi
    
    log_message "System cleanup completed"
}

# Function to handle reboot if required
handle_reboot() {
    if [ "$REBOOT_REQUIRED" = true ]; then
        log_message "REBOOT REQUIRED: System will reboot in 5 minutes"
        log_message "Cancel with: shutdown -c"
        shutdown -r +5 "System reboot required for security updates"
    else
        log_message "No reboot required"
    fi
}

# Main execution
main() {
    log_message "=== Patch Management Script Started ==="
    check_root
    backup_system
    update_repositories
    install_security_updates
    verify_patches
    cleanup_system
    handle_reboot
    log_message "=== Patch Management Script Completed ==="
}

# Execute main function
main
Test the patch management script:
./patch_management.sh
Subtask 1.3: Create a Comprehensive Security Audit Script
Create a script that performs various security checks.

Create the security audit script:
touch security_audit.sh
chmod +x security_audit.sh
Edit the script:
nano security_audit.sh
Add the following content:
#!/bin/bash

# Comprehensive Security Audit Script
# Description: Performs various security checks and generates a report

LOG_FILE="/var/log/security_audit.log"
REPORT_FILE="/var/log/security_audit_report.txt"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "[$DATE] $1" | tee -a "$LOG_FILE"
}

# Function to add to report
add_to_report() {
    echo "$1" >> "$REPORT_FILE"
}

# Function to check file permissions
check_file_permissions() {
    log_message "Checking critical file permissions..."
    add_to_report "=== FILE PERMISSIONS AUDIT ==="
    
    # Check critical system files
    CRITICAL_FILES=("/etc/passwd" "/etc/shadow" "/etc/group" "/etc/gshadow")
    
    for file in "${CRITICAL_FILES[@]}"; do
        if [ -f "$file" ]; then
            PERMS=$(stat -c "%a" "$file")
            OWNER=$(stat -c "%U:%G" "$file")
            add_to_report "$file: Permissions=$PERMS, Owner=$OWNER"
            
            # Check for world-readable shadow files
            if [[ "$file" == *"shadow"* ]] && [[ "$PERMS" != "000" ]] && [[ "$PERMS" != "640" ]]; then
                add_to_report "WARNING: $file has insecure permissions!"
            fi
        fi
    done
}

# Function to check for SUID/SGID files
check_suid_sgid() {
    log_message "Checking for SUID/SGID files..."
    add_to_report "=== SUID/SGID FILES ==="
    
    find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -la {} \; 2>/dev/null | head -20 >> "$REPORT_FILE"
}

# Function to check user accounts
check_user_accounts() {
    log_message "Auditing user accounts..."
    add_to_report "=== USER ACCOUNT AUDIT ==="
    
    # Check for accounts with UID 0
    add_to_report "Accounts with UID 0 (root privileges):"
    awk -F: '$3 == 0 {print $1}' /etc/passwd >> "$REPORT_FILE"
    
    # Check for accounts without passwords
    add_to_report "Accounts without passwords:"
    awk -F: '$2 == "" {print $1}' /etc/shadow >> "$REPORT_FILE"
    
    # Check for inactive accounts
    add_to_report "Recently active users (last 30 days):"
    lastlog -t 30 | grep -v "Never" >> "$REPORT_FILE"
}

# Function to check network security
check_network_security() {
    log_message "Checking network security..."
    add_to_report "=== NETWORK SECURITY AUDIT ==="
    
    # Check listening services
    add_to_report "Listening services:"
    netstat -tuln | grep LISTEN >> "$REPORT_FILE"
    
    # Check firewall status
    add_to_report "Firewall status:"
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --state >> "$REPORT_FILE"
        firewall-cmd --list-all >> "$REPORT_FILE"
    elif command -v ufw >/dev/null 2>&1; then
        ufw status >> "$REPORT_FILE"
    fi
}

# Function to check system logs for security events
check_security_logs() {
    log_message "Checking security logs..."
    add_to_report "=== SECURITY LOG ANALYSIS ==="
    
    # Check for failed login attempts
    add_to_report "Recent failed login attempts:"
    grep "Failed password" /var/log/secure 2>/dev/null | tail -10 >> "$REPORT_FILE"
    
    # Check for sudo usage
    add_to_report "Recent sudo usage:"
    grep "sudo:" /var/log/secure 2>/dev/null | tail -10 >> "$REPORT_FILE"
}

# Function to check system integrity
check_system_integrity() {
    log_message "Checking system integrity..."
    add_to_report "=== SYSTEM INTEGRITY CHECK ==="
    
    # Check for world-writable files
    add_to_report "World-writable files (sample):"
    find / -type f -perm -002 2>/dev/null | head -10 >> "$REPORT_FILE"
    
    # Check disk usage
    add_to_report "Disk usage:"
    df -h >> "$REPORT_FILE"
}

# Function to generate summary
generate_summary() {
    log_message "Generating audit summary..."
    add_to_report "=== AUDIT SUMMARY ==="
    add_to_report "Audit completed on: $DATE"
    add_to_report "Report location: $REPORT_FILE"
    add_to_report "Log location: $LOG_FILE"
    
    # Count potential issues
    ISSUES=$(grep -c "WARNING\|CRITICAL" "$REPORT_FILE" 2>/dev/null || echo "0")
    add_to_report "Potential security issues found: $ISSUES"
}

# Main execution
main() {
    log_message "=== Security Audit Started ==="
    
    # Clear previous report
    > "$REPORT_FILE"
    
    check_file_permissions
    check_suid_sgid
    check_user_accounts
    check_network_security
    check_security_logs
    check_system_integrity
    generate_summary
    
    log_message "=== Security Audit Completed ==="
    log_message "Report saved to: $REPORT_FILE"
}

# Execute main function
main
Run the security audit script:
./security_audit.sh
Review the audit report:
cat /var/log/security_audit_report.txt
Task 2: Scheduling Scripts with Cron
Subtask 2.1: Understanding Cron Syntax
Before scheduling our scripts, let's understand cron syntax:

* * * * * command
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, Sunday = 0 or 7)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
Common examples:

0 2 * * * - Daily at 2:00 AM
0 0 * * 0 - Weekly on Sunday at midnight
*/15 * * * * - Every 15 minutes
0 1 1 * * - Monthly on the 1st at 1:00 AM
Subtask 2.2: Create a Master Security Script
First, create a master script that calls all our security scripts:

Create the master script:
touch master_security.sh
chmod +x master_security.sh
Edit the master script:
nano master_security.sh
Add the following content:
#!/bin/bash

# Master Security Script
# Description: Orchestrates all security scripts based on schedule type

SCRIPT_DIR="/opt/security-scripts"
LOG_FILE="/var/log/master_security.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "[$DATE] $1" | tee -a "$LOG_FILE"
}

# Function to run daily security tasks
run_daily_tasks() {
    log_message "Running daily security tasks..."
    
    # Run security audit
    if [ -x "$SCRIPT_DIR/security_audit.sh" ]; then
        log_message "Executing security audit..."
        "$SCRIPT_DIR/security_audit.sh"
    fi
    
    # Run port security check
    if [ -x "$SCRIPT_DIR/port_security.sh" ]; then
        log_message "Executing port security check..."
        "$SCRIPT_DIR/port_security.sh"
    fi
}

# Function to run weekly security tasks
run_weekly_tasks() {
    log_message "Running weekly security tasks..."
    
    # Run patch management
    if [ -x "$SCRIPT_DIR/patch_management.sh" ]; then
        log_message "Executing patch management..."
        "$SCRIPT_DIR/patch_management.sh"
    fi
    
    # Run daily tasks as well
    run_daily_tasks
}

# Function to send email notification (if mail is configured)
send_notification() {
    local subject="$1"
    local message="$2"
    
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "$subject" root
        log_message "Email notification sent: $subject"
    else
        log_message "Mail not configured - notification skipped"
    fi
}

# Main execution based on argument
case "$1" in
    "daily")
        log_message "=== Daily Security Tasks Started ==="
        run_daily_tasks
        send_notification "Daily Security Report" "Daily security tasks completed. Check logs for details."
        log_message "=== Daily Security Tasks Completed ==="
        ;;
    "weekly")
        log_message "=== Weekly Security Tasks Started ==="
        run_weekly_tasks
        send_notification "Weekly Security Report" "Weekly security tasks completed. Check logs for details."
        log_message "=== Weekly Security Tasks Completed ==="
        ;;
    *)
        echo "Usage: $0 {daily|weekly}"
        echo "  daily  - Run daily security checks"
        echo "  weekly - Run weekly security maintenance"
        exit 1
        ;;
esac
Subtask 2.3: Schedule Scripts with Cron
Now let's schedule our security scripts using cron:

Open the root crontab:
crontab -e
Add the following cron entries:
# Security automation cron jobs
# Daily security audit at 2:00 AM
0 2 * * * /opt/security-scripts/master_security.sh daily

# Weekly security maintenance on Sunday at 3:00 AM
0 3 * * 0 /opt/security-scripts/master_security.sh weekly

# Port security check every 6 hours
0 */6 * * * /opt/security-scripts/port_security.sh

# Quick security audit every 4 hours during business days
0 8,12,16 * * 1-5 /opt/security-scripts/security_audit.sh
Save and exit the crontab editor

Verify the cron jobs are scheduled:

crontab -l
Subtask 2.4: Create a Cron Management Script
Create a script to help manage cron jobs for security tasks:

Create the cron management script:
touch cron_manager.sh
chmod +x cron_manager.sh
Edit the script:
nano cron_manager.sh
Add the following content:
#!/bin/bash

# Cron Management Script for Security Tasks
# Description: Helps manage security-related cron jobs

CRON_BACKUP="/tmp/crontab_backup_$(date +%Y%m%d_%H%M%S)"

# Function to display current cron jobs
show_cron_jobs() {
    echo "Current cron jobs:"
    echo "=================="
    crontab -l 2>/dev/null || echo "No cron jobs found"
}

# Function to backup current crontab
backup_crontab() {
    echo "Backing up current crontab to: $CRON_BACKUP"
    crontab -l > "$CRON_BACKUP" 2>/dev/null
    echo "Backup completed"
}

# Function to install security cron jobs
install_security_crons() {
    echo "Installing security cron jobs..."
    
    # Backup existing crontab
    backup_crontab
    
    # Create temporary cron file
    TEMP_CRON="/tmp/security_crons"
    
    # Add existing cron jobs (if any)
    crontab -l 2>/dev/null > "$TEMP_CRON"
    
    # Add security cron jobs
    cat >> "$TEMP_CRON" << 'EOF'

# Security automation cron jobs - Added by cron_manager.sh
# Daily security audit at 2:00 AM
0 2 * * * /opt/security-scripts/master_security.sh daily

# Weekly security maintenance on Sunday at 3:00 AM
0 3 * * 0 /opt/security-scripts/master_security.sh weekly

# Port security check every 6 hours
0 */6 * * * /opt/security-scripts/port_security.sh

# Quick security audit every 4 hours during business days
0 8,12,16 * * 1-5 /opt/security-scripts/security_audit.sh
EOF

    # Install the new crontab
    crontab "$TEMP_CRON"
    rm "$TEMP_CRON"
    
    echo "Security cron jobs installed successfully"
}

# Function to remove security cron jobs
remove_security_crons() {
    echo "Removing security cron jobs..."
    
    # Backup existing crontab
    backup_crontab
    
    # Remove security-related cron jobs
    crontab -l 2>/dev/null | grep -v "security-scripts\|Security automation" | crontab -
    
    echo "Security cron jobs removed"
}

# Function to test cron job execution
test_cron_execution() {
    echo "Testing cron job execution..."
    
    # Test daily tasks
    echo "Testing daily security tasks..."
    /opt/security-scripts/master_security.sh daily
    
    echo "Test completed. Check log files for results."
}

# Function to show cron logs
show_cron_logs() {
    echo "Recent cron execution logs:"
    echo "=========================="
    
    # Check different possible cron log locations
    if [ -f /var/log/cron ]; then
        tail -20 /var/log/cron | grep security-scripts
    elif [ -f /var/log/syslog ]; then
        tail -20 /var/log/syslog | grep CRON | grep security-scripts
    else
        echo "Cron logs not found in standard locations"
    fi
}

# Main menu
show_menu() {
    echo "Security Cron Management Script"
    echo "==============================="
    echo "1. Show current cron jobs"
    echo "2. Install security cron jobs"
    echo "3. Remove security cron jobs"
    echo "4. Test cron job execution"
    echo "5. Show cron logs"
    echo "6. Backup current crontab"
    echo "7. Exit"
    echo
}

# Main execution
main() {
    while true; do
        show_menu
        read -p "Select an option (1-7): " choice
        
        case $choice in
            1) show_cron_jobs ;;
            2) install_security_crons ;;
            3) remove_security_crons ;;
            4) test_cron_execution ;;
            5) show_cron_logs ;;
            6) backup_crontab ;;
            7) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
        clear
    done
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script should be run as root for full functionality"
    read -p "Continue anyway? (y/n): " continue_choice
    if [[ $continue_choice != "y" ]]; then
        exit 1
    fi
fi

# Execute main function
main
Run the cron management script:
./cron_manager.sh
Subtask 2.5: Monitor Cron Job Execution
Create a monitoring script to track cron job execution:

Create the monitoring script:
touch cron_monitor.sh
chmod +x cron_monitor.sh
Edit the script:
nano cron_monitor.sh
Add the following content:
#!/bin/bash

# Cron Job Monitoring Script
# Description: Monitors execution of security cron jobs

MONITOR_LOG="/var/log/cron_monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "[$DATE] $1" | tee -a "$MONITOR_LOG"
}

# Function to check if cron service is running
check_cron_service() {
    log_message "Checking cron service status..."
    
    if systemctl is-active --quiet crond; then
        log_message "Cron service is running"
        return 0
    elif systemctl is-active --quiet cron; then
        log_message "Cron service is running"
        return 0
    else
        log_message "ERROR: Cron service is not running!"
        return 1
    fi
}

# Function to verify cron jobs are scheduled
verify_cron_jobs() {
    log_message "Verifying security cron jobs..."
    
    CRON_COUNT=$(crontab -l 2>/dev/null | grep -c "security-scripts")
    
    if [ "$CRON_COUNT" -gt 0 ]; then
        log_message "Found $CRON_COUNT security cron jobs"
        crontab -l | grep "security-scripts" | while read line; do
            log_message "Scheduled: $line"
        done
    else
        log_message "WARNING: No security cron jobs found!"
    fi
}

# Function to check recent executions
check_recent_executions() {
    log_message "Checking recent cron executions..."
    
    # Check various log locations for cron execution
    if [ -f /var/log/cron ]; then
        RECENT_RUNS=$(grep "security-scripts" /var/log/cron | tail -5)
    elif [ -f /var/log/syslog ]; then
        RECENT_RUNS=$(grep "CRON.*security-scripts" /var/log/syslog | tail -5)
    else
        log_message "Cron logs not found"
        return
    fi
    
    if [ -n "$RECENT_RUNS" ]; then
        log_message "Recent executions:"
        echo "$RECENT_RUNS" | tee -a "$MONITOR_LOG"
    else
        log_message "No recent executions found"
    fi
}

# Function to check log file sizes and rotation
check_log_files() {
    log_message "Checking security log files..."
    
    LOG_FILES=("/var/log/security_audit.log" "/var/log/port_security.log" "/var/log/patch_management.log")
    
    for logfile in "${LOG_FILES[@]}"; do
        if [ -f "$logfile" ]; then
            SIZE=$(du -h "$logfile" | cut -f1)
            LINES=$(wc -l < "$logfile")
            log_message "$logfile: Size=$SIZE, Lines=$LINES"
            
            # Check if log file is getting too large
            SIZE_BYTES=$(stat -c%s "$logfile")
            if [ "$SIZE_BYTES" -gt 10485760 ]; then  # 10MB
                log_message "WARNING: $logfile is larger than 10MB"
            fi
        else
            log_message "Log file not found: $logfile"
        fi
    done
}

# Function to generate monitoring report
generate_report() {
    REPORT_FILE="/var/log/cron_monitoring_report.txt"
    
    {
        echo "Cron Job Monitoring Report"
        echo "========================="
        echo "Generated: $DATE"
        echo
        
        echo "Cron Service Status:"
        systemctl status crond 2>/dev/null || systemctl status cron 2>/dev/null
        echo
        
        echo "Scheduled Security Jobs:"
        crontab -l 2>/dev/null | grep "security-scripts" || echo "None found"
        echo
        
        echo "Recent Security Script Executions:"
        if [ -f /var/log/master_security.log ]; then
            tail -10 /var/log/master_security.log
        else
            echo "No execution logs found"
        fi
        
    } > "$REPORT_FILE"
    
    log_message "Monitoring report generated: $REPORT_FILE"
}

# Main execution
main() {
    log_message "=== Cron Monitoring Started ==="
    
    check_cron_service
    verify_cron_jobs
    check_recent_executions
    check_log_files
    generate_report
    
    log_message "=== Cron Monitoring Completed ==="
}

# Execute main function
main
Run the monitoring script:
./cron_monitor.sh
View the monitoring report:
cat /var/log/cron_monitoring_report.txt
Testing and Validation
Test Script Execution
Test individual scripts manually:
# Test port security script
./port_security.sh

# Test patch management script (be careful in production)
./patch_management.sh

# Test security audit script
./security_audit.sh
Test the master script:
# Test daily tasks
./master_security.sh daily

# Test weekly tasks
./master_security.sh weekly
Verify cron job scheduling:
# List current cron jobs
crontab -l

# Check cron service status
systemctl status crond
Verify Log Files
Check that all log files are being created and populated:

ls -la /var/log/*security*
ls -la /var/log/*patch*
ls -la /var/log/*cron*
Troubleshooting Common Issues
