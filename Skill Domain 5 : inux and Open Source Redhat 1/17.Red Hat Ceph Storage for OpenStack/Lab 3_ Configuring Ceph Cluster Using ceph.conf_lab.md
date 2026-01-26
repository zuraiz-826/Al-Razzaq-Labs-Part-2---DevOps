Lab 3: Configuring Ceph Cluster Using ceph.conf
Objectives
By the end of this lab, students will be able to:

Understand the structure and purpose of the ceph.conf configuration file
Configure Monitor (MON) daemons using ceph.conf parameters
Configure Object Storage Daemon (OSD) settings for optimal performance
Configure Manager (MGR) daemon parameters
Set appropriate data replication policies and pool configurations
Configure recovery thresholds to optimize cluster performance
Implement cluster health monitoring parameters
Apply configuration changes and verify cluster functionality
Troubleshoot common configuration issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph architecture and components
Familiarity with Linux command line operations
Knowledge of text editors (nano, vim, or similar)
Understanding of YAML/INI configuration file formats
Completion of previous Ceph installation labs
Basic networking concepts knowledge
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph already installed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ubuntu 22.04 LTS nodes (ceph-node1, ceph-node2, ceph-node3)
Ceph Quincy (v17.x) pre-installed
All necessary dependencies configured
Network connectivity between nodes established
Task 1: Understanding and Preparing the ceph.conf File
Subtask 1.1: Locate and Examine the Current Configuration
First, let's understand the current Ceph configuration structure.

Connect to your primary Ceph node:
ssh ceph-admin@ceph-node1
Locate the ceph.conf file:
sudo find /etc -name "ceph.conf" -type f
ls -la /etc/ceph/
Create a backup of the existing configuration:
sudo cp /etc/ceph/ceph.conf /etc/ceph/ceph.conf.backup.$(date +%Y%m%d)
Examine the current configuration:
sudo cat /etc/ceph/ceph.conf
Subtask 1.2: Understanding Configuration File Structure
The ceph.conf file follows an INI-style format with sections:

[global]: Settings that apply to all daemons
[mon]: Settings specific to Monitor daemons
[osd]: Settings specific to OSD daemons
[mgr]: Settings specific to Manager daemons
[client]: Settings for Ceph clients
Task 2: Configuring Monitor (MON) Daemons
Subtask 2.1: Configure Global MON Settings
Open the ceph.conf file for editing:
sudo nano /etc/ceph/ceph.conf
Add or modify the global section with MON-related parameters:
[global]
# Cluster identification
fsid = 12345678-1234-1234-1234-123456789012
mon_initial_members = ceph-node1, ceph-node2, ceph-node3
mon_host = 192.168.1.10, 192.168.1.11, 192.168.1.12

# Authentication settings
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx

# Network settings
public_network = 192.168.1.0/24
cluster_network = 192.168.2.0/24

# Logging
log_file = /var/log/ceph/$cluster-$name.log
log_to_syslog = true
log_to_syslog_level = info
Subtask 2.2: Configure Specific MON Settings
Add the [mon] section with Monitor-specific configurations:
[mon]
# Monitor data directory
mon_data = /var/lib/ceph/mon/$cluster-$id

# Clock drift tolerance
mon_clock_drift_allowed = 0.05
mon_clock_drift_warn_backoff = 30

# Monitor election settings
mon_election_timeout = 5
mon_lease = 5
mon_lease_renew_interval_factor = 0.6

# Monitor storage settings
mon_compact_on_start = true
mon_compact_on_trim = true

# Health and warning settings
mon_health_preluminous_compat_warning = false
mon_warn_on_legacy_crush_tunables = false
mon_warn_on_crush_straw_calc_version_zero = false
Subtask 2.3: Configure Individual Monitor Nodes
Add specific configurations for each monitor:
[mon.ceph-node1]
host = ceph-node1
mon_addr = 192.168.1.10:6789

[mon.ceph-node2]
host = ceph-node2
mon_addr = 192.168.1.11:6789

