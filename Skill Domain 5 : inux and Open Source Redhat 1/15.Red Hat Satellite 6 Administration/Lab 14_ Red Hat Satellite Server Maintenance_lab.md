Lab 14: Red Hat Satellite Server Maintenance
Objectives
By the end of this lab, students will be able to:

Apply security patches to Red Hat Satellite server using best practices
Configure and schedule automated backup procedures for Satellite data
Monitor Satellite server performance and resource utilization
Implement proactive maintenance strategies for optimal Satellite operations
Troubleshoot common maintenance-related issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with Red Hat Satellite 6 architecture and components
Knowledge of command-line operations and text editors
Understanding of backup and recovery concepts
Basic knowledge of system monitoring principles
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Red Hat Satellite 6 already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

Red Hat Enterprise Linux 8 server with Satellite 6.12 installed
Pre-configured Satellite organization and location
Sample managed hosts for testing
Monitoring tools and utilities
Task 1: Apply Security Patches to Satellite Server
Security patching is critical for maintaining a secure and stable Satellite environment. This task covers the proper procedure for applying updates.

Subtask 1.1: Pre-Patch Assessment
Before applying any patches, assess the current system state and plan the maintenance window.

Check current Satellite version and status:
# Check Satellite version
satellite-maintain service status

# Verify Satellite health
foreman-maintain health check
Review available updates:
# Check for available updates
sudo yum check-update

# List security updates specifically
sudo yum --security check-update
Create a pre-patch system snapshot:
# Create backup before patching
sudo foreman-maintain backup snapshot /var/backup/pre-patch-$(date +%Y%m%d)
Subtask 1.2: Apply Security Patches
Follow the recommended procedure for patching Satellite servers.

Put Satellite in maintenance mode:
# Stop Satellite services gracefully
sudo foreman-maintain service stop

# Verify services are stopped
sudo foreman-maintain service status
Apply security updates:
# Apply only security updates
sudo yum update --security -y

# For comprehensive updates (if approved)
sudo yum update -y
Update Satellite-specific packages:
# Update Satellite packages
sudo yum update satellite* -y

# Update Foreman packages
sudo yum update foreman* -y
Subtask 1.3: Post-Patch Verification
Verify that the system is functioning correctly after patching.

Restart Satellite services:
# Start Satellite services
sudo foreman-maintain service start

# Verify all services are running
sudo foreman-maintain service status
Perform health checks:
# Run comprehensive health check
foreman-maintain health check

# Check database integrity
foreman-maintain health check --label db-up
Verify web interface accessibility:
# Test web interface connectivity
curl -k https://$(hostname)/users/login

# Check API functionality
hammer ping
Task 2: Schedule and Configure Regular Backups
Regular backups are essential for disaster recovery and business continuity.

Subtask 2.1: Configure Full System Backup
Set up comprehensive backup procedures for Satellite data.

Create backup directory structure:
# Create backup directories
sudo mkdir -p /var/satellite-backups/{daily,weekly,monthly}
sudo chown foreman:foreman /var/satellite-backups -R
sudo chmod 755 /var/satellite-backups -R
Create backup script:
# Create backup script
sudo tee /usr/local/bin/satellite-backup.sh << 'EOF'
#!/bin/bash

# Satellite Backup Script
BACKUP_BASE="/var/satellite-backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_TYPE=$1

case $BACKUP_TYPE in
    "daily")
        BACKUP_DIR="$BACKUP_BASE/daily/satellite-backup-$DATE"
        RETENTION_DAYS=7
        ;;
    "weekly")
        BACKUP_DIR="$BACKUP_BASE/weekly/satellite-backup-$DATE"
        RETENTION_DAYS=30
        ;;
    "monthly")
        BACKUP_DIR="$BACKUP_BASE/monthly/satellite-backup-$DATE"
        RETENTION_DAYS=365
        ;;
    *)
        echo "Usage: $0 {daily|weekly|monthly}"
        exit 1
        ;;
esac

# Create backup
echo "Starting $BACKUP_TYPE backup at $(date)"
foreman-maintain backup offline --assumeyes $BACKUP_DIR

# Compress backup
if [ $? -eq 0 ]; then
    echo "Compressing backup..."
    tar -czf "${BACKUP_DIR}.tar.gz" -C $(dirname $BACKUP_DIR) $(basename $BACKUP_DIR)
    rm -rf $BACKUP_DIR
    echo "Backup completed: ${BACKUP_DIR}.tar.gz"
else
    echo "Backup failed!"
    exit 1
