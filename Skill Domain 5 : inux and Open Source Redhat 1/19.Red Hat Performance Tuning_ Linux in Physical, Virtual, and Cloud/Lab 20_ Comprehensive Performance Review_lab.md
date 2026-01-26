Lab 20: Comprehensive Performance Review
Objectives
By the end of this lab, students will be able to:

• Perform comprehensive system performance analysis using multiple monitoring tools simultaneously • Identify performance bottlenecks across CPU, memory, disk I/O, and network resources • Apply appropriate system tuning techniques based on performance analysis results • Document performance changes and validate optimization effectiveness • Integrate multiple monitoring tools for holistic system assessment • Make data-driven decisions for system optimization in production environments

Prerequisites
Before starting this lab, students should have:

• Basic Linux command-line proficiency including file navigation and text editing • Understanding of system resources (CPU, memory, disk I/O, processes) • Familiarity with performance monitoring concepts from previous labs • Knowledge of system tuning parameters and their impact • Experience with basic shell scripting and command piping • Access to root or sudo privileges for system configuration changes

Lab Environment Setup
Al Nafi Cloud Machines: This lab uses Al Nafi's pre-configured Linux cloud machines. Simply click Start Lab to access your dedicated environment - no VM setup required! Your machine comes with all necessary tools pre-installed.

System Specifications: • CentOS/RHEL 8+ or Ubuntu 20.04+ Linux distribution • Minimum 4GB RAM and 2 CPU cores • Root/sudo access enabled • Performance monitoring tools pre-installed

Task 1: Comprehensive System Performance Assessment
Subtask 1.1: Initialize Monitoring Environment
First, let's prepare our monitoring environment and create a workspace for our performance review.

Step 1: Create a dedicated directory for performance data collection

# Create performance review workspace
sudo mkdir -p /opt/performance-review
cd /opt/performance-review

# Create subdirectories for different data types
sudo mkdir -p {baseline,monitoring,reports,scripts}
sudo chown -R $USER:$USER /opt/performance-review
Step 2: Verify all required monitoring tools are available

# Check tool availability
which top iostat sar htop vmstat free df
echo "All tools check completed"
Step 3: Create a system information baseline

# Collect basic system information
cat > baseline/system_info.txt << EOF
System Performance Review - $(date)
=====================================
Hostname: $(hostname)
Kernel: $(uname -r)
CPU Info: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)
Memory: $(free -h | grep Mem | awk '{print $2}')
Disk Space: $(df -h / | tail -1 | awk '{print $2}')
Uptime: $(uptime)
EOF

cat baseline/system_info.txt
Subtask 1.2: Concurrent Performance Monitoring Setup
Step 1: Create a comprehensive monitoring script

cat > scripts/performance_monitor.sh << 'EOF'
#!/bin/bash

# Comprehensive Performance Monitoring Script
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MONITOR_DIR="/opt/performance-review/monitoring"
DURATION=300  # 5 minutes monitoring

echo "Starting comprehensive performance monitoring..."
echo "Duration: ${DURATION} seconds"
echo "Timestamp: ${TIMESTAMP}"

# Create timestamped directory
mkdir -p "${MONITOR_DIR}/${TIMESTAMP}"
cd "${MONITOR_DIR}/${TIMESTAMP}"

# Function to run monitoring tools in background
start_monitoring() {
    echo "Initializing monitoring tools..."
    
    # CPU and process monitoring with top
    top -b -d 2 -n $((DURATION/2)) > top_output.txt &
    TOP_PID=$!
    
    # I/O statistics monitoring
    iostat -x 2 $((DURATION/2)) > iostat_output.txt &
    IOSTAT_PID=$!
    
    # System activity reporting
    sar -u -r -d -n DEV 2 $((DURATION/2)) > sar_output.txt &
    SAR_PID=$!
    
    # Additional system metrics
    vmstat 2 $((DURATION/2)) > vmstat_output.txt &
    VMSTAT_PID=$!
    
    # Memory usage tracking
    while [ $DURATION -gt 0 ]; do
        echo "$(date): $(free -m | grep Mem)" >> memory_tracking.txt
        sleep 5
        DURATION=$((DURATION-5))
    done &
    MEMORY_PID=$!
    
    # Store process IDs for cleanup
    echo "$TOP_PID $IOSTAT_PID $SAR_PID $VMSTAT_PID $MEMORY_PID" > monitor_pids.txt
    
    echo "All monitoring tools started. PIDs saved to monitor_pids.txt"
    echo "Monitoring will run for 5 minutes..."
}

