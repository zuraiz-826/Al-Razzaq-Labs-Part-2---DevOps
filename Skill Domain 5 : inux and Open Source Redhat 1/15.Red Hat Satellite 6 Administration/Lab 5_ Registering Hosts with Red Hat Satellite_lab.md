Lab 5: Registering Hosts with Red Hat Satellite
Objectives
By the end of this lab, you will be able to:

Register RHEL systems with Red Hat Satellite using subscription-manager
Assign registered hosts to appropriate content views for software management
Organize systems into host groups based on their roles and functions
Understand the centralized management capabilities of Red Hat Satellite
Troubleshoot common registration issues and verify successful host registration
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with RHEL system administration concepts
Knowledge of subscription management concepts
Understanding of content views and lifecycle environments
Access to a Red Hat Satellite server (provided in the lab environment)
Basic networking knowledge (DNS, FQDN concepts)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes:

Red Hat Satellite 6 server (satellite.example.com)
Multiple RHEL client systems to register
Pre-configured network connectivity
Administrative access to all systems
Task 1: Register Hosts Using Subscription-Manager
Subtask 1.1: Prepare the Client System for Registration
First, we need to prepare our client system and verify connectivity to the Satellite server.

Access your client system and open a terminal as root:
sudo -i
Verify network connectivity to the Satellite server:
ping -c 3 satellite.example.com
Check current subscription status:
subscription-manager status
Remove any existing registration (if present):
subscription-manager unregister
subscription-manager clean
Subtask 1.2: Download and Install the Satellite CA Certificate
The client system needs to trust the Satellite server's SSL certificate.

Download the CA certificate from the Satellite server:
wget http://satellite.example.com/pub/katello-ca-consumer-latest.noarch.rpm
Install the CA certificate package:
rpm -Uvh katello-ca-consumer-latest.noarch.rpm
Verify the certificate installation:
ls -la /etc/rhsm/ca/
Subtask 1.3: Register the Host with Satellite
Now we'll register the system with the Satellite server using subscription-manager.

Register the system using the activation key method:
subscription-manager register --org="Default_Organization" \
  --activationkey="rhel8-key" \
  --serverurl=https://satellite.example.com:443/rhsm \
  --baseurl=https://satellite.example.com/pulp/repos
Alternative registration using username/password:

subscription-manager register --org="Default_Organization" \
  --username=admin \
  --password=redhat \
  --serverurl=https://satellite.example.com:443/rhsm \
  --baseurl=https://satellite.example.com/pulp/repos
Verify successful registration:
subscription-manager status
subscription-manager identity
Check available subscriptions:
subscription-manager list --available
Auto-attach subscriptions (if not using activation keys):
subscription-manager attach --auto
Subtask 1.4: Install and Configure Katello Agent
The Katello agent enables remote management capabilities from Satellite.

Install the Katello agent:
yum install -y katello-agent
Enable and start the goferd service:
systemctl enable goferd
systemctl start goferd
systemctl status goferd
Verify the agent installation:
katello-package-upload
Task 2: Assign Hosts to Content Views
Subtask 2.1: Verify Current Content View Assignment
Check the current content view assignment from the client:
subscription-manager repos --list-enabled
View subscription details:
subscription-manager list --consumed
Subtask 2.2: Access Satellite Web Interface
Open a web browser and navigate to the Satellite server:
https://satellite.example.com
Log in with the provided credentials:

Username: admin
Password: redhat
Navigate to Hosts → All Hosts to see your registered system.

Subtask 2.3: Assign Host to Specific Content View
In the Satellite web interface, click on your registered host name.

Go to the Content tab and note the current content view assignment.

Change the content view assignment:

Click Edit next to Content View
Select a different content view (e.g., "RHEL8-Production")
Select the appropriate lifecycle environment
Click Save
Verify the change from the command line on the client:

subscription-manager refresh
subscription-manager repos --list-enabled
Subtask 2.4: Update Repository Configuration
Clean the repository cache:
yum clean all
Verify new repositories are available:
yum repolist
Test package installation from the new content view:
yum search httpd
yum info httpd
Task 3: Organize Systems into Host Groups
Subtask 3.1: Create Host Groups in Satellite
In the Satellite web interface, navigate to Configure → Host Groups.

