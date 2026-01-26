Lab 20: Comprehensive Performance Tuning Review
Objectives
By the end of this lab, students will be able to:

Analyze and interpret performance data collected from multiple system monitoring tools
Identify performance bottlenecks using comprehensive data analysis techniques
Implement targeted performance optimizations based on collected metrics
Validate performance improvements through systematic testing
Create a performance tuning report with actionable recommendations
Develop skills essential for the Red Hat Certified Specialist in Performance Tuning exam
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface operations
Knowledge of system performance concepts (CPU, memory, disk I/O, network)
Experience with performance monitoring tools: top, sar, iostat, and perf
Understanding of system processes and resource utilization
Basic scripting knowledge (bash)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
All performance monitoring tools pre-installed
Sample workloads and test applications
Historical performance data from previous lab sessions
Task 1: Comprehensive Data Collection and Review
Subtask 1.1: Gather Historical Performance Data
First, we'll collect and organize all performance data from previous monitoring sessions.

Create a dedicated workspace for performance analysis:
mkdir -p /opt/performance-review
cd /opt/performance-review
mkdir -p {cpu-data,memory-data,disk-data,network-data,reports}
Collect existing sar data:
# Copy recent sar data files
cp /var/log/sa/sa* ./cpu-data/
ls -la cpu-data/
Generate comprehensive sar reports for the last 7 days:
# CPU utilization report
sar -u -f /var/log/sa/sa$(date -d "1 day ago" +%d) > cpu-data/cpu-utilization-yesterday.txt

# Memory utilization report
sar -r -f /var/log/sa/sa$(date -d "1 day ago" +%d) > memory-data/memory-utilization-yesterday.txt

# Disk I/O report
sar -d -f /var/log/sa/sa$(date -d "1 day ago" +%d) > disk-data/disk-io-yesterday.txt

# Network statistics
sar -n DEV -f /var/log/sa/sa$(date -d "1 day ago" +%d) > network-data/network-stats-yesterday.txt
Subtask 1.2: Create Real-Time Performance Baseline
Start comprehensive system monitoring:
# Create a monitoring script
cat > monitor-system.sh << 'EOF'
#!/bin/bash

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGDIR="/opt/performance-review"

echo "Starting comprehensive system monitoring at $(date)"

# CPU monitoring with top
top -b -n 5 -d 2 > ${LOGDIR}/cpu-data/top-baseline-${TIMESTAMP}.txt &

# Memory and CPU with sar (5-minute intervals, 12 samples = 1 hour)
sar -u -r 300 12 > ${LOGDIR}/cpu-data/sar-cpu-memory-${TIMESTAMP}.txt &

# Disk I/O monitoring
iostat -x 300 12 > ${LOGDIR}/disk-data/iostat-baseline-${TIMESTAMP}.txt &

# Network monitoring
sar -n DEV 300 12 > ${LOGDIR}/network-data/sar-network-${TIMESTAMP}.txt &

echo "Monitoring started. Data will be collected for 1 hour."
echo "Log files created with timestamp: ${TIMESTAMP}"
EOF

chmod +x monitor-system.sh
./monitor-system.sh
Generate system load to analyze:
# Create a test workload script
cat > generate-load.sh << 'EOF'
#!/bin/bash

echo "Generating CPU load..."
# CPU intensive task
stress-ng --cpu 2 --timeout 300s &

echo "Generating memory load..."
# Memory intensive task
stress-ng --vm 1 --vm-bytes 512M --timeout 300s &

echo "Generating disk I/O load..."
# Disk I/O intensive task
dd if=/dev/zero of=/tmp/testfile bs=1M count=1000 &

echo "Load generation started. Will run for 5 minutes."
wait
echo "Load generation completed."
EOF

chmod +x generate-load.sh
Subtask 1.3: Collect Detailed Process Performance Data
Use perf to collect detailed performance data:
# Record system-wide performance for 60 seconds
perf record -g -a sleep 60

# Generate performance report
perf report --stdio > cpu-data/perf-report-$(date +%Y%m%d_%H%M%S).txt

# Collect CPU performance counters
perf stat -a -d sleep 30 2> cpu-data/perf-stat-$(date +%Y%m%d_%H%M%S).txt
Analyze process-specific performance:
# Find top CPU consuming processes
ps aux --sort=-%cpu | head -20 > cpu-data/top-cpu-processes.txt