fi

# Clean old backups
find $(dirname $BACKUP_DIR) -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "$BACKUP_TYPE backup completed at $(date)"
EOF

# Make script executable
sudo chmod +x /usr/local/bin/satellite-backup.sh
Subtask 2.2: Schedule Automated Backups
Configure cron jobs for automated backup execution.

Create cron jobs for different backup schedules:
# Edit crontab for foreman user
sudo crontab -u foreman -e

# Add the following lines to the crontab:
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/satellite-backup.sh daily >> /var/log/satellite-backup.log 2>&1

# Weekly backup on Sunday at 3 AM
0 3 * * 0 /usr/local/bin/satellite-backup.sh weekly >> /var/log/satellite-backup.log 2>&1

# Monthly backup on 1st day at 4 AM
0 4 1 * * /usr/local/bin/satellite-backup.sh monthly >> /var/log/satellite-backup.log 2>&1
Create backup monitoring script:
# Create backup monitoring script
sudo tee /usr/local/bin/backup-monitor.sh << 'EOF'
#!/bin/bash

# Backup Monitoring Script
LOG_FILE="/var/log/satellite-backup.log"
ALERT_EMAIL="admin@company.com"

# Check if backup completed successfully today
TODAY=$(date +%Y%m%d)
if ! grep -q "backup completed at.*$TODAY" $LOG_FILE; then
    echo "WARNING: No successful backup found for today ($TODAY)" | \
    mail -s "Satellite Backup Alert" $ALERT_EMAIL
fi

# Check backup file sizes
BACKUP_DIRS=("/var/satellite-backups/daily" "/var/satellite-backups/weekly" "/var/satellite-backups/monthly")

for dir in "${BACKUP_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        LATEST_BACKUP=$(ls -t $dir/*.tar.gz 2>/dev/null | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            SIZE=$(du -h "$LATEST_BACKUP" | cut -f1)
            echo "Latest backup in $dir: $(basename $LATEST_BACKUP) - Size: $SIZE"
        fi
    fi
done
EOF

sudo chmod +x /usr/local/bin/backup-monitor.sh
Subtask 2.3: Test Backup and Restore Procedures
Verify that backups can be successfully restored.

Test backup creation:
# Run a test backup
sudo /usr/local/bin/satellite-backup.sh daily

# Verify backup was created
ls -la /var/satellite-backups/daily/
Test backup restoration (on test system):
# Extract backup for testing
cd /tmp
sudo tar -xzf /var/satellite-backups/daily/satellite-backup-*.tar.gz

# Test restore command (DO NOT run on production)
# foreman-maintain restore /tmp/satellite-backup-*
echo "Restore test command prepared (not executed on production)"
Task 3: Monitor Satellite Server Performance and Resources
Continuous monitoring ensures optimal performance and early detection of issues.

Subtask 3.1: Set Up System Resource Monitoring
Configure monitoring for CPU, memory, disk, and network resources.

Install monitoring tools:
# Install system monitoring packages
sudo yum install -y htop iotop nethogs sysstat

# Enable and start sysstat service
sudo systemctl enable sysstat
sudo systemctl start sysstat
Create system monitoring script:
# Create comprehensive monitoring script
sudo tee /usr/local/bin/satellite-monitor.sh << 'EOF'
#!/bin/bash

# Satellite System Monitoring Script
REPORT_FILE="/var/log/satellite-monitor-$(date +%Y%m%d).log"
THRESHOLD_CPU=80
THRESHOLD_MEMORY=85
THRESHOLD_DISK=90

echo "=== Satellite System Monitor Report - $(date) ===" >> $REPORT_FILE

# CPU Usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
echo "CPU Usage: ${CPU_USAGE}%" >> $REPORT_FILE

# Memory Usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.1f", ($3/$2) * 100.0)}')
echo "Memory Usage: ${MEMORY_USAGE}%" >> $REPORT_FILE

# Disk Usage
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
echo "Root Disk Usage: ${DISK_USAGE}%" >> $REPORT_FILE

# Satellite-specific disk usage
SATELLITE_DISK=$(df -h /var/lib/pulp | awk 'NR==2 {print $5}' | cut -d'%' -f1)
echo "Satellite Content Disk Usage: ${SATELLITE_DISK}%" >> $REPORT_FILE

# Database connections
DB_CONNECTIONS=$(sudo -u postgres psql -d foreman -c "SELECT count(*) FROM pg_stat_activity;" -t | xargs)
echo "Database Connections: $DB_CONNECTIONS" >> $REPORT_FILE

