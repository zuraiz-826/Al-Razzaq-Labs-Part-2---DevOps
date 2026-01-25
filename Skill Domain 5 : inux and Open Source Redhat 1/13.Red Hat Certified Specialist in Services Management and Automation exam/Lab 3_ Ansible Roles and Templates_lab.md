Lab 3: Ansible Roles and Templates
Objectives
By the end of this lab, students will be able to:

Understand the concept and benefits of Ansible roles for code organization and reusability
Create a structured Ansible role for Apache HTTP Server installation and configuration
Implement Jinja2 templates to dynamically manage configuration files
Execute playbooks that utilize custom roles to automate service deployment
Apply best practices for role structure and template management
Troubleshoot common issues with roles and templates
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Completion of previous Ansible labs or equivalent knowledge of:
Ansible playbook creation and execution
Basic Ansible modules (yum/apt, service, copy, file)
Inventory file configuration
Understanding of Apache HTTP Server basics
Text editor proficiency (vim, nano, or similar)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

Control Node: CentOS/RHEL 8 or Ubuntu 20.04 with Ansible pre-installed
Managed Nodes: 2-3 target servers for Apache deployment
All necessary networking and SSH key configurations completed
Task 1: Understanding Ansible Roles Structure
Subtask 1.1: Explore the Standard Role Directory Structure
First, let's understand what Ansible roles are and why they're important.

What are Ansible Roles? Roles are a way to organize playbooks and related files in a structured manner. They promote reusability, maintainability, and sharing of automation code.

Connect to your control node and navigate to your home directory:
cd ~
Create a project directory for this lab:
mkdir ansible-roles-lab
cd ansible-roles-lab
Examine the standard role structure by creating a sample role:
ansible-galaxy init apache-role
Explore the created directory structure:
tree apache-role
You should see output similar to:

apache-role/
├── README.md
├── defaults/
│   └── main.yml
├── files/
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   └── main.yml
├── templates/
├── tests/
│   ├── inventory
│   └── test.yml
└── vars/
    └── main.yml
Subtask 1.2: Understanding Each Directory's Purpose
Let's examine what each directory contains:

View the purpose of each directory:
echo "=== Role Directory Structure ==="
echo "tasks/     - Main logic and tasks"
echo "handlers/  - Event-driven tasks (like service restarts)"
echo "templates/ - Jinja2 template files"
echo "files/     - Static files to copy"
echo "vars/      - Role-specific variables"
echo "defaults/  - Default variable values"
echo "meta/      - Role metadata and dependencies"
Task 2: Creating an Apache HTTP Server Role
Subtask 2.1: Define Role Variables and Defaults
Edit the defaults file to set default values:
vim apache-role/defaults/main.yml
Add the following default variables:
---
# defaults file for apache-role

# Apache package name (varies by OS)
apache_package: httpd

# Apache service name
apache_service: httpd

# Apache configuration directory
apache_config_dir: /etc/httpd/conf.d

# Apache document root
apache_document_root: /var/www/html

# Apache listen port
apache_port: 80

# Apache server name
apache_server_name: "{{ ansible_fqdn }}"

# Apache admin email
apache_admin_email: admin@example.com

# Custom index page content
apache_index_content: |
  <html>
  <head>
    <title>Welcome to Apache</title>
  </head>
  <body>
    <h1>Apache HTTP Server Deployed with Ansible</h1>
    <p>Server: {{ ansible_hostname }}</p>
    <p>IP Address: {{ ansible_default_ipv4.address }}</p>
  </body>
  </html>
Create OS-specific variables for different distributions:
mkdir -p apache-role/vars
vim apache-role/vars/RedHat.yml
Add RedHat/CentOS specific variables:
---
# RedHat/CentOS specific variables
apache_package: httpd
apache_service: httpd
apache_config_dir: /etc/httpd/conf.d
apache_user: apache
apache_group: apache
Create Ubuntu/Debian specific variables:
vim apache-role/vars/Debian.yml
---
# Ubuntu/Debian specific variables
apache_package: apache2
apache_service: apache2
apache_config_dir: /etc/apache2/sites-available
apache_user: www-data
apache_group: www-data
Subtask 2.2: Create the Main Tasks
Edit the main tasks file:
vim apache-role/tasks/main.yml
Add the following tasks:
---
# tasks file for apache-role

- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"
  tags: always

- name: Install Apache HTTP Server
  package:
    name: "{{ apache_package }}"
    state: present
  become: yes
  notify: restart apache

- name: Ensure Apache is started and enabled
  service:
    name: "{{ apache_service }}"
    state: started
    enabled: yes
  become: yes

- name: Create custom Apache configuration from template
  template:
    src: apache-custom.conf.j2
    dest: "{{ apache_config_dir }}/custom.conf"
    owner: root
    group: root
    mode: '0644'
  become: yes
  notify: restart apache
  when: ansible_os_family == "RedHat"

- name: Create custom index page from template
  template:
    src: index.html.j2
    dest: "{{ apache_document_root }}/index.html"
    owner: "{{ apache_user }}"
    group: "{{ apache_group }}"
    mode: '0644'
  become: yes

- name: Open firewall for HTTP (RedHat/CentOS)
  firewalld:
    service: http
    permanent: yes
    state: enabled
    immediate: yes
  become: yes
  when: ansible_os_family == "RedHat"
  ignore_errors: yes

- name: Open firewall for HTTP (Ubuntu/Debian)
  ufw:
    rule: allow
    port: "{{ apache_port }}"
    proto: tcp
  become: yes
  when: ansible_os_family == "Debian"
  ignore_errors: yes
Subtask 2.3: Create Handlers
Edit the handlers file:
vim apache-role/handlers/main.yml
Add restart handler:
---
# handlers file for apache-role

- name: restart apache
  service:
    name: "{{ apache_service }}"
    state: restarted
  become: yes
  listen: restart apache

- name: reload apache
  service:
    name: "{{ apache_service }}"
    state: reloaded
  become: yes
  listen: reload apache
Task 3: Creating Jinja2 Templates
Subtask 3.1: Create Apache Configuration Template
Create the Apache configuration template:
vim apache-role/templates/apache-custom.conf.j2
Add the following template content:
# Custom Apache Configuration
# Generated by Ansible on {{ ansible_date_time.iso8601 }}

# Server configuration
ServerName {{ apache_server_name }}
ServerAdmin {{ apache_admin_email }}

# Listen on specified port
Listen {{ apache_port }}

# Virtual Host Configuration
<VirtualHost *:{{ apache_port }}>
    ServerName {{ apache_server_name }}
    DocumentRoot {{ apache_document_root }}
    
    # Logging
    ErrorLog logs/{{ ansible_hostname }}_error.log
    CustomLog logs/{{ ansible_hostname }}_access.log combined
    
    # Directory permissions
    <Directory "{{ apache_document_root }}">
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
</VirtualHost>

# Server information
ServerTokens Prod
ServerSignature Off

