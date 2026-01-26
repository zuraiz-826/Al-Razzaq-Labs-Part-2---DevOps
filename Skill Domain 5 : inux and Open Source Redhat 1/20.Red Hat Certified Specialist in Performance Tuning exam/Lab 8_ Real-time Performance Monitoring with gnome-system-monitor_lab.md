Lab 8: Real-time Performance Monitoring with gnome-system-monitor
Objectives
By the end of this lab, students will be able to:

Install and configure gnome-system-monitor for comprehensive system monitoring
Navigate the gnome-system-monitor interface to view real-time system performance metrics
Monitor CPU utilization patterns and identify performance bottlenecks
Analyze memory usage and detect memory leaks or excessive consumption
Track running processes and their resource consumption
Identify performance issues through visual analysis of system metrics
Implement basic system optimizations based on monitoring data
Generate performance reports and document findings
Understand the relationship between system resources and application performance
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux operating systems and command-line interface
Familiarity with system processes and resource management concepts
Knowledge of CPU, memory, and disk I/O fundamentals
Understanding of process management in Linux environments
Basic troubleshooting skills for system performance issues
Familiarity with package management systems (apt, yum, dnf)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment. No need to build your own virtual machine or install additional software initially.

Your cloud machine includes:

Ubuntu 22.04 LTS or CentOS Stream 9
Root access for system administration
Network connectivity for package installation
Sufficient resources for performance testing scenarios
Task 1: Installing and Configuring gnome-system-monitor
Subtask 1.1: System Preparation and Package Installation
First, we need to ensure our system is updated and install the necessary packages.

Step 1: Update your system package repository

# For Ubuntu/Debian systems
sudo apt update && sudo apt upgrade -y

# For CentOS/RHEL/Fedora systems
sudo dnf update -y
Step 2: Install gnome-system-monitor and related dependencies

# For Ubuntu/Debian systems
sudo apt install gnome-system-monitor htop stress-ng -y

# For CentOS/RHEL/Fedora systems
sudo dnf install gnome-system-monitor htop stress-ng -y
Step 3: Verify the installation

# Check if gnome-system-monitor is installed
which gnome-system-monitor

# Check version information
gnome-system-monitor --version
Subtask 1.2: Initial Configuration and Interface Familiarization
Step 1: Launch gnome-system-monitor from the command line

# Start gnome-system-monitor in the background
gnome-system-monitor &
Step 2: Explore the main interface tabs

The gnome-system-monitor interface consists of four main tabs:

Processes: Shows running processes and their resource usage
Resources: Displays real-time CPU, memory, and network usage graphs
File Systems: Shows disk usage and mounted file systems
Hardware: Provides information about system hardware components
Step 3: Configure display preferences

Click on Preferences in the application menu
Under the Processes tab, enable:
Show process dependencies
Show all processes
Update interval: 2 seconds
Under the Resources tab, set:
Update interval: 1 second
Graph data points: 60 seconds
Subtask 1.3: Understanding the Processes Tab
Step 1: Navigate to the Processes tab and examine the column headers

Key columns include:

Process Name: The name of the running process
User: The user account running the process
% CPU: Percentage of CPU time used by the process
Memory: Amount of RAM used by the process
PID: Process ID number
Priority: Process scheduling priority
Step 2: Sort processes by different criteria

# Right-click on column headers to add/remove columns
# Click on column headers to sort by that criterion
# Try sorting by:
# - CPU usage (highest first)
# - Memory usage (highest first)
# - Process name (alphabetical)
Task 2: Real-time CPU Utilization Monitoring
Subtask 2.1: Baseline CPU Performance Analysis
Step 1: Establish baseline CPU metrics

Navigate to the Resources tab
Observe the CPU usage graph for 2-3 minutes during normal system operation
Note the average CPU usage percentage
Document any periodic spikes or patterns
Step 2: Create a CPU monitoring script

# Create a script to log CPU usage
cat > cpu_monitor.sh << 'EOF'
#!/bin/bash

