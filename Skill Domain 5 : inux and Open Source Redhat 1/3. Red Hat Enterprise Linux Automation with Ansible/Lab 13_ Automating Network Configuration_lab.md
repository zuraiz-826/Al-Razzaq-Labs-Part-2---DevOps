Lab 13: Automating Network Configuration
Objectives
By the end of this lab, students will be able to:

• Configure network interfaces using Ansible's nmcli module • Automate static IP address assignment and network interface management • Set up routing configurations through Ansible playbooks • Configure DNS settings automatically using Ansible • Understand the fundamentals of network automation in enterprise environments • Troubleshoot common network configuration issues in automated deployments

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux networking concepts (IP addresses, subnets, routing) • Familiarity with Ansible fundamentals (playbooks, modules, inventory) • Knowledge of YAML syntax and structure • Understanding of SSH connectivity and key-based authentication • Basic command-line experience with Linux systems

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking setups.

Your lab environment includes: • One Ansible control node (ansible-controller) • Two managed nodes (node1 and node2) • Pre-installed Ansible software • SSH key authentication already configured

Task 1: Configure Network Interfaces Using nmcli Module
Subtask 1.1: Verify Initial Network Configuration
First, let's examine the current network configuration on our managed nodes.

Connect to your Ansible control node:
ssh student@ansible-controller
Check connectivity to managed nodes:
ansible all -m ping
Examine current network interfaces on managed nodes:
ansible all -m shell -a "ip addr show"
Check current NetworkManager connections:
ansible all -m shell -a "nmcli connection show"
Subtask 1.2: Create Ansible Inventory and Basic Playbook Structure
Create a working directory for this lab:
mkdir ~/lab13-network-automation
cd ~/lab13-network-automation
Create an inventory file:
cat > inventory << EOF
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[all:vars]
ansible_user=student
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Test inventory connectivity:
ansible -i inventory all -m ping
Subtask 1.3: Configure Static IP Addresses
Create a playbook to configure static IP addresses:
cat > configure-static-ip.yml << 'EOF'
---
- name: Configure Static IP Addresses
  hosts: all
  become: yes
  vars:
    network_configs:
      node1:
        ip: "192.168.1.100"
        gateway: "192.168.1.1"
        dns: "8.8.8.8"
      node2:
        ip: "192.168.1.101"
        gateway: "192.168.1.1"
        dns: "8.8.8.8"
  
  tasks:
    - name: Configure static IP for ethernet interface
      community.general.nmcli:
        conn_name: "{{ ansible_default_ipv4.interface }}"
        ifname: "{{ ansible_default_ipv4.interface }}"
        type: ethernet
        ip4: "{{ network_configs[inventory_hostname].ip }}/24"
        gw4: "{{ network_configs[inventory_hostname].gateway }}"
        dns4: "{{ network_configs[inventory_hostname].dns }}"
        state: present
      notify: restart_network

    - name: Bring up the connection
      community.general.nmcli:
        conn_name: "{{ ansible_default_ipv4.interface }}"
        state: up

  handlers:
    - name: restart_network
      service:
        name: NetworkManager
        state: restarted
EOF
Run the playbook to configure static IPs:
ansible-playbook -i inventory configure-static-ip.yml
Verify the new IP configuration:
ansible -i inventory all -m shell -a "ip addr show"
Subtask 1.4: Configure Additional Network Interfaces
Create a playbook for configuring secondary network interfaces:
cat > configure-secondary-interface.yml << 'EOF'
---
- name: Configure Secondary Network Interface
  hosts: all
  become: yes
  
  tasks:
    - name: Create secondary network connection
      community.general.nmcli:
        conn_name: "secondary-net"
        ifname: "{{ ansible_default_ipv4.interface }}"
        type: ethernet
        ip4: "10.0.0.{{ ansible_play_hosts.index(inventory_hostname) + 10 }}/24"
        state: present
      
    - name: Verify secondary connection exists
      community.general.nmcli:
        conn_name: "secondary-net"
        state: present
      register: secondary_result
      
    - name: Display connection status
      debug:
        msg: "Secondary network connection configured: {{ secondary_result.changed }}"
