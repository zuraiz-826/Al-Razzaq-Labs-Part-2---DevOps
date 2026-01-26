Lab 3: Centralized Authentication Setup (IdM)
Objectives
By the end of this lab, students will be able to:

Install and configure a Red Hat Identity Management (IdM) server using FreeIPA
Register and configure client systems to authenticate against the IdM server
Test Kerberos authentication functionality
Verify and troubleshoot SSSD (System Security Services Daemon) configurations
Understand the benefits of centralized authentication in enterprise environments
Configure DNS settings for proper IdM operation
Manage users and groups through the IdM web interface
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line operations
Knowledge of DNS concepts and configuration
Understanding of user and group management in Linux
Basic networking concepts (IP addressing, hostnames)
Experience with text editors like vi/vim or nano
Required Knowledge Areas:
Linux file permissions and ownership
Service management using systemctl
Basic firewall configuration
Understanding of authentication concepts
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab and you'll have access to:

Server Machine: CentOS/RHEL 8 or 9 system (idm-server.example.com)
Client Machine: CentOS/RHEL 8 or 9 system (client1.example.com)
Pre-configured network connectivity between machines
Root access to both systems
No need to build your own VMs! Everything is ready for you to begin immediately.

Task 1: Install and Configure IdM Server
Subtask 1.1: Prepare the Server Environment
First, let's prepare our server system for IdM installation.

Step 1: Set the Hostname
# Set the fully qualified domain name
hostnamectl set-hostname idm-server.example.com

# Verify the hostname
hostnamectl status
Step 2: Configure Network Settings
# Check current IP address
ip addr show

# Edit the hosts file to ensure proper name resolution
vi /etc/hosts

# Add the following line (replace with your actual IP):
192.168.1.10 idm-server.example.com idm-server
Step 3: Update the System
# Update all packages to latest versions
dnf update -y

# Reboot if kernel was updated
reboot
Subtask 1.2: Install IdM Server Packages
Step 1: Install FreeIPA Server
# Install the IdM server package
dnf install -y ipa-server ipa-server-dns

# Verify installation
rpm -qa | grep ipa-server
Step 2: Configure Firewall Rules
# Enable and start firewalld
systemctl enable --now firewalld

# Add IdM services to firewall
firewall-cmd --permanent --add-service=freeipa-ldap
firewall-cmd --permanent --add-service=freeipa-ldaps
firewall-cmd --permanent --add-service=dns
firewall-cmd --permanent --add-service=ntp
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=kerberos
firewall-cmd --permanent --add-service=kpasswd

# Reload firewall configuration
firewall-cmd --reload

# Verify firewall rules
firewall-cmd --list-all
Subtask 1.3: Configure the IdM Server
Step 1: Run the IdM Server Installation
# Install and configure IdM server with integrated DNS
ipa-server-install --setup-dns --auto-forwarders

# You will be prompted for the following information:
# - Server host name: idm-server.example.com (should be auto-detected)
# - Domain name: example.com
# - Realm name: EXAMPLE.COM (usually uppercase of domain)
# - Directory Manager password: (create a strong password)
# - IPA admin password: (create a strong password)
# - Continue to configure the system with these values? [no]: yes
Important Notes:

The installation process takes 10-15 minutes
Write down the passwords you create - you'll need them later
The installer will configure DNS, Kerberos, LDAP, and web services automatically
Step 2: Verify IdM Server Installation
# Check IdM services status
ipactl status

# Verify Kerberos authentication
kinit admin
klist

# Test DNS resolution
nslookup idm-server.example.com
Step 3: Access the Web Interface
# Get the server's IP address
ip addr show | grep inet

# Open a web browser and navigate to:
# https://idm-server.example.com
# or
# https://[SERVER_IP_ADDRESS]

# Login with:
# Username: admin
# Password: [the IPA admin password you created]
Subtask 1.4: Create Test Users and Groups
Step 1: Create Users via Command Line
# Create a test user
ipa user-add testuser1 --first=Test --last=User1 --email=testuser1@example.com --password

# Create another test user
ipa user-add testuser2 --first=Test --last=User2 --email=testuser2@example.com --password

# List all users
ipa user-find
Step 2: Create Groups
# Create a test group
ipa group-add testgroup --desc="Test Group for Lab"

# Add users to the group
ipa group-add-member testgroup --users=testuser1,testuser2

# Verify group membership
ipa group-show testgroup
Task 2: Register and Configure Client Systems
Subtask 2.1: Prepare the Client System
Step 1: Configure Client Hostname
# Set hostname on client machine
hostnamectl set-hostname client1.example.com

# Update hosts file
vi /etc/hosts

# Add entries for both server and client:
192.168.1.10 idm-server.example.com idm-server
192.168.1.11 client1.example.com client1
Step 2: Configure DNS Settings
# Edit network configuration to use IdM server as DNS
vi /etc/resolv.conf

# Add the following line:
nameserver 192.168.1.10
search example.com

# Or configure via NetworkManager:
nmcli con mod "System eth0" ipv4.dns "192.168.1.10"
nmcli con mod "System eth0" ipv4.dns-search "example.com"
nmcli con up "System eth0"
Step 3: Test DNS Resolution
# Test DNS resolution
nslookup idm-server.example.com
nslookup client1.example.com

# Test reverse DNS
nslookup 192.168.1.10
Subtask 2.2: Install IdM Client
Step 1: Install Client Packages
# Update system
dnf update -y

# Install IdM client packages
dnf install -y ipa-client

