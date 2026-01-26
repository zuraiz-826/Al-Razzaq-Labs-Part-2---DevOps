Lab 2: Installing Red Hat Ceph Storage Cluster
Lab Objectives
By the end of this lab, you will be able to:

• Install and configure a basic Red Hat Ceph storage cluster using open-source tools • Set up and configure the MON (Monitor) service for cluster coordination • Deploy and manage OSD (Object Storage Daemon) nodes for data storage • Configure and operate MGR (Manager) services for cluster management • Understand the fundamental architecture of a Ceph distributed storage system • Verify cluster health and basic functionality • Troubleshoot common installation and configuration issues

Prerequisites
Before starting this lab, you should have:

• Basic Linux administration skills including command-line navigation, file editing, and service management • Understanding of storage concepts such as block devices, filesystems, and network storage • Familiarity with SSH for remote server management • Knowledge of basic networking concepts including IP addressing and firewall configuration • Experience with package management using yum or dnf • Understanding of systemd services and service management

Required Knowledge Areas:
Linux command line operations
Basic networking and firewall concepts
Storage device management
Service configuration and management
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab and you'll have access to pre-configured virtual machines. No need to build your own VMs or worry about hardware requirements.

Provided Infrastructure:
3 CentOS/RHEL 8 virtual machines with root access
Pre-configured networking between all nodes
Additional storage devices attached to each VM for OSD deployment
Internet connectivity for package installation
Lab Architecture Overview
In this lab, we'll create a minimal Ceph cluster with the following components:

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ceph-node1    │    │   ceph-node2    │    │   ceph-node3    │
│                 │    │                 │    │                 │
│ MON + MGR + OSD │    │     OSD         │    │     OSD         │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
Task 1: Prepare the Environment and Install Ceph
Subtask 1.1: Verify System Requirements
First, let's check our system configuration and prepare all nodes.

Step 1: Connect to all three nodes and verify system information:

# Run on all nodes
hostnamectl
cat /etc/os-release
free -h
df -h
Step 2: Set up proper hostnames and hosts file:

# On ceph-node1
sudo hostnamectl set-hostname ceph-node1

# On ceph-node2
sudo hostnamectl set-hostname ceph-node2

# On ceph-node3
sudo hostnamectl set-hostname ceph-node3
Step 3: Configure the hosts file on all nodes:

# Run on all nodes - replace with your actual IP addresses
sudo tee -a /etc/hosts << EOF
192.168.1.10 ceph-node1
192.168.1.11 ceph-node2
192.168.1.12 ceph-node3
EOF
Subtask 1.2: Configure Firewall and SELinux
Step 1: Configure firewall rules for Ceph communication:

# Run on all nodes
sudo firewall-cmd --permanent --add-service=ceph-mon
sudo firewall-cmd --permanent --add-service=ceph
sudo firewall-cmd --permanent --add-port=6789/tcp
sudo firewall-cmd --permanent --add-port=6800-7300/tcp
sudo firewall-cmd --reload
Step 2: Configure SELinux (set to permissive for lab purposes):

# Run on all nodes
sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
Subtask 1.3: Install Ceph Packages
Step 1: Add the Ceph repository:

# Run on all nodes
sudo dnf install -y centos-release-ceph-pacific
sudo dnf update -y
Step 2: Install Ceph packages:

# Run on all nodes
sudo dnf install -y ceph ceph-radosgw python3-ceph-argparse python3-ceph-common
Step 3: Verify installation:

# Check Ceph version
ceph --version
Task 2: Set up the MON (Monitor) Service
The Monitor service maintains the cluster map and provides authentication services.

Subtask 2.1: Generate Cluster Configuration
Step 1: Create the Ceph configuration directory and generate cluster UUID:

# Run on ceph-node1
sudo mkdir -p /etc/ceph
cd /etc/ceph

# Generate cluster UUID
uuidgen | sudo tee cluster.uuid
CLUSTER_UUID=$(cat cluster.uuid)
echo "Cluster UUID: $CLUSTER_UUID"
Step 2: Create the initial Ceph configuration file:

# Run on ceph-node1
sudo tee /etc/ceph/ceph.conf << EOF
[global]
fsid = $(cat cluster.uuid)
mon initial members = ceph-node1
mon host = 192.168.1.10
public network = 192.168.1.0/24
cluster network = 192.168.1.0/24
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
osd pool default size = 2
osd pool default min size = 1
osd pool default pg num = 64
osd pool default pgp num = 64
osd crush chooseleaf type = 1

[mon]
mon allow pool delete = true

[mgr]
mgr modules = dashboard restful

[osd]
osd mkfs type = xfs
osd mkfs options xfs = -f -i size=2048
osd mount options xfs = noatime,largeio,inode64,swalloc
EOF
Subtask 2.2: Create Monitor Keyring
Step 1: Generate the monitor keyring:

# Run on ceph-node1
sudo ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
Step 2: Generate the admin keyring:

# Run on ceph-node1
sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
Step 3: Generate the bootstrap OSD keyring:

# Run on ceph-node1
sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'
Step 4: Add the client.admin key to the monitor keyring:

# Run on ceph-node1
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
Subtask 2.3: Initialize and Start Monitor
Step 1: Generate the monitor map:

# Run on ceph-node1
monmaptool --create --add ceph-node1 192.168.1.10 --fsid $(cat /etc/ceph/cluster.uuid) /tmp/monmap
Step 2: Create the monitor data directory:

# Run on ceph-node1
sudo mkdir -p /var/lib/ceph/mon/ceph-ceph-node1
sudo chown ceph:ceph /var/lib/ceph/mon/ceph-ceph-node1
Step 3: Populate the monitor daemon:

# Run on ceph-node1
sudo -u ceph ceph-mon --mkfs -i ceph-node1 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
Step 4: Create systemd service file and start the monitor:

# Run on ceph-node1
sudo systemctl enable ceph-mon@ceph-node1
sudo systemctl start ceph-mon@ceph-node1
sudo systemctl status ceph-mon@ceph-node1
Step 5: Verify monitor is running:

# Run on ceph-node1
sudo ceph -s
Task 3: Deploy OSD (Object Storage Daemon) and MGR (Manager) Nodes
Subtask 3.1: Set up Manager Service
The Manager service provides additional monitoring and management capabilities.

Step 1: Create MGR data directory:

# Run on ceph-node1
sudo mkdir -p /var/lib/ceph/mgr/ceph-ceph-node1
sudo chown ceph:ceph /var/lib/ceph/mgr/ceph-ceph-node1
Step 2: Create MGR authentication key:

# Run on ceph-node1
sudo ceph auth get-or-create mgr.ceph-node1 mon 'allow profile mgr' osd 'allow *' mds 'allow *' > /tmp/mgr.ceph-node1.keyring
sudo cp /tmp/mgr.ceph-node1.keyring /var/lib/ceph/mgr/ceph-ceph-node1/keyring
sudo chown ceph:ceph /var/lib/ceph/mgr/ceph-ceph-node1/keyring
Step 3: Start the Manager service:

# Run on ceph-node1
sudo systemctl enable ceph-mgr@ceph-node1
sudo systemctl start ceph-mgr@ceph-node1
sudo systemctl status ceph-mgr@ceph-node1
Subtask 3.2: Prepare Storage Devices for OSDs
Step 1: Identify available storage devices on all nodes:

# Run on all nodes
lsblk
sudo fdisk -l
Step 2: Prepare the storage device (assuming /dev/sdb is available):

# Run on all nodes - CAUTION: This will destroy data on /dev/sdb
sudo wipefs -a /dev/sdb
sudo sgdisk --zap-all /dev/sdb
Subtask 3.3: Create OSDs on All Nodes
Step 1: Copy configuration files to all nodes:

# Run on ceph-node1 to copy files to other nodes
sudo scp /etc/ceph/ceph.conf root@ceph-node2:/etc/ceph/
sudo scp /etc/ceph/ceph.conf root@ceph-node3:/etc/ceph/
sudo scp /etc/ceph/ceph.client.admin.keyring root@ceph-node2:/etc/ceph/
sudo scp /etc/ceph/ceph.client.admin.keyring root@ceph-node3:/etc/ceph/
sudo scp /var/lib/ceph/bootstrap-osd/ceph.keyring root@ceph-node2:/var/lib/ceph/bootstrap-osd/
sudo scp /var/lib/ceph/bootstrap-osd/ceph.keyring root@ceph-node3:/var/lib/ceph/bootstrap-osd/
Step 2: Create bootstrap-osd directory on other nodes:

# Run on ceph-node2 and ceph-node3
sudo mkdir -p /var/lib/ceph/bootstrap-osd
sudo chown ceph:ceph /var/lib/ceph/bootstrap-osd
Step 3: Create OSDs using ceph-volume:

# Run on ceph-node1
sudo ceph-volume lvm create --data /dev/sdb

# Run on ceph-node2
sudo ceph-volume lvm create --data /dev/sdb

# Run on ceph-node3
sudo ceph-volume lvm create --data /dev/sdb
Step 4: Verify OSD creation and activation:

# Run on all nodes
sudo ceph-volume lvm list
sudo systemctl list-units | grep ceph-osd
Subtask 3.4: Verify Cluster Status
Step 1: Check overall cluster health:

# Run on ceph-node1
sudo ceph -s
sudo ceph health detail
Step 2: Verify all services are running:

# Run on ceph-node1
sudo ceph mon stat
sudo ceph osd stat
sudo ceph mgr stat
Step 3: Check OSD tree:

# Run on ceph-node1
sudo ceph osd tree
Step 4: Verify cluster map:

# Run on ceph-node1
sudo ceph osd dump
sudo ceph mon dump
Task 4: Final Configuration and Testing
Subtask 4.1: Enable Ceph Dashboard (Optional)
Step 1: Enable the dashboard module:

# Run on ceph-node1
sudo ceph mgr module enable dashboard
sudo ceph dashboard create-self-signed-cert
Step 2: Create dashboard admin user:

# Run on ceph-node1
echo "admin123" | sudo ceph dashboard ac-user-create admin -i - administrator
Step 3: Check dashboard access:

# Run on ceph-node1
sudo ceph mgr services
Subtask 4.2: Create Test Pool and Verify Functionality
Step 1: Create a test pool:

# Run on ceph-node1
sudo ceph osd pool create testpool 32 32
sudo ceph osd pool application enable testpool rbd
Step 2: Test basic operations:

# Run on ceph-node1
# Create a test object
echo "Hello Ceph Storage!" | sudo rados -p testpool put test-object -

# Retrieve the test object
sudo rados -p testpool get test-object -

# List objects in pool
sudo rados -p testpool ls
Step 3: Monitor cluster during operations:

# Run on ceph-node1
sudo ceph -w
# Press Ctrl+C to exit watch mode
Troubleshooting Common Issues
Issue 1: Monitor Won't Start
Symptoms: Monitor service fails to start or cluster shows no monitors

Solution:

# Check monitor logs
sudo journalctl -u ceph-mon@ceph-node1 -f

# Verify permissions
sudo chown -R ceph:ceph /var/lib/ceph/mon/

# Check configuration
sudo ceph-conf --show-config-value mon_host
Issue 2: OSDs Not Coming Up
Symptoms: OSDs show as down or out in cluster status

Solution:

# Check OSD logs
sudo journalctl -u ceph-osd@* -f

# Verify disk preparation
sudo ceph-volume lvm list

# Check OSD authentication
sudo ceph auth list | grep osd
Issue 3: Cluster Health Warnings
Symptoms: Cluster shows HEALTH_WARN status

Solution:

# Get detailed health information
sudo ceph health detail

# Common fixes for warnings
sudo ceph config set mon auth_allow_insecure_global_id_reclaim false
sudo ceph osd pool set testpool size 2
sudo ceph osd pool set testpool min_size 1
Issue 4: Network Connectivity Problems
Symptoms: Nodes cannot communicate or form cluster

Solution:

# Test network connectivity
ping ceph-node2
ping ceph-node3

# Check firewall rules
sudo firewall-cmd --list-all

# Verify port accessibility
sudo netstat -tlnp | grep :6789
Lab Validation Checklist
Before completing the lab, verify the following:

 All three nodes are properly configured with hostnames and networking
 Ceph packages are installed on all nodes
 Monitor service is running on ceph-node1
 Manager service is running on ceph-node1
 OSDs are created and active on all three nodes
 Cluster status shows HEALTH_OK
 Test pool can be created and objects stored/retrieved
 All services start automatically on boot
Verification Commands:

# Final cluster status check
sudo ceph -s
sudo ceph osd tree
sudo ceph df
sudo systemctl status ceph-mon@ceph-node1
sudo systemctl status ceph-mgr@ceph-node1
Conclusion
Congratulations! You have successfully completed the installation and configuration of a Red Hat Ceph Storage cluster. In this lab, you accomplished several critical tasks:

What You Achieved:
• Built a functional Ceph cluster with three nodes providing distributed storage capabilities • Configured the Monitor service which maintains cluster state and provides authentication • Deployed Object Storage Daemons on all nodes to provide actual data storage capacity • Set up the Manager service for enhanced cluster monitoring and management features • Verified cluster functionality through testing and health checks

Why This Matters:
Enterprise Storage Solution: Ceph provides enterprise-grade distributed storage that can scale from small clusters to massive deployments supporting petabytes of data.

High Availability: The distributed architecture ensures data remains available even when individual nodes fail, making it ideal for mission-critical applications.

Cost-Effective: As an open-source solution, Ceph provides enterprise storage capabilities without expensive proprietary licensing costs.

OpenStack Integration: This knowledge directly applies to Red Hat OpenStack deployments where Ceph serves as the backend storage for compute instances, images, and block storage.

Career Advancement: Understanding Ceph storage administration is valuable for cloud architects, storage administrators, and DevOps engineers working with modern infrastructure.

Next Steps:
With this foundation, you're prepared to explore advanced Ceph features such as:

RADOS Block Device (RBD) configuration
CephFS filesystem deployment
RADOS Gateway for object storage
Cluster expansion and scaling
Performance tuning and optimization
Integration with container orchestration platforms
This lab has provided you with practical, hands-on experience that directly applies to real-world storage infrastructure challenges and prepares you for advanced Red Hat Ceph Storage certifications.
