Lab 1: Introduction to the Bash Shell
Objectives
By the end of this lab, students will be able to:

• Access and navigate the Linux command line interface using Bash • Execute fundamental Bash commands for file and directory operations • Understand and implement input/output redirection and piping techniques • Create, modify, and execute basic shell scripts • Apply command-line skills essential for Red Hat system administration • Demonstrate proficiency with core Linux commands required for RHCSA certification

Prerequisites
Before starting this lab, students should have:

• Basic understanding of computer file systems and directory structures • Familiarity with text editing concepts • No prior Linux or command-line experience required • Access to a web browser for the cloud-based lab environment

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click the Start Lab button to access your dedicated environment. No need to build or configure your own virtual machine - everything is ready to use immediately.

Your cloud machine includes: • CentOS/RHEL-based Linux distribution • Bash shell (version 4.2 or higher) • Standard Linux utilities and text editors • Full root access for administrative tasks

Task 1: Access the Command Line Interface
Subtask 1.1: Connect to Your Lab Environment
Click the Start Lab button in your Al Nafi dashboard
Wait for the lab environment to initialize (typically 30-60 seconds)
Once ready, you will see a terminal window or desktop environment
If you see a desktop, locate and open the Terminal application
Subtask 1.2: Verify Your Shell Environment
Check which shell you are using:
echo $SHELL
Verify the Bash version:
bash --version
Display your current username:
whoami
Show the current date and time:
date
Expected Output Example:

[student@lab-machine ~]$ echo $SHELL
/bin/bash
[student@lab-machine ~]$ whoami
student
Task 2: Use Basic Bash Commands
Subtask 2.1: Navigate the File System
Display your current working directory:
pwd
List the contents of your current directory:
ls
List detailed information about files and directories:
ls -l
List all files including hidden ones:
ls -la
Navigate to the root directory:
cd /
List the contents of the root directory:
ls
Return to your home directory:
cd ~
Subtask 2.2: Create and Manage Directories
Create a new directory called lab1-practice:
mkdir lab1-practice
Navigate into the new directory:
cd lab1-practice
Create multiple directories at once:
mkdir scripts documents backups
Create a nested directory structure:
mkdir -p projects/web/html projects/web/css
List the directory structure you created:
ls -R
Subtask 2.3: Create and Manage Files
Create an empty file using the touch command:
touch readme.txt
Create a file with content using echo:
echo "Welcome to Bash Shell Lab" > welcome.txt
Display the contents of the file:
cat welcome.txt
Create a file with multiple lines:
cat > system-info.txt << EOF
System Information Lab File
Created on: $(date)
User: $(whoami)
Directory: $(pwd)
EOF
View the file contents:
cat system-info.txt
Subtask 2.4: Copy, Move, and Remove Files
Copy a file to a new location:
cp welcome.txt documents/
Copy a file with a new name:
cp welcome.txt welcome-backup.txt
Move a file to a different directory:
mv readme.txt documents/
Rename a file:
mv welcome-backup.txt welcome-copy.txt
Remove a file:
rm welcome-copy.txt
Verify the changes:
ls
ls documents/
Task 3: Practice Using Redirection and Piping
Subtask 3.1: Output Redirection
Redirect command output to a file:
ls -la > file-listing.txt
View the redirected output:
cat file-listing.txt
Append output to an existing file:
date >> file-listing.txt
echo "--- End of listing ---" >> file-listing.txt
View the updated file:
cat file-listing.txt
Subtask 3.2: Input Redirection
Create a file with sample data:
cat > numbers.txt << EOF
10
25
5
30
15
EOF
Sort the numbers using input redirection:
sort < numbers.txt
Sort and save to a new file:
sort < numbers.txt > sorted-numbers.txt
Subtask 3.3: Using Pipes
List files and count them:
ls | wc -l
Display system processes and search for specific ones:
ps aux | grep bash
Show disk usage and sort by size:
du -h | sort -hr
Display file contents and search for specific text:
cat /etc/passwd | grep root
Chain multiple commands with pipes:
ls -la | grep "^d" | wc -l
Subtask 3.4: Advanced Redirection Examples
Redirect both standard output and error:
ls /nonexistent-directory > output.txt 2> error.txt
Redirect both to the same file:
ls /nonexistent-directory > combined.txt 2>&1
Use tee to display and save output simultaneously:
ls -la | tee directory-listing.txt
Task 4: Create and Execute Simple Scripts
Subtask 4.1: Create Your First Shell Script
Navigate to the scripts directory:
cd ~/lab1-practice/scripts
Create a simple script file:
cat > hello-world.sh << 'EOF'
#!/bin/bash
# My first shell script
echo "Hello, World!"
echo "Welcome to Bash scripting!"
echo "Today is: $(date)"
echo "Current user: $(whoami)"
EOF
Make the script executable:
chmod +x hello-world.sh
Execute the script:
./hello-world.sh
Subtask 4.2: Create a System Information Script
Create a more advanced script:
cat > system-report.sh << 'EOF'
#!/bin/bash
# System Information Report Script

echo "=================================="
echo "    SYSTEM INFORMATION REPORT"
echo "=================================="
echo
echo "Date and Time: $(date)"
echo "Hostname: $(hostname)"
echo "Current User: $(whoami)"
echo "Current Directory: $(pwd)"
echo
echo "System Uptime:"
uptime
echo
echo "Disk Usage:"
df -h | head -5
echo
echo "Memory Usage:"
free -h
echo
echo "Number of files in current directory: $(ls | wc -l)"
echo "=================================="
EOF
Make the script executable:
chmod +x system-report.sh
Run the script:
./system-report.sh
Subtask 4.3: Create an Interactive Script
Create a script that accepts user input:
cat > user-info.sh << 'EOF'
#!/bin/bash
# Interactive User Information Script

echo "Welcome to the User Information Collector!"
echo

# Get user input
read -p "Enter your name: " username
read -p "Enter your favorite color: " color
read -p "Enter your age: " age

echo
echo "=================================="
echo "User Information Summary"
echo "=================================="
echo "Name: $username"
echo "Favorite Color: $color"
echo "Age: $age"
echo "Script run on: $(date)"
echo "=================================="

# Create a personalized file
echo "Creating a personalized file for $username..."
cat > "${username}-info.txt" << EOF
Personal Information File
Name: $username
Favorite Color: $color
Age: $age
File created: $(date)
EOF

echo "File ${username}-info.txt has been created!"
EOF
Make the script executable:
chmod +x user-info.sh
Run the interactive script:
./user-info.sh
Follow the prompts and enter sample information
Subtask 4.4: Create a File Management Script
Create a script for file operations:
cat > file-manager.sh << 'EOF'
#!/bin/bash
# Simple File Management Script

echo "File Management Utility"
echo "======================"

# Create backup directory
backup_dir="backup-$(date +%Y%m%d)"
mkdir -p "$backup_dir"

# List current files
echo "Current files in directory:"
ls -la

echo
echo "Creating backup of .txt files..."

# Backup all .txt files
for file in *.txt; do
    if [ -f "$file" ]; then
        cp "$file" "$backup_dir/"
        echo "Backed up: $file"
    fi
done

echo
echo "Backup completed in directory: $backup_dir"
echo "Contents of backup directory:"
ls -la "$backup_dir"
EOF
Make the script executable:
chmod +x file-manager.sh
Run the file management script:
./file-manager.sh
Troubleshooting Tips
Common Issues and Solutions
Issue: Permission denied when executing scripts Solution: Ensure the script has execute permissions using chmod +x scriptname.sh

Issue: Command not found Solution:

Check if you're in the correct directory
Use ./scriptname.sh to execute scripts in the current directory
Verify the script path is correct
Issue: Syntax errors in scripts Solution:

Check for missing quotes or brackets
Ensure proper spacing around operators
Use bash -x scriptname.sh for debugging
Issue: File or directory not found Solution:

Use pwd to check your current location
Use ls to verify file existence
Check file/directory names for typos
Verification and Testing
Verify Your Lab Completion
Check that all directories were created:
cd ~/lab1-practice
find . -type d
Verify all scripts are executable:
ls -la scripts/
Test each script works properly:
cd scripts
./hello-world.sh
./system-report.sh
Confirm redirection examples created files:
ls -la *.txt
Conclusion
Congratulations! You have successfully completed Lab 1: Introduction to the Bash Shell. In this lab, you have accomplished the following:

Key Skills Developed: • Command Line Navigation: You learned to navigate the Linux file system using essential commands like pwd, ls, and cd • File Management: You practiced creating, copying, moving, and removing files and directories • Input/Output Redirection: You mastered redirecting command output to files and using pipes to chain commands • Shell Scripting: You created and executed multiple shell scripts, from simple hello-world programs to interactive utilities

Why This Matters: These fundamental Bash skills form the foundation for Linux system administration and are essential for the Red Hat Certified System Administrator (RHCSA) certification. The command-line proficiency you've gained will enable you to:

• Efficiently manage Linux systems in enterprise environments • Automate routine administrative tasks through scripting • Troubleshoot system issues using command-line tools • Prepare for advanced Red Hat certification tracks

Next Steps: You are now ready to advance to more complex Linux administration topics, including user management, file permissions, process control, and system services. The skills practiced in this lab will be used throughout your Red Hat certification journey.

Keep practicing these commands and scripts in your daily work to build muscle memory and confidence with the Bash shell environment.
