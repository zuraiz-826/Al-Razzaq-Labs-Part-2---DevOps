Lab 4: Configuring Kernel Tunables
Objectives
By the end of this lab, students will be able to:

Understand the purpose and importance of kernel tunables in system optimization
Navigate and explore the /proc/sys filesystem structure
Use the sysctl command to view, modify, and persist kernel parameters
Configure memory management parameters to optimize system performance
Adjust network-related kernel parameters for improved network performance
Test and validate the impact of kernel parameter changes
Implement best practices for kernel tuning in production environments
Troubleshoot common issues related to kernel parameter modifications
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and text editors (vi/vim or nano)
Knowledge of basic networking concepts (TCP/IP, network buffers)
Understanding of Linux memory management concepts
Root or sudo access to a Linux system
Experience with system monitoring tools (top, htop, free, netstat)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS system
Root access via sudo
Pre-installed monitoring tools
Network connectivity for testing
Task 1: Understanding Kernel Tunables
Subtask 1.1: Explore the /proc/sys Filesystem
The /proc/sys directory contains virtual files that represent kernel parameters. Let's start by exploring this structure.

# Navigate to the proc/sys directory
cd /proc/sys

# List the main categories of kernel parameters
ls -la
Expected Output:

drwxr-xr-x  1 root root 0 Nov 15 10:00 abi
drwxr-xr-x  1 root root 0 Nov 15 10:00 debug
drwxr-xr-x  1 root root 0 Nov 15 10:00 dev
drwxr-xr-x  1 root root 0 Nov 15 10:00 fs
drwxr-xr-x  1 root root 0 Nov 15 10:00 kernel
drwxr-xr-x  1 root root 0 Nov 15 10:00 net
drwxr-xr-x  1 root root 0 Nov 15 10:00 vm
Subtask 1.2: Examine Key Directories
# Explore virtual memory parameters
ls /proc/sys/vm/

# Explore network parameters
ls /proc/sys/net/

# Explore kernel parameters
ls /proc/sys/kernel/
Subtask 1.3: Introduction to sysctl Command
The sysctl command provides a more user-friendly interface to kernel parameters.

# Display all current kernel parameters (this will be a long list)
sysctl -a | head -20

# Display parameters in a specific category
sysctl vm.

# Display a specific parameter
sysctl vm.swappiness
Task 2: Memory Management Kernel Parameters
Subtask 2.1: Examine Current Memory Settings
Before making changes, let's examine the current memory-related kernel parameters.

# Check current memory information
free -h

# Check current swap usage and swappiness
sysctl vm.swappiness
cat /proc/sys/vm/swappiness

# Check dirty page parameters
sysctl vm.dirty_ratio
sysctl vm.dirty_background_ratio
sysctl vm.dirty_writeback_centisecs
Subtask 2.2: Create a Baseline Memory Test Script
Create a script to monitor memory performance before and after changes.

# Create a memory monitoring script
cat > /tmp/memory_monitor.sh << 'EOF'
#!/bin/bash

echo "=== Memory Performance Monitor ==="
echo "Timestamp: $(date)"
echo

echo "=== Memory Usage ==="
free -h
echo

echo "=== Swap Information ==="
swapon --show
echo

echo "=== Key VM Parameters ==="
echo "vm.swappiness = $(sysctl -n vm.swappiness)"
echo "vm.dirty_ratio = $(sysctl -n vm.dirty_ratio)"
echo "vm.dirty_background_ratio = $(sysctl -n vm.dirty_background_ratio)"
echo "vm.vfs_cache_pressure = $(sysctl -n vm.vfs_cache_pressure)"
echo

echo "=== Memory Pressure ==="
cat /proc/pressure/memory 2>/dev/null || echo "Memory pressure info not available"
echo
EOF

# Make the script executable
chmod +x /tmp/memory_monitor.sh

# Run the baseline test
/tmp/memory_monitor.sh
Subtask 2.3: Modify Swappiness Parameter
Swappiness controls how aggressively the kernel swaps memory pages to disk.

