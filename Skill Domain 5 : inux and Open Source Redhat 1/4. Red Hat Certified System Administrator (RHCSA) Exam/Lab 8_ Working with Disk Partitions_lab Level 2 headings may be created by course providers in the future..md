Lab 8: Working with Disk Partitions
Objectives
By the end of this lab, you will be able to:

Understand disk partitioning concepts and terminology
Use fdisk to create, modify, and delete disk partitions
Format partitions using mkfs command with different file system types
Mount and unmount file systems using mount and umount commands
Configure persistent mounts using /etc/fstab
Verify disk usage and partition information using system utilities
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line interface
Familiarity with file system hierarchy and directory structure
Knowledge of basic Linux commands (ls, cd, cat, etc.)
Understanding of file permissions and ownership concepts
Access to a Linux system with root or sudo privileges
Lab Environment Setup
Al Nafi Cloud Machines: This lab uses Al Nafi's pre-configured Linux-based cloud machines. Simply click Start Lab to access your ready-to-use environment. No need to build your own virtual machine or install additional software.

Your cloud machine includes:

CentOS/RHEL-based Linux distribution
Root access for system administration tasks
Pre-installed disk management utilities
Additional virtual disk for practice exercises
Task 1: Understanding Disk Structure and Partitioning with fdisk
Subtask 1.1: Examine Current Disk Configuration
First, let's explore the current disk setup on your system.

List all available block devices:
lsblk
Display detailed disk information:
fdisk -l
Check current disk usage:
df -h
Expected Output Analysis:

lsblk shows a tree view of all block devices
fdisk -l displays partition tables for all disks
df -h shows mounted file systems and their usage
Subtask 1.2: Identify the Practice Disk
For this lab, we'll work with a secondary disk (usually /dev/sdb or /dev/xvdb).

Identify available disks:
ls -la /dev/sd* /dev/xvd* 2>/dev/null
Verify the practice disk has no important data:
fdisk -l /dev/sdb
Important Safety Note: Always verify you're working with the correct disk to avoid data loss. In this lab environment, /dev/sdb is provided specifically for practice.

Subtask 1.3: Create Partitions Using fdisk
Now we'll create multiple partitions on our practice disk.

Start fdisk interactive mode:
sudo fdisk /dev/sdb
Inside fdisk, follow these steps:

a. Display current partition table:

p
b. Create a new primary partition:

n
p
1
[Press Enter for default start]
+2G
c. Create a second primary partition:

n
p
2
[Press Enter for default start]
+1G
d. Display the new partition table:

p
e. Write changes to disk:

w
Verify the new partitions:

lsblk /dev/sdb
fdisk -l /dev/sdb
Subtask 1.4: Understanding Partition Types
Let's explore different partition types and their uses.

Create an extended partition for logical drives:
sudo fdisk /dev/sdb
Inside fdisk:

n
e
3
[Press Enter for default start]
[Press Enter for default end]
Create logical partitions within the extended partition:

n
l
[Press Enter for default start]
+500M
Save changes and exit:

w
Task 2: Formatting Partitions with mkfs
Subtask 2.1: Understanding File System Types
Different file systems serve different purposes. Let's explore the most common ones.

Check available file system types:
ls /sbin/mkfs*
View file system support:
cat /proc/filesystems
Subtask 2.2: Format Partitions with Different File Systems
Now we'll format our partitions with various file system types.

Format the first partition with ext4:
sudo mkfs.ext4 /dev/sdb1
Format the second partition with xfs:
sudo mkfs.xfs /dev/sdb2
Format the logical partition with ext3:
sudo mkfs.ext3 /dev/sdb5
Verify the file systems:
sudo blkid /dev/sdb1 /dev/sdb2 /dev/sdb5
Subtask 2.3: Adding Labels to File Systems
Labels make file systems easier to identify and manage.

Add a label to the ext4 partition:
sudo e2label /dev/sdb1 "DATA_EXT4"
Add a label to the xfs partition:
sudo xfs_admin -L "DATA_XFS" /dev/sdb2
Verify the labels:
sudo blkid | grep sdb
Task 3: Mounting and Unmounting File Systems
Subtask 3.1: Create Mount Points
Mount points are directories where file systems are attached to the directory tree.

Create mount point directories:
sudo mkdir -p /mnt/data1
sudo mkdir -p /mnt/data2
sudo mkdir -p /mnt/data3
Verify the directories were created:
ls -la /mnt/
Subtask 3.2: Manual Mounting
Let's mount our formatted partitions manually.

Mount the ext4 partition:
sudo mount /dev/sdb1 /mnt/data1
Mount the xfs partition:
sudo mount /dev/sdb2 /mnt/data2
Mount the ext3 partition:
sudo mount /dev/sdb5 /mnt/data3
Verify all mounts:
mount | grep sdb
df -h | grep sdb
Subtask 3.3: Testing Mounted File Systems
Let's verify our mounted file systems are working correctly.

Create test files on each mounted file system:
sudo touch /mnt/data1/test_ext4.txt
sudo touch /mnt/data2/test_xfs.txt
sudo touch /mnt/data3/test_ext3.txt
Write data to test files:
echo "This is an ext4 file system" | sudo tee /mnt/data1/test_ext4.txt
echo "This is an xfs file system" | sudo tee /mnt/data2/test_xfs.txt
echo "This is an ext3 file system" | sudo tee /mnt/data3/test_ext3.txt
Verify the files:
ls -la /mnt/data1/
ls -la /mnt/data2/
ls -la /mnt/data3/
Check file system usage:
df -h /mnt/data1 /mnt/data2 /mnt/data3
Subtask 3.4: Unmounting File Systems
Proper unmounting is crucial for data integrity.

