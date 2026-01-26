Lab 2: Installing Performance Monitoring Tools
Objectives
By the end of this lab, you will be able to:

Install and configure essential performance monitoring tools on Red Hat Enterprise Linux (RHEL)
Understand the purpose and functionality of key monitoring utilities including top, vmstat, iostat, mpstat, and sar
Execute basic monitoring tasks to analyze system performance metrics
Interpret output from various monitoring tools to identify system bottlenecks
Configure monitoring tools for continuous system observation
Apply performance monitoring best practices in enterprise environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line interface
Familiarity with RHEL system administration concepts
Knowledge of system processes and resource management
Understanding of CPU, memory, disk, and network concepts
Root or sudo access to a RHEL system
Basic text editor skills (vi/vim or nano)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated RHEL environment. No need to build your own virtual machine or configure networking - everything is ready for immediate use.

Your lab environment includes:

Red Hat Enterprise Linux 8 or 9
Root access privileges
Internet connectivity for package installation
Pre-allocated system resources for testing
Task 1: Installing Performance Monitoring Tools on RHEL
Subtask 1.1: Verify System Information
First, let's check our system information and current tool availability.

Check RHEL version and system information:
cat /etc/redhat-release
uname -a
hostnamectl
Check currently installed monitoring tools:
which top
which vmstat
which iostat
which mpstat
which sar
Display current system resource usage:
free -h
df -h
lscpu
Subtask 1.2: Install Required Packages
Most monitoring tools come from the sysstat package and are often pre-installed on RHEL systems.

Update the system package repository:
sudo dnf update -y
Install the sysstat package (contains iostat, mpstat, sar, and other tools):
sudo dnf install -y sysstat
Install additional monitoring utilities:
sudo dnf install -y htop iotop nethogs
Verify installation:
rpm -qa | grep sysstat
which iostat
which mpstat
which sar
Subtask 1.3: Enable and Configure System Activity Reporter (SAR)
The sar tool requires the sysstat service to collect data continuously.

Enable and start the sysstat service:
sudo systemctl enable sysstat
sudo systemctl start sysstat
sudo systemctl status sysstat
Configure data collection intervals by editing the sysstat configuration:
sudo vi /etc/sysconfig/sysstat
Add or modify the following line:

HISTORY=7
COMPRESSAFTER=10
Check the cron job for automatic data collection:
cat /etc/cron.d/sysstat
Task 2: Running Basic Monitoring Tasks
Subtask 2.1: Using the top Command
The top command provides real-time system monitoring and process information.

Run basic top command:
top
Key shortcuts while in top:

Press q to quit
Press 1 to show individual CPU cores
Press M to sort by memory usage
Press P to sort by CPU usage
Press k to kill a process
Run top with specific options:
# Show top 10 processes
top -n 1 -b | head -20

# Monitor specific user processes
top -u root

# Update every 2 seconds
top -d 2
Save top output to a file:
top -n 1 -b > /tmp/top_output.txt
cat /tmp/top_output.txt
Subtask 2.2: Using the sar Command
The sar (System Activity Reporter) command collects and displays system performance statistics.

Display current CPU utilization:
sar -u 1 5
This command shows CPU usage every 1 second for 5 intervals.

Display memory utilization:
sar -r 1 5
Display disk I/O statistics:
sar -d 1 5
Display network statistics:
sar -n DEV 1 5
Display load average:
sar -q 1 5
View historical data (if sysstat has been running):
# Today's data
sar -u

# Yesterday's data
sar -u -f /var/log/sa/sa$(date -d yesterday +%d)

# Specific time range
sar -u -s 10:00:00 -e 12:00:00
Generate comprehensive system report:
sar -A > /tmp/system_report.txt
Subtask 2.3: Using the vmstat Command
The vmstat command reports virtual memory statistics and system performance.

Display basic system statistics:
vmstat
Monitor system continuously:
vmstat 2 10
This shows statistics every 2 seconds for 10 intervals.

Display memory statistics in MB:
vmstat -S M 2 5
Show disk statistics:
vmstat -d
Display active and inactive memory:
vmstat -a 2 5
Create a monitoring script:
cat > /tmp/vmstat_monitor.sh << 'EOF'
#!/bin/bash
echo "=== VM Statistics Monitor ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""
echo "Current Memory and CPU Usage:"
vmstat 1 1
echo ""
echo "Disk Statistics:"
vmstat -d
EOF

chmod +x /tmp/vmstat_monitor.sh
/tmp/vmstat_monitor.sh
Subtask 2.4: Using the iostat Command
The iostat command monitors system input/output device loading.

Display basic I/O statistics:
iostat
Monitor I/O continuously:
iostat 2 5
Display extended statistics:
iostat -x 2 5
Show statistics for specific devices:
iostat -x sda 2 5
Display CPU and I/O statistics together:
iostat -c -d 2 5
Generate detailed I/O report:
iostat -x -t 1 10 > /tmp/iostat_report.txt
Monitor specific mount points:
iostat -x -m 2 5
Task 3: Advanced Monitoring Configuration
Subtask 3.1: Create Custom Monitoring Scripts
Create a comprehensive system monitoring script:
cat > /tmp/system_monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/tmp/system_monitor_$(date +%Y%m%d_%H%M%S).log"

echo "=== System Performance Monitor ===" | tee $LOG_FILE
echo "Timestamp: $(date)" | tee -a $LOG_FILE
echo "Hostname: $(hostname)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "=== CPU Information ===" | tee -a $LOG_FILE
sar -u 1 3 | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "=== Memory Usage ===" | tee -a $LOG_FILE
free -h | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "=== Disk I/O Statistics ===" | tee -a $LOG_FILE
iostat -x 1 3 | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "=== Top 10 Processes by CPU ===" | tee -a $LOG_FILE
ps aux --sort=-%cpu | head -11 | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "=== Top 10 Processes by Memory ===" | tee -a $LOG_FILE
ps aux --sort=-%mem | head -11 | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "=== Load Average ===" | tee -a $LOG_FILE
uptime | tee -a $LOG_FILE

echo "Report saved to: $LOG_FILE"
EOF

chmod +x /tmp/system_monitor.sh
Run the monitoring script:
/tmp/system_monitor.sh
Subtask 3.2: Set Up Automated Monitoring
Create a cron job for regular monitoring:
# Edit crontab
crontab -e

# Add the following line to run monitoring every 15 minutes
*/15 * * * * /tmp/system_monitor.sh > /dev/null 2>&1
Create a log rotation configuration:
sudo cat > /etc/logrotate.d/system-monitor << 'EOF'
/tmp/system_monitor_*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
Subtask 3.3: Performance Baseline Creation
Create a baseline performance script:
cat > /tmp/create_baseline.sh << 'EOF'
#!/bin/bash

BASELINE_DIR="/tmp/performance_baseline"
mkdir -p $BASELINE_DIR

echo "Creating performance baseline..."

# CPU baseline
echo "Collecting CPU baseline..."
sar -u 1 60 > $BASELINE_DIR/cpu_baseline.txt &

# Memory baseline
echo "Collecting memory baseline..."
sar -r 1 60 > $BASELINE_DIR/memory_baseline.txt &

# Disk I/O baseline
echo "Collecting disk I/O baseline..."
iostat -x 1 60 > $BASELINE_DIR/disk_baseline.txt &

# Network baseline
echo "Collecting network baseline..."
sar -n DEV 1 60 > $BASELINE_DIR/network_baseline.txt &

wait

echo "Baseline collection complete. Files saved in $BASELINE_DIR"
ls -la $BASELINE_DIR
EOF

chmod +x /tmp/create_baseline.sh
Run baseline creation (this will take about 1 minute):
/tmp/create_baseline.sh
Task 4: Interpreting Monitoring Output
Subtask 4.1: Understanding Key Metrics
Analyze top output:
top -n 1 -b | head -20
Key metrics to understand:

Load average: Should be less than number of CPU cores
CPU usage: %us (user), %sy (system), %id (idle), %wa (wait)
Memory: Total, used, free, available
Processes: Running, sleeping, stopped, zombie
Analyze vmstat output:
vmstat 1 5
Key columns:

r: Processes waiting for CPU
b: Processes in uninterruptible sleep
swpd: Virtual memory used
free: Idle memory
si/so: Swap in/out
bi/bo: Blocks in/out
us/sy/id/wa: CPU usage percentages
Analyze iostat output:
iostat -x 1 3
Key metrics:

%util: Device utilization
await: Average wait time
r/s, w/s: Read/write operations per second
rkB/s, wkB/s: Read/write kilobytes per second
Subtask 4.2: Create Performance Analysis Report
Generate comprehensive analysis:
cat > /tmp/performance_analysis.sh << 'EOF'
#!/bin/bash

echo "=== SYSTEM PERFORMANCE ANALYSIS ==="
echo "Analysis Date: $(date)"
echo ""

# System Information
echo "=== SYSTEM INFORMATION ==="
echo "Hostname: $(hostname)"
echo "OS Version: $(cat /etc/redhat-release)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime)"
echo ""

