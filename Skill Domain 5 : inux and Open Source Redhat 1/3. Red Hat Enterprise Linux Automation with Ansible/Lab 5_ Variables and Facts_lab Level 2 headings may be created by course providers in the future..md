Lab 5: Variables and Facts
Objectives
By the end of this lab, you will be able to:

• Define and use variables in Ansible playbooks • Gather system information using Ansible facts • Create conditional tasks based on gathered facts such as OS type and version • Implement variable substitution in playbook tasks • Understand the difference between user-defined variables and system facts • Apply best practices for variable naming and usage in automation scenarios

Prerequisites
Before starting this lab, you should have:

• Basic understanding of YAML syntax • Familiarity with Linux command line operations • Completion of previous Ansible labs (Lab 1-4) or equivalent knowledge • Understanding of basic Ansible playbook structure • Knowledge of SSH key-based authentication

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes: • Control Node: CentOS/RHEL 8 with Ansible pre-installed • Managed Nodes: Multiple target systems (CentOS, Ubuntu) for testing • Pre-configured SSH keys for seamless connectivity • Sample inventory files ready for use

Task 1: Understanding and Defining Variables in Playbooks
Subtask 1.1: Create a Basic Playbook with Variables
Variables in Ansible allow you to store and reuse values throughout your playbooks, making them more flexible and maintainable.

Step 1: Connect to your control node and create a new directory for this lab

mkdir ~/lab5-variables-facts
cd ~/lab5-variables-facts
Step 2: Create your first playbook with variables

nano variables-demo.yml
Step 3: Add the following content to demonstrate different ways to define variables

---
- name: Variables and Facts Demonstration
  hosts: all
  vars:
    # Simple string variable
    application_name: "WebServer"
    
    # Numeric variable
    port_number: 8080
    
    # Boolean variable
    enable_ssl: true
    
    # List variable
    required_packages:
      - httpd
      - firewalld
      - vim
    
    # Dictionary variable
    database_config:
      host: "localhost"
      port: 3306
      name: "webapp_db"
      user: "webapp_user"
  
  tasks:
    - name: Display application information
      debug:
        msg: "Setting up {{ application_name }} on port {{ port_number }}"
    
    - name: Show SSL status
      debug:
        msg: "SSL is {{ 'enabled' if enable_ssl else 'disabled' }}"
    
    - name: Display required packages
      debug:
        msg: "Installing package: {{ item }}"
      loop: "{{ required_packages }}"
    
    - name: Show database configuration
      debug:
        msg: "Database: {{ database_config.name }} on {{ database_config.host }}:{{ database_config.port }}"
Step 4: Run the playbook to see variables in action

ansible-playbook -i inventory variables-demo.yml
Subtask 1.2: Using External Variable Files
Step 1: Create a separate variable file for better organization

nano group_vars/all.yml
Step 2: Add variables to the external file

---
# Application Configuration
app_name: "MyWebApp"
app_version: "2.1.0"
app_port: 9090

# System Configuration
max_connections: 100
timeout_seconds: 30

# Environment Settings
environment: "production"
debug_mode: false

# File paths
log_directory: "/var/log/myapp"
config_directory: "/etc/myapp"
Step 3: Create a playbook that uses external variables

nano external-vars-demo.yml
---
- name: Using External Variables
  hosts: all
  
  tasks:
    - name: Display application details
      debug:
        msg: |
          Application: {{ app_name }}
          Version: {{ app_version }}
          Port: {{ app_port }}
          Environment: {{ environment }}
    
    - name: Show configuration paths
      debug:
        msg: |
          Log Directory: {{ log_directory }}
          Config Directory: {{ config_directory }}
          Max Connections: {{ max_connections }}
Step 4: Execute the playbook

ansible-playbook -i inventory external-vars-demo.yml
Task 2: Using Ansible Facts to Gather System Information
Subtask 2.1: Understanding Ansible Facts
Ansible facts are system properties automatically discovered by Ansible when connecting to managed hosts.

Step 1: Create a playbook to explore available facts

nano facts-exploration.yml
Step 2: Add content to gather and display facts

