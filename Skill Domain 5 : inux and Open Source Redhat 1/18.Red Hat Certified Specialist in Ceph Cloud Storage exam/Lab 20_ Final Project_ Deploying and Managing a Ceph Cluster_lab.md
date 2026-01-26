Lab 20: Final Project: Deploying and Managing a Ceph Cluster
Objectives
By the end of this lab, students will be able to:

Deploy a complete Ceph cluster with all storage types (RBD, RGW, and CephFS)
Configure replication policies and failover mechanisms
Implement performance tuning for optimal cluster operation
Set up comprehensive monitoring and alerting systems
Troubleshoot common Ceph cluster issues
Demonstrate mastery of Ceph administration skills required for Red Hat Certified Specialist in Ceph Cloud Storage exam
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with storage concepts (block, object, and file storage)
Knowledge of networking fundamentals
Experience with command-line interfaces
Completion of previous Ceph-related labs or equivalent knowledge
Understanding of YAML configuration files
Lab Environment
Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own VMs.

Environment Details:

5 CentOS Stream 9 machines (1 admin node + 4 storage nodes)
Each machine has 4 vCPUs, 8GB RAM, and multiple storage devices
Pre-installed packages: podman, python3, chrony
Network connectivity between all nodes
Task 1: Deploy a Complete Ceph Cluster
Subtask 1.1: Prepare the Environment
Step 1: Access your lab environment and verify all nodes are accessible.

# On admin node, verify connectivity to all nodes
for i in {1..4}; do
    ping -c 2 ceph-node-$i
done
Step 2: Configure time synchronization on all nodes.

# Run on all nodes
sudo systemctl enable --now chronyd
sudo chrony sources -v
Step 3: Install cephadm on the admin node.

# Download and install cephadm
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
chmod +x cephadm
sudo ./cephadm add-repo --release quincy
sudo ./cephadm install
Subtask 1.2: Bootstrap the Ceph Cluster
Step 1: Initialize the Ceph cluster.

# Bootstrap the cluster on admin node
sudo cephadm bootstrap --mon-ip 192.168.1.10 --cluster-network 192.168.1.0/24
Step 2: Save the admin credentials displayed after bootstrap completion.

# The bootstrap process will display:
# - Dashboard URL
# - Admin username and password
# - SSH key information
Step 3: Install Ceph CLI tools.

sudo cephadm install ceph-common
Subtask 1.3: Add Storage Nodes to the Cluster
Step 1: Copy SSH keys to all storage nodes.

# Copy public key to each node
for i in {1..4}; do
    ssh-copy-id root@ceph-node-$i
done
Step 2: Add nodes to the cluster.

# Add each storage node
sudo ceph orch host add ceph-node-1 192.168.1.11
sudo ceph orch host add ceph-node-2 192.168.1.12
sudo ceph orch host add ceph-node-3 192.168.1.13
sudo ceph orch host add ceph-node-4 192.168.1.14
Step 3: Verify cluster status.

sudo ceph status
sudo ceph orch host ls
Subtask 1.4: Deploy Monitor and Manager Services
Step 1: Deploy additional monitors for high availability.

# Deploy monitors on 3 nodes total
sudo ceph orch apply mon --placement="3 ceph-node-1 ceph-node-2 ceph-node-3"
Step 2: Deploy manager services.

# Deploy managers on 2 nodes
sudo ceph orch apply mgr --placement="2 ceph-node-1 ceph-node-2"
Step 3: Verify service deployment.

sudo ceph orch ls
sudo ceph -s
Subtask 1.5: Configure OSDs (Object Storage Daemons)
Step 1: List available storage devices.

sudo ceph orch device ls
Step 2: Deploy OSDs on available devices.

# Deploy OSDs on all available devices
sudo ceph orch apply osd --all-available-devices
Step 3: Verify OSD deployment.

