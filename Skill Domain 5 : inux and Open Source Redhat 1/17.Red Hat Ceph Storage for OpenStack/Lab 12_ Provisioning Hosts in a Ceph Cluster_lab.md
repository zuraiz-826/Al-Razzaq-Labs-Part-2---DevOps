Lab 12: Provisioning Hosts in a Ceph Cluster
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of automated host provisioning in Ceph clusters
Configure PXE booting infrastructure for automated node deployment
Create and customize Ceph configuration templates for new hosts
Provision new nodes using automated deployment methods
Assign newly provisioned nodes to appropriate Ceph pools
Verify successful integration of new hosts into the existing cluster
Troubleshoot common provisioning issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with Ceph cluster architecture and components
Knowledge of networking concepts (DHCP, TFTP, PXE)
Experience with command-line interface operations
Understanding of YAML configuration files
Basic knowledge of storage pools and placement groups in Ceph
Required Knowledge Areas
Linux file systems and partitioning
Network boot processes
Ceph cluster management fundamentals
SSH key management
Basic scripting concepts
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure hardware.

Environment Details
Your lab environment includes:

ceph-admin: Administration node with cephadm installed
ceph-mon1: Existing monitor node
ceph-osd1: Existing OSD node
pxe-server: PXE boot server for provisioning
new-node1: Target node for provisioning (initially powered off)
new-node2: Target node for provisioning (initially powered off)
All machines are connected to the same network segment with appropriate firewall rules configured.

Task 1: Setting Up PXE Boot Infrastructure
Subtask 1.1: Configure DHCP Server for PXE Boot
First, we'll configure the DHCP server to support PXE booting for new nodes.

Connect to the PXE server:
ssh root@pxe-server
Install required packages:
dnf install -y dhcp-server tftp-server syslinux httpd
Configure DHCP for PXE boot:
cat > /etc/dhcp/dhcpd.conf << 'EOF'
# DHCP configuration for PXE boot
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.100.0 netmask 255.255.255.0 {
    range 192.168.100.50 192.168.100.100;
    option routers 192.168.100.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    option broadcast-address 192.168.100.255;
    
    # PXE boot configuration
    next-server 192.168.100.10;  # PXE server IP
    filename "pxelinux.0";
    
    # Static reservations for new nodes
    host new-node1 {
        hardware ethernet 52:54:00:12:34:56;
        fixed-address 192.168.100.51;
        option host-name "new-node1";
    }
    
    host new-node2 {
        hardware ethernet 52:54:00:12:34:57;
        fixed-address 192.168.100.52;
        option host-name "new-node2";
    }
}
EOF
Start and enable DHCP service:
systemctl enable --now dhcpd
systemctl status dhcpd
Subtask 1.2: Configure TFTP Server
Configure TFTP service:
# Enable TFTP in xinetd configuration
sed -i 's/disable.*= yes/disable = no/' /etc/xinetd.d/tftp

