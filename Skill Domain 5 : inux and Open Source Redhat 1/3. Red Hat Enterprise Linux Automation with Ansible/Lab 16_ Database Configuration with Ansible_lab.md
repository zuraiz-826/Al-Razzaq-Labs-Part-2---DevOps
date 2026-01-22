Lab 16: Database Configuration with Ansible
Objectives
By the end of this lab, students will be able to:

• Install and configure MySQL and PostgreSQL database servers on remote Linux hosts using Ansible • Create databases and database users through Ansible playbooks • Implement database security best practices by configuring proper permissions and access controls • Write reusable Ansible roles for database management tasks • Understand the fundamentals of Infrastructure as Code (IaC) for database administration • Troubleshoot common database configuration issues in automated deployments

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with YAML syntax and structure • Basic knowledge of Ansible concepts (playbooks, tasks, modules) • Understanding of database concepts (users, permissions, schemas) • Completion of previous Ansible labs or equivalent experience • Basic networking knowledge (IP addresses, ports, SSH)

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or install software locally.

Your lab environment includes: • Control Node: CentOS/RHEL 8 with Ansible pre-installed • Target Nodes: Two Ubuntu 20.04 LTS servers for database installation • All necessary network connectivity and SSH keys pre-configured

Task 1: Environment Preparation and Inventory Setup
Subtask 1.1: Verify Lab Environment
First, let's verify that your Ansible control node is properly configured and can communicate with the target hosts.

Connect to your control node via the provided terminal access

Check Ansible installation:

ansible --version
Verify target host connectivity:
ansible all -m ping
Expected output should show successful pings to both target hosts.

Subtask 1.2: Create Project Directory Structure
Create the lab project directory:
mkdir -p ~/ansible-database-lab
cd ~/ansible-database-lab
Create the directory structure:
mkdir -p {playbooks,roles,group_vars,host_vars,files,templates}
Create the inventory file:
cat > inventory.ini << 'EOF'
[mysql_servers]
mysql-server ansible_host=10.0.1.10

[postgresql_servers]
postgres-server ansible_host=10.0.1.11

[database_servers:children]
mysql_servers
postgresql_servers

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/lab_key
EOF
Subtask 1.3: Test Inventory Configuration
List all hosts in inventory:
ansible-inventory -i inventory.ini --list
Test connectivity to specific groups:
ansible mysql_servers -i inventory.ini -m ping
ansible postgresql_servers -i inventory.ini -m ping
Task 2: MySQL Installation and Configuration
Subtask 2.1: Create MySQL Installation Playbook
Create the MySQL playbook:
cat > playbooks/mysql-setup.yml << 'EOF'
---
- name: Install and Configure MySQL Server
  hosts: mysql_servers
  become: yes
  vars:
    mysql_root_password: "SecureRootPass123!"
    mysql_databases:
      - name: webapp_db
        encoding: utf8mb4
        collation: utf8mb4_unicode_ci
      - name: inventory_db
        encoding: utf8mb4
        collation: utf8mb4_unicode_ci
    mysql_users:
      - name: webapp_user
        password: "WebAppPass123!"
        priv: "webapp_db.*:ALL"
        host: "%"
      - name: inventory_user
        password: "InventoryPass123!"
        priv: "inventory_db.*:SELECT,INSERT,UPDATE,DELETE"
        host: "localhost"

  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install MySQL server and client
      apt:
        name:
          - mysql-server
          - mysql-client
          - python3-pymysql
        state: present

    - name: Start and enable MySQL service
      systemd:
        name: mysql
        state: started
        enabled: yes

    - name: Set MySQL root password
      mysql_user:
        name: root
        password: "{{ mysql_root_password }}"
        login_unix_socket: /var/run/mysqld/mysqld.sock
        state: present

    - name: Create MySQL configuration file for root
      template:
        src: my.cnf.j2
        dest: /root/.my.cnf
        owner: root
        group: root
        mode: '0600'

    - name: Remove anonymous MySQL users
      mysql_user:
        name: ""
        host_all: yes
        state: absent
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Remove MySQL test database
      mysql_db:
        name: test
        state: absent
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Create MySQL databases
      mysql_db:
        name: "{{ item.name }}"
        encoding: "{{ item.encoding }}"
        collation: "{{ item.collation }}"
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"
      loop: "{{ mysql_databases }}"

    - name: Create MySQL users
      mysql_user:
        name: "{{ item.name }}"
        password: "{{ item.password }}"
        priv: "{{ item.priv }}"
        host: "{{ item.host }}"
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"
      loop: "{{ mysql_users }}"

    - name: Configure MySQL for remote connections
      lineinfile:
        path: /etc/mysql/mysql.conf.d/mysqld.cnf
        regexp: '^bind-address'
        line: 'bind-address = 0.0.0.0'
        backup: yes
      notify: restart mysql

    - name: Open MySQL port in firewall
      ufw:
        rule: allow
        port: '3306'
        proto: tcp

  handlers:
    - name: restart mysql
      systemd:
        name: mysql
        state: restarted
