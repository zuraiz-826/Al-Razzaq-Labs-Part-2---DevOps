Lab 7: Installing and Managing Software Packages
Objectives
By the end of this lab, you will be able to:

• Install software packages using dnf and yum package managers • Query and search for installed packages using rpm and dnf commands • Remove unwanted software packages from the system • Update existing packages to their latest versions • Understand the difference between package managers and their use cases • Navigate package dependencies and resolve conflicts • Verify package integrity and installation status

Prerequisites
Before starting this lab, you should have:

• Basic knowledge of Linux command line interface • Understanding of file system navigation using cd, ls, and pwd commands • Familiarity with text editors like vi or nano • Root or sudo privileges on a Red Hat-based Linux system • Basic understanding of what software packages are and why they're important

Lab Environment Setup
Al Nafi Cloud Machines: This lab uses Al Nafi's pre-configured Linux-based cloud machines. Simply click Start Lab to access your ready-to-use environment. No need to build your own virtual machine or configure any additional software.

Your cloud machine comes with: • Red Hat Enterprise Linux or CentOS/Rocky Linux • Pre-configured network connectivity • Root access privileges • All necessary package management tools installed

Task 1: Installing Packages Using dnf or yum
Subtask 1.1: Understanding Package Managers
Package managers are tools that automate the process of installing, upgrading, configuring, and removing software packages. In Red Hat-based systems:

• yum (Yellowdog Updater Modified) - Traditional package manager • dnf (Dandified YUM) - Modern replacement for yum with better performance • rpm (Red Hat Package Manager) - Low-level package management tool

Subtask 1.2: Checking Your Package Manager
First, let's identify which package manager is available on your system:

# Check if dnf is available
which dnf

# Check if yum is available
which yum

# Check system version
cat /etc/redhat-release
Note: On newer systems (RHEL 8+, CentOS 8+), dnf is the default. On older systems, yum is used. Many commands are interchangeable.

Subtask 1.3: Updating Package Repository Information
Before installing packages, update your package repository information:

# Using dnf (preferred for newer systems)
sudo dnf update

# Using yum (for older systems)
sudo yum update

# To update only repository metadata without upgrading packages
sudo dnf makecache
Subtask 1.4: Searching for Packages
Learn how to search for available packages:

# Search for a specific package
sudo dnf search wget

# Search for packages related to a keyword
sudo dnf search "text editor"

# Get detailed information about a package
sudo dnf info wget

# List all available packages
sudo dnf list available | head -20
Subtask 1.5: Installing Single Packages
Install individual software packages:

# Install wget (web file downloader)
sudo dnf install wget -y

# Install nano text editor
sudo dnf install nano -y

# Install tree (directory structure viewer)
sudo dnf install tree -y

# Verify installation
which wget
which nano
which tree
Subtask 1.6: Installing Multiple Packages
Install several packages in one command:

# Install multiple packages at once
sudo dnf install htop curl unzip -y

# Install packages from different groups
sudo dnf install git vim-enhanced bash-completion -y
Subtask 1.7: Installing Package Groups
Package groups contain related software packages:

# List available package groups
sudo dnf group list

# Install Development Tools group
sudo dnf group install "Development Tools" -y

# Install specific group (alternative syntax)
sudo dnf groupinstall "System Tools" -y
Task 2: Querying Installed Packages with rpm and dnf
Subtask 2.1: Using dnf to Query Packages
Query installed packages using dnf:

# List all installed packages
sudo dnf list installed | head -20

# Check if a specific package is installed
sudo dnf list installed | grep wget

# Show detailed information about an installed package
sudo dnf info wget

# List recently installed packages
sudo dnf history list | head -10
Subtask 2.2: Using rpm to Query Packages
The rpm command provides low-level package information:

# List all installed packages using rpm
rpm -qa | head -20

# Query specific package
rpm -q wget

# Get detailed information about a package
rpm -qi wget

# List files installed by a package
rpm -ql wget

# Find which package owns a specific file
rpm -qf /usr/bin/wget
Subtask 2.3: Advanced Package Queries
Perform more sophisticated package queries:

# List packages by installation date
rpm -qa --last | head -10

# Find packages that depend on a specific package
sudo dnf repoquery --whatrequires wget

# Show package dependencies
sudo dnf repoquery --requires wget

# List configuration files for a package
rpm -qc httpd
Subtask 2.4: Checking Package Integrity
Verify package integrity and files:

# Verify all files in a package
rpm -V wget

# Check if package files have been modified
rpm -Va | head -10

# Verify package signature
rpm -K /var/cache/dnf/*/packages/wget*.rpm
Task 3: Remove and Update Packages
Subtask 3.1: Updating Individual Packages
Update specific packages to their latest versions:

# Check for available updates
sudo dnf check-update

# Update a specific package
sudo dnf update wget -y

# Update multiple specific packages
sudo dnf update curl nano tree -y

# Show what would be updated without actually updating
sudo dnf update --assumeno
Subtask 3.2: Updating All Packages
Perform system-wide package updates:

# Update all packages on the system
sudo dnf update -y

# Update only security patches
sudo dnf update --security -y

# Download updates without installing
sudo dnf update --downloadonly
Subtask 3.3: Removing Individual Packages
Remove unwanted packages from your system:

# Remove a single package
sudo dnf remove tree -y

# Remove multiple packages
sudo dnf remove htop unzip -y

# Remove package and its dependencies (if not needed by other packages)
sudo dnf autoremove tree -y
Subtask 3.4: Removing Package Groups
Remove entire package groups:

# List installed groups
sudo dnf group list --installed

# Remove a package group
sudo dnf group remove "Development Tools" -y

# Remove group and its dependencies
sudo dnf group remove "System Tools" -y
Subtask 3.5: Advanced Removal Operations
Perform more sophisticated removal operations:

# Remove orphaned packages (no longer needed)
sudo dnf autoremove -y

# Remove packages installed as dependencies but no longer needed
sudo dnf remove --duplicates

# Clean package cache
sudo dnf clean all

# Remove old kernel versions (keep current and one previous)
sudo dnf remove $(dnf repoquery --installonly --latest-limit=-2 -q)
Subtask 3.6: Working with Package History
Manage package installation history:

# View package management history
sudo dnf history list

# Get details about a specific transaction
sudo dnf history info 1

# Undo a specific transaction
sudo dnf history undo 1

# Redo a specific transaction
sudo dnf history redo 1
Practical Exercise: Complete Package Management Scenario
Let's put everything together with a real-world scenario:

Step 1: System Preparation
# Update system and clean cache
sudo dnf update -y
sudo dnf clean all
sudo dnf makecache
Step 2: Install Web Server Environment
# Install Apache web server and related tools
sudo dnf install httpd php php-mysql mariadb-server -y

# Install additional utilities
sudo dnf install wget curl vim-enhanced -y

# Verify installations
rpm -q httpd php mariadb-server
Step 3: Query and Verify Installation
# Check installed web server packages
sudo dnf list installed | grep -E "(httpd|php|mariadb)"

# Get detailed information
sudo dnf info httpd

# List configuration files
rpm -qc httpd
Step 4: Update and Maintenance
# Check for updates
sudo dnf check-update

# Update web server components
sudo dnf update httpd php mariadb-server -y

# Clean up unnecessary packages
sudo dnf autoremove -y
Step 5: Selective Removal
# Remove development packages we don't need
sudo dnf remove php-mysql -y

# Verify removal
rpm -q php-mysql
Troubleshooting Common Issues
Issue 1: Package Conflicts
# If you encounter dependency conflicts
sudo dnf install package-name --skip-broken

# Force installation (use with caution)
sudo rpm -ivh package.rpm --force --nodeps
Issue 2: Corrupted Package Database
# Rebuild RPM database
sudo rpm --rebuilddb

# Clean and rebuild dnf cache
sudo dnf clean all
sudo dnf makecache
Issue 3: Network Issues
# Test repository connectivity
sudo dnf repolist

# Use specific repository
sudo dnf --enablerepo=repository-name install package-name
Best Practices
• Always update package repository information before installing new packages • Use -y flag carefully in scripts, but review changes in interactive sessions • Regularly clean package cache to save disk space • Keep track of installed packages for system documentation • Test package updates in non-production environments first • Use package groups for installing related software efficiently • Regularly remove orphaned packages to keep system clean

Security Considerations
• Verify package signatures when possible • Only install packages from trusted repositories • Keep systems updated with security patches • Review package dependencies before installation • Monitor package installation history for unauthorized changes

Conclusion
In this lab, you have successfully learned how to manage software packages on Red Hat-based Linux systems. You now understand how to:

• Install individual packages and package groups using dnf and yum • Query package information using both dnf and rpm commands • Update packages to maintain system security and functionality • Remove unwanted packages and clean up system dependencies • Troubleshoot common package management issues

These skills are fundamental for system administration and are essential for the Red Hat Certified System Administrator (RHCSA) certification. Package management is a daily task for Linux administrators, and mastering these tools will help you maintain secure, up-to-date, and efficient systems.

The ability to effectively manage software packages ensures that your systems have the necessary tools while maintaining security and stability. Continue practicing these commands in different scenarios to build confidence and expertise in Linux system administration.
