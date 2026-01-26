Lab 1: Introduction to Red Hat Ceph Storage
Lab Objectives
By the end of this lab, students will be able to:

Understand the fundamental concepts and architecture of Red Hat Ceph Storage
Identify and explain the roles of core Ceph components: OSDs, MONs, MDS, and MGR
Analyze Ceph's distributed storage architecture and data flow mechanisms
Deploy a basic Ceph cluster using open-source tools
Perform basic operations to validate cluster functionality
Troubleshoot common Ceph deployment issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with storage concepts (block, object, and file storage)
Knowledge of distributed systems fundamentals
Understanding of network configuration basics
Experience with SSH and remote server management
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure hardware.

Your lab environment includes:

4 CentOS Stream 9 virtual machines
Pre-installed Ceph packages and dependencies
Network connectivity between all nodes
Root access to all systems
Task 1: Understanding Ceph Components and Architecture
Subtask 1.1: Explore Ceph Architecture Overview
Step 1: Access your lab environment and connect to the first node

# Connect to your primary node (node1)
ssh root@node1
Step 2: Review the Ceph architecture documentation

# Install documentation packages
dnf install -y ceph-common

# View Ceph version and basic information
ceph --version
Step 3: Understand the core components by examining the system

# Check available Ceph services
systemctl list-unit-files | grep ceph
Subtask 1.2: Learn About Object Storage Daemons (OSDs)
Object Storage Daemons (OSDs) are the heart of Ceph storage. They store data, handle replication, recovery, and provide storage capacity to the cluster.

Step 1: Examine OSD concepts

# Create a directory to understand OSD structure
mkdir -p /tmp/ceph-learning/osd-example
cd /tmp/ceph-learning/osd-example

# Create example files to understand data distribution
echo "Understanding OSDs: These daemons store actual data objects" > osd-info.txt
cat osd-info.txt
Step 2: Review OSD responsibilities

# Create a summary of OSD functions
cat << EOF > osd-functions.txt
OSD (Object Storage Daemon) Functions:
1. Store data objects on local storage devices
2. Handle data replication across the cluster
3. Perform data recovery and backfilling
4. Execute data scrubbing for consistency
5. Provide storage capacity metrics
6. Handle client I/O operations
EOF

cat osd-functions.txt
Subtask 1.3: Understand Monitor Daemons (MONs)
Monitor Daemons (MONs) maintain the cluster map and provide consensus for distributed decision-making.

Step 1: Learn about Monitor functions

# Create MON information file
cat << EOF > mon-functions.txt
MON (Monitor Daemon) Functions:
1. Maintain cluster map (monitor map, OSD map, PG map, CRUSH map)
2. Provide cluster state information to clients and OSDs
3. Handle authentication and authorization
4. Maintain quorum for cluster decisions
5. Store cluster configuration and metadata
EOF

cat mon-functions.txt
Step 2: Understand quorum concepts

# Create quorum explanation
cat << EOF > quorum-concept.txt
Ceph Monitor Quorum:
- Requires odd number of monitors (1, 3, 5, etc.)
- Majority must be available for cluster operations
- Prevents split-brain scenarios
- Recommended: 3 monitors for production
EOF

cat quorum-concept.txt
Subtask 1.4: Explore Metadata Server (MDS) Role
Metadata Servers (MDS) manage metadata for CephFS (Ceph File System).

Step 1: Understand MDS functionality

# Create MDS information file
cat << EOF > mds-functions.txt
MDS (Metadata Server) Functions:
1. Manage file system metadata for CephFS
2. Handle directory operations and file attributes
3. Provide POSIX-compliant file system interface
4. Cache metadata for performance
5. Support multiple active MDS for scalability
Note: Only required for CephFS, not for RBD or RGW
EOF

cat mds-functions.txt
Subtask 1.5: Learn About Manager Daemons (MGR)
Manager Daemons (MGR) provide additional monitoring and management capabilities.

Step 1: Explore MGR functions

# Create MGR information file
cat << EOF > mgr-functions.txt
MGR (Manager Daemon) Functions:
1. Collect and provide cluster metrics
2. Host web-based dashboard interface
3. Provide REST API for management
4. Execute management modules and plugins
5. Handle telemetry and monitoring integration
6. Support for external monitoring systems
EOF

cat mgr-functions.txt
Task 2: Exploring Ceph Architecture and Data Flow
Subtask 2.1: Understand CRUSH Algorithm
Step 1: Learn about CRUSH (Controlled Replication Under Scalable Hashing)