# Find top memory consuming processes
ps aux --sort=-%mem | head -20 > memory-data/top-memory-processes.txt

# Check for zombie or defunct processes
ps aux | grep -E "(zombie|defunct)" > reports/problematic-processes.txt
Task 2: Performance Data Analysis and Bottleneck Identification
Subtask 2.1: CPU Performance Analysis
Create CPU analysis script:
cat > analyze-cpu.sh << 'EOF'
#!/bin/bash

REPORT_FILE="reports/cpu-analysis-$(date +%Y%m%d_%H%M%S).txt"

echo "=== CPU Performance Analysis Report ===" > $REPORT_FILE
echo "Generated on: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "1. Current CPU Information:" >> $REPORT_FILE
lscpu >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "2. Current Load Average:" >> $REPORT_FILE
uptime >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "3. CPU Utilization Summary (last 24 hours):" >> $REPORT_FILE
sar -u | tail -20 >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "4. Top CPU Consuming Processes:" >> $REPORT_FILE
cat cpu-data/top-cpu-processes.txt >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "5. CPU Performance Recommendations:" >> $REPORT_FILE
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
CPU_CORES=$(nproc)

if (( $(echo "$LOAD_AVG > $CPU_CORES" | bc -l) )); then
    echo "- HIGH LOAD DETECTED: Load average ($LOAD_AVG) exceeds CPU cores ($CPU_CORES)" >> $REPORT_FILE
    echo "- Consider process optimization or hardware upgrade" >> $REPORT_FILE
else
    echo "- CPU load is within acceptable range" >> $REPORT_FILE
fi

echo "CPU analysis completed. Report saved to: $REPORT_FILE"
EOF

chmod +x analyze-cpu.sh
./analyze-cpu.sh
Subtask 2.2: Memory Performance Analysis
Create memory analysis script:
cat > analyze-memory.sh << 'EOF'
#!/bin/bash

REPORT_FILE="reports/memory-analysis-$(date +%Y%m%d_%H%M%S).txt"

echo "=== Memory Performance Analysis Report ===" > $REPORT_FILE
echo "Generated on: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "1. Current Memory Usage:" >> $REPORT_FILE
free -h >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "2. Memory Utilization Trend:" >> $REPORT_FILE
sar -r | tail -10 >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "3. Swap Usage:" >> $REPORT_FILE
swapon --show >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "4. Top Memory Consuming Processes:" >> $REPORT_FILE
cat memory-data/top-memory-processes.txt >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "5. Memory Performance Analysis:" >> $REPORT_FILE
TOTAL_MEM=$(free | grep Mem | awk '{print $2}')
USED_MEM=$(free | grep Mem | awk '{print $3}')
MEM_USAGE_PERCENT=$(echo "scale=2; $USED_MEM * 100 / $TOTAL_MEM" | bc)

echo "Memory Usage: ${MEM_USAGE_PERCENT}%" >> $REPORT_FILE

if (( $(echo "$MEM_USAGE_PERCENT > 80" | bc -l) )); then
    echo "- WARNING: High memory usage detected (${MEM_USAGE_PERCENT}%)" >> $REPORT_FILE
    echo "- Consider memory optimization or upgrade" >> $REPORT_FILE
elif (( $(echo "$MEM_USAGE_PERCENT > 90" | bc -l) )); then
    echo "- CRITICAL: Very high memory usage (${MEM_USAGE_PERCENT}%)" >> $REPORT_FILE
    echo "- Immediate action required" >> $REPORT_FILE
else
    echo "- Memory usage is within acceptable range" >> $REPORT_FILE
fi

echo "Memory analysis completed. Report saved to: $REPORT_FILE"
EOF

chmod +x analyze-memory.sh
./analyze-memory.sh
Subtask 2.3: Disk I/O Performance Analysis
Create disk I/O analysis script:
cat > analyze-disk.sh << 'EOF'
#!/bin/bash

REPORT_FILE="reports/disk-analysis-$(date +%Y%m%d_%H%M%S).txt"

echo "=== Disk I/O Performance Analysis Report ===" > $REPORT_FILE
echo "Generated on: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "1. Current Disk Usage:" >> $REPORT_FILE
df -h >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "2. Disk I/O Statistics:" >> $REPORT_FILE
iostat -x 1 3 >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "3. Recent Disk Activity:" >> $REPORT_FILE
sar -d | tail -10 >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "4. Disk Performance Analysis:" >> $REPORT_FILE