sudo ceph osd status
sudo ceph osd tree
Task 2: Configure Storage Services (RBD, RGW, CephFS)
Subtask 2.1: Configure RADOS Block Device (RBD)
Step 1: Create a pool for RBD.

# Create replicated pool for RBD
sudo ceph osd pool create rbd-pool 64 64
sudo ceph osd pool application enable rbd-pool rbd
Step 2: Initialize the RBD pool.

sudo rbd pool init rbd-pool
Step 3: Create and test an RBD image.

# Create a 10GB RBD image
sudo rbd create --size 10G --pool rbd-pool test-image

# List RBD images
sudo rbd ls -p rbd-pool

# Get image information
sudo rbd info rbd-pool/test-image
Step 4: Map and mount the RBD image.

# Map the RBD image
sudo rbd map rbd-pool/test-image

# Create filesystem and mount
sudo mkfs.ext4 /dev/rbd0
sudo mkdir /mnt/ceph-rbd
sudo mount /dev/rbd0 /mnt/ceph-rbd

# Test write operations
sudo echo "RBD test successful" > /mnt/ceph-rbd/test.txt
cat /mnt/ceph-rbd/test.txt
Subtask 2.2: Configure RADOS Gateway (RGW)
Step 1: Deploy RGW service.

# Deploy RGW on specific nodes
sudo ceph orch apply rgw default --placement="2 ceph-node-3 ceph-node-4" --port=8080
Step 2: Verify RGW deployment.

sudo ceph orch ls | grep rgw
sudo ceph -s
Step 3: Create RGW user and test S3 access.

# Create S3 user
sudo radosgw-admin user create --uid=testuser --display-name="Test User" --email=test@example.com

# Generate access keys
sudo radosgw-admin key create --uid=testuser --key-type=s3 --gen-access-key --gen-secret
Step 4: Test S3 functionality using AWS CLI.

# Install AWS CLI
sudo dnf install -y awscli

# Configure AWS CLI (use the generated access keys)
aws configure set aws_access_key_id YOUR_ACCESS_KEY
aws configure set aws_secret_access_key YOUR_SECRET_KEY
aws configure set default.region us-east-1

# Test S3 operations
aws --endpoint-url http://ceph-node-3:8080 s3 mb s3://test-bucket
aws --endpoint-url http://ceph-node-3:8080 s3 cp /etc/hosts s3://test-bucket/
aws --endpoint-url http://ceph-node-3:8080 s3 ls s3://test-bucket/
Subtask 2.3: Configure CephFS (Ceph File System)
Step 1: Deploy MDS (Metadata Server) services.

# Deploy MDS services
sudo ceph orch apply mds cephfs --placement="2 ceph-node-1 ceph-node-2"
Step 2: Create CephFS pools.

# Create metadata and data pools
sudo ceph osd pool create cephfs-metadata 32 32
sudo ceph osd pool create cephfs-data 64 64

# Enable CephFS application
sudo ceph osd pool application enable cephfs-metadata cephfs
sudo ceph osd pool application enable cephfs-data cephfs
Step 3: Create the CephFS filesystem.

# Create filesystem
sudo ceph fs new cephfs cephfs-metadata cephfs-data

# Verify filesystem creation
sudo ceph fs status
sudo ceph mds stat
Step 4: Mount and test CephFS.

# Get admin key
sudo ceph auth get-key client.admin > /tmp/admin.key

# Create mount point and mount CephFS
sudo mkdir /mnt/cephfs
sudo mount -t ceph ceph-node-1:6789:/ /mnt/cephfs -o name=admin,secretfile=/tmp/admin.key

# Test CephFS operations
sudo echo "CephFS test successful" > /mnt/cephfs/test.txt
cat /mnt/cephfs/test.txt
ls -la /mnt/cephfs/
Task 3: Configure Replication and Failover
Subtask 3.1: Configure Pool Replication
Step 1: Set replication levels for different pools.

# Set replication size for RBD pool
sudo ceph osd pool set rbd-pool size 3
sudo ceph osd pool set rbd-pool min_size 2

