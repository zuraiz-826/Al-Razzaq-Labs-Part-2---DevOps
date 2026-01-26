Lab 13: Gather Facts from Managed Devices
Objectives
By the end of this lab, you will be able to:

Understand how to use Ansible network modules to gather facts from network devices
Configure and execute fact-gathering playbooks using ansible_network_os
Display and analyze network device information including interfaces, VLANs, and routing tables
Implement best practices for network device fact collection in enterprise environments
Troubleshoot common issues when gathering facts from network infrastructure
Prerequisites
Before starting this lab, you should have:

Basic understanding of Ansible fundamentals (playbooks, inventory, modules)
Familiarity with network concepts (interfaces, VLANs, routing)
Knowledge of YAML syntax and structure
Understanding of SSH connectivity and network device access
Experience with Linux command line operations
Required Knowledge Areas
Ansible inventory configuration
Network device authentication methods
Basic networking protocols (SSH, SNMP)
YAML file structure and syntax
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking setups.

Your lab environment includes:

Ansible control node (pre-installed with Ansible 2.15+)
Simulated network devices (Cisco IOS, Arista EOS, Juniper JunOS)
Pre-configured SSH connectivity
Sample network topologies for testing
Task 1: Configure Ansible Environment for Network Device Management
Subtask 1.1: Verify Ansible Installation and Network Collections
First, let's verify that Ansible is properly installed with the necessary network collections.

# Check Ansible version
ansible --version

# List installed collections
ansible-galaxy collection list | grep -E "(cisco|arista|juniper|ansible.netcommon)"

# Install required network collections if not present
ansible-galaxy collection install cisco.ios
ansible-galaxy collection install arista.eos
ansible-galaxy collection install junipernetworks.junos
ansible-galaxy collection install ansible.netcommon
Subtask 1.2: Create Project Directory Structure
Set up a well-organized directory structure for your network automation project.

# Create main project directory
mkdir -p ~/ansible-network-facts
cd ~/ansible-network-facts

# Create subdirectories for organization
mkdir -p {inventory,playbooks,group_vars,host_vars,output}

# Create initial files
touch inventory/hosts.yml
touch ansible.cfg
Subtask 1.3: Configure Ansible Settings
Create an ansible.cfg file with network-specific configurations.

[defaults]
inventory = inventory/hosts.yml
host_key_checking = False
timeout = 30
gathering = explicit
retry_files_enabled = False
stdout_callback = yaml

[inventory]
enable_plugins = yaml, ini, auto

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
Task 2: Create Network Device Inventory
Subtask 2.1: Define Network Device Inventory
Create a comprehensive inventory file that includes various network device types.

# inventory/hosts.yml
all:
  children:
    cisco_devices:
      hosts:
        cisco-switch-01:
          ansible_host: 192.168.1.10
          ansible_network_os: cisco.ios.ios
          ansible_user: admin
          ansible_password: cisco123
          ansible_connection: ansible.netcommon.network_cli
          device_type: switch
          location: datacenter-1
        cisco-router-01:
          ansible_host: 192.168.1.11
          ansible_network_os: cisco.ios.ios
          ansible_user: admin
          ansible_password: cisco123
          ansible_connection: ansible.netcommon.network_cli
          device_type: router
          location: datacenter-1
    
    arista_devices:
      hosts:
        arista-switch-01:
          ansible_host: 192.168.1.20
          ansible_network_os: arista.eos.eos
          ansible_user: admin
          ansible_password: arista123
          ansible_connection: ansible.netcommon.network_cli
          device_type: switch
          location: datacenter-2
    
    juniper_devices:
      hosts:
        juniper-router-01:
          ansible_host: 192.168.1.30
          ansible_network_os: junipernetworks.junos.junos
          ansible_user: admin
          ansible_password: juniper123
          ansible_connection: ansible.netcommon.netconf
          device_type: router
          location: datacenter-3

  vars:
    ansible_python_interpreter: /usr/bin/python3
