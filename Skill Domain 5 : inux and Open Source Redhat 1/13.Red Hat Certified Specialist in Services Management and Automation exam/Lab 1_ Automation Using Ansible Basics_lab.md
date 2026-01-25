Lab 1: Automation Using Ansible Basics
Objectives
By the end of this lab, students will be able to:

Execute Ansible ad hoc commands to verify host connectivity and gather system information
Create and run simple Ansible playbooks to automate service configuration
Implement user account management across multiple systems using Ansible
Understand the fundamental concepts of Infrastructure as Code (IaC)
Apply Ansible best practices for configuration management
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with SSH concepts and key-based authentication
Knowledge of YAML syntax fundamentals
Understanding of basic system administration tasks (user management, service control)
Experience with text editors like vim or nano
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or install software.

Your lab environment includes:

Control Node: CentOS/RHEL 8 system with Ansible pre-installed
Managed Nodes: Two target systems (node1 and node2) for automation tasks
Pre-configured SSH key authentication between all systems
All necessary packages and dependencies installed
Task 1: Run Ad Hoc Commands to Check Host Availability
Subtask 1.1: Verify Ansible Installation and Configuration
First, let's confirm that Ansible is properly installed and configured on your control node.

Connect to your control node and verify Ansible installation:
ansible --version
Expected output should show Ansible version 2.9 or higher.

Check the inventory file to see your managed hosts:
cat /etc/ansible/hosts
You should see entries similar to:

[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=/home/ansible/.ssh/id_rsa
Verify SSH connectivity to managed nodes:
ssh node1 "hostname"
ssh node2 "hostname"
Subtask 1.2: Execute Basic Ad Hoc Commands
Ad hoc commands allow you to run single tasks across multiple systems without writing playbooks.

Test connectivity to all managed hosts using the ping module:
ansible all -m ping
Expected output:

node1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
node2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
Gather system information from all hosts:
ansible all -m setup -a "filter=ansible_distribution*"
Check disk space on all managed nodes:
ansible all -m shell -a "df -h"
Verify system uptime across all hosts:
ansible all -m command -a "uptime"
Subtask 1.3: Target Specific Host Groups
Run commands on specific groups defined in your inventory:
ansible webservers -m command -a "whoami"
Check memory usage on webserver group:
ansible webservers -m shell -a "free -m"
List running processes on a specific host:
ansible node1 -m shell -a "ps aux | head -10"
Task 2: Write Simple Ansible Playbooks to Configure Services
Subtask 2.1: Create Your First Playbook
Playbooks are YAML files that define a series of tasks to be executed on managed hosts.

Create a directory for your playbooks:
mkdir ~/ansible-lab
cd ~/ansible-lab
Create a simple playbook to install and configure Apache web server:
nano webserver-setup.yml
Add the following content:

---
- name: Configure Web Servers
  hosts: webservers
  become: yes
  tasks:
    - name: Install Apache HTTP Server
      yum:
        name: httpd
        state: present

    - name: Start and enable Apache service
      systemd:
        name: httpd
        state: started
        enabled: yes

    - name: Create a simple index page
      copy:
        content: |
          <html>
          <head><title>Ansible Lab Server</title></head>
          <body>
          <h1>Welcome to {{ ansible_hostname }}</h1>
          <p>This server was configured by Ansible!</p>
          <p>Server IP: {{ ansible_default_ipv4.address }}</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: apache
        group: apache
        mode: '0644'

    - name: Open firewall for HTTP
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
Run the playbook to configure your web servers:
ansible-playbook webserver-setup.yml
Verify the web service is running:
ansible webservers -m uri -a "url=http://{{ ansible_default_ipv4.address }} method=GET"
Subtask 2.2: Create a Database Server Playbook
Create a playbook for database server configuration:
nano database-setup.yml
Add the following content:

---
- name: Configure Database Server
  hosts: node2
  become: yes
  vars:
    mysql_root_password: "SecurePass123!"
  tasks:
    - name: Install MariaDB server
      yum:
        name:
          - mariadb-server
          - mariadb
          - python3-PyMySQL
        state: present

    - name: Start and enable MariaDB service
      systemd:
        name: mariadb
        state: started
        enabled: yes

    - name: Set MariaDB root password
      mysql_user:
        name: root
        password: "{{ mysql_root_password }}"
        login_unix_socket: /var/lib/mysql/mysql.sock
        state: present

    - name: Create application database
      mysql_db:
        name: webapp_db
        login_user: root
        login_password: "{{ mysql_root_password }}"
        state: present

    - name: Create database user
      mysql_user:
        name: webapp_user
        password: "WebApp123!"
        priv: "webapp_db.*:ALL"
        login_user: root
        login_password: "{{ mysql_root_password }}"
        state: present
Execute the database playbook:
ansible-playbook database-setup.yml
Verify database installation:
ansible node2 -m shell -a "systemctl status mariadb"
Subtask 2.3: Create a Multi-Service Playbook
Create a comprehensive playbook that configures multiple services:
nano complete-setup.yml
Add the following content:

---
- name: Complete System Configuration
  hosts: all
  become: yes
  tasks:
    - name: Update system packages
      yum:
        name: "*"
        state: latest
        update_cache: yes

    - name: Install essential packages
      yum:
        name:
          - vim
          - wget
          - curl
          - htop
          - git
        state: present

    - name: Configure timezone
      timezone:
        name: America/New_York

    - name: Create log directory
      file:
        path: /var/log/ansible-managed
        state: directory
        owner: root
        group: root
        mode: '0755'

    - name: Generate system information file
      template:
        src: system-info.j2
        dest: /var/log/ansible-managed/system-info.txt
        owner: root
        group: root
        mode: '0644'
Create the template file:
mkdir templates
nano templates/system-info.j2
Add the following content:

System Information for {{ ansible_hostname }}
==========================================
Operating System: {{ ansible_distribution }} {{ ansible_distribution_version }}
Kernel Version: {{ ansible_kernel }}
Architecture: {{ ansible_architecture }}
Total Memory: {{ ansible_memtotal_mb }} MB
CPU Cores: {{ ansible_processor_vcpus }}
IP Address: {{ ansible_default_ipv4.address }}
Last Updated: {{ ansible_date_time.iso8601 }}

Managed by Ansible
Configuration Date: {{ ansible_date_time.date }}
Run the complete setup playbook:
ansible-playbook complete-setup.yml
Task 3: Use Ansible to Manage User Accounts Across Systems
Subtask 3.1: Create User Management Playbook
User management is a critical aspect of system administration that Ansible can automate effectively.

Create a user management playbook:
nano user-management.yml
Add the following content:

---
- name: Manage User Accounts
  hosts: all
  become: yes
  vars:
    users_to_create:
      - username: developer1
        full_name: "John Developer"
        groups: ["wheel", "developers"]
        shell: /bin/bash
      - username: developer2
        full_name: "Jane Developer"
        groups: ["developers"]
        shell: /bin/bash
      - username: operator1
        full_name: "System Operator"
        groups: ["wheel", "operators"]
        shell: /bin/bash

  tasks:
    - name: Create user groups
      group:
        name: "{{ item }}"
        state: present
      loop:
        - developers
        - operators

    - name: Create user accounts
      user:
        name: "{{ item.username }}"
        comment: "{{ item.full_name }}"
        groups: "{{ item.groups }}"
        shell: "{{ item.shell }}"
        create_home: yes
        state: present
      loop: "{{ users_to_create }}"

    - name: Set up SSH directory for users
      file:
        path: "/home/{{ item.username }}/.ssh"
        state: directory
        owner: "{{ item.username }}"
        group: "{{ item.username }}"
        mode: '0700'
      loop: "{{ users_to_create }}"

    - name: Generate SSH key pairs for users
      openssh_keypair:
        path: "/home/{{ item.username }}/.ssh/id_rsa"
        owner: "{{ item.username }}"
        group: "{{ item.username }}"
        mode: '0600'
      loop: "{{ users_to_create }}"

    - name: Create user-specific directories
      file:
        path: "/home/{{ item.username }}/{{ dir }}"
        state: directory
        owner: "{{ item.username }}"
        group: "{{ item.username }}"
        mode: '0755'
      loop: "{{ users_to_create }}"
      vars:
        dir: "{{ item_dir }}"
      with_nested:
        - "{{ users_to_create }}"
        - ["projects", "scripts", "logs"]
      loop_control:
        loop_var: item_dir
Execute the user management playbook:
ansible-playbook user-management.yml
Subtask 3.2: Configure User Permissions and Sudo Access
Create a playbook for sudo configuration:
nano sudo-config.yml
Add the following content:

---
- name: Configure Sudo Access
  hosts: all
  become: yes
  tasks:
    - name: Create sudoers file for developers group
      copy:
        content: |
          # Allow developers group to run specific commands
          %developers ALL=(ALL) /bin/systemctl status *, /bin/systemctl restart httpd, /usr/bin/tail /var/log/*
        dest: /etc/sudoers.d/developers
        owner: root
        group: root
        mode: '0440'
        validate: 'visudo -cf %s'

    - name: Create sudoers file for operators group
      copy:
        content: |
          # Allow operators group full sudo access
          %operators ALL=(ALL) NOPASSWD: ALL
        dest: /etc/sudoers.d/operators
        owner: root
        group: root
        mode: '0440'
        validate: 'visudo -cf %s'

    - name: Set password for developer users
      user:
        name: "{{ item }}"
        password: "{{ 'DevPass123!' | password_hash('sha512') }}"
        update_password: on_create
      loop:
        - developer1
        - developer2

    - name: Set password for operator users
      user:
        name: operator1
        password: "{{ 'OpPass123!' | password_hash('sha512') }}"
        update_password: on_create
Run the sudo configuration playbook:
ansible-playbook sudo-config.yml
Subtask 3.3: Implement User Account Auditing
Create an auditing playbook:
nano user-audit.yml
Add the following content:

---
- name: User Account Audit
  hosts: all
  become: yes
  tasks:
    - name: Gather user account information
      getent:
        database: passwd
      register: user_accounts

    - name: Create audit report directory
      file:
        path: /var/log/ansible-audit
        state: directory
        owner: root
        group: root
        mode: '0755'

    - name: Generate user audit report
      template:
        src: user-audit.j2
        dest: "/var/log/ansible-audit/user-audit-{{ ansible_date_time.date }}.txt"
        owner: root
        group: root
        mode: '0644'

    - name: Check for users with sudo access
      shell: "getent group wheel sudo | cut -d: -f4"
      register: sudo_users
      ignore_errors: yes

    - name: Display sudo users
      debug:
        msg: "Users with sudo access: {{ sudo_users.stdout }}"

    - name: Check last login information
      shell: "lastlog | grep -v 'Never logged in' | tail -10"
      register: recent_logins

    - name: Display recent logins
      debug:
        msg: "{{ recent_logins.stdout_lines }}"
Create the audit template:
nano templates/user-audit.j2
Add the following content:

User Account Audit Report
========================
Server: {{ ansible_hostname }}
Date: {{ ansible_date_time.iso8601 }}

System Users:
{% for user in ansible_user_list %}
- {{ user.name }} (UID: {{ user.uid }}, Shell: {{ user.shell }})
{% endfor %}

Group Memberships:
{% for group in ansible_group_list %}
- {{ group.name }} (GID: {{ group.gid }})
{% endfor %}

Home Directories:
{% for user in users_to_create %}
- /home/{{ user.username }} - {{ user.full_name }}
{% endfor %}

Audit completed by Ansible
Execute the audit playbook:
ansible-playbook user-audit.yml
Subtask 3.4: User Cleanup and Management
Create a user cleanup playbook:
nano user-cleanup.yml
Add the following content:

---
- name: User Account Cleanup
  hosts: all
  become: yes
  vars:
    users_to_remove:
      - testuser1
      - tempuser
      - olduser
  tasks:
    - name: Check if users exist before removal
      getent:
        database: passwd
        key: "{{ item }}"
      register: user_check
      failed_when: false
      loop: "{{ users_to_remove }}"

    - name: Remove specified user accounts
      user:
        name: "{{ item }}"
        state: absent
        remove: yes
        force: yes
      loop: "{{ users_to_remove }}"
      when: user_check is succeeded

    - name: Archive old user home directories
      archive:
        path: "/home/{{ item }}"
        dest: "/var/backups/{{ item }}-{{ ansible_date_time.date }}.tar.gz"
        remove: yes
      loop: "{{ users_to_remove }}"
      ignore_errors: yes

    - name: Clean up temporary files
      file:
        path: "{{ item }}"
        state: absent
      loop:
        - /tmp/user-*
        - /var/tmp/user-*
      ignore_errors: yes

    - name: Update user count statistics
      shell: "wc -l /etc/passwd"
      register: user_count

    - name: Display user statistics
      debug:
        msg: "Total users on {{ ansible_hostname }}: {{ user_count.stdout.split()[0] }}"
Run the cleanup playbook:
ansible-playbook user-cleanup.yml
Verification and Testing
Verify All Configurations
Test web server accessibility:
ansible webservers -m uri -a "url=http://{{ ansible_default_ipv4.address }}"
Verify user accounts were created:
ansible all -m shell -a "id developer1"
ansible all -m shell -a "id operator1"
Check service status across all hosts:
ansible all -m service_facts
Validate sudo configuration:
ansible all -m shell -a "sudo -l -U developer1" become=yes
Troubleshooting Common Issues
Connection Issues
Problem: SSH connection failures
Solution: Verify SSH keys and network connectivity
ansible all -m ping -vvv
Permission Errors
Problem: Tasks fail due to insufficient privileges
Solution: Ensure become: yes is set in playbooks
ansible-playbook playbook.yml --check --diff
Service Start Failures
Problem: Services fail to start
Solution: Check service dependencies and firewall rules
ansible all -m shell -a "systemctl status httpd" become=yes
User Creation Issues
Problem: User accounts not created properly
Solution: Verify group existence and password policies
ansible all -m shell -a "getent passwd | grep developer"
Conclusion
In this comprehensive lab, you have successfully accomplished the following key automation tasks using Ansible:

What You Learned:

Ad Hoc Commands: Executed immediate tasks across multiple systems for system monitoring, connectivity testing, and information gathering
Playbook Development: Created structured YAML playbooks to automate complex multi-step configurations
Service Management: Automated the installation and configuration of web servers and database systems
User Account Management: Implemented comprehensive user lifecycle management including creation, permission assignment, and cleanup
Infrastructure as Code: Applied IaC principles to ensure consistent and repeatable system configurations
Why This Matters:

Scalability: These skills enable you to manage hundreds or thousands of systems with the same effort as managing one
Consistency: Automated configurations eliminate human error and ensure standardized deployments
Efficiency: Tasks that would take hours manually can now be completed in minutes
Compliance: Automated user management and auditing help maintain security standards and regulatory compliance
Career Advancement: These foundational Ansible skills are essential for DevOps, Cloud Engineering, and System Administration roles
Next Steps:

Practice creating more complex playbooks with conditional logic and loops
Explore Ansible roles for better code organization and reusability
Learn about Ansible Vault for managing sensitive data
Investigate Ansible Tower/AWX for enterprise automation workflows
You now have the fundamental skills to begin automating infrastructure management tasks in enterprise environments, making you well-prepared for the Red Hat Certified Specialist in Services Management and Automation exam and real-world automation challenges.
