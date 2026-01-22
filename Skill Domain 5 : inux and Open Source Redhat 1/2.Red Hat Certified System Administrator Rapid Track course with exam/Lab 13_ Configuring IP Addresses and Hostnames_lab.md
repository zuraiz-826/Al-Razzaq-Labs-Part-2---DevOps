Lab 13: Configuring IP Addresses and Hostnames
Objectives
By the end of this lab, students will be able to:

• Configure static IP addresses using the nmcli command-line tool • Set up and manage network interfaces on Red Hat Enterprise Linux systems • Modify system hostnames using the hostnamectl command • Understand the relationship between IP addresses, network interfaces, and hostnames • Troubleshoot basic network connectivity issues • Verify network configuration changes and ensure they persist across reboots

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command-line interface • Familiarity with text editors like vi or nano • Knowledge of basic networking concepts (IP addresses, subnets, gateways) • Understanding of the Linux file system structure • Access to a terminal with root or sudo privileges

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or configure additional software.

Your lab environment includes: • Red Hat Enterprise Linux 8 or 9 system • NetworkManager service pre-installed and running • Root access for system configuration • Internet connectivity for testing

Task 1: Configure Static IP Addresses with nmcli
Subtask 1.1: Understanding Current Network Configuration
First, let's examine the current network configuration on your system.

Step 1: Check current network connections

nmcli connection show
Step 2: Display detailed information about active connections

nmcli connection show --active
Step 3: View current IP address configuration

ip addr show
Step 4: Check the status of NetworkManager service

systemctl status NetworkManager
Subtask 1.2: Creating a New Static IP Connection
Now we'll create a new network connection with a static IP address.

Step 1: Identify your network interface name

nmcli device status
Note: Common interface names include eth0, ens33, enp0s3, or similar. Replace eth0 in the following commands with your actual interface name.

Step 2: Create a new connection profile with static IP

sudo nmcli connection add \
    type ethernet \
    con-name "static-connection" \
    ifname eth0 \
    ip4 192.168.1.100/24 \
    gw4 192.168.1.1
Step 3: Add DNS servers to the connection

sudo nmcli connection modify "static-connection" \
    ipv4.dns "8.8.8.8,8.8.4.4"
Step 4: Set the connection to manual (static) mode

sudo nmcli connection modify "static-connection" \
    ipv4.method manual
Subtask 1.3: Activating and Testing the Static Connection
Step 1: Activate the new connection

sudo nmcli connection up "static-connection"
Step 2: Verify the connection is active

nmcli connection show --active
Step 3: Check the new IP address assignment

ip addr show eth0
Step 4: Test connectivity

ping -c 4 8.8.8.8
Task 2: Set Up Network Interfaces
Subtask 2.1: Managing Multiple Network Connections
Step 1: List all available network devices

nmcli device show
Step 2: Create a backup connection profile

sudo nmcli connection add \
    type ethernet \
    con-name "backup-connection" \
    ifname eth0 \
    ip4 192.168.1.101/24 \
    gw4 192.168.1.1
Step 3: Configure DNS for the backup connection

sudo nmcli connection modify "backup-connection" \
    ipv4.dns "1.1.1.1,1.0.0.1" \
    ipv4.method manual
Subtask 2.2: Switching Between Network Connections
Step 1: View all connection profiles

nmcli connection show
Step 2: Switch to the backup connection

sudo nmcli connection down "static-connection"
sudo nmcli connection up "backup-connection"
Step 3: Verify the IP address change

ip addr show eth0
Step 4: Test connectivity with the new configuration

ping -c 4 google.com
Subtask 2.3: Configuring Connection Auto-Connect
Step 1: Enable auto-connect for the primary connection

sudo nmcli connection modify "static-connection" \
    connection.autoconnect yes
Step 2: Set connection priority

sudo nmcli connection modify "static-connection" \
    connection.autoconnect-priority 10
Step 3: Disable auto-connect for backup connection

sudo nmcli connection modify "backup-connection" \
    connection.autoconnect no
