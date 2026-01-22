Lab 17: Orchestrating Multiple Tasks
Objectives
By the end of this lab, students will be able to:

• Create and organize multiple Ansible playbooks for complex system orchestration • Implement task dependencies and execution order control • Use Ansible roles and includes to structure multi-playbook workflows • Handle error conditions and rollback scenarios in orchestrated deployments • Manage variable passing between different playbooks and tasks • Implement conditional execution based on system states and prerequisites

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Ansible playbooks and YAML syntax • Familiarity with Linux command line operations • Knowledge of SSH key-based authentication • Understanding of basic system administration concepts • Completion of previous Ansible labs covering playbook basics

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or configure complex networking.

Your lab environment includes: • Control Node: CentOS/RHEL 8 with Ansible pre-installed • Managed Nodes: 3 target systems (web servers, database server, load balancer) • Pre-configured SSH keys for passwordless authentication • Sample application files and configuration templates

Task 1: Create a Multi-Playbook Structure for Orchestrating Multiple System Configurations
Subtask 1.1: Design the Orchestration Architecture
First, let's understand what we're building - a complete web application stack with multiple components that must be deployed in a specific order.

Architecture Overview: • Database server (must be deployed first) • Web application servers (depend on database) • Load balancer (depends on web servers) • Monitoring system (depends on all components)

Create the project directory structure:

mkdir -p ~/ansible-orchestration
cd ~/ansible-orchestration
mkdir -p {playbooks,roles,group_vars,host_vars,inventory}
Subtask 1.2: Create the Master Orchestration Playbook
Create the main orchestration playbook that will coordinate all deployments:

# playbooks/site.yml
---
- name: "Complete Application Stack Deployment"
  hosts: localhost
  gather_facts: false
  vars:
    deployment_timestamp: "{{ ansible_date_time.epoch }}"
    deployment_id: "deploy-{{ deployment_timestamp }}"
  
  tasks:
    - name: "Display deployment information"
      debug:
        msg: |
          Starting orchestrated deployment
          Deployment ID: {{ deployment_id }}
          Timestamp: {{ ansible_date_time.iso8601 }}

    - name: "Phase 1 - Deploy Database Infrastructure"
      import_playbook: database.yml
      tags: ['database', 'infrastructure']

    - name: "Phase 2 - Deploy Web Application Servers"
      import_playbook: webservers.yml
      tags: ['webservers', 'application']

    - name: "Phase 3 - Configure Load Balancer"
      import_playbook: loadbalancer.yml
      tags: ['loadbalancer', 'networking']

    - name: "Phase 4 - Setup Monitoring"
      import_playbook: monitoring.yml
      tags: ['monitoring', 'observability']

    - name: "Phase 5 - Validate Complete Stack"
      import_playbook: validation.yml
      tags: ['validation', 'testing']
Subtask 1.3: Create Individual Component Playbooks
Database Playbook:

# playbooks/database.yml
---
- name: "Deploy Database Server"
  hosts: database_servers
  become: yes
  vars:
    db_name: "webapp_db"
    db_user: "webapp_user"
    db_password: "{{ vault_db_password | default('defaultpass123') }}"
    
  pre_tasks:
    - name: "Check if database server is reachable"
      ping:
      register: db_ping_result
      
    - name: "Fail if database server unreachable"
      fail:
        msg: "Database server is not reachable"
      when: db_ping_result is failed

  tasks:
    - name: "Install MySQL/MariaDB packages"
      yum:
        name:
          - mariadb-server
          - mariadb
          - python3-PyMySQL
        state: present

    - name: "Start and enable MariaDB service"
      systemd:
        name: mariadb
        state: started
        enabled: yes

    - name: "Create application database"
      mysql_db:
        name: "{{ db_name }}"
        state: present
        login_unix_socket: /var/lib/mysql/mysql.sock

    - name: "Create database user"
      mysql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        priv: "{{ db_name }}.*:ALL"
        host: "%"
        state: present
        login_unix_socket: /var/lib/mysql/mysql.sock

    - name: "Configure firewall for MySQL"
      firewalld:
        service: mysql
        permanent: yes
        state: enabled
        immediate: yes

  post_tasks:
    - name: "Verify database service is running"
      systemd:
        name: mariadb
      register: db_service_status
      
    - name: "Set database deployment fact"
      set_fact:
        database_deployed: true
        database_host: "{{ ansible_default_ipv4.address }}"
      when: db_service_status.status.ActiveState == "active"
Web Servers Playbook:

# playbooks/webservers.yml
---
- name: "Deploy Web Application Servers"
  hosts: web_servers
  become: yes
  vars:
    app_name: "webapp"
    app_port: 8080
    
  pre_tasks:
    - name: "Verify database is deployed"
      fail:
        msg: "Database must be deployed before web servers"
      when: hostvars[groups['database_servers'][0]]['database_deployed'] is not defined

  tasks:
    - name: "Install web server packages"
      yum:
        name:
          - httpd
          - php
          - php-mysql
          - php-json
        state: present

    - name: "Create application directory"
      file:
        path: "/var/www/html/{{ app_name }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'

    - name: "Deploy application configuration"
      template:
        src: app_config.php.j2
        dest: "/var/www/html/{{ app_name }}/config.php"
        owner: apache
        group: apache
        mode: '0644'
      vars:
        db_host: "{{ hostvars[groups['database_servers'][0]]['database_host'] }}"

    - name: "Deploy sample application"
      copy:
        content: |
          <?php
          require_once 'config.php';
          echo "<h1>Web Server: {{ ansible_hostname }}</h1>";
          echo "<p>Database Connection: " . DB_HOST . "</p>";
          echo "<p>Deployment Time: {{ ansible_date_time.iso8601 }}</p>";
          ?>
        dest: "/var/www/html/{{ app_name }}/index.php"
        owner: apache
        group: apache
        mode: '0644'

    - name: "Configure Apache virtual host"
      template:
        src: webapp.conf.j2
        dest: "/etc/httpd/conf.d/{{ app_name }}.conf"
      notify: restart apache

    - name: "Start and enable Apache"
      systemd:
        name: httpd
        state: started
        enabled: yes

    - name: "Configure firewall for HTTP"
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes

  handlers:
    - name: restart apache
      systemd:
        name: httpd
        state: restarted

  post_tasks:
    - name: "Set web server deployment fact"
      set_fact:
        webserver_deployed: true
        webserver_url: "http://{{ ansible_default_ipv4.address }}/{{ app_name }}"
Subtask 1.4: Create Template Files
Create the necessary template files:

mkdir -p templates
Application Configuration Template:

# templates/app_config.php.j2
<?php
define('DB_HOST', '{{ db_host }}');
define('DB_NAME', '{{ db_name }}');
define('DB_USER', '{{ db_user }}');
define('DB_PASS', '{{ db_password }}');
define('APP_NAME', '{{ app_name }}');
?>
Apache Virtual Host Template:

# templates/webapp.conf.j2
<VirtualHost *:80>
    DocumentRoot /var/www/html/{{ app_name }}
    ServerName {{ ansible_fqdn }}
    
    <Directory /var/www/html/{{ app_name }}>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog logs/{{ app_name }}_error.log
    CustomLog logs/{{ app_name }}_access.log combined
</VirtualHost>
Task 2: Handle Interdependencies Between Tasks and Systems
Subtask 2.1: Implement Dependency Checking
Create a dependency validation playbook:

# playbooks/dependency_check.yml
---
- name: "Validate System Dependencies"
  hosts: all
  gather_facts: yes
  vars:
    required_dependencies:
      - name: "Network Connectivity"
        check: "ping"
      - name: "Sufficient Disk Space"
        check: "disk_space"
      - name: "Required Ports Available"
        check: "ports"

  tasks:
    - name: "Check network connectivity between servers"
      ping:
      delegate_to: "{{ item }}"
      loop: "{{ groups['all'] }}"
      when: item != inventory_hostname

    - name: "Check available disk space"
      assert:
        that:
          - ansible_mounts | selectattr('mount', 'equalto', '/') | map(attribute='size_available') | first > 1073741824
        fail_msg: "Insufficient disk space (less than 1GB available)"
        success_msg: "Sufficient disk space available"

    - name: "Check if required ports are available"
      wait_for:
        port: "{{ item }}"
        host: "{{ ansible_default_ipv4.address }}"
        state: stopped
        timeout: 5
      loop:
        - 80
        - 3306
        - 8080
      ignore_errors: yes
      register: port_check

    - name: "Report port availability"
      debug:
        msg: "Port {{ item.item }} is {{ 'available' if item.failed else 'in use' }}"
      loop: "{{ port_check.results }}"
