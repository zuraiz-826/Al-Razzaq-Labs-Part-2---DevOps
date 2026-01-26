Lab 6: Configure Automation Content Navigator
Objectives
By the end of this lab, students will be able to:

• Install and configure Automation Content Navigator (ansible-navigator) on a Linux system • Configure ansible-navigator to interact with Ansible Automation Platform/Controller • Establish secure connections between ansible-navigator and Ansible Tower/Controller • Test integration capabilities with existing Ansible playbooks • Navigate and manage automation content using the navigator interface • Troubleshoot common connectivity and configuration issues

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Ansible concepts (playbooks, inventory, modules) • Familiarity with Linux command line operations • Knowledge of YAML syntax and structure • Understanding of container technologies (Podman/Docker) • Basic networking concepts (HTTP/HTTPS, API endpoints) • Previous experience with Ansible Automation Platform or Tower

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes: • CentOS/RHEL 8 or 9 based system • Python 3.8+ pre-installed • Network connectivity to external repositories • Sudo privileges for package installation

Task 1: Install and Configure Automation Content Navigator
Subtask 1.1: Prepare the System Environment
First, let's ensure our system is ready for ansible-navigator installation.

Update the system packages:
sudo dnf update -y
Install required dependencies:
sudo dnf install -y python3-pip podman git curl
Verify Python version:
python3 --version
Expected output: Python 3.8.x or higher

Start and enable Podman service:
sudo systemctl enable --now podman
Subtask 1.2: Install Ansible Navigator
Install ansible-navigator using pip:
pip3 install --user ansible-navigator
Add pip user bin to PATH (if not already added):
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
Verify installation:
ansible-navigator --version
Install additional Ansible collections:
ansible-navigator collections install community.general ansible.posix
Subtask 1.3: Create Navigator Configuration
Create configuration directory:
mkdir -p ~/.ansible-navigator
Create the main configuration file:
cat > ~/.ansible-navigator/ansible-navigator.yml << 'EOF'
---
ansible-navigator:
  ansible:
    inventory:
      entries:
        - /home/student/inventory
    playbook: /home/student/playbooks
  
  execution-environment:
    enabled: true
    image: quay.io/ansible/ansible-runner:latest
    pull:
      policy: missing
    
  logging:
    level: debug
    append: true
    file: /tmp/navigator.log
  
  playbook-artifact:
    enable: true
    replay: /tmp/playbook-artifacts
    save-as: /tmp/playbook-artifacts/{playbook_name}-{time_stamp}.json
EOF
Create a basic inventory file:
mkdir -p ~/inventory ~/playbooks
cat > ~/inventory/hosts << 'EOF'
[local]
localhost ansible_connection=local