Subtask 2.2: Create Group Variables
Define common variables for each device group.

# group_vars/cisco_devices.yml
---
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: cisco.ios.ios
ansible_become: yes
ansible_become_method: enable
ansible_become_password: enable123
# group_vars/arista_devices.yml
---
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: arista.eos.eos
ansible_become: yes
ansible_become_method: enable
# group_vars/juniper_devices.yml
---
ansible_connection: ansible.netcommon.netconf
ansible_network_os: junipernetworks.junos.junos
Subtask 2.3: Test Connectivity
Verify that Ansible can connect to your network devices.

# Test connectivity to all devices
ansible all -m ping

# Test connectivity to specific groups
ansible cisco_devices -m ping
ansible arista_devices -m ping
ansible juniper_devices -m ping
Task 3: Create Fact-Gathering Playbooks
Subtask 3.1: Basic Facts Collection Playbook
Create a comprehensive playbook to gather basic facts from all network devices.

# playbooks/gather_basic_facts.yml
---
- name: Gather Basic Facts from Network Devices
  hosts: all
  gather_facts: no
  connection: local
  
  tasks:
    - name: Gather facts from Cisco IOS devices
      cisco.ios.ios_facts:
        gather_subset:
          - all
      when: ansible_network_os == 'cisco.ios.ios'
      register: cisco_facts
    
    - name: Gather facts from Arista EOS devices
      arista.eos.eos_facts:
        gather_subset:
          - all
      when: ansible_network_os == 'arista.eos.eos'
      register: arista_facts
    
    - name: Gather facts from Juniper JunOS devices
      junipernetworks.junos.junos_facts:
        gather_subset:
          - all
      when: ansible_network_os == 'junipernetworks.junos.junos'
      register: juniper_facts
    
    - name: Display device hostname and version
      debug:
        msg: |
          Device: {{ inventory_hostname }}
          Hostname: {{ ansible_net_hostname | default('N/A') }}
          OS Version: {{ ansible_net_version | default('N/A') }}
          Model: {{ ansible_net_model | default('N/A') }}
          Serial Number: {{ ansible_net_serialnum | default('N/A') }}
Subtask 3.2: Interface Information Gathering
Create a specialized playbook to gather detailed interface information.

# playbooks/gather_interface_facts.yml
---
- name: Gather Interface Facts from Network Devices
  hosts: all
  gather_facts: no
  connection: local
  
  tasks:
    - name: Gather interface facts from Cisco devices
      cisco.ios.ios_facts:
        gather_subset:
          - interfaces
      when: ansible_network_os == 'cisco.ios.ios'
    
    - name: Gather interface facts from Arista devices
      arista.eos.eos_facts:
        gather_subset:
          - interfaces
      when: ansible_network_os == 'arista.eos.eos'
    
    - name: Gather interface facts from Juniper devices
      junipernetworks.junos.junos_facts:
        gather_subset:
          - interfaces
      when: ansible_network_os == 'junipernetworks.junos.junos'
    
    - name: Display interface information
      debug:
        msg: |
          Device: {{ inventory_hostname }}
          Interface: {{ item.key }}
          Description: {{ item.value.description | default('No description') }}
          IP Address: {{ item.value.ipv4[0].address | default('No IP') if item.value.ipv4 is defined else 'No IP' }}
          Status: {{ item.value.operstatus | default('Unknown') }}
          Speed: {{ item.value.bandwidth | default('Unknown') }}
      loop: "{{ ansible_net_interfaces | dict2items }}"
      when: ansible_net_interfaces is defined
    
    - name: Save interface facts to file
      copy:
        content: |
          Device: {{ inventory_hostname }}
          Timestamp: {{ ansible_date_time.iso8601 }}
          
          Interface Details:
          {% for interface, details in ansible_net_interfaces.items() %}
          - Interface: {{ interface }}
            Description: {{ details.description | default('No description') }}
            IP Address: {{ details.ipv4[0].address | default('No IP') if details.ipv4 is defined else 'No IP' }}
            Status: {{ details.operstatus | default('Unknown') }}
            Speed: {{ details.bandwidth | default('Unknown') }}
            MAC Address: {{ details.macaddress | default('Unknown') }}
          {% endfor %}
        dest: "./output/{{ inventory_hostname }}_interfaces.txt"
      when: ansible_net_interfaces is defined
Subtask 3.3: VLAN Information Gathering
Create a playbook specifically for gathering VLAN information.

# playbooks/gather_vlan_facts.yml
---
- name: Gather VLAN Facts from Network Devices
  hosts: cisco_devices:arista_devices
  gather_facts: no
  connection: local
  
  tasks:
    - name: Gather VLAN information from Cisco devices
      cisco.ios.ios_vlans:
        state: gathered
      when: ansible_network_os == 'cisco.ios.ios'
      register: cisco_vlans
    
    - name: Gather VLAN information from Arista devices
      arista.eos.eos_vlans:
        state: gathered
      when: ansible_network_os == 'arista.eos.eos'
      register: arista_vlans
    
    - name: Display VLAN information for Cisco devices
      debug:
        msg: |
          Device: {{ inventory_hostname }}
          VLAN ID: {{ item.vlan_id }}
          Name: {{ item.name | default('Unnamed') }}
          State: {{ item.state | default('active') }}
      loop: "{{ cisco_vlans.gathered | default([]) }}"
      when: ansible_network_os == 'cisco.ios.ios' and cisco_vlans.gathered is defined
    
    - name: Display VLAN information for Arista devices
      debug:
        msg: |
          Device: {{ inventory_hostname }}
          VLAN ID: {{ item.vlan_id }}
          Name: {{ item.name | default('Unnamed') }}
          State: {{ item.state | default('active') }}
      loop: "{{ arista_vlans.gathered | default([]) }}"
      when: ansible_network_os == 'arista.eos.eos' and arista_vlans.gathered is defined
    
    - name: Save VLAN information to file
      template:
        src: vlan_report.j2
        dest: "./output/{{ inventory_hostname }}_vlans.txt"
      vars:
        vlans: "{{ cisco_vlans.gathered | default(arista_vlans.gathered) | default([]) }}"
Subtask 3.4: Routing Table Information
Create a playbook to gather routing table information.

# playbooks/gather_routing_facts.yml
---
- name: Gather Routing Facts from Network Devices
  hosts: all
  gather_facts: no
  connection: local
  
  tasks:
    - name: Gather routing facts from Cisco devices
      cisco.ios.ios_command:
        commands:
          - show ip route
          - show ipv6 route
      when: ansible_network_os == 'cisco.ios.ios'
      register: cisco_routes
    
    - name: Gather routing facts from Arista devices
      arista.eos.eos_command:
        commands:
          - show ip route
          - show ipv6 route
      when: ansible_network_os == 'arista.eos.eos'
      register: arista_routes
    
    - name: Gather routing facts from Juniper devices
      junipernetworks.junos.junos_command:
        commands:
          - show route
          - show route inet6
      when: ansible_network_os == 'junipernetworks.junos.junos'
      register: juniper_routes
    
    - name: Display routing information
      debug:
        var: item
      loop: "{{ cisco_routes.stdout | default(arista_routes.stdout) | default(juniper_routes.stdout) | default([]) }}"
      when: item is defined
    
    - name: Save routing information to file
      copy:
        content: |
          Device: {{ inventory_hostname }}
          Timestamp: {{ ansible_date_time.iso8601 }}
          Network OS: {{ ansible_network_os }}
          
          IPv4 Routing Table:
          {{ cisco_routes.stdout[0] | default(arista_routes.stdout[0]) | default(juniper_routes.stdout[0]) | default('No IPv4 routes found') }}
          
          IPv6 Routing Table:
          {{ cisco_routes.stdout[1] | default(arista_routes.stdout[1]) | default(juniper_routes.stdout[1]) | default('No IPv6 routes found') }}
        dest: "./output/{{ inventory_hostname }}_routes.txt"
