Lab 14: Troubleshooting Network Connectivity
Objectives
By the end of this lab, students will be able to:

• Test network connectivity using ping, traceroute, and nslookup commands • Understand how to interpret network diagnostic output • Use nmcli to view and manage network configurations • Configure and manage firewall rules using firewalld • Troubleshoot common network connectivity issues in Linux environments • Apply systematic approaches to network problem resolution

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Familiarity with terminal navigation and file editing • Basic knowledge of networking concepts (IP addresses, DNS, ports) • Understanding of Linux file permissions and system administration basics

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes: • CentOS/RHEL-based Linux system with network tools pre-installed • Root access for system configuration • Internet connectivity for testing external connections • Pre-configured network interfaces

Task 1: Testing Network Connectivity with Basic Tools
Subtask 1.1: Using the ping Command
The ping command is the most basic tool for testing network connectivity. It sends ICMP echo requests to a target host.

Step 1: Test Local Connectivity
First, let's test connectivity to the local machine:

ping -c 4 127.0.0.1
Expected Output:

PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.045 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.037 ms
64 bytes from 127.0.0.1: icmp_seq=3 ttl=64 time=0.039 ms
64 bytes from 127.0.0.1: icmp_seq=4 ttl=64 time=0.041 ms
Step 2: Test Gateway Connectivity
Check your default gateway:

ip route show default
Then ping your gateway (replace with your actual gateway IP):

ping -c 4 192.168.1.1
Step 3: Test External Connectivity
Test connectivity to external servers:

# Test Google's public DNS
ping -c 4 8.8.8.8

# Test a domain name
ping -c 4 google.com
Subtask 1.2: Using the traceroute Command
Traceroute shows the path packets take to reach a destination, helping identify where connectivity issues occur.

Step 1: Install traceroute (if not already installed)
# For RHEL/CentOS systems
sudo yum install -y traceroute

# For newer systems using dnf
sudo dnf install -y traceroute
Step 2: Trace Route to External Host
traceroute google.com
Understanding the Output: Each line represents a hop (router) in the path. The three time values show round-trip times for three test packets.

Step 3: Trace Route with IP Addresses
traceroute -n 8.8.8.8
The -n flag prevents DNS lookups, showing only IP addresses for faster results.

Subtask 1.3: Using the nslookup Command
Nslookup is used for DNS troubleshooting and domain name resolution testing.

Step 1: Basic DNS Lookup
nslookup google.com
Step 2: Reverse DNS Lookup
nslookup 8.8.8.8
Step 3: Query Specific DNS Record Types
# Query MX records (mail servers)
nslookup -type=MX google.com

# Query NS records (name servers)
nslookup -type=NS google.com
Step 4: Use Specific DNS Server
nslookup google.com 8.8.8.8
Task 2: Managing Network Configurations with nmcli
NetworkManager Command Line Interface (nmcli) is the primary tool for managing network connections in modern Linux systems.

Subtask 2.1: Viewing Current Network Status
Step 1: Check NetworkManager Status
nmcli general status
Step 2: List All Network Devices
nmcli device status
Step 3: Show Detailed Device Information
nmcli device show
Subtask 2.2: Managing Network Connections
Step 1: List All Connections
nmcli connection show
Step 2: Show Active Connections
nmcli connection show --active
Step 3: View Detailed Connection Information
Replace connection-name with an actual connection name from your system:

nmcli connection show "System eth0"
Subtask 2.3: Modifying Network Settings
Step 1: Change DNS Settings
# Add a DNS server to existing connection
sudo nmcli connection modify "System eth0" ipv4.dns "8.8.8.8,8.8.4.4"

# Apply the changes
sudo nmcli connection up "System eth0"
Step 2: Set Static IP Address
# Configure static IP (replace with appropriate values)
sudo nmcli connection modify "System eth0" ipv4.addresses "192.168.1.100/24"
sudo nmcli connection modify "System eth0" ipv4.gateway "192.168.1.1"
sudo nmcli connection modify "System eth0" ipv4.method manual

# Restart the connection
sudo nmcli connection up "System eth0"
Step 3: Revert to DHCP
sudo nmcli connection modify "System eth0" ipv4.method auto
sudo nmcli connection up "System eth0"
Subtask 2.4: Creating New Network Connections
Step 1: Create a New Ethernet Connection
sudo nmcli connection add type ethernet con-name "lab-connection" ifname eth0
Step 2: Configure the New Connection
sudo nmcli connection modify "lab-connection" ipv4.addresses "192.168.1.150/24"
sudo nmcli connection modify "lab-connection" ipv4.gateway "192.168.1.1"
sudo nmcli connection modify "lab-connection" ipv4.dns "8.8.8.8"
sudo nmcli connection modify "lab-connection" ipv4.method manual
Step 3: Activate the New Connection
sudo nmcli connection up "lab-connection"
Task 3: Configuring Firewall Rules with firewalld
Firewalld is the default firewall management tool in RHEL/CentOS systems, providing dynamic firewall management.

Subtask 3.1: Understanding Firewalld Basics
Step 1: Check Firewalld Status
sudo systemctl status firewalld
If firewalld is not running, start it:

sudo systemctl start firewalld
sudo systemctl enable firewalld
Step 2: View Current Firewall Configuration
# Show default zone
sudo firewall-cmd --get-default-zone

# List all zones
sudo firewall-cmd --get-zones

# Show active zones
sudo firewall-cmd --get-active-zones
Step 3: View Zone Configuration
# Show configuration for default zone
sudo firewall-cmd --list-all

# Show configuration for specific zone
sudo firewall-cmd --zone=public --list-all
Subtask 3.2: Managing Firewall Services
Step 1: List Available Services
sudo firewall-cmd --get-services
Step 2: Add Services to Firewall
# Allow HTTP traffic
sudo firewall-cmd --zone=public --add-service=http --permanent

# Allow HTTPS traffic
sudo firewall-cmd --zone=public --add-service=https --permanent

# Allow SSH (usually already enabled)
sudo firewall-cmd --zone=public --add-service=ssh --permanent
Step 3: Reload Firewall Configuration
sudo firewall-cmd --reload
Step 4: Verify Services Are Added
sudo firewall-cmd --zone=public --list-services
Subtask 3.3: Managing Firewall Ports
Step 1: Open Specific Ports
# Open port 8080 for TCP traffic
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent

# Open port 53 for UDP traffic (DNS)
sudo firewall-cmd --zone=public --add-port=53/udp --permanent

# Open a range of ports
sudo firewall-cmd --zone=public --add-port=3000-3005/tcp --permanent
Step 2: Reload and Verify
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-ports
Step 3: Remove Ports
# Remove a specific port
sudo firewall-cmd --zone=public --remove-port=8080/tcp --permanent
sudo firewall-cmd --reload
Subtask 3.4: Advanced Firewall Configuration
Step 1: Create Custom Service
Create a custom service definition:

sudo firewall-cmd --permanent --new-service=myapp
Configure the service:

sudo firewall-cmd --permanent --service=myapp --set-description="My Custom Application"
sudo firewall-cmd --permanent --service=myapp --set-short="MyApp"
sudo firewall-cmd --permanent --service=myapp --add-port=9090/tcp
Step 2: Add Custom Service to Zone
sudo firewall-cmd --zone=public --add-service=myapp --permanent
sudo firewall-cmd --reload
Step 3: Configure Rich Rules
Rich rules provide more granular control:

# Allow specific IP to access SSH
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.100" service name="ssh" accept' --permanent

# Block specific IP from accessing HTTP
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.200" service name="http" drop' --permanent

sudo firewall-cmd --reload
Practical Troubleshooting Scenarios
Scenario 1: Cannot Reach External Websites
Problem: User reports inability to browse websites.

Troubleshooting Steps:

Test local connectivity:
ping 127.0.0.1
Test gateway connectivity:
ip route show default
ping -c 4 [gateway-ip]
Test DNS resolution:
nslookup google.com
Test external connectivity:
ping -c 4 8.8.8.8
Scenario 2: Service Not Accessible
Problem: Web service running on port 8080 is not accessible from other machines.

Troubleshooting Steps:

Verify service is running:
sudo netstat -tlnp | grep 8080
Check firewall rules:
sudo firewall-cmd --list-all
Add firewall rule if needed:
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
Scenario 3: DNS Resolution Issues
Problem: Cannot resolve domain names but can ping IP addresses.

Troubleshooting Steps:

Check DNS configuration:
cat /etc/resolv.conf
Test different DNS servers:
nslookup google.com 8.8.8.8
nslookup google.com 1.1.1.1
Update DNS settings:
sudo nmcli connection modify "System eth0" ipv4.dns "8.8.8.8,8.8.4.4"
sudo nmcli connection up "System eth0"
Common Issues and Troubleshooting Tips
Network Interface Issues
Problem: Network interface is down Solution:

# Check interface status
nmcli device status

# Bring interface up
sudo nmcli device connect eth0
Firewall Blocking Connections
Problem: Connections are being blocked unexpectedly Solution:

# Check firewall logs
sudo journalctl -u firewalld -f

# Temporarily disable firewall for testing
sudo systemctl stop firewalld
DNS Cache Issues
Problem: Old DNS records are cached Solution:

# Flush DNS cache (if systemd-resolved is used)
sudo systemd-resolve --flush-caches

# Restart NetworkManager
sudo systemctl restart NetworkManager
Verification and Testing
Test Your Configuration
Connectivity Test:
ping -c 4 google.com
traceroute google.com
DNS Test:
nslookup google.com
nslookup -type=MX google.com
Firewall Test:
sudo firewall-cmd --list-all
sudo nmap -p 22,80,443 localhost
Network Configuration Test:
nmcli connection show --active
ip addr show
ip route show
Conclusion
In this lab, you have successfully learned how to troubleshoot network connectivity issues using essential Linux networking tools. You've mastered the use of ping, traceroute, and nslookup for diagnosing connectivity problems, learned to manage network configurations with nmcli, and configured firewall rules using firewalld.

Key Accomplishments
• Network Diagnostics: You can now systematically diagnose network connectivity issues using command-line tools • Network Management: You understand how to view, modify, and create network connections using NetworkManager • Firewall Configuration: You can configure and manage firewall rules to control network access • Troubleshooting Methodology: You've learned a systematic approach to network problem resolution

Why This Matters
Network troubleshooting skills are essential for system administrators because:

• Critical Infrastructure: Networks are the backbone of modern IT infrastructure • Problem Resolution: Quick identification and resolution of network issues minimizes downtime • Security: Proper firewall configuration protects systems from unauthorized access • Performance: Understanding network tools helps optimize system performance

These skills directly prepare you for the Red Hat Certified System Administrator certification and real-world system administration scenarios where network connectivity issues are common and must be resolved quickly and efficiently.

Next Steps
Continue practicing these commands in different scenarios and explore advanced networking topics such as: • Network bonding and teaming • VLAN configuration • Advanced firewall rules and zones • Network monitoring and performance analysis
