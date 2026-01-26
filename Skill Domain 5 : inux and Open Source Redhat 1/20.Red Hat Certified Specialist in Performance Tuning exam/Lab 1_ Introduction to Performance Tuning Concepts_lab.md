Lab 1: Introduction to Performance Tuning Concepts
Objectives
By the end of this lab, students will be able to:

Understand the primary goals and principles of performance tuning in Linux systems
Identify and analyze common resource bottlenecks (CPU, memory, disk, and network)
Implement basic tuning strategies for CPU optimization
Apply memory management techniques to improve system performance
Configure disk I/O optimization settings
Use open-source monitoring tools to assess system performance
Interpret performance metrics and make data-driven tuning decisions
Prerequisites
Before starting this lab, students should have:

Basic Linux command-line knowledge
Understanding of Linux file system structure
Familiarity with text editors (vi/vim or nano)
Basic knowledge of system processes and services
Understanding of Linux user permissions and sudo access
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment. No need to build or configure your own virtual machine.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
Pre-installed performance monitoring tools
Sample workloads for testing
Network connectivity for package installation
Task 1: Understanding Performance Tuning Goals and Concepts
Subtask 1.1: Define Performance Tuning Objectives
Performance tuning is the systematic process of optimizing system resources to achieve better performance, efficiency, and user experience.

Primary Goals of Performance Tuning:

Maximize Throughput: Increase the amount of work completed per unit of time
Minimize Response Time: Reduce the time between request and response
Optimize Resource Utilization: Efficiently use CPU, memory, disk, and network resources
Improve Scalability: Enable systems to handle increased load effectively
Enhance User Experience: Provide consistent and responsive system behavior
Reduce Costs: Optimize resource usage to minimize hardware and operational expenses
Subtask 1.2: Establish Baseline Performance Metrics
First, let's install essential performance monitoring tools and establish baseline metrics.

# Update system packages
sudo dnf update -y

# Install performance monitoring tools
sudo dnf install -y htop iotop sysstat perf stress-ng

# Enable and start sysstat service for historical data collection
sudo systemctl enable sysstat
sudo systemctl start sysstat
Create a performance monitoring script:

# Create a baseline monitoring script
cat > ~/performance_baseline.sh << 'EOF'
#!/bin/bash

echo "=== SYSTEM PERFORMANCE BASELINE ==="
echo "Date: $(date)"
echo ""

echo "=== CPU Information ==="
lscpu | grep -E "Model name|CPU\(s\)|Thread|Core"
echo ""

echo "=== Memory Information ==="
free -h
echo ""

echo "=== Disk Information ==="
df -h
echo ""

echo "=== Current Load Average ==="
uptime
echo ""

echo "=== Top 5 CPU Consuming Processes ==="
ps aux --sort=-%cpu | head -6
echo ""

echo "=== Top 5 Memory Consuming Processes ==="
ps aux --sort=-%mem | head -6
echo ""
EOF

# Make the script executable
chmod +x ~/performance_baseline.sh

# Run the baseline assessment
~/performance_baseline.sh
Subtask 1.3: Understanding Performance Metrics
Key performance indicators to monitor:

CPU Utilization: Percentage of CPU time used
Load Average: System load over 1, 5, and 15-minute intervals
Memory Usage: RAM utilization and swap usage
Disk I/O: Read/write operations per second and throughput
Network I/O: Bandwidth utilization and packet rates
Response Time: Time to complete operations
Throughput: Operations completed per unit time
Task 2: Identifying Resource Bottlenecks
Subtask 2.1: CPU Bottleneck Detection
CPU bottlenecks occur when the processor cannot handle the workload efficiently.

Signs of CPU Bottlenecks:

High CPU utilization (consistently above 80%)
High load average (exceeding number of CPU cores)
Increased response times
Process queuing
Let's create a CPU stress test and monitor the bottleneck:

# Monitor CPU usage in real-time (run in terminal 1)
htop

# In another terminal, create CPU stress
stress-ng --cpu 4 --timeout 60s --metrics-brief

# Monitor CPU statistics
sar -u 1 10
Create a CPU bottleneck detection script:

cat > ~/detect_cpu_bottleneck.sh << 'EOF'
#!/bin/bash

echo "=== CPU BOTTLENECK DETECTION ==="

# Get number of CPU cores
CPU_CORES=$(nproc)
echo "System has $CPU_CORES CPU cores"

# Get current load average
LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
LOAD_5MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | tr -d ' ')

echo "Current load average: 1min=$LOAD_1MIN, 5min=$LOAD_5MIN"

# Check if load exceeds CPU cores
if (( $(echo "$LOAD_1MIN > $CPU_CORES" | bc -l) )); then
    echo "WARNING: CPU bottleneck detected! Load ($LOAD_1MIN) exceeds CPU cores ($CPU_CORES)"
else
    echo "CPU load is within normal range"
fi

# Show top CPU consuming processes
echo ""
echo "Top 5 CPU consuming processes:"
ps aux --sort=-%cpu | head -6
EOF

chmod +x ~/detect_cpu_bottleneck.sh
~/detect_cpu_bottleneck.sh
Subtask 2.2: Memory Bottleneck Detection
Memory bottlenecks occur when the system runs out of available RAM.

Signs of Memory Bottlenecks:

High memory utilization (above 90%)
Excessive swap usage
Frequent page faults
Out of Memory (OOM) killer activation
# Monitor memory usage
free -h

# Check for swap usage
swapon --show

# Monitor memory statistics
sar -r 1 5

# Check for OOM killer activity
dmesg | grep -i "killed process"
Create a memory bottleneck detection script:

cat > ~/detect_memory_bottleneck.sh << 'EOF'
#!/bin/bash

echo "=== MEMORY BOTTLENECK DETECTION ==="

# Get memory information
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
USED_MEM=$(free -m | awk 'NR==2{print $3}')
AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
SWAP_USED=$(free -m | awk 'NR==3{print $3}')

# Calculate memory usage percentage
MEM_USAGE_PERCENT=$((USED_MEM * 100 / TOTAL_MEM))

echo "Total Memory: ${TOTAL_MEM}MB"
echo "Used Memory: ${USED_MEM}MB (${MEM_USAGE_PERCENT}%)"
echo "Available Memory: ${AVAILABLE_MEM}MB"
echo "Swap Used: ${SWAP_USED}MB"

# Check for memory bottleneck
if [ $MEM_USAGE_PERCENT -gt 90 ]; then
    echo "CRITICAL: Memory bottleneck detected! Usage above 90%"
elif [ $MEM_USAGE_PERCENT -gt 80 ]; then
    echo "WARNING: High memory usage detected! Usage above 80%"
else
    echo "Memory usage is within normal range"
fi

# Check swap usage
if [ $SWAP_USED -gt 0 ]; then
    echo "WARNING: System is using swap memory ($SWAP_USED MB)"
fi

echo ""
echo "Top 5 memory consuming processes:"
ps aux --sort=-%mem | head -6
EOF

chmod +x ~/detect_memory_bottleneck.sh
~/detect_memory_bottleneck.sh
Subtask 2.3: Disk I/O Bottleneck Detection
Disk bottlenecks occur when storage devices cannot keep up with I/O demands.

Signs of Disk Bottlenecks:

High disk utilization
Long I/O wait times
High average queue length
Slow file operations
# Monitor disk I/O in real-time
iotop

# Check disk statistics
iostat -x 1 5

# Monitor disk usage
df -h
Create a disk bottleneck detection script:

cat > ~/detect_disk_bottleneck.sh << 'EOF'
#!/bin/bash

echo "=== DISK I/O BOTTLENECK DETECTION ==="

# Check disk space usage
echo "Disk Space Usage:"
df -h | grep -E "^/dev"

echo ""
echo "Disk I/O Statistics (5-second average):"
iostat -x 1 5 | tail -n +4

# Check for high I/O wait
IOWAIT=$(sar -u 1 1 | tail -1 | awk '{print $5}' | cut -d'.' -f1)
echo ""
echo "Current I/O Wait: ${IOWAIT}%"

if [ $IOWAIT -gt 20 ]; then
    echo "WARNING: High I/O wait detected! This may indicate disk bottleneck"
