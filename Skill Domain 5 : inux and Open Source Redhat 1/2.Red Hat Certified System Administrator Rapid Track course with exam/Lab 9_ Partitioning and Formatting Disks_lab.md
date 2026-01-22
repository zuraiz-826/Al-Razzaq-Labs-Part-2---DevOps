Lab 9: Partitioning and Formatting Disks
Objectives
By the end of this lab, students will be able to:

• Create and manage disk partitions using fdisk and parted command-line tools • Format partitions with various file systems using mkfs utilities • Mount and unmount file systems to make them accessible to the operating system • Understand the difference between MBR and GPT partition tables • Verify partition and file system information using system commands • Implement proper disk management practices for Linux systems

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command-line interface • Knowledge of file system hierarchy and directory structure • Familiarity with sudo command for administrative privileges • Understanding of basic storage concepts (disks, partitions, file systems) • Access to a Linux terminal environment

Lab Environment Setup
Al Nafi Cloud Machines: This lab uses Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machine or install additional software.

Your cloud machine includes: • CentOS/RHEL-based Linux distribution • Administrative (sudo) access • Pre-attached additional storage devices for practice • All necessary partitioning and formatting tools pre-installed

Task 1: Create Partitions with fdisk and parted
Subtask 1.1: Identify Available Storage Devices
First, let's examine the storage devices available on your system.

Step 1: List all block devices

lsblk
Step 2: Display detailed disk information

sudo fdisk -l
Step 3: Check current disk usage

df -h
Expected Output: You should see your primary disk (usually /dev/sda or /dev/vda) and additional practice disks (like /dev/sdb, /dev/sdc).

Subtask 1.2: Create Partitions Using fdisk
fdisk is a traditional partitioning tool that works with MBR (Master Boot Record) partition tables.

Step 1: Start fdisk on the second disk

sudo fdisk /dev/sdb
Step 2: Create a new partition table

Command (m for help): o
This creates a new empty DOS partition table.

Step 3: Create the first partition

Command (m for help): n
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
Select (default p): p
Partition number (1-4, default 1): 1
First sector (2048-20971519, default 2048): [Press Enter]
Last sector, +sectors or +size{K,M,G} (2048-20971519, default 20971519): +2G
Step 4: Create a second partition

Command (m for help): n
Partition type:
   p   primary (1 primary, 0 extended, 3 free)
   e   extended
Select (default p): p
Partition number (2-4, default 2): 2
First sector (4196352-20971519, default 4196352): [Press Enter]
Last sector, +sectors or +size{K,M,G} (4196352-20971519, default 20971519): +1G
Step 5: View the partition table

Command (m for help): p
Step 6: Write changes to disk

Command (m for help): w
Step 7: Verify the new partitions

lsblk /dev/sdb
Subtask 1.3: Create Partitions Using parted
parted is a more modern partitioning tool that supports both MBR and GPT partition tables.

Step 1: Start parted on the third disk

sudo parted /dev/sdc
Step 2: Create a GPT partition table

(parted) mklabel gpt
Step 3: Create the first partition

(parted) mkpart primary ext4 1MiB 1GiB
Step 4: Create the second partition

(parted) mkpart primary xfs 1GiB 3GiB
Step 5: Display the partition table

(parted) print
Step 6: Exit parted

(parted) quit
Step 7: Verify the new partitions

lsblk /dev/sdc
Task 2: Format Partitions with mkfs
Subtask 2.1: Format with ext4 File System
ext4 is the default file system for most Linux distributions.

Step 1: Format the first partition on /dev/sdb with ext4

sudo mkfs.ext4 /dev/sdb1
Step 2: Add a label to the file system

sudo mkfs.ext4 -L "DataDisk1" /dev/sdb1
Step 3: Verify the file system creation

sudo blkid /dev/sdb1
Subtask 2.2: Format with xfs File System
XFS is a high-performance file system commonly used in enterprise environments.

Step 1: Format the second partition on /dev/sdb with xfs

sudo mkfs.xfs /dev/sdb2
Step 2: Add a label to the XFS file system

sudo mkfs.xfs -L "DataDisk2" /dev/sdb2
Step 3: Verify the file system creation

sudo blkid /dev/sdb2
Subtask 2.3: Format GPT Partitions
Step 1: Format the first GPT partition with ext4

sudo mkfs.ext4 -L "GPTDisk1" /dev/sdc1
Step 2: Format the second GPT partition with xfs

sudo mkfs.xfs -L "GPTDisk2" /dev/sdc2
Step 3: Verify both file systems

sudo blkid /dev/sdc1 /dev/sdc2
Task 3: Mount and Unmount File Systems
Subtask 3.1: Create Mount Points
Step 1: Create directories for mount points

sudo mkdir -p /mnt/disk1
sudo mkdir -p /mnt/disk2
sudo mkdir -p /mnt/gpt1
sudo mkdir -p /mnt/gpt2
Step 2: Verify the directories were created

ls -la /mnt/
Subtask 3.2: Mount File Systems Manually
Step 1: Mount the ext4 partition

