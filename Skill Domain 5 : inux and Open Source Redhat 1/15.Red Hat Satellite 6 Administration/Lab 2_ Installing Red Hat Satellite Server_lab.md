Lab 2: Installing Red Hat Satellite Server
Objectives
By the end of this lab, you will be able to:

Install Red Hat Satellite server using the satellite-installer command-line tool
Configure PostgreSQL database for Satellite data storage
Set up proper network configurations for Satellite server connectivity
Verify the installation and perform initial configuration checks
Understand the core components of a Satellite server deployment
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux system administration
Familiarity with command-line interface operations
Knowledge of network configuration concepts (IP addresses, DNS, firewall rules)
Understanding of database concepts and PostgreSQL basics
Experience with package management in Red Hat-based systems
Required Knowledge Areas:
Linux file system navigation
Basic networking concepts
System service management (systemctl)
Text editing using vi/vim or nano
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab and you'll have access to a pre-configured environment. No need to build your own virtual machine or worry about hardware requirements.

What You'll Get:
Red Hat Enterprise Linux 8 or 9 system
Sufficient resources (minimum 4 CPU cores, 20GB RAM, 300GB storage)
Network connectivity pre-configured
Root access to perform administrative tasks
Task 1: Prepare the System for Satellite Installation
Subtask 1.1: System Requirements Verification
First, let's verify that our system meets the minimum requirements for Red Hat Satellite installation.

# Check system resources
echo "=== System Information ==="
hostnamectl
echo ""
echo "=== CPU Information ==="
lscpu | grep -E "CPU\(s\)|Model name"
echo ""
echo "=== Memory Information ==="
free -h
echo ""
echo "=== Disk Space Information ==="
df -h
Subtask 1.2: Configure System Hostname
Set a proper fully qualified domain name (FQDN) for your Satellite server:

# Set the hostname (replace 'satellite.example.com' with your desired FQDN)
hostnamectl set-hostname satellite.example.com

# Verify the hostname change
hostnamectl status

# Update /etc/hosts file
echo "127.0.0.1 satellite.example.com satellite" >> /etc/hosts

# Verify DNS resolution
nslookup satellite.example.com
Subtask 1.3: Configure Firewall Rules
Open the necessary ports for Satellite server communication:

# Enable and start firewalld service
systemctl enable --now firewalld

# Add Satellite-specific firewall rules
firewall-cmd --permanent --add-port=443/tcp    # HTTPS for web UI
firewall-cmd --permanent --add-port=80/tcp     # HTTP (redirects to HTTPS)
firewall-cmd --permanent --add-port=5647/tcp   # Katello agent
firewall-cmd --permanent --add-port=8000/tcp   # Anaconda
firewall-cmd --permanent --add-port=8140/tcp   # Puppet
firewall-cmd --permanent --add-port=9090/tcp   # Cockpit (optional)
firewall-cmd --permanent --add-port=53/udp     # DNS
firewall-cmd --permanent --add-port=53/tcp     # DNS
firewall-cmd --permanent --add-port=67/udp     # DHCP
firewall-cmd --permanent --add-port=69/udp     # TFTP

# Reload firewall configuration
firewall-cmd --reload

# Verify firewall rules
firewall-cmd --list-all
Task 2: Install Red Hat Satellite Server
Subtask 2.1: Enable Required Repositories
Configure the necessary repositories for Satellite installation:

# Register the system (if not already registered)
# Note: In a real environment, you would use your Red Hat credentials
# For this lab, we'll simulate the repository setup

# Enable required repositories
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms
subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms
subscription-manager repos --enable=satellite-6.12-for-rhel-8-x86_64-rpms
subscription-manager repos --enable=satellite-maintenance-6.12-for-rhel-8-x86_64-rpms

# Update the system
dnf update -y

# Reboot if kernel was updated
needs-restarting -r && echo "Reboot required" || echo "No reboot needed"
Subtask 2.2: Install Satellite Packages
Install the Red Hat Satellite server packages:

# Install Satellite server packages
dnf install -y satellite

# Verify installation
rpm -qa | grep satellite

