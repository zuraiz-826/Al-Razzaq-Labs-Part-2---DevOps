Lab 5: Configuring Ceph Block Storage (RBD)
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of RADOS Block Devices (RBD) in Ceph storage
Create and configure RBD images for block storage
Map RBD images to virtual machines and mount them as block devices
Perform RBD snapshot operations for data protection
Create and manage RBD clones for efficient storage utilization
Implement best practices for Ceph block storage management
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with storage concepts (block devices, filesystems, mounting)
Knowledge of Ceph cluster architecture and components
Experience with basic Ceph administration commands
Understanding of RADOS pools and placement groups
Access to a functional Ceph cluster (minimum 3 nodes)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph cluster already deployed. Simply click Start Lab to access your environment - no need to build your own virtual machines or install Ceph from scratch.

Your lab environment includes:

3 Ceph monitor nodes
3 Ceph OSD nodes
1 Ceph client node
Pre-configured Ceph cluster with active pools
Task 1: Create an RBD Image
Subtask 1.1: Verify Ceph Cluster Status
First, let's ensure our Ceph cluster is healthy and ready for RBD operations.

Connect to the Ceph client node and verify cluster health:
# Check overall cluster status
ceph status

# Verify OSD status
ceph osd status

# Check monitor status
ceph mon status
List existing pools to understand the current storage configuration:
# List all pools
ceph osd lspool

# Get detailed pool information
ceph osd pool ls detail
Subtask 1.2: Create a Pool for RBD Images
RBD images require a dedicated pool. Let's create one specifically for block storage.

Create a new pool named rbd-pool for our RBD images:
# Create pool with 64 placement groups
ceph osd pool create rbd-pool 64 64

# Initialize the pool for RBD use
rbd pool init rbd-pool
Verify the pool creation:
# Confirm pool exists
ceph osd pool ls | grep rbd-pool

# Check pool statistics
ceph osd pool stats rbd-pool
Subtask 1.3: Create RBD Images
Now we'll create several RBD images with different configurations to demonstrate various use cases.

Create a basic RBD image:
# Create a 10GB RBD image named 'disk1'
rbd create --size 10G --pool rbd-pool disk1

# Verify image creation
rbd ls rbd-pool
Create an RBD image with specific features:
# Create a 5GB image with layering and exclusive-lock features
rbd create --size 5G --image-feature layering,exclusive-lock --pool rbd-pool disk2

# Create a 20GB image with object-map and fast-diff features
rbd create --size 20G --image-feature layering,exclusive-lock,object-map,fast-diff --pool rbd-pool disk3
View detailed information about created images:
# List all images with details
rbd ls -l rbd-pool

# Get specific image information
rbd info rbd-pool/disk1
rbd info rbd-pool/disk2
rbd info rbd-pool/disk3
Subtask 1.4: Resize RBD Images
Demonstrate the flexibility of RBD by resizing images.

Increase the size of an existing image:
# Resize disk1 from 10GB to 15GB
rbd resize --size 15G rbd-pool/disk1

# Verify the resize operation
rbd info rbd-pool/disk1
Shrink an image (use with caution in production):
# Resize disk2 from 5GB to 3GB
rbd resize --size 3G --allow-shrink rbd-pool/disk2

# Verify the resize operation
rbd info rbd-pool/disk2
Task 2: Map and Mount the RBD Image to a Virtual Machine
Subtask 2.1: Map RBD Images to Block Devices
Before we can use RBD images, we need to map them to local block devices.

Install RBD kernel module (if not already loaded):
# Load the RBD kernel module
sudo modprobe rbd

# Verify module is loaded
lsmod | grep rbd
Map RBD images to local block devices:
# Map disk1 to a local block device
sudo rbd map rbd-pool/disk1

# Map disk2 to a local block device
sudo rbd map rbd-pool/disk2

# List mapped RBD devices
rbd showmapped
Identify the mapped device names:
# List block devices to see new RBD devices
lsblk | grep rbd

# Get detailed information about RBD devices
ls -la /dev/rbd*
Subtask 2.2: Create Filesystems on RBD Devices
Now we'll create filesystems on our mapped RBD devices.

Create ext4 filesystem on the first RBD device:
# Create ext4 filesystem on /dev/rbd0 (disk1)
sudo mkfs.ext4 /dev/rbd0

# Create xfs filesystem on /dev/rbd1 (disk2)
sudo mkfs.xfs /dev/rbd1
Verify filesystem creation:
# Check filesystem type
sudo blkid /dev/rbd0
sudo blkid /dev/rbd1

# Display filesystem information
sudo tune2fs -l /dev/rbd0
sudo xfs_info /dev/rbd1
Subtask 2.3: Mount RBD Filesystems
Mount the RBD devices to make them accessible for data storage.

Create mount points:
# Create directories for mounting
sudo mkdir -p /mnt/rbd-disk1
sudo mkdir -p /mnt/rbd-disk2
Mount the RBD devices:
# Mount ext4 filesystem
sudo mount /dev/rbd0 /mnt/rbd-disk1

# Mount xfs filesystem
sudo mount /dev/rbd1 /mnt/rbd-disk2

