Lab 3: Using nano Text Editor
Objectives
By the end of this lab, students will be able to:

• Understand the basics of the nano text editor and its interface • Create and edit text files using nano • Navigate through text files efficiently using nano's keyboard shortcuts • Use nano's on-screen commands to save files and exit the editor • Perform text manipulation operations including cut, copy, and paste • Apply nano skills in real-world Linux administration scenarios • Prepare for Red Hat Certified Specialist in Ansible Network Automation exam requirements

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Familiarity with terminal navigation commands (cd, ls, pwd) • Knowledge of file and directory concepts in Linux • Access to a Linux terminal environment

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your cloud machine includes: • CentOS/RHEL or Ubuntu Linux distribution • Pre-installed nano text editor • Full terminal access with sudo privileges • All necessary tools for completing lab tasks

Task 1: Introduction to nano Text Editor
Subtask 1.1: Understanding nano Basics
nano is a simple, user-friendly text editor that runs in the terminal. Unlike more complex editors like vim or emacs, nano displays its most important commands at the bottom of the screen, making it ideal for beginners.

Key advantages of nano: • Intuitive interface with on-screen help • Easy to learn with minimal learning curve • Built-in command reference displayed at bottom • Cross-platform compatibility across Linux distributions

Subtask 1.2: Accessing nano Help
First, let's explore nano's built-in help system:

nano --help
This command displays nano's command-line options and basic usage information.

To see the version of nano installed:

nano --version
Task 2: Creating and Editing Files with nano
Subtask 2.1: Creating Your First File
Let's create a new file called welcome.txt:

nano welcome.txt
What happens: nano opens with a blank screen ready for text input. Notice the bottom of the screen shows available commands using the ^ symbol (which represents the Ctrl key).

Subtask 2.2: Understanding the nano Interface
When nano opens, you'll see:

• Title bar: Shows nano version and filename • Text area: Main editing space • Status line: Shows cursor position and file information • Command shortcuts: Bottom two lines showing available commands

Key interface elements: • ^X means Ctrl+X (Exit) • ^O means Ctrl+O (Write Out/Save) • ^R means Ctrl+R (Read File) • ^W means Ctrl+W (Where Is/Search)

Subtask 2.3: Adding Content to Your File
Type the following text into your welcome.txt file:

Welcome to Linux System Administration!

This is my first file created with nano text editor.

Key benefits of using nano:
- User-friendly interface
- Easy to learn
- Perfect for beginners
- Great for quick edits

Today's date: [Add current date here]
System administrator: [Add your name here]
Practice tip: As you type, notice how nano automatically wraps long lines and allows free-form text entry.

Subtask 2.4: Navigating Within the File
Practice these navigation commands while in nano:

• Arrow keys: Move cursor in any direction • Ctrl+A: Move to beginning of current line • Ctrl+E: Move to end of current line • Ctrl+Y: Move up one page • Ctrl+V: Move down one page • Ctrl+_: Go to specific line number (you'll be prompted)

Try moving to line 5:

Press Ctrl+_
Type 5 and press Enter
Your cursor moves to line 5
Task 3: Mastering Save and Exit Operations
Subtask 3.1: Saving Your File
To save your file without exiting:

Press Ctrl+O (Write Out)
nano will show the filename at the bottom
Press Enter to confirm the filename
You'll see "Wrote X lines" confirmation
Alternative method: You can also change the filename when saving by typing a new name before pressing Enter.

Subtask 3.2: Exiting nano
To exit nano:

Method 1 - Exit without saving changes:

Press Ctrl+X
If you have unsaved changes, nano asks "Save modified buffer?"
Press N for No to exit without saving
Method 2 - Save and exit:

Press Ctrl+X
Press Y when prompted to save
Press Enter to confirm filename
Method 3 - Save then exit:

Press Ctrl+O to save
Press Enter to confirm
Press Ctrl+X to exit
Subtask 3.3: Practice Save and Exit Workflow
Let's practice the complete workflow:

Create a new file:
nano practice.txt
Add this content:
This is a practice file for nano operations.
Line 2: Testing save functionality
Line 3: Testing exit procedures
Save the file using Ctrl+O, then Enter
Exit using Ctrl+X
Verify the file was created:
ls -la practice.txt
cat practice.txt
Task 4: Text Manipulation - Cut, Copy, and Paste
Subtask 4.1: Understanding nano's Text Selection
nano uses a marking system for text selection:

• Ctrl+6 (or Ctrl+Shift+6): Start/stop marking text • Alt+6: Copy marked text • Ctrl+K: Cut current line or marked text • Ctrl+U: Paste (uncut) text

Subtask 4.2: Cutting and Pasting Lines
Let's practice with a new file:

nano textmanip.txt
Add this content:

Line 1: This line will be moved
Line 2: This line stays here
Line 3: This line will be deleted
Line 4: This line will be copied
Line 5: Final line
Cutting a single line:

Position cursor on Line 3
Press Ctrl+K to cut the entire line
Move cursor to end of file
Press Ctrl+U to paste the line
Result: Line 3 moves to the end of the file.

Subtask 4.3: Copying Text Using Mark and Copy
Copying specific text:

Position cursor at the beginning of "Line 4"
Press Ctrl+6 to start marking (you'll see "Mark Set" message)
Use arrow keys to select "Line 4: This line will be copied"
Press Alt+6 to copy the marked text
Move cursor to desired location
Press Ctrl+U to paste
Subtask 4.4: Advanced Text Manipulation
Cutting multiple lines:

Position cursor at beginning of Line 1
Press Ctrl+6 to start marking
Move cursor to end of Line 2
Press Ctrl+K to cut marked text
Move to desired location and press Ctrl+U to paste
Copying without marking (entire lines):

Position cursor on any line
Press Ctrl+K to cut the line
Immediately press Ctrl+U to paste it back (creates a copy)
Move to new location and press Ctrl+U again
Task 5: Advanced nano Features
Subtask 5.1: Search and Replace Functionality
Searching for text:

Open your welcome.txt file:
nano welcome.txt
Press Ctrl+W to search
Type "administrator" and press Enter
nano highlights the first occurrence
Press Ctrl+W again and Enter to find next occurrence
Search and Replace:

Press Ctrl+\ (backslash) to open replace dialog
Enter search term: "administrator"
Press Enter
Enter replacement: "system admin"
Press Enter
Choose Y to replace each occurrence or A to replace all
Subtask 5.2: Working with Multiple Files
Opening additional files:

While in nano, press Ctrl+R to read/insert another file
Type filename: practice.txt
Press Enter to insert the file content at cursor position
Creating configuration files: Let's create a sample configuration file:

nano server.conf
Add this configuration content:

# Server Configuration File
# Created with nano text editor

[SERVER_SETTINGS]
hostname=webserver01
port=8080
max_connections=100
timeout=30

[DATABASE]
db_host=localhost
db_port=3306
db_name=webapp
db_user=admin

[LOGGING]
log_level=INFO
log_file=/var/log/server.log
rotate_logs=true
Save the file using Ctrl+O, then Enter.

Subtask 5.3: Using nano with System Files
Editing system configuration (demonstration purposes):

sudo nano /etc/hosts
Important: This opens the system hosts file. You can view it but be careful not to make changes unless you understand the implications.

Best practices when editing system files: • Always make backups first • Use sudo when required • Understand what you're changing • Test changes in non-production environments

Task 6: Practical Application Scenarios
Subtask 6.1: Creating Ansible Inventory File
Since this lab prepares for Red Hat Certified Specialist in Ansible Network Automation, let's create an Ansible inventory file:

nano inventory.ini
Add this content:

# Ansible Inventory File
# Network Automation Lab Environment

[webservers]
web01 ansible_host=192.168.1.10 ansible_user=admin
web02 ansible_host=192.168.1.11 ansible_user=admin
web03 ansible_host=192.168.1.12 ansible_user=admin

[databases]
db01 ansible_host=192.168.1.20 ansible_user=dbadmin
db02 ansible_host=192.168.1.21 ansible_user=dbadmin

[network_devices]
switch01 ansible_host=192.168.1.100 ansible_network_os=ios
router01 ansible_host=192.168.1.101 ansible_network_os=ios
firewall01 ansible_host=192.168.1.102 ansible_network_os=asa

[all:vars]
ansible_python_interpreter=/usr/bin/python3
Subtask 6.2: Creating a Simple Shell Script
Create a system monitoring script:

nano system_check.sh
Add this script content:

#!/bin/bash
# System Check Script
# Created with nano text editor

echo "=== System Health Check ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""

echo "=== Disk Usage ==="
df -h | head -5

echo ""
echo "=== Memory Usage ==="
free -h

echo ""
echo "=== CPU Load ==="
uptime

echo ""
echo "=== Network Interfaces ==="
ip addr show | grep -E "^[0-9]|inet "

echo "=== Check Complete ==="
Make the script executable:

chmod +x system_check.sh
Test the script:

./system_check.sh
Subtask 6.3: Creating Documentation Files
Create a README file for your lab work:

nano README.md
Add this markdown content:

# Lab 3: nano Text Editor Practice

## Overview
This repository contains files created during the nano text editor lab exercise.

## Files Created
- `welcome.txt` - Introduction file with nano basics
- `practice.txt` - Practice file for basic operations
- `textmanip.txt` - Text manipulation examples
- `server.conf` - Sample server configuration
- `inventory.ini` - Ansible inventory file
- `system_check.sh` - System monitoring script

## Skills Demonstrated
- File creation and editing with nano
- Text navigation and manipulation
- Cut, copy, and paste operations
- Search and replace functionality
- Configuration file editing
- Script creation

## Commands Learned
- `nano filename` - Open/create file
- `Ctrl+O` - Save file
- `Ctrl+X` - Exit nano
- `Ctrl+K` - Cut line/text
- `Ctrl+U` - Paste text
- `Ctrl+W` - Search
- `Ctrl+\` - Search and replace

## Next Steps
- Practice with more complex files
- Learn advanced nano features
- Apply skills to real system administration tasks
Troubleshooting Common Issues
Issue 1: nano Command Not Found
Problem: Terminal shows "command not found" when typing nano

Solution:

# Check if nano is installed
which nano

# Install nano if missing (Ubuntu/Debian)
sudo apt update && sudo apt install nano

# Install nano if missing (CentOS/RHEL)
sudo yum install nano
# or for newer versions
sudo dnf install nano
Issue 2: Cannot Save File (Permission Denied)
Problem: Getting permission errors when trying to save

Solution:

# Use sudo for system files
sudo nano /path/to/system/file

# Check file permissions
ls -la filename

# Change ownership if needed
sudo chown $USER:$USER filename
Issue 3: Accidentally Cut Important Text
Problem: Cut text by mistake and need to recover

Solution: • Press Ctrl+U immediately to paste back the cut text • nano keeps a buffer of cut text until you cut something else • Use Ctrl+Z to suspend nano and return later if needed

Issue 4: Lost in Large File
Problem: Cursor position unknown in large file

Solution: • Press Ctrl+C to see current line and column position • Press Ctrl+_ to go to specific line number • Use Ctrl+W to search for specific text

Conclusion
Congratulations! You have successfully completed Lab 3: Using nano Text Editor. In this comprehensive lab, you have accomplished the following:

Key Achievements
Technical Skills Mastered: • Created and edited multiple files using nano text editor • Learned essential navigation commands and keyboard shortcuts • Mastered save and exit procedures with various scenarios • Performed text manipulation operations including cut, copy, and paste • Implemented search and replace functionality • Created practical files relevant to system administration

Real-World Applications: • Built Ansible inventory files for network automation • Created system monitoring scripts • Developed configuration files for server management • Generated documentation using markdown format • Applied nano skills to actual Linux administration tasks

Professional Development: • Gained foundational skills required for Red Hat Certified Specialist in Ansible Network Automation exam • Developed confidence in Linux command-line text editing • Learned best practices for system file editing and backup procedures • Built practical experience with open-source tools used in enterprise environments

Why This Matters
The nano text editor is an essential tool for Linux system administrators and DevOps professionals. Unlike complex editors that require extensive training, nano provides immediate productivity while still offering powerful features. The skills you've learned in this lab directly apply to:

• System Configuration: Editing configuration files, scripts, and documentation • Automation Tasks: Creating and modifying Ansible playbooks and inventory files • Troubleshooting: Quickly editing log files and configuration during incident response • Development Work: Making quick changes to code and configuration files • Certification Preparation: Building foundational skills for advanced Linux certifications

Next Steps
To continue building your Linux administration skills:

Practice Daily: Use nano for all your text editing needs to build muscle memory
Explore Advanced Features: Learn about nano's syntax highlighting and customization options
Combine with Other Tools: Practice using nano with grep, sed, and awk for text processing
System Administration: Apply these skills to real system configuration tasks
Automation Focus: Use nano to create and edit Ansible playbooks for network automation
The foundation you've built with nano will serve you well as you progress toward advanced Linux certifications and real-world system administration challenges. Remember, mastery comes through consistent practice and application of these fundamental skills.
