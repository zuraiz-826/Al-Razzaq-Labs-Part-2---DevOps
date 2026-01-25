Lab 6: Automating Squid Proxy Server Installation
Objectives
By the end of this lab, students will be able to:

Install and configure Squid proxy server using Ansible automation
Create Ansible playbooks for service deployment and configuration
Configure Squid caching policies and access control rules
Test proxy server functionality and verify proper operation
Understand the benefits of using proxy servers in network infrastructure
Apply configuration management principles using Infrastructure as Code
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Knowledge of Ansible fundamentals (playbooks, tasks, modules)
Understanding of networking concepts (IP addresses, ports, HTTP/HTTPS)
Experience with text editors (nano, vim, or similar)
Basic knowledge of proxy server concepts
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or install additional software.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Target Node: CentOS/RHEL 8 for Squid installation
Client Machine: For testing proxy functionality
Task 1: Create a Playbook to Install Squid Proxy Server
Subtask 1.1: Set Up the Ansible Project Structure
First, let's create a proper directory structure for our Ansible project.

Connect to your control node and create the project directory:
mkdir -p ~/squid-proxy-lab
cd ~/squid-proxy-lab
Create the necessary subdirectories:
mkdir -p {playbooks,inventory,templates,vars}
Create the inventory file to define our target hosts:
nano inventory/hosts.yml
Add the following content to the inventory file:
all:
  children:
    proxy_servers:
      hosts:
        squid-server:
          ansible_host: 192.168.1.100
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
Note: Replace 192.168.1.100 with the actual IP address of your target node provided in the lab environment.

Subtask 1.2: Create the Main Squid Installation Playbook
Create the main playbook file:
nano playbooks/install-squid.yml
Add the following comprehensive playbook content:
---
- name: Install and Configure Squid Proxy Server
  hosts: proxy_servers
  become: yes
  vars:
    squid_port: 3128
    squid_cache_dir: /var/spool/squid
    squid_cache_size: 1000
    allowed_networks:
      - 192.168.1.0/24
      - 10.0.0.0/8
    
  tasks:
    - name: Update system packages
      yum:
        name: "*"
        state: latest
        update_cache: yes
      tags: system_update

    - name: Install EPEL repository
      yum:
        name: epel-release
        state: present
      tags: prerequisites

    - name: Install Squid proxy server
      yum:
        name: squid
        state: present
      tags: install_squid

    - name: Install additional utilities
      yum:
        name:
          - wget
          - curl
          - net-tools
        state: present
      tags: utilities

    - name: Create squid cache directory
      file:
        path: "{{ squid_cache_dir }}"
        state: directory
        owner: squid
        group: squid
        mode: '0755'
      tags: cache_setup

    - name: Initialize squid cache directories
      command: squid -z
      args:
        creates: "{{ squid_cache_dir }}/00"
      become_user: squid
      tags: cache_init

    - name: Enable and start squid service
      systemd:
        name: squid
        enabled: yes
        state: started
      tags: service_management

    - name: Configure firewall for squid
      firewalld:
        port: "{{ squid_port }}/tcp"
        permanent: yes
        state: enabled
        immediate: yes
      tags: firewall_config

    - name: Display squid service status
      command: systemctl status squid
      register: squid_status
      tags: verification

    - name: Show squid status
      debug:
        var: squid_status.stdout_lines
      tags: verification
Subtask 1.3: Test the Basic Installation
Run the playbook to install Squid:
cd ~/squid-proxy-lab
ansible-playbook -i inventory/hosts.yml playbooks/install-squid.yml
Verify the installation by checking if Squid is running:
ansible proxy_servers -i inventory/hosts.yml -m command -a "systemctl status squid"
Task 2: Configure Squid Settings for Caching and Access Control
Subtask 2.1: Create Squid Configuration Template
Create a comprehensive Squid configuration template:
nano templates/squid.conf.j2
Add the following configuration template:
# Squid Configuration File - Managed by Ansible
# Generated on {{ ansible_date_time.iso8601 }}

# Network and Port Configuration
http_port {{ squid_port }}

# Cache Directory Configuration
cache_dir ufs {{ squid_cache_dir }} {{ squid_cache_size }} 16 256

# Memory Cache Settings
cache_mem 256 MB
maximum_object_size_in_memory 512 KB
maximum_object_size 1024 MB

# Access Control Lists (ACLs)
acl localnet src 0.0.0.1-0.255.255.255  # RFC 1122 "this" network (LAN)
acl localnet src 10.0.0.0/8             # RFC 1918 local private network (LAN)
acl localnet src 100.64.0.0/10          # RFC 6598 shared address space (CGN)
acl localnet src 169.254.0.0/16         # RFC 3927 link-local (directly plugged machines)
acl localnet src 172.16.0.0/12          # RFC 1918 local private network (LAN)
acl localnet src 192.168.0.0/16         # RFC 1918 local private network (LAN)
acl localnet src fc00::/7               # RFC 4193 local private network range
acl localnet src fe80::/10              # RFC 4291 link-local (directly plugged machines)

# Custom allowed networks
{% for network in allowed_networks %}
acl allowed_nets src {{ network }}
{% endfor %}

# Standard ACLs
acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

# Access Rules
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localnet
http_access allow allowed_nets
http_access allow localhost
http_access deny all

# Cache Management
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320

# Logging Configuration
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log
cache_store_log /var/log/squid/store.log

# Performance Tuning
dns_nameservers 8.8.8.8 8.8.4.4
fqdncache_size 1024
ipcache_size 1024

# Security Headers
request_header_access Referer deny all
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access Cache-Control deny all

# Coredump directory
coredump_dir /var/spool/squid

