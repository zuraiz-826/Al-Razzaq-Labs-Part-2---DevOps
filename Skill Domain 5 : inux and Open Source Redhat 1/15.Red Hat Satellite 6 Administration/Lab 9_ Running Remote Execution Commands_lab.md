Lab 9: Running Remote Execution Commands
Objectives
By the end of this lab, you will be able to:

Execute ad-hoc commands on multiple hosts simultaneously using Red Hat Satellite
Schedule recurring maintenance tasks across your infrastructure
Integrate Ansible playbooks with Satellite for advanced automation
Monitor and troubleshoot remote execution jobs
Configure remote execution templates for common administrative tasks
Understand the security implications and best practices for remote execution
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with Red Hat Satellite 6 interface and navigation
Knowledge of SSH key authentication concepts
Basic understanding of Ansible concepts (playbooks, tasks, modules)
Completed previous Satellite labs covering host registration and content management
Administrative access to Red Hat Satellite server
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or configure complex networking.

Your lab environment includes:

Red Hat Satellite 6 server (satellite.example.com)
3 registered client hosts (client1.example.com, client2.example.com, client3.example.com)
Pre-configured SSH keys and remote execution settings
Sample Ansible playbooks and job templates
Task 1: Run Ad-Hoc Tasks on Registered Hosts
Subtask 1.1: Verify Remote Execution Prerequisites
First, let's ensure that remote execution is properly configured in your Satellite environment.

Access the Satellite Web Interface

# Open your web browser and navigate to:
https://satellite.example.com
Login with Administrator Credentials

Username: admin
Password: redhat123
Verify SSH Key Configuration

Navigate to Administer → Settings → Remote Execution
Confirm that SSH User is set to root
Verify SSH Key Passphrase is configured (if applicable)
Check Host Connectivity

Go to Hosts → All Hosts
Verify all client hosts show green status indicators
Note the Remote Execution column shows enabled status
Subtask 1.2: Execute Simple Ad-Hoc Commands
Now let's run some basic commands across multiple hosts simultaneously.

Navigate to Remote Execution Interface

Click Monitor → Jobs
Click Run Job button
Configure Your First Ad-Hoc Command

Job Category: Commands
Job Template: Run Command - SSH Default
Command:
uptime && free -h && df -h /
Select Target Hosts

Click Hosts tab
Select all three client hosts:
client1.example.com
client2.example.com
client3.example.com
Configure Execution Settings

Effective User: root
Timeout: 60 seconds
Concurrency Level: 3 (run on all hosts simultaneously)
Submit the Job

Click Submit to execute the command
Monitor the job progress in real-time
Subtask 1.3: Analyze Job Results
Review Job Output

Click on the job ID to view detailed results
Examine output from each host individually
Note any differences in system resources between hosts
Export Job Results

# From Satellite server command line, export job results
hammer job-invocation output --id <JOB_ID> --host client1.example.com
Subtask 1.4: Run Package Management Commands
Let's execute more complex administrative tasks across multiple hosts.

Create Package Update Job

Job Template: Package Action - SSH Default
Action: update
Package: * (all packages)
Target Hosts: Select client1.example.com only (for testing)
Monitor Package Updates

Watch the real-time output as packages are updated
Note the detailed logging of each package operation
Verify Package Installation

Job Template: Run Command - SSH Default
Command:
rpm -qa | grep -E "(httpd|nginx)" | sort
Task 2: Schedule Recurring Tasks for Host Maintenance
Subtask 2.1: Create Recurring Job Templates
Navigate to Job Templates

Go to Hosts → Job Templates
Click Create Template
Create System Health Check Template

Name: Weekly System Health Check
Job Category: Commands
Provider Type: SSH
Template:
#!/bin/bash
echo "=== System Health Check Report ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime)"
echo "Memory Usage:"
free -h
echo "Disk Usage:"
df -h
echo "Load Average:"
cat /proc/loadavg
echo "Failed Services:"
systemctl --failed --no-legend
echo "=== End Report ==="
Configure Template Parameters

Timeout: 120 seconds
Effective User: root
Description: Weekly automated system health monitoring
Subtask 2.2: Schedule Recurring Maintenance Tasks
Create Recurring Job Schedule

