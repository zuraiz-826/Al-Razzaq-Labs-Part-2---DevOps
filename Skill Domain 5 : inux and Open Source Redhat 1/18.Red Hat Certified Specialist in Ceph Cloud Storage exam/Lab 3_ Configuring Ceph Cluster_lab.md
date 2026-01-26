Lab 3: Configuring Ceph Cluster
Objectives
By the end of this lab, you will be able to:

Understand the structure and components of the Ceph configuration file (ceph.conf)
Configure Monitor (MON) services with appropriate settings
Configure Object Storage Daemon (OSD) services for optimal performance
Configure Manager (MGR) services with required modules
Implement Ceph authentication mechanisms using cephx
Configure network settings for cluster and public networks
Apply configuration changes and verify cluster health
Troubleshoot common configuration issues in Ceph clusters
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with text editors (nano, vim, or similar)
Knowledge of networking concepts (IP addresses, subnets)
Understanding of storage concepts (disks, partitions, filesystems)
Completion of previous Ceph installation labs
Basic knowledge of YAML/INI configuration file formats
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or install software.

Your lab environment includes:

3 CentOS/RHEL 8 nodes pre-configured with Ceph
Node1: ceph-admin (10.0.1.10)
Node2: ceph-node1 (10.0.1.11)
Node3: ceph-node2 (10.0.1.12)
All necessary Ceph packages pre-installed
SSH access configured between nodes
Task 1: Understanding and Modifying ceph.conf for Core Services
Subtask 1.1: Examine the Current Ceph Configuration
First, let's understand the current configuration structure and locate the main configuration file.

Connect to the admin node:
ssh root@ceph-admin
Navigate to the Ceph configuration directory:
cd /etc/ceph
ls -la
Examine the current ceph.conf file:
cat ceph.conf
Create a backup of the original configuration:
cp ceph.conf ceph.conf.backup.$(date +%Y%m%d)
Subtask 1.2: Configure Monitor (MON) Services
Monitors maintain the cluster map and are critical for cluster operations.

Open the ceph.conf file for editing:
nano /etc/ceph/ceph.conf
Add or modify the MON configuration section:
[global]
fsid = YOUR_CLUSTER_FSID
mon_initial_members = ceph-admin, ceph-node1, ceph-node2
mon_host = 10.0.1.10, 10.0.1.11, 10.0.1.12
public_network = 10.0.1.0/24
cluster_network = 10.0.1.0/24
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx

[mon]
mon_allow_pool_delete = false
mon_max_pg_per_osd = 300
mon_pg_warn_max_per_osd = 400
mon_osd_full_ratio = 0.85
mon_osd_backfillfull_ratio = 0.80
mon_osd_nearfull_ratio = 0.75
mon_clock_drift_allowed = 0.5
mon_clock_drift_warn_backoff = 30

[mon.ceph-admin]
host = ceph-admin
mon_addr = 10.0.1.10:6789

[mon.ceph-node1]
host = ceph-node1
mon_addr = 10.0.1.11:6789

[mon.ceph-node2]
host = ceph-node2
mon_addr = 10.0.1.12:6789
Verify the MON configuration syntax:
ceph-conf --show-config-value mon_host
Subtask 1.3: Configure Object Storage Daemon (OSD) Services
OSDs store the actual data and handle data replication, recovery, and rebalancing.

Add OSD configuration to ceph.conf:
[osd]
osd_journal_size = 5120
osd_pool_default_size = 3
osd_pool_default_min_size = 2
osd_pool_default_pg_num = 128
osd_pool_default_pgp_num = 128
osd_crush_chooseleaf_type = 1
osd_recovery_max_active = 3
osd_max_backfills = 1
osd_recovery_op_priority = 1
osd_client_op_priority = 63
osd_recovery_max_chunk = 8388608
osd_op_threads = 8
osd_disk_threads = 1
osd_map_cache_size = 1024
osd_map_cache_bl_size = 128
osd_mount_options_xfs = "rw,noexec,nodev,noatime,nodiratime,nobarrier"
osd_mkfs_options_xfs = "-f -i size=2048"
osd_mkfs_type = xfs
Add specific OSD node configurations:
[osd.0]
host = ceph-node1
osd_data = /var/lib/ceph/osd/ceph-0
osd_journal = /var/lib/ceph/osd/ceph-0/journal