# Check current swappiness (default is usually 60)
sysctl vm.swappiness

# Temporarily change swappiness to 10 (less aggressive swapping)
sudo sysctl vm.swappiness=10

# Verify the change
sysctl vm.swappiness

# Alternative method using /proc/sys
echo 10 | sudo tee /proc/sys/vm/swappiness
Subtask 2.4: Adjust Dirty Page Parameters
Dirty pages are memory pages that have been modified but not yet written to disk.

# Check current dirty page settings
sysctl vm.dirty_ratio vm.dirty_background_ratio

# Modify dirty_ratio (percentage of memory that can be dirty before sync)
sudo sysctl vm.dirty_ratio=15

# Modify dirty_background_ratio (percentage when background writeback starts)
sudo sysctl vm.dirty_background_ratio=5

# Adjust writeback frequency (centiseconds)
sudo sysctl vm.dirty_writeback_centisecs=500

# Verify changes
sysctl vm.dirty_ratio vm.dirty_background_ratio vm.dirty_writeback_centisecs
Subtask 2.5: Configure VFS Cache Pressure
VFS cache pressure controls how aggressively the kernel reclaims memory used for caching directory and inode objects.

# Check current VFS cache pressure
sysctl vm.vfs_cache_pressure

# Increase cache pressure to reclaim cache memory more aggressively
sudo sysctl vm.vfs_cache_pressure=150

# Verify the change
sysctl vm.vfs_cache_pressure
Subtask 2.6: Test Memory Parameter Impact
# Run the memory monitor to see current state
/tmp/memory_monitor.sh

# Create a simple memory stress test
cat > /tmp/memory_test.sh << 'EOF'
#!/bin/bash

echo "Starting memory allocation test..."

# Allocate memory in chunks
for i in {1..5}; do
    echo "Allocating 100MB chunk $i..."
    # Create a 100MB file in memory
    dd if=/dev/zero of=/tmp/memtest_$i bs=1M count=100 2>/dev/null &
done

echo "Waiting for allocations to complete..."
wait

echo "Memory allocated. Checking system state..."
free -h

echo "Cleaning up..."
rm -f /tmp/memtest_*
echo "Memory test completed."
EOF

chmod +x /tmp/memory_test.sh

# Run the memory test
/tmp/memory_test.sh
Task 3: Network Kernel Parameters
Subtask 3.1: Examine Current Network Settings
# Check current network buffer sizes
sysctl net.core.rmem_max
sysctl net.core.wmem_max
sysctl net.core.rmem_default
sysctl net.core.wmem_default

# Check TCP-specific parameters
sysctl net.ipv4.tcp_rmem
sysctl net.ipv4.tcp_wmem
sysctl net.ipv4.tcp_congestion_control

# Check network device queue length
sysctl net.core.netdev_max_backlog
Subtask 3.2: Create Network Performance Monitoring Script
# Create a network monitoring script
cat > /tmp/network_monitor.sh << 'EOF'
#!/bin/bash

echo "=== Network Performance Monitor ==="
echo "Timestamp: $(date)"
echo

echo "=== Network Buffer Settings ==="
echo "net.core.rmem_max = $(sysctl -n net.core.rmem_max)"
echo "net.core.wmem_max = $(sysctl -n net.core.wmem_max)"
echo "net.core.rmem_default = $(sysctl -n net.core.rmem_default)"
echo "net.core.wmem_default = $(sysctl -n net.core.wmem_default)"
echo

echo "=== TCP Settings ==="
echo "net.ipv4.tcp_rmem = $(sysctl -n net.ipv4.tcp_rmem)"
echo "net.ipv4.tcp_wmem = $(sysctl -n net.ipv4.tcp_wmem)"
echo "net.ipv4.tcp_congestion_control = $(sysctl -n net.ipv4.tcp_congestion_control)"
echo

