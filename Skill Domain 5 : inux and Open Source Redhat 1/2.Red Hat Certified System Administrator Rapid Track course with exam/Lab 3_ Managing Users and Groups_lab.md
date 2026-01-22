Lab 3: Managing Users and Groups
Objectives
By the end of this lab, students will be able to:

• Create new user accounts using the useradd command with various options • Set and modify user passwords using the passwd command • Modify existing user account details using the usermod command • Create and manage groups using groupadd and groupmod commands • Add users to groups and manage group memberships • Delete users and groups safely using userdel and groupdel commands • Understand the structure of /etc/passwd, /etc/group, and /etc/shadow files • Apply proper security practices when managing user accounts

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Familiarity with file permissions and ownership concepts • Knowledge of basic Linux file system structure • Understanding of what users and groups are in Linux systems • Access to a terminal with root or sudo privileges

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machine or install any software.

Your lab environment includes: • CentOS/RHEL-based Linux system • Root access via sudo • Pre-installed user management utilities • Terminal access

Task 1: Create User Accounts with useradd
Subtask 1.1: Understanding User Account Basics
Before creating users, let's examine the current user database:

# View existing users
cat /etc/passwd | tail -5

# Check current user
whoami

# Switch to root user (if not already)
sudo su -
Subtask 1.2: Create Basic User Accounts
Create your first user account with default settings:

# Create a basic user account
useradd john

# Verify the user was created
grep john /etc/passwd

# Check the user's home directory
ls -la /home/
Subtask 1.3: Create Users with Custom Options
Create users with specific configurations:

# Create user with custom home directory
useradd -d /home/custom_jane jane

# Create user with specific shell
useradd -s /bin/bash mike

# Create user with comment (full name)
useradd -c "Sarah Johnson" sarah

# Create user with specific UID
useradd -u 1500 tom

# Create user with multiple options
useradd -c "Alice Smith" -d /home/alice_home -s /bin/bash -u 1501 alice
Subtask 1.4: Verify User Creation
Check that all users were created correctly:

# View all newly created users
grep -E "john|jane|mike|sarah|tom|alice" /etc/passwd

# Check home directories
ls -la /home/

# View user IDs
id john
id alice
Task 2: Set Passwords and Modify User Details
Subtask 2.1: Set User Passwords
Set passwords for the newly created users:

# Set password for john
passwd john
# Enter password when prompted (e.g., "SecurePass123!")

# Set password for jane
passwd jane
# Enter password when prompted

# Set password for mike
passwd mike
# Enter password when prompted

# Set password for sarah
passwd sarah
# Enter password when prompted
Subtask 2.2: Modify User Account Details
Use usermod to change user account properties:

# Change user's full name (comment)
usermod -c "John Doe - Developer" john

# Change user's home directory
usermod -d /home/john_new john

# Change user's login shell
usermod -s /bin/zsh sarah

# Change user's UID
usermod -u 1502 mike

# Lock a user account
usermod -L tom

# Unlock a user account
usermod -U tom
Subtask 2.3: Verify User Modifications
Check that modifications were applied:

# View updated user information
grep -E "john|sarah|mike|tom" /etc/passwd

# Check password status
passwd -S john
passwd -S tom

# Test user login (open new terminal)
su - john
# Enter password and verify login works
exit
Task 3: Create and Manage Groups
Subtask 3.1: Create New Groups
Create various groups for organizing users:

# Create basic groups
groupadd developers
groupadd testers
groupadd managers

# Create group with specific GID
groupadd -g 2000 admins

# Create system group
groupadd -r sysops
Subtask 3.2: Verify Group Creation
Check that groups were created successfully:

# View newly created groups
grep -E "developers|testers|managers|admins|sysops" /etc/group

# Check group IDs
getent group developers
getent group admins
Subtask 3.3: Add Users to Groups
Assign users to appropriate groups:

# Add user to primary group
usermod -g developers john

# Add user to secondary groups
usermod -G testers,managers jane

# Add user to multiple groups (append mode)
usermod -a -G developers,admins mike

# Add user to group using gpasswd
gpasswd -a sarah developers

# Add multiple users to a group
gpasswd -M alice,tom testers
Subtask 3.4: Verify Group Memberships
Confirm users are in correct groups:

# Check user's group memberships
groups john
groups jane
groups mike

# View group members
getent group developers
getent group testers
getent group managers

# Check user's detailed group information
id john
id jane
Subtask 3.5: Modify Group Properties
Change group settings:

# Change group name
groupmod -n development developers