# Function to stop monitoring
stop_monitoring() {
    echo "Stopping monitoring tools..."
    if [ -f monitor_pids.txt ]; then
        for pid in $(cat monitor_pids.txt); do
            kill $pid 2>/dev/null || true
        done
        rm -f monitor_pids.txt
    fi
    echo "Monitoring stopped."
}

# Trap to ensure cleanup on script exit
trap stop_monitoring EXIT

# Start monitoring
start_monitoring

# Wait for monitoring to complete
sleep 305

echo "Performance monitoring completed. Data saved in: ${MONITOR_DIR}/${TIMESTAMP}"
EOF

chmod +x scripts/performance_monitor.sh
Step 2: Execute the comprehensive monitoring script

# Run the monitoring script
./scripts/performance_monitor.sh
Note: This script will run for 5 minutes, collecting data from multiple tools simultaneously. You can continue with other tasks while it runs.

Subtask 1.3: Generate System Load for Testing
While monitoring is running, let's create some system load to generate meaningful performance data.

Step 1: Create a CPU stress test script

cat > scripts/cpu_stress.sh << 'EOF'
#!/bin/bash

echo "Starting CPU stress test..."

# CPU intensive task - calculate prime numbers
stress_cpu() {
    local duration=$1
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Prime number calculation
        for i in {1..10000}; do
            factor $i > /dev/null 2>&1
        done
    done
}

# Run CPU stress on multiple cores
for i in {1..2}; do
    stress_cpu 180 &  # 3 minutes
done

echo "CPU stress test running for 3 minutes..."
wait
echo "CPU stress test completed."
EOF

chmod +x scripts/cpu_stress.sh
Step 2: Create a disk I/O stress test script

cat > scripts/io_stress.sh << 'EOF'
#!/bin/bash

echo "Starting I/O stress test..."

# Create test directory
mkdir -p /tmp/io_test
cd /tmp/io_test

# Write test - create multiple files
for i in {1..5}; do
    dd if=/dev/zero of=testfile_${i}.dat bs=1M count=100 2>/dev/null &
done

sleep 60  # Let write operations run

# Read test - read the files
for i in {1..5}; do
    dd if=testfile_${i}.dat of=/dev/null bs=1M 2>/dev/null &
done

sleep 60  # Let read operations run

# Cleanup
rm -f testfile_*.dat
cd /opt/performance-review

echo "I/O stress test completed."
EOF

chmod +x scripts/io_stress.sh
Step 3: Execute stress tests (in separate terminals or background)

# Run CPU stress in background
./scripts/cpu_stress.sh &

# Wait 30 seconds, then run I/O stress
sleep 30
./scripts/io_stress.sh &

echo "Stress tests initiated. Monitor system performance."
Task 2: Performance Data Analysis and Tunable Identification
Subtask 2.1: Analyze Collected Performance Data
Step 1: Create a data analysis script

cat > scripts/analyze_performance.sh << 'EOF'
#!/bin/bash

# Performance Data Analysis Script
LATEST_DIR=$(ls -1t /opt/performance-review/monitoring/ | head -1)
DATA_DIR="/opt/performance-review/monitoring/${LATEST_DIR}"
REPORT_DIR="/opt/performance-review/reports"

mkdir -p "$REPORT_DIR"
REPORT_FILE="${REPORT_DIR}/performance_analysis_$(date +%Y%m%d_%H%M%S).txt"

