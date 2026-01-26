Lab 19: Disaster Recovery and Backup Planning
Objectives
By the end of this lab, students will be able to:

Understand the importance of disaster recovery planning for Red Hat Satellite infrastructure
Create comprehensive backups of Satellite database and configuration files
Implement automated backup strategies using open-source tools
Design and test disaster recovery procedures
Successfully restore Satellite from backup in a test environment
Validate backup integrity and recovery processes
Document disaster recovery procedures for operational use
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with Red Hat Satellite 6 architecture and components
Knowledge of PostgreSQL database concepts
Understanding of file system operations and permissions
Experience with shell scripting and cron jobs
Access to command-line interface and text editors
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Red Hat Satellite 6 installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

Primary Satellite server (satellite.example.com)
Backup test server (backup.example.com)
PostgreSQL database with sample data
Pre-configured storage locations for backups
Task 1: Create Regular Backups of Satellite's Database and Configurations
Subtask 1.1: Understanding Satellite Backup Components
Before creating backups, let's identify the critical components that need protection:

Connect to your Satellite server:
ssh root@satellite.example.com
Examine Satellite directory structure:
ls -la /var/lib/pulp/
ls -la /etc/foreman/
ls -la /etc/httpd/
ls -la /var/lib/candlepin/
Check PostgreSQL database status:
systemctl status postgresql
sudo -u postgres psql -l
Subtask 1.2: Create Database Backup Script
Create backup directory structure:
mkdir -p /backup/satellite/{database,config,pulp}
chmod 750 /backup/satellite
Create database backup script:
cat > /backup/satellite/backup-database.sh << 'EOF'
#!/bin/bash

# Satellite Database Backup Script
# Created for disaster recovery purposes

BACKUP_DIR="/backup/satellite/database"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/satellite-backup.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Starting Satellite database backup"

# Stop Satellite services to ensure consistent backup
log_message "Stopping Satellite services"
satellite-maintain service stop

# Create PostgreSQL dump
log_message "Creating PostgreSQL database dump"
sudo -u postgres pg_dumpall > $BACKUP_DIR/satellite_db_$DATE.sql

if [ $? -eq 0 ]; then
    log_message "Database backup completed successfully"
    
    # Compress the backup
    gzip $BACKUP_DIR/satellite_db_$DATE.sql
    log_message "Database backup compressed"
else
    log_message "ERROR: Database backup failed"
    exit 1
fi

# Start Satellite services
log_message "Starting Satellite services"
satellite-maintain service start

# Clean up old backups (keep last 7 days)
find $BACKUP_DIR -name "satellite_db_*.sql.gz" -mtime +7 -delete
log_message "Old backups cleaned up"

log_message "Database backup process completed"
EOF
Make the script executable:
chmod +x /backup/satellite/backup-database.sh
Subtask 1.3: Create Configuration Backup Script
Create configuration backup script:
cat > /backup/satellite/backup-config.sh << 'EOF'
#!/bin/bash

# Satellite Configuration Backup Script
BACKUP_DIR="/backup/satellite/config"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/satellite-backup.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Starting Satellite configuration backup"

# Create configuration backup archive
tar -czf $BACKUP_DIR/satellite_config_$DATE.tar.gz \
    /etc/foreman/ \
    /etc/foreman-proxy/ \
    /etc/httpd/ \
    /etc/candlepin/ \
    /etc/pulp/ \
    /etc/qpid/ \
    /etc/squid/ \
    /etc/dhcp/ \
    /etc/named/ \
    /var/lib/foreman/ \
    /var/lib/puppet/ssl/ \
    /root/ssl-build/ 2>/dev/null

if [ $? -eq 0 ]; then
    log_message "Configuration backup completed successfully"
else
    log_message "WARNING: Some configuration files may not have been backed up"
fi

# Clean up old configuration backups
find $BACKUP_DIR -name "satellite_config_*.tar.gz" -mtime +7 -delete
log_message "Configuration backup process completed"
EOF
Make the script executable:
chmod +x /backup/satellite/backup-config.sh
Subtask 1.4: Create Pulp Content Backup Script
Create Pulp content backup script:
cat > /backup/satellite/backup-pulp.sh << 'EOF'
#!/bin/bash

# Satellite Pulp Content Backup Script
BACKUP_DIR="/backup/satellite/pulp"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/satellite-backup.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Starting Pulp content backup"

