Lab 4: Managing Software Life Cycle
Objectives
By the end of this lab, you will be able to:

Understand the concept of software life cycle management in enterprise Linux environments
Create and configure multiple life cycle environments (Development, Staging, Production)
Implement software promotion workflows across different environments
Track and monitor software deployment status across environments
Use open-source tools to manage content views and environment promotion
Apply best practices for software life cycle management in RHEL systems
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with RHEL/CentOS package management (yum/dnf)
Understanding of repository concepts
Basic knowledge of web interface navigation
Completed previous labs in the Red Hat Satellite series (recommended)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

Satellite Server: Pre-installed with Foreman/Katello
Client Systems: Multiple RHEL-based systems for testing
Network Configuration: All systems properly networked and accessible
Required Repositories: Base repositories already synchronized
Task 1: Create Life Cycle Environments
Subtask 1.1: Access the Satellite Web Interface
Open your web browser and navigate to the Satellite server
Log in using the provided credentials
Navigate to Content → Life Cycle Environments
# If accessing via command line, ensure the satellite service is running
sudo systemctl status foreman

# Check satellite status
sudo satellite-maintain service status
Subtask 1.2: Create Development Environment
Click Create Environment Path or New Environment

Fill in the following details:

Name: Development
Label: development
Description: Development environment for testing new packages
Prior Environment: Library
Click Save to create the environment

Subtask 1.3: Create Staging Environment
Click New Environment again

Configure the staging environment:

Name: Staging
Label: staging
Description: Staging environment for pre-production testing
Prior Environment: Development
Click Save

Subtask 1.4: Create Production Environment
Create the final environment:

Name: Production
Label: production
Description: Production environment for live systems
Prior Environment: Staging
Click Save

Subtask 1.5: Verify Environment Chain
Your environment chain should now look like:

Library → Development → Staging → Production
Navigate to Content → Life Cycle Environments to verify the complete chain is visible.

Task 2: Promote Software Updates Across Environments
Subtask 2.1: Create a Content View
Navigate to Content → Content Views

Click Create New View

Configure the content view:

Name: RHEL-BaseOS-CV
Label: rhel-baseos-cv
Description: Base operating system packages for RHEL
Click Save

Subtask 2.2: Add Repositories to Content View
Click on your newly created content view

Go to the Repositories tab

Click Add and select relevant repositories:

RHEL BaseOS repository
RHEL AppStream repository (if available)
Click Add Repository

Subtask 2.3: Publish Initial Version
Go to Versions tab in your content view

Click Publish New Version

Fill in the details:

Description: Initial version with base packages
Version: Will auto-increment (1.0)
Click Save

Wait for the publication process to complete. This may take several minutes.

Subtask 2.4: Promote to Development Environment
Once published, click on the version number (e.g., "Version 1.0")
Click Promote
Select Development environment
Add promotion description: Promoting base packages to development
Click Promote Version
Subtask 2.5: Test in Development Environment
Before promoting further, verify the content in development:

# On a client system registered to development environment
sudo dnf clean all
sudo dnf repolist

# Check available updates
sudo dnf check-update

# Install a test package to verify functionality
sudo dnf install -y tree
Subtask 2.6: Promote to Staging Environment
Return to the content view version
Click Promote again
Select Staging environment
Description: Promoting tested packages to staging
Click Promote Version
Subtask 2.7: Promote to Production Environment
After testing in staging:

Click Promote once more
Select Production environment
Description: Promoting validated packages to production
Click Promote Version
Task 3: Track the Status of Software Deployment
Subtask 3.1: Monitor Promotion Status
Navigate to Monitor → Tasks
Filter tasks by type: Package Promotion
Review the status of recent promotions:
Pending: Promotion is queued
Running: Promotion in progress
Success: Promotion completed successfully
Error: Promotion failed
Subtask 3.2: Create a Deployment Tracking Script
Create a script to monitor deployment status across environments:

# Create monitoring script
sudo vi /usr/local/bin/deployment-tracker.sh
Add the following content:

#!/bin/bash

# Deployment Status Tracker
# This script checks the status of content across environments

echo "=== Software Deployment Status Report ==="
echo "Generated on: $(date)"
echo "=========================================="

