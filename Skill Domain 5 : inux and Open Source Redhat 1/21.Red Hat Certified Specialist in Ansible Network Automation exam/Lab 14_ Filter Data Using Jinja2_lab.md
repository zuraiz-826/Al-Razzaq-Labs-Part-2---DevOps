Lab 14: Filter Data Using Jinja2
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of Jinja2 templating in Ansible
Apply various Jinja2 filters to manipulate and transform data
Use built-in filters for string manipulation, date formatting, and data conversion
Create custom Jinja2 templates for generating network configurations
Implement conditional logic and loops within Jinja2 templates
Debug and troubleshoot Jinja2 template issues in Ansible playbooks
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ansible playbooks and YAML syntax
Familiarity with Linux command line operations
Knowledge of network configuration concepts
Understanding of data types (strings, lists, dictionaries)
Previous experience with Ansible variables and facts
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 control node with Ansible pre-installed
Multiple target hosts for testing
Pre-configured SSH connectivity
Sample data files and templates
Task 1: Understanding Jinja2 Filters Basics
Subtask 1.1: Set Up Lab Directory Structure
First, let's create a proper directory structure for our lab exercises.

# Create main lab directory
mkdir -p ~/ansible-jinja2-lab
cd ~/ansible-jinja2-lab

# Create subdirectories for organization
mkdir -p {playbooks,templates,vars,inventory}

# Create inventory file
cat > inventory/hosts << EOF
[webservers]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[databases]
db1 ansible_host=192.168.1.20

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Subtask 1.2: Create Sample Data Variables
Create a variables file with sample data that we'll use throughout the lab.

cat > vars/sample_data.yml << 'EOF'
---
# User information
users:
  - name: john_doe
    email: john.doe@company.com
    department: engineering
    join_date: "2023-01-15"
    active: true
  - name: jane_smith
    email: jane.smith@company.com
    department: marketing
    join_date: "2022-11-20"
    active: false
  - name: bob_wilson
    email: bob.wilson@company.com
    department: sales
    join_date: "2023-03-10"
    active: true

# Network configuration
network_config:
  domain: company.local
  dns_servers:
    - 8.8.8.8
    - 8.8.4.4
  vlans:
    - id: 10
      name: management
      subnet: 192.168.10.0/24
    - id: 20
      name: production
      subnet: 192.168.20.0/24

# Application settings
app_settings:
  version: "2.4.1"
  environment: production
  debug_mode: false
  max_connections: 1000
  timeout: 30
EOF
Subtask 1.3: Basic String Filters Playbook
Create your first playbook to explore basic Jinja2 string filters.

cat > playbooks/01-string-filters.yml << 'EOF'
---
- name: Demonstrate Basic String Filters
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../vars/sample_data.yml
  vars:
    sample_text: "  Hello World from Ansible  "
    mixed_case: "ThIs Is MiXeD cAsE tExT"
    
  tasks:
    - name: Display original strings
      debug:
        msg:
          - "Original text: '{{ sample_text }}'"
          - "Mixed case: '{{ mixed_case }}'"
    
    - name: Apply uppercase filter
      debug:
        msg: "Uppercase: {{ sample_text | upper }}"
    
    - name: Apply lowercase filter
      debug:
        msg: "Lowercase: {{ mixed_case | lower }}"
    
    - name: Apply title case filter
      debug:
        msg: "Title case: {{ mixed_case | title }}"
    
    - name: Apply trim filter to remove whitespace
      debug:
        msg: "Trimmed: '{{ sample_text | trim }}'"
    
    - name: Apply replace filter
      debug:
        msg: "Replaced: {{ sample_text | replace('World', 'Universe') }}"
    
    - name: Apply length filter
      debug:
        msg: "Length of trimmed text: {{ sample_text | trim | length }}"
    
    - name: Chain multiple filters
      debug:
        msg: "Chained filters: {{ sample_text | trim | upper | replace('HELLO', 'GREETINGS') }}"
EOF
Run the playbook to see string filters in action:

ansible-playbook -i inventory/hosts playbooks/01-string-filters.yml
Task 2: Advanced Data Manipulation Filters
Subtask 2.1: Working with Lists and Dictionaries
Create a playbook that demonstrates list and dictionary manipulation filters.

cat > playbooks/02-data-filters.yml << 'EOF'
---
- name: Demonstrate Data Manipulation Filters
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../vars/sample_data.yml
  vars:
    numbers: [1, 5, 3, 9, 2, 7, 4]
    mixed_list: ["apple", "banana", "cherry", "apple", "date"]
    
  tasks:
    - name: Display original data
      debug:
        msg:
          - "Numbers: {{ numbers }}"
          - "Mixed list: {{ mixed_list }}"
          - "Users count: {{ users | length }}"
    
    - name: Sort and manipulate lists
      debug:
        msg:
          - "Sorted numbers: {{ numbers | sort }}"
          - "Reverse sorted: {{ numbers | sort(reverse=true) }}"
          - "Unique items: {{ mixed_list | unique }}"
          - "First 3 numbers: {{ numbers | sort | first(3) }}"
          - "Last 2 items: {{ mixed_list | last(2) }}"
    
    - name: Mathematical operations on lists
      debug:
        msg:
          - "Sum of numbers: {{ numbers | sum }}"
          - "Maximum: {{ numbers | max }}"
          - "Minimum: {{ numbers | min }}"
          - "Average: {{ (numbers | sum) / (numbers | length) }}"
    
    - name: Extract data from dictionaries
      debug:
        msg:
          - "User names: {{ users | map(attribute='name') | list }}"
          - "Active users: {{ users | selectattr('active') | map(attribute='name') | list }}"
          - "Engineering users: {{ users | selectattr('department', 'equalto', 'engineering') | map(attribute='name') | list }}"
    
    - name: Group and organize data
      debug:
        msg:
          - "Users by department: {{ users | groupby('department') }}"
          - "VLAN IDs: {{ network_config.vlans | map(attribute='id') | list }}"
EOF
Subtask 2.2: Date and Time Filters
Create a playbook focusing on date and time manipulation.

cat > playbooks/03-date-filters.yml << 'EOF'
---
- name: Demonstrate Date and Time Filters
  hosts: localhost
  gather_facts: true
  vars_files:
    - ../vars/sample_data.yml
  vars:
    current_timestamp: "{{ ansible_date_time.epoch }}"
    
  tasks:
    - name: Display current date information
      debug:
        msg:
          - "Current date: {{ ansible_date_time.date }}"
          - "Current time: {{ ansible_date_time.time }}"
          - "ISO format: {{ ansible_date_time.iso8601 }}"
          - "Timestamp: {{ current_timestamp }}"
    
    - name: Format dates from user data
      debug:
        msg: "{{ item.name }} joined on {{ item.join_date | strftime('%B %d, %Y') }}"
      loop: "{{ users }}"
    
    - name: Calculate days since joining
      debug:
        msg: "{{ item.name }} has been with us for {{ ((ansible_date_time.epoch | int) - (item.join_date | to_datetime('%Y-%m-%d') | strftime('%s') | int)) // 86400 }} days"
      loop: "{{ users }}"
    
    - name: Format timestamp in different ways
      debug:
        msg:
          - "Human readable: {{ current_timestamp | int | strftime('%A, %B %d, %Y at %I:%M %p') }}"
          - "Short format: {{ current_timestamp | int | strftime('%m/%d/%Y') }}"
          - "ISO format: {{ current_timestamp | int | strftime('%Y-%m-%dT%H:%M:%S') }}"
EOF
Run both playbooks to see the filters in action:

ansible-playbook -i inventory/hosts playbooks/02-data-filters.yml
ansible-playbook -i inventory/hosts playbooks/03-date-filters.yml
Task 3: Creating Configuration Templates
Subtask 3.1: Network Configuration Template
Create a Jinja2 template for generating network device configurations.

cat > templates/router-config.j2 << 'EOF'
!
! Router Configuration Generated by Ansible
! Generated on: {{ ansible_date_time.iso8601 }}
! Template version: {{ app_settings.version }}
!
hostname {{ inventory_hostname | upper }}
!
! Domain configuration
ip domain-name {{ network_config.domain }}
{% for dns in network_config.dns_servers %}
ip name-server {{ dns }}
{% endfor %}
!
! VLAN Configuration
{% for vlan in network_config.vlans %}
vlan {{ vlan.id }}
 name {{ vlan.name | upper }}
 subnet {{ vlan.subnet }}
{% endfor %}
!
! Interface Configuration
{% set interface_counter = 1 %}
{% for vlan in network_config.vlans %}
interface GigabitEthernet0/{{ interface_counter }}
 description {{ vlan.name | title }} Network
 ip address {{ vlan.subnet | ipaddr('1') | ipaddr('address') }} {{ vlan.subnet | ipaddr('netmask') }}
 no shutdown
!
{% set interface_counter = interface_counter + 1 %}
{% endfor %}
!
! Access Control
{% if app_settings.debug_mode %}
! DEBUG MODE ENABLED - Remove in production
logging console debugging
{% else %}
logging console warnings
{% endif %}
!
! Connection limits
line vty 0 {{ app_settings.max_connections - 1 }}
 exec-timeout {{ app_settings.timeout }} 0
 transport input ssh
!
! User Configuration
{% for user in users %}
{% if user.active %}
username {{ user.name | upper }} privilege 15 secret {{ user.name | hash('sha256') | truncate(8, true, '') }}
! User: {{ user.name | title }} ({{ user.department | title }})
! Email: {{ user.email }}
! Joined: {{ user.join_date | strftime('%B %Y') }}
{% endif %}
{% endfor %}
!
end
EOF
Subtask 3.2: Web Server Configuration Template
Create a template for Apache virtual host configuration.

cat > templates/apache-vhost.j2 << 'EOF'
# Apache Virtual Host Configuration
# Generated by Ansible on {{ ansible_date_time.iso8601 }}
# Environment: {{ app_settings.environment | upper }}

