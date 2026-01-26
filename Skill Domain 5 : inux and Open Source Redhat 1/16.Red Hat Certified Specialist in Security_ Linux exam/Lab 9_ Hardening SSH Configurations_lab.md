Lab 9: Hardening SSH Configurations
Objectives
By the end of this lab, students will be able to:

Configure and implement SSH key-based authentication for secure remote access
Modify SSH daemon configuration to disable root login and enhance security settings
Test and validate SSH access restrictions and security configurations
Understand the importance of SSH hardening in enterprise security environments
Apply security best practices for remote system administration
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with text editors (nano, vim, or vi)
Knowledge of file permissions and ownership concepts
Understanding of SSH fundamentals and remote access concepts
Basic networking knowledge (IP addresses, ports)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or configure additional software.

Your lab environment includes:

Two CentOS/RHEL 8 or Ubuntu 20.04 LTS systems
System 1: server (SSH server)
System 2: client (SSH client)
Root and regular user access
Network connectivity between systems
Task 1: Set Up Key-Based Authentication for SSH
Subtask 1.1: Generate SSH Key Pairs
Step 1: Access your client system and generate an SSH key pair

# Switch to regular user (if not already)
su - student

# Generate RSA key pair with 4096-bit encryption
ssh-keygen -t rsa -b 4096 -C "student@client-system"
Step 2: Follow the interactive prompts

# When prompted for file location, press Enter for default
Generating public/private rsa key pair.
Enter file in which to save the key (/home/student/.ssh/id_rsa): [Press Enter]

# Set a strong passphrase for additional security
Enter passphrase (empty for no passphrase): [Enter a secure passphrase]
Enter same passphrase again: [Confirm passphrase]
Step 3: Verify key generation

# List the generated keys
ls -la ~/.ssh/

# View the public key content
cat ~/.ssh/id_rsa.pub
Subtask 1.2: Copy Public Key to SSH Server
Step 4: Use ssh-copy-id to transfer the public key

# Copy public key to the server system
# Replace 'server_ip' with your actual server IP address
ssh-copy-id student@server_ip

# Example:
ssh-copy-id student@192.168.1.100
Step 5: Alternative manual method (if ssh-copy-id is not available)

# Create .ssh directory on server (if it doesn't exist)
ssh student@server_ip "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

# Copy public key manually
cat ~/.ssh/id_rsa.pub | ssh student@server_ip "cat >> ~/.ssh/authorized_keys"

# Set proper permissions on server
ssh student@server_ip "chmod 600 ~/.ssh/authorized_keys"
Subtask 1.3: Test Key-Based Authentication
Step 6: Test SSH connection using key authentication

# Connect to server using key authentication
ssh student@server_ip

# You should be prompted for your key passphrase, not the user password
Step 7: Verify successful connection

# Once connected to server, check connection details
who am i
hostname
Task 2: Disable Root Login and Configure SSH Settings
Subtask 2.1: Backup Original SSH Configuration
Step 8: On the server system, backup the SSH configuration file

# Switch to root user
sudo su -

# Create backup of original sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Verify backup creation
ls -la /etc/ssh/sshd_config*
Subtask 2.2: Modify SSH Daemon Configuration
Step 9: Edit the SSH daemon configuration file

# Open sshd_config with your preferred editor
nano /etc/ssh/sshd_config
Step 10: Apply security hardening configurations

Find and modify the following settings in /etc/ssh/sshd_config:

# Disable root login
PermitRootLogin no

# Change default SSH port (optional but recommended)
Port 2222

# Disable password authentication (force key-based auth)
PasswordAuthentication no

# Disable empty passwords
PermitEmptyPasswords no

# Enable public key authentication
PubkeyAuthentication yes

# Limit login attempts
MaxAuthTries 3

# Set login grace time
LoginGraceTime 60

# Disable X11 forwarding if not needed
X11Forwarding no

# Disable unused authentication methods
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no

# Specify allowed users (replace with actual usernames)
AllowUsers student

# Set client alive settings to prevent hanging connections
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable protocol version 1 (if present)
Protocol 2
Step 11: Validate configuration syntax

# Test SSH configuration for syntax errors
sshd -t

# If no errors, you should see no output
# If there are errors, fix them before proceeding
Subtask 2.3: Restart SSH Service
Step 12: Restart the SSH daemon to apply changes

# For systemd-based systems (CentOS 8, RHEL 8, Ubuntu 20.04)
systemctl restart sshd

# Verify service status
systemctl status sshd

# For older systems using init.d
# service ssh restart
Step 13: Verify SSH service is listening on new port

# Check if SSH is listening on the configured port
netstat -tlnp | grep :2222

# Alternative using ss command
ss -tlnp | grep :2222
Task 3: Test SSH Access Restrictions
Subtask 3.1: Test Key-Based Authentication
Step 14: From the client system, test SSH connection with new settings

# Test connection using new port and key authentication
ssh -p 2222 student@server_ip

