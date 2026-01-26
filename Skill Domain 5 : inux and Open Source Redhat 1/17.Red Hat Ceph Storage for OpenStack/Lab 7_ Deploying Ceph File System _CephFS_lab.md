Lab 7: Deploying Ceph File System (CephFS)
Objectives
By the end of this lab, you will be able to:

Understand the architecture and components of Ceph File System (CephFS)
Deploy and configure Metadata Servers (MDS) for CephFS
Create and mount CephFS volumes on client systems
Perform file system operations including creating, reading, and modifying files
Manage CephFS permissions and access controls
Monitor and troubleshoot CephFS deployments
Implement best practices for CephFS in production environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux file systems and storage concepts
Familiarity with Ceph cluster architecture (RADOS, OSDs, Monitors)
Knowledge of Linux command-line operations
Understanding of network file systems concepts
Completion of previous Ceph labs or equivalent experience with Ceph cluster deployment
Basic knowledge of POSIX file system semantics
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

3 Ceph Monitor nodes (ceph-mon1, ceph-mon2, ceph-mon3)
6 Ceph OSD nodes with storage devices
2 Metadata Server nodes (ceph-mds1, ceph-mds2)
2 Client nodes for mounting CephFS
Pre-installed Ceph cluster (Quincy release)
Network connectivity between all nodes
Task 1: Set up MDS (Metadata Server) for CephFS
Subtask 1.1: Verify Ceph Cluster Health
Before deploying CephFS, ensure your Ceph cluster is healthy and operational.

Connect to the Ceph admin node:
# Check cluster status
sudo ceph status

# Verify all OSDs are up and in
sudo ceph osd status

# Check monitor quorum
sudo ceph mon status
Verify minimum requirements for CephFS:
# CephFS requires at least 2 data pools and 1 metadata pool
# Check existing pools
sudo ceph osd lspools

# Verify we have sufficient OSDs (minimum 3 for production)
sudo ceph osd tree
Subtask 1.2: Create Required Pools for CephFS
CephFS requires separate pools for data and metadata storage.

Create the metadata pool:
# Create metadata pool with appropriate PG count
sudo ceph osd pool create cephfs_metadata 32 32

# Set the pool application type
sudo ceph osd pool application enable cephfs_metadata cephfs
Create the data pool:
# Create data pool with higher PG count for better distribution
sudo ceph osd pool create cephfs_data 128 128

# Set the pool application type
sudo ceph osd pool application enable cephfs_data cephfs
Verify pool creation:
# List all pools
sudo ceph osd lspools

# Check pool statistics
sudo ceph df
Subtask 1.3: Deploy Metadata Servers
Install MDS packages on designated nodes:
# On ceph-mds1 and ceph-mds2 nodes
sudo apt update
sudo apt install -y ceph-mds

# Or for RHEL/CentOS systems:
# sudo yum install -y ceph-mds
Create MDS authentication keys:
# On the admin node, create keys for each MDS
sudo ceph auth get-or-create mds.ceph-mds1 mon 'allow profile mds' osd 'allow rwx' mgh 'allow profile mds'
sudo ceph auth get-or-create mds.ceph-mds2 mon 'allow profile mds' osd 'allow rwx' mgh 'allow profile mds'

# Export the keys
sudo ceph auth get mds.ceph-mds1 -o /etc/ceph/ceph.mds.ceph-mds1.keyring
sudo ceph auth get mds.ceph-mds2 -o /etc/ceph/ceph.mds.ceph-mds2.keyring
Copy configuration and keys to MDS nodes:
# Copy to ceph-mds1
sudo scp /etc/ceph/ceph.conf ceph-mds1:/etc/ceph/
sudo scp /etc/ceph/ceph.mds.ceph-mds1.keyring ceph-mds1:/etc/ceph/

# Copy to ceph-mds2
sudo scp /etc/ceph/ceph.conf ceph-mds2:/etc/ceph/
sudo scp /etc/ceph/ceph.mds.ceph-mds2.keyring ceph-mds2:/etc/ceph/
Start MDS services:
# On ceph-mds1
sudo systemctl enable ceph-mds@ceph-mds1
sudo systemctl start ceph-mds@ceph-mds1

# On ceph-mds2
sudo systemctl enable ceph-mds@ceph-mds2
sudo systemctl start ceph-mds@ceph-mds2
Verify MDS deployment:
# Check MDS status
sudo ceph mds stat

# List MDS daemons
sudo ceph fs dump
Subtask 1.4: Create the CephFS File System
Create the file system:
# Create CephFS with metadata and data pools
sudo ceph fs new myfs cephfs_metadata cephfs_data

# Verify file system creation
sudo ceph fs ls
Check file system status:
# View detailed file system information
sudo ceph fs status myfs

