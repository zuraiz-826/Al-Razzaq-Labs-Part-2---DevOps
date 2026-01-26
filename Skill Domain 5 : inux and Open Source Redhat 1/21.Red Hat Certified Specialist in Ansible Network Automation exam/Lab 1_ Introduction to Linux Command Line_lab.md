Lab 1: Introduction to Linux Command Line
Objectives
By the end of this lab, students will be able to:

Navigate the Linux file system using basic shell commands
Understand the directory structure and current working directory concept
Create, copy, and remove files and directories using command-line tools
Practice essential file manipulation operations in Red Hat Enterprise Linux (RHEL)
Build foundational skills necessary for advanced system administration and automation tasks
Prerequisites
Before starting this lab, students should have:

Basic understanding of what an operating system is
Familiarity with the concept of files and folders
No prior Linux experience required - this lab is designed for beginners
Access to a computer with internet connection
Note: Al Nafi provides ready-to-use Linux-based cloud machines. Simply click Start Lab to access your RHEL environment - no need to build your own virtual machine or install any software locally.

Lab Environment Setup
Ready-to-Use Cloud Machines
Al Nafi has prepared Linux-based cloud machines specifically for this lab. When you click Start Lab, you will receive:

A fully configured Red Hat Enterprise Linux (RHEL) system
Terminal access with appropriate user permissions
All necessary tools pre-installed
Isolated environment for safe practice
Simply click the Start Lab button and wait for your environment to initialize (typically 2-3 minutes).

Task 1: Understanding Your Environment and Basic Navigation
Subtask 1.1: Accessing the Terminal
Once your cloud machine is ready, locate the terminal application
Click on the terminal icon or press Ctrl + Alt + T to open the command line interface
You should see a prompt similar to:
[user@hostname ~]$
This prompt indicates:

user: Your username
hostname: The name of your machine
~: You are in your home directory
$: You have regular user privileges
Subtask 1.2: Learning the pwd Command
The pwd command stands for "Print Working Directory" and shows you exactly where you are in the file system.

Type the following command and press Enter:
pwd
You should see output similar to:
/home/user
This tells you that you are currently in the /home/user directory, which is your personal home folder.

Key Concept: Think of the file system like a tree structure. The / at the beginning represents the root of the tree, and each / separates different levels of directories.

Subtask 1.3: Exploring with the ls Command
The ls command lists the contents of directories. It's like looking inside a folder to see what files and folders it contains.

List the contents of your current directory:
ls
Get more detailed information using the -l option (long format):
ls -l
Show hidden files (files that start with a dot) using the -a option:
ls -a
Combine options for detailed listing including hidden files:
ls -la
Understanding the Output: The -l option shows:

File permissions
Number of links
Owner name
Group name
File size
Last modification date
File/directory name
Subtask 1.4: Navigating with the cd Command
The cd command stands for "Change Directory" and allows you to move around the file system.

First, let's see what directories are available to explore:
ls /
This shows the root directory contents.

Navigate to the root directory:
cd /
Confirm your location:
pwd
List the contents to see system directories:
ls
Navigate to the /tmp directory (a temporary storage area):
cd /tmp
Verify your location:
pwd
Return to your home directory using the tilde shortcut:
cd ~
Confirm you're back home:
pwd
Navigation Shortcuts:

cd ~ or just cd: Go to home directory
cd ..: Go up one directory level
cd -: Go back to the previous directory
Task 2: File Manipulation Basics
Subtask 2.1: Creating Files with touch
The touch command creates empty files or updates the timestamp of existing files.

Create your first file:
touch myfile.txt
Verify the file was created:
ls -l
Create multiple files at once:
touch file1.txt file2.txt file3.txt
List files to confirm creation:
ls
Create a file with a more descriptive name:
touch "my important document.txt"
Note: When file names contain spaces, use quotes to treat the entire name as one unit.

Subtask 2.2: Copying Files with cp
The cp command copies files and directories from one location to another.

Copy a single file:
cp myfile.txt myfile_backup.txt
Verify the copy was created:
ls -l
Copy a file to a different name:
cp file1.txt important_file.txt
Create a directory to practice copying into:
mkdir practice_folder
Copy a file into the directory:
cp myfile.txt practice_folder/
Verify the file was copied into the directory:
ls practice_folder/
Copy multiple files at once:
cp file1.txt file2.txt file3.txt practice_folder/
Subtask 2.3: Removing Files with rm
The rm command removes (deletes) files and directories. Be careful - deleted files cannot be easily recovered.

First, let's see what files we have:
ls
Remove a single file:
rm file2.txt
Verify the file is gone:
ls
Try to remove a file that doesn't exist to see the error message:
rm nonexistent.txt
Remove multiple files at once:
rm file1.txt file3.txt
Remove files from within a directory:
rm practice_folder/file1.txt
Safety Tips:

Always double-check file names before using rm
Use ls to verify what you're about to delete
The -i option asks for confirmation: rm -i filename.txt
Task 3: Advanced File System Navigation
Subtask 3.1: Creating a Directory Structure
Let's create a more complex directory structure to practice navigation.

Create a main project directory:
mkdir my_project
Navigate into the project directory:
cd my_project
Create subdirectories:
mkdir documents images scripts
Verify the structure:
ls -l
Create files in different directories:
touch documents/readme.txt
touch documents/notes.txt
touch images/photo1.jpg
touch scripts/backup.sh
Subtask 3.2: Complex Navigation Practice
Navigate to the documents folder:
cd documents
List the files:
ls
Go back to the parent directory:
cd ..
Navigate to images directory:
cd images
Go back to your home directory:
cd ~
Navigate directly to the scripts folder using the full path:
cd my_project/scripts
Show your current location:
pwd
Subtask 3.3: Advanced File Operations
From the scripts directory, copy a file to the documents directory:
cp backup.sh ../documents/
Navigate to documents to verify:
cd ../documents
ls
Copy the readme.txt file to your home directory:
cp readme.txt ~/readme_copy.txt
Navigate home and verify:
cd ~
ls
Remove the copy:
rm readme_copy.txt
Task 4: Practical File Management Scenarios
Subtask 4.1: Organizing Files by Type
Let's practice a real-world scenario of organizing files.

Create a downloads directory:
mkdir downloads
cd downloads
Create sample files of different types:
touch document1.pdf document2.pdf
touch image1.jpg image2.png image3.gif
touch song1.mp3 song2.wav
touch program1.exe program2.deb
Create directories for organization:
mkdir documents images audio software
Move files to appropriate directories:
cp *.pdf documents/
cp *.jpg *.png *.gif images/
cp *.mp3 *.wav audio/
cp *.exe *.deb software/
Verify the organization:
ls documents/
ls images/
ls audio/
ls software/
Subtask 4.2: Cleaning Up
Remove the original files (since we copied them):
rm *.pdf *.jpg *.png *.gif *.mp3 *.wav *.exe *.deb
Verify only directories remain:
ls
Navigate back to home:
cd ~
Troubleshooting Common Issues
Issue 1: Permission Denied
If you see "Permission denied" errors:

ls -l filename
Check the file permissions. You may need to use different commands or contact your administrator.

Issue 2: File Not Found
If you get "No such file or directory":

Check your current location:
pwd
List available files:
ls
Verify the correct file name and path
Issue 3: Command Not Found
If you get "command not found":

Check your spelling
Ensure you're using the correct command syntax
Try using the full path: /bin/ls instead of just ls
Lab Summary and Verification
Verification Checklist
Before completing this lab, ensure you can:

 Use pwd to show your current directory
 Use ls to list directory contents with various options
 Use cd to navigate between directories
 Use touch to create new files
 Use cp to copy files and directories
 Use rm to safely remove files
 Navigate complex directory structures
 Understand basic file permissions output
Final Verification Commands
Run these commands to demonstrate your skills:

# Show current location
pwd

# Create a test directory
mkdir lab_completion_test

# Navigate to it
cd lab_completion_test

# Create test files
touch test1.txt test2.txt

# Copy a file
cp test1.txt test1_backup.txt

# List all files
ls -la

# Navigate back home
cd ~

# Clean up
rm -rf lab_completion_test
Conclusion
Congratulations! You have successfully completed Lab 1: Introduction to Linux Command Line. In this lab, you have:

Accomplished Skills:

Mastered basic Linux navigation using cd, pwd, and ls commands
Learned to create files using the touch command
Practiced file manipulation with cp and rm commands
Navigated complex directory structures confidently
Developed foundational command-line skills essential for system administration
Why This Matters: These fundamental skills form the foundation for advanced Linux system administration and automation tasks. As you progress toward certifications like the Red Hat Certified Specialist in Ansible Network Automation, these basic commands will be used constantly for:

Managing configuration files
Navigating system directories
Creating and organizing automation scripts
Troubleshooting system issues
Preparing environments for automation tools
Next Steps: With these basic navigation and file manipulation skills, you're ready to explore more advanced topics such as:

File permissions and ownership
Text editing with vi/vim
Process management
System monitoring
Automation scripting
The command-line proficiency you've gained today will serve as the foundation for all future Linux administration and automation tasks. Keep practicing these commands regularly to build muscle memory and confidence in the Linux environment.
