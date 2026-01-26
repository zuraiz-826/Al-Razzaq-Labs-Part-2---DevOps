Lab 12: Network Utilization Tuning
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of network performance optimization in Linux systems
Modify TCP buffer sizes using sysctl to improve network throughput
Configure network interface settings using ethtool for optimal performance
Measure network performance using iperf3 and analyze results
Apply systematic tuning methodologies to optimize network utilization
Troubleshoot common network performance bottlenecks
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with network concepts (TCP/IP, bandwidth, latency)
Knowledge of basic system administration tasks
Understanding of performance monitoring concepts
Access to root or sudo privileges on the lab system
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your lab environment includes:

Two CentOS/RHEL 8+ or Ubuntu 20.04+ virtual machines
Pre-installed network performance tools (iperf3, ethtool, sysstat)
Root access for system configuration changes
Network connectivity between machines for testing
Task 1: Baseline Network Performance Assessment
Subtask 1.1: Initial System Information Gathering
First, let's gather information about our current network configuration and establish baseline performance metrics.

Step 1: Check current network interfaces and their status

# Display all network interfaces
ip addr show

# Check interface statistics
ip -s link show

# Display current network interface configuration
ifconfig -a
Step 2: Examine current TCP buffer settings

# Check current TCP buffer sizes
sysctl net.core.rmem_max
sysctl net.core.wmem_max
sysctl net.core.rmem_default
sysctl net.core.wmem_default
sysctl net.ipv4.tcp_rmem
sysctl net.ipv4.tcp_wmem

# Display all network-related sysctl parameters
sysctl -a | grep -E "(net.core|net.ipv4.tcp)" | head -20
Step 3: Check current ethtool settings for your primary network interface

# Replace 'eth0' with your actual interface name (use 'ip addr' to find it)
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
echo "Primary interface: $INTERFACE"

# Display current interface settings
ethtool $INTERFACE

# Check ring buffer settings
ethtool -g $INTERFACE

# Check offload settings
ethtool -k $INTERFACE
Subtask 1.2: Establish Baseline Performance
Step 1: Install and configure iperf3 on both machines

On the first machine (server):

# Install iperf3 if not already installed
sudo yum install iperf3 -y  # For RHEL/CentOS
# OR
sudo apt-get install iperf3 -y  # For Ubuntu/Debian

# Start iperf3 server
iperf3 -s -p 5001
On the second machine (client):

# Install iperf3
sudo yum install iperf3 -y  # For RHEL/CentOS
# OR
sudo apt-get install iperf3 -y  # For Ubuntu/Debian

# Test connection to server (replace SERVER_IP with actual IP)
SERVER_IP="192.168.1.100"  # Replace with your server's IP
iperf3 -c $SERVER_IP -p 5001 -t 30
Step 2: Record baseline measurements

# Create a results directory
mkdir -p ~/network_tuning_results
cd ~/network_tuning_results

# Run comprehensive baseline tests
echo "=== BASELINE PERFORMANCE TEST ===" > baseline_results.txt
date >> baseline_results.txt

# TCP throughput test
echo "TCP Throughput Test:" >> baseline_results.txt
iperf3 -c $SERVER_IP -p 5001 -t 30 >> baseline_results.txt

# UDP throughput test
echo "UDP Throughput Test:" >> baseline_results.txt
iperf3 -c $SERVER_IP -p 5001 -u -b 1G -t 30 >> baseline_results.txt

# Latency test using ping
echo "Latency Test:" >> baseline_results.txt
ping -c 100 $SERVER_IP >> baseline_results.txt
Task 2: TCP Buffer Size Optimization
Subtask 2.1: Understanding Current TCP Buffer Configuration
Step 1: Analyze current TCP buffer settings in detail

