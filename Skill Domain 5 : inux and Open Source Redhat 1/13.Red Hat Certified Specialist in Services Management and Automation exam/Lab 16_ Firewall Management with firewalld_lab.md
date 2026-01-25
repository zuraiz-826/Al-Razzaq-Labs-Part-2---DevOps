Lab 16: Firewall Management with firewalld
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of firewalld and its zone-based architecture
Configure firewalld zones and services using Ansible automation
Create and manage custom firewall rules to control network traffic
Implement security policies through automated firewall configuration
Test and validate firewall configurations to ensure proper functionality
Troubleshoot common firewall issues and verify rule effectiveness
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with network concepts (ports, protocols, IP addresses)
Basic knowledge of Ansible playbooks and YAML syntax
Understanding of SSH connectivity and remote system management
Knowledge of systemd services and service management
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or install software.

Your lab environment includes:

Control Node: CentOS/RHEL 8+ with Ansible pre-installed
Managed Nodes: Two target systems (web server and database server)
Network Configuration: All systems connected in a secure lab network
Pre-installed Tools: firewalld, Ansible, and necessary utilities
Task 1: Configure firewalld Zones and Services using Ansible
Subtask 1.1: Verify Lab Environment and Initial Setup
First, let's verify our lab environment and ensure all systems are accessible.

Connect to your control node and verify Ansible installation:
# Check Ansible version
ansible --version

# Verify connectivity to managed nodes
ansible all -m ping -i inventory
Create the lab directory structure:
# Create main lab directory
mkdir -p ~/firewall-lab
cd ~/firewall-lab

# Create subdirectories for organization
mkdir -p playbooks roles group_vars host_vars
Create the inventory file:
cat > inventory << 'EOF'
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=student

[dbservers]
db1 ansible_host=192.168.1.11 ansible_user=student

[all:vars]
ansible_ssh_private_key_file=~/.ssh/lab_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
Subtask 1.2: Create Firewalld Configuration Playbook
Create the main firewall configuration playbook:
cat > playbooks/firewall-config.yml << 'EOF'
---
- name: Configure Firewalld on Web Servers
  hosts: webservers
  become: yes
  vars:
    web_services:
      - http
      - https
      - ssh
    web_ports:
      - "8080/tcp"
      - "8443/tcp"
  
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

    - name: Set default zone to public
      firewalld:
        zone: public
        state: present
        permanent: yes
        immediate: yes

    - name: Configure web server services in public zone
      firewalld:
        service: "{{ item }}"
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
      loop: "{{ web_services }}"

    - name: Configure custom ports for web applications
      firewalld:
        port: "{{ item }}"
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
      loop: "{{ web_ports }}"

    - name: Create custom zone for internal services
      firewalld:
        zone: internal-web
        state: present
        permanent: yes
        immediate: yes

    - name: Configure internal zone with specific services
      firewalld:
        service: "{{ item }}"
        zone: internal-web
        permanent: yes
        immediate: yes
        state: enabled
      loop:
        - ssh
        - mysql

- name: Configure Firewalld on Database Servers
  hosts: dbservers
  become: yes
  vars:
    db_services:
      - ssh
      - mysql
    trusted_sources:
      - "192.168.1.0/24"
      - "10.0.0.0/8"
  
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

    - name: Create database zone
      firewalld:
        zone: database
        state: present
        permanent: yes
        immediate: yes

    - name: Configure database services
      firewalld:
        service: "{{ item }}"
        zone: database
        permanent: yes
        immediate: yes
        state: enabled
      loop: "{{ db_services }}"

    - name: Add trusted source networks to database zone
      firewalld:
        source: "{{ item }}"
        zone: database
        permanent: yes
        immediate: yes
        state: enabled
      loop: "{{ trusted_sources }}"

    - name: Set interface to database zone
      firewalld:
        interface: eth0
        zone: database
        permanent: yes
        immediate: yes
        state: enabled
EOF
Create a playbook for advanced firewall rules:
cat > playbooks/advanced-firewall-rules.yml << 'EOF'
---
- name: Configure Advanced Firewall Rules
  hosts: all
  become: yes
  
  tasks:
    - name: Create rich rules for specific traffic control
      firewalld:
        rich_rule: 'rule family="ipv4" source address="192.168.1.0/24" service name="ssh" accept'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
      when: inventory_hostname in groups['webservers']

    - name: Block specific IP addresses
      firewalld:
        rich_rule: 'rule family="ipv4" source address="10.0.0.100" drop'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled

    - name: Allow specific port range for application cluster
      firewalld:
        rich_rule: 'rule family="ipv4" source address="192.168.1.0/24" port port="9000-9010" protocol="tcp" accept'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
      when: inventory_hostname in groups['webservers']

    - name: Configure port forwarding for load balancer
      firewalld:
        rich_rule: 'rule family="ipv4" forward-port port="80" protocol="tcp" to-port="8080"'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
      when: inventory_hostname in groups['webservers']
