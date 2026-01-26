Lab 4: Managing RADOS and Pools
Objectives
By the end of this lab, students will be able to:

Create and manage RADOS pools using command-line tools
Understand and manipulate placement groups (PGs) for optimal data distribution
Customize data distribution using CRUSH maps
Monitor and inspect pool performance metrics
Implement best practices for pool configuration and management
Troubleshoot common pool-related issues in Ceph clusters
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph architecture and components
Familiarity with Linux command-line interface
Knowledge of storage concepts (replication, erasure coding)
Completion of previous Ceph labs or equivalent experience
Understanding of RADOS (Reliable Autonomic Distributed Object Store) concepts
Basic networking knowledge
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph already installed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3-node Ceph cluster (ceph-node1, ceph-node2, ceph-node3)
Ceph Monitor, Manager, and OSD services pre-configured
Administrative access to all nodes
Network connectivity between all nodes
Task 1: Create and Manage RADOS Pools
Subtask 1.1: Understanding Pool Basics
Before creating pools, let's examine the current cluster state and understand pool fundamentals.

Step 1: Connect to the Ceph admin node and check cluster status

# Connect to ceph-node1 (admin node)
ssh ceph-admin@ceph-node1

# Check overall cluster health
ceph status

# List existing pools
ceph osd lspool
Step 2: Understand pool parameters and calculate PG numbers

# Check current OSD count
ceph osd stat

# View detailed OSD information
ceph osd tree

# Calculate recommended PG count (formula: Total PGs = (OSDs * 100) / pool_size)
# For a 3-OSD cluster with replication size 3: (3 * 100) / 3 = 100 PGs
Subtask 1.2: Create Replicated Pools
Step 1: Create a basic replicated pool

# Create a replicated pool named 'web-data' with 32 PGs
ceph osd pool create web-data 32 32 replicated

# Verify pool creation
ceph osd lspool

# Get detailed pool information
ceph osd pool ls detail
Step 2: Configure pool properties

# Set replication size to 3
ceph osd pool set web-data size 3

# Set minimum replication size to 2 (for availability during failures)
ceph osd pool set web-data min_size 2

# Enable pool for RBD usage
ceph osd pool application enable web-data rbd

# Verify pool settings
ceph osd pool get web-data all
Step 3: Create additional pools for different use cases

# Create a pool for database storage
ceph osd pool create db-storage 16 16 replicated
ceph osd pool set db-storage size 3
ceph osd pool set db-storage min_size 2
ceph osd pool application enable db-storage rbd

# Create a pool for backup data with different replication
ceph osd pool create backup-data 8 8 replicated
ceph osd pool set backup-data size 2
ceph osd pool set backup-data min_size 1
ceph osd pool application enable backup-data rgw
Subtask 1.3: Create Erasure Coded Pools
Step 1: Create an erasure coding profile

# Create a custom erasure coding profile
ceph osd erasure-code-profile set ec-profile-4-2 k=4 m=2 crush-failure-domain=osd

# List available erasure coding profiles
ceph osd erasure-code-profile ls

# View profile details
ceph osd erasure-code-profile get ec-profile-4-2
Step 2: Create an erasure coded pool

# Create erasure coded pool for archive data
ceph osd pool create archive-data 16 16 erasure ec-profile-4-2

# Enable application for the erasure coded pool
ceph osd pool application enable archive-data rgw

# Verify the pool configuration
ceph osd pool get archive-data all
Task 2: Customize Data Distribution with CRUSH Maps
Subtask 2.1: Understanding Current CRUSH Map
Step 1: Examine the current CRUSH map structure

# View the CRUSH map in a readable format
ceph osd crush tree

# Get detailed CRUSH map information
ceph osd getcrushmap -o crushmap.bin
crushtool -d crushmap.bin -o crushmap.txt
cat crushmap.txt
Step 2: Analyze CRUSH rules

# List all CRUSH rules
ceph osd crush rule ls

# View details of the default replicated rule
ceph osd crush rule dump replicated_rule

# Check which pools use which rules
ceph osd pool ls detail | grep crush_rule
Subtask 2.2: Create Custom CRUSH Rules
Step 1: Create a custom CRUSH rule for specific requirements

# Create a rule that places data only on specific hosts
ceph osd crush rule create-replicated ssd-only default host ssd

# Create a rule for rack-level distribution
ceph osd crush rule create-replicated rack-distributed default rack

# List all rules to verify creation
ceph osd crush rule ls
Step 2: Apply custom CRUSH rules to pools

# Apply the custom rule to a specific pool
ceph osd pool set web-data crush_rule ssd-only

# Verify the rule assignment
ceph osd pool get web-data crush_rule

# Check data distribution after rule change
ceph pg dump | grep web-data
Subtask 2.3: Modify CRUSH Map for Custom Topology
Step 1: Add custom buckets to CRUSH map

# Add a custom rack bucket
ceph osd crush add-bucket rack01 rack

# Add a custom row bucket
ceph osd crush add-bucket row01 row

# Move rack01 under row01
ceph osd crush move rack01 row=row01

# View the updated hierarchy
ceph osd crush tree
Step 2: Modify device classes and weights

# Check current device classes
ceph osd crush class ls

# Set device class for specific OSDs
ceph osd crush set-device-class ssd osd.0
ceph osd crush set-device-class hdd osd.1 osd.2

# Verify device class assignments
ceph osd crush class ls-osd ssd
ceph osd crush class ls-osd hdd
Task 3: Inspect and Monitor Pool Performance
Subtask 3.1: Monitor Pool Statistics
Step 1: Examine basic pool statistics

# Get comprehensive pool statistics
ceph df

# Get detailed pool usage information
ceph osd pool stats

# Monitor specific pool statistics
ceph osd pool stats web-data
Step 2: Analyze placement group distribution

# Check PG distribution across OSDs
ceph pg dump osds

# View PG states and distribution
ceph pg stat

# Check for any stuck or problematic PGs
ceph pg dump_stuck
Subtask 3.2: Performance Monitoring and Benchmarking
Step 1: Use built-in benchmarking tools

# Create test objects for benchmarking
rados -p web-data bench 60 write --no-cleanup

# Run read benchmark
rados -p web-data bench 60 seq

# Clean up benchmark objects
rados -p web-data cleanup
Step 2: Monitor real-time performance

# Monitor cluster performance in real-time
ceph -w

# In another terminal, generate some load
rados -p web-data put test-object /etc/hosts

# Check pool I/O statistics
ceph osd pool stats web-data
Subtask 3.3: Advanced Pool Monitoring
Step 1: Examine detailed PG information

# Get detailed information about specific PGs
ceph pg dump | head -20

# Check PG mapping for a specific pool
ceph pg ls-by-pool web-data

# Examine PG query for detailed state information
ceph pg query 1.0
Step 2: Monitor pool health and recovery

# Check for any recovery operations
ceph -s | grep recovery

# Monitor scrubbing operations
ceph pg dump | grep scrub

# Check for any inconsistent PGs
ceph health detail
Task 4: Advanced Pool Management Operations
Subtask 4.1: Pool Snapshots and Cloning
Step 1: Create and manage pool snapshots

# Create a pool snapshot
ceph osd pool mksnap web-data snapshot-$(date +%Y%m%d)

# List pool snapshots
ceph osd pool ls detail | grep web-data -A 10

# Store some data before creating another snapshot
echo "Test data" | rados -p web-data put test-file -

# Create another snapshot
ceph osd pool mksnap web-data snapshot-after-data
Step 2: Work with object operations

# List objects in the pool
rados -p web-data ls

# Get object information
rados -p web-data stat test-file

# Create multiple test objects
for i in {1..5}; do
    echo "Test data $i" | rados -p web-data put test-file-$i -
done

# List all objects again
rados -p web-data ls
Subtask 4.2: Pool Quota Management
Step 1: Set and manage pool quotas

# Set maximum objects quota
ceph osd pool set-quota web-data max_objects 1000

# Set maximum bytes quota (100MB)
ceph osd pool set-quota web-data max_bytes 104857600

# Check quota settings
ceph osd pool get-quota web-data

# Test quota by trying to exceed limits
for i in {1..10}; do
    dd if=/dev/zero bs=1M count=20 | rados -p web-data put large-file-$i -
done
Step 2: Monitor quota usage

# Check current pool usage against quotas
ceph df detail

