Lab 19: Error Handling and Debugging
Objectives
By the end of this lab, students will be able to:

• Implement debug module to output variable values for troubleshooting • Utilize Ansible's --check mode to perform dry runs and validate playbooks • Implement comprehensive error handling using ignore_errors and block/rescue/always constructs • Identify and resolve common Ansible playbook errors • Apply best practices for debugging and error handling in automation workflows

Prerequisites
Before starting this lab, students should have:

• Basic understanding of YAML syntax • Familiarity with Ansible playbook structure • Knowledge of Ansible modules and tasks • Experience running Ansible playbooks • Understanding of Linux command line basics

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click "Start Lab" to access your environment - no need to build your own VM or install software.

Your lab environment includes: • Control node with Ansible pre-installed • Two managed nodes (target servers) • All necessary SSH keys and inventory files configured

Task 1: Using Debug Module to Output Variable Values
Subtask 1.1: Create a Basic Debug Playbook
First, let's create a playbook that demonstrates how to use the debug module to display variable values.

Create the lab directory structure:
mkdir -p ~/lab19-error-handling
cd ~/lab19-error-handling
Create a basic inventory file:
cat > inventory << EOF
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Create your first debug playbook:
cat > debug-variables.yml << 'EOF'
---
- name: Debug Module Demonstration
  hosts: webservers
  gather_facts: yes
  vars:
    app_name: "MyWebApp"
    app_version: "2.1.0"
    environment: "production"
    server_ports:
      - 80
      - 443
      - 8080
  
  tasks:
    - name: Debug simple string variable
      debug:
        msg: "Application name is: {{ app_name }}"
    
    - name: Debug variable with formatting
      debug:
        msg: "Running {{ app_name }} version {{ app_version }} in {{ environment }} environment"
    
    - name: Debug list variable
      debug:
        var: server_ports
    
    - name: Debug system facts
      debug:
        msg: "Server {{ inventory_hostname }} is running {{ ansible_distribution }} {{ ansible_distribution_version }}"
    
    - name: Debug with conditional output
      debug:
        msg: "This is a production server"
      when: environment == "production"
EOF
Run the debug playbook:
ansible-playbook -i inventory debug-variables.yml
Subtask 1.2: Advanced Debug Techniques
Create an advanced debug playbook:
cat > advanced-debug.yml << 'EOF'
---
- name: Advanced Debug Techniques
  hosts: webservers
  gather_facts: yes
  vars:
    users:
      - name: "alice"
        role: "admin"
        active: true
      - name: "bob"
        role: "user"
        active: false
      - name: "charlie"
        role: "developer"
        active: true
  
  tasks:
    - name: Debug loop with item details
      debug:
        msg: "User: {{ item.name }}, Role: {{ item.role }}, Active: {{ item.active }}"
      loop: "{{ users }}"
    
    - name: Debug filtered results
      debug:
        msg: "Active user found: {{ item.name }}"
      loop: "{{ users }}"
      when: item.active == true
    
    - name: Debug variable type and content
      debug:
        msg: 
          - "Variable name: users"
          - "Variable type: {{ users | type_debug }}"
          - "Number of users: {{ users | length }}"
    
    - name: Debug with verbosity levels
      debug:
        msg: "This message appears only with -v flag"
        verbosity: 1
    
    - name: Debug detailed system information
      debug:
        var: ansible_all_ipv4_addresses
      when: ansible_all_ipv4_addresses is defined
EOF
Run with different verbosity levels:
# Normal output
ansible-playbook -i inventory advanced-debug.yml

# Verbose output
ansible-playbook -i inventory advanced-debug.yml -v
Task 2: Utilizing --check Mode for Dry Runs
Subtask 2.1: Create a Playbook for Check Mode Testing
Create a playbook that makes system changes:
cat > system-changes.yml << 'EOF'
---
- name: System Configuration Changes
  hosts: webservers
  become: yes
  vars:
    packages_to_install:
      - htop
      - curl
      - wget
    service_name: "httpd"
    config_file: "/etc/httpd/conf/httpd.conf"
  
  tasks:
    - name: Install required packages
      yum:
        name: "{{ packages_to_install }}"
        state: present
    
    - name: Create application directory
      file:
        path: /opt/myapp
        state: directory
        mode: '0755'
        owner: root
        group: root
    
    - name: Create configuration file
      copy:
        content: |
          # Application Configuration
          app_name={{ app_name | default('DefaultApp') }}
          debug_mode=false
          log_level=info
        dest: /opt/myapp/config.conf
        mode: '0644'
    
    - name: Start and enable service
      systemd:
        name: "{{ service_name }}"
        state: started
        enabled: yes
      ignore_errors: yes
    
    - name: Display completion message
      debug:
        msg: "System configuration completed successfully"
