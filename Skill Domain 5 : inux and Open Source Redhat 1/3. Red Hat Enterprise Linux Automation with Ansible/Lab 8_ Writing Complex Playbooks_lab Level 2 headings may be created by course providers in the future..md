Lab 8: Writing Complex Playbooks
Objectives
By the end of this lab, students will be able to:

• Break down complex automation tasks into multiple organized plays • Structure playbooks using roles for better organization and reusability • Create comprehensive playbooks that configure multiple web and database servers • Implement best practices for complex Ansible playbook architecture • Use variables, handlers, and templates effectively in multi-tier applications • Understand the relationship between plays, tasks, and roles in complex scenarios

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Ansible concepts (playbooks, tasks, modules) • Familiarity with YAML syntax and structure • Knowledge of Linux command line operations • Understanding of web servers (Apache/Nginx) and database servers (MySQL/PostgreSQL) • Completion of previous Ansible labs covering basic playbook creation • Basic networking concepts (ports, services, firewalls)

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines.

Your lab environment includes: • 1 Ansible Control Node (CentOS/RHEL 8) • 2 Web Server nodes (CentOS/RHEL 8) • 2 Database Server nodes (CentOS/RHEL 8) • Pre-installed Ansible on the control node • SSH key-based authentication already configured

Task 1: Breaking Down Complex Tasks into Multiple Plays
Subtask 1.1: Understanding Multi-Play Structure
A complex playbook should be organized into logical plays that handle specific aspects of your infrastructure.

Create the main playbook structure:

mkdir -p ~/complex-playbook/{group_vars,host_vars,roles,templates,files}
cd ~/complex-playbook
Create the main playbook file:

nano site.yml
Add the following multi-play structure:

---
- name: Configure Database Servers
  hosts: database_servers
  become: yes
  vars:
    mysql_root_password: "SecurePass123!"
    mysql_database: "webapp_db"
    mysql_user: "webapp_user"
    mysql_password: "WebApp123!"
  
  tasks:
    - name: Install MySQL server
      yum:
        name: 
          - mysql-server
          - python3-PyMySQL
        state: present
    
    - name: Start and enable MySQL service
      systemd:
        name: mysqld
        state: started
        enabled: yes
    
    - name: Set MySQL root password
      mysql_user:
        name: root
        password: "{{ mysql_root_password }}"
        login_unix_socket: /var/lib/mysql/mysql.sock
        state: present
    
    - name: Create application database
      mysql_db:
        name: "{{ mysql_database }}"
        login_user: root
        login_password: "{{ mysql_root_password }}"
        state: present
    
    - name: Create application user
      mysql_user:
        name: "{{ mysql_user }}"
        password: "{{ mysql_password }}"
        priv: "{{ mysql_database }}.*:ALL"
        login_user: root
        login_password: "{{ mysql_root_password }}"
        state: present

- name: Configure Web Servers
  hosts: web_servers
  become: yes
  vars:
    web_user: "webadmin"
    document_root: "/var/www/html"
    
  tasks:
    - name: Install Apache web server
      yum:
        name:
          - httpd
          - php
          - php-mysql
        state: present
    
    - name: Create web user
      user:
        name: "{{ web_user }}"
        system: yes
        shell: /bin/bash
        home: /home/{{ web_user }}
        create_home: yes
    
    - name: Start and enable Apache service
      systemd:
        name: httpd
        state: started
        enabled: yes
    
    - name: Configure firewall for HTTP
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes

- name: Deploy Application
  hosts: web_servers
  become: yes
  vars:
    app_name: "webapp"
    
  tasks:
    - name: Create application directory
      file:
        path: "{{ document_root }}/{{ app_name }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
    
    - name: Deploy sample PHP application
      copy:
        content: |
          <?php
          $servername = "{{ groups['database_servers'][0] }}";
          $username = "{{ mysql_user }}";
          $password = "{{ mysql_password }}";
          $dbname = "{{ mysql_database }}";
          
          try {
              $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
              $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
              echo "<h1>Database Connection Successful!</h1>";
              echo "<p>Connected to database: $dbname</p>";
          } catch(PDOException $e) {
              echo "<h1>Connection failed: " . $e->getMessage() . "</h1>";
          }
          ?>
        dest: "{{ document_root }}/{{ app_name }}/index.php"
        owner: apache
        group: apache
        mode: '0644'
