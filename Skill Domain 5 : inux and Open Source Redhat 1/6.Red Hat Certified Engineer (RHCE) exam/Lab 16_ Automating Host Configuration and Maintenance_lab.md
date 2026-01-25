Lab 16: Automating Host Configuration and Maintenance
Objectives
By the end of this lab, students will be able to:

Create and execute Ansible playbooks to automate system package and service management
Configure automated maintenance tasks including log rotation and package updates
Implement automated system reboot procedures with health checks
Understand best practices for configuration management in enterprise environments
Develop skills essential for the Red Hat Certified Engineer (RHCE) certification
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Basic knowledge of system administration concepts (packages, services, logs)
Understanding of SSH key-based authentication
Previous exposure to Ansible fundamentals (recommended but not required)
Lab Environment Setup
Al Nafi Cloud Machines: This lab uses Al Nafi's pre-configured Linux-based cloud machines. Simply click Start Lab to access your environment - no VM setup required!

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: 2 target hosts (node1 and node2) for configuration management
All necessary tools and dependencies pre-configured
Task 1: Write a Playbook to Manage System Packages and Services
Subtask 1.1: Set Up Ansible Inventory and Configuration
First, let's establish our Ansible environment and inventory.

Connect to your control node and verify Ansible installation:
ansible --version
Create the lab directory structure:
mkdir -p ~/lab16-automation/{playbooks,inventory,roles,group_vars}
cd ~/lab16-automation
Create the inventory file:
cat > inventory/hosts.yml << 'EOF'
all:
  children:
    webservers:
      hosts:
        node1:
          ansible_host: 192.168.1.10
        node2:
          ansible_host: 192.168.1.11
  vars:
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
EOF
Create ansible.cfg configuration file:
cat > ansible.cfg << 'EOF'
[defaults]
inventory = inventory/hosts.yml
remote_user = ansible
private_key_file = ~/.ssh/id_rsa
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = memory

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOF
Test connectivity to managed nodes:
ansible all -m ping
Subtask 1.2: Create Package Management Playbook
Now we'll create a comprehensive playbook for managing system packages and services.

Create the main package management playbook:
cat > playbooks/package-service-management.yml << 'EOF'
---
- name: System Package and Service Management
  hosts: all
  become: yes
  vars:
    required_packages:
      - htop
      - vim
      - curl
      - wget
      - git
      - rsync
      - logrotate
      - chrony
    
    required_services:
      - chronyd
      - sshd
    
    packages_to_remove:
      - telnet
      - rsh
  
  tasks:
    - name: Update package cache (RHEL/CentOS)
      yum:
        update_cache: yes
      when: ansible_os_family == "RedHat"
    
    - name: Update package cache (Ubuntu/Debian)
      apt:
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: Install required packages (RHEL/CentOS)
      yum:
        name: "{{ required_packages }}"
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Install required packages (Ubuntu/Debian)
      apt:
        name: "{{ required_packages }}"
        state: present
      when: ansible_os_family == "Debian"
    
    - name: Remove unwanted packages (RHEL/CentOS)
      yum:
        name: "{{ packages_to_remove }}"
        state: absent
      when: ansible_os_family == "RedHat"
    
    - name: Remove unwanted packages (Ubuntu/Debian)
      apt:
        name: "{{ packages_to_remove }}"
        state: absent
      when: ansible_os_family == "Debian"
    
    - name: Ensure required services are started and enabled
      systemd:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop: "{{ required_services }}"
    
    - name: Gather service facts
      service_facts:
    
    - name: Display service status
      debug:
        msg: "Service {{ item }} is {{ ansible_facts.services[item + '.service'].state }}"
      loop: "{{ required_services }}"
      when: ansible_facts.services[item + '.service'] is defined
EOF
Execute the package management playbook:
ansible-playbook playbooks/package-service-management.yml
Verify the installation by checking installed packages:
ansible all -m shell -a "rpm -qa | grep -E 'htop|vim|curl'"
Subtask 1.3: Create Advanced Service Management Playbook
Let's create a more sophisticated service management playbook with configuration templates.

