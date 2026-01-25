Lab 19: Scaling Automation with Ansible
Objectives
By the end of this lab, students will be able to:

Deploy and manage infrastructure at scale using Ansible
Create and execute Ansible playbooks for multi-host environments
Configure and manage multiple environments (development, staging, production)
Implement Ansible best practices for scalable automation
Test and validate automation performance across multiple machines
Troubleshoot common issues in large-scale Ansible deployments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax
Basic knowledge of SSH and public key authentication
Understanding of web servers (Apache/Nginx) and basic networking concepts
Completion of introductory Ansible labs or equivalent experience
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install software - everything is ready to use!

Your lab environment includes:

1 Ansible Control Node (ansible-control)
4 Managed Nodes (web-01, web-02, db-01, db-02)
All machines running CentOS 8 Stream
SSH keys pre-configured for passwordless authentication
Ansible 4.x pre-installed on the control node
Task 1: Setting Up Multi-Host Ansible Environment
Subtask 1.1: Verify Lab Environment and Connectivity
First, let's verify that all machines are accessible and properly configured.

Connect to the Ansible Control Node
# You should already be logged into the ansible-control machine
whoami
hostname
Verify Ansible Installation
ansible --version
ansible-config dump --only-changed
Test connectivity to all managed nodes
# Test SSH connectivity to all nodes
ssh web-01 "hostname && whoami"
ssh web-02 "hostname && whoami"
ssh db-01 "hostname && whoami"
ssh db-02 "hostname && whoami"
Subtask 1.2: Create Ansible Inventory for Multi-Host Setup
Create the main project directory
mkdir -p ~/ansible-scaling-lab
cd ~/ansible-scaling-lab
Create a comprehensive inventory file
cat > inventory.ini << 'EOF'
[webservers]
web-01 ansible_host=web-01
web-02 ansible_host=web-02

[databases]
db-01 ansible_host=db-01
db-02 ansible_host=db-02

[development:children]
webservers

[staging:children]
webservers
databases

[production:children]
webservers
databases

[all:vars]
ansible_user=centos
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
Test the inventory configuration
# List all hosts
ansible all -i inventory.ini --list-hosts

# Test connectivity using ping module
ansible all -i inventory.ini -m ping
Subtask 1.3: Create Ansible Configuration File
Create ansible.cfg for optimized performance
cat > ansible.cfg << 'EOF'
[defaults]
inventory = inventory.ini
remote_user = centos
private_key_file = ~/.ssh/id_rsa
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = memory
stdout_callback = yaml
forks = 10
timeout = 30

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
pipelining = True
EOF
Verify configuration
ansible-config view
ansible all -m setup --tree /tmp/facts
Task 2: Deploy Applications Across Multi-Host Setup
Subtask 2.1: Create Web Application Deployment Playbook
Create directory structure for organized playbooks
mkdir -p playbooks roles group_vars host_vars
Create a comprehensive web application deployment playbook
cat > playbooks/deploy-web-app.yml << 'EOF'
---
- name: Deploy Web Application Across Multiple Hosts
  hosts: webservers
  become: yes
  vars:
    app_name: "scalable-web-app"
    app_version: "1.0.0"
    web_root: "/var/www/html"
    
  tasks:
    - name: Update system packages
      yum:
        name: "*"
        state: latest
        update_cache: yes
      tags: system

    - name: Install required packages
      yum:
        name:
          - httpd
          - php
          - php-mysql
          - git
          - unzip
        state: present
      tags: packages

    - name: Start and enable Apache service
      systemd:
        name: httpd
        state: started
        enabled: yes
      tags: services

    - name: Configure firewall for HTTP traffic
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      tags: firewall

    - name: Create application directory
      file:
        path: "{{ web_root }}/{{ app_name }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
      tags: app

    - name: Deploy application files
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>{{ app_name }} - {{ inventory_hostname }}</title>
              <style>
                  body { font-family: Arial, sans-serif; margin: 40px; }
                  .server-info { background: #f0f0f0; padding: 20px; border-radius: 5px; }
              </style>
          </head>
          <body>
              <h1>Welcome to {{ app_name }}</h1>
              <div class="server-info">
                  <h2>Server Information</h2>
                  <p><strong>Hostname:</strong> {{ inventory_hostname }}</p>
                  <p><strong>Version:</strong> {{ app_version }}</p>
                  <p><strong>Deployed:</strong> {{ ansible_date_time.iso8601 }}</p>
                  <p><strong>Environment:</strong> {{ environment | default('development') }}</p>
              </div>
              <?php
              echo "<h2>PHP Information</h2>";
              echo "<p>PHP Version: " . phpversion() . "</p>";
              echo "<p>Server Time: " . date('Y-m-d H:i:s') . "</p>";
              ?>
          </body>
          </html>
        dest: "{{ web_root }}/{{ app_name }}/index.php"
        owner: apache
        group: apache
        mode: '0644'
      tags: app

    - name: Create health check endpoint
      copy:
        content: |
          <?php
          header('Content-Type: application/json');
          $health = array(
              'status' => 'healthy',
              'hostname' => gethostname(),
              'timestamp' => date('c'),
              'version' => '{{ app_version }}'
          );
          echo json_encode($health, JSON_PRETTY_PRINT);
          ?>
        dest: "{{ web_root }}/{{ app_name }}/health.php"
        owner: apache
        group: apache
        mode: '0644'
      tags: app

    - name: Configure Apache virtual host
      copy:
        content: |
          <VirtualHost *:80>
              DocumentRoot {{ web_root }}/{{ app_name }}
              ServerName {{ inventory_hostname }}
              
              <Directory {{ web_root }}/{{ app_name }}>
                  AllowOverride All
                  Require all granted
              </Directory>
              
              ErrorLog /var/log/httpd/{{ app_name }}_error.log
              CustomLog /var/log/httpd/{{ app_name }}_access.log combined
          </VirtualHost>
        dest: "/etc/httpd/conf.d/{{ app_name }}.conf"
        owner: root
        group: root
        mode: '0644'
      notify: restart apache
      tags: config

  handlers:
    - name: restart apache
      systemd:
        name: httpd
        state: restarted
EOF
Subtask 2.2: Create Database Setup Playbook
Create database deployment playbook
cat > playbooks/deploy-database.yml << 'EOF'
---
- name: Deploy Database Servers
  hosts: databases
  become: yes
  vars:
    mysql_root_password: "SecurePass123!"
    app_db_name: "scalable_app"
    app_db_user: "app_user"
    app_db_password: "AppPass123!"
    
  tasks:
    - name: Install MySQL/MariaDB
      yum:
        name:
          - mariadb-server
          - mariadb
          - python3-PyMySQL
        state: present
      tags: packages

    - name: Start and enable MariaDB service
      systemd:
        name: mariadb
        state: started
        enabled: yes
      tags: services

    - name: Configure firewall for MySQL
      firewalld:
        port: 3306/tcp
        permanent: yes
        state: enabled
        immediate: yes
      tags: firewall

    - name: Set MySQL root password
      mysql_user:
        name: root
        password: "{{ mysql_root_password }}"
        login_unix_socket: /var/lib/mysql/mysql.sock
        state: present
      tags: mysql

    - name: Create application database
      mysql_db:
        name: "{{ app_db_name }}"
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"
      tags: mysql

    - name: Create application database user
      mysql_user:
        name: "{{ app_db_user }}"
        password: "{{ app_db_password }}"
        priv: "{{ app_db_name }}.*:ALL"
        host: "%"
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"
      tags: mysql

    - name: Create sample table and data
      mysql_query:
        login_user: root
        login_password: "{{ mysql_root_password }}"
        login_db: "{{ app_db_name }}"
        query:
          - CREATE TABLE IF NOT EXISTS server_stats (id INT AUTO_INCREMENT PRIMARY KEY, hostname VARCHAR(255), last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
          - INSERT INTO server_stats (hostname) VALUES ('{{ inventory_hostname }}') ON DUPLICATE KEY UPDATE last_update = CURRENT_TIMESTAMP
      tags: mysql
EOF
Subtask 2.3: Execute Multi-Host Deployment
Run the web application deployment
# Deploy to all web servers
ansible-playbook playbooks/deploy-web-app.yml -v

# Check deployment status
ansible webservers -m systemd -a "name=httpd state=started"
Deploy database servers
# Deploy to all database servers
ansible-playbook playbooks/deploy-database.yml -v

# Verify database services
ansible databases -m systemd -a "name=mariadb state=started"
Verify application deployment
# Test web application endpoints
ansible webservers -m uri -a "url=http://{{ inventory_hostname }}/scalable-web-app/ method=GET"

# Test health check endpoints
ansible webservers -m uri -a "url=http://{{ inventory_hostname }}/scalable-web-app/health.php method=GET"
Task 3: Manage Configurations for Multiple Environments
Subtask 3.1: Create Environment-Specific Variables
Create group variables for different environments
# Development environment variables
cat > group_vars/development.yml << 'EOF'
---
environment: development
app_version: "1.0.0-dev"
debug_mode: true
log_level: debug
max_connections: 50
cache_enabled: false
backup_retention_days: 7

database_config:
  max_connections: 100
  query_cache_size: 16M
  innodb_buffer_pool_size: 128M
EOF
# Staging environment variables
cat > group_vars/staging.yml << 'EOF'
---
environment: staging
app_version: "1.0.0-rc"
debug_mode: false
log_level: info
max_connections: 100
cache_enabled: true
backup_retention_days: 14

database_config:
  max_connections: 200
  query_cache_size: 32M
  innodb_buffer_pool_size: 256M
EOF
# Production environment variables
cat > group_vars/production.yml << 'EOF'
---
environment: production
app_version: "1.0.0"
debug_mode: false
log_level: warning
max_connections: 200
cache_enabled: true
backup_retention_days: 30

database_config:
  max_connections: 500
  query_cache_size: 64M
  innodb_buffer_pool_size: 512M
EOF
Create host-specific variables
# Web server specific configurations
cat > host_vars/web-01.yml << 'EOF'
---
server_role: primary_web
load_balancer_weight: 100
maintenance_window: "02:00-04:00"
EOF
cat > host_vars/web-02.yml << 'EOF'
---
server_role: secondary_web
load_balancer_weight: 80
maintenance_window: "03:00-05:00"
EOF
Subtask 3.2: Create Environment-Aware Configuration Playbook
Create advanced configuration management playbook
cat > playbooks/configure-environments.yml << 'EOF'
---
- name: Configure Applications for Different Environments
  hosts: all
  become: yes
  vars:
    config_dir: "/etc/{{ app_name | default('scalable-web-app') }}"
    
  tasks:
    - name: Create application configuration directory
      file:
        path: "{{ config_dir }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
      tags: config

    - name: Generate environment-specific application config
      template:
        src: app-config.j2
        dest: "{{ config_dir }}/app.conf"
        owner: root
        group: root
        mode: '0644'
      notify: restart services
      tags: config

    - name: Configure log rotation
      copy:
        content: |
          /var/log/{{ app_name | default('scalable-web-app') }}/*.log {
              daily
              rotate {{ backup_retention_days | default(7) }}
              compress
              delaycompress
              missingok
              notifempty
              create 0644 apache apache
          }
        dest: "/etc/logrotate.d/{{ app_name | default('scalable-web-app') }}"
        owner: root
        group: root
        mode: '0644'
      tags: logging

    - name: Set up monitoring configuration
      copy:
        content: |
          # {{ environment | upper }} Environment Monitoring
          [general]
          environment={{ environment | default('development') }}
          hostname={{ inventory_hostname }}
          role={{ server_role | default('generic') }}
          
          [performance]
          max_connections={{ max_connections | default(50) }}
          cache_enabled={{ cache_enabled | default(false) }}
          log_level={{ log_level | default('info') }}
          
          [maintenance]
          window={{ maintenance_window | default('02:00-04:00') }}
          backup_retention={{ backup_retention_days | default(7) }}
        dest: "{{ config_dir }}/monitoring.conf"
        owner: root
        group: root
        mode: '0644'
      tags: monitoring

  handlers:
    - name: restart services
      systemd:
        name: "{{ item }}"
        state: restarted
      loop:
        - httpd
      when: inventory_hostname in groups['webservers']
EOF
Create configuration template
mkdir -p templates
cat > templates/app-config.j2 << 'EOF'
# {{ app_name | default('scalable-web-app') }} Configuration
# Environment: {{ environment | upper }}
# Generated: {{ ansible_date_time.iso8601 }}

[application]
name={{ app_name | default('scalable-web-app') }}
version={{ app_version | default('1.0.0') }}
environment={{ environment | default('development') }}
debug={{ debug_mode | default(true) | lower }}

[server]
hostname={{ inventory_hostname }}
role={{ server_role | default('generic') }}
max_connections={{ max_connections | default(50) }}

[logging]
level={{ log_level | default('info') }}
file=/var/log/{{ app_name | default('scalable-web-app') }}/app.log

[cache]
enabled={{ cache_enabled | default(false) | lower }}
{% if cache_enabled | default(false) %}
type=redis
host=localhost
port=6379
{% endif %}

{% if inventory_hostname in groups['databases'] %}
[database]
max_connections={{ database_config.max_connections | default(100) }}
query_cache_size={{ database_config.query_cache_size | default('16M') }}
innodb_buffer_pool_size={{ database_config.innodb_buffer_pool_size | default('128M') }}
{% endif %}

[maintenance]
window={{ maintenance_window | default('02:00-04:00') }}
backup_retention_days={{ backup_retention_days | default(7) }}
EOF
Subtask 3.3: Deploy Environment-Specific Configurations
Deploy configurations to development environment
# Deploy to development (webservers only in this case)
ansible-playbook playbooks/configure-environments.yml --limit development -v

# Verify development configuration
ansible development -m shell -a "cat /etc/scalable-web-app/app.conf | head -10"
Deploy configurations to staging environment
# Deploy to staging environment
ansible-playbook playbooks/configure-environments.yml --limit staging -v

# Compare configurations between environments
ansible staging -m shell -a "grep environment /etc/scalable-web-app/app.conf"
Create environment deployment script
cat > deploy-environment.sh << 'EOF'
#!/bin/bash

ENVIRONMENT=${1:-development}
PLAYBOOK=${2:-playbooks/configure-environments.yml}

echo "Deploying to $ENVIRONMENT environment..."

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
    echo "Error: Invalid environment. Use: development, staging, or production"
    exit 1
fi

# Run deployment
ansible-playbook $PLAYBOOK --limit $ENVIRONMENT -v

# Verify deployment
echo "Verifying deployment..."
ansible $ENVIRONMENT -m shell -a "cat /etc/scalable-web-app/monitoring.conf | grep environment"

echo "Deployment to $ENVIRONMENT completed!"
EOF

chmod +x deploy-environment.sh
Test environment deployment script
# Deploy to development
./deploy-environment.sh development

# Deploy to staging
./deploy-environment.sh staging
Task 4: Test Performance and Efficiency of Automation
Subtask 4.1: Create Performance Testing Playbook
Create comprehensive performance testing playbook
cat > playbooks/performance-test.yml << 'EOF'
---
- name: Performance Testing for Scaled Ansible Automation
  hosts: all
  gather_facts: yes
  vars:
    test_results_dir: "/tmp/ansible-performance"
    concurrent_tasks: 10
    
  tasks:
    - name: Create test results directory
      file:
        path: "{{ test_results_dir }}"
        state: directory
        mode: '0755'
      delegate_to: localhost
      run_once: true
      tags: setup

    - name: Record start time
      set_fact:
        test_start_time: "{{ ansible_date_time.epoch }}"
      tags: timing

    - name: System information gathering
      setup:
        gather_subset:
          - hardware
          - network
          - virtual
      register: system_facts
      tags: facts

    - name: CPU and Memory stress test
      shell: |
        # CPU test
        timeout 30s yes > /dev/null &
        CPU_PID=$!
        
        # Memory test  
        timeout 30s dd if=/dev/zero of=/tmp/memory_test bs=1M count=100 2>/dev/null &
        MEM_PID=$!
        
        # Wait for tests to complete
        wait $CPU_PID 2>/dev/null
        wait $MEM_PID 2>/dev/null
        
        # Cleanup
        rm -f /tmp/memory_test
        
        echo "Stress test completed on {{ inventory_hostname }}"
      register: stress_test_result
      tags: stress

    - name: Network connectivity test
      uri:
        url: "http://{{ item }}"
        method: GET
        timeout: 10
      loop: "{{ groups['webservers'] }}"
      when: inventory_hostname in groups['webservers']
      register: network_test_result
      ignore_errors: yes
      tags: network

    - name: Database connectivity test
      mysql_query:
        login_user: root
        login_password: "SecurePass123!"
        query: "SELECT 1 as test_connection"
      when: inventory_hostname in groups['databases']
      register: db_test_result
      ignore_errors: yes
      tags: database

    - name: Disk I/O performance test
      shell: |
        # Write test
        WRITE_START=$(date +%s.%N)
        dd if=/dev/zero of=/tmp/io_test bs=1M count=50 oflag=direct 2>/dev/null
        WRITE_END=$(date +%s.%N)
        
        # Read test
        READ_START=$(date +%s.%N)
        dd if=/tmp/io_test of=/dev/null bs=1M iflag=direct 2>/dev/null
        READ_END=$(date +%s.%N)
        
        # Calculate performance
        WRITE_TIME=$(echo "$WRITE_END - $WRITE_START" | bc)
        READ_TIME=$(echo "$READ_END - $READ_START" | bc)
        
        # Cleanup
        rm -f /tmp/io_test
        
        echo "Write time: ${WRITE_TIME}s, Read time: ${READ_TIME}s"
      register: io_test_result
      tags: io

    - name: Record end time and calculate duration
      set_fact:
        test_end_time: "{{ ansible_date_time.epoch }}"
        test_duration: "{{ ansible_date_time.epoch | int - test_start_time | int }}"
      tags: timing

    - name: Generate performance report
      template:
        src: performance-report.j2
        dest: "{{ test_results_dir }}/{{ inventory_hostname }}-performance.json"
      delegate_to: localhost
      tags: report
EOF
Create performance report template
cat > templates/performance-report.j2 << 'EOF'
{
  "hostname": "{{ inventory_hostname }}",
  "test_timestamp": "{{ ansible_date_time.iso8601 }}",
  "test_duration_seconds": {{ test_duration }},
  "system_info": {
    "os": "{{ ansible_distribution }} {{ ansible_distribution_version }}",
    "kernel": "{{ ansible_kernel }}",
    "architecture": "{{ ansible_architecture }}",
    "cpu_cores": {{ ansible_processor_vcpus }},
    "memory_mb": {{ ansible_memtotal_mb }},
    "disk_space_gb": {{ (ansible_mounts | selectattr('mount', 'equalto', '/') | first).size_total / 1024 / 1024 / 1024 | round(2) }}
  },
  "performance_tests": {
    "stress_test": {
      "status": "{{ 'passed' if stress_test_result.rc == 0 else 'failed' }}",
      "output": "{{ stress_test_result.stdout | default('') }}"
    },
    "io_test": {
      "status": "{{ 'passed' if io_test_result.rc == 0 else 'failed' }}",
      "results": "{{ io_test_result.stdout | default('') }}"
    }{% if inventory_hostname in groups['webservers'] %},
    "network_test": {
      "status": "{{ 'passed' if network_test_result.results | selectattr('status', 'equalto', 200) | list | length > 0 else 'failed' }}",
      "connections_tested": {{ network_test_result.results | length }}
    }{% endif %}{% if inventory_hostname in groups['databases'] %},
    "database_test": {
      "status": "{{ 'passed' if db_test_result.query_result is defined else 'failed' }}",
      "connection": "{{ 'successful' if db_test_result.query_result is defined else 'failed' }}"
    }{% endif %}
  },
  "ansible_performance": {
    "facts_gathering_time": "{{ hostvars[inventory_hostname]['ansible_date_time']['epoch'] | int - test_start_time | int }}s",
    "total_tasks_executed": "{{ ansible_play_batch | length }}",
    "parallel_execution": true
  }
}
EOF
Subtask 4.2: Execute Performance Tests
Run performance tests across all hosts
# Execute performance testing
time ansible-playbook playbooks/performance-test.yml -f 10 -v

# Check test results
ls -la /tmp/ansible-performance/
Create performance analysis script
cat > analyze-performance.py << 'EOF'
#!/usr/bin/env python3
import json
import os
import statistics
from datetime import datetime

def analyze_performance_results():
    results_dir = "/tmp/ansible-performance"
    results = []
    
    # Read all performance result files
    for filename in os.listdir(results_dir):
        if filename.endswith('-performance.json'):
            with open(os.path.join(results_dir, filename), 'r') as f:
                results.append(json.load(f))
    
    if not results:
        print("No performance results found!")
        return
    
    print("=== Ansible Performance Analysis ===")
    print(f"Total hosts tested: {len(results)}")
    print(f"Test timestamp: {results[0]['test_timestamp']}")
    print()
    
    # Analyze test durations
    durations = [r['test_duration_seconds'] for r in results]
    print("=== Test Duration Analysis ===")
    print(f"Average duration: {statistics.mean(durations):.2f} seconds")
    print(f"Minimum duration: {min(durations)} seconds")
    print(f"Maximum duration: {max(durations)} seconds")
    print(f"Standard deviation: {statistics.stdev(durations):.2f} seconds")
    print()
    
    # Analyze system resources
    print("=== System Resources Summary ===")
    total_cpu_cores = sum(r['system_info']['cpu_cores'] for r in results)
    total_memory_gb = sum(r['system_info']['memory_mb'] for r in results) / 1024
    total_disk_gb = sum(r['system_info']['disk_space_gb'] for r in results)
    
    print(f"Total CPU cores: {total_cpu_cores}")
    print(f"Total memory: {total_memory_gb:.2f} GB")
    print(f"Total disk space: {total_disk_gb:.2f} GB")
    print()
    
    # Test results summary
    print("=== Test Results Summary ===")
    for result in results:
        hostname = result['hostname']
        tests = result['performance_tests']
        
        print(f"Host: {hostname}")
        for test_name, test_data in tests.items():
            status = test_data.get('status', 'unknown')
            print(f"  {test_name}: {status}")
        print()
    
    # Performance recommendations
    print("=== Performance Recommendations ===")
    if max(durations) > 60:
        print("- Consider increasing Ansible forks for better parallelization")
    if statistics.stdev(durations) > 10:
        print("- High variance in execution times detected - check network connectivity")
    if len(results) > 10:
        print("- For large inventories, consider using Ansible Tower/AWX for better scaling")
    
    print("\nAnalysis complete!")

if __name__ == "__main__":
    analyze_performance_results()
EOF

chmod +x analyze-performance.py
Run performance analysis
# Install Python if needed and run analysis
python3 analyze-performance.py
Subtask 4.3: Optimize Ansible Performance
Create optimized ansible.cfg for large-scale deployments
cp ansible.cfg ansible.cfg.backup

cat > ansible.cfg << 'EOF'
[defaults]
inventory = inventory.ini
remote_user = centos
private_key_file = ~/.ssh/id_rsa
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 3600
stdout_callback = yaml
forks = 20
timeout = 30
poll_interval = 2
ansible_managed = Ansible managed: {file} modified on %Y-%m-%d %H:%M:%S by {uid} on {host}

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=300s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
pipelining = True
control_path_dir = /tmp/.ansible-cp

[persistent_connection]
command_timeout = 60
connect_timeout = 30

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml
EOF
Create performance optimization playbook
cat > playbooks/optimize-performance.yml << 'EOF'
---
- name: Optimize Ansible Performance for Scale
  hosts: localhost
  gather_facts: no
  vars:
    optimization_results: []
    
  tasks:
    - name: Test current Ansible configuration
      debug:
        msg: "Testing optimized Ansible configuration"
      
    - name: Benchmark fact gathering with optimization
      setup:
      delegate_to: "{{ item }}"
      loop: "{{ groups['all'] }}"
      register: fact_gathering_results
      
    - name: Test parallel task execution
      ping:
      delegate_to: "{{ item }}"
      loop: "{{ groups['all'] }}"
      register: ping_results
      
    - name: Calculate performance metrics
      set_fact:
        total_hosts: "{{ groups['all'] | length }}"
        successful_pings: "{{ ping_results.results | selectattr('ping', 'defined') | list | length }}"
        fact_gathering_time: "{{ ansible_date_time.epoch }}"
        
    - name: Display optimization results
      debug:
        msg:
          - "Performance Optimization Results:"
          - "Total hosts managed: {{ total_hosts }}"
          - "Successful connections: {{ successful_pings }}"
          - "Fact caching enabled: {{ ansible_facts_cacheable | default(false) }}"
          - "Current forks setting: {{ ansible_forks | default(5) }}"
          - "SSH pipelining: {{ ansible_ssh_pipelining | default(false) }}"
EOF
Execute optimization tests
# Test optimized configuration
time ansible-playbook playbooks/optimize-performance.
