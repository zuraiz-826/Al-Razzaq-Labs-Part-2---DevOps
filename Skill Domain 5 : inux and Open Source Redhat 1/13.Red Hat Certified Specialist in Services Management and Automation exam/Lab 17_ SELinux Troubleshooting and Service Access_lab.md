Lab 17: SELinux Troubleshooting and Service Access
Objectives
By the end of this lab, students will be able to:

Understand SELinux security contexts and policy enforcement
Investigate SELinux access denials using audit logs and troubleshooting tools
Use audit2why and audit2allow to analyze SELinux denials
Modify SELinux policies to allow legitimate service access
Test and verify service functionality after SELinux policy modifications
Apply best practices for SELinux troubleshooting in production environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and text editors
Knowledge of Linux services and systemctl commands
Understanding of file permissions and ownership concepts
Basic networking concepts (ports, protocols)
Previous exposure to SELinux concepts (contexts, modes, policies)
Lab Environment Setup
Al Nafi Cloud Machines: This lab uses pre-configured Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your ready-to-use environment. No need to build your own virtual machine or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with SELinux enabled
Pre-installed troubleshooting tools (audit2why, audit2allow, sealert)
Sample web service and database service for testing
Administrative privileges (sudo access)
Task 1: Investigate SELinux Logs for Denied Access
Subtask 1.1: Verify SELinux Status and Mode
First, let's check the current SELinux configuration and ensure it's properly enabled.

Check SELinux status:
sestatus
Verify SELinux is in enforcing mode:
getenforce
If SELinux is not in enforcing mode, set it temporarily:
sudo setenforce 1
Expected Output: You should see SELinux status as "enabled" and current mode as "Enforcing".

Subtask 1.2: Create a Test Scenario with SELinux Denials
Let's create a realistic scenario where SELinux will deny access to demonstrate troubleshooting techniques.

Install Apache web server if not already installed:
sudo dnf install httpd -y
Create a custom web directory outside the standard location:
sudo mkdir -p /custom/web/content
Create a test HTML file:
sudo tee /custom/web/content/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>SELinux Test Page</title>
</head>
<body>
    <h1>Welcome to SELinux Troubleshooting Lab</h1>
    <p>If you can see this page, SELinux policies are working correctly!</p>
</body>
</html>
EOF
Set proper ownership:
sudo chown -R apache:apache /custom/web/content
sudo chmod -R 755 /custom/web/content
Configure Apache to serve from the custom directory:
sudo tee /etc/httpd/conf.d/custom-site.conf > /dev/null << 'EOF'
<VirtualHost *:8080>
    DocumentRoot /custom/web/content
    <Directory "/custom/web/content">
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>

Listen 8080
EOF
Start and enable Apache:
sudo systemctl start httpd
sudo systemctl enable httpd
Subtask 1.3: Generate SELinux Denials
Try to access the custom website:
curl http://localhost:8080
Expected Result: This should fail due to SELinux policy restrictions.

Check if the service is running and listening:
sudo systemctl status httpd
sudo netstat -tlnp | grep :8080
Subtask 1.4: Examine SELinux Audit Logs
Check recent SELinux denials in the audit log:
sudo ausearch -m AVC -ts recent
Use audit2why to analyze the denials:
sudo ausearch -m AVC -ts recent | audit2why
Alternative method using sealert for more detailed analysis:
sudo sealert -a /var/log/audit/audit.log
Check SELinux context of the custom directory:
ls -laZ /custom/web/content/
Compare with standard Apache document root context:
ls -laZ /var/www/html/
Key Observation: Notice the difference in SELinux contexts between the standard Apache directory and your custom directory.

Task 2: Modify SELinux Policies to Allow Required Services
Subtask 2.1: Understand the SELinux Denial
Analyze the specific denial message from audit2why output. Look for:

Source context: The process trying to access (httpd_t)
Target context: The file/directory being accessed
Permission: The type of access being denied (read, write, execute)
Check current SELinux context of the custom directory:

sudo semanage fcontext -l | grep "/var/www"
Subtask 2.2: Method 1 - Change File Context (Recommended)
The best practice is to set the correct SELinux context for files rather than modifying policies.

Set the correct SELinux context for the custom web directory:
sudo semanage fcontext -a -t httpd_exec_t "/custom/web/content(/.*)?"
Apply the context change:
sudo restorecon -Rv /custom/web/content/
Verify the context change:
ls -laZ /custom/web/content/
Test the web service again:
curl http://localhost:8080
Subtask 2.3: Method 2 - Create Custom SELinux Policy (Alternative)
If changing file context isn't suitable, you can create a custom policy.

First, restore the original context to demonstrate policy creation:
sudo semanage fcontext -d "/custom/web/content(/.*)?"
sudo restorecon -Rv /custom/web/content/
Generate SELinux denials again:
curl http://localhost:8080
Create a custom policy module using audit2allow:
sudo ausearch -m AVC -ts recent | audit2allow -M custom_httpd_policy
Review the generated policy:
cat custom_httpd_policy.te
Install the custom policy:
sudo semodule -i custom_httpd_policy.pp
Verify the policy installation:
sudo semodule -l | grep custom_httpd_policy
Subtask 2.4: Configure Additional Service - Database Access
Let's create another scenario with a database service.

Install MariaDB:
sudo dnf install mariadb-server -y
Create a custom database directory:
sudo mkdir -p /custom/database/data
sudo chown -R mysql:mysql /custom/database/data
Configure MariaDB to use custom directory by editing the configuration:
sudo tee -a /etc/my.cnf.d/custom.cnf > /dev/null << 'EOF'
[mysqld]
datadir=/custom/database/data
socket=/custom/database/data/mysql.sock

