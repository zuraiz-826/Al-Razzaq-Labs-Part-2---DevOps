Lab 10: Configuring and Managing Erasure-Coded Pools
Objectives
By the end of this lab, you will be able to:

• Understand the fundamentals of erasure coding in Ceph storage systems • Create and configure erasure-coded pools with appropriate parameters • Define and customize erasure-coded pool profiles for different use cases • Test redundancy mechanisms and evaluate performance characteristics of erasure-coded pools • Compare erasure-coded pools with replicated pools for storage efficiency • Troubleshoot common issues with erasure-coded pool configurations

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Ceph storage architecture and components • Familiarity with Ceph command-line interface (ceph CLI) • Knowledge of storage concepts including replication and redundancy • Experience with Linux command-line operations • Understanding of RADOS pools and placement groups • Completion of previous Ceph labs covering basic pool management

Required Knowledge Areas
• Ceph Cluster Architecture: Understanding of MONs, OSDs, and MGRs • Pool Management: Basic pool creation and configuration concepts • Storage Mathematics: Basic understanding of storage efficiency calculations • Linux Administration: File system operations and permissions

Lab Environment Setup
Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or install Ceph from scratch.

Environment Specifications
Your lab environment includes: • 3 Monitor nodes (ceph-mon01, ceph-mon02, ceph-mon03) • 6 OSD nodes with multiple disks each • 1 Admin node for cluster management • Pre-installed Ceph cluster (Pacific or Quincy release) • Network connectivity between all nodes

Task 1: Understanding Erasure Coding Fundamentals
Subtask 1.1: Review Current Cluster Status
First, let's examine the current state of your Ceph cluster and understand the existing pool configurations.

# Connect to the admin node
ssh ceph-admin

# Check cluster health
ceph health

# List existing pools
ceph osd lspools

# Check current pool details
ceph osd pool ls detail
Subtask 1.2: Understand Erasure Coding Concepts
Erasure coding is a method of data protection that divides data into fragments, expands and encodes them with redundant data pieces, and stores them across different locations.

Key Concepts: • k: Number of data chunks • m: Number of coding chunks • Total chunks: k + m • Storage overhead: m/k ratio • Failure tolerance: Can lose up to m chunks

Subtask 1.3: Compare Storage Efficiency
Let's calculate storage efficiency for different configurations:

# Create a simple script to calculate storage efficiency
cat > /tmp/calculate_efficiency.sh << 'EOF'
#!/bin/bash
echo "=== Storage Efficiency Calculator ==="
echo "Replicated Pool (3 replicas): 33.33% efficiency"
echo "Erasure Coded k=4,m=2: $(echo "scale=2; 4/6*100" | bc)% efficiency"
echo "Erasure Coded k=6,m=3: $(echo "scale=2; 6/9*100" | bc)% efficiency"
echo "Erasure Coded k=8,m=2: $(echo "scale=2; 8/10*100" | bc)% efficiency"
EOF

chmod +x /tmp/calculate_efficiency.sh
/tmp/calculate_efficiency.sh
Task 2: Creating and Configuring Erasure-Coded Pools
Subtask 2.1: Create Your First Erasure-Coded Pool Profile
Erasure-coded pools require profiles that define the encoding parameters. Let's create a basic profile first.

# Create a basic erasure code profile
ceph osd erasure-code-profile set ec-profile-basic \
    k=4 \
    m=2 \
    plugin=jerasure \
    technique=reed_sol_van

# Verify the profile was created
ceph osd erasure-code-profile ls

# View profile details
ceph osd erasure-code-profile get ec-profile-basic
Profile Parameters Explained: • k=4: Data will be split into 4 chunks • m=2: 2 additional parity chunks will be created • plugin=jerasure: Uses the Jerasure erasure coding library • technique=reed_sol_van: Specific Reed-Solomon algorithm variant

Subtask 2.2: Create the Erasure-Coded Pool
Now let's create an erasure-coded pool using our profile:

# Create erasure-coded pool
ceph osd pool create ec-pool-basic 128 128 erasure ec-profile-basic

# Verify pool creation
ceph osd pool ls detail | grep ec-pool-basic

# Check pool statistics
ceph osd pool stats ec-pool-basic
Subtask 2.3: Configure Pool Parameters
Let's configure additional parameters for our erasure-coded pool:

# Set application type for the pool
ceph osd pool application enable ec-pool-basic rgw

# Configure placement group autoscaling
ceph osd pool set ec-pool-basic pg_autoscale_mode on