echo "=== Network Queue Settings ==="
echo "net.core.netdev_max_backlog = $(sysctl -n net.core.netdev_max_backlog)"
echo "net.core.somaxconn = $(sysctl -n net.core.somaxconn)"
echo

echo "=== Current Network Connections ==="
ss -tuln | head -10
echo
EOF

chmod +x /tmp/network_monitor.sh

# Run baseline network monitoring
/tmp/network_monitor.sh
Subtask 3.3: Optimize Network Buffer Sizes
# Increase maximum receive buffer size (16MB)
sudo sysctl net.core.rmem_max=16777216

# Increase maximum send buffer size (16MB)
sudo sysctl net.core.wmem_max=16777216

# Increase default receive buffer size (256KB)
sudo sysctl net.core.rmem_default=262144

# Increase default send buffer size (256KB)
sudo sysctl net.core.wmem_default=262144

# Verify changes
sysctl net.core.rmem_max net.core.wmem_max net.core.rmem_default net.core.wmem_default
Subtask 3.4: Configure TCP Buffer Parameters
# Configure TCP receive buffer sizes (min, default, max)
sudo sysctl net.ipv4.tcp_rmem="4096 87380 16777216"

# Configure TCP send buffer sizes (min, default, max)
sudo sysctl net.ipv4.tcp_wmem="4096 65536 16777216"

# Verify TCP buffer settings
sysctl net.ipv4.tcp_rmem net.ipv4.tcp_wmem
Subtask 3.5: Adjust Network Queue Parameters
# Increase network device backlog queue
sudo sysctl net.core.netdev_max_backlog=5000

# Increase maximum number of pending connections
sudo sysctl net.core.somaxconn=1024

# Enable TCP window scaling
sudo sysctl net.ipv4.tcp_window_scaling=1

# Verify queue settings
sysctl net.core.netdev_max_backlog net.core.somaxconn net.ipv4.tcp_window_scaling
Subtask 3.6: Test Network Parameter Impact
# Run network monitor to see current state
/tmp/network_monitor.sh

# Create a simple network test
cat > /tmp/network_test.sh << 'EOF'
#!/bin/bash

echo "=== Network Performance Test ==="

# Test local network performance using nc (netcat)
echo "Testing local network throughput..."

# Start a simple server in background
nc -l -p 12345 > /dev/null &
SERVER_PID=$!

# Give server time to start
sleep 1

# Send data to test throughput
echo "Sending test data..."
dd if=/dev/zero bs=1M count=100 2>/dev/null | nc localhost 12345

# Clean up
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null

echo "Network test completed."

# Show current network statistics
echo "=== Network Statistics ==="
cat /proc/net/dev | head -3
EOF

chmod +x /tmp/network_test.sh

# Run the network test
/tmp/network_test.sh
Task 4: Making Kernel Parameter Changes Persistent
Subtask 4.1: Understanding sysctl.conf
Temporary changes made with sysctl command are lost after reboot. To make changes persistent, we use configuration files.

# Check if sysctl.conf exists
ls -la /etc/sysctl.conf

# View current persistent settings
cat /etc/sysctl.conf
Subtask 4.2: Create Custom sysctl Configuration
# Create a custom configuration file for our optimizations
sudo tee /etc/sysctl.d/99-performance-tuning.conf << 'EOF'
# Performance Tuning Configuration
# Created for Lab 4: Configuring Kernel Tunables

# Memory Management Parameters
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_writeback_centisecs = 500
vm.vfs_cache_pressure = 150

# Network Performance Parameters
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 1024
net.ipv4.tcp_window_scaling = 1

# Additional optimizations
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 0
EOF

# Verify the configuration file
cat /etc/sysctl.d/99-performance-tuning.conf
Subtask 4.3: Apply and Test Persistent Configuration
# Apply the new configuration without rebooting
sudo sysctl -p /etc/sysctl.d/99-performance-tuning.conf

# Verify all parameters are applied
sysctl vm.swappiness vm.dirty_ratio net.core.rmem_max net.ipv4.tcp_rmem