[client]
socket=/custom/database/data/mysql.sock
EOF
Set SELinux context for the database directory:
sudo semanage fcontext -a -t mysqld_db_t "/custom/database/data(/.*)?"
sudo restorecon -Rv /custom/database/data/
Initialize and start MariaDB:
sudo mysql_install_db --user=mysql --datadir=/custom/database/data
sudo systemctl start mariadb
sudo systemctl enable mariadb
Task 3: Test Service Access Post-Configuration
Subtask 3.1: Verify Web Service Functionality
Test the web service access:
curl -v http://localhost:8080
Check for any remaining SELinux denials:
sudo ausearch -m AVC -ts recent
Verify Apache can read the custom directory:
sudo -u apache cat /custom/web/content/index.html
Test from a different terminal or browser if available:
wget http://localhost:8080 -O test_page.html
cat test_page.html
Subtask 3.2: Verify Database Service Functionality
Check MariaDB service status:
sudo systemctl status mariadb
Test database connectivity:
sudo mysql -u root -e "SELECT 'Database is working!' as Status;"
Verify the custom data directory is being used:
sudo mysql -u root -e "SHOW VARIABLES LIKE 'datadir';"
Check for any database-related SELinux denials:
sudo ausearch -m AVC -ts recent | grep mysql
Subtask 3.3: Performance and Security Verification
Create a simple PHP script to test web-database integration:
sudo dnf install php php-mysqlnd -y
Create a test PHP file:
sudo tee /custom/web/content/dbtest.php > /dev/null << 'EOF'
<?php
$connection = new mysqli('localhost', 'root', '', '');
if ($connection->connect_error) {
    die('Connection failed: ' . $connection->connect_error);
}
echo '<h2>Database Connection Successful!</h2>';
echo '<p>SELinux is properly configured for web-database access.</p>';
$connection->close();
?>
EOF
Test the PHP script:
curl http://localhost:8080/dbtest.php
Monitor system logs for any issues:
sudo journalctl -f -u httpd -u mariadb
Subtask 3.4: Document and Verify SELinux Configuration
Create a summary of SELinux contexts applied:
sudo semanage fcontext -l | grep custom
List any custom SELinux modules installed:
sudo semodule -l | grep custom
Generate a final SELinux status report:
echo "=== SELinux Configuration Summary ===" > selinux_config_summary.txt
echo "SELinux Status: $(getenforce)" >> selinux_config_summary.txt
echo "Custom File Contexts:" >> selinux_config_summary.txt
sudo semanage fcontext -l | grep custom >> selinux_config_summary.txt
echo "Custom Modules:" >> selinux_config_summary.txt
sudo semodule -l | grep custom >> selinux_config_summary.txt
echo "Services Status:" >> selinux_config_summary.txt
systemctl is-active httpd mariadb >> selinux_config_summary.txt
cat selinux_config_summary.txt
Test all services one final time:
echo "Testing web service..."
curl -s http://localhost:8080 | grep -o "<title>.*</title>"
echo "Testing database service..."
sudo mysql -u root -e "SELECT 'OK' as DatabaseStatus;" 2>/dev/null
echo "Checking for recent SELinux denials..."
sudo ausearch -m AVC -ts recent | wc -l
Troubleshooting Common Issues
Issue 1: Services Still Denied After Context Changes
Symptoms: Services still fail to access files after setting correct contexts.

Solution:

# Ensure contexts are properly applied
sudo restorecon -Rv /custom/
# Check if SELinux booleans need to be enabled
getsebool -a | grep httpd
# Enable necessary booleans if needed
sudo setsebool -P httpd_can_network_connect on
Issue 2: Custom Policies Not Working
Symptoms: Custom SELinux policies don't resolve access issues.

Solution:

# Remove problematic custom policy
sudo semodule -r custom_httpd_policy
# Regenerate with more recent audit logs
sudo ausearch -m AVC -ts recent | audit2allow -M new_custom_policy
sudo semodule -i new_custom_policy.pp
Issue 3: Database Connection Issues
Symptoms: Database service fails to start or connect.

Solution:

# Check SELinux context for database files
ls -laZ /custom/database/data/
# Ensure proper ownership
sudo chown -R mysql:mysql /custom/database/data/
# Check for database-specific SELinux booleans
getsebool -a | grep mysql
Conclusion
In this comprehensive lab, you have successfully:

Investigated SELinux denials using audit logs and the audit2why tool to understand why services were being blocked
Modified SELinux policies using two different approaches: setting proper file contexts (recommended) and creating custom policy modules
Tested service access after configuration changes to ensure both web and database services function correctly with SELinux enforcing
Key Takeaways
SELinux Context Management: The most effective approach is usually to set correct SELinux contexts rather than creating permissive policies
Troubleshooting Methodology: Always start by examining audit logs with audit2why to understand the root cause of denials
Security Best Practices: Custom policies should be used sparingly; proper file contexts and SELinux booleans are preferred solutions
Testing Importance: Always verify that services work correctly after making SELinux changes
Real-World Applications
This lab simulates common scenarios system administrators face when:

Deploying web applications in custom directories
Configuring databases with non-standard data locations
Troubleshooting service access issues in SELinux-enabled environments
Maintaining security while ensuring application functionality
The skills learned here are directly applicable to Red Hat Certified Specialist in Services Management and Automation exam objectives and real-world enterprise Linux environments where SELinux is mandatory for security compliance.

Next Steps
To further develop your SELinux expertise:

Practice with different service types (FTP, DNS, email servers)
Learn about SELinux user mappings and role-based access control
Explore advanced policy writing and custom module development
Study SELinux in containerized environments (Podman, Docker)