# Set target size ratio (optional)
ceph osd pool set ec-pool-basic target_size_ratio 0.1

# View current pool configuration
ceph osd pool get ec-pool-basic all
Task 3: Defining Advanced Erasure-Coded Pool Profiles
Subtask 3.1: Create High-Performance Profile
For scenarios requiring better performance with acceptable storage overhead:

# Create high-performance profile (k=8, m=2)
ceph osd erasure-code-profile set ec-profile-performance \
    k=8 \
    m=2 \
    plugin=jerasure \
    technique=reed_sol_van \
    w=8

# Create pool with performance profile
ceph osd pool create ec-pool-performance 64 64 erasure ec-profile-performance

# Enable application
ceph osd pool application enable ec-pool-performance rbd
Subtask 3.2: Create High-Durability Profile
For scenarios requiring maximum data protection:

# Create high-durability profile (k=6, m=3)
ceph osd erasure-code-profile set ec-profile-durability \
    k=6 \
    m=3 \
    plugin=jerasure \
    technique=reed_sol_van

# Create pool with durability profile
ceph osd pool create ec-pool-durability 64 64 erasure ec-profile-durability

# Enable application
ceph osd pool application enable ec-pool-durability cephfs
Subtask 3.3: Create Balanced Profile with LRC Plugin
Local Reconstruction Codes (LRC) provide better repair performance:

# Create LRC profile for balanced performance and durability
ceph osd erasure-code-profile set ec-profile-lrc \
    plugin=lrc \
    k=4 \
    m=2 \
    l=2

# Create pool with LRC profile
ceph osd pool create ec-pool-lrc 64 64 erasure ec-profile-lrc

# Enable application
ceph osd pool application enable ec-pool-lrc rgw
Subtask 3.4: View All Profiles and Pools
# List all erasure code profiles
echo "=== Erasure Code Profiles ==="
ceph osd erasure-code-profile ls

# Show details of each profile
for profile in $(ceph osd erasure-code-profile ls); do
    echo "Profile: $profile"
    ceph osd erasure-code-profile get $profile
    echo "---"
done

# List all erasure-coded pools
echo "=== Erasure-Coded Pools ==="
ceph osd pool ls detail | grep erasure
Task 4: Testing Redundancy and Performance
Subtask 4.1: Test Data Storage and Retrieval
Let's test our erasure-coded pools by storing and retrieving data:

# Create test data
echo "This is test data for erasure-coded pool testing" > /tmp/test-data.txt
echo "Additional test content for comprehensive testing" >> /tmp/test-data.txt

# Store data in basic erasure-coded pool
rados -p ec-pool-basic put test-object-1 /tmp/test-data.txt

# Store data in performance pool
rados -p ec-pool-performance put test-object-2 /tmp/test-data.txt

# Store data in durability pool
rados -p ec-pool-durability put test-object-3 /tmp/test-data.txt

# Verify data storage
rados -p ec-pool-basic ls
rados -p ec-pool-performance ls
rados -p ec-pool-durability ls
Subtask 4.2: Test Data Integrity
# Retrieve data and verify integrity
rados -p ec-pool-basic get test-object-1 /tmp/retrieved-basic.txt
rados -p ec-pool-performance get test-object-2 /tmp/retrieved-performance.txt
rados -p ec-pool-durability get test-object-3 /tmp/retrieved-durability.txt

# Compare original and retrieved data
echo "=== Data Integrity Check ==="
diff /tmp/test-data.txt /tmp/retrieved-basic.txt && echo "Basic pool: Data integrity OK"
diff /tmp/test-data.txt /tmp/retrieved-performance.txt && echo "Performance pool: Data integrity OK"
diff /tmp/test-data.txt /tmp/retrieved-durability.txt && echo "Durability pool: Data integrity OK"
Subtask 4.3: Simulate OSD Failure and Test Redundancy
# Check current OSD status
ceph osd tree

# Identify OSDs containing our data
ceph osd map ec-pool-basic test-object-1

# Simulate OSD failure (choose an OSD that contains data)
# Replace 'X' with an actual OSD ID from the mapping above
OSD_ID=$(ceph osd map ec-pool-basic test-object-1 | grep -o 'osd\.[0-9]*' | head -1 | cut -d. -f2)
echo "Simulating failure of OSD: $OSD_ID"

# Mark OSD as down (simulation)
ceph osd down osd.$OSD_ID

# Wait a moment and check cluster status
sleep 10
ceph health

