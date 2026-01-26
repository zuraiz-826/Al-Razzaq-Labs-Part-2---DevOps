Lab 16: Automating Security with Ansible
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of Ansible for security automation
Create Ansible playbooks for system hardening tasks
Implement automated security configurations including SSH hardening and firewall rules
Apply security configurations across multiple systems simultaneously
Validate and verify security configurations using Ansible
Troubleshoot common issues in Ansible security automation
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with SSH concepts and key-based authentication
Basic knowledge of firewall concepts (iptables/firewalld)
Understanding of YAML syntax fundamentals
Basic networking concepts (ports, protocols, IP addresses)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your lab environment includes:

Control Node: CentOS/RHEL 8 system with Ansible pre-installed
Managed Nodes: 2-3 target systems for applying security configurations
All necessary SSH keys and connectivity pre-configured
Task 1: Setting Up Ansible Environment and Inventory
Subtask 1.1: Verify Ansible Installation and Configuration
First, let's verify that Ansible is properly installed and configured on your control node.

Connect to your control node via SSH or terminal
Check Ansible version:
ansible --version
Verify the default Ansible configuration:
ansible-config view
Check the default inventory location:
ls -la /etc/ansible/
Subtask 1.2: Create Custom Inventory File
Create a custom inventory file for your managed nodes:

Create a project directory:
mkdir ~/security-automation
cd ~/security-automation
Create an inventory file:
cat > inventory.ini << 'EOF'
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=centos
web2 ansible_host=192.168.1.11 ansible_user=centos

[databases]
db1 ansible_host=192.168.1.20 ansible_user=centos

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
Note: Replace the IP addresses with the actual IP addresses of your managed nodes provided in your lab environment.

Test connectivity to all managed nodes:
ansible all -i inventory.ini -m ping
Subtask 1.3: Create Ansible Configuration File
Create a custom ansible.cfg file for your project:

cat > ansible.cfg << 'EOF'
[defaults]
inventory = inventory.ini
host_key_checking = False
remote_user = centos
private_key_file = ~/.ssh/id_rsa
timeout = 30
gathering = smart
fact_caching = memory

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
EOF
Task 2: Creating Security Hardening Playbooks
Subtask 2.1: SSH Security Hardening Playbook
Create a comprehensive SSH hardening playbook:

cat > ssh-hardening.yml << 'EOF'
---
- name: SSH Security Hardening
  hosts: all
  become: yes
  vars:
    ssh_config_file: /etc/ssh/sshd_config
    backup_suffix: ".backup.{{ ansible_date_time.epoch }}"
  
  tasks:
    - name: Backup original SSH configuration
      copy:
        src: "{{ ssh_config_file }}"
        dest: "{{ ssh_config_file }}{{ backup_suffix }}"
        remote_src: yes
      
    - name: Disable root login via SSH
      lineinfile:
        path: "{{ ssh_config_file }}"
        regexp: '^#?PermitRootLogin'
        line: 'PermitRootLogin no'
        backup: yes
      notify: restart sshd
      
    - name: Disable password authentication
      lineinfile:
        path: "{{ ssh_config_file }}"
        regexp: '^#?PasswordAuthentication'
        line: 'PasswordAuthentication no'
      notify: restart sshd
      
    - name: Disable empty passwords
      lineinfile:
        path: "{{ ssh_config_file }}"
        regexp: '^#?PermitEmptyPasswords'
        line: 'PermitEmptyPasswords no'
      notify: restart sshd
      
    - name: Set maximum authentication attempts
      lineinfile:
        path: "{{ ssh_config_file }}"
        regexp: '^#?MaxAuthTries'
        line: 'MaxAuthTries 3'
      notify: restart sshd
      
    - name: Set client alive interval
      lineinfile:
        path: "{{ ssh_config_file }}"
        regexp: '^#?ClientAliveInterval'
        line: 'ClientAliveInterval 300'
      notify: restart sshd
      
    - name: Set client alive count max
      lineinfile:
        path: "{{ ssh_config_file }}"
        regexp: '^#?ClientAliveCountMax'
        line: 'ClientAliveCountMax 2'
      notify: restart sshd
      
    - name: Disable X11 forwarding
      lineinfile:
        path: "{{ ssh_config_file }}"
        regexp: '^#?X11Forwarding'
        line: 'X11Forwarding no'
      notify: restart sshd
      
    - name: Set SSH protocol version 2
      lineinfile:
        path: "{{ ssh_config_file }}"
        regexp: '^#?Protocol'
        line: 'Protocol 2'
      notify: restart sshd
      
    - name: Configure allowed users (optional)
      lineinfile:
        path: "{{ ssh_config_file }}"
        regexp: '^#?AllowUsers'
        line: 'AllowUsers centos'
      notify: restart sshd
      when: ssh_allow_users is defined
      
    - name: Validate SSH configuration
      command: sshd -t
      changed_when: false
      
  handlers:
    - name: restart sshd
      systemd:
        name: sshd
        state: restarted
        enabled: yes
