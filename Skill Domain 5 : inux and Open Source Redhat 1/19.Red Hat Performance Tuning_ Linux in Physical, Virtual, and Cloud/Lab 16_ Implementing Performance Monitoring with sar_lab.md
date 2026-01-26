Lab 16: Implementing Performance Monitoring with sar
Objectives
By the end of this lab, students will be able to:

Install and configure the sar (System Activity Reporter) tool for comprehensive system monitoring
Set up automated data collection for historical performance tracking
Analyze CPU, memory, disk I/O, and network utilization trends over time
Generate detailed performance reports for system optimization
Interpret sar output to identify performance bottlenecks and resource constraints
Create custom monitoring scripts for specific performance metrics
Implement best practices for long-term system performance monitoring
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with system administration concepts
Knowledge of system resources (CPU, memory, disk, network)
Understanding of file permissions and cron jobs
Basic knowledge of system performance concepts
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS system
Root access for system configuration
Pre-installed system monitoring tools
Sample workload generators for testing
Task 1: Set up sar for Historical Performance Tracking
Subtask 1.1: Install and Verify sar Installation
First, let's ensure the sar tool is properly installed and configured on your system.

Step 1: Check if sar is already installed

# Check if sar is installed
which sar
sar -V
Step 2: Install sysstat package if needed

For RHEL/CentOS systems:

# Install sysstat package
sudo yum install -y sysstat

# For newer versions, use dnf
sudo dnf install -y sysstat
For Ubuntu/Debian systems:

# Update package list
sudo apt update

# Install sysstat package
sudo apt install -y sysstat
Step 3: Enable and start the sysstat service

# Enable sysstat service
sudo systemctl enable sysstat

# Start the service
sudo systemctl start sysstat

# Check service status
sudo systemctl status sysstat
Subtask 1.2: Configure Data Collection Settings
Step 1: Configure the sysstat data collection interval

# Edit the sysstat configuration file
sudo nano /etc/sysconfig/sysstat
Add or modify the following settings:

# History length (days)
HISTORY=30

# Compression settings
COMPRESSAFTER=10

# Additional options
SADC_OPTIONS="-S DISK"
Step 2: Configure cron job for automatic data collection

# Edit the sysstat cron configuration
sudo nano /etc/cron.d/sysstat
Verify or add the following entries:

# Run system activity accounting tool every 10 minutes
*/10 * * * * root /usr/lib64/sa/sa1 1 1

# Generate daily summary at 23:53
53 23 * * * root /usr/lib64/sa/sa2 -A
Step 3: Create custom data collection script

# Create a custom monitoring script
sudo nano /usr/local/bin/custom-sar-collect.sh
Add the following content:

#!/bin/bash
# Custom sar data collection script

# Set variables
LOG_DIR="/var/log/sar-custom"
DATE=$(date +%Y%m%d)
TIME=$(date +%H%M%S)

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR

# Collect comprehensive system data
echo "Starting comprehensive system monitoring at $(date)" >> $LOG_DIR/sar-$DATE.log

# CPU utilization every 2 seconds for 30 samples
sar -u 2 30 >> $LOG_DIR/cpu-$DATE-$TIME.log &

# Memory utilization
sar -r 2 30 >> $LOG_DIR/memory-$DATE-$TIME.log &

# Disk I/O statistics
sar -d 2 30 >> $LOG_DIR/disk-$DATE-$TIME.log &

# Network statistics
sar -n DEV 2 30 >> $LOG_DIR/network-$DATE-$TIME.log &

echo "Data collection completed at $(date)" >> $LOG_DIR/sar-$DATE.log
Step 4: Make the script executable and test it

# Make script executable
sudo chmod +x /usr/local/bin/custom-sar-collect.sh

# Test the script
sudo /usr/local/bin/custom-sar-collect.sh
Subtask 1.3: Verify Data Collection
Step 1: Check if data files are being created

