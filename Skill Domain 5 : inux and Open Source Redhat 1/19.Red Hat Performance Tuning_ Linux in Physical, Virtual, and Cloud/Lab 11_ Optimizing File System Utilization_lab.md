Lab 11: Optimizing File System Utilization
Objectives
By the end of this lab, students will be able to:

Configure advanced mount options like noatime and nodiratime to improve file system performance
Tune file system parameters for optimal performance in large-scale data operations
Compare performance characteristics of different file systems (ext4, xfs, btrfs)
Implement file system optimization strategies for production environments
Measure and analyze file system performance improvements using benchmarking tools
Apply best practices for file system tuning in enterprise Linux environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux file systems and mount points
Familiarity with command-line operations and text editors
Knowledge of Linux system administration fundamentals
Understanding of storage concepts and disk partitioning
Experience with performance monitoring tools
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click "Start Lab" to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
Multiple storage devices for testing different file systems
Pre-installed performance monitoring and benchmarking tools
Sample datasets for performance testing
Task 1: Configure Advanced Mount Options for Performance
Subtask 1.1: Understanding File System Mount Options
First, let's examine the current mount options and understand their impact on performance.

Step 1: Check current mount options for all file systems

# Display current mount points and options
mount | grep -E "(ext4|xfs|btrfs)"

# Show detailed mount information
cat /proc/mounts | grep -E "(ext4|xfs|btrfs)"

# Check current file system usage
df -h
Step 2: Create a test directory and examine default behavior

# Create a test directory
mkdir -p /opt/fstest
cd /opt/fstest

# Create a test file to observe access time behavior
echo "Test file for access time monitoring" > testfile.txt

# Check initial timestamps
stat testfile.txt
Subtask 1.2: Implementing noatime and nodiratime Options
The noatime and nodiratime options prevent the system from updating access times, significantly improving performance for read-heavy workloads.

Step 1: Create a test partition for optimization

# Create a test file to simulate a partition (if no spare partition available)
dd if=/dev/zero of=/opt/testfs.img bs=1M count=1024

# Create a loop device
losetup /dev/loop0 /opt/testfs.img

# Format with ext4
mkfs.ext4 /dev/loop0

# Create mount point
mkdir -p /mnt/optimized-fs
Step 2: Mount with default options and test performance

# Mount with default options
mount /dev/loop0 /mnt/optimized-fs

# Create test script for baseline performance
cat > /opt/fstest/baseline_test.sh << 'EOF'
#!/bin/bash
echo "=== Baseline Performance Test ==="
cd /mnt/optimized-fs

# Create test files
echo "Creating test files..."
time for i in {1..1000}; do
    echo "Test data $i" > file_$i.txt
done

# Read test files multiple times
echo "Reading test files..."
time for j in {1..5}; do
    for i in {1..1000}; do
        cat file_$i.txt > /dev/null
    done
done

# Check access times
echo "Sample file timestamps:"
stat file_1.txt | grep -E "(Access|Modify|Change)"
EOF

chmod +x /opt/fstest/baseline_test.sh
Step 3: Run baseline test

# Execute baseline test
/opt/fstest/baseline_test.sh
Step 4: Remount with optimized options

# Unmount the file system
umount /mnt/optimized-fs

# Remount with noatime and nodiratime options
mount -o noatime,nodiratime /dev/loop0 /mnt/optimized-fs

# Verify mount options
mount | grep optimized-fs
Step 5: Create optimized performance test

cat > /opt/fstest/optimized_test.sh << 'EOF'
#!/bin/bash
echo "=== Optimized Performance Test ==="
cd /mnt/optimized-fs

# Clean previous test files
rm -f file_*.txt

# Create test files
echo "Creating test files with optimized mount..."
time for i in {1..1000}; do
    echo "Test data $i" > file_$i.txt
done

# Read test files multiple times
echo "Reading test files with optimized mount..."
time for j in {1..5}; do
    for i in {1..1000}; do
        cat file_$i.txt > /dev/null
    done
done

# Check access times (should not update)
echo "Sample file timestamps after reads:"
stat file_1.txt | grep -E "(Access|Modify|Change)"
EOF

chmod +x /opt/fstest/optimized_test.sh
Step 6: Run optimized test and compare results

# Execute optimized test
/opt/fstest/optimized_test.sh
Subtask 1.3: Implementing Additional Performance Mount Options
Step 1: Configure advanced ext4 mount options

# Unmount and remount with additional optimizations
umount /mnt/optimized-fs

# Mount with comprehensive optimization options
mount -o noatime,nodiratime,data=writeback,barrier=0,nobh /dev/loop0 /mnt/optimized-fs

# Verify new mount options
mount | grep optimized-fs
Step 2: Create comprehensive performance test

cat > /opt/fstest/comprehensive_test.sh << 'EOF'
#!/bin/bash
echo "=== Comprehensive Performance Test ==="
cd /mnt/optimized-fs

# Clean previous test files
rm -f file_*.txt large_file.dat

# Test 1: Small file operations
echo "Test 1: Small file I/O performance"
time for i in {1..2000}; do
    echo "Test data for file $i with timestamp $(date)" > small_file_$i.txt
done

# Test 2: Large file operations
echo "Test 2: Large file I/O performance"
time dd if=/dev/zero of=large_file.dat bs=1M count=100 2>/dev/null

# Test 3: Directory operations
echo "Test 3: Directory operations"
time for i in {1..100}; do
    mkdir -p dir_$i
    touch dir_$i/file_{1..10}.txt
done

# Test 4: File deletion performance
echo "Test 4: File deletion performance"
time rm -rf dir_* small_file_*.txt large_file.dat

echo "Comprehensive test completed"
EOF

chmod +x /opt/fstest/comprehensive_test.sh
/opt/fstest/comprehensive_test.sh
Task 2: Tune File System Types and Options
Subtask 2.1: Configuring ext4 File System Parameters
Step 1: Create and configure ext4 with custom parameters

# Create another test image for ext4 tuning
dd if=/dev/zero of=/opt/ext4_tuned.img bs=1M count=1024

# Setup loop device
losetup /dev/loop1 /opt/ext4_tuned.img

# Format with optimized ext4 parameters
mkfs.ext4 -b 4096 -E stride=32,stripe-width=64 -O ^has_journal /dev/loop1

# Create mount point
mkdir -p /mnt/ext4-tuned
Step 2: Configure ext4 with performance-oriented options

# Mount with optimized ext4 options
mount -o noatime,nodiratime,data=writeback,commit=60,barrier=0 /dev/loop1 /mnt/ext4-tuned

# Verify mount options
mount | grep ext4-tuned
Step 3: Tune ext4 runtime parameters

# Adjust read-ahead settings
echo 4096 > /sys/block/loop1/queue/read_ahead_kb

# Configure I/O scheduler
echo deadline > /sys/block/loop1/queue/scheduler

# Verify settings
cat /sys/block/loop1/queue/read_ahead_kb
cat /sys/block/loop1/queue/scheduler
Subtask 2.2: Configuring XFS File System Parameters
Step 1: Create and configure XFS file system

# Create test image for XFS
dd if=/dev/zero of=/opt/xfs_tuned.img bs=1M count=1024

# Setup loop device
losetup /dev/loop2 /opt/xfs_tuned.img

# Format with optimized XFS parameters
mkfs.xfs -b size=4096 -d agcount=4 -l size=64m /dev/loop2

# Create mount point
mkdir -p /mnt/xfs-tuned
Step 2: Mount XFS with performance options

# Mount with XFS-specific optimizations
mount -o noatime,nodiratime,logbufs=8,logbsize=256k,largeio,inode64 /dev/loop2 /mnt/xfs-tuned

# Verify mount options
mount | grep xfs-tuned
Step 3: Configure XFS runtime parameters

# Set XFS-specific parameters
echo 65536 > /sys/fs/xfs/loop2/log_recovery_delay
echo 1 > /sys/fs/xfs/loop2/irix_sgid_inherit
echo 1 > /sys/fs/xfs/loop2/irix_symlink_mode

# Verify XFS configuration
ls -la /sys/fs/xfs/loop2/
Subtask 2.3: Configuring Btrfs File System Parameters
Step 1: Create and configure Btrfs file system

# Create test image for Btrfs
dd if=/dev/zero of=/opt/btrfs_tuned.img bs=1M count=1024

