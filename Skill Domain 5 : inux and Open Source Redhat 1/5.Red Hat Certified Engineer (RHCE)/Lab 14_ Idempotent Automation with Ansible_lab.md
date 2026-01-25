Lab 14: Idempotent Automation with Ansible
Objectives
By the end of this lab, students will be able to:

Understand the concept of idempotency in automation and why it's crucial
Modify Ansible playbooks to ensure idempotent behavior
Implement proper handlers and conditional statements to prevent unintended changes
Test playbook idempotency by running the same playbook multiple times
Use Ansible modules that naturally support idempotent operations
Troubleshoot common idempotency issues in automation scripts
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Previous experience with Ansible basics (playbooks, tasks, modules)
Understanding of SSH key-based authentication
Knowledge of basic system administration concepts (users, services, packages)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or install software - everything is ready to use!

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: Two target servers (node1 and node2) for testing
Pre-configured SSH keys for passwordless authentication
Sample configuration files and directories
Task 1: Understanding Idempotency and Creating a Non-Idempotent Playbook
Subtask 1.1: Connect to Your Lab Environment
Access your control node through the provided terminal interface
Verify Ansible installation and version:
ansible --version
Check the inventory file to see your managed nodes:
cat /etc/ansible/hosts
Test connectivity to managed nodes:
ansible all -m ping
Subtask 1.2: Create a Non-Idempotent Playbook Example
First, let's create a playbook that demonstrates non-idempotent behavior to understand the problem:

Create a working directory for this lab:
mkdir ~/ansible-idempotency-lab
cd ~/ansible-idempotency-lab
Create a non-idempotent playbook:
nano non-idempotent-playbook.yml
Add the following content:
---
- name: Non-Idempotent Configuration Example
  hosts: all
  become: yes
  tasks:
    - name: Add a line to /etc/hosts (NON-IDEMPOTENT)
      shell: echo "192.168.1.100 custom-server" >> /etc/hosts
      
    - name: Create a user with shell command (NON-IDEMPOTENT)
      shell: useradd -m testuser
      
    - name: Install package using shell (NON-IDEMPOTENT)
      shell: yum install -y wget
      
    - name: Start a service using shell (NON-IDEMPOTENT)
      shell: systemctl start httpd
Run this playbook and observe the behavior:
ansible-playbook non-idempotent-playbook.yml
Run it again immediately and notice the errors and duplicate entries:
ansible-playbook non-idempotent-playbook.yml
Subtask 1.3: Analyze the Problems
Check the /etc/hosts file on a managed node to see duplicate entries:
ansible all -m shell -a "tail -5 /etc/hosts"
Try to check if the user was created multiple times:
ansible all -m shell -a "grep testuser /etc/passwd"
The problems with the non-idempotent approach:

Duplicate entries in configuration files
Error messages when trying to create existing users
Unnecessary operations that waste time and resources
Unpredictable state of the target systems
Task 2: Converting to Idempotent Operations
Subtask 2.1: Create an Idempotent Version
Create a new idempotent playbook:
nano idempotent-playbook.yml
Add the following idempotent version:
---
- name: Idempotent Configuration Example
  hosts: all
  become: yes
  tasks:
    - name: Ensure custom server entry in /etc/hosts
      lineinfile:
        path: /etc/hosts
        line: "192.168.1.100 custom-server"
        state: present
        backup: yes
      
    - name: Ensure testuser exists
      user:
        name: testuser
        state: present
        create_home: yes
        shell: /bin/bash
      
    - name: Ensure wget package is installed
      package:
        name: wget
        state: present
      
    - name: Ensure httpd package is installed
      package:
        name: httpd
        state: present
        
    - name: Ensure httpd service is started and enabled
      service:
        name: httpd
        state: started
        enabled: yes
Subtask 2.2: Test Idempotency
First, clean up the previous non-idempotent changes:
ansible all -m shell -a "userdel -r testuser" --ignore-errors
ansible all -m shell -a "sed -i '/custom-server/d' /etc/hosts"
ansible all -m package -a "name=httpd state=absent" --become
Run the idempotent playbook for the first time:
ansible-playbook idempotent-playbook.yml
Note the output showing "changed" status for tasks that made modifications.

