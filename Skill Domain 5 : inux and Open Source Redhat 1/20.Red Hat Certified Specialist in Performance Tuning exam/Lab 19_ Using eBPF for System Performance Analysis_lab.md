Lab 19: Using eBPF for System Performance Analysis
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of eBPF (Extended Berkeley Packet Filter) technology
Install and configure eBPF tools for system performance monitoring
Use syscount to trace and analyze system calls in real-time
Implement gethostlatency to measure DNS resolution latency
Analyze performance bottlenecks using eBPF-based monitoring tools
Interpret eBPF output data to identify system performance issues
Apply eBPF techniques for troubleshooting production systems
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and shell scripting
Knowledge of system calls and kernel concepts
Understanding of network protocols and DNS resolution
Experience with performance monitoring concepts
Root or sudo access to a Linux system
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment - no need to build your own VM or install additional software.

Your lab environment includes:

Ubuntu 22.04 LTS or CentOS Stream 9
Pre-installed eBPF tools and dependencies
Sample applications for testing
Network connectivity for DNS testing
Task 1: Setting Up eBPF Tools and Environment
Subtask 1.1: Verify System Compatibility
First, let's check if your system supports eBPF and has the necessary kernel version.

# Check kernel version (eBPF requires kernel 4.1+, recommended 5.4+)
uname -r

# Verify eBPF support
ls /sys/kernel/debug/tracing/

# Check if BPF filesystem is mounted
mount | grep bpf
Subtask 1.2: Install eBPF Tools
Install the BCC (BPF Compiler Collection) tools which include syscount and other eBPF utilities.

For Ubuntu/Debian systems:

# Update package repository
sudo apt update

# Install BCC tools
sudo apt install -y bpfcc-tools linux-headers-$(uname -r)

# Install additional dependencies
sudo apt install -y python3-bpfcc libbpfcc-dev
For CentOS/RHEL systems:

# Install EPEL repository
sudo dnf install -y epel-release

# Install BCC tools
sudo dnf install -y bcc-tools kernel-devel-$(uname -r)

# Install Python BCC bindings
sudo dnf install -y python3-bcc
Subtask 1.3: Verify Installation
Confirm that eBPF tools are properly installed and accessible.

# Check if syscount is available
which syscount.py

# List all available BCC tools
ls /usr/share/bcc/tools/ | head -20

# Verify permissions for eBPF operations
sudo ls /sys/kernel/debug/tracing/events/
Subtask 1.4: Enable Debug Filesystem
Ensure the debug filesystem is properly mounted for eBPF operations.

# Mount debugfs if not already mounted
sudo mount -t debugfs debugfs /sys/kernel/debug

# Verify mount
mount | grep debugfs

# Check tracing capabilities
sudo ls -la /sys/kernel/debug/tracing/
Task 2: Using syscount to Trace System Calls
Subtask 2.1: Basic System Call Monitoring
Start with basic system call tracing to understand normal system behavior.

# Run syscount for 10 seconds to capture system calls
sudo /usr/share/bcc/tools/syscount.py -d 10

# Monitor system calls for a specific process (replace PID)
sudo /usr/share/bcc/tools/syscount.py -p 1234 -d 5
Subtask 2.2: Create Test Workload
Generate some system activity to observe with syscount.

# Create a test script that generates various system calls
cat > test_workload.sh << 'EOF'
#!/bin/bash
echo "Starting test workload..."

# File operations
for i in {1..100}; do
    echo "Test data $i" > /tmp/test_file_$i.txt
    cat /tmp/test_file_$i.txt > /dev/null
    rm /tmp/test_file_$i.txt
done

# Network operations
ping -c 5 8.8.8.8 > /dev/null 2>&1

# Process operations
ps aux > /dev/null
ls -la /proc/ > /dev/null

echo "Test workload completed"
EOF

chmod +x test_workload.sh
Subtask 2.3: Monitor System Calls During Workload
Run syscount while executing the test workload to observe system call patterns.

# Start syscount in background
sudo /usr/share/bcc/tools/syscount.py -d 30 > syscount_output.txt &

# Wait a moment, then run the test workload
sleep 2
./test_workload.sh

# Wait for syscount to complete
wait

# Analyze the results
cat syscount_output.txt
Subtask 2.4: Advanced syscount Usage
Explore advanced features of syscount for detailed analysis.

# Count system calls by process name
sudo /usr/share/bcc/tools/syscount.py -P -d 15

# Monitor specific system calls only
sudo /usr/share/bcc/tools/syscount.py -e open,close,read,write -d 10

# Show top system calls with intervals
sudo /usr/share/bcc/tools/syscount.py -i 2 -d 10
Subtask 2.5: Analyze syscount Output
Create a script to parse and analyze syscount output for performance insights.

# Create analysis script
cat > analyze_syscalls.py << 'EOF'
#!/usr/bin/env python3
import sys
import re

def analyze_syscount_output(filename):
    print("=== System Call Analysis ===")
    
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    # Find the summary section
    summary_started = False
    syscalls = []
    
    for line in lines:
        if "SYSCALL" in line and "COUNT" in line:
            summary_started = True
            continue
        
        if summary_started and line.strip():
            parts = line.strip().split()
            if len(parts) >= 2:
                try:
                    count = int(parts[1])
                    syscall = parts[0]
                    syscalls.append((syscall, count))
                except ValueError:
                    continue
    
    # Sort by count
    syscalls.sort(key=lambda x: x[1], reverse=True)
    
    print(f"Top 10 System Calls:")
    print(f"{'Syscall':<15} {'Count':<10} {'Percentage':<10}")
    print("-" * 35)
    
    total_calls = sum(count for _, count in syscalls)
    
    for i, (syscall, count) in enumerate(syscalls[:10]):
        percentage = (count / total_calls) * 100 if total_calls > 0 else 0
        print(f"{syscall:<15} {count:<10} {percentage:.2f}%")
    
    print(f"\nTotal system calls: {total_calls}")
    
    # Identify potential performance issues
    print("\n=== Performance Insights ===")
    high_io_calls = ['read', 'write', 'open', 'close', 'stat', 'fstat']
    network_calls = ['socket', 'connect', 'sendto', 'recvfrom']
    
    io_total = sum(count for syscall, count in syscalls if syscall in high_io_calls)
    network_total = sum(count for syscall, count in syscalls if syscall in network_calls)
    
    print(f"I/O related calls: {io_total} ({(io_total/total_calls)*100:.2f}%)")
    print(f"Network related calls: {network_total} ({(network_total/total_calls)*100:.2f}%)")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 analyze_syscalls.py <syscount_output_file>")
        sys.exit(1)
    
    analyze_syscount_output(sys.argv[1])
EOF

chmod +x analyze_syscalls.py

# Run the analysis
python3 analyze_syscalls.py syscount_output.txt
Task 3: Measuring Latency with gethostlatency
Subtask 3.1: Understanding gethostlatency
The gethostlatency tool traces DNS resolution latency by monitoring gethostbyname() and related functions.

# Check if gethostlatency is available
ls /usr/share/bcc/tools/gethostlatency.py

# View the tool's help
sudo /usr/share/bcc/tools/gethostlatency.py --help
Subtask 3.2: Basic DNS Latency Monitoring
Start monitoring DNS resolution latency in real-time.

# Start gethostlatency monitoring
sudo /usr/share/bcc/tools/gethostlatency.py
Keep this running in one terminal and open another terminal for the next steps.

Subtask 3.3: Generate DNS Resolution Activity
Create DNS lookup activity to observe with gethostlatency.

# Create a script to generate DNS lookups
cat > dns_test.sh << 'EOF'
#!/bin/bash
echo "Starting DNS resolution tests..."

# Common websites for testing
websites=(
    "google.com"
    "github.com"
    "stackoverflow.com"
    "redhat.com"
    "ubuntu.com"
    "kernel.org"
    "python.org"
    "nginx.org"
    "apache.org"
    "cloudflare.com"
)

# Perform DNS lookups
for site in "${websites[@]}"; do
    echo "Resolving $site..."
    nslookup $site > /dev/null 2>&1
    host $site > /dev/null 2>&1
    dig $site > /dev/null 2>&1
    sleep 1
done

# Test with different DNS servers
echo "Testing with different DNS servers..."
nslookup google.com 8.8.8.8 > /dev/null 2>&1
nslookup google.com 1.1.1.1 > /dev/null 2>&1
nslookup google.com 208.67.222.222 > /dev/null 2>&1

echo "DNS tests completed"
EOF

chmod +x dns_test.sh

# Run the DNS test
./dns_test.sh
Subtask 3.4: Advanced gethostlatency Usage
Explore advanced features for detailed DNS latency analysis.

