Lab 12: Managing Satellite Using the API
Objectives
By the end of this lab, you will be able to:

• Authenticate and interact with the Red Hat Satellite REST API • Use API endpoints to retrieve system information and manage resources • Automate host registration using Python scripts and API calls • Create automated tasks for software deployment via the Satellite API • Implement configuration management workflows through API automation • Troubleshoot common API authentication and connectivity issues

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Linux command line operations • Familiarity with Red Hat Satellite 6 concepts (hosts, content views, activation keys) • Basic knowledge of REST APIs and HTTP methods • Understanding of JSON data format • Basic Python scripting knowledge (helpful but not required) • Access to a Red Hat Satellite 6 server with administrative privileges

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes: • Red Hat Satellite 6 server (satellite.example.com) • Client systems for testing host registration • Pre-installed Python 3 with required libraries • Sample scripts and configuration files

Task 1: Authenticate and Interact with the API
Subtask 1.1: Understanding Satellite API Basics
The Red Hat Satellite API is a RESTful web service that allows you to manage your Satellite infrastructure programmatically. It uses standard HTTP methods and returns data in JSON format.

Key API Concepts: • Base URL: https://satellite.example.com/api/v2/ • Authentication: Uses basic HTTP authentication or OAuth • Content-Type: Application/JSON for most requests • HTTP Methods: GET (retrieve), POST (create), PUT (update), DELETE (remove)

Subtask 1.2: Set Up API Authentication
First, let's establish authentication credentials and test basic connectivity.

Create API user credentials file:
# Create a secure credentials file
mkdir -p ~/satellite-api
cd ~/satellite-api

# Create credentials file (replace with your actual credentials)
cat > credentials.txt << EOF
SATELLITE_URL=https://satellite.example.com
SATELLITE_USER=admin
SATELLITE_PASSWORD=redhat123
EOF

# Secure the credentials file
chmod 600 credentials.txt
Test basic API connectivity using curl:
# Source the credentials
source credentials.txt

# Test API connectivity
curl -k -u "${SATELLITE_USER}:${SATELLITE_PASSWORD}" \
  -H "Accept: application/json" \
  "${SATELLITE_URL}/api/v2/status"
Expected Output: You should see JSON response with Satellite status information including version, database status, and plugin information.

Subtask 1.3: Create Python API Client Script
Create a reusable Python script for API interactions:

#!/usr/bin/env python3
"""
Satellite API Client
A simple client for interacting with Red Hat Satellite API
"""

import requests
import json
import sys
import os
from urllib3.exceptions import InsecureRequestWarning

# Disable SSL warnings for lab environment
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

class SatelliteAPI:
    def __init__(self, url, username, password):
        self.base_url = url.rstrip('/') + '/api/v2'
        self.auth = (username, password)
        self.headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        }
    
    def get(self, endpoint, params=None):
        """Make GET request to API endpoint"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        try:
            response = requests.get(url, auth=self.auth, headers=self.headers, 
                                  params=params, verify=False)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"API GET Error: {e}")
            return None
    
    def post(self, endpoint, data=None):
        """Make POST request to API endpoint"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        try:
            response = requests.post(url, auth=self.auth, headers=self.headers,
                                   data=json.dumps(data) if data else None, 
                                   verify=False)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"API POST Error: {e}")
            return None
    
    def put(self, endpoint, data=None):
        """Make PUT request to API endpoint"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        try:
            response = requests.put(url, auth=self.auth, headers=self.headers,
                                  data=json.dumps(data) if data else None, 
                                  verify=False)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"API PUT Error: {e}")
            return None
    
    def delete(self, endpoint):
        """Make DELETE request to API endpoint"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        try:
            response = requests.delete(url, auth=self.auth, headers=self.headers, 
                                     verify=False)
            response.raise_for_status()
            return True
        except requests.exceptions.RequestException as e:
            print(f"API DELETE Error: {e}")
            return False

