Lab 7: Performance Analysis with sar
Objectives
By the end of this lab, students will be able to:

Install and configure the sar (System Activity Reporter) tool for continuous system monitoring
Set up automated data collection for historical performance analysis
Analyze CPU utilization patterns and identify performance bottlenecks
Examine memory usage trends and detect memory-related issues
Monitor disk I/O performance and storage subsystem behavior
Generate comprehensive performance reports from historical data
Interpret sar output to make informed system optimization decisions
Create custom monitoring scripts for specific performance scenarios
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command-line interface
Familiarity with system administration concepts
Knowledge of CPU, memory, and disk fundamentals
Understanding of performance monitoring principles
Experience with text editors like vi or nano
Basic scripting knowledge (bash)
Lab Environment
Al Nafi provides Linux-based cloud machines - simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Pre-installed sysstat package (contains sar)
Root access for system configuration
Sample workload generators for testing
Task 1: Set Up sar to Collect System Activity Data Over Time
Subtask 1.1: Verify and Install sysstat Package
First, let's ensure the sysstat package is installed and check the current version.

# Check if sysstat is installed
rpm -qa | grep sysstat

# If not installed on RHEL/CentOS
sudo yum install -y sysstat

# For Ubuntu systems
sudo apt update
sudo apt install -y sysstat
Verify the installation and check available tools:

# Check sar version
sar -V

# List all sysstat utilities
ls -la /usr/bin/sa*
Subtask 1.2: Configure Data Collection Service
Enable and configure the sadc (System Activity Data Collector) service:

# Enable sysstat service
sudo systemctl enable sysstat
sudo systemctl start sysstat

# Check service status
sudo systemctl status sysstat
Configure the data collection interval by editing the cron job:

# View current cron configuration
sudo cat /etc/cron.d/sysstat

# Edit the configuration file
sudo nano /etc/cron.d/sysstat
Modify the file to collect data every 2 minutes (default is 10 minutes):

# Activity reports every 2 minutes Monday to Sunday
*/2 * * * * root /usr/lib64/sa/sa1 1 1

# Daily summary at 23:53
53 23 * * * root /usr/lib64/sa/sa2 -A
Subtask 1.3: Verify Data Collection Setup
Check that data collection is working properly:

# Check if data files are being created
ls -la /var/log/sa/

# View current day's data file
ls -la /var/log/sa/sa$(date +%d)

# Force immediate data collection
sudo /usr/lib64/sa/sa1 1 1

# Verify data was collected
sar -u 1 1
Subtask 1.4: Create Custom Collection Script
Create a script for enhanced data collection during specific periods:

# Create monitoring script
sudo nano /usr/local/bin/enhanced_sar_collection.sh
Add the following content:

#!/bin/bash
# Enhanced SAR Data Collection Script

LOG_DIR="/var/log/sa"
DATE=$(date +%Y%m%d)
TIME=$(date +%H%M%S)

# Collect comprehensive system data
echo "Starting enhanced data collection at $(date)"

# CPU data every 30 seconds for 10 minutes
sar -u 30 20 > ${LOG_DIR}/cpu_detailed_${DATE}_${TIME}.log &

# Memory data every 30 seconds for 10 minutes  
sar -r 30 20 > ${LOG_DIR}/memory_detailed_${DATE}_${TIME}.log &

# Disk I/O data every 30 seconds for 10 minutes
sar -d 30 20 > ${LOG_DIR}/disk_detailed_${DATE}_${TIME}.log &

# Network data every 30 seconds for 10 minutes
sar -n DEV 30 20 > ${LOG_DIR}/network_detailed_${DATE}_${TIME}.log &

echo "Enhanced collection started. Data will be saved to ${LOG_DIR}"
Make the script executable:

sudo chmod +x /usr/local/bin/enhanced_sar_collection.sh
Task 2: Analyze CPU Performance Metrics from Historical Data
Subtask 2.1: Generate CPU Load for Testing
Create a CPU-intensive workload to generate meaningful data:

# Create CPU stress script
nano cpu_stress_test.sh
Add the following content:

#!/bin/bash
# CPU Stress Test Script

echo "Starting CPU stress test..."

# Function to create CPU load
cpu_load() {
    local duration=$1
    local cores=$2
    
    for ((i=1; i<=cores; i++)); do
        yes > /dev/null &
    done
    
    sleep $duration
    killall yes
}

# Light load - 2 cores for 2 minutes
echo "Phase 1: Light CPU load"
cpu_load 120 2

sleep 30

# Heavy load - 4 cores for 3 minutes
echo "Phase 2: Heavy CPU load"  
cpu_load 180 4

sleep 30

# Variable load pattern
echo "Phase 3: Variable load pattern"
for i in {1..5}; do
    cpu_load 30 $i
    sleep 15
done

echo "CPU stress test completed"
Make executable and run:

chmod +x cpu_stress_test.sh
./cpu_stress_test.sh &
Subtask 2.2: Collect Real-time CPU Data
While the stress test runs, collect CPU performance data:

# Real-time CPU utilization (every 5 seconds for 20 intervals)
sar -u 5 20

# CPU utilization with individual core breakdown
sar -P ALL 5 10

# Collect data to file for later analysis
sar -u 2 300 > cpu_performance_$(date +%Y%m%d_%H%M).log &
Subtask 2.3: Analyze Historical CPU Data
Analyze CPU performance from collected data:

# View CPU data from today's file
sar -u -f /var/log/sa/sa$(date +%d)

# Show CPU data for specific time range (last 2 hours)
sar -u -s $(date -d '2 hours ago' +%H:%M:%S) -f /var/log/sa/sa$(date +%d)

# Generate CPU summary report
sar -u -f /var/log/sa/sa$(date +%d) | tail -20
Create a CPU analysis script:

nano analyze_cpu_performance.sh
Add the following content:

#!/bin/bash
# CPU Performance Analysis Script

DATA_FILE="/var/log/sa/sa$(date +%d)"
REPORT_FILE="cpu_analysis_report_$(date +%Y%m%d).txt"

echo "CPU Performance Analysis Report" > $REPORT_FILE
echo "Generated on: $(date)" >> $REPORT_FILE
echo "=================================" >> $REPORT_FILE

# Overall CPU utilization
echo -e "\n1. Overall CPU Utilization:" >> $REPORT_FILE
sar -u -f $DATA_FILE | grep -E "(Average|%user|%nice|%system|%iowait|%steal|%idle)" >> $REPORT_FILE

# Peak CPU usage periods
echo -e "\n2. Peak CPU Usage Periods (>80% utilization):" >> $REPORT_FILE
sar -u -f $DATA_FILE | awk '$3 != "%user" && ($3+$5) > 80 {print $1, $2, "Total:", $3+$5"%"}' >> $REPORT_FILE

# I/O Wait analysis
echo -e "\n3. High I/O Wait Periods (>10%):" >> $REPORT_FILE
sar -u -f $DATA_FILE | awk '$6 != "%iowait" && $6 > 10 {print $1, $2, "I/O Wait:", $6"%"}' >> $REPORT_FILE

# CPU efficiency calculation
echo -e "\n4. CPU Efficiency Summary:" >> $REPORT_FILE
sar -u -f $DATA_FILE | awk '
BEGIN {total_samples=0; total_idle=0; total_user=0; total_system=0}
$3 != "%user" && NF > 6 {
    total_samples++; 
    total_idle+=$8; 
    total_user+=$3; 
    total_system+=$5
}
END {
    if(total_samples > 0) {
        avg_idle = total_idle/total_samples;
        avg_user = total_user/total_samples;
        avg_system = total_system/total_samples;
        efficiency = 100 - avg_idle;
        print "Average CPU Utilization:", efficiency"%";
        print "User processes:", avg_user"%";
        print "System processes:", avg_system"%";
        print "Idle time:", avg_idle"%"
    }
}' >> $REPORT_FILE

