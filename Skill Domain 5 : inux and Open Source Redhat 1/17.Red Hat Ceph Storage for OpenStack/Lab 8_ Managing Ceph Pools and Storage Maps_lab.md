Lab 8: Managing Ceph Pools and Storage Maps
Objectives
By the end of this lab, students will be able to:

Create and configure Ceph pools with specific replication rules
Understand and modify CRUSH maps for custom storage placement
Manage OSD maps and monitor storage distribution across the cluster
Implement advanced pool configurations for different storage requirements
Troubleshoot common pool and CRUSH map issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph architecture and components
Familiarity with Linux command line operations
Knowledge of YAML and JSON file formats
Understanding of storage concepts like replication and erasure coding
Completion of previous Ceph labs or equivalent experience
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph already installed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ceph monitor nodes
6 Ceph OSD nodes with multiple disks
1 Ceph admin node for management
Pre-configured Ceph cluster ready for pool management
Task 1: Create Pools with Specific Replication Rules
Subtask 1.1: Examine Current Cluster Status
First, let's check the current state of our Ceph cluster and existing pools.

Connect to the admin node and check cluster health:
# Check overall cluster status
ceph status

# List existing pools
ceph osd lspools

# Check pool details
ceph osd pool ls detail
Examine current CRUSH map structure:
# View CRUSH map tree
ceph osd tree

# Get CRUSH map rules
ceph osd crush rule ls
ceph osd crush rule dump
Subtask 1.2: Create a Replicated Pool
Now we'll create a new replicated pool with specific replication settings.

Create a basic replicated pool:
# Create a pool named 'web-data' with 128 placement groups
ceph osd pool create web-data 128 128 replicated

# Verify pool creation
ceph osd pool ls detail | grep web-data
Configure replication settings:
# Set replication size to 3 (3 copies of each object)
ceph osd pool set web-data size 3

# Set minimum replication size to 2 (minimum copies for I/O)
ceph osd pool set web-data min_size 2

# Verify settings
ceph osd pool get web-data size
ceph osd pool get web-data min_size
Subtask 1.3: Create an Erasure Coded Pool
Erasure coding provides better storage efficiency than replication.

Create an erasure coding profile:
# Create a profile with 4 data chunks and 2 coding chunks (4+2)
ceph osd erasure-code-profile set ec-profile-42 \
    k=4 m=2 \
    crush-failure-domain=host \
    crush-device-class=hdd

# Verify profile creation
ceph osd erasure-code-profile ls
ceph osd erasure-code-profile get ec-profile-42
Create erasure coded pool:
# Create EC pool using the profile
ceph osd pool create backup-data 64 64 erasure ec-profile-42

# Verify pool creation
ceph osd pool ls detail | grep backup-data
Subtask 1.4: Create Pools with Custom Rules
Let's create pools that use specific types of storage devices.

Create a pool for SSD storage only:
# First, create a CRUSH rule for SSD devices
ceph osd crush rule create-replicated ssd-rule default host ssd

# Create pool using SSD rule
ceph osd pool create fast-cache 32 32 replicated ssd-rule

# Verify the pool uses the correct rule
ceph osd pool get fast-cache crush_rule
Create a pool for HDD storage only:
# Create a CRUSH rule for HDD devices
ceph osd crush rule create-replicated hdd-rule default host hdd

# Create pool using HDD rule
ceph osd pool create archive-data 64 64 replicated hdd-rule

# Verify the pool configuration
ceph osd pool get archive-data crush_rule
Task 2: Modify the CRUSH Map for Custom Storage Placement
Subtask 2.1: Extract and Examine Current CRUSH Map
Understanding the CRUSH map is essential for custom storage placement.

Extract the current CRUSH map:
# Get the compiled CRUSH map
ceph osd getcrushmap -o crushmap.bin

# Decompile to human-readable format
crushtool -d crushmap.bin -o crushmap.txt

# View the CRUSH map structure
cat crushmap.txt
Analyze CRUSH map components:
# View the hierarchy
grep -A 20 "# buckets" crushmap.txt

# View the rules
grep -A 10 "# rules" crushmap.txt
Subtask 2.2: Create Custom CRUSH Hierarchy
We'll create a custom hierarchy that separates storage by performance tiers.

Create a custom CRUSH map with performance tiers:
# Create a backup of current map
cp crushmap.txt crushmap-backup.txt

