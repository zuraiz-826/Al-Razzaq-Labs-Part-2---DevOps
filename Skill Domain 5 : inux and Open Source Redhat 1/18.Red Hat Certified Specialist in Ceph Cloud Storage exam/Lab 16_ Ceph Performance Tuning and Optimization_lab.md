Lab 16: Ceph Performance Tuning and Optimization
Objectives
By the end of this lab, students will be able to:

Understand Ceph performance bottlenecks and optimization strategies
Configure and optimize CRUSH maps for improved data distribution
Tune pool configurations for enhanced performance
Optimize OSD (Object Storage Daemon) parameters for better throughput
Configure MON (Monitor) settings for improved cluster performance
Implement networking optimizations for Ceph clusters
Measure and validate performance improvements using benchmarking tools
Apply best practices for Ceph performance tuning in production environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph architecture (OSDs, MONs, MGRs)
Experience with Linux command line operations
Knowledge of storage concepts (IOPS, throughput, latency)
Familiarity with YAML configuration files
Understanding of networking concepts
Completed previous Ceph labs or equivalent experience
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph already installed. Simply click "Start Lab" to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ceph monitor nodes (ceph-mon-01, ceph-mon-02, ceph-mon-03)
6 Ceph OSD nodes (ceph-osd-01 through ceph-osd-06)
1 Ceph admin node (ceph-admin)
Pre-installed Ceph Octopus cluster
Performance testing tools (fio, rados bench)
Task 1: Analyze Current Cluster Performance and Baseline Measurements
Subtask 1.1: Check Cluster Health and Status
First, let's establish our baseline performance metrics.

Connect to the admin node and check cluster status:
# SSH to the admin node
ssh ceph-admin

# Check overall cluster health
sudo ceph health detail

# View cluster status
sudo ceph -s

# Check OSD tree structure
sudo ceph osd tree
Examine current pool configurations:
# List all pools
sudo ceph osd lspools

# Check pool details (assuming 'rbd' pool exists)
sudo ceph osd pool get rbd all

# View CRUSH map
sudo ceph osd getcrushmap -o crushmap.bin
sudo crushtool -d crushmap.bin -o crushmap.txt
cat crushmap.txt
Subtask 1.2: Perform Baseline Performance Tests
Test RADOS performance:
# Create a test pool for benchmarking
sudo ceph osd pool create benchmark 128 128

# Run RADOS bench write test (10 seconds, 4MB objects)
sudo rados bench -p benchmark 10 write --no-cleanup

# Run RADOS bench read test
sudo rados bench -p benchmark 10 seq

# Run random read test
sudo rados bench -p benchmark 10 rand
Test RBD performance:
# Create an RBD image for testing
sudo rbd create --size 10G --pool benchmark test-image

# Map the RBD image
sudo rbd map benchmark/test-image

# Find the mapped device
lsblk | grep rbd

# Run fio benchmark on the RBD device (replace /dev/rbd0 with actual device)
sudo fio --name=rbd-test --ioengine=libaio --direct=1 --bs=4k --iodepth=32 \
    --rw=randwrite --runtime=60 --filename=/dev/rbd0 --size=1G
Record baseline metrics:
# Create a performance log file
echo "=== BASELINE PERFORMANCE METRICS ===" > ~/performance_log.txt
echo "Date: $(date)" >> ~/performance_log.txt
echo "" >> ~/performance_log.txt

# Record current OSD settings
echo "Current OSD Settings:" >> ~/performance_log.txt
sudo ceph config dump | grep osd >> ~/performance_log.txt
echo "" >> ~/performance_log.txt
Task 2: Optimize CRUSH Map and Pool Configurations
Subtask 2.1: Analyze and Optimize CRUSH Map
Examine current CRUSH map structure:
# View current CRUSH rules
sudo ceph osd crush rule ls
sudo ceph osd crush rule dump

# Check current data distribution
sudo ceph pg dump | grep -E "^[0-9]" | awk '{print $1, $15}' | head -20
Create an optimized CRUSH rule for performance:
# Create a new CRUSH rule optimized for SSDs (if available)
sudo ceph osd crush rule create-replicated ssd_rule default host ssd

# Or create a rule that spreads across racks for better performance
sudo ceph osd crush rule create-replicated performance_rule default rack
Modify the CRUSH map for better distribution:
# Export current CRUSH map
sudo ceph osd getcrushmap -o crushmap_original.bin
sudo crushtool -d crushmap_original.bin -o crushmap_original.txt

# Create a backup
cp crushmap_original.txt crushmap_optimized.txt

# Edit the CRUSH map to optimize weights and structure
sudo nano crushmap_optimized.txt
Example CRUSH map optimization:

# Add this optimized rule to your CRUSH map
rule performance_rule {
    id 1
    type replicated
    min_size 1
    max_size 10
    step take default
    step choose firstn 0 type rack
    step chooseleaf firstn 0 type host
    step emit
}
Apply the optimized CRUSH map:
# Compile and apply the new CRUSH map
sudo crushtool -c crushmap_optimized.txt -o crushmap_optimized.bin
sudo ceph osd setcrushmap -i crushmap_optimized.bin

# Verify the changes
sudo ceph osd crush rule ls
Subtask 2.2: Optimize Pool Configurations
Tune pool parameters for performance:
# Optimize the benchmark pool
sudo ceph osd pool set benchmark size 2  # Reduce replica count for better write performance
sudo ceph osd pool set benchmark min_size 1
sudo ceph osd pool set benchmark pg_num 256  # Increase PG count for better distribution
sudo ceph osd pool set benchmark pgp_num 256

# Set the pool to use our optimized CRUSH rule
sudo ceph osd pool set benchmark crush_rule performance_rule
Configure pool-specific optimizations:
# Enable fast read for better read performance
sudo ceph osd pool set benchmark fast_read true

# Optimize for write performance
sudo ceph osd pool set benchmark write_fadvise_dontneed true

# Set application type for better optimization
sudo ceph osd pool application enable benchmark rbd
Configure RBD-specific optimizations:
# Create an optimized RBD pool
sudo ceph osd pool create rbd_optimized 256 256
sudo ceph osd pool set rbd_optimized size 2
sudo ceph osd pool set rbd_optimized min_size 1
sudo ceph osd pool application enable rbd_optimized rbd

# Initialize the pool for RBD
sudo rbd pool init rbd_optimized
Task 3: Tune OSDs for Better Throughput
Subtask 3.1: Optimize OSD Configuration Parameters
Configure OSD performance settings:
# Set OSD-wide performance parameters
sudo ceph config set osd osd_op_threads 8
sudo ceph config set osd osd_disk_threads 4
sudo ceph config set osd osd_recovery_threads 2

# Optimize memory usage
sudo ceph config set osd osd_memory_target 4294967296  # 4GB
sudo ceph config set osd bluestore_cache_size 2147483648  # 2GB

# Optimize I/O settings
sudo ceph config set osd osd_max_backfills 2
sudo ceph config set osd osd_recovery_max_active 3
sudo ceph config set osd osd_recovery_max_single_start 1
Configure BlueStore optimizations:
# Optimize BlueStore settings
sudo ceph config set osd bluestore_min_alloc_size 4096
sudo ceph config set osd bluestore_prefer_deferred_size 32768
sudo ceph config set osd bluestore_compression_algorithm snappy
sudo ceph config set osd bluestore_compression_mode aggressive
Set OSD journal and WAL optimizations:
# Configure RocksDB settings for better performance
sudo ceph config set osd bluestore_rocksdb_options "compression=kNoCompression,max_write_buffer_number=4,min_write_buffer_number_to_merge=1,recycle_log_file_num=4,write_buffer_size=268435456,writable_file_max_buffer_size=0,compaction_readahead_size=2097152"
Subtask 3.2: Optimize Individual OSD Settings
Check current OSD utilization:
# View OSD performance statistics
sudo ceph osd perf

# Check OSD utilization
sudo ceph osd df

# Monitor OSD operations
sudo ceph osd pool stats
Apply per-OSD optimizations:
# Set CPU affinity for OSDs (example for OSD.0)
sudo systemctl edit ceph-osd@0.service
Add this content to the service override:

[Service]
CPUAffinity=0-3
IOSchedulingClass=1
IOSchedulingPriority=4
Restart OSDs to apply changes:
# Restart OSDs one by one to avoid downtime
for osd in 0 1 2 3 4 5; do
    echo "Restarting OSD.$osd"
    sudo systemctl restart ceph-osd@$osd
    sleep 30
    sudo ceph health
done
Task 4: Configure MON Settings for Improved Performance
Subtask 4.1: Optimize Monitor Configuration
Configure MON performance settings:
# Optimize monitor database settings
sudo ceph config set mon mon_compact_on_start true
sudo ceph config set mon mon_compact_on_bootstrap true
sudo ceph config set mon mon_compact_on_trim true

# Optimize election and heartbeat settings
sudo ceph config set mon mon_election_timeout 5
sudo ceph config set mon mon_lease 5
sudo ceph config set mon mon_lease_renew_interval_factor 0.6
Configure MON memory and CPU settings:
# Set memory limits for monitors
sudo ceph config set mon mon_osd_cache_size 1024
sudo ceph config set mon mon_pg_warn_max_per_osd 300

# Optimize logging for performance
sudo ceph config set mon debug_mon 1
sudo ceph config set mon debug_paxos 1
Subtask 4.2: Optimize Cluster-Wide Settings
Configure global performance parameters:
# Optimize client I/O settings
sudo ceph config set global rbd_cache true
sudo ceph config set global rbd_cache_size 67108864  # 64MB
sudo ceph config set global rbd_cache_max_dirty 50331648  # 48MB
sudo ceph config set global rbd_cache_writethrough_until_flush true

# Optimize network settings
sudo ceph config set global ms_tcp_nodelay true
sudo ceph config set global ms_tcp_rcvbuf 65536
Configure PG and placement settings:
# Optimize PG settings for performance
sudo ceph config set mgr mgr/pg_autoscaler/sleep_interval 60
sudo ceph config set osd osd_pg_max_concurrent_snap_trims 1
sudo ceph config set osd osd_snap_trim_sleep 0.1
Task 5: Implement Networking Optimizations
Subtask 5.1: Configure Network Performance Settings
Optimize network interface settings:
# Check current network configuration
ip addr show
ethtool eth0

# Configure network buffer sizes (run on all nodes)
echo 'net.core.rmem_default = 262144' | sudo tee -a /etc/sysctl.conf
echo 'net.core.rmem_max = 16777216' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_default = 262144' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem = 4096 65536 16777216' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 16777216' | sudo tee -a /etc/sysctl.conf

# Apply the changes
sudo sysctl -p
Configure Ceph network settings:
# Set network-specific Ceph configurations
sudo ceph config set global ms_tcp_read_timeout 900
sudo ceph config set global ms_tcp_nodelay true
sudo ceph config set global ms_async_op_threads 3
sudo ceph config set global ms_async_max_op_threads 5
Subtask 5.2: Optimize Network Topology
Configure separate networks for cluster and public traffic:
# Check current network configuration
sudo ceph config get mon public_network
sudo ceph config get mon cluster_network

# If not already configured, set up separate networks
# (This would typically be done during initial setup)
# sudo ceph config set mon public_network 192.168.1.0/24
# sudo ceph config set mon cluster_network 192.168.2.0/24
Monitor network performance:
# Install network monitoring tools
sudo yum install -y iftop nethogs

# Monitor network traffic during tests
sudo iftop -i eth0
Task 6: Test and Measure Performance Improvements
Subtask 6.1: Run Comprehensive Performance Tests
Test RADOS performance after optimizations:
# Clean up previous test data
sudo rados -p benchmark cleanup

# Run optimized RADOS bench tests
echo "=== POST-OPTIMIZATION RADOS PERFORMANCE ===" >> ~/performance_log.txt
echo "Date: $(date)" >> ~/performance_log.txt

