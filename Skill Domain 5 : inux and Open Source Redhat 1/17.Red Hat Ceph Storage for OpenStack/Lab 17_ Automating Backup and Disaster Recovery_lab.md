Lab 17: Automating Backup and Disaster Recovery
Objectives
By the end of this lab, students will be able to:

Understand the importance of backup and disaster recovery in Ceph storage systems
Create regular backups of Ceph cluster metadata and configuration data
Implement automated backup solutions using Ansible playbooks
Test disaster recovery procedures by restoring from backups
Configure monitoring and alerting for backup operations
Establish best practices for backup retention and storage
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph storage architecture and components
Familiarity with Linux command-line operations
Knowledge of YAML syntax and Ansible basics
Understanding of cron jobs and task scheduling
Basic networking concepts and SSH connectivity
Experience with text editors (vim, nano, or similar)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph cluster already deployed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ceph monitor nodes (ceph-mon-01, ceph-mon-02, ceph-mon-03)
3 Ceph OSD nodes (ceph-osd-01, ceph-osd-02, ceph-osd-03)
1 Ceph admin node (ceph-admin)
1 Backup server (backup-server)
Ansible pre-installed on the admin node
Task 1: Create Regular Backups of Ceph Data
Subtask 1.1: Understanding Ceph Backup Components
Before creating backups, let's understand what needs to be backed up in a Ceph cluster:

Connect to the Ceph admin node:
ssh ceph-admin
Check cluster status:
sudo ceph status
Identify critical components to backup:
# Monitor maps and cluster state
sudo ceph mon dump
sudo ceph osd dump
sudo ceph mds dump
sudo ceph mgr dump
Subtask 1.2: Create Backup Directory Structure
Create backup directories:
sudo mkdir -p /opt/ceph-backups/{cluster-maps,configs,keys,logs}
sudo mkdir -p /opt/ceph-backups/daily/{$(date +%Y-%m-%d)}
Set proper permissions:
sudo chown -R ceph:ceph /opt/ceph-backups
sudo chmod -R 755 /opt/ceph-backups
Subtask 1.3: Create Manual Backup Scripts
Create the main backup script:
sudo vim /opt/ceph-backups/ceph-backup.sh
Add the following content:
#!/bin/bash

# Ceph Cluster Backup Script
# This script creates backups of critical Ceph cluster components

BACKUP_DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/opt/ceph-backups/daily/$BACKUP_DATE"
LOG_FILE="/opt/ceph-backups/logs/backup-$BACKUP_DATE.log"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting Ceph cluster backup"

# Backup cluster maps
log_message "Backing up cluster maps"
ceph mon dump > "$BACKUP_DIR/mon-dump.txt" 2>&1
ceph osd dump > "$BACKUP_DIR/osd-dump.txt" 2>&1
ceph mds dump > "$BACKUP_DIR/mds-dump.txt" 2>&1
ceph mgr dump > "$BACKUP_DIR/mgr-dump.txt" 2>&1
ceph pg dump > "$BACKUP_DIR/pg-dump.txt" 2>&1

# Backup cluster configuration
log_message "Backing up cluster configuration"
ceph config dump > "$BACKUP_DIR/config-dump.txt" 2>&1

# Backup authentication keys
log_message "Backing up authentication keys"
cp -r /etc/ceph/ "$BACKUP_DIR/ceph-config/" 2>&1

# Backup crush map
log_message "Backing up CRUSH map"
ceph osd getcrushmap -o "$BACKUP_DIR/crushmap.bin" 2>&1
crushtool -d "$BACKUP_DIR/crushmap.bin" -o "$BACKUP_DIR/crushmap.txt" 2>&1

# Create cluster health report
log_message "Creating cluster health report"
ceph health detail > "$BACKUP_DIR/health-detail.txt" 2>&1
ceph df > "$BACKUP_DIR/cluster-usage.txt" 2>&1