# Create TFTP root directory
mkdir -p /var/lib/tftpboot/pxelinux.cfg
Copy PXE boot files:
# Copy syslinux files
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/
cp /usr/share/syslinux/menu.c32 /var/lib/tftpboot/
cp /usr/share/syslinux/ldlinux.c32 /var/lib/tftpboot/
cp /usr/share/syslinux/libutil.c32 /var/lib/tftpboot/
Start TFTP service:
systemctl enable --now xinetd
systemctl enable --now tftp
Subtask 1.3: Prepare Boot Images and Kickstart Files
Create directory structure for boot files:
mkdir -p /var/www/html/images/centos8
mkdir -p /var/www/html/kickstart
Download CentOS 8 Stream boot images:
cd /var/www/html/images/centos8
wget http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/images/pxeboot/vmlinuz
wget http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/images/pxeboot/initrd.img
Copy boot images to TFTP directory:
cp /var/www/html/images/centos8/* /var/lib/tftpboot/
Create PXE boot menu:
cat > /var/lib/tftpboot/pxelinux.cfg/default << 'EOF'
DEFAULT menu.c32
PROMPT 0
TIMEOUT 30
MENU TITLE Ceph Node Provisioning

LABEL centos8-ceph
    MENU LABEL CentOS 8 Stream - Ceph Node
    KERNEL vmlinuz
    APPEND initrd=initrd.img inst.repo=http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/ inst.ks=http://192.168.100.10/kickstart/ceph-node.ks ip=dhcp
EOF
Task 2: Creating Ceph Configuration Templates
Subtask 2.1: Create Kickstart Template for Ceph Nodes
Create kickstart configuration for Ceph nodes:
cat > /var/www/html/kickstart/ceph-node.ks << 'EOF'
#version=RHEL8
# System authorization information
auth --enableshadow --passalgo=sha512

# Use network installation
url --url="http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/"

# Use text mode install
text

# Run the Setup Agent on first boot
firstboot --enable

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Network information
network --bootproto=dhcp --device=eth0 --onboot=on --activate

# Root password (change this in production)
rootpw --iscrypted $6$rounds=4096$saltsaltsal$L9.LO/QLOeXq.XqXq0XqXq0XqXq0XqXq0XqXq0XqXq0XqXq0XqXq0XqXq0XqXq0XqXq0XqXq0XqXq0XqXq0

# System services
services --enabled="chronyd,sshd"

# System timezone
timezone America/New_York --isUtc

# System bootloader configuration
bootloader --location=mbr --boot-drive=vda

# Partition clearing information
clearpart --all --initlabel --drives=vda

# Disk partitioning information
part /boot --fstype="xfs" --ondisk=vda --size=1024
part pv.01 --fstype="lvmpv" --ondisk=vda --size=1 --grow
volgroup vg_root --pesize=4096 pv.01
logvol / --fstype="xfs" --size=20480 --name=lv_root --vgname=vg_root
logvol /var --fstype="xfs" --size=10240 --name=lv_var --vgname=vg_root
logvol swap --fstype="swap" --size=4096 --name=lv_swap --vgname=vg_root

# Additional disk for Ceph OSD (if available)
part /var/lib/ceph/osd --fstype="xfs" --ondisk=vdb --size=1 --grow

%packages
@^minimal-environment
chrony
openssh-server
python3
podman
lvm2
%end

%post --log=/root/ks-post.log

# Configure SSH key for ceph-admin access
mkdir -p /root/.ssh
cat >> /root/.ssh/authorized_keys << 'SSHKEY'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7... ceph-admin@ceph-cluster
SSHKEY

chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh

# Configure hostname based on IP
IP=$(ip route get 8.8.8.8 | awk '{print $7}' | head -1)
case $IP in
    192.168.100.51)
        hostnamectl set-hostname new-node1.ceph.local
        ;;
    192.168.100.52)
        hostnamectl set-hostname new-node2.ceph.local
        ;;
esac

# Add entries to /etc/hosts
cat >> /etc/hosts << 'HOSTS'
192.168.100.10  ceph-admin.ceph.local ceph-admin
192.168.100.11  ceph-mon1.ceph.local ceph-mon1
192.168.100.12  ceph-osd1.ceph.local ceph-osd1
192.168.100.51  new-node1.ceph.local new-node1
192.168.100.52  new-node2.ceph.local new-node2
HOSTS

# Configure firewall for Ceph
firewall-cmd --permanent --add-service=ceph
firewall-cmd --permanent --add-service=ceph-mon
firewall-cmd --reload

# Install and configure chrony for time synchronization
systemctl enable chronyd
systemctl start chronyd

# Signal completion
curl -X POST http://192.168.100.10/provisioning-complete/$(hostname)

%end

reboot
EOF
Subtask 2.2: Create Ceph Deployment Templates
Create cephadm specification template:
mkdir -p /var/www/html/ceph-templates
cat > /var/www/html/ceph-templates/cluster-spec.yaml << 'EOF'
service_type: host
addr: NEW_NODE_IP
hostname: NEW_NODE_HOSTNAME
labels:
  - osd
---
service_type: mon
placement:
  hosts:
    - ceph-mon1
    - NEW_NODE_HOSTNAME
---
service_type: mgr
placement:
  hosts:
    - ceph-admin
    - NEW_NODE_HOSTNAME
---
service_type: osd
service_id: default_drive_group
placement:
  host_pattern: '*'
data_devices:
  paths:
    - /dev/vdb
EOF
Start HTTP service for serving files:
systemctl enable --now httpd
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
Task 3: Provisioning New Nodes
Subtask 3.1: Prepare Ceph Admin Node
Connect to ceph-admin node:
ssh root@ceph-admin
Generate SSH key for cluster access:
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""
Create provisioning script:
cat > /root/provision-ceph-node.sh << 'EOF'
#!/bin/bash

NODE_IP=$1
NODE_HOSTNAME=$2

if [ -z "$NODE_IP" ] || [ -z "$NODE_HOSTNAME" ]; then
    echo "Usage: $0 <node_ip> <node_hostname>"
    exit 1
fi

echo "Provisioning Ceph node: $NODE_HOSTNAME ($NODE_IP)"

# Wait for node to be accessible
echo "Waiting for node to be accessible..."
while ! ping -c 1 $NODE_IP &> /dev/null; do
    sleep 10
done

# Wait for SSH to be available
echo "Waiting for SSH service..."
while ! nc -z $NODE_IP 22; do
    sleep 5
done

# Add node to known hosts
ssh-keyscan -H $NODE_IP >> /root/.ssh/known_hosts

# Test SSH connectivity
if ssh -o ConnectTimeout=10 root@$NODE_IP "echo 'SSH connection successful'"; then
    echo "SSH connection to $NODE_HOSTNAME established"
else
    echo "Failed to establish SSH connection to $NODE_HOSTNAME"
    exit 1
fi

# Add host to Ceph cluster
echo "Adding $NODE_HOSTNAME to Ceph cluster..."
ceph orch host add $NODE_HOSTNAME $NODE_IP --labels osd

# Wait for host to be added
sleep 30

# Deploy OSD on new node
echo "Deploying OSD on $NODE_HOSTNAME..."
ceph orch daemon add osd $NODE_HOSTNAME:/dev/vdb

echo "Node $NODE_HOSTNAME provisioned successfully!"
EOF

chmod +x /root/provision-ceph-node.sh
Subtask 3.2: Power On and Provision First Node
Power on new-node1 (simulate by connecting to the node):
# This would typically be done through IPMI or virtualization management
# For this lab, we'll simulate the node being powered on and PXE booting
echo "Simulating power-on of new-node1..."
Monitor provisioning progress:
# Check DHCP leases
ssh root@pxe-server "tail -f /var/log/messages | grep dhcp"
Wait for installation completion and provision the node:
# Wait for the node to complete installation and reboot
sleep 300  # Adjust based on installation time

# Provision the node
./provision-ceph-node.sh 192.168.100.51 new-node1
Subtask 3.3: Provision Second Node
Power on new-node2:
echo "Simulating power-on of new-node2..."
Provision the second node:
# Wait for installation completion
sleep 300

# Provision the node
./provision-ceph-node.sh 192.168.100.52 new-node2
Task 4: Assigning Nodes to Appropriate Pools
Subtask 4.1: Verify Cluster Status
Check cluster health:
ceph status
ceph orch host ls
ceph osd tree
Verify new OSDs are active:
ceph osd stat
ceph df
Subtask 4.2: Create Custom Pools and Assign Nodes
Create a new pool for the provisioned nodes:
# Create a replicated pool
ceph osd pool create new-nodes-pool 32 32

# Enable the pool for RBD
ceph osd pool application enable new-nodes-pool rbd
Create CRUSH rule for new nodes:
# Create CRUSH rule to use only new nodes
ceph osd crush rule create-replicated new-nodes-rule default host
Modify CRUSH map to create a separate root for new nodes:
# Get current CRUSH map
ceph osd getcrushmap -o crushmap.bin
crushtool -d crushmap.bin -o crushmap.txt

# Create a backup
cp crushmap.txt crushmap.txt.backup

# Add new root for new nodes (manual editing required)
cat >> crushmap.txt << 'EOF'

# New nodes root
root new-nodes {
    id -10
    alg straw2
    hash 0
    item new-node1 weight 1.000
    item new-node2 weight 1.000
}

# Rule for new nodes pool
rule new-nodes-rule {
    id 1
    type replicated
    min_size 1
    max_size 10
    step take new-nodes
    step chooseleaf firstn 0 type host
    step emit
}
EOF

# Compile and set the new CRUSH map
crushtool -c crushmap.txt -o crushmap-new.bin
ceph osd setcrushmap -i crushmap-new.bin
Apply the new rule to the pool:
ceph osd pool set new-nodes-pool crush_rule new-nodes-rule
Subtask 4.3: Test Pool Functionality
Create a test RBD image in the new pool:
rbd create --size 1G --pool new-nodes-pool test-image
rbd info new-nodes-pool/test-image
Verify data placement:
# Check where the PGs are placed
ceph pg dump | grep new-nodes-pool
Test I/O operations:
# Map the RBD image
rbd map new-nodes-pool/test-image

# Create filesystem and mount
mkfs.xfs /dev/rbd0
mkdir -p /mnt/test-rbd
mount /dev/rbd0 /mnt/test-rbd

# Test write operations
dd if=/dev/zero of=/mnt/test-rbd/testfile bs=1M count=100

# Verify
ls -lh /mnt/test-rbd/

# Cleanup
umount /mnt/test-rbd
rbd unmap /dev/rbd0
Task 5: Verification and Monitoring
Subtask 5.1: Comprehensive Cluster Verification
Check overall cluster health:
ceph health detail
ceph status
Verify all services are running:
ceph orch ps
ceph orch host ls
Check OSD status and distribution:
ceph osd tree
ceph osd df
ceph pg stat
Subtask 5.2: Performance Testing
Run RADOS bench on new pool:
# Write test
rados bench -p new-nodes-pool 60 write --no-cleanup

# Read test
rados bench -p new-nodes-pool 60 seq

# Cleanup
rados -p new-nodes-pool cleanup
Monitor cluster performance:
ceph tell osd.* perf dump
ceph daemon osd.2 perf dump  # Assuming OSD.2 is on new-node1
Troubleshooting Common Issues
PXE Boot Issues
DHCP not responding:
# Check DHCP service status
systemctl status dhcpd
journalctl -u dhcpd -f

# Verify network connectivity
tcpdump -i eth0 port 67 or port 68
TFTP files not accessible:
# Test TFTP connectivity
tftp 192.168.100.10
> get pxelinux.0
> quit

# Check TFTP logs
journalctl -u xinetd -f
Ceph Integration Issues
SSH connectivity problems:
# Test SSH connection
ssh -v root@new-node1

# Check SSH key permissions
ls -la /root/.ssh/
OSD deployment failures:
# Check cephadm logs
ceph orch logs
ceph log last cephadm

# Verify disk availability
ssh root@new-node1 "lsblk"
Network Configuration Issues
Hostname resolution problems:
# Test DNS resolution
nslookup new-node1.ceph.local

# Check /etc/hosts entries
cat /etc/hosts
Firewall blocking connections:
# Check firewall status
firewall-cmd --list-all
ss -tlnp | grep :3300  # Ceph messenger port
Conclusion
In this comprehensive lab, you have successfully:

Configured PXE Boot Infrastructure: Set up DHCP and TFTP servers to enable automated network booting of new nodes, eliminating the need for manual OS installation.

Created Ceph Configuration Templates: Developed kickstart files and deployment templates that automatically configure new nodes with appropriate Ceph settings, SSH keys, and network configurations.

Automated Node Provisioning: Implemented a complete automated provisioning workflow that takes bare-metal servers from power-on to fully integrated Ceph cluster members.

Managed Pool Assignments: Created custom storage pools and CRUSH rules to control data placement and ensure new nodes are properly integrated into the cluster's storage hierarchy.

Verified Cluster Integration: Performed comprehensive testing to ensure new nodes are functioning correctly and contributing to cluster performance and reliability.

Why This Matters
Automated provisioning is crucial for large-scale Ceph deployments because it:

Reduces Human Error: Eliminates manual configuration mistakes that can lead to cluster inconsistencies
Improves Scalability: Enables rapid deployment of dozens or hundreds of nodes with consistent configurations
Enhances Reliability: Ensures all nodes are configured identically, reducing troubleshooting complexity
Saves Time: Transforms a multi-hour manual process into a largely automated workflow
Supports Infrastructure as Code: Enables version-controlled, repeatable infrastructure deployments
Real-World Applications
The skills learned in this lab are directly applicable to:

Cloud Service Providers: Rapidly scaling storage infrastructure to meet customer demands
Enterprise Data Centers: Standardizing storage node deployments across multiple facilities
Research Institutions: Quickly provisioning compute and storage resources for large-scale projects
Disaster Recovery: Rapidly rebuilding storage infrastructure after hardware failures
This automated approach to Ceph cluster expansion is essential for maintaining operational efficiency in production environments where storage demands can change rapidly and predictably.
