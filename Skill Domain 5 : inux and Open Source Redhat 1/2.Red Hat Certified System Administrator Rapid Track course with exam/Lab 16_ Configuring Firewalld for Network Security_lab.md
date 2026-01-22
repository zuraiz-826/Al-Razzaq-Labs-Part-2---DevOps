Lab 16: Configuring Firewalld for Network Security
Objectives
By the end of this lab, students will be able to:

• Understand the fundamentals of firewalld and its role in Linux network security • Install and configure firewalld service on a Linux system • Create and manage firewall rules using firewalld commands • Configure firewall zones and assign network interfaces to appropriate zones • Manage services and ports within firewall zones • Test firewall configurations to ensure proper network security • Implement secure communication policies using firewalld zones and services • Troubleshoot common firewall configuration issues

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Familiarity with network concepts (IP addresses, ports, protocols) • Knowledge of basic Linux system administration commands • Understanding of network services (SSH, HTTP, HTTPS, FTP) • Basic knowledge of TCP/IP networking fundamentals

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install any software.

Your lab environment includes: • CentOS/RHEL 8 or 9 system with root access • Pre-installed firewalld package • Network connectivity for testing • Multiple network interfaces for zone configuration

Task 1: Create Firewall Rules Using Firewalld
Subtask 1.1: Install and Start Firewalld Service
First, let's ensure firewalld is installed and running on your system.

Check if firewalld is installed:
rpm -qa | grep firewalld
Install firewalld if not present:
sudo dnf install firewalld -y
Start and enable firewalld service:
sudo systemctl start firewalld
sudo systemctl enable firewalld
Verify firewalld status:
sudo systemctl status firewalld
sudo firewall-cmd --state
Subtask 1.2: Understanding Firewalld Basics
Check current firewall configuration:
sudo firewall-cmd --list-all
View all available zones:
sudo firewall-cmd --get-zones
Check the default zone:
sudo firewall-cmd --get-default-zone
List active zones:
sudo firewall-cmd --get-active-zones
Subtask 1.3: Create Basic Firewall Rules
Allow HTTP service temporarily:
sudo firewall-cmd --add-service=http
Allow HTTP service permanently:
sudo firewall-cmd --add-service=http --permanent
Allow HTTPS service permanently:
sudo firewall-cmd --add-service=https --permanent
Allow specific port (example: port 8080):
sudo firewall-cmd --add-port=8080/tcp --permanent
Allow port range (example: ports 3000-3005):
sudo firewall-cmd --add-port=3000-3005/tcp --permanent
Reload firewall to apply permanent changes:
sudo firewall-cmd --reload
Verify the rules are active:
sudo firewall-cmd --list-all
Subtask 1.4: Create Advanced Firewall Rules
Allow traffic from specific IP address:
sudo firewall-cmd --add-source=192.168.1.100 --permanent
Allow traffic from specific subnet:
sudo firewall-cmd --add-source=192.168.1.0/24 --permanent
Block traffic from specific IP address:
sudo firewall-cmd --add-rich-rule='rule source address="192.168.1.50" drop' --permanent
Allow specific service from specific IP:
sudo firewall-cmd --add-rich-rule='rule source address="192.168.1.100" service name="ssh" accept' --permanent
Reload and verify configuration:
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
Task 2: Test Firewall Configuration
Subtask 2.1: Install Testing Tools
Install network testing utilities:
sudo dnf install nmap telnet nc -y
Install web server for testing:
sudo dnf install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
Create a simple test web page:
echo "<h1>Firewall Test Page</h1>" | sudo tee /var/www/html/index.html
Subtask 2.2: Test HTTP/HTTPS Access
Test HTTP access locally:
curl http://localhost
Test from another terminal or machine (if available):
curl http://[YOUR_SERVER_IP]
Check if port 80 is accessible:
nmap -p 80 localhost
Test port 8080 accessibility:
telnet localhost 8080
Subtask 2.3: Test SSH Access
Verify SSH service is allowed:
sudo firewall-cmd --list-services | grep ssh
Test SSH connection locally:
ssh localhost
Check SSH port accessibility:
nmap -p 22 localhost
Subtask 2.4: Test Blocked Ports
Try to access a blocked port:
telnet localhost 3306
Scan for open ports:
nmap localhost
Test connection timeout on blocked services:
nc -zv localhost 3306
Task 3: Set Up Zones and Services for Secure Communication
Subtask 3.1: Understanding and Managing Zones
List all available zones with details:
sudo firewall-cmd --list-all-zones
Get information about specific zones:
sudo firewall-cmd --zone=public --list-all
sudo firewall-cmd --zone=internal --list-all
sudo firewall-cmd --zone=dmz --list-all
Create a custom zone:
sudo firewall-cmd --new-zone=webserver --permanent
sudo firewall-cmd --reload
Verify the new zone was created:
sudo firewall-cmd --get-zones
Subtask 3.2: Configure Custom Zone
Configure the webserver zone:
sudo firewall-cmd --zone=webserver --add-service=http --permanent
sudo firewall-cmd --zone=webserver --add-service=https --permanent
sudo firewall-cmd --zone=webserver --add-service=ssh --permanent
Add custom port to webserver zone:
sudo firewall-cmd --zone=webserver --add-port=8080/tcp --permanent
Set description for the zone:
sudo firewall-cmd --zone=webserver --set-description="Web Server Zone for HTTP/HTTPS traffic" --permanent
Reload and verify configuration:
sudo firewall-cmd --reload
sudo firewall-cmd --zone=webserver --list-all
Subtask 3.3: Assign Network Interfaces to Zones
Check current network interfaces:
ip addr show
Check which zone interfaces are assigned to:
sudo firewall-cmd --get-active-zones
Assign interface to custom zone (replace eth0 with your interface name):
sudo firewall-cmd --zone=webserver --change-interface=eth0 --permanent
Verify interface assignment:
sudo firewall-cmd --get-active-zones
Subtask 3.4: Configure Internal Zone for Secure Communication
Configure internal zone for trusted network:
sudo firewall-cmd --zone=internal --add-service=ssh --permanent
sudo firewall-cmd --zone=internal --add-service=samba --permanent
sudo firewall-cmd --zone=internal --add-service=nfs --permanent
Add trusted source networks to internal zone:
sudo firewall-cmd --zone=internal --add-source=192.168.1.0/24 --permanent
sudo firewall-cmd --zone=internal --add-source=10.0.0.0/8 --permanent
Configure DMZ zone for semi-trusted services:
sudo firewall-cmd --zone=dmz --add-service=http --permanent
sudo firewall-cmd --zone=dmz --add-service=https --permanent
sudo firewall-cmd --zone=dmz --add-port=8080/tcp --permanent
Reload and verify all zone configurations:
sudo firewall-cmd --reload
sudo firewall-cmd --zone=internal --list-all
sudo firewall-cmd --zone=dmz --list-all
Subtask 3.5: Create Rich Rules for Advanced Security
Allow SSH only from specific subnet:
sudo firewall-cmd --add-rich-rule='rule source address="192.168.1.0/24" service name="ssh" accept' --permanent
Block all traffic except from trusted sources:
sudo firewall-cmd --zone=internal --add-rich-rule='rule source address="0.0.0.0/0" drop' --permanent
sudo firewall-cmd --zone=internal --add-rich-rule='rule source address="192.168.1.0/24" accept' --permanent
Rate limit SSH connections:
sudo firewall-cmd --add-rich-rule='rule service name="ssh" accept limit value="3/m"' --permanent
Log dropped packets:
sudo firewall-cmd --add-rich-rule='rule drop log prefix="FIREWALL-DROP: " level="warning"' --permanent
Apply and verify rich rules:
sudo firewall-cmd --reload
sudo firewall-cmd --list-rich-rules
Subtask 3.6: Test Zone-Based Security
Test access from different zones:
# Test public zone access
sudo firewall-cmd --zone=public --list-services

