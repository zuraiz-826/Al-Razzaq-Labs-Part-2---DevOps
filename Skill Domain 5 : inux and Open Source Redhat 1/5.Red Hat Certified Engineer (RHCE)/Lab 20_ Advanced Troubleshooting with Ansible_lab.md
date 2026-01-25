Lab 20: Advanced Troubleshooting with Ansible
Objectives
By the end of this lab, students will be able to:

Master advanced debugging techniques using Ansible's built-in troubleshooting tools
Implement step-by-step execution and differential analysis for complex playbooks
Perform comprehensive dry-run testing to prevent execution errors
Analyze and troubleshoot service-related issues using system logs
Apply systematic debugging methodologies for large-scale Ansible deployments
Identify and resolve common playbook failures in enterprise environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ansible playbooks, tasks, and modules
Familiarity with YAML syntax and structure
Knowledge of Linux command-line operations
Understanding of system services and log management
Experience with basic Ansible inventory and configuration files
Completion of fundamental Ansible labs or equivalent experience
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: 3 target servers (web1, web2, db1)
Pre-configured SSH key authentication
Sample playbooks with intentional issues for troubleshooting practice
Task 1: Advanced Debugging with Step-by-Step Execution
Subtask 1.1: Setting Up the Lab Environment
First, let's verify our Ansible installation and create our working directory:

# Check Ansible version
ansible --version

# Create lab directory
mkdir -p ~/ansible-troubleshooting-lab
cd ~/ansible-troubleshooting-lab

# Verify connectivity to managed nodes
ansible all -m ping
Subtask 1.2: Creating a Complex Playbook for Testing
Create a comprehensive playbook that we'll use for debugging exercises:

# Create the main playbook
cat > complex-deployment.yml << 'EOF'
---
- name: Complex Web Application Deployment
  hosts: web_servers
  become: yes
  vars:
    app_name: "mywebapp"
    app_version: "2.1.0"
    web_port: 8080
    db_host: "{{ hostvars['db1']['ansible_default_ipv4']['address'] }}"
    
  tasks:
    - name: Install required packages
      yum:
        name:
          - httpd
          - php
          - php-mysql
          - wget
          - unzip
        state: present
      tags: packages
      
    - name: Create application directory
      file:
        path: "/opt/{{ app_name }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
      tags: directories
      
    - name: Download application source
      get_url:
        url: "https://github.com/example/{{ app_name }}/archive/v{{ app_version }}.zip"
        dest: "/tmp/{{ app_name }}-{{ app_version }}.zip"
        timeout: 30
      tags: download
      
    - name: Extract application
      unarchive:
        src: "/tmp/{{ app_name }}-{{ app_version }}.zip"
        dest: "/opt/{{ app_name }}"
        remote_src: yes
        owner: apache
        group: apache
      tags: extract
      
    - name: Configure Apache virtual host
      template:
        src: vhost.conf.j2
        dest: "/etc/httpd/conf.d/{{ app_name }}.conf"
        backup: yes
      notify: restart apache
      tags: configuration
      
    - name: Start and enable Apache
      systemd:
        name: httpd
        state: started
        enabled: yes
      tags: services
      
    - name: Configure firewall
      firewalld:
        port: "{{ web_port }}/tcp"
        permanent: yes
        state: enabled
        immediate: yes
      tags: firewall
      
  handlers:
    - name: restart apache
      systemd:
        name: httpd
        state: restarted

- name: Database Server Configuration
  hosts: db_servers
  become: yes
  vars:
    mysql_root_password: "SecurePass123!"
    app_db_name: "webapp_db"
    app_db_user: "webapp_user"
    app_db_password: "WebApp456!"
    
  tasks:
    - name: Install MySQL server
      yum:
        name:
          - mysql-server
          - python3-PyMySQL
        state: present
      tags: database
      
    - name: Start and enable MySQL
      systemd:
        name: mysqld
        state: started
        enabled: yes
      tags: database
      
    - name: Set MySQL root password
      mysql_user:
        name: root
        password: "{{ mysql_root_password }}"
        login_unix_socket: /var/lib/mysql/mysql.sock
      tags: database
      
    - name: Create application database
      mysql_db:
        name: "{{ app_db_name }}"
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"
      tags: database
      
    - name: Create application user
      mysql_user:
        name: "{{ app_db_user }}"
        password: "{{ app_db_password }}"
        priv: "{{ app_db_name }}.*:ALL"
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"
      tags: database
