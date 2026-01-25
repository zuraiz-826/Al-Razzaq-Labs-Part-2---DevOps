Lab 20: Managing and Troubleshooting Services
Objectives
By the end of this lab, students will be able to:

Use systemctl commands to manage and troubleshoot system services
Utilize journalctl to analyze service logs and identify failures
Diagnose and resolve common network configuration issues
Check service status and interpret log entries effectively
Apply systematic troubleshooting methodologies for service failures
Implement solutions for network connectivity problems
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line interface
Familiarity with file system navigation and text editing
Knowledge of basic networking concepts (IP addresses, DNS, routing)
Understanding of system services and daemons
Access to a terminal or SSH client
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
Pre-installed systemd services
Network configuration tools
Sample services for troubleshooting practice
Task 1: Using systemctl and journalctl for Troubleshooting Service Failures
Subtask 1.1: Understanding systemctl Basics
First, let's explore the fundamental systemctl commands for service management.

Check the status of all services:
systemctl list-units --type=service
View only failed services:
systemctl list-units --type=service --state=failed
Check the status of a specific service (using SSH as an example):
systemctl status sshd
View detailed service information:
systemctl show sshd
Subtask 1.2: Creating a Problematic Service for Practice
Let's create a service that will fail so we can practice troubleshooting.

Create a simple script that will fail:
sudo mkdir -p /opt/lab-scripts
sudo tee /opt/lab-scripts/failing-service.sh > /dev/null << 'EOF'
#!/bin/bash
echo "Service starting..."
sleep 5
echo "Service attempting to access non-existent file..."
cat /nonexistent/file.txt
echo "This line will never execute"
EOF
Make the script executable:
sudo chmod +x /opt/lab-scripts/failing-service.sh
Create a systemd service file:
sudo tee /etc/systemd/system/lab-failing.service > /dev/null << 'EOF'
[Unit]
Description=Lab Failing Service for Troubleshooting Practice
After=network.target

[Service]
Type=simple
ExecStart=/opt/lab-scripts/failing-service.sh
Restart=no
User=root

[Install]
WantedBy=multi-user.target
EOF
Reload systemd and enable the service:
sudo systemctl daemon-reload
sudo systemctl enable lab-failing.service
Subtask 1.3: Troubleshooting the Failed Service
Start the service and observe the failure:
sudo systemctl start lab-failing.service
Check the service status:
systemctl status lab-failing.service
Use journalctl to examine detailed logs:
sudo journalctl -u lab-failing.service
View logs in real-time (open a second terminal for this):
sudo journalctl -u lab-failing.service -f
View logs with specific time range:
sudo journalctl -u lab-failing.service --since "10 minutes ago"
Show logs with higher verbosity:
sudo journalctl -u lab-failing.service -o verbose
Subtask 1.4: Fixing the Service
Edit the script to fix the issue:
sudo tee /opt/lab-scripts/failing-service.sh > /dev/null << 'EOF'
#!/bin/bash
echo "Service starting..."
sleep 5
echo "Service running successfully..."
echo "Current date: $(date)"
echo "Service completed successfully"
EOF
Restart the service:
sudo systemctl restart lab-failing.service
Verify the fix:
systemctl status lab-failing.service
sudo journalctl -u lab-failing.service --since "1 minute ago"
Task 2: Resolving Network Issues and Misconfigurations
Subtask 2.1: Network Diagnostics
Check network interface status:
ip addr show
View routing table:
ip route show
Check DNS configuration:
cat /etc/resolv.conf
Test network connectivity:
ping -c 4 8.8.8.8
ping -c 4 google.com
Subtask 2.2: Simulating Network Issues
Create a backup of network configuration:
sudo cp /etc/resolv.conf /etc/resolv.conf.backup
Simulate DNS issue by modifying resolv.conf:
sudo tee /etc/resolv.conf > /dev/null << 'EOF'
nameserver 192.168.999.999
nameserver 10.0.0.999
EOF
Test the DNS issue:
nslookup google.com
dig google.com
Subtask 2.3: Troubleshooting Network Services
Check if NetworkManager is running:
systemctl status NetworkManager
Examine NetworkManager logs:
sudo journalctl -u NetworkManager --since "10 minutes ago"
Check network interface configuration:
nmcli device status
nmcli connection show
Restart NetworkManager if needed:
sudo systemctl restart NetworkManager
Subtask 2.4: Fixing Network Configuration
Restore DNS configuration:
sudo cp /etc/resolv.conf.backup /etc/resolv.conf
Verify DNS resolution works:
nslookup google.com
dig google.com
Test network connectivity again:
ping -c 4 google.com
Task 3: Comprehensive Service Status and Log Analysis
Subtask 3.1: System-Wide Service Analysis
Check overall system status:
systemctl status
List all active services:
systemctl list-units --type=service --state=active
List all inactive services:
systemctl list-units --type=service --state=inactive
Check for any failed services:
systemctl --failed
Subtask 3.2: Critical Service Monitoring
Check SSH service (critical for remote access):
systemctl status sshd
sudo journalctl -u sshd --since today
Check firewall service:
systemctl status firewalld
sudo journalctl -u firewalld --since today
Check system logging service:
systemctl status rsyslog
sudo journalctl -u rsyslog --since today
Subtask 3.3: Advanced Log Analysis
View system boot logs:
sudo journalctl -b
Check for kernel messages:
sudo journalctl -k
View logs by priority (errors only):
sudo journalctl -p err
Check disk space used by logs:
sudo journalctl --disk-usage
View logs in JSON format for parsing:
sudo journalctl -u sshd -o json-pretty | head -20
Subtask 3.4: Creating a Service Health Check Script
Create a comprehensive health check script:
sudo tee /opt/lab-scripts/service-health-check.sh > /dev/null << 'EOF'
#!/bin/bash

