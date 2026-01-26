Lab 16: Kernel Module Parameter Tuning
Objectives
By the end of this lab, students will be able to:

Understand kernel module parameters and their impact on system performance
Identify and modify network-related kernel module parameters
Adjust storage subsystem kernel module parameters
Evaluate performance changes using system monitoring tools
Measure resource consumption before and after parameter adjustments
Apply systematic approaches to kernel parameter tuning for specific workloads
Document and validate performance improvements
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and text editors
Knowledge of system monitoring concepts
Understanding of network and storage fundamentals
Experience with performance monitoring tools like top, iostat, and sar
Root or sudo access to the system
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
Pre-installed performance monitoring tools
Network testing utilities
Storage benchmarking tools
Task 1: Understanding and Modifying Network Kernel Module Parameters
Subtask 1.1: Examine Current Network Parameters
First, let's explore the current network-related kernel parameters and understand their current values.

List all network-related kernel parameters:
# View all network parameters
sysctl -a | grep net | head -20

# Focus on key TCP parameters
sysctl net.core.rmem_max net.core.wmem_max net.core.netdev_max_backlog
Check current network module parameters:
# List loaded network modules
lsmod | grep -E "(e1000|igb|ixgbe|virtio_net)"

# Check parameters for network interface module (example with virtio_net)
modinfo virtio_net
Document baseline network performance:
# Install network testing tools if not available
sudo yum install -y iperf3 netperf

# Check current network interface statistics
cat /proc/net/dev

# Save baseline network statistics
ip -s link show > /tmp/network_baseline.txt
Subtask 1.2: Modify Network Buffer Parameters
Now we'll adjust network buffer sizes to optimize for high-throughput workloads.

Create a backup of current settings:
# Backup current network settings
sysctl -a | grep net > /tmp/network_sysctl_backup.txt
Modify TCP buffer sizes:
# Increase TCP receive buffer sizes
sudo sysctl -w net.core.rmem_default=262144
sudo sysctl -w net.core.rmem_max=16777216

# Increase TCP send buffer sizes
sudo sysctl -w net.core.wmem_default=262144
sudo sysctl -w net.core.wmem_max=16777216

# Adjust TCP window scaling
sudo sysctl -w net.ipv4.tcp_window_scaling=1

# Increase network device backlog
sudo sysctl -w net.core.netdev_max_backlog=5000
Configure TCP congestion control:
# Check available congestion control algorithms
cat /proc/sys/net/ipv4/tcp_available_congestion_control

# Set BBR congestion control (if available)
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr

# Or use CUBIC as alternative
# sudo sysctl -w net.ipv4.tcp_congestion_control=cubic
Subtask 1.3: Adjust Network Interface Parameters
Modify parameters specific to network interface modules for better performance.

Identify your network interface:
# List network interfaces
ip link show

# Get interface driver information
ethtool -i eth0  # Replace eth0 with your interface name
Adjust interface ring buffer sizes:
# Check current ring buffer settings
ethtool -g eth0

# Increase ring buffer sizes (adjust values based on your hardware)
sudo ethtool -G eth0 rx 4096 tx 4096
Enable network interface optimizations:
# Enable TCP segmentation offload
sudo ethtool -K eth0 tso on

# Enable generic receive offload
sudo ethtool -K eth0 gro on

# Enable receive packet steering
echo 2 | sudo tee /sys/class/net/eth0/queues/rx-0/rps_cpus
Task 2: Modifying Storage Kernel Module Parameters
Subtask 2.1: Examine Current Storage Parameters
Let's analyze the current storage subsystem configuration and parameters.

