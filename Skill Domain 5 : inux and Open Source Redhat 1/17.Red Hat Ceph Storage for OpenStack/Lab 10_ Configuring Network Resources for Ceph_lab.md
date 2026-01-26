Lab 10: Configuring Network Resources for Ceph
Objectives
By the end of this lab, you will be able to:

Configure and deploy DHCP services for automated IP address assignment in a Ceph environment
Set up DNS services to provide name resolution for Ceph cluster nodes
Implement PXE boot infrastructure for automated host provisioning
Configure network boot services for seamless Ceph node deployment
Verify network functionality and connectivity for Ceph services
Troubleshoot common network configuration issues in Ceph environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux networking concepts
Familiarity with command-line interface operations
Knowledge of IP addressing and subnetting
Understanding of DNS concepts and record types
Basic knowledge of Ceph architecture and components
Experience with text editors like vim or nano
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure basic networking.

Your lab environment includes:

1 Network Services Server (Ubuntu 22.04 LTS)
3 Ceph Node Machines (for testing provisioning)
Pre-configured network interfaces and basic connectivity
Task 1: Set up DHCP and DNS Servers
Subtask 1.1: Install and Configure DHCP Server
Step 1: Update System Packages
sudo apt update && sudo apt upgrade -y
Step 2: Install DHCP Server
sudo apt install isc-dhcp-server -y
Step 3: Configure Network Interface for DHCP
First, identify your network interface:

ip addr show
Edit the DHCP server configuration to specify which interface to use:

sudo nano /etc/default/isc-dhcp-server
Add or modify the following line (replace eth0 with your actual interface name):

INTERFACESv4="eth0"
INTERFACESv6=""
Step 4: Configure DHCP Server Settings
Create a backup of the original configuration:

sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup
Edit the DHCP configuration file:

sudo nano /etc/dhcp/dhcpd.conf
Add the following configuration (adjust IP ranges according to your network):

# Global DHCP Configuration
default-lease-time 600;
max-lease-time 7200;
authoritative;

# Subnet configuration for Ceph network
subnet 192.168.100.0 netmask 255.255.255.0 {
    range 192.168.100.50 192.168.100.100;
    option routers 192.168.100.1;
    option domain-name-servers 192.168.100.10;
    option domain-name "ceph.local";
    option broadcast-address 192.168.100.255;
    
    # PXE Boot configuration
    next-server 192.168.100.10;
    filename "pxelinux.0";
}

# Reserved IP addresses for Ceph nodes
host ceph-node1 {
    hardware ethernet 52:54:00:12:34:56;
    fixed-address 192.168.100.11;
    option host-name "ceph-node1";
}

host ceph-node2 {
    hardware ethernet 52:54:00:12:34:57;
    fixed-address 192.168.100.12;
    option host-name "ceph-node2";
}

host ceph-node3 {
    hardware ethernet 52:54:00:12:34:58;
    fixed-address 192.168.100.13;
    option host-name "ceph-node3";
}
Step 5: Start and Enable DHCP Service
sudo systemctl start isc-dhcp-server
sudo systemctl enable isc-dhcp-server
sudo systemctl status isc-dhcp-server
Subtask 1.2: Install and Configure DNS Server
Step 1: Install BIND9 DNS Server
sudo apt install bind9 bind9utils bind9-doc -y
Step 2: Configure DNS Server Options
Edit the main BIND configuration file:

sudo nano /etc/bind/named.conf.options
Add the following configuration:

options {
    directory "/var/cache/bind";
    
    # Listen on all interfaces
    listen-on { any; };
    listen-on-v6 { any; };
    
    # Allow queries from local network
    allow-query { localhost; 192.168.100.0/24; };
    
    # Forwarders for external DNS resolution
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    
    # Enable recursion
    recursion yes;
    
    dnssec-validation auto;
    auth-nxdomain no;
};
Step 3: Configure Local DNS Zones
Edit the local zones configuration:

sudo nano /etc/bind/named.conf.local
Add the following zone definitions:

# Forward zone for ceph.local
zone "ceph.local" {
    type master;
    file "/etc/bind/db.ceph.local";
};

# Reverse zone for 192.168.100.x
zone "100.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.100";
};
Step 4: Create Forward DNS Zone File
sudo nano /etc/bind/db.ceph.local
Add the following content:

$TTL    604800
@       IN      SOA     ns1.ceph.local. admin.ceph.local. (
                        2023110101      ; Serial
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL

; Name servers
@       IN      NS      ns1.ceph.local.

; A records
ns1             IN      A       192.168.100.10
dhcp            IN      A       192.168.100.10
pxe             IN      A       192.168.100.10

; Ceph cluster nodes
ceph-node1      IN      A       192.168.100.11
ceph-node2      IN      A       192.168.100.12
ceph-node3      IN      A       192.168.100.13
ceph-mon1       IN      A       192.168.100.11
ceph-mon2       IN      A       192.168.100.12
ceph-mon3       IN      A       192.168.100.13
ceph-osd1       IN      A       192.168.100.11
ceph-osd2       IN      A       192.168.100.12
ceph-osd3       IN      A       192.168.100.13

; CNAME records for services
monitor         IN      CNAME   ceph-mon1
dashboard       IN      CNAME   ceph-mon1
Step 5: Create Reverse DNS Zone File
sudo nano /etc/bind/db.192.168.100
Add the following content:

$TTL    604800
@       IN      SOA     ns1.ceph.local. admin.ceph.local. (
                        2023110101      ; Serial
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL

; Name servers
@       IN      NS      ns1.ceph.local.

; PTR records
10      IN      PTR     ns1.ceph.local.
10      IN      PTR     dhcp.ceph.local.
10      IN      PTR     pxe.ceph.local.
11      IN      PTR     ceph-node1.ceph.local.
12      IN      PTR     ceph-node2.ceph.local.
13      IN      PTR     ceph-node3.ceph.local.
Step 6: Validate DNS Configuration
Check the configuration syntax:

sudo named-checkconf
sudo named-checkzone ceph.local /etc/bind/db.ceph.local
sudo named-checkzone 100.168.192.in-addr.arpa /etc/bind/db.192.168.100
Step 7: Start and Enable DNS Service
sudo systemctl start bind9
sudo systemctl enable bind9
sudo systemctl status bind9
Task 2: Configure PXE Booting and Host Provisioning
Subtask 2.1: Install and Configure TFTP Server
Step 1: Install TFTP Server
sudo apt install tftpd-hpa -y
Step 2: Configure TFTP Server
Edit the TFTP configuration:

sudo nano /etc/default/tftpd-hpa
Modify the configuration:

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure"
Step 3: Create TFTP Boot Directory Structure
sudo mkdir -p /var/lib/tftpboot/pxelinux.cfg
sudo mkdir -p /var/lib/tftpboot/images/ubuntu
sudo chmod -R 755 /var/lib/tftpboot
Step 4: Download PXE Boot Files
# Download syslinux for PXE boot files
sudo apt install syslinux-common pxelinux -y

# Copy PXE boot files
sudo cp /usr/lib/PXELINUX/pxelinux.0 /var/lib/tftpboot/
sudo cp /usr/lib/syslinux/modules/bios/*.c32 /var/lib/tftpboot/
Step 5: Start and Enable TFTP Service
sudo systemctl start tftpd-hpa
sudo systemctl enable tftpd-hpa
sudo systemctl status tftpd-hpa
Subtask 2.2: Configure PXE Boot Menu
Step 1: Create Default PXE Configuration
sudo nano /var/lib/tftpboot/pxelinux.cfg/default
Add the following configuration:

DEFAULT menu.c32
PROMPT 0
TIMEOUT 300
ONTIMEOUT local

MENU TITLE Ceph Node PXE Boot Menu
MENU BACKGROUND pxelinux.cfg/background.png

LABEL local
    MENU LABEL Boot from ^Local Drive
    LOCALBOOT 0

LABEL ubuntu-install
    MENU LABEL ^Install Ubuntu 22.04 for Ceph Node
    KERNEL images/ubuntu/vmlinuz
    APPEND initrd=images/ubuntu/initrd.gz url=http://192.168.100.10/ubuntu/preseed.cfg netcfg/choose_interface=auto locale=en_US keyboard-configuration/layoutcode=us netcfg/get_hostname=ceph-node netcfg/get_domain=ceph.local

LABEL ubuntu-rescue
    MENU LABEL Ubuntu ^Rescue Mode
    KERNEL images/ubuntu/vmlinuz
    APPEND initrd=images/ubuntu/initrd.gz rescue/enable=true
Step 2: Download Ubuntu Network Boot Images
# Create temporary directory
cd /tmp
wget http://archive.ubuntu.com/ubuntu/dists/jammy/main/installer-amd64/current/legacy-images/netboot/netboot.tar.gz

# Extract and copy boot images
sudo tar -xzf netboot.tar.gz
sudo cp ubuntu-installer/amd64/linux /var/lib/tftpboot/images/ubuntu/vmlinuz
sudo cp ubuntu-installer/amd64/initrd.gz /var/lib/tftpboot/images/ubuntu/
Subtask 2.3: Configure HTTP Server for Provisioning
Step 1: Install Apache Web Server
sudo apt install apache2 -y
Step 2: Create Provisioning Directory Structure
sudo mkdir -p /var/www/html/ubuntu
sudo mkdir -p /var/www/html/ceph-scripts
Step 3: Create Preseed Configuration for Automated Installation
sudo nano /var/www/html/ubuntu/preseed.cfg
Add the following preseed configuration:

# Localization
d-i debian-installer/locale string en_US
d-i keyboard-configuration/xkb-keymap select us

# Network configuration
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string ceph-node
d-i netcfg/get_domain string ceph.local

# Mirror settings
d-i mirror/country string manual
d-i mirror/http/hostname string archive.ubuntu.com
d-i mirror/http/directory string /ubuntu
d-i mirror/http/proxy string

# Account setup
d-i passwd/user-fullname string Ceph Administrator
d-i passwd/username string cephadmin
d-i passwd/user-password password ceph123
d-i passwd/user-password-again password ceph123
d-i user-setup/allow-password-weak boolean true

# Clock and time zone setup
d-i clock-setup/utc boolean true
d-i time/zone string UTC

# Partitioning
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# Package selection
tasksel tasksel/first multiselect ubuntu-server
d-i pkgsel/include string openssh-server python3 python3-pip curl wget
d-i pkgsel/upgrade select full-upgrade

# Boot loader installation
d-i grub-installer/only_debian boolean true

# Finish installation
d-i finish-install/reboot_in_progress note

# Late commands for Ceph preparation
d-i preseed/late_command string \
    in-target wget -O /tmp/ceph-prep.sh http://192.168.100.10/ceph-scripts/ceph-prep.sh; \
    in-target chmod +x /tmp/ceph-prep.sh; \
    in-target /tmp/ceph-prep.sh
Step 4: Create Ceph Preparation Script
sudo nano /var/www/html/ceph-scripts/ceph-prep.sh
Add the following script:

#!/bin/bash

# Ceph Node Preparation Script
echo "Starting Ceph node preparation..."

# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y python3-pip docker.io chrony

# Configure chrony for time synchronization
cat > /etc/chrony/chrony.conf << EOF
server 192.168.100.10 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF

systemctl enable chrony
systemctl start chrony

# Configure SSH for cephadmin user
mkdir -p /home/cephadmin/.ssh
chmod 700 /home/cephadmin/.ssh
chown cephadmin:cephadmin /home/cephadmin/.ssh

# Add cephadmin to sudo group
usermod -aG sudo cephadmin
echo "cephadmin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Enable and start Docker
systemctl enable docker
systemctl start docker
usermod -aG docker cephadmin

# Install cephadm
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
chmod +x cephadm
mv cephadm /usr/local/bin/

# Create ceph configuration directory
mkdir -p /etc/ceph
chown cephadmin:cephadmin /etc/ceph

echo "Ceph node preparation completed successfully!"
Make the script executable:

sudo chmod +x /var/www/html/ceph-scripts/ceph-prep.sh
Step 5: Start and Enable Apache Service
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl status apache2
Task 3: Verify Network Functionality for Ceph Services
Subtask 3.1: Test DHCP Functionality
Step 1: Check DHCP Server Status and Logs
sudo systemctl status isc-dhcp-server
sudo journalctl -u isc-dhcp-server -f
Step 2: Test DHCP Lease Assignment
Check current DHCP leases:

sudo cat /var/lib/dhcp/dhcpd.leases
Step 3: Verify DHCP Configuration
Test DHCP configuration syntax:

sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
Subtask 3.2: Test DNS Functionality
Step 1: Test Forward DNS Resolution
# Test local DNS resolution
nslookup ceph-node1.ceph.local 192.168.100.10
nslookup ceph-node2.ceph.local 192.168.100.10
nslookup ceph-node3.ceph.local 192.168.100.10

# Test using dig command
dig @192.168.100.10 ceph-node1.ceph.local
Step 2: Test Reverse DNS Resolution
# Test reverse DNS lookup
nslookup 192.168.100.11 192.168.100.10
nslookup 192.168.100.12 192.168.100.10

# Test using dig command
dig @192.168.100.10 -x 192.168.100.11
Step 3: Verify DNS Server Logs
sudo journalctl -u bind9 -f
Subtask 3.3: Test PXE Boot Functionality
Step 1: Verify TFTP Server Accessibility
# Test TFTP server locally
tftp 192.168.100.10
> get pxelinux.0
> quit

# Check if file was downloaded
ls -la pxelinux.0
Step 2: Verify HTTP Server Accessibility
# Test preseed file accessibility
curl http://192.168.100.10/ubuntu/preseed.cfg

# Test Ceph preparation script
curl http://192.168.100.10/ceph-scripts/ceph-prep.sh
Step 3: Check Network Boot Files
# Verify PXE boot files are in place
sudo ls -la /var/lib/tftpboot/
sudo ls -la /var/lib/tftpboot/pxelinux.cfg/
sudo ls -la /var/lib/tftpboot/images/ubuntu/
Subtask 3.4: Network Connectivity Tests
Step 1: Test Network Interfaces
# Check network interface configuration
ip addr show
ip route show

# Test connectivity to gateway
ping -c 4 192.168.100.1
Step 2: Test Port Connectivity
# Test DHCP port (67)
sudo netstat -ulnp | grep :67

# Test DNS port (53)
sudo netstat -ulnp | grep :53

# Test TFTP port (69)
sudo netstat -ulnp | grep :69

# Test HTTP port (80)
sudo netstat -tlnp | grep :80
Step 3: Create Network Validation Script
sudo nano /usr/local/bin/ceph-network-test.sh
Add the following script:

#!/bin/bash

echo "=== Ceph Network Services Validation ==="
echo

# Test DHCP Service
echo "1. Testing DHCP Service..."
if systemctl is-active --quiet isc-dhcp-server; then
    echo "   ✓ DHCP service is running"
else
    echo "   ✗ DHCP service is not running"
fi

# Test DNS Service
echo "2. Testing DNS Service..."
if systemctl is-active --quiet bind9; then
    echo "   ✓ DNS service is running"
    
    # Test DNS resolution
    if nslookup ceph-node1.ceph.local 192.168.100.10 >/dev/null 2>&1; then
        echo "   ✓ DNS resolution working"
    else
        echo "   ✗ DNS resolution failed"
    fi
else
    echo "   ✗ DNS service is not running"
fi

# Test TFTP Service
echo "3. Testing TFTP Service..."
if systemctl is-active --quiet tftpd-hpa; then
    echo "   ✓ TFTP service is running"
else
    echo "   ✗ TFTP service is not running"
fi

# Test HTTP Service
echo "4. Testing HTTP Service..."
if systemctl is-active --quiet apache2; then
    echo "   ✓ HTTP service is running"
    
    # Test preseed file
    if curl -s http://192.168.100.10/ubuntu/preseed.cfg >/dev/null; then
        echo "   ✓ Preseed file accessible"
    else
        echo "   ✗ Preseed file not accessible"
    fi
else
    echo "   ✗ HTTP service is not running"
fi

# Test Network Connectivity
echo "5. Testing Network Connectivity..."
if ping -c 1 192.168.100.1 >/dev/null 2>&1; then
    echo "   ✓ Gateway connectivity working"
else
    echo "   ✗ Gateway connectivity failed"
fi

echo
echo "=== Network Services Validation Complete ==="
Make the script executable and run it:

sudo chmod +x /usr/local/bin/ceph-network-test.sh
sudo /usr/local/bin/ceph-network-test.sh
Subtask 3.5: Troubleshooting Common Issues
Common DHCP Issues
Issue: DHCP service fails to start Solution:

# Check configuration syntax
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf

# Check interface configuration
sudo nano /etc/default/isc-dhcp-server

# Restart service
sudo systemctl restart isc-dhcp-server
Issue: No IP addresses being assigned Solution:

# Check DHCP logs
sudo journalctl -u isc-dhcp-server

# Verify network interface is up
ip link show

# Check firewall rules
sudo ufw status
Common DNS Issues
Issue: DNS queries not resolving Solution:

# Check DNS configuration
sudo named-checkconf

# Check zone files
sudo named-checkzone ceph.local /etc/bind/db.ceph.local

# Restart DNS service
sudo systemctl restart bind9
Issue: Reverse DNS not working Solution:

# Verify reverse zone configuration
sudo named-checkzone 100.168.192.in-addr.arpa /etc/bind/db.192.168.100

# Check PTR records syntax
sudo nano /etc/bind/db.192.168.100
Common PXE Issues
Issue: PXE boot files not found Solution:

# Verify TFTP directory permissions
sudo chmod -R 755 /var/lib/tftpboot

# Check file locations
sudo ls -la /var/lib/tftpboot/pxelinux.0

# Test TFTP connectivity
tftp 192.168.100.10
Issue: Preseed file not accessible Solution:

# Check Apache service
sudo systemctl status apache2

# Verify file permissions
sudo chmod 644 /var/www/html/ubuntu/preseed.cfg

# Test HTTP connectivity
curl -I http://192.168.100.10/ubuntu/preseed.cfg
Conclusion
In this comprehensive lab, you have successfully configured essential network resources for a Ceph storage environment. Here's what you accomplished:

Key Achievements:

DHCP Configuration: You set up a DHCP server that automatically assigns IP addresses to Ceph nodes, including reserved addresses for specific hardware MAC addresses. This ensures consistent network addressing across your Ceph cluster.

DNS Services: You configured a complete DNS infrastructure with both forward and reverse lookup capabilities, providing name resolution for all Ceph services and nodes. This is crucial for Ceph's inter-node communication.

PXE Boot Infrastructure: You implemented a complete PXE boot environment with TFTP services, enabling automated network-based installation of new Ceph nodes without manual intervention.

Automated Provisioning: You created preseed configurations and preparation scripts that automatically configure new nodes with all necessary Ceph prerequisites, significantly reducing deployment time.

Network Validation: You developed comprehensive testing procedures to verify all network services are functioning correctly and can support Ceph operations.

Why This Matters:

Scalability: This infrastructure allows you to rapidly deploy new Ceph nodes as your storage needs grow
Consistency: Automated provisioning ensures all nodes are configured identically, reducing configuration drift
Reliability: Proper DNS and DHCP services provide stable network foundations for Ceph cluster operations
Efficiency: PXE boot capabilities eliminate manual installation processes, saving significant time in large deployments
Maintainability: Centralized network services make it easier to manage and troubleshoot network-related issues
This network infrastructure forms the foundation for a production-ready Ceph environment, enabling automated deployment, consistent configuration, and reliable inter-node communication essential for distributed storage operations.
