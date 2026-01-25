Lab 10: Configuring NFSv4 File Sharing
Objectives
By the end of this lab, you will be able to:

Configure an NFSv4 server to export directories for network file sharing
Set up NFSv4 clients to mount and access exported directories
Implement proper security and permissions for NFS file sharing
Test file sharing functionality between NFS server and client systems
Troubleshoot common NFSv4 configuration issues
Understand the differences between NFSv3 and NFSv4 implementations
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux file systems and directory structures
Knowledge of Linux user and group management
Familiarity with systemd service management
Understanding of network concepts and IP addressing
Experience with command-line text editors (vi/vim or nano)
Basic knowledge of firewall configuration in Linux
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure networking.

Your lab environment includes:

Server Machine: CentOS/RHEL 8 or 9 system (nfs-server)
Client Machine: CentOS/RHEL 8 or 9 system (nfs-client)
Both machines are networked and can communicate with each other
Root access is provided on both systems
Task 1: Configure NFSv4 Server and Export Directories
Subtask 1.1: Install and Enable NFS Server Services
First, we'll install the necessary NFS server packages and enable the required services.

Step 1: Connect to your NFS server machine and install the NFS utilities:

# Update the system packages
sudo dnf update -y

# Install NFS server utilities
sudo dnf install -y nfs-utils
Step 2: Enable and start the NFS server services:

# Enable NFS server service to start at boot
sudo systemctl enable nfs-server

# Start the NFS server service
sudo systemctl start nfs-server

# Enable and start the RPC bind service (required for NFS)
sudo systemctl enable rpcbind
sudo systemctl start rpcbind

# Verify services are running
sudo systemctl status nfs-server
sudo systemctl status rpcbind
Subtask 1.2: Create Directories for NFS Export
Step 1: Create directories that will be shared via NFS:

# Create main NFS export directory
sudo mkdir -p /nfs/shared

# Create subdirectories for different purposes
sudo mkdir -p /nfs/shared/documents
sudo mkdir -p /nfs/shared/projects
sudo mkdir -p /nfs/shared/public

# Create a directory for user home directories
sudo mkdir -p /nfs/home
Step 2: Set appropriate ownership and permissions:

# Set ownership for shared directories
sudo chown -R nfsnobody:nfsnobody /nfs/shared

# Set permissions for shared directories
sudo chmod -R 755 /nfs/shared

# Set ownership for home directory export
sudo chown root:root /nfs/home
sudo chmod 755 /nfs/home
Step 3: Create sample content for testing:

# Create sample files in the shared directories
sudo touch /nfs/shared/documents/sample_document.txt
sudo touch /nfs/shared/projects/project_readme.txt
sudo touch /nfs/shared/public/public_info.txt

# Add content to sample files
echo "This is a sample document for NFS testing" | sudo tee /nfs/shared/documents/sample_document.txt
echo "Project information and guidelines" | sudo tee /nfs/shared/projects/project_readme.txt
echo "Public information accessible to all users" | sudo tee /nfs/shared/public/public_info.txt

# Set proper ownership for sample files
sudo chown -R nfsnobody:nfsnobody /nfs/shared/*
Subtask 1.3: Configure NFS Exports
Step 1: Create the NFS exports configuration file:

# Backup the original exports file if it exists
sudo cp /etc/exports /etc/exports.backup 2>/dev/null || true

# Create the exports configuration
sudo tee /etc/exports > /dev/null << 'EOF'
# NFS Exports Configuration
# Format: directory client(options)

# Shared directories - accessible by all clients in the network
/nfs/shared *(rw,sync,no_root_squash,no_subtree_check,fsid=0)
/nfs/shared/documents *(rw,sync,no_root_squash,no_subtree_check)
/nfs/shared/projects *(rw,sync,no_root_squash,no_subtree_check)
/nfs/shared/public *(ro,sync,no_root_squash,no_subtree_check)

# Home directories - read-write access
/nfs/home *(rw,sync,no_root_squash,no_subtree_check)
EOF
Step 2: Understand the export options:

rw: Read-write access
ro: Read-only access
sync: Write operations are committed to storage before replying
no_root_squash: Root user on client has root privileges on server
no_subtree_check: Disables subtree checking for better performance
fsid=0: Designates this as the NFSv4 root filesystem
Step 3: Apply the exports configuration:

# Export the configured directories
sudo exportfs -arv

# Verify the exports
sudo exportfs -v
Subtask 1.4: Configure Firewall for NFS
Step 1: Configure firewall rules to allow NFS traffic:

# Add NFS service to firewall
sudo firewall-cmd --permanent --add-service=nfs

# Add RPC bind service
sudo firewall-cmd --permanent --add-service=rpc-bind

# Add mountd service
sudo firewall-cmd --permanent --add-service=mountd

# Reload firewall configuration
sudo firewall-cmd --reload

# Verify firewall rules
sudo firewall-cmd --list-services
Step 2: Verify NFS server is listening on correct ports:

# Check NFS related processes and ports
sudo ss -tulpn | grep -E ':(111|2049|20048)'

# Show RPC services
sudo rpcinfo -p localhost
Task 2: Set Up NFS Clients and Mount Exported Directories
Subtask 2.1: Install NFS Client Utilities
Step 1: Connect to your NFS client machine and install client utilities:

# Update system packages
sudo dnf update -y

# Install NFS client utilities
sudo dnf install -y nfs-utils

# Enable and start rpcbind service
sudo systemctl enable rpcbind
sudo systemctl start rpcbind
Subtask 2.2: Create Mount Points
Step 1: Create directories where NFS exports will be mounted:

# Create mount points for NFS shares
sudo mkdir -p /mnt/nfs/shared
sudo mkdir -p /mnt/nfs/documents
sudo mkdir -p /mnt/nfs/projects
sudo mkdir -p /mnt/nfs/public
sudo mkdir -p /mnt/nfs/home

# Set appropriate permissions
sudo chmod 755 /mnt/nfs/*
Subtask 2.3: Test NFS Server Connectivity
Step 1: Verify you can see the NFS exports from the client:

# Replace 'nfs-server' with your server's IP address or hostname
# For this lab, use the internal IP of your server machine

# Show available NFS exports
sudo showmount -e nfs-server

# Alternative command to list exports
sudo rpcinfo -p nfs-server
Note: If you don't know your server's IP address, run ip addr show on the server machine to find it.

Subtask 2.4: Mount NFS Shares Manually
Step 1: Mount the NFS shares using NFSv4:

# Mount the main shared directory (NFSv4 root)
sudo mount -t nfs4 nfs-server:/ /mnt/nfs/shared

# Mount specific subdirectories
sudo mount -t nfs4 nfs-server:/documents /mnt/nfs/documents
sudo mount -t nfs4 nfs-server:/projects /mnt/nfs/projects
sudo mount -t nfs4 nfs-server:/public /mnt/nfs/public

# Mount home directory share
sudo mount -t nfs4 nfs-server:/home /mnt/nfs/home
Step 2: Verify the mounts:

# Check mounted filesystems
df -h | grep nfs

# Show detailed mount information
mount | grep nfs

# List contents of mounted directories
ls -la /mnt/nfs/shared/
ls -la /mnt/nfs/documents/
ls -la /mnt/nfs/projects/
ls -la /mnt/nfs/public/
Subtask 2.5: Configure Persistent Mounts
Step 1: Add NFS mounts to /etc/fstab for automatic mounting at boot:

# Backup the original fstab
sudo cp /etc/fstab /etc/fstab.backup

# Add NFS mount entries to fstab
sudo tee -a /etc/fstab > /dev/null << 'EOF'

# NFS Mounts
nfs-server:/     /mnt/nfs/shared     nfs4    defaults,_netdev    0 0
nfs-server:/documents /mnt/nfs/documents nfs4    defaults,_netdev    0 0
nfs-server:/projects  /mnt/nfs/projects  nfs4    defaults,_netdev    0 0
nfs-server:/public    /mnt/nfs/public    nfs4    ro,defaults,_netdev 0 0
nfs-server:/home      /mnt/nfs/home      nfs4    defaults,_netdev    0 0
EOF
Step 2: Test the fstab configuration:

# Unmount all NFS shares
sudo umount /mnt/nfs/shared
sudo umount /mnt/nfs/documents
sudo umount /mnt/nfs/projects
sudo umount /mnt/nfs/public
sudo umount /mnt/nfs/home

# Mount all filesystems from fstab
sudo mount -a

# Verify mounts are working
df -h | grep nfs
Task 3: Test File Sharing Between NFS Server and Client Systems
Subtask 3.1: Test Read Operations
Step 1: Test reading files from the NFS client:

# Read sample files from different shares
cat /mnt/nfs/documents/sample_document.txt
cat /mnt/nfs/projects/project_readme.txt
cat /mnt/nfs/public/public_info.txt

# List directory contents
ls -la /mnt/nfs/shared/
ls -la /mnt/nfs/documents/
ls -la /mnt/nfs/projects/
Subtask 3.2: Test Write Operations
Step 1: Test creating and modifying files from the NFS client:

# Create a new file in the documents directory
echo "This file was created from the NFS client" | sudo tee /mnt/nfs/documents/client_created.txt

# Create a file in the projects directory
echo "Project update from client system" | sudo tee /mnt/nfs/projects/client_update.txt

# Try to create a file in the read-only public directory (this should fail)
echo "This should fail" | sudo tee /mnt/nfs/public/readonly_test.txt 2>&1 || echo "Write operation failed as expected (read-only mount)"

# Create a directory in the shared space
sudo mkdir -p /mnt/nfs/shared/client_directory
echo "Directory created by client" | sudo tee /mnt/nfs/shared/client_directory/info.txt
Step 2: Verify the files were created on the server:

# On the NFS server, check if files created by client exist
ls -la /nfs/shared/documents/
ls -la /nfs/shared/projects/
ls -la /nfs/shared/client_directory/

# Read the files created by the client
cat /nfs/shared/documents/client_created.txt
cat /nfs/shared/projects/client_update.txt
Subtask 3.3: Test File Permissions and Ownership
Step 1: Test file ownership and permissions:

# On the client, create files with different permissions
sudo touch /mnt/nfs/shared/permission_test.txt
sudo chmod 644 /mnt/nfs/shared/permission_test.txt
sudo chown nfsnobody:nfsnobody /mnt/nfs/shared/permission_test.txt

# Check ownership and permissions
ls -la /mnt/nfs/shared/permission_test.txt
Step 2: Test user access (create a test user):

# On both server and client, create a test user
sudo useradd -u 1001 testuser
sudo passwd testuser

# On the client, test access as the test user
sudo su - testuser -c "echo 'User test file' > /mnt/nfs/shared/user_test.txt"
sudo su - testuser -c "ls -la /mnt/nfs/shared/user_test.txt"
Subtask 3.4: Performance and Stress Testing
Step 1: Test file transfer performance:

# Create a large test file on the client
sudo dd if=/dev/zero of=/mnt/nfs/shared/large_test_file bs=1M count=100

# Time the operation
time sudo cp /mnt/nfs/shared/large_test_file /mnt/nfs/shared/large_test_copy

# Check file sizes
ls -lh /mnt/nfs/shared/large_test*
Step 2: Test concurrent access:

# Create multiple files simultaneously
for i in {1..5}; do
    echo "Concurrent file $i" | sudo tee /mnt/nfs/shared/concurrent_$i.txt &
done
wait

# Verify all files were created
ls -la /mnt/nfs/shared/concurrent_*
Subtask 3.5: Test NFS Service Reliability
Step 1: Test behavior when NFS server is temporarily unavailable:

# On the server, temporarily stop the NFS service
sudo systemctl stop nfs-server

# On the client, try to access files (this will hang or timeout)
timeout 10s ls /mnt/nfs/shared/ || echo "Operation timed out as expected"

# On the server, restart the NFS service
sudo systemctl start nfs-server

# On the client, verify access is restored
ls /mnt/nfs/shared/
Troubleshooting Common Issues
Issue 1: Mount Operation Fails
Symptoms: Mount command returns "mount.nfs4: access denied" or "No such file or directory"

Solutions:

# Check if NFS server is running
sudo systemctl status nfs-server

# Verify exports are active
sudo exportfs -v

# Check firewall settings
sudo firewall-cmd --list-services

# Test network connectivity
ping nfs-server
telnet nfs-server 2049
Issue 2: Permission Denied Errors
Symptoms: Cannot read or write files on mounted NFS shares

Solutions:

# Check export options in /etc/exports
cat /etc/exports

# Verify directory permissions on server
ls -la /nfs/shared/

# Check if no_root_squash is needed
sudo exportfs -arv
Issue 3: Stale File Handle Errors
Symptoms: "Stale file handle" errors when accessing files

Solutions:

# Unmount and remount the NFS share
sudo umount /mnt/nfs/shared
sudo mount -t nfs4 nfs-server:/ /mnt/nfs/shared

# On server, re-export the directories
sudo exportfs -arv
Advanced Configuration Options
Subtask 4.1: Configure NFSv4 with Kerberos Security (Optional)
For enhanced security in production environments:

# Install Kerberos packages (on both server and client)
sudo dnf install -y krb5-libs krb5-workstation

# Configure NFS with sec=krb5 option
# This requires a Kerberos infrastructure setup
Subtask 4.2: Optimize NFS Performance
Step 1: Configure NFS with performance optimizations:

# Edit /etc/nfs.conf for performance tuning
sudo tee -a /etc/nfs.conf > /dev/null << 'EOF'

[nfsd]
threads=16
vers4.0=y
vers4.1=y
vers4.2=y

[mountd]
threads=16
EOF

# Restart NFS services
sudo systemctl restart nfs-server
Step 2: Mount with performance options:

# Unmount existing mounts
sudo umount /mnt/nfs/shared

# Mount with performance options
sudo mount -t nfs4 -o rsize=32768,wsize=32768,hard,intr nfs-server:/ /mnt/nfs/shared
Lab Validation and Testing
Final Verification Checklist
Step 1: Complete functionality test:

# Create verification script
sudo tee /tmp/nfs_test.sh > /dev/null << 'EOF'
#!/bin/bash

echo "=== NFS Functionality Test ==="

# Test 1: Check mounts
echo "1. Checking NFS mounts:"
df -h | grep nfs4

# Test 2: Test read access
echo "2. Testing read access:"
cat /mnt/nfs/documents/sample_document.txt

# Test 3: Test write access
echo "3. Testing write access:"
echo "Final test $(date)" | sudo tee /mnt/nfs/shared/final_test.txt
cat /mnt/nfs/shared/final_test.txt

# Test 4: Test directory creation
echo "4. Testing directory operations:"
sudo mkdir -p /mnt/nfs/shared/test_dir
ls -la /mnt/nfs/shared/ | grep test_dir

echo "=== All tests completed ==="
EOF

# Make script executable and run it
sudo chmod +x /tmp/nfs_test.sh
sudo /tmp/nfs_test.sh
Step 2: Performance verification:

# Test file transfer speed
time sudo dd if=/dev/zero of=/mnt/nfs/shared/speed_test bs=1M count=50

# Clean up test files
sudo rm -f /mnt/nfs/shared/speed_test
sudo rm -f /mnt/nfs/shared/large_test*
Conclusion
Congratulations! You have successfully completed Lab 10: Configuring NFSv4 File Sharing. In this comprehensive lab, you have accomplished the following:

Key Achievements
NFSv4 Server Configuration: You installed and configured a complete NFSv4 server, including:

Installing nfs-utils package and enabling required services
Creating and organizing export directories with proper permissions
Configuring /etc/exports with appropriate security options
Setting up firewall rules for NFS traffic
NFSv4 Client Setup: You successfully configured NFS clients to:

Install client utilities and dependencies
Create appropriate mount points
Mount NFS shares both manually and persistently
Configure automatic mounting through /etc/fstab
File Sharing Testing: You thoroughly tested the NFS implementation by:

Verifying read and write operations across the network
Testing file permissions and ownership handling
Performing performance and stress testing
Validating service reliability and recovery
Why This Matters
NFSv4 file sharing is a critical skill for system administrators and DevOps professionals because:

Centralized Storage: NFS enables centralized file storage and sharing across multiple systems, reducing storage costs and improving data management
Scalability: Organizations can easily scale storage resources and provide consistent access to files across their infrastructure
Collaboration: Teams can collaborate effectively by sharing common directories and resources
Backup and Recovery: Centralized storage simplifies backup strategies and disaster recovery planning
Performance: NFSv4 provides improved performance and security compared to earlier NFS versions
Real-World Applications
The skills you've learned apply directly to:

Enterprise File Servers: Setting up departmental file shares and home directories
Development Environments: Sharing code repositories and build artifacts across development teams
High-Performance Computing: Providing shared storage for compute clusters
Container Orchestration: Using NFS as persistent storage for Kubernetes and Docker environments
Backup Solutions: Implementing network-attached storage for backup systems
Next Steps
To further enhance your NFS expertise, consider exploring:

NFS Security: Implementing Kerberos authentication and encryption
Performance Tuning: Advanced optimization techniques for high-throughput environments
Monitoring: Setting up monitoring and alerting for NFS services
Integration: Combining NFS with other storage technologies like GlusterFS or Ceph
Automation: Using Ansible or other tools to automate NFS deployment and management
This lab has provided you with practical, hands-on experience that directly applies to the Red Hat Certified Specialist in Services Management and Automation exam and real-world system administration scenarios. The knowledge and skills gained here form a solid foundation for managing enterprise file sharing solutions.
