Lab 18: Managing Infrastructure as Code (IaC)
Lab Objectives
By the end of this lab, students will be able to:

Understand the fundamental principles of Infrastructure as Code (IaC)
Create and execute Ansible playbooks to automate cloud resource deployment
Implement variables and Jinja2 templates for standardized infrastructure deployments
Apply version control best practices to manage Ansible playbooks
Deploy and manage cloud infrastructure using declarative configuration files
Troubleshoot common IaC deployment issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Basic knowledge of cloud computing concepts
Understanding of SSH key-based authentication
Basic Git version control knowledge
Familiarity with text editors (vim, nano, or VS Code)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or install additional software.

Your lab environment includes:

Control node with Ansible pre-installed
Target nodes for infrastructure deployment
Git repository access
Pre-configured SSH keys for seamless connectivity
Task 1: Write Ansible Playbooks to Automate Cloud Resource Deployment
Subtask 1.1: Understanding Infrastructure as Code Concepts
Infrastructure as Code (IaC) is a practice where infrastructure is provisioned and managed using code and software development techniques, rather than manual processes.

Key Benefits of IaC:

Consistency: Eliminates configuration drift
Repeatability: Deploy identical environments multiple times
Version Control: Track changes and rollback when needed
Automation: Reduce manual errors and deployment time
Subtask 1.2: Setting Up the Ansible Environment
First, let's verify our Ansible installation and set up the working directory:

# Check Ansible version
ansible --version

# Create project directory structure
mkdir -p ~/iac-lab/{playbooks,inventory,group_vars,host_vars,templates,roles}
cd ~/iac-lab

# Create initial inventory file
cat > inventory/hosts.yml << EOF
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
    loadbalancers:
      hosts:
        lb1:
          ansible_host: 192.168.1.30
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
EOF
Subtask 1.3: Creating Your First Infrastructure Playbook
Create a comprehensive playbook that deploys a basic web infrastructure:

# Create the main infrastructure playbook
cat > playbooks/deploy-infrastructure.yml << 'EOF'
---
- name: Deploy Web Infrastructure
  hosts: all
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Update system packages
      apt:
        update_cache: yes
        upgrade: dist
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
    
    - name: Install common packages
      apt:
        name:
          - curl
          - wget
          - htop
          - vim
          - git
        state: present
      when: ansible_os_family == "Debian"

- name: Configure Web Servers
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install Apache web server
      apt:
        name: apache2
        state: present
    
    - name: Start and enable Apache service
      systemd:
        name: apache2
        state: started
        enabled: yes
    
    - name: Configure firewall for web traffic
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "80"
        - "443"
        - "22"
    
    - name: Create web content directory
      file:
        path: /var/www/html/app
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'

- name: Configure Database Servers
  hosts: databases
  become: yes
  
  tasks:
    - name: Install MySQL server
      apt:
        name:
          - mysql-server
          - python3-pymysql
        state: present
    
    - name: Start and enable MySQL service
      systemd:
        name: mysql
        state: started
        enabled: yes
    
    - name: Configure firewall for database traffic
      ufw:
        rule: allow
        port: "3306"
        proto: tcp
        src: "192.168.1.0/24"

- name: Configure Load Balancer
  hosts: loadbalancers
  become: yes
  
  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present
    
    - name: Start and enable Nginx service
      systemd:
        name: nginx
        state: started
        enabled: yes
    
    - name: Configure firewall for load balancer
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "80"
        - "443"
        - "22"
EOF
Subtask 1.4: Creating a Cloud Resource Provisioning Playbook
Now, let's create a playbook that simulates cloud resource provisioning:

# Create cloud provisioning playbook
cat > playbooks/provision-cloud-resources.yml << 'EOF'
---
- name: Provision Cloud Infrastructure
  hosts: localhost
  connection: local
  gather_facts: no
  
  vars:
    cloud_resources:
      - name: "web-server-1"
        type: "compute"
        size: "medium"
        os: "ubuntu-20.04"
        region: "us-east-1"
      - name: "web-server-2"
        type: "compute"
        size: "medium"
        os: "ubuntu-20.04"
        region: "us-east-1"
      - name: "database-server"
        type: "compute"
        size: "large"
        os: "ubuntu-20.04"
        region: "us-east-1"
      - name: "load-balancer"
        type: "compute"
        size: "small"
        os: "ubuntu-20.04"
        region: "us-east-1"
  
  tasks:
    - name: Create resource provisioning log directory
      file:
        path: /tmp/cloud-provisioning
        state: directory
        mode: '0755'
    
    - name: Simulate cloud resource provisioning
      shell: |
        echo "Provisioning {{ item.name }}..."
        echo "Type: {{ item.type }}"
        echo "Size: {{ item.size }}"
        echo "OS: {{ item.os }}"
        echo "Region: {{ item.region }}"
        echo "Status: Provisioned at $(date)"
        echo "---"
      loop: "{{ cloud_resources }}"
      register: provisioning_results
    
    - name: Save provisioning results to file
      copy:
        content: |
          Cloud Infrastructure Provisioning Report
          Generated: {{ ansible_date_time.iso8601 }}
          
          {% for result in provisioning_results.results %}
          {{ result.stdout }}
          {% endfor %}
        dest: "/tmp/cloud-provisioning/provisioning-report-{{ ansible_date_time.epoch }}.txt"
    
    - name: Display provisioning summary
      debug:
        msg: |
          Successfully simulated provisioning of {{ cloud_resources | length }} resources.
          Report saved to: /tmp/cloud-provisioning/provisioning-report-{{ ansible_date_time.epoch }}.txt
EOF
Subtask 1.5: Testing the Infrastructure Playbook
Execute the playbooks to test your infrastructure deployment:

# Test the playbook syntax
ansible-playbook -i inventory/hosts.yml playbooks/deploy-infrastructure.yml --syntax-check

# Run the cloud provisioning playbook
ansible-playbook playbooks/provision-cloud-resources.yml

# Check the provisioning report
ls -la /tmp/cloud-provisioning/
cat /tmp/cloud-provisioning/provisioning-report-*.txt
Task 2: Use Variables and Templates to Standardize Infrastructure Deployments
Subtask 2.1: Creating Group Variables
Organize your variables to make deployments more flexible and maintainable:

# Create group variables for all hosts
cat > group_vars/all.yml << 'EOF'
---
# Global configuration variables
project_name: "iac-demo"
environment: "production"
admin_email: "admin@company.com"

# Common packages to install on all servers
common_packages:
  - curl
  - wget
  - htop
  - vim
  - git
  - unzip

# Security settings
ssh_port: 22
firewall_enabled: true

# Backup configuration
backup_enabled: true
backup_retention_days: 30

# Monitoring settings
monitoring_enabled: true
log_level: "info"
EOF

# Create web server specific variables
cat > group_vars/webservers.yml << 'EOF'
---
# Web server configuration
web_server_package: "apache2"
web_server_service: "apache2"
web_server_port: 80
web_server_ssl_port: 443

# Application settings
app_name: "demo-app"
app_version: "1.0.0"
app_port: 8080

# Performance tuning
max_connections: 1000
worker_processes: 4

# SSL configuration
ssl_enabled: true
ssl_cert_path: "/etc/ssl/certs"
ssl_key_path: "/etc/ssl/private"
EOF

# Create database server specific variables
cat > group_vars/databases.yml << 'EOF'
---
# Database configuration
db_engine: "mysql"
db_version: "8.0"
db_port: 3306
db_name: "application_db"
db_user: "app_user"
db_password: "SecurePassword123!"

# Performance settings
max_connections: 200
innodb_buffer_pool_size: "1G"
query_cache_size: "256M"

# Backup settings
db_backup_enabled: true
db_backup_schedule: "0 2 * * *"  # Daily at 2 AM
EOF

# Create load balancer specific variables
cat > group_vars/loadbalancers.yml << 'EOF'
---
# Load balancer configuration
lb_algorithm: "round_robin"
lb_health_check_interval: 30
lb_timeout: 5

# Backend servers
backend_servers:
  - { name: "web1", ip: "192.168.1.10", port: 80, weight: 1 }
  - { name: "web2", ip: "192.168.1.11", port: 80, weight: 1 }

# SSL termination
ssl_termination: true
ssl_protocols: "TLSv1.2 TLSv1.3"
EOF
Subtask 2.2: Creating Jinja2 Templates
Templates allow you to create dynamic configuration files:

# Create templates directory structure
mkdir -p templates/{apache,nginx,mysql}

# Create Apache virtual host template
cat > templates/apache/vhost.conf.j2 << 'EOF'
<VirtualHost *:{{ web_server_port }}>
    ServerName {{ inventory_hostname }}.{{ project_name }}.local
    ServerAlias {{ inventory_hostname }}
    DocumentRoot /var/www/html/{{ app_name }}
    
    # Logging
    ErrorLog ${APACHE_LOG_DIR}/{{ app_name }}_error.log
    CustomLog ${APACHE_LOG_DIR}/{{ app_name }}_access.log combined
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    
    # Application specific settings
    <Directory /var/www/html/{{ app_name }}>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # Performance settings
    MaxRequestWorkers {{ max_connections }}
    
    {% if ssl_enabled %}
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile {{ ssl_cert_path }}/{{ inventory_hostname }}.crt
    SSLCertificateKeyFile {{ ssl_key_path }}/{{ inventory_hostname }}.key
    SSLProtocol all -SSLv2 -SSLv3
    {% endif %}
</VirtualHost>
EOF

# Create Nginx load balancer configuration template
cat > templates/nginx/load-balancer.conf.j2 << 'EOF'
upstream {{ app_name }}_backend {
    {% for server in backend_servers %}
    server {{ server.ip }}:{{ server.port }} weight={{ server.weight }};
    {% endfor %}
}

