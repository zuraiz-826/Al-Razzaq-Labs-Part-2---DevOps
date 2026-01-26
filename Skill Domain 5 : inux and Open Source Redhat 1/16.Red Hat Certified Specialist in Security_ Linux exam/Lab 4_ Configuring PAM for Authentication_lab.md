Lab 4: Configuring PAM for Authentication
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of Pluggable Authentication Modules (PAM)
Configure password aging policies using PAM modules
Implement account locking mechanisms for failed login attempts
Set up comprehensive login policies for enhanced security
Test and validate PAM configurations using system commands
Troubleshoot common PAM configuration issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and text editors
Knowledge of user account management concepts
Understanding of file permissions and system security basics
Experience with sudo privileges and root access
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
Pre-installed PAM modules and utilities
Text editors (vi/vim, nano)
All necessary system tools for testing
Task 1: Understanding and Configuring Password Aging
Subtask 1.1: Examine Current PAM Configuration
First, let's explore the existing PAM configuration to understand the current setup.

View the main PAM configuration directory:
ls -la /etc/pam.d/
Examine the system-auth configuration:
cat /etc/pam.d/system-auth
Check the password-auth configuration:
cat /etc/pam.d/password-auth
View current password policies:
cat /etc/login.defs | grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE"
Subtask 1.2: Configure Password Complexity Requirements
Install the required PAM module (if not already installed):
sudo yum install -y pam_pwquality
Edit the pwquality configuration file:
sudo vi /etc/security/pwquality.conf
Add or modify the following password complexity settings:
# Minimum password length
minlen = 8

# Require at least one digit
dcredit = -1

# Require at least one uppercase letter
ucredit = -1

# Require at least one lowercase letter
lcredit = -1

# Require at least one special character
ocredit = -1

# Maximum number of consecutive identical characters
maxrepeat = 2

# Minimum number of character classes
minclass = 3
Save and exit the file.
Subtask 1.3: Configure Password Aging Policies
Edit the login.defs file to set system-wide password aging:
sudo vi /etc/login.defs
Modify or add the following lines:
# Maximum number of days a password may be used
PASS_MAX_DAYS   90

# Minimum number of days allowed between password changes
PASS_MIN_DAYS   1

# Number of days warning given before a password expires
PASS_WARN_AGE   7

# Minimum acceptable password length
PASS_MIN_LEN    8
Save and exit the file.

Create a test user to verify password aging:

sudo useradd testuser1
sudo passwd testuser1
Apply password aging to the test user:
sudo chage -M 90 -m 1 -W 7 testuser1
Verify the password aging settings:
sudo chage -l testuser1
Task 2: Implementing Account Locking Mechanisms
Subtask 2.1: Configure Account Lockout for Failed Login Attempts
Edit the system-auth PAM configuration:
sudo vi /etc/pam.d/system-auth
Add the following line after the existing auth lines:
auth        required      pam_faillock.so preauth audit silent deny=3 unlock_time=600
auth        [default=die] pam_faillock.so authfail audit deny=3 unlock_time=600
Add the account line for faillock:
account     required      pam_faillock.so
Edit the password-auth PAM configuration:
sudo vi /etc/pam.d/password-auth
Add the same faillock configuration as above.
Subtask 2.2: Configure Advanced Account Locking Options
Create a faillock configuration file:
sudo vi /etc/security/faillock.conf
Add the following configuration:
# Directory where lock files will be kept
dir = /var/run/faillock

# Deny access if the number of consecutive authentication failures reaches this value
deny = 3

# The length of time in seconds during which no login attempts will be allowed after a lockout
unlock_time = 600

# The length of time in seconds during which the attempts to access will be recorded
fail_interval = 900

# If a user account is currently locked and this option is set, also root will be asked for authentication
even_deny_root

# Root account can become locked as well as regular accounts
root_unlock_time = 60
Save and exit the file.
Subtask 2.3: Test Account Locking
Create another test user:
sudo useradd testuser2
sudo passwd testuser2
Test the account locking by attempting failed logins:
# Switch to a different terminal or use su to test
su - testuser2
# Enter wrong password 3 times
Check the faillock status:
sudo faillock --user testuser2
Unlock the account manually:
sudo faillock --user testuser2 --reset
Task 3: Configuring Comprehensive Login Policies
Subtask 3.1: Implement Time-Based Access Controls
Edit the time.conf file:
sudo vi /etc/security/time.conf
Add time-based restrictions (example):
# Allow testuser1 to login only during business hours on weekdays
*;*;testuser1;MoTuWeThFr0800-1800

# Deny access to testuser2 during weekends
*;*;!testuser2;SaSu0000-2400
Enable the pam_time module in system-auth:
sudo vi /etc/pam.d/system-auth
Add the following line in the account section:
account    required     pam_time.so
Subtask 3.2: Configure User Access Limits
Edit the limits.conf file:
sudo vi /etc/security/limits.conf
Add resource limits for users:
# Limit maximum number of processes for testuser1
testuser1    soft    nproc    50
testuser1    hard    nproc    100

# Limit maximum number of open files
testuser1    soft    nofile   1024
testuser1    hard    nofile   2048

