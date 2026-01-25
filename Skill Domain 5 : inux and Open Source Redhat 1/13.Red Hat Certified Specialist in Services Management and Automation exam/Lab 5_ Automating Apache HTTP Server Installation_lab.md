Lab 5: Automating Apache HTTP Server Installation
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of Ansible automation for web server deployment
Create and execute Ansible playbooks to install Apache HTTP Server
Configure virtual hosts for multiple websites on a single server
Implement SSL/TLS encryption for secure web communications
Set up custom error pages for better user experience
Deploy and validate Apache configurations using automated testing
Troubleshoot common Apache installation and configuration issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Knowledge of web server concepts (HTTP, HTTPS, virtual hosts)
Understanding of SSH key-based authentication
Basic networking concepts (ports, DNS, certificates)
Required Knowledge Level: Intermediate Linux administration and basic Ansible concepts

Lab Environment Setup
Al Nafi Cloud Machines: This lab uses pre-configured Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your environment. No need to build your own virtual machines.

Environment Details:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Target Nodes: 2 CentOS/RHEL 8 servers for Apache deployment
Network: All machines configured with SSH key authentication
Tools: Ansible 4.x, OpenSSL, curl, and text editors available
Task 1: Setting Up Ansible Environment and Initial Playbook
Subtask 1.1: Verify Ansible Installation and Inventory Setup
First, let's verify that Ansible is properly installed and configure our inventory file.

Connect to your control node and verify Ansible installation:
ansible --version
Create the project directory structure:
mkdir -p ~/apache-automation/{playbooks,inventory,templates,files,vars}
cd ~/apache-automation
Create the inventory file to define your target servers:
cat > inventory/hosts.yml << 'EOF'
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 10.0.1.10
          ansible_user: centos
        web2:
          ansible_host: 10.0.1.11
          ansible_user: centos
  vars:
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF
Test connectivity to your target servers:
ansible -i inventory/hosts.yml webservers -m ping
Subtask 1.2: Create Basic Apache Installation Playbook
Create the main Apache installation playbook:
cat > playbooks/apache-install.yml << 'EOF'
---
- name: Install and Configure Apache HTTP Server
  hosts: webservers
  become: yes
  vars:
    apache_service_name: httpd
    apache_config_dir: /etc/httpd
    apache_document_root: /var/www/html
    apache_log_dir: /var/log/httpd
    
  tasks:
    - name: Update system packages
      yum:
        name: '*'
        state: latest
        update_cache: yes
      tags: system_update
      
    - name: Install Apache HTTP Server
      yum:
        name:
          - httpd
          - httpd-tools
          - mod_ssl
        state: present
      tags: apache_install
      
    - name: Install additional packages for SSL
      yum:
        name:
          - openssl
          - python3-cryptography
        state: present
      tags: ssl_packages
      
    - name: Start and enable Apache service
      systemd:
        name: "{{ apache_service_name }}"
        state: started
        enabled: yes
      tags: apache_service
      
    - name: Configure firewall for HTTP and HTTPS
      firewalld:
        service: "{{ item }}"
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - http
        - https
      tags: firewall
      
    - name: Create basic index.html
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Apache Server - {{ inventory_hostname }}</title>
          </head>
          <body>
              <h1>Welcome to {{ inventory_hostname }}</h1>
              <p>Apache HTTP Server is running successfully!</p>
              <p>Server Time: {{ ansible_date_time.iso8601 }}</p>
          </body>
          </html>
        dest: "{{ apache_document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      tags: default_page
EOF
Execute the basic installation playbook:
ansible-playbook -i inventory/hosts.yml playbooks/apache-install.yml
Verify the installation by testing HTTP access:
# Test from control node
curl -I http://10.0.1.10
curl -I http://10.0.1.11
Task 2: Configuring Virtual Hosts
Subtask 2.1: Create Virtual Host Configuration Templates
Create a template directory and virtual host template:
cat > templates/vhost.conf.j2 << 'EOF'
<VirtualHost *:80>
    ServerName {{ item.server_name }}
    {% if item.server_alias is defined %}
    ServerAlias {{ item.server_alias }}
    {% endif %}
    DocumentRoot {{ item.document_root }}
    
    <Directory "{{ item.document_root }}">
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog {{ apache_log_dir }}/{{ item.server_name }}_error.log
    CustomLog {{ apache_log_dir }}/{{ item.server_name }}_access.log combined
    
    {% if item.redirect_to_https is defined and item.redirect_to_https %}
    # Redirect all HTTP traffic to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
    {% endif %}
</VirtualHost>

{% if item.ssl_enabled is defined and item.ssl_enabled %}
<VirtualHost *:443>
    ServerName {{ item.server_name }}
    {% if item.server_alias is defined %}
    ServerAlias {{ item.server_alias }}
    {% endif %}
    DocumentRoot {{ item.document_root }}
    
    <Directory "{{ item.document_root }}">
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog {{ apache_log_dir }}/{{ item.server_name }}_ssl_error.log
    CustomLog {{ apache_log_dir }}/{{ item.server_name }}_ssl_access.log combined
    
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile {{ item.ssl_cert_path }}
    SSLCertificateKeyFile {{ item.ssl_key_path }}
    
    # Modern SSL configuration
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder off
    SSLSessionTickets off
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
</VirtualHost>
{% endif %}
EOF
Create variables file for virtual hosts:
cat > vars/vhosts.yml << 'EOF'
virtual_hosts:
  - server_name: "example1.local"
    server_alias: "www.example1.local"
    document_root: "/var/www/example1"
    ssl_enabled: true
    ssl_cert_path: "/etc/ssl/certs/example1.crt"
    ssl_key_path: "/etc/ssl/private/example1.key"
    redirect_to_https: true
    
  - server_name: "example2.local"
    server_alias: "www.example2.local"
    document_root: "/var/www/example2"
    ssl_enabled: true
    ssl_cert_path: "/etc/ssl/certs/example2.crt"
    ssl_key_path: "/etc/ssl/private/example2.key"
    redirect_to_https: true
    
  - server_name: "test.local"
    document_root: "/var/www/test"
    ssl_enabled: false
