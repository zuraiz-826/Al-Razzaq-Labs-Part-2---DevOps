Lab 7: Configuring and Securing SSH
Objectives
By the end of this lab, students will be able to:

• Install and configure OpenSSH server on a Linux system • Understand SSH service configuration files and security settings • Test SSH connections both locally and remotely • Configure key-based authentication for enhanced security • Implement SSH security best practices • Troubleshoot common SSH connection issues • Manage SSH keys and user access

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Knowledge of file permissions and ownership concepts • Familiarity with text editors like nano or vim • Understanding of network concepts (IP addresses, ports) • Basic knowledge of user management in Linux

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machine or install additional software.

Your lab environment includes: • Two CentOS/RHEL 8 or 9 virtual machines • Root and regular user access • Network connectivity between machines • All necessary packages available for installation

Task 1: Install and Configure OpenSSH Server
Subtask 1.1: Check Current SSH Status
First, let's examine if SSH is already installed and running on your system.

Check if OpenSSH server is installed:
rpm -qa | grep openssh-server
Check the status of SSH service:
systemctl status sshd
If SSH is not installed, install it:
sudo dnf install openssh-server -y
Subtask 1.2: Start and Enable SSH Service
Start the SSH service:
sudo systemctl start sshd
Enable SSH to start automatically at boot:
sudo systemctl enable sshd
Verify the service is running:
sudo systemctl status sshd
Subtask 1.3: Configure SSH Server Settings
Create a backup of the original SSH configuration file:
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
Open the SSH configuration file for editing:
sudo nano /etc/ssh/sshd_config
Modify the following settings for basic security (uncomment and change as needed):
# Change default port (optional but recommended)
Port 22

# Disable root login for security
PermitRootLogin no

# Enable public key authentication
PubkeyAuthentication yes

# Disable password authentication (we'll enable this later)
PasswordAuthentication yes

# Disable empty passwords
PermitEmptyPasswords no

# Set maximum authentication attempts
MaxAuthTries 3

# Set client alive interval to prevent timeouts
ClientAliveInterval 300
ClientAliveCountMax 2
Save and exit the file (Ctrl+X, then Y, then Enter in nano)

Test the configuration file for syntax errors:

sudo sshd -t
If no errors, restart the SSH service to apply changes:
sudo systemctl restart sshd
Subtask 1.4: Configure Firewall for SSH
Check current firewall status:
sudo firewall-cmd --state
Allow SSH through the firewall:
sudo firewall-cmd --permanent --add-service=ssh
If you changed the SSH port, allow the custom port:
sudo firewall-cmd --permanent --add-port=22/tcp
Reload firewall rules:
sudo firewall-cmd --reload
Verify SSH service is allowed:
sudo firewall-cmd --list-services
Task 2: Test SSH Connection Locally and Remotely
Subtask 2.1: Test Local SSH Connection
Create a test user for SSH connections:
sudo useradd testuser
sudo passwd testuser
Test SSH connection to localhost:
ssh testuser@localhost
Accept the host key when prompted and enter the password

Verify you're connected via SSH:

whoami
hostname
Exit the SSH session:
exit
Subtask 2.2: Test Remote SSH Connection
Find your machine's IP address:
ip addr show
From another terminal or machine, test remote SSH connection:
ssh testuser@YOUR_IP_ADDRESS
Replace YOUR_IP_ADDRESS with the actual IP address from step 1.

Test SSH connection with verbose output for troubleshooting:
ssh -v testuser@YOUR_IP_ADDRESS
Subtask 2.3: Monitor SSH Connections
View current SSH connections:
sudo ss -tuln | grep :22
Check SSH logs for connection attempts:
sudo journalctl -u sshd -f
View authentication logs:
sudo tail -f /var/log/secure
Task 3: Set Up Key-Based Authentication for SSH
Subtask 3.1: Generate SSH Key Pair
Generate an SSH key pair on the client machine:
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
When prompted, press Enter to accept the default file location

Enter a secure passphrase when prompted (optional but recommended)