Subtask 1.2: Creating Inventory File
Create an inventory file to define your server groups:

nano inventory.ini
Add the following inventory structure:

[web_servers]
web1 ansible_host=10.0.1.10
web2 ansible_host=10.0.1.11

[database_servers]
db1 ansible_host=10.0.1.20
db2 ansible_host=10.0.1.21

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
Subtask 1.3: Testing the Multi-Play Structure
Run the playbook to test the multi-play structure:

ansible-playbook -i inventory.ini site.yml --check
Execute the actual deployment:

ansible-playbook -i inventory.ini site.yml
Task 2: Organizing Tasks by Roles
Subtask 2.1: Creating Role Structure
Create role directories for better organization:

ansible-galaxy init roles/mysql
ansible-galaxy init roles/apache
ansible-galaxy init roles/webapp
Subtask 2.2: Developing the MySQL Role
Create the MySQL role tasks:

nano roles/mysql/tasks/main.yml
Add the following content:

---
- name: Install MySQL packages
  yum:
    name:
      - mysql-server
      - python3-PyMySQL
    state: present

- name: Start and enable MySQL service
  systemd:
    name: mysqld
    state: started
    enabled: yes

- name: Set MySQL root password
  mysql_user:
    name: root
    password: "{{ mysql_root_password }}"
    login_unix_socket: /var/lib/mysql/mysql.sock
    state: present
  notify: restart mysql

- name: Create MySQL configuration file
  template:
    src: my.cnf.j2
    dest: /etc/my.cnf
    backup: yes
  notify: restart mysql

- name: Create application database
  mysql_db:
    name: "{{ mysql_database }}"
    login_user: root
    login_password: "{{ mysql_root_password }}"
    state: present

- name: Create application user
  mysql_user:
    name: "{{ mysql_user }}"
    password: "{{ mysql_password }}"
    priv: "{{ mysql_database }}.*:ALL"
    login_user: root
    login_password: "{{ mysql_root_password }}"
    state: present

- name: Configure firewall for MySQL
  firewalld:
    port: 3306/tcp
    permanent: yes
    state: enabled
    immediate: yes
Create MySQL role variables:

nano roles/mysql/defaults/main.yml
---
mysql_root_password: "SecurePass123!"
mysql_database: "webapp_db"
mysql_user: "webapp_user"
mysql_password: "WebApp123!"
mysql_port: 3306
mysql_bind_address: "0.0.0.0"
Create MySQL configuration template:

nano roles/mysql/templates/my.cnf.j2
[mysqld]
bind-address = {{ mysql_bind_address }}
port = {{ mysql_port }}
datadir = /var/lib/mysql
socket = /var/lib/mysql/mysql.sock
user = mysql
symbolic-links = 0

[mysqld_safe]
log-error = /var/log/mysqld.log
pid-file = /var/run/mysqld/mysqld.pid
Create MySQL role handlers:

nano roles/mysql/handlers/main.yml
---
- name: restart mysql
  systemd:
    name: mysqld
    state: restarted
Subtask 2.3: Developing the Apache Role
Create the Apache role tasks:

nano roles/apache/tasks/main.yml
---
- name: Install Apache and PHP packages
  yum:
    name:
      - httpd
      - php
      - php-mysql
      - php-json
    state: present

- name: Create web user
  user:
    name: "{{ web_user }}"
    system: yes
    shell: /bin/bash
    home: /home/{{ web_user }}
    create_home: yes

- name: Configure Apache virtual host
  template:
    src: vhost.conf.j2
    dest: /etc/httpd/conf.d/{{ app_name }}.conf
    backup: yes
  notify: restart apache

- name: Create document root directory
  file:
    path: "{{ document_root }}"
    state: directory
    owner: apache
    group: apache
    mode: '0755'

- name: Start and enable Apache service
  systemd:
    name: httpd
    state: started
    enabled: yes

- name: Configure firewall for HTTP and HTTPS
  firewalld:
    service: "{{ item }}"
    permanent: yes
    state: enabled
    immediate: yes
  loop:
    - http
    - https
