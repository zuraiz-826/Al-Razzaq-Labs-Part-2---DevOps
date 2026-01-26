Lab 9: Performance Tuning in Ceph
Objectives
By the end of this lab, students will be able to:

Monitor and analyze Ceph cluster performance using the Ceph dashboard and command-line tools
Identify performance bottlenecks in OSD, MON, and MGR components
Configure and tune critical Ceph parameters for optimal performance
Analyze Placement Group (PG) states and optimize recovery operations
Implement best practices for Ceph cluster performance optimization
Troubleshoot common performance issues in production environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph architecture and components (OSDs, MONs, MGRs)
Familiarity with Linux command-line interface
Knowledge of storage concepts (IOPS, throughput, latency)
Understanding of Ceph pools and placement groups
Experience with basic Ceph administration commands
Access to a functional Ceph cluster (minimum 3 nodes)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph cluster already deployed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ceph nodes (ceph-node1, ceph-node2, ceph-node3)
Ceph Octopus or newer version pre-installed
Ceph dashboard enabled and configured
Sample data pools for testing
Task 1: Monitor Cluster Performance Using Ceph Dashboard
Subtask 1.1: Access and Configure Ceph Dashboard
Step 1: Connect to your primary Ceph node

# SSH to the first Ceph node
ssh root@ceph-node1
Step 2: Verify Ceph cluster status

# Check overall cluster health
ceph status

# Verify all services are running
ceph orch ls
Step 3: Enable and configure Ceph dashboard if not already active

# Enable the dashboard module
ceph mgr module enable dashboard

# Create dashboard admin user
ceph dashboard ac-user-create admin administrator

# Set dashboard password (use 'cephlab123' for this lab)
ceph dashboard ac-user-set-password admin cephlab123

# Get dashboard URL
ceph mgr services
Step 4: Access the dashboard through your web browser

# Get the dashboard access URL and port
ceph config get mgr mgr/dashboard/server_addr
ceph config get mgr mgr/dashboard/server_port
Navigate to https://[node-ip]:8443 in your browser and login with admin/cephlab123.

Subtask 1.2: Analyze Performance Metrics
Step 1: Navigate through dashboard sections

Click on Cluster → Hosts to view node performance
Go to Cluster → OSDs to examine OSD statistics
Visit Cluster → Pools to analyze pool performance
Step 2: Generate baseline performance data

# Create a test pool for performance testing
ceph osd pool create performance-test 64 64

# Enable RBD on the pool
ceph osd pool application enable performance-test rbd

# Create an RBD image for testing
rbd create --size 10G performance-test/test-image
Step 3: Run initial performance tests

# Install fio for performance testing
yum install -y fio

# Create a simple performance test script
cat > /tmp/ceph-perf-test.sh << 'EOF'
#!/bin/bash
echo "Starting Ceph Performance Baseline Test"

# Map RBD image
rbd map performance-test/test-image

# Find the mapped device
DEVICE=$(rbd showmapped | grep test-image | awk '{print $5}')
echo "Mapped device: $DEVICE"

# Run sequential write test
echo "Running sequential write test..."
fio --name=seq-write --ioengine=libaio --rw=write --bs=4M --size=1G --numjobs=1 --filename=$DEVICE --direct=1 --runtime=60 --time_based

# Run random read test
echo "Running random read test..."
fio --name=rand-read --ioengine=libaio --rw=randread --bs=4K --size=1G --numjobs=4 --filename=$DEVICE --direct=1 --runtime=60 --time_based

# Unmap the device
rbd unmap $DEVICE
echo "Performance test completed"
EOF

chmod +x /tmp/ceph-perf-test.sh
/tmp/ceph-perf-test.sh
Step 4: Monitor performance in real-time

# Monitor cluster performance during tests
watch -n 2 'ceph status'

# In another terminal, monitor OSD performance
watch -n 2 'ceph osd perf'

# Monitor pool statistics
watch -n 2 'ceph osd pool stats'
Task 2: Tune OSD, MON, and MGR Parameters for Better Performance
Subtask 2.1: OSD Performance Tuning
Step 1: Analyze current OSD configuration

# Check current OSD configuration
ceph config dump | grep osd

# View OSD performance statistics
ceph osd perf

# Check OSD utilization
ceph osd df
Step 2: Optimize OSD journal and WAL settings

# Set optimal journal size (for FileStore OSDs)
ceph config set osd osd_journal_size 10240

# Configure BlueStore cache settings (for BlueStore OSDs)
ceph config set osd bluestore_cache_size_hdd 1073741824
ceph config set osd bluestore_cache_size_ssd 3221225472

