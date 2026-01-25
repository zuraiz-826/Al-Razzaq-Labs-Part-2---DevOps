Lab 5: Automating File Management with Ansible
Objectives
By the end of this lab, you will be able to:

Automate file management tasks using Ansible playbooks
Copy files from local control machine to remote target systems
Create files and directories with specific content using copy and template modules
Modify existing files using the lineinfile module
Understand best practices for file management automation in enterprise environments
Apply file management concepts relevant to the Red Hat Certified Engineer (RHCE) exam
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Knowledge of Ansible fundamentals (inventory, playbooks, modules)
Understanding of file permissions and ownership in Linux
Completed previous Ansible labs or equivalent experience
Required Knowledge Areas:
Linux file system structure
Text editors (vi/vim or nano)
SSH connectivity concepts
Basic networking concepts
Lab Environment Setup
Good News! Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab and you'll have access to:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: Two target systems (node1 and node2) ready for automation
Network Configuration: All systems properly networked and accessible
SSH Keys: Pre-configured for passwordless authentication
No need to build your own virtual machines or configure networking!

Lab Architecture
Control Node (ansible-control)
├── Ansible Engine installed
├── SSH keys configured
└── Connected to managed nodes

Managed Nodes
├── node1 (192.168.1.10)
└── node2 (192.168.1.11)
Task 1: Write a Playbook to Copy Files from Local to Remote Machine
Task 1.1: Create the Lab Directory Structure
First, let's organize our lab workspace on the control node.

Connect to your control node and create the lab directory:
mkdir -p ~/ansible-lab5/files
cd ~/ansible-lab5
Create a sample file to copy to remote machines:
echo "Welcome to Ansible File Management Lab
This file was created on the control node
Date: $(date)
Lab: Automating File Management" > files/welcome.txt
Verify the file creation:
cat files/welcome.txt
Task 1.2: Create the Inventory File
Create an inventory file to define your managed nodes:

cat > inventory << EOF
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Task 1.3: Test Connectivity
Verify that Ansible can connect to your managed nodes:

ansible all -i inventory -m ping
Expected Output:

node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
node2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
Task 1.4: Create the File Copy Playbook
Create your first playbook to copy files from local to remote machines:

cat > copy-files-playbook.yml << 'EOF'
---
- name: Copy Files from Local to Remote Machines
  hosts: all
  become: yes
  vars:
    destination_path: /opt/lab-files
    
  tasks:
    - name: Create destination directory on remote machines
      file:
        path: "{{ destination_path }}"
        state: directory
        mode: '0755'
        owner: root
        group: root
      
    - name: Copy welcome file to remote machines
      copy:
        src: files/welcome.txt
        dest: "{{ destination_path }}/welcome.txt"
        mode: '0644'
        owner: root
        group: root
        backup: yes
      notify: Display copy status
      
    - name: Copy multiple files using with_items
      copy:
        content: "{{ item.content }}"
        dest: "{{ destination_path }}/{{ item.filename }}"
        mode: '0644'
        owner: root
        group: root
      with_items:
        - { filename: "server-info.txt", content: "Server: {{ inventory_hostname }}\nIP: {{ ansible_default_ipv4.address }}\nOS: {{ ansible_distribution }} {{ ansible_distribution_version }}" }
        - { filename: "lab-status.txt", content: "Lab 5: File Management\nStatus: In Progress\nStudent: {{ ansible_user }}" }
        
  handlers:
    - name: Display copy status
      debug:
        msg: "File successfully copied to {{ inventory_hostname }}"
EOF
Task 1.5: Execute the File Copy Playbook
Run the playbook to copy files to your managed nodes:

ansible-playbook -i inventory copy-files-playbook.yml
Task 1.6: Verify File Copy Results
Check that files were copied successfully:

ansible all -i inventory -m shell -a "ls -la /opt/lab-files/"
ansible all -i inventory -m shell -a "cat /opt/lab-files/welcome.txt"
Task 2: Create Files and Directories with Specific Content Using Copy and Template Modules
Task 2.1: Create Template Files
Templates allow dynamic content generation. Create a template directory and files:

mkdir -p templates
Create a Jinja2 template for system information:

cat > templates/system-report.j2 << 'EOF'
=== SYSTEM INFORMATION REPORT ===
Generated on: {{ ansible_date_time.date }} at {{ ansible_date_time.time }}
Hostname: {{ inventory_hostname }}
IP Address: {{ ansible_default_ipv4.address }}
Operating System: {{ ansible_distribution }} {{ ansible_distribution_version }}
Architecture: {{ ansible_architecture }}
CPU Cores: {{ ansible_processor_vcpus }}
Memory: {{ ansible_memtotal_mb }} MB
Disk Usage: {{ ansible_mounts[0].size_total // 1024 // 1024 // 1024 }} GB

=== NETWORK INTERFACES ===
{% for interface in ansible_interfaces %}
{% if interface != 'lo' %}
Interface: {{ interface }}
{% if ansible_facts[interface]['ipv4'] is defined %}
IP: {{ ansible_facts[interface]['ipv4']['address'] }}
Netmask: {{ ansible_facts[interface]['ipv4']['netmask'] }}
{% endif %}
{% endif %}
{% endfor %}

=== MOUNTED FILESYSTEMS ===
{% for mount in ansible_mounts %}
Device: {{ mount.device }}
Mount Point: {{ mount.mount }}
Filesystem: {{ mount.fstype }}
Size: {{ (mount.size_total / 1024 / 1024 / 1024) | round(2) }} GB
Available: {{ (mount.size_available / 1024 / 1024 / 1024) | round(2) }} GB
{% endfor %}
EOF
Create a configuration template:

cat > templates/app-config.j2 << 'EOF'
# Application Configuration File
# Generated by Ansible on {{ ansible_date_time.iso8601 }}

[server]
hostname = {{ inventory_hostname }}
ip_address = {{ ansible_default_ipv4.address }}
port = {{ app_port | default(8080) }}
environment = {{ app_environment | default('production') }}

[database]
host = {{ db_host | default('localhost') }}
port = {{ db_port | default(5432) }}
name = {{ db_name | default('appdb') }}
user = {{ db_user | default('appuser') }}

[logging]
level = {{ log_level | default('INFO') }}
file = /var/log/{{ app_name | default('myapp') }}.log
max_size = {{ log_max_size | default('10MB') }}

[features]
debug_mode = {{ debug_mode | default('false') }}
cache_enabled = {{ cache_enabled | default('true') }}
ssl_enabled = {{ ssl_enabled | default('true') }}
EOF
Task 2.2: Create the Template and Directory Management Playbook
cat > template-management-playbook.yml << 'EOF'
---
- name: Create Files and Directories with Templates and Copy Module
  hosts: all
  become: yes
  vars:
    app_name: "lab-application"
    app_port: 9090
    app_environment: "development"
    db_host: "db.example.com"
    db_name: "lab_database"
    log_level: "DEBUG"
    debug_mode: "true"
    
  tasks:
    - name: Create application directory structure
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
        owner: root
        group: root
      loop:
        - /opt/lab-app
        - /opt/lab-app/config
        - /opt/lab-app/logs
        - /opt/lab-app/data
        - /opt/lab-app/scripts
        - /var/log/lab-app
        
    - name: Generate system report using template
      template:
        src: templates/system-report.j2
        dest: /opt/lab-app/system-report.txt
        mode: '0644'
        owner: root
        group: root
        backup: yes
        
    - name: Generate application configuration using template
      template:
        src: templates/app-config.j2
        dest: /opt/lab-app/config/app.conf
        mode: '0600'
        owner: root
        group: root
        backup: yes
      notify: Restart application service
      
    - name: Create startup script using copy module with content
      copy:
        content: |
          #!/bin/bash
          # {{ app_name }} Startup Script
          # Generated by Ansible
          
          APP_HOME="/opt/lab-app"
          CONFIG_FILE="$APP_HOME/config/app.conf"
          LOG_FILE="/var/log/lab-app/startup.log"
          
          echo "$(date): Starting {{ app_name }}..." >> $LOG_FILE
          echo "$(date): Configuration file: $CONFIG_FILE" >> $LOG_FILE
          echo "$(date): Application home: $APP_HOME" >> $LOG_FILE
          echo "$(date): Server: {{ inventory_hostname }}" >> $LOG_FILE
          
          # Add your application startup commands here
          echo "$(date): {{ app_name }} startup script executed successfully" >> $LOG_FILE
        dest: /opt/lab-app/scripts/startup.sh
        mode: '0755'
        owner: root
        group: root
        
    - name: Create data files with specific content
      copy:
        content: "{{ item.content }}"
        dest: "/opt/lab-app/data/{{ item.filename }}"
        mode: '0644'
        owner: root
        group: root
      loop:
        - filename: "servers.txt"
          content: |
            # Server List for {{ app_name }}
            {% for host in groups['all'] %}
            {{ host }}: {{ hostvars[host]['ansible_default_ipv4']['address'] }}
            {% endfor %}
        - filename: "environment.txt"
          content: |
            Environment: {{ app_environment }}
            Debug Mode: {{ debug_mode }}
            Application: {{ app_name }}
            Generated: {{ ansible_date_time.iso8601 }}
            
    - name: Create README file with instructions
      copy:
        content: |
          # {{ app_name | upper }} - Lab 5 File Management
          
          ## Directory Structure
          ```
          /opt/lab-app/
          ├── config/          # Configuration files
          ├── data/            # Data files
          ├── logs/            # Application logs
          ├── scripts/         # Startup and utility scripts
          └── system-report.txt # System information
          ```
          
          ## Files Created
          - **system-report.txt**: Detailed system information
          - **config/app.conf**: Application configuration
          - **scripts/startup.sh**: Application startup script
          - **data/servers.txt**: Server inventory
          - **data/environment.txt**: Environment information
          
          ## Usage
          1. Review configuration: `cat config/app.conf`
          2. Check system info: `cat system-report.txt`
          3. Run startup script: `./scripts/startup.sh`
          
          Generated by Ansible on {{ ansible_date_time.iso8601 }}
          Target Host: {{ inventory_hostname }}
        dest: /opt/lab-app/README.md
        mode: '0644'
        owner: root
        group: root
        
  handlers:
    - name: Restart application service
      debug:
        msg: "Application configuration updated on {{ inventory_hostname }} - Service restart would occur here"
EOF
Task 2.3: Execute the Template Management Playbook
Run the playbook to create directories and files using templates:

ansible-playbook -i inventory template-management-playbook.yml
Task 2.4: Verify Template Results
Check the created directory structure:

ansible all -i inventory -m shell -a "find /opt/lab-app -type f -exec ls -la {} \;"
View the generated system report:

ansible all -i inventory -m shell -a "head -20 /opt/lab-app/system-report.txt"
Check the application configuration:

ansible all -i inventory -m shell -a "cat /opt/lab-app/config/app.conf"
Task 3: Modify Files Using the Lineinfile Module
Task 3.1: Create Files to Modify
First, create some configuration files that we'll modify:

cat > create-base-configs.yml << 'EOF'
---
- name: Create Base Configuration Files for Modification
  hosts: all
  become: yes
  
  tasks:
    - name: Create SSH configuration file
      copy:
        content: |
          # SSH Configuration File
          Port 22
          Protocol 2
          PermitRootLogin no
          PasswordAuthentication yes
          PubkeyAuthentication yes
          X11Forwarding no
          PrintMotd yes
          PrintLastLog yes
          TCPKeepAlive yes
          ClientAliveInterval 0
          ClientAliveCountMax 3
        dest: /etc/ssh/sshd_config_lab
        mode: '0644'
        owner: root
        group: root
        backup: yes
        
    - name: Create application properties file
      copy:
        content: |
          # Application Properties
          app.name=MyApplication
          app.version=1.0.0
          app.debug=false
          app.port=8080
          app.host=localhost
          
          # Database Configuration
          db.host=localhost
          db.port=5432
          db.name=myapp
          db.user=appuser
          
          # Logging Configuration
          log.level=INFO
          log.file=/var/log/myapp.log
          log.max.size=10MB
          
          # Security Settings
          security.enabled=true
          security.ssl=false
          security.timeout=3600
        dest: /opt/lab-app/config/application.properties
        mode: '0644'
        owner: root
        group: root
        
    - name: Create system configuration file
      copy:
        content: |
          # System Configuration
          HOSTNAME={{ inventory_hostname }}
          ENVIRONMENT=production
          MAX_CONNECTIONS=100
          TIMEOUT=30
          ENABLE_LOGGING=yes
          LOG_LEVEL=info
          BACKUP_ENABLED=no
          MONITORING=disabled
          
          # Network Settings
          NETWORK_INTERFACE=eth0
          IP_ADDRESS={{ ansible_default_ipv4.address }}
          NETMASK=255.255.255.0
          
          # Service Settings
          SERVICE_USER=appuser
          SERVICE_GROUP=appgroup
          SERVICE_HOME=/opt/lab-app
        dest: /opt/lab-app/config/system.conf
        mode: '0644'
        owner: root
        group: root
EOF
Execute the base configuration creation:

ansible-playbook -i inventory create-base-configs.yml
Task 3.2: Create the File Modification Playbook
Now create a comprehensive playbook using the lineinfile module:

cat > modify-files-playbook.yml << 'EOF'
---
- name: Modify Files Using Lineinfile Module
  hosts: all
  become: yes
  vars:
    new_ssh_port: 2222
    app_debug_mode: true
    environment_type: "development"
    
  tasks:
    - name: Modify SSH port in configuration
      lineinfile:
        path: /etc/ssh/sshd_config_lab
        regexp: '^Port\s+'
        line: 'Port {{ new_ssh_port }}'
        backup: yes
      notify: SSH config modified
      
    - name: Enable SSH X11 forwarding
      lineinfile:
        path: /etc/ssh/sshd_config_lab
        regexp: '^X11Forwarding\s+'
        line: 'X11Forwarding yes'
        backup: yes
        
    - name: Add new SSH security setting
      lineinfile:
        path: /etc/ssh/sshd_config_lab
        line: 'MaxAuthTries 3'
        insertafter: '^PermitRootLogin'
        create: yes
        
    - name: Modify application debug setting
      lineinfile:
        path: /opt/lab-app/config/application.properties
        regexp: '^app\.debug='
        line: 'app.debug={{ app_debug_mode | lower }}'
        backup: yes
        
    - name: Update application port
      lineinfile:
        path: /opt/lab-app/config/application.properties
        regexp: '^app\.port='
        line: 'app.port=9090'
        
    - name: Add new database connection pool setting
      lineinfile:
        path: /opt/lab-app/config/application.properties
        line: 'db.pool.max=20'
        insertafter: '^db\.user='
        
    - name: Enable SSL security
      lineinfile:
        path: /opt/lab-app/config/application.properties
        regexp: '^security\.ssl='
        line: 'security.ssl=true'
        
    - name: Change environment in system config
      lineinfile:
        path: /opt/lab-app/config/system.conf
        regexp: '^ENVIRONMENT='
        line: 'ENVIRONMENT={{ environment_type }}'
        backup: yes
        
    - name: Increase max connections
      lineinfile:
        path: /opt/lab-app/config/system.conf
        regexp: '^MAX_CONNECTIONS='
        line: 'MAX_CONNECTIONS=200'
        
    - name: Enable backup functionality
      lineinfile:
        path: /opt/lab-app/config/system.conf
        regexp: '^BACKUP_ENABLED='
        line: 'BACKUP_ENABLED=yes'
        
    - name: Add backup schedule setting
      lineinfile:
        path: /opt/lab-app/config/system.conf
        line: 'BACKUP_SCHEDULE=daily'
        insertafter: '^BACKUP_ENABLED='
        
    - name: Enable monitoring
      lineinfile:
        path: /opt/lab-app/config/system.conf
        regexp: '^MONITORING='
        line: 'MONITORING=enabled'
        
    - name: Add monitoring port
      lineinfile:
        path: /opt/lab-app/config/system.conf
        line: 'MONITORING_PORT=9999'
        insertafter: '^MONITORING='
        
    - name: Remove a specific line (disable password authentication)
      lineinfile:
        path: /etc/ssh/sshd_config_lab
        regexp: '^PasswordAuthentication yes'
        state: absent
        backup: yes
        
    - name: Add password authentication disabled
      lineinfile:
        path: /etc/ssh/sshd_config_lab
        line: 'PasswordAuthentication no'
        insertafter: '^PubkeyAuthentication'
        
    - name: Create modification summary file
      lineinfile:
        path: /opt/lab-app/modification-log.txt
        line: "{{ item }}"
        create: yes
        mode: '0644'
      loop:
        - "=== FILE MODIFICATION LOG ==="
        - "Date: {{ ansible_date_time.iso8601 }}"
        - "Host: {{ inventory_hostname }}"
        - "Modified by: Ansible Lab 5"
        - ""
        - "SSH Configuration Changes:"
        - "- Port changed to {{ new_ssh_port }}"
        - "- X11 forwarding enabled"
        - "- Max auth tries set to 3"
        - "- Password authentication disabled"
        - ""
        - "Application Configuration Changes:"
        - "- Debug mode: {{ app_debug_mode }}"
        - "- Port changed to 9090"
        - "- SSL enabled"
        - "- Database pool max set to 20"
        - ""
        - "System Configuration Changes:"
        - "- Environment: {{ environment_type }}"
        - "- Max connections: 200"
        - "- Backup enabled with daily schedule"
        - "- Monitoring enabled on port 9999"
        
  handlers:
    - name: SSH config modified
      debug:
        msg: "SSH configuration has been modified on {{ inventory_hostname }}"
EOF
Task 3.3: Execute the File Modification Playbook
Run the playbook to modify files using lineinfile:

ansible-playbook -i inventory modify-files-playbook.yml
Task 3.4: Verify File Modifications
Check the SSH configuration changes:

ansible all -i inventory -m shell -a "grep -E '^(Port|X11Forwarding|MaxAuthTries|PasswordAuthentication)' /etc/ssh/sshd_config_lab"
Verify application properties modifications:

ansible all -i inventory -m shell -a "grep -E '^(app\.|db\.pool|security\.ssl)' /opt/lab-app/config/application.properties"
Check system configuration changes:

ansible all -i inventory -m shell -a "grep -E '^(ENVIRONMENT|MAX_CONNECTIONS|BACKUP|MONITORING)' /opt/lab-app/config/system.conf"
View the modification log:

ansible all -i inventory -m shell -a "cat /opt/lab-app/modification-log.txt"
Task 3.5: Advanced Lineinfile Operations
Create an advanced modification playbook:

cat > advanced-lineinfile.yml << 'EOF'
---
- name: Advanced Lineinfile Operations
  hosts: all
  become: yes
  
  tasks:
    - name: Create a hosts file for modification
      copy:
        content: |
          127.0.0.1   localhost localhost.localdomain
          ::1         localhost localhost.localdomain
          
          # Lab servers
          192.168.1.10  node1.lab.local node1
          192.168.1.11  node2.lab.local node2
        dest: /opt/lab-app/hosts
        mode: '0644'
        
    - name: Add database server entry using backrefs
      lineinfile:
        path: /opt/lab-app/hosts
        regexp: '^(# Lab servers)$'
        line: '\1\n192.168.1.20  db.lab.local database'
        backrefs: yes
        
    - name: Insert multiple lines after a pattern
      lineinfile:
        path: /opt/lab-app/hosts
        insertafter: '^192\.168\.1\.20'
        line: "{{ item }}"
      loop:
        - "192.168.1.30  web.lab.local webserver"
        - "192.168.1.40  cache.lab.local redis"
        
    - name: Modify line with validation
      lineinfile:
        path: /opt/lab-app/config/application.properties
        regexp: '^log\.level='
        line: 'log.level=DEBUG'
        validate: 'grep -q "log.level=DEBUG" %s'
        backup: yes
        
    - name: Use lineinfile with complex regex
      lineinfile:
        path: /opt/lab-app/config/system.conf
        regexp: '^(SERVICE_USER=).*'
        line: '\1{{ ansible_user }}'
        backrefs: yes
        
    - name: Add line only if it doesn't exist
      lineinfile:
        path: /opt/lab-app/config/system.conf
        line: 'CUSTOM_SETTING=enabled'
        state: present
        
    - name: Create summary of advanced operations
      copy:
        content: |
          Advanced Lineinfile Operations Summary
          =====================================
          
          1. Used backrefs to modify existing lines while preserving parts
          2. Inserted multiple lines after a specific pattern
          3. Applied validation to ensure changes are correct
          4. Used complex regex patterns for precise matching
          5. Added lines conditionally (only if not present)
          
          Files Modified:
          - /opt/lab-app/hosts: Added server entries
          - /opt/lab-app/config/application.properties: Changed log level
          - /opt/lab-app/config/system.conf: Updated service user and added custom setting
          
          Generated on: {{ ansible_date_time.iso8601 }}
          Host: {{ inventory_hostname }}
        dest: /opt/lab-app/advanced-operations-summary.txt
        mode: '0644'
EOF
Execute the advanced operations:

ansible-playbook -i inventory advanced-lineinfile.yml
Task 4: Create a Comprehensive File Management Playbook
Task 4.1: Create the Master File Management Playbook
Combine all concepts into one comprehensive playbook:

cat > master-file-management.yml << 'EOF'
---
- name: Master File Management Playbook - Lab 5 Complete
  hosts: all
  become: yes
  vars:
    lab_name: "Ansible File Management Lab 5"
    lab_date: "{{ ansible_date_time.date }}"
    admin_email: "admin@lab.local"
    
  tasks:
    # Phase 1: Directory Structure Creation
    - name: Create comprehensive directory structure
      file:
        path: "{{ item.path }}"
        state: directory
        mode: "{{ item.mode }}"
        owner: "{{ item.owner | default('root') }}"
        group: "{{ item.group | default('root') }}"
      loop:
        - { path: "/opt/lab-final", mode: "0755" }
        - { path: "/opt/lab-final/config", mode: "0750" }
        - { path: "/opt/lab-final/data", mode: "0755" }
        - { path: "/opt/lab-final/logs", mode: "0755" }
        - { path: "/opt/lab-final/scripts", mode: "0755" }
        - { path: "/opt/lab-final/templates", mode: "0755" }
        - { path: "/opt/lab-final/backup", mode: "0700" }
        
    # Phase 2: File Copying Operations
    - name: Copy essential files from control node
      copy:
        src: "{{ item.src }}"
        dest: "{{ item.dest }}"
        mode: "{{ item.mode }}"
        backup: yes
      loop:
        - { src: "files/welcome.txt", dest: "/opt/lab-final/welcome.txt", mode: "0644" }
      when: item.src is exists
      ignore_errors: yes
      
    # Phase 3: Template-based File Generation
    - name: Generate configuration files from templates
      template:
        src: "{{ item.src }}"
        dest: "{{ item.dest }}"
        mode: "{{ item.mode }}"
        backup: yes
      loop:
        - { src: "templates/system-report.j2", dest: "/opt/lab-final/system-report.txt", mode: "0644" }
        - { src: "templates/app-config.j2", dest: "/opt/lab-final/config/final-app.conf", mode: "0600" }
      when: item.src is exists
      ignore_errors: yes
      
    # Phase 4: Dynamic Content Creation
    - name: Create files with dynamic content
      copy:
        content: "{{ item.content }}"
        dest: "{{ item.dest }}"
        mode: "{{ item.mode }}"
      loop:
        - dest: "/opt/lab-final/lab-info.txt"
          mode: "0644"
          content: |
            {{ lab_name }}
            =========================
            Date: {{ lab_date }}
            Host: {{ inventory_hostname }}
            IP: {{ ansible_default_ipv4.address }}
            OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
            Admin: {{ admin_email }}
            
            Lab Objectives Completed:
            ✓ File copying from local to remote
            ✓ Directory and file creation with templates
            ✓ File modification using lineinfile
            ✓ Advanced file management operations
            
        - dest: "/opt/lab-final/scripts/maintenance.sh"
          mode: "0755"
          content: |
            #!/bin/bash
            # Maintenance Script for {{ lab_name }}
            # Generated on {{ ansible_date_time.iso8601 }}
            
            LOG_FILE="/opt/lab-final/logs/maintenance.log"
            BACKUP_DIR="/opt/lab-final/backup"
            
            echo "$(date): Starting maintenance on {{ inventory_hostname }}" >> $LOG_FILE
            
            # Create backup of configuration files
            cp -r /opt/lab-final/config/* $BACKUP_DIR/ 2>/dev/null
            echo "$(date): Configuration backup completed" >> $LOG_FILE
            
            # Check disk space
            DISK_USAGE=$(df /opt | tail -1 | awk '{print $5}' | sed 's/%//')
            echo "$(date): Disk usage: ${DISK_USAGE}%" >> $LOG_FILE
            
            if [ $DISK_USAGE -gt 80 ]; then
                echo "$(date): WARNING: Disk usage is above 80%" >> $LOG_FILE
            fi
            
            echo "$(date): Maintenance completed successfully" >> $LOG_FILE
            
        - dest: "/opt/lab-final/data/inventory.json"
          mode: "0644"
          content: |
            {
              "lab_info": {
                "name": "{{ lab_name }}",
                "date": "{{ lab_date }}",
                "admin": "{{ admin_email }}"
              },
              "servers": [
            {% for host in groups['all'] %}
                {
                  "hostname": "{{ host }}",
                  "ip": "{{ hostvars[host]['ansible_default_ipv4']['address'] }}",
                  "os": "{{ hostvars[host]['ansible_distribution'] }} {{ hostvars[host]['ansible_distribution_version'] }}"
                }{% if not loop.last %},{% endif %}
            {% endfor %}
              ]
            }
            
    # Phase 5: File Modifications
    - name: Create base configuration for modification
      copy:
        content: |
          # Application Configuration
          app_name=FinalLabApp
          app_version=1.0.0
          app_port=8080
          app_debug=false
          app_environment=production
          
          # Database Settings
          db_host=localhost
          db_port=5432
          db_name=finallab
          
          # Security Settings
          security_enabled=true
          ssl_enabled=false
          max_connections=50
        dest: /opt/lab-final/config/app.properties
        mode: '0644'
        
    - name: Modify configuration using lineinfile
      lineinfile:
        path: /opt/lab-final/config/app.properties
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        backup: yes
      loop:
        - { regexp: '^app_port=', line: 'app_port=9090' }
        - { regexp: '^
