Lab 10: Managing Files with Ansible
Objectives
By the end of this lab, students will be able to:

• Understand the difference between static and dynamic file management in Ansible • Use the copy module to transfer static files from the control node to managed hosts • Implement the template module to deploy dynamic configuration files using Jinja2 templates • Work with Ansible variables to customize file content across different hosts • Apply file permissions and ownership settings during file deployment • Troubleshoot common file management issues in Ansible playbooks

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux file system and permissions • Familiarity with YAML syntax and structure • Knowledge of Ansible inventory and playbook concepts from previous labs • Understanding of variables in Ansible • Basic text editor skills (nano, vim, or similar)

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes: • Control Node: CentOS/RHEL 8 with Ansible pre-installed • Managed Hosts: Two target servers (web1 and web2) ready for configuration • All necessary network connectivity and SSH keys configured

Task 1: Using the Copy Module for Static Files
Subtask 1.1: Create a Static Configuration File
First, let's create a static configuration file that we'll copy to our managed hosts.

Connect to your control node and navigate to your working directory:
cd /home/student/ansible-labs
mkdir lab10-file-management
cd lab10-file-management
Create a static Apache configuration file:
nano static-files/apache-security.conf
Add the following content to the file:
# Security Configuration for Apache Web Server
ServerTokens Prod
ServerSignature Off

# Hide Apache version information
Header always unset "X-Powered-By"
Header unset "X-Powered-By"

# Prevent access to .htaccess files
<Files ".ht*">
    Require all denied
</Files>

# Disable server-status and server-info
<Location "/server-status">
    Require all denied
</Location>

<Location "/server-info">
    Require all denied
</Location>
Save and exit the editor (Ctrl+X, then Y, then Enter in nano).
Subtask 1.2: Create a Playbook Using the Copy Module
Create a playbook for copying static files:
nano copy-static-files.yml
Add the following playbook content:
---
- name: Copy Static Files to Web Servers
  hosts: webservers
  become: yes
  vars:
    apache_config_dir: /etc/httpd/conf.d
    backup_dir: /backup/configs
  
  tasks:
    - name: Ensure backup directory exists
      file:
        path: "{{ backup_dir }}"
        state: directory
        mode: '0755'
        owner: root
        group: root

    - name: Copy Apache security configuration
      copy:
        src: static-files/apache-security.conf
        dest: "{{ apache_config_dir }}/security.conf"
        owner: root
        group: root
        mode: '0644'
        backup: yes
        validate: 'httpd -t -f %s'
      notify: restart apache

    - name: Copy custom index.html file
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Welcome to {{ inventory_hostname }}</title>
          </head>
          <body>
              <h1>Static Content Deployed Successfully!</h1>
              <p>This server is: {{ inventory_hostname }}</p>
              <p>Deployed on: {{ ansible_date_time.date }}</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: apache
        group: apache
        mode: '0644'

    - name: Copy binary file (favicon)
      copy:
        src: static-files/favicon.ico
        dest: /var/www/html/favicon.ico
        owner: apache
        group: apache
        mode: '0644'
      ignore_errors: yes

  handlers:
    - name: restart apache
      service:
        name: httpd
        state: restarted
Subtask 1.3: Create Additional Static Files
Create the static-files directory structure:
mkdir -p static-files
Create a simple favicon file (or download one):
# Create a simple text-based favicon placeholder
echo "FAVICON" > static-files/favicon.ico
Update your inventory file to include the webservers group:
nano inventory.ini
Add the following inventory content:
[webservers]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[all:vars]
ansible_user=student
ansible_ssh_private_key_file=~/.ssh/id_rsa
Subtask 1.4: Execute the Copy Playbook
Run the playbook to copy static files:
ansible-playbook -i inventory.ini copy-static-files.yml
Verify the files were copied by checking on the managed hosts:
ansible webservers -i inventory.ini -m shell -a "ls -la /etc/httpd/conf.d/security.conf"
ansible webservers -i inventory.ini -m shell -a "ls -la /var/www/html/"
Task 2: Using the Template Module for Dynamic Configuration Files
Subtask 2.1: Create Jinja2 Templates
Create a templates directory:
mkdir templates
Create a dynamic Apache virtual host template:
nano templates/vhost.conf.j2
Add the following Jinja2 template content:
# Virtual Host Configuration for {{ server_name }}
# Generated automatically by Ansible

