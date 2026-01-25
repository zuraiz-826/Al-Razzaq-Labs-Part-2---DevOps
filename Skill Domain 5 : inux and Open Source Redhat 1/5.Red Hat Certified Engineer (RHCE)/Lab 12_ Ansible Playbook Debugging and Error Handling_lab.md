Lab 12: Ansible Playbook Debugging and Error Handling
Objectives
By the end of this lab, you will be able to:

Implement debug and fail modules to capture output and handle errors in Ansible playbooks
Use check_mode to perform dry runs and validate playbook execution without making changes
Learn how to handle errors gracefully using block and rescue constructs
Troubleshoot common Ansible playbook issues using built-in debugging features
Apply error handling best practices in production Ansible environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Ansible concepts (playbooks, tasks, modules)
Familiarity with YAML syntax
Experience writing and running simple Ansible playbooks
Knowledge of Linux command line operations
Understanding of SSH key-based authentication
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install Ansible - everything is ready to use.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: Two target servers (node1 and node2) configured for Ansible management
Pre-configured SSH keys and inventory files
Task 1: Implement Debug and Fail Modules
Subtask 1.1: Understanding the Debug Module
The debug module is essential for troubleshooting playbooks by displaying variable values and custom messages.

Connect to your control node and navigate to the working directory:
cd /home/ansible
mkdir lab12-debugging
cd lab12-debugging
Create a basic debug playbook to understand how debug works:
cat > debug_basics.yml << 'EOF'
---
- name: Debug Module Basics
  hosts: localhost
  gather_facts: yes
  vars:
    custom_message: "Hello from Ansible debugging lab"
    server_count: 3
    
  tasks:
    - name: Display a simple debug message
      debug:
        msg: "This is a basic debug message"
    
    - name: Display variable content
      debug:
        var: custom_message
    
    - name: Display multiple variables
      debug:
        msg: "Server count is {{ server_count }} and message is {{ custom_message }}"
    
    - name: Display system facts
      debug:
        var: ansible_hostname
    
    - name: Display facts with custom formatting
      debug:
        msg: "Running on {{ ansible_hostname }} with {{ ansible_processor_cores }} CPU cores"
EOF
Run the debug playbook:
ansible-playbook debug_basics.yml
Observe the output and note how different debug formats display information.
Subtask 1.2: Advanced Debug Techniques
Create an advanced debug playbook with conditional debugging:
cat > advanced_debug.yml << 'EOF'
---
- name: Advanced Debug Techniques
  hosts: localhost
  gather_facts: yes
  vars:
    debug_mode: true
    environment: "development"
    services:
      - name: "web"
        port: 80
        status: "running"
      - name: "database"
        port: 3306
        status: "stopped"
    
  tasks:
    - name: Debug only when debug_mode is enabled
      debug:
        msg: "Debug mode is active - Environment: {{ environment }}"
      when: debug_mode
    
    - name: Display complex data structures
      debug:
        var: services
    
    - name: Loop through services with debug
      debug:
        msg: "Service {{ item.name }} on port {{ item.port }} is {{ item.status }}"
      loop: "{{ services }}"
    
    - name: Debug with verbosity levels
      debug:
        msg: "This message appears only with -v flag"
        verbosity: 1
    
    - name: Debug with higher verbosity
      debug:
        msg: "This message appears only with -vv flag"
        verbosity: 2
EOF
Run with different verbosity levels:
# Normal run
ansible-playbook advanced_debug.yml

# With verbose output
ansible-playbook advanced_debug.yml -v

