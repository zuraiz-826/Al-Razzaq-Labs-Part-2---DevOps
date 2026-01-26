Lab 13: Managing Cluster Health and Logs
Objectives
By the end of this lab, students will be able to:

Monitor Ceph cluster health using built-in diagnostic commands
Interpret cluster status information and health indicators
Analyze Ceph logs to identify and diagnose issues
Resolve common Ceph cluster problems using logs and alerts
Implement proactive monitoring strategies for Ceph clusters
Use advanced diagnostic tools for troubleshooting complex issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph storage architecture
Familiarity with Linux command line operations
Knowledge of storage concepts (OSDs, MONs, MGRs)
Experience with basic Ceph administration commands
Understanding of log file analysis techniques
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph cluster already deployed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Monitor nodes (ceph-mon-01, ceph-mon-02, ceph-mon-03)
6 OSD nodes with storage devices
2 Manager nodes
Pre-configured Ceph cluster in operational state
Task 1: Monitor Cluster Health Using Basic Commands
Subtask 1.1: Check Overall Cluster Status
First, let's examine the overall health of your Ceph cluster using the primary status command.

Connect to the Ceph monitor node:
ssh ceph-admin@ceph-mon-01
Check the basic cluster status:
sudo ceph status
Analyze the output. You should see information similar to:
cluster:
  id:     a7f64266-0894-4f1e-a635-d0aeaca0e993
  health: HEALTH_OK

services:
  mon: 3 daemons, quorum ceph-mon-01,ceph-mon-02,ceph-mon-03
  mgr: ceph-mgr-01(active), standbys: ceph-mgr-02
  osd: 6 osds: 6 up, 6 in

data:
  pools:   1 pools, 64 pgs
  objects: 0 objects, 0 B
  usage:   6.0 GiB used, 54 GiB / 60 GiB avail
  pgs:     64 active+clean
Document the key information:
Cluster ID: Unique identifier for your cluster
Health Status: Should be HEALTH_OK for a healthy cluster
Services: Number of monitors, managers, and OSDs
Data Usage: Storage utilization statistics
Subtask 1.2: Use Detailed Health Commands
Get detailed health information:
sudo ceph health detail
Check for any health warnings:
sudo ceph health
View cluster summary with more details:
sudo ceph -s
Check the cluster's data distribution:
sudo ceph df
Subtask 1.3: Monitor Individual Components
Check monitor status:
sudo ceph mon stat
sudo ceph mon dump
Check OSD status:
sudo ceph osd stat
sudo ceph osd tree
Check manager status:
sudo ceph mgr stat
sudo ceph mgr dump
View placement group status:
sudo ceph pg stat
sudo ceph pg dump summary
Task 2: Analyze Logs for Errors
Subtask 2.1: Locate and Access Ceph Log Files
Navigate to the Ceph log directory:
cd /var/log/ceph
ls -la
Identify the main log files:

ceph-mon logs: Monitor daemon logs
ceph-osd logs: OSD daemon logs
ceph-mgr logs: Manager daemon logs
ceph.log: Cluster-wide events log
Check the cluster log for recent events:

sudo tail -50 /var/log/ceph/ceph.log
Monitor real-time cluster events:
sudo tail -f /var/log/ceph/ceph.log
Subtask 2.2: Analyze Monitor Logs
Examine monitor logs for errors:
sudo grep -i error /var/log/ceph/ceph-mon.*.log
sudo grep -i warn /var/log/ceph/ceph-mon.*.log
Check for quorum issues:
sudo grep -i quorum /var/log/ceph/ceph-mon.*.log | tail -20
Look for clock synchronization problems:
sudo grep -i "clock skew" /var/log/ceph/ceph-mon.*.log
Check monitor election events:
sudo grep -i election /var/log/ceph/ceph-mon.*.log | tail -10
Subtask 2.3: Analyze OSD Logs
Check OSD logs for errors:
sudo grep -i error /var/log/ceph/ceph-osd.*.log
Look for disk-related issues:
sudo grep -i "disk\|device\|io error" /var/log/ceph/ceph-osd.*.log
Check for heartbeat failures:
sudo grep -i heartbeat /var/log/ceph/ceph-osd.*.log | tail -20
Examine specific OSD log:
sudo tail -100 /var/log/ceph/ceph-osd.0.log
Subtask 2.4: Use Centralized Logging Commands
View recent cluster events:
sudo ceph log last 50
Monitor live cluster events:
sudo ceph -w
Check for specific error patterns:
sudo ceph log last 100 | grep -i error
sudo ceph log last 100 | grep -i warn
Task 3: Resolve Common Ceph Issues
Subtask 3.1: Simulate and Resolve OSD Down Issue
Simulate an OSD failure by stopping an OSD:
sudo systemctl stop ceph-osd@0
Check cluster status to see the impact:
sudo ceph status
sudo ceph health detail
Analyze the logs for this issue:
sudo grep "osd.0" /var/log/ceph/ceph.log | tail -10
Resolve the issue by restarting the OSD:
sudo systemctl start ceph-osd@0
sudo systemctl status ceph-osd@0
Verify the resolution:
sudo ceph status
sudo ceph osd tree
Subtask 3.2: Handle Clock Skew Issues
Check current time synchronization:
sudo chrony sources -v
If clock skew is detected, synchronize time:
sudo chrony makestep
sudo systemctl restart chronyd
Verify time synchronization across nodes:
for node in ceph-mon-01 ceph-mon-02 ceph-mon-03; do
  echo "=== $node ==="
  ssh $node "date"