def main():
    # Load credentials from environment or file
    satellite_url = os.getenv('SATELLITE_URL', 'https://satellite.example.com')
    satellite_user = os.getenv('SATELLITE_USER', 'admin')
    satellite_password = os.getenv('SATELLITE_PASSWORD', 'redhat123')
    
    # Initialize API client
    api = SatelliteAPI(satellite_url, satellite_user, satellite_password)
    
    # Test connection
    print("Testing Satellite API connection...")
    status = api.get('/status')
    if status:
        print(f"✓ Connected to Satellite {status.get('version', 'Unknown')}")
        print(f"✓ Database: {status.get('database', {}).get('active', 'Unknown')}")
    else:
        print("✗ Failed to connect to Satellite API")
        sys.exit(1)

if __name__ == "__main__":
    main()
Save and test the API client:
# Save the script
cat > satellite_api_client.py << 'EOF'
[Insert the Python script from above]
EOF

# Make it executable
chmod +x satellite_api_client.py

# Test the client
python3 satellite_api_client.py
Subtask 1.4: Explore Common API Endpoints
Let's explore some frequently used API endpoints:

# List all organizations
curl -k -u "${SATELLITE_USER}:${SATELLITE_PASSWORD}" \
  -H "Accept: application/json" \
  "${SATELLITE_URL}/api/v2/organizations"

# List all hosts
curl -k -u "${SATELLITE_USER}:${SATELLITE_PASSWORD}" \
  -H "Accept: application/json" \
  "${SATELLITE_URL}/api/v2/hosts"

# List content views
curl -k -u "${SATELLITE_USER}:${SATELLITE_PASSWORD}" \
  -H "Accept: application/json" \
  "${SATELLITE_URL}/api/v2/content_views"

# List activation keys
curl -k -u "${SATELLITE_USER}:${SATELLITE_PASSWORD}" \
  -H "Accept: application/json" \
  "${SATELLITE_URL}/api/v2/activation_keys"
Task 2: Automate Host Registration Using Scripts
Subtask 2.1: Create Host Registration Script
Create a comprehensive script to automate host registration:

#!/usr/bin/env python3
"""
Automated Host Registration Script
Registers hosts with Red Hat Satellite using API
"""

import requests
import json
import sys
import os
import argparse
from urllib3.exceptions import InsecureRequestWarning

# Disable SSL warnings
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

