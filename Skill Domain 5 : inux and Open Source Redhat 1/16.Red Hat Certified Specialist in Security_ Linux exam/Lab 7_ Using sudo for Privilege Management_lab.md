Lab 7: Using sudo for Privilege Management
Objectives
By the end of this lab, students will be able to:

Configure the sudoers file to implement least privilege access principles
Create and manage sudo rules for different user groups and scenarios
Test and validate sudo policies for various users and commands
Enable and analyze sudo logging for security auditing purposes
Troubleshoot common sudo configuration issues
Understand the security implications of privilege escalation
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Knowledge of user and group management in Linux
Familiarity with file permissions and ownership concepts
Understanding of text editors like nano or vim
Basic knowledge of system administration concepts
Lab Environment
Al Nafi Cloud Machines: This lab uses Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS system
Multiple user accounts for testing
Pre-installed sudo package
Root access for initial configuration
Task 1: Configure sudoers File for Least Privilege Access
Subtask 1.1: Understanding the Current sudo Configuration
First, let's examine the current sudo configuration and understand the default setup.

Check current sudo version and status:
sudo --version
View the main sudoers file:
sudo cat /etc/sudoers
Check for additional sudoers files:
ls -la /etc/sudoers.d/
Verify your current user's sudo privileges:
sudo -l
Subtask 1.2: Creating Test Users and Groups
Before configuring sudo rules, let's create test users and groups to demonstrate different privilege levels.

Create test groups:
sudo groupadd developers
sudo groupadd operators
sudo groupadd auditors
Create test users:
sudo useradd -m -s /bin/bash alice
sudo useradd -m -s /bin/bash bob
sudo useradd -m -s /bin/bash charlie
sudo useradd -m -s /bin/bash diana
Set passwords for test users:
echo "alice:password123" | sudo chpasswd
echo "bob:password123" | sudo chpasswd
echo "charlie:password123" | sudo chpasswd
echo "diana:password123" | sudo chpasswd
Add users to appropriate groups:
sudo usermod -a -G developers alice
sudo usermod -a -G developers bob
sudo usermod -a -G operators charlie
sudo usermod -a -G auditors diana
Subtask 1.3: Configuring Custom sudo Rules
Now we'll create custom sudo rules following the principle of least privilege.

Always use visudo to edit sudoers files (this prevents syntax errors):
sudo visudo -f /etc/sudoers.d/custom-rules
Add the following configuration to the file:
# Custom sudo rules for different user groups