echo "Performance Analysis Report - $(date)" > "$REPORT_FILE"
echo "=========================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Analyze CPU usage from top output
echo "CPU USAGE ANALYSIS:" >> "$REPORT_FILE"
echo "-------------------" >> "$REPORT_FILE"
if [ -f "${DATA_DIR}/top_output.txt" ]; then
    # Extract CPU usage statistics
    grep "Cpu(s)" "${DATA_DIR}/top_output.txt" | head -10 | \
    awk '{print $2}' | sed 's/%us,//' | \
    awk '{sum+=$1; count++} END {if(count>0) printf "Average CPU Usage: %.2f%%\n", sum/count}' >> "$REPORT_FILE"
    
    # Find highest CPU consuming processes
    echo "Top CPU consuming processes:" >> "$REPORT_FILE"
    grep -A 20 "PID USER" "${DATA_DIR}/top_output.txt" | grep -v "PID USER" | \
    head -10 | awk '{print $9"% - "$12}' | sort -nr | head -5 >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Analyze I/O statistics
echo "DISK I/O ANALYSIS:" >> "$REPORT_FILE"
echo "------------------" >> "$REPORT_FILE"
if [ -f "${DATA_DIR}/iostat_output.txt" ]; then
    # Extract average I/O wait times
    grep -E "^[a-z]" "${DATA_DIR}/iostat_output.txt" | \
    awk '{if(NF>10) {util+=$NF; count++}} END {if(count>0) printf "Average Disk Utilization: %.2f%%\n", util/count}' >> "$REPORT_FILE"
    
    # Find devices with high I/O wait
    echo "Devices with high I/O utilization:" >> "$REPORT_FILE"
    grep -E "^[a-z]" "${DATA_DIR}/iostat_output.txt" | \
    awk '{if(NF>10 && $NF>50) print $1": "$NF"%"}' | sort -u >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Analyze memory usage
echo "MEMORY USAGE ANALYSIS:" >> "$REPORT_FILE"
echo "----------------------" >> "$REPORT_FILE"
if [ -f "${DATA_DIR}/memory_tracking.txt" ]; then
    # Calculate average memory usage
    awk '{used+=$3; total+=$2; count++} END {
        if(count>0) {
            avg_used=used/count; 
            avg_total=total/count; 
            usage_pct=(avg_used/avg_total)*100;
            printf "Average Memory Usage: %.0f MB / %.0f MB (%.1f%%)\n", avg_used, avg_total, usage_pct
        }
    }' "${DATA_DIR}/memory_tracking.txt" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Analyze SAR data
echo "SYSTEM ACTIVITY ANALYSIS:" >> "$REPORT_FILE"
echo "-------------------------" >> "$REPORT_FILE"
if [ -f "${DATA_DIR}/sar_output.txt" ]; then
    # Extract network activity
    echo "Network Activity Summary:" >> "$REPORT_FILE"
    grep -E "eth0|ens|enp" "${DATA_DIR}/sar_output.txt" | \
    awk '{rx+=$5; tx+=$6; count++} END {
        if(count>0) printf "Average RX: %.2f KB/s, TX: %.2f KB/s\n", rx/count, tx/count
    }' >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

echo "Analysis completed. Report saved to: $REPORT_FILE"
cat "$REPORT_FILE"
EOF

chmod +x scripts/analyze_performance.sh
Step 2: Run the performance analysis

# Execute the analysis script
./scripts/analyze_performance.sh
Subtask 2.2: Identify Performance Bottlenecks
Step 1: Create a bottleneck identification script

cat > scripts/identify_bottlenecks.sh << 'EOF'
#!/bin/bash

echo "PERFORMANCE BOTTLENECK IDENTIFICATION"
echo "====================================="

# Check current system tunables
echo "Current System Configuration:"
echo "-----------------------------"

# CPU-related settings
echo "CPU Scaling Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'Not available')"

# Memory settings
echo "Swappiness: $(cat /proc/sys/vm/swappiness)"
echo "Dirty Ratio: $(cat /proc/sys/vm/dirty_ratio)"
echo "Dirty Background Ratio: $(cat /proc/sys/vm/dirty_background_ratio)"

# I/O scheduler
for disk in $(lsblk -d -n -o NAME | grep -E '^[a-z]+$'); do
    scheduler=$(cat /sys/block/$disk/queue/scheduler 2>/dev/null || echo 'N/A')
    echo "I/O Scheduler for $disk: $scheduler"
