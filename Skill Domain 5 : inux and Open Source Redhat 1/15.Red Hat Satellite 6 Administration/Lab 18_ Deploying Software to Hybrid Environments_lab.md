Lab 18: Deploying Software to Hybrid Environments
Objectives
By the end of this lab, you will be able to:

Understand the concept of hybrid environments in enterprise IT infrastructure
Create and configure lifecycle environments for hybrid deployments using Red Hat Satellite
Deploy software packages to both on-premise and cloud-based systems
Manage content views and activation keys for different environment types
Test and verify software deployment across hybrid infrastructure
Troubleshoot common deployment issues in hybrid environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux system administration
Familiarity with Red Hat Enterprise Linux (RHEL) systems
Knowledge of package management using YUM/DNF
Understanding of network concepts and SSH connectivity
Basic experience with Red Hat Satellite or similar configuration management tools
Completed previous labs covering Satellite basics and content management
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines.

Your lab environment includes:

Satellite Server: Red Hat Satellite 6 server (satellite.lab.local)
On-Premise Host: RHEL 8 system simulating on-premise infrastructure (onprem.lab.local)
Cloud Host: RHEL 8 system simulating cloud infrastructure (cloud.lab.local)
Network Configuration: All systems are pre-configured with proper networking and DNS resolution
Task 1: Create Lifecycle Environments for Hybrid Environments
Subtask 1.1: Understanding Lifecycle Environments
Lifecycle environments in Red Hat Satellite represent different stages of your infrastructure where content moves through a promotion path. In hybrid environments, we typically have:

Library: The initial environment where all content is imported
Development: Testing environment for initial deployments
On-Premise Production: Production environment for on-premise systems
Cloud Production: Production environment for cloud-based systems
Subtask 1.2: Access Red Hat Satellite Web Interface
Open your web browser and navigate to the Satellite server:
https://satellite.lab.local
Log in with the provided credentials:

Username: admin
Password: redhat123
Navigate to Content → Lifecycle Environments from the main menu.

Subtask 1.3: Create Development Environment
Click Create Environment Path button.

Fill in the environment details:

Name: Development
Label: development
Description: Development environment for testing deployments
Prior Environment: Library
Click Save to create the environment.

Subtask 1.4: Create On-Premise Production Environment
Click Create Environment Path again.

Configure the on-premise production environment:

Name: On-Premise Production
Label: onprem-prod
Description: Production environment for on-premise infrastructure
Prior Environment: Development
Click Save to create the environment.

Subtask 1.5: Create Cloud Production Environment
Create another environment path for cloud infrastructure:

Name: Cloud Production
Label: cloud-prod
Description: Production environment for cloud infrastructure
Prior Environment: Development
Click Save to complete the lifecycle environment setup.

Subtask 1.6: Verify Lifecycle Environment Structure
Navigate back to Content → Lifecycle Environments.

Verify your environment structure looks like this:

Library → Development → On-Premise Production
                   → Cloud Production
Task 2: Deploy Software to Both On-Premise and Cloud Hosts
Subtask 2.1: Create Content Views for Hybrid Deployment
Navigate to Content → Content Views.

Click Create New View.

Create a content view for web server software:

Name: Web Server Packages
Label: web-server-packages
Description: Apache web server and related packages for hybrid deployment
Click Save.

Subtask 2.2: Add Repositories to Content View
Click on the Web Server Packages content view.

Go to the Yum Content → Repositories tab.

Click Add and select the RHEL 8 BaseOS and AppStream repositories.

Click Add Repository to include them in the content view.

Subtask 2.3: Add Package Filters
Go to the Filters tab within the content view.

Click New Filter.

Create a filter for web server packages:

Name: Web Server Filter
Type: Include
Content Type: Package
Click Save.

Click on the filter and add the following packages:

httpd
httpd-tools
mod_ssl
php
php-mysql
Subtask 2.4: Publish Content View
Go to the Versions tab.

Click Publish New Version.

Add a description: "Initial web server package deployment for hybrid environments"

Click Save to publish the content view.

Subtask 2.5: Promote Content to Lifecycle Environments
Once published, click on Version 1.0.

Click Promote.

Select Development environment and click Promote.

After promotion completes, promote to both production environments:

Promote to On-Premise Production
Promote to Cloud Production
Subtask 2.6: Create Activation Keys
Navigate to Content → Activation Keys.

Create activation key for on-premise systems:

Name: OnPrem-WebServer-Key
Environment: On-Premise Production
Content View: Web Server Packages
Usage Limit: Unlimited
Create activation key for cloud systems:

Name: Cloud-WebServer-Key
Environment: Cloud Production
Content View: Web Server Packages
Usage Limit: Unlimited
Subtask 2.7: Register On-Premise Host
SSH to the on-premise host:
ssh root@onprem.lab.local
Install the Satellite CA certificate:
rpm -Uvh http://satellite.lab.local/pub/katello-ca-consumer-latest.noarch.rpm
Register the system using the on-premise activation key:
subscription-manager register --org="Default_Organization" \
  --activationkey="OnPrem-WebServer-Key" \
  --serverurl=https://satellite.lab.local:443/rhsm \
  --baseurl=https://satellite.lab.local/pulp/repos
Verify registration:
subscription-manager status
subscription-manager list --available
Subtask 2.8: Register Cloud Host
SSH to the cloud host:
ssh root@cloud.lab.local
Install the Satellite CA certificate:
rpm -Uvh http://satellite.lab.local/pub/katello-ca-consumer-latest.noarch.rpm
Register the system using the cloud activation key:
subscription-manager register --org="Default_Organization" \
  --activationkey="Cloud-WebServer-Key" \
  --serverurl=https://satellite.lab.local:443/rhsm \
  --baseurl=https://satellite.lab.local/pulp/repos
