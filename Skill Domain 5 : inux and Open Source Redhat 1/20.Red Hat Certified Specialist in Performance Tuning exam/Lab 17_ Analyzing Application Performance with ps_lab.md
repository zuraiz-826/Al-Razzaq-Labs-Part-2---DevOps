Lab 17: Analyzing Application Performance with ps
Objectives
By the end of this lab, students will be able to:

• Master the ps command and its various options for process monitoring • Analyze running applications and their resource consumption patterns • Identify performance bottlenecks and resource-intensive processes • Implement optimization strategies for system performance • Terminate inefficient applications safely using proper procedures • Interpret process statistics and system resource utilization metrics

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command-line interface • Familiarity with file system navigation and basic commands • Knowledge of process concepts in Linux/Unix systems • Understanding of system resources (CPU, memory, disk I/O) • Basic text editor skills (nano, vim, or similar)

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment. No need to build your own virtual machine or install additional software.

Your cloud machine includes: • CentOS/RHEL 8 or Ubuntu 20.04 LTS • Pre-installed monitoring tools • Sample applications for testing • Administrative privileges for process management

Task 1: Understanding and Using ps Command for Process Analysis
Subtask 1.1: Basic ps Command Usage
First, let's explore the fundamental ps command options and understand process information display.

Step 1: Connect to your cloud machine and open a terminal session.

Step 2: Display all running processes with detailed information:

ps aux
Expected Output Explanation: • USER: Process owner • PID: Process ID (unique identifier) • %CPU: CPU usage percentage • %MEM: Memory usage percentage • VSZ: Virtual memory size in KB • RSS: Resident Set Size (physical memory) in KB • TTY: Terminal type • STAT: Process state • START: Process start time • TIME: CPU time consumed • COMMAND: Command that started the process

Step 3: Display processes in a tree format to show parent-child relationships:

ps auxf
Step 4: Show processes for the current user only:

ps ux
Subtask 1.2: Advanced ps Command Options
Step 1: Display processes with custom formatting for better analysis:

ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu
This command shows: • Process ID and Parent Process ID • Command name • Memory and CPU usage • Sorted by CPU usage (highest first)

Step 2: Monitor specific process information:

ps -eo pid,user,cmd,pcpu,pmem,time --sort=-pcpu | head -20
Step 3: Display processes with their thread count:

ps -eLf
Subtask 1.3: Creating Sample Workloads for Analysis
To practice performance analysis, we'll create some test processes with different resource consumption patterns.

Step 1: Create a CPU-intensive script:

cat > cpu_intensive.sh << 'EOF'
#!/bin/bash
# CPU-intensive process simulation
echo "Starting CPU-intensive process..."
while true; do
    echo "scale=5000; 4*a(1)" | bc -l > /dev/null 2>&1
done
EOF

chmod +x cpu_intensive.sh
Step 2: Create a memory-intensive script:

cat > memory_intensive.py << 'EOF'
#!/usr/bin/env python3
import time
import sys

print("Starting memory-intensive process...")
# Allocate memory gradually
memory_blocks = []
try:
    for i in range(1000):
        # Allocate 1MB blocks
        block = bytearray(1024 * 1024)
        memory_blocks.append(block)
        time.sleep(0.1)
        if i % 100 == 0:
            print(f"Allocated {i} MB")
except KeyboardInterrupt:
    print("Process interrupted")
    sys.exit(0)
EOF

chmod +x memory_intensive.py
Step 3: Start the test processes in background:

# Start CPU-intensive process
./cpu_intensive.sh &
CPU_PID=$!
echo "CPU-intensive process started with PID: $CPU_PID"

# Start memory-intensive process
python3 memory_intensive.py &
MEM_PID=$!
echo "Memory-intensive process started with PID: $MEM_PID"
Task 2: Analyzing Resource Usage and Identifying Performance Issues
Subtask 2.1: Real-time Process Monitoring
Step 1: Monitor processes with continuous updates:

watch -n 2 'ps aux --sort=-%cpu | head -20'
This command updates every 2 seconds showing the top 20 CPU-consuming processes.

Step 2: In a new terminal, monitor memory usage:

watch -n 2 'ps aux --sort=-%mem | head -20'
Step 3: Create a comprehensive monitoring script:

cat > process_monitor.sh << 'EOF'
#!/bin/bash