# Satellite service status
echo "=== Service Status ===" >> $REPORT_FILE
foreman-maintain service status >> $REPORT_FILE 2>&1

# Check for alerts
if (( $(echo "$CPU_USAGE > $THRESHOLD_CPU" | bc -l) )); then
    echo "ALERT: High CPU usage detected: ${CPU_USAGE}%" >> $REPORT_FILE
fi

if (( $(echo "$MEMORY_USAGE > $THRESHOLD_MEMORY" | bc -l) )); then
    echo "ALERT: High memory usage detected: ${MEMORY_USAGE}%" >> $REPORT_FILE
fi

if [ "$DISK_USAGE" -gt "$THRESHOLD_DISK" ]; then
    echo "ALERT: High disk usage detected: ${DISK_USAGE}%" >> $REPORT_FILE
fi

echo "=== End Report ===" >> $REPORT_FILE
echo "" >> $REPORT_FILE
EOF

sudo chmod +x /usr/local/bin/satellite-monitor.sh
Subtask 3.2: Configure Satellite-Specific Monitoring
Monitor Satellite-specific metrics and performance indicators.

Create Satellite performance monitoring script:
# Create Satellite-specific monitoring script
sudo tee /usr/local/bin/satellite-perf-monitor.sh << 'EOF'
#!/bin/bash

# Satellite Performance Monitoring Script
PERF_LOG="/var/log/satellite-performance-$(date +%Y%m%d).log"

echo "=== Satellite Performance Report - $(date) ===" >> $PERF_LOG

# Foreman tasks status
echo "=== Foreman Tasks Status ===" >> $PERF_LOG
hammer task list --search "state=running" >> $PERF_LOG 2>&1

# Content view publish status
echo "=== Recent Content View Activities ===" >> $PERF_LOG
hammer task list --search "label~content_view" --per-page 10 >> $PERF_LOG 2>&1

# Sync status
echo "=== Repository Sync Status ===" >> $PERF_LOG
hammer repository list --fields "Name,Product,Last sync" >> $PERF_LOG 2>&1

# Host registration statistics
echo "=== Host Statistics ===" >> $PERF_LOG
hammer host list --per-page 1 | head -1 >> $PERF_LOG 2>&1

# Capsule status (if any)
echo "=== Capsule Status ===" >> $PERF_LOG
hammer capsule list --fields "Name,Features" >> $PERF_LOG 2>&1

# Database size
echo "=== Database Size Information ===" >> $PERF_LOG
sudo -u postgres psql -d foreman -c "SELECT pg_size_pretty(pg_database_size('foreman')) AS foreman_db_size;" >> $PERF_LOG 2>&1

echo "=== End Performance Report ===" >> $PERF_LOG
echo "" >> $PERF_LOG
EOF

sudo chmod +x /usr/local/bin/satellite-perf-monitor.sh
Schedule monitoring scripts:
# Add monitoring scripts to crontab
sudo crontab -e

# Add these lines to run monitoring every 15 minutes
*/15 * * * * /usr/local/bin/satellite-monitor.sh
0 */4 * * * /usr/local/bin/satellite-perf-monitor.sh
Subtask 3.3: Set Up Log Monitoring and Alerting
Configure log monitoring for proactive issue detection.

Create log monitoring script:
# Create log monitoring script
sudo tee /usr/local/bin/satellite-log-monitor.sh << 'EOF'
#!/bin/bash

# Satellite Log Monitoring Script
LOG_ALERT_FILE="/var/log/satellite-alerts-$(date +%Y%m%d).log"
SATELLITE_LOGS=("/var/log/foreman/production.log" "/var/log/httpd/error_log" "/var/log/messages")

echo "=== Satellite Log Alert Report - $(date) ===" >> $LOG_ALERT_FILE

# Check for errors in the last hour
for log_file in "${SATELLITE_LOGS[@]}"; do
    if [ -f "$log_file" ]; then
        echo "=== Checking $log_file ===" >> $LOG_ALERT_FILE
        
        # Look for ERROR, FATAL, or CRITICAL messages in the last hour
        ERRORS=$(find "$log_file" -newermt "1 hour ago" -exec grep -i "error\|fatal\|critical" {} \; 2>/dev/null | wc -l)
        
        if [ "$ERRORS" -gt 0 ]; then
            echo "Found $ERRORS error(s) in $log_file in the last hour" >> $LOG_ALERT_FILE
            find "$log_file" -newermt "1 hour ago" -exec grep -i "error\|fatal\|critical" {} \; 2>/dev/null | tail -5 >> $LOG_ALERT_FILE
        else
            echo "No critical errors found in $log_file" >> $LOG_ALERT_FILE
        fi
        echo "" >> $LOG_ALERT_FILE
    fi