sudo mount /dev/sdb1 /mnt/disk1
Step 2: Mount the xfs partition

sudo mount /dev/sdb2 /mnt/disk2
Step 3: Mount the GPT partitions

sudo mount /dev/sdc1 /mnt/gpt1
sudo mount /dev/sdc2 /mnt/gpt2
Step 4: Verify all mounts

df -h
Step 5: Check mount details

mount | grep -E "(sdb|sdc)"
Subtask 3.3: Test File System Access
Step 1: Create test files on each mounted file system

sudo touch /mnt/disk1/test_ext4.txt
sudo touch /mnt/disk2/test_xfs.txt
sudo touch /mnt/gpt1/test_gpt_ext4.txt
sudo touch /mnt/gpt2/test_gpt_xfs.txt
Step 2: Write data to test files

echo "This is an ext4 file system" | sudo tee /mnt/disk1/test_ext4.txt
echo "This is an xfs file system" | sudo tee /mnt/disk2/test_xfs.txt
echo "This is a GPT ext4 file system" | sudo tee /mnt/gpt1/test_gpt_ext4.txt
echo "This is a GPT xfs file system" | sudo tee /mnt/gpt2/test_gpt_xfs.txt
Step 3: Verify file contents

cat /mnt/disk1/test_ext4.txt
cat /mnt/disk2/test_xfs.txt
cat /mnt/gpt1/test_gpt_ext4.txt
cat /mnt/gpt2/test_gpt_xfs.txt
Subtask 3.4: Unmount File Systems
Step 1: Unmount all file systems

sudo umount /mnt/disk1
sudo umount /mnt/disk2
sudo umount /mnt/gpt1
sudo umount /mnt/gpt2
Step 2: Verify unmounting

df -h | grep -E "(sdb|sdc)"
Step 3: Check if mount points are empty

ls -la /mnt/disk1/
ls -la /mnt/disk2/
Subtask 3.5: Configure Persistent Mounts
Step 1: Backup the current fstab file

sudo cp /etc/fstab /etc/fstab.backup
Step 2: Get UUID information for partitions

sudo blkid | grep -E "(sdb|sdc)"
Step 3: Add entries to /etc/fstab using UUIDs

echo "# Lab 9 - Disk partitions" | sudo tee -a /etc/fstab
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1) /mnt/disk1 ext4 defaults 0 2" | sudo tee -a /etc/fstab
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb2) /mnt/disk2 xfs defaults 0 2" | sudo tee -a /etc/fstab
Step 4: Test the fstab configuration

sudo mount -a
Step 5: Verify persistent mounts

df -h | grep -E "(disk1|disk2)"
Verification and Testing
Final System Check
Step 1: Display complete partition information

lsblk -f
Step 2: Show file system usage

df -hT
Step 3: Verify fstab entries

cat /etc/fstab | tail -5
Step 4: Test file system integrity

sudo fsck -n /dev/sdb1
sudo xfs_info /dev/sdb2
Troubleshooting Common Issues
Issue 1: Device is Busy
If you encounter "device is busy" when trying to unmount:

sudo fuser -m /mnt/disk1
sudo lsof +D /mnt/disk1
Issue 2: Partition Not Recognized
If new partitions aren't visible:

sudo partprobe /dev/sdb
sudo partprobe /dev/sdc
Issue 3: Mount Point Already in Use
If mount fails due to existing mount:

sudo umount /mnt/disk1
sudo mount /dev/sdb1 /mnt/disk1
Cleanup (Optional)
If you want to clean up the lab environment:

Step 1: Unmount all file systems

sudo umount /mnt/disk1 /mnt/disk2 /mnt/gpt1 /mnt/gpt2
Step 2: Remove fstab entries

sudo cp /etc/fstab.backup /etc/fstab
Step 3: Remove mount point directories

sudo rmdir /mnt/disk1 /mnt/disk2 /mnt/gpt1 /mnt/gpt2
Conclusion
In this lab, you have successfully accomplished the following key tasks:

• Mastered Disk Partitioning: You learned to create partitions using both traditional fdisk (for MBR) and modern parted (for GPT) tools, understanding the differences between partition table types.

• Implemented File System Formatting: You formatted partitions with different file systems (ext4 and xfs) using mkfs utilities, adding labels for better identification.

• Configured File System Mounting: You manually mounted and unmounted file systems, created persistent mount configurations in /etc/fstab, and verified proper functionality.

• Applied Best Practices: You used UUIDs for persistent mounting, created proper mount points, and learned troubleshooting techniques for common disk management issues.

Why This Matters: Disk partitioning and formatting are fundamental skills for Linux system administrators. These skills are essential for:

Managing storage in production environments
Preparing systems for data storage and backup
Optimizing performance through proper file system selection
Meeting Red Hat Certified System Administrator (RHCSA) certification requirements
The hands-on experience gained in this lab provides the foundation for advanced storage management topics including LVM (Logical Volume Management), RAID configurations, and enterprise storage solutions. These skills are directly applicable in real-world scenarios where proper disk management is critical for system reliability and performance.
