Lab 15: Managing SELinux Policies
Objectives
By the end of this lab, students will be able to:

• Understand the fundamentals of SELinux (Security-Enhanced Linux) and its security model • Check and interpret SELinux status using the sestatus command • Modify SELinux policies using the semanage command-line tool • Troubleshoot SELinux denials by analyzing audit logs and resolving common issues • Apply SELinux best practices for system security hardening • Configure SELinux contexts and boolean settings for specific applications

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command-line interface • Familiarity with file permissions and ownership concepts • Knowledge of system administration fundamentals • Understanding of log file analysis • Access to a Red Hat-based Linux distribution (RHEL, CentOS, or Fedora)

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes: • Red Hat Enterprise Linux 9 or CentOS Stream 9 • SELinux enabled and configured • All necessary SELinux management tools pre-installed • Sample applications and services for testing

Task 1: Check SELinux Status with sestatus
Subtask 1.1: Understanding SELinux Basics
SELinux (Security-Enhanced Linux) is a mandatory access control (MAC) security mechanism that provides fine-grained access control over system resources. Before working with SELinux policies, we need to understand its current state.

Step 1: Open a terminal and check if you have root privileges:

sudo whoami
Step 2: Display comprehensive SELinux status information:

sestatus
Expected Output Analysis:

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
Step 3: Check the current SELinux mode:

getenforce
Step 4: View SELinux mode configuration:

cat /etc/selinux/config
Key Concepts: • Enforcing: SELinux policy is enforced, denials are logged and blocked • Permissive: SELinux policy is not enforced, but denials are logged • Disabled: SELinux is completely disabled

Subtask 1.3: Examining SELinux Contexts
Step 5: View SELinux contexts for files in your home directory:

ls -Z ~/
Step 6: Check SELinux context for system processes:

ps -eZ | head -10
Step 7: Display SELinux context for the current user:

id -Z
Task 2: Modify SELinux Policies with semanage
Subtask 2.1: Installing SELinux Management Tools
Step 8: Ensure all SELinux management tools are installed:

sudo dnf install -y policycoreutils-python-utils setools-console
Step 9: Verify semanage installation:

which semanage
semanage --help
Subtask 2.2: Managing SELinux File Contexts
Step 10: Create a test directory and file:

mkdir -p /opt/testapp
sudo touch /opt/testapp/config.conf
Step 11: Check the current SELinux context:

ls -Z /opt/testapp/
Step 12: Add a custom file context rule:

sudo semanage fcontext -a -t httpd_config_t "/opt/testapp/config.conf"
Step 13: Apply the new context:

sudo restorecon -v /opt/testapp/config.conf
Step 14: Verify the context change:

ls -Z /opt/testapp/config.conf
Subtask 2.3: Managing SELinux Port Contexts
Step 15: View current port contexts for HTTP:

semanage port -l | grep http
Step 16: Add a custom port for HTTP service:

sudo semanage port -a -t http_port_t -p tcp 8080
Step 17: Verify the new port context:

semanage port -l | grep 8080
Subtask 2.4: Managing SELinux Booleans
Step 18: List all SELinux booleans:

getsebool -a | head -10
Step 19: Check a specific boolean (httpd network connect):

getsebool httpd_can_network_connect
Step 20: Temporarily enable the boolean:

sudo setsebool httpd_can_network_connect on
Step 21: Make the boolean change persistent:

sudo setsebool -P httpd_can_network_connect on
Step 22: Verify the boolean status:

getsebool httpd_can_network_connect
Subtask 2.5: Managing SELinux User Mappings
Step 23: View current SELinux user mappings:

semanage login -l
Step 24: View SELinux users:

semanage user -l
Task 3: Troubleshoot SELinux Denials Using Audit Logs
Subtask 3.1: Understanding SELinux Audit Logs
Step 25: Install audit log analysis tools:

sudo dnf install -y setroubleshoot-server
Step 26: Check if auditd service is running:

sudo systemctl status auditd
Step 27: View recent SELinux denials:

sudo ausearch -m avc -ts recent
Subtask 3.2: Creating and Analyzing SELinux Denials
Step 28: Create a scenario that will generate SELinux denials. First, create a simple web content:

sudo mkdir -p /home/testuser/website
sudo echo "<html><body>Test Page</body></html>" > /home/testuser/website/index.html
sudo chown -R apache:apache /home/testuser/website
Step 29: Install and start Apache web server:

sudo dnf install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
Step 30: Configure Apache to serve content from the non-standard location:

sudo tee /etc/httpd/conf.d/testsite.conf << EOF
<VirtualHost *:80>
    DocumentRoot /home/testuser/website
    <Directory "/home/testuser/website">
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF
Step 31: Restart Apache (this should generate SELinux denials):

sudo systemctl restart httpd
Step 32: Try to access the website:

curl http://localhost/
Subtask 3.3: Analyzing SELinux Denials
Step 33: Check for SELinux denials in the audit log:

sudo ausearch -m avc -ts recent
Step 34: Use sealert to analyze denials:

sudo sealert -a /var/log/audit/audit.log
Step 35: Get specific suggestions for recent denials:

sudo grep "denied" /var/log/audit/audit.log | tail -5
Subtask 3.4: Resolving SELinux Denials
Step 36: Check the current context of the website directory:

ls -Z /home/testuser/website/
Step 37: Set the correct SELinux context for web content:

sudo semanage fcontext -a -t httpd_exec_t "/home/testuser/website(/.*)?"
sudo restorecon -R -v /home/testuser/website/
Step 38: Alternative approach - copy context from standard web directory:

sudo chcon --reference=/var/www/html /home/testuser/website/index.html
Step 39: Verify the context change:

ls -Z /home/testuser/website/
Step 40: Test the website again:

curl http://localhost/
Subtask 3.5: Using SELinux Troubleshooting Tools
Step 41: Install additional troubleshooting tools:

sudo dnf install -y policycoreutils-gui
Step 42: Generate a custom SELinux policy module (if needed):

sudo grep httpd /var/log/audit/audit.log | audit2allow -M myhttpd
Step 43: Review the generated policy:

cat myhttpd.te
Step 44: Install the custom policy module (only if necessary):

sudo semodule -i myhttpd.pp
Advanced SELinux Management
Subtask 3.6: SELinux Policy Modules
Step 45: List installed SELinux policy modules:

semodule -l | head -10
Step 46: Get information about a specific module:

semodule -l | grep httpd
Step 47: Check SELinux policy version:

sestatus | grep "policy version"
Subtask 3.7: SELinux Monitoring and Maintenance
Step 48: Create a script to monitor SELinux denials:

sudo tee /usr/local/bin/selinux-monitor.sh << 'EOF'
#!/bin/bash
echo "=== SELinux Status ==="
sestatus

echo -e "\n=== Recent SELinux Denials ==="
ausearch -m avc -ts today 2>/dev/null | tail -10

echo -e "\n=== SELinux Boolean Status ==="
getsebool -a | grep "on$" | wc -l
echo "Total booleans enabled"

echo -e "\n=== Custom File Contexts ==="
semanage fcontext -l -C
EOF

sudo chmod +x /usr/local/bin/selinux-monitor.sh
Step 49: Run the monitoring script:

sudo /usr/local/bin/selinux-monitor.sh
Step 50: Set up a cron job for regular SELinux monitoring:

echo "0 */6 * * * root /usr/local/bin/selinux-monitor.sh >> /var/log/selinux-monitor.log 2>&1" | sudo tee -a /etc/crontab
Troubleshooting Common Issues
Common SELinux Problems and Solutions
Issue 1: Service fails to start due to SELinux

Solution: Check audit logs and adjust file contexts or booleans
Issue 2: Web server cannot access files in non-standard locations

Solution: Set appropriate httpd_exec_t or httpd_config_t contexts
Issue 3: Applications cannot bind to non-standard ports

Solution: Add port contexts using semanage port
Debugging Commands:

# Check for denials
sudo ausearch -m avc -ts recent

# Analyze with sealert
sudo sealert -a /var/log/audit/audit.log

# Generate policy suggestions
sudo grep denied /var/log/audit/audit.log | audit2allow
Lab Cleanup
Step 51: Clean up the test environment:

# Remove test files
sudo rm -rf /opt/testapp
sudo rm -rf /home/testuser/website

# Remove custom Apache configuration
sudo rm -f /etc/httpd/conf.d/testsite.conf

# Remove custom SELinux contexts
sudo semanage fcontext -d "/opt/testapp/config.conf"
sudo semanage port -d -t http_port_t -p tcp 8080

# Restart Apache
sudo systemctl restart httpd
Conclusion
In this comprehensive lab, you have successfully:

• Mastered SELinux Status Checking: You learned to use sestatus, getenforce, and context viewing commands to understand your system's SELinux configuration and current state.

• Implemented Policy Management: You gained hands-on experience with semanage to modify file contexts, port contexts, booleans, and user mappings, giving you the tools to customize SELinux policies for specific applications and services.

• Developed Troubleshooting Skills: You learned to analyze audit logs, identify SELinux denials, and resolve common issues using tools like ausearch, sealert, and audit2allow.

• Applied Real-World Scenarios: Through practical exercises with Apache web server configuration, you experienced how SELinux affects real applications and learned to resolve typical deployment challenges.

Why This Matters: SELinux is a critical security component in enterprise Linux environments. The skills you've developed in this lab are essential for:

System Security: Implementing defense-in-depth security strategies
Compliance: Meeting security requirements in regulated industries
Troubleshooting: Resolving application deployment issues in SELinux-enabled environments
Career Advancement: These skills are fundamental for Red Hat certifications and Linux system administration roles
Next Steps: Continue practicing with different applications and services to build confidence in SELinux management. Consider exploring advanced topics like custom policy development and SELinux in containerized environments.

The knowledge gained from this lab provides a solid foundation for managing SELinux in production environments and prepares you for advanced Linux security administration tasks.