done

# Check disk space for log directories
echo "=== Log Directory Disk Usage ===" >> $LOG_ALERT_FILE
du -sh /var/log/foreman/ /var/log/httpd/ >> $LOG_ALERT_FILE 2>&1

echo "=== End Log Alert Report ===" >> $LOG_ALERT_FILE
echo "" >> $LOG_ALERT_FILE
EOF

sudo chmod +x /usr/local/bin/satellite-log-monitor.sh
Create maintenance dashboard script:
# Create maintenance dashboard
sudo tee /usr/local/bin/satellite-dashboard.sh << 'EOF'
#!/bin/bash

# Satellite Maintenance Dashboard
clear
echo "========================================"
echo "    SATELLITE MAINTENANCE DASHBOARD"
echo "========================================"
echo "Generated: $(date)"
echo ""

# System Information
echo "=== SYSTEM INFORMATION ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime | cut -d',' -f1 | cut -d' ' -f4-)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Satellite Version
echo "=== SATELLITE VERSION ==="
rpm -q satellite 2>/dev/null || echo "Satellite package info not available"
echo ""

# Service Status
echo "=== SERVICE STATUS ==="
foreman-maintain service status | grep -E "(running|stopped)"
echo ""

# Resource Usage
echo "=== RESOURCE USAGE ==="
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"
echo "Memory: $(free -h | grep Mem | awk '{print "Used: " $3 " / Total: " $2}')"
echo "Disk (Root): $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}')"
echo "Disk (Satellite): $(df -h /var/lib/pulp 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}' || echo "N/A")"
echo ""

# Recent Backups
echo "=== RECENT BACKUPS ==="
if [ -d "/var/satellite-backups" ]; then
    find /var/satellite-backups -name "*.tar.gz" -mtime -7 -exec ls -lh {} \; | tail -3
else
    echo "No backup directory found"
fi
echo ""

# Active Tasks
echo "=== ACTIVE TASKS ==="
hammer task list --search "state=running" --fields "Id,Action,State" 2>/dev/null | head -5 || echo "Unable to retrieve task information"
echo ""

echo "========================================"
EOF

sudo chmod +x /usr/local/bin/satellite-dashboard.sh
Troubleshooting Common Issues
Issue 1: Service Start Failures After Patching
Symptoms: Services fail to start after applying patches

Solution:

# Check service dependencies
sudo foreman-maintain service status --details

# Restart services in correct order
sudo foreman-maintain service restart

# Check for configuration issues
sudo foreman-maintain health check
Issue 2: Backup Failures
Symptoms: Backup scripts report errors or incomplete backups

Solution:

# Check disk space
df -h /var/satellite-backups

# Verify permissions
ls -la /var/satellite-backups

# Run backup with verbose output
foreman-maintain backup offline --assumeyes /tmp/test-backup --verbose
Issue 3: High Resource Usage
Symptoms: System performance degradation, high CPU or memory usage

Solution:

# Identify resource-intensive processes
top -p $(pgrep -d',' -f foreman)

# Check for stuck tasks
hammer task list --search "state=running"

# Clean up old tasks if necessary
foreman-rake foreman_tasks:cleanup TASK_SEARCH='state=stopped' STATES='stopped' VERBOSE=true
Conclusion
In this lab, you have successfully completed comprehensive Red Hat Satellite server maintenance tasks that are essential for production environments. You have learned to:

Apply security patches safely using proper pre-patch assessment, maintenance mode procedures, and post-patch verification
Implement automated backup strategies with scheduled daily, weekly, and monthly backups, including retention policies and monitoring
Set up comprehensive monitoring systems for both system resources and Satellite-specific performance metrics
These maintenance practices are crucial for:

Security: Regular patching protects against vulnerabilities
Business Continuity: Reliable backups ensure data recovery capabilities
Performance Optimization: Continuous monitoring enables proactive issue resolution
Compliance: Systematic maintenance supports audit and compliance requirements
The scripts and procedures you've implemented provide a solid foundation for maintaining a production Satellite environment. Regular execution of these maintenance tasks will help ensure your Satellite infrastructure remains secure, performant, and reliable.

Next Steps: Consider implementing additional monitoring tools like Nagios or Zabbix for more advanced alerting, and explore Red Hat Insights integration for proactive system health management.
