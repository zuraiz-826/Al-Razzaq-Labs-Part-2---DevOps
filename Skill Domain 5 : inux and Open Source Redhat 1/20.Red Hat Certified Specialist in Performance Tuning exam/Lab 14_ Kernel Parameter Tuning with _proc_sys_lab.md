Lab 14: Kernel Parameter Tuning with /proc/sys
Objectives
By the end of this lab, students will be able to:

Navigate and explore the /proc/sys filesystem to understand kernel parameters
View current kernel parameter values and understand their impact on system performance
Modify kernel parameters at runtime using the /proc/sys interface
Tune critical performance parameters including vm.swappiness and net.ipv4.tcp_rmem
Test and validate system performance improvements after parameter adjustments
Make kernel parameter changes persistent across system reboots
Understand the relationship between kernel tuning and system optimization
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and basic shell commands
Knowledge of file system navigation and text editing
Understanding of system performance concepts (memory, network, I/O)
Basic knowledge of TCP/IP networking concepts
Experience with system monitoring tools
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment - no need to build your own virtual machine or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS system
Root access for kernel parameter modifications
Pre-installed monitoring tools
Network connectivity for testing
Task 1: Explore /proc/sys to View and Modify Kernel Parameters
Subtask 1.1: Understanding the /proc/sys Filesystem Structure
The /proc/sys directory provides a runtime interface to kernel parameters, allowing administrators to view and modify system behavior without recompiling the kernel.

Step 1: Connect to your lab environment and explore the basic structure:

# Navigate to the /proc/sys directory
cd /proc/sys

# List the main categories of kernel parameters
ls -la
Step 2: Examine the major subdirectories:

# View kernel parameters
ls -la kernel/

# View virtual memory parameters
ls -la vm/

# View network parameters
ls -la net/

# View filesystem parameters
ls -la fs/
Subtask 1.2: Viewing Current Kernel Parameters
Step 3: Check current system parameter values:

# View current swappiness value
cat /proc/sys/vm/swappiness

# View current TCP receive memory settings
cat /proc/sys/net/ipv4/tcp_rmem

# View current TCP send memory settings
cat /proc/sys/net/ipv4/tcp_wmem

# View current maximum number of open files
cat /proc/sys/fs/file-max
Step 4: Use the sysctl command to view parameters:

# View all kernel parameters (this will be a long list)
sysctl -a | head -20

# View specific parameter
sysctl vm.swappiness

# View all VM-related parameters
sysctl vm. | head -10

# View all network-related parameters
sysctl net.ipv4. | head -10
Subtask 1.3: Understanding Parameter Documentation
Step 5: Create a script to document current baseline settings:

# Create a baseline documentation script
cat > baseline_check.sh << 'EOF'
#!/bin/bash

echo "=== System Baseline Parameters ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""

echo "=== Memory Management Parameters ==="
echo "vm.swappiness: $(cat /proc/sys/vm/swappiness)"
echo "vm.dirty_ratio: $(cat /proc/sys/vm/dirty_ratio)"
echo "vm.dirty_background_ratio: $(cat /proc/sys/vm/dirty_background_ratio)"
echo "vm.vfs_cache_pressure: $(cat /proc/sys/vm/vfs_cache_pressure)"
echo ""

echo "=== Network Parameters ==="
echo "net.ipv4.tcp_rmem: $(cat /proc/sys/net/ipv4/tcp_rmem)"
echo "net.ipv4.tcp_wmem: $(cat /proc/sys/net/ipv4/tcp_wmem)"
echo "net.core.rmem_max: $(cat /proc/sys/net/core/rmem_max)"
echo "net.core.wmem_max: $(cat /proc/sys/net/core/wmem_max)"
echo ""

echo "=== File System Parameters ==="
echo "fs.file-max: $(cat /proc/sys/fs/file-max)"
echo "fs.inotify.max_user_watches: $(cat /proc/sys/fs/inotify/max_user_watches)"
EOF

# Make the script executable
chmod +x baseline_check.sh

