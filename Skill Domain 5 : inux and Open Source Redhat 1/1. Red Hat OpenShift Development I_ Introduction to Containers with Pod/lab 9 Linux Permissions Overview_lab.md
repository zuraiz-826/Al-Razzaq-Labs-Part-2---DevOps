Lab 9: Linux Permissions Overview
Objectives
By the end of this lab, you will:

Understand Linux file and directory permissions.
Use ls -l to view permissions.
Modify permissions using chmod.
Change file ownership and group assignments using chown and chgrp.
Prerequisites
A Linux-based system (Ubuntu, CentOS, Fedora, etc.).
Basic familiarity with the Linux command line.
A non-root user with sudo privileges.
Task 1: Viewing File and Directory Permissions
Step 1: Check Current Permissions
Open a terminal.
Run the following command to list files with detailed permissions:
ls -l
Expected Output:
-rw-r--r-- 1 user group 1024 Jan 1 10:00 file.txt
drwxr-xr-x 2 user group 4096 Jan 1 10:01 directory
Explanation:
-rw-r--r-- indicates file permissions.
drwxr-xr-x indicates directory permissions.
The first character (- or d) denotes file type.
The next nine characters represent permissions for owner, group, and others.
Step 2: Understanding Permission Notation
Permission Breakdown:

r = Read
w = Write
x = Execute
- = No permission
Example:

rwxr-xr-- means:
Owner: Read, Write, Execute
Group: Read, Execute
Others: Read
Task 2: Modifying Permissions with chmod
Step 1: Change Permissions Using Symbolic Mode
Create a test file:
touch testfile.txt
Modify permissions to rw-r----- (Owner: Read/Write, Group: Read, Others: No access):
chmod 640 testfile.txt
Verify changes:
ls -l testfile.txt
Expected Output:
-rw-r----- 1 user group 0 Jan 1 10:05 testfile.txt
Step 2: Change Permissions Using Symbolic Notation
Add execute permission for the owner:
chmod u+x testfile.txt
Remove read permission for others:
chmod o-r testfile.txt
Verify changes:
ls -l testfile.txt
Expected Output:
-rwxr----- 1 user group 0 Jan 1 10:05 testfile.txt
Troubleshooting Tip:

If you get a "Permission denied" error, ensure you have the necessary rights (use sudo if required).
Task 3: Changing Ownership and Group with chown and chgrp
Step 1: Change File Ownership
Create a new user (if needed):
sudo useradd testuser
Change the owner of testfile.txt to testuser:
sudo chown testuser testfile.txt
Verify the change:
ls -l testfile.txt
Expected Output:
-rwxr----- 1 testuser group 0 Jan 1 10:05 testfile.txt
Step 2: Change Group Ownership
Create a new group (if needed):
sudo groupadd testgroup
Change the group of testfile.txt to testgroup:
sudo chgrp testgroup testfile.txt
Verify the change:
ls -l testfile.txt
Expected Output:
-rwxr----- 1 testuser testgroup 0 Jan 1 10:05 testfile.txt
Alternative Method (Using chown for Both Owner and Group):

sudo chown testuser:testgroup testfile.txt
Conclusion
In this lab, you learned how to:

View file and directory permissions using ls -l.
Modify permissions using chmod (numeric and symbolic modes).
Change ownership (chown) and group (chgrp) of files.
These skills are essential for managing security and access control in Linux environments, particularly in containerized applications (e.g., Red Hat OpenShift).

Next Steps:

Experiment with different permission combinations.
Explore umask for default permission settings.
Apply these concepts in a Podman container environment.
Lab Complete! 🎉
