Lab 19: Configuring Ceph for High Availability
Objectives
By the end of this lab, students will be able to:

Configure a multi-site Ceph cluster with replication capabilities
Implement and test failover mechanisms for disaster recovery
Optimize Ceph clusters for maximum uptime and fault tolerance
Understand Ceph's RADOS Gateway (RGW) multi-site configuration
Perform disaster recovery testing and validation
Monitor cluster health and performance across multiple sites
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph storage architecture
Familiarity with Linux command line operations
Knowledge of network configuration concepts
Understanding of storage replication principles
Experience with YAML configuration files
Basic knowledge of containerization (Docker/Podman)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click "Start Lab" to access your environment - no need to build your own virtual machines.

Your lab environment includes:

6 CentOS Stream 9 machines (3 per site)
Pre-installed Ceph Quincy release
Network connectivity between sites
Required dependencies and tools
Task 1: Set Up Multi-Site Ceph Cluster Replication
Subtask 1.1: Initialize Primary Site Cluster
First, we'll set up the primary Ceph cluster that will serve as our main data center.

Step 1: Access the Primary Site Machines

Connect to your primary site machines (ceph-primary-1, ceph-primary-2, ceph-primary-3):

# Connect to the first primary node
ssh root@ceph-primary-1

# Verify Ceph installation
ceph --version
Step 2: Bootstrap the Primary Cluster

# Install cephadm if not already present
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
chmod +x cephadm
./cephadm add-repo --release quincy
./cephadm install

# Bootstrap the cluster
cephadm bootstrap --mon-ip 10.0.1.10 --cluster-network 10.0.1.0/24 --ssh-user root
Step 3: Add Additional Nodes to Primary Cluster

# Copy SSH keys to other nodes
ssh-copy-id root@ceph-primary-2
ssh-copy-id root@ceph-primary-3

# Add nodes to the cluster
ceph orch host add ceph-primary-2 10.0.1.11
ceph orch host add ceph-primary-3 10.0.1.12

# Verify cluster status
ceph status
Step 4: Deploy OSDs on Primary Site

# List available devices
ceph orch device ls

# Deploy OSDs on all available devices
ceph orch apply osd --all-available-devices

# Verify OSD deployment
ceph osd status
Subtask 1.2: Configure RADOS Gateway on Primary Site
Step 1: Deploy RGW Service

# Create RGW service
ceph orch apply rgw primary-site --placement="3 ceph-primary-1 ceph-primary-2 ceph-primary-3" --port=8080

# Verify RGW deployment
ceph orch ls rgw
Step 2: Create RGW User and Configure Realm

# Create a realm for multi-site configuration
radosgw-admin realm create --rgw-realm=multisite --default

# Create a zonegroup
radosgw-admin zonegroup create --rgw-zonegroup=primary-zg --master --default

# Create a zone
radosgw-admin zone create --rgw-zonegroup=primary-zg --rgw-zone=primary-zone --master --default

# Create system user for replication
radosgw-admin user create --uid=replication-user --display-name="Replication User" --system
Step 3: Configure Zone Parameters

# Set zone configuration
radosgw-admin zone modify --rgw-zone=primary-zone --access-key=ACCESS_KEY --secret=SECRET_KEY

# Commit the configuration
radosgw-admin period update --commit

# Restart RGW services
ceph orch restart rgw.primary-site
Subtask 1.3: Initialize Secondary Site Cluster
Step 1: Bootstrap Secondary Cluster

Connect to the secondary site and bootstrap the cluster:

# Connect to secondary site
ssh root@ceph-secondary-1

# Bootstrap secondary cluster
cephadm bootstrap --mon-ip 10.0.2.10 --cluster-network 10.0.2.0/24 --ssh-user root
Step 2: Add Secondary Site Nodes

# Add secondary nodes
ssh-copy-id root@ceph-secondary-2
ssh-copy-id root@ceph-secondary-3

ceph orch host add ceph-secondary-2 10.0.2.11
ceph orch host add ceph-secondary-3 10.0.2.12

