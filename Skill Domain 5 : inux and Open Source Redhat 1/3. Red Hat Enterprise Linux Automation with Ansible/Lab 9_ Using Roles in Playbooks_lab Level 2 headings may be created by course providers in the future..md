Lab 9: Using Roles in Playbooks
Objectives
By the end of this lab, students will be able to:

• Understand the concept and benefits of Ansible roles • Create a custom role for installing and configuring Apache web server • Organize tasks, handlers, and templates into appropriate role directories • Include roles in playbooks effectively • Apply role-based automation to manage web server configurations • Implement best practices for role structure and organization

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with YAML syntax and structure • Completion of previous Ansible labs covering playbooks and basic tasks • Understanding of web server concepts (Apache HTTP Server) • Knowledge of file permissions and directory structures in Linux

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes: • Control node with Ansible pre-installed • Two managed nodes (web servers) • All necessary networking and SSH configurations • Text editors (nano, vim) available for file editing

Task 1: Understanding Ansible Roles Structure
Subtask 1.1: Explore the Standard Role Directory Structure
First, let's understand how Ansible roles are organized.

Navigate to your home directory and create a roles directory:
cd ~
mkdir -p ansible-lab9/roles
cd ansible-lab9
Create the standard role structure for an Apache web server role:
mkdir -p roles/apache-webserver/{tasks,handlers,templates,files,vars,defaults,meta}
Verify the directory structure:
tree roles/
Expected output:

roles/
└── apache-webserver
    ├── defaults
    ├── files
    ├── handlers
    ├── meta
    ├── tasks
    ├── templates
    └── vars
Subtask 1.2: Understanding Each Directory Purpose
Let's create a documentation file to understand each directory:

cat > role-structure-guide.txt << 'EOF'
Ansible Role Directory Structure:

tasks/     - Contains the main list of tasks to be executed by the role
handlers/  - Contains handlers triggered by notify statements
templates/ - Contains Jinja2 template files
files/     - Contains files to be copied to managed nodes
vars/      - Contains variables for the role (higher precedence)
defaults/  - Contains default variables for the role (lower precedence)
meta/      - Contains role metadata and dependencies
EOF
Task 2: Create a Custom Role for Installing Apache Web Server
Subtask 2.1: Create the Main Tasks File
Create the main tasks file for the Apache role:
cat > roles/apache-webserver/tasks/main.yml << 'EOF'
---
# Main tasks file for apache-webserver role

- name: Install Apache HTTP Server
  package:
    name: "{{ apache_package_name }}"
    state: present
  become: yes

- name: Start and enable Apache service
  service:
    name: "{{ apache_service_name }}"
    state: started
    enabled: yes
  become: yes
  notify: restart apache

- name: Create document root directory
  file:
    path: "{{ document_root }}"
    state: directory
    owner: "{{ apache_user }}"
    group: "{{ apache_group }}"
    mode: '0755'
  become: yes

- name: Deploy custom index.html from template
  template:
    src: index.html.j2
    dest: "{{ document_root }}/index.html"
    owner: "{{ apache_user }}"
    group: "{{ apache_group }}"
    mode: '0644'
  become: yes
  notify: restart apache

- name: Configure Apache virtual host
  template:
    src: vhost.conf.j2
    dest: "{{ apache_config_dir }}/{{ site_name }}.conf"
    owner: root
    group: root
    mode: '0644'
  become: yes
  notify: restart apache

- name: Open firewall for HTTP traffic
  firewalld:
    service: http
    permanent: yes
    state: enabled
    immediate: yes
  become: yes
  ignore_errors: yes
EOF
Subtask 2.2: Create Default Variables
Define default variables for the role:
cat > roles/apache-webserver/defaults/main.yml << 'EOF'
---
# Default variables for apache-webserver role

# Package and service names (will vary by OS)
apache_package_name: httpd
apache_service_name: httpd
apache_user: apache
apache_group: apache

# Paths and directories
document_root: /var/www/html
apache_config_dir: /etc/httpd/conf.d

