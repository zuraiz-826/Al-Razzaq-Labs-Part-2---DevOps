Lab 10: Write Simple Ansible Playbooks
Objectives
By the end of this lab, you will be able to:

Understand the structure and syntax of Ansible playbooks
Create a basic playbook to install packages on managed hosts
Execute playbooks using the ansible-playbook command
Modify playbooks to include multiple tasks and advanced configurations
Implement best practices for playbook organization and error handling
Troubleshoot common playbook execution issues
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and formatting
Knowledge of SSH key-based authentication
Completion of previous Ansible labs covering inventory management and ad-hoc commands
Understanding of package management concepts (yum, apt, dnf)
Basic text editor skills (vim, nano, or similar)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or configure complex networking.

Your lab environment includes:

Control Node: CentOS/RHEL 8 system with Ansible pre-installed
Managed Hosts: Two target systems (managed1 and managed2) ready for automation
Pre-configured SSH keys and inventory files
All necessary permissions and network connectivity
Task 1: Create a Basic Playbook to Install a Package
Subtask 1.1: Understanding Playbook Structure
Before creating your first playbook, let's understand the basic structure of an Ansible playbook.

Connect to your control node and navigate to your working directory:
cd /home/student/ansible-labs
Create a new directory for this lab:
mkdir lab10-playbooks
cd lab10-playbooks
Examine the basic playbook structure by creating a simple example:
cat > playbook-structure-example.yml << 'EOF'
---
# This is a YAML comment - playbooks start with three dashes
- name: Example playbook structure
  hosts: all                    # Target hosts or groups
  become: yes                   # Run with elevated privileges
  vars:                        # Variables section
    package_name: httpd
  
  tasks:                       # List of tasks to execute
    - name: Task description
      module_name:             # Ansible module to use
        parameter: value       # Module parameters
EOF
Subtask 1.2: Create Your First Package Installation Playbook
Create a playbook to install the Apache web server:
cat > install-apache.yml << 'EOF'
---
- name: Install Apache Web Server
  hosts: managed1
  become: yes
  
  tasks:
    - name: Install Apache package
      yum:
        name: httpd
        state: present
    
    - name: Start and enable Apache service
      systemd:
        name: httpd
        state: started
        enabled: yes
    
    - name: Open firewall for HTTP traffic
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
EOF
Verify the playbook syntax before execution:
ansible-playbook --syntax-check install-apache.yml
Check the inventory to ensure your managed hosts are accessible:
ansible all --list-hosts
Subtask 1.3: Understanding Playbook Components
Let's break down the key components of your playbook:

---: YAML document separator (required at the beginning)
name: Human-readable description of the play
hosts: Specifies target hosts or groups from inventory
become: Enables privilege escalation (sudo)
tasks: List of actions to perform on target hosts
Module parameters: Specific configuration for each task
Task 2: Execute the Playbook Using ansible-playbook
Subtask 2.1: Basic Playbook Execution
Run the playbook with verbose output to see detailed execution:
ansible-playbook -v install-apache.yml
Verify the installation by checking if Apache is running:
ansible managed1 -m systemd -a "name=httpd" --become
Test the web server by making an HTTP request:
ansible managed1 -m uri -a "url=http://managed1 method=GET"
Subtask 2.2: Advanced Execution Options
Run with different verbosity levels to understand output detail:
# Standard output
ansible-playbook install-apache.yml

# Verbose output (-v)
ansible-playbook -v install-apache.yml

# Very verbose output (-vv)
ansible-playbook -vv install-apache.yml

