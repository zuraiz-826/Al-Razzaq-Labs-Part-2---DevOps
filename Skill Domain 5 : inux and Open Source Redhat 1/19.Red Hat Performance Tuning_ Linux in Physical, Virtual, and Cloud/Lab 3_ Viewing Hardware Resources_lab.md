Lab 3: Viewing Hardware Resources
Objectives
By the end of this lab, you will be able to:

• Interpret hardware resource utilization on Linux systems using command-line tools • Analyze CPU specifications and performance characteristics using lscpu • Monitor memory usage and availability using the free command • Examine storage devices and block device information with lsblk • Gather comprehensive hardware information using lshw • Identify underutilized resources that could be optimized for better performance • Make informed decisions about system capacity planning and resource allocation

Prerequisites
Before starting this lab, you should have:

• Basic Linux command-line knowledge including navigation and file operations • Understanding of fundamental hardware concepts such as CPU, RAM, and storage • Familiarity with terminal operations and command execution • Basic knowledge of system administration concepts • Understanding of performance monitoring principles

Note: Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment - no need to build your own virtual machine.

Lab Environment Setup
Your Al Nafi cloud machine comes pre-configured with: • CentOS/RHEL 8 or 9 operating system • All necessary command-line tools pre-installed • Root or sudo access for system-level commands • Network connectivity for additional package installation if needed

Task 1: Analyzing CPU Resources with lscpu
Subtask 1.1: Basic CPU Information Gathering
The lscpu command provides detailed information about your system's CPU architecture and specifications.

Step 1: Execute the basic lscpu command

lscpu
Step 2: Analyze the key output fields

Look for these important sections in the output: • Architecture: Shows if you're running on x86_64, ARM, etc. • CPU(s): Total number of logical CPUs • Thread(s) per core: Indicates hyperthreading capability • Core(s) per socket: Physical cores per CPU socket • Socket(s): Number of physical CPU sockets • Model name: Specific CPU model and speed

Step 3: Calculate total processing capacity

Use this formula to understand your CPU resources:

Total Logical CPUs = Sockets × Cores per Socket × Threads per Core
Subtask 1.2: Advanced CPU Analysis
Step 1: Get CPU frequency information

lscpu | grep -E "(MHz|GHz)"
Step 2: Check CPU cache information

lscpu | grep -i cache
Step 3: Examine CPU flags and capabilities

lscpu | grep Flags
Key Analysis Points: • Base frequency vs maximum frequency indicates turbo boost capability • Cache sizes (L1, L2, L3) affect performance for different workloads • CPU flags show supported instruction sets and features

Task 2: Memory Analysis with free Command
Subtask 2.1: Basic Memory Information
The free command displays memory usage statistics in an easy-to-understand format.

Step 1: Display memory information in human-readable format

free -h
Step 2: Show memory statistics with detailed breakdown

free -h --wide
Step 3: Monitor memory usage over time

free -h -s 5 -c 3
This command shows memory stats every 5 seconds for 3 iterations.

Subtask 2.2: Advanced Memory Analysis
Step 1: Examine memory details from /proc/meminfo

cat /proc/meminfo | head -20
Step 2: Calculate memory utilization percentages

free | awk 'NR==2{printf "Memory Usage: %.2f%%\n", $3*100/$2}'
Step 3: Check swap usage and efficiency

free -h | grep Swap
swapon --show
Memory Analysis Guidelines: • Available memory is more important than free memory • Buffer/cache memory is reclaimable when needed • Swap usage above 10% may indicate memory pressure • High memory utilization (>80%) suggests need for more RAM

Task 3: Storage Device Analysis with lsblk
Subtask 3.1: Basic Block Device Information
The lsblk command displays block devices in a tree format, showing relationships between devices and partitions.

Step 1: Display all block devices

lsblk
Step 2: Show detailed information including filesystem types

lsblk -f
Step 3: Display size information in human-readable format

lsblk -h
Subtask 3.2: Advanced Storage Analysis
Step 1: Show detailed device information

lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,UUID
Step 2: Examine disk usage for mounted filesystems

df -h
Step 3: Check disk I/O statistics

iostat -x 1 3
If iostat is not available, install it:

sudo yum install sysstat -y
# or for Ubuntu/Debian:
# sudo apt-get install sysstat -y
Storage Analysis Points: • Device naming (sda, nvme0n1) indicates storage type • Partition layout shows how storage is organized • Filesystem types (ext4, xfs, btrfs) affect performance • Mount points show where storage is accessible

Task 4: Comprehensive Hardware Analysis with lshw
Subtask 4.1: Complete System Hardware Overview
The lshw command provides the most comprehensive hardware information available on Linux systems.

Step 1: Generate complete hardware report

sudo lshw
Step 2: Create a concise summary report

sudo lshw -short
Step 3: Focus on specific hardware classes

sudo lshw -class processor
sudo lshw -class memory
sudo lshw -class disk
sudo lshw -class network
Subtask 4.2: Network Hardware Analysis
Step 1: Examine network interfaces

sudo lshw -class network
Step 2: Check network interface status

ip link show
Step 3: Display network configuration

ip addr show
Step 4: Test network connectivity and performance

ping -c 4 8.8.8.8
Task 5: Resource Utilization Analysis and Optimization
Subtask 5.1: Real-Time Resource Monitoring
Step 1: Monitor overall system performance

top
Press q to quit when done analyzing.

Step 2: Use htop for enhanced monitoring (if available)

htop
If not installed:

sudo yum install htop -y
# or for Ubuntu/Debian:
# sudo apt-get install htop -y
Step 3: Check system load averages

uptime
Subtask 5.2: Identifying Underutilized Resources
Step 1: Create a comprehensive system report

#!/bin/bash
echo "=== SYSTEM RESOURCE ANALYSIS REPORT ==="
echo "Generated on: $(date)"
echo ""

echo "=== CPU INFORMATION ==="
lscpu | grep -E "(Model name|CPU\(s\)|Thread|Core|Socket|MHz)"
echo ""

echo "=== MEMORY UTILIZATION ==="
free -h
echo ""

echo "=== STORAGE DEVICES ==="
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
echo ""

echo "=== DISK USAGE ==="
df -h
echo ""

echo "=== SYSTEM LOAD ==="
uptime
echo ""

echo "=== NETWORK INTERFACES ==="
ip link show | grep -E "(^[0-9]|state)"
Save this script as system_report.sh and run it:

chmod +x system_report.sh
./system_report.sh
Step 2: Analyze resource utilization patterns

Create a monitoring script for continuous analysis:

#!/bin/bash
echo "Monitoring system resources for 60 seconds..."
echo "Timestamp,CPU_Usage,Memory_Usage,Disk_Usage" > resource_log.csv

for i in {1..12}; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    memory_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    disk_usage=$(df / | awk 'NR==2{print $5}' | cut -d'%' -f1)
    
    echo "$timestamp,$cpu_usage,$memory_usage,$disk_usage" >> resource_log.csv
    sleep 5
done

echo "Resource monitoring complete. Check resource_log.csv for results."
Save as monitor_resources.sh and execute:

chmod +x monitor_resources.sh
./monitor_resources.sh
Subtask 5.3: Resource Optimization Recommendations
Step 1: Analyze the collected data

cat resource_log.csv
Step 2: Generate optimization recommendations

Based on your analysis, identify:

CPU Optimization Opportunities: • Low CPU utilization (<20% average): Consider consolidating workloads • High CPU wait time: May indicate I/O bottlenecks • Uneven core utilization: Check process affinity settings

Memory Optimization Opportunities: • Excessive free memory (>50% unused): Opportunity for caching or additional services • High swap usage: Need for more physical RAM • Memory leaks: Processes with continuously growing memory usage

Storage Optimization Opportunities: • Low disk utilization: Consider storage consolidation • High I/O wait: May need faster storage or better I/O scheduling • Unbalanced partition usage: Redistribute data across available storage

Network Optimization Opportunities: • Unused network interfaces: Potential for bonding or redundancy • Low bandwidth utilization: Opportunity for additional network services • High latency: Network configuration optimization needed

Troubleshooting Common Issues
Issue 1: Command Not Found Errors
Problem: Some commands like lshw, htop, or iostat are not available.

Solution:

# For RHEL/CentOS systems:
sudo yum install lshw htop sysstat -y

# For Ubuntu/Debian systems:
sudo apt-get update
sudo apt-get install lshw htop sysstat -y
Issue 2: Permission Denied Errors
Problem: Some hardware information requires root privileges.

Solution:

# Use sudo for privileged commands
sudo lshw
sudo dmidecode
Issue 3: Incomplete Hardware Information
Problem: Virtual machines may not show complete hardware details.

Solution: This is normal in virtualized environments. Focus on the available information and note that some physical hardware details may not be accessible.

Lab Validation and Testing
Validation Checklist
Ensure you have successfully completed each task:

 CPU Analysis: Identified CPU model, cores, threads, and frequency
 Memory Analysis: Determined total, used, and available memory
 Storage Analysis: Listed all storage devices and their utilization
 Network Analysis: Identified network interfaces and their status
 Resource Monitoring: Created monitoring scripts and collected data
 Optimization Analysis: Identified underutilized resources
Performance Baseline Documentation
Create a summary document with your findings:

echo "=== HARDWARE RESOURCE BASELINE ===" > baseline_report.txt
echo "System: $(hostname)" >> baseline_report.txt
echo "Date: $(date)" >> baseline_report.txt
echo "" >> baseline_report.txt
echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)" >> baseline_report.txt
echo "Total Memory: $(free -h | awk 'NR==2{print $2}')" >> baseline_report.txt
echo "Storage: $(lsblk | grep disk | wc -l) devices" >> baseline_report.txt
echo "Network: $(ip link show | grep -c '^[0-9]') interfaces" >> baseline_report.txt
Conclusion
In this comprehensive lab, you have successfully:

• Mastered essential Linux hardware monitoring commands including lscpu, free, lsblk, and lshw • Analyzed CPU specifications and identified processing capabilities and limitations • Evaluated memory utilization patterns and identified optimization opportunities • Examined storage devices and understood disk usage patterns • Investigated network hardware and connectivity options • Created monitoring scripts for ongoing resource analysis • Identified underutilized resources that could be optimized for better performance

Why This Matters:

Understanding hardware resources is crucial for: • Performance optimization and capacity planning • Troubleshooting system bottlenecks and performance issues • Making informed decisions about hardware upgrades • Optimizing resource allocation in virtualized environments • Preparing for Red Hat Performance Tuning certification and real-world scenarios

Next Steps:

• Practice these commands regularly on different systems • Combine hardware analysis with performance monitoring tools • Explore advanced performance tuning techniques • Study Red Hat Performance Tuning documentation • Apply these skills to production environment analysis

This foundational knowledge of hardware resource analysis will serve as the basis for advanced performance tuning and system optimization tasks in your Linux administration career.