# Create CRUSH explanation
cat << EOF > crush-algorithm.txt
CRUSH Algorithm Concepts:
1. Deterministic data placement algorithm
2. Eliminates need for centralized metadata lookup
3. Calculates object location based on cluster map
4. Supports hierarchical storage organization
5. Enables intelligent data placement policies
6. Provides failure domain isolation
EOF

cat crush-algorithm.txt
Step 2: Understand placement groups

# Create placement group explanation
cat << EOF > placement-groups.txt
Placement Groups (PGs):
1. Logical grouping of objects for management
2. Intermediate layer between objects and OSDs
3. Enable efficient replication and recovery
4. Reduce metadata overhead
5. Typical calculation: (OSDs * 100) / replica_count
6. Must be power of 2 for optimal distribution
EOF

cat placement-groups.txt
Subtask 2.2: Analyze Data Flow Architecture
Step 1: Create data flow diagram explanation

# Create data flow explanation
cat << EOF > data-flow.txt
Ceph Data Flow Process:
1. Client requests data operation
2. Client calculates object location using CRUSH
3. Client contacts primary OSD directly
4. Primary OSD handles replication to secondary OSDs
5. Primary OSD confirms write completion
6. Client receives acknowledgment

Benefits:
- No single point of failure
- Direct client-to-OSD communication
- Eliminates metadata bottlenecks
- Scales horizontally
EOF

cat data-flow.txt
Step 2: Understand storage interfaces

# Create storage interfaces explanation
cat << EOF > storage-interfaces.txt
Ceph Storage Interfaces:
1. RADOS Block Device (RBD) - Block storage
   - Virtual disk images
   - Snapshot and cloning support
   - Integration with OpenStack, Kubernetes

2. RADOS Gateway (RGW) - Object storage
   - S3 and Swift API compatibility
   - Multi-tenancy support
   - Bucket and object management

3. CephFS - File system
   - POSIX-compliant distributed file system
   - Multiple mount points
   - Snapshot support
EOF

cat storage-interfaces.txt
Task 3: Deploying a Basic Ceph Cluster
Subtask 3.1: Prepare Cluster Nodes
Step 1: Configure all nodes for Ceph deployment

# Run on all nodes (node1, node2, node3, node4)
# Update system packages
dnf update -y

# Install required packages
dnf install -y python3 python3-pip chrony

# Configure time synchronization
systemctl enable --now chronyd

# Verify time sync
chrony sources -v
Step 2: Configure SSH key authentication

# Generate SSH key on node1 (if not exists)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Copy SSH key to all nodes
for node in node1 node2 node3 node4; do
    ssh-copy-id root@$node
done

# Test SSH connectivity
for node in node1 node2 node3 node4; do
    ssh root@$node "hostname"
done
Subtask 3.2: Install Ceph Using Cephadm
Step 1: Install cephadm bootstrap tool

# Install cephadm on node1
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
chmod +x cephadm
./cephadm add-repo --release quincy
./cephadm install
Step 2: Bootstrap the Ceph cluster

# Bootstrap cluster on node1
cephadm bootstrap --mon-ip $(hostname -I | awk '{print $1}')

# Note the admin credentials displayed after bootstrap
# Save the dashboard URL and password
Step 3: Verify initial cluster status

# Check cluster status
ceph status

# View cluster health
ceph health detail

# List available commands
ceph --help
Subtask 3.3: Add Additional Nodes
Step 1: Add remaining nodes to the cluster

# Get the join command from bootstrap output or generate new one
ceph cephadm get-pub-key > ~/ceph.pub
ssh-copy-id -f -i ~/ceph.pub root@node2
ssh-copy-id -f -i ~/ceph.pub root@node3
ssh-copy-id -f -i ~/ceph.pub root@node4

# Add nodes to cluster
ceph orch host add node2
ceph orch host add node3
ceph orch host add node4

# Verify hosts
ceph orch host ls
Step 2: Deploy additional monitors

# Deploy monitors on additional nodes
ceph orch apply mon --placement="node1,node2,node3"

# Verify monitor deployment
ceph mon stat
ceph quorum_status
Subtask 3.4: Configure OSDs
Step 1: Identify available storage devices

# List available devices on all nodes
ceph orch device ls

# Check device details
for node in node1 node2 node3 node4; do
    echo "=== $node ==="
    ssh root@$node "lsblk"
done
Step 2: Create OSDs on available devices

# Create OSDs on all available devices
ceph orch apply osd --all-available-devices