[mon.ceph-node3]
host = ceph-node3
mon_addr = 192.168.1.12:6789
Task 3: Configuring Object Storage Daemons (OSDs)
Subtask 3.1: Configure Global OSD Settings
Add the [osd] section with performance and reliability settings:
[osd]
# OSD data and journal paths
osd_data = /var/lib/ceph/osd/$cluster-$id
osd_journal_size = 5120

# Performance settings
osd_op_threads = 8
osd_disk_threads = 4
osd_recovery_threads = 2

# Memory settings
osd_memory_target = 4294967296
bluestore_cache_size = 1073741824

# Heartbeat settings
osd_heartbeat_interval = 6
osd_heartbeat_grace = 20

# Recovery and backfill settings
osd_recovery_max_active = 3
osd_recovery_max_single_start = 1
osd_max_backfills = 1
osd_recovery_op_priority = 3

# Scrubbing settings
osd_scrub_begin_hour = 22
osd_scrub_end_hour = 6
osd_scrub_during_recovery = false
osd_scrub_load_threshold = 0.5
Subtask 3.2: Configure BlueStore Settings
Add BlueStore-specific configurations:
# BlueStore settings (continued in [osd] section)
bluestore_block_size = 10737418240
bluestore_block_db_size = 67108864
bluestore_block_wal_size = 134217728
bluestore_cache_meta_ratio = 0.4
bluestore_cache_kv_ratio = 0.4
bluestore_compression_algorithm = lz4
bluestore_compression_mode = aggressive
Subtask 3.3: Configure OSD Placement and Distribution
Add placement and CRUSH map settings:
# CRUSH and placement settings (in [osd] section)
osd_crush_chooseleaf_type = 1
osd_pool_default_crush_rule = 0
osd_crush_update_on_start = true

# PG settings
osd_pool_default_pg_num = 128
osd_pool_default_pgp_num = 128
osd_pool_default_size = 3
osd_pool_default_min_size = 2
Task 4: Configuring Manager (MGR) Daemons
Subtask 4.1: Configure MGR Settings
Add the [mgr] section for Manager daemon configuration:
[mgr]
# Manager data directory
mgr_data = /var/lib/ceph/mgr/$cluster-$id

# Module settings
mgr_initial_modules = dashboard, restful, prometheus, alerts

# Dashboard settings
mgr_dashboard_ssl = true
mgr_dashboard_port = 8443
mgr_dashboard_ssl_cert = /etc/ceph/ceph-mgr.crt
mgr_dashboard_ssl_key = /etc/ceph/ceph-mgr.key

# Prometheus settings
mgr_prometheus_port = 9283

# Standby settings
mgr_standby_modules = true
Subtask 4.2: Configure Individual Manager Nodes
Add specific MGR node configurations:
[mgr.ceph-node1]
host = ceph-node1

[mgr.ceph-node2]
host = ceph-node2

[mgr.ceph-node3]
host = ceph-node3
Task 5: Setting Data Replication Parameters
Subtask 5.1: Configure Pool Replication Settings
Add replication settings to the global section:
# Add to [global] section
# Default pool settings
osd_pool_default_size = 3
osd_pool_default_min_size = 2
osd_pool_default_pg_num = 128
osd_pool_default_pgp_num = 128

# Replication and erasure coding
osd_pool_default_crush_rule = 0
osd_pool_default_type = replicated

# Pool creation settings
mon_allow_pool_delete = false
mon_max_pool_pg_num = 65536
Subtask 5.2: Configure Advanced Replication Parameters
Add advanced replication settings:
# Add to [osd] section
# Replication and consistency
osd_pool_default_flag_hashpspool = true
osd_pool_default_flag_nodelete = false
osd_pool_default_flag_nopgchange = false
osd_pool_default_flag_nosizechange = false

# Write acknowledgment settings
osd_pool_default_write_fadvise_dontneed = false
osd_client_message_size_cap = 524288000
osd_client_message_cap = 256
Task 6: Configuring Recovery Thresholds
Subtask 6.1: Set Recovery Performance Parameters
Configure recovery thresholds in the [osd] section:
# Recovery performance settings (add to [osd] section)
osd_recovery_delay_start = 0
osd_recovery_max_active = 3
osd_recovery_max_single_start = 1
osd_recovery_max_chunk = 8388608
osd_recovery_threads = 1

# Backfill settings
osd_max_backfills = 1
osd_backfill_scan_min = 64
osd_backfill_scan_max = 512
osd_backfill_full_ratio = 0.95
osd_backfill_retry_interval = 30.0

# Recovery priority and throttling
osd_recovery_op_priority = 3
osd_recovery_op_warn_multiple = 16
osd_recovery_sleep = 0
osd_recovery_sleep_hdd = 0.1
osd_recovery_sleep_ssd = 0
osd_recovery_sleep_hybrid = 0.025
Subtask 6.2: Configure Cluster Load Balancing
Add load balancing and threshold settings:
# Load balancing settings (add to [osd] section)
osd_backfill_full_ratio = 0.95
osd_backfill_nearfull_ratio = 0.90
osd_failsafe_full_ratio = 0.97

# Recovery and rebalancing thresholds
osd_recovery_priority = 5
osd_client_op_priority = 63
osd_snap_trim_priority = 5
osd_snap_trim_sleep = 0.1

# PG splitting and merging
osd_pg_max_concurrent_snap_trims = 2
osd_snap_trim_thread_timeout = 1800
Task 7: Implementing Cluster Health Monitoring
Subtask 7.1: Configure Health Check Parameters
Add health monitoring settings to the [mon] section:
# Health monitoring settings (add to [mon] section)
mon_health_check_interval = 300
mon_health_warn_on_flag_noout = true
mon_health_warn_on_flag_nodown = true
mon_health_warn_on_flag_noin = true
mon_health_warn_on_flag_nobackfill = true
mon_health_warn_on_flag_norecover = true
mon_health_warn_on_flag_noscrub = true
mon_health_warn_on_flag_nodeep_scrub = true

# OSD health monitoring
mon_osd_down_out_interval = 600
mon_osd_down_out_subtree_limit = rack
mon_osd_min_down_reporters = 2
mon_osd_reporter_subtree_level = host
Subtask 7.2: Configure Alerting and Notification Settings
Add alerting configurations:
# Add to [global] section
# Logging and alerting
log_to_cluster = true
err_to_cluster = true
clog_to_monitors = true
clog_to_syslog = true
clog_to_syslog_facility = daemon
clog_to_syslog_level = info

# Health warnings
mon_health_to_clog = true
mon_health_to_clog_interval = 3600
mon_health_to_clog_tick_interval = 60
Task 8: Applying Configuration Changes
Subtask 8.1: Validate Configuration Syntax
Check the configuration file syntax:
sudo ceph-conf --show-config-value fsid
sudo ceph-conf --show-config-value mon_host
Validate the complete configuration:
sudo ceph-conf -c /etc/ceph/ceph.conf --show-config | head -20
Subtask 8.2: Distribute Configuration to All Nodes
Copy the configuration to other nodes:
# Copy to node2
sudo scp /etc/ceph/ceph.conf ceph-admin@ceph-node2:/tmp/
ssh ceph-admin@ceph-node2 "sudo mv /tmp/ceph.conf /etc/ceph/"

# Copy to node3
sudo scp /etc/ceph/ceph.conf ceph-admin@ceph-node3:/tmp/
ssh ceph-admin@ceph-node3 "sudo mv /tmp/ceph.conf /etc/ceph/"
Set proper permissions on all nodes:
# On each node
for node in ceph-node1 ceph-node2 ceph-node3; do
    ssh ceph-admin@$node "sudo chown ceph:ceph /etc/ceph/ceph.conf"
    ssh ceph-admin@$node "sudo chmod 644 /etc/ceph/ceph.conf"
done
Subtask 8.3: Restart Ceph Services
Restart services in the correct order:
# Restart monitors first
sudo systemctl restart ceph-mon@ceph-node1
ssh ceph-admin@ceph-node2 "sudo systemctl restart ceph-mon@ceph-node2"
ssh ceph-admin@ceph-node3 "sudo systemctl restart ceph-mon@ceph-node3"

# Wait for monitors to stabilize
sleep 30

# Restart managers
sudo systemctl restart ceph-mgr@ceph-node1
ssh ceph-admin@ceph-node2 "sudo systemctl restart ceph-mgr@ceph-node2"

