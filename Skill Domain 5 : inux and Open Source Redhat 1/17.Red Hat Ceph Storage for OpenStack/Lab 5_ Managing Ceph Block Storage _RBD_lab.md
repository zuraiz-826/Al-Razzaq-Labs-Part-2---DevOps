Lab 5: Managing Ceph Block Storage (RBD)
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of RADOS Block Devices (RBD) in Ceph storage
Create and configure RBD images for block storage
Attach RBD images to virtual machines and mount them as block devices
Implement RBD snapshots for data protection and recovery
Create clones from RBD snapshots for efficient data management
Configure and utilize thin provisioning features in Ceph RBD
Manage RBD storage lifecycle including resizing and deletion
Troubleshoot common RBD-related issues
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with storage concepts (block devices, filesystems, mounting)
Knowledge of virtualization concepts
Understanding of Ceph cluster architecture from previous labs
Experience with basic Ceph administration commands
A functioning Ceph cluster (minimum 3 nodes with OSDs)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph cluster already deployed. Simply click Start Lab to access your environment - no need to build your own virtual machines or install Ceph from scratch.

Your lab environment includes:

3 Ceph nodes (ceph-node1, ceph-node2, ceph-node3)
Pre-configured Ceph cluster with OSDs
Client machine for RBD operations
All necessary tools and dependencies installed
Task 1: Create an RBD Image
Subtask 1.1: Verify Ceph Cluster Status
First, let's ensure our Ceph cluster is healthy and ready for RBD operations.

Connect to your Ceph admin node:
# Check cluster health
sudo ceph health

# Verify cluster status
sudo ceph status

# List available pools
sudo ceph osd lspools
Create a dedicated pool for RBD if not exists:
# Create RBD pool with appropriate placement groups
sudo ceph osd pool create rbd 64 64

# Enable RBD application on the pool
sudo ceph osd pool application enable rbd rbd

# Initialize the pool for RBD use
sudo rbd pool init rbd
Subtask 1.2: Create Your First RBD Image
Create a basic RBD image:
# Create a 10GB RBD image named 'lab-disk1'
sudo rbd create --size 10G --pool rbd lab-disk1

# Verify the image was created
sudo rbd ls rbd

# Get detailed information about the image
sudo rbd info rbd/lab-disk1
Create additional RBD images with different features:
# Create an image with specific features enabled
sudo rbd create --size 5G --image-feature layering,exclusive-lock,object-map,fast-diff --pool rbd lab-disk2

# Create a thin-provisioned image
sudo rbd create --size 20G --image-feature layering --pool rbd thin-disk1

# List all images with details
sudo rbd ls -l rbd
Subtask 1.3: Understanding RBD Image Features
Examine RBD features:
# Check available RBD features
sudo rbd feature ls

# View image features for each created image
sudo rbd info rbd/lab-disk1
sudo rbd info rbd/lab-disk2
sudo rbd info rbd/thin-disk1
Key RBD Features Explained:

layering: Enables cloning capabilities
exclusive-lock: Prevents multiple clients from accessing simultaneously
object-map: Tracks which objects exist for faster operations
fast-diff: Enables fast difference calculations between snapshots
Task 2: Attach the RBD to a Virtual Machine
Subtask 2.1: Map RBD Image to Block Device
Map the RBD image to a local block device:
# Map the RBD image to create a block device
sudo rbd map rbd/lab-disk1

# Check mapped devices
sudo rbd showmapped

# Verify the block device was created
lsblk | grep rbd
Check device information:
# Get device path (usually /dev/rbd0, /dev/rbd1, etc.)
DEVICE=$(sudo rbd showmapped | grep lab-disk1 | awk '{print $5}')
echo "Device path: $DEVICE"

# Check device properties
sudo fdisk -l $DEVICE
Subtask 2.2: Create Filesystem and Mount
Create a filesystem on the RBD device:
# Create ext4 filesystem
sudo mkfs.ext4 /dev/rbd0

# Create mount point
sudo mkdir -p /mnt/ceph-rbd

# Mount the filesystem
sudo mount /dev/rbd0 /mnt/ceph-rbd

# Verify mount
df -h /mnt/ceph-rbd
Test the mounted storage:
# Create test files
sudo touch /mnt/ceph-rbd/test-file.txt
echo "Hello from Ceph RBD!" | sudo tee /mnt/ceph-rbd/test-file.txt

# Verify file creation
ls -la /mnt/ceph-rbd/
cat /mnt/ceph-rbd/test-file.txt