[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com
EOF
Task 2: Link to Ansible Tower/Controller
Subtask 2.1: Configure Controller Connection
Create controller configuration file:
cat > ~/.ansible-navigator/controller-config.yml << 'EOF'
---
controller:
  host: https://your-controller.example.com
  username: admin
  password: your-password
  verify_ssl: false
  
# Alternative: Use token-based authentication
# token: your-api-token
EOF
Set secure permissions on configuration file:
chmod 600 ~/.ansible-navigator/controller-config.yml
Update main navigator configuration to include controller settings:
cat >> ~/.ansible-navigator/ansible-navigator.yml << 'EOF'

  ansible-runner:
    artifact-dir: /tmp/artifacts
    rotate-artifacts: 10
    
  mode: stdout
  
  # Controller integration settings
  settings:
    effective: true
    sources: true
EOF
Subtask 2.2: Test Controller Connectivity
Create a test script to verify controller connection:
cat > ~/test-controller-connection.py << 'EOF'
#!/usr/bin/env python3

import requests
import json
import urllib3
from urllib3.exceptions import InsecureRequestWarning

# Disable SSL warnings for testing
urllib3.disable_warnings(InsecureRequestWarning)

# Controller configuration
CONTROLLER_HOST = "https://your-controller.example.com"
USERNAME = "admin"
PASSWORD = "your-password"

def test_controller_connection():
    """Test basic connectivity to Ansible Controller"""
    
    try:
        # Test basic connectivity
        auth_url = f"{CONTROLLER_HOST}/api/v2/me/"
        
        response = requests.get(
            auth_url,
            auth=(USERNAME, PASSWORD),
            verify=False,
            timeout=10
        )
        
        if response.status_code == 200:
            user_info = response.json()
            print(f"✓ Successfully connected to controller")
            print(f"✓ Authenticated as: {user_info.get('username')}")
            return True
        else:
            print(f"✗ Connection failed with status: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"✗ Connection error: {str(e)}")
        return False

if __name__ == "__main__":
    print("Testing Ansible Controller connectivity...")
    test_controller_connection()
EOF
Make the script executable and run it:
chmod +x ~/test-controller-connection.py
python3 ~/test-controller-connection.py
Subtask 2.3: Configure Navigator for Controller Integration
Create an enhanced navigator configuration with controller integration:
cat > ~/.ansible-navigator/ansible-navigator.yml << 'EOF'
---
ansible-navigator:
  ansible:
    inventory:
      entries:
        - /home/student/inventory
    playbook: /home/student/playbooks
    
  execution-environment:
    enabled: true
    image: quay.io/ansible/ansible-runner:latest
    pull:
      policy: missing
    environment-variables:
      set:
        CONTROLLER_HOST: https://your-controller.example.com
        CONTROLLER_USERNAME: admin
        CONTROLLER_VERIFY_SSL: "false"
    
  logging:
    level: info
    append: true
    file: /tmp/navigator.log
  
  playbook-artifact:
    enable: true
    replay: /tmp/playbook-artifacts
    save-as: /tmp/playbook-artifacts/{playbook_name}-{time_stamp}.json
    
  mode: interactive
  
  settings:
    effective: true
    sources: true
EOF
Task 3: Test Integration with Existing Playbooks
Subtask 3.1: Create Test Playbooks
Create a simple test playbook:
cat > ~/playbooks/test-integration.yml << 'EOF'
---
- name: Test Ansible Navigator Integration
  hosts: localhost
  gather_facts: yes
  connection: local
  
  vars:
    test_message: "Navigator integration test successful"
    
  tasks:
    - name: Display system information
      debug:
        msg: |
          Hostname: {{ ansible_hostname }}
          OS Family: {{ ansible_os_family }}
          Python Version: {{ ansible_python_version }}
          
    - name: Create test directory
      file:
        path: /tmp/navigator-test
        state: directory
        mode: '0755'
        
    - name: Write test file
      copy:
        content: |
          {{ test_message }}
          Timestamp: {{ ansible_date_time.iso8601 }}
          Executed by: {{ ansible_user_id }}
        dest: /tmp/navigator-test/integration-test.txt
        mode: '0644'
        
    - name: Verify file creation
      stat:
        path: /tmp/navigator-test/integration-test.txt
      register: test_file
      
    - name: Display test results
      debug:
        msg: "Test file created successfully: {{ test_file.stat.exists }}"
EOF
Create a more complex playbook for advanced testing:
cat > ~/playbooks/advanced-test.yml << 'EOF'
---
- name: Advanced Navigator Integration Test
  hosts: localhost
  gather_facts: yes
  connection: local
  
  vars:
    services_to_check:
      - sshd
      - chronyd
    test_packages:
      - curl
      - wget
      
  tasks:
    - name: Check system services
      service_facts:
      
    - name: Display running services
      debug:
        msg: "Service {{ item }} is {{ ansible_facts.services[item + '.service'].state | default('not found') }}"
      loop: "{{ services_to_check }}"
      when: ansible_facts.services[item + '.service'] is defined
      
    - name: Check installed packages
      package_facts:
        manager: auto
        
    - name: Verify test packages
      debug:
        msg: "Package {{ item }} is {{ 'installed' if item in ansible_facts.packages else 'not installed' }}"
      loop: "{{ test_packages }}"
      
    - name: Create comprehensive test report
      template:
        src: test-report.j2
        dest: /tmp/navigator-test/test-report.txt
      vars:
        report_data:
          hostname: "{{ ansible_hostname }}"
          os_info: "{{ ansible_distribution }} {{ ansible_distribution_version }}"
          memory_mb: "{{ ansible_memtotal_mb }}"
          cpu_count: "{{ ansible_processor_vcpus }}"
EOF
Create the template file:
mkdir -p ~/playbooks/templates
cat > ~/playbooks/templates/test-report.j2 << 'EOF'
Ansible Navigator Integration Test Report
=========================================

System Information:
- Hostname: {{ report_data.hostname }}
- Operating System: {{ report_data.os_info }}
- Memory (MB): {{ report_data.memory_mb }}
- CPU Cores: {{ report_data.cpu_count }}

Test Execution:
- Date: {{ ansible_date_time.date }}
- Time: {{ ansible_date_time.time }}
- User: {{ ansible_user_id }}

Navigator Configuration:
- Execution Environment: Enabled
- Artifact Collection: Enabled
- Logging: Enabled

Test Status: PASSED
EOF
Subtask 3.2: Execute Playbooks with Navigator
Run the basic test playbook:
ansible-navigator run ~/playbooks/test-integration.yml
Run playbook with verbose output:
ansible-navigator run ~/playbooks/test-integration.yml --mode stdout -v
Execute the advanced test playbook:
ansible-navigator run ~/playbooks/advanced-test.yml --mode stdout
Run playbook with artifact collection:
ansible-navigator run ~/playbooks/advanced-test.yml --artifact-dir /tmp/test-artifacts
Subtask 3.3: Explore Navigator Interactive Mode
Launch navigator in interactive mode:
ansible-navigator
Navigate through the interface using these commands:

Type :help to see available commands
Type :inventory to explore inventory
Type :collections to view installed collections
Type :config to examine configuration
Type :quit to exit
Run a playbook interactively:

ansible-navigator run ~/playbooks/test-integration.yml --mode interactive
Subtask 3.4: Verify Integration Results
Check created test files:
ls -la /tmp/navigator-test/
cat /tmp/navigator-test/integration-test.txt
Review navigator logs:
tail -f /tmp/navigator.log
Examine playbook artifacts:
ls -la /tmp/playbook-artifacts/
View artifact content (if artifacts were created):
find /tmp -name "*.json" -path "*/playbook-artifacts/*" -exec echo "=== {} ===" \; -exec head -20 {} \;
Advanced Configuration and Troubleshooting
Common Issues and Solutions
Issue 1: Container/Podman connectivity problems

# Check podman status
systemctl --user status podman

# Test container connectivity
podman run --rm quay.io/ansible/ansible-runner:latest ansible --version
Issue 2: Navigator configuration not loading

# Verify configuration file syntax
ansible-navigator settings --effective

# Check configuration sources
ansible-navigator settings --sources
Issue 3: Controller authentication failures

# Test API connectivity manually
curl -k -u admin:password https://your-controller.example.com/api/v2/ping/

# Verify SSL certificate issues
openssl s_client -connect your-controller.example.com:443 -servername your-controller.example.com
Performance Optimization
Configure container image caching:
cat >> ~/.ansible-navigator/ansible-navigator.yml << 'EOF'

  execution-environment:
    container-engine: podman
    enabled: true
    image: quay.io/ansible/ansible-runner:latest
    pull:
      policy: missing
    volume-mounts:
      - src: /tmp
        dest: /tmp
        options: rw
EOF
Enable parallel execution:
export ANSIBLE_FORKS=10
ansible-navigator run ~/playbooks/advanced-test.yml --forks 10
Conclusion
In this lab, you have successfully:

• Installed and configured Automation Content Navigator - You now have a powerful tool for managing and executing Ansible automation content with enhanced visualization and debugging capabilities.

• Established integration with Ansible Controller - You've learned how to connect ansible-navigator to Ansible Automation Platform, enabling centralized management and execution of automation workflows.

• Tested playbook integration - You've verified that existing playbooks work seamlessly with navigator, and explored both interactive and command-line execution modes.

• Explored advanced features - You've gained hands-on experience with artifact collection, logging, and troubleshooting techniques that are essential for production environments.

Why This Matters: Automation Content Navigator represents the next generation of Ansible tooling, providing developers and operators with enhanced visibility into automation execution, better debugging capabilities, and seamless integration with containerized execution environments. These skills are crucial for organizations adopting modern Ansible practices and preparing for Red Hat Certified Specialist in Ansible Network Automation certification.

The integration capabilities you've learned enable teams to maintain consistency between development and production environments while leveraging the full power of Ansible Automation Platform's centralized management features.
