Lab 15: Deploying Systems at Scale with Ansible
Objectives
By the end of this lab, you will be able to:

Create and execute Ansible playbooks to deploy web servers across multiple hosts
Configure Ansible inventories for different environments (development, staging, production)
Implement idempotent deployments that ensure consistent system configurations
Scale deployments efficiently using Ansible's automation capabilities
Troubleshoot common deployment issues in multi-host environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Knowledge of web server concepts (Apache/Nginx)
Understanding of SSH key-based authentication
Basic networking concepts (IP addresses, ports)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machines.

Your lab environment includes:

1 Ansible Control Node (ansible-control)
3 Target Hosts (web-01, web-02, web-03)
Pre-installed Ansible on the control node
SSH keys already configured between hosts
Task 1: Create a Playbook to Deploy and Configure Web Servers
Subtask 1.1: Verify Lab Environment and Connectivity
First, let's verify that our lab environment is properly set up and all hosts are accessible.

Connect to the Ansible Control Node
# You should already be logged into the ansible-control node
whoami
hostname
Verify Ansible Installation
ansible --version
Check SSH connectivity to target hosts
# Test connectivity to all target hosts
ssh web-01 "hostname && whoami"
ssh web-02 "hostname && whoami"
ssh web-03 "hostname && whoami"
Subtask 1.2: Create Basic Inventory File
Create a working directory for our lab
mkdir -p ~/ansible-lab15
cd ~/ansible-lab15
Create a basic inventory file
cat > inventory.ini << 'EOF'
[webservers]
web-01 ansible_host=web-01
web-02 ansible_host=web-02
web-03 ansible_host=web-03

[webservers:vars]
ansible_user=student
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Test the inventory
ansible -i inventory.ini webservers -m ping
Subtask 1.3: Create Web Server Deployment Playbook
Create the main playbook file
cat > deploy-webserver.yml << 'EOF'
---
- name: Deploy and Configure Web Servers at Scale
  hosts: webservers
  become: yes
  vars:
    web_server_port: 80
    document_root: /var/www/html
    server_name: "{{ inventory_hostname }}"
    
  tasks:
    - name: Update package cache (Ubuntu/Debian)
      apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
      
    - name: Update package cache (RHEL/CentOS)
      yum:
        update_cache: yes
      when: ansible_os_family == "RedHat"
      
    - name: Install Apache web server (Ubuntu/Debian)
      apt:
        name: apache2
        state: present
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Install Apache web server (RHEL/CentOS)
      yum:
        name: httpd
        state: present
      when: ansible_os_family == "RedHat"
      notify: restart httpd
      
    - name: Install additional packages
      package:
        name:
          - curl
          - wget
          - unzip
        state: present
        
    - name: Create document root directory
      file:
        path: "{{ document_root }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
      when: ansible_os_family == "Debian"
      
    - name: Create document root directory (RHEL/CentOS)
      file:
        path: "{{ document_root }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
      when: ansible_os_family == "RedHat"
      
    - name: Create custom index.html
      template:
        src: index.html.j2
        dest: "{{ document_root }}/index.html"
        owner: www-data
        group: www-data
        mode: '0644'
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Create custom index.html (RHEL/CentOS)
      template:
        src: index.html.j2
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      when: ansible_os_family == "RedHat"
      notify: restart httpd
      
    - name: Configure Apache virtual host (Ubuntu/Debian)
      template:
        src: vhost.conf.j2
        dest: "/etc/apache2/sites-available/{{ server_name }}.conf"
        backup: yes
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Enable Apache site (Ubuntu/Debian)
      command: a2ensite "{{ server_name }}.conf"
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Disable default Apache site (Ubuntu/Debian)
      command: a2dissite 000-default.conf
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Configure Apache virtual host (RHEL/CentOS)
      template:
        src: vhost.conf.j2
        dest: "/etc/httpd/conf.d/{{ server_name }}.conf"
        backup: yes
      when: ansible_os_family == "RedHat"
      notify: restart httpd
      
    - name: Start and enable Apache service (Ubuntu/Debian)
      systemd:
        name: apache2
        state: started
        enabled: yes
      when: ansible_os_family == "Debian"
      
    - name: Start and enable Apache service (RHEL/CentOS)
      systemd:
        name: httpd
        state: started
        enabled: yes
      when: ansible_os_family == "RedHat"
      
    - name: Configure firewall for HTTP (Ubuntu/Debian)
      ufw:
        rule: allow
        port: "{{ web_server_port }}"
        proto: tcp
      when: ansible_os_family == "Debian"
      
    - name: Configure firewall for HTTP (RHEL/CentOS)
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      when: ansible_os_family == "RedHat"
      
  handlers:
    - name: restart apache
      systemd:
        name: apache2
        state: restarted
      when: ansible_os_family == "Debian"
      
    - name: restart httpd
      systemd:
        name: httpd
        state: restarted
      when: ansible_os_family == "RedHat"
