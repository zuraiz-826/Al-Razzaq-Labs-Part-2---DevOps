Lab 19: Troubleshooting Ceph Cluster Issues
Objectives
By the end of this lab, students will be able to:

Identify and diagnose common Ceph cluster issues using built-in diagnostic tools
Troubleshoot and resolve failed OSD (Object Storage Daemon) problems
Diagnose and fix monitor quorum issues that affect cluster availability
Perform data rebalancing operations to optimize cluster performance
Analyze cluster logs to identify and resolve various error conditions
Implement preventive measures to maintain cluster health
Use Ceph management commands to monitor and maintain cluster stability
Prerequisites
Before starting this lab, students should have:

Basic understanding of distributed storage systems concepts
Familiarity with Linux command-line operations
Knowledge of Ceph architecture including OSDs, MONs, and MGRs
Experience with basic Ceph administration commands
Understanding of CRUSH maps and placement groups
Basic networking knowledge for cluster communication troubleshooting
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph cluster already installed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Monitor nodes (ceph-mon-01, ceph-mon-02, ceph-mon-03)
6 OSD nodes with multiple disks each
1 Admin node for cluster management
Pre-configured network connectivity between all nodes
Task 1: Identify and Fix Failed OSDs
Subtask 1.1: Check Overall Cluster Health
First, let's examine the current state of our Ceph cluster to identify any issues.

Connect to the admin node and check cluster status:
# Check overall cluster health
sudo ceph health

# Get detailed health information
sudo ceph health detail

# Check cluster status summary
sudo ceph status
Examine OSD status specifically:
# List all OSDs and their current state
sudo ceph osd stat

# Get detailed OSD information
sudo ceph osd tree

# Check for any down or out OSDs
sudo ceph osd ls
Subtask 1.2: Identify Failed OSDs
Look for problematic OSDs:
# Check which OSDs are down
sudo ceph osd tree | grep down

# Check which OSDs are out of the cluster
sudo ceph osd tree | grep out

# Get detailed information about specific OSD issues
sudo ceph osd dump | grep -E "(down|out)"
Examine OSD logs for failure reasons:
# Check logs for a specific failed OSD (replace X with actual OSD number)
sudo journalctl -u ceph-osd@X -n 50

# Check for common error patterns
sudo journalctl -u ceph-osd@X | grep -i error
Subtask 1.3: Diagnose OSD Failure Causes
Check disk health and filesystem issues:
# Check disk health for OSD data directory
sudo df -h /var/lib/ceph/osd/

# Check for filesystem errors
sudo dmesg | grep -i error

# Verify disk health using smartctl
sudo smartctl -a /dev/sdX  # Replace X with actual disk identifier
Check OSD authentication and permissions:
# Verify OSD keyring exists and has correct permissions
sudo ls -la /var/lib/ceph/osd/ceph-*/keyring

# Check OSD configuration
sudo ceph daemon osd.X config show | grep -i auth
Subtask 1.4: Fix Failed OSDs
Restart failed OSD services:
# Restart a specific OSD service
sudo systemctl restart ceph-osd@X

# Check if the service started successfully
sudo systemctl status ceph-osd@X

# Verify OSD is back in the cluster
sudo ceph osd tree
If restart doesn't work, recreate the OSD:
# First, remove the failed OSD from the cluster
sudo ceph osd out X
sudo ceph osd crush remove osd.X
sudo ceph auth del osd.X
sudo ceph osd rm X

# Recreate the OSD (replace /dev/sdX with actual device)
sudo ceph-volume lvm create --data /dev/sdX --osd-id X

# Verify the new OSD is working
sudo ceph osd tree
sudo ceph health
Task 2: Resolve Monitor Quorum Issues
Subtask 2.1: Identify Monitor Problems
Check monitor status and quorum:
# Check monitor quorum status
sudo ceph quorum_status

# Get detailed monitor information
sudo ceph mon stat

# List all monitors and their status
sudo ceph mon dump
Examine monitor logs for issues:
# Check monitor logs on each monitor node
sudo journalctl -u ceph-mon@$(hostname) -n 100

# Look for specific error patterns
sudo journalctl -u ceph-mon@$(hostname) | grep -i -E "(error|failed|timeout)"
Subtask 2.2: Diagnose Monitor Communication Issues
Test network connectivity between monitors:
# Test connectivity to other monitor nodes
ping -c 3 ceph-mon-02
ping -c 3 ceph-mon-03

# Check if monitor ports are accessible
telnet ceph-mon-02 6789
telnet ceph-mon-03 6789
Verify monitor configuration:
# Check monitor configuration
sudo ceph daemon mon.$(hostname) config show | grep -i mon

# Verify monitor addresses
sudo ceph mon dump | grep addr
Subtask 2.3: Fix Monitor Quorum Issues
Restart problematic monitors:
# Restart monitor service on the current node
sudo systemctl restart ceph-mon@$(hostname)

# Check service status
sudo systemctl status ceph-mon@$(hostname)

# Verify monitor rejoined quorum
sudo ceph quorum_status
If a monitor is completely failed, remove and re-add it:
# Remove failed monitor from cluster (run from working monitor)
sudo ceph mon remove mon-failed-name

# Add monitor back to cluster
sudo ceph mon add mon-failed-name 192.168.1.X:6789

# Verify monitor is back in quorum
sudo ceph mon stat
Subtask 2.4: Handle Split-Brain Scenarios
In case of monitor split-brain, force quorum:
# CAUTION: Only use in emergency situations
# Force quorum with available monitors
sudo ceph mon force_create_pg

# Restart all monitor services
sudo systemctl restart ceph-mon.target

# Verify cluster recovery
sudo ceph health
Task 3: Perform Data Rebalancing and Monitor Cluster Logs
Subtask 3.1: Assess Data Distribution
Check current data distribution:
# Check placement group distribution
sudo ceph pg dump | grep -E "^pg_stat"

# Check OSD utilization
sudo ceph osd df

# Identify imbalanced OSDs
sudo ceph osd df tree
Examine CRUSH map for potential issues:
# Get current CRUSH map
sudo ceph osd getcrushmap -o crushmap.bin
sudo crushtool -d crushmap.bin -o crushmap.txt
sudo cat crushmap.txt

# Check CRUSH rule configuration
sudo ceph osd crush rule dump
Subtask 3.2: Identify Rebalancing Needs
Calculate data imbalance:
# Check for OSDs with significantly different utilization
sudo ceph osd df | awk '{print $1, $7}' | sort -k2 -n

# Check for placement group imbalances
sudo ceph pg ls-by-osd osd.X | wc -l  # Replace X with OSD number
Check for stuck placement groups:
# Look for stuck PGs
sudo ceph pg dump | grep -E "(stuck|inactive|unclean)"

# Get detailed information about problematic PGs
sudo ceph pg X.Y query  # Replace X.Y with actual PG ID
Subtask 3.3: Perform Data Rebalancing
Adjust OSD weights for rebalancing:
# Check current OSD weights
sudo ceph osd tree | grep -E "osd\."

# Gradually adjust weight of overutilized OSD
sudo ceph osd reweight osd.X 0.8  # Reduce weight to 80%

# Monitor rebalancing progress
sudo ceph -w
Use reweight-by-utilization for automatic balancing:
# Automatically reweight OSDs based on utilization
sudo ceph osd reweight-by-utilization 110

# Monitor the rebalancing process
sudo ceph health
sudo ceph osd df
Subtask 3.4: Monitor Rebalancing Progress
Track data movement and cluster performance:
# Monitor ongoing data movement
sudo ceph status

# Watch placement group states
sudo ceph pg stat

# Monitor cluster performance during rebalancing
sudo ceph osd perf
Set rebalancing throttles to control impact:
# Limit recovery operations to reduce impact
sudo ceph tell 'osd.*' injectargs '--osd-max-backfills 1'
sudo ceph tell 'osd.*' injectargs '--osd-recovery-max-active 1'

# Monitor recovery progress
sudo ceph -s
Subtask 3.5: Comprehensive Log Analysis
Set up centralized log monitoring:
# Create log monitoring script
cat << 'EOF' > /tmp/ceph_log_monitor.sh
#!/bin/bash
echo "=== Ceph Cluster Health ==="
ceph health detail

echo -e "\n=== Recent OSD Errors ==="
journalctl -u 'ceph-osd@*' --since "1 hour ago" | grep -i error | tail -10

echo -e "\n=== Recent Monitor Errors ==="
journalctl -u 'ceph-mon@*' --since "1 hour ago" | grep -i error | tail -10

echo -e "\n=== Recent MGR Errors ==="
journalctl -u 'ceph-mgr@*' --since "1 hour ago" | grep -i error | tail -10

echo -e "\n=== Placement Group Issues ==="
ceph pg dump | grep -E "(stuck|inactive|unclean)" | head -5
EOF

