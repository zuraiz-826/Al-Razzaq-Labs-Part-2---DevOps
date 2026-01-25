Lab 11: Setting Up Samba (SMB) for File Sharing
Objectives
By the end of this lab, students will be able to:

Install and configure Samba server on a Linux system
Create and manage SMB file shares for cross-platform access
Implement user-based access control for file shares
Configure shares accessible by both Windows and Linux clients
Test and verify Samba functionality across different operating systems
Troubleshoot common Samba configuration issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Knowledge of file permissions and user management in Linux
Familiarity with network concepts (IP addresses, ports, protocols)
Understanding of Windows file sharing concepts
Basic text editor skills (nano, vim, or similar)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install any software locally.

Your lab environment includes:

CentOS/RHEL 8 or 9 based system with root access
Network connectivity for testing
All necessary repositories configured
Task 1: Install and Configure Samba Server
Subtask 1.1: Install Samba Packages
First, we'll install the required Samba packages and dependencies.

# Update the system packages
sudo dnf update -y

# Install Samba server and client packages
sudo dnf install -y samba samba-client samba-common

# Install additional utilities for testing
sudo dnf install -y cifs-utils
Subtask 1.2: Start and Enable Samba Services
Configure Samba services to start automatically and begin running.

# Start the Samba services
sudo systemctl start smb nmb

# Enable services to start at boot
sudo systemctl enable smb nmb

# Check the status of services
sudo systemctl status smb nmb
Subtask 1.3: Configure Firewall Rules
Open the necessary ports for Samba communication.

# Add Samba service to firewall
sudo firewall-cmd --permanent --add-service=samba

# Reload firewall configuration
sudo firewall-cmd --reload

# Verify firewall rules
sudo firewall-cmd --list-services
Subtask 1.4: Backup Original Configuration
Always backup configuration files before making changes.

# Create backup of original Samba configuration
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

# View the original configuration
sudo cat /etc/samba/smb.conf
Task 2: Create Shares for Windows and Linux Clients
Subtask 2.1: Create Directory Structure
Set up directories that will be shared via Samba.

# Create shared directories
sudo mkdir -p /srv/samba/public
sudo mkdir -p /srv/samba/private
sudo mkdir -p /srv/samba/team

# Create a directory for individual user homes
sudo mkdir -p /srv/samba/users
Subtask 2.2: Set Directory Permissions
Configure appropriate permissions for the shared directories.

# Set permissions for public share (everyone can read/write)
sudo chmod 777 /srv/samba/public

# Set permissions for private share (restricted access)
sudo chmod 750 /srv/samba/private

# Set permissions for team share
sudo chmod 770 /srv/samba/team

# Set permissions for users directory
sudo chmod 755 /srv/samba/users

# Change ownership to nobody for public access
sudo chown nobody:nobody /srv/samba/public
Subtask 2.3: Configure SELinux Context
Set proper SELinux contexts for Samba shares.

# Set SELinux context for Samba shares
sudo setsebool -P samba_enable_home_dirs on
sudo setsebool -P samba_export_all_rw on

# Apply SELinux context to directories
sudo semanage fcontext -a -t samba_share_t "/srv/samba(/.*)?"
sudo restorecon -R /srv/samba/
Subtask 2.4: Create Main Samba Configuration
Create a comprehensive Samba configuration file.

# Create new Samba configuration
sudo tee /etc/samba/smb.conf > /dev/null << 'EOF'
[global]
    # Server identification
    workgroup = WORKGROUP
    server string = Samba Server %v
    netbios name = SAMBASERVER
    
    # Security settings
    security = user
    map to guest = bad user
    guest account = nobody
    
    # Logging
    log file = /var/log/samba/log.%m
    max log size = 1000
    log level = 1
    
    # Network settings
    hosts allow = 127. 192.168. 10.
    hosts deny = ALL
    
    # Performance tuning
    socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
    
    # Disable printing by default
    load printers = no
    printing = bsd
    printcap name = /dev/null
    disable spoolss = yes

# Public share - accessible to everyone
[public]
    comment = Public File Share
    path = /srv/samba/public
    browseable = yes
    writable = yes
    guest ok = yes
    read only = no
    force user = nobody
    force group = nobody
    create mask = 0664
    directory mask = 0775

# Private share - requires authentication
[private]
    comment = Private File Share
    path = /srv/samba/private
    browseable = yes
    writable = yes
    guest ok = no
    read only = no
    valid users = @sambausers
    create mask = 0664
    directory mask = 0775

# Team share - for group collaboration
[team]
    comment = Team Collaboration Share
    path = /srv/samba/team
    browseable = yes
    writable = yes
    guest ok = no
    read only = no
    valid users = @teamusers
    force group = teamusers
    create mask = 0664
    directory mask = 0775

# Individual user directories
[users]
    comment = User Home Directories
    path = /srv/samba/users/%S
    browseable = no
    writable = yes
    guest ok = no
    read only = no
    valid users = %S
    create mask = 0600
    directory mask = 0700