Unmount all test file systems:
sudo umount /mnt/data1
sudo umount /mnt/data2
sudo umount /mnt/data3
Verify unmounting:
mount | grep sdb
df -h | grep sdb
Check that mount points are empty:
ls -la /mnt/data1/
ls -la /mnt/data2/
ls -la /mnt/data3/
Subtask 3.5: Mounting by Label and UUID
Using labels and UUIDs provides more reliable mounting than device names.

Mount by label:
sudo mount LABEL="DATA_EXT4" /mnt/data1
Get UUID information:
sudo blkid /dev/sdb2
Mount by UUID (replace UUID with actual value from previous command):
sudo mount UUID="your-actual-uuid-here" /mnt/data2
Verify mounts:
mount | grep -E "(data1|data2)"
Task 4: Configuring Persistent Mounts
Subtask 4.1: Understanding /etc/fstab
The /etc/fstab file controls which file systems are mounted automatically at boot.

Examine the current fstab file:
cat /etc/fstab
Create a backup of fstab:
sudo cp /etc/fstab /etc/fstab.backup
Subtask 4.2: Adding Entries to /etc/fstab
Let's add our partitions to fstab for automatic mounting.

Get UUID information for all partitions:
sudo blkid /dev/sdb1 /dev/sdb2 /dev/sdb5
Add entries to fstab (replace UUIDs with actual values):
echo "UUID=your-sdb1-uuid /mnt/data1 ext4 defaults 0 2" | sudo tee -a /etc/fstab
echo "UUID=your-sdb2-uuid /mnt/data2 xfs defaults 0 2" | sudo tee -a /etc/fstab
echo "UUID=your-sdb5-uuid /mnt/data3 ext3 defaults 0 2" | sudo tee -a /etc/fstab
Verify the fstab entries:
tail -3 /etc/fstab
Subtask 4.3: Testing fstab Configuration
Always test fstab changes before rebooting.

Unmount all partitions:
sudo umount /mnt/data1 /mnt/data2 2>/dev/null
Test mounting all fstab entries:
sudo mount -a
Verify successful mounting:
mount | grep sdb
df -h | grep sdb
Test specific mount:
sudo umount /mnt/data1
sudo mount /mnt/data1
Advanced Operations and Troubleshooting
Common Issues and Solutions
Device busy error when unmounting:
# Check what's using the mount point
sudo lsof /mnt/data1
sudo fuser -v /mnt/data1

# Force unmount if necessary (use with caution)
sudo umount -f /mnt/data1
Check file system for errors:
# For ext4/ext3 file systems
sudo fsck.ext4 /dev/sdb1

# For xfs file systems
sudo xfs_repair /dev/sdb2
View detailed partition information:
sudo parted /dev/sdb print
Performance and Monitoring
Monitor disk I/O:
iostat -x 1 5
Check file system statistics:
# For ext4 file systems
sudo tune2fs -l /dev/sdb1

# For xfs file systems
sudo xfs_info /mnt/data2
Lab Cleanup
Before finishing the lab, let's clean up our work.

Unmount all test partitions:
sudo umount /mnt/data1 /mnt/data2 /mnt/data3 2>/dev/null
Remove fstab entries (optional, for cleanup):
sudo cp /etc/fstab.backup /etc/fstab
Remove mount point directories:
sudo rmdir /mnt/data1 /mnt/data2 /mnt/data3
Conclusion
Congratulations! You have successfully completed Lab 8: Working with Disk Partitions. In this comprehensive lab, you have accomplished the following:

Key Skills Developed:

Disk Management: You learned to examine disk structure and identify available storage devices using tools like lsblk and fdisk -l
Partitioning: You mastered creating primary, extended, and logical partitions using fdisk interactive commands
File System Creation: You formatted partitions with different file system types (ext4, xfs, ext3) using various mkfs commands
Mount Management: You practiced mounting and unmounting file systems manually using mount and umount commands
Persistent Configuration: You configured automatic mounting through /etc/fstab entries using UUIDs and labels
Troubleshooting: You learned to identify and resolve common mounting issues and perform file system checks
Real-World Applications: These skills are essential for Linux system administrators and are directly applicable to:

Server Storage Management: Adding new disks and partitions to production servers
Data Organization: Creating separate partitions for different types of data (logs, databases, user files)
System Maintenance: Performing file system checks and repairs
Disaster Recovery: Understanding partition structure for backup and recovery operations
Performance Optimization: Choosing appropriate file systems for specific use cases
RHCSA Exam Relevance: This lab directly prepares you for Red Hat Certified System Administrator (RHCSA) exam objectives, specifically:

Configure local storage including disk partitions and logical volumes
Create and configure file systems and file system attributes
Mount and unmount network file systems using NFS
Next Steps: With these foundational disk management skills, you're ready to explore more advanced topics such as:

Logical Volume Management (LVM)
RAID configuration
Network file systems (NFS, CIFS)
Storage encryption and security
The hands-on experience gained in this lab provides you with practical skills that are immediately applicable in real-world Linux environments, making you more effective as a system administrator and better prepared for professional certification exams.
