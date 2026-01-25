Lab 1: Review of RHCSA Core Concepts
Objectives
By the end of this lab, students will be able to:

Create and manage user accounts using useradd and passwd commands
Configure and manage system services using systemctl command
Set and modify file permissions using chmod command
Change file and directory ownership using chown command
Understand the relationship between users, services, and security in Linux systems
Apply RHCSA core concepts in practical scenarios
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line interface
Familiarity with terminal navigation commands (cd, ls, pwd)
Basic knowledge of text editors (nano or vi)
Understanding of Linux file system hierarchy
Access to a Linux system with root or sudo privileges
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment. No need to build your own virtual machine or install any software.

Your lab environment includes:

Red Hat Enterprise Linux 9 or CentOS Stream 9
Root access for administrative tasks
Pre-installed system tools and utilities
Network connectivity for package management
Task 1: User Management with useradd and passwd
Subtask 1.1: Creating Basic User Accounts
Objective: Learn to create user accounts with default settings.

Connect to your lab machine and open a terminal session.

Check current users on the system:

cat /etc/passwd | tail -5
Create a basic user account named student1:
sudo useradd student1
Verify the user was created:
id student1
Check the user's home directory:
ls -la /home/student1
Subtask 1.2: Setting User Passwords
Objective: Configure secure passwords for user accounts.

Set a password for the student1 user:
sudo passwd student1
When prompted, enter a secure password (minimum 8 characters)
Confirm the password when asked
Test the password by switching to the user:
su - student1
Return to your original user:
exit
Subtask 1.3: Creating Users with Custom Options
Objective: Create users with specific home directories, shells, and groups.

Create a user with custom home directory:
sudo useradd -d /home/custom_user -m developer1
Create a user with specific shell:
sudo useradd -s /bin/bash -m analyst1
Create a user and add to specific group:
sudo groupadd projectteam
sudo useradd -G projectteam -m manager1
Set passwords for all new users:
sudo passwd developer1
sudo passwd analyst1
sudo passwd manager1
Verify user configurations:
grep -E "(developer1|analyst1|manager1)" /etc/passwd
Subtask 1.4: User Account Modification
Objective: Modify existing user account properties.

Change user's shell:
sudo usermod -s /bin/zsh student1
Add user to additional group:
sudo usermod -aG projectteam student1
Lock a user account:
sudo usermod -L developer1
Unlock the user account:
sudo usermod -U developer1
Verify modifications:
grep student1 /etc/passwd
groups student1
Task 2: System Service Management with systemctl
Subtask 2.1: Checking Service Status
Objective: Learn to monitor system service states.

Check the status of SSH service:
sudo systemctl status sshd
List all active services:
sudo systemctl list-units --type=service --state=active
Check if a service is enabled:
sudo systemctl is-enabled sshd
Check if a service is running:
sudo systemctl is-active sshd
Subtask 2.2: Starting and Stopping Services
Objective: Control service operations manually.

Install and configure a test service (httpd):
sudo dnf install -y httpd
Check httpd service status:
sudo systemctl status httpd
Start the httpd service:
sudo systemctl start httpd
Verify the service is running:
sudo systemctl is-active httpd
Stop the httpd service:
sudo systemctl stop httpd
Restart the service:
sudo systemctl restart httpd
Subtask 2.3: Enabling and Disabling Services
Objective: Configure services to start automatically at boot.

Enable httpd service to start at boot:
sudo systemctl enable httpd
Verify the service is enabled:
sudo systemctl is-enabled httpd
Start and enable in one command:
sudo systemctl enable --now httpd
Disable the service:
sudo systemctl disable httpd
Check service dependencies:
sudo systemctl list-dependencies httpd
Subtask 2.4: Service Configuration and Logs
Objective: Monitor service logs and troubleshoot issues.

View service logs:
sudo journalctl -u httpd
View recent logs only:
sudo journalctl -u httpd --since "1 hour ago"
Follow logs in real-time:
sudo journalctl -u httpd -f
Press Ctrl+C to stop following
Check service configuration file:
sudo systemctl cat httpd
Task 3: File Permissions and Ownership Management
Subtask 3.1: Understanding Current Permissions
Objective: Learn to read and interpret file permissions.

Create a test directory structure:
mkdir -p /tmp/lab_files
cd /tmp/lab_files
Create test files:
touch file1.txt file2.txt file3.txt
mkdir dir1 dir2
Check current permissions:
ls -la
Understand permission notation:
ls -l file1.txt
First character: file type (- for file, d for directory)
Next 9 characters: permissions (rwx for owner, group, others)
Subtask 3.2: Modifying File Permissions with chmod
Objective: Change file and directory permissions using different methods.