EOF
Subtask 2.2: Create MySQL Configuration Template
Create the templates directory and MySQL config template:
mkdir -p templates

cat > templates/my.cnf.j2 << 'EOF'
[client]
user=root
password={{ mysql_root_password }}
socket=/var/run/mysqld/mysqld.sock

[mysql]
user=root
password={{ mysql_root_password }}
socket=/var/run/mysqld/mysqld.sock
EOF
Subtask 2.3: Execute MySQL Installation
Run the MySQL setup playbook:
ansible-playbook -i inventory.ini playbooks/mysql-setup.yml
Verify MySQL installation:
ansible mysql_servers -i inventory.ini -m shell -a "systemctl status mysql" --become
Test database connectivity:
ansible mysql_servers -i inventory.ini -m shell -a "mysql -u root -p'SecureRootPass123!' -e 'SHOW DATABASES;'" --become
Task 3: PostgreSQL Installation and Configuration
Subtask 3.1: Create PostgreSQL Installation Playbook
Create the PostgreSQL playbook:
cat > playbooks/postgresql-setup.yml << 'EOF'
---
- name: Install and Configure PostgreSQL Server
  hosts: postgresql_servers
  become: yes
  vars:
    postgresql_version: "12"
    postgresql_databases:
      - name: ecommerce_db
        owner: ecommerce_user
        encoding: UTF8
        locale: en_US.UTF-8
      - name: analytics_db
        owner: analytics_user
        encoding: UTF8
        locale: en_US.UTF-8
    postgresql_users:
      - name: ecommerce_user
        password: "EcommercePass123!"
        role_attr_flags: CREATEDB,NOSUPERUSER
      - name: analytics_user
        password: "AnalyticsPass123!"
        role_attr_flags: NOCREATEDB,NOSUPERUSER
      - name: readonly_user
        password: "ReadOnlyPass123!"
        role_attr_flags: NOCREATEDB,NOSUPERUSER

  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install PostgreSQL and dependencies
      apt:
        name:
          - postgresql
          - postgresql-contrib
          - python3-psycopg2
          - acl
        state: present

    - name: Start and enable PostgreSQL service
      systemd:
        name: postgresql
        state: started
        enabled: yes

    - name: Create PostgreSQL users
      postgresql_user:
        name: "{{ item.name }}"
        password: "{{ item.password }}"
        role_attr_flags: "{{ item.role_attr_flags }}"
        state: present
      become_user: postgres
      loop: "{{ postgresql_users }}"

    - name: Create PostgreSQL databases
      postgresql_db:
        name: "{{ item.name }}"
        owner: "{{ item.owner }}"
        encoding: "{{ item.encoding }}"
        lc_collate: "{{ item.locale }}"
        lc_ctype: "{{ item.locale }}"
        state: present
      become_user: postgres
      loop: "{{ postgresql_databases }}"

    - name: Configure PostgreSQL authentication
      postgresql_pg_hba:
        dest: /etc/postgresql/12/main/pg_hba.conf
        contype: host
        databases: all
        method: md5
        users: all
        source: 0.0.0.0/0
        backup: yes
      notify: restart postgresql

    - name: Configure PostgreSQL for remote connections
      postgresql_set:
        name: listen_addresses
        value: '*'
      become_user: postgres
      notify: restart postgresql

    - name: Configure PostgreSQL max connections
      postgresql_set:
        name: max_connections
        value: '200'
      become_user: postgres
      notify: restart postgresql

    - name: Grant database privileges to users
      postgresql_privs:
        database: "{{ item.db }}"
        roles: "{{ item.user }}"
        privs: "{{ item.privs }}"
        type: database
        state: present
      become_user: postgres
      loop:
        - { db: "ecommerce_db", user: "ecommerce_user", privs: "ALL" }
        - { db: "analytics_db", user: "analytics_user", privs: "ALL" }
        - { db: "ecommerce_db", user: "readonly_user", privs: "CONNECT" }
        - { db: "analytics_db", user: "readonly_user", privs: "CONNECT" }

    - name: Open PostgreSQL port in firewall
      ufw:
        rule: allow
        port: '5432'
        proto: tcp

  handlers:
    - name: restart postgresql
      systemd:
        name: postgresql
        state: restarted