# Check if satellite-installer is available
which satellite-installer
satellite-installer --help | head -20
Subtask 2.3: Run the Satellite Installer
Execute the satellite-installer with appropriate parameters:

# Create a script for the installation to make it repeatable
cat > /root/satellite-install.sh << 'EOF'
#!/bin/bash

# Satellite installation script
satellite-installer \
  --scenario satellite \
  --foreman-initial-admin-username admin \
  --foreman-initial-admin-password 'RedHat123!' \
  --foreman-initial-admin-first-name "Satellite" \
  --foreman-initial-admin-last-name "Administrator" \
  --foreman-initial-admin-email "admin@example.com" \
  --foreman-initial-organization "Default Organization" \
  --foreman-initial-location "Default Location" \
  --enable-foreman-plugin-remote-execution \
  --enable-foreman-plugin-ansible \
  --enable-foreman-plugin-openscap \
  --tuning development

EOF

# Make the script executable
chmod +x /root/satellite-install.sh

# Run the installation (this will take 15-30 minutes)
echo "Starting Satellite installation..."
echo "This process will take approximately 15-30 minutes."
echo "Please be patient and do not interrupt the installation."

/root/satellite-install.sh
Important Note: The installation process is lengthy. You'll see various services being configured including:

PostgreSQL database setup
Apache web server configuration
Pulp content management
Candlepin subscription management
Foreman provisioning engine
Task 3: Configure PostgreSQL Database
Subtask 3.1: Verify PostgreSQL Installation and Configuration
Check that PostgreSQL was properly installed and configured during the Satellite installation:

# Check PostgreSQL service status
systemctl status postgresql

# Verify PostgreSQL is listening on the correct port
ss -tlnp | grep 5432

# Check PostgreSQL version
sudo -u postgres psql -c "SELECT version();"

# List Satellite databases
sudo -u postgres psql -l | grep -E "(foreman|candlepin|pulp)"
Subtask 3.2: Configure PostgreSQL Performance Settings
Optimize PostgreSQL settings for Satellite workload:

# Backup original PostgreSQL configuration
cp /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.backup

# Create optimized PostgreSQL configuration
cat >> /var/lib/pgsql/data/postgresql.conf << 'EOF'

# Satellite-specific PostgreSQL optimizations
shared_buffers = 1GB
effective_cache_size = 4GB
work_mem = 4MB
maintenance_work_mem = 500MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200

EOF

# Restart PostgreSQL to apply changes
systemctl restart postgresql

# Verify PostgreSQL is running with new configuration
systemctl status postgresql
Subtask 3.3: Database Maintenance Configuration
Set up automated database maintenance tasks:

# Create database maintenance script
cat > /usr/local/bin/satellite-db-maintenance.sh << 'EOF'
#!/bin/bash

# Satellite database maintenance script
echo "Starting database maintenance at $(date)"

# Vacuum and analyze Foreman database
sudo -u postgres psql foreman -c "VACUUM ANALYZE;"

# Vacuum and analyze Candlepin database  
sudo -u postgres psql candlepin -c "VACUUM ANALYZE;"

# Check database sizes
echo "Database sizes:"
sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database WHERE datname IN ('foreman', 'candlepin', 'pulpcore');"

echo "Database maintenance completed at $(date)"
EOF

# Make script executable
chmod +x /usr/local/bin/satellite-db-maintenance.sh

# Test the maintenance script
/usr/local/bin/satellite-db-maintenance.sh
Task 4: Configure Network Settings and Connectivity
Subtask 4.1: Verify Network Configuration
Ensure proper network connectivity for Satellite services:

# Check network interface configuration
ip addr show

# Verify routing table
ip route show

# Test DNS resolution
nslookup satellite.example.com
nslookup google.com

# Check if Satellite web interface is accessible
curl -k https://localhost/users/login
Subtask 4.2: Configure SELinux for Satellite
Ensure SELinux is properly configured for Satellite operations:

# Check SELinux status
getenforce
sestatus

# Verify Satellite-specific SELinux contexts
ls -Z /usr/share/foreman/
ls -Z /var/lib/pulp/

# Check for SELinux denials related to Satellite
ausearch -m avc -ts recent | grep -i satellite || echo "No recent SELinux denials found"

