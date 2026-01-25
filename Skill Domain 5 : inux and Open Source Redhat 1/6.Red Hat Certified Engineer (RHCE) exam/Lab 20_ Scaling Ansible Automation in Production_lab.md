Lab 20: Scaling Ansible Automation in Production
Objectives
By the end of this lab, students will be able to:

Implement dynamic inventories to manage large-scale infrastructure across multiple regions
Optimize Ansible playbooks for performance in large deployments
Configure and utilize Ansible strategies for parallel execution
Implement caching mechanisms to improve playbook performance
Troubleshoot common issues in large-scale Ansible deployments
Apply performance tuning techniques for production environments
Monitor and analyze Ansible execution metrics
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ansible concepts (playbooks, inventories, modules)
Familiarity with YAML syntax and Jinja2 templating
Knowledge of Linux command line operations
Understanding of web server concepts (Apache/Nginx)
Basic networking knowledge
Experience with SSH key management
Lab Environment
Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own VM or install additional software - everything is ready to use.

Your lab environment includes:

Ansible control node with Ansible 2.15+ installed
Multiple target nodes simulating different regions
Pre-configured SSH keys for seamless connectivity
Sample web applications for deployment testing
Task 1: Automate Scaling of Web Servers Using Dynamic Inventories
Subtask 1.1: Set Up Dynamic Inventory Structure
First, let's create a dynamic inventory system that can automatically discover and categorize servers across multiple regions.

Navigate to the Ansible working directory:
cd /home/ansible
mkdir -p scaling-lab/{inventories,playbooks,roles,group_vars,host_vars}
cd scaling-lab
Create a dynamic inventory script for AWS-style regions:
cat > inventories/dynamic_inventory.py << 'EOF'
#!/usr/bin/env python3

import json
import sys
import subprocess

