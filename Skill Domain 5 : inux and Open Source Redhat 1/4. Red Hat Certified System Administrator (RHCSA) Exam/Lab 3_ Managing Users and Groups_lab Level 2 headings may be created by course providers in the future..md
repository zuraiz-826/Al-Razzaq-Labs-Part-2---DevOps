Lab 3: Managing Users and Groups
Objectives
By the end of this lab, you will be able to:

• Create new user accounts using the useradd command • Modify existing user accounts with the usermod command • Create and manage groups using the groupadd command • Assign users to groups and manage group memberships • Change user passwords securely using the passwd command • Understand the relationship between users, groups, and system security • Navigate user and group configuration files

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Linux command line interface • Familiarity with navigating directories using cd, ls, and pwd commands • Knowledge of file permissions concepts • Access to a Linux system with root or sudo privileges • Understanding of what users and groups are in a Linux environment

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machine or install any software.

Your lab environment includes: • CentOS/RHEL-based Linux system • Root access via sudo • All necessary system utilities pre-installed • Clean environment ready for user and group management

Task 1: Create a User with useradd
Understanding User Creation
The useradd command is the primary tool for creating new user accounts in Linux systems. When you create a user, the system automatically: • Creates a home directory • Assigns a unique User ID (UID) • Sets up default shell and group memberships • Copies skeleton files to the user's home directory

Subtask 1.1: Create a Basic User Account
Open your terminal and ensure you have administrative privileges:
sudo -i
Create a new user named "john":
useradd john
Verify the user was created by checking the /etc/passwd file:
grep john /etc/passwd
Expected Output:

john:x:1001:1001::/home/john:/bin/bash
Subtask 1.2: Create a User with Custom Options
Create a user with specific options:
useradd -c "Jane Smith, Marketing Department" -s /bin/bash -m -d /home/jsmith jsmith
Command Breakdown: • -c: Adds a comment (full name and department) • -s: Specifies the login shell • -m: Creates the home directory • -d: Specifies the home directory path

Verify the user creation:
grep jsmith /etc/passwd
ls -la /home/jsmith
Subtask 1.3: Create a System User
Create a system user for a service:
useradd -r -s /sbin/nologin -c "Web Server User" webuser
Command Breakdown: • -r: Creates a system user (UID below 1000) • -s /sbin/nologin: Prevents interactive login • This type of user is typically used for running services

Verify the system user:
grep webuser /etc/passwd
id webuser
Task 2: Modify Users with usermod
Understanding User Modification
The usermod command allows you to modify existing user accounts without deleting and recreating them. This is essential for maintaining user data while updating account properties.

Subtask 2.1: Change User's Home Directory
Create a new directory for john:
mkdir /home/john_new
Change john's home directory:
usermod -d /home/john_new -m john
Command Breakdown: • -d: Specifies new home directory • -m: Moves contents from old to new home directory

Verify the change:
grep john /etc/passwd
ls -la /home/john_new
Subtask 2.2: Change User's Login Shell
Change jsmith's shell to zsh (if available):
usermod -s /bin/zsh jsmith
If zsh is not available, install it first:
# On RHEL/CentOS
yum install -y zsh
# Then change the shell
usermod -s /bin/zsh jsmith
Verify the shell change:
grep jsmith /etc/passwd
Subtask 2.3: Lock and Unlock User Accounts
Lock john's account:
usermod -L john
Verify the account is locked:
grep john /etc/shadow
Note: You'll see an exclamation mark (!) in the password field indicating the account is locked.

Unlock the account:
usermod -U john
Task 3: Create Groups and Assign Users
Understanding Groups
Groups in Linux provide a way to organize users and manage permissions collectively. Every user belongs to at least one group (their primary group), and can be members of multiple secondary groups.

Subtask 3.1: Create Groups with groupadd
Create a marketing group:
groupadd marketing
Create a developers group with specific GID:
groupadd -g 2000 developers
Create a system group:
groupadd -r services
Verify group creation:
grep -E "(marketing|developers|services)" /etc/group
Subtask 3.2: Assign Users to Groups
Add jsmith to the marketing group as primary group:
usermod -g marketing jsmith
Add john to multiple groups:
usermod -G developers,marketing john
Important: The -G option sets secondary groups. Use -a -G to append to existing groups without removing current memberships.

Add john to services group without removing other memberships:
usermod -a -G services john
Verify group memberships:
groups john
groups jsmith
id john
id jsmith
Subtask 3.3: Create Users and Assign to Groups During Creation
Create a user and assign to a group simultaneously:
useradd -g developers -G marketing -c "Bob Developer" -m bdev
Verify the user and group assignment:
id bdev
groups bdev
Task 4: Change User Passwords using passwd
Understanding Password Management
The passwd command is used to change user passwords. As an administrator, you can change any user's password, while regular users can only change their own passwords.

