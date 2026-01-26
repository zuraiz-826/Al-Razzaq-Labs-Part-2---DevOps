Lab 7: Managing Custom Software Products
Objectives
By the end of this lab, you will be able to:

Create and configure custom repositories for third-party software in Red Hat Satellite
Build and package internal software into RPM packages
Deploy custom software products to managed hosts
Understand the complete lifecycle of custom software management in enterprise environments
Configure content views and activation keys for custom software distribution
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux system administration
Familiarity with Red Hat Satellite 6 concepts (organizations, locations, content views)
Knowledge of RPM package management
Understanding of repository management concepts
Access to Red Hat Satellite 6 server with administrative privileges
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or install software.

Your lab environment includes:

Red Hat Satellite 6 server (satellite.example.com)
Two managed client hosts (client1.example.com, client2.example.com)
All necessary tools and dependencies pre-installed
Task 1: Create Custom Repositories for Third-Party Software
Subtask 1.1: Create a Custom Product
First, we'll create a custom product to organize our third-party software repositories.

Access the Satellite Web UI

# Open your web browser and navigate to:
https://satellite.example.com
Navigate to Content Management

Click on Content → Products
Click Create Product
Configure the Custom Product

Name: Third-Party Software
Label: third-party-software
Description: Custom repositories for third-party applications
Click Save
Subtask 1.2: Create Custom Repository for EPEL
We'll add the EPEL (Extra Packages for Enterprise Linux) repository as an example of third-party software.

Create EPEL Repository

In the Third-Party Software product page, click Create Repository
Configure the repository:
Name: EPEL 8
Label: epel-8
Type: yum
URL: https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/
Download Policy: On Demand
Click Save
Synchronize the Repository

# From the Satellite server command line
hammer repository synchronize --name "EPEL 8" --product "Third-Party Software" --organization "Default Organization"
Subtask 1.3: Create Custom Repository for Docker CE
Let's add another third-party repository for Docker Community Edition.

Create Docker CE Repository

Click Create Repository in the Third-Party Software product
Configure:
Name: Docker CE
Label: docker-ce
Type: yum
URL: https://download.docker.com/linux/centos/8/x86_64/stable/
Download Policy: On Demand
Click Save
Synchronize Docker Repository

hammer repository synchronize --name "Docker CE" --product "Third-Party Software" --organization "Default Organization"
Subtask 1.4: Verify Repository Creation
Check Repository Status

# List all custom repositories
hammer repository list --product "Third-Party Software"

# Check synchronization status
hammer repository info --name "EPEL 8" --product "Third-Party Software"
View Repository Content

# List packages in EPEL repository
hammer package list --repository "EPEL 8" --product "Third-Party Software" | head -20
Task 2: Create RPM Packages for Internal Software
Subtask 2.1: Set Up RPM Build Environment
We'll create a simple internal application and package it as an RPM.

Install RPM Development Tools

# On the Satellite server
sudo dnf install -y rpm-build rpmdevtools rpmlint

# Set up RPM build environment
rpmdev-setuptree
Verify Build Environment

# Check the created directory structure
ls -la ~/rpmbuild/
Subtask 2.2: Create a Simple Internal Application
Create Application Directory

mkdir -p ~/myapp-1.0
cd ~/myapp-1.0
Create the Application Script

cat > myapp.sh << 'EOF'
#!/bin/bash
# MyApp - Internal Company Application
# Version 1.0

echo "==================================="
echo "  Welcome to MyApp v1.0"
echo "  Internal Company Application"
echo "==================================="
echo "Current Date: $(date)"
echo "System Information:"
echo "  Hostname: $(hostname)"
echo "  Uptime: $(uptime -p)"
echo "  Disk Usage:"
df -h / | tail -1
echo "==================================="
EOF

chmod +x myapp.sh
Create Application Configuration

