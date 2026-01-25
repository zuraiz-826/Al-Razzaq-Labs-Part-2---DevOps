Lab 10: Automating Task Scheduling
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of task scheduling in Linux environments
Create and manage Ansible playbooks for automating cron jobs
Implement one-time task scheduling using the at command through Ansible
Configure and manage systemd timers for advanced task automation
Apply best practices for automated task scheduling in enterprise environments
Troubleshoot common issues with scheduled tasks
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with Ansible fundamentals and playbook structure
Knowledge of YAML syntax
Understanding of basic system administration concepts
Experience with text editors (vim, nano, or similar)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 based systems
Ansible pre-installed and configured
Multiple target nodes for testing
All necessary packages and dependencies
Task 1: Write a Playbook to Schedule Recurring Tasks Using Cron Module
Subtask 1.1: Understanding Cron Basics
Before diving into Ansible automation, let's understand cron fundamentals:

Cron is a time-based job scheduler in Unix-like operating systems. It allows users to schedule jobs (commands or scripts) to run periodically at fixed times, dates, or intervals.

Cron time format: minute hour day month day_of_week

Examples:

0 2 * * * - Run at 2:00 AM every day
30 14 * * 1 - Run at 2:30 PM every Monday
*/15 * * * * - Run every 15 minutes
Subtask 1.2: Create Directory Structure
First, let's create a proper directory structure for our Ansible project:

mkdir -p ~/ansible-scheduling-lab/{playbooks,inventory,roles}
cd ~/ansible-scheduling-lab
Create an inventory file:

cat > inventory/hosts << EOF
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[databases]
node3 ansible_host=192.168.1.12

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Subtask 1.3: Create Basic Cron Playbook
Create your first cron automation playbook:

cat > playbooks/cron-tasks.yml << 'EOF'
---
- name: Automate Cron Job Scheduling
  hosts: all
  become: yes
  vars:
    log_directory: /var/log/automated-tasks
    
  tasks:
    - name: Ensure log directory exists
      file:
        path: "{{ log_directory }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
    
    - name: Schedule daily system cleanup
      cron:
        name: "Daily system cleanup"
        minute: "0"
        hour: "2"
        job: "find /tmp -type f -mtime +7 -delete >> {{ log_directory }}/cleanup.log 2>&1"
        user: root
        state: present
    
    - name: Schedule weekly log rotation check
      cron:
        name: "Weekly log rotation check"
        minute: "30"
        hour: "1"
        weekday: "0"
        job: "logrotate -f /etc/logrotate.conf >> {{ log_directory }}/logrotate.log 2>&1"
        user: root
        state: present
    
    - name: Schedule disk usage monitoring
      cron:
        name: "Disk usage monitoring"
        minute: "*/30"
        job: "df -h | grep -E '(8[0-9]|9[0-9])%' >> {{ log_directory }}/disk-usage.log"
        user: root
        state: present
EOF
Subtask 1.4: Execute the Cron Playbook
Run the playbook to schedule your cron jobs:

ansible-playbook -i inventory/hosts playbooks/cron-tasks.yml
Subtask 1.5: Verify Cron Jobs
Check that the cron jobs were created successfully:

ansible all -i inventory/hosts -m shell -a "crontab -l" --become
Subtask 1.6: Advanced Cron Management
Create an advanced playbook for more complex cron scenarios:

cat > playbooks/advanced-cron.yml << 'EOF'
---
- name: Advanced Cron Job Management
  hosts: webservers
  become: yes
  vars:
    backup_script: /usr/local/bin/backup.sh
    
  tasks:
    - name: Create backup script
      copy:
        content: |
          #!/bin/bash
          DATE=$(date +%Y%m%d_%H%M%S)
          BACKUP_DIR="/backup"
          SOURCE_DIR="/var/www/html"
          
          mkdir -p $BACKUP_DIR
          tar -czf $BACKUP_DIR/website_backup_$DATE.tar.gz $SOURCE_DIR
          
          # Keep only last 7 backups
          find $BACKUP_DIR -name "website_backup_*.tar.gz" -mtime +7 -delete
          
          echo "Backup completed: $DATE" >> /var/log/backup.log
        dest: "{{ backup_script }}"
        mode: '0755'
        owner: root
        group: root
    
    - name: Schedule website backup
      cron:
        name: "Website backup"
        minute: "0"
        hour: "3"
        job: "{{ backup_script }}"
        user: root
        state: present
        backup: yes
    
    - name: Schedule database backup (databases group only)
      cron:
        name: "Database backup"
        minute: "30"
        hour: "2"
        job: "mysqldump --all-databases > /backup/db_backup_$(date +\\%Y\\%m\\%d).sql"
        user: root
        state: present
      when: inventory_hostname in groups['databases']
    
    - name: Remove old cron job if exists
      cron:
        name: "Old cleanup job"
        state: absent
EOF
Run the advanced playbook:

ansible-playbook -i inventory/hosts playbooks/advanced-cron.yml
Task 2: Automate One-Time Tasks Using the At Module
Subtask 2.1: Understanding At Command
The at command is used to schedule one-time tasks to run at a specific time in the future. Unlike cron, which schedules recurring tasks, at is perfect for tasks that need to run only once.

Subtask 2.2: Install At Service
First, ensure the at service is installed and running:

cat > playbooks/setup-at.yml << 'EOF'
---
- name: Setup At Service
  hosts: all
  become: yes
  
  tasks:
    - name: Install at package
      package:
        name: at
        state: present
    
    - name: Start and enable atd service
      systemd:
        name: atd
        state: started
        enabled: yes
    
    - name: Check atd service status
      systemd:
        name: atd
      register: atd_status
    
    - name: Display atd status
      debug:
        msg: "ATD service is {{ atd_status.status.ActiveState }}"
EOF
Execute the setup playbook:

ansible-playbook -i inventory/hosts playbooks/setup-at.yml
Subtask 2.3: Create At Jobs Playbook
Create a playbook to schedule one-time tasks:

cat > playbooks/at-tasks.yml << 'EOF'
---
- name: Schedule One-Time Tasks with At
  hosts: all
  become: yes
  
  tasks:
    - name: Schedule system update in 5 minutes
      at:
        command: "yum update -y >> /var/log/scheduled-update.log 2>&1"
        count: 5
        units: minutes
        unique: yes
    
    - name: Schedule log cleanup tomorrow at 3 AM
      at:
        command: "find /var/log -name '*.log' -mtime +30 -delete"
        count: 1
        units: days
        time: "03:00"
        unique: yes
    
    - name: Schedule service restart in 1 hour
      at:
        command: "systemctl restart httpd && echo 'Apache restarted' >> /var/log/service-restart.log"
        count: 1
        units: hours
        unique: yes
      when: inventory_hostname in groups['webservers']
    
    - name: Schedule temporary file creation
      at:
        command: "echo 'Temporary task executed at $(date)' > /tmp/at-task-$(date +%s).txt"
        count: 2
        units: minutes
        unique: yes
EOF
Subtask 2.4: Execute At Tasks
Run the at tasks playbook:

ansible-playbook -i inventory/hosts playbooks/at-tasks.yml
Subtask 2.5: Verify At Jobs
Check scheduled at jobs:

ansible all -i inventory/hosts -m shell -a "atq" --become
View details of specific at jobs:

ansible all -i inventory/hosts -m shell -a "at -c 1" --become
Subtask 2.6: Advanced At Usage
Create a more complex at scheduling scenario:

cat > playbooks/advanced-at.yml << 'EOF'
---
- name: Advanced At Job Scheduling
  hosts: all
  become: yes
  vars:
    maintenance_script: /usr/local/bin/maintenance.sh
    
  tasks:
    - name: Create maintenance script
      copy:
        content: |
          #!/bin/bash
          echo "Starting maintenance at $(date)" >> /var/log/maintenance.log
          
          # Stop services
          systemctl stop httpd 2>/dev/null || true
          systemctl stop nginx 2>/dev/null || true
          
          # Perform maintenance tasks
          yum clean all
          find /tmp -type f -mtime +1 -delete
          
          # Start services
          systemctl start httpd 2>/dev/null || true
          systemctl start nginx 2>/dev/null || true
          
          echo "Maintenance completed at $(date)" >> /var/log/maintenance.log
        dest: "{{ maintenance_script }}"
        mode: '0755'
        owner: root
        group: root
    
    - name: Schedule maintenance for next Sunday at 2 AM
      at:
        command: "{{ maintenance_script }}"
        count: 1
        units: weeks
        time: "02:00"
        unique: yes
    
    - name: Schedule conditional task based on system load
      at:
        command: |
          if [ $(uptime | awk '{print $10}' | cut -d',' -f1) -lt 1 ]; then
            echo "System load is low, performing optimization" >> /var/log/optimization.log
            nice -n 19 find / -name "*.tmp" -delete 2>/dev/null
          fi
        count: 30
        units: minutes
        unique: yes
EOF
Execute the advanced at playbook:

ansible-playbook -i inventory/hosts playbooks/advanced-at.yml
Task 3: Configure Systemd Timers for Task Automation
Subtask 3.1: Understanding Systemd Timers
Systemd timers are a modern alternative to cron jobs, offering more precise control and better integration with the systemd ecosystem. They provide:

More accurate timing
Better logging and monitoring
Dependency management
Resource control
Subtask 3.2: Create Systemd Timer Playbook
Create a comprehensive playbook for systemd timers:

cat > playbooks/systemd-timers.yml << 'EOF'
---
- name: Configure Systemd Timers
  hosts: all
  become: yes
  vars:
    timer_directory: /etc/systemd/system
    script_directory: /usr/local/bin
    
  tasks:
    - name: Create backup script for systemd timer
      copy:
        content: |
          #!/bin/bash
          BACKUP_DIR="/backup/systemd"
          DATE=$(date +%Y%m%d_%H%M%S)
          
          mkdir -p $BACKUP_DIR
          
          # Backup important system files
          tar -czf $BACKUP_DIR/system_backup_$DATE.tar.gz \
              /etc/passwd /etc/group /etc/hosts /etc/fstab \
              2>/dev/null || true
          
          # Log the backup
          echo "System backup completed: $DATE" >> /var/log/systemd-backup.log
          
          # Cleanup old backups (keep last 10)
          ls -t $BACKUP_DIR/system_backup_*.tar.gz | tail -n +11 | xargs rm -f
        dest: "{{ script_directory }}/systemd-backup.sh"
        mode: '0755'
        owner: root
        group: root
    
    - name: Create systemd service file for backup
      copy:
        content: |
          [Unit]
          Description=System Backup Service
          After=multi-user.target
          
          [Service]
          Type=oneshot
          ExecStart={{ script_directory }}/systemd-backup.sh
          User=root
          StandardOutput=journal
          StandardError=journal
        dest: "{{ timer_directory }}/system-backup.service"
        owner: root
        group: root
        mode: '0644'
    
    - name: Create systemd timer file for backup
      copy:
        content: |
          [Unit]
          Description=Run system backup daily
          Requires=system-backup.service
          
          [Timer]
          OnCalendar=daily
          RandomizedDelaySec=1800
          Persistent=true
          
          [Install]
          WantedBy=timers.target
        dest: "{{ timer_directory }}/system-backup.timer"
        owner: root
        group: root
        mode: '0644'
    
    - name: Create monitoring script
      copy:
        content: |
          #!/bin/bash
          LOG_FILE="/var/log/system-monitor.log"
          
          # Check disk usage
          DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
          if [ $DISK_USAGE -gt 80 ]; then
              echo "$(date): WARNING - Disk usage is ${DISK_USAGE}%" >> $LOG_FILE
          fi
          
          # Check memory usage
          MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
          if [ $MEM_USAGE -gt 90 ]; then
              echo "$(date): WARNING - Memory usage is ${MEM_USAGE}%" >> $LOG_FILE
          fi
          
          # Check load average
          LOAD_AVG=$(uptime | awk '{print $10}' | cut -d',' -f1)
          if (( $(echo "$LOAD_AVG > 2.0" | bc -l) )); then
              echo "$(date): WARNING - High load average: $LOAD_AVG" >> $LOG_FILE
          fi
          
          echo "$(date): System monitoring completed" >> $LOG_FILE
        dest: "{{ script_directory }}/system-monitor.sh"
        mode: '0755'
        owner: root
        group: root
    
    - name: Create systemd service file for monitoring
      copy:
        content: |
          [Unit]
          Description=System Monitoring Service
          After=multi-user.target
          
          [Service]
          Type=oneshot
          ExecStart={{ script_directory }}/system-monitor.sh
          User=root
          StandardOutput=journal
          StandardError=journal
        dest: "{{ timer_directory }}/system-monitor.service"
        owner: root
        group: root
        mode: '0644'
    
    - name: Create systemd timer file for monitoring (every 15 minutes)
      copy:
        content: |
          [Unit]
          Description=Run system monitoring every 15 minutes
          Requires=system-monitor.service
          
          [Timer]
          OnBootSec=15min
          OnUnitActiveSec=15min
          Persistent=true
          
          [Install]
          WantedBy=timers.target
        dest: "{{ timer_directory }}/system-monitor.timer"
        owner: root
        group: root
        mode: '0644'
    
    - name: Reload systemd daemon
      systemd:
        daemon_reload: yes
    
    - name: Enable and start backup timer
      systemd:
        name: system-backup.timer
        enabled: yes
        state: started
    
    - name: Enable and start monitoring timer
      systemd:
        name: system-monitor.timer
        enabled: yes
        state: started