Verify registration:
subscription-manager status
subscription-manager list --available
Subtask 2.9: Install Software on Both Hosts
On the on-premise host, install Apache web server:
dnf clean all
dnf install httpd httpd-tools mod_ssl -y
On the cloud host, install Apache with PHP:
dnf clean all
dnf install httpd httpd-tools mod_ssl php php-mysql -y
Verify installations on both hosts:
rpm -qa | grep httpd
systemctl status httpd
Task 3: Test Software Deployment in Hybrid Environments
Subtask 3.1: Configure Web Services
On the on-premise host, start and enable Apache:
systemctl start httpd
systemctl enable httpd
systemctl status httpd
Create a test web page:
echo "<h1>On-Premise Web Server</h1>" > /var/www/html/index.html
echo "<p>Deployed via Red Hat Satellite</p>" >> /var/www/html/index.html
echo "<p>Environment: On-Premise Production</p>" >> /var/www/html/index.html
On the cloud host, start and enable Apache:
systemctl start httpd
systemctl enable httpd
systemctl status httpd
Create a PHP test page:
cat > /var/www/html/index.php << 'EOF'
<?php
echo "<h1>Cloud Web Server</h1>";
echo "<p>Deployed via Red Hat Satellite</p>";
echo "<p>Environment: Cloud Production</p>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Server Time: " . date('Y-m-d H:i:s') . "</p>";
?>
EOF
Subtask 3.2: Configure Firewall Rules
On both hosts, configure firewall to allow HTTP traffic:
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
firewall-cmd --list-services
Subtask 3.3: Test Web Server Connectivity
From the Satellite server, test connectivity to on-premise host:
curl http://onprem.lab.local
Expected output:

<h1>On-Premise Web Server</h1>
<p>Deployed via Red Hat Satellite</p>
<p>Environment: On-Premise Production</p>
Test connectivity to cloud host:
curl http://cloud.lab.local/index.php
Expected output:

<h1>Cloud Web Server</h1>
<p>Deployed via Red Hat Satellite</p>
<p>Environment: Cloud Production</p>
<p>PHP Version: 7.4.x</p>
<p>Server Time: 2024-xx-xx xx:xx:xx</p>
Subtask 3.4: Verify Satellite Management
In the Satellite web interface, navigate to Hosts → All Hosts.

Verify both hosts are listed and showing as managed:

onprem.lab.local
cloud.lab.local
Click on each host to view details:

Check Content tab for installed packages
Verify Subscriptions tab shows correct activation keys
Review Facts tab for system information
Subtask 3.5: Test Package Updates
Create a new version of the content view with additional packages.

Navigate to Content → Content Views → Web Server Packages.

Go to Filters and modify the Web Server Filter to include:

wget
curl
nano
Publish a new version (2.0) of the content view.

Promote version 2.0 to both production environments.

On both hosts, refresh repository metadata and install new packages:

dnf clean all
dnf install wget curl nano -y
Verify installations:
which wget curl nano
Subtask 3.6: Monitor Deployment Status
In Satellite, navigate to Monitor → Tasks.

Review recent tasks related to content promotion and package installations.

Check Reports → Host Configuration for compliance status.

Navigate to Content → Content Views → Web Server Packages → History to see promotion history.

Troubleshooting Common Issues
Issue 1: Host Registration Fails
Symptoms: Registration command returns certificate or connectivity errors.

Solution:

# Verify Satellite server connectivity
ping satellite.lab.local

# Check if CA certificate is properly installed
ls -la /etc/rhsm/ca/

# Reinstall CA certificate if needed
rpm -e katello-ca-consumer-satellite.lab.local
rpm -Uvh http://satellite.lab.local/pub/katello-ca-consumer-latest.noarch.rpm
Issue 2: Package Installation Fails
Symptoms: DNF/YUM cannot find packages or repositories.

Solution:

# Clean repository cache
dnf clean all

# Verify subscription status
subscription-manager status
subscription-manager repos --list-enabled

# Refresh subscription
subscription-manager refresh
Issue 3: Web Server Not Accessible
Symptoms: Cannot access web pages via curl or browser.

Solution:

# Check service status
systemctl status httpd

# Verify firewall rules
firewall-cmd --list-services

# Check SELinux status
getenforce
setsebool -P httpd_can_network_connect 1
Conclusion
In this lab, you have successfully:

Created Lifecycle Environments: Established a proper promotion path for hybrid environments including development, on-premise production, and cloud production stages.

Deployed Software Across Hybrid Infrastructure: Used Red Hat Satellite to manage and deploy web server packages to both on-premise and cloud-based systems using content views and activation keys.

Tested Hybrid Deployments: Verified that software deployments work correctly across different environment types and validated the management capabilities of Satellite in hybrid scenarios.

Why This Matters:

Hybrid environments are increasingly common in enterprise IT, where organizations maintain both on-premise infrastructure and cloud resources. This lab demonstrates how Red Hat Satellite provides centralized management capabilities that can span across different infrastructure types, ensuring consistent software deployment, security updates, and compliance across your entire hybrid environment.

The skills you've learned here are essential for:

Enterprise System Administration: Managing large-scale hybrid infrastructures
DevOps Practices: Implementing consistent deployment pipelines across environments
Compliance Management: Ensuring all systems receive appropriate updates regardless of location
Cost Optimization: Efficiently managing resources across on-premise and cloud environments
This foundation prepares you for real-world scenarios where you'll need to maintain consistency and control across diverse infrastructure components while leveraging the benefits of both on-premise and cloud computing models.