Task 3: Modify Hostnames Using hostnamectl
Subtask 3.1: Understanding Current Hostname Configuration
Step 1: Display current hostname information

hostnamectl status
Step 2: Show only the current hostname

hostname
Step 3: Check hostname configuration files

cat /etc/hostname
Subtask 3.2: Setting Different Types of Hostnames
Step 1: Set the static hostname

sudo hostnamectl set-hostname "lab-server-01"
Step 2: Set a pretty hostname (descriptive name)

sudo hostnamectl set-hostname "Lab Server 01" --pretty
Step 3: Set a transient hostname (temporary)

sudo hostnamectl set-hostname "temp-lab-server" --transient
Step 4: Verify all hostname settings

hostnamectl status
Subtask 3.3: Configuring Hostname Resolution
Step 1: Edit the hosts file to add local hostname resolution

sudo nano /etc/hosts
Step 2: Add the following line to the hosts file

192.168.1.100    lab-server-01.localdomain    lab-server-01
Step 3: Save and exit the editor (Ctrl+X, then Y, then Enter for nano)

Step 4: Test hostname resolution

ping -c 2 lab-server-01
Step 5: Verify reverse DNS lookup

nslookup lab-server-01
Verification and Testing
Complete System Verification
Step 1: Restart NetworkManager to ensure persistence

sudo systemctl restart NetworkManager
Step 2: Verify network configuration persists

nmcli connection show --active
ip addr show
Step 3: Test hostname persistence

hostnamectl status
hostname -f
Step 4: Perform comprehensive connectivity test

ping -c 4 8.8.8.8
ping -c 4 google.com
ping -c 2 lab-server-01
Step 5: Check DNS resolution

nslookup google.com
dig google.com
Troubleshooting Common Issues
Network Connection Issues
Problem: Connection fails to activate Solution: Check interface name and ensure no conflicting connections

nmcli connection show
nmcli device status
sudo nmcli connection down "conflicting-connection"
Problem: No internet connectivity Solution: Verify gateway and DNS settings

ip route show
cat /etc/resolv.conf
Hostname Issues
Problem: Hostname doesn't persist after reboot Solution: Ensure proper permissions on hostname file

sudo chmod 644 /etc/hostname
sudo systemctl restart systemd-hostnamed
Problem: Hostname resolution fails Solution: Check hosts file and DNS configuration

cat /etc/hosts
cat /etc/resolv.conf
Lab Cleanup (Optional)
If you want to reset your configuration:

Step 1: Remove custom connections

sudo nmcli connection delete "static-connection"
sudo nmcli connection delete "backup-connection"
Step 2: Reset hostname to default

sudo hostnamectl set-hostname "localhost.localdomain"
Step 3: Restore original hosts file

sudo cp /etc/hosts /etc/hosts.backup
sudo nano /etc/hosts
Conclusion
In this lab, you have successfully accomplished several important network administration tasks:

Key Achievements: • Configured static IP addresses using the powerful nmcli command-line tool, which is essential for servers and systems requiring consistent network addresses • Managed network interfaces by creating multiple connection profiles and understanding how to switch between them • Modified system hostnames using hostnamectl, learning the difference between static, pretty, and transient hostnames • Implemented hostname resolution by configuring the local hosts file for internal network communication

Why This Matters: These skills are fundamental for Red Hat Certified System Administrators because: • Static IP configuration ensures servers maintain consistent network addresses • Proper hostname management is crucial for system identification and network services • Understanding nmcli and hostnamectl prepares you for managing enterprise Linux environments • These configurations form the foundation for more advanced networking topics like DNS, DHCP, and network services

Real-World Applications: • Web servers require static IP addresses for reliable service delivery • Database servers need consistent hostnames for application connectivity • Network monitoring systems depend on proper hostname resolution • Enterprise environments require standardized network configuration management

You now have the practical skills to configure and manage network settings on Red Hat Enterprise Linux systems, which is a core competency for system administrators in enterprise environments.