# Verify mounts
df -h | grep rbd
mount | grep rbd
Test write operations:
# Create test files on mounted RBD devices
sudo touch /mnt/rbd-disk1/test-file-1.txt
echo "Hello from RBD disk1" | sudo tee /mnt/rbd-disk1/test-file-1.txt

sudo touch /mnt/rbd-disk2/test-file-2.txt
echo "Hello from RBD disk2" | sudo tee /mnt/rbd-disk2/test-file-2.txt

# Verify files were created
ls -la /mnt/rbd-disk1/
ls -la /mnt/rbd-disk2/
cat /mnt/rbd-disk1/test-file-1.txt
cat /mnt/rbd-disk2/test-file-2.txt
Subtask 2.4: Configure Persistent Mounting
Set up automatic mounting of RBD devices on system boot.

Get UUID of RBD devices:
# Get UUID for persistent mounting
sudo blkid /dev/rbd0
sudo blkid /dev/rbd1
Create systemd service for RBD mapping:
# Create systemd service file
sudo tee /etc/systemd/system/rbd-map.service << 'EOF'
[Unit]
Description=Map RBD devices
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/rbd map rbd-pool/disk1
ExecStart=/usr/bin/rbd map rbd-pool/disk2
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl enable rbd-map.service
Add entries to /etc/fstab for automatic mounting:
# Backup current fstab
sudo cp /etc/fstab /etc/fstab.backup

# Add RBD mount entries (replace UUIDs with actual values from blkid output)
echo "UUID=your-disk1-uuid /mnt/rbd-disk1 ext4 defaults,_netdev 0 2" | sudo tee -a /etc/fstab
echo "UUID=your-disk2-uuid /mnt/rbd-disk2 xfs defaults,_netdev 0 2" | sudo tee -a /etc/fstab
Task 3: Demonstrate RBD Snapshot and Cloning
Subtask 3.1: Create RBD Snapshots
Snapshots provide point-in-time copies of RBD images for backup and recovery purposes.

Create initial data for snapshot demonstration:
# Create some test data
sudo mkdir -p /mnt/rbd-disk1/important-data
echo "Critical business data - Version 1" | sudo tee /mnt/rbd-disk1/important-data/business-file.txt
echo "Configuration settings - Initial" | sudo tee /mnt/rbd-disk1/important-data/config.txt

# Create a large test file
sudo dd if=/dev/zero of=/mnt/rbd-disk1/large-file.dat bs=1M count=100