# Create a script to display current settings
cat > ~/check_tcp_buffers.sh << 'EOF'
#!/bin/bash
echo "=== Current TCP Buffer Configuration ==="
echo "Core receive buffer max: $(sysctl -n net.core.rmem_max) bytes"
echo "Core send buffer max: $(sysctl -n net.core.wmem_max) bytes"
echo "Core receive buffer default: $(sysctl -n net.core.rmem_default) bytes"
echo "Core send buffer default: $(sysctl -n net.core.wmem_default) bytes"
echo ""
echo "TCP receive buffer (min/default/max): $(sysctl -n net.ipv4.tcp_rmem)"
echo "TCP send buffer (min/default/max): $(sysctl -n net.ipv4.tcp_wmem)"
echo ""
echo "TCP window scaling: $(sysctl -n net.ipv4.tcp_window_scaling)"
echo "TCP timestamps: $(sysctl -n net.ipv4.tcp_timestamps)"
echo "TCP SACK: $(sysctl -n net.ipv4.tcp_sack)"
EOF

chmod +x ~/check_tcp_buffers.sh
~/check_tcp_buffers.sh
Subtask 2.2: Calculate Optimal Buffer Sizes
Step 1: Determine optimal buffer sizes based on network characteristics

# Create a buffer calculation script
cat > ~/calculate_buffers.sh << 'EOF'
#!/bin/bash
echo "=== Buffer Size Calculation ==="

# Get network interface speed (in Mbps)
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
SPEED=$(ethtool $INTERFACE 2>/dev/null | grep "Speed:" | awk '{print $2}' | sed 's/Mb\/s//')

if [ -z "$SPEED" ] || [ "$SPEED" = "Unknown!" ]; then
    SPEED=1000  # Default to 1Gbps if unable to detect
fi

echo "Interface: $INTERFACE"
echo "Speed: ${SPEED}Mbps"

# Calculate RTT (Round Trip Time) - using ping to gateway
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
RTT=$(ping -c 5 $GATEWAY 2>/dev/null | tail -1 | awk -F'/' '{print $5}' | cut -d'.' -f1)

if [ -z "$RTT" ]; then
    RTT=1  # Default to 1ms if unable to measure
fi

echo "Estimated RTT: ${RTT}ms"

# Calculate Bandwidth-Delay Product (BDP)
# BDP = Bandwidth × RTT
# Convert to bytes: (Speed in Mbps × RTT in ms × 1000) / 8
BDP=$(echo "scale=0; ($SPEED * $RTT * 1000) / 8" | bc -l 2>/dev/null || echo $((SPEED * RTT * 125)))

echo "Calculated BDP: ${BDP} bytes"

# Recommended buffer sizes (2x BDP for good performance)
RECOMMENDED_BUFFER=$((BDP * 2))
echo "Recommended buffer size: ${RECOMMENDED_BUFFER} bytes"

# Ensure minimum reasonable size
if [ $RECOMMENDED_BUFFER -lt 65536 ]; then
    RECOMMENDED_BUFFER=65536
fi

# Ensure maximum reasonable size (32MB)
if [ $RECOMMENDED_BUFFER -gt 33554432 ]; then
    RECOMMENDED_BUFFER=33554432
fi

echo "Final recommended buffer size: ${RECOMMENDED_BUFFER} bytes"
EOF

chmod +x ~/calculate_buffers.sh
~/calculate_buffers.sh
Subtask 2.3: Apply TCP Buffer Optimizations
Step 1: Create optimized sysctl configuration

# Backup current sysctl configuration
sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup

# Create optimized network configuration
cat > ~/network_optimization.conf << 'EOF'
# Network Performance Tuning Configuration

# TCP Buffer Sizes
# Increase maximum buffer sizes
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.rmem_default = 262144
net.core.wmem_default = 262144

# TCP-specific buffer sizes (min, default, max)
net.ipv4.tcp_rmem = 4096 262144 33554432
net.ipv4.tcp_wmem = 4096 262144 33554432

# Enable TCP window scaling
net.ipv4.tcp_window_scaling = 1

# Enable selective acknowledgments
net.ipv4.tcp_sack = 1

# Enable timestamps
net.ipv4.tcp_timestamps = 1

# Increase network device backlog
net.core.netdev_max_backlog = 5000

# Increase socket listen backlog
net.core.somaxconn = 1024

# TCP congestion control
net.ipv4.tcp_congestion_control = bbr

# Enable TCP fast open
net.ipv4.tcp_fastopen = 3
EOF

