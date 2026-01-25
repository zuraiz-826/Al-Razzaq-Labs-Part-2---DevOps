Lab 14: Configuring Chrony for NTP Synchronization
Objectives
By the end of this lab, students will be able to:

Install and configure Chrony service on a Linux system
Configure Chrony to synchronize with remote NTP servers
Verify NTP synchronization status and troubleshoot common issues
Understand the importance of accurate time synchronization in enterprise environments
Configure Chrony as both client and server for network time synchronization
Monitor and maintain time synchronization services
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with systemd service management
Knowledge of text editors (nano, vim, or gedit)
Understanding of network concepts and firewall basics
Root or sudo access to a Linux system
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with internet connectivity
Root access for system configuration
All necessary packages available for installation
Task 1: Install and Configure Chrony
Subtask 1.1: Install Chrony Package
First, we'll install the Chrony package and understand its components.

Update the system package repository:
sudo dnf update -y
Install Chrony package:
sudo dnf install chrony -y
Verify the installation:
rpm -qa | grep chrony
Check Chrony version:
chronyd --version
Subtask 1.2: Understand Chrony Configuration Files
Examine the main configuration file:
sudo cat /etc/chrony.conf
Create a backup of the original configuration:
sudo cp /etc/chrony.conf /etc/chrony.conf.backup
View the Chrony service status:
sudo systemctl status chronyd
Subtask 1.3: Basic Chrony Configuration
Edit the Chrony configuration file:
sudo nano /etc/chrony.conf
Configure basic NTP servers by adding these lines (replace existing server entries):
# Use public NTP servers from the pool.ntp.org project
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# Allow NTP client access from local network
allow 192.168.0.0/16
allow 10.0.0.0/8
allow 172.16.0.0/12

# Serve time even if not synchronized to a time source
local stratum 10

# Specify file containing keys for NTP authentication
keyfile /etc/chrony.keys

# Get TAI-UTC offset and leap seconds from the system tz database
leapsectz right/UTC

# Specify directory for log files
logdir /var/log/chrony

# Select which information is logged
log measurements statistics tracking
Save and exit the editor (Ctrl+X, then Y, then Enter for nano)
Task 2: Set up Chrony for Synchronization with Remote NTP Servers
Subtask 2.1: Configure Multiple NTP Sources
Add additional reliable NTP servers to the configuration:
sudo nano /etc/chrony.conf
Add these additional server entries:
# Additional reliable NTP servers
server time.nist.gov iburst
server time.google.com iburst
server time.cloudflare.com iburst

# Configure polling intervals
minpoll 4
maxpoll 10

# Maximum allowed offset
maxdistance 16.0

# Step the system clock if offset is larger than 1 second
makestep 1.0 3
Subtask 2.2: Configure Chrony Client Settings
Add client-specific configurations:
sudo nano /etc/chrony.conf
Ensure these client settings are present:
# Enable kernel synchronization of the real-time clock (RTC)
rtcsync

# Specify the drift file location
driftfile /var/lib/chrony/drift

# Enable logging of time adjustment
logchange 0.5

# Dump measurements when daemon exits
dumponexit
dumpdir /var/lib/chrony

# Specify the maximum rate of messages sent to syslog
maxupdateskew 100.0

# Enable hardware timestamping if available
hwtimestamp *
Subtask 2.3: Start and Enable Chrony Service
Start the Chrony service:
sudo systemctl start chronyd
Enable Chrony to start at boot:
sudo systemctl enable chronyd
Verify the service is running:
sudo systemctl status chronyd
Check if the service is enabled:
sudo systemctl is-enabled chronyd
Task 3: Verify Synchronization Status and Adjust Time Settings
Subtask 3.1: Monitor NTP Synchronization Status
Check current time sources:
chrony sources -v
Display detailed source statistics:
chrony sourcestats -v
Show current system time status:
chrony tracking
Check NTP activity:
chrony activity
Subtask 3.2: Verify Time Synchronization
Force immediate synchronization (if needed):
sudo chrony makestep
Check system time:
date
Compare with hardware clock:
sudo hwclock --show
Synchronize hardware clock with system time:
sudo hwclock --systohc
Subtask 3.3: Advanced Monitoring and Troubleshooting
Monitor real-time synchronization:
watch -n 5 'chrony sources'
Press Ctrl+C to exit the watch command.

Check Chrony logs:
sudo journalctl -u chronyd -f
Press Ctrl+C to exit log monitoring.