done

# Network settings
echo "TCP Congestion Control: $(cat /proc/sys/net/ipv4/tcp_congestion_control)"
echo "TCP Window Scaling: $(cat /proc/sys/net/ipv4/tcp_window_scaling)"

echo ""
echo "BOTTLENECK ANALYSIS:"
echo "-------------------"

# Check CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
if (( $(echo "$cpu_usage > 80" | bc -l) )); then
    echo "⚠️  HIGH CPU USAGE DETECTED: ${cpu_usage}%"
    echo "   Recommendation: Check CPU governor, consider process optimization"
fi

# Check memory usage
mem_usage=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')
if (( $(echo "$mem_usage > 85" | bc -l) )); then
    echo "⚠️  HIGH MEMORY USAGE DETECTED: ${mem_usage}%"
    echo "   Recommendation: Adjust swappiness, check for memory leaks"
fi

# Check swap usage
swap_usage=$(free | grep Swap | awk '{if($2>0) printf "%.1f", ($3/$2) * 100.0; else print "0"}')
if (( $(echo "$swap_usage > 10" | bc -l) )); then
    echo "⚠️  SWAP USAGE DETECTED: ${swap_usage}%"
    echo "   Recommendation: Increase RAM or optimize memory usage"
fi

# Check disk I/O wait
io_wait=$(iostat -c 1 2 | tail -1 | awk '{print $4}')
if (( $(echo "$io_wait > 20" | bc -l) )); then
    echo "⚠️  HIGH I/O WAIT DETECTED: ${io_wait}%"
    echo "   Recommendation: Check I/O scheduler, disk performance"
fi

# Check load average
load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
cpu_cores=$(nproc)
if (( $(echo "$load_avg > $cpu_cores" | bc -l) )); then
    echo "⚠️  HIGH LOAD AVERAGE: $load_avg (CPU cores: $cpu_cores)"
    echo "   Recommendation: Investigate running processes"
fi

echo ""
echo "Bottleneck identification completed."
EOF

chmod +x scripts/identify_bottlenecks.sh
Step 2: Execute bottleneck identification

# Run bottleneck identification
./scripts/identify_bottlenecks.sh
Task 3: Apply System Tuning Based on Analysis
Subtask 3.1: Create Tuning Recommendations
Step 1: Generate tuning recommendations script

cat > scripts/tuning_recommendations.sh << 'EOF'
#!/bin/bash

echo "SYSTEM TUNING RECOMMENDATIONS"
echo "=============================="

# Create backup of current settings
BACKUP_DIR="/opt/performance-review/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup of current settings in: $BACKUP_DIR"

# Backup current tunables
echo "$(cat /proc/sys/vm/swappiness)" > "$BACKUP_DIR/swappiness.bak"
echo "$(cat /proc/sys/vm/dirty_ratio)" > "$BACKUP_DIR/dirty_ratio.bak"
echo "$(cat /proc/sys/vm/dirty_background_ratio)" > "$BACKUP_DIR/dirty_background_ratio.bak"

# Network settings backup
echo "$(cat /proc/sys/net/core/rmem_max)" > "$BACKUP_DIR/rmem_max.bak"
echo "$(cat /proc/sys/net/core/wmem_max)" > "$BACKUP_DIR/wmem_max.bak"

echo "Backup completed."
echo ""

echo "RECOMMENDED TUNING PARAMETERS:"
echo "------------------------------"

# Memory tuning recommendations
current_swappiness=$(cat /proc/sys/vm/swappiness)
echo "Current swappiness: $current_swappiness"
if [ "$current_swappiness" -gt 10 ]; then
    echo "✓ Recommendation: Reduce swappiness to 10 for better performance"
    echo "  Command: echo 10 | sudo tee /proc/sys/vm/swappiness"
fi

# Dirty ratio tuning
current_dirty=$(cat /proc/sys/vm/dirty_ratio)
echo "Current dirty_ratio: $current_dirty"
if [ "$current_dirty" -gt 15 ]; then
    echo "✓ Recommendation: Reduce dirty_ratio to 15 for better I/O performance"
    echo "  Command: echo 15 | sudo tee /proc/sys/vm/dirty_ratio"
