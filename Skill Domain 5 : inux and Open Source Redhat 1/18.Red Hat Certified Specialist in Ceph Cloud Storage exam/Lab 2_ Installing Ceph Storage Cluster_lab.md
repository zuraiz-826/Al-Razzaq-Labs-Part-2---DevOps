Lab 2: Installing Ceph Storage Cluster
Objectives
By the end of this lab, you will be able to:

• Deploy a basic Red Hat Ceph Storage cluster using open-source tools • Install and configure MON (Monitor), OSD (Object Storage Daemon), and MGR (Manager) services • Verify cluster health and functionality • Understand the fundamental architecture of a Ceph storage cluster • Troubleshoot common installation issues

Prerequisites
Before starting this lab, you should have:

• Basic Linux administration skills including command-line navigation and file editing • Understanding of storage concepts such as block storage, object storage, and distributed systems • Familiarity with SSH and remote server management • Knowledge of network configuration including IP addressing and firewall concepts • Experience with package management using yum or dnf

Required Knowledge Areas
• Linux file system hierarchy and permissions • Basic networking concepts (TCP/IP, ports, firewalls) • Understanding of virtualization concepts • Familiarity with YAML configuration files

Lab Environment Setup
Al Nafi Cloud Machines: This lab uses pre-configured Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your environment - no need to build your own virtual machines.

Environment Specifications
• Operating System: CentOS 8 Stream or Rocky Linux 8 • Number of Nodes: 3 virtual machines • RAM per Node: 4GB minimum • Storage per Node: 20GB system disk + 10GB additional disk for OSD • Network: Private network with internet access

Node Configuration
Node Name	Role	IP Address	Hostname
ceph-admin	Admin/MON/MGR	192.168.1.10	ceph-admin
ceph-node1	MON/OSD	192.168.1.11	ceph-node1
ceph-node2	OSD	192.168.1.12	ceph-node2
Task 1: Prepare the Environment
Subtask 1.1: Initial System Configuration
Step 1: Connect to the admin node

ssh root@ceph-admin
Step 2: Update the system packages

dnf update -y
Step 3: Configure hostname and hosts file

# Set hostname
hostnamectl set-hostname ceph-admin

# Edit hosts file
cat >> /etc/hosts << EOF
192.168.1.10 ceph-admin
192.168.1.11 ceph-node1
192.168.1.12 ceph-node2
EOF
Step 4: Repeat hostname configuration on all nodes

# On ceph-node1
ssh root@ceph-node1
hostnamectl set-hostname ceph-node1
cat >> /etc/hosts << EOF
192.168.1.10 ceph-admin
192.168.1.11 ceph-node1
192.168.1.12 ceph-node2
EOF

# On ceph-node2
ssh root@ceph-node2
hostnamectl set-hostname ceph-node2
cat >> /etc/hosts << EOF
192.168.1.10 ceph-admin
192.168.1.11 ceph-node1
192.168.1.12 ceph-node2
EOF
Subtask 1.2: Configure SSH Key Authentication
Step 1: Generate SSH key pair on admin node

ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
Step 2: Copy SSH keys to all nodes

ssh-copy-id root@ceph-admin
ssh-copy-id root@ceph-node1
ssh-copy-id root@ceph-node2
Step 3: Test SSH connectivity

ssh ceph-node1 "hostname"
ssh ceph-node2 "hostname"
Subtask 1.3: Configure Firewall and SELinux
Step 1: Configure firewall rules on all nodes

# Run on all nodes
firewall-cmd --permanent --add-service=ceph-mon
firewall-cmd --permanent --add-service=ceph
firewall-cmd --permanent --add-port=6789/tcp
firewall-cmd --permanent --add-port=6800-7300/tcp
firewall-cmd --reload
Step 2: Configure SELinux (set to permissive for lab purposes)

# Run on all nodes
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
Task 2: Install Ceph Components
Subtask 2.1: Add Ceph Repository
Step 1: Add the official Ceph repository on all nodes

# Create Ceph repository file
cat > /etc/yum.repos.d/ceph.repo << EOF
[ceph]
name=Ceph packages for x86_64
baseurl=https://download.ceph.com/rpm-pacific/el8/x86_64/
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-pacific/el8/noarch/
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=https://download.ceph.com/rpm-pacific/el8/SRPMS/
enabled=0
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc
EOF
Step 2: Import GPG key