# Check disk utilization
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo "Root filesystem usage: ${DISK_USAGE}%" >> $REPORT_FILE

if [ $DISK_USAGE -gt 90 ]; then
    echo "- CRITICAL: Disk usage is very high (${DISK_USAGE}%)" >> $REPORT_FILE
    echo "- Immediate cleanup required" >> $REPORT_FILE
elif [ $DISK_USAGE -gt 80 ]; then
    echo "- WARNING: Disk usage is high (${DISK_USAGE}%)" >> $REPORT_FILE
    echo "- Consider cleanup or expansion" >> $REPORT_FILE
else
    echo "- Disk usage is within acceptable range" >> $REPORT_FILE
fi

echo "" >> $REPORT_FILE
echo "5. I/O Wait Analysis:" >> $REPORT_FILE
IOWAIT=$(sar -u 1 3 | grep Average | awk '{print $6}')
echo "Average I/O Wait: ${IOWAIT}%" >> $REPORT_FILE

echo "Disk analysis completed. Report saved to: $REPORT_FILE"
EOF

chmod +x analyze-disk.sh
./analyze-disk.sh
Task 3: Performance Optimization Implementation
Subtask 3.1: CPU Optimization
Implement CPU performance optimizations:
cat > optimize-cpu.sh << 'EOF'
#!/bin/bash

echo "=== CPU Performance Optimization ==="

# Check current CPU governor
echo "Current CPU governor:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Set performance governor for better performance
echo "Setting CPU governor to performance mode..."
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance > $cpu 2>/dev/null || echo "Could not set governor for $cpu"
done

# Optimize process priorities for critical services
echo "Optimizing process priorities..."
# Find and renice CPU-intensive processes
for pid in $(ps aux --sort=-%cpu | head -10 | awk 'NR>1 {print $2}'); do
    current_nice=$(ps -o pid,ni -p $pid | tail -1 | awk '{print $2}')
    if [ "$current_nice" -gt 0 ]; then
        renice -5 $pid 2>/dev/null && echo "Reniced process $pid"
    fi
done

# Disable unnecessary services
echo "Checking for unnecessary services..."
systemctl list-unit-files --type=service --state=enabled | grep -E "(bluetooth|cups)" | while read service; do
    service_name=$(echo $service | awk '{print $1}')
    echo "Consider disabling: $service_name"
done

echo "CPU optimization completed."
EOF

chmod +x optimize-cpu.sh
./optimize-cpu.sh
Subtask 3.2: Memory Optimization
Implement memory performance optimizations:
cat > optimize-memory.sh << 'EOF'
#!/bin/bash

echo "=== Memory Performance Optimization ==="

# Clear system caches
echo "Clearing system caches..."
sync
echo 3 > /proc/sys/vm/drop_caches
echo "System caches cleared."

# Optimize swap usage
echo "Current swappiness value:"
cat /proc/sys/vm/swappiness

echo "Setting optimal swappiness value..."
echo 10 > /proc/sys/vm/swappiness
echo "vm.swappiness = 10" >> /etc/sysctl.conf

# Configure memory overcommit
echo "Configuring memory overcommit..."
echo 1 > /proc/sys/vm/overcommit_memory
echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf

# Find and optimize memory-hungry processes
echo "Analyzing memory usage by processes..."
ps aux --sort=-%mem | head -10 | while read line; do
    if echo "$line" | grep -v "PID"; then
        pid=$(echo "$line" | awk '{print $2}')
        mem_percent=$(echo "$line" | awk '{print $4}')
        command=$(echo "$line" | awk '{print $11}')
        
        if (( $(echo "$mem_percent > 10" | bc -l) )); then
            echo "High memory usage detected: PID $pid ($command) using ${mem_percent}% memory"
        fi
    fi
done

echo "Memory optimization completed."
EOF

chmod +x optimize-memory.sh
./optimize-memory.sh
Subtask 3.3: Disk I/O Optimization
Implement disk I/O optimizations:
cat > optimize-disk.sh << 'EOF'
#!/bin/bash

echo "=== Disk I/O Performance Optimization ==="

# Optimize I/O scheduler
echo "Current I/O schedulers:"
for disk in /sys/block/*/queue/scheduler; do
    echo "$disk: $(cat $disk)"
done

echo "Setting optimal I/O scheduler..."
for disk in /sys/block/sd*/queue/scheduler; do
    echo mq-deadline > $disk 2>/dev/null && echo "Set mq-deadline for $disk"
