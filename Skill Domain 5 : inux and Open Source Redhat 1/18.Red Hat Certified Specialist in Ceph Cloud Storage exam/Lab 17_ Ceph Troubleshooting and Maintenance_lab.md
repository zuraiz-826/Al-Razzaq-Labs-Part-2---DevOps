Lab 17: Ceph Troubleshooting and Maintenance
Objectives
By the end of this lab, students will be able to:

Diagnose and resolve common Ceph cluster issues using built-in diagnostic tools
Analyze Ceph logs to identify root causes of problems
Perform cluster rebalancing operations after node failures
Recover from OSD (Object Storage Daemon) failures
Recover from MON (Monitor) failures
Implement preventive maintenance procedures for Ceph clusters
Use Ceph health commands to monitor cluster status
Understand Ceph placement group states and troubleshoot PG issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph architecture (MONs, OSDs, MGRs)
Experience with Linux command line operations
Knowledge of storage concepts and RAID principles
Familiarity with systemd service management
Understanding of network troubleshooting basics
Completion of previous Ceph installation and configuration labs
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph already installed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ceph Monitor nodes (ceph-mon1, ceph-mon2, ceph-mon3)
6 Ceph OSD nodes (ceph-osd1 through ceph-osd6)
1 Ceph Admin node (ceph-admin)
Pre-configured Ceph cluster with intentional issues for troubleshooting
Task 1: Diagnose and Fix Common Ceph Issues
Subtask 1.1: Check Overall Cluster Health
First, let's examine the current state of our Ceph cluster and identify any issues.

Connect to the Ceph admin node:
ssh ceph-admin
Check the overall cluster status:
sudo ceph status
Get detailed health information:
sudo ceph health detail
Check cluster configuration:
sudo ceph config dump
Subtask 1.2: Analyze Placement Group Issues
Placement Groups (PGs) are fundamental to Ceph's data distribution. Let's diagnose PG-related problems.

Check PG status:
sudo ceph pg stat
List problematic PGs:
sudo ceph pg dump | grep -v "active+clean"
Get detailed information about stuck PGs:
sudo ceph pg dump_stuck
Fix stuck PGs by restarting the primary OSD:
# First, identify which OSD is primary for the stuck PG
sudo ceph pg map <pg_id>

# Restart the primary OSD (replace X with actual OSD number)
sudo systemctl restart ceph-osd@X
Subtask 1.3: Resolve Authentication Issues
Authentication problems are common in Ceph clusters. Let's diagnose and fix them.

Check authentication status:
sudo ceph auth list
Verify client authentication:
sudo ceph auth get client.admin
Fix missing authentication keys:
# Generate new client key if missing
sudo ceph auth get-or-create client.admin mon 'allow *' osd 'allow *' mds 'allow *' mgr 'allow *'

# Copy the key to the appropriate location
sudo ceph auth get client.admin -o /etc/ceph/ceph.client.admin.keyring
Set proper permissions:
sudo chmod 600 /etc/ceph/ceph.client.admin.keyring
sudo chown ceph:ceph /etc/ceph/ceph.client.admin.keyring
Subtask 1.4: Fix Network Connectivity Issues
Network problems can cause various Ceph issues. Let's diagnose and resolve them.

Check network connectivity between nodes:
# Test connectivity to all monitor nodes
for mon in ceph-mon1 ceph-mon2 ceph-mon3; do
    echo "Testing connectivity to $mon"
    ping -c 3 $mon
done
Verify Ceph network configuration:
sudo ceph config get mon public_network
sudo ceph config get mon cluster_network
Check port accessibility:
# Check if Ceph ports are accessible
nmap -p 6789,6800-7300 ceph-mon1
Fix firewall issues if needed:
# Open required Ceph ports
sudo firewall-cmd --permanent --add-port=6789/tcp
sudo firewall-cmd --permanent --add-port=6800-7300/tcp
sudo firewall-cmd --reload
Task 2: Rebalance the Cluster After Node Failures
Subtask 2.1: Simulate and Detect Node Failure
Let's simulate a node failure and learn how to handle it properly.

Check current cluster map:
sudo ceph osd tree
Simulate OSD failure by stopping an OSD service:
# Stop OSD.1 to simulate failure
sudo systemctl stop ceph-osd@1
Monitor the cluster response:
# Watch cluster status in real-time
watch -n 5 'ceph status'
Check the impact on data placement:
sudo ceph pg dump | grep -E "(degraded|misplaced|recovering)"
Subtask 2.2: Mark Failed OSD as Out
When an OSD fails permanently, we need to mark it as "out" to trigger rebalancing.

