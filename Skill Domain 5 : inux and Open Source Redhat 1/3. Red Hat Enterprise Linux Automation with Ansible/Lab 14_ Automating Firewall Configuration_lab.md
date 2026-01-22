Lab 14: Automating Firewall Configuration
Objectives
By the end of this lab, students will be able to:

• Configure firewall rules using the Ansible firewalld module • Manage firewall zones and services with Ansible automation • Create and apply firewall policies across multiple systems • Understand the relationship between firewalld zones, services, and rules • Implement security best practices through automated firewall management • Troubleshoot common firewall configuration issues using Ansible

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with Ansible fundamentals (playbooks, modules, inventory) • Knowledge of basic networking concepts (ports, protocols, services) • Understanding of firewall concepts and security principles • Completion of previous Ansible labs or equivalent experience

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex setups.

Your lab environment includes: • Control Node: CentOS/RHEL 8 system with Ansible pre-installed • Managed Nodes: Two target systems for firewall configuration • Network Access: All systems can communicate with each other • Sudo Access: Administrative privileges on all systems

Task 1: Configure Firewall Rules Using the firewalld Module
Subtask 1.1: Verify Lab Environment and Firewalld Status
First, let's check our environment and ensure firewalld is properly installed and running on our managed nodes.

Connect to your control node and verify Ansible installation:
ansible --version
Check connectivity to managed nodes:
ansible all -m ping
Verify firewalld status on managed nodes:
ansible all -m systemd -a "name=firewalld state=started enabled=yes" --become
Check current firewall status:
ansible all -m command -a "firewall-cmd --state" --become
Subtask 1.2: Create Basic Firewall Configuration Playbook
Now we'll create our first playbook to configure basic firewall rules.

Create a new directory for firewall playbooks:
mkdir ~/firewall-lab
cd ~/firewall-lab
Create the inventory file:
cat > inventory << EOF
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[all:vars]
ansible_user=student
ansible_become=yes
EOF
Create your first firewall playbook:
cat > basic-firewall.yml << 'EOF'
---
- name: Configure Basic Firewall Rules
  hosts: all
  become: yes
  tasks:
    - name: Ensure firewalld is installed
      package:
        name: firewalld
        state: present

    - name: Start and enable firewalld service
      systemd:
        name: firewalld
        state: started
        enabled: yes

    - name: Allow SSH service
      firewalld:
        service: ssh
        permanent: yes
        state: enabled
        immediate: yes

    - name: Allow HTTP service
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes

    - name: Allow HTTPS service
      firewalld:
        service: https
        permanent: yes
        state: enabled
        immediate: yes

    - name: Display current firewall rules
      command: firewall-cmd --list-all
      register: firewall_rules

    - name: Show firewall configuration
      debug:
        var: firewall_rules.stdout_lines
EOF
Run the basic firewall playbook:
ansible-playbook -i inventory basic-firewall.yml
Subtask 1.3: Configure Custom Port Rules
Let's extend our firewall configuration to include custom ports and more specific rules.

Create an advanced firewall playbook:
cat > advanced-firewall.yml << 'EOF'
---
- name: Configure Advanced Firewall Rules
  hosts: webservers
  become: yes
  vars:
    custom_ports:
      - port: 8080
        protocol: tcp
        description: "Custom web application"
      - port: 3306
        protocol: tcp
        description: "MySQL database"
      - port: 5432
        protocol: tcp
        description: "PostgreSQL database"

  tasks:
    - name: Open custom TCP ports
      firewalld:
        port: "{{ item.port }}/{{ item.protocol }}"
        permanent: yes
        state: enabled
        immediate: yes
      loop: "{{ custom_ports }}"

    - name: Block specific port (example: 23/tcp for telnet)
      firewalld:
        port: 23/tcp
        permanent: yes
        state: disabled
        immediate: yes

    - name: Allow specific source IP for SSH
      firewalld:
        rich_rule: 'rule family="ipv4" source address="192.168.1.0/24" service name="ssh" accept'
        permanent: yes
        state: enabled
        immediate: yes

    - name: Create port range rule
      firewalld:
        port: 60000-61000/tcp
        permanent: yes
        state: enabled
        immediate: yes

    - name: Verify firewall configuration
      command: firewall-cmd --list-all
      register: advanced_rules

    - name: Display advanced firewall rules
      debug:
        msg: "{{ advanced_rules.stdout_lines }}"