# Or create OSDs on specific devices
# ceph orch daemon add osd node1:/dev/sdb
# ceph orch daemon add osd node2:/dev/sdb

# Monitor OSD creation progress
watch ceph orch ps
Step 3: Verify OSD deployment

# Check OSD status
ceph osd status
ceph osd tree
ceph osd df

# Verify cluster health
ceph status
Subtask 3.5: Deploy Manager Daemons
Step 1: Deploy additional manager daemons

# Deploy managers for high availability
ceph orch apply mgr --placement="node1,node2"

# Verify manager deployment
ceph mgr stat
ceph orch ps --daemon-type mgr
Step 2: Enable useful manager modules

# Enable dashboard module
ceph mgr module enable dashboard

# Enable other useful modules
ceph mgr module enable prometheus
ceph mgr module enable alerts

# List enabled modules
ceph mgr module ls
Task 4: Validating Cluster Operations
Subtask 4.1: Test Basic Cluster Operations
Step 1: Create a test pool

# Create a test pool
ceph osd pool create testpool 32 32

# List pools
ceph osd lspools

# Get pool information
ceph osd pool get testpool all
Step 2: Test object operations

# Put an object in the pool
echo "Hello Ceph Storage!" > test-object.txt
rados -p testpool put test-object test-object.txt

# List objects in pool
rados -p testpool ls

# Get object from pool
rados -p testpool get test-object retrieved-object.txt
cat retrieved-object.txt

# Verify object placement
ceph osd map testpool test-object
Subtask 4.2: Monitor Cluster Health
Step 1: Check comprehensive cluster status

# Detailed cluster status
ceph status
ceph health detail

# Check cluster capacity
ceph df
ceph osd df

# Monitor cluster performance
ceph osd perf
Step 2: Access Ceph Dashboard

# Get dashboard URL
ceph mgr services

# Reset dashboard password if needed
ceph dashboard ac-user-set-password admin <new-password>

# Create dashboard user (if needed)
ceph dashboard ac-user-create monitoring viewer

echo "Access the dashboard using the URL and credentials shown above"
Troubleshooting Common Issues
Issue 1: Time Synchronization Problems
# Check time sync status
timedatectl status
chrony sources -v

# Restart chronyd if needed
systemctl restart chronyd
Issue 2: Network Connectivity Issues
# Test network connectivity between nodes
for node in node1 node2 node3 node4; do
    ping -c 3 $node
done

# Check firewall status
systemctl status firewalld
# If firewall is active, configure Ceph ports
Issue 3: Insufficient Storage Space
# Check available disk space
df -h
lsblk

# Clean up if needed
ceph tell osd.* injectargs --osd-max-pg-log-entries=10
Issue 4: OSD Creation Failures
# Check OSD creation logs
ceph orch ps --daemon-type osd
ceph log last cephadm

# Manually clean device if needed
ceph orch device zap <node>:<device> --force
Lab Summary and Cleanup
Subtask 5.1: Review What You've Accomplished
In this lab, you have successfully:

Learned Ceph Architecture: Understood the roles of OSDs (data storage), MONs (cluster state), MDS (file system metadata), and MGR (management and monitoring)

Explored Data Flow: Analyzed how CRUSH algorithm enables direct client-to-OSD communication without centralized bottlenecks

Deployed Ceph Cluster: Built a functional multi-node Ceph cluster using modern cephadm deployment tools

Validated Operations: Tested basic storage operations and verified cluster health

Subtask 5.2: Clean Up Resources (Optional)
# Remove test objects and pools
rados -p testpool rm test-object
ceph osd pool delete testpool testpool --yes-i-really-really-mean-it

# View final cluster status
ceph status
Key Takeaways
Ceph provides unified storage: Block (RBD), Object (RGW), and File (CephFS) storage from a single cluster
No single point of failure: Distributed architecture with intelligent data placement
Self-healing: Automatic data recovery and rebalancing
Scalable: Add nodes and storage capacity without downtime
Open source: Enterprise-grade storage without vendor lock-in
This foundational knowledge prepares you for advanced Ceph operations, integration with OpenStack, and production deployment scenarios. The skills learned here are directly applicable to Red Hat Ceph Storage certification objectives and real-world storage infrastructure management.

Next Steps
Continue your Ceph learning journey by exploring:

Advanced CRUSH map customization
RBD block device operations
CephFS file system deployment
RADOS Gateway object storage configuration
Performance tuning and optimization
Integration with container orchestration platforms
