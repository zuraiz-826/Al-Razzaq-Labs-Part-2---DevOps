Lab 16: Installing and Managing Software in RHEL
Objectives
By the end of this lab, you will be able to:

Install, update, and remove software packages using yum or dnf.
Configure additional repositories for package management.
Resolve and manage package dependencies.
Prerequisites
A RHEL 8/9 system (or CentOS/Rocky Linux as open-source alternatives).
Sudo or root access.
Active internet connection.
Task 1: Installing Packages with yum or dnf
Subtask 1.1: Check Available Package Managers
RHEL 8+ uses dnf (Dandified YUM) as the default package manager, though yum is still available as a symlink.

Verify which package manager is installed:

which dnf yum
Expected Output:

/usr/bin/dnf  
/usr/bin/yum  
Check the version:

dnf --version
Expected Output: Displays version details.

Subtask 1.2: Install a Package
Install the htop system monitor:

sudo dnf install htop -y
Expected Output: Confirmation of installation and dependencies resolved.

Troubleshooting Tip:

If dnf fails, check internet connectivity (ping google.com).
Ensure repositories are enabled (sudo dnf repolist).
Task 2: Updating and Removing Packages
Subtask 2.1: Update All Packages
sudo dnf update -y
Expected Output: Lists packages to be updated and applies changes.

Subtask 2.2: Remove a Package
Remove htop:

sudo dnf remove htop -y
Expected Output: Confirmation of package removal.

Key Concept:

dnf autoremove removes unused dependencies.
Task 3: Configuring Repositories and Managing Dependencies
Subtask 3.1: List Enabled Repositories
sudo dnf repolist
Expected Output: Lists active repositories (e.g., AppStream, BaseOS).

Subtask 3.2: Add the EPEL Repository
EPEL (Extra Packages for Enterprise Linux) provides additional open-source packages.

Install EPEL release package:
sudo dnf install epel-release -y
Verify:
sudo dnf repolist | grep epel
Expected Output: Shows epel repository in the list.
Subtask 3.3: Resolve Dependencies
Install a package with complex dependencies (e.g., nginx):

sudo dnf install nginx -y
Expected Output: Shows dependency resolution and installation.

Troubleshooting Tip:

If dependencies fail, run sudo dnf clean all and retry.
Conclusion
In this lab, you:

Installed, updated, and removed packages using dnf.
Configured the EPEL repository for additional software.
Managed package dependencies effectively.
Next Steps:

Explore dnf history to audit changes.
Practice with rpm for low-level package queries.
Final Command to Verify Skills:

dnf list installed | grep -E 'nginx|htop'
Expected Output: Lists installed packages (if any).

Lab Complete 🎉