Run the same playbook again immediately:

ansible-playbook idempotent-playbook.yml
Observe that the second run shows "ok" status instead of "changed" for most tasks, indicating no changes were made.
Subtask 2.3: Verify Idempotent Behavior
Check that /etc/hosts contains only one entry:
ansible all -m shell -a "grep -c custom-server /etc/hosts"
Verify the user exists and wasn't duplicated:
ansible all -m shell -a "id testuser"
Check service status:
ansible all -m shell -a "systemctl is-active httpd"
Task 3: Implementing Advanced Idempotency with Handlers and Conditions
Subtask 3.1: Create a Configuration Management Playbook
Create a more complex playbook that demonstrates handlers and conditions:
nano advanced-idempotent-playbook.yml
Add the following content:
---
- name: Advanced Idempotent Web Server Configuration
  hosts: all
  become: yes
  vars:
    web_port: 8080
    document_root: /var/www/html
    
  tasks:
    - name: Ensure httpd package is installed
      package:
        name: httpd
        state: present
      notify: restart httpd
      
    - name: Ensure custom web directory exists
      file:
        path: "{{ document_root }}/custom"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
      
    - name: Create custom httpd configuration
      template:
        src: httpd-custom.conf.j2
        dest: /etc/httpd/conf.d/custom.conf
        backup: yes
      notify: restart httpd
      
    - name: Ensure index.html exists with specific content
      copy:
        content: |
          <html>
          <head><title>Idempotent Web Server</title></head>
          <body>
          <h1>Welcome to Idempotent Configuration</h1>
          <p>This server is configured using idempotent Ansible playbooks.</p>
          <p>Port: {{ web_port }}</p>
          </body>
          </html>
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      
    - name: Ensure firewall allows HTTP traffic
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      when: ansible_facts['os_family'] == "RedHat"
      
    - name: Ensure httpd service is running and enabled
      service:
        name: httpd
        state: started
        enabled: yes
        
  handlers:
    - name: restart httpd
      service:
        name: httpd
        state: restarted
      listen: restart httpd
Subtask 3.2: Create the Template File
Create a templates directory:
mkdir templates
Create the configuration template:
nano templates/httpd-custom.conf.j2
Add the following template content:
# Custom HTTP Configuration - Managed by Ansible
# This file is automatically generated - do not edit manually

Listen {{ web_port }}

<VirtualHost *:{{ web_port }}>
    DocumentRoot {{ document_root }}
    ServerName {{ ansible_hostname }}.local
    
    <Directory "{{ document_root }}">
        AllowOverride None
        Require all granted
    </Directory>
    
    ErrorLog logs/custom_error.log
    CustomLog logs/custom_access.log combined
</VirtualHost>
Subtask 3.3: Test Advanced Idempotency
Run the advanced playbook:
ansible-playbook advanced-idempotent-playbook.yml
Note which tasks show "changed" status and observe handler execution.

Run the playbook again immediately:

ansible-playbook advanced-idempotent-playbook.yml
Observe that handlers are not triggered on the second run since no changes occurred.

Verify the web server is running on the custom port:

ansible all -m shell -a "netstat -tlnp | grep :8080"
Subtask 3.4: Test Conditional Idempotency
Create a playbook that demonstrates conditional idempotency:
nano conditional-idempotent-playbook.yml
Add the following content:
---
- name: Conditional Idempotent Operations
  hosts: all
  become: yes
  tasks:
    - name: Check if custom configuration exists
      stat:
        path: /etc/custom-app.conf
      register: custom_config
      
    - name: Create initial configuration only if it doesn't exist
      copy:
        content: |
          # Custom Application Configuration
          app_name=MyApp
          version=1.0
          debug=false
        dest: /etc/custom-app.conf
        mode: '0644'
      when: not custom_config.stat.exists
      
    - name: Ensure specific configuration line exists
      lineinfile:
        path: /etc/custom-app.conf
        regexp: '^log_level='
        line: 'log_level=info'
        state: present
      
    - name: Ensure debug is disabled (idempotent replacement)
      replace:
        path: /etc/custom-app.conf
        regexp: '^debug=true'
        replace: 'debug=false'
      
    - name: Create backup only if file was modified today
      copy:
        src: /etc/custom-app.conf
        dest: /etc/custom-app.conf.backup
        remote_src: yes
      when: 
        - custom_config.stat.exists
        - custom_config.stat.mtime > (ansible_date_time.epoch | int - 86400)