# Deploy OSDs
ceph orch apply osd --all-available-devices
Step 3: Configure Secondary Site for Multi-Site Replication

# Pull realm configuration from primary site
radosgw-admin realm pull --url=http://10.0.1.10:8080 --access-key=ACCESS_KEY --secret=SECRET_KEY

# Set default realm
radosgw-admin realm default --rgw-realm=multisite

# Pull zonegroup configuration
radosgw-admin zonegroup pull --url=http://10.0.1.10:8080 --access-key=ACCESS_KEY --secret=SECRET_KEY

# Create secondary zone
radosgw-admin zone create --rgw-zonegroup=primary-zg --rgw-zone=secondary-zone --access-key=ACCESS_KEY --secret=SECRET_KEY --endpoints=http://10.0.2.10:8080

# Update period
radosgw-admin period update --commit

# Deploy RGW on secondary site
ceph orch apply rgw secondary-site --placement="3 ceph-secondary-1 ceph-secondary-2 ceph-secondary-3" --port=8080
Subtask 1.4: Verify Multi-Site Replication
Step 1: Test Data Replication

# On primary site, create a test bucket
aws s3 mb s3://test-replication --endpoint-url=http://10.0.1.10:8080

# Upload test data
echo "This is test data for replication" > test-file.txt
aws s3 cp test-file.txt s3://test-replication/ --endpoint-url=http://10.0.1.10:8080

# Verify replication on secondary site
aws s3 ls s3://test-replication --endpoint-url=http://10.0.2.10:8080
Step 2: Monitor Replication Status

# Check sync status
radosgw-admin sync status

# View replication log
radosgw-admin sync error list
Task 2: Test Failover and Recovery Mechanisms
Subtask 2.1: Simulate Primary Site Failure
Step 1: Create Comprehensive Test Data

# Create multiple buckets with various data types
for i in {1..5}; do
    aws s3 mb s3://test-bucket-$i --endpoint-url=http://10.0.1.10:8080
    
    # Upload different file types
    dd if=/dev/urandom of=large-file-$i.bin bs=1M count=10
    aws s3 cp large-file-$i.bin s3://test-bucket-$i/ --endpoint-url=http://10.0.1.10:8080
done
Step 2: Document Pre-Failure State

# Record bucket list and contents
aws s3 ls --endpoint-url=http://10.0.1.10:8080 > pre-failure-buckets.txt

# Record cluster status
ceph status > pre-failure-cluster-status.txt
Step 3: Simulate Primary Site Failure

# Stop all services on primary site nodes
for node in ceph-primary-1 ceph-primary-2 ceph-primary-3; do
    ssh root@$node "systemctl stop ceph.target"
done

# Verify primary site is down
curl -I http://10.0.1.10:8080 || echo "Primary site is down"
Subtask 2.2: Promote Secondary Site to Primary
Step 1: Promote Secondary Zone

# On secondary site, promote zone to master
radosgw-admin zone modify --rgw-zone=secondary-zone --master

# Update and commit period
radosgw-admin period update --commit

# Restart RGW services
ceph orch restart rgw.secondary-site
Step 2: Verify Failover Success

# Test data accessibility from secondary site
aws s3 ls --endpoint-url=http://10.0.2.10:8080

# Verify all buckets are accessible
for i in {1..5}; do
    aws s3 ls s3://test-bucket-$i --endpoint-url=http://10.0.2.10:8080
done
Step 3: Test Write Operations on Secondary

# Create new data on secondary site
aws s3 mb s3://failover-test --endpoint-url=http://10.0.2.10:8080
echo "Data created during failover" > failover-data.txt
aws s3 cp failover-data.txt s3://failover-test/ --endpoint-url=http://10.0.2.10:8080
Subtask 2.3: Recover Primary Site
Step 1: Restart Primary Site Services

# Restart Ceph services on primary site
for node in ceph-primary-1 ceph-primary-2 ceph-primary-3; do
    ssh root@$node "systemctl start ceph.target"
done

# Wait for cluster to stabilize
sleep 60
Step 2: Resync Primary Site

