Lab 13: System Diagnostics with sosreport
Objectives
By the end of this lab, students will be able to:

Understand the purpose and functionality of sosreport for system diagnostics
Generate comprehensive system diagnostic reports using sosreport
Navigate and analyze sosreport output to identify system information
Interpret diagnostic data to identify potential performance bottlenecks
Recognize common system misconfigurations through report analysis
Apply best practices for system troubleshooting using sosreport data
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with system administration concepts
Knowledge of Linux file system structure
Understanding of system logs and configuration files
Basic networking concepts
Root or sudo access to a Linux system
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with sosreport pre-installed
Root access for system diagnostics
Sample system configurations for analysis
Network connectivity for package management
Task 1: Understanding and Running sosreport
Subtask 1.1: Verify sosreport Installation
First, let's verify that sosreport is installed and understand its basic functionality.

# Check if sosreport is installed
which sosreport

# Check sosreport version
sosreport --version

# If sosreport is not installed, install it
sudo dnf install sos -y
# or for Ubuntu/Debian systems:
# sudo apt-get install sosreport -y
Subtask 1.2: Explore sosreport Help and Options
Understanding available options helps customize the diagnostic collection process.

# Display sosreport help
sosreport --help

# List available plugins
sosreport --list-plugins

# Show plugin information
sosreport --describe networking
sosreport --describe kernel
sosreport --describe performance
Subtask 1.3: Run Basic sosreport Collection
Generate a comprehensive system diagnostic report with default settings.

# Create a directory for sosreports
sudo mkdir -p /var/tmp/sosreports
cd /var/tmp/sosreports

# Run sosreport with basic options
sudo sosreport --batch --tmp-dir=/var/tmp/sosreports

# The --batch flag runs without interactive prompts
# --tmp-dir specifies where to store the report
Expected Output: The command will create a compressed archive file with a name like sosreport-hostname-YYYY-MM-DD-HHMMSS.tar.xz

Subtask 1.4: Run Targeted sosreport Collection
Generate reports focusing on specific system areas for targeted analysis.

# Generate report focusing on networking issues
sudo sosreport --batch --only-plugins=networking,network,firewalld,iptables --tmp-dir=/var/tmp/sosreports

# Generate report for performance analysis
sudo sosreport --batch --only-plugins=performance,kernel,memory,processor,block --tmp-dir=/var/tmp/sosreports

# Generate report for storage issues
sudo sosreport --batch --only-plugins=block,filesys,lvm2,md,multipath --tmp-dir=/var/tmp/sosreports
Subtask 1.5: Extract and Examine Report Structure
Extract the generated report and understand its structure.

# List generated reports
ls -la /var/tmp/sosreports/

# Extract the most recent report (adjust filename as needed)
LATEST_REPORT=$(ls -t /var/tmp/sosreports/sosreport-*.tar.xz | head -1)
echo "Extracting: $LATEST_REPORT"

# Extract the report
cd /var/tmp/sosreports
tar -xf $LATEST_REPORT

# Navigate to extracted directory
EXTRACTED_DIR=$(basename $LATEST_REPORT .tar.xz)
cd $EXTRACTED_DIR

# Examine the directory structure
tree -L 2 . || find . -maxdepth 2 -type d
Task 2: Analyzing the Generated Report for System Issues
Subtask 2.1: System Overview Analysis
Begin analysis by examining system overview information.

# Navigate to the extracted sosreport directory
cd /var/tmp/sosreports/sosreport-*

# Examine system information
echo "=== HOSTNAME INFORMATION ==="
cat hostname

echo -e "\n=== SYSTEM UPTIME ==="
cat uptime

echo -e "\n=== SYSTEM DATE ==="
cat date

echo -e "\n=== OS RELEASE INFORMATION ==="
cat etc/os-release

echo -e "\n=== KERNEL VERSION ==="
cat uname

echo -e "\n=== SYSTEM LOAD AVERAGE ==="
cat proc/loadavg
Subtask 2.2: Hardware and Performance Analysis
Analyze hardware configuration and performance metrics.

# CPU Information Analysis
echo "=== CPU INFORMATION ==="
cat proc/cpuinfo | grep -E "(processor|model name|cpu MHz|cache size)" | head -20

echo -e "\n=== CPU UTILIZATION ==="
if [ -f sar_files/sar* ]; then
    echo "SAR data available for detailed CPU analysis"
    ls sar_files/
fi