EOF
Create the Apache virtual host template:

# Create templates directory
mkdir -p templates

# Create the virtual host template
cat > templates/vhost.conf.j2 << 'EOF'
<VirtualHost *:{{ web_port }}>
    ServerName {{ inventory_hostname }}
    DocumentRoot /opt/{{ app_name }}/public
    
    <Directory /opt/{{ app_name }}/public>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog /var/log/httpd/{{ app_name }}_error.log
    CustomLog /var/log/httpd/{{ app_name }}_access.log combined
    
    # Database connection settings
    SetEnv DB_HOST {{ db_host }}
    SetEnv DB_NAME {{ app_db_name }}
    SetEnv DB_USER {{ app_db_user }}
    SetEnv DB_PASS {{ app_db_password }}
</VirtualHost>
EOF
Subtask 1.3: Using Step-by-Step Execution
The --step flag allows you to execute tasks one at a time, providing granular control:

# Execute playbook with step-by-step control
ansible-playbook complex-deployment.yml --step

# When prompted, you can choose:
# y - execute the task
# n - skip the task
# c - continue without asking
Practice Exercise: Run the playbook with --step and observe each task execution. Pay attention to:

Variable resolution
Task dependencies
Handler triggering
Error propagation
Subtask 1.4: Advanced Step Execution with Tags
Combine step execution with tags for targeted debugging:

# Step through only package installation tasks
ansible-playbook complex-deployment.yml --step --tags packages

# Step through configuration tasks only
ansible-playbook complex-deployment.yml --step --tags configuration

# Step through multiple tag categories
ansible-playbook complex-deployment.yml --step --tags "packages,services"
Task 2: Differential Analysis and Change Detection
Subtask 2.1: Using the --diff Flag
The --diff flag shows exactly what changes Ansible will make:

# Run playbook with diff to see changes
ansible-playbook complex-deployment.yml --diff

# Combine diff with check mode for safe analysis
ansible-playbook complex-deployment.yml --diff --check
Subtask 2.2: Creating a Modified Configuration for Diff Testing
Let's modify our template to see diff in action:

# Create a modified version of the virtual host template
cat > templates/vhost.conf.j2 << 'EOF'
<VirtualHost *:{{ web_port }}>
    ServerName {{ inventory_hostname }}
    DocumentRoot /opt/{{ app_name }}/public
    
    # Enhanced security settings
    <Directory /opt/{{ app_name }}/public>
        AllowOverride All
        Require all granted
        Options -Indexes +FollowSymLinks
    </Directory>
    
    # Improved logging
    ErrorLog /var/log/httpd/{{ app_name }}_error.log
    CustomLog /var/log/httpd/{{ app_name }}_access.log combined
    LogLevel warn
    
    # Database connection settings
    SetEnv DB_HOST {{ db_host }}
    SetEnv DB_NAME {{ app_db_name }}
    SetEnv DB_USER {{ app_db_user }}
    SetEnv DB_PASS {{ app_db_password }}
    
    # Performance settings
    KeepAlive On
    MaxKeepAliveRequests 100
    KeepAliveTimeout 15
</VirtualHost>
EOF
Now run with diff to see the changes:

# See what will change
ansible-playbook complex-deployment.yml --diff --check --tags configuration

# Apply changes and see diff output
ansible-playbook complex-deployment.yml --diff --tags configuration
Subtask 2.3: Advanced Diff Analysis
Create a script to capture and analyze diff output:

# Create diff analysis script
cat > analyze-changes.sh << 'EOF'
#!/bin/bash

PLAYBOOK="$1"
LOGFILE="changes-$(date +%Y%m%d-%H%M%S).log"

echo "=== Ansible Diff Analysis ===" | tee "$LOGFILE"
echo "Playbook: $PLAYBOOK" | tee -a "$LOGFILE"
echo "Timestamp: $(date)" | tee -a "$LOGFILE"
echo "================================" | tee -a "$LOGFILE"

# Run with diff and capture output
ansible-playbook "$PLAYBOOK" --diff --check 2>&1 | tee -a "$LOGFILE"

echo "================================" | tee -a "$LOGFILE"
echo "Analysis complete. Log saved to: $LOGFILE" | tee -a "$LOGFILE"

# Extract changed files
echo "Files that would be modified:" | tee -a "$LOGFILE"
grep -E "^\+\+\+|^---" "$LOGFILE" | sort | uniq | tee -a "$LOGFILE"
EOF

chmod +x analyze-changes.sh

# Use the analysis script
./analyze-changes.sh complex-deployment.yml
Task 3: Comprehensive Dry-Run Testing
Subtask 3.1: Basic Check Mode Operations
Check mode (--check) performs a dry run without making changes:

# Basic dry run
ansible-playbook complex-deployment.yml --check

# Dry run with verbose output
ansible-playbook complex-deployment.yml --check -v

# Dry run with maximum verbosity
ansible-playbook complex-deployment.yml --check -vvv
Subtask 3.2: Creating a Pre-Flight Check Playbook
Create a dedicated playbook for pre-flight checks:

cat > preflight-checks.yml << 'EOF'
---
- name: Pre-flight System Checks
  hosts: all
  gather_facts: yes
  tasks:
    - name: Check disk space
      shell: df -h / | awk 'NR==2 {print $5}' | sed 's/%//'
      register: disk_usage
      changed_when: false
      
    - name: Verify sufficient disk space
      fail:
        msg: "Insufficient disk space: {{ disk_usage.stdout }}% used"
      when: disk_usage.stdout|int > 85
      
    - name: Check memory availability
      shell: free -m | awk 'NR==2{printf "%.0f", $3*100/$2}'
      register: memory_usage
      changed_when: false
      
    - name: Verify sufficient memory
      fail:
        msg: "High memory usage: {{ memory_usage.stdout }}%"
      when: memory_usage.stdout|int > 90
      
    - name: Check required ports availability
      wait_for:
        port: "{{ item }}"
        host: "{{ inventory_hostname }}"
        state: stopped
        timeout: 5
      loop:
        - 80
        - 8080
        - 3306
      ignore_errors: yes
      register: port_check
      
    - name: Verify network connectivity
      uri:
        url: "http://{{ item }}"
        method: HEAD
        timeout: 10
      loop:
        - "google.com"
        - "github.com"
      ignore_errors: yes
      register: network_check
      
    - name: Display system information
      debug:
        msg:
          - "Hostname: {{ inventory_hostname }}"
          - "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
          - "Architecture: {{ ansible_architecture }}"
          - "CPU Cores: {{ ansible_processor_vcpus }}"
          - "Total Memory: {{ ansible_memtotal_mb }}MB"
          - "Disk Usage: {{ disk_usage.stdout }}%"
          - "Memory Usage: {{ memory_usage.stdout }}%"
EOF

# Run pre-flight checks
ansible-playbook preflight-checks.yml
Subtask 3.3: Advanced Check Mode with Conditional Logic
Create a playbook that demonstrates check mode with complex conditions:

cat > conditional-deployment.yml << 'EOF'
---
- name: Conditional Deployment with Check Mode Support
  hosts: web_servers
  become: yes
  vars:
    deployment_mode: "{{ ansible_check_mode | ternary('check', 'deploy') }}"
    
  tasks:
    - name: Display deployment mode
      debug:
        msg: "Running in {{ deployment_mode }} mode"
        
    - name: Check if application already exists
      stat:
        path: "/opt/{{ app_name }}"
      register: app_exists
      
    - name: Determine deployment action
      set_fact:
        deployment_action: "{{ 'upgrade' if app_exists.stat.exists else 'install' }}"
        
    - name: Display deployment action
      debug:
        msg: "Will perform {{ deployment_action }} of {{ app_name }}"
        
    - name: Backup existing application (if upgrading)
      archive:
        path: "/opt/{{ app_name }}"
        dest: "/opt/{{ app_name }}-backup-{{ ansible_date_time.epoch }}.tar.gz"
      when: 
        - deployment_action == "upgrade"
        - not ansible_check_mode
        
    - name: Simulate backup in check mode
      debug:
        msg: "Would create backup: /opt/{{ app_name }}-backup-{{ ansible_date_time.epoch }}.tar.gz"
      when:
        - deployment_action == "upgrade"
        - ansible_check_mode
        
    - name: Install packages (check mode aware)
      yum:
        name:
          - httpd
          - php
          - php-mysql
        state: present
      register: package_install
      
    - name: Display package installation results
      debug:
        msg: "Packages {{ 'would be' if ansible_check_mode else 'were' }} installed: {{ package_install.results | map(attribute='name') | list }}"
      when: package_install.results is defined
EOF

# Test with check mode
ansible-playbook conditional-deployment.yml --check

# Test with actual deployment
ansible-playbook conditional-deployment.yml
Task 4: Service Troubleshooting Using Logs
Subtask 4.1: Creating a Service Monitoring Playbook
Create a comprehensive service monitoring and troubleshooting playbook:

cat > service-troubleshooting.yml << 'EOF'
---
- name: Service Troubleshooting and Log Analysis
  hosts: all
  become: yes
  vars:
    services_to_check:
      - httpd
      - mysqld
      - firewalld
      - sshd
    log_files:
      - /var/log/messages
      - /var/log/httpd/error_log
      - /var/log/mysqld.log
      - /var/log/secure
      
  tasks:
    - name: Check service status
      systemd:
        name: "{{ item }}"
      register: service_status
      loop: "{{ services_to_check }}"
      ignore_errors: yes
      
    - name: Display service status summary
      debug:
        msg: |
          Service Status Summary:
          {% for result in service_status.results %}
          - {{ result.item }}: {{ result.status.ActiveState | default('unknown') }}
          {% endfor %}
          
    - name: Identify failed services
      set_fact:
        failed_services: "{{ service_status.results | selectattr('status.ActiveState', 'equalto', 'failed') | map(attribute='item') | list }}"
        
    - name: Get detailed status for failed services
      shell: "systemctl status {{ item }} --no-pager -l"
      register: failed_service_details
      loop: "{{ failed_services }}"
      when: failed_services | length > 0
      
    - name: Display failed service details
      debug:
        msg: |
          Failed Service: {{ item.item }}
          Status Output:
          {{ item.stdout }}
      loop: "{{ failed_service_details.results }}"
      when: failed_services | length > 0
      
    - name: Check recent log entries for errors
      shell: "tail -50 {{ item }} | grep -i error || echo 'No recent errors found'"
      register: log_errors
      loop: "{{ log_files }}"
      ignore_errors: yes
      changed_when: false
      
    - name: Display log error summary
      debug:
        msg: |
          Log File: {{ item.item }}
          Recent Errors:
          {{ item.stdout }}
      loop: "{{ log_errors.results }}"
      when: "'No recent errors found' not in item.stdout"
      
    - name: Check disk space for log directories
      shell: "df -h {{ item | dirname }}"
      register: log_disk_space
      loop: "{{ log_files }}"
      changed_when: false
      
    - name: Analyze system resource usage
      shell: |
        echo "=== CPU Usage ==="
        top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
        echo "=== Memory Usage ==="
        free -m | awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }'
        echo "=== Load Average ==="
        uptime | awk -F'load average:' '{ print $2 }'
      register: system_resources
      changed_when: false
      
    - name: Display system resource analysis
      debug:
        msg: |
          System Resource Analysis:
          {{ system_resources.stdout }}
