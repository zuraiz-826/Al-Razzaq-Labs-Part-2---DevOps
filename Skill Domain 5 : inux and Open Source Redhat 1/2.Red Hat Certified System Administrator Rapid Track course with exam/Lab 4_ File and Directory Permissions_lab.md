Lab 4: File and Directory Permissions
Objectives
By the end of this lab, students will be able to:

• Understand Linux file permission concepts including read, write, and execute permissions • Use the chmod command to modify file and directory permissions using both numeric and symbolic notation • Apply the chown command to change file and directory ownership • Implement Access Control Lists (ACLs) using setfacl for advanced permission management • Verify permission changes using ls -l and getfacl commands • Troubleshoot common permission-related issues in Linux systems

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Familiarity with file system navigation using commands like cd, ls, and pwd • Knowledge of basic file operations such as creating, copying, and moving files • Understanding of user accounts and groups in Linux • Access to a terminal or command prompt

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machine or install additional software.

Your cloud machine includes: • CentOS/RHEL-based Linux distribution • Pre-installed ACL utilities • Multiple user accounts for testing • Root access for administrative tasks

Task 1: Change File Permissions with chmod
Understanding File Permissions
Linux file permissions control who can read, write, or execute files and directories. Permissions are displayed using the format: rwxrwxrwx where: • First three characters: Owner permissions • Next three characters: Group permissions
• Last three characters: Other users permissions

Each position represents: • r = read permission (4) • w = write permission (2) • x = execute permission (1)

Subtask 1.1: Create Test Files and Examine Default Permissions
Create a working directory and navigate to it:
mkdir ~/permissions_lab
cd ~/permissions_lab
Create test files with different content:
echo "This is a regular text file" > textfile.txt
echo "#!/bin/bash" > script.sh
echo "echo 'Hello World'" >> script.sh
mkdir testdir
Examine current permissions:
ls -l
Expected Output:

-rw-rw-r-- 1 student student   29 Nov 15 10:30 textfile.txt
-rw-rw-r-- 1 student student   32 Nov 15 10:30 script.sh
drwxrwxr-x 2 student student 4096 Nov 15 10:30 testdir
Subtask 1.2: Using Numeric (Octal) Notation
Make the script executable using numeric notation:
chmod 755 script.sh
ls -l script.sh
Expected Output:

-rwxr-xr-x 1 student student 32 Nov 15 10:30 script.sh
Set restrictive permissions on the text file:
chmod 600 textfile.txt
ls -l textfile.txt
Expected Output:

-rw------- 1 student student 29 Nov 15 10:30 textfile.txt
Test the script execution:
./script.sh
Subtask 1.3: Using Symbolic Notation
Add execute permission for group and others on script:
chmod g+x,o+x script.sh
ls -l script.sh
Remove write permission for group on textfile:
chmod g-w textfile.txt
ls -l textfile.txt
Set multiple permissions at once:
chmod u+rw,g+r,o-rwx textfile.txt
ls -l textfile.txt
Subtask 1.4: Directory Permissions
Create files inside the test directory:
echo "Directory content" > testdir/file1.txt
echo "More content" > testdir/file2.txt
Remove execute permission from directory:
chmod -x testdir
ls -l
Try to access the directory:
ls testdir
cd testdir
Note: You should receive permission denied errors.

Restore execute permission:
chmod +x testdir
ls testdir
Task 2: Modify File Ownership with chown
Understanding File Ownership
Every file and directory has an owner (user) and a group. The chown command changes ownership, while chgrp changes group ownership.

Subtask 2.1: Create Additional User Account
Switch to root user (if not already):
sudo su -
Create a new user account:
useradd testuser
passwd testuser
Enter a simple password when prompted (e.g., "password123")

Create a new group:
groupadd testgroup
Add testuser to testgroup:
usermod -a -G testgroup testuser
Return to your regular user:
exit
Subtask 2.2: Change File Ownership
Check current ownership of files:
ls -l ~/permissions_lab/
Change owner of textfile.txt (requires sudo):
sudo chown testuser ~/permissions_lab/textfile.txt
ls -l ~/permissions_lab/textfile.txt
Expected Output:

-rw-r----- 1 testuser student 29 Nov 15 10:30 textfile.txt
Change both owner and group:
sudo chown testuser:testgroup ~/permissions_lab/script.sh
ls -l ~/permissions_lab/script.sh
Subtask 2.3: Recursive Ownership Changes
Change ownership of directory and all contents:
sudo chown -R testuser:testgroup ~/permissions_lab/testdir
ls -l ~/permissions_lab/
ls -l ~/permissions_lab/testdir/
Change only group ownership:
sudo chgrp student ~/permissions_lab/textfile.txt
ls -l ~/permissions_lab/textfile.txt
Task 3: Set Access Control Lists using setfacl
Understanding Access Control Lists (ACLs)
ACLs provide more granular permission control than traditional Unix permissions, allowing you to set permissions for specific users and groups beyond the owner/group/other model.

