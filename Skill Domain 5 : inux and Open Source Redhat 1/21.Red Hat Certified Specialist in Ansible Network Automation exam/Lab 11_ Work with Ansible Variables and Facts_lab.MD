Lab 11: Work with Ansible Variables and Facts
Objectives
By the end of this lab, you will be able to:

Understand and utilize Ansible facts to gather system information automatically
Create and manage variables for dynamic configuration management
Implement variables and facts in playbooks to create flexible automation solutions
Apply conditional logic based on system facts
Use variable precedence and scoping effectively
Create reusable playbooks that adapt to different environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Completion of previous Ansible labs or equivalent knowledge
Understanding of basic Ansible concepts (playbooks, tasks, modules)
Knowledge of text editors (vim, nano, or similar)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own VM or install software - everything is ready to use!

Your lab environment includes:

Control node with Ansible pre-installed
Two managed nodes (target servers)
All necessary network connectivity configured
Sample files and directories prepared
Task 1: Use ansible_facts to Gather System Information
Subtask 1.1: Understanding Ansible Facts
Ansible facts are system properties that Ansible automatically discovers about managed hosts. These facts include information like operating system, network interfaces, memory, and much more.

Step 1: Connect to your control node and verify Ansible installation

ansible --version
Step 2: Check your inventory file to see available hosts

cat /etc/ansible/hosts
Step 3: Gather facts from all managed hosts using the setup module

ansible all -m setup
This command will display extensive information about each host. The output might be overwhelming, so let's filter it.

Subtask 1.2: Filtering and Using Specific Facts
Step 4: Gather only network-related facts

ansible all -m setup -a "filter=ansible_default_ipv4"
Step 5: Get memory information from all hosts

ansible all -m setup -a "filter=ansible_memtotal_mb"
Step 6: Create a playbook to display useful system facts

Create a new file called system_facts.yml:

nano system_facts.yml
Add the following content:

---
- name: Display System Facts
  hosts: all
  gather_facts: yes
  tasks:
    - name: Show hostname
      debug:
        msg: "Hostname: {{ ansible_hostname }}"
    
    - name: Show operating system
      debug:
        msg: "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
    
    - name: Show IP address
      debug:
        msg: "IP Address: {{ ansible_default_ipv4.address }}"
    
    - name: Show total memory
      debug:
        msg: "Total Memory: {{ ansible_memtotal_mb }} MB"
    
    - name: Show CPU information
      debug:
        msg: "CPU Cores: {{ ansible_processor_cores }}"
Step 7: Run the playbook to see system facts

ansible-playbook system_facts.yml
Subtask 1.3: Using Facts for Conditional Tasks
Step 8: Create a playbook that performs different actions based on the operating system

Create conditional_facts.yml:

nano conditional_facts.yml
---
- name: Conditional Tasks Based on Facts
  hosts: all
  gather_facts: yes
  tasks:
    - name: Install package on Ubuntu/Debian
      apt:
        name: htop
        state: present
      when: ansible_os_family == "Debian"
      become: yes
    
    - name: Install package on RedHat/CentOS
      yum:
        name: htop
        state: present
      when: ansible_os_family == "RedHat"
      become: yes
    
    - name: Display different message for low memory systems
      debug:
        msg: "Warning: This system has low memory ({{ ansible_memtotal_mb }} MB)"
      when: ansible_memtotal_mb < 2048
    
    - name: Display message for high memory systems
      debug:
        msg: "Good: This system has sufficient memory ({{ ansible_memtotal_mb }} MB)"
      when: ansible_memtotal_mb >= 2048
Step 9: Execute the conditional playbook

ansible-playbook conditional_facts.yml
Task 2: Create Variables for Configuration
Subtask 2.1: Defining Variables in Playbooks
Variables in Ansible allow you to store values that can be reused throughout your playbooks, making them more flexible and maintainable.

Step 10: Create a playbook with inline variables

Create variables_basic.yml:

nano variables_basic.yml
---
- name: Basic Variables Example
  hosts: all
  vars:
    web_server_port: 8080
    web_server_name: "MyWebServer"
    admin_email: "admin@example.com"
    packages_to_install:
      - nginx
      - curl
      - wget
  
  tasks:
    - name: Display web server configuration
      debug:
        msg: |
          Server Name: {{ web_server_name }}
          Port: {{ web_server_port }}
          Admin Email: {{ admin_email }}
    
    - name: Show packages to install
      debug:
        msg: "Package: {{ item }}"
      loop: "{{ packages_to_install }}"