View detailed tracking information:
chrony tracking
Test NTP connectivity to specific servers:
chrony sources | grep "^\*\|^+"
Subtask 3.4: Configure Firewall for NTP
Check current firewall status:
sudo firewall-cmd --state
Allow NTP service through firewall:
sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --reload
Verify NTP service is allowed:
sudo firewall-cmd --list-services | grep ntp
Subtask 3.5: Performance Tuning and Optimization
Create a custom monitoring script:
sudo nano /usr/local/bin/chrony-monitor.sh
Add the following monitoring script:
#!/bin/bash
# Chrony Monitoring Script

echo "=== Chrony Status Report ==="
echo "Date: $(date)"
echo ""

echo "=== Time Sources ==="
chrony sources -v
echo ""

echo "=== Tracking Information ==="
chrony tracking
echo ""

echo "=== Source Statistics ==="
chrony sourcestats
echo ""

echo "=== System Time vs Hardware Clock ==="
echo "System Time: $(date)"
echo "Hardware Clock: $(sudo hwclock --show)"
echo ""

echo "=== Service Status ==="
systemctl status chronyd --no-pager -l
Make the script executable:
sudo chmod +x /usr/local/bin/chrony-monitor.sh
Run the monitoring script:
sudo /usr/local/bin/chrony-monitor.sh
Subtask 3.6: Configure Chrony as NTP Server
Edit the configuration to allow serving time:
sudo nano /etc/chrony.conf
Add server configuration:
# Allow clients from local networks
allow 192.168.0.0/16
allow 10.0.0.0/8

# Serve time even if not synchronized
local stratum 10

# Increase logging for server operations
log measurements statistics tracking refclocks tempcomp
Restart Chrony service:
sudo systemctl restart chronyd
Verify server is listening:
sudo netstat -ulnp | grep :123
Troubleshooting Common Issues
Issue 1: Chrony Not Synchronizing
Symptoms: Sources show no synchronization, large time offsets

Solutions:

# Check network connectivity to NTP servers
ping -c 3 pool.ntp.org

# Verify firewall settings
sudo firewall-cmd --list-all

# Check for time zone issues
timedatectl status

# Force synchronization
sudo chrony makestep
Issue 2: Service Fails to Start
Symptoms: chronyd service fails to start or crashes

Solutions:

# Check configuration syntax
sudo chronyd -n -d

# Review system logs
sudo journalctl -u chronyd --no-pager

# Verify configuration file permissions
ls -la /etc/chrony.conf

# Reset to default configuration if needed
sudo cp /etc/chrony.conf.backup /etc/chrony.conf
Issue 3: Large Time Jumps
Symptoms: System time jumps significantly

Solutions:

# Configure gradual time adjustment
echo "makestep 0.1 3" | sudo tee -a /etc/chrony.conf

# Monitor time adjustments
sudo journalctl -u chronyd | grep -i step

# Check for hardware clock issues
sudo hwclock --compare
Verification and Testing
Final Verification Steps
Comprehensive status check:
echo "=== Final Chrony Verification ==="
echo "Service Status:"
sudo systemctl status chronyd --no-pager

echo -e "\nTime Sources:"
chrony sources

echo -e "\nTracking Status:"
chrony tracking

echo -e "\nSystem Time:"
date

echo -e "\nTime Zone:"
timedatectl status
Test time synchronization accuracy:
# Compare with external time source
curl -s http://worldtimeapi.org/api/timezone/UTC | grep -o '"datetime":"[^"]*'
Verify configuration persistence:
sudo systemctl reboot
# After reboot, check if Chrony starts automatically
sudo systemctl status chronyd
Conclusion
In this lab, you have successfully:

Installed and configured Chrony as a modern NTP client and server solution
Set up synchronization with multiple reliable NTP servers for redundancy
Verified time synchronization using various monitoring tools and commands
Configured advanced features including firewall rules and performance monitoring
Implemented troubleshooting procedures for common NTP synchronization issues
Why This Matters: Accurate time synchronization is critical in enterprise environments for:

Security: Authentication protocols and certificates depend on synchronized time
Logging: Correlating events across multiple systems requires accurate timestamps
Compliance: Many regulatory requirements mandate synchronized system clocks
Performance: Distributed applications and databases rely on consistent time references
Troubleshooting: Accurate timestamps are essential for effective system debugging
The skills you've learned in this lab are essential for the Red Hat Certified Specialist in Services Management and Automation exam and are directly applicable to real-world system administration tasks. Chrony's superior accuracy and performance make it the preferred NTP implementation for modern Linux systems.

Next Steps: Consider exploring advanced Chrony features such as hardware timestamping, PTP (Precision Time Protocol) integration, and setting up Chrony in high-availability configurations for mission-critical environments.
