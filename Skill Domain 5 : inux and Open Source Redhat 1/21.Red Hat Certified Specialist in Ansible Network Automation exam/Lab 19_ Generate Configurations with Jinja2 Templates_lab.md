Lab 19: Generate Configurations with Jinja2 Templates
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of Jinja2 templating engine
Create dynamic Jinja2 templates for network device configurations
Use variables, loops, and conditionals in Jinja2 templates
Generate customized configuration files for different network devices
Integrate Jinja2 templates with Python scripts for automated configuration generation
Apply best practices for template organization and maintenance
Prerequisites
Before starting this lab, you should have:

Basic understanding of network device configurations (routers, switches)
Familiarity with Python programming fundamentals
Knowledge of YAML data structures
Understanding of network protocols (OSPF, BGP, VLANs)
Experience with command-line interface operations
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

Ubuntu 20.04 LTS with Python 3.8+
Pre-installed Jinja2 library
Text editors (nano, vim)
Sample network topology data
Task 1: Create a Jinja2 Template to Generate Network Configuration Files
Subtask 1.1: Set Up the Lab Environment
First, let's verify our environment and create the necessary directory structure.

Open your terminal and check Python installation:
python3 --version
Verify Jinja2 installation:
python3 -c "import jinja2; print(jinja2.__version__)"
Create the lab directory structure:
mkdir -p ~/jinja2-lab/{templates,data,output,scripts}
cd ~/jinja2-lab
Create subdirectories for organization:
mkdir -p templates/{cisco,juniper,arista}
mkdir -p data/{devices,vlans,routing}
Subtask 1.2: Create Your First Basic Jinja2 Template
Let's start with a simple router configuration template.

Create a basic router template:
nano templates/cisco/basic_router.j2
Add the following template content:
!
! Configuration for {{ hostname }}
! Generated on {{ generation_date }}
!
version 15.1
service timestamps debug datetime msec
service timestamps log datetime msec
no service password-encryption
!
hostname {{ hostname }}
!
{% if enable_secret %}
enable secret {{ enable_secret }}
{% endif %}
!
{% if interfaces %}
{% for interface in interfaces %}
interface {{ interface.name }}
{% if interface.ip_address %}
 ip address {{ interface.ip_address }} {{ interface.subnet_mask }}
{% endif %}
{% if interface.description %}
 description {{ interface.description }}
{% endif %}
{% if interface.shutdown is defined and not interface.shutdown %}
 no shutdown
{% else %}
 shutdown
{% endif %}
!
{% endfor %}
{% endif %}
!
{% if static_routes %}
{% for route in static_routes %}
ip route {{ route.network }} {{ route.mask }} {{ route.next_hop }}
{% endfor %}
{% endif %}
!
line con 0
line aux 0
line vty 0 4
 login
!
end
Subtask 1.3: Create Device Data Files
Now let's create YAML data files that will populate our templates.

Create a device data file:
nano data/devices/router1.yml
Add device-specific data:
hostname: "R1-CORE"
enable_secret: "cisco123"
generation_date: "2024-01-15"

interfaces:
  - name: "GigabitEthernet0/0"
    ip_address: "192.168.1.1"
    subnet_mask: "255.255.255.0"
    description: "LAN Interface"
    shutdown: false
  
  - name: "GigabitEthernet0/1"
    ip_address: "10.0.0.1"
    subnet_mask: "255.255.255.252"
    description: "WAN Interface to ISP"
    shutdown: false
  
  - name: "GigabitEthernet0/2"
    description: "Unused Interface"
    shutdown: true

static_routes:
  - network: "0.0.0.0"
    mask: "0.0.0.0"
    next_hop: "10.0.0.2"
  
  - network: "172.16.0.0"
    mask: "255.255.0.0"
    next_hop: "192.168.1.254"
Create another device data file:
nano data/devices/router2.yml
hostname: "R2-BRANCH"
enable_secret: "secure456"
generation_date: "2024-01-15"