Step 11: Run the basic variables playbook

ansible-playbook variables_basic.yml
Subtask 2.2: Using External Variable Files
Step 12: Create a separate variables file

Create vars/web_config.yml:

mkdir -p vars
nano vars/web_config.yml
---
# Web server configuration variables
web_server:
  name: "ProductionWebServer"
  port: 80
  ssl_port: 443
  document_root: "/var/www/html"
  
database:
  host: "db.example.com"
  port: 3306
  name: "webapp_db"
  user: "webapp_user"

application:
  version: "2.1.0"
  environment: "production"
  debug_mode: false
Step 13: Create a playbook that uses external variables

Create external_vars.yml:

nano external_vars.yml
---
- name: Using External Variables
  hosts: all
  vars_files:
    - vars/web_config.yml
  
  tasks:
    - name: Display web server configuration
      debug:
        msg: |
          Web Server: {{ web_server.name }}
          HTTP Port: {{ web_server.port }}
          HTTPS Port: {{ web_server.ssl_port }}
          Document Root: {{ web_server.document_root }}
    
    - name: Display database configuration
      debug:
        msg: |
          Database Host: {{ database.host }}
          Database Port: {{ database.port }}
          Database Name: {{ database.name }}
    
    - name: Display application info
      debug:
        msg: |
          App Version: {{ application.version }}
          Environment: {{ application.environment }}
          Debug Mode: {{ application.debug_mode }}
Step 14: Execute the playbook with external variables

ansible-playbook external_vars.yml
Subtask 2.3: Host and Group Variables
Step 15: Create host-specific variables

Create directories for host and group variables:

mkdir -p host_vars group_vars
Create host-specific variables (replace hostname1 with your actual host name):

nano host_vars/hostname1.yml
---
server_role: "web"
max_connections: 100
backup_enabled: true
Step 16: Create group variables

nano group_vars/all.yml
---
company_name: "TechCorp"
support_email: "support@techcorp.com"
timezone: "UTC"
log_level: "info"
Step 17: Create a playbook to demonstrate variable precedence

Create variable_precedence.yml:

nano variable_precedence.yml
---
- name: Variable Precedence Demo
  hosts: all
  vars:
    log_level: "debug"  # This will override group_vars
  
  tasks:
    - name: Show company information
      debug:
        msg: |
          Company: {{ company_name }}
          Support Email: {{ support_email }}
          Timezone: {{ timezone }}
    
    - name: Show log level (demonstrating precedence)
      debug:
        msg: "Log Level: {{ log_level }}"
    
    - name: Show host-specific variables
      debug:
        msg: |
          Server Role: {{ server_role | default('undefined') }}
          Max Connections: {{ max_connections | default('undefined') }}
          Backup Enabled: {{ backup_enabled | default('undefined') }}
Step 18: Run the variable precedence demonstration

ansible-playbook variable_precedence.yml
Task 3: Use Variables and Facts in Playbooks
Subtask 3.1: Combining Variables and Facts
Step 19: Create a comprehensive playbook that combines variables and facts

Create combined_vars_facts.yml:

nano combined_vars_facts.yml
---
- name: Combined Variables and Facts
  hosts: all
  gather_facts: yes
  vars:
    service_name: "myapp"
    config_dir: "/etc/{{ service_name }}"
    log_dir: "/var/log/{{ service_name }}"
    
  tasks:
    - name: Create configuration directory
      file:
        path: "{{ config_dir }}"
        state: directory
        mode: '0755'
      become: yes
    
    - name: Create log directory
      file:
        path: "{{ log_dir }}"
        state: directory
        mode: '0755'
      become: yes
    
    - name: Generate configuration file using facts and variables
      copy:
        content: |
          # {{ service_name }} Configuration File
          # Generated on {{ ansible_date_time.iso8601 }}
          
          [server]
          hostname = {{ ansible_hostname }}
          ip_address = {{ ansible_default_ipv4.address }}
          port = 8080
          
          [system]
          os = {{ ansible_distribution }} {{ ansible_distribution_version }}
          architecture = {{ ansible_architecture }}
          total_memory = {{ ansible_memtotal_mb }}MB
          cpu_cores = {{ ansible_processor_cores }}
          
          [application]
          service_name = {{ service_name }}
          config_dir = {{ config_dir }}
          log_dir = {{ log_dir }}
          environment = production
        dest: "{{ config_dir }}/{{ service_name }}.conf"
        mode: '0644'
      become: yes
    
    - name: Display configuration file location
      debug:
        msg: "Configuration file created at: {{ config_dir }}/{{ service_name }}.conf"