# CPU monitoring script
LOG_FILE="cpu_usage_log.txt"
DURATION=300  # 5 minutes
INTERVAL=5    # 5 seconds

echo "Starting CPU monitoring for $DURATION seconds..."
echo "Timestamp,CPU_Usage_Percent" > $LOG_FILE

for ((i=1; i<=DURATION/INTERVAL; i++)); do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    echo "$TIMESTAMP,$CPU_USAGE" >> $LOG_FILE
    sleep $INTERVAL
done

echo "CPU monitoring completed. Check $LOG_FILE for results."
EOF

chmod +x cpu_monitor.sh
Subtask 2.2: Generating CPU Load for Testing
Step 1: Create controlled CPU load using stress-ng

# Generate CPU load on all available cores for 2 minutes
stress-ng --cpu 0 --timeout 120s --metrics-brief
Step 2: Monitor CPU usage during stress test

While stress-ng is running, observe the gnome-system-monitor Resources tab
Note the CPU usage graph climbing to near 100%
Switch to the Processes tab and identify the stress-ng processes
Document the PID and CPU percentage of each stress-ng worker
Step 3: Generate specific CPU load patterns

# Generate load on specific number of CPU cores
stress-ng --cpu 2 --timeout 60s

# Generate CPU load with specific intensity
stress-ng --cpu 1 --cpu-load 75 --timeout 60s
Subtask 2.3: Analyzing CPU Performance Patterns
Step 1: Identify CPU-intensive processes

Sort processes by CPU usage in descending order
Identify the top 5 CPU-consuming processes
Right-click on high-CPU processes to view additional details
Step 2: Monitor CPU usage over time

# Create a comprehensive CPU analysis script
cat > cpu_analysis.sh << 'EOF'
#!/bin/bash

echo "=== CPU Analysis Report ==="
echo "Date: $(date)"
echo "System: $(uname -a)"
echo ""

echo "CPU Information:"
lscpu | grep -E "CPU\(s\)|Model name|CPU MHz"
echo ""

echo "Current CPU Usage:"
top -bn1 | head -20
echo ""

echo "Load Average:"
uptime
echo ""

echo "Top 10 CPU-consuming processes:"
ps aux --sort=-%cpu | head -11
EOF

chmod +x cpu_analysis.sh
./cpu_analysis.sh
Task 3: Memory Usage Analysis and Monitoring
Subtask 3.1: Understanding Memory Metrics
Step 1: Examine memory information in gnome-system-monitor

Navigate to the Resources tab
Observe the Memory and Swap History graph
Note the different memory categories:
Used: Memory currently in use by applications
Available: Memory available for new applications
Cached: Memory used for file system caching
Swap: Virtual memory usage
Step 2: Create a memory monitoring script

cat > memory_monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="memory_usage_log.txt"
echo "Timestamp,Total_MB,Used_MB,Free_MB,Available_MB,Cached_MB,Swap_Used_MB" > $LOG_FILE

for i in {1..60}; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    MEMORY_INFO=$(free -m | awk 'NR==2{printf "%s,%s,%s,%s", $2,$3,$4,$7} NR==3{printf ",%s", $3}')
    SWAP_INFO=$(free -m | awk 'NR==3{printf ",%s", $3}')
    echo "$TIMESTAMP,$MEMORY_INFO$SWAP_INFO" >> $LOG_FILE
    sleep 5
done

echo "Memory monitoring completed. Check $LOG_FILE for results."
EOF

chmod +x memory_monitor.sh
Subtask 3.2: Memory Stress Testing
Step 1: Generate memory pressure using stress-ng

# Allocate 1GB of memory for 2 minutes
stress-ng --vm 1 --vm-bytes 1G --timeout 120s --metrics-brief
Step 2: Monitor memory usage during stress test

While the memory stress test runs, observe the memory graph in gnome-system-monitor
Watch for:
Increase in used memory
Decrease in available memory
Potential swap usage activation
System responsiveness changes
Step 3: Test different memory allocation patterns

# Multiple workers with smaller allocations
stress-ng --vm 4 --vm-bytes 256M --timeout 60s

# Large single allocation
stress-ng --vm 1 --vm-bytes 2G --timeout 60s --vm-keep
Subtask 3.3: Identifying Memory Leaks and Issues
Step 1: Create a memory leak simulation

cat > memory_leak_sim.py << 'EOF'
#!/usr/bin/env python3
import time
import sys

def memory_leak_simulation():
    """Simulate a memory leak by continuously allocating memory"""
    memory_hog = []
    iteration = 0
    
    print("Starting memory leak simulation...")
    print("Monitor this process in gnome-system-monitor")
    print("Press Ctrl+C to stop")
    
    try:
        while True:
            # Allocate 10MB of memory each iteration
            chunk = 'x' * (10 * 1024 * 1024)
            memory_hog.append(chunk)
            iteration += 1
            
            if iteration % 10 == 0:
                print(f"Iteration {iteration}: Allocated ~{iteration * 10}MB")
            
            time.sleep(2)
    except KeyboardInterrupt:
        print("\nMemory leak simulation stopped")
        print(f"Total allocated: ~{iteration * 10}MB")

if __name__ == "__main__":
    memory_leak_simulation()
EOF

chmod +x memory_leak_sim.py
Step 2: Run the memory leak simulation and monitor

# Start the simulation in the background
python3 memory_leak_sim.py &
LEAK_PID=$!

# Monitor the process
echo "Memory leak simulation PID: $LEAK_PID"
echo "Monitor this PID in gnome-system-monitor Processes tab"
Step 3: Analyze memory usage patterns

In gnome-system-monitor, locate the Python process
Observe the memory usage increasing over time
Note the impact on system available memory
Stop the simulation when memory usage becomes concerning:
# Stop the memory leak simulation
kill $LEAK_PID
Task 4: Process Management and Analysis
Subtask 4.1: Process Hierarchy and Dependencies
Step 1: Enable process tree view in gnome-system-monitor

In the Processes tab, click View menu
Select Show Dependencies
Observe the hierarchical process tree structure
Step 2: Analyze parent-child process relationships

# Create a script that spawns child processes
cat > process_tree_demo.sh << 'EOF'
#!/bin/bash

echo "Creating process tree demonstration..."
echo "Parent PID: $$"

# Function to create child processes
create_children() {
    local parent_name=$1
    local depth=$2
    
    if [ $depth -gt 0 ]; then
        echo "[$parent_name] Creating child process at depth $depth"
        (
            echo "Child process PID: $$ (Parent: $PPID)"
            sleep 300 &  # Background sleep process
            create_children "Child-$depth" $((depth-1))
            wait
        ) &
    fi
}

# Create a 3-level process tree
create_children "Root" 3

echo "Process tree created. Check gnome-system-monitor for the hierarchy."
echo "Processes will run for 5 minutes. Press Ctrl+C to stop early."

# Wait for all background processes
wait
EOF

chmod +x process_tree_demo.sh
Subtask 4.2: Process Resource Consumption Analysis
Step 1: Create processes with different resource patterns

# CPU-intensive process
cat > cpu_intensive.sh << 'EOF'
#!/bin/bash
echo "Starting CPU-intensive process..."
while true; do
    echo "scale=5000; 4*a(1)" | bc -l > /dev/null
done
EOF

# Memory-intensive process
cat > memory_intensive.sh << 'EOF'
#!/bin/bash
echo "Starting memory-intensive process..."
python3 -c "
import time
data = []
for i in range(1000):
    data.append('x' * 1024 * 1024)  # 1MB chunks
    time.sleep(0.1)
    if i % 100 == 0:
        print(f'Allocated {i}MB')
"
EOF