Create Apache role variables:

nano roles/apache/defaults/main.yml
---
web_user: "webadmin"
document_root: "/var/www/html"
app_name: "webapp"
server_name: "{{ ansible_fqdn }}"
Create Apache virtual host template:

nano roles/apache/templates/vhost.conf.j2
<VirtualHost *:80>
    ServerName {{ server_name }}
    DocumentRoot {{ document_root }}
    
    <Directory {{ document_root }}>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog /var/log/httpd/{{ app_name }}_error.log
    CustomLog /var/log/httpd/{{ app_name }}_access.log combined
</VirtualHost>
Create Apache role handlers:

nano roles/apache/handlers/main.yml
---
- name: restart apache
  systemd:
    name: httpd
    state: restarted
Subtask 2.4: Developing the Web Application Role
Create the webapp role tasks:

nano roles/webapp/tasks/main.yml
---
- name: Create application directory
  file:
    path: "{{ document_root }}/{{ app_name }}"
    state: directory
    owner: apache
    group: apache
    mode: '0755'

- name: Deploy application configuration
  template:
    src: config.php.j2
    dest: "{{ document_root }}/{{ app_name }}/config.php"
    owner: apache
    group: apache
    mode: '0644'

- name: Deploy main application file
  template:
    src: index.php.j2
    dest: "{{ document_root }}/{{ app_name }}/index.php"
    owner: apache
    group: apache
    mode: '0644'

- name: Deploy database connection test
  template:
    src: dbtest.php.j2
    dest: "{{ document_root }}/{{ app_name }}/dbtest.php"
    owner: apache
    group: apache
    mode: '0644'

- name: Create uploads directory
  file:
    path: "{{ document_root }}/{{ app_name }}/uploads"
    state: directory
    owner: apache
    group: apache
    mode: '0755'
Create webapp role variables:

nano roles/webapp/defaults/main.yml
---
app_name: "webapp"
app_version: "1.0"
database_host: "{{ groups['database_servers'][0] }}"
Create application templates:

nano roles/webapp/templates/config.php.j2
<?php
// Database configuration
define('DB_HOST', '{{ database_host }}');
define('DB_NAME', '{{ mysql_database }}');
define('DB_USER', '{{ mysql_user }}');
define('DB_PASS', '{{ mysql_password }}');

// Application configuration
define('APP_NAME', '{{ app_name }}');
define('APP_VERSION', '{{ app_version }}');
define('DEBUG', false);
?>
nano roles/webapp/templates/index.php.j2
<?php
require_once 'config.php';

echo "<h1>Welcome to " . APP_NAME . "</h1>";
echo "<p>Version: " . APP_VERSION . "</p>";
echo "<p>Server: " . gethostname() . "</p>";

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<div style='color: green;'>";
    echo "<h2>✓ Database Connection Successful!</h2>";
    echo "<p>Connected to database: " . DB_NAME . "</p>";
    echo "<p>Database server: " . DB_HOST . "</p>";
    echo "</div>";
    
    // Create a simple table if it doesn't exist
    $pdo->exec("CREATE TABLE IF NOT EXISTS visitors (
        id INT AUTO_INCREMENT PRIMARY KEY,
        visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ip_address VARCHAR(45)
    )");
    
    // Log this visit
    $stmt = $pdo->prepare("INSERT INTO visitors (ip_address) VALUES (?)");
    $stmt->execute([$_SERVER['REMOTE_ADDR']]);
    
    // Show visitor count
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM visitors");
    $count = $stmt->fetch()['count'];
    echo "<p>Total visits: " . $count . "</p>";
    
} catch(PDOException $e) {
    echo "<div style='color: red;'>";
    echo "<h2>✗ Database Connection Failed!</h2>";
    echo "<p>Error: " . $e->getMessage() . "</p>";
    echo "</div>";
}
?>

<hr>
<p><a href="dbtest.php">Test Database Connection</a></p>
nano roles/webapp/templates/dbtest.php.j2
<?php
require_once 'config.php';