EOF
Subtask 2.2: Firewall Configuration Playbook
Create a firewall hardening playbook:

cat > firewall-hardening.yml << 'EOF'
---
- name: Firewall Security Configuration
  hosts: all
  become: yes
  vars:
    allowed_ports:
      - 22/tcp    # SSH
      - 80/tcp    # HTTP
      - 443/tcp   # HTTPS
    
  tasks:
    - name: Install firewalld
      package:
        name: firewalld
        state: present
        
    - name: Start and enable firewalld
      systemd:
        name: firewalld
        state: started
        enabled: yes
        
    - name: Set default zone to drop
      firewalld:
        zone: drop
        state: present
        permanent: yes
        immediate: yes
        
    - name: Configure public zone as default
      command: firewall-cmd --set-default-zone=public
      
    - name: Remove unnecessary services from public zone
      firewalld:
        zone: public
        service: "{{ item }}"
        permanent: yes
        immediate: yes
        state: disabled
      loop:
        - dhcpv6-client
        - cockpit
      ignore_errors: yes
      
    - name: Allow essential ports in public zone
      firewalld:
        zone: public
        port: "{{ item }}"
        permanent: yes
        immediate: yes
        state: enabled
      loop: "{{ allowed_ports }}"
      
    - name: Enable SSH service in public zone
      firewalld:
        zone: public
        service: ssh
        permanent: yes
        immediate: yes
        state: enabled
        
    - name: Configure rate limiting for SSH
      firewalld:
        zone: public
        rich_rule: 'rule service name="ssh" accept limit value="3/m"'
        permanent: yes
        immediate: yes
        state: enabled
        
    - name: Block common attack ports
      firewalld:
        zone: public
        port: "{{ item }}"
        permanent: yes
        immediate: yes
        state: disabled
      loop:
        - 23/tcp    # Telnet
        - 135/tcp   # RPC
        - 139/tcp   # NetBIOS
        - 445/tcp   # SMB
        - 1433/tcp  # SQL Server
        - 3389/tcp  # RDP
      ignore_errors: yes
      
    - name: Reload firewalld configuration
      command: firewall-cmd --reload
EOF
Subtask 2.3: System Security Hardening Playbook
Create a comprehensive system hardening playbook:

cat > system-hardening.yml << 'EOF'
---
- name: System Security Hardening
  hosts: all
  become: yes
  
  tasks:
    - name: Update all packages
      package:
        name: '*'
        state: latest
      when: ansible_os_family == "RedHat"
      
    - name: Install security packages
      package:
        name:
          - fail2ban
          - aide
          - rkhunter
          - chkrootkit
        state: present
        
    - name: Configure fail2ban for SSH
      copy:
        content: |
          [sshd]
          enabled = true
          port = ssh
          filter = sshd
          logpath = /var/log/secure
          maxretry = 3
          bantime = 3600
          findtime = 600
        dest: /etc/fail2ban/jail.d/sshd.conf
      notify: restart fail2ban
      
    - name: Start and enable fail2ban
      systemd:
        name: fail2ban
        state: started
        enabled: yes
        
    - name: Set password policy - minimum length
      lineinfile:
        path: /etc/security/pwquality.conf
        regexp: '^#?minlen'
        line: 'minlen = 8'
        
    - name: Set password policy - complexity
      lineinfile:
        path: /etc/security/pwquality.conf
        regexp: '^#?minclass'
        line: 'minclass = 3'
        
    - name: Configure login timeout
      lineinfile:
        path: /etc/profile
        line: 'export TMOUT=900'
        
    - name: Disable unused network protocols
      copy:
        content: |
          install dccp /bin/true
          install sctp /bin/true
          install rds /bin/true
          install tipc /bin/true
        dest: /etc/modprobe.d/blacklist-rare-network.conf
        
    - name: Set kernel parameters for security
      sysctl:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
        state: present
        reload: yes
      loop:
        - { name: 'net.ipv4.ip_forward', value: '0' }
        - { name: 'net.ipv4.conf.all.send_redirects', value: '0' }
        - { name: 'net.ipv4.conf.default.send_redirects', value: '0' }
        - { name: 'net.ipv4.conf.all.accept_redirects', value: '0' }
        - { name: 'net.ipv4.conf.default.accept_redirects', value: '0' }
        - { name: 'net.ipv4.conf.all.secure_redirects', value: '0' }
        - { name: 'net.ipv4.conf.default.secure_redirects', value: '0' }
        - { name: 'net.ipv4.conf.all.log_martians', value: '1' }
        - { name: 'net.ipv4.conf.default.log_martians', value: '1' }
        - { name: 'net.ipv4.icmp_echo_ignore_broadcasts', value: '1' }
        - { name: 'net.ipv4.icmp_ignore_bogus_error_responses', value: '1' }
        - { name: 'net.ipv4.tcp_syncookies', value: '1' }
        
    - name: Remove unnecessary packages
      package:
        name:
          - telnet
          - rsh
          - ypbind
          - ypserv
          - tftp
          - tftp-server
          - talk
          - talk-server
        state: absent
      ignore_errors: yes
      
    - name: Set file permissions on sensitive files
      file:
        path: "{{ item }}"
        mode: '0600'
        owner: root
        group: root
      loop:
        - /etc/ssh/sshd_config
        - /etc/shadow
        - /etc/gshadow
      ignore_errors: yes
      
  handlers:
    - name: restart fail2ban
      systemd:
        name: fail2ban
        state: restarted
EOF
Task 3: Applying Security Configurations to Multiple Systems
Subtask 3.1: Execute SSH Hardening Playbook
Apply SSH security configurations across all managed nodes:

Run the SSH hardening playbook:
ansible-playbook ssh-hardening.yml -v
Verify SSH configuration changes:
ansible all -m shell -a "grep -E '^(PermitRootLogin|PasswordAuthentication|MaxAuthTries)' /etc/ssh/sshd_config"
Check SSH service status:
ansible all -m systemd -a "name=sshd state=started enabled=yes" --become
Subtask 3.2: Execute Firewall Hardening Playbook
Apply firewall configurations to all systems:

Run the firewall hardening playbook:
ansible-playbook firewall-hardening.yml -v
Verify firewall status:
ansible all -m shell -a "firewall-cmd --state" --become
Check active firewall rules:
ansible all -m shell -a "firewall-cmd --list-all" --become
Subtask 3.3: Execute System Hardening Playbook
Apply comprehensive system hardening:

Run the system hardening playbook:
ansible-playbook system-hardening.yml -v
Verify fail2ban installation and status:
ansible all -m systemd -a "name=fail2ban" --become
Check kernel security parameters:
ansible all -m shell -a "sysctl net.ipv4.ip_forward net.ipv4.tcp_syncookies" --become
Subtask 3.4: Create Master Security Playbook
Create a master playbook that combines all security measures:

cat > master-security.yml << 'EOF'
---
- import_playbook: ssh-hardening.yml
- import_playbook: firewall-hardening.yml  
- import_playbook: system-hardening.yml

- name: Final Security Validation
  hosts: all
  become: yes
  
  tasks:
    - name: Generate security report
      shell: |
        echo "=== Security Configuration Report ===" > /tmp/security_report.txt
        echo "Date: $(date)" >> /tmp/security_report.txt
        echo "" >> /tmp/security_report.txt
        echo "SSH Configuration:" >> /tmp/security_report.txt
        grep -E '^(PermitRootLogin|PasswordAuthentication|MaxAuthTries)' /etc/ssh/sshd_config >> /tmp/security_report.txt
        echo "" >> /tmp/security_report.txt
        echo "Firewall Status:" >> /tmp/security_report.txt
        firewall-cmd --state >> /tmp/security_report.txt
        echo "" >> /tmp/security_report.txt
        echo "Active Services:" >> /tmp/security_report.txt
        systemctl list-units --type=service --state=active | grep -E '(sshd|firewalld|fail2ban)' >> /tmp/security_report.txt
        
    - name: Fetch security reports
      fetch:
        src: /tmp/security_report.txt
        dest: ./reports/{{ inventory_hostname }}_security_report.txt
        flat: yes
