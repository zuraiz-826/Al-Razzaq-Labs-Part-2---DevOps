Lab 12: Managing Firewall with firewalld
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of firewalld and its architecture
Configure firewall rules using firewalld command-line tools
Manage firewall zones and assign network interfaces to appropriate zones
Configure services and ports for different zones
Test and validate firewall configurations
Troubleshoot common firewall issues
Implement security best practices using firewalld
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line interface
Knowledge of network concepts (IP addresses, ports, protocols)
Familiarity with systemd services
Understanding of basic security concepts
Access to a Linux system with root or sudo privileges
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with firewalld pre-installed
Root access via sudo
Network connectivity for testing
All necessary tools and utilities
Task 1: Configure Firewall Rules Using firewalld
Subtask 1.1: Understanding firewalld Basics
First, let's explore the current state of firewalld and understand its basic concepts.

Step 1: Check if firewalld is running

sudo systemctl status firewalld
Step 2: If firewalld is not running, start and enable it

sudo systemctl start firewalld
sudo systemctl enable firewalld
Step 3: Verify firewalld is active

sudo firewall-cmd --state
Step 4: Display current firewall configuration

sudo firewall-cmd --list-all
Expected Output: You should see the default zone configuration with allowed services and ports.

Subtask 1.2: Working with Basic Firewall Rules
Step 1: Check the default zone

sudo firewall-cmd --get-default-zone
Step 2: List all available zones

sudo firewall-cmd --get-zones
Step 3: View detailed information about the public zone

sudo firewall-cmd --zone=public --list-all
Step 4: Add a service to the current default zone (temporary rule)

sudo firewall-cmd --add-service=http
Step 5: Verify the service was added

sudo firewall-cmd --list-services
Step 6: Make the rule permanent

sudo firewall-cmd --add-service=http --permanent
Step 7: Reload firewall to apply permanent rules

sudo firewall-cmd --reload
Subtask 1.3: Managing Ports and Protocols
Step 1: Add a specific port (temporary)

sudo firewall-cmd --add-port=8080/tcp
Step 2: Add multiple ports at once

sudo firewall-cmd --add-port=3000-3005/tcp
Step 3: Make port rules permanent

sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --add-port=3000-3005/tcp --permanent
Step 4: Remove a port rule

sudo firewall-cmd --remove-port=3000-3005/tcp --permanent
Step 5: Add UDP port

sudo firewall-cmd --add-port=53/udp --permanent
Step 6: Reload and verify changes

sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
Task 2: Manage Zones and Services
Subtask 2.1: Understanding and Working with Zones
Step 1: List all available zones with their configurations

sudo firewall-cmd --list-all-zones
Step 2: Get information about specific zones

sudo firewall-cmd --zone=dmz --list-all
sudo firewall-cmd --zone=internal --list-all
sudo firewall-cmd --zone=trusted --list-all
Step 3: Check which zone your network interface is assigned to

sudo firewall-cmd --get-active-zones
Step 4: Change the default zone

sudo firewall-cmd --set-default-zone=internal
Step 5: Verify the change

sudo firewall-cmd --get-default-zone
Subtask 2.2: Assigning Interfaces to Zones
Step 1: List network interfaces

ip addr show
Step 2: Assign an interface to a specific zone (replace eth0 with your interface name)

sudo firewall-cmd --zone=public --change-interface=eth0 --permanent
Step 3: Verify interface assignment

sudo firewall-cmd --get-zone-of-interface=eth0
Step 4: Add a source IP range to a zone

sudo firewall-cmd --zone=trusted --add-source=192.168.1.0/24 --permanent
Step 5: Remove a source from a zone

sudo firewall-cmd --zone=trusted --remove-source=192.168.1.0/24 --permanent
Subtask 2.3: Managing Services in Different Zones
Step 1: List all available services

sudo firewall-cmd --get-services
Step 2: Add services to specific zones

sudo firewall-cmd --zone=public --add-service=ssh --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --zone=internal --add-service=samba --permanent
Step 3: Remove a service from a zone

sudo firewall-cmd --zone=public --remove-service=dhcpv6-client --permanent
Step 4: Create a custom service definition

sudo firewall-cmd --permanent --new-service=myapp
Step 5: Configure the custom service

sudo firewall-cmd --permanent --service=myapp --set-description="My Custom Application"
sudo firewall-cmd --permanent --service=myapp --set-short="MyApp"
sudo firewall-cmd --permanent --service=myapp --add-port=9090/tcp
Step 6: Add the custom service to a zone

sudo firewall-cmd --zone=public --add-service=myapp --permanent
Step 7: Reload firewall and verify

sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-services
Task 3: Test Firewall Configurations
Subtask 3.1: Testing Port Accessibility
Step 1: Install testing tools (if not already available)

sudo yum install -y nmap telnet nc
Step 2: Start a simple web server for testing

sudo python3 -m http.server 8080 &
Step 3: Test local connectivity

