Lab 17: Troubleshooting Automation Runs with Ansible
Objectives
By the end of this lab, you will be able to:

Perform dry runs using ansible-playbook --check to validate playbooks before execution
Implement debugging techniques using Ansible's debug module to troubleshoot issues
Use ansible-playbook --step to interactively step through playbook execution
Identify and resolve common Ansible automation issues
Apply best practices for troubleshooting Ansible playbooks in production environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Knowledge of Ansible fundamentals including playbooks, tasks, and modules
Understanding of SSH key-based authentication
Experience with text editors like vim or nano
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: Two target servers (node1 and node2) for testing
Pre-configured SSH keys for passwordless authentication
Sample files and directories for hands-on practice
Task 1: Using ansible-playbook --check for Dry Runs
Subtask 1.1: Understanding Check Mode
Check mode allows you to validate what changes Ansible would make without actually executing them. This is crucial for testing playbooks safely.

Step 1: Connect to your control node and navigate to the working directory

cd /home/ansible
ls -la
Step 2: Create a sample playbook with intentional issues for troubleshooting

mkdir troubleshooting-lab
cd troubleshooting-lab
Step 3: Create a basic inventory file

cat > inventory << EOF
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=/home/ansible/.ssh/id_rsa
EOF
Subtask 1.2: Creating a Test Playbook
Step 4: Create a playbook that installs and configures a web server

cat > webserver-setup.yml << 'EOF'
---
- name: Web Server Setup and Configuration
  hosts: webservers
  become: yes
  vars:
    web_package: httpd
    web_service: httpd
    document_root: /var/www/html
    
  tasks:
    - name: Install web server package
      yum:
        name: "{{ web_package }}"
        state: present
        
    - name: Start and enable web service
      systemd:
        name: "{{ web_service }}"
        state: started
        enabled: yes
        
    - name: Create custom index page
      copy:
        content: |
          <html>
          <head><title>Welcome to {{ inventory_hostname }}</title></head>
          <body>
          <h1>Server: {{ inventory_hostname }}</h1>
          <p>Managed by Ansible</p>
          </body>
          </html>
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
        
    - name: Open firewall for HTTP
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
EOF
Subtask 1.3: Performing Dry Runs
Step 5: Run the playbook in check mode to see what would happen

ansible-playbook -i inventory webserver-setup.yml --check
Step 6: Run check mode with verbose output for more details

ansible-playbook -i inventory webserver-setup.yml --check -v
Step 7: Use check mode with diff to see file changes

ansible-playbook -i inventory webserver-setup.yml --check --diff
Subtask 1.4: Analyzing Check Mode Results
Step 8: Create a playbook with a deliberate error to see how check mode catches issues

cat > problematic-playbook.yml << 'EOF'
---
- name: Problematic Playbook for Testing
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install package with wrong name
      yum:
        name: non-existent-package
        state: present
        
    - name: Copy file to non-existent directory
      copy:
        src: /tmp/nonexistent-file.txt
        dest: /nonexistent/directory/file.txt
        
    - name: Start service with wrong name
      systemd:
        name: wrong-service-name
        state: started
EOF
Step 9: Run check mode on the problematic playbook

ansible-playbook -i inventory problematic-playbook.yml --check -v
Task 2: Implementing Debugging with the Debug Module
Subtask 2.1: Basic Debug Module Usage
Step 10: Create a playbook that demonstrates various debug techniques

cat > debug-examples.yml << 'EOF'
---
- name: Debug Module Examples
  hosts: webservers
  gather_facts: yes
  vars:
    app_name: "MyWebApp"
    app_version: "1.2.3"
    debug_enabled: true
    
  tasks:
    - name: Debug - Display simple message
      debug:
        msg: "Starting deployment of {{ app_name }} version {{ app_version }}"
        
    - name: Debug - Display variable values
      debug:
        var: ansible_hostname
        
    - name: Debug - Display multiple variables
      debug:
        msg: |
          Host Information:
          - Hostname: {{ ansible_hostname }}
          - IP Address: {{ ansible_default_ipv4.address }}
          - OS Family: {{ ansible_os_family }}
          - Architecture: {{ ansible_architecture }}
          
    - name: Debug - Conditional debugging
      debug:
        msg: "Debug mode is enabled for {{ inventory_hostname }}"
      when: debug_enabled
      
    - name: Gather package facts
      package_facts:
        manager: auto
        
    - name: Debug - Display installed packages (filtered)
      debug:
        msg: "Package {{ item }} is installed"
      loop:
        - httpd
        - openssh-server
        - vim
      when: item in ansible_facts.packages
