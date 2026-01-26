Lab 13: Deploying Red Hat Satellite on AWS
Objectives
By the end of this lab, students will be able to:

Deploy Red Hat Satellite 6 on Amazon Web Services (AWS) infrastructure
Configure proper networking and storage for Satellite server operations
Set up and register cloud-based content hosts to the Satellite server
Understand the architecture and components of Red Hat Satellite in cloud environments
Implement basic content management and host configuration using Satellite
Configure security groups and network access controls for Satellite deployment
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with AWS console and basic cloud concepts
Knowledge of Red Hat Enterprise Linux (RHEL) fundamentals
Understanding of package management and repository concepts
Basic networking knowledge (subnets, security groups, ports)
Access to Red Hat Customer Portal for subscription management
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure AWS accounts.

Your lab environment includes:

AWS account with appropriate permissions
Pre-configured VPC and subnets
Access to Red Hat Enterprise Linux AMIs
Necessary IAM roles and policies
Task 1: Launch Red Hat Satellite on AWS
Subtask 1.1: Prepare AWS Environment
Access AWS Console

Log into the AWS Management Console using your provided credentials
Navigate to the EC2 service dashboard
Ensure you are in the correct AWS region (us-east-1 recommended)
Create Key Pair for SSH Access

# From AWS CLI (if available) or use AWS Console
aws ec2 create-key-pair --key-name satellite-lab-key --query 'KeyMaterial' --output text > satellite-lab-key.pem
chmod 400 satellite-lab-key.pem
Verify VPC and Subnet Configuration

Navigate to VPC service in AWS Console
Confirm default VPC exists with public subnet
Note the subnet ID for later use
Subtask 1.2: Launch Satellite Server Instance
Select Red Hat Enterprise Linux AMI