def get_inventory():
    inventory = {
        '_meta': {
            'hostvars': {}
        },
        'webservers': {
            'hosts': [],
            'vars': {
                'ansible_user': 'ansible',
                'http_port': 80,
                'max_clients': 200
            }
        },
        'us_east': {
            'hosts': [],
            'vars': {
                'region': 'us-east-1',
                'datacenter': 'virginia'
            }
        },
        'us_west': {
            'hosts': [],
            'vars': {
                'region': 'us-west-2',
                'datacenter': 'oregon'
            }
        },
        'europe': {
            'hosts': [],
            'vars': {
                'region': 'eu-west-1',
                'datacenter': 'ireland'
            }
        }
    }
    
    # Simulate discovering hosts (in production, this would query cloud APIs)
    hosts = [
        {'name': 'web-us-east-01', 'ip': '10.0.1.10', 'region': 'us_east'},
        {'name': 'web-us-east-02', 'ip': '10.0.1.11', 'region': 'us_east'},
        {'name': 'web-us-west-01', 'ip': '10.0.2.10', 'region': 'us_west'},
        {'name': 'web-us-west-02', 'ip': '10.0.2.11', 'region': 'us_west'},
        {'name': 'web-eu-west-01', 'ip': '10.0.3.10', 'region': 'europe'},
        {'name': 'web-eu-west-02', 'ip': '10.0.3.11', 'region': 'europe'}
    ]
    
    for host in hosts:
        # Add to webservers group
        inventory['webservers']['hosts'].append(host['name'])
        
        # Add to regional group
        inventory[host['region']]['hosts'].append(host['name'])
        
        # Add host variables
        inventory['_meta']['hostvars'][host['name']] = {
            'ansible_host': host['ip'],
            'region_name': host['region'],
            'server_id': host['name']
        }
    
    return inventory

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] == '--list':
        print(json.dumps(get_inventory(), indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == '--host':
        print(json.dumps({}))
    else:
        print("Usage: %s --list or %s --host <hostname>" % (sys.argv[0], sys.argv[0]))
        sys.exit(1)
EOF

chmod +x inventories/dynamic_inventory.py
Test the dynamic inventory:
./inventories/dynamic_inventory.py --list
Subtask 1.2: Create Optimized Web Server Role
Create a reusable role for web server deployment that's optimized for large-scale operations.

Generate the role structure:
ansible-galaxy init roles/webserver
Create optimized web server tasks:
cat > roles/webserver/tasks/main.yml << 'EOF'
---
- name: Install web server packages
  package:
    name: "{{ web_packages }}"
    state: present
  become: yes
  tags: ['packages']

- name: Create web content directory
  file:
    path: "{{ web_root }}"
    state: directory
    owner: "{{ web_user }}"
    group: "{{ web_group }}"
    mode: '0755'
  become: yes
  tags: ['filesystem']

- name: Deploy web application template
  template:
    src: index.html.j2
    dest: "{{ web_root }}/index.html"
    owner: "{{ web_user }}"
    group: "{{ web_group }}"
    mode: '0644'
  become: yes
  notify: restart webserver
  tags: ['content']

- name: Configure web server
  template:
    src: "{{ web_config_template }}"
    dest: "{{ web_config_path }}"
    owner: root
    group: root
    mode: '0644'
    backup: yes
  become: yes
  notify: restart webserver
  tags: ['config']

- name: Start and enable web server
  service:
    name: "{{ web_service }}"
    state: started
    enabled: yes
  become: yes
  tags: ['service']

- name: Configure firewall for web traffic
  firewalld:
    service: http
    permanent: yes
    state: enabled
    immediate: yes
  become: yes
  ignore_errors: yes
  tags: ['firewall']
EOF
Create role variables:
cat > roles/webserver/defaults/main.yml << 'EOF'
---
# Web server defaults
web_packages:
  - httpd
  - firewalld

web_service: httpd
web_user: apache
web_group: apache
web_root: /var/www/html
web_config_path: /etc/httpd/conf/httpd.conf
web_config_template: httpd.conf.j2

# Performance settings
max_clients: "{{ ansible_processor_vcpus * 25 }}"
server_limit: "{{ ansible_processor_vcpus * 2 }}"
thread_limit: 25
threads_per_child: 25
EOF
Create web server configuration template:
cat > roles/webserver/templates/httpd.conf.j2 << 'EOF'
ServerRoot "/etc/httpd"
Listen {{ http_port | default(80) }}

Include conf.modules.d/*.conf

User {{ web_user }}
Group {{ web_group }}

ServerAdmin admin@{{ ansible_fqdn }}
ServerName {{ ansible_fqdn }}:{{ http_port | default(80) }}

<Directory />
    AllowOverride none
    Require all denied
</Directory>

DocumentRoot "{{ web_root }}"

<Directory "{{ web_root }}">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "logs/error_log"
LogLevel warn

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
    CustomLog "logs/access_log" combined
</IfModule>

<IfModule mime_module>
    TypesConfig /etc/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>

# Performance optimizations
<IfModule mpm_prefork_module>
    StartServers             8
    MinSpareServers          5
    MaxSpareServers         20
    ServerLimit           {{ server_limit }}
    MaxRequestWorkers     {{ max_clients }}
    MaxConnectionsPerChild   0
</IfModule>

# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>

Include conf.d/*.conf
EOF
Create web content template:
cat > roles/webserver/templates/index.html.j2 << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>{{ region_name | title }} Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; }
        .region { color: #0066cc; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Production Web Server</h1>
        <p class="region">Region: {{ region_name | upper }}</p>
    </div>
    
    <div class="info">
        <h2>Server Information</h2>
        <ul>
            <li><strong>Hostname:</strong> {{ ansible_hostname }}</li>
            <li><strong>Server ID:</strong> {{ server_id }}</li>
            <li><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</li>
            <li><strong>Region:</strong> {{ region_name }}</li>
            <li><strong>Datacenter:</strong> {{ datacenter }}</li>
            <li><strong>CPU Cores:</strong> {{ ansible_processor_vcpus }}</li>
            <li><strong>Memory:</strong> {{ ansible_memtotal_mb }}MB</li>
            <li><strong>Deployment Time:</strong> {{ ansible_date_time.iso8601 }}</li>
        </ul>
    </div>
    
    <div class="info">
        <h2>Performance Configuration</h2>
        <ul>
            <li><strong>Max Clients:</strong> {{ max_clients }}</li>
            <li><strong>Server Limit:</strong> {{ server_limit }}</li>
            <li><strong>HTTP Port:</strong> {{ http_port | default(80) }}</li>
        </ul>
    </div>
</body>
</html>
EOF
Create role handlers:
cat > roles/webserver/handlers/main.yml << 'EOF'
---
- name: restart webserver
  service:
    name: "{{ web_service }}"
    state: restarted
  become: yes
EOF
Subtask 1.3: Create Scaling Playbook
Now create a playbook that can scale web servers across multiple regions efficiently.

Create the main scaling playbook:
cat > playbooks/scale-webservers.yml << 'EOF'
---
- name: Scale Web Servers Across Multiple Regions
  hosts: webservers
  gather_facts: yes
  become: yes
  strategy: free
  serial: "30%"
  
  vars:
    http_port: 80
    deployment_batch_size: 5
    health_check_retries: 3
    health_check_delay: 10
  
  pre_tasks:
    - name: Display deployment information
      debug:
        msg: |
          Starting deployment to {{ inventory_hostname }}
          Region: {{ region_name }}
          Batch size: {{ deployment_batch_size }}
      tags: ['info']
    
    - name: Ensure system is ready for deployment
      wait_for_connection:
        timeout: 30
      tags: ['connectivity']
  
  roles:
    - role: webserver
      tags: ['webserver']
  
  post_tasks:
    - name: Perform health check
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ http_port }}"
        method: GET
        status_code: 200
      register: health_check
      retries: "{{ health_check_retries }}"
      delay: "{{ health_check_delay }}"
      tags: ['health_check']
    
    - name: Display deployment success
      debug:
        msg: |
          Successfully deployed to {{ inventory_hostname }}
          Health check status: {{ health_check.status }}
          Response time: {{ health_check.elapsed }}s
      when: health_check is succeeded
      tags: ['info']
EOF
Create a region-specific scaling playbook:
cat > playbooks/scale-by-region.yml << 'EOF'
---
- name: Scale Web Servers by Region
  hosts: localhost
  gather_facts: no
  vars:
    target_regions: ['us_east', 'us_west', 'europe']
    parallel_regions: 2
  
  tasks:
    - name: Deploy to regions in parallel
      include_tasks: deploy-region.yml
      vars:
        region: "{{ item }}"
      loop: "{{ target_regions }}"
      when: region in groups
      throttle: "{{ parallel_regions }}"

- name: Deploy Web Servers to Specific Region
  hosts: "{{ region }}"
  gather_facts: yes
  become: yes
  strategy: free
  serial: "50%"
  
  roles:
    - role: webserver
  
  post_tasks:
    - name: Verify regional deployment
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ http_port | default(80) }}"
        method: GET
        status_code: 200
      register: regional_health_check
      retries: 3
      delay: 5
    
    - name: Report regional deployment status
      debug:
        msg: "Region {{ region_name }} deployment completed successfully"
      when: regional_health_check is succeeded
EOF
Task 2: Optimize Playbooks for Large Deployments
Subtask 2.1: Implement Performance Optimizations
Create an optimized ansible.cfg file:
cat > ansible.cfg << 'EOF'
[defaults]
# Inventory settings
inventory = inventories/dynamic_inventory.py
host_key_checking = False
remote_user = ansible

# Performance optimizations
forks = 20
poll_interval = 1
timeout = 30
gather_timeout = 30

# Connection optimizations
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
pipelining = True
control_path_dir = /tmp/.ansible-cp

# Fact caching
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_fact_cache
fact_caching_timeout = 3600

# Callback plugins for better output
stdout_callback = yaml
callbacks_enabled = timer, profile_tasks

# Logging
log_path = /var/log/ansible.log

# Role and collection paths
roles_path = roles
collections_paths = collections

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
control_path = /tmp/.ansible-cp/ansible-ssh-%%h-%%p-%%r
pipelining = True
retries = 3
EOF
Create a performance-optimized playbook:
cat > playbooks/optimized-deployment.yml << 'EOF'
---
- name: High-Performance Web Server Deployment
  hosts: webservers
  gather_facts: yes
  become: yes
  strategy: free
  serial: "25%"
  max_fail_percentage: 10
  
  vars:
    # Performance variables
    ansible_ssh_pipelining: true
    ansible_ssh_extra_args: '-o ControlMaster=auto -o ControlPersist=60s'
    
    # Deployment settings
    deployment_timeout: 300
    batch_delay: 2
    
  environment:
    # Optimize package manager
    DEBIAN_FRONTEND: noninteractive
  
  pre_tasks:
    - name: Set deployment start time
      set_fact:
        deployment_start: "{{ ansible_date_time.epoch }}"
      run_once: true
      delegate_to: localhost
    
    - name: Check system resources
      setup:
        filter: 
          - 'ansible_memtotal_mb'
          - 'ansible_processor_vcpus'
          - 'ansible_default_ipv4'
      tags: ['facts']
    
    - name: Validate minimum system requirements
      assert:
        that:
          - ansible_memtotal_mb >= 512
          - ansible_processor_vcpus >= 1
        fail_msg: "System does not meet minimum requirements"
        success_msg: "System requirements validated"
      tags: ['validation']
  
  tasks:
    - name: Update package cache (optimized)
      package:
        update_cache: yes
        cache_valid_time: 3600
      become: yes
      when: ansible_os_family == "Debian"
      tags: ['packages']
    
    - name: Install packages in batch
      package:
        name: "{{ web_packages }}"
        state: present
      become: yes
      async: 300
      poll: 0
      register: package_install
      tags: ['packages']
    
    - name: Wait for package installation
      async_status:
        jid: "{{ package_install.ansible_job_id }}"
      register: package_result
      until: package_result.finished
      retries: 30
      delay: 10
      tags: ['packages']
    
    - name: Deploy web server role
      include_role:
        name: webserver
      tags: ['webserver']
  
  post_tasks:
    - name: Calculate deployment time
      set_fact:
        deployment_duration: "{{ ansible_date_time.epoch | int - deployment_start | int }}"
    
    - name: Performance health check
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ http_port | default(80) }}"
        method: GET
        status_code: 200
        timeout: 10
      register: perf_health_check
      retries: 3
      delay: 2
      tags: ['health_check']
    
    - name: Log deployment metrics
      lineinfile:
        path: /tmp/deployment_metrics.log
        line: "{{ ansible_date_time.iso8601 }},{{ inventory_hostname }},{{ deployment_duration }},{{ perf_health_check.elapsed }}"
        create: yes
      delegate_to: localhost
      tags: ['metrics']
EOF
Subtask 2.2: Implement Caching and Fact Optimization
Create a fact caching playbook:
cat > playbooks/cache-facts.yml << 'EOF'
---
- name: Cache System Facts for Large Deployments
  hosts: all
  gather_facts: yes
  
  vars:
    custom_fact_modules:
      - setup
      - service_facts
  
  tasks:
    - name: Gather comprehensive facts
      setup:
        gather_subset:
          - 'all'
          - '!facter'
          - '!ohai'
      tags: ['facts']
    
    - name: Gather service facts
      service_facts:
      tags: ['facts']
    
    - name: Create custom facts directory
      file:
        path: /etc/ansible/facts.d
        state: directory
        mode: '0755'
      become: yes
      tags: ['custom_facts']
    
    - name: Deploy custom web server facts
      copy:
        content: |
          #!/bin/bash
          echo "{"
          echo "  \"web_server_installed\": \"$(rpm -q httpd >/dev/null 2>&1 && echo true || echo false)\","
          echo "  \"web_server_running\": \"$(systemctl is-active httpd 2>/dev/null || echo false)\","
          echo "  \"web_port_open\": \"$(ss -tlnp | grep :80 >/dev/null 2>&1 && echo true || echo false)\","
          echo "  \"last_deployment\": \"$(stat -c %Y /var/www/html/index.html 2>/dev/null || echo 0)\""
          echo "}"
        dest: /etc/ansible/facts.d/webserver.fact
        mode: '0755'
      become: yes
      tags: ['custom_facts']
    
    - name: Refresh facts after custom fact deployment
      setup:
        filter: ansible_local
      tags: ['custom_facts']
    
    - name: Display cached facts summary
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Memory: {{ ansible_memtotal_mb }}MB
          CPU: {{ ansible_processor_vcpus }} cores
          Web Server Status: {{ ansible_local.webserver.web_server_installed | default('unknown') }}
      tags: ['summary']
EOF
Create a playbook that leverages cached facts:
cat > playbooks/deploy-with-cache.yml << 'EOF'
---
- name: Deploy Using Cached Facts
  hosts: webservers
  gather_facts: no
  become: yes
  
  vars:
    force_fact_gathering: false
  
  pre_tasks:
    - name: Load cached facts
      setup:
        gather_subset: 'min'
      when: force_fact_gathering | bool
      tags: ['facts']
    
    - name: Use cached facts for deployment decisions
      set_fact:
        skip_package_install: "{{ ansible_local.webserver.web_server_installed | default(false) | bool }}"
        needs_service_restart: "{{ not (ansible_local.webserver.web_server_running | default(false) | bool) }}"
      tags: ['facts']
  
  tasks:
    - name: Install web server (conditional)
      package:
        name: httpd
        state: present
      when: not skip_package_install
      tags: ['packages']
    
    - name: Deploy web content
      include_role:
        name: webserver
        tasks_from: main
      tags: ['content']
    
    - name: Start web server (conditional)
      service:
        name: httpd
        state: started
        enabled: yes
      when: needs_service_restart
      tags: ['service']
  
  post_tasks:
    - name: Update custom facts
      shell: /etc/ansible/facts.d/webserver.fact
      register: updated_facts
      changed_when: false
      tags: ['facts_update']
EOF
Task 3: Troubleshoot and Apply Performance Optimizations
Subtask 3.1: Create Monitoring and Troubleshooting Tools
Create a performance monitoring playbook:
cat > playbooks/monitor-performance.yml << 'EOF'
---
- name: Monitor Ansible Performance and System Health
  hosts: webservers
  gather_facts: yes
  become: yes
  
  vars:
    monitoring_duration: 60
    performance_threshold:
      cpu_usage: 80
      memory_usage: 85
      disk_usage: 90
  
  tasks:
    - name: Install monitoring tools
      package:
        name:
          - htop
          - iotop
          - nethogs
          - sysstat
        state: present
      tags: ['monitoring_tools']
    
    - name: Check system performance
      shell: |
        echo "=== CPU Usage ==="
        top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
        echo "=== Memory Usage ==="
        free | grep Mem | awk '{printf "%.1f\n", $3/$2 * 100.0}'
        echo "=== Disk Usage ==="
        df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1
        echo "=== Load Average ==="
        uptime | awk -F'load average:' '{print $2}'
        echo "=== Active Connections ==="
        ss -tuln | wc -l
      register: system_performance
      changed_when: false
      tags: ['performance_check']
    
    - name: Parse performance metrics
      set_fact:
        current_performance:
          cpu_usage: "{{ system_performance.stdout_lines[1] | float }}"
          memory_usage: "{{ system_performance.stdout_lines[3] | float }}"
          disk_usage: "{{ system_performance.stdout_lines[5] | int }}"
          load_average: "{{ system_performance.stdout_lines[7] | trim }}"
          connections: "{{ system_performance.stdout_lines[9] | int }}"
      tags: ['performance_check']
    
    - name: Check performance thresholds
      debug:
        msg: |
          WARNING: Performance threshold exceeded!
          CPU: {{ current_performance.cpu_usage }}% (threshold: {{ performance_threshold.cpu_usage }}%)
          Memory: {{ current_performance.memory_usage }}% (threshold: {{ performance_threshold.memory_usage }}%)
          Disk: {{ current_performance.disk_usage }}% (threshold: {{ performance_threshold.disk_usage }}%)
      when: >
        current_performance.cpu_usage > performance_threshold.cpu_usage or
        current_performance.memory_usage > performance_threshold.memory_usage or
        current_performance.disk_usage > performance_threshold.disk_usage
      tags: ['performance_check']
    
    - name: Log performance metrics
      lineinfile:
        path: /var/log/ansible-performance.log
        line: "{{ ansible_date_time.iso8601 }},{{ inventory_hostname }},{{ current_performance.cpu_usage }},{{ current_performance.memory_usage }},{{ current_performance.disk_usage }},{{ current_performance.connections }}"
        create: yes
      tags: ['logging']
    
    - name: Test web server response time
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ http_port | default(80) }}"
        method: GET
        status_code: 200
      register: response_test
      tags: ['response_test']
    
    - name: Log response time metrics
      lineinfile:
        path: /var/log/ansible-response-times.log
        line: "{{ ansible_date_time.iso8601 }},{{ inventory_hostname }},{{ response_test.elapsed }},{{ response_test.status }}"
        create: yes
      tags: ['logging']
EOF
Create a troubleshooting playbook:
cat > playbooks/troubleshoot-deployment.yml << 'EOF'
---
- name: Troubleshoot Large-Scale Deployment Issues
  hosts: webservers
  gather_facts: yes
  become: yes
  ignore_errors: yes
  
  vars:
    troubleshoot_mode: true
    log_level: debug
  
  tasks:
    - name: Check connectivity to all hosts
      ping:
      register: connectivity_test
      tags: ['connectivity']
    
    - name: Test SSH connection parameters
      shell: |
        echo "SSH Connection Test Results:"
        echo "User: $(whoami)"
        echo "Home: $HOME"
        echo "SSH Agent: $SSH_AUTH_SOCK"
        echo "Current directory: $(pwd)"
        echo "Sudo access: $(sudo -n true 2>/dev/null && echo 'Yes' || echo 'No')"
      register: ssh_test
      changed_when: false
      tags: ['connectivity']
    
    - name: Check system resources
      shell: |
        echo "=== System Resources ==="
        echo "Memory: $(free -h | grep Mem)"
        echo "Disk: $(df -h /)"
        echo "CPU: $(nproc) cores"
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
        echo "=== Network ==="
        echo "Hostname: $(hostname -f)"
        echo "IP: $(hostname -I)"
        echo "=== Services ==="
        systemctl status httpd --no-pager -l || echo "httpd not running"
      register: resource_check
      changed_when: false
      tags: ['resources']
    
    - name: Check for common issues
      shell: |
        echo "=== Common Issues Check ==="
        
        # Check SELinux
        if command -v getenforce >/dev/null 2>&1; then
          echo "SELinux: $(getenforce)"
        fi
        
        # Check firewall
        if systemctl is-active firewalld >/dev/null 2>&1; then
          echo "Firewall: Active"
          firewall-cmd --list-services 2>/dev/null || echo "Cannot list firewall services"
        else
          echo "Firewall: Inactive"
        fi
        
        # Check package manager locks
        if [ -f /var/lib/dpkg/lock ]; then
          echo "APT lock: $(ls -la /var/lib/dpkg/lock* 2>/dev/null || echo 'No locks')"
        fi
        
        if [ -f /var/lib/rpm/.rpm.lock ]; then
          echo "RPM lock: Present"
        else
          echo "RPM lock: None"
        fi
        
        # Check disk space
        echo "Disk usage:"
        df -h | grep -E '(Filesystem|/dev/)'
        
        # Check for zombie processes
        echo "Zombie processes: $(ps aux | awk '$8 ~ /^Z/ { count++ } END { print count+0 }')"
      register: common_issues
      changed_when: false
      tags: ['issues']
    
    - name: Generate troubleshooting report
      copy:
        content: |
          ANSIBLE TROUBLESHOOTING REPORT
          ==============================
          Host: {{ inventory_hostname }}
          Date: {{ ansible_date_time.iso8601 }}
          
          CONNECTIVITY TEST:
          {{ connectivity_test | to_nice_json }}
          
          SSH CONNECTION:
          {{ ssh_test.stdout }}
          
          SYSTEM RESOURCES:
          {{ resource_check.stdout }}
          
          COMMON ISSUES:
          {{ common_issues.stdout }}
          
          ANSIBLE FACTS SUMMARY:
          - OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          - Kernel: {{ ansible_kernel }}
          - Architecture:
