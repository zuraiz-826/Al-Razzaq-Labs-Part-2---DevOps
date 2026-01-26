Lab 8: Monitoring Ceph Cluster Health
Objectives
By the end of this lab, students will be able to:

Use essential Ceph monitoring commands to assess cluster health and status
Analyze Ceph logs to identify and troubleshoot OSD and MON issues
Configure health thresholds and alerts for proactive cluster monitoring
Interpret cluster health indicators and performance metrics
Implement monitoring best practices for production Ceph environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph architecture (OSDs, MONs, MGRs)
Familiarity with Linux command line operations
Knowledge of log file analysis techniques
Understanding of storage cluster concepts
Completion of previous Ceph installation and configuration labs
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph already installed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ceph monitor nodes
6 Ceph OSD nodes
1 Ceph manager node
Pre-configured Ceph cluster
Administrative access to all nodes
Task 1: Using Ceph Status and Health Commands
Subtask 1.1: Basic Cluster Health Assessment
First, let's examine the overall health of your Ceph cluster using fundamental monitoring commands.

Connect to the Ceph admin node:
# SSH is already configured in your lab environment
sudo ceph --version
Check basic cluster status:
# Display comprehensive cluster status
sudo ceph status

# Alternative short form
sudo ceph -s
Examine detailed health information:
# Show detailed health status
sudo ceph health detail

# Show only health summary
sudo ceph health
Analyze the output:
HEALTH_OK: Cluster is functioning normally
HEALTH_WARN: Non-critical issues present
HEALTH_ERR: Critical issues requiring immediate attention
Subtask 1.2: Monitoring Cluster Components
Check OSD status:
# List all OSDs and their status
sudo ceph osd status

# Show OSD tree structure
sudo ceph osd tree

# Display OSD utilization
sudo ceph osd df
Monitor MON status:
# Check monitor status
sudo ceph mon status

# Show monitor statistics
sudo ceph mon stat

# Display quorum status
sudo ceph quorum_status
Examine MGR status:
# Check manager daemon status
sudo ceph mgr stat

# List available MGR modules
sudo ceph mgr module ls
Subtask 1.3: Performance Monitoring
Monitor cluster performance:
# Show cluster I/O statistics
sudo ceph iostat

# Display pool statistics
sudo ceph df

# Show detailed pool information
sudo ceph df detail
Check placement group status:
# Display PG summary
sudo ceph pg stat

# Show detailed PG information
sudo ceph pg dump
Task 2: Analyzing Logs for OSD and MON Issues
Subtask 2.1: Locating and Accessing Ceph Logs
Identify log locations:
# Check Ceph configuration for log paths
sudo ceph config dump | grep log

# Common log locations
ls -la /var/log/ceph/
Examine cluster log:
# View recent cluster events
sudo ceph log last 50

# Monitor real-time cluster events
sudo ceph -w
Subtask 2.2: Analyzing OSD Logs
Identify OSD log files:
# List OSD log files
sudo ls -la /var/log/ceph/ceph-osd.*

# Check which OSDs are running on current node
sudo ps aux | grep ceph-osd
Analyze OSD logs for common issues:
# Check for OSD startup issues
sudo tail -100 /var/log/ceph/ceph-osd.0.log

# Search for error patterns
sudo grep -i "error\|fail\|warn" /var/log/ceph/ceph-osd.0.log | tail -20

# Look for slow operations
sudo grep "slow request" /var/log/ceph/ceph-osd.0.log
Monitor OSD performance issues:
# Check for heartbeat failures
sudo grep "heartbeat" /var/log/ceph/ceph-osd.0.log | tail -10

# Look for disk issues
sudo grep -i "disk\|io error" /var/log/ceph/ceph-osd.0.log
Subtask 2.3: Analyzing MON Logs
Examine monitor logs:
# View monitor log files
sudo ls -la /var/log/ceph/ceph-mon.*

