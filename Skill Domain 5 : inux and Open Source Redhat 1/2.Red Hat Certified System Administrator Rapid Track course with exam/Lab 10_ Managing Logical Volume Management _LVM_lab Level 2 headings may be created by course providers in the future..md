Lab 10: Managing Logical Volume Management (LVM)
Objectives
By the end of this lab, students will be able to:

• Understand the fundamental concepts of Logical Volume Management (LVM) • Create physical volumes using the pvcreate command • Create volume groups with the vgcreate command • Create logical volumes using the lvcreate command • Extend logical volumes to increase storage capacity • Shrink logical volumes to reduce storage space • Monitor and manage LVM components effectively • Apply LVM concepts in real-world storage management scenarios

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux file systems and partitions • Familiarity with command-line interface operations • Knowledge of basic Linux commands (ls, cd, mkdir, etc.) • Understanding of storage devices and disk management concepts • Root or sudo access to perform administrative tasks

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or configure additional software.

Your lab environment includes: • CentOS/RHEL-based Linux system with LVM tools pre-installed • Multiple virtual disks for practicing LVM operations • Root access for administrative tasks • All necessary utilities and commands ready to use

Understanding LVM Concepts
Before diving into the practical tasks, let's understand the key components of LVM:

• Physical Volume (PV): Raw storage devices or partitions that LVM can use • Volume Group (VG): A collection of physical volumes that creates a storage pool • Logical Volume (LV): Virtual partitions created from volume group space • Physical Extent (PE): The smallest unit of space that can be allocated (default 4MB)

Task 1: Creating Physical Volumes
Subtask 1.1: Identify Available Storage Devices
First, let's identify the available storage devices on our system.

# List all block devices
lsblk

# Display detailed information about disks
fdisk -l

# Check current disk usage
df -h
Subtask 1.2: Prepare Disks for LVM
We'll use additional disks that are available in your lab environment. Typically, these will be /dev/sdb, /dev/sdc, and /dev/sdd.

# Verify the disks are available and not mounted
lsblk | grep -E "sdb|sdc|sdd"

# Check if any of these disks have existing partitions
fdisk -l /dev/sdb
fdisk -l /dev/sdc
fdisk -l /dev/sdd
Subtask 1.3: Create Physical Volumes
Now we'll create physical volumes from our available disks.

# Create physical volumes on three disks
pvcreate /dev/sdb
pvcreate /dev/sdc
pvcreate /dev/sdd

# Verify the physical volumes were created successfully
pvdisplay

# Show a summary of physical volumes
pvs
Expected Output: You should see confirmation messages indicating that physical volumes were successfully created, and the pvdisplay command should show details about each physical volume.

Subtask 1.4: Examine Physical Volume Details
Let's examine the details of our newly created physical volumes.

# Display detailed information about all physical volumes
pvdisplay -v

# Show specific information about one physical volume
pvdisplay /dev/sdb

# List physical volumes in a compact format
pvscan
Task 2: Creating Volume Groups
Subtask 2.1: Create Your First Volume Group
A volume group combines multiple physical volumes into a single storage pool.

# Create a volume group named 'vg_data' using two physical volumes
vgcreate vg_data /dev/sdb /dev/sdc

# Verify the volume group was created
vgdisplay

# Show volume group summary
vgs
Subtask 2.2: Create a Second Volume Group
Let's create another volume group for practice.

# Create a second volume group named 'vg_backup' using the third disk
vgcreate vg_backup /dev/sdd

# Display information about all volume groups
vgdisplay -v

# Check the status of all volume groups
vgs -v
Subtask 2.3: Examine Volume Group Properties
Understanding volume group properties is crucial for effective management.

# Display detailed information about a specific volume group
vgdisplay vg_data

# Show the physical volumes in a volume group
vgdisplay -v vg_data

# Scan for all volume groups
vgscan
Task 3: Creating Logical Volumes
Subtask 3.1: Create Logical Volumes with Specific Sizes
Now we'll create logical volumes within our volume groups.

# Create a 2GB logical volume named 'lv_documents' in vg_data
lvcreate -L 2G -n lv_documents vg_data

# Create a 1GB logical volume named 'lv_projects' in vg_data
lvcreate -L 1G -n lv_projects vg_data

# Create a 500MB logical volume named 'lv_backup' in vg_backup
lvcreate -L 500M -n lv_backup vg_backup

# Verify the logical volumes were created
lvdisplay