# Test data accessibility during OSD failure
echo "=== Testing data access during OSD failure ==="
rados -p ec-pool-basic get test-object-1 /tmp/test-during-failure.txt
diff /tmp/test-data.txt /tmp/test-during-failure.txt && echo "Data accessible during OSD failure!"

# Bring OSD back up
ceph osd up osd.$OSD_ID
Subtask 4.4: Performance Benchmarking
Let's benchmark the performance of our erasure-coded pools:

# Create benchmark script
cat > /tmp/ec_benchmark.sh << 'EOF'
#!/bin/bash

echo "=== Erasure-Coded Pool Performance Benchmark ==="

# Function to run rados bench
run_benchmark() {
    local pool=$1
    local test_type=$2
    echo "Testing $pool - $test_type"
    rados bench -p $pool 30 $test_type --no-cleanup 2>/dev/null | grep -E "(Bandwidth|Average IOPS)"
    echo "---"
}

# Benchmark write performance
echo "Write Performance:"
run_benchmark ec-pool-basic write
run_benchmark ec-pool-performance write
run_benchmark ec-pool-durability write

# Benchmark read performance
echo "Read Performance:"
run_benchmark ec-pool-basic seq
run_benchmark ec-pool-performance seq
run_benchmark ec-pool-durability seq

# Cleanup benchmark data
rados -p ec-pool-basic cleanup
rados -p ec-pool-performance cleanup
rados -p ec-pool-durability cleanup
EOF

chmod +x /tmp/ec_benchmark.sh
/tmp/ec_benchmark.sh
Subtask 4.5: Storage Efficiency Analysis
# Create storage analysis script
cat > /tmp/storage_analysis.sh << 'EOF'
#!/bin/bash

echo "=== Storage Efficiency Analysis ==="

# Function to analyze pool efficiency
analyze_pool() {
    local pool=$1
    echo "Analyzing pool: $pool"
    
    # Get pool stats
    local stats=$(ceph osd pool stats $pool)
    echo "Pool statistics:"
    echo "$stats"
    
    # Get erasure code profile
    local profile=$(ceph osd pool get $pool erasure_code_profile | awk '{print $2}')
    echo "Erasure code profile: $profile"
    
    # Get profile details
    echo "Profile details:"
    ceph osd erasure-code-profile get $profile
    echo "---"
}

# Analyze each pool
analyze_pool ec-pool-basic
analyze_pool ec-pool-performance
analyze_pool ec-pool-durability

# Calculate theoretical storage efficiency
echo "=== Theoretical Storage Efficiency ==="
echo "Basic pool (k=4, m=2): 66.67% efficiency"
echo "Performance pool (k=8, m=2): 80% efficiency"
echo "Durability pool (k=6, m=3): 66.67% efficiency"
EOF

chmod +x /tmp/storage_analysis.sh
/tmp/storage_analysis.sh
Task 5: Advanced Configuration and Optimization
Subtask 5.1: Configure Crush Rules for Erasure-Coded Pools
# View current CRUSH rules
ceph osd crush rule ls

# Create custom CRUSH rule for erasure-coded pools
ceph osd crush rule create-erasure ec-rule-custom ec-profile-basic

# Apply custom CRUSH rule to pool
ceph osd pool set ec-pool-basic crush_rule ec-rule-custom

# Verify the change
ceph osd pool get ec-pool-basic crush_rule
Subtask 5.2: Configure Pool Quotas
# Set object quota for erasure-coded pools
ceph osd pool set-quota ec-pool-basic max_objects 10000

# Set byte quota (10GB)
ceph osd pool set-quota ec-pool-basic max_bytes 10737418240

# View quota settings
ceph osd pool get-quota ec-pool-basic
Subtask 5.3: Monitor Pool Health and Statistics
# Create monitoring script
cat > /tmp/monitor_ec_pools.sh << 'EOF'
#!/bin/bash

echo "=== Erasure-Coded Pool Monitoring ==="
echo "Timestamp: $(date)"
echo

# Function to monitor pool
monitor_pool() {
    local pool=$1
    echo "Pool: $pool"
    echo "Health: $(ceph health)"
    echo "Pool stats:"
    ceph osd pool stats $pool
    echo "PG status:"
    ceph pg ls-by-pool $pool | head -5
    echo "---"
}

# Monitor all EC pools
for pool in ec-pool-basic ec-pool-performance ec-pool-durability ec-pool-lrc; do
    if ceph osd pool ls | grep -q $pool; then
        monitor_pool $pool
    fi
done

# Overall cluster status
echo "=== Overall Cluster Status ==="
ceph status
EOF