Task 4: Execute Fact-Gathering Operations
Subtask 4.1: Run Basic Facts Collection
Execute the basic facts gathering playbook and analyze the results.

# Run basic facts collection
ansible-playbook playbooks/gather_basic_facts.yml -v

# Run with specific device groups
ansible-playbook playbooks/gather_basic_facts.yml --limit cisco_devices
ansible-playbook playbooks/gather_basic_facts.yml --limit arista_devices
Subtask 4.2: Execute Interface Facts Collection
Run the interface facts gathering playbook.

# Gather interface facts from all devices
ansible-playbook playbooks/gather_interface_facts.yml

# Check the generated output files
ls -la output/
cat output/*_interfaces.txt
Subtask 4.3: Collect VLAN Information
Execute VLAN facts collection for supported devices.

# Create VLAN report template first
mkdir -p templates
Create the VLAN report template:

# templates/vlan_report.j2
Device: {{ inventory_hostname }}
Timestamp: {{ ansible_date_time.iso8601 }}
Network OS: {{ ansible_network_os }}

VLAN Configuration:
==================
{% for vlan in vlans %}
VLAN ID: {{ vlan.vlan_id }}
Name: {{ vlan.name | default('Unnamed') }}
State: {{ vlan.state | default('active') }}
---
{% endfor %}
# Run VLAN facts collection
ansible-playbook playbooks/gather_vlan_facts.yml
Subtask 4.4: Gather Routing Information
Execute routing facts collection.

# Collect routing information
ansible-playbook playbooks/gather_routing_facts.yml

# Review routing output
cat output/*_routes.txt
Task 5: Create Comprehensive Reporting
Subtask 5.1: Master Facts Collection Playbook
Create a comprehensive playbook that gathers all types of facts.

# playbooks/comprehensive_facts.yml
---
- name: Comprehensive Network Device Facts Collection
  hosts: all
  gather_facts: no
  connection: local
  
  vars:
    timestamp: "{{ ansible_date_time.epoch }}"
    report_dir: "./reports/{{ timestamp }}"
  
  tasks:
    - name: Create report directory
      file:
        path: "{{ report_dir }}"
        state: directory
      delegate_to: localhost
      run_once: true
    
    - name: Gather all facts from Cisco devices
      cisco.ios.ios_facts:
        gather_subset:
          - all
      when: ansible_network_os == 'cisco.ios.ios'
    
    - name: Gather all facts from Arista devices
      arista.eos.eos_facts:
        gather_subset:
          - all
      when: ansible_network_os == 'arista.eos.eos'
    
    - name: Gather all facts from Juniper devices
      junipernetworks.junos.junos_facts:
        gather_subset:
          - all
      when: ansible_network_os == 'junipernetworks.junos.junos'
    
    - name: Generate comprehensive device report
      template:
        src: device_report.j2
        dest: "{{ report_dir }}/{{ inventory_hostname }}_comprehensive_report.html"
      vars:
        device_facts: "{{ ansible_facts }}"
Subtask 5.2: Create HTML Report Template
Create an HTML template for comprehensive reporting.

<!-- templates/device_report.j2 -->
<!DOCTYPE html>
<html>
<head>
    <title>Network Device Report - {{ inventory_hostname }}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .section { margin: 20px 0; }
        .interface-table { border-collapse: collapse; width: 100%; }
        .interface-table th, .interface-table td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        .interface-table th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Network Device Report</h1>
        <p><strong>Device:</strong> {{ inventory_hostname }}</p>
        <p><strong>Hostname:</strong> {{ ansible_net_hostname | default('N/A') }}</p>
        <p><strong>OS Version:</strong> {{ ansible_net_version | default('N/A') }}</p>
        <p><strong>Model:</strong> {{ ansible_net_model | default('N/A') }}</p>
        <p><strong>Serial Number:</strong> {{ ansible_net_serialnum | default('N/A') }}</p>
        <p><strong>Report Generated:</strong> {{ ansible_date_time.iso8601 }}</p>
    </div>
    
    <div class="section">
        <h2>Interface Information</h2>
        {% if ansible_net_interfaces is defined %}
        <table class="interface-table">
            <tr>
                <th>Interface</th>
                <th>Description</th>
                <th>IP Address</th>
                <th>Status</th>
                <th>Speed</th>
            </tr>
            {% for interface, details in ansible_net_interfaces.items() %}
            <tr>
                <td>{{ interface }}</td>
                <td>{{ details.description | default('No description') }}</td>
                <td>{{ details.ipv4[0].address | default('No IP') if details.ipv4 is defined else 'No IP' }}</td>
                <td>{{ details.operstatus | default('Unknown') }}</td>
                <td>{{ details.bandwidth | default('Unknown') }}</td>
            </tr>
            {% endfor %}
        </table>
        {% else %}
        <p>No interface information available</p>
        {% endif %}
    </div>
    
    <div class="section">
        <h2>System Information</h2>
        <ul>
            <li><strong>Uptime:</strong> {{ ansible_net_uptime | default('N/A') }}</li>
            <li><strong>Memory:</strong> {{ ansible_net_memtotal_mb | default('N/A') }} MB</li>
            <li><strong>Free Memory:</strong> {{ ansible_net_memfree_mb | default('N/A') }} MB</li>
        </ul>
    </div>
</body>
</html>
Subtask 5.3: Execute Comprehensive Reporting
Run the comprehensive facts collection and generate reports.

# Run comprehensive facts collection
ansible-playbook playbooks/comprehensive_facts.yml

# View generated reports
ls -la reports/*/
Task 6: Advanced Fact Filtering and Analysis
Subtask 6.1: Create Filtered Facts Playbook
Create a playbook that filters and analyzes specific facts.

