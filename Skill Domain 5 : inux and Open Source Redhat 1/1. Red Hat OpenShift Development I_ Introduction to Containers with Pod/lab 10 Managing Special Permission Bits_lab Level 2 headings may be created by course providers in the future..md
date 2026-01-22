Lab 10: Managing Special Permission Bits
Objectives
By the end of this lab, you will be able to:

Understand and apply the sticky bit on shared directories to enhance security.
Configure setuid and setgid permissions on executables to control access.
Verify the effectiveness of these special permission bits in a Linux environment.
Prerequisites
A Linux system (e.g., Fedora, CentOS, or Ubuntu) with root or sudo access.
Basic familiarity with Linux file permissions (chmod, ls -l).
A terminal or command-line interface.
Lab Tasks
Task 1: Set the Sticky Bit on a Shared Directory
The sticky bit ensures that only the file owner can delete or rename files in a shared directory, even if other users have write permissions.

Subtask 1.1: Create a Shared Directory
Open a terminal.
Create a shared directory named shared_dir:
mkdir /tmp/shared_dir
Set read, write, and execute permissions for all users:
chmod 777 /tmp/shared_dir
Verify the permissions:
ls -ld /tmp/shared_dir
Expected Output:
drwxrwxrwx 2 user user 4096 Jun 1 10:00 /tmp/shared_dir
Subtask 1.2: Apply the Sticky Bit
Set the sticky bit using chmod +t:
chmod +t /tmp/shared_dir
Verify the sticky bit is set:
ls -ld /tmp/shared_dir
Expected Output:
drwxrwxrwt 2 user user 4096 Jun 1 10:00 /tmp/shared_dir
(Note the t in permissions, indicating the sticky bit.)
Subtask 1.3: Test the Sticky Bit
Create a file as user1:
touch /tmp/shared_dir/user1_file
Switch to another user (or simulate it using sudo):
sudo -u nobody touch /tmp/shared_dir/nobody_file
Attempt to delete user1_file as nobody:
sudo -u nobody rm /tmp/shared_dir/user1_file
Expected Outcome:
Permission denied (only the owner or root can delete the file).
Task 2: Apply setuid and setgid on Executables
The setuid and setgid bits allow executables to run with the permissions of the file owner or group.

Subtask 2.1: Create a Test Executable
Write a simple script that displays the effective user ID (EUID):
echo '#!/bin/bash
echo "Effective UID: $EUID"' > /usr/local/bin/show_euid
Make it executable:
chmod +x /usr/local/bin/show_euid
Subtask 2.2: Apply setuid
Set the setuid bit:

chmod u+s /usr/local/bin/show_euid
Verify:

ls -l /usr/local/bin/show_euid
Expected Output:
-rwsr-xr-x 1 root root 45 Jun 1 10:05 /usr/local/bin/show_euid
(Note the s in place of x for the owner.)

Test as a non-root user:

sudo -u nobody /usr/local/bin/show_euid
Expected Output:
Effective UID: 0 (if owned by root) or the owner's UID.

Subtask 2.3: Apply setgid
Create a group and assign ownership:
groupadd testgroup
chown :testgroup /usr/local/bin/show_euid
Set the setgid bit:
chmod g+s /usr/local/bin/show_euid
Verify:
ls -l /usr/local/bin/show_euid
Expected Output:
-rwsr-sr-x 1 root testgroup 45 Jun 1 10:05 /usr/local/bin/show_euid
(Note the s in group permissions.)
Task 3: Verify the Effectiveness of Permissions
Subtask 3.1: Check Sticky Bit Enforcement
Confirm non-owners cannot delete files in shared_dir (as tested earlier).
Subtask 3.2: Verify setuid/setgid Execution
Ensure executables run with elevated permissions when setuid/setgid is applied.
Troubleshooting Tips
If setuid doesn’t work, check if the filesystem is mounted with nosuid (run mount | grep nosuid).
Use stat for detailed permission checks:
stat /usr/local/bin/show_euid
Conclusion
In this lab, you:

How to apply the sticky bit to secure shared directories.
Configured setuid and setgid to manage executable permissions.
Verified the security enhancements provided by these special permission bits.
These techniques are essential for secure system administration and are widely used in multi-user environments.

Next Steps:

Explore ACLs (Access Control Lists) for finer-grained permission control.
Practice securing system binaries with setuid (e.g., passwd).
Lab Complete! 🎉
