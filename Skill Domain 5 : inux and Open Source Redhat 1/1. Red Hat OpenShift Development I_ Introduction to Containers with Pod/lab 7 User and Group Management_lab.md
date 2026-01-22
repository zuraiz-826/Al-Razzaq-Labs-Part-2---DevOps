Lab 7: User and Group Management in Linux
Objectives
By the end of this lab, you will be able to:

Create and manage local users and groups in Linux.
Modify user attributes such as home directory and default shell.
Assign users to groups and remove them when needed.
Prerequisites
A Linux system (e.g., CentOS, Fedora, or Ubuntu) with root/sudo access.
Basic familiarity with the Linux command line.
Task 1: Create New Users and Groups
Subtask 1.1: Create a New User
Open a terminal and run the following command to create a new user named labuser1:

sudo useradd labuser1
Explanation: useradd creates a new user without a home directory by default.
Expected Outcome: The user labuser1 is created but has no home directory.
To create a user with a home directory, use:

sudo useradd -m labuser2
Explanation: The -m flag ensures a home directory is created (/home/labuser2).
Verify the user creation:

id labuser1
id labuser2
Expected Outcome: Output shows user IDs (UID) and group IDs (GID).
Subtask 1.2: Create a New Group
Create a group named developers:
sudo groupadd developers
Verify the group:
grep developers /etc/group
Expected Outcome: Output shows the developers group entry.
Task 2: Modify User Information
Subtask 2.1: Change User's Home Directory
Modify labuser1 to set a new home directory (/home/labuser1_new):

sudo usermod -d /home/labuser1_new -m labuser1
Explanation: -d specifies the new directory, and -m moves contents from the old home directory.
Verify the change:

ls /home
Expected Outcome: The directory /home/labuser1_new appears.
Subtask 2.2: Change User's Default Shell
Set the default shell for labuser1 to /bin/bash:
sudo usermod -s /bin/bash labuser1
Verify:
grep labuser1 /etc/passwd
Expected Outcome: The shell field shows /bin/bash.
Task 3: Assign Users to Groups and Delete Them
Subtask 3.1: Add Users to a Group
Add labuser1 and labuser2 to the developers group:

sudo usermod -aG developers labuser1
sudo usermod -aG developers labuser2
Explanation: -aG appends the user to the group without removing existing group memberships.
Verify group membership:

groups labuser1
Expected Outcome: Output includes developers.
Subtask 3.2: Remove Users from a Group
Remove labuser1 from the developers group:
sudo gpasswd -d labuser1 developers
Verify:
groups labuser1
Expected Outcome: developers is no longer listed.
Subtask 3.3: Delete Users and Groups
Delete labuser1 and its home directory:

sudo userdel -r labuser1
Explanation: -r removes the home directory and mail spool.
Delete the developers group:

sudo groupdel developers
Verify deletion:

grep developers /etc/group
Expected Outcome: No output (group is deleted).
Troubleshooting Tips
If a user/group deletion fails, ensure no processes are running under that user:
sudo pkill -u labuser1
For permission issues, use sudo or switch to the root user.
Conclusion
In this lab, you learned to:

Create and manage users/groups in Linux.
Modify user attributes like home directory and shell.
Assign/remove users from groups and clean up resources.
These skills are foundational for system administration and align with Red Hat OpenShift Development I certification objectives.