# Monitor specific process DNS lookups
sudo /usr/share/bcc/tools/gethostlatency.py -p $(pgrep firefox)

# Add timestamps to output
sudo /usr/share/bcc/tools/gethostlatency.py -t

# Monitor with custom output format
sudo /usr/share/bcc/tools/gethostlatency.py -t > dns_latency.log &

# Run DNS tests and capture output
./dns_test.sh
sleep 5
sudo pkill -f gethostlatency.py

# Analyze the captured data
cat dns_latency.log
Subtask 3.5: Create DNS Latency Analysis Tool
Develop a script to analyze DNS latency patterns and identify issues.

# Create DNS latency analyzer
cat > analyze_dns_latency.py << 'EOF'
#!/usr/bin/env python3
import sys
import re
from datetime import datetime
from collections import defaultdict
import statistics

def parse_gethostlatency_output(filename):
    print("=== DNS Latency Analysis ===")
    
    latencies = []
    host_latencies = defaultdict(list)
    pid_latencies = defaultdict(list)
    
    with open(filename, 'r') as f:
        for line in f:
            # Parse gethostlatency output format
            # Example: 12:34:56 1234 curl google.com 1.23
            match = re.search(r'(\d+:\d+:\d+)\s+(\d+)\s+(\w+)\s+([^\s]+)\s+([\d.]+)', line)
            if match:
                time_str, pid, comm, host, latency = match.groups()
                latency_ms = float(latency)
                
                latencies.append(latency_ms)
                host_latencies[host].append(latency_ms)
                pid_latencies[f"{pid}({comm})"].append(latency_ms)
    
    if not latencies:
        print("No DNS latency data found in the file.")
        return
    
    # Overall statistics
    print(f"Total DNS resolutions: {len(latencies)}")
    print(f"Average latency: {statistics.mean(latencies):.2f} ms")
    print(f"Median latency: {statistics.median(latencies):.2f} ms")
    print(f"Min latency: {min(latencies):.2f} ms")
    print(f"Max latency: {max(latencies):.2f} ms")
    
    if len(latencies) > 1:
        print(f"Standard deviation: {statistics.stdev(latencies):.2f} ms")
    
    # Latency distribution
    print("\n=== Latency Distribution ===")
    ranges = [(0, 10), (10, 50), (50, 100), (100, 500), (500, float('inf'))]
    range_labels = ["0-10ms", "10-50ms", "50-100ms", "100-500ms", ">500ms"]
    
    for (min_lat, max_lat), label in zip(ranges, range_labels):
        count = sum(1 for lat in latencies if min_lat <= lat < max_lat)
        percentage = (count / len(latencies)) * 100
        print(f"{label:<10}: {count:>3} ({percentage:>5.1f}%)")
    
    # Top slowest hosts
    print("\n=== Slowest Hosts (Average Latency) ===")
    host_avg_latencies = [(host, statistics.mean(lats)) for host, lats in host_latencies.items()]
    host_avg_latencies.sort(key=lambda x: x[1], reverse=True)
    
    for host, avg_lat in host_avg_latencies[:10]:
        count = len(host_latencies[host])
        print(f"{host:<25}: {avg_lat:>6.2f} ms (n={count})")
    
    # Process analysis
    print("\n=== Process DNS Activity ===")
    pid_avg_latencies = [(pid_comm, statistics.mean(lats)) for pid_comm, lats in pid_latencies.items()]
    pid_avg_latencies.sort(key=lambda x: len(pid_latencies[x[0]]), reverse=True)
    
    for pid_comm, avg_lat in pid_avg_latencies[:5]:
        count = len(pid_latencies[pid_comm])
        print(f"{pid_comm:<20}: {count:>3} lookups, avg {avg_lat:>6.2f} ms")
    
    # Performance warnings
    print("\n=== Performance Warnings ===")
    slow_resolutions = [lat for lat in latencies if lat > 100]
    if slow_resolutions:
        print(f"⚠️  {len(slow_resolutions)} DNS resolutions took >100ms")
        print(f"   Slowest resolution: {max(slow_resolutions):.2f} ms")
    
    very_slow_resolutions = [lat for lat in latencies if lat > 500]
    if very_slow_resolutions:
        print(f"🚨 {len(very_slow_resolutions)} DNS resolutions took >500ms")
    
    if not slow_resolutions:
        print("✅ All DNS resolutions completed in reasonable time")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 analyze_dns_latency.py <gethostlatency_output_file>")
        sys.exit(1)
    
    parse_gethostlatency_output(sys.argv[1])
