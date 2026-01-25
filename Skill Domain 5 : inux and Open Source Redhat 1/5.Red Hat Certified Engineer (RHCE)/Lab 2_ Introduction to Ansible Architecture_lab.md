Lab 2: Introduction to Ansible Architecture
Objectives
By the end of this lab, students will be able to:

• Understand the core components of Ansible architecture including control nodes, managed nodes, inventory, and modules • Successfully install Ansible on a Linux system using package managers • Create and configure Ansible inventory files to manage target hosts • Execute ad-hoc Ansible commands to perform system administration tasks • Differentiate between Ansible's agentless architecture and traditional configuration management tools • Demonstrate practical knowledge of Ansible's push-based model for automation

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with SSH concepts and key-based authentication • Knowledge of YAML syntax fundamentals • Understanding of basic networking concepts (IP addresses, hostnames) • Experience with text editors like vim, nano, or gedit • Basic system administration knowledge

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes: • One control node (where Ansible will be installed) • Access to localhost for testing Ansible commands • Pre-configured SSH access between systems • All necessary network connectivity established

Task 1: Install Ansible on the System
Subtask 1.1: Update System Packages
First, ensure your system has the latest package information.

sudo apt update
For RHEL/CentOS systems:

sudo yum update -y
Subtask 1.2: Install Ansible Using Package Manager
Install Ansible using the system's package manager.

For Ubuntu/Debian systems:

sudo apt install ansible -y
For RHEL/CentOS systems:

sudo yum install epel-release -y
sudo yum install ansible -y
Subtask 1.3: Verify Ansible Installation
Confirm that Ansible has been installed successfully by checking the version.

ansible --version
Expected output should show Ansible version information, Python version, and configuration file location:

ansible [core 2.12.x]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/user/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/dist-packages/ansible
  ansible collection location = /home/user/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.x.x
Subtask 1.4: Understand Ansible Architecture Components
Control Node: The machine where Ansible is installed and from which automation is executed. This is your current system.

Managed Nodes: Target systems that Ansible manages. These can be servers, network devices, or cloud instances.

Inventory: A file that defines the managed nodes and organizes them into groups.

Modules: Units of code that Ansible executes on managed nodes to perform specific tasks.

Playbooks: YAML files containing a series of tasks to be executed on managed nodes.

Task 2: Configure Ansible Inventory File
Subtask 2.1: Create a Custom Inventory Directory
Create a dedicated directory for your Ansible configuration files.

mkdir -p ~/ansible-lab
cd ~/ansible-lab
Subtask 2.2: Create a Basic Inventory File
Create an inventory file that defines your managed hosts.

nano inventory.ini
Add the following content to define localhost and any additional hosts:

# Ansible Inventory File
# Local machine group
[local]
localhost ansible_connection=local

# Web servers group (example)
[webservers]
web1 ansible_host=127.0.0.1 ansible_user=ubuntu
web2 ansible_host=127.0.0.1 ansible_user=ubuntu

# Database servers group (example)
[databases]
db1 ansible_host=127.0.0.1 ansible_user=ubuntu

# All servers group
[all_servers:children]
webservers
databases
Save and exit the file (Ctrl+X, then Y, then Enter in nano).

Subtask 2.3: Create an Alternative YAML Inventory
Ansible also supports YAML format for inventory files. Create a YAML version:

nano inventory.yml
Add the following YAML content:

---
all:
  children:
    local:
      hosts:
        localhost:
          ansible_connection: local
    webservers:
      hosts:
        web1:
          ansible_host: 127.0.0.1
          ansible_user: ubuntu
        web2:
          ansible_host: 127.0.0.1
          ansible_user: ubuntu
    databases:
      hosts:
        db1:
          ansible_host: 127.0.0.1
          ansible_user: ubuntu
Subtask 2.4: Test Inventory Configuration
Verify that Ansible can read your inventory file correctly.

ansible-inventory -i inventory.ini --list
This command should display your inventory in JSON format, showing all hosts and groups.

To see a more readable graph format:

ansible-inventory -i inventory.ini --graph
Expected output:

@all:
  |--@databases:
  |  |--db1
  |--@local:
  |  |--localhost
  |--@ungrouped:
  |--@webservers:
  |  |--web1
  |  |--web2
Task 3: Use Ansible Commands to Run Ad-hoc Tasks
Subtask 3.1: Test Basic Connectivity
Test if Ansible can connect to the localhost using the ping module.

ansible -i inventory.ini localhost -m ping
Expected output:

localhost | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
Subtask 3.2: Gather System Information
Use the setup module to gather detailed information about the system.

ansible -i inventory.ini localhost -m setup
This command will display extensive system information including: • Operating system details • Hardware information • Network configuration • Environment variables

To filter specific information, use the filter parameter:

ansible -i inventory.ini localhost -m setup -a "filter=ansible_os_family"
Subtask 3.3: Execute Shell Commands
Run shell commands on the target system using the shell module.

ansible -i inventory.ini localhost -m shell -a "uptime"
Check disk usage:

ansible -i inventory.ini localhost -m shell -a "df -h"
List running processes:

ansible -i inventory.ini localhost -m shell -a "ps aux | head -10"
Subtask 3.4: File Operations
Create a file using the file module:

ansible -i inventory.ini localhost -m file -a "path=/tmp/ansible-test.txt state=touch"
Check if the file was created:

ansible -i inventory.ini localhost -m shell -a "ls -la /tmp/ansible-test.txt"
Create a directory:

ansible -i inventory.ini localhost -m file -a "path=/tmp/ansible-lab-dir state=directory mode=0755"
Subtask 3.5: Copy Files
Create a sample file to copy:

echo "This is a test file for Ansible lab" > ~/test-file.txt
Copy the file using Ansible:

ansible -i inventory.ini localhost -m copy -a "src=~/test-file.txt dest=/tmp/copied-file.txt"
Verify the copy operation:

ansible -i inventory.ini localhost -m shell -a "cat /tmp/copied-file.txt"
Subtask 3.6: Package Management
Check if a package is installed (using apt module for Ubuntu/Debian):

ansible -i inventory.ini localhost -m apt -a "name=curl state=present" --become
Note: The --become flag is used to run the command with elevated privileges (sudo).

For RHEL/CentOS systems, use the yum module:

ansible -i inventory.ini localhost -m yum -a "name=curl state=present" --become
Subtask 3.7: Service Management
Check the status of a service:

ansible -i inventory.ini localhost -m service -a "name=ssh" --become
Subtask 3.8: Working with Multiple Hosts
Test commands against multiple hosts or groups:

ansible -i inventory.ini webservers -m ping
Run a command on all hosts in the inventory:

ansible -i inventory.ini all -m shell -a "hostname"
Subtask 3.9: Using Variables in Ad-hoc Commands
You can pass variables to ad-hoc commands using the -e flag:

ansible -i inventory.ini localhost -m shell -a "echo 'Hello {{ username }}'" -e "username=AnsibleUser"
Advanced Ad-hoc Command Examples
Working with JSON Output
Format output as JSON for better readability:

ansible -i inventory.ini localhost -m setup -a "filter=ansible_distribution*" | python3 -m json.tool
Using Different Connection Types
Test different connection methods:

ansible -i inventory.ini localhost -m ping -c local
Limiting Execution
Limit execution to specific hosts using patterns:

ansible -i inventory.ini "web*" -m ping
Troubleshooting Common Issues
Issue 1: Permission Denied Errors
If you encounter permission denied errors, ensure you're using the --become flag for operations requiring elevated privileges:

ansible -i inventory.ini localhost -m apt -a "name=htop state=present" --become
Issue 2: SSH Connection Issues
For remote hosts, ensure SSH key-based authentication is configured:

ssh-keygen -t rsa -b 2048
ssh-copy-id user@remote-host
Issue 3: Inventory File Not Found
Always specify the inventory file path explicitly:

ansible -i /full/path/to/inventory.ini localhost -m ping
Issue 4: Module Not Found
Ensure you're using the correct module name. List available modules:

ansible-doc -l | grep -i module_name
Best Practices for Ansible Ad-hoc Commands
• Use specific inventory files rather than the default /etc/ansible/hosts • Test connectivity first with the ping module before running complex commands • Use the --check flag to perform dry runs of potentially destructive operations • Leverage host patterns to target specific groups or hosts efficiently • Use variables to make commands more flexible and reusable • Always use --become for operations requiring elevated privileges • Keep inventory files organized with meaningful group names and host variables

Conclusion
In this lab, you have successfully:

• Installed Ansible on a Linux system and verified the installation • Created and configured inventory files in both INI and YAML formats to organize managed hosts • Executed various ad-hoc Ansible commands to perform system administration tasks including connectivity testing, file operations, package management, and service control • Understood Ansible's architecture including the roles of control nodes, managed nodes, inventory, and modules • Gained hands-on experience with Ansible's agentless, push-based automation model

This foundational knowledge of Ansible architecture and basic operations prepares you for more advanced automation tasks using playbooks and roles. The skills learned here are essential for the Red Hat Certified Engineer (RHCE) certification and real-world infrastructure automation scenarios.

Ansible's simplicity and power make it an invaluable tool for system administrators and DevOps engineers. The agentless architecture you've explored eliminates the need for additional software on managed nodes, while the human-readable YAML syntax makes automation accessible to teams with varying technical backgrounds.

Continue practicing these concepts and explore Ansible's extensive module library to automate more complex infrastructure management tasks.
