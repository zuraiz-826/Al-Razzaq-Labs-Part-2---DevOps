Lab 7: Configuring CephFS for File Storage
Objectives
By the end of this lab, you will be able to:

Deploy and configure Metadata Servers (MDS) for CephFS
Create and mount CephFS volumes for POSIX-compliant file storage
Configure access control mechanisms for CephFS
Implement and manage CephFS snapshots
Understand the architecture and components of CephFS
Troubleshoot common CephFS deployment issues
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux file systems and storage concepts
Familiarity with Ceph cluster architecture (OSDs, MONs)
Knowledge of Linux command-line operations
Understanding of POSIX file system concepts
Completion of previous Ceph labs or equivalent experience
Basic networking knowledge (IP addressing, ports)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

3 Ceph cluster nodes (ceph-node1, ceph-node2, ceph-node3)
1 client machine for mounting CephFS
Pre-installed Ceph packages and dependencies
Network connectivity between all nodes
Task 1: Set up MDS (Metadata Server) for CephFS
Subtask 1.1: Verify Ceph Cluster Status
Before deploying MDS services, ensure your Ceph cluster is healthy and operational.

Check cluster health:
sudo ceph health
sudo ceph status
Verify available pools:
sudo ceph osd pool ls
Check MON and OSD status:
sudo ceph mon stat
sudo ceph osd stat
Expected output should show HEALTH_OK status with all MONs and OSDs up and running.

Subtask 1.2: Create Required Pools for CephFS
CephFS requires two pools: one for metadata and one for data storage.

Create metadata pool:
sudo ceph osd pool create cephfs_metadata 32 32
Create data pool:
sudo ceph osd pool create cephfs_data 64 64
Verify pool creation:
sudo ceph osd pool ls detail
Note: Pool placement group (PG) numbers should be adjusted based on your cluster size. For production environments, use the PG calculator.

Subtask 1.3: Deploy MDS Services
Install MDS package (if not already installed):
sudo apt update
sudo apt install ceph-mds -y
Create MDS data directory:
sudo mkdir -p /var/lib/ceph/mds/ceph-mds.ceph-node1
sudo chown ceph:ceph /var/lib/ceph/mds/ceph-mds.ceph-node1
Create MDS keyring:
sudo ceph auth get-or-create mds.ceph-node1 mon 'allow profile mds' osd 'allow rwx' mds 'allow *' -o /var/lib/ceph/mds/ceph-mds.ceph-node1/keyring
Set proper permissions:
sudo chown ceph:ceph /var/lib/ceph/mds/ceph-mds.ceph-node1/keyring
sudo chmod 600 /var/lib/ceph/mds/ceph-mds.ceph-node1/keyring
Start and enable MDS service:
sudo systemctl start ceph-mds@ceph-node1
sudo systemctl enable ceph-mds@ceph-node1
Verify MDS service status:
sudo systemctl status ceph-mds@ceph-node1
sudo ceph mds stat
Subtask 1.4: Deploy Additional MDS for High Availability
For production environments, deploy multiple MDS instances for redundancy.

On ceph-node2, repeat the MDS setup:
# SSH to ceph-node2
ssh ceph-node2

# Create MDS directory
sudo mkdir -p /var/lib/ceph/mds/ceph-mds.ceph-node2
sudo chown ceph:ceph /var/lib/ceph/mds/ceph-mds.ceph-node2

# Create keyring
sudo ceph auth get-or-create mds.ceph-node2 mon 'allow profile mds' osd 'allow rwx' mds 'allow *' -o /var/lib/ceph/mds/ceph-mds.ceph-node2/keyring

# Set permissions
sudo chown ceph:ceph /var/lib/ceph/mds/ceph-mds.ceph-node2/keyring
sudo chmod 600 /var/lib/ceph/mds/ceph-mds.ceph-node2/keyring

# Start service
sudo systemctl start ceph-mds@ceph-node2
sudo systemctl enable ceph-mds@ceph-node2
Verify multiple MDS instances:
sudo ceph mds stat
sudo ceph fs status
Task 2: Create and Mount a CephFS Volume
Subtask 2.1: Create CephFS File System
Create the CephFS file system:
sudo ceph fs new cephfs cephfs_metadata cephfs_data
Verify file system creation:
sudo ceph fs ls
sudo ceph fs status cephfs
Check MDS status after file system creation:
sudo ceph mds stat
You should see one MDS in active state and others in standby.

Subtask 2.2: Configure Client Authentication
Create client keyring with appropriate permissions:
sudo ceph auth get-or-create client.cephfs mon 'allow r' mds 'allow rw' osd 'allow rw pool=cephfs_data' -o /etc/ceph/ceph.client.cephfs.keyring
Set proper permissions on keyring:
sudo chmod 600 /etc/ceph/ceph.client.cephfs.keyring
Verify client authentication:
sudo ceph auth list | grep client.cephfs
Subtask 2.3: Mount CephFS using Kernel Client
Install CephFS kernel client (if not already installed):
sudo apt install ceph-fuse -y
Create mount point:
sudo mkdir -p /mnt/cephfs
Mount CephFS using kernel client:
sudo mount -t ceph ceph-node1:6789,ceph-node2:6789,ceph-node3:6789:/ /mnt/cephfs -o name=cephfs,secretfile=/etc/ceph/ceph.client.cephfs.keyring
Verify mount:
df -h /mnt/cephfs
mount | grep cephfs
Test write operations:
sudo touch /mnt/cephfs/test-file
echo "Hello CephFS" | sudo tee /mnt/cephfs/test-file
cat /mnt/cephfs/test-file
Subtask 2.4: Mount CephFS using FUSE Client
Create alternative mount point:
sudo mkdir -p /mnt/cephfs-fuse
Mount using ceph-fuse:
sudo ceph-fuse /mnt/cephfs-fuse --name client.cephfs --keyring /etc/ceph/ceph.client.cephfs.keyring
Verify FUSE mount:
df -h /mnt/cephfs-fuse
mount | grep fuse
Test FUSE mount functionality:
sudo mkdir /mnt/cephfs-fuse/fuse-test
sudo touch /mnt/cephfs-fuse/fuse-test/sample.txt
echo "FUSE mount test" | sudo tee /mnt/cephfs-fuse/fuse-test/sample.txt
Subtask 2.5: Configure Persistent Mounts
Create mount script for automation:
sudo tee /usr/local/bin/mount-cephfs.sh << 'EOF'
#!/bin/bash
# CephFS Mount Script

MOUNT_POINT="/mnt/cephfs"
MONITORS="ceph-node1:6789,ceph-node2:6789,ceph-node3:6789"
CLIENT_NAME="cephfs"
KEYRING_FILE="/etc/ceph/ceph.client.cephfs.keyring"

# Check if already mounted
if mountpoint -q "$MOUNT_POINT"; then
    echo "CephFS already mounted at $MOUNT_POINT"
    exit 0
fi

# Create mount point if it doesn't exist
mkdir -p "$MOUNT_POINT"

# Mount CephFS
mount -t ceph "$MONITORS":/ "$MOUNT_POINT" -o name="$CLIENT_NAME",secretfile="$KEYRING_FILE"

if [ $? -eq 0 ]; then
    echo "CephFS successfully mounted at $MOUNT_POINT"
else
    echo "Failed to mount CephFS"
    exit 1
fi
EOF
Make script executable:
sudo chmod +x /usr/local/bin/mount-cephfs.sh
Test mount script:
sudo umount /mnt/cephfs
sudo /usr/local/bin/mount-cephfs.sh
Task 3: Configure Access Control and Snapshots
Subtask 3.1: Configure Directory-Based Access Control
Create test directories with different access levels:
sudo mkdir -p /mnt/cephfs/public
sudo mkdir -p /mnt/cephfs/restricted
sudo mkdir -p /mnt/cephfs/admin-only
Create specialized client keys with restricted access:
# Client with read-only access to public directory
sudo ceph auth get-or-create client.readonly mon 'allow r' mds 'allow r path=/public' osd 'allow r pool=cephfs_data' -o /etc/ceph/ceph.client.readonly.keyring

