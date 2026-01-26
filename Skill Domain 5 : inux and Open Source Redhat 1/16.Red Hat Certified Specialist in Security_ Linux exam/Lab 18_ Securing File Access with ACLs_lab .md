Lab 18: Securing File Access with ACLs
Objectives
By the end of this lab, students will be able to:

Understand the concept and purpose of Access Control Lists (ACLs) in Linux
Implement ACLs on files and directories to provide granular access control
Use setfacl command to create and modify ACL entries
Use getfacl command to view and analyze existing ACL configurations
Test and validate ACL-based access restrictions
Troubleshoot common ACL permission issues
Apply ACL best practices for enterprise security scenarios
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux file system permissions (owner, group, other)
Familiarity with Linux command-line interface
Knowledge of user and group management in Linux
Understanding of file and directory operations
Basic text editor skills (nano, vim, or similar)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS system
Pre-installed ACL utilities (acl package)
Multiple user accounts for testing
Root/sudo access for administrative tasks
Task 1: Understanding and Implementing ACLs on Files and Directories
Subtask 1.1: Verify ACL Support and Install Required Tools
First, let's ensure that ACL support is available and properly configured on your system.

Step 1: Check if ACL support is enabled on your file system

# Check mount options for ACL support
mount | grep acl
Step 2: If ACL support is not enabled, remount the file system with ACL support

# For root partition (if needed)
sudo mount -o remount,acl /

# Verify ACL support is now enabled
mount | grep "/ "
Step 3: Install ACL utilities if not already present

# For RHEL/CentOS systems
sudo yum install acl -y

# For Ubuntu/Debian systems
sudo apt-get update
sudo apt-get install acl -y
Step 4: Verify ACL tools are installed

# Check if setfacl and getfacl are available
which setfacl
which getfacl
Subtask 1.2: Create Test Environment
Let's create a test environment with users, groups, and files to work with ACLs.

Step 1: Create test users and groups

# Create test users
sudo useradd alice
sudo useradd bob
sudo useradd charlie
sudo useradd diana

# Set passwords for test users
echo "alice:password123" | sudo chpasswd
echo "bob:password123" | sudo chpasswd
echo "charlie:password123" | sudo chpasswd
echo "diana:password123" | sudo chpasswd

# Create test groups
sudo groupadd developers
sudo groupadd managers
sudo groupadd auditors

# Add users to groups
sudo usermod -a -G developers alice
sudo usermod -a -G developers bob
sudo usermod -a -G managers charlie
sudo usermod -a -G auditors diana
Step 2: Create test directory structure

# Create main project directory
sudo mkdir -p /opt/project
sudo mkdir -p /opt/project/src
sudo mkdir -p /opt/project/docs
sudo mkdir -p /opt/project/config

# Create test files
sudo touch /opt/project/README.txt
sudo touch /opt/project/src/main.py
sudo touch /opt/project/docs/manual.pdf
sudo touch /opt/project/config/settings.conf

# Set initial ownership
sudo chown -R root:root /opt/project
sudo chmod -R 755 /opt/project
Subtask 1.3: Implement Basic ACLs on Files
Now let's implement ACLs to provide specific access permissions.

Step 1: Set ACL for a specific user on a file

# Give alice read and write access to README.txt
sudo setfacl -m u:alice:rw /opt/project/README.txt

# Verify the ACL was set
getfacl /opt/project/README.txt
Step 2: Set ACL for a specific group on a file

# Give developers group read and execute access to main.py
sudo setfacl -m g:developers:rx /opt/project/src/main.py

# Verify the ACL
getfacl /opt/project/src/main.py
Step 3: Set multiple ACL entries at once

# Set multiple ACL entries for the manual.pdf file
sudo setfacl -m u:charlie:r,g:managers:rw,u:diana:r /opt/project/docs/manual.pdf

# Verify the ACLs
getfacl /opt/project/docs/manual.pdf
Subtask 1.4: Implement ACLs on Directories
Directory ACLs are crucial for controlling access to entire directory trees.

Step 1: Set ACL on a directory

# Give alice full access to the src directory
sudo setfacl -m u:alice:rwx /opt/project/src

# Give developers group read and execute access
sudo setfacl -m g:developers:rx /opt/project/src

# Verify directory ACL
getfacl /opt/project/src
Step 2: Set default ACLs for new files in directory

