Lab 16: Validating Configuration with Ansible Facts
Objectives
By the end of this lab, you will be able to:

• Understand what Ansible facts are and how they are collected • Use the setup module to gather comprehensive system information • Write conditional statements to validate system configurations • Create playbooks that ensure systems are in desired states using facts • Implement configuration validation checks across multiple environments • Troubleshoot configuration drift using fact-based validation

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Linux command line operations • Familiarity with YAML syntax and structure • Previous experience with Ansible playbooks and modules • Understanding of conditional statements in programming • Knowledge of system administration concepts (services, packages, users)

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes: • Control Node: CentOS/RHEL 8 with Ansible pre-installed • Managed Nodes: 2-3 target systems for configuration validation • All necessary networking and SSH key configurations completed

Task 1: Understanding and Gathering Ansible Facts
Subtask 1.1: Explore the Setup Module
The setup module is Ansible's fact-gathering engine that collects detailed information about target systems.

Connect to your control node and navigate to the working directory:
cd /home/student/ansible-labs
mkdir lab16-facts-validation
cd lab16-facts-validation
Create an inventory file to define your managed nodes:
cat > inventory << EOF
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[databases]
node3 ansible_host=192.168.1.12

[all:vars]
ansible_user=student
ansible_ssh_private_key_file=/home/student/.ssh/id_rsa
EOF
Test connectivity to all managed nodes:
ansible all -i inventory -m ping
Gather facts from a single host to understand the data structure:
ansible node1 -i inventory -m setup
Subtask 1.2: Filter and Examine Specific Facts
Gather only network-related facts:
ansible node1 -i inventory -m setup -a "filter=ansible_default_ipv4"
Examine memory information:
ansible node1 -i inventory -m setup -a "filter=ansible_memory_mb"
Check operating system details:
ansible node1 -i inventory -m setup -a "filter=ansible_distribution*"
Create a fact-gathering playbook to save output for analysis:
cat > gather-facts.yml << EOF
---
- name: Comprehensive Fact Gathering
  hosts: all
  gather_facts: yes
  tasks:
    - name: Display hostname and IP address
      debug:
        msg: "Host {{ ansible_hostname }} has IP {{ ansible_default_ipv4.address }}"
    
    - name: Show OS information
      debug:
        msg: "Running {{ ansible_distribution }} {{ ansible_distribution_version }}"
    
    - name: Display memory information
      debug:
        msg: "Total memory: {{ ansible_memory_mb.real.total }}MB, Available: {{ ansible_memory_mb.real.free }}MB"
    
    - name: Save facts to file
      copy:
        content: "{{ ansible_facts | to_nice_json }}"
        dest: "/tmp/{{ ansible_hostname }}_facts.json"
EOF
Execute the fact-gathering playbook:
ansible-playbook -i inventory gather-facts.yml
Task 2: Writing Conditional Statements for Configuration Validation
Subtask 2.1: Create Basic Validation Conditions
Create a validation playbook with basic conditional checks:
cat > basic-validation.yml << EOF
---
- name: Basic System Validation
  hosts: all
  gather_facts: yes
  tasks:
    - name: Validate minimum memory requirement
      assert:
        that:
          - ansible_memory_mb.real.total >= 1024
        fail_msg: "System has insufficient memory: {{ ansible_memory_mb.real.total }}MB (minimum 1024MB required)"
        success_msg: "Memory requirement satisfied: {{ ansible_memory_mb.real.total }}MB"
    
    - name: Validate supported operating system
      assert:
        that:
          - ansible_distribution in ['CentOS', 'RedHat', 'Ubuntu', 'Debian']
        fail_msg: "Unsupported OS: {{ ansible_distribution }}"
        success_msg: "Supported OS detected: {{ ansible_distribution }}"
    
    - name: Check if system is 64-bit
      assert:
        that:
          - ansible_architecture == "x86_64"
        fail_msg: "32-bit architecture not supported: {{ ansible_architecture }}"
        success_msg: "64-bit architecture confirmed: {{ ansible_architecture }}"
    
    - name: Validate network connectivity
      assert:
        that:
          - ansible_default_ipv4.address is defined
        fail_msg: "No default IPv4 address found"
        success_msg: "Network configured with IP: {{ ansible_default_ipv4.address }}"
