Lab 3: Managing Inventory
Objectives
By the end of this lab, students will be able to:

• Create and configure static inventory files for Ansible automation • Understand the structure and syntax of Ansible inventory files • Implement dynamic inventory for cloud-based systems using scripts • Test and validate inventory configurations using Ansible commands • Troubleshoot common inventory-related issues • Organize hosts into groups for efficient management • Apply inventory variables to customize host configurations

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with text editors (nano, vim, or gedit) • Completed Lab 1 and Lab 2 of the Ansible series • Basic knowledge of YAML syntax • Understanding of SSH key-based authentication • Access to multiple Linux systems for testing

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines. Your lab environment includes:

• One Ansible control node (ansible-control) • Three managed nodes (web1, web2, db1) • All necessary software pre-installed • SSH keys already configured between nodes

Task 1: Create a Static Inventory File
Subtask 1.1: Understanding Inventory Basics
An inventory file tells Ansible which servers to manage and how to connect to them. Think of it as your contact list for servers.

Connect to your control node:
ssh student@ansible-control
Navigate to your working directory:
cd /home/student/ansible-labs
mkdir lab3-inventory
cd lab3-inventory
Create your first inventory file:
nano inventory.ini
Add the following content to create a basic inventory:
# Basic Static Inventory File
# Web Servers Group
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=student
web2 ansible_host=192.168.1.11 ansible_user=student

# Database Servers Group
[databases]
db1 ansible_host=192.168.1.20 ansible_user=student

# All servers group (automatically created)
[production:children]
webservers
databases

# Group variables
[webservers:vars]
http_port=80
max_clients=200

[databases:vars]
mysql_port=3306
max_connections=100
Save and exit (Ctrl+X, then Y, then Enter)
Subtask 1.2: Creating an Advanced Static Inventory
Create a more detailed inventory file:
nano advanced-inventory.ini
Add comprehensive inventory configuration:
# Advanced Static Inventory Configuration

# Web Server Tier
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=student server_role=frontend
web2 ansible_host=192.168.1.11 ansible_user=student server_role=frontend

# Database Tier
[databases]
db1 ansible_host=192.168.1.20 ansible_user=student server_role=backend

# Load Balancers
[loadbalancers]
lb1 ansible_host=192.168.1.30 ansible_user=student server_role=loadbalancer

# Environment Groups
[production:children]
webservers
databases
loadbalancers

[staging]
staging-web ansible_host=192.168.1.40 ansible_user=student
staging-db ansible_host=192.168.1.41 ansible_user=student

# Regional Groups
[east-coast]
web1
db1

[west-coast]
web2
lb1

# Global Variables
[all:vars]
ansible_ssh_private_key_file=/home/student/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

# Group-specific Variables
[webservers:vars]
http_port=80
https_port=443
document_root=/var/www/html
max_clients=200

[databases:vars]
mysql_port=3306
mysql_datadir=/var/lib/mysql
max_connections=100
innodb_buffer_pool_size=256M

[loadbalancers:vars]
balance_method=roundrobin
health_check_interval=30
Save the file (Ctrl+X, then Y, then Enter)
Subtask 1.3: Creating YAML Format Inventory
Create a YAML inventory file:
nano inventory.yml
Add YAML-formatted inventory:
# YAML Static Inventory File
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.10
          ansible_user: student
          server_role: frontend
          http_port: 80
        web2:
          ansible_host: 192.168.1.11
          ansible_user: student
          server_role: frontend
          http_port: 80
      vars:
        max_clients: 200
        document_root: /var/www/html
    
    databases:
      hosts:
        db1:
          ansible_host: 192.168.1.20
          ansible_user: student
          server_role: backend
          mysql_port: 3306
      vars:
        max_connections: 100
        mysql_datadir: /var/lib/mysql
    
    production:
      children:
        webservers:
        databases:
      vars:
        environment: production
        backup_schedule: "0 2 * * *"
Save the file (Ctrl+X, then Y, then Enter)
Task 2: Use Dynamic Inventory for Cloud-Based Systems
Subtask 2.1: Understanding Dynamic Inventory
Dynamic inventory automatically discovers and manages hosts from external sources like cloud providers, databases, or APIs.

Create a simple dynamic inventory script:
nano dynamic-inventory.py
Add the following Python script:
#!/usr/bin/env python3
"""
Simple Dynamic Inventory Script for Ansible
This script demonstrates how to create dynamic inventory
"""

import json
import sys
import subprocess