---
- name: Exploring Ansible Facts
  hosts: all
  gather_facts: yes
  
  tasks:
    - name: Display all available facts
      debug:
        var: ansible_facts
      when: inventory_hostname == groups['all'][0]  # Only show for first host
    
    - name: Show basic system information
      debug:
        msg: |
          Hostname: {{ ansible_hostname }}
          Operating System: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Architecture: {{ ansible_architecture }}
          Kernel: {{ ansible_kernel }}
          Total Memory: {{ ansible_memtotal_mb }} MB
          CPU Cores: {{ ansible_processor_cores }}
    
    - name: Display network information
      debug:
        msg: |
          IP Address: {{ ansible_default_ipv4.address }}
          Network Interface: {{ ansible_default_ipv4.interface }}
          Gateway: {{ ansible_default_ipv4.gateway }}
    
    - name: Show disk information
      debug:
        msg: |
          Mount Point: {{ item.mount }}
          Device: {{ item.device }}
          Filesystem: {{ item.fstype }}
          Size: {{ item.size_total | human_readable }}
          Available: {{ item.size_available | human_readable }}
      loop: "{{ ansible_mounts }}"
      when: item.mount == "/"
Step 3: Run the facts exploration playbook

ansible-playbook -i inventory facts-exploration.yml
Subtask 2.2: Creating Custom Facts
Step 1: Create a custom facts script on managed nodes

nano setup-custom-facts.yml
Step 2: Add playbook content to create custom facts