EOF
Subtask 3.3: Execute Systemd Timer Playbook
Run the systemd timer playbook:

ansible-playbook -i inventory/hosts playbooks/systemd-timers.yml
Subtask 3.4: Verify Systemd Timers
Check the status of your timers:

ansible all -i inventory/hosts -m shell -a "systemctl list-timers --all" --become
Check specific timer status:

ansible all -i inventory/hosts -m shell -a "systemctl status system-backup.timer" --become
View timer logs:

ansible all -i inventory/hosts -m shell -a "journalctl -u system-backup.timer -n 10" --become
Subtask 3.5: Advanced Systemd Timer Configuration
Create an advanced timer configuration with dependencies:

cat > playbooks/advanced-systemd-timers.yml << 'EOF'
---
- name: Advanced Systemd Timer Configuration
  hosts: webservers
  become: yes
  vars:
    timer_directory: /etc/systemd/system
    script_directory: /usr/local/bin
    
  tasks:
    - name: Create web application maintenance script
      copy:
        content: |
          #!/bin/bash
          APP_DIR="/var/www/html"
          LOG_FILE="/var/log/webapp-maintenance.log"
          
          echo "$(date): Starting web application maintenance" >> $LOG_FILE
          
          # Check if Apache is running
          if systemctl is-active --quiet httpd; then
              echo "$(date): Apache is running, proceeding with maintenance" >> $LOG_FILE
              
              # Clear application cache
              find $APP_DIR/cache -type f -name "*.cache" -delete 2>/dev/null || true
              
              # Optimize images older than 1 day
              find $APP_DIR -name "*.jpg" -o -name "*.png" -mtime +1 | while read img; do
                  if command -v optipng >/dev/null 2>&1; then
                      optipng -quiet "$img" 2>/dev/null || true
                  fi
              done
              
              # Generate sitemap
              if [ -f "$APP_DIR/generate_sitemap.php" ]; then
                  php $APP_DIR/generate_sitemap.php >> $LOG_FILE 2>&1
              fi
              
              echo "$(date): Web application maintenance completed" >> $LOG_FILE
          else
              echo "$(date): Apache is not running, skipping maintenance" >> $LOG_FILE
          fi
        dest: "{{ script_directory }}/webapp-maintenance.sh"
        mode: '0755'
        owner: root
        group: root
    
    - name: Create web application maintenance service
      copy:
        content: |
          [Unit]
          Description=Web Application Maintenance
          After=httpd.service
          Wants=httpd.service
          
          [Service]
          Type=oneshot
          ExecStart={{ script_directory }}/webapp-maintenance.sh
          User=root
          StandardOutput=journal
          StandardError=journal
          
          # Resource limits
          MemoryLimit=512M
          CPUQuota=50%
        dest: "{{ timer_directory }}/webapp-maintenance.service"
        owner: root
        group: root
        mode: '0644'
    
    - name: Create web application maintenance timer
      copy:
        content: |
          [Unit]
          Description=Run web application maintenance
          Requires=webapp-maintenance.service
          
          [Timer]
          OnCalendar=*-*-* 02:30:00
          RandomizedDelaySec=600
          Persistent=true
          
          [Install]
          WantedBy=timers.target
        dest: "{{ timer_directory }}/webapp-maintenance.timer"
        owner: root
        group: root
        mode: '0644'
    
    - name: Create log rotation service
      copy:
        content: |
          [Unit]
          Description=Custom Log Rotation
          After=rsyslog.service
          
          [Service]
          Type=oneshot
          ExecStart=/usr/sbin/logrotate -f /etc/logrotate.conf
          ExecStartPost=/bin/systemctl reload rsyslog
          User=root
          StandardOutput=journal
          StandardError=journal
        dest: "{{ timer_directory }}/custom-logrotate.service"
        owner: root
        group: root
        mode: '0644'
    
    - name: Create log rotation timer (weekly)
      copy:
        content: |
          [Unit]
          Description=Run custom log rotation weekly
          Requires=custom-logrotate.service
          
          [Timer]
          OnCalendar=weekly
          RandomizedDelaySec=3600
          Persistent=true
          
          [Install]
          WantedBy=timers.target
        dest: "{{ timer_directory }}/custom-logrotate.timer"
        owner: root
        group: root
        mode: '0644'
    
    - name: Reload systemd daemon
      systemd:
        daemon_reload: yes
    
    - name: Enable and start webapp maintenance timer
      systemd:
        name: webapp-maintenance.timer
        enabled: yes
        state: started
    
    - name: Enable and start custom logrotate timer
      systemd:
        name: custom-logrotate.timer
        enabled: yes
        state: started
EOF
Execute the advanced systemd timer playbook:

ansible-playbook -i inventory/hosts playbooks/advanced-systemd-timers.yml
Verification and Testing
Comprehensive System Check
Create a verification playbook to check all scheduled tasks:

cat > playbooks/verify-scheduling.yml << 'EOF'
---
- name: Verify All Scheduled Tasks
  hosts: all
  become: yes
  
  tasks:
    - name: Check cron jobs
      shell: crontab -l
      register: cron_jobs
      failed_when: false
    
    - name: Display cron jobs
      debug:
        msg: "Cron jobs: {{ cron_jobs.stdout_lines }}"
      when: cron_jobs.stdout_lines is defined
    
    - name: Check at jobs
      shell: atq
      register: at_jobs
      failed_when: false
    
    - name: Display at jobs
      debug:
        msg: "At jobs: {{ at_jobs.stdout_lines }}"
      when: at_jobs.stdout_lines is defined
    
    - name: Check systemd timers
      shell: systemctl list-timers --no-pager
      register: systemd_timers
    
    - name: Display systemd timers
      debug:
        msg: "Systemd timers: {{ systemd_timers.stdout_lines }}"
    
    - name: Check timer service status
      shell: systemctl is-active {{ item }}
      register: timer_status
      failed_when: false
      loop:
        - system-backup.timer
        - system-monitor.timer
        - webapp-maintenance.timer
        - custom-logrotate.timer
    
    - name: Display timer status
      debug:
        msg: "Timer {{ item.item }} is {{ item.stdout }}"
      loop: "{{ timer_status.results }}"
      when: item.stdout is defined
EOF
Run the verification:

ansible-playbook -i inventory/hosts playbooks/verify-scheduling.yml
Troubleshooting Common Issues
Issue 1: Cron Jobs Not Executing
Problem: Cron jobs appear in crontab but don't execute.

Solution:

# Check cron service status
ansible all -i inventory/hosts -m shell -a "systemctl status crond" --become

# Check cron logs
ansible all -i inventory/hosts -m shell -a "grep CRON /var/log/messages | tail -10" --become

# Verify script permissions
ansible all -i inventory/hosts -m shell -a "ls -la /usr/local/bin/backup.sh" --become
Issue 2: At Jobs Failing
Problem: At jobs are scheduled but fail to execute.

Solution:

# Check atd service
ansible all -i inventory/hosts -m shell -a "systemctl status atd" --become

# Check at job details
ansible all -i inventory/hosts -m shell -a "at -c 1" --become

# Check mail for error messages
ansible all -i inventory/hosts -m shell -a "mail" --become
Issue 3: Systemd Timers Not Starting
Problem: Systemd timers are created but not starting.

Solution:

# Check timer status
ansible all -i inventory/hosts -m shell -a "systemctl status system-backup.timer" --become

# Check for syntax errors
ansible all -i inventory/hosts -m shell -a "systemd-analyze verify /etc/systemd/system/system-backup.timer" --become

# Reload systemd and restart timer
ansible all -i inventory/hosts -m shell -a "systemctl daemon-reload && systemctl restart system-backup.timer" --become
Best Practices and Security Considerations
Security Best Practices
Use specific users for scheduled tasks:
- name: Create dedicated user for backups
  user:
    name: backup_user
    system: yes
    shell: /bin/bash
    home: /var/lib/backup_user
Set proper file permissions:
- name: Secure script permissions
  file:
    path: /usr/local/bin/backup.sh
    mode: '0750'
    owner: root
    group: backup_user
Use environment variables securely:
- name: Set secure environment for cron
  cron:
    name: "Secure backup"
    job: "export PATH=/usr/local/bin:/bin:/usr/bin && /usr/local/bin/secure-backup.sh"
    minute: "0"
    hour: "2"
Performance Considerations
Use RandomizedDelaySec for systemd timers to prevent system overload
Set resource limits for intensive tasks
Schedule tasks during low-usage periods
Monitor system resources when tasks are running
Conclusion
In this comprehensive lab, you have successfully learned to automate task scheduling using three different methods:

What You Accomplished
Cron Automation: You created Ansible playbooks to manage recurring tasks using the cron module, including:

Basic daily, weekly, and interval-based scheduling
Advanced backup and maintenance scripts
Proper logging and error handling
At Command Integration: You implemented one-time task scheduling using the at module, covering:

Service installation and configuration
Various scheduling formats (minutes, hours, days)
Complex conditional tasks
Systemd Timer Configuration: You configured modern systemd timers with:

Service and timer file creation
Dependency management
Resource control and monitoring
Advanced scheduling patterns
Why This Matters
Task scheduling automation is crucial for:

System Maintenance: Automated backups, log rotation, and cleanup tasks ensure system health
Resource Optimization: Scheduled tasks can run during low-usage periods
Reliability: Automated scheduling reduces human error and ensures consistency
Scalability: Ansible allows you to manage scheduling across multiple systems efficiently
Compliance: Regular automated tasks help maintain security and compliance requirements
Key Takeaways
Cron is perfect for simple, recurring tasks with basic scheduling needs
At excels for one-time tasks and temporary scheduling requirements
Systemd timers provide the most advanced features with better integration and monitoring
Ansible makes it easy to manage all three scheduling methods across multiple systems
Proper logging and monitoring are essential for troubleshooting scheduled tasks
You now have the skills to implement comprehensive task scheduling automation in enterprise environments, supporting your preparation for the Red Hat Certified Engineer (RHCE) exam and real-world system administration scenarios.
