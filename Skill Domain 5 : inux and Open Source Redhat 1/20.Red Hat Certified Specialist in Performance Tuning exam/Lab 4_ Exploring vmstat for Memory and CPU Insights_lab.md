Lab 4: Exploring vmstat for Memory and CPU Insights
Objectives
By the end of this lab, students will be able to:

Understand the purpose and functionality of the vmstat command
Use vmstat to monitor real-time system performance metrics
Analyze memory usage patterns and identify memory bottlenecks
Monitor swap activity and understand its impact on system performance
Interpret CPU utilization statistics and identify performance issues
Recognize signs of system resource contention
Apply vmstat analysis techniques for performance tuning scenarios
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line interface
Familiarity with system administration concepts
Knowledge of memory management fundamentals (RAM, swap, virtual memory)
Understanding of CPU concepts (user space, kernel space, I/O wait)
Access to a Linux terminal environment
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Pre-installed system monitoring tools
Sufficient resources to generate meaningful performance data
Root or sudo access for system monitoring
Task 1: Understanding vmstat Basics and Initial System Analysis
Subtask 1.1: Introduction to vmstat Command Structure
First, let's understand what vmstat is and how it works.

Access your lab environment and open a terminal session.

Check if vmstat is available on your system:

which vmstat
View the vmstat manual to understand its options:
man vmstat
Display vmstat help for quick reference:
vmstat --help
Subtask 1.2: Basic vmstat Execution
Run vmstat with default settings to get a snapshot of current system state:
vmstat
Expected Output Example:

procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 1  0      0 1847532  92164 1456789    0    0     8     5   45   89  2  1 97  0  0
Understand each column by examining the output:
Process Columns (procs):

r: Number of runnable processes
b: Number of processes blocked waiting for I/O
Memory Columns (memory - in KB):

swpd: Amount of virtual memory used
free: Amount of idle memory
buff: Amount of memory used as buffers
cache: Amount of memory used as cache
Swap Columns (swap):

si: Memory swapped in from disk (KB/s)
so: Memory swapped out to disk (KB/s)
I/O Columns (io):

bi: Blocks received from block device (blocks/s)
bo: Blocks sent to block device (blocks/s)
System Columns (system):

in: Number of interrupts per second
cs: Number of context switches per second
CPU Columns (cpu - percentages):

us: Time spent running user code
sy: Time spent running kernel code
id: Time spent idle
wa: Time spent waiting for I/O
st: Time stolen from virtual machine
Subtask 1.3: Continuous Monitoring Setup
Run vmstat with continuous monitoring (updates every 2 seconds):
vmstat 2
Let it run for about 30 seconds, then stop with Ctrl+C.

Run vmstat with specific count (5 reports, 3 seconds apart):

vmstat 3 5
Task 2: Memory Analysis and Bottleneck Identification
Subtask 2.1: Memory Usage Pattern Analysis
Create a script to generate memory load for testing purposes:
cat > memory_test.sh << 'EOF'
#!/bin/bash
echo "Starting memory allocation test..."
# Allocate memory in chunks
for i in {1..10}; do
    echo "Allocating memory chunk $i"
    # Create a large array in memory
    dd if=/dev/zero of=/tmp/memtest_$i bs=100M count=1 2>/dev/null &
    sleep 2
done
wait
echo "Memory test complete. Cleaning up..."
rm -f /tmp/memtest_*
EOF
Make the script executable:
chmod +x memory_test.sh
Start vmstat monitoring in one terminal:
vmstat 1
In another terminal, run the memory test:
./memory_test.sh
Observe the memory columns during the test:
Watch free memory decrease
Monitor buff and cache changes
Check for any swpd activity
Subtask 2.2: Swap Activity Monitoring
Check current swap configuration:
free -h
swapon --show
Create a script to force swap usage:
cat > swap_test.sh << 'EOF'
#!/bin/bash
echo "Creating memory pressure to trigger swap..."
# Get total RAM in KB
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
# Calculate 80% of RAM
TARGET_SIZE=$((TOTAL_RAM * 80 / 100))

echo "Allocating ${TARGET_SIZE}KB of memory..."
# Use stress tool if available, otherwise use dd
if command -v stress >/dev/null 2>&1; then
    stress --vm 1 --vm-bytes ${TARGET_SIZE}k --timeout 60s
