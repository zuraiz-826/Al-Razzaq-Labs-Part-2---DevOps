Lab 9: Configuring Firewalls Using Ansible
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of firewall automation using Ansible
Write Ansible playbooks to configure firewalld services
Implement dynamic firewall zone and rule management using variables
Use Ansible handlers to manage firewall service reloads efficiently
Apply best practices for firewall configuration management in enterprise environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Knowledge of Ansible fundamentals (playbooks, tasks, variables)
Understanding of firewall concepts and network security basics
Experience with SSH and remote system administration
Required Knowledge Areas
Ansible Core Concepts: Playbooks, tasks, handlers, variables, and inventory management
Linux System Administration: Service management, file permissions, and network configuration
Firewall Fundamentals: Understanding of ports, protocols, and network zones
YAML Formatting: Proper indentation and syntax requirements
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machines or install additional software.

What's Included in Your Lab Environment
Control Node: CentOS/RHEL 8+ with Ansible pre-installed
Managed Nodes: Two target systems for firewall configuration
Network Access: Full connectivity between all systems
Root Access: Administrative privileges on all machines
Task 1: Write a Playbook to Configure Firewalld for HTTP and HTTPS Services
Subtask 1.1: Create the Basic Project Structure
First, let's establish a proper directory structure for our Ansible project.

# Create the main project directory
mkdir -p ~/firewall-ansible-lab
cd ~/firewall-ansible-lab

# Create subdirectories for organization
mkdir -p {playbooks,inventory,group_vars,host_vars}

# Create the main inventory file
touch inventory/hosts.yml
Subtask 1.2: Configure the Inventory File
Create your inventory file to define the target systems:

# Edit the inventory file
nano inventory/hosts.yml
Add the following content:

all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.10
          ansible_user: root
        web2:
          ansible_host: 192.168.1.11
          ansible_user: root
    firewalls:
      hosts:
        firewall1:
          ansible_host: 192.168.1.20
          ansible_user: root
Note: Replace the IP addresses with the actual IPs provided in your lab environment.

Subtask 1.3: Create the Basic HTTP/HTTPS Firewall Playbook
Create your first playbook for basic firewall configuration:

# Create the main playbook
nano playbooks/configure-basic-firewall.yml
Add the following content:

---
- name: Configure Firewalld for Web Services
  hosts: webservers
  become: yes
  vars:
    web_services:
      - http
      - https
    firewall_zone: public

  tasks:
    - name: Ensure firewalld is installed
      package:
        name: firewalld
        state: present

    - name: Ensure firewalld service is running and enabled
      systemd:
        name: firewalld
        state: started
        enabled: yes

    - name: Allow web services through firewall
      firewalld:
        service: "{{ item }}"
        zone: "{{ firewall_zone }}"
        permanent: yes
        state: enabled
        immediate: yes
      loop: "{{ web_services }}"
      notify: reload firewalld

    - name: Verify firewall rules are active
      command: firewall-cmd --list-services --zone={{ firewall_zone }}
      register: active_services
      changed_when: false

    - name: Display active services
      debug:
        msg: "Active services in {{ firewall_zone }} zone: {{ active_services.stdout }}"

  handlers:
    - name: reload firewalld
      systemd:
        name: firewalld
        state: reloaded
Subtask 1.4: Test the Basic Playbook
Execute the playbook to configure basic firewall rules:

# Run the playbook
ansible-playbook -i inventory/hosts.yml playbooks/configure-basic-firewall.yml

# Verify the configuration on target systems
ansible webservers -i inventory/hosts.yml -m command -a "firewall-cmd --list-all"
Task 2: Define Firewalld Zones and Rules Dynamically Using Variables
Subtask 2.1: Create Advanced Variable Structure
Create a comprehensive variable file for dynamic configuration:

# Create group variables for webservers
nano group_vars/webservers.yml
Add the following advanced configuration:

---
# Firewall Zone Configuration
firewall_zones:
  - name: public
    target: default
    services:
      - http
      - https
      - ssh
    ports:
      - "8080/tcp"
      - "8443/tcp"
    rich_rules:
      - 'rule family="ipv4" source address="10.0.0.0/8" service name="ssh" accept'

  - name: internal
    target: default
    services:
      - ssh
      - dhcpv6-client
    ports:
      - "3306/tcp"
      - "5432/tcp"
    sources:
      - "192.168.1.0/24"
      - "10.0.0.0/8"

  - name: dmz
    target: default
    services:
      - http
      - https
    ports:
      - "80/tcp"
      - "443/tcp"

# Default zone configuration
default_zone: public

# Custom port definitions
custom_ports:
  web_alt: "8080/tcp"
  web_ssl_alt: "8443/tcp"
  mysql: "3306/tcp"
  postgresql: "5432/tcp"

# Trusted IP ranges
trusted_networks:
  - "192.168.1.0/24"
  - "10.0.0.0/8"
  - "172.16.0.0/12"
Subtask 2.2: Create the Advanced Dynamic Firewall Playbook
Create a more sophisticated playbook that uses dynamic variables:

# Create the advanced playbook
nano playbooks/configure-dynamic-firewall.yml
Add the following content:

---
- name: Configure Dynamic Firewalld Zones and Rules
  hosts: webservers
  become: yes
  vars:
    backup_config: true
    config_timestamp: "{{ ansible_date_time.epoch }}"

  tasks:
    - name: Ensure firewalld is installed and updated
      package:
        name: firewalld
        state: latest

    - name: Ensure firewalld service is running and enabled
      systemd:
        name: firewalld
        state: started
        enabled: yes

    - name: Backup current firewall configuration
      command: firewall-cmd --list-all-zones
      register: firewall_backup
      when: backup_config | bool

    - name: Save firewall backup to file
      copy:
        content: "{{ firewall_backup.stdout }}"
        dest: "/tmp/firewall-backup-{{ config_timestamp }}.txt"
      when: backup_config | bool

    - name: Configure firewall zones
      firewalld:
        zone: "{{ item.name }}"
        state: present
        permanent: yes
      loop: "{{ firewall_zones }}"
      notify: reload firewalld

    - name: Set zone targets
      command: >
        firewall-cmd --permanent --zone={{ item.name }} 
        --set-target={{ item.target | default('default') }}
      loop: "{{ firewall_zones }}"
      when: item.target is defined
      notify: reload firewalld

    - name: Configure services for each zone
      firewalld:
        zone: "{{ item.0.name }}"
        service: "{{ item.1 }}"
        permanent: yes
        state: enabled
        immediate: yes
      with_subelements:
        - "{{ firewall_zones }}"
        - services
        - flags:
          skip_missing: true
      notify: reload firewalld

    - name: Configure ports for each zone
      firewalld:
        zone: "{{ item.0.name }}"
        port: "{{ item.1 }}"
        permanent: yes
        state: enabled
        immediate: yes
      with_subelements:
        - "{{ firewall_zones }}"
        - ports
        - flags:
          skip_missing: true
      notify: reload firewalld

    - name: Configure source networks for zones
      firewalld:
        zone: "{{ item.0.name }}"
        source: "{{ item.1 }}"
        permanent: yes
        state: enabled
        immediate: yes
      with_subelements:
        - "{{ firewall_zones }}"
        - sources
        - flags:
          skip_missing: true
      notify: reload firewalld

    - name: Configure rich rules for zones
      firewalld:
        zone: "{{ item.0.name }}"
        rich_rule: "{{ item.1 }}"
        permanent: yes
        state: enabled
        immediate: yes
      with_subelements:
        - "{{ firewall_zones }}"
        - rich_rules
        - flags:
          skip_missing: true
      notify: reload firewalld

    - name: Set default zone
      command: firewall-cmd --set-default-zone={{ default_zone }}
      notify: reload firewalld

    - name: Verify zone configurations
      command: firewall-cmd --list-all-zones
      register: zone_status
      changed_when: false

    - name: Display zone configurations
      debug:
        var: zone_status.stdout_lines

  handlers:
    - name: reload firewalld
      systemd:
        name: firewalld
        state: reloaded
      listen: "reload firewalld"
Subtask 2.3: Create Host-Specific Variables
Create host-specific configurations for different server roles:

# Create host-specific variables for web1
nano host_vars/web1.yml
Add the following content:

---
# Web1 specific configuration - Public facing web server
firewall_zones:
  - name: public
    target: default
    services:
      - http
      - https
      - ssh
    ports:
      - "80/tcp"
      - "443/tcp"
      - "8080/tcp"
    rich_rules:
      - 'rule family="ipv4" source address="0.0.0.0/0" service name="http" accept'
      - 'rule family="ipv4" source address="0.0.0.0/0" service name="https" accept'

default_zone: public
server_role: "public_web"
# Create host-specific variables for web2
nano host_vars/web2.yml
Add the following content:

---
# Web2 specific configuration - Internal application server
firewall_zones:
  - name: internal
    target: default
    services:
      - ssh
      - http
    ports:
      - "8080/tcp"
      - "3306/tcp"
    sources:
      - "192.168.1.0/24"
      - "10.0.0.0/8"

  - name: public
    target: DROP
    services:
      - ssh

default_zone: internal
server_role: "internal_app"
Subtask 2.4: Execute the Dynamic Configuration
Run the advanced playbook with dynamic variables:

# Execute the dynamic firewall configuration
ansible-playbook -i inventory/hosts.yml playbooks/configure-dynamic-firewall.yml -v

# Verify configurations on specific hosts
ansible web1 -i inventory/hosts.yml -m command -a "firewall-cmd --get-default-zone"
ansible web2 -i inventory/hosts.yml -m command -a "firewall-cmd --list-all-zones"
Task 3: Use Handlers to Reload the Firewall Service After Updates
Subtask 3.1: Create Advanced Handler Configuration
Create a comprehensive playbook that demonstrates advanced handler usage:

# Create the handler-focused playbook
nano playbooks/firewall-with-handlers.yml
Add the following content:

---
- name: Advanced Firewall Configuration with Handlers
  hosts: webservers
  become: yes
  vars:
    firewall_config_changed: false
    notification_email: "admin@company.com"
    log_changes: true

  tasks:
    - name: Check if firewalld is installed
      package_facts:
        manager: auto

    - name: Install firewalld if not present
      package:
        name: firewalld
        state: present
      when: "'firewalld' not in ansible_facts.packages"
      notify:
        - start firewalld
        - enable firewalld
        - log installation

    - name: Ensure firewalld is running
      systemd:
        name: firewalld
        state: started
        enabled: yes
      register: firewalld_service_status

    - name: Get current firewall configuration
      command: firewall-cmd --list-all
      register: current_config
      changed_when: false

    - name: Configure firewall services
      firewalld:
        service: "{{ item }}"
        zone: public
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - http
        - https
        - ssh
      register: service_config_result
      notify:
        - reload firewalld
        - verify firewall config
        - log configuration changes

    - name: Configure custom ports
      firewalld:
        port: "{{ item }}"
        zone: public
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - "8080/tcp"
        - "8443/tcp"
        - "9000/tcp"
      register: port_config_result
      notify:
        - reload firewalld
        - verify firewall config
        - log configuration changes

    - name: Add rich rules for enhanced security
      firewalld:
        rich_rule: "{{ item }}"
        zone: public
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - 'rule family="ipv4" source address="192.168.1.0/24" service name="ssh" accept'
        - 'rule family="ipv4" source address="10.0.0.0/8" port port="8080" protocol="tcp" accept'
      register: rich_rule_result
      notify:
        - reload firewalld
        - verify firewall config
        - log configuration changes
        - send notification

    - name: Configure firewall for database access (conditional)
      firewalld:
        port: "3306/tcp"
        zone: internal
        permanent: yes
        state: enabled
        immediate: yes
      when: "'database' in group_names"
      notify:
        - reload firewalld
        - verify firewall config
        - log database config

  handlers:
    - name: start firewalld
      systemd:
        name: firewalld
        state: started
      listen: "start firewalld"

    - name: enable firewalld
      systemd:
        name: firewalld
        enabled: yes
      listen: "enable firewalld"

    - name: reload firewalld
      systemd:
        name: firewalld
        state: reloaded
      listen: "reload firewalld"

    - name: verify firewall config
      command: firewall-cmd --list-all
      register: verification_result
      changed_when: false
      listen: "verify firewall config"

    - name: log installation
      lineinfile:
        path: /var/log/firewall-changes.log
        line: "{{ ansible_date_time.iso8601 }} - Firewalld installed on {{ inventory_hostname }}"
        create: yes
      listen: "log installation"

    - name: log configuration changes
      lineinfile:
        path: /var/log/firewall-changes.log
        line: "{{ ansible_date_time.iso8601 }} - Firewall configuration updated on {{ inventory_hostname }}"
        create: yes
      when: log_changes | bool
      listen: "log configuration changes"

    - name: log database config
      lineinfile:
        path: /var/log/firewall-changes.log
        line: "{{ ansible_date_time.iso8601 }} - Database firewall rules applied on {{ inventory_hostname }}"
        create: yes
      listen: "log database config"

    - name: send notification
      mail:
        to: "{{ notification_email }}"
        subject: "Firewall Configuration Updated"
        body: "Firewall rules have been updated on {{ inventory_hostname }} at {{ ansible_date_time.iso8601 }}"
      delegate_to: localhost
      when: notification_email is defined
      listen: "send notification"
      ignore_errors: yes

    - name: display verification results
      debug:
        var: verification_result.stdout_lines
      when: verification_result is defined
      listen: "verify firewall config"
Subtask 3.2: Create a Rollback Playbook with Handlers
Create a rollback mechanism using handlers:

# Create rollback playbook
nano playbooks/firewall-rollback.yml
Add the following content:

---
- name: Firewall Configuration Rollback with Handlers
  hosts: webservers
  become: yes
  vars:
    rollback_timestamp: "{{ ansible_date_time.epoch }}"
    backup_location: "/tmp/firewall-backups"

  tasks:
    - name: Create backup directory
      file:
        path: "{{ backup_location }}"
        state: directory
        mode: '0755'

    - name: Backup current configuration
      shell: |
        firewall-cmd --list-all-zones > {{ backup_location }}/zones-{{ rollback_timestamp }}.backup
        firewall-cmd --get-default-zone > {{ backup_location }}/default-zone-{{ rollback_timestamp }}.backup
      notify: log backup creation

    - name: Reset firewall to default state
      command: firewall-cmd --complete-reload
      notify:
        - verify reset
        - log rollback action

    - name: Remove custom zones (if any)
      firewalld:
        zone: "{{ item }}"
        state: absent
        permanent: yes
      loop:
        - custom-web
        - custom-db
        - custom-app
      ignore_errors: yes
      notify: reload firewalld after cleanup

    - name: Restore basic services only
      firewalld:
        service: "{{ item }}"
        zone: public
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - ssh
        - dhcpv6-client
      notify:
        - reload firewalld after cleanup
        - verify basic config

  handlers:
    - name: log backup creation
      lineinfile:
        path: /var/log/firewall-rollback.log
        line: "{{ ansible_date_time.iso8601 }} - Backup created before rollback on {{ inventory_hostname }}"
        create: yes

    - name: verify reset
      command: firewall-cmd --list-all
      register: reset_verification
      changed_when: false

    - name: log rollback action
      lineinfile:
        path: /var/log/firewall-rollback.log
        line: "{{ ansible_date_time.iso8601 }} - Firewall rollback completed on {{ inventory_hostname }}"
        create: yes

    - name: reload firewalld after cleanup
      systemd:
        name: firewalld
        state: reloaded

    - name: verify basic config
      command: firewall-cmd --list-services
      register: basic_config_check
      changed_when: false

    - name: display rollback results
      debug:
        msg: "Rollback completed. Active services: {{ basic_config_check.stdout }}"
      when: basic_config_check is defined
Subtask 3.3: Test Handler Functionality
Execute the playbooks to test handler functionality:

# Run the advanced handler playbook
ansible-playbook -i inventory/hosts.yml playbooks/firewall-with-handlers.yml -v

# Check the logs created by handlers
ansible webservers -i inventory/hosts.yml -m command -a "cat /var/log/firewall-changes.log"

# Test the rollback functionality
ansible-playbook -i inventory/hosts.yml playbooks/firewall-rollback.yml

# Verify rollback logs
ansible webservers -i inventory/hosts.yml -m command -a "cat /var/log/firewall-rollback.log"
Subtask 3.4: Create a Comprehensive Testing and Validation Playbook
Create a final playbook that tests all configurations:

# Create validation playbook
nano playbooks/validate-firewall-config.yml
Add the following content:

---
- name: Validate Firewall Configuration
  hosts: webservers
  become: yes
  vars:
    validation_tests:
      - name: "Check firewalld service status"
        command: "systemctl is-active firewalld"
        expected: "active"
      - name: "Check default zone"
        command: "firewall-cmd --get-default-zone"
        expected: "public"
      - name: "List active services"
        command: "firewall-cmd --list-services"
        expected_contains: ["http", "https", "ssh"]

  tasks:
    - name: Run validation tests
      command: "{{ item.command }}"
      register: test_results
      loop: "{{ validation_tests }}"
      changed_when: false
      failed_when: false

    - name: Analyze test results
      set_fact:
        validation_summary: "{{ validation_summary | default([]) + [{'test': item.item.name, 'result': item.stdout, 'status': 'PASS' if item.rc == 0 else 'FAIL'}] }}"
      loop: "{{ test_results.results }}"

    - name: Display validation summary
      debug:
        var: validation_summary

    - name: Generate validation report
      template:
        src: validation_report.j2
        dest: "/tmp/firewall-validation-{{ ansible_date_time.date }}.html"
      notify: display report location

  handlers:
    - name: display report location
      debug:
        msg: "Validation report generated at /tmp/firewall-validation-{{ ansible_date_time.date }}.html"
Troubleshooting Common Issues
Issue 1: Firewalld Service Not Starting
Symptoms: Service fails to start or enable Solution:

# Check service status
systemctl status firewalld

# Check for conflicting services
systemctl status iptables
systemctl stop iptables
systemctl disable iptables

# Restart firewalld
systemctl restart firewalld
Issue 2: Rules Not Persisting After Reboot
Symptoms: Firewall rules disappear after system restart Solution:

# Ensure permanent flag is used in playbooks
- name: Configure persistent rules
  firewalld:
    service: http
    zone: public
    permanent: yes  # This is crucial
    state: enabled
    immediate: yes  # Apply immediately without reload
Issue 3: Handler Not Triggering
Symptoms: Firewall service not reloading after configuration changes Solution:

# Ensure proper handler notification
tasks:
  - name: Configure firewall rule
    firewalld:
      service: http
      zone: public
      permanent: yes
      state: enabled
    notify: reload firewalld  # Must match handler name exactly

handlers:
  - name: reload firewalld  # Exact match required
    systemd:
      name: firewalld
      state: reloaded
Issue 4: Zone Configuration Conflicts
Symptoms: Rules not applying to correct zones Solution:

# Check current zone assignments
firewall-cmd --get-active-zones

# Verify interface assignments
firewall-cmd --list-all-zones

# Reset if necessary
firewall-cmd --complete-reload
Validation and Testing
Final Validation Commands
Execute these commands to verify your lab completion:

# Test 1: Verify firewalld is active on all hosts
ansible webservers -i inventory/hosts.yml -m command -a "systemctl is-active firewalld"

# Test 2: Check HTTP/HTTPS services are enabled
ansible webservers -i inventory/hosts.yml -m command -a "firewall-cmd --list-services --zone=public"

# Test 3: Verify custom ports are configured
ansible webservers -i inventory/hosts.yml -m command -a "firewall-cmd --list-ports --zone=public"

# Test 4: Test handler functionality by running a configuration change
ansible-playbook -i inventory/hosts.yml playbooks/firewall-with-handlers.yml --check

# Test 5: Verify logs were created by handlers
ansible webservers -i inventory/hosts.yml -m command -a "ls -la /var/log/firewall-*.log"
Conclusion
Congratulations! You have successfully completed Lab 9: Configuring Firewalls Using Ansible. Throughout this lab, you have accomplished several critical objectives:

What You Accomplished
Automated Firewall Configuration: You created Ansible playbooks that automatically configure firewalld to allow HTTP and HTTPS services, eliminating manual configuration errors and ensuring consistency across multiple systems.

Dynamic Rule Management: You implemented sophisticated variable-driven firewall configurations that can adapt to different server roles and environments, making your infrastructure more flexible and maintainable.

Handler Implementation: You mastered the use of Ansible handlers to efficiently manage firewall service reloads, ensuring that configuration changes are applied properly without unnecessary service interruptions.

Advanced Automation Techniques: You learned to use complex data structures, loops, and conditional logic to create robust firewall management solutions that can scale across enterprise environments.

Why This Matters
Security Automation: In today's threat landscape, manual firewall configuration is both time-consuming and error-prone. The automation skills you've developed ensure consistent security policies across your infrastructure.

Operational Efficiency: By automating firewall management, you've reduced the time required for security configuration from hours to minutes, while simultaneously reducing human error.

Compliance and Auditing: Your automated approach creates a clear audit trail of all firewall changes, which is essential for compliance with security standards and regulations.

Scalability: The dynamic configuration techniques you've learned allow you to manage firewall rules for hundreds or thousands of servers with the same effort required for a single system.

Real-World Applications
The skills you've developed in this lab directly apply to:

Enterprise Security Management: Implementing consistent security policies across large server fleets
DevOps Integration: Incorporating security configuration into CI/CD pipelines
Disaster Recovery: Rapidly restoring security configurations during system recovery
Compliance Automation: Ensuring security configurations meet regulatory requirements
Next Steps
To further develop your skills, consider:

Exploring integration with configuration management databases (CMDB)
Learning about firewall rule optimization and performance tuning
Investigating integration with security information and event management (SIEM) systems
Studying advanced Ansible features like custom modules and plugins
This lab has provided you with production-ready skills that are highly valued in the cybersecurity and DevOps industries, particularly for roles requiring Red Hat Certified Engineer (RHCE) expertise.