# Set replication for CephFS pools
sudo ceph osd pool set cephfs-metadata size 3
sudo ceph osd pool set cephfs-metadata min_size 2
sudo ceph osd pool set cephfs-data size 3
sudo ceph osd pool set cephfs-data min_size 2

# Verify replication settings
sudo ceph osd pool ls detail
Step 2: Configure CRUSH rules for data placement.

# View current CRUSH map
sudo ceph osd crush tree

# Create custom CRUSH rule for rack-aware placement
sudo ceph osd crush rule create-replicated rack-rule default rack
sudo ceph osd pool set rbd-pool crush_rule rack-rule
Subtask 3.2: Test Failover Scenarios
Step 1: Simulate OSD failure.

# Stop an OSD to simulate failure
sudo ceph orch daemon stop osd.0

# Monitor cluster recovery
sudo ceph -w
sudo ceph health detail
Step 2: Verify data accessibility during failure.

# Test RBD access
sudo rbd ls -p rbd-pool
ls -la /mnt/ceph-rbd/

# Test CephFS access
ls -la /mnt/cephfs/

# Test RGW access
aws --endpoint-url http://ceph-node-3:8080 s3 ls s3://test-bucket/
Step 3: Restart the failed OSD and monitor recovery.

# Restart the OSD
sudo ceph orch daemon start osd.0

# Monitor recovery progress
sudo ceph -s
sudo ceph pg stat
Subtask 3.3: Configure Multi-Site Replication (RGW)
Step 1: Create realm and zonegroup for multi-site setup.

# Create realm
sudo radosgw-admin realm create --rgw-realm=test-realm --default

# Create zonegroup
sudo radosgw-admin zonegroup create --rgw-zonegroup=default --master --default

# Create zone
sudo radosgw-admin zone create --rgw-zonegroup=default --rgw-zone=zone1 --master --default
Step 2: Configure zone parameters.

# Set zone configuration
sudo radosgw-admin period update --commit

# Restart RGW services
sudo ceph orch restart rgw.default
Task 4: Performance Tuning
Subtask 4.1: Optimize OSD Performance
Step 1: Configure OSD performance parameters.

# Set OSD performance parameters
sudo ceph config set osd osd_max_backfills 2
sudo ceph config set osd osd_recovery_max_active 3
sudo ceph config set osd osd_recovery_op_priority 3

# Configure journal settings
sudo ceph config set osd osd_journal_size 5120
sudo ceph config set osd osd_op_threads 8
Step 2: Optimize network settings.

# Configure network parameters
sudo ceph config set global ms_bind_port_min 6800
sudo ceph config set global ms_bind_port_max 7100
sudo ceph config set global ms_crc_data false
sudo ceph config set global ms_crc_header false
Subtask 4.2: Tune Pool Parameters
Step 1: Optimize pool settings for performance.

# Set pool parameters for better performance
sudo ceph osd pool set rbd-pool pg_autoscale_mode on
sudo ceph osd pool set cephfs-data pg_autoscale_mode on

# Configure pool target ratios
sudo ceph osd pool set rbd-pool target_size_ratio 0.3
sudo ceph osd pool set cephfs-data target_size_ratio 0.5
Step 2: Enable fast read for pools.

# Enable fast read for RBD pool
sudo ceph osd pool set rbd-pool fast_read true
Subtask 4.3: Performance Testing
Step 1: Install and run performance testing tools.

# Install fio for performance testing
sudo dnf install -y fio

# Create fio test configuration
cat > /tmp/rbd-test.fio << EOF
[global]
ioengine=rbd
clientname=admin
pool=rbd-pool
rbdname=test-image
invalidate=0
rw=randwrite
bs=4k
iodepth=32
numjobs=1
runtime=60
group_reporting

[rbd-randwrite]
EOF

# Run performance test
sudo fio /tmp/rbd-test.fio
Step 2: Test CephFS performance.