elif [ $IOWAIT -gt 10 ]; then
    echo "CAUTION: Moderate I/O wait detected"
else
    echo "I/O wait is within normal range"
fi

# Show processes causing high I/O
echo ""
echo "Top I/O intensive processes:"
iotop -b -n 1 | head -10
EOF

chmod +x ~/detect_disk_bottleneck.sh
~/detect_disk_bottleneck.sh
Task 3: CPU Tuning Strategies
Subtask 3.1: CPU Governor Configuration
CPU governors control how the CPU frequency is adjusted based on system load.

# Check current CPU governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# List available governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors

# Install cpupower utility
sudo dnf install -y kernel-tools

# Check current CPU frequency information
cpupower frequency-info
Configure CPU governor for performance:

# Set performance governor for maximum performance
sudo cpupower frequency-set -g performance

# Verify the change
cpupower frequency-info | grep "current policy"

# Create a script to set optimal CPU governor
cat > ~/set_cpu_governor.sh << 'EOF'
#!/bin/bash

echo "=== CPU GOVERNOR CONFIGURATION ==="

# Check if running on battery or AC power (for laptops)
if [ -f /sys/class/power_supply/ADP1/online ]; then
    POWER_SOURCE=$(cat /sys/class/power_supply/ADP1/online)
    if [ $POWER_SOURCE -eq 1 ]; then
        echo "AC Power detected - Setting performance governor"
        sudo cpupower frequency-set -g performance
    else
        echo "Battery power detected - Setting powersave governor"
        sudo cpupower frequency-set -g powersave
    fi
else
    echo "Server/Desktop system - Setting performance governor"
    sudo cpupower frequency-set -g performance
fi

echo "Current CPU governor:"
cpupower frequency-info | grep "current policy"
EOF

chmod +x ~/set_cpu_governor.sh
~/set_cpu_governor.sh
Subtask 3.2: Process Priority and CPU Affinity
Optimize process scheduling and CPU core assignment:

# Create a CPU-intensive test process
stress-ng --cpu 1 --timeout 300s &
STRESS_PID=$!

# Check current process priority
ps -o pid,ni,comm -p $STRESS_PID

# Reduce process priority (increase nice value)
sudo renice +10 $STRESS_PID

# Verify priority change
ps -o pid,ni,comm -p $STRESS_PID

# Set CPU affinity to specific cores
sudo taskset -cp 0,1 $STRESS_PID

# Verify CPU affinity
taskset -cp $STRESS_PID

# Kill the test process
kill $STRESS_PID
Create a CPU optimization script:

cat > ~/optimize_cpu.sh << 'EOF'
#!/bin/bash

echo "=== CPU OPTIMIZATION SCRIPT ==="

# Function to optimize a process
optimize_process() {
    local PROCESS_NAME=$1
    local NICE_VALUE=$2
    local CPU_CORES=$3
    
    # Find process PID
    PID=$(pgrep $PROCESS_NAME | head -1)
    
    if [ -n "$PID" ]; then
        echo "Optimizing process: $PROCESS_NAME (PID: $PID)"
        
        # Set process priority
        sudo renice $NICE_VALUE $PID
        echo "Set nice value to $NICE_VALUE"
        
        # Set CPU affinity if specified
        if [ -n "$CPU_CORES" ]; then
            sudo taskset -cp $CPU_CORES $PID
            echo "Set CPU affinity to cores: $CPU_CORES"
        fi
    else
        echo "Process $PROCESS_NAME not found"
    fi
}

# Example optimizations
echo "Available CPU cores: $(nproc)"
echo ""

# Optimize system processes (example)
# optimize_process "httpd" "-5" "0,1"  # High priority web server
# optimize_process "mysqld" "-3" "2,3" # Database server
# optimize_process "backup" "10" "0"   # Low priority backup process

echo "CPU optimization complete"
EOF

chmod +x ~/optimize_cpu.sh
Subtask 3.3: CPU Performance Monitoring
Set up continuous CPU performance monitoring:

# Create a comprehensive CPU monitoring script
cat > ~/monitor_cpu_performance.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/cpu_performance.log"
INTERVAL=5