# Function to check environment status
check_environment() {
    local env_name=$1
    echo ""
    echo "Environment: $env_name"
    echo "------------------------"
    
    # Use hammer CLI to get environment info
    hammer lifecycle-environment info --name "$env_name" --organization "Default Organization" 2>/dev/null || {
        echo "Error: Could not retrieve information for $env_name"
        return 1
    }
}

# Check each environment
for env in "Library" "Development" "Staging" "Production"; do
    check_environment "$env"
done

echo ""
echo "=== Content View Status ==="
hammer content-view list --organization "Default Organization"

echo ""
echo "=== Recent Tasks ==="
hammer task list --search "label ~ promotion" | head -10
Make the script executable:

sudo chmod +x /usr/local/bin/deployment-tracker.sh
Subtask 3.3: Set Up Automated Monitoring
Create a systemd timer for regular monitoring:

# Create service file
sudo vi /etc/systemd/system/deployment-monitor.service
Add the following content:

[Unit]
Description=Software Deployment Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/deployment-tracker.sh
User=root
StandardOutput=journal
Create the timer file:

sudo vi /etc/systemd/system/deployment-monitor.timer
Add the following content:

[Unit]
Description=Run deployment monitor every hour
Requires=deployment-monitor.service

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
Enable and start the timer:

sudo systemctl daemon-reload
sudo systemctl enable deployment-monitor.timer
sudo systemctl start deployment-monitor.timer

# Check timer status
sudo systemctl status deployment-monitor.timer
Subtask 3.4: Create Environment Comparison Report
Create a script to compare package versions across environments:

sudo vi /usr/local/bin/environment-compare.sh
Add the following content:

#!/bin/bash

# Environment Package Comparison Tool
echo "=== Environment Package Comparison ==="
echo "Comparing package versions across environments"
echo "=============================================="

# Function to get package count for environment
get_package_count() {
    local env_name=$1
    local cv_name=$2
    
    echo "Checking $env_name environment..."
    
    # Get content view version in environment
    local version=$(hammer content-view version list \
        --content-view "$cv_name" \
        --environment "$env_name" \
        --organization "Default Organization" \
        --fields "Version" --csv | tail -n +2)
    
    if [ -n "$version" ]; then
        echo "  Content View Version: $version"
        
        # Get package count
        local pkg_count=$(hammer package list \
            --content-view "$cv_name" \
            --content-view-version "$version" \
            --organization "Default Organization" \
            --per-page 1 --fields "Total" --csv 2>/dev/null | tail -n +2)
        
        echo "  Package Count: ${pkg_count:-'Unable to determine'}"
    else
        echo "  No content view version found"
    fi
    echo ""
}

# Compare environments
CV_NAME="RHEL-BaseOS-CV"

for env in "Development" "Staging" "Production"; do
    get_package_count "$env" "$CV_NAME"
done
Make it executable and run:

sudo chmod +x /usr/local/bin/environment-compare.sh
sudo /usr/local/bin/environment-compare.sh
Subtask 3.5: Monitor Client System Status
Create a client monitoring script:

sudo vi /usr/local/bin/client-status.sh
Add the following content:

#!/bin/bash

# Client System Status Monitor
echo "=== Client System Status Report ==="
echo "Generated on: $(date)"
echo "==================================="

# Check subscription status
echo "Subscription Status:"
sudo subscription-manager status

echo ""
echo "Enabled Repositories:"
sudo dnf repolist enabled

echo ""
echo "Available Updates:"
sudo dnf check-update | wc -l
echo "packages have updates available"

echo ""
echo "Last Update Check:"
sudo dnf history | head -5

echo ""
echo "System Environment:"
# Check which lifecycle environment this system is using
if [ -f /etc/rhsm/rhsm.conf ]; then
    grep -E "(hostname|baseurl)" /etc/rhsm/rhsm.conf
fi
Make executable and run:

sudo chmod +x /usr/local/bin/client-status.sh
sudo /usr/local/bin/client-status.sh
Advanced Configuration and Best Practices
Creating Composite Content Views
For more complex scenarios, create composite content views:

Navigate to Content → Content Views

