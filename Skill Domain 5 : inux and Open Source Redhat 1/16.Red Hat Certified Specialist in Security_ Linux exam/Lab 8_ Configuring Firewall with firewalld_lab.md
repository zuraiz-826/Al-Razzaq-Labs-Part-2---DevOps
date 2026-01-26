Lab 8: Configuring Firewall with firewalld
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of firewalld and its zone-based architecture
Configure and manage firewall zones for different network environments
Implement masquerading for network address translation (NAT)
Set up port forwarding to redirect network traffic
Test and validate firewall rules using firewall-cmd
Troubleshoot common firewall configuration issues
Apply security best practices for RHEL system protection
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line interface
Familiarity with network concepts (IP addresses, ports, protocols)
Knowledge of systemd service management
Understanding of basic security principles
Access to a RHEL-based system with root privileges
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes:

RHEL 9 or compatible system with firewalld installed
Root access for system configuration
Network connectivity for testing
All necessary tools pre-installed
Task 1: Set up and manage firewall zones using firewalld
Subtask 1.1: Understanding firewalld basics
First, let's explore the current firewall status and understand the zone concept.

Step 1: Check if firewalld is running

sudo systemctl status firewalld
Step 2: If firewalld is not running, start and enable it

sudo systemctl start firewalld
sudo systemctl enable firewalld
Step 3: View the current default zone

sudo firewall-cmd --get-default-zone
Step 4: List all available zones

sudo firewall-cmd --get-zones
Step 5: Get detailed information about the current active zones

sudo firewall-cmd --get-active-zones
Subtask 1.2: Exploring zone configurations
Step 1: View the configuration of the public zone (default zone)

sudo firewall-cmd --zone=public --list-all
Step 2: Check all zones and their configurations

sudo firewall-cmd --list-all-zones
Step 3: Understand the trust levels of different zones by examining specific zones

# Check the trusted zone (allows all traffic)
sudo firewall-cmd --zone=trusted --list-all

# Check the drop zone (drops all incoming traffic)
sudo firewall-cmd --zone=drop --list-all

# Check the work zone (suitable for work environments)
sudo firewall-cmd --zone=work --list-all
Subtask 1.3: Managing network interfaces and zones
Step 1: List current network interfaces

ip addr show
Step 2: Check which zone your network interface is assigned to

sudo firewall-cmd --get-zone-of-interface=eth0
Note: Replace eth0 with your actual interface name from Step 1.

Step 3: Move your network interface to the work zone temporarily

sudo firewall-cmd --zone=work --change-interface=eth0
Step 4: Verify the change

sudo firewall-cmd --get-active-zones
Step 5: Move the interface back to the public zone

sudo firewall-cmd --zone=public --change-interface=eth0
Subtask 1.4: Creating and configuring custom zones
Step 1: Create a new custom zone called "lab-zone"

sudo firewall-cmd --permanent --new-zone=lab-zone
Step 2: Reload firewalld to apply the permanent change

sudo firewall-cmd --reload
Step 3: Verify the new zone was created

sudo firewall-cmd --get-zones
Step 4: Configure the custom zone with specific services

# Add SSH service to the lab-zone
sudo firewall-cmd --zone=lab-zone --add-service=ssh --permanent

# Add HTTP service to the lab-zone
sudo firewall-cmd --zone=lab-zone --add-service=http --permanent

# Add a custom port (port 8080/tcp)
sudo firewall-cmd --zone=lab-zone --add-port=8080/tcp --permanent
Step 5: Reload and verify the configuration

sudo firewall-cmd --reload
sudo firewall-cmd --zone=lab-zone --list-all
Task 2: Implement masquerading and port forwarding
Subtask 2.1: Understanding and configuring masquerading
Masquerading allows your system to act as a router, translating private IP addresses to public ones.

Step 1: Check if masquerading is currently enabled in the public zone

sudo firewall-cmd --zone=public --query-masquerade
Step 2: Enable masquerading in the public zone

sudo firewall-cmd --zone=public --add-masquerade --permanent
Step 3: Reload firewalld and verify masquerading is enabled

sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --query-masquerade
Step 4: View the complete public zone configuration to see masquerading

sudo firewall-cmd --zone=public --list-all
Subtask 2.2: Configuring port forwarding
Port forwarding redirects traffic from one port to another, either on the same system or to a different system.

Step 1: Set up port forwarding from port 8080 to port 80 (HTTP)

sudo firewall-cmd --zone=public --add-forward-port=port=8080:proto=tcp:toport=80 --permanent
Step 2: Set up port forwarding to a different host (example: forward port 2222 to SSH on another machine)

