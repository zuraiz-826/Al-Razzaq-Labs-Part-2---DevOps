Lab 6: Managing Resource Limits with cgroups
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of Control Groups (cgroups) and their role in resource management
Create and configure cgroups to limit CPU, memory, and I/O usage for processes
Monitor resource usage of processes using cgroups statistics and tools
Fine-tune resource allocations based on system requirements and performance metrics
Implement practical resource management scenarios using cgroups v2
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and terminal operations
Knowledge of process management concepts
Understanding of system resources (CPU, memory, I/O)
Basic knowledge of file system navigation and permissions
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

Ubuntu 22.04 LTS or CentOS Stream 9 with cgroups v2 enabled
Root access for system configuration
Pre-installed monitoring tools
Sample applications for testing
Task 1: Understanding and Setting Up cgroups
Subtask 1.1: Verify cgroups Version and Mount Point
First, let's check which version of cgroups is available and where it's mounted.

# Check cgroups version
mount | grep cgroup

# Verify cgroups v2 is available
ls -la /sys/fs/cgroup/

# Check if systemd is using cgroups v2
systemctl --version
Subtask 1.2: Explore the cgroups Hierarchy
Navigate through the cgroups filesystem to understand its structure.

# Navigate to cgroups root
cd /sys/fs/cgroup

# List available controllers
cat cgroup.controllers

# Check current processes in root cgroup
cat cgroup.procs

# View available subtree controllers
cat cgroup.subtree_control
Subtask 1.3: Create Your First Custom cgroup
Create a custom cgroup for our lab exercises.

# Create a new cgroup directory
sudo mkdir /sys/fs/cgroup/lab6_demo

# Verify the cgroup was created
ls -la /sys/fs/cgroup/lab6_demo/

# Check available controllers for our new cgroup
cat /sys/fs/cgroup/lab6_demo/cgroup.controllers
Task 2: Configuring CPU Limits with cgroups
Subtask 2.1: Enable CPU Controller
Enable the CPU controller for our custom cgroup.

# Enable CPU controller in the parent cgroup
echo "+cpu" | sudo tee /sys/fs/cgroup/cgroup.subtree_control

# Verify CPU controller is available in our cgroup
cat /sys/fs/cgroup/lab6_demo/cgroup.controllers
Subtask 2.2: Set CPU Limits
Configure CPU usage limits for processes in our cgroup.

# Set CPU weight (relative priority, default is 100)
echo "50" | sudo tee /sys/fs/cgroup/lab6_demo/cpu.weight

# Set CPU maximum usage (50% of one CPU core)
echo "50000 100000" | sudo tee /sys/fs/cgroup/lab6_demo/cpu.max

# Verify the settings
cat /sys/fs/cgroup/lab6_demo/cpu.weight
cat /sys/fs/cgroup/lab6_demo/cpu.max
Subtask 2.3: Test CPU Limits with a CPU-Intensive Process
Create and run a CPU-intensive script to test our limits.

# Create a CPU stress script
cat << 'EOF' > /tmp/cpu_stress.sh
#!/bin/bash
echo "Starting CPU stress test..."
while true; do
    echo "scale=5000; 4*a(1)" | bc -l > /dev/null
done
EOF

# Make the script executable
chmod +x /tmp/cpu_stress.sh

# Run the script in background
/tmp/cpu_stress.sh &
CPU_PID=$!

# Add the process to our cgroup
echo $CPU_PID | sudo tee /sys/fs/cgroup/lab6_demo/cgroup.procs

# Monitor CPU usage (run this in another terminal)
top -p $CPU_PID
Subtask 2.4: Monitor CPU Usage Statistics
Check the CPU usage statistics for our cgroup.

# View CPU statistics
cat /sys/fs/cgroup/lab6_demo/cpu.stat

# Monitor CPU usage over time
watch -n 1 cat /sys/fs/cgroup/lab6_demo/cpu.stat