interfaces:
  - name: "GigabitEthernet0/0"
    ip_address: "192.168.2.1"
    subnet_mask: "255.255.255.0"
    description: "Branch LAN"
    shutdown: false
  
  - name: "GigabitEthernet0/1"
    ip_address: "10.0.0.5"
    subnet_mask: "255.255.255.252"
    description: "Link to Core Router"
    shutdown: false

static_routes:
  - network: "0.0.0.0"
    mask: "0.0.0.0"
    next_hop: "10.0.0.6"
Subtask 1.4: Create a Python Script to Generate Configurations
Create the configuration generator script:
nano scripts/generate_config.py
Add the Python script content:
#!/usr/bin/env python3

import os
import yaml
from jinja2 import Environment, FileSystemLoader
from datetime import datetime

def load_device_data(data_file):
    """Load device data from YAML file"""
    try:
        with open(data_file, 'r') as file:
            return yaml.safe_load(file)
    except FileNotFoundError:
        print(f"Error: Data file {data_file} not found")
        return None
    except yaml.YAMLError as e:
        print(f"Error parsing YAML file: {e}")
        return None

def generate_configuration(template_file, data, output_file):
    """Generate configuration using Jinja2 template"""
    try:
        # Set up Jinja2 environment
        template_dir = os.path.dirname(template_file)
        template_name = os.path.basename(template_file)
        
        env = Environment(
            loader=FileSystemLoader(template_dir),
            trim_blocks=True,
            lstrip_blocks=True
        )
        
        # Load template
        template = env.get_template(template_name)
        
        # Add current timestamp if not provided
        if 'generation_date' not in data:
            data['generation_date'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Render template with data
        config = template.render(data)
        
        # Write to output file
        with open(output_file, 'w') as file:
            file.write(config)
        
        print(f"Configuration generated successfully: {output_file}")
        return True
        
    except Exception as e:
        print(f"Error generating configuration: {e}")
        return False

def main():
    """Main function to generate configurations for all devices"""
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    # Define paths
    template_file = os.path.join(base_dir, "templates/cisco/basic_router.j2")
    data_dir = os.path.join(base_dir, "data/devices")
    output_dir = os.path.join(base_dir, "output")
    
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Process each device data file
    for filename in os.listdir(data_dir):
        if filename.endswith('.yml') or filename.endswith('.yaml'):
            print(f"\nProcessing {filename}...")
            
            # Load device data
            data_file = os.path.join(data_dir, filename)
            device_data = load_device_data(data_file)
            
            if device_data:
                # Generate output filename
                device_name = os.path.splitext(filename)[0]
                output_file = os.path.join(output_dir, f"{device_name}_config.txt")
                
                # Generate configuration
                generate_configuration(template_file, device_data, output_file)

if __name__ == "__main__":
    main()
Make the script executable:
chmod +x scripts/generate_config.py
Run the configuration generator:
cd ~/jinja2-lab
python3 scripts/generate_config.py
Verify the generated configurations:
ls -la output/
cat output/router1_config.txt
Task 2: Use Variables to Customize Templates for Different Devices
Subtask 2.1: Create Advanced Templates with Complex Logic
Let's create more sophisticated templates that handle different device types and features.

Create an advanced switch template:
nano templates/cisco/advanced_switch.j2
Add the advanced switch template:
!
! {{ device_type | upper }} Configuration for {{ hostname }}
! Location: {{ location | default('Not Specified') }}
! Generated: {{ generation_date }}
! Template Version: 2.1
!
version 15.2
service timestamps debug datetime msec
service timestamps log datetime msec
no service password-encryption
service compress-config
!
hostname {{ hostname }}
!
{% if domain_name %}
ip domain-name {{ domain_name }}
{% endif %}
!
{% if enable_secret %}
enable secret 5 {{ enable_secret }}
{% endif %}
!
{% if users %}
{% for user in users %}
username {{ user.name }} privilege {{ user.privilege | default(1) }} secret {{ user.password }}
{% endfor %}
{% endif %}
!
{% if vlans %}
! VLAN Configuration
{% for vlan in vlans %}
vlan {{ vlan.id }}
 name {{ vlan.name }}
{% if vlan.state is defined %}
 state {{ vlan.state }}
{% endif %}
!
{% endfor %}
{% endif %}
!
{% if interfaces %}
! Interface Configuration
{% for interface in interfaces %}
interface {{ interface.name }}
{% if interface.description %}
 description {{ interface.description }}
{% endif %}
{% if interface.switchport %}
 switchport
{% if interface.switchport.mode %}
 switchport mode {{ interface.switchport.mode }}
{% endif %}
{% if interface.switchport.access_vlan %}
 switchport access vlan {{ interface.switchport.access_vlan }}
{% endif %}
{% if interface.switchport.trunk_vlans %}
 switchport trunk allowed vlan {{ interface.switchport.trunk_vlans | join(',') }}
{% endif %}
{% if interface.switchport.native_vlan %}
 switchport trunk native vlan {{ interface.switchport.native_vlan }}
{% endif %}
{% endif %}
{% if interface.ip_address %}
 ip address {{ interface.ip_address }} {{ interface.subnet_mask }}
{% endif %}
{% if interface.spanning_tree %}
{% for st_config in interface.spanning_tree %}
 spanning-tree {{ st_config }}
{% endfor %}
{% endif %}
{% if interface.shutdown is defined and not interface.shutdown %}
 no shutdown
{% else %}
 shutdown
{% endif %}
!
{% endfor %}
{% endif %}
!
{% if spanning_tree %}
! Spanning Tree Configuration
{% if spanning_tree.mode %}
spanning-tree mode {{ spanning_tree.mode }}
{% endif %}
{% if spanning_tree.priority %}
{% for vlan_id, priority in spanning_tree.priority.items() %}
spanning-tree vlan {{ vlan_id }} priority {{ priority }}
{% endfor %}
{% endif %}
{% endif %}
!
{% if management %}
! Management Configuration
{% if management.ip %}
interface vlan{{ management.vlan | default(1) }}
 ip address {{ management.ip }} {{ management.mask }}
 no shutdown
!
{% endif %}
{% if management.default_gateway %}
ip default-gateway {{ management.default_gateway }}
{% endif %}
{% if management.dns %}
{% for dns_server in management.dns %}
ip name-server {{ dns_server }}
{% endfor %}
{% endif %}
{% endif %}
!
line con 0
 logging synchronous
line vty 0 4
 login local
 transport input ssh
line vty 5 15
 login local
 transport input ssh
!
end
Subtask 2.2: Create Complex Device Data with Multiple Features
Create advanced switch data:
nano data/devices/switch1.yml
Add comprehensive switch configuration data:
hostname: "SW1-ACCESS"
device_type: "access_switch"
location: "Building A - Floor 1"
domain_name: "company.local"
enable_secret: "switch123"
generation_date: "2024-01-15"

users:
  - name: "admin"
    privilege: 15
    password: "admin123"
  - name: "operator"
    privilege: 5
    password: "oper456"

vlans:
  - id: 10
    name: "SALES"
    state: "active"
  - id: 20
    name: "ENGINEERING"
    state: "active"
  - id: 30
    name: "GUEST"
    state: "active"
  - id: 99
    name: "MANAGEMENT"
    state: "active"

interfaces:
  - name: "FastEthernet0/1"
    description: "Sales Department PC"
    switchport:
      mode: "access"
      access_vlan: 10
    spanning_tree:
      - "portfast"
      - "bpduguard enable"
    shutdown: false

  - name: "FastEthernet0/2"
    description: "Engineering Workstation"
    switchport:
      mode: "access"
      access_vlan: 20
    spanning_tree:
      - "portfast"
      - "bpduguard enable"
    shutdown: false

  - name: "FastEthernet0/24"
    description: "Trunk to Core Switch"
    switchport:
      mode: "trunk"
      trunk_vlans: [10, 20, 30, 99]
      native_vlan: 1
    shutdown: false

  - name: "GigabitEthernet0/1"
    description: "Uplink to Distribution"
    switchport:
      mode: "trunk"
      trunk_vlans: [10, 20, 30, 99]
      native_vlan: 1
    shutdown: false

spanning_tree:
  mode: "rapid-pvst"
  priority:
    10: 32768
    20: 32768
    30: 32768

management:
  vlan: 99
  ip: "192.168.99.10"
  mask: "255.255.255.0"
  default_gateway: "192.168.99.1"
  dns:
    - "8.8.8.8"
    - "8.8.4.4"
Subtask 2.3: Create a Multi-Vendor Template System
Let's create templates for different network device vendors.

Create a Juniper template:
nano templates/juniper/basic_router.j2
Add Juniper-specific template:
## Configuration for {{ hostname }}
## Generated on {{ generation_date }}
## Device Type: {{ device_type | default('Router') }}

system {
    host-name {{ hostname }};
{% if domain_name %}
    domain-name {{ domain_name }};
{% endif %}
{% if users %}
    login {
{% for user in users %}
        user {{ user.name }} {
            uid {{ user.uid | default(2000 + loop.index) }};
            class {{ user.class | default('operator') }};
            authentication {
                encrypted-password "{{ user.password }}";
            }
        }
{% endfor %}
    }
{% endif %}
    services {
        ssh;
        netconf {
            ssh;
        }
    }
}

{% if interfaces %}
interfaces {
{% for interface in interfaces %}
    {{ interface.name }} {
{% if interface.description %}
        description "{{ interface.description }}";
{% endif %}
{% if interface.unit is defined %}
        unit {{ interface.unit }} {
{% if interface.ip_address %}
            family inet {
                address {{ interface.ip_address }}/{{ interface.prefix_length }};
            }
{% endif %}
        }
{% endif %}
{% if interface.disable is defined and interface.disable %}
        disable;
{% endif %}
    }
{% endfor %}
}
{% endif %}

{% if routing_options %}
routing-options {
{% if routing_options.static_routes %}
{% for route in routing_options.static_routes %}
    static {
        route {{ route.destination }} next-hop {{ route.next_hop }};
    }
{% endfor %}
{% endif %}
{% if routing_options.router_id %}
    router-id {{ routing_options.router_id }};
{% endif %}
}
{% endif %}

{% if protocols %}
protocols {
{% if protocols.ospf %}
    ospf {
{% for area in protocols.ospf.areas %}
        area {{ area.id }} {
{% for interface in area.interfaces %}
            interface {{ interface }};
{% endfor %}
        }
{% endfor %}
    }
{% endif %}
}
{% endif %}
Create Juniper device data:
nano data/devices/juniper_router1.yml
hostname: "JR1-CORE"
device_type: "Core Router"
domain_name: "network.local"
generation_date: "2024-01-15"

users:
  - name: "netadmin"
    uid: 2001
    class: "super-user"
    password: "$1$abc123$xyz789"
  - name: "monitor"
    uid: 2002
    class: "read-only"
    password: "$1$def456$uvw012"

interfaces:
  - name: "ge-0/0/0"
    description: "LAN Interface"
    unit: 0
    ip_address: "192.168.1.1"
    prefix_length: 24
    disable: false

  - name: "ge-0/0/1"
    description: "WAN Interface"
    unit: 0
    ip_address: "10.0.0.1"
    prefix_length: 30
    disable: false

  - name: "ge-0/0/2"
    description: "Unused Interface"
    disable: true

routing_options:
  router_id: "1.1.1.1"
  static_routes:
    - destination: "0.0.0.0/0"
      next_hop: "10.0.0.2"
    - destination: "172.16.0.0/16"
      next_hop: "192.168.1.254"

protocols:
  ospf:
    areas:
      - id: "0.0.0.0"
        interfaces:
          - "ge-0/0/0.0"
          - "ge-0/0/1.0"
Subtask 2.4: Create an Enhanced Multi-Vendor Generator
Create an advanced generator script:
nano scripts/multi_vendor_generator.py
Add the enhanced generator code:
#!/usr/bin/env python3

import os
import yaml
import json
from jinja2 import Environment, FileSystemLoader
from datetime import datetime
import argparse

class ConfigurationGenerator:
    def __init__(self, base_dir):
        self.base_dir = base_dir
        self.templates_dir = os.path.join(base_dir, "templates")
        self.data_dir = os.path.join(base_dir, "data/devices")
        self.output_dir = os.path.join(base_dir, "output")
        
        # Ensure output directory exists
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Vendor to template mapping
        self.vendor_templates = {
            'cisco': {
                'router': 'cisco/basic_router.j2',
                'switch': 'cisco/advanced_switch.j2'
            },
            'juniper': {
                'router': 'juniper/basic_router.j2'
            }
        }

    def load_device_data(self, data_file):
        """Load device data from YAML file"""
        try:
            with open(data_file, 'r') as file:
                data = yaml.safe_load(file)
                
            # Add generation timestamp if not present
            if 'generation_date' not in data:
                data['generation_date'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                
            return data
        except FileNotFoundError:
            print(f"Error: Data file {data_file} not found")
            return None
        except yaml.YAMLError as e:
            print(f"Error parsing YAML file: {e}")
            return None

    def get_template_path(self, vendor, device_type):
        """Get template path based on vendor and device type"""
        vendor = vendor.lower()
        device_type = device_type.lower()
        
        if vendor in self.vendor_templates:
            if device_type in self.vendor_templates[vendor]:
                return self.vendor_templates[vendor][device_type]
            else:
                # Default to router template if device type not found
                return self.vendor_templates[vendor].get('router')
        
        return None

    def generate_configuration(self, template_path, data, output_file):
        """Generate configuration using Jinja2 template"""
        try:
            template_full_path = os.path.join(self.templates_dir, template_path)
            template_dir = os.path.dirname(template_full_path)
            template_name = os.path.basename(template_full_path)
            
            # Set up Jinja2 environment with custom filters
            env = Environment(
                loader=FileSystemLoader(template_dir),
                trim_blocks=True,
                lstrip_blocks=True
            )
            
            # Add custom filters
            env.filters['subnet_mask_to_cidr'] = self.subnet_mask_to_cidr
            env.filters['cidr_to_subnet_mask'] = self.cidr_to_subnet_mask
            
            # Load and render template
            template = env.get_template(template_name)
            config = template.render(data)
            
            # Write to output file
            with open(output_file, 'w') as file:
                file.write(config)
            
            print(f"✓ Configuration generated: {output_file}")
            return True
            
        except Exception as e:
            print(f"✗ Error generating configuration: {e}")
            return False

    def subnet_mask_to_cidr(self, subnet_mask):
        """Convert subnet mask to CIDR notation"""
        cidr_map = {
            '255.255.255.255': 32, '255.255.255.254': 31, '255.255.255.252': 30,
            '255.255.255.248': 29, '255.255.255.240': 28, '255.255.255.224': 27,
            '255.255.255.192': 26, '255.255.255.128': 25, '255.255.255.0': 24,
            '255.255.254.0': 23, '255.255.252.0': 22, '255.255.248.0': 21,
            '255.255.240.0': 20, '255.255.224.0': 19, '255.255.192.0': 18,
            '255.255.128.0': 17, '255.255.0.0': 16, '255.254.0.0': 15,
            '255.252.0.0': 14, '255.248.0.0': 13, '255.240.0.0': 12,
            '255.224.0.0': 11, '255.192.0.0': 10, '255.128.0.0': 9,
            '255.0.0.0': 8, '254.0.0.0': 7, '252.0.0.0': 6,
            '248.0.0.0': 5, '240.0.0.0': 4, '224.0.0.0': 3,
            '192.0.0.0': 2, '128.0.0.0': 1, '0.0.0.0': 0
        }
        return cidr_map.get(subnet_mask, 24)

    def cidr_to_subnet_mask(self, cidr):
        """Convert CIDR to subnet mask"""
        mask_map = {
            32: '255.255.255.255', 31: '255.255.255.254', 30: '255.255.255.252',
            29: '255.255.255.248', 28: '255.255.255.240', 27: '255.255.255.224',
            26: '255.255.255.192', 25: '255.255.255.128', 24: '255.255.255.0',
            23: '255.255.254.0', 22: '255.255.252.0', 21: '255.255.248.0',
            20: '255.255.240.0', 19: '255.255.224.0', 18: '255.255.192.0',
            17: '255.255.128.0', 16: '255.255.0.0', 15: '255.254.0.0',
            14: '255.252.0.0', 13: '255.248.0.0', 12: '255.240.0.0',
            11: '255.224.0.0', 10: '255.192.0.0', 9: '255.128.0.0',
            8: '255.0.0.0', 7: '254.0.0.0', 6: '252.0.0.0',
            5: '248.0.0.0', 4: '240.0.0.0', 3: '224.0.0.0',
            2: '192.0.0.0', 1: '128.0.0.0', 0: '0.0.0.0'
        }
        return mask_map.get(cidr, '255.255.255.0')

    def process_device(self, data_file):
        """Process a single device data file"""
        print(f"\n📋 Processing {os.path.basename(data_file)}...")
        
        # Load device data
        device_data = self.load_device_data(data_file)
        if not device_data:
            return False
        
        # Determine vendor and device type
        vendor = device_data.get('vendor', 'cisco')
        device_type = device_data.get('device_type', 'router')
        
        print(f"   Vendor: {vendor.title()}")
        print(f"   Device Type: {device_type.title()}")
        
        # Get appropriate template
        template_path = self.get_template_path(vendor, device_type)
        if not template_path:
            print(f"   ✗ No template found for {vendor} {device_type}")
            return False
        
        print(f"   Template: {template_path}")
        
        # Generate output filename
        device_name = os.path.splitext(os.path.basename(data_file))[0]
        output_file = os.path.join(self.output_dir, f"{device_name}_config.txt")
        
        # Generate configuration
        return self.generate_configuration(template_path, device_data, output_file)

    def process_all_devices(self):
        """Process all device data files"""
        print("🚀 Starting configuration generation...")
        
        success_count = 0
        total_count = 0
        
        for filename in os.listdir(self.data_dir):
            if filename.endswith('.yml') or filename.endswith('.yaml'):
                total_count += 1
                data_file = os.path.join(self.data_dir, filename)
                
                if self.process_device(data_file):
                    success_count += 1
        
        print(f"\n📊 Summary:")
        print(f"   Total devices: {total_count}")
        print(f"   Successful: {success_count}")
        print(f"   Failed: {total_count - success_count}")
        
        return success_count == total_count

def main():
    parser = argparse.ArgumentParser(description='Multi-vendor network configuration generator')
    parser.add_argument('--device', help='Process specific device file')
    parser.add_argument('--list', action='store_true', help='List available device files')
    
    args = parser.parse_args()
    
    # Get base directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.dirname(script_dir)
    
    generator = ConfigurationGenerator(base_dir)
    
    if args.list:
        print("📁 Available device files:")
        for filename in os.listdir(generator.data_dir):
            if filename.endswith('.yml') or filename.endswith('.yaml'):
                print(f"   - {filename}")
        return
    
    if args.device:
        device_file = os.path.join(generator.data_dir, args.device)
        if os.path.exists(device_file):
            generator.process_device(device_file)
        else:
            print(f"Error: Device file {args.device} not found")
    else:
        generator.process_all_devices()

if __name__ == "__main__":
    main()
Make the script executable and test it:
chmod +x scripts/multi_vendor_generator.py
Update device data to include vendor information:
nano data/devices/router1.yml
Add these lines at the top:

vendor: "cisco"
device_type: "router"
Update switch data:
nano data/devices/switch1.yml
Add these lines at the top:

vendor: "cisco"
device_type: "switch"
Update Juniper data:
nano data/devices/juniper_router1.yml
Add these lines at the top:

vendor: "juniper"
device_type: "router"
Subtask 2.5: Test the Multi-Vendor Generator
List available devices:
cd ~/jinja2-lab
python3 scripts/multi_vendor_generator.py --list
Generate configurations for all devices:
python3 scripts/multi_vendor_generator.py
Generate configuration for a specific device:
python3 scripts/multi_vendor_generator.py --device switch1.yml
Verify the generated configurations:
ls -la output/
echo "=== Cisco Router Configuration ==="
head -20 output/router1_config.txt
echo -e "\n=== Cisco Switch Configuration ==="
head -20 output/switch1_config.txt
echo -e "\n=== Juniper Router Configuration ==="
head -20 output/juniper_router1_config.txt
Subtask 2.6: Create Template Inheritance and Macros
Let's create reusable template components