# Replace 192.168.1.100 with an actual IP address in your network
sudo firewall-cmd --zone=public --add-forward-port=port=2222:proto=tcp:toaddr=192.168.1.100:toport=22 --permanent
Step 3: Reload firewalld to apply changes

sudo firewall-cmd --reload
Step 4: Verify the port forwarding rules

sudo firewall-cmd --zone=public --list-forward-ports
Step 5: View the complete zone configuration

sudo firewall-cmd --zone=public --list-all
Subtask 2.3: Advanced masquerading scenarios
Step 1: Create a scenario for internal network routing by adding a rich rule

# Allow masquerading for a specific source network
sudo firewall-cmd --zone=public --add-rich-rule='rule family=ipv4 source address=192.168.100.0/24 masquerade' --permanent
Step 2: Add a rich rule for port forwarding with source restrictions

# Forward port 9090 to 80, but only for specific source network
sudo firewall-cmd --zone=public --add-rich-rule='rule family=ipv4 source address=192.168.1.0/24 forward-port port=9090 protocol=tcp to-port=80' --permanent
Step 3: Reload and verify the rich rules

sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-rich-rules
Task 3: Test firewall rules with firewall-cmd
Subtask 3.1: Testing basic connectivity and rules
Step 1: Install testing tools if not already available

sudo dnf install -y nmap telnet nc
Step 2: Test SSH connectivity (should work as SSH is typically allowed)

# Test from localhost
telnet localhost 22
Press Ctrl+C to exit telnet.

Step 3: Test HTTP connectivity

# First, let's add HTTP service to public zone if not already added
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --reload

# Test HTTP port
telnet localhost 80
Step 4: Test a blocked port (should fail)

# Try connecting to a port that's not allowed (e.g., 3306 - MySQL)
telnet localhost 3306
This should timeout or be refused.

Subtask 3.2: Testing port forwarding rules
Step 1: Install a simple web server for testing

sudo dnf install -y python3
Step 2: Start a simple HTTP server on port 80

# Create a test HTML file
echo "<h1>Test Web Server</h1><p>Port forwarding test successful!</p>" | sudo tee /var/www/html/index.html

# Start Python HTTP server on port 80 (run in background)
sudo python3 -m http.server 80 --directory /var/www/html &
Step 3: Test the port forwarding rule (8080 -> 80)

# Test direct access to port 80
curl http://localhost:80

# Test access through forwarded port 8080
curl http://localhost:8080
Both should return the same content.

Step 4: Stop the test server

sudo pkill -f "python3 -m http.server"
Subtask 3.3: Advanced testing with nmap and custom rules
Step 1: Scan open ports on your system

nmap localhost
Step 2: Add a custom port and test it

# Add port 9999/tcp to public zone
sudo firewall-cmd --zone=public --add-port=9999/tcp --permanent
sudo firewall-cmd --reload

# Start a listener on port 9999
nc -l 9999 &
NC_PID=$!

# Test the connection from another terminal or background process
echo "Test message" | nc localhost 9999

# Clean up
kill $NC_PID 2>/dev/null
Step 3: Test zone switching effects

# Move interface to drop zone (blocks all traffic)
sudo firewall-cmd --zone=drop --change-interface=eth0

# Try to connect (should fail)
timeout 5 telnet localhost 22

# Move back to public zone
sudo firewall-cmd --zone=public --change-interface=eth0

# Try to connect again (should work)
timeout 5 telnet localhost 22
Subtask 3.4: Testing rich rules and logging
Step 1: Add a rich rule with logging

# Add a rule that logs SSH connection attempts
sudo firewall-cmd --zone=public --add-rich-rule='rule service name="ssh" log prefix="SSH-ACCESS: " level="info" accept' --permanent
sudo firewall-cmd --reload
Step 2: Configure rsyslog to handle firewall logs (if not already configured)

# Check if firewall logs are being generated
sudo tail -f /var/log/messages | grep "SSH-ACCESS" &
LOG_PID=$!
Step 3: Generate some SSH traffic to test logging

# Make an SSH connection attempt
ssh localhost -o ConnectTimeout=5
Step 4: Check the logs

# Stop the log monitoring
kill $LOG_PID 2>/dev/null

# Check recent firewall logs
sudo grep "SSH-ACCESS" /var/log/messages | tail -5
Subtask 3.5: Performance and rule validation testing
Step 1: Check firewall performance with multiple rules

# Add multiple port rules
for port in {8001..8010}; do
    sudo firewall-cmd --zone=public --add-port=${port}/tcp --permanent
done