Click Create New View

Select Composite Content View

Configure:

Name: Enterprise-Stack-CV
Description: Complete enterprise application stack
Add multiple content views to create a comprehensive deployment package

Implementing Approval Workflows
Create a simple approval workflow:

# Create approval script
sudo vi /usr/local/bin/promotion-approval.sh
#!/bin/bash

# Simple promotion approval workflow
ENVIRONMENT=$1
CONTENT_VIEW=$2
VERSION=$3

if [ $# -ne 3 ]; then
    echo "Usage: $0 <environment> <content_view> <version>"
    exit 1
fi

echo "Promotion Request:"
echo "  Environment: $ENVIRONMENT"
echo "  Content View: $CONTENT_VIEW"
echo "  Version: $VERSION"
echo ""

read -p "Approve this promotion? (yes/no): " approval

if [ "$approval" = "yes" ]; then
    echo "Promotion approved. Executing..."
    hammer content-view version promote \
        --content-view "$CONTENT_VIEW" \
        --version "$VERSION" \
        --to-lifecycle-environment "$ENVIRONMENT" \
        --organization "Default Organization"
else
    echo "Promotion denied."
    exit 1
fi
Troubleshooting Common Issues
Issue 1: Promotion Fails
Symptoms: Promotion task shows error status

Solution:

# Check task details
hammer task info --id <task_id>

# Check disk space
df -h /var/lib/pulp

# Check service status
sudo systemctl status pulpcore-worker@*
Issue 2: Content View Won't Publish
Symptoms: Publication hangs or fails

Solution:

# Check for conflicting tasks
hammer task list --search "state = running"

# Restart pulp services if needed
sudo systemctl restart pulpcore-worker@*
sudo systemctl restart pulpcore-content
Issue 3: Client Can't Access Repository
Symptoms: dnf commands fail with repository errors

Solution:

# Re-register client
sudo subscription-manager unregister
sudo subscription-manager register --org="Default_Organization" --activationkey="your-key"

# Clean and refresh
sudo dnf clean all
sudo dnf makecache
Verification and Testing
Verify Environment Setup
Run this verification script:

#!/bin/bash
echo "=== Lab Verification Script ==="

# Check environments exist
echo "Checking lifecycle environments..."
for env in "Development" "Staging" "Production"; do
    if hammer lifecycle-environment info --name "$env" --organization "Default Organization" >/dev/null 2>&1; then
        echo "✓ $env environment exists"
    else
        echo "✗ $env environment missing"
    fi
done

# Check content view
echo ""
echo "Checking content view..."
if hammer content-view info --name "RHEL-BaseOS-CV" --organization "Default Organization" >/dev/null 2>&1; then
    echo "✓ Content view exists"
else
    echo "✗ Content view missing"
fi

# Check promotions
echo ""
echo "Checking promotions..."
hammer content-view version list --content-view "RHEL-BaseOS-CV" --organization "Default Organization"
Conclusion
In this lab, you have successfully:

Created a complete software life cycle management system with Development, Staging, and Production environments that follow industry best practices for controlled software deployment.

Implemented content promotion workflows that ensure software moves through proper testing phases before reaching production systems, reducing the risk of system failures.

Established comprehensive monitoring and tracking systems that provide visibility into deployment status across all environments, enabling proactive management of software updates.

Developed automation scripts for monitoring, comparison, and approval workflows that can be adapted for real-world enterprise environments.

Why This Matters
Software life cycle management is crucial for enterprise environments because it:

Reduces Risk: By testing updates in non-production environments first
Ensures Consistency: All systems in an environment have identical software versions
Provides Rollback Capability: Easy to revert to previous versions if issues arise
Enables Compliance: Maintains audit trails of all software changes
Improves Reliability: Systematic testing reduces production failures
Next Steps
To further enhance your software life cycle management skills:

Explore automated testing integration with your promotion workflows
Implement rollback procedures for failed deployments
Set up notification systems for promotion status updates
Create custom reports for management visibility
Integrate with configuration management tools like Ansible
The skills you've learned in this lab are directly applicable to Red Hat Satellite 6 Administration certification and real-world enterprise Linux management scenarios.
