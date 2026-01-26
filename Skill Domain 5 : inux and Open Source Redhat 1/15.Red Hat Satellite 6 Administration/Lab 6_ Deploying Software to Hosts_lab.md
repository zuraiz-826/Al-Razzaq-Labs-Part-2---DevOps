Lab 6: Deploying Software to Hosts
Objectives
By the end of this lab, you will be able to:

Understand the concepts of Content Views and Life Cycle Environments in Red Hat Satellite
Create and configure a Content View for software deployment
Deploy software updates to a development environment
Promote software updates through staging to production environments
Implement a structured software deployment workflow using open-source tools
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux system administration
Familiarity with package management concepts (RPM, YUM/DNF)
Knowledge of Red Hat Enterprise Linux or CentOS/Rocky Linux
Understanding of software deployment lifecycle concepts
Basic command-line interface skills
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex setups.

Your lab environment includes:

Red Hat Satellite 6 server (or Foreman/Katello equivalent)
Multiple client hosts representing different environments
Pre-configured repositories and basic content
Task 1: Define a Content View
A Content View is a filtered set of content that defines what software packages, errata, and puppet modules are available to your hosts. Think of it as a snapshot of your software repository at a specific point in time.

Subtask 1.1: Access the Satellite Web Interface
Open your web browser and navigate to the Satellite server interface:
https://satellite.example.com
Log in with the provided credentials:

Username: admin
Password: redhat123
Navigate to Content → Content Views from the main menu

Subtask 1.2: Create a New Content View
Click the Create Content View button

Fill in the Content View details:

Name: RHEL8-WebServer-CV
Label: rhel8-webserver-cv
Description: Content view for RHEL 8 web servers with Apache and security updates
Click Save to create the content view

Subtask 1.3: Add Repositories to the Content View
In your newly created content view, click on the Repositories tab

Click Add to add repositories

Select the following repositories:

Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)
Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
Click Add Repository to confirm

Subtask 1.4: Add Package Filters
Navigate to the Filters tab within your content view

Click New Filter and configure:

Name: Security-Updates-Filter
Type: Package
Inclusion Type: Include
Click Save

In the filter, add rules to include security-related packages:

Click Add Rule
Package Name: httpd* (for Apache web server)
Click Save
Create another filter for excluding development packages:

Name: Exclude-Development-Filter
Type: Package
Inclusion Type: Exclude
Add rule for package name: *-devel
Subtask 1.5: Publish the Content View
Navigate to Versions tab in your content view

Click Publish New Version

Configure the publication:

Description: Initial version with Apache web server packages
Force Metadata Regeneration: Check this box
Click Save to start the publication process

Monitor the publication progress in the Tasks section

Task 2: Deploy a Software Update to a Development Environment
Life Cycle Environments represent different stages in your software deployment pipeline. We'll start by deploying to the development environment.

Subtask 2.1: Create Life Cycle Environments
Navigate to Content → Life Cycle Environments

You should see the default Library environment. Create the development environment:

Click Create Environment Path
Name: Development
Label: development
Description: Development environment for testing updates
Prior Environment: Library
Click Save

Create the staging environment:

Name: Staging
Label: staging
Description: Staging environment for pre-production testing
Prior Environment: Development
Create the production environment:

Name: Production
Label: production
Description: Production environment for live systems
Prior Environment: Staging
Subtask 2.2: Promote Content View to Development
Return to Content → Content Views

Click on your RHEL8-WebServer-CV content view

Go to the Versions tab

Find your published version and click Promote

Select the Development environment

Add a description: Promoting initial web server configuration to development

Click Promote Version

Subtask 2.3: Register a Host to Development Environment
SSH into your development host:
ssh root@dev-host.example.com
Install the Satellite CA certificate:
rpm -Uvh http://satellite.example.com/pub/katello-ca-consumer-latest.noarch.rpm
Register the host to the development environment:
subscription-manager register --org="Default_Organization" \
  --activationkey="dev-activation-key" \
  --environment="Development/RHEL8-WebServer-CV"
