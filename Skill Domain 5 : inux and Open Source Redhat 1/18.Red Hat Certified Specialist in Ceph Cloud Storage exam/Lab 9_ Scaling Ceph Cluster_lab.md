Lab 9: Scaling Ceph Cluster
Objectives
By the end of this lab, students will be able to:

Understand the principles of Ceph cluster scaling and expansion
Add new Monitor (MON) nodes to maintain cluster quorum and high availability
Configure and integrate new Object Storage Daemon (OSD) nodes into an existing cluster
Monitor the automatic data rebalancing process during cluster expansion
Verify proper data distribution across the expanded cluster
Implement best practices for cluster scaling operations
Troubleshoot common issues encountered during cluster expansion
Prerequisites
Before starting this lab, students should have:

Knowledge Requirements:

Basic understanding of Ceph architecture (MONs, OSDs, MGRs)
Familiarity with Linux command line operations
Understanding of distributed storage concepts
Knowledge of CRUSH maps and placement groups
Technical Requirements:

Access to Al Nafi cloud machines (Linux-based)
Existing Ceph cluster with at least 3 MON nodes and 6 OSD nodes
Root or sudo access on all cluster nodes
Network connectivity between all nodes
Tools and Software:

Ceph Pacific (16.x) or later version
ceph-deploy or cephadm for cluster management
Basic monitoring tools (htop, iostat, iotop)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines.

Your lab environment includes:

Existing Cluster: 3 MON nodes, 6 OSD nodes, 2 MGR nodes
New Nodes: 2 additional MON nodes, 4 additional OSD nodes
Network: All nodes connected via private network
Storage: Each OSD node has additional unused disks ready for configuration
Task 1: Add New MON Nodes and Configure Quorum
Subtask 1.1: Prepare New MON Nodes
First, let's identify and prepare the new MON nodes for integration.

Step 1: Check Current Cluster Status

# Connect to your existing admin node
sudo ceph status

# Check current MON configuration
sudo ceph mon stat

# List current MONs
sudo ceph mon dump
Step 2: Prepare New MON Nodes

# SSH to each new MON node and update system
ssh ceph-mon4
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y ceph-mon ceph-common

# Repeat for ceph-mon5
ssh ceph-mon5
sudo apt update && sudo apt upgrade -y
sudo apt install -y ceph-mon ceph-common
Subtask 1.2: Add First New MON Node
Step 1: Create MON Data Directory

# On ceph-mon4
sudo mkdir -p /var/lib/ceph/mon/ceph-mon4
sudo chown ceph:ceph /var/lib/ceph/mon/ceph-mon4
Step 2: Get MON Map and Keys

# From admin node, get the current MON map
sudo ceph mon getmap -o /tmp/monmap

# Get the MON keyring
sudo ceph auth get mon. -o /tmp/mon.keyring

# Copy files to new MON node
scp /tmp/monmap ceph-mon4:/tmp/
scp /tmp/mon.keyring ceph-mon4:/tmp/
Step 3: Initialize New MON

# On ceph-mon4
sudo ceph-mon --mkfs -i mon4 --monmap /tmp/monmap --keyring /tmp/mon.keyring

# Set ownership
sudo chown -R ceph:ceph /var/lib/ceph/mon/ceph-mon4

# Start the MON service
sudo systemctl enable ceph-mon@mon4
sudo systemctl start ceph-mon@mon4
Step 4: Add MON to Cluster

# From admin node, add the new MON
sudo ceph mon add mon4 <MON4_IP_ADDRESS>:6789

# Verify the addition
sudo ceph mon stat
sudo ceph status
Subtask 1.3: Add Second New MON Node
Step 1: Repeat Process for MON5

# On ceph-mon5
sudo mkdir -p /var/lib/ceph/mon/ceph-mon5
sudo chown ceph:ceph /var/lib/ceph/mon/ceph-mon5

# From admin node
sudo ceph mon getmap -o /tmp/monmap-new
scp /tmp/monmap-new ceph-mon5:/tmp/monmap
scp /tmp/mon.keyring ceph-mon5:/tmp/

# On ceph-mon5
sudo ceph-mon --mkfs -i mon5 --monmap /tmp/monmap --keyring /tmp/mon.keyring
sudo chown -R ceph:ceph /var/lib/ceph/mon/ceph-mon5
sudo systemctl enable ceph-mon@mon5
sudo systemctl start ceph-mon@mon5
Step 2: Add to Cluster and Verify

# From admin node
sudo ceph mon add mon5 <MON5_IP_ADDRESS>:6789

# Verify quorum with 5 MONs
sudo ceph quorum_status --format json-pretty
sudo ceph mon stat
Subtask 1.4: Verify MON Quorum Configuration
Step 1: Check Quorum Status

# Verify all 5 MONs are in quorum
sudo ceph quorum_status

# Check MON election history
sudo ceph mon dump

# Verify MON connectivity
sudo ceph tell mon.* version
Step 2: Test Quorum Resilience

# Stop one MON to test quorum (should still work with 4/5)
sudo systemctl stop ceph-mon@mon1