# Verify installation
rpm -qa | grep ipa-client
Step 2: Join Client to IdM Domain
# Join the client to the IdM domain
ipa-client-install --domain=example.com --server=idm-server.example.com --mkhomedir

# You will be prompted for:
# - Continue to configure the system with these values? [no]: yes
# - User authorized to enroll computers: admin
# - Password for admin@EXAMPLE.COM: [enter IPA admin password]
Step 3: Verify Client Registration
# Check client status
ipa-client-install --unattended --domain=example.com --server=idm-server.example.com --mkhomedir

# Verify SSSD is running
systemctl status sssd

# Test Kerberos authentication
kinit admin@EXAMPLE.COM
klist
Subtask 2.3: Configure SSSD
Step 1: Review SSSD Configuration
# View SSSD configuration file
cat /etc/sssd/sssd.conf

# The file should contain sections like:
# [domain/example.com]
# [sssd]
# [nss]
# [pam]
Step 2: Verify SSSD Services
# Check SSSD status
systemctl status sssd

# Restart SSSD if needed
systemctl restart sssd

# Enable SSSD to start at boot
systemctl enable sssd
Step 3: Test Name Service Switch
# Test user lookup
getent passwd testuser1

# Test group lookup
getent group testgroup

# Test with id command
id testuser1
Task 3: Test Kerberos Authentication and Verify SSSD Configurations
Subtask 3.1: Test Kerberos Authentication
Step 1: Test Admin Authentication
# Clear any existing tickets
kdestroy

# Authenticate as admin
kinit admin@EXAMPLE.COM

# List current tickets
klist

# Verify ticket details
klist -v
Step 2: Test User Authentication
# Test authentication for test user
kinit testuser1@EXAMPLE.COM

# Check tickets
klist

# Test SSH key-based authentication
ssh testuser1@client1.example.com
Step 3: Test Password Authentication
# Test local login (if GUI available)
# Or test su command
su - testuser1

# Verify home directory creation
ls -la /home/testuser1
Subtask 3.2: Verify SSSD Configuration
Step 1: Check SSSD Logs
# View SSSD logs
tail -f /var/log/sssd/sssd.log

# View domain-specific logs
tail -f /var/log/sssd/sssd_example.com.log

# Check for any errors
grep -i error /var/log/sssd/*.log
Step 2: Test SSSD Cache
# Clear SSSD cache
sss_cache -E

# Restart SSSD
systemctl restart sssd

# Test user lookup again
getent passwd testuser1
Step 3: Verify PAM Configuration
# Check PAM configuration for system-auth
cat /etc/pam.d/system-auth

# Look for lines containing:
# pam_sss.so
# pam_krb5.so (if present)

# Check password-auth
cat /etc/pam.d/password-auth
Subtask 3.3: Advanced Testing
Step 1: Test Group Membership
# Check group membership
groups testuser1

# Test group-based access
# Create a test directory
mkdir /tmp/testgroup_access
chgrp testgroup /tmp/testgroup_access
chmod 770 /tmp/testgroup_access

# Test access as testuser1
su - testuser1
cd /tmp/testgroup_access
touch test_file
ls -la
exit
Step 2: Test Password Changes
# Test password change for user
passwd testuser1

# Or use IPA command
ipa passwd testuser1
Step 3: Test Service Principal Names
# List service principals
ipa service-find

# Add a service principal (example)
ipa service-add HTTP/client1.example.com@EXAMPLE.COM
Troubleshooting Common Issues
DNS Resolution Problems
# If DNS isn't working properly:
systemctl restart named
systemctl status named

# Check DNS configuration
cat /etc/named.conf
SSSD Not Working
# If SSSD isn't working:
systemctl stop sssd
rm -rf /var/lib/sss/db/*
systemctl start sssd
Kerberos Authentication Failures
# Check time synchronization
timedatectl status

# Synchronize time if needed
chrony sources -v
Client Registration Issues
# If client registration fails:
ipa-client-install --uninstall
# Then re-run the installation command
Verification Commands Summary
Use these commands to verify your setup is working correctly:

# On IdM Server:
ipactl status
ipa user-find
ipa group-find

# On Client:
systemctl status sssd
getent passwd testuser1
kinit testuser1@EXAMPLE.COM
klist
Conclusion
Congratulations! You have successfully completed the Centralized Authentication Setup lab. Here's what you accomplished:

Key Achievements:
Installed and configured a FreeIPA server - You now have a fully functional Identity Management server that provides centralized authentication, authorization, and account information
Successfully registered client systems - Your client machines can now authenticate users against the central IdM server
Verified Kerberos authentication - Users can now obtain Kerberos tickets for secure, single sign-on access across the network
Configured and tested SSSD - The System Security Services Daemon is properly configured to handle authentication requests
Why This Matters:
In enterprise environments, centralized authentication is crucial for:

Security: Centralized password policies and account management
Efficiency: Single sign-on capabilities reduce password fatigue
Management: Administrators can manage users and groups from one location
Compliance: Centralized logging and auditing capabilities
Scalability: Easy to add new systems and users to the authentication domain
Real-World Applications:
The skills you've learned in this lab are directly applicable to:

Enterprise Linux environments
Red Hat Certified Specialist in Security: Linux certification
System administrator roles requiring identity management
Organizations implementing centralized authentication solutions
Next Steps:
Consider exploring advanced IdM features such as:

Certificate management
Host-based access controls
Sudo rule management
Trust relationships with Active Directory
Two-factor authentication setup
You now have the foundational knowledge to implement and manage centralized authentication systems in production environments!