Create a service configuration playbook:
cat > playbooks/advanced-service-management.yml << 'EOF'
---
- name: Advanced Service Configuration Management
  hosts: all
  become: yes
  vars:
    web_services:
      - name: httpd
        package: httpd
        config_file: /etc/httpd/conf/httpd.conf
        port: 80
      - name: nginx
        package: nginx
        config_file: /etc/nginx/nginx.conf
        port: 8080
  
  tasks:
    - name: Install web server packages
      yum:
        name: "{{ item.package }}"
        state: present
      loop: "{{ web_services }}"
      when: ansible_os_family == "RedHat"
    
    - name: Create custom index page for Apache
      copy:
        content: |
          <html>
          <head><title>Automated Configuration</title></head>
          <body>
          <h1>Server: {{ ansible_hostname }}</h1>
          <p>Configured automatically via Ansible</p>
          <p>Last updated: {{ ansible_date_time.iso8601 }}</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: apache
        group: apache
        mode: '0644'
      when: "'httpd' in web_services | map(attribute='package') | list"
    
    - name: Configure firewall for web services
      firewalld:
        port: "{{ item.port }}/tcp"
        permanent: yes
        state: enabled
        immediate: yes
      loop: "{{ web_services }}"
      ignore_errors: yes
    
    - name: Start and enable web services
      systemd:
        name: "{{ item.name }}"
        state: started
        enabled: yes
      loop: "{{ web_services }}"
    
    - name: Verify service status
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ item.port }}"
        method: GET
        status_code: 200
      loop: "{{ web_services }}"
      delegate_to: localhost
      ignore_errors: yes
EOF
Run the advanced service management playbook:
ansible-playbook playbooks/advanced-service-management.yml
Task 2: Configure Host Maintenance Tasks
Subtask 2.1: Set Up Log Rotation Configuration
Log rotation is crucial for maintaining system health and preventing disk space issues.