EOF
Step 11: Run the debug playbook

ansible-playbook -i inventory debug-examples.yml
Subtask 2.2: Advanced Debugging Techniques
Step 12: Create a playbook that demonstrates debugging complex data structures

cat > advanced-debug.yml << 'EOF'
---
- name: Advanced Debugging Techniques
  hosts: webservers
  gather_facts: yes
  vars:
    users:
      - name: alice
        uid: 1001
        groups: [wheel, developers]
      - name: bob
        uid: 1002
        groups: [developers]
    
  tasks:
    - name: Debug - Display entire data structure
      debug:
        var: users
        
    - name: Debug - Loop through complex data
      debug:
        msg: |
          User: {{ item.name }}
          UID: {{ item.uid }}
          Groups: {{ item.groups | join(', ') }}
      loop: "{{ users }}"
      
    - name: Register command output for debugging
      command: df -h
      register: disk_usage
      
    - name: Debug - Display command results
      debug:
        var: disk_usage
        
    - name: Debug - Display specific parts of registered variable
      debug:
        msg: |
          Command: {{ disk_usage.cmd | join(' ') }}
          Return Code: {{ disk_usage.rc }}
          Output Lines: {{ disk_usage.stdout_lines | length }}
          
    - name: Debug - Network interface information
      debug:
        msg: "Interface {{ item }} has IP {{ hostvars[inventory_hostname]['ansible_' + item]['ipv4']['address'] }}"
      loop: "{{ ansible_interfaces }}"
      when: 
        - hostvars[inventory_hostname]['ansible_' + item] is defined
        - hostvars[inventory_hostname]['ansible_' + item]['ipv4'] is defined
EOF
Step 13: Execute the advanced debugging playbook

ansible-playbook -i inventory advanced-debug.yml
Subtask 2.3: Debugging Failed Tasks
Step 14: Create a playbook that demonstrates debugging failures

cat > debug-failures.yml << 'EOF'
---
- name: Debugging Failed Tasks
  hosts: webservers
  become: yes
  
  tasks:
    - name: Attempt to install package (might fail)
      yum:
        name: "{{ package_name | default('httpd') }}"
        state: present
      register: package_result
      ignore_errors: yes
      
    - name: Debug - Package installation result
      debug:
        var: package_result
        
    - name: Debug - Conditional message based on result
      debug:
        msg: "Package installation failed: {{ package_result.msg }}"
      when: package_result.failed
      
    - name: Debug - Success message
      debug:
        msg: "Package {{ package_name | default('httpd') }} installed successfully"
      when: not package_result.failed
      
    - name: Test file operations with debugging
      block:
        - name: Create test file
          copy:
            content: "Test content"
            dest: /tmp/test-file.txt
          register: file_result
          
        - name: Debug - File creation result
          debug:
            msg: "File created successfully at {{ file_result.dest }}"
            
      rescue:
        - name: Debug - File creation failed
          debug:
            msg: "Failed to create file: {{ ansible_failed_result.msg }}"
EOF
Step 15: Run the failure debugging playbook

ansible-playbook -i inventory debug-failures.yml
Task 3: Using ansible-playbook --step for Interactive Execution
Subtask 3.1: Understanding Step Mode
Step mode allows you to execute playbooks one task at a time, giving you control over the execution flow.

Step 16: Create a comprehensive playbook for step-by-step execution

cat > step-by-step.yml << 'EOF'
---
- name: Step-by-Step Playbook Execution
  hosts: webservers
  become: yes
  vars:
    packages_to_install:
      - vim
      - wget
      - curl
      - htop
    
  tasks:
    - name: Update package cache
      yum:
        update_cache: yes
        
    - name: Install essential packages
      yum:
        name: "{{ packages_to_install }}"
        state: present
        
    - name: Create application directory
      file:
        path: /opt/myapp
        state: directory
        owner: root
        group: root
        mode: '0755'
        
    - name: Create configuration file
      copy:
        content: |
          # Application Configuration
          app_name=MyApplication
          app_version=1.0.0
          debug_mode=false
        dest: /opt/myapp/config.conf
        owner: root
        group: root
        mode: '0644'
        
    - name: Create startup script
      copy:
        content: |
          #!/bin/bash
          echo "Starting MyApplication..."
          echo "Configuration loaded from /opt/myapp/config.conf"
          echo "Application started successfully"
        dest: /opt/myapp/start.sh
        owner: root
        group: root
        mode: '0755'
        
    - name: Test the startup script
      command: /opt/myapp/start.sh
      register: startup_result
      
    - name: Display startup result
      debug:
        var: startup_result.stdout_lines
EOF
Subtask 3.2: Executing Playbooks in Step Mode
Step 17: Run the playbook in step mode

ansible-playbook -i inventory step-by-step.yml --step
Note: In step mode, you'll be prompted for each task with options:

y - Execute the task
n - Skip the task
c - Continue without prompting for remaining tasks
Subtask 3.3: Combining Step Mode with Other Options
Step 18: Use step mode with check mode for maximum control

ansible-playbook -i inventory step-by-step.yml --step --check
Step 19: Use step mode with specific host targeting

ansible-playbook -i inventory step-by-step.yml --step --limit node1
Step 20: Create a playbook specifically designed for interactive troubleshooting

cat > interactive-troubleshooting.yml << 'EOF'
---
- name: Interactive Troubleshooting Session
  hosts: webservers
  become: yes
  
  tasks:
    - name: Check system resources
      shell: |
        echo "=== SYSTEM RESOURCES ==="
        free -h
        echo ""
        echo "=== DISK USAGE ==="
        df -h
        echo ""
        echo "=== LOAD AVERAGE ==="
        uptime
      register: system_check
      
    - name: Display system information
      debug:
        var: system_check.stdout_lines
        
    - name: Check for running services
      shell: systemctl list-units --type=service --state=running | head -10
      register: running_services
      
    - name: Display running services
      debug:
        var: running_services.stdout_lines
        
    - name: Check network connectivity
      shell: |
        echo "=== NETWORK INTERFACES ==="
        ip addr show | grep -E "^[0-9]+:|inet "
        echo ""
        echo "=== ROUTING TABLE ==="
        ip route
      register: network_check
      
    - name: Display network information
      debug:
        var: network_check.stdout_lines
        
    - name: Check log files for errors
      shell: |
        echo "=== RECENT SYSTEM ERRORS ==="
        journalctl --since "1 hour ago" --priority=err --no-pager | tail -10
      register: error_check
      ignore_errors: yes
      
    - name: Display recent errors
      debug:
        var: error_check.stdout_lines
      when: error_check.stdout_lines | length > 0
      
    - name: No recent errors found
      debug:
        msg: "No recent system errors found in the last hour"
      when: error_check.stdout_lines | length == 0
EOF
Step 21: Run the interactive troubleshooting playbook in step mode

ansible-playbook -i inventory interactive-troubleshooting.yml --step -v
Task 4: Comprehensive Troubleshooting Scenario
Subtask 4.1: Creating a Complex Scenario
Step 22: Create a playbook that simulates real-world troubleshooting challenges