# Compress backup
log_message "Compressing backup"
cd /opt/ceph-backups/daily/
tar -czf "ceph-backup-$BACKUP_DATE.tar.gz" "$BACKUP_DATE/"

# Cleanup old backups (keep last 7 days)
log_message "Cleaning up old backups"
find /opt/ceph-backups/daily/ -name "ceph-backup-*.tar.gz" -mtime +7 -delete

log_message "Backup completed successfully"
Make the script executable:
sudo chmod +x /opt/ceph-backups/ceph-backup.sh
Test the backup script:
sudo /opt/ceph-backups/ceph-backup.sh
Verify backup creation:
ls -la /opt/ceph-backups/daily/
Subtask 1.4: Create Pool Data Backup Script
Create pool data backup script:
sudo vim /opt/ceph-backups/pool-backup.sh
Add the following content:
#!/bin/bash

# Ceph Pool Data Backup Script
BACKUP_DATE=$(date +%Y-%m-%d_%H-%M-%S)
POOL_BACKUP_DIR="/opt/ceph-backups/pools/$BACKUP_DATE"
LOG_FILE="/opt/ceph-backups/logs/pool-backup-$BACKUP_DATE.log"

mkdir -p "$POOL_BACKUP_DIR"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting pool data backup"

# Get list of pools
POOLS=$(ceph osd lspools | awk '{print $2}')

for pool in $POOLS; do
    log_message "Backing up pool: $pool"
    
    # Create pool-specific backup directory
    mkdir -p "$POOL_BACKUP_DIR/$pool"
    
    # Export pool data (for RBD pools)
    if ceph osd pool get "$pool" size > /dev/null 2>&1; then
        # List objects in pool
        rados -p "$pool" ls > "$POOL_BACKUP_DIR/$pool/object-list.txt"
        
        # Backup pool metadata
        ceph osd pool get "$pool" size > "$POOL_BACKUP_DIR/$pool/pool-size.txt"
        ceph osd pool get "$pool" min_size > "$POOL_BACKUP_DIR/$pool/pool-min-size.txt"
        ceph osd pool get "$pool" pg_num > "$POOL_BACKUP_DIR/$pool/pool-pg-num.txt"
        ceph osd pool get "$pool" pgp_num > "$POOL_BACKUP_DIR/$pool/pool-pgp-num.txt"
    fi
done

log_message "Pool backup completed"
Make the script executable:
sudo chmod +x /opt/ceph-backups/pool-backup.sh
Task 2: Automate Backups with Ansible
Subtask 2.1: Create Ansible Inventory
Create Ansible inventory file:
sudo vim /etc/ansible/hosts
Add the following content:
[ceph_admin]
ceph-admin ansible_host=ceph-admin ansible_user=ceph

[ceph_mons]
ceph-mon-01 ansible_host=ceph-mon-01 ansible_user=ceph
ceph-mon-02 ansible_host=ceph-mon-02 ansible_user=ceph
ceph-mon-03 ansible_host=ceph-mon-03 ansible_user=ceph

[ceph_osds]
ceph-osd-01 ansible_host=ceph-osd-01 ansible_user=ceph
ceph-osd-02 ansible_host=ceph-osd-02 ansible_user=ceph
ceph-osd-03 ansible_host=ceph-osd-03 ansible_user=ceph

[backup_servers]
backup-server ansible_host=backup-server ansible_user=backup

