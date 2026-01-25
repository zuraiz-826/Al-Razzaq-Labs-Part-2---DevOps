Lab 17: Automating Service Management with Ansible
Objectives
By the end of this lab, you will be able to:

Create Ansible playbooks to automate service management using the systemd module
Implement handlers to restart services only when configuration changes occur
Validate service status and configurations across multiple hosts
Apply best practices for service automation in enterprise environments
Understand the relationship between configuration changes and service restarts
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux system administration
Familiarity with systemd service management
Knowledge of YAML syntax and structure
Previous experience with Ansible basics (inventory, playbooks, modules)
Understanding of SSH key-based authentication
Basic text editor skills (vim, nano, or similar)
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab and you'll have access to:

1 Ansible Control Node (CentOS/RHEL 8 or 9)
2 Managed Nodes (CentOS/RHEL 8 or 9)
Pre-configured SSH connectivity
Ansible already installed on the control node
No need to build your own VMs or configure networking!

Task 1: Setting Up the Lab Environment
Subtask 1.1: Verify Ansible Installation and Connectivity
Connect to your control node and verify Ansible installation:
ansible --version
Create a working directory for this lab:
mkdir -p ~/ansible-service-lab
cd ~/ansible-service-lab
Create an inventory file to define your managed hosts:
cat > inventory.ini << 'EOF'
[webservers]
node1 ansible_host=10.0.1.10
node2 ansible_host=10.0.1.11

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Note: Replace the IP addresses with your actual managed node IPs provided in the lab environment.

Test connectivity to all managed nodes:
ansible all -i inventory.ini -m ping
Expected output should show SUCCESS for both nodes.

Subtask 1.2: Install Required Services on Managed Nodes
Create a setup playbook to install Apache HTTP server:
cat > setup-services.yml << 'EOF'
---
- name: Setup Services for Management Lab
  hosts: webservers
  become: yes
  tasks:
    - name: Install Apache HTTP Server
      yum:
        name: httpd
        state: present
      when: ansible_os_family == "RedHat"

    - name: Install Apache HTTP Server (Ubuntu/Debian)
      apt:
        name: apache2
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"

    - name: Create custom web content directory
      file:
        path: /var/www/html/custom
        state: directory
        mode: '0755'
EOF
Run the setup playbook:
ansible-playbook -i inventory.ini setup-services.yml
Task 2: Writing Playbooks to Manage Services Using systemd Module
Subtask 2.1: Create Basic Service Management Playbook
Create a comprehensive service management playbook:
cat > service-management.yml << 'EOF'
---
- name: Comprehensive Service Management with Ansible
  hosts: webservers
  become: yes
  vars:
    web_service_name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
    web_port: 80
    custom_index_content: |
      <!DOCTYPE html>
      <html>
      <head>
          <title>Ansible Managed Server</title>
      </head>
      <body>
          <h1>Welcome to {{ inventory_hostname }}</h1>
          <p>This server is managed by Ansible</p>
          <p>Service: {{ web_service_name }}</p>
          <p>Last updated: {{ ansible_date_time.iso8601 }}</p>
      </body>
      </html>

  tasks:
    - name: Ensure web service is installed
      package:
        name: "{{ web_service_name }}"
        state: present

    - name: Create custom index.html
      copy:
        content: "{{ custom_index_content }}"
        dest: /var/www/html/index.html
        mode: '0644'
      notify: restart web service

    - name: Configure firewall for web service (RHEL/CentOS)
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      when: ansible_os_family == "RedHat"
      ignore_errors: yes

    - name: Ensure web service is started and enabled
      systemd:
        name: "{{ web_service_name }}"
        state: started
        enabled: yes
        daemon_reload: yes

    - name: Check if web service is listening on port {{ web_port }}
      wait_for:
        port: "{{ web_port }}"
        host: "{{ ansible_default_ipv4.address }}"
        timeout: 30
      delegate_to: localhost

  handlers:
    - name: restart web service
      systemd:
        name: "{{ web_service_name }}"
        state: restarted