# Check MDS status for the file system
sudo ceph mds stat
Configure MDS settings (optional):
# Set maximum number of active MDS (for high availability)
sudo ceph fs set myfs max_mds 2

# Set standby replay MDS
sudo ceph fs set myfs allow_standby_replay true
Task 2: Create and Mount a CephFS Volume
Subtask 2.1: Prepare Client Nodes
Install CephFS client packages:
# On client nodes
sudo apt update
sudo apt install -y ceph-fuse

# Or for kernel client:
sudo apt install -y ceph-common

# For RHEL/CentOS:
# sudo yum install -y ceph-fuse ceph-common
Create client authentication:
# On admin node, create client key
sudo ceph auth get-or-create client.cephfs mon 'allow r' mds 'allow rw' osd 'allow rw pool=cephfs_data'

# Export client keyring
sudo ceph auth get client.cephfs -o /etc/ceph/ceph.client.cephfs.keyring
Copy configuration to client nodes:
# Copy configuration and keyring to clients
sudo scp /etc/ceph/ceph.conf client1:/etc/ceph/
sudo scp /etc/ceph/ceph.client.cephfs.keyring client1:/etc/ceph/

sudo scp /etc/ceph/ceph.conf client2:/etc/ceph/
sudo scp /etc/ceph/ceph.client.cephfs.keyring client2:/etc/ceph/
Subtask 2.2: Mount CephFS Using Kernel Client
Create mount point:
# On client node
sudo mkdir -p /mnt/cephfs
Mount using kernel client:
# Get monitor addresses
MONITORS=$(sudo ceph mon dump | grep "mon\." | awk '{print $2}' | cut -d'/' -f1 | paste -sd,)

# Mount CephFS
sudo mount -t ceph $MONITORS:/ /mnt/cephfs -o name=cephfs,secretfile=/etc/ceph/ceph.client.cephfs.keyring
Verify mount:
# Check if mounted
df -h /mnt/cephfs

# List mount details
mount | grep cephfs
Create persistent mount:
# Add to /etc/fstab for persistent mounting
echo "$MONITORS:/ /mnt/cephfs ceph name=cephfs,secretfile=/etc/ceph/ceph.client.cephfs.keyring,_netdev 0 0" | sudo tee -a /etc/fstab
Subtask 2.3: Mount CephFS Using FUSE Client
Create alternative mount point:
sudo mkdir -p /mnt/cephfs-fuse
Mount using FUSE client:
# Mount with ceph-fuse
sudo ceph-fuse /mnt/cephfs-fuse --name client.cephfs --keyring /etc/ceph/ceph.client.cephfs.keyring
Verify FUSE mount:
# Check mount
df -h /mnt/cephfs-fuse

# Test FUSE functionality
ls -la /mnt/cephfs-fuse
Subtask 2.4: Create Subdirectories and Test Basic Operations
Create directory structure:
# Create test directories
sudo mkdir -p /mnt/cephfs/projects/{project1,project2,shared}
sudo mkdir -p /mnt/cephfs/users/{alice,bob,charlie}
sudo mkdir -p /mnt/cephfs/backup
Test file operations:
# Create test files
echo "Hello CephFS!" | sudo tee /mnt/cephfs/test.txt
echo "Project 1 data" | sudo tee /mnt/cephfs/projects/project1/data.txt
echo "Shared resources" | sudo tee /mnt/cephfs/projects/shared/readme.txt
Verify file system functionality:
# List directory contents
ls -la /mnt/cephfs/
ls -la /mnt/cephfs/projects/

# Read file contents
cat /mnt/cephfs/test.txt
cat /mnt/cephfs/projects/project1/data.txt
Task 3: Perform File System Operations and Manage Permissions
Subtask 3.1: Advanced File Operations
Create large files for testing:
# Create files of different sizes
sudo dd if=/dev/zero of=/mnt/cephfs/large_file_1MB bs=1M count=1
sudo dd if=/dev/zero of=/mnt/cephfs/large_file_10MB bs=1M count=10
sudo dd if=/dev/zero of=/mnt/cephfs/large_file_100MB bs=1M count=100
Test file copying and moving:
# Copy files
sudo cp /mnt/cephfs/large_file_1MB /mnt/cephfs/backup/
sudo cp /mnt/cephfs/projects/project1/data.txt /mnt/cephfs/projects/project2/

# Move files
sudo mv /mnt/cephfs/large_file_10MB /mnt/cephfs/projects/shared/
Test symbolic and hard links:
# Create symbolic links
sudo ln -s /mnt/cephfs/projects/shared/readme.txt /mnt/cephfs/shared_link
sudo ln -s /mnt/cephfs/projects /mnt/cephfs/project_link

