Lab 2: Using vi/vim Text Editor
Objectives
By the end of this lab, students will be able to:

Navigate and operate the vi/vim text editor efficiently in a Linux environment
Switch between different vi/vim modes (command, insert, and visual)
Create, edit, save, and close files using vi/vim commands
Perform basic text manipulation operations including copying, cutting, and pasting
Search and replace text within files using vi/vim functionality
Configure basic vi/vim settings for improved productivity
Apply vi/vim skills in real-world system administration scenarios
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line interface
Familiarity with file system navigation using commands like cd, ls, and pwd
Access to a terminal or command prompt
Basic knowledge of file permissions and ownership concepts
Understanding of text file formats and line endings
Lab Environment Setup
Al Nafi Cloud Machine Access: This lab uses Al Nafi's pre-configured Linux-based cloud machines. Simply click Start Lab to access your dedicated environment. No virtual machine setup or installation is required.

Your cloud machine includes:

CentOS/RHEL or Ubuntu Linux distribution
Pre-installed vi/vim editor
Sample files for practice
Full root access for configuration changes
Task 1: Getting Started with vi/vim
Subtask 1.1: Understanding vi/vim Basics
First, let's understand what vi/vim is and verify it's available on your system.

Step 1: Check if vi/vim is installed

which vi
which vim
Step 2: Check the version of vim

vim --version
Step 3: Create a practice directory

mkdir ~/vim_practice
cd ~/vim_practice
Subtask 1.2: Opening Files with vi/vim
Step 1: Create and open a new file

vim practice1.txt
Step 2: If vim is not available, use vi

vi practice1.txt
Note: When you first open vim, you'll be in command mode. This is the default mode where you can navigate and execute commands.

Subtask 1.3: Understanding the Interface
When vim opens, you'll see:

A blank screen with tildes (~) indicating empty lines
The filename at the bottom
Cursor positioned at the top-left corner
Task 2: Mastering vi/vim Modes
Subtask 2.1: Command Mode Operations
Command mode is the default mode for navigation and file operations.

Step 1: Practice basic navigation (ensure you're in command mode)

h - move left
j - move down  
k - move up
l - move right
Step 2: Advanced navigation commands

w - move to beginning of next word
b - move to beginning of previous word
0 - move to beginning of line
$ - move to end of line
gg - go to first line
G - go to last line
Step 3: Practice with a sample file

echo "This is line 1
This is line 2
This is line 3
Welcome to vim practice
Learning vim is essential for Linux" > sample.txt
vim sample.txt
Subtask 2.2: Insert Mode Operations
Insert mode allows you to add and modify text.

Step 1: Enter insert mode from command mode

i - insert before cursor
a - insert after cursor
o - open new line below cursor
O - open new line above cursor
Step 2: Practice inserting text

Press i to enter insert mode
Type: "Hello, this is my first vim edit!"
Press Esc to return to command mode
Step 3: Practice different insert methods

Move cursor to end of line using $
Press a to append text
Add: " - Added text at end"
Press Esc to return to command mode
Subtask 2.3: Visual Mode Operations
Visual mode allows you to select text for operations.

Step 1: Enter visual mode

v - character-wise visual mode
V - line-wise visual mode
Ctrl+v - block-wise visual mode
Step 2: Practice text selection

Position cursor at beginning of a word
Press v to enter visual mode
Use arrow keys or w to select text
Press Esc to exit visual mode
Step 3: Copy and paste operations

Select text using visual mode
Press y to copy (yank)
Move cursor to desired location
Press p to paste after cursor or P to paste before cursor
Task 3: File Operations and Saving
Subtask 3.1: Saving Files
Step 1: Save without exiting

:w - save file
:w filename - save as new filename
Step 2: Practice saving

Make some changes to your file
Press Esc to ensure you're in command mode
Type :w and press Enter
Subtask 3.2: Exiting vi/vim
Step 1: Different exit methods

:q - quit (only if no changes)
:q! - quit without saving changes
:wq - save and quit
:x - save and quit (same as :wq)
ZZ - save and quit (command mode shortcut)
Step 2: Practice safe exiting

Make changes to your file
Try :q (should show warning)
Use :wq to save and exit
Subtask 3.3: Advanced File Operations
Step 1: Working with multiple files

vim file1.txt file2.txt file3.txt
Step 2: Navigate between files

:n - next file
:prev - previous file
:ls - list open files
:e filename - edit new file
Task 4: Advanced Editing Techniques
Subtask 4.1: Search and Replace
Step 1: Create a practice file with repeated content

cat > search_practice.txt << EOF
The quick brown fox jumps over the lazy dog.
The fox is quick and brown.
A lazy dog sleeps under the tree.
The brown fox runs quickly.
EOF
vim search_practice.txt
Step 2: Search operations

/pattern - search forward
?pattern - search backward
n - next occurrence
N - previous occurrence
Step 3: Replace operations

:s/old/new/ - replace first occurrence in current line
:s/old/new/g - replace all occurrences in current line
:%s/old/new/g - replace all occurrences in file
:%s/old/new/gc - replace with confirmation
Step 4: Practice search and replace

Search for "fox": /fox
Replace all "fox" with "cat": :%s/fox/cat/g
Verify changes by navigating through the file
Subtask 4.2: Copy, Cut, and Paste Operations
Step 1: Copying (yanking) text

yy - copy current line
y$ - copy from cursor to end of line
yw - copy word
y5w - copy 5 words
Step 2: Cutting (deleting) text

dd - cut current line
d$ - cut from cursor to end of line
dw - cut word
x - cut character under cursor
Step 3: Pasting text

p - paste after cursor/line
P - paste before cursor/line
Step 4: Practice copy/cut/paste

Copy a line using yy
Move to another location
Paste using p
Cut a word using dw
Paste it elsewhere using p
Subtask 4.3: Undo and Redo Operations
Step 1: Undo operations

u - undo last change
U - undo all changes to current line
Ctrl+r - redo
Step 2: Practice undo/redo

Make several changes to your file
Use u to undo changes one by one
Use Ctrl+r to redo changes
Task 5: Configuration and Customization
Subtask 5.1: Basic vim Configuration
Step 1: Create a vim configuration file

vim ~/.vimrc
Step 2: Add basic configuration settings

" Enable line numbers
set number

" Enable syntax highlighting
syntax on

" Set tab width
set tabstop=4
set shiftwidth=4
set expandtab

" Enable search highlighting
set hlsearch

" Enable incremental search
set incsearch

" Show matching brackets
set showmatch

" Enable auto-indentation
set autoindent
Step 3: Save and test configuration

Save the .vimrc file using :wq
Open a new file with vim to see the changes
Verify line numbers and syntax highlighting work
Subtask 5.2: Useful vim Commands for System Administration
Step 1: Create a system configuration file

sudo vim /tmp/system_config.conf
Step 2: Practice with system-like content

# Add this content to practice with
[database]
host=localhost
port=3306
username=admin
password=secret123

[web_server]
port=80
ssl_port=443
document_root=/var/www/html

[logging]
level=info
file=/var/log/application.log
Step 3: Practice administrative tasks

Comment out lines using visual mode and I#
Duplicate configuration sections using yy and p
Search and replace configuration values
Use :set number to show line numbers for debugging
Task 6: Real-World Scenarios
Subtask 6.1: Editing System Files
Step 1: Practice with a hosts file

sudo cp /etc/hosts /tmp/hosts_backup
sudo vim /tmp/hosts_backup
Step 2: Add entries to the hosts file

# Add these lines
192.168.1.100   webserver.local
192.168.1.101   database.local
192.168.1.102   cache.local
Step 3: Practice system administration tasks

Comment out entries by adding # at the beginning
Copy and modify existing entries
Search for specific IP addresses or hostnames
Subtask 6.2: Log File Analysis
Step 1: Create a sample log file

cat > /tmp/sample.log << EOF
2024-01-15 10:30:15 INFO Application started
2024-01-15 10:30:16 DEBUG Loading configuration
2024-01-15 10:30:17 INFO Database connection established
2024-01-15 10:31:22 ERROR Failed to connect to external API
2024-01-15 10:31:23 WARN Retrying connection in 5 seconds
2024-01-15 10:31:28 INFO Connection restored
2024-01-15 10:32:45 ERROR Database timeout
2024-01-15 10:32:46 INFO Reconnecting to database
EOF
vim /tmp/sample.log
Step 2: Practice log analysis techniques

Search for all ERROR entries: /ERROR
Count occurrences: :%s/ERROR//gn
Navigate between errors using n and N
Extract error lines to a new file
Troubleshooting Common Issues
Issue 1: Stuck in Insert Mode
Problem: Cannot execute commands, everything typed appears as text Solution: Press Esc key to return to command mode

Issue 2: Cannot Save File
Problem: Getting "Permission denied" error Solution:

Check file permissions: :!ls -l %
Save to a different location: :w /tmp/filename
Use sudo: :w !sudo tee %
Issue 3: Accidentally Modified Important File
Problem: Made unwanted changes to system file Solution:

Exit without saving: :q!
Restore from backup if available
Use undo commands: u multiple times
Issue 4: Lost in Large File
Problem: Cannot find current position in large file Solution:

Show line numbers: :set number
Go to specific line: :line_number
Show current position: Ctrl+g
Issue 5: Search Not Working
Problem: Search command not finding text Solution:

Check case sensitivity: :set ignorecase
Use exact case: :set noignorecase
Clear search highlighting: :noh
Performance Tips and Best Practices
Efficiency Tips
Use keyboard shortcuts: Learn hjkl for navigation instead of arrow keys
Master text objects: Use ciw (change inner word), di" (delete inside quotes)
Use marks: Set marks with ma and jump to them with 'a
Learn macros: Record repetitive tasks with q and replay with @
Best Practices
Always work in command mode when not actively typing
Save frequently using :w
Use meaningful filenames and organize your work
Practice regularly to build muscle memory
Customize your .vimrc for your workflow
Conclusion
In this comprehensive lab, you have successfully learned to use the vi/vim text editor, one of the most powerful and ubiquitous text editors in Linux environments. You have mastered:

Navigation and Mode Management: Understanding command, insert, and visual modes and switching between them efficiently
File Operations: Opening, editing, saving, and closing files with various methods
Text Manipulation: Copying, cutting, pasting, searching, and replacing text
Advanced Features: Configuration customization, multiple file handling, and system administration applications
Real-World Applications: Editing system files, analyzing logs, and performing administrative tasks
Why This Matters: vi/vim proficiency is essential for Linux system administrators, DevOps engineers, and anyone working with remote systems. Many Linux distributions include vi/vim by default, making it the go-to editor when graphical interfaces are unavailable. For Red Hat Certified Specialist in Ansible Network Automation, vim skills are crucial for editing playbooks, configuration files, and troubleshooting automation scripts.

Next Steps: Continue practicing with vim daily, explore advanced features like macros and plugins, and consider learning about vim's scripting capabilities. The investment in mastering vim will pay dividends throughout your career in Linux system administration and automation.

Your vim journey has just begun – with consistent practice, you'll develop the speed and efficiency that makes vim users so productive in command-line environments.