<VirtualHost *:{{ http_port | default(80) }}>
    ServerName {{ server_name }}
    {% if server_aliases is defined %}
    {% for alias in server_aliases %}
    ServerAlias {{ alias }}
    {% endfor %}
    {% endif %}
    
    DocumentRoot {{ document_root | default('/var/www/html') }}
    
    # Logging Configuration
    ErrorLog {{ log_dir }}/{{ server_name }}_error.log
    CustomLog {{ log_dir }}/{{ server_name }}_access.log combined
    
    # Security Headers
    {% if enable_security_headers | default(true) %}
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    {% endif %}
    
    # Environment-specific settings
    {% if ansible_hostname == 'web1' %}
    # Primary server configuration
    SetEnv SERVER_ROLE "primary"
    {% else %}
    # Secondary server configuration
    SetEnv SERVER_ROLE "secondary"
    {% endif %}
    
    <Directory "{{ document_root }}">
        Options {{ directory_options | default('Indexes FollowSymLinks') }}
        AllowOverride {{ allow_override | default('None') }}
        Require all granted
    </Directory>
    
    {% if ssl_enabled | default(false) %}
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile {{ ssl_cert_path }}
    SSLCertificateKeyFile {{ ssl_key_path }}
    {% endif %}
</VirtualHost>
Create a dynamic system configuration template:
nano templates/system-info.conf.j2
Add the following template content:
# System Information Configuration
# Generated on {{ ansible_date_time.date }} at {{ ansible_date_time.time }}

# Server Details
HOSTNAME={{ inventory_hostname }}
SERVER_IP={{ ansible_default_ipv4.address }}
TOTAL_MEMORY={{ ansible_memtotal_mb }}MB
CPU_CORES={{ ansible_processor_vcpus }}
OS_FAMILY={{ ansible_os_family }}
OS_VERSION={{ ansible_distribution_version }}

# Environment Configuration
ENVIRONMENT={{ environment | default('production') }}
APPLICATION_PORT={{ app_port | default(8080) }}
MAX_CONNECTIONS={{ max_connections | default(100) }}

# Feature Flags
{% for feature, enabled in feature_flags.items() %}
{{ feature | upper }}_ENABLED={{ enabled | lower }}
{% endfor %}

# Custom Variables
{% if custom_vars is defined %}
{% for key, value in custom_vars.items() %}
{{ key | upper }}={{ value }}
{% endfor %}
{% endif %}
Subtask 2.2: Create Variables for Templates
Create a group variables file:
mkdir -p group_vars
nano group_vars/webservers.yml
Add the following group variables:
---
# Apache Configuration Variables
http_port: 80
log_dir: /var/log/httpd
enable_security_headers: true
directory_options: "Indexes FollowSymLinks"
allow_override: "All"

# SSL Configuration
ssl_enabled: false
ssl_cert_path: /etc/ssl/certs/server.crt
ssl_key_path: /etc/ssl/private/server.key

# Application Configuration
environment: production
app_port: 8080
max_connections: 150

# Feature Flags
feature_flags:
  caching: true
  compression: true
  monitoring: true
  debug_mode: false

# Custom Variables
custom_vars:
  app_version: "2.1.0"
  maintenance_window: "02:00-04:00"
  backup_retention: "30"
Create host-specific variables:
mkdir -p host_vars
nano host_vars/web1.yml
Add variables for web1:
---
server_name: web1.example.com
server_aliases:
  - www.web1.example.com
  - primary.example.com
document_root: /var/www/web1
max_connections: 200
Create variables for web2:
nano host_vars/web2.yml
Add variables for web2:
---
server_name: web2.example.com
server_aliases:
  - www.web2.example.com
  - secondary.example.com