else
    # Alternative method using dd and temporary files
    for i in {1..8}; do
        dd if=/dev/zero of=/tmp/swaptest_$i bs=1M count=$((TARGET_SIZE/8/1024)) 2>/dev/null &
    done
    sleep 60
    killall dd 2>/dev/null
    rm -f /tmp/swaptest_*
fi
EOF
Make the script executable:
chmod +x swap_test.sh
Monitor swap activity with vmstat:
vmstat 1
Run the swap test (in another terminal):
./swap_test.sh
Analyze the swap columns:
si (swap in): Should show activity when memory is read from swap
so (swap out): Should show activity when memory is written to swap
High values indicate memory pressure
Subtask 2.3: Memory Bottleneck Identification
Create a comprehensive memory analysis script:
cat > memory_analysis.sh << 'EOF'
#!/bin/bash
echo "=== Memory Analysis Report ==="
echo "Current Date: $(date)"
echo

echo "=== Basic Memory Information ==="
free -h
echo

echo "=== Swap Information ==="
swapon --show
echo

echo "=== Memory Usage Breakdown ==="
cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree)"
echo

echo "=== Top Memory Consuming Processes ==="
ps aux --sort=-%mem | head -10
echo

echo "=== vmstat Summary (5 samples, 1 second apart) ==="
vmstat 1 5
EOF
Run the memory analysis:
chmod +x memory_analysis.sh
./memory_analysis.sh
Interpret the results:
Memory bottleneck indicators:
Free memory consistently below 10% of total
High swap usage (swpd > 0 and growing)
Frequent swap in/out activity (si/so > 0)
High number of blocked processes (b column)
Task 3: CPU Performance Analysis
Subtask 3.1: CPU Utilization Monitoring
Monitor baseline CPU usage:
vmstat 2 10
Create a CPU load generator script:
cat > cpu_test.sh << 'EOF'
#!/bin/bash
echo "Starting CPU load test..."

# Function to create CPU load
cpu_load() {
    local duration=$1
    local end_time=$((SECONDS + duration))
    
    while [ $SECONDS -lt $end_time ]; do
        # Perform CPU-intensive calculation
        echo "scale=5000; 4*a(1)" | bc -l > /dev/null 2>&1
    done
}

# Create different types of CPU load
echo "Phase 1: User space CPU load (30 seconds)..."
for i in {1..2}; do
    cpu_load 30 &
done
wait

echo "Phase 2: Mixed load with I/O (30 seconds)..."
for i in {1..2}; do
    (
        while [ $SECONDS -lt 30 ]; do
            dd if=/dev/zero of=/tmp/iotest_$i bs=1M count=10 2>/dev/null
            rm -f /tmp/iotest_$i
        done
    ) &
done
wait

echo "CPU test complete."
EOF
Make the script executable:
chmod +x cpu_test.sh
Start vmstat monitoring:
vmstat 1
Run the CPU test (in another terminal):
./cpu_test.sh
Analyze CPU columns during the test:
us: Should increase during user space load
sy: Should increase during system calls and I/O
id: Should decrease when CPU is busy
wa: Should increase during I/O wait periods
Subtask 3.2: I/O Wait Analysis
Create an I/O intensive script:
cat > io_test.sh << 'EOF'
#!/bin/bash
echo "Starting I/O intensive test..."

# Create large files to generate I/O load
for i in {1..5}; do
    echo "Creating I/O load $i..."
    (
        # Write large file
        dd if=/dev/zero of=/tmp/ioload_$i bs=10M count=50 2>/dev/null
        # Read it back
        dd if=/tmp/ioload_$i of=/dev/null bs=10M 2>/dev/null
        # Clean up
        rm -f /tmp/ioload_$i
    ) &
done

wait
echo "I/O test complete."
EOF
Make the script executable:
chmod +x io_test.sh
Monitor I/O wait with vmstat:
vmstat 1
Run the I/O test (in another terminal):
./io_test.sh
Observe the I/O and CPU metrics:
wa: Should show high values during I/O operations
bi/bo: Should show disk I/O activity
b: May show processes blocked on I/O
Subtask 3.3: CPU Performance Bottleneck Identification
Create a comprehensive CPU analysis script:
cat > cpu_analysis.sh << 'EOF'
#!/bin/bash
echo "=== CPU Performance Analysis ==="
echo "Current Date: $(date)"
echo