# Set default ACLs that will be inherited by new files
sudo setfacl -d -m u:alice:rw /opt/project/src
sudo setfacl -d -m g:developers:r /opt/project/src
sudo setfacl -d -m other::--- /opt/project/src

# Verify default ACLs
getfacl /opt/project/src
Step 3: Test default ACL inheritance

# Create a new file in the directory
sudo touch /opt/project/src/newfile.py

# Check if it inherited the default ACLs
getfacl /opt/project/src/newfile.py
Task 2: Managing and Modifying ACLs using setfacl and getfacl
Subtask 2.1: Advanced setfacl Operations
Let's explore advanced ACL management techniques.

Step 1: Modify existing ACL entries

# Change alice's permissions on README.txt from rw to rwx
sudo setfacl -m u:alice:rwx /opt/project/README.txt

# Verify the change
getfacl /opt/project/README.txt
Step 2: Remove specific ACL entries

# Remove alice's ACL entry from README.txt
sudo setfacl -x u:alice /opt/project/README.txt

# Remove developers group ACL from main.py
sudo setfacl -x g:developers /opt/project/src/main.py

# Verify removals
getfacl /opt/project/README.txt
getfacl /opt/project/src/main.py
Step 3: Remove all ACLs from a file

# Create a file with multiple ACLs
sudo touch /opt/project/test_acl.txt
sudo setfacl -m u:alice:rw,u:bob:r,g:developers:rw /opt/project/test_acl.txt

# View current ACLs
getfacl /opt/project/test_acl.txt

# Remove all ACLs (keeping base permissions)
sudo setfacl -b /opt/project/test_acl.txt

# Verify all ACLs are removed
getfacl /opt/project/test_acl.txt
Subtask 2.2: Recursive ACL Operations
Learn how to apply ACLs recursively to directory trees.

Step 1: Apply ACLs recursively to all files and subdirectories

# Apply ACLs recursively to the entire project directory
sudo setfacl -R -m u:alice:rwx /opt/project
sudo setfacl -R -m g:developers:rx /opt/project

# Verify recursive application
getfacl /opt/project
getfacl /opt/project/src
getfacl /opt/project/docs
getfacl /opt/project/README.txt
Step 2: Set default ACLs recursively for all directories

# Set default ACLs for all directories recursively
find /opt/project -type d -exec sudo setfacl -d -m u:alice:rwx {} \;
find /opt/project -type d -exec sudo setfacl -d -m g:developers:rx {} \;

# Verify default ACLs on directories
getfacl /opt/project/src
getfacl /opt/project/docs
Subtask 2.3: Using getfacl for ACL Analysis
Master the getfacl command for comprehensive ACL analysis.

Step 1: Basic getfacl usage with different output formats

# Standard output
getfacl /opt/project/README.txt

# Compact output (no comments)
getfacl -c /opt/project/README.txt

# Omit header comments
getfacl --omit-header /opt/project/README.txt
Step 2: Recursive ACL listing

# List ACLs for all files and directories recursively
getfacl -R /opt/project

# Save ACL information to a file for backup
getfacl -R /opt/project > /tmp/project_acls_backup.txt

# View the backup file
head -20 /tmp/project_acls_backup.txt
Step 3: Restore ACLs from backup

# First, remove all ACLs
sudo setfacl -R -b /opt/project

# Verify ACLs are removed
getfacl /opt/project/README.txt

# Restore ACLs from backup file
sudo setfacl --restore=/tmp/project_acls_backup.txt

# Verify restoration
getfacl /opt/project/README.txt
Task 3: Testing ACL-Based Access Restrictions
Subtask 3.1: Create Comprehensive Test Scenarios
Let's create realistic scenarios to test ACL effectiveness.

Step 1: Set up a complex ACL scenario

# Create a sensitive configuration directory
sudo mkdir -p /opt/project/sensitive
sudo touch /opt/project/sensitive/database.conf
sudo touch /opt/project/sensitive/api_keys.txt

# Set restrictive base permissions
sudo chmod 700 /opt/project/sensitive
sudo chmod 600 /opt/project/sensitive/*

# Set specific ACLs
sudo setfacl -m u:alice:rwx /opt/project/sensitive
sudo setfacl -m u:charlie:rx /opt/project/sensitive
sudo setfacl -m u:alice:rw /opt/project/sensitive/database.conf
sudo setfacl -m u:charlie:r /opt/project/sensitive/database.conf
sudo setfacl -m u:diana:r /opt/project/sensitive/api_keys.txt

# Verify ACL setup
getfacl /opt/project/sensitive
getfacl /opt/project/sensitive/database.conf
getfacl /opt/project/sensitive/api_keys.txt
Subtask 3.2: Test User Access with Different Scenarios
Now let's test the ACLs by switching to different users.

Step 1: Test alice's access (should have full access to sensitive directory)

# Switch to alice and test access
sudo su - alice -c "ls -la /opt/project/sensitive"
sudo su - alice -c "cat /opt/project/sensitive/database.conf"
sudo su - alice -c "echo 'test content' >> /opt/project/sensitive/database.conf"
sudo su - alice -c "cat /opt/project/sensitive/database.conf"
Step 2: Test charlie's access (should have read access to directory and database.conf)

# Switch to charlie and test access
sudo su - charlie -c "ls -la /opt/project/sensitive"
sudo su - charlie -c "cat /opt/project/sensitive/database.conf"

# This should fail (no write permission)
sudo su - charlie -c "echo 'unauthorized change' >> /opt/project/sensitive/database.conf" 2>&1 || echo "Access denied as expected"

# This should fail (no access to api_keys.txt)
sudo su - charlie -c "cat /opt/project/sensitive/api_keys.txt" 2>&1 || echo "Access denied as expected"
Step 3: Test diana's access (should only read api_keys.txt)

# Switch to diana and test access
sudo su - diana -c "cat /opt/project/sensitive/api_keys.txt"

# These should fail
sudo su - diana -c "ls /opt/project/sensitive" 2>&1 || echo "Directory access denied as expected"
sudo su - diana -c "cat /opt/project/sensitive/database.conf" 2>&1 || echo "File access denied as expected"
Step 4: Test bob's access (should have no access)

# Switch to bob and test access - all should fail
sudo su - bob -c "ls /opt/project/sensitive" 2>&1 || echo "Access denied as expected"
sudo su - bob -c "cat /opt/project/sensitive/database.conf" 2>&1 || echo "Access denied as expected"
sudo su - bob -c "cat /opt/project/sensitive/api_keys.txt" 2>&1 || echo "Access denied as expected"
Subtask 3.3: Test Group-Based ACL Access
Let's test group-based ACL functionality.

Step 1: Set up group-based ACLs

# Create a shared project directory
sudo mkdir -p /opt/project/shared
sudo touch /opt/project/shared/team_document.txt

# Set group-based ACLs
sudo setfacl -m g:developers:rw /opt/project/shared/team_document.txt
sudo setfacl -m g:managers:r /opt/project/shared/team_document.txt
sudo setfacl -m g:auditors:r /opt/project/shared/team_document.txt

# Verify ACLs
getfacl /opt/project/shared/team_document.txt
Step 2: Test group access

# Test alice (developers group) - should have read/write
sudo su - alice -c "echo 'Development notes' >> /opt/project/shared/team_document.txt"
sudo su - alice -c "cat /opt/project/shared/team_document.txt"

# Test charlie (managers group) - should have read only
sudo su - charlie -c "cat /opt/project/shared/team_document.txt"
sudo su - charlie -c "echo 'Manager notes' >> /opt/project/shared/team_document.txt" 2>&1 || echo "Write access denied as expected"

# Test diana (auditors group) - should have read only
sudo su - diana -c "cat /opt/project/shared/team_document.txt"
sudo su - diana -c "echo 'Audit notes' >> /opt/project/shared/team_document.txt" 2>&1 || echo "Write access denied as expected"
Subtask 3.4: Test ACL Inheritance
Test how ACLs are inherited by new files and directories.

Step 1: Create directory with default ACLs

# Create a new directory for testing inheritance
sudo mkdir -p /opt/project/inheritance_test

# Set default ACLs
sudo setfacl -d -m u:alice:rwx /opt/project/inheritance_test
sudo setfacl -d -m g:developers:rw /opt/project/inheritance_test
sudo setfacl -d -m other::--- /opt/project/inheritance_test

# Also set access ACLs for the directory itself
sudo setfacl -m u:alice:rwx /opt/project/inheritance_test
sudo setfacl -m g:developers:rx /opt/project/inheritance_test

# Verify default ACLs
getfacl /opt/project/inheritance_test
Step 2: Test inheritance with new files

# Create new files as different users
sudo su - alice -c "touch /opt/project/inheritance_test/alice_file.txt"
sudo su - alice -c "echo 'Alice created this file' > /opt/project/inheritance_test/alice_file.txt"

# Check inherited ACLs
getfacl /opt/project/inheritance_test/alice_file.txt

# Test access by other users
sudo su - bob -c "cat /opt/project/inheritance_test/alice_file.txt"
sudo su - bob -c "echo 'Bob adding content' >> /opt/project/inheritance_test/alice_file.txt"
Step 3: Test inheritance with subdirectories

# Create subdirectory
sudo su - alice -c "mkdir /opt/project/inheritance_test/subdir"

# Check inherited ACLs on subdirectory
getfacl /opt/project/inheritance_test/subdir

# Create file in subdirectory
sudo su - alice -c "touch /opt/project/inheritance_test/subdir/nested_file.txt"

# Check ACLs on nested file
getfacl /opt/project/inheritance_test/subdir/nested_file.txt
Troubleshooting Common ACL Issues
Issue 1: ACL Not Supported Error
Problem: Getting "Operation not supported" when using setfacl

Solution:

# Check if file system supports ACLs
tune2fs -l /dev/sda1 | grep "Default mount options"

# If ACL is not listed, remount with ACL support
sudo mount -o remount,acl /
Issue 2: Permission Denied Despite ACL
Problem: User still gets permission denied even with proper ACL

Solution:

# Check effective permissions
getfacl filename

# Verify user group membership
groups username

# Check if there are conflicting base permissions
ls -l filename
Issue 3: ACLs Not Inherited
Problem: New files don't inherit default ACLs

Solution:

# Verify default ACLs are set on parent directory
getfacl -d /path/to/directory

# Set default ACLs if missing
sudo setfacl -d -m u:user:permissions /path/to/directory
Best Practices for ACL Implementation
Security Best Practices
Principle of Least Privilege: Grant only the minimum permissions necessary
Regular ACL Audits: Periodically review and clean up ACLs
Document ACL Policies: Maintain documentation of ACL implementations
Use Groups When Possible: Prefer group-based ACLs over individual user ACLs
Test ACL Changes: Always test ACL modifications in a safe environment
Performance Considerations
Limit ACL Complexity: Avoid overly complex ACL structures
Use Default ACLs Wisely: Set appropriate default ACLs to reduce management overhead
Monitor File System Performance: ACLs can impact file system performance
Management Best Practices
Backup ACLs: Regularly backup ACL configurations
Standardize ACL Policies: Develop standard ACL templates for common scenarios
Automate ACL Management: Use scripts for repetitive ACL operations
Train Users: Educate users about ACL concepts and limitations
Conclusion
In this comprehensive lab, you have successfully learned how to implement and manage Access Control Lists (ACLs) in Linux environments. You have accomplished the following key objectives:

What You Learned:

ACL Fundamentals: Understanding how ACLs extend traditional Linux permissions to provide granular access control
Implementation Skills: Successfully implemented ACLs on both files and directories using the setfacl command
Management Techniques: Mastered the use of getfacl and setfacl for viewing, modifying, and removing ACL entries
Access Testing: Validated ACL effectiveness through comprehensive testing scenarios with multiple users and groups
Inheritance Concepts: Learned how default ACLs work and how they are inherited by new files and directories
Troubleshooting: Gained experience in identifying and resolving common ACL-related issues
Why This Matters: ACLs are essential for enterprise security environments where traditional Linux permissions (owner, group, other) are insufficient. They provide the flexibility needed to implement complex security policies while maintaining system performance and usability. This knowledge is particularly valuable for:

System Administrators: Managing multi-user environments with complex permission requirements
Security Professionals: Implementing defense-in-depth strategies and access controls
DevOps Engineers: Securing application deployments and shared development environments
Compliance Requirements: Meeting regulatory requirements for access control and audit trails
Real-World Applications: The skills you've developed in this lab directly apply to scenarios such as:

Securing shared project directories in development teams
Implementing role-based access control in enterprise environments
Managing sensitive configuration files and databases
Controlling access to audit logs and compliance documentation
Setting up secure file sharing systems
You are now equipped with the knowledge and practical experience to implement robust file access security using ACLs in production Linux environments, contributing to your preparation for the Red Hat Certified Specialist in Security: Linux exam and real-world security implementations.