done

# Optimize filesystem mount options
echo "Checking current mount options..."
mount | grep -E "(ext4|xfs)" | head -5

# Clean up temporary files
echo "Cleaning up temporary files..."
find /tmp -type f -atime +7 -delete 2>/dev/null
find /var/tmp -type f -atime +7 -delete 2>/dev/null

# Optimize log rotation
echo "Configuring log rotation..."
cat > /etc/logrotate.d/performance-optimization << 'LOGROTATE_EOF'
/var/log/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
LOGROTATE_EOF

# Check for large files consuming disk space
echo "Finding large files (>100MB)..."
find / -type f -size +100M 2>/dev/null | head -10

echo "Disk I/O optimization completed."
EOF

chmod +x optimize-disk.sh
./optimize-disk.sh
Subtask 3.4: System-Wide Optimization
Apply comprehensive system optimizations:
cat > optimize-system.sh << 'EOF'
#!/bin/bash

echo "=== Comprehensive System Optimization ==="

# Create optimized sysctl configuration
cat > /etc/sysctl.d/99-performance-tuning.conf << 'SYSCTL_EOF'
# Network optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Memory optimizations
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.swappiness = 10

# File system optimizations
fs.file-max = 2097152
SYSCTL_EOF

# Apply sysctl changes
sysctl -p /etc/sysctl.d/99-performance-tuning.conf

# Optimize systemd services
echo "Optimizing systemd configuration..."
mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/performance.conf << 'SYSTEMD_EOF'
[Manager]
DefaultTimeoutStopSec=30s
DefaultTimeoutStartSec=30s
SYSTEMD_EOF

# Update system limits
echo "Updating system limits..."
cat >> /etc/security/limits.conf << 'LIMITS_EOF'
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
LIMITS_EOF

echo "System-wide optimization completed."
echo "Note: Some changes require a system reboot to take effect."
EOF

chmod +x optimize-system.sh
./optimize-system.sh
Task 4: Performance Testing and Validation
Subtask 4.1: Pre and Post-Optimization Comparison
Create performance testing framework:
cat > performance-test.sh << 'EOF'
#!/bin/bash

TEST_DURATION=300  # 5 minutes
RESULTS_DIR="/opt/performance-review/test-results"
mkdir -p $RESULTS_DIR

echo "=== Performance Testing Framework ==="
echo "Test duration: ${TEST_DURATION} seconds"

# Function to run performance test
run_performance_test() {
    local test_name=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo "Starting $test_name test at $(date)"
    
    # Start monitoring
    sar -u -r 5 $((TEST_DURATION/5)) > ${RESULTS_DIR}/${test_name}-sar-${timestamp}.txt &
    iostat -x 5 $((TEST_DURATION/5)) > ${RESULTS_DIR}/${test_name}-iostat-${timestamp}.txt &
    
    # CPU stress test
    stress-ng --cpu $(nproc) --timeout ${TEST_DURATION}s &
    
    # Memory stress test
    stress-ng --vm 2 --vm-bytes 256M --timeout ${TEST_DURATION}s &
    
    # I/O stress test
    stress-ng --hdd 1 --hdd-bytes 1G --timeout ${TEST_DURATION}s &
    
    # Wait for tests to complete
    wait
    
    echo "$test_name test completed at $(date)"
}

# Run baseline test
echo "Running baseline performance test..."
run_performance_test "baseline"

echo "Performance testing completed."
echo "Results saved in: $RESULTS_DIR"
EOF

chmod +x performance-test.sh
Execute performance tests:
# Run the performance test
./performance-test.sh

# Wait for completion and analyze results
sleep 10
Subtask 4.2: Generate Performance Comparison Report
Create comprehensive comparison report:
cat > generate-final-report.sh << 'EOF'
#!/bin/bash

FINAL_REPORT="reports/final-performance-report-$(date +%Y%m%d_%H%M%S).txt"

echo "=== COMPREHENSIVE PERFORMANCE TUNING REPORT ===" > $FINAL_REPORT
echo "Generated on: $(date)" >> $FINAL_REPORT
echo "System: $(hostname)" >> $FINAL_REPORT
echo "Kernel: $(uname -r)" >> $FINAL_REPORT
echo "" >> $FINAL_REPORT

echo "1. SYSTEM SPECIFICATIONS:" >> $FINAL_REPORT
echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)" >> $FINAL_REPORT
echo "Memory: $(free -h | grep Mem | awk '{print $2}')" >> $FINAL_REPORT
echo "Storage: $(df -h / | tail -1 | awk '{print $2}')" >> $FINAL_REPORT
echo "" >> $FINAL_REPORT

echo "2. PERFORMANCE ANALYSIS SUMMARY:" >> $FINAL_REPORT
echo "" >> $FINAL_REPORT

# CPU Analysis Summary
echo "CPU Performance:" >> $FINAL_REPORT
CURRENT_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
echo "- Current Load Average: $CURRENT_LOAD" >> $FINAL_REPORT
echo "- CPU Cores: $(nproc)" >> $FINAL_REPORT
echo "- CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')" >> $FINAL_REPORT
echo "" >> $FINAL_REPORT

# Memory Analysis Summary
echo "Memory Performance:" >> $FINAL_REPORT
TOTAL_MEM=$(free | grep Mem | awk '{print $2}')
USED_MEM=$(free | grep Mem | awk '{print $3}')
MEM_USAGE_PERCENT=$(echo "scale=2; $USED_MEM * 100 / $TOTAL_MEM" | bc)
echo "- Memory Usage: ${MEM_USAGE_PERCENT}%" >> $FINAL_REPORT
echo "- Swappiness: $(cat /proc/sys/vm/swappiness)" >> $FINAL_REPORT
echo "- Available Memory: $(free -h | grep Mem | awk '{print $7}')" >> $FINAL_REPORT
echo "" >> $FINAL_REPORT

# Disk Analysis Summary
echo "Disk Performance:" >> $FINAL_REPORT
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo "- Root Filesystem Usage: ${DISK_USAGE}%" >> $FINAL_REPORT
echo "- I/O Scheduler: $(cat /sys/block/sda/queue/scheduler 2>/dev/null | grep -o '\[.*\]' | tr -d '[]' || echo 'N/A')" >> $FINAL_REPORT
echo "" >> $FINAL_REPORT

echo "3. OPTIMIZATIONS IMPLEMENTED:" >> $FINAL_REPORT
echo "- CPU governor set to performance mode" >> $FINAL_REPORT
echo "- Memory swappiness optimized to 10" >> $FINAL_REPORT
echo "- I/O scheduler optimized to mq-deadline" >> $FINAL_REPORT
echo "- System limits increased for better performance" >> $FINAL_REPORT
echo "- Network parameters tuned for better throughput" >> $FINAL_REPORT
echo "- Temporary files cleaned up" >> $FINAL_REPORT
echo "" >> $FINAL_REPORT

echo "4. RECOMMENDATIONS:" >> $FINAL_REPORT
echo "- Monitor system performance regularly using sar and iostat" >> $FINAL_REPORT
echo "- Set up automated performance monitoring with cron jobs" >> $FINAL_REPORT
echo "- Review and update performance settings quarterly" >> $FINAL_REPORT
echo "- Consider hardware upgrades if bottlenecks persist" >> $FINAL_REPORT
echo "- Implement application-level optimizations where needed" >> $FINAL_REPORT
echo "" >> $FINAL_REPORT

echo "5. MONITORING COMMANDS FOR ONGOING MAINTENANCE:" >> $FINAL_REPORT
echo "- CPU monitoring: sar -u 5 12" >> $FINAL_REPORT
echo "- Memory monitoring: sar -r 5 12" >> $FINAL_REPORT
echo "- Disk I/O monitoring: iostat -x 5 12" >> $FINAL_REPORT
echo "- Process monitoring: top -b -n 1" >> $FINAL_REPORT
echo "- Network monitoring: sar -n DEV 5 12" >> $FINAL_REPORT
echo "" >> $FINAL_REPORT

echo "Report generation completed."
echo "Final report saved to: $FINAL_REPORT"

# Display report summary
echo ""
echo "=== REPORT SUMMARY ==="
cat $FINAL_REPORT
EOF

chmod +x generate-final-report.sh
./generate-final-report.sh
Subtask 4.3: Create Ongoing Monitoring Setup
Set up automated performance monitoring:
cat > setup-monitoring.sh << 'EOF'
#!/bin/bash

echo "=== Setting up Ongoing Performance Monitoring ==="

# Create monitoring directory
mkdir -p /opt/performance-monitoring
cd /opt/performance-monitoring

