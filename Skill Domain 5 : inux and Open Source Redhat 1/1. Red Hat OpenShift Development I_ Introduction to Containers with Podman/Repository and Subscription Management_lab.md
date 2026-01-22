Lab 17: Repository and Subscription Management
Objectives
Register a system with Red Hat Subscription Manager (RHSM)
Enable and disable repositories for software management
Install software from enabled repositories
Prerequisites
A Red Hat Enterprise Linux (RHEL) 8/9 system with root/sudo access
Active Red Hat subscription credentials
Internet connectivity
subscription-manager and dnf packages installed (default on RHEL)
Lab Setup
Ensure your system is updated:
sudo dnf update -y
Task 1: Register System with Red Hat Subscription Manager
Step 1.1: Verify Current Subscription Status
sudo subscription-manager status
Expected Output:
"Overall Status: Unknown" (if unregistered) or subscription details (if registered).

Step 1.2: Register System
Replace <username> and <password> with your Red Hat credentials:

sudo subscription-manager register --username=<username> --password=<password>
Troubleshooting:

If behind a corporate proxy, use --proxy=<proxy_URL> --proxyuser=<proxy_user> --proxypassword=<proxy_password>
For organizations with activation keys:
sudo subscription-manager register --org=<org_ID> --activationkey=<key>
Step 1.3: Attach a Subscription
sudo subscription-manager attach --auto
Verification:

sudo subscription-manager list --consumed
Task 2: Manage Repositories
Step 2.1: List Available Repositories
sudo subscription-manager repos --list
Step 2.2: Enable a Repository (e.g., RPMs)
sudo subscription-manager repos --enable=codeready-builder-for-rhel-9-$(arch)-rpms
Step 2.3: Disable a Repository
sudo subscription-manager repos --disable=codeready-builder-for-rhel-9-$(arch)-rpms
Step 2.4: Verify Enabled Repositories
sudo dnf repolist enabled
Task 3: Install Software from Repositories
Step 3.1: Search for a Package (e.g., Podman)
sudo dnf search podman
Step 3.2: Install the Package
sudo dnf install -y podman
Step 3.3: Verify Installation
podman --version
Expected Output:
podman version 4.x.x

Conclusion
Successfully registered the system with RHSM and attached a subscription.
Enabled/disabled repositories to control software sources.
Installed Podman from Red Hat repositories, demonstrating package management.
Key Concepts
Subscription Management: Required for accessing Red Hat's official repositories.
Repository: A storage location for RPM packages.
DNF: Next-generation package manager for RHEL.
Troubleshooting Tips
Registration Errors: Verify network connectivity and credentials.
Missing Repositories: Ensure the correct subscription is attached.
Package Not Found: Check repository availability with dnf repolist.
Next Steps
Explore advanced repository management with dnf config-manager.
Configure custom repositories for third-party software.