EOF
Subtask 2.5: Test Configuration Syntax
Verify that the Samba configuration is valid.

# Test Samba configuration syntax
sudo testparm

# Test configuration and show all parameters
sudo testparm -v
Task 3: Set Up User-Based Access Control for File Shares
Subtask 3.1: Create System Groups
Create groups for organizing user access to shares.

# Create groups for Samba users
sudo groupadd sambausers
sudo groupadd teamusers

# Verify groups were created
getent group sambausers teamusers
Subtask 3.2: Create System Users
Create users that will access the Samba shares.

# Create system users
sudo useradd -M -s /sbin/nologin sambauser1
sudo useradd -M -s /sbin/nologin sambauser2
sudo useradd -M -s /sbin/nologin teamuser1
sudo useradd -M -s /sbin/nologin teamuser2

# Add users to appropriate groups
sudo usermod -a -G sambausers sambauser1
sudo usermod -a -G sambausers sambauser2
sudo usermod -a -G teamusers teamuser1
sudo usermod -a -G teamusers teamuser2
Subtask 3.3: Create Samba User Accounts
Add users to the Samba user database with passwords.

# Add users to Samba database
# You'll be prompted to enter passwords for each user
sudo smbpasswd -a sambauser1
sudo smbpasswd -a sambauser2
sudo smbpasswd -a teamuser1
sudo smbpasswd -a teamuser2

# Enable the users
sudo smbpasswd -e sambauser1
sudo smbpasswd -e sambauser2
sudo smbpasswd -e teamuser1
sudo smbpasswd -e teamuser2

# List Samba users
sudo pdbedit -L
Subtask 3.4: Create User Home Directories
Set up individual directories for users in the users share.

# Create individual user directories
sudo mkdir -p /srv/samba/users/sambauser1
sudo mkdir -p /srv/samba/users/sambauser2
sudo mkdir -p /srv/samba/users/teamuser1
sudo mkdir -p /srv/samba/users/teamuser2

# Set ownership and permissions
sudo chown sambauser1:sambausers /srv/samba/users/sambauser1
sudo chown sambauser2:sambausers /srv/samba/users/sambauser2
sudo chown teamuser1:teamusers /srv/samba/users/teamuser1
sudo chown teamuser2:teamusers /srv/samba/users/teamuser2

sudo chmod 700 /srv/samba/users/sambauser1
sudo chmod 700 /srv/samba/users/sambauser2
sudo chmod 700 /srv/samba/users/teamuser1
sudo chmod 700 /srv/samba/users/teamuser2
Subtask 3.5: Set Directory Ownership for Group Shares
Configure proper ownership for group-accessible shares.

# Set ownership for private share
sudo chown root:sambausers /srv/samba/private

# Set ownership for team share
sudo chown root:teamusers /srv/samba/team

# Apply proper permissions
sudo chmod 770 /srv/samba/private
sudo chmod 770 /srv/samba/team
Subtask 3.6: Restart Samba Services
Apply all configuration changes by restarting services.

# Restart Samba services
sudo systemctl restart smb nmb

# Verify services are running
sudo systemctl status smb nmb

# Check if Samba is listening on correct ports
sudo netstat -tulpn | grep -E '(139|445)'
Task 4: Testing and Verification
Subtask 4.1: Test from Linux Client
Test Samba shares from the Linux command line.

# List available shares
smbclient -L localhost -U sambauser1

# Test public share access (anonymous)
smbclient //localhost/public -N

# Test private share access with authentication
smbclient //localhost/private -U sambauser1

# Test mounting a share
sudo mkdir -p /mnt/samba-test
sudo mount -t cifs //localhost/public /mnt/samba-test -o guest,uid=1000,gid=1000

# Test write access
echo "Test file from Linux" | sudo tee /mnt/samba-test/linux-test.txt

# Unmount the share
sudo umount /mnt/samba-test
Subtask 4.2: Create Test Files
Create test files in shares to verify functionality.

# Create test files in public share
sudo touch /srv/samba/public/public-test.txt
echo "This is a public test file" | sudo tee /srv/samba/public/public-test.txt

# Create test files in private share
sudo touch /srv/samba/private/private-test.txt
echo "This is a private test file" | sudo tee /srv/samba/private/private-test.txt
sudo chown root:sambausers /srv/samba/private/private-test.txt

# Create test files in team share
sudo touch /srv/samba/team/team-test.txt
echo "This is a team test file" | sudo tee /srv/samba/team/team-test.txt
sudo chown root:teamusers /srv/samba/team/team-test.txt
Subtask 4.3: Verify User Access Controls
Test that access controls are working properly.

# Test user access to their own directory
sudo -u sambauser1 smbclient //localhost/users -U sambauser1%password << 'EOF'
ls
put /etc/hostname sambauser1-test.txt
ls
quit
EOF

