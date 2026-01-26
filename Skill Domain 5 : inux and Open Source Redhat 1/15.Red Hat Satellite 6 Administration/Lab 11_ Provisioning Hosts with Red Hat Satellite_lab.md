Lab 11: Provisioning Hosts with Red Hat Satellite
Objectives
By the end of this lab, students will be able to:

Configure and use predefined provisioning templates in Red Hat Satellite
Customize provisioning templates for different environments (Development and Production)
Automate host provisioning using content views and templates
Validate the provisioning process and troubleshoot common issues
Understand the relationship between templates, content views, and host groups
Implement environment-specific configurations during provisioning
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with Red Hat Satellite 6 concepts (Content Views, Host Groups, Activation Keys)
Completion of previous Satellite labs covering content management and host registration
Understanding of kickstart/provisioning concepts
Basic knowledge of DHCP, DNS, and TFTP services
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM. Your lab environment includes:

Red Hat Satellite 6 server (satellite.example.com)
DHCP/DNS/TFTP services pre-configured
Sample content views and activation keys
Network infrastructure for provisioning
Task 1: Prepare Provisioning Infrastructure
Subtask 1.1: Verify Satellite Services
First, let's ensure all required services are running on the Satellite server.

Connect to the Satellite server:
ssh root@satellite.example.com
Check Satellite services status:
satellite-maintain service status
Verify DHCP service configuration:
systemctl status dhcpd
cat /etc/dhcp/dhcpd.conf | grep -A 10 "subnet"
Check TFTP service:
systemctl status tftp
ls -la /var/lib/tftpboot/
Subtask 1.2: Configure Provisioning Settings
Access Satellite Web UI:

Open browser and navigate to https://satellite.example.com
Login with admin credentials
Configure Global Provisioning Settings:

Navigate to Administer → Settings → Provisioning
Set the following parameters:
Default PXE global template: PXELinux global default
Default PXE local template: PXELinux default local boot
Default iPXE template: iPXE global default
Verify Installation Media:

Go to Hosts → Installation Media
Ensure RHEL 8 and RHEL 9 media are available
Note the media URLs for later use
Task 2: Create and Customize Provisioning Templates
Subtask 2.1: Create Development Environment Template
Navigate to Provisioning Templates:

Go to Hosts → Provisioning Templates
Click Create Template
Create Development Kickstart Template:

# Template Name: RHEL Development Kickstart
# Template Type: Provision

<%#
kind: provision
name: RHEL Development Kickstart
model: ProvisioningTemplate
oses:
- RedHat 8
- RedHat 9
%>

# Development Environment Kickstart Template
install
url --url="<%= @medium_uri %>"
lang en_US.UTF-8
keyboard us
timezone America/New_York --isUtc

# Network configuration
network --bootproto=dhcp --device=<%= @host.mac %> --hostname=<%= @host.name %>

# Root password (encrypted)
rootpw --iscrypted <%= root_pass %>

# Firewall configuration - more permissive for development
firewall --enabled --ssh --http --https --port=8080:tcp

# SELinux configuration - permissive for development
selinux --permissive

# Disk partitioning for development (smaller swap, more /home)
clearpart --all --initlabel
part /boot --fstype=xfs --size=1024
part pv.01 --size=1 --grow
volgroup vg_dev pv.01
logvol / --vgname=vg_dev --name=root --fstype=xfs --size=8192
logvol /home --vgname=vg_dev --name=home --fstype=xfs --size=4096
logvol swap --vgname=vg_dev --name=swap --fstype=swap --size=2048

# Package selection for development
%packages
@^minimal-environment
@development-tools
git
vim
wget
curl
python3
python3-pip
nodejs
npm
docker
%end

# Post-installation script for development environment
%post --log=/root/ks-post.log

# Register with Satellite
/usr/sbin/subscription-manager register --org="<%= @host.organization.name %>" --activationkey="<%= @host.activation_keys.first.name %>" --serverurl="https://<%= @host.subnet.dhcp.url %>" --baseurl="https://<%= @host.subnet.dhcp.url %>/pulp/repos"

# Enable development repositories
subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms
subscription-manager repos --enable=codeready-builder-for-rhel-8-x86_64-rpms

# Install additional development packages
yum install -y epel-release
yum groupinstall -y "Development Tools"

# Configure development user
useradd -m developer
echo "developer:devpass123" | chpasswd
usermod -aG wheel developer

# Start and enable Docker for development
systemctl enable docker
systemctl start docker
usermod -aG docker developer

# Development environment customizations
echo "export PS1='\[\e[32m\][DEV]\[\e[0m\] \u@\h:\w\$ '" >> /home/developer/.bashrc
echo "alias ll='ls -la'" >> /home/developer/.bashrc

%end

reboot
Save the Development Template:
Click Submit to save the template
Associate with appropriate organizations and locations
Subtask 2.2: Create Production Environment Template
Create Production Kickstart Template:
# Template Name: RHEL Production Kickstart
# Template Type: Provision

<%#
kind: provision
name: RHEL Production Kickstart
model: ProvisioningTemplate
oses:
- RedHat 8
- RedHat 9
%>

# Production Environment Kickstart Template
install
url --url="<%= @medium_uri %>"
lang en_US.UTF-8
keyboard us
timezone America/New_York --isUtc

# Network configuration
network --bootproto=dhcp --device=<%= @host.mac %> --hostname=<%= @host.name %>

# Root password (encrypted)
rootpw --iscrypted <%= root_pass %>

# Firewall configuration - restrictive for production
firewall --enabled --ssh

# SELinux configuration - enforcing for production
selinux --enforcing

# Disk partitioning for production (larger swap, separate /var, /tmp)
clearpart --all --initlabel
part /boot --fstype=xfs --size=1024
part pv.01 --size=1 --grow
volgroup vg_prod pv.01
logvol / --vgname=vg_prod --name=root --fstype=xfs --size=10240
logvol /var --vgname=vg_prod --name=var --fstype=xfs --size=8192
logvol /tmp --vgname=vg_prod --name=tmp --fstype=xfs --size=2048
logvol /home --vgname=vg_prod --name=home --fstype=xfs --size=2048
logvol swap --vgname=vg_prod --name=swap --fstype=swap --size=4096

# Minimal package selection for production
%packages
@^minimal-environment
rsyslog
chrony
aide
%end

# Post-installation script for production environment
%post --log=/root/ks-post.log

# Register with Satellite
/usr/sbin/subscription-manager register --org="<%= @host.organization.name %>" --activationkey="<%= @host.activation_keys.first.name %>" --serverurl="https://<%= @host.subnet.dhcp.url %>" --baseurl="https://<%= @host.subnet.dhcp.url %>/pulp/repos"

# Enable only necessary repositories
subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms

# Production security hardening
# Disable unnecessary services
systemctl disable bluetooth
systemctl disable cups

# Configure secure /tmp
echo "tmpfs /tmp tmpfs defaults,nodev,nosuid,noexec 0 0" >> /etc/fstab

# Set up log rotation
cat > /etc/logrotate.d/production << EOF
/var/log/messages {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF

# Configure chrony for time synchronization
systemctl enable chronyd
systemctl start chronyd

# Initialize AIDE database
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Production environment identification
echo "export PS1='\[\e[31m\][PROD]\[\e[0m\] \u@\h:\w\$ '" >> /root/.bashrc

%end

reboot
Save the Production Template:
Click Submit to save the template
Subtask 2.3: Create PXE Templates
Create Development PXE Template:
Go to Hosts → Provisioning Templates
Click Create Template
Template Type: PXELinux
<%#
kind: PXELinux
name: Development PXE Template
%>

DEFAULT menu
PROMPT 0
MENU TITLE Development Environment PXE Boot Menu
TIMEOUT 200

LABEL local
  MENU LABEL Boot from local drive
  LOCALBOOT 0

LABEL install
  MENU LABEL Install RHEL Development Environment
  KERNEL <%= @kernel %>
  APPEND initrd=<%= @initrd %> ks=<%= foreman_url('provision') %> inst.stage2=<%= @host.operatingsystem.medium_uri(@host) %> quiet
  IPAPPEND 2
Create Production PXE Template:
<%#
kind: PXELinux
name: Production PXE Template
%>

DEFAULT menu
PROMPT 0
MENU TITLE Production Environment PXE Boot Menu
TIMEOUT 100

LABEL local
  MENU LABEL Boot from local drive
  LOCALBOOT 0

LABEL install
  MENU LABEL Install RHEL Production Environment
  KERNEL <%= @kernel %>
  APPEND initrd=<%= @initrd %> ks=<%= foreman_url('provision') %> inst.stage2=<%= @host.operatingsystem.medium_uri(@host) %> quiet
  IPAPPEND 2
Task 3: Configure Host Groups and Activation Keys
Subtask 3.1: Create Development Host Group
Navigate to Host Groups:

Go to Configure → Host Groups
Click Create Host Group
Configure Development Host Group:

Name: Development Servers
Parent: Leave blank
Environment: Development
Puppet Classes: Add relevant classes if using Puppet
Operating System Tab:

Operating System: RedHat 8.x
Media: Select appropriate RHEL 8 media
Partition Table: Kickstart default
PXE Loader: PXELinux BIOS
Templates Tab:

Provisioning Template: RHEL Development Kickstart
PXELinux Template: Development PXE Template
Subtask 3.2: Create Production Host Group
Create Production Host Group:

Name: Production Servers
Environment: Production
Configure Templates:

Provisioning Template: RHEL Production Kickstart
PXELinux Template: Production PXE Template
Subtask 3.3: Create Environment-Specific Activation Keys
Create Development Activation Key:
hammer activation-key create \
  --name "dev-rhel8-key" \
  --organization "Default Organization" \
  --content-view "RHEL8-Dev-CV" \
  --lifecycle-environment "Development"
Create Production Activation Key:
hammer activation-key create \
  --name "prod-rhel8-key" \
  --organization "Default Organization" \
  --content-view "RHEL8-Prod-CV" \
  --lifecycle-environment "Production"
Add Subscriptions to Activation Keys:
# List available subscriptions
hammer subscription list --organization "Default Organization"

# Add subscription to development key
hammer activation-key add-subscription \
  --name "dev-rhel8-key" \
  --organization "Default Organization" \
  --subscription-id <subscription-id>

# Add subscription to production key
hammer activation-key add-subscription \
  --name "prod-rhel8-key" \
  --organization "Default Organization" \
  --subscription-id <subscription-id>
Task 4: Provision Hosts Using Templates
Subtask 4.1: Provision Development Host
Create Development Host Entry:

Go to Hosts → All Hosts
Click Create Host
Configure Host Details:

Name: dev-web01.example.com
Organization: Default Organization
Location: Default Location
Host Group: Development Servers
Deploy on: Bare Metal
Interface Configuration:

MAC Address: Enter the MAC address of target system
Domain: example.com
Subnet: Select appropriate subnet
Managed: Check this option
Primary: Check this option
Provision: Check this option
Operating System Configuration:

Verify settings inherited from Host Group
Root Password: Set a secure password
Activation Keys: dev-rhel8-key
Submit Host Creation:

Click Submit to create the host
Note the generated kickstart URL
Subtask 4.2: Provision Production Host
Create Production Host:

Name: prod-web01.example.com
Host Group: Production Servers
Activation Keys: prod-rhel8-key
Configure Production-Specific Settings:

Ensure all security settings are properly configured
Verify template associations
Subtask 4.3: Initiate PXE Boot Process
Prepare Target Systems:

Ensure target systems are configured for PXE boot
Verify network connectivity to Satellite server
Monitor Provisioning Process:

# Monitor DHCP logs
tail -f /var/log/dhcpd.log

# Monitor TFTP logs
tail -f /var/log/messages | grep tftp

# Monitor Satellite logs
tail -f /var/log/foreman/production.log
Boot Target Systems:
Power on target systems
Ensure they boot from network/PXE
Monitor the installation progress
Task 5: Validate Provisioning Process
Subtask 5.1: Monitor Installation Progress
Check Host Status in Satellite:

Navigate to Hosts → All Hosts
Monitor the build status of provisioning hosts
Check for any error messages
Verify Template Rendering:

# Check rendered kickstart file
curl -k https://satellite.example.com/unattended/provision?token=<host-token>
Monitor System Logs:
# On Satellite server, monitor various logs
tail -f /var/log/foreman/production.log
tail -f /var/log/httpd/foreman_access.log
tail -f /var/log/dhcpd.log
Subtask 5.2: Post-Installation Validation
Verify Development Host Configuration:
# SSH to development host after installation
ssh developer@dev-web01.example.com

# Check development-specific configurations
docker --version
git --version
python3 --version
whoami
groups

# Verify SELinux is in permissive mode
getenforce

# Check firewall rules
firewall-cmd --list-all
Verify Production Host Configuration:
# SSH to production host
ssh root@prod-web01.example.com

# Check production-specific configurations
getenforce  # Should show "Enforcing"
systemctl status chronyd
ls -la /var/lib/aide/

# Verify minimal package installation
rpm -qa | wc -l  # Should be fewer packages than dev

# Check disk partitioning
df -h
lsblk
Validate Satellite Registration:
# On both hosts, verify registration
subscription-manager status
subscription-manager list --installed
katello-agent --version
Subtask 5.3: Test Template Customizations
Verify Environment-Specific Customizations:
# On development host
echo $PS1  # Should show [DEV] prefix
ls -la /home/developer/

# On production host
echo $PS1  # Should show [PROD] prefix
cat /etc/fstab | grep tmp  # Should show tmpfs for /tmp
Test Package Differences:
# Development host should have development tools
which gcc
which git
which docker

# Production host should have minimal packages
which gcc  # Should not be found
systemctl list-unit-files | grep disabled  # Should show disabled services
Task 6: Troubleshooting and Optimization
Subtask 6.1: Common Troubleshooting Steps
Template Syntax Issues:
# Validate template syntax
hammer template dump --name "RHEL Development Kickstart"

# Check for ERB syntax errors in logs
grep -i "erb" /var/log/foreman/production.log
Network Boot Issues:
# Verify DHCP configuration
dhcp-lease-list
cat /etc/dhcp/dhcpd.conf

# Check TFTP files
ls -la /var/lib/tftpboot/pxelinux.cfg/
ls -la /var/lib/tftpboot/boot/
Host Registration Problems:
# Check activation key configuration
hammer activation-key info --name "dev-rhel8-key"

# Verify content view and lifecycle environment
hammer content-view list
hammer lifecycle-environment list
Subtask 6.2: Performance Optimization
Optimize Template Performance:

Remove unnecessary packages from %packages section
Minimize post-installation scripts
Use local repositories when possible
Monitor Resource Usage:

# Monitor Satellite server resources during provisioning
top
iostat 1
sar -u 1
Conclusion
In this comprehensive lab, you have successfully:

Configured provisioning infrastructure including DHCP, TFTP, and DNS services required for automated host deployment
Created environment-specific provisioning templates that automatically configure systems differently for development and production environments
Implemented security best practices by applying different hardening levels based on the target environment
Automated the entire provisioning workflow from PXE boot through final system configuration
Validated the provisioning process by confirming that hosts are properly configured according to their intended environment
Why This Matters: Automated provisioning with Red Hat Satellite dramatically reduces the time and effort required to deploy new systems while ensuring consistency and compliance across your infrastructure. By using environment-specific templates, you can automatically apply appropriate security policies, package selections, and configurations without manual intervention. This approach is essential for organizations managing large-scale infrastructure where manual provisioning would be time-consuming and error-prone.

The skills you've developed in this lab are directly applicable to real-world scenarios where rapid, consistent, and secure system deployment is critical for business operations. Understanding how to customize provisioning templates for different environments ensures that development systems have the tools developers need while production systems maintain the security and stability required for business-critical applications.