echo "=== CPU Information ==="
lscpu | grep -E "(CPU\(s\)|Model name|CPU MHz|Cache)"
echo

echo "=== Load Average ==="
uptime
echo

echo "=== Current CPU Usage ==="
top -bn1 | grep "Cpu(s)"
echo

echo "=== Top CPU Consuming Processes ==="
ps aux --sort=-%cpu | head -10
echo

echo "=== vmstat CPU Analysis (10 samples, 2 seconds apart) ==="
vmstat 2 10
echo

echo "=== CPU Performance Indicators ==="
echo "High CPU utilization: us + sy > 80%"
echo "I/O bottleneck: wa > 20%"
echo "System overhead: sy > 30%"
echo "CPU contention: r > number of CPUs"
EOF
Run the CPU analysis:
chmod +x cpu_analysis.sh
./cpu_analysis.sh
Task 4: Advanced vmstat Usage and Performance Tuning
Subtask 4.1: Disk I/O Analysis
Use vmstat with disk statistics:
vmstat -d
Monitor disk I/O over time:
vmstat -d 3 5
Analyze partition-specific statistics:
vmstat -p /dev/sda1 2 5
Subtask 4.2: Memory Statistics Deep Dive
Display detailed memory statistics:
vmstat -s
Create a memory trend analysis:
cat > memory_trend.sh << 'EOF'
#!/bin/bash
echo "=== Memory Trend Analysis ==="
echo "Timestamp,Free_MB,Used_MB,Buff_MB,Cache_MB,Swap_Used_MB" > memory_trend.csv

for i in {1..20}; do
    TIMESTAMP=$(date '+%H:%M:%S')
    MEMORY_DATA=$(free -m | awk 'NR==2{printf "%d,%d,%d", $4,$3,$6} NR==3{printf ",%d", $3}')
    CACHE_DATA=$(free -m | awk 'NR==2{printf ",%d", $7}')
    echo "$TIMESTAMP,$MEMORY_DATA$CACHE_DATA" >> memory_trend.csv
    sleep 3
done

echo "Memory trend data saved to memory_trend.csv"
cat memory_trend.csv
EOF
Run the memory trend analysis:
chmod +x memory_trend.sh
./memory_trend.sh
Subtask 4.3: System Performance Baseline
Create a comprehensive system baseline script:
cat > system_baseline.sh << 'EOF'
#!/bin/bash
BASELINE_FILE="system_baseline_$(date +%Y%m%d_%H%M%S).txt"

echo "=== System Performance Baseline ===" > $BASELINE_FILE
echo "Generated: $(date)" >> $BASELINE_FILE
echo >> $BASELINE_FILE

echo "=== System Information ===" >> $BASELINE_FILE
uname -a >> $BASELINE_FILE
echo >> $BASELINE_FILE

echo "=== CPU Information ===" >> $BASELINE_FILE
lscpu >> $BASELINE_FILE
echo >> $BASELINE_FILE

echo "=== Memory Information ===" >> $BASELINE_FILE
free -h >> $BASELINE_FILE
echo >> $BASELINE_FILE

echo "=== Disk Information ===" >> $BASELINE_FILE
df -h >> $BASELINE_FILE
echo >> $BASELINE_FILE

echo "=== Network Interfaces ===" >> $BASELINE_FILE
ip addr show >> $BASELINE_FILE
echo >> $BASELINE_FILE

echo "=== vmstat Baseline (20 samples, 3 seconds apart) ===" >> $BASELINE_FILE
vmstat 3 20 >> $BASELINE_FILE
echo >> $BASELINE_FILE

echo "=== vmstat Memory Statistics ===" >> $BASELINE_FILE
vmstat -s >> $BASELINE_FILE
echo >> $BASELINE_FILE

echo "=== vmstat Disk Statistics ===" >> $BASELINE_FILE
vmstat -d >> $BASELINE_FILE

