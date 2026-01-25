Lab 19: Advanced Ansible Automation for Security
Objectives
By the end of this lab, students will be able to:

Automate security policy configurations using Ansible playbooks
Configure and manage SELinux settings across multiple systems
Implement automated firewall rule management for different network zones
Secure user accounts and manage permissions using Ansible automation
Deploy consistent security configurations across multiple environments
Troubleshoot common security automation issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface
Knowledge of YAML syntax fundamentals
Understanding of basic networking concepts
Previous experience with Ansible basics (inventory, playbooks, modules)
Knowledge of SSH key-based authentication
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: 3 target systems (web server, database server, application server)
All systems are pre-configured with SSH key authentication
Task 1: Automate Security Policies and SELinux Configuration
Subtask 1.1: Create Ansible Inventory
First, let's set up our inventory file to define our managed hosts.

Connect to your control node and create the inventory file:
mkdir -p ~/ansible-security-lab
cd ~/ansible-security-lab
Create the inventory file:
nano inventory.ini
Add the following content:
[webservers]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[databases]
db1 ansible_host=192.168.1.20

[appservers]
app1 ansible_host=192.168.1.30

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
Subtask 1.2: Create SELinux Configuration Playbook
Create a playbook for SELinux management:
nano selinux-config.yml
Add the following playbook content:
---
- name: Configure SELinux Security Policies
  hosts: all
  become: yes
  vars:
    selinux_state: enforcing
    selinux_policy: targeted
    
  tasks:
    - name: Install SELinux management tools
      yum:
        name:
          - policycoreutils
          - policycoreutils-python-utils
          - selinux-policy
          - selinux-policy-targeted
          - setroubleshoot-server
        state: present

    - name: Set SELinux to enforcing mode
      selinux:
        policy: "{{ selinux_policy }}"
        state: "{{ selinux_state }}"
      register: selinux_result

    - name: Reboot if SELinux state changed
      reboot:
        reboot_timeout: 300
      when: selinux_result.reboot_required

    - name: Configure SELinux booleans for web services
      seboolean:
        name: "{{ item }}"
        state: yes
        persistent: yes
      loop:
        - httpd_can_network_connect
        - httpd_can_network_connect_db
        - httpd_execmem
      when: inventory_hostname in groups['webservers']

    - name: Configure SELinux booleans for database services
      seboolean:
        name: "{{ item }}"
        state: yes
        persistent: yes
      loop:
        - mysql_connect_any
        - selinuxuser_mysql_connect_enabled
      when: inventory_hostname in groups['databases']

    - name: Set SELinux file contexts for web content
      sefcontext:
        target: '/var/www/html(/.*)?'
        setype: httpd_exec_t
        state: present
      when: inventory_hostname in groups['webservers']

    - name: Apply SELinux file contexts
      command: restorecon -R /var/www/html
      when: inventory_hostname in groups['webservers']
      ignore_errors: yes

    - name: Verify SELinux status
      command: sestatus
      register: selinux_status
      changed_when: false

    - name: Display SELinux status
      debug:
        var: selinux_status.stdout_lines
