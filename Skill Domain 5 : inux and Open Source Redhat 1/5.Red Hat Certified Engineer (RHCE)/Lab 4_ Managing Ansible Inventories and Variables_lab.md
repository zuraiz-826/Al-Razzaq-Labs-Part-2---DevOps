Lab 4: Managing Ansible Inventories and Variables
Objectives
By the end of this lab, you will be able to:

Understand the difference between static and dynamic inventories in Ansible
Create and manage static inventory files with proper formatting
Configure host variables for different environments (development, staging, production)
Implement group variables to target specific sets of machines
Use variable precedence to control configuration inheritance
Apply best practices for organizing inventory structures in enterprise environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and formatting
Completed previous Ansible labs or equivalent knowledge of:
Ansible installation and configuration
Basic playbook creation and execution
SSH key-based authentication concepts
Text editor proficiency (nano, vim, or similar)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: 3 target servers representing different environments
Pre-configured SSH connectivity between all nodes
All necessary tools and dependencies installed
Task 1: Understanding and Creating Static Inventories
Subtask 1.1: Explore Default Inventory Structure
First, let's examine the default Ansible inventory configuration and understand how it works.

Connect to your control node and navigate to the Ansible configuration directory:
cd /etc/ansible
ls -la
Examine the default hosts file:
cat hosts
Create a working directory for this lab:
mkdir -p ~/ansible-lab4
cd ~/ansible-lab4
Subtask 1.2: Create a Basic Static Inventory
Now we'll create our first custom static inventory file.

Create a simple inventory file called inventory.ini:
nano inventory.ini
Add the following content to define your managed hosts:
# Basic Static Inventory for Lab 4
# Web Servers Group
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=centos
web2 ansible_host=192.168.1.11 ansible_user=centos

# Database Servers Group
[databases]
db1 ansible_host=192.168.1.20 ansible_user=centos
db2 ansible_host=192.168.1.21 ansible_user=centos

# Load Balancer Group
[loadbalancers]
lb1 ansible_host=192.168.1.30 ansible_user=centos

# Parent Groups
[frontend:children]
webservers
loadbalancers

[backend:children]
databases

# All Production Servers
[production:children]
frontend
backend
Save and exit the file (Ctrl+X, then Y, then Enter in nano).
Subtask 1.3: Test Your Static Inventory
Verify inventory syntax using the ansible-inventory command:
ansible-inventory -i inventory.ini --list
Test connectivity to all hosts in your inventory:
ansible -i inventory.ini all -m ping
Test specific groups:
ansible -i inventory.ini webservers -m ping
ansible -i inventory.ini databases -m ping
Task 2: Setting Up Host Variables for Different Environments
Subtask 2.1: Create Environment-Specific Inventories
We'll create separate inventory files for different environments to demonstrate how host variables work across environments.

Create a development environment inventory:
nano inventory-dev.ini
Add development-specific configuration:
# Development Environment Inventory
[webservers]
dev-web1 ansible_host=192.168.1.100 ansible_user=centos environment=development
dev-web2 ansible_host=192.168.1.101 ansible_user=centos environment=development

[databases]
dev-db1 ansible_host=192.168.1.110 ansible_user=centos environment=development

[loadbalancers]
dev-lb1 ansible_host=192.168.1.120 ansible_user=centos environment=development

# Development-specific variables
[webservers:vars]
http_port=8080
max_connections=50
debug_mode=true

[databases:vars]
db_port=3306
max_connections=100
backup_enabled=false

[all:vars]
ansible_ssh_private_key_file=~/.ssh/dev_key
log_level=debug
Create a production environment inventory:
nano inventory-prod.ini
Add production-specific configuration:
# Production Environment Inventory
[webservers]
prod-web1 ansible_host=10.0.1.10 ansible_user=centos environment=production
prod-web2 ansible_host=10.0.1.11 ansible_user=centos environment=production
prod-web3 ansible_host=10.0.1.12 ansible_user=centos environment=production

[databases]
prod-db1 ansible_host=10.0.1.20 ansible_user=centos environment=production
prod-db2 ansible_host=10.0.1.21 ansible_user=centos environment=production

[loadbalancers]
prod-lb1 ansible_host=10.0.1.30 ansible_user=centos environment=production
prod-lb2 ansible_host=10.0.1.31 ansible_user=centos environment=production

# Production-specific variables
[webservers:vars]
http_port=80
max_connections=1000
debug_mode=false

[databases:vars]
db_port=3306
max_connections=500
backup_enabled=true