# Memory Analysis
echo -e "\n=== MEMORY INFORMATION ==="
cat proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree)"

echo -e "\n=== MEMORY USAGE ANALYSIS ==="
if [ -f free ]; then
    cat free
fi

# Check for memory pressure indicators
echo -e "\n=== CHECKING FOR MEMORY PRESSURE ==="
if [ -f proc/pressure/memory ]; then
    cat proc/pressure/memory
fi
Subtask 2.3: Storage and Filesystem Analysis
Examine storage configuration and identify potential bottlenecks.

# Disk Usage Analysis
echo "=== DISK USAGE INFORMATION ==="
cat df

echo -e "\n=== FILESYSTEM MOUNT INFORMATION ==="
cat proc/mounts | grep -v tmpfs | head -10

echo -e "\n=== BLOCK DEVICE INFORMATION ==="
if [ -f lsblk ]; then
    cat lsblk
fi

# I/O Statistics Analysis
echo -e "\n=== I/O STATISTICS ==="
if [ -f proc/diskstats ]; then
    echo "Disk statistics available:"
    head -10 proc/diskstats
fi

# Check for filesystem errors
echo -e "\n=== CHECKING FILESYSTEM ERRORS ==="
grep -i "error\|fail\|corrupt" var/log/messages* 2>/dev/null | head -5 || echo "No obvious filesystem errors found"
Subtask 2.4: Network Configuration Analysis
Analyze network configuration and identify connectivity issues.

# Network Interface Analysis
echo "=== NETWORK INTERFACE INFORMATION ==="
if [ -f ip_addr ]; then
    cat ip_addr
fi

echo -e "\n=== NETWORK ROUTING INFORMATION ==="
if [ -f ip_route ]; then
    cat ip_route
fi

echo -e "\n=== NETWORK STATISTICS ==="
if [ -f proc/net/dev ]; then
    cat proc/net/dev
fi

# DNS Configuration
echo -e "\n=== DNS CONFIGURATION ==="
if [ -f etc/resolv.conf ]; then
    cat etc/resolv.conf
fi

# Network Service Status
echo -e "\n=== NETWORK SERVICE STATUS ==="
grep -i "network\|dhcp" systemctl_list-units 2>/dev/null | head -5 || echo "Network service information not available in this format"
Subtask 2.5: Service and Process Analysis
Examine running services and processes for performance issues.

# Process Analysis
echo "=== TOP PROCESSES BY CPU/MEMORY ==="
if [ -f ps ]; then
    echo "Process information available:"
    head -20 ps
fi

# Service Status Analysis
echo -e "\n=== FAILED SERVICES ==="
grep -i "failed\|error" systemctl_list-units 2>/dev/null | head -10 || echo "No failed services found in current format"

# System Load Analysis
echo -e "\n=== SYSTEM LOAD ANALYSIS ==="
if [ -f proc/loadavg ]; then
    LOAD=$(cat proc/loadavg | awk '{print $1}')
    CPU_COUNT=$(grep -c processor proc/cpuinfo)
    echo "Current load: $LOAD"
    echo "CPU count: $CPU_COUNT"
    echo "Load per CPU: $(echo "scale=2; $LOAD / $CPU_COUNT" | bc 2>/dev/null || echo "calculation unavailable")"
fi
Subtask 2.6: Log Analysis for System Issues
Analyze system logs for errors and warnings.

# System Log Analysis
echo "=== RECENT SYSTEM ERRORS ==="
if [ -d var/log ]; then
    echo "Checking for critical errors in system logs:"
    grep -i "error\|critical\|fail" var/log/messages* 2>/dev/null | tail -10 || echo "No recent critical errors found"
fi

echo -e "\n=== KERNEL MESSAGES ==="
if [ -f var/log/dmesg ]; then
    echo "Recent kernel messages:"
    tail -20 var/log/dmesg
fi

echo -e "\n=== AUTHENTICATION FAILURES ==="
if [ -f var/log/secure ]; then
    echo "Recent authentication issues:"
    grep -i "failed\|invalid" var/log/secure 2>/dev/null | tail -5 || echo "No recent authentication failures"
fi
Subtask 2.7: Performance Bottleneck Identification
Create a comprehensive analysis script to identify common performance issues.

# Create performance analysis script
cat > /tmp/analyze_performance.sh << 'EOF'
#!/bin/bash