[ceph_cluster:children]
ceph_admin
ceph_mons
ceph_osds
Subtask 2.2: Create Ansible Playbook for Backup Automation
Create the main backup playbook:
mkdir -p /opt/ansible-ceph-backup
cd /opt/ansible-ceph-backup
Create the playbook file:
vim ceph-backup-playbook.yml
Add the following content:
---
- name: Automated Ceph Cluster Backup
  hosts: ceph_admin
  become: yes
  vars:
    backup_base_dir: "/opt/ceph-backups"
    backup_retention_days: 7
    remote_backup_server: "backup-server"
    remote_backup_path: "/backup/ceph-cluster"
    
  tasks:
    - name: Ensure backup directories exist
      file:
        path: "{{ item }}"
        state: directory
        owner: ceph
        group: ceph
        mode: '0755'
      loop:
        - "{{ backup_base_dir }}/daily"
        - "{{ backup_base_dir }}/logs"
        - "{{ backup_base_dir }}/scripts"
        - "{{ backup_base_dir }}/configs"
        - "{{ backup_base_dir }}/keys"

    - name: Copy backup scripts
      copy:
        src: "{{ item.src }}"
        dest: "{{ item.dest }}"
        owner: ceph
        group: ceph
        mode: '0755'
      loop:
        - { src: "/opt/ceph-backups/ceph-backup.sh", dest: "{{ backup_base_dir }}/scripts/ceph-backup.sh" }
        - { src: "/opt/ceph-backups/pool-backup.sh", dest: "{{ backup_base_dir }}/scripts/pool-backup.sh" }

    - name: Execute cluster backup
      shell: "{{ backup_base_dir }}/scripts/ceph-backup.sh"
      register: backup_result
      
    - name: Execute pool backup
      shell: "{{ backup_base_dir }}/scripts/pool-backup.sh"
      register: pool_backup_result

    - name: Display backup results
      debug:
        msg: 
          - "Cluster backup status: {{ backup_result.rc }}"
          - "Pool backup status: {{ pool_backup_result.rc }}"

    - name: Find latest backup file
      find:
        paths: "{{ backup_base_dir }}/daily"
        patterns: "ceph-backup-*.tar.gz"
        age: -1d
      register: latest_backup

    - name: Copy backup to remote server
      copy:
        src: "{{ item.path }}"
        dest: "{{ remote_backup_path }}/{{ item.path | basename }}"
        remote_src: yes
      delegate_to: "{{ remote_backup_server }}"
      loop: "{{ latest_backup.files }}"
      when: latest_backup.files | length > 0

    - name: Send backup notification
      mail:
        to: admin@company.com
        subject: "Ceph Backup Completed - {{ ansible_date_time.date }}"
        body: |
          Ceph cluster backup completed successfully.
          
          Backup Details:
          - Date: {{ ansible_date_time.date }}
          - Time: {{ ansible_date_time.time }}
          - Backup files: {{ latest_backup.files | length }}
          - Remote backup: {{ 'Success' if latest_backup.files | length > 0 else 'Failed' }}
      when: latest_backup.files | length > 0
Subtask 2.3: Create Backup Monitoring Playbook
Create monitoring playbook:
vim ceph-backup-monitor.yml
Add the following content:
---
- name: Monitor Ceph Backup Health
  hosts: ceph_admin
  become: yes
  vars:
    backup_base_dir: "/opt/ceph-backups"
    max_backup_age_hours: 25
    
  tasks:
    - name: Check for recent backups
      find:
        paths: "{{ backup_base_dir }}/daily"
        patterns: "ceph-backup-*.tar.gz"
        age: "-{{ max_backup_age_hours }}h"
      register: recent_backups

    - name: Check backup log for errors
      shell: "tail -n 50 {{ backup_base_dir }}/logs/backup-*.log | grep -i error || true"
      register: backup_errors
      changed_when: false

    - name: Verify cluster health
      shell: "ceph health"
      register: cluster_health
      changed_when: false

    - name: Generate backup report
      template:
        src: backup-report.j2
        dest: "{{ backup_base_dir }}/reports/backup-report-{{ ansible_date_time.date }}.txt"
      vars:
        backup_count: "{{ recent_backups.files | length }}"
        backup_errors_found: "{{ backup_errors.stdout_lines | length > 0 }}"
        cluster_status: "{{ cluster_health.stdout }}"

    - name: Alert if no recent backups
      fail:
        msg: "No recent backups found! Last backup is older than {{ max_backup_age_hours }} hours."
      when: recent_backups.files | length == 0
Subtask 2.4: Schedule Automated Backups
Create cron job for automated backups:
sudo crontab -e
Add the following cron entries:
# Daily backup at 2 AM
0 2 * * * /usr/bin/ansible-playbook /opt/ansible-ceph-backup/ceph-backup-playbook.yml

# Backup monitoring every 6 hours
0 */6 * * * /usr/bin/ansible-playbook /opt/ansible-ceph-backup/ceph-backup-monitor.yml

# Weekly cleanup of old backups
0 3 * * 0 find /opt/ceph-backups/daily -name "ceph-backup-*.tar.gz" -mtime +7 -delete
Test the automated backup:
ansible-playbook /opt/ansible-ceph-backup/ceph-backup-playbook.yml
Task 3: Test Disaster Recovery by Restoring from Backups
Subtask 3.1: Create Disaster Recovery Scripts
Create disaster recovery directory:
sudo mkdir -p /opt/ceph-recovery/scripts
cd /opt/ceph-recovery
Create the main recovery script:
sudo vim scripts/ceph-recovery.sh
Add the following content:
#!/bin/bash

# Ceph Disaster Recovery Script
RECOVERY_DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$1"
RECOVERY_LOG="/opt/ceph-recovery/logs/recovery-$RECOVERY_DATE.log"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file.tar.gz>"
    exit 1
fi

mkdir -p /opt/ceph-recovery/logs
mkdir -p /opt/ceph-recovery/temp

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$RECOVERY_LOG"
}

log_message "Starting disaster recovery from backup: $BACKUP_FILE"

# Extract backup
log_message "Extracting backup file"
cd /opt/ceph-recovery/temp
tar -xzf "$BACKUP_FILE"

BACKUP_DIR=$(find . -maxdepth 1 -type d -name "20*" | head -1)

if [ -z "$BACKUP_DIR" ]; then
    log_message "ERROR: Could not find backup directory in archive"
    exit 1
fi

log_message "Found backup directory: $BACKUP_DIR"

# Stop Ceph services (if running)
log_message "Stopping Ceph services"
systemctl stop ceph-mon@$(hostname)
systemctl stop ceph-mgr@$(hostname)

# Restore configuration files
log_message "Restoring Ceph configuration"
if [ -d "$BACKUP_DIR/ceph-config" ]; then
    cp -r "$BACKUP_DIR/ceph-config/"* /etc/ceph/
    chown -R ceph:ceph /etc/ceph
fi

# Restore CRUSH map
log_message "Restoring CRUSH map"
if [ -f "$BACKUP_DIR/crushmap.bin" ]; then
    ceph osd setcrushmap -i "$BACKUP_DIR/crushmap.bin"
fi

# Display recovery information
log_message "Recovery information available:"
log_message "- Monitor dump: $BACKUP_DIR/mon-dump.txt"
log_message "- OSD dump: $BACKUP_DIR/osd-dump.txt"
log_message "- Configuration: $BACKUP_DIR/config-dump.txt"
log_message "- Health report: $BACKUP_DIR/health-detail.txt"

log_message "Manual steps required:"
log_message "1. Review cluster maps in backup directory"
log_message "2. Recreate OSDs if necessary"
log_message "3. Restart Ceph services"
log_message "4. Verify cluster health"

log_message "Disaster recovery preparation completed"
Make the script executable:
sudo chmod +x scripts/ceph-recovery.sh
Subtask 3.2: Create Test Disaster Scenario
Create a test pool with data:
# Create test pool
sudo ceph osd pool create test-recovery 32 32

# Create test data
sudo rados -p test-recovery put test-object-1 /etc/hostname
sudo rados -p test-recovery put test-object-2 /etc/hosts

# Verify test data
sudo rados -p test-recovery ls
Create a backup of current state:
sudo /opt/ceph-backups/ceph-backup.sh
Simulate disaster by removing test data:
# Remove test objects
sudo rados -p test-recovery rm test-object-1
sudo rados -p test-recovery rm test-object-2