# On primary site, pull latest period
radosgw-admin period pull --url=http://10.0.2.10:8080 --access-key=ACCESS_KEY --secret=SECRET_KEY

# Force full sync
radosgw-admin sync run --source-zone=secondary-zone
Step 3: Verify Data Consistency

# Compare data between sites
aws s3 ls --endpoint-url=http://10.0.1.10:8080 > post-recovery-primary.txt
aws s3 ls --endpoint-url=http://10.0.2.10:8080 > post-recovery-secondary.txt

# Check for differences
diff post-recovery-primary.txt post-recovery-secondary.txt
Task 3: Optimize the Cluster for Uptime and Disaster Recovery
Subtask 3.1: Configure Advanced Monitoring
Step 1: Deploy Prometheus and Grafana

# Deploy Prometheus
ceph orch apply prometheus --placement="ceph-primary-1"

# Deploy Grafana
ceph orch apply grafana --placement="ceph-primary-1"

# Deploy Node Exporter
ceph orch apply node-exporter

# Deploy Alert Manager
ceph orch apply alertmanager --placement="ceph-primary-1"
Step 2: Configure Custom Alerts

Create a custom alert configuration file:

cat > /etc/ceph/alerting-rules.yml << 'EOF'
groups:
- name: ceph-multisite
  rules:
  - alert: CephMultisiteReplicationLag
    expr: ceph_rgw_sync_lag > 300
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Ceph multisite replication lag detected"
      description: "Replication lag between sites is {{ $value }} seconds"
  
  - alert: CephSiteDown
    expr: up{job="ceph-rgw"} == 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Ceph site is down"
      description: "Site {{ $labels.instance }} is not responding"
EOF
Step 3: Configure Automated Health Checks

# Create health check script
cat > /usr/local/bin/ceph-multisite-health.sh << 'EOF'
#!/bin/bash

PRIMARY_ENDPOINT="http://10.0.1.10:8080"
SECONDARY_ENDPOINT="http://10.0.2.10:8080"
LOG_FILE="/var/log/ceph-multisite-health.log"

check_site() {
    local endpoint=$1
    local site_name=$2
    
    if curl -s -f "$endpoint" > /dev/null; then
        echo "$(date): $site_name is healthy" >> $LOG_FILE
        return 0
    else
        echo "$(date): $site_name is down" >> $LOG_FILE
        return 1
    fi
}

# Check both sites
check_site $PRIMARY_ENDPOINT "Primary"
check_site $SECONDARY_ENDPOINT "Secondary"

# Check replication status
radosgw-admin sync status >> $LOG_FILE 2>&1
EOF

chmod +x /usr/local/bin/ceph-multisite-health.sh

# Add to crontab for regular execution
echo "*/5 * * * * /usr/local/bin/ceph-multisite-health.sh" | crontab -
Subtask 3.2: Implement Automated Failover
Step 1: Create Failover Script

cat > /usr/local/bin/ceph-auto-failover.sh << 'EOF'
#!/bin/bash

PRIMARY_ENDPOINT="http://10.0.1.10:8080"
SECONDARY_ENDPOINT="http://10.0.2.10:8080"
FAILOVER_FLAG="/tmp/ceph-failover-active"
LOG_FILE="/var/log/ceph-failover.log"

log_message() {
    echo "$(date): $1" >> $LOG_FILE
}

check_primary() {
    curl -s -f "$PRIMARY_ENDPOINT" > /dev/null
    return $?
}

promote_secondary() {
    log_message "Promoting secondary site to primary"
    
    # Promote secondary zone
    radosgw-admin zone modify --rgw-zone=secondary-zone --master
    radosgw-admin period update --commit
    
    # Restart RGW services
    ceph orch restart rgw.secondary-site
    
    # Create failover flag
    touch $FAILOVER_FLAG
    
    log_message "Failover completed successfully"
}

# Main logic
if ! check_primary; then
    if [ ! -f $FAILOVER_FLAG ]; then
        log_message "Primary site failure detected, initiating failover"
        promote_secondary
    else
        log_message "Failover already active"
    fi