# I/O-intensive process
cat > io_intensive.sh << 'EOF'
#!/bin/bash
echo "Starting I/O-intensive process..."
while true; do
    dd if=/dev/zero of=/tmp/test_file bs=1M count=100 2>/dev/null
    rm -f /tmp/test_file
    sleep 1
done
EOF

chmod +x cpu_intensive.sh memory_intensive.sh io_intensive.sh
Step 2: Launch different process types and monitor

# Start each process type in background
./cpu_intensive.sh &
CPU_PID=$!

./memory_intensive.sh &
MEM_PID=$!

./io_intensive.sh &
IO_PID=$!

echo "Process PIDs:"
echo "CPU-intensive: $CPU_PID"
echo "Memory-intensive: $MEM_PID"
echo "I/O-intensive: $IO_PID"
Step 3: Analyze resource consumption patterns

In gnome-system-monitor Processes tab, locate each test process
Observe and document:
CPU usage percentage for each process
Memory consumption patterns
Process priority and nice values
Sort by different columns to see resource usage rankings
Subtask 4.3: Process Control and Management
Step 1: Practice process priority adjustment

Right-click on the CPU-intensive process in gnome-system-monitor
Select Change Priority
Experiment with different priority levels:
Very High
High
Normal
Low
Very Low
Step 2: Process termination techniques

# Graceful termination
kill -TERM $CPU_PID

# Force termination if needed
kill -KILL $MEM_PID

# Clean up remaining processes
kill $IO_PID
Step 3: Create a process management script

cat > process_manager.sh << 'EOF'
#!/bin/bash

show_process_info() {
    local pid=$1
    echo "=== Process Information for PID $pid ==="
    if ps -p $pid > /dev/null 2>&1; then
        ps -p $pid -o pid,ppid,user,%cpu,%mem,vsz,rss,tty,stat,start,time,command
        echo ""
        echo "Memory details:"
        cat /proc/$pid/status | grep -E "VmSize|VmRSS|VmData|VmStk"
        echo ""
        echo "Open files:"
        lsof -p $pid 2>/dev/null | wc -l
        echo ""
    else
        echo "Process $pid not found or terminated"
    fi
}