EOF
Subtask 3.2: Execute PostgreSQL Installation
Run the PostgreSQL setup playbook:
ansible-playbook -i inventory.ini playbooks/postgresql-setup.yml
Verify PostgreSQL installation:
ansible postgresql_servers -i inventory.ini -m shell -a "systemctl status postgresql" --become
Test PostgreSQL connectivity:
ansible postgresql_servers -i inventory.ini -m shell -a "sudo -u postgres psql -c '\l'" --become
Task 4: Database Security Configuration
Subtask 4.1: Create Security Hardening Playbook
Create the security playbook:
cat > playbooks/database-security.yml << 'EOF'
---
- name: Secure Database Installations
  hosts: database_servers
  become: yes
  tasks:
    - name: Install fail2ban for intrusion prevention
      apt:
        name: fail2ban
        state: present

    - name: Configure fail2ban for SSH
      copy:
        content: |
          [sshd]
          enabled = true
          port = ssh
          filter = sshd
          logpath = /var/log/auth.log
          maxretry = 3
          bantime = 3600
        dest: /etc/fail2ban/jail.local
        backup: yes
      notify: restart fail2ban

    - name: Start and enable fail2ban
      systemd:
        name: fail2ban
        state: started
        enabled: yes

    - name: Configure automatic security updates
      apt:
        name: unattended-upgrades
        state: present

    - name: Enable automatic security updates
      lineinfile:
        path: /etc/apt/apt.conf.d/20auto-upgrades
        line: "{{ item }}"
        create: yes
      loop:
        - 'APT::Periodic::Update-Package-Lists "1";'
        - 'APT::Periodic::Unattended-Upgrade "1";'

  handlers:
    - name: restart fail2ban
      systemd:
        name: fail2ban
        state: restarted

- name: Secure MySQL Installation
  hosts: mysql_servers
  become: yes
  tasks:
    - name: Configure MySQL security settings
      lineinfile:
        path: /etc/mysql/mysql.conf.d/mysqld.cnf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        backup: yes
      loop:
        - { regexp: '^#?local-infile', line: 'local-infile = 0' }
        - { regexp: '^#?skip-show-database', line: 'skip-show-database' }
        - { regexp: '^#?skip-symbolic-links', line: 'skip-symbolic-links = 1' }
      notify: restart mysql

    - name: Set MySQL file permissions
      file:
        path: "{{ item }}"
        owner: mysql
        group: mysql
        mode: '0600'
      loop:
        - /etc/mysql/mysql.conf.d/mysqld.cnf
        - /var/log/mysql/error.log

  handlers:
    - name: restart mysql
      systemd:
        name: mysql
        state: restarted

- name: Secure PostgreSQL Installation
  hosts: postgresql_servers
  become: yes
  tasks:
    - name: Configure PostgreSQL security settings
      postgresql_set:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
      become_user: postgres
      loop:
        - { name: "log_connections", value: "on" }
        - { name: "log_disconnections", value: "on" }
        - { name: "log_statement", value: "all" }
        - { name: "ssl", value: "on" }
      notify: restart postgresql

    - name: Set PostgreSQL file permissions
      file:
        path: "{{ item }}"
        owner: postgres
        group: postgres
        mode: '0600'
      loop:
        - /etc/postgresql/12/main/postgresql.conf
        - /etc/postgresql/12/main/pg_hba.conf

  handlers:
    - name: restart postgresql
      systemd:
        name: postgresql
        state: restarted
EOF
Subtask 4.2: Execute Security Configuration
Run the security hardening playbook:
ansible-playbook -i inventory.ini playbooks/database-security.yml
Verify security configurations:
# Check fail2ban status
ansible database_servers -i inventory.ini -m shell -a "systemctl status fail2ban" --become

# Check MySQL security settings
ansible mysql_servers -i inventory.ini -m shell -a "grep -E '(local-infile|skip-show-database)' /etc/mysql/mysql.conf.d/mysqld.cnf" --become

# Check PostgreSQL security settings
ansible postgresql_servers -i inventory.ini -m shell -a "sudo -u postgres psql -c 'SHOW log_connections;'" --become
Task 5: Database Backup and Maintenance
Subtask 5.1: Create Backup Playbook
Create the backup playbook:
cat > playbooks/database-backup.yml << 'EOF'
---
- name: Configure Database Backups
  hosts: database_servers
  become: yes
  vars:
    backup_dir: /opt/database-backups
    backup_retention_days: 7

  tasks:
    - name: Create backup directory
      file:
        path: "{{ backup_dir }}"
        state: directory
        owner: root
        group: root
        mode: '0755'

    - name: Install backup utilities
      apt:
        name:
          - cron
          - gzip
        state: present

- name: Configure MySQL Backups
  hosts: mysql_servers
  become: yes
  vars:
    backup_dir: /opt/database-backups
    mysql_root_password: "SecureRootPass123!"

  tasks:
    - name: Create MySQL backup script
      copy:
        content: |
          #!/bin/bash
          BACKUP_DIR="{{ backup_dir }}"
          DATE=$(date +%Y%m%d_%H%M%S)
          MYSQL_USER="root"
          MYSQL_PASSWORD="{{ mysql_root_password }}"
          
          # Create backup directory if it doesn't exist
          mkdir -p $BACKUP_DIR
          
          # Backup all databases
          mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD --all-databases --single-transaction --routines --triggers | gzip > $BACKUP_DIR/mysql_backup_$DATE.sql.gz
          
          # Remove backups older than 7 days
          find $BACKUP_DIR -name "mysql_backup_*.sql.gz" -mtime +7 -delete
          
          echo "MySQL backup completed: mysql_backup_$DATE.sql.gz"
        dest: /usr/local/bin/mysql-backup.sh
        mode: '0755'

    - name: Schedule MySQL backup cron job
      cron:
        name: "MySQL Daily Backup"
        minute: "0"
        hour: "2"
        job: "/usr/local/bin/mysql-backup.sh >> /var/log/mysql-backup.log 2>&1"

- name: Configure PostgreSQL Backups
  hosts: postgresql_servers
  become: yes
  vars:
    backup_dir: /opt/database-backups

  tasks:
    - name: Create PostgreSQL backup script
      copy:
        content: |
          #!/bin/bash
          BACKUP_DIR="{{ backup_dir }}"
          DATE=$(date +%Y%m%d_%H%M%S)
          
          # Create backup directory if it doesn't exist
          mkdir -p $BACKUP_DIR
          
          # Backup all databases
          sudo -u postgres pg_dumpall | gzip > $BACKUP_DIR/postgresql_backup_$DATE.sql.gz
          
          # Remove backups older than 7 days
          find $BACKUP_DIR -name "postgresql_backup_*.sql.gz" -mtime +7 -delete
          
          echo "PostgreSQL backup completed: postgresql_backup_$DATE.sql.gz"
        dest: /usr/local/bin/postgresql-backup.sh
        mode: '0755'

    - name: Schedule PostgreSQL backup cron job
      cron:
        name: "PostgreSQL Daily Backup"
        minute: "0"
        hour: "3"
        job: "/usr/local/bin/postgresql-backup.sh >> /var/log/postgresql-backup.log 2>&1"
EOF
Subtask 5.2: Execute Backup Configuration
Run the backup configuration playbook:
ansible-playbook -i inventory.ini playbooks/database-backup.yml
Test backup scripts manually:
# Test MySQL backup
ansible mysql_servers -i inventory.ini -m shell -a "/usr/local/bin/mysql-backup.sh" --become

# Test PostgreSQL backup
ansible postgresql_servers -i inventory.ini -m shell -a "/usr/local/bin/postgresql-backup.sh" --become
Verify backup files were created:
ansible database_servers -i inventory.ini -m shell -a "ls -la /opt/database-backups/" --become
Task 6: Database Monitoring and Health Checks
Subtask 6.1: Create Monitoring Playbook
Create the monitoring playbook:
cat > playbooks/database-monitoring.yml << 'EOF'
---
- name: Configure Database Monitoring
  hosts: database_servers
  become: yes
  tasks:
    - name: Install monitoring tools
      apt:
        name:
          - htop
          - iotop
          - netstat-nat
        state: present

    - name: Create database health check script
      copy:
        content: |
          #!/bin/bash
          echo "=== Database Server Health Check ==="
          echo "Date: $(date)"
          echo "Hostname: $(hostname)"
          echo "Uptime: $(uptime)"
          echo ""
          echo "=== Memory Usage ==="
          free -h
          echo ""
          echo "=== Disk Usage ==="
          df -h
          echo ""
          echo "=== Network Connections ==="
          netstat -tuln | grep -E ':(3306|5432)'
          echo ""
        dest: /usr/local/bin/db-health-check.sh
        mode: '0755'