# Check system activity data files
ls -la /var/log/sa/

# View the most recent data file
ls -lt /var/log/sa/ | head -5
Step 2: Generate some system activity for testing

# Create CPU load
stress-ng --cpu 2 --timeout 60s &

# Create memory pressure
stress-ng --vm 1 --vm-bytes 512M --timeout 60s &

# Create disk I/O
dd if=/dev/zero of=/tmp/testfile bs=1M count=100
Step 3: Verify data is being collected

# Check current system activity
sar -u 1 5

# View historical data (if available)
sar -u -f /var/log/sa/sa$(date +%d)
Task 2: Analyze Resource Utilization Trends
Subtask 2.1: CPU Utilization Analysis
Step 1: Collect and analyze CPU performance data

# Display CPU utilization for the current day
sar -u

# Show CPU utilization with specific time range
sar -u -s 09:00:00 -e 17:00:00

# Display CPU utilization for a specific date
sar -u -f /var/log/sa/sa$(date +%d)
Step 2: Create a CPU analysis script

# Create CPU analysis script
nano cpu-analysis.sh
Add the following content:

#!/bin/bash
# CPU Performance Analysis Script

echo "=== CPU Performance Analysis ==="
echo "Date: $(date)"
echo

# Current CPU utilization
echo "Current CPU Utilization (5 samples):"
sar -u 1 5

echo
echo "=== CPU Utilization Summary for Today ==="
sar -u | tail -1

echo
echo "=== Peak CPU Usage Times ==="
sar -u | grep -v "Average" | grep -v "Linux" | grep -v "^$" | sort -k3 -nr | head -5

echo
echo "=== CPU Load Average ==="
sar -q | tail -5
Step 3: Run the CPU analysis

# Make script executable
chmod +x cpu-analysis.sh

# Run the analysis
./cpu-analysis.sh
Subtask 2.2: Memory Utilization Analysis
Step 1: Analyze memory usage patterns

# Display memory utilization
sar -r

# Show memory and swap usage
sar -S

# Display memory utilization for specific time period
sar -r -s 08:00:00 -e 18:00:00
Step 2: Create memory analysis script

# Create memory analysis script
nano memory-analysis.sh
Add the following content:

#!/bin/bash
# Memory Performance Analysis Script

echo "=== Memory Performance Analysis ==="
echo "Date: $(date)"
echo

# Current memory utilization
echo "Current Memory Utilization:"
sar -r 1 3

echo
echo "=== Memory Usage Summary ==="
sar -r | tail -1

echo
echo "=== Swap Usage Analysis ==="
sar -S | tail -5

echo
echo "=== Memory Pressure Indicators ==="
# Check for high memory utilization periods
sar -r | awk '$4 > 80 {print "High memory usage at", $1, "- Used:", $4"%"}'

echo
echo "=== Page Fault Statistics ==="
sar -B | tail -5
Step 3: Execute memory analysis

# Make script executable
chmod +x memory-analysis.sh

# Run the analysis
./memory-analysis.sh
Subtask 2.3: Disk I/O Performance Analysis
Step 1: Collect disk I/O statistics

# Display disk I/O statistics
sar -d

# Show disk utilization percentage
sar -d | grep -E "(DEV|Average)"

# Display I/O statistics for specific devices
sar -d -p | grep sda
Step 2: Create disk I/O analysis script

# Create disk I/O analysis script
nano disk-analysis.sh
Add the following content:

#!/bin/bash
# Disk I/O Performance Analysis Script

echo "=== Disk I/O Performance Analysis ==="
echo "Date: $(date)"
echo

# Current disk I/O activity
echo "Current Disk I/O Activity:"
sar -d 1 3

echo
echo "=== Disk Utilization Summary ==="
sar -d | tail -5

echo
echo "=== High Disk Utilization Periods ==="
# Find periods with high disk utilization
sar -d | awk '$NF > 50 {print "High disk utilization:", $1, $2, "Util:", $NF"%"}'