EOF
Run the service management playbook:
ansible-playbook -i inventory.ini service-management.yml
Subtask 2.2: Advanced Service Management with Multiple Services
Create an advanced playbook managing multiple services:
cat > advanced-service-management.yml << 'EOF'
---
- name: Advanced Multi-Service Management
  hosts: webservers
  become: yes
  vars:
    services_to_manage:
      - name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
        state: started
        enabled: yes
        config_file: "{{ '/etc/httpd/conf/httpd.conf' if ansible_os_family == 'RedHat' else '/etc/apache2/apache2.conf' }}"
      - name: "{{ 'crond' if ansible_os_family == 'RedHat' else 'cron' }}"
        state: started
        enabled: yes
        config_file: /etc/crontab

  tasks:
    - name: Display services to be managed
      debug:
        msg: "Managing service: {{ item.name }}"
      loop: "{{ services_to_manage }}"

    - name: Ensure all required services are installed
      package:
        name: "{{ item.name }}"
        state: present
      loop: "{{ services_to_manage }}"
      ignore_errors: yes

    - name: Manage service states using systemd
      systemd:
        name: "{{ item.name }}"
        state: "{{ item.state }}"
        enabled: "{{ item.enabled }}"
        daemon_reload: yes
      loop: "{{ services_to_manage }}"
      register: service_results

    - name: Display service management results
      debug:
        msg: "Service {{ item.item.name }}: State={{ item.state }}, Changed={{ item.changed }}"
      loop: "{{ service_results.results }}"

    - name: Verify service status
      systemd:
        name: "{{ item.name }}"
      loop: "{{ services_to_manage }}"
      register: service_status

    - name: Report service status
      debug:
        msg: "{{ item.item.name }} is {{ 'active' if item.status.ActiveState == 'active' else 'inactive' }}"
      loop: "{{ service_status.results }}"
EOF
Execute the advanced service management playbook:
ansible-playbook -i inventory.ini advanced-service-management.yml
Task 3: Using Handlers to Restart Services Only When Necessary
Subtask 3.1: Understanding Handlers and Notifications
Create a playbook demonstrating handler usage:
cat > handler-demo.yml << 'EOF'
---
- name: Demonstrating Handlers for Service Management
  hosts: webservers
  become: yes
  vars:
    web_service: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
    config_path: "{{ '/etc/httpd/conf.d' if ansible_os_family == 'RedHat' else '/etc/apache2/sites-available' }}"

  tasks:
    - name: Create custom Apache configuration
      copy:
        content: |
          # Custom configuration managed by Ansible
          ServerTokens Prod
          ServerSignature Off
          
          # Custom virtual host
          <VirtualHost *:80>
              ServerName {{ inventory_hostname }}
              DocumentRoot /var/www/html
              ErrorLog logs/{{ inventory_hostname }}_error.log
              CustomLog logs/{{ inventory_hostname }}_access.log combined
          </VirtualHost>
        dest: "{{ config_path }}/ansible-custom.conf"
        mode: '0644'
      notify:
        - restart web service
        - validate web service

    - name: Update main index page with timestamp
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Ansible Handler Demo - {{ inventory_hostname }}</title>
          </head>
          <body>
              <h1>Handler Demonstration</h1>
              <p>Server: {{ inventory_hostname }}</p>
              <p>Configuration updated: {{ ansible_date_time.iso8601 }}</p>
              <p>This page triggers handler only when content changes</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        mode: '0644'
      notify: restart web service

    - name: Ensure web service is running
      systemd:
        name: "{{ web_service }}"
        state: started
        enabled: yes

  handlers:
    - name: restart web service
      systemd:
        name: "{{ web_service }}"
        state: restarted
      listen: "restart web service"

    - name: validate web service
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      delegate_to: localhost
      listen: "validate web service"
EOF
Run the handler demonstration playbook:
ansible-playbook -i inventory.ini handler-demo.yml
Run the playbook again to see that handlers are NOT triggered when no changes occur:
ansible-playbook -i inventory.ini handler-demo.yml
Subtask 3.2: Complex Handler Scenarios
Create a playbook with multiple handlers and conditions:
cat > complex-handlers.yml << 'EOF'
---
- name: Complex Handler Scenarios
  hosts: webservers
  become: yes
  vars:
    web_service: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
    backup_dir: /opt/ansible-backups

  tasks:
    - name: Create backup directory
      file:
        path: "{{ backup_dir }}"
        state: directory
        mode: '0755'

    - name: Backup current configuration
      copy:
        src: "{{ '/etc/httpd/conf/httpd.conf' if ansible_os_family == 'RedHat' else '/etc/apache2/apache2.conf' }}"
        dest: "{{ backup_dir }}/{{ web_service }}-{{ ansible_date_time.epoch }}.conf"
        remote_src: yes
      notify: log backup creation

    - name: Update service configuration
      lineinfile:
        path: "{{ '/etc/httpd/conf/httpd.conf' if ansible_os_family == 'RedHat' else '/etc/apache2/apache2.conf' }}"
        regexp: '^#?ServerTokens'
        line: 'ServerTokens Prod'
        backup: yes
      notify:
        - restart web service
        - validate configuration
        - send notification

    - name: Create monitoring script
      copy:
        content: |
          #!/bin/bash
          # Service monitoring script
          SERVICE="{{ web_service }}"
          if systemctl is-active --quiet $SERVICE; then
              echo "$(date): $SERVICE is running" >> /var/log/service-monitor.log
          else
              echo "$(date): $SERVICE is NOT running" >> /var/log/service-monitor.log
          fi
        dest: /usr/local/bin/monitor-service.sh
        mode: '0755'
      notify: setup monitoring

  handlers:
    - name: restart web service
      systemd:
        name: "{{ web_service }}"
        state: restarted
      listen: "restart web service"

    - name: validate configuration
      command: "{{ 'httpd -t' if ansible_os_family == 'RedHat' else 'apache2ctl configtest' }}"
      listen: "validate configuration"

    - name: send notification
      debug:
        msg: "Configuration updated and service restarted on {{ inventory_hostname }}"
      listen: "send notification"

    - name: log backup creation
      lineinfile:
        path: /var/log/ansible-backups.log
        line: "{{ ansible_date_time.iso8601 }}: Backup created for {{ web_service }} on {{ inventory_hostname }}"
        create: yes
      listen: "log backup creation"

    - name: setup monitoring
      cron:
        name: "Monitor {{ web_service }}"
        minute: "*/5"
        job: "/usr/local/bin/monitor-service.sh"
      listen: "setup monitoring"
EOF
Execute the complex handlers playbook:
ansible-playbook -i inventory.ini complex-handlers.yml
Task 4: Checking Service Status and Validating Service Configurations
Subtask 4.1: Service Status Verification
Create a comprehensive service validation playbook:
cat > service-validation.yml << 'EOF'
---
- name: Comprehensive Service Status and Configuration Validation
  hosts: webservers
  become: yes
  vars:
    web_service: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
    services_to_check:
      - "{{ web_service }}"
      - "{{ 'crond' if ansible_os_family == 'RedHat' else 'cron' }}"
      - sshd

  tasks:
    - name: Gather service facts
      service_facts:

    - name: Display all running services (first 10)
      debug:
        msg: "{{ item.key }} is {{ item.value.state }}"
      loop: "{{ ansible_facts.services | dict2items | selectattr('value.state', 'equalto', 'running') | list[:10] }}"

    - name: Check specific service status using systemd module
      systemd:
        name: "{{ item }}"
      register: service_check
      loop: "{{ services_to_check }}"

    - name: Report service status details
      debug:
        msg: |
          Service: {{ item.item }}
          Active State: {{ item.status.ActiveState }}
          Sub State: {{ item.status.SubState }}
          Enabled: {{ item.status.UnitFileState }}
          Main PID: {{ item.status.MainPID | default('N/A') }}
      loop: "{{ service_check.results }}"

    - name: Validate web service is responding
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
        timeout: 10
      delegate_to: localhost
      register: web_response

    - name: Display web service response
      debug:
        msg: "Web service responded with status: {{ web_response.status }}"

    - name: Check service ports
      wait_for:
        port: "{{ item.port }}"
        host: "{{ ansible_default_ipv4.address }}"
        timeout: 5
      delegate_to: localhost
      loop:
        - { service: "{{ web_service }}", port: 80 }
        - { service: "sshd", port: 22 }
      register: port_check

    - name: Report port status
      debug:
        msg: "Port {{ item.item.port }} for {{ item.item.service }} is {{ 'open' if not item.failed else 'closed' }}"
      loop: "{{ port_check.results }}"
