Lab 13: Managing Hosts in Different Environments
Objectives
By the end of this lab, you will be able to:

Organize Ansible inventory files for different environments (development, staging, production)
Create environment-specific playbooks using variables and group variables
Write playbooks that can target specific environments using tags
Use ansible-playbook command with environment-specific configurations
Implement best practices for managing multi-environment infrastructure
Understand how to maintain separation between different deployment environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and file structure
Basic knowledge of Ansible concepts (playbooks, inventory, modules)
Understanding of SSH key-based authentication
Knowledge of text editors like vim or nano
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your lab environment includes:

1 Ansible Control Node (ansible-control)
3 Target hosts representing different environments:
dev-server (Development environment)
staging-server (Staging environment)
prod-server (Production environment)
Task 1: Organize Inventory for Different Environments
Subtask 1.1: Create Directory Structure
First, let's create a proper directory structure for managing multiple environments.

# Navigate to home directory
cd ~

# Create main project directory
mkdir ansible-environments
cd ansible-environments

# Create directory structure
mkdir -p inventories/{dev,staging,prod}
mkdir -p group_vars/{dev,staging,prod}
mkdir -p host_vars
mkdir playbooks
mkdir roles

# Verify directory structure
tree .
Subtask 1.2: Create Environment-Specific Inventory Files
Create separate inventory files for each environment.

Development Environment Inventory:

# Create development inventory
cat > inventories/dev/hosts << 'EOF'
[webservers]
dev-server ansible_host=192.168.1.10 ansible_user=ec2-user

[databases]
dev-server

[dev:children]
webservers
databases

[dev:vars]
environment=development
app_port=8080
debug_mode=true
EOF
Staging Environment Inventory:

# Create staging inventory
cat > inventories/staging/hosts << 'EOF'
[webservers]
staging-server ansible_host=192.168.1.20 ansible_user=ec2-user

[databases]
staging-server

[loadbalancers]
staging-server

[staging:children]
webservers
databases
loadbalancers

[staging:vars]
environment=staging
app_port=8080
debug_mode=false
EOF
Production Environment Inventory:

# Create production inventory
cat > inventories/prod/hosts << 'EOF'
[webservers]
prod-server ansible_host=192.168.1.30 ansible_user=ec2-user

[databases]
prod-server

[loadbalancers]
prod-server

[monitoring]
prod-server

[prod:children]
webservers
databases
loadbalancers
monitoring

[prod:vars]
environment=production
app_port=80
debug_mode=false
ssl_enabled=true
EOF
Subtask 1.3: Test Inventory Configuration
Verify that your inventory files are correctly configured:

# Test development inventory
ansible-inventory -i inventories/dev/hosts --list

# Test staging inventory
ansible-inventory -i inventories/staging/hosts --list

# Test production inventory
ansible-inventory -i inventories/prod/hosts --list

# Test connectivity to all environments
ansible all -i inventories/dev/hosts -m ping
ansible all -i inventories/staging/hosts -m ping
ansible all -i inventories/prod/hosts -m ping
Task 2: Write Environment-Specific Playbooks Using Variables
Subtask 2.1: Create Group Variables Files
Create group variable files for each environment to store environment-specific configurations.

Development Group Variables:

# Create development group variables
cat > group_vars/dev/main.yml << 'EOF'
---
# Development Environment Variables
environment_name: "development"
app_version: "latest"
database_name: "myapp_dev"
database_user: "dev_user"
database_password: "dev_password"
log_level: "debug"
backup_enabled: false
monitoring_enabled: false

# Application Configuration
app_config:
  max_connections: 10
  timeout: 30
  cache_enabled: false
  
# Security Settings
firewall_rules:
  - port: 22
    protocol: tcp
    source: "0.0.0.0/0"
  - port: 8080
    protocol: tcp
    source: "0.0.0.0/0"
EOF
Staging Group Variables:

# Create staging group variables
cat > group_vars/staging/main.yml << 'EOF'
---
# Staging Environment Variables
environment_name: "staging"
app_version: "v1.2.0"
database_name: "myapp_staging"
database_user: "staging_user"
database_password: "staging_secure_password"
log_level: "info"
backup_enabled: true
monitoring_enabled: true

# Application Configuration
app_config:
  max_connections: 50
  timeout: 60
  cache_enabled: true
  
# Security Settings
firewall_rules:
  - port: 22
    protocol: tcp
    source: "10.0.0.0/8"
  - port: 8080
    protocol: tcp
    source: "10.0.0.0/8"
  - port: 443
    protocol: tcp
    source: "0.0.0.0/0"
