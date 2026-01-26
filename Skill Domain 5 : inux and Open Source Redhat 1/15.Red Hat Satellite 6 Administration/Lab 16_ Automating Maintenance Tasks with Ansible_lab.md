Lab 16: Automating Maintenance Tasks with Ansible
Objectives
By the end of this lab, students will be able to:

Create and execute Ansible playbooks for Red Hat Satellite maintenance tasks
Automate backup processes for Red Hat Satellite using Ansible
Implement automated patch management workflows with Ansible
Test and validate automated maintenance processes
Understand best practices for Ansible automation in enterprise environments
Configure scheduled maintenance tasks using Ansible and cron
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Basic knowledge of Red Hat Satellite 6 concepts
Understanding of SSH key-based authentication
Basic networking concepts (IP addresses, ports, protocols)
Text editor experience (vi/vim or nano)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or install software.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Satellite Server: Red Hat Satellite 6 simulation environment
Managed Nodes: Multiple client systems for testing
All necessary SSH keys and network connectivity pre-configured
Task 1: Setting Up Ansible Environment and Creating Basic Playbooks
Subtask 1.1: Verify Ansible Installation and Configuration
First, let's verify that Ansible is properly installed and configured in your environment.

Connect to your control node and verify Ansible installation:
ansible --version
Check the Ansible configuration file:
cat /etc/ansible/ansible.cfg
Verify the inventory file:
cat /etc/ansible/hosts
Test connectivity to managed nodes:
ansible all -m ping
Subtask 1.2: Create Directory Structure for Satellite Automation
Organize your Ansible playbooks with a proper directory structure.

Create the main project directory:
mkdir -p ~/satellite-automation
cd ~/satellite-automation
Create subdirectories for organization:
mkdir -p {playbooks,roles,inventory,group_vars,host_vars,files,templates}
Create the inventory file for Satellite servers:
cat > inventory/satellite_hosts << 'EOF'
[satellite_servers]
satellite.example.com ansible_host=192.168.1.100 ansible_user=root

[satellite_clients]
client1.example.com ansible_host=192.168.1.101 ansible_user=root
client2.example.com ansible_host=192.168.1.102 ansible_user=root

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
Subtask 1.3: Create Basic Satellite Health Check Playbook
Create a foundational playbook to check Satellite server health.

Create the health check playbook:
cat > playbooks/satellite_health_check.yml << 'EOF'
---
- name: Red Hat Satellite Health Check
  hosts: satellite_servers
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Check Satellite services status
      systemd:
        name: "{{ item }}"
        state: started
      register: service_status
      failed_when: false
      loop:
        - foreman
        - httpd
        - postgresql
        - pulp_workers
        - pulp_celerybeat
        - pulp_resource_manager
    
    - name: Display service status
      debug:
        msg: "Service {{ item.item }} is {{ item.state }}"
      loop: "{{ service_status.results }}"
    
    - name: Check disk space
      shell: df -h /var/lib/pulp
      register: disk_space
    
    - name: Display disk usage
      debug:
        msg: "Pulp storage usage: {{ disk_space.stdout }}"
    
    - name: Check Satellite version
      shell: satellite-maintain service status
      register: satellite_status
      failed_when: false
    
    - name: Display Satellite status
      debug:
        msg: "{{ satellite_status.stdout }}"
    
    - name: Check database connections
      shell: sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
      register: db_connections
      failed_when: false
    
    - name: Display database connection count
      debug:
        msg: "Active database connections: {{ db_connections.stdout }}"
EOF
Test the health check playbook:
ansible-playbook -i inventory/satellite_hosts playbooks/satellite_health_check.yml
Task 2: Automating Backup Tasks with Ansible
Subtask 2.1: Create Satellite Backup Playbook
Develop a comprehensive backup solution for Red Hat Satellite.

Create the backup configuration file:
cat > group_vars/satellite_servers.yml << 'EOF'
# Satellite Backup Configuration
backup_base_dir: /var/satellite-backups
backup_retention_days: 30
backup_timestamp: "{{ ansible_date_time.year }}{{ ansible_date_time.month }}{{ ansible_date_time.day }}_{{ ansible_date_time.hour }}{{ ansible_date_time.minute }}"
backup_dir: "{{ backup_base_dir }}/backup_{{ backup_timestamp }}"

# Backup components
backup_database: true
backup_pulp_content: true
backup_configuration: true

# Notification settings
notification_email: admin@example.com
smtp_server: localhost
EOF
Create the main backup playbook:
cat > playbooks/satellite_backup.yml << 'EOF'
---
- name: Red Hat Satellite Backup Automation
  hosts: satellite_servers
  become: yes
  gather_facts: yes
  vars_files:
    - ../group_vars/satellite_servers.yml
  
  pre_tasks:
    - name: Create backup directory
      file:
        path: "{{ backup_dir }}"
        state: directory
        mode: '0755'
        owner: root
        group: root
    
    - name: Check available disk space
      shell: df -BG {{ backup_base_dir }} | awk 'NR==2 {print $4}' | sed 's/G//'
      register: available_space
    
    - name: Ensure sufficient disk space (minimum 50GB)
      fail:
        msg: "Insufficient disk space. Available: {{ available_space.stdout }}GB, Required: 50GB"
      when: available_space.stdout|int < 50
  
  tasks:
    - name: Stop Satellite services for consistent backup
      systemd:
        name: "{{ item }}"
        state: stopped
      loop:
        - foreman
        - httpd
        - pulp_workers
        - pulp_celerybeat
        - pulp_resource_manager
      register: stopped_services
    
    - name: Create database backup
      shell: |
        sudo -u postgres pg_dump foreman > {{ backup_dir }}/foreman_db_backup.sql
        sudo -u postgres pg_dump candlepin > {{ backup_dir }}/candlepin_db_backup.sql
      when: backup_database
    
    - name: Backup Satellite configuration files
      archive:
        path:
          - /etc/foreman
          - /etc/pulp
          - /etc/candlepin
          - /etc/httpd/conf.d
          - /etc/foreman-proxy
        dest: "{{ backup_dir }}/satellite_config_backup.tar.gz"
        format: gz
      when: backup_configuration
    
    - name: Backup SSL certificates
      archive:
        path:
          - /etc/pki/katello-certs-tools
          - /etc/pki/pulp
          - /root/ssl-build
        dest: "{{ backup_dir }}/ssl_certificates_backup.tar.gz"
        format: gz
        exclude_path:
          - /root/ssl-build/*.rpm
    
    - name: Create Pulp content backup (selective)
      shell: |
        rsync -av --progress /var/lib/pulp/content/ {{ backup_dir }}/pulp_content_backup/
      when: backup_pulp_content
      async: 3600
      poll: 30
    
    - name: Backup Foreman database dump with compression
      archive:
        path: "{{ backup_dir }}/foreman_db_backup.sql"
        dest: "{{ backup_dir }}/foreman_db_backup.sql.gz"
        format: gz
        remove: yes
    
    - name: Backup Candlepin database dump with compression
      archive:
        path: "{{ backup_dir }}/candlepin_db_backup.sql"
        dest: "{{ backup_dir }}/candlepin_db_backup.sql.gz"
        format: gz
        remove: yes
    
    - name: Create backup manifest file
      template:
        src: ../templates/backup_manifest.j2
        dest: "{{ backup_dir }}/backup_manifest.txt"
    
    - name: Calculate backup size
      shell: du -sh {{ backup_dir }}
      register: backup_size
    
    - name: Start Satellite services
      systemd:
        name: "{{ item.item }}"
        state: started
      loop: "{{ stopped_services.results }}"
      when: item.changed
    
    - name: Verify services are running
      systemd:
        name: "{{ item }}"
        state: started
      loop:
        - foreman
        - httpd
        - pulp_workers
        - pulp_celerybeat
        - pulp_resource_manager
    
    - name: Clean old backups
      find:
        paths: "{{ backup_base_dir }}"
        age: "{{ backup_retention_days }}d"
        file_type: directory
        patterns: "backup_*"
      register: old_backups
    
    - name: Remove old backup directories
      file:
        path: "{{ item.path }}"
        state: absent
      loop: "{{ old_backups.files }}"
    
    - name: Send backup completion notification
      mail:
        to: "{{ notification_email }}"
        subject: "Satellite Backup Completed - {{ inventory_hostname }}"
        body: |
          Satellite backup completed successfully.
          
          Backup Details:
          - Server: {{ inventory_hostname }}
          - Backup Directory: {{ backup_dir }}
          - Backup Size: {{ backup_size.stdout }}
          - Timestamp: {{ ansible_date_time.iso8601 }}
          
          Components backed up:
          - Database: {{ backup_database }}
          - Configuration: {{ backup_configuration }}
          - Pulp Content: {{ backup_pulp_content }}
        host: "{{ smtp_server }}"
      failed_when: false
EOF
Create the backup manifest template:
mkdir -p templates
cat > templates/backup_manifest.j2 << 'EOF'
Red Hat Satellite Backup Manifest
=================================

Backup Information:
- Server: {{ inventory_hostname }}
- Backup Date: {{ ansible_date_time.iso8601 }}
- Backup Directory: {{ backup_dir }}
- Ansible User: {{ ansible_user }}

System Information:
- OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
- Kernel: {{ ansible_kernel }}
- Architecture: {{ ansible_architecture }}
- Total Memory: {{ ansible_memtotal_mb }}MB

Backup Components:
- Database Backup: {{ backup_database }}
- Configuration Backup: {{ backup_configuration }}
- Pulp Content Backup: {{ backup_pulp_content }}

Files in this backup:
{% if backup_database %}
- foreman_db_backup.sql.gz
- candlepin_db_backup.sql.gz
{% endif %}
{% if backup_configuration %}
- satellite_config_backup.tar.gz
- ssl_certificates_backup.tar.gz
{% endif %}
{% if backup_pulp_content %}
- pulp_content_backup/ (directory)
{% endif %}

Restore Instructions:
1. Stop Satellite services
2. Restore database: gunzip -c foreman_db_backup.sql.gz | sudo -u postgres psql foreman
3. Restore configuration: tar -xzf satellite_config_backup.tar.gz -C /
4. Restore SSL certificates: tar -xzf ssl_certificates_backup.tar.gz -C /
5. Restore Pulp content: rsync -av pulp_content_backup/ /var/lib/pulp/content/
6. Start Satellite services
EOF
Subtask 2.2: Create Backup Verification Playbook
Create a playbook to verify backup integrity.

Create backup verification playbook:
cat > playbooks/verify_backup.yml << 'EOF'
---
- name: Verify Satellite Backup Integrity
  hosts: satellite_servers
  become: yes
  gather_facts: yes
  vars_files:
    - ../group_vars/satellite_servers.yml
  
  tasks:
    - name: Find latest backup directory
      find:
        paths: "{{ backup_base_dir }}"
        file_type: directory
        patterns: "backup_*"
      register: backup_dirs
    
    - name: Set latest backup directory
      set_fact:
        latest_backup: "{{ backup_dirs.files | sort(attribute='mtime') | last }}"
      when: backup_dirs.files | length > 0
    
    - name: Verify backup directory exists
      stat:
        path: "{{ latest_backup.path }}"
      register: backup_dir_stat
      when: latest_backup is defined
    
    - name: Check database backup files
      stat:
        path: "{{ latest_backup.path }}/{{ item }}"
      register: db_backup_files
      loop:
        - foreman_db_backup.sql.gz
        - candlepin_db_backup.sql.gz
      when: latest_backup is defined
    
    - name: Verify database backup file integrity
      shell: gunzip -t {{ latest_backup.path }}/{{ item }}
      register: db_integrity_check
      failed_when: false
      loop:
        - foreman_db_backup.sql.gz
        - candlepin_db_backup.sql.gz
      when: latest_backup is defined
    
    - name: Check configuration backup files
      stat:
        path: "{{ latest_backup.path }}/{{ item }}"
      register: config_backup_files
      loop:
        - satellite_config_backup.tar.gz
        - ssl_certificates_backup.tar.gz
      when: latest_backup is defined
    
    - name: Verify configuration backup integrity
      shell: tar -tzf {{ latest_backup.path }}/{{ item }} > /dev/null
      register: config_integrity_check
      failed_when: false
      loop:
        - satellite_config_backup.tar.gz
        - ssl_certificates_backup.tar.gz
      when: latest_backup is defined
    
    - name: Generate backup verification report
      template:
        src: ../templates/backup_verification_report.j2
        dest: "{{ latest_backup.path }}/verification_report.txt"
      when: latest_backup is defined
    
    - name: Display verification summary
      debug:
        msg: |
          Backup Verification Summary:
          - Backup Directory: {{ latest_backup.path if latest_backup is defined else 'No backup found' }}
          - Database Backups: {{ 'OK' if db_integrity_check.results | selectattr('rc', 'equalto', 0) | list | length == 2 else 'FAILED' }}
          - Configuration Backups: {{ 'OK' if config_integrity_check.results | selectattr('rc', 'equalto', 0) | list | length == 2 else 'FAILED' }}
      when: latest_backup is defined
EOF
Create verification report template:
cat > templates/backup_verification_report.j2 << 'EOF'
Satellite Backup Verification Report
====================================

Verification Date: {{ ansible_date_time.iso8601 }}
Backup Directory: {{ latest_backup.path }}

Database Backup Verification:
{% for result in db_integrity_check.results %}
- {{ result.item }}: {{ 'PASSED' if result.rc == 0 else 'FAILED' }}
{% endfor %}

Configuration Backup Verification:
{% for result in config_integrity_check.results %}
- {{ result.item }}: {{ 'PASSED' if result.rc == 0 else 'FAILED' }}
{% endfor %}

File Sizes:
{% for file in db_backup_files.results + config_backup_files.results %}
{% if file.stat.exists %}
- {{ file.item }}: {{ (file.stat.size / 1024 / 1024) | round(2) }}MB
{% endif %}
{% endfor %}

Overall Status: {{ 'BACKUP VERIFIED' if (db_integrity_check.results | selectattr('rc', 'equalto', 0) | list | length == 2) and (config_integrity_check.results | selectattr('rc', 'equalto', 0) | list | length == 2) else 'VERIFICATION FAILED' }}
EOF
Task 3: Automating Patch Management with Ansible
Subtask 3.1: Create Patch Management Playbook
Develop an automated patch management solution for Satellite and managed systems.

Create patch management configuration:
cat > group_vars/all.yml << 'EOF'
# Patch Management Configuration
patch_management:
  maintenance_window: "02:00-04:00"
  reboot_required: true
  pre_patch_snapshot: true
  rollback_enabled: true
  notification_enabled: true
  
# Package management
exclude_packages:
  - kernel*
  - satellite*
  - foreman*

# Reboot configuration
reboot_timeout: 600
reboot_delay: 30

# Notification settings
patch_notification_email: patches@example.com
EOF
Create the main patch management playbook:
cat > playbooks/satellite_patch_management.yml << 'EOF'
---
- name: Satellite Server Patch Management
  hosts: satellite_servers
  become: yes
  gather_facts: yes
  vars_files:
    - ../group_vars/all.yml
    - ../group_vars/satellite_servers.yml
  
  pre_tasks:
    - name: Check current time against maintenance window
      set_fact:
        current_hour: "{{ ansible_date_time.hour | int }}"
        maintenance_start: "{{ patch_management.maintenance_window.split('-')[0].split(':')[0] | int }}"
        maintenance_end: "{{ patch_management.maintenance_window.split('-')[1].split(':')[0] | int }}"
    
    - name: Verify maintenance window
      fail:
        msg: "Current time {{ current_hour }}:00 is outside maintenance window {{ patch_management.maintenance_window }}"
      when: current_hour < maintenance_start or current_hour >= maintenance_end
    
    - name: Create pre-patch backup
      include_tasks: ../playbooks/satellite_backup.yml
      when: patch_management.pre_patch_snapshot
  
  tasks:
    - name: Get list of available updates
      yum:
        list: updates
      register: available_updates
    
    - name: Display available updates
      debug:
        msg: "{{ available_updates.results | length }} updates available"
    
    - name: Create patch report directory
      file:
        path: /var/log/satellite-patches
        state: directory
        mode: '0755'
    
    - name: Generate pre-patch system report
      shell: |
        echo "Pre-Patch System Report - $(date)" > /var/log/satellite-patches/pre-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "=================================" >> /var/log/satellite-patches/pre-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "Hostname: $(hostname)" >> /var/log/satellite-patches/pre-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "Kernel Version: $(uname -r)" >> /var/log/satellite-patches/pre-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "Uptime: $(uptime)" >> /var/log/satellite-patches/pre-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "Available Updates:" >> /var/log/satellite-patches/pre-patch-report-{{ ansible_date_time.epoch }}.txt
        yum list updates >> /var/log/satellite-patches/pre-patch-report-{{ ansible_date_time.epoch }}.txt 2>&1
    
    - name: Stop Satellite services before patching
      systemd:
        name: "{{ item }}"
        state: stopped
      loop:
        - foreman
        - httpd
        - pulp_workers
        - pulp_celerybeat
        - pulp_resource_manager
      register: stopped_services_patch
    
    - name: Update system packages (excluding critical packages)
      yum:
        name: "*"
        state: latest
        exclude: "{{ exclude_packages | join(',') }}"
        update_cache: yes
      register: patch_result
    
    - name: Update Satellite-specific packages separately
      yum:
        name: "{{ item }}"
        state: latest
      loop:
        - satellite
        - foreman
        - katello
      register: satellite_patch_result
      failed_when: false
    
    - name: Start Satellite services after patching
      systemd:
        name: "{{ item.item }}"
        state: started
      loop: "{{ stopped_services_patch.results }}"
      when: item.changed
    
    - name: Wait for services to be fully operational
      wait_for:
        port: 443
        host: "{{ ansible_default_ipv4.address }}"
        delay: 30
        timeout: 300
    
    - name: Run satellite-maintain health check
      shell: satellite-maintain health check
      register: health_check_result
      failed_when: false
    
    - name: Generate post-patch system report
      shell: |
        echo "Post-Patch System Report - $(date)" > /var/log/satellite-patches/post-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "==================================" >> /var/log/satellite-patches/post-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "Hostname: $(hostname)" >> /var/log/satellite-patches/post-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "Kernel Version: $(uname -r)" >> /var/log/satellite-patches/post-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "Uptime: $(uptime)" >> /var/log/satellite-patches/post-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "Patch Results:" >> /var/log/satellite-patches/post-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "{{ patch_result }}" >> /var/log/satellite-patches/post-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "Health Check Results:" >> /var/log/satellite-patches/post-patch-report-{{ ansible_date_time.epoch }}.txt
        echo "{{ health_check_result.stdout }}" >> /var/log/satellite-patches/post-patch-report-{{ ansible_date_time.epoch }}.txt
    
    - name: Check if reboot is required
      stat:
        path: /var/run/reboot-required
      register: reboot_required_file
    
    - name: Reboot server if required
      reboot:
        reboot_timeout: "{{ reboot_timeout }}"
        pre_reboot_delay: "{{ reboot_delay }}"
        msg: "Rebooting for kernel updates"
      when: 
        - patch_management.reboot_required
        - reboot_required_file.stat.exists or patch_result.changed
    
    - name: Wait for Satellite services after reboot
      wait_for:
        port: 443
        host: "{{ ansible_default_ipv4.address }}"
        delay: 60
        timeout: 600
      when: 
        - patch_management.reboot_required
        - reboot_required_file.stat.exists or patch_result.changed
    
    - name: Final health check after reboot
      shell: satellite-maintain health check
      register: final_health_check
      failed_when: false
      when: 
        - patch_management.reboot_required
        - reboot_required_file.stat.exists or patch_result.changed
    
    - name: Send patch completion notification
      mail:
        to: "{{ patch_notification_email }}"
        subject: "Satellite Patch Management Completed - {{ inventory_hostname }}"
        body: |
          Satellite patch management completed.
          
          Server: {{ inventory_hostname }}
          Patch Date: {{ ansible_date_time.iso8601 }}
          
          Patch Summary:
          - Packages Updated: {{ patch_result.changed }}
          - Reboot Required: {{ reboot_required_file.stat.exists | default(false) }}
          - Services Status: {{ 'Healthy' if health_check_result.rc == 0 else 'Issues Detected' }}
          
          Detailed reports available at: /var/log/satellite-patches/
        host: "{{ smtp_server }}"
      when: patch_management.notification_enabled
      failed_when: false
EOF
Subtask 3.2: Create Client Systems Patch Management
Create a playbook to manage patches on Satellite client systems.

Create client patch management playbook:
cat > playbooks/client_patch_management.yml << 'EOF'
---
- name: Client Systems Patch Management
  hosts: satellite_clients
  become: yes
  gather_facts: yes
  serial: 2  # Patch 2 systems at a time
  vars_files:
    - ../group_vars/all.yml
  
  pre_tasks:
    - name: Check system connectivity
      ping:
    
    - name: Verify subscription status
      shell: subscription-manager status
      register: subscription_status
      failed_when: false
    
    - name: Display subscription status
      debug:
        msg: "Subscription status: {{ subscription_status.stdout }}"
  
  tasks:
    - name: Create client patch log directory
      file:
        path: /var/log/client-patches
        state: directory
        mode: '0755'
    
    - name: Generate pre-patch inventory
      shell: |
        echo "Pre-Patch Inventory - $(date)" > /var/log/client-patches/pre-patch-{{ ansible_date_time.epoch }}.log
        echo "=============================" >> /var/log/client-patches/pre-patch-{{ ansible_date_time.epoch }}.log
        echo "Hostname: $(hostname)" >> /var/log/client-patches/pre-patch-{{ ansible_date_time.epoch }}.log
        echo "IP Address: {{ ansible_default_ipv4.address }}" >> /var/log/client-patches/pre-patch-{{ ansible_date_time.epoch }}.log
        echo "OS Version: {{ ansible_distribution }} {{ ansible_distribution_version }}" >> /var/log/client-patches/pre-patch-{{ ansible_date_time.epoch }}.log
        echo "Kernel: $(uname -r)" >> /var/log/client-patches/pre-patch-{{ ansible_date_time.epoch }}.log
        echo "Uptime: $(uptime)" >> /var/log/client-patches/pre-patch-{{ ansible_date_time.epoch }}.log
        echo "Available Updates:" >> /var/log/client-patches/pre-patch-{{ ansible_date_time.epoch }}.log
        yum list updates >> /var/log/client-patches/pre-patch-{{ ansible_date_time.epoch }}.log 2>&1
    
    - name: Check for available updates
      yum:
        list: updates
      register: client_updates
    
    - name: Skip patching if no updates available
      meta: end_host
      when: client_updates.results | length == 0
    
    - name: Update all packages
      yum:
        name: "*"
        state: latest
        update_cache: yes
      register: client_patch_result
    
    - name: Check if reboot is required
      shell: |
        if [ -f /var/run/reboot-required ]; then
          echo "reboot_required"
        elif rpm -q --last kernel | head -1 | grep "$(date +%a\ %b\ %d)" > /dev/null; then
          echo "kernel_updated"
        else
          echo "no_reboot_needed"
        fi
      register: reboot_check
    
    - name: Generate post-patch report
      shell: |
        echo "Post-Patch Report - $(date)" > /var/log/client-patches/post-patch-{{ ansible_date_time.epoch }}.log
        echo "============================" >> /var/log/client-patches/post-patch-{{ ansible_date_time.epoch }}.log
        echo "Hostname: $(hostname)" >> /var/log/client-patches/post-patch-{{ ansible_date_time.epoch }}.log
        echo "Packages Updated: {{ client_patch_result.changed }}" >> /var/log/client-patches/post-patch-{{ ansible_date_time.epoch }}.log
        echo "Reboot Status: {{ reboot_check.stdout }}" >> /var/log/client-patches/post-patch-{{ ansible_date_time.epoch }}.log
        echo "Current Kernel: $(uname -r)" >> /var/log/client-patches/post-patch-{{ ansible_date_time.epoch }}.log
    
    - name: Reboot client if required
      reboot:
        reboot_timeout: "{{ reboot_timeout }}"
        pre_reboot_delay: "{{ reboot_delay }}"
        msg: "Rebooting after patch installation"
      when: 
        - patch_management.reboot_required
        - reboot_check.stdout in ['reboot_required', 'kernel_updated']
    
    - name: Verify system after reboot
      wait_for_connection:
        delay: 30
        timeout: 300
      when: 
        - patch_management.reboot_required
        - reboot_check.stdout in ['reboot_required', 'kernel_updated']
    
    - name: Final system check
      shell: |
        echo "Final System Check - $(date)" >> /var/log/client-patches/post-patch-{{ ansible_date_time.epoch }}.log
        echo "Current Kernel: $(uname -r)" >> /var/log/client-patches/post-patch-{{ ansible_date_time.epoch }}.log
        echo "System Load: $(uptime)" >> /var/log/client-patches/post-patch-{{ ansible_date_time.epoch }}.log
        echo "Disk Usage: $(df -h /)" >> /var/log/client-patches/post-patch-{{ ansible_date_time.epoch }}.log
EOF
Task 4: Testing and Validating Automated Processes
Subtask 4.1: Create Comprehensive Testing Framework
Develop a testing framework to validate all automated processes.

Create the main testing playbook:
cat > playbooks/test_automation.yml << 'EOF'
---
- name: Test Satellite Automation Processes
  hosts: satellite_servers
  become: yes
  gather_facts: yes
  vars:
    test_results: []
  
  tasks:
    - name: Test 1 - Verify Ansible connectivity
      ping:
      register: connectivity_test
      failed_when: false
    
    - name: Record connectivity test result
      set_fact:
        test_results: "{{ test_results + [{'test': 'Connectivity Test', 'status': 'PASS' if connectivity_test.ping is defined else 'FAIL', 'details': connectivity_test}] }}"
    
    - name: Test 2 - Check Satellite services
      systemd:
        name: "{{ item }}"
      register: service_test
      failed_when
