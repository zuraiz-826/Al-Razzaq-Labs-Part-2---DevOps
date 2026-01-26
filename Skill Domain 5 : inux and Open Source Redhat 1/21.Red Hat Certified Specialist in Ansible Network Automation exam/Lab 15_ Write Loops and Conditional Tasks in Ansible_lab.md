Lab 15: Write Loops and Conditional Tasks in Ansible
Objectives
By the end of this lab, you will be able to:

Understand and implement various loop constructs in Ansible playbooks
Create conditional tasks that execute based on specific criteria
Use loops to install multiple packages efficiently
Apply conditionals to control task execution flow
Combine loops and conditionals for advanced automation scenarios
Debug and troubleshoot loop and conditional logic in playbooks
Prerequisites
Before starting this lab, you should have:

Basic understanding of Ansible fundamentals
Knowledge of YAML syntax
Familiarity with Linux command line operations
Understanding of Ansible playbook structure
Experience with basic Ansible modules (yum, apt, service, file)
Access to at least two Linux systems (control node and managed node)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure networking.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Node: Ubuntu 20.04 LTS target system
Pre-configured SSH connectivity between nodes
Sample inventory files and directory structure
Task 1: Understanding Ansible Loops
Subtask 1.1: Set Up Lab Directory Structure
First, let's create a proper directory structure for our lab exercises.

Connect to your control node and create the lab directory:
mkdir -p ~/ansible-loops-conditionals
cd ~/ansible-loops-conditionals
Create the inventory file:
cat > inventory << EOF
[webservers]
managed-node ansible_host=<MANAGED_NODE_IP> ansible_user=ubuntu

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
Test connectivity to ensure your setup is working:
ansible all -i inventory -m ping
Subtask 1.2: Basic Loop Implementation
Let's start with simple loops using the loop keyword.

Create a basic loop playbook:
cat > basic-loops.yml << 'EOF'
---
- name: Basic Loops Demonstration
  hosts: webservers
  become: yes
  tasks:
    
    - name: Create multiple directories using loop
      file:
        path: "/tmp/{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - app1
        - app2
        - app3
        - logs
        - config

    - name: Create multiple files with different content
      copy:
        content: "This is {{ item.name }} file created on {{ ansible_date_time.date }}"
        dest: "/tmp/{{ item.name }}.txt"
        mode: "{{ item.mode }}"
      loop:
        - { name: "readme", mode: "0644" }
        - { name: "script", mode: "0755" }
        - { name: "config", mode: "0600" }

    - name: Display loop results
      debug:
        msg: "Created file: {{ item.name }} with mode {{ item.mode }}"
      loop:
        - { name: "readme", mode: "0644" }
        - { name: "script", mode: "0755" }
        - { name: "config", mode: "0600" }
EOF
Execute the playbook:
ansible-playbook -i inventory basic-loops.yml
Verify the results on the managed node:
ansible webservers -i inventory -m shell -a "ls -la /tmp/*.txt"
ansible webservers -i inventory -m shell -a "ls -ld /tmp/app*"
Subtask 1.3: Installing Multiple Packages with Loops
Now let's implement a practical example of installing multiple packages.

Create a package installation playbook:
cat > package-loops.yml << 'EOF'
---
- name: Install Multiple Packages Using Loops
  hosts: webservers
  become: yes
  vars:
    web_packages:
      - nginx
      - curl
      - wget
      - unzip
    
    dev_packages:
      - git
      - vim
      - htop
      - tree
    
    database_packages:
      - mysql-client
      - postgresql-client
  
  tasks:
    
    - name: Update package cache (Ubuntu/Debian)
      apt:
        update_cache: yes
      when: ansible_os_family == "Debian"

    - name: Install web server packages
      apt:
        name: "{{ item }}"
        state: present
      loop: "{{ web_packages }}"
      when: ansible_os_family == "Debian"

    - name: Install development packages
      apt:
        name: "{{ item }}"
        state: present
      loop: "{{ dev_packages }}"
      when: ansible_os_family == "Debian"

    - name: Install database client packages
      apt:
        name: "{{ item }}"
        state: present
      loop: "{{ database_packages }}"
      when: ansible_os_family == "Debian"
      ignore_errors: yes

    - name: Verify installed packages
      command: "dpkg -l {{ item }}"
      loop: "{{ web_packages + dev_packages }}"
      register: package_status
      changed_when: false
      failed_when: false

    - name: Display package installation status
      debug:
        msg: "Package {{ item.item }} status: {{ 'INSTALLED' if item.rc == 0 else 'NOT FOUND' }}"
      loop: "{{ package_status.results }}"
EOF
Run the package installation playbook:
ansible-playbook -i inventory package-loops.yml
Task 2: Implementing Conditional Tasks
Subtask 2.1: Basic Conditionals
Let's explore different types of conditionals in Ansible.

Create a basic conditionals playbook:
cat > basic-conditionals.yml << 'EOF'
---
- name: Basic Conditionals Demonstration
  hosts: webservers
  become: yes
  vars:
    app_environment: "production"
    enable_monitoring: true
    server_role: "webserver"
  
  tasks:
    
    - name: Gather system information
      setup:
    
    - name: Install nginx only on Ubuntu systems
      apt:
        name: nginx
        state: present
      when: ansible_distribution == "Ubuntu"

    - name: Install httpd on RedHat family systems
      yum:
        name: httpd
        state: present
      when: ansible_os_family == "RedHat"

    - name: Configure production settings
      copy:
        content: |
          # Production Configuration
          server_name = {{ ansible_hostname }}
          environment = {{ app_environment }}
          debug = false
        dest: /tmp/app.conf
      when: app_environment == "production"

    - name: Configure development settings
      copy:
        content: |
          # Development Configuration
          server_name = {{ ansible_hostname }}
          environment = {{ app_environment }}
          debug = true
        dest: /tmp/app.conf
      when: app_environment == "development"

    - name: Install monitoring tools when enabled
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - htop
        - iotop
        - nethogs
      when: 
        - enable_monitoring == true
        - ansible_os_family == "Debian"

    - name: Create web directory for web servers
      file:
        path: /var/www/html/app
        state: directory
        mode: '0755'
      when: server_role == "webserver"

    - name: Display conditional results
      debug:
        msg: |
          System: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Environment: {{ app_environment }}
          Monitoring: {{ enable_monitoring }}
          Role: {{ server_role }}
EOF
Execute the conditionals playbook:
ansible-playbook -i inventory basic-conditionals.yml
Subtask 2.2: Advanced Conditionals with Multiple Criteria
Create an advanced conditionals playbook:
cat > advanced-conditionals.yml << 'EOF'
---
- name: Advanced Conditionals with Multiple Criteria
  hosts: webservers
  become: yes
  vars:
    min_memory_gb: 2
    required_disk_space_gb: 10
    supported_os_versions:
      - "18.04"
      - "20.04"
      - "22.04"
  
  tasks:
    
    - name: Gather system facts
      setup:

    - name: Check if system meets memory requirements
      debug:
        msg: "System has {{ (ansible_memtotal_mb / 1024) | round(1) }}GB RAM"
      
    - name: Install memory-intensive applications
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - docker.io
        - nodejs
        - npm
      when: 
        - (ansible_memtotal_mb / 1024) >= min_memory_gb
        - ansible_distribution == "Ubuntu"
        - ansible_distribution_version in supported_os_versions

    - name: Check available disk space
      shell: df -BG / | awk 'NR==2 {print $4}' | sed 's/G//'
      register: available_space
      changed_when: false

    - name: Install applications requiring disk space
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - mysql-server
        - postgresql
      when: 
        - available_space.stdout | int >= required_disk_space_gb
        - ansible_os_family == "Debian"

    - name: Configure firewall for web servers
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "80"
        - "443"
        - "22"
      when: 
        - ansible_distribution == "Ubuntu"
        - "'webserver' in group_names or server_role is defined"

    - name: Create backup directory on systems with sufficient space
      file:
        path: /backup
        state: directory
        mode: '0755'
      when: available_space.stdout | int >= 20

    - name: Display system compatibility report
      debug:
        msg: |
          === System Compatibility Report ===
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Memory: {{ (ansible_memtotal_mb / 1024) | round(1) }}GB (Required: {{ min_memory_gb }}GB)
          Available Disk: {{ available_space.stdout }}GB (Required: {{ required_disk_space_gb }}GB)
          OS Supported: {{ ansible_distribution_version in supported_os_versions }}
          Memory OK: {{ (ansible_memtotal_mb / 1024) >= min_memory_gb }}
          Disk OK: {{ available_space.stdout | int >= required_disk_space_gb }}