document_root: /var/www/web2
max_connections: 100
Subtask 2.3: Create a Template Deployment Playbook
Create a playbook for template deployment:
nano deploy-templates.yml
Add the following playbook content:
---
- name: Deploy Dynamic Configuration Templates
  hosts: webservers
  become: yes
  vars:
    config_backup_dir: /backup/templates
  
  tasks:
    - name: Ensure backup directory exists
      file:
        path: "{{ config_backup_dir }}"
        state: directory
        mode: '0755'

    - name: Ensure document root directories exist
      file:
        path: "{{ document_root }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'

    - name: Deploy virtual host configuration from template
      template:
        src: vhost.conf.j2
        dest: /etc/httpd/conf.d/{{ server_name }}.conf
        owner: root
        group: root
        mode: '0644'
        backup: yes
        validate: 'httpd -t -f %s'
      notify: 
        - restart apache
        - reload apache

    - name: Deploy system information configuration
      template:
        src: system-info.conf.j2
        dest: /etc/system-info.conf
        owner: root
        group: root
        mode: '0644'
        backup: yes

    - name: Create dynamic index.html from template
      template:
        src: index.html.j2
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'

    - name: Display template variables for verification
      debug:
        msg: |
          Server: {{ server_name }}
          Document Root: {{ document_root }}
          Environment: {{ environment }}
          Max Connections: {{ max_connections }}
          Features: {{ feature_flags }}

  handlers:
    - name: restart apache
      service:
        name: httpd
        state: restarted

    - name: reload apache
      service:
        name: httpd
        state: reloaded