View the generated keys:

ls -la ~/.ssh/
Display the public key:
cat ~/.ssh/id_rsa.pub
Subtask 3.2: Copy Public Key to Remote Server
Copy the public key to the remote server using ssh-copy-id:
ssh-copy-id testuser@YOUR_IP_ADDRESS
Alternatively, manually copy the key:
cat ~/.ssh/id_rsa.pub | ssh testuser@YOUR_IP_ADDRESS "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
Set proper permissions on the remote server:
ssh testuser@YOUR_IP_ADDRESS "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
Subtask 3.3: Test Key-Based Authentication
Test SSH connection using key authentication:
ssh testuser@YOUR_IP_ADDRESS
You should now connect without entering a password (unless you set a passphrase)

Verify the connection method in SSH logs:

sudo journalctl -u sshd | grep "Accepted publickey"
Subtask 3.4: Disable Password Authentication
Edit the SSH configuration file:
sudo nano /etc/ssh/sshd_config
Change the following setting:
PasswordAuthentication no
Test configuration and restart SSH:
sudo sshd -t
sudo systemctl restart sshd
Test that password authentication is disabled by trying to connect from a machine without the key
Subtask 3.5: Advanced SSH Security Configuration
Edit SSH configuration for additional security:
sudo nano /etc/ssh/sshd_config
Add or modify these security settings:
# Disable protocol 1
Protocol 2

# Limit user access
AllowUsers testuser

# Disable X11 forwarding if not needed
X11Forwarding no

# Disable agent forwarding if not needed
AllowAgentForwarding no

# Disable TCP forwarding if not needed
AllowTcpForwarding no

# Use strong ciphers
Ciphers aes256-ctr,aes192-ctr,aes128-ctr

# Use strong MACs
MACs hmac-sha2-256,hmac-sha2-512

# Set login grace time
LoginGraceTime 30
Restart SSH service:
sudo systemctl restart sshd
Troubleshooting Common Issues
Connection Refused Errors
Check if SSH service is running:
sudo systemctl status sshd
Verify firewall settings:
sudo firewall-cmd --list-services
Check SSH configuration syntax:
sudo sshd -t
Permission Denied Errors
Check SSH key permissions:
ls -la ~/.ssh/
Verify authorized_keys file permissions:
ls -la ~/.ssh/authorized_keys
Check SSH logs for detailed error messages:
sudo journalctl -u sshd -n 20
Key Authentication Not Working
Verify public key is correctly copied:
ssh testuser@YOUR_IP_ADDRESS "cat ~/.ssh/authorized_keys"
Check SSH client configuration:
ssh -v testuser@YOUR_IP_ADDRESS
Ensure SELinux contexts are correct:
sudo restorecon -R ~/.ssh/
Verification Commands
Use these commands to verify your SSH configuration:

# Check SSH service status
sudo systemctl status sshd

# Verify SSH configuration
sudo sshd -t

# Check listening ports
sudo ss -tuln | grep :22

# View SSH logs
sudo journalctl -u sshd -n 10

# Test SSH connection
ssh -T testuser@localhost
Conclusion
In this lab, you have successfully:

• Installed and configured OpenSSH server with security-focused settings • Tested SSH connections both locally and remotely to ensure proper functionality • Implemented key-based authentication to enhance security beyond password-based access • Applied SSH security best practices including disabling root login and password authentication • Configured firewall rules to allow SSH traffic while maintaining system security

Why This Matters: SSH is the primary method for secure remote administration of Linux systems. Understanding how to properly configure and secure SSH is essential for system administrators, as it protects against unauthorized access while enabling legitimate remote management. Key-based authentication provides stronger security than passwords and is required in many enterprise environments.

The skills learned in this lab are fundamental for the Red Hat Certified System Administrator certification and are directly applicable in real-world scenarios where secure remote access is critical for system management and maintenance.

Next Steps: Practice these configurations in different scenarios, explore SSH tunneling and port forwarding, and consider implementing additional security measures like fail2ban for intrusion prevention.