echo "=== SOSREPORT PERFORMANCE ANALYSIS ==="
echo "Analysis Date: $(date)"
echo "========================================="

# CPU Analysis
echo -e "\n1. CPU ANALYSIS:"
if [ -f proc/cpuinfo ]; then
    CPU_COUNT=$(grep -c processor proc/cpuinfo)
    echo "   - CPU Cores: $CPU_COUNT"
fi

if [ -f proc/loadavg ]; then
    LOAD_1MIN=$(awk '{print $1}' proc/loadavg)
    LOAD_5MIN=$(awk '{print $2}' proc/loadavg)
    LOAD_15MIN=$(awk '{print $3}' proc/loadavg)
    echo "   - Load Average: $LOAD_1MIN (1min), $LOAD_5MIN (5min), $LOAD_15MIN (15min)"
    
    # Load analysis
    if (( $(echo "$LOAD_1MIN > $CPU_COUNT" | bc -l 2>/dev/null || echo 0) )); then
        echo "   - WARNING: High CPU load detected!"
    fi
fi

# Memory Analysis
echo -e "\n2. MEMORY ANALYSIS:"
if [ -f proc/meminfo ]; then
    TOTAL_MEM=$(grep MemTotal proc/meminfo | awk '{print $2}')
    FREE_MEM=$(grep MemFree proc/meminfo | awk '{print $2}')
    AVAILABLE_MEM=$(grep MemAvailable proc/meminfo | awk '{print $2}')
    
    echo "   - Total Memory: $((TOTAL_MEM/1024)) MB"
    echo "   - Free Memory: $((FREE_MEM/1024)) MB"
    echo "   - Available Memory: $((AVAILABLE_MEM/1024)) MB"
    
    # Memory usage percentage
    USED_PERCENT=$(echo "scale=2; (($TOTAL_MEM - $AVAILABLE_MEM) * 100) / $TOTAL_MEM" | bc 2>/dev/null || echo "0")
    echo "   - Memory Usage: ${USED_PERCENT}%"
    
    if (( $(echo "$USED_PERCENT > 90" | bc -l 2>/dev/null || echo 0) )); then
        echo "   - WARNING: High memory usage detected!"
    fi
fi

# Disk Analysis
echo -e "\n3. DISK ANALYSIS:"
if [ -f df ]; then
    echo "   - Filesystem usage:"
    while read line; do
        if echo "$line" | grep -q "%"; then
            USAGE=$(echo "$line" | awk '{print $5}' | sed 's/%//')
            FILESYSTEM=$(echo "$line" | awk '{print $6}')
            echo "     $FILESYSTEM: ${USAGE}%"
            if [ "$USAGE" -gt 90 ] 2>/dev/null; then
                echo "     WARNING: High disk usage on $FILESYSTEM!"
            fi
        fi
    done < df
fi

# Network Analysis
echo -e "\n4. NETWORK ANALYSIS:"
if [ -f proc/net/dev ]; then
    echo "   - Network interface statistics available"
    echo "   - Check for high error rates or dropped packets"
fi

echo -e "\n5. RECOMMENDATIONS:"
echo "   - Monitor systems with high CPU load or memory usage"
echo "   - Investigate filesystems with >90% usage"
echo "   - Review system logs for recurring errors"
echo "   - Consider performance tuning for bottlenecked resources"

EOF

# Make script executable and run it
chmod +x /tmp/analyze_performance.sh
/tmp/analyze_performance.sh
Subtask 2.8: Generate System Health Report
Create a comprehensive system health summary.

# Create system health report
cat > /tmp/system_health_report.txt << EOF
SYSTEM HEALTH ANALYSIS REPORT
Generated: $(date)
Sosreport Location: $(pwd)

