Lab 2: Setting Up Performance Monitoring Tools
Objectives
By the end of this lab, students will be able to:

Install and configure essential performance monitoring tools on Red Hat Enterprise Linux (RHEL)
Execute initial performance tests using various monitoring utilities
Gather and interpret system resource usage data
Understand the purpose and functionality of each monitoring tool
Create baseline performance measurements for system optimization
Prerequisites
Before starting this lab, students should have:

Basic knowledge of Linux command line interface
Understanding of system processes and resource management concepts
Familiarity with package management in RHEL
Root or sudo access to a RHEL system
Basic understanding of system performance metrics (CPU, memory, disk I/O, network)
Lab Environment
Al Nafi Cloud Machine Setup: This lab uses Al Nafi's pre-configured Linux-based cloud machines. Simply click Start Lab to access your ready-to-use RHEL environment. No need to build your own virtual machine or configure additional settings.

Your cloud machine includes:

Red Hat Enterprise Linux 8/9
Root access via sudo
Network connectivity for package installation
Pre-configured terminal access
Task 1: Installing Performance Monitoring Tools
Subtask 1.1: Update System Packages
First, ensure your system packages are up to date before installing monitoring tools.

# Update the system package repository
sudo dnf update -y

# Verify system version
cat /etc/redhat-release
Subtask 1.2: Install Core Monitoring Tools
Install the essential performance monitoring tools using the DNF package manager.

# Install procps-ng package (contains top, vmstat, and other tools)
sudo dnf install -y procps-ng

# Install sysstat package (contains iostat, sar, and other utilities)
sudo dnf install -y sysstat

# Install dstat package
sudo dnf install -y dstat

# Install perf package for advanced performance analysis
sudo dnf install -y perf

# Verify installations
which top vmstat iostat sar dstat perf
Subtask 1.3: Enable System Activity Data Collection
Configure the system to collect performance data automatically.

# Enable and start the sysstat service for data collection
sudo systemctl enable sysstat
sudo systemctl start sysstat

# Verify the service is running
sudo systemctl status sysstat
Subtask 1.4: Verify Tool Installation
Confirm all tools are properly installed and accessible.

# Check version information for each tool
top -v
vmstat -V
iostat -V
sar -V
dstat --version
perf --version
Task 2: Running Initial Performance Tests
Subtask 2.1: Basic System Overview with top
The top command provides real-time system performance information.

# Run top in batch mode for 5 iterations
top -b -n 5

# Run top with specific delay (2 seconds between updates)
top -d 2

# Display only processes for a specific user
top -u root

# Sort processes by memory usage
top -o %MEM
Key Metrics to Observe:

Load average: System load over 1, 5, and 15 minutes
CPU usage: User, system, idle, and wait percentages
Memory usage: Total, used, free, and cached memory
Process information: PID, CPU%, MEM%, and command
Subtask 2.2: Memory and System Statistics with vmstat
The vmstat command reports virtual memory statistics.

# Display current system statistics
vmstat

# Run vmstat with 2-second intervals for 10 iterations
vmstat 2 10

# Display statistics in megabytes
vmstat -S M 2 5

# Show detailed memory statistics
vmstat -s
Understanding vmstat Output:

procs: r (running processes), b (blocked processes)
memory: swpd (swap used), free (free memory), buff (buffers), cache (cache)
swap: si (swap in), so (swap out)
io: bi (blocks in), bo (blocks out)
system: in (interrupts), cs (context switches)
cpu: us (user), sy (system), id (idle), wa (wait), st (stolen)
Subtask 2.3: Disk I/O Statistics with iostat
The iostat command monitors disk input/output statistics.

# Display current I/O statistics
iostat

# Run iostat with 3-second intervals for 5 iterations
iostat 3 5

# Display extended statistics
iostat -x 2 5

# Show statistics for specific devices
iostat -x sda 2 5

# Display statistics in megabytes per second
iostat -m 2 5
Key iostat Metrics:

tps: Transfers per second
kB_read/s: Kilobytes read per second
kB_wrtn/s: Kilobytes written per second
%util: Percentage of CPU time during which I/O requests were issued
Subtask 2.4: System Activity Reports with sar
The sar command collects and reports system activity information.

# Display CPU utilization for the current day
sar -u

# Show memory utilization
sar -r

