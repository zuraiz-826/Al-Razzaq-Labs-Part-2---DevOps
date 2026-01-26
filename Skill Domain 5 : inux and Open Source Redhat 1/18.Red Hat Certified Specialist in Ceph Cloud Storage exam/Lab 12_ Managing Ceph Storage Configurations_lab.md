Lab 12: Managing Ceph Storage Configurations
Objectives
By the end of this lab, students will be able to:

Understand and modify Ceph replication factors and pool configurations
Tune network settings to optimize Ceph cluster performance
Configure storage limits and quotas for Ceph pools
Apply configuration changes safely in a production-like environment
Monitor and validate configuration changes using Ceph management tools
Prerequisites
Before starting this lab, students should have:

Basic understanding of distributed storage systems
Familiarity with Linux command line operations
Knowledge of Ceph architecture and components (OSDs, MONs, MGRs)
Experience with basic Ceph administration commands
Understanding of RADOS pools and placement groups concepts
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph cluster already deployed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ceph Monitor nodes
6 Ceph OSD nodes with storage devices
2 Ceph Manager nodes
Pre-configured Ceph cluster with basic pools
Ceph management tools and utilities
Task 1: Adjust Replication Factors and Pool Configurations
Subtask 1.1: Examine Current Pool Configuration
First, let's examine the existing pools and their current configurations.

Connect to the Ceph cluster and check cluster status:
# Check overall cluster health
sudo ceph status

# List all existing pools
sudo ceph osd lspool
Examine detailed pool information:
# Get detailed information about all pools
sudo ceph osd pool ls detail

# Check specific pool configuration (replace 'rbd' with actual pool name)
sudo ceph osd pool get rbd all
View placement group information:
# Check placement groups status
sudo ceph pg stat

# List placement groups for a specific pool
sudo ceph pg ls-by-pool rbd
Subtask 1.2: Create a New Pool with Custom Configuration
Create a new pool with specific parameters:
# Create a new pool named 'lab-pool' with 128 placement groups
sudo ceph osd pool create lab-pool 128 128

# Set the pool application type
sudo ceph osd pool application enable lab-pool rbd
Configure replication factor:
# Set replication size to 3 (default is usually 3)
sudo ceph osd pool set lab-pool size 3

# Set minimum replication size to 2 (for availability during failures)
sudo ceph osd pool set lab-pool min_size 2

# Verify the settings
sudo ceph osd pool get lab-pool size
sudo ceph osd pool get lab-pool min_size
Subtask 1.3: Modify Existing Pool Configurations
Adjust placement group numbers (if needed):
# Check current PG count
sudo ceph osd pool get lab-pool pg_num
sudo ceph osd pool get lab-pool pgp_num

# Increase PG count if cluster has grown (be cautious with this operation)
sudo ceph osd pool set lab-pool pg_num 256
sudo ceph osd pool set lab-pool pgp_num 256
Configure pool-specific settings:
# Set pool quota (1TB limit)
sudo ceph osd pool set-quota lab-pool max_bytes 1099511627776

# Set maximum number of objects
sudo ceph osd pool set-quota lab-pool max_objects 1000000

# Verify quota settings
sudo ceph osd pool get-quota lab-pool
Subtask 1.4: Configure CRUSH Rules for Pool Placement
Examine existing CRUSH rules:
# List all CRUSH rules
sudo ceph osd crush rule ls

# View details of a specific rule
sudo ceph osd crush rule dump replicated_rule
Create a custom CRUSH rule for specific placement requirements:
# Create a new CRUSH rule for rack-level distribution
sudo ceph osd crush rule create-replicated rack-rule default rack

# Apply the new rule to our lab pool
sudo ceph osd pool set lab-pool crush_rule rack-rule

# Verify the rule assignment
sudo ceph osd pool get lab-pool crush_rule
Task 2: Tune Network Settings for Performance
Subtask 2.1: Configure Network Parameters
Check current network configuration:
# View current Ceph network settings
sudo ceph config dump | grep network