curl http://localhost:8080
Step 4: Test from another terminal or system (replace IP with your system's IP)

nmap -p 8080 YOUR_SERVER_IP
Step 5: Test blocked ports

nmap -p 9999 YOUR_SERVER_IP
Step 6: Stop the test web server

sudo pkill -f "python3 -m http.server"
Subtask 3.2: Testing Zone Configurations
Step 1: Create a test scenario with different zones

sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=internal --add-service=ssh --permanent
sudo firewall-cmd --zone=dmz --add-port=8443/tcp --permanent
sudo firewall-cmd --reload
Step 2: Test service availability in different zones

sudo firewall-cmd --zone=public --list-services
sudo firewall-cmd --zone=internal --list-services
sudo firewall-cmd --zone=dmz --list-ports
Step 3: Simulate zone switching

sudo firewall-cmd --set-default-zone=dmz
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --list-all
Step 4: Switch back to public zone

sudo firewall-cmd --set-default-zone=public
Subtask 3.3: Advanced Testing and Validation
Step 1: Enable firewall logging

sudo firewall-cmd --set-log-denied=all
Step 2: Test denied connections and check logs

sudo tail -f /var/log/messages | grep -i firewall &
Step 3: Attempt connection to blocked port

telnet YOUR_SERVER_IP 9999
Step 4: Check firewall statistics

sudo firewall-cmd --direct --get-all-rules
Step 5: Create rich rules for advanced filtering

sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.100" service name="ssh" accept' --permanent
Step 6: Test rich rule functionality

sudo firewall-cmd --list-rich-rules
Step 7: Remove test rich rule

sudo firewall-cmd --remove-rich-rule='rule family="ipv4" source address="192.168.1.100" service name="ssh" accept' --permanent
Troubleshooting Common Issues
Issue 1: Firewall Rules Not Taking Effect
Problem: Changes made to firewall rules don't seem to work.

Solution:

# Always reload after making permanent changes
sudo firewall-cmd --reload

# Check if rules are permanent
sudo firewall-cmd --list-all --permanent

# Verify current runtime configuration
sudo firewall-cmd --list-all
Issue 2: Service Not Starting
Problem: firewalld service fails to start.

Solution:

# Check service status
sudo systemctl status firewalld -l

# Check for conflicting services
sudo systemctl status iptables
sudo systemctl stop iptables
sudo systemctl disable iptables

# Restart firewalld
sudo systemctl restart firewalld
Issue 3: Network Interface Not in Expected Zone
Problem: Network interface is not assigned to the correct zone.

Solution:

# Check current zone assignment
sudo firewall-cmd --get-active-zones

# Reassign interface to correct zone
sudo firewall-cmd --zone=public --change-interface=eth0 --permanent
sudo firewall-cmd --reload
Best Practices and Security Tips
Security Best Practices
Principle of Least Privilege: Only open ports and services that are absolutely necessary
Regular Auditing: Periodically review firewall rules and remove unused ones
Zone Segregation: Use appropriate zones for different network segments
Logging: Enable logging for denied connections to monitor potential attacks
Backup Configuration: Regularly backup firewall configurations
Useful Commands for Daily Management
# Quick status check
sudo firewall-cmd --state && sudo firewall-cmd --get-default-zone

# List all current rules
sudo firewall-cmd --list-all

# Emergency: Block all traffic (panic mode)
sudo firewall-cmd --panic-on

# Disable panic mode
sudo firewall-cmd --panic-off

# Backup current configuration
sudo cp -r /etc/firewalld/ /etc/firewalld.backup.$(date +%Y%m%d)
Verification and Testing Script
Create a comprehensive testing script to verify your firewall configuration:

#!/bin/bash
# firewall-test.sh

echo "=== Firewall Configuration Test ==="
echo "1. Checking firewalld status..."
sudo systemctl is-active firewalld

echo "2. Current default zone:"
sudo firewall-cmd --get-default-zone

echo "3. Active zones:"
sudo firewall-cmd --get-active-zones

echo "4. Services in default zone:"
sudo firewall-cmd --list-services

echo "5. Open ports in default zone:"
sudo firewall-cmd --list-ports

echo "6. Rich rules:"
sudo firewall-cmd --list-rich-rules

echo "=== Test Complete ==="
Make the script executable and run it:

chmod +x firewall-test.sh
./firewall-test.sh
Conclusion
In this comprehensive lab, you have successfully learned how to manage firewall configurations using firewalld. You have accomplished the following key tasks:

What You Learned:

Configured basic firewall rules using firewalld commands
Managed different firewall zones and understood their purposes
Assigned network interfaces and IP ranges to appropriate zones
Added and removed services and ports from firewall rules
Created custom service definitions
Tested firewall configurations to ensure they work as expected
Implemented advanced features like rich rules
Troubleshot common firewall issues
Why This Matters: Firewall management is a critical skill for system administrators and security professionals. firewalld provides a dynamic and flexible approach to managing Linux firewalls, making it easier to implement security policies without disrupting network services. The skills you've developed in this lab are essential for:

Securing Linux servers in production environments
Passing the Red Hat Certified System Administrator (RHCSA) exam
Implementing network security best practices
Managing enterprise-level firewall configurations
Troubleshooting network connectivity issues
Next Steps:

Practice implementing firewall rules for real-world scenarios
Explore integration with other security tools
Learn about firewalld's D-Bus interface for programmatic management
Study advanced topics like firewall zones for container environments
Consider pursuing additional Red Hat certifications that build on these skills
The firewall management skills you've gained will serve as a foundation for more advanced network security topics and are directly applicable to real-world system administration tasks.