# Stop the CPU stress test
kill $CPU_PID
Task 3: Configuring Memory Limits with cgroups
Subtask 3.1: Enable Memory Controller
Enable the memory controller for our cgroup.

# Enable memory controller
echo "+memory" | sudo tee /sys/fs/cgroup/cgroup.subtree_control

# Verify memory controller is available
cat /sys/fs/cgroup/lab6_demo/cgroup.controllers
Subtask 3.2: Set Memory Limits
Configure memory usage limits for processes.

# Set memory limit to 100MB
echo "104857600" | sudo tee /sys/fs/cgroup/lab6_demo/memory.max

# Set memory high watermark to 80MB (soft limit)
echo "83886080" | sudo tee /sys/fs/cgroup/lab6_demo/memory.high

# Verify the settings
cat /sys/fs/cgroup/lab6_demo/memory.max
cat /sys/fs/cgroup/lab6_demo/memory.high
Subtask 3.3: Test Memory Limits
Create a memory-intensive script to test our limits.

# Create a memory stress script
cat << 'EOF' > /tmp/memory_stress.py
#!/usr/bin/env python3
import time
import sys

print("Starting memory stress test...")
memory_chunks = []

try:
    for i in range(200):  # Try to allocate 200MB
        chunk = bytearray(1024 * 1024)  # 1MB chunk
        memory_chunks.append(chunk)
        print(f"Allocated {i+1} MB")
        time.sleep(0.1)
except MemoryError:
    print("Memory allocation failed - limit reached!")
except KeyboardInterrupt:
    print("Test interrupted")

print("Holding memory for 30 seconds...")
time.sleep(30)
EOF

# Make the script executable
chmod +x /tmp/memory_stress.py

# Run the script and add to cgroup
python3 /tmp/memory_stress.py &
MEMORY_PID=$!
echo $MEMORY_PID | sudo tee /sys/fs/cgroup/lab6_demo/cgroup.procs
Subtask 3.4: Monitor Memory Usage
Monitor memory usage and statistics.

# View current memory usage
cat /sys/fs/cgroup/lab6_demo/memory.current

# View memory statistics
cat /sys/fs/cgroup/lab6_demo/memory.stat

# Monitor memory usage in real-time
watch -n 1 "echo 'Current:'; cat /sys/fs/cgroup/lab6_demo/memory.current; echo 'Events:'; cat /sys/fs/cgroup/lab6_demo/memory.events"

# Clean up
kill $MEMORY_PID 2>/dev/null || true
Task 4: Configuring I/O Limits with cgroups
Subtask 4.1: Enable I/O Controller
Enable the I/O controller for our cgroup.

# Enable I/O controller
echo "+io" | sudo tee /sys/fs/cgroup/cgroup.subtree_control

# Verify I/O controller is available
cat /sys/fs/cgroup/lab6_demo/cgroup.controllers

# Find the device number for our root filesystem
df / | tail -1 | awk '{print $1}' | xargs lsblk -no MAJOR:MINOR
Subtask 4.2: Set I/O Limits
Configure I/O bandwidth limits. Replace 8:0 with your actual device major:minor numbers.

# Get the device major:minor for root filesystem
DEVICE=$(df / | tail -1 | awk '{print $1}' | xargs lsblk -no MAJOR:MINOR | tr -d ' ')
echo "Device: $DEVICE"

# Set read bandwidth limit to 10MB/s
echo "$DEVICE rbps=10485760" | sudo tee /sys/fs/cgroup/lab6_demo/io.max

# Set write bandwidth limit to 5MB/s
echo "$DEVICE wbps=5242880" | sudo tee -a /sys/fs/cgroup/lab6_demo/io.max

# Verify the settings
cat /sys/fs/cgroup/lab6_demo/io.max
Subtask 4.3: Test I/O Limits
Create and test I/O-intensive operations.

# Create a test directory
mkdir -p /tmp/io_test

# Create an I/O stress script
cat << 'EOF' > /tmp/io_stress.sh
#!/bin/bash
echo "Starting I/O stress test..."