Run this conditional playbook:
ansible-playbook conditional-idempotent-playbook.yml
Run it again to see conditional behavior:
ansible-playbook conditional-idempotent-playbook.yml
Task 4: Testing and Validating Idempotency
Subtask 4.1: Create a Comprehensive Test Playbook
Create a test playbook that validates idempotency:
nano test-idempotency.yml
Add the following content:
---
- name: Comprehensive Idempotency Test
  hosts: all
  become: yes
  vars:
    test_results: []
    
  tasks:
    - name: Ensure test directory structure
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - /opt/test-app
        - /opt/test-app/config
        - /opt/test-app/logs
        - /opt/test-app/data
      
    - name: Create application configuration files
      template:
        src: app-config.j2
        dest: "/opt/test-app/config/{{ item.name }}.conf"
        mode: '0644'
      loop:
        - { name: "database", content: "host=localhost\nport=5432\ndb=testdb" }
        - { name: "cache", content: "host=localhost\nport=6379\nttl=3600" }
        - { name: "logging", content: "level=info\nfile=/opt/test-app/logs/app.log" }
      vars:
        config_content: "{{ item.content }}"
      
    - name: Ensure application user exists
      user:
        name: appuser
        system: yes
        home: /opt/test-app
        shell: /bin/bash
        state: present
        
    - name: Set proper ownership on application directories
      file:
        path: /opt/test-app
        owner: appuser
        group: appuser
        recurse: yes
        
    - name: Create systemd service file
      copy:
        content: |
          [Unit]
          Description=Test Application
          After=network.target
          
          [Service]
          Type=simple
          User=appuser
          WorkingDirectory=/opt/test-app
          ExecStart=/bin/bash -c 'while true; do echo "App running: $(date)" >> logs/app.log; sleep 60; done'
          Restart=always
          
          [Install]
          WantedBy=multi-user.target
        dest: /etc/systemd/system/test-app.service
        mode: '0644'
      notify: reload systemd
      
    - name: Ensure service is enabled but not necessarily started
      systemd:
        name: test-app
        enabled: yes
        daemon_reload: yes
        
  handlers:
    - name: reload systemd
      systemd:
        daemon_reload: yes
Create the template file for configurations:
nano templates/app-config.j2
Add the template content:
# {{ ansible_managed }}
# Configuration file generated by Ansible
# Last updated: {{ ansible_date_time.iso8601 }}

{{ config_content }}

# System Information
hostname={{ ansible_hostname }}
os_family={{ ansible_os_family }}
Subtask 4.2: Run Idempotency Tests
Execute the test playbook multiple times and measure execution time:
time ansible-playbook test-idempotency.yml
Run it again immediately:
time ansible-playbook test-idempotency.yml
Compare execution times - the second run should be significantly faster.

Verify all components are properly configured:

ansible all -m shell -a "ls -la /opt/test-app/"
ansible all -m shell -a "systemctl is-enabled test-app"
ansible all -m shell -a "id appuser"
Subtask 4.3: Create an Idempotency Validation Script
Create a validation script:
nano validate-idempotency.sh
Add the following content:
#!/bin/bash

# Idempotency Validation Script
echo "=== Ansible Idempotency Validation ==="
echo "Testing playbook: $1"

if [ -z "$1" ]; then
    echo "Usage: $0 <playbook-name.yml>"
    exit 1
fi

PLAYBOOK=$1
TEMP_DIR="/tmp/idempotency-test-$(date +%s)"
mkdir -p $TEMP_DIR

echo "Running playbook first time..."
ansible-playbook $PLAYBOOK > $TEMP_DIR/run1.log 2>&1
FIRST_EXIT_CODE=$?

echo "Running playbook second time..."
ansible-playbook $PLAYBOOK > $TEMP_DIR/run2.log 2>&1
SECOND_EXIT_CODE=$?