EOF
Subtask 1.4: Create Template Files
Create templates directory
mkdir -p templates
Create HTML template
cat > templates/index.html.j2 << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ server_name }} - Deployed with Ansible</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            color: #333;
            border-bottom: 2px solid #007acc;
            padding-bottom: 10px;
        }
        .info {
            margin: 20px 0;
            padding: 15px;
            background-color: #e7f3ff;
            border-left: 4px solid #007acc;
        }
        .success {
            color: #28a745;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Web Server Successfully Deployed!</h1>
            <h2>{{ server_name }}</h2>
        </div>
        
        <div class="info">
            <h3>Server Information:</h3>
            <ul>
                <li><strong>Hostname:</strong> {{ inventory_hostname }}</li>
                <li><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</li>
                <li><strong>Operating System:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</li>
                <li><strong>Architecture:</strong> {{ ansible_architecture }}</li>
                <li><strong>Deployment Time:</strong> {{ ansible_date_time.iso8601 }}</li>
            </ul>
        </div>
        
        <div class="info">
            <h3>Deployment Details:</h3>
            <ul>
                <li><strong>Deployed by:</strong> Ansible Automation</li>
                <li><strong>Web Server:</strong> Apache HTTP Server</li>
                <li><strong>Document Root:</strong> {{ document_root }}</li>
                <li><strong>Port:</strong> {{ web_server_port }}</li>
            </ul>
        </div>
        
        <div class="success">
            <p>✅ This server was deployed and configured automatically using Ansible!</p>
            <p>🔧 Configuration is idempotent and consistent across all environments.</p>
        </div>
    </div>
</body>
</html>
EOF
Create Apache virtual host template
cat > templates/vhost.conf.j2 << 'EOF'
<VirtualHost *:{{ web_server_port }}>
    ServerName {{ server_name }}
    DocumentRoot {{ document_root }}
    
    <Directory {{ document_root }}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/{{ server_name }}_error.log
    CustomLog ${APACHE_LOG_DIR}/{{ server_name }}_access.log combined
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
</VirtualHost>
EOF
Subtask 1.5: Execute the Deployment Playbook
Run the playbook with verbose output
ansible-playbook -i inventory.ini deploy-webserver.yml -v
Verify the deployment
# Check if Apache is running on all hosts
ansible -i inventory.ini webservers -m shell -a "systemctl status apache2 || systemctl status httpd"

# Test HTTP connectivity
ansible -i inventory.ini webservers -m uri -a "url=http://{{ inventory_hostname }} method=GET"
Test web servers manually
# Test each web server
curl http://web-01
curl http://web-02
curl http://web-03
Task 2: Automate Scaling by Modifying Inventories for Different Environments
Subtask 2.1: Create Environment-Specific Inventories
Create environments directory
mkdir -p environments/{development,staging,production}
Create development environment inventory
cat > environments/development/inventory.ini << 'EOF'
[webservers]
web-01 ansible_host=web-01

[webservers:vars]
ansible_user=student
ansible_ssh_private_key_file=~/.ssh/id_rsa
environment=development
web_server_port=8080
max_connections=50
EOF
Create staging environment inventory
cat > environments/staging/inventory.ini << 'EOF'
[webservers]
web-01 ansible_host=web-01
web-02 ansible_host=web-02

[webservers:vars]
ansible_user=student
ansible_ssh_private_key_file=~/.ssh/id_rsa
environment=staging
web_server_port=80
max_connections=100
EOF
Create production environment inventory
cat > environments/production/inventory.ini << 'EOF'
[webservers]
web-01 ansible_host=web-01
web-02 ansible_host=web-02
web-03 ansible_host=web-03

[load_balancers]
# Future load balancer hosts can be added here

[webservers:vars]
ansible_user=student
ansible_ssh_private_key_file=~/.ssh/id_rsa
environment=production
web_server_port=80
max_connections=200

[production:children]
webservers
load_balancers
EOF
Subtask 2.2: Create Environment-Specific Variable Files
Create group_vars directories
mkdir -p environments/development/group_vars/webservers
mkdir -p environments/staging/group_vars/webservers
mkdir -p environments/production/group_vars/webservers
Create development variables
cat > environments/development/group_vars/webservers/main.yml << 'EOF'
---
# Development Environment Variables
environment_name: "Development"
debug_mode: true
log_level: "debug"
backup_enabled: false
monitoring_enabled: false

# Performance settings for development
worker_processes: 1
worker_connections: 50
keepalive_timeout: 30

# Security settings (relaxed for development)
ssl_enabled: false
security_headers: false

# Application settings
app_version: "latest"
database_pool_size: 5
cache_enabled: false
EOF
Create staging variables
cat > environments/staging/group_vars/webservers/main.yml << 'EOF'
---
# Staging Environment Variables
environment_name: "Staging"
debug_mode: false
log_level: "info"
backup_enabled: true
monitoring_enabled: true

# Performance settings for staging
worker_processes: 2
worker_connections: 100
keepalive_timeout: 60

# Security settings (moderate for staging)
ssl_enabled: false
security_headers: true

# Application settings
app_version: "stable"
database_pool_size: 10
cache_enabled: true
cache_ttl: 300
EOF
Create production variables
cat > environments/production/group_vars/webservers/main.yml << 'EOF'
---
# Production Environment Variables
environment_name: "Production"
debug_mode: false
log_level: "warn"
backup_enabled: true
monitoring_enabled: true

# Performance settings for production
worker_processes: 4
worker_connections: 200
keepalive_timeout: 65

# Security settings (strict for production)
ssl_enabled: true
security_headers: true
fail2ban_enabled: true

# Application settings
app_version: "1.2.3"
database_pool_size: 20
cache_enabled: true
cache_ttl: 600

# Backup settings
backup_schedule: "0 2 * * *"
backup_retention_days: 30
EOF
Subtask 2.3: Create Enhanced Deployment Playbook
Create an enhanced playbook that uses environment variables
cat > deploy-webserver-enhanced.yml << 'EOF'
---
- name: Deploy Web Servers with Environment-Specific Configuration
  hosts: webservers
  become: yes
  vars:
    document_root: /var/www/html
    server_name: "{{ inventory_hostname }}"
    
  tasks:
    - name: Display deployment information
      debug:
        msg: |
          Deploying to {{ environment_name }} environment
          Host: {{ inventory_hostname }}
          Port: {{ web_server_port }}
          Max Connections: {{ max_connections }}
          
    - name: Update package cache (Ubuntu/Debian)
      apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
      
    - name: Install Apache web server (Ubuntu/Debian)
      apt:
        name: apache2
        state: present
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Install additional packages based on environment
      package:
        name: "{{ item }}"
        state: present
      loop:
        - curl
        - wget
        - unzip
        - "{{ 'htop' if debug_mode else 'omit' }}"
        - "{{ 'fail2ban' if fail2ban_enabled | default(false) else 'omit' }}"
      when: item != 'omit'
      
    - name: Create document root directory
      file:
        path: "{{ document_root }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
      when: ansible_os_family == "Debian"
      
    - name: Create environment-specific index.html
      template:
        src: index-enhanced.html.j2
        dest: "{{ document_root }}/index.html"
        owner: www-data
        group: www-data
        mode: '0644'
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Configure Apache with environment-specific settings
      template:
        src: apache-enhanced.conf.j2
        dest: "/etc/apache2/sites-available/{{ server_name }}.conf"
        backup: yes
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Enable Apache modules based on environment
      apache2_module:
        name: "{{ item }}"
        state: present
      loop:
        - rewrite
        - "{{ 'ssl' if ssl_enabled | default(false) else 'omit' }}"
        - "{{ 'headers' if security_headers | default(false) else 'omit' }}"
      when: 
        - ansible_os_family == "Debian"
        - item != 'omit'
      notify: restart apache
      
    - name: Enable Apache site
      command: a2ensite "{{ server_name }}.conf"
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Disable default Apache site
      command: a2dissite 000-default.conf
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Configure Apache port
      lineinfile:
        path: /etc/apache2/ports.conf
        regexp: '^Listen 80'
        line: "Listen {{ web_server_port }}"
        backup: yes
      when: ansible_os_family == "Debian"
      notify: restart apache
      
    - name: Start and enable Apache service
      systemd:
        name: apache2
        state: started
        enabled: yes
      when: ansible_os_family == "Debian"
      
    - name: Configure firewall for HTTP
      ufw:
        rule: allow
        port: "{{ web_server_port }}"
        proto: tcp
      when: ansible_os_family == "Debian"
      
    - name: Create monitoring script (if monitoring enabled)
      template:
        src: monitor.sh.j2
        dest: /usr/local/bin/web-monitor.sh
        mode: '0755'
      when: monitoring_enabled | default(false)
      
    - name: Setup log rotation
      template:
        src: logrotate.j2
        dest: "/etc/logrotate.d/{{ server_name }}"
      when: ansible_os_family == "Debian"
      
  handlers:
    - name: restart apache
      systemd:
        name: apache2
        state: restarted
      when: ansible_os_family == "Debian"
EOF
Create enhanced HTML template
cat > templates/index-enhanced.html.j2 << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ server_name }} - {{ environment_name }} Environment</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, 
                {% if environment_name == "Development" %}#e3f2fd, #bbdefb{% endif %}
                {% if environment_name == "Staging" %}#fff3e0, #ffcc02{% endif %}
                {% if environment_name == "Production" %}#e8f5e8, #4caf50{% endif %}
            );
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            color: #333;
            border-bottom: 3px solid 
                {% if environment_name == "Development" %}#2196f3{% endif %}
                {% if environment_name == "Staging" %}#ff9800{% endif %}
                {% if environment_name == "Production" %}#4caf50{% endif %};
            padding-bottom: 15px;
            margin-bottom: 30px;
        }
        .env-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            color: white;
            font-weight: bold;
            background-color: 
                {% if environment_name == "Development" %}#2196f3{% endif %}
                {% if environment_name == "Staging" %}#ff9800{% endif %}
                {% if environment_name == "Production" %}#4caf50{% endif %};
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin: 20px 0;
        }
        .info-card {
            padding: 20px;
            background-color: #f8f9fa;
            border-left: 4px solid 
                {% if environment_name == "Development" %}#2196f3{% endif %}
                {% if environment_name == "Staging" %}#ff9800{% endif %}
                {% if environment_name == "Production" %}#4caf50{% endif %};
            border-radius: 5px;
        }
        .success {
            color: #28a745;
            font-weight: bold;
            text-align: center;
            margin-top: 30px;
            padding: 20px;
            background-color: #d4edda;
            border-radius: 10px;
        }
        @media (max-width: 768px) {
            .info-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Scalable Web Deployment</h1>
            <h2>{{ server_name }}</h2>
            <span class="env-badge">{{ environment_name }}</span>
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>🖥️ Server Information</h3>
                <ul>
                    <li><strong>Hostname:</strong> {{ inventory_hostname }}</li>
                    <li><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</li>
                    <li><strong>OS:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</li>
                    <li><strong>Architecture:</strong> {{ ansible_architecture }}</li>
                </ul>
            </div>
            
            <div class="info-card">
                <h3>⚙️ Configuration</h3>
                <ul>
                    <li><strong>Environment:</strong> {{ environment_name }}</li>
                    <li><strong>Port:</strong> {{ web_server_port }}</li>
                    <li><strong>Max Connections:</strong> {{ max_connections }}</li>
                    <li><strong>Debug Mode:</strong> {{ debug_mode | default('N/A') }}</li>
                </ul>
            </div>
            
            <div class="info-card">
                <h3>🔧 Performance Settings</h3>
                <ul>
                    <li><strong>Worker Processes:</strong> {{ worker_processes | default('N/A') }}</li>
                    <li><strong>Worker Connections:</strong> {{ worker_connections | default('N/A') }}</li>
                    <li><strong>Keepalive Timeout:</strong> {{ keepalive_timeout | default('N/A') }}s</li>
                    <li><strong>Cache Enabled:</strong> {{ cache_enabled | default('N/A') }}</li>
                </ul>
            </div>
            
            <div class="info-card">
                <h3>🔒 Security & Monitoring</h3>
                <ul>
                    <li><strong>SSL Enabled:</strong> {{ ssl_enabled | default('N/A') }}</li>
                    <li><strong>Security Headers:</strong> {{ security_headers | default('N/A') }}</li>
                    <li><strong>Monitoring:</strong> {{ monitoring_enabled | default('N/A') }}</li>
                    <li><strong>Backup Enabled:</strong> {{ backup_enabled | default('N/A') }}</li>
                </ul>
            </div>
        </div>
        
        <div class="success">
            <p>✅ Server deployed successfully with environment-specific configuration!</p>
            <p>🔄 Deployment is idempotent and scalable across environments</p>
            <p>📊 Configuration optimized for {{ environment_name }} workloads</p>
            <p>⏰ Deployed: {{ ansible_date_time.iso8601 }}</p>
        </div>
    </div>
</body>
</html>
EOF
Create enhanced Apache configuration template
cat > templates/apache-enhanced.conf.j2 << 'EOF'
<VirtualHost *:{{ web_server_port }}>
    ServerName {{ server_name }}
    DocumentRoot {{ document_root }}
    
    # Environment: {{ environment_name }}
    
    <Directory {{ document_root }}>
        Options {% if debug_mode | default(false) %}Indexes {% endif %}FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # Performance tuning based on environment
    MaxRequestWorkers {{ max_connections }}
    KeepAlive On
    KeepAliveTimeout {{ keepalive_timeout | default(60) }}
    
    {% if security_headers | default(false) %}
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    {% endif %}
    
    # Logging configuration
    ErrorLog ${APACHE_LOG_DIR}/{{ server_name }}_error.log
    CustomLog ${APACHE_LOG_DIR}/{{ server_name }}_access.log combined
    LogLevel {{ log_level | default('warn') }}
    
    {% if debug_mode | default(false) %}
    # Debug mode - additional logging
    LogLevel info rewrite:trace3
    {% endif %}
</VirtualHost>
EOF
Create monitoring script template
cat > templates/monitor.sh.j2 << 'EOF'
#!/bin/bash
# Web Server Monitoring Script for {{ environment_name }}
# Generated by Ansible

LOG_FILE="/var/log/web-monitor.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "[$TIMESTAMP] $1" >> $LOG_FILE
}