# Write test
echo "Testing write performance..."
dd if=/dev/zero of=/tmp/io_test/testfile bs=1M count=100 2>&1 | grep -E "(copied|MB/s)"

# Read test
echo "Testing read performance..."
dd if=/tmp/io_test/testfile of=/dev/null bs=1M 2>&1 | grep -E "(copied|MB/s)"

# Cleanup
rm -f /tmp/io_test/testfile
EOF

chmod +x /tmp/io_stress.sh

# Run I/O test without limits first
echo "Running I/O test WITHOUT limits:"
/tmp/io_stress.sh

# Run I/O test with limits
echo "Running I/O test WITH limits:"
/tmp/io_stress.sh &
IO_PID=$!
echo $IO_PID | sudo tee /sys/fs/cgroup/lab6_demo/cgroup.procs
wait $IO_PID
Subtask 4.4: Monitor I/O Statistics
Monitor I/O usage and statistics.

# View I/O statistics
cat /sys/fs/cgroup/lab6_demo/io.stat

# Monitor I/O statistics in real-time during a test
watch -n 1 cat /sys/fs/cgroup/lab6_demo/io.stat &
WATCH_PID=$!

# Run another I/O test
/tmp/io_stress.sh &
IO_PID=$!
echo $IO_PID | sudo tee /sys/fs/cgroup/lab6_demo/cgroup.procs
wait $IO_PID

# Stop monitoring
kill $WATCH_PID 2>/dev/null || true
Task 5: Advanced Resource Monitoring and Fine-Tuning
Subtask 5.1: Create a Comprehensive Monitoring Script
Create a script to monitor all resource usage in real-time.

# Create a comprehensive monitoring script
cat << 'EOF' > /tmp/cgroup_monitor.sh
#!/bin/bash

CGROUP_PATH="/sys/fs/cgroup/lab6_demo"

echo "=== cgroup Resource Monitor ==="
echo "Monitoring cgroup: $CGROUP_PATH"
echo "Press Ctrl+C to stop"
echo

while true; do
    clear
    echo "=== cgroup Resource Monitor - $(date) ==="
    echo
    
    # CPU Statistics
    echo "CPU Statistics:"
    if [ -f "$CGROUP_PATH/cpu.stat" ]; then
        cat "$CGROUP_PATH/cpu.stat" | while read line; do
            echo "  $line"
        done
    fi
    echo
    
    # Memory Statistics
    echo "Memory Usage:"
    if [ -f "$CGROUP_PATH/memory.current" ]; then
        current=$(cat "$CGROUP_PATH/memory.current")
        max=$(cat "$CGROUP_PATH/memory.max")
        echo "  Current: $(($current / 1024 / 1024)) MB"
        echo "  Limit: $(($max / 1024 / 1024)) MB"
        echo "  Usage: $((current * 100 / max))%"
    fi
    echo
    
    # I/O Statistics
    echo "I/O Statistics:"
    if [ -f "$CGROUP_PATH/io.stat" ]; then
        cat "$CGROUP_PATH/io.stat" | while read line; do
            echo "  $line"
        done
    fi
    echo
    
    # Process Count
    echo "Processes in cgroup:"
    if [ -f "$CGROUP_PATH/cgroup.procs" ]; then
        proc_count=$(cat "$CGROUP_PATH/cgroup.procs" | wc -l)
        echo "  Count: $proc_count"
        if [ $proc_count -gt 0 ]; then
            echo "  PIDs: $(cat "$CGROUP_PATH/cgroup.procs" | tr '\n' ' ')"
        fi
    fi
    
    sleep 2
done
EOF

chmod +x /tmp/cgroup_monitor.sh
Subtask 5.2: Fine-Tune Resource Allocations
Adjust resource limits based on monitoring results.

# Start monitoring in background
/tmp/cgroup_monitor.sh &
MONITOR_PID=$!

