Lab 18: Managing and Troubleshooting Ansible Runs
Objectives
By the end of this lab, you will be able to:

Use ansible-console to interact with the Ansible environment interactively
Diagnose and troubleshoot failed Ansible playbook runs
Analyze error messages and logs to identify root causes of failures
Use ansible-playbook --check to run playbooks in check mode for validation
Apply systematic troubleshooting methodologies for Ansible automation
Implement best practices for debugging Ansible configurations
Prerequisites
Before starting this lab, you should have:

Basic understanding of Ansible concepts (playbooks, inventory, modules)
Familiarity with Linux command line operations
Knowledge of YAML syntax and structure
Experience running basic Ansible playbooks
Understanding of SSH connectivity and key-based authentication
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible installed
Managed Nodes: Two target systems (node1 and node2)
Pre-configured SSH keys and basic inventory file
Task 1: Using ansible-console for Interactive Management
Subtask 1.1: Launch and Explore ansible-console
ansible-console is an interactive REPL (Read-Eval-Print Loop) tool that allows you to run Ansible modules against your inventory interactively.

Connect to your control node and verify Ansible installation:
ansible --version
Check your inventory file:
cat /etc/ansible/hosts
Expected output should show your managed nodes:

[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=/home/ansible/.ssh/id_rsa
Launch ansible-console targeting all hosts:
ansible-console all
You should see a prompt like:

Welcome to the ansible console.
Type help or ? to list commands.

ansible@all (2)[f:5]$
The prompt shows:

ansible@all: Current user and host pattern
(2): Number of hosts matched
[f:5]: Fork count
Subtask 1.2: Execute Basic Commands in ansible-console
Test connectivity to all managed nodes:
ping
Gather system facts:
setup
Check disk usage:
shell df -h
List running processes:
shell ps aux | head -10
Change the host pattern to target specific hosts:
cd webservers
Install a package using the yum module:
yum name=htop state=present
Exit ansible-console:
exit
Subtask 1.3: Advanced ansible-console Operations
Launch ansible-console with specific options:
ansible-console -i /etc/ansible/hosts --become all
Use variables in commands:
shell echo "Current user: {{ ansible_user }}"
Run commands with different privilege escalation:
become_user=root shell whoami
Check service status:
systemd name=sshd state=started
Task 2: Troubleshooting Failed Playbook Runs
Subtask 2.1: Create a Problematic Playbook
First, let's create a playbook with intentional issues to practice troubleshooting.

Create a directory for troubleshooting exercises:
mkdir -p ~/ansible-troubleshooting
cd ~/ansible-troubleshooting
Create a problematic playbook:
cat > broken-playbook.yml << 'EOF'
---
- name: Problematic Web Server Setup
  hosts: webservers
  become: yes
  vars:
    web_package: httpd
    web_service: httpd
    document_root: /var/www/html
    
  tasks:
    - name: Install web server
      yum:
        name: "{{ web_package }}"
        state: present
        
    - name: Start and enable web service
      systemd:
        name: "{{ wrong_service_name }}"
        state: started
        enabled: yes
        
    - name: Create index.html
      copy:
        content: "<h1>Welcome to {{ ansible_hostname }}</h1>"
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
        
    - name: Configure firewall
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
        
    - name: Copy configuration file
      copy:
        src: /nonexistent/httpd.conf
        dest: /etc/httpd/conf/httpd.conf
        backup: yes
      notify: restart web service
      
  handlers:
    - name: restart web service
      systemd:
        name: "{{ web_service }}"
        state: restarted
EOF
Subtask 2.2: Run and Analyze the Failed Playbook
Run the problematic playbook with verbose output:
ansible-playbook -i /etc/ansible/hosts broken-playbook.yml -v
Analyze the first error. You should see an error about undefined variable wrong_service_name.

Run with increased verbosity to get more details:

ansible-playbook -i /etc/ansible/hosts broken-playbook.yml -vvv
Subtask 2.3: Systematic Error Resolution
Fix the undefined variable error:
sed -i 's/wrong_service_name/web_service/g' broken-playbook.yml
Run the playbook again:
ansible-playbook -i /etc/ansible/hosts broken-playbook.yml -v
Identify the next error (missing source file). Create a temporary fix:
# Comment out the problematic task
sed -i '/Copy configuration file/,/notify: restart web service/s/^/# /' broken-playbook.yml
Run the playbook again to identify remaining issues:
ansible-playbook -i /etc/ansible/hosts broken-playbook.yml -v
Subtask 2.4: Advanced Troubleshooting Techniques
Use step-by-step execution:
ansible-playbook -i /etc/ansible/hosts broken-playbook.yml --step
Start from a specific task:
ansible-playbook -i /etc/ansible/hosts broken-playbook.yml --start-at-task="Configure firewall"
Use tags for selective execution (first add tags to the playbook):
# Add tags to tasks
cat > tagged-playbook.yml << 'EOF'
---
- name: Web Server Setup with Tags
  hosts: webservers
  become: yes
  vars:
    web_package: httpd
    web_service: httpd
    document_root: /var/www/html
    
  tasks:
    - name: Install web server
      yum:
        name: "{{ web_package }}"
        state: present
      tags: install
        
    - name: Start and enable web service
      systemd:
        name: "{{ web_service }}"
        state: started
        enabled: yes
      tags: service
        
    - name: Create index.html
      copy:
        content: "<h1>Welcome to {{ ansible_hostname }}</h1>"
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      tags: content
        
    - name: Configure firewall
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      tags: firewall
EOF
Run specific tags:
ansible-playbook -i /etc/ansible/hosts tagged-playbook.yml --tags="install,service"
Task 3: Using Check Mode and Validation
Subtask 3.1: Understanding Check Mode
Check mode (also known as "dry run") allows you to see what changes Ansible would make without actually executing them.

Create a comprehensive playbook for check mode testing:
cat > check-mode-demo.yml << 'EOF'
---
- name: System Configuration Demo
  hosts: all
  become: yes
  vars:
    packages_to_install:
      - vim
      - git
      - curl
      - wget
    users_to_create:
      - testuser1
      - testuser2
    
  tasks:
    - name: Update package cache
      yum:
        update_cache: yes
      tags: packages
        
    - name: Install required packages
      yum:
        name: "{{ packages_to_install }}"
        state: present
      tags: packages
        
    - name: Create user accounts
      user:
        name: "{{ item }}"
        state: present
        shell: /bin/bash
        create_home: yes
      loop: "{{ users_to_create }}"
      tags: users
        
    - name: Create application directory
      file:
        path: /opt/myapp
        state: directory
        owner: root
        group: root
        mode: '0755'
      tags: directories
        
    - name: Configure SSH settings
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?PermitRootLogin'
        line: 'PermitRootLogin no'
        backup: yes
      notify: restart sshd
      tags: security
      
  handlers:
    - name: restart sshd
      systemd:
        name: sshd
        state: restarted
EOF
Subtask 3.2: Running Playbooks in Check Mode
Run the playbook in check mode:
ansible-playbook -i /etc/ansible/hosts check-mode-demo.yml --check
Run check mode with diff output to see what would change:
ansible-playbook -i /etc/ansible/hosts check-mode-demo.yml --check --diff
Run check mode for specific tags:
ansible-playbook -i /etc/ansible/hosts check-mode-demo.yml --check --tags="packages"
Compare check mode vs actual execution:
# First, run in check mode and save output
ansible-playbook -i /etc/ansible/hosts check-mode-demo.yml --check > check-output.txt

# Then run normally and save output
ansible-playbook -i /etc/ansible/hosts check-mode-demo.yml > normal-output.txt

# Compare the outputs
diff check-output.txt normal-output.txt
Subtask 3.3: Advanced Check Mode Scenarios
Create a playbook with check mode considerations:
cat > check-mode-advanced.yml << 'EOF'
---
- name: Advanced Check Mode Demo
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install Apache (always runs in check mode)
      yum:
        name: httpd
        state: present
      check_mode: no
      tags: install
        
    - name: Check if Apache is installed
      command: rpm -q httpd
      register: apache_check
      failed_when: false
      changed_when: false
      check_mode: no
      
    - name: Display Apache installation status
      debug:
        msg: "Apache installation status: {{ apache_check.rc }}"
        
    - name: Start Apache (skip in check mode)
      systemd:
        name: httpd
        state: started
        enabled: yes
      when: apache_check.rc == 0
      tags: service
      
    - name: Create web content
      copy:
        content: |
          <html>
          <head><title>Check Mode Demo</title></head>
          <body>
          <h1>Server: {{ ansible_hostname }}</h1>
          <p>Generated on: {{ ansible_date_time.iso8601 }}</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: apache
        group: apache
        mode: '0644'
      tags: content
EOF
Run the advanced check mode playbook:
ansible-playbook -i /etc/ansible/hosts check-mode-advanced.yml --check --diff
Run normally to see the difference:
ansible-playbook -i /etc/ansible/hosts check-mode-advanced.yml
Subtask 3.4: Validation and Syntax Checking
Check playbook syntax:
ansible-playbook --syntax-check check-mode-advanced.yml
List all tasks without execution:
ansible-playbook -i /etc/ansible/hosts check-mode-advanced.yml --list-tasks
List all hosts that would be affected:
ansible-playbook -i /etc/ansible/hosts check-mode-advanced.yml --list-hosts
List all tags available:
ansible-playbook -i /etc/ansible/hosts check-mode-advanced.yml --list-tags
Advanced Troubleshooting Scenarios
Scenario 1: Connection Issues
Create a playbook to test connectivity issues:
cat > connection-test.yml << 'EOF'
---
- name: Connection Troubleshooting
  hosts: all
  gather_facts: no
  
  tasks:
    - name: Test basic connectivity
      ping:
      
    - name: Gather minimal facts
      setup:
        gather_subset: min
        
    - name: Test privilege escalation
      command: whoami
      become: yes
EOF
Run with connection debugging:
ansible-playbook -i /etc/ansible/hosts connection-test.yml -vvvv
Scenario 2: Variable and Template Issues
Create a playbook with variable problems:
cat > variable-issues.yml << 'EOF'
---
- name: Variable Troubleshooting Demo
  hosts: webservers
  vars:
    app_name: myapp
    app_version: "1.0"
    
  tasks:
    - name: Debug variables
      debug:
        msg: |
          App: {{ app_name }}
          Version: {{ app_version }}
          Undefined: {{ undefined_var | default('Not defined') }}
          
    - name: Create config with template
      copy:
        content: |
          # Configuration for {{ app_name }}
          version={{ app_version }}
          hostname={{ ansible_hostname }}
          ip_address={{ ansible_default_ipv4.address }}
        dest: /tmp/app.conf
        
    - name: Show configuration
      command: cat /tmp/app.conf
      register: config_content
      
    - name: Display config content
      debug:
        var: config_content.stdout_lines
EOF
Run the variable troubleshooting playbook:
ansible-playbook -i /etc/ansible/hosts variable-issues.yml -v
Best Practices for Troubleshooting
Creating a Troubleshooting Checklist
Create a troubleshooting script:
cat > troubleshoot-ansible.sh << 'EOF'
#!/bin/bash

echo "=== Ansible Troubleshooting Checklist ==="
echo

echo "1. Checking Ansible version:"
ansible --version
echo

echo "2. Checking inventory:"
ansible-inventory --list -i /etc/ansible/hosts
echo

echo "3. Testing connectivity:"
ansible all -i /etc/ansible/hosts -m ping
echo

echo "4. Checking SSH connectivity:"
ansible all -i /etc/ansible/hosts -m command -a "whoami"
echo

echo "5. Testing privilege escalation:"
ansible all -i /etc/ansible/hosts -m command -a "whoami" --become
echo

echo "6. Checking disk space on control node:"
df -h
echo

echo "7. Checking memory usage:"
free -h
echo

echo "=== Troubleshooting complete ==="
EOF

chmod +x troubleshoot-ansible.sh
Run the troubleshooting script:
./troubleshoot-ansible.sh
Log Analysis
Enable detailed logging by creating an ansible.cfg file:
cat > ansible.cfg << 'EOF'
[defaults]
log_path = /tmp/ansible.log
host_key_checking = False
retry_files_enabled = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF
Run a playbook and analyze logs:
ansible-playbook -i /etc/ansible/hosts check-mode-demo.yml
tail -f /tmp/ansible.log
Conclusion
In this lab, you have successfully learned how to manage and troubleshoot Ansible runs using various tools and techniques. Here's what you accomplished:

Key Skills Developed:

Interactive Management: You learned to use ansible-console for real-time interaction with your Ansible environment, allowing for quick testing and exploration of your infrastructure.

Systematic Troubleshooting: You developed skills to diagnose and resolve common Ansible issues, including undefined variables, missing files, and configuration errors.

Check Mode Mastery: You mastered the use of ansible-playbook --check to validate playbooks before execution, preventing potential issues in production environments.

Advanced Debugging: You learned to use verbose output, step-by-step execution, and selective task running to isolate and resolve complex problems.

Why This Matters:

Production Safety: Check mode allows you to validate changes before applying them to critical systems
Faster Problem Resolution: Systematic troubleshooting reduces downtime and improves reliability
Better Automation: Understanding how to debug Ansible helps you write more robust and maintainable playbooks
Career Advancement: These skills are essential for the Red Hat Certified Engineer (RHCE) certification and real-world DevOps roles
Next Steps:

Practice these troubleshooting techniques with your own playbooks
Explore Ansible's built-in debugging modules like debug and assert
Learn about Ansible Vault for secure variable management
Study advanced Ansible features like custom modules and plugins
The troubleshooting skills you've developed in this lab will serve as a foundation for managing complex Ansible automation in enterprise environments, making you a more effective and confident automation engineer.