rpm --import https://download.ceph.com/keys/release.asc
Subtask 2.2: Install Ceph Packages
Step 1: Install cephadm on admin node

dnf install -y cephadm
Step 2: Install Docker or Podman (required for containerized deployment)

# Install Podman (recommended)
dnf install -y podman
systemctl enable --now podman
Step 3: Verify cephadm installation

cephadm version
Task 3: Bootstrap Ceph Cluster
Subtask 3.1: Initialize the Cluster
Step 1: Bootstrap the Ceph cluster from admin node

cephadm bootstrap --mon-ip 192.168.1.10 --cluster-network 192.168.1.0/24
Important Note: The bootstrap process will:

Create the first MON daemon
Create the first MGR daemon
Generate cluster configuration
Create admin keyring
Start the Ceph dashboard
Step 2: Save the dashboard credentials (displayed during bootstrap)

The output will show something like:

Ceph Dashboard is now available at:

             URL: https://ceph-admin:8443/
            User: admin
        Password: [generated-password]
Step 3: Install Ceph CLI tools

cephadm add-repo --release pacific
cephadm install ceph-common
Subtask 3.2: Configure Ceph CLI
Step 1: Copy admin keyring and config

mkdir -p /etc/ceph
cephadm shell -- ceph config generate-minimal-conf > /etc/ceph/ceph.conf
cephadm shell -- ceph auth get client.admin > /etc/ceph/ceph.client.admin.keyring
Step 2: Test Ceph CLI

ceph status
Expected output should show:

cluster:
    id:     [cluster-id]
    health: HEALTH_WARN
            OSD count 0 < osd_pool_default_size 3
Task 4: Add Additional Nodes
Subtask 4.1: Add Hosts to Cluster
Step 1: Add ceph-node1 to the cluster

ceph orch host add ceph-node1 192.168.1.11
Step 2: Add ceph-node2 to the cluster

ceph orch host add ceph-node2 192.168.1.12
Step 3: Verify hosts are added

ceph orch host ls
Subtask 4.2: Deploy Additional MON Services
Step 1: Deploy MON service on ceph-node1

ceph orch daemon add mon ceph-node1:192.168.1.11
Step 2: Verify MON services

ceph mon stat
Task 5: Configure OSD Services
Subtask 5.1: Prepare Storage Devices
Step 1: List available storage devices on all nodes

ceph orch device ls
Step 2: If no additional disks are shown, create loop devices for lab purposes

# Run on all nodes
dd if=/dev/zero of=/var/lib/ceph-osd.img bs=1G count=10
losetup /dev/loop0 /var/lib/ceph-osd.img
Subtask 5.2: Create OSDs
Step 1: Create OSD on ceph-admin using available device

ceph orch daemon add osd ceph-admin:/dev/loop0
Step 2: Create OSD on ceph-node1

ceph orch daemon add osd ceph-node1:/dev/loop0
Step 3: Create OSD on ceph-node2

ceph orch daemon add osd ceph-node2:/dev/loop0
Step 4: Verify OSD creation

ceph osd tree
Expected output:

ID CLASS WEIGHT  TYPE NAME           STATUS REWEIGHT PRI-AFF
-1       0.02939 root default
-3       0.00980     host ceph-admin
 0   hdd 0.00980         osd.0           up  1.00000 1.00000
-5       0.00980     host ceph-node1
 1   hdd 0.00980         osd.1           up  1.00000 1.00000
-7       0.00980     host ceph-node2
 2   hdd 0.00980         osd.2           up  1.00000 1.00000
Task 6: Verify Cluster Health
Subtask 6.1: Check Cluster Status
Step 1: Check overall cluster health

ceph health
Step 2: Get detailed cluster status

ceph status
Step 3: Check cluster configuration

ceph config dump
Subtask 6.2: Verify Services
Step 1: List all running services

ceph orch ls
Step 2: Check MON services

ceph mon dump
Step 3: Check MGR services

ceph mgr dump
Step 4: Check OSD services

ceph osd dump
Subtask 6.3: Test Basic Functionality
Step 1: Create a test pool

ceph osd pool create test-pool 32 32
Step 2: Enable the pool for RBD

ceph osd pool application enable test-pool rbd
Step 3: Create a test RBD image

rbd create --size 1G test-pool/test-image
Step 4: List RBD images

rbd ls test-pool
Step 5: Get image information

rbd info test-pool/test-image
Task 7: Access Ceph Dashboard
Subtask 7.1: Configure Dashboard Access
Step 1: Check dashboard status

