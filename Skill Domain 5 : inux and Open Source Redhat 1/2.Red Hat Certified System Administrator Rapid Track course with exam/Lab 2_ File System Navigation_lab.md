Lab 2: File System Navigation
Objectives
By the end of this lab, students will be able to:

• Navigate the Linux file system using command-line tools • Use the cd, ls, and find commands effectively to explore directories • Create and organize directories and files using command-line interface • Understand and modify file permissions using ls -l and chmod commands • Apply fundamental file system concepts essential for Red Hat system administration

Prerequisites
Before starting this lab, students should have:

• Basic understanding of what a command line interface is • Familiarity with the concept of files and folders (directories) • No prior Linux experience required - this lab is designed for beginners • Access to a web browser to connect to the provided cloud environment

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click the Start Lab button to access your pre-configured environment. No need to build your own virtual machine or install any software locally.

Your cloud machine will include: • CentOS/RHEL-based Linux distribution • Full command-line access via web terminal • All necessary tools pre-installed

Task 1: Master Directory Navigation with cd, ls, and find
Subtask 1.1: Understanding Your Current Location
First, let's understand where you are in the file system and explore basic navigation.

Step 1: Open your terminal and check your current directory location

pwd
Expected Output: You should see something like /home/student or /root

Step 2: List the contents of your current directory

ls
Step 3: Get detailed information about files and directories

ls -l
Key Concept: The ls -l command shows detailed information including permissions, ownership, size, and modification dates.

Subtask 1.2: Basic Directory Navigation
Step 1: Navigate to the root directory

cd /
Step 2: List the contents to see the main system directories

ls
Step 3: Navigate to the home directory

cd /home
Step 4: List the contents of the home directory

ls -l
Step 5: Return to your user's home directory using the shortcut

cd ~
Step 6: Verify you're in your home directory

pwd
Subtask 1.3: Advanced Navigation Techniques
Step 1: Navigate to the parent directory

cd ..
Step 2: Check where you are now

pwd
Step 3: Go back to the previous directory

cd -
Step 4: Navigate using relative paths - go to a subdirectory (if it exists)

ls
cd Documents 2>/dev/null || echo "Documents directory doesn't exist yet"
Subtask 1.4: Using the find Command
Step 1: Return to your home directory

cd ~
Step 2: Find all files in your home directory

find . -type f
Step 3: Find all directories in your home directory

find . -type d
Step 4: Find files with specific names (case-insensitive)

find /etc -name "*.conf" -type f 2>/dev/null | head -10
Note: The 2>/dev/null redirects error messages, and head -10 shows only the first 10 results.

Task 2: Create Directories and Files
Subtask 2.1: Creating Directory Structure
Step 1: Navigate to your home directory

cd ~
Step 2: Create a single directory

mkdir lab2_practice
Step 3: Verify the directory was created

ls -l
Step 4: Create multiple directories at once

mkdir projects documents scripts
Step 5: Create nested directories in one command

mkdir -p lab2_practice/level1/level2/level3
Key Concept: The -p flag creates parent directories as needed and doesn't give an error if directories already exist.

Step 6: Verify the nested structure

ls -R lab2_practice
Subtask 2.2: Creating Files
Step 1: Navigate into your practice directory

cd lab2_practice
Step 2: Create an empty file using touch

touch readme.txt
Step 3: Create multiple files at once

touch file1.txt file2.txt file3.txt
Step 4: Create a file with content using echo

echo "This is my first Linux file" > welcome.txt
Step 5: Create a file with multiple lines using cat

cat > myinfo.txt << EOF
Name: Student
Course: Red Hat System Administration
Lab: File System Navigation
Date: $(date)
EOF
Step 6: Verify all files were created

ls -l
Subtask 2.3: Organizing Files into Directories
Step 1: Move files into the nested directory structure

mv file1.txt level1/
Step 2: Move multiple files

mv file2.txt file3.txt level1/level2/
Step 3: Copy files to different locations

cp welcome.txt level1/level2/level3/
Step 4: Verify the file organization

find . -type f
Task 3: Explore File Permissions with ls -l and chmod
Subtask 3.1: Understanding File Permissions
Step 1: Display detailed file information

ls -l
Expected Output Format:

-rw-rw-r-- 1 student student   29 Nov 15 10:30 welcome.txt
drwxrwxr-x 3 student student 4096 Nov 15 10:25 level1
Key Concept: Permission format breakdown:

First character: file type (- for file, d for directory)
Next 9 characters: permissions in groups of 3 (owner, group, others)
r = read (4), w = write (2), x = execute (1)
Subtask 3.2: Understanding Permission Numbers
Step 1: Create a test file to practice with

echo "Permission test file" > permissions_test.txt
Step 2: Check current permissions

ls -l permissions_test.txt
Step 3: Display permissions in numeric format

stat -c "%a %n" permissions_test.txt
Subtask 3.3: Modifying File Permissions
Step 1: Remove write permission for group and others

chmod 644 permissions_test.txt
Step 2: Verify the change

ls -l permissions_test.txt
Step 3: Make the file executable for the owner

chmod 744 permissions_test.txt
Step 4: Verify the change

ls -l permissions_test.txt
Step 5: Use symbolic notation to add execute permission for group

chmod g+x permissions_test.txt
Step 6: Remove read permission for others using symbolic notation

chmod o-r permissions_test.txt
Step 7: Check final permissions

ls -l permissions_test.txt
Subtask 3.4: Working with Directory Permissions
Step 1: Create a test directory

mkdir permission_test_dir
Step 2: Check directory permissions

ls -ld permission_test_dir
Step 3: Change directory permissions

chmod 755 permission_test_dir
Step 4: Create a file inside the directory

echo "Directory test" > permission_test_dir/test_file.txt
Step 5: Remove execute permission from the directory

chmod 644 permission_test_dir
Step 6: Try to access the directory (this should fail)

ls permission_test_dir
Step 7: Restore execute permission

chmod 755 permission_test_dir
Step 8: Verify access is restored

ls permission_test_dir
Subtask 3.5: Practical Permission Scenarios
Step 1: Create a script file

cat > myscript.sh << 'EOF'
#!/bin/bash
echo "Hello from my script!"
echo "Current directory: $(pwd)"
echo "Current user: $(whoami)"
EOF
Step 2: Check the script permissions

ls -l myscript.sh
Step 3: Try to execute the script (this should fail)

./myscript.sh
Step 4: Make the script executable

chmod +x myscript.sh
Step 5: Execute the script successfully

./myscript.sh
Step 6: Check the updated permissions

ls -l myscript.sh
Troubleshooting Tips
Common Issues and Solutions
Issue: "Permission denied" when trying to access a directory Solution: Check if the directory has execute permission using ls -ld directory_name and add it with chmod +x directory_name

Issue: "No such file or directory" error Solution: Use pwd to check your current location and ls to see available files and directories

Issue: Cannot create files or directories Solution: Ensure you have write permission in the current directory using ls -ld .

Issue: find command returns too many results Solution: Use head -n to limit results or add more specific search criteria

Verification Commands
Use these commands to verify your work:

# Check current location
pwd

# List all files and directories with details
ls -la

# Show directory tree structure
tree . 2>/dev/null || find . -type d

# Display file permissions in numeric format
stat -c "%a %n" filename
Lab Summary and Conclusion
Congratulations! You have successfully completed Lab 2: File System Navigation. In this lab, you have accomplished the following:

Key Skills Developed
• Navigation Mastery: You learned to navigate the Linux file system using cd, ls, and find commands effectively • File System Organization: You created directories and files, organizing them in a logical structure • Permission Management: You explored and modified file permissions using both numeric and symbolic notation • Command Proficiency: You gained hands-on experience with essential Linux commands that form the foundation of system administration

Why This Matters
These skills are fundamental for Red Hat Certified System Administrator certification and real-world Linux administration because:

• System Navigation: Efficient file system navigation is essential for managing Linux servers • Security: Understanding file permissions is crucial for maintaining system security • Automation: These commands form the building blocks for shell scripting and automation • Troubleshooting: File system knowledge is essential for diagnosing and resolving system issues

Next Steps
You are now prepared to: • Work confidently with Linux file systems • Manage file and directory permissions appropriately • Navigate complex directory structures efficiently • Apply these skills in more advanced system administration tasks

The foundation you've built in this lab will serve you well as you progress through the Red Hat Certified System Administrator curriculum and in your future career as a Linux system administrator.