EOF
Run the service validation playbook:
ansible-playbook -i inventory.ini service-validation.yml
Subtask 4.2: Configuration Validation and Health Checks
Create a health check and configuration validation playbook:
cat > health-check.yml << 'EOF'
---
- name: Service Health Check and Configuration Validation
  hosts: webservers
  become: yes
  vars:
    web_service: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
    config_file: "{{ '/etc/httpd/conf/httpd.conf' if ansible_os_family == 'RedHat' else '/etc/apache2/apache2.conf' }}"

  tasks:
    - name: Test web server configuration syntax
      command: "{{ 'httpd -t' if ansible_os_family == 'RedHat' else 'apache2ctl configtest' }}"
      register: config_test
      failed_when: config_test.rc != 0

    - name: Display configuration test results
      debug:
        msg: "Configuration test: {{ 'PASSED' if config_test.rc == 0 else 'FAILED' }}"

    - name: Check service memory usage
      shell: |
        ps aux | grep {{ web_service }} | grep -v grep | awk '{sum+=$6} END {print sum/1024 " MB"}'
      register: memory_usage

    - name: Display memory usage
      debug:
        msg: "{{ web_service }} memory usage: {{ memory_usage.stdout }}"

    - name: Check service uptime
      shell: |
        systemctl show {{ web_service }} --property=ActiveEnterTimestamp | cut -d= -f2
      register: service_uptime

    - name: Display service uptime
      debug:
        msg: "{{ web_service }} started at: {{ service_uptime.stdout }}"

    - name: Validate critical configuration parameters
      lineinfile:
        path: "{{ config_file }}"
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        state: present
      check_mode: yes
      register: config_validation
      loop:
        - { regexp: '^ServerTokens', line: 'ServerTokens Prod' }
        - { regexp: '^ServerSignature', line: 'ServerSignature Off' }

    - name: Report configuration validation
      debug:
        msg: "Configuration check for '{{ item.item.line }}': {{ 'OK' if not item.changed else 'NEEDS UPDATE' }}"
      loop: "{{ config_validation.results }}"

    - name: Create service health report
      copy:
        content: |
          Service Health Report for {{ inventory_hostname }}
          Generated: {{ ansible_date_time.iso8601 }}
          
          Service: {{ web_service }}
          Status: {{ ansible_facts.services[web_service].state | default('unknown') }}
          Configuration Test: {{ 'PASSED' if config_test.rc == 0 else 'FAILED' }}
          Memory Usage: {{ memory_usage.stdout }}
          Started: {{ service_uptime.stdout }}
          
          Port Connectivity:
          - Port 80: {{ 'OPEN' if web_response is defined and web_response.status == 200 else 'CLOSED' }}
          - Port 22: OPEN (SSH)
          
          Configuration Status:
          {% for item in config_validation.results %}
          - {{ item.item.line }}: {{ 'OK' if not item.changed else 'NEEDS UPDATE' }}
          {% endfor %}
        dest: "/tmp/service-health-{{ inventory_hostname }}.txt"
        mode: '0644'

    - name: Fetch health reports to control node
      fetch:
        src: "/tmp/service-health-{{ inventory_hostname }}.txt"
        dest: "./health-reports/"
        flat: yes
EOF
Execute the health check playbook:
ansible-playbook -i inventory.ini health-check.yml
View the generated health reports:
ls -la health-reports/
cat health-reports/service-health-*.txt
Subtask 4.3: Automated Service Recovery
Create a service recovery playbook:
cat > service-recovery.yml << 'EOF'
---
- name: Automated Service Recovery and Monitoring
  hosts: webservers
  become: yes
  vars:
    web_service: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
    max_restart_attempts: 3

  tasks:
    - name: Check if service is running
      systemd:
        name: "{{ web_service }}"
      register: service_status

    - name: Attempt service recovery if not running
      block:
        - name: Stop service gracefully
          systemd:
            name: "{{ web_service }}"
            state: stopped
          when: service_status.status.ActiveState != "active"

        - name: Clear any lock files
          file:
            path: "{{ item }}"
            state: absent
          loop:
            - /var/lock/subsys/httpd
            - /var/run/httpd/httpd.pid
          when: ansible_os_family == "RedHat"

        - name: Start service
          systemd:
            name: "{{ web_service }}"
            state: started
            daemon_reload: yes

        - name: Wait for service to be fully started
          wait_for:
            port: 80
            host: "{{ ansible_default_ipv4.address }}"
            timeout: 30
          delegate_to: localhost

        - name: Verify service is responding
          uri:
            url: "http://{{ ansible_default_ipv4.address }}"
            method: GET
            status_code: 200
          delegate_to: localhost

      rescue:
        - name: Log recovery failure
          debug:
            msg: "Failed to recover {{ web_service }} on {{ inventory_hostname }}"

        - name: Check system resources
          shell: |
            echo "=== DISK USAGE ==="
            df -h
            echo "=== MEMORY USAGE ==="
            free -h
            echo "=== LOAD AVERAGE ==="
            uptime
          register: system_resources

        - name: Display system resources
          debug:
            var: system_resources.stdout_lines

      when: service_status.status.ActiveState != "active"

    - name: Final service status check
      systemd:
        name: "{{ web_service }}"
      register: final_status

    - name: Report final status
      debug:
        msg: "{{ web_service }} final status: {{ final_status.status.ActiveState }}"