EOF
Production Group Variables:

# Create production group variables
cat > group_vars/prod/main.yml << 'EOF'
---
# Production Environment Variables
environment_name: "production"
app_version: "v1.1.5"
database_name: "myapp_prod"
database_user: "prod_user"
database_password: "prod_very_secure_password"
log_level: "warn"
backup_enabled: true
monitoring_enabled: true

# Application Configuration
app_config:
  max_connections: 200
  timeout: 120
  cache_enabled: true
  
# Security Settings
firewall_rules:
  - port: 22
    protocol: tcp
    source: "10.0.0.0/8"
  - port: 80
    protocol: tcp
    source: "0.0.0.0/0"
  - port: 443
    protocol: tcp
    source: "0.0.0.0/0"

# SSL Configuration
ssl_config:
  cert_path: "/etc/ssl/certs/myapp.crt"
  key_path: "/etc/ssl/private/myapp.key"
EOF
Subtask 2.2: Create Environment-Specific Playbooks
Create playbooks that utilize environment-specific variables and can be targeted using tags.

Main Application Deployment Playbook:

# Create main deployment playbook
cat > playbooks/deploy-app.yml << 'EOF'
---
- name: Deploy Application Across Environments
  hosts: webservers
  become: yes
  vars:
    app_name: "myapp"
    app_user: "appuser"
    app_directory: "/opt/{{ app_name }}"
    
  tasks:
    - name: Display Environment Information
      debug:
        msg: |
          Deploying to {{ environment_name }} environment
          App Version: {{ app_version }}
          Database: {{ database_name }}
          Log Level: {{ log_level }}
      tags:
        - info
        - deploy

    - name: Create application user
      user:
        name: "{{ app_user }}"
        system: yes
        shell: /bin/bash
        home: "{{ app_directory }}"
        create_home: yes
      tags:
        - setup
        - users

    - name: Create application directory
      file:
        path: "{{ app_directory }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'
      tags:
        - setup
        - directories

    - name: Install required packages
      package:
        name:
          - python3
          - python3-pip
          - nginx
        state: present
      tags:
        - packages
        - setup

    - name: Configure application settings
      template:
        src: app_config.j2
        dest: "{{ app_directory }}/config.yml"
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0644'
      notify: restart application
      tags:
        - config
        - deploy

    - name: Configure nginx for application
      template:
        src: nginx_app.j2
        dest: /etc/nginx/sites-available/{{ app_name }}
        backup: yes
      notify: restart nginx
      tags:
        - webserver
        - config

    - name: Enable nginx site
      file:
        src: /etc/nginx/sites-available/{{ app_name }}
        dest: /etc/nginx/sites-enabled/{{ app_name }}
        state: link
      notify: restart nginx
      tags:
        - webserver
        - config

    - name: Configure firewall rules
      ufw:
        rule: allow
        port: "{{ item.port }}"
        proto: "{{ item.protocol }}"
        src: "{{ item.source }}"
      loop: "{{ firewall_rules }}"
      when: firewall_rules is defined
      tags:
        - security
        - firewall

    - name: Start and enable nginx
      systemd:
        name: nginx
        state: started
        enabled: yes
      tags:
        - services
        - webserver

  handlers:
    - name: restart application
      systemd:
        name: "{{ app_name }}"
        state: restarted
      listen: restart application

    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
      listen: restart nginx
EOF
Database Configuration Playbook:

# Create database configuration playbook
cat > playbooks/configure-database.yml << 'EOF'
---
- name: Configure Database for Environment
  hosts: databases
  become: yes
  vars:
    mysql_root_password: "root_password_{{ environment_name }}"
    
  tasks:
    - name: Display Database Configuration
      debug:
        msg: |
          Configuring database for {{ environment_name }}
          Database Name: {{ database_name }}
          Database User: {{ database_user }}
          Backup Enabled: {{ backup_enabled }}
      tags:
        - info
        - database

    - name: Install MySQL/MariaDB
      package:
        name:
          - mariadb-server
          - mariadb-client
          - python3-pymysql
        state: present
      tags:
        - packages
        - database

    - name: Start and enable MariaDB
      systemd:
        name: mariadb
        state: started
        enabled: yes
      tags:
        - services
        - database

    - name: Create application database
      mysql_db:
        name: "{{ database_name }}"
        state: present
        login_unix_socket: /var/run/mysqld/mysqld.sock
      tags:
        - database
        - setup

    - name: Create database user
      mysql_user:
        name: "{{ database_user }}"
        password: "{{ database_password }}"
        priv: "{{ database_name }}.*:ALL"
        state: present
        login_unix_socket: /var/run/mysqld/mysqld.sock
      tags:
        - database
        - users

    - name: Configure database backup (production/staging only)
      cron:
        name: "Database backup for {{ database_name }}"
        minute: "0"
        hour: "2"
        job: "mysqldump {{ database_name }} > /backup/{{ database_name }}_$(date +%Y%m%d).sql"
        user: root
      when: backup_enabled | bool
      tags:
        - backup
        - database

    - name: Create backup directory
      file:
        path: /backup
        state: directory
        mode: '0755'
      when: backup_enabled | bool
      tags:
        - backup
        - directories