Verify the registration:
subscription-manager status
subscription-manager list --available
Subtask 2.4: Install Software on Development Host
Update the package cache:
dnf clean all
dnf makecache
Install Apache web server:
dnf install httpd -y
Start and enable Apache:
systemctl start httpd
systemctl enable httpd
Verify the installation:
systemctl status httpd
curl http://localhost
Create a simple test page:
echo "<h1>Development Web Server - Version 1.0</h1>" > /var/www/html/index.html
Task 3: Promote the Update to Staging and Production Environments
Now we'll promote our tested configuration through the remaining environments.

Subtask 3.1: Test and Validate Development Deployment
On the development host, run comprehensive tests:
# Test web server functionality
curl -I http://localhost
systemctl is-active httpd
systemctl is-enabled httpd

# Check for security updates
dnf check-update --security

# Verify package versions
rpm -qa | grep httpd
Document any issues or create a test report:
echo "Development Testing Report - $(date)" > /tmp/dev-test-report.txt
echo "Apache Status: $(systemctl is-active httpd)" >> /tmp/dev-test-report.txt
echo "Security Updates Available: $(dnf check-update --security | wc -l)" >> /tmp/dev-test-report.txt
Subtask 3.2: Promote to Staging Environment
Return to the Satellite web interface

Navigate to Content → Content Views → RHEL8-WebServer-CV

Go to the Versions tab

Click Promote for your content view version

Select the Staging environment

Add description: Promoting to staging after successful development testing

Click Promote Version

Subtask 3.3: Deploy to Staging Host
SSH into your staging host:
ssh root@staging-host.example.com
Register the staging host:
rpm -Uvh http://satellite.example.com/pub/katello-ca-consumer-latest.noarch.rpm

subscription-manager register --org="Default_Organization" \
  --activationkey="staging-activation-key" \
  --environment="Staging/RHEL8-WebServer-CV"
Install and configure Apache:
dnf install httpd -y
systemctl start httpd
systemctl enable httpd
echo "<h1>Staging Web Server - Version 1.0</h1>" > /var/www/html/index.html
Run staging-specific tests:
# Performance testing
ab -n 100 -c 10 http://localhost/

# Security scanning (if available)
nmap -sV localhost

# Load testing
curl -w "@curl-format.txt" -o /dev/null -s http://localhost
Subtask 3.4: Create Staging Test Script
Create a comprehensive staging test script:
cat > /root/staging-tests.sh << 'EOF'
#!/bin/bash

echo "=== Staging Environment Tests ==="
echo "Date: $(date)"
echo

# Test 1: Service Status
echo "1. Testing Apache Service Status:"
systemctl is-active httpd && echo "✓ Apache is running" || echo "✗ Apache is not running"
systemctl is-enabled httpd && echo "✓ Apache is enabled" || echo "✗ Apache is not enabled"
echo

# Test 2: HTTP Response
echo "2. Testing HTTP Response:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ HTTP response: $HTTP_CODE (OK)"
else
    echo "✗ HTTP response: $HTTP_CODE (Error)"
fi
echo

# Test 3: Content Verification
echo "3. Testing Web Content:"
if curl -s http://localhost | grep -q "Staging Web Server"; then
    echo "✓ Correct staging content served"
else
    echo "✗ Incorrect or missing content"
fi
echo

# Test 4: Security Updates
echo "4. Checking Security Updates:"
SECURITY_UPDATES=$(dnf check-update --security 2>/dev/null | grep -c "updates")
echo "Security updates available: $SECURITY_UPDATES"
echo

echo "=== Test Summary ==="
echo "Staging tests completed at $(date)"
EOF

chmod +x /root/staging-tests.sh
Run the staging tests:
/root/staging-tests.sh
Subtask 3.5: Promote to Production Environment
After successful staging tests, return to Satellite web interface

Navigate to Content → Content Views → RHEL8-WebServer-CV

Click Promote for your content view version

Select the Production environment

Add description: Promoting to production after successful staging validation

Click Promote Version

Subtask 3.6: Deploy to Production Host
SSH into your production host:
ssh root@prod-host.example.com
Register the production host:
rpm -Uvh http://satellite.example.com/pub/katello-ca-consumer-latest.noarch.rpm

subscription-manager register --org="Default_Organization" \
  --activationkey="production-activation-key" \
  --environment="Production/RHEL8-WebServer-CV"
Install Apache with production considerations:
# Install packages
dnf install httpd mod_ssl -y

# Configure firewall
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Start services
systemctl start httpd
systemctl enable httpd

