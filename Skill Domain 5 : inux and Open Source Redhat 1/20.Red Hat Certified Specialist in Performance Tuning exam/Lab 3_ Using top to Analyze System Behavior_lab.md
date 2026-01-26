Lab 3: Using top to Analyze System Behavior
Objectives
By the end of this lab, students will be able to:

Master the top command to monitor real-time system performance
Analyze CPU utilization, memory consumption, and process behavior
Identify resource-intensive processes and system bottlenecks
Understand process priorities and their impact on system performance
Modify process priorities using nice and renice commands
Interpret system load averages and performance metrics
Implement performance optimization strategies based on top analysis
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line interface
Familiarity with process concepts in Linux
Knowledge of basic system administration commands
Understanding of CPU and memory concepts
Access to a terminal or command prompt
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Pre-installed system monitoring tools
Sample applications for testing
Administrative privileges for system modifications
Task 1: Use top to Monitor CPU, Memory, and Process Behavior
Subtask 1.1: Understanding the top Interface
Step 1: Launch the top command

top
Step 2: Examine the top display sections

The top command displays information in several sections:

Header Section: System summary information
Process List: Individual process details
Step 3: Understand the header information

top - 14:30:25 up 2 days,  3:42,  2 users,  load average: 0.15, 0.25, 0.30
Tasks: 245 total,   1 running, 244 sleeping,   0 stopped,   0 zombie
%Cpu(s):  2.3 us,  1.2 sy,  0.0 ni, 96.2 id,  0.3 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   3924.5 total,   1245.2 free,   1234.5 used,   1444.8 buff/cache
MiB Swap:   2048.0 total,   2048.0 free,      0.0 used.   2456.3 avail Mem
Key Metrics Explanation:

Load Average: System load over 1, 5, and 15 minutes
Tasks: Total processes and their states
CPU Usage: User space, system, nice, idle, wait, hardware/software interrupts
Memory: Total, free, used, and cached memory
Subtask 1.2: Navigating and Customizing top
Step 4: Learn essential top navigation keys

While top is running, practice these commands:

h     - Display help
q     - Quit top
k     - Kill a process
r     - Renice a process
f     - Field management (add/remove columns)
o     - Change sort order
1     - Toggle CPU core display
m     - Toggle memory display format
t     - Toggle task/CPU display format
Step 5: Customize the display

Press f to enter field management mode and explore available columns:

PID: Process ID
USER: Process owner
PR: Priority
NI: Nice value
VIRT: Virtual memory
RES: Resident memory
SHR: Shared memory
S: Process state
%CPU: CPU usage percentage
%MEM: Memory usage percentage
TIME+: Total CPU time
COMMAND: Command name
Subtask 1.3: Monitoring CPU Performance
Step 6: Create CPU-intensive processes for monitoring

Open a new terminal and create a CPU stress test:

# Install stress tool if not available
sudo yum install stress -y
# or for Ubuntu/Debian
sudo apt-get install stress -y

# Create CPU load on all cores for 300 seconds
stress --cpu 4 --timeout 300s &
Step 7: Monitor CPU usage in top

Return to your top session and observe:

CPU percentage usage increasing
Load average rising
Process list showing stress processes
Step 8: Sort processes by CPU usage

In top, press P to sort by CPU usage (this is usually the default).

Subtask 1.4: Monitoring Memory Usage
Step 9: Create memory-intensive processes

# Create memory stress (allocate 1GB of memory)
stress --vm 2 --vm-bytes 512M --timeout 300s &
Step 10: Monitor memory consumption

In top, press M to sort by memory usage and observe:

Memory usage in the header section
Individual process memory consumption
Available memory decreasing
Step 11: Analyze memory metrics

Focus on these memory indicators:

VIRT: Virtual memory size
RES: Physical memory currently used
SHR: Shared memory
%MEM: Percentage of total memory used
Task 2: Identify Resource Hogs and Inefficiencies
Subtask 2.1: Identifying CPU Resource Hogs
Step 12: Create a script to simulate various workloads

Create a test script:

cat > resource_test.sh << 'EOF'
#!/bin/bash

# Function to create CPU load
cpu_hog() {
    echo "Starting CPU intensive task..."
    while true; do
        echo "scale=5000; 4*a(1)" | bc -l > /dev/null 2>&1
    done
}