echo
echo "=== Disk Transfer Rate Analysis ==="
sar -d | awk 'NR>3 && $3+$4 > 100 {print "High transfer rate:", $1, $2, "Read+Write:", $3+$4, "KB/s"}'

echo
echo "=== Average Wait Time Analysis ==="
sar -d | awk 'NR>3 && $10 > 10 {print "High wait time:", $1, $2, "Await:", $10, "ms"}'
Step 3: Run disk I/O analysis

# Make script executable
chmod +x disk-analysis.sh

# Run the analysis
./disk-analysis.sh
Subtask 2.4: Network Performance Analysis
Step 1: Collect network statistics

# Display network interface statistics
sar -n DEV

# Show network error statistics
sar -n EDEV

# Display TCP connection statistics
sar -n TCP
Step 2: Create network analysis script

# Create network analysis script
nano network-analysis.sh
Add the following content:

#!/bin/bash
# Network Performance Analysis Script

echo "=== Network Performance Analysis ==="
echo "Date: $(date)"
echo

# Current network activity
echo "Current Network Activity:"
sar -n DEV 1 3

echo
echo "=== Network Interface Summary ==="
sar -n DEV | grep -E "(IFACE|Average)" | grep -v lo

echo
echo "=== High Network Utilization Periods ==="
# Find periods with high network activity (>1MB/s)
sar -n DEV | awk '$3+$4 > 1000 && $2 != "lo" {print "High network activity:", $1, $2, "RX+TX:", ($3+$4)/1024, "MB/s"}'

echo
echo "=== Network Error Analysis ==="
sar -n EDEV | grep -v "00:00:00" | grep -v "Average" | awk '$3+$4+$5+$6 > 0'

echo
echo "=== TCP Connection Statistics ==="
sar -n TCP | tail -5
Step 3: Execute network analysis

# Make script executable
chmod +x network-analysis.sh

# Run the analysis
./network-analysis.sh
Task 3: Generate Reports for Performance Insights
Subtask 3.1: Create Comprehensive Performance Report
Step 1: Develop a master reporting script

# Create comprehensive reporting script
nano performance-report.sh
Add the following content:

#!/bin/bash
# Comprehensive Performance Report Generator

# Set variables
REPORT_DATE=$(date +%Y-%m-%d)
REPORT_FILE="/tmp/performance-report-$REPORT_DATE.txt"
SA_FILE="/var/log/sa/sa$(date +%d)"

# Function to add section headers
add_header() {
    echo "========================================" >> $REPORT_FILE
    echo "$1" >> $REPORT_FILE
    echo "========================================" >> $REPORT_FILE
    echo >> $REPORT_FILE
}

# Initialize report
echo "SYSTEM PERFORMANCE REPORT" > $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo "Hostname: $(hostname)" >> $REPORT_FILE
echo "Kernel: $(uname -r)" >> $REPORT_FILE
echo >> $REPORT_FILE

# CPU Performance Section
add_header "CPU PERFORMANCE ANALYSIS"
echo "CPU Utilization Summary:" >> $REPORT_FILE
sar -u | tail -1 >> $REPORT_FILE
echo >> $REPORT_FILE

echo "Load Average Trends:" >> $REPORT_FILE
sar -q | tail -5 >> $REPORT_FILE
echo >> $REPORT_FILE

# Memory Performance Section
add_header "MEMORY PERFORMANCE ANALYSIS"
echo "Memory Utilization Summary:" >> $REPORT_FILE
sar -r | tail -1 >> $REPORT_FILE
echo >> $REPORT_FILE

echo "Swap Usage Summary:" >> $REPORT_FILE
sar -S | tail -1 >> $REPORT_FILE
echo >> $REPORT_FILE

# Disk I/O Performance Section
add_header "DISK I/O PERFORMANCE ANALYSIS"
echo "Disk Utilization Summary:" >> $REPORT_FILE
sar -d | grep "Average" >> $REPORT_FILE
echo >> $REPORT_FILE

# Network Performance Section
add_header "NETWORK PERFORMANCE ANALYSIS"
echo "Network Interface Summary:" >> $REPORT_FILE
sar -n DEV | grep "Average" | grep -v lo >> $REPORT_FILE
echo >> $REPORT_FILE

# Performance Recommendations
add_header "PERFORMANCE RECOMMENDATIONS"

# CPU recommendations
CPU_UTIL=$(sar -u | tail -1 | awk '{print $3}')
if (( $(echo "$CPU_UTIL > 80" | bc -l) )); then
    echo "- HIGH CPU UTILIZATION DETECTED ($CPU_UTIL%)" >> $REPORT_FILE
    echo "  Consider CPU optimization or scaling" >> $REPORT_FILE
fi

# Memory recommendations
MEM_UTIL=$(sar -r | tail -1 | awk '{print $4}')
if (( $(echo "$MEM_UTIL > 85" | bc -l) )); then
    echo "- HIGH MEMORY UTILIZATION DETECTED ($MEM_UTIL%)" >> $REPORT_FILE
    echo "  Consider memory optimization or upgrade" >> $REPORT_FILE
fi

echo >> $REPORT_FILE
echo "Report generated successfully: $REPORT_FILE"
Step 2: Execute the comprehensive report

# Make script executable
chmod +x performance-report.sh

# Generate the report
./performance-report.sh

# View the generated report
cat /tmp/performance-report-$(date +%Y-%m-%d).txt
Subtask 3.2: Create Historical Trend Analysis
Step 1: Develop historical analysis script

# Create historical trend analysis script
nano historical-analysis.sh
Add the following content:

#!/bin/bash
# Historical Performance Trend Analysis

DAYS_BACK=7
REPORT_FILE="/tmp/historical-trends-$(date +%Y-%m-%d).txt"

echo "HISTORICAL PERFORMANCE TRENDS ANALYSIS" > $REPORT_FILE
echo "Analysis Period: Last $DAYS_BACK days" >> $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo >> $REPORT_FILE

# Function to analyze trends for each day
analyze_daily_trends() {
    local day_offset=$1
    local analysis_date=$(date -d "$day_offset days ago" +%d)
    local sa_file="/var/log/sa/sa$analysis_date"
    
    if [ -f "$sa_file" ]; then
        echo "=== $(date -d "$day_offset days ago" +%Y-%m-%d) ===" >> $REPORT_FILE
        
        # CPU trends
        echo "CPU Average: $(sar -u -f $sa_file | tail -1 | awk '{print $3"%"}')" >> $REPORT_FILE
        
        # Memory trends
        echo "Memory Average: $(sar -r -f $sa_file | tail -1 | awk '{print $4"%"}')" >> $REPORT_FILE
        
        # Load average
        echo "Load Average: $(sar -q -f $sa_file | tail -1 | awk '{print $4}')" >> $REPORT_FILE
        
        echo >> $REPORT_FILE
    fi
}

# Analyze trends for the past week
echo "DAILY PERFORMANCE SUMMARY:" >> $REPORT_FILE
echo "=========================" >> $REPORT_FILE
for i in $(seq 0 $((DAYS_BACK-1))); do
    analyze_daily_trends $i
done

# Peak usage analysis
echo "PEAK USAGE ANALYSIS:" >> $REPORT_FILE
echo "===================" >> $REPORT_FILE

# Find peak CPU usage across all available data
echo "Peak CPU Usage Periods:" >> $REPORT_FILE
for sa_file in /var/log/sa/sa[0-9][0-9]; do
    if [ -f "$sa_file" ]; then
        sar -u -f $sa_file | grep -v "Average" | grep -v "Linux" | grep -v "^$" | \
        awk '$3 > 90 {print FILENAME, $1, "CPU:", $3"%"}' FILENAME=$sa_file >> $REPORT_FILE
    fi
