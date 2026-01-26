Lab 7: Build Static Ansible Inventories
Objectives
By the end of this lab, you will be able to:

Understand the purpose and structure of Ansible static inventories
Create a static inventory file using YAML format
Define hosts and organize them into logical groups
Configure host-specific variables and group variables
Test and validate your static inventory using Ansible commands
Troubleshoot common inventory configuration issues
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and formatting
Knowledge of SSH key-based authentication
Understanding of basic networking concepts (IP addresses, hostnames)
Ansible installed on your control node (version 2.9 or later)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machines or install additional software.

Your lab environment includes:

1 Ansible control node (where you'll run commands)
3 managed nodes (target hosts for inventory)
Pre-configured SSH keys for passwordless authentication
Ansible already installed and ready to use
Task 1: Understanding Ansible Inventories
Subtask 1.1: Explore the Default Inventory Location
First, let's understand where Ansible looks for inventory files by default.

Connect to your Ansible control node
Check the default inventory location:
ansible --version
View the current Ansible configuration:
ansible-config dump | grep DEFAULT_HOST_LIST
Create a working directory for this lab:
mkdir -p ~/ansible-lab7
cd ~/ansible-lab7
Subtask 1.2: Examine Your Lab Environment
Let's identify the managed nodes available in your environment.

List the available hosts by checking the /etc/hosts file:
cat /etc/hosts
Test connectivity to each managed node:
ping -c 2 node1
ping -c 2 node2
ping -c 2 node3
Verify SSH connectivity:
ssh node1 "hostname && whoami"
ssh node2 "hostname && whoami"
ssh node3 "hostname && whoami"
Task 2: Create a Basic Static Inventory in YAML Format
Subtask 2.1: Create Your First YAML Inventory File
Now we'll create a static inventory file using YAML format, which is more readable and flexible than the traditional INI format.

Create a new inventory file:
nano inventory.yml
Add the following basic inventory structure:
---
all:
  hosts:
    node1:
      ansible_host: node1
      ansible_user: student
    node2:
      ansible_host: node2
      ansible_user: student
    node3:
      ansible_host: node3
      ansible_user: student
Save and exit the file (Ctrl+X, then Y, then Enter)
Subtask 2.2: Test the Basic Inventory
Let's verify that our inventory file is correctly formatted and accessible.

Test the inventory syntax:
ansible-inventory -i inventory.yml --list
Display the inventory in a more readable format:
ansible-inventory -i inventory.yml --list --yaml
Test connectivity to all hosts:
ansible -i inventory.yml all -m ping
Task 3: Define Hosts and Groups
Subtask 3.1: Organize Hosts into Logical Groups
Let's enhance our inventory by organizing hosts into meaningful groups based on their roles or functions.

Edit the inventory file to add groups:
nano inventory.yml
Replace the content with this enhanced structure:
---
all:
  children:
    webservers:
      hosts:
        node1:
          ansible_host: node1
          ansible_user: student
          server_role: frontend
        node2:
          ansible_host: node2
          ansible_user: student
          server_role: backend
    databases:
      hosts:
        node3:
          ansible_host: node3
          ansible_user: student
          db_type: mysql
    development:
      hosts:
        node1:
          environment: dev
        node2:
          environment: dev
    production:
      hosts:
        node3:
          environment: prod
Save the file
Subtask 3.2: Add Group Variables
Group variables allow you to set common variables for all hosts in a group.

Enhance the inventory with group variables:
nano inventory.yml
Update the inventory to include group variables:
---
all:
  vars:
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    company: "Al Nafi Training"
  children:
    webservers:
      vars:
        http_port: 80
        https_port: 443
        web_package: apache2
      hosts:
        node1:
          ansible_host: node1
          ansible_user: student
          server_role: frontend
          cpu_cores: 2
        node2:
          ansible_host: node2
          ansible_user: student
          server_role: backend
          cpu_cores: 4
    databases:
      vars:
        db_port: 3306
        backup_schedule: "0 2 * * *"
      hosts:
        node3:
          ansible_host: node3
          ansible_user: student
          db_type: mysql
          storage_size: "100GB"
    development:
      vars:
        log_level: debug
        monitoring_enabled: false
      hosts:
        node1:
          environment: dev
        node2:
          environment: dev
    production:
      vars:
        log_level: info
        monitoring_enabled: true
        backup_enabled: true
      hosts:
        node3:
          environment: prod
Save the file
Subtask 3.3: Verify Group Structure
Let's test our enhanced inventory structure.

List all groups:
ansible -i inventory.yml --list-hosts all
List hosts in specific groups:
ansible -i inventory.yml --list-hosts webservers
ansible -i inventory.yml --list-hosts databases
ansible -i inventory.yml --list-hosts development
Display detailed inventory information:
ansible-inventory -i inventory.yml --list --yaml
Task 4: Test the Static Inventory with Ansible Commands
Subtask 4.1: Basic Connectivity Tests
Now let's thoroughly test our inventory with various Ansible commands.

Test connectivity to all hosts:
ansible -i inventory.yml all -m ping
Test connectivity to specific groups:
ansible -i inventory.yml webservers -m ping
ansible -i inventory.yml databases -m ping
Test connectivity to individual hosts:
ansible -i inventory.yml node1 -m ping
Subtask 4.2: Gather System Information
Let's use our inventory to gather information from managed hosts.

Collect system facts from all hosts:
ansible -i inventory.yml all -m setup -a "filter=ansible_distribution*"
Get hostname information from webservers:
ansible -i inventory.yml webservers -m command -a "hostname"
Check disk space on all hosts:
ansible -i inventory.yml all -m command -a "df -h"
Subtask 4.3: Test Variable Usage
Let's verify that our variables are properly configured and accessible.

Display variables for a specific host:
ansible-inventory -i inventory.yml --host node1
Create a simple playbook to test variables:
nano test-variables.yml
Add the following playbook content:
---
- name: Test Inventory Variables
  hosts: all
  gather_facts: no
  tasks:
    - name: Display host-specific variables
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          Company: {{ company }}
          Environment: {{ environment | default('not set') }}
          Server Role: {{ server_role | default('not set') }}
          
    - name: Display group membership
      debug:
        msg: "{{ inventory_hostname }} belongs to groups: {{ group_names }}"
Run the playbook:
ansible-playbook -i inventory.yml test-variables.yml
Subtask 4.4: Advanced Inventory Testing
Let's perform more advanced tests to ensure our inventory is robust.

Test pattern matching with groups:
ansible -i inventory.yml 'webservers:&development' --list-hosts
Test exclusion patterns:
ansible -i inventory.yml 'all:!production' --list-hosts
Test host patterns with wildcards:
ansible -i inventory.yml 'node*' --list-hosts
Validate inventory syntax:
ansible-inventory -i inventory.yml --list > /dev/null && echo "Inventory syntax is valid" || echo "Inventory has syntax errors"
Task 5: Create Advanced Inventory Configurations
Subtask 5.1: Add Host Aliases and Connection Parameters
Let's create a more sophisticated inventory with aliases and specific connection parameters.

Create an advanced inventory file:
nano advanced-inventory.yml
Add the following advanced configuration:
---
all:
  vars:
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    ansible_python_interpreter: /usr/bin/python3
  children:
    webservers:
      vars:
        http_port: 80
        https_port: 443
        max_connections: 1000
      hosts:
        web01:
          ansible_host: node1
          ansible_user: student
          ansible_port: 22
          server_id: "web-001"
          datacenter: "us-east-1"
        web02:
          ansible_host: node2
          ansible_user: student
          ansible_port: 22
          server_id: "web-002"
          datacenter: "us-west-1"
    databases:
      vars:
        db_port: 3306
        max_connections: 500
        backup_retention_days: 30
      hosts:
        db01:
          ansible_host: node3
          ansible_user: student
          ansible_port: 22
          server_id: "db-001"
          datacenter: "us-central-1"
          replication_role: master
    loadbalancers:
      vars:
        lb_algorithm: round_robin
        health_check_interval: 30
      hosts:
        lb01:
          ansible_host: node1
          ansible_user: student
          server_id: "lb-001"
          virtual_ip: "192.168.1.100"
    regions:
      children:
        us_east:
          hosts:
            web01:
        us_west:
          hosts:
            web02:
        us_central:
          hosts:
            db01:
Save the file
Subtask 5.2: Test Advanced Inventory Features
Test the advanced inventory:
ansible-inventory -i advanced-inventory.yml --list --yaml
Test complex group patterns:
ansible -i advanced-inventory.yml 'webservers:&us_east' --list-hosts
Display variables for aliased hosts:
ansible-inventory -i advanced-inventory.yml --host web01
ansible-inventory -i advanced-inventory.yml --host db01
Test connectivity using aliases:
ansible -i advanced-inventory.yml web01 -m ping
ansible -i advanced-inventory.yml db01 -m ping
Task 6: Troubleshooting and Best Practices
Subtask 6.1: Common Issues and Solutions
Let's explore common inventory issues and how to resolve them.

Create a problematic inventory for testing:
nano broken-inventory.yml
Add this intentionally broken inventory:
---
all:
  children:
    webservers:
      hosts:
        node1:
          ansible_host: nonexistent-host
          ansible_user: wronguser
        node2:
          ansible_host: node2
          ansible_user: student
          ansible_port: 9999
Test the broken inventory:
ansible -i broken-inventory.yml all -m ping -v
Fix the issues and test again:
nano broken-inventory.yml
Update to:

---
all:
  children:
    webservers:
      hosts:
        node1:
          ansible_host: node1
          ansible_user: student
        node2:
          ansible_host: node2
          ansible_user: student
Test the fixed inventory:
ansible -i broken-inventory.yml all -m ping
Subtask 6.2: Inventory Validation Script
Create a script to validate your inventory files.

Create a validation script:
nano validate-inventory.sh
Add the following script content:
#!/bin/bash

INVENTORY_FILE="$1"

if [ -z "$INVENTORY_FILE" ]; then
    echo "Usage: $0 <inventory-file>"
    exit 1
fi

if [ ! -f "$INVENTORY_FILE" ]; then
    echo "Error: Inventory file '$INVENTORY_FILE' not found"
    exit 1
fi

echo "Validating inventory file: $INVENTORY_FILE"
echo "========================================="

# Test syntax
echo "1. Testing YAML syntax..."
if ansible-inventory -i "$INVENTORY_FILE" --list > /dev/null 2>&1; then
    echo "   ✓ YAML syntax is valid"
else
    echo "   ✗ YAML syntax error detected"
    ansible-inventory -i "$INVENTORY_FILE" --list
    exit 1
fi

# List all hosts
echo "2. Listing all hosts..."
ansible-inventory -i "$INVENTORY_FILE" --list-hosts all

# Test connectivity
echo "3. Testing connectivity..."
if ansible -i "$INVENTORY_FILE" all -m ping > /dev/null 2>&1; then
    echo "   ✓ All hosts are reachable"
else
    echo "   ⚠ Some hosts may not be reachable"
    ansible -i "$INVENTORY_FILE" all -m ping
fi

echo "========================================="
echo "Validation complete"
Make the script executable:
chmod +x validate-inventory.sh
Test the validation script:
./validate-inventory.sh inventory.yml
./validate-inventory.sh advanced-inventory.yml
Conclusion
Congratulations! You have successfully completed Lab 7: Build Static Ansible Inventories. In this comprehensive lab, you have accomplished the following:

Key Achievements:

Created Static Inventories: You built multiple static inventory files using YAML format, demonstrating the flexibility and readability of this approach over traditional INI format.

Organized Hosts and Groups: You learned to organize hosts into logical groups such as webservers, databases, development, and production environments, making your infrastructure management more structured and efficient.

Implemented Variables: You successfully configured host-specific variables and group variables, enabling dynamic configuration management across your infrastructure.

Tested Inventory Functionality: You validated your inventories using various Ansible commands, ensuring connectivity and proper variable inheritance.

Advanced Configurations: You explored advanced inventory features including host aliases, connection parameters, and complex group patterns.

Troubleshooting Skills: You developed skills to identify and resolve common inventory issues, creating a validation script for ongoing inventory management.

Why This Matters:

Static inventories are fundamental to Ansible automation and are essential for the Red Hat Certified Specialist in Ansible Network Automation exam. The skills you've developed in this lab provide the foundation for:

Managing large-scale infrastructure deployments
Organizing complex multi-environment setups
Implementing infrastructure as code practices
Preparing for advanced Ansible automation scenarios
Your ability to create, manage, and troubleshoot static inventories will serve as a cornerstone for all future Ansible automation projects. These skills are directly applicable in enterprise environments where proper inventory management is crucial for successful automation initiatives.

Next Steps:

Consider exploring dynamic inventories, inventory plugins, and integration with cloud providers to further enhance your Ansible expertise. The solid foundation you've built with static inventories will make these advanced topics much more accessible.
