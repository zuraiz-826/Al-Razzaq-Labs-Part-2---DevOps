Lab 4: Understanding and Using RADOS
Objectives
By the end of this lab, students will be able to:

Understand the fundamental concepts of RADOS (Reliable Autonomic Distributed Object Store)
Explore how RADOS manages object storage, replication, and recovery mechanisms
Learn the concept of pools and placement groups (PGs) in Ceph storage
Perform essential operations including creating pools and placing objects
Monitor RADOS operations and cluster status effectively
Implement best practices for RADOS pool management and object operations
Prerequisites
Before starting this lab, students should have:

Basic understanding of distributed storage systems
Familiarity with Linux command-line interface
Knowledge of storage concepts (objects, replication, consistency)
Understanding of Ceph architecture fundamentals
Experience with basic system administration tasks
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Ceph Octopus or Pacific release pre-installed
Multiple OSD nodes configured
Administrative privileges for Ceph operations
Task 1: Understanding RADOS Architecture and Concepts
Subtask 1.1: Explore RADOS Fundamentals
Step 1: Connect to your lab environment and verify Ceph cluster status

# Check overall cluster health
sudo ceph status

# Display detailed cluster information
sudo ceph -s

# View cluster configuration
sudo ceph config dump
Step 2: Understand RADOS components

# List all monitors in the cluster
sudo ceph mon stat

# Display OSD (Object Storage Daemon) information
sudo ceph osd stat

# Show OSD tree structure
sudo ceph osd tree
Step 3: Examine the CRUSH map (Controlled Replication Under Scalable Hashing)

# Display CRUSH map in text format
sudo ceph osd crush dump

# Show CRUSH rules
sudo ceph osd crush rule ls

# Display detailed CRUSH rule information
sudo ceph osd crush rule dump
Subtask 1.2: Understanding Object Storage in RADOS
Step 1: Learn about object naming and structure

# Create a test file to understand object operations
echo "This is a test object for RADOS lab" > test_object.txt

# Display file content
cat test_object.txt
Step 2: Understand RADOS object addressing

# Show how RADOS calculates object placement
sudo ceph osd map rbd test_object

# Display placement group information
sudo ceph pg dump summary
Task 2: Working with Pools and Placement Groups
Subtask 2.1: Understanding Pools
Step 1: List existing pools and examine their properties

# List all pools in the cluster
sudo ceph osd lspools

# Display detailed pool information
sudo ceph osd pool ls detail

# Show pool statistics
sudo ceph df
Step 2: Understand placement group concepts

# Display placement group summary
sudo ceph pg stat

# Show detailed PG information
sudo ceph pg dump

# Display PG distribution across OSDs
sudo ceph pg dump osds
Subtask 2.2: Creating and Managing Pools
Step 1: Calculate appropriate PG numbers for new pools

# Display current OSD count for PG calculation
sudo ceph osd stat

# Note: PG calculation formula: (OSDs * 100) / replicas / pools
# For this lab, we'll use recommended values
Step 2: Create a new pool for testing

# Create a replicated pool named 'lab-pool'
sudo ceph osd pool create lab-pool 32 32

# Verify pool creation
sudo ceph osd lspools

# Display new pool details
sudo ceph osd pool ls detail | grep lab-pool
Step 3: Configure pool properties

# Set pool replication size
sudo ceph osd pool set lab-pool size 3

# Set minimum replication size
sudo ceph osd pool set lab-pool min_size 2

# Display pool configuration
sudo ceph osd pool get lab-pool all
Step 4: Create an erasure-coded pool (advanced)

# Create erasure code profile
sudo ceph osd erasure-code-profile set lab-ec-profile k=2 m=1

# Create erasure-coded pool
sudo ceph osd pool create lab-ec-pool 16 16 erasure lab-ec-profile

# Verify erasure-coded pool
sudo ceph osd pool ls detail | grep lab-ec-pool
Subtask 2.3: Understanding Placement Groups in Detail
Step 1: Examine PG states and distribution

# Show PG states
sudo ceph pg stat

# Display PGs for specific pool
sudo ceph pg ls-by-pool lab-pool

# Show PG mapping
sudo ceph pg map 1.0
Step 2: Monitor PG health

# Check for any unhealthy PGs
sudo ceph pg dump stuck

# Display PG statistics
sudo ceph pg dump summary
Task 3: Object Operations in RADOS
Subtask 3.1: Basic Object Operations
Step 1: Store objects in RADOS pools

# Put an object into the lab-pool
echo "Hello RADOS World!" | sudo rados -p lab-pool put hello-object -

# Put a file as an object
sudo rados -p lab-pool put test-file test_object.txt

# List objects in the pool
sudo rados -p lab-pool ls
Step 2: Retrieve and manipulate objects

# Get an object from the pool
sudo rados -p lab-pool get hello-object retrieved-hello.txt

# Display retrieved content
cat retrieved-hello.txt

# Get object information
sudo rados -p lab-pool stat hello-object
Step 3: Perform advanced object operations

# Append data to an existing object
echo " - Additional data" | sudo rados -p lab-pool append hello-object -

# Retrieve updated object
sudo rados -p lab-pool get hello-object updated-hello.txt
cat updated-hello.txt

# Create object with extended attributes
sudo rados -p lab-pool setxattr hello-object version "1.0"

# List extended attributes
sudo rados -p lab-pool listxattr hello-object

# Get extended attribute value
sudo rados -p lab-pool getxattr hello-object version
Subtask 3.2: Object Placement and Replication
Step 1: Understand object placement

# Show where objects are stored
sudo ceph osd map lab-pool hello-object

# Display object location details
sudo rados -p lab-pool listomapkeys hello-object
Step 2: Verify replication

# Check object replicas across OSDs
sudo ceph pg query $(sudo ceph osd map lab-pool hello-object | awk '{print $1}')
Subtask 3.3: Bulk Object Operations
Step 1: Create multiple test objects

# Create multiple objects using a loop
for i in {1..10}; do
    echo "Test object number $i" | sudo rados -p lab-pool put test-obj-$i -
done

# List all objects
sudo rados -p lab-pool ls
Step 2: Perform bulk operations

# Export objects to a directory
mkdir -p exported-objects
sudo rados -p lab-pool export exported-objects/

# List exported files
ls -la exported-objects/
Task 4: Monitoring RADOS Operations and Status
Subtask 4.1: Real-time Monitoring
Step 1: Monitor cluster operations in real-time

# Watch cluster status continuously
sudo ceph -w

# In another terminal, perform operations to see changes
# (Open a new terminal session)
Step 2: Monitor specific components

# Monitor OSD operations
sudo ceph osd perf

# Monitor pool I/O statistics
sudo ceph osd pool stats

# Display detailed cluster usage
sudo ceph df detail
Subtask 4.2: Performance Monitoring
Step 1: Benchmark pool performance

# Run write performance test
sudo rados -p lab-pool bench 30 write --no-cleanup

# Run read performance test
sudo rados -p lab-pool bench 30 seq

# Clean up benchmark objects
sudo rados -p lab-pool cleanup
Step 2: Monitor placement group performance

# Show slow operations
sudo ceph daemon osd.0 dump_historic_slow_ops

# Display OSD performance counters
sudo ceph daemon osd.0 perf dump
Subtask 4.3: Health and Status Monitoring
Step 1: Comprehensive health checks

# Detailed health information
sudo ceph health detail

# Check for any warnings or errors
sudo ceph health

# Display cluster log
sudo ceph log last 20
Step 2: Monitor recovery operations

# Show recovery status
sudo ceph -s | grep recovery

# Display backfill operations
sudo ceph pg dump | grep backfill
Task 5: Advanced RADOS Operations
Subtask 5.1: Pool Snapshots
Step 1: Create pool snapshots

# Create a snapshot of the lab-pool
sudo ceph osd pool mksnap lab-pool lab-snapshot-1

# List pool snapshots
sudo ceph osd pool ls detail | grep lab-pool
Step 2: Work with snapshots

# Add more objects after snapshot
echo "Post-snapshot object" | sudo rados -p lab-pool put post-snap-obj -