echo "=== System Process Analysis Report ==="
echo "Generated on: $(date)"
echo

echo "=== TOP 10 CPU CONSUMERS ==="
ps aux --sort=-%cpu | head -11

echo
echo "=== TOP 10 MEMORY CONSUMERS ==="
ps aux --sort=-%mem | head -11

echo
echo "=== PROCESS COUNT BY USER ==="
ps aux | awk 'NR>1 {users[$1]++} END {for (user in users) print user, users[user]}' | sort -k2 -nr

echo
echo "=== ZOMBIE PROCESSES ==="
ps aux | awk '$8 ~ /^Z/ {print $2, $11}'

echo
echo "=== SYSTEM LOAD AVERAGE ==="
uptime
EOF

chmod +x process_monitor.sh
Step 4: Run the monitoring script:

./process_monitor.sh
Subtask 2.2: Detailed Process Analysis
Step 1: Analyze specific process details using PID:

# Replace PID with actual process ID from your system
ps -p $CPU_PID -o pid,ppid,cmd,pcpu,pmem,etime,time
Step 2: Check process status and state information:

ps -p $CPU_PID -o pid,stat,wchan,cmd
Process State Codes: • R: Running or runnable • S: Interruptible sleep • D: Uninterruptible sleep • Z: Zombie • T: Stopped

Step 3: Monitor process resource usage over time:

cat > track_process.sh << 'EOF'
#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <PID>"
    exit 1
fi

PID=$1
echo "Tracking process $PID..."
echo "Time,CPU%,MEM%,VSZ,RSS"

for i in {1..10}; do
    if ps -p $PID > /dev/null 2>&1; then
        ps -p $PID -o pcpu,pmem,vsz,rss --no-headers | \
        awk -v time="$(date +%H:%M:%S)" '{printf "%s,%.1f,%.1f,%d,%d\n", time, $1, $2, $3, $4}'
    else
        echo "Process $PID no longer exists"
        break
    fi
    sleep 5
done
EOF

chmod +x track_process.sh
Step 4: Track your CPU-intensive process:

./track_process.sh $CPU_PID
Subtask 2.3: Identifying Performance Bottlenecks
Step 1: Create a script to identify problematic processes:

cat > identify_issues.sh << 'EOF'
#!/bin/bash

echo "=== PERFORMANCE ISSUE IDENTIFICATION ==="
echo

# High CPU usage processes (>50%)
echo "=== HIGH CPU USAGE PROCESSES (>50%) ==="
ps aux | awk 'NR>1 && $3>50 {printf "PID: %s, USER: %s, CPU: %.1f%%, CMD: %s\n", $2, $1, $3, $11}'

echo
# High memory usage processes (>10%)
echo "=== HIGH MEMORY USAGE PROCESSES (>10%) ==="
ps aux | awk 'NR>1 && $4>10 {printf "PID: %s, USER: %s, MEM: %.1f%%, CMD: %s\n", $2, $1, $4, $11}'

echo
# Long-running processes
echo "=== LONG-RUNNING PROCESSES (>1 hour CPU time) ==="
ps aux | awk 'NR>1 {
    split($10, time_parts, ":");
    if (length(time_parts) == 3 && (time_parts[1] > 0 || time_parts[2] > 60)) {
        printf "PID: %s, USER: %s, TIME: %s, CMD: %s\n", $2, $1, $10, $11
    }
}'

echo
# Processes with many threads
echo "=== PROCESSES WITH HIGH THREAD COUNT ==="
ps -eLf | awk 'NR>1 {threads[$2]++} END {for (pid in threads) if (threads[pid] > 10) print "PID:", pid, "Threads:", threads[pid]}' | sort -k4 -nr
EOF

chmod +x identify_issues.sh
Step 2: Run the issue identification script:

./identify_issues.sh
Task 3: Process Optimization and Termination
Subtask 3.1: Process Priority Management
Step 1: Check current process priorities:

ps -eo pid,ni,cmd --sort=pid | head -20
The NI column shows the nice value (-20 to 19, where lower values mean higher priority).

Step 2: Change process priority using renice:

# Lower priority (higher nice value) for CPU-intensive process
sudo renice 10 $CPU_PID
echo "Changed priority for PID $CPU_PID"

# Verify the change
ps -p $CPU_PID -o pid,ni,cmd
Step 3: Start a process with specific priority:

# Start a low-priority background task
nice -n 15 ./cpu_intensive.sh &
LOW_PRIORITY_PID=$!
echo "Started low-priority process with PID: $LOW_PRIORITY_PID"
Subtask 3.2: Safe Process Termination
Step 1: Create a script for safe process termination:

cat > safe_terminate.sh << 'EOF'
#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <PID> [signal]"
    echo "Common signals: TERM (15), KILL (9), HUP (1), USR1 (10)"
    exit 1
fi

PID=$1
SIGNAL=${2:-TERM}

# Check if process exists
if ! ps -p $PID > /dev/null 2>&1; then
    echo "Process $PID does not exist"
    exit 1
fi

# Get process information
PROCESS_INFO=$(ps -p $PID -o pid,user,cmd --no-headers)
echo "Process to terminate: $PROCESS_INFO"

# Send signal
echo "Sending $SIGNAL signal to process $PID..."
kill -$SIGNAL $PID

# Wait and check if process terminated
sleep 2
if ps -p $PID > /dev/null 2>&1; then
    echo "Process $PID is still running"
    if [ "$SIGNAL" != "KILL" ]; then
        echo "You may need to use KILL signal: $0 $PID KILL"
    fi
else
    echo "Process $PID terminated successfully"
fi
EOF

chmod +x safe_terminate.sh
Step 2: Terminate the test processes gracefully:

# First, try graceful termination
./safe_terminate.sh $CPU_PID TERM
./safe_terminate.sh $MEM_PID TERM

# If needed, force termination
if ps -p $CPU_PID > /dev/null 2>&1; then
    ./safe_terminate.sh $CPU_PID KILL
fi

if ps -p $LOW_PRIORITY_PID > /dev/null 2>&1; then
    ./safe_terminate.sh $LOW_PRIORITY_PID KILL
fi
Subtask 3.3: Process Management Best Practices
Step 1: Create a comprehensive process management script:

cat > process_manager.sh << 'EOF'
#!/bin/bash

show_help() {
    echo "Process Manager - Advanced ps-based process analysis tool"
    echo
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  -t, --top           Show top resource consumers"
    echo "  -u, --user USER     Show processes for specific user"
    echo "  -s, --search TERM   Search for processes containing TERM"
    echo "  -k, --kill PID      Safely terminate process"
    echo "  -m, --monitor       Continuous monitoring mode"
    echo "  -r, --report        Generate detailed system report"
    echo "  -h, --help          Show this help message"
}

show_top() {
    echo "=== TOP RESOURCE CONSUMERS ==="
    echo
    echo "Top 10 CPU consumers:"
    ps aux --sort=-%cpu | head -11 | awk 'NR==1 {print $0} NR>1 {printf "%-8s %6s %5.1f%% %5.1f%% %s\n", $1, $2, $3, $4, $11}'
    echo
    echo "Top 10 Memory consumers:"
    ps aux --sort=-%mem | head -11 | awk 'NR==1 {print $0} NR>1 {printf "%-8s %6s %5.1f%% %5.1f%% %s\n", $1, $2, $3, $4, $11}'
}

show_user_processes() {
    local user=$1
    echo "=== PROCESSES FOR USER: $user ==="
    ps -u $user -o pid,pcpu,pmem,time,cmd --sort=-%cpu
}

search_processes() {
    local term=$1
    echo "=== PROCESSES MATCHING: $term ==="
    ps aux | grep -i "$term" | grep -v grep
}

monitor_mode() {
    echo "=== CONTINUOUS MONITORING MODE ==="
    echo "Press Ctrl+C to exit"
    while true; do
        clear
        echo "System Process Monitor - $(date)"
        echo "========================================"
        ps aux --sort=-%cpu | head -15
        echo
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        sleep 3
    done
}

generate_report() {
    local report_file="process_report_$(date +%Y%m%d_%H%M%S).txt"
    echo "Generating detailed report: $report_file"
    
    {
        echo "=== SYSTEM PROCESS ANALYSIS REPORT ==="
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "Uptime: $(uptime)"
        echo
        
        echo "=== SYSTEM SUMMARY ==="
        echo "Total processes: $(ps aux | wc -l)"
        echo "Running processes: $(ps aux | awk '$8=="R" {count++} END {print count+0}')"
        echo "Sleeping processes: $(ps aux | awk '$8~/^S/ {count++} END {print count+0}')"
        echo "Zombie processes: $(ps aux | awk '$8=="Z" {count++} END {print count+0}')"
        echo
        
        show_top
        echo
        
        echo "=== PROCESS TREE ==="
        ps auxf
        
    } > "$report_file"
    
    echo "Report saved to: $report_file"
}