Subtask 3.1: Install and Verify ACL Support
Check if ACL utilities are installed:
which setfacl getfacl
If not installed, install ACL utilities:
sudo yum install acl -y
For Ubuntu/Debian systems:

sudo apt-get install acl -y
Verify filesystem supports ACLs:
mount | grep acl
Subtask 3.2: Set Basic ACLs
Create a new test file:
cd ~/permissions_lab
echo "ACL test content" > acltest.txt
ls -l acltest.txt
View current ACL:
getfacl acltest.txt
Expected Output:

# file: acltest.txt
# owner: student
# group: student
user::rw-
group::rw-
other::r--
Grant read and write access to testuser:
setfacl -m u:testuser:rw acltest.txt
getfacl acltest.txt
Notice the '+' symbol in ls output indicating ACL:
ls -l acltest.txt
Subtask 3.3: Advanced ACL Operations
Set ACL for a group:
setfacl -m g:testgroup:r acltest.txt
getfacl acltest.txt
Set default ACLs on directory:
setfacl -m d:u:testuser:rwx testdir
setfacl -m d:g:testgroup:rx testdir
getfacl testdir
Create a file in the directory to test default ACLs:
echo "Testing default ACL" > testdir/newfile.txt
getfacl testdir/newfile.txt
Subtask 3.4: Remove and Modify ACLs
Remove specific ACL entry:
setfacl -x u:testuser acltest.txt
getfacl acltest.txt
Remove all ACLs:
setfacl -b acltest.txt
getfacl acltest.txt
ls -l acltest.txt
Note: The '+' symbol should disappear from ls output.

Set multiple ACLs at once:
setfacl -m u:testuser:rw,g:testgroup:r,o::--- acltest.txt
getfacl acltest.txt
Verification and Testing
Test Permission Changes
Create a comprehensive test script:
cat > permission_test.sh << 'EOF'
#!/bin/bash
echo "=== Permission Testing Script ==="
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
echo ""

echo "=== File Permissions ==="
ls -l *.txt *.sh 2>/dev/null

echo ""
echo "=== Directory Permissions ==="
ls -ld testdir

echo ""
echo "=== ACL Information ==="
echo "Files with ACLs:"
ls -l | grep "+"

echo ""
echo "=== Detailed ACL for acltest.txt ==="
getfacl acltest.txt 2>/dev/null

echo ""
echo "=== Testing file access ==="
if [ -r textfile.txt ]; then
    echo "✓ Can read textfile.txt"
else
    echo "✗ Cannot read textfile.txt"
fi

if [ -x script.sh ]; then
    echo "✓ Can execute script.sh"
else
    echo "✗ Cannot execute script.sh"
fi
EOF
Make the test script executable and run it:
chmod +x permission_test.sh
./permission_test.sh
Troubleshooting Common Issues
Issue 1: Permission Denied Errors
Problem: Cannot access files or directories Solution:

# Check current permissions
ls -l filename
# Check if you're in the right group
groups
# Verify ACLs if applicable
getfacl filename
Issue 2: ACL Commands Not Found
Problem: setfacl or getfacl commands not available Solution:

# Install ACL utilities
sudo yum install acl -y
# or for Ubuntu/Debian
sudo apt-get install acl -y
Issue 3: ACLs Not Working
Problem: ACLs not being applied or recognized Solution:

# Check if filesystem supports ACLs
mount | grep acl
# Remount with ACL support if needed
sudo mount -o remount,acl /
Best Practices
Security Considerations
Principle of Least Privilege:

Grant minimum permissions necessary
Regularly audit file permissions
Use ACLs for granular control when needed
Common Permission Patterns:

Executable files: 755 (rwxr-xr-x)
Configuration files: 644 (rw-r--r--)
Sensitive files: 600 (rw-------)
Directories: 755 (rwxr-xr-x)
ACL Best Practices:

Document ACL usage
Use default ACLs for consistent directory permissions
Regular ACL audits
Conclusion
In this lab, you have successfully learned and practiced essential Linux file and directory permission management skills. You accomplished the following:

Key Achievements: • Mastered the chmod command using both numeric (755, 644) and symbolic (u+x, g-w) notation to control file access • Applied the chown command to change file ownership and group assignments, understanding the security implications • Implemented Access Control Lists (ACLs) using setfacl for advanced permission scenarios beyond traditional Unix permissions • Learned to verify and troubleshoot permission settings using ls -l and getfacl commands

Why This Matters: File permissions are fundamental to Linux security and system administration. These skills are essential for: • Protecting sensitive data and system files • Ensuring proper application functionality • Meeting compliance and security requirements • Troubleshooting access-related issues in production environments

Red Hat Certification Relevance: The skills practiced in this lab directly support Red Hat Certified System Administrator (RHCSA) exam objectives, particularly in areas of file permissions, ownership management, and access control. These are core competencies expected of Linux system administrators in enterprise environments.

You are now equipped with the knowledge to manage file permissions effectively in real-world Linux environments, ensuring both security and functionality in your systems.
