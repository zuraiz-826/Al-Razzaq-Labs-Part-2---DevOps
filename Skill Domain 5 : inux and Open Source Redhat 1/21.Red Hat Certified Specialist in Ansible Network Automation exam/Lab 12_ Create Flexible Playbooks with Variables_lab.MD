Lab 12: Create Flexible Playbooks with Variables
Objectives
By the end of this lab, students will be able to:

Understand the importance of variables in Ansible playbooks for creating reusable and flexible automation
Define and use variables in playbooks and inventory files
Implement vars and extra_vars for dynamic customization
Test playbooks with different variable values to ensure flexibility
Create maintainable and scalable Ansible automation solutions
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ansible concepts (playbooks, tasks, modules)
Familiarity with YAML syntax and structure
Experience with Linux command line operations
Knowledge of SSH and basic networking concepts
Completion of previous Ansible labs or equivalent experience
Lab Environment
Al Nafi Cloud Machines: This lab uses pre-configured Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your environment - no need to build your own VM or configure infrastructure.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: 2-3 target systems for testing
Pre-configured SSH keys for passwordless authentication
Sample inventory files and directory structure
Task 1: Define Variables in Playbooks and Inventory
Subtask 1.1: Understanding Variable Types and Scope
Variables in Ansible provide flexibility and reusability. Let's start by understanding different variable types:

Connect to your control node and navigate to the working directory:
cd /home/ansible
mkdir lab12-variables
cd lab12-variables
Create a basic inventory file with host variables:
cat > inventory.ini << 'EOF'
[webservers]
web1 ansible_host=192.168.1.10 http_port=80 server_name=production-web1
web2 ansible_host=192.168.1.11 http_port=8080 server_name=staging-web2

[databases]
db1 ansible_host=192.168.1.20 db_port=3306 db_name=proddb
db2 ansible_host=192.168.1.21 db_port=3307 db_name=testdb

[webservers:vars]
web_user=apache
document_root=/var/www/html

[databases:vars]
db_user=mysql
data_dir=/var/lib/mysql

[all:vars]
ansible_user=ansible
backup_dir=/opt/backups
EOF
Create a group variables directory structure:
mkdir -p group_vars host_vars
Create group variable files:
# Group variables for webservers
cat > group_vars/webservers.yml << 'EOF'
---
# Web server configuration variables
web_packages:
  - httpd
  - php
  - php-mysql

web_service: httpd
web_config_template: httpd.conf.j2
ssl_enabled: false
max_connections: 100

# Security settings
firewall_rules:
  - port: "{{ http_port }}"
    protocol: tcp
    state: enabled
  - port: 443
    protocol: tcp
    state: "{{ 'enabled' if ssl_enabled else 'disabled' }}"
EOF
# Group variables for databases
cat > group_vars/databases.yml << 'EOF'
---
# Database configuration variables
db_packages:
  - mysql-server
  - python3-pymysql

db_service: mysqld
db_config_template: my.cnf.j2
backup_enabled: true
max_connections: 200

# Performance tuning
innodb_buffer_pool_size: "128M"
query_cache_size: "16M"

# Backup configuration
backup_schedule:
  hour: 2
  minute: 30
  weekday: "*"
EOF
Create host-specific variables:
# Host variables for web1
cat > host_vars/web1.yml << 'EOF'
---
# Production web server specific settings
environment: production
ssl_enabled: true
max_connections: 500
monitoring_enabled: true

# Custom application settings
app_debug: false
app_log_level: warning
cache_enabled: true
EOF
# Host variables for web2
cat > host_vars/web2.yml << 'EOF'
---
# Staging web server specific settings
environment: staging
ssl_enabled: false
max_connections: 50
monitoring_enabled: false

