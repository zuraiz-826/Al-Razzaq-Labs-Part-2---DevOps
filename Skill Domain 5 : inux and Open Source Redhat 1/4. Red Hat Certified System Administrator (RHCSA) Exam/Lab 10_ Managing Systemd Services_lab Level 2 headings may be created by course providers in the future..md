Lab 10: Managing Systemd Services
Objectives
By the end of this lab, you will be able to:

Start, stop, restart, and enable/disable system services using systemctl
Check the status and configuration of systemd services
Configure system boot targets and understand their purpose
Troubleshoot systemd services using journalctl
Understand the relationship between systemd units and system initialization
Manage service dependencies and boot behavior
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line interface
Familiarity with file permissions and basic system administration concepts
Knowledge of text editors like nano or vim
Understanding of process management concepts
Access to a Linux system with systemd (most modern distributions)
Ready-to-Use Cloud Machines
Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software - everything is ready to use!

Your cloud machine includes:

CentOS/RHEL or Ubuntu Linux with systemd
All necessary tools and services pre-installed
Root access for system administration tasks
Sample services for practice
Task 1: Managing Services with systemctl
Subtask 1.1: Understanding systemctl Basics
First, let's explore the basic systemctl commands and understand how to interact with systemd services.

Step 1: Check the status of systemd itself

systemctl status
Step 2: List all active services

systemctl list-units --type=service --state=active
Step 3: List all available services (active and inactive)

systemctl list-units --type=service --all
Step 4: Check if a specific service is enabled

systemctl is-enabled sshd
systemctl is-enabled httpd
Subtask 1.2: Starting and Stopping Services
Let's practice with the SSH service, which is commonly available on most systems.

Step 1: Check the current status of SSH service

systemctl status sshd
Step 2: If SSH is running, stop it temporarily

sudo systemctl stop sshd
Step 3: Verify the service has stopped

systemctl status sshd
Step 4: Start the SSH service again

sudo systemctl start sshd
Step 5: Restart a service (stop and start in one command)

sudo systemctl restart sshd
Step 6: Reload service configuration without stopping

sudo systemctl reload sshd
Subtask 1.3: Enabling and Disabling Services
Services can be configured to start automatically at boot time.

Step 1: Check if SSH service is enabled for automatic startup

systemctl is-enabled sshd
Step 2: Enable SSH service to start at boot

sudo systemctl enable sshd
Step 3: Disable a service from starting at boot

sudo systemctl disable sshd
Step 4: Enable and start a service simultaneously

sudo systemctl enable --now sshd
Step 5: Disable and stop a service simultaneously

sudo systemctl disable --now sshd
Step 6: Re-enable the SSH service for the remaining tasks

sudo systemctl enable --now sshd
Subtask 1.4: Working with Apache HTTP Server
Let's install and manage Apache web server to practice with another service.

Step 1: Install Apache (if not already installed)

For RHEL/CentOS:

sudo yum install -y httpd
For Ubuntu/Debian:

sudo apt update
sudo apt install -y apache2
Step 2: Start Apache service

For RHEL/CentOS:

sudo systemctl start httpd
For Ubuntu/Debian:

sudo systemctl start apache2
Step 3: Check Apache status

For RHEL/CentOS:

systemctl status httpd
For Ubuntu/Debian:

systemctl status apache2
Step 4: Enable Apache to start at boot

For RHEL/CentOS:

sudo systemctl enable httpd
For Ubuntu/Debian:

sudo systemctl enable apache2
Task 2: Configure System Boot Targets
Subtask 2.1: Understanding Boot Targets
Boot targets in systemd are similar to runlevels in traditional SysV init systems.

Step 1: Check the current boot target

systemctl get-default
Step 2: List all available targets

systemctl list-units --type=target
Step 3: Show details about the multi-user target

systemctl show multi-user.target
Step 4: List dependencies of the current target

