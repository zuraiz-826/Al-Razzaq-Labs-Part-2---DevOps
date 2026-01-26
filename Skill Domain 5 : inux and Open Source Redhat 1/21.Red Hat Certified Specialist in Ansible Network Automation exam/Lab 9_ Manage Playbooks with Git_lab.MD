Lab 9: Manage Playbooks with Git
Objectives
By the end of this lab, students will be able to:

Create and initialize a Git repository for Ansible playbook management
Clone existing repositories and understand repository structure
Commit changes to playbooks with meaningful commit messages
Push changes to remote repositories
Create and manage branches for different playbook versions
Merge branches and handle basic merge conflicts
Apply Git best practices for Ansible playbook version control
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with Ansible playbooks and YAML syntax
Basic knowledge of version control concepts
Understanding of file and directory management in Linux
Completed previous Ansible labs (Labs 1-8)
Lab Environment
Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment. No VM setup required.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Git version 2.x
Ansible 4.x or higher
Text editors (vim, nano)
SSH client and server
Task 1: Create a Git Repository for Playbooks
Subtask 1.1: Initialize Your Working Environment
First, let's set up our working directory and configure Git with your identity.

Create a dedicated directory for your Ansible projects:
mkdir -p ~/ansible-projects
cd ~/ansible-projects
Configure Git with your identity (replace with your information):
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
Verify your Git configuration:
git config --list --global
Subtask 1.2: Create Sample Playbooks
Before initializing Git, let's create some sample playbooks to manage.

Create a basic web server playbook:
cat > webserver.yml << 'EOF'
---
- name: Configure Web Server
  hosts: webservers
  become: yes
  vars:
    http_port: 80
    max_clients: 200
  
  tasks:
    - name: Install Apache HTTP Server
      package:
        name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
        state: present
    
    - name: Start and enable Apache service
      service:
        name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
        state: started
        enabled: yes
    
    - name: Create a simple index page
      copy:
        content: |
          <html>
          <head><title>Welcome to Our Web Server</title></head>
          <body>
            <h1>Hello from Ansible Managed Server!</h1>
            <p>Server configured on {{ ansible_date_time.date }}</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        mode: '0644'
    
    - name: Configure firewall for HTTP
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      when: ansible_os_family == "RedHat"
EOF
Create a database server playbook:
cat > database.yml << 'EOF'
---
- name: Configure Database Server
  hosts: dbservers
  become: yes
  vars:
    mysql_root_password: "SecurePassword123!"
    database_name: "webapp_db"
  
  tasks:
    - name: Install MySQL/MariaDB
      package:
        name: "{{ 'mariadb-server' if ansible_os_family == 'RedHat' else 'mysql-server' }}"
        state: present
    
    - name: Install Python MySQL library
      package:
        name: "{{ 'python3-PyMySQL' if ansible_os_family == 'RedHat' else 'python3-pymysql' }}"
        state: present
    
    - name: Start and enable MySQL service
      service:
        name: "{{ 'mariadb' if ansible_os_family == 'RedHat' else 'mysql' }}"
        state: started
        enabled: yes
    
    - name: Create application database
      mysql_db:
        name: "{{ database_name }}"
        state: present
        login_unix_socket: /var/run/mysqld/mysqld.sock
      ignore_errors: yes
EOF
Create an inventory file:
cat > inventory.ini << 'EOF'
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Create an Ansible configuration file:
cat > ansible.cfg << 'EOF'
[defaults]
inventory = inventory.ini
remote_user = ansible
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = memory

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF
Subtask 1.3: Initialize Git Repository
Now let's initialize our Git repository and make our first commit.

Initialize the Git repository:
git init
Create a .gitignore file to exclude unnecessary files:
cat > .gitignore << 'EOF'
# Ansible specific
*.retry
.vault_pass
host_vars/
group_vars/secrets/

# OS specific
.DS_Store
Thumbs.db

# Editor specific
*.swp
*.swo
*~
.vscode/
.idea/

# Logs
*.log

# Temporary files
tmp/
temp/
EOF
Check the status of your repository:
git status
Add all files to the staging area:
git add .
Make your first commit:
git commit -m "Initial commit: Add basic web server and database playbooks"
View your commit history:
git log --oneline
Task 2: Clone a Repository, Commit Changes, and Push Them
Subtask 2.1: Set Up a Remote Repository
For this lab, we'll simulate working with a remote repository using a bare repository on the same system.