# Create a mixed workload script
cat << 'EOF' > /tmp/mixed_workload.sh
#!/bin/bash
echo "Starting mixed workload..."

# CPU component
(while true; do echo "scale=1000; 4*a(1)" | bc -l > /dev/null; done) &
CPU_WORKER=$!

# Memory component
python3 -c "
import time
data = []
for i in range(50):
    data.append(bytearray(1024*1024))  # 1MB chunks
    time.sleep(0.5)
time.sleep(10)
" &
MEM_WORKER=$!

# I/O component
(for i in {1..10}; do
    dd if=/dev/zero of=/tmp/io_test/file_$i bs=1M count=10 2>/dev/null
    sleep 1
done) &
IO_WORKER=$!

echo "Workload PIDs: CPU=$CPU_WORKER, MEM=$MEM_WORKER, IO=$IO_WORKER"
wait $CPU_WORKER $MEM_WORKER $IO_WORKER 2>/dev/null
EOF

chmod +x /tmp/mixed_workload.sh

# Run mixed workload in our cgroup
/tmp/mixed_workload.sh &
WORKLOAD_PID=$!
echo $WORKLOAD_PID | sudo tee /sys/fs/cgroup/lab6_demo/cgroup.procs

# Let it run for a bit, then adjust limits
sleep 10

# Fine-tune CPU limits (increase to 75%)
echo "75000 100000" | sudo tee /sys/fs/cgroup/lab6_demo/cpu.max

# Fine-tune memory limits (increase to 150MB)
echo "157286400" | sudo tee /sys/fs/cgroup/lab6_demo/memory.max

echo "Limits adjusted - observe the changes in the monitor"
sleep 15

# Stop monitoring and workload
kill $MONITOR_PID $WORKLOAD_PID 2>/dev/null || true
Subtask 5.3: Create Persistent cgroup Configuration
Create a systemd service to make cgroup configuration persistent.

# Create a systemd service file
sudo tee /etc/systemd/system/lab6-cgroup.service << 'EOF'
[Unit]
Description=Lab 6 cgroup Configuration
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'mkdir -p /sys/fs/cgroup/lab6_demo && \
    echo "+cpu +memory +io" > /sys/fs/cgroup/cgroup.subtree_control && \
    echo "50000 100000" > /sys/fs/cgroup/lab6_demo/cpu.max && \
    echo "50" > /sys/fs/cgroup/lab6_demo/cpu.weight && \
    echo "104857600" > /sys/fs/cgroup/lab6_demo/memory.max && \
    echo "83886080" > /sys/fs/cgroup/lab6_demo/memory.high'

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable lab6-cgroup.service
sudo systemctl start lab6-cgroup.service

# Verify the service status
sudo systemctl status lab6-cgroup.service
Task 6: Practical Scenarios and Troubleshooting
Subtask 6.1: Scenario - Web Server Resource Management
Create a realistic scenario managing resources for a web server.

# Create a simple web server simulation
cat << 'EOF' > /tmp/web_server_sim.py
#!/usr/bin/env python3
import http.server
import socketserver
import threading
import time
import random

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Simulate some CPU work
        for _ in range(random.randint(1000, 10000)):
            _ = sum(range(100))
        
        # Simulate memory usage
        data = bytearray(random.randint(1024, 10240))  # 1-10KB
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b'<html><body><h1>Web Server Response</h1></body></html>')

PORT = 8080
with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
    print(f"Web server running on port {PORT}")
    httpd.serve_forever()
EOF

# Create web server cgroup with appropriate limits
sudo mkdir -p /sys/fs/cgroup/webserver
echo "+cpu +memory +io" | sudo tee /sys/fs/cgroup/cgroup.subtree_control

# Set conservative limits for web server
echo "30000 100000" | sudo tee /sys/fs/cgroup/webserver/cpu.max  # 30% CPU
echo "52428800" | sudo tee /sys/fs/cgroup/webserver/memory.max   # 50MB RAM