# Usage example
if [ $# -eq 1 ]; then
    show_process_info $1
else
    echo "Usage: $0 <PID>"
    echo "Example: $0 1234"
fi
EOF

chmod +x process_manager.sh
Task 5: Performance Issue Identification and Optimization
Subtask 5.1: Creating Performance Bottleneck Scenarios
Step 1: Simulate a system under heavy load

cat > system_stress.sh << 'EOF'
#!/bin/bash

echo "Creating comprehensive system stress scenario..."

# CPU stress (use all cores at 80% capacity)
stress-ng --cpu 0 --cpu-load 80 --timeout 300s &
CPU_STRESS_PID=$!

# Memory stress (allocate 70% of available memory)
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
STRESS_MEM=$((TOTAL_MEM * 70 / 100))
stress-ng --vm 2 --vm-bytes ${STRESS_MEM}M --timeout 300s &
MEM_STRESS_PID=$!

# I/O stress
stress-ng --io 4 --timeout 300s &
IO_STRESS_PID=$!

echo "Stress test PIDs:"
echo "CPU: $CPU_STRESS_PID"
echo "Memory: $MEM_STRESS_PID"
echo "I/O: $IO_STRESS_PID"

echo "Monitor system performance in gnome-system-monitor for 5 minutes"
echo "Press Ctrl+C to stop all stress tests early"

# Wait for completion or interruption
trap 'kill $CPU_STRESS_PID $MEM_STRESS_PID $IO_STRESS_PID 2>/dev/null; exit' INT
wait
EOF

chmod +x system_stress.sh
Step 2: Monitor system behavior during stress test

Launch the stress test: ./system_stress.sh
In gnome-system-monitor, observe:
CPU usage approaching 80% across all cores
Memory usage increasing significantly
System responsiveness changes
Process priorities and scheduling
Subtask 5.2: Performance Analysis and Documentation
Step 1: Create a performance analysis checklist

cat > performance_checklist.txt << 'EOF'
SYSTEM PERFORMANCE ANALYSIS CHECKLIST

1. CPU Analysis:
   [ ] Average CPU utilization: _____%
   [ ] Peak CPU utilization: _____%
   [ ] Number of CPU cores fully utilized: _____
   [ ] Top CPU-consuming process: _____________
   [ ] CPU load average (1min): _____

2. Memory Analysis:
   [ ] Total system memory: _____MB
   [ ] Used memory: _____MB (____%)
   [ ] Available memory: _____MB (____%)
   [ ] Swap usage: _____MB (____%)
   [ ] Top memory-consuming process: _____________

3. Process Analysis:
   [ ] Total number of running processes: _____
   [ ] Processes in running state: _____
   [ ] Processes in sleeping state: _____
   [ ] Zombie processes: _____
   [ ] Highest priority process: _____________

4. System Responsiveness:
   [ ] GUI responsiveness: Normal/Slow/Unresponsive
   [ ] Application launch time: Normal/Slow
   [ ] File operations: Normal/Slow

5. Performance Issues Identified:
   [ ] CPU bottleneck: Yes/No
   [ ] Memory bottleneck: Yes/No
   [ ] I/O bottleneck: Yes/No
   [ ] Process scheduling issues: Yes/No

6. Optimization Recommendations:
   _________________________________________________
   _________________________________________________
   _________________________________________________
EOF
Step 2: Generate automated performance report

cat > performance_report.sh << 'EOF'
#!/bin/bash

REPORT_FILE="performance_report_$(date +%Y%m%d_%H%M%S).txt"

{
    echo "=== SYSTEM PERFORMANCE REPORT ==="
    echo "Generated: $(date)"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime)"
    echo ""
    
    echo "=== SYSTEM INFORMATION ==="
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo ""
    
    echo "=== CPU INFORMATION ==="
    lscpu | grep -E "CPU\(s\)|Model name|CPU MHz|Cache"
    echo ""
    echo "Current CPU Usage:"
    top -bn1 | grep "Cpu(s)"
    echo ""
    
    echo "=== MEMORY INFORMATION ==="
    free -h
    echo ""
    
    echo "=== TOP PROCESSES BY CPU ==="
    ps aux --sort=-%cpu | head -10
    echo ""
    
    echo "=== TOP PROCESSES BY MEMORY ==="
    ps aux --sort=-%mem | head -10
    echo ""
    
    echo "=== DISK USAGE ==="
    df -h
    echo ""
    
    echo "=== NETWORK CONNECTIONS ==="
    netstat -tuln | wc -l
    echo "Total network connections: $(netstat -tuln | wc -l)"
    echo ""
    
    echo "=== LOAD AVERAGE HISTORY ==="
    uptime
    echo ""
    
} > $REPORT_FILE

echo "Performance report generated: $REPORT_FILE"
cat $REPORT_FILE
EOF

chmod +x performance_report.sh
./performance_report.sh
Subtask 5.3: System Optimization Implementation
Step 1: Identify optimization opportunities

Based on the performance analysis, common optimization areas include:

Process Priority Optimization
Memory Management
CPU Scheduling
Resource Cleanup
Step 2: Implement basic optimizations

cat > system_optimizer.sh << 'EOF'
#!/bin/bash

echo "=== SYSTEM OPTIMIZATION SCRIPT ==="

# Function to optimize process priorities
optimize_priorities() {
    echo "Optimizing process priorities..."
    
    # Lower priority for non-essential processes
    for proc in $(pgrep -f "stress-ng"); do
        if [ -n "$proc" ]; then
            renice +10 $proc 2>/dev/null
            echo "Lowered priority for process $proc"
        fi
    done
}

# Function to clean up system resources
cleanup_resources() {
    echo "Cleaning up system resources..."
    
    # Clear system caches (be careful in production)
    sync
    echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || echo "Cache cleanup requires root privileges"
    
    # Remove temporary files
    find /tmp -type f -atime +1 -delete 2>/dev/null
    
    echo "Resource cleanup completed"
}

# Function to optimize memory usage
optimize_memory() {
    echo "Memory optimization recommendations:"
    
    # Check for memory-intensive processes
    echo "Top 5 memory consumers:"
    ps aux --sort=-%mem | head -6
    
    # Check swap usage
    SWAP_USED=$(free | awk 'NR==3{print $3}')
    if [ $SWAP_USED -gt 0 ]; then
        echo "Warning: Swap is being used ($SWAP_USED KB)"
        echo "Consider adding more RAM or optimizing memory usage"
    fi
}

# Function to monitor system health
monitor_health() {
    echo "System health check:"
    
    # CPU load check
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    CPU_CORES=$(nproc)
    
    if (( $(echo "$LOAD_AVG > $CPU_CORES" | bc -l) )); then
        echo "Warning: High CPU load detected ($LOAD_AVG on $CPU_CORES cores)"
    else
        echo "CPU load is normal ($LOAD_AVG on $CPU_CORES cores)"
    fi
    
    # Memory usage check
    MEM_USAGE=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    if (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
        echo "Warning: High memory usage ($MEM_USAGE%)"
    else
        echo "Memory usage is normal ($MEM_USAGE%)"
    fi
}

# Main optimization routine
main() {
    echo "Starting system optimization..."
    echo ""
    
    optimize_priorities
    echo ""
    
    cleanup_resources
    echo ""
    
    optimize_memory
    echo ""
    
    monitor_health
    echo ""
    
    echo "Optimization completed!"
}

# Run main function
main
EOF

chmod +x system_optimizer.sh
Step 3: Create performance monitoring dashboard

cat > performance_dashboard.sh << 'EOF'
#!/bin/bash

# Performance monitoring dashboard
while true; do
    clear
    echo "=== REAL-TIME PERFORMANCE DASHBOARD ==="
    echo "Updated: $(date)"
    echo "Press Ctrl+C to exit"
    echo ""
    
    # CPU Information
    echo "=== CPU USAGE ==="
    top -bn1 | grep "Cpu(s)" | awk '{print "CPU Usage: " $2 " user, " $4 " system, " $8 " idle"}'
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    
    # Memory Information
    echo "=== MEMORY USAGE ==="
    free -h | awk 'NR==2{printf "Memory: %s used / %s total (%.1f%%)\n", $3, $2, $3/$2*100}'
    free -h | awk 'NR==3{printf "Swap: %s used / %s total\n", $3, $2}'
    echo ""
    
    # Top Processes
    echo "=== TOP 5 PROCESSES BY CPU ==="
    ps aux --sort=-%cpu | head -6 | awk 'NR>1{printf "%-20s %5s%% %5s%%\n", $11, $3, $4}'
    echo ""
    
    echo "=== TOP 5 PROCESSES BY MEMORY ==="
    ps aux --sort=-%mem | head -6 | awk 'NR>1{printf "%-20s %5s%% %5s%%\n", $11, $3, $4}'
    echo ""
    
    # Disk Usage
    echo "=== DISK USAGE ==="
    df -h / | awk 'NR==2{printf "Root filesystem: %s used / %s total (%s)\n", $3, $2, $5}'
    echo ""
    
    sleep 5
done
EOF

chmod +x performance_dashboard.sh
Task 6: Advanced Monitoring and Reporting
Subtask 6.1: Creating Custom Monitoring Solutions
Step 1: Develop a comprehensive monitoring script

cat > advanced_monitor.sh << 'EOF'
#!/bin/bash

# Advanced system monitoring script
LOG_DIR="monitoring_logs"
mkdir -p $LOG_DIR

# Configuration
MONITOR_DURATION=3600  # 1 hour
SAMPLE_INTERVAL=10     # 10 seconds
ALERT_CPU_THRESHOLD=80
ALERT_MEM_THRESHOLD=85

# Initialize log files
CPU_LOG="$LOG_DIR/cpu_$(date +%Y%m%d_%H%M%S).log"
MEM_LOG="$LOG_DIR/memory_$(date +%Y%m%d_%H%M%S).log"
PROC_LOG="$LOG_DIR/processes_$(date +%Y%m%d_%H%M%S).log"
ALERT_LOG="$LOG_DIR/alerts_$(date +%Y%m%d_%H%M%S).log"

# Function to log CPU metrics
log_cpu_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    echo "$timestamp,$cpu_usage,$load_avg" >> $CPU_LOG
    
    # Check for CPU alerts
    if (( $(echo "$cpu_usage > $ALERT_CPU_THRESHOLD" | bc -l) )); then
        echo "$timestamp,CPU,High CPU usage: $cpu_usage%" >> $ALERT_LOG
    fi
}