# Display network statistics
sar -n DEV

# Show disk I/O statistics
sar -d

# Generate a comprehensive report with 2-second intervals
sar -u -r -d 2 10
Subtask 2.5: Comprehensive Monitoring with dstat
The dstat command provides versatile system resource statistics.

# Basic dstat output
dstat

# Display CPU, memory, disk, and network statistics
dstat -cdnm

# Show top CPU and memory processes
dstat --top-cpu --top-mem

# Custom interval and count
dstat -cdnm 2 10

# Display statistics with timestamps
dstat -cdnm --output /tmp/dstat.log 2 10
Subtask 2.6: Advanced Performance Analysis with perf
The perf command provides advanced performance monitoring capabilities.

# List available performance events
perf list

# Record system-wide performance data for 10 seconds
sudo perf record -a sleep 10

# Display the recorded performance data
sudo perf report

# Monitor system performance in real-time
sudo perf top

# Record specific events (CPU cycles)
sudo perf record -e cycles -a sleep 5
Task 3: Gathering Resource Usage Data
Subtask 3.1: Create System Load for Testing
Generate system activity to observe monitoring tools in action.

# Create CPU load (run in background)
yes > /dev/null &
CPU_PID=$!

# Create memory load
dd if=/dev/zero of=/tmp/memory_test bs=1M count=100

# Create disk I/O load
dd if=/dev/zero of=/tmp/disk_test bs=1M count=500

# Clean up test files
rm -f /tmp/memory_test /tmp/disk_test

# Stop CPU load process
kill $CPU_PID
Subtask 3.2: Collect Baseline Performance Data
Establish baseline measurements for system performance.

# Create a directory for performance logs
mkdir -p ~/performance_logs

# Collect 5-minute baseline CPU data
sar -u 60 5 > ~/performance_logs/cpu_baseline.log

# Collect memory usage baseline
sar -r 60 5 > ~/performance_logs/memory_baseline.log

# Collect disk I/O baseline
iostat -x 60 5 > ~/performance_logs/disk_baseline.log

# Collect network baseline
sar -n DEV 60 5 > ~/performance_logs/network_baseline.log
Subtask 3.3: Create Performance Monitoring Script
Develop a comprehensive monitoring script for regular data collection.

# Create monitoring script
cat > ~/performance_monitor.sh << 'EOF'
#!/bin/bash

# Performance Monitoring Script
# Usage: ./performance_monitor.sh [duration_in_minutes]

DURATION=${1:-5}
INTERVAL=60
ITERATIONS=$((DURATION))
LOGDIR="$HOME/performance_logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create log directory
mkdir -p "$LOGDIR"

echo "Starting performance monitoring for $DURATION minutes..."
echo "Logs will be saved in: $LOGDIR"

# CPU monitoring
echo "Collecting CPU data..."
sar -u $INTERVAL $ITERATIONS > "$LOGDIR/cpu_$TIMESTAMP.log" &

# Memory monitoring
echo "Collecting memory data..."
sar -r $INTERVAL $ITERATIONS > "$LOGDIR/memory_$TIMESTAMP.log" &

# Disk I/O monitoring
echo "Collecting disk I/O data..."
iostat -x $INTERVAL $ITERATIONS > "$LOGDIR/disk_$TIMESTAMP.log" &

# Network monitoring
echo "Collecting network data..."
sar -n DEV $INTERVAL $ITERATIONS > "$LOGDIR/network_$TIMESTAMP.log" &

# Comprehensive system monitoring with dstat
echo "Collecting comprehensive system data..."
dstat -cdnm --output "$LOGDIR/system_$TIMESTAMP.csv" $INTERVAL $ITERATIONS &

# Wait for all background processes to complete
wait

echo "Performance monitoring completed!"
echo "Check logs in: $LOGDIR"
EOF

# Make script executable
chmod +x ~/performance_monitor.sh

# Run the monitoring script for 3 minutes
~/performance_monitor.sh 3
Subtask 3.4: Analyze Collected Data
Review and interpret the performance data collected.

# Display recent log files
ls -la ~/performance_logs/

# View CPU utilization summary
echo "=== CPU Utilization Summary ==="
tail -n 10 ~/performance_logs/cpu_*.log

# View memory usage summary
echo "=== Memory Usage Summary ==="
tail -n 10 ~/performance_logs/memory_*.log