EOF
Run the service recovery playbook:
ansible-playbook -i inventory.ini service-recovery.yml
Verification and Testing
Final Verification Steps
Create a comprehensive verification script:
cat > final-verification.yml << 'EOF'
---
- name: Final Lab Verification
  hosts: webservers
  become: yes
  vars:
    web_service: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"

  tasks:
    - name: Verify all services are running
      systemd:
        name: "{{ item }}"
      register: service_verification
      loop:
        - "{{ web_service }}"
        - sshd

    - name: Display service verification results
      debug:
        msg: "{{ item.item }} is {{ item.status.ActiveState }} and {{ item.status.UnitFileState }}"
      loop: "{{ service_verification.results }}"

    - name: Test web service functionality
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        return_content: yes
      delegate_to: localhost
      register: web_test

    - name: Verify web content
      debug:
        msg: "Web service is responding correctly"
      when: "'Ansible Managed Server' in web_test.content"

    - name: Check if handlers were properly configured
      stat:
        path: /var/log/ansible-backups.log
      register: backup_log

    - name: Verify backup logging
      debug:
        msg: "Backup logging is {{ 'configured' if backup_log.stat.exists else 'not configured' }}"

    - name: Final lab completion status
      debug:
        msg: |
          Lab 17 Completion Status:
          ✓ Service management with systemd module
          ✓ Handler implementation for service restarts
          ✓ Service status validation
          ✓ Configuration management
          ✓ Health monitoring setup
          
          All objectives completed successfully!
EOF
Run the final verification:
ansible-playbook -i inventory.ini final-verification.yml
Troubleshooting Common Issues
Issue 1: Service Won't Start
Problem: Service fails to start after configuration changes.

Solution:

# Check service status and logs
ansible webservers -i inventory.ini -m shell -a "systemctl status httpd -l"
ansible webservers -i inventory.ini -m shell -a "journalctl -u httpd --no-pager -l"

# Test configuration syntax
ansible webservers -i inventory.ini -m shell -a "httpd -t"
Issue 2: Handlers Not Triggering
Problem: Handlers don't execute when expected.

Solution:

Ensure tasks that should trigger handlers actually make changes
Check that notify names exactly match handler names
Use --check mode to see what would change without triggering handlers
Issue 3: Port Connectivity Issues
Problem: Cannot connect to services on expected ports.

Solution:

# Check if service is listening
ansible webservers -i inventory.ini -m shell -a "netstat -tlnp | grep :80"

# Check firewall status
ansible webservers -i inventory.ini -m shell -a "firewall-cmd --list-all"
Conclusion
Congratulations! You have successfully completed Lab 17: Automating Service Management with Ansible. In this comprehensive lab, you have accomplished the following:

Key Achievements
Service Automation Mastery: You learned to automate service management using Ansible's systemd module, enabling consistent service states across multiple hosts.

Handler Implementation: You implemented handlers to restart services only when necessary, following the principle of idempotency and reducing unnecessary service disruptions.

Service Validation: You created comprehensive service status checks and configuration validation procedures to ensure services are running correctly.

Advanced Automation: You built complex playbooks that combine service management, configuration updates, and monitoring in a single automated workflow.

Why This Matters
Service management automation is crucial in modern IT operations because:

Consistency: Ensures all servers have the same service configurations and states
Efficiency: Reduces manual intervention and human error in service management
Reliability: Automated health checks and recovery procedures improve system uptime
Scalability: Manages services across hundreds or thousands of servers simultaneously
Compliance: Maintains consistent security and configuration standards
Real-World Applications
The skills you've developed in this lab directly apply to:

Web Server Management: Automating Apache/Nginx deployments and updates
Database Administration: Managing MySQL, PostgreSQL, and other database services
Application Deployment: Ensuring application services start correctly after deployments
Security Compliance: Maintaining consistent security service configurations
Disaster Recovery: Automated service recovery and health monitoring
Next Steps
To further enhance your Ansible service management skills:

Explore Ansible Tower/AWX for enterprise service management
Learn about Ansible Vault for managing sensitive service configurations
Study advanced handler patterns and error handling
Practice with containerized service management using Ansible
Integrate service management with monitoring tools like Prometheus or Nagios
You now have the foundation to implement robust, automated service management solutions in enterprise environments, making you well-prepared for the Red Hat Certified Engineer (RHCE) certification and real-world DevOps challenges.