chmod +x /tmp/monitor_ec_pools.sh
/tmp/monitor_ec_pools.sh
Task 6: Troubleshooting Common Issues
Subtask 6.1: Diagnose Pool Creation Issues
# Create troubleshooting script
cat > /tmp/troubleshoot_ec.sh << 'EOF'
#!/bin/bash

echo "=== Erasure-Coded Pool Troubleshooting ==="

# Check OSD count vs erasure code requirements
echo "Checking OSD requirements:"
total_osds=$(ceph osd ls | wc -l)
echo "Total OSDs available: $total_osds"

# Check each profile requirements
for profile in $(ceph osd erasure-code-profile ls); do
    echo "Profile: $profile"
    k=$(ceph osd erasure-code-profile get $profile | grep "k=" | cut -d= -f2)
    m=$(ceph osd erasure-code-profile get $profile | grep "m=" | cut -d= -f2)
    required=$((k + m))
    echo "  Required OSDs: $required (k=$k, m=$m)"
    if [ $total_osds -ge $required ]; then
        echo "  Status: OK"
    else
        echo "  Status: INSUFFICIENT OSDs"
    fi
    echo
done

# Check for common configuration issues
echo "=== Common Issues Check ==="
echo "1. Checking for mixed OSD types:"
ceph osd tree | grep -E "(hdd|ssd|nvme)"

echo "2. Checking CRUSH map structure:"
ceph osd crush tree | head -10

echo "3. Checking pool PG counts:"
ceph osd pool ls detail | grep -E "(pool|pg_num)"
EOF

chmod +x /tmp/troubleshoot_ec.sh
/tmp/troubleshoot_ec.sh
Subtask 6.2: Fix Common Configuration Problems
# Script to fix common issues
cat > /tmp/fix_ec_issues.sh << 'EOF'
#!/bin/bash

echo "=== Fixing Common EC Pool Issues ==="

# Function to fix PG count if needed
fix_pg_count() {
    local pool=$1
    local current_pgs=$(ceph osd pool get $pool pg_num | awk '{print $2}')
    local osd_count=$(ceph osd ls | wc -l)
    local recommended_pgs=$((osd_count * 100 / 3))
    
    echo "Pool $pool: Current PGs=$current_pgs, Recommended=$recommended_pgs"
    
    if [ $current_pgs -ne $recommended_pgs ]; then
        echo "Adjusting PG count for $pool"
        ceph osd pool set $pool pg_num $recommended_pgs
        ceph osd pool set $pool pgp_num $recommended_pgs
    fi
}

# Check and fix PG counts for EC pools
for pool in $(ceph osd pool ls | grep ec-pool); do
    fix_pg_count $pool
done

echo "=== Verification ==="
ceph health
EOF

chmod +x /tmp/fix_ec_issues.sh
# Uncomment the next line if you need to run fixes
# /tmp/fix_ec_issues.sh
Task 7: Cleanup and Best Practices
Subtask 7.1: Document Your Configuration
# Create configuration documentation
cat > /tmp/ec_pool_documentation.txt << 'EOF'
=== Erasure-Coded Pool Configuration Documentation ===

Created Profiles:
1. ec-profile-basic (k=4, m=2) - Balanced configuration
2. ec-profile-performance (k=8, m=2) - High performance
3. ec-profile-durability (k=6, m=3) - High durability
4. ec-profile-lrc (LRC plugin) - Optimized repair

Created Pools:
1. ec-pool-basic - General purpose erasure-coded storage
2. ec-pool-performance - High-performance applications
3. ec-pool-durability - Critical data storage
4. ec-pool-lrc - Optimized for repair operations

Best Practices Applied:
- Appropriate PG counts based on OSD count
- Application labels assigned to pools
- Quotas configured for resource management
- Custom CRUSH rules for optimal placement
- Monitoring scripts for ongoing maintenance

Storage Efficiency Achieved:
- Basic: 66.67% vs 33.33% (replicated)
- Performance: 80% vs 33.33% (replicated)
- Durability: 66.67% vs 33.33% (replicated)
EOF

cat /tmp/ec_pool_documentation.txt
Subtask 7.2: Create Maintenance Scripts
# Create daily maintenance script
cat > /tmp/ec_daily_maintenance.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/ceph-ec-maintenance.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting EC pool maintenance" >> $LOG_FILE

# Check cluster health
echo "[$DATE] Cluster health: $(ceph health)" >> $LOG_FILE