# With higher verbosity
ansible-playbook advanced_debug.yml -vv
Subtask 1.3: Implementing the Fail Module
Create a playbook demonstrating the fail module:
cat > fail_module.yml << 'EOF'
---
- name: Fail Module Implementation
  hosts: localhost
  gather_facts: yes
  vars:
    required_memory_gb: 4
    max_cpu_usage: 80
    
  tasks:
    - name: Check if system has enough memory
      fail:
        msg: "System has insufficient memory. Required: {{ required_memory_gb }}GB"
      when: (ansible_memtotal_mb / 1024) < required_memory_gb
    
    - name: Validate environment variable
      fail:
        msg: "ENVIRONMENT variable must be set to 'production' or 'development'"
      when: 
        - ansible_env.ENVIRONMENT is defined
        - ansible_env.ENVIRONMENT not in ['production', 'development']
    
    - name: Check for required packages (simulation)
      set_fact:
        package_installed: false
    
    - name: Fail if required package is missing
      fail:
        msg: "Critical package is not installed. Please install before proceeding."
      when: not package_installed
    
    - name: This task won't execute due to previous failure
      debug:
        msg: "This message should not appear"
EOF
Run the fail module playbook:
ansible-playbook fail_module.yml
Create a conditional fail example:
cat > conditional_fail.yml << 'EOF'
---
- name: Conditional Fail Examples
  hosts: localhost
  vars:
    app_version: "1.2.3"
    min_version: "1.3.0"
    user_role: "admin"
    
  tasks:
    - name: Version check with custom failure
      block:
        - name: Compare versions
          set_fact:
            version_check: "{{ app_version is version(min_version, '>=') }}"
        
        - name: Fail if version is too old
          fail:
            msg: |
              Application version {{ app_version }} is below minimum required version {{ min_version }}.
              Please upgrade before continuing.
          when: not version_check
      
    - name: Role-based access control
      fail:
        msg: "Access denied. Only admin users can perform this operation."
      when: user_role != "admin"
    
    - name: Success message
      debug:
        msg: "All validation checks passed successfully!"
EOF
Test the conditional fail:
ansible-playbook conditional_fail.yml
Task 2: Use Check Mode for Dry Runs
Subtask 2.1: Understanding Check Mode
Check mode allows you to see what changes would be made without actually executing them.

Create a playbook that makes system changes:
cat > system_changes.yml << 'EOF'
---
- name: System Configuration Changes
  hosts: node1
  become: yes
  
  tasks:
    - name: Install a package
      yum:
        name: htop
        state: present
    
    - name: Create a configuration file
      copy:
        content: |
          # Application Configuration
          debug_mode=true
          log_level=info
          max_connections=100
        dest: /etc/myapp.conf
        mode: '0644'
    
    - name: Create a system user
      user:
        name: appuser
        system: yes
        shell: /bin/bash
        home: /opt/appuser
    
    - name: Start and enable a service
      systemd:
        name: chronyd
        state: started
        enabled: yes
    
    - name: Display completion message
      debug:
        msg: "System configuration completed successfully"
EOF
Run in check mode (dry run):
ansible-playbook system_changes.yml --check
Run in check mode with diff to see detailed changes:
ansible-playbook system_changes.yml --check --diff
Compare with actual execution:
ansible-playbook system_changes.yml
Subtask 2.2: Check Mode with Custom Logic
Create a playbook with check mode awareness:
cat > check_mode_aware.yml << 'EOF'
---
- name: Check Mode Aware Playbook
  hosts: localhost
  
  tasks:
    - name: Display mode information
      debug:
        msg: "Running in {{ 'CHECK' if ansible_check_mode else 'NORMAL' }} mode"
    
    - name: Task that behaves differently in check mode
      debug:
        msg: "This would create a backup file"
      when: ansible_check_mode
    
    - name: Actual file creation (skipped in check mode)
      copy:
        content: "Production data"
        dest: /tmp/production_file.txt
      when: not ansible_check_mode
    
    - name: Always run this task regardless of mode
      debug:
        msg: "This task always runs"
      check_mode: no
    
    - name: Never run this task in check mode
      debug:
        msg: "This only runs in normal mode"
      check_mode: no
      when: not ansible_check_mode
EOF
Test check mode behavior:
# Run in check mode
ansible-playbook check_mode_aware.yml --check