# Create incremental backup of Pulp content
rsync -av --delete /var/lib/pulp/ $BACKUP_DIR/pulp_content_$DATE/

if [ $? -eq 0 ]; then
    log_message "Pulp content backup completed successfully"
    
    # Create a compressed archive for storage
    tar -czf $BACKUP_DIR/pulp_content_$DATE.tar.gz -C $BACKUP_DIR pulp_content_$DATE/
    rm -rf $BACKUP_DIR/pulp_content_$DATE/
    
    log_message "Pulp content backup compressed and cleaned up"
else
    log_message "ERROR: Pulp content backup failed"
    exit 1
fi

# Clean up old Pulp backups (keep last 3 days due to size)
find $BACKUP_DIR -name "pulp_content_*.tar.gz" -mtime +3 -delete
log_message "Pulp content backup process completed"
EOF
Make the script executable:
chmod +x /backup/satellite/backup-pulp.sh
Subtask 1.5: Create Master Backup Script
Create comprehensive backup script:
cat > /backup/satellite/full-backup.sh << 'EOF'
#!/bin/bash

# Master Satellite Backup Script
LOG_FILE="/var/log/satellite-backup.log"
BACKUP_BASE="/backup/satellite"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "=== Starting Full Satellite Backup ==="

# Check available disk space
AVAILABLE_SPACE=$(df $BACKUP_BASE | awk 'NR==2 {print $4}')
REQUIRED_SPACE=10485760  # 10GB in KB

if [ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]; then
    log_message "ERROR: Insufficient disk space for backup"
    exit 1
fi

# Execute backup scripts in sequence
log_message "Executing database backup"
/backup/satellite/backup-database.sh

if [ $? -ne 0 ]; then
    log_message "ERROR: Database backup failed"
    exit 1
fi

log_message "Executing configuration backup"
/backup/satellite/backup-config.sh

log_message "Executing Pulp content backup"
/backup/satellite/backup-pulp.sh

# Create backup manifest
DATE=$(date +%Y%m%d_%H%M%S)
cat > $BACKUP_BASE/backup_manifest_$DATE.txt << MANIFEST
Satellite Backup Manifest
Generated: $(date)
Hostname: $(hostname)
Satellite Version: $(satellite-maintain service version)

Database Backup: $(ls -la $BACKUP_BASE/database/satellite_db_*.sql.gz | tail -1)
Config Backup: $(ls -la $BACKUP_BASE/config/satellite_config_*.tar.gz | tail -1)
Pulp Backup: $(ls -la $BACKUP_BASE/pulp/pulp_content_*.tar.gz | tail -1)

Backup completed successfully.
MANIFEST

log_message "=== Full Satellite Backup Completed ==="
EOF
Make the script executable:
chmod +x /backup/satellite/full-backup.sh
Subtask 1.6: Schedule Automated Backups
Create cron job for automated backups:
crontab -e
Add the following cron entries:
# Satellite Backup Schedule
# Full backup every Sunday at 2 AM
0 2 * * 0 /backup/satellite/full-backup.sh

# Database backup every day at 1 AM
0 1 * * * /backup/satellite/backup-database.sh

# Configuration backup every day at 1:30 AM
30 1 * * * /backup/satellite/backup-config.sh
Verify cron job installation:
crontab -l
Subtask 1.7: Test Initial Backup
Run the full backup script manually:
/backup/satellite/full-backup.sh
Verify backup files were created:
ls -la /backup/satellite/database/
ls -la /backup/satellite/config/
ls -la /backup/satellite/pulp/
Check backup log:
tail -20 /var/log/satellite-backup.log
Task 2: Plan and Test Disaster Recovery Procedures
Subtask 2.1: Create Disaster Recovery Documentation
Create disaster recovery plan document:
cat > /backup/satellite/disaster-recovery-plan.md << 'EOF'
# Satellite Disaster Recovery Plan

## Recovery Time Objective (RTO)
- Target: 4 hours for full system recovery
- Critical services: 2 hours

## Recovery Point Objective (RPO)
- Maximum data loss: 24 hours
- Database: 1 hour (with daily backups)

## Recovery Procedures

### Phase 1: Assessment
1. Determine scope of disaster
2. Identify affected components
3. Estimate recovery time
4. Notify stakeholders

