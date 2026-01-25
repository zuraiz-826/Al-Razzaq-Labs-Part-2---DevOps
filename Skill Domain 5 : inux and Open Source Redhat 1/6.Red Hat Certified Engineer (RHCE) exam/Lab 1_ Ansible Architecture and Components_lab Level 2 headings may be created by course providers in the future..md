Lab 1: Ansible Architecture and Components
Objectives
By the end of this lab, students will be able to:

Understand Ansible's core architecture including inventory, modules, playbooks, and roles
Install and configure Ansible on a Linux system
Create and configure basic inventory files for host management
Execute ad-hoc commands to perform remote system administration tasks
Demonstrate practical knowledge of Ansible fundamentals required for RHCE certification
Prerequisites
Before starting this lab, students should have:

Basic Linux command-line knowledge
Understanding of SSH concepts and key-based authentication
Familiarity with YAML syntax basics
Knowledge of basic system administration concepts
Access to multiple Linux systems for testing (provided by Al Nafi cloud environment)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or configure complex networking.

Your lab environment includes:

Control Node: CentOS/RHEL 8 system with Ansible to be installed
Managed Nodes: 2-3 additional Linux systems to manage with Ansible
Pre-configured SSH connectivity between systems
Task 1: Install Ansible on a Linux System
Subtask 1.1: Prepare the System
First, ensure your control node system is updated and ready for Ansible installation.

# Update the system packages
sudo dnf update -y

# Install required dependencies
sudo dnf install -y python3 python3-pip curl wget
Subtask 1.2: Install Ansible Using Package Manager
Install Ansible using the system package manager for the most stable installation.

# Install EPEL repository (if not already available)
sudo dnf install -y epel-release

# Install Ansible
sudo dnf install -y ansible

# Verify installation
ansible --version
Expected output should show Ansible version information similar to:

ansible [core 2.14.x]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/user/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.9/site-packages/ansible
  ansible collection location = /home/user/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.9.x
Subtask 1.3: Alternative Installation Using pip
If package manager installation is not available, use pip as an alternative:

# Install Ansible using pip3
pip3 install --user ansible

# Add pip installation path to PATH
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
source ~/.bashrc

# Verify installation
ansible --version
Subtask 1.4: Configure Ansible Basic Settings
Create a basic Ansible configuration file:

# Create ansible configuration directory
mkdir -p ~/.ansible

# Create basic ansible.cfg file
cat > ~/.ansible.cfg << 'EOF'
[defaults]
inventory = ~/ansible/inventory
host_key_checking = False
remote_user = ansible
private_key_file = ~/.ssh/id_rsa

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOF
Task 2: Set Up a Basic Inventory File
Subtask 2.1: Create Ansible Working Directory
Organize your Ansible files in a dedicated directory structure:

# Create main ansible directory
mkdir -p ~/ansible/{inventories,playbooks,roles,group_vars,host_vars}

# Navigate to ansible directory
cd ~/ansible
Subtask 2.2: Create Basic Inventory File
Create a simple inventory file with your managed hosts:

# Create basic inventory file
cat > ~/ansible/inventory << 'EOF'
# Ansible Inventory File
# Web servers group
[webservers]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

# Database servers group
[databases]
db1 ansible_host=192.168.1.20

