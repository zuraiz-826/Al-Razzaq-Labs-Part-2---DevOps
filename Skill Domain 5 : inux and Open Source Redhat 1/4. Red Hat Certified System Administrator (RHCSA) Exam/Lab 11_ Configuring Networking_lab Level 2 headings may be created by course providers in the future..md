Lab 11: Configuring Networking
Objectives
By the end of this lab, students will be able to:

Configure network interfaces using modern Linux networking tools
Assign static and dynamic IP addresses using nmcli command-line interface
Modify system hostname using hostnamectl for proper network identification
Test network connectivity using essential diagnostic tools (ping, traceroute, nslookup)
Understand the relationship between network configuration and system administration
Troubleshoot basic network connectivity issues in Linux environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command-line interface
Familiarity with text editors (nano, vim, or gedit)
Understanding of basic networking concepts (IP addresses, subnets, DNS)
Knowledge of file permissions and sudo privileges
Completion of previous labs covering basic Linux system administration
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment - no need to build your own virtual machine or configure complex networking setups.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with NetworkManager installed
Root or sudo access for network configuration
Internet connectivity for testing external connections
Pre-installed networking diagnostic tools
Task 1: Assign IP Addresses Using nmcli
NetworkManager Command Line Interface (nmcli) is the modern way to manage network connections in Red Hat-based systems. This task will teach you how to configure network interfaces professionally.

Subtask 1.1: Explore Current Network Configuration
First, let's examine the current network setup to understand what we're working with.

# Check current network connections
nmcli connection show

# Display detailed information about network devices
nmcli device status

# Show current IP configuration
ip addr show
Expected Output Analysis:

Connection names (usually like "System eth0" or "Wired connection 1")
Device states (connected, disconnected, unavailable)
Current IP addresses and network interfaces
Subtask 1.2: Create a New Network Connection Profile
Now we'll create a new connection profile with a static IP address configuration.

# Create a new connection profile with static IP
sudo nmcli connection add \
    type ethernet \
    con-name "lab-static-connection" \
    ifname eth0 \
    ip4 192.168.1.100/24 \
    gw4 192.168.1.1

# Set DNS servers for the connection
sudo nmcli connection modify "lab-static-connection" \
    ipv4.dns "8.8.8.8,8.8.4.4"

# Set the connection to manual (static) mode
sudo nmcli connection modify "lab-static-connection" \
    ipv4.method manual
Command Breakdown:

type ethernet: Specifies this is an Ethernet connection
con-name: Assigns a friendly name to the connection
ifname eth0: Specifies which network interface to use
ip4: Sets the IPv4 address with subnet mask
gw4: Sets the default gateway
Subtask 1.3: Activate the New Connection
# Activate the new connection profile
sudo nmcli connection up "lab-static-connection"

# Verify the connection is active
nmcli connection show --active

# Check the new IP configuration
ip addr show eth0
Subtask 1.4: Alternative Method Using ifconfig (Legacy Support)
While nmcli is preferred, understanding ifconfig is valuable for older systems or specific scenarios.

# Install net-tools if not available (contains ifconfig)
sudo yum install net-tools -y

# Assign IP address using ifconfig (temporary assignment)
sudo ifconfig eth0 192.168.1.101 netmask 255.255.255.0

# Add default gateway
sudo route add default gw 192.168.1.1

# Verify configuration
ifconfig eth0
route -n
Important Note: ifconfig changes are temporary and will be lost after reboot. Use nmcli for permanent configurations.

Task 2: Modify Hostname with hostnamectl
The hostname is crucial for network identification and many services depend on proper hostname configuration.

Subtask 2.1: Check Current Hostname Configuration
# Display current hostname information
hostnamectl status

# Show just the hostname
hostname

# Display hostname resolution
cat /etc/hostname
Subtask 2.2: Set a New Hostname
# Set a new static hostname
sudo hostnamectl set-hostname "lab-server-01"

# Verify the change
hostnamectl status

# Check that the change persists
cat /etc/hostname
Subtask 2.3: Configure Hostname Resolution
# Add hostname to local hosts file for proper resolution
sudo bash -c 'echo "127.0.0.1 lab-server-01" >> /etc/hosts'

# Verify the hosts file
cat /etc/hosts

# Test hostname resolution
nslookup lab-server-01
Subtask 2.4: Set Additional Hostname Properties
# Set pretty hostname (descriptive name)
sudo hostnamectl set-hostname "Lab Server 01" --pretty

# Set deployment environment
sudo hostnamectl set-deployment "development"

# Set location information
sudo hostnamectl set-location "Training Lab"

# View all hostname properties
hostnamectl status
Task 3: Test Network Connectivity
Network testing is essential for verifying configuration and troubleshooting connectivity issues.

Subtask 3.1: Basic Connectivity Testing with ping
The ping command tests basic network connectivity using ICMP packets.

# Test connectivity to local gateway
ping -c 4 192.168.1.1

# Test connectivity to external DNS server
ping -c 4 8.8.8.8

# Test connectivity to external website
ping -c 4 google.com

# Continuous ping (stop with Ctrl+C)
ping google.com
Command Options Explained:

-c 4: Send only 4 packets then stop
Without -c: Continuous ping until manually stopped
Subtask 3.2: Advanced Connectivity Testing with traceroute
Traceroute shows the path packets take to reach their destination, helping identify where connectivity issues occur.