# Performance tuning
{% if ansible_memtotal_mb > 1024 %}
# High memory server configuration
StartServers 8
MinSpareServers 5
MaxSpareServers 20
MaxRequestWorkers 256
{% else %}
# Low memory server configuration
StartServers 2
MinSpareServers 2
MaxSpareServers 10
MaxRequestWorkers 150
{% endif %}
Subtask 3.2: Create Dynamic Index Page Template
Create the index page template:
vim apache-role/templates/index.html.j2
Add dynamic HTML content:
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ apache_server_name }} - Apache Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            color: #d73027;
            border-bottom: 2px solid #d73027;
            padding-bottom: 10px;
        }
        .info-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .info-table th, .info-table td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        .info-table th {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">Apache HTTP Server Successfully Deployed!</h1>
        
        <p>This server has been automatically configured using Ansible roles and templates.</p>
        
        <table class="info-table">
            <tr>
                <th>Property</th>
                <th>Value</th>
            </tr>
            <tr>
                <td>Server Hostname</td>
                <td>{{ ansible_hostname }}</td>
            </tr>
            <tr>
                <td>Server FQDN</td>
                <td>{{ ansible_fqdn }}</td>
            </tr>
            <tr>
                <td>IP Address</td>
                <td>{{ ansible_default_ipv4.address }}</td>
            </tr>
            <tr>
                <td>Operating System</td>
                <td>{{ ansible_distribution }} {{ ansible_distribution_version }}</td>
            </tr>
            <tr>
                <td>Apache Version</td>
                <td>{{ apache_package }}</td>
            </tr>
            <tr>
                <td>Document Root</td>
                <td>{{ apache_document_root }}</td>
            </tr>
            <tr>
                <td>Server Admin</td>
                <td>{{ apache_admin_email }}</td>
            </tr>
            <tr>
                <td>Deployment Time</td>
                <td>{{ ansible_date_time.iso8601 }}</td>
            </tr>
            <tr>
                <td>Total Memory</td>
                <td>{{ ansible_memtotal_mb }} MB</td>
            </tr>
            <tr>
                <td>CPU Cores</td>
                <td>{{ ansible_processor_vcpus }}</td>
            </tr>
        </table>
        
        <h2>Available Services</h2>
        <ul>
            <li>HTTP Server running on port {{ apache_port }}</li>
            <li>Configuration managed by Ansible</li>
            <li>Automatic service management enabled</li>
        </ul>
        
        <p><em>Generated by Ansible Role: apache-role</em></p>
    </div>
</body>
</html>
Task 4: Creating and Executing the Playbook
Subtask 4.1: Create an Inventory File
Create an inventory file for your target servers:
vim inventory.ini
Add your managed nodes (replace with actual IP addresses):
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=centos
web2 ansible_host=192.168.1.11 ansible_user=centos
web3 ansible_host=192.168.1.12 ansible_user=ubuntu

[webservers:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
Subtask 4.2: Create the Main Playbook
Create the playbook that uses your role:
vim deploy-apache.yml
Add the following playbook content:
---
- name: Deploy Apache HTTP Server using Custom Role
  hosts: webservers
  become: yes
  gather_facts: yes
  
  vars:
    apache_admin_email: "webmaster@mycompany.com"
    apache_server_name: "{{ inventory_hostname }}.mycompany.com"
  
  roles:
    - apache-role
  
  post_tasks:
    - name: Verify Apache is running
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ apache_port }}"
        method: GET
        status_code: 200
      delegate_to: localhost
      become: no
      
    - name: Display access information
      debug:
        msg: 
          - "Apache successfully deployed on {{ inventory_hostname }}"
          - "Access URL: http://{{ ansible_default_ipv4.address }}:{{ apache_port }}"
          - "Server Name: {{ apache_server_name }}"
Subtask 4.3: Create a Site-Specific Playbook
Create a more advanced playbook with multiple configurations:
vim site.yml
Add comprehensive site deployment:
---
- name: Deploy Web Infrastructure
  hosts: webservers
  become: yes
  gather_facts: yes
  
  vars:
    # Environment-specific variables
    environment_name: "production"
    company_name: "Al Nafi Tech Solutions"
    
  pre_tasks:
    - name: Update package cache (RedHat/CentOS)
      yum:
        update_cache: yes
      when: ansible_os_family == "RedHat"
      
    - name: Update package cache (Ubuntu/Debian)
      apt:
        update_cache: yes
      when: ansible_os_family == "Debian"
  
  roles:
    - role: apache-role
      vars:
        apache_admin_email: "admin@alnafi.com"
        apache_server_name: "{{ inventory_hostname }}.alnafi.com"
        apache_port: 80
  
  post_tasks:
    - name: Create a simple health check script
      copy:
        content: |
          #!/bin/bash
          # Apache Health Check Script
          if systemctl is-active --quiet {{ apache_service }}; then
            echo "Apache is running on $(hostname)"
            curl -s http://localhost:{{ apache_port }} > /dev/null
            if [ $? -eq 0 ]; then
              echo "Apache is responding to HTTP requests"
            else
              echo "Apache is not responding to HTTP requests"
            fi
          else
            echo "Apache is not running"
          fi
        dest: /usr/local/bin/apache-health-check.sh
        mode: '0755'
        owner: root
        group: root
    
    - name: Run health check
      command: /usr/local/bin/apache-health-check.sh
      register: health_check_result
      
    - name: Display health check results
      debug:
        var: health_check_result.stdout_lines
