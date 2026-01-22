Lab 6: Working with vim and nano
Objectives
By the end of this lab, students will be able to:

• Navigate and edit files using vim's basic commands and modes • Create, modify, and save files using the nano text editor • Understand the differences between vim and nano editors • Perform common text editing operations in both editors • Save and exit files properly in both vim and nano • Choose the appropriate editor for different scenarios

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Familiarity with file system navigation using commands like ls, cd, and pwd • Knowledge of basic file operations such as creating directories with mkdir • Understanding of file permissions concepts • Completion of previous labs covering basic Linux commands

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install any software.

Your cloud machine includes: • CentOS/RHEL-based Linux distribution • vim text editor (pre-installed) • nano text editor (pre-installed) • Sample files for practice • Full sudo access for system administration tasks

Task 1: Getting Started with Text Editors
Subtask 1.1: Understanding Text Editors
Text editors are essential tools for system administrators and developers. In this lab, we'll work with two popular editors:

• vim: A powerful, modal text editor with advanced features • nano: A simple, user-friendly text editor perfect for beginners

Subtask 1.2: Create Practice Directory
First, let's create a workspace for our lab exercises:

mkdir ~/text-editor-lab
cd ~/text-editor-lab
pwd
Subtask 1.3: Check Available Editors
Verify that both editors are installed on your system:

which vim
which nano
vim --version | head -1
nano --version | head -1
Task 2: Working with nano Editor
Subtask 2.1: Understanding nano Interface
nano is an excellent starting point for beginners because it displays helpful commands at the bottom of the screen.

Subtask 2.2: Create Your First File with nano
Let's create a simple configuration file:

nano server-config.txt
Once nano opens, you'll see: • A blank editing area • Command shortcuts at the bottom (^ means Ctrl key) • The filename at the top

Subtask 2.3: Basic nano Operations
Type the following content into your file:

# Server Configuration File
# Created on: [Today's Date]

server_name=web-server-01
port=8080
max_connections=100
timeout=30
debug_mode=false

# Database Settings
db_host=localhost
db_port=3306
db_name=webapp
Subtask 2.4: nano Navigation and Editing
Practice these essential nano commands:

• Arrow keys: Move cursor around • Ctrl + A: Move to beginning of line • Ctrl + E: Move to end of line • Ctrl + Y: Page up • Ctrl + V: Page down • Ctrl + K: Cut entire line • Ctrl + U: Paste cut text

Try cutting and pasting a line:

Position cursor on the port=8080 line
Press Ctrl + K to cut the line
Move cursor to after server_name=web-server-01
Press Ctrl + U to paste
Subtask 2.5: Save and Exit nano
To save your file:

Press Ctrl + O (WriteOut)
Press Enter to confirm the filename
Press Ctrl + X to exit
Verify your file was saved:

ls -la server-config.txt
cat server-config.txt
Subtask 2.6: Reopen and Modify File
Open the file again and make changes:

nano server-config.txt
Add these lines at the end:

# Security Settings
ssl_enabled=true
ssl_port=443
encryption=AES256
Save and exit using Ctrl + O, then Ctrl + X.

Task 3: Working with vim Editor
Subtask 3.1: Understanding vim Modes
vim operates in different modes: • Normal mode: For navigation and commands (default) • Insert mode: For typing text • Command mode: For saving, quitting, and advanced operations

Subtask 3.2: Create Your First File with vim
vim network-settings.conf
When vim opens, you're in Normal mode. Notice there are no helpful hints at the bottom like nano.

Subtask 3.3: Enter Insert Mode and Add Content
Press i to enter Insert mode (you'll see -- INSERT -- at the bottom)
Type the following content:
# Network Configuration
# System: RHEL/CentOS

interface=eth0
ip_address=192.168.1.100
subnet_mask=255.255.255.0
gateway=192.168.1.1
dns_primary=8.8.8.8
dns_secondary=8.8.4.4

# Network Services
ssh_enabled=yes
firewall_enabled=yes
Subtask 3.4: Return to Normal Mode
Press Esc to return to Normal mode. The -- INSERT -- indicator will disappear.

Subtask 3.5: Basic vim Navigation in Normal Mode
Practice these navigation commands (make sure you're in Normal mode):

• h: Move left • j: Move down • k: Move up • l: Move right • w: Move to next word • b: Move to previous word • 0: Move to beginning of line • $: Move to end of line • gg: Go to first line • G: Go to last line

Subtask 3.6: Basic vim Editing Commands
Try these editing commands in Normal mode:

• x: Delete character under cursor • dd: Delete entire line • yy: Copy (yank) entire line • p: Paste after cursor • u: Undo last change • Ctrl + r: Redo

Practice exercise:

Navigate to the line with dns_primary=8.8.8.8
Press yy to copy the line
Press p to paste it below
Press i to enter Insert mode
Change the pasted line to dns_tertiary=1.1.1.1
Press Esc to return to Normal mode
Subtask 3.7: Save and Exit vim
From Normal mode, you can use these commands:

• :w: Save file • :q: Quit vim • :wq: Save and quit • :q!: Quit without saving

To save and exit:

Make sure you're in Normal mode (press Esc)
Type :wq and press Enter
Subtask 3.8: Verify and Reopen File
Check your file:

ls -la network-settings.conf
cat network-settings.conf
Reopen with vim to practice more:

vim network-settings.conf
Subtask 3.9: Advanced vim Operations
Try these useful commands:

Search and Replace:

In Normal mode, type / followed by a search term
Example: /ssh to find "ssh"
Press n to find next occurrence
Press N to find previous occurrence
Line Numbers:

In Normal mode, type :set number to show line numbers
Type :set nonumber to hide them
Go to Specific Line:

Type :5 to go to line 5
Practice these commands, then save and exit with :wq.

Task 4: Comparing vim and nano
Subtask 4.1: Create Comparison Files
Let's create identical files with both editors to compare the experience:

Using nano:

nano comparison-nano.txt
Add this content:

Editor: nano
Ease of use: Beginner-friendly
Learning curve: Gentle
Best for: Quick edits, beginners
Commands visible: Yes
Save with Ctrl + O, Enter, Ctrl + X.

Using vim:

vim comparison-vim.txt
Press i to enter Insert mode
Add this content:
Editor: vim
Ease of use: Advanced users
Learning curve: Steep
Best for: Complex editing, programming
Commands visible: No
Press Esc, then :wq to save and exit
Subtask 4.2: View Both Files
cat comparison-nano.txt
echo "---"
cat comparison-vim.txt
Task 5: Practical Scenarios
Subtask 5.1: Quick Configuration Edit (nano)
System administrators often need to make quick configuration changes. Let's simulate editing a web server configuration:

nano /tmp/httpd.conf
Add this content:

# Apache HTTP Server Configuration
ServerRoot "/etc/httpd"
Listen 80
ServerName localhost:80
DocumentRoot "/var/www/html"

# Security Settings
ServerTokens Prod
ServerSignature Off

# Performance Settings
MaxRequestWorkers 150
ThreadsPerChild 25
Save and exit. This demonstrates nano's strength for quick, straightforward edits.

Subtask 5.2: Complex File Editing (vim)
For more complex editing tasks, vim's power becomes apparent:

vim /tmp/complex-config.conf
Press i and add this content:
# Multi-service Configuration
[database]
host=db-server-01
port=5432
username=admin
password=temp123

[webserver]
host=web-server-01
port=80
ssl_port=443
document_root=/var/www

[cache]
host=cache-server-01
port=6379
memory_limit=512M
Press Esc to enter Normal mode
Use :set number to show line numbers
Navigate to line 5 with :5
Change the password using cw (change word):
Position cursor on "temp123"
Press cw
Type "secure_password_2024"
Press Esc
Save with :w
Subtask 5.3: Search and Replace in vim
Let's replace all instances of "server" with "node":

In Normal mode, type: :%s/server/node/g
Press Enter
Save and exit with :wq
View the result:

cat /tmp/complex-config.conf
Task 6: Best Practices and Tips
Subtask 6.1: When to Use Each Editor
Use nano when: • Making quick configuration changes • You're new to Linux text editors • Working with simple text files • You need to see available commands

Use vim when: • Editing complex configuration files • Programming or scripting • You need advanced search/replace features • Working with large files • You want maximum efficiency after learning

Subtask 6.2: Create a Cheat Sheet
Create quick reference files for both editors:

nano cheat sheet:

nano nano-cheatsheet.txt
Add: ``` NANO QUICK REFERENCE
Ctrl + O : Save file Ctrl + X : Exit Ctrl + K : Cut line Ctrl + U : Paste Ctrl + W : Search Ctrl + A : Beginning of line Ctrl + E : End of line Ctrl + Y : Page up Ctrl + V : Page down


**vim cheat sheet:**
```bash
vim vim-cheatsheet.txt
Press i and add: ``` VIM QUICK REFERENCE
MODES: i : Insert mode Esc : Normal mode : : Command mode

NAVIGATION: h,j,k,l : Left, down, up, right w : Next word b : Previous word 0 : Beginning of line $ : End of line gg : First line G : Last line

EDITING: x : Delete character dd : Delete line yy : Copy line p : Paste u : Undo

SAVE/EXIT: :w : Save :q : Quit :wq : Save and quit :q! : Quit without saving


Press **Esc**, then **:wq**.

## Troubleshooting Common Issues

### Issue 1: Stuck in vim Insert Mode
**Problem**: Can't execute commands in vim
**Solution**: Press **Esc** to return to Normal mode

### Issue 2: Can't Exit vim
**Problem**: vim won't close
**Solution**: 
1. Press **Esc** to ensure Normal mode
2. Type **:q!** to force quit without saving
3. Or **:wq** to save and quit

### Issue 3: Accidentally Modified File
**Problem**: Made unwanted changes
**Solution**: 
- In vim: Press **u** multiple times to undo
- In nano: **Ctrl + X** then choose "No" when asked to save

### Issue 4: Lost in Large File
**Problem**: Can't find your position in file
**Solution**:
- In vim: **:set number** to show line numbers
- In nano: **Ctrl + C** shows current position

## Lab Verification

Verify your lab completion by checking these files exist and contain content:

```bash
ls -la ~/text-editor-lab/
cat ~/text-editor-lab/server-config.txt
cat ~/text-editor-lab/network-settings.conf
cat /tmp/complex-config.conf
Conclusion
Congratulations! You have successfully completed Lab 6: Working with vim and nano. In this lab, you have:

• Mastered nano basics: Learned to create, edit, and save files using nano's user-friendly interface with visible command shortcuts • Conquered vim fundamentals: Understood vim's modal system and practiced essential navigation and editing commands • Compared both editors: Experienced the differences between nano's simplicity and vim's power • Applied practical skills: Worked with realistic configuration files that system administrators handle daily • Built troubleshooting knowledge: Learned how to handle common issues when working with both editors

Why This Matters: Text editors are fundamental tools for Linux system administrators. nano provides an accessible entry point for quick edits and configuration changes, while vim offers powerful features for complex editing tasks. Understanding both editors makes you more versatile and efficient in managing Linux systems.

Next Steps: Practice using both editors regularly. Start with nano for simple tasks and gradually incorporate vim for more complex editing scenarios. As you become comfortable with vim's modal system, you'll discover its efficiency for advanced text manipulation tasks.

Red Hat Certification Relevance: Both vim and nano are essential tools covered in Red Hat certification exams. The skills you've learned here directly apply to managing configuration files, editing scripts, and performing system administration tasks required for RHCSA certification.

Remember: The best editor is the one you're comfortable using efficiently. Many system administrators use both editors depending on the task at hand!