# Check cluster status (should remain healthy)
sudo ceph status

# Restart the MON
sudo systemctl start ceph-mon@mon1

# Verify all MONs rejoin quorum
sudo ceph quorum_status
Task 2: Add New OSD Nodes and Configure Storage Devices
Subtask 2.1: Prepare New OSD Nodes
Step 1: Install Ceph on New OSD Nodes

# SSH to each new OSD node
for node in ceph-osd7 ceph-osd8 ceph-osd9 ceph-osd10; do
    ssh $node "sudo apt update && sudo apt install -y ceph-osd ceph-common"
done
Step 2: Identify Available Disks

# On each OSD node, identify unused disks
ssh ceph-osd7 "lsblk | grep -v part"
ssh ceph-osd8 "lsblk | grep -v part"
ssh ceph-osd9 "lsblk | grep -v part"
ssh ceph-osd10 "lsblk | grep -v part"

# Example output should show unused disks like /dev/sdb, /dev/sdc
Subtask 2.2: Add OSDs Using ceph-volume
Step 1: Prepare Disks on First New OSD Node

# On ceph-osd7, prepare the first disk
ssh ceph-osd7

# List available devices
sudo ceph-volume lvm list

# Create OSD on /dev/sdb
sudo ceph-volume lvm create --data /dev/sdb

# Create OSD on /dev/sdc (if available)
sudo ceph-volume lvm create --data /dev/sdc
Step 2: Add OSDs on Remaining Nodes

# On ceph-osd8
ssh ceph-osd8
sudo ceph-volume lvm create --data /dev/sdb
sudo ceph-volume lvm create --data /dev/sdc

# On ceph-osd9
ssh ceph-osd9
sudo ceph-volume lvm create --data /dev/sdb
sudo ceph-volume lvm create --data /dev/sdc

# On ceph-osd10
ssh ceph-osd10
sudo ceph-volume lvm create --data /dev/sdb
sudo ceph-volume lvm create --data /dev/sdc
Step 3: Verify OSD Creation

# From admin node, check new OSDs
sudo ceph osd tree

# Check OSD status
sudo ceph osd stat

# Verify all OSDs are up and in
sudo ceph osd dump | grep "osd\."
Subtask 2.3: Configure OSD Placement and Weights
Step 1: Check Current CRUSH Map

# View current CRUSH hierarchy
sudo ceph osd tree

# Get CRUSH map for editing
sudo ceph osd getcrushmap -o /tmp/crushmap.bin
sudo crushtool -d /tmp/crushmap.bin -o /tmp/crushmap.txt
Step 2: Verify New OSDs in CRUSH Map

# Check if new OSDs are properly placed
sudo ceph osd tree

# If needed, move OSDs to correct hosts
sudo ceph osd crush move osd.6 host=ceph-osd7
sudo ceph osd crush move osd.7 host=ceph-osd7
# Repeat for other OSDs as needed
Step 3: Adjust OSD Weights if Necessary

# Check OSD weights (should be based on disk size)
sudo ceph osd tree

# If weights need adjustment (example for 1TB disks)
sudo ceph osd crush reweight osd.6 1.0
sudo ceph osd crush reweight osd.7 1.0
# Repeat for other new OSDs
Task 3: Monitor Rebalancing and Verify Data Distribution
Subtask 3.1: Monitor Initial Rebalancing
Step 1: Start Monitoring Cluster Status

# Watch cluster status in real-time
watch -n 5 'ceph status'

# In another terminal, monitor PG status
watch -n 10 'ceph pg stat'

# Monitor OSD utilization
watch -n 15 'ceph osd df'
Step 2: Check Rebalancing Progress

# View detailed rebalancing information
sudo ceph progress

# Check recovery operations
sudo ceph status | grep -A 10 "recovery"

# Monitor data movement
sudo ceph osd pool stats
Subtask 3.2: Analyze Data Distribution
Step 1: Check PG Distribution

# View PG distribution across OSDs
sudo ceph pg dump osds

# Check PG states
sudo ceph pg stat

# Identify any stuck PGs
sudo ceph pg dump_stuck
Step 2: Verify Pool Distribution

# Check data distribution per pool
sudo ceph osd pool stats

# View detailed pool information
sudo ceph osd pool ls detail

# Check pool PG distribution
for pool in $(ceph osd pool ls); do
    echo "Pool: $pool"
    sudo ceph pg ls-by-pool $pool | head -10
done
Subtask 3.3: Performance Monitoring During Rebalancing
Step 1: Monitor Cluster Performance

# Check cluster performance stats
sudo ceph daemonperf osd

# Monitor recovery bandwidth
sudo ceph tell 'osd.*' config show | grep osd_recovery

# Check backfill operations
sudo ceph status | grep backfill
Step 2: Create Performance Monitoring Script

# Create monitoring script
cat > /tmp/monitor_rebalance.sh << 'EOF'
#!/bin/bash

echo "=== Ceph Cluster Rebalancing Monitor ==="
echo "Timestamp: $(date)"
echo