EOF
Subtask 1.3: Execute Firewall Configuration
Run the main firewall configuration playbook:
# Execute the firewall configuration
ansible-playbook -i inventory playbooks/firewall-config.yml -v

# Verify the playbook execution
echo "Checking playbook execution status..."
if [ $? -eq 0 ]; then
    echo "Firewall configuration completed successfully!"
else
    echo "There were issues with the configuration. Check the output above."
fi
Apply advanced firewall rules:
# Execute advanced rules playbook
ansible-playbook -i inventory playbooks/advanced-firewall-rules.yml -v
Task 2: Set up Firewall Rules to Restrict or Allow Traffic
Subtask 2.1: Create Service-Specific Firewall Rules
Create a playbook for web application security:
cat > playbooks/web-security-rules.yml << 'EOF'
---
- name: Configure Web Application Security Rules
  hosts: webservers
  become: yes
  vars:
    allowed_web_ips:
      - "192.168.1.0/24"
      - "172.16.0.0/16"
    blocked_countries:
      - "10.0.0.0/8"  # Example blocked range
  
  tasks:
    - name: Create web-dmz zone for web applications
      firewalld:
        zone: web-dmz
        state: present
        permanent: yes
        immediate: yes

    - name: Configure web-dmz zone with HTTP/HTTPS only
      firewalld:
        service: "{{ item }}"
        zone: web-dmz
        permanent: yes
        immediate: yes
        state: enabled
      loop:
        - http
        - https

    - name: Allow web traffic from specific networks only
      firewalld:
        rich_rule: 'rule family="ipv4" source address="{{ item }}" service name="http" accept'
        zone: web-dmz
        permanent: yes
        immediate: yes
        state: enabled
      loop: "{{ allowed_web_ips }}"

    - name: Allow HTTPS traffic from specific networks only
      firewalld:
        rich_rule: 'rule family="ipv4" source address="{{ item }}" service name="https" accept'
        zone: web-dmz
        permanent: yes
        immediate: yes
        state: enabled
      loop: "{{ allowed_web_ips }}"

    - name: Block suspicious IP ranges
      firewalld:
        rich_rule: 'rule family="ipv4" source address="{{ item }}" drop'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
      loop: "{{ blocked_countries }}"

    - name: Rate limit SSH connections
      firewalld:
        rich_rule: 'rule service name="ssh" accept limit value="3/m"'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled
EOF
Create database security rules:
cat > playbooks/database-security-rules.yml << 'EOF'
---
- name: Configure Database Security Rules
  hosts: dbservers
  become: yes
  vars:
    web_server_ips:
      - "192.168.1.10"
    admin_networks:
      - "192.168.1.0/24"
  
  tasks:
    - name: Create secure-db zone
      firewalld:
        zone: secure-db
        state: present
        permanent: yes
        immediate: yes

    - name: Allow MySQL access only from web servers
      firewalld:
        rich_rule: 'rule family="ipv4" source address="{{ item }}" service name="mysql" accept'
        zone: secure-db
        permanent: yes
        immediate: yes
        state: enabled
      loop: "{{ web_server_ips }}"

    - name: Allow SSH access only from admin networks
      firewalld:
        rich_rule: 'rule family="ipv4" source address="{{ item }}" service name="ssh" accept'
        zone: secure-db
        permanent: yes
        immediate: yes
        state: enabled
      loop: "{{ admin_networks }}"

    - name: Block all other MySQL traffic
      firewalld:
        rich_rule: 'rule service name="mysql" drop'
        zone: public
        permanent: yes
        immediate: yes
        state: enabled

    - name: Configure database backup port access
      firewalld:
        rich_rule: 'rule family="ipv4" source address="192.168.1.0/24" port port="3307" protocol="tcp" accept'
        zone: secure-db
        permanent: yes
        immediate: yes
        state: enabled
EOF
Subtask 2.2: Implement Traffic Logging and Monitoring
Create logging configuration playbook:
cat > playbooks/firewall-logging.yml << 'EOF'
---
- name: Configure Firewall Logging and Monitoring
  hosts: all
  become: yes
  
  tasks:
    - name: Enable firewalld logging
      lineinfile:
        path: /etc/firewalld/firewalld.conf
        regexp: '^LogDenied='
        line: 'LogDenied=all'
        backup: yes
      notify: restart firewalld

    - name: Configure rsyslog for firewall logs
      blockinfile:
        path: /etc/rsyslog.conf
        block: |
          # Firewall logging
          :msg,contains,"FINAL_REJECT" /var/log/firewall-rejected.log
          :msg,contains,"FINAL_ACCEPT" /var/log/firewall-accepted.log
          & stop
        marker: "# {mark} FIREWALL LOGGING BLOCK"
      notify: restart rsyslog

    - name: Create log rotation for firewall logs
      copy:
        content: |
          /var/log/firewall-rejected.log
          /var/log/firewall-accepted.log {
              daily
              rotate 30
              compress
              delaycompress
              missingok
              notifempty
              create 0644 root root
          }
        dest: /etc/logrotate.d/firewall-logs

    - name: Create firewall monitoring script
      copy:
        content: |
          #!/bin/bash
          # Firewall monitoring script
          
          LOG_FILE="/var/log/firewall-monitor.log"
          DATE=$(date '+%Y-%m-%d %H:%M:%S')
          
          # Check firewalld status
          if systemctl is-active --quiet firewalld; then
              echo "[$DATE] Firewalld is running" >> $LOG_FILE
          else
              echo "[$DATE] WARNING: Firewalld is not running!" >> $LOG_FILE
          fi
          
          # Count recent rejected connections
          REJECTED_COUNT=$(grep "$(date '+%b %d %H:')" /var/log/firewall-rejected.log 2>/dev/null | wc -l)
          echo "[$DATE] Rejected connections in last hour: $REJECTED_COUNT" >> $LOG_FILE
          
          # Check for high rejection rates
          if [ $REJECTED_COUNT -gt 100 ]; then
              echo "[$DATE] ALERT: High rejection rate detected!" >> $LOG_FILE
          fi
        dest: /usr/local/bin/firewall-monitor.sh
        mode: '0755'

  handlers:
    - name: restart firewalld
      systemd:
        name: firewalld
        state: restarted

    - name: restart rsyslog
      systemd:
        name: rsyslog
        state: restarted
EOF
Execute the security and logging configurations:
# Apply web security rules
ansible-playbook -i inventory playbooks/web-security-rules.yml -v

# Apply database security rules
ansible-playbook -i inventory playbooks/database-security-rules.yml -v

# Configure logging and monitoring
ansible-playbook -i inventory playbooks/firewall-logging.yml -v
Task 3: Test the Firewall Configuration
Subtask 3.1: Create Comprehensive Testing Framework
Create a firewall testing playbook:
cat > playbooks/firewall-testing.yml << 'EOF'
---
- name: Test Firewall Configuration
  hosts: all
  become: yes
  vars:
    test_results: []
  
  tasks:
    - name: Verify firewalld service status
      systemd:
        name: firewalld
      register: firewalld_status

    - name: Display firewalld status
      debug:
        msg: "Firewalld is {{ firewalld_status.status.ActiveState }}"

    - name: Get current firewall zones
      command: firewall-cmd --get-zones
      register: current_zones
      changed_when: false

    - name: Display configured zones
      debug:
        msg: "Configured zones: {{ current_zones.stdout }}"

    - name: Get default zone
      command: firewall-cmd --get-default-zone
      register: default_zone
      changed_when: false

    - name: Display default zone
      debug:
        msg: "Default zone: {{ default_zone.stdout }}"

    - name: List services in public zone
      command: firewall-cmd --zone=public --list-services
      register: public_services
      changed_when: false

    - name: Display public zone services
      debug:
        msg: "Public zone services: {{ public_services.stdout }}"

    - name: List ports in public zone
      command: firewall-cmd --zone=public --list-ports
      register: public_ports
      changed_when: false

    - name: Display public zone ports
      debug:
        msg: "Public zone ports: {{ public_ports.stdout }}"

    - name: Check rich rules
      command: firewall-cmd --list-rich-rules
      register: rich_rules
      changed_when: false

    - name: Display rich rules
      debug:
        msg: "Rich rules: {{ rich_rules.stdout_lines }}"
EOF
Create network connectivity testing script:
cat > scripts/test-connectivity.sh << 'EOF'
#!/bin/bash

# Network connectivity testing script
echo "=== Firewall Configuration Testing ==="
echo "Date: $(date)"
echo "======================================="

# Test web server connectivity
echo "Testing Web Server Connectivity..."
echo "-----------------------------------"