# Function to create memory load
memory_hog() {
    echo "Starting memory intensive task..."
    python3 -c "
import time
data = []
for i in range(1000000):
    data.append('x' * 1000)
    if i % 10000 == 0:
        print(f'Allocated {i * 1000} bytes')
time.sleep(300)
"
}

# Function to create I/O load
io_hog() {
    echo "Starting I/O intensive task..."
    dd if=/dev/zero of=/tmp/testfile bs=1M count=1000 2>/dev/null
    for i in {1..100}; do
        cat /tmp/testfile > /dev/null
    done
    rm -f /tmp/testfile
}

case $1 in
    cpu) cpu_hog ;;
    memory) memory_hog ;;
    io) io_hog ;;
    *) echo "Usage: $0 {cpu|memory|io}" ;;
esac
EOF

chmod +x resource_test.sh
Step 13: Run different resource tests

# Start CPU hog in background
./resource_test.sh cpu &
CPU_PID=$!

# Start memory hog in background
./resource_test.sh memory &
MEMORY_PID=$!

# Start I/O hog in background
./resource_test.sh io &
IO_PID=$!
Step 14: Analyze resource consumption patterns

In top, observe and document:

CPU Hogs: Processes with high %CPU values
Memory Hogs: Processes with high %MEM and RES values
I/O Impact: Processes causing high system load
Subtask 2.2: Using top Interactive Features for Analysis
Step 15: Filter processes by user

In top, press u and enter your username to filter processes.

Step 16: Highlight running processes

Press z to enable color highlighting, then x to highlight the sort column.

Step 17: Monitor specific processes

Press L to locate a specific process by name or PID.

Subtask 2.3: Identifying System Inefficiencies
Step 18: Analyze system load patterns

Create a monitoring script:

cat > system_monitor.sh << 'EOF'
#!/bin/bash

echo "System Performance Analysis"
echo "=========================="
echo "Date: $(date)"
echo ""

# CPU Information
echo "CPU Information:"
echo "Cores: $(nproc)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Memory Information
echo "Memory Information:"
free -h
echo ""

# Top 10 CPU consuming processes
echo "Top 10 CPU Consuming Processes:"
ps aux --sort=-%cpu | head -11
echo ""

# Top 10 Memory consuming processes
echo "Top 10 Memory Consuming Processes:"
ps aux --sort=-%mem | head -11
echo ""

# Disk I/O
echo "Disk Usage:"
df -h
echo ""

# Network connections
echo "Active Network Connections:"
netstat -tuln | wc -l
echo "Total connections: $(netstat -tuln | wc -l)"
EOF

chmod +x system_monitor.sh
./system_monitor.sh
Task 3: Modify Process Priorities Using nice and renice
Subtask 3.1: Understanding Process Priorities
Step 19: Learn about nice values

Nice values range from -20 (highest priority) to +19 (lowest priority):

-20 to -1: High priority (requires root privileges)
0: Default priority
1 to 19: Lower priority
Step 20: Check current process priorities

# View processes with their nice values
ps -eo pid,ppid,ni,comm --sort=-ni
Subtask 3.2: Using nice to Start Processes with Modified Priority
Step 21: Start processes with different priorities

# Start a low priority CPU-intensive process
nice -n 19 ./resource_test.sh cpu &
LOW_PRIORITY_PID=$!

# Start a high priority process (requires root)
sudo nice -n -10 ./resource_test.sh cpu &
HIGH_PRIORITY_PID=$!

# Start a normal priority process
./resource_test.sh cpu &
NORMAL_PRIORITY_PID=$!
Step 22: Monitor the impact in top

Observe how different nice values affect:

CPU time allocation
Process scheduling
System responsiveness
Subtask 3.3: Using renice to Modify Running Process Priorities
Step 23: Change priority of running processes

# Find a process to modify
ps aux | grep resource_test

# Renice a process to lower priority
renice 15 $NORMAL_PRIORITY_PID

# Renice a process to higher priority (requires root)
sudo renice -5 $LOW_PRIORITY_PID
Step 24: Verify priority changes

# Check the updated priorities
ps -eo pid,ppid,ni,comm | grep resource_test
Subtask 3.4: Advanced Priority Management
Step 25: Create a priority management script

cat > priority_manager.sh << 'EOF'
#!/bin/bash

show_help() {
    echo "Priority Manager Script"
    echo "Usage: $0 [option] [pid] [nice_value]"
    echo ""
    echo "Options:"
    echo "  list     - List all processes with priorities"
    echo "  renice   - Change process priority"
    echo "  monitor  - Monitor priority changes"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 renice 1234 10"
    echo "  $0 monitor"
}

list_priorities() {
    echo "Current Process Priorities:"
    echo "PID     PPID    NI  COMMAND"
    echo "=========================="
    ps -eo pid,ppid,ni,comm --sort=-ni | head -20
}

renice_process() {
    local pid=$1
    local nice_value=$2
    
    if [ -z "$pid" ] || [ -z "$nice_value" ]; then
        echo "Error: PID and nice value required"
        return 1
    fi
    
    echo "Changing priority of PID $pid to nice value $nice_value"
    
    if [ "$nice_value" -lt 0 ]; then
        sudo renice "$nice_value" "$pid"
    else
        renice "$nice_value" "$pid"
    fi
    
    echo "New priority:"
    ps -eo pid,ppid,ni,comm | grep "^[[:space:]]*$pid"
}

monitor_priorities() {
    echo "Monitoring process priorities (Press Ctrl+C to stop)..."
    while true; do
        clear
        echo "Process Priority Monitor - $(date)"
        echo "=================================="
        ps -eo pid,ppid,ni,%cpu,%mem,comm --sort=-%cpu | head -15
        sleep 2
    done
}

case $1 in
    list) list_priorities ;;
    renice) renice_process $2 $3 ;;
    monitor) monitor_priorities ;;
    *) show_help ;;
esac
EOF

chmod +x priority_manager.sh
Step 26: Test the priority management script

# List current priorities
./priority_manager.sh list

# Monitor priorities in real-time
./priority_manager.sh monitor
Subtask 3.5: Performance Impact Analysis
Step 27: Create a performance comparison test

cat > performance_test.sh << 'EOF'
#!/bin/bash

echo "Performance Impact Test"
echo "======================"

# Function to run CPU benchmark
cpu_benchmark() {
    local nice_value=$1
    local label=$2
    
    echo "Running $label test (nice: $nice_value)..."
    
    start_time=$(date +%s.%N)
    nice -n $nice_value bash -c 'for i in {1..1000000}; do echo "scale=100; 4*a(1)" | bc -l > /dev/null 2>&1; done'
    end_time=$(date +%s.%N)
    
    duration=$(echo "$end_time - $start_time" | bc)
    echo "$label completed in: $duration seconds"
    echo ""
}

# Run benchmarks with different priorities
cpu_benchmark 0 "Normal Priority"
cpu_benchmark 10 "Low Priority"
cpu_benchmark -10 "High Priority" 2>/dev/null || echo "High priority test requires root privileges"

echo "Performance test completed."
EOF

chmod +x performance_test.sh
./performance_test.sh
Advanced Monitoring Techniques
Subtask 3.6: Creating Custom top Configurations
Step 28: Save custom top configuration

# Run top and customize the display
top

# Press 'f' to manage fields
# Press 'W' to save current configuration
# Press 'q' to quit
Step 29: Create a top monitoring script

cat > top_monitor.sh << 'EOF'
#!/bin/bash

# Custom top monitoring with specific focus areas

echo "Starting comprehensive system monitoring..."

# Function to capture top output
capture_top() {
    local duration=$1
    local output_file=$2
    
    echo "Capturing top output for $duration seconds..."
    timeout $duration top -b -n $((duration/2)) > $output_file
    echo "Output saved to $output_file"
}

# Function to analyze top output
analyze_top() {
    local input_file=$1
    
    echo "Analysis of $input_file:"
    echo "========================"
    
    # Extract load averages
    echo "Load Average Trends:"
    grep "load average" $input_file | awk '{print $12, $13, $14}'
    echo ""
    
    # Extract top CPU consumers
    echo "Top CPU Consumers:"
    grep -A 20 "PID USER" $input_file | grep -v "PID USER" | head -10
    echo ""
    
    # Extract memory usage
    echo "Memory Usage Patterns:"
    grep "MiB Mem" $input_file
    echo ""
}

# Capture system performance
capture_top 60 "system_performance.log"

# Analyze the captured data
analyze_top "system_performance.log"

echo "Monitoring complete. Check system_performance.log for detailed data."
EOF

chmod +x top_monitor.sh
Troubleshooting Common Issues
Common Problems and Solutions
Problem 1: top command not responding

# Solution: Kill unresponsive top process
pkill top
# Or use alternative monitoring
htop  # If available
Problem 2: Cannot change process priority