Step 20: Execute the combined playbook

ansible-playbook combined_vars_facts.yml
Subtask 3.2: Dynamic Variable Assignment
Step 21: Create a playbook with dynamic variable assignment based on facts

Create dynamic_variables.yml:

nano dynamic_variables.yml
---
- name: Dynamic Variable Assignment
  hosts: all
  gather_facts: yes
  vars:
    memory_threshold: 4096
    
  tasks:
    - name: Set performance profile based on memory
      set_fact:
        performance_profile: "{{ 'high' if ansible_memtotal_mb > memory_threshold else 'standard' }}"
    
    - name: Set worker processes based on CPU cores
      set_fact:
        worker_processes: "{{ ansible_processor_cores * 2 }}"
    
    - name: Set cache size based on available memory
      set_fact:
        cache_size: "{{ (ansible_memtotal_mb * 0.1) | int }}m"
    
    - name: Display dynamic configuration
      debug:
        msg: |
          Performance Profile: {{ performance_profile }}
          Worker Processes: {{ worker_processes }}
          Cache Size: {{ cache_size }}
          Based on: {{ ansible_processor_cores }} CPU cores, {{ ansible_memtotal_mb }}MB RAM
    
    - name: Create optimized configuration
      copy:
        content: |
          # Dynamically Generated Configuration
          # Host: {{ ansible_hostname }}
          # Generated: {{ ansible_date_time.iso8601 }}
          
          performance_profile={{ performance_profile }}
          worker_processes={{ worker_processes }}
          cache_size={{ cache_size }}
          
          # System Information
          cpu_cores={{ ansible_processor_cores }}
          total_memory={{ ansible_memtotal_mb }}MB
          os={{ ansible_distribution }}
        dest: "/tmp/dynamic_config.conf"
        mode: '0644'
      become: yes
Step 22: Run the dynamic variables playbook

ansible-playbook dynamic_variables.yml
Subtask 3.3: Advanced Variable Manipulation
Step 23: Create a playbook demonstrating advanced variable techniques

Create advanced_variables.yml:

nano advanced_variables.yml
---
- name: Advanced Variable Techniques
  hosts: all
  gather_facts: yes
  vars:
    users:
      - name: "alice"
        role: "admin"
        shell: "/bin/bash"
      - name: "bob"
        role: "user"
        shell: "/bin/sh"
    
    default_packages:
      - vim
      - curl
      - wget
    
    os_specific_packages:
      Debian:
        - apt-transport-https
        - software-properties-common
      RedHat:
        - epel-release
        - yum-utils
  
  tasks:
    - name: Combine default and OS-specific packages
      set_fact:
        all_packages: "{{ default_packages + os_specific_packages[ansible_os_family] | default([]) }}"
    
    - name: Display package list
      debug:
        msg: "Packages to install: {{ all_packages }}"
    
    - name: Create user accounts with variables
      debug:
        msg: |
          Creating user: {{ item.name }}
          Role: {{ item.role }}
          Shell: {{ item.shell }}
      loop: "{{ users }}"
    
    - name: Generate system report using facts and variables
      template:
        content: |
          # System Report for {{ ansible_hostname }}
          # Generated on {{ ansible_date_time.iso8601 }}
          
          ## System Information
          Hostname: {{ ansible_hostname }}
          FQDN: {{ ansible_fqdn }}
          Operating System: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Kernel: {{ ansible_kernel }}
          Architecture: {{ ansible_architecture }}
          
          ## Hardware Information
          CPU Model: {{ ansible_processor[2] | default('Unknown') }}
          CPU Cores: {{ ansible_processor_cores }}
          Total Memory: {{ ansible_memtotal_mb }} MB
          
          ## Network Information
          Primary IP: {{ ansible_default_ipv4.address }}
          Gateway: {{ ansible_default_ipv4.gateway }}
          
          ## Configured Users
          {% for user in users %}
          - {{ user.name }} ({{ user.role }})
          {% endfor %}
          
          ## Packages to Install
          {% for package in all_packages %}
          - {{ package }}
          {% endfor %}
        dest: "/tmp/system_report_{{ ansible_hostname }}.txt"
        mode: '0644'
      become: yes
    
    - name: Display report location
      debug:
        msg: "System report created: /tmp/system_report_{{ ansible_hostname }}.txt"