Create a new host group for web servers:

Click Create Host Group
Name: WebServers
Description: Host group for web server systems
Environment: Production
Content View: RHEL8-WebServer
Click Submit
Create another host group for database servers:

Name: DatabaseServers
Description: Host group for database server systems
Environment: Production
Content View: RHEL8-Database
Click Submit
Subtask 3.2: Assign Hosts to Host Groups
Navigate to Hosts → All Hosts.

Select your registered host by clicking on its name.

Edit the host configuration:

Click the Edit button
In the Host Group field, select WebServers
Click Submit
Verify the host group assignment:

The host should now show the assigned host group
Content view and environment should inherit from the host group
Subtask 3.3: Bulk Host Group Assignment
For managing multiple hosts efficiently:

Go to Hosts → All Hosts.

Select multiple hosts using the checkboxes.

Click Select Action → Change Group.

Choose the appropriate host group and click Submit.

Subtask 3.4: Configure Host Group Parameters
Navigate to Configure → Host Groups.

Click on the WebServers host group.

Go to the Parameters tab:

Click Add Parameter
Name: server_role
Value: webserver
Click Submit
Add another parameter:

Name: backup_schedule
Value: daily
Click Submit
Task 4: Verify and Test Host Management
Subtask 4.1: Test Remote Package Management
From the Satellite web interface, navigate to your host.

Go to Content → Packages.

Install a package remotely:

Search for tree
Click Install next to the tree package
Monitor the job status
Verify installation on the client:

rpm -q tree
which tree
Subtask 4.2: Test Configuration Management
Create a simple configuration file on Satellite for distribution.

Apply the configuration to hosts in the WebServers group.

Verify the configuration was applied on the client system.

Subtask 4.3: Monitor Host Status and Compliance
In Satellite, navigate to Monitor → Dashboard.

Review host status indicators:

Registration status
Subscription status
Configuration compliance
Package updates available
Check individual host details:

Click on your host name
Review all tabs for comprehensive information
Troubleshooting Common Issues
Registration Failures
If registration fails, check these common issues:

DNS resolution problems:
nslookup satellite.example.com
cat /etc/resolv.conf
Certificate issues:
rpm -qa | grep katello-ca
rpm -e katello-ca-consumer-satellite.example.com
wget http://satellite.example.com/pub/katello-ca-consumer-latest.noarch.rpm
rpm -Uvh katello-ca-consumer-latest.noarch.rpm
Firewall blocking connections:
telnet satellite.example.com 443
telnet satellite.example.com 80
Content View Assignment Issues
Refresh subscription data:
subscription-manager refresh
subscription-manager repos --list
Clear repository cache:
yum clean all
rm -rf /var/cache/yum/*
Host Group Inheritance Problems
Verify host group configuration in the web interface.

Check parameter inheritance at the host level.

Refresh host configuration:

katello-package-upload
Verification Commands
Use these commands to verify successful completion:

# Check registration status
subscription-manager status
subscription-manager identity

# Verify content view assignment
subscription-manager list --consumed

# Check available repositories
yum repolist enabled

# Verify Katello agent
systemctl status goferd
katello-package-upload

# Test remote management capability
yum check-update
Conclusion
In this lab, you have successfully:

Registered RHEL systems with Red Hat Satellite using subscription-manager, establishing centralized management capabilities
Assigned hosts to content views, enabling controlled software distribution and updates
Organized systems into host groups based on their roles, facilitating efficient bulk management operations
Verified remote management capabilities through package installation and configuration management
This centralized approach to system management provides significant benefits including:

Streamlined patch management across multiple systems
Consistent configuration enforcement through host groups and parameters
Simplified compliance monitoring and reporting
Efficient resource utilization through content view management
Reduced administrative overhead for large-scale deployments
Understanding these concepts is crucial for Red Hat Satellite 6 Administration certification and real-world enterprise Linux management scenarios. The skills you've developed enable you to effectively manage hundreds or thousands of RHEL systems from a single centralized platform, ensuring consistency, security, and compliance across your infrastructure.

Next Steps: Practice registering different types of systems, experiment with various content views, and explore advanced host group configurations to further enhance your Satellite management expertise.