Subtask 2.4: Create an HTML Template
Create a dynamic HTML template:
nano templates/index.html.j2
Add the following HTML template:
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ server_name }} - Dynamic Content</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .info-box { background: #f4f4f4; padding: 20px; margin: 10px 0; border-radius: 5px; }
        .feature { color: green; }
        .disabled { color: red; }
    </style>
</head>
<body>
    <h1>Welcome to {{ server_name }}</h1>
    
    <div class="info-box">
        <h2>Server Information</h2>
        <p><strong>Hostname:</strong> {{ inventory_hostname }}</p>
        <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
        <p><strong>Environment:</strong> {{ environment }}</p>
        <p><strong>Application Port:</strong> {{ app_port }}</p>
        <p><strong>Max Connections:</strong> {{ max_connections }}</p>
    </div>
    
    <div class="info-box">
        <h2>System Specifications</h2>
        <p><strong>Total Memory:</strong> {{ ansible_memtotal_mb }}MB</p>
        <p><strong>CPU Cores:</strong> {{ ansible_processor_vcpus }}</p>
        <p><strong>OS:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
    </div>
    
    <div class="info-box">
        <h2>Feature Status</h2>
        {% for feature, enabled in feature_flags.items() %}
        <p><strong>{{ feature | title }}:</strong> 
        <span class="{% if enabled %}feature{% else %}disabled{% endif %}">
            {{ 'Enabled' if enabled else 'Disabled' }}
        </span></p>
        {% endfor %}
    </div>
    
    <div class="info-box">
        <h2>Custom Configuration</h2>
        {% if custom_vars is defined %}
        {% for key, value in custom_vars.items() %}
        <p><strong>{{ key | replace('_', ' ') | title }}:</strong> {{ value }}</p>
        {% endfor %}
        {% endif %}
    </div>
    
    <div class="info-box">
        <h2>Server Aliases</h2>
        {% if server_aliases is defined %}
        <ul>
        {% for alias in server_aliases %}
        <li>{{ alias }}</li>
        {% endfor %}
        </ul>
        {% else %}
        <p>No aliases configured</p>
        {% endif %}
    </div>
    
    <footer>
        <p><small>Generated on {{ ansible_date_time.date }} at {{ ansible_date_time.time }}</small></p>
    </footer>
</body>
</html>
Subtask 2.5: Execute the Template Deployment
Run the template deployment playbook:
ansible-playbook -i inventory.ini deploy-templates.yml
Verify the templates were processed correctly:
ansible webservers -i inventory.ini -m shell -a "ls -la /etc/httpd/conf.d/"
ansible webservers -i inventory.ini -m shell -a "head -20 /etc/system-info.conf"
Check the generated virtual host configurations:
ansible webservers -i inventory.ini -m shell -a "cat /etc/httpd/conf.d/web*.conf"
Task 3: Advanced File Management Techniques
Subtask 3.1: Create a Comprehensive File Management Playbook
Create an advanced playbook combining both copy and template modules:
nano advanced-file-management.yml
Add the following comprehensive playbook:
---
- name: Advanced File Management with Ansible
  hosts: webservers
  become: yes
  vars:
    config_timestamp: "{{ ansible_date_time.epoch }}"
    
  tasks:
    - name: Create directory structure
      file:
        path: "{{ item }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
      loop:
        - /opt/app/config
        - /opt/app/templates
        - /opt/app/static
        - /var/log/app

    - name: Copy static configuration files with validation
      copy:
        src: "{{ item.src }}"
        dest: "{{ item.dest }}"
        owner: "{{ item.owner | default('root') }}"
        group: "{{ item.group | default('root') }}"
        mode: "{{ item.mode | default('0644') }}"
        backup: yes
        validate: "{{ item.validate | default(omit) }}"
      loop:
        - src: static-files/apache-security.conf
          dest: /opt/app/config/security.conf
          validate: 'httpd -t -f %s'
        - src: static-files/favicon.ico
          dest: /opt/app/static/favicon.ico
          owner: apache
          group: apache
      notify: backup configurations

    - name: Deploy templates with conditional content
      template:
        src: "{{ item.src }}"
        dest: "{{ item.dest }}"
        owner: "{{ item.owner | default('root') }}"
        group: "{{ item.group | default('root') }}"
        mode: "{{ item.mode | default('0644') }}"
        backup: yes
      loop:
        - src: vhost.conf.j2
          dest: /opt/app/config/{{ server_name }}.conf
        - src: system-info.conf.j2
          dest: /opt/app/config/system-info.conf
        - src: index.html.j2
          dest: "{{ document_root }}/index.html"
          owner: apache
          group: apache

    - name: Create file with dynamic content using copy module
      copy:
        content: |
          # Configuration Summary
          # Generated: {{ ansible_date_time.iso8601 }}
          
          SERVER_NAME={{ server_name }}
          ENVIRONMENT={{ environment }}
          TIMESTAMP={{ config_timestamp }}
          
          # Ansible Facts
          HOSTNAME={{ ansible_hostname }}
          FQDN={{ ansible_fqdn }}
          IP_ADDRESS={{ ansible_default_ipv4.address }}
          
          # System Resources
          MEMORY_MB={{ ansible_memtotal_mb }}
          SWAP_MB={{ ansible_swaptotal_mb }}
          PROCESSOR_COUNT={{ ansible_processor_count }}
          
        dest: /opt/app/config/deployment-summary.conf
        mode: '0644'

    - name: Set file attributes and extended properties
      file:
        path: "{{ item.path }}"
        owner: "{{ item.owner | default('root') }}"
        group: "{{ item.group | default('root') }}"
        mode: "{{ item.mode }}"
        attributes: "{{ item.attributes | default(omit) }}"
      loop:
        - path: /opt/app/config
          mode: '0755'
          attributes: '+i'  # Make directory immutable
        - path: /opt/app/static
          owner: apache
          group: apache
          mode: '0755'

  handlers:
    - name: backup configurations
      archive:
        path: /opt/app/config
        dest: "/backup/config-backup-{{ config_timestamp }}.tar.gz"
        format: gz
Subtask 3.2: Test File Management with Different Scenarios
Create a testing playbook:
nano test-file-management.yml
Add testing scenarios:
---
- name: Test File Management Scenarios
  hosts: webservers
  become: yes
  
  tasks:
    - name: Test 1 - Copy with different sources
      block:
        - name: Copy from URL (if accessible)
          get_url:
            url: "https://httpd.apache.org/docs/2.4/favicon.ico"
            dest: /tmp/downloaded-favicon.ico
            mode: '0644'
          ignore_errors: yes

        - name: Copy with content generation
          copy:
            content: |
              # Test Configuration File
              # Created: {{ ansible_date_time.iso8601 }}
              TEST_VALUE=success
              SERVER={{ inventory_hostname }}
            dest: /tmp/test-config.conf

    - name: Test 2 - Template with conditional logic
      template:
        src: conditional-template.j2
        dest: /tmp/conditional-output.txt
      vars:
        test_conditions:
          - name: "memory_check"
            condition: "{{ ansible_memtotal_mb > 1000 }}"
            message: "Sufficient memory available"
          - name: "disk_check"
            condition: "{{ ansible_mounts[0].size_available > 1000000000 }}"
            message: "Sufficient disk space available"

    - name: Test 3 - File operations with loops
      copy:
        content: "Configuration for {{ item.name }}: {{ item.value }}"
        dest: "/tmp/{{ item.name }}.conf"
      loop:
        - { name: "database", value: "mysql://localhost:3306" }
        - { name: "cache", value: "redis://localhost:6379" }
        - { name: "queue", value: "rabbitmq://localhost:5672" }

    - name: Verify all test files were created
      find:
        paths: /tmp
        patterns: "*.conf,*.txt,*favicon*"
      register: test_files

    - name: Display test results
      debug:
        msg: "Created {{ test_files.files | length }} test files"
Create the conditional template:
nano templates/conditional-template.j2
Add conditional template content:
# Conditional Configuration Template
# Generated for {{ inventory_hostname }}

{% for condition in test_conditions %}
# Test: {{ condition.name }}
{% if condition.condition %}
{{ condition.name | upper }}_STATUS=PASS
{{ condition.name | upper }}_MESSAGE="{{ condition.message }}"
{% else %}
{{ condition.name | upper }}_STATUS=FAIL
{{ condition.name | upper }}_MESSAGE="Condition not met"
{% endif %}

{% endfor %}

# System Summary
TOTAL_TESTS={{ test_conditions | length }}
HOSTNAME={{ ansible_hostname }}
TIMESTAMP={{ ansible_date_time.epoch }}
Subtask 3.3: Execute and Verify Advanced File Management
Run the advanced file management playbook:
ansible-playbook -i inventory.ini advanced-file-management.yml
Run the testing playbook:
ansible-playbook -i inventory.ini test-file-management.yml
Verify the results on managed hosts:
# Check directory structure
ansible webservers -i inventory.ini -m shell -a "find /opt/app -type f -ls"

# Check template processing
ansible webservers -i inventory.ini -m shell -a "cat /opt/app/config/system-info.conf"

# Check test files
ansible webservers -i inventory.ini -m shell -a "ls -la /tmp/*.conf /tmp/*.txt"
Troubleshooting Common Issues
Issue 1: Template Syntax Errors
Problem: Jinja2 template syntax errors causing playbook failures.

Solution:

# Test template syntax locally
ansible-playbook --syntax-check deploy-templates.yml

# Use ansible-lint for additional validation
ansible-lint deploy-templates.yml
Issue 2: File Permission Problems
Problem: Files copied with incorrect permissions or ownership.

Solution:

- name: Fix file permissions
  file:
    path: "{{ item }}"
    owner: apache
    group: apache
    mode: '0644'
    recurse: yes
  loop:
    - /var/www/html
    - /opt/app/static
Issue 3: Template Variables Not Defined
Problem: Undefined variables in templates causing errors.

Solution:

# Use default filters in templates
{{ variable_name | default('default_value') }}

# Check if variable is defined
{% if variable_name is defined %}
{{ variable_name }}
{% else %}
Default Value
{% endif %}
Issue 4: Backup Files Accumulating
Problem: Too many backup files created by copy/template modules.

Solution:

- name: Clean old backup files
  find:
    paths: /etc/httpd/conf.d
    patterns: "*.conf.*"
    age: "7d"
  register: old_backups

- name: Remove old backup files
  file:
    path: "{{ item.path }}"
    state: absent
  loop: "{{ old_backups.files }}"
Conclusion
In this lab, you have successfully learned how to manage files with Ansible using both the copy and template modules. Here's what you accomplished:

Key Achievements:
• Static File Management: Used the copy module to deploy static configuration files, binary files, and content with proper permissions and validation

• Dynamic File Generation: Implemented the template module with Jinja2 templates to create dynamic configuration files that adapt to different hosts and environments

• Variable Integration: Worked with group variables, host variables, and facts to customize file content across different managed hosts

• Advanced Techniques: Combined both modules in comprehensive playbooks with error handling, validation, and backup strategies

• Troubleshooting Skills: Learned to identify and resolve common file management issues in Ansible

Why This Matters:
File management is a fundamental aspect of configuration management and automation. The skills you've developed in this lab are essential for:

Configuration Management: Deploying and maintaining consistent configurations across multiple servers
Application Deployment: Managing application configuration files that need to be customized per environment
Infrastructure as Code: Treating configuration files as code that can be version-controlled and automated
Scalability: Managing hundreds or thousands of servers with consistent, reliable file deployment processes
These file management techniques form the foundation for more advanced Ansible automation scenarios, including application deployment, security hardening, and infrastructure provisioning. The combination of static file copying and dynamic template generation provides the flexibility needed for real-world enterprise environments.
