Lab 5: Creating Ansible Roles
Objectives
By the end of this lab, students will be able to:

Understand the concept and benefits of Ansible roles
Create a basic Ansible role structure from scratch
Develop a reusable web server role with proper organization
Implement role dependencies to manage complex deployments
Use Ansible Galaxy to download and integrate community roles
Apply best practices for role development and maintenance
Execute playbooks that utilize custom and community roles
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ansible playbooks and YAML syntax
Familiarity with Linux command line operations
Knowledge of web server concepts (Apache/Nginx)
Experience with package management on Linux systems
Completion of previous Ansible labs or equivalent knowledge
Lab Environment
Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software - everything is ready to go!

Your lab environment includes:

CentOS/RHEL-based control node with Ansible pre-installed
Multiple target nodes for testing roles
Internet access for Ansible Galaxy integration
All necessary development tools
Task 1: Create a Basic Role to Manage Web Server Installation
Subtask 1.1: Understanding Ansible Role Structure
Before creating our first role, let's understand what makes up an Ansible role.

What is an Ansible Role? An Ansible role is a way to organize playbooks and related files in a standardized directory structure. Roles make your automation code reusable, maintainable, and shareable.

Standard Role Directory Structure:

role_name/
├── tasks/          # Main list of tasks
├── handlers/       # Handlers for services
├── templates/      # Jinja2 templates
├── files/          # Static files to copy
├── vars/           # Variables for the role
├── defaults/       # Default variables
├── meta/           # Role metadata and dependencies
└── README.md       # Documentation
Subtask 1.2: Create the Role Directory Structure
Navigate to your home directory and create a roles directory:
cd ~
mkdir -p ansible-lab/roles
cd ansible-lab/roles
Create the web server role structure using ansible-galaxy:
ansible-galaxy init webserver
Verify the role structure was created:
tree webserver
You should see output similar to:

webserver/
├── README.md
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── tasks
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml
Subtask 1.3: Define Role Variables
Edit the default variables file:
nano webserver/defaults/main.yml
Add the following content:
---
# defaults file for webserver
webserver_package: httpd
webserver_service: httpd
webserver_port: 80
webserver_document_root: /var/www/html
webserver_index_file: index.html
webserver_user: apache
webserver_group: apache
Create role-specific variables:
nano webserver/vars/main.yml
Add the following content:
---
# vars file for webserver
webserver_config_file: /etc/httpd/conf/httpd.conf
webserver_log_dir: /var/log/httpd
firewall_service: firewalld
Subtask 1.4: Create the Main Tasks
Edit the main tasks file:
nano webserver/tasks/main.yml
Add the following comprehensive tasks:
---
# tasks file for webserver
- name: Install web server package
  package:
    name: "{{ webserver_package }}"
    state: present
  become: yes

- name: Install additional packages
  package:
    name:
      - firewalld
      - curl
    state: present
  become: yes

- name: Create web server user
  user:
    name: "{{ webserver_user }}"
    group: "{{ webserver_group }}"
    system: yes
    shell: /sbin/nologin
    home: "{{ webserver_document_root }}"
    create_home: no
  become: yes

- name: Create document root directory
  file:
    path: "{{ webserver_document_root }}"
    state: directory
    owner: "{{ webserver_user }}"
    group: "{{ webserver_group }}"
    mode: '0755'
  become: yes

- name: Create a simple index.html
  template:
    src: index.html.j2
    dest: "{{ webserver_document_root }}/{{ webserver_index_file }}"
    owner: "{{ webserver_user }}"
    group: "{{ webserver_group }}"
    mode: '0644'
  become: yes
  notify: restart webserver

- name: Start and enable firewall service
  systemd:
    name: "{{ firewall_service }}"
    state: started
    enabled: yes
  become: yes

- name: Open firewall port for web server
  firewalld:
    port: "{{ webserver_port }}/tcp"
    permanent: yes
    state: enabled
    immediate: yes
  become: yes

- name: Start and enable web server service
  systemd:
    name: "{{ webserver_service }}"
    state: started
    enabled: yes
  become: yes
  notify: restart webserver
Subtask 1.5: Create Templates
Create the templates directory and index.html template:
nano webserver/templates/index.html.j2
Add the following template content:
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to {{ ansible_hostname }}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { color: #333; text-align: center; }
        .info { background-color: #f4f4f4; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1 class="header">Web Server Successfully Deployed!</h1>
    <div class="info">
        <h2>Server Information:</h2>
        <p><strong>Hostname:</strong> {{ ansible_hostname }}</p>
        <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
        <p><strong>Operating System:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
        <p><strong>Web Server:</strong> {{ webserver_package }}</p>
        <p><strong>Port:</strong> {{ webserver_port }}</p>
        <p><strong>Document Root:</strong> {{ webserver_document_root }}</p>
        <p><strong>Deployed by:</strong> Ansible Role</p>
    </div>
</body>
</html>
Subtask 1.6: Create Handlers
Edit the handlers file:
nano webserver/handlers/main.yml
Add the following handlers:
---
# handlers file for webserver
- name: restart webserver
  systemd:
    name: "{{ webserver_service }}"
    state: restarted
  become: yes

- name: reload webserver
  systemd:
    name: "{{ webserver_service }}"
    state: reloaded
  become: yes

- name: restart firewall
  systemd:
    name: "{{ firewall_service }}"
    state: restarted
  become: yes
Subtask 1.7: Create Role Metadata
Edit the meta file to define role information:
nano webserver/meta/main.yml
Add the following metadata:
---
galaxy_info:
  author: Your Name
  description: A role to install and configure a web server
  company: Al Nafi Training
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: EL
      versions:
        - 7
        - 8
        - 9
  galaxy_tags:
    - webserver
    - httpd
    - apache
    - web

dependencies: []
Subtask 1.8: Test the Web Server Role
Create an inventory file:
cd ~/ansible-lab
nano inventory
Add your target hosts:
[webservers]
target1 ansible_host=<TARGET_IP_1>
target2 ansible_host=<TARGET_IP_2>

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
Create a playbook to test the role:
nano test-webserver.yml
Add the following playbook content:
---
- name: Test Web Server Role
  hosts: webservers
  become: yes
  roles:
    - webserver

  post_tasks:
    - name: Verify web server is running
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ webserver_port }}"
        method: GET
        status_code: 200
      delegate_to: localhost

    - name: Display web server status
      debug:
        msg: "Web server is successfully running on http://{{ ansible_default_ipv4.address }}:{{ webserver_port }}"
Run the playbook:
ansible-playbook -i inventory test-webserver.yml
Task 2: Implement Role Dependencies
Subtask 2.1: Create a Database Role
Create a new role for database management:
cd ~/ansible-lab/roles
ansible-galaxy init database
Define database role variables:
nano database/defaults/main.yml
Add the following content:
---
# defaults file for database
db_package: mariadb-server
db_service: mariadb
db_port: 3306
db_root_password: SecurePassword123!
db_user: webapp
db_password: WebAppPassword123!
db_name: webapp_db
Create database tasks:
nano database/tasks/main.yml
Add the following tasks:
---
# tasks file for database
- name: Install database server
  package:
    name:
      - "{{ db_package }}"
      - python3-PyMySQL
    state: present
  become: yes

- name: Start and enable database service
  systemd:
    name: "{{ db_service }}"
    state: started
    enabled: yes
  become: yes

- name: Open firewall port for database
  firewalld:
    port: "{{ db_port }}/tcp"
    permanent: yes
    state: enabled
    immediate: yes
  become: yes
  ignore_errors: yes

- name: Set root password
  mysql_user:
    name: root
    password: "{{ db_root_password }}"
    login_unix_socket: /var/lib/mysql/mysql.sock
  become: yes
  ignore_errors: yes

- name: Create application database
  mysql_db:
    name: "{{ db_name }}"
    state: present
    login_user: root
    login_password: "{{ db_root_password }}"
  become: yes

- name: Create application user
  mysql_user:
    name: "{{ db_user }}"
    password: "{{ db_password }}"
    priv: "{{ db_name }}.*:ALL"
    state: present
    login_user: root
    login_password: "{{ db_root_password }}"
  become: yes
Subtask 2.2: Create a Full-Stack Application Role
Create a new role that depends on both webserver and database:
ansible-galaxy init webapp
Define the dependency in the webapp role:
nano webapp/meta/main.yml
Add the following metadata with dependencies:
---
galaxy_info:
  author: Your Name
  description: A full-stack web application role
  company: Al Nafi Training
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: EL
      versions:
        - 7
        - 8
        - 9
  galaxy_tags:
    - webapp
    - fullstack

dependencies:
  - role: database
    vars:
      db_name: webapp_production
      db_user: webapp_prod
  - role: webserver
    vars:
      webserver_port: 8080
