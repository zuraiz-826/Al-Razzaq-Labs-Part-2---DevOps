Lab 20: Configuring and Mounting NFS
Objectives
Configure and mount Network File System (NFS) shares for centralized data access.
Set up an NFS server and export directories.
Configure an NFS client to mount shared directories.
Test NFS mounts and ensure persistent mounting across reboots.
Prerequisites
Two Linux systems (one as NFS server, one as client) with root/sudo access.
Basic Linux command-line proficiency.
Network connectivity between server and client (verify with ping).
Open-source tools: nfs-utils (or nfs-kernel-server on Debian-based systems).
Task 1: Set Up NFS Server and Export Directories
Subtask 1.1: Install NFS Server Packages
On the NFS server, install the required packages:

# For RHEL/CentOS/Fedora:
sudo dnf install nfs-utils

# For Debian/Ubuntu:
sudo apt install nfs-kernel-server
Enable and start the NFS server:

sudo systemctl enable --now nfs-server
Expected Outcome: NFS service is active (systemctl status nfs-server shows "active (running)").

Subtask 1.2: Create and Export a Shared Directory
Create a directory to share (e.g., /shared):

sudo mkdir /shared
sudo chown nobody:nobody /shared  # Set ownership for anonymous access
sudo chmod 777 /shared  # Temporary permissions for testing
Edit /etc/exports to define the shared directory and permissions:

sudo nano /etc/exports
Add the following line (replace client_ip with the client’s IP or subnet):

/shared client_ip(rw,sync,no_root_squash)
rw: Read/write access.
sync: Write changes synchronously.
no_root_squash: Allow root access from the client.
Apply the exports:

sudo exportfs -arv
Expected Outcome: Verify exports with sudo exportfs -v. The /shared directory should be listed.

Troubleshooting Tip: If changes aren’t applied, restart NFS: sudo systemctl restart nfs-server.

Task 2: Configure NFS Client
Subtask 2.1: Install NFS Client Packages
On the client machine, install NFS utilities:
# RHEL/CentOS/Fedora:
sudo dnf install nfs-utils

# Debian/Ubuntu:
sudo apt install nfs-common
Subtask 2.2: Mount the NFS Share
Create a local mount point (e.g., /mnt/nfs):

sudo mkdir -p /mnt/nfs
Mount the NFS share temporarily:

sudo mount -t nfs server_ip:/shared /mnt/nfs
Replace server_ip with the NFS server’s IP.

Verify the mount:

df -hT | grep nfs
Expected Outcome: The NFS share appears in the output (e.g., server_ip:/shared).

Subtask 2.3: Test Read/Write Access
Create a test file:
sudo touch /mnt/nfs/testfile
ls -l /mnt/nfs
Expected Outcome: testfile appears in the directory.
Task 3: Persistent NFS Mounts
Subtask 3.1: Configure /etc/fstab for Auto-Mounting
Edit /etc/fstab on the client:

sudo nano /etc/fstab
Add this line (replace server_ip):

server_ip:/shared  /mnt/nfs  nfs  defaults  0  0
Test the fstab entry:

sudo mount -a
Expected Outcome: No errors; df -hT shows the NFS share mounted.

Subtask 3.2: Reboot and Verify Persistence
Reboot the client:
sudo reboot
After reboot, check the mount:
df -hT | grep nfs
Expected Outcome: The NFS share is automatically remounted.
Conclusion
Successfully configured an NFS server and exported a directory.
Mounted the NFS share on a client and tested read/write access.
Ensured persistent mounts across reboots via /etc/fstab.
Key Concepts:

NFS: Network File System for centralized storage.
exports: Server-side configuration for shared directories.
fstab: Client-side configuration for persistent mounts.
Next Steps: Explore NFS security (e.g., Kerberos, firewall rules) for production environments.

Troubleshooting Tips
"Access Denied": Check server exports (/etc/exports) and client IP permissions.
Mount Failures: Verify network connectivity (ping server_ip) and NFS service status.
Slow Performance: Use async in /etc/exports (trade-off for speed vs. data integrity).