# Create production content
echo "<h1>Production Web Server - Version 1.0</h1>" > /var/www/html/index.html
echo "<p>Deployed via Red Hat Satellite Content Management</p>" >> /var/www/html/index.html
Verify production deployment:
curl http://localhost
systemctl status httpd
ss -tlnp | grep :80
Subtask 3.7: Create Deployment Report
Generate a comprehensive deployment report:
cat > /root/deployment-report.sh << 'EOF'
#!/bin/bash

REPORT_FILE="/tmp/satellite-deployment-report-$(date +%Y%m%d-%H%M%S).txt"

echo "Red Hat Satellite Software Deployment Report" > $REPORT_FILE
echo "=============================================" >> $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "CONTENT VIEW INFORMATION:" >> $REPORT_FILE
echo "Content View: RHEL8-WebServer-CV" >> $REPORT_FILE
echo "Version: 1.0" >> $REPORT_FILE
echo "Packages Included: httpd, mod_ssl, security updates" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "DEPLOYMENT ENVIRONMENTS:" >> $REPORT_FILE
echo "1. Development - Initial testing completed" >> $REPORT_FILE
echo "2. Staging - Performance and security testing completed" >> $REPORT_FILE
echo "3. Production - Live deployment completed" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "PRODUCTION HOST STATUS:" >> $REPORT_FILE
echo "Hostname: $(hostname)" >> $REPORT_FILE
echo "Apache Status: $(systemctl is-active httpd)" >> $REPORT_FILE
echo "Apache Enabled: $(systemctl is-enabled httpd)" >> $REPORT_FILE
echo "HTTP Response: $(curl -s -o /dev/null -w "%{http_code}" http://localhost)" >> $REPORT_FILE
echo "Firewall Status: $(firewall-cmd --state)" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "INSTALLED PACKAGES:" >> $REPORT_FILE
rpm -qa | grep -E "(httpd|mod_ssl)" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "DEPLOYMENT COMPLETED SUCCESSFULLY" >> $REPORT_FILE

echo "Report generated: $REPORT_FILE"
cat $REPORT_FILE
EOF

chmod +x /root/deployment-report.sh
/root/deployment-report.sh
Troubleshooting Common Issues
Issue 1: Content View Publication Fails
Symptoms: Publication process hangs or fails with errors

Solution:

# Check Satellite services
foreman-maintain service status

# Restart services if needed
foreman-maintain service restart

# Check disk space
df -h /var/lib/pulp
Issue 2: Host Registration Fails
Symptoms: Subscription manager registration returns errors

Solution:

# Clean existing registration
subscription-manager clean

# Check network connectivity
curl -k https://satellite.example.com/pub/katello-ca-consumer-latest.noarch.rpm

# Verify activation key
# Check in Satellite UI: Content → Activation Keys
Issue 3: Package Installation Fails
Symptoms: DNF/YUM cannot find packages or repositories

Solution:

# Refresh subscription
subscription-manager refresh

# Clean package cache
dnf clean all
dnf makecache

# Check enabled repositories
dnf repolist enabled
Conclusion
Congratulations! You have successfully completed Lab 6: Deploying Software to Hosts. In this lab, you accomplished the following:

Key Achievements:

Created a Content View that defines a specific set of software packages and updates for your web server infrastructure
Implemented a structured deployment pipeline using Life Cycle Environments (Development → Staging → Production)
Automated software deployment using Red Hat Satellite's content management capabilities
Tested and validated deployments at each stage before promoting to the next environment
Deployed Apache web server consistently across multiple environments using the same content view
Why This Matters: This lab demonstrates enterprise-grade software deployment practices that are essential in modern IT operations. By using Content Views and Life Cycle Environments, you can:

Ensure Consistency: The same software versions are deployed across all environments
Reduce Risk: Testing in development and staging environments before production deployment
Maintain Control: Centralized management of what software is available to different host groups
Enable Rollback: Ability to promote or demote content versions as needed
Improve Compliance: Standardized deployment processes that can be audited and documented
These skills are directly applicable to Red Hat Satellite 6 Administration certification and real-world enterprise environments where controlled, repeatable software deployments are critical for maintaining stable and secure infrastructure.

The content management workflow you've learned here scales from small environments with a few hosts to enterprise environments with thousands of systems, making it a valuable skill for system administrators and DevOps professionals.