# Function to log memory metrics
log_memory_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local mem_info=$(free | awk 'NR==2{printf "%d,%d,%d,%.1f", $2/1024, $3/1024, $4/1024, $3*100/$2}')
    
    echo "$timestamp,$mem_info" >> $MEM_LOG
    
    # Check for memory alerts
    local mem_percent=$(echo $mem_info | cut -d',' -f4)
    if (( $(echo "$mem_percent > $ALERT_MEM_THRESHOLD" | bc -l) )); then
        echo "$timestamp,MEMORY,High memory usage: $mem_percent%" >> $ALERT_LOG
    fi
}

# Function to log top processes
log_top_processes() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "=== $timestamp ===" >> $PROC_LOG
    ps aux --sort=-%cpu | head -6 >> $PROC_LOG
    echo "" >> $PROC_LOG
}

# Main monitoring loop
echo "Starting advanced monitoring..."
echo "Duration: $MONITOR_DURATION seconds"
echo "Interval: $SAMPLE_INTERVAL seconds"
echo "Logs will be saved in: $LOG_DIR"

# Create log headers
echo "Timestamp,CPU_Usage_Percent,Load_Average" > $CPU_LOG
echo "Timestamp,Total_MB,Used_MB,Free_MB,Usage_Percent" > $MEM_LOG
echo "Advanced Process Monitoring Log" > $PROC_LOG

for ((i=1; i<=MONITOR_DURATION/SAMPLE_INTERVAL; i++)); do
    log_cpu_metrics
    log_memory_metrics
    log_top_processes
    
    echo "Sample $i/$(($MONITOR_DURATION/$SAMPLE_INTERVAL)) completed"
    sleep $SAMPLE_INTERVAL
done

echo "Monitoring completed. Check logs in $LOG_DIR"
EOF

chmod +x advanced_monitor.sh
Subtask 6.2: Performance Trend Analysis
Step 1: Create trend analysis tools

cat > trend_analyzer.sh << 'EOF'
#!/bin/bash

# Performance trend analysis script
LOG_DIR="monitoring_logs"

analyze_cpu_trends() {
    echo "=== CPU TREND ANALYSIS ==="
    
    if [ -f "$LOG_DIR"/*.log ]; then
        local cpu_log=$(ls $LOG_DIR/cpu_*.log | head -1)
        if [ -f "$cpu_log" ]; then
            echo "Analyzing CPU data from: $cpu_log"
            
            # Calculate statistics
            local avg_cpu=$(awk -F',' 'NR>1{sum+=$2; count++} END{printf "%.2f", sum/count}' "$cpu_log")
            local max_cpu=$(awk -F',' 'NR>1{if($2>max) max=$2} END{print max}' "$cpu_log")
            local min_cpu=$(awk -F',' 'NR>1{if(NR==2 || $2<min) min=$2} END{print min}' "$cpu_log")
            
            echo "Average CPU Usage: $avg_cpu%"
            echo "Maximum CPU Usage: $max_cpu%"
            echo "Minimum CPU Usage: $min_cpu%"
            
            # Identify peak