# Site configuration
site_name: default-site
server_name: "{{ ansible_fqdn }}"
server_admin: admin@example.com

# Custom variables
welcome_message: "Welcome to our Apache Web Server!"
company_name: "Al Nafi Learning Lab"
EOF
Subtask 2.3: Create Variable Overrides
Create role-specific variables that override defaults:
cat > roles/apache-webserver/vars/main.yml << 'EOF'
---
# Role variables for apache-webserver (higher precedence than defaults)

# These variables override defaults and are specific to this role
apache_port: 80
max_connections: 100
timeout: 300

# Security settings
server_tokens: "Prod"
server_signature: "Off"
EOF
Task 3: Create Handlers for the Role
Subtask 3.1: Define Service Handlers
Create handlers to manage Apache service operations:
cat > roles/apache-webserver/handlers/main.yml << 'EOF'
---
# Handlers for apache-webserver role

- name: restart apache
  service:
    name: "{{ apache_service_name }}"
    state: restarted
  become: yes

- name: reload apache
  service:
    name: "{{ apache_service_name }}"
    state: reloaded
  become: yes

- name: start apache
  service:
    name: "{{ apache_service_name }}"
    state: started
  become: yes

- name: stop apache
  service:
    name: "{{ apache_service_name }}"
    state: stopped
  become: yes