---
- name: Setup Custom Facts
  hosts: all
  become: yes
  
  tasks:
    - name: Create custom facts directory
      file:
        path: /etc/ansible/facts.d
        state: directory
        mode: '0755'
    
    - name: Create custom application facts
      copy:
        content: |
          #!/bin/bash
          echo "{"
          echo "  \"application\": {"
          echo "    \"name\": \"MyCustomApp\","
          echo "    \"version\": \"1.0.0\","
          echo "    \"status\": \"active\","
          echo "    \"last_updated\": \"$(date -I)\""
          echo "  }"
          echo "}"
        dest: /etc/ansible/facts.d/application.fact
        mode: '0755'
    
    - name: Create system health facts
      copy:
        content: |
          [system_health]
          uptime_days={{ ansible_uptime_seconds | int // 86400 }}
          load_average={{ ansible_loadavg.1m }}
          disk_usage_root={{ (ansible_mounts | selectattr('mount', 'equalto', '/') | first).size_used / (ansible_mounts | selectattr('mount', 'equalto', '/') | first).size_total * 100 | round(2) }}
        dest: /etc/ansible/facts.d/health.fact
        mode: '0644'
    
    - name: Refresh facts to include custom facts
      setup:
Step 3: Execute the custom facts setup

ansible-playbook -i inventory setup-custom-facts.yml
Step 4: Create a playbook to display custom facts

nano display-custom-facts.yml
---
- name: Display Custom Facts
  hosts: all
  
  tasks:
    - name: Show custom application facts
      debug:
        msg: |
          App Name: {{ ansible_local.application.application.name }}
          App Version: {{ ansible_local.application.application.version }}
          App Status: {{ ansible_local.application.application.status }}
          Last Updated: {{ ansible_local.application.application.last_updated }}
    
    - name: Show custom health facts
      debug:
        msg: |
          System Uptime: {{ ansible_local.health.system_health.uptime_days }} days
          Load Average: {{ ansible_local.health.system_health.load_average }}
          Root Disk Usage: {{ ansible_local.health.system_health.disk_usage_root }}%
Step 5: Run the custom facts display playbook

ansible-playbook -i inventory display-custom-facts.yml
Task 3: Modifying Tasks Based on Gathered Facts
Subtask 3.1: OS-Specific Task Execution
Step 1: Create a playbook that performs different actions based on OS type

nano os-specific-tasks.yml
Step 2: Add content for OS-specific operations

---
- name: OS-Specific Task Execution
  hosts: all
  become: yes
  vars:
    web_service_name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
    package_manager: "{{ 'yum' if ansible_os_family == 'RedHat' else 'apt' }}"
  
  tasks:
    - name: Display detected OS information
      debug:
        msg: |
          OS Family: {{ ansible_os_family }}
          Distribution: {{ ansible_distribution }}
          Version: {{ ansible_distribution_version }}
          Package Manager: {{ package_manager }}
          Web Service: {{ web_service_name }}
    
    - name: Install web server on RedHat family
      yum:
        name: httpd
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Install web server on Debian family
      apt:
        name: apache2
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: Configure firewall for RedHat systems
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      when: ansible_os_family == "RedHat"
      ignore_errors: yes
    
    - name: Configure UFW for Debian systems
      ufw:
        rule: allow
        port: '80'
        proto: tcp
      when: ansible_os_family == "Debian"
      ignore_errors: yes
    
    - name: Start and enable web service
      systemd:
        name: "{{ web_service_name }}"
        state: started
        enabled: yes
Step 3: Execute the OS-specific playbook

ansible-playbook -i inventory os-specific-tasks.yml
Subtask 3.2: Version-Based Conditional Tasks
Step 1: Create a playbook with version-specific logic

nano version-specific-tasks.yml
Step 2: Add version-based conditional content

---
- name: Version-Specific Task Execution
  hosts: all
  become: yes
  
  tasks:
    - name: Display version information
      debug:
        msg: |
          Distribution: {{ ansible_distribution }}
          Version: {{ ansible_distribution_version }}
          Major Version: {{ ansible_distribution_major_version }}
    
    - name: Install Python 3 on older CentOS versions
      yum:
        name: python3
        state: present
      when: 
        - ansible_distribution == "CentOS"
        - ansible_distribution_major_version | int < 8
    
    - name: Use dnf for newer RHEL/CentOS versions
      dnf:
        name: git
        state: present
      when:
        - ansible_os_family == "RedHat"
        - ansible_distribution_major_version | int >= 8
    
    - name: Use yum for older RHEL/CentOS versions
      yum:
        name: git
        state: present
      when:
        - ansible_os_family == "RedHat"
        - ansible_distribution_major_version | int < 8
    
    - name: Configure systemd service (modern systems)
      systemd:
        name: sshd
        state: started
        enabled: yes
      when: ansible_service_mgr == "systemd"
    
    - name: Configure service with service module (older systems)
      service:
        name: ssh
        state: started
        enabled: yes
      when: ansible_service_mgr != "systemd"
Step 3: Run the version-specific playbook

ansible-playbook -i inventory version-specific-tasks.yml
Subtask 3.3: Hardware-Based Task Modifications
Step 1: Create a playbook that adapts based on hardware specifications

nano hardware-based-tasks.yml
Step 2: Add hardware-aware task content

---
- name: Hardware-Based Task Modifications
  hosts: all
  become: yes
  vars:
    memory_gb: "{{ (ansible_memtotal_mb / 1024) | round(1) }}"
    is_low_memory: "{{ ansible_memtotal_mb < 2048 }}"
    is_multi_core: "{{ ansible_processor_cores > 1 }}"
  
  tasks:
    - name: Display hardware information
      debug:
        msg: |
          Total Memory: {{ memory_gb }} GB
          CPU Cores: {{ ansible_processor_cores }}
          Architecture: {{ ansible_architecture }}
          Low Memory System: {{ is_low_memory }}
          Multi-core System: {{ is_multi_core }}
    
    - name: Configure swap for low memory systems
      debug:
        msg: "Would configure additional swap space for low memory system"
      when: is_low_memory
    
    - name: Optimize for multi-core systems
      lineinfile:
        path: /etc/sysctl.conf
        line: "kernel.sched_migration_cost_ns = 5000000"
        create: yes
      when: is_multi_core
      notify: reload sysctl
    
    - name: Set conservative CPU governor for single core systems
      debug:
        msg: "Would set conservative CPU governor for single core system"
      when: not is_multi_core
    
    - name: Configure application based on available memory
      template:
        content: |
          # Application Configuration
          max_memory={{ (ansible_memtotal_mb * 0.7) | int }}m
          worker_processes={{ ansible_processor_cores if is_multi_core else 1 }}
          cache_size={{ (ansible_memtotal_mb * 0.1) | int }}m
        dest: /tmp/app_config.conf
    
    - name: Display generated configuration
      debug:
        msg: "Configuration file created based on system specifications"
  
  handlers:
    - name: reload sysctl
      command: sysctl -p
      ignore_errors: yes
Step 3: Execute the hardware-based playbook

ansible-playbook -i inventory hardware-based-tasks.yml
Task 4: Advanced Variable and Facts Usage
Subtask 4.1: Variable Precedence and Scope
Step 1: Create a comprehensive example showing variable precedence

nano variable-precedence.yml
Step 2: Add content demonstrating variable precedence

---
- name: Variable Precedence Demonstration
  hosts: all
  vars:
    environment: "playbook_level"
    database_host: "playbook.example.com"
    debug_level: "info"
  
  tasks:
    - name: Display variables from different sources
      debug:
        msg: |
          Environment: {{ environment }}
          Database Host: {{ database_host }}
          Debug Level: {{ debug_level }}
          Custom Variable: {{ custom_var | default('not_defined') }}
    
    - name: Set task-level variable
      set_fact:
        task_variable: "set_at_task_level"
        environment: "overridden_by_task"
    
    - name: Display updated variables
      debug:
        msg: |
          Environment (now): {{ environment }}
          Task Variable: {{ task_variable }}
    
    - name: Register command output as variable
      command: date +%Y-%m-%d
      register: current_date
    
    - name: Use registered variable
      debug:
        msg: "Today's date is: {{ current_date.stdout }}"
    
    - name: Combine variables with facts
      debug:
        msg: |
          System: {{ ansible_hostname }}
          Environment: {{ environment }}
          Date: {{ current_date.stdout }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
Step 3: Create host-specific variables

mkdir -p host_vars
nano host_vars/$(ansible all -i inventory --list-hosts | head -2 | tail -1).yml
Step 4: Add host-specific content

---
custom_var: "host_specific_value"
database_host: "host.specific.com"
special_config: true
Step 5: Run the precedence demonstration

ansible-playbook -i inventory variable-precedence.yml
Subtask 4.2: Dynamic Variable Creation
Step 1: Create a playbook with dynamic variable generation

nano dynamic-variables.yml
Step 2: Add dynamic variable content

---
- name: Dynamic Variable Creation
  hosts: all
  
  tasks:
    - name: Create dynamic variables based on facts
      set_fact:
        system_info: |
          {{ ansible_hostname }}_{{ ansible_distribution | lower }}_{{ ansible_distribution_major_version }}
        memory_category: "{{ 'high' if ansible_memtotal_mb > 4096 else 'medium' if ansible_memtotal_mb > 2048 else 'low' }}"
        cpu_category: "{{ 'multi' if ansible_processor_cores > 1 else 'single' }}"
        system_profile: "{{ memory_category }}_memory_{{ cpu_category }}_cpu"
    
    - name: Display dynamic variables
      debug:
        msg: |
          System Info: {{ system_info }}
          Memory Category: {{ memory_category }}
          CPU Category: {{ cpu_category }}
          System Profile: {{ system_profile }}
    
    - name: Create configuration based on system profile
      set_fact:
        app_config:
          max_connections: "{{ 100 if system_profile.startswith('high') else 50 if system_profile.startswith('medium') else 25 }}"
          worker_processes: "{{ ansible_processor_cores if cpu_category == 'multi' else 1 }}"
          cache_enabled: "{{ memory_category != 'low' }}"
    
    - name: Display generated configuration
      debug:
        msg: |
          Max Connections: {{ app_config.max_connections }}
          Worker Processes: {{ app_config.worker_processes }}
          Cache Enabled: {{ app_config.cache_enabled }}
    
    - name: Generate unique identifier
      set_fact:
        unique_id: "{{ ansible_hostname }}_{{ ansible_date_time.epoch }}"
    
    - name: Show unique identifier
      debug:
        msg: "Generated unique ID: {{ unique_id }}"
Step 3: Execute the dynamic variables playbook

ansible-playbook -i inventory dynamic-variables.yml
Troubleshooting Common Issues
Issue 1: Variable Not Found Errors
Problem: Playbook fails with "variable not defined" errors

Solution: Use default filters and check variable names

- name: Safe variable usage
  debug:
    msg: "Value: {{ potentially_undefined_var | default('default_value') }}"
Issue 2: Facts Not Available
Problem: Ansible facts are not accessible in tasks

Solution: Ensure gather_facts: yes is set (it's the default)

---
- name: Playbook with explicit fact gathering
  hosts: all
  gather_facts: yes  # Explicitly enable fact gathering
Issue 3: Incorrect Variable Precedence
Problem: Variables are not using expected values

Solution: Understand and verify variable precedence order:

Extra vars (command line -e)
Task vars
Block vars
Role and include vars
Play vars
Host facts
Registered vars
Set_facts
Host vars
Group vars
Role defaults
Issue 4: Type Conversion Issues
Problem: Variables are treated as strings when numbers are expected

Solution: Use filters for type conversion

- name: Convert string to integer
  debug:
    msg: "Port number: {{ port_string | int }}"
Verification and Testing
Step 1: Create a comprehensive test playbook
nano lab5-verification.yml
---
- name: Lab 5 Verification Test
  hosts: all
  vars:
    test_variable: "lab5_test"
    test_number: 42
  
  tasks:
    - name: Test 1 - Variable Definition
      assert:
        that:
          - test_variable == "lab5_test"
          - test_number == 42
        success_msg: "✓ Variable definition test passed"
        fail_msg: "✗ Variable definition test failed"
    
    - name: Test 2 - Facts Gathering
      assert:
        that:
          - ansible_hostname is defined
          - ansible_distribution is defined
          - ansible_memtotal_mb is defined
        success_msg: "✓ Facts gathering test passed"
        fail_msg: "✗ Facts gathering test failed"
    
    - name: Test 3 - Conditional Logic
      set_fact:
        os_test_passed: true
      when: ansible_os_family in ['RedHat', 'Debian']
    
    - name: Verify conditional test
      assert:
        that:
          - os_test_passed is defined
        success_msg: "✓ Conditional logic test passed"
        fail_msg: "✗ Conditional logic test failed"
    
    - name: Test 4 - Variable Combination
      debug:
        msg: "System {{ ansible_hostname }} running {{ ansible_distribution }} with test value {{ test_variable }}"
    
    - name: Final verification message
      debug:
        msg: "🎉 All Lab 5 tests completed successfully!"
Step 2: Run the verification test
ansible-playbook -i inventory lab5-verification.yml
Conclusion
Congratulations! You have successfully completed Lab 5: Variables and Facts. In this lab, you have accomplished the following:

Key Achievements:

• Variable Mastery: You learned how to define variables in multiple ways - within playbooks, in external files, and dynamically during execution. This skill is essential for creating flexible and reusable automation code.

• Facts Utilization: You discovered how to gather and use system facts to make intelligent decisions in your playbooks. This capability allows your automation to adapt to different environments automatically.

• Conditional Logic: You implemented conditional tasks based on operating system type, version, and hardware specifications. This makes your playbooks portable across different systems.

• Advanced Techniques: You explored variable precedence, dynamic variable creation, and custom facts, giving you the tools to handle complex automation scenarios.

Why This Matters:

Variables and facts are the foundation of intelligent automation. In real-world scenarios, you'll manage diverse environments with different operating systems, hardware configurations, and requirements. The skills you've learned enable you to:

Write automation that adapts to different environments
Reduce code duplication through variable reuse
Make data-driven decisions in your automation workflows
Create maintainable and scalable automation solutions
Next Steps:

With these foundational skills in variables and facts, you're ready to tackle more advanced Ansible concepts like templates, roles, and complex conditional logic. These building blocks will serve you well as you progress toward Red Hat Enterprise Linux Automation with Ansible certification and real-world automation challenges.

The ability to create adaptive, intelligent automation is what separates basic scripting from professional infrastructure automation. You now have the tools to build automation that thinks and adapts - a crucial skill for any modern IT professional.