EOF
Subtask 2.2: Create Virtual Host Configuration Playbook
Create the virtual hosts playbook:
cat > playbooks/configure-vhosts.yml << 'EOF'
---
- name: Configure Apache Virtual Hosts
  hosts: webservers
  become: yes
  vars_files:
    - ../vars/vhosts.yml
  vars:
    apache_service_name: httpd
    apache_config_dir: /etc/httpd
    apache_log_dir: /var/log/httpd
    
  tasks:
    - name: Create document root directories
      file:
        path: "{{ item.document_root }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
      loop: "{{ virtual_hosts }}"
      tags: document_roots
      
    - name: Create SSL certificate directories
      file:
        path: "{{ item }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
      loop:
        - /etc/ssl/certs
        - /etc/ssl/private
      tags: ssl_dirs
      
    - name: Generate self-signed SSL certificates
      block:
        - name: Generate private keys
          openssl_privatekey:
            path: "{{ item.ssl_key_path }}"
            size: 2048
            owner: root
            group: root
            mode: '0600'
          loop: "{{ virtual_hosts }}"
          when: item.ssl_enabled is defined and item.ssl_enabled
          tags: ssl_keys
          
        - name: Generate certificate signing requests
          openssl_csr:
            path: "/tmp/{{ item.server_name }}.csr"
            privatekey_path: "{{ item.ssl_key_path }}"
            common_name: "{{ item.server_name }}"
            subject_alt_name:
              - "DNS:{{ item.server_name }}"
              - "DNS:{{ item.server_alias | default('') }}"
          loop: "{{ virtual_hosts }}"
          when: item.ssl_enabled is defined and item.ssl_enabled
          tags: ssl_csr
          
        - name: Generate self-signed certificates
          openssl_certificate:
            path: "{{ item.ssl_cert_path }}"
            privatekey_path: "{{ item.ssl_key_path }}"
            csr_path: "/tmp/{{ item.server_name }}.csr"
            provider: selfsigned
            owner: root
            group: root
            mode: '0644'
          loop: "{{ virtual_hosts }}"
          when: item.ssl_enabled is defined and item.ssl_enabled
          tags: ssl_certs
      tags: ssl_generation
      
    - name: Create virtual host configuration files
      template:
        src: ../templates/vhost.conf.j2
        dest: "{{ apache_config_dir }}/conf.d/{{ item.server_name }}.conf"
        owner: root
        group: root
        mode: '0644'
        backup: yes
      loop: "{{ virtual_hosts }}"
      notify: restart apache
      tags: vhost_config
      
    - name: Create sample content for each virtual host
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>{{ item.server_name }} - Virtual Host</title>
              <style>
                  body { font-family: Arial, sans-serif; margin: 40px; }
                  .header { background-color: #f4f4f4; padding: 20px; border-radius: 5px; }
                  .content { margin-top: 20px; }
              </style>
          </head>
          <body>
              <div class="header">
                  <h1>Welcome to {{ item.server_name }}</h1>
                  <p>Virtual Host Configuration Successful</p>
              </div>
              <div class="content">
                  <h2>Server Information</h2>
                  <ul>
                      <li><strong>Server Name:</strong> {{ item.server_name }}</li>
                      <li><strong>Document Root:</strong> {{ item.document_root }}</li>
                      <li><strong>SSL Enabled:</strong> {{ item.ssl_enabled | default('false') }}</li>
                      <li><strong>Server:</strong> {{ inventory_hostname }}</li>
                  </ul>
              </div>
          </body>
          </html>
        dest: "{{ item.document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      loop: "{{ virtual_hosts }}"
      tags: sample_content
      
  handlers:
    - name: restart apache
      systemd:
        name: "{{ apache_service_name }}"
        state: restarted
EOF
Execute the virtual hosts configuration:
ansible-playbook -i inventory/hosts.yml playbooks/configure-vhosts.yml
Task 3: Implementing SSL/TLS Encryption and Error Pages
Subtask 3.1: Configure Advanced SSL Settings
Create SSL security configuration template:
cat > templates/ssl-security.conf.j2 << 'EOF'
# Modern SSL Configuration
# Generated by Ansible - Do not edit manually

# Disable SSL v2 and v3, enable only TLS
SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1

# Use server cipher order
SSLHonorCipherOrder off

# Modern cipher suite
SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384

# Disable session tickets
SSLSessionTickets off

# OCSP Stapling
SSLUseStapling on
SSLStaplingResponderTimeout 5
SSLStaplingReturnResponderErrors off
SSLStaplingCache shmcb:/var/run/ocsp(128000)

# Security headers
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set X-Frame-Options DENY
Header always set X-Content-Type-Options nosniff
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
EOF
Subtask 3.2: Create Custom Error Pages
Create error page templates:
mkdir -p templates/error-pages

cat > templates/error-pages/404.html.j2 << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Page Not Found</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .error-container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        .error-code {
            font-size: 120px;
            font-weight: bold;
            margin: 0;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .error-message {
            font-size: 24px;
            margin: 20px 0;
        }
        .error-description {
            font-size: 16px;
            margin: 20px 0;
            opacity: 0.8;
        }
        .back-button {
            display: inline-block;
            padding: 12px 24px;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            text-decoration: none;
            border-radius: 25px;
            margin-top: 20px;
            transition: background 0.3s ease;
        }
        .back-button:hover {
            background: rgba(255, 255, 255, 0.3);
        }
    </style>
</head>
<body>
    <div class="error-container">
        <h1 class="error-code">404</h1>
        <h2 class="error-message">Page Not Found</h2>
        <p class="error-description">
            The page you are looking for might have been removed, 
            had its name changed, or is temporarily unavailable.
        </p>
        <a href="/" class="back-button">Go Back Home</a>
        <p style="margin-top: 30px; font-size: 12px; opacity: 0.6;">
            Server: {{ inventory_hostname }}
        </p>
    </div>
</body>
</html>
EOF

cat > templates/error-pages/500.html.j2 << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>500 - Internal Server Error</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .error-container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        .error-code {
            font-size: 120px;
            font-weight: bold;
            margin: 0;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .error-message {
            font-size: 24px;
            margin: 20px 0;
        }
        .error-description {
            font-size: 16px;
            margin: 20px 0;
            opacity: 0.8;
        }
        .back-button {
            display: inline-block;
            padding: 12px 24px;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            text-decoration: none;
            border-radius: 25px;
            margin-top: 20px;
            transition: background 0.3s ease;
        }
        .back-button:hover {
            background: rgba(255, 255, 255, 0.3);
        }
    </style>
</head>
<body>
    <div class="error-container">
        <h1 class="error-code">500</h1>
        <h2 class="error-message">Internal Server Error</h2>
        <p class="error-description">
            Something went wrong on our end. We're working to fix this issue.
            Please try again later.
        </p>
        <a href="/" class="back-button">Go Back Home</a>
        <p style="margin-top: 30px; font-size: 12px; opacity: 0.6;">
            Server: {{ inventory_hostname }}
        </p>
    </div>
</body>
</html>
EOF
Subtask 3.3: Create Complete SSL and Error Pages Configuration Playbook
Create the comprehensive configuration playbook:
cat > playbooks/ssl-and-errors.yml << 'EOF'
---
- name: Configure SSL Security and Custom Error Pages
  hosts: webservers
  become: yes
  vars:
    apache_service_name: httpd
    apache_config_dir: /etc/httpd
    apache_document_root: /var/www/html
    error_pages_dir: /var/www/error-pages
    
  tasks:
    - name: Install mod_headers for security headers
      yum:
        name: 
          - mod_headers
        state: present
      tags: headers_module
      
    - name: Create error pages directory
      file:
        path: "{{ error_pages_dir }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
      tags: error_dirs
      
    - name: Deploy custom error pages
      template:
        src: "../templates/error-pages/{{ item }}.html.j2"
        dest: "{{ error_pages_dir }}/{{ item }}.html"
        owner: apache
        group: apache
        mode: '0644'
      loop:
        - '404'
        - '500'
      tags: error_pages
      
    - name: Configure SSL security settings
      template:
        src: ../templates/ssl-security.conf.j2
        dest: "{{ apache_config_dir }}/conf.d/ssl-security.conf"
        owner: root
        group: root
        mode: '0644'
        backup: yes
      notify: restart apache
      tags: ssl_security
      
    - name: Configure global error pages
      blockinfile:
        path: "{{ apache_config_dir }}/conf/httpd.conf"
        block: |
          # Custom Error Pages
          ErrorDocument 404 /error-pages/404.html
          ErrorDocument 500 /error-pages/500.html
          
          # Alias for error pages
          Alias /error-pages "{{ error_pages_dir }}"
          
          <Directory "{{ error_pages_dir }}">
              AllowOverride None
              Require all granted
          </Directory>
        marker: "# {mark} ANSIBLE MANAGED BLOCK - Error Pages"
        backup: yes
      notify: restart apache
      tags: error_config
      
    - name: Enable required Apache modules
      apache2_module:
        name: "{{ item }}"
        state: present
      loop:
        - rewrite
        - headers
        - ssl
      notify: restart apache
      tags: apache_modules
      ignore_errors: yes
      
    - name: Alternative method - Enable modules via configuration
      lineinfile:
        path: "{{ apache_config_dir }}/conf/httpd.conf"
        line: "LoadModule {{ item.module }} modules/{{ item.file }}"
        state: present
        backup: yes
      loop:
        - { module: "rewrite_module", file: "mod_rewrite.so" }
        - { module: "headers_module", file: "mod_headers.so" }
        - { module: "ssl_module", file: "mod_ssl.so" }
      notify: restart apache
      tags: enable_modules
      
    - name: Test Apache configuration
      command: httpd -t
      register: apache_config_test
      changed_when: false
      tags: config_test
      
    - name: Display configuration test results
      debug:
        var: apache_config_test.stdout_lines
      tags: config_test
      
  handlers:
    - name: restart apache
      systemd:
        name: "{{ apache_service_name }}"
        state: restarted
EOF
Execute the SSL and error pages configuration:
ansible-playbook -i inventory/hosts.yml playbooks/ssl-and-errors.yml
Task 4: Deploy and Test Apache Installation and Configuration
Subtask 4.1: Create Comprehensive Testing Playbook
Create a testing and validation playbook:
cat > playbooks/test-apache.yml << 'EOF'
---
- name: Test Apache HTTP Server Installation and Configuration
  hosts: webservers
  become: yes
  vars_files:
    - ../vars/vhosts.yml
  vars:
    apache_service_name: httpd
    test_results: []
    
  tasks:
    - name: Check Apache service status
      systemd:
        name: "{{ apache_service_name }}"
      register: apache_status
      tags: service_check
      
    - name: Display Apache service status
      debug:
        msg: |
          Apache Service Status:
          - Active: {{ apache_status.status.ActiveState }}
          - Loaded: {{ apache_status.status.LoadState }}
          - Running: {{ apache_status.status.SubState }}
      tags: service_check
      
    - name: Check if Apache is listening on ports 80 and 443
      wait_for:
        port: "{{ item }}"
        host: "{{ ansible_default_ipv4.address }}"
        timeout: 10
      loop:
        - 80
        - 443
      register: port_check
      tags: port_check
      
    - name: Test HTTP connectivity to default site
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      register: http_test
      tags: http_test
      
    - name: Test virtual hosts HTTP connectivity
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        headers:
          Host: "{{ item.server_name }}"
        status_code: [200, 301, 302]
      loop: "{{ virtual_hosts }}"
      register: vhost_http_test
      tags: vhost_test
      
    - name: Test HTTPS connectivity for SSL-enabled virtual hosts
      uri:
        url: "https://{{ ansible_default_ipv4.address }}"
        method: GET
        headers:
          Host: "{{ item.server_name }}"
        validate_certs: no
        status_code: 200
      loop: "{{ virtual_hosts }}"
      when: item.ssl_enabled is defined and item.ssl_enabled
      register: vhost_https_test
      tags: https_test
      
    - name: Test custom error pages
      uri:
        url: "http://{{ ansible_default_ipv4.address }}/nonexistent-page"
        method: GET
        status_code: 404
      register: error_page_test
      tags: error_test
      
    - name: Check SSL certificate validity
      openssl_certificate_info:
        path: "{{ item.ssl_cert_path }}"
      loop: "{{ virtual_hosts }}"
      when: item.ssl_enabled is defined and item.ssl_enabled
      register: ssl_cert_info
      tags: ssl_check
      
    - name: Display SSL certificate information
      debug:
        msg: |
          Certificate for {{ item.item.server_name }}:
          - Subject: {{ item.subject }}
          - Issuer: {{ item.issuer }}
          - Valid from: {{ item.not_before }}
          - Valid until: {{ item.not_after }}
          - Serial: {{ item.serial_number }}
      loop: "{{ ssl_cert_info.results }}"
      when: ssl_cert_info is defined and not item.skipped | default(false)
      tags: ssl_check
      
    - name: Check Apache configuration syntax
      command: httpd -t
      register: config_syntax
      changed_when: false
      tags: syntax_check
      
    - name: Display configuration syntax check
      debug:
        msg: |
          Apache Configuration Syntax Check:
          {{ config_syntax.stdout }}
          {{ config_syntax.stderr }}
      tags: syntax_check
      
    - name: Generate test report
      template:
        src: ../templates/test-report.html.j2
        dest: /var/www/html/test-report.html
        owner: apache
        group: apache
        mode: '0644'
      tags: test_report
EOF
Create test report template:
cat > templates/test-report.html.j2 << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Apache Test Report - {{ inventory_hostname }}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .test-section { margin: 20px 0; padding: 15px; border-left: 4px solid #3498db; background: #ecf0f1; }
        .success { border-left-color: #27ae60; background: #d5f4e6; }
        .warning { border-left-color: #f39c12; background: #fef9e7; }
        .error { border-left-color: #e74c3c; background: #fadbd8; }
        .test-item { margin: 10px 0; padding: 10px; background: white; border-radius: 3px; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #34495e; color: white; }
        .status-ok { color: #27ae60; font-weight: bold; }
        .status-error { color: #e74c3c; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Apache HTTP Server Test Report</h1>
            <p><strong>Server:</strong> {{ inventory_hostname }}</p>
            <p><strong>Test Date:</strong> {{ ansible_date_time.iso8601 }}</p>
            <p><strong>Apache Version:</strong> {{ ansible_facts.packages.http