def get_inventory():
    """Generate dynamic inventory"""
    
    # Simulate discovering hosts (in real scenarios, this would query cloud APIs)
    inventory = {
        'webservers': {
            'hosts': ['web1', 'web2'],
            'vars': {
                'http_port': 80,
                'max_clients': 200
            }
        },
        'databases': {
            'hosts': ['db1'],
            'vars': {
                'mysql_port': 3306,
                'max_connections': 100
            }
        },
        'production': {
            'children': ['webservers', 'databases'],
            'vars': {
                'environment': 'production'
            }
        },
        '_meta': {
            'hostvars': {
                'web1': {
                    'ansible_host': '192.168.1.10',
                    'ansible_user': 'student',
                    'server_role': 'frontend'
                },
                'web2': {
                    'ansible_host': '192.168.1.11',
                    'ansible_user': 'student',
                    'server_role': 'frontend'
                },
                'db1': {
                    'ansible_host': '192.168.1.20',
                    'ansible_user': 'student',
                    'server_role': 'backend'
                }
            }
        }
    }
    
    return inventory

def get_host_vars(host):
    """Get variables for a specific host"""
    inventory = get_inventory()
    return inventory.get('_meta', {}).get('hostvars', {}).get(host, {})

def main():
    """Main function to handle command line arguments"""
    if len(sys.argv) == 2 and sys.argv[1] == '--list':
        # Return full inventory
        print(json.dumps(get_inventory(), indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == '--host':
        # Return host-specific variables
        print(json.dumps(get_host_vars(sys.argv[2]), indent=2))
    else:
        print("Usage: {} --list or {} --host <hostname>".format(sys.argv[0], sys.argv[0]))
        sys.exit(1)

if __name__ == '__main__':
    main()
Make the script executable:
chmod +x dynamic-inventory.py
Subtask 2.2: Creating an Advanced Dynamic Inventory Script
Create an advanced dynamic inventory script:
nano cloud-inventory.py
Add advanced dynamic inventory logic:
#!/usr/bin/env python3
"""
Advanced Dynamic Inventory Script
Simulates cloud provider integration
"""

import json
import sys
import os
import subprocess
from datetime import datetime

class CloudInventory:
    def __init__(self):
        self.inventory = {}
        self.read_environment()
        
    def read_environment(self):
        """Read configuration from environment variables"""
        self.cloud_provider = os.environ.get('CLOUD_PROVIDER', 'aws')
        self.region = os.environ.get('CLOUD_REGION', 'us-east-1')
        self.environment = os.environ.get('ENVIRONMENT', 'production')
        
    def discover_instances(self):
        """Simulate cloud instance discovery"""
        # In real scenarios, this would use cloud provider APIs
        instances = [
            {
                'name': 'web1',
                'ip': '192.168.1.10',
                'type': 't2.micro',
                'tags': {'Role': 'webserver', 'Environment': 'production'}
            },
            {
                'name': 'web2',
                'ip': '192.168.1.11',
                'type': 't2.micro',
                'tags': {'Role': 'webserver', 'Environment': 'production'}
            },
            {
                'name': 'db1',
                'ip': '192.168.1.20',
                'type': 't2.small',
                'tags': {'Role': 'database', 'Environment': 'production'}
            }
        ]
        return instances
        
    def build_inventory(self):
        """Build the inventory structure"""
        instances = self.discover_instances()
        
        # Initialize inventory structure
        self.inventory = {
            'all': {
                'vars': {
                    'cloud_provider': self.cloud_provider,
                    'region': self.region,
                    'discovered_at': datetime.now().isoformat()
                }
            },
            '_meta': {
                'hostvars': {}
            }
        }
        
        # Group instances by role
        for instance in instances:
            role = instance['tags'].get('Role', 'ungrouped')
            group_name = f"{role}s" if not role.endswith('s') else role
            
            # Create group if it doesn't exist
            if group_name not in self.inventory:
                self.inventory[group_name] = {
                    'hosts': [],
                    'vars': {}
                }
            
            # Add host to group
            self.inventory[group_name]['hosts'].append(instance['name'])
            
            # Add host variables
            self.inventory['_meta']['hostvars'][instance['name']] = {
                'ansible_host': instance['ip'],
                'ansible_user': 'student',
                'instance_type': instance['type'],
                'cloud_provider': self.cloud_provider,
                'region': self.region
            }
            
            # Add tags as variables
            for tag_key, tag_value in instance['tags'].items():
                self.inventory['_meta']['hostvars'][instance['name']][f"tag_{tag_key.lower()}"] = tag_value
        
        # Create environment-based groups
        env_group = f"{self.environment}_servers"
        self.inventory[env_group] = {
            'children': list(self.inventory.keys())[1:-1]  # Exclude 'all' and '_meta'
        }
        
        return self.inventory
    
    def get_inventory(self):
        """Return the complete inventory"""
        return self.build_inventory()
    
    def get_host_vars(self, hostname):
        """Return variables for a specific host"""
        inventory = self.get_inventory()
        return inventory.get('_meta', {}).get('hostvars', {}).get(hostname, {})

def main():
    """Main execution function"""
    cloud_inv = CloudInventory()
    
    if len(sys.argv) == 2 and sys.argv[1] == '--list':
        print(json.dumps(cloud_inv.get_inventory(), indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == '--host':
        print(json.dumps(cloud_inv.get_host_vars(sys.argv[2]), indent=2))
    else:
        print("Usage: {} --list or {} --host <hostname>".format(sys.argv[0], sys.argv[0]))
        sys.exit(1)

if __name__ == '__main__':
    main()
Make the script executable:
chmod +x cloud-inventory.py
Subtask 2.3: Testing Dynamic Inventory Scripts
Test the basic dynamic inventory script:
./dynamic-inventory.py --list
Test host-specific variables:
./dynamic-inventory.py --host web1
Test the advanced cloud inventory script:
./cloud-inventory.py --list
Set environment variables and test:
export CLOUD_PROVIDER=aws
export CLOUD_REGION=us-west-2
export ENVIRONMENT=staging
./cloud-inventory.py --list
Task 3: Test Inventory with Ansible Commands
Subtask 3.1: Basic Inventory Testing
Test static inventory connectivity:
ansible all -i inventory.ini -m ping
List all hosts in inventory:
ansible all -i inventory.ini --list-hosts
Test specific groups:
ansible webservers -i inventory.ini --list-hosts
ansible databases -i inventory.ini --list-hosts
Test YAML inventory:
ansible all -i inventory.yml -m ping
Subtask 3.2: Advanced Inventory Testing
Test dynamic inventory:
ansible all -i ./dynamic-inventory.py -m ping
Display inventory variables:
ansible-inventory -i inventory.ini --list
Show variables for specific hosts:
ansible-inventory -i inventory.ini --host web1
Test group variables:
ansible webservers -i inventory.ini -m debug -a "var=hostvars[inventory_hostname]"
Subtask 3.3: Comprehensive Inventory Validation
Create a test playbook to validate inventory:
nano test-inventory.yml
Add inventory validation playbook:
---
- name: Test Inventory Configuration
  hosts: all
  gather_facts: yes
  tasks:
    - name: Display host information
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          IP: {{ ansible_host }}
          User: {{ ansible_user }}
          Group: {{ group_names }}
          
    - name: Test connectivity
      ping:
      
    - name: Display system information
      debug:
        msg: |
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Architecture: {{ ansible_architecture }}
          Hostname: {{ ansible_hostname }}
          
    - name: Show custom variables
      debug:
        var: hostvars[inventory_hostname]
      when: inventory_hostname in hostvars
Run the validation playbook with different inventories:
ansible-playbook -i inventory.ini test-inventory.yml
ansible-playbook -i inventory.yml test-inventory.yml
ansible-playbook -i ./dynamic-inventory.py test-inventory.yml
Subtask 3.4: Inventory Performance and Troubleshooting
Test inventory parsing time:
time ansible-inventory -i inventory.ini --list > /dev/null
time ansible-inventory -i ./dynamic-inventory.py --list > /dev/null
Debug inventory issues:
ansible-inventory -i inventory.ini --list --yaml
ansible all -i inventory.ini -m setup --tree /tmp/facts
Validate inventory syntax:
ansible-inventory -i inventory.ini --list --yaml | head -20
ansible-playbook -i inventory.ini --syntax-check test-inventory.yml
Test with verbose output:
ansible all -i inventory.ini -m ping -vvv
Common Troubleshooting Tips
Connection Issues
SSH Key Problems: Ensure SSH keys are properly configured
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa
ssh-copy-id student@192.168.1.10
Host Key Verification: Add to ansible.cfg or inventory
[defaults]
host_key_checking = False
Inventory Syntax Errors
INI Format: Check for proper section headers and variable syntax
YAML Format: Validate YAML syntax using online validators
Dynamic Scripts: Ensure scripts are executable and return valid JSON
Variable Precedence Issues
Order of precedence: Playbook vars > Host vars > Group vars > Inventory vars
Debug variables: Use debug module to check variable values
Performance Optimization
Large Inventories: Use --limit to target specific hosts
Caching: Implement caching in dynamic inventory scripts
Parallel Execution: Adjust forks setting in ansible.cfg
Conclusion
In this lab, you have successfully:

• Created static inventory files in both INI and YAML formats, learning how to organize hosts into logical groups and assign variables • Implemented dynamic inventory scripts that can automatically discover and manage cloud-based systems, making your infrastructure more flexible and scalable • Tested inventory configurations using various Ansible commands to ensure connectivity and validate your setup

Why This Matters: Proper inventory management is the foundation of effective automation. Static inventories work well for stable environments, while dynamic inventories are essential for cloud and containerized environments where infrastructure changes frequently. The skills you've learned here will help you manage everything from small server deployments to large-scale cloud infrastructures.

Key Takeaways:

Static inventories provide predictable, version-controlled host management
Dynamic inventories enable automatic discovery and scaling
Proper testing ensures your automation will work reliably
Group organization and variables make your playbooks more maintainable
You're now ready to move on to more advanced Ansible topics, building on this solid foundation of inventory management skills.
