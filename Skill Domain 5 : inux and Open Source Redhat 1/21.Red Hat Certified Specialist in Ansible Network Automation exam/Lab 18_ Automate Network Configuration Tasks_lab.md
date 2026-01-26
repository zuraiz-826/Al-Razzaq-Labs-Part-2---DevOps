Lab 18: Automate Network Configuration Tasks
Objectives
By the end of this lab, students will be able to:

• Configure network interfaces using Ansible network modules and ansible_network_os • Set up routing tables and VLANs through Ansible automation • Create and execute Ansible playbooks to manage network devices • Understand the fundamentals of network automation using open-source tools • Apply network automation concepts relevant to the Red Hat Certified Specialist in Ansible Network Automation exam

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Fundamental knowledge of networking concepts (IP addressing, VLANs, routing) • Basic familiarity with YAML syntax • Understanding of SSH connectivity and key-based authentication • Knowledge of basic Ansible concepts (playbooks, inventory, modules)

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or install software - everything is ready to use.

Your lab environment includes: • Ansible control node (pre-installed with Ansible 2.15+) • Simulated network devices using containerized network operating systems • Pre-configured SSH keys and network connectivity • Sample configuration files and templates

Task 1: Configure Network Interfaces Using ansible_network_os
Subtask 1.1: Verify Lab Environment and Ansible Installation
First, let's verify that our lab environment is properly set up and Ansible is installed with network modules.

Connect to your control node and verify Ansible installation:
ansible --version
Check available network modules:
ansible-doc -l | grep -i network | head -10
Verify the lab inventory file:
cat /home/student/network-lab/inventory/hosts.yml
Expected output should show network devices configured similar to:

all:
  children:
    network_devices:
      hosts:
        switch01:
          ansible_host: 192.168.100.10
          ansible_network_os: vyos
          ansible_user: vyos
          ansible_ssh_pass: vyos
        router01:
          ansible_host: 192.168.100.20
          ansible_network_os: vyos
          ansible_user: vyos
          ansible_ssh_pass: vyos
Subtask 1.2: Create Basic Network Interface Configuration Playbook
Navigate to the lab directory:
cd /home/student/network-lab
Create a playbook for interface configuration:
nano playbooks/configure-interfaces.yml
Add the following content to configure network interfaces:
---
- name: Configure Network Interfaces
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  
  vars:
    ansible_command_timeout: 60
    
  tasks:
    - name: Configure interface eth1 on switch
      vyos.vyos.vyos_interfaces:
        config:
          - name: eth1
            description: "LAN Interface configured by Ansible"
            enabled: true
        state: merged
      when: inventory_hostname == 'switch01'
      
    - name: Configure interface eth1 on router
      vyos.vyos.vyos_l3_interfaces:
        config:
          - name: eth1
            ipv4:
              - address: 10.1.1.1/24
        state: merged
      when: inventory_hostname == 'router01'
      
    - name: Save configuration
      vyos.vyos.vyos_config:
        save: yes
Execute the playbook:
ansible-playbook -i inventory/hosts.yml playbooks/configure-interfaces.yml -v
Subtask 1.3: Verify Interface Configuration
Create a verification playbook:
nano playbooks/verify-interfaces.yml
Add verification tasks:
---
- name: Verify Interface Configuration
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  
  tasks:
    - name: Gather interface facts
      vyos.vyos.vyos_facts:
        gather_subset:
          - interfaces
      register: device_facts
      
    - name: Display interface information
      debug:
        msg: "Interface {{ item.key }}: {{ item.value.description | default('No description') }}"
      loop: "{{ device_facts.ansible_facts.ansible_net_interfaces | dict2items }}"
      when: item.key == 'eth1'
Run the verification playbook:
ansible-playbook -i inventory/hosts.yml playbooks/verify-interfaces.yml
Task 2: Set Up Routing and VLANs via Ansible
Subtask 2.1: Configure VLANs on Network Devices
Create a VLAN configuration playbook:
nano playbooks/configure-vlans.yml
Add VLAN configuration tasks:
---
- name: Configure VLANs
  hosts: switch01
  gather_facts: no
  connection: network_cli
  
  vars:
    vlans:
      - vlan_id: 10
        name: "SALES"
        description: "Sales Department VLAN"
      - vlan_id: 20
        name: "IT"
        description: "IT Department VLAN"
      - vlan_id: 30
        name: "GUEST"
        description: "Guest Network VLAN"
        
  tasks:
    - name: Configure VLANs
      vyos.vyos.vyos_config:
        lines:
          - "set interfaces ethernet eth2 vif {{ item.vlan_id }} description '{{ item.description }}'"
          - "set interfaces ethernet eth2 vif {{ item.vlan_id }} address 192.168.{{ item.vlan_id }}.1/24"
        save: yes
      loop: "{{ vlans }}"
      
    - name: Verify VLAN configuration
      vyos.vyos.vyos_command:
        commands:
          - show interfaces ethernet eth2
      register: vlan_output
      
    - name: Display VLAN configuration
      debug:
        var: vlan_output.stdout_lines
