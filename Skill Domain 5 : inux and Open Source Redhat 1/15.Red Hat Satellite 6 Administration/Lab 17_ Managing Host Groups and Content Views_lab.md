Lab 17: Managing Host Groups and Content Views
Objectives
By the end of this lab, students will be able to:

Create and configure host groups based on system roles and organizational requirements
Understand the relationship between host groups and content views in Red Hat Satellite
Assign hosts to appropriate content views for centralized software management
Deploy content views to multiple hosts simultaneously using host groups
Implement best practices for organizing systems in enterprise environments
Troubleshoot common issues related to host group and content view management
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with Red Hat Satellite 6 concepts and terminology
Knowledge of content views and lifecycle environments from previous labs
Understanding of host registration and management processes
Access to Red Hat Satellite 6 server with administrative privileges
At least 2-3 registered client systems for testing
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes:

Red Hat Satellite 6 server (satellite.example.com)
3 RHEL client systems (client1, client2, client3)
Pre-configured network connectivity
Administrative access to all systems
Task 1: Create Host Groups Based on System Roles
Subtask 1.1: Plan Host Group Structure
Before creating host groups, let's plan our organizational structure based on common enterprise scenarios.

Access the Satellite Web UI

# Open your web browser and navigate to:
https://satellite.example.com

# Login credentials:
Username: admin
Password: redhat123
Navigate to Host Groups

Click on Configure in the main menu
Select Host Groups from the dropdown menu
Plan Your Host Group Hierarchy

We'll create the following structure:

Production Environment
├── Web Servers
├── Database Servers
└── Application Servers

Development Environment
├── Dev Web Servers
└── Test Servers
Subtask 1.2: Create Parent Host Groups
Create Production Environment Host Group

Click Create Host Group
Fill in the following details:
Name: Production-Environment
Description: Parent group for all production systems
Environment: Production
Content Source: satellite.example.com
Configure Network Settings

Network Tab:
- Domain: example.com
- Subnet: 192.168.1.0/24
- Gateway: 192.168.1.1
- DNS Primary: 8.8.8.8
Set Operating System Parameters

Operating System Tab:
- Operating System: Red Hat Enterprise Linux 8
- Architecture: x86_64
- Partition Table: Kickstart default
- PXE Loader: PXELinux BIOS
Click Submit to create the host group

Create Development Environment Host Group

Repeat the process with these details:

Name: Development-Environment
Description: Parent group for all development and testing systems
Environment: Development
Keep other settings similar to Production
Subtask 1.3: Create Child Host Groups
Create Web Servers Host Group

Click Create Host Group
Configure the following:
Name: Web-Servers
Description: Apache and Nginx web servers
Parent: Production-Environment
Environment: Production
Add Web Server Specific Parameters

Navigate to the Parameters tab and add:

Parameter Name: server_role
Parameter Value: webserver

Parameter Name: required_packages
Parameter Value: httpd,mod_ssl,php

Parameter Name: firewall_ports
Parameter Value: 80,443
Create Database Servers Host Group

Name: Database-Servers
Description: MySQL and PostgreSQL database servers
Parent: Production-Environment
Add parameters:

Parameter Name: server_role
Parameter Value: database

Parameter Name: required_packages
Parameter Value: mariadb-server,postgresql-server

Parameter Name: firewall_ports
Parameter Value: 3306,5432
Create Application Servers Host Group

Name: Application-Servers
Description: Java and Python application servers
Parent: Production-Environment
Add parameters:

Parameter Name: server_role
Parameter Value: appserver

Parameter Name: required_packages
Parameter Value: java-11-openjdk,python3,tomcat

Parameter Name: firewall_ports
Parameter Value: 8080,8443
Subtask 1.4: Verify Host Group Creation
Review Host Group Hierarchy

Navigate to Configure > Host Groups and verify your structure:

# You should see a hierarchical view like:
Production-Environment
├── Web-Servers
├── Database-Servers
└── Application-Servers

Development-Environment
Test Host Group Inheritance

Click on Web-Servers and verify it inherits settings from Production-Environment

Task 2: Assign Hosts to Content Views
Subtask 2.1: Create Role-Specific Content Views
Navigate to Content Views