Subtask 4.1: Set Passwords for New Users
Set password for john:
passwd john
You will be prompted to enter and confirm the password. Choose a strong password.

Set password for jsmith:
passwd jsmith
Set password for bdev:
passwd bdev
Subtask 4.2: Configure Password Policies
Set password expiration for john (90 days):
chage -M 90 john
Set minimum password age (7 days before change allowed):
chage -m 7 john
Set warning period (7 days before expiration):
chage -W 7 john
View password aging information:
chage -l john
Subtask 4.3: Force Password Change on Next Login
Force jsmith to change password on next login:
chage -d 0 jsmith
Verify the setting:
chage -l jsmith
Verification and Testing
Test User Accounts and Group Memberships
Display all created users:
grep -E "(john|jsmith|bdev|webuser)" /etc/passwd
Display all created groups:
grep -E "(marketing|developers|services)" /etc/group
Test user switching (if you have set passwords):
su - john
whoami
groups
exit
Check user home directories:
ls -la /home/
Verify File Permissions and Ownership
Create test files as different users:
su - john -c "touch /home/john_new/john_file.txt"
su - jsmith -c "touch /home/jsmith/jsmith_file.txt"
Check file ownership:
ls -la /home/john_new/john_file.txt
ls -la /home/jsmith/jsmith_file.txt
Advanced Configuration
Working with Group Files and Directories
Create a shared directory for the marketing group:
mkdir /shared/marketing
chgrp marketing /shared/marketing
chmod 770 /shared/marketing
Set the sticky bit for group collaboration:
chmod g+s /shared/marketing
Test group access:
ls -la /shared/
Managing User Defaults
View default user creation settings:
cat /etc/default/useradd
View login definitions:
cat /etc/login.defs | grep -E "(UID_MIN|GID_MIN|PASS_MAX_DAYS)"
Troubleshooting Common Issues
Issue 1: User Already Exists
Problem: Getting "user already exists" error when creating users.

Solution:

# Check if user exists
id username
# If exists, either use a different name or remove the existing user
userdel username
Issue 2: Permission Denied
Problem: Cannot create users or modify accounts.

Solution:

# Ensure you have root privileges
sudo -i
# Or use sudo with each command
sudo useradd username
Issue 3: Home Directory Not Created
Problem: User created but no home directory exists.

Solution:

# Create home directory manually
mkdir /home/username
# Copy skeleton files
cp -r /etc/skel/. /home/username/
# Set ownership
chown -R username:username /home/username
Issue 4: Group Assignment Not Working
Problem: User not properly added to groups.

Solution:

# Check current group memberships
groups username
# Add to group properly
usermod -a -G groupname username
# Verify
id username
Security Best Practices
Password Security
Enforce strong password policies:
# Edit /etc/security/pwquality.conf for password complexity
# Set minimum length, character requirements, etc.
Regular password expiration:
# Set system-wide password aging in /etc/login.defs
# PASS_MAX_DAYS 90
# PASS_MIN_DAYS 7
# PASS_WARN_AGE 7
User Account Security
Disable unused accounts:
usermod -L username  # Lock account
usermod -s /sbin/nologin username  # Disable shell access
Monitor user activities:
last  # Show recent logins
who   # Show currently logged in users
w     # Show what users are doing
Lab Summary and Cleanup
Summary of Completed Tasks
In this lab, you have successfully:

• Created user accounts using useradd with various options and configurations • Modified existing users using usermod to change home directories, shells, and account status • Created and managed groups using groupadd and assigned users to multiple groups • Set and managed passwords using passwd and implemented password policies • Implemented security best practices for user and group management • Troubleshot common issues related to user and group administration

Cleanup (Optional)
If you want to clean up the lab environment:

Remove created users:
userdel -r john
userdel -r jsmith
userdel -r bdev
userdel webuser
Remove created groups:
groupdel marketing
groupdel developers
groupdel services
Remove shared directories:
rm -rf /shared
Conclusion
User and group management is a fundamental skill for Linux system administrators. These skills are essential for:

• System Security: Properly configured users and groups form the foundation of Linux security • Access Control: Groups enable efficient permission management for multiple users • Service Management: System users are crucial for running services securely • Compliance: Many organizations require specific user management practices • RHCSA Certification: These skills are directly tested in the Red Hat Certified System Administrator exam

The commands and concepts you've learned in this lab are used daily by system administrators worldwide. Understanding user and group management will help you secure systems, manage access permissions, and maintain organized multi-user environments.

Key Takeaways: • Always use strong passwords and implement password policies • Regularly review user accounts and remove unused ones • Use groups to simplify permission management • System users should have restricted shells for security • Document user and group purposes for future reference

Continue practicing these commands in different scenarios to build confidence and expertise in Linux user and group administration.