[all:vars]
ansible_ssh_private_key_file=~/.ssh/prod_key
log_level=info
Subtask 2.2: Create Host-Specific Variable Files
For more complex configurations, we'll use separate variable files for individual hosts.

Create a host_vars directory:
mkdir -p host_vars
Create host-specific variables for dev-web1:
nano host_vars/dev-web1.yml
Add host-specific configuration:
---
# Host-specific variables for dev-web1
server_role: primary_web
cpu_cores: 2
memory_gb: 4
disk_space_gb: 50

# Application-specific settings
app_version: "2.1.0-dev"
ssl_enabled: false
monitoring_enabled: true

# Custom configuration
custom_config:
  cache_size: "128M"
  session_timeout: 1800
  upload_max_size: "10M"
Create host-specific variables for prod-web1:
nano host_vars/prod-web1.yml
Add production host configuration:
---
# Host-specific variables for prod-web1
server_role: primary_web
cpu_cores: 8
memory_gb: 16
disk_space_gb: 200

# Application-specific settings
app_version: "2.0.5"
ssl_enabled: true
monitoring_enabled: true

# Custom configuration
custom_config:
  cache_size: "512M"
  session_timeout: 3600
  upload_max_size: "50M"

# Security settings
firewall_rules:
  - port: 80
    protocol: tcp
    source: "0.0.0.0/0"
  - port: 443
    protocol: tcp
    source: "0.0.0.0/0"
Subtask 2.3: Test Host Variables
Create a playbook to display host variables:
nano test-host-vars.yml
Add the following playbook content:
---
- name: Test Host Variables
  hosts: all
  gather_facts: no
  tasks:
    - name: Display environment information
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          Environment: {{ environment | default('not_set') }}
          HTTP Port: {{ http_port | default('not_set') }}
          Debug Mode: {{ debug_mode | default('not_set') }}
          Server Role: {{ server_role | default('not_set') }}
          CPU Cores: {{ cpu_cores | default('not_set') }}
          Memory: {{ memory_gb | default('not_set') }}GB

    - name: Display custom configuration (if exists)
      debug:
        var: custom_config
      when: custom_config is defined
Run the playbook with different inventories:
# Test with development inventory
ansible-playbook -i inventory-dev.ini test-host-vars.yml --limit dev-web1

# Test with production inventory
ansible-playbook -i inventory-prod.ini test-host-vars.yml --limit prod-web1
Task 3: Using Group Variables to Target Specific Machines
Subtask 3.1: Create Group Variable Files
Group variables allow you to define common settings for groups of hosts, making your configurations more maintainable.

Create a group_vars directory:
mkdir -p group_vars
Create variables for the webservers group:
nano group_vars/webservers.yml
Add webserver-specific group variables:
---
# Group variables for webservers
service_name: "apache"
document_root: "/var/www/html"
log_directory: "/var/log/httpd"

# Common web server packages
required_packages:
  - httpd
  - mod_ssl
  - php
  - php-mysql

# Security settings
security_headers:
  - "X-Frame-Options: DENY"
  - "X-Content-Type-Options: nosniff"
  - "X-XSS-Protection: 1; mode=block"

# Performance tuning
performance_settings:
  max_request_workers: 400
  threads_per_child: 25
  server_limit: 16

# Backup configuration
backup_schedule:
  frequency: "daily"
  retention_days: 7
  backup_path: "/backup/web"
Create variables for the databases group:
nano group_vars/databases.yml
Add database-specific group variables:
---
# Group variables for databases
service_name: "mysqld"
data_directory: "/var/lib/mysql"
log_directory: "/var/log/mysql"
config_file: "/etc/my.cnf"

# Database packages
required_packages:
  - mysql-server
  - mysql-client
  - python3-PyMySQL

# Database configuration
mysql_config:
  bind_address: "0.0.0.0"
  port: 3306
  max_connections: 200
  innodb_buffer_pool_size: "1G"
  query_cache_size: "64M"

# Security settings
security_config:
  remove_anonymous_users: true
  remove_test_database: true
  disallow_root_login_remotely: true

# Backup configuration
backup_schedule:
  frequency: "daily"
  retention_days: 30
  backup_path: "/backup/mysql"
  compress: true
Create variables for the production group:
nano group_vars/production.yml
Add production-wide variables:
---
# Production environment group variables
environment_type: "production"
monitoring_enabled: true
logging_level: "info"
backup_enabled: true

# Common production settings
timezone: "America/New_York"
ntp_servers:
  - "pool.ntp.org"
  - "time.google.com"