Mark the failed OSD as out:
sudo ceph osd out osd.1
Monitor the rebalancing process:
# Check rebalancing progress
sudo ceph status
sudo ceph pg stat
View data movement details:
sudo ceph osd df
Subtask 2.3: Control Rebalancing Speed
Rebalancing can impact cluster performance. Let's learn to control it.

Check current rebalancing settings:
sudo ceph config get osd osd_max_backfills
sudo ceph config get osd osd_recovery_max_active
Adjust rebalancing speed for business hours:
# Slow down rebalancing during business hours
sudo ceph config set osd osd_max_backfills 1
sudo ceph config set osd osd_recovery_max_active 1
sudo ceph config set osd osd_recovery_sleep 0.1
Speed up rebalancing during off-hours:
# Speed up rebalancing during maintenance windows
sudo ceph config set osd osd_max_backfills 4
sudo ceph config set osd osd_recovery_max_active 8
sudo ceph config set osd osd_recovery_sleep 0
Subtask 2.4: Add Replacement OSD
After removing a failed OSD, we need to add a replacement to maintain cluster capacity.

Prepare the replacement disk (on the target OSD node):
# SSH to the OSD node
ssh ceph-osd1

# Prepare the new disk (replace /dev/sdb with actual device)
sudo ceph-volume lvm prepare --data /dev/sdb
Activate the new OSD:
# Find the OSD ID from the prepare output
sudo ceph-volume lvm list

# Activate the OSD (replace the UUID with actual value)
sudo ceph-volume lvm activate <osd-id> <osd-uuid>
Verify the new OSD is added:
sudo ceph osd tree
sudo ceph osd stat
Task 3: Recover from OSD and MON Failures
Subtask 3.1: Recover from Complete OSD Failure
Sometimes an OSD fails completely and needs to be removed and replaced.

Identify the failed OSD:
sudo ceph osd tree | grep down
Stop the failed OSD service:
# On the OSD node
sudo systemctl stop ceph-osd@<osd-id>
sudo systemctl disable ceph-osd@<osd-id>
Remove the OSD from the cluster:
# Mark as out (if not already done)
sudo ceph osd out osd.<id>

# Remove from CRUSH map
sudo ceph osd crush remove osd.<id>

# Delete the OSD authentication key
sudo ceph auth del osd.<id>

# Remove the OSD from the cluster
sudo ceph osd rm osd.<id>
Clean up the OSD data:
# On the OSD node, remove the OSD data
sudo ceph-volume lvm zap /dev/<device> --destroy
Subtask 3.2: Recover from Monitor Failure
Monitor failures are critical as they affect cluster consensus. Let's learn to handle them.

Check monitor status:
sudo ceph mon stat
sudo ceph quorum_status
Simulate monitor failure:
# Stop a monitor service
ssh ceph-mon2
sudo systemctl stop ceph-mon@ceph-mon2
Verify cluster still has quorum:
sudo ceph mon stat
sudo ceph status
Recover the failed monitor:
# If the monitor can be restarted
ssh ceph-mon2
sudo systemctl start ceph-mon@ceph-mon2
sudo systemctl status ceph-mon@ceph-mon2
Subtask 3.3: Replace a Failed Monitor
If a monitor cannot be recovered, it needs to be replaced.

Remove the failed monitor from the cluster:
sudo ceph mon remove ceph-mon2
Prepare a new monitor node:
# On the new monitor node
sudo mkdir -p /var/lib/ceph/mon/ceph-new-mon
Create the new monitor:
# Get the monitor map
sudo ceph mon getmap -o /tmp/monmap

# Create the new monitor
sudo ceph-mon --mkfs -i new-mon --monmap /tmp/monmap --keyring /etc/ceph/ceph.client.admin.keyring
Add the new monitor to the cluster:
sudo ceph mon add new-mon <ip-address>:6789
Subtask 3.4: Handle Split-Brain Scenarios
Split-brain occurs when monitors lose quorum. Here's how to recover.

Identify the split-brain condition:
# Check if monitors can't reach consensus
sudo ceph mon stat
sudo ceph quorum_status --format json-pretty
Force a monitor to be the leader (emergency procedure):
# Stop all monitors first
for mon in ceph-mon1 ceph-mon2 ceph-mon3; do
    ssh $mon sudo systemctl stop ceph-mon@$mon
done

# Start one monitor in standalone mode
ssh ceph-mon1
sudo ceph-mon -i ceph-mon1 --public-addr <ip>:6789
Rebuild the monitor quorum:
# Extract the monitor map from the working monitor
sudo ceph mon getmap -o /tmp/monmap

# Start other monitors with the corrected map
for mon in ceph-mon2 ceph-mon3; do
    ssh $mon
    sudo ceph-mon --mkfs -i $mon --monmap /tmp/monmap --keyring /etc/ceph/ceph.client.admin.keyring
    sudo systemctl start ceph-mon@$mon
done
Advanced Troubleshooting Techniques
Log Analysis
Understanding Ceph logs is crucial for troubleshooting.

Check Ceph daemon logs:
# Monitor logs
sudo journalctl -u ceph-mon@ceph-mon1 -f

# OSD logs
sudo journalctl -u ceph-osd@1 -f

# Manager logs
sudo journalctl -u ceph-mgr@ceph-mgr1 -f
Increase log verbosity for debugging:
# Increase debug level for specific subsystem
sudo ceph config set osd debug_osd 20
sudo ceph config set mon debug_mon 20

# Reset to default after troubleshooting
sudo ceph config rm osd debug_osd
sudo ceph config rm mon debug_mon
Performance Troubleshooting
Check cluster performance metrics:
sudo ceph osd perf
sudo ceph osd df
Identify slow operations:
sudo ceph daemon osd.1 dump_ops_in_flight
sudo ceph daemon osd.1 dump_historic_ops
Monitor I/O patterns:
# Check pool statistics
sudo ceph osd pool stats
sudo rados df
Preventive Maintenance
Regular Health Checks
Create a script for regular health monitoring:

#!/bin/bash
# ceph-health-check.sh

echo "=== Ceph Cluster Health Check ==="
echo "Date: $(date)"
echo

echo "Cluster Status:"
ceph status
echo

echo "Health Details:"
ceph health detail
echo

echo "OSD Status:"
ceph osd stat
echo

echo "Monitor Status:"
ceph mon stat
echo

echo "Storage Usage:"
ceph df
echo

echo "=== End Health Check ==="
Automated Monitoring Setup
Create monitoring script:
sudo nano /usr/local/bin/ceph-monitor.sh
Add the script content:
#!/bin/bash
LOGFILE="/var/log/ceph-health.log"
ALERT_EMAIL="admin@company.com"

# Check cluster health
HEALTH=$(ceph health)

if [[ $HEALTH != "HEALTH_OK" ]]; then
    echo "$(date): ALERT - Ceph cluster health: $HEALTH" >> $LOGFILE
    echo "Ceph cluster health issue detected: $HEALTH" | mail -s "Ceph Alert" $ALERT_EMAIL
fi

# Log current status
echo "$(date): $HEALTH" >> $LOGFILE
Make script executable and schedule it:
sudo chmod +x /usr/local/bin/ceph-monitor.sh

# Add to crontab for every 5 minutes
echo "*/5 * * * * /usr/local/bin/ceph-monitor.sh" | sudo crontab -
Troubleshooting Common Issues
Issue 1: Clock Skew Problems
# Check time synchronization
sudo chrony sources -v

# Fix time sync issues
sudo systemctl restart chronyd
sudo chrony makestep
Issue 2: Disk Space Issues
# Check disk usage
sudo ceph df detail

# Clean up old logs if needed
sudo find /var/log/ceph -name "*.log" -mtime +30 -delete

# Increase monitor store size limit if needed
sudo ceph config set mon mon_data_size_warn 15000000000
Issue 3: Memory Issues
# Check OSD memory usage
sudo ceph daemon osd.1 config show | grep osd_memory

# Adjust OSD memory target
sudo ceph config set osd osd_memory_target 4294967296
Conclusion
In this comprehensive lab, you have learned essential Ceph troubleshooting and maintenance skills that are critical for managing production Ceph clusters. You have successfully:

Diagnosed common Ceph issues using built-in diagnostic tools and log analysis
Performed cluster rebalancing operations to maintain data distribution after node failures
Recovered from OSD failures by properly removing failed OSDs and adding replacements
Handled Monitor failures including split-brain scenarios and monitor replacement
Implemented preventive maintenance procedures to proactively monitor cluster health
These skills are essential for the Red Hat Certified Specialist in Ceph Cloud Storage exam and real-world Ceph administration. The ability to quickly diagnose and resolve issues ensures high availability and performance of your storage infrastructure.

Key takeaways:

Always check cluster health regularly using ceph status and ceph health detail
Monitor logs continuously during troubleshooting for root cause analysis
Control rebalancing speed to minimize impact on production workloads
Maintain proper quorum for monitors to ensure cluster consensus
Implement automated monitoring to catch issues before they become critical
The troubleshooting methodologies and recovery procedures you've practiced will help you maintain robust, reliable Ceph storage clusters in production environments.