EOF
Execute the secondary interface configuration:
ansible-playbook -i inventory configure-secondary-interface.yml
List all network connections:
ansible -i inventory all -m shell -a "nmcli connection show"
Task 2: Set Up Routing and DNS Configurations
Subtask 2.1: Configure Custom Routing Tables
Create a playbook for advanced routing configuration:
cat > configure-routing.yml << 'EOF'
---
- name: Configure Advanced Routing
  hosts: all
  become: yes
  vars:
    custom_routes:
      - destination: "172.16.0.0/16"
        gateway: "192.168.1.1"
        metric: 100
      - destination: "10.10.0.0/16"
        gateway: "192.168.1.1"
        metric: 200
  
  tasks:
    - name: Add custom static routes
      community.general.nmcli:
        conn_name: "{{ ansible_default_ipv4.interface }}"
        type: ethernet
        routes4: "{{ custom_routes | map(attribute='destination') | list }}"
        route_metric4: "{{ custom_routes[0].metric }}"
        state: present
      notify: reload_connection
      
    - name: Configure routing table entries
      lineinfile:
        path: /etc/sysconfig/network-scripts/route-{{ ansible_default_ipv4.interface }}
        line: "{{ item.destination }} via {{ item.gateway }} metric {{ item.metric }}"
        create: yes
      loop: "{{ custom_routes }}"
      notify: reload_connection
      
    - name: Display current routing table
      shell: "ip route show"
      register: routing_table
      
    - name: Show routing configuration
      debug:
        var: routing_table.stdout_lines

  handlers:
    - name: reload_connection
      community.general.nmcli:
        conn_name: "{{ ansible_default_ipv4.interface }}"
        state: down
      
    - name: bring_up_connection
      community.general.nmcli:
        conn_name: "{{ ansible_default_ipv4.interface }}"
        state: up
EOF
Apply the routing configuration:
ansible-playbook -i inventory configure-routing.yml
Verify routing table:
ansible -i inventory all -m shell -a "ip route show"
Subtask 2.2: Configure DNS Settings
Create a comprehensive DNS configuration playbook:
cat > configure-dns.yml << 'EOF'
---
- name: Configure DNS Settings
  hosts: all
  become: yes
  vars:
    dns_servers:
      primary: "8.8.8.8"
      secondary: "8.8.4.4"
      tertiary: "1.1.1.1"
    search_domains:
      - "example.com"
      - "lab.local"
      - "internal.net"
  
  tasks:
    - name: Configure DNS servers in NetworkManager connection
      community.general.nmcli:
        conn_name: "{{ ansible_default_ipv4.interface }}"
        type: ethernet
        dns4: 
          - "{{ dns_servers.primary }}"
          - "{{ dns_servers.secondary }}"
          - "{{ dns_servers.tertiary }}"
        dns4_search: "{{ search_domains }}"
        state: present
      notify: restart_network
      
    - name: Create custom resolv.conf backup
      copy:
        src: /etc/resolv.conf
        dest: /etc/resolv.conf.backup
        remote_src: yes
        
    - name: Configure /etc/resolv.conf
      template:
        src: resolv.conf.j2
        dest: /etc/resolv.conf
        backup: yes
      notify: test_dns
      
    - name: Set DNS resolution priority
      lineinfile:
        path: /etc/nsswitch.conf
        regexp: '^hosts:'
        line: 'hosts: files dns myhostname'
        backup: yes

  handlers:
    - name: restart_network
      service:
        name: NetworkManager
        state: restarted
        
    - name: test_dns
      shell: "nslookup google.com"
      register: dns_test
      ignore_errors: yes
EOF
Create the DNS template file:
mkdir -p templates
cat > templates/resolv.conf.j2 << 'EOF'
# Generated by Ansible - Lab 13
# Search domains
{% for domain in search_domains %}
search {{ domain }}
{% endfor %}

# DNS servers
nameserver {{ dns_servers.primary }}
nameserver {{ dns_servers.secondary }}
nameserver {{ dns_servers.tertiary }}