# Security settings
security_policies:
  password_complexity: true
  session_timeout: 3600
  failed_login_attempts: 3
  account_lockout_duration: 1800

# Monitoring configuration
monitoring:
  agent: "node_exporter"
  metrics_port: 9100
  scrape_interval: "15s"

# Log management
log_management:
  centralized_logging: true
  log_retention_days: 90
  log_rotation: "daily"
Subtask 3.2: Create Advanced Group Targeting Playbook
Now we'll create a comprehensive playbook that demonstrates how group variables work with different targeting strategies.

Create an advanced targeting playbook:
nano group-targeting-demo.yml
Add the following comprehensive playbook:
---
- name: Configure Web Servers
  hosts: webservers
  become: yes
  tasks:
    - name: Display web server configuration
      debug:
        msg: |
          Configuring {{ service_name }} on {{ inventory_hostname }}
          Document Root: {{ document_root }}
          Environment: {{ environment_type | default('development') }}
          Max Workers: {{ performance_settings.max_request_workers }}

    - name: Install web server packages
      yum:
        name: "{{ required_packages }}"
        state: present
      when: ansible_os_family == "RedHat"

    - name: Create document root directory
      file:
        path: "{{ document_root }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'

    - name: Configure backup directory
      file:
        path: "{{ backup_schedule.backup_path }}"
        state: directory
        mode: '0750'

- name: Configure Database Servers
  hosts: databases
  become: yes
  tasks:
    - name: Display database configuration
      debug:
        msg: |
          Configuring {{ service_name }} on {{ inventory_hostname }}
          Data Directory: {{ data_directory }}
          Port: {{ mysql_config.port }}
          Max Connections: {{ mysql_config.max_connections }}

    - name: Install database packages
      yum:
        name: "{{ required_packages }}"
        state: present
      when: ansible_os_family == "RedHat"

    - name: Create data directory
      file:
        path: "{{ data_directory }}"
        state: directory
        owner: mysql
        group: mysql
        mode: '0750'

    - name: Configure backup directory
      file:
        path: "{{ backup_schedule.backup_path }}"
        state: directory
        mode: '0750'

- name: Apply Production-Wide Settings
  hosts: production
  become: yes
  tasks:
    - name: Display production environment info
      debug:
        msg: |
          Production server: {{ inventory_hostname }}
          Environment: {{ environment_type }}
          Monitoring: {{ monitoring_enabled }}
          Timezone: {{ timezone }}

    - name: Set timezone
      timezone:
        name: "{{ timezone }}"

    - name: Configure NTP
      template:
        src: ntp.conf.j2
        dest: /etc/ntp.conf
        backup: yes
      notify: restart ntp

    - name: Install monitoring agent
      yum:
        name: node_exporter
        state: present
      when: monitoring_enabled | bool

  handlers:
    - name: restart ntp
      service:
        name: ntpd
        state: restarted
Subtask 3.3: Create Variable Precedence Demonstration
Understanding variable precedence is crucial for managing complex Ansible environments.

Create a variable precedence test playbook:
nano variable-precedence-test.yml
Add the precedence testing content:
---
- name: Variable Precedence Demonstration
  hosts: all
  vars:
    # Playbook variables (lower precedence)
    test_variable: "playbook_value"
    common_setting: "from_playbook"
    
  tasks:
    - name: Show variable precedence
      debug:
        msg: |
          === Variable Precedence Test ===
          Host: {{ inventory_hostname }}
          Test Variable: {{ test_variable }}
          Common Setting: {{ common_setting }}
          Environment: {{ environment | default('not_defined') }}
          
          === Variable Sources ===
          Group vars take precedence over playbook vars
          Host vars take precedence over group vars
          Extra vars (-e) take precedence over all others

    - name: Display all variables for this host
      debug:
        var: hostvars[inventory_hostname]
      when: inventory_hostname == "dev-web1" or inventory_hostname == "prod-web1"

    - name: Show group membership
      debug:
        msg: "{{ inventory_hostname }} belongs to groups: {{ group_names }}"
Test variable precedence with different methods:
# Test with extra variables (highest precedence)
ansible-playbook -i inventory-dev.ini variable-precedence-test.yml -e "test_variable=extra_var_value"

# Test with limit to specific hosts
ansible-playbook -i inventory-prod.ini variable-precedence-test.yml --limit prod-web1
Subtask 3.4: Create Dynamic Group Targeting
Learn how to target groups dynamically based on conditions and facts.

Create a dynamic targeting playbook:
nano dynamic-targeting.yml
Add dynamic targeting logic:
---
- name: Dynamic Group Targeting Based on Facts
  hosts: all
  gather_facts: yes
  tasks:
    - name: Create dynamic groups based on OS
      group_by:
        key: "os_{{ ansible_distribution | lower }}"

    - name: Create groups based on environment
      group_by:
        key: "env_{{ environment | default('unknown') }}"

    - name: Create groups based on memory size
      group_by:
        key: "memory_{{ 'high' if (ansible_memtotal_mb | int) > 8192 else 'low' }}"

- name: Configure CentOS/RHEL systems
  hosts: os_centos:os_redhat
  tasks:
    - name: Configure Red Hat family systems
      debug:
        msg: "Configuring {{ ansible_distribution }} system: {{ inventory_hostname }}"

- name: Configure high-memory systems
  hosts: memory_high
  tasks:
    - name: Optimize for high-memory systems
      debug:
        msg: |
          High-memory system detected: {{ inventory_hostname }}
          Total Memory: {{ ansible_memtotal_mb }}MB
          Applying high-memory optimizations...

- name: Configure production environment systems
  hosts: env_production
  tasks:
    - name: Apply production-specific configurations
      debug:
        msg: "Applying production settings to {{ inventory_hostname }}"
Run the dynamic targeting playbook:
ansible-playbook -i inventory-prod.ini dynamic-targeting.yml
Advanced Configuration Examples
Creating a Comprehensive Inventory Structure
For enterprise environments, create a well-organized inventory structure:

# Create the complete directory structure
mkdir -p inventories/{development,staging,production}/{group_vars,host_vars}
Create a master inventory template:
nano inventories/production/hosts.yml
Add YAML-format inventory:
---
all:
  children:
    webservers:
      hosts:
        web01.prod.company.com:
          ansible_host: 10.0.1.10
          server_id: web01
          datacenter: east
        web02.prod.company.com:
          ansible_host: 10.0.1.11
          server_id: web02
          datacenter: west
      vars:
        http_port: 80
        https_port: 443
        
    databases:
      hosts:
        db01.prod.company.com:
          ansible_host: 10.0.2.10
          server_id: db01
          datacenter: east
          db_role: master
        db02.prod.company.com:
          ansible_host: 10.0.2.11
          server_id: db02
          datacenter: west
          db_role: slave
      vars:
        mysql_port: 3306
        
    loadbalancers:
      hosts:
        lb01.prod.company.com:
          ansible_host: 10.0.3.10
          server_id: lb01
          datacenter: east
          
  vars:
    environment: production
    backup_enabled: true
    monitoring_enabled: true
Troubleshooting Common Issues
Issue 1: Variable Not Found
Problem: Variables are not being recognized in playbooks.

Solution:

# Check variable precedence and spelling
ansible-inventory -i inventory.ini --host hostname --vars

# Verify group membership
ansible-inventory -i inventory.ini --graph
Issue 2: Group Variables Not Applied
Problem: Group variables are not being applied to hosts.

Solution:

# Ensure proper directory structure
ls -la group_vars/
ls -la host_vars/

# Check YAML syntax
ansible-playbook --syntax-check playbook.yml
Issue 3: Inventory Parsing Errors
Problem: Ansible cannot parse the inventory file.

Solution:

# Test inventory syntax
ansible-inventory -i inventory.ini --list --yaml

# Check for common formatting issues
ansible-inventory -i inventory.ini --graph
Conclusion
In this comprehensive lab, you have successfully learned to:

Create and manage static inventories using both INI and YAML formats, understanding how to organize hosts into logical groups for better management
Implement host variables for environment-specific configurations, allowing you to maintain different settings for development, staging, and production environments
Utilize group variables to apply common configurations to sets of machines, reducing duplication and improving maintainability
Understand variable precedence and how Ansible resolves conflicts between different variable sources
Apply dynamic group targeting based on system facts and conditions for more flexible automation
These skills are fundamental for managing enterprise Ansible deployments where you need to handle multiple environments, different server roles, and complex configuration requirements. The inventory and variable management techniques you've learned will help you create more maintainable, scalable, and organized automation solutions.

Key Takeaways:

Static inventories provide predictable, version-controlled host management
Host and group variables enable environment-specific configurations without code duplication
Proper variable precedence understanding prevents configuration conflicts
Well-organized inventory structures improve team collaboration and system maintainability
These concepts form the foundation for advanced Ansible topics like dynamic inventories, Ansible Vault for sensitive data, and complex multi-environment deployments that you'll encounter in professional DevOps and system administration roles.