# View disk I/O summary
echo "=== Disk I/O Summary ==="
tail -n 10 ~/performance_logs/disk_*.log
Subtask 3.5: Create Performance Dashboard Script
Develop a real-time performance dashboard.

# Create dashboard script
cat > ~/performance_dashboard.sh << 'EOF'
#!/bin/bash

# Real-time Performance Dashboard
# Press Ctrl+C to exit

while true; do
    clear
    echo "=========================================="
    echo "    SYSTEM PERFORMANCE DASHBOARD"
    echo "=========================================="
    echo "Timestamp: $(date)"
    echo ""
    
    echo "--- CPU Usage ---"
    top -bn1 | grep "Cpu(s)" | awk '{print $2 $3 $4 $5 $6 $7 $8}'
    echo ""
    
    echo "--- Memory Usage ---"
    free -h | grep -E "Mem|Swap"
    echo ""
    
    echo "--- Disk Usage ---"
    df -h | head -n 5
    echo ""
    
    echo "--- Load Average ---"
    uptime
    echo ""
    
    echo "--- Top 5 CPU Processes ---"
    ps aux --sort=-%cpu | head -n 6
    echo ""
    
    echo "Press Ctrl+C to exit..."
    sleep 5
done
EOF

# Make dashboard script executable
chmod +x ~/performance_dashboard.sh

# Note: Run the dashboard when needed
echo "Dashboard script created. Run with: ~/performance_dashboard.sh"
Troubleshooting Common Issues
Issue 1: Package Installation Failures
Problem: DNF package installation fails Solution:

# Check repository configuration
sudo dnf repolist

# Clean DNF cache
sudo dnf clean all

# Retry installation
sudo dnf install -y procps-ng sysstat dstat perf
Issue 2: Permission Denied for perf Commands
Problem: perf commands require elevated privileges Solution:

# Run perf commands with sudo
sudo perf top

# Or adjust kernel parameters (temporary)
echo 0 | sudo tee /proc/sys/kernel/perf_event_paranoid
Issue 3: sysstat Service Not Collecting Data
Problem: sar shows no data available Solution:

# Restart sysstat service
sudo systemctl restart sysstat

# Check service status
sudo systemctl status sysstat

# Manually trigger data collection
sudo /usr/lib64/sa/sa1
Issue 4: High System Load During Monitoring
Problem: Monitoring tools consume too many resources Solution:

# Use longer intervals
iostat 30 5  # 30-second intervals instead of 1-second

# Limit monitoring scope
top -p $(pgrep -d',' httpd)  # Monitor specific processes only
Verification and Testing
Verify Tool Functionality
# Test each tool with basic commands
echo "Testing top..."
timeout 5 top -b -n 1 > /dev/null && echo "✓ top working"

echo "Testing vmstat..."
vmstat 1 2 > /dev/null && echo "✓ vmstat working"

echo "Testing iostat..."
iostat 1 2 > /dev/null && echo "✓ iostat working"

echo "Testing sar..."
sar -u 1 2 > /dev/null && echo "✓ sar working"

echo "Testing dstat..."
timeout 5 dstat 1 2 > /dev/null && echo "✓ dstat working"

echo "Testing perf..."
sudo perf list > /dev/null && echo "✓ perf working"
Conclusion
In this lab, you have successfully:

Installed essential performance monitoring tools including top, vmstat, iostat, sar, dstat, and perf on RHEL
Configured system services to enable automatic performance data collection
Executed initial performance tests to understand each tool's capabilities and output format
Gathered comprehensive resource usage data covering CPU, memory, disk I/O, and network metrics
Created automated monitoring scripts for ongoing performance analysis
Developed troubleshooting skills for common monitoring tool issues
These performance monitoring tools are fundamental for system administrators and performance engineers working with Red Hat Enterprise Linux systems. The skills acquired in this lab provide the foundation for:

Proactive system monitoring to identify performance bottlenecks before they impact users
Capacity planning by understanding resource utilization patterns
Performance optimization through data-driven decision making
Troubleshooting system issues using quantitative performance metrics
The monitoring infrastructure you've established will serve as a baseline for advanced performance tuning activities and help maintain optimal system performance in production environments. Regular use of these tools will enhance your ability to maintain high-performing Linux systems in physical, virtual, and cloud environments.
