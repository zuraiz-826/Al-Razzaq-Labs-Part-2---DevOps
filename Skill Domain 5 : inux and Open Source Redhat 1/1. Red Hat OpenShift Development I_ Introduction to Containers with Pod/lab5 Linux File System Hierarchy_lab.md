Lab 5: Linux File System Hierarchy
Objectives
Understand the standard Linux file system hierarchy and its key directories
Learn to navigate the Linux file system using command-line tools
Explore important system directories and their purposes
Understand symbolic links and their role in the file system structure
Prerequisites
A Linux system (physical or virtual machine)
Basic familiarity with Linux command line
Terminal access with standard user privileges (some commands may require sudo)
Lab Setup
No additional software installation is required as we'll be using built-in Linux commands.

Task 1: Exploring Key Directories
Subtask 1.1: Understanding the Root Directory
Open your terminal
Run the following command to list the root directory contents:
ls /
Expected Output: You should see directories like bin, etc, home, usr, var, tmp, and others.

Explanation: The / directory is the root of the file system hierarchy where all other directories are mounted.

Subtask 1.2: Exploring /bin and /sbin
List contents of /bin:
ls /bin
List contents of /sbin:
ls /sbin
Key Concept:

/bin contains essential user command binaries (like ls, cp, mv)
/sbin contains system binaries (like ifconfig, fdisk) typically used by administrators
Subtask 1.3: Examining /etc Directory
View contents of /etc:
ls /etc
Examine a configuration file (use less to view safely):
less /etc/passwd
Explanation: /etc contains system configuration files. Press q to exit the less viewer.

Subtask 1.4: Working with /home
Navigate to your home directory:
cd ~
Verify your location:
pwd
Create a test file:
touch testfile.txt
Key Concept: /home contains user directories where users store personal files and configurations.

Subtask 1.5: Exploring /usr
List contents of /usr:
ls /usr
Check what's in /usr/bin:
ls /usr/bin | wc -l
Explanation: /usr contains user utilities and applications. The wc -l counts how many files are present.

Subtask 1.6: Understanding /var
Examine /var contents:
ls /var
Check log files (may require sudo):
sudo ls /var/log
Key Concept: /var contains variable data like logs, databases, and temporary files that change during system operation.

Subtask 1.7: Working with /tmp
Navigate to /tmp:
cd /tmp
Create a temporary file:
touch tempfile
Explanation: /tmp is for temporary files that may be deleted between reboots.

Task 2: File System Navigation
Subtask 2.1: Basic Navigation Commands
Print working directory:
pwd
List directory contents with details:
ls -l
Change to parent directory:
cd ..
Return to home directory:
cd
Subtask 2.2: Finding Files
Find all .conf files in /etc:
find /etc -name "*.conf"
Search for a specific file:
locate passwd
(If locate isn't available, run sudo updatedb first)

Task 3: Understanding Symbolic Links
Subtask 3.1: Identifying Symbolic Links
Find symbolic links in /bin:
ls -l /bin | grep '^l'
Explanation: The ^l in grep shows only lines starting with 'l' which indicates symbolic links.

Subtask 3.2: Creating Symbolic Links
Create a test file:
touch original.txt
Create a symbolic link:
ln -s original.txt link_to_original
Verify the link:
ls -l link_to_original
Expected Output: You should see link_to_original -> original.txt

Subtask 3.3: Understanding Hard Links
Create a hard link:
ln original.txt hardlink_to_original
Compare inodes (unique file identifiers):
ls -i original.txt hardlink_to_original
Key Concept: Hard links share the same inode number while symbolic links have different inodes.

Troubleshooting Tips
If you get "Permission denied" errors, try prefixing commands with sudo
For "command not found" errors, verify the command exists in /bin, /usr/bin, or /sbin
Use man <command> to read manual pages for any command you don't understand
The tree command (install with sudo apt install tree or sudo yum install tree) can help visualize directory structures
Conclusion
In this lab, you:

Explored the standard Linux file system hierarchy and its key directories
Practiced navigating the file system using essential commands
Learned about symbolic and hard links and their differences
Gained hands-on experience with important system directories
Understanding the Linux file system hierarchy is fundamental for system administration, development, and troubleshooting in Linux environments. The knowledge gained in this lab forms the foundation for more advanced Linux operations and container management in Red Hat OpenShift environments.

Next Steps
Explore additional directories like /proc and /sys which contain system and process information
Learn about filesystem permissions with chmod and chown
Practice more advanced file operations like grep, awk, and sed for file processing