# Setup loop device
losetup /dev/loop3 /opt/btrfs_tuned.img

# Format with Btrfs
mkfs.btrfs -f /dev/loop3

# Create mount point
mkdir -p /mnt/btrfs-tuned
Step 2: Mount Btrfs with performance options

# Mount with Btrfs-specific optimizations
mount -o noatime,nodiratime,compress=lzo,space_cache=v2,commit=60 /dev/loop3 /mnt/btrfs-tuned

# Verify mount options
mount | grep btrfs-tuned
Step 3: Configure Btrfs-specific features

# Enable Btrfs optimizations
btrfs filesystem defragment -r -v -clzo /mnt/btrfs-tuned

# Check Btrfs filesystem information
btrfs filesystem show /mnt/btrfs-tuned
btrfs filesystem usage /mnt/btrfs-tuned
Task 3: Test and Compare Different File Systems
Subtask 3.1: Create Standardized Performance Tests
Step 1: Create comprehensive benchmark script

cat > /opt/fstest/filesystem_benchmark.sh << 'EOF'
#!/bin/bash

# Function to run benchmark on a specific mount point
run_benchmark() {
    local mount_point=$1
    local fs_type=$2
    
    echo "========================================="
    echo "Benchmarking $fs_type at $mount_point"
    echo "========================================="
    
    cd $mount_point
    
    # Clean any existing test files
    rm -rf benchmark_test_*
    
    # Test 1: Sequential write performance
    echo "Test 1: Sequential Write (100MB file)"
    sync && echo 3 > /proc/sys/vm/drop_caches
    time dd if=/dev/zero of=benchmark_test_seq_write.dat bs=1M count=100 oflag=direct 2>/dev/null
    
    # Test 2: Sequential read performance
    echo "Test 2: Sequential Read (100MB file)"
    sync && echo 3 > /proc/sys/vm/drop_caches
    time dd if=benchmark_test_seq_write.dat of=/dev/null bs=1M iflag=direct 2>/dev/null
    
    # Test 3: Random small file creation
    echo "Test 3: Small File Creation (1000 files)"
    sync && echo 3 > /proc/sys/vm/drop_caches
    time for i in {1..1000}; do
        echo "Test data $i $(date)" > benchmark_test_small_$i.txt
    done
    
    # Test 4: Random small file reading
    echo "Test 4: Small File Reading (1000 files)"
    sync && echo 3 > /proc/sys/vm/drop_caches
    time for i in {1..1000}; do
        cat benchmark_test_small_$i.txt > /dev/null
    done
    
    # Test 5: Directory operations
    echo "Test 5: Directory Operations"
    sync && echo 3 > /proc/sys/vm/drop_caches
    time for i in {1..100}; do
        mkdir -p benchmark_test_dir_$i
        touch benchmark_test_dir_$i/file_{1..10}.txt
    done
    
    # Test 6: File deletion
    echo "Test 6: File Deletion"
    sync && echo 3 > /proc/sys/vm/drop_caches
    time rm -rf benchmark_test_*
    
    echo "Benchmark completed for $fs_type"
    echo ""
}

# Run benchmarks on all file systems
run_benchmark "/mnt/ext4-tuned" "EXT4"
run_benchmark "/mnt/xfs-tuned" "XFS"
run_benchmark "/mnt/btrfs-tuned" "BTRFS"

echo "All benchmarks completed!"
EOF

chmod +x /opt/fstest/filesystem_benchmark.sh
Step 2: Run comprehensive benchmarks

# Execute the benchmark script
/opt/fstest/filesystem_benchmark.sh | tee /opt/fstest/benchmark_results.txt
Subtask 3.2: Advanced Performance Analysis
Step 1: Create I/O monitoring script

cat > /opt/fstest/io_monitor.sh << 'EOF'
#!/bin/bash

echo "Starting I/O monitoring for file system comparison..."

# Function to monitor I/O for a specific device
monitor_io() {
    local device=$1
    local fs_type=$2
    local mount_point=$3
    
    echo "Monitoring $fs_type ($device) at $mount_point"
    
    # Start iostat monitoring in background
    iostat -x 1 10 $device > /tmp/iostat_${fs_type}.log &
    local iostat_pid=$!
    
    # Run a mixed workload
    cd $mount_point
    
    # Mixed workload: create, read, modify files
    for i in {1..100}; do
        # Create file
        dd if=/dev/urandom of=workload_file_$i.dat bs=1k count=100 2>/dev/null
        
        # Read file
        cat workload_file_$i.dat > /dev/null
        
        # Modify file
        echo "Modified at $(date)" >> workload_file_$i.dat
        
        # Random sleep to simulate real workload
        sleep 0.1
    done
    
    # Stop iostat monitoring
    kill $iostat_pid 2>/dev/null
    wait $iostat_pid 2>/dev/null
    
    # Clean up
    rm -f workload_file_*.dat
    
    echo "I/O monitoring completed for $fs_type"
}

# Monitor each file system
monitor_io "loop1" "EXT4" "/mnt/ext4-tuned"
monitor_io "loop2" "XFS" "/mnt/xfs-tuned"
monitor_io "loop3" "BTRFS" "/mnt/btrfs-tuned"

echo "I/O monitoring completed for all file systems"
echo "Results saved in /tmp/iostat_*.log files"
EOF

chmod +x /opt/fstest/io_monitor.sh
Step 2: Execute I/O monitoring

# Run I/O monitoring
/opt/fstest/io_monitor.sh

# Analyze results
echo "=== EXT4 I/O Statistics ==="
tail -5 /tmp/iostat_EXT4.log

echo "=== XFS I/O Statistics ==="
tail -5 /tmp/iostat_XFS.log

echo "=== BTRFS I/O Statistics ==="
tail -5 /tmp/iostat_BTRFS.log
Subtask 3.3: Memory and CPU Impact Analysis
Step 1: Create resource usage monitoring script

cat > /opt/fstest/resource_monitor.sh << 'EOF'
#!/bin/bash

echo "Analyzing resource usage for different file systems..."

# Function to monitor resource usage during file operations
monitor_resources() {
    local mount_point=$1
    local fs_type=$2
    
    echo "Testing resource usage for $fs_type"
    
    # Start monitoring
    top -b -n 1 | head -5 > /tmp/cpu_before_${fs_type}.log
    free -h > /tmp/memory_before_${fs_type}.log
    
    cd $mount_point
    
    # CPU and memory intensive file operations
    echo "Running intensive file operations..."
    
    # Create large files with compression (for btrfs)
    time for i in {1..50}; do
        dd if=/dev/urandom of=resource_test_$i.dat bs=1M count=10 2>/dev/null
        
        # Simulate file processing
        gzip resource_test_$i.dat
        gunzip resource_test_$i.dat.gz
    done
    
    # Monitor after operations
    top -b -n 1 | head -5 > /tmp/cpu_after_${fs_type}.log
    free -h > /tmp/memory_after_${fs_type}.log
    
    # Clean up
    rm -f resource_test_*.dat*
    
    echo "Resource monitoring completed for $fs_type"
}

# Test each file system
monitor_resources "/mnt/ext4-tuned" "EXT4"
monitor_resources "/mnt/xfs-tuned" "XFS"
monitor_resources "/mnt/btrfs-tuned" "BTRFS"

echo "Resource usage analysis completed"
EOF

chmod +x /opt/fstest/resource_monitor.sh
/opt/fstest/resource_monitor.sh
Step 2: Generate performance comparison report

cat > /opt/fstest/generate_report.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "FILE SYSTEM PERFORMANCE COMPARISON REPORT"
echo "========================================="
echo "Generated on: $(date)"
echo ""

echo "1. MOUNT OPTIONS COMPARISON"
echo "----------------------------"
echo "EXT4 Mount Options:"
mount | grep ext4-tuned | awk '{print $6}'
echo ""
echo "XFS Mount Options:"
mount | grep xfs-tuned | awk '{print $6}'
echo ""
echo "BTRFS Mount Options:"
mount | grep btrfs-tuned | awk '{print $6}'
echo ""

echo "2. DISK USAGE COMPARISON"
echo "------------------------"
df -h | grep -E "(ext4-tuned|xfs-tuned|btrfs-tuned)"
echo ""

echo "3. FILE SYSTEM FEATURES"
echo "-----------------------"
echo "EXT4 Features:"
tune2fs -l /dev/loop1 | grep "Filesystem features"
echo ""
echo "XFS Features:"
xfs_info /mnt/xfs-tuned | head -3
echo ""
echo "BTRFS Features:"
btrfs filesystem show /dev/loop3 | head -3
echo ""

echo "4. PERFORMANCE RECOMMENDATIONS"
echo "------------------------------"
echo "Based on the tests performed:"
echo ""
echo "• EXT4: Best for general-purpose workloads with good balance of performance and stability"
echo "• XFS: Excellent for large files and high-throughput applications"
echo "• BTRFS: Good for scenarios requiring advanced features like compression and snapshots"
echo ""
echo "• noatime/nodiratime options provide significant performance improvements"
echo "• Proper I/O scheduler selection is crucial for optimal performance"
echo "• File system block size should match workload characteristics"
echo ""

echo "Report generation completed"
EOF

chmod +x /opt/fstest/generate_report.sh
/opt/fstest/generate_report.sh | tee /opt/fstest/performance_report.txt
Troubleshooting Common Issues
Issue 1: Loop Device Management
If you encounter issues with loop devices:

# Check available loop devices
losetup -a

# Detach loop devices if needed
losetup -d /dev/loop0
losetup -d /dev/loop1
losetup -d /dev/loop2
losetup -d /dev/loop3

# Find next available loop device
losetup -f
Issue 2: Mount Permission Issues
If you encounter permission errors:

# Ensure proper permissions
chmod 755 /mnt/ext4-tuned /mnt/xfs-tuned /mnt/btrfs-tuned

# Check SELinux context if applicable
ls -Z /mnt/
Issue 3: Performance Test Inconsistencies
To ensure consistent performance testing:

# Clear system caches before each test
sync
echo 3 > /proc/sys/vm/drop_caches

# Ensure no other processes are interfering
iostat -x 1 1
Lab Cleanup
Step 1: Unmount all test file systems

# Unmount all test file systems
umount /mnt/optimized-fs 2>/dev/null
umount /mnt/ext4-tuned 2>/dev/null
umount /mnt/xfs-tuned 2>/dev/null
umount /mnt/btrfs-tuned 2>/dev/null
Step 2: Detach loop devices

# Detach all loop devices
losetup -d /dev/loop0 2>/dev/null
losetup -d /dev/loop1 2>/dev/null
losetup -d /dev/loop2 2>/dev/null
losetup -d /dev/loop3 2>/dev/null
Step 3: Clean up test files

# Remove test images and temporary files
rm -f /opt/testfs.img /opt/ext4_tuned.img /opt/xfs_tuned.img /opt/btrfs_tuned.img
rm -f /tmp/iostat_*.log /tmp/cpu_*.log /tmp/memory_*.log

# Keep results for review
echo "Lab results saved in /opt/fstest/ directory"
ls -la /opt/fstest/
Conclusion
In this comprehensive lab, you have successfully:

Accomplished Key Learning Objectives:

Configured advanced mount options including noatime, nodiratime, and file system-specific optimizations that can improve performance by 15-30% in read-heavy workloads
Implemented file system tuning for ext4, XFS, and Btrfs with parameters optimized for different use cases and workload patterns
Conducted comparative performance analysis using standardized benchmarks to understand the strengths and weaknesses of different file systems
Applied enterprise-grade optimization techniques that are directly applicable to production environments handling large-scale data operations
Why This Matters: File system optimization is crucial for enterprise Linux environments because it directly impacts application performance, system responsiveness, and resource utilization. The techniques you've learned can:

Reduce I/O latency by up to 40% through proper mount option configuration
Improve throughput for data-intensive applications like databases and web servers
Optimize resource usage leading to better system scalability and cost efficiency
Enable informed decision-making when selecting file systems for specific workloads
Real-World Applications: These skills are essential for Linux system administrators working with:

High-performance computing environments
Database servers requiring optimal I/O performance
Web servers handling large numbers of concurrent requests
Storage systems managing big data workloads
Cloud infrastructure requiring efficient resource utilization
The performance tuning techniques demonstrated in this lab are directly applicable to Red Hat Enterprise Linux environments and align with industry best practices for production system optimization.