Subtask 4.4: Execute the Playbook
Test the inventory connection:
ansible -i inventory.ini webservers -m ping
Run the playbook in check mode first (dry run):
ansible-playbook -i inventory.ini deploy-apache.yml --check
Execute the actual deployment:
ansible-playbook -i inventory.ini deploy-apache.yml -v
Run the comprehensive site playbook:
ansible-playbook -i inventory.ini site.yml
Subtask 4.5: Verify the Deployment
Check Apache status on all servers:
ansible -i inventory.ini webservers -m shell -a "systemctl status httpd || systemctl status apache2" --become
Test HTTP connectivity:
ansible -i inventory.ini webservers -m uri -a "url=http://{{ ansible_default_ipv4.address }} method=GET" --delegate-to localhost
Verify the custom index page:
# Replace with your actual server IP
curl http://192.168.1.10
Task 5: Advanced Role Features and Best Practices
Subtask 5.1: Add Role Dependencies and Metadata
Edit the role metadata:
vim apache-role/meta/main.yml
Add comprehensive metadata:
---
galaxy_info:
  author: "Al Nafi Student"
  description: "Apache HTTP Server deployment and configuration role"
  company: "Al Nafi Tech Solutions"
  license: MIT
  min_ansible_version: 2.9
  
  platforms:
    - name: EL
      versions:
        - 7
        - 8
    - name: Ubuntu
      versions:
        - 18.04
        - 20.04
  
  galaxy_tags:
    - web
    - apache
    - httpd
    - server

dependencies: []
  # Example of role dependencies:
  # - role: firewall-config
  #   vars:
  #     firewall_allowed_ports:
  #       - 80
  #       - 443
Subtask 5.2: Create Role Tests
Create a test playbook:
vim apache-role/tests/test.yml
Add test scenarios:
---
- hosts: localhost
  remote_user: root
  roles:
    - apache-role
  
  post_tasks:
    - name: Test Apache service is running
      service:
        name: "{{ apache_service }}"
        state: started
      check_mode: yes
      register: service_status
      
    - name: Verify Apache responds to HTTP requests
      uri:
        url: "http://localhost:{{ apache_port }}"
        method: GET
        status_code: 200
      
    - name: Check if custom configuration exists
      stat:
        path: "{{ apache_config_dir }}/custom.conf"
      register: config_file
      when: ansible_os_family == "RedHat"
      
    - name: Verify configuration file exists
      assert:
        that:
          - config_file.stat.exists
        fail_msg: "Custom Apache configuration file not found"
      when: ansible_os_family == "RedHat"
Subtask 5.3: Create Multiple Environment Configurations
Create environment-specific variable files:
mkdir -p group_vars
vim group_vars/webservers.yml
Add production environment variables:
---
# Production environment variables for webservers
apache_admin_email: "production-admin@alnafi.com"
apache_server_name: "{{ inventory_hostname }}.prod.alnafi.com"

# Security settings for production
apache_security_headers: true
apache_server_tokens: "Prod"
apache_server_signature: "Off"

# Performance tuning for production
apache_max_request_workers: 400
apache_keepalive: "On"
apache_keepalive_timeout: 5
Create development environment variables:
mkdir -p host_vars
vim host_vars/web1.yml
---
# Development server specific variables
apache_admin_email: "dev-admin@alnafi.com"
apache_server_name: "web1.dev.alnafi.com"
apache_port: 8080