[osd.1]
host = ceph-node2
osd_data = /var/lib/ceph/osd/ceph-1
osd_journal = /var/lib/ceph/osd/ceph-1/journal
Subtask 1.4: Configure Manager (MGR) Services
The Ceph Manager daemon runs alongside monitor daemons to provide additional monitoring and interfaces.

Add MGR configuration to ceph.conf:
[mgr]
mgr_modules = dashboard restful status prometheus
mgr_initial_modules = dashboard restful
mgr_stats_period = 5
mgr_client_service_daemon_unregister_timeout = 60
mgr_service_beacon_grace = 60

[mgr.ceph-admin]
host = ceph-admin

[mgr.ceph-node1]
host = ceph-node1
Save and close the configuration file (Ctrl+X, then Y, then Enter in nano).
Task 2: Setting Up Authentication and Network Configuration
Subtask 2.1: Configure Ceph Authentication (CephX)
CephX is Ceph's authentication protocol that provides mutual authentication between clients and servers.

Verify authentication settings in the global section:
grep -A 10 "\[global\]" /etc/ceph/ceph.conf | grep auth
Generate authentication keys if not present:
ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
Create admin keyring:
ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
Create bootstrap keyrings for OSDs:
ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd'
Subtask 2.2: Configure Network Settings
Proper network configuration is crucial for Ceph cluster performance and security.

Verify current network configuration:
ip addr show
Update network settings in ceph.conf (if not already configured):
[global]
# Public network - client communication
public_network = 10.0.1.0/24
public_addr = 10.0.1.10

# Cluster network - internal replication traffic
cluster_network = 10.0.1.0/24

# Network interface binding
ms_bind_ipv4 = true
ms_bind_ipv6 = false
ms_bind_port_min = 6800
ms_bind_port_max = 7300
Configure firewall rules for Ceph services:
# Open ports for MON services
firewall-cmd --zone=public --add-port=6789/tcp --permanent

# Open ports for OSD services
firewall-cmd --zone=public --add-port=6800-7300/tcp --permanent

# Open ports for MGR dashboard
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=8443/tcp --permanent

# Reload firewall
firewall-cmd --reload
Verify firewall configuration:
firewall-cmd --list-all
Subtask 2.3: Configure Advanced Network Options
Add network performance tuning options:
[global]
# Network message settings
ms_crc_data = false
ms_crc_header = false
ms_die_on_bad_msg = false
ms_dispatch_throttle_bytes = 1048576000
ms_rwthread_stack_bytes = 1048576
ms_tcp_nodelay = true
ms_tcp_rcvbuf = 65536
Configure network encryption (optional):
[global]
ms_cluster_mode = secure
ms_service_mode = secure
ms_client_mode = secure
Task 3: Applying Configurations and Checking Cluster Status
Subtask 3.1: Distribute Configuration to All Nodes
Copy the updated configuration to all cluster nodes:
scp /etc/ceph/ceph.conf root@ceph-node1:/etc/ceph/
scp /etc/ceph/ceph.conf root@ceph-node2:/etc/ceph/
Copy authentication keyrings to all nodes:
scp /etc/ceph/ceph.client.admin.keyring root@ceph-node1:/etc/ceph/
scp /etc/ceph/ceph.client.admin.keyring root@ceph-node2:/etc/ceph/
Set proper permissions on configuration files:
chmod 644 /etc/ceph/ceph.conf
chmod 600 /etc/ceph/ceph.client.admin.keyring

