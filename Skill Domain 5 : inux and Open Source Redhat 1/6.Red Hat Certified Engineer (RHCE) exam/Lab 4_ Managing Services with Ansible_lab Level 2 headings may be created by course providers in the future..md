Lab 4: Managing Services with Ansible
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of service management using Ansible
Write playbooks to automate service management tasks using the systemd module
Enable and start the httpd service on multiple remote machines
Create and implement handlers to restart services when configuration files change
Apply best practices for service management automation in enterprise environments
Troubleshoot common service management issues using Ansible
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Knowledge of Ansible fundamentals (inventories, playbooks, modules)
Understanding of systemd service management concepts
Experience with SSH key-based authentication
Basic knowledge of web server concepts (Apache HTTP Server)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes:

1 Ansible Control Node (CentOS/RHEL 8 or 9)
3 Managed Nodes (CentOS/RHEL 8 or 9)
Pre-installed Ansible on the control node
SSH key-based authentication already configured
All necessary packages and dependencies installed
Task 1: Understanding Service Management with Ansible
Subtask 1.1: Explore the systemd Module
First, let's understand the capabilities of Ansible's systemd module for service management.

Connect to your Ansible control node and examine the systemd module documentation:
ansible-doc systemd
Review key parameters of the systemd module:

name: The name of the service
state: Desired state (started, stopped, restarted, reloaded)
enabled: Whether the service should start on boot (yes/no)
daemon_reload: Reload systemd manager configuration
Create a working directory for this lab:

mkdir -p ~/ansible-labs/lab4-services
cd ~/ansible-labs/lab4-services
Subtask 1.2: Verify Your Inventory
Create an inventory file to define your managed hosts:
cat > inventory.ini << 'EOF'
[webservers]
node1 ansible_host=10.0.1.10
node2 ansible_host=10.0.1.11
node3 ansible_host=10.0.1.12

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Test connectivity to all managed nodes:
ansible all -i inventory.ini -m ping
Expected output should show SUCCESS for all nodes.

Task 2: Write a Playbook to Manage Services Using systemd Module
Subtask 2.1: Create a Basic Service Management Playbook
Create a comprehensive service management playbook:
cat > service-management.yml << 'EOF'
---
- name: Service Management with Ansible
  hosts: webservers
  become: yes
  vars:
    services_to_manage:
      - name: httpd
        state: started
        enabled: yes
      - name: firewalld
        state: started
        enabled: yes
  
  tasks:
    - name: Display current hostname
      debug:
        msg: "Managing services on {{ inventory_hostname }}"
    
    - name: Check if systemd is available
      command: systemctl --version
      register: systemd_check
      changed_when: false
      failed_when: systemd_check.rc != 0
    
    - name: Display systemd version
      debug:
        msg: "systemd version: {{ systemd_check.stdout_lines[0] }}"
    
    - name: Install required packages
      yum:
        name:
          - httpd
          - firewalld
        state: present
    
    - name: Manage multiple services
      systemd:
        name: "{{ item.name }}"
        state: "{{ item.state }}"
        enabled: "{{ item.enabled }}"
        daemon_reload: yes
      loop: "{{ services_to_manage }}"
      register: service_results
    
    - name: Display service management results
      debug:
        msg: "Service {{ item.item.name }} - Changed: {{ item.changed }}"
      loop: "{{ service_results.results }}"
EOF
Execute the playbook to manage services:
ansible-playbook -i inventory.ini service-management.yml
Subtask 2.2: Verify Service Status
Create a verification playbook to check service status:
cat > verify-services.yml << 'EOF'
---
- name: Verify Service Status
  hosts: webservers
  become: yes
  
  tasks:
    - name: Check httpd service status
      systemd:
        name: httpd
      register: httpd_status
    
    - name: Display httpd service information
      debug:
        msg: |
          Service: httpd
          Active: {{ httpd_status.status.ActiveState }}
          Enabled: {{ httpd_status.status.UnitFileState }}
          Main PID: {{ httpd_status.status.MainPID }}
    
    - name: Check if httpd is listening on port 80
      wait_for:
        port: 80
        host: "{{ ansible_default_ipv4.address }}"
        timeout: 10
      register: port_check
      ignore_errors: yes
    
    - name: Display port status
      debug:
        msg: "HTTP port 80 is {{ 'accessible' if port_check is succeeded else 'not accessible' }}"
EOF
Run the verification playbook:
ansible-playbook -i inventory.ini verify-services.yml
Task 3: Enable and Start httpd Service on Multiple Machines
Subtask 3.1: Create a Dedicated Web Server Setup Playbook
Create a comprehensive web server deployment playbook:
cat > webserver-setup.yml << 'EOF'
---
- name: Deploy and Configure Apache Web Servers
  hosts: webservers
  become: yes
  vars:
    web_service: httpd
    web_port: 80
    document_root: /var/www/html
  
  tasks:
    - name: Install Apache HTTP Server
      yum:
        name: "{{ web_service }}"
        state: present
      tags: install
    
    - name: Create custom index.html for each server
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Welcome to {{ inventory_hostname }}</title>
              <style>
                  body { font-family: Arial, sans-serif; margin: 40px; }
                  .header { color: #2c3e50; text-align: center; }
                  .info { background-color: #ecf0f1; padding: 20px; border-radius: 5px; }
              </style>
          </head>
          <body>
              <h1 class="header">Apache Web Server</h1>
              <div class="info">
                  <h2>Server Information</h2>
                  <p><strong>Hostname:</strong> {{ inventory_hostname }}</p>
                  <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
                  <p><strong>Managed by:</strong> Ansible</p>
                  <p><strong>Service Status:</strong> Active and Running</p>
              </div>
          </body>
          </html>
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      tags: content
    
    - name: Start and enable Apache service
      systemd:
        name: "{{ web_service }}"
        state: started
        enabled: yes
        daemon_reload: yes
      register: apache_service
      tags: service
    
    - name: Configure firewall for HTTP traffic
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      tags: firewall
    
    - name: Verify Apache is responding
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      register: web_response
      retries: 3
      delay: 5
      tags: verify
    
    - name: Display service status
      debug:
        msg: |
          Apache Service Status:
          - Service: {{ web_service }}
          - State: {{ 'Started' if apache_service.changed else 'Already Running' }}
          - Enabled: {{ apache_service.enabled }}
          - Web Response: {{ web_response.status }} {{ web_response.msg }}
      tags: status
EOF
Execute the web server setup playbook:
ansible-playbook -i inventory.ini webserver-setup.yml
Subtask 3.2: Test Web Server Functionality
Create a comprehensive testing playbook:
cat > test-webservers.yml << 'EOF'
---
- name: Test Web Server Functionality
  hosts: webservers
  become: yes
  
  tasks:
    - name: Gather service facts
      service_facts:
    
    - name: Verify httpd service is running
      assert:
        that:
          - ansible_facts.services['httpd.service'].state == 'running'
          - ansible_facts.services['httpd.service'].status == 'enabled'
        fail_msg: "Apache service is not properly configured"
        success_msg: "Apache service is running and enabled"
    
    - name: Check Apache process
      command: pgrep -f httpd
      register: apache_processes
      changed_when: false
    
    - name: Display Apache process count
      debug:
        msg: "Apache processes running: {{ apache_processes.stdout_lines | length }}"
    
    - name: Test HTTP response from localhost
      uri:
        url: "http://localhost"
        return_content: yes
      register: local_response
    
    - name: Verify response contains expected content
      assert:
        that:
          - "'Apache Web Server' in local_response.content"
          - "inventory_hostname in local_response.content"
        fail_msg: "Web server response does not contain expected content"
        success_msg: "Web server is serving correct content"

- name: Test Web Servers from Control Node
  hosts: localhost
  connection: local
  
  tasks:
    - name: Test connectivity to all web servers
      uri:
        url: "http://{{ hostvars[item]['ansible_default_ipv4']['address'] }}"
        method: GET
        status_code: 200
      loop: "{{ groups['webservers'] }}"
      register: external_tests
    
    - name: Display external test results
      debug:
        msg: "Successfully connected to {{ item.item }} - Status: {{ item.status }}"
      loop: "{{ external_tests.results }}"
EOF
Run the testing playbook:
ansible-playbook -i inventory.ini test-webservers.yml
Task 4: Create Handlers to Restart Services When Configuration Files Change
Subtask 4.1: Understanding Ansible Handlers
Handlers are special tasks that run only when notified by other tasks. They're perfect for restarting services when configuration files change.

Create a playbook with handlers for configuration management:
cat > config-with-handlers.yml << 'EOF'
---
- name: Apache Configuration Management with Handlers
  hosts: webservers
  become: yes
  vars:
    apache_config_dir: /etc/httpd/conf.d
    custom_config_file: "{{ apache_config_dir }}/custom.conf"
  
  handlers:
    - name: restart apache
      systemd:
        name: httpd
        state: restarted
      listen: "restart web services"
    
    - name: reload apache
      systemd:
        name: httpd
        state: reloaded
      listen: "reload web services"
    
    - name: restart firewalld
      systemd:
        name: firewalld
        state: restarted
      listen: "restart firewall"
  
  tasks:
    - name: Ensure Apache is installed
      yum:
        name: httpd
        state: present
    
    - name: Create custom Apache configuration
      copy:
        content: |
          # Custom Apache Configuration
          # Managed by Ansible - Do not edit manually
          
          # Security Headers
          Header always set X-Content-Type-Options nosniff
          Header always set X-Frame-Options DENY
          Header always set X-XSS-Protection "1; mode=block"
          
          # Performance Settings
          KeepAlive On
          MaxKeepAliveRequests 100
          KeepAliveTimeout 15
          
          # Custom Log Format
          LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined_custom
          
          # Virtual Host Configuration
          <VirtualHost *:80>
              ServerName {{ inventory_hostname }}
              DocumentRoot /var/www/html
              ErrorLog logs/{{ inventory_hostname }}_error.log
              CustomLog logs/{{ inventory_hostname }}_access.log combined_custom
          </VirtualHost>
        dest: "{{ custom_config_file }}"
        owner: root
        group: root
        mode: '0644'
        backup: yes
      notify:
        - "restart web services"
      register: config_result
    
    - name: Update main Apache configuration
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        regexp: '^ServerTokens'
        line: 'ServerTokens Prod'
        backup: yes
      notify:
        - "reload web services"
    
    - name: Configure Apache to hide version information
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        regexp: '^ServerSignature'
        line: 'ServerSignature Off'
        backup: yes
      notify:
        - "reload web services"
    
    - name: Ensure Apache is started and enabled
      systemd:
        name: httpd
        state: started
        enabled: yes
    
    - name: Create a test page to verify configuration
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Configuration Test - {{ inventory_hostname }}</title>
          </head>
          <body>
              <h1>Apache Configuration Updated</h1>
              <p>Server: {{ inventory_hostname }}</p>
              <p>Configuration last updated: {{ ansible_date_time.iso8601 }}</p>
              <p>Custom configuration applied successfully!</p>
          </body>
          </html>
        dest: /var/www/html/config-test.html
        owner: apache
        group: apache
        mode: '0644'
    
    - name: Display configuration change status
      debug:
        msg: |
          Configuration Status:
          - Custom config changed: {{ config_result.changed }}
          - Handlers will {{ 'be triggered' if config_result.changed else 'not be triggered' }}
EOF
Execute the configuration playbook:
ansible-playbook -i inventory.ini config-with-handlers.yml
Subtask 4.2: Advanced Handler Implementation
Create a more complex playbook with multiple configuration scenarios:
cat > advanced-handlers.yml << 'EOF'
---
- name: Advanced Service Management with Handlers
  hosts: webservers
  become: yes
  vars:
    config_timestamp: "{{ ansible_date_time.epoch }}"
  
  handlers:
    - name: restart apache service
      systemd:
        name: httpd
        state: restarted
      listen: "apache restart"
    
    - name: reload apache configuration
      systemd:
        name: httpd
        state: reloaded
      listen: "apache reload"
    
    - name: validate apache configuration
      command: httpd -t
      listen: "apache restart"
      listen: "apache reload"
    
    - name: restart firewall service
      systemd:
        name: firewalld
        state: restarted
      listen: "firewall restart"
  
  tasks:
    - name: Install required packages
      yum:
        name:
          - httpd
          - mod_ssl
        state: present
    
    - name: Create SSL configuration directory
      file:
        path: /etc/httpd/conf.d/ssl
        state: directory
        owner: root
        group: root
        mode: '0755'
    
    - name: Configure SSL settings
      copy:
        content: |
          # SSL Configuration
          LoadModule ssl_module modules/mod_ssl.so
          
          <IfModule mod_ssl.c>
              SSLEngine on
              SSLProtocol all -SSLv2 -SSLv3
              SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5:!SEED:!IDEA
              SSLHonorCipherOrder on
          </IfModule>
        dest: /etc/httpd/conf.d/ssl/ssl-security.conf
        owner: root
        group: root
        mode: '0644'
      notify: "apache reload"
    
    - name: Update Apache security configuration
      blockinfile:
        path: /etc/httpd/conf/httpd.conf
        block: |
          # Security Configuration - Managed by Ansible
          ServerTokens Prod
          ServerSignature Off
          
          # Hide .htaccess files
          <Files ".ht*">
              Require all denied
          </Files>
          
          # Prevent access to version control directories
          <DirectoryMatch "/\.git">
              Require all denied
          </DirectoryMatch>
        marker: "# {mark} ANSIBLE MANAGED SECURITY BLOCK"
        backup: yes
      notify: "apache restart"
    
    - name: Configure custom error pages
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Error 404 - Page Not Found</title>
              <style>
                  body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
                  .error { color: #e74c3c; }
              </style>
          </head>
          <body>
              <h1 class="error">404 - Page Not Found</h1>
              <p>The requested page could not be found on {{ inventory_hostname }}</p>
              <p><a href="/">Return to Home Page</a></p>
          </body>
          </html>
        dest: /var/www/html/404.html
        owner: apache
        group: apache
        mode: '0644'
    
    - name: Configure custom error page directive
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        line: 'ErrorDocument 404 /404.html'
        backup: yes
      notify: "apache reload"
    
    - name: Configure firewall for HTTPS
      firewalld:
        service: https
        permanent: yes
        state: enabled
        immediate: yes
      notify: "firewall restart"
    
    - name: Ensure services are running
      systemd:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - httpd
        - firewalld
    
    - name: Force handler execution for demonstration
      meta: flush_handlers
    
    - name: Verify Apache configuration is valid
      command: httpd -t
      register: apache_config_test
      changed_when: false
    
    - name: Display configuration test results
      debug:
        msg: "Apache configuration test: {{ apache_config_test.stderr }}"
EOF
Run the advanced handlers playbook:
ansible-playbook -i inventory.ini advanced-handlers.yml
Subtask 4.3: Testing Handler Functionality
Create a playbook to test handler triggers:
cat > test-handlers.yml << 'EOF'
---
- name: Test Handler Functionality
  hosts: webservers
  become: yes
  
  handlers:
    - name: test restart handler
      debug:
        msg: "Handler triggered: Apache would be restarted here"
      listen: "test apache restart"
  
  tasks:
    - name: Make a configuration change (this will trigger handler)
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        regexp: '^#ServerName'
        line: 'ServerName {{ inventory_hostname }}'
        backup: yes
      notify: "test apache restart"
    
    - name: Make no change (this will NOT trigger handler)
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        regexp: '^ServerName {{ inventory_hostname }}'
        line: 'ServerName {{ inventory_hostname }}'
    
    - name: Display handler behavior explanation
      debug:
        msg: |
          Handler Behavior:
          - Handlers only run when notified by tasks that report 'changed'
          - If a task doesn't change anything, handlers won't be triggered
          - Handlers run at the end of the play, after all tasks complete
          - Multiple tasks can notify the same handler, but it only runs once
EOF
Execute the handler test:
ansible-playbook -i inventory.ini test-handlers.yml
Troubleshooting Common Issues
Service Management Issues
Service fails to start:
# Check service status
ansible webservers -i inventory.ini -m systemd -a "name=httpd" -b

# Check service logs
ansible webservers -i inventory.ini -m shell -a "journalctl -u httpd --no-pager -n 20" -b
Configuration syntax errors:
# Test Apache configuration
ansible webservers -i inventory.ini -m shell -a "httpd -t" -b
Firewall blocking connections:
# Check firewall status
ansible webservers -i inventory.ini -m shell -a "firewall-cmd --list-all" -b
Handler Issues
Handlers not triggering:

Ensure tasks report changed: true
Check notification syntax matches handler names
Verify handlers are defined in the correct play
Force handler execution:

- name: Force handlers to run immediately
  meta: flush_handlers
Verification and Testing
Final Verification Playbook
Create a comprehensive verification script:

cat > final-verification.yml << 'EOF'
---
- name: Final Lab Verification
  hosts: webservers
  become: yes
  
  tasks:
    - name: Gather all service facts
      service_facts:
    
    - name: Verify Apache service status
      assert:
        that:
          - ansible_facts.services['httpd.service'].state == 'running'
          - ansible_facts.services['httpd.service'].status == 'enabled'
        success_msg: "✓ Apache service is properly configured"
        fail_msg: "✗ Apache service configuration failed"
    
    - name: Test web server response
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        status_code: 200
      register: web_test
    
    - name: Test custom error page
      uri:
        url: "http://{{ ansible_default_ipv4.address }}/nonexistent-page"
        status_code: 404
      register: error_test
    
    - name: Display verification results
      debug:
        msg: |
          Verification Results for {{ inventory_hostname }}:
          ✓ Apache service: Running and Enabled
          ✓ Web server responding: {{ web_test.status }}
          ✓ Custom error page: {{ error_test.status }}
          ✓ Configuration management: Complete
          ✓ Handler functionality: Implemented

- name: Generate Lab Summary Report
  hosts: localhost
  connection: local
  
  tasks:
    - name: Create lab completion summary
      debug:
        msg: |
          
          ==========================================
          LAB 4 COMPLETION SUMMARY
          ==========================================
          
          ✓ Task 1: Service management with systemd module - COMPLETED
          ✓ Task 2: Playbook creation for service management - COMPLETED  
          ✓ Task 3: Apache deployment on multiple machines - COMPLETED
          ✓ Task 4: Handler implementation for configuration changes - COMPLETED
          
          Skills Demonstrated:
          • Automated service management using Ansible
          • systemd module usage for service control
          • Handler implementation for configuration management
          • Multi-host service deployment
          • Service verification and testing
          
          Next Steps:
          • Practice with different service types
          • Explore advanced handler patterns
          • Implement service monitoring playbooks
          • Study service dependencies and ordering
          
          ==========================================
EOF
Run the final verification:

ansible-playbook -i inventory.ini final-verification.yml
Conclusion
Congratulations! You have successfully completed Lab 4: Managing Services with Ansible. In this comprehensive lab, you have accomplished the following:

Key Achievements
Service Management Mastery: You learned to use Ansible's systemd module to automate service management tasks including starting, stopping, enabling, and disabling services across multiple hosts.

Apache Web Server Deployment: You successfully deployed and configured Apache HTTP Server on multiple machines, demonstrating practical service management in a real-world scenario.

Handler Implementation: You created and implemented handlers that automatically restart or reload services when configuration files change, showcasing advanced automation patterns.

Configuration Management: You applied configuration management best practices, including backup creation, validation, and systematic deployment across multiple hosts.

Why This Matters
Service management is a critical skill for system administrators and DevOps engineers because:

Automation Reduces Errors: Manual service management is prone to human error and inconsistency
Scalability: Managing services across hundreds of servers manually is impractical
Consistency: Ansible ensures identical service configurations across all managed hosts
Efficiency: Automated service management saves time and reduces operational overhead
Reliability: Handlers ensure services are properly restarted when configurations change
Real-World Applications
The skills you've developed in this lab directly apply to:

Web Server Farm Management: Deploying and maintaining multiple web servers
Microservices Architecture: Managing containerized services and their dependencies
Database Cluster Management: Coordinating database service restarts and configuration updates
Load Balancer Configuration: Managing reverse proxy and load balancing services
Security Updates: Systematically applying security patches and restarting affected services
RHCE Exam Relevance
This lab directly prepares you for Red Hat Certified Engineer (RHCE) exam objectives including:

Managing system services using Ansible
Creating and using handlers in playbooks
Implementing configuration management strategies
Automating system administration tasks
Troubleshooting service-related issues
Next Steps for Continued Learning
Explore Advanced Service Patterns: Study service dependencies, ordering, and complex restart scenarios
Implement Monitoring: Add service health checks and monitoring to your playbooks
Practice with Different Services: Apply these concepts to databases, message queues, and other services
Study Rolling Updates: Learn to update services without downtime using Ansible strategies
Security Hardening: Implement security best practices for service configuration management
You now have the foundational skills to manage services at scale using Ansible, a crucial capability for modern infrastructure automation and the RHCE certification path.
