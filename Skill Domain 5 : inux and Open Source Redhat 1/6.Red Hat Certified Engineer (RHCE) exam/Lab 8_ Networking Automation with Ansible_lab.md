Lab 8: Networking Automation with Ansible
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of network automation using Ansible
Write Ansible playbooks to configure network interfaces using the nmcli module
Automate firewall configuration using the firewalld module
Validate network connectivity and configuration changes
Apply best practices for network automation in enterprise environments
Prepare for Red Hat Certified Engineer (RHCE) exam networking automation scenarios
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Basic knowledge of networking concepts (IP addresses, subnets, firewall rules)
Understanding of Ansible fundamentals (playbooks, modules, inventory)
Experience with text editors like vim or nano
Required Knowledge Areas
Linux system administration basics
Network interface configuration concepts
Firewall management principles
SSH connectivity and key-based authentication
Lab Environment Setup
Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or install software.

Your lab environment includes:

Control Node: CentOS/RHEL 8+ with Ansible pre-installed
Managed Nodes: Two target systems for network configuration
Pre-configured SSH key authentication between nodes
All necessary packages and dependencies installed
Environment Details
Control Node: ansible-control (192.168.1.10)
Managed Node 1: web-server (192.168.1.20)
Managed Node 2: db-server (192.168.1.30)
Task 1: Configure Network Interfaces with Ansible nmcli Module
Subtask 1.1: Create Ansible Inventory File
First, we'll create an inventory file to define our managed hosts.

Connect to the control node and navigate to your working directory:
cd /home/student/ansible-labs
mkdir lab8-networking
cd lab8-networking
Create the inventory file:
vim inventory.ini
Add the following content:
[webservers]
web-server ansible_host=192.168.1.20

[databases]
db-server ansible_host=192.168.1.30

[all:vars]
ansible_user=student
ansible_ssh_private_key_file=/home/student/.ssh/id_rsa
Test connectivity to ensure all hosts are reachable:
ansible all -i inventory.ini -m ping
Subtask 1.2: Create Network Configuration Playbook
Now we'll create a comprehensive playbook to configure network interfaces and hostnames.

Create the main playbook file:
vim network-config.yml
Add the complete network configuration playbook:
---
- name: Configure Network Interfaces and Hostnames
  hosts: all
  become: yes
  vars:
    dns_servers:
      - 8.8.8.8
      - 8.8.4.4
  
  tasks:
    - name: Set hostname for web server
      hostname:
        name: web-server.lab.local
      when: inventory_hostname == 'web-server'
      
    - name: Set hostname for database server
      hostname:
        name: db-server.lab.local
      when: inventory_hostname == 'db-server'
    
    - name: Configure static IP for web server
      nmcli:
        conn_name: "System eth0"
        ifname: eth0
        type: ethernet
        ip4: 192.168.1.20/24
        gw4: 192.168.1.1
        dns4: "{{ dns_servers }}"
        state: present
      when: inventory_hostname == 'web-server'
      notify: restart network
    
    - name: Configure static IP for database server
      nmcli:
        conn_name: "System eth0"
        ifname: eth0
        type: ethernet
        ip4: 192.168.1.30/24
        gw4: 192.168.1.1
        dns4: "{{ dns_servers }}"
        state: present
      when: inventory_hostname == 'db-server'
      notify: restart network
    
    - name: Add secondary IP to web server
      nmcli:
        conn_name: "System eth0"
        ifname: eth0
        type: ethernet
        ip4: 192.168.1.21/24
        state: present
      when: inventory_hostname == 'web-server'
      notify: restart network
    
    - name: Ensure network connection is up
      nmcli:
        conn_name: "System eth0"
        state: up
      
  handlers:
    - name: restart network
      systemd:
        name: NetworkManager
        state: restarted
Execute the network configuration playbook:
ansible-playbook -i inventory.ini network-config.yml
Subtask 1.3: Verify Network Configuration
Let's verify that our network configuration was applied correctly.

Create a verification playbook:
vim verify-network.yml
Add verification tasks:
---
- name: Verify Network Configuration
  hosts: all
  become: yes
  
  tasks:
    - name: Check hostname configuration
      command: hostname
      register: current_hostname
      
    - name: Display current hostname
      debug:
        msg: "Current hostname: {{ current_hostname.stdout }}"
    
    - name: Get network interface information
      command: nmcli connection show
      register: nmcli_connections
      
    - name: Display network connections
      debug:
        msg: "{{ nmcli_connections.stdout_lines }}"
    
    - name: Check IP address assignment
      command: ip addr show eth0
      register: ip_info
      
    - name: Display IP configuration
      debug:
        msg: "{{ ip_info.stdout_lines }}"
    
    - name: Test DNS resolution
      command: nslookup google.com
      register: dns_test
      ignore_errors: yes
      
    - name: Display DNS test results
      debug:
        msg: "DNS Resolution: {{ 'SUCCESS' if dns_test.rc == 0 else 'FAILED' }}"