EOF

chmod +x analyze_dns_latency.py

# Analyze the DNS latency data
python3 analyze_dns_latency.py dns_latency.log
Task 4: Analyzing Performance Issues with eBPF
Subtask 4.1: Comprehensive System Monitoring
Create a comprehensive monitoring setup using multiple eBPF tools.

# Create a monitoring script that combines multiple tools
cat > comprehensive_monitor.sh << 'EOF'
#!/bin/bash

echo "Starting comprehensive eBPF monitoring..."
echo "Monitoring duration: 60 seconds"

# Create output directory
mkdir -p ebpf_monitoring_$(date +%Y%m%d_%H%M%S)
cd ebpf_monitoring_$(date +%Y%m%d_%H%M%S)

# Start syscount monitoring
echo "Starting syscount monitoring..."
sudo /usr/share/bcc/tools/syscount.py -P -d 60 > syscount_detailed.txt &
SYSCOUNT_PID=$!

# Start gethostlatency monitoring
echo "Starting DNS latency monitoring..."
sudo /usr/share/bcc/tools/gethostlatency.py -t > dns_latency.txt &
GETHOSTLATENCY_PID=$!

# Start additional eBPF tools if available
if [ -f /usr/share/bcc/tools/opensnoop.py ]; then
    echo "Starting file open monitoring..."
    sudo /usr/share/bcc/tools/opensnoop.py -d 60 > file_opens.txt &
    OPENSNOOP_PID=$!
fi

if [ -f /usr/share/bcc/tools/execsnoop.py ]; then
    echo "Starting process execution monitoring..."
    sudo /usr/share/bcc/tools/execsnoop.py -t > process_execs.txt &
    EXECSNOOP_PID=$!
fi

# Generate some system activity
echo "Generating test workload..."
sleep 5

# File I/O workload
for i in {1..50}; do
    dd if=/dev/zero of=test_file_$i bs=1M count=1 2>/dev/null
    sync
done

# Network activity
ping -c 10 8.8.8.8 > /dev/null 2>&1 &
ping -c 10 1.1.1.1 > /dev/null 2>&1 &

# DNS lookups
for domain in google.com github.com stackoverflow.com redhat.com; do
    nslookup $domain > /dev/null 2>&1
    host $domain > /dev/null 2>&1
done

# Process activity
ps aux > /dev/null
find /usr -name "*.conf" -type f 2>/dev/null | head -100 > /dev/null

echo "Waiting for monitoring to complete..."
wait $SYSCOUNT_PID
wait $GETHOSTLATENCY_PID

if [ ! -z "$OPENSNOOP_PID" ]; then
    sudo kill $OPENSNOOP_PID 2>/dev/null
fi

if [ ! -z "$EXECSNOOP_PID" ]; then
    sudo kill $EXECSNOOP_PID 2>/dev/null
fi

# Cleanup test files
rm -f test_file_*

echo "Monitoring completed. Results saved in $(pwd)"
ls -la
EOF

chmod +x comprehensive_monitor.sh

# Run comprehensive monitoring
./comprehensive_monitor.sh
Subtask 4.2: Performance Issue Simulation
Create scenarios that demonstrate common performance issues.

# Create performance issue simulation
cat > simulate_issues.sh << 'EOF'
#!/bin/bash

echo "=== Simulating Performance Issues ==="

# Issue 1: Excessive file I/O
echo "1. Simulating excessive file I/O..."
mkdir -p /tmp/io_test
for i in {1..200}; do
    echo "data" > /tmp/io_test/file_$i.txt
    cat /tmp/io_test/file_$i.txt > /dev/null
    rm /tmp/io_test/file_$i.txt
done
rmdir /tmp/io_test

# Issue 2: DNS resolution delays
echo "2. Simulating DNS resolution issues..."
# Query non-existent domains to cause timeouts
for i in {1..5}; do
    nslookup nonexistent$i.invalid.domain.com 2>/dev/null || true
done

# Issue 3: Rapid process creation
echo "3. Simulating rapid process creation..."
for i in {1..20}; do
    /bin/true &
done
wait

# Issue 4: System call intensive operations
echo "4. Simulating system call intensive operations..."
find /proc -type f -name "stat" -exec cat {} \; 2>/dev/null | head -1000 > /dev/null

echo "Performance issue simulation completed"
EOF

chmod +x simulate_issues.sh
Subtask 4.3: Real-time Performance Analysis
Create a real-time analysis tool that processes eBPF output.

# Create real-time analyzer
cat > realtime_analyzer.py << 'EOF'
#!/usr/bin/env python3
import subprocess
import threading
import time
import signal
import sys
from collections import defaultdict, deque
import re

class PerformanceAnalyzer:
    def __init__(self):
        self.syscall_counts = defaultdict(int)
        self.dns_latencies = deque(maxlen=100)
        self.running = True
        self.analysis_interval = 10
        
    def analyze_syscalls(self, line):
        # Parse syscount output
        if "SYSCALL" in line and "COUNT" in line:
            return
        
        parts = line.strip().split()
        if len(parts) >= 2:
            try:
                syscall = parts[0]
                count = int(parts[1])
                self.syscall_counts[syscall] += count
            except (ValueError, IndexError):
                pass
    
    def analyze_dns_latency(self, line):
        # Parse gethostlatency output
        match = re.search(r'(\d+:\d+:\d+)\s+(\d+)\s+(\w+)\s+([^\s]+)\s+([\d.]+)', line)
        if match:
            latency = float(match.group(5))
            self.dns_latencies.append(latency)
    
    def print_analysis(self):
        print("\n" + "="*50)
        print(f"Performance Analysis - {time.strftime('%H:%M:%S')}")
        print("="*50)
        
        # System call analysis
        if self.syscall_counts:
            print("\nTop System Calls:")
            sorted_syscalls = sorted(self.syscall_counts.items(), 
                                   key=lambda x: x[1], reverse=True)[:10]
            for syscall, count in sorted_syscalls:
                print(f"  {syscall:<15}: {count:>6}")
        
        # DNS latency analysis
        if self.dns_latencies:
            avg_latency = sum(self.dns_latencies) / len(self.dns_latencies)
            max_latency = max(self.dns_latencies)
            print(f"\nDNS Performance:")
            print(f"  Recent queries: {len(self.dns_latencies)}")
            print(f"  Average latency: {avg_latency:.2f} ms")
            print(f"  Max latency: {max_latency:.2f} ms")
            
            slow_queries = [lat for lat in self.dns_latencies if lat > 100]
            if slow_queries:
                print(f"  ⚠️  Slow queries (>100ms): {len(slow_queries)}")
        
        # Performance warnings
        print("\nPerformance Alerts:")
        
        # Check for excessive I/O
        io_calls = sum(count for syscall, count in self.syscall_counts.items() 
                      if syscall in ['read', 'write', 'open', 'close'])
        if io_calls > 1000:
            print(f"  🚨 High I/O activity: {io_calls} calls")
        
        # Check for DNS issues
        if self.dns_latencies:
            recent_slow = sum(1 for lat in list(self.dns_latencies)[-10:] if lat > 100)
            if recent_slow > 3:
                print(f"  🚨 DNS performance degraded: {recent_slow}/10 recent queries slow")
        
        print("-" * 50)
    
    def signal_handler(self, signum, frame):
        print("\nShutting down analyzer...")
        self.running = False
        sys.exit(0)
    
    def run_analysis_loop(self):
        while self.running:
            time.sleep(self.analysis_interval)
            self.print_analysis()

def main():
    analyzer = PerformanceAnalyzer()
    signal.signal(signal.SIGINT, analyzer.signal_handler)
    
    print("Starting real-time performance analysis...")
    print("Press Ctrl+C to stop")
    
    # Start analysis loop in background
    analysis_thread = threading.Thread(target=analyzer.run_analysis_loop)
    analysis_thread.daemon = True
    analysis_thread.start()
    
    # Simulate reading from eBPF tools
    # In a real implementation, you would read from actual tool outputs
    print("Simulating eBPF data collection...")
    print("(In production, this would read from actual syscount and gethostlatency)")
    
    try:
        while analyzer.running:
            time.sleep(1)
    except KeyboardInterrupt:
        analyzer.signal_handler(signal.SIGINT, None)

if __name__ == "__main__":
    main()
EOF

chmod +x realtime_analyzer.py

# Run the real-time analyzer (for demonstration)
echo "Real-time analyzer created. In production, this would connect to live eBPF tools."
Subtask 4.4: Performance Report Generation
Create a comprehensive performance report generator.