# Run in normal mode
ansible-playbook check_mode_aware.yml
Subtask 2.3: Selective Check Mode
Create a playbook with mixed check mode behavior:
cat > selective_check.yml << 'EOF'
---
- name: Selective Check Mode Example
  hosts: localhost
  
  tasks:
    - name: Always gather information (runs in check mode)
      setup:
      check_mode: no
    
    - name: Display system info (always runs)
      debug:
        msg: "System: {{ ansible_hostname }}, OS: {{ ansible_distribution }}"
      check_mode: no
    
    - name: Simulate file creation
      file:
        path: /tmp/test_file.txt
        state: touch
        mode: '0644'
    
    - name: Check if file exists (always runs)
      stat:
        path: /tmp/test_file.txt
      register: file_check
      check_mode: no
    
    - name: Report file status
      debug:
        msg: "File exists: {{ file_check.stat.exists }}"
      check_mode: no
EOF
Execute with check mode:
ansible-playbook selective_check.yml --check -v
Task 3: Error Handling with Block and Rescue
Subtask 3.1: Basic Block and Rescue Structure
Create a playbook demonstrating basic error handling:
cat > basic_error_handling.yml << 'EOF'
---
- name: Basic Error Handling with Block and Rescue
  hosts: localhost
  
  tasks:
    - name: Error handling example
      block:
        - name: Task that might fail
          command: /bin/false
          register: result
        
        - name: This won't execute due to previous failure
          debug:
            msg: "This message won't appear"
      
      rescue:
        - name: Handle the error
          debug:
            msg: "An error occurred, but we're handling it gracefully"
        
        - name: Log error details
          debug:
            msg: "Error handling activated for failed task"
      
      always:
        - name: This always runs
          debug:
            msg: "Cleanup or final actions go here"
    
    - name: Continue with next task
      debug:
        msg: "Playbook continues after error handling"
EOF
Run the error handling playbook:
ansible-playbook basic_error_handling.yml
Subtask 3.2: Advanced Error Handling Scenarios
Create a comprehensive error handling playbook:
cat > advanced_error_handling.yml << 'EOF'
---
- name: Advanced Error Handling Scenarios
  hosts: localhost
  vars:
    retry_count: 3
    
  tasks:
    - name: File operations with error handling
      block:
        - name: Attempt to read a non-existent file
          slurp:
            src: /tmp/nonexistent_file.txt
          register: file_content
        
        - name: Process file content
          debug:
            msg: "File content: {{ file_content.content | b64decode }}"
      
      rescue:
        - name: Handle file not found error
          debug:
            msg: "File not found, creating default file"
        
        - name: Create the missing file
          copy:
            content: "Default configuration content"
            dest: /tmp/nonexistent_file.txt
        
        - name: Retry reading the file
          slurp:
            src: /tmp/nonexistent_file.txt
          register: file_content_retry
        
        - name: Display recovered content
          debug:
            msg: "Recovered content: {{ file_content_retry.content | b64decode }}"
      
      always:
        - name: Cleanup temporary files
          file:
            path: /tmp/nonexistent_file.txt
            state: absent
    
    - name: Service management with error handling
      block:
        - name: Attempt to start a non-existent service
          systemd:
            name: fake-service
            state: started
          become: yes
      
      rescue:
        - name: Handle service error
          debug:
            msg: "Service operation failed, implementing fallback"
        
        - name: Check available services
          command: systemctl list-units --type=service --state=active
          register: active_services
          become: yes
        
        - name: Display service count
          debug:
            msg: "Found {{ active_services.stdout_lines | length }} active services"
      
      always:
        - name: Log service operation attempt
          debug:
            msg: "Service operation completed with error handling"
