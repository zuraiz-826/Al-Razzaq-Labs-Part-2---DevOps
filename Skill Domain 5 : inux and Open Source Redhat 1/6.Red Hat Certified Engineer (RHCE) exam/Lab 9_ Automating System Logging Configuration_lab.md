Lab 9: Automating System Logging Configuration
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of system logging and log management
Configure rsyslog service using Ansible automation
Implement automated log rotation policies with logrotate
Set up centralized logging infrastructure with syslog servers
Create and manage log retention policies for optimal storage management
Write comprehensive Ansible playbooks for logging configuration
Troubleshoot common logging configuration issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with Ansible fundamentals and YAML syntax
Knowledge of SSH and basic networking concepts
Understanding of file permissions and directory structures
Experience with text editors (vim, nano, or similar)
Basic knowledge of systemd services
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines.

Your lab environment includes:

Control Node: CentOS/RHEL 8 system with Ansible pre-installed
Managed Nodes: 2-3 target systems for logging configuration
Network Configuration: All systems can communicate with each other
Required Software: rsyslog, logrotate, and necessary dependencies pre-installed
Task 1: Configure Basic System Logging with Ansible
Subtask 1.1: Create Project Directory Structure
First, let's organize our Ansible project with proper directory structure.

# Create the main project directory
mkdir -p ~/ansible-logging-lab
cd ~/ansible-logging-lab

# Create subdirectories for organization
mkdir -p {playbooks,roles,inventory,templates,files}

# Create the inventory file
cat > inventory/hosts << EOF
[logging_servers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[log_clients]
node3 ansible_host=192.168.1.12

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Subtask 1.2: Test Ansible Connectivity
Verify that Ansible can connect to all managed nodes:

# Test connectivity to all hosts
ansible all -i inventory/hosts -m ping

# Check if rsyslog is installed on all systems
ansible all -i inventory/hosts -m shell -a "rpm -q rsyslog"
Subtask 1.3: Create Basic Rsyslog Configuration Playbook
Create a comprehensive playbook to configure rsyslog on all systems:

# playbooks/configure-rsyslog.yml
---
- name: Configure System Logging with Rsyslog
  hosts: all
  become: yes
  vars:
    rsyslog_conf_dir: /etc/rsyslog.d
    log_dir: /var/log
    rsyslog_port: 514
    
  tasks:
    - name: Ensure rsyslog package is installed
      package:
        name: rsyslog
        state: present
      
    - name: Create custom rsyslog configuration directory
      file:
        path: "{{ rsyslog_conf_dir }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
    
    - name: Configure rsyslog main configuration
      template:
        src: rsyslog.conf.j2
        dest: /etc/rsyslog.conf
        owner: root
        group: root
        mode: '0644'
        backup: yes
      notify: restart rsyslog
    
    - name: Create custom application logging configuration
      copy:
        content: |
          # Custom application logging rules
          # Log all kernel messages to kern.log
          kern.*                          /var/log/kern.log
          
          # Log authentication messages
          auth,authpriv.*                 /var/log/auth.log
          
          # Log mail system messages
          mail.*                          /var/log/mail.log
          
          # Log cron messages
          cron.*                          /var/log/cron.log
          
          # Custom application logs
          local0.*                        /var/log/application.log
          local1.*                        /var/log/security.log
        dest: "{{ rsyslog_conf_dir }}/50-custom-logs.conf"
        owner: root
        group: root
        mode: '0644'
      notify: restart rsyslog
    
    - name: Ensure log directories exist with proper permissions
      file:
        path: "{{ log_dir }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
    
    - name: Create custom log files with proper permissions
      file:
        path: "{{ item }}"
        state: touch
        owner: root
        group: root
        mode: '0640'
      loop:
        - /var/log/kern.log
        - /var/log/auth.log
        - /var/log/mail.log
        - /var/log/cron.log
        - /var/log/application.log
        - /var/log/security.log
    
    - name: Enable and start rsyslog service
      systemd:
        name: rsyslog
        enabled: yes
        state: started
    
    - name: Configure rsyslog to start on boot
      systemd:
        name: rsyslog
        enabled: yes
  
  handlers:
    - name: restart rsyslog
      systemd:
        name: rsyslog
        state: restarted
Subtask 1.4: Create Rsyslog Configuration Template
Create a Jinja2 template for the main rsyslog configuration:

# Create templates directory if it doesn't exist
mkdir -p templates
# templates/rsyslog.conf.j2
# rsyslog configuration file
# Managed by Ansible - Do not edit manually

# Modules
module(load="imuxsock")    # provides support for local system logging
module(load="imjournal")   # provides access to the systemd journal
{% if inventory_hostname in groups['logging_servers'] %}
module(load="imudp")       # provides UDP syslog reception
module(load="imtcp")       # provides TCP syslog reception
{% endif %}

# Global directives
global(workDirectory="/var/lib/rsyslog")

# Include all config files in /etc/rsyslog.d/
include(file="/etc/rsyslog.d/*.conf" mode="optional")

# Rules section
*.info;mail.none;authpriv.none;cron.none    /var/log/messages
authpriv.*                                  /var/log/secure
mail.*                                      -/var/log/maillog
cron.*                                      /var/log/cron
*.emerg                                     :omusrmsg:*
uucp,news.crit                             /var/log/spooler
local7.*                                   /var/log/boot.log

{% if inventory_hostname in groups['logging_servers'] %}
# Server configuration - receive logs from other systems
input(type="imudp" port="{{ rsyslog_port }}")
input(type="imtcp" port="{{ rsyslog_port }}")

# Template for remote logs
template(name="RemoteLogFormat" type="string"
         string="/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log")

# Store remote logs in separate files
if $fromhost-ip != '127.0.0.1' then {
    action(type="omfile" dynaFile="RemoteLogFormat")
    stop
}
{% endif %}

{% if inventory_hostname in groups['log_clients'] %}
# Client configuration - forward logs to central server
*.* @@{{ hostvars[groups['logging_servers'][0]]['ansible_host'] }}:{{ rsyslog_port }}
{% endif %}
Subtask 1.5: Execute the Rsyslog Configuration Playbook
Run the playbook to configure rsyslog on all systems:

# Execute the playbook
ansible-playbook -i inventory/hosts playbooks/configure-rsyslog.yml

# Verify rsyslog service status
ansible all -i inventory/hosts -m shell -a "systemctl status rsyslog"

# Check rsyslog configuration syntax
ansible all -i inventory/hosts -m shell -a "rsyslogd -N1"
Task 2: Set Up Centralized Logging with Syslog Servers
Subtask 2.1: Configure Central Log Server
Create a dedicated playbook for setting up the central logging server:

# playbooks/setup-central-logging.yml
---
- name: Configure Central Logging Server
  hosts: logging_servers
  become: yes
  vars:
    remote_log_dir: /var/log/remote
    rsyslog_port: 514
    max_log_size: "100M"
    
  tasks:
    - name: Create remote log directory structure
      file:
        path: "{{ remote_log_dir }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
    
    - name: Configure firewall for syslog ports
      firewalld:
        port: "{{ rsyslog_port }}/udp"
        permanent: yes
        state: enabled
        immediate: yes
      ignore_errors: yes
    
    - name: Configure firewall for syslog TCP
      firewalld:
        port: "{{ rsyslog_port }}/tcp"
        permanent: yes
        state: enabled
        immediate: yes
      ignore_errors: yes
    
    - name: Create central server rsyslog configuration
      copy:
        content: |
          # Central logging server configuration
          # Enable UDP and TCP reception
          module(load="imudp")
          module(load="imtcp")
          
          # Listen on all interfaces
          input(type="imudp" port="{{ rsyslog_port }}" address="0.0.0.0")
          input(type="imtcp" port="{{ rsyslog_port }}" address="0.0.0.0")
          
          # Template for organizing remote logs
          template(name="RemoteHostLogs" type="string"
                   string="{{ remote_log_dir }}/%HOSTNAME%/%PROGRAMNAME%.log")
          
          template(name="RemoteHostAllLogs" type="string"
                   string="{{ remote_log_dir }}/%HOSTNAME%/all.log")
          
          # Ruleset for remote logs
          ruleset(name="RemoteLogHandling") {
              # Log everything to host-specific all.log
              action(type="omfile" dynaFile="RemoteHostAllLogs")
              
              # Log by program to separate files
              action(type="omfile" dynaFile="RemoteHostLogs")
              
              # Stop processing to prevent local logging
              stop
          }
          
          # Bind ruleset to UDP input
          input(type="imudp" port="{{ rsyslog_port }}" ruleset="RemoteLogHandling")
          input(type="imtcp" port="{{ rsyslog_port }}" ruleset="RemoteLogHandling")
        dest: /etc/rsyslog.d/10-central-server.conf
        owner: root
        group: root
        mode: '0644'
      notify: restart rsyslog
    
    - name: Create log monitoring script
      copy:
        content: |
          #!/bin/bash
          # Log monitoring script for central server
          
          LOG_DIR="{{ remote_log_dir }}"
          ALERT_SIZE=50000000  # 50MB in bytes
          
          echo "=== Central Log Server Status ==="
          echo "Date: $(date)"
          echo "Log Directory: $LOG_DIR"
          echo
          
          if [ -d "$LOG_DIR" ]; then
              echo "Remote hosts logging to this server:"
              ls -la "$LOG_DIR"
              echo
              
              echo "Large log files (>50MB):"
              find "$LOG_DIR" -type f -size +50M -exec ls -lh {} \;
              echo
              
              echo "Recent log activity:"
              find "$LOG_DIR" -type f -mmin -60 -exec echo "Modified in last hour: {}" \;
          else
              echo "Remote log directory does not exist!"
          fi
        dest: /usr/local/bin/log-monitor.sh
        owner: root
        group: root
        mode: '0755'
    
    - name: Create cron job for log monitoring
      cron:
        name: "Log server monitoring"
        minute: "*/30"
        job: "/usr/local/bin/log-monitor.sh >> /var/log/log-monitor.log 2>&1"
        user: root
  
  handlers:
    - name: restart rsyslog
      systemd:
        name: rsyslog
        state: restarted
Subtask 2.2: Configure Log Clients
Create a playbook to configure client systems to send logs to the central server:

# playbooks/configure-log-clients.yml
---
- name: Configure Log Clients for Central Logging
  hosts: log_clients
  become: yes
  vars:
    central_server: "{{ hostvars[groups['logging_servers'][0]]['ansible_host'] }}"
    rsyslog_port: 514
    
  tasks:
    - name: Configure client to forward logs to central server
      copy:
        content: |
          # Forward all logs to central server
          # Using TCP for reliable delivery
          *.* @@{{ central_server }}:{{ rsyslog_port }}
          
          # Also keep local copies of critical logs
          *.err                           /var/log/local-errors.log
          authpriv.*                      /var/log/local-auth.log
          
          # Stop processing after forwarding (optional)
          # Uncomment the next line to prevent local logging
          # & stop
        dest: /etc/rsyslog.d/20-forward-to-central.conf
        owner: root
        group: root
        mode: '0644'
      notify: restart rsyslog
    
    - name: Create local error log file
      file:
        path: /var/log/local-errors.log
        state: touch
        owner: root
        group: root
        mode: '0640'
    
    - name: Create local auth log file
      file:
        path: /var/log/local-auth.log
        state: touch
        owner: root
        group: root
        mode: '0640'
    
    - name: Test log forwarding
      shell: logger -p local0.info "Test message from {{ inventory_hostname }} - $(date)"
      
  handlers:
    - name: restart rsyslog
      systemd:
        name: rsyslog
        state: restarted
Subtask 2.3: Execute Central Logging Setup
Run the playbooks to set up centralized logging:

# Configure the central logging server
ansible-playbook -i inventory/hosts playbooks/setup-central-logging.yml

# Configure log clients
ansible-playbook -i inventory/hosts playbooks/configure-log-clients.yml

# Test the setup by generating test logs
ansible log_clients -i inventory/hosts -m shell -a "logger -p local0.info 'Test centralized logging from \$(hostname)'"

# Check if logs are being received on the central server
ansible logging_servers -i inventory/hosts -m shell -a "ls -la /var/log/remote/"
Task 3: Configure Log Rotation and Retention Policies
Subtask 3.1: Create Comprehensive Logrotate Configuration
Create a playbook to configure log rotation policies:

# playbooks/configure-logrotate.yml
---
- name: Configure Log Rotation and Retention Policies
  hosts: all
  become: yes
  vars:
    logrotate_conf_dir: /etc/logrotate.d
    default_retention_days: 30
    large_log_retention_days: 7
    
  tasks:
    - name: Ensure logrotate package is installed
      package:
        name: logrotate
        state: present
    
    - name: Configure main logrotate configuration
      template:
        src: logrotate.conf.j2
        dest: /etc/logrotate.conf
        owner: root
        group: root
        mode: '0644'
        backup: yes
    
    - name: Configure system log rotation
      copy:
        content: |
          # System logs rotation configuration
          /var/log/messages
          /var/log/secure
          /var/log/maillog
          /var/log/cron
          /var/log/spooler
          /var/log/boot.log {
              daily
              rotate {{ default_retention_days }}
              missingok
              notifempty
              compress
              delaycompress
              sharedscripts
              postrotate
                  /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
              endscript
          }
        dest: "{{ logrotate_conf_dir }}/syslog"
        owner: root
        group: root
        mode: '0644'
    
    - name: Configure custom application log rotation
      copy:
        content: |
          # Custom application logs rotation
          /var/log/application.log
          /var/log/security.log
          /var/log/kern.log
          /var/log/auth.log {
              daily
              rotate {{ default_retention_days }}
              missingok
              notifempty
              compress
              delaycompress
              create 0640 root root
              postrotate
                  /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
              endscript
          }
        dest: "{{ logrotate_conf_dir }}/custom-apps"
        owner: root
        group: root
        mode: '0644'
    
    - name: Configure high-volume log rotation (for central server)
      copy:
        content: |
          # High-volume logs - shorter retention
          /var/log/remote/*/*.log {
              daily
              rotate {{ large_log_retention_days }}
              missingok
              notifempty
              compress
              delaycompress
              create 0640 root root
              maxsize 100M
              postrotate
                  /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
              endscript
          }
        dest: "{{ logrotate_conf_dir }}/remote-logs"
        owner: root
        group: root
        mode: '0644'
      when: inventory_hostname in groups['logging_servers']
    
    - name: Create logrotate status directory
      file:
        path: /var/lib/logrotate
        state: directory
        owner: root
        group: root
        mode: '0755'
    
    - name: Configure logrotate cron job
      cron:
        name: "Daily log rotation"
        minute: "0"
        hour: "2"
        job: "/usr/sbin/logrotate /etc/logrotate.conf"
        user: root
    
    - name: Create log cleanup script for old compressed logs
      copy:
        content: |
          #!/bin/bash
          # Cleanup script for very old compressed logs
          
          LOG_DIRS="/var/log /var/log/remote"
          MAX_AGE_DAYS=90
          
          echo "Starting log cleanup - $(date)"
          
          for dir in $LOG_DIRS; do
              if [ -d "$dir" ]; then
                  echo "Cleaning up logs older than $MAX_AGE_DAYS days in $dir"
                  find "$dir" -name "*.gz" -type f -mtime +$MAX_AGE_DAYS -delete
                  find "$dir" -name "*.bz2" -type f -mtime +$MAX_AGE_DAYS -delete
                  
                  # Clean up empty directories
                  find "$dir" -type d -empty -delete 2>/dev/null || true
              fi
          done
          
          echo "Log cleanup completed - $(date)"
        dest: /usr/local/bin/log-cleanup.sh
        owner: root
        group: root
        mode: '0755'
    
    - name: Schedule weekly log cleanup
      cron:
        name: "Weekly old log cleanup"
        minute: "0"
        hour: "3"
        weekday: "0"
        job: "/usr/local/bin/log-cleanup.sh >> /var/log/log-cleanup.log 2>&1"
        user: root
Subtask 3.2: Create Logrotate Configuration Template
Create the main logrotate configuration template:

# templates/logrotate.conf.j2
# Logrotate configuration - Managed by Ansible

# Global options
weekly
rotate 4
create
dateext
compress

# Include configuration files from logrotate.d directory
include /etc/logrotate.d

# System-specific logs
/var/log/wtmp {
    monthly
    create 0664 root utmp
    minsize 1M
    rotate 1
}

/var/log/btmp {
    missingok
    monthly
    create 0600 root utmp
    rotate 1
}

# RPM packages drop log rotation information into this directory
include /etc/logrotate.d

# Specific configurations for different host types
{% if inventory_hostname in groups['logging_servers'] %}
# Central server specific settings
# Handle large volumes of logs with more aggressive rotation
{% endif %}

{% if inventory_hostname in groups['log_clients'] %}
# Client specific settings
# Less aggressive rotation since logs are forwarded
{% endif %}
Subtask 3.3: Create Advanced Log Management Playbook
Create a comprehensive log management playbook with monitoring and alerting:

# playbooks/advanced-log-management.yml
---
- name: Advanced Log Management and Monitoring
  hosts: all
  become: yes
  vars:
    log_alert_threshold: 80  # Percentage
    log_partition: /var/log
    
  tasks:
    - name: Install log analysis tools
      package:
        name: "{{ item }}"
        state: present
      loop:
        - logwatch
        - mailx
        - bc
    
    - name: Create log space monitoring script
      copy:
        content: |
          #!/bin/bash
          # Log space monitoring script
          
          THRESHOLD={{ log_alert_threshold }}
          LOG_PARTITION="{{ log_partition }}"
          HOSTNAME=$(hostname)
          
          # Get disk usage percentage
          USAGE=$(df "$LOG_PARTITION" | awk 'NR==2 {print $5}' | sed 's/%//')
          
          echo "=== Log Space Report for $HOSTNAME ==="
          echo "Date: $(date)"
          echo "Partition: $LOG_PARTITION"
          echo "Usage: $USAGE%"
          echo "Threshold: $THRESHOLD%"
          echo
          
          if [ "$USAGE" -gt "$THRESHOLD" ]; then
              echo "WARNING: Log partition usage ($USAGE%) exceeds threshold ($THRESHOLD%)"
              echo
              echo "Largest log files:"
              find "$LOG_PARTITION" -type f -exec ls -lh {} \; | sort -k5 -hr | head -10
              echo
              echo "Oldest log files that can be cleaned:"
              find "$LOG_PARTITION" -name "*.log" -type f -mtime +30 | head -10
              
              # Send alert (if mail is configured)
              echo "Log space alert for $HOSTNAME: Usage at $USAGE%" | \
                  mail -s "Log Space Alert - $HOSTNAME" root 2>/dev/null || true
          else
              echo "OK: Log partition usage is within acceptable limits"
          fi
          
          echo
          echo "Recent log rotation activity:"
          grep "$(date '+%b %d')" /var/log/cron | grep logrotate | tail -5
        dest: /usr/local/bin/log-space-monitor.sh
        owner: root
        group: root
        mode: '0755'
    
    - name: Create log analysis script
      copy:
        content: |
          #!/bin/bash
          # Log analysis and summary script
          
          LOG_DIR="/var/log"
          REPORT_FILE="/tmp/log-analysis-$(date +%Y%m%d).txt"
          
          echo "=== Daily Log Analysis Report ===" > "$REPORT_FILE"
          echo "Generated: $(date)" >> "$REPORT_FILE"
          echo "Hostname: $(hostname)" >> "$REPORT_FILE"
          echo >> "$REPORT_FILE"
          
          # System errors in the last 24 hours
          echo "=== System Errors (Last 24 Hours) ===" >> "$REPORT_FILE"
          journalctl --since "24 hours ago" --priority=err --no-pager >> "$REPORT_FILE" 2>/dev/null
          echo >> "$REPORT_FILE"
          
          # Authentication failures
          echo "=== Authentication Failures ===" >> "$REPORT_FILE"
          grep "authentication failure" /var/log/secure 2>/dev/null | tail -10 >> "$REPORT_FILE"
          echo >> "$REPORT_FILE"
          
          # Disk space usage
          echo "=== Disk Space Usage ===" >> "$REPORT_FILE"
          df -h >> "$REPORT_FILE"
          echo >> "$REPORT_FILE"
          
          # Log file sizes
          echo "=== Largest Log Files ===" >> "$REPORT_FILE"
          find "$LOG_DIR" -type f -name "*.log" -exec ls -lh {} \; | sort -k5 -hr | head -10 >> "$REPORT_FILE"
          
          echo "Report saved to: $REPORT_FILE"
        dest: /usr/local/bin/log-analysis.sh
        owner: root
        group: root
        mode: '0755'
    
    - name: Schedule log monitoring
      cron:
        name: "{{ item.name }}"
        minute: "{{ item.minute }}"
        hour: "{{ item.hour }}"
        job: "{{ item.job }}"
        user: root
      loop:
        - name: "Hourly log space check"
          minute: "0"
          hour: "*"
          job: "/usr/local/bin/log-space-monitor.sh >> /var/log/log-monitor.log 2>&1"
        - name: "Daily log analysis"
          minute: "30"
          hour: "6"
          job: "/usr/local/bin/log-analysis.sh"
    
    - name: Test logrotate configuration
      shell: logrotate -d /etc/logrotate.conf
      register: logrotate_test
      failed_when: logrotate_test.rc != 0
    
    - name: Force logrotate to run (for testing)
      shell: logrotate -f /etc/logrotate.conf
      when: ansible_check_mode == false
Subtask 3.4: Execute Log Rotation Configuration
Run the log rotation and management playbooks:

# Configure log rotation
ansible-playbook -i inventory/hosts playbooks/configure-logrotate.yml

# Set up advanced log management
ansible-playbook -i inventory/hosts playbooks/advanced-log-management.yml

# Test logrotate configuration
ansible all -i inventory/hosts -m shell -a "logrotate -d /etc/logrotate.conf"

# Check cron jobs
ansible all -i inventory/hosts -m shell -a "crontab -l"
Verification and Testing
Test Central Logging
# Generate test logs from clients
ansible log_clients -i inventory/hosts -m shell -a "for i in {1..10}; do logger -p local0.info 'Test message \$i from \$(hostname)'; done"

# Check central server for received logs
ansible logging_servers -i inventory/hosts -m shell -a "find /var/log/remote -name '*.log' -exec tail -5 {} \;"

# Verify log forwarding is working
ansible logging_servers -i inventory/hosts -m shell -a "grep 'Test message' /var/log/remote/*/*.log"
Test Log Rotation
# Force log rotation for testing
ansible all -i inventory/hosts -m shell -a "logrotate -f /etc/logrotate.conf"

# Check for rotated files
ansible all -i inventory/hosts -m shell -a "ls -la /var/log/*.1 /var/log/*.gz"

# Verify logrotate status
ansible all -i inventory/hosts -m shell -a "cat /var/lib/logrotate/logrotate.status"
Monitor Log Space Usage
# Run log space monitoring script
ansible all -i inventory/hosts -m shell -a "/usr/local/bin/log-space-monitor.sh"

# Check log analysis reports
ansible all -i inventory/hosts -m shell -a "/usr/local/bin/log-analysis.sh"
Troubleshooting Common Issues
Issue 1: Rsyslog Service Not Starting
Symptoms: Rsyslog fails to start or restart Solution:

# Check rsyslog configuration syntax
ansible all -i inventory/hosts -m shell -a "rsyslogd -N1"

# Check for configuration errors
ansible all -i inventory/hosts -m shell -a "journalctl -u rsyslog -n 20"

# Verify file permissions
ansible all -i inventory/hosts -m shell -a "ls -la /etc/rsyslog.conf /etc/rsyslog.d/"
Issue 2: Central Server Not Receiving Logs
Symptoms: Logs not appearing in /var/log/remote/ Solution:

# Check firewall settings
ansible logging_servers -i inventory/hosts -m shell -a "firewall-cmd --list-ports"

# Verify rsyslog is listening on correct ports
ansible logging_servers -i inventory/hosts -m shell -a "netstat -tulpn | grep 514"

# Test connectivity from clients
ansible log_clients -i inventory/hosts -m shell -a "telnet {{ hostvars[groups['logging_servers'][0]]['ansible_host'] }} 514"
Issue 3: Log Rotation Not Working
Symptoms: Log files growing too large, no rotated files Solution:

# Check logrotate configuration
ansible all -i inventory/hosts -m shell -a "logrotate -d /etc/logrotate.conf"

# Verify cron job is running
ansible all -i inventory/hosts -m shell -a "grep logrotate /var/log/cron"

# Check logrotate status file
ansible all -i inventory/hosts -m shell -a "cat /var/lib/logrotate/logrotate.status"
Conclusion
In this comprehensive lab, you have successfully:

Automated System Logging Configuration: Created Ansible playbooks to configure rsyslog across multiple systems, ensuring consistent logging setup and management.

Implemented Centralized Logging: Set up a central syslog server to collect logs from multiple client systems, providing centralized log management and analysis capabilities.

Configured Log Rotation and Retention: Implemented automated log rotation policies using logrotate to manage disk space and maintain appropriate log retention periods.

Created Monitoring and Alerting: Developed scripts to monitor log space usage and generate analysis reports, ensuring proactive log management.

Established Best Practices: Implemented security measures, proper file permissions, and organized configuration management for enterprise-level logging infrastructure.

This lab demonstrates essential skills for the Red Hat Certified Engineer (RHCE) exam, particularly in automation, system administration, and log management. The centralized logging setup you've created provides a foundation for enterprise log management, security monitoring, and compliance requirements.

The automated configuration approach using Ansible ensures consistency across your infrastructure and makes it easy to scale logging configuration to additional systems. The monitoring and alerting mechanisms help maintain system health and prevent log-related issues before they impact system performance.

These skills are directly applicable in production environments where reliable logging infrastructure is critical for troubleshooting, security monitoring, and regulatory compliance.