# Create performance report generator
cat > generate_performance_report.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
import json
import statistics
from datetime import datetime
from collections import defaultdict
import re

class PerformanceReportGenerator:
    def __init__(self, data_directory):
        self.data_dir = data_directory
        self.report = {
            'timestamp': datetime.now().isoformat(),
            'system_calls': {},
            'dns_performance': {},
            'file_operations': {},
            'process_activity': {},
            'performance_issues': [],
            'recommendations': []
        }
    
    def analyze_syscount_data(self, filename):
        """Analyze syscount output file"""
        if not os.path.exists(filename):
            return
        
        print(f"Analyzing system call data from {filename}...")
        
        with open(filename, 'r') as f:
            content = f.read()
        
        # Extract system call statistics
        syscalls = {}
        lines = content.split('\n')
        
        for line in lines:
            if line.strip() and not line.startswith('SYSCALL'):
                parts = line.strip().split()
                if len(parts) >= 2:
                    try:
                        syscall = parts[0]
                        count = int(parts[1])
                        syscalls[syscall] = count
                    except (ValueError, IndexError):
                        continue
        
        self.report['system_calls'] = {
            'total_calls': sum(syscalls.values()),
            'unique_syscalls': len(syscalls),
            'top_syscalls': dict(sorted(syscalls.items(), 
                                      key=lambda x: x[1], reverse=True)[:10])
        }
        
        # Identify performance issues
        io_calls = sum(count for syscall, count in syscalls.items() 
                      if syscall in ['read', 'write', 'open', 'close', 'stat', 'fstat'])
        
        if io_calls > 10000:
            self.report['performance_issues'].append({
                'type': 'high_io',
                'description': f'High I/O activity detected: {io_calls} I/O system calls',
                'severity': 'medium'
            })
    
    def analyze_dns_latency_data(self, filename):
        """Analyze gethostlatency output file"""
        if not os.path.exists(filename):
            return
        
        print(f"Analyzing DNS latency data from {filename}...")
        
        latencies = []
        hosts = defaultdict(list)
        
        with open(filename, 'r') as f:
            for line in f:
                match = re.search(r'(\d+:\d+:\d+)\s+(\d+)\s+(\w+)\s+([^\s]+)\s+([\d.]+)', line)
                if match:
                    host = match.group(4)
                    latency = float(match.group(5))
                    latencies.append(latency)
                    hosts[host].append(latency)
        
        if latencies:
            self.report['dns_performance'] = {
                'total_queries': len(latencies),
                'average_latency': statistics.mean(latencies),
                'median_latency': statistics.median(latencies),
                'max_latency': max(latencies),
                'min_latency': min(latencies),
                'slow_queries_count': len([l for l in latencies if l > 100]),
                'hosts_queried': len(hosts)
            }
            
            # Check for DNS performance issues
            slow_queries = [l for l in latencies if l > 100]
            if slow_queries:
                self.report['performance_issues'].append({
                    'type': 'slow_dns',
                    'description': f'{len(slow_queries)} DNS queries took >100ms',
                    'severity': 'medium' if len(slow_queries) < 10 else 'high'
                })
            
            very_slow_queries = [l for l in latencies if l > 500]
            if very_slow_queries:
                self.report['performance_issues'].append({
                    'type': 'very_slow_dns',
                    'description': f'{len(very_slow_queries)} DNS queries took >500ms',
                    'severity': 'high'
                })
    
    def analyze_file_operations(self, filename):
        """Analyze file operation data if available"""
        if not os.path.exists(filename):
            return
        
        print(f"Analyzing file operations from {filename}...")
        
        file_ops = []
        with open(filename, 'r') as f:
            for line in f:
                if line.strip():
                    file_ops.append(line.strip())
        
        self.report['file_operations'] = {
            'total_operations': len(file_ops),
            'sample_operations': file_ops[:10]  # First 10 operations
        }
    
    def generate_recommendations(self):
        """Generate performance recommendations based on analysis"""
        recommendations = []
        
        # System call recommendations
        if 'system_calls' in self.report:
            total_calls = self.report['system_calls'].get('total_calls', 0)
            if total_calls > 50000:
                recommendations.append({
                    'category': 'system_calls',
                    'recommendation': 'Consider optimizing application to reduce system call frequency',
                    'priority': 'medium'
                })
        
        # DNS recommendations
        if 'dns_performance' in self.report:
            avg_latency = self.report['dns_performance'].get('average_latency