# Check disk usage
sudo du -sh /mnt/ceph-rbd/
Subtask 2.3: Configure Persistent Mounting
Create persistent mount configuration:
# Get UUID of the filesystem
UUID=$(sudo blkid /dev/rbd0 | grep -o 'UUID="[^"]*"' | cut -d'"' -f2)
echo "Filesystem UUID: $UUID"

# Backup fstab
sudo cp /etc/fstab /etc/fstab.backup

# Add entry to fstab (for demonstration - not recommended for RBD in production)
echo "# Ceph RBD mount (lab purposes only)" | sudo tee -a /etc/fstab
echo "UUID=$UUID /mnt/ceph-rbd ext4 defaults,noauto 0 0" | sudo tee -a /etc/fstab
Note: In production environments, RBD devices should be managed through proper orchestration tools rather than static fstab entries.

Task 3: Demonstrate Snapshots, Cloning, and Thin Provisioning
Subtask 3.1: Working with RBD Snapshots
Create initial data for snapshot demonstration:
# Create some test data
sudo mkdir -p /mnt/ceph-rbd/data
for i in {1..5}; do
    echo "Data file $i - $(date)" | sudo tee /mnt/ceph-rbd/data/file$i.txt
done

# List created files
ls -la /mnt/ceph-rbd/data/
Create RBD snapshots:
# Unmount before creating snapshot (recommended for consistency)
sudo umount /mnt/ceph-rbd

# Create first snapshot
sudo rbd snap create rbd/lab-disk1@snapshot1

# List snapshots
sudo rbd snap ls rbd/lab-disk1

# Get snapshot information
sudo rbd info rbd/lab-disk1@snapshot1
Modify data and create additional snapshots:
# Remount the device
sudo mount /dev/rbd0 /mnt/ceph-rbd

# Add more data
echo "Additional data after snapshot1" | sudo tee /mnt/ceph-rbd/data/after-snap1.txt
sudo rm /mnt/ceph-rbd/data/file1.txt

# Create second snapshot
sudo umount /mnt/ceph-rbd
sudo rbd snap create rbd/lab-disk1@snapshot2

# List all snapshots
sudo rbd snap ls rbd/lab-disk1
Subtask 3.2: Snapshot Rollback and Protection
Demonstrate snapshot rollback:
# Mount and add more data
sudo mount /dev/rbd0 /mnt/ceph-rbd
echo "Data to be lost in rollback" | sudo tee /mnt/ceph-rbd/data/will-be-lost.txt
ls -la /mnt/ceph-rbd/data/

# Unmount before rollback
sudo umount /mnt/ceph-rbd

# Rollback to snapshot1
sudo rbd snap rollback rbd/lab-disk1@snapshot1

# Verify rollback
sudo mount /dev/rbd0 /mnt/ceph-rbd
ls -la /mnt/ceph-rbd/data/
# Note: file1.txt should be back, after-snap1.txt and will-be-lost.txt should be gone
Protect snapshots from deletion:
# Protect a snapshot
sudo rbd snap protect rbd/lab-disk1@snapshot1

# Try to delete protected snapshot (this will fail)
sudo rbd snap rm rbd/lab-disk1@snapshot1

# List snapshots with protection status
sudo rbd snap ls rbd/lab-disk1
Subtask 3.3: RBD Cloning
Create clones from protected snapshots:
# Ensure snapshot is protected (required for cloning)
sudo rbd snap protect rbd/lab-disk1@snapshot2

# Create a clone from the snapshot
sudo rbd clone rbd/lab-disk1@snapshot2 rbd/lab-disk1-clone

# List images to see the clone
sudo rbd ls -l rbd

# Get clone information
sudo rbd info rbd/lab-disk1-clone
Work with the cloned image:
# Map the clone
sudo rbd map rbd/lab-disk1-clone

# Check mapped devices
sudo rbd showmapped

# Mount the clone
sudo mkdir -p /mnt/ceph-rbd-clone
sudo mount /dev/rbd1 /mnt/ceph-rbd-clone

# Verify clone contents
ls -la /mnt/ceph-rbd-clone/data/
Flatten clone (make it independent):
# Unmount clone
sudo umount /mnt/ceph-rbd-clone

# Flatten the clone to make it independent
sudo rbd flatten rbd/lab-disk1-clone

# Verify clone is now independent
sudo rbd info rbd/lab-disk1-clone
Subtask 3.4: Thin Provisioning Demonstration
Examine thin provisioning behavior:
# Check actual disk usage of thin-provisioned image
sudo rbd disk-usage rbd/thin-disk1

# Map and format the thin-provisioned disk
sudo rbd map rbd/thin-disk1
sudo mkfs.ext4 /dev/rbd2

# Check disk usage after formatting
sudo rbd disk-usage rbd/thin-disk1
Monitor space usage with data addition:
# Mount thin-provisioned disk
sudo mkdir -p /mnt/thin-disk
sudo mount /dev/rbd2 /mnt/thin-disk

# Create files and monitor usage
sudo rbd disk-usage rbd/thin-disk1
sudo dd if=/dev/zero of=/mnt/thin-disk/test1.img bs=1M count=100
sudo rbd disk-usage rbd/thin-disk1

# Create sparse file and compare
sudo dd if=/dev/zero of=/mnt/thin-disk/test2.img bs=1M count=100 seek=100
sudo rbd disk-usage rbd/thin-disk1
Subtask 3.5: Advanced RBD Management
Resize RBD images:
# Check current size
sudo rbd info rbd/lab-disk1

# Resize image (increase size)
sudo rbd resize --size 15G rbd/lab-disk1

# Verify new size
sudo rbd info rbd/lab-disk1

# Extend filesystem to use new space
sudo umount /mnt/ceph-rbd
sudo e2fsck -f /dev/rbd0
sudo resize2fs /dev/rbd0
sudo mount /dev/rbd0 /mnt/ceph-rbd
df -h /mnt/ceph-rbd
Export and import RBD images:
# Export an RBD image
sudo rbd export rbd/lab-disk1 /tmp/lab-disk1-backup.img

# Import to create new image
sudo rbd import /tmp/lab-disk1-backup.img rbd/lab-disk1-restored

# Verify imported image
sudo rbd info rbd/lab-disk1-restored
Troubleshooting Common Issues
Issue 1: RBD Map Fails
Problem: Cannot map RBD image to block device

Solution:

# Check if rbd kernel module is loaded
lsmod | grep rbd

# Load rbd module if not present
sudo modprobe rbd

# Check Ceph configuration
sudo ceph auth list
sudo ceph auth get client.admin
Issue 2: Mount Fails After Reboot
Problem: RBD device not available after system reboot

Solution:

# Create systemd service for RBD mapping
sudo tee /etc/systemd/system/rbd-map.service << EOF
[Unit]
Description=Map RBD devices
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/rbd map rbd/lab-disk1
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable service
sudo systemctl enable rbd-map.service
Issue 3: Snapshot Deletion Fails
Problem: Cannot delete snapshot

Solution:

# Check if snapshot is protected
sudo rbd snap ls rbd/lab-disk1

# Unprotect snapshot if protected
sudo rbd snap unprotect rbd/lab-disk1@snapshot1

# Check for clones
sudo rbd children rbd/lab-disk1@snapshot1

# Remove clones first, then snapshot
Cleanup and Resource Management
Unmount all filesystems:
sudo umount /mnt/ceph-rbd
sudo umount /mnt/ceph-rbd-clone
sudo umount /mnt/thin-disk
Unmap RBD devices:
sudo rbd unmap /dev/rbd0
sudo rbd unmap /dev/rbd1
sudo rbd unmap /dev/rbd2
Clean up snapshots and clones:
# Remove clones first
sudo rbd rm rbd/lab-disk1-clone

# Unprotect and remove snapshots
sudo rbd snap unprotect rbd/lab-disk1@snapshot1
sudo rbd snap unprotect rbd/lab-disk1@snapshot2
sudo rbd snap rm rbd/lab-disk1@snapshot1
sudo rbd snap rm rbd/lab-disk1@snapshot2
Remove RBD images (optional):
sudo rbd rm rbd/lab-disk1
sudo rbd rm rbd/lab-disk2
sudo rbd rm rbd/thin-disk1
sudo rbd rm rbd/lab-disk1-restored
Conclusion
In this comprehensive lab, you have successfully:

Created and managed RBD images with various configurations and features
Attached RBD storage to virtual machines and mounted them as block devices
Implemented snapshot functionality for data protection and point-in-time recovery
Demonstrated cloning capabilities for efficient data duplication and testing
Explored thin provisioning to optimize storage utilization
Performed advanced operations like resizing, exporting, and importing RBD images
Why This Matters:

RBD (RADOS Block Device) is a critical component of Ceph storage that provides:

High-performance block storage for virtual machines and containers
Snapshot and cloning capabilities for backup and development workflows
Thin provisioning for efficient storage utilization
Integration with cloud platforms like OpenStack and Kubernetes
These skills are essential for:

Cloud infrastructure management in enterprise environments
Storage administration in software-defined data centers
DevOps workflows requiring flexible storage solutions
Disaster recovery planning with snapshot-based backups
The hands-on experience gained in this lab prepares you for real-world scenarios where Ceph RBD is used as the backbone for block storage in modern cloud and virtualization platforms. Understanding these concepts is crucial for the Red Hat Ceph Storage for OpenStack certification and professional storage administration roles.