# Solution: Check if you have sufficient privileges
sudo renice -10 [PID]
# Or check if process exists
ps -p [PID]
Problem 3: High system load but low CPU usage

# Solution: Check for I/O wait
iostat -x 1 5
# Check disk usage
df -h
# Check for zombie processes
ps aux | grep -i zombie
Problem 4: Memory usage appears incorrect

# Solution: Check actual memory usage
free -h
cat /proc/meminfo
# Check for memory leaks
valgrind --tool=memcheck [program]
Performance Optimization Best Practices
Step 30: Implement monitoring best practices
cat > monitoring_best_practices.sh << 'EOF'
#!/bin/bash

echo "System Performance Best Practices"
echo "================================="

# 1. Regular monitoring
echo "1. Setting up regular monitoring..."
cat > /tmp/system_check.sh << 'INNER_EOF'
#!/bin/bash
LOG_FILE="/var/log/system_performance.log"
echo "$(date): Load: $(uptime | awk -F'load average:' '{print $2}')" >> $LOG_FILE
echo "$(date): Memory: $(free | grep Mem | awk '{print $3/$2 * 100.0}')" >> $LOG_FILE
INNER_EOF

# 2. Process priority guidelines
echo "2. Process Priority Guidelines:"
echo "   - Interactive applications: nice 0 to -5"
echo "   - Background tasks: nice 10 to 19"
echo "   - System critical: nice -10 to -20 (root only)"
echo ""

# 3. Resource thresholds
echo "3. Resource Alert Thresholds:"
echo "   - CPU Load > Number of cores: Investigation needed"
echo "   - Memory usage > 80%: Monitor closely"
echo "   - Memory usage > 90%: Take action"
echo ""

# 4. Automated alerts
echo "4. Setting up automated monitoring..."
cat > /tmp/resource_alert.sh << 'INNER_EOF'
#!/bin/bash
LOAD_THRESHOLD=2.0
MEMORY_THRESHOLD=80

CURRENT_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

if (( $(echo "$CURRENT_LOAD > $LOAD_THRESHOLD" | bc -l) )); then
    echo "ALERT: High system load: $CURRENT_LOAD"
fi

if (( $(echo "$MEMORY_USAGE > $MEMORY_THRESHOLD" | bc -l) )); then
    echo "ALERT: High memory usage: $MEMORY_USAGE%"
fi
INNER_EOF

chmod +x /tmp/system_check.sh
chmod +x /tmp/resource_alert.sh

echo "Best practices scripts created in /tmp/"
echo "Consider adding system_check.sh to crontab for regular monitoring"
EOF

chmod +x monitoring_best_practices.sh
./monitoring_best_practices.sh
Lab Cleanup
Step 31: Clean up test processes and files
# Kill all background test processes
pkill -f resource_test.sh
pkill stress

# Remove temporary files
rm -f resource_test.sh system_monitor.sh priority_manager.sh
rm -f performance_test.sh top_monitor.sh monitoring_best_practices.sh
rm -f system_performance.log
rm -f /tmp/testfile /tmp/system_check.sh /tmp/resource_alert.sh

echo "Lab cleanup completed."
Conclusion
In this comprehensive lab, you have successfully:

Mastered System Monitoring: You learned to use the top command effectively to monitor real-time system performance, understanding CPU utilization, memory consumption, and process behavior patterns.

Identified Performance Issues: You developed skills to identify resource-intensive processes and system bottlenecks, learning to distinguish between CPU-bound, memory-bound, and I/O-bound processes.

Implemented Priority Management: You gained hands-on experience with process priority modification using nice and renice commands, understanding how priority changes affect system performance and resource allocation.

Applied Performance Analysis: You created custom monitoring scripts and learned to analyze system performance data, developing the ability to make informed decisions about system optimization.

Established Best Practices: You implemented monitoring best practices and automated alerting systems that are essential for maintaining optimal system performance in production environments.

These skills are fundamental for system administrators and performance engineers, directly applicable to the Red Hat Certified Specialist in Performance Tuning exam and real-world system administration scenarios. The ability to effectively monitor and optimize system performance using open-source tools like top is crucial for maintaining efficient, responsive systems in enterprise environments.

The techniques you've learned will help you proactively identify and resolve performance issues, optimize resource utilization, and ensure system stability - skills that are highly valued in today's technology landscape.