EOF
Subtask 2.2: Test with Check Mode
Run in check mode (dry run):
ansible-playbook -i inventory system-changes.yml --check
Run in check mode with diff to see changes:
ansible-playbook -i inventory system-changes.yml --check --diff
Create a playbook that handles check mode gracefully:
cat > check-mode-aware.yml << 'EOF'
---
- name: Check Mode Aware Playbook
  hosts: webservers
  become: yes
  
  tasks:
    - name: Check if running in check mode
      debug:
        msg: "Running in check mode - no actual changes will be made"
      when: ansible_check_mode
    
    - name: Check if running in normal mode
      debug:
        msg: "Running in normal mode - changes will be applied"
      when: not ansible_check_mode
    
    - name: Create directory (check mode safe)
      file:
        path: /tmp/test-directory
        state: directory
        mode: '0755'
    
    - name: Gather directory information
      stat:
        path: /tmp/test-directory
      register: dir_info
    
    - name: Display directory status
      debug:
        msg: "Directory exists: {{ dir_info.stat.exists }}"
      when: not ansible_check_mode
    
    - name: Display check mode message
      debug:
        msg: "Directory would be created (check mode)"
      when: ansible_check_mode
EOF
Test the check-mode aware playbook:
# Check mode
ansible-playbook -i inventory check-mode-aware.yml --check

# Normal mode
ansible-playbook -i inventory check-mode-aware.yml
Task 3: Implementing Error Handling with ignore_errors and block
Subtask 3.1: Basic Error Handling with ignore_errors
Create a playbook demonstrating ignore_errors:
cat > basic-error-handling.yml << 'EOF'
---
- name: Basic Error Handling Demonstration
  hosts: webservers
  become: yes
  
  tasks:
    - name: Task that might fail - without error handling
      command: /bin/false
      register: result_without_handling
      ignore_errors: yes
    
    - name: Display result of failed task
      debug:
        msg: "Previous task failed with return code: {{ result_without_handling.rc }}"
    
    - name: Attempt to install non-existent package
      yum:
        name: non-existent-package-12345
        state: present
      ignore_errors: yes
      register: package_result
    
    - name: Handle package installation failure
      debug:
        msg: "Package installation failed: {{ package_result.msg }}"
      when: package_result.failed
    
    - name: Continue with other tasks
      debug:
        msg: "This task runs even after previous failures"
    
    - name: Conditional error handling
      shell: "ls /nonexistent/directory"
      ignore_errors: yes
      register: ls_result
      changed_when: false
    
    - name: Report directory listing result
      debug:
        msg: "Directory listing {{ 'succeeded' if ls_result.rc == 0 else 'failed' }}"
EOF
Run the basic error handling playbook:
ansible-playbook -i inventory basic-error-handling.yml
Subtask 3.2: Advanced Error Handling with Block/Rescue/Always
Create a comprehensive error handling playbook:
cat > advanced-error-handling.yml << 'EOF'
---
- name: Advanced Error Handling with Blocks
  hosts: webservers
  become: yes
  vars:
    critical_services:
      - httpd
      - nginx
      - mysql
  
  tasks:
    - name: Web server configuration block
      block:
        - name: Install web server
          yum:
            name: httpd
            state: present
        
        - name: Start web server
          systemd:
            name: httpd
            state: started
            enabled: yes
        
        - name: Create web content
          copy:
            content: "<h1>Web server is running!</h1>"
            dest: /var/www/html/index.html
            mode: '0644'
        
        - name: Test web server response
          uri:
            url: "http://{{ inventory_hostname }}"
            method: GET
          delegate_to: localhost
      
      rescue:
        - name: Log web server setup failure
          debug:
            msg: "Web server setup failed. Attempting alternative configuration."
        
        - name: Install alternative web server
          yum:
            name: nginx
            state: present
          ignore_errors: yes
        
        - name: Configure alternative web server
          copy:
            content: "<h1>Alternative web server running!</h1>"
            dest: /usr/share/nginx/html/index.html
            mode: '0644'
          ignore_errors: yes
      
      always:
        - name: Log completion status
          debug:
            msg: "Web server configuration attempt completed at {{ ansible_date_time.iso8601 }}"
        
        - name: Check final service status
          command: systemctl is-active httpd nginx
          register: service_status
          ignore_errors: yes
          changed_when: false
        
        - name: Report service status
          debug:
            var: service_status.stdout_lines
    
    - name: Database configuration with nested error handling
      block:
        - name: Attempt primary database setup
          block:
            - name: Install MySQL
              yum:
                name: mysql-server
                state: present
            
            - name: Start MySQL service
              systemd:
                name: mysqld
                state: started
                enabled: yes
          
          rescue:
            - name: Try alternative database
              debug:
                msg: "MySQL installation failed, trying MariaDB"
            
            - name: Install MariaDB
              yum:
                name: mariadb-server
                state: present
            
            - name: Start MariaDB service
              systemd:
                name: mariadb
                state: started
                enabled: yes
      
      rescue:
        - name: Database setup completely failed
          debug:
            msg: "All database installation attempts failed"
        
        - name: Create failure report
          copy:
            content: |
              Database Setup Failure Report
              ============================
              Time: {{ ansible_date_time.iso8601 }}
              Host: {{ inventory_hostname }}
              Error: Unable to install any database server
            dest: /tmp/db-failure-report.txt
            mode: '0644'
      
      always:
        - name: Cleanup temporary files
          file:
            path: /tmp/setup-temp
            state: absent
        
        - name: Final status report
          debug:
            msg: "Database configuration block completed"
EOF
Run the advanced error handling playbook:
ansible-playbook -i inventory advanced-error-handling.yml
Subtask 3.3: Error Handling Best Practices
Create a best practices demonstration playbook:
cat > error-handling-best-practices.yml << 'EOF'
---
- name: Error Handling Best Practices
  hosts: webservers
  become: yes
  vars:
    max_retries: 3
    retry_delay: 5
  
  tasks:
    - name: Robust package installation with retries
      block:
        - name: Update package cache
          yum:
            update_cache: yes
          retries: "{{ max_retries }}"
          delay: "{{ retry_delay }}"
        
        - name: Install packages with retry logic
          yum:
            name: 
              - htop
              - curl
              - wget
            state: present
          retries: "{{ max_retries }}"
          delay: "{{ retry_delay }}"
          register: package_install
      
      rescue:
        - name: Log package installation failure
          debug:
            msg: "Package installation failed after {{ max_retries }} attempts"
        
        - name: Attempt individual package installation
          yum:
            name: "{{ item }}"
            state: present
          loop:
            - htop
            - curl
            - wget
          ignore_errors: yes
          register: individual_installs
        
        - name: Report individual installation results
          debug:
            msg: "Package {{ item.item }}: {{ 'SUCCESS' if not item.failed else 'FAILED' }}"
          loop: "{{ individual_installs.results }}"
    
    - name: Service management with comprehensive error handling
      block:
        - name: Check if service exists
          stat:
            path: "/etc/systemd/system/{{ item }}.service"
          register: service_files
          loop:
            - httpd
            - nginx
            - apache2
        
        - name: Start available web services
          systemd:
            name: "{{ item.item }}"
            state: started
            enabled: yes
          loop: "{{ service_files.results }}"
          when: item.stat.exists
          ignore_errors: yes
          register: service_starts
        
        - name: Verify service status
          command: "systemctl is-active {{ item.item }}"
          loop: "{{ service_starts.results }}"
          when: item is not skipped and not item.failed
          register: service_status
          changed_when: false
          ignore_errors: yes
      
      rescue:
        - name: Service management failed
          debug:
            msg: "Service management encountered errors"
        
        - name: Create service status report
          copy:
            content: |
              Service Status Report
              ====================
              {% for result in service_status.results %}
              {% if result is not skipped %}
              Service: {{ result.item.item }}
              Status: {{ result.stdout | default('Unknown') }}
              {% endif %}
              {% endfor %}
            dest: /tmp/service-status-report.txt
            mode: '0644'
      
      always:
        - name: Final service verification
          shell: "systemctl list-units --type=service --state=active | grep -E '(httpd|nginx|apache2)'"
          register: active_web_services
          changed_when: false
          ignore_errors: yes
        
        - name: Display active web services
          debug:
            msg: "Active web services: {{ active_web_services.stdout_lines | default(['None found']) }}"
EOF
Run the best practices playbook:
ansible-playbook -i inventory error-handling-best-practices.yml
Subtask 3.4: Creating a Comprehensive Error Handling Template
Create a reusable error handling template:
cat > error-handling-template.yml << 'EOF'
---
- name: Comprehensive Error Handling Template
  hosts: webservers
  become: yes
  vars:
    log_file: "/var/log/ansible-deployment.log"
    notification_email: "admin@example.com"
    
  tasks:
    - name: Initialize deployment logging
      copy:
        content: |
          Ansible Deployment Log
          =====================
          Start Time: {{ ansible_date_time.iso8601 }}
          Host: {{ inventory_hostname }}
          Playbook: {{ ansible_play_name }}
          
        dest: "{{ log_file }}"
        mode: '0644'
    
    - name: Main deployment block
      block:
        # Your main deployment tasks go here
        - name: Example deployment task 1
          debug:
            msg: "Executing main deployment task 1"
        
        - name: Example deployment task 2
          debug:
            msg: "Executing main deployment task 2"
        
        - name: Simulate potential failure point
          fail:
            msg: "Simulated deployment failure"
          when: false  # Set to true to test failure handling
        
        - name: Log successful deployment
          lineinfile:
            path: "{{ log_file }}"
            line: "SUCCESS: Deployment completed successfully at {{ ansible_date_time.iso8601 }}"
      
      rescue:
        - name: Log deployment failure
          lineinfile:
            path: "{{ log_file }}"
            line: "ERROR: Deployment failed at {{ ansible_date_time.iso8601 }}"
        
        - name: Attempt rollback procedures
          debug:
            msg: "Initiating rollback procedures"
        
        - name: Create failure notification
          copy:
            content: |
              DEPLOYMENT FAILURE NOTIFICATION
              ==============================
              Host: {{ inventory_hostname }}
              Time: {{ ansible_date_time.iso8601 }}
              Playbook: {{ ansible_play_name }}
              
              Please check the deployment logs for details.
            dest: /tmp/deployment-failure-notification.txt
            mode: '0644'
        
        - name: Set deployment status
          set_fact:
            deployment_status: "failed"
      
      always:
        - name: Cleanup temporary files
          file:
            path: /tmp/deployment-temp
            state: absent
        
        - name: Final log entry
          lineinfile:
            path: "{{ log_file }}"
            line: "COMPLETED: Deployment process finished at {{ ansible_date_time.iso8601 }}"
        
        - name: Display final status
          debug:
            msg: "Deployment status: {{ deployment_status | default('success') }}"
        
        - name: Archive logs
          archive:
            path: "{{ log_file }}"
            dest: "/tmp/deployment-logs-{{ ansible_date_time.epoch }}.tar.gz"
            remove: no
EOF
Test the comprehensive template:
ansible-playbook -i inventory error-handling-template.yml
Troubleshooting Common Issues
Common Debug Module Issues
Issue: Debug output not showing expected values Solution: Check variable scope and ensure variables are defined before debug tasks

Issue: Debug messages not appearing Solution: Verify verbosity level and use appropriate debug parameters

Common Check Mode Issues
Issue: Tasks failing in check mode that work normally Solution: Use when: not ansible_check_mode for tasks that require actual changes

Issue: Check mode not showing expected changes Solution: Ensure modules support check mode and use --diff flag

Common Error Handling Issues
Issue: Playbook stopping despite ignore_errors Solution: Verify ignore_errors is properly indented and applied to correct tasks

Issue: Block/rescue not working as expected Solution: Check block structure and ensure rescue tasks are properly defined

Verification and Testing
Create a verification playbook:
cat > verify-lab-completion.yml << 'EOF'
---
- name: Lab 19 Verification
  hosts: webservers
  gather_facts: yes
  
  tasks:
    - name: Verify debug module understanding
      debug:
        msg: "Debug module verification: {{ ansible_hostname }}"
    
    - name: Verify check mode awareness
      debug:
        msg: "Check mode status: {{ ansible_check_mode }}"
    
    - name: Verify error handling implementation
      block:
        - name: Test successful task
          debug:
            msg: "This task succeeds"
        
        - name: Test error handling
          fail:
            msg: "Testing error handling"
          when: false
      
      rescue:
        - name: Handle test error
          debug:
            msg: "Error handling works correctly"
      
      always:
        - name: Always execute
          debug:
            msg: "Always block executed successfully"
    
    - name: Lab completion confirmation
      debug:
        msg: "Lab 19: Error Handling and Debugging completed successfully!"
EOF
Run the verification:
ansible-playbook -i inventory verify-lab-completion.yml
Conclusion
In this lab, you have successfully learned and implemented comprehensive error handling and debugging techniques in Ansible. You have accomplished the following:

Key Achievements:

• Debug Module Mastery: You learned how to use the debug module to output variable values, system information, and conditional messages, which is essential for troubleshooting playbooks and understanding execution flow.

• Check Mode Proficiency: You mastered the use of --check mode for performing dry runs, allowing you to validate playbook logic and preview changes before actual execution, reducing the risk of unintended modifications.

• Error Handling Implementation: You implemented robust error handling using ignore_errors for non-critical failures and block/rescue/always constructs for comprehensive error management and recovery procedures.

• Best Practices Application: You applied industry best practices for debugging and error handling, including retry logic, logging, and graceful failure recovery.

Why This Matters:

Error handling and debugging are critical skills for automation engineers because they:

Ensure reliable and resilient automation workflows
Reduce downtime and system failures
Enable proactive problem identification and resolution
Improve the maintainability and reliability of infrastructure code
Provide better visibility into automation processes
These skills are essential for the Red Hat Enterprise Linux Automation with Ansible certification and are fundamental for any professional working with infrastructure automation. The techniques you've learned will help you build more robust, reliable, and maintainable automation solutions in production environments.

Next Steps:

Continue practicing these concepts by implementing error handling in your own playbooks and exploring advanced debugging techniques such as callback plugins and custom error handling modules.