# Custom application settings
app_debug: true
app_log_level: debug
cache_enabled: false
EOF
Subtask 1.2: Creating a Variable-Driven Playbook
Create a comprehensive playbook that uses various variable types:
cat > web-deployment.yml << 'EOF'
---
- name: Deploy Web Application with Variables
  hosts: webservers
  become: yes
  vars:
    # Playbook-level variables
    app_name: "MyWebApp"
    app_version: "1.0.0"
    deployment_timestamp: "{{ ansible_date_time.iso8601 }}"
    
    # Default values (can be overridden)
    custom_message: "Welcome to {{ app_name }}"
    maintenance_mode: false
    
  tasks:
    - name: Display variable information
      debug:
        msg: |
          Deploying {{ app_name }} v{{ app_version }}
          Host: {{ inventory_hostname }}
          Environment: {{ environment | default('development') }}
          HTTP Port: {{ http_port }}
          Server Name: {{ server_name }}
          SSL Enabled: {{ ssl_enabled }}
          Max Connections: {{ max_connections }}
          Deployment Time: {{ deployment_timestamp }}

    - name: Install web server packages
      package:
        name: "{{ web_packages }}"
        state: present
      notify: restart web service

    - name: Create application directory
      file:
        path: "{{ document_root }}/{{ app_name | lower }}"
        state: directory
        owner: "{{ web_user }}"
        group: "{{ web_user }}"
        mode: '0755'

    - name: Deploy application configuration
      template:
        src: app-config.j2
        dest: "{{ document_root }}/{{ app_name | lower }}/config.php"
        owner: "{{ web_user }}"
        group: "{{ web_user }}"
        mode: '0644'
      notify: restart web service

    - name: Create index page with variables
      template:
        src: index.html.j2
        dest: "{{ document_root }}/index.html"
        owner: "{{ web_user }}"
        group: "{{ web_user }}"
        mode: '0644'

    - name: Configure firewall rules
      firewalld:
        port: "{{ item.port }}/{{ item.protocol }}"
        permanent: yes
        state: "{{ item.state }}"
        immediate: yes
      loop: "{{ firewall_rules }}"
      when: ansible_facts['os_family'] == "RedHat"

    - name: Start and enable web service
      service:
        name: "{{ web_service }}"
        state: started
        enabled: yes

  handlers:
    - name: restart web service
      service:
        name: "{{ web_service }}"
        state: restarted
EOF
Create template files for dynamic content:
mkdir templates

# Create application configuration template
cat > templates/app-config.j2 << 'EOF'
<?php
// {{ app_name }} Configuration
// Generated on {{ deployment_timestamp }}
// Environment: {{ environment | default('development') }}

define('APP_NAME', '{{ app_name }}');
define('APP_VERSION', '{{ app_version }}');
define('ENVIRONMENT', '{{ environment | default('development') }}');
define('DEBUG_MODE', {{ app_debug | default(false) | lower }});
define('LOG_LEVEL', '{{ app_log_level | default('info') }}');

// Database Configuration
define('DB_HOST', '{{ groups['databases'][0] if groups['databases'] is defined else 'localhost' }}');
define('DB_PORT', {{ db_port | default(3306) }});
define('DB_NAME', '{{ db_name | default('webapp') }}');
define('DB_USER', '{{ db_user | default('webuser') }}');

// Performance Settings
define('CACHE_ENABLED', {{ cache_enabled | default(true) | lower }});
define('MAX_CONNECTIONS', {{ max_connections }});

// Security Settings
define('SSL_ENABLED', {{ ssl_enabled | lower }});
define('MAINTENANCE_MODE', {{ maintenance_mode | lower }});

// Custom Message
define('WELCOME_MESSAGE', '{{ custom_message }}');
?>
EOF
# Create HTML template
cat > templates/index.html.j2 << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ app_name }} - {{ environment | default('Development') | title }}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: {% if environment == 'production' %}#28a745{% elif environment == 'staging' %}#ffc107{% else %}#17a2b8{% endif %}; color: white; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; padding: 15px; background-color: #f8f9fa; border-radius: 5px; }
        .status { margin: 10px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>{{ custom_message }}</h1>
        <p>Version {{ app_version }} - {{ environment | default('Development') | title }} Environment</p>
    </div>
    
    <div class="info">
        <h2>Server Information</h2>
        <div class="status"><strong>Hostname:</strong> {{ inventory_hostname }}</div>
        <div class="status"><strong>Server Name:</strong> {{ server_name }}</div>
        <div class="status"><strong>HTTP Port:</strong> {{ http_port }}</div>
        <div class="status"><strong>SSL Enabled:</strong> {{ ssl_enabled | title }}</div>
        <div class="status"><strong>Max Connections:</strong> {{ max_connections }}</div>
        <div class="status"><strong>Deployed:</strong> {{ deployment_timestamp }}</div>
        {% if maintenance_mode %}
        <div class="status" style="color: red;"><strong>Status:</strong> Maintenance Mode</div>
        {% else %}
        <div class="status" style="color: green;"><strong>Status:</strong> Active</div>
        {% endif %}
    </div>

    <div class="info">
        <h2>Configuration Details</h2>
        <div class="status"><strong>Web User:</strong> {{ web_user }}</div>
        <div class="status"><strong>Document Root:</strong> {{ document_root }}</div>
        <div class="status"><strong>Backup Directory:</strong> {{ backup_dir }}</div>
        {% if monitoring_enabled is defined %}
        <div class="status"><strong>Monitoring:</strong> {{ monitoring_enabled | title }}</div>
        {% endif %}
    </div>
</body>
</html>
EOF
Task 2: Use vars and extra_vars for Customization
Subtask 2.1: Understanding Variable Precedence
Create a playbook to demonstrate variable precedence:
cat > variable-precedence.yml << 'EOF'
---
- name: Demonstrate Variable Precedence
  hosts: webservers
  vars:
    test_var: "playbook_vars"
    precedence_demo: "from_playbook"
    
  tasks:
    - name: Show all variable sources
      debug:
        msg: |
          Variable Precedence Demonstration:
          test_var: {{ test_var }}
          precedence_demo: {{ precedence_demo }}
          inventory_var: {{ http_port }}
          group_var: {{ web_user }}
          host_var: {{ environment | default('not_set') }}
          
    - name: Display variable precedence order
      debug:
        msg: |
          Ansible Variable Precedence (lowest to highest):
          1. role defaults
          2. inventory file or script group vars
          3. inventory group_vars/all
          4. playbook group_vars/all
          5. inventory group_vars/*
          6. playbook group_vars/*
          7. inventory file or script host vars
          8. inventory host_vars/*
          9. playbook host_vars/*
          10. host facts / cached set_facts
          11. play vars
          12. play vars_prompt
          13. play vars_files
          14. role vars (defined in role/vars/main.yml)
          15. block vars (only for tasks in block)
          16. task vars (only for the task)
          17. include_vars
          18. set_facts / registered vars
          19. role (and include_role) params
          20. include params
          21. extra vars (always win precedence)
EOF
Subtask 2.2: Using vars_files for External Variable Loading
Create external variable files:
mkdir vars

# Create environment-specific variable files
cat > vars/production.yml << 'EOF'
---
# Production environment variables
environment: production
app_debug: false
app_log_level: error
ssl_enabled: true
max_connections: 1000
monitoring_enabled: true
backup_enabled: true

# Performance settings
cache_enabled: true
cache_ttl: 3600
session_timeout: 1800

# Security settings
security_headers: true
rate_limiting: true
max_requests_per_minute: 100

# Database settings
db_pool_size: 20
db_timeout: 30
EOF
cat > vars/staging.yml << 'EOF'
---
# Staging environment variables
environment: staging
app_debug: true
app_log_level: debug
ssl_enabled: false
max_connections: 100
monitoring_enabled: true
backup_enabled: false

# Performance settings
cache_enabled: false
cache_ttl: 300
session_timeout: 3600

# Security settings
security_headers: false
rate_limiting: false
max_requests_per_minute: 1000

# Database settings
db_pool_size: 5
db_timeout: 60
EOF
cat > vars/development.yml << 'EOF'
---
# Development environment variables
environment: development
app_debug: true
app_log_level: debug
ssl_enabled: false
max_connections: 10
monitoring_enabled: false
backup_enabled: false

# Performance settings
cache_enabled: false
cache_ttl: 60
session_timeout: 7200

# Security settings
security_headers: false
rate_limiting: false
max_requests_per_minute: 10000

# Database settings
db_pool_size: 2
db_timeout: 120
EOF
Create a playbook that uses vars_files:
cat > environment-deployment.yml << 'EOF'
---
- name: Environment-Specific Deployment
  hosts: webservers
  vars_files:
    - "vars/{{ target_env | default('development') }}.yml"
    
  vars:
    app_name: "FlexibleApp"
    app_version: "2.0.0"
    
  tasks:
    - name: Display loaded environment variables
      debug:
        msg: |
          Deploying to {{ environment }} environment
          Debug Mode: {{ app_debug }}
          Log Level: {{ app_log_level }}
          SSL Enabled: {{ ssl_enabled }}
          Max Connections: {{ max_connections }}
          Cache Enabled: {{ cache_enabled }}
          Monitoring: {{ monitoring_enabled }}

    - name: Create environment-specific configuration
      template:
        src: env-config.j2
        dest: "/tmp/{{ app_name | lower }}-{{ environment }}.conf"
        mode: '0644'
      delegate_to: localhost

    - name: Show configuration file content
      command: cat "/tmp/{{ app_name | lower }}-{{ environment }}.conf"
      delegate_to: localhost
      register: config_content

    - name: Display configuration
      debug:
        var: config_content.stdout_lines
EOF
Create the environment configuration template:
cat > templates/env-config.j2 << 'EOF'
# {{ app_name }} Configuration for {{ environment | title }} Environment
# Generated: {{ ansible_date_time.iso8601 }}

[application]
name = {{ app_name }}
version = {{ app_version }}
environment = {{ environment }}
debug = {{ app_debug | lower }}
log_level = {{ app_log_level }}

[server]
max_connections = {{ max_connections }}
ssl_enabled = {{ ssl_enabled | lower }}
{% if ssl_enabled %}
ssl_cert = /etc/ssl/certs/{{ app_name | lower }}.crt
ssl_key = /etc/ssl/private/{{ app_name | lower }}.key
{% endif %}

[performance]
cache_enabled = {{ cache_enabled | lower }}
{% if cache_enabled %}
cache_ttl = {{ cache_ttl }}
{% endif %}
session_timeout = {{ session_timeout }}

[security]
security_headers = {{ security_headers | default(false) | lower }}
rate_limiting = {{ rate_limiting | default(false) | lower }}
{% if rate_limiting %}
max_requests_per_minute = {{ max_requests_per_minute }}
{% endif %}

[database]
pool_size = {{ db_pool_size }}
timeout = {{ db_timeout }}

[monitoring]
enabled = {{ monitoring_enabled | lower }}
{% if monitoring_enabled %}
metrics_port = 9090
health_check_path = /health
{% endif %}

[backup]
enabled = {{ backup_enabled | lower }}
{% if backup_enabled %}
schedule = daily
retention_days = 30
{% endif %}
EOF
Subtask 2.3: Using extra_vars for Runtime Customization
Create a playbook designed for extra_vars usage:
cat > flexible-deployment.yml << 'EOF'
---
- name: Flexible Deployment with Extra Variables
  hosts: "{{ target_hosts | default('webservers') }}"
  become: "{{ become_user | default(true) }}"
  
  vars:
    # Default values that can be overridden
    deployment_mode: "{{ deploy_mode | default('standard') }}"
    rollback_enabled: "{{ enable_rollback | default(true) }}"
    notification_enabled: "{{ send_notifications | default(false) }}"
    
  pre_tasks:
    - name: Validate required extra variables
      assert:
        that:
          - app_name is defined
          - app_version is defined
        fail_msg: "app_name and app_version must be provided via extra_vars"
        success_msg: "Required variables validated successfully"

    - name: Display deployment parameters
      debug:
        msg: |
          Deployment Parameters:
          Application: {{ app_name }}
          Version: {{ app_version }}
          Target Hosts: {{ target_hosts | default('webservers') }}
          Deployment Mode: {{ deployment_mode }}
          Rollback Enabled: {{ rollback_enabled }}
          Notifications: {{ notification_enabled }}
          Custom Message: {{ custom_message | default('Standard deployment') }}

  tasks:
    - name: Create deployment directory
      file:
        path: "/opt/deployments/{{ app_name | lower }}-{{ app_version }}"
        state: directory
        mode: '0755'

    - name: Generate deployment manifest
      template:
        src: deployment-manifest.j2
        dest: "/opt/deployments/{{ app_name | lower }}-{{ app_version }}/manifest.yml"
        mode: '0644'

    - name: Perform standard deployment
      debug:
        msg: "Performing standard deployment of {{ app_name }} v{{ app_version }}"
      when: deployment_mode == 'standard'

    - name: Perform blue-green deployment
      debug:
        msg: "Performing blue-green deployment of {{ app_name }} v{{ app_version }}"
      when: deployment_mode == 'blue-green'

    - name: Perform canary deployment
      debug:
        msg: "Performing canary deployment of {{ app_name }} v{{ app_version }}"
      when: deployment_mode == 'canary'

    - name: Setup rollback capability
      debug:
        msg: "Setting up rollback for {{ app_name }} v{{ app_version }}"
      when: rollback_enabled | bool

    - name: Send deployment notification
      debug:
        msg: "Sending notification: {{ app_name }} v{{ app_version }} deployed successfully"
      when: notification_enabled | bool

  post_tasks:
    - name: Record deployment
      lineinfile:
        path: /var/log/deployments.log
        line: "{{ ansible_date_time.iso8601 }} - {{ app_name }} v{{ app_version }} deployed to {{ inventory_hostname }} ({{ deployment_mode }} mode)"
        create: yes
        mode: '0644'
EOF
Create the deployment manifest template:
cat > templates/deployment-manifest.j2 << 'EOF'
---
# Deployment Manifest
# Generated: {{ ansible_date_time.iso8601 }}

deployment:
  application: {{ app_name }}
  version: {{ app_version }}
  timestamp: {{ ansible_date_time.iso8601 }}
  mode: {{ deployment_mode }}
  target_host: {{ inventory_hostname }}
  
configuration:
  rollback_enabled: {{ rollback_enabled }}
  notification_enabled: {{ notification_enabled }}
  custom_message: "{{ custom_message | default('No custom message') }}"
  
environment:
  ansible_user: {{ ansible_user }}
  become_user: {{ become_user | default(true) }}
  target_hosts: {{ target_hosts | default('webservers') }}
  
metadata:
  deployed_by: {{ ansible_user }}
  playbook: flexible-deployment.yml
  ansible_version: {{ ansible_version.full }}
  
{% if additional_config is defined %}
additional_configuration:
{% for key, value in additional_config.items() %}
  {{ key }}: {{ value }}
{% endfor %}
{% endif %}
EOF
Task 3: Test Playbooks with Different Values
Subtask 3.1: Testing Basic Variable Functionality
Test the basic web deployment playbook:
# Test with default values
ansible-playbook -i inventory.ini web-deployment.yml --check

# Test with specific hosts
ansible-playbook -i inventory.ini web-deployment.yml --limit web1 --check
Test variable precedence:
# Run the precedence demonstration
ansible-playbook -i inventory.ini variable-precedence.yml

# Test with extra variables overriding
ansible-playbook -i inventory.ini variable-precedence.yml \
  -e "test_var=extra_vars_override" \
  -e "precedence_demo=from_extra_vars"
Subtask 3.2: Testing Environment-Specific Deployments
Test different environment deployments:
# Deploy to development environment
ansible-playbook -i inventory.ini environment-deployment.yml \
  -e "target_env=development" --check

# Deploy to staging environment
ansible-playbook -i inventory.ini environment-deployment.yml \
  -e "target_env=staging" --check

# Deploy to production environment
ansible-playbook -i inventory.ini environment-deployment.yml \
  -e "target_env=production" --check
Test with custom variables:
# Test with additional custom variables
ansible-playbook -i inventory.ini environment-deployment.yml \
  -e "target_env=staging" \
  -e "app_name=CustomApp" \
  -e "app_version=3.0.0" --check
Subtask 3.3: Testing Flexible Deployment Scenarios
Test various deployment scenarios:
# Basic deployment test
ansible-playbook -i inventory.ini flexible-deployment.yml \
  -e "app_name=TestApp" \
  -e "app_version=1.0.0" --check

# Blue-green deployment test
ansible-playbook -i inventory.ini flexible-deployment.yml \
  -e "app_name=TestApp" \
  -e "app_version=1.1.0" \
  -e "deploy_mode=blue-green" \
  -e "target_hosts=web1" --check

# Canary deployment with notifications
ansible-playbook -i inventory.ini flexible-deployment.yml \
  -e "app_name=TestApp" \
  -e "app_version=1.2.0" \
  -e "deploy_mode=canary" \
  -e "send_notifications=true" \
  -e "custom_message=Canary release for testing" --check
Test with complex variable structures:
# Test with JSON extra variables
ansible-playbook -i inventory.ini flexible-deployment.yml \
  -e "app_name=ComplexApp" \
  -e "app_version=2.0.0" \
  -e '{"additional_config": {"feature_flags": {"new_ui": true, "api_v2": false}, "performance": {"cache_size": "256MB", "worker_processes": 4}}}' --check
Subtask 3.4: Creating a Variable Testing Suite
Create a comprehensive test playbook:
cat > test-variables.yml << 'EOF'
---
- name: Variable Testing Suite
  hosts: localhost
  gather_facts: no
  vars:
    test_scenarios:
      - name: "Basic String Variable"
        variable: "test_string"
        expected: "hello_world"
        test_value: "hello_world"
      - name: "Integer Variable"
        variable: "test_number"
        expected: 42
        test_value: 42
      - name: "Boolean Variable"
        variable: "test_boolean"
        expected: true
        test_value: true
      - name: "List Variable"
        variable: "test_list"
        expected: ["item1", "item2", "item3"]
        test_value: ["item1", "item2", "item3"]

  tasks:
    - name: Run variable tests
      block:
        - name: Test {{ item.name }}
          assert:
            that:
              - vars[item.variable] is defined
              - vars[item.variable] == item.expected
            success_msg: "✓ {{ item.name }} test passed"
            fail_msg: "✗ {{ item.name }} test failed"
          vars:
            "{{ item.variable }}": "{{ item.test_value }}"
          loop: "{{ test_scenarios }}"

        - name: Test variable type checking
          debug:
            msg: |
              Variable Type Tests:
              String: {{ test_string | type_debug }}
              Number: {{ test_number | type_debug }}
              Boolean: {{ test_boolean | type_debug }}
              List: {{ test_list | type_debug }}
          vars:
            test_string: "hello_world"
            test_number: 42
            test_boolean: true
            test_list: ["item1", "item2", "item3"]

        - name: Test variable filters and transformations
          debug:
            msg: |
              Filter Tests:
              Uppercase: {{ 'hello world' | upper }}
              Default value: {{ undefined_var | default('default_value') }}
              List length: {{ test_list | length }}
              JSON format: {{ test_dict | to_json }}
          vars:
            test_list: ["a", "b", "c"]
            test_dict: {"key1": "value1", "key2": "value2"}

      rescue:
        - name: Handle test failures
          debug:
            msg: "Some variable tests failed. Check the assertions above."
EOF
Run the variable testing suite:
# Run the comprehensive variable tests
ansible-playbook test-variables.yml
Subtask 3.5: Performance and Validation Testing
Create a validation playbook:
cat > validate-deployment.yml << 'EOF'
---
- name: Validate Variable-Driven Deployment
  hosts: webservers
  vars:
    required_variables:
      - app_name
      - app_version
      - environment
      - http_port
      - web_user
    
    optional_variables:
      - ssl_enabled
      - max_connections
      - monitoring_enabled
      
  tasks:
    - name: Validate required variables are defined
      assert:
        that:
          - vars[item] is defined
          - vars[item] != ""
        fail_msg: "Required variable '{{ item }}' is not defined or empty"
        success_msg: "Required variable '{{ item }}' is properly defined"
      loop: "{{ required_variables }}"

    - name: Check optional variables
      debug:
        msg: "Optional variable '{{ item }}': {{ vars[item] | default('not defined') }}"
      loop: "{{ optional_variables }}"

    - name: Validate variable types
      assert:
        that:
          - http_port | int > 0
          - http_port | int < 65536
        fail_msg: "http_port must be a valid port number (1-65535)"
        success_msg: "http_port is valid"

    - name: Generate deployment summary
      template:
        src: deployment-summary.j2
        dest: "/tmp/deployment-summary-{{ inventory_hostname }}.txt"
        mode: '0644'
      delegate_to: localhost

    - name: Display deployment summary
      debug:
        msg: "Deployment validation completed. Summary saved to /tmp/deployment-summary-{{ inventory_hostname }}.txt"
EOF
Create the deployment summary template:
cat > templates/deployment-summary.j2 << 'EOF'
DEPLOYMENT VALIDATION SUMMARY
=============================
Generated: {{ ansible_date_time.iso8601 }}
Host: {{ inventory_hostname }}

REQUIRED VARIABLES:
{% for var in required_variables %}
  {{ var }}: {{ vars[var] | default('UNDEFINED') }}
{% endfor %}

OPTIONAL VARIABLES:
{% for var in optional_variables %}
  {{ var }}: {{ vars[var] | default('not set') }}
{% endfor %}

HOST-SPECIFIC INFORMATION:
  Server Name: {{ server_name | default('not set') }}
  Environment: {{ environment | default('not set') }}
  Ansible User: {{ ansible_user }}
  
COMPUTED VALUES:
  Deployment Path: {{ document_root }}/{{ app_name | default('unknown') | lower }}
  Service Name: {{ web_service | default('httpd') }}
  Backup Location: {{ backup_dir }}/{{ inventory_hostname }}

VALIDATION STATUS: PASSED
EOF
Run validation tests:
# Validate the deployment configuration
ansible-playbook -i inventory.ini validate-deployment.yml

# Check the generated summaries
ls -la /tmp/deployment-summary-*.txt
cat /tmp/deployment-summary-web1.txt
Troubleshooting Common Issues
Variable-Related Problems
Undefined Variable Errors:
# Use default filter to handle undefined variables
{{ undefined_var | default('fallback_value') }}

# Check if variable is defined before using
{% if my_var is defined %}
  {{ my_var }}
{% endif %}
Variable Type Issues:
# Convert string to integer
{{ string_port | int }}

# Convert to boolean
{{ string_boolean | bool }}

# Check variable type
{{ my_var | type_debug }}
Variable Precedence Confusion:
# Debug variable sources
ansible-playbook playbook.yml -vvv

# Use ansible-inventory to see resolved variables
ansible-inventory -i inventory.ini --host web1
Testing and Debugging
Use debug tasks to inspect variables:
- name: Debug all variables
  debug:
    var: vars

- name: Debug specific variable
  debug:
    var: my_variable
Use assert tasks for validation:
- name: Validate configuration
  assert:
    that:
      - port_number | int > 0
      - environment in ['dev', 'staging', 'pro