EOF

# Run service troubleshooting
ansible-playbook service-troubleshooting.yml
Subtask 4.2: Advanced Log Analysis with Custom Filters
Create a specialized log analysis playbook:

cat > log-analysis.yml << 'EOF'
---
- name: Advanced Log Analysis and Troubleshooting
  hosts: all
  become: yes
  vars:
    analysis_timeframe: "1 hour ago"
    critical_keywords:
      - "error"
      - "failed"
      - "critical"
      - "emergency"
      - "alert"
      - "panic"
    log_locations:
      system: /var/log/messages
      apache: /var/log/httpd/error_log
      mysql: /var/log/mysqld.log
      auth: /var/log/secure
      
  tasks:
    - name: Create log analysis directory
      file:
        path: /tmp/log-analysis
        state: directory
        mode: '0755'
        
    - name: Analyze system logs for critical events
      shell: |
        since_time=$(date -d "{{ analysis_timeframe }}" "+%b %d %H:%M")
        current_year=$(date "+%Y")
        
        echo "=== Critical Events Since {{ analysis_timeframe }} ===" > /tmp/log-analysis/critical-events.log
        
        for keyword in {{ critical_keywords | join(' ') }}; do
          echo "--- Searching for: $keyword ---" >> /tmp/log-analysis/critical-events.log
          awk -v year="$current_year" -v since="$since_time" '
            BEGIN { 
              cmd = "date -d \"" since "\" +%s"
              cmd | getline since_epoch
              close(cmd)
            }
            {
              log_time = $1 " " $2 " " $3
              cmd = "date -d \"" year " " log_time "\" +%s 2>/dev/null"
              if ((cmd | getline log_epoch) > 0 && log_epoch >= since_epoch) {
                if (tolower($0) ~ /'"$keyword"'/) print $0
              }
              close(cmd)
            }
          ' {{ log_locations.system }} >> /tmp/log-analysis/critical-events.log 2>/dev/null || echo "No entries found for $keyword" >> /tmp/log-analysis/critical-events.log
        done
      changed_when: false
      
    - name: Analyze Apache error patterns
      shell: |
        if [ -f "{{ log_locations.apache }}" ]; then
          echo "=== Apache Error Analysis ===" > /tmp/log-analysis/apache-errors.log
          echo "--- Error Frequency ---" >> /tmp/log-analysis/apache-errors.log
          tail -1000 {{ log_locations.apache }} | awk '{print $1, $2, $3}' | sort | uniq -c | sort -nr | head -10 >> /tmp/log-analysis/apache-errors.log
          
          echo "--- Recent 404 Errors ---" >> /tmp/log-analysis/apache-errors.log
          tail -500 {{ log_locations.apache }} | grep "404" | tail -10 >> /tmp/log-analysis/apache-errors.log
          
          echo "--- Recent 500 Errors ---" >> /tmp/log-analysis/apache-errors.log
          tail -500 {{ log_locations.apache }} | grep "500" | tail -10 >> /tmp/log-analysis/apache-errors.log
        else
          echo "Apache error log not found" > /tmp/log-analysis/apache-errors.log
        fi
      changed_when: false
      
    - name: Analyze authentication failures
      shell: |
        if [ -f "{{ log_locations.auth }}" ]; then
          echo "=== Authentication Analysis ===" > /tmp/log-analysis/auth-analysis.log
          echo "--- Failed SSH Attempts ---" >> /tmp/log-analysis/auth-analysis.log
          grep "Failed password" {{ log_locations.auth }} | tail -20 >> /tmp/log-analysis/auth-analysis.log
          
          echo "--- Successful Logins ---" >> /tmp/log-analysis/auth-analysis.log
          grep "Accepted password" {{ log_locations.auth }} | tail -10 >> /tmp/log-analysis/auth-analysis.log
          
          echo "--- Failed Login Summary by IP ---" >> /tmp/log-analysis/auth-analysis.log
          grep "Failed password" {{ log_locations.auth }} | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | head -10 >> /tmp/log-analysis/auth-analysis.log
        else
          echo "Auth log not found" > /tmp/log-analysis/auth-analysis.log
        fi
      changed_when: false
      
    - name: Generate comprehensive report
      shell: |
        echo "=== SYSTEM TROUBLESHOOTING REPORT ===" > /tmp/log-analysis/summary-report.log
        echo "Generated: $(date)" >> /tmp/log-analysis/summary-report.log
        echo "Host: $(hostname)" >> /tmp/log-analysis/summary-report.log
        echo "Analysis Period: {{ analysis_timeframe }}" >> /tmp/log-analysis/summary-report.log
        echo "" >> /tmp/log-analysis/summary-report.log
        
        echo "=== SYSTEM STATUS ===" >> /tmp/log-analysis/summary-report.log
        systemctl list-units --failed --no-pager >> /tmp/log-analysis/summary-report.log
        echo "" >> /tmp/log-analysis/summary-report.log
        
        echo "=== DISK USAGE ===" >> /tmp/log-analysis/summary-report.log
        df -h >> /tmp/log-analysis/summary-report.log
        echo "" >> /tmp/log-analysis/summary-report.log
        
        echo "=== MEMORY USAGE ===" >> /tmp/log-analysis/summary-report.log
        free -h >> /tmp/log-analysis/summary-report.log
        echo "" >> /tmp/log-analysis/summary-report.log
        
        echo "=== LOAD AVERAGE ===" >> /tmp/log-analysis/summary-report.log
        uptime >> /tmp/log-analysis/summary-report.log
        echo "" >> /tmp/log-analysis/summary-report.log
        
        # Append other analysis files
        for file in /tmp/log-analysis/*.log; do
          if [ "$file" != "/tmp/log-analysis/summary-report.log" ]; then
            echo "" >> /tmp/log-analysis/summary-report.log
            cat "$file" >> /tmp/log-analysis/summary-report.log
          fi
        done
      changed_when: false
      
    - name: Fetch analysis results
      fetch:
        src: /tmp/log-analysis/summary-report.log
        dest: ./reports/{{ inventory_hostname }}-troubleshooting-report.log
        flat: yes
      
    - name: Display report location
      debug:
        msg: "Troubleshooting report saved to: ./reports/{{ inventory_hostname }}-troubleshooting-report.log"
EOF

# Create reports directory
mkdir -p reports

# Run log analysis
ansible-playbook log-analysis.yml
Subtask 4.3: Real-time Log Monitoring Setup
Create a playbook for setting up real-time log monitoring:

cat > realtime-monitoring.yml << 'EOF'
---
- name: Setup Real-time Log Monitoring
  hosts: all
  become: yes
  tasks:
    - name: Install log monitoring tools
      yum:
        name:
          - rsyslog
          - logrotate
          - multitail
        state: present
        
    - name: Configure rsyslog for centralized logging
      blockinfile:
        path: /etc/rsyslog.conf
        block: |
          # Custom log monitoring rules
          *.emerg                                                 /var/log/emergency.log
          *.alert                                                 /var/log/alerts.log
          *.crit                                                  /var/log/critical.log
          
          # Application specific logging
          local0.*                                                /var/log/applications.log
          local1.*                                                /var/log/custom-app.log
        marker: "# {mark} ANSIBLE MANAGED BLOCK - Log Monitoring"
      notify: restart rsyslog
      
    - name: Create monitoring script
      copy:
        content: |
          #!/bin/bash
          # Real-time log monitoring script
          
          LOG_DIR="/var/log"
          ALERT_EMAIL="admin@example.com"
          
          monitor_logs() {
              echo "Starting real-time log monitoring..."
              echo "Monitoring directory: $LOG_DIR"
              echo "Press Ctrl+C to stop"
              
              # Monitor multiple log files simultaneously
              multitail \
                  -i "$LOG_DIR/messages" \
                  -i "$LOG_DIR/secure" \
                  -i "$LOG_DIR/httpd/error_log" \
                  -i "$LOG_DIR/mysqld.log" \
                  2>/dev/null
          }
          
          check_critical_errors() {
              # Check for critical errors in the last 5 minutes
              find $LOG_DIR -name "*.log" -mmin -5 -exec grep -l -i "critical\|emergency\|panic" {} \; 2>/dev/null
          }
          
          case "$1" in
              monitor)
                  monitor_logs
                  ;;
              check)
                  check_critical_errors
                  ;;
              *)
                  echo "Usage: $0 {monitor|check}"
                  echo "  monitor - Start real-time log monitoring"
                  echo "  check   - Check for recent critical errors"
                  exit 1
                  ;;
          esac
        dest: /usr/local/bin/log-monitor.sh
        mode: '0755'
        
    - name: Create log analysis cron job
      cron:
        name: "Critical log check"
        minute: "*/15"
        job: "/usr/local/bin/log-monitor.sh check > /tmp/critical-check.log 2>&1"
        
  handlers:
    - name: restart rsyslog
      systemd:
        name: rsyslog
        state: restarted
EOF

# Run real-time monitoring setup
ansible-playbook realtime-monitoring.yml
Task 5: Comprehensive Troubleshooting Scenarios
Subtask 5.1: Creating Intentional Issues for Practice
Create a playbook with common issues to practice troubleshooting:

cat > problematic-playbook.yml << 'EOF'
---
- name: Problematic Playbook for Troubleshooting Practice
  hosts: web_servers
  become: yes
  vars:
    # Intentional issues for learning
    app_name: "{{ undefined_variable }}"  # Issue 1: Undefined variable
    web_port: "eight-zero-eight-zero"     # Issue 2: Wrong data type
    
  tasks:
    - name: Install packages with typo
      yum:
        name:
          - httpd
          - php
          - php-mysqll  # Issue 3: Package name typo
        state: present
        
    - name: Create directory with wrong permissions
      file:
        path: "/opt/{{ app_name }}"
        state: directory
        owner: nonexistent_user  # Issue 4: Non-existent user
        group: apache
        mode: '0755'
        
    - name: Download from invalid URL
      get_url:
        url: "https://invalid-domain-12345.com/app.zip"  # Issue 5: Invalid URL
        dest: "/tmp/app.zip"
        timeout: 5
        
    - name: Use incorrect module syntax
      template:
        source: vhost.conf.j2  # Issue 6: Wrong parameter name (should be 'src')
        dest: "/etc/httpd/conf.d/app.conf"
        
    - name: Reference non-existent handler
      systemd:
        name: httpd
        state: started
      notify: restart_apache_server  # Issue 7: Handler name mismatch
      
  handlers:
    - name: restart apache
      systemd:
        name: httpd
        state: restarted
EOF
Subtask 5.2: Systematic Troubleshooting Approach
Create a troubleshooting methodology script:

cat > troubleshoot-playbook.sh << 'EOF'
#!/bin/bash

PLAYBOOK="$1"
if [ -z "$PLAYBOOK" ]; then
    echo "Usage: $0 <playbook.yml>"
    exit 1
fi

echo "=== ANSIBLE TROUBLESHOOTING METHODOLOGY ==="
echo "Playbook: $PLAYBOOK"
echo "Timestamp: $(date)"
echo "============================================"

# Step 1: Syntax Check
echo "Step 1: Checking playbook syntax..."
ansible-playbook "$PLAYBOOK" --syntax-check
if [ $? -ne 0 ]; then
    echo "❌ Syntax errors found. Fix syntax before proceeding."
    exit 1
else
    echo "✅ Syntax check passed."
fi

# Step 2: Dry Run
echo -e "\nStep 2: Performing dry run..."
ansible