Subtask 2.2: Create Load Balancer with Dependencies
# playbooks/loadbalancer.yml
---
- name: "Deploy Load Balancer"
  hosts: load_balancer
  become: yes
  vars:
    backend_servers: "{{ groups['web_servers'] }}"
    
  pre_tasks:
    - name: "Verify web servers are deployed"
      uri:
        url: "http://{{ item }}:80"
        method: GET
        status_code: 200
      loop: "{{ backend_servers }}"
      delegate_to: localhost
      register: web_server_check
      retries: 3
      delay: 10

    - name: "Fail if any web server is not responding"
      fail:
        msg: "Web server {{ item.item }} is not responding"
      loop: "{{ web_server_check.results }}"
      when: item.status != 200

  tasks:
    - name: "Install HAProxy"
      yum:
        name: haproxy
        state: present

    - name: "Configure HAProxy"
      template:
        src: haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
        backup: yes
      notify: restart haproxy

    - name: "Start and enable HAProxy"
      systemd:
        name: haproxy
        state: started
        enabled: yes

    - name: "Configure firewall for load balancer"
      firewalld:
        port: "{{ item }}"
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - "80/tcp"
        - "8404/tcp"  # HAProxy stats

  handlers:
    - name: restart haproxy
      systemd:
        name: haproxy
        state: restarted

  post_tasks:
    - name: "Verify load balancer is working"
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      delegate_to: localhost
      register: lb_check
      retries: 5
      delay: 5

    - name: "Set load balancer deployment fact"
      set_fact:
        loadbalancer_deployed: true
        loadbalancer_url: "http://{{ ansible_default_ipv4.address }}"
      when: lb_check.status == 200
Subtask 2.3: Create HAProxy Configuration Template
# templates/haproxy.cfg.j2
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

frontend webapp_frontend
    bind *:80
    default_backend webapp_servers

backend webapp_servers
    balance roundrobin
    option httpchk GET /webapp/
{% for server in backend_servers %}
    server {{ hostvars[server]['ansible_hostname'] }} {{ hostvars[server]['ansible_default_ipv4']['address'] }}:80 check
{% endfor %}

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
Subtask 2.4: Create Monitoring and Validation Playbook
# playbooks/monitoring.yml
---
- name: "Setup Basic Monitoring"
  hosts: all
  become: yes
  
  tasks:
    - name: "Install monitoring tools"
      yum:
        name:
          - htop
          - iotop
          - netstat-nat
        state: present

    - name: "Create monitoring script"
      copy:
        content: |
          #!/bin/bash
          echo "=== System Status Report ==="
          echo "Hostname: $(hostname)"
          echo "Date: $(date)"
          echo "Uptime: $(uptime)"
          echo "Disk Usage:"
          df -h /
          echo "Memory Usage:"
          free -h
          echo "Active Services:"
          systemctl list-units --type=service --state=active | grep -E "(httpd|mariadb|haproxy)"
        dest: /usr/local/bin/system-status.sh
        mode: '0755'

    - name: "Create monitoring cron job"
      cron:
        name: "System status monitoring"
        minute: "*/15"
        job: "/usr/local/bin/system-status.sh >> /var/log/system-status.log 2>&1"

- name: "Validate Complete Stack"
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: "Test database connectivity"
      mysql_db:
        name: "{{ db_name }}"
        state: present
        login_host: "{{ hostvars[groups['database_servers'][0]]['ansible_default_ipv4']['address'] }}"
        login_user: "{{ db_user }}"
        login_password: "{{ db_password }}"
      delegate_to: "{{ groups['database_servers'][0] }}"

    - name: "Test web servers individually"
      uri:
        url: "http://{{ item }}/webapp/"
        method: GET
        status_code: 200
      loop: "{{ groups['web_servers'] }}"
      register: web_test_results

    - name: "Test load balancer"
      uri:
        url: "http://{{ groups['load_balancer'][0] }}"
        method: GET
        status_code: 200
      register: lb_test_result

    - name: "Display validation results"
      debug:
        msg: |
          Validation Results:
          Database: Connected
          Web Servers: {{ web_test_results.results | length }} servers responding
          Load Balancer: {{ 'Working' if lb_test_result.status == 200 else 'Failed' }}
          
          Access your application at: http://{{ groups['load_balancer'][0] }}
Subtask 2.5: Create Inventory File
# inventory/hosts
[database_servers]
db1 ansible_host=10.0.1.10

[web_servers]
web1 ansible_host=10.0.1.11
web2 ansible_host=10.0.1.12

[load_balancer]
lb1 ansible_host=10.0.1.13

[all:vars]
ansible_user=centos
ansible_ssh_private_key_file=~/.ssh/id_rsa
Subtask 2.6: Create Group Variables
# group_vars/all.yml
---
# Global deployment settings
deployment_environment: "production"
app_name: "webapp"
db_name: "webapp_db"
db_user: "webapp_user"