# Start web server in cgroup
python3 /tmp/web_server_sim.py &
WEB_PID=$!
echo $WEB_PID | sudo tee /sys/fs/cgroup/webserver/cgroup.procs

echo "Web server started with PID $WEB_PID"
echo "Test with: curl http://localhost:8080"

# Generate some load
for i in {1..20}; do
    curl -s http://localhost:8080 > /dev/null &
done

sleep 10
kill $WEB_PID 2>/dev/null || true
Subtask 6.2: Troubleshooting Common Issues
Learn to identify and resolve common cgroup issues.

# Create a troubleshooting script
cat << 'EOF' > /tmp/cgroup_troubleshoot.sh
#!/bin/bash

echo "=== cgroup Troubleshooting Guide ==="
echo

# Check if cgroups v2 is properly mounted
echo "1. Checking cgroups v2 mount:"
if mount | grep -q "cgroup2"; then
    echo "   ✓ cgroups v2 is mounted"
else
    echo "   ✗ cgroups v2 not found"
    echo "   Solution: Ensure kernel supports cgroups v2 and systemd is configured properly"
fi
echo

# Check available controllers
echo "2. Checking available controllers:"
if [ -f "/sys/fs/cgroup/cgroup.controllers" ]; then
    controllers=$(cat /sys/fs/cgroup/cgroup.controllers)
    echo "   Available: $controllers"
    
    for ctrl in cpu memory io; do
        if echo "$controllers" | grep -q "$ctrl"; then
            echo "   ✓ $ctrl controller available"
        else
            echo "   ✗ $ctrl controller not available"
        fi
    done
else
    echo "   ✗ Cannot read controller information"
fi
echo

# Check permissions
echo "3. Checking permissions:"
if [ -w "/sys/fs/cgroup" ]; then
    echo "   ✓ Write access to cgroup filesystem"
else
    echo "   ✗ No write access - run with sudo"
fi
echo

# Check for common configuration errors
echo "4. Checking for common issues:"

# Check if subtree_control is properly configured
if [ -f "/sys/fs/cgroup/lab6_demo/cgroup.controllers" ]; then
    enabled=$(cat /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || echo "")
    available=$(cat /sys/fs/cgroup/lab6_demo/cgroup.controllers 2>/dev/null || echo "")
    
    echo "   Parent subtree_control: $enabled"
    echo "   Child controllers: $available"
    
    if [ -z "$available" ]; then
        echo "   ✗ No controllers available in child cgroup"
        echo "   Solution: Enable controllers in parent with 'echo \"+cpu +memory +io\" > /sys/fs/cgroup/cgroup.subtree_control'"
    fi
fi

echo
echo "=== End Troubleshooting ==="
EOF

chmod +x /tmp/cgroup_troubleshoot.sh
/tmp/cgroup_troubleshoot.sh
Subtask 6.3: Performance Comparison
Compare performance with and without cgroup limits.

# Create performance comparison script
cat << 'EOF' > /tmp/performance_comparison.sh
#!/bin/bash

echo "=== Performance Comparison: With vs Without cgroups ==="
echo

