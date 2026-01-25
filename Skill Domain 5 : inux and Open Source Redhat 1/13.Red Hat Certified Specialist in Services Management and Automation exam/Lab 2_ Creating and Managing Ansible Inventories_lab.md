Lab 2: Creating and Managing Ansible Inventories
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of Ansible inventory management
Create and configure static inventory files with multiple host groups
Implement dynamic inventories to automatically discover cloud resources
Test and validate inventory configurations using Ansible commands
Apply inventory best practices for scalable automation environments
Troubleshoot common inventory-related issues
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and file formatting
Completed Lab 1 or equivalent Ansible installation experience
Understanding of basic networking concepts (IP addresses, SSH)
Knowledge of text editors like vim, nano, or VS Code
Required Knowledge Areas
Linux Systems Administration: File permissions, directory navigation
Network Fundamentals: SSH connectivity, port configurations
Configuration Management: Basic understanding of infrastructure as code concepts
Lab Environment Setup
Good News! Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or install software.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: 4 target systems (web servers, database servers)
Network Configuration: All systems configured with SSH key authentication
Cloud Integration: AWS CLI tools for dynamic inventory testing
Task 1: Creating Static Inventory Files with Multiple Host Groups
Subtask 1.1: Understanding Inventory File Structure
An Ansible inventory defines the hosts and groups of hosts upon which commands, modules, and tasks in a playbook operate.

Step 1: Navigate to Your Working Directory
cd /home/ansible
mkdir lab2-inventories
cd lab2-inventories
Step 2: Create Your First Basic Inventory File
nano basic_inventory.ini
Add the following content:

# Basic Inventory Example
[webservers]
web1.example.com
web2.example.com
192.168.1.10

[databases]
db1.example.com
db2.example.com
192.168.1.20

[monitoring]
monitor.example.com ansible_host=192.168.1.30
Step 3: Save and Test the Basic Inventory
# Save the file (Ctrl+X, Y, Enter in nano)
# Test the inventory structure
ansible-inventory -i basic_inventory.ini --list
Subtask 1.2: Creating Advanced Inventory with Variables
Step 1: Create an Advanced Inventory File
nano production_inventory.ini
Add the following comprehensive inventory:

# Production Environment Inventory

[webservers]
web01 ansible_host=10.0.1.10 ansible_user=webadmin http_port=80
web02 ansible_host=10.0.1.11 ansible_user=webadmin http_port=80
web03 ansible_host=10.0.1.12 ansible_user=webadmin http_port=8080

[databases]
db01 ansible_host=10.0.2.10 ansible_user=dbadmin mysql_port=3306
db02 ansible_host=10.0.2.11 ansible_user=dbadmin mysql_port=3306

[loadbalancers]
lb01 ansible_host=10.0.3.10 ansible_user=lbadmin

[monitoring]
monitor01 ansible_host=10.0.4.10 ansible_user=monitor

# Group Variables
[webservers:vars]
ansible_ssh_private_key_file=/home/ansible/.ssh/web_key
environment=production
app_version=2.1.0

[databases:vars]
ansible_ssh_private_key_file=/home/ansible/.ssh/db_key
backup_schedule=daily
mysql_root_password=SecurePass123

[production:children]
webservers
databases
loadbalancers
monitoring