done

echo >> $REPORT_FILE
echo "Historical analysis completed: $REPORT_FILE"
Step 2: Run historical analysis

# Make script executable
chmod +x historical-analysis.sh

# Run the historical analysis
./historical-analysis.sh

# View the results
cat /tmp/historical-trends-$(date +%Y-%m-%d).txt
Subtask 3.3: Create Automated Reporting System
Step 1: Set up automated daily reporting

# Create automated daily report script
sudo nano /usr/local/bin/daily-performance-report.sh
Add the following content:

#!/bin/bash
# Automated Daily Performance Report

# Configuration
REPORT_DIR="/var/log/performance-reports"
REPORT_DATE=$(date +%Y-%m-%d)
REPORT_FILE="$REPORT_DIR/daily-report-$REPORT_DATE.txt"
EMAIL_RECIPIENT="admin@company.com"  # Change as needed

# Create report directory
mkdir -p $REPORT_DIR

# Generate report header
cat > $REPORT_FILE << EOF
DAILY PERFORMANCE REPORT
========================
Date: $REPORT_DATE
Hostname: $(hostname)
Uptime: $(uptime)

EOF

# System overview
echo "SYSTEM OVERVIEW:" >> $REPORT_FILE
echo "===============" >> $REPORT_FILE
echo "CPU Cores: $(nproc)" >> $REPORT_FILE
echo "Total Memory: $(free -h | awk '/^Mem:/ {print $2}')" >> $REPORT_FILE
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5}')" >> $REPORT_FILE
echo >> $REPORT_FILE

# Performance metrics
echo "PERFORMANCE METRICS:" >> $REPORT_FILE
echo "===================" >> $REPORT_FILE

# CPU metrics
echo "CPU Utilization:" >> $REPORT_FILE
sar -u | tail -1 >> $REPORT_FILE
echo >> $REPORT_FILE

# Memory metrics
echo "Memory Utilization:" >> $REPORT_FILE
sar -r | tail -1 >> $REPORT_FILE
echo >> $REPORT_FILE

# Disk I/O metrics
echo "Disk I/O Summary:" >> $REPORT_FILE
sar -d | grep "Average" | head -5 >> $REPORT_FILE
echo >> $REPORT_FILE

# Network metrics
echo "Network Activity:" >> $REPORT_FILE
sar -n DEV | grep "Average" | grep -v lo >> $REPORT_FILE
echo >> $REPORT_FILE

# Performance alerts
echo "PERFORMANCE ALERTS:" >> $REPORT_FILE
echo "==================" >> $REPORT_FILE

# Check for high CPU usage
HIGH_CPU=$(sar -u | tail -1 | awk '$3 > 80 {print "HIGH CPU USAGE: " $3"%"}')
if [ ! -z "$HIGH_CPU" ]; then
    echo "⚠️  $HIGH_CPU" >> $REPORT_FILE
fi

# Check for high memory usage
HIGH_MEM=$(sar -r | tail -1 | awk '$4 > 85 {print "HIGH MEMORY USAGE: " $4"%"}')
if [ ! -z "$HIGH_MEM" ]; then
    echo "⚠️  $HIGH_MEM" >> $REPORT_FILE
fi

# Check for high disk utilization
HIGH_DISK=$(sar -d | awk '$NF > 80 {print "HIGH DISK UTILIZATION: " $2 " " $NF"%"}')
if [ ! -z "$HIGH_DISK" ]; then
    echo "⚠️  $HIGH_DISK" >> $REPORT_FILE
fi

echo >> $REPORT_FILE
echo "Report generated at: $(date)" >> $REPORT_FILE

# Optional: Send email report (requires mail command)
# mail -s "Daily Performance Report - $(hostname)" $EMAIL_RECIPIENT < $REPORT_FILE

echo "Daily report generated: $REPORT_FILE"
Step 2: Set up cron job for automated reporting