Create a log rotation configuration playbook:
cat > playbooks/log-rotation-setup.yml << 'EOF'
---
- name: Configure Log Rotation
  hosts: all
  become: yes
  vars:
    custom_log_configs:
      - name: application-logs
        path: /var/log/myapp/*.log
        frequency: daily
        rotate: 30
        compress: yes
        delaycompress: yes
        missingok: yes
        notifempty: yes
      
      - name: system-logs
        path: /var/log/messages /var/log/secure
        frequency: weekly
        rotate: 4
        compress: yes
        delaycompress: yes
        missingok: yes
        notifempty: yes
  
  tasks:
    - name: Ensure logrotate is installed
      yum:
        name: logrotate
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Create custom log directories
      file:
        path: /var/log/myapp
        state: directory
        owner: root
        group: root
        mode: '0755'
    
    - name: Create sample application log
      copy:
        content: |
          {{ ansible_date_time.iso8601 }} - Sample application log entry
          {{ ansible_date_time.iso8601 }} - Application started successfully
        dest: /var/log/myapp/app.log
        owner: root
        group: root
        mode: '0644'
    
    - name: Configure custom log rotation
      template:
        src: logrotate.j2
        dest: "/etc/logrotate.d/{{ item.name }}"
        owner: root
        group: root
        mode: '0644'
      loop: "{{ custom_log_configs }}"
    
    - name: Test logrotate configuration
      command: logrotate -d /etc/logrotate.conf
      register: logrotate_test
      changed_when: false
    
    - name: Display logrotate test results
      debug:
        var: logrotate_test.stdout_lines
EOF
Create the logrotate template:
mkdir -p templates
cat > templates/logrotate.j2 << 'EOF'
{{ item.path }} {
    {{ item.frequency }}
    rotate {{ item.rotate }}
{% if item.compress %}
    compress
{% endif %}
{% if item.delaycompress %}
    delaycompress
{% endif %}
{% if item.missingok %}
    missingok
{% endif %}
{% if item.notifempty %}
    notifempty
{% endif %}
    create 0644 root root
    postrotate
        /bin/systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF
Execute the log rotation setup:
ansible-playbook playbooks/log-rotation-setup.yml
Subtask 2.2: Implement Automated Package Updates
Create a comprehensive package update strategy with safety checks.

Create the package update playbook:
cat > playbooks/automated-updates.yml << 'EOF'
---
- name: Automated Package Updates with Safety Checks
  hosts: all
  become: yes
  vars:
    update_strategy: security  # Options: all, security, minimal
    reboot_required_file: /var/run/reboot-required
    backup_dir: /backup/pre-update
    
  tasks:
    - name: Create backup directory
      file:
        path: "{{ backup_dir }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
    
    - name: Backup current package list
      shell: |
        rpm -qa > {{ backup_dir }}/packages-before-update-{{ ansible_date_time.epoch }}.txt
      when: ansible_os_family == "RedHat"
    
    - name: Check available updates
      yum:
        list: updates
      register: available_updates
      when: ansible_os_family == "RedHat"
    
    - name: Display available updates count
      debug:
        msg: "{{ available_updates.results | length }} updates available"
      when: ansible_os_family == "RedHat"
    
    - name: Apply security updates only
      yum:
        name: "*"
        state: latest
        security: yes
        update_only: yes
      when: 
        - ansible_os_family == "RedHat"
        - update_strategy == "security"
      register: security_updates
    
    - name: Apply all updates
      yum:
        name: "*"
        state: latest
        update_only: yes
      when: 
        - ansible_os_family == "RedHat"
        - update_strategy == "all"
      register: all_updates
    
    - name: Check if reboot is required (RHEL/CentOS)
      stat:
        path: /var/run/reboot-required
      register: reboot_required_rhel
      when: ansible_os_family == "RedHat"
    
    - name: Check for kernel updates requiring reboot
      shell: |
        if [ "$(rpm -q kernel --last | head -n1 | cut -d' ' -f1)" != "$(uname -r | sed 's/-/_/g')" ]; then
          echo "reboot_needed"
        else
          echo "no_reboot_needed"
        fi
      register: kernel_check
      changed_when: false
      when: ansible_os_family == "RedHat"
    
    - name: Create reboot indicator file
      file:
        path: "{{ reboot_required_file }}"
        state: touch
        owner: root
        group: root
        mode: '0644'
      when: 
        - kernel_check is defined
        - kernel_check.stdout == "reboot_needed"
    
    - name: Generate update report
      template:
        src: update-report.j2
        dest: "/var/log/update-report-{{ ansible_date_time.epoch }}.txt"
        owner: root
        group: root
        mode: '0644'
    
    - name: Clean package cache
      yum:
        autoremove: yes
      when: ansible_os_family == "RedHat"
EOF
Create the update report template:
cat > templates/update-report.j2 << 'EOF'
System Update Report
====================
Host: {{ ansible_hostname }}
Date: {{ ansible_date_time.iso8601 }}
Update Strategy: {{ update_strategy }}

System Information:
- OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
- Kernel: {{ ansible_kernel }}
- Architecture: {{ ansible_architecture }}

{% if security_updates is defined and security_updates.changed %}
Security Updates Applied: Yes
{% elif all_updates is defined and all_updates.changed %}
All Updates Applied: Yes
{% else %}
Updates Applied: No updates were necessary
{% endif %}

{% if kernel_check is defined and kernel_check.stdout == "reboot_needed" %}
Reboot Required: Yes
{% else %}
Reboot Required: No
{% endif %}

Backup Location: {{ backup_dir }}
EOF
Run the automated updates playbook:
ansible-playbook playbooks/automated-updates.yml
Subtask 2.3: Create System Health Monitoring
Implement comprehensive system health checks as part of maintenance.

Create a system health monitoring playbook:
cat > playbooks/system-health-check.yml << 'EOF'
---
- name: System Health Monitoring and Reporting
  hosts: all
  become: yes
  vars:
    health_check_dir: /var/log/health-checks
    disk_usage_threshold: 80
    memory_usage_threshold: 85
    load_average_threshold: 2.0
    
  tasks:
    - name: Create health check directory
      file:
        path: "{{ health_check_dir }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
    
    - name: Gather system facts
      setup:
    
    - name: Check disk usage
      shell: df -h | awk 'NR>1 {print $5 " " $6}' | sed 's/%//'
      register: disk_usage
      changed_when: false
    
    - name: Check memory usage
      shell: free | grep Mem | awk '{printf "%.2f", ($3/$2) * 100.0}'
      register: memory_usage
      changed_when: false
    
    - name: Check load average
      shell: uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
      register: load_average
      changed_when: false
    
    - name: Check service status
      systemd:
        name: "{{ item }}"
      register: service_status
      loop:
        - sshd
        - chronyd
        - httpd
      ignore_errors: yes
    
    - name: Check for failed systemd services
      shell: systemctl --failed --no-legend | wc -l
      register: failed_services_count
      changed_when: false
    
    - name: Generate health report
      template:
        src: health-report.j2
        dest: "{{ health_check_dir }}/health-report-{{ ansible_date_time.epoch }}.txt"
        owner: root
        group: root
        mode: '0644'
    
    - name: Check for critical issues
      set_fact:
        critical_issues: []
    
    - name: Add disk usage warnings
      set_fact:
        critical_issues: "{{ critical_issues + ['High disk usage on ' + item.split()[1] + ': ' + item.split()[0] + '%'] }}"
      loop: "{{ disk_usage.stdout_lines }}"
      when: item.split()[0] | int > disk_usage_threshold
    
    - name: Add memory usage warning
      set_fact:
        critical_issues: "{{ critical_issues + ['High memory usage: ' + memory_usage.stdout + '%'] }}"
      when: memory_usage.stdout | float > memory_usage_threshold
    
    - name: Add load average warning
      set_fact:
        critical_issues: "{{ critical_issues + ['High load average: ' + load_average.stdout] }}"
      when: load_average.stdout | float > load_average_threshold
    
    - name: Display critical issues
      debug:
        msg: "CRITICAL ISSUES FOUND: {{ critical_issues }}"
      when: critical_issues | length > 0
    
    - name: Send alert if critical issues found
      mail:
        to: admin@example.com
        subject: "Critical System Issues on {{ ansible_hostname }}"
        body: "The following critical issues were found:\n{{ critical_issues | join('\n') }}"
      when: 
        - critical_issues | length > 0
        - false  # Set to true to enable email alerts
EOF
Create the health report template:
cat > templates/health-report.j2 << 'EOF'
System Health Report
===================
Host: {{ ansible_hostname }}
Date: {{ ansible_date_time.iso8601 }}
Uptime: {{ ansible_uptime_seconds | int // 86400 }} days, {{ (ansible_uptime_seconds | int % 86400) // 3600 }} hours

System Resources:
-----------------
CPU Cores: {{ ansible_processor_vcpus }}
Total Memory: {{ ansible_memtotal_mb }} MB
Memory Usage: {{ memory_usage.stdout }}%
Load Average: {{ load_average.stdout }}

Disk Usage:
-----------
{% for line in disk_usage.stdout_lines %}
{{ line }}
{% endfor %}

Network Interfaces:
------------------
{% for interface in ansible_interfaces %}
{% if interface != 'lo' %}
{{ interface }}: {{ ansible_facts[interface]['ipv4']['address'] | default('No IP') }}
{% endif %}
{% endfor %}

Service Status:
--------------
{% for result in service_status.results %}
{{ result.item }}: {{ 'Running' if result.status.ActiveState == 'active' else 'Not Running' }}
{% endfor %}

Failed Services: {{ failed_services_count.stdout }}

{% if critical_issues is defined and critical_issues | length > 0 %}
CRITICAL ISSUES:
---------------
{% for issue in critical_issues %}
- {{ issue }}
{% endfor %}
{% endif %}
EOF
Execute the health monitoring playbook:
ansible-playbook playbooks/system-health-check.yml
Task 3: Automate System Reboots and Health Checks
Subtask 3.1: Create Safe Reboot Automation
Implement a safe reboot procedure with pre and post-reboot health checks.

Create the automated reboot playbook:
cat > playbooks/automated-reboot.yml << 'EOF'
---
- name: Automated System Reboot with Health Checks
  hosts: all
  become: yes
  serial: 1  # Reboot one host at a time
  vars:
    reboot_timeout: 600
    pre_reboot_checks:
      - check_disk_space
      - check_running_services
      - backup_critical_data
    post_reboot_checks:
      - verify_system_boot
      - check_services_status
      - validate_network_connectivity
    
  tasks:
    - name: Pre-reboot - Check if reboot is required
      stat:
        path: /var/run/reboot-required
      register: reboot_needed
    
    - name: Pre-reboot - Display reboot requirement status
      debug:
        msg: "Reboot {{ 'is' if reboot_needed.stat.exists else 'is not' }} required"
    
    - name: Pre-reboot - Check disk space
      shell: df -h / | tail -1 | awk '{print $5}' | sed 's/%//'
      register: root_disk_usage
      changed_when: false
    
    - name: Pre-reboot - Verify sufficient disk space
      fail:
        msg: "Insufficient disk space for safe reboot. Root partition is {{ root_disk_usage.stdout }}% full"
      when: root_disk_usage.stdout | int > 90
    
    - name: Pre-reboot - Get list of running services
      shell: systemctl list-units --type=service --state=running --no-legend | awk '{print $1}'
      register: running_services_before
      changed_when: false
    
    - name: Pre-reboot - Create service backup list
      copy:
        content: "{{ running_services_before.stdout }}"
        dest: /tmp/services-before-reboot.txt
        owner: root
        group: root
        mode: '0644'
    
    - name: Pre-reboot - Sync filesystem
      command: sync
      changed_when: false
    
    - name: Pre-reboot - Create reboot timestamp
      copy:
        content: "{{ ansible_date_time.iso8601 }}"
        dest: /tmp/reboot-timestamp.txt
        owner: root
        group: root
        mode: '0644'
    
    - name: Perform system reboot
      reboot:
        reboot_timeout: "{{ reboot_timeout }}"
        pre_reboot_delay: 10
        post_reboot_delay: 30
        test_command: uptime
      when: reboot_needed.stat.exists or force_reboot | default(false)
    
    - name: Post-reboot - Wait for system to be fully ready
      wait_for_connection:
        timeout: 300
        delay: 30
    
    - name: Post-reboot - Verify system boot time
      shell: uptime -s
      register: boot_time
      changed_when: false
    
    - name: Post-reboot - Check if reboot was successful
      stat:
        path: /tmp/reboot-timestamp.txt
      register: reboot_timestamp_file
    
    - name: Post-reboot - Compare boot time with reboot timestamp
      shell: |
        reboot_time=$(cat /tmp/reboot-timestamp.txt)
        boot_time=$(uptime -s)
        if [[ "$boot_time" > "$reboot_time" ]]; then
          echo "Reboot successful"
        else
          echo "Reboot may have failed"
        fi
      register: reboot_verification
      changed_when: false
      when: reboot_timestamp_file.stat.exists
    
    - name: Post-reboot - Get current running services
      shell: systemctl list-units --type=service --state=running --no-legend | awk '{print $1}'
      register: running_services_after
      changed_when: false
    
    - name: Post-reboot - Compare service states
      shell: |
        if [ -f /tmp/services-before-reboot.txt ]; then
          comm -23 <(sort /tmp/services-before-reboot.txt) <(echo "{{ running_services_after.stdout }}" | sort) > /tmp/missing-services.txt
          missing_count=$(wc -l < /tmp/missing-services.txt)
          echo "Missing services: $missing_count"
          if [ $missing_count -gt 0 ]; then
            echo "Services that failed to start:"
            cat /tmp/missing-services.txt
          fi
        fi
      register: service_comparison
      changed_when: false
    
    - name: Post-reboot - Test network connectivity
      uri:
        url: http://www.google.com
        method: HEAD
        timeout: 10
      delegate_to: localhost
      register: network_test
      ignore_errors: yes
    
    - name: Post-reboot - Verify critical services
      systemd:
        name: "{{ item }}"
      register: critical_services_status
      loop:
        - sshd
        - chronyd
        - NetworkManager
      ignore_errors: yes
    
    - name: Post-reboot - Generate reboot report
      template:
        src: reboot-report.j2
        dest: "/var/log/reboot-report-{{ ansible_date_time.epoch }}.txt"
        owner: root
        group: root
        mode: '0644'
    
    - name: Post-reboot - Clean up temporary files
      file:
        path: "{{ item }}"
        state: absent
      loop:
        - /tmp/services-before-reboot.txt
        - /tmp/missing-services.txt
        - /tmp/reboot-timestamp.txt
        - /var/run/reboot-required
    
    - name: Post-reboot - Display reboot summary
      debug:
        msg: |
          Reboot Summary for {{ ansible_hostname }}:
          - Boot time: {{ boot_time.stdout }}
          - Reboot verification: {{ reboot_verification.stdout | default('N/A') }}
          - Network connectivity: {{ 'OK' if network_test.status == 200 else 'FAILED' }}
          - Service status: {{ service_comparison.stdout_lines | join(' ') }}
EOF
Create the reboot report template:
cat > templates/reboot-report.j2 << 'EOF'
System Reboot Report
===================
Host: {{ ansible_hostname }}
Reboot Date: {{ ansible_date_time.iso8601 }}
Boot Time: {{ boot_time.stdout }}

Reboot Verification:
{{ reboot_verification.stdout | default('Verification not available') }}

Network Connectivity:
Status: {{ 'OK' if network_test.status == 200 else 'FAILED' }}

Critical Services Status:
{% for result in critical_services_status.results %}
{{ result.item }}: {{ 'Running' if result.status.ActiveState == 'active' else 'Not Running' }}
{% endfor %}

Service Comparison:
{{ service_comparison.stdout }}

System Information Post-Reboot:
- Uptime: {{ ansible_uptime_seconds | int // 3600 }} hours
- Load Average: {{ ansible_loadavg.1m }}
- Memory Usage: {{ (ansible_memory_mb.real.used / ansible_memory_mb.real.total * 100) | round(2) }}%
- Disk Usage: {{ ansible_mounts[0].size_available / ansible_mounts[0].size_total * 100 | round(2) }}% available
EOF
Subtask 3.2: Create Comprehensive Maintenance Workflow
Combine all maintenance tasks into a single comprehensive workflow.

Create the master maintenance playbook:
cat > playbooks/comprehensive-maintenance.yml << 'EOF'
---
- name: Comprehensive System Maintenance Workflow
  hosts: all
  become: yes
  serial: 1
  vars:
    maintenance_mode: true
    maintenance_window_start: "{{ ansible_date_time.iso8601 }}"
    notification_email: admin@example.com
    
  pre_tasks:
    - name: Create maintenance log directory
      file:
        path: /var/log/maintenance
        state: directory
        owner: root
        group: root
        mode: '0755'
    
    - name: Start maintenance logging
      copy:
        content: |
          Maintenance started at: {{ maintenance_window_start }}
          Host: {{ ansible_hostname }}
          Maintenance tasks planned:
          1. System health check
          2. Package updates
          3. Log rotation
          4. Service management
          5. System reboot (if required)
        dest: /var/log/maintenance/maintenance-{{ ansible_date_time.epoch }}.log
        owner: root
        group: root
        mode: '0644'
  
  tasks:
    - name: Phase 1 - Pre-maintenance health check
      include_tasks: tasks/health-check.yml
      vars:
        check_phase: "pre-maintenance"
    
    - name: Phase 2 - Update system packages
      include_tasks: tasks/package-updates.yml
    
    - name: Phase 3 - Configure log rotation
      include_tasks: tasks/log-rotation.yml
    
    - name: Phase 4 - Service management
      include_tasks: tasks/service-management.yml
    
    - name: Phase 5 - System reboot if required
      include_tasks: tasks/conditional-reboot.yml
    
    - name: Phase 6 - Post-maintenance health check
      include_tasks: tasks/health-check.yml
      vars:
        check_phase: "post-maintenance"
  
  post_tasks:
    - name: Generate comprehensive maintenance report
      template:
        src: maintenance-report.j2
        dest: /var/log/maintenance/maintenance-report-{{ ansible_date_time.epoch }}.html
        owner: root
        group: root
        mode: '0644'
    
    - name: Update maintenance log with completion
      lineinfile:
        path: /var/log/maintenance/maintenance-{{ ansible_date_time.epoch }}.log
        line: "Maintenance completed at: {{ ansible_date_time.iso8601 }}"
        create: yes
    
    - name: Display maintenance summary
      debug:
        msg: |
          Maintenance completed for {{ ansible_hostname }}
          Start time: {{ maintenance_window_start }}
          End time: {{ ansible_date_time.iso8601 }}
          Check /var/log/maintenance/ for detailed reports
EOF
Create task files directory and individual task files:
mkdir -p tasks

# Health check task
cat > tasks/health-check.yml << 'EOF'
---
- name: "{{ check_phase | title }} - Gather system information"
  setup:

- name: "{{ check_phase | title }} - Check disk usage"
  shell: df -h | awk 'NR>1 {print $5 " " $6}' | sed 's/%//'
  register: disk_usage
  changed_when: false

- name: "{{ check_phase | title }} - Check memory usage"
  shell: free | grep Mem | awk '{printf "%.2f", ($3/$2) * 100.0}'
  register: memory_usage
  changed_when: false

- name: "{{ check_phase | title }} - Check system load"
  shell: uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
  register: load_average
  changed_when:
