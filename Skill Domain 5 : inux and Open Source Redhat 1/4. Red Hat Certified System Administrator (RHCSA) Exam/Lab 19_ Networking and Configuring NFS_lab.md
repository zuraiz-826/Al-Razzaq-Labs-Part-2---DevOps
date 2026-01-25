Lab 19: Networking and Configuring NFS
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of Network File System (NFS) and its use cases
Configure and manage an NFS server on a Linux system
Set up NFS client systems to mount remote file shares
Configure firewall rules to allow NFS traffic securely
Troubleshoot common NFS connectivity and permission issues
Implement basic security practices for NFS deployments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Knowledge of file permissions and ownership concepts
Familiarity with systemd service management
Understanding of basic networking concepts (IP addresses, ports)
Experience with text editors like vi/vim or nano
Basic knowledge of firewall concepts
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking setups.

Your lab environment includes:

Server Machine: CentOS/RHEL 8 or 9 system (nfs-server)
Client Machine: CentOS/RHEL 8 or 9 system (nfs-client)
Both machines are networked and can communicate with each other
Root access is provided on both systems
Task 1: Configure an NFS Server
Subtask 1.1: Install NFS Server Packages
First, we need to install the necessary NFS server packages on our server machine.

Connect to the NFS Server machine and switch to root user:
sudo su -
Update the system packages:
dnf update -y
Install NFS server packages:
dnf install -y nfs-utils rpcbind
Verify the installation:
rpm -qa | grep nfs-utils
rpm -qa | grep rpcbind
Subtask 1.2: Create Directories for NFS Shares
We'll create directories that will be shared via NFS.

Create shared directories:
mkdir -p /nfs/shared
mkdir -p /nfs/public
mkdir -p /nfs/private
Set appropriate permissions:
# For shared directory - read/write for everyone
chmod 755 /nfs/shared
chown nobody:nobody /nfs/shared

# For public directory - read-only for clients
chmod 755 /nfs/public
chown nobody:nobody /nfs/public

# For private directory - restricted access
chmod 750 /nfs/private
chown root:root /nfs/private
Create some test files:
echo "This is a shared file" > /nfs/shared/shared_file.txt
echo "This is a public file" > /nfs/public/public_file.txt
echo "This is a private file" > /nfs/private/private_file.txt
Subtask 1.3: Configure NFS Exports
The /etc/exports file defines which directories are shared and how they can be accessed.

Create the exports configuration file:
cp /etc/exports /etc/exports.backup
Edit the exports file:
vi /etc/exports
Add the following export entries:
# NFS Export Configuration
# Format: directory client_ip(options)

# Shared directory - read/write access
/nfs/shared     *(rw,sync,no_root_squash,no_subtree_check)

# Public directory - read-only access
/nfs/public     *(ro,sync,root_squash,no_subtree_check)

# Private directory - specific client only
/nfs/private    192.168.1.0/24(rw,sync,root_squash,no_subtree_check)
Export Options Explained:

rw: Read-write access
ro: Read-only access
sync: Write changes to disk before responding
no_root_squash: Don't map root user to anonymous user
root_squash: Map root user to anonymous user (security)
no_subtree_check: Disable subtree checking for better performance
Validate the exports file syntax:
exportfs -a
exportfs -v
Subtask 1.4: Start and Enable NFS Services
Start the required services:
systemctl start rpcbind
systemctl start nfs-server
systemctl start rpc-statd
systemctl start nfs-idmapd
Enable services to start at boot:
systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable rpc-statd
systemctl enable nfs-idmapd
Check service status:
systemctl status nfs-server
systemctl status rpcbind
Verify NFS is listening on correct ports:
rpcinfo -p localhost
Task 2: Mount NFS Shares on Client Systems
Subtask 2.1: Prepare the NFS Client
Connect to the NFS Client machine and switch to root user:
sudo su -
Install NFS client packages:
dnf install -y nfs-utils
Start and enable required services:
systemctl start rpcbind
systemctl enable rpcbind
systemctl status rpcbind
Subtask 2.2: Discover Available NFS Shares
Check what shares are available from the server (replace SERVER_IP with actual server IP):
# First, find the server IP
SERVER_IP=$(hostname -I | awk '{print $1}' | sed 's/\.[0-9]*$/.1/')
echo "Server IP: $SERVER_IP"

# Show available exports
showmount -e $SERVER_IP
Test NFS connectivity:
rpcinfo -p $SERVER_IP
Subtask 2.3: Create Mount Points
Create directories for mounting NFS shares:
mkdir -p /mnt/nfs-shared
mkdir -p /mnt/nfs-public
mkdir -p /mnt/nfs-private
Set appropriate permissions:
chmod 755 /mnt/nfs-shared
chmod 755 /mnt/nfs-public
chmod 755 /mnt/nfs-private
Subtask 2.4: Mount NFS Shares Manually
Mount the shared directory:
mount -t nfs $SERVER_IP:/nfs/shared /mnt/nfs-shared
Mount the public directory:
mount -t nfs $SERVER_IP:/nfs/public /mnt/nfs-public
Mount the private directory:
mount -t nfs $SERVER_IP:/nfs/private /mnt/nfs-private
Verify the mounts:
df -h | grep nfs
mount | grep nfs
Test the mounted shares:
# Test shared directory (should work)
ls -la /mnt/nfs-shared/
cat /mnt/nfs-shared/shared_file.txt

# Test public directory (should work)
ls -la /mnt/nfs-public/
cat /mnt/nfs-public/public_file.txt

# Test private directory (should work if network allows)
ls -la /mnt/nfs-private/
cat /mnt/nfs-private/private_file.txt
Subtask 2.5: Configure Persistent NFS Mounts
To make NFS mounts persistent across reboots, we need to add them to /etc/fstab.

Backup the current fstab:
cp /etc/fstab /etc/fstab.backup
Add NFS entries to fstab:
vi /etc/fstab
Add the following lines at the end of the file:
# NFS Mounts
192.168.1.100:/nfs/shared    /mnt/nfs-shared    nfs    defaults,_netdev    0 0
192.168.1.100:/nfs/public    /mnt/nfs-public    nfs    defaults,_netdev,ro    0 0
192.168.1.100:/nfs/private   /mnt/nfs-private   nfs    defaults,_netdev    0 0
Note: Replace 192.168.1.100 with your actual server IP address.

fstab Options Explained:

defaults: Use default mount options
_netdev: Wait for network before mounting
ro: Mount as read-only
0 0: No dump, no fsck
Test the fstab entries:
# Unmount current mounts
umount /mnt/nfs-shared
umount /mnt/nfs-public
umount /mnt/nfs-private

# Mount using fstab
mount -a

# Verify mounts
df -h | grep nfs
Task 3: Configure Firewall Rules to Allow NFS Traffic
Subtask 3.1: Configure Firewall on NFS Server
NFS uses multiple ports and services. We need to configure the firewall to allow NFS traffic.

Check current firewall status on the server:
firewall-cmd --state
firewall-cmd --list-all
Add NFS service to firewall (this opens multiple required ports):
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
For more granular control, add specific ports:
# NFS daemon
firewall-cmd --permanent --add-port=2049/tcp
firewall-cmd --permanent --add-port=2049/udp

# RPC portmapper
firewall-cmd --permanent --add-port=111/tcp
firewall-cmd --permanent --add-port=111/udp

# RPC mountd (you may need to check actual port)
firewall-cmd --permanent --add-port=20048/tcp
firewall-cmd --permanent --add-port=20048/udp
Reload firewall configuration:
firewall-cmd --reload
Verify firewall rules:
firewall-cmd --list-all
firewall-cmd --list-services
firewall-cmd --list-ports
Subtask 3.2: Configure Firewall on NFS Client
Check firewall status on client:
firewall-cmd --state
firewall-cmd --list-all
Add NFS client services (if needed):
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
Subtask 3.3: Test NFS Connectivity Through Firewall
From the client, test NFS connectivity:
# Test RPC services
rpcinfo -p $SERVER_IP

# Test NFS mount
showmount -e $SERVER_IP
If there are connectivity issues, check specific ports:
# Test port 2049 (NFS)
telnet $SERVER_IP 2049

# Test port 111 (RPC)
telnet $SERVER_IP 111
Subtask 3.4: Advanced Firewall Configuration
For production environments, you might want to restrict NFS access to specific networks.

Create a rich rule to allow NFS only from specific network:
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" service name="nfs" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" service name="rpc-bind" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" service name="mountd" accept'
Remove the general NFS service if using rich rules:
firewall-cmd --permanent --remove-service=nfs
firewall-cmd --permanent --remove-service=rpc-bind
firewall-cmd --permanent --remove-service=mountd
Reload and verify:
firewall-cmd --reload
firewall-cmd --list-rich-rules
Testing and Verification
Comprehensive NFS Testing
Test file operations on mounted shares:
# Test write operations on shared directory
echo "Test from client" > /mnt/nfs-shared/client_test.txt
ls -la /mnt/nfs-shared/

# Test read operations on public directory
cat /mnt/nfs-public/public_file.txt

# Try to write to read-only public directory (should fail)
echo "This should fail" > /mnt/nfs-public/test.txt
Test permissions and ownership:
# Check file ownership
ls -la /mnt/nfs-shared/
ls -la /mnt/nfs-public/

# Test with different users
useradd testuser
su - testuser
echo "User test" > /mnt/nfs-shared/user_test.txt
exit
Test network interruption recovery:
# On server, temporarily stop NFS
systemctl stop nfs-server

# On client, try to access files (should hang or fail)
ls /mnt/nfs-shared/

# On server, restart NFS
systemctl start nfs-server

# On client, access should resume
ls /mnt/nfs-shared/
Troubleshooting Common Issues
Issue 1: Mount Operation Fails
Symptoms: mount.nfs: access denied by server while mounting

Solutions:

# Check exports on server
exportfs -v

# Verify client IP is allowed
showmount -e SERVER_IP

# Check firewall rules
firewall-cmd --list-all
Issue 2: Permission Denied Errors
Symptoms: Cannot read or write files on mounted NFS share

Solutions:

# Check file permissions on server
ls -la /nfs/shared/

# Verify export options
cat /etc/exports

# Check SELinux context (if enabled)
ls -Z /nfs/shared/
Issue 3: Stale File Handle
Symptoms: Stale file handle error when accessing files

Solutions:

# Unmount and remount the share
umount /mnt/nfs-shared
mount -t nfs SERVER_IP:/nfs/shared /mnt/nfs-shared

# Or force unmount if needed
umount -f /mnt/nfs-shared
Issue 4: Services Not Starting
Symptoms: NFS services fail to start

Solutions:

# Check service status and logs
systemctl status nfs-server
journalctl -u nfs-server

# Verify RPC services are running
systemctl status rpcbind
rpcinfo -p
Security Best Practices
Server-Side Security
Use specific IP ranges in exports:
# Instead of * (all hosts), use specific networks
/nfs/shared 192.168.1.0/24(rw,sync,root_squash)
Enable root_squash for security:
# Maps root user to nobody user
/nfs/shared *(rw,sync,root_squash)
Use all_squash for maximum security:
# Maps all users to nobody user
/nfs/public *(ro,sync,all_squash)
Network Security
Use NFSv4 with Kerberos (advanced):
# Enable secure NFS
echo "Domain = example.com" >> /etc/idmapd.conf
systemctl restart nfs-idmapd
Monitor NFS connections:
# Check active NFS connections
ss -tuln | grep :2049
netstat -an | grep :2049
Conclusion
In this lab, you have successfully:

Configured a complete NFS server with multiple shared directories and different access permissions
Set up NFS client systems to mount and access remote file shares both manually and persistently
Implemented proper firewall rules to secure NFS traffic while maintaining functionality
Learned troubleshooting techniques for common NFS issues and connectivity problems
Why This Matters: NFS is a fundamental technology in enterprise Linux environments, enabling centralized file storage and sharing across multiple systems. This skill is essential for system administrators managing distributed computing environments, shared development resources, and centralized data storage solutions.

Key Takeaways:

NFS provides transparent file sharing across networks
Proper security configuration is crucial for production deployments
Firewall configuration must accommodate multiple NFS-related services and ports
Understanding export options and mount parameters is essential for optimal performance and security
Next Steps: Consider exploring advanced NFS features like NFSv4 with Kerberos authentication, NFS over encrypted connections, and integration with LDAP for user management in enterprise environments.

This hands-on experience prepares you for real-world scenarios where network file sharing is required, and provides the foundation for the Red Hat Certified System Administrator (RHCSA) exam objectives related to network services and file sharing.