Check current I/O scheduler and parameters:
# Check I/O scheduler for each block device
for dev in /sys/block/*/queue/scheduler; do
    echo "Device: $dev"
    cat $dev
    echo "---"
done

# Check current I/O parameters
cat /sys/block/sda/queue/read_ahead_kb
cat /sys/block/sda/queue/nr_requests
Examine storage module parameters:
# List storage-related modules
lsmod | grep -E "(scsi|ata|nvme|virtio_blk)"

# Check parameters for storage modules
modinfo virtio_blk
modinfo scsi_mod
Document baseline storage performance:
# Install storage benchmarking tools
sudo yum install -y fio hdparm

# Check current disk statistics
iostat -x 1 3

# Save baseline I/O statistics
cat /proc/diskstats > /tmp/storage_baseline.txt
Subtask 2.2: Optimize I/O Scheduler Parameters
Configure I/O scheduler settings for better performance based on workload type.

Change I/O scheduler to deadline for better latency:
# Check current scheduler
cat /sys/block/sda/queue/scheduler

# Change to deadline scheduler (good for databases)
echo deadline | sudo tee /sys/block/sda/queue/scheduler

# Or use mq-deadline for multi-queue devices
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
Adjust I/O scheduler parameters:
# Increase read-ahead for sequential workloads
echo 512 | sudo tee /sys/block/sda/queue/read_ahead_kb

# Increase request queue depth
echo 128 | sudo tee /sys/block/sda/queue/nr_requests

# Adjust deadline scheduler parameters
echo 50 | sudo tee /sys/block/sda/queue/iosched/read_expire
echo 250 | sudo tee /sys/block/sda/queue/iosched/write_expire
Subtask 2.3: Modify Virtual Memory Parameters
Adjust kernel virtual memory parameters to optimize for storage workloads.

Configure dirty page parameters:
# Reduce dirty page ratio for better write performance
sudo sysctl -w vm.dirty_ratio=10
sudo sysctl -w vm.dirty_background_ratio=5

# Adjust dirty page writeback timing
sudo sysctl -w vm.dirty_expire_centisecs=1500
sudo sysctl -w vm.dirty_writeback_centisecs=500
Optimize swap and memory parameters:
# Reduce swappiness for better performance
sudo sysctl -w vm.swappiness=10

# Adjust VFS cache pressure
sudo sysctl -w vm.vfs_cache_pressure=50
Task 3: Performance Evaluation and Resource Consumption Analysis
Subtask 3.1: Network Performance Testing
Measure network performance improvements after parameter adjustments.

Create network performance test script:
# Create network test script
cat > /tmp/network_test.sh << 'EOF'
#!/bin/bash

echo "=== Network Performance Test ==="
echo "Testing network throughput and latency..."

# Test local network performance
echo "Local network interface statistics:"
ip -s link show eth0

# Test TCP performance (requires iperf3 server on another machine or localhost)
echo "Starting iperf3 server in background..."
iperf3 -s -D

sleep 2

echo "Testing TCP throughput:"
iperf3 -c localhost -t 10 -P 4

# Kill background iperf3 server
pkill iperf3

echo "Network test completed."
EOF

chmod +x /tmp/network_test.sh
Run network performance tests:
# Execute network performance test
/tmp/network_test.sh

# Monitor network statistics during test
watch -n 1 'cat /proc/net/dev | grep eth0'
Measure network resource consumption:
# Monitor network-related CPU usage
top -p $(pgrep -d',' ksoftirqd)

# Check network buffer usage
ss -m

# Monitor network interrupts
watch -n 1 'cat /proc/interrupts | grep eth0'
Subtask 3.2: Storage Performance Testing
Evaluate storage performance improvements after kernel parameter modifications.

Create storage benchmark script:
# Create comprehensive storage test script
cat > /tmp/storage_test.sh << 'EOF'
#!/bin/bash

echo "=== Storage Performance Test ==="
TEST_DIR="/tmp/storage_test"
mkdir -p $TEST_DIR

echo "Testing random read performance..."
fio --name=random_read --ioengine=libaio --rw=randread --bs=4k --numjobs=4 \
    --size=100M --runtime=30 --directory=$TEST_DIR --group_reporting

echo "Testing random write performance..."
fio --name=random_write --ioengine=libaio --rw=randwrite --bs=4k --numjobs=4 \
    --size=100M --runtime=30 --directory=$TEST_DIR --group_reporting

echo "Testing sequential read performance..."
fio --name=seq_read --ioengine=libaio --rw=read --bs=64k --numjobs=1 \
    --size=500M --runtime=30 --directory=$TEST_DIR --group_reporting

echo "Testing sequential write performance..."
fio --name=seq_write --ioengine=libaio --rw=write --bs=64k --numjobs=1 \
    --size=500M --runtime=30 --directory=$TEST_DIR --group_reporting

# Cleanup
rm -rf $TEST_DIR
echo "Storage test completed."
EOF

chmod +x /tmp/storage_test.sh
Execute storage performance tests:
# Run storage benchmark
/tmp/storage_test.sh

# Monitor I/O statistics during test
iostat -x 1 5
Analyze storage resource consumption:
# Monitor I/O wait and system load
vmstat 1 10

# Check disk utilization
iotop -a -o

# Monitor storage-related kernel threads
ps aux | grep -E "\[.*\]" | grep -E "(kworker|ksoftirqd|migration)"
Subtask 3.3: System-Wide Performance Analysis
Perform comprehensive system performance analysis to evaluate overall impact.

Create system monitoring script:
# Create comprehensive monitoring script
cat > /tmp/system_monitor.sh << 'EOF'
#!/bin/bash

echo "=== System Performance Analysis ==="
echo "Timestamp: $(date)"
echo

echo "CPU Usage:"
mpstat 1 5

echo "Memory Usage:"
free -h
echo

echo "System Load:"
uptime
echo

echo "Top Processes by CPU:"
ps aux --sort=-%cpu | head -10
echo

echo "Top Processes by Memory:"
ps aux --sort=-%mem | head -10
echo

echo "Network Connections:"
ss -tuln | wc -l
echo "Active network connections: $(ss -tuln | wc -l)"
echo

echo "Disk I/O Statistics:"
iostat -x 1 3
echo

echo "System Interrupts:"
cat /proc/interrupts | head -10
EOF

chmod +x /tmp/system_monitor.sh
Run comprehensive system analysis:
# Execute system monitoring
/tmp/system_monitor.sh > /tmp/performance_analysis.txt

# Display results
cat /tmp/performance_analysis.txt
Compare before and after performance:
# Create comparison script
cat > /tmp/compare_performance.sh << 'EOF'
#!/bin/bash

echo "=== Performance Comparison ==="
echo "Comparing baseline vs optimized performance"
echo

echo "Network Buffer Sizes:"
echo "Before: Default values"
echo "After:"
sysctl net.core.rmem_max net.core.wmem_max net.core.netdev_max_backlog

echo
echo "Storage I/O Settings:"
echo "Current I/O Scheduler: $(cat /sys/block/sda/queue/scheduler)"
echo "Read-ahead: $(cat /sys/block/sda/queue/read_ahead_kb) KB"
echo "Request Queue Depth: $(cat /sys/block/sda/queue/nr_requests)"

echo
echo "Virtual Memory Settings:"
sysctl vm.dirty_ratio vm.dirty_background_ratio vm.swappiness
EOF

chmod +x /tmp/compare_performance.sh
/tmp/compare_performance.sh
Task 4: Making Changes Persistent
Subtask 4.1: Create Persistent Configuration
Ensure that the optimized kernel parameters persist across system reboots.

Create sysctl configuration file:
# Create custom sysctl configuration
sudo tee /etc/sysctl.d/99-performance-tuning.conf << 'EOF'
# Network Performance Tuning
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_congestion_control = bbr

# Virtual Memory Tuning
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 1500
vm.dirty_writeback_centisecs = 500
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF
Create systemd service for storage parameters:
# Create systemd service for storage tuning
sudo tee /etc/systemd/system/storage-tuning.service << 'EOF'
[Unit]
Description=Storage Performance Tuning
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo deadline > /sys/block/sda/queue/scheduler'
ExecStart=/bin/bash -c 'echo 512 > /sys/block/sda/queue/read_ahead_kb'
ExecStart=/bin/bash -c 'echo 128 > /sys/block/sda/queue/nr_requests'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl enable storage-tuning.service
Create network interface tuning script:
# Create network interface tuning script
sudo tee /usr/local/bin/network-tuning.sh << 'EOF'
#!/bin/bash
# Network interface performance tuning

INTERFACE="eth0"  # Adjust as needed

# Wait for interface to be available
sleep 5

# Apply network interface optimizations
ethtool -G $INTERFACE rx 4096 tx 4096 2>/dev/null || true
ethtool -K $INTERFACE tso on 2>/dev/null || true
ethtool -K $INTERFACE gro on 2>/dev/null || true

# Enable RPS
echo 2 > /sys/class/net/$INTERFACE/queues/rx-0/rps_cpus 2>/dev/null || true
EOF

sudo chmod +x /usr/local/bin/network-tuning.sh

# Create systemd service for network tuning
sudo tee /etc/systemd/system/network-tuning.service << 'EOF'
[Unit]
Description=Network Performance Tuning
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/network-tuning.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable network-tuning.service
Subtask 4.2: Validate Persistent Configuration
Test that the configuration persists across reboots and validate the settings.

Apply current configuration:
# Apply sysctl changes
sudo sysctl -p /etc/sysctl.d/99-performance-tuning.conf

# Start services
sudo systemctl start storage-tuning.service
sudo systemctl start network-tuning.service
Verify configuration:
# Verify sysctl parameters
echo "=== Verifying sysctl parameters ==="
sysctl net.core.rmem_max net.core.wmem_max vm.dirty_ratio vm.swappiness

# Verify storage settings
echo "=== Verifying storage settings ==="
cat /sys/block/sda/queue/scheduler
cat /sys/block/sda/queue/read_ahead_kb

# Verify network settings
echo "=== Verifying network settings ==="
ethtool -g eth0 2>/dev/null || echo "ethtool not available or interface not found"
Create validation script:
# Create comprehensive validation script
cat > /tmp/validate_tuning.sh << 'EOF'
#!/bin/bash

echo "=== Kernel Parameter Tuning Validation ==="
echo "Timestamp: $(date)"
echo

PASS=0
FAIL=0

# Function to check parameter
check_param() {
    local param=$1
    local expected=$2
    local current=$(sysctl -n $param 2>/dev/null)
    
    if [ "$current" = "$expected" ]; then
        echo "✓ $param: $current (Expected: $expected)"
        ((PASS++))
    else
        echo "✗ $param: $current (Expected: $expected)"
        ((FAIL++))
    fi
}

echo "Network Parameters:"
check_param "net.core.rmem_max" "16777216"
check_param "net.core.wmem_max" "16777216"
check_param "net.core.netdev_max_backlog" "5000"

echo
echo "Virtual Memory Parameters:"
check_param "vm.dirty_ratio" "10"
check_param "vm.swappiness" "10"

echo
echo "Storage Settings:"
SCHEDULER=$(cat /sys/block/sda/queue/scheduler 2>/dev/null | grep -o '\[.*\]' | tr -d '[]')
if [ "$SCHEDULER" = "deadline" ] || [ "$SCHEDULER" = "mq-deadline" ]; then
    echo "✓ I/O Scheduler: $SCHEDULER"
    ((PASS++))
else
    echo "✗ I/O Scheduler: $SCHEDULER (Expected: deadline or mq-deadline)"
    ((FAIL++))
fi

echo
echo "=== Validation Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ $FAIL -eq 0 ]; then
    echo "All kernel parameter tuning validated successfully!"
    exit 0
else
    echo "Some parameters need attention."
    exit 1
fi
EOF

chmod +x /tmp/validate_tuning.sh
/tmp/validate_tuning.sh
Troubleshooting Common Issues
Network Parameter Issues
BBR congestion control not available:
# Check if BBR module is loaded
lsmod | grep tcp_bbr

# Load BBR module if available
sudo modprobe tcp_bbr

# Add to modules load configuration
echo 'tcp_bbr' | sudo tee -a /etc/modules-load.d/bbr.conf
ethtool commands failing:
# Check if ethtool is installed
which ethtool || sudo yum install -y ethtool

# Verify interface name
ip link show
Storage Parameter Issues
I/O scheduler change not working:
# Check available schedulers
cat /sys/block/sda/queue/scheduler

# For NVMe devices, use different path
ls /sys/block/nvme*/queue/scheduler
Permission denied errors:
# Ensure you have root privileges
sudo -i

# Check if files are writable
ls -la /sys/block/sda/queue/
Conclusion
In this comprehensive lab, you have successfully:

Analyzed baseline system performance by examining current kernel module parameters for both network and storage subsystems
Modified critical network parameters including TCP buffer sizes, congestion control algorithms, and network interface settings to optimize for high-throughput workloads
Adjusted storage kernel parameters by configuring I/O schedulers, virtual memory settings, and disk queue parameters for improved storage performance
Evaluated performance improvements using industry-standard benchmarking tools like fio, iperf3, and system monitoring utilities
Measured resource consumption changes to understand the impact of parameter modifications on CPU, memory, and I/O utilization
Implemented persistent configuration to ensure optimizations survive system reboots through sysctl configuration files and systemd services
Why This Matters
Kernel module parameter tuning is a critical skill for system administrators and performance engineers because:

Performance Optimization: Proper tuning can significantly improve application performance, sometimes by 20-50% or more
Resource Efficiency: Optimized parameters help systems handle higher workloads with the same hardware resources
Cost Reduction: Better performance per server means fewer servers needed, reducing infrastructure costs
Competitive Advantage: In high-performance computing and enterprise environments, every millisecond and IOPS counts
Certification Readiness: These skills are essential for Red Hat Certified Specialist in Performance Tuning and similar certifications
The techniques learned in this lab apply directly to production environments where you'll need to optimize Linux systems for specific workloads, whether they're database servers, web applications, or high-performance computing clusters. Understanding how to systematically tune, test, and validate kernel parameters is a valuable skill that distinguishes advanced system administrators from novices.

Remember to always test parameter changes in non-production environments first, document your changes, and maintain rollback procedures for critical systems.
