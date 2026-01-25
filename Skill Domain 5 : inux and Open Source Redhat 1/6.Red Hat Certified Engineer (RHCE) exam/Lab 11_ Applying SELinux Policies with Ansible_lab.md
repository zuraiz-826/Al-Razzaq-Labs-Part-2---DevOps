Lab 11: Applying SELinux Policies with Ansible
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of SELinux and its security benefits
Automate SELinux policy management using Ansible playbooks
Set SELinux to enforcing mode programmatically
Modify file contexts using the semanage module in Ansible
Implement automated SELinux policy changes for applications and services
Troubleshoot common SELinux issues in automated environments
Apply best practices for SELinux management in enterprise environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with Ansible fundamentals (playbooks, modules, tasks)
Knowledge of YAML syntax
Understanding of file permissions and ownership concepts
Basic command-line experience with Linux systems
Familiarity with text editors (vim, nano, or similar)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 systems with Ansible pre-installed
SELinux-enabled systems
All necessary tools and utilities pre-configured
Root access for administrative tasks
Task 1: Understanding SELinux Basics and Writing a Playbook to Set Enforcing Mode
Subtask 1.1: Verify Current SELinux Status
First, let's check the current SELinux status on our system.

Connect to your lab machine and check the current SELinux status:
sestatus
Also check the current mode:
getenforce
View the SELinux configuration file:
cat /etc/selinux/config
Subtask 1.2: Create Directory Structure for Ansible Playbooks
Create a working directory for our lab:
mkdir -p ~/selinux-lab
cd ~/selinux-lab
Create subdirectories for organization:
mkdir -p playbooks roles inventory
Subtask 1.3: Create Inventory File
Create an inventory file for our local system:
cat > inventory/hosts << EOF
[selinux_servers]
localhost ansible_connection=local

[selinux_servers:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
Subtask 1.4: Write Playbook to Set SELinux to Enforcing Mode
Create the main playbook for SELinux enforcement:
cat > playbooks/selinux-enforcing.yml << 'EOF'
---
- name: Configure SELinux to Enforcing Mode
  hosts: selinux_servers
  become: yes
  vars:
    selinux_policy: targeted
    selinux_state: enforcing
  
  tasks:
    - name: Check current SELinux status
      command: sestatus
      register: selinux_status
      changed_when: false
      
    - name: Display current SELinux status
      debug:
        msg: "Current SELinux status: {{ selinux_status.stdout_lines }}"
    
    - name: Install SELinux management tools
      package:
        name:
          - policycoreutils
          - policycoreutils-python-utils
          - selinux-policy
          - selinux-policy-targeted
          - setroubleshoot-server
          - setools-console
        state: present
    
    - name: Set SELinux to enforcing mode
      selinux:
        policy: "{{ selinux_policy }}"
        state: "{{ selinux_state }}"
      register: selinux_change
      
    - name: Display SELinux change status
      debug:
        msg: "SELinux state changed: {{ selinux_change.changed }}"
        
    - name: Verify SELinux is in enforcing mode
      command: getenforce
      register: enforce_check
      changed_when: false
      
    - name: Confirm enforcing mode
      debug:
        msg: "SELinux is now in: {{ enforce_check.stdout }} mode"
      
    - name: Check if reboot is required
      debug:
        msg: "Reboot required: {{ selinux_change.reboot_required | default(false) }}"
      when: selinux_change.reboot_required is defined
EOF
Run the playbook to set SELinux to enforcing mode:
ansible-playbook -i inventory/hosts playbooks/selinux-enforcing.yml
Verify the changes:
sestatus
getenforce
Task 2: Modifying File Contexts Using semanage Module
Subtask 2.1: Understanding SELinux File Contexts
First, let's examine current file contexts:
ls -Z /var/www/html/
ls -Z /home/
Check SELinux file context rules:
semanage fcontext -l | head -20
Subtask 2.2: Create Test Directory and Files
Create a test web directory:
mkdir -p /opt/webapp
echo "<h1>Test Web Application</h1>" > /opt/webapp/index.html
Check the current context:
ls -Z /opt/webapp/
Subtask 2.3: Create Playbook for File Context Management
Create a comprehensive playbook for managing file contexts:
cat > playbooks/selinux-file-contexts.yml << 'EOF'
---
- name: Manage SELinux File Contexts
  hosts: selinux_servers
  become: yes
  vars:
    webapp_directory: /opt/webapp
    custom_app_directory: /opt/myapp
    
  tasks:
    - name: Create test directories
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - "{{ webapp_directory }}"
        - "{{ custom_app_directory }}"
        - "{{ custom_app_directory }}/logs"
        - "{{ custom_app_directory }}/config"
    
    - name: Create test files
      copy:
        content: |
          <html>
          <head><title>{{ item.title }}</title></head>
          <body><h1>{{ item.content }}</h1></body>
          </html>
        dest: "{{ item.path }}"
        mode: '0644'
      loop:
        - { path: "{{ webapp_directory }}/index.html", title: "Web App", content: "Welcome to Web Application" }
        - { path: "{{ custom_app_directory }}/app.html", title: "Custom App", content: "Custom Application" }
    
    - name: Check current file contexts before changes
      command: ls -Z {{ webapp_directory }}
      register: context_before
      changed_when: false
      
    - name: Display contexts before changes
      debug:
        msg: "Contexts before: {{ context_before.stdout_lines }}"
    
    - name: Set file context for web application directory
      sefcontext:
        target: "{{ webapp_directory }}(/.*)?"
        setype: httpd_exec_t
        state: present
      register: webapp_context
      
    - name: Set file context for custom application directory
      sefcontext:
        target: "{{ custom_app_directory }}(/.*)?"
        setype: admin_home_t
        state: present
      register: custom_context
      
    - name: Set specific context for log directory
      sefcontext:
        target: "{{ custom_app_directory }}/logs(/.*)?"
        setype: var_log_t
        state: present
      register: log_context
    
    - name: Apply file contexts using restorecon
      command: restorecon -R {{ item }}
      loop:
        - "{{ webapp_directory }}"
        - "{{ custom_app_directory }}"
      when: webapp_context.changed or custom_context.changed or log_context.changed
    
    - name: Verify new file contexts
      command: ls -Z {{ item }}
      register: context_after
      changed_when: false
      loop:
        - "{{ webapp_directory }}"
        - "{{ custom_app_directory }}"
        
    - name: Display new contexts
      debug:
        msg: "New contexts for {{ item.item }}: {{ item.stdout_lines }}"
      loop: "{{ context_after.results }}"
      
    - name: List all custom file context rules
      command: semanage fcontext -l -C
      register: custom_rules
      changed_when: false
      
    - name: Display custom SELinux rules
      debug:
        msg: "Custom SELinux file context rules: {{ custom_rules.stdout_lines }}"
EOF
Run the file context management playbook:
ansible-playbook -i inventory/hosts playbooks/selinux-file-contexts.yml
Subtask 2.4: Advanced File Context Management
Create a playbook for more advanced file context scenarios:
cat > playbooks/advanced-file-contexts.yml << 'EOF'
---
- name: Advanced SELinux File Context Management
  hosts: selinux_servers
  become: yes
  
  tasks:
    - name: Create database directory structure
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
        owner: root
        group: root
      loop:
        - /opt/database
        - /opt/database/data
        - /opt/database/logs
        - /opt/database/config
    
    - name: Set database data directory context
      sefcontext:
        target: "/opt/database/data(/.*)?"
        setype: mysqld_db_t
        state: present
      notify: restore database contexts
        
    - name: Set database log directory context
      sefcontext:
        target: "/opt/database/logs(/.*)?"
        setype: mysqld_log_t
        state: present
      notify: restore database contexts
        
    - name: Set database config directory context
      sefcontext:
        target: "/opt/database/config(/.*)?"
        setype: mysqld_etc_t
        state: present
      notify: restore database contexts
    
    - name: Create sample database files
      copy:
        content: "Sample {{ item.type }} content"
        dest: "{{ item.path }}"
        mode: '0644'
      loop:
        - { path: "/opt/database/data/sample.db", type: "database" }
        - { path: "/opt/database/logs/error.log", type: "log" }
        - { path: "/opt/database/config/my.cnf", type: "config" }
    
    - name: Remove a file context rule (example)
      sefcontext:
        target: "/tmp/old-app(/.*)?"
        state: absent
      ignore_errors: yes
      
    - name: Verify all database contexts are correct
      command: ls -Z {{ item }}
      register: db_contexts
      changed_when: false
      loop:
        - /opt/database/data
        - /opt/database/logs
        - /opt/database/config
        
    - name: Display database contexts
      debug:
        msg: "{{ item.item }} contexts: {{ item.stdout_lines }}"
      loop: "{{ db_contexts.results }}"
  
  handlers:
    - name: restore database contexts
      command: restorecon -R /opt/database
EOF
Execute the advanced file context playbook:
ansible-playbook -i inventory/hosts playbooks/advanced-file-contexts.yml
Task 3: Automate SELinux Policy Changes for Applications and Services
Subtask 3.1: Managing SELinux Booleans
Create a playbook to manage SELinux booleans for common services:
cat > playbooks/selinux-booleans.yml << 'EOF'
---
- name: Manage SELinux Booleans for Applications
  hosts: selinux_servers
  become: yes
  
  tasks:
    - name: List current SELinux booleans status
      command: getsebool -a
      register: current_booleans
      changed_when: false
      
    - name: Show some current boolean values
      debug:
        msg: "{{ current_booleans.stdout_lines[:10] }}"
    
    - name: Enable httpd to connect to network
      seboolean:
        name: httpd_can_network_connect
        state: yes
        persistent: yes
      register: httpd_network
      
    - name: Enable httpd to connect to database
      seboolean:
        name: httpd_can_network_connect_db
        state: yes
        persistent: yes
      register: httpd_db
      
    - name: Enable Samba to export all read/write
      seboolean:
        name: samba_export_all_rw
        state: yes
        persistent: yes
      register: samba_rw
      ignore_errors: yes
      
    - name: Enable FTP home directories
      seboolean:
        name: ftp_home_dir
        state: yes
        persistent: yes
      register: ftp_home
      ignore_errors: yes
      
    - name: Disable SELinux protection for NFS
      seboolean:
        name: nfs_export_all_rw
        state: no
        persistent: yes
      register: nfs_protection
      ignore_errors: yes
    
    - name: Display boolean change results
      debug:
        msg: "Boolean {{ item.name }} changed: {{ item.result.changed }}"
      loop:
        - { name: "httpd_can_network_connect", result: "{{ httpd_network }}" }
        - { name: "httpd_can_network_connect_db", result: "{{ httpd_db }}" }
      when: item.result is defined
      
    - name: Verify boolean changes
      command: getsebool {{ item }}
      register: verify_booleans
      changed_when: false
      loop:
        - httpd_can_network_connect
        - httpd_can_network_connect_db
        
    - name: Show verified boolean values
      debug:
        msg: "{{ item.stdout }}"
      loop: "{{ verify_booleans.results }}"
EOF
Run the SELinux booleans playbook:
ansible-playbook -i inventory/hosts playbooks/selinux-booleans.yml
Subtask 3.2: Managing SELinux Ports
Create a playbook for managing SELinux port policies:
cat > playbooks/selinux-ports.yml << 'EOF'
---
- name: Manage SELinux Port Policies
  hosts: selinux_servers
  become: yes
  
  tasks:
    - name: Check current SELinux port assignments
      command: semanage port -l
      register: current_ports
      changed_when: false
      
    - name: Show HTTP-related port assignments
      debug:
        msg: "{{ current_ports.stdout_lines | select('match', '.*http.*') | list }}"
    
    - name: Add custom port for HTTP service
      seport:
        ports: 8080
        proto: tcp
        setype: http_port_t
        state: present
      register: http_custom_port
      
    - name: Add custom port for SSH service
      seport:
        ports: 2222
        proto: tcp
        setype: ssh_port_t
        state: present
      register: ssh_custom_port
      
    - name: Add range of ports for custom application
      seport:
        ports: 9000-9010
        proto: tcp
        setype: http_port_t
        state: present
      register: custom_app_ports
      
    - name: Display port assignment results
      debug:
        msg: "Port assignment for {{ item.name }}: {{ item.result.changed }}"
      loop:
        - { name: "HTTP 8080", result: "{{ http_custom_port }}" }
        - { name: "SSH 2222", result: "{{ ssh_custom_port }}" }
        - { name: "Custom App 9000-9010", result: "{{ custom_app_ports }}" }
    
    - name: Verify new port assignments
      command: semanage port -l | grep -E "(8080|2222|900[0-9])"
      register: verify_ports
      changed_when: false
      ignore_errors: yes
      
    - name: Show verified port assignments
      debug:
        msg: "New port assignments: {{ verify_ports.stdout_lines }}"
      when: verify_ports.stdout_lines is defined
      
    - name: Remove a port assignment (example)
      seport:
        ports: 9010
        proto: tcp
        setype: http_port_t
        state: absent
      register: remove_port
      ignore_errors: yes
      
    - name: Show removal result
      debug:
        msg: "Port 9010 removal: {{ remove_port.changed }}"
      when: remove_port is defined
EOF
Execute the SELinux ports playbook:
ansible-playbook -i inventory/hosts playbooks/selinux-ports.yml
Subtask 3.3: Comprehensive Application SELinux Configuration
Create a comprehensive playbook that configures SELinux for a complete application stack:
cat > playbooks/application-selinux-config.yml << 'EOF'
---
- name: Complete Application SELinux Configuration
  hosts: selinux_servers
  become: yes
  vars:
    app_name: mywebapp
    app_directory: /opt/mywebapp
    app_port: 8081
    
  tasks:
    - name: Create application directory structure
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
        owner: apache
        group: apache
      loop:
        - "{{ app_directory }}"
        - "{{ app_directory }}/htdocs"
        - "{{ app_directory }}/logs"
        - "{{ app_directory }}/tmp"
        - "{{ app_directory }}/config"
      ignore_errors: yes
    
    - name: Install required packages
      package:
        name:
          - httpd
          - mod_ssl
        state: present
    
    - name: Create application files
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head><title>{{ app_name }}</title></head>
          <body>
            <h1>Welcome to {{ app_name }}</h1>
            <p>This application is secured with SELinux</p>
          </body>
          </html>
        dest: "{{ app_directory }}/htdocs/index.html"
        owner: apache
        group: apache
        mode: '0644'
    
    - name: Set file contexts for application
      sefcontext:
        target: "{{ item.path }}"
        setype: "{{ item.context }}"
        state: present
      loop:
        - { path: "{{ app_directory }}/htdocs(/.*)?", context: "httpd_exec_t" }
        - { path: "{{ app_directory }}/logs(/.*)?", context: "httpd_log_t" }
        - { path: "{{ app_directory }}/tmp(/.*)?", context: "httpd_tmp_t" }
        - { path: "{{ app_directory }}/config(/.*)?", context: "httpd_config_t" }
      register: app_contexts
    
    - name: Apply file contexts
      command: restorecon -R {{ app_directory }}
      when: app_contexts.changed
    
    - name: Configure custom port for application
      seport:
        ports: "{{ app_port }}"
        proto: tcp
        setype: http_port_t
        state: present
      register: app_port_config
    
    - name: Enable required SELinux booleans for application
      seboolean:
        name: "{{ item }}"
        state: yes
        persistent: yes
      loop:
        - httpd_can_network_connect
        - httpd_can_network_connect_db
        - httpd_execmem
      register: app_booleans
      ignore_errors: yes
    
    - name: Create Apache virtual host configuration
      copy:
        content: |
          <VirtualHost *:{{ app_port }}>
              ServerName {{ app_name }}.local
              DocumentRoot {{ app_directory }}/htdocs
              ErrorLog {{ app_directory }}/logs/error.log
              CustomLog {{ app_directory }}/logs/access.log combined
              
              <Directory "{{ app_directory }}/htdocs">
                  AllowOverride All
                  Require all granted
              </Directory>
          </VirtualHost>
          
          Listen {{ app_port }}
        dest: /etc/httpd/conf.d/{{ app_name }}.conf
        mode: '0644'
      notify: restart httpd
    
    - name: Start and enable Apache
      systemd:
        name: httpd
        state: started
        enabled: yes
    
    - name: Verify SELinux contexts are correct
      command: ls -Z {{ item }}
      register: verify_contexts
      changed_when: false
      loop:
        - "{{ app_directory }}/htdocs"
        - "{{ app_directory }}/logs"
        - "{{ app_directory }}/config"
    
    - name: Display verification results
      debug:
        msg: "{{ item.item }} contexts: {{ item.stdout_lines }}"
      loop: "{{ verify_contexts.results }}"
    
    - name: Check if application is accessible
      uri:
        url: "http://localhost:{{ app_port }}"
        method: GET
        status_code: 200
      register: app_check
      ignore_errors: yes
      
    - name: Display application status
      debug:
        msg: "Application accessibility: {{ 'SUCCESS' if app_check.status == 200 else 'FAILED' }}"
      
    - name: Generate SELinux audit report
      command: ausearch -m avc -ts recent
      register: selinux_audit
      changed_when: false
      ignore_errors: yes
      
    - name: Display recent SELinux denials (if any)
      debug:
        msg: "Recent SELinux denials: {{ selinux_audit.stdout_lines }}"
      when: selinux_audit.stdout_lines is defined and selinux_audit.stdout_lines | length > 0
  
  handlers:
    - name: restart httpd
      systemd:
        name: httpd
        state: restarted
EOF
Run the comprehensive application configuration:
ansible-playbook -i inventory/hosts playbooks/application-selinux-config.yml
Subtask 3.4: SELinux Troubleshooting and Monitoring
Create a playbook for SELinux troubleshooting and monitoring:
cat > playbooks/selinux-troubleshooting.yml << 'EOF'
---
- name: SELinux Troubleshooting and Monitoring
  hosts: selinux_servers
  become: yes
  
  tasks:
    - name: Install SELinux troubleshooting tools
      package:
        name:
          - setroubleshoot-server
          - policycoreutils-python-utils
          - setools-console
        state: present
    
    - name: Check SELinux status and mode
      command: sestatus
      register: selinux_status
      changed_when: false
      
    - name: Display SELinux status
      debug:
        msg: "{{ selinux_status.stdout_lines }}"
    
    - name: Check for recent SELinux denials
      command: ausearch -m avc -ts today
      register: recent_denials
      changed_when: false
      ignore_errors: yes
      
    - name: Display recent denials summary
      debug:
        msg: "Found {{ recent_denials.stdout_lines | length }} recent SELinux denial entries"
      when: recent_denials.stdout_lines is defined
    
    - name: Generate SELinux policy module for common issues
      shell: |
        ausearch -m avc -ts recent | audit2allow -M local_policy
      register: policy_generation
      changed_when: false
      ignore_errors: yes
      
    - name: Show generated policy (if any)
      debug:
        msg: "Policy generation output: {{ policy_generation.stdout_lines }}"
      when: policy_generation.stdout_lines is defined and policy_generation.stdout_lines | length > 0
    
    - name: Check SELinux boolean status
      command: getsebool -a | grep -E "(httpd|samba|ftp|nfs)"
      register: service_booleans
      changed_when: false
      ignore_errors: yes
      
    - name: Display service-related booleans
      debug:
        msg: "Service booleans: {{ service_booleans.stdout_lines }}"
      when: service_booleans.stdout_lines is defined
    
    - name: List custom SELinux modules
      command: semodule -l | grep -v "^[a-z]*\s*pp"
      register: custom_modules
      changed_when: false
      ignore_errors: yes
      
    - name: Display custom modules
      debug:
        msg: "Custom SELinux modules: {{ custom_modules.stdout_lines }}"
      when: custom_modules.stdout_lines is defined and custom_modules.stdout_lines | length > 0
    
    - name: Create SELinux monitoring script
      copy:
        content: |
          #!/bin/bash
          echo "=== SELinux Status Report ==="
          echo "Date: $(date)"
          echo "SELinux Status: $(sestatus | grep 'SELinux status')"
          echo "Current Mode: $(getenforce)"
          echo ""
          echo "=== Recent Denials ==="
          ausearch -m avc -ts today 2>/dev/null | tail -10 || echo "No recent denials found"
          echo ""
          echo "=== Custom File Contexts ==="
          semanage fcontext -l -C
          echo ""
          echo "=== Custom Ports ==="
          semanage port -l -C
          echo ""
          echo "=== Modified Booleans ==="
          semanage boolean -l -C
        dest: /usr/local/bin/selinux-report.sh
        mode: '0755'
    
    - name: Run SELinux monitoring script
      command: /usr/local/bin/selinux-report.sh
      register: selinux_report
      changed_when: false
      
    - name: Display SELinux report
      debug:
        msg: "{{ selinux_report.stdout_lines }}"
EOF
Execute the troubleshooting playbook:
ansible-playbook -i inventory/hosts playbooks/selinux-troubleshooting.yml
Troubleshooting Common Issues
Issue 1: SELinux Denials
If you encounter SELinux denials:

Check the audit log:
ausearch -m avc -ts recent
Use audit2allow to generate policy:
ausearch -m avc -ts recent | audit2allow -M mypolicy
Install the policy if appropriate:
semodule -i mypolicy.pp
Issue 2: File Context Issues
If file contexts are not applying:

Check if the context rule exists:
semanage fcontext -l | grep /your/path
Apply contexts manually:
restorecon -R /your/path
Issue 3: Service Not Starting
If services fail to start due to SELinux:

Check relevant booleans:
getsebool -a | grep servicename
Enable required booleans:
setsebool -P boolean_name on
Best Practices
Always use persistent settings for booleans in production
Test changes in permissive mode before enforcing
Document custom policies and file contexts
Monitor SELinux logs regularly
Use specific contexts rather than generic ones when possible
Backup SELinux configuration before major changes
Verification Commands
Use these commands to verify your lab work:

# Check SELinux status
sestatus
getenforce

# List custom file contexts
semanage fcontext -l -C

# List custom ports
semanage port -l -C

# List modified booleans
semanage boolean -l -C

# Check for recent denials
ausearch -m avc -ts today
Conclusion
In this comprehensive lab, you have successfully:

Automated SELinux policy management using Ansible playbooks, eliminating manual configuration errors and ensuring consistency across systems
Implemented enforcing mode programmatically, enhancing system security by ensuring SELinux policies are actively enforced
Managed file contexts using the semanage module, properly securing application files and directories with appropriate SELinux labels
Configured application-specific SELinux policies, including port assignments, boolean settings, and custom contexts for web applications and services
Developed troubleshooting skills for SELinux issues, including audit log analysis and policy generation
Applied enterprise best practices for SELinux management in automated environments
This lab demonstrates the power of combining Ansible automation with SELinux security policies. In enterprise environments, this approach ensures consistent security configurations across multiple systems while reducing the complexity of SELinux management. The skills learned here are directly applicable to the Red Hat Certified Engineer (RHCE) exam and real-world system administration scenarios.

The automated approach to SELinux management you've learned provides significant benefits including reduced human error, consistent policy application, and the ability to quickly deploy security configurations across large infrastructures. These capabilities are essential for maintaining secure, compliant systems in modern IT environments.