# Development-specific settings
apache_debug_mode: true
apache_log_level: "debug"
Troubleshooting Common Issues
Issue 1: Role Not Found
Problem: ERROR! the role 'apache-role' was not found

Solution:

# Ensure you're in the correct directory
pwd
ls -la apache-role/

# Check role structure
ansible-galaxy list
Issue 2: Template Variables Not Resolved
Problem: Variables showing as {{ variable_name }} in output

Solution:

# Check variable precedence and spelling
ansible-playbook -i inventory.ini deploy-apache.yml -v --extra-vars "debug=true"

# Verify template syntax
ansible-playbook -i inventory.ini deploy-apache.yml --syntax-check
Issue 3: Permission Denied Errors
Problem: Permission denied when copying files or restarting services

Solution:

# Ensure become: yes is set
# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa

# Test sudo access
ansible -i inventory.ini webservers -m shell -a "sudo whoami"
Issue 4: Firewall Blocking HTTP Access
Problem: Cannot access Apache web server from browser

Solution:

# Check if firewall rules are applied
ansible -i inventory.ini webservers -m shell -a "firewall-cmd --list-services" --become

# Manually open port if needed
ansible -i inventory.ini webservers -m shell -a "firewall-cmd --permanent --add-service=http && firewall-cmd --reload" --become
Validation and Testing
Test Your Role Implementation
Run comprehensive tests:
# Test role syntax
ansible-playbook -i inventory.ini deploy-apache.yml --syntax-check

# Test with different variables
ansible-playbook -i inventory.ini deploy-apache.yml --extra-vars "apache_port=8080"

# Test idempotency (should show no changes on second run)
ansible-playbook -i inventory.ini deploy-apache.yml
ansible-playbook -i inventory.ini deploy-apache.yml
Verify role functionality:
# Check all services are running
ansible -i inventory.ini webservers -m shell -a "systemctl status httpd apache2 2>/dev/null | grep Active" --become

# Verify web content
for server in web1 web2 web3; do
  echo "Testing $server..."
  curl -s http://$(ansible -i inventory.ini $server -m setup -a "filter=ansible_default_ipv4" | grep address | cut -d'"' -f4) | grep -o "<title>.*</title>"
done
Conclusion
Congratulations! You have successfully completed Lab 3: Ansible Roles and Templates. In this comprehensive lab, you have accomplished the following:

Key Achievements
Created a Reusable Ansible Role: You built a well-structured Apache HTTP Server role following Ansible best practices, including proper directory organization and modular design.

Implemented Dynamic Templates: You created Jinja2 templates that dynamically generate Apache configuration files and HTML content based on system facts and variables.

Mastered Role Components: You worked with all major role components including tasks, handlers, templates, variables, defaults, and metadata.

Applied Cross-Platform Compatibility: Your role handles different Linux distributions (RedHat/CentOS and Ubuntu/Debian) with OS-specific variables and tasks.

Implemented Best Practices: You learned proper variable precedence, role dependencies, testing strategies, and security considerations.

Why This Matters
For Your Career: Understanding Ansible roles and templates is crucial for the Red Hat Certified Specialist in Services Management and Automation exam and real-world automation scenarios.

For Organizations: Roles promote code reusability, maintainability, and standardization across infrastructure deployments, reducing deployment time and human error.

For Scalability: The skills you've learned allow you to create automation that can be easily shared, modified, and applied across different environments and teams.

Next Steps
Practice creating roles for other services (MySQL, Nginx, etc.)
Explore Ansible Galaxy for community roles
Learn about role dependencies and complex multi-role playbooks
Study advanced templating techniques and filters
Investigate Ansible Vault for sensitive data management
You now have the foundation to create sophisticated, reusable automation solutions that can significantly improve infrastructure management efficiency and reliability.