# Apply the configuration
sudo cp ~/network_optimization.conf /etc/sysctl.d/99-network-performance.conf
sudo sysctl -p /etc/sysctl.d/99-network-performance.conf
Step 2: Verify the changes were applied

echo "=== Verifying TCP Buffer Changes ==="
~/check_tcp_buffers.sh

# Check if BBR congestion control is available and active
echo ""
echo "Available congestion control algorithms:"
sysctl net.ipv4.tcp_available_congestion_control

echo "Current congestion control algorithm:"
sysctl net.ipv4.tcp_congestion_control
Subtask 2.4: Test Performance After TCP Buffer Optimization
Step 1: Run performance tests with optimized buffers

cd ~/network_tuning_results

echo "=== POST TCP BUFFER OPTIMIZATION TEST ===" > tcp_optimized_results.txt
date >> tcp_optimized_results.txt

# TCP throughput test with larger window size
echo "TCP Throughput Test (Optimized Buffers):" >> tcp_optimized_results.txt
iperf3 -c $SERVER_IP -p 5001 -t 30 -w 1M >> tcp_optimized_results.txt

# Multiple parallel streams test
echo "TCP Parallel Streams Test:" >> tcp_optimized_results.txt
iperf3 -c $SERVER_IP -p 5001 -t 30 -P 4 >> tcp_optimized_results.txt
Task 3: Network Interface Optimization with ethtool
Subtask 3.1: Analyze Current Interface Settings
Step 1: Comprehensive interface analysis

# Get primary network interface
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

# Create interface analysis script
cat > ~/analyze_interface.sh << 'EOF'
#!/bin/bash
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

echo "=== Network Interface Analysis ==="
echo "Interface: $INTERFACE"
echo ""

echo "Basic Interface Information:"
ethtool $INTERFACE

echo ""
echo "Ring Buffer Settings:"
ethtool -g $INTERFACE

echo ""
echo "Offload Features:"
ethtool -k $INTERFACE

echo ""
echo "Coalescing Settings:"
ethtool -c $INTERFACE

echo ""
echo "Driver Information:"
ethtool -i $INTERFACE

echo ""
echo "Statistics:"
ethtool -S $INTERFACE | head -20
EOF

chmod +x ~/analyze_interface.sh
~/analyze_interface.sh > ~/network_tuning_results/interface_analysis.txt
Subtask 3.2: Optimize Ring Buffer Sizes
Step 1: Check current ring buffer settings and optimize

# Check maximum supported ring buffer sizes
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
echo "Current ring buffer settings for $INTERFACE:"
ethtool -g $INTERFACE

# Create ring buffer optimization script
cat > ~/optimize_ring_buffers.sh << 'EOF'
#!/bin/bash
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

echo "Optimizing ring buffers for interface: $INTERFACE"

# Get maximum supported values
MAX_RX=$(ethtool -g $INTERFACE | grep -A4 "Pre-set maximums" | grep "RX:" | awk '{print $2}')
MAX_TX=$(ethtool -g $INTERFACE | grep -A4 "Pre-set maximums" | grep "TX:" | awk '{print $2}')

echo "Maximum RX ring buffer: $MAX_RX"
echo "Maximum TX ring buffer: $MAX_TX"

# Set ring buffers to maximum supported values
if [ ! -z "$MAX_RX" ] && [ "$MAX_RX" != "n/a" ]; then
    echo "Setting RX ring buffer to maximum: $MAX_RX"
    sudo ethtool -G $INTERFACE rx $MAX_RX
fi

if [ ! -z "$MAX_TX" ] && [ "$MAX_TX" != "n/a" ]; then
    echo "Setting TX ring buffer to maximum: $MAX_TX"
    sudo ethtool -G $INTERFACE tx $MAX_TX
fi

echo "New ring buffer settings:"
ethtool -g $INTERFACE
EOF

chmod +x ~/optimize_ring_buffers.sh
~/optimize_ring_buffers.sh
Subtask 3.3: Configure Hardware Offload Features
Step 1: Optimize offload settings for performance