# Install traceroute if not available
sudo yum install traceroute -y

# Trace route to external website
traceroute google.com

# Trace route to specific IP address
traceroute 8.8.8.8

# Use UDP traceroute (alternative method)
traceroute -U google.com
Understanding Traceroute Output:

Each line represents a network hop
Three time measurements show round-trip times
Asterisks (*) indicate timeouts or blocked responses
Subtask 3.3: DNS Resolution Testing with nslookup
DNS resolution is critical for translating domain names to IP addresses.

# Basic DNS lookup
nslookup google.com

# Lookup specific record types
nslookup -type=MX google.com

# Use specific DNS server
nslookup google.com 8.8.8.8

# Reverse DNS lookup
nslookup 8.8.8.8

# Interactive mode for multiple queries
nslookup
> google.com
> facebook.com
> exit
Subtask 3.4: Additional Network Diagnostic Tools
# Install additional network tools
sudo yum install bind-utils wget curl -y

# Use dig for advanced DNS queries
dig google.com

# Test HTTP connectivity
curl -I http://google.com

# Download test to check bandwidth
wget --spider http://google.com

# Check listening ports
ss -tuln

# Display network statistics
netstat -i
Comprehensive Network Configuration Script
Here's a complete script that combines all the tasks for easy deployment:

#!/bin/bash
# Network Configuration Lab Script

echo "=== Network Configuration Lab Script ==="

# Task 1: Configure Network Interface
echo "Configuring network interface..."
sudo nmcli connection add \
    type ethernet \
    con-name "lab-connection" \
    ifname eth0 \
    ip4 192.168.1.150/24 \
    gw4 192.168.1.1

sudo nmcli connection modify "lab-connection" \
    ipv4.dns "8.8.8.8,8.8.4.4" \
    ipv4.method manual

sudo nmcli connection up "lab-connection"

# Task 2: Set Hostname
echo "Setting hostname..."
sudo hostnamectl set-hostname "lab-network-server"
sudo bash -c 'echo "127.0.0.1 lab-network-server" >> /etc/hosts'

# Task 3: Test Connectivity
echo "Testing network connectivity..."
echo "Testing local gateway..."
ping -c 2 192.168.1.1

echo "Testing external DNS..."
ping -c 2 8.8.8.8

echo "Testing domain resolution..."
nslookup google.com

echo "=== Lab Configuration Complete ==="
Troubleshooting Common Issues
Issue 1: Network Interface Not Found
Problem: Error message "Device 'eth0' not found"

Solution:

# List available network interfaces
nmcli device status

# Use the correct interface name (might be ens33, enp0s3, etc.)
ip link show
Issue 2: DNS Resolution Failures
Problem: nslookup or ping to domain names fails

Solution:

# Check DNS configuration
cat /etc/resolv.conf

# Manually set DNS servers
sudo nmcli connection modify "connection-name" ipv4.dns "8.8.8.8,8.8.4.4"

# Restart NetworkManager
sudo systemctl restart NetworkManager
Issue 3: Permission Denied Errors
Problem: Cannot modify network settings

Solution:

# Ensure you have sudo privileges
sudo -l

# Add user to network management group
sudo usermod -a -G wheel username
Issue 4: Changes Don't Persist After Reboot
Problem: Network configuration lost after system restart

Solution:

# Ensure connection is set to autoconnect
sudo nmcli connection modify "connection-name" connection.autoconnect yes

# Verify autoconnect setting
nmcli connection show "connection-name" | grep autoconnect
Verification and Testing Checklist
Use this checklist to verify your lab completion:

 Successfully created a new network connection using nmcli
 Assigned static IP address to network interface
 Changed system hostname using hostnamectl
 Verified hostname persists after configuration
 Successfully pinged local gateway
 Successfully pinged external IP address
 Successfully pinged external domain name
 Traced network route using traceroute
 Performed DNS lookup using nslookup
 Verified all network services are functioning
Conclusion
Congratulations! You have successfully completed Lab 11: Configuring Networking. In this lab, you have accomplished several critical network administration tasks:

Key Achievements:

Modern Network Management: You learned to use nmcli, the current standard for network configuration in Red Hat-based systems, moving beyond legacy tools to industry-standard practices.

Static IP Configuration: You successfully configured static IP addresses, which is essential for servers and critical infrastructure that require consistent network addressing.

Hostname Management: You properly configured system hostname using hostnamectl, ensuring your system has proper network identity for services and network communication.

Network Diagnostics: You mastered essential network troubleshooting tools (ping, traceroute, nslookup) that are fundamental for identifying and resolving connectivity issues.

Why This Matters:

Network configuration is a cornerstone skill for system administrators. In real-world scenarios, you'll need these skills to:

Set up servers in data centers with specific IP requirements
Troubleshoot connectivity issues affecting business operations
Configure systems for proper DNS resolution and network communication
Ensure systems maintain consistent network identity across reboots
RHCSA Exam Relevance:

This lab directly prepares you for RHCSA exam objectives related to network configuration and troubleshooting. The skills you've practiced are frequently tested and are essential for day-to-day system administration tasks.

Next Steps:

Consider exploring advanced networking topics such as:

Network bonding and teaming
VLAN configuration
Firewall management with firewalld
Network security and access controls
You now have the foundational networking skills necessary for effective Linux system administration and are well-prepared for the networking components of the RHCSA certification exam.