# DNS options
options timeout:2
options attempts:3
options rotate
EOF
Execute the DNS configuration playbook:
ansible-playbook -i inventory configure-dns.yml
Test DNS resolution:
ansible -i inventory all -m shell -a "nslookup google.com"
Subtask 2.3: Create a Comprehensive Network Configuration Playbook
Combine all network configurations into a master playbook:
cat > master-network-config.yml << 'EOF'
---
- name: Master Network Configuration Playbook
  hosts: all
  become: yes
  vars:
    network_interface: "{{ ansible_default_ipv4.interface }}"
    base_ip_network: "192.168.1"
    dns_servers: ["8.8.8.8", "8.8.4.4", "1.1.1.1"]
    search_domains: ["lab.local", "example.com"]
    
  tasks:
    - name: Gather network facts
      setup:
        gather_subset: network
        
    - name: Display current network interface
      debug:
        msg: "Configuring interface: {{ network_interface }}"
        
    - name: Configure primary network connection
      community.general.nmcli:
        conn_name: "primary-{{ network_interface }}"
        ifname: "{{ network_interface }}"
        type: ethernet
        ip4: "{{ base_ip_network }}.{{ 100 + ansible_play_hosts.index(inventory_hostname) }}/24"
        gw4: "{{ base_ip_network }}.1"
        dns4: "{{ dns_servers }}"
        dns4_search: "{{ search_domains }}"
        state: present
      register: primary_config
      
    - name: Activate primary connection
      community.general.nmcli:
        conn_name: "primary-{{ network_interface }}"
        state: up
      when: primary_config.changed
      
    - name: Add static routes for internal networks
      community.general.nmcli:
        conn_name: "primary-{{ network_interface }}"
        type: ethernet
        routes4:
          - "10.0.0.0/8 {{ base_ip_network }}.1"
          - "172.16.0.0/12 {{ base_ip_network }}.1"
        state: present
        
    - name: Verify network connectivity
      ping:
        data: "{{ base_ip_network }}.1"
        count: 3
      register: ping_result
      ignore_errors: yes
      
    - name: Display connectivity results
      debug:
        msg: "Gateway connectivity: {{ 'SUCCESS' if ping_result.rc == 0 else 'FAILED' }}"
        
    - name: Test DNS resolution
      shell: "nslookup {{ item }}"
      loop:
        - "google.com"
        - "github.com"
        - "redhat.com"
      register: dns_tests
      ignore_errors: yes
      
    - name: Display DNS test results
      debug:
        msg: "DNS resolution for {{ item.item }}: {{ 'SUCCESS' if item.rc == 0 else 'FAILED' }}"
      loop: "{{ dns_tests.results }}"
EOF
Run the master network configuration:
ansible-playbook -i inventory master-network-config.yml
Create a network validation playbook:
cat > validate-network.yml << 'EOF'
---
- name: Validate Network Configuration
  hosts: all
  become: yes
  
  tasks:
    - name: Check network interface status
      shell: "nmcli device status"
      register: device_status
      
    - name: Display interface status
      debug:
        var: device_status.stdout_lines
        
    - name: Check active connections
      shell: "nmcli connection show --active"
      register: active_connections
      
    - name: Display active connections
      debug:
        var: active_connections.stdout_lines
        
    - name: Test internet connectivity
      uri:
        url: "http://www.google.com"
        method: HEAD
        timeout: 10
      register: internet_test
      ignore_errors: yes
      
    - name: Display internet connectivity status
      debug:
        msg: "Internet connectivity: {{ 'AVAILABLE' if internet_test.status == 200 else 'UNAVAILABLE' }}"
        
    - name: Generate network configuration report
      shell: |
        echo "=== Network Configuration Report ===" > /tmp/network_report.txt
        echo "Hostname: $(hostname)" >> /tmp/network_report.txt
        echo "Date: $(date)" >> /tmp/network_report.txt
        echo "" >> /tmp/network_report.txt
        echo "=== IP Configuration ===" >> /tmp/network_report.txt
        ip addr show >> /tmp/network_report.txt
        echo "" >> /tmp/network_report.txt
        echo "=== Routing Table ===" >> /tmp/network_report.txt
        ip route show >> /tmp/network_report.txt
        echo "" >> /tmp/network_report.txt
        echo "=== DNS Configuration ===" >> /tmp/network_report.txt
        cat /etc/resolv.conf >> /tmp/network_report.txt
        
    - name: Fetch network reports
      fetch:
        src: /tmp/network_report.txt
        dest: "./reports/{{ inventory_hostname }}_network_report.txt"
        flat: yes
EOF
Create reports directory and run validation:
mkdir -p reports
ansible-playbook -i inventory validate-network.yml
Review the generated reports:
ls -la reports/
cat reports/node1_network_report.txt
Troubleshooting Common Issues
Issue 1: NetworkManager Service Not Running
Problem: nmcli commands fail with "NetworkManager is not running"

Solution:

ansible -i inventory all -m service -a "name=NetworkManager state=started enabled=yes" --become
Issue 2: DNS Resolution Failures
Problem: DNS lookups fail after configuration changes

Solution:

# Check DNS configuration
ansible -i inventory all -m shell -a "cat /etc/resolv.conf"

# Restart NetworkManager
ansible -i inventory all -m service -a "name=NetworkManager state=restarted" --become

# Test DNS manually
ansible -i inventory all -m shell -a "dig @8.8.8.8 google.com"
Issue 3: Static Routes Not Persisting
Problem: Custom routes disappear after reboot

Solution:

# Verify route configuration files
ansible -i inventory all -m shell -a "ls -la /etc/sysconfig/network-scripts/route-*"

# Check NetworkManager connection profiles
ansible -i inventory all -m shell -a "nmcli connection show"
Advanced Configuration Examples
Creating VLAN Interfaces
cat > configure-vlan.yml << 'EOF'
---
- name: Configure VLAN Interface
  hosts: all
  become: yes
  
  tasks:
    - name: Create VLAN interface
      community.general.nmcli:
        conn_name: "vlan100"
        type: vlan
        vlandev: "{{ ansible_default_ipv4.interface }}"
        vlanid: 100
        ip4: "192.168.100.{{ 10 + ansible_play_hosts.index(inventory_hostname) }}/24"
        state: present
        
    - name: Activate VLAN interface
      community.general.nmcli:
        conn_name: "vlan100"
        state: up
EOF
Bonding Network Interfaces
cat > configure-bonding.yml << 'EOF'
---
- name: Configure Network Bonding
  hosts: all
  become: yes
  
  tasks:
    - name: Create bond interface
      community.general.nmcli:
        conn_name: "bond0"
        type: bond
        mode: "active-backup"
        ip4: "192.168.2.{{ 10 + ansible_play_hosts.index(inventory_hostname) }}/24"
        state: present
        
    - name: Add slave interfaces to bond
      community.general.nmcli:
        conn_name: "bond0-slave-{{ item }}"
        type: ethernet
        ifname: "{{ item }}"
        master: "bond0"
        slave_type: bond
        state: present
      loop:
        - "eth1"
        - "eth2"
      ignore_errors: yes
EOF
Conclusion
In this lab, you have successfully accomplished the following:

Key Achievements: • Automated Network Interface Configuration: Used Ansible's nmcli module to programmatically configure network interfaces, eliminating manual configuration errors and ensuring consistency across multiple systems.

• Implemented Static IP Management: Created automated workflows for assigning and managing static IP addresses, which is crucial for server environments where consistent addressing is required.

• Configured Advanced Routing: Set up custom routing tables and static routes through automation, enabling complex network topologies and traffic management.

• Automated DNS Configuration: Implemented centralized DNS management using Ansible, ensuring all systems have consistent name resolution capabilities.

• Created Validation and Reporting: Developed automated testing and reporting mechanisms to verify network configurations and generate documentation.

Why This Matters:

Network automation is essential in modern IT infrastructure because it:

Reduces Human Error: Manual network configuration is prone to mistakes that can cause outages
Ensures Consistency: Automated configurations guarantee identical setups across all systems
Saves Time: What takes hours manually can be completed in minutes with automation
Improves Scalability: Easy to deploy network configurations to hundreds or thousands of systems
Enhances Documentation: Ansible playbooks serve as living documentation of your network infrastructure
Real-World Applications:

Data Center Deployments: Rapidly configure networking for new server installations
Cloud Infrastructure: Automate network setup in cloud environments
Disaster Recovery: Quickly restore network configurations during system recovery
Compliance: Ensure network configurations meet security and regulatory requirements
You now have the foundational skills to automate network configuration tasks in enterprise environments, making you more valuable in DevOps, System Administration, and Network Engineering roles. These automation techniques are directly applicable to Red Hat Enterprise Linux environments and align with industry best practices for infrastructure as code.
