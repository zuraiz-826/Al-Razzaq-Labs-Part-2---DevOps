Lab 5: SSH into Remote Systems
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of SSH (Secure Shell) protocol and its importance in secure remote access
Generate and configure SSH key pairs for passwordless authentication
Connect to remote Linux systems using SSH with various authentication methods
Transfer files securely between local and remote systems using scp command
Synchronize files and directories efficiently using rsync command
Implement SSH security best practices for production environments
Troubleshoot common SSH connection issues and authentication problems
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line interface
Familiarity with file permissions and ownership concepts
Knowledge of basic networking concepts (IP addresses, ports)
Understanding of public-key cryptography fundamentals
Experience with text editors like nano or vim
Completion of previous labs covering basic Linux administration
Lab Environment Setup
Good News! Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or configure complex networking.

Your lab environment includes:

Server Machine: CentOS/RHEL 8 or Ubuntu 20.04 LTS (acting as remote server)
Client Machine: CentOS/RHEL 8 or Ubuntu 20.04 LTS (your workstation)
Pre-installed SSH server and client packages
Network connectivity between machines already configured
Task 1: Set Up SSH Keys for Secure Login
Subtask 1.1: Understanding SSH Authentication Methods
SSH supports multiple authentication methods:

Password Authentication: Traditional username/password login
Public Key Authentication: Uses cryptographic key pairs (more secure)
Certificate-based Authentication: Uses SSH certificates (enterprise environments)
We'll focus on public key authentication as it's more secure and commonly used in production environments.

Subtask 1.2: Generate SSH Key Pair on Client Machine
Open terminal on your client machine and check if SSH keys already exist:
ls -la ~/.ssh/
Generate a new SSH key pair using RSA algorithm with 4096-bit key size:
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
Follow the interactive prompts:

Press Enter to accept default file location (/home/username/.ssh/id_rsa)
Enter a strong passphrase when prompted (recommended for security)
Confirm the passphrase
Verify key generation:

ls -la ~/.ssh/
cat ~/.ssh/id_rsa.pub
Expected output should show:

id_rsa (private key - keep this secure)
id_rsa.pub (public key - safe to share)
Subtask 1.3: Configure SSH Key Permissions
Set correct permissions for SSH directory and keys:
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
Verify permissions:
ls -la ~/.ssh/
Subtask 1.4: Copy Public Key to Remote Server
Method 1: Using ssh-copy-id (Recommended)

Copy your public key to the remote server:
ssh-copy-id username@remote-server-ip
Replace username with your actual username and remote-server-ip with the server's IP address.

Enter the remote user's password when prompted.
Method 2: Manual Copy (Alternative)

Display your public key:
cat ~/.ssh/id_rsa.pub
SSH into remote server using password:
ssh username@remote-server-ip
Create .ssh directory on remote server (if it doesn't exist):
mkdir -p ~/.ssh
chmod 700 ~/.ssh
Add your public key to authorized_keys file:
echo "your-public-key-content" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
Exit from remote server:
exit
Subtask 1.5: Test SSH Key Authentication
Test passwordless login:
ssh username@remote-server-ip
You should now be able to log in without entering a password (only SSH key passphrase if you set one).

Exit from remote server:
exit
Task 2: Use SSH Command to Log into Remote Server
Subtask 2.1: Basic SSH Connection
Connect to remote server using default settings:
ssh username@remote-server-ip
Connect using specific port (if SSH runs on non-standard port):
ssh -p 2222 username@remote-server-ip
Connect with verbose output (useful for troubleshooting):
ssh -v username@remote-server-ip
Subtask 2.2: SSH Configuration File
Create SSH client configuration file:
nano ~/.ssh/config
Add server configuration:
Host myserver
    HostName remote-server-ip
    User username
    Port 22
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
Set correct permissions:
chmod 600 ~/.ssh/config
Connect using alias:
ssh myserver
Subtask 2.3: SSH Agent for Key Management
Start SSH agent:
eval $(ssh-agent -s)
Add your private key to SSH agent:
ssh-add ~/.ssh/id_rsa
List loaded keys:
ssh-add -l
Connect to server (no passphrase prompt if key is loaded):
ssh myserver
Subtask 2.4: Remote Command Execution
Execute single command on remote server:
ssh myserver "uptime"
Execute multiple commands:
ssh myserver "uptime; df -h; free -m"
Run interactive command with pseudo-terminal:
ssh -t myserver "sudo systemctl status sshd"
Task 3: Practice Remote File Management with SCP and Rsync
Subtask 3.1: File Transfer Using SCP
SCP (Secure Copy Protocol) is used for secure file transfer over SSH.

Copy file from local to remote server:
echo "Hello from local machine" > test-file.txt
scp test-file.txt myserver:/home/username/
Copy file from remote to local:
scp myserver:/etc/hostname ./remote-hostname.txt
Copy directory recursively:
mkdir local-directory
echo "File 1" > local-directory/file1.txt
echo "File 2" > local-directory/file2.txt
scp -r local-directory/ myserver:/home/username/
Copy with preserved permissions and timestamps:
scp -p test-file.txt myserver:/home/username/preserved-file.txt
Copy with compression (useful for large files):
scp -C large-file.txt myserver:/home/username/
Subtask 3.2: Advanced SCP Operations
Copy between two remote servers (through local machine):
scp server1:/path/to/file server2:/path/to/destination
Copy with specific SSH key:
scp -i ~/.ssh/specific-key file.txt myserver:/home/username/
Copy with progress indicator:
scp -v file.txt myserver:/home/username/
Subtask 3.3: File Synchronization Using Rsync
Rsync is more efficient than SCP for synchronizing files and directories.

Basic rsync syntax (local to remote):
mkdir sync-test
echo "Original content" > sync-test/file1.txt
echo "Another file" > sync-test/file2.txt
rsync -avz sync-test/ myserver:/home/username/sync-destination/
Flags explanation:

-a: Archive mode (preserves permissions, timestamps, etc.)
-v: Verbose output
-z: Compress data during transfer
Sync from remote to local:
rsync -avz myserver:/home/username/sync-destination/ ./local-sync/
Dry run (preview changes without actually copying):
rsync -avz --dry-run sync-test/ myserver:/home/username/sync-destination/
Subtask 3.4: Advanced Rsync Features
Exclude specific files or patterns:
rsync -avz --exclude='*.log' --exclude='temp/' sync-test/ myserver:/home/username/sync-destination/
Delete files on destination that don't exist on source:
rsync -avz --delete sync-test/ myserver:/home/username/sync-destination/
Show progress during transfer:
rsync -avz --progress sync-test/ myserver:/home/username/sync-destination/
Limit bandwidth usage:
rsync -avz --bwlimit=1000 sync-test/ myserver:/home/username/sync-destination/
Resume interrupted transfers:
rsync -avz --partial --progress sync-test/ myserver:/home/username/sync-destination/
Subtask 3.5: Practical Rsync Scenarios
Backup script example:
#!/bin/bash
# Create backup script
cat > backup-script.sh << 'EOF'
#!/bin/bash

# Variables
SOURCE_DIR="/home/username/important-data"
BACKUP_SERVER="myserver"
BACKUP_DIR="/home/username/backups/$(date +%Y-%m-%d)"
LOG_FILE="/var/log/backup.log"

# Create source directory with sample data
mkdir -p $SOURCE_DIR
echo "Important document 1" > $SOURCE_DIR/doc1.txt
echo "Important document 2" > $SOURCE_DIR/doc2.txt

# Perform backup
echo "Starting backup at $(date)" >> $LOG_FILE
rsync -avz --delete $SOURCE_DIR/ $BACKUP_SERVER:$BACKUP_DIR/
echo "Backup completed at $(date)" >> $LOG_FILE
EOF

chmod +x backup-script.sh
./backup-script.sh
Verify backup:
ssh myserver "ls -la /home/username/backups/"
Security Best Practices
SSH Server Hardening
Connect to remote server and edit SSH configuration:
ssh myserver
sudo nano /etc/ssh/sshd_config
Recommended security settings:
# Disable root login
PermitRootLogin no

# Disable password authentication (use keys only)
PasswordAuthentication no

# Change default port
Port 2222

# Limit user access
AllowUsers username

# Disable empty passwords
PermitEmptyPasswords no

# Set login grace time
LoginGraceTime 60

# Limit authentication attempts
MaxAuthTries 3
Restart SSH service:
sudo systemctl restart sshd
SSH Client Security
Create secure SSH client configuration:
nano ~/.ssh/config
# Global settings
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    HashKnownHosts yes
    VisualHostKey yes
    
Host myserver
    HostName remote-server-ip
    User username
    Port 2222
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes
Troubleshooting Common Issues
Connection Problems
Permission denied (publickey):
# Check key permissions
ls -la ~/.ssh/
# Ensure correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
Connection timeout:
# Test connectivity
ping remote-server-ip
# Check if SSH port is open
telnet remote-server-ip 22
Host key verification failed:
# Remove old host key
ssh-keygen -R remote-server-ip
# Or edit known_hosts file
nano ~/.ssh/known_hosts
Authentication Issues
Debug SSH connection:
ssh -vvv myserver
Check SSH agent:
ssh-add -l
# If no identities, add key
ssh-add ~/.ssh/id_rsa
Verify authorized_keys on server:
ssh myserver "cat ~/.ssh/authorized_keys"
Performance Optimization
SSH Connection Multiplexing
Configure connection sharing:
nano ~/.ssh/config
Host myserver
    HostName remote-server-ip
    User username
    ControlMaster auto
    ControlPath ~/.ssh/control-%r@%h:%p
    ControlPersist 10m
Test multiplexing:
# First connection establishes master
ssh myserver
# Subsequent connections use existing master
ssh myserver "uptime"
Rsync Optimization
Use compression for slow networks:
rsync -avz --compress-level=9 source/ destination/
Parallel transfers (using GNU parallel):
find source/ -type f | parallel -j4 rsync -avz {} myserver:destination/
Lab Validation
Verification Checklist
SSH Key Authentication:

 Generated SSH key pair successfully
 Copied public key to remote server
 Can login without password
SSH Connection:

 Can connect using SSH command
 SSH config file works correctly
 Can execute remote commands
File Transfer:

 Successfully used SCP for file transfer
 Completed directory synchronization with rsync
 Tested various rsync options
Security:

 Applied SSH security best practices
 Configured proper file permissions
 Tested connection troubleshooting
Final Test Script
#!/bin/bash
# Comprehensive test script

echo "=== SSH Lab Validation ==="

# Test 1: SSH Key Authentication
echo "Testing SSH key authentication..."
ssh -o PasswordAuthentication=no myserver "echo 'SSH key auth: SUCCESS'" || echo "SSH key auth: FAILED"

# Test 2: File Transfer with SCP
echo "Testing SCP file transfer..."
echo "Test content" > test-scp.txt
scp test-scp.txt myserver:/tmp/ && echo "SCP transfer: SUCCESS" || echo "SCP transfer: FAILED"

# Test 3: Directory Sync with Rsync
echo "Testing Rsync synchronization..."
mkdir -p test-rsync
echo "Rsync test" > test-rsync/test.txt
rsync -avz test-rsync/ myserver:/tmp/rsync-test/ && echo "Rsync sync: SUCCESS" || echo "Rsync sync: FAILED"

# Test 4: Remote Command Execution
echo "Testing remote command execution..."
UPTIME=$(ssh myserver "uptime")
if [ $? -eq 0 ]; then
    echo "Remote command: SUCCESS"
    echo "Server uptime: $UPTIME"
else
    echo "Remote command: FAILED"
fi

# Cleanup
rm -f test-scp.txt
rm -rf test-rsync/

echo "=== Validation Complete ==="
Conclusion
Congratulations! You have successfully completed Lab 5: SSH into Remote Systems. In this comprehensive lab, you have accomplished the following:

Key Achievements:

Mastered SSH Authentication: You learned to generate and configure SSH key pairs, providing a secure foundation for passwordless authentication that is essential in production environments.

Established Secure Remote Connections: You gained hands-on experience connecting to remote systems using various SSH methods, including basic connections, configuration files, and SSH agents.

Implemented File Transfer Solutions: You practiced both SCP and rsync for different file transfer scenarios, understanding when to use each tool based on specific requirements.

Applied Security Best Practices: You implemented SSH hardening techniques and learned troubleshooting methods that are crucial for maintaining secure remote access in enterprise environments.

Why This Matters:

SSH is the backbone of secure remote administration in Linux environments. The skills you've developed are directly applicable to:

System Administration: Managing multiple servers remotely
DevOps Practices: Automating deployments and configuration management
Cloud Computing: Accessing and managing cloud-based infrastructure
Security Compliance: Meeting industry standards for secure remote access
Real-World Applications:

These SSH skills are fundamental for the Red Hat Certified Specialist in Ansible Network Automation exam and are used daily by:

System administrators managing server farms
DevOps engineers deploying applications
Security professionals implementing access controls
Network administrators configuring remote devices
Next Steps:

With these SSH fundamentals mastered, you're well-prepared to advance to more complex topics such as:

SSH tunneling and port forwarding
Ansible automation using SSH
Advanced security configurations
Integration with identity management systems
The secure remote access skills you've developed in this lab form the foundation for advanced Linux administration and automation tasks that are essential in modern IT infrastructure management.