=== SYSTEM OVERVIEW ===
Hostname: $(cat hostname 2>/dev/null || echo "Unknown")
OS Version: $(grep PRETTY_NAME etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Unknown")
Kernel: $(cat uname 2>/dev/null || echo "Unknown")
Uptime: $(cat uptime 2>/dev/null || echo "Unknown")

=== CRITICAL FINDINGS ===
EOF

# Add critical findings to report
echo "Analyzing system for critical issues..." >> /tmp/system_health_report.txt

# Check for high load
if [ -f proc/loadavg ]; then
    LOAD=$(awk '{print $1}' proc/loadavg)
    CPU_COUNT=$(grep -c processor proc/cpuinfo 2>/dev/null || echo 1)
    if (( $(echo "$LOAD > $CPU_COUNT * 2" | bc -l 2>/dev/null || echo 0) )); then
        echo "- HIGH CPU LOAD: Load average ($LOAD) exceeds CPU capacity" >> /tmp/system_health_report.txt
    fi
fi

# Check for low memory
if [ -f proc/meminfo ]; then
    AVAILABLE=$(grep MemAvailable proc/meminfo | awk '{print $2}')
    TOTAL=$(grep MemTotal proc/meminfo | awk '{print $2}')
    if [ "$AVAILABLE" -lt "$((TOTAL/10))" ] 2>/dev/null; then
        echo "- LOW MEMORY: Available memory is less than 10% of total" >> /tmp/system_health_report.txt
    fi
fi

# Check for full filesystems
if [ -f df ]; then
    while read line; do
        if echo "$line" | grep -q "%"; then
            USAGE=$(echo "$line" | awk '{print $5}' | sed 's/%//')
            FILESYSTEM=$(echo "$line" | awk '{print $6}')
            if [ "$USAGE" -gt 95 ] 2>/dev/null; then
                echo "- DISK FULL: $FILESYSTEM is ${USAGE}% full" >> /tmp/system_health_report.txt
            fi
        fi
    done < df
fi

echo "" >> /tmp/system_health_report.txt
echo "=== RECOMMENDATIONS ===" >> /tmp/system_health_report.txt
echo "1. Review detailed analysis above for specific issues" >> /tmp/system_health_report.txt
echo "2. Monitor resource usage trends over time" >> /tmp/system_health_report.txt
echo "3. Implement proactive monitoring for identified bottlenecks" >> /tmp/system_health_report.txt
echo "4. Consider hardware upgrades for consistently high resource usage" >> /tmp/system_health_report.txt

# Display the report
cat /tmp/system_health_report.txt
Advanced Analysis Techniques
Creating Custom Analysis Scripts
For ongoing system monitoring, create reusable analysis scripts:

# Create a comprehensive sosreport analyzer
cat > /usr/local/bin/sosreport-analyzer << 'EOF'
#!/bin/bash

SOSREPORT_DIR="$1"

if [ -z "$SOSREPORT_DIR" ] || [ ! -d "$SOSREPORT_DIR" ]; then
    echo "Usage: $0 <sosreport_directory>"
    exit 1
fi

cd "$SOSREPORT_DIR"

echo "SOSREPORT ANALYSIS SUMMARY"
echo "=========================="
echo "Report Directory: $(pwd)"
echo "Analysis Time: $(date)"
echo ""

# Function to check if file exists and is readable
check_file() {
    [ -f "$1" ] && [ -r "$1" ]
}

# System Information
echo "SYSTEM INFORMATION:"
check_file hostname && echo "  Hostname: $(cat hostname)"
check_file etc/os-release && echo "  OS: $(grep PRETTY_NAME etc/os-release | cut -d'"' -f2)"
check_file uname && echo "  Kernel: $(cat uname)"
echo ""

# Performance Metrics
echo "PERFORMANCE METRICS:"
if check_file proc/loadavg; then
    LOAD=$(awk '{print $1}' proc/loadavg)
    CPU_COUNT=$(grep -c processor proc/cpuinfo 2>/dev/null || echo 1)
    echo "  Load Average: $LOAD (CPUs: $CPU_COUNT)"
fi

if check_file proc/meminfo; then
    TOTAL=$(grep MemTotal proc/meminfo | awk '{print $2}')
    AVAILABLE=$(grep MemAvailable proc/meminfo | awk '{print $2}')
    USED_PERCENT=$(echo "scale=1; (($TOTAL - $AVAILABLE) * 100) / $TOTAL" | bc 2>/dev/null || echo "0")
    echo "  Memory Usage: ${USED_PERCENT}% of $((TOTAL/1024/1024))GB"
fi

echo ""

# Disk Usage
echo "DISK USAGE:"
if check_file df; then
    grep -v "tmpfs\|devtmpfs" df | while read line; do
        if echo "$line" | grep -q "%"; then
            echo "  $line"
        fi
    done
fi

echo ""

# Recent Errors
echo "RECENT SYSTEM ERRORS:"
if check_file var/log/messages; then
    ERROR_COUNT=$(grep -i "error\|critical\|fail" var/log/messages 2>/dev/null | wc -l)
    echo "  Found $ERROR_COUNT error entries in system log"
fi

EOF

# Make the analyzer executable
sudo chmod +x /usr/local/bin/sosreport-analyzer

# Test the analyzer
/usr/local/bin/sosreport-analyzer $(pwd)
Troubleshooting Common Issues
Issue 1: sosreport Command Not Found
# Install sosreport on different distributions
# RHEL/CentOS/Fedora:
sudo dnf install sos

# Ubuntu/Debian:
sudo apt-get update
sudo apt-get install sosreport

# Verify installation
which sosreport
sosreport --version
Issue 2: Permission Denied Errors
# Ensure you're running with appropriate privileges
sudo sosreport --batch

# Check if /tmp has sufficient space and permissions
df -h /tmp
ls -ld /tmp
Issue 3: Large Report Size
# Generate smaller, targeted reports
sudo sosreport --batch --only-plugins=kernel,memory,networking

# Exclude unnecessary plugins
sudo sosreport --batch --skip-plugins=logs,rpm
Issue 4: Analysis Script Errors
# Ensure bc calculator is installed for mathematical operations
sudo dnf install bc -y
# or
sudo apt-get install bc -y

# Check file permissions in extracted sosreport
find . -name "*.txt" -o -name "proc" -o -name "etc" | head -10
Best Practices for sosreport Usage
Regular System Health Checks
# Create a monthly sosreport collection script
cat > /usr/local/bin/monthly-sosreport << 'EOF'
#!/bin/bash

DATE=$(date +%Y%m%d)
REPORT_DIR="/var/log/sosreports"
mkdir -p "$REPORT_DIR"

echo "Generating monthly sosreport for $DATE"
sudo sosreport --batch --tmp-dir="$REPORT_DIR" \
    --only-plugins=kernel,memory,networking,performance,block \
    --label="monthly-$DATE"

echo "Report generated in $REPORT_DIR"
ls -la "$REPORT_DIR"/sosreport-*monthly-$DATE*
EOF

chmod +x /usr/local/bin/monthly-sosreport
Automated Analysis Pipeline
# Create automated analysis workflow
cat > /usr/local/bin/sosreport-workflow << 'EOF'
#!/bin/bash

WORK_DIR="/tmp/sosreport-analysis"
mkdir -p "$WORK_DIR"

echo "Starting sosreport analysis workflow..."

# Generate report
echo "1. Generating sosreport..."
sudo sosreport --batch --tmp-dir="$WORK_DIR"

# Extract latest report
echo "2. Extracting report..."
cd "$WORK_DIR"
LATEST=$(ls -t sosreport-*.tar.xz | head -1)
tar -xf "$LATEST"

# Analyze report
echo "3. Analyzing report..."
EXTRACTED_DIR=$(basename "$LATEST" .tar.xz)
/usr/local/bin/sosreport-analyzer "$WORK_DIR/$EXTRACTED_DIR"

echo "4. Workflow complete. Files in $WORK_DIR"
EOF

chmod +x /usr/local/bin/sosreport-workflow
Conclusion
In this comprehensive lab, you have successfully learned to use sosreport for system diagnostics and analysis. You have accomplished the following key objectives:

Technical Skills Developed:

Generated comprehensive system diagnostic reports using sosreport
Analyzed system performance metrics including CPU, memory, and disk usage
Identified potential performance bottlenecks through systematic analysis
Created custom analysis scripts for ongoing system monitoring
Developed troubleshooting workflows for common system issues
Practical Applications:

System Administration: sosreport provides a standardized way to collect system information for troubleshooting
Performance Tuning: The diagnostic data helps identify resource constraints and optimization opportunities
Incident Response: Comprehensive system snapshots aid in root cause analysis
Compliance and Auditing: Regular sosreports document system configurations and changes
Why This Matters: sosreport is an essential tool for Linux system administrators and performance engineers. It provides a comprehensive, standardized method for collecting system diagnostic information that can be shared with support teams, analyzed for performance optimization, or used for system documentation. The skills you've developed in this lab are directly applicable to real-world system administration tasks and are valuable for Red Hat certification paths.

Next Steps:

Practice generating sosreports on different system configurations
Develop custom analysis scripts for your specific environment
Integrate sosreport collection into your regular system maintenance procedures
Explore advanced sosreport plugins for specialized system components
The systematic approach to system diagnostics you've learned will serve as a foundation for advanced performance tuning and troubleshooting scenarios in production environments.