# Leave coredumps in the first cache dir
coredump_dir {{ squid_cache_dir }}
Subtask 2.2: Create Advanced Configuration Playbook
Create an advanced configuration playbook:
nano playbooks/configure-squid.yml
Add the following configuration playbook:
---
- name: Advanced Squid Proxy Configuration
  hosts: proxy_servers
  become: yes
  vars:
    squid_port: 3128
    squid_cache_dir: /var/spool/squid
    squid_cache_size: 1000
    allowed_networks:
      - 192.168.1.0/24
      - 10.0.0.0/8
    blocked_domains:
      - facebook.com
      - twitter.com
      - youtube.com
    
  tasks:
    - name: Backup original squid configuration
      copy:
        src: /etc/squid/squid.conf
        dest: /etc/squid/squid.conf.backup
        remote_src: yes
        backup: yes
      tags: backup_config

    - name: Deploy custom squid configuration
      template:
        src: ../templates/squid.conf.j2
        dest: /etc/squid/squid.conf
        owner: root
        group: squid
        mode: '0640'
        backup: yes
      notify: restart_squid
      tags: deploy_config

    - name: Create blocked domains ACL file
      template:
        src: ../templates/blocked_domains.j2
        dest: /etc/squid/blocked_domains
        owner: root
        group: squid
        mode: '0644'
      notify: restart_squid
      tags: blocked_domains

    - name: Create squid log rotation configuration
      copy:
        content: |
          /var/log/squid/*.log {
              weekly
              rotate 5
              compress
              notifempty
              missingok
              nocreate
              sharedscripts
              postrotate
                  /usr/bin/systemctl reload squid.service
              endscript
          }
        dest: /etc/logrotate.d/squid
        mode: '0644'
      tags: log_rotation

    - name: Validate squid configuration
      command: squid -k parse
      register: config_check
      failed_when: config_check.rc != 0
      tags: validate_config

    - name: Display configuration validation results
      debug:
        msg: "Squid configuration is valid"
      when: config_check.rc == 0
      tags: validate_config

  handlers:
    - name: restart_squid
      systemd:
        name: squid
        state: restarted
        daemon_reload: yes
Subtask 2.3: Create Blocked Domains Template
Create the blocked domains template:
nano templates/blocked_domains.j2
Add the following content:
# Blocked domains list - Managed by Ansible
{% for domain in blocked_domains %}
{{ domain }}
{% endfor %}
Subtask 2.4: Apply Advanced Configuration
Run the configuration playbook:
ansible-playbook -i inventory/hosts.yml playbooks/configure-squid.yml
Verify the configuration was applied successfully:
ansible proxy_servers -i inventory/hosts.yml -m command -a "squid -k parse"
Task 3: Test Proxy Functionality
Subtask 3.1: Create Proxy Testing Playbook
Create a comprehensive testing playbook:
nano playbooks/test-squid.yml
Add the following testing playbook:
---
- name: Test Squid Proxy Functionality
  hosts: proxy_servers
  become: yes
  vars:
    squid_port: 3128
    test_urls:
      - http://httpbin.org/ip
      - http://www.google.com
      - http://www.example.com
    
  tasks:
    - name: Check squid service status
      systemd:
        name: squid
      register: squid_service
      tags: service_check

    - name: Display squid service status
      debug:
        msg: "Squid service is {{ squid_service.status.ActiveState }}"
      tags: service_check

    - name: Check if squid port is listening
      wait_for:
        port: "{{ squid_port }}"
        host: "{{ ansible_default_ipv4.address }}"
        timeout: 10
      tags: port_check

    - name: Test proxy connectivity from localhost
      uri:
        url: "{{ item }}"
        method: GET
        timeout: 30
      environment:
        http_proxy: "http://127.0.0.1:{{ squid_port }}"
        https_proxy: "http://127.0.0.1:{{ squid_port }}"
      loop: "{{ test_urls }}"
      register: proxy_tests
      ignore_errors: yes
      tags: connectivity_test

    - name: Display proxy test results
      debug:
        msg: "URL: {{ item.item }} - Status: {{ item.status | default('Failed') }}"
      loop: "{{ proxy_tests.results }}"
      tags: test_results

    - name: Check squid access logs
      command: tail -n 20 /var/log/squid/access.log
      register: access_logs
      tags: log_check

    - name: Display recent access log entries
      debug:
        var: access_logs.stdout_lines
      tags: log_check

    - name: Generate proxy statistics
      command: squidclient -h 127.0.0.1 -p {{ squid_port }} mgr:info
      register: squid_stats
      ignore_errors: yes
      tags: statistics

    - name: Display proxy statistics
      debug:
        var: squid_stats.stdout_lines
      when: squid_stats.rc == 0
      tags: statistics
Subtask 3.2: Create Client Testing Script
Create a client-side testing script:
nano playbooks/client-test.yml
Add the following client testing playbook:
---
- name: Client-Side Proxy Testing
  hosts: localhost
  connection: local
  vars:
    proxy_server: "{{ hostvars[groups['proxy_servers'][0]]['ansible_host'] }}"
    proxy_port: 3128
    
  tasks:
    - name: Test direct connection (without proxy)
      uri:
        url: http://httpbin.org/ip
        method: GET
        timeout: 10
      register: direct_connection
      tags: direct_test

    - name: Display direct connection IP
      debug:
        msg: "Direct connection IP: {{ (direct_connection.json.origin | default('Unknown')) }}"
      tags: direct_test

    - name: Test connection through proxy
      uri:
        url: http://httpbin.org/ip
        method: GET
        timeout: 10
      environment:
        http_proxy: "http://{{ proxy_server }}:{{ proxy_port }}"
      register: proxy_connection
      ignore_errors: yes
      tags: proxy_test

    - name: Display proxy connection results
      debug:
        msg: "Proxy connection IP: {{ (proxy_connection.json.origin | default('Connection Failed')) }}"
      when: proxy_connection is succeeded
      tags: proxy_test

    - name: Test proxy with curl command
      command: >
        curl -x {{ proxy_server }}:{{ proxy_port }} 
        -s http://httpbin.org/headers
      register: curl_test
      ignore_errors: yes
      tags: curl_test

    - name: Display curl test results
      debug:
        var: curl_test.stdout
      when: curl_test.rc == 0
      tags: curl_test
Subtask 3.3: Run Comprehensive Tests
Execute the server-side tests:
ansible-playbook -i inventory/hosts.yml playbooks/test-squid.yml
Run the client-side tests:
ansible-playbook -i inventory/hosts.yml playbooks/client-test.yml
Perform manual testing from the client machine:
# Test basic connectivity
curl -x 192.168.1.100:3128 http://www.google.com

# Test with verbose output
curl -x 192.168.1.100:3128 -v http://httpbin.org/ip

# Test HTTPS through proxy
curl -x 192.168.1.100:3128 https://httpbin.org/ip
Subtask 3.4: Monitor and Verify Proxy Performance
Create a monitoring playbook:
nano playbooks/monitor-squid.yml
Add monitoring tasks:
---
- name: Monitor Squid Proxy Performance
  hosts: proxy_servers
  become: yes
  
  tasks:
    - name: Check squid cache statistics
      command: squidclient mgr:storedir
      register: cache_stats
      tags: cache_monitoring

    - name: Display cache statistics
      debug:
        var: cache_stats.stdout_lines
      tags: cache_monitoring

    - name: Check memory usage
      command: squidclient mgr:mem
      register: memory_stats
      tags: memory_monitoring

    - name: Display memory statistics
      debug:
        var: memory_stats.stdout_lines
      tags: memory_monitoring

    - name: Monitor active connections
      command: netstat -an | grep :3128
      register: connections
      tags: connection_monitoring

    - name: Display active connections
      debug:
        var: connections.stdout_lines
      tags: connection_monitoring

    - name: Check disk usage for cache directory
      command: df -h /var/spool/squid
      register: disk_usage
      tags: disk_monitoring

    - name: Display disk usage
      debug:
        var: disk_usage.stdout_lines
      tags: disk_monitoring
Run the monitoring playbook:
ansible-playbook -i inventory/hosts.yml playbooks/monitor-squid.yml
Troubleshooting Common Issues
Issue 1: Squid Service Fails to Start
Symptoms: Service fails to start or immediately stops

Solutions:

Check configuration syntax:
ansible proxy_servers -i inventory/hosts.yml -m command -a "squid -k parse"
Check system logs:
ansible proxy_servers -i inventory/hosts.yml -m command -a "journalctl -u squid -n 50"
Verify cache directory permissions:
ansible proxy_servers -i inventory/hosts.yml -m command -a "ls -la /var/spool/squid"
Issue 2: Proxy Connection Refused
Symptoms: Clients cannot connect to proxy

Solutions:

Check firewall settings:
ansible proxy_servers -i inventory/hosts.yml -m command -a "firewall-cmd --list-ports"
Verify port binding:
ansible proxy_servers -i inventory/hosts.yml -m command -a "netstat -tlnp | grep 3128"
Issue 3: Access Denied Errors
Symptoms: HTTP 403 Forbidden responses

Solutions:

Review ACL configuration in squid.conf
Check client IP against allowed networks
Verify access rules order
Performance Optimization Tips
Cache Size Tuning: Adjust cache_dir size based on available disk space
Memory Optimization: Configure cache_mem based on available RAM
DNS Performance: Use fast, reliable DNS servers
Log Management: Implement proper log rotation to prevent disk space issues
Conclusion
In this comprehensive lab, you have successfully:

Automated Squid Installation: Created Ansible playbooks to install and configure Squid proxy server automatically, demonstrating Infrastructure as Code principles
Implemented Advanced Configuration: Configured caching policies, access control lists, and security settings using Jinja2 templates
Established Access Controls: Set up network-based access rules and domain blocking capabilities
Validated Functionality: Performed comprehensive testing to ensure proxy server operates correctly
Monitored Performance: Implemented monitoring and statistics collection for ongoing maintenance
Why This Matters: Proxy servers are essential components in enterprise networks, providing caching, security, and access control. By automating their deployment with Ansible, you ensure consistent, repeatable installations that reduce human error and deployment time. This approach is particularly valuable in large-scale environments where multiple proxy servers need to be deployed and maintained.

Real-World Applications: The skills learned in this lab directly apply to:

Enterprise network infrastructure management
Content filtering and security implementations
Performance optimization through caching
Compliance and access control requirements
DevOps and Infrastructure as Code practices
The automation techniques demonstrated here can be extended to manage entire proxy server fleets, implement configuration changes across multiple servers simultaneously, and maintain consistent security policies throughout your infrastructure.