# Test function
run_performance_test() {
    local test_name="$1"
    local use_cgroup="$2"
    
    echo "Running $test_name..."
    
    # CPU test
    echo "  CPU Test (calculating pi):"
    start_time=$(date +%s.%N)
    
    if [ "$use_cgroup" = "true" ]; then
        (echo "scale=2000; 4*a(1)" | bc -l > /dev/null) &
        test_pid=$!
        echo $test_pid | sudo tee /sys/fs/cgroup/lab6_demo/cgroup.procs > /dev/null
        wait $test_pid
    else
        echo "scale=2000; 4*a(1)" | bc -l > /dev/null
    fi
    
    end_time=$(date +%s.%N)
    cpu_time=$(echo "$end_time - $start_time" | bc)
    echo "    Time: ${cpu_time}s"
    
    # Memory allocation test
    echo "  Memory Test (allocating 50MB):"
    start_time=$(date +%s.%N)
    
    if [ "$use_cgroup" = "true" ]; then
        (python3 -c "
data = []
for i in range(50):
    data.append(bytearray(1024*1024))
import time; time.sleep(1)
") &
        test_pid=$!
        echo $test_pid | sudo tee /sys/fs/cgroup/lab6_demo/cgroup.procs > /dev/null
        wait $test_pid
    else
        python3 -c "
data = []
for i in range(50):
    data.append(bytearray(1024*1024))
import time; time.sleep(1)
"
    fi
    
    end_time=$(date +%s.%N)
    mem_time=$(echo "$end_time - $start_time" | bc)
    echo "    Time: ${mem_time}s"
    
    echo
}

# Run tests
run_performance_test "Test WITHOUT cgroups" "false"
run_performance_test "Test WITH cgroups" "true"

echo "Note: cgroup-limited processes should show longer execution times"
echo "due to resource constraints."
EOF

chmod +x /tmp/performance_comparison.sh
/tmp/performance_comparison.sh
Cleanup and Lab Conclusion
Cleanup Resources
Clean up all created resources and processes.

# Kill any remaining processes
sudo pkill -f "cpu_stress\|memory_stress\|io_stress\|web_server_sim" 2>/dev/null || true

# Remove test files
rm -rf /tmp/io_test
rm -f /tmp/cpu_stress.sh /tmp/memory_stress.py /tmp/io_stress.sh
rm -f /tmp/mixed_workload.sh /tmp/web_server_sim.py
rm -f /tmp/cgroup_monitor.sh /tmp/cgroup_troubleshoot.sh
rm -f /tmp/performance_comparison.sh

# Remove custom cgroups
sudo rmdir /sys/fs/cgroup/lab6_demo 2>/dev/null || true
sudo rmdir /sys/fs/cgroup/webserver 2>/dev/null || true

# Disable and remove systemd service
sudo systemctl stop lab6-cgroup.service 2>/dev/null || true
sudo systemctl disable lab6-cgroup.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/lab6-cgroup.service
sudo systemctl daemon-reload

echo "Cleanup completed successfully!"
Conclusion
Congratulations! You have successfully completed Lab 6 on Managing Resource Limits with cgroups. Throughout this comprehensive lab, you have accomplished the following:

Key Achievements:

Mastered cgroups Fundamentals: You learned how to navigate and understand the cgroups v2 filesystem structure, enabling you to effectively manage system resources.

Implemented CPU Resource Management: You successfully created CPU limits using both weight-based priority and maximum usage constraints, demonstrating how to control processor allocation for different processes.

Configured Memory Constraints: You established memory limits and monitoring systems, learning how to prevent processes from consuming excessive RAM and potentially destabilizing the system.

Managed I/O Bandwidth: You implemented I/O throttling controls to manage disk read/write operations, ensuring fair resource distribution among competing processes.

Developed Monitoring Skills: You created comprehensive monitoring solutions to track resource usage in real-time, enabling data-driven decisions for resource allocation.

Applied Practical Scenarios: You worked through realistic use cases like web server resource management, preparing you for real-world system administration challenges.

Why This Matters:

Resource management with cgroups is crucial in modern computing environments because it:

Ensures System Stability: Prevents any single process or application from monopolizing system resources
Improves Performance: Allows for fair resource distribution and prevents resource contention
Enables Containerization: Forms the foundation for container technologies like Docker and Kubernetes
Supports Multi-tenancy: Allows multiple applications or users to share system resources safely
Facilitates Performance Tuning: Provides granular control for optimizing system performance
Real-World Applications:

The skills you've developed in this lab are directly applicable to:

Container orchestration platforms
Cloud computing resource management
High-performance computing environments
Database server optimization
Web server performance tuning
Multi-user system administration
You are now equipped with the knowledge and practical experience to implement sophisticated resource management strategies in production environments, making you a more effective system administrator and contributing to your preparation for the Red Hat Performance Tuning certification.