In EC2 Console, click Launch Instance
Search for Red Hat Enterprise Linux 8 in AMI catalog
Select the latest RHEL 8 AMI (ensure it's 64-bit)
Configure Instance Details

Instance Type: Select m5.xlarge (minimum recommended)
Network: Use default VPC
Subnet: Select public subnet
Auto-assign Public IP: Enable
IAM Role: Create or select role with EC2 permissions
Configure Storage

Root Volume: 100 GB GP3 SSD
Additional Volume: 500 GB GP3 SSD for Satellite data
Ensure both volumes are encrypted
Configure Security Group

# Create security group rules for Satellite
# HTTP (80), HTTPS (443), SSH (22), Satellite-specific ports
Create security group with these inbound rules:

SSH (22): Your IP address
HTTP (80): 0.0.0.0/0
HTTPS (443): 0.0.0.0/0
Port 5647: 0.0.0.0/0 (Satellite client communication)
Port 8140: 0.0.0.0/0 (Puppet)
Port 9090: Your IP address (Cockpit web console)
Launch Instance

Review configuration
Select your key pair
Launch the instance
Wait for instance to reach running state
Subtask 1.3: Initial Server Configuration
Connect to Satellite Server

# Connect via SSH
ssh -i satellite-lab-key.pem ec2-user@<PUBLIC_IP_ADDRESS>

# Switch to root user
sudo su -
Update System and Install Prerequisites

# Update system packages
dnf update -y

# Install required packages
dnf install -y chrony wget curl

# Configure time synchronization
systemctl enable --now chronyd
Configure Hostname and Hosts File

# Set hostname
hostnamectl set-hostname satellite.example.com

# Update /etc/hosts
echo "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) satellite.example.com satellite" >> /etc/hosts
Prepare Additional Storage

# List available disks
lsblk

# Create partition on additional disk (assuming /dev/nvme1n1)
fdisk /dev/nvme1n1
# Press 'n' for new partition, accept defaults, press 'w' to write

# Create filesystem
mkfs.xfs /dev/nvme1n1p1

# Create mount point and mount
mkdir -p /var/lib/pulp
echo "/dev/nvme1n1p1 /var/lib/pulp xfs defaults 0 0" >> /etc/fstab
mount -a
Task 2: Configure Networking and Storage
Subtask 2.1: Configure Firewall Rules
Configure System Firewall
# Install and enable firewalld
dnf install -y firewalld
systemctl enable --now firewalld

# Add Satellite services to firewall
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh

# Add Satellite-specific ports
firewall-cmd --permanent --add-port=5647/tcp  # Satellite client
firewall-cmd --permanent --add-port=8140/tcp  # Puppet
firewall-cmd --permanent --add-port=9090/tcp  # Cockpit
firewall-cmd --permanent --add-port=53/udp    # DNS
firewall-cmd --permanent --add-port=53/tcp    # DNS
firewall-cmd --permanent --add-port=67/udp    # DHCP
firewall-cmd --permanent --add-port=69/udp    # TFTP

# Reload firewall rules
firewall-cmd --reload

# Verify rules
firewall-cmd --list-all
Subtask 2.2: Install and Configure Satellite
Register System with Red Hat

# Register with Red Hat Subscription Management
subscription-manager register --username <your_rh_username> --password <your_rh_password>

# Attach Satellite subscription
subscription-manager attach --pool=<satellite_pool_id>

# Enable required repositories
subscription-manager repos --disable="*"
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms
subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms
subscription-manager repos --enable=satellite-6.12-for-rhel-8-x86_64-rpms
subscription-manager repos --enable=satellite-maintenance-6.12-for-rhel-8-x86_64-rpms
Install Satellite Packages

# Update system with new repositories
dnf update -y

# Install Satellite
dnf install -y satellite

# Verify installation
rpm -qa | grep satellite
Run Satellite Installer ```bash # Create installer answer file cat > /etc/foreman-installer/scenarios.d/satellite-answers.yaml << EOF
certs: generate: true deploy: true foreman: initial_admin_username: admin initial_admin_password: RedHat123! initial_organization: "Default Organization" initial_location: "Default Location" EOF

Run Satellite installer
satellite-installer --scenario satellite
--foreman-initial-admin-username admin
--foreman-initial-admin-password 'RedHat123!'
--foreman-initial-organization "Default Organization"
--foreman-initial-location "Default Location"


Verify Satellite Installation

# Check Satellite services
systemctl status foreman

# Verify web interface accessibility
curl -k https://localhost/users/login

# Check Satellite version
satellite-maintain service status
Subtask 2.3: Configure SSL Certificates
Generate Self-Signed Certificates (for lab purposes)

# Satellite installer should have generated certificates
# Verify certificate location
ls -la /etc/pki/katello/certs/

# Check certificate validity
openssl x509 -in /etc/pki/katello/certs/katello-apache.crt -text -noout
Configure Certificate Trust

# Copy CA certificate for client trust
cp /etc/pki/katello/certs/katello-server-ca.crt /var/www/html/pub/

# Set proper permissions
chmod 644 /var/www/html/pub/katello-server-ca.crt
Task 3: Set Up Cloud-Based Content Hosts
Subtask 3.1: Launch Content Host Instances
Create Content Host Security Group

In AWS Console, create new security group named satellite-content-hosts
Add inbound rules:
SSH (22): Satellite server IP
Port 5647: Satellite server IP
ICMP: Satellite server IP
Launch Content Host Instances

# Launch 2 RHEL instances for content hosts
# Use t3.medium instance type
# Use same key pair as Satellite server
# Place in same subnet as Satellite server
Configure Content Host Instances

# Connect to each content host
ssh -i satellite-lab-key.pem ec2-user@<CONTENT_HOST_IP>

# Switch to root
sudo su -

# Update system
dnf update -y

# Set hostname
hostnamectl set-hostname contenthost1.example.com  # or contenthost2.example.com

# Update hosts file
echo "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) $(hostname)" >> /etc/hosts
echo "<SATELLITE_PRIVATE_IP> satellite.example.com satellite" >> /etc/hosts
Subtask 3.2: Configure Satellite for Content Management
Access Satellite Web Interface

Open web browser and navigate to https://<SATELLITE_PUBLIC_IP>
Login with username: admin and password: RedHat123!
Accept any SSL certificate warnings
Create Organization and Location

# Using Satellite CLI (hammer)
hammer organization create --name "Lab Organization" --description "Lab Environment"
hammer location create --name "AWS East" --description "AWS us-east-1 region"
Configure Content Credentials

Navigate to Content > Content Credentials
Create GPG key for Red Hat repositories
Upload Red Hat GPG key content
Create Products and Repositories

# Create custom product
hammer product create --name "RHEL 8" --organization "Lab Organization"

# Create repository
hammer repository create \
  --name "RHEL 8 BaseOS" \
  --product "RHEL 8" \
  --content-type "yum" \
  --url "https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os" \
  --organization "Lab Organization"
Subtask 3.3: Register Content Hosts
Generate Registration Command

In Satellite web interface, navigate to Hosts > Registration
Select organization and location
Generate registration command
Install Satellite CA Certificate on Content Hosts

# On each content host
curl -k https://<SATELLITE_IP>/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/satellite-ca.crt
update-ca-trust
Register Content Hosts

# Download and install katello-ca-consumer package
rpm -Uvh https://<SATELLITE_IP>/pub/katello-ca-consumer-latest.noarch.rpm

# Register with Satellite
subscription-manager register \
  --org="Lab_Organization" \
  --activationkey="default_key" \
  --serverurl=https://satellite.example.com:443/rhsm \
  --baseurl=https://satellite.example.com/pulp/repos
Verify Registration

# Check subscription status
subscription-manager status

# List available repositories
subscription-manager repos --list

# In Satellite web interface, verify hosts appear under Hosts > All Hosts
Subtask 3.4: Configure Host Collections and Activation Keys
Create Activation Keys

# Create activation key using hammer
hammer activation-key create \
  --name "rhel8-key" \
  --organization "Lab Organization" \
  --lifecycle-environment "Library" \
  --content-view "Default Organization View"
Create Host Collections

# Create host collection
hammer host-collection create \
  --name "Web Servers" \
  --description "Collection of web server hosts" \
  --organization "Lab Organization"

# Add hosts to collection
hammer host-collection add-host \
  --name "Web Servers" \
  --host-ids 1,2 \
  --organization "Lab Organization"
Configure Content Views

Navigate to Content > Content Views
Create new content view named "RHEL 8 Standard"
Add repositories to content view
Publish content view
Promote to lifecycle environments
Troubleshooting Tips
Common Issues and Solutions
Satellite Installation Fails

# Check system requirements
free -h  # Ensure minimum 20GB RAM
df -h    # Ensure sufficient disk space

# Check logs
tail -f /var/log/foreman-installer/satellite.log
Content Host Registration Fails

# Verify network connectivity
telnet <SATELLITE_IP> 443

# Check certificate trust
curl -v https://<SATELLITE_IP>/rhsm/consumers

# Verify time synchronization
chrony sources -v
Web Interface Not Accessible

# Check Apache status
systemctl status httpd

# Verify firewall rules
firewall-cmd --list-all

# Check SSL certificate
openssl s_client -connect localhost:443
Performance Issues

# Monitor system resources
top
iostat -x 1

# Check Satellite services
satellite-maintain service status

# Optimize PostgreSQL
satellite-installer --tuning development  # for lab environments
Verification Steps
Verify Satellite Deployment
Check Satellite Services

# Verify all services are running
satellite-maintain service status

# Check specific services
systemctl status foreman
systemctl status pulpcore-api
systemctl status postgresql
Test Web Interface

Access https://<SATELLITE_PUBLIC_IP>
Login successfully
Navigate through main menu items
Verify no error messages in interface
Verify Content Host Management

Check registered hosts in Hosts > All Hosts
Verify host details and facts
Test remote execution capabilities
Confirm package management functionality
Performance Validation
System Resource Usage

# Check memory usage
free -h

# Check disk usage
df -h

# Monitor CPU usage
top -n 1
Network Connectivity

# Test connectivity from content hosts
ping satellite.example.com
curl -k https://satellite.example.com/api/status
Conclusion
In this lab, you have successfully:

Deployed Red Hat Satellite 6 on Amazon Web Services infrastructure, demonstrating cloud-based configuration management capabilities
Configured networking and storage components including security groups, firewall rules, and dedicated storage volumes for optimal Satellite performance
Set up cloud-based content hosts and registered them with the Satellite server, establishing a complete content management environment
Implemented security best practices including SSL certificates, proper network segmentation, and access controls
Created organizational structures including organizations, locations, host collections, and activation keys for efficient host management
Why This Matters:

This lab demonstrates real-world skills essential for modern IT infrastructure management. Red Hat Satellite provides centralized management capabilities for large-scale Linux environments, and deploying it on cloud platforms like AWS represents current industry practices. The skills learned here directly apply to:

Enterprise Configuration Management: Managing hundreds or thousands of Linux systems efficiently
Cloud Infrastructure Operations: Deploying and managing services on public cloud platforms
Compliance and Security: Maintaining consistent configurations and security policies across distributed environments
Automation and Scalability: Building foundations for automated patch management, configuration deployment, and system monitoring
The combination of Red Hat Satellite with AWS infrastructure provides a powerful platform for organizations to manage their Linux infrastructure at scale while leveraging cloud benefits such as elasticity, global availability, and managed services integration.

Students now have hands-on experience with enterprise-grade tools and cloud deployment patterns that are highly valued in the current job market, particularly for roles in DevOps, Cloud Operations, and Linux System Administration.