Execute the VLAN configuration playbook:
ansible-playbook -i inventory/hosts.yml playbooks/configure-vlans.yml
Subtask 2.2: Configure Static Routing
Create a routing configuration playbook:
nano playbooks/configure-routing.yml
Add routing configuration:
---
- name: Configure Static Routes
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  
  vars:
    routes:
      router01:
        - destination: "192.168.10.0/24"
          next_hop: "10.1.1.2"
          description: "Route to Sales VLAN"
        - destination: "192.168.20.0/24"
          next_hop: "10.1.1.2"
          description: "Route to IT VLAN"
      switch01:
        - destination: "0.0.0.0/0"
          next_hop: "10.1.1.1"
          description: "Default route to router"
          
  tasks:
    - name: Configure static routes
      vyos.vyos.vyos_static_routes:
        config:
          - address_families:
              - afi: ipv4
                routes:
                  - dest: "{{ item.destination }}"
                    next_hops:
                      - forward_router_address: "{{ item.next_hop }}"
                        description: "{{ item.description }}"
        state: merged
      loop: "{{ routes[inventory_hostname] | default([]) }}"
      
    - name: Save routing configuration
      vyos.vyos.vyos_config:
        save: yes
        
    - name: Verify routing table
      vyos.vyos.vyos_command:
        commands:
          - show ip route
      register: routing_output
      
    - name: Display routing table
      debug:
        var: routing_output.stdout_lines
Run the routing configuration playbook:
ansible-playbook -i inventory/hosts.yml playbooks/configure-routing.yml
Subtask 2.3: Configure Dynamic Routing with OSPF
Create an OSPF configuration playbook:
nano playbooks/configure-ospf.yml
Add OSPF configuration:
---
- name: Configure OSPF Dynamic Routing
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  
  vars:
    ospf_config:
      router01:
        router_id: "1.1.1.1"
        networks:
          - network: "10.1.1.0/24"
            area: "0.0.0.0"
          - network: "192.168.10.0/24"
            area: "0.0.0.0"
      switch01:
        router_id: "2.2.2.2"
        networks:
          - network: "10.1.1.0/24"
            area: "0.0.0.0"
          - network: "192.168.20.0/24"
            area: "0.0.0.0"
            
  tasks:
    - name: Configure OSPF
      vyos.vyos.vyos_config:
        lines:
          - "set protocols ospf router-id {{ ospf_config[inventory_hostname].router_id }}"
        save: yes
      when: inventory_hostname in ospf_config
      
    - name: Configure OSPF networks
      vyos.vyos.vyos_config:
        lines:
          - "set protocols ospf area {{ item.area }} network {{ item.network }}"
        save: yes
      loop: "{{ ospf_config[inventory_hostname].networks | default([]) }}"
      when: inventory_hostname in ospf_config
      
    - name: Verify OSPF configuration
      vyos.vyos.vyos_command:
        commands:
          - show ip ospf neighbor
          - show ip ospf database
      register: ospf_output
      
    - name: Display OSPF information
      debug:
        var: ospf_output.stdout_lines
Execute the OSPF configuration:
ansible-playbook -i inventory/hosts.yml playbooks/configure-ospf.yml
Task 3: Manage Network Devices with Playbooks
Subtask 3.1: Create a Comprehensive Network Management Playbook
Create a master network management playbook:
nano playbooks/network-management.yml
Add comprehensive network management tasks:
---
- name: Comprehensive Network Device Management
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  
  vars:
    backup_dir: "/home/student/network-lab/backups"
    config_timestamp: "{{ ansible_date_time.epoch }}"
    
  tasks:
    - name: Create backup directory
      file:
        path: "{{ backup_dir }}"
        state: directory
      delegate_to: localhost
      run_once: true
      
    - name: Backup current configuration
      vyos.vyos.vyos_config:
        backup: yes
        backup_options:
          filename: "{{ inventory_hostname }}-{{ config_timestamp }}.cfg"
          dir_path: "{{ backup_dir }}"
      register: backup_result
      
    - name: Display backup information
      debug:
        msg: "Configuration backed up to: {{ backup_result.backup_path }}"
        
    - name: Gather device facts
      vyos.vyos.vyos_facts:
        gather_subset:
          - all
      register: device_facts
      
    - name: Generate device inventory report
      template:
        src: device_report.j2
        dest: "{{ backup_dir }}/{{ inventory_hostname }}-report.txt"
      delegate_to: localhost
      vars:
        facts: "{{ device_facts.ansible_facts }}"
        
    - name: Configure NTP servers
      vyos.vyos.vyos_config:
        lines:
          - "set system ntp server 0.pool.ntp.org"
          - "set system ntp server 1.pool.ntp.org"
        save: yes
        
    - name: Configure DNS servers
      vyos.vyos.vyos_config:
        lines:
          - "set system name-server 8.8.8.8"
          - "set system name-server 8.8.4.4"
        save: yes
        
    - name: Configure SNMP community
      vyos.vyos.vyos_config:
        lines:
          - "set service snmp community public authorization ro"
          - "set service snmp community public network 192.168.0.0/16"
        save: yes
        
    - name: Verify system services
      vyos.vyos.vyos_command:
        commands:
          - show system ntp
          - show dns forwarding statistics
          - show snmp community
      register: services_output
      
    - name: Display services status
      debug:
        var: services_output.stdout_lines