# Restart OSDs (one at a time to maintain availability)
for osd_id in $(ceph osd ls); do
    echo "Restarting OSD $osd_id"
    sudo systemctl restart ceph-osd@$osd_id
    sleep 60
    ceph health
done
Task 9: Verifying Configuration and Cluster Health
Subtask 9.1: Check Cluster Status
Verify cluster health:
ceph health detail
ceph status
ceph osd tree
ceph mon stat
ceph mgr stat
Check configuration application:
ceph config dump | grep -E "(osd_recovery|mon_health|mgr_dashboard)"
ceph config show mon.ceph-node1 | head -10
ceph config show osd.0 | head -10
Subtask 9.2: Test Configuration Parameters
Verify replication settings:
ceph osd pool ls detail
ceph osd pool get rbd size
ceph osd pool get rbd min_size
ceph osd pool get rbd pg_num
Check recovery and health monitoring:
ceph config show osd.0 osd_recovery_max_active
ceph config show mon.ceph-node1 mon_health_check_interval
ceph config show mgr.ceph-node1 mgr_dashboard_port
Subtask 9.3: Create Test Pool to Validate Settings
Create a test pool with custom settings:
ceph osd pool create test-pool 32 32 replicated
ceph osd pool set test-pool size 3
ceph osd pool set test-pool min_size 2
Test the pool functionality:
echo "Test data for Ceph configuration lab" | rados -p test-pool put test-object -
rados -p test-pool get test-object -
rados -p test-pool ls
Clean up test resources:
rados -p test-pool rm test-object
ceph osd pool delete test-pool test-pool --yes-i-really-really-mean-it
Troubleshooting Common Issues
Configuration File Issues
Problem: Configuration syntax errors

# Solution: Validate syntax
sudo ceph-conf -c /etc/ceph/ceph.conf --show-config > /dev/null
Problem: Services not picking up new configuration

# Solution: Force configuration reload
sudo ceph config assimilate-conf -i /etc/ceph/ceph.conf
Service Restart Issues
Problem: Monitor won't start after configuration change

# Check monitor logs
sudo journalctl -u ceph-mon@$(hostname) -f

# Verify monitor data directory permissions
sudo ls -la /var/lib/ceph/mon/
Problem: OSD performance issues after configuration

# Check OSD performance settings
ceph config show osd.0 | grep -E "(recovery|backfill|threads)"

# Monitor cluster performance
ceph osd perf
Network Configuration Issues
Problem: Monitors can't communicate

# Test network connectivity
ping -c 3 192.168.1.11
telnet 192.168.1.11 6789

# Check firewall settings
sudo ufw status
sudo iptables -L
Conclusion
In this comprehensive lab, you have successfully:

Mastered Ceph Configuration Management: You learned how to structure and modify the ceph.conf file to control all aspects of your Ceph cluster, from basic connectivity to advanced performance tuning.

Configured Critical Cluster Components: You set up Monitor (MON) daemons for cluster coordination, Object Storage Daemons (OSDs) for data storage, and Manager (MGR) daemons for cluster management and monitoring.

Implemented Data Protection Strategies: You configured replication parameters to ensure data durability and availability, setting appropriate replica counts and minimum size requirements for different use cases.

Optimized Cluster Performance: You configured recovery thresholds and performance parameters that balance data recovery speed with cluster performance, ensuring your cluster can handle failures gracefully while maintaining service availability.

Established Health Monitoring: You implemented comprehensive health monitoring and alerting systems that will help you proactively manage your Ceph cluster and respond to issues before they impact users.

Why This Matters:

The skills you've developed in this lab are essential for production Ceph deployments. Proper configuration management ensures your storage cluster operates efficiently, recovers quickly from failures, and scales effectively as your storage needs grow. These configuration techniques are fundamental to achieving the reliability and performance expected in enterprise storage environments.

Next Steps:

With this solid foundation in Ceph configuration, you're prepared to tackle more advanced topics such as performance tuning for specific workloads, implementing erasure coding for space efficiency, and integrating Ceph with container orchestration platforms like OpenStack and Kubernetes.

The configuration skills you've learned here will serve as the foundation for managing large-scale, production Ceph clusters that power modern cloud infrastructure and software-defined storage solutions.
