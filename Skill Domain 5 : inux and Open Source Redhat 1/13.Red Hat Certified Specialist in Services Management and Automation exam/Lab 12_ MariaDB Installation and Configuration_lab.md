Lab 12: MariaDB Installation and Configuration
Objectives
By the end of this lab, students will be able to:

• Install and configure MariaDB server on a Linux system • Secure MariaDB installation using best practices • Create and manage databases programmatically • Create and manage database users with specific permissions • Configure user access control and privilege management • Test database connections and verify access controls • Implement basic database security measures • Troubleshoot common MariaDB installation and configuration issues

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command-line operations • Familiarity with text editors (nano, vim, or similar) • Understanding of basic database concepts (databases, tables, users) • Knowledge of SQL fundamentals (CREATE, SELECT, INSERT commands) • Experience with package management systems (yum, dnf, or apt) • Basic networking concepts (ports, localhost, IP addresses)

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or configure additional software.

System Requirements: • CentOS/RHEL 8+ or Ubuntu 20.04+ Linux distribution • Minimum 2GB RAM and 10GB disk space • Root or sudo access • Internet connectivity for package downloads

Task 1: Install and Configure MariaDB
Subtask 1.1: Update System Packages
First, ensure your system packages are up to date before installing MariaDB.

For RHEL/CentOS systems:

sudo dnf update -y
For Ubuntu systems:

sudo apt update && sudo apt upgrade -y
Subtask 1.2: Install MariaDB Server
Install the MariaDB server package using your system's package manager.

For RHEL/CentOS systems:

sudo dnf install mariadb-server mariadb -y
For Ubuntu systems:

sudo apt install mariadb-server mariadb-client -y
Subtask 1.3: Start and Enable MariaDB Service
Start the MariaDB service and configure it to start automatically at boot.

# Start MariaDB service
sudo systemctl start mariadb

# Enable MariaDB to start at boot
sudo systemctl enable mariadb

# Check service status
sudo systemctl status mariadb
Expected Output: The status command should show MariaDB as active (running) and enabled.

Subtask 1.4: Secure MariaDB Installation
Run the security script to configure initial security settings for MariaDB.

sudo mysql_secure_installation
Interactive Configuration Steps:

Enter current password for root: Press Enter (no password set initially)
Set root password: Choose Y and enter a strong password (e.g., SecurePass123!)
Remove anonymous users: Choose Y
Disallow root login remotely: Choose Y
Remove test database: Choose Y
Reload privilege tables: Choose Y
Subtask 1.5: Verify MariaDB Installation
Test the MariaDB installation by connecting to the database server.

mysql -u root -p
Enter the root password you set in the previous step. You should see the MariaDB prompt:

MariaDB [(none)]>
Exit the MariaDB prompt:

EXIT;
Task 2: Create Databases and Users with Specific Permissions
Subtask 2.1: Create Application Databases
Connect to MariaDB as root and create databases for different applications.

mysql -u root -p
Create multiple databases:

-- Create a database for a web application
CREATE DATABASE webapp_db;

-- Create a database for inventory management
CREATE DATABASE inventory_db;

-- Create a database for user management
CREATE DATABASE users_db;

-- Show all databases
SHOW DATABASES;
Subtask 2.2: Create Database Users
Create specific users for different applications with appropriate naming conventions.

-- Create a web application user
CREATE USER 'webapp_user'@'localhost' IDENTIFIED BY 'WebApp2024!';

-- Create an inventory management user
CREATE USER 'inventory_user'@'localhost' IDENTIFIED BY 'Inventory2024!';

-- Create a read-only reporting user
CREATE USER 'report_user'@'localhost' IDENTIFIED BY 'Report2024!';

-- Create a backup user
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'Backup2024!';

-- Show all users
SELECT User, Host FROM mysql.user;
Subtask 2.3: Grant Specific Permissions
Assign appropriate permissions to each user based on their role and requirements.

-- Grant full privileges to webapp_user on webapp_db
GRANT ALL PRIVILEGES ON webapp_db.* TO 'webapp_user'@'localhost';

-- Grant full privileges to inventory_user on inventory_db
GRANT ALL PRIVILEGES ON inventory_db.* TO 'inventory_user'@'localhost';

-- Grant read-only access to report_user on all databases
GRANT SELECT ON webapp_db.* TO 'report_user'@'localhost';
GRANT SELECT ON inventory_db.* TO 'report_user'@'localhost';
GRANT SELECT ON users_db.* TO 'report_user'@'localhost';

-- Grant backup privileges to backup_user
GRANT SELECT, LOCK TABLES, SHOW VIEW ON *.* TO 'backup_user'@'localhost';

-- Flush privileges to apply changes
FLUSH PRIVILEGES;
Subtask 2.4: Create Sample Tables and Data
Create sample tables in each database to test user permissions.

-- Switch to webapp_db and create a sample table
USE webapp_db;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (username, email) VALUES 
('john_doe', 'john@example.com'),
('jane_smith', 'jane@example.com'),
('admin_user', 'admin@example.com');

-- Switch to inventory_db and create a sample table
USE inventory_db;

CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50)
);

INSERT INTO products (product_name, quantity, price, category) VALUES 
('Laptop', 25, 999.99, 'Electronics'),
('Mouse', 100, 29.99, 'Electronics'),
('Desk Chair', 15, 199.99, 'Furniture');

-- Exit MariaDB
EXIT;
Task 3: Test Database Connection and Access Control
Subtask 3.1: Test Web Application User Access
Test the webapp_user permissions by connecting and performing operations.

mysql -u webapp_user -p
Enter password: WebApp2024!

-- Test access to webapp_db
USE webapp_db;

-- Test SELECT permission
SELECT * FROM users;

-- Test INSERT permission
INSERT INTO users (username, email) VALUES ('test_user', 'test@example.com');

-- Test UPDATE permission
UPDATE users SET email = 'newemail@example.com' WHERE username = 'test_user';

-- Test DELETE permission
DELETE FROM users WHERE username = 'test_user';

-- Try to access inventory_db (should fail)
USE inventory_db;
Expected Result: The last command should fail with an access denied error.

EXIT;
Subtask 3.2: Test Read-Only User Access
Test the report_user permissions to ensure read-only access works correctly.

mysql -u report_user -p
Enter password: Report2024!

-- Test read access to webapp_db
USE webapp_db;
SELECT * FROM users;

-- Test read access to inventory_db
USE inventory_db;
SELECT * FROM products;

-- Try to insert data (should fail)
INSERT INTO products (product_name, quantity, price, category) 
VALUES ('Test Product', 1, 1.00, 'Test');
Expected Result: The INSERT command should fail with insufficient privileges error.

EXIT;
Subtask 3.3: Test Inventory User Access
Verify that inventory_user has full access to inventory_db but not other databases.

mysql -u inventory_user -p
Enter password: Inventory2024!

-- Test full access to inventory_db
USE inventory_db;

-- Test all CRUD operations
SELECT * FROM products;

INSERT INTO products (product_name, quantity, price, category) 
VALUES ('Keyboard', 50, 79.99, 'Electronics');

UPDATE products SET quantity = 45 WHERE product_name = 'Keyboard';

-- Try to access webapp_db (should fail)
USE webapp_db;
Expected Result: Access to webapp_db should be denied.

EXIT;
Subtask 3.4: Create a Database Connection Test Script
Create a shell script to automate connection testing for all users.

nano test_connections.sh
Add the following content:

#!/bin/bash

echo "=== MariaDB Connection Test Script ==="
echo

# Test root connection
echo "Testing root connection..."
mysql -u root -p -e "SELECT 'Root connection successful' as Status;"

echo

# Test webapp_user connection
echo "Testing webapp_user connection..."
mysql -u webapp_user -pWebApp2024! -e "USE webapp_db; SELECT COUNT(*) as user_count FROM users;"

echo

# Test report_user connection
echo "Testing report_user connection..."
mysql -u report_user -pReport2024! -e "USE webapp_db; SELECT 'Read-only access working' as Status;"

echo

# Test inventory_user connection
echo "Testing inventory_user connection..."
mysql -u inventory_user -pInventory2024! -e "USE inventory_db; SELECT COUNT(*) as product_count FROM products;"

echo "=== Connection tests completed ==="
Make the script executable and run it:

chmod +x test_connections.sh
./test_connections.sh
Subtask 3.5: Monitor Database Activity
Create a script to monitor current database connections and processes.

mysql -u root -p
-- Show current processes
SHOW PROCESSLIST;

-- Show current connections by user
SELECT USER, HOST, DB, COMMAND, TIME, STATE 
FROM INFORMATION_SCHEMA.PROCESSLIST 
WHERE USER != 'system user';

-- Show user privileges
SHOW GRANTS FOR 'webapp_user'@'localhost';
SHOW GRANTS FOR 'report_user'@'localhost';
SHOW GRANTS FOR 'inventory_user'@'localhost';