# Verify data creation
ls -la /mnt/rbd-disk1/
du -sh /mnt/rbd-disk1/*
Create snapshots of RBD images:
# Unmount the filesystem before creating snapshot (recommended)
sudo umount /mnt/rbd-disk1

# Create snapshot of disk1
rbd snap create rbd-pool/disk1@snapshot-v1

# Create snapshot of disk2
rbd snap create rbd-pool/disk2@snapshot-v1

# List snapshots
rbd snap ls rbd-pool/disk1
rbd snap ls rbd-pool/disk2
Remount and modify data:
# Remount the filesystem
sudo mount /dev/rbd0 /mnt/rbd-disk1

# Modify existing data
echo "Critical business data - Version 2 (Modified)" | sudo tee /mnt/rbd-disk1/important-data/business-file.txt
echo "Configuration settings - Updated" | sudo tee /mnt/rbd-disk1/important-data/config.txt

# Add new data
echo "New feature data" | sudo tee /mnt/rbd-disk1/important-data/new-feature.txt

# Create another snapshot after modifications
sudo umount /mnt/rbd-disk1
rbd snap create rbd-pool/disk1@snapshot-v2
sudo mount /dev/rbd0 /mnt/rbd-disk1
Subtask 3.2: Manage and Restore from Snapshots
Learn how to work with snapshots for data recovery.

List and examine snapshots:
# List all snapshots with details
rbd snap ls rbd-pool/disk1

# Get information about specific snapshot
rbd info rbd-pool/disk1@snapshot-v1
rbd info rbd-pool/disk1@snapshot-v2
Rollback to a previous snapshot:
# Unmount filesystem before rollback
sudo umount /mnt/rbd-disk1

# Rollback to snapshot-v1
rbd snap rollback rbd-pool/disk1@snapshot-v1

# Remount and verify rollback
sudo mount /dev/rbd0 /mnt/rbd-disk1
cat /mnt/rbd-disk1/important-data/business-file.txt
ls -la /mnt/rbd-disk1/important-data/
Protect snapshots to prevent accidental deletion:
# Protect important snapshots
rbd snap protect rbd-pool/disk1@snapshot-v1

# Try to remove protected snapshot (should fail)
rbd snap rm rbd-pool/disk1@snapshot-v1

# List snapshots to see protection status
rbd snap ls rbd-pool/disk1
Subtask 3.3: Create and Manage RBD Clones
Clones allow you to create copy-on-write copies of snapshots, enabling efficient storage utilization.

Create clones from protected snapshots:
# Create clone from protected snapshot
rbd clone rbd-pool/disk1@snapshot-v1 rbd-pool/disk1-clone1

# Create another clone with different name
rbd clone rbd-pool/disk1@snapshot-v1 rbd-pool/disk1-development

# List all images including clones
rbd ls -l rbd-pool
Work with cloned images:
# Map the clone to a block device
sudo rbd map rbd-pool/disk1-clone1

# Create filesystem on clone
sudo mkfs.ext4 /dev/rbd2

# Mount the clone
sudo mkdir -p /mnt/rbd-clone1
sudo mount /dev/rbd2 /mnt/rbd-clone1

# Verify clone contains original data
ls -la /mnt/rbd-clone1/
cat /mnt/rbd-clone1/important-data/business-file.txt
Modify clone independently:
# Add data specific to clone
echo "Clone-specific modifications" | sudo tee /mnt/rbd-clone1/clone-data.txt
echo "Development environment data" | sudo tee /mnt/rbd-clone1/important-data/dev-notes.txt

# Verify original image is unchanged
cat /mnt/rbd-disk1/important-data/business-file.txt
ls -la /mnt/rbd-disk1/ | grep clone-data || echo "Clone data not found in original"
Subtask 3.4: Flatten Clones and Cleanup
Learn how to manage clone dependencies and perform cleanup operations.

Check clone relationships:
# Show clone information
rbd info rbd-pool/disk1-clone1

# List children of snapshot
rbd children rbd-pool/disk1@snapshot-v1
Flatten a clone to make it independent:
# Unmount clone before flattening
sudo umount /mnt/rbd-clone1

# Flatten the clone (makes it independent of parent)
rbd flatten rbd-pool/disk1-clone1

# Verify clone is now independent
rbd info rbd-pool/disk1-clone1
Clean up snapshots and clones:
# Unmap RBD devices
sudo rbd unmap /dev/rbd2

# Remove unneeded clone
rbd rm rbd-pool/disk1-development

# Unprotect snapshot to allow deletion
rbd snap unprotect rbd-pool/disk1@snapshot-v1

# Remove old snapshots
rbd snap rm rbd-pool/disk1@snapshot-v2

# List remaining images and snapshots
rbd ls -l rbd-pool
rbd snap ls rbd-pool/disk1
Advanced RBD Operations
Performance Monitoring and Tuning
Monitor RBD performance:
# Check RBD performance statistics
rbd perf image iostat rbd-pool/disk1

# Monitor real-time I/O statistics
iostat -x 1 | grep rbd
Configure RBD caching:
# Check current cache settings
rbd config global get rbd_cache

# Enable write-back caching for better performance
rbd config global set rbd_cache true
rbd config global set rbd_cache_writethrough_until_flush true
Troubleshooting Common Issues
Check for common RBD mapping issues:
# Verify RBD kernel module
lsmod | grep rbd

# Check for mapping conflicts
rbd showmapped

# Verify Ceph cluster connectivity
ceph health detail
Debug RBD operations:
# Enable debug logging
rbd config global set debug_rbd 20

# Check system logs for RBD errors
sudo journalctl -u ceph-mon@* | grep -i error
sudo dmesg | grep -i rbd
Cleanup and Unmounting
Before concluding the lab, properly clean up resources:

Unmount all RBD filesystems:
# Unmount all RBD mounts
sudo umount /mnt/rbd-disk1
sudo umount /mnt/rbd-disk2
sudo umount /mnt/rbd-clone1 2>/dev/null || true
Unmap RBD devices:
# Unmap all RBD devices
sudo rbd unmap /dev/rbd0
sudo rbd unmap /dev/rbd1
sudo rbd unmap /dev/rbd2 2>/dev/null || true

# Verify unmapping
rbd showmapped
Remove test mount points:
# Remove mount directories
sudo rmdir /mnt/rbd-disk1
sudo rmdir /mnt/rbd-disk2
sudo rmdir /mnt/rbd-clone1 2>/dev/null || true
Conclusion
In this comprehensive lab, you have successfully:

Created and configured RBD images with various features and sizes, demonstrating the flexibility of Ceph block storage
Mapped RBD images to block devices and mounted them as filesystems, making them accessible for data storage
Implemented RBD snapshots for point-in-time data protection and recovery capabilities
Created and managed RBD clones for efficient storage utilization and development environments
Performed advanced operations including snapshot protection, clone flattening, and performance monitoring
Why This Matters:

RBD (RADOS Block Device) is a critical component of Ceph that provides enterprise-grade block storage capabilities. The skills you've learned in this lab are essential for:

Cloud Infrastructure: RBD is widely used in OpenStack and Kubernetes environments for persistent storage
Virtualization: VMware, KVM, and other hypervisors can use RBD for VM disk storage
Database Storage: High-performance databases benefit from RBD's consistency and snapshot capabilities
Backup and Recovery: RBD snapshots and clones provide efficient data protection strategies
Development Workflows: Cloning enables rapid provisioning of development and testing environments
The hands-on experience with RBD operations, snapshot management, and clone functionality prepares you for real-world Ceph deployments and positions you well for the Red Hat Certified Specialist in Ceph Cloud Storage certification. These skills are increasingly valuable as organizations adopt software-defined storage solutions for their critical workloads.