echo "Analyzing results..."

# Count changed tasks in each run
CHANGED_RUN1=$(grep -c "changed:" $TEMP_DIR/run1.log || echo "0")
CHANGED_RUN2=$(grep -c "changed:" $TEMP_DIR/run2.log || echo "0")

# Count failed tasks
FAILED_RUN1=$(grep -c "failed:" $TEMP_DIR/run1.log || echo "0")
FAILED_RUN2=$(grep -c "failed:" $TEMP_DIR/run2.log || echo "0")

echo "=== RESULTS ==="
echo "First run - Exit code: $FIRST_EXIT_CODE, Changed tasks: $CHANGED_RUN1, Failed tasks: $FAILED_RUN1"
echo "Second run - Exit code: $SECOND_EXIT_CODE, Changed tasks: $CHANGED_RUN2, Failed tasks: $FAILED_RUN2"

if [ $SECOND_EXIT_CODE -eq 0 ] && [ $CHANGED_RUN2 -eq 0 ] && [ $FAILED_RUN2 -eq 0 ]; then
    echo "✅ IDEMPOTENCY TEST PASSED"
    echo "The playbook is idempotent - no changes on second run"
else
    echo "❌ IDEMPOTENCY TEST FAILED"
    echo "The playbook made changes or had errors on second run"
    echo "Check logs in: $TEMP_DIR"
fi

echo "Detailed logs available in: $TEMP_DIR"
Make the script executable:
chmod +x validate-idempotency.sh
Test the validation script with your playbooks:
./validate-idempotency.sh idempotent-playbook.yml
./validate-idempotency.sh advanced-idempotent-playbook.yml
Task 5: Common Idempotency Patterns and Best Practices
Subtask 5.1: Implement Common Idempotency Patterns
Create a best practices playbook:
nano idempotency-best-practices.yml
Add comprehensive examples:
---
- name: Idempotency Best Practices Demonstration
  hosts: all
  become: yes
  vars:
    app_version: "2.1.0"
    config_hash: "{{ lookup('file', 'templates/app-config.j2') | hash('md5') }}"
    
  tasks:
    # Pattern 1: Using 'creates' parameter for command/shell tasks
    - name: Download application archive (idempotent with creates)
      get_url:
        url: "https://github.com/example/app/archive/v{{ app_version }}.tar.gz"
        dest: "/tmp/app-{{ app_version }}.tar.gz"
        mode: '0644'
      
    - name: Extract application (idempotent with creates)
      unarchive:
        src: "/tmp/app-{{ app_version }}.tar.gz"
        dest: /opt/
        remote_src: yes
        creates: "/opt/app-{{ app_version }}"
        
    # Pattern 2: Using register and when for conditional execution
    - name: Check if application is already configured
      stat:
        path: "/opt/app-{{ app_version }}/configured.flag"
      register: app_configured
      
    - name: Run application setup (only if not configured)
      shell: |
        cd /opt/app-{{ app_version }}
        ./setup.sh
        touch configured.flag
      when: not app_configured.stat.exists
      
    # Pattern 3: Using changed_when to control change reporting
    - name: Check application status
      shell: "/opt/app-{{ app_version }}/bin/app --status"
      register: app_status
      changed_when: false
      failed_when: app_status.rc not in [0, 1]
      
    # Pattern 4: Idempotent file modifications
    - name: Ensure configuration line exists
      lineinfile:
        path: "/opt/app-{{ app_version }}/config/app.conf"
        regexp: '^version='
        line: "version={{ app_version }}"
        create: yes
        
    # Pattern 5: Using blockinfile for multi-line configurations
    - name: Ensure logging configuration block
      blockinfile:
        path: "/opt/app-{{ app_version }}/config/logging.conf"
        block: |
          # Logging Configuration
          log.level=INFO
          log.file=/var/log/app.log
          log.rotation=daily
          log.retention=30
        marker: "# {mark} ANSIBLE MANAGED LOGGING BLOCK"
        create: yes
        
    # Pattern 6: Idempotent service management
    - name: Ensure application service file
      template:
        src: app.service.j2
        dest: /etc/systemd/system/myapp.service
      notify:
        - reload systemd
        - restart myapp
        
    - name: Ensure service is enabled and started
      systemd:
        name: myapp
        enabled: yes
        state: started
        daemon_reload: yes
        
  handlers:
    - name: reload systemd
      systemd:
        daemon_reload: yes
        
    - name: restart myapp
      systemd:
        name: myapp
        state: restarted
Subtask 5.2: Create Service Template
Create the service template:
nano templates/app.service.j2
Add the service definition:
[Unit]
Description=My Application v{{ app_version }}
After=network.target

[Service]
Type=forking
User=appuser
Group=appuser
WorkingDirectory=/opt/app-{{ app_version }}
ExecStart=/opt/app-{{ app_version }}/bin/app --daemon
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/var/run/myapp.pid
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
Subtask 5.3: Test Best Practices Implementation
Run the best practices playbook:
ansible-playbook idempotency-best-practices.yml
Validate idempotency:
./validate-idempotency.sh idempotency-best-practices.yml
Check specific idempotent behaviors:
# Verify creates parameter works
ansible all -m shell -a "ls -la /opt/app-*"

# Check configuration files
ansible all -m shell -a "cat /opt/app-*/config/app.conf"

# Verify service status
ansible all -m shell -a "systemctl status myapp" --ignore-errors
Troubleshooting Common Idempotency Issues
Common Problems and Solutions
File Permission Issues

# Problem: Permissions change every run
- name: Wrong way - permissions always change
  file:
    path: /etc/myapp.conf
    mode: 0644  # This might cause issues

# Solution: Use string format for modes
- name: Correct way - stable permissions
  file:
    path: /etc/myapp.conf
    mode: '0644'  # String format is more reliable
Shell Commands Not Idempotent

# Problem: Always shows changed
- name: Non-idempotent shell command
  shell: echo "config=value" >> /etc/app.conf

# Solution: Use appropriate modules
- name: Idempotent configuration
  lineinfile:
    path: /etc/app.conf
    line: "config=value"
    state: present
Handler Issues

# Problem: Handlers run unnecessarily
- name: Template with dynamic content
  template:
    src: config.j2
    dest: /etc/app.conf
  notify: restart service

# Solution: Use backup and check for real changes
- name: Template with change detection
  template:
    src: config.j2
    dest: /etc/app.conf
    backup: yes
  register: config_result
  notify: restart service
  when: config_result.changed
Conclusion
In this comprehensive lab, you have successfully learned and implemented idempotent automation practices with Ansible. Here's what you accomplished:

Key Achievements
Understanding Idempotency: You learned why idempotency is crucial in automation - ensuring that running the same playbook multiple times produces the same result without unintended side effects.

Practical Implementation: You converted non-idempotent shell commands into proper Ansible modules that naturally support idempotent operations, such as:

Using lineinfile instead of shell echo commands
Using user module instead of useradd commands
Using package and service modules for system management
Advanced Techniques: You implemented sophisticated idempotency patterns including:

Handlers for efficient service management
Conditional statements for smart decision-making
Templates for dynamic configuration management
Validation scripts for testing idempotency
Best Practices Mastery: You learned industry-standard approaches such as:

Using creates parameter for command tasks
Implementing proper change detection with register and when
Managing multi-line configurations with blockinfile
Controlling change reporting with changed_when
Why This Matters
For System Administrators: Idempotent automation ensures that your infrastructure remains in a consistent, predictable state regardless of how many times you run your automation scripts. This reduces errors, saves time, and increases confidence in your automation.

For DevOps Engineers: These skills are essential for building reliable CI/CD pipelines and infrastructure-as-code solutions that can be safely executed in production environments.

For Career Development: Understanding idempotency is a fundamental requirement for the Red Hat Certified Engineer (RHCE) certification and is highly valued in the industry for automation roles.

Next Steps
Practice creating idempotent playbooks for your own use cases
Explore Ansible Galaxy for community roles that demonstrate idempotent patterns
Study advanced Ansible features like custom modules and plugins
Apply these concepts to larger infrastructure automation projects
The principles you've learned in this lab form the foundation of professional-grade automation and will serve you well in managing complex IT environments efficiently and reliably.