class HostRegistration:
    def __init__(self, satellite_url, username, password):
        self.base_url = satellite_url.rstrip('/') + '/api/v2'
        self.auth = (username, password)
        self.headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        }
    
    def get_organization_id(self, org_name):
        """Get organization ID by name"""
        response = requests.get(
            f"{self.base_url}/organizations",
            auth=self.auth,
            headers=self.headers,
            verify=False
        )
        
        if response.status_code == 200:
            orgs = response.json()['results']
            for org in orgs:
                if org['name'] == org_name:
                    return org['id']
        return None
    
    def get_location_id(self, location_name):
        """Get location ID by name"""
        response = requests.get(
            f"{self.base_url}/locations",
            auth=self.auth,
            headers=self.headers,
            verify=False
        )
        
        if response.status_code == 200:
            locations = response.json()['results']
            for location in locations:
                if location['name'] == location_name:
                    return location['id']
        return None
    
    def get_hostgroup_id(self, hostgroup_name):
        """Get hostgroup ID by name"""
        response = requests.get(
            f"{self.base_url}/hostgroups",
            auth=self.auth,
            headers=self.headers,
            verify=False
        )
        
        if response.status_code == 200:
            hostgroups = response.json()['results']
            for hg in hostgroups:
                if hg['name'] == hostgroup_name:
                    return hg['id']
        return None
    
    def create_activation_key(self, name, org_id, content_view_id=None, lifecycle_env_id=None):
        """Create activation key for host registration"""
        activation_key_data = {
            "activation_key": {
                "name": name,
                "organization_id": org_id,
                "content_view_id": content_view_id,
                "lifecycle_environment_id": lifecycle_env_id,
                "unlimited_hosts": True
            }
        }
        
        response = requests.post(
            f"{self.base_url}/activation_keys",
            auth=self.auth,
            headers=self.headers,
            data=json.dumps(activation_key_data),
            verify=False
        )
        
        if response.status_code == 201:
            return response.json()
        else:
            print(f"Failed to create activation key: {response.text}")
            return None
    
    def register_host(self, hostname, ip_address, mac_address, org_name, location_name, hostgroup_name=None):
        """Register a new host with Satellite"""
        
        # Get required IDs
        org_id = self.get_organization_id(org_name)
        location_id = self.get_location_id(location_name)
        
        if not org_id:
            print(f"Organization '{org_name}' not found")
            return False
        
        if not location_id:
            print(f"Location '{location_name}' not found")
            return False
        
        # Prepare host data
        host_data = {
            "host": {
                "name": hostname,
                "ip": ip_address,
                "mac": mac_address,
                "organization_id": org_id,
                "location_id": location_id,
                "managed": True,
                "enabled": True
            }
        }
        
        # Add hostgroup if specified
        if hostgroup_name:
            hostgroup_id = self.get_hostgroup_id(hostgroup_name)
            if hostgroup_id:
                host_data["host"]["hostgroup_id"] = hostgroup_id
        
        # Create the host
        response = requests.post(
            f"{self.base_url}/hosts",
            auth=self.auth,
            headers=self.headers,
            data=json.dumps(host_data),
            verify=False
        )
        
        if response.status_code == 201:
            host_info = response.json()
            print(f"✓ Host '{hostname}' registered successfully")
            print(f"  Host ID: {host_info['id']}")
            print(f"  FQDN: {host_info['name']}")
            return True
        else:
            print(f"✗ Failed to register host '{hostname}': {response.text}")
            return False
    
    def bulk_register_hosts(self, hosts_file):
        """Register multiple hosts from CSV file"""
        try:
            with open(hosts_file, 'r') as f:
                # Skip header line
                next(f)
                
                for line_num, line in enumerate(f, 2):
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue
                    
                    try:
                        hostname, ip_address, mac_address, org_name, location_name, hostgroup_name = line.split(',')
                        
                        print(f"\nRegistering host {line_num-1}: {hostname}")
                        success = self.register_host(
                            hostname.strip(),
                            ip_address.strip(),
                            mac_address.strip(),
                            org_name.strip(),
                            location_name.strip(),
                            hostgroup_name.strip() if hostgroup_name.strip() else None
                        )
                        
                        if not success:
                            print(f"Failed to register host on line {line_num}")
                    
                    except ValueError:
                        print(f"Invalid format on line {line_num}: {line}")
                        continue
        
        except FileNotFoundError:
            print(f"Hosts file '{hosts_file}' not found")
            return False
        
        return True

def main():
    parser = argparse.ArgumentParser(description='Automate host registration with Satellite')
    parser.add_argument('--hostname', help='Single host to register')
    parser.add_argument('--ip', help='IP address of the host')
    parser.add_argument('--mac', help='MAC address of the host')
    parser.add_argument('--org', help='Organization name')
    parser.add_argument('--location', help='Location name')
    parser.add_argument('--hostgroup', help='Hostgroup name (optional)')
    parser.add_argument('--bulk-file', help='CSV file for bulk registration')
    
    args = parser.parse_args()
    
    # Load credentials
    satellite_url = os.getenv('SATELLITE_URL', 'https://satellite.example.com')
    satellite_user = os.getenv('SATELLITE_USER', 'admin')
    satellite_password = os.getenv('SATELLITE_PASSWORD', 'redhat123')
    
    # Initialize registration client
    reg_client = HostRegistration(satellite_url, satellite_user, satellite_password)
    
    if args.bulk_file:
        print(f"Starting bulk host registration from {args.bulk_file}")
        reg_client.bulk_register_hosts(args.bulk_file)
    elif args.hostname and args.ip and args.mac and args.org and args.location:
        print(f"Registering single host: {args.hostname}")
        reg_client.register_host(
            args.hostname, args.ip, args.mac, 
            args.org, args.location, args.hostgroup
        )
    else:
        print("Please provide either single host parameters or bulk file")
        parser.print_help()

if __name__ == "__main__":
    main()