cat > comprehensive-troubleshooting.yml << 'EOF'
---
- name: Comprehensive Troubleshooting Scenario
  hosts: webservers
  become: yes
  vars:
    web_user: webadmin
    web_group: webadmin
    app_port: 8080
    
  tasks:
    - name: Debug - Starting comprehensive deployment
      debug:
        msg: |
          Starting deployment on {{ inventory_hostname }}
          Target user: {{ web_user }}
          Target group: {{ web_group }}
          Application port: {{ app_port }}
          
    - name: Create web user and group
      block:
        - name: Create web group
          group:
            name: "{{ web_group }}"
            state: present
            
        - name: Create web user
          user:
            name: "{{ web_user }}"
            group: "{{ web_group }}"
            home: /home/{{ web_user }}
            shell: /bin/bash
            state: present
            
      rescue:
        - name: Debug - User creation failed
          debug:
            msg: "Failed to create user {{ web_user }}: {{ ansible_failed_result.msg }}"
            
    - name: Install and configure web server
      block:
        - name: Install required packages
          yum:
            name:
              - httpd
              - python3-pip
              - git
            state: present
          register: package_install
          
        - name: Debug - Package installation status
          debug:
            msg: "Packages installed: {{ package_install.results | map(attribute='name') | list }}"
            
        - name: Configure custom port
          lineinfile:
            path: /etc/httpd/conf/httpd.conf
            regexp: '^Listen 80'
            line: 'Listen {{ app_port }}'
            backup: yes
          register: config_change
          
        - name: Debug - Configuration change
          debug:
            msg: "Configuration modified: {{ config_change.changed }}"
            
      rescue:
        - name: Debug - Web server setup failed
          debug:
            msg: "Web server setup failed: {{ ansible_failed_result.msg }}"
            
    - name: Deploy application files
      block:
        - name: Create application directory
          file:
            path: /var/www/myapp
            state: directory
            owner: "{{ web_user }}"
            group: "{{ web_group }}"
            mode: '0755'
            
        - name: Deploy index page
          template:
            src: index.html.j2
            dest: /var/www/myapp/index.html
            owner: "{{ web_user }}"
            group: "{{ web_group }}"
            mode: '0644'
          register: deploy_result
          
        - name: Debug - Deployment result
          debug:
            var: deploy_result
            
      rescue:
        - name: Debug - Application deployment failed
          debug:
            msg: "Application deployment failed: {{ ansible_failed_result.msg }}"
            
    - name: Start and verify services
      block:
        - name: Start httpd service
          systemd:
            name: httpd
            state: started
            enabled: yes
          register: service_start
          
        - name: Debug - Service status
          debug:
            msg: "Service started: {{ service_start.changed }}"
            
        - name: Verify service is listening
          wait_for:
            port: "{{ app_port }}"
            host: "{{ ansible_default_ipv4.address }}"
            timeout: 30
          register: port_check
          
        - name: Debug - Port verification
          debug:
            msg: "Port {{ app_port }} is accessible on {{ ansible_default_ipv4.address }}"
            
      rescue:
        - name: Debug - Service startup failed
          debug:
            msg: "Service startup failed: {{ ansible_failed_result.msg }}"
            
    - name: Final system verification
      block:
        - name: Check service status
          command: systemctl status httpd
          register: service_status
          
        - name: Check listening ports
          command: ss -tlnp | grep {{ app_port }}
          register: port_status
          
        - name: Debug - Final verification
          debug:
            msg: |
              Service Status: {{ service_status.rc == 0 }}
              Port Listening: {{ port_status.stdout != '' }}
              
      always:
        - name: Debug - Deployment summary
          debug:
            msg: |
              Deployment completed on {{ inventory_hostname }}
              Check the application at http://{{ ansible_default_ipv4.address }}:{{ app_port }}
EOF
Step 23: Create the template file referenced in the playbook

mkdir templates
cat > templates/index.html.j2 << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>{{ inventory_hostname }} - MyApp</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Welcome to MyApp</h1>
        <p>Running on {{ inventory_hostname }}</p>
    </div>
    
    <div class="info">
        <h2>System Information</h2>
        <ul>
            <li><strong>Hostname:</strong> {{ ansible_hostname }}</li>
            <li><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</li>
            <li><strong>OS:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</li>
            <li><strong>Architecture:</strong> {{ ansible_architecture }}</li>
            <li><strong>Port:</strong> {{ app_port }}</li>
        </ul>
    </div>
    
    <div class="info">
        <h2>Deployment Details</h2>
        <p>Deployed by Ansible on {{ ansible_date_time.iso8601 }}</p>
        <p>Managed by user: {{ web_user }}</p>
    </div>
</body>
</html>
EOF
Subtask 4.2: Running Comprehensive Troubleshooting
Step 24: First, run in check mode to identify potential issues

ansible-playbook -i inventory comprehensive-troubleshooting.yml --check --diff
Step 25: Run in step mode to control execution

ansible-playbook -i inventory comprehensive-troubleshooting.yml --step
Step 26: Run normally with verbose output

ansible-playbook -i inventory comprehensive-troubleshooting.yml -v
Task 5: Best Practices and Common Issues
Subtask 5.1: Common Troubleshooting Commands
Step 27: Create a reference playbook with common troubleshooting tasks

cat > troubleshooting-reference.yml << 'EOF'
---
- name: Ansible Troubleshooting Reference
  hosts: webservers
  gather_facts: yes
  
  tasks:
    - name: Syntax validation (run with --syntax-check)
      debug:
        msg: "This playbook has valid syntax"
        
    - name: Connection test
      ping:
      register: ping_result
      
    - name: Debug - Connection status
      debug:
        msg: "Connection to {{ inventory_hostname }}: {{ 'SUCCESS' if ping_result.ping == 'pong' else 'FAILED' }}"
        
    - name: Gather and display system facts
      debug:
        msg: |
          Key System Facts:
          - OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          - Kernel: {{ ansible_kernel }}
          - Memory: {{ ansible_memtotal_mb }}MB
          - CPU Cores: {{ ansible_processor_vcpus }}
          - Python Version: {{ ansible_python_version }}
          
    - name: Check Ansible version compatibility
      debug:
        msg: "Ansible version: {{ ansible_version.full }}"
        
    - name: Test privilege escalation
      command: whoami
      become: yes
      register: privilege_test
      
    - name: Debug - Privilege escalation result
      debug:
        msg: "Running as: {{ privilege_test.stdout }}"
        
    - name: Test variable resolution
      debug:
        msg: |
          Variable Resolution Test:
          - inventory_hostname: {{ inventory_hostname }}
          - ansible_hostname: {{ ansible_hostname }}
          - group_names: {{ group_names }}
          - hostvars keys: {{ hostvars.keys() | list }}