echo "=== CPU PERFORMANCE MONITORING ==="
echo "Logging to: $LOG_FILE"
echo "Monitoring interval: $INTERVAL seconds"
echo "Press Ctrl+C to stop monitoring"

# Create log file with headers
echo "Timestamp,CPU_Usage,Load_1min,Load_5min,Load_15min,Context_Switches,Interrupts" > $LOG_FILE

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get CPU usage (100 - idle percentage)
    CPU_USAGE=$(sar -u 1 1 | tail -1 | awk '{print 100-$8}')
    
    # Get load averages
    LOAD_AVERAGES=$(uptime | awk -F'load average:' '{print $2}' | tr -d ' ')
    LOAD_1MIN=$(echo $LOAD_AVERAGES | cut -d',' -f1)
    LOAD_5MIN=$(echo $LOAD_AVERAGES | cut -d',' -f2)
    LOAD_15MIN=$(echo $LOAD_AVERAGES | cut -d',' -f3)
    
    # Get context switches and interrupts
    CONTEXT_SWITCHES=$(sar -w 1 1 | tail -1 | awk '{print $2}')
    INTERRUPTS=$(sar -I SUM 1 1 | tail -1 | awk '{print $3}')
    
    # Log the data
    echo "$TIMESTAMP,$CPU_USAGE,$LOAD_1MIN,$LOAD_5MIN,$LOAD_15MIN,$CONTEXT_SWITCHES,$INTERRUPTS" >> $LOG_FILE
    
    # Display current status
    echo "[$TIMESTAMP] CPU: ${CPU_USAGE}% | Load: $LOAD_1MIN,$LOAD_5MIN,$LOAD_15MIN"
    
    sleep $INTERVAL
done
EOF

chmod +x ~/monitor_cpu_performance.sh

# Run the monitoring script in background (optional)
# nohup ~/monitor_cpu_performance.sh &
Task 4: Memory Tuning Strategies
Subtask 4.1: Virtual Memory Configuration
Configure virtual memory settings for optimal performance:

# Check current virtual memory settings
sysctl vm.swappiness
sysctl vm.dirty_ratio
sysctl vm.dirty_background_ratio
sysctl vm.vfs_cache_pressure

# Create memory tuning configuration
sudo tee /etc/sysctl.d/99-memory-tuning.conf << 'EOF'
# Memory tuning parameters

# Reduce swappiness (default is 60)
# Lower values make the kernel less likely to swap
vm.swappiness = 10

# Dirty page ratios for better I/O performance
# Percentage of memory that can be dirty before sync
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Cache pressure (default is 100)
# Lower values preserve cache longer
vm.vfs_cache_pressure = 50

# Memory overcommit handling
# 0 = heuristic overcommit, 1 = always overcommit, 2 = don't overcommit
vm.overcommit_memory = 0
vm.overcommit_ratio = 50
EOF

# Apply the settings
sudo sysctl -p /etc/sysctl.d/99-memory-tuning.conf

# Verify the changes
echo "Updated memory settings:"
sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio vm.vfs_cache_pressure
Subtask 4.2: Memory Usage Optimization
Create tools to analyze and optimize memory usage:

# Create memory analysis script
cat > ~/analyze_memory.sh << 'EOF'
#!/bin/bash

echo "=== MEMORY USAGE ANALYSIS ==="

# Basic memory information
echo "Memory Overview:"
free -h

echo ""
echo "Memory Usage by Type:"
cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree"

echo ""
echo "Top 10 Memory Consuming Processes:"
ps aux --sort=-%mem | head -11

echo ""
echo "Memory Usage by User:"
ps hax -o rss,user | awk '{a[$2]+=$1;}END{for(i in a)print i" "int(a[i]/1024+0.5)"MB";}' | sort -rnk2

echo ""
echo "Shared Memory Segments:"
ipcs -m

echo ""
echo "Memory Fragmentation Info:"
cat /proc/buddyinfo

echo ""
echo "Slab Memory Usage (top 10):"
sudo slabtop -o | head -15
EOF

chmod +x ~/analyze_memory.sh
~/analyze_memory.sh
Subtask 4.3: Memory Cleanup and Optimization
Implement memory cleanup strategies:

# Create memory cleanup script
cat > ~/cleanup_memory.sh << 'EOF'
#!/bin/bash

echo "=== MEMORY CLEANUP SCRIPT ==="

# Check memory before cleanup
echo "Memory usage before cleanup:"
free -h

echo ""
echo "Clearing page cache, dentries, and inodes..."

# Clear page cache
sudo sync
sudo echo 1 > /proc/sys/vm/drop_caches

# Clear dentries and inodes
sudo echo 2 > /proc/sys/vm/drop_caches

# Clear page cache, dentries, and inodes
sudo echo 3 > /proc/sys/vm/drop_caches

echo "Cache clearing complete"

echo ""
echo "Memory usage after cleanup:"
free -h

echo ""
echo "Checking for memory leaks in running processes..."

# Create a simple memory leak detector
ps aux --sort=-%mem | head -10 | while read line; do
    PID=$(echo $line | awk '{print $2}')
    COMM=$(echo $line | awk '{print $11}')
    MEM=$(echo $line | awk '{print $4}')
    
    if [ "$PID" != "PID" ] && [ $(echo "$MEM > 10" | bc -l) -eq 1 ]; then
        echo "High memory usage detected: $COMM (PID: $PID) using $MEM% memory"
    fi
done
EOF

chmod +x ~/cleanup_memory.sh
~/cleanup_memory.sh
Task 5: Disk I/O Tuning Strategies
Subtask 5.1: File System Optimization
Configure file system parameters for better performance:

# Check current file system mount options
mount | grep -E "ext4|xfs"