# playbooks/filtered_facts_analysis.yml
---
- name: Advanced Facts Filtering and Analysis
  hosts: all
  gather_facts: no
  connection: local
  
  tasks:
    - name: Gather facts from all devices
      include_tasks: "{{ ansible_network_os | replace('.', '_') }}_facts.yml"
    
    - name: Analyze interface utilization
      set_fact:
        active_interfaces: "{{ ansible_net_interfaces | dict2items | selectattr('value.operstatus', 'equalto', 'up') | list }}"
        inactive_interfaces: "{{ ansible_net_interfaces | dict2items | selectattr('value.operstatus', 'equalto', 'down') | list }}"
      when: ansible_net_interfaces is defined
    
    - name: Display interface analysis
      debug:
        msg: |
          Device: {{ inventory_hostname }}
          Total Interfaces: {{ ansible_net_interfaces | length if ansible_net_interfaces is defined else 0 }}
          Active Interfaces: {{ active_interfaces | length if active_interfaces is defined else 0 }}
          Inactive Interfaces: {{ inactive_interfaces | length if inactive_interfaces is defined else 0 }}
    
    - name: Identify high-speed interfaces
      set_fact:
        high_speed_interfaces: "{{ ansible_net_interfaces | dict2items | selectattr('value.bandwidth', 'defined') | selectattr('value.bandwidth', '>=', 1000000) | list }}"
      when: ansible_net_interfaces is defined
    
    - name: Display high-speed interface information
      debug:
        msg: |
          High-Speed Interface: {{ item.key }}
          Speed: {{ item.value.bandwidth }}
          Status: {{ item.value.operstatus }}
      loop: "{{ high_speed_interfaces | default([]) }}"
Subtask 6.2: Create OS-Specific Fact Tasks
Create separate task files for each network OS.

# playbooks/cisco_ios_ios_facts.yml
---
- name: Gather Cisco IOS facts
  cisco.ios.ios_facts:
    gather_subset:
      - all
  when: ansible_network_os == 'cisco.ios.ios'
# playbooks/arista_eos_eos_facts.yml
---
- name: Gather Arista EOS facts
  arista.eos.eos_facts:
    gather_subset:
      - all
  when: ansible_network_os == 'arista.eos.eos'