EOF
Subtask 2.3: Create Template Files
Create template files that will be used by the playbooks.

# Create templates directory
mkdir -p templates

# Create application configuration template
cat > templates/app_config.j2 << 'EOF'
# Application Configuration for {{ environment_name }}
app:
  name: {{ app_name | default('myapp') }}
  version: {{ app_version }}
  environment: {{ environment_name }}
  port: {{ app_port | default(8080) }}
  debug: {{ debug_mode | default(false) }}
  log_level: {{ log_level | default('info') }}

database:
  name: {{ database_name }}
  user: {{ database_user }}
  password: {{ database_password }}
  host: localhost
  port: 3306

{% if app_config is defined %}
performance:
  max_connections: {{ app_config.max_connections }}
  timeout: {{ app_config.timeout }}
  cache_enabled: {{ app_config.cache_enabled }}
{% endif %}

{% if ssl_config is defined and ssl_enabled | default(false) %}
ssl:
  enabled: true
  cert_path: {{ ssl_config.cert_path }}
  key_path: {{ ssl_config.key_path }}
{% endif %}
EOF

# Create nginx configuration template
cat > templates/nginx_app.j2 << 'EOF'
server {
    listen {{ app_port | default(80) }};
    server_name {{ ansible_hostname }};
    
    # Environment: {{ environment_name }}
    
    location / {
        proxy_pass http://127.0.0.1:{{ app_port | default(8080) }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    {% if environment_name == 'production' and ssl_enabled | default(false) %}
    # SSL Configuration for Production
    listen 443 ssl;
    ssl_certificate {{ ssl_config.cert_path }};
    ssl_certificate_key {{ ssl_config.key_path }};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    {% endif %}
    
    # Logging
    access_log /var/log/nginx/{{ app_name | default('myapp') }}_access.log;
    error_log /var/log/nginx/{{ app_name | default('myapp') }}_error.log {{ log_level | default('warn') }};
}
EOF
Task 3: Use ansible-playbook to Target Specific Environments Based on Tags
Subtask 3.1: Create Environment-Specific Execution Scripts
Create wrapper scripts to easily deploy to different environments.

Development Deployment Script:

# Create development deployment script
cat > deploy-dev.sh << 'EOF'
#!/bin/bash

echo "=== Deploying to Development Environment ==="
echo "Environment: Development"
echo "Inventory: inventories/dev/hosts"
echo "=========================================="

# Deploy application to development
ansible-playbook -i inventories/dev/hosts playbooks/deploy-app.yml \
  --tags "setup,deploy,config" \
  --extra-vars "target_env=dev"

# Configure database for development
ansible-playbook -i inventories/dev/hosts playbooks/configure-database.yml \
  --tags "database,setup" \
  --extra-vars "target_env=dev"

echo "=== Development deployment completed ==="
EOF

chmod +x deploy-dev.sh
Staging Deployment Script:

# Create staging deployment script
cat > deploy-staging.sh << 'EOF'
#!/bin/bash

echo "=== Deploying to Staging Environment ==="
echo "Environment: Staging"
echo "Inventory: inventories/staging/hosts"
echo "======================================="

# Deploy application to staging
ansible-playbook -i inventories/staging/hosts playbooks/deploy-app.yml \
  --tags "setup,deploy,config,security" \
  --extra-vars "target_env=staging"

# Configure database for staging
ansible-playbook -i inventories/staging/hosts playbooks/configure-database.yml \
  --tags "database,setup,backup" \
  --extra-vars "target_env=staging"

echo "=== Staging deployment completed ==="
EOF

chmod +x deploy-staging.sh
Production Deployment Script:

# Create production deployment script
cat > deploy-prod.sh << 'EOF'
#!/bin/bash

echo "=== Deploying to Production Environment ==="
echo "Environment: Production"
echo "Inventory: inventories/prod/hosts"
echo "WARNING: This will deploy to PRODUCTION!"
echo "=========================================="

read -p "Are you sure you want to deploy to production? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Production deployment cancelled."
    exit 1
fi

# Deploy application to production
ansible-playbook -i inventories/prod/hosts playbooks/deploy-app.yml \
  --tags "setup,deploy,config,security,webserver" \
  --extra-vars "target_env=prod" \
  --check

read -p "Dry run completed. Proceed with actual deployment? (yes/no): " proceed
if [ "$proceed" != "yes" ]; then
    echo "Production deployment cancelled."
    exit 1
fi

# Actual deployment
ansible-playbook -i inventories/prod/hosts playbooks/deploy-app.yml \
  --tags "setup,deploy,config,security,webserver" \
  --extra-vars "target_env=prod"

# Configure database for production
ansible-playbook -i inventories/prod/hosts playbooks/configure-database.yml \
  --tags "database,setup,backup" \
  --extra-vars "target_env=prod"

echo "=== Production deployment completed ==="
EOF

chmod +x deploy-prod.sh
Subtask 3.2: Test Environment-Specific Deployments
Execute deployments to different environments using tags and inventory files.

Test Development Environment:

# Deploy to development environment
./deploy-dev.sh

# Or run individual commands with specific tags
ansible-playbook -i inventories/dev/hosts playbooks/deploy-app.yml --tags "info"
ansible-playbook -i inventories/dev/hosts playbooks/deploy-app.yml --tags "setup,packages"
Test Staging Environment:

# Deploy to staging environment
./deploy-staging.sh

# Run with specific tags for staging
ansible-playbook -i inventories/staging/hosts playbooks/deploy-app.yml --tags "config,security"
Test Production Environment (Dry Run):

# Run production deployment in check mode first
ansible-playbook -i inventories/prod/hosts playbooks/deploy-app.yml --check --tags "all"

# Deploy specific components to production
ansible-playbook -i inventories/prod/hosts playbooks/deploy-app.yml --tags "webserver,security"
Subtask 3.3: Create Advanced Tag-Based Operations
Create additional playbooks for specific operations across environments.

Monitoring Setup Playbook:

# Create monitoring playbook
cat > playbooks/setup-monitoring.yml << 'EOF'
---
- name: Setup Monitoring for Environment
  hosts: monitoring
  become: yes
  
  tasks:
    - name: Display monitoring setup info
      debug:
        msg: |
          Setting up monitoring for {{ environment_name }}
          Monitoring enabled: {{ monitoring_enabled }}
      tags:
        - info
        - monitoring

    - name: Install monitoring tools
      package:
        name:
          - htop
          - iotop
          - netstat-nat
          - sysstat
        state: present
      when: monitoring_enabled | bool
      tags:
        - monitoring
        - packages

    - name: Configure system monitoring
      template:
        src: monitoring_config.j2
        dest: /etc/monitoring/config.yml
        mode: '0644'
      when: monitoring_enabled | bool
      tags:
        - monitoring
        - config

    - name: Setup log rotation for application logs
      template:
        src: logrotate_app.j2
        dest: /etc/logrotate.d/{{ app_name | default('myapp') }}
        mode: '0644'
      tags:
        - monitoring
        - logs
EOF
Security Hardening Playbook:

# Create security hardening playbook
cat > playbooks/security-hardening.yml << 'EOF'
---
- name: Security Hardening for Environment
  hosts: all
  become: yes
  
  tasks:
    - name: Display security hardening info
      debug:
        msg: |
          Applying security hardening for {{ environment_name }}
          Environment-specific security rules will be applied
      tags:
        - info
        - security

    - name: Update all packages
      package:
        name: "*"
        state: latest
      when: environment_name != "production"
      tags:
        - security
        - updates

    - name: Configure SSH security
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        backup: yes
      loop:
        - { regexp: '^#?PermitRootLogin', line: 'PermitRootLogin no' }
        - { regexp: '^#?PasswordAuthentication', line: 'PasswordAuthentication no' }
        - { regexp: '^#?MaxAuthTries', line: 'MaxAuthTries 3' }
      notify: restart ssh
      tags:
        - security
        - ssh

    - name: Install and configure fail2ban
      package:
        name: fail2ban
        state: present
      tags:
        - security
        - fail2ban

    - name: Configure fail2ban for SSH
      template:
        src: fail2ban_ssh.j2
        dest: /etc/fail2ban/jail.d/ssh.conf
        mode: '0644'
      notify: restart fail2ban
      tags:
        - security
        - fail2ban

  handlers:
    - name: restart ssh
      systemd:
        name: sshd
        state: restarted

    - name: restart fail2ban
      systemd:
        name: fail2ban
        state: restarted
EOF
Subtask 3.4: Execute Tag-Based Operations
Run specific operations across different environments using tags.

# Run monitoring setup only on production and staging
ansible-playbook -i inventories/staging/hosts playbooks/setup-monitoring.yml --tags "monitoring"
ansible-playbook -i inventories/prod/hosts playbooks/setup-monitoring.yml --tags "monitoring"

# Apply security hardening to all environments
ansible-playbook -i inventories/dev/hosts playbooks/security-hardening.yml --tags "security,ssh"
ansible-playbook -i inventories/staging/hosts playbooks/security-hardening.yml --tags "security"
ansible-playbook -i inventories/prod/hosts playbooks/security-hardening.yml --tags "security" --check

# Run only configuration updates across all environments
for env in dev staging prod; do
    echo "Updating configuration for $env environment"
    ansible-playbook -i inventories/$env/hosts playbooks/deploy-app.yml --tags "config"
done

# Run information gathering across all environments
ansible-playbook -i inventories/dev/hosts playbooks/deploy-app.yml --tags "info"
ansible-playbook -i inventories/staging/hosts playbooks/deploy-app.yml --tags "info"
ansible-playbook -i inventories/prod/hosts playbooks/deploy-app.yml --tags "info"
Verification and Testing
Verify Environment Separation
Test that each environment is properly configured and isolated:

# Check environment-specific variables
ansible-playbook -i inventories/dev/hosts playbooks/deploy-app.yml --tags "info" --check
ansible-playbook -i inventories/staging/hosts playbooks/deploy-app.yml --tags "info" --check
ansible-playbook -i inventories/prod/hosts playbooks/deploy-app.yml --tags "info" --check

# Verify inventory organization
ansible-inventory -i inventories/dev/hosts --graph
ansible-inventory -i inventories/staging/hosts --graph
ansible-inventory -i inventories/prod/hosts --graph

# Test connectivity to each environment
ansible all -i inventories/dev/hosts -m setup --tree /tmp/facts_dev
ansible all -i inventories/staging/hosts -m setup --tree /tmp/facts_staging
ansible all -i inventories/prod/hosts -m setup --tree /tmp/facts_prod
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Inventory file not found

# Solution: Verify file paths and permissions
ls -la inventories/*/hosts
ansible-inventory -i inventories/dev/hosts --list
Issue 2: Variables not being applied correctly

# Solution: Check variable precedence and syntax
ansible-playbook -i inventories/dev/hosts playbooks/deploy-app.yml --tags "info" -vv
Issue 3: Tags not working as expected

# Solution: List available tags and verify syntax
ansible-playbook -i inventories/dev/hosts playbooks/deploy-app.yml --list-tags
Issue 4: Template rendering errors

# Solution: Check template syntax and variable availability
ansible-playbook -i inventories/dev/hosts playbooks/deploy-app.yml --tags "config" --check -vv
Conclusion
In this lab, you have successfully learned how to manage hosts across different environments using Ansible. You accomplished the following key objectives:

What You Accomplished:

Environment Organization: Created a structured approach to managing multiple environments (development, staging, production) with separate inventory files and group variables.

Variable Management: Implemented environment-specific configurations using group variables, allowing for different settings across environments while maintaining code reusability.

Tag-Based Deployment: Developed playbooks with comprehensive tagging strategies that enable selective execution of tasks based on environment needs and deployment phases.

Best Practices Implementation: Established proper directory structure, naming conventions, and deployment workflows that follow industry standards for multi-environment management.

Why This Matters:

Risk Mitigation: Proper environment separation prevents accidental deployments to production and allows for thorough testing in lower environments.

Scalability: The structured approach you've learned can easily scale to support additional environments or more complex infrastructure requirements.

Operational Efficiency: Tag-based deployments allow for granular control over what gets deployed when, reducing deployment time and increasing reliability.

Career Relevance: These skills are essential for the Red Hat Certified Engineer (RHCE) certification and are highly valued in DevOps and system administration roles.

Real-World Application: The techniques you've practiced mirror real-world enterprise environments where managing multiple deployment stages is critical for successful software delivery.

You now have the foundation to manage complex, multi-environment infrastructure using Ansible, with the ability to maintain consistency while allowing for environment-specific customizations. This knowledge will serve you well in professional environments where reliable, repeatable deployments across multiple environments are essential for business success.