# Create hard links
sudo ln /mnt/cephfs/test.txt /mnt/cephfs/test_hardlink.txt
Verify link functionality:
# Check links
ls -la /mnt/cephfs/ | grep link
readlink /mnt/cephfs/shared_link
Subtask 3.2: User and Group Management
Create test users and groups:
# Create groups
sudo groupadd cephfs_users
sudo groupadd project1_team
sudo groupadd project2_team

# Create users
sudo useradd -m -g cephfs_users -s /bin/bash alice
sudo useradd -m -g cephfs_users -s /bin/bash bob
sudo useradd -m -g cephfs_users -s /bin/bash charlie

# Add users to project groups
sudo usermod -a -G project1_team alice
sudo usermod -a -G project1_team bob
sudo usermod -a -G project2_team charlie
Set directory ownership:
# Set ownership for user directories
sudo chown alice:cephfs_users /mnt/cephfs/users/alice
sudo chown bob:cephfs_users /mnt/cephfs/users/bob
sudo chown charlie:cephfs_users /mnt/cephfs/users/charlie

# Set ownership for project directories
sudo chown root:project1_team /mnt/cephfs/projects/project1
sudo chown root:project2_team /mnt/cephfs/projects/project2
sudo chown root:cephfs_users /mnt/cephfs/projects/shared
Subtask 3.3: Configure File System Permissions
Set basic permissions:
# Set permissions for user directories (owner full access, group read, others none)
sudo chmod 750 /mnt/cephfs/users/alice
sudo chmod 750 /mnt/cephfs/users/bob
sudo chmod 750 /mnt/cephfs/users/charlie

# Set permissions for project directories
sudo chmod 770 /mnt/cephfs/projects/project1  # Group collaboration
sudo chmod 770 /mnt/cephfs/projects/project2
sudo chmod 775 /mnt/cephfs/projects/shared     # Shared access
Set up Access Control Lists (ACLs):
# Install ACL tools if not present
sudo apt install -y acl

# Set ACLs for fine-grained permissions
sudo setfacl -m g:project1_team:rwx /mnt/cephfs/projects/project1
sudo setfacl -m g:project2_team:rwx /mnt/cephfs/projects/project2
sudo setfacl -m g:cephfs_users:rx /mnt/cephfs/projects/shared

# Set default ACLs for new files
sudo setfacl -d -m g:project1_team:rwx /mnt/cephfs/projects/project1
sudo setfacl -d -m g:project2_team:rwx /mnt/cephfs/projects/project2
Verify ACL settings:
# Check ACLs
getfacl /mnt/cephfs/projects/project1
getfacl /mnt/cephfs/projects/project2
getfacl /mnt/cephfs/projects/shared
Subtask 3.4: Test Permission Enforcement
Test user access as alice:
# Switch to alice user
sudo -u alice bash

# Test access to own directory
echo "Alice's data" > /mnt/cephfs/users/alice/personal.txt
ls -la /mnt/cephfs/users/alice/

# Test access to project1 (should work)
echo "Alice project1 work" > /mnt/cephfs/projects/project1/alice_work.txt

# Test access to project2 (should fail)
echo "Alice project2 work" > /mnt/cephfs/projects/project2/alice_work.txt 2>&1 || echo "Access denied as expected"

# Exit alice session
exit
Test user access as charlie:
# Switch to charlie user
sudo -u charlie bash

# Test access to project2 (should work)
echo "Charlie project2 work" > /mnt/cephfs/projects/project2/charlie_work.txt

# Test access to project1 (should fail)
echo "Charlie project1 work" > /mnt/cephfs/projects/project1/charlie_work.txt 2>&1 || echo "Access denied as expected"

# Test shared directory access
echo "Charlie shared content" > /mnt/cephfs/projects/shared/charlie_shared.txt

# Exit charlie session
exit
Subtask 3.5: Monitor File System Usage and Performance
Check file system statistics:
# Check CephFS usage
sudo ceph fs status myfs

# Check detailed statistics
sudo ceph daemonperf mds.ceph-mds1

# Monitor MDS performance
sudo ceph tell mds.ceph-mds1 perf dump
Monitor client connections:
# List connected clients
sudo ceph tell mds.ceph-mds1 client ls

# Check session information
sudo ceph tell mds.ceph-mds1 session ls
Check pool usage:
# Check pool statistics
sudo ceph df detail

# Check specific pool usage
sudo ceph osd pool stats cephfs_data
sudo ceph osd pool stats cephfs_metadata
Subtask 3.6: Implement Quotas and Limits
Set directory quotas:
# Set quota on user directories (100MB limit)
sudo setfattr -n ceph.quota.max_bytes -v 104857600 /mnt/cephfs/users/alice
sudo setfattr -n ceph.quota.max_bytes -v 104857600 /mnt/cephfs/users/bob
sudo setfattr -n ceph.quota.max_bytes -v 104857600 /mnt/cephfs/users/charlie

# Set file count quota (1000 files)
sudo setfattr -n ceph.quota.max_files -v 1000 /mnt/cephfs/users/alice
Set project directory quotas:
# Set larger quotas for project directories (1GB)
sudo setfattr -n ceph.quota.max_bytes -v 1073741824 /mnt/cephfs/projects/project1
sudo setfattr -n ceph.quota.max_bytes -v 1073741824 /mnt/cephfs/projects/project2
Verify quota settings:
# Check quota attributes
getfattr -n ceph.quota.max_bytes /mnt/cephfs/users/alice
getfattr -n ceph.quota.max_files /mnt/cephfs/users/alice
getfattr -n ceph.quota.max_bytes /mnt/cephfs/projects/project1
Test quota enforcement:
# Test quota by creating large file as alice
sudo -u alice dd if=/dev/zero of=/mnt/cephfs/users/alice/large_test bs=1M count=200 2>&1 || echo "Quota limit reached"
Troubleshooting Common Issues
Issue 1: MDS Fails to Start
Symptoms: MDS daemon won't start or crashes immediately

Solutions:

# Check MDS logs
sudo journalctl -u ceph-mds@ceph-mds1 -f

# Verify authentication
sudo ceph auth list | grep mds

# Check network connectivity
sudo ceph -s
Issue 2: Mount Fails
Symptoms: Cannot mount CephFS on client

Solutions:

# Check monitor connectivity
sudo ceph mon stat

# Verify client authentication
sudo ceph auth get client.cephfs

# Check network connectivity to monitors
telnet <monitor-ip> 6789
Issue 3: Permission Denied Errors
Symptoms: Users cannot access files despite correct permissions

Solutions:

# Check file ownership and permissions
ls -la /mnt/cephfs/path/to/file

# Verify ACLs
getfacl /mnt/cephfs/path/to/directory

# Check user group membership
groups username
Issue 4: Poor Performance
Symptoms: Slow file operations

Solutions:

# Check MDS performance
sudo ceph tell mds.ceph-mds1 perf dump

# Monitor OSD performance
sudo ceph osd perf

# Check network latency
ping <mds-node-ip>
Best Practices and Security Considerations
Security Best Practices
Use separate client keys for different access levels:
# Create read-only client
sudo ceph auth get-or-create client.readonly mon 'allow r' mds 'allow r' osd 'allow r pool=cephfs_data'

# Create admin client with full access
sudo ceph auth get-or-create client.admin mon 'allow *' mds 'allow *' osd 'allow *'
Implement network security:
# Configure firewall rules (example for iptables)
sudo iptables -A INPUT -p tcp --dport 6800:7300 -s <trusted-network> -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 6800:7300 -j DROP
Regular security audits:
# Review client connections
sudo ceph tell mds.ceph-mds1 client ls

# Check authentication keys
sudo ceph auth list
Performance Optimization
Tune MDS cache settings:
# Increase MDS cache size for better performance
sudo ceph tell mds.ceph-mds1 config set mds_cache_memory_limit 4294967296  # 4GB
Optimize client settings:
# Mount with performance options
sudo mount -t ceph $MONITORS:/ /mnt/cephfs -o name=cephfs,secretfile=/etc/ceph/ceph.client.cephfs.keyring,cache=strict,fsc
Conclusion
In this comprehensive lab, you have successfully:

Deployed a complete CephFS infrastructure including Metadata Servers (MDS) and the necessary storage pools
Created and configured a distributed file system that provides POSIX-compliant shared storage across multiple clients
Implemented advanced permission management using traditional Unix permissions, ACLs, and CephFS-specific features like quotas
Tested file system operations including file creation, copying, linking, and access control enforcement
Learned troubleshooting techniques for common CephFS deployment and operational issues
Why This Matters: CephFS provides a scalable, distributed file system solution that is essential for modern cloud and enterprise environments. The skills you've developed enable you to:

Deploy shared storage solutions for containerized applications and traditional workloads
Implement secure, multi-tenant file sharing in cloud environments
Provide high-performance, fault-tolerant storage for HPC and big data applications
Support backup and archival systems with unlimited scalability
Real-World Applications: The CephFS deployment skills from this lab are directly applicable to:

OpenStack environments where CephFS serves as shared storage for instances
Kubernetes clusters using CephFS as a persistent volume provider
Enterprise file sharing replacing traditional NAS solutions
Research computing providing shared storage for scientific workloads
Media and content management systems requiring high-throughput file access
The combination of CephFS with proper permission management and monitoring creates a production-ready shared storage solution that can scale from small teams to enterprise-wide deployments. These skills are highly valued in cloud infrastructure, DevOps, and storage administration roles.
