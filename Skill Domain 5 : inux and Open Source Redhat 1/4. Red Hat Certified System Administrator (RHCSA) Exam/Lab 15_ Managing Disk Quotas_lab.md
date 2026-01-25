Lab 15: Managing Disk Quotas
Objectives
By the end of this lab, students will be able to:

Understand the concept and importance of disk quotas in Linux systems
Enable quota support on file systems
Set and configure user disk quotas using the edquota command
Monitor disk usage and quota limits using quota and repquota commands
Troubleshoot common quota-related issues
Implement quota policies for system administration
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux file systems and directory structure
Familiarity with Linux command-line interface
Knowledge of user and group management in Linux
Understanding of file permissions and ownership
Basic text editor skills (vi/vim or nano)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
Pre-installed quota utilities
Multiple user accounts for testing
Additional disk partition for quota implementation
Task 1: Enable Quota on File Systems
Subtask 1.1: Check Current File System Configuration
First, let's examine the current file system setup and identify where we'll implement quotas.

Check current mounted file systems:
df -h
View the current fstab configuration:
cat /etc/fstab
Check if quota packages are installed:
rpm -qa | grep quota
If quota packages are not installed, install them:

sudo yum install quota -y
Subtask 1.2: Modify File System for Quota Support
Create a backup of the fstab file:
sudo cp /etc/fstab /etc/fstab.backup
Edit the fstab file to enable quotas:
sudo vi /etc/fstab
Add quota options to the desired file system. Find the line for your target file system (typically /home or /) and add usrquota,grpquota to the options:
# Example: Original line
/dev/mapper/rhel-home /home xfs defaults 0 0

# Modified line with quota support
/dev/mapper/rhel-home /home xfs defaults,usrquota,grpquota 0 0
Note: For XFS file systems, use uquota,gquota instead of usrquota,grpquota.

Subtask 1.3: Remount File System with Quota Support
Remount the file system to apply quota options:
sudo mount -o remount /home
Verify the mount options:
mount | grep /home
You should see the quota options in the output.

Subtask 1.4: Initialize Quota Database
For ext4 file systems, create quota database files:
sudo quotacheck -cug /home
For XFS file systems, enable quota enforcement:
sudo xfs_quota -x -c 'enable -uv' /home
sudo xfs_quota -x -c 'enable -gv' /home
Turn on quota enforcement:
# For ext4 file systems
sudo quotaon /home

# For XFS file systems (quotas are automatically enabled)
sudo xfs_quota -x -c 'state' /home
Task 2: Set User Quotas Using edquota
Subtask 2.1: Create Test Users
Create test users for quota demonstration:
sudo useradd testuser1
sudo useradd testuser2
sudo useradd testuser3
Set passwords for test users:
sudo passwd testuser1
sudo passwd testuser2
sudo passwd testuser3
Use simple passwords like password123 for lab purposes.

Create home directories if they don't exist:
sudo mkdir -p /home/testuser1
sudo mkdir -p /home/testuser2
sudo mkdir -p /home/testuser3
sudo chown testuser1:testuser1 /home/testuser1
sudo chown testuser2:testuser2 /home/testuser2
sudo chown testuser3:testuser3 /home/testuser3
Subtask 2.2: Set User Quotas with edquota
Set quota for testuser1 using edquota:
sudo edquota -u testuser1
This opens an editor with quota settings. Modify the values as follows:

Disk quotas for user testuser1 (uid 1001):
  Filesystem                   blocks       soft       hard     inodes     soft     hard
  /dev/mapper/rhel-home             0      50000     100000          0        0        0
Explanation of fields:

blocks: Current disk usage in 1KB blocks
soft: Soft limit for disk space (warning threshold)
hard: Hard limit for disk space (absolute maximum)
inodes: Current number of files/directories
soft/hard (inodes): Limits on number of files
Set different quotas for testuser2:
sudo edquota -u testuser2
Set values:

Disk quotas for user testuser2 (uid 1002):
  Filesystem                   blocks       soft       hard     inodes     soft     hard
  /dev/mapper/rhel-home             0      25000      50000          0      100      150
Copy quota settings from one user to another:
sudo edquota -p testuser1 testuser3
This copies testuser1's quota settings to testuser3.

Subtask 2.3: Set Grace Periods
Configure grace periods for soft limit violations:
sudo edquota -t
Set grace periods:

Grace period before enforcing soft limits for users:
Time units may be: days, hours, minutes, or seconds
  Filesystem             Block grace period     Inode grace period
  /dev/mapper/rhel-home           7days                  7days
Task 3: Monitor Disk Usage with quota and repquota
Subtask 3.1: Check Individual User Quotas
Check quota for a specific user:
sudo quota -u testuser1
Check quota for all users:
sudo quota -u testuser1 testuser2 testuser3
Display quota in human-readable format:
sudo quota -u testuser1 -h
Subtask 3.2: Generate Quota Reports
Generate a comprehensive quota report:
sudo repquota /home
Generate report for all file systems:
sudo repquota -a
Generate report in human-readable format:
sudo repquota -h /home
Generate report for users only:
sudo repquota -u /home
Subtask 3.3: Test Quota Enforcement
Switch to testuser1 and test quota limits:
sudo su - testuser1
Create a large file to test soft limit:
dd if=/dev/zero of=testfile1 bs=1M count=40
Check current quota usage:
quota -u
Try to exceed the hard limit:
dd if=/dev/zero of=testfile2 bs=1M count=70
You should receive a quota exceeded error.

Return to root user:
exit
Subtask 3.4: Monitor Quota Violations
Check for users exceeding quotas:
sudo repquota /home | grep -E '\+|\*'
The + symbol indicates soft limit exceeded, * indicates hard limit exceeded.

Generate a report of quota violations:
sudo warnquota
Advanced Quota Management
Setting Group Quotas
Set quota for a group:
sudo edquota -g users
Check group quota:
sudo quota -g users
Quota Maintenance Commands
Check quota consistency:
sudo quotacheck -avug
Turn off quotas temporarily:
sudo quotaoff /home
Turn quotas back on:
sudo quotaon /home
Check quota status:
sudo quotaon -p /home
Troubleshooting Common Issues
Issue 1: Quota Not Working After Setup
Problem: Quotas are configured but not enforcing limits.

Solution:

# Check if quotas are enabled
sudo quotaon -p /home

# If not enabled, turn them on
sudo quotaon /home

# For XFS, check quota state
sudo xfs_quota -x -c 'state' /home
Issue 2: Permission Denied When Running edquota
Problem: Cannot edit quota settings.

Solution:

# Ensure you're running as root or with sudo
sudo edquota -u username

# Check if quota files exist and have correct permissions
ls -la /home/aquota.*
Issue 3: Quota Database Corruption
Problem: Quota database appears corrupted.

Solution:

# Turn off quotas
sudo quotaoff /home

# Rebuild quota database
sudo quotacheck -avug /home

# Turn quotas back on
sudo quotaon /home
Lab Verification
Verification Checklist
Verify quota is enabled on file system:
mount | grep quota
Confirm users have quota limits set:
sudo repquota /home
Test quota enforcement:
sudo su - testuser1
dd if=/dev/zero of=large_file bs=1M count=60
quota -u
exit
Verify quota reports are working:
sudo repquota -h /home
Conclusion
In this lab, you have successfully learned how to implement and manage disk quotas on Linux systems. You accomplished the following key tasks:

What You Learned:

Quota Implementation: Enabled quota support on file systems by modifying /etc/fstab and remounting file systems with quota options
User Quota Management: Used edquota to set disk space and inode limits for individual users, including soft and hard limits
Quota Monitoring: Utilized quota and repquota commands to monitor disk usage and generate comprehensive quota reports
Quota Enforcement: Tested quota limits to ensure proper enforcement and learned how the system prevents users from exceeding their allocated disk space
Why This Matters: Disk quota management is essential for system administrators to:

Prevent System Overload: Stop individual users from consuming all available disk space
Resource Planning: Monitor and plan storage requirements based on actual usage patterns
Fair Resource Distribution: Ensure equitable access to storage resources among multiple users
System Stability: Maintain system performance by preventing disk space exhaustion
Real-World Applications:

Multi-user Servers: Web hosting environments where multiple customers share server resources
Educational Institutions: University systems where students need limited storage allocations
Corporate Environments: Employee workstations and shared file servers with storage policies
Cloud Infrastructure: Virtual private servers with defined storage limits
These quota management skills are fundamental for the Red Hat Certified System Administrator (RHCSA) certification and are widely applicable in enterprise Linux environments. The ability to implement, monitor, and maintain disk quotas demonstrates proficiency in essential system administration tasks that ensure optimal resource utilization and system reliability.