- name: Configure MySQL Monitoring
  hosts: mysql_servers
  become: yes
  tasks:
    - name: Create MySQL status check script
      copy:
        content: |
          #!/bin/bash
          echo "=== MySQL Status Check ==="
          systemctl status mysql --no-pager
          echo ""
          echo "=== MySQL Process List ==="
          mysql -u root -p'SecureRootPass123!' -e "SHOW PROCESSLIST;"
          echo ""
          echo "=== MySQL Variables ==="
          mysql -u root -p'SecureRootPass123!' -e "SHOW VARIABLES LIKE 'max_connections';"
          mysql -u root -p'SecureRootPass123!' -e "SHOW STATUS LIKE 'Threads_connected';"
        dest: /usr/local/bin/mysql-status.sh
        mode: '0755'

- name: Configure PostgreSQL Monitoring
  hosts: postgresql_servers
  become: yes
  tasks:
    - name: Create PostgreSQL status check script
      copy:
        content: |
          #!/bin/bash
          echo "=== PostgreSQL Status Check ==="
          systemctl status postgresql --no-pager
          echo ""
          echo "=== PostgreSQL Activity ==="
          sudo -u postgres psql -c "SELECT datname, numbackends, xact_commit, xact_rollback FROM pg_stat_database;"
          echo ""
          echo "=== PostgreSQL Connections ==="
          sudo -u postgres psql -c "SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';"
        dest: /usr/local/bin/postgresql-status.sh
        mode: '0755'
EOF
Subtask 6.2: Execute Monitoring Setup
Run the monitoring playbook:
ansible-playbook -i inventory.ini playbooks/database-monitoring.yml
Test monitoring scripts:
# Test general health check
ansible database_servers -i inventory.ini -m shell -a "/usr/local/bin/db-health-check.sh" --become

# Test MySQL monitoring
ansible mysql_servers -i inventory.ini -m shell -a "/usr/local/bin/mysql-status.sh" --become

# Test PostgreSQL monitoring
ansible postgresql_servers -i inventory.ini -m shell -a "/usr/local/bin/postgresql-status.sh" --become
Task 7: Create Comprehensive Database Management Role
Subtask 7.1: Create Ansible Role Structure
Create the role directory structure:
mkdir -p roles/database-management/{tasks,handlers,templates,vars,defaults,files,meta}
Create role metadata:
cat > roles/database-management/meta/main.yml << 'EOF'
---
galaxy_info:
  author: Lab Student
  description: Comprehensive database management role for MySQL and PostgreSQL
  company: Al Nafi Learning
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - focal
  galaxy_tags:
    - database
    - mysql
    - postgresql
    - automation

dependencies: []
EOF
Create role defaults:
cat > roles/database-management/defaults/main.yml << 'EOF'
---
# Default variables for database management role
database_type: mysql  # mysql or postgresql
backup_enabled: true
monitoring_enabled: true
security_hardening: true
backup_retention_days: 7
backup_schedule_hour: 2
backup_schedule_minute: 0

# MySQL defaults
mysql_root_password: "ChangeMe123!"
mysql_port: 3306
mysql_bind_address: "0.0.0.0"

# PostgreSQL defaults
postgresql_version: "12"
postgresql_port: 5432
postgresql_listen_addresses: "*"
EOF
Create main tasks file:
cat > roles/database-management/tasks/main.yml << 'EOF'
---
- name: Include MySQL tasks
  include_tasks: mysql.yml
  when: database_type == "mysql"

- name: Include PostgreSQL tasks
  include_tasks: postgresql.yml
  when: database_type == "postgresql"

- name: Include security tasks
  include_tasks: security.yml
  when: security_hardening | bool

- name: Include backup tasks
  include_tasks: backup.yml
  when: backup_enabled | bool

- name: Include monitoring tasks
  include_tasks: monitoring.yml
  when: monitoring_enabled | bool
EOF
Subtask 7.2: Create Role Task Files
Create MySQL tasks:
cat > roles/database-management/tasks/mysql.yml << 'EOF'
---
- name: Install MySQL packages
  apt:
    name:
      - mysql-server
      - mysql-client
      - python3-pymysql
    state: present
    update_cache: yes

- name: Start and enable MySQL service
  systemd:
    name: mysql
    state: started
    enabled: yes