# Check cluster and public network settings
sudo ceph config get mon public_network
sudo ceph config get mon cluster_network
Optimize network timeouts and intervals:
# Set heartbeat interval (time between heartbeat messages)
sudo ceph config set osd osd_heartbeat_interval 10

# Set heartbeat grace period (time to wait before marking OSD down)
sudo ceph config set osd osd_heartbeat_grace 30

# Configure network timeout settings
sudo ceph config set osd ms_tcp_nodelay true
sudo ceph config set osd ms_tcp_rcvbuf 65536
Subtask 2.2: Configure Message Throttling
Set up message throttling for better performance:
# Configure OSD operation throttling
sudo ceph config set osd osd_op_queue wpq
sudo ceph config set osd osd_op_queue_cut_off high

# Set maximum concurrent operations
sudo ceph config set osd osd_max_backfills 2
sudo ceph config set osd osd_recovery_max_active 5
Configure client-side throttling:
# Set client read/write throttling
sudo ceph config set client client_oc_max_dirty 104857600
sudo ceph config set client client_oc_max_dirty_age 5.0
Subtask 2.3: Optimize Recovery and Backfill Settings
Configure recovery priorities:
# Set recovery operation priority
sudo ceph config set osd osd_recovery_op_priority 3
sudo ceph config set osd osd_recovery_max_chunk 8388608

# Configure backfill settings
sudo ceph config set osd osd_max_backfills 2
sudo ceph config set osd osd_backfill_scan_min 64
sudo ceph config set osd osd_backfill_scan_max 512
Set recovery sleep intervals:
# Add delays to reduce impact on client I/O
sudo ceph config set osd osd_recovery_sleep 0.1
sudo ceph config set osd osd_recovery_sleep_hdd 0.1
sudo ceph config set osd osd_recovery_sleep_ssd 0.0
Task 3: Adjust Storage Limits and Apply Configuration
Subtask 3.1: Configure OSD Storage Limits
Set OSD capacity thresholds:
# Set full ratio (when OSD stops accepting writes)
sudo ceph config set mon mon_osd_full_ratio 0.95

# Set near-full ratio (when warnings are issued)
sudo ceph config set mon mon_osd_nearfull_ratio 0.85

# Set backfill full ratio
sudo ceph config set mon mon_osd_backfillfull_ratio 0.90
Configure individual OSD limits:
# Check current OSD usage
sudo ceph osd df

# Set per-OSD weight adjustments if needed (example for OSD.0)
sudo ceph osd reweight 0 0.8

# View the updated weights
sudo ceph osd tree
Subtask 3.2: Implement Pool-Level Storage Quotas
Set comprehensive pool quotas:
# Set byte-based quota (2TB for lab-pool)
sudo ceph osd pool set-quota lab-pool max_bytes 2199023255552

# Set object count quota
sudo ceph osd pool set-quota lab-pool max_objects 2000000

# Create a test pool with smaller quotas for demonstration
sudo ceph osd pool create test-quota-pool 32 32
sudo ceph osd pool application enable test-quota-pool rbd
sudo ceph osd pool set-quota test-quota-pool max_bytes 10737418240  # 10GB
sudo ceph osd pool set-quota test-quota-pool max_objects 100000
Verify quota enforcement:
# Check quota status
sudo ceph osd pool get-quota lab-pool
sudo ceph osd pool get-quota test-quota-pool

# Monitor pool usage
sudo ceph df detail
Subtask 3.3: Apply and Validate Configuration Changes
Create a configuration validation script:
# Create a script to validate all our changes
cat > validate_config.sh << 'EOF'
#!/bin/bash

echo "=== Ceph Configuration Validation ==="
echo

echo "1. Cluster Health:"
sudo ceph health detail
echo

echo "2. Pool Configurations:"
for pool in $(sudo ceph osd lspool | awk '{print $2}'); do
    echo "Pool: $pool"
    sudo ceph osd pool get $pool size
    sudo ceph osd pool get $pool min_size
    sudo ceph osd pool get-quota $pool
    echo
done

echo "3. Network Settings:"
sudo ceph config dump | grep -E "(heartbeat|network|tcp)"
echo

