Lab 18: Network Traffic Performance Tuning
Objectives
By the end of this lab, students will be able to:

Configure TCP parameters to optimize performance for large data transfers
Implement DNS optimization techniques to reduce resolution latency
Use network monitoring tools (netstat and ss) to analyze and tune network traffic
Apply performance tuning strategies for high-volume network environments
Troubleshoot network bottlenecks using command-line tools
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with network concepts (TCP/IP, DNS)
Knowledge of file editing using vi/nano
Understanding of system administration fundamentals
Experience with basic networking commands (ping, traceroute)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Root access for system configuration
Network connectivity for testing
Pre-installed monitoring tools
Task 1: Adjust TCP Parameters for Large Data Transfers
Subtask 1.1: Examine Current TCP Settings
First, let's examine the current TCP configuration on your system.

Check current TCP buffer sizes:
# View current TCP buffer settings
cat /proc/sys/net/core/rmem_default
cat /proc/sys/net/core/rmem_max
cat /proc/sys/net/core/wmem_default
cat /proc/sys/net/core/wmem_max
Check TCP window scaling and congestion control:
# Check TCP window scaling
cat /proc/sys/net/ipv4/tcp_window_scaling

# Check current congestion control algorithm
cat /proc/sys/net/ipv4/tcp_congestion_control

# List available congestion control algorithms
cat /proc/sys/net/ipv4/tcp_available_congestion_control
Document baseline performance:
# Create a baseline performance log
echo "=== Baseline TCP Settings ===" > /tmp/tcp_baseline.log
echo "Date: $(date)" >> /tmp/tcp_baseline.log
echo "rmem_default: $(cat /proc/sys/net/core/rmem_default)" >> /tmp/tcp_baseline.log
echo "rmem_max: $(cat /proc/sys/net/core/rmem_max)" >> /tmp/tcp_baseline.log
echo "wmem_default: $(cat /proc/sys/net/core/wmem_default)" >> /tmp/tcp_baseline.log
echo "wmem_max: $(cat /proc/sys/net/core/wmem_max)" >> /tmp/tcp_baseline.log
echo "tcp_congestion_control: $(cat /proc/sys/net/ipv4/tcp_congestion_control)" >> /tmp/tcp_baseline.log
Subtask 1.2: Configure TCP Buffer Sizes for High Throughput
Create a backup of current sysctl configuration:
# Backup current sysctl settings
cp /etc/sysctl.conf /etc/sysctl.conf.backup
Configure optimized TCP parameters:
# Create TCP optimization configuration
cat << 'EOF' > /etc/sysctl.d/99-tcp-performance.conf
# TCP Buffer Size Optimization for Large Data Transfers

# Increase default and maximum socket buffer sizes
net.core.rmem_default = 262144
net.core.rmem_max = 134217728
net.core.wmem_default = 262144
net.core.wmem_max = 134217728

# TCP memory allocation (min, default, max)
net.ipv4.tcp_rmem = 4096 262144 134217728
net.ipv4.tcp_wmem = 4096 262144 134217728

# Enable TCP window scaling
net.ipv4.tcp_window_scaling = 1

# Increase maximum backlog queue
net.core.netdev_max_backlog = 5000

# Enable TCP timestamps
net.ipv4.tcp_timestamps = 1

# Enable selective acknowledgments
net.ipv4.tcp_sack = 1

# Set congestion control to BBR (if available) or cubic
net.ipv4.tcp_congestion_control = bbr

# Increase maximum number of connections
net.core.somaxconn = 65535

# TCP keepalive settings
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3
EOF
Apply the new settings:
# Apply sysctl settings
sysctl -p /etc/sysctl.d/99-tcp-performance.conf

# Verify settings were applied
echo "=== New TCP Settings ===" > /tmp/tcp_optimized.log
echo "Date: $(date)" >> /tmp/tcp_optimized.log
echo "rmem_default: $(cat /proc/sys/net/core/rmem_default)" >> /tmp/tcp_optimized.log
echo "rmem_max: $(cat /proc/sys/net/core/rmem_max)" >> /tmp/tcp_optimized.log
echo "wmem_default: $(cat /proc/sys/net/core/wmem_default)" >> /tmp/tcp_optimized.log
echo "wmem_max: $(cat /proc/sys/net/core/wmem_max)" >> /tmp/tcp_optimized.log
Subtask 1.3: Test TCP Performance Improvements
Install performance testing tools:
# Install iperf3 for network performance testing
# For RHEL/CentOS
yum install -y iperf3

# For Ubuntu/Debian
# apt update && apt install -y iperf3
Create a simple TCP performance test script:
cat << 'EOF' > /tmp/tcp_test.sh
#!/bin/bash

echo "TCP Performance Test Script"
echo "=========================="

# Test local loopback performance
echo "Starting iperf3 server in background..."
iperf3 -s -D

sleep 2

echo "Running TCP throughput test..."
iperf3 -c localhost -t 10 -P 4

echo "Stopping iperf3 server..."
pkill iperf3

echo "Test completed."
EOF

chmod +x /tmp/tcp_test.sh
Run the performance test:
# Execute the TCP performance test
/tmp/tcp_test.sh
Task 2: Optimize DNS Settings for Low-Latency Resolution
Subtask 2.1: Analyze Current DNS Configuration
Examine current DNS settings:
# Check current DNS configuration
cat /etc/resolv.conf

# Check DNS resolution time
dig google.com | grep "Query time"

# Test multiple DNS queries
for i in {1..5}; do
    echo "Query $i:"
    time nslookup google.com
done
Install DNS performance testing tools:
# Install dig and other DNS tools
# For RHEL/CentOS
yum install -y bind-utils

# For Ubuntu/Debian
# apt install -y dnsutils
Subtask 2.2: Configure Local DNS Caching
Install and configure systemd-resolved for DNS caching:
# Check if systemd-resolved is available
systemctl status systemd-resolved

# If not running, start and enable it
systemctl start systemd-resolved
systemctl enable systemd-resolved
Configure DNS caching parameters:
# Create systemd-resolved configuration
mkdir -p /etc/systemd/resolved.conf.d

cat << 'EOF' > /etc/systemd/resolved.conf.d/dns-performance.conf
[Resolve]
# Use fast public DNS servers
DNS=1.1.1.1 8.8.8.8 8.8.4.4
FallbackDNS=1.0.0.1 9.9.9.9

# Enable DNS caching
Cache=yes
CacheFromLocalhost=yes

# Set cache size (entries)
DefaultRoute=yes

# Enable DNSSEC validation
DNSSEC=yes

# Reduce DNS timeout
DNSStubListener=yes
EOF
Apply DNS configuration:
# Restart systemd-resolved
systemctl restart systemd-resolved

# Update resolv.conf to use local resolver
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Verify configuration
systemd-resolve --status
Subtask 2.3: Implement Additional DNS Optimizations
Configure DNS over HTTPS (DoH) for security and performance:
# Install cloudflared for DoH
# Download cloudflared binary
wget -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x /usr/local/bin/cloudflared

# Create cloudflared service
cat << 'EOF' > /etc/systemd/system/cloudflared.service
[Unit]
Description=Cloudflare DNS over HTTPS proxy
After=network.target

[Service]
ExecStart=/usr/local/bin/cloudflared proxy-dns --port 5053 --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

# Start cloudflared service
systemctl daemon-reload
systemctl start cloudflared
systemctl enable cloudflared
Create DNS performance monitoring script:
cat << 'EOF' > /tmp/dns_monitor.sh
#!/bin/bash

echo "DNS Performance Monitoring"
echo "========================="

# Test domains for DNS resolution time
DOMAINS=("google.com" "github.com" "stackoverflow.com" "redhat.com" "ubuntu.com")

echo "Testing DNS resolution times..."
for domain in "${DOMAINS[@]}"; do
    echo -n "Testing $domain: "
    dig +short +time=1 +tries=1 $domain > /dev/null
    if [ $? -eq 0 ]; then
        time_result=$(dig $domain | grep "Query time" | awk '{print $4}')
        echo "${time_result}ms"
    else
        echo "Failed"
    fi
done

echo ""
echo "DNS Cache Statistics:"
systemd-resolve --statistics
EOF

chmod +x /tmp/dns_monitor.sh
Run DNS performance test:
# Execute DNS monitoring script
/tmp/dns_monitor.sh
Task 3: Use netstat and ss to Monitor and Adjust Traffic
Subtask 3.1: Monitor Network Connections with netstat and ss
Install network monitoring tools:
# Install net-tools package for netstat
# For RHEL/CentOS
yum install -y net-tools

# For Ubuntu/Debian
# apt install -y net-tools
Create comprehensive network monitoring script:
cat << 'EOF' > /tmp/network_monitor.sh
#!/bin/bash

echo "Network Traffic Monitoring Report"
echo "================================="
echo "Generated on: $(date)"
echo ""

echo "1. Active Network Connections (netstat):"
echo "----------------------------------------"
netstat -tuln | head -20

echo ""
echo "2. Socket Statistics (ss):"
echo "-------------------------"
ss -tuln | head -20

echo ""
echo "3. TCP Connection States:"
echo "------------------------"
ss -tan state established | wc -l | xargs echo "ESTABLISHED connections:"
ss -tan state time-wait | wc -l | xargs echo "TIME-WAIT connections:"
ss -tan state close-wait | wc -l | xargs echo "CLOSE-WAIT connections:"

echo ""
echo "4. Network Interface Statistics:"
echo "-------------------------------"
cat /proc/net/dev | grep -E "(eth0|ens|enp)" | head -5

echo ""
echo "5. TCP Memory Usage:"
echo "-------------------"
cat /proc/net/sockstat

echo ""
echo "6. Network Buffer Usage:"
echo "-----------------------"
echo "Receive buffer: $(cat /proc/sys/net/core/rmem_default) (default), $(cat /proc/sys/net/core/rmem_max) (max)"
echo "Send buffer: $(cat /proc/sys/net/core/wmem_default) (default), $(cat /proc/sys/net/core/wmem_max) (max)"

echo ""
echo "7. Top Network Processes:"
echo "------------------------"
ss -tulpn | grep -E ":(80|443|22|53)" | head -10
EOF

chmod +x /tmp/network_monitor.sh
Run initial network monitoring:
# Execute network monitoring script
/tmp/network_monitor.sh > /tmp/network_baseline.log

# Display the report
cat /tmp/network_baseline.log
Subtask 3.2: Analyze Network Traffic Patterns
Create traffic analysis script:
cat << 'EOF' > /tmp/traffic_analysis.sh
#!/bin/bash

echo "Network Traffic Analysis"
echo "======================="

echo "Analyzing connection patterns..."

echo ""
echo "1. Connections by State:"
echo "-----------------------"
ss -tan | awk '{print $1}' | sort | uniq -c | sort -nr

echo ""
echo "2. Most Active Ports:"
echo "--------------------"
ss -tuln | awk '{print $5}' | cut -d: -f2 | sort | uniq -c | sort -nr | head -10

echo ""
echo "3. Connection Distribution by Protocol:"
echo "--------------------------------------"
ss -tan | grep -E "^tcp" | wc -l | xargs echo "TCP connections:"
ss -uan | grep -E "^udp" | wc -l | xargs echo "UDP connections:"

echo ""
echo "4. Network Interface Throughput:"
echo "-------------------------------"
for interface in $(ls /sys/class/net/ | grep -E "^(eth|ens|enp)"); do
    if [ -f "/sys/class/net/$interface/statistics/rx_bytes" ]; then
        rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes)
        tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes)
        echo "$interface: RX=$(($rx_bytes/1024/1024))MB, TX=$(($tx_bytes/1024/1024))MB"
    fi
done

echo ""
echo "5. TCP Retransmission Statistics:"
echo "--------------------------------"
cat /proc/net/netstat | grep TcpExt | tail -1 | tr ' ' '\n' | nl
EOF

chmod +x /tmp/traffic_analysis.sh
Run traffic analysis:
# Execute traffic analysis
/tmp/traffic_analysis.sh
Subtask 3.3: Implement Traffic Optimization Based on Analysis
Create dynamic traffic optimization script:
cat << 'EOF' > /tmp/optimize_traffic.sh
#!/bin/bash

echo "Dynamic Network Traffic Optimization"
echo "==================================="

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Function to optimize based on connection count
optimize_connections() {
    local conn_count=$(ss -tan state established | wc -l)
    echo "Current established connections: $conn_count"
    
    if [ $conn_count -gt 1000 ]; then
        echo "High connection count detected. Applying optimizations..."
        
        # Increase connection tracking table size
        echo 65536 > /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || true
        
        # Reduce TIME_WAIT timeout
        echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
        
        # Enable TCP recycling
        echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
        
        echo "High-load optimizations applied."
    else
        echo "Connection count is normal. Standard optimizations applied."
    fi
}

# Function to optimize based on interface utilization
optimize_interfaces() {
    echo ""
    echo "Optimizing network interfaces..."
    
    for interface in $(ls /sys/class/net/ | grep -E "^(eth|ens|enp)"); do
        if [ -d "/sys/class/net/$interface" ]; then
            # Increase interface queue length
            ifconfig $interface txqueuelen 10000 2>/dev/null || true
            echo "Optimized $interface queue length"
        fi
    done
}

# Function to monitor and adjust in real-time
monitor_and_adjust() {
    echo ""
    echo "Starting real-time monitoring (30 seconds)..."
    
    for i in {1..6}; do
        echo "Check $i/6:"
        
        # Check for high TIME_WAIT connections
        time_wait_count=$(ss -tan state time-wait | wc -l)
        echo "  TIME_WAIT connections: $time_wait_count"
        
        if [ $time_wait_count -gt 500 ]; then
            echo "  High TIME_WAIT count detected. Adjusting parameters..."
            echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
        fi
        
        # Check memory usage
        tcp_mem=$(cat /proc/net/sockstat | grep TCP | awk '{print $3}')
        echo "  TCP sockets in use: $tcp_mem"
        
        sleep 5
    done
}

# Main execution
check_root
optimize_connections
optimize_interfaces
monitor_and_adjust

echo ""
echo "Traffic optimization completed."
echo "New settings will persist until reboot."
echo "To make permanent, add to /etc/sysctl.d/99-tcp-performance.conf"
EOF

chmod +x /tmp/optimize_traffic.sh
Run traffic optimization:
# Execute traffic optimization (requires root)
sudo /tmp/optimize_traffic.sh
Create continuous monitoring service:
cat << 'EOF' > /tmp/network_watchdog.sh
#!/bin/bash

# Network performance watchdog script
LOG_FILE="/var/log/network_performance.log"

while true; do
    timestamp=$(date)
    
    # Collect metrics
    established=$(ss -tan state established | wc -l)
    time_wait=$(ss -tan state time-wait | wc -l)
    tcp_mem=$(cat /proc/net/sockstat | grep TCP | awk '{print $3}')
    
    # Log metrics
    echo "$timestamp - EST:$established TW:$time_wait MEM:$tcp_mem" >> $LOG_FILE
    
    # Alert conditions
    if [ $established -gt 2000 ]; then
        echo "$timestamp - ALERT: High connection count ($established)" >> $LOG_FILE
    fi
    
    if [ $time_wait -gt 1000 ]; then
        echo "$timestamp - ALERT: High TIME_WAIT count ($time_wait)" >> $LOG_FILE
    fi
    
    sleep 60
done
EOF

chmod +x /tmp/network_watchdog.sh
Verification and Testing
Performance Validation
Run comprehensive performance test:
cat << 'EOF' > /tmp/performance_validation.sh
#!/bin/bash

echo "Network Performance Validation"
echo "============================="

echo "1. TCP Performance Test:"
echo "-----------------------"
# Start iperf3 server
iperf3 -s -D
sleep 2

# Run client test
iperf3 -c localhost -t 10 -P 4

# Stop server
pkill iperf3

echo ""
echo "2. DNS Resolution Performance:"
echo "-----------------------------"
for i in {1..5}; do
    echo -n "Test $i: "
    time dig google.com +short > /dev/null
done

echo ""
echo "3. Connection Handling Test:"
echo "---------------------------"
echo "Current connection limits:"
ulimit -n
cat /proc/sys/net/core/somaxconn

echo ""
echo "4. Memory Usage:"
echo "---------------"
free -h
cat /proc/net/sockstat

echo ""
echo "Performance validation completed."
EOF

chmod +x /tmp/performance_validation.sh
/tmp/performance_validation.sh
Troubleshooting Common Issues
Issue 1: Permission Denied

# If you get permission denied errors
sudo su -
# Then run the commands
Issue 2: Settings Not Persisting

# Ensure settings persist across reboots
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
sysctl -p
Issue 3: High Memory Usage

# Monitor memory usage
watch -n 1 'cat /proc/net/sockstat'

# Adjust if needed
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
Conclusion
In this lab, you have successfully:

Optimized TCP parameters for high-volume data transfers by adjusting buffer sizes, enabling window scaling, and configuring advanced TCP features like BBR congestion control

Implemented DNS optimizations including local caching with systemd-resolved, DNS over HTTPS for improved security and performance, and comprehensive DNS monitoring

Mastered network monitoring tools (netstat and ss) to analyze traffic patterns, identify bottlenecks, and implement dynamic optimizations based on real-time network conditions

Key Achievements:

Increased network throughput through TCP buffer optimization
Reduced DNS resolution latency with local caching
Implemented proactive network monitoring and alerting
Created automated scripts for ongoing performance management
Why This Matters: Network performance tuning is critical in modern IT environments where applications demand high throughput and low latency. The skills learned in this lab directly apply to:

Web server optimization for high-traffic websites
Database server performance in enterprise environments
Cloud infrastructure optimization
Container and microservices networking
Real-time application performance
These optimizations can result in significant improvements in application response times, user experience, and overall system efficiency. The monitoring and tuning techniques you've learned provide the foundation for maintaining optimal network performance in production environments.

Next Steps:

Practice these techniques in different network scenarios
Explore advanced topics like DPDK and SR-IOV for extreme performance
Study network performance in containerized environments
Learn about network function virtualization (NFV) optimization