EXIT;
Advanced Configuration and Security
Subtask 3.6: Configure MariaDB for Remote Access (Optional)
If you need to allow remote connections, modify the MariaDB configuration.

sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
Find and modify the bind-address line:

# Change from:
bind-address = 127.0.0.1

# To (for all interfaces):
bind-address = 0.0.0.0
Restart MariaDB:

sudo systemctl restart mariadb
Create a remote user (if needed):

mysql -u root -p
CREATE USER 'remote_user'@'%' IDENTIFIED BY 'RemotePass2024!';
GRANT SELECT ON webapp_db.* TO 'remote_user'@'%';
FLUSH PRIVILEGES;
EXIT;
Subtask 3.7: Configure Firewall for MariaDB
Open the MariaDB port in the firewall if remote access is required.

For RHEL/CentOS with firewalld:

sudo firewall-cmd --permanent --add-service=mysql
sudo firewall-cmd --reload
For Ubuntu with ufw:

sudo ufw allow 3306/tcp
Troubleshooting Common Issues
Issue 1: MariaDB Service Won't Start
Symptoms: Service fails to start or shows failed status.

Solutions:

# Check service status and logs
sudo systemctl status mariadb
sudo journalctl -u mariadb

# Check if port 3306 is already in use
sudo netstat -tlnp | grep 3306

# Reset MariaDB if necessary
sudo systemctl stop mariadb
sudo systemctl start mariadb
Issue 2: Access Denied Errors
Symptoms: Users cannot connect or access databases.

Solutions:

# Verify user exists and has correct permissions
mysql -u root -p -e "SELECT User, Host FROM mysql.user;"
mysql -u root -p -e "SHOW GRANTS FOR 'username'@'localhost';"

# Reset user password if needed
mysql -u root -p -e "ALTER USER 'username'@'localhost' IDENTIFIED BY 'newpassword';"
Issue 3: Cannot Connect to MariaDB
Symptoms: Connection refused or timeout errors.

Solutions:

# Check if MariaDB is running
sudo systemctl status mariadb

# Check if MariaDB is listening on correct port
sudo netstat -tlnp | grep 3306

# Verify configuration file
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
Performance Optimization Tips
Configure MariaDB for Better Performance
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
Add performance optimizations:

[mysqld]
# Buffer pool size (set to 70-80% of available RAM)
innodb_buffer_pool_size = 1G

# Log file size
innodb_log_file_size = 256M

# Query cache
query_cache_size = 64M
query_cache_type = 1

# Connection limits
max_connections = 200
Restart MariaDB after changes:

sudo systemctl restart mariadb
Backup and Recovery Setup
Create a Backup Script
nano backup_databases.sh
#!/bin/bash

BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
sudo mkdir -p $BACKUP_DIR

# Backup all databases
sudo mysqldump -u backup_user -pBackup2024! --all-databases > $BACKUP_DIR/all_databases_$DATE.sql

# Backup specific databases
sudo mysqldump -u backup_user -pBackup2024! webapp_db > $BACKUP_DIR/webapp_db_$DATE.sql
sudo mysqldump -u backup_user -pBackup2024! inventory_db > $BACKUP_DIR/inventory_db_$DATE.sql

echo "Backup completed: $DATE"
Make executable and test:

chmod +x backup_databases.sh
./backup_databases.sh
Conclusion
In this comprehensive lab, you have successfully:

• Installed and configured MariaDB on a Linux system using package managers and security best practices • Created multiple databases for different applications with proper naming conventions • Established user accounts with role-based access control and strong password policies • Implemented granular permissions including full access, read-only access, and backup privileges • Tested database connections and verified access control mechanisms work correctly • Created automation scripts for connection testing and database backups • Configured advanced security settings including firewall rules and remote access controls • Learned troubleshooting techniques for common MariaDB installation and configuration issues

Why This Matters:

Database administration is a critical skill in modern IT infrastructure. MariaDB, as an open-source MySQL-compatible database, is widely used in enterprise environments. The skills you've developed in this lab are directly applicable to:

• Red Hat Certified Specialist in Services Management and Automation exam preparation • Production database deployment and management • Application development requiring database backends • Security compliance in enterprise environments • Automated database operations and DevOps practices

The hands-on experience with user management, permission control, and security configuration provides a solid foundation for managing databases in real-world scenarios. These skills are essential for system administrators, database administrators, and DevOps engineers working with Linux-based infrastructure.

Next Steps:

Consider exploring advanced topics such as MariaDB clustering, replication, performance tuning, and integration with containerized environments to further enhance your database administration expertise.