# Write test
sudo rados bench -p benchmark 60 write --no-cleanup -t 16 | tee -a ~/performance_log.txt

# Sequential read test
sudo rados bench -p benchmark 60 seq -t 16 | tee -a ~/performance_log.txt

# Random read test
sudo rados bench -p benchmark 60 rand -t 16 | tee -a ~/performance_log.txt
Test RBD performance:
# Create a new optimized RBD image
sudo rbd create --size 10G --pool rbd_optimized test-image-optimized \
    --image-feature layering,exclusive-lock,object-map,fast-diff

# Map the image
sudo rbd map rbd_optimized/test-image-optimized

# Find the device
RBD_DEV=$(lsblk | grep rbd | tail -1 | awk '{print $1}')
echo "Testing on device: /dev/$RBD_DEV"

# Run comprehensive fio tests
echo "=== POST-OPTIMIZATION RBD PERFORMANCE ===" >> ~/performance_log.txt

# Random write test
sudo fio --name=rbd-randwrite --ioengine=libaio --direct=1 --bs=4k \
    --iodepth=32 --rw=randwrite --runtime=60 --filename=/dev/$RBD_DEV \
    --size=2G --numjobs=4 --group_reporting | tee -a ~/performance_log.txt

# Random read test
sudo fio --name=rbd-randread --ioengine=libaio --direct=1 --bs=4k \
    --iodepth=32 --rw=randread --runtime=60 --filename=/dev/$RBD_DEV \
    --size=2G --numjobs=4 --group_reporting | tee -a ~/performance_log.txt

# Sequential write test
sudo fio --name=rbd-seqwrite --ioengine=libaio --direct=1 --bs=1M \
    --iodepth=8 --rw=write --runtime=60 --filename=/dev/$RBD_DEV \
    --size=2G --group_reporting | tee -a ~/performance_log.txt
Subtask 6.2: Monitor and Analyze Performance Metrics
Monitor cluster performance during tests:
# Monitor OSD performance
watch -n 5 'ceph osd perf'

# Monitor cluster I/O
watch -n 5 'ceph -s'

# Check PG distribution
sudo ceph pg dump | grep -E "^[0-9]" | awk '{print $1, $15}' | sort | uniq -c
Generate performance comparison report:
# Create a comprehensive performance report
cat > ~/generate_performance_report.sh << 'EOF'
#!/bin/bash

echo "=== CEPH PERFORMANCE OPTIMIZATION REPORT ===" > ~/performance_report.txt
echo "Generated on: $(date)" >> ~/performance_report.txt
echo "" >> ~/performance_report.txt

echo "=== CLUSTER STATUS ===" >> ~/performance_report.txt
ceph -s >> ~/performance_report.txt
echo "" >> ~/performance_report.txt

echo "=== OSD PERFORMANCE ===" >> ~/performance_report.txt
ceph osd perf >> ~/performance_report.txt
echo "" >> ~/performance_report.txt

echo "=== POOL STATISTICS ===" >> ~/performance_report.txt
ceph osd pool stats >> ~/performance_report.txt
echo "" >> ~/performance_report.txt

echo "=== CURRENT CONFIGURATION ===" >> ~/performance_report.txt
ceph config dump | grep -E "(osd_|mon_|bluestore_)" >> ~/performance_report.txt
echo "" >> ~/performance_report.txt

echo "Performance report generated: ~/performance_report.txt"
EOF

chmod +x ~/generate_performance_report.sh
./generate_performance_report.sh
Subtask 6.3: Validate and Document Improvements
Compare before and after metrics:
# Display performance comparison
echo "=== PERFORMANCE COMPARISON SUMMARY ===" >> ~/performance_log.txt
echo "Review the complete log to compare baseline vs optimized performance" >> ~/performance_log.txt
echo "" >> ~/performance_log.txt

# View the complete performance log
cat ~/performance_log.txt
Document optimization settings:
# Create optimization documentation
cat > ~/optimization_summary.txt << 'EOF'
=== CEPH PERFORMANCE OPTIMIZATION SUMMARY ===