- name: Set MySQL root password
  mysql_user:
    name: root
    password: "{{ mysql_root_password }}"
    login_unix_socket: /var/run/mysqld/mysqld.sock
    state: present

- name: Configure MySQL
  template:
    src: mysqld.cnf.j2
    dest: /etc/mysql/mysql.conf.d/mysqld.cnf
    backup: yes
  notify: restart mysql
EOF
Create PostgreSQL tasks:
cat > roles/database-management/tasks/postgresql.yml << 'EOF'
---
- name: Install PostgreSQL packages
  apt:
    name:
      - postgresql
      - postgresql-contrib
      - python3-psycopg2
    state: present
    update_cache: yes

- name: Start and enable PostgreSQL service
  systemd:
    name: postgresql
    state: started
    enabled: yes

- name: Configure PostgreSQL
  postgresql_set:
    name: "{{ item.name }}"
    value: "{{ item.value }}"
  become_user: postgres
  loop:
    - { name: "listen_addresses", value: "{{ postgresql_listen_addresses }}" }
    - { name: "port", value: "{{ postgresql_port }}" }
  notify: restart postgresql
EOF
Create security tasks:
cat > roles/database-management/tasks/security.yml << 'EOF'
---
- name: Install security packages
  apt:
    name:
      - fail2ban
      - ufw
    state: present

- name: Configure firewall rules
  ufw:
    rule: allow
    port: "{{ item }}"
    proto: tcp
  loop:
    - "{{ mysql_port if database_type == 'mysql' else postgresql_port }}"
    - "22"  # SSH

- name: Enable firewall
  ufw:
    state: enabled
    policy: deny
    direction: incoming
EOF
Create backup tasks:
cat > roles/database-management/tasks/backup.yml << 'EOF'
---
- name: Create backup directory
  file:
    path: /opt/database-backups
    state: directory
    mode: '0755'

- name: Create backup script for MySQL
  template:
    src: mysql-backup.sh.j2
    dest: /usr/local/bin/mysql-backup.sh
    mode: '0755'
  when: database_type == "mysql"

- name: Create backup script for PostgreSQL
  template:
    src: postgresql-backup.sh.j2
    dest: /usr/local/bin/postgresql-backup.sh
    mode: '0755'
  when: database_type == "postgresql"

- name: Schedule backup cron job
  cron:
    name: "Database Backup"
    minute: "{{ backup_schedule_minute }}"
    hour: "{{ backup_schedule_hour }}"
    job: "/usr/local/bin/{{ database_type }}-backup.sh"
EOF
Create monitoring tasks:
cat > roles/database-management/tasks/monitoring.yml << 'EOF'
---
- name: Install monitoring tools
  apt:
    name:
      - htop
      - iotop
    state: present

- name: Create monitoring script
  template:
    src: db-monitor.sh.j2
    dest: /usr/local/bin/db-monitor.sh
    mode: '0755'
EOF
Subtask 7.3: Create Role Templates
Create MySQL configuration template:
cat > roles/database-management/templates/mysqld.cnf.j2 << 'EOF'
[mysqld]
bind-address = {{ mysql_bind_address }}
port = {{ mysql_port }}
local-infile = 0
skip-show-database
skip-symbolic-links = 1

# Security settings
sql_mode = STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION

# Performance settings
max_connections = 200
innodb_buffer_pool_size = 256M
EOF
Create backup script templates:
cat > roles/database-management/templates/mysql-backup.sh.j2 << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/database-backups"
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u root -p'{{ mysql_root_password }}' --all-databases --single-transaction | gzip > $BACKUP_DIR/mysql_backup_$DATE.sql.gz
find $BACKUP_DIR -name "mysql_backup_*.sql.gz" -mtime +{{ backup_retention_days }} -delete
EOF
cat > roles/database-management/templates/postgresql-backup.sh.j2 << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/database-backups"
DATE=$(date +%Y%m%d_%H%M%S)
sudo -u postgres pg_dumpall | gzip > $BACKUP_DIR/postgresql_backup_$DATE.sql.gz
find $BACKUP_DIR -name "postgresql_backup_*.sql.gz" -mtime +{{ backup_retention_days }} -delete
EOF
Subtask 7.4: Create Role Handlers
Create handlers file:
cat > roles/database-management/handlers/main.yml << 'EOF'
---
- name: restart mysql
  systemd:
    name: mysql
    state: restarted

- name: restart postgresql