# Check EC pool statistics
for pool in $(ceph osd pool ls | grep ec-pool); do
    echo "[$DATE] Pool $pool stats:" >> $LOG_FILE
    ceph osd pool stats $pool >> $LOG_FILE 2>&1
done

# Check for any degraded PGs
degraded_pgs=$(ceph pg ls | grep -c degraded)
if [ $degraded_pgs -gt 0 ]; then
    echo "[$DATE] WARNING: $degraded_pgs degraded PGs found" >> $LOG_FILE
fi

echo "[$DATE] EC pool maintenance completed" >> $LOG_FILE
EOF

chmod +x /tmp/ec_daily_maintenance.sh
Subtask 7.3: Optional Cleanup (if needed)
# Cleanup script (use with caution)
cat > /tmp/cleanup_ec_lab.sh << 'EOF'
#!/bin/bash

echo "=== EC Pool Cleanup Script ==="
echo "WARNING: This will delete all test pools and data!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    # Remove test objects
    for pool in ec-pool-basic ec-pool-performance ec-pool-durability ec-pool-lrc; do
        if ceph osd pool ls | grep -q $pool; then
            echo "Cleaning objects from $pool"
            rados -p $pool ls | xargs -I {} rados -p $pool rm {}
        fi
    done
    
    # Remove pools (uncomment if you want to delete pools)
    # ceph osd pool delete ec-pool-basic ec-pool-basic --yes-i-really-really-mean-it
    # ceph osd pool delete ec-pool-performance ec-pool-performance --yes-i-really-really-mean-it
    # ceph osd pool delete ec-pool-durability ec-pool-durability --yes-i-really-really-mean-it
    # ceph osd pool delete ec-pool-lrc ec-pool-lrc --yes-i-really-really-mean-it
    
    echo "Cleanup completed"
else
    echo "Cleanup cancelled"
fi
EOF

chmod +x /tmp/cleanup_ec_lab.sh
# Run only if you want to clean up: /tmp/cleanup_ec_lab.sh
Troubleshooting Common Issues
Issue 1: Insufficient OSDs for Erasure Code Profile
Problem: Error creating pool due to insufficient OSDs Solution:

# Check OSD count
ceph osd ls | wc -l

# Adjust profile parameters or add more OSDs
# For testing, create a smaller profile
ceph osd erasure-code-profile set ec-profile-small k=2 m=1 plugin=jerasure technique=reed_sol_van
Issue 2: Pool Creation Fails
Problem: Pool creation command fails Solution:

# Check for existing pools with same name
ceph osd pool ls | grep pool-name

# Verify profile exists
ceph osd erasure-code-profile ls

# Check cluster health
ceph health detail
Issue 3: Poor Performance
Problem: Erasure-coded pool shows poor performance Solution:

# Check PG distribution
ceph pg ls-by-pool pool-name

# Verify CRUSH rule
ceph osd pool get pool-name crush_rule

# Consider adjusting k/m ratio for better performance
Conclusion
In this comprehensive lab, you have successfully:

• Mastered Erasure Coding Fundamentals: You learned how erasure coding works, including the concepts of data chunks (k) and parity chunks (m), and how they provide data protection with better storage efficiency than traditional replication.

• Created Multiple Pool Profiles: You configured various erasure-coded pool profiles optimized for different use cases - balanced performance, high performance, maximum durability, and optimized repair operations using LRC.

• Implemented Advanced Configurations: You applied custom CRUSH rules, configured quotas, and set up monitoring for your erasure-coded pools, demonstrating enterprise-level storage management skills.

• Validated Redundancy and Performance: Through comprehensive testing, you verified that erasure-coded pools maintain data integrity even during OSD failures while providing significantly better storage efficiency (66-80%) compared to replicated pools (33%).

• Developed Operational Skills: You created monitoring and maintenance scripts, learned troubleshooting techniques, and documented configurations following best practices for production environments.

Why This Matters
Erasure coding is crucial for modern storage systems because it:

Reduces Storage Costs: Achieves 2-3x better storage efficiency than replication
Maintains High Durability: Provides configurable levels of fault tolerance
Scales Efficiently: Works well in large-scale distributed storage environments
Optimizes Resources: Balances performance, durability, and storage efficiency
Next Steps
To further develop your Ceph expertise:

Explore advanced erasure coding plugins (ISA-L, SHEC)
Implement erasure coding in production workloads
Study performance tuning for specific applications
Learn about erasure coding in multi-site deployments
This lab has prepared you for the Red Hat Certified Specialist in Ceph Cloud Storage exam by providing hands-on experience with one of the most important advanced features in modern distributed storage systems.
