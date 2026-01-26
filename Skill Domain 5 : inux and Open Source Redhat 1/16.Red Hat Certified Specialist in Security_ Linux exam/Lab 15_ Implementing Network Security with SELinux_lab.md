Lab 15: Implementing Network Security with SELinux
Objectives
By the end of this lab, students will be able to:

Configure SELinux to enforce security policies on network services
Identify and troubleshoot network-related SELinux denials using audit logs
Use semanage and chcon commands to adjust SELinux policies for proper network communication
Understand SELinux contexts and their impact on network service security
Implement best practices for SELinux network security in enterprise environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with network services (HTTP, SSH, FTP)
Knowledge of file permissions and ownership concepts
Understanding of log file analysis
Basic knowledge of SELinux concepts and modes
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with SELinux enabled
Apache HTTP server
SSH service
Administrative privileges (sudo access)
All necessary SELinux tools pre-installed
Task 1: Set SELinux to Enforcing for Network Services
Subtask 1.1: Check Current SELinux Status
First, let's examine the current SELinux configuration and understand its impact on network services.

Check the current SELinux mode:
getenforce
View detailed SELinux status:
sestatus
Check SELinux configuration file:
cat /etc/selinux/config
Subtask 1.2: Configure SELinux to Enforcing Mode
If SELinux is not in enforcing mode, we need to configure it properly.

Set SELinux to enforcing mode temporarily:
sudo setenforce 1
Verify the change:
getenforce
Make the change permanent by editing the configuration file:
sudo vi /etc/selinux/config
Ensure the following line is present:

SELINUX=enforcing
Subtask 1.3: Install and Configure Network Services
Let's set up Apache HTTP server as our test network service.

Install Apache HTTP server:
sudo dnf install httpd -y
Start and enable Apache service:
sudo systemctl start httpd
sudo systemctl enable httpd
Check service status:
sudo systemctl status httpd
Create a simple test web page:
sudo echo "<h1>SELinux Network Security Lab</h1>" > /var/www/html/index.html
Subtask 1.4: Verify SELinux Contexts for Network Services
Check SELinux context of Apache process:
ps -eZ | grep httpd
Check SELinux context of web directory:
ls -lZ /var/www/html/
View network-related SELinux booleans:
getsebool -a | grep httpd
Task 2: Troubleshoot Network-Related SELinux Denials
Subtask 2.1: Generate SELinux Denials
Let's create scenarios that will generate SELinux denials for troubleshooting practice.

Create a custom web directory with incorrect context:
sudo mkdir /custom-web
sudo echo "<h1>Custom Web Content</h1>" > /custom-web/test.html
Try to configure Apache to serve from this directory by editing the configuration:
sudo vi /etc/httpd/conf/httpd.conf
Add the following configuration block:

<Directory "/custom-web">
    AllowOverride None
    Require all granted
</Directory>

Alias /custom "/custom-web"
Restart Apache service:
sudo systemctl restart httpd
Test access to the custom directory:
curl http://localhost/custom/test.html
Subtask 2.2: Monitor and Analyze SELinux Audit Logs
Install SELinux troubleshooting tools:
sudo dnf install setroubleshoot-server -y
Monitor SELinux denials in real-time:
sudo tail -f /var/log/audit/audit.log | grep AVC
Use ausearch to find specific denials:
sudo ausearch -m avc -ts recent
Generate a human-readable report of denials:
sudo sealert -a /var/log/audit/audit.log
Subtask 2.3: Identify Common Network Service Denials
Check for HTTP-related denials:
sudo ausearch -m avc -c httpd
Look for file access denials:
sudo grep "denied" /var/log/audit/audit.log | grep httpd
Use sealert for detailed analysis:
sudo sealert -l [denial_id_from_previous_output]
Task 3: Adjust Policies Using semanage and chcon
Subtask 3.1: Fix File Context Issues with chcon
The chcon command temporarily changes SELinux contexts.

Check the current context of our custom directory:
ls -lZ /custom-web/
Change the context to match Apache requirements:
sudo chcon -R -t httpd_exec_t /custom-web/
Verify the context change:
ls -lZ /custom-web/
Test web access again:
curl http://localhost/custom/test.html
Subtask 3.2: Create Permanent Policy Changes with semanage
The semanage command makes permanent changes to SELinux policy.