# Create offload optimization script
cat > ~/optimize_offloads.sh << 'EOF'
#!/bin/bash
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

echo "Optimizing offload features for interface: $INTERFACE"

# Enable beneficial offload features
echo "Enabling performance-enhancing offload features..."

# TCP Segmentation Offload
sudo ethtool -K $INTERFACE tso on 2>/dev/null && echo "TSO: enabled" || echo "TSO: not supported"

# Generic Segmentation Offload
sudo ethtool -K $INTERFACE gso on 2>/dev/null && echo "GSO: enabled" || echo "GSO: not supported"

# Generic Receive Offload
sudo ethtool -K $INTERFACE gro on 2>/dev/null && echo "GRO: enabled" || echo "GRO: not supported"

# Checksum offloading
sudo ethtool -K $INTERFACE rx on 2>/dev/null && echo "RX checksum: enabled" || echo "RX checksum: not supported"
sudo ethtool -K $INTERFACE tx on 2>/dev/null && echo "TX checksum: enabled" || echo "TX checksum: not supported"

# Scatter-gather
sudo ethtool -K $INTERFACE sg on 2>/dev/null && echo "Scatter-gather: enabled" || echo "Scatter-gather: not supported"

echo ""
echo "Current offload settings:"
ethtool -k $INTERFACE | grep -E "(tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload|rx-checksumming|tx-checksumming|scatter-gather)"
EOF

chmod +x ~/optimize_offloads.sh
~/optimize_offloads.sh
Subtask 3.4: Optimize Interrupt Coalescing
Step 1: Configure interrupt coalescing for better performance

# Create coalescing optimization script
cat > ~/optimize_coalescing.sh << 'EOF'
#!/bin/bash
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

echo "Optimizing interrupt coalescing for interface: $INTERFACE"

echo "Current coalescing settings:"
ethtool -c $INTERFACE

# Optimize coalescing parameters for throughput
# These values balance latency and throughput
echo ""
echo "Applying optimized coalescing settings..."

# Set adaptive coalescing if supported
sudo ethtool -C $INTERFACE adaptive-rx on adaptive-tx on 2>/dev/null && echo "Adaptive coalescing: enabled" || echo "Adaptive coalescing: not supported"

# Set reasonable static values if adaptive is not supported
sudo ethtool -C $INTERFACE rx-usecs 50 2>/dev/null && echo "RX interrupt delay: 50 usecs" || echo "RX interrupt delay: not configurable"
sudo ethtool -C $INTERFACE tx-usecs 50 2>/dev/null && echo "TX interrupt delay: 50 usecs" || echo "TX interrupt delay: not configurable"

# Set frame limits
sudo ethtool -C $INTERFACE rx-frames 32 2>/dev/null && echo "RX frame limit: 32" || echo "RX frame limit: not configurable"
sudo ethtool -C $INTERFACE tx-frames 32 2>/dev/null && echo "TX frame limit: 32" || echo "TX frame limit: not configurable"

echo ""
echo "New coalescing settings:"
ethtool -c $INTERFACE
EOF

chmod +x ~/optimize_coalescing.sh
~/optimize_coalescing.sh
Subtask 3.5: Make ethtool Changes Persistent
Step 1: Create persistent configuration for ethtool settings

# Create a script to apply ethtool settings at boot
cat > ~/ethtool_persistent.sh << 'EOF'
#!/bin/bash
# Network interface optimization script
# This script should be run at boot time

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

if [ -z "$INTERFACE" ]; then
    echo "No default interface found"
    exit 1
fi

echo "Applying network optimizations to interface: $INTERFACE"

# Ring buffer optimization
MAX_RX=$(ethtool -g $INTERFACE | grep -A4 "Pre-set maximums" | grep "RX:" | awk '{print $2}')
MAX_TX=$(ethtool -g $INTERFACE | grep -A4 "Pre-set maximums" | grep "TX:" | awk '{print $2}')

[ ! -z "$MAX_RX" ] && [ "$MAX_RX" != "n/a" ] && ethtool -G $INTERFACE rx $MAX_RX
[ ! -z "$MAX_TX" ] && [ "$MAX_TX" != "n/a" ] && ethtool -G $INTERFACE tx $MAX_TX