# You should be able to connect using your SSH key
Subtask 3.2: Test Root Login Restriction
Step 15: Attempt to login as root (should fail)

# Try to connect as root - this should be denied
ssh -p 2222 root@server_ip

# Expected output: Permission denied (publickey)
Subtask 3.3: Test Password Authentication Restriction
Step 16: Test password authentication (should fail)

# Remove or rename your private key temporarily
mv ~/.ssh/id_rsa ~/.ssh/id_rsa.temp

# Try to connect - should fail without key
ssh -p 2222 student@server_ip

# Restore your private key
mv ~/.ssh/id_rsa.temp ~/.ssh/id_rsa
Subtask 3.4: Test User Access Restrictions
Step 17: Create a test user and verify access restrictions

# On server system, create a test user
sudo useradd testuser
sudo passwd testuser

# Try to connect as testuser from client (should fail)
ssh -p 2222 testuser@server_ip

# Expected: Permission denied - user not in AllowUsers list
Subtask 3.5: Monitor SSH Connection Attempts
Step 18: Monitor SSH logs for connection attempts

# On server system, monitor SSH logs
tail -f /var/log/secure

# For Ubuntu systems:
tail -f /var/log/auth.log

# Look for authentication attempts and failures
Advanced Configuration Options
Subtask 3.6: Configure SSH Banner and Additional Security
Step 19: Create a login banner

# Create banner file
cat > /etc/ssh/banner << EOF
***************************************************************************
                    AUTHORIZED ACCESS ONLY
***************************************************************************
This system is for authorized users only. All activities are monitored
and logged. Unauthorized access is prohibited and will be prosecuted.
***************************************************************************
EOF
Step 20: Enable banner in SSH configuration

# Add banner configuration to sshd_config
echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd
Subtask 3.7: Configure SSH Key Management
Step 21: Set up proper key management practices

# On client system, set proper permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# On server system, verify authorized_keys permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
Troubleshooting Common Issues
Issue 1: SSH Connection Refused
Problem: Connection refused when trying to connect

Solution:

# Check if SSH service is running
systemctl status sshd

# Check if firewall is blocking the port
firewall-cmd --list-ports
firewall-cmd --add-port=2222/tcp --permanent
firewall-cmd --reload

# For Ubuntu with ufw:
ufw allow 2222/tcp
Issue 2: Permission Denied with Valid Key
Problem: Permission denied even with correct SSH key

Solution:

# Check SSH logs for detailed error messages
tail -20 /var/log/secure

# Verify file permissions
ls -la ~/.ssh/
ls -la ~/.ssh/authorized_keys

# Check SELinux context (if applicable)
restorecon -R ~/.ssh/
Issue 3: SSH Configuration Syntax Errors
Problem: SSH service fails to start after configuration changes

Solution:

# Test configuration syntax
sshd -t

# Restore backup if needed
cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config

# Restart service
systemctl restart sshd
Verification and Testing Checklist
Complete the following verification steps:

 SSH key pair generated successfully
 Public key copied to server
 Key-based authentication working
 Root login disabled and tested
 Password authentication disabled
 SSH service running on custom port
 Unauthorized users cannot connect
 SSH logs showing security events
 Banner displayed on connection
 File permissions set correctly
Security Best Practices Summary
Key Security Configurations Applied:
Authentication Security:

Disabled password authentication
Implemented key-based authentication
Disabled root login
Limited user access with AllowUsers
Network Security:

Changed default SSH port
Configured connection timeouts
Limited authentication attempts
Monitoring and Logging:

Enabled comprehensive logging
Configured login banners
Set up connection monitoring
Access Control:

Proper file permissions
User access restrictions
Protocol version enforcement
Conclusion
In this lab, you have successfully implemented comprehensive SSH hardening configurations that significantly improve the security posture of your Linux systems. You have learned to:

Secure Authentication: Replaced password-based authentication with more secure SSH key-based authentication, eliminating the risk of password-based attacks
Access Control: Disabled root login and implemented user access restrictions, following the principle of least privilege
Network Security: Modified default SSH settings including port changes and connection parameters to reduce attack surface
Monitoring: Configured logging and banners to track access attempts and warn unauthorized users
These SSH hardening techniques are essential skills for system administrators and security professionals. The configurations you've implemented align with industry security standards and are commonly required in enterprise environments. These practices help protect against common attack vectors including brute force attacks, unauthorized access attempts, and privilege escalation.

The skills demonstrated in this lab are directly applicable to the Red Hat Certified Specialist in Security Linux exam and real-world security implementations. Remember to regularly review and update your SSH configurations as security requirements evolve, and always test changes in a controlled environment before applying them to production systems.

Key Takeaway: SSH hardening is a fundamental security practice that provides the first line of defense for remote system access. The multi-layered approach you've implemented creates a robust security framework that significantly reduces the risk of unauthorized system access.