# Test HTTP access
echo -n "HTTP (port 80): "
if timeout 5 bash -c "</dev/tcp/192.168.1.10/80" 2>/dev/null; then
    echo "ACCESSIBLE"
else
    echo "BLOCKED/UNAVAILABLE"
fi

# Test HTTPS access
echo -n "HTTPS (port 443): "
if timeout 5 bash -c "</dev/tcp/192.168.1.10/443" 2>/dev/null; then
    echo "ACCESSIBLE"
else
    echo "BLOCKED/UNAVAILABLE"
fi

# Test custom web port
echo -n "Custom Web Port (8080): "
if timeout 5 bash -c "</dev/tcp/192.168.1.10/8080" 2>/dev/null; then
    echo "ACCESSIBLE"
else
    echo "BLOCKED/UNAVAILABLE"
fi

# Test SSH access
echo -n "SSH (port 22): "
if timeout 5 bash -c "</dev/tcp/192.168.1.10/22" 2>/dev/null; then
    echo "ACCESSIBLE"
else
    echo "BLOCKED/UNAVAILABLE"
fi

echo ""
echo "Testing Database Server Connectivity..."
echo "--------------------------------------"

# Test MySQL access
echo -n "MySQL (port 3306): "
if timeout 5 bash -c "</dev/tcp/192.168.1.11/3306" 2>/dev/null; then
    echo "ACCESSIBLE"
else
    echo "BLOCKED/UNAVAILABLE"
fi

# Test SSH access to database
echo -n "SSH to Database (port 22): "
if timeout 5 bash -c "</dev/tcp/192.168.1.11/22" 2>/dev/null; then
    echo "ACCESSIBLE"
else
    echo "BLOCKED/UNAVAILABLE"
fi

echo ""
echo "Testing Blocked Connections..."
echo "-----------------------------"

# Test blocked port (should fail)
echo -n "Blocked Port (9999): "
if timeout 5 bash -c "</dev/tcp/192.168.1.10/9999" 2>/dev/null; then
    echo "ACCESSIBLE (UNEXPECTED!)"
else
    echo "BLOCKED (EXPECTED)"
fi

echo ""
echo "=== Testing Complete ==="
EOF

chmod +x scripts/test-connectivity.sh
Subtask 3.2: Execute Comprehensive Testing
Run the firewall testing playbook:
# Execute firewall configuration tests
ansible-playbook -i inventory playbooks/firewall-testing.yml -v
Perform manual connectivity tests:
# Run connectivity testing script
./scripts/test-connectivity.sh

# Test from control node to managed nodes
echo "Testing SSH connectivity to all managed nodes..."
ansible all -i inventory -m ping

# Test specific services
echo "Testing web services..."
ansible webservers -i inventory -m shell -a "curl -I http://localhost:80" --become

echo "Testing database services..."
ansible dbservers -i inventory -m shell -a "systemctl status mysqld" --become
Subtask 3.3: Advanced Testing and Validation
Create advanced testing playbook:
cat > playbooks/advanced-firewall-tests.yml << 'EOF'
---
- name: Advanced Firewall Testing and Validation
  hosts: all
  become: yes
  
  tasks:
    - name: Test firewall rule effectiveness
      block:
        - name: Attempt connection to blocked port
          wait_for:
            host: "{{ ansible_default_ipv4.address }}"
            port: 9999
            timeout: 5
          register: blocked_port_test
          failed_when: false

        - name: Verify blocked port is actually blocked
          assert:
            that:
              - blocked_port_test.failed
            fail_msg: "Port 9999 should be blocked but is accessible"
            success_msg: "Port 9999 is properly blocked"

    - name: Validate zone assignments
      shell: firewall-cmd --get-zone-of-interface={{ ansible_default_ipv4.interface }}
      register: interface_zone
      changed_when: false

    - name: Display interface zone assignment
      debug:
        msg: "Interface {{ ansible_default_ipv4.interface }} is in zone: {{ interface_zone.stdout }}"

    - name: Check for firewall rule conflicts
      shell: |
        firewall-cmd --list-all-zones | grep -A 10 -B 2 "services:"
      register: zone_analysis
      changed_when: false

    - name: Generate firewall configuration report
      copy:
        content: |
          Firewall Configuration Report
          ============================
          Generated: {{ ansible_date_time.iso8601 }}
          Host: {{ inventory_hostname }}
          
          Active Zones:
          {{ current_zones.stdout if current_zones is defined else 'N/A' }}
          
          Default Zone:
          {{ default_zone.stdout if default_zone is defined else 'N/A' }}
          
          Interface Assignments:
          {{ interface_zone.stdout if interface_zone is defined else 'N/A' }}
          
          Rich Rules:
          {% for rule in rich_rules.stdout_lines if rich_rules is defined %}
          {{ rule }}
          {% endfor %}
          
        dest: "/tmp/firewall-report-{{ inventory_hostname }}.txt"

    - name: Fetch firewall reports
      fetch:
        src: "/tmp/firewall-report-{{ inventory_hostname }}.txt"
        dest: "./reports/"
        flat: yes