# Set memory limits (in KB)
testuser1    soft    as       102400
testuser1    hard    as       204800
Enable the pam_limits module:
sudo vi /etc/pam.d/system-auth
Add the following line in the session section:
session    required     pam_limits.so
Subtask 3.3: Implement Login Notification and Logging
Configure login notifications:
sudo vi /etc/pam.d/system-auth
Add the following line in the session section:
session    optional     pam_lastlog.so showfailed
Create a custom login banner:
sudo vi /etc/issue
Add a security warning message:
***************************************************************************
                    AUTHORIZED ACCESS ONLY
                    
This system is for authorized users only. All activities are monitored
and logged. Unauthorized access is strictly prohibited and will be
prosecuted to the full extent of the law.
***************************************************************************
Configure the banner in PAM:
sudo vi /etc/pam.d/login
Add the following line at the beginning:
auth       optional     pam_issue.so issue=/etc/issue
Task 4: Testing and Validation
Subtask 4.1: Test Password Policies with passwd Command
Test password complexity requirements:
sudo passwd testuser1
# Try entering passwords that don't meet complexity requirements
# Examples: "123456", "password", "abc"
Test with a compliant password:
# Enter a password like: "SecurePass123!"
Verify password change restrictions:
sudo su - testuser1
passwd
# Try to change password immediately (should be denied due to PASS_MIN_DAYS)
Subtask 4.2: Test Password Aging with chage Command
View current password aging information:
sudo chage -l testuser1
Set password to expire immediately:
sudo chage -d 0 testuser1
Test forced password change on next login:
su - testuser1
# User will be forced to change password
Set specific expiration date:
sudo chage -E 2024-12-31 testuser1
View updated aging information:
sudo chage -l testuser1
Subtask 4.3: Comprehensive Testing Scenarios
Test account lockout scenario:
# Create a script to test multiple failed logins
cat > test_lockout.sh << 'EOF'
#!/bin/bash
echo "Testing account lockout for testuser2"
for i in {1..4}; do
    echo "Attempt $i:"
    echo "wrongpassword" | su - testuser2 2>/dev/null
    sleep 2
done
echo "Checking lockout status:"
sudo faillock --user testuser2
EOF

chmod +x test_lockout.sh
./test_lockout.sh
Test time-based access (if configured):
# Check current time and test access during restricted hours
date
su - testuser1
Test resource limits:
sudo su - testuser1
ulimit -a
# Verify that limits match what was configured
Monitor authentication logs:
sudo tail -f /var/log/secure
# In another terminal, attempt various login scenarios
Troubleshooting Common Issues
Issue 1: PAM Configuration Syntax Errors
Problem: Authentication fails after PAM configuration changes.

Solution:

# Check PAM configuration syntax
sudo pam-config --verify

# Review system logs for PAM errors
sudo journalctl -u systemd-logind | grep pam

# Restore backup configuration if needed
sudo cp /etc/pam.d/system-auth.backup /etc/pam.d/system-auth
Issue 2: Account Lockout Not Working
Problem: Failed login attempts don't trigger account lockout.

Solution:

# Verify faillock module is properly configured
sudo cat /etc/pam.d/system-auth | grep faillock

# Check faillock directory permissions
ls -la /var/run/faillock

# Test faillock manually
sudo faillock --user testuser2 --reset
Issue 3: Password Complexity Not Enforced
Problem: Users can set weak passwords despite pwquality configuration.

Solution:

# Verify pwquality module is loaded
sudo cat /etc/pam.d/system-auth | grep pwquality

# Check pwquality configuration
sudo cat /etc/security/pwquality.conf

# Test password quality manually
echo "weakpass" | pwscore
Verification Commands
Use these commands to verify your PAM configuration:

# Check all PAM modules
sudo pam-config --list-modules

# Verify password aging for all users
sudo cat /etc/shadow | cut -d: -f1,5,6,7

# Check current faillock status for all users
sudo faillock

# View authentication logs
sudo grep "pam" /var/log/secure | tail -20

# Test PAM configuration
sudo pamtester system-auth testuser1 authenticate
Conclusion
In this lab, you have successfully:

Configured comprehensive password policies using PAM modules, including complexity requirements and aging policies that enhance system security
Implemented robust account locking mechanisms that automatically protect against brute-force attacks by locking accounts after failed login attempts
Set up advanced login policies including time-based access controls and resource limits that provide granular control over user access
Tested and validated configurations using system commands like passwd, chage, and faillock to ensure policies work as expected
Learned troubleshooting techniques for common PAM configuration issues
Why This Matters: PAM (Pluggable Authentication Modules) is a critical security component in Linux systems that provides flexible authentication mechanisms. The skills you've learned are essential for:

Enterprise Security: Organizations rely on strong authentication policies to protect sensitive data
Compliance Requirements: Many regulatory frameworks require specific password and access controls
System Administration: PAM configuration is a fundamental skill for Linux system administrators
Career Development: These skills are directly applicable to Red Hat Certified Specialist in Security: Linux certification and other security-focused roles
The hands-on experience gained in this lab provides practical knowledge that can be immediately applied in production environments to enhance system security and meet organizational security requirements.