# Check monitor log for issues
sudo tail -100 /var/log/ceph/ceph-mon.$(hostname).log
Identify common MON issues:
# Check for quorum issues
sudo grep -i "quorum\|election" /var/log/ceph/ceph-mon.$(hostname).log | tail -10

# Look for clock skew problems
sudo grep -i "clock skew" /var/log/ceph/ceph-mon.$(hostname).log

# Monitor store synchronization
sudo grep -i "sync\|paxos" /var/log/ceph/ceph-mon.$(hostname).log | tail -5
Subtask 2.4: Using Journalctl for Systemd Logs
Monitor Ceph services with journalctl:
# View OSD service logs
sudo journalctl -u ceph-osd@0 -f

# Check MON service logs
sudo journalctl -u ceph-mon@$(hostname) --since "1 hour ago"

# Monitor all Ceph services
sudo journalctl -u "ceph*" --since "30 minutes ago"
Task 3: Setting Up Health Thresholds for Alerts
Subtask 3.1: Understanding Ceph Health Checks
List available health checks:
# Show all health checks and their status
sudo ceph health detail

# List health check configuration
sudo ceph config dump | grep health
Examine current thresholds:
# Show OSD-related thresholds
sudo ceph config get mon mon_osd_full_ratio
sudo ceph config get mon mon_osd_nearfull_ratio
sudo ceph config get mon mon_osd_backfillfull_ratio
Subtask 3.2: Configuring Storage Thresholds
Set OSD utilization thresholds:
# Configure near-full threshold (85%)
sudo ceph config set mon mon_osd_nearfull_ratio 0.85

# Configure full threshold (95%)
sudo ceph config set mon mon_osd_full_ratio 0.95

# Configure backfill-full threshold (90%)
sudo ceph config set mon mon_osd_backfillfull_ratio 0.90
Verify threshold configuration:
# Check applied thresholds
sudo ceph osd dump | grep -E "full_ratio|nearfull_ratio"

# Test threshold alerts
sudo ceph health detail
Subtask 3.3: Configuring Performance Thresholds
Set slow operation thresholds:
# Configure slow request threshold (30 seconds)
sudo ceph config set osd osd_op_complaint_time 30

# Set slow heartbeat threshold
sudo ceph config set osd osd_heartbeat_grace 20
Configure PG-related thresholds:
# Set PG stuck threshold
sudo ceph config set mon mon_pg_stuck_threshold 300

# Configure degraded PG threshold
sudo ceph config set mon mon_pg_warn_max_per_osd 300
Subtask 3.4: Setting Up Basic Alerting
Create a monitoring script:
# Create monitoring directory
sudo mkdir -p /opt/ceph-monitoring

# Create basic health check script
sudo tee /opt/ceph-monitoring/health-check.sh << 'EOF'
#!/bin/bash

# Ceph Health Monitoring Script
LOG_FILE="/var/log/ceph-health-monitor.log"
EMAIL_ALERT="admin@example.com"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Check cluster health
HEALTH_STATUS=$(sudo ceph health)

if [[ $HEALTH_STATUS != "HEALTH_OK" ]]; then
    log_message "ALERT: Cluster health is $HEALTH_STATUS"
    
    # Get detailed health information
    HEALTH_DETAIL=$(sudo ceph health detail)
    log_message "Health Details: $HEALTH_DETAIL"
    
    # Optional: Send email alert (requires mail configuration)
    # echo "$HEALTH_DETAIL" | mail -s "Ceph Cluster Alert" $EMAIL_ALERT
    
    echo "ALERT: Ceph cluster health issue detected!"
    echo "$HEALTH_DETAIL"
else
    log_message "INFO: Cluster health is OK"
fi

# Check OSD utilization
OSD_USAGE=$(sudo ceph df | grep "TOTAL" | awk '{print $5}' | sed 's/%//')
if [[ $OSD_USAGE -gt 80 ]]; then
    log_message "WARNING: Cluster utilization is ${OSD_USAGE}%"
    echo "WARNING: High cluster utilization: ${OSD_USAGE}%"