# Offload features
ethtool -K $INTERFACE tso on 2>/dev/null
ethtool -K $INTERFACE gso on 2>/dev/null
ethtool -K $INTERFACE gro on 2>/dev/null
ethtool -K $INTERFACE rx on 2>/dev/null
ethtool -K $INTERFACE tx on 2>/dev/null
ethtool -K $INTERFACE sg on 2>/dev/null

# Coalescing
ethtool -C $INTERFACE adaptive-rx on adaptive-tx on 2>/dev/null
ethtool -C $INTERFACE rx-usecs 50 2>/dev/null
ethtool -C $INTERFACE tx-usecs 50 2>/dev/null
ethtool -C $INTERFACE rx-frames 32 2>/dev/null
ethtool -C $INTERFACE tx-frames 32 2>/dev/null

echo "Network optimizations applied successfully"
EOF

chmod +x ~/ethtool_persistent.sh

# Copy to system location and create systemd service
sudo cp ~/ethtool_persistent.sh /usr/local/bin/

# Create systemd service for persistent settings
sudo tee /etc/systemd/system/network-optimization.service > /dev/null << 'EOF'
[Unit]
Description=Network Interface Optimization
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ethtool_persistent.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl enable network-optimization.service
sudo systemctl start network-optimization.service
Task 4: Comprehensive Performance Testing and Analysis
Subtask 4.1: Advanced iperf3 Testing
Step 1: Comprehensive performance testing with various parameters

cd ~/network_tuning_results

# Create comprehensive testing script
cat > ~/comprehensive_test.sh << 'EOF'
#!/bin/bash
SERVER_IP="192.168.1.100"  # Replace with your server IP
RESULTS_FILE="comprehensive_results.txt"

echo "=== COMPREHENSIVE NETWORK PERFORMANCE TEST ===" > $RESULTS_FILE
echo "Test Date: $(date)" >> $RESULTS_FILE
echo "Server IP: $SERVER_IP" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Test 1: Single stream TCP throughput
echo "=== Test 1: Single Stream TCP Throughput ===" >> $RESULTS_FILE
iperf3 -c $SERVER_IP -p 5001 -t 60 -i 10 >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Test 2: Multiple parallel streams
echo "=== Test 2: Multiple Parallel Streams (4 streams) ===" >> $RESULTS_FILE
iperf3 -c $SERVER_IP -p 5001 -t 60 -P 4 -i 10 >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Test 3: Different window sizes
for window in 64K 128K 256K 512K 1M 2M; do
    echo "=== Test 3: TCP with ${window} window size ===" >> $RESULTS_FILE
    iperf3 -c $SERVER_IP -p 5001 -t 30 -w $window >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
done

# Test 4: UDP throughput at different rates
for rate in 100M 500M 1G; do
    echo "=== Test 4: UDP at ${rate} rate ===" >> $RESULTS_FILE
    iperf3 -c $SERVER_IP -p 5001 -u -b $rate -t 30 >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
done

# Test 5: Bidirectional test
echo "=== Test 5: Bidirectional Test ===" >> $RESULTS_FILE
iperf3 -c $SERVER_IP -p 5001 -t 30 --bidir >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Test 6: Reverse mode test
echo "=== Test 6: Reverse Mode Test ===" >> $RESULTS_FILE
iperf3 -c $SERVER_IP -p 5001 -t 30 -R >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

echo "Comprehensive testing completed. Results saved to $RESULTS_FILE"
EOF

chmod +x ~/comprehensive_test.sh

# Run the comprehensive test
~/comprehensive_test.sh
Subtask 4.2: System Resource Monitoring During Tests
Step 1: Monitor system resources during network tests

# Create monitoring script
cat > ~/monitor_performance.sh << 'EOF'
#!/bin/bash
MONITOR_FILE="system_monitoring.txt"
DURATION=60

echo "=== SYSTEM PERFORMANCE MONITORING ===" > $MONITOR_FILE
echo "Monitor Duration: ${DURATION} seconds" >> $MONITOR_FILE
echo "Start Time: $(date)" >> $MONITOR_FILE
echo "" >> $MONITOR_FILE

# Start background monitoring
(
    echo "=== CPU Usage ===" >> $MONITOR_FILE
    sar -u 5 $((DURATION/5)) >> $MONITOR_FILE
    echo "" >> $MONITOR_FILE
    
    echo "=== Memory Usage ===" >> $MONITOR_FILE
    sar -r 5 $((DURATION/5)) >> $MONITOR_FILE
    echo "" >> $MONITOR_FILE
    
    echo "=== Network Interface Statistics ===" >> $MONITOR_FILE
    sar -n DEV 5 $((DURATION/5)) >> $MONITOR_FILE
    echo "" >> $MONITOR_FILE
    
    echo "=== Network Error Statistics ===" >> $MONITOR_FILE
    sar -n EDEV 5 $((DURATION/5)) >> $MONITOR_FILE
    echo "" >> $MONITOR_FILE
) &

MONITOR_PID=$!

# Run network test while monitoring
echo "Starting network test with monitoring..."
SERVER_IP="192.168.1.100"  # Replace with your server IP
iperf3 -c $SERVER_IP -p 5001 -t $DURATION -P 4

# Wait for monitoring to complete
wait $MONITOR_PID

echo "Monitoring completed. Results saved to $MONITOR_FILE"
EOF

chmod +x ~/monitor_performance.sh

# Install sysstat if not available
sudo yum install sysstat -y 2>/dev/null || sudo apt-get install sysstat -y 2>/dev/null

# Run monitoring test
~/monitor_performance.sh
Subtask 4.3: Network Latency and Jitter Analysis
Step 1: Detailed latency analysis

# Create latency analysis script
cat > ~/latency_analysis.sh << 'EOF'
#!/bin/bash
SERVER_IP="192.168.1.100"  # Replace with your server IP
LATENCY_FILE="latency_analysis.txt"

echo "=== NETWORK LATENCY ANALYSIS ===" > $LATENCY_FILE
echo "Target Server: $SERVER_IP" >> $LATENCY_FILE
echo "Test Date: $(date)" >> $LATENCY_FILE
echo "" >> $LATENCY_FILE

# Basic ping test
echo "=== Basic Ping Test (1000 packets) ===" >> $LATENCY_FILE
ping -c 1000 -i 0.01 $SERVER_IP >> $LATENCY_FILE
echo "" >> $LATENCY_FILE

# Different packet sizes
for size in 64 128 256 512 1024 1500; do
    echo "=== Ping Test with ${size} byte packets ===" >> $LATENCY_FILE
    ping -c 100 -s $size $SERVER_IP >> $LATENCY_FILE
    echo "" >> $LATENCY_FILE
done

# Flood ping (requires root)
if [ "$EUID" -eq 0 ]; then
    echo "=== Flood Ping Test ===" >> $LATENCY_FILE
    ping -f -c 1000 $SERVER_IP >> $LATENCY_FILE
    echo "" >> $LATENCY_FILE
fi

# hping3 test if available
if command -v hping3 &> /dev/null; then
    echo "=== TCP SYN Latency Test ===" >> $LATENCY_FILE
    hping3 -S -c 100 -p 80 $SERVER_IP >> $LATENCY_FILE
    echo "" >> $LATENCY_FILE
fi

echo "Latency analysis completed. Results saved to $LATENCY_FILE"
EOF

chmod +x ~/latency_analysis.sh
~/latency_analysis.sh
Subtask 4.4: Performance Comparison and Analysis
Step 1: Create performance comparison report

# Create comparison analysis script
cat > ~/performance_comparison.sh << 'EOF'
#!/bin/bash
COMPARISON_FILE="performance_comparison.txt"

echo "=== NETWORK PERFORMANCE COMPARISON REPORT ===" > $COMPARISON_FILE
echo "Generated: $(date)" >> $COMPARISON_FILE
echo "" >> $COMPARISON_FILE