Run the verification playbook:
ansible-playbook -i inventory.ini verify-network.yml
Task 2: Automate Firewall Configuration with firewalld Module
Subtask 2.1: Create Firewall Configuration Playbook
We'll create a comprehensive firewall configuration that follows security best practices.

Create the firewall playbook:
vim firewall-config.yml
Add the complete firewall configuration:
---
- name: Configure Firewall Rules with firewalld
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
    
    - name: Configure firewall for web server
      block:
        - name: Allow HTTP traffic
          firewalld:
            service: http
            permanent: yes
            state: enabled
            immediate: yes
        
        - name: Allow HTTPS traffic
          firewalld:
            service: https
            permanent: yes
            state: enabled
            immediate: yes
        
        - name: Allow custom web port 8080
          firewalld:
            port: 8080/tcp
            permanent: yes
            state: enabled
            immediate: yes
        
        - name: Allow SSH from specific subnet
          firewalld:
            rich_rule: 'rule family="ipv4" source address="192.168.1.0/24" service name="ssh" accept'
            permanent: yes
            state: enabled
            immediate: yes
      when: inventory_hostname == 'web-server'
    
    - name: Configure firewall for database server
      block:
        - name: Allow MySQL/MariaDB
          firewalld:
            service: mysql
            permanent: yes
            state: enabled
            immediate: yes
        
        - name: Allow PostgreSQL
          firewalld:
            port: 5432/tcp
            permanent: yes
            state: enabled
            immediate: yes
        
        - name: Allow database backup port
          firewalld:
            port: 3307/tcp
            permanent: yes
            state: enabled
            immediate: yes
            zone: internal
        
        - name: Restrict SSH to management network
          firewalld:
            rich_rule: 'rule family="ipv4" source address="192.168.1.10/32" service name="ssh" accept'
            permanent: yes
            state: enabled
            immediate: yes
      when: inventory_hostname == 'db-server'
    
    - name: Remove default SSH rule (if exists)
      firewalld:
        service: ssh
        permanent: yes
        state: disabled
        immediate: yes
      ignore_errors: yes
    
    - name: Set default zone to public
      firewalld:
        zone: public
        interface: eth0
        permanent: yes
        immediate: yes
        state: enabled
    
    - name: Enable logging for denied packets
      firewalld:
        zone: public
        log_denied: all
        permanent: yes
        immediate: yes
        state: enabled
Execute the firewall configuration:
ansible-playbook -i inventory.ini firewall-config.yml
Subtask 2.2: Create Advanced Firewall Rules
Let's add more sophisticated firewall rules including rate limiting and zone-based configurations.

Create an advanced firewall playbook:
vim advanced-firewall.yml
Add advanced firewall configurations:
---
- name: Advanced Firewall Configuration
  hosts: all
  become: yes
  
  tasks:
    - name: Create custom firewall zone for DMZ
      firewalld:
        zone: dmz
        permanent: yes
        state: present
        immediate: yes
    
    - name: Configure rate limiting for SSH
      firewalld:
        rich_rule: 'rule service name="ssh" accept limit value="3/m"'
        permanent: yes
        state: enabled
        immediate: yes
        zone: public
    
    - name: Block specific IP range
      firewalld:
        rich_rule: 'rule family="ipv4" source address="10.0.0.0/8" drop'
        permanent: yes
        state: enabled
        immediate: yes
        zone: public
    
    - name: Allow ICMP ping with rate limiting
      firewalld:
        rich_rule: 'rule protocol value="icmp" accept limit value="10/s"'
        permanent: yes
        state: enabled
        immediate: yes
        zone: public
    
    - name: Configure port forwarding for web server
      firewalld:
        rich_rule: 'rule family="ipv4" forward-port port="80" protocol="tcp" to-port="8080"'
        permanent: yes
        state: enabled
        immediate: yes
        zone: public
      when: inventory_hostname == 'web-server'
    
    - name: Create service definition for custom application
      copy:
        content: |
          <?xml version="1.0" encoding="utf-8"?>
          <service>
            <short>Custom App</short>
            <description>Custom application service</description>
            <port protocol="tcp" port="9090"/>
            <port protocol="udp" port="9091"/>
          </service>
        dest: /etc/firewalld/services/custom-app.xml
        mode: '0644'
      notify: reload firewalld
    
    - name: Enable custom service
      firewalld:
        service: custom-app
        permanent: yes
        state: enabled
        immediate: yes
        zone: dmz
  
  handlers:
    - name: reload firewalld
      systemd:
        name: firewalld
        state: reloaded
