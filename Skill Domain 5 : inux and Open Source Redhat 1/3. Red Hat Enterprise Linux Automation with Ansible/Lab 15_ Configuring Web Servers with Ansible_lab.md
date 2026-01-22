Lab 15: Configuring Web Servers with Ansible
Objectives
By the end of this lab, you will be able to:

• Understand the fundamentals of Ansible automation for web server configuration • Write and execute Ansible playbooks to install and configure Apache web server • Ensure web services are properly enabled and running using Ansible • Deploy custom HTML content to web servers using automation • Implement best practices for infrastructure as code using Ansible • Troubleshoot common issues in Ansible playbook execution

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Linux command line operations • Familiarity with YAML syntax and structure • Basic knowledge of web servers and HTTP protocol • Understanding of SSH key-based authentication • Access to a text editor (nano, vim, or similar)

Note: Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click "Start Lab" to access your pre-configured environment - no need to build your own virtual machines.

Lab Environment Setup
Your lab environment includes: • Control Node: CentOS/RHEL 8 machine with Ansible pre-installed • Managed Nodes: Two CentOS/RHEL 8 machines that will serve as web servers • SSH connectivity pre-configured between all machines • Sudo privileges on all systems

Task 1: Setting Up Ansible Inventory and Basic Configuration
Subtask 1.1: Verify Ansible Installation
First, let's confirm that Ansible is properly installed on your control node.

# Check Ansible version
ansible --version

# Verify Ansible configuration
ansible-config view
Subtask 1.2: Create Project Directory Structure
Create a well-organized directory structure for your Ansible project.

# Create main project directory
mkdir ~/ansible-webserver-lab
cd ~/ansible-webserver-lab

# Create subdirectories for organization
mkdir playbooks
mkdir inventory
mkdir templates
mkdir files
Subtask 1.3: Configure Ansible Inventory
Create an inventory file to define your managed nodes.

# Create inventory file
nano inventory/hosts.ini
Add the following content to the inventory file:

[webservers]
web1 ansible_host=192.168.1.10 ansible_user=ec2-user
web2 ansible_host=192.168.1.11 ansible_user=ec2-user