Run the SELinux configuration playbook:
ansible-playbook -i inventory.ini selinux-config.yml
Subtask 1.3: Create Security Hardening Playbook
Create a comprehensive security hardening playbook:
nano security-hardening.yml
Add the following content:
---
- name: System Security Hardening
  hosts: all
  become: yes
  vars:
    max_login_attempts: 3
    password_max_age: 90
    password_min_age: 7
    
  tasks:
    - name: Update all packages
      yum:
        name: '*'
        state: latest
        update_cache: yes

    - name: Install security packages
      yum:
        name:
          - aide
          - fail2ban
          - rkhunter
          - chkrootkit
        state: present

    - name: Configure password aging policies
      lineinfile:
        path: /etc/login.defs
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        backup: yes
      loop:
        - { regexp: '^PASS_MAX_DAYS', line: 'PASS_MAX_DAYS {{ password_max_age }}' }
        - { regexp: '^PASS_MIN_DAYS', line: 'PASS_MIN_DAYS {{ password_min_age }}' }
        - { regexp: '^PASS_WARN_AGE', line: 'PASS_WARN_AGE 7' }

    - name: Configure account lockout policy
      lineinfile:
        path: /etc/pam.d/system-auth
        line: 'auth required pam_faillock.so preauth audit silent deny={{ max_login_attempts }} unlock_time=900'
        insertafter: '^auth.*pam_env.so'
        backup: yes

    - name: Disable unused network services
      systemd:
        name: "{{ item }}"
        state: stopped
        enabled: no
      loop:
        - rpcbind
        - nfs-server
        - cups
      ignore_errors: yes

    - name: Configure kernel parameters for security
      sysctl:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
        state: present
        reload: yes
      loop:
        - { name: 'net.ipv4.ip_forward', value: '0' }
        - { name: 'net.ipv4.conf.all.send_redirects', value: '0' }
        - { name: 'net.ipv4.conf.all.accept_redirects', value: '0' }
        - { name: 'net.ipv4.conf.all.accept_source_route', value: '0' }
        - { name: 'net.ipv4.icmp_echo_ignore_broadcasts', value: '1' }

    - name: Initialize AIDE database
      command: aide --init
      args:
        creates: /var/lib/aide/aide.db.new.gz

    - name: Move AIDE database to production location
      command: mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
      args:
        creates: /var/lib/aide/aide.db.gz
Execute the security hardening playbook:
ansible-playbook -i inventory.ini security-hardening.yml
Task 2: Configure Firewall Rules for Various Zones
Subtask 2.1: Create Firewall Configuration Playbook
Create a comprehensive firewall management playbook:
nano firewall-config.yml
Add the following content:
---
- name: Configure Firewall Rules and Zones
  hosts: all
  become: yes
  vars:
    default_zone: public
    
  tasks:
    - name: Install firewalld
      yum:
        name: firewalld
        state: present

    - name: Start and enable firewalld
      systemd:
        name: firewalld
        state: started
        enabled: yes

    - name: Set default zone
      firewalld:
        zone: "{{ default_zone }}"
        state: enabled
        permanent: yes
        immediate: yes

    - name: Configure web server firewall rules
      firewalld:
        service: "{{ item }}"
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
      loop:
        - http
        - https
        - ssh
      when: inventory_hostname in groups['webservers']

    - name: Configure database server firewall rules
      firewalld:
        port: "{{ item }}"
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
      loop:
        - 3306/tcp
        - 22/tcp
      when: inventory_hostname in groups['databases']

    - name: Configure application server firewall rules
      firewalld:
        port: "{{ item }}"
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
      loop:
        - 8080/tcp
        - 8443/tcp
        - 22/tcp
      when: inventory_hostname in groups['appservers']

    - name: Create custom zone for internal services
      firewalld:
        zone: internal
        state: present
        permanent: yes

    - name: Configure internal zone for database access
      firewalld:
        source: "{{ item }}"
        zone: internal
        permanent: yes
        immediate: yes
        state: enabled
      loop:
        - 192.168.1.0/24
      when: inventory_hostname in groups['databases']

    - name: Allow database port in internal zone
      firewalld:
        port: 3306/tcp
        zone: internal
        permanent: yes
        immediate: yes
        state: enabled
      when: inventory_hostname in groups['databases']

    - name: Block specific IP ranges (example security rule)
      firewalld:
        rich_rule: 'rule family="ipv4" source address="10.0.0.0/8" drop'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled

    - name: Configure rate limiting for SSH
      firewalld:
        rich_rule: 'rule service name="ssh" accept limit value="3/m"'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled

    - name: Reload firewalld configuration
      command: firewall-cmd --reload
