Lab 9: Managing Logical Volumes (LVM)
Objectives
By the end of this lab, you will be able to:

Understand the fundamental concepts of Logical Volume Management (LVM)
Create and configure physical volumes using pvcreate
Create and manage volume groups using vgcreate
Create logical volumes using lvcreate
Extend logical volumes dynamically using lvextend
Format and mount LVM-based filesystems
Monitor and display LVM information using various commands
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line interface
Knowledge of disk partitioning concepts
Familiarity with filesystem operations (mount, umount, mkfs)
Understanding of storage devices and block devices in Linux
Basic knowledge of file permissions and directory structure
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or configure additional storage devices.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
Multiple unused disk devices for LVM practice
All necessary LVM tools pre-installed
Understanding LVM Concepts
Logical Volume Management (LVM) is a storage management technology that provides a flexible approach to managing disk storage. LVM creates an abstraction layer between physical storage devices and the filesystem.

Key LVM Components:
Physical Volume (PV): Raw storage devices or partitions prepared for LVM use
Volume Group (VG): Collection of physical volumes that creates a storage pool
Logical Volume (LV): Virtual partitions created from volume group space
Physical Extent (PE): Smallest unit of space allocation in LVM (default 4MB)
Task 1: Creating Physical Volumes
Subtask 1.1: Identify Available Storage Devices
First, let's identify the available storage devices on your system.

# List all block devices
lsblk

# Display detailed disk information
fdisk -l

# Show current LVM physical volumes (if any)
pvs
Subtask 1.2: Prepare Disks for LVM
For this lab, we'll assume you have unused disks /dev/sdb, /dev/sdc, and /dev/sdd. If your system has different device names, adjust accordingly.

# Check if the disks are currently mounted or in use
mount | grep -E "(sdb|sdc|sdd)"

# Verify disk status
lsblk /dev/sdb /dev/sdc /dev/sdd
Subtask 1.3: Create Physical Volumes
Now we'll convert our raw disks into LVM physical volumes.

# Create physical volumes on three disks
pvcreate /dev/sdb
pvcreate /dev/sdc
pvcreate /dev/sdd

# Alternative: Create multiple PVs in one command
# pvcreate /dev/sdb /dev/sdc /dev/sdd
Subtask 1.4: Verify Physical Volume Creation
# Display physical volume information
pvs

# Show detailed PV information
pvdisplay

# Display specific PV details
pvdisplay /dev/sdb
Expected Output Example:

PV         VG Fmt  Attr PSize  PFree
/dev/sdb      lvm2 ---  20.00g 20.00g
/dev/sdc      lvm2 ---  20.00g 20.00g
/dev/sdd      lvm2 ---  20.00g 20.00g
Task 2: Creating Volume Groups
Subtask 2.1: Create Your First Volume Group
A volume group combines multiple physical volumes into a single storage pool.

# Create a volume group named 'vg_data' using two physical volumes
vgcreate vg_data /dev/sdb /dev/sdc

# Verify volume group creation
vgs

# Display detailed VG information
vgdisplay vg_data
Subtask 2.2: Create Additional Volume Group
# Create another volume group with the remaining disk
vgcreate vg_backup /dev/sdd

# View all volume groups
vgs
Subtask 2.3: Extend Volume Group
You can add physical volumes to existing volume groups.

# First, let's create another physical volume (using a partition this time)
# Create a partition on /dev/sdb if needed (optional demonstration)
fdisk /dev/sdb
# Follow prompts to create a new partition /dev/sdb1
# Then make it a physical volume
# pvcreate /dev/sdb1

# For this example, we'll extend vg_data by adding vg_backup's PV
# First remove the PV from vg_backup
vgreduce vg_backup /dev/sdd

# Add it to vg_data
vgextend vg_data /dev/sdd

# Verify the extension
vgs
vgdisplay vg_data
Task 3: Creating and Managing Logical Volumes
Subtask 3.1: Create Basic Logical Volumes
# Create a 10GB logical volume named 'lv_web'
lvcreate -L 10G -n lv_web vg_data

# Create a 5GB logical volume named 'lv_database'
lvcreate -L 5G -n lv_database vg_data

# Create a logical volume using percentage of VG space
lvcreate -l 50%VG -n lv_logs vg_data

# Display logical volumes
lvs

# Show detailed LV information
lvdisplay
Subtask 3.2: Format and Mount Logical Volumes
# Create filesystems on the logical volumes
mkfs.ext4 /dev/vg_data/lv_web
mkfs.xfs /dev/vg_data/lv_database
mkfs.ext4 /dev/vg_data/lv_logs

# Create mount points
mkdir -p /mnt/web
mkdir -p /mnt/database
mkdir -p /mnt/logs

# Mount the logical volumes
mount /dev/vg_data/lv_web /mnt/web
mount /dev/vg_data/lv_database /mnt/database
mount /dev/vg_data/lv_logs /mnt/logs

# Verify mounts
df -h
mount | grep vg_data
Subtask 3.3: Test Logical Volume Functionality
# Create test files on each mounted LV
echo "Web server data" > /mnt/web/index.html
echo "Database content" > /mnt/database/data.sql
echo "Application logs" > /mnt/logs/app.log

# Verify file creation
ls -la /mnt/web/
ls -la /mnt/database/
ls -la /mnt/logs/

# Check disk usage
du -sh /mnt/web /mnt/database /mnt/logs
Task 4: Extending Logical Volumes
Subtask 4.1: Extend Logical Volume Size
One of LVM's key advantages is the ability to resize logical volumes dynamically.

# Check current LV sizes
lvs

# Check available space in volume group
vgs

# Extend lv_web by 5GB
lvextend -L +5G /dev/vg_data/lv_web

# Alternative: Extend to specific size
# lvextend -L 20G /dev/vg_data/lv_web

# Verify the extension
lvs
Subtask 4.2: Resize the Filesystem
After extending the logical volume, you must resize the filesystem to use the new space.

# For ext4 filesystems (lv_web)
resize2fs /dev/vg_data/lv_web

# For XFS filesystems (lv_database), first extend the LV
lvextend -L +3G /dev/vg_data/lv_database
# Then resize XFS filesystem (must be mounted)
xfs_growfs /mnt/database

# Verify the filesystem sizes
df -h /mnt/web /mnt/database
Subtask 4.3: One-Step Extension with Filesystem Resize
LVM provides a convenient option to extend both the LV and filesystem in one command.

# Extend logical volume and resize filesystem simultaneously
lvextend -L +2G -r /dev/vg_data/lv_logs

# Verify the changes
df -h /mnt/logs
lvs
Task 5: Monitoring and Information Commands
Subtask 5.1: Comprehensive LVM Status Check
# Display all LVM information
pvs && echo "---" && vgs && echo "---" && lvs

# Show detailed information for all components
echo "=== Physical Volumes ==="
pvdisplay

echo "=== Volume Groups ==="
vgdisplay

echo "=== Logical Volumes ==="
lvdisplay
Subtask 5.2: Advanced Monitoring Commands
# Show LVM scan results
pvscan
vgscan
lvscan

# Display LV status and attributes
lvs -o +lv_layout,lv_role

# Show VG with PE information
vgs -o +vg_extent_size,vg_extent_count,vg_free_count

# Display PV allocation information
pvs -o +pv_used,pv_free
Task 6: Creating Persistent Mounts
Subtask 6.1: Configure Automatic Mounting
To ensure your logical volumes mount automatically at boot, add them to /etc/fstab.

# Backup the current fstab
cp /etc/fstab /etc/fstab.backup

# Add LVM mounts to fstab
echo "/dev/vg_data/lv_web     /mnt/web      ext4    defaults    0 2" >> /etc/fstab
echo "/dev/vg_data/lv_database /mnt/database xfs     defaults    0 2" >> /etc/fstab
echo "/dev/vg_data/lv_logs    /mnt/logs     ext4    defaults    0 2" >> /etc/fstab

# Verify fstab entries
tail -3 /etc/fstab

# Test fstab configuration
umount /mnt/web /mnt/database /mnt/logs
mount -a