# Verify file was created
ls -la /srv/samba/users/sambauser1/
Task 5: Advanced Configuration and Monitoring
Subtask 5.1: Configure Logging
Set up detailed logging for monitoring and troubleshooting.

# Create log directory if it doesn't exist
sudo mkdir -p /var/log/samba

# Update logging configuration
sudo tee -a /etc/samba/smb.conf > /dev/null << 'EOF'

# Enhanced logging configuration
[global]
    log level = 2 auth:3 sam:3
    max log size = 5000
    log file = /var/log/samba/log.%m
    debug timestamp = yes
EOF

# Restart services to apply logging changes
sudo systemctl restart smb nmb
Subtask 5.2: Monitor Samba Activity
Learn how to monitor Samba connections and activity.

# View current Samba connections
sudo smbstatus

# View Samba processes
sudo smbstatus -p

# View locked files
sudo smbstatus -L

# Monitor log files
sudo tail -f /var/log/samba/log.smbd
Subtask 5.3: Performance Optimization
Apply performance optimizations for better throughput.

# Add performance tuning to configuration
sudo tee -a /etc/samba/smb.conf > /dev/null << 'EOF'

# Performance optimization
[global]
    # TCP settings
    socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
    
    # SMB protocol optimization
    server min protocol = SMB2
    server max protocol = SMB3
    
    # Async I/O
    aio read size = 16384
    aio write size = 16384
    
    # Oplocks for better performance
    oplocks = yes
    level2 oplocks = yes
EOF

# Restart services
sudo systemctl restart smb nmb
Troubleshooting Common Issues
Issue 1: Cannot Connect to Samba Share
Symptoms: Connection refused or timeout errors

Solutions:

# Check if services are running
sudo systemctl status smb nmb

# Check firewall settings
sudo firewall-cmd --list-services

# Check SELinux denials
sudo ausearch -m avc -ts recent | grep samba
Issue 2: Authentication Failures
Symptoms: Access denied or invalid credentials

Solutions:

# Verify user exists in Samba database
sudo pdbedit -L

# Reset user password
sudo smbpasswd sambauser1

# Check user group membership
groups sambauser1
Issue 3: Permission Denied Errors
Symptoms: Cannot write to shares or access files

Solutions:

# Check directory permissions
ls -la /srv/samba/

# Verify SELinux contexts
ls -Z /srv/samba/

# Check Samba configuration
sudo testparm -s
Security Best Practices
Subtask 6.1: Implement Security Hardening
Apply security best practices to your Samba configuration.

# Create a security-hardened configuration section
sudo tee -a /etc/samba/smb.conf > /dev/null << 'EOF'

# Security hardening
[global]
    # Restrict SMB versions
    server min protocol = SMB2
    server max protocol = SMB3
    
    # Disable unnecessary features
    disable netbios = yes
    smb ports = 445
    
    # Enhanced security
    ntlm auth = no
    restrict anonymous = 2
    
    # Logging security events
    log level = 1 auth:3 winbind:2
EOF

# Restart services
sudo systemctl restart smb nmb
Subtask 6.2: Regular Maintenance Tasks
Set up regular maintenance procedures.

# Create a maintenance script
sudo tee /usr/local/bin/samba-maintenance.sh > /dev/null << 'EOF'
#!/bin/bash
# Samba maintenance script

# Rotate logs
find /var/log/samba -name "*.log" -size +10M -exec logrotate {} \;

# Check configuration
testparm -s > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Samba configuration error detected!"
    exit 1
fi

# Backup user database
cp /var/lib/samba/private/passdb.tdb /var/lib/samba/private/passdb.tdb.backup

echo "Samba maintenance completed successfully"
EOF

# Make script executable
sudo chmod +x /usr/local/bin/samba-maintenance.sh

# Test the maintenance script
sudo /usr/local/bin/samba-maintenance.sh
Conclusion
In this comprehensive lab, you have successfully:

Installed and configured Samba server - You set up a complete Samba file sharing environment with proper service configuration and firewall rules.

Created multiple types of shares - You implemented public shares for anonymous access, private shares for authenticated users, team collaboration shares, and individual user directories.

Implemented robust user-based access control - You created system users, Samba users, and groups with appropriate permissions and access restrictions.

Applied security best practices - You configured SELinux contexts, implemented logging, and applied security hardening measures.

Tested cross-platform compatibility - You verified that shares work correctly with both Linux and Windows clients.

Why This Matters: Samba is a critical technology in enterprise environments where Windows and Linux systems need to coexist and share resources. The skills you've learned enable you to:

Provide seamless file sharing between different operating systems
Implement secure, role-based access to shared resources
Support business collaboration through centralized file storage
Maintain and troubleshoot file sharing services in production environments
These capabilities are essential for system administrators working in mixed-platform environments and are directly applicable to the Red Hat Certified Specialist in Services Management and Automation exam objectives.

The configuration you've created provides a solid foundation that can be scaled and customized for various organizational needs, from small workgroups to large enterprise deployments.