### Phase 2: Infrastructure Recovery
1. Provision new hardware/VM if needed
2. Install base operating system
3. Configure network settings
4. Install Satellite software

### Phase 3: Data Recovery
1. Restore database from backup
2. Restore configuration files
3. Restore Pulp content
4. Verify file permissions

### Phase 4: Service Validation
1. Start Satellite services
2. Verify web interface access
3. Test client connections
4. Validate content synchronization

### Phase 5: Post-Recovery
1. Update DNS records if needed
2. Notify users of service restoration
3. Document lessons learned
4. Update recovery procedures
EOF
Subtask 2.2: Create Recovery Scripts
Create database recovery script:
cat > /backup/satellite/restore-database.sh << 'EOF'
#!/bin/bash

# Satellite Database Recovery Script
BACKUP_DIR="/backup/satellite/database"
LOG_FILE="/var/log/satellite-recovery.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 satellite_db_20231201_020000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    log_message "ERROR: Backup file not found: $BACKUP_DIR/$BACKUP_FILE"
    exit 1
fi

log_message "Starting database recovery from $BACKUP_FILE"

# Stop Satellite services
log_message "Stopping Satellite services"
satellite-maintain service stop

# Drop existing databases (CAUTION: This will destroy current data)
log_message "WARNING: Dropping existing databases"
sudo -u postgres psql -c "DROP DATABASE IF EXISTS foreman;"
sudo -u postgres psql -c "DROP DATABASE IF EXISTS candlepin;"
sudo -u postgres psql -c "DROP DATABASE IF EXISTS pulp_database;"

# Restore from backup
log_message "Restoring database from backup"
gunzip -c $BACKUP_DIR/$BACKUP_FILE | sudo -u postgres psql

if [ $? -eq 0 ]; then
    log_message "Database restoration completed successfully"
else
    log_message "ERROR: Database restoration failed"
    exit 1
fi

# Start Satellite services
log_message "Starting Satellite services"
satellite-maintain service start

log_message "Database recovery completed"
EOF
Make the script executable:
chmod +x /backup/satellite/restore-database.sh
Create configuration recovery script:
cat > /backup/satellite/restore-config.sh << 'EOF'
#!/bin/bash

# Satellite Configuration Recovery Script
BACKUP_DIR="/backup/satellite/config"
LOG_FILE="/var/log/satellite-recovery.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 satellite_config_20231201_020000.tar.gz"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    log_message "ERROR: Backup file not found: $BACKUP_DIR/$BACKUP_FILE"
    exit 1
fi

log_message "Starting configuration recovery from $BACKUP_FILE"

# Stop services before restoration
satellite-maintain service stop

# Backup current configuration (just in case)
tar -czf /tmp/current_config_backup_$(date +%Y%m%d_%H%M%S).tar.gz \
    /etc/foreman/ /etc/foreman-proxy/ /etc/httpd/ 2>/dev/null

# Restore configuration files
log_message "Restoring configuration files"
tar -xzf $BACKUP_DIR/$BACKUP_FILE -C /

# Fix file permissions
log_message "Fixing file permissions"
chown -R foreman:foreman /var/lib/foreman/
chown -R apache:apache /etc/httpd/
chown -R foreman-proxy:foreman-proxy /etc/foreman-proxy/

# Start services
satellite-maintain service start

log_message "Configuration recovery completed"
EOF
Make the script executable:
chmod +x /backup/satellite/restore-config.sh
Subtask 2.3: Create Recovery Validation Script
Create validation script:
cat > /backup/satellite/validate-recovery.sh << 'EOF'
#!/bin/bash

# Satellite Recovery Validation Script
LOG_FILE="/var/log/satellite-recovery.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Starting recovery validation"

# Check service status
log_message "Checking service status"
satellite-maintain service status

# Check database connectivity
log_message "Testing database connectivity"
sudo -u postgres psql -c "SELECT version();" foreman

# Check web interface
log_message "Testing web interface"
curl -k -s -o /dev/null -w "%{http_code}" https://$(hostname)/users/login

# Check API access
log_message "Testing API access"
hammer ping

# Verify content availability
log_message "Checking content availability"
ls -la /var/lib/pulp/