# Show logical volume summary
lvs
Subtask 3.2: Create Logical Volumes Using Percentages
You can also create logical volumes using percentages of available space.

# Create a logical volume using 50% of remaining free space in vg_backup
lvcreate -l 50%FREE -n lv_archive vg_backup

# Display all logical volumes
lvdisplay -v

# Show logical volume information in table format
lvs -o +lv_size,lv_path
Subtask 3.3: Format and Mount Logical Volumes
To use logical volumes, we need to format them with a file system and mount them.

# Create directories for mount points
mkdir -p /mnt/documents
mkdir -p /mnt/projects
mkdir -p /mnt/backup
mkdir -p /mnt/archive

# Format logical volumes with ext4 file system
mkfs.ext4 /dev/vg_data/lv_documents
mkfs.ext4 /dev/vg_data/lv_projects
mkfs.ext4 /dev/vg_backup/lv_backup
mkfs.ext4 /dev/vg_backup/lv_archive

# Mount the logical volumes
mount /dev/vg_data/lv_documents /mnt/documents
mount /dev/vg_data/lv_projects /mnt/projects
mount /dev/vg_backup/lv_backup /mnt/backup
mount /dev/vg_backup/lv_archive /mnt/archive

# Verify the mounts
df -h | grep -E "documents|projects|backup|archive"
Task 4: Extending and Shrinking Volumes
Subtask 4.1: Extend a Logical Volume
Let's extend the lv_documents logical volume to provide more storage space.

# Check current size of the logical volume
lvs vg_data/lv_documents

# Check available space in the volume group
vgs vg_data

# Extend the logical volume by 1GB
lvextend -L +1G /dev/vg_data/lv_documents

# Verify the extension
lvs vg_data/lv_documents

# Resize the file system to use the new space
resize2fs /dev/vg_data/lv_documents

# Check the new file system size
df -h /mnt/documents
Subtask 4.2: Extend a Volume Group
If you need more space than available in the volume group, you can extend the volume group first.

# Check current volume group size
vgs vg_data

# If you had additional physical volumes, you could add them like this:
# (This is for demonstration - we'll simulate the concept)
echo "# To extend a volume group with a new physical volume:"
echo "# vgextend vg_data /dev/sde"

# Show how to extend a logical volume to use all available space
lvextend -l +100%FREE /dev/vg_data/lv_projects

# Resize the file system
resize2fs /dev/vg_data/lv_projects

# Verify the changes
df -h /mnt/projects
Subtask 4.3: Shrink a Logical Volume
Important: Always backup data before shrinking volumes, and unmount the file system first.

# Unmount the logical volume we want to shrink
umount /mnt/archive

# Check the file system for errors
e2fsck -f /dev/vg_backup/lv_archive

# Shrink the file system first (to 200MB)
resize2fs /dev/vg_backup/lv_archive 200M

# Then shrink the logical volume
lvreduce -L 200M /dev/vg_backup/lv_archive

# Confirm the operation when prompted
# Type 'y' when asked

# Verify the new size
lvs vg_backup/lv_archive

# Remount the logical volume
mount /dev/vg_backup/lv_archive /mnt/archive

# Check the file system size
df -h /mnt/archive
Subtask 4.4: Monitor LVM Components
Let's create some test files and monitor our LVM setup.

# Create test files in different logical volumes
echo "This is a test document" > /mnt/documents/test.txt
echo "This is a project file" > /mnt/projects/project.txt
echo "This is backup data" > /mnt/backup/backup.txt
echo "This is archived data" > /mnt/archive/archive.txt

# Check disk usage
df -h | grep -E "documents|projects|backup|archive"

# Display comprehensive LVM information
echo "=== Physical Volumes ==="
pvs

echo "=== Volume Groups ==="
vgs

echo "=== Logical Volumes ==="
lvs

# Show detailed LVM tree structure
lsblk | grep -E "sdb|sdc|sdd"
Advanced LVM Operations
Subtask 4.5: Create LVM Snapshots
Snapshots are useful for backups and testing.

# Create a snapshot of lv_documents (100MB snapshot space)
lvcreate -L 100M -s -n lv_documents_snapshot /dev/vg_data/lv_documents

# Verify the snapshot was created
lvs | grep snapshot

# Mount the snapshot to access it
mkdir -p /mnt/snapshot
mount /dev/vg_data/lv_documents_snapshot /mnt/snapshot

# Compare original and snapshot
ls -la /mnt/documents/
ls -la /mnt/snapshot/