# List current objects
sudo rados -p lab-pool ls
Subtask 5.2: Pool Quotas and Limits
Step 1: Set pool quotas

# Set maximum objects quota
sudo ceph osd pool set-quota lab-pool max_objects 100

# Set maximum bytes quota (10MB)
sudo ceph osd pool set-quota lab-pool max_bytes 10485760

# Display quota information
sudo ceph osd pool get-quota lab-pool
Step 2: Test quota enforcement

# Try to exceed quota (this should eventually fail)
for i in {1..150}; do
    echo "Quota test object $i" | sudo rados -p lab-pool put quota-test-$i - 2>/dev/null || echo "Quota reached at object $i"
done
Subtask 5.3: Pool Maintenance Operations
Step 1: Scrub operations

# Initiate deep scrub on a placement group
sudo ceph pg deep-scrub 1.0

# Check scrub status
sudo ceph pg dump | grep scrub
Step 2: Pool statistics and cleanup

# Display detailed pool statistics
sudo rados -p lab-pool df

# Remove test objects
for i in {1..10}; do
    sudo rados -p lab-pool rm test-obj-$i
done

# Verify cleanup
sudo rados -p lab-pool ls
Troubleshooting Common Issues
Issue 1: Pool Creation Failures
Problem: Pool creation fails with PG-related errors

Solution:

# Check current PG distribution
sudo ceph pg stat

# Verify OSD capacity
sudo ceph osd df

# Adjust PG count if necessary
sudo ceph osd pool set lab-pool pg_num 16
sudo ceph osd pool set lab-pool pgp_num 16
Issue 2: Object Operations Timeout
Problem: Object put/get operations timeout

Solution:

# Check cluster health
sudo ceph health detail

# Verify OSD status
sudo ceph osd stat

# Check network connectivity
sudo ceph osd tree
Issue 3: Placement Group Issues
Problem: PGs stuck in inactive/unclean state

Solution:

# Identify problematic PGs
sudo ceph pg dump stuck

# Check OSD logs for specific PG
sudo ceph pg query <pg-id>

# Force PG recovery if safe
sudo ceph pg force-recovery <pg-id>
Lab Cleanup
Step 1: Remove test objects and pools

# Remove all objects from lab-pool
sudo rados -p lab-pool cleanup

# Remove snapshots
sudo ceph osd pool rmsnap lab-pool lab-snapshot-1

# Delete test pools (be careful!)
sudo ceph osd pool delete lab-pool lab-pool --yes-i-really-really-mean-it
sudo ceph osd pool delete lab-ec-pool lab-ec-pool --yes-i-really-really-mean-it

# Remove erasure code profile
sudo ceph osd erasure-code-profile rm lab-ec-profile
Step 2: Verify cleanup

# Confirm pools are removed
sudo ceph osd lspools

# Check cluster status
sudo ceph status
Conclusion
In this comprehensive lab, you have successfully:

Explored RADOS Architecture: Gained deep understanding of how RADOS manages distributed object storage, including the roles of monitors, OSDs, and the CRUSH algorithm
Mastered Pool Management: Learned to create, configure, and manage both replicated and erasure-coded pools with appropriate placement group calculations
Performed Object Operations: Successfully stored, retrieved, and manipulated objects in RADOS pools, understanding object placement and replication mechanisms
Implemented Monitoring: Developed skills in monitoring RADOS operations, performance metrics, and cluster health status
Applied Advanced Concepts: Worked with snapshots, quotas, and maintenance operations that are crucial for production environments
Why This Matters: RADOS is the foundation of Ceph storage, powering object, block, and file storage services. Understanding RADOS operations is essential for:

Storage Administrators: Managing large-scale distributed storage systems
Cloud Engineers: Implementing reliable storage backends for cloud services
DevOps Professionals: Ensuring data durability and availability in containerized environments
Red Hat Certification: Building expertise required for Red Hat Ceph Storage certifications
The hands-on experience gained in this lab provides the practical foundation needed to design, deploy, and maintain production Ceph clusters, making you proficient in one of the most important open-source distributed storage technologies available today.