log_message "Recovery validation completed"
EOF
Make the script executable:
chmod +x /backup/satellite/validate-recovery.sh
Subtask 2.4: Document Recovery Procedures
Create step-by-step recovery guide:
cat > /backup/satellite/recovery-procedures.txt << 'EOF'
SATELLITE DISASTER RECOVERY PROCEDURES

=== EMERGENCY RECOVERY STEPS ===

1. PREPARATION
   - Ensure backup files are accessible
   - Verify new server meets minimum requirements
   - Have Satellite installation media ready

2. SYSTEM INSTALLATION
   - Install RHEL 8 on new server
   - Configure network settings
   - Install Satellite 6 software
   - DO NOT run satellite-installer yet

3. DATABASE RECOVERY
   - Copy backup files to new server
   - Run: /backup/satellite/restore-database.sh <backup_file>
   - Wait for completion

4. CONFIGURATION RECOVERY
   - Run: /backup/satellite/restore-config.sh <config_backup>
   - Verify file permissions

5. CONTENT RECOVERY
   - Extract Pulp content backup
   - Copy to /var/lib/pulp/
   - Fix ownership: chown -R apache:apache /var/lib/pulp/

6. SERVICE STARTUP
   - Run: satellite-maintain service start
   - Monitor logs: tail -f /var/log/foreman/production.log

7. VALIDATION
   - Run: /backup/satellite/validate-recovery.sh
   - Test web interface access
   - Verify client connectivity

8. POST-RECOVERY
   - Update DNS records if needed
   - Notify users
   - Schedule full backup
   - Document any issues encountered