EOF
Execute the advanced firewall playbook:
ansible-playbook -i inventory advanced-firewall.yml
Subtask 1.4: Implement Rich Rules for Complex Scenarios
Rich rules provide more granular control over firewall policies. Let's implement some practical examples.

Create a rich rules playbook:
cat > rich-rules.yml << 'EOF'
---
- name: Configure Firewall Rich Rules
  hosts: all
  become: yes
  tasks:
    - name: Allow HTTP only from specific network
      firewalld:
        rich_rule: 'rule family="ipv4" source address="10.0.0.0/8" service name="http" accept'
        permanent: yes
        state: enabled
        immediate: yes

    - name: Block specific IP from accessing SSH
      firewalld:
        rich_rule: 'rule family="ipv4" source address="192.168.1.100" service name="ssh" drop'
        permanent: yes
        state: enabled
        immediate: yes

    - name: Rate limit SSH connections
      firewalld:
        rich_rule: 'rule service name="ssh" accept limit value="3/m"'
        permanent: yes
        state: enabled
        immediate: yes

    - name: Allow ICMP ping from internal network only
      firewalld:
        rich_rule: 'rule family="ipv4" source address="192.168.0.0/16" icmp-block-inversion="yes" accept'
        permanent: yes
        state: enabled
        immediate: yes

    - name: Log dropped packets on port 80
      firewalld:
        rich_rule: 'rule port port="80" protocol="tcp" log prefix="HTTP-DROP" level="info" drop'
        permanent: yes
        state: enabled
        immediate: yes

    - name: List all rich rules
      command: firewall-cmd --list-rich-rules
      register: rich_rules_output

    - name: Display configured rich rules
      debug:
        msg: "{{ rich_rules_output.stdout_lines }}"
EOF
Run the rich rules playbook:
ansible-playbook -i inventory rich-rules.yml
Task 2: Manage Zones and Services with firewalld in Ansible
Subtask 2.1: Understanding and Configuring Firewall Zones
Firewall zones are predefined sets of rules that define the trust level of network connections. Let's explore and configure different zones.

Create a zones management playbook:
cat > zones-management.yml << 'EOF'
---
- name: Manage Firewall Zones
  hosts: all
  become: yes
  tasks:
    - name: List all available zones
      command: firewall-cmd --get-zones
      register: available_zones

    - name: Display available zones
      debug:
        msg: "Available zones: {{ available_zones.stdout }}"

    - name: Get default zone
      command: firewall-cmd --get-default-zone
      register: default_zone

    - name: Display default zone
      debug:
        msg: "Default zone: {{ default_zone.stdout }}"

    - name: Create custom zone for DMZ servers
      firewalld:
        zone: dmz-custom
        permanent: yes
        state: present

    - name: Configure DMZ zone with specific services
      firewalld:
        zone: dmz-custom
        service: "{{ item }}"
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - http
        - https
        - ssh

    - name: Add interface to specific zone (example)
      firewalld:
        zone: public
        interface: eth0
        permanent: yes
        state: enabled
        immediate: yes
      ignore_errors: yes

    - name: Set trusted zone for internal network
      firewalld:
        zone: trusted
        source: 192.168.1.0/24
        permanent: yes
        state: enabled
        immediate: yes

    - name: List zones and their configurations
      command: firewall-cmd --list-all-zones
      register: all_zones

    - name: Display zones configuration (first 50 lines)
      debug:
        msg: "{{ all_zones.stdout_lines[:50] }}"
EOF
Execute the zones management playbook:
ansible-playbook -i inventory zones-management.yml
Subtask 2.2: Managing Services and Creating Custom Services
Let's learn how to manage predefined services and create custom service definitions.