Create webapp-specific tasks:
nano webapp/tasks/main.yml
Add the following tasks:
---
# tasks file for webapp
- name: Install PHP and required modules
  package:
    name:
      - php
      - php-mysql
      - php-json
      - php-curl
    state: present
  become: yes

- name: Create application directory
  file:
    path: /var/www/html/webapp
    state: directory
    owner: apache
    group: apache
    mode: '0755'
  become: yes

- name: Deploy application configuration
  template:
    src: config.php.j2
    dest: /var/www/html/webapp/config.php
    owner: apache
    group: apache
    mode: '0644'
  become: yes
  notify: restart webserver

- name: Deploy sample application
  template:
    src: app.php.j2
    dest: /var/www/html/webapp/index.php
    owner: apache
    group: apache
    mode: '0644'
  become: yes
Create PHP configuration template:
nano webapp/templates/config.php.j2
Add the following PHP configuration:
<?php
// Database configuration
define('DB_HOST', 'localhost');
define('DB_NAME', '{{ db_name }}');
define('DB_USER', '{{ db_user }}');
define('DB_PASS', '{{ db_password }}');
define('DB_PORT', {{ db_port }});

// Application settings
define('APP_NAME', 'Web Application');
define('APP_VERSION', '1.0.0');
define('DEBUG', false);
?>
Create a simple PHP application:
nano webapp/templates/app.php.j2
Add the following PHP application:
<?php
require_once 'config.php';

echo "<h1>Welcome to " . APP_NAME . "</h1>";
echo "<p>Version: " . APP_VERSION . "</p>";
echo "<p>Server: " . gethostname() . "</p>";

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    echo "<p style='color: green;'>Database connection: SUCCESS</p>";
    
    // Create a simple table and insert data
    $pdo->exec("CREATE TABLE IF NOT EXISTS visitors (
        id INT AUTO_INCREMENT PRIMARY KEY,
        visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ip_address VARCHAR(45)
    )");
    
    $stmt = $pdo->prepare("INSERT INTO visitors (ip_address) VALUES (?)");
    $stmt->execute([$_SERVER['REMOTE_ADDR']]);
    
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM visitors");
    $count = $stmt->fetch()['count'];
    echo "<p>Total visits: " . $count . "</p>";
    
} catch(PDOException $e) {
    echo "<p style='color: red;'>Database connection failed: " . $e->getMessage() . "</p>";
}
?>
Subtask 2.3: Test Role Dependencies
Create a playbook to test the full-stack application:
cd ~/ansible-lab
nano test-webapp.yml
Add the following playbook:
---
- name: Deploy Full-Stack Web Application
  hosts: webservers
  become: yes
  roles:
    - webapp

  post_tasks:
    - name: Wait for services to be ready
      wait_for:
        port: "{{ item }}"
        host: "{{ ansible_default_ipv4.address }}"
        delay: 10
      loop:
        - "{{ webserver_port | default(8080) }}"
        - "{{ db_port | default(3306) }}"

    - name: Test web application
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ webserver_port | default(8080) }}/webapp/"
        method: GET
        status_code: 200
      delegate_to: localhost

    - name: Display application URL
      debug:
        msg: "Full-stack application is running at http://{{ ansible_default_ipv4.address }}:{{ webserver_port | default(8080) }}/webapp/"
Run the full-stack deployment:
ansible-playbook -i inventory test-webapp.yml
Task 3: Use Ansible Galaxy to Download and Implement a Pre-existing Role
Subtask 3.1: Explore Ansible Galaxy
Search for available roles on Ansible Galaxy:
ansible-galaxy search nginx
Get information about a specific role:
ansible-galaxy info geerlingguy.nginx
List currently installed roles:
ansible-galaxy list
Subtask 3.2: Install a Community Role
Install the popular nginx role from Ansible Galaxy:
ansible-galaxy install geerlingguy.nginx
Install additional useful roles:
ansible-galaxy install geerlingguy.firewall
ansible-galaxy install geerlingguy.security
Verify the roles were installed:
ansible-galaxy list
Examine the installed role structure:
ls -la ~/.ansible/roles/geerlingguy.nginx/
Subtask 3.3: Create a Requirements File
Create a requirements.yml file for managing role dependencies:
nano requirements.yml
Add the following content:
---
# Install from Ansible Galaxy
- name: geerlingguy.nginx
  version: "3.1.4"

- name: geerlingguy.firewall
  version: "2.5.0"

- name: geerlingguy.security
  version: "2.0.1"