# Clean up the snapshot
umount /mnt/snapshot
lvremove /dev/vg_data/lv_documents_snapshot
# Type 'y' when prompted
Troubleshooting Common Issues
Issue 1: Physical Volume Creation Fails
# If pvcreate fails, check if the device is in use
lsof /dev/sdb

# Check if there are existing partitions
fdisk -l /dev/sdb

# If needed, wipe existing signatures
wipefs -a /dev/sdb
Issue 2: Volume Group Creation Problems
# If vgcreate fails, verify physical volumes exist
pvs

# Check if the volume group name already exists
vgs | grep vg_data

# Use a different name if needed
vgcreate vg_data2 /dev/sdb /dev/sdc
Issue 3: Logical Volume Mount Issues
# If mount fails, check the file system
fsck /dev/vg_data/lv_documents

# Verify the mount point exists
ls -ld /mnt/documents

# Check if already mounted
mount | grep documents
Lab Verification and Testing
Final System Check
Let's verify everything is working correctly:

# Complete system overview
echo "=== LVM System Overview ==="
echo "Physical Volumes:"
pvs
echo ""
echo "Volume Groups:"
vgs
echo ""
echo "Logical Volumes:"
lvs
echo ""
echo "Mounted File Systems:"
df -h | grep -E "documents|projects|backup|archive"
echo ""
echo "LVM Tree Structure:"
lsblk | grep -A 20 -B 5 -E "sdb|sdc|sdd"
Performance Test
# Test write performance on different logical volumes
echo "Testing write performance..."
time dd if=/dev/zero of=/mnt/documents/testfile bs=1M count=100
time dd if=/dev/zero of=/mnt/projects/testfile bs=1M count=100

# Clean up test files
rm /mnt/documents/testfile
rm /mnt/projects/testfile
Cleanup (Optional)
If you want to clean up the lab environment:

# Unmount all logical volumes
umount /mnt/documents
umount /mnt/projects
umount /mnt/backup
umount /mnt/archive

# Remove logical volumes
lvremove /dev/vg_data/lv_documents
lvremove /dev/vg_data/lv_projects
lvremove /dev/vg_backup/lv_backup
lvremove /dev/vg_backup/lv_archive

# Remove volume groups
vgremove vg_data
vgremove vg_backup

# Remove physical volumes
pvremove /dev/sdb
pvremove /dev/sdc
pvremove /dev/sdd
Conclusion
Congratulations! You have successfully completed Lab 10 on Managing Logical Volume Management (LVM). In this lab, you have accomplished the following:

Key Achievements:

• Mastered LVM Fundamentals: You learned the core concepts of Physical Volumes, Volume Groups, and Logical Volumes, understanding how they work together to provide flexible storage management.

• Created Physical Volumes: You successfully used the pvcreate command to prepare raw storage devices for use with LVM, establishing the foundation of your storage infrastructure.

• Built Volume Groups: You created volume groups using vgcreate, combining multiple physical volumes into unified storage pools that can be managed as single entities.

• Deployed Logical Volumes: You created multiple logical volumes with lvcreate, using both specific sizes and percentage-based allocation methods to meet different storage requirements.

• Performed Dynamic Storage Management: You successfully extended and shrunk logical volumes, demonstrating LVM's key advantage of providing flexible, on-demand storage allocation without system downtime.

• Implemented Advanced Features: You explored LVM snapshots and learned troubleshooting techniques that are essential for production environments.

Why This Matters:

LVM is a critical technology in enterprise Linux environments because it provides:

• Flexibility: Storage can be allocated and reallocated dynamically without reformatting or system downtime • Scalability: Storage pools can grow by adding new physical volumes • Efficiency: Space utilization is optimized through logical volume management • Reliability: Features like snapshots provide backup and recovery capabilities • Simplified Management: Complex storage configurations become manageable through logical abstraction

Real-World Applications:

The skills you've developed in this lab are directly applicable to:

• Database server storage management • Web server content storage scaling • Backup and disaster recovery solutions • Cloud infrastructure storage provisioning • Enterprise data center storage administration

Next Steps:

To further develop your LVM expertise, consider exploring:

• LVM striping and mirroring for performance and redundancy • Integration with file system quotas and access controls • Automation of LVM operations through scripting • LVM monitoring and alerting in production environments • Advanced snapshot management and backup strategies

You now have the foundational knowledge and practical experience to implement and manage LVM in professional Linux environments, making you better prepared for the Red Hat Certified System Administrator certification and real-world system administration roles.
