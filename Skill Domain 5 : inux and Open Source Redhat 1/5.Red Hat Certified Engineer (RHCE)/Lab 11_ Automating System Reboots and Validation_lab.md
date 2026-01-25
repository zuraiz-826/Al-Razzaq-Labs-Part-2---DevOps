Lab 11: Automating System Reboots and Validation
Objectives
By the end of this lab, you will be able to:

Create Ansible playbooks to safely reboot managed systems
Implement proper wait conditions and timeout handling for system reboots
Validate system services and configurations after reboot using Ansible facts
Implement comprehensive error handling for failed reboot scenarios
Use Ansible modules for system state verification and service management
Apply best practices for automated system maintenance workflows
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux system administration
Familiarity with YAML syntax and structure
Knowledge of Ansible fundamentals including playbooks, tasks, and modules
Understanding of Linux services and systemd
Basic networking concepts and SSH connectivity
Experience with text editors (vim, nano, or similar)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex setups.

Your lab environment includes:

Control Node: CentOS/RHEL 8 system with Ansible pre-installed
Managed Nodes: Two target systems (node1 and node2) for reboot testing
Pre-configured SSH key authentication between systems
Sample services and configurations for validation testing
Task 1: Creating a Basic System Reboot Playbook
Subtask 1.1: Understanding the Reboot Module
The Ansible reboot module provides a safe way to restart systems with built-in wait mechanisms and error handling.

Key parameters of the reboot module:

reboot_timeout: Maximum time to wait for reboot (default: 600 seconds)
connect_timeout: Timeout for reconnecting after reboot (default: 5 seconds)
test_command: Command to run to verify system is ready (default: whoami)
pre_reboot_delay: Time to wait before initiating reboot (default: 0 seconds)
post_reboot_delay: Time to wait after system comes back online (default: 0 seconds)
Subtask 1.2: Create the Basic Reboot Playbook
Create a directory structure for your reboot automation:

mkdir -p ~/ansible-reboot-lab
cd ~/ansible-reboot-lab
mkdir playbooks group_vars host_vars
Create the main reboot playbook:

vim playbooks/system-reboot.yml
Add the following content:

---
- name: System Reboot and Validation Playbook
  hosts: managed_nodes
  become: yes
  gather_facts: yes
  
  vars:
    reboot_timeout: 300
    connect_timeout: 10
    services_to_check:
      - sshd
      - NetworkManager
      - chronyd
    
  tasks:
    - name: Display current system uptime before reboot
      command: uptime
      register: uptime_before
      
    - name: Show uptime before reboot
      debug:
        msg: "System uptime before reboot: {{ uptime_before.stdout }}"
    
    - name: Check if reboot is required
      stat:
        path: /var/run/reboot-required
      register: reboot_required_file
      
    - name: Force reboot requirement for demonstration
      file:
        path: /var/run/reboot-required
        state: touch
      when: not reboot_required_file.stat.exists
    
    - name: Perform system reboot
      reboot:
        reboot_timeout: "{{ reboot_timeout }}"
        connect_timeout: "{{ connect_timeout }}"
        test_command: whoami
        msg: "Reboot initiated by Ansible automation"
      register: reboot_result
      
    - name: Display reboot completion message
      debug:
        msg: "System successfully rebooted. Elapsed time: {{ reboot_result.elapsed }} seconds"
Subtask 1.3: Create Inventory File
Create an inventory file for your managed nodes:

vim inventory.ini
Add the following content:

[managed_nodes]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[managed_nodes:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
Subtask 1.4: Test the Basic Reboot Playbook
Run the playbook to test basic reboot functionality:

ansible-playbook -i inventory.ini playbooks/system-reboot.yml
Verify the playbook execution and note the reboot timing information displayed.

Task 2: Implementing Service Validation After Reboot
Subtask 2.1: Create Service Validation Playbook
Create a comprehensive playbook that validates services after reboot:

vim playbooks/reboot-with-validation.yml
Add the following content:

---
- name: System Reboot with Comprehensive Validation
  hosts: managed_nodes
  become: yes
  gather_facts: yes
  
  vars:
    reboot_timeout: 600
    connect_timeout: 15
    post_reboot_delay: 30
    critical_services:
      - name: sshd
        description: "SSH Daemon"
      - name: NetworkManager
        description: "Network Manager"
      - name: chronyd
        description: "Time Synchronization"
      - name: systemd-logind
        description: "Login Manager"
    
    validation_commands:
      - command: "df -h /"
        description: "Root filesystem space"
      - command: "free -m"
        description: "Memory usage"
      - command: "systemctl is-system-running"
        description: "System state"
  
  pre_tasks:
    - name: Gather pre-reboot system facts
      setup:
      register: pre_reboot_facts
      
    - name: Record pre-reboot service states
      service_facts:
      register: pre_reboot_services
      
    - name: Display pre-reboot system information
      debug:
        msg: |
          Hostname: {{ ansible_hostname }}
          Kernel: {{ ansible_kernel }}
          Uptime: {{ ansible_uptime_seconds }} seconds
          Load Average: {{ ansible_loadavg }}
  
  tasks:
    - name: Create reboot log directory
      file:
        path: /var/log/ansible-reboot
        state: directory
        mode: '0755'
        
    - name: Log reboot initiation
      lineinfile:
        path: /var/log/ansible-reboot/reboot.log
        line: "{{ ansible_date_time.iso8601 }} - Reboot initiated by Ansible"
        create: yes
        
    - name: Perform controlled system reboot
      reboot:
        reboot_timeout: "{{ reboot_timeout }}"
        connect_timeout: "{{ connect_timeout }}"
        post_reboot_delay: "{{ post_reboot_delay }}"
        test_command: "systemctl is-system-running --wait"
        msg: "Ansible-controlled reboot for maintenance"
      register: reboot_result
      
    - name: Log reboot completion
      lineinfile:
        path: /var/log/ansible-reboot/reboot.log
        line: "{{ ansible_date_time.iso8601 }} - Reboot completed in {{ reboot_result.elapsed }} seconds"
  
  post_tasks:
    - name: Gather post-reboot system facts
      setup:
      
    - name: Validate critical services are running
      systemd:
        name: "{{ item.name }}"
        state: started
        enabled: yes
      loop: "{{ critical_services }}"
      register: service_validation
      
    - name: Check service status details
      service_facts:
      register: post_reboot_services
      
    - name: Display service validation results
      debug:
        msg: "Service {{ item.name }} ({{ item.description }}): {{ 'RUNNING' if post_reboot_services.ansible_facts.services[item.name + '.service']['state'] == 'running' else 'FAILED' }}"
      loop: "{{ critical_services }}"
      
    - name: Run system validation commands
      command: "{{ item.command }}"
      register: validation_results
      loop: "{{ validation_commands }}"
      ignore_errors: yes
      
    - name: Display validation command results
      debug:
        msg: |
          {{ item.item.description }}:
          {{ item.stdout }}
      loop: "{{ validation_results.results }}"
      when: item.rc == 0
      
    - name: Compare system state before and after reboot
      debug:
        msg: |
          System Comparison:
          - Hostname: {{ ansible_hostname }} (unchanged: {{ ansible_hostname == pre_reboot_facts.ansible_facts.ansible_hostname }})
          - Kernel: {{ ansible_kernel }} (unchanged: {{ ansible_kernel == pre_reboot_facts.ansible_facts.ansible_kernel }})
          - Architecture: {{ ansible_architecture }}
          - Total Memory: {{ ansible_memtotal_mb }} MB
Subtask 2.2: Create Service-Specific Validation Tasks
Create a separate file for detailed service validation:

vim playbooks/service-validation.yml
Add the following content:

---
- name: Detailed Service Validation After Reboot
  hosts: managed_nodes
  become: yes
  gather_facts: yes
  
  vars:
    service_checks:
      sshd:
        port: 22
        process_name: sshd
        config_file: /etc/ssh/sshd_config
      NetworkManager:
        process_name: NetworkManager
        config_file: /etc/NetworkManager/NetworkManager.conf
      chronyd:
        port: 123
        process_name: chronyd
        config_file: /etc/chrony.conf
  
  tasks:
    - name: Validate service processes are running
      command: pgrep -f "{{ item.value.process_name }}"
      register: process_check
      loop: "{{ service_checks | dict2items }}"
      failed_when: process_check.rc != 0
      
    - name: Check service listening ports
      wait_for:
        port: "{{ item.value.port }}"
        host: "{{ ansible_default_ipv4.address }}"
        timeout: 10
      loop: "{{ service_checks | dict2items }}"
      when: item.value.port is defined
      
    - name: Verify service configuration files exist
      stat:
        path: "{{ item.value.config_file }}"
      register: config_check
      loop: "{{ service_checks | dict2items }}"
      when: item.value.config_file is defined
      
    - name: Display configuration file status
      debug:
        msg: "Config file {{ item.item.value.config_file }} for {{ item.item.key }}: {{ 'EXISTS' if item.stat.exists else 'MISSING' }}"
      loop: "{{ config_check.results }}"
      when: item.item.value.config_file is defined
      
    - name: Test network connectivity
      uri:
        url: "http://www.google.com"
        method: HEAD
        timeout: 10
      register: connectivity_test
      ignore_errors: yes
      
    - name: Display connectivity test result
      debug:
        msg: "Internet connectivity: {{ 'AVAILABLE' if connectivity_test.status == 200 else 'UNAVAILABLE' }}"
Subtask 2.3: Run the Validation Playbook
Execute the comprehensive reboot and validation playbook:

ansible-playbook -i inventory.ini playbooks/reboot-with-validation.yml
Then run the detailed service validation:

ansible-playbook -i inventory.ini playbooks/service-validation.yml
Task 3: Implementing Error Handling for Failed Reboots
Subtask 3.1: Create Error Handling Playbook
Create a robust playbook with comprehensive error handling:

vim playbooks/reboot-with-error-handling.yml
Add the following content:

---
- name: Robust System Reboot with Error Handling
  hosts: managed_nodes
  become: yes
  gather_facts: yes
  serial: 1  # Reboot one system at a time
  
  vars:
    reboot_timeout: 300
    connect_timeout: 10
    max_reboot_attempts: 3
    notification_email: "admin@company.com"
    
  handlers:
    - name: Send failure notification
      mail:
        to: "{{ notification_email }}"
        subject: "ALERT: System Reboot Failed on {{ inventory_hostname }}"
        body: |
          System reboot failed on {{ inventory_hostname }}
          Time: {{ ansible_date_time.iso8601 }}
          Error: {{ reboot_error_msg | default('Unknown error') }}
        host: localhost
      listen: "reboot failed"
      ignore_errors: yes
  
  pre_tasks:
    - name: Check system prerequisites
      block:
        - name: Verify system is accessible
          ping:
          
        - name: Check available disk space
          shell: df / | awk 'NR==2 {print $5}' | sed 's/%//'
          register: disk_usage
          
        - name: Fail if disk space is critical
          fail:
            msg: "Insufficient disk space: {{ disk_usage.stdout }}% used"
          when: disk_usage.stdout | int > 95
          
        - name: Check system load
          shell: uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
          register: system_load
          
        - name: Warning for high system load
          debug:
            msg: "WARNING: High system load detected: {{ system_load.stdout }}"
          when: system_load.stdout | float > 5.0
          
      rescue:
        - name: Handle prerequisite check failures
          debug:
            msg: "Prerequisite checks failed, but continuing with reboot attempt"
          
        - name: Set error flag
          set_fact:
            prereq_failed: true
  
  tasks:
    - name: Attempt system reboot with retry logic
      block:
        - name: Create backup of critical files before reboot
          copy:
            src: "{{ item }}"
            dest: "{{ item }}.backup.{{ ansible_date_time.epoch }}"
            remote_src: yes
          loop:
            - /etc/fstab
            - /etc/hosts
            - /boot/grub2/grub.cfg
          ignore_errors: yes
          
        - name: Perform system reboot with error handling
          reboot:
            reboot_timeout: "{{ reboot_timeout }}"
            connect_timeout: "{{ connect_timeout }}"
            test_command: "systemctl is-system-running --wait"
            msg: "Ansible reboot with error handling"
          register: reboot_result
          retries: "{{ max_reboot_attempts }}"
          delay: 60
          
        - name: Verify reboot success
          debug:
            msg: "Reboot successful! Elapsed time: {{ reboot_result.elapsed }} seconds"
            
      rescue:
        - name: Handle reboot failure
          block:
            - name: Set error message
              set_fact:
                reboot_error_msg: "Reboot failed after {{ max_reboot_attempts }} attempts"
                
            - name: Log reboot failure
              lineinfile:
                path: /var/log/ansible-reboot/failed-reboots.log
                line: "{{ ansible_date_time.iso8601 }} - FAILED: {{ inventory_hostname }} - {{ reboot_error_msg }}"
                create: yes
              delegate_to: localhost
              
            - name: Attempt emergency recovery
              include_tasks: emergency-recovery.yml
              
            - name: Trigger failure notification
              debug:
                msg: "Triggering failure notification handler"
              notify: reboot failed
              
            - name: Fail the play for this host
              fail:
                msg: "{{ reboot_error_msg }}"
                
      always:
        - name: Record reboot attempt
          lineinfile:
            path: /var/log/ansible-reboot/reboot-attempts.log
            line: "{{ ansible_date_time.iso8601 }} - {{ inventory_hostname }} - {{ 'SUCCESS' if reboot_result is defined and reboot_result.elapsed is defined else 'FAILED' }}"
            create: yes
          delegate_to: localhost
          
  post_tasks:
    - name: Post-reboot validation with error handling
      block:
        - name: Wait for system to be fully ready
          wait_for:
            timeout: 60
          delegate_to: localhost
          
        - name: Comprehensive system health check
          include_tasks: health-check.yml
          
        - name: Generate reboot report
          template:
            src: reboot-report.j2
            dest: "/tmp/reboot-report-{{ inventory_hostname }}-{{ ansible_date_time.epoch }}.txt"
          delegate_to: localhost
          
      rescue:
        - name: Handle post-reboot validation failures
          debug:
            msg: "Post-reboot validation failed, but system appears to be running"
            
        - name: Mark system for manual review
          lineinfile:
            path: /var/log/ansible-reboot/manual-review.log
            line: "{{ ansible_date_time.iso8601 }} - {{ inventory_hostname }} - Post-reboot validation failed"
            create: yes
          delegate_to: localhost
Subtask 3.2: Create Emergency Recovery Tasks
Create emergency recovery procedures:

vim playbooks/emergency-recovery.yml
Add the following content:

---
- name: Check if system is partially responsive
  ping:
  register: ping_result
  ignore_errors: yes
  
- name: Attempt to connect via alternative methods
  block:
    - name: Try connecting with longer timeout
      wait_for_connection:
        timeout: 120
        delay: 10
      register: connection_result
      
    - name: Check system status if connected
      command: systemctl is-system-running
      register: system_status
      when: connection_result is succeeded
      
  rescue:
    - name: System appears to be completely unresponsive
      debug:
        msg: "System {{ inventory_hostname }} is not responding to connection attempts"
        
    - name: Log critical failure
      lineinfile:
        path: /var/log/ansible-reboot/critical-failures.log
        line: "{{ ansible_date_time.iso8601 }} - CRITICAL: {{ inventory_hostname }} - System unresponsive after reboot"
        create: yes
      delegate_to: localhost
      
- name: Attempt basic service recovery
  block:
    - name: Restart critical services
      systemd:
        name: "{{ item }}"
        state: restarted
      loop:
        - sshd
        - NetworkManager
      ignore_errors: yes
      
  when: connection_result is succeeded
Subtask 3.3: Create Health Check Tasks
Create comprehensive health check procedures:

vim playbooks/health-check.yml
Add the following content:

---
- name: System Health Check After Reboot
  block:
    - name: Check system uptime
      command: uptime
      register: uptime_check
      
    - name: Verify kernel version
      command: uname -r
      register: kernel_check
      
    - name: Check memory usage
      command: free -m
      register: memory_check
      
    - name: Check disk usage
      command: df -h
      register: disk_check
      
    - name: Verify network interfaces
      command: ip addr show
      register: network_check
      
    - name: Check running services
      command: systemctl list-units --type=service --state=running
      register: services_check
      
    - name: Test DNS resolution
      command: nslookup google.com
      register: dns_check
      ignore_errors: yes
      
    - name: Compile health check results
      set_fact:
        health_check_results:
          uptime: "{{ uptime_check.stdout }}"
          kernel: "{{ kernel_check.stdout }}"
          memory_status: "{{ 'OK' if memory_check.rc == 0 else 'FAILED' }}"
          disk_status: "{{ 'OK' if disk_check.rc == 0 else 'FAILED' }}"
          network_status: "{{ 'OK' if network_check.rc == 0 else 'FAILED' }}"
          dns_status: "{{ 'OK' if dns_check.rc == 0 else 'FAILED' }}"
          
    - name: Display health check summary
      debug:
        var: health_check_results
        
  rescue:
    - name: Health check failed
      set_fact:
        health_check_failed: true
        
    - name: Log health check failure
      debug:
        msg: "Health check failed for {{ inventory_hostname }}"
Subtask 3.4: Create Reboot Report Template
Create a template for reboot reports:

mkdir templates
vim templates/reboot-report.j2
Add the following content:

SYSTEM REBOOT REPORT
===================

System: {{ inventory_hostname }}
Date: {{ ansible_date_time.iso8601 }}
Operator: {{ ansible_user }}

REBOOT DETAILS:
{% if reboot_result is defined and reboot_result.elapsed is defined %}
- Status: SUCCESS
- Duration: {{ reboot_result.elapsed }} seconds
- Timeout Used: {{ reboot_timeout }} seconds
{% else %}
- Status: FAILED
- Error: {{ reboot_error_msg | default('Unknown error occurred') }}
{% endif %}

SYSTEM INFORMATION:
- Hostname: {{ ansible_hostname }}
- Kernel: {{ ansible_kernel }}
- Architecture: {{ ansible_architecture }}
- Memory: {{ ansible_memtotal_mb }} MB
- IP Address: {{ ansible_default_ipv4.address }}

{% if health_check_results is defined %}
HEALTH CHECK RESULTS:
- Uptime: {{ health_check_results.uptime }}
- Kernel: {{ health_check_results.kernel }}
- Memory: {{ health_check_results.memory_status }}
- Disk: {{ health_check_results.disk_status }}
- Network: {{ health_check_results.network_status }}
- DNS: {{ health_check_results.dns_status }}
{% endif %}

SERVICES STATUS:
{% for service in critical_services %}
- {{ service.name }}: {{ ansible_facts.services[service.name + '.service']['state'] | upper }}
{% endfor %}

---
Report generated by Ansible automation
Subtask 3.5: Test Error Handling Playbook
Run the comprehensive error handling playbook:

ansible-playbook -i inventory.ini playbooks/reboot-with-error-handling.yml
To test error scenarios, you can temporarily modify the inventory to include an unreachable host:

# Add to inventory.ini for testing
[test_unreachable]
unreachable-host ansible_host=192.168.1.999
Then run:

ansible-playbook -i inventory.ini playbooks/reboot-with-error-handling.yml --limit test_unreachable
Task 4: Advanced Reboot Scenarios and Best Practices
Subtask 4.1: Create Rolling Reboot Playbook
Create a playbook for rolling reboots across multiple systems:

vim playbooks/rolling-reboot.yml
Add the following content:

---
- name: Rolling System Reboot with Load Balancer Integration
  hosts: web_servers
  become: yes
  gather_facts: yes
  serial: 1
  
  vars:
    load_balancer_api: "http://lb.company.com/api"
    health_check_url: "http://{{ ansible_default_ipv4.address }}/health"
    reboot_timeout: 300
    
  pre_tasks:
    - name: Remove server from load balancer
      uri:
        url: "{{ load_balancer_api }}/servers/{{ inventory_hostname }}/disable"
        method: POST
        status_code: 200
      delegate_to: localhost
      ignore_errors: yes
      
    - name: Wait for connections to drain
      wait_for:
        timeout: 30
      delegate_to: localhost
      
    - name: Verify no active connections
      shell: netstat -an | grep :80 | grep ESTABLISHED | wc -l
      register: active_connections
      
    - name: Display connection count
      debug:
        msg: "Active connections before reboot: {{ active_connections.stdout }}"
  
  tasks:
    - name: Perform graceful reboot
      reboot:
        reboot_timeout: "{{ reboot_timeout }}"
        pre_reboot_delay: 10
        post_reboot_delay: 30
        test_command: "curl -f {{ health_check_url }}"
      register: reboot_result
      
  post_tasks:
    - name: Verify application health
      uri:
        url: "{{ health_check_url }}"
        method: GET
        status_code: 200
      register: health_check
      retries: 5
      delay: 10
      
    - name: Re-enable server in load balancer
      uri:
        url: "{{ load_balancer_api }}/servers/{{ inventory_hostname }}/enable"
        method: POST
        status_code: 200
      delegate_to: localhost
      when: health_check is succeeded
      
    - name: Wait before proceeding to next server
      wait_for:
        timeout: 60
      delegate_to: localhost
Subtask 4.2: Create Maintenance Window Playbook
Create a playbook that respects maintenance windows:

vim playbooks/scheduled-reboot.yml
Add the following content:

---
- name: Scheduled Maintenance Reboot
  hosts: managed_nodes
  become: yes
  gather_facts: yes
  
  vars:
    maintenance_start: "02:00"
    maintenance_end: "04:00"
    timezone: "America/New_York"
    
  pre_tasks:
    - name: Get current time
      setup:
        filter: ansible_date_time
        
    - name: Check if within maintenance window
      set_fact:
        in_maintenance_window: "{{ 
          (ansible_date_time.hour | int >= maintenance_start.split(':')[0] | int) and 
          (ansible_date_time.hour | int < maintenance_end.split(':')[0] | int) 
        }}"
        
    - name: Display maintenance window status
      debug:
        msg: |
          Current time: {{ ansible_date_time.time }}
          Maintenance window: {{ maintenance_start }} - {{ maintenance_end }}
          In window: {{ in_maintenance_window }}
          
    - name: Skip reboot if outside maintenance window
      meta: end_host
      when: not in_maintenance_window
      
    - name: Confirm maintenance window
      debug:
        msg: "Proceeding with reboot during maintenance window"
  
  tasks:
    - name: Create maintenance log entry
      lineinfile:
        path: /var/log/maintenance.log
        line: "{{ ansible_date_time.iso8601 }} - Maintenance reboot started"
        create: yes
        
    - name: Notify users of impending reboot
      command: wall "System will reboot in 2 minutes for scheduled maintenance"
      
    - name: Wait before reboot
      wait_for:
        timeout: 120
      delegate_to: localhost
      
    - name: Perform maintenance reboot
      reboot:
        reboot_timeout: 600
        msg: "Scheduled maintenance reboot"
      register: maintenance_reboot
      
    - name: Log maintenance completion
      lineinfile:
        path: /var/log/maintenance.log
        line: "{{ ansible_date_time.iso8601 }} - Maintenance reboot completed in {{ maintenance_reboot.elapsed }} seconds"
Subtask 4.3: Test Advanced Scenarios
Create a test inventory for advanced scenarios:

vim advanced-inventory.ini
Add the following content:

[web_servers]
web1 ansible_host=192.168.1.20
web2 ansible_host=192.168.1.21

[database_servers]
db1 ansible_host=192.168.1.30

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
Run the rolling reboot playbook:

ansible-playbook -i advanced-inventory.ini playbooks/rolling-reboot.yml
Run the scheduled maintenance playbook:

ansible-playbook -i advanced-inventory.ini playbooks/scheduled-reboot.yml
Troubleshooting Common Issues
Issue 1: Reboot Timeout Errors
Problem: Systems taking longer than expected to reboot

Solution:

- name: Increase reboot timeout for slow systems
  reboot:
    reboot_timeout: 900  # 15 minutes
    connect_timeout: 20
    post_reboot_delay: 60
Issue 2: Service Validation Failures
Problem: Services not starting properly after reboot

Solution:

- name: Force service restart if not running
  systemd:
    name: "{{ item }}"
    state: restarted
    enabled: yes
  loop: "{{ critical_services }}"
  register: service_restart
  until: service_restart is succeeded
  retries: 3
  delay: 10
Issue 3: Network Connectivity Issues
Problem: Network not available immediately after reboot

Solution:

- name: Wait for network connectivity
  wait_for:
    host: "8.8.8.8"
    port: 53
    timeout: 120
  delegate_to: "{{ inventory_hostname }}"
Issue 4: SSH Connection Problems
Problem: SSH service not responding after reboot

Solution:

- name: Custom SSH connectivity test
  reboot:
    test_command: "ssh -o ConnectTimeout=5 {{ ansible_user }}@{{ ansible_host }} 'echo SSH_OK'"
    connect_timeout: 30
Best Practices Summary
Always use serial execution for critical systems to avoid simultaneous outages
Implement proper error handling with retry logic and fallback procedures
Validate system state both before and after reboots
Maintain detailed logs of all reboot activities
Test playbooks in non-production environments first
Use maintenance windows for scheduled reboots
Implement health checks to verify system functionality
Have rollback procedures ready in case of failures
Conclusion
In this lab, you have successfully learned how to:

Create robust Ansible playbooks for automated system reboots using the reboot module
Implement comprehensive validation procedures to verify system health after reboots
Design sophisticated error handling mechanisms to deal with failed reboot scenarios
Apply advanced techniques like rolling reboots and maintenance window scheduling
Use Ansible facts and service modules to validate system configurations post-reboot
These skills are essential for maintaining large-scale infrastructure where manual reboots are impractical and automated, reliable reboot procedures are critical for system maintenance, security updates, and operational continuity. The error handling and validation techniques you've learned ensure that your automation is production-ready and can handle real-world scenarios where systems may not behave as expected.

The playbooks and techniques demonstrated in this lab provide a solid foundation for implementing automated maintenance procedures in enterprise environments, supporting both planned maintenance activities and emergency response scenarios while maintaining system reliability and minimizing downtime.
