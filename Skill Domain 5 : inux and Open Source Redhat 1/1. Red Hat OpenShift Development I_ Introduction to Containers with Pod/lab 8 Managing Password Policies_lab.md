Lab 8: Managing Password Policies
Objectives
To enforce password policies on Linux systems to ensure secure access
To configure password expiration and complexity requirements
To set password aging and enforce policies via configuration files
To test password policies with different users
Prerequisites
A Linux system (preferably RHEL/CentOS 8+ or Fedora)
Root or sudo privileges
Basic knowledge of Linux command line
passwd and chage utilities installed (default on most systems)
Lab Setup
Ensure you have a working Linux installation
Create two test users for policy testing:
sudo useradd testuser1
sudo useradd testuser2
Task 1: Configure Password Expiration and Complexity Requirements
Subtask 1.1: Install Required Packages
sudo dnf install libpwquality -y
Explanation:
libpwquality provides password quality checking and generation utilities.

Subtask 1.2: Configure Password Complexity
Edit the password quality configuration file:

sudo nano /etc/security/pwquality.conf
Add/modify these parameters:

minlen = 12
minclass = 4
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
Parameters Explanation:

minlen: Minimum password length
minclass: Minimum number of character classes (upper, lower, digit, special)
dcredit/ucredit/lcredit/ocredit: Minimum requirements for digits, uppercase, lowercase, and other characters
Subtask 1.3: Verify Configuration
Test password complexity:

echo "Weakpass1" | sudo pwscore
echo "StrongPass123!" | sudo pwscore
Expected Outcome:
The first command should return a low score (fail), while the second should pass.

Task 2: Set Password Aging and Enforce Policies
Subtask 2.1: Configure Global Password Aging
Edit the login definitions file:

sudo nano /etc/login.defs
Modify these parameters:

PASS_MAX_DAYS 90
PASS_MIN_DAYS 7
PASS_WARN_AGE 14
PASS_MIN_LEN 12
Parameters Explanation:

PASS_MAX_DAYS: Maximum password validity
PASS_MIN_DAYS: Minimum days before password change
PASS_WARN_AGE: Warning period before expiration
Subtask 2.2: Apply Policies to Existing Users
For all existing users, run:

sudo chage -M 90 -m 7 -W 14 testuser1
sudo chage -M 90 -m 7 -W 14 testuser2
Verify settings:

sudo chage -l testuser1
Subtask 2.3: Lock Inactive Accounts
Set account locking after 30 days of inactivity:

sudo useradd -D -f 30
Task 3: Test Password Policies
Subtask 3.1: Test Password Complexity
Attempt to set weak passwords:

sudo passwd testuser1
# Try "password123" (should fail)
# Then try "SecurePass123!" (should succeed)
Subtask 3.2: Test Password Aging
Check expiration dates:

sudo chage -l testuser1
Force password change:

sudo chage -d 0 testuser1
Expected Outcome:
User will be forced to change password at next login.

Subtask 3.3: Test Account Locking
Simulate inactive account:

sudo chage -I 30 -E $(date -d "+30 days" +%Y-%m-%d) testuser2
Verify:

sudo chage -l testuser2
Troubleshooting Tips
If password policies aren't applying:
Check /etc/pam.d/system-auth for pam_pwquality.so inclusion
Verify SELinux` context if policies aren't enforced
For account locking issues:
Check /var/log/secure for authentication logs
Password complexity not working:
Ensure libpwquality is properly installed
Check /etc/security/pwquality.conf syntax
Conclusion
In this lab, you have:

Configured password complexity requirements using libpwquality
Set password aging policies through /etc/login.defs and chage
Enforced account security with inactivity locking
Tested policies with different user scenarios
These measures significantly improve system security by enforcing strong password practices and regular credential rotation.

Cleanup (Optional)
To remove test users:

sudo userdel -r testuser1
sudo userdel -r testuser2
