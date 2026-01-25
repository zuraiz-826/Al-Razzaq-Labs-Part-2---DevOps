Lab 7: Automating Software Installation with Ansible
Objectives
By the end of this lab, students will be able to:

Create and execute Ansible playbooks for automated software installation
Utilize the dnf/yum module for efficient package management on Red Hat-based systems
Implement version control strategies for software packages
Configure automated package upgrades using Ansible
Apply best practices for infrastructure automation and configuration management
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Knowledge of Red Hat-based Linux distributions (CentOS, RHEL, Fedora)
Understanding of SSH key-based authentication
Basic networking concepts (IP addresses, hostnames)
Note: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines.

Lab Environment Setup
Your Al Nafi cloud environment includes:

Control Node: CentOS/RHEL 8 or 9 with Ansible pre-installed
Managed Nodes: 2-3 target servers for package installation
Network Configuration: All nodes can communicate via SSH
User Access: Root or sudo privileges on all systems
Task 1: Setting Up Ansible Environment and Inventory
Subtask 1.1: Verify Ansible Installation
First, let's confirm that Ansible is properly installed and check the version.

# Check Ansible version
ansible --version

# Verify Ansible configuration
ansible-config view
Subtask 1.2: Create Project Directory Structure
Organize your Ansible project with a proper directory structure.

# Create main project directory
mkdir -p ~/ansible-lab7
cd ~/ansible-lab7

# Create subdirectories for organization
mkdir -p {playbooks,inventory,group_vars,host_vars,roles}

# Create initial files
touch inventory/hosts.yml
touch ansible.cfg
Subtask 1.3: Configure Ansible Settings
Create a custom Ansible configuration file for this lab.

# Create ansible.cfg file
cat > ansible.cfg << 'EOF'
[defaults]
inventory = inventory/hosts.yml
remote_user = root
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = memory

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF
Subtask 1.4: Create Inventory File
Set up your inventory with the managed nodes provided in your lab environment.

# Create inventory file with your lab nodes
cat > inventory/hosts.yml << 'EOF'
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.10
        web2:
          ansible_host: 192.168.1.11
    databases:
      hosts:
        db1:
          ansible_host: 192.168.1.20
    development:
      hosts:
        dev1:
          ansible_host: 192.168.1.30
  vars:
    ansible_user: root
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
EOF
Note: Replace the IP addresses with the actual IPs provided in your Al Nafi lab environment.

Subtask 1.5: Test Connectivity
Verify that Ansible can connect to all managed nodes.

# Test connection to all hosts
ansible all -m ping

# Check if all hosts are reachable
ansible all -m setup --tree /tmp/facts
Task 2: Writing Playbooks for Package Installation
Subtask 2.1: Create Basic Package Installation Playbook
Create your first playbook to install essential packages across different server groups.

# Create basic package installation playbook
cat > playbooks/install-packages.yml << 'EOF'
---
- name: Install and Configure Essential Packages
  hosts: all
  become: yes
  gather_facts: yes
  
  vars:
    common_packages:
      - vim
      - curl
      - wget
      - git
      - htop
    
  tasks:
    - name: Update package cache (DNF/YUM)
      dnf:
        update_cache: yes
      when: ansible_os_family == "RedHat"
    
    - name: Install common packages
      dnf:
        name: "{{ common_packages }}"
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Verify package installation
      command: rpm -q {{ item }}
      loop: "{{ common_packages }}"
      register: package_check
      failed_when: package_check.rc != 0
      changed_when: false
EOF
Subtask 2.2: Create Web Server Specific Playbook
Develop a specialized playbook for web server package installation.

# Create web server playbook
cat > playbooks/webserver-setup.yml << 'EOF'
---
- name: Configure Web Servers with Apache and PHP
  hosts: webservers
  become: yes
  gather_facts: yes
  
  vars:
    web_packages:
      - httpd
      - php
      - php-mysql
      - php-fpm
      - mod_ssl
    
    apache_service: httpd
    
  tasks:
    - name: Install web server packages
      dnf:
        name: "{{ web_packages }}"
        state: present
      notify: restart apache
    
    - name: Start and enable Apache service
      systemd:
        name: "{{ apache_service }}"
        state: started
        enabled: yes
    
    - name: Configure firewall for HTTP and HTTPS
      firewalld:
        service: "{{ item }}"
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - http
        - https
      ignore_errors: yes
    
    - name: Create a simple index.html
      copy:
        content: |
          <html>
          <head><title>Ansible Managed Server</title></head>
          <body>
          <h1>Welcome to {{ inventory_hostname }}</h1>
          <p>This server was configured by Ansible</p>
          <p>Server IP: {{ ansible_default_ipv4.address }}</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: apache
        group: apache
        mode: '0644'
      notify: restart apache
  
  handlers:
    - name: restart apache
      systemd:
        name: "{{ apache_service }}"
        state: restarted
EOF
Subtask 2.3: Create Database Server Playbook
Build a playbook specifically for database server configuration.

# Create database server playbook
cat > playbooks/database-setup.yml << 'EOF'
---
- name: Configure Database Servers with MariaDB
  hosts: databases
  become: yes
  gather_facts: yes
  
  vars:
    db_packages:
      - mariadb-server
      - mariadb
      - python3-PyMySQL
    
    mysql_root_password: "SecurePassword123!"
    
  tasks:
    - name: Install MariaDB packages
      dnf:
        name: "{{ db_packages }}"
        state: present
      notify: restart mariadb
    
    - name: Start and enable MariaDB service
      systemd:
        name: mariadb
        state: started
        enabled: yes
    
    - name: Configure firewall for MySQL
      firewalld:
        port: 3306/tcp
        permanent: yes
        state: enabled
        immediate: yes
      ignore_errors: yes
    
    - name: Set MySQL root password
      mysql_user:
        name: root
        password: "{{ mysql_root_password }}"
        login_unix_socket: /var/lib/mysql/mysql.sock
        state: present
      ignore_errors: yes
    
    - name: Create .my.cnf file for root user
      copy:
        content: |
          [client]
          user=root
          password={{ mysql_root_password }}
        dest: /root/.my.cnf
        owner: root
        group: root
        mode: '0600'
  
  handlers:
    - name: restart mariadb
      systemd:
        name: mariadb
        state: restarted
EOF
Task 3: Implementing DNF/YUM Module Best Practices
Subtask 3.1: Advanced Package Management Playbook
Create a comprehensive playbook demonstrating advanced dnf/yum module usage.

# Create advanced package management playbook
cat > playbooks/advanced-package-management.yml << 'EOF'
---
- name: Advanced Package Management with DNF/YUM
  hosts: all
  become: yes
  gather_facts: yes
  
  vars:
    packages_to_install:
      - name: development-tools
        state: present
        type: group
      - name: nginx
        state: present
        type: package
      - name: nodejs
        state: present
        type: package
        version: "16*"
    
    packages_to_remove:
      - sendmail
      - postfix
    
    repositories:
      - name: epel-release
        state: present
    
  tasks:
    - name: Install EPEL repository
      dnf:
        name: epel-release
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Install package groups
      dnf:
        name: "{{ item.name }}"
        state: "{{ item.state }}"
      loop: "{{ packages_to_install }}"
      when: 
        - item.type == "group"
        - ansible_os_family == "RedHat"
    
    - name: Install specific package versions
      dnf:
        name: "{{ item.name }}-{{ item.version | default('*') }}"
        state: "{{ item.state }}"
      loop: "{{ packages_to_install }}"
      when: 
        - item.type == "package"
        - ansible_os_family == "RedHat"
    
    - name: Remove unwanted packages
      dnf:
        name: "{{ packages_to_remove }}"
        state: absent
      when: ansible_os_family == "RedHat"
    
    - name: Clean package cache
      dnf:
        autoremove: yes
        update_cache: yes
      when: ansible_os_family == "RedHat"
    
    - name: Check for available updates
      dnf:
        list: updates
      register: available_updates
      when: ansible_os_family == "RedHat"
    
    - name: Display available updates
      debug:
        msg: "Available updates: {{ available_updates.results | length }}"
      when: 
        - ansible_os_family == "RedHat"
        - available_updates is defined
EOF
Subtask 3.2: Create Package Version Control Playbook
Implement version control and upgrade strategies.

# Create version control playbook
cat > playbooks/version-control.yml << 'EOF'
---
- name: Package Version Control and Upgrade Management
  hosts: all
  become: yes
  gather_facts: yes
  
  vars:
    controlled_packages:
      - name: kernel
        state: latest
        update_only: yes
      - name: openssl
        state: latest
        security_only: yes
      - name: httpd
        state: present
        version: "2.4*"
        hold_version: no
    
    exclude_packages:
      - kernel-debug
      - kernel-devel
    
  tasks:
    - name: Create DNF configuration for version control
      copy:
        content: |
          [main]
          gpgcheck=1
          installonly_limit=3
          clean_requirements_on_remove=True
          best=True
          skip_if_unavailable=False
          exclude={{ exclude_packages | join(' ') }}
        dest: /etc/dnf/dnf.conf
        backup: yes
      when: ansible_os_family == "RedHat"
    
    - name: Install specific package versions
      dnf:
        name: "{{ item.name }}{% if item.version is defined %}-{{ item.version }}{% endif %}"
        state: "{{ item.state }}"
        update_only: "{{ item.update_only | default(false) }}"
      loop: "{{ controlled_packages }}"
      when: ansible_os_family == "RedHat"
    
    - name: Check current package versions
      shell: rpm -qa | grep -E "{{ controlled_packages | map(attribute='name') | join('|') }}"
      register: current_versions
      changed_when: false
    
    - name: Display current package versions
      debug:
        msg: "Current versions: {{ current_versions.stdout_lines }}"
    
    - name: Create package version report
      copy:
        content: |
          Package Version Report - {{ ansible_date_time.iso8601 }}
          ================================================
          Hostname: {{ inventory_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          
          Installed Packages:
          {% for line in current_versions.stdout_lines %}
          {{ line }}
          {% endfor %}
        dest: /tmp/package-report-{{ inventory_hostname }}.txt
      delegate_to: localhost
EOF
Task 4: Implementing Automated Upgrades and Maintenance
Subtask 4.1: Create Automated Update Playbook
Develop a playbook for automated system updates with safety checks.

# Create automated update playbook
cat > playbooks/automated-updates.yml << 'EOF'
---
- name: Automated System Updates with Safety Checks
  hosts: all
  become: yes
  gather_facts: yes
  serial: 1  # Update one host at a time for safety
  
  vars:
    update_types:
      - security
      - bugfix
    
    reboot_required_packages:
      - kernel
      - glibc
      - systemd
    
    maintenance_window:
      start_hour: 2
      end_hour: 4
    
  pre_tasks:
    - name: Check if system is in maintenance window
      fail:
        msg: "Updates can only be performed between {{ maintenance_window.start_hour }}:00 and {{ maintenance_window.end_hour }}:00"
      when: 
        - ansible_date_time.hour | int < maintenance_window.start_hour
        - ansible_date_time.hour | int > maintenance_window.end_hour
      tags: never  # Skip this check by default
    
    - name: Create pre-update system snapshot
      shell: |
        df -h > /tmp/pre-update-disk-usage.txt
        rpm -qa | sort > /tmp/pre-update-packages.txt
        systemctl list-units --state=active > /tmp/pre-update-services.txt
      changed_when: false
  
  tasks:
    - name: Check for available security updates
      dnf:
        security: yes
        list: updates
      register: security_updates
      when: ansible_os_family == "RedHat"
    
    - name: Install security updates only
      dnf:
        name: "*"
        state: latest
        security: yes
        update_only: yes
      register: security_update_result
      when: 
        - ansible_os_family == "RedHat"
        - security_updates.results | length > 0
    
    - name: Check for available bugfix updates
      dnf:
        bugfix: yes
        list: updates
      register: bugfix_updates
      when: ansible_os_family == "RedHat"
    
    - name: Install bugfix updates
      dnf:
        name: "*"
        state: latest
        bugfix: yes
        update_only: yes
      register: bugfix_update_result
      when: 
        - ansible_os_family == "RedHat"
        - bugfix_updates.results | length > 0
    
    - name: Check if reboot is required
      shell: |
        if [ -f /var/run/reboot-required ]; then
          echo "reboot_required"
        elif rpm -q --last kernel | head -1 | grep "$(date +%a\ %b\ %d)" > /dev/null; then
          echo "reboot_required"
        else
          echo "no_reboot_required"
        fi
      register: reboot_check
      changed_when: false
    
    - name: Create post-update system snapshot
      shell: |
        df -h > /tmp/post-update-disk-usage.txt
        rpm -qa | sort > /tmp/post-update-packages.txt
        systemctl list-units --state=active > /tmp/post-update-services.txt
      changed_when: false
    
    - name: Generate update report
      template:
        src: update-report.j2
        dest: /tmp/update-report-{{ ansible_date_time.epoch }}.txt
      vars:
        security_updates_installed: "{{ security_update_result.changed | default(false) }}"
        bugfix_updates_installed: "{{ bugfix_update_result.changed | default(false) }}"
        reboot_required: "{{ reboot_check.stdout == 'reboot_required' }}"
  
  post_tasks:
    - name: Schedule reboot if required
      reboot:
        reboot_timeout: 300
        connect_timeout: 20
        test_command: uptime
      when: 
        - reboot_check.stdout == "reboot_required"
        - ansible_reboot_required | default(false)
      tags: never  # Manual tag to control reboots
EOF
Subtask 4.2: Create Update Report Template
Create a template for generating detailed update reports.

# Create templates directory and update report template
mkdir -p templates

cat > templates/update-report.j2 << 'EOF'
System Update Report
====================
Date: {{ ansible_date_time.iso8601 }}
Hostname: {{ inventory_hostname }}
IP Address: {{ ansible_default_ipv4.address }}
OS: {{ ansible_distribution }} {{ ansible_distribution_version }}

Update Summary:
- Security Updates Installed: {{ security_updates_installed | ternary('Yes', 'No') }}
- Bugfix Updates Installed: {{ bugfix_updates_installed | ternary('Yes', 'No') }}
- Reboot Required: {{ reboot_required | ternary('Yes', 'No') }}

System Information:
- Kernel Version: {{ ansible_kernel }}
- Architecture: {{ ansible_architecture }}
- Memory: {{ ansible_memtotal_mb }} MB
- CPU Cores: {{ ansible_processor_vcpus }}

Package Statistics:
- Total Packages Before: {{ ansible_pkg_mgr_packages | length if ansible_pkg_mgr_packages is defined else 'N/A' }}

Services Status:
{% for service in ansible_facts.services.keys() | list | sort %}
{% if ansible_facts.services[service].state == 'running' %}
- {{ service }}: {{ ansible_facts.services[service].state }}
{% endif %}
{% endfor %}

Disk Usage:
{% for mount in ansible_mounts %}
- {{ mount.mount }}: {{ mount.size_available | filesizeformat }} available of {{ mount.size_total | filesizeformat }}
{% endfor %}
EOF
Subtask 4.3: Execute and Test All Playbooks
Now let's run all the playbooks we've created and verify their functionality.

# Run the basic package installation playbook
ansible-playbook playbooks/install-packages.yml -v

# Run web server setup (only on webserver group)
ansible-playbook playbooks/webserver-setup.yml -v

# Run database setup (only on database group)
ansible-playbook playbooks/database-setup.yml -v

# Run advanced package management
ansible-playbook playbooks/advanced-package-management.yml -v

# Run version control playbook
ansible-playbook playbooks/version-control.yml -v

# Test the automated updates playbook (dry run first)
ansible-playbook playbooks/automated-updates.yml --check -v

# Run actual updates (uncomment when ready)
# ansible-playbook playbooks/automated-updates.yml -v
Subtask 4.4: Verify Installation and Configuration
Create verification scripts to ensure everything is working correctly.

# Create verification playbook
cat > playbooks/verify-installation.yml << 'EOF'
---
- name: Verify Package Installation and Configuration
  hosts: all
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Check if common packages are installed
      package_facts:
        manager: rpm
    
    - name: Verify essential packages
      assert:
        that:
          - "'vim' in ansible_facts.packages"
          - "'curl' in ansible_facts.packages"
          - "'wget' in ansible_facts.packages"
          - "'git' in ansible_facts.packages"
        fail_msg: "One or more essential packages are missing"
        success_msg: "All essential packages are installed"
    
    - name: Check web server status (webservers only)
      systemd:
        name: httpd
      register: httpd_status
      when: inventory_hostname in groups['webservers']
    
    - name: Verify web server is running
      assert:
        that:
          - httpd_status.status.ActiveState == "active"
        fail_msg: "Apache web server is not running"
        success_msg: "Apache web server is running correctly"
      when: inventory_hostname in groups['webservers']
    
    - name: Check database server status (databases only)
      systemd:
        name: mariadb
      register: mariadb_status
      when: inventory_hostname in groups['databases']
    
    - name: Verify database server is running
      assert:
        that:
          - mariadb_status.status.ActiveState == "active"
        fail_msg: "MariaDB database server is not running"
        success_msg: "MariaDB database server is running correctly"
      when: inventory_hostname in groups['databases']
    
    - name: Generate verification report
      copy:
        content: |
          Verification Report - {{ ansible_date_time.iso8601 }}
          =============================================
          Hostname: {{ inventory_hostname }}
          Status: PASSED
          
          Installed Packages: {{ ansible_facts.packages.keys() | list | length }}
          Services Running: {{ ansible_facts.services.keys() | select('match', '.*running.*') | list | length }}
          
          System Health: OK
        dest: /tmp/verification-report-{{ inventory_hostname }}.txt
EOF

# Run verification
ansible-playbook playbooks/verify-installation.yml -v
Troubleshooting Common Issues
Issue 1: SSH Connection Problems
If you encounter SSH connection issues:

# Test SSH connectivity manually
ssh -i ~/.ssh/id_rsa root@target_host

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Verify SSH agent
ssh-add ~/.ssh/id_rsa
Issue 2: Package Installation Failures
For package installation problems:

# Check repository configuration
ansible all -m shell -a "dnf repolist"

# Clear package cache
ansible all -m shell -a "dnf clean all"

# Check disk space
ansible all -m shell -a "df -h"
Issue 3: Service Start Failures
When services fail to start:

# Check service status
ansible all -m shell -a "systemctl status httpd"

# View service logs
ansible all -m shell -a "journalctl -u httpd -n 20"

# Check firewall settings
ansible all -m shell -a "firewall-cmd --list-all"
Issue 4: Playbook Syntax Errors
To debug playbook syntax:

# Check playbook syntax
ansible-playbook playbooks/install-packages.yml --syntax-check

# Run in check mode first
ansible-playbook playbooks/install-packages.yml --check

# Use verbose output for debugging
ansible-playbook playbooks/install-packages.yml -vvv
Best Practices Summary
Security Best Practices
Always use become: yes for tasks requiring elevated privileges
Store sensitive data in Ansible Vault encrypted files
Use SSH key authentication instead of passwords
Implement least privilege principle for user access
Performance Optimization
Use serial execution for critical updates to minimize downtime
Implement fact caching to reduce gathering overhead
Use pipelining in SSH connections for faster execution
Group related tasks using blocks and tags
Maintenance and Monitoring
Create comprehensive logging for all automation activities
Implement rollback procedures for failed deployments
Use check mode for testing before actual execution
Maintain version control for all playbooks and configurations
Conclusion
In this comprehensive lab, you have successfully learned to automate software installation and configuration using Ansible. You have accomplished the following key objectives:

Technical Skills Developed:

Created multiple Ansible playbooks for different server roles and purposes
Mastered the dnf/yum module for advanced package management on Red Hat-based systems
Implemented version control strategies for maintaining consistent software versions
Developed automated update procedures with safety checks and rollback capabilities
Practical Applications:

Web Server Automation: Automated Apache and PHP installation with proper configuration
Database Server Setup: Implemented MariaDB installation with security configurations
System Maintenance: Created automated update procedures with maintenance windows
Monitoring and Reporting: Developed comprehensive reporting mechanisms for tracking changes
Professional Benefits: This lab directly prepares you for Red Hat Certified Engineer (RHCE) certification requirements and provides real-world skills essential for:

DevOps Engineering roles requiring infrastructure automation
System Administration positions managing large server fleets
Cloud Operations teams implementing Infrastructure as Code practices
Site Reliability Engineering roles focusing on automated maintenance
Industry Relevance: The automation techniques learned in this lab are fundamental to modern IT operations, enabling organizations to:

Reduce manual errors through consistent, repeatable processes
Scale infrastructure efficiently across multiple environments
Improve security posture through standardized configurations
Minimize downtime with automated maintenance procedures
By mastering these Ansible automation techniques, you have gained valuable skills that are highly sought after in today's technology landscape, particularly in environments requiring reliable, scalable, and maintainable infrastructure management.