Create a bare repository to simulate a remote:
cd ~/
mkdir ansible-playbooks-remote.git
cd ansible-playbooks-remote.git
git init --bare
Return to your working directory and add the remote:
cd ~/ansible-projects
git remote add origin ~/ansible-playbooks-remote.git
Verify the remote configuration:
git remote -v
Subtask 2.2: Push Initial Content
Push your initial commit to the remote repository:
git push -u origin main
Note: If you encounter an error about the branch name, you might need to rename your branch:

git branch -M main
git push -u origin main
Subtask 2.3: Clone the Repository
Now let's simulate another developer cloning the repository.

Create a new directory and clone the repository:
cd ~/
git clone ansible-playbooks-remote.git ansible-projects-clone
cd ansible-projects-clone
Verify the cloned content:
ls -la
git log --oneline
Subtask 2.4: Make Changes and Commit
Let's make some improvements to our playbooks.

Modify the web server playbook to add SSL support:
cat >> webserver.yml << 'EOF'
    
    - name: Install SSL module
      package:
        name: "{{ 'mod_ssl' if ansible_os_family == 'RedHat' else 'apache2-ssl-dev' }}"
        state: present
    
    - name: Configure HTTPS firewall rule
      firewalld:
        service: https
        permanent: yes
        state: enabled
        immediate: yes
      when: ansible_os_family == "RedHat"
EOF
Create a new playbook for system monitoring:
cat > monitoring.yml << 'EOF'
---
- name: Configure System Monitoring
  hosts: all
  become: yes
  
  tasks:
    - name: Install monitoring tools
      package:
        name:
          - htop
          - iotop
          - nethogs
        state: present
    
    - name: Create monitoring script
      copy:
        content: |
          #!/bin/bash
          # System monitoring script
          echo "=== System Status Report ===" > /tmp/system_status.log
          echo "Date: $(date)" >> /tmp/system_status.log
          echo "Uptime: $(uptime)" >> /tmp/system_status.log
          echo "Disk Usage:" >> /tmp/system_status.log
          df -h >> /tmp/system_status.log
          echo "Memory Usage:" >> /tmp/system_status.log
          free -h >> /tmp/system_status.log
        dest: /usr/local/bin/system_monitor.sh
        mode: '0755'
    
    - name: Schedule monitoring script
      cron:
        name: "System monitoring"
        minute: "0"
        hour: "*/6"
        job: "/usr/local/bin/system_monitor.sh"
EOF
Check what files have changed:
git status
View the differences in modified files:
git diff webserver.yml
Add the changes to staging:
git add .
Commit the changes with a descriptive message:
git commit -m "Add SSL support to web server and create monitoring playbook

- Enhanced webserver.yml with SSL module installation
- Added HTTPS firewall configuration
- Created new monitoring.yml playbook with system monitoring tools
- Added automated system status reporting script"
Subtask 2.5: Push Changes to Remote
Push your changes to the remote repository:
git push origin main
Verify the push was successful:
git log --oneline
Task 3: Work with Branches for Managing Playbook Versions
Subtask 3.1: Create and Switch to a Development Branch
Branches allow you to work on different features or versions without affecting the main codebase.

Create a new branch for development:
git checkout -b development
Verify you're on the new branch:
git branch
List all branches including remote:
git branch -a
Subtask 3.2: Develop New Features in the Development Branch
Create a new playbook for security hardening:
cat > security.yml << 'EOF'
---
- name: Security Hardening
  hosts: all
  become: yes
  
  tasks:
    - name: Update all packages
      package:
        name: "*"
        state: latest
      when: ansible_os_family == "RedHat"
    
    - name: Configure automatic security updates
      package:
        name: yum-cron
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Disable root SSH login
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?PermitRootLogin'
        line: 'PermitRootLogin no'
        backup: yes
      notify: restart sshd
    
    - name: Configure password policy
      lineinfile:
        path: /etc/login.defs
        regexp: '^PASS_MAX_DAYS'
        line: 'PASS_MAX_DAYS 90'
        backup: yes
    
    - name: Install and configure fail2ban
      package:
        name: fail2ban
        state: present
    
    - name: Start and enable fail2ban
      service:
        name: fail2ban
        state: started
        enabled: yes
  
  handlers:
    - name: restart sshd
      service:
        name: sshd
        state: restarted
EOF
Modify the database playbook to add backup functionality:
cat >> database.yml << 'EOF'
    
    - name: Create backup directory
      file:
        path: /var/backups/mysql
        state: directory
        mode: '0700'
        owner: mysql
        group: mysql
    
    - name: Create database backup script
      copy:
        content: |
          #!/bin/bash
          BACKUP_DIR="/var/backups/mysql"
          DATE=$(date +%Y%m%d_%H%M%S)
          mysqldump --all-databases > $BACKUP_DIR/full_backup_$DATE.sql
          # Keep only last 7 days of backups
          find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
        dest: /usr/local/bin/mysql_backup.sh
        mode: '0755'
    
    - name: Schedule daily database backup
      cron:
        name: "MySQL backup"
        minute: "0"
        hour: "2"
        job: "/usr/local/bin/mysql_backup.sh"
EOF
Create a main site playbook that orchestrates everything:
cat > site.yml << 'EOF'
---
- import_playbook: security.yml
- import_playbook: webserver.yml
- import_playbook: database.yml
- import_playbook: monitoring.yml
EOF
Commit these development changes:
git add .
git commit -m "Development branch: Add security hardening and backup features

- Created security.yml playbook with hardening measures
- Added database backup functionality to database.yml
- Created site.yml as main orchestration playbook
- Enhanced system security and data protection"
Subtask 3.3: Create a Feature Branch
Let's create another branch for a specific feature.

Create a feature branch for load balancer configuration:
git checkout -b feature/load-balancer
Create a load balancer playbook:
cat > loadbalancer.yml << 'EOF'
---
- name: Configure Load Balancer
  hosts: loadbalancers
  become: yes
  vars:
    backend_servers:
      - { name: "web1", address: "192.168.1.10:80" }
      - { name: "web2", address: "192.168.1.11:80" }
  
  tasks:
    - name: Install HAProxy
      package:
        name: haproxy
        state: present
    
    - name: Configure HAProxy
      template:
        src: haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
        backup: yes
      notify: restart haproxy
    
    - name: Start and enable HAProxy
      service:
        name: haproxy
        state: started
        enabled: yes
    
    - name: Configure firewall for load balancer
      firewalld:
        port: "{{ item }}"
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - "80/tcp"
        - "443/tcp"
        - "8080/tcp"
      when: ansible_os_family == "RedHat"
  
  handlers:
    - name: restart haproxy
      service:
        name: haproxy
        state: restarted
EOF
Create the HAProxy configuration template directory and file:
mkdir -p templates
cat > templates/haproxy.cfg.j2 << 'EOF'
global
    daemon
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog
    option dontlognull

frontend web_frontend
    bind *:80
    bind *:443 ssl crt /etc/ssl/certs/haproxy.pem
    redirect scheme https if !{ ssl_fc }
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /
{% for server in backend_servers %}
    server {{ server.name }} {{ server.address }} check
{% endfor %}

listen stats
    bind *:8080
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
EOF
Update the inventory to include load balancers:
cat >> inventory.ini << 'EOF'

[loadbalancers]
lb1.example.com
EOF
Commit the load balancer feature:
git add .
git commit -m "Feature: Add HAProxy load balancer configuration

- Created loadbalancer.yml playbook
- Added HAProxy configuration template
- Updated inventory to include load balancer hosts
- Configured SSL termination and health checks"
Subtask 3.4: Merge Branches
Now let's merge our feature branch back into development, then merge development into main.

Switch back to the development branch:
git checkout development
Merge the load balancer feature:
git merge feature/load-balancer
Update the site.yml to include the load balancer:
cat > site.yml << 'EOF'
---
- import_playbook: security.yml
- import_playbook: loadbalancer.yml
- import_playbook: webserver.yml
- import_playbook: database.yml
- import_playbook: monitoring.yml
EOF
Commit the updated site.yml:
git add site.yml
git commit -m "Update site.yml to include load balancer playbook"
Switch to main branch:
git checkout main
Merge development into main:
git merge development
Push all changes to remote:
git push origin main
git push origin development
Subtask 3.5: View Branch History and Clean Up
View the commit history with branch visualization:
git log --oneline --graph --all
Delete the feature branch (it's been merged):
git branch -d feature/load-balancer
List remaining branches:
git branch -a
Subtask 3.6: Working with Tags
Tags are useful for marking specific versions of your playbooks.

Create a tag for version 1.0:
git tag -a v1.0 -m "Version 1.0: Complete infrastructure playbooks with security, monitoring, and load balancing"
List all tags:
git tag
Push tags to remote:
git push origin --tags
View tag information:
git show v1.0
Advanced Git Operations for Playbook Management
Subtask 3.7: Handle a Merge Conflict Scenario
Let's simulate a merge conflict and learn how to resolve it.

Create two conflicting branches:
# Create branch for web server updates
git checkout -b webserver-update
Modify the webserver playbook:
sed -i 's/max_clients: 200/max_clients: 500/' webserver.yml
git add webserver.yml
git commit -m "Increase max clients to 500"
Switch to main and create a conflicting change:
git checkout main
sed -i 's/max_clients: 200/max_clients: 300/' webserver.yml
git add webserver.yml
git commit -m "Increase max clients to 300"
Try to merge the webserver-update branch:
git merge webserver-update
Resolve the conflict by editing the file:
# View the conflict
cat webserver.yml | grep -A5 -B5 "<<<<<"

# Edit the file to resolve conflict (choose 500 as the value)
sed -i '/<<<<<<< HEAD/,/>>>>>>> webserver-update/c\    max_clients: 500' webserver.yml
Complete the merge:
git add webserver.yml
git commit -m "Resolve merge conflict: Set max_clients to 500"
Subtask 3.8: Use Git Stash for Temporary Changes
Make some temporary changes:
echo "# Temporary debugging" >> webserver.yml
Stash the changes:
git stash save "Temporary debugging changes"
View stash list:
git stash list
Apply the stash later:
git stash apply
Clean up the stash:
git stash drop
Best Practices and Troubleshooting
Common Git Commands for Playbook Management
Check repository status frequently:
git status
View changes before committing:
git diff
git diff --staged
Undo changes (be careful with these):
# Undo changes in working directory
git checkout -- filename

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
View file history:
git log --follow webserver.yml
Troubleshooting Common Issues
Issue 1: Permission denied when pushing

# Check remote URL
git remote -v
# Update remote URL if needed
git remote set-url origin /path/to/correct/repo
Issue 2: Merge conflicts

# View conflicted files
git status
# Edit files to resolve conflicts
# Add resolved files
git add .
# Complete merge
git commit
Issue 3: Accidentally committed sensitive data

# Remove file from last commit
git rm --cached sensitive_file
git commit --amend -m "Remove sensitive file"
Conclusion
In this comprehensive lab, you have successfully learned how to manage Ansible playbooks using Git version control. Here's what you accomplished:

Key Achievements:

Repository Management: You created a Git repository from scratch, initialized it with Ansible playbooks, and learned to manage the repository lifecycle.

Version Control Workflow: You mastered the fundamental Git workflow of adding, committing, and pushing changes to remote repositories.

Branch Management: You learned to create, switch between, and merge branches, enabling you to work on different features simultaneously without affecting the main codebase.

Collaboration Skills: You practiced cloning repositories and working with remote repositories, essential skills for team collaboration.

Advanced Operations: You handled merge conflicts, used tags for version marking, and learned Git stash for temporary change management.

Why This Matters:

Professional Development: Version control is essential in any professional IT environment
Change Tracking: You can now track every change made to your infrastructure code
Collaboration: Teams can work together on playbooks without conflicts
Rollback Capability: You can easily revert to previous working versions
Release Management: Tags and branches help manage different versions of your infrastructure
Real-World Applications:

Managing infrastructure as code in enterprise environments
Collaborating with team members on automation projects
Maintaining different environments (development, staging, production)
Tracking changes for compliance and audit purposes
Implementing CI/CD pipelines for infrastructure automation
This lab has prepared you with essential skills for the Red Hat Certified Specialist in Ansible Network Automation exam and real-world Ansible automation projects. You now have the foundation to manage complex playbook repositories professionally and efficiently.

Next Steps:

Practice with more complex branching strategies (GitFlow)
Learn about Git hooks for automated testing
Explore integration with CI/CD platforms
Study advanced Git features like rebasing and cherry-picking