EOF
Run the advanced conditionals playbook:
ansible-playbook -i inventory advanced-conditionals.yml
Task 3: Combining Loops and Conditionals
Subtask 3.1: Complex Loop and Conditional Scenarios
Let's create scenarios that combine both loops and conditionals for real-world automation.

Create a comprehensive playbook:
cat > loops-conditionals-combined.yml << 'EOF'
---
- name: Combined Loops and Conditionals
  hosts: webservers
  become: yes
  vars:
    applications:
      - name: "nginx"
        service: "nginx"
        config_file: "/etc/nginx/nginx.conf"
        required_os: ["Ubuntu", "Debian"]
        min_memory_mb: 512
        ports: [80, 443]
      
      - name: "mysql-server"
        service: "mysql"
        config_file: "/etc/mysql/mysql.conf.d/mysqld.cnf"
        required_os: ["Ubuntu", "Debian"]
        min_memory_mb: 1024
        ports: [3306]
      
      - name: "redis-server"
        service: "redis-server"
        config_file: "/etc/redis/redis.conf"
        required_os: ["Ubuntu", "Debian"]
        min_memory_mb: 256
        ports: [6379]

    users:
      - name: "webadmin"
        groups: ["www-data", "sudo"]
        shell: "/bin/bash"
        create_when: "webserver"
      
      - name: "dbadmin"
        groups: ["mysql", "sudo"]
        shell: "/bin/bash"
        create_when: "database"
      
      - name: "devuser"
        groups: ["developers", "sudo"]
        shell: "/bin/bash"
        create_when: "development"

    server_type: "webserver"  # Change this to test different scenarios
  
  tasks:
    
    - name: Gather system information
      setup:

    - name: Install applications based on system requirements
      apt:
        name: "{{ item.name }}"
        state: present
      loop: "{{ applications }}"
      when: 
        - ansible_distribution in item.required_os
        - ansible_memtotal_mb >= item.min_memory_mb
      register: app_installation

    - name: Start and enable services for successfully installed applications
      systemd:
        name: "{{ item.item.service }}"
        state: started
        enabled: yes
      loop: "{{ app_installation.results }}"
      when: 
        - item is not skipped
        - item is succeeded

    - name: Configure firewall for installed applications
      ufw:
        rule: allow
        port: "{{ port }}"
        proto: tcp
      loop: "{{ applications | selectattr('name', 'in', ansible_facts.packages.keys()) | map(attribute='ports') | flatten }}"
      loop_control:
        loop_var: port
      when: 
        - ansible_distribution == "Ubuntu"
        - ansible_facts.packages is defined

    - name: Create users based on server type
      user:
        name: "{{ item.name }}"
        groups: "{{ item.groups }}"
        shell: "{{ item.shell }}"
        create_home: yes
        state: present
      loop: "{{ users }}"
      when: item.create_when == server_type

    - name: Create application-specific directories
      file:
        path: "/opt/{{ item.name }}"
        state: directory
        mode: '0755'
        owner: root
        group: root
      loop: "{{ applications }}"
      when: 
        - ansible_distribution in item.required_os
        - ansible_memtotal_mb >= item.min_memory_mb

    - name: Generate configuration files for installed applications
      template:
        src: "{{ item.name }}.conf.j2"
        dest: "{{ item.config_file }}"
        backup: yes
      loop: "{{ applications }}"
      when: 
        - ansible_distribution in item.required_os
        - ansible_memtotal_mb >= item.min_memory_mb
        - item.name in ansible_facts.packages.keys()
      ignore_errors: yes  # Template files might not exist in this demo

    - name: Display installation summary
      debug:
        msg: |
          === Installation Summary ===
          Application: {{ item.name }}
          Status: {{ 'INSTALLED' if (ansible_distribution in item.required_os and ansible_memtotal_mb >= item.min_memory_mb) else 'SKIPPED' }}
          Reason: {{ 'Requirements met' if (ansible_distribution in item.required_os and ansible_memtotal_mb >= item.min_memory_mb) else 'Requirements not met' }}
          Required OS: {{ item.required_os | join(', ') }}
          Required Memory: {{ item.min_memory_mb }}MB
          System Memory: {{ ansible_memtotal_mb }}MB
      loop: "{{ applications }}"