# Check disk scheduler
cat /sys/block/*/queue/scheduler

# Create disk optimization script
cat > ~/optimize_disk.sh << 'EOF'
#!/bin/bash

echo "=== DISK I/O OPTIMIZATION ==="

# Function to optimize disk scheduler
optimize_scheduler() {
    local DISK=$1
    local SCHEDULER=$2
    
    if [ -f /sys/block/$DISK/queue/scheduler ]; then
        echo "Setting $SCHEDULER scheduler for $DISK"
        echo $SCHEDULER | sudo tee /sys/block/$DISK/queue/scheduler
        
        # Verify the change
        echo "Current scheduler for $DISK:"
        cat /sys/block/$DISK/queue/scheduler
    fi
}

# Get list of block devices
DISKS=$(lsblk -d -n -o NAME | grep -E "^sd|^nvme|^vd")

for DISK in $DISKS; do
    echo "Optimizing disk: $DISK"
    
    # For SSDs, use noop or deadline
    # For HDDs, use deadline or cfq
    # For NVMe, use none or mq-deadline
    
    if [[ $DISK == nvme* ]]; then
        optimize_scheduler $DISK "none"
    else
        optimize_scheduler $DISK "deadline"
    fi
    
    # Optimize read-ahead settings
    if [ -f /sys/block/$DISK/queue/read_ahead_kb ]; then
        echo "Setting read-ahead for $DISK to 128KB"
        echo 128 | sudo tee /sys/block/$DISK/queue/read_ahead_kb
    fi
done

echo ""
echo "Disk optimization complete"
EOF

chmod +x ~/optimize_disk.sh
~/optimize_disk.sh
Subtask 5.2: I/O Monitoring and Analysis
Set up comprehensive I/O monitoring:

# Create I/O monitoring script
cat > ~/monitor_disk_io.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/disk_io_performance.log"
INTERVAL=5

echo "=== DISK I/O PERFORMANCE MONITORING ==="
echo "Logging to: $LOG_FILE"
echo "Monitoring interval: $INTERVAL seconds"
echo "Press Ctrl+C to stop monitoring"

# Create log file with headers
echo "Timestamp,Device,Read_KB/s,Write_KB/s,Read_IOPS,Write_IOPS,Util%" > $LOG_FILE

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get I/O statistics
    iostat -x 1 1 | grep -E "^sd|^nvme|^vd" | while read line; do
        DEVICE=$(echo $line | awk '{print $1}')
        READ_KBS=$(echo $line | awk '{print $6}')
        WRITE_KBS=$(echo $line | awk '{print $7}')
        READ_IOPS=$(echo $line | awk '{print $4}')
        WRITE_IOPS=$(echo $line | awk '{print $5}')
        UTIL=$(echo $line | awk '{print $10}')
        
        # Log the data
        echo "$TIMESTAMP,$DEVICE,$READ_KBS,$WRITE_KBS,$READ_IOPS,$WRITE_IOPS,$UTIL" >> $LOG_FILE
        
        # Display current status
        echo "[$TIMESTAMP] $DEVICE: R=${READ_KBS}KB/s W=${WRITE_KBS}KB/s Util=${UTIL}%"
    done
    
    sleep $INTERVAL
done
EOF

chmod +x ~/monitor_disk_io.sh

# Create I/O analysis script
cat > ~/analyze_disk_io.sh << 'EOF'
#!/bin/bash

echo "=== DISK I/O ANALYSIS ==="

echo "Current I/O Statistics:"
iostat -x 1 1

echo ""
echo "Top I/O Intensive Processes:"
iotop -b -n 1 | head -15

echo ""
echo "Disk Usage by Mount Point:"
df -h

echo ""
echo "Inode Usage:"
df -i

echo ""
echo "Files with High I/O Activity:"
sudo lsof | awk '{print $2}' | sort | uniq -c | sort -rn | head -10

echo ""
echo "Block Device Information:"
lsblk -f
EOF

chmod +x ~/analyze_disk_io.sh
~/analyze_disk_io.sh
Subtask 5.3: File System Tuning
Optimize file system parameters:

# Create file system tuning script
cat > ~/tune_filesystem.sh << 'EOF'
#!/bin/bash

echo "=== FILE SYSTEM TUNING ==="

# Function to tune ext4 file systems
tune_ext4() {
    local DEVICE=$1
    echo "Tuning ext4 file system on $DEVICE"
    
    # Check current settings
    sudo tune2fs -l $DEVICE | grep -E "Reserved block count|Block size"
    
    # Reduce reserved blocks for non-root file systems
    if [[ $DEVICE != *"root"* ]] && [[ $DEVICE != *"/"* ]]; then
        echo "Reducing reserved blocks to 1%"
        sudo tune2fs -m 1 $DEVICE
    fi
    
    # Enable dir_index for better directory performance
    sudo tune2fs -O dir_index $DEVICE
}

# Function to tune XFS file systems
tune_xfs() {
    local DEVICE=$1
    echo "XFS file system detected on $DEVICE"
    echo "XFS is already well-optimized by default"
    
    # Show XFS information
    sudo xfs_info $DEVICE 2>/dev/null || echo "XFS tools not available"
}

# Get mounted file systems
echo "Analyzing mounted file systems:"
df -T | grep -E "ext4|xfs" | while read line; do
    DEVICE=$(echo $line | awk '{print $1}')
    FSTYPE=$(echo $line | awk '{print $2}')
    MOUNTPOINT=$(echo $line | awk '{print $7}')
    
    echo ""
    echo "Processing: $DEVICE ($FSTYPE) mounted on $MOUNTPOINT"
    
    case $FSTYPE in
        ext4)
            tune_ext4 $DEVICE
            ;;
        xfs)
            tune_xfs $DEVICE
            ;;
        *)
            echo "File system type $FSTYPE not supported for tuning"
            ;;
    esac
done

echo ""
echo "File system tuning complete"
EOF

chmod +x ~/tune_filesystem.sh
~/tune_filesystem.sh
Comprehensive Performance Testing
Create an Integrated Performance Test
# Create comprehensive performance test script
cat > ~/performance_test_suite.sh << 'EOF'
#!/bin/bash

TEST_DURATION=60
RESULTS_DIR="$HOME/performance_results"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

echo "=== COMPREHENSIVE PERFORMANCE TEST SUITE ==="
echo "Test duration: $TEST_DURATION seconds"
echo "Results directory: $RESULTS_DIR"

# Create results directory
mkdir -p $RESULTS_DIR

# Function to run CPU test
test_cpu() {
    echo "Running CPU performance test..."
    
    # Baseline CPU test
    echo "CPU cores: $(nproc)" > $RESULTS_DIR/cpu_test_$TIMESTAMP.log
    echo "CPU model: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)" >> $RESULTS_DIR/cpu_test_$TIMESTAMP.log
    
    # CPU stress test with monitoring
    stress-ng --cpu $(nproc) --timeout ${TEST_DURATION}s --metrics-brief >> $RESULTS_DIR/cpu_test_$TIMESTAMP.log 2>&1 &
    STRESS_PID=$!
    
    # Monitor CPU during test
    for i in $(seq 1 $((TEST_DURATION/5))); do
        echo "Sample $i: $(date)" >> $RESULTS_DIR/cpu_monitoring_$TIMESTAMP.log
        sar -u 1 1 >> $RESULTS_DIR/cpu_monitoring_$TIMESTAMP.log
        sleep 4
    done
    
    wait $STRESS_PID
    echo "CPU test completed"
}

# Function to run memory test
test_memory() {
    echo "Running memory performance test..."
    
    # Get memory info
    free -h > $RESULTS_DIR/memory_test_$TIMESTAMP.log
    
    # Memory stress test
    MEMORY_SIZE=$(free -m | awk 'NR==2{printf "%.0f", $2*0.8}')  # Use 80% of available memory
    echo "Testing with ${MEMORY_SIZE}MB memory allocation" >> $RESULTS_DIR/memory_test_$TIMESTAMP.log
    
    stress-ng --vm 2 --vm-bytes ${MEMORY_SIZE}M --timeout ${TEST_DURATION}s --metrics-brief >> $RESULTS_DIR/memory_test_$TIMESTAMP.log 2>&1 &
    STRESS_PID=$!
    
    # Monitor memory during test
    for i in $(seq 1 $((TEST_DURATION/5))); do
        echo "Sample $i: $(date)" >> $RESULTS_DIR/memory_monitoring_$TIMESTAMP.log
        free -h >> $RESULTS_DIR/memory_monitoring_$TIMESTAMP.log
        sleep 4
    done
    
    wait $STRESS_PID
    echo "Memory test completed"
}

# Function to run disk I/O test
test_disk_io() {
    echo "Running disk I/O performance test..."
    
    # Create test directory
    TEST_DIR="$HOME/disk_test"
    mkdir -p $TEST_DIR
    
    # Disk write test
    echo "Write test:" > $RESULTS_DIR/disk_test_$TIMESTAMP.log
    dd if=/dev/zero of=$TEST_DIR/testfile bs=1M count=1024 oflag=direct 2>> $RESULTS_DIR/disk_test_$TIMESTAMP.log
    
    # Disk read test
    echo "Read test:" >> $RESULTS_DIR/disk_test_$TIMESTAMP.log
    dd if=$TEST_DIR/testfile of=/dev/null bs=1M iflag=direct 2>> $RESULTS_DIR/disk_test_$TIMESTAMP.log
    
    # Random I/O test using stress-ng
    stress-ng --hdd 2 --hdd-bytes 1G --temp-path $TEST_DIR --timeout ${TEST_DURATION}s --metrics-brief >> $RESULTS_DIR/disk_test_$TIMESTAMP.log 2>&1 &
    STRESS_PID=$!
    
    # Monitor I/O during test
    for i in $(seq 1 $((TEST_DURATION/5))); do
        echo "Sample $i: $(date)" >> $RESULTS_DIR/disk_monitoring_$TIMESTAMP.log
        iostat -x 1 1 >> $RESULTS_DIR/disk_monitoring_$TIMESTAMP.log
        sleep 4
    done
    
    wait $STRESS_PID
    
    # Cleanup
    rm -rf $TEST_DIR
    echo "Disk I/O test completed"
}

# Run all tests
echo "Starting performance test suite at $(date)"

test_cpu
echo ""
test_memory
echo ""
test_disk_io

echo ""
echo "=== PERFORMANCE TEST SUMMARY ==="
echo "All tests completed at $(date)"
echo "Results saved in: $RESULTS_DIR"
echo ""
echo "Test files created:"
ls -la $RESULTS_DIR/*$TIMESTAMP*

# Generate summary report
cat