EOF
Execute the advanced error handling:
ansible-playbook advanced_error_handling.yml
Subtask 3.3: Nested Error Handling and Recovery
Create a playbook with nested error handling:
cat > nested_error_handling.yml << 'EOF'
---
- name: Nested Error Handling and Recovery
  hosts: localhost
  vars:
    max_retries: 2
    
  tasks:
    - name: Multi-level error handling
      block:
        - name: Primary operation block
          block:
            - name: Attempt primary method
              command: /usr/bin/nonexistent-command
              register: primary_result
          
          rescue:
            - name: Primary method failed, trying alternative
              debug:
                msg: "Primary method failed, attempting alternative approach"
            
            - name: Alternative operation block
              block:
                - name: Attempt alternative method
                  command: /bin/false
                  register: alternative_result
              
              rescue:
                - name: Alternative method also failed
                  debug:
                    msg: "Alternative method failed, using fallback"
                
                - name: Fallback operation
                  debug:
                    msg: "Executing fallback procedure"
                  register: fallback_result
                
                - name: Set success flag for fallback
                  set_fact:
                    operation_successful: true
      
      rescue:
        - name: All methods failed
          debug:
            msg: "All recovery attempts failed, logging error"
        
        - name: Set failure flag
          set_fact:
            operation_successful: false
      
      always:
        - name: Report final status
          debug:
            msg: "Operation status: {{ 'SUCCESS' if operation_successful | default(false) else 'FAILED' }}"
    
    - name: Conditional continuation based on previous results
      debug:
        msg: "Continuing with next phase of operations"
      when: operation_successful | default(false)
    
    - name: Error notification
      debug:
        msg: "Sending error notification to administrators"
      when: not (operation_successful | default(false))
EOF
Run the nested error handling playbook:
ansible-playbook nested_error_handling.yml
Subtask 3.4: Real-World Error Handling Example
Create a practical error handling scenario:
cat > practical_error_handling.yml << 'EOF'
---
- name: Practical Error Handling - Web Server Setup
  hosts: node1
  become: yes
  vars:
    web_packages:
      - httpd
      - mod_ssl
    backup_packages:
      - nginx
    
  tasks:
    - name: Web server installation with fallback
      block:
        - name: Install Apache web server
          yum:
            name: "{{ web_packages }}"
            state: present
        
        - name: Start Apache service
          systemd:
            name: httpd
            state: started
            enabled: yes
        
        - name: Create web content
          copy:
            content: |
              <html>
                <head><title>Apache Server</title></head>
                <body><h1>Apache is running successfully!</h1></body>
              </html>
            dest: /var/www/html/index.html
        
        - name: Set web server type
          set_fact:
            web_server: "apache"
      
      rescue:
        - name: Apache installation failed, trying Nginx
          debug:
            msg: "Apache installation failed, falling back to Nginx"
        
        - name: Install Nginx as fallback
          yum:
            name: "{{ backup_packages }}"
            state: present
        
        - name: Start Nginx service
          systemd:
            name: nginx
            state: started
            enabled: yes
        
        - name: Create Nginx web content
          copy:
            content: |
              <html>
                <head><title>Nginx Server</title></head>
                <body><h1>Nginx is running as fallback!</h1></body>
              </html>
            dest: /usr/share/nginx/html/index.html
        
        - name: Set web server type
          set_fact:
            web_server: "nginx"
      
      always:
        - name: Display web server status
          debug:
            msg: "Web server setup completed using: {{ web_server | default('none') }}"
        
        - name: Check web server process
          command: "ps aux | grep {{ web_server | default('http') }}"
          register: web_process
          ignore_errors: yes
        
        - name: Display process information
          debug:
            var: web_process.stdout_lines
          when: web_process.rc == 0
EOF
Execute the practical error handling example:
ansible-playbook practical_error_handling.yml
Comprehensive Debugging Lab Exercise
Create a Complete Debugging Scenario
Create a comprehensive debugging playbook:
cat > complete_debugging_lab.yml << 'EOF'
---
- name: Complete Debugging and Error Handling Lab
  hosts: localhost
  gather_facts: yes
  vars:
    debug_enabled: true
    environment: "{{ ansible_env.ENVIRONMENT | default('development') }}"
    required_services:
      - name: "database"
        port: 3306
        critical: true
      - name: "cache"
        port: 6379
        critical: false
      - name: "web"
        port: 80
        critical: true
    
  tasks:
    - name: Environment validation and debugging
      block:
        - name: Display environment information
          debug:
            msg: |
              Environment: {{ environment }}
              Hostname: {{ ansible_hostname }}
              OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
              Memory: {{ (ansible_memtotal_mb / 1024) | round(1) }}GB
          when: debug_enabled
        
        - name: Validate environment setting
          fail:
            msg: "Invalid environment '{{ environment }}'. Must be 'development', 'staging', or 'production'"
          when: environment not in ['development', 'staging', 'production']
        
        - name: Check system resources
          block:
            - name: Memory check
              fail:
                msg: "Insufficient memory. Required: 2GB, Available: {{ (ansible_memtotal_mb / 1024) | round(1) }}GB"
              when: (ansible_memtotal_mb / 1024) < 2
            
            - name: Disk space check (simulation)
              set_fact:
                disk_usage: 85
            
            - name: Fail if disk usage too high
              fail:
                msg: "Disk usage too high: {{ disk_usage }}%"
              when: disk_usage > 90
          
          rescue:
            - name: Handle resource constraints
              debug:
                msg: "Resource constraints detected, adjusting configuration"
            
            - name: Set resource-aware configuration
              set_fact:
                optimized_config: true
        
        - name: Service validation loop
          include_tasks: service_check.yml
          loop: "{{ required_services }}"
          loop_control:
            loop_var: service
      
      rescue:
        - name: Handle validation errors
          debug:
            msg: "Validation failed, implementing recovery procedures"
        
        - name: Log error details
          debug:
            msg: "Error occurred during environment validation"
      
      always:
        - name: Generate validation report
          debug:
            msg: |
              Validation Summary:
              - Environment: {{ environment }}
              - Optimized Config: {{ optimized_config | default(false) }}
              - Timestamp: {{ ansible_date_time.iso8601 }}

    - name: Final status check
      debug:
        msg: "Lab completed successfully - all debugging techniques demonstrated"
EOF
Create the service check task file:
cat > service_check.yml << 'EOF'
---
- name: Check service {{ service.name }}
  block:
    - name: Debug service information
      debug:
        msg: "Checking {{ service.name }} on port {{ service.port }} (Critical: {{ service.critical }})"
      when: debug_enabled
    
    - name: Simulate service check
      set_fact:
        service_status: "{{ 'running' if service.port != 3306 else 'stopped' }}"
    
    - name: Fail for critical services that are down
      fail:
        msg: "Critical service {{ service.name }} is not running"
      when: 
        - service.critical
        - service_status != 'running'

rescue:
  - name: Handle service failure
    debug:
      msg: "Service {{ service.name }} failed check, implementing recovery"
    when: service.critical
  
  - name: Skip non-critical service failures
    debug:
      msg: "Non-critical service {{ service.name }} failure ignored"
    when: not service.critical
EOF
Run the complete debugging lab:
# Run in check mode first
ansible-playbook complete_debugging_lab.yml --check -v

# Run normally
ansible-playbook complete_debugging_lab.yml -v

# Run with different environment
ENVIRONMENT=production ansible-playbook complete_debugging_lab.yml
Troubleshooting Common Issues
Common Debugging Scenarios
Variable undefined errors:
cat > variable_debugging.yml << 'EOF'
---
- name: Variable Debugging Examples
  hosts: localhost
  vars:
    defined_var: "I exist"
    
  tasks:
    - name: Safe variable access
      debug:
        msg: "Variable value: {{ defined_var | default('Not defined') }}"
    
    - name: Check if variable is defined
      debug:
        msg: "undefined_var is {{ 'defined' if undefined_var is defined else 'not defined' }}"
    
    - name: Conditional task based on variable existence
      debug:
        msg: "This runs only if variable exists"
      when: undefined_var is defined
    
    - name: Using default values
      debug:
        msg: "Value: {{ undefined_var | default('Default value used') }}"