Run the advanced firewall configuration:
ansible-playbook -i inventory.ini advanced-firewall.yml
Task 3: Validate Network Connectivity and Configuration
Subtask 3.1: Create Comprehensive Network Validation Playbook
Now we'll create a thorough validation playbook to test all our configurations.

Create the validation playbook:
vim network-validation.yml
Add comprehensive validation tasks:
---
- name: Comprehensive Network and Firewall Validation
  hosts: all
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Test connectivity to external hosts
      ping:
        data: google.com
      register: external_ping
      ignore_errors: yes
    
    - name: Test connectivity between managed hosts
      ping:
        data: "{{ hostvars[item]['ansible_host'] }}"
      loop: "{{ groups['all'] }}"
      when: item != inventory_hostname
      register: internal_ping
      ignore_errors: yes
    
    - name: Check network interface status
      command: nmcli device status
      register: device_status
    
    - name: Display network device status
      debug:
        msg: "{{ device_status.stdout_lines }}"
    
    - name: Verify IP configuration with nmcli
      command: nmcli connection show "System eth0"
      register: connection_details
    
    - name: Display connection details
      debug:
        msg: "{{ connection_details.stdout_lines }}"
    
    - name: Check firewall status
      command: firewall-cmd --state
      register: firewall_status
    
    - name: Display firewall status
      debug:
        msg: "Firewall Status: {{ firewall_status.stdout }}"
    
    - name: List active firewall zones
      command: firewall-cmd --get-active-zones
      register: active_zones
    
    - name: Display active zones
      debug:
        msg: "{{ active_zones.stdout_lines }}"
    
    - name: List allowed services in public zone
      command: firewall-cmd --zone=public --list-services
      register: public_services
    
    - name: Display allowed services
      debug:
        msg: "Public Zone Services: {{ public_services.stdout }}"
    
    - name: List allowed ports in public zone
      command: firewall-cmd --zone=public --list-ports
      register: public_ports
    
    - name: Display allowed ports
      debug:
        msg: "Public Zone Ports: {{ public_ports.stdout }}"
    
    - name: Test specific port connectivity
      wait_for:
        host: "{{ ansible_host }}"
        port: 22
        timeout: 5
      delegate_to: localhost
      register: ssh_connectivity
      ignore_errors: yes
    
    - name: Display connectivity test results
      debug:
        msg: "SSH Connectivity: {{ 'SUCCESS' if ssh_connectivity is succeeded else 'FAILED' }}"
    
    - name: Generate network summary report
      debug:
        msg: |
          =================================
          NETWORK CONFIGURATION SUMMARY
          =================================
          Hostname: {{ ansible_hostname }}
          IP Address: {{ ansible_default_ipv4.address }}
          Gateway: {{ ansible_default_ipv4.gateway }}
          DNS Servers: {{ ansible_dns.nameservers | join(', ') }}
          Network Interface: {{ ansible_default_ipv4.interface }}
          Firewall Status: {{ firewall_status.stdout }}
          External Connectivity: {{ 'SUCCESS' if external_ping is succeeded else 'FAILED' }}
          =================================
Execute the validation playbook:
ansible-playbook -i inventory.ini network-validation.yml
Subtask 3.2: Create Automated Network Testing Suite
Let's create a more advanced testing suite that performs various network tests.

Create the testing suite playbook:
vim network-testing-suite.yml
Add comprehensive testing tasks:
---
- name: Automated Network Testing Suite
  hosts: all
  become: yes
  
  vars:
    test_results: []
  
  tasks:
    - name: Test 1 - Basic Connectivity
      block:
        - name: Ping localhost
          ping:
            data: 127.0.0.1
          register: localhost_ping
        
        - name: Record localhost test result
          set_fact:
            test_results: "{{ test_results + ['Localhost Ping: ' + ('PASS' if localhost_ping is succeeded else 'FAIL')] }}"
    
    - name: Test 2 - DNS Resolution
      block:
        - name: Resolve external domain
          command: nslookup redhat.com
          register: dns_resolution
          ignore_errors: yes
        
        - name: Record DNS test result
          set_fact:
            test_results: "{{ test_results + ['DNS Resolution: ' + ('PASS' if dns_resolution.rc == 0 else 'FAIL')] }}"
    
    - name: Test 3 - Network Interface Configuration
      block:
        - name: Check if interface has IP
          command: ip addr show eth0
          register: interface_check
        
        - name: Verify IP assignment
          set_fact:
            has_ip: "{{ '192.168.1.' in interface_check.stdout }}"
        
        - name: Record interface test result
          set_fact:
            test_results: "{{ test_results + ['Interface Configuration: ' + ('PASS' if has_ip else 'FAIL')] }}"
    
    - name: Test 4 - Firewall Service Status
      block:
        - name: Check firewalld service
          systemd:
            name: firewalld
          register: firewall_service
        
        - name: Record firewall service test
          set_fact:
            test_results: "{{ test_results + ['Firewall Service: ' + ('PASS' if firewall_service.status.ActiveState == 'active' else 'FAIL')] }}"
    
    - name: Test 5 - Port Accessibility
      block:
        - name: Test SSH port accessibility
          wait_for:
            port: 22
            host: "{{ ansible_host }}"
            timeout: 3
          delegate_to: localhost
          register: ssh_port_test
          ignore_errors: yes
        
        - name: Record port accessibility test
          set_fact:
            test_results: "{{ test_results + ['SSH Port Access: ' + ('PASS' if ssh_port_test is succeeded else 'FAIL')] }}"
    
    - name: Test 6 - Service-Specific Tests for Web Server
      block:
        - name: Check if HTTP port is configured
          command: firewall-cmd --zone=public --query-service=http
          register: http_configured
          ignore_errors: yes
        
        - name: Record HTTP configuration test
          set_fact:
            test_results: "{{ test_results + ['HTTP Service Config: ' + ('PASS' if http_configured.rc == 0 else 'FAIL')] }}"
      when: inventory_hostname == 'web-server'
    
    - name: Test 7 - Service-Specific Tests for Database Server
      block:
        - name: Check if MySQL port is configured
          command: firewall-cmd --zone=public --query-service=mysql
          register: mysql_configured
          ignore_errors: yes
        
        - name: Record MySQL configuration test
          set_fact:
            test_results: "{{ test_results + ['MySQL Service Config: ' + ('PASS' if mysql_configured.rc == 0 else 'FAIL')] }}"
      when: inventory_hostname == 'db-server'
    
    - name: Generate Test Report
      debug:
        msg: |
          =====================================
          NETWORK TESTING REPORT - {{ inventory_hostname }}
          =====================================
          {% for result in test_results %}
          {{ result }}
          {% endfor %}
          =====================================
          Test Completed: {{ ansible_date_time.iso8601 }}
          =====================================
Run the testing suite:
ansible-playbook -i inventory.ini network-testing-suite.yml
Subtask 3.3: Create Network Troubleshooting Playbook
Finally, let's create a troubleshooting playbook that can help diagnose common network issues.

Create the troubleshooting playbook:
vim network-troubleshooting.yml
Add troubleshooting tasks:
---
- name: Network Troubleshooting and Diagnostics
  hosts: all
  become: yes
  
  tasks:
    - name: Collect system information
      setup:
        gather_subset:
          - network
          - hardware
      register: system_facts
    
    - name: Check network service status
      systemd:
        name: "{{ item }}"
      register: service_status
      loop:
        - NetworkManager
        - firewalld
        - systemd-resolved
      ignore_errors: yes
    
    - name: Display service status
      debug:
        msg: "{{ item.item }}: {{ item.status.ActiveState if item.status is defined else 'Not Found' }}"
      loop: "{{ service_status.results }}"
    
    - name: Check routing table
      command: ip route show
      register: routing_table
    
    - name: Display routing information
      debug:
        msg: "{{ routing_table.stdout_lines }}"
    
    - name: Check network statistics
      command: ss -tuln
      register: network_stats
    
    - name: Display listening ports
      debug:
        msg: "{{ network_stats.stdout_lines }}"
    
    - name: Check firewall rules
      command: firewall-cmd --list-all
      register: firewall_rules
    
    - name: Display firewall configuration
      debug:
        msg: "{{ firewall_rules.stdout_lines }}"
    
    - name: Test connectivity to critical services
      uri:
        url: "http://{{ item }}"
        method: GET
        timeout: 5
      loop:
        - "httpbin.org/get"
      register: connectivity_test
      ignore_errors: yes
    
    - name: Generate troubleshooting report
      copy:
        content: |
          Network Troubleshooting Report
          Generated: {{ ansible_date_time.iso8601 }}
          Host: {{ inventory_hostname }}
          
          System Information:
          - OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          - Kernel: {{ ansible_kernel }}
          - Architecture: {{ ansible_architecture }}
          
          Network Configuration:
          - Primary IP: {{ ansible_default_ipv4.address }}
          - Gateway: {{ ansible_default_ipv4.gateway }}
          - Interface: {{ ansible_default_ipv4.interface }}
          - DNS Servers: {{ ansible_dns.nameservers | join(', ') }}
          
          Service Status:
          {% for service in service_status.results %}
          - {{ service.item }}: {{ service.status.ActiveState if service.status is defined else 'Not Found' }}
          {% endfor %}
          
          Firewall Status:
          {{ firewall_rules.stdout }}
          
          Routing Table:
          {{ routing_table.stdout }}
          
        dest: "/tmp/network-report-{{ inventory_hostname }}.txt"
        mode: '0644'
    
    - name: Fetch troubleshooting reports
      fetch:
        src: "/tmp/network-report-{{ inventory_hostname }}.txt"
        dest: "./reports/"
        flat: yes
Execute the troubleshooting playbook:
ansible-playbook -i inventory.ini network-troubleshooting.yml
View the generated reports:
ls -la reports/
cat reports/network-report-web-server.txt
cat reports/network-report-db-server.txt
Common Troubleshooting Tips
Network Configuration Issues
Problem: nmcli commands fail with permission errors Solution: Ensure the playbook runs with become: yes and the user has sudo privileges

Problem: Network changes don't take effect immediately Solution: Add handlers to restart NetworkManager service or use immediate: yes in firewalld tasks

Problem: DNS resolution fails after configuration Solution: Verify DNS servers are correctly set and accessible

Firewall Configuration Issues
Problem: Services become inaccessible after firewall configuration Solution: Check if the required ports/services are allowed in the correct zone

Problem: Firewalld service fails to start Solution: Check system logs with journalctl -u firewalld and ensure no conflicting services

Problem: Rich rules syntax errors Solution: Validate rich rule syntax using firewall-cmd --check-config

Connectivity Testing Issues
Problem: Ping tests fail between hosts Solution: Verify firewall allows ICMP traffic and network routing is correct

Problem: Port connectivity tests timeout Solution: Check if the target service is running and firewall allows the specific port

Conclusion
In this comprehensive lab, you have successfully accomplished the following:

Key Achievements
Network Interface Automation: You learned to use Ansible's nmcli module to automate network interface configuration, including IP address assignment, hostname configuration, and DNS settings.

Firewall Automation: You mastered the firewalld module to create sophisticated firewall rules, including service-based rules, port-based rules, rich rules, and zone-based configurations.

Network Validation: You developed comprehensive testing and validation procedures to ensure network configurations are working correctly and troubleshoot issues when they arise.

Best Practices Implementation: You applied enterprise-level best practices for network automation, including proper error handling, idempotent configurations, and comprehensive logging.

Real-World Applications
The skills you've developed in this lab are directly applicable to:

Enterprise Network Management: Automating network configuration across hundreds or thousands of servers
Cloud Infrastructure: Managing network settings in dynamic cloud environments
Security Compliance: Ensuring consistent firewall configurations across all systems
Disaster Recovery: Quickly restoring network configurations after system failures
DevOps Integration: Incorporating network automation into CI/CD pipelines
RHCE Exam Preparation
This lab specifically prepares you for RHCE exam objectives related to:

Automating system administration tasks using Ansible
Managing network services and configurations
Implementing security policies through automation
Troubleshooting and validating automated configurations
Next Steps
To further enhance your network automation skills:

Explore Advanced Modules: Learn about other Ansible networking modules like uri, get_url, and lineinfile
Integration with Monitoring: Combine network automation with monitoring solutions
Template-Based Configurations: Use Jinja2 templates for more complex network configurations
Role Development: Convert your playbooks into reusable Ansible roles
Testing Frameworks: Implement automated testing using tools like Molecule
The automation techniques you've learned will significantly improve your efficiency in managing network infrastructure and prepare you well for advanced system administration roles and certifications.