[webservers:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
Note: Replace the IP addresses with the actual IP addresses of your managed nodes provided in your lab environment.

Subtask 1.4: Test Connectivity
Verify that Ansible can connect to your managed nodes.

# Test connectivity to all hosts
ansible -i inventory/hosts.ini all -m ping

# Test with specific group
ansible -i inventory/hosts.ini webservers -m ping
Expected output should show successful pings to all managed nodes.

Task 2: Writing Playbooks to Install and Configure Apache
Subtask 2.1: Create Basic Apache Installation Playbook
Create your first playbook to install Apache web server.

# Create the main playbook file
nano playbooks/install-apache.yml
Add the following content:

---
- name: Install and Configure Apache Web Server
  hosts: webservers
  become: yes
  vars:
    apache_package: httpd
    apache_service: httpd
    document_root: /var/www/html
    
  tasks:
    - name: Update system packages
      yum:
        name: '*'
        state: latest
        update_cache: yes
      tags: update

    - name: Install Apache web server
      yum:
        name: "{{ apache_package }}"
        state: present
      tags: install

    - name: Install additional packages
      yum:
        name:
          - wget
          - curl
          - vim
        state: present
      tags: install
Subtask 2.2: Add Apache Configuration Tasks
Extend the playbook to include Apache configuration.

# Edit the existing playbook
nano playbooks/install-apache.yml
Add these additional tasks to the existing playbook:

    - name: Create custom Apache configuration
      copy:
        content: |
          ServerRoot /etc/httpd
          Listen 80
          Include conf.modules.d/*.conf
          User apache
          Group apache
          ServerAdmin webmaster@localhost
          DocumentRoot {{ document_root }}
          
          <Directory "{{ document_root }}">
              AllowOverride None
              Require all granted
          </Directory>
          
          ErrorLog logs/error_log
          CustomLog logs/access_log combined
        dest: /etc/httpd/conf/httpd.conf
        backup: yes
      notify: restart apache
      tags: configure

    - name: Set proper permissions on document root
      file:
        path: "{{ document_root }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
      tags: configure

    - name: Configure firewall for HTTP traffic
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      tags: firewall
Subtask 2.3: Add Handlers for Service Management
Add handlers to manage the Apache service properly.

Add this section at the end of your playbook:

  handlers:
    - name: restart apache
      systemd:
        name: "{{ apache_service }}"
        state: restarted
        enabled: yes

    - name: reload apache
      systemd:
        name: "{{ apache_service }}"
        state: reloaded
Task 3: Ensuring Services are Enabled and Running
Subtask 3.1: Add Service Management Tasks
Add service management tasks to your playbook:

    - name: Start and enable Apache service
      systemd:
        name: "{{ apache_service }}"
        state: started
        enabled: yes
      tags: service

    - name: Verify Apache is running
      systemd:
        name: "{{ apache_service }}"
        state: started
      register: apache_status
      tags: verify

    - name: Display Apache service status
      debug:
        msg: "Apache service is {{ apache_status.status.ActiveState }}"
      tags: verify

    - name: Check if Apache is listening on port 80
      wait_for:
        port: 80
        host: "{{ ansible_default_ipv4.address }}"
        timeout: 30
      tags: verify
Subtask 3.2: Execute the Playbook
Run your playbook to install and configure Apache:

# Execute the playbook
ansible-playbook -i inventory/hosts.ini playbooks/install-apache.yml

# Run with specific tags if needed
ansible-playbook -i inventory/hosts.ini playbooks/install-apache.yml --tags "install,configure"

# Run in check mode first (dry run)
ansible-playbook -i inventory/hosts.ini playbooks/install-apache.yml --check
Task 4: Deploying a Sample HTML Page
Subtask 4.1: Create HTML Template
Create a dynamic HTML template for your web page:

# Create HTML template
nano templates/index.html.j2
Add the following content:

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to {{ inventory_hostname }}</title>
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
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to {{ inventory_hostname }}</h1>
        <div class="info">
            <h3>Server Information:</h3>
            <p><strong>Hostname:</strong> {{ inventory_hostname }}</p>
            <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
            <p><strong>Operating System:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
            <p><strong>Deployment Time:</strong> {{ ansible_date_time.iso8601 }}</p>
        </div>
        <p>This web server was configured automatically using Ansible!</p>
        <div class="footer">
            <p>Powered by Apache HTTP Server</p>
        </div>
    </div>
</body>
</html>
Subtask 4.2: Create Static Files
Create additional static files for your website:

# Create a CSS file
nano files/style.css
Add the following CSS content:

/* Additional styles for the website */
.highlight {
    background-color: #ffeb3b;
    padding: 2px 4px;
    border-radius: 3px;
}

.success {
    color: #4caf50;
    font-weight: bold;
}

.button {
    background-color: #2196F3;
    color: white;
    padding: 10px 20px;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    text-decoration: none;
    display: inline-block;
    margin: 10px 0;
}

.button:hover {
    background-color: #1976D2;
}
Subtask 4.3: Create Web Content Deployment Playbook
Create a separate playbook for deploying web content:

# Create web content deployment playbook
nano playbooks/deploy-website.yml
Add the following content:

---
- name: Deploy Website Content
  hosts: webservers
  become: yes
  vars:
    document_root: /var/www/html
    
  tasks:
    - name: Deploy main HTML page from template
      template:
        src: ../templates/index.html.j2
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      notify: reload apache
      tags: deploy

    - name: Deploy CSS file
      copy:
        src: ../files/style.css
        dest: "{{ document_root }}/style.css"
        owner: apache
        group: apache
        mode: '0644'
      tags: deploy

    - name: Create images directory
      file:
        path: "{{ document_root }}/images"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
      tags: deploy

    - name: Deploy additional HTML pages
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>About - {{ inventory_hostname }}</title>
              <link rel="stylesheet" href="style.css">
          </head>
          <body>
              <div class="container">
                  <h1>About This Server</h1>
                  <p>This is the about page for {{ inventory_hostname }}</p>
                  <p><a href="index.html" class="button">Back to Home</a></p>
              </div>
          </body>
          </html>
        dest: "{{ document_root }}/about.html"
        owner: apache
        group: apache
        mode: '0644'
      tags: deploy

    - name: Verify web content deployment
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      register: web_check
      tags: verify

    - name: Display web check results
      debug:
        msg: "Website is accessible. Status: {{ web_check.status }}"
      tags: verify

  handlers:
    - name: reload apache
      systemd:
        name: httpd
        state: reloaded
Subtask 4.4: Execute Website Deployment
Deploy your website content:

# Deploy website content
ansible-playbook -i inventory/hosts.ini playbooks/deploy-website.yml

# Verify deployment with verbose output
ansible-playbook -i inventory/hosts.ini playbooks/deploy-website.yml -v --tags verify
Task 5: Creating a Complete Deployment Playbook
Subtask 5.1: Create Master Playbook
Create a comprehensive playbook that combines all tasks:

# Create master playbook
nano playbooks/complete-webserver-setup.yml
Add the following content:

---
- name: Complete Web Server Setup and Configuration
  hosts: webservers
  become: yes
  vars:
    apache_package: httpd
    apache_service: httpd
    document_root: /var/www/html
    
  pre_tasks:
    - name: Gather system facts
      setup:
      tags: always

  tasks:
    # System preparation
    - name: Update system packages
      yum:
        name: '*'
        state: latest
        update_cache: yes
      tags: [update, system]

    # Apache installation
    - name: Install Apache and dependencies
      yum:
        name:
          - "{{ apache_package }}"
          - wget
          - curl
          - vim
          - firewalld
        state: present
      tags: [install, apache]

    # Apache configuration
    - name: Configure Apache main configuration
      template:
        src: ../templates/httpd.conf.j2
        dest: /etc/httpd/conf/httpd.conf
        backup: yes
        owner: root
        group: root
        mode: '0644'
      notify: restart apache
      tags: [configure, apache]

    # Service management
    - name: Start and enable Apache service
      systemd:
        name: "{{ apache_service }}"
        state: started
        enabled: yes
      tags: [service, apache]

    # Firewall configuration
    - name: Start and enable firewalld
      systemd:
        name: firewalld
        state: started
        enabled: yes
      tags: [firewall, service]

    - name: Configure firewall for HTTP
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      tags: [firewall, apache]

    # Web content deployment
    - name: Deploy website content
      include_tasks: deploy-content.yml
      tags: [deploy, content]

    # Verification
    - name: Verify Apache is running
      systemd:
        name: "{{ apache_service }}"
        state: started
      register: apache_status
      tags: [verify, service]

    - name: Test web server response
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      register: web_response
      tags: [verify, web]

    - name: Display deployment summary
      debug:
        msg: |
          Deployment Summary:
          - Apache Status: {{ apache_status.status.ActiveState }}
          - Web Response: {{ web_response.status }}
          - Server URL: http://{{ ansible_default_ipv4.address }}
      tags: [verify, summary]

  handlers:
    - name: restart apache
      systemd:
        name: "{{ apache_service }}"
        state: restarted

    - name: reload apache
      systemd:
        name: "{{ apache_service }}"
        state: reloaded
Subtask 5.2: Create Apache Configuration Template
Create a proper Apache configuration template:

# Create Apache configuration template
nano templates/httpd.conf.j2
Add the following content:

ServerRoot /etc/httpd
Listen 80

Include conf.modules.d/*.conf

User apache
Group apache

ServerAdmin webmaster@{{ inventory_hostname }}
ServerName {{ inventory_hostname }}:80

DocumentRoot {{ document_root }}

<Directory />
    AllowOverride none
    Require all denied
</Directory>

<Directory "{{ document_root }}">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog logs/error_log
LogLevel warn

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
    
    <IfModule logio_module>
        LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>
    
    CustomLog logs/access_log combined
</IfModule>

<IfModule mime_module>
    TypesConfig /etc/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>

AddDefaultCharset UTF-8

<IfModule mime_magic_module>
    MIMEMagicFile conf/magic
</IfModule>

EnableSendfile on

IncludeOptional conf.d/*.conf
Subtask 5.3: Create Content Deployment Tasks
Create a separate task file for content deployment:

# Create content deployment tasks
nano playbooks/deploy-content.yml
Add the following content:

---
- name: Create document root directory
  file:
    path: "{{ document_root }}"
    state: directory
    owner: apache
    group: apache
    mode: '0755'

- name: Deploy main HTML page
  template:
    src: ../templates/index.html.j2
    dest: "{{ document_root }}/index.html"
    owner: apache
    group: apache
    mode: '0644'
  notify: reload apache

- name: Deploy CSS file
  copy:
    src: ../files/style.css
    dest: "{{ document_root }}/style.css"
    owner: apache
    group: apache
    mode: '0644'

- name: Deploy about page
  copy:
    content: |
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <title>About - {{ inventory_hostname }}</title>
          <link rel="stylesheet" href="style.css">
      </head>
      <body>
          <div class="container">
              <h1>About {{ inventory_hostname }}</h1>
              <p>This server was configured using Ansible automation.</p>
              <div class="info">
                  <h3>Configuration Details:</h3>
                  <p><strong>Managed by:</strong> Ansible</p>
                  <p><strong>Web Server:</strong> Apache HTTP Server</p>
                  <p><strong>Document Root:</strong> {{ document_root }}</p>
              </div>
              <p><a href="index.html" class="button">Back to Home</a></p>
          </div>
      </body>
      </html>
    dest: "{{ document_root }}/about.html"
    owner: apache
    group: apache
    mode: '0644'
Task 6: Testing and Verification
Subtask 6.1: Execute Complete Deployment
Run the complete deployment playbook:

# Execute complete deployment
ansible-playbook -i inventory/hosts.ini playbooks/complete-webserver-setup.yml

# Run with increased verbosity for troubleshooting
ansible-playbook -i inventory/hosts.ini playbooks/complete-webserver-setup.yml -vv
Subtask 6.2: Verify Web Server Functionality
Test your web servers using various methods:

# Test web server response using Ansible
ansible -i inventory/hosts.ini webservers -m uri -a "url=http://{{ ansible_default_ipv4.address }} method=GET"

# Check Apache service status
ansible -i inventory/hosts.ini webservers -m systemd -a "name=httpd" --become

# Verify listening ports
ansible -i inventory/hosts.ini webservers -m shell -a "netstat -tlnp | grep :80"

# Test from control node
curl http://192.168.1.10  # Replace with actual IP
curl http://192.168.1.11  # Replace with actual IP
Subtask 6.3: Create Verification Playbook
Create a dedicated playbook for testing and verification:

# Create verification playbook
nano playbooks/verify-deployment.yml
Add the following content:

---
- name: Verify Web Server Deployment
  hosts: webservers
  become: yes
  
  tasks:
    - name: Check Apache service status
      systemd:
        name: httpd
      register: apache_service_status
      
    - name: Verify Apache is listening on port 80
      wait_for:
        port: 80
        host: "{{ ansible_default_ipv4.address }}"
        timeout: 10
      register: port_check
      
    - name: Test HTTP response
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      register: http_response
      
    - name: Test about page
      uri:
        url: "http://{{ ansible_default_ipv4.address }}/about.html"
        method: GET
        status_code: 200
      register: about_response
      
    - name: Check CSS file accessibility
      uri:
        url: "http://{{ ansible_default_ipv4.address }}/style.css"
        method: GET
        status_code: 200
      register: css_response
      
    - name: Display verification results
      debug:
        msg: |
          Verification Results for {{ inventory_hostname }}:
          - Apache Service: {{ apache_service_status.status.ActiveState }}
          - Port 80 Status: {{ 'Open' if port_check.elapsed is defined else 'Closed' }}
          - Main Page: {{ 'OK' if http_response.status == 200 else 'Failed' }}
          - About Page: {{ 'OK' if about_response.status == 200 else 'Failed' }}
          - CSS File: {{ 'OK' if css_response.status == 200 else 'Failed' }}
          - Server URL: http://{{ ansible_default_ipv4.address }}
Run the verification playbook:

# Execute verification
ansible-playbook -i inventory/hosts.ini playbooks/verify-deployment.yml
Troubleshooting Common Issues
Issue 1: SSH Connection Problems
If you encounter SSH connection issues:

# Test SSH connectivity manually
ssh -i ~/.ssh/id_rsa ec2-user@192.168.1.10

# Check SSH agent
ssh-add -l

# Add SSH key if needed
ssh-add ~/.ssh/id_rsa
Issue 2: Permission Denied Errors
If you get permission errors:

# Check sudo access
ansible -i inventory/hosts.ini webservers -m shell -a "sudo whoami"

# Verify user permissions in inventory
cat inventory/hosts.ini
Issue 3: Firewall Blocking Connections
If web pages are not accessible:

# Check firewall status
ansible -i inventory/hosts.ini webservers -m shell -a "firewall-cmd --list-all" --become

# Manually open HTTP port if needed
ansible -i inventory/hosts.ini webservers -m firewalld -a "service=http permanent=yes state=enabled immediate=yes" --become
Issue 4: Apache Configuration Errors
If Apache fails to start:

# Check Apache configuration syntax
ansible -i inventory/hosts.ini webservers -m shell -a "httpd -t" --become

# Check Apache error logs
ansible -i inventory/hosts.ini webservers -m shell -a "tail -20 /var/log/httpd/error_log" --become
Best Practices and Tips
Security Considerations
Use SSH Keys: Always use SSH key-based authentication instead of passwords
Limit Sudo Access: Use specific sudo commands rather than full sudo access
Firewall Configuration: Only open necessary ports
Regular Updates: Keep systems updated with security patches
Ansible Best Practices
Use Tags: Tag your tasks for selective execution
Idempotency: Ensure playbooks can be run multiple times safely
Variable Management: Use group_vars and host_vars for better organization
Error Handling: Implement proper error handling and notifications
Documentation: Comment your playbooks and maintain documentation
Performance Optimization
Parallel Execution: Use Ansible's parallel execution capabilities
Fact Caching: Enable fact caching for better performance
Selective Updates: Use tags to run only necessary tasks
Connection Reuse: Configure SSH connection reuse
Conclusion
Congratulations! You have successfully completed Lab 15: Configuring Web Servers with Ansible. In this comprehensive lab, you have accomplished the following:

What You Learned
• Ansible Fundamentals: You gained hands-on experience with Ansible automation, including inventory management, playbook creation, and task execution

• Web Server Automation: You learned how to automate the installation and configuration of Apache web servers using infrastructure as code principles

• Service Management: You implemented proper service management techniques to ensure web services are enabled, running, and properly configured

• Content Deployment: You created dynamic web content using Ansible templates and deployed static files to web servers

• Verification and Testing: You developed comprehensive testing strategies to verify successful deployments and troubleshoot common issues

Key Skills Developed
• Writing YAML-based Ansible playbooks with proper structure and syntax • Managing server configurations using templates and variables • Implementing idempotent automation that can be safely executed multiple times • Using Ansible modules for system administration tasks • Organizing complex automation projects with proper directory structure • Troubleshooting and debugging Ansible playbook execution

Real-World Applications
The skills you've developed in this lab are directly applicable to:

• DevOps Practices: Implementing infrastructure as code in production environments • System Administration: Automating repetitive server configuration tasks • Continuous Deployment: Integrating web server configuration into CI/CD pipelines • Disaster Recovery: Quickly rebuilding web infrastructure using automation • Compliance Management: Ensuring consistent server configurations across environments

Why This Matters
In today's fast-paced IT environment, manual server configuration is time-consuming, error-prone, and doesn't scale effectively. By mastering Ansible automation for web server configuration, you've learned to:

• Reduce deployment time from hours to minutes • Eliminate human errors in server configuration • Ensure consistent environments across development, testing, and production • Enable rapid scaling of web infrastructure • Maintain detailed documentation of infrastructure changes through code

This lab has provided you with foundational skills that are essential for modern system administration and DevOps practices. The automation techniques you've learned can be extended to manage complex multi-tier applications, database servers, load balancers, and entire cloud infrastructures.

Continue practicing these skills by exploring more advanced Ansible features such as roles, collections, and Ansible Tower/AWX for enterprise automation management.