sudo firewall-cmd --reload
Step 2: Validate all rules are working

# List all ports to verify they were added
sudo firewall-cmd --zone=public --list-ports

# Test a few of the ports
for port in 8001 8005 8010; do
    echo "Testing port $port"
    timeout 2 telnet localhost $port
done
Step 3: Clean up test rules

# Remove the test ports
for port in {8001..8010}; do
    sudo firewall-cmd --zone=public --remove-port=${port}/tcp --permanent
done

sudo firewall-cmd --reload
Troubleshooting Common Issues
Issue 1: Firewalld service not starting
Problem: systemctl start firewalld fails

Solution:

# Check for conflicting services
sudo systemctl status iptables
sudo systemctl stop iptables
sudo systemctl disable iptables

# Check firewalld configuration
sudo firewall-cmd --check-config

# Restart NetworkManager if needed
sudo systemctl restart NetworkManager
sudo systemctl start firewalld
Issue 2: Rules not taking effect
Problem: Firewall rules added but not working

Solution:

# Always reload after adding permanent rules
sudo firewall-cmd --reload

# Check if rules are in the correct zone
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=public --list-all

# Verify interface assignment
sudo firewall-cmd --get-zone-of-interface=eth0
Issue 3: Port forwarding not working
Problem: Port forwarding rules don't redirect traffic

Solution:

# Ensure masquerading is enabled
sudo firewall-cmd --zone=public --add-masquerade --permanent

# Check kernel IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Verify the forward rule syntax
sudo firewall-cmd --zone=public --list-forward-ports
Issue 4: Cannot access services after firewall changes
Problem: Services become inaccessible after firewall configuration

Solution:

# Check if the service is allowed in the current zone
sudo firewall-cmd --zone=public --list-services

# Add the required service
sudo firewall-cmd --zone=public --add-service=ssh --permanent
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --reload

# Temporarily disable firewall for testing (use with caution)
sudo systemctl stop firewalld
# Test connectivity, then restart firewall
sudo systemctl start firewalld
Best Practices and Security Considerations
Security Best Practices
Principle of Least Privilege: Only open ports and services that are absolutely necessary
Regular Audits: Periodically review firewall rules and remove unused ones
Logging: Enable logging for security-critical services
Zone Management: Use appropriate zones for different network environments
Rich Rules: Use rich rules for complex scenarios requiring granular control
Maintenance Commands
# Backup current configuration
sudo cp -r /etc/firewalld /etc/firewalld.backup.$(date +%Y%m%d)

# View configuration files
sudo ls -la /etc/firewalld/zones/

# Reset to default configuration (use with extreme caution)
sudo firewall-cmd --complete-reload

# Check firewall status and statistics
sudo firewall-cmd --state
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --get-active-zones
Conclusion
In this comprehensive lab, you have successfully:

Mastered firewalld fundamentals by exploring zones, services, and the zone-based security model
Configured multiple firewall zones including creating custom zones tailored to specific security requirements
Implemented masquerading to enable Network Address Translation (NAT) functionality
Set up port forwarding rules to redirect network traffic efficiently
Tested firewall configurations using various tools and techniques to ensure proper functionality
Troubleshot common issues and learned best practices for firewall management
Why This Matters
Firewall configuration is a critical skill for system administrators and security professionals because:

Network Security: Firewalls are the first line of defense against network-based attacks
Compliance Requirements: Many regulatory frameworks require proper firewall configuration
Service Management: Proper firewall rules ensure legitimate services remain accessible while blocking threats
Performance Optimization: Well-configured firewalls can improve network performance by efficiently handling traffic
Next Steps
To further enhance your firewall and security skills:

Practice with Complex Scenarios: Set up multi-zone environments with different security requirements
Integration with Other Tools: Learn to integrate firewalld with SELinux and other security tools
Automation: Explore Ansible playbooks for automated firewall configuration
Monitoring: Implement comprehensive logging and monitoring solutions
Advanced Features: Study firewalld's integration with NetworkManager and systemd
Key Commands Reference
# Essential firewalld commands for daily use
sudo firewall-cmd --state                    # Check firewall status
sudo firewall-cmd --get-default-zone         # Get default zone
sudo firewall-cmd --get-active-zones         # List active zones
sudo firewall-cmd --zone=public --list-all   # List zone configuration
sudo firewall-cmd --reload                   # Reload configuration
sudo firewall-cmd --permanent                # Make changes permanent
This lab has provided you with practical, hands-on experience in configuring and managing firewalld, preparing you for real-world network security challenges and the Red Hat Certified Specialist in Security: Linux exam.
