Lab 13: Automating MariaDB Backup and Restore
Objectives
By the end of this lab, students will be able to:

Create and configure Ansible playbooks for automated MariaDB database backups
Implement automated database restoration procedures using Ansible
Schedule and manage backup operations with proper error handling
Validate backup integrity and test restore functionality
Configure backup retention policies and storage management
Troubleshoot common backup and restore issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with MariaDB/MySQL database concepts
Basic knowledge of Ansible playbooks and YAML syntax
Understanding of cron jobs and task scheduling
Knowledge of file permissions and directory structures
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click "Start Lab" to begin - no need to build your own virtual machine or install software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
MariaDB Server pre-installed
Ansible pre-installed and configured
Sample databases for testing
Sufficient storage space for backups
Task 1: Write an Ansible Playbook to Back Up MariaDB Databases
Subtask 1.1: Prepare the Lab Environment
First, let's verify our environment and create the necessary directory structure.

Connect to your lab machine and verify MariaDB service:
sudo systemctl status mariadb
sudo systemctl start mariadb
sudo systemctl enable mariadb
Create directory structure for our Ansible project:
mkdir -p ~/mariadb-automation/{playbooks,roles,inventory,backups,scripts}
cd ~/mariadb-automation
Create the inventory file:
cat > inventory/hosts << 'EOF'
[database_servers]
localhost ansible_connection=local

[database_servers:vars]
ansible_user=root
ansible_become=yes
EOF
Subtask 1.2: Create Sample Databases for Testing
Connect to MariaDB and create test databases:
sudo mysql -u root << 'EOF'
CREATE DATABASE IF NOT EXISTS company_db;
CREATE DATABASE IF NOT EXISTS inventory_db;
CREATE DATABASE IF NOT EXISTS users_db;

USE company_db;
CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2)
);

INSERT INTO employees (name, department, salary) VALUES
('John Doe', 'IT', 75000.00),
('Jane Smith', 'HR', 65000.00),
('Mike Johnson', 'Finance', 80000.00);

USE inventory_db;
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    quantity INT,
    price DECIMAL(8,2)
);

INSERT INTO products (name, quantity, price) VALUES
('Laptop', 50, 999.99),
('Mouse', 200, 25.50),
('Keyboard', 150, 75.00);

USE users_db;
CREATE TABLE user_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    created_date DATE
);

INSERT INTO user_accounts (username, email, created_date) VALUES
('admin', 'admin@company.com', '2024-01-01'),
('user1', 'user1@company.com', '2024-01-15'),
('user2', 'user2@company.com', '2024-02-01');

FLUSH PRIVILEGES;
EOF
Subtask 1.3: Create the Main Backup Playbook
Create the primary backup playbook:
cat > playbooks/mariadb-backup.yml << 'EOF'
---
- name: MariaDB Database Backup Automation
  hosts: database_servers
  become: yes
  vars:
    backup_dir: "/opt/mariadb-backups"
    backup_retention_days: 7
    mysql_root_password: ""
    databases_to_backup:
      - company_db
      - inventory_db
      - users_db
    backup_timestamp: "{{ ansible_date_time.year }}{{ ansible_date_time.month }}{{ ansible_date_time.day }}_{{ ansible_date_time.hour }}{{ ansible_date_time.minute }}{{ ansible_date_time.second }}"
    
  tasks:
    - name: Create backup directory
      file:
        path: "{{ backup_dir }}"
        state: directory
        mode: '0755'
        owner: root
        group: root

    - name: Create daily backup subdirectory
      file:
        path: "{{ backup_dir }}/{{ ansible_date_time.date }}"
        state: directory
        mode: '0755'
        owner: root
        group: root

    - name: Install required packages
      package:
        name:
          - mariadb-client
          - gzip
        state: present

    - name: Check MariaDB service status
      systemd:
        name: mariadb
        state: started
      register: mariadb_status

    - name: Fail if MariaDB is not running
      fail:
        msg: "MariaDB service is not running"
      when: mariadb_status.state != "started"

    - name: Create individual database backups
      shell: |
        mysqldump --single-transaction --routines --triggers \
        -u root {{ '-p' + mysql_root_password if mysql_root_password else '' }} \
        {{ item }} | gzip > {{ backup_dir }}/{{ ansible_date_time.date }}/{{ item }}_{{ backup_timestamp }}.sql.gz
      loop: "{{ databases_to_backup }}"
      register: backup_results
      failed_when: backup_results.rc != 0

    - name: Create full database backup (all databases)
      shell: |
        mysqldump --single-transaction --routines --triggers --all-databases \
        -u root {{ '-p' + mysql_root_password if mysql_root_password else '' }} \
        | gzip > {{ backup_dir }}/{{ ansible_date_time.date }}/full_backup_{{ backup_timestamp }}.sql.gz
      register: full_backup_result
      failed_when: full_backup_result.rc != 0

    - name: Verify backup files exist and have content
      stat:
        path: "{{ backup_dir }}/{{ ansible_date_time.date }}/{{ item }}_{{ backup_timestamp }}.sql.gz"
      loop: "{{ databases_to_backup }}"
      register: backup_file_stats
      failed_when: not backup_file_stats.stat.exists or backup_file_stats.stat.size == 0

    - name: Create backup log entry
      lineinfile:
        path: "{{ backup_dir }}/backup.log"
        line: "{{ ansible_date_time.iso8601 }} - Backup completed successfully for databases: {{ databases_to_backup | join(', ') }}"
        create: yes
        mode: '0644'

    - name: Remove old backups (retention policy)
      find:
        paths: "{{ backup_dir }}"
        age: "{{ backup_retention_days }}d"
        recurse: yes
        file_type: directory
      register: old_backups

    - name: Delete old backup directories
      file:
        path: "{{ item.path }}"
        state: absent
      loop: "{{ old_backups.files }}"
      when: old_backups.files is defined

    - name: Display backup summary
      debug:
        msg: |
          Backup Summary:
          - Backup Location: {{ backup_dir }}/{{ ansible_date_time.date }}
          - Databases Backed Up: {{ databases_to_backup | join(', ') }}
          - Backup Timestamp: {{ backup_timestamp }}
          - Full Backup: full_backup_{{ backup_timestamp }}.sql.gz
EOF
Subtask 1.4: Create a Backup Configuration File
Create a configuration file for backup settings:
cat > playbooks/backup-config.yml << 'EOF'
---
# MariaDB Backup Configuration
backup_settings:
  backup_dir: "/opt/mariadb-backups"
  retention_days: 7
  compression: true
  verify_backups: true
  
database_config:
  mysql_root_password: ""
  backup_user: "backup_user"
  backup_password: "secure_backup_pass"
  
notification_settings:
  enable_email: false
  email_recipient: "admin@company.com"
  log_file: "/var/log/mariadb-backup.log"
EOF
Subtask 1.5: Test the Backup Playbook
Run the backup playbook:
cd ~/mariadb-automation
ansible-playbook -i inventory/hosts playbooks/mariadb-backup.yml -v
Verify the backup was created successfully:
ls -la /opt/mariadb-backups/
ls -la /opt/mariadb-backups/$(date +%Y-%m-%d)/
Check backup file sizes and content:
du -sh /opt/mariadb-backups/$(date +%Y-%m-%d)/*
zcat /opt/mariadb-backups/$(date +%Y-%m-%d)/company_db_*.sql.gz | head -20
Task 2: Automate the Restoration of Databases from Backups
Subtask 2.1: Create Database Restore Playbook
Create the restore playbook:
cat > playbooks/mariadb-restore.yml << 'EOF'
---
- name: MariaDB Database Restore Automation
  hosts: database_servers
  become: yes
  vars:
    backup_dir: "/opt/mariadb-backups"
    mysql_root_password: ""
    restore_date: "{{ restore_target_date | default(ansible_date_time.date) }}"
    
  tasks:
    - name: Prompt for restore confirmation
      pause:
        prompt: |
          WARNING: This will restore databases from backup!
          This operation will OVERWRITE existing data.
          Restore date: {{ restore_date }}
          
          Available backup dates:
          {{ ansible_date_time.date }}
          
          Type 'yes' to continue or 'no' to abort
      register: restore_confirmation
      when: force_restore is not defined

    - name: Abort if not confirmed
      fail:
        msg: "Restore operation aborted by user"
      when: 
        - force_restore is not defined
        - restore_confirmation.user_input != "yes"

    - name: Check if backup directory exists
      stat:
        path: "{{ backup_dir }}/{{ restore_date }}"
      register: backup_dir_stat

    - name: Fail if backup directory doesn't exist
      fail:
        msg: "Backup directory {{ backup_dir }}/{{ restore_date }} does not exist"
      when: not backup_dir_stat.stat.exists

    - name: List available backup files
      find:
        paths: "{{ backup_dir }}/{{ restore_date }}"
        patterns: "*.sql.gz"
      register: available_backups

    - name: Display available backups
      debug:
        msg: "Available backup files: {{ available_backups.files | map(attribute='path') | map('basename') | list }}"

    - name: Check MariaDB service status
      systemd:
        name: mariadb
        state: started
      register: mariadb_status

    - name: Create restore log entry - Start
      lineinfile:
        path: "{{ backup_dir }}/restore.log"
        line: "{{ ansible_date_time.iso8601 }} - Starting restore operation from {{ restore_date }}"
        create: yes
        mode: '0644'

    - name: Restore individual databases
      shell: |
        zcat {{ item.path }} | mysql -u root {{ '-p' + mysql_root_password if mysql_root_password else '' }}
      loop: "{{ available_backups.files }}"
      when: 
        - "'full_backup' not in item.path"
        - restore_type is not defined or restore_type == "individual"
      register: restore_results
      failed_when: restore_results.rc != 0

    - name: Restore from full backup
      shell: |
        zcat {{ backup_dir }}/{{ restore_date }}/full_backup_*.sql.gz | mysql -u root {{ '-p' + mysql_root_password if mysql_root_password else '' }}
      when: restore_type is defined and restore_type == "full"
      register: full_restore_result
      failed_when: full_restore_result.rc != 0

    - name: Verify database restoration
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        query: "SHOW DATABASES"
      register: databases_after_restore

    - name: Create restore log entry - Complete
      lineinfile:
        path: "{{ backup_dir }}/restore.log"
        line: "{{ ansible_date_time.iso8601 }} - Restore operation completed successfully"
        create: yes
        mode: '0644'

    - name: Display restore summary
      debug:
        msg: |
          Restore Summary:
          - Restore Date: {{ restore_date }}
          - Backup Source: {{ backup_dir }}/{{ restore_date }}
          - Databases Available: {{ databases_after_restore.query_result[0] | length }}
          - Restore Type: {{ restore_type | default('individual') }}
EOF
Subtask 2.2: Create Selective Restore Playbook
Create a playbook for restoring specific databases:
cat > playbooks/mariadb-selective-restore.yml << 'EOF'
---
- name: MariaDB Selective Database Restore
  hosts: database_servers
  become: yes
  vars:
    backup_dir: "/opt/mariadb-backups"
    mysql_root_password: ""
    restore_date: "{{ restore_target_date | default(ansible_date_time.date) }}"
    databases_to_restore: "{{ target_databases | default(['company_db']) }}"
    
  tasks:
    - name: Display restore parameters
      debug:
        msg: |
          Selective Restore Parameters:
          - Target Databases: {{ databases_to_restore }}
          - Restore Date: {{ restore_date }}
          - Backup Directory: {{ backup_dir }}/{{ restore_date }}

    - name: Check if backup files exist for target databases
      stat:
        path: "{{ backup_dir }}/{{ restore_date }}/{{ item }}_*.sql.gz"
      loop: "{{ databases_to_restore }}"
      register: backup_files_check

    - name: Find exact backup files for each database
      find:
        paths: "{{ backup_dir }}/{{ restore_date }}"
        patterns: "{{ item }}_*.sql.gz"
      loop: "{{ databases_to_restore }}"
      register: database_backup_files

    - name: Create backup of current databases before restore
      shell: |
        mysqldump --single-transaction -u root {{ '-p' + mysql_root_password if mysql_root_password else '' }} \
        {{ item }} | gzip > {{ backup_dir }}/pre_restore_{{ item }}_{{ ansible_date_time.epoch }}.sql.gz
      loop: "{{ databases_to_restore }}"
      ignore_errors: yes

    - name: Drop existing databases (if they exist)
      mysql_db:
        name: "{{ item }}"
        state: absent
        login_user: root
        login_password: "{{ mysql_root_password }}"
      loop: "{{ databases_to_restore }}"
      when: drop_before_restore | default(false) | bool

    - name: Restore selected databases
      shell: |
        zcat {{ item.files[0].path }} | mysql -u root {{ '-p' + mysql_root_password if mysql_root_password else '' }}
      loop: "{{ database_backup_files.results }}"
      when: item.files | length > 0
      register: selective_restore_results

    - name: Verify restored databases
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        query: "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = '{{ item }}'"
      loop: "{{ databases_to_restore }}"
      register: table_counts

    - name: Display verification results
      debug:
        msg: "Database {{ item.item }} has {{ item.query_result[0][0].table_count }} tables"
      loop: "{{ table_counts.results }}"
EOF
Subtask 2.3: Test Database Restoration
First, let's modify some data to test the restore:
sudo mysql -u root << 'EOF'
USE company_db;
DELETE FROM employees WHERE name = 'John Doe';
INSERT INTO employees (name, department, salary) VALUES ('Test User', 'Testing', 50000.00);
SELECT * FROM employees;
EOF
Run the restore playbook:
ansible-playbook -i inventory/hosts playbooks/mariadb-restore.yml -e "force_restore=true" -v
Verify the restoration worked:
sudo mysql -u root -e "USE company_db; SELECT * FROM employees;"
Task 3: Test Backup and Restore Functionality
Subtask 3.1: Create Comprehensive Testing Playbook
Create a testing playbook that validates backup and restore operations:
cat > playbooks/test-backup-restore.yml << 'EOF'
---
- name: Comprehensive Backup and Restore Testing
  hosts: database_servers
  become: yes
  vars:
    backup_dir: "/opt/mariadb-backups"
    mysql_root_password: ""
    test_database: "test_backup_db"
    
  tasks:
    - name: Create test database with sample data
      mysql_db:
        name: "{{ test_database }}"
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Create test table and insert data
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        login_db: "{{ test_database }}"
        query: |
          CREATE TABLE IF NOT EXISTS test_data (
            id INT AUTO_INCREMENT PRIMARY KEY,
            test_value VARCHAR(100),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
          
          INSERT INTO test_data (test_value) VALUES 
          ('Original Data 1'),
          ('Original Data 2'),
          ('Original Data 3');

    - name: Get original data count
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        login_db: "{{ test_database }}"
        query: "SELECT COUNT(*) as count FROM test_data"
      register: original_count

    - name: Display original data
      debug:
        msg: "Original record count: {{ original_count.query_result[0][0].count }}"

    - name: Run backup for test database
      shell: |
        mysqldump --single-transaction -u root {{ '-p' + mysql_root_password if mysql_root_password else '' }} \
        {{ test_database }} | gzip > {{ backup_dir }}/test_backup_{{ ansible_date_time.epoch }}.sql.gz
      register: test_backup_result

    - name: Verify backup file was created
      stat:
        path: "{{ backup_dir }}/test_backup_{{ ansible_date_time.epoch }}.sql.gz"
      register: backup_file_stat

    - name: Fail if backup file doesn't exist or is empty
      fail:
        msg: "Backup file was not created or is empty"
      when: not backup_file_stat.stat.exists or backup_file_stat.stat.size == 0

    - name: Modify test data (simulate data changes)
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        login_db: "{{ test_database }}"
        query: |
          DELETE FROM test_data WHERE id = 1;
          INSERT INTO test_data (test_value) VALUES ('Modified Data');
          UPDATE test_data SET test_value = 'Updated Data' WHERE id = 2;

    - name: Get modified data count
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        login_db: "{{ test_database }}"
        query: "SELECT COUNT(*) as count FROM test_data"
      register: modified_count

    - name: Display modified data count
      debug:
        msg: "Modified record count: {{ modified_count.query_result[0][0].count }}"

    - name: Drop test database to simulate data loss
      mysql_db:
        name: "{{ test_database }}"
        state: absent
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Verify database was dropped
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        query: "SHOW DATABASES LIKE '{{ test_database }}'"
      register: db_check_after_drop

    - name: Restore test database from backup
      shell: |
        zcat {{ backup_dir }}/test_backup_{{ ansible_date_time.epoch }}.sql.gz | mysql -u root {{ '-p' + mysql_root_password if mysql_root_password else '' }}
      register: restore_result

    - name: Verify database was restored
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        query: "SHOW DATABASES LIKE '{{ test_database }}'"
      register: db_check_after_restore

    - name: Get restored data count
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        login_db: "{{ test_database }}"
        query: "SELECT COUNT(*) as count FROM test_data"
      register: restored_count

    - name: Verify data integrity
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        login_db: "{{ test_database }}"
        query: "SELECT * FROM test_data ORDER BY id"
      register: restored_data

    - name: Display test results
      debug:
        msg: |
          Backup and Restore Test Results:
          - Original Count: {{ original_count.query_result[0][0].count }}
          - Modified Count: {{ modified_count.query_result[0][0].count }}
          - Restored Count: {{ restored_count.query_result[0][0].count }}
          - Data Integrity: {{ 'PASSED' if restored_count.query_result[0][0].count == original_count.query_result[0][0].count else 'FAILED' }}
          - Backup File Size: {{ backup_file_stat.stat.size }} bytes

    - name: Clean up test backup file
      file:
        path: "{{ backup_dir }}/test_backup_{{ ansible_date_time.epoch }}.sql.gz"
        state: absent

    - name: Test result summary
      debug:
        msg: |
          TEST SUMMARY:
          ✓ Backup Creation: {{ 'PASSED' if backup_file_stat.stat.exists else 'FAILED' }}
          ✓ Database Drop: {{ 'PASSED' if db_check_after_drop.query_result | length == 0 else 'FAILED' }}
          ✓ Database Restore: {{ 'PASSED' if db_check_after_restore.query_result | length > 0 else 'FAILED' }}
          ✓ Data Integrity: {{ 'PASSED' if restored_count.query_result[0][0].count == original_count.query_result[0][0].count else 'FAILED' }}
EOF
Subtask 3.2: Create Automated Backup Scheduling
Create a playbook to set up automated backups via cron:
cat > playbooks/schedule-backups.yml << 'EOF'
---
- name: Schedule Automated MariaDB Backups
  hosts: database_servers
  become: yes
  vars:
    backup_script_path: "/usr/local/bin/mariadb-backup.sh"
    
  tasks:
    - name: Create backup script
      copy:
        content: |
          #!/bin/bash
          # Automated MariaDB Backup Script
          
          BACKUP_DIR="/opt/mariadb-backups"
          DATE=$(date +%Y-%m-%d)
          TIMESTAMP=$(date +%Y%m%d_%H%M%S)
          DATABASES=("company_db" "inventory_db" "users_db")
          RETENTION_DAYS=7
          
          # Create backup directory
          mkdir -p "$BACKUP_DIR/$DATE"
          
          # Function to log messages
          log_message() {
              echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$BACKUP_DIR/backup.log"
          }
          
          log_message "Starting automated backup"
          
          # Backup individual databases
          for db in "${DATABASES[@]}"; do
              log_message "Backing up database: $db"
              mysqldump --single-transaction --routines --triggers -u root "$db" | gzip > "$BACKUP_DIR/$DATE/${db}_${TIMESTAMP}.sql.gz"
              
              if [ $? -eq 0 ]; then
                  log_message "Successfully backed up $db"
              else
                  log_message "ERROR: Failed to backup $db"
                  exit 1
              fi
          done
          
          # Create full backup
          log_message "Creating full backup"
          mysqldump --single-transaction --routines --triggers --all-databases -u root | gzip > "$BACKUP_DIR/$DATE/full_backup_${TIMESTAMP}.sql.gz"
          
          if [ $? -eq 0 ]; then
              log_message "Successfully created full backup"
          else
              log_message "ERROR: Failed to create full backup"
              exit 1
          fi
          
          # Clean up old backups
          log_message "Cleaning up backups older than $RETENTION_DAYS days"
          find "$BACKUP_DIR" -type d -name "20*" -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null
          
          log_message "Backup process completed successfully"
        dest: "{{ backup_script_path }}"
        mode: '0755'
        owner: root
        group: root

    - name: Schedule daily backup at 2 AM
      cron:
        name: "MariaDB Daily Backup"
        minute: "0"
        hour: "2"
        job: "{{ backup_script_path }}"
        user: root

    - name: Schedule weekly full backup on Sunday at 1 AM
      cron:
        name: "MariaDB Weekly Full Backup"
        minute: "0"
        hour: "1"
        weekday: "0"
        job: "{{ backup_script_path }}"
        user: root

    - name: Create backup monitoring script
      copy:
        content: |
          #!/bin/bash
          # Backup Monitoring Script
          
          BACKUP_DIR="/opt/mariadb-backups"
          TODAY=$(date +%Y-%m-%d)
          YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
          
          echo "=== MariaDB Backup Status Report ==="
          echo "Generated: $(date)"
          echo
          
          # Check today's backups
          if [ -d "$BACKUP_DIR/$TODAY" ]; then
              echo "✓ Today's backup directory exists: $BACKUP_DIR/$TODAY"
              echo "Files in today's backup:"
              ls -lh "$BACKUP_DIR/$TODAY/"
          else
              echo "✗ Today's backup directory missing: $BACKUP_DIR/$TODAY"
          fi
          
          echo
          
          # Check backup log
          if [ -f "$BACKUP_DIR/backup.log" ]; then
              echo "Recent backup log entries:"
              tail -10 "$BACKUP_DIR/backup.log"
          else
              echo "✗ Backup log file not found"
          fi
          
          echo
          echo "=== Disk Usage ==="
          du -sh "$BACKUP_DIR"/*
        dest: "/usr/local/bin/backup-status.sh"
        mode: '0755'
        owner: root
        group: root

    - name: Display scheduling information
      debug:
        msg: |
          Backup Scheduling Configured:
          - Daily backups: 2:00 AM
          - Weekly full backups: Sunday 1:00 AM
          - Backup script: {{ backup_script_path }}
          - Status script: /usr/local/bin/backup-status.sh
          
          To check backup status manually, run:
          /usr/local/bin/backup-status.sh
EOF
Subtask 3.3: Run Comprehensive Tests
Execute the comprehensive test:
ansible-playbook -i inventory/hosts playbooks/test-backup-restore.yml -v
Set up automated scheduling:
ansible-playbook -i inventory/hosts playbooks/schedule-backups.yml -v
Test the backup script manually:
sudo /usr/local/bin/mariadb-backup.sh
Check the backup status:
sudo /usr/local/bin/backup-status.sh
Verify cron jobs were created:
sudo crontab -l
Subtask 3.4: Performance and Integrity Testing
Create a performance testing script:
cat > scripts/backup-performance-test.sh << 'EOF'
#!/bin/bash

echo "=== MariaDB Backup Performance Test ==="
echo "Starting performance test at $(date)"

BACKUP_DIR="/opt/mariadb-backups/performance-test"
mkdir -p "$BACKUP_DIR"

# Test 1: Individual database backup timing
echo
echo "Test 1: Individual Database Backup Performance"
for db in company_db inventory_db users_db; do
    echo -n "Backing up $db... "
    start_time=$(date +%s.%N)
    mysqldump --single-transaction -u root "$db" | gzip > "$BACKUP_DIR/${db}_perf_test.sql.gz"
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    size=$(du -sh "$BACKUP_DIR/${db}_perf_test.sql.gz" | cut -f1)
    echo "Duration: ${duration}s, Size: $size"
done

# Test 2: Full backup timing
echo
echo "Test 2: Full Database Backup Performance"
echo -n "Creating full backup... "
start_time=$(date +%s.%N)
mysqldump --single-transaction --all-databases -u root | gzip > "$BACKUP_DIR/full_perf_test.sql.gz"
end_time=$(date +%s.%N)
duration=$(echo "$end_time - $start_time" | bc)
size=$(du -sh "$BACKUP_DIR/full_perf_test.sql.gz" | cut -f1)
echo "Duration: ${duration}s, Size: $size"

# Test 3: Backup integrity verification
echo
echo "Test 3: Backup Integrity Verification"
for backup_file in "$BACKUP_DIR"/*.sql.gz; do
    echo -n "Verifying $(basename "$backup_file")... "
    if zcat "$backup_file" | head -1 | grep -q "MySQL dump"; then
        echo "✓ Valid"
    else
        echo "✗ Invalid"
    fi
done

# Cleanup
rm -rf "$BACKUP_DIR"

echo
echo "Performance test completed at $(date)"
EOF

chmod +x scripts/backup-performance-test.sh
Run the performance test:
sudo ./scripts/backup-performance-test.sh
Troubleshooting Common Issues
