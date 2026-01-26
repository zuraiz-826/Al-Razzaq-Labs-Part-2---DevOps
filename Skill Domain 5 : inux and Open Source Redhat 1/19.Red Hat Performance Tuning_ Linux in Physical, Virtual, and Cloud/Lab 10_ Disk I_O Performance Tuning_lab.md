Lab 10: Disk I/O Performance Tuning
Objectives
By the end of this lab, you will be able to:

Monitor disk I/O performance using iostat and other system monitoring tools
Understand different disk I/O schedulers and their characteristics
Change disk I/O scheduler settings using command-line tools
Test and compare disk performance under different scheduler configurations
Select the optimal I/O scheduler for specific workload requirements
Implement performance tuning strategies for disk-intensive applications
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line interface
Familiarity with file system concepts and disk operations
Knowledge of system administration fundamentals
Understanding of performance monitoring concepts
Experience with text editors like vi or nano
Required Knowledge Areas:
Linux file systems and mount points
Basic understanding of I/O operations
System process monitoring
Command-line text manipulation
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Pre-installed system monitoring tools
Multiple disk devices for testing
Root access for system configuration changes
Task 1: Monitor Disk Usage with iostat
Subtask 1.1: Install and Verify System Monitoring Tools
First, let's ensure all necessary tools are installed and available.

Check if iostat is available:
which iostat
If iostat is not found, install the sysstat package:
For RHEL/CentOS systems:

sudo yum install -y sysstat
For Ubuntu/Debian systems:

sudo apt update
sudo apt install -y sysstat
Verify installation:
iostat -V
Subtask 1.2: Basic Disk Monitoring with iostat
Display current disk statistics:
iostat
This command shows CPU utilization and disk I/O statistics since system boot.

Display extended disk statistics:
iostat -x
The -x flag provides extended statistics including:

rrqm/s: Read requests merged per second
wrqm/s: Write requests merged per second
r/s: Read requests per second
w/s: Write requests per second
rkB/s: Kilobytes read per second
wkB/s: Kilobytes written per second
avgrq-sz: Average request size
avgqu-sz: Average queue length
await: Average wait time for I/O requests
r_await: Average wait time for read requests
w_await: Average wait time for write requests
svctm: Average service time
%util: Percentage of CPU time during which I/O requests were issued
Monitor disk activity in real-time:
iostat -x 2 5
This command displays extended statistics every 2 seconds for 5 iterations.

Subtask 1.3: Identify Available Disk Devices
List all block devices:
lsblk
Display disk information:
fdisk -l
Check mounted filesystems:
df -h
Identify the primary disk device (usually /dev/sda, /dev/vda, or /dev/nvme0n1):
ls -la /dev/sd* /dev/vd* /dev/nvme* 2>/dev/null
Subtask 1.4: Generate Disk I/O Load for Testing
Create a test directory:
mkdir -p /tmp/iotest
cd /tmp/iotest
Generate write-intensive workload:
dd if=/dev/zero of=testfile1 bs=1M count=1000 oflag=direct
In another terminal, monitor the I/O during the write operation:
iostat -x 1
Generate read-intensive workload:
dd if=testfile1 of=/dev/null bs=1M iflag=direct
Clean up test files:
rm -f /tmp/iotest/testfile1
Task 2: Change Disk I/O Scheduler Using Echo Commands
Subtask 2.1: Understand Available I/O Schedulers
Check current I/O scheduler for your primary disk:
Replace sda with your actual disk device name:

cat /sys/block/sda/queue/scheduler
The output shows available schedulers with the current one in brackets, for example:

noop deadline [cfq] mq-deadline kyber bfq none
Understand different scheduler types:
noop: No-operation scheduler, simple FIFO queue
deadline: Deadline scheduler, prevents request starvation
cfq: Completely Fair Queuing (legacy)
mq-deadline: Multi-queue deadline scheduler
kyber: Token-based scheduler for fast storage
bfq: Budget Fair Queuing scheduler
none: No scheduler (for NVMe devices)
Subtask 2.2: Change I/O Scheduler Temporarily
Change to deadline scheduler:
echo deadline | sudo tee /sys/block/sda/queue/scheduler
Verify the change:
cat /sys/block/sda/queue/scheduler
Change to mq-deadline scheduler:
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
Change to bfq scheduler (if available):
echo bfq | sudo tee /sys/block/sda/queue/scheduler
Subtask 2.3: Make Scheduler Changes Persistent
Create a script to set scheduler at boot:
sudo nano /etc/rc.local
Add the following content:
#!/bin/bash
# Set I/O scheduler for optimal performance
echo mq-deadline > /sys/block/sda/queue/scheduler
exit 0
Make the script executable:
sudo chmod +x /etc/rc.local
Alternative method using udev rules:
sudo nano /etc/udev/rules.d/60-ioscheduler.rules
Add udev rule content:
# Set I/O scheduler for all SCSI/SATA devices
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="mq-deadline"
# Set I/O scheduler for NVMe devices
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
Task 3: Test Disk Performance and Choose the Best Scheduler
Subtask 3.1: Create Performance Testing Scripts
Create a comprehensive test script:
nano disk_performance_test.sh
Add the following script content:
#!/bin/bash

# Disk Performance Testing Script
DEVICE="sda"  # Change this to your disk device
TEST_FILE="/tmp/iotest/perftest"
TEST_SIZE="1G"
SCHEDULERS=("mq-deadline" "kyber" "bfq" "none")

# Create test directory
mkdir -p /tmp/iotest

echo "=== Disk Performance Testing ==="
echo "Device: /dev/$DEVICE"
echo "Test file: $TEST_FILE"
echo "Test size: $TEST_SIZE"
echo

# Function to test scheduler performance
test_scheduler() {
    local scheduler=$1
    echo "Testing scheduler: $scheduler"
    
    # Set scheduler
    echo $scheduler | sudo tee /sys/block/$DEVICE/queue/scheduler > /dev/null
    
    # Clear cache
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    
    # Sequential write test
    echo "  Sequential write test..."
    write_result=$(dd if=/dev/zero of=$TEST_FILE bs=1M count=1024 oflag=direct 2>&1 | grep -o '[0-9.]* MB/s')
    
    # Sequential read test
    echo "  Sequential read test..."
    read_result=$(dd if=$TEST_FILE of=/dev/null bs=1M iflag=direct 2>&1 | grep -o '[0-9.]* MB/s')
    
    # Random I/O test using fio (if available)
    if command -v fio &> /dev/null; then
        echo "  Random I/O test..."
        fio_result=$(fio --name=random-rw --ioengine=libaio --iodepth=4 --rw=randrw --bs=4k --direct=1 --size=100M --numjobs=1 --filename=$TEST_FILE --group_reporting --runtime=30 --time_based 2>/dev/null | grep -E "read:|write:" | head -2)
    fi
    
    echo "  Results for $scheduler:"
    echo "    Sequential Write: $write_result"
    echo "    Sequential Read: $read_result"
    if [ ! -z "$fio_result" ]; then
        echo "    Random I/O: $fio_result"
    fi
    echo
    
    # Clean up
    rm -f $TEST_FILE
}

# Test each scheduler
for scheduler in "${SCHEDULERS[@]}"; do
    # Check if scheduler is available
    if grep -q $scheduler /sys/block/$DEVICE/queue/scheduler; then
        test_scheduler $scheduler
    else
        echo "Scheduler $scheduler not available on this system"
    fi
done

echo "=== Testing Complete ==="
Make the script executable:
chmod +x disk_performance_test.sh
Subtask 3.2: Install Additional Testing Tools
Install fio for advanced I/O testing:
For RHEL/CentOS:

sudo yum install -y fio
For Ubuntu/Debian:

sudo apt install -y fio
Install hdparm for disk benchmarking:
For RHEL/CentOS:

sudo yum install -y hdparm
For Ubuntu/Debian:

sudo apt install -y hdparm
Subtask 3.3: Run Comprehensive Performance Tests
Execute the performance test script:
./disk_performance_test.sh
Run individual fio tests for detailed analysis:
Random read test:

fio --name=random-read --ioengine=libaio --iodepth=16 --rw=randread --bs=4k --direct=1 --size=1G --numjobs=4 --filename=/tmp/iotest/fio-test --group_reporting --runtime=60 --time_based
Random write test:

fio --name=random-write --ioengine=libaio --iodepth=16 --rw=randwrite --bs=4k --direct=1 --size=1G --numjobs=4 --filename=/tmp/iotest/fio-test --group_reporting --runtime=60 --time_based
Sequential read test:

fio --name=sequential-read --ioengine=libaio --iodepth=1 --rw=read --bs=1M --direct=1 --size=2G --numjobs=1 --filename=/tmp/iotest/fio-test --group_reporting
Sequential write test:

fio --name=sequential-write --ioengine=libaio --iodepth=1 --rw=write --bs=1M --direct=1 --size=2G --numjobs=1 --filename=/tmp/iotest/fio-test --group_reporting
Test with hdparm:
sudo hdparm -tT /dev/sda
Subtask 3.4: Monitor I/O Performance During Tests
Open multiple terminal sessions and run monitoring commands:
Terminal 1 - iostat monitoring:

iostat -x 2
Terminal 2 - iotop monitoring (if available):

sudo iotop -o
Terminal 3 - System load monitoring:

watch -n 1 'cat /proc/loadavg; echo; cat /proc/meminfo | head -5'
Subtask 3.5: Analyze Results and Choose Optimal Scheduler
Create a results comparison script:
nano analyze_results.sh
Add analysis script content:
#!/bin/bash

echo "=== I/O Scheduler Performance Analysis ==="
echo

# Function to get current scheduler
get_current_scheduler() {
    cat /sys/block/sda/queue/scheduler | grep -o '\[.*\]' | tr -d '[]'
}

# Test different workload scenarios
test_workload() {
    local workload_name=$1
    local fio_params=$2
    
    echo "Testing workload: $workload_name"
    echo "Current scheduler: $(get_current_scheduler)"
    
    # Run iostat in background
    iostat -x 1 10 > /tmp/iostat_${workload_name}.log &
    iostat_pid=$!
    
    # Run fio test
    fio $fio_params --filename=/tmp/iotest/workload_test > /tmp/fio_${workload_name}.log 2>&1
    
    # Stop iostat
    kill $iostat_pid 2>/dev/null
    
    # Extract key metrics
    iops=$(grep "IOPS=" /tmp/fio_${workload_name}.log | head -1 | grep -o 'IOPS=[0-9]*' | cut -d= -f2)
    bandwidth=$(grep "BW=" /tmp/fio_${workload_name}.log | head -1 | grep -o 'BW=[0-9]*[KMG]iB/s' | cut -d= -f2)
    latency=$(grep "lat.*avg" /tmp/fio_${workload_name}.log | head -1 | awk '{print $4}' | tr -d ',')
    
    echo "  IOPS: $iops"
    echo "  Bandwidth: $bandwidth"
    echo "  Average Latency: $latency"
    echo
}

# Database-like workload (random read/write)
echo "=== Database Workload Test ==="
test_workload "database" "--name=db-test --ioengine=libaio --iodepth=8 --rw=randrw --rwmixread=70 --bs=8k --direct=1 --size=500M --numjobs=2 --runtime=30 --time_based --group_reporting"

# Web server workload (mostly reads)
echo "=== Web Server Workload Test ==="
test_workload "webserver" "--name=web-test --ioengine=libaio --iodepth=4 --rw=randrw --rwmixread=90 --bs=4k --direct=1 --size=500M --numjobs=4 --runtime=30 --time_based --group_reporting"

# File server workload (sequential)
echo "=== File Server Workload Test ==="
test_workload "fileserver" "--name=file-test --ioengine=libaio --iodepth=2 --rw=rw --rwmixread=60 --bs=64k --direct=1 --size=1G --numjobs=1 --runtime=30 --time_based --group_reporting"

echo "=== Analysis Complete ==="
echo "Check log files in /tmp/ for detailed results"
Make the analysis script executable:
chmod +x analyze_results.sh
Run analysis for each scheduler:
# Test mq-deadline
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
./analyze_results.sh

# Test bfq
echo bfq | sudo tee /sys/block/sda/queue/scheduler
./analyze_results.sh

# Test kyber (if available)
echo kyber | sudo tee /sys/block/sda/queue/scheduler
./analyze_results.sh
Subtask 3.6: Document and Implement Optimal Configuration
Create a performance summary report:
nano performance_report.txt
Document your findings:
=== Disk I/O Performance Tuning Report ===

System Information:
- OS: [Your OS version]
- Disk Type: [SSD/HDD/NVMe]
- Disk Device: /dev/sda
- File System: [ext4/xfs/etc.]

Scheduler Performance Summary:
[Document results for each scheduler tested]