EOF
Execute the combined playbook:
ansible-playbook -i inventory loops-conditionals-combined.yml
Subtask 3.2: Error Handling with Loops and Conditionals
Create an error handling playbook:
cat > error-handling-loops.yml << 'EOF'
---
- name: Error Handling with Loops and Conditionals
  hosts: webservers
  become: yes
  vars:
    packages_to_test:
      - name: "curl"
        critical: true
      - name: "wget"
        critical: true
      - name: "nonexistent-package"
        critical: false
      - name: "vim"
        critical: true
      - name: "another-fake-package"
        critical: false

    services_to_check:
      - name: "ssh"
        should_be_running: true
      - name: "nginx"
        should_be_running: false
      - name: "mysql"
        should_be_running: false
  
  tasks:
    
    - name: Attempt to install packages with error handling
      apt:
        name: "{{ item.name }}"
        state: present
      loop: "{{ packages_to_test }}"
      register: package_results
      failed_when: 
        - package_results.failed is defined
        - package_results.failed == true
        - item.critical == true
      ignore_errors: yes

    - name: Display package installation results
      debug:
        msg: |
          Package: {{ item.item.name }}
          Critical: {{ item.item.critical }}
          Status: {{ 'SUCCESS' if item.failed is not defined else 'FAILED' }}
          Action: {{ 'CONTINUE' if not item.item.critical else 'WOULD STOP IF FAILED' }}
      loop: "{{ package_results.results }}"

    - name: Check service status with conditionals
      systemd:
        name: "{{ item.name }}"
      register: service_status
      loop: "{{ services_to_check }}"
      failed_when: false
      changed_when: false

    - name: Start services that should be running but aren't
      systemd:
        name: "{{ item.item.name }}"
        state: started
        enabled: yes
      loop: "{{ service_status.results }}"
      when: 
        - item.item.should_be_running == true
        - item.status.ActiveState != "active"
      ignore_errors: yes

    - name: Create summary report
      debug:
        msg: |
          === Error Handling Summary ===
          Total packages processed: {{ packages_to_test | length }}
          Critical packages: {{ packages_to_test | selectattr('critical', 'equalto', true) | list | length }}
          Non-critical packages: {{ packages_to_test | selectattr('critical', 'equalto', false) | list | length }}
          Services checked: {{ services_to_check | length }}
          
          Failed installations were {{ 'ignored for non-critical' if true else 'handled appropriately' }} packages.
EOF
Run the error handling playbook:
ansible-playbook -i inventory error-handling-loops.yml
Task 4: Advanced Loop Techniques
Subtask 4.1: Using Different Loop Types
Create a playbook demonstrating various loop types:
cat > advanced-loop-types.yml << 'EOF'
---
- name: Advanced Loop Types in Ansible
  hosts: webservers
  become: yes
  vars:
    user_data:
      john:
        full_name: "John Doe"
        email: "john@example.com"
        department: "IT"
      jane:
        full_name: "Jane Smith"
        email: "jane@example.com"
        department: "HR"
      bob:
        full_name: "Bob Johnson"
        email: "bob@example.com"
        department: "Finance"

    network_config:
      interfaces:
        eth0:
          ip: "192.168.1.10"
          netmask: "255.255.255.0"
        eth1:
          ip: "10.0.0.10"
          netmask: "255.255.0.0"
  
  tasks:
    
    - name: Loop with range (create numbered directories)
      file:
        path: "/tmp/dir{{ item }}"
        state: directory
        mode: '0755'
      loop: "{{ range(1, 6) | list }}"

    - name: Loop with until (wait for service)
      uri:
        url: "http://localhost"
        method: GET
      register: web_check
      until: web_check.status == 200
      retries: 5
      delay: 2
      ignore_errors: yes

    - name: Loop over dictionary keys and values
      debug:
        msg: "User: {{ item.key }}, Name: {{ item.value.full_name }}, Email: {{ item.value.email }}"
      loop: "{{ user_data | dict2items }}"

    - name: Create user accounts from dictionary
      user:
        name: "{{ item.key }}"
        comment: "{{ item.value.full_name }}"
        create_home: yes
        state: present
      loop: "{{ user_data | dict2items }}"

    - name: Loop with subelements
      debug:
        msg: "Interface {{ item.key }} has IP {{ item.value.ip }}"
      loop: "{{ network_config.interfaces | dict2items }}"

    - name: Nested loops using include_tasks
      include_tasks: nested_loop_task.yml
      loop: "{{ user_data | dict2items }}"
      loop_control:
        loop_var: outer_item

    - name: Loop with conditional break simulation
      debug:
        msg: "Processing item {{ item }}"
      loop: "{{ range(1, 11) | list }}"
      when: item <= 7  # Simulates breaking at item 8

    - name: Loop with index
      debug:
        msg: "Item {{ ansible_loop.index }}: {{ item.key }} ({{ item.value.department }})"
      loop: "{{ user_data | dict2items }}"
      loop_control:
        extended: yes
EOF
Create the nested task file:
cat > nested_loop_task.yml << 'EOF'
---
- name: Nested task for {{ outer_item.key }}
  debug:
    msg: "Processing {{ outer_item.key }} in department {{ outer_item.value.department }}"

- name: Create department directory for {{ outer_item.key }}
  file:
    path: "/tmp/departments/{{ outer_item.value.department }}"
    state: directory
    mode: '0755'
EOF
Execute the advanced loops playbook:
ansible-playbook -i inventory advanced-loop-types.yml
Subtask 4.2: Performance Optimization with Loops
Create a performance-optimized playbook:
cat > optimized-loops.yml << 'EOF'
---
- name: Performance Optimized Loops
  hosts: webservers
  become: yes
  vars:
    large_package_list:
      - curl
      - wget
      - vim
      - git
      - htop
      - tree
      - unzip
      - zip
      - rsync
      - screen

    config_files:
      - { src: "app1.conf", dest: "/etc/app1/app1.conf", mode: "0644" }
      - { src: "app2.conf", dest: "/etc/app2/app2.conf", mode: "0644" }
      - { src: "app3.conf", dest: "/etc/app3/app3.conf", mode: "0600" }
  
  tasks:
    
    # Optimized: Install all packages in one task instead of looping
    - name: Install multiple packages efficiently (single task)
      apt:
        name: "{{ large_package_list }}"
        state: present
        update_cache: yes

    # Less efficient approach (for comparison)
    - name: Install packages one by one (less efficient)
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - nano
        - less
        - more
      when: false  # Disabled for demo

    # Optimized: Use async for time-consuming tasks
    - name: Download large files asynchronously
      get_url:
        url: "https://releases.ubuntu.com/20.04/ubuntu-20.04.6-desktop-amd64.iso"
        dest: "/tmp/ubuntu-{{ item }}.iso"
        timeout: 30
      loop:
        - "backup1"
        - "backup2"
      async: 300
      poll: 0
      register: download_jobs
      ignore_errors: yes

    # Check async job status
    - name: Check download status
      async_status:
        jid: "{{ item.ansible_job_id }}"
      loop: "{{ download_jobs.results }}"
      register: download_status
      until: download_status.finished
      retries: 30
      delay: 10
      when: item.ansible_job_id is defined
      ignore_errors: yes

    # Batch operations
    - name: Create multiple directories in batch
      file:
        path: "/tmp/batch/{{ item }}"
        state: directory
        mode: '0755'
      loop: "{{ range(1, 21) | list }}"

    # Use loop_control for better performance monitoring
    - name: Process items with progress tracking
      debug:
        msg: |
          Processing item {{ ansible_loop.index }} of {{ ansible_loop.length }}
          Item: {{ item }}
          Progress: {{ (ansible_loop.index / ansible_loop.length * 100) | round(1) }}%
      loop: "{{ large_package_list }}"
      loop_control:
        extended: yes
        pause: 1  # Pause between iterations

    - name: Performance summary
      debug:
        msg: |
          === Performance Summary ===
          Packages installed in batch: {{ large_package_list | length }}
          Directories created: 20
          Async downloads initiated: {{ download_jobs.results | length }}
          Total loop iterations: {{ large_package_list | length + 20 }}