echo "4. Storage Thresholds:"
sudo ceph config dump | grep -E "(full_ratio|nearfull_ratio)"
echo

echo "5. OSD Status:"
sudo ceph osd stat
sudo ceph osd df
EOF

chmod +x validate_config.sh
Run the validation script:
# Execute the validation
./validate_config.sh
Test configuration with sample data:
# Create a test RBD image in our configured pool
sudo rbd create --size 1024 lab-pool/test-image

# Map the image and create a filesystem
sudo rbd map lab-pool/test-image
sudo mkfs.ext4 /dev/rbd0

# Mount and test write operations
sudo mkdir -p /mnt/ceph-test
sudo mount /dev/rbd0 /mnt/ceph-test

# Write test data
sudo dd if=/dev/zero of=/mnt/ceph-test/testfile bs=1M count=100

# Check pool usage after write
sudo ceph df detail
Subtask 3.4: Monitor and Fine-tune Performance
Set up performance monitoring:
# Enable detailed performance counters
sudo ceph config set mgr mgr/prometheus/server_addr 0.0.0.0
sudo ceph config set mgr mgr/prometheus/server_port 9283

# Check performance statistics
sudo ceph osd perf
sudo ceph osd pool stats
Create a performance monitoring script:
cat > monitor_performance.sh << 'EOF'
#!/bin/bash

echo "=== Ceph Performance Monitoring ==="
echo "Timestamp: $(date)"
echo

echo "Cluster Performance:"
sudo ceph status
echo

echo "Pool Statistics:"
sudo ceph osd pool stats
echo

echo "OSD Performance:"
sudo ceph osd perf
echo

echo "Placement Group Status:"
sudo ceph pg stat
EOF

chmod +x monitor_performance.sh
Clean up test resources:
# Unmount and clean up test resources
sudo umount /mnt/ceph-test
sudo rbd unmap /dev/rbd0
sudo rbd rm lab-pool/test-image

# Remove test quota pool if desired
# sudo ceph osd pool delete test-quota-pool test-quota-pool --yes-i-really-really-mean-it
Troubleshooting Common Issues
Issue 1: Pool Creation Fails
Problem: Pool creation fails with placement group errors.

Solution:

# Check if the PG count is appropriate for your cluster size
# Rule of thumb: ~100-200 PGs per OSD
sudo ceph osd stat
# Calculate: (Target PGs per OSD * Number of OSDs) / Pool replication size
Issue 2: Configuration Changes Not Taking Effect
Problem: Configuration changes don't seem to apply.

Solution:

# Restart the affected services
sudo systemctl restart ceph-osd@*
sudo systemctl restart ceph-mon@*

# Or restart specific services
sudo systemctl restart ceph-osd@0
Issue 3: High Recovery Impact on Performance
Problem: Recovery operations are impacting client performance.

Solution:

# Reduce recovery priority and add sleep
sudo ceph config set osd osd_recovery_op_priority 1
sudo ceph config set osd osd_recovery_sleep 0.5
sudo ceph config set osd osd_max_backfills 1
Conclusion
In this lab, you have successfully:

Modified Ceph pool configurations including replication factors, placement groups, and CRUSH rules to optimize data distribution and availability
Tuned network settings for improved performance by configuring heartbeat intervals, message throttling, and recovery parameters
Implemented storage limits and quotas at both the cluster and pool levels to manage capacity and prevent storage exhaustion
Applied and validated configuration changes using systematic testing and monitoring approaches
These skills are essential for managing production Ceph clusters effectively. Proper configuration management ensures optimal performance, data safety, and resource utilization in distributed storage environments. The techniques learned here directly apply to real-world scenarios where storage administrators must balance performance, availability, and capacity constraints.

Key Takeaways:

Always validate configuration changes in a test environment first
Monitor cluster health and performance after making changes
Use quotas and limits to prevent resource exhaustion
Network tuning can significantly impact cluster performance
Regular monitoring and adjustment are crucial for optimal Ceph operations
This knowledge prepares you for advanced Ceph administration tasks and contributes toward achieving the Red Hat Certified Specialist in Ceph Cloud Storage certification.
