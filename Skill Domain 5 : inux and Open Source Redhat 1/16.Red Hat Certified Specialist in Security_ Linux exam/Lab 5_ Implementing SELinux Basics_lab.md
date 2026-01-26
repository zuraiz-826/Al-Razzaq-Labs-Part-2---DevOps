Lab 5: Implementing SELinux Basics
Objectives
By the end of this lab, students will be able to:

Understand the fundamental concepts of SELinux (Security-Enhanced Linux)
Configure SELinux to operate in Enforcing mode for maximum security
Modify SELinux contexts using both temporary and permanent methods
Troubleshoot SELinux policy violations using built-in diagnostic tools
Apply SELinux best practices for system hardening
Prerequisites
Before starting this lab, students should have:

Basic Linux command-line knowledge
Understanding of file permissions and ownership concepts
Familiarity with system administration tasks
Knowledge of text editors (vi/vim or nano)
Basic understanding of Linux services and processes
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with SELinux installed
Root access privileges
All necessary SELinux tools pre-installed
Sample files and directories for practice
Task 1: Set SELinux to Enforcing Mode
Understanding SELinux Modes
SELinux operates in three modes:

Enforcing: SELinux policy is enforced, violations are blocked and logged
Permissive: SELinux policy violations are logged but not blocked
Disabled: SELinux is completely turned off
Subtask 1.1: Check Current SELinux Status
First, let's examine the current SELinux configuration on your system.

# Check current SELinux status
sestatus

# Check current mode
getenforce

# View SELinux configuration file
cat /etc/selinux/config
Expected Output Example:

SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   permissive
Mode from config file:          permissive
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      33
Subtask 1.2: Temporarily Set SELinux to Enforcing Mode
# Set SELinux to enforcing mode temporarily
setenforce 1

# Verify the change
getenforce
Note: This change is temporary and will revert after reboot.

Subtask 1.3: Permanently Configure SELinux to Enforcing Mode
# Edit the SELinux configuration file
vi /etc/selinux/config

# Change the SELINUX line to:
# SELINUX=enforcing

# Alternative method using sed
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# Verify the configuration
grep "^SELINUX=" /etc/selinux/config
Subtask 1.4: Understanding SELinux Policy Types
# View available SELinux policies
ls /etc/selinux/

# Check current policy
sestatus | grep "Loaded policy name"

# View policy modules
semodule -l | head -10
Task 2: Change SELinux Contexts with chcon and semanage
Understanding SELinux Contexts
SELinux contexts consist of four parts: user:role:type:level

User: SELinux user identity
Role: Role-based access control
Type: Most important for file contexts
Level: Multi-Level Security (MLS) level
Subtask 2.1: View Current File Contexts
# Create a test directory and file
mkdir /tmp/selinux-test
echo "This is a test file" > /tmp/selinux-test/testfile.txt

# View SELinux contexts
ls -Z /tmp/selinux-test/
ls -Z /tmp/selinux-test/testfile.txt

# View context of system directories
ls -Z /var/www/html/
ls -Z /etc/
Subtask 2.2: Using chcon for Temporary Context Changes
The chcon command changes SELinux contexts temporarily. These changes are lost when the file system is relabeled.

# View current context of test file
ls -Z /tmp/selinux-test/testfile.txt

# Change the type context to httpd_exec_t
chcon -t httpd_exec_t /tmp/selinux-test/testfile.txt

# Verify the change
ls -Z /tmp/selinux-test/testfile.txt

# Change multiple context components
chcon -u system_u -r object_r -t admin_home_t /tmp/selinux-test/testfile.txt

# Verify the complete change
ls -Z /tmp/selinux-test/testfile.txt

# Copy context from another file
chcon --reference=/etc/passwd /tmp/selinux-test/testfile.txt
ls -Z /tmp/selinux-test/testfile.txt
Subtask 2.3: Using semanage for Permanent Context Changes
The semanage command makes permanent changes to SELinux policy that survive system relabeling.

# Install policycoreutils-python-utils if not available
dnf install -y policycoreutils-python-utils

# View current file context mappings
semanage fcontext -l | grep "/tmp"

# Add a permanent file context rule
semanage fcontext -a -t httpd_exec_t "/tmp/selinux-test/.*"

# View the new rule
semanage fcontext -l | grep "/tmp/selinux-test"

# Apply the context to existing files
restorecon -R /tmp/selinux-test/

# Verify the context was applied
ls -Z /tmp/selinux-test/
Subtask 2.4: Working with Port Contexts
# View current port contexts
semanage port -l | grep http

# Add a custom port for HTTP service
semanage port -a -t http_port_t -p tcp 8080

# Verify the new port context
semanage port -l | grep 8080

# List all custom port modifications
semanage port -l -C
Subtask 2.5: Managing Boolean Values
# List all SELinux booleans
getsebool -a | head -10

# Check specific boolean values
getsebool httpd_can_network_connect
getsebool ftpd_anon_write

# Set a boolean temporarily
setsebool httpd_can_network_connect on

# Set a boolean permanently
setsebool -P ftpd_anon_write on

# Verify the changes
getsebool httpd_can_network_connect ftpd_anon_write
Task 3: Troubleshoot SELinux Denials Using audit2allow and sealert
Understanding SELinux Logging
SELinux violations are logged to:

/var/log/audit/audit.log (if auditd is running)
/var/log/messages (if auditd is not running)
Subtask 3.1: Generate SELinux Denials for Testing
# Install Apache web server for testing
dnf install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a test file in wrong location
echo "<h1>Test Page</h1>" > /root/test.html