# Run the baseline check
./baseline_check.sh
Task 2: Tune Parameters like vm.swappiness and net.ipv4.tcp_rmem
Subtask 2.1: Understanding and Tuning vm.swappiness
The vm.swappiness parameter controls how aggressively the kernel swaps memory pages to disk. Values range from 0 to 100.

Step 6: Understand current memory usage:

# Check current memory usage
free -h

# Check swap usage
swapon --show

# View detailed memory information
cat /proc/meminfo | grep -E "(MemTotal|MemFree|SwapTotal|SwapFree)"
Step 7: Modify vm.swappiness parameter:

# View current swappiness value
echo "Current swappiness: $(cat /proc/sys/vm/swappiness)"

# Method 1: Direct file modification
echo 10 > /proc/sys/vm/swappiness

# Verify the change
cat /proc/sys/vm/swappiness

# Method 2: Using sysctl command
sysctl vm.swappiness=20

# Verify using sysctl
sysctl vm.swappiness
Step 8: Create a memory pressure test:

# Create a script to simulate memory pressure
cat > memory_test.sh << 'EOF'
#!/bin/bash

echo "=== Memory Pressure Test ==="
echo "Initial memory state:"
free -h

echo ""
echo "Creating memory pressure..."

# Create a process that consumes memory
stress --vm 1 --vm-bytes 512M --timeout 30s &
STRESS_PID=$!

# Monitor memory usage during stress
for i in {1..10}; do
    echo "Time: ${i}0s"
    free -h | grep -E "(Mem:|Swap:)"
    echo "Swappiness: $(cat /proc/sys/vm/swappiness)"
    echo "---"
    sleep 3
done

# Wait for stress test to complete
wait $STRESS_PID
echo "Memory pressure test completed"
EOF

chmod +x memory_test.sh
Subtask 2.2: Tuning Network TCP Memory Parameters
Step 9: Understand TCP memory parameters:

# View current TCP receive memory settings
echo "TCP receive memory (min default max): $(cat /proc/sys/net/ipv4/tcp_rmem)"

# View current TCP send memory settings  
echo "TCP send memory (min default max): $(cat /proc/sys/net/ipv4/tcp_wmem)"

# View maximum socket receive buffer
echo "Max receive buffer: $(cat /proc/sys/net/core/rmem_max)"

# View maximum socket send buffer
echo "Max send buffer: $(cat /proc/sys/net/core/wmem_max)"
Step 10: Tune TCP memory parameters for better performance:

# Increase TCP receive memory buffers
# Format: min default max (in bytes)
echo "4096 87380 16777216" > /proc/sys/net/ipv4/tcp_rmem

# Increase TCP send memory buffers
echo "4096 65536 16777216" > /proc/sys/net/ipv4/tcp_wmem

# Increase maximum socket buffer sizes
echo 16777216 > /proc/sys/net/core/rmem_max
echo 16777216 > /proc/sys/net/core/wmem_max

# Verify changes
echo "New TCP rmem: $(cat /proc/sys/net/ipv4/tcp_rmem)"
echo "New TCP wmem: $(cat /proc/sys/net/ipv4/tcp_wmem)"
echo "New rmem_max: $(cat /proc/sys/net/core/rmem_max)"
echo "New wmem_max: $(cat /proc/sys/net/core/wmem_max)"
Subtask 2.3: Additional Performance Tuning Parameters
Step 11: Tune additional system parameters:

# Increase the maximum number of open files
echo 1048576 > /proc/sys/fs/file-max

# Tune dirty page parameters for better I/O performance
echo 15 > /proc/sys/vm/dirty_ratio
echo 5 > /proc/sys/vm/dirty_background_ratio

# Reduce cache pressure for better performance
echo 50 > /proc/sys/vm/vfs_cache_pressure

# Verify all changes
echo "=== Updated Parameters ==="
echo "fs.file-max: $(cat /proc/sys/fs/file-max)"
echo "vm.dirty_ratio: $(cat /proc/sys/vm/dirty_ratio)"
echo "vm.dirty_background_ratio: $(cat /proc/sys/vm/dirty_background_ratio)"
echo "vm.vfs_cache_pressure: $(cat /proc/sys/vm/vfs_cache_pressure)"
Task 3: Test System Performance with Adjustments
Subtask 3.1: Create Performance Testing Scripts
Step 12: Create a comprehensive performance testing suite:

# Create network performance test script
cat > network_test.sh << 'EOF'
#!/bin/bash

echo "=== Network Performance Test ==="
echo "Testing with current TCP buffer settings:"
echo "TCP rmem: $(cat /proc/sys/net/ipv4/tcp_rmem)"
echo "TCP wmem: $(cat /proc/sys/net/ipv4/tcp_wmem)"
echo ""

# Test network throughput using iperf3 (if available) or nc
if command -v iperf3 &> /dev/null; then
    echo "Starting iperf3 server in background..."
    iperf3 -s -p 5001 &
    SERVER_PID=$!
    sleep 2
    
    echo "Running iperf3 client test..."
    iperf3 -c localhost -p 5001 -t 10
    
    kill $SERVER_PID
else
    echo "iperf3 not available, using basic network test"
    # Simple network test using netcat
    echo "Testing basic network connectivity..."
    nc -l 8080 &
    NC_PID=$!
    sleep 1
    echo "Network test data" | nc localhost 8080
    kill $NC_PID 2>/dev/null
fi
EOF

chmod +x network_test.sh
Step 13: Create I/O performance test script:

# Create I/O performance test script
cat > io_test.sh << 'EOF'
#!/bin/bash

echo "=== I/O Performance Test ==="
echo "Current dirty page settings:"
echo "vm.dirty_ratio: $(cat /proc/sys/vm/dirty_ratio)"
echo "vm.dirty_background_ratio: $(cat /proc/sys/vm/dirty_background_ratio)"
echo ""

# Create test directory
mkdir -p /tmp/io_test
cd /tmp/io_test

echo "Testing write performance..."
# Test write performance
time dd if=/dev/zero of=test_file bs=1M count=100 2>&1

echo ""
echo "Testing read performance..."
# Clear cache and test read performance
sync
echo 3 > /proc/sys/vm/drop_caches
time dd if=test_file of=/dev/null bs=1M 2>&1

echo ""
echo "Testing random I/O performance..."
# Test random I/O if available
if command -v fio &> /dev/null; then
    fio --name=random-rw --ioengine=posixaio --rw=randrw --bs=4k --size=100M --numjobs=1 --runtime=30 --group_reporting
else
    echo "fio not available, using basic random I/O test"
    time dd if=/dev/urandom of=random_test bs=4k count=1000 2>&1
fi

# Cleanup
rm -f test_file random_test
cd /
rmdir /tmp/io_test
EOF

chmod +x io_test.sh
Subtask 3.2: Performance Monitoring and Comparison
Step 14: Create a monitoring script to track system performance:

# Create system monitoring script
cat > monitor_performance.sh << 'EOF'
#!/bin/bash

DURATION=${1:-60}
INTERVAL=${2:-5}

echo "=== System Performance Monitor ==="
echo "Monitoring for $DURATION seconds with $INTERVAL second intervals"
echo "Current kernel parameters:"
echo "vm.swappiness: $(cat /proc/sys/vm/swappiness)"
echo "vm.dirty_ratio: $(cat /proc/sys/vm/dirty_ratio)"
echo "TCP rmem: $(cat /proc/sys/net/ipv4/tcp_rmem)"
echo ""

# Create log file
LOG_FILE="/tmp/performance_$(date +%Y%m%d_%H%M%S).log"
echo "Logging to: $LOG_FILE"

# Monitor system performance
for ((i=0; i<$DURATION; i+=$INTERVAL)); do
    echo "=== Time: $(date) ===" >> $LOG_FILE
    
    # Memory usage
    echo "Memory Usage:" >> $LOG_FILE
    free -h >> $LOG_FILE
    
    # CPU usage
    echo "CPU Usage:" >> $LOG_FILE
    top -bn1 | grep "Cpu(s)" >> $LOG_FILE
    
    # I/O statistics
    echo "I/O Statistics:" >> $LOG_FILE
    iostat -x 1 1 >> $LOG_FILE 2>/dev/null || echo "iostat not available" >> $LOG_FILE
    
    # Network statistics
    echo "Network Statistics:" >> $LOG_FILE
    cat /proc/net/dev | head -3 >> $LOG_FILE
    
    echo "" >> $LOG_FILE
    
    # Display progress
    echo "Monitoring... $((i+$INTERVAL))/$DURATION seconds"
    sleep $INTERVAL
done

echo "Monitoring complete. Log saved to: $LOG_FILE"
echo "Last 20 lines of log:"
tail -20 $LOG_FILE
EOF

chmod +x monitor_performance.sh
Subtask 3.3: Before and After Performance Testing
Step 15: Test performance with default settings:

# Reset parameters to default values for baseline test
echo 60 > /proc/sys/vm/swappiness
echo "4096 87380 6291456" > /proc/sys/net/ipv4/tcp_rmem
echo "4096 16384 4194304" > /proc/sys/net/ipv4/tcp_wmem

echo "=== Baseline Performance Test ==="
echo "Running with default parameters..."

# Run baseline tests
./baseline_check.sh > baseline_results.txt
./io_test.sh > baseline_io_results.txt
Step 16: Test performance with optimized settings:

# Apply optimized parameters
echo 10 > /proc/sys/vm/swappiness
echo "4096 87380 16777216" > /proc/sys/net/ipv4/tcp_rmem
echo "4096 65536 16777216" > /proc/sys/net/ipv4/tcp_wmem
echo 16777216 > /proc/sys/net/core/rmem_max
echo 16777216 > /proc/sys/net/core/wmem_max
echo 15 > /proc/sys/vm/dirty_ratio
echo 5 > /proc/sys/vm/dirty_background_ratio

echo "=== Optimized Performance Test ==="
echo "Running with tuned parameters..."

# Run optimized tests
./baseline_check.sh > optimized_results.txt
./io_test.sh > optimized_io_results.txt
Subtask 3.4: Making Changes Persistent
Step 17: Configure persistent kernel parameter changes:

# Create sysctl configuration file for persistent changes
cat > /etc/sysctl.d/99-performance-tuning.conf << 'EOF'
# Performance tuning parameters
# Memory management
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50

# Network tuning
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# File system tuning
fs.file-max = 1048576
EOF

# Apply the configuration
sysctl -p /etc/sysctl.d/99-performance-tuning.conf

# Verify persistent configuration
echo "=== Persistent Configuration Applied ==="
sysctl -p /etc/sysctl.d/99-performance-tuning.conf
Step 18: Create a validation script:

# Create validation script
cat > validate_tuning.sh << 'EOF'
#!/bin/bash

echo "=== Kernel Parameter Validation ==="
echo "Checking if all tuned parameters are correctly applied..."
echo ""

# Define expected values
declare -A expected_params=(
    ["vm.swappiness"]="10"
    ["vm.dirty_ratio"]="15"
    ["vm.dirty_background_ratio"]="5"
    ["vm.vfs_cache_pressure"]="50"
    ["net.core.rmem_max"]="16777216"
    ["net.core.wmem_max"]="16777216"
    ["fs.file-max"]="1048576"
)

# Check each parameter
all_correct=true
for param in "${!expected_params[@]}"; do
    current_value=$(sysctl -n $param)
    expected_value=${expected_params[$param]}
    
    if [ "$current_value" = "$expected_value" ]; then
        echo "✓ $param: $current_value (correct)"
    else
        echo "✗ $param: $current_value (expected: $expected_value)"
        all_correct=false
    fi
done

# Check TCP memory parameters separately (they have multiple values)
tcp_rmem_current=$(cat /proc/sys/net/ipv4/tcp_rmem)
tcp_rmem_expected="4096 87380 16777216"
if [ "$tcp_rmem_current" = "$tcp_rmem_expected" ]; then
    echo "✓ net.ipv4.tcp_rmem: $tcp_rmem_current (correct)"