echo "CPU analysis complete. Report saved to: $REPORT_FILE"
cat $REPORT_FILE
Make executable and run:

chmod +x analyze_cpu_performance.sh
./analyze_cpu_performance.sh
Task 3: Analyze Memory Performance Metrics
Subtask 3.1: Generate Memory Load for Testing
Create a memory-intensive workload:

nano memory_stress_test.sh
Add the following content:

#!/bin/bash
# Memory Stress Test Script

echo "Starting memory stress test..."

# Function to allocate memory
allocate_memory() {
    local size_mb=$1
    local duration=$2
    
    echo "Allocating ${size_mb}MB of memory for ${duration} seconds"
    
    # Use dd to create memory pressure
    dd if=/dev/zero of=/dev/null bs=1M count=$size_mb &
    local pid=$!
    
    sleep $duration
    kill $pid 2>/dev/null
}

# Phase 1: Gradual memory allocation
echo "Phase 1: Gradual memory increase"
for size in 100 200 400 800; do
    allocate_memory $size 60
    sleep 30
done

# Phase 2: Memory pressure simulation
echo "Phase 2: Memory pressure simulation"
# Create multiple processes consuming memory
for i in {1..5}; do
    dd if=/dev/zero of=/tmp/memtest_$i bs=1M count=200 &
done

sleep 180

# Cleanup
rm -f /tmp/memtest_*
killall dd 2>/dev/null

echo "Memory stress test completed"
Make executable and run:

chmod +x memory_stress_test.sh
./memory_stress_test.sh &
Subtask 3.2: Collect Memory Performance Data
Monitor memory usage during the stress test:

# Real-time memory statistics
sar -r 5 20

# Memory and swap usage
sar -S 5 10

# Page statistics (paging activity)
sar -B 5 15

# Collect detailed memory data to file
sar -r 2 600 > memory_performance_$(date +%Y%m%d_%H%M).log &
Subtask 3.3: Analyze Historical Memory Data
Create a comprehensive memory analysis script:

nano analyze_memory_performance.sh
Add the following content:

#!/bin/bash
# Memory Performance Analysis Script

DATA_FILE="/var/log/sa/sa$(date +%d)"
REPORT_FILE="memory_analysis_report_$(date +%Y%m%d).txt"

echo "Memory Performance Analysis Report" > $REPORT_FILE
echo "Generated on: $(date)" >> $REPORT_FILE
echo "===================================" >> $REPORT_FILE

# Memory utilization overview
echo -e "\n1. Memory Utilization Overview:" >> $REPORT_FILE
sar -r -f $DATA_FILE | grep -E "(Average|kbmemfree|kbmemused|%memused)" | tail -5 >> $REPORT_FILE

# High memory usage periods
echo -e "\n2. High Memory Usage Periods (>80%):" >> $REPORT_FILE
sar -r -f $DATA_FILE | awk '$4 != "%memused" && $4 > 80 {print $1, $2, "Memory Used:", $4"%", "Available:", $6"KB"}' >> $REPORT_FILE

# Swap usage analysis
echo -e "\n3. Swap Usage Analysis:" >> $REPORT_FILE
sar -S -f $DATA_FILE | grep -E "(Average|kbswpfree|kbswpused|%swpused)" | tail -5 >> $REPORT_FILE

# Memory pressure indicators
echo -e "\n4. Memory Pressure Indicators:" >> $REPORT_FILE
echo "Paging Activity:" >> $REPORT_FILE
sar -B -f $DATA_FILE | awk '$3 != "pgpgin/s" && ($3 > 100 || $4 > 100) {print $1, $2, "Pages in/s:", $3, "Pages out/s:", $4}' >> $REPORT_FILE

# Memory efficiency calculation
echo -e "\n5. Memory Efficiency Summary:" >> $REPORT_FILE
sar -r -f $DATA_FILE | awk '
BEGIN {samples=0; total_used=0; total_free=0; total_buffer=0; total_cache=0}
$4 != "%memused" && NF > 8 {
    samples++;
    total_used += $4;
    total_free += $2;
    total_buffer += $5;
    total_cache += $6;
}
END {
    if(samples > 0) {
        avg_used = total_used/samples;
        avg_free = total_free/samples;
        avg_buffer = total_buffer/samples;
        avg_cache = total_cache/samples;
        print "Average Memory Usage:", avg_used"%";
        print "Average Free Memory:", avg_free"KB";
        print "Average Buffer Usage:", avg_buffer"KB";
        print "Average Cache Usage:", avg_cache"KB";
    }
}' >> $REPORT_FILE

echo "Memory analysis complete. Report saved to: $REPORT_FILE"
cat $REPORT_FILE
Make executable and run:

chmod +x analyze_memory_performance.sh
./analyze_memory_performance.sh
Task 4: Analyze Disk Performance Metrics
Subtask 4.1: Generate Disk I/O Load for Testing
Create a disk-intensive workload:

nano disk_stress_test.sh
Add the following content:

#!/bin/bash
# Disk I/O Stress Test Script

TEST_DIR="/tmp/disk_test"
mkdir -p $TEST_DIR

echo "Starting disk I/O stress test..."

# Function for sequential write test
sequential_write_test() {
    local file_size=$1
    local block_size=$2
    
    echo "Sequential write test: ${file_size}MB with ${block_size} block size"
    dd if=/dev/zero of=${TEST_DIR}/seq_write_test bs=$block_size count=$((file_size*1024/block_size)) conv=fsync
}

# Function for random I/O test
random_io_test() {
    local duration=$1
    
    echo "Random I/O test for ${duration} seconds"
    timeout $duration dd if=/dev/urandom of=${TEST_DIR}/random_test bs=4k count=10000 oflag=direct &
    timeout $duration dd if=${TEST_DIR}/random_test of=/dev/null bs=4k iflag=direct &
    wait
}

# Phase 1: Sequential I/O patterns
echo "Phase 1: Sequential I/O tests"
sequential_write_test 100 1024
sequential_write_test 200 4096
sequential_write_test 500 8192

# Phase 2: Random I/O patterns
echo "Phase 2: Random I/O tests"
random_io_test 120
sleep 30
random_io_test 180

# Phase 3: Mixed workload
echo "Phase 3: Mixed I/O workload"
for i in {1..3}; do
    dd if=/dev/zero of=${TEST_DIR}/mixed_test_$i bs=1M count=100 &
    dd if=${TEST_DIR}/seq_write_test of=/dev/null bs=4k &
done
wait

# Cleanup
rm -rf $TEST_DIR
echo "Disk stress test completed"
Make executable and run:

chmod +x disk_stress_test.sh
./disk_stress_test.sh &
Subtask 4.2: Collect Disk Performance Data
Monitor disk I/O during the stress test:

# Real-time disk statistics for all devices
sar -d 5 20

# Detailed disk statistics with device names
sar -d -p 5 15

# Block device statistics
sar -b 5 10

# Collect detailed disk data to file
sar -d 2 600 > disk_performance_$(date +%Y%m%d_%H%M).log &
Subtask 4.3: Analyze Historical Disk Data
Create a comprehensive disk analysis script:

nano analyze_disk_performance.sh
Add the following content:

#!/bin/bash
# Disk Performance Analysis Script

DATA_FILE="/var/log/sa/sa$(date +%d)"
REPORT_FILE="disk_analysis_report_$(date +%Y%m%d).txt"

echo "Disk Performance Analysis Report" > $REPORT_FILE
echo "Generated on: $(date)" >> $REPORT_FILE
echo "==================================" >> $REPORT_FILE

# Disk utilization overview
echo -e "\n1. Disk Utilization Overview:" >> $REPORT_FILE
sar -d -f $DATA_FILE | grep -E "(Average|DEV|tps|rd_sec|wr_sec|%util)" | tail -10 >> $REPORT_FILE

# High disk utilization periods
echo -e "\n2. High Disk Utilization Periods (>70%):" >> $REPORT_FILE
sar -d -f $DATA_FILE | awk '$NF != "%util" && $NF > 70 {print $1, $2, "Device:", $3, "Utilization:", $NF"%", "TPS:", $4}' >> $REPORT_FILE

# I/O throughput analysis
echo -e "\n3. I/O Throughput Analysis:" >> $REPORT_FILE
echo "High Read Activity (>1000 sectors/s):" >> $REPORT_FILE
sar -d -f $DATA_FILE | awk '$6 != "rd_sec/s" && $6 > 1000 {print $1, $2, "Device:", $3, "Read:", $6"sec/s"}' >> $REPORT_FILE

echo -e "\nHigh Write Activity (>1000 sectors/s):" >> $REPORT_FILE
sar -d -f $DATA_FILE | awk '$7 != "wr_sec/s" && $7 > 1000 {print $1, $2, "Device:", $3, "Write:", $7"sec/s"}' >> $REPORT_FILE

# Block device statistics
echo -e "\n4. Block Device Statistics:" >> $REPORT_FILE
sar -b -f $DATA_FILE | grep -E "(Average|tps|rtps|wtps|bread|bwrtn)" | tail -5 >> $REPORT_FILE

# Disk performance summary
echo -e "\n5. Disk Performance Summary:" >> $REPORT_FILE
sar -d -f $DATA_FILE | awk '
BEGIN {samples=0; total_tps=0; total_read=0; total_write=0; total_util=0; devices=0}
$4 != "tps" && NF > 9 {
    samples++;
    total_tps += $4;
    total_read += $6;
    total_write += $7;
    total_util += $NF;
    if($3 != prev_device) {devices++; prev_device=$3}
}
END {
    if(samples > 0) {
        avg_tps = total_tps/samples;
        avg_read = total_read/samples;
        avg_write = total_write/samples;
        avg_util = total_util/samples;
        print "Number of devices monitored:", devices;
        print "Average TPS:", avg_tps;
        print "Average Read (sectors/s):", avg_read;
        print "Average Write (sectors/s):", avg_write;
        print "Average Utilization:", avg_util"%";
    }
}' >> $REPORT_FILE

# I/O wait correlation
echo -e "\n6. I/O Wait Correlation:" >> $REPORT_FILE
echo "Periods with high I/O wait and disk utilization:" >> $REPORT_FILE
join -1 2 -2 2 <(sar -u -f $DATA_FILE | awk '$6 > 5 {print $2, $6}' | sort) \
                <(sar -d -f $DATA_FILE | awk '$NF > 50 {print $2, $NF}' | sort) | \
head -10 >> $REPORT_FILE

echo "Disk analysis complete. Report saved to: $REPORT_FILE"
cat $REPORT_FILE
Make executable and run:

chmod +x analyze_disk_performance.sh
./analyze_disk_performance.sh
Task 5: Generate Comprehensive Performance Reports
Subtask 5.1: Create Master Performance Analysis Script
Create a comprehensive script that combines all performance metrics:

nano master_performance_analysis.sh
Add the following content:

#!/bin/bash
# Master Performance Analysis Script

# Configuration
DATA_FILE="/var/log/sa/sa$(date +%d)"
REPORT_DIR="/tmp/performance_reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MASTER_REPORT="${REPORT_DIR}/master_performance_report_${TIMESTAMP}.html"

# Create report directory
mkdir -p $REPORT_DIR

# HTML Report Generation
cat > $MASTER_REPORT << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>System Performance Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .section { margin: 20px 0; border: 1px solid #ddd; padding: 15px; border-radius: 5px; }
        .metric { background-color: #f9f9f9; padding: 5px; margin: 5px 0; }
        .warning { color: #ff6600; font-weight: bold; }
        .critical { color: #ff0000; font-weight: bold; }
        .good { color: #00aa00; font-weight: bold; }
        pre { background-color: #f5f5f5; padding: 10px; overflow-x: auto; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
EOF

# Add header information
cat >> $MASTER_REPORT << EOF
<div class="header">
    <h1>System Performance Analysis Report</h1>
    <p><strong>Generated:</strong> $(date)</p>
    <p><strong>Hostname:</strong> $(hostname)</p>
    <p><strong>Kernel:</strong> $(uname -r)</p>
    <p><strong>Uptime:</strong> $(uptime)</p>
</div>
EOF

# Function to add section to HTML report
add_section() {
    local title="$1"
    local content="$2"
    
    cat >> $MASTER_REPORT << EOF
<div class="section">
    <h2>$title</h2>
    <pre>$content</pre>
</div>
EOF
}

# System Overview
SYSTEM_INFO=$(cat << 'SYSINFO'
CPU Information:
$(lscpu | grep -E "(Model name|CPU\(s\)|Thread|Core)")

Memory Information:
$(free -h)

Disk Information:
$(df -h | grep -v tmpfs)

Network Interfaces:
$(ip addr show | grep -E "(inet |link/)")
SYSINFO
)

add_section "System Overview" "$SYSTEM_INFO"

# CPU Analysis
CPU_ANALYSIS=$(sar -u -f $DATA_FILE | awk '
BEGIN {
    print "CPU Performance Summary"
    print "======================"
    samples=0; total_user=0; total_system=0; total_idle=0; total_iowait=0;
    max_util=0; min_util=100;
}
$3 != "%user" && NF > 6 {
    samples++;
    user=$3; system=$5; idle=$8; iowait=$6;
    utilization = 100 - idle;
    total_user += user;
    total_system += system;
    total_idle += idle;
    total_iowait += iowait;
    if(utilization > max_util) max_util = utilization;
    if(utilization < min_util) min_util = utilization;
    if(utilization > 80) high_util_count++;
    if(iowait > 10) high_iowait_count++;
}
END {
    if(samples > 0) {
        avg_user = total_user/samples;
        avg_system = total_system/samples;
        avg_idle = total_idle/samples;
        avg_iowait = total_iowait/samples;
        avg_util = 100 - avg_idle;
        
        print "Average CPU Utilization: " avg_util "%";
        print "Peak CPU Utilization: " max_util "%";
        print "Minimum CPU Utilization: " min_util "%";
        print "Average User CPU: " avg_user "%";
        print "Average System CPU: " avg_system "%";
        print "Average I/O Wait: " avg_iowait "%";
        print "High Utilization Periods (>80%): " (high_util_count ? high_util_count : 0);
        print "High I/O Wait Periods (>10%): " (high_iowait_count ? high_iowait_count : 0);
        
        if(avg_util < 50) print "Status: CPU utilization is GOOD";
        else if(avg_util < 80) print "Status: CPU utilization is MODERATE";
        else print "Status: CPU utilization is HIGH - Investigation needed";
    }
}')

add_section "CPU Performance Analysis" "$CPU_ANALYSIS"

# Memory Analysis
MEMORY_ANALYSIS=$(sar -r -f $DATA_FILE | awk '
BEGIN {
    print "Memory Performance Summary"
    print "========================="
    samples=0; total_used=0; total_free=0; max_used=0;
}
$4 != "%memused" && NF > 6 {
    samples++;
    used_pct=$4;
    free_kb=$2;
    total_used += used_pct;
    total_free += free_kb;
    if(used_pct > max_used) max_used = used_pct;
    if(used_pct > 90) critical_count++;
    if(used_pct > 80) warning_count++;
}
END {
    if(samples > 0) {
        avg_used = total_used/samples;
        avg_free = total_free/samples;
        
        print "Average Memory Usage: " avg_used "%";
        print "Peak Memory Usage: " max_used "%";
        print "Average Free Memory: " avg_free " KB";
        print "Critical Usage Periods (>90%): " (critical_count ? critical_count : 0);
        print "Warning Usage Periods (>80%): " (warning_count ? warning_count : 0);
        
        if(avg_used < 70) print "Status: Memory usage is GOOD";
        else if(avg_used < 85) print "Status: Memory usage is MODERATE";
        else print "Status: Memory usage is HIGH - Investigation needed";
    }
}')

add_section "Memory Performance Analysis" "$MEMORY_ANALYSIS"

# Disk Analysis
DISK_ANALYSIS=$(sar -d -f $DATA_FILE | awk '
BEGIN {
    print "Disk Performance Summary"
    print "======================="
    samples=0; total_tps=0; total_util=0; max_util=0;
}
$4 != "tps" && NF > 9 {
    samples++;
    tps=$4; util=$NF;
    total_tps += tps;
    total_util += util;
    if(util > max_util) max_util = util;
    if(util > 80) high_util_count++;
    if(tps > 100) high_tps_count++;
}
END {
    if(samples > 0) {
        avg_tps = total_tps/samples;
        avg_util = total_util/samples;
        
        print "Average TPS: " avg_tps;
        print "Average Disk Utilization: " avg_util "%";
        print "Peak Disk Utilization: " max_util "%";
        print "High Utilization Periods (>80%): " (high_util_count ? high_util_count : 0);
        print "High TPS Periods (>100): " (high_tps_count ? high_tps_count : 0);
        
        if(avg_util < 50) print "Status: Disk performance is GOOD";
        else if(avg_util < 80) print "Status: Disk performance is MODERATE";
        else print "Status: Disk performance is HIGH - Investigation needed";
    }
}')

add_section "Disk Performance Analysis" "$DISK_ANALYSIS"

# Performance Recommendations
RECOMMENDATIONS=$(cat << 'RECOMMENDATIONS'
Performance Optimization Recommendations:

1. CPU Optimization:
   - Monitor processes with high CPU usage using 'top' or 'htop'
   - Consider CPU affinity for critical processes
   - Evaluate if additional CPU cores are needed

2. Memory Optimization:
   - Review memory-intensive applications
   - Consider increasing swap space if memory usage is consistently high
   - Monitor for memory leaks in applications

3. Disk I/O Optimization:
   - Consider faster storage solutions (SSD) for high I/O workloads
   - Implement proper file system tuning
   - Monitor disk queue lengths and response times

4. General Recommendations:
   - Set up automated monitoring and alerting
   - Establish performance baselines
   - Regular performance reviews and capacity planning
RECOMMENDATIONS
)

add_section "Performance Recommendations" "$RECOMMENDATIONS"

# Close HTML
cat >> $MASTER_REPORT << 'EOF'
</body>
</html>
EOF

echo "Master performance report generated: $MASTER_REPORT"

# Also create a text version
TEXT_REPORT="${REPORT_DIR}/master_performance_report_${TIMESTAMP}.txt"
lynx -dump $MASTER_REPORT > $TEXT_REPORT 2>/dev/null || \
w3m -dump $MASTER_REPORT > $TEXT_REPORT 2>/dev/null || \
echo "Text version could not be generated. Install lynx or w3m for text output." > $TEXT_REPORT

echo "Text report generated: $TEXT_REPORT"
echo "Reports saved in: $REPORT_DIR"
ls -la $REPORT_DIR/
Make executable and run:

chmod +x master_performance_analysis.sh
./master_performance_analysis.sh
Subtask 5.2: Create Automated Monitoring Setup
Create a script for ongoing automated monitoring:
