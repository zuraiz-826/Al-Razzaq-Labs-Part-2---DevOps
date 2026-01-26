Lab 18: Systemd Unit Files for Custom Services
Objectives
By the end of this lab, students will be able to:

Understand the structure and components of systemd unit files
Create custom systemd unit files for various types of services
Configure service dependencies and startup behavior
Enable and manage custom services using systemctl commands
Test service functionality and verify automatic startup on boot
Troubleshoot common issues with custom systemd services
Implement best practices for service management and automation
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with text editors (nano, vim, or gedit)
Knowledge of file permissions and ownership concepts
Understanding of basic shell scripting
Experience with sudo privileges and system administration tasks
Completion of previous labs covering basic systemd concepts
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS system
Full sudo access
Pre-installed systemd (version 245 or later)
Text editors and development tools
Network connectivity for testing
Task 1: Create and Configure Systemd Unit Files for Custom Services
Subtask 1.1: Understanding Systemd Unit File Structure
First, let's examine the basic structure of systemd unit files and understand their components.

Step 1: Access your lab environment and open a terminal.

Step 2: Examine existing systemd unit files to understand the structure:

# View the structure of a simple service unit file
sudo systemctl cat sshd.service

# List all available unit file locations
systemctl show --property=UnitPath
Step 3: Create a working directory for our custom services:

# Create a directory for our lab work
mkdir ~/systemd-lab
cd ~/systemd-lab

# Create directories for our custom scripts and configurations
mkdir scripts
mkdir unit-files
Subtask 1.2: Create a Simple Custom Service
Let's create our first custom service - a simple web server script.

Step 1: Create a simple Python web server script:

# Create a simple web server script
cat > scripts/simple-webserver.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import signal
import sys
from datetime import datetime

PORT = 8080
DIRECTORY = "/tmp/webserver"

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def do_GET(self):
        if self.path == '/status':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            response = f"""
            <html>
            <body>
            <h1>Custom Web Server Status</h1>
            <p>Server is running on port {PORT}</p>
            <p>Current time: {datetime.now()}</p>
            <p>PID: {os.getpid()}</p>
            </body>
            </html>
            """
            self.wfile.write(response.encode())
        else:
            super().do_GET()

def signal_handler(signum, frame):
    print(f"Received signal {signum}, shutting down gracefully...")
    sys.exit(0)

def main():
    # Create web directory if it doesn't exist
    os.makedirs(DIRECTORY, exist_ok=True)
    
    # Create a simple index.html file
    with open(f"{DIRECTORY}/index.html", "w") as f:
        f.write("""
        <html>
        <body>
        <h1>Welcome to Custom Web Server</h1>
        <p>This is a custom systemd service!</p>
        <p><a href="/status">Check Status</a></p>
        </body>
        </html>
        """)
    
    # Set up signal handlers for graceful shutdown
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    print(f"Starting web server on port {PORT}")
    print(f"Serving directory: {DIRECTORY}")
    
    with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("Server interrupted, shutting down...")
        finally:
            httpd.shutdown()

if __name__ == "__main__":
    main()
EOF

# Make the script executable
chmod +x scripts/simple-webserver.py
Step 2: Test the script manually to ensure it works:

# Test the script (run in background)
python3 scripts/simple-webserver.py &
WEBSERVER_PID=$!

# Test the web server
curl http://localhost:8080/
curl http://localhost:8080/status

# Stop the test server
kill $WEBSERVER_PID
Step 3: Create the systemd unit file for our web server:

# Create the unit file
cat > unit-files/custom-webserver.service << 'EOF'
[Unit]
Description=Custom Python Web Server
Documentation=https://docs.python.org/3/library/http.server.html
After=network.target
Wants=network.target

[Service]
Type=simple
User=nobody
Group=nobody
WorkingDirectory=/tmp
ExecStart=/usr/bin/python3 /home/student/systemd-lab/scripts/simple-webserver.py
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/tmp

[Install]
WantedBy=multi-user.target
EOF
Subtask 1.3: Create a More Complex Service with Dependencies
Now let's create a more complex service that demonstrates dependencies and different service types.

Step 1: Create a log monitoring service:

# Create a log monitoring script
cat > scripts/log-monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/custom-monitor.log"
MONITOR_DIR="/tmp/monitor"
PID_FILE="/tmp/log-monitor.pid"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE"
}

# Function for graceful shutdown
cleanup() {
    log_message "Log monitor service stopping..."
    rm -f "$PID_FILE"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Create monitoring directory
mkdir -p "$MONITOR_DIR"

# Write PID file
echo $$ > "$PID_FILE"

log_message "Log monitor service starting..."
log_message "Monitoring directory: $MONITOR_DIR"
log_message "PID: $$"

# Main monitoring loop
while true; do
    # Count files in monitor directory
    FILE_COUNT=$(find "$MONITOR_DIR" -type f | wc -l)
    
    # Log current status
    log_message "Files in monitor directory: $FILE_COUNT"
    
    # Check system load
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    log_message "System load average: $LOAD_AVG"
    
    # Sleep for 30 seconds
    sleep 30
done
EOF

# Make the script executable
chmod +x scripts/log-monitor.sh
Step 2: Create the unit file for the log monitor:

# Create the log monitor unit file
cat > unit-files/log-monitor.service << 'EOF'
[Unit]
Description=Custom Log Monitor Service
Documentation=man:systemd.service(5)
After=multi-user.target
Requires=multi-user.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/home/student/systemd-lab/scripts/log-monitor.sh
ExecStop=/bin/kill -TERM $MAINPID
PIDFile=/tmp/log-monitor.pid
Restart=always
RestartSec=10
TimeoutStartSec=30
TimeoutStopSec=30

# Environment variables
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=log-monitor

[Install]
WantedBy=multi-user.target
EOF
Subtask 1.4: Create a Timer-Based Service
Let's create a service that runs periodically using systemd timers.

Step 1: Create a cleanup script:

# Create a system cleanup script
cat > scripts/system-cleanup.sh << 'EOF'
#!/bin/bash

CLEANUP_LOG="/var/log/system-cleanup.log"
TEMP_DIRS=("/tmp/cleanup-test" "/tmp/old-files")

# Function to log messages
log_cleanup() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CLEANUP: $1" | sudo tee -a "$CLEANUP_LOG"
}

log_cleanup "Starting system cleanup task..."

# Create test directories and files for cleanup demonstration
for dir in "${TEMP_DIRS[@]}"; do
    mkdir -p "$dir"
    
    # Create some test files older than 1 hour
    touch -d "2 hours ago" "$dir/old_file_1.tmp"
    touch -d "3 hours ago" "$dir/old_file_2.tmp"
    touch "$dir/new_file.tmp"
done

# Clean up old temporary files (older than 1 hour)
for dir in "${TEMP_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        OLD_FILES=$(find "$dir" -name "*.tmp" -type f -mmin +60 2>/dev/null)
        if [ -n "$OLD_FILES" ]; then
            echo "$OLD_FILES" | while read -r file; do
                rm -f "$file"
                log_cleanup "Removed old file: $file"
            done
        else
            log_cleanup "No old files found in $dir"
        fi
    fi
done

# Clean up empty directories
for dir in "${TEMP_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ]; then
        rmdir "$dir"
        log_cleanup "Removed empty directory: $dir"
    fi
done

# Report disk usage
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
log_cleanup "Current disk usage: $DISK_USAGE"

# Report memory usage
MEMORY_USAGE=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
log_cleanup "Current memory usage: $MEMORY_USAGE"

log_cleanup "System cleanup task completed successfully"
EOF

# Make the script executable
chmod +x scripts/system-cleanup.sh
Step 2: Create the service unit file for the cleanup task:

# Create the cleanup service unit file
cat > unit-files/system-cleanup.service << 'EOF'
[Unit]
Description=System Cleanup Task
Documentation=Custom cleanup service for temporary files

[Service]
Type=oneshot
User=root
Group=root
ExecStart=/home/student/systemd-lab/scripts/system-cleanup.sh
StandardOutput=journal
StandardError=journal
SyslogIdentifier=system-cleanup

# Security settings
NoNewPrivileges=true
PrivateNetwork=true
ProtectSystem=strict
ReadWritePaths=/tmp /var/log
EOF
Step 3: Create the timer unit file:

# Create the timer unit file
cat > unit-files/system-cleanup.timer << 'EOF'
[Unit]
Description=Run System Cleanup Every 15 Minutes
Documentation=Timer for system-cleanup.service
Requires=system-cleanup.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF
Task 2: Enable and Start Services Using Systemctl
Subtask 2.1: Install and Enable Custom Services
Now let's install our custom unit files and manage them with systemctl.

Step 1: Copy unit files to the system directory:

# Copy unit files to the systemd directory
sudo cp unit-files/*.service /etc/systemd/system/
sudo cp unit-files/*.timer /etc/systemd/system/

# Set proper permissions
sudo chmod 644 /etc/systemd/system/custom-webserver.service
sudo chmod 644 /etc/systemd/system/log-monitor.service
sudo chmod 644 /etc/systemd/system/system-cleanup.service
sudo chmod 644 /etc/systemd/system/system-cleanup.timer

# Verify files are in place
ls -la /etc/systemd/system/custom-* /etc/systemd/system/log-monitor.* /etc/systemd/system/system-cleanup.*
Step 2: Reload systemd to recognize new unit files:

# Reload systemd daemon
sudo systemctl daemon-reload

# Verify that systemd recognizes our new services
systemctl list-unit-files | grep -E "(custom-webserver|log-monitor|system-cleanup)"
Step 3: Enable and start the web server service:

# Enable the custom web server service
sudo systemctl enable custom-webserver.service

# Start the service
sudo systemctl start custom-webserver.service

# Check the status
systemctl status custom-webserver.service

# Verify the service is running
systemctl is-active custom-webserver.service
systemctl is-enabled custom-webserver.service
Subtask 2.2: Manage the Log Monitor Service
Step 1: Enable and start the log monitor service:

# Enable the log monitor service
sudo systemctl enable log-monitor.service

# Start the service
sudo systemctl start log-monitor.service

# Check the status
systemctl status log-monitor.service

# View the logs
sudo journalctl -u log-monitor.service -f --lines=10
Step 2: Test service management commands:

# Stop the service
sudo systemctl stop log-monitor.service

# Check status after stopping
systemctl status log-monitor.service

# Restart the service
sudo systemctl restart log-monitor.service

# Reload the service (if supported)
sudo systemctl reload-or-restart log-monitor.service
Subtask 2.3: Configure and Start Timer-Based Service
Step 1: Enable and start the cleanup timer:

# Enable the cleanup timer
sudo systemctl enable system-cleanup.timer

# Start the timer
sudo systemctl start system-cleanup.timer

# Check timer status
systemctl status system-cleanup.timer

# List all active timers
systemctl list-timers --all
Step 2: Test the cleanup service manually:

# Run the cleanup service manually
sudo systemctl start system-cleanup.service

# Check the service status
systemctl status system-cleanup.service

# View the cleanup logs
sudo journalctl -u system-cleanup.service --lines=20
Task 3: Test Service Functionality and Automatic Start on Boot
Subtask 3.1: Test Web Server Functionality
Step 1: Verify web server is responding:

# Test the web server endpoints
curl -s http://localhost:8080/ | head -5
curl -s http://localhost:8080/status

# Test with wget as alternative
wget -qO- http://localhost:8080/status

# Check if the service is listening on the correct port
sudo netstat -tlnp | grep :8080
# or use ss command
sudo ss -tlnp | grep :8080
Step 2: Test service resilience:

# Get the current PID of the web server
WEB_PID=$(systemctl show --property MainPID custom-webserver.service | cut -d= -f2)
echo "Web server PID: $WEB_PID"

# Kill the process to test restart behavior
sudo kill -9 $WEB_PID

# Wait a moment and check if systemd restarted it
sleep 10
systemctl status custom-webserver.service

# Verify it's still responding
curl -s http://localhost:8080/status
Subtask 3.2: Test Log Monitor Functionality
Step 1: Verify log monitor is working:

# Check the log file created by the monitor
sudo tail -f /var/log/custom-monitor.log &
TAIL_PID=$!

# Create some files in the monitored directory to see changes
mkdir -p /tmp/monitor
touch /tmp/monitor/test1.txt /tmp/monitor/test2.txt

# Wait for the next monitoring cycle (30 seconds)
sleep 35

# Stop tailing the log
kill $TAIL_PID

# View recent log entries
sudo tail -10 /var/log/custom-monitor.log
Step 2: Test log monitor restart behavior:

# Restart the log monitor service
sudo systemctl restart log-monitor.service

# Verify it restarted successfully
systemctl status log-monitor.service

# Check that logging resumed
sleep 35
sudo tail -5 /var/log/custom-monitor.log
Subtask 3.3: Test Timer-Based Service
Step 1: Verify timer functionality:

# Check when the timer will next run
systemctl list-timers system-cleanup.timer

# View timer details
systemctl show system-cleanup.timer

# Check cleanup service logs
sudo journalctl -u system-cleanup.service --since "10 minutes ago"
Step 2: Test manual timer trigger:

# Trigger the cleanup service manually
sudo systemctl start system-cleanup.service

# Check the execution
systemctl status system-cleanup.service

# View the cleanup log
sudo tail -10 /var/log/system-cleanup.log
Subtask 3.4: Test Automatic Start on Boot
Step 1: Verify services are enabled for boot:

# Check which services are enabled
systemctl is-enabled custom-webserver.service
systemctl is-enabled log-monitor.service
systemctl is-enabled system-cleanup.timer

# List all enabled custom services
systemctl list-unit-files --state=enabled | grep -E "(custom|log-monitor|system-cleanup)"
Step 2: Simulate boot test (if possible):

# Stop all our custom services
sudo systemctl stop custom-webserver.service
sudo systemctl stop log-monitor.service
sudo systemctl stop system-cleanup.timer

# Check they are stopped
systemctl is-active custom-webserver.service
systemctl is-active log-monitor.service
systemctl is-active system-cleanup.timer

# Start the targets they depend on to simulate boot
sudo systemctl start multi-user.target
sudo systemctl start timers.target

# Wait a moment and check if services started automatically
sleep 10
systemctl is-active custom-webserver.service
systemctl is-active log-monitor.service
systemctl is-active system-cleanup.timer
Subtask 3.5: Performance and Dependency Testing
Step 1: Test service dependencies:

# View service dependency tree
systemctl list-dependencies custom-webserver.service
systemctl list-dependencies log-monitor.service
systemctl list-dependencies system-cleanup.timer

# Check what depends on our services
systemctl list-dependencies --reverse custom-webserver.service
Step 2: Monitor service performance:

# Check resource usage of our services
systemctl show custom-webserver.service --property=MainPID
systemctl show log-monitor.service --property=MainPID

# Get PIDs and check resource usage
WEB_PID=$(systemctl show --property MainPID custom-webserver.service | cut -d= -f2)
LOG_PID=$(systemctl show --property MainPID log-monitor.service | cut -d= -f2)

if [ "$WEB_PID" != "0" ]; then
    echo "Web server resource usage:"
    ps -p $WEB_PID -o pid,ppid,cmd,%mem,%cpu
fi

if [ "$LOG_PID" != "0" ]; then
    echo "Log monitor resource usage:"
    ps -p $LOG_PID -o pid,ppid,cmd,%mem,%cpu
fi
Subtask 3.6: Comprehensive Service Testing
Step 1: Create a comprehensive test script:

# Create a test script to verify all services
cat > scripts/test-services.sh << 'EOF'
#!/bin/bash

echo "=== Custom Services Test Report ==="
echo "Generated on: $(date)"
echo

# Test web server
echo "1. Testing Custom Web Server:"
if systemctl is-active --quiet custom-webserver.service; then
    echo "   ✓ Service is active"
    if curl -s http://localhost:8080/status > /dev/null; then
        echo "   ✓ Web server is responding"
    else
        echo "   ✗ Web server is not responding"
    fi
else
    echo "   ✗ Service is not active"
fi

# Test log monitor
echo
echo "2. Testing Log Monitor:"
if systemctl is-active --quiet log-monitor.service; then
    echo "   ✓ Service is active"
    if [ -f /var/log/custom-monitor.log ]; then
        LAST_LOG=$(sudo tail -1 /var/log/custom-monitor.log)
        echo "   ✓ Log file exists"
        echo "   Last log entry: $LAST_LOG"
    else
        echo "   ✗ Log file not found"
    fi
else
    echo "   ✗ Service is not active"
fi

# Test cleanup timer
echo
echo "3. Testing Cleanup Timer:"
if systemctl is-active --quiet system-cleanup.timer; then
    echo "   ✓ Timer is active"
    NEXT_RUN=$(systemctl list-timers system-cleanup.timer --no-pager | grep system-cleanup.timer | awk '{print $1, $2}')
    echo "   Next run: $NEXT_RUN"
else
    echo "   ✗ Timer is not active"
fi

# Check enabled status
echo
echo "4. Boot Startup Status:"
echo "   Web Server: $(systemctl is-enabled custom-webserver.service)"
echo "   Log Monitor: $(systemctl is-enabled log-monitor.service)"
echo "   Cleanup Timer: $(systemctl is-enabled system-cleanup.timer)"

echo
echo "=== Test Complete ==="
EOF

chmod +x scripts/test-services.sh

# Run the test script
./scripts/test-services.sh
Step 2: Test service failure and recovery:

# Test service failure scenarios
echo "Testing service failure and recovery..."

# Kill web server process and verify restart
WEB_PID=$(systemctl show --property MainPID custom-webserver.service | cut -d= -f2)
if [ "$WEB_PID" != "0" ]; then
    echo "Killing web server process $WEB_PID"
    sudo kill -9 $WEB_PID
    
    echo "Waiting for restart..."
    sleep 10
    
    if systemctl is-active --quiet custom-webserver.service; then
        echo "✓ Web server restarted successfully"
    else
        echo "✗ Web server failed to restart"
    fi
fi

# Test configuration reload
echo "Testing configuration reload..."
sudo systemctl reload-or-restart custom-webserver.service
systemctl status custom-webserver.service --no-pager -l
Troubleshooting Common Issues
Common Problems and Solutions
Problem 1: Service fails to start with permission errors

# Check service status for detailed error messages
systemctl status service-name.service -l

# Check journal logs for more details
journalctl -u service-name.service --since "1 hour ago"

# Verify file permissions
ls -la /path/to/script
ls -la /etc/systemd/system/service-name.service
Problem 2: Service starts but doesn't work as expected

# Check if the service is actually running
systemctl is-active service-name.service

# Check the process list
ps aux | grep service-name

# Check network ports (for network services)
sudo netstat -tlnp | grep port-number
Problem 3: Timer not triggering service

# Check timer status
systemctl list-timers --all

# Verify timer configuration
systemctl cat timer-name.timer

# Check timer logs
journalctl -u timer-name.timer
Debugging Commands
# Reload systemd after making changes
sudo systemctl daemon-reload

# Check unit file syntax
systemd-analyze verify /etc/systemd/system/service-name.service

# View service dependencies
systemctl list-dependencies service-name.service

# Check system boot time and service startup times
systemd-analyze blame

# View detailed service information
systemctl show service-name.service
Cleanup and Service Management
Stopping and Disabling Services
When you're done with the lab, you can clean up the services:

# Stop all custom services
sudo systemctl stop custom-webserver.service
sudo systemctl stop log-monitor.service
sudo systemctl stop system-cleanup.timer

# Disable services from starting at boot
sudo systemctl disable custom-webserver.service
sudo systemctl disable log-monitor.service
sudo systemctl disable system-cleanup.timer

# Remove unit files (optional)
sudo rm /etc/systemd/system/custom-webserver.service
sudo rm /etc/systemd/system/log-monitor.service
sudo rm /etc/systemd/system/system-cleanup.service
sudo rm /etc/systemd/system/system-cleanup.timer

# Reload systemd
sudo systemctl daemon-reload

# Clean up log files (optional)
sudo rm -f /var/log/custom-monitor.log
sudo rm -f /var/log/system-cleanup.log
Conclusion
In this comprehensive lab, you have successfully:

Mastered Systemd Unit File Creation: You learned how to create different types of systemd unit files including simple services, complex services with dependencies, and timer-based services. You understand the structure and key sections of unit files including [Unit], [Service], and [Install] sections.

Implemented Service Management: You gained hands-on experience with systemctl commands to enable, start, stop, restart, and monitor custom services. You learned how to check service status, view logs, and troubleshoot common issues.

Configured Automatic Startup: You successfully configured services to start automatically at boot time and verified their functionality. You understand how systemd targets work and how services integrate with the boot process.

Applied Security Best Practices: You implemented security settings in unit files including user/group restrictions, filesystem protections, and privilege limitations to ensure services run securely.

Tested Service Resilience: You verified that services can recover from failures, restart automatically, and maintain their functionality under various conditions.

Utilized Advanced Features: You worked with systemd timers for scheduled tasks, implemented proper logging and monitoring, and learned how to create services with complex dependencies.

This knowledge is essential for the Red Hat Certified Specialist in Services Management and Automation exam and provides you with practical skills for managing enterprise Linux systems. Understanding systemd unit files and service management is crucial for system administrators who need to deploy, manage, and maintain custom applications and services in production environments.

The skills you've developed in this lab will enable you to:

Create robust, production-ready services
Implement proper service monitoring and logging
Ensure services start reliably and recover from failures
Apply security best practices to service deployment
Automate system maintenance tasks using timers
Troubleshoot service-related issues effectively
These capabilities are fundamental for modern Linux system administration and are highly valued in enterprise environments where reliable service management is critical for business operations.