# Client with read-write access to restricted directory
sudo ceph auth get-or-create client.restricted mon 'allow r' mds 'allow rw path=/restricted' osd 'allow rw pool=cephfs_data' -o /etc/ceph/ceph.client.restricted.keyring

# Admin client with full access
sudo ceph auth get-or-create client.admin mon 'allow *' mds 'allow *' osd 'allow *' -o /etc/ceph/ceph.client.admin.keyring
Set proper permissions on keyrings:
sudo chmod 600 /etc/ceph/ceph.client.*.keyring
Test restricted access:
# Create test mount points
sudo mkdir -p /mnt/readonly /mnt/restricted

# Mount with readonly client
sudo mount -t ceph ceph-node1:6789,ceph-node2:6789,ceph-node3:6789:/public /mnt/readonly -o name=readonly,secretfile=/etc/ceph/ceph.client.readonly.keyring

# Test readonly access
echo "Public content" | sudo tee /mnt/cephfs/public/public-file.txt
cat /mnt/readonly/public-file.txt
Subtask 3.2: Configure CephFS Quotas
Enable quota support:
sudo ceph config set mds mds_enforce_unique_name false
sudo ceph config set client client_quota true
Set directory quotas:
# Set 1GB quota on restricted directory
sudo setfattr -n ceph.quota.max_bytes -v 1073741824 /mnt/cephfs/restricted

# Set file count quota
sudo setfattr -n ceph.quota.max_files -v 1000 /mnt/cephfs/restricted
Verify quota settings:
getfattr -n ceph.quota.max_bytes /mnt/cephfs/restricted
getfattr -n ceph.quota.max_files /mnt/cephfs/restricted
Test quota enforcement:
# Create test files to approach quota
sudo mkdir -p /mnt/cephfs/restricted/quota-test
for i in {1..10}; do
    sudo dd if=/dev/zero of=/mnt/cephfs/restricted/quota-test/file$i.dat bs=1M count=50
done
Subtask 3.3: Configure and Manage Snapshots
Enable snapshot functionality:
sudo ceph config set mds mds_allow_new_snaps true
sudo ceph config set client client_permissions true
Create snapshot directories:
sudo mkdir -p /mnt/cephfs/data-to-snapshot
echo "Original data before snapshot" | sudo tee /mnt/cephfs/data-to-snapshot/important-file.txt
Create manual snapshots:
# Create snapshot directory (hidden .snap directory)
sudo mkdir /mnt/cephfs/data-to-snapshot/.snap/snapshot-$(date +%Y%m%d-%H%M%S)
Verify snapshot creation:
ls -la /mnt/cephfs/data-to-snapshot/.snap/
Test snapshot functionality:
# Modify original file
echo "Modified data after snapshot" | sudo tee /mnt/cephfs/data-to-snapshot/important-file.txt

# Compare with snapshot
SNAPSHOT_NAME=$(ls /mnt/cephfs/data-to-snapshot/.snap/ | head -1)
cat /mnt/cephfs/data-to-snapshot/.snap/$SNAPSHOT_NAME/important-file.txt
cat /mnt/cephfs/data-to-snapshot/important-file.txt
Subtask 3.4: Automated Snapshot Management
Create snapshot management script:
sudo tee /usr/local/bin/cephfs-snapshot.sh << 'EOF'
#!/bin/bash
# CephFS Snapshot Management Script

CEPHFS_PATH="/mnt/cephfs"
SNAPSHOT_DIR="$1"
ACTION="$2"

usage() {
    echo "Usage: $0 <directory> <create|list|cleanup>"
    echo "  create  - Create new snapshot"
    echo "  list    - List existing snapshots"
    echo "  cleanup - Remove snapshots older than 7 days"
    exit 1
}

create_snapshot() {
    local dir="$CEPHFS_PATH/$SNAPSHOT_DIR"
    local snap_name="snapshot-$(date +%Y%m%d-%H%M%S)"
    
    if [ ! -d "$dir" ]; then
        echo "Directory $dir does not exist"
        exit 1
    fi
    
    mkdir "$dir/.snap/$snap_name"
    echo "Snapshot created: $snap_name"
}

list_snapshots() {
    local dir="$CEPHFS_PATH/$SNAPSHOT_DIR"
    echo "Snapshots for $SNAPSHOT_DIR:"
    ls -la "$dir/.snap/" 2>/dev/null || echo "No snapshots found"
}

cleanup_snapshots() {
    local dir="$CEPHFS_PATH/$SNAPSHOT_DIR"
    local snap_dir="$dir/.snap"
    
    if [ -d "$snap_dir" ]; then
        find "$snap_dir" -maxdepth 1 -type d -mtime +7 -exec rmdir {} \; 2>/dev/null
        echo "Cleaned up snapshots older than 7 days"
    fi
}

case "$ACTION" in
    create)
        create_snapshot
        ;;
    list)
        list_snapshots
        ;;
    cleanup)
        cleanup_snapshots
        ;;
    *)
        usage
        ;;
esac
EOF
Make script executable:
sudo chmod +x /usr/local/bin/cephfs-snapshot.sh
Test snapshot script:
# Create snapshot
sudo /usr/local/bin/cephfs-snapshot.sh data-to-snapshot create

# List snapshots
sudo /usr/local/bin/cephfs-snapshot.sh data-to-snapshot list
Schedule automated snapshots with cron:
# Add cron job for daily snapshots
echo "0 2 * * * root /usr/local/bin/cephfs-snapshot.sh data-to-snapshot create" | sudo tee -a /etc/crontab

# Add weekly cleanup
echo "0 3 * * 0 root /usr/local/bin/cephfs-snapshot.sh data-to-snapshot cleanup" | sudo tee -a /etc/crontab
Troubleshooting Common Issues
MDS Issues
MDS fails to start:
# Check logs
sudo journalctl -u ceph-mds@ceph-node1 -f

# Verify keyring permissions
ls -la /var/lib/ceph/mds/ceph-mds.ceph-node1/keyring

# Check cluster connectivity
sudo ceph health detail
MDS in damaged state:
# Reset MDS
sudo ceph mds fail ceph-node1
sudo systemctl restart ceph-mds@ceph-node1
Mount Issues
Mount fails with permission denied:
# Check client keyring
sudo ceph auth list | grep client.cephfs

# Verify MON connectivity
telnet ceph-node1 6789
Performance issues:
# Check MDS performance
sudo ceph daemon mds.ceph-node1 perf dump

# Monitor client operations
sudo ceph daemon mds.ceph-node1 dump_ops_in_flight
Snapshot Issues
Snapshots not working:
# Verify snapshot settings
sudo ceph config get mds mds_allow_new_snaps

# Check directory permissions
ls -la /mnt/cephfs/data-to-snapshot/
Performance Optimization Tips
Tune MDS cache size:
sudo ceph config set mds mds_cache_memory_limit 4294967296
Optimize client cache:
sudo ceph config set client client_cache_size 16777216
Monitor performance metrics:
sudo ceph daemon mds.ceph-node1 perf dump | grep -E "(request|cache|session)"
Conclusion
In this comprehensive lab, you have successfully:

Deployed MDS services for CephFS metadata management with high availability configuration
Created and mounted CephFS volumes using both kernel and FUSE clients
Implemented access control mechanisms including directory-based permissions and client authentication
Configured quota management to control storage usage
Set up snapshot functionality with both manual and automated snapshot management
Why This Matters: CephFS provides a POSIX-compliant distributed file system that enables organizations to:

Scale file storage horizontally across multiple nodes
Ensure high availability through redundant metadata servers
Implement granular access control for security compliance
Protect data through snapshot capabilities
Optimize performance through intelligent caching and load balancing
These skills are essential for managing enterprise-scale file storage solutions and are directly applicable to the Red Hat Certified Specialist in Ceph Cloud Storage certification. The hands-on experience gained in this lab prepares you to deploy and manage CephFS in production environments, handling real-world scenarios such as user access management, data protection, and performance optimization.

Next Steps: Consider exploring advanced CephFS features such as multi-filesystem deployments, disaster recovery configurations, and integration with container orchestration platforms like Kubernetes for cloud-native applications.