# Verify all mounts are working
df -h | grep vg_data
Task 7: LVM Snapshot Creation (Bonus)
Subtask 7.1: Create LVM Snapshots
Snapshots provide point-in-time copies of logical volumes, useful for backups.

# Create a snapshot of lv_web (10% of original size for snapshot metadata)
lvcreate -L 1G -s -n lv_web_snapshot /dev/vg_data/lv_web

# Create snapshot of lv_database
lvcreate -L 1G -s -n lv_database_snapshot /dev/vg_data/lv_database

# Display snapshots
lvs -o +origin,snap_percent

# Mount snapshot to verify content
mkdir /mnt/web_snapshot
mount /dev/vg_data/lv_web_snapshot /mnt/web_snapshot
ls -la /mnt/web_snapshot/
Subtask 7.2: Test Snapshot Functionality
# Modify original data
echo "Modified web content" >> /mnt/web/index.html

# Compare original and snapshot
cat /mnt/web/index.html
cat /mnt/web_snapshot/index.html

# Clean up snapshots when done
umount /mnt/web_snapshot
lvremove /dev/vg_data/lv_web_snapshot
lvremove /dev/vg_data/lv_database_snapshot
Troubleshooting Common Issues
Issue 1: Device Busy Error
# If you get "device busy" errors:
# Check what's using the device
lsof /dev/sdb
fuser -v /dev/sdb

# Unmount any filesystems
umount /dev/sdb1

# Stop any processes using the device
fuser -k /dev/sdb
Issue 2: Insufficient Space
# Check available space in volume group
vgdisplay vg_data | grep -E "(VG Size|Free)"

# If needed, add more physical volumes
pvcreate /dev/sde
vgextend vg_data /dev/sde
Issue 3: LVM Commands Not Found
# Install LVM tools if missing
yum install lvm2 -y
# or
dnf install lvm2 -y

# Start LVM services
systemctl start lvm2-monitor
systemctl enable lvm2-monitor
Lab Verification Checklist
Before completing the lab, verify you have accomplished:

 Created at least 3 physical volumes using pvcreate
 Created 1 or more volume groups using vgcreate
 Created multiple logical volumes with different sizes
 Successfully extended at least one logical volume
 Formatted logical volumes with different filesystems (ext4, xfs)
 Mounted logical volumes and created test files
 Extended both logical volume and filesystem
 Added LVM mounts to /etc/fstab for persistence
 Used various LVM information commands (pvs, vgs, lvs, etc.)
Cleanup Instructions (Optional)
If you want to clean up the lab environment:

# Unmount all LVM filesystems
umount /mnt/web /mnt/database /mnt/logs

# Remove fstab entries (edit manually)
vi /etc/fstab

# Remove logical volumes
lvremove /dev/vg_data/lv_web
lvremove /dev/vg_data/lv_database
lvremove /dev/vg_data/lv_logs

# Remove volume groups
vgremove vg_data

# Remove physical volumes
pvremove /dev/sdb /dev/sdc /dev/sdd
Conclusion
Congratulations! You have successfully completed Lab 9: Managing Logical Volumes (LVM). In this comprehensive lab, you have:

Accomplished Key Skills:

Mastered the creation and management of LVM physical volumes, volume groups, and logical volumes
Learned to dynamically extend storage without system downtime
Gained hands-on experience with advanced storage management techniques
Implemented persistent mounting configurations for production environments
Why This Matters: LVM is a critical technology for system administrators because it provides:

Flexibility: Resize storage on-demand without repartitioning
Scalability: Add storage capacity by simply adding new disks
Reliability: Create snapshots for backup and recovery purposes
Efficiency: Optimize storage utilization across multiple physical devices
Real-World Applications:

Database servers requiring dynamic storage expansion
Web servers with growing content requirements
Enterprise environments with changing storage needs
Cloud infrastructure requiring flexible storage management
RHCSA Exam Relevance: This lab directly prepares you for RHCSA exam objectives related to storage management, including creating and managing LVM configurations, extending logical volumes, and implementing persistent storage solutions.

You now have the practical skills to implement LVM in production environments and can confidently manage complex storage scenarios that system administrators encounter daily. These skills are essential for the Red Hat Certified System Administrator certification and real-world Linux system administration roles.
