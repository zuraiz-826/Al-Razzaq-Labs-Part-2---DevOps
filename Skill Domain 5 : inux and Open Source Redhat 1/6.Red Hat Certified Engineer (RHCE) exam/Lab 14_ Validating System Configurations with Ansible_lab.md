Lab 14: Validating System Configurations with Ansible
Objectives
By the end of this lab, you will be able to:

Use Ansible facts to gather and validate system information
Implement assertions to check configuration consistency across multiple hosts
Create playbooks that validate disk usage and system configurations
Implement proper error handling for configuration discrepancies
Generate reports for configuration validation results
Apply best practices for infrastructure validation using Ansible
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Previous experience with Ansible playbooks and modules
Understanding of system administration concepts (disk usage, services, configurations)
Knowledge of Jinja2 templating basics
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: 3 target servers (node1, node2, node3) for configuration validation
All necessary tools and dependencies pre-configured
Task 1: Write a Playbook to Validate Disk Usage with Ansible Facts
Subtask 1.1: Understanding Ansible Facts for System Validation
First, let's explore what Ansible facts are available for disk usage validation.

Connect to your control node and navigate to the working directory:
cd /home/ansible
mkdir lab14-validation
cd lab14-validation
Create a fact-gathering playbook to understand available disk information:
nano gather-facts.yml
Add the following content to explore disk-related facts:
---
- name: Gather and Display Disk Facts
  hosts: all
  gather_facts: yes
  tasks:
    - name: Display all disk-related facts
      debug:
        msg: |
          Hostname: {{ ansible_hostname }}
          Total Memory: {{ ansible_memtotal_mb }} MB
          Available Disk Space: {{ ansible_mounts }}
          Architecture: {{ ansible_architecture }}
          OS Family: {{ ansible_os_family }}
          
    - name: Show specific mount point information
      debug:
        msg: |
          Mount Point: {{ item.mount }}
          Device: {{ item.device }}
          Filesystem: {{ item.fstype }}
          Size: {{ item.size_total | human_readable }}
          Available: {{ item.size_available | human_readable }}
          Used: {{ ((item.size_total - item.size_available) / item.size_total * 100) | round(2) }}%
      loop: "{{ ansible_mounts }}"
      when: item.mount == "/"
Run the fact-gathering playbook:
ansible-playbook -i inventory gather-facts.yml
Subtask 1.2: Create Disk Usage Validation Playbook
Now let's create a comprehensive playbook to validate disk usage across all managed nodes.