EOF
Execute advanced testing:
# Create reports directory
mkdir -p reports

# Run advanced testing
ansible-playbook -i inventory playbooks/advanced-firewall-tests.yml -v

# Display collected reports
echo "Generated firewall reports:"
ls -la reports/
Subtask 3.4: Performance and Security Validation
Create performance testing script:
cat > scripts/firewall-performance-test.sh << 'EOF'
#!/bin/bash

echo "=== Firewall Performance Testing ==="
echo "Date: $(date)"
echo "===================================="

# Test firewall rule processing time
echo "Testing firewall rule processing performance..."

# Measure time for rule listing
echo -n "Time to list all rules: "
time firewall-cmd --list-all-zones > /dev/null

# Test connection establishment time
echo "Testing connection establishment times..."

# HTTP connection time
echo -n "HTTP connection time: "
time curl -s -o /dev/null -w "%{time_total}" http://192.168.1.10/ 2>/dev/null
echo " seconds"

# SSH connection time
echo -n "SSH connection time: "
time ssh -o ConnectTimeout=5 -o BatchMode=yes 192.168.1.10 exit 2>/dev/null
echo " seconds"

# Test rule reload time
echo -n "Firewall reload time: "
time firewall-cmd --reload > /dev/null 2>&1
echo ""

echo "=== Performance Testing Complete ==="
EOF

chmod +x scripts/firewall-performance-test.sh
Run performance tests:
# Execute performance testing
./scripts/firewall-performance-test.sh

# Check firewall logs for any issues
echo "Checking recent firewall logs..."
ansible all -i inventory -m shell -a "tail -20 /var/log/messages | grep -i firewall" --become
Troubleshooting Common Issues
Common Problems and Solutions
Firewalld Service Issues:
# Check service status
systemctl status firewalld

# Restart if needed
systemctl restart firewalld

# Check for configuration errors
firewall-cmd --check-config
Zone Configuration Problems:
# List all zones and their configurations
firewall-cmd --list-all-zones

# Reset to default if needed
firewall-cmd --complete-reload
Rich Rule Syntax Errors:
# Test rich rule syntax
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" accept' --timeout=10

# Remove problematic rules
firewall-cmd --remove-rich-rule='problematic-rule'
Connectivity Issues:
# Check if ports are actually open
ss -tlnp | grep :80

# Verify iptables rules
iptables -L -n

# Check for SELinux interference
sealert -a /var/log/audit/audit.log
Conclusion
In this comprehensive lab, you have successfully:

Accomplished Key Objectives:

Automated Firewall Management: Implemented Ansible playbooks to automate firewalld configuration across multiple systems, eliminating manual configuration errors and ensuring consistency.

Zone-Based Security Architecture: Created and configured multiple firewall zones (public, internal-web, database, web-dmz, secure-db) to implement defense-in-depth security strategies.

Service-Specific Rules: Configured granular firewall rules for web servers and database servers, implementing the principle of least privilege by allowing only necessary traffic.

Advanced Traffic Control: Implemented rich rules for sophisticated traffic filtering, including source-based restrictions, port forwarding, and rate limiting.

Comprehensive Testing Framework: Developed automated testing procedures to validate firewall configurations and ensure security policies are properly enforced.

Why This Matters:

Enterprise Security: The skills demonstrated in this lab are critical for enterprise environments where automated, consistent firewall management is essential for maintaining security across large infrastructures.

Compliance Requirements: Many regulatory frameworks require documented and tested firewall configurations, which this lab's approach directly addresses through automation and validation.

Operational Efficiency: By automating firewall management with Ansible, organizations can reduce configuration time, minimize human errors, and ensure rapid deployment of security policies.

Career Advancement: These skills directly align with Red Hat Certified Specialist in Services Management and Automation exam objectives and are highly valued in DevOps and security roles.

Real-World Application: The zone-based approach and rich rule configurations demonstrated here mirror production environments in cloud and on-premises infrastructures.

You now have the practical experience to implement enterprise-grade firewall automation solutions, contributing to more secure and efficiently managed IT infrastructures. The combination of Ansible automation and firewalld's powerful features provides a robust foundation for modern network security management.