else
    log_message "Primary site is healthy"
    if [ -f $FAILOVER_FLAG ]; then
        log_message "Primary site recovered, manual intervention required"
    fi
fi
EOF

chmod +x /usr/local/bin/ceph-auto-failover.sh
Step 2: Configure Failover Monitoring

# Add failover script to crontab
echo "*/2 * * * * /usr/local/bin/ceph-auto-failover.sh" | crontab -

# Create systemd service for more robust monitoring
cat > /etc/systemd/system/ceph-failover-monitor.service << 'EOF'
[Unit]
Description=Ceph Multi-site Failover Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ceph-auto-failover.sh
Restart=always
RestartSec=120
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ceph-failover-monitor.service
systemctl start ceph-failover-monitor.service
Subtask 3.3: Optimize Performance and Reliability
Step 1: Configure Optimal OSD Settings

# Set optimal OSD configuration
ceph config set osd osd_memory_target 4294967296
ceph config set osd osd_max_backfills 1
ceph config set osd osd_recovery_max_active 3
ceph config set osd osd_recovery_op_priority 3

# Configure BlueStore settings
ceph config set osd bluestore_cache_size 2147483648
ceph config set osd bluestore_cache_meta_ratio 0.4
ceph config set osd bluestore_cache_kv_ratio 0.4
Step 2: Optimize RGW for Multi-Site

# Configure RGW for better multi-site performance
ceph config set client.rgw rgw_sync_lease_period 120
ceph config set client.rgw rgw_sync_log_trim_interval 1200
ceph config set client.rgw rgw_sync_data_inject_err_probability 0
ceph config set client.rgw rgw_sync_meta_inject_err_probability 0

# Restart RGW services to apply changes
ceph orch restart rgw
Step 3: Configure Backup and Snapshot Policies

# Create automated snapshot script
cat > /usr/local/bin/ceph-backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/backup/ceph-config"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup cluster configuration
ceph config dump > $BACKUP_DIR/cluster-config-$DATE.json
ceph osd tree > $BACKUP_DIR/osd-tree-$DATE.txt
ceph status > $BACKUP_DIR/cluster-status-$DATE.txt

# Backup RGW configuration
radosgw-admin realm list > $BACKUP_DIR/rgw-realms-$DATE.json
radosgw-admin zonegroup list > $BACKUP_DIR/rgw-zonegroups-$DATE.json
radosgw-admin zone list > $BACKUP_DIR/rgw-zones-$DATE.json

# Compress old backups
find $BACKUP_DIR -name "*.txt" -o -name "*.json" -mtime +7 -exec gzip {} \;

# Remove backups older than 30 days
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /usr/local/bin/ceph-backup.sh

# Schedule daily backups
echo "0 2 * * * /usr/local/bin/ceph-backup.sh" | crontab -
Subtask 3.4: Validate Disaster Recovery Procedures
Step 1: Create Disaster Recovery Test Plan

# Create comprehensive test data
for i in {1..10}; do
    aws s3 mb s3://dr-test-bucket-$i --endpoint-url=http://10.0.1.10:8080
    
    # Create files of different sizes
    dd if=/dev/urandom of=small-file-$i.bin bs=1K count=100
    dd if=/dev/urandom of=medium-file-$i.bin bs=1M count=5
    dd if=/dev/urandom of=large-file-$i.bin bs=1M count=50
    
    aws s3 cp small-file-$i.bin s3://dr-test-bucket-$i/ --endpoint-url=http://10.0.1.10:8080
    aws s3 cp medium-file-$i.bin s3://dr-test-bucket-$i/ --endpoint-url=http://10.0.1.10:8080
    aws s3 cp large-file-$i.bin s3://dr-test-bucket-$i/ --endpoint-url=http://10.0.1.10:8080
done
Step 2: Execute Full Disaster Recovery Test

# Document pre-test state
aws s3 ls --endpoint-url=http://10.0.1.10:8080 > dr-test-before.txt
radosgw-admin sync status > sync-status-before.txt

# Simulate complete primary site failure
for node in ceph-primary-1 ceph-primary-2 ceph-primary-3; do
    ssh root@$node "systemctl stop ceph.target && systemctl disable ceph.target"
done

# Wait for failover detection
sleep 300

# Verify secondary site operation
aws s3 ls --endpoint-url=http://10.0.2.10:8080 > dr-test-after-failover.txt

# Test data integrity
for i in {1..10}; do
    aws s3 ls s3://dr-test-bucket-$i --endpoint-url=http://10.0.2.10:8080
done
Step 3: Measure Recovery Metrics

# Create recovery metrics script
cat > /usr/local/bin/measure-recovery.sh << 'EOF'
#!/bin/bash

START_TIME=$(date +%s)
ENDPOINT="http://10.0.2.10:8080"
LOG_FILE="/var/log/recovery-metrics.log"

echo "Recovery test started at $(date)" >> $LOG_FILE

# Test service availability
while ! curl -s -f $ENDPOINT > /dev/null; do
    sleep 5
done

SERVICE_RECOVERY_TIME=$(($(date +%s) - START_TIME))
echo "Service recovery time: ${SERVICE_RECOVERY_TIME} seconds" >> $LOG_FILE

# Test data availability
DATA_START_TIME=$(date +%s)
while ! aws s3 ls s3://dr-test-bucket-1 --endpoint-url=$ENDPOINT > /dev/null 2>&1; do
    sleep 5
done

DATA_RECOVERY_TIME=$(($(date +%s) - DATA_START_TIME))
echo "Data recovery time: ${DATA_RECOVERY_TIME} seconds" >> $LOG_FILE

# Calculate total recovery time
TOTAL_RECOVERY_TIME=$(($(date +%s) - START_TIME))
echo "Total recovery time: ${TOTAL_RECOVERY_TIME} seconds" >> $LOG_FILE

echo "Recovery test completed at $(date)" >> $LOG_FILE
EOF

chmod +x /usr/local/bin/measure-recovery.sh
Troubleshooting Common Issues
Issue 1: Replication Lag
Symptoms: Data not appearing on secondary site promptly

Solution:

# Check sync status
radosgw-admin sync status

# Force sync if needed
radosgw-admin sync run --source-zone=primary-zone

# Increase sync workers
ceph config set client.rgw rgw_sync_data_inject_err_probability 0
Issue 2: Split-Brain Scenario
Symptoms: Both sites claiming to be primary

Solution:

# Identify the correct primary based on latest period
radosgw-admin period get

# Reset the incorrect site
radosgw-admin zone modify --rgw-zone=secondary-zone --master=false
radosgw-admin period update --commit
Issue 3: Network Connectivity Issues
Symptoms: Sites cannot communicate

Solution:

# Test network connectivity
ping 10.0.2.10
telnet 10.0.2.10 8080

# Check firewall rules
firewall-cmd --list-all
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
Conclusion
In this comprehensive lab, you have successfully:

Configured a multi-site Ceph cluster with automatic replication between primary and secondary sites, ensuring data redundancy across geographically distributed locations
Implemented and tested failover mechanisms that automatically promote the secondary site to primary during disasters, minimizing downtime and data loss
Optimized cluster performance through advanced monitoring, automated health checks, and performance tuning for maximum uptime
Validated disaster recovery procedures with comprehensive testing scenarios that measure recovery times and data integrity
This high-availability Ceph configuration provides enterprise-grade disaster recovery capabilities essential for mission-critical applications. The multi-site replication ensures business continuity even during complete site failures, while automated monitoring and failover mechanisms reduce manual intervention and recovery time.

The skills learned in this lab are directly applicable to the Red Hat Certified Specialist in Ceph Cloud Storage exam and real-world enterprise storage deployments where data availability and disaster recovery are paramount concerns.

Key takeaways include understanding the importance of regular disaster recovery testing, maintaining proper monitoring and alerting systems, and implementing automated failover procedures that can respond to failures faster than manual intervention. These practices ensure that your Ceph storage infrastructure can meet the demanding availability requirements of modern enterprise applications.