Create a device report template:
mkdir -p templates
nano templates/device_report.j2
Add template content:
Device Report for {{ inventory_hostname }}
Generated on: {{ ansible_date_time.iso8601 }}
========================================

System Information:
- Hostname: {{ facts.ansible_net_hostname | default('N/A') }}
- Model: {{ facts.ansible_net_model | default('N/A') }}
- Version: {{ facts.ansible_net_version | default('N/A') }}
- Serial Number: {{ facts.ansible_net_serialnum | default('N/A') }}

Network Interfaces:
{% for interface, details in facts.ansible_net_interfaces.items() %}
- {{ interface }}: 
  - Status: {{ details.operstatus | default('Unknown') }}
  - Description: {{ details.description | default('No description') }}
  - MAC Address: {{ details.macaddress | default('N/A') }}
{% endfor %}

Memory Usage:
- Total Memory: {{ facts.ansible_net_memtotal_mb | default('N/A') }} MB
- Free Memory: {{ facts.ansible_net_memfree_mb | default('N/A') }} MB
Execute the comprehensive management playbook:
ansible-playbook -i inventory/hosts.yml playbooks/network-management.yml
Subtask 3.2: Create Network Monitoring and Health Check Playbook
Create a monitoring playbook:
nano playbooks/network-monitoring.yml
Add monitoring and health check tasks:
---
- name: Network Device Monitoring and Health Checks
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  
  vars:
    health_check_results: []
    
  tasks:
    - name: Check system uptime
      vyos.vyos.vyos_command:
        commands:
          - show system uptime
      register: uptime_result
      
    - name: Check memory usage
      vyos.vyos.vyos_command:
        commands:
          - show system memory
      register: memory_result
      
    - name: Check disk usage
      vyos.vyos.vyos_command:
        commands:
          - show system storage
      register: disk_result
      
    - name: Check interface status
      vyos.vyos.vyos_command:
        commands:
          - show interfaces
      register: interface_result
      
    - name: Check routing table
      vyos.vyos.vyos_command:
        commands:
          - show ip route summary
      register: route_result
      
    - name: Ping connectivity test
      vyos.vyos.vyos_ping:
        dest: 8.8.8.8
        count: 3
      register: ping_result
      ignore_errors: yes
      
    - name: Compile health check results
      set_fact:
        device_health:
          hostname: "{{ inventory_hostname }}"
          uptime: "{{ uptime_result.stdout[0] }}"
          memory_status: "{{ 'OK' if 'MemAvailable' in memory_result.stdout[0] else 'CHECK' }}"
          disk_status: "{{ 'OK' if 'Filesystem' in disk_result.stdout[0] else 'CHECK' }}"
          interface_count: "{{ interface_result.stdout[0] | regex_findall('eth\\d+') | length }}"
          connectivity: "{{ 'OK' if ping_result.packet_loss == '0' else 'FAILED' }}"
          
    - name: Display health check summary
      debug:
        msg: |
          Health Check Summary for {{ device_health.hostname }}:
          - Uptime: {{ device_health.uptime }}
          - Memory Status: {{ device_health.memory_status }}
          - Disk Status: {{ device_health.disk_status }}
          - Active Interfaces: {{ device_health.interface_count }}
          - Internet Connectivity: {{ device_health.connectivity }}
          
    - name: Generate health report
      copy:
        content: |
          Network Health Report - {{ ansible_date_time.iso8601 }}
          ================================================
          Device: {{ device_health.hostname }}
          Uptime: {{ device_health.uptime }}
          Memory Status: {{ device_health.memory_status }}
          Disk Status: {{ device_health.disk_status }}
          Active Interfaces: {{ device_health.interface_count }}
          Internet Connectivity: {{ device_health.connectivity }}
          
          Detailed Interface Information:
          {{ interface_result.stdout[0] }}
          
          Routing Summary:
          {{ route_result.stdout[0] }}
        dest: "/home/student/network-lab/reports/{{ inventory_hostname }}-health-{{ ansible_date_time.epoch }}.txt"
      delegate_to: localhost