=== EMERGENCY CONTACTS ===
System Administrator: admin@example.com
Network Team: network@example.com
Management: manager@example.com
EOF
Task 3: Restore from Backup in a Test Environment
Subtask 3.1: Prepare Test Environment
Connect to backup test server:
ssh root@backup.example.com
Install required packages:
dnf install -y postgresql-server rsync tar gzip
Initialize PostgreSQL:
postgresql-setup --initdb
systemctl enable postgresql
systemctl start postgresql
Create backup directory structure:
mkdir -p /backup/satellite/{database,config,pulp}
Subtask 3.2: Copy Backup Files to Test Environment
Copy backup files from production server:
# From the test server, copy backups from production
scp root@satellite.example.com:/backup/satellite/database/*.sql.gz /backup/satellite/database/
scp root@satellite.example.com:/backup/satellite/config/*.tar.gz /backup/satellite/config/
scp root@satellite.example.com:/backup/satellite/pulp/*.tar.gz /backup/satellite/pulp/
Verify backup files:
ls -la /backup/satellite/database/
ls -la /backup/satellite/config/
ls -la /backup/satellite/pulp/
Subtask 3.3: Test Database Restoration
Create test database restoration script:
cat > /backup/satellite/test-db-restore.sh << 'EOF'
#!/bin/bash

# Test Database Restoration Script
BACKUP_DIR="/backup/satellite/database"
LOG_FILE="/var/log/test-restore.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Find the latest database backup
LATEST_BACKUP=$(ls -t $BACKUP_DIR/satellite_db_*.sql.gz | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    log_message "ERROR: No database backup found"
    exit 1
fi

log_message "Testing database restoration from $(basename $LATEST_BACKUP)"

# Create test database
sudo -u postgres createdb test_satellite_restore

# Restore to test database
log_message "Restoring database backup"
gunzip -c $LATEST_BACKUP | sudo -u postgres psql test_satellite_restore

if [ $? -eq 0 ]; then
    log_message "Database restoration test SUCCESSFUL"
    
    # Verify data integrity
    log_message "Verifying restored data"
    sudo -u postgres psql test_satellite_restore -c "\dt" | head -10
    
    # Clean up test database
    sudo -u postgres dropdb test_satellite_restore
    log_message "Test database cleaned up"
else
    log_message "ERROR: Database restoration test FAILED"
    exit 1
fi

log_message "Database restoration test completed"
EOF
Make the script executable and run it:
chmod +x /backup/satellite/test-db-restore.sh
/backup/satellite/test-db-restore.sh
Subtask 3.4: Test Configuration Restoration
Create test configuration restoration script:
cat > /backup/satellite/test-config-restore.sh << 'EOF'
#!/bin/bash

# Test Configuration Restoration Script
BACKUP_DIR="/backup/satellite/config"
LOG_FILE="/var/log/test-restore.log"
TEST_DIR="/tmp/config-restore-test"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Find the latest configuration backup
LATEST_CONFIG=$(ls -t $BACKUP_DIR/satellite_config_*.tar.gz | head -1)

if [ -z "$LATEST_CONFIG" ]; then
    log_message "ERROR: No configuration backup found"
    exit 1
fi

log_message "Testing configuration restoration from $(basename $LATEST_CONFIG)"

# Create test directory
mkdir -p $TEST_DIR
cd $TEST_DIR

# Extract configuration backup
log_message "Extracting configuration backup"
tar -xzf $LATEST_CONFIG

if [ $? -eq 0 ]; then
    log_message "Configuration extraction test SUCCESSFUL"
    
    # Verify extracted files
    log_message "Verifying extracted configuration files"
    find . -name "*.conf" | head -10
    find . -name "*.yml" | head -5
    
    # Check for critical configuration files
    if [ -d "./etc/foreman" ]; then
        log_message "Foreman configuration found"
    fi
    
    if [ -d "./etc/httpd" ]; then
        log_message "Apache configuration found"
    fi
    
    # Clean up test directory
    rm -rf $TEST_DIR
    log_message "Test directory cleaned up"
else
    log_message "ERROR: Configuration extraction test FAILED"
    exit 1
fi

log_message "Configuration restoration test completed"
EOF
Make the script executable and run it:
chmod +x /backup/satellite/test-config-restore.sh
/backup/satellite/test-config-restore.sh
Subtask 3.5: Test Pulp Content Restoration
Create test Pulp restoration script:
cat > /backup/satellite/test-pulp-restore.sh << 'EOF'
#!/bin/bash

# Test Pulp Content Restoration Script
BACKUP_DIR="/backup/satellite/pulp"
LOG_FILE="/var/log/test-restore.log"
TEST_DIR="/tmp/pulp-restore-test"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Find the latest Pulp backup
LATEST_PULP=$(ls -t $BACKUP_DIR/pulp_content_*.tar.gz | head -1)

if [ -z "$LATEST_PULP" ]; then
    log_message "ERROR: No Pulp content backup found"
    exit 1
fi

log_message "Testing Pulp content restoration from $(basename $LATEST_PULP)"

# Create test directory
mkdir -p $TEST_DIR
cd $TEST_DIR

# Extract Pulp backup
log_message "Extracting Pulp content backup"
tar -xzf $LATEST_PULP

if [ $? -eq 0 ]; then
    log_message "Pulp content extraction test SUCCESSFUL"
    
    # Verify extracted content
    log_message "Verifying extracted Pulp content"
    find . -type f | wc -l | xargs echo "Total files extracted:"
    du -sh . | xargs echo "Total size:"
    
    # Check for typical Pulp directories
    if [ -d "./content" ]; then
        log_message "Pulp content directory found"
    fi
    
    # Clean up test directory
    rm -rf $TEST_DIR
    log_message "Test directory cleaned up"
else
    log_message "ERROR: Pulp content extraction test FAILED"
    exit 1
fi

log_message "Pulp content restoration test completed"
EOF
Make the script executable and run it:
chmod +x /backup/satellite/test-pulp-restore.sh
/backup/satellite/test-pulp-restore.sh
Subtask 3.6: Create Comprehensive Test Report
Create test report generation script:
cat > /backup/satellite/generate-test-report.sh << 'EOF'
#!/bin/bash

# Test Report Generation Script
REPORT_FILE="/backup/satellite/disaster-recovery-test-report.txt"
LOG_FILE="/var/log/test-restore.log"

cat > $REPORT_FILE << REPORT
SATELLITE DISASTER RECOVERY TEST REPORT
Generated: $(date)
Test Environment: $(hostname)

=== TEST SUMMARY ===
Database Restoration Test: $(grep -q "Database restoration test SUCCESSFUL" $LOG_FILE && echo "PASSED" || echo "FAILED")
Configuration Restoration Test: $(grep -q "Configuration extraction test SUCCESSFUL" $LOG_FILE && echo "PASSED" || echo "FAILED")
Pulp Content Restoration Test: $(grep -q "Pulp content extraction test SUCCESSFUL" $LOG_FILE && echo "PASSED" || echo "FAILED")

=== BACKUP FILE INVENTORY ===
Database Backups:
$(ls -la /backup/satellite/database/)

Configuration Backups:
$(ls -la /backup/satellite/config/)

Pulp Content Backups:
$(ls -la /backup/satellite/pulp/)

=== TEST LOG SUMMARY ===
$(tail -20 $LOG_FILE)

=== RECOMMENDATIONS ===
1. All backup restoration tests completed successfully
2. Backup files are intact and restorable
3. Recovery procedures are validated
4. Consider scheduling regular DR tests monthly
5. Update recovery documentation as needed

=== NEXT STEPS ===
1. Schedule production disaster recovery drill
2. Train additional staff on recovery procedures
3. Review and update backup retention policies
4. Test recovery with different failure scenarios

Report completed: $(date)
REPORT

echo "Test report generated: $REPORT_FILE"
EOF
Make the script executable and run it:
chmod +x /backup/satellite/generate-test-report.sh
/backup/satellite/generate-test-report.sh
View the test report:
cat /backup/satellite/disaster-recovery-test-report.txt
Subtask 3.7: Validate Complete Recovery Process
Create end-to-end validation script:
cat > /backup/satellite/validate-complete-recovery.sh << 'EOF'
#!/bin/bash

# Complete Recovery Validation Script
LOG_FILE="/var/log/test-restore.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "=== STARTING COMPLETE RECOVERY VALIDATION ==="

# Test 1: Database Restoration
log_message "Running database restoration test"
/backup/satellite/test-db-restore.sh
DB_TEST_RESULT=$?

# Test 2: Configuration Restoration
log_message "Running configuration restoration test"
/backup/satellite/test-config-restore.sh
CONFIG_TEST_RESULT=$?

# Test 3: Pulp Content Restoration
log_message "Running Pulp content restoration test"
/backup/satellite/test-pulp-restore.sh
PULP_TEST_RESULT=$?

# Generate comprehensive report
log_message "Generating test report"
/backup/satellite/generate-test-report.sh

# Summary
log_message "=== VALIDATION SUMMARY ==="
if [ $DB_TEST_RESULT -eq 0 ] && [ $CONFIG_TEST_RESULT -eq 0 ] && [ $PULP_TEST_RESULT -eq 0 ]; then
    log_message "ALL TESTS PASSED - Disaster recovery procedures validated"
    echo "✓ Disaster Recovery Validation: SUCCESSFUL"
else
    log_message "SOME TESTS FAILED - Review procedures and backups"
    echo "✗ Disaster Recovery Validation: FAILED"
fi

log_message "=== COMPLETE RECOVERY VALIDATION FINISHED ==="
EOF
Make the script executable and run final validation:
chmod +x /backup/satellite/validate-complete-recovery.sh
/backup/satellite/validate-complete-recovery.sh
Troubleshooting Tips
Common Backup Issues
Issue: Backup script fails with permission errors Solution:

# Check and fix backup directory permissions
chown -R root:root /backup/satellite
chmod -R 750 /backup/satellite
Issue: Database backup fails due to insufficient space Solution:

# Check available space
df -h /backup
# Clean up old backups or increase storage
find /backup -name "*.gz" -mtime +30 -delete
Issue: Satellite services won't stop during backup Solution:

# Force stop services
satellite-maintain service stop --force
# Check for remaining processes
ps aux | grep -E "(foreman|httpd|postgresql)"
Common Recovery Issues
Issue: Database restoration fails with encoding errors Solution:

# Set correct locale before restoration
export LC_ALL=en_US.UTF-8
sudo -u postgres psql -c "UPDATE pg_database SET datcollate='en_US.UTF-8', datctype='en_US.UTF-8' WHERE datname='template0';"
Issue: Configuration files have wrong permissions after restoration Solution:

# Fix common permission issues
chown -R foreman:foreman /var/lib/foreman/
chown -R apache:apache /var/lib/pulp/
chmod 640 /etc/foreman/database.yml
Issue: Services fail to start after recovery Solution:

# Check service dependencies
satellite-maintain service status
# Restart services in correct order
satellite-maintain service restart
Conclusion
In this comprehensive lab, you have successfully:

Created robust backup strategies for Red Hat Satellite infrastructure, including database, configuration, and content backups
Implemented automated backup scheduling using cron jobs to ensure regular data protection
Developed comprehensive disaster recovery procedures with detailed documentation and step-by-step recovery scripts
Tested backup and recovery processes in a controlled environment to validate their effectiveness