Create the main disk validation playbook:
nano validate-disk-usage.yml
Add the following comprehensive validation logic:
---
- name: Validate System Disk Usage
  hosts: all
  gather_facts: yes
  vars:
    # Define thresholds for validation
    disk_usage_warning_threshold: 80
    disk_usage_critical_threshold: 90
    minimum_free_space_gb: 2
    
  tasks:
    - name: Initialize validation results
      set_fact:
        validation_results: []
        failed_validations: []
        
    - name: Validate root filesystem disk usage
      block:
        - name: Calculate root filesystem usage percentage
          set_fact:
            root_mount_info: "{{ ansible_mounts | selectattr('mount', 'equalto', '/') | first }}"
            
        - name: Calculate usage percentage
          set_fact:
            root_usage_percent: "{{ ((root_mount_info.size_total - root_mount_info.size_available) / root_mount_info.size_total * 100) | round(2) }}"
            root_free_gb: "{{ (root_mount_info.size_available / 1024 / 1024 / 1024) | round(2) }}"
            
        - name: Add disk usage validation result
          set_fact:
            validation_results: "{{ validation_results + [validation_item] }}"
          vars:
            validation_item:
              host: "{{ ansible_hostname }}"
              check: "Root Disk Usage"
              status: "{{ 'CRITICAL' if (root_usage_percent | float) > disk_usage_critical_threshold else ('WARNING' if (root_usage_percent | float) > disk_usage_warning_threshold else 'OK') }}"
              value: "{{ root_usage_percent }}%"
              threshold: "Warning: {{ disk_usage_warning_threshold }}%, Critical: {{ disk_usage_critical_threshold }}%"
              free_space: "{{ root_free_gb }} GB"
              
        - name: Check if disk usage exceeds critical threshold
          fail:
            msg: |
              CRITICAL: Disk usage on {{ ansible_hostname }} is {{ root_usage_percent }}%
              This exceeds the critical threshold of {{ disk_usage_critical_threshold }}%
              Free space remaining: {{ root_free_gb }} GB
          when: (root_usage_percent | float) > disk_usage_critical_threshold
          
        - name: Warn about high disk usage
          debug:
            msg: |
              WARNING: Disk usage on {{ ansible_hostname }} is {{ root_usage_percent }}%
              This exceeds the warning threshold of {{ disk_usage_warning_threshold }}%
              Free space remaining: {{ root_free_gb }} GB
          when: 
            - (root_usage_percent | float) > disk_usage_warning_threshold
            - (root_usage_percent | float) <= disk_usage_critical_threshold
            
        - name: Validate minimum free space requirement
          fail:
            msg: |
              CRITICAL: Free space on {{ ansible_hostname }} is {{ root_free_gb }} GB
              This is below the minimum requirement of {{ minimum_free_space_gb }} GB
          when: (root_free_gb | float) < minimum_free_space_gb
          
      rescue:
        - name: Record failed validation
          set_fact:
            failed_validations: "{{ failed_validations + [failure_item] }}"
          vars:
            failure_item:
              host: "{{ ansible_hostname }}"
              error: "{{ ansible_failed_result.msg }}"
              timestamp: "{{ ansible_date_time.iso8601 }}"
              
        - name: Continue with other validations despite failure
          debug:
            msg: "Validation failed for {{ ansible_hostname }}, but continuing with other checks"
            
    - name: Validate additional mount points
      block:
        - name: Check other significant mount points
          set_fact:
            mount_validation: "{{ mount_validation | default([]) + [mount_item] }}"
          vars:
            mount_usage_percent: "{{ ((item.size_total - item.size_available) / item.size_total * 100) | round(2) }}"
            mount_item:
              mount_point: "{{ item.mount }}"
              usage_percent: "{{ mount_usage_percent }}"
              free_gb: "{{ (item.size_available / 1024 / 1024 / 1024) | round(2) }}"
              status: "{{ 'CRITICAL' if (mount_usage_percent | float) > disk_usage_critical_threshold else ('WARNING' if (mount_usage_percent | float) > disk_usage_warning_threshold else 'OK') }}"
          loop: "{{ ansible_mounts }}"
          when: 
            - item.mount != "/"
            - item.fstype not in ['tmpfs', 'devtmpfs', 'proc', 'sysfs']
            - item.size_total > 1073741824  # Only check mounts larger than 1GB
            
        - name: Display additional mount point validations
          debug:
            msg: |
              Mount Point: {{ item.mount_point }}
              Usage: {{ item.usage_percent }}%
              Free Space: {{ item.free_gb }} GB
              Status: {{ item.status }}
          loop: "{{ mount_validation | default([]) }}"
          
      rescue:
        - name: Handle mount point validation errors
          debug:
            msg: "Error validating additional mount points on {{ ansible_hostname }}"
Create an inventory file for your managed nodes:
nano inventory
Add your managed nodes:
[webservers]
node1 ansible_host=10.0.1.10
node2 ansible_host=10.0.1.11

[databases]
node3 ansible_host=10.0.1.12

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=/home/ansible/.ssh/id_rsa
Run the disk usage validation playbook:
ansible-playbook -i inventory validate-disk-usage.yml
Task 2: Use Assertions to Check Configuration Consistency
Subtask 2.1: Create Configuration Consistency Validation
Let's create a playbook that uses assertions to validate configuration consistency across all managed nodes.

Create a configuration consistency playbook:
nano validate-config-consistency.yml
Add comprehensive configuration validation logic:
---
- name: Validate Configuration Consistency Across Hosts
  hosts: all
  gather_facts: yes
  vars:
    # Expected configuration standards
    expected_os_family: "RedHat"
    minimum_memory_mb: 1024
    required_services:
      - sshd
      - chronyd
    prohibited_services:
      - telnet
    expected_timezone: "UTC"
    minimum_cpu_cores: 1
    
  tasks:
    - name: Initialize consistency check results
      set_fact:
        consistency_results: []
        assertion_failures: []
        
    - name: Validate Operating System Consistency
      block:
        - name: Assert OS family consistency
          assert:
            that:
              - ansible_os_family == expected_os_family
            fail_msg: |
              OS Family mismatch on {{ ansible_hostname }}:
              Expected: {{ expected_os_family }}
              Actual: {{ ansible_os_family }}
            success_msg: "OS family validation passed for {{ ansible_hostname }}"
            
        - name: Record OS validation success
          set_fact:
            consistency_results: "{{ consistency_results + [os_result] }}"
          vars:
            os_result:
              host: "{{ ansible_hostname }}"
              check: "OS Family"
              status: "PASS"
              expected: "{{ expected_os_family }}"
              actual: "{{ ansible_os_family }}"
              
      rescue:
        - name: Record OS validation failure
          set_fact:
            assertion_failures: "{{ assertion_failures + [os_failure] }}"
          vars:
            os_failure:
              host: "{{ ansible_hostname }}"
              check: "OS Family"
              status: "FAIL"
              expected: "{{ expected_os_family }}"
              actual: "{{ ansible_os_family }}"
              error: "{{ ansible_failed_result.msg }}"
              
    - name: Validate Memory Requirements
      block:
        - name: Assert minimum memory requirement
          assert:
            that:
              - ansible_memtotal_mb >= minimum_memory_mb
            fail_msg: |
              Insufficient memory on {{ ansible_hostname }}:
              Required: {{ minimum_memory_mb }} MB
              Available: {{ ansible_memtotal_mb }} MB
            success_msg: "Memory requirement satisfied for {{ ansible_hostname }}"
            
        - name: Record memory validation success
          set_fact:
            consistency_results: "{{ consistency_results + [memory_result] }}"
          vars:
            memory_result:
              host: "{{ ansible_hostname }}"
              check: "Memory Requirement"
              status: "PASS"
              expected: "{{ minimum_memory_mb }} MB minimum"
              actual: "{{ ansible_memtotal_mb }} MB"
              
      rescue:
        - name: Record memory validation failure
          set_fact:
            assertion_failures: "{{ assertion_failures + [memory_failure] }}"
          vars:
            memory_failure:
              host: "{{ ansible_hostname }}"
              check: "Memory Requirement"
              status: "FAIL"
              expected: "{{ minimum_memory_mb }} MB minimum"
              actual: "{{ ansible_memtotal_mb }} MB"
              error: "{{ ansible_failed_result.msg }}"
              
    - name: Validate CPU Requirements
      block:
        - name: Assert minimum CPU cores
          assert:
            that:
              - ansible_processor_vcpus >= minimum_cpu_cores
            fail_msg: |
              Insufficient CPU cores on {{ ansible_hostname }}:
              Required: {{ minimum_cpu_cores }} cores minimum
              Available: {{ ansible_processor_vcpus }} cores
            success_msg: "CPU requirement satisfied for {{ ansible_hostname }}"
            
        - name: Record CPU validation success
          set_fact:
            consistency_results: "{{ consistency_results + [cpu_result] }}"
          vars:
            cpu_result:
              host: "{{ ansible_hostname }}"
              check: "CPU Cores"
              status: "PASS"
              expected: "{{ minimum_cpu_cores }} cores minimum"
              actual: "{{ ansible_processor_vcpus }} cores"
              
      rescue:
        - name: Record CPU validation failure
          set_fact:
            assertion_failures: "{{ assertion_failures + [cpu_failure] }}"
          vars:
            cpu_failure:
              host: "{{ ansible_hostname }}"
              check: "CPU Cores"
              status: "FAIL"
              expected: "{{ minimum_cpu_cores }} cores minimum"
              actual: "{{ ansible_processor_vcpus }} cores"
              error: "{{ ansible_failed_result.msg }}"
              
    - name: Validate Service Consistency
      block:
        - name: Gather service facts
          service_facts:
          
        - name: Assert required services are running
          assert:
            that:
              - ansible_facts.services[item + '.service'].state == 'running'
            fail_msg: |
              Required service {{ item }} is not running on {{ ansible_hostname }}
              Status: {{ ansible_facts.services[item + '.service'].state | default('not found') }}
            success_msg: "Service {{ item }} is running on {{ ansible_hostname }}"
          loop: "{{ required_services }}"
          when: (item + '.service') in ansible_facts.services
          
        - name: Record service validation results
          set_fact:
            consistency_results: "{{ consistency_results + [service_result] }}"
          vars:
            service_result:
              host: "{{ ansible_hostname }}"
              check: "Required Services"
              status: "PASS"
              services: "{{ required_services | join(', ') }}"
              
      rescue:
        - name: Record service validation failure
          set_fact:
            assertion_failures: "{{ assertion_failures + [service_failure] }}"
          vars:
            service_failure:
              host: "{{ ansible_hostname }}"
              check: "Required Services"
              status: "FAIL"
              error: "{{ ansible_failed_result.msg }}"
              
    - name: Validate Network Configuration Consistency
      block:
        - name: Assert hostname format consistency
          assert:
            that:
              - ansible_hostname | length > 0
              - ansible_hostname is match("^[a-zA-Z0-9-]+$")
            fail_msg: |
              Invalid hostname format on {{ ansible_hostname }}:
              Hostname should contain only alphanumeric characters and hyphens
            success_msg: "Hostname format is valid for {{ ansible_hostname }}"
            
        - name: Assert FQDN is properly configured
          assert:
            that:
              - ansible_fqdn != ansible_hostname
              - ansible_fqdn | length > ansible_hostname | length
            fail_msg: |
              FQDN not properly configured on {{ ansible_hostname }}:
              FQDN: {{ ansible_fqdn }}
              Hostname: {{ ansible_hostname }}
            success_msg: "FQDN is properly configured for {{ ansible_hostname }}"
          when: ansible_fqdn is defined
          
        - name: Record network validation success
          set_fact:
            consistency_results: "{{ consistency_results + [network_result] }}"
          vars:
            network_result:
              host: "{{ ansible_hostname }}"
              check: "Network Configuration"
              status: "PASS"
              hostname: "{{ ansible_hostname }}"
              fqdn: "{{ ansible_fqdn | default('N/A') }}"
              
      rescue:
        - name: Record network validation failure
          set_fact:
            assertion_failures: "{{ assertion_failures + [network_failure] }}"
          vars:
            network_failure:
              host: "{{ ansible_hostname }}"
              check: "Network Configuration"
              status: "FAIL"
              error: "{{ ansible_failed_result.msg }}"
Run the configuration consistency validation:
ansible-playbook -i inventory validate-config-consistency.yml
Subtask 2.2: Advanced Assertion Techniques
Let's create more sophisticated assertions for complex configuration validation.

Create an advanced assertions playbook:
nano advanced-assertions.yml
Add advanced validation logic:
---
- name: Advanced Configuration Assertions
  hosts: all
  gather_facts: yes
  vars:
    security_requirements:
      ssh_port: 22
      max_auth_tries: 3
      permit_root_login: false
    performance_thresholds:
      max_load_average: 2.0
      min_swap_mb: 512
      
  tasks:
    - name: Advanced Security Configuration Validation
      block:
        - name: Check SSH configuration file exists
          stat:
            path: /etc/ssh/sshd_config
          register: ssh_config_stat
          
        - name: Assert SSH config file exists and is readable
          assert:
            that:
              - ssh_config_stat.stat.exists
              - ssh_config_stat.stat.isreg
              - ssh_config_stat.stat.readable
            fail_msg: "SSH configuration file is missing or not readable on {{ ansible_hostname }}"
            success_msg: "SSH configuration file is accessible on {{ ansible_hostname }}"
            
        - name: Read SSH configuration
          slurp:
            src: /etc/ssh/sshd_config
          register: ssh_config_content
          
        - name: Parse SSH configuration
          set_fact:
            ssh_config_lines: "{{ (ssh_config_content.content | b64decode).split('\n') }}"
            
        - name: Validate SSH security settings
          assert:
            that:
              - ssh_config_lines | select('match', '^PermitRootLogin\\s+no') | list | length > 0 or
                ssh_config_lines | select('match', '^#PermitRootLogin\\s+no') | list | length == 0
            fail_msg: "Root login should be disabled in SSH configuration on {{ ansible_hostname }}"
            success_msg: "SSH root login is properly configured on {{ ansible_hostname }}"
            
    - name: System Performance Assertions
      block:
        - name: Get current load average
          shell: uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' '
          register: current_load
          changed_when: false
          
        - name: Assert load average is within acceptable range
          assert:
            that:
              - (current_load.stdout | float) <= performance_thresholds.max_load_average
            fail_msg: |
              High load average detected on {{ ansible_hostname }}:
              Current: {{ current_load.stdout }}
              Threshold: {{ performance_thresholds.max_load_average }}
            success_msg: "Load average is within acceptable range on {{ ansible_hostname }}"
            
        - name: Validate swap configuration
          assert:
            that:
              - ansible_swaptotal_mb >= performance_thresholds.min_swap_mb
            fail_msg: |
              Insufficient swap space on {{ ansible_hostname }}:
              Current: {{ ansible_swaptotal_mb }} MB
              Required: {{ performance_thresholds.min_swap_mb }} MB
            success_msg: "Swap space is adequately configured on {{ ansible_hostname }}"
          when: ansible_swaptotal_mb is defined
          
    - name: File System Consistency Validation
      block:
        - name: Validate critical directories exist
          stat:
            path: "{{ item }}"
          register: critical_dirs
          loop:
            - /etc
            - /var/log
            - /tmp
            - /home
            
        - name: Assert critical directories are present
          assert:
            that:
              - item.stat.exists
              - item.stat.isdir
            fail_msg: "Critical directory {{ item.item }} is missing on {{ ansible_hostname }}"
            success_msg: "Critical directory {{ item.item }} exists on {{ ansible_hostname }}"
          loop: "{{ critical_dirs.results }}"
          
        - name: Validate log directory permissions
          stat:
            path: /var/log
          register: log_dir_stat
          
        - name: Assert log directory has correct permissions
          assert:
            that:
              - log_dir_stat.stat.mode == '0755'
              - log_dir_stat.stat.uid == 0
              - log_dir_stat.stat.gid == 0
            fail_msg: |
              Incorrect permissions on /var/log directory on {{ ansible_hostname }}:
              Mode: {{ log_dir_stat.stat.mode }}
              Owner: {{ log_dir_stat.stat.uid }}:{{ log_dir_stat.stat.gid }}
            success_msg: "Log directory permissions are correct on {{ ansible_hostname }}"
Execute the advanced assertions playbook:
ansible-playbook -i inventory advanced-assertions.yml
Task 3: Implement Error Handling and Report Discrepancies
Subtask 3.1: Comprehensive Error Handling Implementation
Let's create a robust error handling system for our validation playbooks.

Create an error handling and reporting playbook:
nano validation-with-reporting.yml
Add comprehensive error handling and reporting logic:
---
- name: Comprehensive System Validation with Error Handling and Reporting
  hosts: all
  gather_facts: yes
  vars:
    validation_timestamp: "{{ ansible_date_time.iso8601 }}"
    report_directory: "/tmp/ansible-validation-reports"
    
  tasks:
    - name: Initialize validation tracking variables
      set_fact:
        validation_summary: []
        error_summary: []
        host_status: "UNKNOWN"
        total_checks: 0
        passed_checks: 0
        failed_checks: 0
        
    - name: Create report directory on control node
      file:
        path: "{{ report_directory }}"
        state: directory
        mode: '0755'
      delegate_to: localhost
      run_once: true
      
    - name: Disk Usage Validation with Error Handling
      block:
        - name: Increment total checks counter
          set_fact:
            total_checks: "{{ total_checks | int + 1 }}"
            
        - name: Get root filesystem information
          set_fact:
            root_fs: "{{ ansible_mounts | selectattr('mount', 'equalto', '/') | first }}"
            
        - name: Calculate disk usage percentage
          set_fact:
            disk_usage_percent: "{{ ((root_fs.size_total - root_fs.size_available) / root_fs.size_total * 100) | round(2) }}"
            
        - name: Validate disk usage is acceptable
          assert:
            that:
              - (disk_usage_percent | float) < 90
            fail_msg: "Disk usage {{ disk_usage_percent }}% exceeds 90% threshold"
            success_msg: "Disk usage {{ disk_usage_percent }}% is within acceptable limits"
            
        - name: Record successful disk validation
          set_fact:
            passed_checks: "{{ passed_checks | int + 1 }}"
            validation_summary: "{{ validation_summary + [disk_success] }}"
          vars:
            disk_success:
              check_name: "Disk Usage Validation"
              status: "PASS"
              details: "Usage: {{ disk_usage_percent }}%"
              timestamp: "{{ validation_timestamp }}"
              
      rescue:
        - name: Record disk validation failure
          set_fact:
            failed_checks: "{{ failed_checks | int + 1 }}"
            validation_summary: "{{ validation_summary + [disk_failure] }}"
            error_summary: "{{ error_summary + [disk_error] }}"
          vars:
            disk_failure:
              check_name: "Disk Usage Validation"
              status: "FAIL"
              details: "{{ ansible_failed_result.msg }}"
              timestamp: "{{ validation_timestamp }}"
            disk_error:
              error_type: "Disk Usage"
              error_message: "{{ ansible_failed_result.msg }}"
              host: "{{ ansible_hostname }}"
              timestamp: "{{ validation_timestamp }}"
              
    - name: Memory Validation with Error Handling
      block:
        - name: Increment total checks counter
          set_fact:
            total_checks: "{{ total_checks | int + 1 }}"
            
        - name: Validate minimum memory requirement
          assert:
            that:
              - ansible_memtotal_mb >= 1024
            fail_msg: "Available memory {{ ansible_memtotal_mb }}MB is below 1024MB requirement"
            success_msg: "Memory {{ ansible_memtotal_mb }}MB meets minimum requirements"
            
        - name: Record successful memory validation
          set_fact:
            passed_checks: "{{ passed_checks | int + 1 }}"
            validation_summary: "{{ validation_summary + [memory_success] }}"
          vars:
            memory_success:
              check_name: "Memory Validation"
              status: "PASS"
              details: "Available: {{ ansible_memtotal_mb }}MB"
              timestamp: "{{ validation_timestamp }}"
              
      rescue:
        - name: Record memory validation failure
          set_fact:
            failed_checks: "{{ failed_checks | int + 1 }}"
            validation_summary: "{{ validation_summary + [memory_failure] }}"
            error_summary: "{{ error_summary + [memory_error] }}"
          vars:
            memory_failure:
              check_name: "Memory Validation"
              status: "FAIL"
              details: "{{ ansible_failed_result.msg }}"
              timestamp: "{{ validation_timestamp }}"
            memory_error:
              error_type: "Memory"
              error_message: "{{ ansible_failed_result.msg }}"
              host: "{{ ansible_hostname }}"
              timestamp: "{{ validation_timestamp }}"
              
    - name: Service Status Validation with Error Handling
      block:
        - name: Increment total checks counter
          set_fact:
            total_checks: "{{ total_checks | int + 1 }}"
            
        - name: Gather service facts
          service_facts:
          
        - name: Validate SSH service is running
          assert:
            that:
              - ansible_facts.services['sshd.service'].state == 'running'
            fail_msg: "SSH service is not running: {{ ansible_facts.services['sshd.service'].state | default('not found') }}"
            success_msg: "SSH service is running properly"
            
        - name: Record successful service validation
          set_fact:
            passed_checks: "{{ passed_checks | int + 1 }}"
            validation_summary: "{{ validation_summary + [service_success] }}"
          vars:
            service_success:
              check_name: "SSH Service Validation"
              status: "PASS"
              details: "SSH service is running"
              timestamp: "{{ validation_timestamp }}"
              
      rescue:
        - name: Record service validation failure
          set_fact:
            failed_checks: "{{ failed_checks | int + 1 }}"
            validation_summary: "{{ validation_summary + [service_failure] }}"
            error_summary: "{{ error_summary + [service_error] }}"
          vars:
            service_failure:
              check_name: "SSH Service Validation"
              status: "FAIL"
              details: "{{ ansible_failed_result.msg }}"
              timestamp: "{{ validation_timestamp }}"
            service_error:
              error_type: "Service"
              error_message: "{{ ansible_failed_result.msg }}"
              host: "{{ ansible_hostname }}"
              timestamp: "{{ validation_timestamp }}"
              
    - name: Network Connectivity Validation with Error Handling
      block:
        - name: Increment total checks counter
          set_fact:
            total_checks: "{{ total_checks | int + 1 }}"
            
        - name: Test network connectivity to control node
          wait_for:
            host: "{{ hostvars['localhost']['ansible_default_ipv4']['address'] | default('127.0.0.1') }}"
            port: 22
            timeout: 5
          delegate_to: "{{ inventory_hostname }}"
          
        - name: Record successful network validation
          set_fact:
            passed_checks: "{{ passed_checks | int + 1 }}"
            validation_summary: "{{ validation_summary + [network_success] }}"
          vars:
            network_success:
              check_name: "Network Connectivity"
              status: "PASS"
              details: "Network connectivity verified"
              timestamp: "{{ validation_timestamp }}"
              
      rescue:
        - name: Record network validation failure
          set_fact:
            failed_checks: "{{ failed_checks | int + 1 }}"
            validation_summary: "{{ validation_summary + [network_failure] }}"
            error_summary: "{{ error_summary + [network_error] }}"
          vars:
            network_failure:
              check_name: "Network Connectivity"
              status: "FAIL"
              details: "{{ ansible_failed_result.msg }}"
              timestamp: "{{ validation_timestamp }}"
            network_error:
              error_type: "Network"
              error_message: "{{ ansible_failed_result.msg }}"
              host: "{{ ansible_hostname }}"
              timestamp: "{{ validation_timestamp }}"
              
    - name: Determine overall host status
      set_fact:
        host_status: "{{ 'FAIL' if (failed_checks | int) > 0 else 'PASS' }}"
        success_rate: "{{ ((passed_checks | int) / (total_checks | int) * 100) | round(2) }}"
        
    - name: Display validation summary
      debug:
        msg: |
          ========================================
          VALIDATION SUMMARY for {{ ansible_hostname }}
          ========================================
          Overall Status: {{ host_status }}
          Total Checks: {{ total_checks }}
          Passed: {{ passed_checks }}
          Failed: {{ failed_checks }}
          Success Rate: {{ success_rate }}%
          Timestamp: {{ validation_timestamp }}
          ========================================
          
    - name: Generate detailed host report
      template:
        src: host_validation_report.j2
        dest: "{{ report_directory }}/{{ ansible_hostname }}_validation_report.json"
      delegate_to: localhost
      vars:
        report_data:
          hostname: "{{ ansible_hostname }}"
          ip_address: "{{ ansible_default_ipv4.address }}"
          overall_status: "{{ host_status }}"
          validation_timestamp: "{{ validation_timestamp }}"
          statistics:
            total_checks: "{{ total_checks }}"
            passed_checks: "{{ passed_checks }}"
            failed_checks: "{{ failed_checks }}"
            success_rate: "{{ success_rate }}"
          validation_results: "{{ validation_summary }}"
          errors: "{{ error_summary }}"
          system_info:
            os_family: "{{ ansible_os_family }}"
            os_version: "{{ ansible_distribution_version }}"
            architecture: "{{ ansible_architecture }}"