View current file context mappings:
sudo semanage fcontext -l | grep httpd_exec_t
Add a permanent file context mapping:
sudo semanage fcontext -a -t httpd_exec_t "/custom-web(/.*)?"
Apply the new context mapping:
sudo restorecon -R /custom-web/
Verify the permanent change:
ls -lZ /custom-web/
Subtask 3.3: Configure Network Port Access
Let's configure Apache to run on a non-standard port and adjust SELinux accordingly.

Check current HTTP port assignments:
sudo semanage port -l | grep http
Configure Apache to listen on port 8080 by editing the configuration:
sudo vi /etc/httpd/conf/httpd.conf
Change the Listen directive:

Listen 8080
Add the new port to SELinux policy:
sudo semanage port -a -t http_port_t -p tcp 8080
Restart Apache and test:
sudo systemctl restart httpd
curl http://localhost:8080
Subtask 3.4: Manage SELinux Booleans for Network Services
SELinux booleans control specific policy behaviors.

List all HTTP-related booleans:
getsebool -a | grep httpd
Enable network connections for HTTP (if needed):
sudo setsebool -P httpd_can_network_connect on
Allow HTTP to connect to databases:
sudo setsebool -P httpd_can_network_connect_db on
Verify boolean settings:
getsebool httpd_can_network_connect
getsebool httpd_can_network_connect_db
Advanced Configuration Examples
Example 1: Securing SSH Service
Check SSH SELinux context:
ps -eZ | grep sshd
View SSH port configuration:
sudo semanage port -l | grep ssh
Add a custom SSH port:
sudo semanage port -a -t ssh_port_t -p tcp 2222
Example 2: FTP Service Configuration
Install and configure FTP service:
sudo dnf install vsftpd -y
sudo systemctl start vsftpd
Check FTP-related SELinux booleans:
getsebool -a | grep ftp
Enable FTP home directory access:
sudo setsebool -P ftp_home_dir on
Verification and Testing
Comprehensive System Check
Verify all services are running correctly:
sudo systemctl status httpd
sudo systemctl status sshd
Check for any remaining SELinux denials:
sudo ausearch -m avc -ts today
Test network connectivity:
curl http://localhost
curl http://localhost:8080
curl http://localhost/custom/test.html
Verify SELinux contexts are correct:
ls -lZ /var/www/html/
ls -lZ /custom-web/
Troubleshooting Common Issues
Issue 1: Service Won't Start After SELinux Changes
Problem: Apache fails to start after SELinux configuration changes.

Solution:

sudo systemctl status httpd
sudo journalctl -u httpd
sudo sealert -a /var/log/audit/audit.log
Issue 2: File Access Denied
Problem: Web server cannot access files despite correct permissions.

Solution:

sudo restorecon -R /var/www/html/
sudo semanage fcontext -l | grep httpd
Issue 3: Network Connection Blocked
Problem: Service cannot make network connections.

Solution:

getsebool -a | grep network
sudo setsebool -P httpd_can_network_connect on
Best Practices for SELinux Network Security
Always use semanage for permanent changes instead of chcon
Test changes in permissive mode first before enforcing
Monitor audit logs regularly for security violations
Use specific contexts rather than broad permissions
Document all policy changes for future reference
Regular security audits of SELinux configurations
Conclusion
In this lab, you have successfully implemented network security using SELinux by:

Configuring SELinux to enforcing mode for enhanced network service security
Learning to identify and troubleshoot network-related SELinux denials through audit log analysis
Using semanage to create permanent policy changes for file contexts and network ports
Applying chcon for temporary context modifications during testing
Managing SELinux booleans to control specific network service behaviors
Implementing best practices for SELinux network security in enterprise environments
These skills are essential for maintaining secure network services in enterprise Linux environments and are directly applicable to the Red Hat Certified Specialist in Security: Linux exam. SELinux provides mandatory access control that significantly enhances system security by preventing unauthorized access to network services and system resources, even if traditional discretionary access controls are compromised.

The knowledge gained from this lab enables you to implement defense-in-depth security strategies, troubleshoot complex SELinux issues, and maintain secure network services in production environments.