fi
EOF

# Make script executable
sudo chmod +x /opt/ceph-monitoring/health-check.sh
Test the monitoring script:
# Run the script manually
sudo /opt/ceph-monitoring/health-check.sh

# Check the log file
sudo tail -10 /var/log/ceph-health-monitor.log
Set up automated monitoring with cron:
# Add cron job for regular health checks
sudo crontab -e

# Add this line to run every 5 minutes:
# */5 * * * * /opt/ceph-monitoring/health-check.sh
Subtask 3.5: Advanced Monitoring with Ceph Manager
Enable the alerts module:
# Enable alerts manager module
sudo ceph mgr module enable alerts

# Check enabled modules
sudo ceph mgr module ls | grep enabled
Configure dashboard for monitoring:
# Enable dashboard module
sudo ceph mgr module enable dashboard

# Create dashboard admin user
sudo ceph dashboard ac-user-create admin password administrator

# Check dashboard status
sudo ceph mgr services
Troubleshooting Common Issues
Issue 1: Cluster Shows HEALTH_WARN
Symptoms: Cluster status shows warnings

Solution:

# Get detailed warning information
sudo ceph health detail

# Common fixes for warnings:
# 1. For clock skew warnings
sudo ntpdate -s time.nist.gov

# 2. For too many PGs per OSD
sudo ceph osd pool set <pool-name> pg_num <new-value>
Issue 2: OSDs Marked as Down
Symptoms: OSDs showing as down in status

Solution:

# Check OSD status
sudo ceph osd tree

# Restart OSD service
sudo systemctl restart ceph-osd@<osd-id>

# Check OSD logs
sudo journalctl -u ceph-osd@<osd-id> -f
Issue 3: Monitor Quorum Issues
Symptoms: Monitor quorum problems

Solution:

# Check quorum status
sudo ceph quorum_status

# Restart monitor service
sudo systemctl restart ceph-mon@$(hostname)

# Check time synchronization
sudo chrony sources -v
Verification Steps
Verify cluster monitoring:
# Confirm cluster is healthy
sudo ceph status

# Check all thresholds are applied
sudo ceph config dump | grep -E "full_ratio|complaint_time"
Test alerting system:
# Run monitoring script
sudo /opt/ceph-monitoring/health-check.sh

# Verify log entries
sudo tail -5 /var/log/ceph-health-monitor.log
Validate log analysis skills:
# Generate a test log entry
sudo ceph log "Test log entry for monitoring lab"

# Verify it appears in cluster log
sudo ceph log last 5
Conclusion
In this comprehensive lab, you have successfully learned to monitor Ceph cluster health using essential tools and techniques. You accomplished the following key objectives:

What You Learned:

Cluster Health Assessment: Mastered using ceph status, ceph health, and related commands to evaluate cluster condition
Log Analysis: Developed skills to analyze OSD and MON logs for troubleshooting issues
Threshold Configuration: Set up appropriate health thresholds for storage utilization and performance monitoring
Automated Monitoring: Created monitoring scripts and configured basic alerting systems
Why This Matters: Effective monitoring is crucial for maintaining a healthy Ceph storage cluster in production environments. The skills you've developed enable you to:

Proactively identify issues before they impact users
Quickly diagnose and resolve storage problems
Maintain optimal cluster performance and availability
Meet enterprise storage reliability requirements
Next Steps: These monitoring fundamentals prepare you for advanced Ceph administration topics and are essential knowledge for the Red Hat Certified Specialist in Ceph Cloud Storage exam. Continue practicing these monitoring techniques in different scenarios to build expertise in production Ceph cluster management.

The monitoring capabilities you've implemented provide the foundation for maintaining robust, enterprise-grade Ceph storage infrastructure that can scale to meet demanding storage requirements while ensuring high availability and performance.
