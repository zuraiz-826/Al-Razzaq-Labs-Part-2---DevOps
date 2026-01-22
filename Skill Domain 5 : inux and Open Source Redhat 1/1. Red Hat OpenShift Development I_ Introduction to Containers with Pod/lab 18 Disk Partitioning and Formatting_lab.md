Lab 18: Disk Partitioning and Formatting
Objectives
To understand disk partitioning concepts in Linux
To practice using fdisk and parted partitioning tools
To format partitions with different filesystems using mkfs
To configure persistent mount points using /etc/fstab
Prerequisites
A Linux system (physical or virtual machine) with root/sudo access
An additional unused disk (or virtual disk) for practice
Basic familiarity with Linux command line
The following packages installed: util-linux (for fdisk), parted, e2fsprogs
Lab Setup
Verify available disks:
lsblk
Identify the target disk (we'll use /dev/sdb in examples - replace with your actual target disk)
Task 1: Partitioning a Disk
Subtask 1.1: Using fdisk
Launch fdisk on target disk:
sudo fdisk /dev/sdb
Common fdisk commands:
n - Create new partition
p - Print partition table
d - Delete partition
t - Change partition type
w - Write changes and exit
q - Quit without saving
Create a new partition:
n → p → 1 → (default first sector) → +5G → w
Expected Output: New 5GB partition created as /dev/sdb1

Subtask 1.2: Using parted (Alternative)
Start parted:
sudo parted /dev/sdb
Create partition:
(parted) mklabel gpt
(parted) mkpart primary ext4 1MiB 5GiB
(parted) print
(parted) quit
Troubleshooting Tip: If you get "unrecognized disk label", run mklabel first as shown above.

Task 2: Formatting Partitions
Subtask 2.1: Creating Filesystems
Format as ext4:
sudo mkfs.ext4 /dev/sdb1
For XFS (if preferred):
sudo mkfs.xfs /dev/sdb1
Verify filesystem creation:
sudo blkid /dev/sdb1
Expected Output: Should show filesystem type and UUID

Task 3: Mounting and Persistence
Subtask 3.1: Temporary Mount
Create mount point:
sudo mkdir /mnt/mydata
Mount partition:
sudo mount /dev/sdb1 /mnt/mydata
Verify:
df -hT /mnt/mydata
Subtask 3.2: Persistent Mount
Get partition UUID:
sudo blkid /dev/sdb1
Edit fstab:
sudo nano /etc/fstab
Add entry (example for ext4):
UUID=your-uuid-here /mnt/mydata ext4 defaults 0 2
Test fstab entry:
sudo mount -a
Verify automatic mount after reboot:
sudo reboot
df -hT /mnt/mydata
Troubleshooting Tip: If system fails to boot after fstab changes, boot into rescue mode and correct the fstab file.

Advanced Exercise (Optional)
Create a swap partition:
sudo fdisk /dev/sdb
# Create new partition, change to type 82' (Linux swap)
sudo mkswap /dev/sdb2
sudo swapon /dev/sdb2
Add to fstab:
/dev/sdb2 none swap sw 0 0
Conclusion
In this lab, you have:

Practiced disk partitioning using both fdisk and parted utilities
Created different types of filesystems on partitions
Configured both temporary and persistent mount points
Learned to verify your configurations at each step
These skills are essential for system administrators and are particularly relevant when working with container storage in OpenShift environments, where understanding persistent storage is crucial.

Cleanup (Optional)
To remove your changes:

Unmount the partition:
sudo umount /mnt/mydata
Remove fstab entry if added
Delete partitions using fdisk or parted
Additional Resources
man fdisk
man parted
man mkfs
man mount
Red Hat Storage Administration documentation
