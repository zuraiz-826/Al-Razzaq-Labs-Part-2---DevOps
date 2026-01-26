ab 17: Create and Use Ansible Roles
Objectives
By the end of this lab, you will be able to:

Understand the concept and benefits of Ansible roles
Create a custom Ansible role for web server configuration
Structure role directories and files according to best practices
Use ansible-galaxy command to initialize and manage roles
Import and utilize community roles from Ansible Galaxy
Implement role-based playbooks for modular automation
Apply variables and templates within roles
Test and validate role functionality
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Previous experience with Ansible playbooks and tasks
Knowledge of web server concepts (Apache/Nginx)
Understanding of SSH key-based authentication
Completion of previous Ansible labs or equivalent experience
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click "Start Lab" to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: 2 Ubuntu 20.04 servers for testing roles
Pre-configured SSH keys and inventory files
Internet access for downloading community roles
Task 1: Understanding Ansible Roles Structure
Subtask 1.1: Explore Role Directory Structure
First, let's understand what Ansible roles are and how they're organized.

Connect to your control node and navigate to the working directory:
cd /home/student/ansible-labs
Create a roles directory to organize our custom roles:
mkdir -p roles
cd roles
Examine the standard role directory structure by creating a sample structure:
mkdir -p sample-role/{tasks,handlers,templates,files,vars,defaults,meta}
tree sample-role/
Understand each directory purpose:
tasks/: Contains the main list of tasks to be executed
handlers/: Contains handlers triggered by notify statements
templates/: Contains Jinja2 template files
files/: Contains files to be copied to managed nodes
vars/: Contains variables for the role
defaults/: Contains default variables with lowest precedence
meta/: Contains role metadata and dependencies
Subtask 1.2: Initialize Role with ansible-galaxy
Remove the sample directory and use ansible-galaxy to create a proper role:
rm -rf sample-role
ansible-galaxy init webserver
Examine the generated structure:
tree webserver/
View the generated files:
ls -la webserver/
cat webserver/meta/main.yml
Task 2: Create a Custom Web Server Role
Subtask 2.1: Define Role Variables
Navigate to the webserver role directory:
cd webserver
Edit the defaults file to define default variables:
cat > defaults/main.yml << 'EOF'
---
# defaults file for webserver
webserver_package: apache2
webserver_service: apache2
webserver_port: 80
webserver_document_root: /var/www/html
webserver_index_file: index.html
webserver_admin_email: admin@example.com
firewall_enabled: true
EOF
Create role-specific variables in the vars directory:
cat > vars/main.yml << 'EOF'
---
# vars file for webserver
webserver_packages:
  - "{{ webserver_package }}"
  - ufw

webserver_directories:
  - "{{ webserver_document_root }}"
  - /var/log/apache2

required_modules:
  - rewrite
  - ssl
EOF
Subtask 2.2: Create Role Tasks
Create the main tasks file:
cat > tasks/main.yml << 'EOF'
---
# tasks file for webserver
- name: Update package cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Install web server packages
  apt:
    name: "{{ webserver_packages }}"
    state: present
  when: ansible_os_family == "Debian"

- name: Create web server directories
  file:
    path: "{{ item }}"
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'
  loop: "{{ webserver_directories }}"

- name: Enable Apache modules
  apache2_module:
    name: "{{ item }}"
    state: present
  loop: "{{ required_modules }}"
  notify: restart webserver

- name: Configure firewall for web server
  ufw:
    rule: allow
    port: "{{ webserver_port }}"
    proto: tcp
  when: firewall_enabled

- name: Deploy custom index page
  template:
    src: index.html.j2
    dest: "{{ webserver_document_root }}/{{ webserver_index_file }}"
    owner: www-data
    group: www-data
    mode: '0644'
  notify: restart webserver

- name: Start and enable web server service
  systemd:
    name: "{{ webserver_service }}"
    state: started
    enabled: yes

- name: Verify web server is responding
  uri:
    url: "http://{{ ansible_default_ipv4.address }}:{{ webserver_port }}"
    method: GET
    status_code: 200
  delegate_to: localhost
EOF
Subtask 2.3: Create Role Handlers
Define handlers for service management:
cat > handlers/main.yml << 'EOF'
---
# handlers file for webserver
- name: restart webserver
  systemd:
    name: "{{ webserver_service }}"
    state: restarted
  listen: restart webserver

- name: reload webserver
  systemd:
    name: "{{ webserver_service }}"
    state: reloaded
  listen: reload webserver

- name: restart firewall
  systemd:
    name: ufw
    state: restarted
  listen: restart firewall
EOF
Subtask 2.4: Create Templates
Create a Jinja2 template for the index page:
cat > templates/index.html.j2 << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ ansible_hostname }} Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f4f4f4; }
        .container { background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { color: #333; border-bottom: 2px solid #007acc; padding-bottom: 10px; }
        .info { margin: 20px 0; }
        .highlight { background-color: #e7f3ff; padding: 10px; border-left: 4px solid #007acc; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">Welcome to {{ ansible_hostname }}</h1>
        <div class="info">
            <h2>Server Information</h2>
            <div class="highlight">
                <p><strong>Hostname:</strong> {{ ansible_hostname }}</p>
                <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
                <p><strong>Operating System:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
                <p><strong>Web Server:</strong> {{ webserver_package }}</p>
                <p><strong>Port:</strong> {{ webserver_port }}</p>
                <p><strong>Admin Contact:</strong> {{ webserver_admin_email }}</p>
                <p><strong>Deployment Time:</strong> {{ ansible_date_time.iso8601 }}</p>
            </div>
        </div>
        <div class="info">
            <h2>Role Configuration</h2>
            <p>This web server was configured using an Ansible role with the following features:</p>
            <ul>
                <li>Automated package installation</li>
                <li>Firewall configuration</li>
                <li>Service management</li>
                <li>Custom content deployment</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF
Subtask 2.5: Update Role Metadata
Edit the role metadata:
cat > meta/main.yml << 'EOF'
---
galaxy_info:
  author: Student Lab
  description: A role for setting up and configuring Apache web server
  company: Al Nafi Education
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - focal
        - bionic
    - name: Debian
      versions:
        - buster
        - bullseye
  galaxy_tags:
    - web
    - apache
    - webserver
    - http

dependencies: []
EOF
Task 3: Test the Custom Role
Subtask 3.1: Create a Playbook Using the Role
Navigate back to the main ansible directory:
cd /home/student/ansible-labs
Create a playbook that uses our custom role:
cat > webserver-role-playbook.yml << 'EOF'
---
- name: Deploy Web Server using Custom Role
  hosts: web_servers
  become: yes
  vars:
    webserver_admin_email: "lab-admin@alnafi.com"
    webserver_port: 8080
  roles:
    - webserver

- name: Verify deployment
  hosts: web_servers
  tasks:
    - name: Check if web server is accessible
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ webserver_port }}"
        method: GET
        return_content: yes
      register: web_response
      delegate_to: localhost

    - name: Display web server response
      debug:
        msg: "Web server is responding with status: {{ web_response.status }}"
EOF
Update the inventory file to define web server hosts:
cat > inventory << 'EOF'
[web_servers]
node1 ansible_host=10.0.1.10
node2 ansible_host=10.0.1.11

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/student/.ssh/lab_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
Subtask 3.2: Execute the Role-Based Playbook
Run the playbook with verbose output:
ansible-playbook -i inventory webserver-role-playbook.yml -v
Verify the role execution by checking the deployed web pages:
curl http://10.0.1.10:8080
curl http://10.0.1.11:8080
Test role idempotency by running the playbook again:
ansible-playbook -i inventory webserver-role-playbook.yml
Task 4: Use ansible-galaxy to Import Community Roles
Subtask 4.1: Search and Install Community Roles
Search for available roles on Ansible Galaxy:
ansible-galaxy search nginx --platforms EL
Install a community role for Nginx:
ansible-galaxy install geerlingguy.nginx
List installed roles:
ansible-galaxy list
View role information:
ansible-galaxy info geerlingguy.nginx
Subtask 4.2: Create a Requirements File
Create a requirements.yml file for managing role dependencies:
cat > requirements.yml << 'EOF'
---
# Install roles from Ansible Galaxy
- name: geerlingguy.nginx
  version: "3.1.4"

- name: geerlingguy.mysql
  version: "4.3.4"

- name: geerlingguy.php
  version: "4.9.0"

# Install roles from Git repositories
- src: https://github.com/geerlingguy/ansible-role-docker.git
  scm: git
  version: main
  name: geerlingguy.docker

# Install local roles
- src: ./roles/webserver
  name: local.webserver
EOF
Install roles from requirements file:
ansible-galaxy install -r requirements.yml
Verify installation:
ansible-galaxy list
Subtask 4.3: Create a Multi-Role Playbook
Create a comprehensive playbook using multiple roles:
cat > lamp-stack-playbook.yml << 'EOF'
---
- name: Deploy LAMP Stack using Community Roles
  hosts: web_servers
  become: yes
  vars:
    nginx_remove_default_vhost: true
    nginx_vhosts:
      - listen: "80"
        server_name: "{{ ansible_default_ipv4.address }}"
        root: "/var/www/html"
        index: "index.php index.html index.htm"
        extra_parameters: |
          location ~ \.php$ {
              fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
              fastcgi_index index.php;
              fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
              include fastcgi_params;
          }
    
    mysql_root_password: "SecurePassword123!"
    mysql_databases:
      - name: webapp_db
        encoding: utf8mb4
        collation: utf8mb4_unicode_ci
    
    mysql_users:
      - name: webapp_user
        host: localhost
        password: "WebAppPassword123!"
        priv: "webapp_db.*:ALL"
    
    php_packages:
      - php7.4-fpm
      - php7.4-mysql
      - php7.4-curl
      - php7.4-gd
      - php7.4-mbstring
      - php7.4-xml
      - php7.4-zip

  roles:
    - geerlingguy.nginx
    - geerlingguy.mysql
    - geerlingguy.php

  post_tasks:
    - name: Create PHP info page
      copy:
        content: |
          <?php
          echo "<h1>LAMP Stack Deployed Successfully!</h1>";
          echo "<h2>Server Information</h2>";
          echo "<p><strong>Hostname:</strong> " . gethostname() . "</p>";
          echo "<p><strong>PHP Version:</strong> " . phpversion() . "</p>";
          echo "<p><strong>Server Software:</strong> " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
          
          // Test MySQL connection
          $servername = "localhost";
          $username = "webapp_user";
          $password = "WebAppPassword123!";
          $dbname = "webapp_db";
          
          try {
              $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
              $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
              echo "<p><strong>Database Connection:</strong> <span style='color: green;'>Successful</span></p>";
          } catch(PDOException $e) {
              echo "<p><strong>Database Connection:</strong> <span style='color: red;'>Failed - " . $e->getMessage() . "</span></p>";
          }
          
          echo "<h2>PHP Configuration</h2>";
          phpinfo();
          ?>
        dest: /var/www/html/info.php
        owner: www-data
        group: www-data
        mode: '0644'

    - name: Create simple HTML index
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>LAMP Stack Server</title>
              <style>
                  body { font-family: Arial, sans-serif; margin: 40px; }
                  .container { max-width: 800px; margin: 0 auto; }
                  .success { color: green; font-weight: bold; }
                  .link { display: inline-block; margin: 10px; padding: 10px 20px; background-color: #007acc; color: white; text-decoration: none; border-radius: 5px; }
              </style>
          </head>
          <body>
              <div class="container">
                  <h1>Welcome to Your LAMP Stack Server</h1>
                  <p class="success">✓ Nginx Web Server</p>
                  <p class="success">✓ MySQL Database</p>
                  <p class="success">✓ PHP Processing</p>
                  <p><a href="/info.php" class="link">View PHP Info</a></p>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'
EOF
Execute the multi-role playbook:
ansible-playbook -i inventory lamp-stack-playbook.yml
Task 5: Advanced Role Management
Subtask 5.1: Create Role Dependencies
Create a database role that depends on our webserver role:
cd roles
ansible-galaxy init database
Define dependencies in the database role:
cat > database/meta/main.yml << 'EOF'
---
galaxy_info:
  author: Student Lab
  description: Database role with web server dependency
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - focal

dependencies:
  - role: webserver
    vars:
      webserver_port: 80
      webserver_admin_email: "db-admin@alnafi.com"
EOF
Create database tasks:
cat > database/tasks/main.yml << 'EOF'
---
- name: Install MySQL server
  apt:
    name: mysql-server
    state: present
    update_cache: yes

- name: Install Python MySQL dependencies
  apt:
    name: python3-pymysql
    state: present

- name: Start and enable MySQL service
  systemd:
    name: mysql
    state: started
    enabled: yes

- name: Create application database
  mysql_db:
    name: "{{ db_name | default('app_database') }}"
    state: present
    login_unix_socket: /var/run/mysqld/mysqld.sock

- name: Create database user
  mysql_user:
    name: "{{ db_user | default('app_user') }}"
    password: "{{ db_password | default('SecurePass123!') }}"
    priv: "{{ db_name | default('app_database') }}.*:ALL"
    state: present
    login_unix_socket: /var/run/mysqld/mysqld.sock
EOF
Subtask 5.2: Test Role Dependencies
Create a playbook that uses the database role:
cd /home/student/ansible-labs
cat > database-with-web-playbook.yml << 'EOF'
---
- name: Deploy Database with Web Server Dependencies
  hosts: web_servers
  become: yes
  vars:
    db_name: webapp_db
    db_user: webapp_user
    db_password: "WebApp123!"
    webserver_admin_email: "webapp-admin@alnafi.com"
  roles:
    - database
EOF
Execute the playbook to see dependency resolution:
ansible-playbook -i inventory database-with-web-playbook.yml -v
Subtask 5.3: Create a Custom Role Collection
Create a roles directory structure for a collection:
mkdir -p collections/ansible_collections/alnafi/webstack/{roles,plugins,playbooks}
cd collections/ansible_collections/alnafi/webstack
Create collection metadata:
cat > galaxy.yml << 'EOF'
namespace: alnafi
name: webstack
version: 1.0.0
readme: README.md
authors:
  - "Al Nafi Student Lab"
description: A collection of roles for web stack deployment
license:
  - MIT
tags:
  - web
  - apache
  - mysql
  - php
dependencies: {}
repository: https://github.com/alnafi/webstack-collection
documentation: https://docs.alnafi.com/webstack
homepage: https://www.alnafi.com
issues: https://github.com/alnafi/webstack-collection/issues
EOF
Copy our custom roles to the collection:
cp -r /home/student/ansible-labs/roles/webserver roles/
cp -r /home/student/ansible-labs/roles/database roles/
Build the collection:
cd /home/student/ansible-labs
ansible-galaxy collection build collections/ansible_collections/alnafi/webstack/
Task 6: Role Testing and Validation
Subtask 6.1: Create Role Tests
Create a test directory for our webserver role:
mkdir -p roles/webserver/molecule/default
cd roles/webserver/molecule/default
Create a basic test playbook:
cat > converge.yml << 'EOF'
---
- name: Converge
  hosts: all
  become: yes
  roles:
    - role: webserver
      vars:
        webserver_port: 8080
        webserver_admin_email: "test@example.com"
EOF
Create verification tests:
cat > verify.yml << 'EOF'
---
- name: Verify
  hosts: all
  tasks:
    - name: Check if Apache is running
      systemd:
        name: apache2
      register: apache_status

    - name: Verify Apache is active
      assert:
        that:
          - apache_status.status.ActiveState == "active"
        fail_msg: "Apache service is not running"

    - name: Check if web server responds
      uri:
        url: "http://localhost:8080"
        method: GET
        status_code: 200
      register: web_response

    - name: Verify web content
      assert:
        that:
          - "'Welcome to' in web_response.content"
        fail_msg: "Web server is not serving expected content"
EOF
Subtask 6.2: Manual Role Validation
Create a validation playbook:
cd /home/student/ansible-labs
cat > validate-roles-playbook.yml << 'EOF'
---
- name: Validate Web Server Role Deployment
  hosts: web_servers
  become: yes
  tasks:
    - name: Check Apache service status
      systemd:
        name: apache2
      register: apache_service

    - name: Verify Apache is running
      debug:
        msg: "Apache service is {{ apache_service.status.ActiveState }}"

    - name: Check listening ports
      shell: netstat -tlnp | grep :80
      register: listening_ports
      ignore_errors: yes

    - name: Display listening ports
      debug:
        var: listening_ports.stdout_lines

    - name: Test web server response
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:80"
        method: GET
        return_content: yes
      register: web_test
      delegate_to: localhost

    - name: Verify web server content
      assert:
        that:
          - web_test.status == 200
          - "'Welcome to' in web_test.content"
        success_msg: "Web server is working correctly"
        fail_msg: "Web server validation failed"

    - name: Check firewall rules
      shell: ufw status | grep 80
      register: firewall_rules
      ignore_errors: yes

    - name: Display firewall status
      debug:
        var: firewall_rules.stdout_lines
EOF
Run the validation playbook:
ansible-playbook -i inventory validate-roles-playbook.yml
Task 7: Role Documentation and Best Practices
Subtask 7.1: Document Your Roles
Create comprehensive README for the webserver role:
cat > roles/webserver/README.md << 'EOF'
# Webserver Role

This Ansible role installs and configures Apache web server on Ubuntu/Debian systems.

## Requirements

- Ubuntu 18.04+ or Debian 9+
- Ansible 2.9+
- Sudo privileges on target hosts

## Role Variables

Available variables are listed below, along with default values:

```yaml
# Web server package name
webserver_package: apache2

# Service name
webserver_service: apache2

# Port to listen on
webserver_port: 80

# Document root directory
webserver_document_root: /var/www/html

# Index file name
webserver_index_file: index.html

# Administrator email
webserver_admin_email: admin@example.com

# Enable firewall configuration
firewall_enabled: true
Dependencies
None.

Example Playbook
- hosts: web_servers
  become: yes
  vars:
    webserver_port: 8080
    webserver_admin_email: "admin@mycompany.com"
  roles:
    - webserver
Testing
To test this role:

Create a test inventory
Run the example playbook
Verify web server responds on configured port
Check service status with systemctl status apache2
License
MIT

Author Information
Created for Al Nafi Educational Labs. EOF


2. **Create a changelog**:

```bash
cat > roles/webserver/CHANGELOG.md << 'EOF'
# Changelog

All notable changes to this role will be documented in this file.

## [1.0.0] - 2024-01-15

### Added
- Initial release of webserver role
- Apache installation and configuration
- Firewall management
- Custom index page template
- Service management handlers
- Role metadata and documentation

### Features
- Ubuntu/Debian support
- Configurable port and document root
- Template-based content deployment
- Idempotent operations
- Comprehensive error handling
EOF
Subtask 7.2: Implement Role Best Practices
Create a role linting configuration:
cat > .ansible-lint << 'EOF'
---
exclude_paths:
  - .cache/
  - .github/
  - molecule/
  - .ansible-lint

use_default_rules: true
verbosity: 1

rules:
  line-length:
    max: 120
  truthy:
    allowed-values: ['true', 'false', 'yes', 'no']
EOF
Create a comprehensive inventory for testing:
cat > test-inventory << 'EOF'
[web_servers]
node1 ansible_host=10.0.1.10 webserver_port=80
node2 ansible_host=10.0.1.11 webserver_port=8080

[database_servers]
node1 ansible_host=10.0.1.10

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/student/.ssh/lab_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
webserver_admin_email=lab@alnafi.com
firewall_enabled=true
EOF
Create a final comprehensive playbook:
cat > final-role-demo-playbook.yml << 'EOF'
---
- name: Comprehensive Role Demonstration
  hosts: all
  become: yes
  gather_facts: yes
  
  pre_tasks:
    - name: Display target host information
      debug:
        msg: |
          Configuring {{ inventory_hostname }}
          IP: {{ ansible_default_ipv4.address }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}

  roles:
    - role: webserver
      when: inventory_hostname in groups['web_servers']
      tags: ['web', 'apache']
    
    - role: database
      when: inventory_hostname in groups['database_servers']
      tags: ['db', 'mysql']

  post_tasks:
    - name: Verify services are running
      systemd:
        name: "{{ item }}"
      register: service_status
      loop:
        - apache2
        - mysql
      when: item in ansible_facts.services
      ignore_errors: yes

    - name: Display service status
      debug:
        msg: "{{ item.item }} service is {{ item.status.ActiveState | default('not installed') }}"
      loop: "{{ service_status.results }}"
      when: service_status.results is defined

    - name: Create deployment summary
      copy:
        content: |
          Deployment Summary
          ==================
          Host: {{ inventory_hostname }}
          IP Address: {{ ansible_default_ipv4.address }}
          Deployment Time: {{ ansible_date_time.iso8601 }}
          
          Installed Roles:
          {% if inventory_hostname in groups['web_servers'] %}
          - Web Server (Apache) on port {{ webserver_port }}
          {% endif %}
          {% if inventory_hostname in groups['database_servers'] %}
          - Database Server (MySQL)
          {% endif %}
          
          Admin Contact: {{ webserver_admin_email }}
        dest: /tmp/deployment-summary.txt
        mode: '0644'

    - name: Display deployment completion
      debug:
        msg: |
          ✓ Role-based deployment completed successfully!
          ✓ Check /tmp/deployment-summary.txt for details
          {% if inventory_hostname in groups['web_servers'] %}
          ✓ Web server accessible at: http://{{ ansible_default_ipv4.address }}:{{ webserver_port }}
          {% endif %}
EOF
Execute the final demonstration:
ansible-playbook -i test-inventory final-role-demo-playbook.yml --tags web,db
Troubleshooting Common Issues
Issue 1: Role Not Found
Problem: Ansible cannot find the custom role Solution:

# Check role path
ansible-config dump | grep ROLES_PATH
# Ensure role is in correct directory structure
ls -la roles/webserver/
Issue 2: Template Rendering Errors
Problem: Jinja2 template variables not rendering Solution:

# Test template syntax
ansible-playbook --syntax-check playbook.yml
# Check variable definitions
ansible-playbook -i inventory playbook.yml --list-tasks -v
Issue 3: Handler Not Triggered
Problem: Service restart handler not executing Solution:

# Verify handler names match notify statements
grep -r "notify:" roles/webserver/tasks/
grep -r "listen:" roles/webserver/handlers/
Issue 4: Permission Denied Errors
Problem: Tasks failing due to insufficient permissions Solution:

# Ensure become: yes is set
# Check SSH key permissions
chmod 600 /home/student/.ssh/lab_key
# Verify sudo access on target hosts
ansible all -i inventory -m shell -a "sudo whoami"
Conclusion
Congratulations! You have successfully completed Lab 17: Create and Use Ansible Roles. In this comprehensive lab, you have accomplished the following:

Key Achievements
Mastered Ansible Role Structure: You learned the standard directory layout for Ansible roles and understand the purpose of each component (tasks, handlers, templates, vars, defaults, meta).

Created Custom Roles: You built a complete webserver role from scratch, including:
