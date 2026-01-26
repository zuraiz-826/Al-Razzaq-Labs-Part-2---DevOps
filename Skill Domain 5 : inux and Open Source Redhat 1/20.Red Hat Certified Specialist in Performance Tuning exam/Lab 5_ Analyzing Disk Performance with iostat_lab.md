Lab 5: Analyzing Disk Performance with iostat
Objectives
By the end of this lab, students will be able to:

Monitor disk I/O performance using the iostat command and interpret key metrics
Identify disk I/O bottlenecks by analyzing utilization, wait times, and throughput statistics
Optimize storage performance by changing disk I/O schedulers and understanding their impact
Implement performance tuning strategies for storage subsystems in Linux environments
Generate synthetic workloads to test and validate performance improvements
Prerequisites
Before starting this lab, students should have:

Basic Linux command-line knowledge including file navigation and text editing
Understanding of Linux file systems and storage concepts
Familiarity with system monitoring concepts and basic performance metrics
Root or sudo access to modify system configurations
Knowledge of process management and background job execution
Lab Environment Setup
Al Nafi Cloud Machines: This lab uses pre-configured Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your ready-to-use environment. No need to build your own VM or install additional software.

Your cloud machine includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS with iostat pre-installed
Multiple disk devices for testing different scenarios
Root access for system configuration changes
Stress testing tools for generating I/O workloads
Task 1: Monitor Disk Performance with iostat
Subtask 1.1: Understanding iostat Basics
First, let's explore the iostat command and understand its basic functionality.

Check if iostat is installed and view its version:
iostat -V
Install iostat if needed (part of sysstat package):
# For RHEL/CentOS
sudo yum install sysstat -y

# For Ubuntu/Debian
sudo apt-get update && sudo apt-get install sysstat -y
Run basic iostat command to see current disk statistics:
iostat
Display extended statistics with device utilization:
iostat -x
Subtask 1.2: Continuous Monitoring Setup
Monitor disk performance continuously with 2-second intervals:
iostat -x 2
Monitor specific devices only:
iostat -x 2 /dev/sda /dev/sdb
Generate a monitoring script for automated data collection:
cat > disk_monitor.sh << 'EOF'
#!/bin/bash
# Disk Performance Monitoring Script

echo "Starting disk performance monitoring..."
echo "Timestamp: $(date)"
echo "=================================="

# Monitor for 60 seconds with 5-second intervals
iostat -x 5 12 > disk_performance_$(date +%Y%m%d_%H%M%S).log &

echo "Monitoring started. Check disk_performance_*.log for results."
echo "Press Ctrl+C to stop monitoring early."

# Wait for monitoring to complete
wait
echo "Monitoring completed."
EOF

chmod +x disk_monitor.sh
Subtask 1.3: Understanding Key Metrics
Create a reference guide for iostat metrics:
cat > iostat_metrics_guide.txt << 'EOF'
IOSTAT KEY METRICS REFERENCE GUIDE
==================================

Device Utilization Metrics:
- %util: Percentage of CPU time during which I/O requests were issued
- r/s: Read requests per second
- w/s: Write requests per second
- rkB/s: Kilobytes read per second
- wkB/s: Kilobytes written per second

Latency Metrics:
- await: Average time for I/O requests (including queue time)
- r_await: Average time for read requests
- w_await: Average time for write requests
- svctm: Average service time (deprecated in newer versions)

Queue Metrics:
- avgqu-sz: Average queue length of requests
- aqu-sz: Average queue size (newer metric name)

Performance Indicators:
- High %util (>80%): Potential bottleneck
- High await (>20ms): Slow response times
- High avgqu-sz (>2): Queue buildup indicating saturation
EOF

cat iostat_metrics_guide.txt
Task 2: Analyze I/O Statistics to Identify Bottlenecks
Subtask 2.1: Generate Test Workloads
Create a synthetic I/O workload generator:
cat > io_workload_generator.sh << 'EOF'
#!/bin/bash
# I/O Workload Generator for Testing

TESTDIR="/tmp/iostest"
mkdir -p $TESTDIR

echo "Generating I/O workload patterns..."

# Function to generate random read workload
generate_read_load() {
    echo "Starting random read workload..."
    dd if=/dev/urandom of=$TESTDIR/testfile bs=1M count=1000 2>/dev/null
    
    for i in {1..100}; do
        dd if=$TESTDIR/testfile of=/dev/null bs=4k skip=$((RANDOM % 250000)) count=1 2>/dev/null &
    done
}

# Function to generate sequential write workload
generate_write_load() {
    echo "Starting sequential write workload..."
    for i in {1..50}; do
        dd if=/dev/zero of=$TESTDIR/writefile_$i bs=1M count=100 2>/dev/null &
    done
}

# Function to generate mixed workload
generate_mixed_load() {
    echo "Starting mixed I/O workload..."
    generate_read_load &
    generate_write_load &
}

case "$1" in
    "read")
        generate_read_load
        ;;
    "write")
        generate_write_load
        ;;
    "mixed")
        generate_mixed_load
        ;;
    *)
        echo "Usage: $0 {read|write|mixed}"
        exit 1
        ;;
esac

echo "Workload generation started. Monitor with iostat in another terminal."
wait
echo "Workload generation completed."

# Cleanup
rm -rf $TESTDIR
EOF

chmod +x io_workload_generator.sh
Start monitoring in one terminal:
iostat -x 2
Generate workload in another terminal (open new terminal session):
./io_workload_generator.sh mixed
Subtask 2.2: Bottleneck Analysis Techniques
Create an automated bottleneck detection script:
cat > bottleneck_analyzer.sh << 'EOF'
#!/bin/bash
# Automated I/O Bottleneck Detection Script

LOGFILE="bottleneck_analysis_$(date +%Y%m%d_%H%M%S).log"

echo "I/O Bottleneck Analysis Report" > $LOGFILE
echo "Generated: $(date)" >> $LOGFILE
echo "================================" >> $LOGFILE

# Collect iostat data for analysis
iostat -x 1 10 > temp_iostat.log

# Analyze the data
echo "" >> $LOGFILE
echo "BOTTLENECK ANALYSIS RESULTS:" >> $LOGFILE
echo "----------------------------" >> $LOGFILE

# Check for high utilization
echo "Devices with high utilization (>80%):" >> $LOGFILE
awk '/^[a-z]/ && $NF > 80 {print $1 ": " $NF "%"}' temp_iostat.log >> $LOGFILE

# Check for high await times
echo "" >> $LOGFILE
echo "Devices with high await times (>20ms):" >> $LOGFILE
awk '/^[a-z]/ && $(NF-1) > 20 {print $1 ": " $(NF-1) "ms"}' temp_iostat.log >> $LOGFILE

# Check for high queue sizes
echo "" >> $LOGFILE
echo "Devices with high average queue sizes (>2):" >> $LOGFILE
awk '/^[a-z]/ && $(NF-2) > 2 {print $1 ": " $(NF-2)}' temp_iostat.log >> $LOGFILE

# Generate recommendations
echo "" >> $LOGFILE
echo "RECOMMENDATIONS:" >> $LOGFILE
echo "----------------" >> $LOGFILE
echo "1. Consider I/O scheduler optimization for high utilization devices" >> $LOGFILE
echo "2. Investigate storage hardware for devices with high await times" >> $LOGFILE
echo "3. Implement I/O throttling for applications causing queue buildup" >> $LOGFILE

# Cleanup
rm temp_iostat.log

echo "Analysis complete. Results saved to: $LOGFILE"
cat $LOGFILE
EOF

chmod +x bottleneck_analyzer.sh
Run the bottleneck analysis:
./bottleneck_analyzer.sh
Subtask 2.3: Performance Baseline Establishment
Create a baseline performance measurement script:
cat > baseline_measurement.sh << 'EOF'
#!/bin/bash
# Baseline Performance Measurement Script

BASELINE_DIR="baseline_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BASELINE_DIR

echo "Establishing performance baseline..."
echo "Measurement directory: $BASELINE_DIR"

# Collect system information
echo "System Information:" > $BASELINE_DIR/system_info.txt
uname -a >> $BASELINE_DIR/system_info.txt
cat /proc/cpuinfo | grep "model name" | head -1 >> $BASELINE_DIR/system_info.txt
free -h >> $BASELINE_DIR/system_info.txt
df -h >> $BASELINE_DIR/system_info.txt

# Collect idle performance metrics
echo "Collecting idle performance metrics..."
iostat -x 1 30 > $BASELINE_DIR/idle_performance.log &
IOSTAT_PID=$!

sleep 30
kill $IOSTAT_PID 2>/dev/null

# Collect loaded performance metrics
echo "Collecting loaded performance metrics..."
./io_workload_generator.sh mixed &
WORKLOAD_PID=$!

iostat -x 1 60 > $BASELINE_DIR/loaded_performance.log &
IOSTAT_PID=$!

sleep 60
kill $IOSTAT_PID 2>/dev/null
kill $WORKLOAD_PID 2>/dev/null

# Generate baseline report
echo "Generating baseline report..."
cat > $BASELINE_DIR/baseline_report.txt << 'REPORT_EOF'
PERFORMANCE BASELINE REPORT
===========================

This baseline measurement captures:
1. System configuration details
2. Idle performance characteristics
3. Performance under synthetic load

Use this baseline to:
- Compare before/after optimization results
- Identify performance degradation over time
- Establish SLA thresholds

Files in this baseline:
- system_info.txt: Hardware and OS details
- idle_performance.log: Performance without load
- loaded_performance.log: Performance under test load
REPORT_EOF

echo "Baseline measurement completed in: $BASELINE_DIR"
ls -la $BASELINE_DIR/
EOF

chmod +x baseline_measurement.sh
Establish your performance baseline:
./baseline_measurement.sh
Task 3: Change Disk I/O Schedulers to Improve Performance
Subtask 3.1: Understanding I/O Schedulers
Check current I/O schedulers for all block devices:
cat > check_schedulers.sh << 'EOF'
#!/bin/bash
# Check I/O Schedulers for All Block Devices

echo "Current I/O Schedulers:"
echo "======================"

for device in /sys/block/*/queue/scheduler; do
    device_name=$(echo $device | cut -d'/' -f4)
    if [[ $device_name =~ ^[a-z]+$ ]]; then
        echo -n "$device_name: "
        cat $device
    fi
done

echo ""
echo "Available schedulers are shown in brackets []"
echo "Current scheduler is shown in square brackets [current]"
EOF

chmod +x check_schedulers.sh
./check_schedulers.sh
Create an I/O scheduler information guide:
cat > scheduler_guide.txt << 'EOF'
I/O SCHEDULER COMPARISON GUIDE
==============================

1. mq-deadline (Multi-Queue Deadline):
   - Best for: General purpose, mixed workloads
   - Characteristics: Good balance of throughput and latency
   - Use case: Default choice for most scenarios

2. kyber:
   - Best for: Latency-sensitive applications
   - Characteristics: Focuses on response time consistency
   - Use case: Interactive workloads, databases

3. bfq (Budget Fair Queueing):
   - Best for: Desktop systems, interactive workloads
   - Characteristics: Provides fairness between processes
   - Use case: Multi-user systems, mixed workloads

4. none:
   - Best for: High-performance SSDs, NVMe drives
   - Characteristics: No scheduling overhead
   - Use case: Fast storage with hardware queuing

SELECTION CRITERIA:
- Rotational drives: mq-deadline or bfq
- SSDs: mq-deadline, kyber, or none
- Database servers: kyber or mq-deadline
- File servers: mq-deadline or bfq
- High IOPS applications: none or kyber
EOF

cat scheduler_guide.txt
Subtask 3.2: Testing Different I/O Schedulers
Create a scheduler performance testing script:
cat > scheduler_performance_test.sh << 'EOF'
#!/bin/bash
# I/O Scheduler Performance Testing Script

if [ $# -ne 1 ]; then
    echo "Usage: $0 <device_name>"
    echo "Example: $0 sda"
    exit 1
fi

DEVICE=$1
TEST_DIR="scheduler_test_$(date +%Y%m%d_%H%M%S)"
mkdir -p $TEST_DIR

# Get available schedulers
SCHEDULERS=$(cat /sys/block/$DEVICE/queue/scheduler | tr -d '[]' | tr ' ' '\n' | grep -v '^$')

echo "Testing I/O schedulers for device: $DEVICE"
echo "Available schedulers: $(echo $SCHEDULERS | tr '\n' ' ')"
echo "Results will be saved in: $TEST_DIR"

# Function to run performance test
run_test() {
    local scheduler=$1
    echo "Testing scheduler: $scheduler"
    
    # Set scheduler
    echo $scheduler > /sys/block/$DEVICE/queue/scheduler
    
    # Wait for scheduler change to take effect
    sleep 2
    
    # Start iostat monitoring
    iostat -x 2 30 > $TEST_DIR/${scheduler}_iostat.log &
    IOSTAT_PID=$!
    
    # Run test workload
    echo "Running test workload for $scheduler..."
    ./io_workload_generator.sh mixed > $TEST_DIR/${scheduler}_workload.log 2>&1
    
    # Stop iostat
    kill $IOSTAT_PID 2>/dev/null
    
    # Extract key metrics
    echo "Scheduler: $scheduler" > $TEST_DIR/${scheduler}_summary.txt
    echo "Average utilization: $(awk '/^[a-z]/ {sum+=$NF; count++} END {if(count>0) print sum/count "%"}' $TEST_DIR/${scheduler}_iostat.log)" >> $TEST_DIR/${scheduler}_summary.txt
    echo "Average await: $(awk '/^[a-z]/ {sum+=$(NF-1); count++} END {if(count>0) print sum/count "ms"}' $TEST_DIR/${scheduler}_iostat.log)" >> $TEST_DIR/${scheduler}_summary.txt
    
    echo "Test completed for $scheduler"
    sleep 5
}

# Test each scheduler
for scheduler in $SCHEDULERS; do
    run_test $scheduler
done

# Generate comparison report
echo "Generating comparison report..."
cat > $TEST_DIR/comparison_report.txt << 'REPORT_EOF'
I/O SCHEDULER PERFORMANCE COMPARISON
====================================

Test Configuration:
- Device tested: DEVICE_PLACEHOLDER
- Test duration: 60 seconds per scheduler
- Workload: Mixed read/write operations

Results Summary:
REPORT_EOF

# Add results to report
for scheduler in $SCHEDULERS; do
    if [ -f "$TEST_DIR/${scheduler}_summary.txt" ]; then
        echo "" >> $TEST_DIR/comparison_report.txt
        cat $TEST_DIR/${scheduler}_summary.txt >> $TEST_DIR/comparison_report.txt
    fi
done

# Replace placeholder
sed -i "s/DEVICE_PLACEHOLDER/$DEVICE/g" $TEST_DIR/comparison_report.txt

echo ""
echo "Performance testing completed!"
echo "Results directory: $TEST_DIR"
echo ""
echo "Comparison Report:"
echo "=================="
cat $TEST_DIR/comparison_report.txt
EOF

chmod +x scheduler_performance_test.sh
Run the scheduler performance test (replace 'sda' with your actual device):
# First, identify your block devices
lsblk

# Run the test on your primary disk (usually sda or nvme0n1)
sudo ./scheduler_performance_test.sh sda
Subtask 3.3: Implementing Scheduler Optimizations
Create a scheduler optimization script:
cat > optimize_schedulers.sh << 'EOF'
#!/bin/bash
# I/O Scheduler Optimization Script

echo "I/O Scheduler Optimization Tool"
echo "==============================="

# Function to detect storage type
detect_storage_type() {
    local device=$1
    if [ -f "/sys/block/$device/queue/rotational" ]; then
        if [ "$(cat /sys/block/$device/queue/rotational)" = "0" ]; then
            echo "SSD"
        else
            echo "HDD"
        fi
    else
        echo "UNKNOWN"
    fi
}

# Function to recommend scheduler
recommend_scheduler() {
    local device=$1
    local storage_type=$(detect_storage_type $device)
    
    case $storage_type in
        "SSD")
            echo "kyber"
            ;;
        "HDD")
            echo "mq-deadline"
            ;;
        *)
            echo "mq-deadline"
            ;;
    esac
}

# Function to apply optimization
apply_optimization() {
    local device=$1
    local scheduler=$2
    
    echo "Applying optimization to $device..."
    echo "Current scheduler: $(cat /sys/block/$device/queue/scheduler | grep -o '\[.*\]' | tr -d '[]')"
    echo "Recommended scheduler: $scheduler"
    
    # Apply scheduler
    echo $scheduler > /sys/block/$device/queue/scheduler
    
    # Verify change
    if [ "$(cat /sys/block/$device/queue/scheduler | grep -o '\[.*\]' | tr -d '[]')" = "$scheduler" ]; then
        echo "✓ Successfully applied $scheduler to $device"
        
        # Apply additional optimizations based on scheduler
        case $scheduler in
            "kyber")
                # Optimize for latency
                echo 2 > /sys/block/$device/queue/kyber/read_lat_nsec 2>/dev/null || true
                echo 10 > /sys/block/$device/queue/kyber/write_lat_nsec 2>/dev/null || true
                ;;
            "mq-deadline")
                # Optimize queue depth
                echo 32 > /sys/block/$device/queue/nr_requests 2>/dev/null || true
                ;;
        esac
    else
        echo "✗ Failed to apply $scheduler to $device"
    fi
}

# Main optimization logic
echo "Scanning block devices..."
for device_path in /sys/block/*; do
    device=$(basename $device_path)
    
    # Skip loop devices and other virtual devices
    if [[ $device =~ ^(loop|ram|dm-) ]]; then
        continue
    fi
    
    storage_type=$(detect_storage_type $device)
    recommended=$(recommend_scheduler $device)
    
    echo ""
    echo "Device: $device"
    echo "Type: $storage_type"
    echo "Recommended scheduler: $recommended"
    
    read -p "Apply optimization to $device? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_optimization $device $recommended
    fi
done

echo ""
echo "Optimization completed!"
echo "Current scheduler configuration:"
./check_schedulers.sh
EOF

chmod +x optimize_schedulers.sh
Run the optimization script:
sudo ./optimize_schedulers.sh
Make scheduler changes persistent across reboots:
cat > make_persistent.sh << 'EOF'
#!/bin/bash
# Make I/O Scheduler Changes Persistent

UDEV_RULE_FILE="/etc/udev/rules.d/60-io-schedulers.rules"

echo "Creating persistent I/O scheduler configuration..."

# Backup existing rules if they exist
if [ -f "$UDEV_RULE_FILE" ]; then
    cp "$UDEV_RULE_FILE" "${UDEV_RULE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create new udev rules
cat > "$UDEV_RULE_FILE" << 'UDEV_EOF'
# I/O Scheduler optimization rules
# Generated automatically - modify with care

# SSD devices - use kyber scheduler
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="kyber"

# HDD devices - use mq-deadline scheduler
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="mq-deadline"

# Additional optimizations for SSDs
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/nr_requests}="64"
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="64"
UDEV_EOF

echo "Udev rules created at: $UDEV_RULE_FILE"
echo "Rules will take effect after reboot or udev reload."

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

echo "Udev rules reloaded successfully."
EOF

chmod +x make_persistent.sh
sudo ./make_persistent.sh
Subtask 3.4: Performance Validation
Create a validation script to compare before and after performance:
cat > validate_optimization.sh << 'EOF'
#!/bin/bash
# Performance Optimization Validation Script

VALIDATION_DIR="validation_$(date +%Y%m%d_%H%M%S)"
mkdir -p $VALIDATION_DIR

echo "Performance Optimization Validation"
echo "==================================="
echo "Results will be saved in: $VALIDATION_DIR"

# Record current configuration
echo "Recording current configuration..."
./check_schedulers.sh > $VALIDATION_DIR/current_schedulers.txt

# Run performance test
echo "Running post-optimization performance test..."
iostat -x 1 60 > $VALIDATION_DIR/optimized_performance.log &
IOSTAT_PID=$!

# Generate test load
./io_workload_generator.sh mixed > $VALIDATION_DIR/test_workload.log 2>&1

# Stop iostat
kill $IOSTAT_PID 2>/dev/null

# Generate validation report
echo "Generating validation report..."
cat > $VALIDATION_DIR/validation_report.txt << 'VALIDATION_EOF'
PERFORMANCE OPTIMIZATION VALIDATION REPORT
==========================================

Test Date: $(date)
Test Duration: 60 seconds
Workload: Mixed read/write operations

OPTIMIZATION RESULTS:
--------------------

Current Scheduler Configuration:
$(cat current_schedulers.txt)

Performance Metrics Summary:
- Average Utilization: $(awk '/^[a-z]/ {sum+=$NF; count++} END {if(count>0) printf "%.2f%%", sum/count}' optimized_performance.log)
- Average Await Time: $(awk '/^[a-z]/ {sum+=$(NF-1); count++} END {if(count>0) printf "%.2fms", sum/count}' optimized_performance.log)
- Average Queue Size: $(awk '/^[a-z]/ {sum+=$(NF-2); count++} END {if(count>0) printf "%.2f", sum/count}' optimized_performance.log)

RECOMMENDATIONS:
---------------
1. Compare these results with your baseline measurements
2. Monitor performance over time to ensure stability
3. Consider application-specific tuning if needed
4. Document changes for future reference

FILES INCLUDED:
--------------
- current_schedulers.txt: Active scheduler configuration
- optimized_performance.log: Detailed iostat output
- test_workload.log: Workload generation log
- validation_report.txt: This summary report
VALIDATION_EOF

# Process the template
cd $VALIDATION_DIR
eval "echo \"$(cat validation_report.txt)\"" > validation_report_final.txt
mv validation_report_final.txt validation_report.txt
cd ..

echo ""
echo "Validation completed!"
echo "Report location: $VALIDATION_DIR/validation_report.txt"
echo ""
echo "Validation Summary:"
echo "=================="
cat $VALIDATION_DIR/validation_report.txt
EOF

chmod +x validate_optimization.sh
Run the validation:
./validate_optimization.sh
Troubleshooting Common Issues
Issue 1: Permission Denied When Changing Schedulers
Problem: Cannot modify scheduler settings due to permission errors.

Solution:

# Ensure you have root privileges
sudo su -

# Or use sudo with each command
sudo echo kyber > /sys/block/sda/queue/scheduler
Issue 2: Scheduler Not Available
Problem: Requested scheduler is not available on the system.

Solution:

# Check available schedulers
cat /sys/block/sda/queue/scheduler

# Install additional schedulers if needed (kernel modules)
modprobe bfq
modprobe kyber-iosched
Issue 3: High CPU Usage During Testing
Problem: System becomes unresponsive during I/O testing.

Solution:

# Limit test intensity
# Modify io_workload_generator.sh to use smaller files
# Reduce concurrent operations
# Use ionice to limit I/O priority

ionice -c 3 ./io_workload_generator.sh mixed
Issue 4: Inconsistent Performance Results
Problem: Performance measurements vary significantly between runs.

Solution:

# Clear caches before each test
sync
echo 3 > /proc/sys/vm/drop_caches

# Run multiple iterations and average results
# Ensure system is idle during testing
# Check for background processes affecting I/O
Conclusion
In this comprehensive lab, you have successfully:

Mastered iostat monitoring by learning to interpret key performance metrics including utilization, await times, and queue depths. This skill is essential for identifying storage bottlenecks in production environments.

Developed bottleneck analysis expertise through hands-on experience with synthetic workloads and automated detection scripts. You can now systematically identify and diagnose I/O performance issues.

Implemented I/O scheduler optimizations by understanding the characteristics of different schedulers and applying appropriate configurations based on storage types and workload patterns.

Established performance validation processes using baseline measurements and comparative analysis to quantify optimization improvements.

Why This Matters: Storage performance is often the limiting factor in system performance. The skills you've developed in this lab are directly applicable to:

Production system optimization where storage bottlenecks impact application performance
Capacity planning by understanding I/O patterns and requirements
Troubleshooting performance issues in enterprise environments
Red Hat Certified Specialist in Performance Tuning exam preparation
Next Steps: Continue practicing these techniques in different environments, experiment with various workload patterns, and consider advanced topics like storage tiering, caching strategies, and application-specific I/O optimizations.

The combination of monitoring skills, analytical techniques, and optimization strategies you've learned provides a solid foundation for managing storage performance in any Linux environment.