else
    echo "✗ net.ipv4.tcp_rmem: $tcp_rmem_current (expected: $tcp_rmem_expected)"
    all_correct=false
fi

tcp_wmem_current=$(cat /proc/sys/net/ipv4/tcp_wmem)
tcp_wmem_expected="4096 65536 16777216"
if [ "$tcp_wmem_current" = "$tcp_wmem_expected" ]; then
    echo "✓ net.ipv4.tcp_wmem: $tcp_wmem_current (correct)"
else
    echo "✗ net.ipv4.tcp_wmem: $tcp_wmem_current (expected: $tcp_wmem_expected)"
    all_correct=false
fi

echo ""
if [ "$all_correct" = true ]; then
    echo "🎉 All kernel parameters are correctly tuned!"
else
    echo "⚠️  Some parameters need adjustment. Please review the configuration."
fi
EOF

chmod +x validate_tuning.sh
./validate_tuning.sh
Troubleshooting Common Issues
Issue 1: Permission Denied When Modifying Parameters
Problem: Getting "Permission denied" when trying to modify /proc/sys files.

Solution:

# Ensure you have root privileges
sudo su -

# Or use sudo with each command
sudo echo 10 > /proc/sys/vm/swappiness
Issue 2: Changes Not Persisting After Reboot
Problem: Kernel parameter changes are lost after system reboot.

Solution:

# Always create persistent configuration
sudo nano /etc/sysctl.d/99-custom-tuning.conf

# Add your parameters to the file
# Apply with: sudo sysctl -p /etc/sysctl.d/99-custom-tuning.conf
Issue 3: Invalid Parameter Values
Problem: System rejects certain parameter values.

Solution:

# Check valid ranges for parameters
sysctl -a | grep parameter_name

# For vm.swappiness, valid range is 0-100
# For memory parameters, use reasonable values based on system RAM
Issue 4: Performance Testing Tools Not Available
Problem: Tools like iperf3, fio, or iostat are not installed.

Solution:

# Install performance testing tools
# On RHEL/CentOS:
sudo yum install iperf3 fio sysstat

# On Ubuntu/Debian:
sudo apt-get install iperf3 fio sysstat
Conclusion
In this comprehensive lab, you have successfully learned how to tune kernel parameters using the /proc/sys interface to optimize system performance. Here's what you accomplished:

Key Achievements:

Explored the /proc/sys Filesystem: You navigated through the kernel parameter interface and understood how different categories of parameters affect system behavior.

Mastered Parameter Modification: You learned multiple methods to view and modify kernel parameters, including direct file manipulation and the sysctl command.

Optimized Critical Parameters: You tuned essential performance parameters including:

vm.swappiness for memory management optimization
net.ipv4.tcp_rmem and net.ipv4.tcp_wmem for network performance
Various I/O and filesystem parameters for better system responsiveness
Implemented Performance Testing: You created comprehensive testing scripts to measure the impact of your tuning efforts and validate improvements.

Ensured Persistence: You learned how to make kernel parameter changes persistent across system reboots using /etc/sysctl.d/ configuration files.

Why This Matters:

Kernel parameter tuning is a critical skill for system administrators and performance engineers because it allows you to:

Optimize System Performance: Fine-tune your Linux systems for specific workloads and use cases
Improve Resource Utilization: Better manage memory, network, and I/O resources
Enhance Application Performance: Provide optimal system conditions for applications to perform efficiently
Troubleshoot Performance Issues: Identify and resolve system bottlenecks through parameter adjustment
Prepare for Certification: Master skills required for Red Hat Certified Specialist in Performance Tuning and similar certifications
Next Steps:

Practice tuning parameters for different workload types (database servers, web servers, high-performance computing)
Learn about advanced monitoring tools like perf, sar, and htop for deeper performance analysis
Explore container-specific kernel parameter tuning for Docker and Kubernetes environments
Study the impact of kernel parameters on security and stability
Remember that kernel parameter tuning requires careful testing and validation. Always document your changes, test thoroughly in non-production environments, and monitor system behavior after implementing changes. The skills you've developed in this lab form the foundation for advanced Linux system optimization and performance engineering.