Navigate to Monitor → Recurring Logics
Click Create Recurring Logic
Configure Weekly Health Check Schedule

Cron Line: 0 2 * * 1 (Every Monday at 2 AM)
End Time: Set to 6 months from now
Purpose: System Health Monitoring
Associate with Job Template

Go to Monitor → Jobs
Click Run Job
Select your Weekly System Health Check template
Select target hosts
Click Schedule recurring
Link to your created recurring logic
Subtask 2.3: Create Log Rotation Job
Create Log Rotation Template

Name: Monthly Log Rotation
Template:
#!/bin/bash
# Rotate and compress old log files
/usr/sbin/logrotate -f /etc/logrotate.conf

# Clean old journal logs (keep 30 days)
journalctl --vacuum-time=30d

# Report disk space after cleanup
echo "Disk space after log rotation:"
df -h /var/log
Schedule Monthly Execution

Cron Line: 0 3 1 * * (First day of each month at 3 AM)
Apply to all production hosts
Subtask 2.4: Monitor Scheduled Jobs
View Recurring Job Status

Navigate to Monitor → Recurring Logics
Check status of all scheduled jobs
Review next execution times
Examine Job History

# From Satellite CLI, list recent jobs
hammer job-invocation list --per-page 20 --order "id DESC"

# Get details of specific recurring jobs
hammer recurring-logic list
Task 3: Integrate with Ansible for Task Automation
Subtask 3.1: Configure Ansible Integration
Verify Ansible Installation

# On Satellite server, check Ansible version
ansible --version

# Verify Ansible collections
ansible-galaxy collection list
Import Ansible Roles

Navigate to Configure → Ansible Roles
Click Import from satellite.example.com
Select roles to import (if any custom roles exist)
Subtask 3.2: Create Ansible Playbook Template
Create Custom Playbook

# On Satellite server, create playbook directory
mkdir -p /usr/share/foreman-proxy/ansible-runner/playbooks

# Create security hardening playbook
cat > /usr/share/foreman-proxy/ansible-runner/playbooks/security_hardening.yml << 'EOF'
---
- name: Basic Security Hardening
  hosts: all
  become: yes
  tasks:
    - name: Update all packages
      yum:
        name: "*"
        state: latest
      register: package_updates

    - name: Install security tools
      yum:
        name:
          - aide
          - fail2ban
          - rkhunter
        state: present

    - name: Configure fail2ban
      service:
        name: fail2ban
        state: started
        enabled: yes

    - name: Set password policy
      lineinfile:
        path: /etc/login.defs
        regexp: '^PASS_MIN_LEN'
        line: 'PASS_MIN_LEN 8'

    - name: Report results
      debug:
        msg: "Security hardening completed. {{ package_updates.changed }} packages updated."
EOF
Create Ansible Job Template in Satellite

Navigate to Hosts → Job Templates
Click Create Template
Name: Security Hardening Playbook
Job Category: Ansible Playbook
Provider Type: Ansible
Ansible Playbook: security_hardening.yml
Subtask 3.3: Execute Ansible Playbooks via Satellite
Run Security Hardening Playbook

Go to Monitor → Jobs
Click Run Job
Select Security Hardening Playbook template
Choose target hosts: client2.example.com and client3.example.com
Variables: Leave default or add custom variables:
extra_packages:
  - vim
  - htop
Monitor Ansible Execution

Watch real-time Ansible task execution
Note the structured output showing each task result
Observe how Ansible handles idempotency
Subtask 3.4: Create Complex Multi-Host Orchestration
Create Load Balancer Configuration Playbook ```bash cat > /usr/share/foreman-proxy/ansible-runner/playbooks/web_cluster_setup.yml << 'EOF'
name: Configure Web Servers hosts: webservers become: yes tasks:

name: Install Apache yum: name: httpd state: present

name: Create custom index page copy: content: |

Web Server: {{ inventory_hostname }}
Configured via Satellite + Ansible

Server Time: {{ ansible_date_time.iso8601 }}

dest: /var/www/html/index.html
name: Start and enable Apache service: name: httpd state: started enabled: yes

name: Open firewall for HTTP firewalld: service: http permanent: yes state: enabled immediate: yes

name: Configure Load Balancer hosts: loadbalancers become: yes tasks:

name: Install HAProxy yum: name: haproxy state: present

name: Configure HAProxy template: src: haproxy.cfg.j2 dest: /etc/haproxy/haproxy.cfg notify: restart haproxy

name: Start HAProxy service: name: haproxy state: started enabled: yes

handlers:

name: restart haproxy service: name: haproxy state: restarted
EOF


Execute Multi-Host Orchestration

Create job template for web cluster setup
Use host groups to target different server roles
Monitor coordinated deployment across multiple hosts
Subtask 3.5: Integrate with Satellite Smart Variables
Configure Ansible Variables in Satellite

Navigate to Configure → Global Parameters
Add parameters:
web_server_port: 80
max_connections: 100
environment: production
Use Variables in Playbooks

# Reference Satellite parameters in Ansible tasks
- name: Configure Apache port
  lineinfile:
    path: /etc/httpd/conf/httpd.conf
    regexp: '^Listen'
    line: "Listen {{ web_server_port | default(80) }}"
Troubleshooting Common Issues
SSH Connection Problems
# Test SSH connectivity from Satellite
ssh -i /usr/share/foreman-proxy/.ssh/id_rsa_foreman_proxy root@client1.example.com

# Check SSH key permissions
ls -la /usr/share/foreman-proxy/.ssh/
Job Execution Failures
Check Job Logs

Navigate to failed job in Satellite UI
Review detailed error messages
Check host-specific output
Verify Host Status

# Check if hosts are responsive
hammer host list --search "name ~ client"

# Test remote execution capability
hammer job-invocation create --job-template "Run Command - SSH Default" \
  --inputs command="echo 'test'" --search-query "name = client1.example.com"
Ansible Integration Issues
# Verify Ansible proxy configuration
systemctl status foreman-proxy

# Check Ansible runner logs
tail -f /var/log/foreman-proxy/proxy.log | grep -i ansible

# Test Ansible connectivity
ansible all -i /etc/foreman-proxy/ansible.cfg -m ping
Best Practices and Security Considerations
Security Best Practices
Use Least Privilege Principle

Create specific users for remote execution instead of using root
Implement sudo rules for specific commands only
SSH Key Management

# Rotate SSH keys regularly
ssh-keygen -t rsa -b 4096 -f /usr/share/foreman-proxy/.ssh/id_rsa_foreman_proxy_new

# Update key in Satellite settings
# Distribute new public key to all managed hosts
Job Template Security

Validate all input parameters
Avoid hardcoded credentials
Use Satellite's built-in parameter encryption
Performance Optimization
Concurrency Settings

Adjust concurrency levels based on network capacity
Consider host resources when running intensive tasks
Job Scheduling

Distribute maintenance windows across different time zones
Avoid scheduling multiple resource-intensive jobs simultaneously
Conclusion
In this lab, you have successfully learned how to leverage Red Hat Satellite's remote execution capabilities to manage your infrastructure efficiently. You accomplished the following key objectives:

What You Learned:

Ad-Hoc Command Execution: You can now execute commands across multiple hosts simultaneously, saving significant time compared to manual SSH connections to each server
Scheduled Automation: You've configured recurring maintenance tasks that will run automatically, ensuring consistent system health monitoring and maintenance
Ansible Integration: You've combined the power of Ansible automation with Satellite's centralized management, creating sophisticated orchestration workflows
Why This Matters: Remote execution through Satellite transforms how system administrators manage large-scale infrastructure. Instead of manually connecting to dozens or hundreds of servers, you can now:

Execute emergency patches across your entire infrastructure in minutes
Ensure consistent configuration management through automated playbooks
Maintain detailed audit logs of all administrative actions
Reduce human error through standardized, tested automation scripts
Real-World Applications: The skills you've developed are directly applicable to enterprise environments where you might need to:

Deploy security updates across thousands of servers during maintenance windows
Collect system information for compliance reporting
Orchestrate complex application deployments involving multiple server tiers
Respond quickly to security incidents by executing remediation scripts fleet-wide
This foundation in remote execution will significantly enhance your efficiency as a system administrator and prepare you for advanced Red Hat Satellite administration scenarios. The combination of immediate ad-hoc capabilities with long-term automation scheduling provides the flexibility needed in modern IT operations.
