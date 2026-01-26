Lab 15: Advanced Performance Tuning with Blktrace
Objectives
By the end of this lab, students will be able to:

Install and configure blktrace and related tools for block I/O tracing
Capture and analyze block layer I/O activity using blktrace
Interpret blktrace output to identify performance bottlenecks
Use blkparse to convert binary trace data into human-readable format
Analyze I/O patterns, throughput, and latency metrics
Implement disk performance optimizations based on trace analysis
Configure I/O schedulers and tune kernel parameters for better performance
Monitor the impact of tuning changes using before/after comparisons
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux file systems and storage concepts
Familiarity with command-line operations and text editors
Knowledge of I/O concepts including throughput, latency, and IOPS
Understanding of Linux kernel modules and system administration
Experience with performance monitoring tools like iostat and iotop
Root or sudo access to perform system-level configurations
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install an operating system.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS system
Root access for system configuration
Pre-installed development tools and utilities
Multiple storage devices for testing scenarios
Task 1: Install and Configure Blktrace
Subtask 1.1: Install Blktrace Package
First, we need to install the blktrace package and its dependencies.

For RHEL/CentOS systems:

# Update package repository
sudo yum update -y

# Install blktrace and related tools
sudo yum install -y blktrace

# Install additional analysis tools
sudo yum install -y sysstat iotop
For Ubuntu/Debian systems:

# Update package repository
sudo apt update

# Install blktrace and related tools
sudo apt install -y blktrace

# Install additional analysis tools
sudo apt install -y sysstat iotop
Subtask 1.2: Verify Installation and Check Available Devices
Verify that blktrace is properly installed and identify available block devices.

# Check blktrace version
blktrace -V

# List available block devices
lsblk

# Check current I/O scheduler for each device
for dev in $(lsblk -d -o NAME --noheadings); do
    if [ -f /sys/block/$dev/queue/scheduler ]; then
        echo "Device $dev scheduler: $(cat /sys/block/$dev/queue/scheduler)"
    fi
done

# Check current I/O statistics baseline
iostat -x 1 3
Subtask 1.3: Prepare Test Environment
Create a dedicated directory and test files for our I/O tracing experiments.

# Create test directory
sudo mkdir -p /opt/blktrace-lab
cd /opt/blktrace-lab

# Create test files of different sizes
sudo dd if=/dev/zero of=test_1mb.dat bs=1M count=1
sudo dd if=/dev/zero of=test_10mb.dat bs=1M count=10
sudo dd if=/dev/zero of=test_100mb.dat bs=1M count=100

# Create a script for generating I/O load
sudo tee io_load_generator.sh << 'EOF'
#!/bin/bash
# I/O Load Generator Script

TESTDIR="/opt/blktrace-lab"
DURATION=${1:-30}

echo "Starting I/O load generation for $DURATION seconds..."

# Sequential read test
dd if=$TESTDIR/test_100mb.dat of=/dev/null bs=4k &

# Sequential write test  
dd if=/dev/zero of=$TESTDIR/temp_write.dat bs=4k count=1000 &

# Random read test using dd with skip
for i in {1..100}; do
    dd if=$TESTDIR/test_100mb.dat of=/dev/null bs=4k count=1 skip=$((RANDOM % 1000)) 2>/dev/null &
done

# Wait for specified duration
sleep $DURATION

# Clean up background processes
pkill -f "dd if=$TESTDIR"
rm -f $TESTDIR/temp_write.dat

echo "I/O load generation completed."
EOF

sudo chmod +x io_load_generator.sh
Task 2: Trace I/O Activity and Analyze Throughput
Subtask 2.1: Basic Blktrace Usage
Learn the fundamental blktrace commands and options.

# Identify the primary storage device (usually sda, nvme0n1, etc.)
PRIMARY_DEVICE=$(lsblk -d -o NAME --noheadings | head -1)
echo "Primary device: $PRIMARY_DEVICE"

# Start a basic trace (run for 10 seconds)
sudo blktrace -d /dev/$PRIMARY_DEVICE -o trace_basic &
TRACE_PID=$!

# Generate some I/O activity
sudo dd if=/dev/zero of=/opt/blktrace-lab/trace_test.dat bs=1M count=50

# Stop the trace
sleep 2
sudo kill $TRACE_PID
wait $TRACE_PID 2>/dev/null

# List generated trace files
ls -la trace_basic.*
Subtask 2.2: Advanced Tracing with Multiple Options
Configure blktrace with advanced options for comprehensive analysis.

# Create advanced tracing script
sudo tee advanced_trace.sh << 'EOF'
#!/bin/bash

DEVICE=${1:-sda}
DURATION=${2:-60}
OUTPUT_PREFIX="advanced_trace"

echo "Starting advanced blktrace on /dev/$DEVICE for $DURATION seconds..."

# Start blktrace with comprehensive options
blktrace -d /dev/$DEVICE \
         -o $OUTPUT_PREFIX \
         -b 512 \
         -n 8 \
         -a issue,complete,queue,requeue &

TRACE_PID=$!
echo "Blktrace PID: $TRACE_PID"

# Wait for specified duration
sleep $DURATION

# Stop tracing
kill $TRACE_PID
wait $TRACE_PID 2>/dev/null

echo "Trace completed. Files generated:"
ls -la ${OUTPUT_PREFIX}.*

EOF

sudo chmod +x advanced_trace.sh
Subtask 2.3: Concurrent Tracing and I/O Load Generation
Run blktrace while generating controlled I/O load to capture realistic data.

# Start comprehensive trace
sudo ./advanced_trace.sh $PRIMARY_DEVICE 45 &
TRACE_SCRIPT_PID=$!

# Wait a moment for trace to start
sleep 3

# Generate mixed I/O load
echo "Generating I/O load..."
sudo ./io_load_generator.sh 30

# Additional specific I/O patterns
echo "Testing sequential read pattern..."
sudo dd if=/opt/blktrace-lab/test_100mb.dat of=/dev/null bs=64k

echo "Testing random write pattern..."
sudo dd if=/dev/urandom of=/opt/blktrace-lab/random_test.dat bs=4k count=1000

# Wait for trace to complete
wait $TRACE_SCRIPT_PID

echo "Trace and I/O generation completed."
Subtask 2.4: Parse and Analyze Trace Data
Convert binary trace data to human-readable format and perform initial analysis.

# Parse the trace data
sudo blkparse -i advanced_trace -o parsed_trace.txt

# Display basic statistics
echo "=== TRACE ANALYSIS SUMMARY ==="
echo "Total trace file size:"
ls -lh advanced_trace.* | awk '{sum+=$5} END {print sum/1024/1024 " MB"}'

echo -e "\n=== FIRST 20 TRACE ENTRIES ==="
head -20 parsed_trace.txt

echo -e "\n=== I/O OPERATION SUMMARY ==="
# Count different I/O operations
grep -c " Q " parsed_trace.txt | xargs echo "Queue operations:"
grep -c " I " parsed_trace.txt | xargs echo "Issue operations:"  
grep -c " C " parsed_trace.txt | xargs echo "Complete operations:"

echo -e "\n=== READ vs WRITE OPERATIONS ==="
grep -c " R " parsed_trace.txt | xargs echo "Read operations:"
grep -c " W " parsed_trace.txt | xargs echo "Write operations:"
Task 3: Tune Disk Access Patterns Based on Results
Subtask 3.1: Detailed Performance Analysis
Create comprehensive analysis scripts to identify performance bottlenecks.

# Create detailed analysis script
sudo tee analyze_performance.sh << 'EOF'
#!/bin/bash

TRACE_FILE="parsed_trace.txt"

if [ ! -f "$TRACE_FILE" ]; then
    echo "Error: Trace file $TRACE_FILE not found!"
    exit 1
fi

echo "=== DETAILED PERFORMANCE ANALYSIS ==="
echo "Analysis of: $TRACE_FILE"
echo "Generated on: $(date)"
echo

# Calculate basic metrics
TOTAL_OPS=$(wc -l < $TRACE_FILE)
READ_OPS=$(grep -c " R " $TRACE_FILE)
WRITE_OPS=$(grep -c " W " $TRACE_FILE)

echo "=== OPERATION STATISTICS ==="
echo "Total operations: $TOTAL_OPS"
echo "Read operations: $READ_OPS ($(( READ_OPS * 100 / TOTAL_OPS ))%)"
echo "Write operations: $WRITE_OPS ($(( WRITE_OPS * 100 / TOTAL_OPS ))%)"
echo

# Analyze I/O sizes
echo "=== I/O SIZE ANALYSIS ==="
awk '/[RW]/ {
    size = $10
    if (size <= 4096) small++
    else if (size <= 65536) medium++  
    else large++
    total++
}
END {
    print "Small I/O (<=4KB): " small " (" int(small*100/total) "%)"
    print "Medium I/O (4KB-64KB): " medium " (" int(medium*100/total) "%)"  
    print "Large I/O (>64KB): " large " (" int(large*100/total) "%)"
}' $TRACE_FILE

echo

# Analyze sequential vs random patterns
echo "=== ACCESS PATTERN ANALYSIS ==="
awk '/[RW]/ {
    sector = $8
    if (prev_sector != "" && sector == prev_sector + prev_size/512) {
        sequential++
    } else {
        random++
    }
    prev_sector = sector
    prev_size = $10
    total++
}
END {
    if (total > 0) {
        print "Sequential I/O: " sequential " (" int(sequential*100/total) "%)"
        print "Random I/O: " random " (" int(random*100/total) "%)"
    }
}' $TRACE_FILE

echo

# Calculate average latency (simplified)
echo "=== LATENCY ANALYSIS ==="
awk '
/Q/ { queue_time[$6] = $4 }
/C/ { 
    if (queue_time[$6] != "") {
        latency = $4 - queue_time[$6]
        if (latency > 0) {
            total_latency += latency
            count++
        }
    }
}
END {
    if (count > 0) {
        avg_latency = total_latency / count
        print "Average I/O latency: " avg_latency " seconds"
        print "Operations with latency data: " count
    }
}' $TRACE_FILE

EOF

sudo chmod +x analyze_performance.sh
sudo ./analyze_performance.sh
Subtask 3.2: Identify Current I/O Scheduler and Performance Baseline
Check current system configuration and establish performance baseline.

# Check current I/O scheduler for all devices
echo "=== CURRENT I/O SCHEDULER CONFIGURATION ==="
for dev in $(lsblk -d -o NAME --noheadings); do
    if [ -f /sys/block/$dev/queue/scheduler ]; then
        current=$(cat /sys/block/$dev/queue/scheduler)
        echo "Device /dev/$dev: $current"
    fi
done

echo -e "\n=== CURRENT QUEUE DEPTH SETTINGS ==="
for dev in $(lsblk -d -o NAME --noheadings); do
    if [ -f /sys/block/$dev/queue/nr_requests ]; then
        nr_requests=$(cat /sys/block/$dev/queue/nr_requests)
        echo "Device /dev/$dev queue depth: $nr_requests"
    fi
done

echo -e "\n=== CURRENT READ-AHEAD SETTINGS ==="
for dev in $(lsblk -d -o NAME --noheadings); do
    if [ -f /sys/block/$dev/queue/read_ahead_kb ]; then
        read_ahead=$(cat /sys/block/$dev/queue/read_ahead_kb)
        echo "Device /dev/$dev read-ahead: ${read_ahead}KB"
    fi
done

# Establish baseline performance
echo -e "\n=== BASELINE PERFORMANCE TEST ==="
echo "Running baseline I/O performance test..."

# Sequential read test
echo "Sequential read test (64KB blocks):"
sudo dd if=/opt/blktrace-lab/test_100mb.dat of=/dev/null bs=64k 2>&1 | grep -E "(copied|MB/s|GB/s)"

# Sequential write test
echo "Sequential write test (64KB blocks):"
sudo dd if=/dev/zero of=/opt/blktrace-lab/baseline_write.dat bs=64k count=1000 2>&1 | grep -E "(copied|MB/s|GB/s)"
sudo rm -f /opt/blktrace-lab/baseline_write.dat

# Random read test using fio if available, otherwise use dd
if command -v fio >/dev/null 2>&1; then
    echo "Random read test (4KB blocks):"
    sudo fio --name=random_read --ioengine=libaio --rw=randread --bs=4k --numjobs=1 --size=50m --runtime=10 --directory=/opt/blktrace-lab --group_reporting
else
    echo "Random read test (using dd with random seeks):"
    time (for i in {1..100}; do
        sudo dd if=/opt/blktrace-lab/test_100mb.dat of=/dev/null bs=4k count=1 skip=$((RANDOM % 1000)) 2>/dev/null
    done)
fi
Subtask 3.3: Implement I/O Scheduler Optimizations
Apply different I/O schedulers and measure their impact.

# Create I/O scheduler tuning script
sudo tee tune_io_scheduler.sh << 'EOF'
#!/bin/bash

DEVICE=${1:-sda}
SCHEDULER=${2:-mq-deadline}

if [ ! -f /sys/block/$DEVICE/queue/scheduler ]; then
    echo "Error: Device $DEVICE not found or scheduler not configurable"
    exit 1
fi

echo "Current scheduler for $DEVICE:"
cat /sys/block/$DEVICE/queue/scheduler

echo "Available schedulers:"
cat /sys/block/$DEVICE/queue/scheduler | tr '[]' ' ' | tr ' ' '\n' | grep -v '^$'

echo "Changing scheduler to: $SCHEDULER"
echo $SCHEDULER | sudo tee /sys/block/$DEVICE/queue/scheduler

echo "New scheduler setting:"
cat /sys/block/$DEVICE/queue/scheduler

# Configure scheduler-specific parameters
case $SCHEDULER in
    "mq-deadline")
        echo "Configuring mq-deadline parameters..."
        echo 500 | sudo tee /sys/block/$DEVICE/queue/iosched/read_expire 2>/dev/null || true
        echo 5000 | sudo tee /sys/block/$DEVICE/queue/iosched/write_expire 2>/dev/null || true
        echo 16 | sudo tee /sys/block/$DEVICE/queue/iosched/writes_starved 2>/dev/null || true
        ;;
    "kyber")
        echo "Configuring kyber parameters..."
        echo 2000000 | sudo tee /sys/block/$DEVICE/queue/iosched/read_lat_nsec 2>/dev/null || true
        echo 10000000 | sudo tee /sys/block/$DEVICE/queue/iosched/write_lat_nsec 2>/dev/null || true
        ;;
    "bfq")
        echo "Configuring BFQ parameters..."
        echo 0 | sudo tee /sys/block/$DEVICE/queue/iosched/slice_idle 2>/dev/null || true
        echo 8 | sudo tee /sys/block/$DEVICE/queue/iosched/fifo_expire_sync 2>/dev/null || true
        ;;
esac

echo "Scheduler configuration completed."

EOF

sudo chmod +x tune_io_scheduler.sh

# Test different schedulers
echo "=== TESTING DIFFERENT I/O SCHEDULERS ==="

# Get available schedulers for primary device
AVAILABLE_SCHEDULERS=$(cat /sys/block/$PRIMARY_DEVICE/queue/scheduler | tr '[]' ' ' | tr ' ' '\n' | grep -v '^$')

for scheduler in $AVAILABLE_SCHEDULERS; do
    echo -e "\n--- Testing scheduler: $scheduler ---"
    
    # Apply scheduler
    sudo ./tune_io_scheduler.sh $PRIMARY_DEVICE $scheduler
    
    # Wait for changes to take effect
    sleep 2
    
    # Run performance test
    echo "Performance test with $scheduler:"
    sudo dd if=/opt/blktrace-lab/test_100mb.dat of=/dev/null bs=64k 2>&1 | grep -E "(copied|MB/s|GB/s)"
    
    # Brief trace to see I/O pattern
    sudo blktrace -d /dev/$PRIMARY_DEVICE -o trace_${scheduler} &
    TRACE_PID=$!
    
    # Generate I/O load
    sudo dd if=/dev/zero of=/opt/blktrace-lab/scheduler_test.dat bs=64k count=500 2>/dev/null
    
    sleep 2
    sudo kill $TRACE_PID 2>/dev/null
    wait $TRACE_PID 2>/dev/null
    
    # Parse and analyze
    sudo blkparse -i trace_${scheduler} -o parsed_${scheduler}.txt 2>/dev/null
    
    if [ -f "parsed_${scheduler}.txt" ]; then
        ops=$(wc -l < parsed_${scheduler}.txt)
        echo "Trace operations captured: $ops"
    fi
    
    sudo rm -f /opt/blktrace-lab/scheduler_test.dat
done
Subtask 3.4: Optimize Queue Depth and Read-Ahead Settings
Fine-tune queue depth and read-ahead parameters based on workload characteristics.

# Create queue optimization script
sudo tee optimize_queue_settings.sh << 'EOF'
#!/bin/bash

DEVICE=${1:-sda}

echo "=== OPTIMIZING QUEUE SETTINGS FOR $DEVICE ==="

# Current settings
echo "Current queue depth: $(cat /sys/block/$DEVICE/queue/nr_requests)"
echo "Current read-ahead: $(cat /sys/block/$DEVICE/queue/read_ahead_kb)KB"

# Test different queue depths
echo -e "\n--- Testing Queue Depth Settings ---"
for queue_depth in 32 64 128 256; do
    echo "Testing queue depth: $queue_depth"
    echo $queue_depth | sudo tee /sys/block/$DEVICE/queue/nr_requests
    
    # Performance test
    time_result=$(sudo dd if=/opt/blktrace-lab/test_100mb.dat of=/dev/null bs=64k 2>&1 | grep -E "copied.*s")
    echo "Result: $time_result"
    
    sleep 1
done

echo -e "\n--- Testing Read-Ahead Settings ---"
# Test different read-ahead values
for read_ahead in 128 256 512 1024 2048; do
    echo "Testing read-ahead: ${read_ahead}KB"
    echo $read_ahead | sudo tee /sys/block/$DEVICE/queue/read_ahead_kb
    
    # Sequential read test
    time_result=$(sudo dd if=/opt/blktrace-lab/test_100mb.dat of=/dev/null bs=4k 2>&1 | grep -E "copied.*s")
    echo "Result: $time_result"
    
    sleep 1
done

# Set optimal values based on typical workloads
echo -e "\n--- Applying Optimized Settings ---"

# For general purpose workloads
echo 128 | sudo tee /sys/block/$DEVICE/queue/nr_requests
echo 512 | sudo tee /sys/block/$DEVICE/queue/read_ahead_kb

# Additional optimizations
echo "Applying additional optimizations..."

# Disable NCQ if it's causing issues (uncomment if needed)
# echo 1 | sudo tee /sys/block/$DEVICE/queue/nomerges

# Set optimal rotational setting
if [ -f /sys/block/$DEVICE/queue/rotational ]; then
    # Set to 0 for SSD, 1 for HDD - auto-detect based on rotation rate
    rotation_rate=$(cat /sys/block/$DEVICE/queue/rotational)
    echo "Current rotational setting: $rotation_rate"
fi

echo "Queue optimization completed."
echo "Final settings:"
echo "Queue depth: $(cat /sys/block/$DEVICE/queue/nr_requests)"
echo "Read-ahead: $(cat /sys/block/$DEVICE/queue/read_ahead_kb)KB"

EOF

sudo chmod +x optimize_queue_settings.sh
sudo ./optimize_queue_settings.sh $PRIMARY_DEVICE
Subtask 3.5: Validate Optimizations with Before/After Comparison
Perform comprehensive before/after testing to validate improvements.

# Create comprehensive validation script
sudo tee validate_optimizations.sh << 'EOF'
#!/bin/bash

DEVICE=${1:-sda}
TEST_DIR="/opt/blktrace-lab"

echo "=== COMPREHENSIVE PERFORMANCE VALIDATION ==="
echo "Device: /dev/$DEVICE"
echo "Test directory: $TEST_DIR"
echo "Timestamp: $(date)"