# Check Apache service status
if systemctl is-active --quiet apache2; then
    log_message "INFO: Apache service is running"
else
    log_message "ERROR: Apache service is not running"
    systemctl restart apache2
    log_message "INFO: Attempted to restart Apache service"
fi

# Check HTTP response
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:{{ web_server_port }})
if [ "$HTTP_CODE" = "200" ]; then
    log_message "INFO: HTTP response OK (200)"
else
    log_message "WARNING: HTTP response code: $HTTP_CODE"
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    log_message "WARNING: Disk usage is ${DISK_USAGE}%"
else
    log_message "INFO: Disk usage is ${DISK_USAGE}%"
fi

# Environment-specific checks
{% if environment_name == "Production" %}
# Production-specific monitoring
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')
log_message "INFO: Memory usage: ${MEMORY_USAGE}%"
{% endif %}
EOF
Create logrotate template
cat > templates/logrotate.j2 << 'EOF'
/var/log/apache2/{{ server_name }}_*.log {
    daily
    missingok
    rotate {% if environment_name == "Production" %}30{% else %}7{% endif %}
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        if /bin/systemctl status apache2 > /dev/null ; then \
            /bin/systemctl reload apache2 > /dev/null; \
        fi;
    endscript
}
EOF
Subtask 2.4: Deploy to Different Environments
Deploy to development environment
ansible-playbook -i environments/development/inventory.ini deploy-webserver-enhanced.yml -v
Deploy to staging environment
ansible-playbook -i environments/staging/inventory.ini deploy-webserver-enhanced.yml -v
Deploy to production environment
ansible-playbook -i environments/production/inventory.ini deploy-webserver-enhanced.yml -v
Verify environment-specific deployments
# Check development (port 8080)
curl http://web-01:8080

# Check staging (port 80, 2 servers)
curl http://web-01
curl http://web-02

# Check production (port 80, 3 servers)
curl http://web-01
curl http://web-02
curl http://web-03