# Install from Git repository
- name: custom-monitoring
  src: https://github.com/example/ansible-monitoring-role.git
  version: main

# Install from local path
- name: local-role
  src: ./roles/webserver
Install roles from requirements file:
ansible-galaxy install -r requirements.yml
Subtask 3.4: Create a Playbook Using Community Roles
Create a comprehensive playbook using community roles:
nano nginx-deployment.yml
Add the following playbook content:
---
- name: Deploy Nginx Web Server with Security
  hosts: webservers
  become: yes
  
  vars:
    nginx_vhosts:
      - listen: "80"
        server_name: "{{ ansible_default_ipv4.address }}"
        root: "/var/www/html"
        index: "index.html index.htm"
        extra_parameters: |
          location / {
              try_files $uri $uri/ =404;
          }
          location /api/ {
              proxy_pass http://localhost:3000/;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
          }
    
    nginx_remove_default_vhost: true
    
    firewall_allowed_tcp_ports:
      - "22"
      - "80"
      - "443"
    
    security_autoupdate_enabled: true
    security_fail2ban_enabled: true

  roles:
    - geerlingguy.security
    - geerlingguy.firewall
    - geerlingguy.nginx

  post_tasks:
    - name: Create custom index page
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Nginx Deployed via Ansible Galaxy</title>
              <style>
                  body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
                  .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                  .header { color: #2c3e50; text-align: center; }
                  .success { color: #27ae60; font-weight: bold; }
              </style>
          </head>
          <body>
              <div class="container">
                  <h1 class="header">🚀 Nginx Successfully Deployed!</h1>
                  <p class="success">This server was configured using Ansible Galaxy community roles.</p>
                  <h3>Server Details:</h3>
                  <ul>
                      <li><strong>Hostname:</strong> {{ ansible_hostname }}</li>
                      <li><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</li>
                      <li><strong>OS:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</li>
                      <li><strong>Web Server:</strong> Nginx (via geerlingguy.nginx role)</li>
                      <li><strong>Security:</strong> Enhanced (via geerlingguy.security role)</li>
                      <li><strong>Firewall:</strong> Configured (via geerlingguy.firewall role)</li>
                  </ul>
                  <p><em>Deployed with ❤️ using Ansible</em></p>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: nginx
        group: nginx
        mode: '0644'

    - name: Test Nginx is responding
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      delegate_to: localhost

    - name: Display deployment success message
      debug:
        msg: "Nginx deployment completed successfully! Visit http://{{ ansible_default_ipv4.address }}"
Run the Nginx deployment playbook:
ansible-playbook -i inventory nginx-deployment.yml
Subtask 3.5: Create a Custom Role Collection
Create a roles directory structure for your custom collection:
mkdir -p ~/ansible-lab/collections/ansible_collections/alnafi/webstack
cd ~/ansible-lab/collections/ansible_collections/alnafi/webstack
Initialize the collection:
ansible-galaxy collection init alnafi.webstack --init-path ~/ansible-lab/collections/ansible_collections/
Create a galaxy.yml file for the collection:
nano galaxy.yml
Add collection metadata:
namespace: alnafi
name: webstack
version: 1.0.0
readme: README.md
authors:
  - Al Nafi Training Team
description: A collection of roles for web stack deployment
license:
  - MIT
tags:
  - webserver
  - database
  - fullstack
dependencies: {}
repository: https://github.com/alnafi/ansible-webstack
documentation: https://docs.alnafi.com/ansible-webstack
homepage: https://alnafi.com
issues: https://github.com/alnafi/ansible-webstack/issues
Move your custom roles to the collection:
mkdir -p roles
cp -r ~/ansible-lab/roles/webserver roles/
cp -r ~/ansible-lab/roles/database roles/
cp -r ~/ansible-lab/roles/webapp roles/
Build the collection:
ansible-galaxy collection build
Subtask 3.6: Test the Complete Setup
Create a final comprehensive playbook:
cd ~/ansible-lab
nano final-deployment.yml
Add the following comprehensive playbook:
---
- name: Complete Web Stack Deployment
  hosts: webservers
  become: yes
  
  vars:
    deployment_environment: production
    monitoring_enabled: true

  pre_tasks:
    - name: Update system packages
      package:
        name: '*'
        state: latest
      when: ansible_os_family == "RedHat"

    - name: Display deployment information
      debug:
        msg: |
          Starting deployment on {{ ansible_hostname }}
          Environment: {{ deployment_environment }}
          IP Address: {{ ansible_default_ipv4.address }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}

  roles:
    # Security and firewall first
    - geerlingguy.security
    - geerlingguy.firewall
    
    # Our custom roles
    - database
    - webserver
    - webapp
    
    # Community nginx role for load balancing
    - role: geerlingguy.nginx
      vars:
        nginx_vhosts:
          - listen: "80"
            server_name: "{{ ansible_default_ipv4.address }}"
            root: "/var/www/html"
            index: "index.html"
            extra_parameters: |
              location /app/ {
                  proxy_pass http://localhost:8080/webapp/;
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
              }

  post_tasks:
    - name: Verify all services are running
      systemd:
        name: "{{ item }}"
        state: started
      loop:
        - httpd
        - mariadb
        - nginx
        - firewalld

    - name: Test all endpoints
      uri:
        url: "{{ item }}"
        method: GET
        status_code: 200
      loop:
        - "http://{{ ansible_default_ipv4.address }}"
        - "http://{{ ansible_default_ipv4.address }}/app/"
      delegate_to: localhost

    - name: Display final deployment status
      debug:
        msg: |
          🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉
          
          Services Available:
          - Main Website: http://{{ ansible_default_ipv4.address }}
          - Web Application: http://{{ ansible_default_ipv4.address }}/app/
          - Database: {{ ansible_default_ipv4.address }}:3306
          
          Security Features:
          - Firewall configured and active
          - Security hardening applied
          - Fail2ban protection enabled
          
          All services are running and accessible!
Run the final comprehensive deployment:
ansible-playbook -i inventory final-deployment.yml
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Role not found error

# Solution: Ensure roles are in the correct path
export ANSIBLE_ROLES_PATH=~/ansible-lab/roles:~/.ansible/roles:/etc/ansible/roles
Issue 2: Permission denied errors

# Solution: Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
# Verify sudo access on target hosts
ansible all -i inventory -m ping --become
Issue 3: Service startup failures

# Solution: Check service status and logs
ansible all -i inventory -m shell -a "systemctl status httpd" --become
ansible all -i inventory -m shell -a "journalctl -u httpd -n 20" --become
Issue 4: Firewall blocking connections

# Solution: Verify firewall rules
ansible all -i inventory -m shell -a "firewall-cmd --list-all" --become
Issue 5: Database connection issues

# Solution: Check database service and user permissions
ansible all -i inventory -m shell -a "systemctl status mariadb" --become
ansible all -i inventory -m shell -a "mysql -u root -p -e 'SHOW DATABASES;'" --become
Conclusion
Congratulations! You have successfully completed Lab 5: Creating Ansible Roles. In this comprehensive lab, you have accomplished the following:

What You Learned
Role Structure and Organization: You created well-structured Ansible roles following best practices with proper directory organization, making your automation code reusable and maintainable.

Custom Role Development: You built a complete web server role from scratch, including tasks, templates, handlers, variables, and metadata, demonstrating the full lifecycle of role development.

Role Dependencies: You implemented complex role dependencies by creating a full-stack application that automatically deploys both web server and database components, showing how roles can work together seamlessly.

Community Role Integration: You successfully used Ansible Galaxy to discover, install, and implement community-maintained roles, leveraging the power of the Ansible ecosystem.

Advanced Deployment Patterns: You created comprehensive playbooks that combine custom roles with community roles to deploy complete, production-ready infrastructure.

Why This Matters
For Your Career: Understanding Ansible roles is crucial for the Red Hat Certified Engineer (RHCE) certification and demonstrates advanced automation skills that are highly valued in DevOps and system administration roles.

For Real-World Applications: The skills you've learned enable you to:

Create reusable automation components that can be shared across teams
Implement complex, multi-tier application deployments
Leverage community expertise through Ansible Galaxy
Maintain consistent, reliable infrastructure deployments
Scale automation efforts across large organizations
Best Practices You've Mastered:

Proper role structure and organization
Variable management and templating
Service orchestration and dependency management
Error handling and troubleshooting
Documentation and metadata management
Next Steps
With these role creation skills, you're now ready to:

Develop custom role collections for your organization
Contribute roles back to the Ansible Galaxy community
Implement advanced automation patterns like blue-green deployments
Integrate Ansible roles with CI/CD pipelines
Pursue advanced Ansible certifications and specializations
The foundation you've built in this lab will serve as the cornerstone for all your future infrastructure automation endeavors. Keep practicing, keep automating, and keep building amazing things with Ansible!