# Create new CRUSH map with custom hierarchy
cat > custom-crushmap.txt << 'EOF'
# begin crush map
tunable choose_local_tries 0
tunable choose_local_fallback_tries 0
tunable choose_total_tries 50
tunable chooseleaf_descend_once 1
tunable chooseleaf_vary_r 1
tunable chooseleaf_stable 1
tunable straw_calc_version 1
tunable allowed_bucket_algs 54

# devices
device 0 osd.0 class hdd
device 1 osd.1 class hdd
device 2 osd.2 class ssd
device 3 osd.3 class ssd
device 4 osd.4 class hdd
device 5 osd.5 class hdd

# types
type 0 osd
type 1 host
type 2 chassis
type 3 rack
type 4 row
type 5 pdu
type 6 pod
type 7 room
type 8 datacenter
type 9 zone
type 10 region
type 11 root

# buckets
host ceph-node1 {
    id -3
    alg straw2
    hash 0
    item osd.0 weight 1.000
    item osd.1 weight 1.000
}

host ceph-node2 {
    id -5
    alg straw2
    hash 0
    item osd.2 weight 1.000
    item osd.3 weight 1.000
}

host ceph-node3 {
    id -7
    alg straw2
    hash 0
    item osd.4 weight 1.000
    item osd.5 weight 1.000
}

rack performance-rack {
    id -9
    alg straw2
    hash 0
    item ceph-node2 weight 2.000
}

rack capacity-rack {
    id -11
    alg straw2
    hash 0
    item ceph-node1 weight 2.000
    item ceph-node3 weight 2.000
}

root default {
    id -1
    alg straw2
    hash 0
    item performance-rack weight 2.000
    item capacity-rack weight 4.000
}

# rules
rule replicated_rule {
    id 0
    type replicated
    min_size 1
    max_size 10
    step take default
    step chooseleaf firstn 0 type host
    step emit
}

rule performance_rule {
    id 1
    type replicated
    min_size 1
    max_size 10
    step take performance-rack
    step chooseleaf firstn 0 type host
    step emit
}

rule capacity_rule {
    id 2
    type replicated
    min_size 1
    max_size 10
    step take capacity-rack
    step chooseleaf firstn 0 type host
    step emit
}

# end crush map
EOF
Compile and apply the custom CRUSH map:
# Compile the new CRUSH map
crushtool -c custom-crushmap.txt -o custom-crushmap.bin

# Apply the new CRUSH map (be careful with this step)
ceph osd setcrushmap -i custom-crushmap.bin

# Verify the new hierarchy
ceph osd tree
Subtask 2.3: Create Pools Using Custom Rules
Now let's create pools that use our custom CRUSH rules.

Create a high-performance pool:
# Create pool using performance rule
ceph osd pool create high-perf-db 32 32 replicated performance_rule

# Verify placement
ceph osd pool get high-perf-db crush_rule
Create a capacity-optimized pool:
# Create pool using capacity rule
ceph osd pool create bulk-storage 64 64 replicated capacity_rule

# Verify placement
ceph osd pool get bulk-storage crush_rule
Task 3: Manage OSD Maps and Observe Storage Distribution
Subtask 3.1: Monitor Pool Distribution
Understanding how data is distributed across OSDs is crucial for performance optimization.

Check pool statistics:
# View pool usage statistics
ceph df

# Get detailed pool information
ceph osd pool stats

# Check specific pool statistics
ceph osd pool stats web-data
ceph osd pool stats high-perf-db
Examine placement group distribution:
# View PG distribution across OSDs
ceph pg dump osds

# Check PG states
ceph pg stat

# View detailed PG information
ceph pg dump pgs | head -20
Subtask 3.2: Test Data Distribution
Let's add some test data to see how it's distributed.

Create test objects in different pools:
# Create test objects in web-data pool
for i in {1..10}; do
    echo "Test data for object $i" | rados -p web-data put test-object-$i -
done

# Create test objects in high-perf-db pool
for i in {1..10}; do
    echo "High performance data $i" | rados -p high-perf-db put perf-object-$i -
done

# List objects in pools
rados -p web-data ls
rados -p high-perf-db ls
Check object placement:
# Check where specific objects are placed
ceph osd map web-data test-object-1
ceph osd map high-perf-db perf-object-1

# View object distribution across OSDs
for pool in web-data high-perf-db; do
    echo "=== Pool: $pool ==="
    rados -p $pool ls | while read obj; do
        echo -n "$obj: "
        ceph osd map $pool $obj | grep "osd"
    done
done
Subtask 3.3: Monitor and Adjust Pool Parameters
Fine-tuning pool parameters based on observed distribution.

Monitor pool performance metrics:
# Check pool I/O statistics
ceph osd pool stats

# Monitor real-time cluster activity
ceph -w
Adjust pool parameters based on observations:
# Increase PG count if needed (only if cluster is healthy)
# Note: This should be done carefully in production
ceph osd pool set web-data pg_num 256
ceph osd pool set web-data pgp_num 256

# Set pool quotas
ceph osd pool set-quota web-data max_objects 10000
ceph osd pool set-quota web-data max_bytes 1073741824  # 1GB

# Check quota settings
ceph osd pool get-quota web-data
Subtask 3.4: Implement Advanced Pool Features
Configure additional pool features for better management.

Enable pool compression:
# Enable compression on backup-data pool
ceph osd pool set backup-data compression_algorithm snappy
ceph osd pool set backup-data compression_mode aggressive

# Verify compression settings
ceph osd pool get backup-data compression_algorithm
ceph osd pool get backup-data compression_mode
Configure pool applications:
# Tag pools with application types
ceph osd pool application enable web-data rbd
ceph osd pool application enable high-perf-db rbd
ceph osd pool application enable backup-data rgw

# Verify application tags
ceph osd pool application get web-data
Troubleshooting Common Issues
Issue 1: Pool Creation Fails
Problem: Pool creation fails with "too many PGs" error.

Solution:

# Check current PG count
ceph osd pool ls detail | grep pg_num

# Calculate appropriate PG count (typically 100-200 PGs per OSD)
# For 6 OSDs: 6 * 100 = 600 total PGs across all pools

# Create pool with fewer PGs
ceph osd pool create new-pool 32 32
Issue 2: CRUSH Map Changes Not Taking Effect
Problem: Custom CRUSH map changes don't affect data placement.

Solution:

# Force rebalancing after CRUSH map changes
ceph osd reweight-by-utilization

# Check if rebalancing is in progress
ceph status

# Monitor PG movement
ceph pg dump pgs | grep -v "active+clean"
Issue 3: Uneven Data Distribution
Problem: Data is not evenly distributed across OSDs.

Solution:

# Check OSD utilization
ceph osd df

# Reweight OSDs that are over/under utilized
ceph osd reweight osd.X 0.9  # Reduce weight for over-utilized OSD
ceph osd reweight osd.Y 1.1  # Increase weight for under-utilized OSD

# Use automatic reweighting
ceph osd reweight-by-utilization 110  # Reweight OSDs over 110% of average
Verification and Testing
Final Verification Steps
Verify all pools are healthy:
# Check cluster health
ceph health detail

# Verify all pools
ceph osd pool ls detail

# Check PG states
ceph pg stat
Test pool functionality:
# Test write/read operations on each pool
echo "Test data" | rados -p web-data put test-final -
rados -p web-data get test-final -

echo "Performance test" | rados -p high-perf-db put perf-test -
rados -p high-perf-db get perf-test -
Document pool configurations:
# Create a summary of all pool configurations
echo "=== Pool Configuration Summary ===" > pool-summary.txt
for pool in $(ceph osd pool ls); do
    echo "Pool: $pool" >> pool-summary.txt
    ceph osd pool get $pool size >> pool-summary.txt
    ceph osd pool get $pool crush_rule >> pool-summary.txt
    echo "---" >> pool-summary.txt
done

cat pool-summary.txt
Conclusion
In this comprehensive lab, you have successfully:

Created multiple types of Ceph pools including replicated and erasure-coded pools with specific replication rules
Modified CRUSH maps to implement custom storage placement strategies based on performance tiers
Managed OSD maps and observed how data distribution works across the cluster
Implemented advanced pool features such as compression, quotas, and application tagging
Troubleshot common issues related to pool management and data distribution
Why This Matters: Understanding pool management and CRUSH maps is crucial for optimizing Ceph storage performance and reliability. These skills enable you to:

Design storage architectures that meet specific performance and capacity requirements
Implement data placement policies that align with hardware capabilities
Optimize storage efficiency through proper pool configuration
Troubleshoot and resolve storage distribution issues
Key Takeaways:

Pools are the fundamental unit of storage management in Ceph
CRUSH maps control how data is distributed across the cluster
Different pool types serve different use cases (replication vs erasure coding)
Custom CRUSH rules enable fine-grained control over data placement
Regular monitoring and adjustment of pool parameters ensures optimal performance
These skills are essential for managing enterprise Ceph deployments and are directly applicable to Red Hat Ceph Storage certification objectives. The hands-on experience gained in this lab provides a solid foundation for advanced Ceph administration tasks.