Step 24: Execute the advanced variables playbook

ansible-playbook advanced_variables.yml
Step 25: Verify the generated files

ansible all -m shell -a "ls -la /tmp/system_report_*.txt" -b
ansible all -m shell -a "head -20 /tmp/system_report_*.txt" -b
Subtask 3.4: Variable Validation and Error Handling
Step 26: Create a playbook with variable validation

Create variable_validation.yml:

nano variable_validation.yml
---
- name: Variable Validation and Error Handling
  hosts: all
  gather_facts: yes
  vars:
    required_memory: 1024
    required_disk_space: 10  # GB
    
  tasks:
    - name: Validate minimum memory requirement
      fail:
        msg: "Insufficient memory: {{ ansible_memtotal_mb }}MB available, {{ required_memory }}MB required"
      when: ansible_memtotal_mb < required_memory
    
    - name: Check if required variables are defined
      fail:
        msg: "Variable {{ item }} is not defined"
      when: vars[item] is not defined
      loop:
        - required_memory
        - required_disk_space
    
    - name: Display validation success
      debug:
        msg: |
          Validation passed:
          - Memory: {{ ansible_memtotal_mb }}MB (required: {{ required_memory }}MB)
          - Host meets requirements
    
    - name: Use default values for undefined variables
      debug:
        msg: |
          Service Port: {{ service_port | default(8080) }}
          Debug Mode: {{ debug_mode | default(false) }}
          Max Connections: {{ max_connections | default(100) }}
Step 27: Run the validation playbook

ansible-playbook variable_validation.yml
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Variables not being recognized

Solution: Check variable spelling and ensure proper YAML indentation
Command to debug: ansible-playbook playbook.yml --check -v
Issue 2: Facts not gathering correctly

Solution: Ensure gather_facts: yes is set in your playbook
Command to test: ansible hostname -m setup
Issue 3: Variable precedence confusion

Solution: Use ansible-playbook playbook.yml -v to see which variables are being used
Issue 4: Template or file creation failures

Solution: Check file permissions and ensure the target directory exists
Command to verify: ansible all -m shell -a "ls -la /path/to/file" -b
Debugging Commands
# Check variable values
ansible-playbook playbook.yml --extra-vars "debug=true" -v

# List all facts for a host
ansible hostname -m setup | grep ansible_

# Test connectivity
ansible all -m ping

# Check syntax
ansible-playbook playbook.yml --syntax-check
Conclusion
In this comprehensive lab, you have successfully learned to work with Ansible variables and facts. Here's what you accomplished:

Key Achievements
Mastered Ansible Facts: You learned how to gather, filter, and use system facts to make your playbooks intelligent and adaptive to different environments.

Variable Management: You created and managed variables using multiple methods including inline variables, external files, host variables, and group variables.

Dynamic Configuration: You built playbooks that dynamically adjust their behavior based on system characteristics, creating truly flexible automation solutions.

Advanced Techniques: You implemented variable validation, error handling, and complex variable manipulation techniques that are essential for production environments.

Why This Matters
Understanding variables and facts is crucial for creating maintainable, scalable Ansible automation because:

Flexibility: Your playbooks can adapt to different environments without code changes
Reusability: Variables make your code modular and reusable across different projects
Intelligence: Facts allow your automation to make smart decisions based on target system characteristics
Maintainability: Proper variable management makes your automation easier to update and maintain
Next Steps
With these skills, you're now prepared to:

Create complex, environment-aware automation solutions
Build reusable playbooks for diverse infrastructure
Implement configuration management that scales across different systems
Prepare for advanced Ansible certifications like the Red Hat Certified Specialist in Ansible Network Automation exam
The combination of variables and facts forms the foundation of professional Ansible automation, enabling you to create sophisticated infrastructure-as-code solutions that adapt intelligently to your environment's needs.