echo "Baseline saved to: $BASELINE_FILE"
echo "Use this file to compare against future performance measurements."
EOF
Generate system baseline:
chmod +x system_baseline.sh
./system_baseline.sh
Task 5: Performance Issue Simulation and Analysis
Subtask 5.1: Simulating Common Performance Issues
Create a performance issue simulator:
cat > performance_simulator.sh << 'EOF'
#!/bin/bash

simulate_memory_leak() {
    echo "Simulating memory leak..."
    # Gradually consume memory
    for i in {1..50}; do
        dd if=/dev/zero of=/tmp/leak_$i bs=10M count=1 2>/dev/null &
        sleep 2
    done
}

simulate_cpu_spike() {
    echo "Simulating CPU spike..."
    # Create CPU-intensive processes
    for i in {1..4}; do
        (while true; do echo "scale=1000; 4*a(1)" | bc -l >/dev/null 2>&1; done) &
    done
    sleep 30
    killall bc 2>/dev/null
}

simulate_io_bottleneck() {
    echo "Simulating I/O bottleneck..."
    # Create multiple I/O intensive processes
    for i in {1..8}; do
        (
            while [ $SECONDS -lt 45 ]; do
                dd if=/dev/zero of=/tmp/iobottleneck_$i bs=5M count=20 2>/dev/null
                dd if=/tmp/iobottleneck_$i of=/dev/null bs=5M 2>/dev/null
            done
            rm -f /tmp/iobottleneck_$i
        ) &
    done
    wait
}

cleanup() {
    echo "Cleaning up..."
    killall dd bc 2>/dev/null
    rm -f /tmp/leak_* /tmp/iobottleneck_*
}

trap cleanup EXIT

echo "Performance Issue Simulator"
echo "1. Memory leak simulation"
echo "2. CPU spike simulation"
echo "3. I/O bottleneck simulation"
echo "4. All simulations"
read -p "Choose simulation (1-4): " choice

case $choice in
    1) simulate_memory_leak ;;
    2) simulate_cpu_spike ;;
    3) simulate_io_bottleneck ;;
    4) 
        simulate_memory_leak &
        sleep 10
        simulate_cpu_spike &
        sleep 10
        simulate_io_bottleneck &
        wait
        ;;
    *) echo "Invalid choice" ;;
esac
EOF
Make the simulator executable:
chmod +x performance_simulator.sh
Subtask 5.2: Real-time Performance Monitoring
Create a real-time monitoring dashboard:
cat > monitor_dashboard.sh << 'EOF'
#!/bin/bash

# Function to display colored output
print_colored() {
    local color=$1
    local text=$2
    case $color in
        red) echo -e "\033[31m$text\033[0m" ;;
        green) echo -e "\033[32m$text\033[0m" ;;
        yellow) echo -e "\033[33m$text\033[0m" ;;
        blue) echo -e "\033[34m$text\033[0m" ;;
        *) echo "$text" ;;
    esac
}

# Function to analyze vmstat output
analyze_performance() {
    local vmstat_line=$1
    local r b us sy id wa
    
    read r b swpd free buff cache si so bi bo in cs us sy id wa st <<< "$vmstat_line"
    
    echo "=== Performance Analysis ==="
    
    # CPU Analysis
    if [ "$us" -gt 80 ]; then
        print_colored red "HIGH USER CPU: $us%"
    elif [ "$us" -gt 50 ]; then
        print_colored yellow "MODERATE USER CPU: $us%"
    else
        print_colored green "NORMAL USER CPU: $us%"
    fi
    
    if [ "$sy" -gt 30 ]; then
        print_colored red "HIGH SYSTEM CPU: $sy%"
    elif [ "$sy" -gt 15 ]; then
        print_colored yellow "MODERATE SYSTEM CPU: $sy%"
    else
        print_colored green "NORMAL SYSTEM CPU: $sy%"
    fi
    
    if [ "$wa" -gt 20 ]; then
        print_colored red "HIGH I/O WAIT: $wa%"
    elif [ "$wa" -gt 10 ]; then
        print_colored yellow "MODERATE I/O WAIT: $wa%"
    else
        print_colored green "NORMAL I/O WAIT: $wa%"
    fi
    
    # Memory Analysis
    if [ "$si" -gt 0 ] || [ "$so" -gt 0 ]; then
        print_colored red "SWAP ACTIVITY DETECTED: SI=$si SO=$so"
    else
        print_colored green "NO SWAP ACTIVITY"
    fi
    
    # Process Analysis
    local cpu_count=$(nproc)
    if [ "$r" -gt $((cpu_count * 2)) ]; then
        print_colored red "HIGH PROCESS QUEUE: $r processes"
    elif [ "$r" -gt "$cpu_count" ]; then
        print_colored yellow "MODERATE PROCESS QUEUE: $r processes"
    else
        print_colored green "NORMAL PROCESS QUEUE: $r processes"
    fi
    
    if [ "$b" -gt 5 ]; then
        print_colored red "HIGH BLOCKED PROCESSES: $b"
    elif [ "$b" -gt 0 ]; then
        print_colored yellow "SOME BLOCKED PROCESSES: $b"
    else
        print_colored green "NO BLOCKED PROCESSES"
    fi
    
    echo "=========================="
}