systemctl list-dependencies
Subtask 2.2: Common Boot Targets
Let's explore the most common boot targets:

Step 1: View graphical target details

systemctl cat graphical.target
Step 2: View multi-user target details

systemctl cat multi-user.target
Step 3: Check what services are wanted by multi-user target

systemctl list-dependencies multi-user.target
Subtask 2.3: Changing Boot Targets
Step 1: Set the default boot target to multi-user (text mode)

sudo systemctl set-default multi-user.target
Step 2: Verify the change

systemctl get-default
Step 3: Set the default back to graphical target (if GUI is available)

sudo systemctl set-default graphical.target
Step 4: Switch to multi-user target immediately (without reboot)

sudo systemctl isolate multi-user.target
Step 5: Switch back to graphical target (if available)

sudo systemctl isolate graphical.target
Subtask 2.4: Emergency and Rescue Targets
Understanding emergency targets is crucial for system recovery.

Step 1: View rescue target information

systemctl cat rescue.target
Step 2: View emergency target information

systemctl cat emergency.target
Note: Do not isolate to emergency or rescue targets in this lab environment as it may disrupt your session.

Task 3: Troubleshooting with journalctl
Subtask 3.1: Basic journalctl Usage
The systemd journal stores all log messages from services and the kernel.

Step 1: View all journal entries

journalctl
Step 2: View journal entries from the current boot

journalctl -b
Step 3: View journal entries from the previous boot

journalctl -b -1
Step 4: Follow journal entries in real-time

journalctl -f
Press Ctrl+C to stop following.

Subtask 3.2: Service-Specific Logs
Step 1: View logs for SSH service

journalctl -u sshd
Step 2: View logs for Apache service

For RHEL/CentOS:

journalctl -u httpd
For Ubuntu/Debian:

journalctl -u apache2
Step 3: View logs for a service since a specific time

journalctl -u sshd --since "1 hour ago"
Step 4: View logs for a service with specific priority

journalctl -u sshd -p err
Subtask 3.3: Advanced journalctl Filtering
Step 1: View logs from a specific date

journalctl --since "2024-01-01" --until "2024-01-02"
Step 2: View logs with specific fields

journalctl _SYSTEMD_UNIT=sshd.service
Step 3: View kernel messages

journalctl -k
Step 4: View logs in JSON format

journalctl -u sshd -o json-pretty
Subtask 3.4: Troubleshooting Failed Services
Let's create a scenario to practice troubleshooting.

Step 1: Create a custom service file that will fail

sudo tee /etc/systemd/system/test-fail.service > /dev/null << 'EOF'
[Unit]
Description=Test Service That Fails
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/nonexistent-command
Restart=no

[Install]
WantedBy=multi-user.target
EOF
Step 2: Reload systemd to recognize the new service

sudo systemctl daemon-reload
Step 3: Try to start the failing service

sudo systemctl start test-fail.service
Step 4: Check the status of the failed service

systemctl status test-fail.service
Step 5: View detailed logs for the failed service

journalctl -u test-fail.service
Step 6: View the last few log entries for the service

journalctl -u test-fail.service -n 10
Step 7: Clean up by removing the test service

sudo systemctl stop test-fail.service 2>/dev/null || true
sudo systemctl disable test-fail.service 2>/dev/null || true
sudo rm /etc/systemd/system/test-fail.service
sudo systemctl daemon-reload
Subtask 3.5: Monitoring System Boot Process
Step 1: View boot messages

journalctl -b --no-pager
Step 2: Analyze boot time

systemd-analyze
Step 3: Show detailed boot timing

systemd-analyze blame
Step 4: Show boot process critical chain

systemd-analyze critical-chain
Practical Exercise: Complete Service Management Scenario
Let's put everything together with a comprehensive exercise.

Exercise: Setting up and Managing a Web Server
Step 1: Ensure Apache is installed and configured

For RHEL/CentOS:

sudo yum install -y httpd
sudo systemctl enable --now httpd
For Ubuntu/Debian:

sudo apt update
sudo apt install -y apache2
sudo systemctl enable --now apache2
Step 2: Create a simple web page

sudo tee /var/www/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Systemd Lab Test Page</title>
</head>
<body>
    <h1>Welcome to the Systemd Management Lab!</h1>
    <p>This page is served by Apache, managed through systemd.</p>
    <p>Current time: $(date)</p>
</body>
</html>
EOF
Step 3: Test the web server

curl http://localhost
Step 4: Monitor Apache logs in real-time (open a second terminal if possible)

For RHEL/CentOS:

journalctl -u httpd -f
For Ubuntu/Debian:

journalctl -u apache2 -f
Step 5: Generate some web traffic

for i in {1..5}; do curl http://localhost; sleep 1; done
Step 6: Check service status and recent logs

For RHEL/CentOS:

systemctl status httpd
journalctl -u httpd --since "5 minutes ago"
For Ubuntu/Debian:

systemctl status apache2
journalctl -u apache2 --since "5 minutes ago"
Step 7: Practice service management

# Stop the service
sudo systemctl stop httpd  # or apache2 for Ubuntu/Debian

# Verify it's stopped
curl http://localhost  # This should fail

# Start it again
sudo systemctl start httpd  # or apache2 for Ubuntu/Debian

# Verify it's working
curl http://localhost  # This should work again
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Service fails to start

Solution: Check systemctl status servicename and journalctl -u servicename for error messages
Look for configuration file errors or missing dependencies
Issue 2: Service starts but doesn't work as expected

Solution: Check service logs with journalctl -u servicename -f while testing
Verify configuration files and permissions
Issue 3: Service doesn't start at boot

Solution: Ensure service is enabled with systemctl enable servicename
Check if service dependencies are met
Issue 4: Cannot find service logs

Solution: Use journalctl -u servicename instead of looking in /var/log/
Some services may still log to traditional log files in /var/log/
Useful Commands Reference
# Service Management
systemctl start servicename      # Start a service
systemctl stop servicename       # Stop a service
systemctl restart servicename    # Restart a service
systemctl reload servicename     # Reload service configuration
systemctl status servicename     # Check service status
systemctl enable servicename     # Enable service at boot
systemctl disable servicename    # Disable service at boot
systemctl is-active servicename  # Check if service is active
systemctl is-enabled servicename # Check if service is enabled

# Target Management
systemctl get-default            # Show default boot target
systemctl set-default target     # Set default boot target
systemctl isolate target         # Switch to target immediately
systemctl list-units --type=target # List all targets

# Log Management
journalctl                       # View all logs
journalctl -u servicename        # View logs for specific service
journalctl -f                    # Follow logs in real-time
journalctl -b                    # View logs from current boot
journalctl --since "1 hour ago"  # View logs from specific time
journalctl -p err                # View only error messages
Conclusion
In this lab, you have successfully learned how to:

Manage systemd services using systemctl commands to start, stop, restart, enable, and disable services
Configure boot targets to control which services start during system initialization
Troubleshoot services using journalctl to view and analyze system logs
Monitor system behavior and understand service dependencies
These skills are fundamental for Linux system administration and are essential for the Red Hat Certified System Administrator (RHCSA) exam. Understanding systemd is crucial because:

Modern Linux distributions use systemd as their init system
Service management is a core responsibility of system administrators
Troubleshooting skills help you quickly identify and resolve system issues
Boot target configuration allows you to optimize system startup for different use cases
The hands-on experience you've gained with real services like SSH and Apache web server provides practical knowledge that you can immediately apply in production environments. Remember to always check service status and logs when troubleshooting issues, as systemd provides comprehensive logging that makes problem diagnosis much easier than traditional init systems.

Continue practicing these commands and concepts, as they form the foundation of modern Linux system administration and will serve you well in both certification exams and real-world scenarios.