# Copy file to web directory (this may cause SELinux issues)
cp /root/test.html /var/www/html/

# Check the context
ls -Z /var/www/html/test.html

# Try to access the file through web browser or curl
curl http://localhost/test.html
Subtask 3.2: Install and Configure SELinux Troubleshooting Tools
# Install setroubleshoot packages
dnf install -y setroubleshoot-server setroubleshoot

# Restart auditd service
systemctl restart auditd

# Install additional analysis tools
dnf install -y policycoreutils-python-utils
Subtask 3.3: Using sealert for SELinux Analysis
# Generate some SELinux denials first
# Try to start a service on a non-standard port
echo "Listen 8080" >> /etc/httpd/conf/httpd.conf
systemctl restart httpd

# Check for SELinux alerts
sealert -a /var/log/audit/audit.log

# View recent alerts with more detail
sealert -l "*"

# Analyze specific AVC denial
grep "AVC" /var/log/audit/audit.log | tail -5
Subtask 3.4: Using audit2allow for Policy Generation
# View recent AVC denials
ausearch -m AVC -ts recent

# Generate policy recommendations from audit log
audit2allow -a

# Generate a specific policy module
audit2allow -a -M mypolicy

# View the generated policy
cat mypolicy.te

# Install the custom policy module
semodule -i mypolicy.pp

# Verify the module is installed
semodule -l | grep mypolicy
Subtask 3.5: Advanced Troubleshooting Techniques
# Create a more complex scenario
mkdir /custom-web
echo "<h1>Custom Web Content</h1>" > /custom-web/index.html

# Modify Apache configuration to use custom directory
echo "DocumentRoot /custom-web" >> /etc/httpd/conf/httpd.conf
echo "<Directory /custom-web>" >> /etc/httpd/conf/httpd.conf
echo "    AllowOverride None" >> /etc/httpd/conf/httpd.conf
echo "    Require all granted" >> /etc/httpd/conf/httpd.conf
echo "</Directory>" >> /etc/httpd/conf/httpd.conf

# Restart Apache (this will likely fail due to SELinux)
systemctl restart httpd

# Check service status
systemctl status httpd

# Analyze the denial
ausearch -m AVC -ts recent | audit2allow

# Fix the issue by setting proper context
semanage fcontext -a -t httpd_exec_t "/custom-web(/.*)?"
restorecon -R /custom-web/

# Restart Apache
systemctl restart httpd
Subtask 3.6: Monitoring SELinux in Real-Time
# Monitor audit log in real-time
tail -f /var/log/audit/audit.log | grep AVC

# In another terminal, generate some activity
curl http://localhost/

# Use journalctl to monitor SELinux messages
journalctl -f | grep -i selinux

# Check for setroubleshoot messages
journalctl -u setroubleshoot
Common Troubleshooting Tips
Issue 1: Service Won't Start After Enabling SELinux
Symptoms: Services fail to start with permission denied errors

Solution:

# Check for AVC denials
ausearch -m AVC -ts recent

# Generate and apply policy
audit2allow -a -M service_fix
semodule -i service_fix.pp
Issue 2: Web Server Can't Access Files
Symptoms: HTTP 403 errors, files exist but aren't accessible

Solution:

# Check file contexts
ls -Z /var/www/html/

# Restore proper contexts
restorecon -R /var/www/html/

# Or set specific context
chcon -t httpd_exec_t /var/www/html/file.html
Issue 3: Custom Application Ports Blocked
Symptoms: Applications can't bind to custom ports

Solution:

# Add port to SELinux policy
semanage port -a -t http_port_t -p tcp 8080

# Verify port is added
semanage port -l | grep 8080
Verification and Testing
Final Verification Steps
# Verify SELinux is in enforcing mode
getenforce

# Check that all services are running
systemctl status httpd

# Verify custom contexts are working
ls -Z /tmp/selinux-test/
ls -Z /custom-web/

# Test web server functionality
curl http://localhost/
curl http://localhost:8080/

# Check for any remaining denials
ausearch -m AVC -ts today | wc -l
Cleanup
# Remove test files and directories
rm -rf /tmp/selinux-test/
rm -rf /custom-web/

# Remove custom policy module
semodule -r mypolicy

# Reset Apache configuration
cp /etc/httpd/conf/httpd.conf.bak /etc/httpd/conf/httpd.conf
systemctl restart httpd

# Remove custom port context
semanage port -d -t http_port_t -p tcp 8080
Conclusion
In this lab, you have successfully:

Configured SELinux in Enforcing mode to provide maximum security protection for your Linux system
Learned the difference between temporary and permanent context changes using chcon and semanage commands
Mastered SELinux troubleshooting techniques using audit2allow and sealert tools to diagnose and resolve policy violations
Implemented practical SELinux policies for web services and custom applications
Why This Matters: SELinux is a critical security feature in enterprise Linux environments, particularly in Red Hat Enterprise Linux systems. Understanding how to properly configure and troubleshoot SELinux is essential for:

System Security: Preventing unauthorized access and privilege escalation
Compliance Requirements: Meeting security standards in regulated industries
Professional Certification: These skills are directly tested in Red Hat Certified Specialist in Security: Linux exam
Real-World Applications: Managing production servers where security is paramount
The hands-on experience gained in this lab provides you with practical skills that are immediately applicable in professional Linux administration roles, making you more valuable in the cybersecurity and system administration job market.