Click Content in the main menu
Select Content Views
Create Web Server Content View

Click Create New View
Configure:
Name: WebServer-ContentView
Label: webserver-cv
Description: Content view for web servers with Apache, PHP, and security updates
Add Repositories to Web Server Content View

Click on the newly created content view
Navigate to Repositories tab
Click Add and select:
Red Hat Enterprise Linux 8 BaseOS
Red Hat Enterprise Linux 8 AppStream
EPEL 8 (if available)
Add Package Filters

Navigate to Filters tab:

Click New Filter
Name: WebServer-Packages
Type: Include
Content Type: Package
Add packages:

httpd
mod_ssl
php
php-mysql
openssl
Create Database Server Content View

Repeat the process:

Name: DatabaseServer-ContentView
Label: database-cv
Add same repositories
Create filter with packages:
mariadb-server
mariadb
postgresql-server
postgresql
python3-PyMySQL
Publish Content Views

For each content view:

Click Publish New Version
Add description: Initial version with base packages
Click Save
Subtask 2.2: Associate Content Views with Host Groups
Update Web Servers Host Group

Navigate to Configure > Host Groups
Click on Web-Servers
In the Content tab, set:
Content View: WebServer-ContentView
Lifecycle Environment: Production
Update Database Servers Host Group

Click on Database-Servers
Set Content View: DatabaseServer-ContentView
Set Lifecycle Environment: Production
Verify Content View Assignments

Check that each host group shows the correct content view in the overview

Subtask 2.3: Register Hosts to Host Groups
Prepare Registration Command

Navigate to Hosts > Registration:

Select Host Group: Web-Servers
Lifecycle Environment: Production
Content View: WebServer-ContentView
Generate activation key if needed
Register First Client as Web Server

On client1 system:

# Download and install katello-ca-consumer
curl -k https://satellite.example.com/pub/katello-ca-consumer-latest.noarch.rpm -o katello-ca-consumer.rpm
sudo rpm -Uvh katello-ca-consumer.rpm

# Register with host group
sudo subscription-manager register --org="Default_Organization" \
  --activationkey="WebServer-Key" \
  --environment="Production/WebServer-ContentView"

# Install katello-agent
sudo yum install -y katello-agent
sudo systemctl enable goferd
sudo systemctl start goferd
Assign Host to Host Group

In Satellite Web UI:

Navigate to Hosts > All Hosts
Click on the registered client
Click Edit
Set Host Group: Web-Servers
Click Submit
Register Additional Clients

Repeat for client2 (Database Server) and client3 (Application Server)

Task 3: Deploy Content Views to Multiple Hosts
Subtask 3.1: Promote Content Views Through Lifecycle
Create Lifecycle Environment Path

Navigate to Content > Lifecycle Environments:

Verify path: Library → Development → Testing → Production
If missing environments, create them
Promote Web Server Content View

Navigate to Content > Content Views
Click WebServer-ContentView
Click Promote next to the latest version
Select Production environment
Add promotion description: Promoting web server packages to production
Click Promote Version
Promote Database Content View

Repeat promotion process for DatabaseServer-ContentView

Subtask 3.2: Bulk Actions on Host Groups
Select Multiple Hosts

Navigate to Hosts > All Hosts:

Use filters to show hosts in Web-Servers host group
Select all web servers using checkboxes
Click Select Action > Change Content View
Update Content View Assignment

New Content View: WebServer-ContentView
New Lifecycle Environment: Production
Click Submit
Monitor Content View Changes

Navigate to Monitor > Tasks to track the progress

Subtask 3.3: Install Packages on Host Groups
Create Package Installation Job

Navigate to Hosts > All Hosts:

Filter by host group: Web-Servers
Select all web servers
Click Select Action > Install Package
Specify Packages to Install

Package Names: httpd mod_ssl php
Click Submit
Monitor Installation Progress

Navigate to Monitor > Jobs
Click on the package installation job
Monitor progress across all selected hosts
Verify Package Installation

On each web server:

# Check installed packages
rpm -qa | grep -E "(httpd|mod_ssl|php)"

# Verify services
sudo systemctl status httpd
Subtask 3.4: Apply Errata to Host Groups
Check Available Errata

Navigate to Content > Errata:

Filter by Applicable: Yes
Note security and bug fix updates
Apply Security Updates to Host Group

Navigate to Hosts > All Hosts:

Filter by host group: Web-Servers
Select all hosts
Click Select Action > Install Errata
Select Security errata type
Click Submit
Schedule Maintenance Window

For production systems:

Set Schedule: Future date/time
Add Description: Monthly security updates for web servers
Click Submit
Subtask 3.5: Create Recurring Jobs
Set Up Automated Package Updates

Navigate to Hosts > Job Templates:

Find Package Action - Yum template
Click Run
Configure:
Job Category: Commands
Hosts: Select host group Web-Servers
Action: update
Package: (leave blank for all updates)
Schedule Recurring Execution

Schedule: Recurring
Repeats: Monthly
Starts at: First Sunday of month, 2:00 AM
Click Submit
Verification and Testing
Verify Host Group Configuration
Check Host Group Membership

# On Satellite server, verify host assignments
hammer host list --search "hostgroup = Web-Servers"
hammer host list --search "hostgroup = Database-Servers"
Verify Content View Assignments

# Check content view assignments
hammer host info --name client1.example.com | grep -E "(Content View|Lifecycle)"
Test Content Deployment
Verify Package Installation

On web servers:

# Check web server packages
rpm -qa | grep httpd
systemctl status httpd

# Check if packages came from correct content view
yum history info | head -20
Test Content View Updates

# Check for available updates
yum check-update

# Verify repository sources
yum repolist enabled
Troubleshooting Common Issues
Host Group Assignment Issues
Problem: Host not inheriting host group settings

Solution:

# Force host group parameter refresh
hammer host update --name client1.example.com --hostgroup "Web-Servers"

# Verify inheritance
hammer host info --name client1.example.com
Content View Deployment Issues
Problem: Packages not available after content view assignment

Solution:

Verify content view promotion:

hammer content-view version list --content-view "WebServer-ContentView"
Check repository synchronization:

hammer repository list --organization "Default_Organization"
Refresh host subscription:

# On client system
sudo subscription-manager refresh
sudo yum clean all
Performance Optimization
Problem: Slow deployment to multiple hosts

Solution:

Adjust concurrent execution settings
Use host collections for better grouping
Schedule deployments during off-peak hours
Best Practices
Host Group Organization
Use Hierarchical Structure: Organize host groups in a logical hierarchy
Consistent Naming: Use clear, descriptive names for host groups
Parameter Inheritance: Leverage inheritance to reduce configuration duplication
Role-Based Grouping: Group hosts by function rather than location
Content View Management
Version Control: Always use descriptive version comments
Testing Pipeline: Test content views in development before production
Incremental Updates: Use composite content views for complex environments
Regular Cleanup: Remove old content view versions periodically
Deployment Strategies
Staged Rollouts: Deploy to small groups first, then expand
Maintenance Windows: Schedule updates during planned downtime
Rollback Planning: Always have a rollback strategy
Monitoring: Monitor deployment progress and system health
Conclusion
In this lab, you have successfully:

Created a hierarchical host group structure that mirrors real-world organizational needs, making system management more efficient and scalable
Implemented role-based content views that ensure each system type receives appropriate software packages and updates
Deployed content to multiple hosts simultaneously using host groups, demonstrating the power of centralized management
Established automated processes for ongoing maintenance and updates
Why This Matters: In enterprise environments, managing hundreds or thousands of systems individually is impractical and error-prone. Host groups and content views provide the foundation for:

Consistent Configuration: Ensuring all systems of the same type have identical configurations
Efficient Updates: Deploying patches and updates to entire groups simultaneously
Compliance Management: Maintaining security and compliance standards across the infrastructure
Operational Efficiency: Reducing administrative overhead through automation and standardization
These skills are essential for Red Hat Satellite administrators and form the backbone of enterprise Linux management strategies. The concepts learned here scale from small environments to massive data centers with thousands of systems.

Next Steps: Consider exploring advanced topics such as:

Composite content views for complex multi-repository scenarios
Host collections for cross-host-group management
Ansible integration for configuration management
Compliance scanning and remediation workflows