# Test CephFS write performance
sudo dd if=/dev/zero of=/mnt/cephfs/testfile bs=1M count=1000 oflag=direct

# Test CephFS read performance
sudo dd if=/mnt/cephfs/testfile of=/dev/null bs=1M iflag=direct
Task 5: Implement Monitoring and Alerting
Subtask 5.1: Enable Ceph Dashboard
Step 1: Access and configure the Ceph Dashboard.

# Get dashboard URL and credentials
sudo ceph mgr services

# Enable dashboard modules
sudo ceph mgr module enable dashboard
sudo ceph mgr module enable prometheus
sudo ceph mgr module enable alerts
Step 2: Configure dashboard settings.

# Set dashboard configuration
sudo ceph dashboard create-self-signed-cert
sudo ceph dashboard ac-user-create admin administrator

# Set dashboard password
echo "admin123" | sudo ceph dashboard ac-user-set-password admin -i -
Subtask 5.2: Deploy Prometheus and Grafana
Step 1: Deploy Prometheus for metrics collection.

# Deploy Prometheus
sudo ceph orch apply prometheus --placement="1 ceph-node-1"

# Deploy node-exporter for system metrics
sudo ceph orch apply node-exporter
Step 2: Deploy Grafana for visualization.

# Deploy Grafana
sudo ceph orch apply grafana --placement="1 ceph-node-1"

# Get Grafana admin password
sudo ceph orch ls grafana --format json | jq -r '.[0].status.ports'
Step 3: Configure Grafana dashboards.

# Access Grafana web interface
# Default credentials: admin/admin
# Import Ceph dashboards from Grafana.com
Subtask 5.3: Set Up Alerting
Step 1: Configure Alertmanager.

# Deploy Alertmanager
sudo ceph orch apply alertmanager --placement="1 ceph-node-2"
Step 2: Create custom alert rules.

# Create alert rules file
cat > /tmp/ceph-alerts.yml << EOF
groups:
- name: ceph-alerts
  rules:
  - alert: CephClusterWarning
    expr: ceph_health_status == 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Ceph cluster health is in warning state"
      
  - alert: CephClusterError
    expr: ceph_health_status == 2
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Ceph cluster health is in error state"
      
  - alert: CephOSDDown
    expr: ceph_osd_up == 0
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: "Ceph OSD {{ \$labels.ceph_daemon }} is down"
EOF

# Apply alert rules
sudo ceph orch apply -i /tmp/ceph-alerts.yml
Subtask 5.4: Monitor Cluster Health
Step 1: Set up continuous monitoring commands.

# Create monitoring script
cat > /tmp/monitor-ceph.sh << '#!/bin/bash
while true; do
    echo "=== Ceph Cluster Status ==="
    sudo ceph -s
    echo ""
    echo "=== OSD Status ==="
    sudo ceph osd stat
    echo ""
    echo "=== Pool Usage ==="
    sudo ceph df
    echo ""
    sleep 30
done
EOF'

chmod +x /tmp/monitor-ceph.sh
Step 2: Verify monitoring data collection.

# Check Prometheus metrics
curl http://ceph-node-1:9095/metrics | grep ceph_health_status

# Verify dashboard accessibility
curl -k https://ceph-node-1:8443/
Task 6: Advanced Configuration and Troubleshooting
Subtask 6.1: Configure Advanced Security
Step 1: Enable encryption at rest.

# Create encrypted pool
sudo ceph osd pool create encrypted-pool 32 32
sudo ceph osd pool application enable encrypted-pool rbd

# Configure encryption
sudo ceph config set osd osd_dmcrypt_key_size 256
Step 2: Configure client authentication.

# Create restricted client user
sudo ceph auth get-or-create client.restricted mon 'allow r' osd 'allow rw pool=rbd-pool'

# Export client keyring
sudo ceph auth export client.restricted > /tmp/client.restricted.keyring
Subtask 6.2: Backup and Recovery Procedures
Step 1: Create cluster configuration backup.