[production:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
datacenter=us-east-1
Step 2: Test the Advanced Inventory
# List all hosts
ansible-inventory -i production_inventory.ini --list

# Show specific group
ansible-inventory -i production_inventory.ini --list --limit webservers

# Display in YAML format
ansible-inventory -i production_inventory.ini --list --yaml
Subtask 1.3: Creating YAML Format Inventory
Step 1: Create YAML Inventory File
nano inventory.yml
Add the following YAML inventory:

---
all:
  children:
    webservers:
      hosts:
        web01:
          ansible_host: 10.0.1.10
          ansible_user: webadmin
          http_port: 80
          server_role: frontend
        web02:
          ansible_host: 10.0.1.11
          ansible_user: webadmin
          http_port: 80
          server_role: frontend
        web03:
          ansible_host: 10.0.1.12
          ansible_user: webadmin
          http_port: 8080
          server_role: api
      vars:
        ansible_ssh_private_key_file: /home/ansible/.ssh/web_key
        environment: production
        app_version: "2.1.0"
        
    databases:
      hosts:
        db01:
          ansible_host: 10.0.2.10
          ansible_user: dbadmin
          mysql_port: 3306
          db_role: master
        db02:
          ansible_host: 10.0.2.11
          ansible_user: dbadmin
          mysql_port: 3306
          db_role: slave
      vars:
        ansible_ssh_private_key_file: /home/ansible/.ssh/db_key
        backup_schedule: daily
        mysql_version: "8.0"
        
    loadbalancers:
      hosts:
        lb01:
          ansible_host: 10.0.3.10
          ansible_user: lbadmin
          lb_algorithm: round_robin
          
    monitoring:
      hosts:
        monitor01:
          ansible_host: 10.0.4.10
          ansible_user: monitor
          monitoring_tools: ["nagios", "grafana"]
          
    production:
      children:
        webservers:
        databases:
        loadbalancers:
        monitoring:
      vars:
        datacenter: us-east-1
        backup_retention: 30
        security_level: high
Step 2: Validate YAML Inventory
# Test YAML syntax
ansible-inventory -i inventory.yml --list

# Check specific host details
ansible-inventory -i inventory.yml --host web01

# Verify group membership
ansible-inventory -i inventory.yml --graph
Task 2: Implementing Dynamic Inventories for Cloud Providers
Subtask 2.1: Setting Up AWS Dynamic Inventory
Step 1: Install Required Dependencies
# Install boto3 for AWS integration
pip3 install boto3 botocore

# Verify installation
python3 -c "import boto3; print('boto3 installed successfully')"
Step 2: Configure AWS Credentials
# Create AWS credentials directory
mkdir -p ~/.aws

# Create credentials file
nano ~/.aws/credentials
Add your AWS credentials:

[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
region = us-east-1
Create AWS config file:

nano ~/.aws/config
[default]
region = us-east-1
output = json
Step 3: Create AWS Dynamic Inventory Script
nano aws_ec2_inventory.py
#!/usr/bin/env python3

import boto3
import json
import sys

def get_ec2_inventory():
    """
    Generate dynamic inventory from AWS EC2 instances
    """
    inventory = {
        '_meta': {
            'hostvars': {}
        }
    }
    
    # Initialize EC2 client
    try:
        ec2 = boto3.client('ec2')
        response = ec2.describe_instances()
    except Exception as e:
        print(f"Error connecting to AWS: {e}", file=sys.stderr)
        return inventory
    
    # Process instances
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            if instance['State']['Name'] != 'running':
                continue
                
            instance_id = instance['InstanceId']
            private_ip = instance.get('PrivateIpAddress', '')
            public_ip = instance.get('PublicIpAddress', '')
            
            # Get instance tags
            tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
            instance_name = tags.get('Name', instance_id)
            
            # Add to inventory
            inventory['_meta']['hostvars'][instance_name] = {
                'ansible_host': public_ip or private_ip,
                'ec2_instance_id': instance_id,
                'ec2_instance_type': instance['InstanceType'],
                'ec2_private_ip': private_ip,
                'ec2_public_ip': public_ip,
                'ec2_state': instance['State']['Name'],
                'ec2_tags': tags
            }
            
            # Group by tags
            for key, value in tags.items():
                group_name = f"{key}_{value}".replace(' ', '_').replace('-', '_').lower()
                if group_name not in inventory:
                    inventory[group_name] = {'hosts': []}
                inventory[group_name]['hosts'].append(instance_name)
            
            # Group by instance type
            instance_type_group = f"type_{instance['InstanceType'].replace('.', '_')}"
            if instance_type_group not in inventory:
                inventory[instance_type_group] = {'hosts': []}
            inventory[instance_type_group]['hosts'].append(instance_name)
    
    return inventory

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] == '--list':
        inventory = get_ec2_inventory()
        print(json.dumps(inventory, indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == '--host':
        # Return empty dict for host-specific vars (handled in --list)
        print(json.dumps({}))
    else:
        print("Usage: aws_ec2_inventory.py --list")
        print("       aws_ec2_inventory.py --host <hostname>")
        sys.exit(1)
Step 4: Make Script Executable and Test
# Make script executable
chmod +x aws_ec2_inventory.py

# Test the dynamic inventory
./aws_ec2_inventory.py --list

# Test with Ansible
ansible-inventory -i aws_ec2_inventory.py --list
Subtask 2.2: Using Ansible's Built-in AWS EC2 Plugin
Step 1: Create EC2 Plugin Configuration
nano aws_ec2.yml
---
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
  - us-west-2
keyed_groups:
  # Create groups based on instance tags
  - key: tags.Environment
    prefix: env
  - key: tags.Application
    prefix: app
  - key: instance_type
    prefix: type
  - key: placement.availability_zone
    prefix: az
compose:
  # Set ansible_host to public IP if available, otherwise private IP
  ansible_host: public_ip_address | default(private_ip_address)
  ec2_instance_type: instance_type
  ec2_placement_az: placement.availability_zone
  ec2_state: state.name
filters:
  # Only include running instances
  instance-state-name: running
Step 2: Test the EC2 Plugin
# Install the Amazon AWS collection
ansible-galaxy collection install amazon.aws

# Test the plugin
ansible-inventory -i aws_ec2.yml --list

# Show the inventory graph
ansible-inventory -i aws_ec2.yml --graph
Subtask 2.3: Creating a Hybrid Inventory Setup
Step 1: Create Inventory Directory Structure
mkdir -p inventories/production
cd inventories/production
Step 2: Create Multiple Inventory Sources
# Static inventory for on-premises servers
nano static_hosts.ini
[onprem_webservers]
web-onprem-01 ansible_host=192.168.1.10
web-onprem-02 ansible_host=192.168.1.11

[onprem_databases]
db-onprem-01 ansible_host=192.168.2.10

[onpremise:children]
onprem_webservers
onprem_databases

[onpremise:vars]
datacenter=local
environment=production
Copy the AWS dynamic inventory configuration:

cp ../../aws_ec2.yml ./
Step 3: Test Hybrid Inventory
# Test combined inventory (Ansible automatically combines all files in directory)
cd ..
ansible-inventory -i production/ --list

# Show combined graph
ansible-inventory -i production/ --graph

# List only cloud instances
ansible-inventory -i production/ --list --limit 'env_production'

# List only on-premises servers
ansible-inventory -i production/ --list --limit 'onpremise'
Task 3: Testing Inventory Setups Using Ansible Commands
Subtask 3.1: Basic Inventory Testing Commands
Step 1: Test Host Connectivity
# Test all hosts in inventory
ansible all -i production_inventory.ini -m ping

# Test specific group
ansible webservers -i production_inventory.ini -m ping

# Test with different inventory formats
ansible all -i inventory.yml -m ping
Step 2: Gather System Information
# Collect facts from all hosts
ansible all -i production_inventory.ini -m setup --tree /tmp/facts

# Get specific facts
ansible webservers -i production_inventory.ini -m setup -a "filter=ansible_os_family"

# Check disk space
ansible databases -i production_inventory.ini -m shell -a "df -h"
Subtask 3.2: Advanced Inventory Testing
Step 1: Create Inventory Validation Playbook
nano validate_inventory.yml
---
- name: Validate Inventory Configuration
  hosts: all
  gather_facts: yes
  tasks:
    - name: Display host information
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          IP: {{ ansible_host | default('N/A') }}
          Group: {{ group_names }}
          OS: {{ ansible_os_family | default('Unknown') }}
          
    - name: Check SSH connectivity
      ping:
      register: ping_result
      
    - name: Verify required variables are set
      assert:
        that:
          - ansible_host is defined
          - inventory_hostname is defined
        fail_msg: "Required variables missing for {{ inventory_hostname }}"
        success_msg: "All required variables present for {{ inventory_hostname }}"
        
    - name: Test sudo access (if applicable)
      command: whoami
      become: yes
      register: sudo_test
      ignore_errors: yes
      
    - name: Report sudo status
      debug:
        msg: "Sudo access: {{ 'Available' if sudo_test.rc == 0 else 'Not available' }}"
Step 2: Run Validation Playbook
# Run against static inventory
ansible-playbook -i production_inventory.ini validate_inventory.yml

# Run against YAML inventory
ansible-playbook -i inventory.yml validate_inventory.yml

# Run with verbose output
ansible-playbook -i production_inventory.ini validate_inventory.yml -v
Subtask 3.3: Inventory Troubleshooting and Debugging
Step 1: Common Debugging Commands
# Check inventory syntax
ansible-inventory -i production_inventory.ini --list --yaml | python3 -m yaml.tool

# Verify host variables
ansible-inventory -i production_inventory.ini --host web01

# List all groups
ansible-inventory -i production_inventory.ini --graph

# Check for duplicate hosts
ansible-inventory -i production_inventory.ini --list | jq '.["_meta"]["hostvars"] | keys'
Step 2: Create Debugging Script
nano debug_inventory.sh
#!/bin/bash

INVENTORY_FILE=$1

if [ -z "$INVENTORY_FILE" ]; then
    echo "Usage: $0 <inventory_file>"
    exit 1
fi

echo "=== Inventory Debug Report ==="
echo "Inventory file: $INVENTORY_FILE"
echo "Generated on: $(date)"
echo

echo "=== Inventory Structure ==="
ansible-inventory -i "$INVENTORY_FILE" --graph
echo

echo "=== All Hosts ==="
ansible-inventory -i "$INVENTORY_FILE" --list | jq -r '._meta.hostvars | keys[]' | sort
echo

echo "=== Groups ==="
ansible-inventory -i "$INVENTORY_FILE" --list | jq -r 'keys[]' | grep -v "_meta" | sort
echo

echo "=== Connectivity Test ==="
ansible all -i "$INVENTORY_FILE" -m ping --one-line
echo

echo "=== Host Variables Sample (first host) ==="
FIRST_HOST=$(ansible-inventory -i "$INVENTORY_FILE" --list | jq -r '._meta.hostvars | keys[0]')
if [ "$FIRST_HOST" != "null" ]; then
    ansible-inventory -i "$INVENTORY_FILE" --host "$FIRST_HOST"
fi
Step 3: Make Script Executable and Test
chmod +x debug_inventory.sh

# Test with different inventories
./debug_inventory.sh production_inventory.ini
./debug_inventory.sh inventory.yml
Subtask 3.4: Performance Testing with Large Inventories
Step 1: Create Large Test Inventory
nano generate_large_inventory.py
#!/usr/bin/env python3

import sys

def generate_inventory(num_hosts=100):
    """Generate a large inventory file for testing"""
    
    print("[webservers]")
    for i in range(1, num_hosts // 2 + 1):
        print(f"web{i:03d} ansible_host=10.0.1.{i % 254 + 1}")
    
    print("\n[databases]")
    for i in range(1, num_hosts // 4 + 1):
        print(f"db{i:03d} ansible_host=10.0.2.{i % 254 + 1}")
    
    print("\n[monitoring]")
    for i in range(1, num_hosts // 4 + 1):
        print(f"monitor{i:03d} ansible_host=10.0.3.{i % 254 + 1}")
    
    print("\n[production:children]")
    print("webservers")
    print("databases")
    print("monitoring")
    
    print("\n[production:vars]")
    print("ansible_user=testuser")
    print("ansible_ssh_private_key_file=/home/ansible/.ssh/test_key")

if __name__ == "__main__":
    num_hosts = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    generate_inventory(num_hosts)
Step 2: Generate and Test Large Inventory
# Make script executable
chmod +x generate_large_inventory.py

# Generate large inventory
./generate_large_inventory.py 500 > large_inventory.ini

# Test performance
time ansible-inventory -i large_inventory.ini --list > /dev/null

# Test with different formats
time ansible-inventory -i large_inventory.ini --list --yaml > /dev/null
Troubleshooting Common Issues
Issue 1: SSH Connection Problems
Problem: Hosts are unreachable via SSH

Solution:

# Test SSH connectivity manually
ssh -i ~/.ssh/your_key user@hostname

# Check SSH configuration in inventory
ansible-inventory -i your_inventory.ini --host problematic_host

# Test with verbose SSH debugging
ansible all -i your_inventory.ini -m ping -vvv
Issue 2: Dynamic Inventory Not Working
Problem: AWS dynamic inventory returns empty results

Solution:

# Check AWS credentials
aws sts get-caller-identity

# Test boto3 connection
python3 -c "import boto3; print(boto3.client('ec2').describe_instances())"

# Verify EC2 plugin configuration
ansible-inventory -i aws_ec2.yml --list --export
Issue 3: Inventory Syntax Errors
Problem: YAML or INI syntax errors

Solution:

# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('inventory.yml'))"

# Check INI file format
ansible-inventory -i inventory.ini --list --export

# Use ansible-inventory to identify issues
ansible-inventory -i problematic_inventory.ini --list 2>&1 | grep -i error
Issue 4: Variable Precedence Issues
Problem: Variables not applying as expected

Solution:

# Check variable precedence
ansible-inventory -i inventory.ini --host hostname

# Test variable resolution in playbook
ansible-playbook test_vars.yml -i inventory.ini --extra-vars "debug=true"

# Use debug module to inspect variables
ansible hostname -i inventory.ini -m debug -a "var=hostvars[inventory_hostname]"
Best Practices Summary
Inventory Organization
Use descriptive group names that reflect server roles and environments
Implement consistent naming conventions for hosts and variables
Separate environments using different inventory files or directories
Use group variables to reduce duplication and improve maintainability
Security Considerations
Store sensitive data in Ansible Vault, not in plain text inventory files
Use SSH key authentication instead of passwords
Limit SSH access using specific users and key files
Regularly rotate SSH keys and access credentials
Performance Optimization
Use inventory caching for dynamic inventories to improve performance
Limit host patterns when running commands against large inventories
Implement inventory plugins for better integration with external systems
Monitor inventory size and consider splitting large inventories
Maintenance Guidelines
Version control all inventory files using Git
Document inventory structure and variable purposes
Test inventory changes in development environments first
Implement automated validation for inventory syntax and connectivity
Conclusion
In this comprehensive lab, you have successfully mastered the fundamentals of Ansible inventory management. You've learned to create and manage both static and dynamic inventories, which are essential skills for any automation engineer working with Ansible.

Key Accomplishments
Static Inventory Mastery: You created multiple inventory formats (INI and YAML) with complex group structures, host variables, and group variables. This foundation enables you to organize and manage infrastructure efficiently across different environments.

Dynamic Inventory Implementation: You implemented AWS EC2 dynamic inventories using both custom Python scripts and Ansible's built-in plugins. This skill is crucial for managing cloud-native and hybrid infrastructure where resources change frequently.

Testing and Validation: You developed comprehensive testing strategies using Ansible commands, validation playbooks, and debugging scripts. These skills ensure your inventory configurations are reliable and maintainable.

Troubleshooting Expertise: You learned to identify and resolve common inventory issues, from SSH connectivity problems to variable precedence conflicts. This troubleshooting knowledge is invaluable for production environments.

Real-World Applications
The skills you've developed directly apply to enterprise automation scenarios:

Multi-Environment Management: Your inventory organization skills enable consistent deployment across development, staging, and production environments
Cloud Integration: Dynamic inventory capabilities allow seamless automation of cloud resources that scale up and down automatically
Compliance and Auditing: Proper inventory management supports compliance requirements and audit trails for infrastructure changes
Team Collaboration: Well-structured inventories improve team productivity and reduce configuration errors
Next Steps
With solid inventory management skills, you're prepared to tackle more advanced Ansible topics such as complex playbook development, role creation, and enterprise automation workflows. The inventory foundation you've built will support all future Ansible automation projects.

Your journey in infrastructure automation continues to build upon these essential inventory management concepts, positioning you well for Red Hat certification success and professional automation engineering roles.