# Developers group - can restart web services and view logs
%developers ALL=(ALL) /bin/systemctl restart httpd, /bin/systemctl restart nginx, /bin/systemctl status httpd, /bin/systemctl status nginx, /usr/bin/tail /var/log/httpd/*, /usr/bin/tail /var/log/nginx/*

# Operators group - can manage system services and view system status
%operators ALL=(ALL) /bin/systemctl start *, /bin/systemctl stop *, /bin/systemctl restart *, /bin/systemctl status *, /usr/bin/top, /usr/bin/htop, /bin/ps aux

# Auditors group - read-only access to logs and system information
%auditors ALL=(ALL) NOPASSWD: /usr/bin/tail /var/log/*, /bin/cat /var/log/*, /usr/bin/less /var/log/*, /bin/ps aux, /usr/bin/who, /usr/bin/last

# Specific user rules
alice ALL=(ALL) /usr/bin/vim /etc/hosts
bob ALL=(ALL) NOPASSWD: /bin/ls /root/

# Alias definitions for common command groups
Cmnd_Alias NETWORKING = /sbin/route, /sbin/ifconfig, /bin/ping, /sbin/dhclient, /usr/bin/net, /sbin/iptables, /usr/bin/rfcomm, /usr/bin/wvdial, /sbin/iwconfig, /sbin/mii-tool

# Network administrators
User_Alias NETADMINS = alice, bob
NETADMINS ALL = NETWORKING

# Prevent certain dangerous commands
%developers ALL = !/bin/su, !/usr/bin/passwd root, !/usr/sbin/visudo
Save and exit the editor (Ctrl+X, then Y, then Enter if using nano)

Verify the syntax of your sudoers file:

sudo visudo -c -f /etc/sudoers.d/custom-rules
Subtask 1.4: Creating Role-Based Access Control
Let's create more sophisticated rules based on specific roles.

Create a new sudoers file for role-based access:
sudo visudo -f /etc/sudoers.d/role-based-access
Add role-based configurations:
# Role-based sudo access control

# Database Administrator Role
Cmnd_Alias DB_COMMANDS = /usr/bin/mysql, /usr/bin/mysqldump, /bin/systemctl * mysql*, /bin/systemctl * mariadb*

# Web Administrator Role  
Cmnd_Alias WEB_COMMANDS = /bin/systemctl * httpd*, /bin/systemctl * nginx*, /bin/systemctl * apache2*, /usr/bin/tail /var/log/httpd/*, /usr/bin/tail /var/log/nginx/*, /usr/bin/tail /var/log/apache2/*

# System Monitor Role
Cmnd_Alias MONITOR_COMMANDS = /usr/bin/top, /usr/bin/htop, /bin/ps, /usr/bin/netstat, /bin/ss, /usr/bin/iotop, /usr/bin/iostat

# File System Administrator Role
Cmnd_Alias FS_COMMANDS = /bin/mount, /bin/umount, /sbin/fsck, /sbin/fdisk -l, /bin/df, /bin/du

# Assign roles to users
alice ALL = DB_COMMANDS
bob ALL = WEB_COMMANDS  
charlie ALL = MONITOR_COMMANDS, FS_COMMANDS
diana ALL = MONITOR_COMMANDS

# Time-based restrictions (optional - requires additional configuration)
# Defaults:alice timestamp_timeout=30
# Defaults:bob timestamp_timeout=60
Task 2: Test sudo Policies for Various Users
Subtask 2.1: Testing Basic User Privileges
Now let's test our configured sudo policies by switching between users and attempting various commands.

Test alice's privileges (developer with database admin role):
# Switch to alice
sudo su - alice

# Test allowed commands
sudo systemctl status httpd
sudo mysql --version
sudo tail /var/log/messages

# Test denied commands (should fail)
sudo passwd root
sudo su -

# Check what alice can do
sudo -l

# Return to original user
exit
Test bob's privileges (developer with web admin role):
# Switch to bob
sudo su - bob

# Test allowed commands
sudo systemctl status nginx
sudo ls /root/  # Should work without password
sudo tail /var/log/httpd/access_log

# Test denied commands
sudo systemctl start mysql
sudo passwd charlie

# Check bob's privileges
sudo -l

# Return to original user
exit
Test charlie's privileges (operator with system monitoring):
# Switch to charlie
sudo su - charlie

# Test allowed commands
sudo systemctl restart sshd
sudo top
sudo mount
sudo df -h

# Test denied commands
sudo tail /var/log/secure

# Check charlie's privileges
sudo -l

# Return to original user
exit
Test diana's privileges (auditor with read-only access):
# Switch to diana
sudo su - diana

# Test allowed commands (no password required)
sudo tail /var/log/messages
sudo ps aux
sudo who
sudo last

# Test denied commands
sudo systemctl restart httpd
sudo mount /dev/sdb1 /mnt

# Check diana's privileges
sudo -l

# Return to original user
exit
Subtask 2.2: Testing Command Restrictions and Aliases
Let's test the command aliases and restrictions we configured.

Test networking commands for alice:
sudo su - alice

# These should work (alice is in NETADMINS)
sudo ping -c 3 google.com
sudo ifconfig
sudo route -n

# Return to original user
exit
Test restricted commands:
sudo su - bob

# This should be denied
sudo su -
# Expected output: Sorry, user bob is not allowed to execute '/bin/su -' as root

# This should also be denied
sudo passwd root
# Expected output: Sorry, user bob is not allowed to execute '/usr/bin/passwd root' as root

exit
Subtask 2.3: Testing Privilege Escalation Scenarios
Let's test various privilege escalation scenarios to ensure our security measures work.

Create a test script to verify command execution:
cat > /tmp/test_sudo.sh << 'EOF'
#!/bin/bash

echo "=== Testing sudo privileges for current user ==="
echo "Current user: $(whoami)"
echo "Groups: $(groups)"
echo ""

echo "=== Available sudo commands ==="
sudo -l
echo ""

echo "=== Testing specific commands ==="
echo "1. Testing systemctl status:"
sudo systemctl status sshd 2>&1 | head -5

echo ""
echo "2. Testing log access:"
sudo tail -n 5 /var/log/messages 2>&1 | head -5

echo ""
echo "3. Testing restricted command (should fail):"
sudo passwd root 2>&1 | head -2
EOF

chmod +x /tmp/test_sudo.sh
Run the test script for each user:
# Test as alice
sudo su - alice -c "/tmp/test_sudo.sh"

echo "================================"

# Test as bob  
sudo su - bob -c "/tmp/test_sudo.sh"

echo "================================"

# Test as charlie
sudo su - charlie -c "/tmp/test_sudo.sh"

echo "================================"

# Test as diana
sudo su - diana -c "/tmp/test_sudo.sh"
Task 3: Use sudo Logging to Audit Usage
Subtask 3.1: Enable Comprehensive sudo Logging
By default, sudo logs to the system log, but we can enhance logging for better auditing.

Configure enhanced sudo logging:
sudo visudo -f /etc/sudoers.d/logging-config
Add logging configuration:
# Enhanced sudo logging configuration

# Log all sudo commands with detailed information
Defaults log_host, log_year, logfile="/var/log/sudo.log"

# Log input and output for specific users (security-sensitive)
Defaults:alice log_input, log_output
Defaults:bob log_input, log_output

# Set log format for better readability
Defaults loglinelen=0

# Enable syslog logging with specific facility
Defaults syslog=authpriv

# Log failed attempts
Defaults log_allowed, log_denied

# Set custom log format
Defaults logformat="%h : %u : %t : %c"
Create the sudo log file with proper permissions:
sudo touch /var/log/sudo.log
sudo chmod 640 /var/log/sudo.log
sudo chown root:adm /var/log/sudo.log
Configure rsyslog for sudo logging (if not already configured):
echo "# sudo logging" | sudo tee -a /etc/rsyslog.conf
echo "authpriv.*    /var/log/sudo.log" | sudo tee -a /etc/rsyslog.conf
sudo systemctl restart rsyslog
Subtask 3.2: Generate Test Log Entries
Let's generate some sudo activity to populate our logs.

Create a script to generate test activities:
cat > /tmp/generate_sudo_activity.sh << 'EOF'
#!/bin/bash

users=("alice" "bob" "charlie" "diana")

echo "Generating sudo activity for auditing..."

for user in "${users[@]}"; do
    echo "=== Testing as $user ==="
    
    # Successful commands
    sudo su - $user -c "sudo -l > /dev/null 2>&1"
    sudo su - $user -c "sudo ps aux > /dev/null 2>&1"
    
    # Failed commands (intentional)
    sudo su - $user -c "sudo passwd root 2>/dev/null" || true
    sudo su - $user -c "sudo su - 2>/dev/null" || true
    
    sleep 2
done

echo "Activity generation complete."
EOF

chmod +x /tmp/generate_sudo_activity.sh
Run the activity generator:
/tmp/generate_sudo_activity.sh
Subtask 3.3: Analyzing sudo Logs
Now let's examine and analyze the sudo logs we've generated.

View the main sudo log:
sudo tail -20 /var/log/sudo.log
Check system logs for sudo entries:
sudo grep sudo /var/log/secure | tail -10
Create a log analysis script:
cat > /tmp/analyze_sudo_logs.sh << 'EOF'
#!/bin/bash

SUDO_LOG="/var/log/sudo.log"
SECURE_LOG="/var/log/secure"

echo "=== SUDO LOG ANALYSIS REPORT ==="
echo "Generated on: $(date)"
echo ""

if [ -f "$SUDO_LOG" ]; then
    echo "=== Recent sudo commands from $SUDO_LOG ==="
    tail -20 "$SUDO_LOG"
    echo ""
    
    echo "=== Command frequency analysis ==="
    if [ -s "$SUDO_LOG" ]; then
        awk '{print $NF}' "$SUDO_LOG" | sort | uniq -c | sort -nr | head -10
    else
        echo "No entries in sudo.log yet"
    fi
    echo ""
fi

echo "=== Recent sudo activity from system logs ==="
grep "sudo:" "$SECURE_LOG" | tail -15
echo ""

echo "=== Failed sudo attempts ==="
grep -i "failed\|denied\|incorrect" "$SECURE_LOG" | grep sudo | tail -10
echo ""

echo "=== Unique users using sudo ==="
grep "sudo:" "$SECURE_LOG" | awk '{print $5}' | sort | uniq -c
echo ""

echo "=== Most common sudo commands ==="
grep "COMMAND=" "$SECURE_LOG" | sed 's/.*COMMAND=//' | sort | uniq -c | sort -nr | head -10
EOF

chmod +x /tmp/analyze_sudo_logs.sh
Run the log analysis:
/tmp/analyze_sudo_logs.sh
Subtask 3.4: Setting up Log Rotation and Monitoring
To maintain logs effectively, let's set up log rotation and basic monitoring.

Create a logrotate configuration for sudo logs:
sudo tee /etc/logrotate.d/sudo << 'EOF'
/var/log/sudo.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 root adm
    postrotate
        /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
    endscript
}
EOF
Test the logrotate configuration:
sudo logrotate -d /etc/logrotate.d/sudo
Create a simple monitoring script:
cat > /tmp/sudo_monitor.sh << 'EOF'
#!/bin/bash

# Simple sudo monitoring script
LOG_FILE="/var/log/secure"
ALERT_FILE="/tmp/sudo_alerts.log"

# Monitor for suspicious sudo activity
echo "=== Sudo Security Monitor ===" 
echo "Timestamp: $(date)"

# Check for failed sudo attempts in the last hour
FAILED_ATTEMPTS=$(grep "$(date '+%b %d %H')" "$LOG_FILE" | grep -c "sudo.*FAILED\|sudo.*incorrect password")

if [ "$FAILED_ATTEMPTS" -gt 5 ]; then
    echo "ALERT: $FAILED_ATTEMPTS failed sudo attempts in the last hour" | tee -a "$ALERT_FILE"
fi

# Check for root password changes
ROOT_PASSWD_CHANGES=$(grep "$(date '+%b %d')" "$LOG_FILE" | grep -c "passwd.*root")
if [ "$ROOT_PASSWD_CHANGES" -gt 0 ]; then
    echo "ALERT: Root password change attempts detected today" | tee -a "$ALERT_FILE"
fi

# Check for su command usage
SU_USAGE=$(grep "$(date '+%b %d')" "$LOG_FILE" | grep -c "sudo.*COMMAND=/bin/su")
if [ "$SU_USAGE" -gt 0 ]; then
    echo "INFO: su command used via sudo $SU_USAGE times today" | tee -a "$ALERT_FILE"
fi

echo "Monitoring complete."
EOF

chmod +x /tmp/sudo_monitor.sh
Run the monitoring script:
/tmp/sudo_monitor.sh
Advanced Configuration and Troubleshooting
Common Issues and Solutions
Syntax errors in sudoers file:
# Always test syntax before saving
sudo visudo -c

# If locked out, boot into single-user mode or use:
pkexec visudo
User not in sudoers file error:
# Add user to sudo group (Ubuntu/Debian)
sudo usermod -a -G sudo username

# Add user to wheel group (RHEL/CentOS)
sudo usermod -a -G wheel username
Password timeout issues:
# Adjust timeout in sudoers
Defaults timestamp_timeout=30
Security Best Practices
Regular audit of sudo privileges:
# Create audit script
cat > /tmp/sudo_audit.sh << 'EOF'
#!/bin/bash

echo "=== SUDO PRIVILEGE AUDIT ==="
echo "Date: $(date)"
echo ""

echo "=== Users with sudo access ==="
getent group sudo wheel | cut -d: -f4 | tr ',' '\n' | sort

echo ""
echo "=== Custom sudoers files ==="
ls -la /etc/sudoers.d/

echo ""
echo "=== Recent sudo usage summary ==="
grep "sudo:" /var/log/secure | tail -20 | awk '{print $1, $2, $3, $5, $6}' | sort | uniq -c
EOF

chmod +x /tmp/sudo_audit.sh
/tmp/sudo_audit.sh
Conclusion
In this comprehensive lab, you have successfully:

Configured the sudoers file following the principle of least privilege, creating role-based access controls that limit users to only the commands they need for their specific responsibilities.

Implemented and tested sudo policies for various user types including developers, operators, and auditors, ensuring that each group has appropriate access levels while maintaining security boundaries.

Enabled comprehensive sudo logging and created monitoring tools to track and audit sudo usage, which is crucial for security compliance and incident investigation.

Key Takeaways
Least Privilege Principle: Always grant users the minimum privileges necessary to perform their job functions
Regular Auditing: Continuously monitor and review sudo usage to detect potential security issues
Proper Configuration: Use visudo to prevent syntax errors that could lock you out of the system
Logging is Critical: Comprehensive logging helps with compliance, troubleshooting, and security incident response
Why This Matters
Proper sudo configuration is essential for:

Security: Preventing unauthorized privilege escalation
Compliance: Meeting regulatory requirements for access control
Auditing: Maintaining detailed records of administrative actions
Operational Safety: Reducing the risk of accidental system damage
This lab has provided you with practical skills that are directly applicable to real-world Linux system administration and are essential for the Red Hat Certified Specialist in Security: Linux exam. The techniques you've learned will help you implement robust privilege management in production environments while maintaining security and operational efficiency.