chmod +x /tmp/ceph_log_monitor.sh
sudo /tmp/ceph_log_monitor.sh
Analyze specific error patterns:
# Look for common error patterns across all services
sudo journalctl -u 'ceph-*' --since "24 hours ago" | grep -i -E "(slow request|heartbeat|timeout)" | head -20

# Check for network-related issues
sudo journalctl -u 'ceph-*' --since "24 hours ago" | grep -i -E "(connection|network|unreachable)" | head -10

# Monitor authentication issues
sudo journalctl -u 'ceph-*' --since "24 hours ago" | grep -i -E "(auth|permission|denied)" | head -10
Subtask 3.6: Implement Preventive Monitoring
Set up automated health checks:
# Create health check script for regular monitoring
cat << 'EOF' > /tmp/ceph_health_check.sh
#!/bin/bash
LOGFILE="/var/log/ceph_health_check.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting health check" >> $LOGFILE

# Check overall health
HEALTH=$(ceph health)
echo "[$DATE] Health: $HEALTH" >> $LOGFILE

# Check for down OSDs
DOWN_OSDS=$(ceph osd tree | grep down | wc -l)
if [ $DOWN_OSDS -gt 0 ]; then
    echo "[$DATE] WARNING: $DOWN_OSDS OSDs are down" >> $LOGFILE
fi

# Check monitor quorum
QUORUM_SIZE=$(ceph quorum_status | jq '.quorum | length')
if [ $QUORUM_SIZE -lt 2 ]; then
    echo "[$DATE] CRITICAL: Monitor quorum size is $QUORUM_SIZE" >> $LOGFILE
fi

# Check data balance
MAX_UTIL=$(ceph osd df | awk 'NR>1 {print $7}' | sed 's/%//' | sort -n | tail -1)
if [ $MAX_UTIL -gt 85 ]; then
    echo "[$DATE] WARNING: Highest OSD utilization is ${MAX_UTIL}%" >> $LOGFILE
fi

echo "[$DATE] Health check completed" >> $LOGFILE
EOF

chmod +x /tmp/ceph_health_check.sh
sudo /tmp/ceph_health_check.sh
Verify cluster stability after troubleshooting:
# Final comprehensive health check
sudo ceph health detail
sudo ceph status
sudo ceph osd stat
sudo ceph mon stat
sudo ceph pg stat

# Check that all services are running properly
sudo systemctl status ceph.target
Troubleshooting Tips and Common Issues
Common OSD Issues and Solutions
Issue: OSD fails to start after reboot Solution: Check filesystem integrity and permissions on OSD data directory

Issue: OSD shows as "down" but process is running Solution: Check network connectivity and authentication keys

Issue: OSD constantly flapping (up/down) Solution: Investigate disk health and increase heartbeat timeouts

Common Monitor Issues and Solutions
Issue: Monitor cannot join quorum Solution: Verify network connectivity and time synchronization between nodes

Issue: Split-brain scenario with monitors Solution: Ensure odd number of monitors and proper network configuration

Issue: Monitor database corruption Solution: Remove corrupted monitor and re-add with fresh database

Common Rebalancing Issues and Solutions
Issue: Rebalancing is too slow Solution: Increase recovery and backfill limits within reasonable bounds

Issue: Rebalancing causes performance degradation Solution: Implement throttling and schedule rebalancing during off-peak hours

Issue: Data remains imbalanced after reweighting Solution: Check CRUSH map configuration and consider manual PG redistribution

Conclusion
In this comprehensive lab, you have successfully learned to troubleshoot critical Ceph cluster issues that commonly occur in production environments. You have gained hands-on experience in:

Diagnosing and resolving OSD failures by identifying root causes, restarting services, and recreating failed OSDs when necessary
Fixing monitor quorum issues by understanding quorum mechanics, resolving network connectivity problems, and handling split-brain scenarios
Performing data rebalancing operations to optimize cluster performance and ensure even data distribution across OSDs
Implementing comprehensive log monitoring to proactively identify and resolve issues before they impact cluster availability
These troubleshooting skills are essential for maintaining healthy Ceph storage clusters in production environments. The ability to quickly identify, diagnose, and resolve these common issues ensures high availability and optimal performance of your distributed storage infrastructure.

The preventive monitoring techniques you've implemented will help you catch issues early, reducing downtime and maintaining consistent cluster performance. Remember that regular health checks, proper monitoring, and understanding your cluster's normal behavior patterns are key to successful Ceph cluster administration.

This knowledge directly applies to Red Hat Ceph Storage environments and prepares you for real-world scenarios where quick problem resolution is critical for business continuity.