EOF
Run the optimized loops playbook:
ansible-playbook -i inventory optimized-loops.yml
Task 5: Real-World Scenarios
Subtask 5.1: Web Server Deployment with Loops and Conditionals
Create a comprehensive web server deployment playbook:
cat > web-deployment.yml << 'EOF'
---
- name: Complete Web Server Deployment
  hosts: webservers
  become: yes
  vars:
    web_apps:
      - name: "frontend"
        port: 3000
        repo: "https://github.com/example/frontend.git"
        dependencies: ["nodejs", "npm"]
        environment: "production"
      
      - name: "api"
        port: 8080
        repo: "https://github.com/example/api.git"
        dependencies: ["python3", "python3-pip", "python3-venv"]
        environment: "production"
      
      - name: "admin"
        port: 9000
        repo: "https://github.com/example/admin.git"
        dependencies: ["php", "php-fpm", "php-mysql"]
        environment: "staging"

    ssl_domains:
      - "example.com"
      - "api.example.com"
      - "admin.example.com"

    backup_paths:
      - "/var/www"
      - "/etc/nginx"
      - "/etc/ssl"

    monitoring_enabled: true
    ssl_enabled: true
    backup_enabled: true
  
  tasks:
    
    - name: Update system packages
      apt:
        update_cache: yes
        upgrade: dist
      when: ansible_os_family == "Debian"

    - name: Install base web server packages
      apt:
        name:
          - nginx
          - ufw
          - certbot
          - python3-certbot-nginx
        state: present

    - name: Install application dependencies
      apt:
        name: "{{ item.1 }}"
        state: present
      loop: "{{ web_apps | subelements('dependencies') }}"
      when: item.0.environment == "production"

    - name: Create application directories
      file:
        path: "/var/www/{{ item.name }}"
        state: directory
        mode: '0755'
        owner: www-data
        group: www-data
      loop: "{{ web_apps }}"

    - name: Clone application repositories
      git:
        repo: "{{ item.repo }}"
        dest: "/var/www/{{ item.name }}"
        version: "{{ 'main' if item.environment == 'production' else 'develop' }}"
      loop: "{{ web_apps }}"
      become_user: www-data
      ignore_errors: yes  # Repos might not exist

    - name: Configure nginx virtual hosts
      template:
        src: nginx-vhost.j2
        dest: "/etc/nginx/sites-available/{{ item.name }}"
      loop: "{{ web_apps }}"
      notify: restart nginx
      ignore_errors: yes  # Template might not exist

    - name: Enable nginx sites
      file:
        src: "/etc/nginx/sites-available/{{ item.name }}"
        dest: "/etc/nginx/sites-enabled/{{ item.name }}"
        state: link
      loop: "{{ web_apps }}"
      notify: restart nginx

    - name: Configure firewall for web applications
      ufw:
        rule: allow
        port: "{{ item.port }}"
        proto: tcp
      loop: "{{ web_apps }}"

    - name: Configure firewall for standard web ports
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "80"
        - "443"
        - "22"

    - name: Generate SSL certificates
      command: >
        certbot --nginx -d {{ item }} --non-interactive --agree-tos 
        --email admin@{{ item }} --redirect
      loop: "{{ ssl_domains }}"
      when: 
        - ssl_enabled == true
        - ansible_distribution == "Ubuntu"
      ignore_errors: yes  # Might fail in test environment

    - name: Install monitoring tools
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - htop
        - iotop
        - nethogs
        - nginx-module-vts
      when: monitoring_enabled == true

    - name: Create backup directories
      file:
        path: "/backup/{{ item | basename }}"
        state: directory
        mode: '0700'
      loop: "{{ backup_paths }}"
      when: backup_enabled == true

    - name: Create backup scripts
      template:
        src: backup-script.j2
        dest: "/usr/local/bin/backup-{{ item | basename }}.sh"
        mode: '0755'
      loop: "{{ backup_paths }}"
      when: backup_enabled == true
      ignore_errors: yes

    - name: Schedule backups
      cron:
        name: "Backup {{ item | basename }}"
        minute: "0"
        hour: "2"
        job: "/usr/local/bin/backup-{{ item | basename }}.sh"
      loop: "{{ backup_paths }}"
      when: backup_enabled == true

    - name: Start and enable services
      systemd:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - nginx
        - ufw

    - name: Display deployment summary
      debug:
        msg: |
          === Web Deployment Summary ===
          Applications deployed: {{ web_apps | length }}
          Production apps: {{ web_apps | selectattr('environment', 'equalto', 'production') | list | length }}
          Staging apps: {{ web_apps | selectattr('environment', 'equalto', 'staging') | list | length }}
          SSL domains: {{ ssl_domains | length if ssl_enabled else 0 }}
          Backup paths: {{ backup_paths | length if backup_enabled else 0 }}
          Monitoring: {{ 'Enabled' if monitoring_enabled else 'Disable