echo "<h1>Database Connection Test</h1>";

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<h2>Connection Details:</h2>";
    echo "<ul>";
    echo "<li>Host: " . DB_HOST . "</li>";
    echo "<li>Database: " . DB_NAME . "</li>";
    echo "<li>User: " . DB_USER . "</li>";
    echo "<li>Status: <span style='color: green;'>Connected</span></li>";
    echo "</ul>";
    
    // Test query
    $stmt = $pdo->query("SELECT VERSION() as version");
    $version = $stmt->fetch()['version'];
    echo "<p>MySQL Version: " . $version . "</p>";
    
    // Show tables
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "<h3>Available Tables:</h3>";
    echo "<ul>";
    foreach($tables as $table) {
        echo "<li>" . $table . "</li>";
    }
    echo "</ul>";
    
} catch(PDOException $e) {
    echo "<h2 style='color: red;'>Connection Failed!</h2>";
    echo "<p>Error: " . $e->getMessage() . "</p>";
}
?>

<hr>
<p><a href="index.php">Back to Main Page</a></p>
Task 3: Creating a Comprehensive Multi-Server Playbook
Subtask 3.1: Creating the Role-Based Playbook
Create a new playbook that uses the roles:

nano site-with-roles.yml
---
- name: Configure Database Servers
  hosts: database_servers
  become: yes
  roles:
    - mysql
  tags:
    - database
    - mysql

- name: Configure Web Servers
  hosts: web_servers
  become: yes
  roles:
    - apache
  tags:
    - webserver
    - apache

- name: Deploy Web Application
  hosts: web_servers
  become: yes
  roles:
    - webapp
  tags:
    - application
    - webapp

- name: Verify Deployment
  hosts: web_servers
  become: yes
  tasks:
    - name: Check Apache service status
      systemd:
        name: httpd
      register: apache_status
    
    - name: Display Apache status
      debug:
        msg: "Apache is {{ apache_status.status.ActiveState }}"
    
    - name: Test web application
      uri:
        url: "http://{{ ansible_default_ipv4.address }}/{{ app_name }}"
        method: GET
        status_code: 200
      register: web_test
      ignore_errors: yes
    
    - name: Display web test results
      debug:
        msg: "Web application test: {{ 'PASSED' if web_test.status == 200 else 'FAILED' }}"
  tags:
    - verification
    - testing
Subtask 3.2: Creating Group Variables
Create group-specific variables:

nano group_vars/database_servers.yml
---
mysql_root_password: "DatabaseRoot123!"
mysql_database: "production_db"
mysql_user: "app_user"
mysql_password: "AppUser123!"
mysql_bind_address: "0.0.0.0"

# Performance tuning
mysql_max_connections: 100
mysql_innodb_buffer_pool_size: "128M"
nano group_vars/web_servers.yml
---
web_user: "webadmin"
document_root: "/var/www/html"
app_name: "mywebapp"
server_name: "{{ inventory_hostname }}.example.com"

# Apache tuning
apache_max_request_workers: 150
apache_server_limit: 16
nano group_vars/all.yml
---
# Common variables for all servers
timezone: "America/New_York"
ntp_servers:
  - "0.pool.ntp.org"
  - "1.pool.ntp.org"

# Security settings
ssh_port: 22
firewall_enabled: true

# Monitoring
log_retention_days: 30
Subtask 3.3: Adding Pre and Post Tasks
Create a comprehensive playbook with pre and post tasks:

nano complete-deployment.yml
---
- name: Pre-deployment Tasks
  hosts: all
  become: yes
  tasks:
    - name: Update system packages
      yum:
        name: "*"
        state: latest
        update_cache: yes
    
    - name: Install common packages
      yum:
        name:
          - vim
          - wget
          - curl
          - net-tools
          - htop
        state: present
    
    - name: Set timezone
      timezone:
        name: "{{ timezone }}"
    
    - name: Start and enable firewalld
      systemd:
        name: firewalld
        state: started
        enabled: yes
  tags:
    - preparation
    - system-update