Set permissions using octal notation:
chmod 755 file1.txt
ls -l file1.txt
Set permissions using symbolic notation:
chmod u+x file2.txt
ls -l file2.txt
Remove permissions:
chmod g-w file2.txt
ls -l file2.txt
Set multiple permissions:
chmod u+rw,g+r,o-rwx file3.txt
ls -l file3.txt
Apply permissions recursively to directories:
chmod -R 644 dir1/
ls -la dir1/
Subtask 3.3: Advanced Permission Scenarios
Objective: Work with special permissions and complex scenarios.

Create a shared directory:
mkdir /tmp/shared_project
chmod 775 /tmp/shared_project
Set sticky bit on directory:
chmod +t /tmp/shared_project
ls -ld /tmp/shared_project
Set SGID on directory:
chmod g+s /tmp/shared_project
ls -ld /tmp/shared_project
Create files with different permissions:
touch /tmp/shared_project/public_file.txt
chmod 644 /tmp/shared_project/public_file.txt

touch /tmp/shared_project/private_file.txt
chmod 600 /tmp/shared_project/private_file.txt

touch /tmp/shared_project/executable_script.sh
chmod 755 /tmp/shared_project/executable_script.sh
Subtask 3.4: Changing File Ownership with chown
Objective: Modify file and directory ownership.

Check current ownership:
ls -la /tmp/lab_files/
Change file owner:
sudo chown student1 /tmp/lab_files/file1.txt
ls -l /tmp/lab_files/file1.txt
Change file owner and group:
sudo chown student1:projectteam /tmp/lab_files/file2.txt
ls -l /tmp/lab_files/file2.txt
Change ownership recursively:
sudo chown -R manager1:projectteam /tmp/lab_files/dir1/
ls -la /tmp/lab_files/dir1/
Change only group ownership:
sudo chgrp projectteam /tmp/lab_files/file3.txt
ls -l /tmp/lab_files/file3.txt
Subtask 3.5: Practical Security Scenarios
Objective: Apply permissions and ownership in real-world scenarios.

Create a log directory with appropriate permissions:
sudo mkdir /var/log/myapp
sudo chown manager1:projectteam /var/log/myapp
sudo chmod 775 /var/log/myapp
Create a configuration file with restricted access:
sudo touch /etc/myapp.conf
sudo chown root:projectteam /etc/myapp.conf
sudo chmod 640 /etc/myapp.conf
Set up a shared workspace:
sudo mkdir /opt/workspace
sudo chown :projectteam /opt/workspace
sudo chmod 2775 /opt/workspace
Verify all configurations:
ls -ld /var/log/myapp /etc/myapp.conf /opt/workspace
Troubleshooting Tips
Common User Management Issues
Permission denied when creating users: Ensure you're using sudo or running as root
User already exists error: Check existing users with cat /etc/passwd | grep username
Password complexity errors: Use passwords with mixed case, numbers, and special characters
Common Service Management Issues
Service fails to start: Check logs with journalctl -u servicename
Port already in use: Use netstat -tulpn to check port usage
Service not found: Verify package installation with rpm -qa | grep packagename
Common Permission Issues
Permission denied errors: Check file permissions with ls -l filename
Cannot change ownership: Ensure you have sudo privileges
Recursive operations not working: Use -R flag with chmod and chown commands
Verification Commands
Use these commands to verify your lab completion:

# Check created users
cut -d: -f1 /etc/passwd | grep -E "(student1|developer1|analyst1|manager1)"

# Check service status
sudo systemctl is-active httpd
sudo systemctl is-enabled httpd

# Check file permissions and ownership
ls -la /tmp/lab_files/
ls -ld /var/log/myapp /etc/myapp.conf /opt/workspace
Conclusion
In this lab, you have successfully reviewed and practiced essential RHCSA core concepts including:

User Management: Created multiple user accounts with various configurations, set passwords, and modified user properties using useradd, passwd, and usermod commands
Service Management: Controlled system services using systemctl commands, including starting, stopping, enabling, and monitoring services
Security Configuration: Applied proper file permissions using chmod and managed ownership with chown to ensure system security
These fundamental skills form the foundation for Linux system administration and are critical for the RHCE certification path. The ability to manage users, control services, and secure files through proper permissions is essential for maintaining secure and functional Linux environments in enterprise settings.

Key Takeaways:

User management is crucial for system security and access control
Service management ensures system reliability and availability
Proper file permissions and ownership prevent unauthorized access and maintain system integrity
These skills are interconnected and work together to create a secure Linux environment
Continue practicing these concepts in different scenarios to strengthen your understanding and prepare for advanced Linux administration tasks.