Create a services management playbook:
cat > services-management.yml << 'EOF'
---
- name: Manage Firewall Services
  hosts: webservers
  become: yes
  tasks:
    - name: List all available services
      command: firewall-cmd --get-services
      register: available_services

    - name: Display first 20 available services
      debug:
        msg: "{{ available_services.stdout.split()[:20] }}"

    - name: Enable common web services
      firewalld:
        service: "{{ item }}"
        permanent: yes
        state: enabled
        immediate: yes
        zone: public
      loop:
        - http
        - https
        - ftp
        - dns

    - name: Create custom service definition directory
      file:
        path: /etc/firewalld/services
        state: directory
        mode: '0755'

    - name: Create custom application service
      copy:
        content: |
          <?xml version="1.0" encoding="utf-8"?>
          <service>
            <short>Custom App</short>
            <description>Custom web application running on port 8080</description>
            <port protocol="tcp" port="8080"/>
            <port protocol="tcp" port="8443"/>
          </service>
        dest: /etc/firewalld/services/custom-app.xml
        mode: '0644'

    - name: Reload firewalld to recognize new service
      command: firewall-cmd --reload

    - name: Enable custom service
      firewalld:
        service: custom-app
        permanent: yes
        state: enabled
        immediate: yes

    - name: Disable unnecessary services
      firewalld:
        service: "{{ item }}"
        permanent: yes
        state: disabled
        immediate: yes
      loop:
        - cockpit
        - dhcpv6-client
      ignore_errors: yes

    - name: Check enabled services in public zone
      command: firewall-cmd --zone=public --list-services
      register: enabled_services

    - name: Display enabled services
      debug:
        msg: "Enabled services: {{ enabled_services.stdout }}"
EOF
Run the services management playbook:
ansible-playbook -i inventory services-management.yml
Subtask 2.3: Implementing Zone-Based Security Policies
Now let's create a comprehensive security policy using different zones for different types of servers.

Create a comprehensive security policy playbook:
cat > security-policy.yml << 'EOF'
---
- name: Implement Comprehensive Security Policy
  hosts: all
  become: yes
  vars:
    web_servers: ['node1']
    db_servers: ['node2']

  tasks:
    - name: Configure web servers with public zone
      block:
        - name: Set public zone as default for web servers
          firewalld:
            zone: public
            permanent: yes
            state: enabled
            immediate: yes

        - name: Allow web services for web servers
          firewalld:
            zone: public
            service: "{{ item }}"
            permanent: yes
            state: enabled
            immediate: yes
          loop:
            - http
            - https
            - ssh

        - name: Allow custom web ports
          firewalld:
            zone: public
            port: "{{ item }}"
            permanent: yes
            state: enabled
            immediate: yes
          loop:
            - 8080/tcp
            - 8443/tcp

      when: inventory_hostname in web_servers

    - name: Configure database servers with internal zone
      block:
        - name: Create internal zone for database servers
          firewalld:
            zone: internal
            permanent: yes
            state: present

        - name: Allow SSH for management
          firewalld:
            zone: internal
            service: ssh
            permanent: yes
            state: enabled
            immediate: yes

        - name: Allow database ports only from web servers
          firewalld:
            zone: internal
            rich_rule: 'rule family="ipv4" source address="192.168.1.10" port port="3306" protocol="tcp" accept'
            permanent: yes
            state: enabled
            immediate: yes

        - name: Block all other database access
          firewalld:
            zone: internal
            rich_rule: 'rule port port="3306" protocol="tcp" drop'
            permanent: yes
            state: enabled
            immediate: yes

      when: inventory_hostname in db_servers

    - name: Apply common security rules to all servers
      block:
        - name: Block common attack ports
          firewalld:
            port: "{{ item }}"
            permanent: yes
            state: disabled
            immediate: yes
          loop:
            - 23/tcp    # Telnet
            - 135/tcp   # RPC
            - 139/tcp   # NetBIOS
            - 445/tcp   # SMB

        - name: Enable logging for dropped packets
          firewalld:
            rich_rule: 'rule drop log prefix="FIREWALL-DROP" level="info"'
            permanent: yes
            state: enabled
            immediate: yes

    - name: Verify final configuration
      command: firewall-cmd --list-all
      register: final_config

    - name: Display final firewall configuration
      debug:
        msg: "{{ final_config.stdout_lines }}"
EOF
Execute the comprehensive security policy:
ansible-playbook -i inventory security-policy.yml
Subtask 2.4: Testing and Validation
Let's create a playbook to test our firewall configurations and ensure they're working as expected.

Create a firewall testing playbook:
cat > firewall-testing.yml << 'EOF'
---
- name: Test Firewall Configuration
  hosts: all
  become: yes
  tasks:
    - name: Test SSH connectivity (should work)
      wait_for:
        host: "{{ inventory_hostname }}"
        port: 22
        timeout: 5
      delegate_to: localhost
      ignore_errors: yes
      register: ssh_test

    - name: Test HTTP connectivity (should work on web servers)
      wait_for:
        host: "{{ inventory_hostname }}"
        port: 80
        timeout: 5
      delegate_to: localhost
      ignore_errors: yes
      register: http_test

    - name: Test blocked port (should fail)
      wait_for:
        host: "{{ inventory_hostname }}"
        port: 23
        timeout: 5
      delegate_to: localhost
      ignore_errors: yes
      register: telnet_test

    - name: Generate firewall test report
      debug:
        msg:
          - "=== Firewall Test Results for {{ inventory_hostname }} ==="
          - "SSH (port 22): {{ 'PASS' if ssh_test.failed is not defined else 'FAIL' }}"
          - "HTTP (port 80): {{ 'PASS' if http_test.failed is not defined else 'BLOCKED' }}"
          - "Telnet (port 23): {{ 'BLOCKED' if telnet_test.failed is defined else 'FAIL - Should be blocked!' }}"

    - name: Save firewall configuration backup
      command: firewall-cmd --list-all
      register: firewall_backup

    - name: Create configuration backup file
      copy:
        content: "{{ firewall_backup.stdout }}"
        dest: "/tmp/firewall-backup-{{ inventory_hostname }}.txt"
        mode: '0644'

    - name: Display backup location
      debug:
        msg: "Firewall configuration backed up to /tmp/firewall-backup-{{ inventory_hostname }}.txt"
EOF
Run the firewall testing playbook:
ansible-playbook -i inventory firewall-testing.yml
Troubleshooting Common Issues
Issue 1: Firewalld Service Not Running
If firewalld is not running, use this troubleshooting playbook:

cat > troubleshoot-firewalld.yml << 'EOF'
---
- name: Troubleshoot Firewalld Issues
  hosts: all
  become: yes
  tasks:
    - name: Check if firewalld is installed
      package_facts:
        manager: auto

    - name: Install firewalld if missing
      package:
        name: firewalld
        state: present
      when: "'firewalld' not in ansible_facts.packages"

    - name: Stop conflicting iptables service
      systemd:
        name: iptables
        state: stopped
        enabled: no
      ignore_errors: yes

    - name: Start and enable firewalld
      systemd:
        name: firewalld
        state: started
        enabled: yes

    - name: Verify firewalld status
      command: systemctl status firewalld
      register: firewalld_status

    - name: Display firewalld status
      debug:
        msg: "{{ firewalld_status.stdout_lines }}"
EOF
Issue 2: Rules Not Persisting
To ensure rules persist across reboots:

# Always use permanent=yes and immediate=yes together
firewalld:
  service: http
  permanent: yes    # Saves to permanent configuration
  immediate: yes    # Applies immediately to running configuration
  state: enabled
Issue 3: Zone Configuration Problems
Check zone assignments and fix common issues:

# List all zones and their configurations
ansible all -m command -a "firewall-cmd --list-all-zones" --become

# Check which zone an interface belongs to
ansible all -m command -a "firewall-cmd --get-zone-of-interface=eth0" --become
Best Practices Summary
Always use both permanent and immediate flags when configuring firewall rules
Test connectivity after applying firewall changes
Use zones appropriately - public for internet-facing, internal for private networks
Implement least privilege - only open necessary ports and services
Use rich rules for complex scenarios requiring granular control
Document your firewall policies and maintain configuration backups
Regular auditing - periodically review and update firewall rules
Conclusion
In this lab, you have successfully learned how to automate firewall configuration using Ansible and the firewalld module. You accomplished the following key objectives:

What You Learned: • Automated firewall rule management using Ansible playbooks instead of manual configuration • Zone-based security implementation to create different security policies for different server types • Service and port management including custom service definitions and rich rules • Security policy enforcement across multiple systems simultaneously • Testing and validation of firewall configurations to ensure they work as expected

Why This Matters: Automating firewall configuration is crucial in modern IT environments because it: • Ensures consistency across all systems in your infrastructure • Reduces human error that can lead to security vulnerabilities • Saves time when managing large numbers of servers • Provides audit trails and documentation of security policies • Enables rapid deployment of security updates and policy changes

Real-World Applications: The skills you've developed in this lab directly apply to: • Managing security policies in cloud environments • Implementing compliance requirements across enterprise networks • Automating security responses to threats • Maintaining consistent security posture in DevOps pipelines

You now have the foundation to implement enterprise-grade automated firewall management using open-source tools, making you more valuable in roles involving system administration, security engineering, and DevOps practices.