- name: Configure Database Servers
  hosts: database_servers
  become: yes
  pre_tasks:
    - name: Check available disk space
      shell: df -h /var/lib/mysql
      register: disk_space
      changed_when: false
    
    - name: Display disk space
      debug:
        var: disk_space.stdout_lines
  
  roles:
    - mysql
  
  post_tasks:
    - name: Verify MySQL is running
      systemd:
        name: mysqld
      register: mysql_status
    
    - name: Test MySQL connection
      mysql_db:
        name: "{{ mysql_database }}"
        login_user: root
        login_password: "{{ mysql_root_password }}"
        state: present
      register: mysql_test
    
    - name: Display MySQL status
      debug:
        msg: "MySQL service is {{ mysql_status.status.ActiveState }} and database connection is {{ 'working' if mysql_test is succeeded else 'failed' }}"
  
  tags:
    - database

- name: Configure Web Servers
  hosts: web_servers
  become: yes
  pre_tasks:
    - name: Check Apache package availability
      yum:
        list: httpd
      register: apache_package
    
    - name: Display Apache package info
      debug:
        msg: "Apache package version: {{ apache_package.results[0].version }}"
  
  roles:
    - apache
    - webapp
  
  post_tasks:
    - name: Wait for Apache to be ready
      wait_for:
        port: 80
        host: "{{ ansible_default_ipv4.address }}"
        delay: 5
        timeout: 30
    
    - name: Test web application connectivity
      uri:
        url: "http://{{ ansible_default_ipv4.address }}/{{ app_name }}"
        method: GET
        return_content: yes
      register: webapp_test
      retries: 3
      delay: 5
    
    - name: Display web application test results
      debug:
        msg: "Web application is {{ 'accessible' if webapp_test.status == 200 else 'not accessible' }}"
  
  tags:
    - webserver

- name: Post-deployment Verification
  hosts: all
  become: yes
  tasks:
    - name: Check system load
      shell: uptime
      register: system_load
      changed_when: false
    
    - name: Display system load
      debug:
        var: system_load.stdout
    
    - name: Check memory usage
      shell: free -h
      register: memory_usage
      changed_when: false
    
    - name: Display memory usage
      debug:
        var: memory_usage.stdout_lines
    
    - name: Generate deployment report
      template:
        src: deployment-report.j2
        dest: /tmp/deployment-report.txt
        mode: '0644'
      delegate_to: localhost
      run_once: true
  
  tags:
    - verification
    - reporting
Subtask 3.4: Creating Deployment Report Template
Create a deployment report template:

mkdir -p templates
nano templates/deployment-report.j2
DEPLOYMENT REPORT
=================
Generated: {{ ansible_date_time.iso8601 }}
Playbook: {{ ansible_playbook_python }}

INFRASTRUCTURE SUMMARY
======================
Total Servers: {{ groups['all'] | length }}
Web Servers: {{ groups['web_servers'] | length }}
Database Servers: {{ groups['database_servers'] | length }}

WEB SERVERS
===========
{% for host in groups['web_servers'] %}
- {{ host }}: {{ hostvars[host]['ansible_default_ipv4']['address'] }}
  OS: {{ hostvars[host]['ansible_distribution'] }} {{ hostvars[host]['ansible_distribution_version'] }}
  Apache Status: Running
  Application: {{ app_name }}
{% endfor %}

DATABASE SERVERS
================
{% for host in groups['database_servers'] %}
- {{ host }}: {{ hostvars[host]['ansible_default_ipv4']['address'] }}
  OS: {{ hostvars[host]['ansible_distribution'] }} {{ hostvars[host]['ansible_distribution_version'] }}
  MySQL Status: Running
  Database: {{ mysql_database }}
{% endfor %}

DEPLOYMENT STATUS
=================
Status: SUCCESS
Timestamp: {{ ansible_date_time.iso8601 }}
Duration: {{ ansible_play_batch | length }} servers configured

NEXT STEPS
==========
1. Monitor application logs: /var/log/httpd/
2. Check database performance: MySQL slow query log
3. Verify backup procedures
4. Set up monitoring and alerting
Subtask 3.5: Running the Complete Deployment
Execute the comprehensive deployment:

# Run with specific tags
ansible-playbook -i inventory.ini complete-deployment.yml --tags "preparation,database"

# Run full deployment
ansible-playbook -i inventory.ini complete-deployment.yml

# Run only verification
ansible-playbook -i inventory.ini complete-deployment.yml --tags "verification"
Subtask 3.6: Testing and Validation
Create a separate testing playbook:

nano test-deployment.yml
---
- name: Test Database Connectivity
  hosts: database_servers
  become: yes
  tasks:
    - name: Test MySQL service
      systemd:
        name: mysqld
      register: mysql_service
    
    - name: Test database connection
      mysql_db:
        name: "{{ mysql_database }}"
        login_user: "{{ mysql_user }}"
        login_password: "{{ mysql_password }}"
        state: present
      register: db_connection
    
    - name: Display database test results
      debug:
        msg: "Database test: {{ 'PASSED' if db_connection is succeeded else 'FAILED' }}"

- name: Test Web Application
  hosts: web_servers
  become: yes
  tasks:
    - name: Test Apache service
      systemd:
        name: httpd
      register: apache_service
    
    - name: Test web application response
      uri:
        url: "http://{{ ansible_default_ipv4.address }}/{{ app_name }}"
        method: GET
        return_content: yes
      register: web_response
    
    - name: Test database connectivity from web
      uri:
        url: "http://{{ ansible_default_ipv4.address }}/{{ app_name }}/dbtest.php"
        method: GET
        return_content: yes
      register: db_web_test
    
    - name: Display web application test results
      debug:
        msg: 
          - "Web server test: {{ 'PASSED' if web_response.status == 200 else 'FAILED' }}"
          - "Database connectivity test: {{ 'PASSED' if 'Connected' in db_web_test.content else 'FAILED' }}"

- name: Generate Test Report
  hosts: localhost
  tasks:
    - name: Create test summary
      debug:
        msg:
          - "=== DEPLOYMENT TEST SUMMARY ==="
          - "Database servers: {{ groups['database_servers'] | length }} configured"
          - "Web servers: {{ groups['web_servers'] | length }} configured"
          - "Test completed at: {{ ansible_date_time.iso8601 }}"
Run the testing playbook:

ansible-playbook -i inventory.ini test-deployment.yml
Troubleshooting Common Issues
Database Connection Issues
If you encounter database connection problems:

# Check MySQL service status
ansible database_servers -i inventory.ini -m systemd -a "name=mysqld" --become

# Check MySQL logs
ansible database_servers -i inventory.ini -m shell -a "tail -20 /var/log/mysqld.log" --become

# Test MySQL connectivity
ansible database_servers -i inventory.ini -m shell -a "mysql -u root -p'SecurePass123!' -e 'SHOW DATABASES;'" --become
Web Server Issues
If web servers are not responding:

# Check Apache service status
ansible web_servers -i inventory.ini -m systemd -a "name=httpd" --become

# Check Apache error logs
ansible web_servers -i inventory.ini -m shell -a "tail -20 /var/log/httpd/error_log" --become

# Test port connectivity
ansible web_servers -i inventory.ini -m shell -a "netstat -tlnp | grep :80" --become
Firewall Issues
If services are blocked by firewall:

# Check firewall status
ansible all -i inventory.ini -m shell -a "firewall-cmd --list-all" --become

# Open required ports
ansible web_servers -i inventory.ini -m firewalld -a "port=80/tcp permanent=yes state=enabled immediate=yes" --become
Conclusion
In this comprehensive lab, you have successfully:

• Mastered Multi-Play Architecture: You learned how to break down complex automation tasks into logical, manageable plays that handle specific infrastructure components separately.

• Implemented Role-Based Organization: You created reusable roles for MySQL, Apache, and web applications, making your playbooks modular, maintainable, and scalable.

• Built Production-Ready Infrastructure: You deployed a complete multi-tier application stack with proper configuration management, including database servers, web servers, and application deployment.

• Applied Best Practices: You implemented proper variable management, template usage, handlers, and error handling throughout your playbooks.

• Created Comprehensive Testing: You developed verification and testing procedures to ensure your deployments work correctly and can be validated automatically.

This lab demonstrates the power of Ansible for managing complex, multi-server environments. The skills you've developed here are directly applicable to real-world scenarios where you need to manage large-scale infrastructure deployments. The role-based approach you've learned will help you create maintainable automation that can be easily shared and reused across different projects and environments.

The techniques covered in this lab are essential for the Red Hat Enterprise Linux Automation with Ansible certification and provide a solid foundation for advanced Ansible automation in enterprise environments.