# Main script logic
case "$1" in
    -t|--top)
        show_top
        ;;
    -u|--user)
        if [ -z "$2" ]; then
            echo "Error: Please specify a username"
            exit 1
        fi
        show_user_processes "$2"
        ;;
    -s|--search)
        if [ -z "$2" ]; then
            echo "Error: Please specify a search term"
            exit 1
        fi
        search_processes "$2"
        ;;
    -k|--kill)
        if [ -z "$2" ]; then
            echo "Error: Please specify a PID"
            exit 1
        fi
        ./safe_terminate.sh "$2"
        ;;
    -m|--monitor)
        monitor_mode
        ;;
    -r|--report)
        generate_report
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "Error: Unknown option '$1'"
        show_help
        exit 1
        ;;
esac
EOF

chmod +x process_manager.sh
Step 2: Test the process manager:

# Show top consumers
./process_manager.sh --top

# Generate a detailed report
./process_manager.sh --report

# Search for specific processes
./process_manager.sh --search "python"
Task 4: Advanced Performance Analysis Techniques
Subtask 4.1: Process Resource Tracking
Step 1: Create a long-term process tracking system:

cat > resource_tracker.sh << 'EOF'
#!/bin/bash

LOGFILE="process_resources.log"
INTERVAL=10  # seconds

echo "Starting resource tracking (logging to $LOGFILE)"
echo "Press Ctrl+C to stop"

# Initialize log file
echo "Timestamp,PID,User,CPU%,MEM%,VSZ,RSS,Command" > "$LOGFILE"

trap 'echo "Stopping resource tracker..."; exit 0' INT

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log top 5 CPU consumers
    ps aux --sort=-%cpu | head -6 | tail -5 | while read line; do
        echo "$TIMESTAMP,$line" | awk '{
            gsub(/ +/, ",", $0)
            print $1","$3","$2","$4","$5","$6","$7","$12
        }' >> "$LOGFILE"
    done
    
    sleep $INTERVAL
done
EOF

chmod +x resource_tracker.sh
Step 2: Start some test processes and track them:

# Start a few background processes for tracking
python3 -c "import time; [time.sleep(0.1) for _ in range(1000)]" &
TEST_PID1=$!

dd if=/dev/zero of=/tmp/testfile bs=1M count=100 2>/dev/null &
TEST_PID2=$!

# Start tracking (run for 1 minute)
timeout 60 ./resource_tracker.sh

# Clean up test processes
kill $TEST_PID1 $TEST_PID2 2>/dev/null
rm -f /tmp/testfile
Step 3: Analyze the collected data:

cat > analyze_logs.sh << 'EOF'
#!/bin/bash

LOGFILE="process_resources.log"

if [ ! -f "$LOGFILE" ]; then
    echo "Log file $LOGFILE not found"
    exit 1
fi

echo "=== RESOURCE USAGE ANALYSIS ==="
echo

echo "=== HIGHEST CPU USAGE RECORDED ==="
tail -n +2 "$LOGFILE" | sort -t',' -k4 -nr | head -5

echo
echo "=== HIGHEST MEMORY USAGE RECORDED ==="
tail -n +2 "$LOGFILE" | sort -t',' -k5 -nr | head -5

echo
echo "=== MOST FREQUENT HIGH-RESOURCE PROCESSES ==="
tail -n +2 "$LOGFILE" | awk -F',' '$4>10 || $5>5 {print $8}' | sort | uniq -c | sort -nr

echo
echo "=== RESOURCE USAGE OVER TIME ==="
tail -n +2 "$LOGFILE" | awk -F',' '{
    time=$1; cpu+=$4; mem+=$5; count++
    if (count==5) {
        printf "%s: Avg CPU=%.1f%%, Avg MEM=%.1f%%\n", time, cpu/5, mem/5
        cpu=0; mem=0; count=0
    }
}'
EOF

chmod +x analyze_logs.sh
./analyze_logs.sh
Subtask 4.2: System Performance Baseline
Step 1: Create a system baseline script:

cat > system_baseline.sh << 'EOF'
#!/bin/bash

BASELINE_FILE="system_baseline_$(date +%Y%m%d).txt"

echo "Creating system performance baseline: $BASELINE_FILE"

{
    echo "=== SYSTEM PERFORMANCE BASELINE ==="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo
    
    echo "=== SYSTEM INFORMATION ==="
    echo "Kernel: $(uname -r)"
    echo "CPU Info: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
    echo "CPU Cores: $(nproc)"
    echo "Total Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo
    
    echo "=== CURRENT LOAD ==="
    uptime
    echo
    
    echo "=== MEMORY USAGE ==="
    free -h
    echo
    
    echo "=== PROCESS STATISTICS ==="
    echo "Total processes: $(ps aux | wc -l)"
    echo "Running: $(ps aux | awk '$8=="R" {count++} END {print count+0}')"
    echo "Sleeping: $(ps aux | awk '$8~/^S/ {count++} END {print count+0}')"
    echo "Stopped: $(ps aux | awk '$8=="T" {count++} END {print count+0}')"
    echo "Zombie: $(ps aux | awk '$8=="Z" {count++} END {print count+0}')"
    echo
    
    echo "=== TOP 10 PROCESSES BY CPU ==="
    ps aux --sort=-%cpu | head -11
    echo
    
    echo "=== TOP 10 PROCESSES BY MEMORY ==="
    ps aux --sort=-%mem | head -11
    echo
    
    echo "=== PROCESS COUNT BY USER ==="
    ps aux | awk 'NR>1 {users[$1]++} END {for (user in users) printf "%-10s %d\n", user, users[user]}' | sort -k2 -nr
    
} > "$BASELINE_FILE"

echo "Baseline saved to: $BASELINE_FILE"
echo "Use this file to compare against future system states"
EOF

chmod +x system_baseline.sh
./system_baseline.sh
Troubleshooting Common Issues
Issue 1: Process Information Not Updating
Problem: ps command shows stale information Solution:

# Force refresh of process information
sync
echo 3 > /proc/sys/vm/drop_caches  # Requires root
Issue 2: Cannot Kill Process
Problem: Process doesn't respond to TERM signal Solution:

# Try different signals in order
kill -TERM $PID
sleep 5
kill -INT $PID
sleep 5
kill -KILL $PID
Issue 3: High CPU Usage but No Obvious Cause
Problem: System shows high CPU but ps doesn't show culprit Solution:

# Check for kernel threads and system processes
ps aux | grep -E '\[.*\]'
# Check I/O wait
iostat 1 5
Issue 4: Memory Usage Doesn't Add Up
Problem: Individual process memory doesn't match system total Solution:

# Check shared memory and buffers
cat /proc/meminfo
# Use pmap for detailed memory mapping
pmap -x $PID
Conclusion
In this comprehensive lab, you have successfully mastered advanced process analysis and performance monitoring using the ps command and related tools. Here's what you accomplished:

Key Skills Developed
• Process Monitoring Mastery: You learned to use various ps command options to monitor system processes, analyze resource consumption, and identify performance bottlenecks.

• Performance Analysis: You developed skills to interpret process statistics, track resource usage over time, and create comprehensive system performance reports.

• Process Management: You implemented safe process termination procedures, priority management, and optimization strategies for system performance.

• Automation and Scripting: You created sophisticated monitoring scripts that can be used in production environments for ongoing system analysis.

Real-World Applications
The skills you've developed in this lab are directly applicable to:

• System Administration: Daily monitoring and maintenance of production servers • Performance Tuning: Identifying and resolving system bottlenecks • Capacity Planning: Understanding resource utilization patterns for future planning • Troubleshooting: Diagnosing system performance issues and application problems • Security Monitoring: Detecting unusual process behavior that might indicate security issues

Red Hat Certification Relevance
This lab directly supports preparation for the Red Hat Certified Specialist in Performance Tuning exam by providing hands-on experience with:

• Process analysis and monitoring techniques • System performance baseline establishment • Resource utilization optimization • Performance troubleshooting methodologies

Next Steps
To further enhance your performance analysis skills, consider:

• Exploring additional monitoring tools like top, htop, and iotop • Learning about system performance metrics and sar command usage • Studying advanced process scheduling and priority management • Investigating container and virtualization performance monitoring

The process analysis skills you've mastered form the foundation for advanced system administration and performance engineering roles in enterprise environments.