# Make script executable
sudo chmod +x /usr/local/bin/daily-performance-report.sh

# Add to crontab for daily execution at 6 AM
echo "0 6 * * * root /usr/local/bin/daily-performance-report.sh" | sudo tee -a /etc/crontab

# Test the script
sudo /usr/local/bin/daily-performance-report.sh
Step 3: Create performance dashboard script

# Create real-time dashboard script
nano performance-dashboard.sh
Add the following content:

#!/bin/bash
# Real-time Performance Dashboard

# Function to display dashboard
show_dashboard() {
    clear
    echo "=========================================="
    echo "    REAL-TIME PERFORMANCE DASHBOARD"
    echo "=========================================="
    echo "Hostname: $(hostname)"
    echo "Time: $(date)"
    echo "Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
    echo
    
    echo "CPU UTILIZATION:"
    echo "================"
    sar -u 1 1 | tail -1
    echo
    
    echo "MEMORY USAGE:"
    echo "============="
    free -h
    echo
    
    echo "DISK I/O (Last 5 seconds):"
    echo "=========================="
    sar -d 1 1 | grep -E "(DEV|Average)" | head -6
    echo
    
    echo "NETWORK ACTIVITY (Last 5 seconds):"
    echo "=================================="
    sar -n DEV 1 1 | grep -E "(IFACE|Average)" | grep -v lo
    echo
    
    echo "TOP PROCESSES:"
    echo "=============="
    ps aux --sort=-%cpu | head -6
    echo
    
    echo "Press Ctrl+C to exit..."
}

# Main loop
while true; do
    show_dashboard
    sleep 5
done
Step 4: Test the dashboard

# Make script executable
chmod +x performance-dashboard.sh

# Run the dashboard (press Ctrl+C to exit)
./performance-dashboard.sh
Troubleshooting Tips
Common Issues and Solutions
Issue 1: sar command not found

# Solution: Install sysstat package
sudo yum install sysstat  # For RHEL/CentOS
sudo apt install sysstat  # For Ubuntu/Debian
Issue 2: No data in sar files

# Check if sysstat service is running
sudo systemctl status sysstat

# Restart the service
sudo systemctl restart sysstat

# Check cron configuration
sudo cat /etc/cron.d/sysstat
Issue 3: Permission denied when accessing sa files

# Check file permissions
ls -la /var/log/sa/

# Fix permissions if needed
sudo chmod 644 /var/log/sa/sa*
Issue 4: Scripts not executing properly

# Check script permissions
ls -la *.sh

# Make scripts executable
chmod +x *.sh

# Check for syntax errors
bash -n script-name.sh
Conclusion
In this comprehensive lab, you have successfully implemented a complete performance monitoring solution using the sar tool. Here's what you accomplished:

Key Achievements
Configured Historical Performance Tracking: You set up sar to automatically collect system performance data at regular intervals, creating a valuable historical database for trend analysis.

Analyzed Resource Utilization Trends: You learned to examine CPU, memory, disk I/O, and network performance patterns, identifying bottlenecks and optimization opportunities.

Generated Comprehensive Performance Reports: You created automated reporting systems that provide actionable insights into system performance, including alerts for critical thresholds.

Why This Matters
Performance monitoring with sar is crucial for:

Proactive System Management: Identifying issues before they impact users
Capacity Planning: Understanding resource usage trends to plan for future needs
Troubleshooting: Having historical data to correlate with performance problems
Optimization: Making data-driven decisions about system tuning and resource allocation
Next Steps
To further enhance your performance monitoring capabilities:

Integrate sar data with visualization tools like Grafana
Set up alerting mechanisms for critical performance thresholds
Combine sar monitoring with application-specific metrics
Implement automated performance optimization based on sar insights
The skills you've developed in this lab are essential for maintaining high-performance Linux systems in production environments and are directly applicable to Red Hat Performance Tuning certification objectives.