# Repeat on other nodes
ssh root@ceph-node1 "chmod 644 /etc/ceph/ceph.conf && chmod 600 /etc/ceph/ceph.client.admin.keyring"
ssh root@ceph-node2 "chmod 644 /etc/ceph/ceph.conf && chmod 600 /etc/ceph/ceph.client.admin.keyring"
Subtask 3.2: Restart Ceph Services
Restart MON services on all nodes:
systemctl restart ceph-mon@ceph-admin
ssh root@ceph-node1 "systemctl restart ceph-mon@ceph-node1"
ssh root@ceph-node2 "systemctl restart ceph-mon@ceph-node2"
Restart MGR services:
systemctl restart ceph-mgr@ceph-admin
ssh root@ceph-node1 "systemctl restart ceph-mgr@ceph-node1"
Restart OSD services:
ssh root@ceph-node1 "systemctl restart ceph-osd@0"
ssh root@ceph-node2 "systemctl restart ceph-osd@1"
Verify all services are running:
systemctl status ceph-mon@ceph-admin
systemctl status ceph-mgr@ceph-admin
ssh root@ceph-node1 "systemctl status ceph-osd@0"
ssh root@ceph-node2 "systemctl status ceph-osd@1"
Subtask 3.3: Verify Configuration Changes
Check cluster status:
ceph status
Verify MON configuration:
ceph mon dump
Check OSD configuration:
ceph osd dump
Verify MGR status:
ceph mgr dump
Check authentication status:
ceph auth list
Verify network connectivity:
ceph health detail
Subtask 3.4: Test Configuration with Basic Operations
Create a test pool to verify functionality:
ceph osd pool create test_pool 64 64
Put a test object:
echo "Hello Ceph Configuration" | rados put test-object -p test_pool
Retrieve the test object:
rados get test-object -p test_pool -
List objects in the pool:
rados ls -p test_pool
Clean up test resources:
rados rm test-object -p test_pool
ceph osd pool delete test_pool test_pool --yes-i-really-really-mean-it
Troubleshooting Common Issues
Issue 1: MON Services Not Starting
Symptoms: MON services fail to start or cluster shows MON down

Solutions:

# Check MON logs
journalctl -u ceph-mon@$(hostname) -f

# Verify MON data directory permissions
ls -la /var/lib/ceph/mon/

# Check network connectivity
telnet 10.0.1.11 6789
Issue 2: Authentication Failures
Symptoms: "authentication failed" errors in logs

Solutions:

# Verify keyring permissions
ls -la /etc/ceph/ceph.client.admin.keyring

# Check authentication configuration
ceph-conf --show-config-value auth_cluster_required

# Regenerate keyrings if corrupted
ceph auth get-or-create client.admin mon 'allow *' osd 'allow *' mds 'allow *' mgr 'allow *'
Issue 3: Network Configuration Problems
Symptoms: OSDs can't communicate, slow performance

Solutions:

# Test network connectivity
ping -c 3 10.0.1.11

# Check firewall rules
iptables -L -n

# Verify network interface configuration
ip route show
Advanced Configuration Options
Performance Tuning
Add performance-oriented settings:
[osd]
# Increase concurrent operations
osd_op_threads = 16
osd_disk_threads = 4

# Optimize recovery
osd_recovery_max_active = 5
osd_max_backfills = 2

# Memory optimization
osd_memory_target = 4294967296
High Availability Configuration
Configure for production resilience:
[global]
# Increase MON tolerance
mon_lease = 5
mon_lease_renew_interval_factor = 0.6
mon_lease_ack_timeout_factor = 2.0

# OSD heartbeat settings
osd_heartbeat_interval = 6
osd_heartbeat_grace = 20
Verification Commands Summary
Use these commands to verify your configuration:

# Overall cluster health
ceph health detail

# Configuration verification
ceph-conf --show-config

# Service status
ceph mon stat
ceph osd stat
ceph mgr stat

# Network and authentication
ceph auth list
ceph mon dump
Conclusion
In this lab, you have successfully:

Configured core Ceph services: You learned how to properly configure MON, OSD, and MGR services through the ceph.conf file, understanding the role each service plays in the cluster ecosystem.

Implemented security measures: You set up CephX authentication to secure cluster communications and prevent unauthorized access to your storage cluster.

Optimized network settings: You configured both public and cluster networks, implemented firewall rules, and tuned network parameters for optimal performance.

Applied and verified changes: You learned the proper procedure for distributing configuration changes across the cluster and verifying that services are running correctly.

Gained troubleshooting skills: You now understand how to diagnose common configuration issues and have the tools to resolve them effectively.

This configuration knowledge is fundamental for managing production Ceph clusters and is essential for the Red Hat Certified Specialist in Ceph Cloud Storage exam. The skills you've developed here form the foundation for more advanced Ceph administration tasks, including performance tuning, scaling operations, and disaster recovery planning.

Understanding Ceph configuration is crucial because it directly impacts cluster performance, reliability, and security. A well-configured Ceph cluster can provide enterprise-grade storage solutions that scale from terabytes to exabytes while maintaining high availability and data integrity.