Create reports directory and run monitoring:
mkdir -p reports
ansible-playbook -i inventory/hosts.yml playbooks/network-monitoring.yml
Subtask 3.3: Create Network Configuration Rollback Playbook
Create a rollback playbook:
nano playbooks/network-rollback.yml
Add rollback functionality:
---
- name: Network Configuration Rollback
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  
  vars:
    backup_dir: "/home/student/network-lab/backups"
    
  tasks:
    - name: List available backup files
      find:
        paths: "{{ backup_dir }}"
        patterns: "{{ inventory_hostname }}-*.cfg"
      register: backup_files
      delegate_to: localhost
      
    - name: Display available backups
      debug:
        msg: "Available backups: {{ backup_files.files | map(attribute='path') | list }}"
        
    - name: Get latest backup file
      set_fact:
        latest_backup: "{{ backup_files.files | sort(attribute='mtime') | last }}"
      when: backup_files.files | length > 0
      
    - name: Restore from latest backup
      vyos.vyos.vyos_config:
        src: "{{ latest_backup.path }}"
        save: yes
      when: latest_backup is defined and restore_from_backup | default(false)
      
    - name: Create configuration checkpoint
      vyos.vyos.vyos_command:
        commands:
          - configure
          - save /tmp/checkpoint-{{ ansible_date_time.epoch }}
          - exit
      when: create_checkpoint | default(false)
      
    - name: Verify configuration after rollback
      vyos.vyos.vyos_command:
        commands:
          - show configuration
      register: current_config
      when: latest_backup is defined and restore_from_backup | default(false)
      
    - name: Display rollback status
      debug:
        msg: "Configuration rollback completed successfully"
      when: latest_backup is defined and restore_from_backup | default(false)
Test the rollback functionality (without actually rolling back):
ansible-playbook -i inventory/hosts.yml playbooks/network-rollback.yml
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Connection timeout errors

Solution: Increase the ansible_command_timeout variable in your playbooks
Example: Add ansible_command_timeout: 120 to your vars section
Issue 2: Authentication failures

Solution: Verify SSH keys and credentials in the inventory file
Check: Ensure the network devices are accessible via SSH
Issue 3: Module not found errors

Solution: Install the required Ansible collections:
ansible-galaxy collection install vyos.vyos
ansible-galaxy collection install ansible.netcommon
Issue 4: Configuration not saving

Solution: Always include save: yes in your vyos_config tasks
Alternative: Use a separate task to save configuration
Issue 5: Playbook syntax errors

Solution: Validate your YAML syntax:
ansible-playbook --syntax-check playbooks/your-playbook.yml
Verification Commands
Use these commands to verify your configurations:

# Check all network device connectivity
ansible network_devices -i inventory/hosts.yml -m vyos.vyos.vyos_command -a "commands='show version'"

# Verify interface configurations
ansible network_devices -i inventory/hosts.yml -m vyos.vyos.vyos_command -a "commands='show interfaces'"

# Check routing tables
ansible network_devices -i inventory/hosts.yml -m vyos.vyos.vyos_command -a "commands='show ip route'"
Conclusion
In this comprehensive lab, you have successfully accomplished the following key objectives:

Network Interface Automation: You learned how to use Ansible's network modules to automatically configure network interfaces across multiple devices, eliminating manual configuration errors and saving significant time.

VLAN and Routing Management: You implemented automated VLAN creation and routing configuration, including both static and dynamic routing protocols like OSPF, demonstrating how network automation can handle complex networking scenarios.

Comprehensive Device Management: You created sophisticated playbooks that handle device backups, monitoring, health checks, and configuration rollbacks, providing a complete network automation solution.

Real-World Skills: The techniques you've mastered in this lab directly apply to enterprise network environments and are essential for the Red Hat Certified Specialist in Ansible Network Automation certification.

Why This Matters: Network automation is crucial in modern IT infrastructure because it:

Reduces human error in network configurations
Ensures consistency across multiple network devices
Enables rapid deployment and scaling of network services
Provides audit trails and configuration management
Allows for quick recovery from configuration issues
The skills you've developed will help you manage large-scale network infrastructures efficiently and reliably, making you valuable in roles such as Network Engineer, DevOps Engineer, or Infrastructure Automation Specialist. These automation techniques are increasingly important as organizations adopt Infrastructure as Code practices and seek to improve their network operations through automation.