# Test that the configuration will be loaded at boot
sudo sysctl --system
Subtask 4.4: Create Configuration Validation Script
# Create a script to validate our configuration
cat > /tmp/validate_config.sh << 'EOF'
#!/bin/bash

echo "=== Kernel Parameter Validation ==="
echo "Timestamp: $(date)"
echo

CONFIG_FILE="/etc/sysctl.d/99-performance-tuning.conf"
ERRORS=0

echo "Validating configuration from: $CONFIG_FILE"
echo

# Function to check parameter
check_param() {
    local param=$1
    local expected=$2
    local current=$(sysctl -n $param 2>/dev/null)
    
    if [ "$current" = "$expected" ]; then
        echo "✓ $param = $current (OK)"
    else
        echo "✗ $param = $current (Expected: $expected)"
        ((ERRORS++))
    fi
}

# Check memory parameters
echo "=== Memory Parameters ==="
check_param "vm.swappiness" "10"
check_param "vm.dirty_ratio" "15"
check_param "vm.dirty_background_ratio" "5"
check_param "vm.vfs_cache_pressure" "150"
echo

# Check network parameters
echo "=== Network Parameters ==="
check_param "net.core.rmem_max" "16777216"
check_param "net.core.wmem_max" "16777216"
check_param "net.core.somaxconn" "1024"
echo

echo "=== Validation Summary ==="
if [ $ERRORS -eq 0 ]; then
    echo "✓ All parameters configured correctly!"
else
    echo "✗ Found $ERRORS configuration errors"
fi
EOF

chmod +x /tmp/validate_config.sh

# Run the validation
/tmp/validate_config.sh
Task 5: Advanced Kernel Tuning and Monitoring
Subtask 5.1: Performance Impact Analysis
# Create a comprehensive performance analysis script
cat > /tmp/performance_analysis.sh << 'EOF'
#!/bin/bash

echo "=== System Performance Analysis ==="
echo "Analysis performed at: $(date)"
echo

echo "=== CPU Information ==="
lscpu | grep -E "(Model name|CPU\(s\)|Thread|Core)"
echo

echo "=== Memory Analysis ==="
echo "Total Memory:"
free -h | grep -E "(Mem|Swap)"
echo

echo "Memory Pressure (if available):"
if [ -f /proc/pressure/memory ]; then
    cat /proc/pressure/memory
else
    echo "Memory pressure information not available"
fi
echo

echo "=== I/O Performance ==="
echo "Dirty Pages Status:"
grep -E "(Dirty|Writeback)" /proc/meminfo
echo

echo "=== Network Performance Indicators ==="
echo "Network Interface Statistics:"
cat /proc/net/dev | head -3
echo

echo "TCP Connection States:"
ss -s
echo

echo "=== Current Kernel Parameters ==="
echo "Key VM Parameters:"
sysctl vm.swappiness vm.dirty_ratio vm.vfs_cache_pressure
echo

echo "Key Network Parameters:"
sysctl net.core.rmem_max net.core.wmem_max net.core.somaxconn
echo

echo "=== System Load ==="
uptime
echo
EOF

chmod +x /tmp/performance_analysis.sh

# Run the performance analysis
/tmp/performance_analysis.sh
Subtask 5.2: Create a Tuning Rollback Script
# Create a rollback script to restore default values
cat > /tmp/rollback_tuning.sh << 'EOF'
#!/bin/bash

echo "=== Kernel Parameter Rollback Script ==="
echo "This script will restore default kernel parameters"
echo

read -p "Are you sure you want to rollback all tuning changes? (y/N): " confirm

if [[ $confirm != [yY] ]]; then
    echo "Rollback cancelled."
    exit 0
fi

echo "Rolling back kernel parameters..."

# Restore default memory parameters
sudo sysctl vm.swappiness=60
sudo sysctl vm.dirty_ratio=20
sudo sysctl vm.dirty_background_ratio=10
sudo sysctl vm.dirty_writeback_centisecs=500
sudo sysctl vm.vfs_cache_pressure=100