# Verify data is gone
sudo rados -p test-recovery ls
Subtask 3.3: Perform Recovery Test
Find the latest backup:
LATEST_BACKUP=$(ls -t /opt/ceph-backups/daily/ceph-backup-*.tar.gz | head -1)
echo "Latest backup: $LATEST_BACKUP"
Run the recovery script:
sudo /opt/ceph-recovery/scripts/ceph-recovery.sh "$LATEST_BACKUP"
Review recovery logs:
sudo tail -f /opt/ceph-recovery/logs/recovery-*.log
Subtask 3.4: Create Recovery Validation Script
Create validation script:
sudo vim /opt/ceph-recovery/scripts/validate-recovery.sh
Add the following content:
#!/bin/bash

# Ceph Recovery Validation Script
VALIDATION_LOG="/opt/ceph-recovery/logs/validation-$(date +%Y-%m-%d_%H-%M-%S).log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$VALIDATION_LOG"
}

log_message "Starting recovery validation"

# Check cluster health
log_message "Checking cluster health"
HEALTH_STATUS=$(ceph health)
log_message "Cluster health: $HEALTH_STATUS"

# Check monitor status
log_message "Checking monitor status"
ceph mon stat | tee -a "$VALIDATION_LOG"

# Check OSD status
log_message "Checking OSD status"
ceph osd stat | tee -a "$VALIDATION_LOG"

# Check pool status
log_message "Checking pool status"
ceph df | tee -a "$VALIDATION_LOG"

# Test data operations
log_message "Testing data operations"
TEST_POOL="recovery-test-$(date +%s)"
ceph osd pool create "$TEST_POOL" 8 8

# Write test data
echo "Recovery test data" | rados -p "$TEST_POOL" put recovery-test-object -

# Read test data
RECOVERED_DATA=$(rados -p "$TEST_POOL" get recovery-test-object -)
if [ "$RECOVERED_DATA" = "Recovery test data" ]; then
    log_message "SUCCESS: Data operations working correctly"
else
    log_message "ERROR: Data operations failed"
fi

# Cleanup test pool
ceph osd pool delete "$TEST_POOL" "$TEST_POOL" --yes-i-really-really-mean-it

log_message "Recovery validation completed"
log_message "Check log file for detailed results: $VALIDATION_LOG"
Make the script executable:
sudo chmod +x /opt/ceph-recovery/scripts/validate-recovery.sh
Run validation:
sudo /opt/ceph-recovery/scripts/validate-recovery.sh
Subtask 3.5: Create Recovery Playbook
Create Ansible recovery playbook:
vim /opt/ansible-ceph-backup/ceph-recovery-playbook.yml
Add the following content:
---
- name: Ceph Disaster Recovery Automation
  hosts: ceph_admin
  become: yes
  vars:
    recovery_base_dir: "/opt/ceph-recovery"
    backup_source: "{{ backup_file | default('latest') }}"
    
  tasks:
    - name: Ensure recovery directories exist
      file:
        path: "{{ item }}"
        state: directory
        owner: ceph
        group: ceph
        mode: '0755'
      loop:
        - "{{ recovery_base_dir }}/logs"
        - "{{ recovery_base_dir }}/temp"
        - "{{ recovery_base_dir }}/scripts"

    - name: Find latest backup if not specified
      find:
        paths: "/opt/ceph-backups/daily"
        patterns: "ceph-backup-*.tar.gz"
        age: -7d
      register: available_backups
      when: backup_source == "latest"

    - name: Set backup file path
      set_fact:
        backup_file_path: "{{ (available_backups.files | sort(attribute='mtime') | last).path }}"
      when: backup_source == "latest" and available_backups.files | length > 0

    - name: Verify backup file exists
      stat:
        path: "{{ backup_file_path | default(backup_source) }}"
      register: backup_file_stat

    - name: Fail if backup file not found
      fail:
        msg: "Backup file not found: {{ backup_file_path | default(backup_source) }}"
      when: not backup_file_stat.stat.exists

    - name: Extract backup archive
      unarchive:
        src: "{{ backup_file_path | default(backup_source) }}"
        dest: "{{ recovery_base_dir }}/temp"
        remote_src: yes
        owner: ceph
        group: ceph

    - name: Find extracted backup directory
      find:
        paths: "{{ recovery_base_dir }}/temp"
        file_type: directory
        patterns: "20*"
      register: backup_dirs

    - name: Set backup directory
      set_fact:
        backup_dir: "{{ backup_dirs.files[0].path }}"
      when: backup_dirs.files | length > 0

    - name: Display recovery information
      debug:
        msg:
          - "Backup file: {{ backup_file_path | default(backup_source) }}"
          - "Backup directory: {{ backup_dir }}"
          - "Recovery logs: {{ recovery_base_dir }}/logs"

    - name: Create recovery report
      template:
        src: recovery-report.j2
        dest: "{{ recovery_base_dir }}/recovery-report-{{ ansible_date_time.date }}.txt"
      vars:
        backup_file: "{{ backup_file_path | default(backup_source) }}"
        recovery_time: "{{ ansible_date_time.iso8601 }}"