EOF
Run the basic validation:
ansible-playbook -i inventory basic-validation.yml
Subtask 2.2: Advanced Conditional Validation
Create advanced validation with multiple conditions:
cat > advanced-validation.yml << EOF
---
- name: Advanced Configuration Validation
  hosts: all
  gather_facts: yes
  vars:
    required_packages:
      - httpd
      - firewalld
    required_services:
      - httpd
      - firewalld
    min_disk_space_gb: 10
  
  tasks:
    - name: Gather package facts
      package_facts:
        manager: auto
    
    - name: Gather service facts
      service_facts:
    
    - name: Validate required packages are installed
      assert:
        that:
          - item in ansible_facts.packages
        fail_msg: "Required package {{ item }} is not installed"
        success_msg: "Package {{ item }} is installed"
      loop: "{{ required_packages }}"
      when: ansible_os_family == "RedHat"
    
    - name: Validate critical services are running
      assert:
        that:
          - ansible_facts.services[item + '.service'].state == 'running'
        fail_msg: "Service {{ item }} is not running"
        success_msg: "Service {{ item }} is running"
      loop: "{{ required_services }}"
      when: 
        - ansible_os_family == "RedHat"
        - item + '.service' in ansible_facts.services
    
    - name: Check available disk space
      assert:
        that:
          - (ansible_mounts | selectattr('mount', 'equalto', '/') | first).size_available > (min_disk_space_gb * 1024 * 1024 * 1024)
        fail_msg: "Insufficient disk space on root filesystem"
        success_msg: "Adequate disk space available"
    
    - name: Validate firewall configuration
      assert:
        that:
          - ansible_facts.services['firewalld.service'].state == 'running'
        fail_msg: "Firewall service is not running"
        success_msg: "Firewall service is active"
      when: "'firewalld.service' in ansible_facts.services"