server {
    listen {{ web_server_port }};
    server_name {{ inventory_hostname }}.{{ project_name }}.local;
    
    # Load balancing configuration
    location / {
        proxy_pass http://{{ app_name }}_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Health check settings
        proxy_connect_timeout {{ lb_timeout }}s;
        proxy_send_timeout {{ lb_timeout }}s;
        proxy_read_timeout {{ lb_timeout }}s;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    {% if ssl_enabled %}
    # SSL Configuration
    listen {{ web_server_ssl_port }} ssl;
    ssl_certificate {{ ssl_cert_path }}/{{ inventory_hostname }}.crt;
    ssl_certificate_key {{ ssl_key_path }}/{{ inventory_hostname }}.key;
    ssl_protocols {{ ssl_protocols }};
    {% endif %}
}
EOF

# Create MySQL configuration template
cat > templates/mysql/my.cnf.j2 << 'EOF'
[mysqld]
# Basic settings
port = {{ db_port }}
bind-address = 0.0.0.0
datadir = /var/lib/mysql
socket = /var/run/mysqld/mysqld.sock

# Performance tuning
max_connections = {{ max_connections }}
innodb_buffer_pool_size = {{ innodb_buffer_pool_size }}
query_cache_size = {{ query_cache_size }}
query_cache_type = 1

# Security settings
skip-name-resolve
local-infile = 0

# Logging
log-error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Binary logging for replication
server-id = {{ ansible_default_ipv4.address.split('.')[-1] }}
log-bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7

# Character set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4

[client]
default-character-set = utf8mb4
port = {{ db_port }}
socket = /var/run/mysqld/mysqld.sock
EOF
Subtask 2.3: Creating an Advanced Playbook with Variables and Templates
Now create a comprehensive playbook that uses variables and templates:

cat > playbooks/deploy-with-templates.yml << 'EOF'
---
- name: Deploy Infrastructure with Templates and Variables
  hosts: all
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Update system packages
      apt:
        update_cache: yes
        upgrade: dist
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
    
    - name: Install common packages
      apt:
        name: "{{ common_packages }}"
        state: present
      when: ansible_os_family == "Debian"
    
    - name: Create project directory
      file:
        path: "/opt/{{ project_name }}"
        state: directory
        mode: '0755'
    
    - name: Generate server information file
      template:
        src: server-info.txt.j2
        dest: "/opt/{{ project_name }}/server-info.txt"
        mode: '0644'

- name: Configure Web Servers with Templates
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install web server
      apt:
        name: "{{ web_server_package }}"
        state: present
    
    - name: Install additional Apache modules
      apt:
        name:
          - libapache2-mod-ssl
          - libapache2-mod-headers
        state: present
      when: web_server_package == "apache2"
    
    - name: Enable Apache modules
      apache2_module:
        name: "{{ item }}"
        state: present
      loop:
        - ssl
        - headers
        - rewrite
      when: web_server_package == "apache2"
      notify: restart apache
    
    - name: Create application directory
      file:
        path: "/var/www/html/{{ app_name }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
    
    - name: Deploy Apache virtual host configuration
      template:
        src: apache/vhost.conf.j2
        dest: "/etc/apache2/sites-available/{{ app_name }}.conf"
        backup: yes
      when: web_server_package == "apache2"
      notify: restart apache
    
    - name: Enable Apache virtual host
      command: a2ensite {{ app_name }}.conf
      when: web_server_package == "apache2"
      notify: restart apache
    
    - name: Create sample application file
      template:
        src: index.html.j2
        dest: "/var/www/html/{{ app_name }}/index.html"
        owner: www-data
        group: www-data
        mode: '0644'
    
    - name: Start and enable web server service
      systemd:
        name: "{{ web_server_service }}"
        state: started
        enabled: yes

- name: Configure Database Servers with Templates
  hosts: databases
  become: yes
  
  tasks:
    - name: Install MySQL server
      apt:
        name:
          - mysql-server
          - python3-pymysql
        state: present
    
    - name: Deploy MySQL configuration
      template:
        src: mysql/my.cnf.j2
        dest: /etc/mysql/mysql.conf.d/custom.cnf
        backup: yes
      notify: restart mysql
    
    - name: Start and enable MySQL service
      systemd:
        name: mysql
        state: started
        enabled: yes
    
    - name: Create application database
      mysql_db:
        name: "{{ db_name }}"
        state: present
        login_unix_socket: /var/run/mysqld/mysqld.sock
    
    - name: Create database user
      mysql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        priv: "{{ db_name }}.*:ALL"
        host: "192.168.1.%"
        state: present
        login_unix_socket: /var/run/mysqld/mysqld.sock

- name: Configure Load Balancer with Templates
  hosts: loadbalancers
  become: yes
  
  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present
    
    - name: Deploy Nginx load balancer configuration
      template:
        src: nginx/load-balancer.conf.j2
        dest: "/etc/nginx/sites-available/{{ app_name }}-lb"
        backup: yes
      notify: restart nginx
    
    - name: Enable Nginx site
      file:
        src: "/etc/nginx/sites-available/{{ app_name }}-lb"
        dest: "/etc/nginx/sites-enabled/{{ app_name }}-lb"
        state: link
      notify: restart nginx
    
    - name: Remove default Nginx site
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      notify: restart nginx
    
    - name: Start and enable Nginx service
      systemd:
        name: nginx
        state: started
        enabled: yes
  
  handlers:
    - name: restart apache
      systemd:
        name: apache2
        state: restarted
    
    - name: restart mysql
      systemd:
        name: mysql
        state: restarted
    
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
EOF
Subtask 2.4: Creating Additional Templates
Create the remaining templates referenced in the playbook:

# Create server information template
cat > templates/server-info.txt.j2 << 'EOF'
Server Information Report
========================
Generated: {{ ansible_date_time.iso8601 }}
Project: {{ project_name }}
Environment: {{ environment }}

Server Details:
- Hostname: {{ inventory_hostname }}
- IP Address: {{ ansible_default_ipv4.address }}
- Operating System: {{ ansible_distribution }} {{ ansible_distribution_version }}
- Architecture: {{ ansible_architecture }}
- CPU Cores: {{ ansible_processor_vcpus }}
- Memory: {{ ansible_memtotal_mb }} MB

{% if inventory_hostname in groups['webservers'] %}
Web Server Configuration:
- Package: {{ web_server_package }}
- Port: {{ web_server_port }}
- SSL Port: {{ web_server_ssl_port }}
- Application: {{ app_name }} v{{ app_version }}
- Max Connections: {{ max_connections }}
{% endif %}

{% if inventory_hostname in groups['databases'] %}
Database Configuration:
- Engine: {{ db_engine }}
- Version: {{ db_version }}
- Port: {{ db_port }}
- Database: {{ db_name }}
- Max Connections: {{ max_connections }}
{% endif %}

{% if inventory_hostname in groups['loadbalancers'] %}
Load Balancer Configuration:
- Algorithm: {{ lb_algorithm }}
- Health Check Interval: {{ lb_health_check_interval }}s
- Backend Servers: {{ backend_servers | length }}
{% endif %}

Contact: {{ admin_email }}
EOF

# Create sample application template
cat > templates/index.html.j2 << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ app_name | title }} - {{ environment | title }}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f4f4f4; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { color: #333; border-bottom: 2px solid #007acc; padding-bottom: 10px; }
        .info { margin: 20px 0; }
        .status { color: #28a745; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">{{ app_name | title }} Application</h1>
        <p class="status">✓ Application is running successfully!</p>
        
        <div class="info">
            <h2>Server Information</h2>
            <table>
                <tr><th>Property</th><th>Value</th></tr>
                <tr><td>Server Name</td><td>{{ inventory_hostname }}</td></tr>
                <tr><td>IP Address</td><td>{{ ansible_default_ipv4.address }}</td></tr>
                <tr><td>Environment</td><td>{{ environment | title }}</td></tr>
                <tr><td>Application Version</td><td>{{ app_version }}</td></tr>
                <tr><td>Deployment Time</td><td>{{ ansible_date_time.iso8601 }}</td></tr>
                <tr><td>Operating System</td><td>{{ ansible_distribution }} {{ ansible_distribution_version }}</td></tr>
            </table>
        </div>
        
        <div class="info">
            <h2>Application Status</h2>
            <p>This page was generated automatically using Infrastructure as Code (IaC) principles with Ansible.</p>
            <p>Project: <strong>{{ project_name }}</strong></p>
            <p>Contact: <a href="mailto:{{ admin_email }}">{{ admin_email }}</a></p>
        </div>
    </div>
</body>
</html>
EOF
Subtask 2.5: Testing the Template-Based Deployment
Execute the enhanced playbook with templates:

# Test the playbook syntax
ansible-playbook -i inventory/hosts.yml playbooks/deploy-with-templates.yml --syntax-check

# Run the playbook with verbose output
ansible-playbook -i inventory/hosts.yml playbooks/deploy-with-templates.yml -v

# Verify the generated configuration files
ansible all -i inventory/hosts.yml -m shell -a "ls -la /opt/{{ project_name }}/"
ansible webservers -i inventory/hosts.yml -m shell -a "cat /etc/apache2/sites-available/{{ app_name }}.conf"
Task 3: Apply Version Control to Playbook Management
Subtask 3.1: Initialize Git Repository
Set up version control for your Infrastructure as Code project:

# Initialize Git repository
cd ~/iac-lab
git init

# Create .gitignore file
cat > .gitignore << 'EOF'
# Ansible specific
*.retry
.vault_pass
host_vars/*/vault.yml

# Temporary files
*.tmp
*.log
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Backup files
*.bak
*.backup
*~

# Environment specific
.env
.env.local
.env.production

# Generated files
/tmp/
/logs/
EOF

# Configure Git user (if not already configured)
git config user.name "IaC Administrator"
git config user.email "iac-admin@company.com"

# Add all files to Git
git add .

# Create initial commit
git commit -m "Initial commit: Infrastructure as Code project setup

- Added Ansible playbooks for infrastructure deployment
- Implemented variables and templates for standardization
- Created inventory and group variable files
- Added comprehensive documentation"
Subtask 3.2: Creating a Branching Strategy
Implement a proper branching strategy for infrastructure management:

# Create development branch
git checkout -b development
git push -u origin development

# Create feature branch for new infrastructure components
git checkout -b feature/monitoring-setup
git push -u origin feature/monitoring-setup

# Create a hotfix branch
git checkout main
git checkout -b hotfix/security-updates
git push -u origin hotfix/security-updates

# List all branches
git branch -a
Subtask 3.3: Creating Infrastructure Versioning
Implement proper versioning for your infrastructure:

# Create version file
cat > VERSION << 'EOF'
MAJOR=1
MINOR=0
PATCH=0
BUILD=1
VERSION=1.0.0
EOF

# Create infrastructure metadata file
cat > infrastructure.yml << 'EOF'
---
infrastructure:
  name: "Demo Infrastructure"
  version: "1.0.0"
  description: "Complete web application infrastructure with load balancing"
  
  components:
    webservers:
      count: 2
      type: "apache"
      version: "2.4"
    
    databases:
      count: 1
      type: "mysql"
      version: "8.0"
    
    loadbalancers:
      count: 1
      type: "nginx"
      version: "1.18"
  
  environments:
    - development
    - staging
    - production
  
  maintainers:
    - name: "Infrastructure Team"
      email: "infrastructure@company.com"
  
  last_updated: "2024-01-15"
  
  dependencies:
    ansible_version: ">=2.9"
    python_version: ">=3.6"
EOF

# Add and commit versioning files
git add VERSION infrastructure.yml
git commit -m "Add infrastructure versioning and metadata"
Subtask 3.4: Creating Release Management
Implement proper release management for infrastructure deployments:

# Create release preparation script
cat > scripts/prepare-release.sh << 'EOF'
#!/bin/bash

# Infrastructure Release Preparation Script
set -e

echo "=== Infrastructure Release Preparation ==="

# Read current version
source VERSION

echo "Current version: $VERSION"

# Validate playbooks
echo "Validating Ansible playbooks..."
for playbook in playbooks/*.yml; do
    echo "Checking $playbook..."
    ansible-playbook "$playbook" --syntax-check
done

# Run tests
echo "Running infrastructure tests..."
ansible-playbook playbooks/test-infrastructure.yml --check

# Generate changelog
echo "Generating changelog..."
git log --oneline --since="$(git describe --tags --abbrev=0 2>/dev/null || echo '1 month ago')" > CHANGELOG.tmp

# Create release notes
cat > RELEASE_NOTES.md << EOL
# Release Notes - Version $VERSION

## Changes in this release:
$(cat CHANGELOG.tmp)

## Infrastructure Components:
- Web Servers: $(grep -A 10 "webservers:" infrastructure.yml | grep "count:" | awk '{print $2}') instances
- Database Servers: $(grep -A 10 "databases:" infrastructure.yml | grep "count:" | awk '{print $2}') instances  
- Load Balancers: $(grep -A 10 "loadbalancers:" infrastructure.yml | grep "count:" | awk '{print $2}') instances

## Deployment Instructions:
1. Review the changes in this release
2. Test in development environment first
3. Deploy to staging for validation
4. Deploy to production during maintenance window

## Rollback Plan:
If issues occur, rollback using:
\`\`\`bash
git checkout <previous-tag>
ansible-playbook playbooks/deploy-infrastructure.yml
\`\`\`

Generated: $(date)
EOL

rm CHANGELOG.tmp

echo "Release preparation completed!"
echo "Review RELEASE_NOTES.md before creating the release tag."
EOF

# Make script executable
chmod +x scripts/prepare-release.sh

# Create infrastructure testing playbook
cat > playbooks/test-infrastructure.yml << 'EOF'
---
- name: Test Infrastructure Deployment
  hosts: all
  gather_facts: yes
  
  tasks:
    - name: Check if servers are reachable
      ping:
    
    - name: Verify system uptime
      command: uptime
      register: uptime_result
    
    - name: Display uptime
      debug:
        msg: "{{ inventory_hostname }} uptime: {{ uptime_result.stdout }}"

- name: Test Web Servers
  hosts: webservers
  
  tasks:
    - name: Check if Apache is running
      systemd:
        name: apache2
      register: apache_status
    
    - name: Verify Apache is active
      assert:
        that:
          - apache_status.status.ActiveState == "active"
        fail_msg: "Apache is not running on {{ inventory_hostname }}"
        success_msg: "Apache is running correctly on {{ inventory_hostname }}"
    
    - name
Lab Terminal

Instructions