EOF
Create reports directory and run master playbook:
mkdir -p reports
ansible-playbook master-security.yml
Task 4: Security Configuration Validation and Monitoring
Subtask 4.1: Create Security Validation Playbook
Create a playbook to validate security configurations:

cat > security-validation.yml << 'EOF'
---
- name: Security Configuration Validation
  hosts: all
  become: yes
  
  tasks:
    - name: Check SSH root login is disabled
      shell: grep "^PermitRootLogin no" /etc/ssh/sshd_config
      register: ssh_root_check
      failed_when: ssh_root_check.rc != 0
      
    - name: Check password authentication is disabled
      shell: grep "^PasswordAuthentication no" /etc/ssh/sshd_config
      register: ssh_password_check
      failed_when: ssh_password_check.rc != 0
      
    - name: Verify firewalld is active
      systemd:
        name: firewalld
      register: firewall_status
      failed_when: firewall_status.status.ActiveState != "active"
      
    - name: Check fail2ban is running
      systemd:
        name: fail2ban
      register: fail2ban_status
      failed_when: fail2ban_status.status.ActiveState != "active"
      
    - name: Verify SSH service is running
      systemd:
        name: sshd
      register: sshd_status
      failed_when: sshd_status.status.ActiveState != "active"
      
    - name: Check for unauthorized users
      shell: awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd
      register: user_check
      
    - name: Display validation results
      debug:
        msg: |
          Security Validation Results:
          - SSH Root Login: {{ 'DISABLED' if ssh_root_check.rc == 0 else 'ENABLED' }}
          - SSH Password Auth: {{ 'DISABLED' if ssh_password_check.rc == 0 else 'ENABLED' }}
          - Firewall Status: {{ firewall_status.status.ActiveState }}
          - Fail2ban Status: {{ fail2ban_status.status.ActiveState }}
          - SSH Service: {{ sshd_status.status.ActiveState }}
          - Regular Users: {{ user_check.stdout_lines | join(', ') }}
EOF
Subtask 4.2: Run Security Validation
Execute the validation playbook:

ansible-playbook security-validation.yml
Subtask 4.3: Create Security Monitoring Playbook
Create a playbook for ongoing security monitoring:

cat > security-monitoring.yml << 'EOF'
---
- name: Security Monitoring and Alerting
  hosts: all
  become: yes
  
  tasks:
    - name: Check for failed SSH login attempts
      shell: grep "Failed password" /var/log/secure | tail -10
      register: failed_logins
      ignore_errors: yes
      
    - name: Check fail2ban status and banned IPs
      shell: fail2ban-client status sshd
      register: fail2ban_status
      ignore_errors: yes
      
    - name: Check for suspicious network connections
      shell: netstat -tuln | grep LISTEN
      register: listening_ports
      
    - name: Check system load
      shell: uptime
      register: system_load
      
    - name: Check disk usage
      shell: df -h | grep -E '^/dev/'
      register: disk_usage
      
    - name: Generate monitoring report
      copy:
        content: |
          === Security Monitoring Report ===
          Generated: {{ ansible_date_time.iso8601 }}
          Host: {{ inventory_hostname }}
          
          Recent Failed SSH Logins:
          {{ failed_logins.stdout }}
          
          Fail2ban Status:
          {{ fail2ban_status.stdout }}
          
          Listening Ports:
          {{ listening_ports.stdout }}
          
          System Load:
          {{ system_load.stdout }}
          
          Disk Usage:
          {{ disk_usage.stdout }}
        dest: /tmp/monitoring_report_{{ ansible_date_time.epoch }}.txt
        
    - name: Fetch monitoring reports
      fetch:
        src: /tmp/monitoring_report_{{ ansible_date_time.epoch }}.txt
        dest: ./monitoring/{{ inventory_hostname }}_{{ ansible_date_time.date }}.txt
        flat: yes
EOF
Subtask 4.4: Execute Monitoring Playbook
Run the monitoring playbook:

mkdir -p monitoring
ansible-playbook security-monitoring.yml
Troubleshooting Common Issues
SSH Connection Issues
If you encounter SSH connection problems after hardening:

Check if SSH service is running:
ansible all -m systemd -a "name=sshd" --become
Validate SSH configuration:
ansible all -m shell -a "sshd -t" --become
Check SSH logs:
ansible all -m shell -a "tail -20 /var/log/secure" --become
Firewall Connectivity Issues
If systems become unreachable after firewall configuration:

Check firewall status:
ansible all -m shell -a "systemctl status firewalld" --become
Temporarily disable firewall for troubleshooting:
ansible all -m systemd -a "name=firewalld state=stopped" --become
Check firewall rules:
ansible all -m shell -a "firewall-cmd --list-all-zones" --become
Playbook Execution Errors
Common solutions for playbook failures:

Run with increased verbosity:
ansible-playbook playbook-name.yml -vvv
Check syntax:
ansible-playbook playbook-name.yml --syntax-check
Run in check mode first:
ansible-playbook playbook-name.yml --check
Advanced Security Automation
Creating Custom Security Roles
Create a reusable Ansible role for security hardening:

mkdir -p roles/security-hardening/{tasks,handlers,vars,templates,files}
Create the main tasks file:

cat > roles/security-hardening/tasks/main.yml << 'EOF'
---
- include_tasks: ssh-hardening.yml
- include_tasks: firewall-config.yml
- include_tasks: system-hardening.yml
- include_tasks: monitoring-setup.yml
EOF
Implementing Security Compliance Checks
Create a compliance checking playbook:

cat > compliance-check.yml << 'EOF'
---
- name: Security Compliance Verification
  hosts: all
  become: yes
  vars:
    compliance_report: /tmp/compliance_report.json
    
  tasks:
    - name: Initialize compliance report
      copy:
        content: |
          {
            "host": "{{ inventory_hostname }}",
            "timestamp": "{{ ansible_date_time.iso8601 }}",
            "checks": {}
          }
        dest: "{{ compliance_report }}"
        
    - name: Check CIS benchmark compliance
      block:
        - name: Verify SSH protocol version
          shell: grep "^Protocol 2" /etc/ssh/sshd_config
          register: ssh_protocol
          
        - name: Update compliance report - SSH Protocol
          lineinfile:
            path: "{{ compliance_report }}"
            insertbefore: '  }'
            line: '    "ssh_protocol_v2": {{ "true" if ssh_protocol.rc == 0 else "false" }},'
            
        - name: Check firewall status
          systemd:
            name: firewalld
          register: fw_status
          
        - name: Update compliance report - Firewall
          lineinfile:
            path: "{{ compliance_report }}"
            insertbefore: '  }'
            line: '    "firewall_active": {{ "true" if fw_status.status.ActiveState == "active" else "false" }},'
            
    - name: Fetch compliance reports
      fetch:
        src: "{{ compliance_report }}"
        dest: ./compliance/{{ inventory_hostname }}_compliance.json
        flat: yes
EOF
Conclusion
In this comprehensive lab, you have successfully:

Automated SSH Security: Created and deployed Ansible playbooks that disable root login, enforce key-based authentication, and implement connection limits across multiple systems simultaneously.

Implemented Firewall Automation: Developed automated firewall configurations using firewalld, including rate limiting, port management, and attack prevention rules.

Applied System Hardening: Automated the installation and configuration of security tools like fail2ban, implemented kernel security parameters, and removed unnecessary packages.

Created Validation and Monitoring: Built automated security validation checks and monitoring systems to ensure configurations remain compliant and detect security issues.

Developed Reusable Security Automation: Created modular, reusable Ansible playbooks and roles that can be applied across different environments and scaled to hundreds of systems.

Why This Matters: Security automation with Ansible is crucial in modern IT environments because it ensures consistent security configurations across all systems, reduces human error, and enables rapid response to security threats. This approach is essential for maintaining compliance with security standards like CIS benchmarks and is a key skill for Red Hat Certified Security specialists.

The skills you've developed in this lab directly apply to real-world scenarios where organizations need to maintain security across large server fleets, ensure compliance with security policies, and respond quickly to emerging threats through automated remediation.

Your automated security configurations can now be version-controlled, tested, and deployed consistently across development, staging, and production environments, making your infrastructure more secure and manageable.
