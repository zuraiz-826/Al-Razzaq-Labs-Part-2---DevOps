Lab 10: Configuring Network Resources for Host Provisioning
Objectives
By the end of this lab, students will be able to:

Configure DHCP services in Red Hat Satellite for automated IP address assignment
Set up DNS services to support host provisioning and name resolution
Configure PXE (Preboot Execution Environment) booting for network-based system provisioning
Integrate network services with Red Hat Satellite for seamless host deployment
Test and validate the complete host provisioning workflow
Troubleshoot common network configuration issues in provisioning environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with Red Hat Satellite 6 concepts and architecture
Knowledge of networking fundamentals (DHCP, DNS, TFTP)
Experience with command-line interface operations
Understanding of virtualization concepts
Completed previous Red Hat Satellite labs or equivalent experience
Required Knowledge Areas
TCP/IP networking fundamentals
DHCP lease management
DNS record types and configuration
PXE boot process
Red Hat Satellite capsule servers
Kickstart provisioning concepts
Lab Environment Setup
Al Nafi Cloud Environment: This lab uses pre-configured Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your environment - no need to build your own virtual machines.

Environment Details
Satellite Server: satellite.example.com (192.168.1.10)
Capsule Server: capsule.example.com (192.168.1.20)
Test Network: 192.168.1.0/24
DHCP Range: 192.168.1.100-192.168.1.200
Domain: example.com
Task 1: Setting Up DHCP Server in Satellite
Subtask 1.1: Install and Configure DHCP Service
First, we'll install the DHCP service on the Satellite capsule server and configure it for host provisioning.

Step 1: Access the Capsule Server
# SSH to the capsule server
ssh root@capsule.example.com

# Update the system
dnf update -y
Step 2: Install DHCP Server Package
# Install DHCP server
dnf install -y dhcp-server

# Verify installation
rpm -qa | grep dhcp-server
Step 3: Configure DHCP Service
Create the main DHCP configuration file:

# Backup original configuration
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup

# Create new DHCP configuration
cat > /etc/dhcp/dhcpd.conf << 'EOF'
# DHCP Server Configuration for Satellite Provisioning
authoritative;
ddns-update-style none;
ignore client-updates;

# Global options
option domain-name "example.com";
option domain-name-servers 192.168.1.20;
option routers 192.168.1.1;
option broadcast-address 192.168.1.255;
option netbios-name-servers 192.168.1.20;
option netbios-node-type 8;

# Default and maximum lease times
default-lease-time 86400;
max-lease-time 604800;

# PXE Boot configuration
next-server 192.168.1.20;
filename "pxelinux.0";

# Subnet declaration
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option subnet-mask 255.255.255.0;
    option routers 192.168.1.1;
    option domain-name-servers 192.168.1.20;
    option domain-name "example.com";
    option broadcast-address 192.168.1.255;
    
    # PXE boot options
    next-server 192.168.1.20;
    filename "pxelinux.0";
}

# Host reservations for known systems
host test-server {
    hardware ethernet 52:54:00:12:34:56;
    fixed-address 192.168.1.150;
    option host-name "test-server.example.com";
}
EOF
Step 4: Configure DHCP Service Startup
# Enable and start DHCP service
systemctl enable dhcpd
systemctl start dhcpd

# Check service status
systemctl status dhcpd

# Verify DHCP is listening
netstat -ulnp | grep :67
Subtask 1.2: Integrate DHCP with Satellite
Step 1: Configure Satellite to Manage DHCP
# SSH to Satellite server
ssh root@satellite.example.com

# Install satellite-installer if not present
satellite-installer --scenario satellite \
  --foreman-proxy-dhcp true \
  --foreman-proxy-dhcp-managed true \
  --foreman-proxy-dhcp-interface eth0 \
  --foreman-proxy-dhcp-gateway 192.168.1.1 \
  --foreman-proxy-dhcp-range "192.168.1.100 192.168.1.200" \
  --foreman-proxy-dhcp-nameservers "192.168.1.20"
Step 2: Verify DHCP Integration
# Check proxy features
hammer proxy list

# Verify DHCP feature is enabled
hammer proxy info --name "satellite.example.com"

# Test DHCP connectivity
curl -k https://satellite.example.com:9090/dhcp
Subtask 1.3: Configure DHCP Reservations
Step 1: Create DHCP Reservations via Satellite
# Create subnet in Satellite
hammer subnet create \
  --name "Production Network" \
  --network "192.168.1.0" \
  --mask "255.255.255.0" \
  --gateway "192.168.1.1" \
  --dns-primary "192.168.1.20" \
  --domains "example.com" \
  --dhcp-id 1 \
  --tftp-id 1

# List available subnets
hammer subnet list
Step 2: Configure Host Groups for DHCP
# Create host group with DHCP settings
hammer hostgroup create \
  --name "RHEL8-Servers" \
  --subnet "Production Network" \
  --domain "example.com" \
  --architecture "x86_64" \
  --operatingsystem "RedHat 8.6" \
  --partition-table "Kickstart default" \
  --medium "Red Hat Enterprise Linux 8"
Task 2: Setting Up DNS Server in Satellite
Subtask 2.1: Install and Configure DNS Service
Step 1: Install BIND DNS Server
# SSH to capsule server
ssh root@capsule.example.com

# Install BIND DNS server
dnf install -y bind bind-utils

# Verify installation
named -v
Step 2: Configure Main DNS Configuration
# Backup original configuration
cp /etc/named.conf /etc/named.conf.backup

# Create new named.conf
cat > /etc/named.conf << 'EOF'
//
// named.conf for Satellite DNS
//
options {
    listen-on port 53 { 127.0.0.1; 192.168.1.20; };
    listen-on-v6 port 53 { ::1; };
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    recursing-file "/var/named/data/named.recursing";
    secroots-file "/var/named/data/named.secroots";
    allow-query { localhost; 192.168.1.0/24; };
    allow-recursion { localhost; 192.168.1.0/24; };
    
    recursion yes;
    dnssec-enable yes;
    dnssec-validation yes;
    
    bindkeys-file "/etc/named.root.key";
    managed-keys-directory "/var/named/dynamic";
    pid-file "/run/named/named.pid";
    session-keyfile "/run/named/session.key";
};

logging {
    channel default_debug {
        file "data/named.run";
        severity dynamic;
    };
};

zone "." IN {
    type hint;
    file "named.ca";
};

// Forward zone for example.com
zone "example.com" IN {
    type master;
    file "example.com.zone";
    allow-update { none; };
};

// Reverse zone for 192.168.1.0/24
zone "1.168.192.in-addr.arpa" IN {
    type master;
    file "1.168.192.in-addr.arpa.zone";
    allow-update { none; };
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF
Step 3: Create Forward DNS Zone File
# Create forward zone file
cat > /var/named/example.com.zone << 'EOF'
$TTL 86400
@   IN  SOA     satellite.example.com. admin.example.com. (
        2023110801  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)

; Name servers
@               IN  NS      satellite.example.com.
@               IN  NS      capsule.example.com.

; A records
satellite       IN  A       192.168.1.10
capsule         IN  A       192.168.1.20
test-server     IN  A       192.168.1.150

; CNAME records
www             IN  CNAME   satellite.example.com.
foreman         IN  CNAME   satellite.example.com.

; MX record
@               IN  MX  10  satellite.example.com.
EOF
Step 4: Create Reverse DNS Zone File
# Create reverse zone file
cat > /var/named/1.168.192.in-addr.arpa.zone << 'EOF'
$TTL 86400
@   IN  SOA     satellite.example.com. admin.example.com. (
        2023110801  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)

; Name servers
@               IN  NS      satellite.example.com.
@               IN  NS      capsule.example.com.

; PTR records
10              IN  PTR     satellite.example.com.
20              IN  PTR     capsule.example.com.
150             IN  PTR     test-server.example.com.
EOF
Step 5: Set Proper Permissions and Start DNS
# Set ownership and permissions
chown root:named /var/named/example.com.zone
chown root:named /var/named/1.168.192.in-addr.arpa.zone
chmod 640 /var/named/example.com.zone
chmod 640 /var/named/1.168.192.in-addr.arpa.zone

# Check configuration syntax
named-checkconf /etc/named.conf
named-checkzone example.com /var/named/example.com.zone
named-checkzone 1.168.192.in-addr.arpa /var/named/1.168.192.in-addr.arpa.zone

# Enable and start DNS service
systemctl enable named
systemctl start named
systemctl status named
Subtask 2.2: Integrate DNS with Satellite
Step 1: Configure Satellite DNS Proxy
# SSH to Satellite server
ssh root@satellite.example.com

# Configure DNS proxy
satellite-installer --scenario satellite \
  --foreman-proxy-dns true \
  --foreman-proxy-dns-managed true \
  --foreman-proxy-dns-provider nsupdate \
  --foreman-proxy-dns-server 192.168.1.20
Step 2: Verify DNS Integration
# Check DNS proxy status
hammer proxy info --name "satellite.example.com" | grep -i dns

# Test DNS resolution
nslookup satellite.example.com 192.168.1.20
nslookup capsule.example.com 192.168.1.20

# Test reverse DNS
nslookup 192.168.1.10 192.168.1.20
Subtask 2.3: Configure Dynamic DNS Updates
Step 1: Generate TSIG Key for Secure Updates
# Generate TSIG key
dnssec-keygen -a HMAC-MD5 -b 128 -n HOST satellite-key

# Extract key value
cat Ksatellite-key.*.key

# Create key file for named
cat > /etc/named.keys << 'EOF'
key "satellite-key" {
    algorithm hmac-md5;
    secret "generated-key-value-here";
};
EOF
Step 2: Update DNS Configuration for Dynamic Updates
# Update named.conf to include key and allow updates
cat >> /etc/named.conf << 'EOF'

include "/etc/named.keys";

// Update zone definitions to allow dynamic updates
zone "example.com" IN {
    type master;
    file "example.com.zone";
    allow-update { key "satellite-key"; };
};

zone "1.168.192.in-addr.arpa" IN {
    type master;
    file "1.168.192.in-addr.arpa.zone";
    allow-update { key "satellite-key"; };
};
EOF

# Restart named service
systemctl restart named
Task 3: Configuring PXE Booting for System Provisioning
Subtask 3.1: Install and Configure TFTP Server
Step 1: Install TFTP Server
# SSH to capsule server
ssh root@capsule.example.com

# Install TFTP server
dnf install -y tftp-server xinetd

# Verify installation
rpm -qa | grep tftp-server
Step 2: Configure TFTP Service
# Enable TFTP in xinetd
cat > /etc/xinetd.d/tftp << 'EOF'
service tftp
{
    socket_type     = dgram
    protocol        = udp
    wait            = yes
    user            = root
    server          = /usr/sbin/in.tftpd
    server_args     = -s /var/lib/tftpboot
    disable         = no
    per_source      = 11
    cps             = 100 2
    flags           = IPv4
}
EOF

# Create TFTP root directory
mkdir -p /var/lib/tftpboot
chmod 755 /var/lib/tftpboot

# Enable and start services
systemctl enable xinetd
systemctl start xinetd
systemctl status xinetd
Step 3: Configure PXE Boot Files
# Install syslinux for PXE boot files
dnf install -y syslinux

# Copy PXE boot files
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/
cp /usr/share/syslinux/menu.c32 /var/lib/tftpboot/
cp /usr/share/syslinux/memdisk /var/lib/tftpboot/
cp /usr/share/syslinux/mboot.c32 /var/lib/tftpboot/
cp /usr/share/syslinux/chain.c32 /var/lib/tftpboot/

# Create PXE configuration directory
mkdir -p /var/lib/tftpboot/pxelinux.cfg

# Create default PXE menu
cat > /var/lib/tftpboot/pxelinux.cfg/default << 'EOF'
DEFAULT menu.c32
PROMPT 0
TIMEOUT 300
ONTIMEOUT local

MENU TITLE Satellite PXE Boot Menu
MENU BACKGROUND pxelinux.cfg/splash.png

LABEL local
    MENU LABEL Boot from ^Local Drive
    MENU DEFAULT
    LOCALBOOT 0

LABEL rhel8
    MENU LABEL Install ^RHEL 8
    KERNEL images/rhel8/vmlinuz
    APPEND initrd=images/rhel8/initrd.img inst.repo=http://satellite.example.com/pulp/repos/Default_Organization/Library/content/dist/rhel8/8/x86_64/baseos/os/ inst.ks=http://satellite.example.com/unattended/provision

LABEL rescue
    MENU LABEL ^Rescue Mode
    KERNEL images/rhel8/vmlinuz
    APPEND initrd=images/rhel8/initrd.img rescue
EOF
Subtask 3.2: Configure Boot Images
Step 1: Create Boot Image Directories
# Create directory structure for boot images
mkdir -p /var/lib/tftpboot/images/rhel8
mkdir -p /var/lib/tftpboot/images/rhel9

# Set proper permissions
chmod -R 755 /var/lib/tftpboot/images
Step 2: Download and Configure Boot Images
# Mount RHEL 8 ISO (assuming it's available)
mkdir -p /mnt/rhel8-iso
mount -o loop /path/to/rhel8.iso /mnt/rhel8-iso

# Copy kernel and initrd
cp /mnt/rhel8-iso/images/pxeboot/vmlinuz /var/lib/tftpboot/images/rhel8/
cp /mnt/rhel8-iso/images/pxeboot/initrd.img /var/lib/tftpboot/images/rhel8/

# Unmount ISO
umount /mnt/rhel8-iso
Subtask 3.3: Integrate PXE with Satellite
Step 1: Configure Satellite TFTP Proxy
# SSH to Satellite server
ssh root@satellite.example.com

# Configure TFTP proxy
satellite-installer --scenario satellite \
  --foreman-proxy-tftp true \
  --foreman-proxy-tftp-managed true \
  --foreman-proxy-tftp-servername 192.168.1.20
Step 2: Configure PXE Templates in Satellite
# Create PXE template
hammer template create \
  --name "RHEL8 PXE Template" \
  --type "PXELinux" \
  --file /dev/stdin << 'EOF'
DEFAULT linux
LABEL linux
    KERNEL <%= @kernel %>
    APPEND initrd=<%= @initrd %> inst.repo=<%= @mediapath %> inst.ks=<%= foreman_url('provision') %> inst.stage2=<%= @mediapath %> quiet
IPAPPEND 2
EOF

# List available templates
hammer template list --search "PXE"
Step 3: Configure Host Groups for PXE Boot
# Update host group with PXE settings
hammer hostgroup update \
  --name "RHEL8-Servers" \
  --pxe-loader "PXELinux BIOS" \
  --operatingsystem "RedHat 8.6"

# Verify host group configuration
hammer hostgroup info --name "RHEL8-Servers"
Subtask 3.4: Configure Firewall Rules
Step 1: Configure Firewall on Capsule Server
# SSH to capsule server
ssh root@capsule.example.com

# Open required ports
firewall-cmd --permanent --add-service=dhcp
firewall-cmd --permanent --add-service=dns
firewall-cmd --permanent --add-service=tftp
firewall-cmd --permanent --add-port=69/udp
firewall-cmd --permanent --add-port=4011/udp

# Reload firewall
firewall-cmd --reload

# Verify rules
firewall-cmd --list-all
Step 2: Configure SELinux Contexts
# Set proper SELinux contexts
setsebool -P dhcpd_use_ldap on
setsebool -P named_write_master_zones on
restorecon -R /var/lib/tftpboot
restorecon -R /var/named

# Check SELinux status
getenforce
sestatus
Task 4: Testing Host Provisioning in Controlled Environment
Subtask 4.1: Create Test Virtual Machine
Step 1: Prepare Test Environment
# SSH to Satellite server
ssh root@satellite.example.com

# Create compute resource for local virtualization
hammer compute-resource create \
  --name "Local KVM" \
  --provider "Libvirt" \
  --url "qemu:///system"

# Verify compute resource
hammer compute-resource list
Step 2: Create Host Entry for Testing
# Create new host for provisioning
hammer host create \
  --name "test-provision.example.com" \
  --hostgroup "RHEL8-Servers" \
  --compute-resource "Local KVM" \
  --subnet "Production Network" \
  --domain "example.com" \
  --mac "52:54:00:12:34:57" \
  --ip "192.168.1.151" \
  --build true

# Verify host creation
hammer host list
Subtask 4.2: Test DHCP Functionality
Step 1: Verify DHCP Lease Assignment
# Check DHCP leases
cat /var/lib/dhcpd/dhcpd.leases

# Test DHCP with dhcping (if available)
# Or use a test client to request DHCP lease

# Monitor DHCP logs
tail -f /var/log/messages | grep dhcpd
Step 2: Validate DHCP Reservations
# Check specific host reservation
grep -A 5 "52:54:00:12:34:57" /etc/dhcp/dhcpd.conf

# Test DHCP response for specific MAC
# This would typically be done from a test client
Subtask 4.3: Test DNS Resolution
Step 1: Test Forward DNS Resolution
# Test DNS resolution from different hosts
nslookup satellite.example.com 192.168.1.20
nslookup capsule.example.com 192.168.1.20
nslookup test-server.example.com 192.168.1.20

# Test with dig command
dig @192.168.1.20 satellite.example.com
dig @192.168.1.20 example.com MX
Step 2: Test Reverse DNS Resolution
# Test reverse DNS lookups
nslookup 192.168.1.10 192.168.1.20
nslookup 192.168.1.20 192.168.1.20

# Test with dig
dig @192.168.1.20 -x 192.168.1.10
Subtask 4.4: Test PXE Boot Process
Step 1: Verify TFTP Service
# Test TFTP connectivity
tftp 192.168.1.20
> get pxelinux.0
> quit

# Check if file was downloaded
ls -la pxelinux.0

# Test from different client
echo "get pxelinux.0" | tftp 192.168.1.20
Step 2: Simulate PXE Boot
# Create test VM for PXE boot
virt-install \
  --name test-pxe-boot \
  --memory 2048 \
  --vcpus 2 \
  --disk size=20 \
  --network bridge=virbr0,mac=52:54:00:12:34:58 \
  --pxe \
  --graphics vnc \
  --noautoconsole

# Monitor the boot process
virsh console test-pxe-boot
Subtask 4.5: End-to-End Provisioning Test
Step 1: Create Complete Host Definition
# Create comprehensive host definition
hammer host create \
  --name "full-test.example.com" \
  --hostgroup "RHEL8-Servers" \
  --subnet "Production Network" \
  --domain "example.com" \
  --mac "52:54:00:12:34:59" \
  --ip "192.168.1.152" \
  --build true \
  --enabled true \
  --managed true \
  --provision-method "build"

# Generate PXE configuration
hammer host rebuild-config --name "full-test.example.com"
Step 2: Monitor Provisioning Process
# Check host build status
hammer host info --name "full-test.example.com"

# Monitor logs during provisioning
tail -f /var/log/foreman/production.log
tail -f /var/log/foreman-proxy/proxy.log

# Check DHCP and DNS logs
tail -f /var/log/messages | grep -E "(dhcpd|named)"
Subtask 4.6: Validation and Troubleshooting
Step 1: Validate Network Services
# Create validation script
cat > /root/validate-services.sh << 'EOF'
#!/bin/bash

echo "=== Network Services Validation ==="

# Test DHCP
echo "Testing DHCP service..."
systemctl is-active dhcpd
netstat -ulnp | grep :67

# Test DNS
echo "Testing DNS service..."
systemctl is-active named
netstat -ulnp | grep :53

# Test TFTP
echo "Testing TFTP service..."
systemctl is-active xinetd
netstat -ulnp | grep :69

# Test connectivity
echo "Testing service connectivity..."
nslookup satellite.example.com 192.168.1.20
echo "get pxelinux.0" | tftp 192.168.1.20

echo "=== Validation Complete ==="
EOF

chmod +x /root/validate-services.sh
/root/validate-services.sh
Step 2: Common Troubleshooting Steps
# Check service status
systemctl status dhcpd named xinetd

# Verify configuration files
named-checkconf /etc/named.conf
dhcpd -t -cf /etc/dhcp/dhcpd.conf

# Check firewall rules
firewall-cmd --list-all

# Verify SELinux contexts
ls -laZ /var/lib/tftpboot/
ls -laZ /var/named/

# Check logs for errors
journalctl -u dhcpd -f
journalctl -u named -f
Troubleshooting Common Issues
DHCP Issues
Problem: DHCP service fails to start Solution:

# Check configuration syntax
dhcpd -t -cf /etc/dhcp/dhcpd.conf

# Verify network interface
ip addr show

# Check for port conflicts
netstat -ulnp | grep :67
Problem: Clients not receiving DHCP leases Solution:

# Check DHCP logs
tail -f /var/log/messages | grep dhcpd

# Verify subnet configuration
grep -A 10 "subnet" /etc/dhcp/dhcpd.conf

# Check firewall rules
firewall-cmd --list-services | grep dhcp
DNS Issues
Problem: DNS queries not resolving Solution:

# Test DNS configuration
named-checkconf
named-checkzone example.com /var/named/example.com.zone

# Check DNS service status
systemctl status named

# Verify zone files
dig @localhost example.com SOA
Problem: Reverse DNS not working Solution:

# Check reverse zone configuration
named-checkzone 1.168.192.in-addr.arpa /var/named/1.168.192.in-addr.arpa.zone

# Test reverse lookup
dig @192.168.1.20 -x 192.168.1.10
PXE Boot Issues
Problem: PXE boot fails to start Solution:

# Verify TFTP service
systemctl status xinetd
tftp 192.168.1.20 -c get pxelinux.0

# Check boot files
ls -la /var/lib/tftpboot/
ls -la /var/lib/tftpboot/pxelinux.cfg/
Problem: Boot images not found Solution:

# Verify image paths
ls -la /var/lib/tftpboot/images/rhel8/

# Check PXE configuration
cat /var/lib/tftpboot/pxelinux.cfg/default

# Verify file permissions
chmod -R 755 /var/lib/tftpboot/
Conclusion
In this comprehensive lab, you have successfully configured the essential network resources required for automated host provisioning using Red Hat Satellite. Here's what you accomplished:

Key Achievements
DHCP Configuration: You set up a fully functional DHCP server that automatically assigns IP addresses to new hosts, configured reservations for known systems, and integrated it with Red Hat Satellite for centralized management.

DNS Services: You implemented both forward and reverse DNS resolution, created zone files for your domain, and configured dynamic DNS updates to support automated host registration.

PXE Boot Environment: You established a complete PXE boot infrastructure including TFTP services, boot images, and menu configurations that enable network-based system provisioning.

Service Integration: You successfully integrated all network services with Red Hat Satellite, creating a seamless provisioning workflow that automates the entire host deployment process.

Testing and Validation: You performed comprehensive testing of each service component and validated the complete end-to-end provisioning workflow.

Why This Matters
The network infrastructure you've configured forms the foundation of modern automated data center operations. These skills are essential because:

Scalability: Automated provisioning allows organizations to deploy hundreds or thousands of systems efficiently
Consistency: Standardized network configurations ensure reliable and predictable deployments
Efficiency: Reduces manual intervention and human error in system deployment processes
Compliance: Centralized management helps maintain security and compliance standards across the infrastructure
Real-World Applications
The configuration you've completed mirrors enterprise environments where:

Cloud providers automate virtual machine provisioning
Data centers deploy bare-metal servers at scale
Development teams provision test environments on-demand
Disaster recovery procedures require rapid system restoration
Next Steps
With this foundation in place, you're prepared to:

Configure advanced provisioning templates and kickstart files
Implement configuration management with Puppet or Ansible
Set up monitoring and logging for provisioned systems
Explore container and cloud-native deployment strategies
This lab has provided you with practical, hands-on experience with the core technologies that power modern infrastructure automation, preparing you for advanced Red Hat Satellite administration and enterprise system management roles.