ceph mgr module ls | grep dashboard
Step 2: Get dashboard URL and credentials

ceph mgr services
Step 3: Create additional dashboard user (optional)

ceph dashboard ac-user-create lab-user password administrator
Subtask 7.2: Access Dashboard
Step 1: Open web browser and navigate to the dashboard URL

Step 2: Login with admin credentials

Step 3: Explore the dashboard sections:

Cluster: Overall health and status
Hosts: Node information and services
Monitor: MON service details
OSDs: Storage device information
Pools: Storage pool management
Troubleshooting Common Issues
Issue 1: Bootstrap Fails
Symptoms: Bootstrap command fails with network errors

Solution:

# Check firewall rules
firewall-cmd --list-all

# Verify network connectivity
ping 192.168.1.11
ping 192.168.1.12

# Check if ports are available
ss -tlnp | grep 6789
Issue 2: OSDs Not Starting
Symptoms: OSD services fail to start

Solution:

# Check device availability
lsblk

# Verify device permissions
ls -la /dev/loop0

# Check OSD logs
ceph orch logs osd.0
Issue 3: Cluster Health Warnings
Symptoms: Cluster shows HEALTH_WARN status

Solution:

# Get detailed health information
ceph health detail

# Common fixes for lab environment
ceph config set global osd_pool_default_size 2
ceph config set global osd_pool_default_min_size 1
Issue 4: Dashboard Not Accessible
Symptoms: Cannot access Ceph dashboard

Solution:

# Check MGR service status
ceph mgr stat

# Restart dashboard module
ceph mgr module disable dashboard
ceph mgr module enable dashboard

# Check dashboard configuration
ceph config get mgr mgr/dashboard/server_addr
Performance Verification
Basic Performance Tests
Step 1: Test cluster write performance

rados bench -p test-pool 10 write --no-cleanup
Step 2: Test cluster read performance

rados bench -p test-pool 10 seq
Step 3: Clean up test data

rados bench -p test-pool 10 cleanup
Cleanup and Maintenance
Regular Maintenance Commands
Step 1: Monitor cluster health regularly

ceph health detail
ceph df
Step 2: Check for software updates

ceph orch upgrade check
Step 3: Backup cluster configuration

ceph config generate-minimal-conf > /backup/ceph.conf.backup
ceph auth export > /backup/ceph.keyring.backup
Conclusion
Congratulations! You have successfully completed Lab 2: Installing Ceph Storage Cluster. In this comprehensive lab, you have accomplished the following:

Key Achievements
• Deployed a functional Ceph storage cluster with three nodes using open-source tools • Configured essential Ceph services including MON (Monitor), OSD (Object Storage Daemon), and MGR (Manager) components • Established cluster networking and security configurations for production-ready deployment • Verified cluster health and functionality through comprehensive testing procedures • Gained hands-on experience with cephadm orchestration tool for modern Ceph deployments

Technical Skills Developed
• Cluster Architecture Understanding: You now understand how Ceph's distributed architecture works with MONs maintaining cluster state, OSDs handling data storage, and MGRs providing management interfaces • Container-Based Deployment: Experience with modern containerized Ceph deployment using cephadm • Storage Management: Practical knowledge of creating and managing storage pools and RBD images • Monitoring and Troubleshooting: Skills in using Ceph CLI tools and dashboard for cluster monitoring

Real-World Applications
This lab provides the foundation for enterprise storage solutions where high availability, scalability, and fault tolerance are critical requirements. The skills you've developed are directly applicable to:

• Cloud Infrastructure: Building storage backends for OpenStack, Kubernetes, and other cloud platforms • Enterprise Storage: Implementing software-defined storage solutions for large organizations • Backup and Archive Systems: Creating resilient storage systems for data protection • High-Performance Computing: Supporting storage needs for scientific and research computing environments

Next Steps
With your Ceph cluster now operational, you're prepared to explore advanced topics such as: • RBD (RADOS Block Device) configuration for virtual machine storage • CephFS setup for distributed file system capabilities • Object Gateway (RGW) deployment for S3-compatible object storage • Advanced monitoring and performance tuning techniques

The foundation you've built in this lab serves as the cornerstone for pursuing the Red Hat Certified Specialist in Ceph Cloud Storage certification and advancing your expertise in software-defined storage technologies.

Remember to regularly monitor your cluster health and keep your Ceph installation updated with the latest stable releases to maintain optimal performance and security.