# Backup cluster configuration
sudo ceph config dump > /tmp/ceph-config-backup.txt
sudo ceph auth export > /tmp/ceph-auth-backup.txt
sudo ceph osd getcrushmap -o /tmp/crushmap-backup.bin
Step 2: Test RBD snapshot and restore.

# Create RBD snapshot
sudo rbd snap create rbd-pool/test-image@backup-snapshot

# List snapshots
sudo rbd snap ls rbd-pool/test-image

# Clone snapshot for testing
sudo rbd clone rbd-pool/test-image@backup-snapshot rbd-pool/restored-image
Subtask 6.3: Common Troubleshooting Scenarios
Step 1: Diagnose and fix common issues.

# Check for common problems
sudo ceph health detail

# Fix clock skew issues
sudo chrony sources -v
sudo systemctl restart chronyd

# Resolve placement group issues
sudo ceph pg dump | grep -E "(stuck|inconsistent|incomplete)"
sudo ceph pg repair 1.0  # Replace with actual PG ID if needed
Step 2: Performance troubleshooting.

# Check slow operations
sudo ceph daemon osd.0 dump_historic_slow_ops

# Monitor real-time operations
sudo ceph daemon osd.0 perf dump

# Check network connectivity
sudo ceph daemon osd.0 dump_watchers
Verification and Testing
Final Cluster Validation
Step 1: Comprehensive cluster health check.

# Complete cluster status
sudo ceph status
sudo ceph health detail
sudo ceph df detail

# Service status verification
sudo ceph orch ls
sudo ceph orch ps
Step 2: End-to-end functionality testing.

# Test all storage types
echo "Testing RBD..." && ls -la /mnt/ceph-rbd/
echo "Testing CephFS..." && ls -la /mnt/cephfs/
echo "Testing RGW..." && aws --endpoint-url http://ceph-node-3:8080 s3 ls

# Performance verification
sudo ceph osd perf
sudo ceph pg stat
Step 3: Generate cluster report.

# Create comprehensive cluster report
sudo ceph report > /tmp/ceph-cluster-report.json
sudo ceph versions
sudo ceph features
Conclusion
Congratulations! You have successfully completed the comprehensive Ceph cluster deployment and management lab. Throughout this lab, you have:

Key Accomplishments:

Deployed a Production-Ready Ceph Cluster: Successfully bootstrapped and configured a multi-node Ceph cluster with all essential services
Implemented All Storage Types: Configured and tested RBD (block storage), RGW (object storage), and CephFS (file storage)
Established High Availability: Configured replication, failover mechanisms, and tested disaster recovery scenarios
Optimized Performance: Applied performance tuning techniques and conducted comprehensive testing
Implemented Monitoring: Set up complete monitoring and alerting infrastructure using Prometheus, Grafana, and Alertmanager
Applied Security Best Practices: Configured authentication, authorization, and encryption features
Developed Troubleshooting Skills: Learned to diagnose and resolve common Ceph cluster issues
Why This Matters:

This lab represents real-world enterprise storage deployment scenarios. The skills you've developed are directly applicable to:

Enterprise Storage Solutions: Managing petabyte-scale storage infrastructure
Cloud Storage Platforms: Building and maintaining cloud storage services
DevOps and SRE Roles: Ensuring storage reliability and performance in production environments
Red Hat Certification: Preparing for the Red Hat Certified Specialist in Ceph Cloud Storage exam
Next Steps:

Practice scaling the cluster by adding more nodes and storage
Explore advanced features like erasure coding and cache tiering
Implement automation using Ansible or other configuration management tools
Study disaster recovery procedures and multi-site replication
Prepare for the Red Hat Ceph Storage certification exam
The comprehensive Ceph cluster you've built serves as a foundation for understanding modern software-defined storage solutions and prepares you for advanced storage administration roles in enterprise environments.