# playbooks/junipernetworks_junos_junos_facts.yml
---
- name: Gather Juniper JunOS facts
  junipernetworks.junos.junos_facts:
    gather_subset:
      - all
  when: ansible_network_os == 'junipernetworks.junos.junos'
Subtask 6.3: Execute Advanced Analysis
Run the advanced facts analysis playbook.

# Execute advanced facts analysis
ansible-playbook playbooks/filtered_facts_analysis.yml -v
Troubleshooting Common Issues
Connection Issues
Problem: Unable to connect to network devices

Solutions:

# Test basic connectivity
ping 192.168.1.10

# Verify SSH connectivity
ssh admin@192.168.1.10

# Check Ansible connectivity with verbose output
ansible cisco-switch-01 -m ping -vvv
Authentication Problems
Problem: Authentication failures

Solutions:

Verify credentials in inventory
Check enable passwords for Cisco devices
Ensure proper connection types (network_cli vs netconf)
# Example fix for Cisco devices
ansible_become: yes
ansible_become_method: enable
ansible_become_password: your_enable_password
Module Not Found Errors
Problem: Network modules not available

Solutions:

# Install missing collections
ansible-galaxy collection install cisco.ios --force
ansible-galaxy collection install arista.eos --force
ansible-galaxy collection install junipernetworks.junos --force

# Verify installation
ansible-galaxy collection list
Fact Gathering Timeouts
Problem: Playbooks timeout when gathering facts

Solutions:

# Increase timeout in ansible.cfg
[defaults]
timeout = 60

# Or in playbook
- name: Gather facts with extended timeout
  cisco.ios.ios_facts:
    gather_subset:
      - all
  vars:
    ansible_command_timeout: 60
Best Practices and Security Considerations
Security Best Practices
Use Ansible Vault for Credentials:
# Create encrypted password file
ansible-vault create group_vars/all/vault.yml

# Add encrypted passwords
vault_cisco_password: cisco123
vault_enable_password: enable123
Implement Proper Access Controls:
# Use dedicated service accounts
ansible_user: ansible-service
ansible_password: "{{ vault_ansible_password }}"
Enable Logging and Auditing:
# In ansible.cfg
[defaults]
log_path = /var/log/ansible.log
Performance Optimization
Use Fact Caching:
# In ansible.cfg
[defaults]
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 3600
Parallel Execution:
# In ansible.cfg
[defaults]
forks = 10
Selective Fact Gathering:
# Only gather specific facts
gather_subset:
  - interfaces
  - hardware
Conclusion
In this comprehensive lab, you have successfully learned how to:

Configure Ansible environments specifically for network device management using modern collections and best practices
Create and manage network device inventories with proper grouping and variable organization
Implement fact-gathering playbooks that collect detailed information from Cisco IOS, Arista EOS, and Juniper JunOS devices
Extract and display critical network information including interfaces, VLANs, and routing tables
Generate comprehensive reports in multiple formats for network documentation and analysis
Apply advanced filtering and analysis techniques to process network facts effectively
Troubleshoot common issues and implement security best practices
Why This Matters
Network fact gathering with Ansible is crucial for:

Network Documentation: Automatically maintaining up-to-date network inventories
Compliance Reporting: Generating reports for security and regulatory requirements
Change Management: Establishing baselines before implementing network changes
Troubleshooting: Quickly gathering diagnostic information across multiple devices
Capacity Planning: Analyzing interface utilization and device performance metrics
Next Steps
To further enhance your network automation skills:

Explore custom fact modules for specialized network equipment
Implement scheduled fact collection using cron jobs or automation platforms
Integrate with monitoring systems like Nagios, Zabbix, or Prometheus
Develop custom reporting dashboards using the collected facts
Practice with real network equipment in lab environments
This lab provides the foundation for advanced network automation scenarios and prepares you for the Red Hat Certified Specialist in Ansible Network Automation certification exam by demonstrating practical skills in network device fact collection and analysis.