# CPU Analysis
echo "=== CPU ANALYSIS ==="
echo "CPU Cores: $(nproc)"
echo "Current Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""
echo "CPU Usage (5 samples):"
sar -u 1 5 | tail -1
echo ""

# Memory Analysis
echo "=== MEMORY ANALYSIS ==="
echo "Total Memory: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Used Memory: $(free -h | awk '/^Mem:/ {print $3}')"
echo "Available Memory: $(free -h | awk '/^Mem:/ {print $7}')"
echo "Memory Usage Percentage: $(free | awk '/^Mem:/ {printf "%.1f%%", $3/$2 * 100.0}')"
echo ""

# Disk Analysis
echo "=== DISK ANALYSIS ==="
echo "Disk Usage:"
df -h | grep -E '^/dev/'
echo ""
echo "Disk I/O Statistics:"
iostat -x 1 1 | grep -E '^[a-z]'
echo ""

# Top Processes
echo "=== TOP PROCESSES ==="
echo "Top 5 CPU consumers:"
ps aux --sort=-%cpu | head -6 | tail -5
echo ""
echo "Top 5 Memory consumers:"
ps aux --sort=-%mem | head -6 | tail -5
echo ""

# Performance Recommendations
echo "=== PERFORMANCE RECOMMENDATIONS ==="
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
CPU_CORES=$(nproc)
MEM_USAGE=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100.0}')

if (( $(echo "$LOAD_AVG > $CPU_CORES" | bc -l) )); then
    echo "- HIGH LOAD: Load average ($LOAD_AVG) exceeds CPU cores ($CPU_CORES)"
fi

if [ $MEM_USAGE -gt 80 ]; then
    echo "- HIGH MEMORY USAGE: Memory usage is ${MEM_USAGE}%"
fi

echo "- Monitor disk I/O if %util consistently > 80%"
echo "- Check for zombie processes regularly"
echo "- Consider load balancing if CPU usage consistently > 70%"
EOF

chmod +x /tmp/performance_analysis.sh
/tmp/performance_analysis.sh
Troubleshooting Common Issues
Issue 1: sysstat Service Not Starting
Problem: sysstat service fails to start

Solution:

# Check service status
sudo systemctl status sysstat

# Check logs
sudo journalctl -u sysstat

# Restart the service
sudo systemctl restart sysstat

# Verify configuration
sudo cat /etc/sysconfig/sysstat
Issue 2: No Historical Data in sar
Problem: sar shows no historical data

Solution:

# Check if data collection is enabled
sudo systemctl status sysstat

# Manually trigger data collection
sudo /usr/lib64/sa/sa1

# Check data files
ls -la /var/log/sa/
Issue 3: Permission Denied Errors
Problem: Cannot access certain monitoring data

Solution:

# Run with sudo for system-level monitoring
sudo sar -u
sudo iostat -x

# Check file permissions
ls -la /proc/
ls -la /var/log/sa/
Performance Monitoring Best Practices
1. Establish Baselines
Collect performance data during normal operations
Document typical resource usage patterns
Create alerts based on baseline deviations
2. Monitor Key Metrics
CPU: Load average, utilization, context switches
Memory: Usage, swap activity, page faults
Disk: I/O rates, response times, queue depths
Network: Throughput, packet rates, errors
3. Automate Monitoring
Set up regular data collection
Create automated reports
Implement alerting for critical thresholds
4. Historical Analysis
Keep historical data for trend analysis
Compare current performance to baselines
Identify performance degradation over time
Conclusion
In this lab, you have successfully:

Installed and configured essential performance monitoring tools on RHEL including top, vmstat, iostat, mpstat, and sar
Executed basic monitoring tasks to collect real-time and historical system performance data
Created custom monitoring scripts for automated performance analysis
Learned to interpret key performance metrics and identify potential system bottlenecks
Established performance baselines for future comparison and trend analysis
Implemented best practices for continuous system monitoring
These monitoring tools are fundamental for system administrators and performance engineers working with Red Hat Enterprise Linux systems. The skills you've developed will help you proactively identify performance issues, optimize system resources, and maintain optimal system performance in production environments.

Why This Matters: Performance monitoring is critical for maintaining system reliability, identifying bottlenecks before they impact users, and making informed decisions about system scaling and optimization. These tools provide the foundation for effective system administration and are essential skills for the Red Hat Certified Specialist in Performance Tuning certification.

Continue practicing with these tools in different scenarios, create custom monitoring solutions for your specific environment, and always remember that consistent monitoring is key to maintaining high-performance systems.