fi

# I/O scheduler recommendations
echo ""
echo "I/O SCHEDULER RECOMMENDATIONS:"
for disk in $(lsblk -d -n -o NAME | grep -E '^[a-z]+$'); do
    current_scheduler=$(cat /sys/block/$disk/queue/scheduler | grep -o '\[.*\]' | tr -d '[]')
    echo "Disk $disk current scheduler: $current_scheduler"
    
    # Check if it's SSD or HDD
    rotational=$(cat /sys/block/$disk/queue/rotational)
    if [ "$rotational" = "0" ]; then
        echo "✓ SSD detected - Recommend 'noop' or 'deadline' scheduler"
        echo "  Command: echo noop | sudo tee /sys/block/$disk/queue/scheduler"
    else
        echo "✓ HDD detected - Recommend 'cfq' scheduler"
        echo "  Command: echo cfq | sudo tee /sys/block/$disk/queue/scheduler"
    fi
done

echo ""
echo "NETWORK TUNING RECOMMENDATIONS:"
echo "-------------------------------"
current_rmem=$(cat /proc/sys/net/core/rmem_max)
current_wmem=$(cat /proc/sys/net/core/wmem_max)

if [ "$current_rmem" -lt 16777216 ]; then
    echo "✓ Increase network receive buffer size"
    echo "  Command: echo 16777216 | sudo tee /proc/sys/net/core/rmem_max"
fi

if [ "$current_wmem" -lt 16777216 ]; then
    echo "✓ Increase network send buffer size"
    echo "  Command: echo 16777216 | sudo tee /proc/sys/net/core/wmem_max"
fi

echo ""
echo "To apply all recommendations, run: ./scripts/apply_tuning.sh"
EOF

chmod +x scripts/tuning_recommendations.sh
Step 2: Run tuning recommendations

# Generate recommendations
./scripts/tuning_recommendations.sh
Subtask 3.2: Apply Performance Tuning
Step 1: Create tuning application script

cat > scripts/apply_tuning.sh << 'EOF'
#!/bin/bash

echo "APPLYING PERFORMANCE TUNING"
echo "==========================="

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

echo "Applying memory tuning..."

# Memory tuning
echo 10 > /proc/sys/vm/swappiness
echo "✓ Swappiness set to 10"

echo 15 > /proc/sys/vm/dirty_ratio
echo "✓ Dirty ratio set to 15"

echo 5 > /proc/sys/vm/dirty_background_ratio
echo "✓ Dirty background ratio set to 5"

# I/O scheduler tuning
echo "Applying I/O scheduler tuning..."
for disk in $(lsblk -d -n -o NAME | grep -E '^[a-z]+$'); do
    rotational=$(cat /sys/block/$disk/queue/rotational)
    if [ "$rotational" = "0" ]; then
        # SSD - use noop scheduler
        echo noop > /sys/block/$disk/queue/scheduler 2>/dev/null || echo deadline > /sys/block/$disk/queue/scheduler
        echo "✓ Set scheduler for SSD $disk to noop/deadline"
    else
        # HDD - use cfq scheduler
        echo cfq > /sys/block/$disk/queue/scheduler 2>/dev/null || echo mq-deadline > /sys/block/$disk/queue/scheduler
        echo "✓ Set scheduler for HDD $disk to cfq/mq-deadline"
    fi
done

# Network tuning
echo "Applying network tuning..."
echo 16777216 > /proc/sys/net/core/rmem_max
echo 16777216 > /proc/sys/net/core/wmem_max
echo "✓ Network buffer sizes increased"

# TCP tuning
echo 1 > /proc/sys/net/ipv4/tcp_window_scaling
echo "✓ TCP window scaling enabled"

# Create persistent configuration
echo "Creating persistent configuration..."
cat > /etc/sysctl.d/99-performance-tuning.conf << 'SYSCTL_EOF'
# Performance tuning applied by lab
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_window_scaling = 1
SYSCTL_EOF

echo "✓ Persistent configuration saved to /etc/sysctl.d/99-performance-tuning.conf"