# Security settings
vault_db_password: "SecurePassword123!"

# Network settings
http_port: 80
app_port: 8080
mysql_port: 3306
Subtask 2.7: Execute the Orchestrated Deployment
Run the complete orchestration:

# First, run dependency checks
ansible-playbook -i inventory/hosts playbooks/dependency_check.yml

# Run the complete orchestration
ansible-playbook -i inventory/hosts playbooks/site.yml

# Run specific phases if needed
ansible-playbook -i inventory/hosts playbooks/site.yml --tags database
ansible-playbook -i inventory/hosts playbooks/site.yml --tags webservers
ansible-playbook -i inventory/hosts playbooks/site.yml --tags loadbalancer
Subtask 2.8: Create Rollback Playbook
# playbooks/rollback.yml
---
- name: "Rollback Application Stack"
  hosts: all
  become: yes
  vars:
    rollback_services:
      - httpd
      - mariadb
      - haproxy
      
  tasks:
    - name: "Stop application services"
      systemd:
        name: "{{ item }}"
        state: stopped
      loop: "{{ rollback_services }}"
      ignore_errors: yes

    - name: "Remove application files"
      file:
        path: "{{ item }}"
        state: absent
      loop:
        - "/var/www/html/webapp"
        - "/etc/httpd/conf.d/webapp.conf"
        - "/etc/haproxy/haproxy.cfg.bak"

    - name: "Remove firewall rules"
      firewalld:
        service: "{{ item }}"
        permanent: yes
        state: disabled
        immediate: yes
      loop:
        - http
        - mysql
      ignore_errors: yes

    - name: "Display rollback completion"
      debug:
        msg: "Rollback completed for {{ inventory_hostname }}"
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Database Connection Failures

# Check database service status
ansible database_servers -i inventory/hosts -m systemd -a "name=mariadb" --become

# Test database connectivity
ansible database_servers -i inventory/hosts -m mysql_db -a "name=webapp_db state=present login_unix_socket=/var/lib/mysql/mysql.sock" --become
Issue 2: Web Server Not Responding

# Check Apache status and logs
ansible web_servers -i inventory/hosts -m shell -a "systemctl status httpd && tail -10 /var/log/httpd/error_log" --become
Issue 3: Load Balancer Backend Failures

# Check HAProxy configuration and status
ansible load_balancer -i inventory/hosts -m shell -a "haproxy -c -f /etc/haproxy/haproxy.cfg && systemctl status haproxy" --become
Issue 4: Firewall Blocking Connections

# Check firewall status
ansible all -i inventory/hosts -m shell -a "firewall-cmd --list-all" --become
Debugging Commands
# Run playbook with verbose output
ansible-playbook -i inventory/hosts playbooks/site.yml -vvv

# Check facts gathering
ansible all -i inventory/hosts -m setup

# Test connectivity
ansible all -i inventory/hosts -m ping

# Check specific service status
ansible all -i inventory/hosts -m shell -a "systemctl status httpd mariadb haproxy" --become
Conclusion
In this lab, you have successfully learned how to orchestrate multiple tasks and systems using Ansible. You accomplished the following key objectives:

What You Built: • A complete multi-tier web application stack with database, web servers, and load balancer • Interdependent playbooks that execute in proper sequence • Dependency validation and error handling mechanisms • Monitoring and validation systems for the entire stack

Key Skills Developed: • Multi-playbook orchestration - You learned how to break complex deployments into manageable, reusable components • Dependency management - You implemented proper sequencing and validation between system components • Error handling - You created robust playbooks that can detect and respond to failure conditions • Template management - You used Jinja2 templates to create dynamic configurations • Fact sharing - You learned how to pass information between different playbooks and hosts

Why This Matters: In real-world enterprise environments, applications rarely exist in isolation. Modern systems require orchestrating multiple components that depend on each other. The skills you've developed in this lab are essential for:

• DevOps automation - Automating complex application deployments • Infrastructure as Code - Managing infrastructure through version-controlled playbooks • Disaster recovery - Creating repeatable deployment processes for quick recovery • Scaling operations - Managing large-scale infrastructure changes efficiently

Next Steps: • Explore Ansible Tower/AWX for enterprise orchestration with GUI interfaces • Learn about Ansible Vault for secure credential management • Practice with more complex scenarios involving containers and cloud services • Study advanced Ansible features like custom modules and plugins

You now have the foundation to handle complex, multi-system deployments with confidence and can apply these orchestration principles to any technology stack in your organization.