# Set SELinux booleans for Satellite (if needed)
setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_network_relay 1
Subtask 4.3: Test Satellite Services
Verify all Satellite services are running correctly:

# Check all Satellite-related services
satellite-maintain service status

# Alternative method to check individual services
systemctl status httpd
systemctl status postgresql
systemctl status pulpcore-api
systemctl status pulpcore-content
systemctl status pulpcore-worker@*

# Check Satellite health
satellite-maintain health check

# Verify web interface accessibility
curl -k -I https://satellite.example.com
Task 5: Initial Satellite Configuration and Verification
Subtask 5.1: Access Satellite Web Interface
Test access to the Satellite web interface:

# Display connection information
echo "=== Satellite Server Access Information ==="
echo "URL: https://$(hostname)"
echo "Username: admin"
echo "Password: RedHat123!"
echo ""
echo "You can now access the Satellite web interface using these credentials."

# Test API connectivity
curl -k -u admin:RedHat123! https://$(hostname)/api/status
Subtask 5.2: Verify Installation Logs
Check installation logs for any issues:

# Review Satellite installer logs
tail -50 /var/log/foreman-installer/satellite.log

# Check for any error messages
grep -i error /var/log/foreman-installer/satellite.log | tail -10

# Review system logs for Satellite services
journalctl -u httpd --since "1 hour ago" --no-pager
journalctl -u postgresql --since "1 hour ago" --no-pager
Subtask 5.3: Create Initial Configuration Backup
Create a backup of the initial configuration:

# Create backup directory
mkdir -p /root/satellite-backups

# Backup Satellite configuration
satellite-maintain backup offline /root/satellite-backups/initial-config-$(date +%Y%m%d)

# Verify backup was created
ls -la /root/satellite-backups/
Troubleshooting Common Issues
Issue 1: Installation Fails Due to Insufficient Resources
Symptoms: Installation stops with memory or disk space errors

Solution:

# Check available resources
free -h
df -h

# If running low on memory, add swap space
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
Issue 2: PostgreSQL Connection Issues
Symptoms: Database connection errors in logs

Solution:

# Check PostgreSQL status and logs
systemctl status postgresql
journalctl -u postgresql --since "1 hour ago"

# Verify PostgreSQL is accepting connections
sudo -u postgres psql -c "SELECT 1;"

# Restart PostgreSQL if needed
systemctl restart postgresql
Issue 3: Firewall Blocking Connections
Symptoms: Cannot access web interface from remote systems

Solution:

# Verify firewall rules
firewall-cmd --list-all

# Temporarily disable firewall for testing
systemctl stop firewalld

# If that resolves the issue, re-enable and add proper rules
systemctl start firewalld
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
Conclusion
Congratulations! You have successfully completed the Red Hat Satellite Server installation lab. Here's what you accomplished:

Key Achievements:
System Preparation: You prepared a Red Hat Enterprise Linux system with proper hostname, firewall rules, and system requirements verification.

Satellite Installation: You successfully installed Red Hat Satellite server using the satellite-installer tool with appropriate configuration parameters.

Database Configuration: You configured and optimized PostgreSQL database settings for Satellite workload, including performance tuning and maintenance procedures.

Network Configuration: You established proper network connectivity, configured SELinux settings, and verified service accessibility.

Verification and Testing: You verified the installation success, tested web interface access, and created initial configuration backups.

Why This Matters:
Red Hat Satellite is a critical infrastructure component for enterprise Linux environments. The skills you've learned in this lab are essential for:

Centralized Management: Satellite provides a single point of control for managing hundreds or thousands of Red Hat systems
Compliance and Security: Automated patching and configuration management help maintain security standards
Operational Efficiency: Streamlined provisioning and management reduce administrative overhead
Cost Control: Better visibility into subscription usage and system inventory
Next Steps:
With your Satellite server now installed and configured, you're ready to:

Configure content management and synchronization
Set up host provisioning and configuration management
Implement patch management workflows
Integrate with monitoring and automation tools
This foundation will serve you well as you continue your journey toward Red Hat Satellite 6 Administration certification and advanced enterprise Linux management skills.