echo ""
echo "TUNING APPLIED SUCCESSFULLY!"
echo "Changes will persist after reboot."
echo ""
echo "Current settings verification:"
echo "Swappiness: $(cat /proc/sys/vm/swappiness)"
echo "Dirty ratio: $(cat /proc/sys/vm/dirty_ratio)"
echo "Network rmem_max: $(cat /proc/sys/net/core/rmem_max)"
EOF

chmod +x scripts/apply_tuning.sh
Step 2: Apply the tuning (requires sudo)

# Apply tuning with sudo privileges
sudo ./scripts/apply_tuning.sh
Subtask 3.3: Verify Applied Changes
Step 1: Create verification script

cat > scripts/verify_tuning.sh << 'EOF'
#!/bin/bash

echo "TUNING VERIFICATION"
echo "==================="

echo "Memory Settings:"
echo "---------------"
echo "Swappiness: $(cat /proc/sys/vm/swappiness)"
echo "Dirty Ratio: $(cat /proc/sys/vm/dirty_ratio)"
echo "Dirty Background Ratio: $(cat /proc/sys/vm/dirty_background_ratio)"

echo ""
echo "I/O Schedulers:"
echo "--------------"
for disk in $(lsblk -d -n -o NAME | grep -E '^[a-z]+$'); do
    scheduler=$(cat /sys/block/$disk/queue/scheduler | grep -o '\[.*\]' | tr -d '[]')
    rotational=$(cat /sys/block/$disk/queue/rotational)
    disk_type=$([ "$rotational" = "0" ] && echo "SSD" || echo "HDD")
    echo "$disk ($disk_type): $scheduler"
done

echo ""
echo "Network Settings:"
echo "----------------"
echo "Receive buffer max: $(cat /proc/sys/net/core/rmem_max)"
echo "Send buffer max: $(cat /proc/sys/net/core/wmem_max)"
echo "TCP window scaling: $(cat /proc/sys/net/ipv4/tcp_window_scaling)"

echo ""
echo "Persistent Configuration:"
echo "------------------------"
if [ -f /etc/sysctl.d/99-performance-tuning.conf ]; then
    echo "✓ Persistent configuration file exists"
    echo "Contents:"
    cat /etc/sysctl.d/99-performance-tuning.conf
else
    echo "⚠️  Persistent configuration file not found"
fi
EOF

chmod +x scripts/verify_tuning.sh
Step 2: Verify the applied tuning

# Verify tuning changes
./scripts/verify_tuning.sh
Task 4: Performance Testing and Documentation
Subtask 4.1: Post-Tuning Performance Test
Step 1: Create post-tuning performance test

cat > scripts/post_tuning_test.sh << 'EOF'
#!/bin/bash

echo "POST-TUNING PERFORMANCE TEST"
echo "============================"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEST_DIR="/opt/performance-review/post_tuning_${TIMESTAMP}"
mkdir -p "$TEST_DIR"

echo "Test directory: $TEST_DIR"
echo "Starting performance test..."

# Quick system snapshot
echo "System snapshot at $(date):" > "$TEST_DIR/system_snapshot.txt"
echo "Load average: $(uptime | awk -F'load average:' '{print $2}')" >> "$TEST_DIR/system_snapshot.txt"
echo "Memory usage: $(free -h | grep Mem)" >> "$TEST_DIR/system_snapshot.txt"
echo "CPU usage: $(top -bn1 | grep "Cpu(s)")" >> "$TEST_DIR/system_snapshot.txt"

# CPU performance test
echo "Running CPU performance test..."
time_output=$(time (for i in {1..5000}; do factor $i >/dev/null 2>&1; done) 2>&1)
echo "CPU test result: $time_output" > "$TEST_DIR/cpu_test.txt"

# Memory performance test
echo "Running memory performance test..."
dd if=/dev/zero of="$TEST_DIR/memory_test.tmp" bs=1M count=100 2>&1 | \
grep -E "(copied|MB/s)" > "$TEST_DIR/memory_test.txt"
rm -f "$TEST_DIR/memory_test.tmp"

# Disk I/O performance test
echo "Running disk I/O performance test..."
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