1. CRUSH Map Optimizations:
   - Created performance-optimized CRUSH rule
   - Improved data distribution across OSDs

2. Pool Optimizations:
   - Reduced replica count to 2 for better write performance
   - Increased PG count for better distribution
   - Enabled fast_read for improved read performance

3. OSD Optimizations:
   - Increased op_threads and disk_threads
   - Optimized BlueStore cache settings
   - Configured compression settings
   - Set memory targets appropriately

4. MON Optimizations:
   - Enabled database compaction
   - Optimized election timeouts
   - Configured cache sizes

5. Network Optimizations:
   - Tuned TCP buffer sizes
   - Enabled TCP nodelay
   - Optimized async operation threads

6. Global Optimizations:
   - Enabled RBD caching
   - Optimized client I/O settings
   - Configured PG autoscaler
EOF

cat ~/optimization_summary.txt
Troubleshooting Common Issues
Issue 1: Performance Degradation After Changes
Symptoms: Cluster performance is worse after optimization

Solution:

# Check cluster health
sudo ceph health detail

# Verify all OSDs are up and in
sudo ceph osd stat

# Check for any stuck PGs
sudo ceph pg stat

# If needed, revert specific settings
sudo ceph config rm osd osd_op_threads
sudo ceph config rm osd bluestore_cache_size
Issue 2: High CPU Usage on OSDs
Symptoms: OSDs consuming excessive CPU resources

Solution:

# Reduce thread counts
sudo ceph config set osd osd_op_threads 4
sudo ceph config set osd osd_disk_threads 2

# Check CPU affinity settings
sudo systemctl status ceph-osd@0.service
Issue 3: Memory Issues
Symptoms: OSDs running out of memory

Solution:

# Reduce memory targets
sudo ceph config set osd osd_memory_target 2147483648  # 2GB
sudo ceph config set osd bluestore_cache_size 1073741824  # 1GB

# Monitor memory usage
free -h
sudo systemctl status ceph-osd@*.service
Issue 4: Network Bottlenecks
Symptoms: Network saturation during tests

Solution:

# Check network utilization
sudo iftop -i eth0

# Verify network settings
sudo sysctl net.core.rmem_max
sudo sysctl net.core.wmem_max

# Reduce concurrent operations if needed
sudo ceph config set osd osd_max_backfills 1
Conclusion
In this comprehensive lab, you have successfully:

Established baseline performance metrics for your Ceph cluster using industry-standard benchmarking tools
Optimized CRUSH maps to improve data distribution and reduce hotspots across OSDs
Configured pool settings for enhanced read and write performance
Tuned OSD parameters including BlueStore settings, memory allocation, and thread configurations
Optimized MON settings for better cluster coordination and reduced latency
Implemented network optimizations to maximize throughput and minimize network-related bottlenecks
Validated improvements through comprehensive performance testing and comparison
Why This Matters:

Performance optimization is crucial for production Ceph deployments because:

Cost Efficiency: Optimized clusters require fewer resources to achieve the same performance levels
User Experience: Better performance translates to faster application response times
Scalability: Well-tuned clusters can handle more concurrent operations and larger workloads
Resource Utilization: Proper optimization ensures balanced resource usage across the cluster
Operational Excellence: Understanding performance tuning helps in troubleshooting and capacity planning
Key Takeaways:

Always establish baseline metrics before making changes
Performance tuning is an iterative process requiring careful monitoring
Different workloads may require different optimization strategies
Network and storage hardware significantly impact optimization potential
Regular performance monitoring helps maintain optimal cluster performance
Next Steps:

Continue monitoring your optimized cluster in production
Implement automated performance monitoring and alerting
Consider advanced features like erasure coding for further optimization
Explore Ceph's built-in performance analysis tools
Plan for regular performance reviews and re-optimization as workloads evolve
This lab has provided you with practical, hands-on experience in Ceph performance optimization that directly applies to real-world storage infrastructure management and aligns with Red Hat Certified Specialist in Ceph Cloud Storage exam objectives.
