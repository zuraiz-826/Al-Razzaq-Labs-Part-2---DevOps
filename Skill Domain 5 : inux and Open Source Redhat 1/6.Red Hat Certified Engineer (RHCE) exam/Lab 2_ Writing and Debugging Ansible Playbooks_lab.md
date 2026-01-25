Lab 2: Writing and Debugging Ansible Playbooks
Objectives
By the end of this lab, you will be able to:

Write structured Ansible playbooks using YAML syntax
Execute playbooks using the ansible-playbook command
Debug and validate playbooks using check mode and verbose output
Configure basic system packages and services using Ansible
Troubleshoot common playbook errors and syntax issues
Understand best practices for playbook organization and structure
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Completion of Lab 1 or equivalent knowledge of Ansible basics
Understanding of package management concepts (yum, apt, etc.)
Basic knowledge of system services and configuration files
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

Control node with Ansible pre-installed
Two managed nodes (target servers)
All necessary SSH keys and connectivity pre-configured
Text editors (nano, vim) available for playbook creation
Task 1: Create an Ansible Playbook to Install and Configure a Package
Subtask 1.1: Set Up the Lab Directory Structure
First, let's create a proper directory structure for our Ansible project.

Connect to your control node and create the lab directory:
mkdir -p ~/ansible-lab2
cd ~/ansible-lab2
Create the inventory file to define our managed hosts:
cat > inventory << EOF
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Verify connectivity to your managed nodes:
ansible all -i inventory -m ping
You should see successful ping responses from both nodes.

Subtask 1.2: Create Your First Playbook
Now we'll create a playbook to install and configure the Apache web server.

Create the main playbook file:
nano webserver-setup.yml
Add the following playbook content:
---
- name: Install and Configure Apache Web Server
  hosts: webservers
  become: yes
  vars:
    package_name: httpd
    service_name: httpd
    document_root: /var/www/html
    
  tasks:
    - name: Install Apache package
      yum:
        name: "{{ package_name }}"
        state: present
      tags: install
      
    - name: Start and enable Apache service
      systemd:
        name: "{{ service_name }}"
        state: started
        enabled: yes
      tags: service
      
    - name: Create custom index.html
      copy:
        content: |
          <html>
          <head><title>Ansible Lab 2</title></head>
          <body>
            <h1>Welcome to {{ inventory_hostname }}</h1>
            <p>This server was configured by Ansible!</p>
            <p>Server IP: {{ ansible_default_ipv4.address }}</p>
          </body>
          </html>
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      tags: content
      
    - name: Configure firewall for HTTP
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      tags: firewall
      
    - name: Verify Apache is responding
      uri:
        url: "http://{{ inventory_hostname }}"
        method: GET
        status_code: 200
      delegate_to: localhost
      tags: verify
Save and exit the editor (Ctrl+X, then Y, then Enter in nano).
Subtask 1.3: Create a More Advanced Configuration Playbook
Let's create a second playbook that demonstrates more advanced configuration options.

Create an advanced configuration playbook:
nano advanced-config.yml
Add the following content:
---
- name: Advanced Apache Configuration
  hosts: webservers
  become: yes
  vars:
    apache_port: 8080
    custom_config_dir: /etc/httpd/conf.d
    
  tasks:
    - name: Create custom Apache configuration
      copy:
        content: |
          # Custom Apache Configuration
          Listen {{ apache_port }}
          
          <VirtualHost *:{{ apache_port }}>
              ServerName {{ inventory_hostname }}
              DocumentRoot /var/www/html
              ErrorLog logs/custom_error.log
              CustomLog logs/custom_access.log combined
          </VirtualHost>
        dest: "{{ custom_config_dir }}/custom.conf"
        backup: yes
      notify: restart apache
      
    - name: Update main Apache configuration
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        regexp: '^Listen 80'
        line: 'Listen 80'
        backup: yes
      notify: restart apache
      
    - name: Create log directory
      file:
        path: /var/log/httpd/custom
        state: directory
        owner: apache
        group: apache
        mode: '0755'
        
    - name: Install additional packages
      yum:
        name:
          - mod_ssl
          - httpd-tools
        state: present
        
  handlers:
    - name: restart apache
      systemd:
        name: httpd
        state: restarted
Save and exit the editor.
Task 2: Use ansible-playbook to Run the Playbook
Subtask 2.1: Execute the Basic Playbook
Now let's run our playbooks and observe the results.

Run the basic webserver setup playbook:
ansible-playbook -i inventory webserver-setup.yml
Observe the output. You should see:

Task execution status for each managed node
Changed status for tasks that modify the system
OK status for tasks that find the system already in the desired state
Run the playbook again to see idempotency in action:

ansible-playbook -i inventory webserver-setup.yml
Notice that most tasks now show OK instead of Changed, demonstrating Ansible's idempotent behavior.

Subtask 2.2: Use Tags to Run Specific Tasks
Tags allow you to run only specific parts of a playbook.

Run only the installation tasks:
ansible-playbook -i inventory webserver-setup.yml --tags "install"
Run multiple specific tags:
ansible-playbook -i inventory webserver-setup.yml --tags "service,content"
Skip specific tags:
ansible-playbook -i inventory webserver-setup.yml --skip-tags "firewall"
Subtask 2.3: Execute with Different Verbosity Levels
Ansible provides different verbosity levels to help with troubleshooting.

Run with increased verbosity:
ansible-playbook -i inventory webserver-setup.yml -v
Run with maximum verbosity for detailed debugging:
ansible-playbook -i inventory webserver-setup.yml -vvv
Run the advanced configuration playbook:
ansible-playbook -i inventory advanced-config.yml -v
Task 3: Debug Playbooks Using ansible-playbook --check
Subtask 3.1: Use Check Mode for Dry Runs
Check mode (also called "dry run") shows what changes would be made without actually making them.

Run the basic playbook in check mode:
ansible-playbook -i inventory webserver-setup.yml --check
Observe the output. Tasks will show what would change, marked with changed status, but no actual changes are made to the target systems.

Combine check mode with verbosity:

ansible-playbook -i inventory webserver-setup.yml --check -v
Subtask 3.2: Create a Playbook with Intentional Errors
Let's create a playbook with common errors to practice debugging.

Create a playbook with errors:
nano debug-practice.yml
Add the following content with intentional mistakes:
---
- name: Debugging Practice Playbook
  hosts: webservers
  become: yes
  
  tasks:
    # Error 1: Incorrect indentation
  - name: Install package with wrong indentation
    yum:
      name: htop
      state: present
      
    # Error 2: Missing required parameter
    - name: Create directory without path
      file:
        state: directory
        mode: '0755'
        
    # Error 3: Invalid module parameter
    - name: Copy file with invalid parameter
      copy:
        source: /tmp/nonexistent.txt
        dest: /tmp/test.txt
        invalid_param: yes
        
    # Error 4: Syntax error in template
    - name: Create file with template error
      copy:
        content: "Hello {{ inventory_hostname"
        dest: /tmp/broken.txt
Save and exit the editor.
Subtask 3.3: Debug the Problematic Playbook
Run the problematic playbook in check mode:
ansible-playbook -i inventory debug-practice.yml --check
Analyze the error messages. You'll see various types of errors:

YAML syntax errors (indentation issues)
Missing required parameters
Invalid module parameters
Template syntax errors
Fix the errors one by one. Create a corrected version:

nano debug-practice-fixed.yml
Add the corrected content:
---
- name: Debugging Practice Playbook (Fixed)
  hosts: webservers
  become: yes
  
  tasks:
    # Fixed: Correct indentation
    - name: Install package with correct indentation
      yum:
        name: htop
        state: present
        
    # Fixed: Added required path parameter
    - name: Create directory with proper parameters
      file:
        path: /tmp/ansible-test
        state: directory
        mode: '0755'
        
    # Fixed: Removed invalid parameter and used existing source
    - name: Copy file with valid parameters
      copy:
        content: "This is a test file created by Ansible"
        dest: /tmp/test.txt
        mode: '0644'
        
    # Fixed: Corrected template syntax
    - name: Create file with proper template
      copy:
        content: "Hello {{ inventory_hostname }}!"
        dest: /tmp/greeting.txt
        mode: '0644'
