Lab 19: LVM Configuration
Objectives
Understand and configure Logical Volume Manager (LVM) for flexible storage management
Create and manage physical volumes (PVs), volume groups (VGs), and logical volumes (LVs)
Perform storage operations including extending and shrinking logical volumes
Prerequisites
A Linux system (RHEL/CentOS/Fedora recommended)
Root or sudo privileges
Unallocated disk space or additional disks (physical or virtual)
Basic familiarity with Linux command line and storage concepts
Lab Setup
Before beginning, ensure you have available storage devices. You can use:

Unpartitioned disks (/dev/sdb, /dev/sdc, etc.)
Unused disk partitions
Loop devices (for testing)
Verify available disks:

lsblk
sudo fdisk -l
Task 1: Create Physical Volumes (PVs) and Volume Groups (VGs)
Subtask 1.1: Create Physical Volumes
Identify the disk/partition to use (e.g., /dev/sdb)
Create a physical volume:
sudo pvcreate /dev/sdb
Verify the PV creation:
sudo pvdisplay
Expected Output:
Information about the newly created PV including size, PE size, and free space.

Troubleshooting:

If device is in use, unmount it first with umount /dev/sdb
If device has existing partitions, wipe them with wipefs -a /dev/sdb
Subtask 1.2: Create Volume Group
Create a VG named vg01 using the PV:
sudo vgcreate vg01 /dev/sdb
Verify VG creation:
sudo vgdisplay vg01
Expected Output:
VG name, size, number of PVs, and free space.

Task 2: Create Logical Volumes (LVs) and Format Them
Subtask 2.1: Create Logical Volume
Create a 5GB LV named lv01 in vg01:
sudo lvcreate -L 5G -n lv01 vg01
Verify LV creation:
sudo lvdisplay /dev/vg01/lv01
Expected Output:
LV path, size, and block device information.

Subtask 2.2: Format and Mount LV
Format the LV with ext4 filesystem:
sudo mkfs.ext4 /dev/vg01/lv01
Create a mount point and mount the LV:
sudo mkdir /mnt/lv01
sudo mount /dev/vg01/lv01 /mnt/lv01
Verify mounting:
df -h /mnt/lv01
Expected Output:
Mounted filesystem showing 5GB capacity.

Troubleshooting:

If mount fails, check dmesg for filesystem errors
Ensure mount point directory exists
Task 3: Extend and Shrink LVs
Subtask 3.1: Extend a Logical Volume
Extend lv01 by additional 2GB (assuming space is available in VG):
sudo lvextend -L +2G /dev/vg01/lv01
Resize the filesystem (for ext4):
sudo resize2fs /dev/vg01/lv01
Verify new size:
df -h /mnt/lv01
Expected Output:
Filesystem now shows ~7GB capacity.

Subtask 3.2: Shrink a Logical Volume
Warning: Shrinking requires unmounting and carries risk of data loss. Backup first.

Unmount the filesystem:
sudo umount /mnt/lv01
Check filesystem for errors:
sudo e2fsck -f /dev/vg01/lv01
Shrink filesystem first (to 4GB):
sudo resize2fs /dev/vg01/lv01 4G
Shrink the LV:
sudo lvreduce -L 4G /dev/vg01/lv01
Remount and verify:
sudo mount /dev/vg01/lv01 /mnt/lv01
df -h /mnt/lv01
Expected Output:
Filesystem now shows ~4GB capacity.

Advanced Operations (Optional)
Snapshot Creation
Create a snapshot of lv01:
sudo lvcreate -s -n lv01_snap -L 1G /dev/vg01/lv01
Mount snapshot to verify:
sudo mkdir /mnt/snap
sudo mount /dev/vg01/lv01_snap /mnt/snap
Troubleshooting Tips
Use vgscan and vgchange -ay if VGs aren't detected
Check /var/log/messages for LVM errors
For thin provisioning, use lvcreate -T instead of -L
Conclusion
In this lab you have:

Created and managed physical volumes and volume groups
Configured logical volumes with filesystems
Performed dynamic resizing operations (extend/shrink)
(Optional) Created LVM snapshots
LVM provides powerful storage management capabilities that are essential for system administrators managing dynamic storage requirements.

Cleanup (Optional)
To remove all lab resources:

sudo umount /mnt/lv01
sudo lvremove /dev/vg01/lv01
sudo vgremove vg01
sudo pvremove /dev/sdb
Further Reading
man lvm for complete LVM documentation
Red Hat Storage Administration Guide (RHCSA/RHCE objectives)
Linux Documentation Project: tldp.org/HOWTO/LVM-HOWTO