EOF
Step 28: Run syntax check

ansible-playbook troubleshooting-reference.yml --syntax-check
Step 29: Run the reference playbook

ansible-playbook -i inventory troubleshooting-reference.yml
Subtask 5.2: Creating a Troubleshooting Checklist
Step 30: Create a comprehensive troubleshooting checklist script

cat > troubleshooting-checklist.sh << 'EOF'
#!/bin/bash

echo "=== ANSIBLE TROUBLESHOOTING CHECKLIST ==="
echo ""

echo "1. SYNTAX CHECK:"
echo "   ansible-playbook playbook.yml --syntax-check"
echo ""

echo "2. DRY RUN (CHECK MODE):"
echo "   ansible-playbook -i inventory playbook.yml --check"
echo ""

echo "3. DRY RUN WITH DIFF:"
echo "   ansible-playbook -i inventory playbook.yml --check --diff"
echo ""

echo "4. STEP-BY-STEP EXECUTION:"
echo "   ansible-playbook -i inventory playbook.yml --step"
echo ""

echo "5. VERBOSE OUTPUT:"
echo "   ansible-playbook -i inventory playbook.yml -v"
echo "   (Use -vv, -vvv, or -vvvv for more verbosity)"
echo ""

echo "6. CONNECTION TEST:"
echo "   ansible -i inventory all -m ping"
echo ""

echo "7. FACT GATHERING:"
echo "   ansible -i inventory all -m setup"
echo ""

echo "8. SPECIFIC HOST TARGETING:"
echo "   ansible-playbook -i inventory playbook.yml --limit hostname"
echo ""

echo "9. TAG-BASED EXECUTION:"
echo "   ansible-playbook -i inventory playbook.yml --tags tag_name"
echo ""

echo "10. LIST TASKS:"
echo "    ansible-playbook -i inventory playbook.yml --list-tasks"
echo ""

echo "11. LIST HOSTS:"
echo "    ansible-playbook -i inventory playbook.yml --list-hosts"
echo ""

echo "12. COMMON DEBUG PATTERNS:"
echo "    - Use debug module with 'var:' for variables"
echo "    - Use debug module with 'msg:' for custom messages"
echo "    - Register task results and debug them"
echo "    - Use 'ignore_errors: yes' for non-critical tasks"
echo "    - Use 'failed_when:' for custom failure conditions"
echo ""
EOF

chmod +x troubleshooting-checklist.sh
Step 31: Display the troubleshooting checklist

./troubleshooting-checklist.sh
Conclusion
Congratulations! You have successfully completed Lab 17: Troubleshooting Automation Runs with Ansible. In this comprehensive lab, you have learned and practiced essential troubleshooting techniques that are crucial for maintaining reliable Ansible automation in production environments.

What You Accomplished
Dry Run Validation: You mastered the use of ansible-playbook --check to perform safe dry runs, allowing you to validate playbooks before execution and catch potential issues early in the development cycle.

Debug Module Mastery: You implemented various debugging techniques using Ansible's debug module, learning how to display variable values, troubleshoot complex data structures, and analyze task execution results.

Interactive Execution: You gained hands-on experience with ansible-playbook --step, enabling you to execute playbooks interactively and maintain fine-grained control over automation workflows.

Real-World Scenarios: You worked through comprehensive troubleshooting scenarios that simulate actual production challenges, building confidence in your ability to diagnose and resolve automation issues.

Best Practices: You developed a systematic approach to troubleshooting Ansible playbooks, including syntax validation, connection testing, and verbose output analysis.

Why This Matters
These troubleshooting skills are essential for:

Production Reliability: Ensuring automation runs smoothly in critical environments
Rapid Issue Resolution: Quickly identifying and fixing problems when they occur
Preventive Maintenance: Catching issues before they impact production systems
Team Collaboration: Providing clear debugging information when working with colleagues
Certification Success: These skills are fundamental for the Red Hat Certified Engineer (RHCE) exam
The techniques you've learned in this lab will serve as your foundation for maintaining robust, reliable Ansible automation in any environment. Remember to always test your playbooks thoroughly and use these debugging tools proactively to ensure smooth operations.