Test the fixed playbook:
ansible-playbook -i inventory debug-practice-fixed.yml --check
Subtask 3.4: Advanced Debugging Techniques
Use the debug module to inspect variables. Create a debugging playbook:
nano variable-debug.yml
Add debugging content:
---
- name: Variable Debugging Example
  hosts: webservers
  become: yes
  gather_facts: yes
  
  vars:
    custom_message: "Hello from Ansible"
    package_list:
      - vim
      - curl
      - wget
  
  tasks:
    - name: Debug custom variables
      debug:
        msg: "Custom message is: {{ custom_message }}"
        
    - name: Debug system facts
      debug:
        var: ansible_distribution
        
    - name: Debug multiple variables
      debug:
        msg: |
          Hostname: {{ inventory_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Architecture: {{ ansible_architecture }}
          IP Address: {{ ansible_default_ipv4.address }}
          
    - name: Debug list variables
      debug:
        msg: "Package {{ item }} will be installed"
      loop: "{{ package_list }}"
      
    - name: Conditional debugging
      debug:
        msg: "This is a Red Hat-based system"
      when: ansible_os_family == "RedHat"
Run the debugging playbook:
ansible-playbook -i inventory variable-debug.yml
Subtask 3.5: Syntax Validation
Use ansible-playbook syntax check:
ansible-playbook -i inventory webserver-setup.yml --syntax-check
Check syntax of the problematic playbook:
ansible-playbook -i inventory debug-practice.yml --syntax-check
Validate the fixed playbook:
ansible-playbook -i inventory debug-practice-fixed.yml --syntax-check
Advanced Debugging and Best Practices
Error Handling and Recovery
Create a playbook with error handling:
nano error-handling.yml
Add error handling examples:
---
- name: Error Handling Examples
  hosts: webservers
  become: yes
  
  tasks:
    - name: Task that might fail
      command: /bin/false
      ignore_errors: yes
      register: result
      
    - name: Show result of previous task
      debug:
        var: result
        
    - name: Task with error handling
      block:
        - name: Attempt to install non-existent package
          yum:
            name: non-existent-package
            state: present
      rescue:
        - name: Handle the error
          debug:
            msg: "Package installation failed, continuing with alternative"
        - name: Install alternative package
          yum:
            name: htop
            state: present
      always:
        - name: This always runs
          debug:
            msg: "Cleanup or logging task"
Run the error handling playbook:
ansible-playbook -i inventory error-handling.yml -v
Performance and Optimization
Create a playbook demonstrating performance features:
nano performance-demo.yml
Add performance optimization examples:
---
- name: Performance Optimization Demo
  hosts: webservers
  become: yes
  strategy: free  # Allows hosts to run independently
  
  tasks:
    - name: Install multiple packages efficiently
      yum:
        name:
          - git
          - tree
          - unzip
          - wget
        state: present
        
    - name: Parallel file creation
      copy:
        content: "File {{ item }}"
        dest: "/tmp/file{{ item }}.txt"
      loop:
        - 1
        - 2
        - 3
        - 4
        - 5
      async: 10  # Run asynchronously
      poll: 0    # Fire and forget
      register: async_results
      
    - name: Wait for async tasks to complete
      async_status:
        jid: "{{ item.ansible_job_id }}"
      loop: "{{ async_results.results }}"
      register: async_poll_results
      until: async_poll_results.finished
      retries: 10
      delay: 1
Run with timing information:
time ansible-playbook -i inventory performance-demo.yml
Troubleshooting Common Issues
Common Error Types and Solutions
YAML Syntax Errors:

Problem: Incorrect indentation or formatting
Solution: Use consistent spacing (2 or 4 spaces, not tabs)
Check: Use --syntax-check flag
Module Parameter Errors:

Problem: Invalid or missing required parameters
Solution: Check module documentation with ansible-doc module_name
Example: ansible-doc yum
Connection Issues:

Problem: Cannot connect to managed nodes
Solution: Verify SSH connectivity and credentials
Check: ansible all -i inventory -m ping
Permission Errors:

Problem: Insufficient privileges for tasks
Solution: Use become: yes or check sudo configuration
Debug: Run with -vvv for detailed error messages
Verification Commands
After completing the lab, verify your work:

Check Apache installation and status:
ansible webservers -i inventory -m command -a "systemctl status httpd" --become
Verify web content:
ansible webservers -i inventory -m uri -a "url=http://{{ inventory_hostname }} method=GET"
List installed packages:
ansible webservers -i inventory -m command -a "rpm -qa | grep httpd" --become
Conclusion
In this lab, you have successfully:

Created structured Ansible playbooks using proper YAML syntax and best practices
Executed playbooks using various ansible-playbook command options and flags
Implemented debugging techniques including check mode, verbosity levels, and syntax validation
Configured system packages and services using Ansible modules like yum, systemd, and copy
Handled errors gracefully using blocks, rescue, and error handling strategies
Optimized playbook performance using parallel execution and asynchronous tasks
Why This Matters: These skills are fundamental for Red Hat Certified Engineer (RHCE) certification and real-world automation scenarios. Ansible playbooks are the primary way to define and execute complex system configurations at scale. The debugging techniques you've learned will help you troubleshoot issues quickly and efficiently in production environments.

Key Takeaways:

Always use check mode (--check) before running playbooks in production
Leverage verbosity flags (-v, -vv, -vvv) for troubleshooting
Implement proper error handling to make playbooks more robust
Use tags to run specific portions of large playbooks
Practice idempotency to ensure playbooks can be run multiple times safely
You now have the foundation to write, execute, and debug Ansible playbooks effectively, preparing you for more advanced automation challenges and the RHCE certification exam.