echo "=== System Service Health Check ==="
echo "Date: $(date)"
echo

# Check critical services
CRITICAL_SERVICES=("sshd" "NetworkManager" "firewalld" "rsyslog")

echo "=== Critical Services Status ==="
for service in "${CRITICAL_SERVICES[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "✓ $service: ACTIVE"
    else
        echo "✗ $service: INACTIVE"
    fi
done

echo
echo "=== Failed Services ==="
failed_services=$(systemctl --failed --no-legend | wc -l)
if [ "$failed_services" -eq 0 ]; then
    echo "✓ No failed services"
else
    echo "✗ $failed_services failed services found:"
    systemctl --failed --no-legend
fi

echo
echo "=== Network Connectivity ==="
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo "✓ Internet connectivity: OK"
else
    echo "✗ Internet connectivity: FAILED"
fi

if nslookup google.com &> /dev/null; then
    echo "✓ DNS resolution: OK"
else
    echo "✗ DNS resolution: FAILED"
fi

echo
echo "=== Disk Space ==="
df -h / | tail -1 | awk '{print "Root filesystem: " $5 " used"}'

echo
echo "=== Recent Errors ==="
error_count=$(sudo journalctl -p err --since "1 hour ago" --no-pager | wc -l)
echo "Errors in last hour: $error_count"

echo
echo "Health check completed."
EOF
Make the script executable:
sudo chmod +x /opt/lab-scripts/service-health-check.sh
Run the health check:
sudo /opt/lab-scripts/service-health-check.sh
Troubleshooting Common Issues
Issue 1: Service Won't Start
Symptoms: Service fails to start with systemctl start

Troubleshooting Steps:

# Check service status
systemctl status service-name

# Check service configuration
systemctl cat service-name

# Check logs
sudo journalctl -u service-name

# Verify file permissions
ls -la /path/to/service/files
Issue 2: Network Connectivity Problems
Symptoms: Cannot reach external hosts

Troubleshooting Steps:

# Check interface status
ip addr show

# Check routing
ip route show

# Check DNS
cat /etc/resolv.conf
nslookup google.com

# Check firewall
sudo firewall-cmd --list-all
Issue 3: Service Keeps Restarting
Symptoms: Service shows as active but keeps restarting

Troubleshooting Steps:

# Check restart policy
systemctl show service-name | grep Restart

# Monitor in real-time
sudo journalctl -u service-name -f

# Check resource usage
systemctl status service-name
Lab Validation
To verify your lab completion, run these validation commands:

Verify systemctl knowledge:
systemctl list-units --type=service --state=failed
systemctl status lab-failing.service
Verify journalctl skills:
sudo journalctl -u lab-failing.service --since "30 minutes ago"
Verify network troubleshooting:
ping -c 2 google.com
nslookup google.com
Run the health check script:
sudo /opt/lab-scripts/service-health-check.sh
Conclusion
In this lab, you have successfully learned to:

Master systemctl commands for comprehensive service management and troubleshooting
Utilize journalctl effectively to analyze service logs and identify root causes of failures
Diagnose and resolve network issues using systematic troubleshooting approaches
Create automated health check scripts for proactive system monitoring
Apply best practices for service troubleshooting in enterprise environments
These skills are essential for the Red Hat Certified System Administrator (RHCSA) exam and real-world system administration. The ability to quickly identify, diagnose, and resolve service and network issues is crucial for maintaining system reliability and minimizing downtime in production environments.

Key Takeaways:

Always check service status before attempting fixes
Use journalctl with appropriate filters to find relevant log entries
Network issues often involve DNS, routing, or firewall configurations
Systematic troubleshooting saves time and prevents additional problems
Documentation and scripts help standardize troubleshooting procedures
Continue practicing these commands and techniques in different scenarios to build confidence and expertise in Linux system administration.