# All servers group variables
[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_become=yes
ansible_become_method=sudo
EOF
Note: Replace the IP addresses with the actual IP addresses of your managed nodes provided in the Al Nafi lab environment.

Subtask 2.3: Create Advanced Inventory with Groups
Create a more sophisticated inventory structure:

# Create advanced inventory file
cat > ~/ansible/inventories/production << 'EOF'
# Production Environment Inventory

[webservers]
web1 ansible_host=192.168.1.10 http_port=80
web2 ansible_host=192.168.1.11 http_port=8080

[databases]
db1 ansible_host=192.168.1.20 mysql_port=3306

[loadbalancers]
lb1 ansible_host=192.168.1.30

# Group of groups
[frontend:children]
webservers
loadbalancers

[backend:children]
databases

# Group variables
[webservers:vars]
server_type=web
environment=production

[databases:vars]
server_type=database
environment=production

# Global variables
[all:vars]
ansible_user=ansible
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
Subtask 2.4: Verify Inventory Configuration
Test your inventory configuration:

# List all hosts in inventory
ansible all --list-hosts -i ~/ansible/inventory

# List hosts in specific groups
ansible webservers --list-hosts -i ~/ansible/inventory

# Display inventory in JSON format
ansible-inventory --list -i ~/ansible/inventory
Task 3: Run Ad-hoc Commands to Manage Remote Hosts
Subtask 3.1: Test Basic Connectivity
Verify that Ansible can connect to your managed hosts:

# Test connectivity to all hosts
ansible all -m ping -i ~/ansible/inventory

# Test connectivity to specific group
ansible webservers -m ping -i ~/ansible/inventory
Expected successful output:

web1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
Subtask 3.2: Gather System Information
Use ad-hoc commands to collect system information:

# Gather all facts about hosts
ansible all -m setup -i ~/ansible/inventory

# Gather specific facts
ansible all -m setup -a "filter=ansible_os_family" -i ~/ansible/inventory

# Get disk usage information
ansible all -m shell -a "df -h" -i ~/ansible/inventory

# Check system uptime
ansible all -m command -a "uptime" -i ~/ansible/inventory
Subtask 3.3: Perform System Administration Tasks
Execute common system administration commands:

# Check if a service is running
ansible all -m service -a "name=sshd state=started" -i ~/ansible/inventory

# Install a package
ansible webservers -m dnf -a "name=httpd state=present" -i ~/ansible/inventory

# Create a user
ansible all -m user -a "name=testuser state=present" -i ~/ansible/inventory

# Copy a file to remote hosts
echo "Hello from Ansible" > /tmp/test.txt
ansible all -m copy -a "src=/tmp/test.txt dest=/tmp/ansible-test.txt" -i ~/ansible/inventory

# Set file permissions
ansible all -m file -a "path=/tmp/ansible-test.txt mode=0644 owner=testuser" -i ~/ansible/inventory
Subtask 3.4: Advanced Ad-hoc Commands
Perform more complex administrative tasks:

# Create a directory structure
ansible all -m file -a "path=/opt/myapp state=directory mode=0755" -i ~/ansible/inventory

# Download a file from the internet
ansible webservers -m get_url -a "url=https://httpd.apache.org/download.cgi dest=/tmp/apache-info.html" -i ~/ansible/inventory

# Execute a script on remote hosts
cat > /tmp/system-info.sh << 'EOF'
#!/bin/bash
echo "System Information:"
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "Memory: $(free -h | grep Mem)"
echo "Disk: $(df -h / | tail -1)"
EOF

chmod +x /tmp/system-info.sh
ansible all -m copy -a "src=/tmp/system-info.sh dest=/tmp/system-info.sh mode=0755" -i ~/ansible/inventory
ansible all -m shell -a "/tmp/system-info.sh" -i ~/ansible/inventory
Subtask 3.5: Working with Variables in Ad-hoc Commands
Use variables and facts in your ad-hoc commands:

# Use host variables
ansible webservers -m debug -a "var=http_port" -i ~/ansible/inventories/production

# Use gathered facts
ansible all -m debug -a "var=ansible_hostname" -i ~/ansible/inventory

# Set and use variables
ansible all -m set_fact -a "custom_message='Hello from {{ ansible_hostname }}'" -i ~/ansible/inventory
ansible all -m debug -a "var=custom_message" -i ~/ansible/inventory
Understanding Ansible Architecture Components
Inventory Deep Dive
The inventory is Ansible's way of organizing and defining the hosts you want to manage. Key concepts include:

Static Inventory: Text files listing hosts and groups
Dynamic Inventory: Scripts that generate host lists from external sources
Host Variables: Specific settings for individual hosts
Group Variables: Settings applied to all hosts in a group
Group of Groups: Organizing groups hierarchically
Modules Overview
Modules are the units of work in Ansible. Common modules used in this lab:

ping: Test connectivity
setup: Gather system facts
command/shell: Execute commands
copy: Copy files to remote hosts
file: Manage file properties
service: Manage system services
dnf/yum: Package management
user: User account management
Playbooks Introduction
While this lab focuses on ad-hoc commands, playbooks are YAML files that define a series of tasks to be executed. They provide:

Repeatable automation
Complex logic and conditionals
Error handling
Task organization
Roles Concept
Roles are a way to organize playbooks and related files in a standardized directory structure, promoting reusability and sharing.

Troubleshooting Common Issues
SSH Connection Problems
If you encounter SSH connection issues:

# Test SSH connectivity manually
ssh ansible@192.168.1.10

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Verify SSH agent
ssh-add ~/.ssh/id_rsa
Permission Denied Errors
For sudo permission issues:

# Test sudo access manually
ssh ansible@192.168.1.10 'sudo whoami'

# Add user to sudoers (on managed host)
echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible
Module Not Found Errors
If modules are not found:

# Check Ansible installation
ansible-doc -l | grep -i module_name

# Update Ansible if needed
sudo dnf update ansible
Inventory Parsing Issues
For inventory problems:

# Validate inventory syntax
ansible-inventory --list -i ~/ansible/inventory

# Check for YAML syntax errors
python3 -c "import yaml; yaml.safe_load(open('inventory'))"
Verification and Testing
Comprehensive System Check
Run this comprehensive check to verify your Ansible setup:

#!/bin/bash
# Ansible Lab Verification Script

echo "=== Ansible Installation Check ==="
ansible --version

echo -e "\n=== Inventory Validation ==="
ansible-inventory --list -i ~/ansible/inventory

echo -e "\n=== Connectivity Test ==="
ansible all -m ping -i ~/ansible/inventory

echo -e "\n=== System Information Gathering ==="
ansible all -m setup -a "filter=ansible_distribution*" -i ~/ansible/inventory

echo -e "\n=== Service Management Test ==="
ansible all -m service -a "name=sshd" -i ~/ansible/inventory

echo "=== Lab Verification Complete ==="
Save this as verify-lab.sh, make it executable, and run it:

chmod +x verify-lab.sh
./verify-lab.sh
Conclusion
In this lab, you have successfully:

Installed Ansible on a Linux control node using both package manager and pip methods
Created and configured inventory files with both simple and advanced group structures
Executed ad-hoc commands to perform various system administration tasks including connectivity testing, information gathering, package management, and file operations
Understood Ansible's core architecture including the roles of inventory, modules, and the relationship between control and managed nodes
Why This Matters
Ansible's agentless architecture and simple YAML-based configuration make it an essential tool for:

Infrastructure Automation: Automating repetitive system administration tasks
Configuration Management: Ensuring consistent system configurations across environments
Application Deployment: Streamlining application rollouts and updates
Compliance Management: Maintaining security and compliance standards
Next Steps
With this foundation, you are prepared to:

Create more complex playbooks for multi-step automation
Develop custom roles for reusable automation components
Implement advanced inventory management with dynamic sources
Explore Ansible Galaxy for community-contributed roles and collections
This lab provides the essential knowledge required for the Red Hat Certified Engineer (RHCE) exam, specifically covering Ansible fundamentals, inventory management, and ad-hoc command execution. The hands-on experience gained here forms the foundation for more advanced Ansible automation scenarios.