EOF
Execute the advanced validation:
ansible-playbook -i inventory advanced-validation.yml
Task 3: Creating Comprehensive State Validation Playbooks
Subtask 3.1: Web Server Configuration Validation
Create a web server validation playbook:
cat > webserver-validation.yml << EOF
---
- name: Web Server Configuration Validation
  hosts: webservers
  gather_facts: yes
  become: yes
  vars:
    web_packages:
      - httpd
      - mod_ssl
    web_services:
      - httpd
    required_ports:
      - 80
      - 443
    document_root: "/var/www/html"
    config_file: "/etc/httpd/conf/httpd.conf"
  
  tasks:
    - name: Ensure web packages are installed
      package:
        name: "{{ web_packages }}"
        state: present
      register: package_result
    
    - name: Gather updated package facts
      package_facts:
        manager: auto
    
    - name: Validate web packages installation
      assert:
        that:
          - item in ansible_facts.packages
        fail_msg: "Web package {{ item }} failed to install"
        success_msg: "Web package {{ item }} is properly installed"
      loop: "{{ web_packages }}"
    
    - name: Start and enable web services
      service:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop: "{{ web_services }}"
    
    - name: Gather service facts
      service_facts:
    
    - name: Validate web services are running
      assert:
        that:
          - ansible_facts.services[item + '.service'].state == 'running'
          - ansible_facts.services[item + '.service'].status == 'enabled'
        fail_msg: "Web service {{ item }} is not properly configured"
        success_msg: "Web service {{ item }} is running and enabled"
      loop: "{{ web_services }}"
    
    - name: Check if document root exists
      stat:
        path: "{{ document_root }}"
      register: docroot_stat
    
    - name: Validate document root directory
      assert:
        that:
          - docroot_stat.stat.exists
          - docroot_stat.stat.isdir
        fail_msg: "Document root {{ document_root }} is not properly configured"
        success_msg: "Document root {{ document_root }} exists and is accessible"
    
    - name: Create test index file
      copy:
        content: |
          <html>
          <head><title>Test Page</title></head>
          <body>
          <h1>Server: {{ ansible_hostname }}</h1>
          <p>IP Address: {{ ansible_default_ipv4.address }}</p>
          <p>OS: {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
          </body>
          </html>
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
    
    - name: Validate configuration file exists
      stat:
        path: "{{ config_file }}"
      register: config_stat
    
    - name: Assert configuration file is present
      assert:
        that:
          - config_stat.stat.exists
        fail_msg: "Apache configuration file missing: {{ config_file }}"
        success_msg: "Apache configuration file found: {{ config_file }}"
    
    - name: Test web server response
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      register: web_response
      ignore_errors: yes
    
    - name: Validate web server is responding
      assert:
        that:
          - web_response.status == 200
        fail_msg: "Web server is not responding properly"
        success_msg: "Web server is responding correctly"
      when: web_response is defined
EOF
Execute the web server validation:
ansible-playbook -i inventory webserver-validation.yml
Subtask 3.2: Database Server Validation
Create a database server validation playbook:
cat > database-validation.yml << EOF
---
- name: Database Server Configuration Validation
  hosts: databases
  gather_facts: yes
  become: yes
  vars:
    db_packages:
      - mariadb-server
      - mariadb
    db_service: mariadb
    db_port: 3306
    db_config_file: "/etc/my.cnf"
    db_data_dir: "/var/lib/mysql"
  
  tasks:
    - name: Install database packages
      package:
        name: "{{ db_packages }}"
        state: present
    
    - name: Start and enable database service
      service:
        name: "{{ db_service }}"
        state: started
        enabled: yes
    
    - name: Gather updated facts
      setup:
    
    - name: Gather package facts
      package_facts:
        manager: auto
    
    - name: Gather service facts
      service_facts:
    
    - name: Validate database packages are installed
      assert:
        that:
          - item in ansible_facts.packages
        fail_msg: "Database package {{ item }} is not installed"
        success_msg: "Database package {{ item }} is installed"
      loop: "{{ db_packages }}"
    
    - name: Validate database service is running
      assert:
        that:
          - ansible_facts.services[db_service + '.service'].state == 'running'
          - ansible_facts.services[db_service + '.service'].status == 'enabled'
        fail_msg: "Database service {{ db_service }} is not properly configured"
        success_msg: "Database service {{ db_service }} is running and enabled"
    
    - name: Check if database is listening on correct port
      wait_for:
        port: "{{ db_port }}"
        host: "{{ ansible_default_ipv4.address }}"
        timeout: 10
      register: port_check
      ignore_errors: yes
    
    - name: Validate database port accessibility
      assert:
        that:
          - port_check is succeeded
        fail_msg: "Database is not listening on port {{ db_port }}"
        success_msg: "Database is listening on port {{ db_port }}"
    
    - name: Check database data directory
      stat:
        path: "{{ db_data_dir }}"
      register: data_dir_stat
    
    - name: Validate database data directory
      assert:
        that:
          - data_dir_stat.stat.exists
          - data_dir_stat.stat.isdir
        fail_msg: "Database data directory {{ db_data_dir }} is not properly configured"
        success_msg: "Database data directory {{ db_data_dir }} exists"
    
    - name: Test database connectivity
      command: mysql -e "SELECT 1"
      register: db_test
      ignore_errors: yes
      changed_when: false
    
    - name: Validate database connectivity
      assert:
        that:
          - db_test.rc == 0
        fail_msg: "Cannot connect to database"
        success_msg: "Database connectivity test passed"
      when: db_test is defined
EOF
Run the database validation:
ansible-playbook -i inventory database-validation.yml
Subtask 3.3: Comprehensive System State Validation
Create a comprehensive validation playbook:
cat > comprehensive-validation.yml << EOF
---
- name: Comprehensive System State Validation
  hosts: all
  gather_facts: yes
  become: yes
  vars:
    security_requirements:
      min_password_length: 8
      max_login_attempts: 3
    performance_thresholds:
      max_cpu_usage: 80
      max_memory_usage: 85
      min_disk_free_percent: 15
    compliance_checks:
      selinux_enabled: true
      firewall_active: true
  
  tasks:
    - name: Gather all system facts
      setup:
        gather_subset: all
    
    - name: Gather package and service facts
      package_facts:
        manager: auto
    
    - name: Gather service facts
      service_facts:
    
    - name: Create validation report directory
      file:
        path: "/tmp/validation_reports"
        state: directory
        mode: '0755'
    
    - name: System Resource Validation
      block:
        - name: Check CPU usage
          shell: top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
          register: cpu_usage
          changed_when: false
        
        - name: Validate CPU usage is within limits
          assert:
            that:
              - cpu_usage.stdout | float < performance_thresholds.max_cpu_usage
            fail_msg: "CPU usage too high: {{ cpu_usage.stdout }}%"
            success_msg: "CPU usage acceptable: {{ cpu_usage.stdout }}%"
          when: cpu_usage.stdout is defined
        
        - name: Calculate memory usage percentage
          set_fact:
            memory_usage_percent: "{{ ((ansible_memory_mb.real.total - ansible_memory_mb.real.free) / ansible_memory_mb.real.total * 100) | round(2) }}"
        
        - name: Validate memory usage
          assert:
            that:
              - memory_usage_percent | float < performance_thresholds.max_memory_usage
            fail_msg: "Memory usage too high: {{ memory_usage_percent }}%"
            success_msg: "Memory usage acceptable: {{ memory_usage_percent }}%"
        
        - name: Check disk space usage
          set_fact:
            root_disk_usage: "{{ ((ansible_mounts | selectattr('mount', 'equalto', '/') | first).size_total - (ansible_mounts | selectattr('mount', 'equalto', '/') | first).size_available) / (ansible_mounts | selectattr('mount', 'equalto', '/') | first).size_total * 100 }}"
        
        - name: Validate disk space usage
          assert:
            that:
              - (100 - root_disk_usage | float) > performance_thresholds.min_disk_free_percent
            fail_msg: "Insufficient disk space: {{ 100 - root_disk_usage | float }}% free"
            success_msg: "Adequate disk space: {{ 100 - root_disk_usage | float }}% free"
    
    - name: Security Configuration Validation
      block:
        - name: Check SELinux status
          command: getenforce
          register: selinux_status
          changed_when: false
          ignore_errors: yes
        
        - name: Validate SELinux configuration
          assert:
            that:
              - selinux_status.stdout == "Enforcing"
            fail_msg: "SELinux is not enforcing: {{ selinux_status.stdout }}"
            success_msg: "SELinux is properly enforcing"
          when: 
            - compliance_checks.selinux_enabled
            - selinux_status is succeeded
        
        - name: Validate firewall service
          assert:
            that:
              - "'firewalld.service' in ansible_facts.services"
              - ansible_facts.services['firewalld.service'].state == 'running'
            fail_msg: "Firewall service is not active"
            success_msg: "Firewall service is running"
          when: compliance_checks.firewall_active
    
    - name: Generate validation report
      template:
        src: validation_report.j2
        dest: "/tmp/validation_reports/{{ ansible_hostname }}_validation_report.txt"
      vars:
        validation_timestamp: "{{ ansible_date_time.iso8601 }}"
        system_info:
          hostname: "{{ ansible_hostname }}"
          ip_address: "{{ ansible_default_ipv4.address }}"
          os: "{{ ansible_distribution }} {{ ansible_distribution_version }}"
          kernel: "{{ ansible_kernel }}"
          architecture: "{{ ansible_architecture }}"
          memory_total: "{{ ansible_memory_mb.real.total }}MB"
          memory_usage: "{{ memory_usage_percent }}%"
          cpu_count: "{{ ansible_processor_vcpus }}"
          uptime: "{{ ansible_uptime_seconds // 3600 }} hours"
    
    - name: Display validation summary
      debug:
        msg: |
          Validation Summary for {{ ansible_hostname }}:
          - OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          - Memory: {{ ansible_memory_mb.real.total }}MB ({{ memory_usage_percent }}% used)
          - Disk: {{ 100 - root_disk_usage | float }}% free space
          - Services: {{ ansible_facts.services | length }} total services
          - Packages: {{ ansible_facts.packages | length }} installed packages
          - Validation completed at: {{ ansible_date_time.iso8601 }}
EOF
Create the validation report template:
mkdir -p templates
cat > templates/validation_report.j2 << EOF
SYSTEM VALIDATION REPORT
========================
Generated: {{ validation_timestamp }}

SYSTEM INFORMATION
------------------
Hostname: {{ system_info.hostname }}
IP Address: {{ system_info.ip_address }}
Operating System: {{ system_info.os }}
Kernel Version: {{ system_info.kernel }}
Architecture: {{ system_info.architecture }}
Total Memory: {{ system_info.memory_total }}
Memory Usage: {{ system_info.memory_usage }}
CPU Cores: {{ system_info.cpu_count }}
System Uptime: {{ system_info.uptime }}

VALIDATION RESULTS
------------------
{% if ansible_facts.services['firewalld.service'] is defined %}
Firewall Status: {{ ansible_facts.services['firewalld.service'].state }}
{% endif %}

{% if selinux_status is defined %}
SELinux Status: {{ selinux_status.stdout }}
{% endif %}

INSTALLED PACKAGES: {{ ansible_facts.packages | length }}
RUNNING SERVICES: {{ ansible_facts.services | selectattr('value.state', 'equalto', 'running') | list | length }}

NETWORK INTERFACES
------------------
{% for interface in ansible_interfaces %}
{{ interface }}: {{ ansible_facts[interface]['ipv4']['address'] | default('No IP') }}
{% endfor %}

MOUNT POINTS
------------
{% for mount in ansible_mounts %}
{{ mount.mount }}: {{ (mount.size_available / 1024 / 1024 / 1024) | round(2) }}GB available
{% endfor %}
EOF
Execute the comprehensive validation:
ansible-playbook -i inventory comprehensive-validation.yml
View the generated reports:
ansible all -i inventory -m fetch -a "src=/tmp/validation_reports/{{ ansible_hostname }}_validation_report.txt dest=./reports/ flat=yes"
ls -la reports/
cat reports/*_validation_report.txt
Troubleshooting Common Issues
Issue 1: Facts Not Gathering Properly
Problem: Setup module fails or returns incomplete information

Solution:

# Test basic connectivity first
ansible all -i inventory -m ping

# Try gathering facts with verbose output
ansible all -i inventory -m setup -v

# Check for Python installation on managed nodes
ansible all -i inventory -m raw -a "python3 --version"
Issue 2: Assertion Failures
Problem: Assert tasks fail unexpectedly

Solution:

# Debug the specific fact being tested
ansible node1 -i inventory -m setup -a "filter=ansible_memory_mb"

# Use debug module to examine values
ansible-playbook -i inventory debug-facts.yml
Create a debug playbook: ```yaml cat > debug-facts.yml << EOF
hosts: all gather_facts: yes tasks:
debug: var: ansible_memory_mb
debug: var: ansible_distribution
debug: var: ansible_default_ipv4
EOF


### Issue 3: Service Facts Not Available

**Problem**: Service facts module fails on certain systems

**Solution**:
```bash
# Check if systemctl is available
ansible all -i inventory -m command -a "systemctl --version"

# Use alternative service checking
ansible all -i inventory -m command -a "service --status-all"
Best Practices for Fact-Based Validation
1. Fact Caching
Enable fact caching to improve performance:

cat >> ansible.cfg << EOF
[defaults]
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 3600
EOF
2. Custom Facts
Create custom facts for application-specific validation:

# On managed nodes, create custom fact
sudo mkdir -p /etc/ansible/facts.d
sudo cat > /etc/ansible/facts.d/application.fact << EOF
#!/bin/bash
echo '{"app_version": "2.1.0", "config_valid": true}'
EOF
sudo chmod +x /etc/ansible/facts.d/application.fact
3. Validation Templates
Create reusable validation templates:

cat > validation-template.yml << EOF
---
- name: "{{ validation_name | default('System Validation') }}"
  hosts: "{{ target_hosts | default('all') }}"
  gather_facts: yes
  tasks:
    - include_tasks: "{{ validation_type }}-checks.yml"
      when: validation_type is defined
EOF
Conclusion
In this lab, you have successfully learned how to:

• Gather comprehensive system information using Ansible's setup module and understand the structure of facts • Create conditional validation statements using assert modules to verify system configurations • Build sophisticated validation playbooks that ensure systems meet specific requirements and standards • Implement multi-layered validation checks covering security, performance, and compliance requirements • Generate detailed validation reports for documentation and audit purposes

Why This Matters: Configuration validation using Ansible facts is crucial for:

Maintaining consistency across multiple environments (development, staging, production)
Ensuring compliance with security and operational standards
Preventing configuration drift by regularly validating system states
Automating quality assurance processes in infrastructure management
Supporting audit requirements with detailed validation reports
These skills are essential for Red Hat Certified Engineers (RHCE) and are widely applicable in enterprise environments where configuration management and compliance are critical. The ability to validate configurations programmatically reduces manual errors, improves reliability, and ensures that infrastructure remains in desired states over time.

The techniques you've learned can be extended to validate any aspect of system configuration, from simple package installations to complex multi-tier application deployments, making them invaluable tools for modern infrastructure automation.