Subtask 2.2: Create Sample Host Data File
Create a CSV file with sample host data for bulk registration:

# Create sample hosts data file
cat > hosts_to_register.csv << EOF
hostname,ip_address,mac_address,organization,location,hostgroup
webserver01.example.com,192.168.1.10,00:50:56:12:34:56,Default Organization,Default Location,Web Servers
webserver02.example.com,192.168.1.11,00:50:56:12:34:57,Default Organization,Default Location,Web Servers
dbserver01.example.com,192.168.1.20,00:50:56:12:34:58,Default Organization,Default Location,Database Servers
appserver01.example.com,192.168.1.30,00:50:56:12:34:59,Default Organization,Default Location,Application Servers
EOF
Subtask 2.3: Test Host Registration
Save the registration script:
# Save the host registration script
cat > host_registration.py << 'EOF'
[Insert the Python script from Subtask 2.1]
EOF

chmod +x host_registration.py
Test single host registration:
# Register a single host
python3 host_registration.py \
  --hostname testhost01.example.com \
  --ip 192.168.1.100 \
  --mac 00:50:56:12:34:60 \
  --org "Default Organization" \
  --location "Default Location"
Test bulk host registration:
# Register multiple hosts from CSV file
python3 host_registration.py --bulk-file hosts_to_register.csv
Subtask 2.4: Create Host Registration Verification Script
Create a script to verify successful host registration:

#!/usr/bin/env python3
"""
Host Registration Verification Script
Verifies hosts are properly registered in Satellite
"""

import requests
import json
import os
from urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

def verify_host_registration(satellite_url, username, password, hostname):
    """Verify if a host is registered in Satellite"""
    
    base_url = satellite_url.rstrip('/') + '/api/v2'
    auth = (username, password)
    headers = {'Accept': 'application/json'}
    
    # Search for the host
    params = {'search': f'name={hostname}'}
    response = requests.get(
        f"{base_url}/hosts",
        auth=auth,
        headers=headers,
        params=params,
        verify=False
    )
    
    if response.status_code == 200:
        hosts = response.json()['results']
        if hosts:
            host = hosts[0]
            print(f"✓ Host '{hostname}' found in Satellite")
            print(f"  ID: {host['id']}")
            print(f"  IP: {host.get('ip', 'N/A')}")
            print(f"  MAC: {host.get('mac', 'N/A')}")
            print(f"  Organization: {host.get('organization_name', 'N/A')}")
            print(f"  Location: {host.get('location_name', 'N/A')}")
            print(f"  Last Report: {host.get('last_report', 'Never')}")
            return True
        else:
            print(f"✗ Host '{hostname}' not found in Satellite")
            return False
    else:
        print(f"✗ Error searching for host: {response.text}")
        return False

def main():
    # Load credentials
    satellite_url = os.getenv('SATELLITE_URL', 'https://satellite.example.com')
    satellite_user = os.getenv('SATELLITE_USER', 'admin')
    satellite_password = os.getenv('SATELLITE_PASSWORD', 'redhat123')
    
    # Test hosts from our registration
    test_hosts = [
        'testhost01.example.com',
        'webserver01.example.com',
        'webserver02.example.com',
        'dbserver01.example.com',
        'appserver01.example.com'
    ]
    
    print("Verifying host registrations...\n")
    
    for hostname in test_hosts:
        verify_host_registration(satellite_url, satellite_user, satellite_password, hostname)
        print()

if __name__ == "__main__":
    main()
# Save and run the verification script
cat > verify_registration.py << 'EOF'
[Insert the verification script from above]
EOF

chmod +x verify_registration.py
python3 verify_registration.py
Task 3: Create Automated Tasks for Software Deployment via the API
Subtask 3.1: Create Software Package Deployment Script
Create a comprehensive script for automated software deployment:

#!/usr/bin/env python3
"""
Automated Software Deployment Script
Deploy software packages to hosts using Satellite API
"""

import requests
import json
import sys
import os
import time
import argparse
from urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

class SoftwareDeployment:
    def __init__(self, satellite_url, username, password):
        self.base_url = satellite_url.rstrip('/') + '/api/v2'
        self.auth = (username, password)
        self.headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        }
    
    def get_host_id(self, hostname):
        """Get host ID by hostname"""
        params = {'search': f'name={hostname}'}
        response = requests.get(
            f"{self.base_url}/hosts",
            auth=self.auth,
            headers=self.headers,
            params=params,
            verify=False
        )
        
        if response.status_code == 200:
            hosts = response.json()['results']
            if hosts:
                return hosts[0]['id']
        return None
    
    def get_host_group_hosts(self, hostgroup_name):
        """Get all hosts in a hostgroup"""
        params = {'search': f'hostgroup={hostgroup_name}'}
        response = requests.get(
            f"{self.base_url}/hosts",
            auth=self.auth,
            headers=self.headers,
            params=params,
            verify=False
        )
        
        if response.status_code == 200:
            return response.json()['results']
        return []
    
    def install_packages(self, host_ids, packages):
        """Install packages on specified hosts"""
        if isinstance(host_ids, int):
            host_ids = [host_ids]
        
        job_data = {
            "job_invocation": {
                "job_template_name": "Package Action - Katello Script Default",
                "inputs": {
                    "action": "install",
                    "package": " ".join(packages)
                },
                "targeting_type": "static_query",
                "search_query": f"id ^ ({','.join(map(str, host_ids))})"
            }
        }
        
        response = requests.post(
            f"{self.base_url}/job_invocations",
            auth=self.auth,
            headers=self.headers,
            data=json.dumps(job_data),
            verify=False
        )
        
        if response.status_code == 201:
            job = response.json()
            print(f"✓ Package installation job created: {job['id']}")
            return job['id']
        else:
            print(f"✗ Failed to create package installation job: {response.text}")
            return None
    
    def update_packages(self, host_ids, packages=None):
        """Update packages on specified hosts"""
        if isinstance(host_ids, int):
            host_ids = [host_ids]
        
        job_data = {
            "job_invocation": {
                "job_template_name": "Package Action - Katello Script Default",
                "inputs": {
                    "action": "update",
                    "package": " ".join(packages) if packages else ""
                },
                "targeting_type": "static_query",
                "search_query": f"id ^ ({','.join(map(str, host_ids))})"
            }
        }
        
        response = requests.post(
            f"{self.base_url}/job_invocations",
            auth=self.auth,
            headers=self.headers,
            data=json.dumps(job_data),
            verify=False
        )
        
        if response.status_code == 201:
            job = response.json()
            print(f"✓ Package update job created: {job['id']}")
            return job['id']
        else:
            print(f"✗ Failed to create package update job: {response.text}")
            return None
    
    def run_custom_command(self, host_ids, command):
        """Run custom command on specified hosts"""
        if isinstance(host_ids, int):
            host_ids = [host_ids]
        
        job_data = {
            "job_invocation": {
                "job_template_name": "Run Command - Katello Script Default",
                "inputs": {
                    "command": command
                },
                "targeting_type": "static_query",
                "search_query": f"id ^ ({','.join(map(str, host_ids))})"
            }
        }
        
        response = requests.post(
            f"{self.base_url}/job_invocations",
            auth=self.auth,
            headers=self.headers,
            data=json.dumps(job_data),
            verify=False
        )
        
        if response.status_code == 201:
            job = response.json()
            print(f"✓ Custom command job created: {job['id']}")
            return job['id']
        else:
            print(f"✗ Failed to create custom command job: {response.text}")
            return None
    
    def get_job_status(self, job_id):
        """Get job execution status"""
        response = requests.get(
            f"{self.base_url}/job_invocations/{job_id}",
            auth=self.auth,
            headers=self.headers,
            verify=False
        )
        
        if response.status_code == 200:
            job = response.json()
            return {
                'status': job.get('status_label', 'Unknown'),
                'progress': job.get('progress', 0),
                'succeeded': job.get('succeeded', 0),
                'failed': job.get('failed', 0),
                'pending': job.get('pending', 0)
            }
        return None
    
    def wait_for_job_completion(self, job_id, timeout=300):
        """Wait for job completion with timeout"""
        print(f"Waiting for job {job_id} to complete...")
        
        start_time = time.time()
        while time.time() - start_time < timeout:
            status = self.get_job_status(job_id)
            if status:
                print(f"Status: {status['status']} | Progress: {status['progress']}% | "
                      f"Success: {status['succeeded']} | Failed: {status['failed']} | "
                      f"Pending: {status['pending']}")
                
                if status['status'] in ['succeeded', 'failed']:
                    return status['status'] == 'succeeded'
            
            time.sleep(10)
        
        print(f"Job {job_id} timed out after {timeout} seconds")
        return False
    
    def deploy_software_package(self, deployment_config):
        """Deploy software based on configuration"""
        print(f"Starting software deployment: {deployment_config['name']}")
        
        # Get target hosts
        target_hosts = []
        
        if 'hostnames' in deployment_config:
            for hostname in deployment_config['hostnames']:
                host_id = self.get_host_id(hostname)
                if host_id:
                    target_hosts.append(host_id)
                    print(f"✓ Found host: {hostname} (ID: {host_id})")
                else:
                    print(f"✗ Host not found: {hostname}")
        
        if 'hostgroups' in deployment_config:
            for hostgroup in deployment_config['hostgroups']:
                hosts = self.get_host_group_hosts(hostgroup)
                for host in hosts:
                    target_hosts.append(host['id'])
                    print(f"✓ Found host in group '{hostgroup}': {host['name']} (ID: {host['id']})")
        
        if not target_hosts:
            print("✗ No target hosts found for deployment")
            return False
        
        print(f"Deploying to {len(target_hosts)} hosts")
        
        # Execute deployment steps
        for step in deployment_config.get('steps', []):
            print(f"\nExecuting step: {step['name']}")
            
            if step['type'] == 'install_packages':
                job_id = self.install_packages(target_hosts, step['packages'])
            elif step['type'] == 'update_packages':
                job_id = self.update_packages(target_hosts, step.get('packages'))
            elif step['type'] == 'run_command':
                job_id = self.run_custom_command(target_hosts, step['command'])
            else:
                print(f"Unknown step type: {step['type']}")
                continue
            
            if job_id:
                success = self.wait_for_job_completion(job_id)
                if not success:
                    print(f"✗ Step '{step['name']}' failed")
                    if step.get('critical', False):
                        print("Critical step failed, stopping deployment")
                        return False
                else:
                    print(f"✓ Step '{step['name']}' completed successfully")
            else:
                print(f"✗ Failed to create job for step '{step['name']}'")
                return False
        
        print(f"\n✓ Software deployment '{deployment_config['name']}' completed")
        return True