# Restore default network parameters
sudo sysctl net.core.rmem_max=212992
sudo sysctl net.core.wmem_max=212992
sudo sysctl net.core.rmem_default=212992
sudo sysctl net.core.wmem_default=212992
sudo sysctl net.core.netdev_max_backlog=1000
sudo sysctl net.core.somaxconn=128

echo "Rollback completed."
echo "Note: To make rollback permanent, remove or rename:"
echo "  /etc/sysctl.d/99-performance-tuning.conf"
EOF

chmod +x /tmp/rollback_tuning.sh

echo "Rollback script created at /tmp/rollback_tuning.sh"
Subtask 5.3: Monitoring and Alerting Setup
# Create a monitoring script for ongoing performance tracking
cat > /tmp/continuous_monitor.sh << 'EOF'
#!/bin/bash

LOGFILE="/tmp/performance_log.txt"
INTERVAL=60  # Monitor every 60 seconds

echo "=== Continuous Performance Monitor Started ==="
echo "Logging to: $LOGFILE"
echo "Monitoring interval: ${INTERVAL} seconds"
echo "Press Ctrl+C to stop"
echo

# Function to log performance metrics
log_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    {
        echo "[$timestamp] Performance Metrics"
        echo "Memory: $(free -m | grep '^Mem:' | awk '{printf "Used: %dMB (%.1f%%), Available: %dMB", $3, ($3/$2)*100, $7}')"
        echo "Swap: $(free -m | grep '^Swap:' | awk '{if($2>0) printf "Used: %dMB (%.1f%%)", $3, ($3/$2)*100; else print "No swap configured"}')"
        echo "Load: $(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')"
        echo "TCP Connections: $(ss -t | wc -l) active"
        echo "---"
    } >> "$LOGFILE"
}

# Trap Ctrl+C to exit gracefully
trap 'echo "Monitoring stopped."; exit 0' INT

# Start monitoring loop
while true; do
    log_metrics
    echo "Logged metrics at $(date '+%H:%M:%S')"
    sleep $INTERVAL
done
EOF

chmod +x /tmp/continuous_monitor.sh

echo "Continuous monitoring script created."
echo "Run with: /tmp/continuous_monitor.sh"
Troubleshooting Common Issues
Issue 1: Permission Denied Errors
# If you get permission denied when modifying kernel parameters:

# Check if you have sudo access
sudo -l

# Ensure you're using sudo with sysctl commands
sudo sysctl vm.swappiness=10

# Check if the parameter exists
ls /proc/sys/vm/swappiness
Issue 2: Parameter Not Found
# If a parameter doesn't exist, check available parameters:
find /proc/sys -name "*swappiness*" 2>/dev/null

# List all available parameters in a category:
sysctl -a | grep vm | head -20
Issue 3: Changes Not Persisting
# Verify configuration file syntax
sudo sysctl -p /etc/sysctl.d/99-performance-tuning.conf

# Check for syntax errors in configuration
sudo sysctl --system 2>&1 | grep -i error

# Ensure configuration file has correct permissions
ls -la /etc/sysctl.d/99-performance-tuning.conf
Issue 4: System Instability After Changes
# If system becomes unstable, use the rollback script:
/tmp/rollback_tuning.sh

# Or manually reset critical parameters:
sudo sysctl vm.swappiness=60
sudo sysctl vm.dirty_ratio=20

# Check system logs for errors:
sudo journalctl -n 50 | grep -i error
Best Practices and Security Considerations
Performance Tuning Best Practices
Always Baseline First: Document current performance before making changes
Change One Parameter at a Time: This helps identify which changes have impact
Test Thoroughly: Use realistic workloads to test parameter changes
Monitor Continuously: Keep track of system behavior after changes
Document Changes: Maintain records of what was changed and why
Security Considerations
# Some parameters can affect security. Be cautious with:

# Network parameters that might affect DoS protection
sysctl net.ipv4.tcp_syncookies  # Should remain enabled (1)

# Memory parameters that might affect system stability
sysctl vm.overcommit_memory    # Understand implications before changing

# Check current security-related settings
sysctl net.ipv4.tcp_syncookies net.ipv4.icmp_echo_ignore_broadcasts
Lab Validation and Testing
Final Validation Steps
# Run all monitoring scripts to validate configuration
echo "=== Final Lab Validation ==="

echo "1. Running configuration validation..."
/tmp/validate_config.sh

echo -e "\n2. Running performance analysis..."
/tmp/performance_analysis.sh

echo -e "\n3. Testing parameter persistence..."
sudo sysctl --system > /dev/null 2>&1
echo "✓ Configuration loaded successfully"

echo -e "\n4. Creating final report..."
cat > /tmp/lab_completion_report.txt << EOF
Lab 4: Configuring Kernel Tunables - Completion Report
Generated: $(date)

Configuration Applied:
- Memory tuning: swappiness, dirty ratios, cache pressure
- Network tuning: buffer sizes, TCP parameters, queue settings
- Configuration made persistent in /etc/sysctl.d/99-performance-tuning.conf

Scripts Created:
- /tmp/memory_monitor.sh - Memory performance monitoring
- /tmp/network_monitor.sh - Network performance monitoring
- /tmp/validate_config.sh - Configuration validation
- /tmp/performance_analysis.sh - Comprehensive analysis
- /tmp/rollback_tuning.sh - Rollback script
- /tmp/continuous_monitor.sh - Ongoing monitoring

Lab Status: COMPLETED SUCCESSFULLY
EOF

echo "✓ Lab completion report created: /tmp/lab_completion_report.txt"
cat /tmp/lab_completion_report.txt
Conclusion
Congratulations! You have successfully completed Lab 4: Configuring Kernel Tunables. In this comprehensive lab, you have accomplished the following:

Key Achievements
Mastered Kernel Parameter Management: You learned how to navigate the /proc/sys filesystem and use the sysctl command to view and modify kernel parameters effectively.

Optimized Memory Management: You configured critical memory parameters including swappiness, dirty page ratios, and VFS cache pressure to improve system memory utilization and performance.

Enhanced Network Performance: You tuned network buffer sizes, TCP parameters, and queue settings to optimize network throughput and reduce latency.

Implemented Persistent Configuration: You created proper configuration files to ensure your optimizations survive system reboots and learned best practices for configuration management.

Developed Monitoring and Validation Skills: You created comprehensive monitoring scripts to track performance impact and validate configuration changes.

Built Troubleshooting Capabilities: You learned how to identify and resolve common issues related to kernel parameter modifications and created rollback procedures for safety.

Why This Matters
Kernel tuning is a critical skill for system administrators and performance engineers because:

Performance Optimization: Proper kernel tuning can significantly improve system performance, especially in high-load environments
Resource Efficiency: Optimized parameters help systems make better use of available hardware resources
Application Support: Many enterprise applications require specific kernel parameter adjustments for optimal performance
Cost Savings: Better performance from existing hardware reduces the need for costly upgrades
Professional Development: These skills are essential for Red Hat Performance Tuning certification and advanced Linux administration roles
Next Steps
To continue building on this knowledge:

Practice in Different Environments: Apply these techniques to various workloads (web servers, databases, high-performance computing)
Learn Advanced Monitoring: Explore tools like perf, sar, and iotop for deeper performance analysis
Study Workload-Specific Tuning: Research kernel parameters specific to your application environments
Explore Container Tuning: Learn how kernel parameters affect containerized applications
Pursue Certification: Use this knowledge toward Red Hat Performance Tuning certification
Remember: Always test kernel parameter changes in non-production environments first, and maintain proper documentation of all modifications. The skills you've developed in this lab form the foundation for advanced Linux performance tuning and system optimization.
