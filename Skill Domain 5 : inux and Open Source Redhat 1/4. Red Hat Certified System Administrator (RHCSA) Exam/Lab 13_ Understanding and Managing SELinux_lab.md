Lab 13: Understanding and Managing SELinux
Objectives
By the end of this lab, students will be able to:

Understand what SELinux is and why it's important for system security
Check and interpret SELinux status using the sestatus command
Configure different SELinux modes using setenforce
Troubleshoot SELinux-related issues using ausearch and audit2allow
Apply SELinux security policies to protect system resources
Identify and resolve common SELinux permission problems
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with file permissions and ownership concepts
Knowledge of basic system administration tasks
Understanding of log files and system monitoring
Access to a Linux system with SELinux installed (typically Red Hat Enterprise Linux, CentOS, or Fedora)
Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines with SELinux already installed and configured. Simply click Start Lab to access your virtual environment. No need to build your own VM or install additional software - everything is ready for you to begin learning immediately.

Lab Environment Setup
Your cloud machine includes:

Red Hat Enterprise Linux or CentOS with SELinux enabled
All necessary SELinux tools and utilities pre-installed
Sample files and directories for testing
Audit logging configured and running
Task 1: Check SELinux Status with sestatus
Subtask 1.1: Understanding SELinux Basics
SELinux (Security-Enhanced Linux) is a mandatory access control system that provides an additional layer of security beyond traditional Linux permissions. Think of it as a security guard that checks every action against a detailed policy before allowing it to proceed.

Step 1: Open a terminal and check if you have root privileges

whoami
If you're not root, switch to root user:

sudo su -
Step 2: Check the current SELinux status

sestatus
You should see output similar to:

SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:     33
Subtask 1.2: Understanding SELinux Modes
SELinux operates in three modes:

Enforcing: SELinux actively enforces security policies and blocks unauthorized actions
Permissive: SELinux logs policy violations but doesn't block them
Disabled: SELinux is completely turned off
Step 3: Check the current mode specifically

getenforce
Step 4: View SELinux configuration file

cat /etc/selinux/config
This file shows the default SELinux mode that will be used after system reboot.

Subtask 1.3: Examining SELinux Contexts
Step 5: Check SELinux contexts of files

ls -Z /etc/passwd
The output shows the SELinux context in the format: user:role:type:level

Step 6: Check SELinux contexts of processes

ps -eZ | head -10
Step 7: Check your current SELinux user context

id -Z
Task 2: Configure SELinux Modes with setenforce
Subtask 2.1: Temporarily Changing SELinux Mode
The setenforce command allows you to temporarily change SELinux mode without rebooting.

Step 1: Check current mode

getenforce
Step 2: Switch to permissive mode (if currently in enforcing)

setenforce 0
Step 3: Verify the mode change

getenforce
You should see Permissive.

Step 4: Check the status again

sestatus
Notice that the current mode shows permissive while the config file mode remains enforcing.

Subtask 2.2: Testing Mode Differences
Step 5: Create a test scenario in permissive mode

# Create a test directory
mkdir /tmp/selinux-test
cd /tmp/selinux-test

# Create a test file
echo "This is a test file" > testfile.txt

# Check the SELinux context
ls -Z testfile.txt
Step 6: Try to change the context incorrectly (this will be logged but not blocked in permissive mode)

# This command might fail, but let's see what happens
chcon -t httpd_exec_t testfile.txt
ls -Z testfile.txt
Subtask 2.3: Switching Back to Enforcing Mode
Step 7: Return to enforcing mode

setenforce 1
Step 8: Verify the change

getenforce
Subtask 2.4: Permanently Changing SELinux Mode
Step 9: To permanently change SELinux mode, edit the configuration file

# First, make a backup
cp /etc/selinux/config /etc/selinux/config.backup