# Debug level output (-vvv)
ansible-playbook -vvv install-apache.yml
Execute in check mode (dry run) to see what would change:
ansible-playbook --check install-apache.yml
Use step mode to execute tasks one at a time:
ansible-playbook --step install-apache.yml
Subtask 2.3: Limiting Execution Scope
Run the playbook on specific hosts:
ansible-playbook install-apache.yml --limit managed1
Execute specific tags (we'll add tags in the next task):
# This will be used after we modify the playbook
ansible-playbook install-apache.yml --tags "install"
Task 3: Modify the Playbook to Include Multiple Tasks
Subtask 3.1: Enhanced Playbook with Multiple Tasks
Create an advanced playbook with multiple tasks and features:
cat > advanced-webserver.yml << 'EOF'
---
- name: Deploy Complete Web Server Setup
  hosts: managed_hosts
  become: yes
  vars:
    web_package: httpd
    web_service: httpd
    document_root: /var/www/html
    custom_index_content: |
      <html>
      <head><title>Ansible Managed Server</title></head>
      <body>
        <h1>Welcome to {{ inventory_hostname }}</h1>
        <p>This server was configured by Ansible on {{ ansible_date_time.date }}</p>
        <p>Server IP: {{ ansible_default_ipv4.address }}</p>
      </body>
      </html>
  
  tasks:
    - name: Install web server package
      yum:
        name: "{{ web_package }}"
        state: present
      tags:
        - install
        - packages
    
    - name: Install additional packages
      yum:
        name:
          - wget
          - curl
          - vim
        state: present
      tags:
        - install
        - packages
    
    - name: Create custom index.html
      copy:
        content: "{{ custom_index_content }}"
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      tags:
        - content
        - configuration
      notify:
        - restart web service
    
    - name: Configure firewall for HTTP
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      tags:
        - firewall
        - security
    
    - name: Configure firewall for HTTPS
      firewalld:
        service: https
        permanent: yes
        state: enabled
        immediate: yes
      tags:
        - firewall
        - security
    
    - name: Start and enable web service
      systemd:
        name: "{{ web_service }}"
        state: started
        enabled: yes
      tags:
        - service
        - configuration
    
    - name: Verify web service is responding
      uri:
        url: "http://{{ inventory_hostname }}"
        method: GET
        status_code: 200
      tags:
        - verification
        - testing
      delegate_to: localhost
  
  handlers:
    - name: restart web service
      systemd:
        name: "{{ web_service }}"
        state: restarted
EOF
Subtask 3.2: Create a Multi-Host Inventory
Update your inventory to include multiple managed hosts:
cat > inventory << 'EOF'
[managed_hosts]
managed1 ansible_host=managed1.example.com
managed2 ansible_host=managed2.example.com

[webservers]
managed1
managed2

[all:vars]
ansible_user=student
ansible_ssh_private_key_file=/home/student/.ssh/id_rsa
EOF
Test connectivity to all hosts:
ansible -i inventory all -m ping
Subtask 3.3: Execute the Enhanced Playbook
Run the complete playbook:
ansible-playbook -i inventory advanced-webserver.yml
Execute specific tags:
# Install packages only
ansible-playbook -i inventory advanced-webserver.yml --tags "install"

# Configure content and services
ansible-playbook -i inventory advanced-webserver.yml --tags "content,service"

# Security-related tasks only
ansible-playbook -i inventory advanced-webserver.yml --tags "security"
Skip specific tags:
# Skip verification tasks
ansible-playbook -i inventory advanced-webserver.yml --skip-tags "verification"
Subtask 3.4: Create a Playbook with Conditional Tasks
Create a playbook that handles different operating systems:
cat > multi-os-setup.yml << 'EOF'
---
- name: Multi-OS Package Installation
  hosts: all
  become: yes
  
  tasks:
    - name: Gather OS facts
      setup:
        gather_subset:
          - '!all'
          - '!min'
          - distribution
    
    - name: Install packages on RedHat/CentOS systems
      yum:
        name:
          - httpd
          - firewalld
        state: present
      when: ansible_os_family == "RedHat"
      tags: redhat
    
    - name: Install packages on Debian/Ubuntu systems
      apt:
        name:
          - apache2
          - ufw
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
      tags: debian
    
    - name: Start service on RedHat systems
      systemd:
        name: httpd
        state: started
        enabled: yes
      when: ansible_os_family == "RedHat"
      tags: redhat
    
    - name: Start service on Debian systems
      systemd:
        name: apache2
        state: started
        enabled: yes
      when: ansible_os_family == "Debian"
      tags: debian
    
    - name: Display system information
      debug:
        msg: |
          Hostname: {{ inventory_hostname }}
          OS Family: {{ ansible_os_family }}
          Distribution: {{ ansible_distribution }}
          Version: {{ ansible_distribution_version }}
EOF
Execute the multi-OS playbook:
ansible-playbook -i inventory multi-os-setup.yml
Subtask 3.5: Create a Playbook with Loops and Variables
Create a playbook demonstrating loops and variable usage:
cat > loop-variables-demo.yml << 'EOF'
---
- name: Demonstrate Loops and Variables
  hosts: managed1
  become: yes
  vars:
    users_to_create:
      - name: webadmin
        shell: /bin/bash
        groups: wheel
      - name: developer
        shell: /bin/bash
        groups: users
      - name: tester
        shell: /bin/bash
        groups: users
    
    packages_to_install:
      - git
      - tree
      - htop
      - ncdu
    
    directories_to_create:
      - /opt/applications
      - /opt/scripts
      - /opt/logs
  
  tasks:
    - name: Create multiple users
      user:
        name: "{{ item.name }}"
        shell: "{{ item.shell }}"
        groups: "{{ item.groups }}"
        create_home: yes
      loop: "{{ users_to_create }}"
      tags: users
    
    - name: Install multiple packages
      yum:
        name: "{{ packages_to_install }}"
        state: present
      tags: packages
    
    - name: Create multiple directories
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
        owner: root
        group: root
      loop: "{{ directories_to_create }}"
      tags: directories
    
    - name: Set custom facts
      set_fact:
        deployment_time: "{{ ansible_date_time.epoch }}"
        server_role: "web_server"
    
    - name: Display custom facts
      debug:
        msg: |
          Server {{ inventory_hostname }} configured as {{ server_role }}
          Deployment timestamp: {{ deployment_time }}
EOF
Execute the loop demonstration playbook:
ansible-playbook -i inventory loop-variables-demo.yml
Advanced Playbook Features
Error Handling and Recovery
Create a playbook with error handling:
cat > error-handling.yml << 'EOF'
---
- name: Demonstrate Error Handling
  hosts: managed1
  become: yes
  
  tasks:
    - name: Attempt to install non-existent package
      yum:
        name: non-existent-package
        state: present
      ignore_errors: yes
      register: package_result
    
    - name: Display error message
      debug:
        msg: "Package installation failed: {{ package_result.msg }}"
      when: package_result.failed
    
    - name: Ensure service is running (with retry)
      systemd:
        name: httpd
        state: started
      retries: 3
      delay: 5
      register: service_result
      until: service_result is succeeded
    
    - name: Fail playbook if critical condition not met
      fail:
        msg: "Critical service is not running"
      when: service_result.failed
EOF
Using Templates
Create a Jinja2 template for Apache configuration:
mkdir -p templates

cat > templates/httpd.conf.j2 << 'EOF'
# Apache Configuration - Managed by Ansible
ServerRoot /etc/httpd
Listen {{ ansible_default_ipv4.address }}:80

# Server Information
ServerName {{ inventory_hostname }}
ServerAdmin admin@{{ inventory_hostname }}

# Document Root
DocumentRoot {{ document_root | default('/var/www/html') }}

# Directory Configuration
<Directory "{{ document_root | default('/var/www/html') }}">
    AllowOverride None
    Require all granted
</Directory>

# Logging
ErrorLog logs/error_log
CustomLog logs/access_log combined

# Load Modules
LoadModule dir_module modules/mod_dir.so
LoadModule mime_module modules/mod_mime.so
LoadModule rewrite_module modules/mod_rewrite.so

# MIME Types
TypesConfig /etc/mime.types
DirectoryIndex index.html
EOF
Create a playbook using the template:
cat > template-demo.yml << 'EOF'
---
- name: Deploy Configuration Using Templates
  hosts: managed1
  become: yes
  vars:
    document_root: /var/www/html
  
  tasks:
    - name: Deploy Apache configuration from template
      template:
        src: templates/httpd.conf.j2
        dest: /etc/httpd/conf/httpd.conf
        owner: root
        group: root
        mode: '0644'
        backup: yes
      notify:
        - restart apache
    
    - name: Ensure Apache is running
      systemd:
        name: httpd
        state: started
        enabled: yes
  
  handlers:
    - name: restart apache
      systemd:
        name: httpd
        state: restarted
EOF
Troubleshooting Common Issues
Issue 1: Syntax Errors
Problem: YAML syntax errors in playbooks

Solution:

# Always check syntax before running
ansible-playbook --syntax-check your-playbook.yml

# Use proper YAML indentation (spaces, not tabs)
# Ensure proper list and dictionary formatting
Issue 2: Connection Problems
Problem: Cannot connect to managed hosts

Solution:

# Test connectivity
ansible all -m ping

# Check SSH configuration
ansible all -m setup --limit managed1

# Verify inventory file
ansible-inventory --list
Issue 3: Permission Denied
Problem: Tasks fail due to insufficient permissions

Solution:

# Use become for privilege escalation
ansible-playbook playbook.yml --become

# Check sudo configuration on managed hosts
ansible all -m shell -a "sudo -l" --become
Issue 4: Module Not Found
Problem: Ansible module not available

Solution:

# Check available modules
ansible-doc -l | grep module_name

# Verify Ansible version
ansible --version

# Install required collections
ansible-galaxy collection install community.general
Best Practices for Playbook Development
1. Playbook Organization
# Create a structured project layout
mkdir -p ansible-project/{playbooks,roles,inventory,group_vars,host_vars}

# Use descriptive names
# Good: deploy-webserver.yml
# Bad: playbook1.yml
2. Variable Management
# Create group variables
cat > group_vars/webservers.yml << 'EOF'
web_package: httpd
web_service: httpd
document_root: /var/www/html
EOF

# Create host-specific variables
cat > host_vars/managed1.yml << 'EOF'
server_id: web01
custom_port: 8080
EOF
3. Using Vault for Sensitive Data
# Create encrypted variables
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Run playbook with vault
ansible-playbook playbook.yml --ask-vault-pass
Verification and Testing
Test Your Playbooks
Verify all services are running:
ansible all -m systemd -a "name=httpd" --become
Check web server response:
ansible all -m uri -a "url=http://{{ inventory_hostname }} method=GET"
Validate configuration files:
ansible all -m shell -a "httpd -t" --become
Generate a summary report:
cat > generate-report.yml << 'EOF'
---
- name: Generate System Report
  hosts: all
  gather_facts: yes
  
  tasks:
    - name: Collect system information
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          IP: {{ ansible_default_ipv4.address }}
          Uptime: {{ ansible_uptime_seconds }} seconds
          Memory: {{ ansible_memtotal_mb }} MB
EOF
ansible-playbook -i inventory generate-report.yml
Conclusion
In this comprehensive lab, you have successfully:

Created basic Ansible playbooks with proper YAML syntax and structure
Executed playbooks using various ansible-playbook command options and flags
Developed advanced playbooks incorporating multiple tasks, variables, loops, and conditional logic
Implemented error handling and recovery mechanisms in your automation
Used templates to generate dynamic configuration files
Applied best practices for playbook organization and variable management
Troubleshot common issues that arise during playbook development and execution
Why This Matters: Ansible playbooks are the foundation of infrastructure automation and configuration management. The skills you've developed enable you to:

Automate repetitive tasks across multiple systems simultaneously
Ensure consistent configuration across your infrastructure
Reduce human error through codified processes
Scale operations efficiently as your infrastructure grows
Maintain compliance through repeatable, auditable processes
These playbook writing skills are essential for the Red Hat Certified Specialist in Ansible Network Automation exam and are directly applicable to real-world DevOps and system administration scenarios. You can now confidently create, modify, and execute Ansible playbooks to automate complex multi-step processes across your infrastructure.

The techniques learned in this lab form the building blocks for more advanced Ansible concepts including roles, collections, and enterprise automation frameworks. Continue practicing by creating playbooks for your specific use cases and gradually incorporating more advanced features as your automation requirements grow.