# Remove quota limits
ceph osd pool set-quota web-data max_objects 0
ceph osd pool set-quota web-data max_bytes 0
Task 5: Troubleshooting and Optimization
Subtask 5.1: Common Pool Issues and Solutions
Step 1: Identify and resolve PG issues

# Check for inactive PGs
ceph pg dump | grep -v "active+clean"

# If PGs are stuck, try to repair them
# (Only run if you see stuck PGs)
# ceph pg repair <pg_id>

# Force scrub on a specific PG if needed
ceph pg scrub 1.0
Step 2: Optimize pool performance

# Adjust PG autoscaler settings
ceph osd pool set web-data pg_autoscale_mode on

# Check autoscaler recommendations
ceph osd pool autoscale-status

# Manually adjust PG count if needed (be cautious)
# ceph osd pool set web-data pg_num 64
# ceph osd pool set web-data pgp_num 64
Subtask 5.2: Pool Maintenance Operations
Step 1: Perform maintenance tasks

# Initiate deep scrub on all PGs in a pool
for pg in $(ceph pg ls-by-pool web-data | awk '{print $1}' | grep -v PG_STAT); do
    ceph pg deep-scrub $pg
done

# Check scrub status
ceph pg dump | grep scrub | head -5
Step 2: Clean up and optimize

# Remove unnecessary snapshots
ceph osd pool rmsnap web-data snapshot-$(date +%Y%m%d)

# Clean up test objects
rados -p web-data rm test-file
for i in {1..5}; do
    rados -p web-data rm test-file-$i
done

# Verify cleanup
rados -p web-data ls
Verification and Testing
Final Verification Steps
Step 1: Verify all pools are healthy

# Check overall cluster health
ceph health

# Verify all pools are active
ceph osd pool ls detail

# Check PG distribution
ceph pg stat
Step 2: Test pool functionality

# Test write/read operations on each pool
echo "Final test" | rados -p web-data put final-test -
rados -p web-data get final-test -

echo "DB test" | rados -p db-storage put db-test -
rados -p db-storage get db-test -

# Verify data integrity
rados -p web-data stat final-test
rados -p db-storage stat db-test
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Pool creation fails with "too many PGs"

# Solution: Reduce PG count or increase OSD count
ceph osd pool create test-pool 8 8 replicated
Issue 2: PGs stuck in creating state

# Solution: Check OSD status and restart if necessary
ceph osd tree
systemctl restart ceph-osd@0
Issue 3: CRUSH rule application fails

# Solution: Verify rule exists and pool is empty
ceph osd crush rule ls
ceph osd pool get <pool-name> crush_rule
Issue 4: Performance issues

# Solution: Check PG distribution and rebalance
ceph pg dump osds
ceph osd reweight <osd-id> <weight>
Conclusion
In this comprehensive lab, you have successfully:

Created and managed multiple types of RADOS pools including replicated and erasure-coded pools with different configurations for various use cases
Customized data distribution by creating and applying custom CRUSH rules, modifying CRUSH maps, and understanding how Ceph distributes data across the cluster
Monitored pool performance using built-in tools, benchmarking capabilities, and real-time monitoring to ensure optimal cluster operation
Implemented advanced pool management including snapshots, quotas, and maintenance operations
Troubleshot common issues and learned optimization techniques for production environments
Why This Matters
Understanding RADOS pool management is crucial for:

Data Organization: Properly configured pools ensure data is stored efficiently and accessed quickly
Performance Optimization: Custom CRUSH rules and proper PG distribution directly impact cluster performance
Reliability: Appropriate replication settings and monitoring prevent data loss
Scalability: Proper pool configuration allows clusters to grow seamlessly
Cost Efficiency: Erasure coding and intelligent data placement reduce storage costs
Next Steps
To further enhance your Ceph expertise:

Explore advanced CRUSH map modifications for complex topologies
Implement automated monitoring and alerting for pool health
Practice disaster recovery scenarios with pool snapshots
Study integration with applications like RBD, CephFS, and RGW
Learn about pool tiering and cache pools for hybrid storage solutions
This knowledge prepares you for the Red Hat Certified Specialist in Ceph Cloud Storage exam and real-world Ceph administration scenarios where efficient pool management is essential for maintaining high-performance, reliable storage systems.