mq-deadline:
- Best for: General purpose workloads
- Sequential Read: [X MB/s]
- Sequential Write: [X MB/s]
- Random IOPS: [X]
- Average Latency: [X ms]

bfq:
- Best for: Interactive/desktop workloads
- Sequential Read: [X MB/s]
- Sequential Write: [X MB/s]
- Random IOPS: [X]
- Average Latency: [X ms]

kyber:
- Best for: Fast NVMe storage
- Sequential Read: [X MB/s]
- Sequential Write: [X MB/s]
- Random IOPS: [X]
- Average Latency: [X ms]

Recommendation:
Based on testing, [scheduler name] provides the best performance for this system because [reasoning].

Implementation:
The optimal scheduler has been configured using:
echo [scheduler] > /sys/block/sda/queue/scheduler
Implement the optimal scheduler permanently:
# Method 1: Using systemd service
sudo nano /etc/systemd/system/ioscheduler.service
Add service content:

[Unit]
Description=Set optimal I/O scheduler
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo mq-deadline > /sys/block/sda/queue/scheduler'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
Enable the service:

sudo systemctl enable ioscheduler.service
sudo systemctl start ioscheduler.service
Troubleshooting Tips
Common Issues and Solutions
Permission denied when changing scheduler:

Ensure you're using sudo
Check if the scheduler is available: cat /sys/block/sda/queue/scheduler
iostat command not found:

Install sysstat package: sudo yum install sysstat or sudo apt install sysstat
No performance improvement observed:

Ensure you're testing with direct I/O (oflag=direct, iflag=direct)
Clear system caches before testing: echo 3 | sudo tee /proc/sys/vm/drop_caches
Use appropriate test sizes (larger than system RAM for meaningful results)
Scheduler change doesn't persist after reboot:

Implement persistent configuration using systemd service or udev rules
Check if your distribution has specific configuration files for I/O schedulers
fio tests show inconsistent results:

Run tests multiple times and average the results
Ensure system is not under load during testing
Use appropriate test duration (at least 30 seconds for meaningful results)
Performance Tuning Best Practices
Choose scheduler based on storage type:

SSDs/NVMe: Use none or mq-deadline
HDDs: Use mq-deadline or bfq
Mixed workloads: Use bfq
Consider workload characteristics:

Database servers: mq-deadline for balanced performance
File servers: bfq for fairness
High-performance computing: none for NVMe, mq-deadline for others
Monitor continuously:

Set up regular performance monitoring
Use tools like iotop, iostat, and sar
Implement alerting for I/O bottlenecks
Conclusion
In this lab, you have successfully learned how to optimize disk I/O performance in Linux systems. You accomplished the following key tasks:

What You Learned:
Disk I/O Monitoring: You mastered using iostat to monitor disk performance metrics, understanding key indicators like IOPS, throughput, latency, and queue depth.

I/O Scheduler Management: You learned how to identify, change, and configure different I/O schedulers including mq-deadline, bfq, kyber, and none, understanding their specific use cases and characteristics.

Performance Testing: You implemented comprehensive testing methodologies using tools like fio and dd to evaluate disk performance under various workload scenarios.

Optimization Strategy: You developed the skills to analyze performance data and select the optimal I/O scheduler based on your specific hardware and workload requirements.

Persistent Configuration: You learned how to make I/O scheduler changes permanent using systemd services and udev rules.

Why This Matters:
Disk I/O performance tuning is critical for system administrators and performance engineers because:

Application Performance: Proper I/O scheduling can significantly improve application response times and throughput
Resource Utilization: Optimal schedulers ensure efficient use of storage hardware capabilities
Cost Optimization: Better performance from existing hardware reduces the need for expensive upgrades
User Experience: Improved I/O performance directly translates to better user experience in database applications, web servers, and file systems
Scalability: Proper I/O tuning enables systems to handle higher loads and concurrent users
Real-World Applications:
The skills you've developed apply directly to:

Database server optimization
Web server performance tuning
File server configuration
Virtual machine host optimization
Cloud infrastructure management
High-performance computing environments
This knowledge forms a foundation for advanced Linux performance tuning and is essential for roles in system administration, DevOps, and infrastructure engineering. The techniques you've learned will help you diagnose and resolve I/O bottlenecks in production environments, ensuring optimal system performance and reliability.