# View current configuration
cat /etc/selinux/config
Step 10: If you needed to change the permanent mode (don't do this now), you would edit:

# This is just for demonstration - don't run this command
# sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
Task 3: Troubleshoot SELinux Issues using ausearch and audit2allow
Subtask 3.1: Understanding SELinux Logging
SELinux logs all policy violations to the audit log, typically located at /var/log/audit/audit.log.

Step 1: Check if auditd service is running

systemctl status auditd
Step 2: Look at recent audit log entries

tail -20 /var/log/audit/audit.log
Subtask 3.2: Creating a SELinux Violation for Testing
Step 3: Create a scenario that will trigger SELinux violations

# Create a simple web directory
mkdir -p /var/www/html/test
echo "<h1>Test Page</h1>" > /var/www/html/test/index.html

# Check the current context
ls -Z /var/www/html/test/index.html
Step 4: Move a file from /tmp to web directory (this often causes context issues)

# Create a file in /tmp
echo "<h1>Moved Test Page</h1>" > /tmp/moved-page.html

# Move it to web directory
mv /tmp/moved-page.html /var/www/html/test/

# Check the context - it will likely be wrong
ls -Z /var/www/html/test/moved-page.html
Subtask 3.3: Using ausearch to Find SELinux Denials
Step 5: Search for recent SELinux denials

ausearch -m AVC -ts recent
If no recent denials are found, let's create one:

Step 6: Try to start httpd service and access the moved file

# Install httpd if not already installed
yum install -y httpd

# Start httpd service
systemctl start httpd
systemctl enable httpd

# Try to access the file via curl (this might generate SELinux denials)
curl http://localhost/test/moved-page.html
Step 7: Search for SELinux denials related to httpd

ausearch -m AVC -c httpd
Subtask 3.4: Using audit2allow to Generate Policy Rules
Step 8: Use audit2allow to analyze denials and suggest solutions

# Search for recent httpd-related denials and pipe to audit2allow
ausearch -m AVC -c httpd | audit2allow
Step 9: Get more detailed information about the denial

ausearch -m AVC -c httpd | audit2allow -w
This command explains what the denial means in human-readable terms.

Step 10: Generate a custom policy module (if needed)

# Generate a policy module
ausearch -m AVC -c httpd | audit2allow -M myhttpd

# This creates two files: myhttpd.te and myhttpd.pp
ls -l myhttpd.*
Subtask 3.5: Proper SELinux Context Management
Instead of creating custom policies, it's often better to fix the context:

Step 11: Fix the file context properly

# Restore proper SELinux contexts for web content
restorecon -Rv /var/www/html/test/
Step 12: Verify the context is now correct

ls -Z /var/www/html/test/
Step 13: Test access again

curl http://localhost/test/moved-page.html
Subtask 3.6: Using sealert for User-Friendly Analysis
Step 14: Install setroubleshoot if not already available

yum install -y setroubleshoot-server
Step 15: Use sealert to analyze recent denials

sealert -a /var/log/audit/audit.log
Advanced Troubleshooting Techniques
Subtask 3.7: Common SELinux Commands for Troubleshooting
Step 16: Check SELinux booleans that might affect your service

# List all SELinux booleans
getsebool -a | grep httpd

# Check specific boolean
getsebool httpd_can_network_connect
Step 17: Temporarily enable a boolean if needed

# Example: Allow httpd to make network connections
setsebool httpd_can_network_connect on

# To make it permanent, add -P flag
# setsebool -P httpd_can_network_connect on
Step 18: Check file contexts and policies

# Show file context rules
semanage fcontext -l | grep "/var/www"

# Show port contexts
semanage port -l | grep http
Practical Exercise: Complete SELinux Scenario
Step 19: Create a comprehensive test scenario
# Create a custom application directory
mkdir -p /opt/myapp/bin
mkdir -p /opt/myapp/data

# Create a simple script
cat > /opt/myapp/bin/myapp.sh << 'EOF'
#!/bin/bash
echo "MyApp is running"
echo "Data directory contents:"
ls -la /opt/myapp/data/
EOF

chmod +x /opt/myapp/bin/myapp.sh

# Create some data files
echo "Important data" > /opt/myapp/data/data1.txt
echo "More data" > /opt/myapp/data/data2.txt
Step 20: Check and fix SELinux contexts
# Check current contexts
ls -Z /opt/myapp/bin/
ls -Z /opt/myapp/data/

# Set appropriate contexts
semanage fcontext -a -t bin_t "/opt/myapp/bin(/.*)?"
semanage fcontext -a -t var_t "/opt/myapp/data(/.*)?"

# Apply the contexts
restorecon -Rv /opt/myapp/

# Verify the changes
ls -Z /opt/myapp/bin/
ls -Z /opt/myapp/data/
Cleanup and Verification
Step 21: Clean up test files and verify system state
# Remove test files
rm -rf /tmp/selinux-test
rm -rf /var/www/html/test
rm -rf /opt/myapp

# Check final SELinux status
sestatus
getenforce

# Verify no recent denials
ausearch -m AVC -ts today | tail -5
Conclusion
In this lab, you have successfully:

Learned to check SELinux status using sestatus and getenforce commands, understanding the different modes and their implications for system security.

Configured SELinux modes using setenforce to temporarily switch between enforcing and permissive modes, and learned how to make permanent changes through configuration files.

Mastered SELinux troubleshooting using ausearch to find policy violations and audit2allow to understand and resolve SELinux denials.

Applied proper context management using restorecon and semanage to ensure files and directories have appropriate SELinux contexts.

Gained practical experience with real-world scenarios involving web servers and custom applications.

Why This Matters
SELinux is a critical security feature in enterprise Linux environments. Understanding how to manage and troubleshoot SELinux is essential for:

System Security: SELinux provides mandatory access controls that prevent unauthorized access even if traditional permissions are compromised
Compliance: Many security standards require mandatory access controls like SELinux
Troubleshooting: Many application issues in RHEL/CentOS environments are related to SELinux contexts
Career Development: SELinux knowledge is required for RHCSA certification and valued by employers
Key Takeaways
Always check SELinux status when troubleshooting permission issues
Use permissive mode temporarily for testing, but return to enforcing mode for production
Proper file contexts are usually better than custom policies
The audit log is your best friend for understanding SELinux denials
Tools like sealert and audit2allow make SELinux troubleshooting much easier
Next Steps
To further develop your SELinux skills:

Practice with different services (database servers, mail servers, etc.)
Learn about SELinux policy development
Explore advanced features like MLS (Multi-Level Security)
Study SELinux in containerized environments
This foundational knowledge will serve you well in managing secure Linux systems and preparing for advanced system administration roles.