Subtask 2.2: Create Advanced Firewall Rules Playbook
Create an advanced firewall rules playbook:
nano advanced-firewall.yml
Add the following content:
---
- name: Advanced Firewall Configuration
  hosts: all
  become: yes
  
  tasks:
    - name: Create DMZ zone for web servers
      firewalld:
        zone: dmz
        state: present
        permanent: yes
      when: inventory_hostname in groups['webservers']

    - name: Configure DMZ zone interface
      firewalld:
        zone: dmz
        interface: eth0
        permanent: yes
        immediate: yes
        state: enabled
      when: inventory_hostname in groups['webservers']

    - name: Allow web services in DMZ
      firewalld:
        service: "{{ item }}"
        zone: dmz
        permanent: yes
        immediate: yes
        state: enabled
      loop:
        - http
        - https
      when: inventory_hostname in groups['webservers']

    - name: Configure port forwarding for load balancer
      firewalld:
        rich_rule: 'rule family=ipv4 forward-port port=80 protocol=tcp to-port=8080'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
      when: inventory_hostname in groups['webservers']

    - name: Log dropped packets
      firewalld:
        rich_rule: 'rule drop log prefix="FIREWALL-DROP: "'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled

    - name: Verify firewall status
      command: firewall-cmd --list-all-zones
      register: firewall_status
      changed_when: false

    - name: Display firewall configuration
      debug:
        var: firewall_status.stdout_lines
Run the firewall configuration playbooks:
ansible-playbook -i inventory.ini firewall-config.yml
ansible-playbook -i inventory.ini advanced-firewall.yml
Task 3: Secure User Accounts and Permissions with Ansible
Subtask 3.1: Create User Management Playbook
Create a comprehensive user management playbook:
nano user-management.yml
Add the following content:
---
- name: Secure User Account Management
  hosts: all
  become: yes
  vars:
    admin_users:
      - name: secadmin
        groups: wheel
        shell: /bin/bash
        password: "$6$rounds=656000$salt$hashed_password_here"
      - name: webadmin
        groups: apache
        shell: /bin/bash
        password: "$6$rounds=656000$salt$hashed_password_here"
    
    service_users:
      - name: webapp
        system: yes
        shell: /sbin/nologin
        home: /var/lib/webapp
      - name: dbuser
        system: yes
        shell: /sbin/nologin
        home: /var/lib/mysql

  tasks:
    - name: Create admin users
      user:
        name: "{{ item.name }}"
        groups: "{{ item.groups }}"
        shell: "{{ item.shell }}"
        password: "{{ item.password }}"
        state: present
        create_home: yes
      loop: "{{ admin_users }}"

    - name: Create service users
      user:
        name: "{{ item.name }}"
        system: "{{ item.system | default(false) }}"
        shell: "{{ item.shell }}"
        home: "{{ item.home }}"
        state: present
        create_home: yes
      loop: "{{ service_users }}"

    - name: Configure SSH keys for admin users
      authorized_key:
        user: "{{ item.name }}"
        key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
        state: present
      loop: "{{ admin_users }}"

    - name: Configure sudo access for admin users
      lineinfile:
        path: /etc/sudoers.d/admin-users
        line: "{{ item.name }} ALL=(ALL) NOPASSWD: ALL"
        create: yes
        validate: 'visudo -cf %s'
      loop: "{{ admin_users }}"
      when: "'wheel' in item.groups"

    - name: Set password policies for users
      user:
        name: "{{ item.name }}"
        password_expire_max: 90
        password_expire_min: 7
        password_expire_warn: 7
      loop: "{{ admin_users }}"

    - name: Lock unused system accounts
      user:
        name: "{{ item }}"
        password_lock: yes
      loop:
        - games
        - ftp
        - nobody
      ignore_errors: yes

    - name: Remove unnecessary users
      user:
        name: "{{ item }}"
        state: absent
        remove: yes
      loop:
        - guest
        - test
      ignore_errors: yes

    - name: Configure login banner
      copy:
        content: |
          **************************************************************************
          *                                                                        *
          *  This system is for authorized users only. All activity is monitored  *
          *  and logged. Unauthorized access is prohibited and will be prosecuted *
          *  to the full extent of the law.                                       *
          *                                                                        *
          **************************************************************************
        dest: /etc/issue
        owner: root
        group: root
        mode: '0644'

    - name: Configure SSH banner
      copy:
        src: /etc/issue
        dest: /etc/issue.net
        remote_src: yes
        owner: root
        group: root
        mode: '0644'
Subtask 3.2: Create SSH Security Configuration Playbook
Create an SSH hardening playbook:
nano ssh-security.yml
Add the following content:
---
- name: SSH Security Configuration
  hosts: all
  become: yes
  
  tasks:
    - name: Backup original SSH configuration
      copy:
        src: /etc/ssh/sshd_config
        dest: /etc/ssh/sshd_config.backup
        remote_src: yes
        backup: yes

    - name: Configure SSH security settings
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        backup: yes
      loop:
        - { regexp: '^#?PermitRootLogin', line: 'PermitRootLogin no' }
        - { regexp: '^#?PasswordAuthentication', line: 'PasswordAuthentication no' }
        - { regexp: '^#?PubkeyAuthentication', line: 'PubkeyAuthentication yes' }
        - { regexp: '^#?Protocol', line: 'Protocol 2' }
        - { regexp: '^#?MaxAuthTries', line: 'MaxAuthTries 3' }
        - { regexp: '^#?ClientAliveInterval', line: 'ClientAliveInterval 300' }
        - { regexp: '^#?ClientAliveCountMax', line: 'ClientAliveCountMax 2' }
        - { regexp: '^#?LoginGraceTime', line: 'LoginGraceTime 60' }
        - { regexp: '^#?Banner', line: 'Banner /etc/issue.net' }
        - { regexp: '^#?X11Forwarding', line: 'X11Forwarding no' }
      notify: restart sshd

    - name: Allow specific users SSH access
      lineinfile:
        path: /etc/ssh/sshd_config
        line: "AllowUsers secadmin webadmin ansible"
        insertafter: EOF
      notify: restart sshd

    - name: Deny specific groups SSH access
      lineinfile:
        path: /etc/ssh/sshd_config
        line: "DenyGroups games ftp"
        insertafter: EOF
      notify: restart sshd

    - name: Validate SSH configuration
      command: sshd -t
      changed_when: false

  handlers:
    - name: restart sshd
      systemd:
        name: sshd
        state: restarted
Subtask 3.3: Create File Permissions and Access Control Playbook
Create a file permissions playbook:
nano file-permissions.yml
Add the following content:
---
- name: Configure File Permissions and Access Control
  hosts: all
  become: yes
  
  tasks:
    - name: Set secure permissions on sensitive files
      file:
        path: "{{ item.path }}"
        owner: "{{ item.owner }}"
        group: "{{ item.group }}"
        mode: "{{ item.mode }}"
      loop:
        - { path: '/etc/passwd', owner: 'root', group: 'root', mode: '0644' }
        - { path: '/etc/shadow', owner: 'root', group: 'shadow', mode: '0640' }
        - { path: '/etc/group', owner: 'root', group: 'root', mode: '0644' }
        - { path: '/etc/gshadow', owner: 'root', group: 'shadow', mode: '0640' }
        - { path: '/etc/ssh/sshd_config', owner: 'root', group: 'root', mode: '0600' }

    - name: Create secure directories for applications
      file:
        path: "{{ item.path }}"
        state: directory
        owner: "{{ item.owner }}"
        group: "{{ item.group }}"
        mode: "{{ item.mode }}"
      loop:
        - { path: '/var/log/secure-apps', owner: 'root', group: 'root', mode: '0750' }
        - { path: '/etc/security/custom', owner: 'root', group: 'root', mode: '0700' }
        - { path: '/var/lib/webapp', owner: 'webapp', group: 'webapp', mode: '0750' }
      when: inventory_hostname in groups['webservers']

    - name: Configure ACLs for shared directories
      acl:
        path: /var/log/secure-apps
        entity: webadmin
        etype: user
        permissions: rw
        state: present
      when: inventory_hostname in groups['webservers']

    - name: Set immutable attribute on critical files
      file:
        path: "{{ item }}"
        attributes: +i
      loop:
        - /etc/passwd
        - /etc/group
      ignore_errors: yes

    - name: Configure log rotation for security logs
      copy:
        content: |
          /var/log/secure {
              weekly
              rotate 52
              compress
              delaycompress
              missingok
              notifempty
              create 0600 root root
          }
        dest: /etc/logrotate.d/security-logs
        owner: root
        group: root
        mode: '0644'

    - name: Verify file permissions
      command: ls -la {{ item }}
      loop:
        - /etc/passwd
        - /etc/shadow
        - /etc/ssh/sshd_config
      register: file_perms
      changed_when: false

    - name: Display file permissions
      debug:
        var: file_perms.results
Run the user management and security playbooks:
ansible-playbook -i inventory.ini user-management.yml
ansible-playbook -i inventory.ini ssh-security.yml
ansible-playbook -i inventory.ini file-permissions.yml
Subtask 3.4: Create Security Monitoring Playbook
Create a security monitoring and auditing playbook:
nano security-monitoring.yml
Add the following content:
---
- name: Security Monitoring and Auditing
  hosts: all
  become: yes
  
  tasks:
    - name: Install audit daemon
      yum:
        name: audit
        state: present

    - name: Configure audit rules
      copy:
        content: |
          # Monitor authentication events
          -w /var/log/auth.log -p wa -k authentication
          -w /var/log/secure -p wa -k authentication
          
          # Monitor user and group modifications
          -w /etc/passwd -p wa -k user_modification
          -w /etc/group -p wa -k group_modification
          -w /etc/shadow -p wa -k password_modification
          
          # Monitor sudo usage
          -w /etc/sudoers -p wa -k sudo_modification
          -w /etc/sudoers.d/ -p wa -k sudo_modification
          
          # Monitor SSH configuration
          -w /etc/ssh/sshd_config -p wa -k ssh_config
          
          # Monitor system calls
          -a always,exit -F arch=b64 -S execve -k process_execution
          -a always,exit -F arch=b32 -S execve -k process_execution
          
          # Monitor file access
          -a always,exit -F arch=b64 -S open -S openat -F exit=-EACCES -k access_denied
          -a always,exit -F arch=b64 -S open -S openat -F exit=-EPERM -k access_denied
        dest: /etc/audit/rules.d/security.rules
        owner: root
        group: root
        mode: '0640'
      notify: restart auditd

    - name: Start and enable audit daemon
      systemd:
        name: auditd
        state: started
        enabled: yes

    - name: Configure fail2ban for SSH protection
      copy:
        content: |
          [DEFAULT]
          bantime = 3600
          findtime = 600
          maxretry = 3
          
          [sshd]
          enabled = true
          port = ssh
          logpath = /var/log/secure
          maxretry = 3
          bantime = 3600
        dest: /etc/fail2ban/jail.local
        owner: root
        group: root
        mode: '0644'
      notify: restart fail2ban

    - name: Start and enable fail2ban
      systemd:
        name: fail2ban
        state: started
        enabled: yes

    - name: Create security check script
      copy:
        content: |
          #!/bin/bash
          # Security monitoring script
          
          echo "=== Security Status Report ===" > /var/log/security-report.log
          echo "Date: $(date)" >> /var/log/security-report.log
          echo "" >> /var/log/security-report.log
          
          echo "Failed SSH attempts:" >> /var/log/security-report.log
          grep "Failed password" /var/log/secure | tail -10 >> /var/log/security-report.log
          echo "" >> /var/log/security-report.log
          
          echo "Current active users:" >> /var/log/security-report.log
          who >> /var/log/security-report.log
          echo "" >> /var/log/security-report.log
          
          echo "Sudo usage:" >> /var/log/security-report.log
          grep "sudo:" /var/log/secure | tail -5 >> /var/log/security-report.log
          echo "" >> /var/log/security-report.log
          
          echo "SELinux denials:" >> /var/log/security-report.log
          grep "denied" /var/log/audit/audit.log | tail -5 >> /var/log/security-report.log
        dest: /usr/local/bin/security-check.sh
        owner: root
        group: root
        mode: '0755'

    - name: Schedule security monitoring
      cron:
        name: "Security monitoring"
        minute: "0"
        hour: "*/6"
        job: "/usr/local/bin/security-check.sh"
        user: root

  handlers:
    - name: restart auditd
      systemd:
        name: auditd
        state: restarted

    - name: restart fail2ban
      systemd:
        name: fail2ban
        state: restarted
Run the security monitoring playbook:
ansible-playbook -i inventory.ini security-monitoring.yml
Verification and Testing
Subtask 4.1: Create Verification Playbook
Create a comprehensive verification playbook:
nano verify-security.yml
Add the following content:
---
- name: Verify Security Configuration
  hosts: all
  become: yes
  
  tasks:
    - name: Check SELinux status
      command: sestatus
      register: selinux_check
      changed_when: false

    - name: Verify firewall status
      command: firewall-cmd --state
      register: firewall_check
      changed_when: false

    - name: Check active firewall zones
      command: firewall-cmd --get-active-zones
      register: zones_check
      changed_when: false

    - name: Verify SSH configuration
      command: sshd -T
      register: ssh_check
      changed_when: false

    - name: Check audit daemon status
      command: systemctl is-active auditd
      register: audit_check
      changed_when: false

    - name: Verify fail2ban status
      command: systemctl is-active fail2ban
      register: fail2ban_check
      changed_when: false

    - name: Check user accounts
      command: getent passwd
      register: users_check
      changed_when: false

    - name: Display verification results
      debug:
        msg:
          - "SELinux Status: {{ selinux_check.stdout }}"
          - "Firewall Status: {{ firewall_check.stdout }}"
          - "Active Zones: {{ zones_check.stdout }}"
          - "Audit Status: {{ audit_check.stdout }}"
          - "Fail2ban Status: {{ fail2ban_check.stdout }}"
Run the verification playbook:
ansible-playbook -i inventory.ini verify-security.yml
Troubleshooting Common Issues
Issue 1: SELinux Preventing Service Startup
Problem: Services fail to start after enabling SELinux Solution:

# Check SELinux denials
sudo ausearch -m AVC -ts recent

# Generate and apply SELinux policy
sudo audit2allow -a -M mymodule
sudo semodule -i mymodule.pp
Issue 2: Firewall Blocking Required Services
Problem: Applications cannot connect after firewall configuration Solution:

# Check firewall logs
sudo journalctl -u firewalld

# Temporarily disable firewall for testing
sudo systemctl stop firewalld

# Add missing rules
sudo firewall-cmd --add-port=PORT/tcp --permanent
sudo firewall-cmd --reload
Issue 3: SSH Access Issues
Problem: Cannot connect via SSH after hardening Solution:

# Check SSH configuration syntax
sudo sshd -t

# Review SSH logs
sudo journalctl -u sshd

# Temporarily allow password authentication for recovery
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
Best Practices and Security Considerations
Security Best Practices
Principle of Least Privilege: Grant users only the minimum permissions necessary
Defense in Depth: Implement multiple layers of security controls
Regular Updates: Keep systems and security tools updated
Monitoring and Logging: Implement comprehensive logging and monitoring
Backup and Recovery: Maintain secure backups of configurations
Ansible Security Best Practices
Vault Usage: Use Ansible Vault for sensitive data
Idempotency: Ensure playbooks are idempotent
Testing: Test playbooks in development environments first
Version Control: Store playbooks in version control systems
Documentation: Document all security configurations and procedures
Conclusion
In this comprehensive lab, you have successfully:

Automated SELinux Configuration: Implemented consistent SELinux policies across multiple systems, ensuring proper security contexts and boolean settings for different service types
Configured Advanced Firewall Rules: Set up zone-based firewall configurations with service-specific rules, rate limiting, and custom zones for different network segments
Secured User Account Management: Automated the creation and management of user accounts with proper permissions, SSH key authentication, and password policies
Implemented Security Monitoring: Deployed audit logging, fail2ban protection, and automated security reporting across your infrastructure
Created Verification Procedures: Developed comprehensive testing and verification playbooks to ensure security configurations are properly applied
Why This Matters:

Security automation is critical in modern IT environments because:

Consistency: Ensures identical security configurations across all systems
Scalability: Allows security policies to be applied to hundreds or thousands of systems simultaneously
Compliance: Helps maintain regulatory compliance through documented, repeatable processes
Efficiency: Reduces manual errors and saves significant time in security management
Rapid Response: Enables quick deployment of security updates and patches
The skills you've developed in this lab are directly applicable to real-world scenarios where organizations need to maintain secure, compliant infrastructure at scale. These automation techniques are essential for roles such as Security Engineers, DevSecOps Engineers, and System Administrators working in enterprise environments.

Your automated security configurations now provide a solid foundation for maintaining robust security postures across diverse IT environments, making you well-prepared for advanced security automation challenges and RHCE certification requirements.