Troubleshooting Common Issues
Issue 1: Backup Script Permissions
Problem: Backup script fails with permission denied errors.

Solution:

# Fix script permissions
sudo chmod +x /opt/ceph-backups/*.sh
sudo chown ceph:ceph /opt/ceph-backups/*.sh

# Fix directory permissions
sudo chown -R ceph:ceph /opt/ceph-backups
sudo chmod -R 755 /opt/ceph-backups
Issue 2: Ansible Connection Issues
Problem: Ansible cannot connect to Ceph nodes.

Solution:

# Test connectivity
ansible all -m ping

# Check SSH keys
ssh-copy-id ceph@ceph-mon-01
ssh-copy-id ceph@ceph-osd-01

# Verify inventory
ansible-inventory --list
Issue 3: Backup Storage Space
Problem: Insufficient space for backups.

Solution:

# Check disk usage
df -h /opt/ceph-backups

# Clean old backups
find /opt/ceph-backups/daily -name "*.tar.gz" -mtime +7 -delete

# Compress backups more efficiently
tar -czf backup.tar.gz --exclude='*.tmp' backup-directory/
Issue 4: Recovery Validation Failures
Problem: Recovery validation shows cluster issues.

Solution:

# Check cluster status
ceph status
ceph health detail

# Restart services if needed
sudo systemctl restart ceph-mon@$(hostname)
sudo systemctl restart ceph-mgr@$(hostname)

# Verify configuration
ceph config dump
Best Practices and Security Considerations
Backup Security
Encrypt backup files using GPG or similar tools
Store backups in multiple locations (local and remote)
Implement access controls on backup directories
Regular testing of backup integrity
Automation Security
Use Ansible Vault for sensitive variables
Implement proper SSH key management
Monitor backup job execution and failures
Set up alerting for backup failures
Recovery Planning
Document recovery procedures clearly
Test recovery processes regularly
Maintain updated contact information
Keep recovery tools and scripts current
Conclusion
In this comprehensive lab, you have successfully:

Created comprehensive backup solutions for Ceph clusters, including both metadata and configuration backups
Implemented automation using Ansible to ensure consistent and reliable backup operations
Developed disaster recovery procedures with proper testing and validation mechanisms
Established monitoring and alerting for backup operations to ensure business continuity
This lab demonstrates critical skills for maintaining production Ceph storage systems. The automated backup and recovery procedures you've implemented provide essential protection against data loss and system failures. These skills are directly applicable to real-world scenarios where storage reliability and data protection are paramount.

The combination of manual scripts and Ansible automation provides both flexibility and reliability, while the comprehensive testing procedures ensure that your disaster recovery plans will work when needed. Regular practice of these procedures and continuous improvement of your backup strategies will help maintain robust and reliable storage infrastructure.

Remember that backup and disaster recovery is an ongoing process that requires regular testing, monitoring, and updates to remain effective as your infrastructure evolves.