echo "Real-time Performance Monitor"
echo "Press Ctrl+C to stop"
echo

# Skip the header line and process vmstat output
vmstat 2 | tail -n +4 | while read line; do
    clear
    echo "=== System Performance Dashboard ==="
    echo "Time: $(date)"
    echo
    echo "Raw vmstat output:"
    echo "$line"
    echo
    analyze_performance "$line"
    echo
    echo "Legend: Green=Normal, Yellow=Warning, Red=Critical"
done
EOF
Run the monitoring dashboard:
chmod +x monitor_dashboard.sh
./monitor_dashboard.sh
In another terminal, run the performance simulator:
./performance_simulator.sh
Task 6: Troubleshooting Common Issues
Common vmstat Troubleshooting Scenarios
Issue: vmstat command not found

# Solution: Install procps package
# On RHEL/CentOS:
sudo yum install procps-ng
# On Ubuntu/Debian:
sudo apt-get install procps
Issue: Permission denied errors

# Solution: Run with appropriate permissions
sudo vmstat
Issue: Understanding negative values

# Some values might appear negative due to counter overflow
# This is normal for long-running systems
Performance Interpretation Guidelines
Memory Bottleneck Indicators:

swpd consistently increasing
si and so values > 0 regularly
free memory < 10% of total RAM
High cache usage with low free memory
CPU Bottleneck Indicators:

us + sy > 80% consistently
r (run queue) > number of CPU cores
id (idle) < 20% consistently
wa > 20% indicates I/O bottleneck
I/O Bottleneck Indicators:

wa > 20% consistently
b (blocked processes) > 0 regularly
High bi and bo values
r queue building up with high wa
Conclusion
In this comprehensive lab, you have successfully:

Mastered vmstat fundamentals - You learned how to use vmstat to monitor system performance in real-time, understanding each column and metric provided by this powerful tool.

Analyzed memory performance - You gained hands-on experience identifying memory bottlenecks, monitoring swap activity, and understanding memory usage patterns that can impact system performance.

Evaluated CPU utilization - You learned to interpret CPU statistics, identify different types of CPU load (user, system, I/O wait), and recognize performance bottlenecks.

Implemented performance monitoring - You created scripts and tools for continuous monitoring, baseline establishment, and automated performance analysis.

Simulated real-world scenarios - You experienced common performance issues in a controlled environment and learned how to identify and analyze them using vmstat.

Why This Matters:

Understanding vmstat is crucial for system administrators and performance engineers because:

Proactive Monitoring: Early detection of performance issues before they impact users
Resource Planning: Making informed decisions about hardware upgrades and capacity planning
Troubleshooting: Quickly identifying the root cause of performance problems
Optimization: Fine-tuning system performance based on actual usage patterns
Cost Management: Optimizing resource utilization to reduce infrastructure costs
Next Steps:

Practice using vmstat in different scenarios and environments
Combine vmstat with other monitoring tools like iostat, sar, and top
Create automated monitoring scripts for production environments
Study the relationship between vmstat metrics and application performance
Explore advanced performance tuning techniques based on vmstat insights
This knowledge directly applies to the Red Hat Certified Specialist in Performance Tuning exam and real-world system administration tasks, making you more effective at maintaining high-performing Linux systems.