# Create daily monitoring script
cat > daily-monitor.sh << 'DAILY_EOF'
#!/bin/bash

DATE=$(date +%Y%m%d)
LOGDIR="/opt/performance-monitoring/logs"
mkdir -p $LOGDIR

# Daily system performance snapshot
{
    echo "=== Daily Performance Report - $(date) ==="
    echo ""
    echo "System Load:"
    uptime
    echo ""
    echo "Memory Usage:"
    free -h
    echo ""
    echo "Disk Usage:"
    df -h
    echo ""
    echo "Top CPU Processes:"
    ps aux --sort=-%cpu | head -10
    echo ""
    echo "Top Memory Processes:"
    ps aux --sort=-%mem | head -10
    echo ""
} > ${LOGDIR}/daily-report-${DATE}.txt

# Collect sar data
sar -A > ${LOGDIR}/sar-all-${DATE}.txt
DAILY_EOF

chmod +x daily-monitor.sh

# Create weekly monitoring script
cat > weekly-monitor.sh << 'WEEKLY_EOF'
#!/bin/bash

WEEK=$(date +%Y%U)
LOGDIR="/opt/performance-monitoring/logs"
REPORTDIR="/opt/performance-monitoring/reports"
mkdir -p $REPORTDIR

# Generate weekly performance summary
{
    echo "=== Weekly Performance Summary - Week $WEEK ==="
    echo ""
    echo "Average System Load (last 7 days):"
    sar -q -f /var/log/sa/sa* | grep Average
    echo ""
    echo "Average Memory Usage (last 7 days):"
    sar -r -f /var/log/sa/sa* | grep Average
    echo ""
    echo "Average Disk I/O (last 7 days):"
    sar -d -f /var/log/sa/sa* | grep Average
    echo ""
} > ${REPORTDIR}/weekly-summary-${WEEK}.txt
WEEKLY_EOF

chmod +x weekly-monitor.sh

# Set up cron jobs
echo "Setting up cron jobs for automated monitoring..."
(crontab -l 2>/dev/null; echo "0 6 * * * /opt/performance-monitoring/daily-monitor.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 7 * * 1 /opt/performance-monitoring/weekly-monitor.sh") | crontab -

echo "Automated monitoring setup completed."
echo "Daily reports will be generated at 6:00 AM"
echo "Weekly summaries will be generated at 7:00 AM on Mondays"
EOF

chmod +x setup-monitoring.sh
./setup-monitoring.sh
Troubleshooting Tips
Common Issues and Solutions
Permission Denied Errors:

Ensure you're running scripts with appropriate privileges
Use sudo for system-level modifications
Check file permissions with ls -la
Missing Commands:

Install missing tools: yum install sysstat stress-ng bc -y
Verify tool availability: which command_name
High System Load During Testing:

Reduce stress test intensity
Monitor system resources during tests
Stop tests if system becomes unresponsive: killall stress-ng
Insufficient Disk Space:

Clean up temporary files: rm -rf /tmp/testfile*
Check disk usage: df -h
Remove old log files if necessary
Performance Data Collection Issues:

Ensure sar is properly configured: systemctl enable sysstat
Check if performance counters are available: perf list
Verify log file permissions
Conclusion
In this comprehensive performance tuning lab, you have successfully:

Collected and analyzed performance data from multiple monitoring tools including top, sar, iostat, and perf
Identified performance bottlenecks through systematic analysis of CPU, memory, disk I/O, and network metrics
Implemented targeted optimizations including CPU governor tuning, memory management improvements, and I/O scheduler optimization
Validated performance improvements through before-and-after testing and comparison
Created comprehensive reports documenting findings and recommendations
Established ongoing monitoring procedures for continuous performance management
This lab demonstrates the complete performance tuning workflow essential for system administrators and aligns with the skills required for the Red Hat Certified Specialist in Performance Tuning exam. The methodical approach of data collection, analysis, optimization, and validation provides a solid foundation for real-world performance tuning scenarios.

Key Takeaways:

Performance tuning is an iterative process requiring continuous monitoring
Multiple tools provide different perspectives on system performance
Systematic analysis leads to more effective optimizations
Documentation and reporting are crucial for tracking improvements
Automated monitoring ensures ongoing performance management
The skills developed in this lab will enable you to effectively diagnose and resolve performance issues in production Linux environments, making you a more valuable system administrator and preparing you for advanced certification exams.