# Set optimal WAL and DB sizes for BlueStore
ceph config set osd bluestore_block_wal_size 1073741824
ceph config set osd bluestore_block_db_size 68719476736
Step 3: Tune OSD threading and queue parameters

# Optimize OSD operation threads
ceph config set osd osd_op_threads 8
ceph config set osd osd_disk_threads 4

# Configure queue sizes
ceph config set osd osd_op_queue_max_ops 4000
ceph config set osd osd_op_queue_max_bytes 104857600

# Set recovery and backfill parameters
ceph config set osd osd_recovery_max_active 5
ceph config set osd osd_max_backfills 2
ceph config set osd osd_recovery_op_priority 2
Step 4: Configure OSD memory and CPU settings

# Set memory target for BlueStore
ceph config set osd bluestore_cache_meta_ratio 0.4
ceph config set osd bluestore_cache_kv_ratio 0.4

# Configure OSD heartbeat settings
ceph config set osd osd_heartbeat_interval 10
ceph config set osd osd_heartbeat_grace 30

# Set OSD scrubbing parameters for better performance
ceph config set osd osd_scrub_begin_hour 22
ceph config set osd osd_scrub_end_hour 6
ceph config set osd osd_scrub_load_threshold 0.5
Subtask 2.2: MON Performance Tuning
Step 1: Analyze MON performance

# Check MON status and performance
ceph mon stat
ceph mon dump

# Monitor MON store size
ceph daemon mon.$(hostname) mon_status | grep store_stats
Step 2: Optimize MON database settings

# Configure MON data store compaction
ceph config set mon mon_compact_on_start true
ceph config set mon mon_compact_on_trim true

# Set optimal MON sync settings
ceph config set mon mon_sync_max_payload_size 1048576
ceph config set mon mon_sync_timeout 60

# Configure MON election timeout
ceph config set mon mon_election_timeout 5
Step 3: Tune MON memory and storage

# Set MON data store cache size
ceph config set mon rocksdb_cache_size 134217728

# Configure MON log settings
ceph config set mon mon_max_log_entries_per_event 4096
ceph config set mon mon_health_to_clog_interval 600

# Set MON osdmap cache settings
ceph config set mon mon_osdmap_cache_size 500
Subtask 2.3: MGR Performance Tuning
Step 1: Analyze MGR performance

# Check MGR status
ceph mgr stat
ceph mgr dump

# List active MGR modules
ceph mgr module ls
Step 2: Optimize MGR module settings

# Configure MGR service reporting intervals
ceph config set mgr mgr_stats_period 5
ceph config set mgr mgr_client_service_daemon_unregister_timeout 60

# Optimize dashboard refresh rates
ceph config set mgr mgr/dashboard/feature_toggle_dashboard false
ceph config set mgr mgr/dashboard/grafana_update_dashboards false

# Configure telemetry settings
ceph config set mgr mgr/telemetry/enabled false
Step 3: Apply and verify configuration changes

# Restart OSDs to apply changes (do this one by one)
systemctl restart ceph-osd@0
systemctl restart ceph-osd@1
systemctl restart ceph-osd@2

# Restart MON services
systemctl restart ceph-mon@$(hostname)

# Restart MGR service
systemctl restart ceph-mgr@$(hostname)

# Verify all services are running
ceph status
Task 3: Analyze PG States and Recovery Speeds
Subtask 3.1: Analyze Placement Group States
Step 1: Examine current PG states

# Check overall PG status
ceph pg stat

# List all PG states
ceph pg ls

# Get detailed PG information
ceph pg dump | head -20
Step 2: Identify problematic PGs

# Find PGs in non-active+clean states
ceph pg ls-by-state

# Check for stuck PGs
ceph pg ls-by-state stale
ceph pg ls-by-state inactive
ceph pg ls-by-state unclean

# Analyze PG distribution
ceph osd tree
ceph pg ls-by-osd
Step 3: Create a PG analysis script

cat > /tmp/pg-analysis.sh << 'EOF'
#!/bin/bash
echo "=== Ceph PG Analysis Report ==="
echo "Date: $(date)"
echo

echo "1. Overall PG Statistics:"
ceph pg stat
echo

echo "2. PG States Summary:"
ceph pg ls-by-state | head -10
echo

echo "3. Pool PG Distribution:"
for pool in $(ceph osd lspools | awk '{print $2}'); do
    echo "Pool: $pool"
    ceph pg ls-by-pool $pool | wc -l
done
echo

echo "4. OSD PG Distribution:"
ceph pg ls-by-osd | head -10
echo

echo "5. Stuck PGs (if any):"
ceph health detail | grep -i stuck
echo

echo "=== End of Report ==="
EOF

chmod +x /tmp/pg-analysis.sh
/tmp/pg-analysis.sh
Subtask 3.2: Optimize PG Configuration
Step 1: Calculate optimal PG numbers

# Create PG calculation script
cat > /tmp/pg-calculator.sh << 'EOF'
#!/bin/bash
echo "PG Number Calculator for Ceph Pools"
echo "==================================="

# Get cluster information
TOTAL_OSDS=$(ceph osd ls | wc -l)
echo "Total OSDs: $TOTAL_OSDS"

# Calculate recommended PGs per pool
# Formula: (Total OSDs * 100) / Pool Replicas / Number of Pools
REPLICAS=3
POOLS=$(ceph osd lspools | wc -l)

RECOMMENDED_PGS=$(( (TOTAL_OSDS * 100) / REPLICAS / POOLS ))

# Round to nearest power of 2
POWER=1
while [ $POWER -lt $RECOMMENDED_PGS ]; do
    POWER=$((POWER * 2))
done

echo "Recommended PGs per pool: $POWER"
echo "Current pool configurations:"
ceph osd pool ls detail | grep -E "pool|pg_num"
EOF

chmod +x /tmp/pg-calculator.sh
/tmp/pg-calculator.sh
Step 2: Adjust PG numbers for optimal performance

# Increase PG count for performance-test pool (if needed)
# Note: Only increase, never decrease PG count
ceph osd pool set performance-test pg_num 128
ceph osd pool set performance-test pgp_num 128

# Monitor PG creation progress
watch -n 5 'ceph pg stat'
Subtask 3.3: Optimize Recovery and Backfill Operations
Step 1: Configure recovery parameters

# Set recovery operation limits
ceph config set global osd_recovery_max_active 3
ceph config set global osd_recovery_max_single_start 1
ceph config set global osd_max_backfills 1

# Configure recovery priority
ceph config set global osd_recovery_op_priority 1
ceph config set global osd_client_op_priority 63

# Set recovery sleep parameters
ceph config set global osd_recovery_sleep_hdd 0.1
ceph config set global osd_recovery_sleep_ssd 0.0
Step 2: Monitor recovery performance

# Create recovery monitoring script
cat > /tmp/recovery-monitor.sh << 'EOF'
#!/bin/bash
echo "Ceph Recovery Monitoring"
echo "======================="

while true; do
    clear
    echo "Time: $(date)"
    echo
    
    echo "Cluster Status:"
    ceph status | grep -E "health|recovery|backfill"
    echo
    
    echo "Recovery Progress:"
    ceph pg stat
    echo
    
    echo "Active Recovery Operations:"
    ceph pg ls | grep -E "recovery|backfill" | wc -l
    echo
    
    echo "OSD Performance:"
    ceph osd perf | head -5
    echo
    
    sleep 10
done
EOF

chmod +x /tmp/recovery-monitor.sh
# Run this in background: /tmp/recovery-monitor.sh &
Step 3: Test recovery performance

# Simulate OSD failure for recovery testing
# WARNING: This will temporarily impact cluster performance
OSD_ID=0
ceph osd out $OSD_ID

# Monitor recovery process
ceph -w

# Wait for recovery to complete, then bring OSD back
sleep 300
ceph osd in $OSD_ID
Subtask 3.4: Performance Validation
Step 1: Run comprehensive performance test

cat > /tmp/comprehensive-perf-test.sh << 'EOF'
#!/bin/bash
echo "Comprehensive Ceph Performance Test"
echo "==================================="

# Test parameters
POOL_NAME="performance-test"
IMAGE_NAME="perf-test-image"
IMAGE_SIZE="5G"

echo "1. Creating test environment..."
rbd create --size $IMAGE_SIZE $POOL_NAME/$IMAGE_NAME
rbd map $POOL_NAME/$IMAGE_NAME
DEVICE=$(rbd showmapped | grep $IMAGE_NAME | awk '{print $5}')

echo "2. Running sequential write test..."
fio --name=seq-write --ioengine=libaio --rw=write --bs=1M --size=2G \
    --numjobs=1 --filename=$DEVICE --direct=1 --runtime=120 --time_based \
    --output-format=json --output=/tmp/seq-write.json

echo "3. Running sequential read test..."
fio --name=seq-read --ioengine=libaio --rw=read --bs=1M --size=2G \
    --numjobs=1 --filename=$DEVICE --direct=1 --runtime=120 --time_based \
    --output-format=json --output=/tmp/seq-read.json

echo "4. Running random write test..."
fio --name=rand-write --ioengine=libaio --rw=randwrite --bs=4K --size=1G \
    --numjobs=4 --filename=$DEVICE --direct=1 --runtime=120 --time_based \
    --output-format=json --output=/tmp/rand-write.json

echo "5. Running random read test..."
fio --name=rand-read --ioengine=libaio --rw=randread --bs=4K --size=1G \
    --numjobs=4 --filename=$DEVICE --direct=1 --runtime=120 --time_based \
    --output-format=json --output=/tmp/rand-read.json

echo "6. Cleaning up..."
rbd unmap $DEVICE
rbd rm $POOL_NAME/$IMAGE_NAME

echo "Performance test completed. Results saved in /tmp/"
echo "Sequential Write: $(cat /tmp/seq-write.json | jq '.jobs[0].write.bw')"
echo "Sequential Read: $(cat /tmp/seq-read.json | jq '.jobs[0].read.bw')"
echo "Random Write IOPS: $(cat /tmp/rand-write.json | jq '.jobs[0].write.iops')"
echo "Random Read IOPS: $(cat /tmp/rand-read.json | jq '.jobs[0].read.iops')"
EOF

chmod +x /tmp/comprehensive-perf-test.sh
# Install jq for JSON parsing
yum install -y jq
/tmp/comprehensive-perf-test.sh
Step 2: Compare before and after performance

# Create performance comparison report
cat > /tmp/performance-report.sh << 'EOF'
#!/bin/bash
echo "Ceph Performance Tuning Report"
echo "=============================="
echo "Date: $(date)"
echo

echo "Cluster Configuration:"
echo "- Total OSDs: $(ceph osd ls | wc -l)"
echo "- Total MONs: $(ceph mon stat | grep -o '[0-9]* mons')"
echo "- Total MGRs: $(ceph mgr stat | grep -o '[0-9]* mgrs')"
echo

echo "Key Performance Settings:"
echo "- OSD Op Threads: $(ceph config get osd osd_op_threads)"
echo "- Recovery Max Active: $(ceph config get osd osd_recovery_max_active)"
echo "- BlueStore Cache Size: $(ceph config get osd bluestore_cache_size_hdd)"
echo

echo "Current Cluster Status:"
ceph status
echo

echo "PG Statistics:"
ceph pg stat
echo

echo "OSD Performance:"
ceph osd perf
echo

echo "Pool Statistics:"
ceph osd pool stats
EOF

chmod +x /tmp/performance-report.sh
/tmp/performance-report.sh > /tmp/final-performance-report.txt
cat /tmp/final-performance-report.txt
Troubleshooting Common Issues
Issue 1: High Latency
Symptoms: Slow I/O operations, high client wait times

Solutions:

# Check for slow OSDs
ceph osd perf

# Identify network issues
ceph osd tree

# Verify disk performance on OSD nodes
iostat -x 1 5
Issue 2: Uneven PG Distribution
Symptoms: Some OSDs are fuller than others

Solutions:

# Check OSD utilization
ceph osd df

# Rebalance cluster
ceph osd reweight-by-utilization 105

# Monitor rebalancing
ceph -w
Issue 3: Stuck PGs
Symptoms: PGs remain in inactive or unclean states

Solutions:

# Identify stuck PGs
ceph pg ls-by-state inactive
ceph pg ls-by-state unclean

# Force PG creation (use carefully)
ceph pg force-create-pg <pg-id>

# Query specific PG
ceph pg <pg-id> query
Conclusion
In this comprehensive lab, you have successfully:

Monitored cluster performance using the Ceph dashboard and command-line tools, establishing baseline metrics and identifying performance bottlenecks

Optimized critical parameters for OSDs (threading, caching, recovery), MONs (database settings, sync parameters), and MGRs (module configurations, reporting intervals)

Analyzed and optimized Placement Groups by calculating optimal PG numbers, monitoring PG states, and configuring recovery operations for better performance

Validated performance improvements through comprehensive testing and monitoring, demonstrating the impact of tuning efforts

Why This Matters: Performance tuning is crucial for production Ceph deployments because:

Cost Efficiency: Optimized clusters require fewer resources to achieve the same performance levels
User Experience: Better performance directly translates to faster application response times
Scalability: Well-tuned clusters can handle growth more effectively
Reliability: Proper tuning reduces the likelihood of performance-related failures
Operational Excellence: Understanding performance characteristics enables proactive management
The skills you've developed in this lab are essential for maintaining high-performance Ceph storage systems in enterprise environments. These optimization techniques will help you maximize the return on investment for storage infrastructure while ensuring reliable service delivery to applications and users.

Remember to always test performance changes in non-production environments first, and monitor the impact of tuning adjustments carefully to ensure they provide the expected benefits without introducing new issues.