# Extract key metrics from test results
extract_throughput() {
    local file=$1
    local test_name=$2
    
    echo "=== $test_name ===" >> $COMPARISON_FILE
    
    if [ -f "$file" ]; then
        # Extract final throughput values
        grep "receiver" "$file" | tail -5 >> $COMPARISON_FILE
        echo "" >> $COMPARISON_FILE
    else
        echo "File $file not found" >> $COMPARISON_FILE
        echo "" >> $COMPARISON_FILE
    fi
}

# Compare baseline vs optimized results
extract_throughput "baseline_results.txt" "BASELINE PERFORMANCE"
extract_throughput "tcp_optimized_results.txt" "TCP BUFFER OPTIMIZED"
extract_throughput "comprehensive_results.txt" "FULLY OPTIMIZED"

# Calculate improvement percentages
echo "=== PERFORMANCE IMPROVEMENT ANALYSIS ===" >> $COMPARISON_FILE

# Extract baseline throughput (simplified extraction)
BASELINE_THROUGHPUT=$(grep "receiver" baseline_results.txt 2>/dev/null | head -1 | awk '{print $7}' | sed 's/Mbits\/sec//')
OPTIMIZED_THROUGHPUT=$(grep "receiver" comprehensive_results.txt 2>/dev/null | head -1 | awk '{print $7}' | sed 's/Mbits\/sec//')

if [ ! -z "$BASELINE_THROUGHPUT" ] && [ ! -z "$OPTIMIZED_THROUGHPUT" ]; then
    IMPROVEMENT=$(echo "scale=2; (($OPTIMIZED_THROUGHPUT - $BASELINE_THROUGHPUT) / $BASELINE_THROUGHPUT) * 100" | bc -l 2>/dev/null)
    echo "Baseline Throughput: ${BASELINE_THROUGHPUT} Mbps" >> $COMPARISON_FILE
    echo "Optimized Throughput: ${OPTIMIZED_THROUGHPUT} Mbps" >> $COMPARISON_FILE
    echo "Performance Improvement: ${IMPROVEMENT}%" >> $COMPARISON_FILE
else
    echo "Unable to calculate improvement percentage" >> $COMPARISON_FILE
fi

echo "" >> $COMPARISON_FILE

# System configuration summary
echo "=== APPLIED OPTIMIZATIONS SUMMARY ===" >> $COMPARISON_FILE
echo "1. TCP Buffer Sizes:" >> $COMPARISON_FILE
sysctl net.ipv4.tcp_rmem >> $COMPARISON_FILE
sysctl net.ipv4.tcp_wmem >> $COMPARISON_FILE
echo "" >> $COMPARISON_FILE

echo "2. Network Interface Settings:" >> $COMPARISON_FILE
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
echo "Interface: $INTERFACE" >> $COMPARISON_FILE
ethtool -g $INTERFACE | grep -A2 "Current hardware settings" >> $COMPARISON_FILE
echo "" >> $COMPARISON_FILE

echo "3. Offload Features:" >> $COMPARISON_FILE
ethtool -k $INTERFACE | grep -E "(tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload)" >> $COMPARISON_FILE

echo "Performance comparison completed. Report saved to $COMPARISON_FILE"
EOF

chmod +x ~/performance_comparison.sh
~/performance_comparison.sh
Troubleshooting Common Issues
Issue 1: Permission Denied Errors
Problem: Cannot modify sysctl parameters or ethtool settings

Solution:

# Ensure you have sudo privileges
sudo -v

# Check if sysctl parameters are read-only
sysctl -a | grep net.ipv4.tcp_rmem

# For containers or restricted environments, some parameters may not be modifiable
# Check kernel version and capabilities
uname -r
cat /proc/version
Issue 2: ethtool Settings Not Supported
Problem: ethtool returns "Operation not supported"

Solution:

# Check if the network interface supports the feature
ethtool -k $INTERFACE | grep "fixed"

# Some virtual interfaces don't support all features
# Check interface type
ip link show $INTERFACE

# For virtual machines, ensure the hypervisor supports the features
lspci | grep -i network
Issue 3: iperf3 Connection Issues
Problem: Cannot connect to iperf3 server

Solution:

# Check if server is running
netstat -tlnp | grep 5001

# Check firewall settings
su