EOF
Loop debugging:
cat > loop_debugging.yml << 'EOF'
---
- name: Loop Debugging Examples
  hosts: localhost
  vars:
    items_list:
      - name: "item1"
        value: 10
      - name: "item2"
        value: 20
      - name: "item3"
        value: 30
    
  tasks:
    - name: Debug loop items
      debug:
        msg: "Processing {{ item.name }} with value {{ item.value }} (Index: {{ ansible_loop.index }})"
      loop: "{{ items_list }}"
      loop_control:
        extended: yes
    
    - name: Debug with conditional loop
      debug:
        msg: "High value item: {{ item.name }}"
      loop: "{{ items_list }}"
      when: item.value > 15
EOF
Run the troubleshooting examples:
ansible-playbook variable_debugging.yml
ansible-playbook loop_debugging.yml
Lab Validation and Testing
Validation Checklist
Create a validation playbook:
cat > lab_validation.yml << 'EOF'
---
- name: Lab 12 Validation Checklist
  hosts: localhost
  
  tasks:
    - name: Test 1 - Debug module functionality
      debug:
        msg: "✓ Debug module working correctly"
    
    - name: Test 2 - Variable display
      debug:
        var: ansible_hostname
    
    - name: Test 3 - Conditional debug
      debug:
        msg: "✓ Conditional debug working"
      when: true
    
    - name: Test 4 - Check mode awareness
      debug:
        msg: "Running in {{ 'CHECK' if ansible_check_mode else 'NORMAL' }} mode"
    
    - name: Test 5 - Error handling validation
      block:
        - name: Intentional failure for testing
          fail:
            msg: "This is a test failure"
          when: false  # This won't actually fail
        
        - name: Success path
          debug:
            msg: "✓ Block executed successfully"
      
      rescue:
        - name: This shouldn't execute
          debug:
            msg: "✗ Rescue block executed unexpectedly"
      
      always:
        - name: Always block validation
          debug:
            msg: "✓ Always block executed correctly"
    
    - name: Final validation message
      debug:
        msg: |
          ✓ Lab 12 Validation Complete
          All debugging and error handling features tested successfully!
EOF
Run validation tests:
# Normal validation
ansible-playbook lab_validation.yml

# Check mode validation
ansible-playbook lab_validation.yml --check
Conclusion
Congratulations! You have successfully completed Lab 12: Ansible Playbook Debugging and Error Handling. In this comprehensive lab, you have accomplished the following:

Key Achievements
Debug Module Mastery: You learned how to use the debug module effectively to display variable values, custom messages, and system information. You explored different verbosity levels and conditional debugging techniques that are essential for troubleshooting complex playbooks.

Fail Module Implementation: You implemented the fail module to create controlled failure points in your playbooks, enabling proper validation and error reporting. This skill is crucial for creating robust automation that fails fast when conditions aren't met.

Check Mode Proficiency: You mastered the use of check mode (dry runs) to validate playbook changes before execution. This capability allows you to safely test playbooks in production environments and understand what changes would be made.

Advanced Error Handling: You implemented sophisticated error handling using block, rescue, and always constructs. These techniques enable you to create resilient automation that can recover from failures and continue operation.

Real-World Applications: You applied these debugging and error handling techniques to practical scenarios like web server deployment with fallback options, demonstrating how these skills translate to production environments.

Why This Matters
The skills you've developed in this lab are fundamental for any Ansible practitioner working in production environments. Proper debugging and error handling are what separate basic automation scripts from enterprise-grade infrastructure as code. These techniques will help you:

Reduce Downtime: By implementing proper error handling, your automation can recover from failures automatically
Improve Reliability: Debug capabilities help you identify and resolve issues quickly
Enhance Safety: Check mode allows you to validate changes before applying them to critical systems
Accelerate Development: Effective debugging techniques speed up playbook development and troubleshooting
Next Steps
With these debugging and error handling skills, you're well-prepared to create production-ready Ansible playbooks that can handle real-world complexity and unexpected conditions. These techniques form the foundation for advanced Ansible practices and are essential for the Red Hat Certified Engineer (RHCE) certification path.

The debugging and error handling patterns you've learned will serve you well as you continue to develop more sophisticated automation solutions and work with larger, more complex infrastructure environments.