echo "=== Cluster Status ==="
ceph status
echo

echo "=== OSD Utilization ==="
ceph osd df
echo

echo "=== PG Status ==="
ceph pg stat
echo

echo "=== Recovery Progress ==="
ceph progress
echo

echo "=== Active Recovery Operations ==="
ceph status | grep -E "(recovery|backfill|rebalancing)"
echo
EOF

chmod +x /tmp/monitor_rebalance.sh

# Run monitoring script
/tmp/monitor_rebalance.sh
Subtask 3.4: Verify Successful Scaling
Step 1: Final Cluster Verification

# Check final cluster health
sudo ceph health detail

# Verify all OSDs are up and in
sudo ceph osd stat

# Check MON quorum
sudo ceph quorum_status

# Verify data distribution
sudo ceph osd df tree
Step 2: Test Cluster Functionality

# Create test pool to verify functionality
sudo ceph osd pool create test_scaling 32 32

# Write test data
echo "Test data after scaling" | sudo rados -p test_scaling put test_object -

# Read test data
sudo rados -p test_scaling get test_object -

# Check object placement
sudo ceph osd map test_scaling test_object

# Clean up test pool
sudo ceph osd pool delete test_scaling test_scaling --yes-i-really-really-mean-it
Step 3: Document Final Configuration

# Generate cluster report
sudo ceph report > /tmp/cluster_report_after_scaling.json

# Save cluster configuration
sudo ceph config dump > /tmp/cluster_config_after_scaling.txt

# Save CRUSH map
sudo ceph osd getcrushmap -o /tmp/crushmap_after_scaling.bin
sudo crushtool -d /tmp/crushmap_after_scaling.bin -o /tmp/crushmap_after_scaling.txt
Troubleshooting Common Issues
MON Addition Issues
Problem: MON fails to join quorum

# Check MON logs
sudo journalctl -u ceph-mon@mon4 -f

# Verify network connectivity
sudo ceph tell mon.* version

# Check time synchronization
sudo chrony sources -v
Solution: Ensure time sync and network connectivity

# Restart NTP/chrony service
sudo systemctl restart chrony

# Restart MON service
sudo systemctl restart ceph-mon@mon4
OSD Addition Issues
Problem: OSD fails to start or join cluster

# Check OSD logs
sudo journalctl -u ceph-osd@6 -f

# Verify OSD authentication
sudo ceph auth list | grep osd.6

# Check disk status
sudo ceph-volume lvm list
Solution: Recreate OSD if necessary

# Remove failed OSD
sudo ceph osd out 6
sudo ceph osd crush remove osd.6
sudo ceph auth del osd.6
sudo ceph osd rm 6

# Recreate OSD
sudo ceph-volume lvm create --data /dev/sdb
Rebalancing Issues
Problem: Slow or stuck rebalancing

# Check recovery settings
sudo ceph tell 'osd.*' config show | grep recovery

# Adjust recovery parameters
sudo ceph tell 'osd.*' config set osd_recovery_max_active 3
sudo ceph tell 'osd.*' config set osd_recovery_op_priority 1
Best Practices for Cluster Scaling
Planning Considerations
Capacity Planning: Add OSDs in increments that maintain balanced utilization
Network Bandwidth: Ensure sufficient network capacity for rebalancing
Timing: Perform scaling during maintenance windows when possible
Monitoring: Continuously monitor cluster health during expansion
Scaling Guidelines
MON Scaling: Always maintain odd numbers of MONs (3, 5, 7)
OSD Scaling: Add OSDs gradually to minimize rebalancing impact
Host Distribution: Distribute new OSDs across different hosts for fault tolerance
Weight Management: Set appropriate CRUSH weights based on disk capacity
Conclusion
In this lab, you have successfully learned how to scale a Ceph cluster by:

Adding MON Nodes: You expanded the Monitor quorum from 3 to 5 nodes, improving cluster resilience and availability. This ensures better fault tolerance and maintains cluster consensus even if multiple MONs fail.

Integrating OSD Nodes: You added 4 new OSD nodes with 8 additional storage devices, significantly increasing cluster storage capacity and performance. The new OSDs were properly integrated into the CRUSH hierarchy.

Managing Rebalancing: You monitored the automatic data rebalancing process that occurs when new OSDs join the cluster. This ensures optimal data distribution and maintains the desired replication levels.

Verifying Distribution: You confirmed that data is properly distributed across the expanded cluster, maintaining performance and reliability standards.

Why This Matters: Cluster scaling is a critical skill for storage administrators managing growing data requirements. The ability to seamlessly add capacity without service interruption is essential for production environments. Understanding the rebalancing process helps ensure optimal performance during and after expansion operations.

Key Takeaways:

Proper planning and gradual scaling minimize disruption
Monitoring during rebalancing ensures successful operations
Maintaining odd numbers of MONs preserves quorum integrity
CRUSH map management is crucial for optimal data placement
This knowledge prepares you for the Red Hat Certified Specialist in Ceph Cloud Storage exam and real-world Ceph cluster management scenarios.