# Test internal zone access
sudo firewall-cmd --zone=internal --list-services
Simulate traffic from different sources:
# Test with nmap from localhost
nmap -p 22,80,443 localhost

# Check firewall logs
sudo journalctl -u firewalld -f
Verify zone assignments are working:
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all-zones | grep -A 10 "webserver"
Troubleshooting Common Issues
Issue 1: Firewalld Service Not Starting
Problem: Firewalld fails to start Solution:

# Check for conflicting services
sudo systemctl status iptables
sudo systemctl stop iptables
sudo systemctl disable iptables

# Restart firewalld
sudo systemctl restart firewalld
Issue 2: Rules Not Taking Effect
Problem: Firewall rules are not working Solution:

# Ensure you reload after permanent changes
sudo firewall-cmd --reload

# Check if rules are in permanent configuration
sudo firewall-cmd --list-all --permanent
Issue 3: Cannot Access Services
Problem: Services are blocked unexpectedly Solution:

# Check current zone and services
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --list-services

# Verify interface zone assignment
sudo firewall-cmd --get-active-zones
Issue 4: Zone Configuration Problems
Problem: Custom zones not working properly Solution:

# Verify zone exists
sudo firewall-cmd --get-zones

# Check zone configuration
sudo firewall-cmd --zone=ZONENAME --list-all

# Reload configuration
sudo firewall-cmd --reload
Verification Commands
Use these commands to verify your firewall configuration:

# Check firewalld status
sudo systemctl status firewalld
sudo firewall-cmd --state

# List all current rules
sudo firewall-cmd --list-all

# Check specific zone
sudo firewall-cmd --zone=ZONENAME --list-all

# View rich rules
sudo firewall-cmd --list-rich-rules

# Check active zones
sudo firewall-cmd --get-active-zones

# Test port accessibility
nmap -p PORT localhost
telnet localhost PORT
Conclusion
In this lab, you have successfully:

• Installed and configured firewalld on a Linux system, establishing the foundation for network security management • Created comprehensive firewall rules including basic service allowances, port configurations, and IP-based restrictions • Tested firewall configurations using various network tools to ensure rules are working as expected • Implemented zone-based security by creating custom zones, assigning network interfaces, and configuring zone-specific rules • Applied advanced security policies using rich rules for granular control over network traffic

Why This Matters: Firewalld is a critical component of Linux system security, especially for servers and systems exposed to networks. The zone-based approach provides flexible security policies that can adapt to different network environments. Understanding firewalld configuration is essential for:

System Administrators managing Linux servers in production environments
Security Professionals implementing network security policies
Red Hat Certification candidates preparing for RHCSA examinations
DevOps Engineers securing containerized and cloud-based applications
The skills learned in this lab form the foundation for advanced network security topics and are directly applicable to real-world Linux system administration scenarios. Proper firewall configuration is often the first line of defense against network-based attacks and unauthorized access attempts.