# Change group GID
groupmod -g 2001 admins

# Verify changes
getent group development
getent group admins
Task 4: Delete Users and Groups Securely
Subtask 4.1: Remove Users from Groups
Before deleting users, remove them from groups:

# Remove user from specific group
gpasswd -d tom testers

# Remove user from all secondary groups
usermod -G "" alice

# Verify removal
groups tom
groups alice
Subtask 4.2: Delete User Accounts Safely
Remove user accounts with different options:

# Delete user but keep home directory
userdel tom

# Delete user and remove home directory
userdel -r alice

# Force delete user (even if logged in)
userdel -f mike

# Verify users are deleted
grep -E "tom|alice|mike" /etc/passwd
ls -la /home/
Subtask 4.3: Delete Groups Safely
Remove groups that are no longer needed:

# Check if group has members before deletion
getent group testers

# Delete empty group
groupdel testers

# Try to delete group with members (will fail)
groupdel development

# Remove users from group first, then delete
gpasswd -d john development
gpasswd -d sarah development
groupdel development

# Verify group deletion
getent group testers
getent group development
Subtask 4.4: Clean Up Remaining Test Accounts
Remove remaining test accounts and groups:

# Remove remaining users
userdel -r john
userdel -r jane
userdel -r sarah

# Remove remaining groups
groupdel managers
groupdel admins
groupdel sysops

# Verify cleanup
grep -E "john|jane|sarah|tom|alice|mike" /etc/passwd
grep -E "developers|testers|managers|admins|sysops" /etc/group
Advanced User Management Concepts
Understanding Key Files
Important system files for user management:

# View password file structure
head -5 /etc/passwd
# Format: username:x:UID:GID:comment:home:shell

# View group file structure
head -5 /etc/group
# Format: groupname:x:GID:members

# View shadow file (password hashes)
sudo head -5 /etc/shadow
# Format: username:password_hash:last_change:min:max:warn:inactive:expire
User Account Security Best Practices
# Set password aging policies
chage -M 90 username    # Maximum password age
chage -m 7 username     # Minimum password age
chage -W 7 username     # Warning days before expiration

# View password aging information
chage -l username

# Set account expiration date
chage -E 2024-12-31 username

# Disable account without deleting
usermod -L -e 1 username
Troubleshooting Common Issues
Issue 1: User Already Exists Error
# Error: useradd: user 'username' already exists
# Solution: Check if user exists first
getent passwd username
# If exists, use usermod instead of useradd
Issue 2: Permission Denied
# Error: Permission denied when creating users
# Solution: Ensure you have root privileges
sudo su -
# Or use sudo with each command
sudo useradd username
Issue 3: Group Deletion Fails
# Error: groupdel: cannot remove the primary group of user 'username'
# Solution: Change user's primary group first
usermod -g newgroup username
# Then delete the old group
groupdel oldgroup
Issue 4: Home Directory Issues
# If home directory wasn't created
# Create it manually and set ownership
mkdir /home/username
chown username:username /home/username
chmod 755 /home/username

# Copy default files
cp -r /etc/skel/. /home/username/
chown -R username:username /home/username
Verification Commands Summary
Use these commands to verify your work:

# List all users
cut -d: -f1 /etc/passwd | sort

# List all groups
cut -d: -f1 /etc/group | sort

# Check user details
id username
groups username
finger username

# Check group members
getent group groupname

# Verify password settings
passwd -S username
chage -l username
Conclusion
In this lab, you have successfully learned how to manage users and groups in Linux systems. You accomplished the following key tasks:

User Management Skills Gained: • Created user accounts with various options using useradd • Set and managed user passwords with passwd • Modified user account properties using usermod • Understood the structure of user-related system files

Group Management Skills Gained: • Created and configured groups using groupadd • Added users to groups and managed memberships • Modified group properties with groupmod • Safely removed groups using groupdel

Security Best Practices Learned: • Proper user account deletion procedures • Understanding of password aging and account expiration • Safe group management to avoid system issues • Verification techniques to ensure changes are applied correctly

Why This Matters: User and group management is fundamental to Linux system administration and is essential for the Red Hat Certified System Administrator certification. These skills enable you to: • Maintain system security through proper access control • Organize users efficiently in enterprise environments • Implement the principle of least privilege • Manage multi-user systems effectively

The commands and concepts you've practiced in this lab form the foundation for more advanced topics like file permissions, access control lists, and system security policies. These skills are directly applicable in real-world scenarios where you'll need to manage user accounts, control access to resources, and maintain system security in production environments.