cat > myapp.conf << 'EOF'
# MyApp Configuration File
APP_NAME="MyApp"
APP_VERSION="1.0"
LOG_LEVEL="INFO"
LOG_FILE="/var/log/myapp.log"
EOF
Subtask 2.3: Create RPM Spec File
Create the Spec File
cat > ~/rpmbuild/SPECS/myapp.spec << 'EOF'
Name:           myapp
Version:        1.0
Release:        1%{?dist}
Summary:        Internal Company Application

License:        Proprietary
URL:            http://internal.company.com
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       bash

%description
MyApp is an internal company application that provides
system information and monitoring capabilities.

%prep
%setup -q

%build
# Nothing to build for shell script

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/bin
mkdir -p $RPM_BUILD_ROOT/etc/myapp

install -m 755 myapp.sh $RPM_BUILD_ROOT/usr/local/bin/myapp
install -m 644 myapp.conf $RPM_BUILD_ROOT/etc/myapp/myapp.conf

%files
/usr/local/bin/myapp
/etc/myapp/myapp.conf

%changelog
* Wed Nov 15 2023 Lab User <user@example.com> - 1.0-1
- Initial package creation
EOF
Subtask 2.4: Build the RPM Package
Create Source Tarball

cd ~
tar czf ~/rpmbuild/SOURCES/myapp-1.0.tar.gz myapp-1.0/
Build the RPM

rpmbuild -ba ~/rpmbuild/SPECS/myapp.spec
Verify the Built Package

# List the created RPM
ls -la ~/rpmbuild/RPMS/noarch/

# Check RPM information
rpm -qip ~/rpmbuild/RPMS/noarch/myapp-1.0-1.el8.noarch.rpm
Subtask 2.5: Create Custom Repository for Internal Software
Create Internal Software Product

In Satellite Web UI, go to Content → Products
Click Create Product
Configure:
Name: Internal Software
Label: internal-software
Description: Internal company applications and tools
Click Save
Create Repository for Internal RPMs

In the Internal Software product, click Create Repository
Configure:
Name: Internal Applications
Label: internal-applications
Type: yum
URL: Leave empty (local repository)
Click Save
Upload the Custom RPM

# Upload the RPM to Satellite
hammer repository upload-content \
  --name "Internal Applications" \
  --product "Internal Software" \
  --path ~/rpmbuild/RPMS/noarch/myapp-1.0-1.el8.noarch.rpm
Task 3: Deploy Custom Software Products to Hosts
Subtask 3.1: Create Content View with Custom Software
Create Content View

Navigate to Content → Content Views
Click Create New View
Configure:
Name: Custom Software View
Label: custom-software-view
Description: Content view including custom and third-party software
Click Save
Add Repositories to Content View

In the Custom Software View, go to Yum Content → Repositories
Click Add and select:
EPEL 8 from Third-Party Software
Docker CE from Third-Party Software
Internal Applications from Internal Software
Click Add Repositories
Publish Content View

# Publish the content view
hammer content-view publish --name "Custom Software View" --organization "Default Organization"
Subtask 3.2: Create Activation Key
Create Activation Key via Web UI

Go to Content → Activation Keys
Click Create Activation Key
Configure:
Name: Custom-Software-Key
Description: Key for hosts with custom software access
Environment: Library
Content View: Custom Software View
Click Save
Configure Activation Key via CLI

# Add subscriptions to activation key
hammer activation-key add-subscription \
  --name "Custom-Software-Key" \
  --subscription "Third-Party Software" \
  --organization "Default Organization"

hammer activation-key add-subscription \
  --name "Custom-Software-Key" \
  --subscription "Internal Software" \
  --organization "Default Organization"
Subtask 3.3: Register Client Hosts
Generate Registration Command

# Generate registration command
hammer host-registration generate-command \
  --activation-keys "Custom-Software-Key" \
  --organization "Default Organization"
Register Client1

# On client1.example.com, run the generated command
# Example (replace with actual generated command):
curl -sS https://satellite.example.com/register | bash -s -- --activationkey="Custom-Software-Key"
Verify Registration