# Write test
write_result=$(dd if=/dev/zero of="$TEST_DIR/io_test.tmp" bs=1M count=50 2>&1 | \
grep -E "(copied|MB/s)")
echo "Write test: $write_result" > "$TEST_DIR/io_test.txt"

# Read test
sync
read_result=$(dd if="$TEST_DIR/io_test.tmp" of=/dev/null bs=1M 2>&1 | \
grep -E "(copied|MB/s)")
echo "Read test: $read_result" >> "$TEST_DIR/io_test.txt"

rm -f "$TEST_DIR/io_test.tmp"

# Network performance test (loopback)
echo "Running network performance test..."
timeout 10 iperf3 -s >/dev/null 2>&1 &
sleep 2
iperf3 -c localhost -t 5 2>/dev/null | grep "sender\|receiver" > "$TEST_DIR/network_test.txt" || \
echo "Network test skipped - iperf3 not available" > "$TEST_DIR/network_test.txt"

echo "Performance test completed. Results saved in: $TEST_DIR"

# Display summary
echo ""
echo "PERFORMANCE TEST SUMMARY:"
echo "========================"
cat "$TEST_DIR/system_snapshot.txt"
echo ""
echo "CPU Test:"
cat "$TEST_DIR/cpu_test.txt"
echo ""
echo "Memory Test:"
cat "$TEST_DIR/memory_test.txt"
echo ""
echo "I/O Test:"
cat "$TEST_DIR/io_test.txt"
echo ""
echo "Network Test:"
cat "$TEST_DIR/network_test.txt"
EOF

chmod +x scripts/post_tuning_test.sh
Step 2: Execute post-tuning performance test

# Run post-tuning performance test
./scripts/post_tuning_test.sh
Subtask 4.2: Compare Before and After Performance
Step 1: Create performance comparison script

cat > scripts/compare_performance.sh << 'EOF'
#!/bin/bash

echo "PERFORMANCE COMPARISON ANALYSIS"
echo "==============================="

# Find baseline and post-tuning directories
BASELINE_DIR=$(ls -1t /opt/performance-review/monitoring/ | tail -1)
POST_TUNING_DIR=$(ls -1t /opt/performance-review/ | grep "post_tuning" | head -1)

if [ -z "$BASELINE_DIR" ] || [ -z "$POST_TUNING_DIR" ]; then
    echo "Error: Could not find baseline or post-tuning data"
    echo "Baseline: $BASELINE_DIR"
    echo "Post-tuning: $POST_TUNING_DIR"
    exit 1
fi

echo "Comparing:"
echo "Baseline: /opt/performance-review/monitoring/$BASELINE_DIR"
echo "Post-tuning: /opt/performance-review/$POST_TUNING_DIR"
echo ""

# Create comparison report
COMPARISON_REPORT="/opt/performance-review/reports/performance_comparison_$(date +%Y%m%d_%H%M%S).txt"

cat > "$COMPARISON_REPORT" << REPORT_EOF
PERFORMANCE COMPARISON REPORT
============================
Generated: $(date)

BASELINE DATA (Before Tuning):
-----------------------------
REPORT_EOF

# Extract baseline metrics if available
if [ -f "/opt/performance-review/monitoring/$BASELINE_DIR/memory_tracking.txt" ]; then
    baseline_mem=$(tail -1 "/opt/performance-review/monitoring/$BASELINE_DIR/memory_tracking.txt" | \
    awk '{printf "%.1f", ($3/$2)*100}')
    echo "Memory Usage: ${baseline_mem}%" >> "$COMPARISON_REPORT"
fi

if [ -f "/opt/performance-review/monitoring/$BASELINE_DIR/top_output.txt" ]; then
    baseline_cpu=$(grep "Cpu(s)" "/opt/performance-review/monitoring/$BASELINE_DIR/top_output.txt" | \
    head -1 | awk '{print $2}' | sed 's/%us,//')
    echo "CPU Usage: ${baseline_cpu}%" >> "$COMPARISON_REPORT"
fi

cat >> "$COMPARISON_REPORT" << REPORT_EOF

POST-
