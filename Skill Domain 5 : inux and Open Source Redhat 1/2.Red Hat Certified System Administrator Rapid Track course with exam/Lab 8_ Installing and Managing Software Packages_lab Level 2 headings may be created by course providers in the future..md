Lab 8: Installing and Managing Software Packages
Objectives
By the end of this lab, students will be able to:

• Install software packages using dnf and yum package managers • Query and search for installed packages using rpm and dnf commands • Remove unwanted software packages from the system • Update existing packages to their latest versions • Understand the difference between package managers and their use cases • Navigate package dependencies and resolve conflicts • Verify package integrity and installation status

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Familiarity with terminal navigation and file system structure • Knowledge of sudo privileges and user permissions • Understanding of what software packages are and why they're important • Basic text editor skills (nano, vim, or gedit)

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your Red Hat Enterprise Linux (RHEL) or CentOS environment. No need to build your own virtual machine or install additional software.

Your cloud machine includes: • Red Hat Enterprise Linux 8/9 or CentOS Stream • Pre-configured sudo access • Internet connectivity for package downloads • All necessary package management tools pre-installed

Task 1: Installing Packages Using DNF and YUM
Subtask 1.1: Understanding Package Managers
Package managers are tools that automate the process of installing, upgrading, configuring, and removing software packages. In Red Hat-based systems:

• DNF (Dandified YUM): The modern package manager for RHEL 8+ and Fedora • YUM (Yellowdog Updater Modified): The traditional package manager for older RHEL versions • RPM (Red Hat Package Manager): The low-level package management system

Subtask 1.2: Checking Your Package Manager
First, let's identify which package manager is available on your system:

# Check if dnf is available
which dnf

# Check if yum is available
which yum

# Check the version of your package manager
dnf --version
# OR
yum --version
Subtask 1.3: Updating Package Repository Information
Before installing packages, update your package repository cache:

# Update repository metadata
sudo dnf update
# OR for older systems
sudo yum update
Subtask 1.4: Installing Individual Packages
Let's install some useful packages step by step:

Installing a text editor (nano):

# Install nano text editor
sudo dnf install nano -y

# Verify installation
which nano
nano --version
Installing a system monitoring tool (htop):

# Install htop for system monitoring
sudo dnf install htop -y

# Test the installation
htop --version
Installing a network utility (wget):

# Install wget for downloading files
sudo dnf install wget -y

# Verify installation
wget --version
Subtask 1.5: Installing Multiple Packages at Once
You can install multiple packages in a single command:

# Install multiple packages simultaneously
sudo dnf install tree unzip zip curl -y

# Verify all installations
tree --version
unzip -v | head -1
zip -v | head -1
curl --version | head -1
Subtask 1.6: Installing Package Groups
Package groups are collections of related packages:

# List available package groups
dnf group list

# Install Development Tools group
sudo dnf group install "Development Tools" -y

# Verify installation by checking for gcc
gcc --version
Task 2: Querying Installed Packages with RPM and DNF
Subtask 2.1: Using RPM to Query Packages
RPM provides detailed information about installed packages:

List all installed packages:

# List all installed packages
rpm -qa | head -20

# Count total installed packages
rpm -qa | wc -l
Query specific package information:

# Check if a specific package is installed
rpm -q nano

# Get detailed information about a package
rpm -qi nano

# List files installed by a package
rpm -ql nano | head -10

# Find which package owns a specific file
rpm -qf /usr/bin/nano
Subtask 2.2: Using DNF to Query Packages
DNF provides more user-friendly querying options:

Search for packages:

# Search for packages containing 'editor' in name or description
dnf search editor

# Search for packages by exact name
dnf list nano

# List all installed packages
dnf list installed | head -20
Get package information:

# Show detailed information about a package
dnf info nano

# Show package dependencies
dnf deplist nano

# Check for available updates
dnf check-update
Subtask 2.3: Advanced Package Queries
Find packages that provide specific capabilities:

# Find packages that provide a specific file
dnf provides /usr/bin/python3

# Find packages that provide a specific capability
dnf provides "*/bin/gcc"

# List package history
dnf history list | head -10
Query package repositories:

# List enabled repositories
dnf repolist

# List all repositories (enabled and disabled)
dnf repolist all

# Search in specific repository
dnf repository-packages epel list
Task 3: Removing and Updating Packages
Subtask 3.1: Removing Individual Packages
Let's practice removing packages safely:

Remove a single package:

# Remove the tree package
sudo dnf remove tree -y

# Verify removal
which tree
# This should return nothing or "not found"
Remove packages with dependencies:

# Install a package with dependencies first
sudo dnf install httpd -y

# Check what depends on httpd
dnf deplist httpd

# Remove httpd and its unused dependencies
sudo dnf remove httpd -y

# Clean up orphaned dependencies
sudo dnf autoremove -y
Subtask 3.2: Updating Packages
Update a specific package:

# Check current version of a package
rpm -q kernel

# Update a specific package
sudo dnf update nano -y

# Verify the update
dnf info nano
Update all packages:

# Check for available updates
dnf check-update

# Update all packages (be careful in production!)
sudo dnf update -y

# Check update history
dnf history list | head -5
Subtask 3.3: Downgrading and Reinstalling Packages
Reinstall a package:

# Reinstall a package (useful if files are corrupted)
sudo dnf reinstall nano -y
Downgrade a package (if needed):

# Show available versions
dnf list nano --showduplicates

# Downgrade to a specific version (example)
# sudo dnf downgrade nano-2.9.8-1.el8
Subtask 3.4: Managing Package Cache
Clean package cache:

# Clean package cache to free disk space
sudo dnf clean all

# Check cache size before and after
du -sh /var/cache/dnf/
sudo dnf clean all
du -sh /var/cache/dnf/
Practical Exercise: Complete Package Management Scenario
Let's put everything together with a real-world scenario:

Scenario: Setting Up a Web Development Environment
Step 1: Install required packages

# Install web development tools
sudo dnf install httpd php php-mysql mariadb-server git -y
Step 2: Query the installation

# Verify all packages are installed
rpm -q httpd php php-mysql mariadb-server git

# Check what files httpd installed
rpm -ql httpd | grep bin
Step 3: Start and test services

# Start Apache web server
sudo systemctl start httpd
sudo systemctl enable httpd

# Check if it's running
systemctl status httpd
Step 4: Update and maintain

# Check for updates to our installed packages
dnf check-update httpd php php-mysql mariadb-server git

# Update if needed
sudo dnf update httpd php php-mysql mariadb-server git -y
Step 5: Clean up (optional)

# If you want to remove the web server later
sudo systemctl stop httpd
sudo systemctl disable httpd
sudo dnf remove httpd php php-mysql mariadb-server -y
sudo dnf autoremove -y
Troubleshooting Common Issues
Issue 1: Package Not Found
# If a package is not found, update repositories first
sudo dnf update

# Check if the package name is correct
dnf search package_name

# Check if additional repositories are needed
dnf repolist
Issue 2: Dependency Conflicts
# If there are dependency issues, try:
sudo dnf install package_name --best --allowerasing

# Or skip broken dependencies (use carefully)
sudo dnf install package_name --skip-broken
Issue 3: Disk Space Issues
# Check available disk space
df -h

# Clean package cache
sudo dnf clean all

# Remove orphaned packages
sudo dnf autoremove -y
Issue 4: Repository Issues
# If repositories are unreachable, check network
ping google.com

# Refresh repository metadata
sudo dnf clean metadata
sudo dnf update
Verification Commands
Use these commands to verify your lab completion:

# Check installed packages from this lab
rpm -q nano htop wget curl

# Verify package management commands work
dnf --version
rpm --version

# Check system update status
dnf check-update | head -5

# Verify repository access
dnf repolist enabled
Conclusion
In this lab, you have successfully learned how to:

• Install software packages using both dnf and yum package managers, including individual packages, multiple packages, and package groups • Query package information using rpm and dnf commands to find installed packages, check package details, and search for available software • Remove and update packages safely while managing dependencies and maintaining system integrity • Troubleshoot common package management issues that occur in real-world scenarios

These skills are fundamental for any Linux system administrator and are essential for the Red Hat Certified System Administrator certification. Package management is a daily task that ensures your systems remain secure, up-to-date, and properly configured with the software needed for your organization.

Why This Matters: Proper package management is crucial for system security, stability, and functionality. Understanding these tools allows you to maintain systems efficiently, deploy software consistently, and troubleshoot issues effectively. In enterprise environments, these skills help ensure that servers and workstations have the correct software versions and security updates needed for optimal operation.

Next Steps: Practice these commands regularly, explore advanced package management features like creating custom repositories, and learn about package signing and verification for enhanced security in production environments.