def main():
    parser = argparse.ArgumentParser(description='Automated software deployment via Satellite API')
    parser.add_argument('--config', required=True, help='Deployment configuration file (JSON)')
    
    args = parser.parse_args()
    
    # Load credentials
    satellite_url = os.getenv('SATELLITE_URL', 'https://satellite.example.com')
    satellite_user = os.getenv('SATELLITE_USER', 'admin')
    satellite_password = os.getenv('SATELLITE_PASSWORD', 'redhat123')
    
    # Initialize deployment client
    deploy_client = SoftwareDeployment(satellite_url, satellite_user, satellite_password)
    
    # Load deployment configuration
    try:
        with open(args.config, 'r') as f:
            deployment_config = json.load(f)
    except FileNotFoundError:
        print(f"Configuration file '{args.config}' not found")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in configuration file: {e}")
        sys.exit(1)
    
    # Execute deployment
    success = deploy_client.deploy_software_package(deployment_config)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
Subtask 3.2: Create Deployment Configuration Files
Create sample deployment configuration files for different scenarios:

Web Server Deployment Configuration:
cat > web_server_deployment.json << EOF
{
    "name": "Web Server Software Deployment",
    "description": "Deploy Apache web server and related packages",
    "hostgroups": ["Web Servers"],
    "hostnames": ["webserver01.example.com", "webserver02.example.com"],
    "steps": [
        {
            "name": "Update system packages",