# Function to run performance test
run_performance_test() {
    local test_name="$1"
    local trace_prefix="$2"
    
    echo -e "\n--- $test_name ---"
    
    # Start tracing
    blktrace -d /dev/$DEVICE -o $trace_prefix &
    TRACE_PID=$!
    
    sleep 1
    
    # Sequential read test
    echo "Sequential read (64KB blocks):"
    dd if=$TEST_DIR/test_100mb.dat of=/dev/null bs=64k 2>&1 | grep -E "(copied|MB/s|GB/s)"
    
    # Sequential write test
    echo "Sequential write (64KB blocks):"
    dd if=/dev/zero of=$TEST_DIR/temp_write.dat bs=64k count=1000 2>&1 | grep -E "(copied|MB/s|GB/s)"
    
    # Mixed I/O test
    echo "Mixed I/O test:"
    (
        dd if=$TEST_DIR/test_100mb.dat of=/dev/null bs=4k &
        dd if=/dev/zero of=$TEST_DIR/temp_mixed.dat bs=4k count=2000 &
        wait
    ) 2>&1 | grep -E "(copied|MB/s|GB/s)" | tail -2
    
    # Stop tracing
    sleep 2
    kill $TRACE_PID 2>/dev/null
    wait $TRACE_PID 2>/dev/null
    
    # Parse trace
    blkparse -i $trace_prefix -o ${trace_prefix}_parsed.txt 2>/dev/null
    
    if [ -f "${trace_prefix}_parsed.txt" ]; then
        total_ops=$(wc -l < ${trace_prefix}_parsed.txt)
        read_ops=$(grep -c " R " ${trace_prefix}_parsed.txt)
        write_ops=$(grep -c " W " ${trace_prefix}_parsed.txt)
        
        echo "Trace summary:"
        echo "  Total operations: $total_ops"
        echo "  Read operations: $read_ops"
        echo "  Write operations: $write_ops"
        
        # Calculate average I/O size
        avg_size=$(awk '/[RW]/ {sum+=$10; count++} END {if(count>0) print int(sum/count)}' ${trace_prefix}_parsed.txt)
        echo "  Average I/O size: ${avg_size} bytes"
    fi
    
    # Cleanup
    rm -f $TEST_DIR/temp_write.dat $TEST_DIR/temp_mixed.dat
}

# Record current system state
echo "=== CURRENT SYSTEM CONFIGURATION ==="
echo "I/O Scheduler: $(cat /sys/block/$DEVICE/queue/scheduler)"
echo "Queue depth: $(cat /sys/block/$DEVICE/queue/nr_requests)"
echo "Read-ahead: $(cat /sys/block/$DEVICE/queue/read_ahead_kb)KB"

# Run optimized performance test
run_performance_test "OPTIMIZED CONFIGURATION TEST" "trace_optimized"

# Generate comprehensive report
echo -e "\n=== OPTIMIZATION IMPACT ANALYSIS ==="

# Compare with any previous baseline if available
if [ -f "trace_baseline_parsed.txt" ] && [ -f "trace_optimized_parsed.txt" ]; then
    echo "Comparing baseline vs optimized configuration:"
    
    baseline_ops=$(wc -l < trace_baseline_parsed.txt)
    optimized_ops=$(wc -l < trace_optimized_parsed.txt)
    
    echo "Operations - Baseline: $baseline_ops, Optimized: $optimized_ops"
    
    if [ $baseline_ops -gt 0 ] && [ $optimized_ops -gt 0 ]; then
        improvement=$((optimized_ops * 100 / baseline_ops - 100))
        if [ $improvement -gt 0 ]; then
            echo "Performance improvement: +${improvement}% more operations"
        else
            echo "Performance change: ${improvement}% operations"
        fi
    fi
fi

# System resource usage during test
echo -e "\n=== SYSTEM RESOURCE USAGE ==="
echo "Current load average: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory usage:"
free -h | grep -E "(Mem|Swap)"

echo -e "\n=== RECOMMENDATIONS ==="
echo "Based on the analysis, consider the following:"
echo "1. Monitor these settings under production workload"
echo "2. Adjust queue depth based on storage type (SSD vs HDD)"
echo "3. Fine-tune read-ahead for your specific access patterns"
echo "4. Consider workload-specific I/O scheduler selection"

EOF

sudo chmod +x validate_optimizations.sh
sudo ./validate_optimizations.sh $PRIMARY_DEVICE
Subtask 3.6: Create Persistent Configuration
Make the optimizations persistent across reboots.

# Create persistent configuration script
sudo tee make_persistent.sh << 'EOF'
#!/bin/bash

DEVICE=${1:-sda}

echo "=== MAKING I/O OPTIMIZATIONS PERSISTENT ==="

# Create udev rule for I/O scheduler
sudo tee /etc/udev/rules.d/60-io-scheduler.rules << UDEV_EOF
# Set I/O scheduler for block devices
ACTION=="add|change", KERNEL=="sd*", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
UDEV_EOF

# Create systemd service for queue optimizations
sudo tee /etc/systemd/system/io-optimization.service << SYSTEMD_EOF
[Unit]
Description=I/O Performance Optimizations
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/apply-io-optimizations.sh

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

# Create the optimization script
sudo tee /usr/local/bin/apply-io-optimizations.sh << OPT_EOF
#!/bin/bash

# Apply I/O optimizations to all block devices
for device in \$(lsblk -d -o NAME --noheadings); do
    # Skip loop and ram devices
    if [[ \$device =~ ^(loop|ram) ]]; then
        continue
    fi
    
    # Set queue depth
    if [ -f /sys/block/\$device/queue/nr_requests ]; then
        echo 128 > /sys/block/\$device/queue/nr_requests
    fi
    
    # Set read-ahead
    if [ -f /sys/block/\$device/queue/read_ahead_kb ]; then
        echo 512 > /sys/block/\$device/queue/read_ahead_kb
    fi
    
    # Additional optimizations for SSDs
    if [ -f /sys/block/\$device/queue/rotational ]; then
        rotational=\$(cat /sys/block/\$device/queue/rotational)
        if [ "\$rotational" = "0" ]; then
            # SSD optimizations
            echo 0 > /sys/block/\$device/queue/add_random 2>/dev/null || true
            echo 1 > /sys/block/\$device/queue/nomerges 2>/dev/null || true
        fi
    fi
done

logger "I/O optimizations applied successfully"
OPT_EOF

sudo chmod +x /usr/local/bin/apply-io-optimizations.sh

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable io-optimization.service

# Create sysctl configuration for kernel parameters
sudo tee /etc/sysctl.d/99-io-performance.conf << SYSCTL_EOF
# I/O Performance Tuning Parameters

# Virtual memory settings
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500

# Kernel I/O settings
kernel.io_delay_type = 1

# Network and I/O related
net.core.busy_read = 50
net.core.busy_poll = 50
SYSCTL_EOF

# Apply sysctl settings
sudo sysctl -p /etc/sysctl.d/99-io-performance.conf

echo "Persistent configuration created successfully!"
echo "The following components have been configured:"
echo "1. udev rules for I/O scheduler (/etc/udev/rules.d/60-io-scheduler.rules)"
echo "2. systemd service for queue optimizations (/etc/systemd/system/io-optimization.service)"
echo "3. Optimization script (/usr/local/bin/apply-io-optimizations.sh)"
echo "4. Kernel parameters (/etc/sysctl.d/99-io-performance.conf)"
echo
echo "To test the persistent configuration:"
echo "sudo systemctl start io-optimization.service"
echo "sudo systemctl status io-optimization.service"

EOF

sudo chmod +x make_persistent.sh
sudo ./make_persistent.sh $PRIMARY_DEVICE
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Blktrace fails to start

# Check if device exists and is accessible
ls -la /dev/$PRIMARY_DEVICE

# Verify blktrace permissions
sudo blktrace -d /dev/$PRIMARY_DEVICE -o test_trace &
TRACE_PID=$!
sleep 2
sudo kill $TRACE_PID
Issue 2: No trace data captured

# Check if debugfs is mounted
mount | grep debugfs

# Mount debugfs if not available
sudo mount -t debugfs debugfs /sys/kernel/debug
Issue 3: Permission denied errors

# Ensure proper permissions for trace directory
sudo chown -R $USER:$USER /opt/blktrace-lab
sudo chmod 755 /opt/blktrace-lab
**Issue 4: High system load during