# On client1, verify repositories are available
sudo dnf repolist

# Check for custom repositories
sudo dnf repolist | grep -E "(epel|docker|internal)"
Subtask 3.4: Install Custom Software
Install Internal Application

# On client1
sudo dnf install -y myapp

# Test the application
myapp
Install Third-Party Software

# Install a package from EPEL
sudo dnf install -y htop

# Verify installation
htop --version
Install Docker CE

# Install Docker from custom repository
sudo dnf install -y docker-ce

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
sudo docker --version
Subtask 3.5: Verify Deployment via Satellite
Check Host Content

# List installed packages on managed host
hammer host package list --host "client1.example.com"

# Check for specific packages
hammer host package list --host "client1.example.com" | grep -E "(myapp|htop|docker)"
View Host Details

In Satellite Web UI, go to Hosts → All Hosts
Click on client1.example.com
Navigate to Content → Packages to see installed packages
Subtask 3.6: Create Host Collection for Custom Software
Create Host Collection

# Create host collection for custom software hosts
hammer host-collection create \
  --name "Custom Software Hosts" \
  --description "Hosts with custom software deployed" \
  --organization "Default Organization"
Add Hosts to Collection

# Add client1 to the host collection
hammer host-collection add-host \
  --name "Custom Software Hosts" \
  --host "client1.example.com" \
  --organization "Default Organization"
Bulk Operations on Host Collection

# Install package on all hosts in collection
hammer host-collection package install \
  --name "Custom Software Hosts" \
  --packages "vim-enhanced" \
  --organization "Default Organization"
Troubleshooting Tips
Common Issues and Solutions
Repository Synchronization Fails

# Check repository URL accessibility
curl -I https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/

# Check Satellite logs
sudo tail -f /var/log/foreman/production.log
RPM Build Errors

# Check spec file syntax
rpmlint ~/rpmbuild/SPECS/myapp.spec

# Verify source files exist
ls -la ~/rpmbuild/SOURCES/
Client Registration Issues

# Check Satellite connectivity from client
curl -k https://satellite.example.com/pub/katello-ca-consumer-latest.noarch.rpm

# Verify activation key
hammer activation-key info --name "Custom-Software-Key"
Package Installation Failures

# Clear DNF cache
sudo dnf clean all

# Check repository configuration
sudo dnf repolist -v

# Test repository access
sudo dnf makecache
Verification Commands
Use these commands to verify your lab completion:

# Verify custom products exist
hammer product list | grep -E "(Third-Party|Internal)"

# Check repository synchronization status
hammer repository list --product "Third-Party Software"

# Verify content view publication
hammer content-view version list --content-view "Custom Software View"

# Check host registration and content
hammer host list
hammer host info --name "client1.example.com"

# Verify package installations
hammer host package list --host "client1.example.com" | grep -E "(myapp|htop|docker)"
Conclusion
In this lab, you have successfully:

Created custom repositories for third-party software like EPEL and Docker CE, enabling your organization to manage external software sources centrally
Built and packaged internal software into RPM format, demonstrating how to distribute proprietary applications through Satellite
Deployed custom software products to managed hosts using content views and activation keys, showing the complete software lifecycle management process
Why This Matters: Managing custom software products is crucial in enterprise environments because it allows organizations to:

Maintain control over all software deployed in their infrastructure
Ensure consistency and compliance across all systems
Streamline the deployment and updates of both internal and third-party applications
Reduce security risks by managing software from trusted repositories
Enable efficient bulk operations across multiple hosts
You now have the skills to manage the complete lifecycle of custom software in Red Hat Satellite, from creation and packaging to deployment and maintenance. These capabilities are essential for Red Hat Satellite administrators managing complex enterprise environments with diverse software requirements.

The techniques learned in this lab form the foundation for advanced software management scenarios, including automated deployments, compliance reporting, and integration with CI/CD pipelines.