EOF
Task 4: Create Templates for Configuration Files
Subtask 4.1: Create HTML Template
Create a dynamic HTML template:
cat > roles/apache-webserver/templates/index.html.j2 << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ company_name }} - Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .info {
            background-color: #e7f3ff;
            padding: 15px;
            border-left: 4px solid #2196F3;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>{{ welcome_message }}</h1>
        <div class="info">
            <h3>Server Information:</h3>
            <p><strong>Hostname:</strong> {{ ansible_hostname }}</p>
            <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
            <p><strong>Operating System:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
            <p><strong>Server Admin:</strong> {{ server_admin }}</p>
            <p><strong>Deployed by:</strong> Ansible Role</p>
        </div>
        <p>This web server was configured automatically using Ansible roles!</p>
        <p><em>Powered by {{ company_name }}</em></p>
    </div>
</body>
</html>
EOF
Subtask 4.2: Create Apache Virtual Host Template
Create a virtual host configuration template:
cat > roles/apache-webserver/templates/vhost.conf.j2 << 'EOF'
# Virtual Host Configuration for {{ site_name }}
# Generated by Ansible Role: apache-webserver

<VirtualHost *:{{ apache_port }}>
    ServerName {{ server_name }}
    ServerAdmin {{ server_admin }}
    DocumentRoot {{ document_root }}
    
    # Security settings
    ServerTokens {{ server_tokens }}
    ServerSignature {{ server_signature }}
    
    # Performance settings
    Timeout {{ timeout }}
    MaxRequestWorkers {{ max_connections }}
    
    # Logging
    ErrorLog logs/{{ site_name }}_error.log
    CustomLog logs/{{ site_name }}_access.log combined
    
    # Directory permissions
    <Directory "{{ document_root }}">
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
</VirtualHost>
EOF
Task 5: Create Role Metadata
Subtask 5.1: Define Role Metadata
Create metadata file for the role:
cat > roles/apache-webserver/meta/main.yml << 'EOF'
---
# Role metadata for apache-webserver

galaxy_info:
  author: Al Nafi Learning Lab
  description: Apache HTTP Server installation and configuration role
  company: Al Nafi
  license: MIT
  min_ansible_version: 2.9
  
  platforms:
    - name: EL
      versions:
        - 7
        - 8
        - 9
    - name: Ubuntu
      versions:
        - 18.04
        - 20.04
        - 22.04
  
  galaxy_tags:
    - web
    - apache
    - httpd
    - webserver

dependencies: []
  # List role dependencies here
  # Example:
  # - role: common
  # - role: firewall
EOF
Task 6: Include Roles in Playbooks
Subtask 6.1: Create a Simple Playbook Using the Role
Create a basic playbook that uses our custom role:
cat > deploy-webserver.yml << 'EOF'
---
- name: Deploy Apache Web Server using Custom Role
  hosts: web_servers
  become: yes
  
  roles:
    - apache-webserver
EOF
Subtask 6.2: Create an Advanced Playbook with Role Variables
Create a more advanced playbook with custom variables:
cat > deploy-webserver-advanced.yml << 'EOF'
---
- name: Deploy Apache Web Server with Custom Configuration
  hosts: web_servers
  become: yes
  
  vars:
    # Override default role variables
    welcome_message: "Welcome to Al Nafi Production Web Server!"
    company_name: "Al Nafi Technology Solutions"
    server_admin: "webmaster@alnafi.com"
    site_name: "production-site"
    
  roles:
    - role: apache-webserver
      vars:
        # Role-specific variable overrides
        apache_port: 80
        max_connections: 200
        timeout: 600
EOF
Subtask 6.3: Create Inventory File
Create an inventory file for your managed nodes:
cat > inventory.ini << 'EOF'
[web_servers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[web_servers:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Note: Replace the IP addresses with your actual managed node IPs provided in your lab environment.

Task 7: Execute and Test the Role-Based Playbook
Subtask 7.1: Run the Basic Playbook
Execute the basic playbook:
ansible-playbook -i inventory.ini deploy-webserver.yml
Verify the playbook execution and check for any errors.
Subtask 7.2: Run the Advanced Playbook
Execute the advanced playbook with custom variables:
ansible-playbook -i inventory.ini deploy-webserver-advanced.yml
Subtask 7.3: Verify Web Server Installation
Test the web server on both managed nodes:
# Test from control node
curl http://192.168.1.10
curl http://192.168.1.11
Check Apache service status on managed nodes:
ansible web_servers -i inventory.ini -m service -a "name=httpd state=started" --become
Verify Apache configuration:
ansible web_servers -i inventory.ini -m shell -a "httpd -t" --become
Task 8: Create Multiple Roles and Dependencies
Subtask 8.1: Create a Common Role
Create a common role for basic system setup:
mkdir -p roles/common/{tasks,handlers,defaults}

cat > roles/common/tasks/main.yml << 'EOF'
---
# Common system setup tasks

- name: Update system packages
  package:
    name: '*'
    state: latest
  become: yes

- name: Install common packages
  package:
    name:
      - wget
      - curl
      - vim
      - htop
    state: present
  become: yes

- name: Set timezone
  timezone:
    name: "{{ system_timezone }}"
  become: yes
EOF

cat > roles/common/defaults/main.yml << 'EOF'
---
system_timezone: "America/New_York"
EOF
Subtask 8.2: Create a Playbook with Multiple Roles
Create a comprehensive playbook using multiple roles:
cat > site.yml << 'EOF'
---
- name: Complete Web Server Deployment
  hosts: web_servers
  become: yes
  
  roles:
    - common
    - apache-webserver
  
  post_tasks:
    - name: Display deployment completion message
      debug:
        msg: "Web server deployment completed successfully on {{ inventory_hostname }}"
EOF
Subtask 8.3: Execute the Multi-Role Playbook
Run the comprehensive playbook:
ansible-playbook -i inventory.ini site.yml
Task 9: Role Testing and Validation
Subtask 9.1: Create a Validation Playbook
Create a playbook to validate the role deployment:
cat > validate-deployment.yml << 'EOF'
---
- name: Validate Apache Web Server Deployment
  hosts: web_servers
  
  tasks:
    - name: Check if Apache is running
      service_facts:
      
    - name: Verify Apache service status
      assert:
        that:
          - ansible_facts.services['httpd.service'].state == 'running'
        fail_msg: "Apache service is not running"
        success_msg: "Apache service is running successfully"
    
    - name: Test HTTP response
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      delegate_to: localhost
      
    - name: Check if custom index.html exists
      stat:
        path: /var/www/html/index.html
      register: index_file
      
    - name: Verify index.html was created
      assert:
        that:
          - index_file.stat.exists
        fail_msg: "Custom index.html file not found"
        success_msg: "Custom index.html file exists"
EOF
Run the validation playbook:
ansible-playbook -i inventory.ini validate-deployment.yml
Subtask 9.2: Create Role Documentation
Create a README file for the role:
cat > roles/apache-webserver/README.md << 'EOF'
# Apache Web Server Role

This Ansible role installs and configures Apache HTTP Server on RHEL/CentOS systems.

## Requirements

- Ansible 2.9 or higher
- Target systems running RHEL/CentOS 7, 8, or 9

## Role Variables

### Default Variables (defaults/main.yml)
- `apache_package_name`: Package name for Apache (default: httpd)
- `apache_service_name`: Service name for Apache (default: httpd)
- `document_root`: Web document root (default: /var/www/html)
- `welcome_message`: Welcome message for index page
- `company_name`: Company name displayed on web page

### Role Variables (vars/main.yml)
- `apache_port`: Port number for Apache (default: 80)
- `max_connections`: Maximum connections (default: 100)
- `timeout`: Connection timeout (default: 300)

## Dependencies

None

## Example Playbook

```yaml
- hosts: web_servers
  roles:
    - apache-webserver
License
MIT

Author Information
Created by Al Nafi Learning Lab for educational purposes. EOF


## Troubleshooting Common Issues

### Issue 1: Role Not Found Error

If you encounter "role not found" errors:

1. Verify the role directory structure:
```bash
ls -la roles/apache-webserver/
Check that the role name in the playbook matches the directory name exactly.
Issue 2: Template Rendering Errors
If templates fail to render:

Check template syntax:
ansible-playbook --syntax-check deploy-webserver.yml
Verify all variables are defined in defaults or vars files.
Issue 3: Permission Denied Errors
If you encounter permission errors:

Ensure become: yes is set in tasks that require root privileges
Verify SSH key authentication is working:
ansible web_servers -i inventory.ini -m ping
Issue 4: Firewall Blocking HTTP Traffic
If web pages are not accessible:

Check firewall status:
ansible web_servers -i inventory.ini -m shell -a "firewall-cmd --list-services" --become
Manually open HTTP port if needed:
ansible web_servers -i inventory.ini -m firewalld -a "service=http permanent=yes state=enabled immediate=yes" --become
Conclusion
Congratulations! You have successfully completed Lab 9: Using Roles in Playbooks. In this comprehensive lab, you have accomplished the following:

Key Achievements
• Created a Custom Role: Built a complete Apache web server role with proper directory structure and organization • Implemented Role Components: Developed tasks, handlers, templates, variables, and metadata files • Applied Best Practices: Organized code using Ansible role conventions and standards • Used Templates: Created dynamic configuration files using Jinja2 templating • Managed Variables: Implemented variable precedence with defaults and role-specific variables • Created Reusable Code: Built modular, reusable automation components • Tested Deployments: Validated role functionality through comprehensive testing

Why This Matters
Ansible roles are fundamental to creating maintainable, scalable automation solutions. The skills you've developed in this lab are essential for:

• Enterprise Automation: Large organizations rely on roles for consistent, repeatable deployments • Code Reusability: Roles can be shared across projects and teams, reducing duplication • Maintainability: Well-structured roles are easier to update and troubleshoot • Collaboration: Teams can work on different roles simultaneously without conflicts • Certification Preparation: Role creation and management are key topics in Red Hat Ansible certifications

Next Steps
To further enhance your Ansible skills:

• Explore Ansible Galaxy for community roles • Practice creating roles for different services (databases, monitoring tools) • Learn about role dependencies and complex role relationships • Study advanced templating techniques and filters • Investigate role testing frameworks like Molecule

You now have the foundation to create professional-grade Ansible automation using roles, making your infrastructure management more efficient and reliable.