done
Check if clock skew warnings are resolved:
sudo ceph health detail
Subtask 3.3: Resolve Placement Group Issues
Check for stuck placement groups:
sudo ceph pg dump | grep -v "active+clean"
If you find stuck PGs, get detailed information:
sudo ceph pg 1.0 query
Force scrubbing on problematic PGs:
sudo ceph pg scrub 1.0
sudo ceph pg deep-scrub 1.0
Monitor PG recovery:
sudo ceph pg stat
sudo ceph -w
Subtask 3.4: Address Storage Space Issues
Check cluster storage utilization:
sudo ceph df
sudo ceph osd df
If storage is nearly full, identify large objects:
sudo rados df
Check for uneven data distribution:
sudo ceph osd utilization
Rebalance if necessary:
sudo ceph osd reweight-by-utilization
Subtask 3.5: Troubleshoot Network Connectivity Issues
Check network connectivity between nodes:
sudo ceph osd find 0
ping -c 3 <osd-host-ip>
Test Ceph network ports:
telnet <osd-host-ip> 6800
telnet <mon-host-ip> 6789
Check firewall settings:
sudo firewall-cmd --list-all
Verify Ceph network configuration:
sudo ceph config dump | grep network
Advanced Diagnostic Techniques
Subtask 4.1: Use Ceph Diagnostic Tools
Generate a cluster report:
sudo ceph report > cluster-report.json
Check daemon versions and compatibility:
sudo ceph versions
Examine cluster configuration:
sudo ceph config dump
sudo ceph config show mon
Use the Ceph daemon interface for detailed diagnostics:
sudo ceph daemon mon.ceph-mon-01 help
sudo ceph daemon mon.ceph-mon-01 status
Subtask 4.2: Implement Proactive Monitoring
Set up log rotation for Ceph logs:
sudo cat > /etc/logrotate.d/ceph << EOF
/var/log/ceph/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 ceph ceph
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF
Create a health monitoring script:
sudo cat > /usr/local/bin/ceph-health-check.sh << 'EOF'
#!/bin/bash
HEALTH=$(ceph health)
if [[ "$HEALTH" != "HEALTH_OK" ]]; then
    echo "$(date): Ceph cluster health issue detected: $HEALTH" >> /var/log/ceph-health-alerts.log
    ceph health detail >> /var/log/ceph-health-alerts.log
fi
EOF

sudo chmod +x /usr/local/bin/ceph-health-check.sh
Set up a cron job for regular health checks:
echo "*/5 * * * * /usr/local/bin/ceph-health-check.sh" | sudo crontab -
Test the monitoring script:
sudo /usr/local/bin/ceph-health-check.sh
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Cluster shows HEALTH_WARN

Cause: Various warnings like clock skew, near-full OSDs, or slow requests
Solution: Use ceph health detail to identify specific warnings and address them individually
Issue 2: OSDs frequently going down

Cause: Hardware issues, network problems, or resource constraints
Solution: Check hardware health, network connectivity, and system resources
Issue 3: Slow performance

Cause: Network latency, disk I/O issues, or unbalanced data distribution
Solution: Monitor network and disk performance, rebalance data if needed
Issue 4: Monitor quorum lost

Cause: Network partitions or monitor failures
Solution: Ensure network connectivity and restart failed monitors
Log Analysis Best Practices
Use grep effectively:
# Search for errors in the last hour
sudo grep "$(date -d '1 hour ago' '+%Y-%m-%d %H')" /var/log/ceph/ceph.log | grep -i error
Monitor specific time ranges:
# Check logs between specific times
sudo awk '/2024-01-15 10:00:00/,/2024-01-15 11:00:00/' /var/log/ceph/ceph.log
Use journalctl for systemd services:
sudo journalctl -u ceph-osd@0 --since "1 hour ago"
Verification and Testing
Final Health Check
Perform comprehensive cluster verification:
sudo ceph status
sudo ceph health detail
sudo ceph df
sudo ceph osd tree
Verify all services are running:
sudo systemctl status ceph-mon@$(hostname)
sudo systemctl status ceph-mgr@$(hostname)
Test cluster functionality:
# Create a test pool and object
sudo ceph osd pool create test-pool 32 32
echo "test data" | sudo rados put test-object - --pool=test-pool
sudo rados get test-object - --pool=test-pool
sudo ceph osd pool delete test-pool test-pool --yes-i-really-really-mean-it
Conclusion
In this comprehensive lab, you have successfully learned how to monitor and troubleshoot Ceph cluster health using various diagnostic tools and log analysis techniques. You have gained hands-on experience with:

Cluster Monitoring: Using ceph status, ceph health, and related commands to assess cluster health
Log Analysis: Examining Ceph logs to identify errors, warnings, and performance issues
Issue Resolution: Resolving common Ceph problems including OSD failures, clock skew, and placement group issues
Proactive Monitoring: Implementing monitoring scripts and log management practices
Advanced Diagnostics: Using specialized Ceph diagnostic tools for complex troubleshooting
These skills are essential for maintaining a healthy Ceph storage cluster in production environments. Regular monitoring and proactive log analysis help prevent minor issues from becoming major problems, ensuring high availability and performance of your storage infrastructure.

The techniques you've learned in this lab form the foundation for advanced Ceph administration and are crucial for anyone working with Ceph storage systems in enterprise environments. Continue practicing these skills and stay updated with Ceph documentation for the latest troubleshooting techniques and best practices.