<VirtualHost *:80>
    ServerName {{ inventory_hostname }}.{{ network_config.domain }}
    {% if network_config.domain != 'localhost' %}
    ServerAlias www.{{ inventory_hostname }}.{{ network_config.domain }}
    {% endif %}
    
    DocumentRoot /var/www/{{ inventory_hostname }}/html
    
    # Logging configuration
    ErrorLog /var/log/apache2/{{ inventory_hostname }}_error.log
    CustomLog /var/log/apache2/{{ inventory_hostname }}_access.log combined
    
    # Security headers
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    
    # Environment specific settings
    {% if app_settings.environment == 'production' %}
    # Production settings
    ServerTokens Prod
    ServerSignature Off
    {% elif app_settings.environment == 'development' %}
    # Development settings
    LogLevel debug
    {% endif %}
    
    # Directory configuration
    <Directory /var/www/{{ inventory_hostname }}/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Connection limits based on app settings
        {% if app_settings.max_connections > 500 %}
        # High traffic configuration
        KeepAlive On
        MaxKeepAliveRequests {{ app_settings.max_connections // 10 }}
        KeepAliveTimeout {{ app_settings.timeout }}
        {% else %}
        # Standard configuration
        KeepAlive Off
        {% endif %}
    </Directory>
    
    # User access control
    {% set admin_users = users | selectattr('department', 'equalto', 'engineering') | selectattr('active') | list %}
    {% if admin_users | length > 0 %}
    <Location "/admin">
        AuthType Basic
        AuthName "Admin Area"
        AuthUserFile /etc/apache2/.htpasswd
        Require user {% for user in admin_users %}{{ user.name }}{% if not loop.last %} {% endif %}{% endfor %}
    </Location>
    {% endif %}
    
</VirtualHost>

# SSL Virtual Host (if certificates are available)
{% if app_settings.environment == 'production' %}
<VirtualHost *:443>
    ServerName {{ inventory_hostname }}.{{ network_config.domain }}
    DocumentRoot /var/www/{{ inventory_hostname }}/html
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/{{ inventory_hostname }}.crt
    SSLCertificateKeyFile /etc/ssl/private/{{ inventory_hostname }}.key
    
    # Redirect HTTP to HTTPS
    <VirtualHost *:80>
        ServerName {{ inventory_hostname }}.{{ network_config.domain }}
        Redirect permanent / https://{{ inventory_hostname }}.{{ network_config.domain }}/
    </VirtualHost>
</VirtualHost>
{% endif %}
EOF
Subtask 3.3: Playbook to Generate Configurations
Create a playbook that uses the templates to generate configurations.

cat > playbooks/04-generate-configs.yml << 'EOF'
---
- name: Generate Configuration Files Using Jinja2 Templates
  hosts: all
  gather_facts: true
  vars_files:
    - ../vars/sample_data.yml
  
  tasks:
    - name: Create output directory
      file:
        path: "{{ playbook_dir }}/../output"
        state: directory
      delegate_to: localhost
      run_once: true
    
    - name: Generate router configuration
      template:
        src: ../templates/router-config.j2
        dest: "{{ playbook_dir }}/../output/{{ inventory_hostname }}-router.cfg"
      delegate_to: localhost
      when: inventory_hostname in groups['all']
    
    - name: Generate Apache virtual host configuration
      template:
        src: ../templates/apache-vhost.j2
        dest: "{{ playbook_dir }}/../output/{{ inventory_hostname }}-vhost.conf"
      delegate_to: localhost
      when: inventory_hostname in groups['webservers']
    
    - name: Display generated files
      debug:
        msg: "Configuration files generated in {{ playbook_dir }}/../output/"
      run_once: true
    
    - name: Show file contents for verification
      debug:
        msg: "{{ lookup('file', playbook_dir + '/../output/' + inventory_hostname + '-router.cfg') }}"
      when: inventory_hostname == 'web1'
EOF
Run the configuration generation playbook:

ansible-playbook -i inventory/hosts playbooks/04-generate-configs.yml
Task 4: Advanced Jinja2 Techniques
Subtask 4.1: Custom Filters and Complex Logic
Create a playbook demonstrating advanced Jinja2 techniques.

cat > playbooks/05-advanced-jinja2.yml << 'EOF'
---
- name: Advanced Jinja2 Techniques
  hosts: localhost
  gather_facts: true
  vars_files:
    - ../vars/sample_data.yml
  vars:
    server_specs:
      - hostname: web-server-01
        cpu_cores: 4
        memory_gb: 8
        disk_gb: 100
        os: "ubuntu-20.04"
      - hostname: db-server-01
        cpu_cores: 8
        memory_gb: 16
        disk_gb: 500
        os: "centos-8"
      - hostname: app-server-01
        cpu_cores: 2
        memory_gb: 4
        disk_gb: 50
        os: "debian-11"
  
  tasks:
    - name: Conditional formatting based on values
      debug:
        msg: |
          Server: {{ item.hostname }}
          Performance Class: {% if item.cpu_cores >= 8 %}High-Performance{% elif item.cpu_cores >= 4 %}Standard{% else %}Basic{% endif %}
          
          Memory Status: {{ item.memory_gb }}GB {% if item.memory_gb >= 16 %}(Excellent){% elif item.memory_gb >= 8 %}(Good){% else %}(Adequate){% endif %}
          
          Storage: {{ item.disk_gb }}GB {% if item.disk_gb >= 500 %}(Large){% elif item.disk_gb >= 100 %}(Medium){% else %}(Small){% endif %}
          
          OS Family: {% if 'ubuntu' in item.os or 'debian' in item.os %}Debian-based{% elif 'centos' in item.os or 'rhel' in item.os %}RedHat-based{% else %}Other{% endif %}
      loop: "{{ server_specs }}"
    
    - name: Complex data transformation
      debug:
        msg:
          - "Total CPU cores: {{ server_specs | map(attribute='cpu_cores') | sum }}"
          - "Total memory: {{ server_specs | map(attribute='memory_gb') | sum }}GB"
          - "Average disk size: {{ (server_specs | map(attribute='disk_gb') | sum) // (server_specs | length) }}GB"
          - "High-performance servers: {{ server_specs | selectattr('cpu_cores', '>=', 8) | map(attribute='hostname') | list }}"
    
    - name: JSON and YAML formatting
      debug:
        msg:
          - "Users as JSON: {{ users | to_nice_json }}"
          - "Network config as YAML: {{ network_config | to_nice_yaml }}"
    
    - name: Regular expressions and pattern matching
      debug:
        msg: "Email domains: {{ users | map(attribute='email') | map('regex_replace', '^.*@(.*)$', '\\1') | unique | list }}"
    
    - name: Base64 encoding and hashing
      debug:
        msg:
          - "Encoded hostname: {{ inventory_hostname | b64encode }}"
          - "SHA256 hash: {{ inventory_hostname | hash('sha256') }}"
          - "MD5 hash: {{ inventory_hostname | hash('md5') }}"
EOF
Subtask 4.2: Error Handling and Default Values
Create a playbook that demonstrates error handling in Jinja2 templates.

cat > playbooks/06-error-handling.yml << 'EOF'
---
- name: Jinja2 Error Handling and Default Values
  hosts: localhost
  gather_facts: false
  vars:
    incomplete_data:
      - name: "server1"
        # missing other fields
      - name: "server2"
        ip: "192.168.1.100"
        # missing other fields
    
  tasks:
    - name: Using default filter for missing values
      debug:
        msg:
          - "Server: {{ item.name }}"
          - "IP: {{ item.ip | default('Not configured') }}"
          - "Port: {{ item.port | default(80) }}"
          - "SSL: {{ item.ssl | default(false) | bool }}"
      loop: "{{ incomplete_data }}"
    
    - name: Safe attribute access
      debug:
        msg:
          - "User count: {{ users | default([]) | length }}"
          - "First user name: {{ users[0].name | default('No users') }}"
          - "Network domain: {{ network_config.domain | default('localhost') }}"
    
    - name: Conditional checks before processing
      debug:
        msg: |
          {% if users is defined and users | length > 0 %}
          Active users: {{ users | selectattr('active', 'defined') | selectattr('active') | map(attribute='name') | list | join(', ') }}
          {% else %}
          No user data available
          {% endif %}
    
    - name: Type checking and conversion
      debug:
        msg:
          - "App version (string): {{ app_settings.version | string }}"
          - "Max connections (int): {{ app_settings.max_connections | int }}"
          - "Debug mode (bool): {{ app_settings.debug_mode | bool }}"
          - "Timeout as string: '{{ app_settings.timeout | string }}'"
    
    - name: List safety checks
      debug:
        msg: |
          {% set user_list = users | default([]) %}
          {% if user_list | length > 0 %}
          Processing {{ user_list | length }} users:
          {% for user in user_list %}
          - {{ user.name | default('Unknown') }} ({{ user.department | default('No department') }})
          {% endfor %}
          {% else %}
          No users to process
          {% endif %}
EOF
Run the advanced technique playbooks:

ansible-playbook -i inventory/hosts playbooks/05-advanced-jinja2.yml
ansible-playbook -i inventory/hosts playbooks/06-error-handling.yml
Task 5: Real-World Configuration Generation
Subtask 5.1: Complete Network Device Template
Create a comprehensive network device configuration template.

cat > templates/complete-network-config.j2 << 'EOF'
!
! Complete Network Device Configuration
! Device: {{ inventory_hostname | upper }}
! Generated: {{ ansible_date_time.iso8601 }}
! Environment: {{ app_settings.environment | upper }}
!
version {{ app_settings.version }}
!
{% if app_settings.environment == 'production' %}
! Production Security Settings
service password-encryption
service timestamps debug datetime msec
service timestamps log datetime msec
no service dhcp
{% else %}
! Development Settings
service timestamps debug uptime
service timestamps log uptime
{% endif %}
!
hostname {{ inventory_hostname | upper }}
!
! User Management
{% for user in users %}
{% if user.active %}
username {{ user.name | replace('_', '-') | upper }} privilege {% if user.department == 'engineering' %}15{% else %}1{% endif %} secret {{ user.name | hash('sha256') | truncate(12, true, '') }}
{% endif %}
{% endfor %}
!
! AAA Configuration
aaa new-model
aaa authentication login default local
aaa authorization exec default local
!
! Domain and DNS
ip domain-name {{ network_config.domain }}
{% for dns in network_config.dns_servers %}
ip name-server {{ dns }}
{% endfor %}
!
! VLAN Database
{% for vlan in network_config.vlans %}
vlan {{ vlan.id }}
 name {{ vlan.name | upper | replace(' ', '_') }}
{% endfor %}
!
! Interface Configuration
{% for vlan in network_config.vlans %}
{% set loop_index = loop.index %}
interface GigabitEthernet0/{{ loop_index }}
 description {{ vlan.name | title }} Network - VLAN {{ vlan.id }}
 switchport mode access
 switchport access vlan {{ vlan.id }}
 no shutdown
!
interface Vlan{{ vlan.id }}
 description {{ vlan.name | title }} SVI
 ip address {{ vlan.subnet | ipaddr('1') | ipaddr('address') }} {{ vlan.subnet | ipaddr('netmask') }}
 {% if vlan.name == 'management' %}
 ip helper-address {{ network_config.dns_servers[0] }}
 {% endif %}
 no shutdown
!
{% endfor %}
!
! Routing Configuration
ip routing
{% for vlan in network_config.vlans %}
{% if not loop.first %}
ip route {{ vlan.subnet }} {{ vlan.subnet | ipaddr('netmask') }} Vlan{{ vlan.id }}
{% endif %}
{% endfor %}
!
! Access Control Lists
{% set mgmt_vlan = network_config.vlans | selectattr('name', 'equalto', 'management') | first %}
{% if mgmt_vlan is defined %}
ip access-list extended MGMT_ACCESS
 permit tcp {{ mgmt_vlan.subnet | ipaddr('network') }} {{ mgmt_vlan.subnet | ipaddr('hostmask') }} any eq 22
 permit tcp {{ mgmt_vlan.subnet | ipaddr('network') }} {{ mgmt_vlan.subnet | ipaddr('hostmask') }} any eq 443
 deny ip any any log
!
{% endif %}
!
! SNMP Configuration
{% if app_settings.environment == 'production' %}
snmp-server community {{ 'production' | hash('md5') | truncate(8, true, '') }} RO
{% else %}
snmp-server community public RO
{% endif %}
snmp-server location {{ inventory_hostname | title }} - {{ app_settings.environment | title }}
snmp-server contact {{ users | selectattr('department', 'equalto', 'engineering') | selectattr('active') | map(attribute='email') | first | default('admin@company.com') }}
!
! Logging
{% if app_settings.debug_mode %}
logging console debugging
logging buffered 32768 debugging
{% else %}
logging console warnings
logging buffered 16384 informational
{% endif %}
logging source-interface Vlan{{ network_config.vlans[0].id }}
!
! NTP Configuration
ntp server {{ network_config.dns_servers[0] }}
ntp server {{ network_config.dns_servers[1] }}
!
! Line Configuration
line console 0
 exec-timeout {{ app_settings.timeout }} 0
 logging synchronous
 login authentication default
!
line vty 0 {{ (app_settings.max_connections // 100) | int }}
 exec-timeout {{ app_settings.timeout }} 0
 transport input ssh
 login authentication default
!
! SSH Configuration
ip ssh version 2
ip ssh time-out {{ app_settings.timeout }}
ip ssh authentication-retries 3
!
end
EOF
Subtask 5.2: Application Configuration Template
Create a comprehensive application configuration template.

cat > templates/app-config.j2 << 'EOF'
# Application Configuration File
# Generated by Ansible on {{ ansible_date_time.iso8601 }}
# Host: {{ inventory_hostname }}
# Environment: {{ app_settings.environment | upper }}

[application]
version = {{ app_settings.version }}
environment = {{ app_settings.environment }}
debug = {{ app_settings.debug_mode | lower }}
max_connections = {{ app_settings.max_connections }}
timeout = {{ app_settings.timeout }}

[database]
{% set db_host = groups['databases'][0] | default('localhost') %}
host = {{ db_host }}
port = 5432
name = {{ app_settings.environment }}_db
user = app_user
# Connection pool settings based on max_connections
pool_size = {{ (app_settings.max_connections * 0.1) | int }}
max_overflow = {{ (app_settings.max_connections * 0.05) | int }}

[network]
domain = {{ network_config.domain }}
{% for dns in network_config.dns_servers %}
dns_server_{{ loop.index }} = {{ dns }}
{% endfor %}

# VLAN Configuration
{% for vlan in network_config.vlans %}
vlan_{{ vlan.name }}_id = {{ vlan.id }}
vlan_{{ vlan.name }}_subnet = {{ vlan.subnet }}
{% endfor %}

[security]
{% if app_settings.environment == 'production' %}
# Production security settings
ssl_required = true
session_timeout = {{ app_settings.timeout * 60 }}
password_complexity = high
{% else %}
# Development security settings
ssl_required = false
session_timeout = {{ app_settings.timeout * 120 }}
password_complexity = medium
{% endif %}

# User access levels
{% for user in users %}
{% if user.active %}
user_{{ user.name }}_level = {% if user.department == 'engineering' %}admin{% elif user.department == 'management' %}manager{% else %}user{% endif %}
user_{{ user.name }}_email = {{ user.email }}
{% endif %}
{% endfor %}

[logging]
{% if app_settings.debug_mode %}
level = DEBUG
{% elif app_settings.environment == 'production' %}
level = WARNING
{% else %}
level = INFO
{% endif %}

log_file = /var/log/{{ inventory_hostname }}/app.log
max_file_size = 10MB
backup_count = 5

# Performance monitoring
[monitoring]
enabled = {{ 'true' if app_settings.environment == 'production' else 'false' }}
metrics_interval = 60
{% if app_settings.max_connections > 500 %}
# High-load monitoring
cpu_threshold = 80
memory_threshold = 85
disk_threshold = 90
{% else %}
# Standard monitoring
cpu_threshold = 70
memory_threshold = 75
disk_threshold = 80
{% endif %}

[cache]
{% if app_settings.environment == 'production' %}
# Production cache settings
enabled = true
ttl = {{ app_settings.timeout * 10 }}
max_size = {{ app_settings.max_connections * 2 }}MB
{% else %}
# Development cache settings
enabled = false
ttl = {{ app_settings.timeout }}
max_size = 100MB
{% endif %}

# Generated configuration summary
[summary]
total_users = {{ users | length }}
active_users = {{ users | selectattr('active') | list | length }}
admin_users = {{ users | selectattr('department', 'equalto', 'engineering') | selectattr('active') | list | length }}
total_vlans = {{ network_config.vlans | length }}
config_generated = {{ ansible_date_time.iso8601 }}
EOF
Subtask 5.3: Master Playbook for All Configurations
Create a comprehensive playbook that generates all configurations.

cat > playbooks/07-master-config-generator.yml << 'EOF'
---
- name: Master Configuration Generator
  hosts: all
  gather_facts: true
  vars_files:
    - ../vars/sample_data.yml
  
  tasks:
    - name: Create output directories
      file:
        path: "{{ item }}"
        state: directory
      loop:
        - "{{ playbook_dir }}/../output/network-configs"
        - "{{ playbook_dir }}/../output/app-configs"
        - "{{ playbook_dir }}/../output/web-configs"
      delegate_to: localhost
      run_once: true
    
    - name: Generate complete network configuration
      template:
        src: ../templates/complete-network-config.j2
        dest: "{{ playbook_dir }}/../output/network-configs/{{ inventory_hostname }}-complete.cfg"
      delegate_to: localhost
    
    - name: Generate application configuration
      template:
        src: ../templates/app-config.j2
        dest: "{{ playbook_dir }}/../output/app-configs/{{
