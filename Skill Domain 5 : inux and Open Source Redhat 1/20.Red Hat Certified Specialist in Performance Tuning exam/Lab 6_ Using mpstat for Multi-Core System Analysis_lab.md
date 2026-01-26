Lab 6: Using mpstat for Multi-Core System Analysis
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of multi-core CPU architecture and performance monitoring
Install and configure the sysstat package containing mpstat utility
Execute mpstat commands to monitor CPU usage across multiple cores
Interpret mpstat output to identify performance bottlenecks and resource utilization patterns
Analyze CPU load distribution across individual cores and logical processors
Generate CPU stress scenarios to observe real-time performance metrics
Optimize resource allocation based on mpstat analysis results
Create automated monitoring scripts for continuous CPU performance tracking
Apply performance tuning techniques for multi-core systems
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command-line interface
Familiarity with system administration concepts
Knowledge of CPU architecture fundamentals (cores, threads, hyperthreading)
Understanding of system performance metrics
Basic scripting knowledge (bash preferred)
Familiarity with process management in Linux
Lab Environment Setup
Al Nafi Cloud Machines: This lab uses Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machine or install additional software.

Your cloud machine includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Multi-core CPU configuration
Pre-installed development tools
Root access for system monitoring
Network connectivity for package installation
Task 1: Environment Preparation and mpstat Installation
Subtask 1.1: Verify System Information
First, let's examine your system's CPU configuration to understand the multi-core architecture.

# Check CPU information
lscpu

# Display detailed CPU architecture
cat /proc/cpuinfo | grep -E "(processor|model name|cpu cores|siblings)"

# Check the number of logical CPUs
nproc

# Verify system load
uptime
Expected Output Analysis:

processor: Shows logical CPU numbers (0, 1, 2, etc.)
cpu cores: Physical cores per socket
siblings: Logical processors per socket (includes hyperthreading)
model name: CPU model and specifications
Subtask 1.2: Install sysstat Package
The mpstat utility is part of the sysstat package. Let's install it:

For RHEL/CentOS systems:

# Update package repository
sudo yum update -y

# Install sysstat package
sudo yum install -y sysstat

# Verify installation
mpstat -V
For Ubuntu/Debian systems:

# Update package repository
sudo apt update

# Install sysstat package
sudo apt install -y sysstat

# Verify installation
mpstat -V
Subtask 1.3: Enable sysstat Data Collection
# Enable sysstat service for historical data collection
sudo systemctl enable sysstat
sudo systemctl start sysstat

# Verify service status
sudo systemctl status sysstat

# Check sysstat configuration
cat /etc/default/sysstat
Task 2: Basic mpstat Usage and CPU Monitoring
Subtask 2.1: Understanding mpstat Command Structure
The basic syntax of mpstat is:

mpstat [options] [interval] [count]
Key Options:

-P: Specify which processors to monitor (ALL, 0, 1, 2, etc.)
-u: Display CPU utilization (default)
-I: Display interrupt statistics
-A: Display all available statistics
Subtask 2.2: Basic CPU Monitoring
# Display current CPU statistics for all processors
mpstat -P ALL

# Monitor CPU usage every 2 seconds for 5 iterations
mpstat -P ALL 2 5

# Monitor specific CPU core (core 0)
mpstat -P 0 2 5

# Display CPU statistics with timestamps
mpstat -P ALL 1 3 | head -20
Understanding the Output:

%usr: User space CPU utilization
%nice: Nice priority processes CPU utilization
%sys: System/kernel space CPU utilization
%iowait: CPU idle time waiting for I/O operations
%irq: Hardware interrupt CPU utilization
%soft: Software interrupt CPU utilization
%steal: Virtual CPU wait time (relevant in virtualized environments)
%guest: Virtual processor CPU utilization
%idle: CPU idle time percentage
Subtask 2.3: Creating a Baseline Measurement
# Create a baseline measurement script
cat > baseline_cpu.sh << 'EOF'
#!/bin/bash

echo "=== CPU Baseline Measurement ==="
echo "Date: $(date)"
echo "System: $(hostname)"
echo ""

echo "=== CPU Architecture ==="
lscpu | grep -E "(Architecture|CPU\(s\)|Thread|Core|Socket)"
echo ""

echo "=== Current CPU Usage (10 second average) ==="
mpstat -P ALL 1 10 | grep "Average"
echo ""

echo "=== System Load ==="
uptime
echo ""

echo "=== Top CPU Consuming Processes ==="
ps aux --sort=-%cpu | head -10
EOF

# Make script executable
chmod +x baseline_cpu.sh

# Run baseline measurement
./baseline_cpu.sh
Task 3: Advanced CPU Load Distribution Analysis
Subtask 3.1: Generate CPU Load for Testing
To properly analyze CPU performance, we need to create controlled load scenarios:

# Install stress testing tools
# For RHEL/CentOS:
sudo yum install -y stress

# For Ubuntu/Debian:
# sudo apt install -y stress

# Create CPU stress on all cores
stress --cpu $(nproc) --timeout 60s &

# Monitor during stress test
mpstat -P ALL 2 30
Subtask 3.2: Analyze Load Distribution Patterns
# Create a comprehensive monitoring script
cat > cpu_analysis.sh << 'EOF'
#!/bin/bash

DURATION=${1:-30}
INTERVAL=${2:-2}

echo "=== Multi-Core CPU Analysis ==="
echo "Monitoring for $DURATION seconds with $INTERVAL second intervals"
echo "Start time: $(date)"
echo ""

# Start background monitoring
mpstat -P ALL $INTERVAL $((DURATION/INTERVAL)) > cpu_stats.log &
MPSTAT_PID=$!

# Generate different types of load
echo "Generating single-core load..."
stress --cpu 1 --timeout 10s &

sleep 12

echo "Generating multi-core load..."
stress --cpu $(nproc) --timeout 10s &

sleep 12

echo "Generating I/O intensive load..."
stress --io 2 --timeout 8s &

# Wait for monitoring to complete
wait $MPSTAT_PID

echo ""
echo "=== Analysis Results ==="
echo "Average CPU utilization per core:"
grep "Average" cpu_stats.log

echo ""
echo "Peak utilization periods:"
awk '/^[0-9]/ && $3 != "CPU" && $4+$5+$6 > 50 {print $1, $2, "CPU"$3, "Total:", $4+$5+$6"%"}' cpu_stats.log | head -10
EOF

chmod +x cpu_analysis.sh

# Run the analysis
./cpu_analysis.sh 60 2
Subtask 3.3: Identify CPU Bottlenecks
# Create bottleneck detection script
cat > detect_bottlenecks.sh << 'EOF'
#!/bin/bash

echo "=== CPU Bottleneck Detection ==="

# Function to analyze CPU metrics
analyze_cpu_metrics() {
    local logfile=$1
    
    echo "Analyzing CPU metrics from $logfile"
    echo ""
    
    # Calculate average utilization per CPU
    echo "=== Average CPU Utilization per Core ==="
    awk '
    /Average/ && $3 ~ /^[0-9]+$/ {
        cpu = $3
        usr = $4
        sys = $6
        total = usr + sys
        printf "CPU %s: User=%.1f%% System=%.1f%% Total=%.1f%%\n", cpu, usr, sys, total
    }
    ' $logfile
    
    echo ""
    
    # Identify imbalanced cores
    echo "=== Load Imbalance Detection ==="
    awk '
    /Average/ && $3 ~ /^[0-9]+$/ {
        cpu = $3
        total = $4 + $6  # usr + sys
        if (total > 80) print "HIGH LOAD: CPU " cpu " at " total "%"
        else if (total < 10) print "LOW LOAD: CPU " cpu " at " total "%"
    }
    ' $logfile
    
    echo ""
    
    # Check for I/O wait issues
    echo "=== I/O Wait Analysis ==="
    awk '
    /Average/ && $3 ~ /^[0-9]+$/ {
        cpu = $3
        iowait = $7
        if (iowait > 20) print "HIGH I/O WAIT: CPU " cpu " at " iowait "%"
    }
    ' $logfile
}

# Run analysis on existing log
if [ -f "cpu_stats.log" ]; then
    analyze_cpu_metrics "cpu_stats.log"
else
    echo "No existing log found. Generating new data..."
    mpstat -P ALL 2 15 > temp_cpu_stats.log
    analyze_cpu_metrics "temp_cpu_stats.log"
fi
EOF

chmod +x detect_bottlenecks.sh
./detect_bottlenecks.sh
Task 4: Resource Allocation Optimization
Subtask 4.1: CPU Affinity Analysis
# Create CPU affinity testing script
cat > cpu_affinity_test.sh << 'EOF'
#!/bin/bash

echo "=== CPU Affinity and Load Balancing Test ==="

# Function to run process on specific CPU
test_cpu_affinity() {
    local cpu_num=$1
    local duration=$2
    
    echo "Testing CPU affinity for CPU $cpu_num"
    
    # Start monitoring
    mpstat -P $cpu_num 1 $duration > cpu_${cpu_num}_stats.log &
    MPSTAT_PID=$!
    
    # Run CPU-intensive task on specific CPU
    taskset -c $cpu_num stress --cpu 1 --timeout ${duration}s &
    STRESS_PID=$!
    
    # Wait for completion
    wait $STRESS_PID
    wait $MPSTAT_PID
    
    echo "Results for CPU $cpu_num:"
    grep "Average" cpu_${cpu_num}_stats.log
    echo ""
}

# Test each CPU core individually
NUM_CPUS=$(nproc)
echo "System has $NUM_CPUS logical CPUs"
echo ""

for ((i=0; i<NUM_CPUS && i<4; i++)); do
    test_cpu_affinity $i 10
done

echo "=== Load Distribution Summary ==="
for ((i=0; i<NUM_CPUS && i<4; i++)); do
    if [ -f "cpu_${i}_stats.log" ]; then
        echo -n "CPU $i: "
        awk '/Average/ {printf "%.1f%% utilized\n", $4+$6}' cpu_${i}_stats.log
    fi
done
EOF

chmod +x cpu_affinity_test.sh
./cpu_affinity_test.sh
Subtask 4.2: Optimize Process Distribution
# Create process optimization script
cat > optimize_processes.sh << 'EOF'
#!/bin/bash

echo "=== Process Distribution Optimization ==="

# Function to demonstrate load balancing
demonstrate_load_balancing() {
    echo "Scenario 1: All processes on CPU 0 (Poor distribution)"
    
    # Start monitoring
    mpstat -P ALL 2 10 > unbalanced_load.log &
    MPSTAT_PID=$!
    
    # Run multiple processes on CPU 0 only
    for i in {1..4}; do
        taskset -c 0 stress --cpu 1 --timeout 8s &
    done
    
    wait $MPSTAT_PID
    
    echo "Results - Unbalanced Load:"
    grep "Average" unbalanced_load.log | head -5
    echo ""
    
    sleep 5
    
    echo "Scenario 2: Distributed processes (Good distribution)"
    
    # Start monitoring
    mpstat -P ALL 2 10 > balanced_load.log &
    MPSTAT_PID=$!
    
    # Distribute processes across available CPUs
    NUM_CPUS=$(nproc)
    for i in {1..4}; do
        CPU_ID=$(( (i-1) % NUM_CPUS ))
        taskset -c $CPU_ID stress --cpu 1 --timeout 8s &
    done
    
    wait $MPSTAT_PID
    
    echo "Results - Balanced Load:"
    grep "Average" balanced_load.log | head -5
    echo ""
}

demonstrate_load_balancing

# Analyze the difference
echo "=== Load Distribution Analysis ==="
echo "Unbalanced scenario - CPU utilization:"
awk '/Average/ && $3 ~ /^[0-9]+$/ {printf "CPU %s: %.1f%%\n", $3, $4+$6}' unbalanced_load.log

echo ""
echo "Balanced scenario - CPU utilization:"
awk '/Average/ && $3 ~ /^[0-9]+$/ {printf "CPU %s: %.1f%%\n", $3, $4+$6}' balanced_load.log
EOF

chmod +x optimize_processes.sh
./optimize_processes.sh
Subtask 4.3: Create Performance Monitoring Dashboard
# Create real-time monitoring dashboard
cat > cpu_dashboard.sh << 'EOF'
#!/bin/bash

# Function to display CPU dashboard
display_dashboard() {
    while true; do
        clear
        echo "=========================================="
        echo "    Multi-Core CPU Performance Dashboard"
        echo "=========================================="
        echo "Time: $(date)"
        echo ""
        
        # System overview
        echo "=== System Overview ==="
        echo "Hostname: $(hostname)"
        echo "Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        
        # CPU utilization
        echo "=== CPU Utilization (Last 5 seconds) ==="
        mpstat -P ALL 1 5 | grep "Average" | while read line; do
            if echo "$line" | grep -q "CPU"; then
                echo "$line" | awk '{printf "%-8s %6s %6s %6s %6s %6s\n", $3, $4"%", $6"%", $7"%", $11"%", $12"%"}'
            else
                echo "$line" | awk '{printf "%-8s %6.1f %6.1f %6.1f %6.1f %6.1f\n", "CPU"$3, $4, $6, $7, $11, $12}'
            fi
        done
        echo ""
        
        # Top processes
        echo "=== Top CPU Consuming Processes ==="
        ps aux --sort=-%cpu | head -6 | awk 'NR==1 {print $0} NR>1 {printf "%-10s %5s %5s %s\n", $1, $3"%", $4"%", $11}'
        echo ""
        
        echo "Press Ctrl+C to exit..."
        sleep 5
    done
}

# Check if running in interactive mode
if [ -t 0 ]; then
    display_dashboard
else
    echo "This script requires interactive terminal. Run directly: ./cpu_dashboard.sh"
fi
EOF

chmod +x cpu_dashboard.sh

echo "Dashboard created. Run './cpu_dashboard.sh' for real-time monitoring."
Task 5: Advanced Analysis and Reporting
Subtask 5.1: Historical Data Analysis
# Create historical analysis script
cat > historical_analysis.sh << 'EOF'
#!/bin/bash

echo "=== Historical CPU Performance Analysis ==="

# Check if sar data is available
if [ -d "/var/log/sysstat" ] || [ -d "/var/log/sa" ]; then
    echo "System Activity Reporter (SAR) data found."
    
    # Find the most recent sar data file
    SAR_DIR="/var/log/sysstat"
    [ ! -d "$SAR_DIR" ] && SAR_DIR="/var/log/sa"
    
    LATEST_FILE=$(ls -t $SAR_DIR/sa[0-9]* 2>/dev/null | head -1)
    
    if [ -n "$LATEST_FILE" ]; then
        echo "Analyzing data from: $LATEST_FILE"
        echo ""
        
        echo "=== CPU Utilization Summary (Last 24 hours) ==="
        sar -u -f "$LATEST_FILE" | tail -20
        echo ""
        
        echo "=== Per-CPU Statistics ==="
        sar -P ALL -f "$LATEST_FILE" | tail -20
        echo ""
    else
        echo "No SAR data files found. Generating sample data..."
        generate_sample_data
    fi
else
    echo "SAR not configured. Generating sample data..."
    generate_sample_data
fi

generate_sample_data() {
    echo "Collecting 5 minutes of sample data..."
    mpstat -P ALL 10 30 > sample_historical.log
    
    echo "=== Sample Data Analysis ==="
    echo "Average utilization over sampling period:"
    grep "Average" sample_historical.log
}
EOF

chmod +x historical_analysis.sh
./historical_analysis.sh
Subtask 5.2: Performance Report Generation
# Create comprehensive performance report
cat > generate_report.sh << 'EOF'
#!/bin/bash

REPORT_FILE="cpu_performance_report_$(date +%Y%m%d_%H%M%S).txt"

echo "=== Generating CPU Performance Report ==="
echo "Report will be saved as: $REPORT_FILE"

{
    echo "=========================================="
    echo "    CPU PERFORMANCE ANALYSIS REPORT"
    echo "=========================================="
    echo "Generated: $(date)"
    echo "System: $(hostname)"
    echo "Analyst: $(whoami)"
    echo ""
    
    echo "=== SYSTEM CONFIGURATION ==="
    echo "CPU Architecture:"
    lscpu | grep -E "(Architecture|Model name|CPU\(s\)|Thread|Core|Socket|Cache)"
    echo ""
    
    echo "Memory Information:"
    free -h
    echo ""
    
    echo "=== CURRENT PERFORMANCE METRICS ==="
    echo "System Load:"
    uptime
    echo ""
    
    echo "CPU Utilization (10-second average):"
    mpstat -P ALL 1 10 | grep "Average"
    echo ""
    
    echo "=== PERFORMANCE TEST RESULTS ==="
    echo "Running CPU stress test for analysis..."
    
    # Run stress test and capture results
    mpstat -P ALL 2 20 > temp_stress_results.log &
    MPSTAT_PID=$!
    
    stress --cpu $(nproc) --timeout 15s >/dev/null 2>&1 &
    STRESS_PID=$!
    
    wait $STRESS_PID
    wait $MPSTAT_PID
    
    echo "Stress Test Results:"
    grep "Average" temp_stress_results.log
    echo ""
    
    echo "=== ANALYSIS AND RECOMMENDATIONS ==="
    
    # Analyze results and provide recommendations
    MAX_UTIL=$(grep "Average" temp_stress_results.log | awk '$3 ~ /^[0-9]+$/ {total=$4+$6; if(total>max) max=total} END {print max}')
    MIN_UTIL=$(grep "Average" temp_stress_results.log | awk '$3 ~ /^[0-9]+$/ {total=$4+$6; if(NR==1 || total<min) min=total} END {print min}')
    
    echo "Performance Analysis:"
    echo "- Maximum CPU utilization during test: ${MAX_UTIL}%"
    echo "- Minimum CPU utilization during test: ${MIN_UTIL}%"
    
    if (( $(echo "$MAX_UTIL > 90" | bc -l) )); then
        echo "- Status: HIGH CPU utilization detected"
        echo "- Recommendation: Monitor for sustained high usage"
    elif (( $(echo "$MAX_UTIL < 50" | bc -l) )); then
        echo "- Status: LOW CPU utilization"
        echo "- Recommendation: System has available CPU capacity"
    else
        echo "- Status: MODERATE CPU utilization"
        echo "- Recommendation: Normal operating range"
    fi
    
    echo ""
    echo "Load Balancing Analysis:"
    CORE_COUNT=$(grep "Average" temp_stress_results.log | awk '$3 ~ /^[0-9]+$/' | wc -l)
    echo "- Number of CPU cores analyzed: $CORE_COUNT"
    
    # Check for load imbalance
    grep "Average" temp_stress_results.log | awk '
    $3 ~ /^[0-9]+$/ {
        total = $4 + $6
        sum += total
        count++
        util[count] = total
    }
    END {
        avg = sum / count
        variance = 0
        for (i = 1; i <= count; i++) {
            variance += (util[i] - avg) ^ 2
        }
        variance = variance / count
        stddev = sqrt(variance)
        
        printf "- Average utilization across cores: %.1f%%\n", avg
        printf "- Standard deviation: %.1f%%\n", stddev
        
        if (stddev > 15) {
            print "- Load Balance: POOR - Significant variation between cores"
            print "- Recommendation: Consider CPU affinity optimization"
        } else if (stddev > 5) {
            print "- Load Balance: MODERATE - Some variation between cores"
            print "- Recommendation: Monitor load distribution"
        } else {
            print "- Load Balance: GOOD - Even distribution across cores"
            print "- Recommendation: Current load balancing is effective"
        }
    }'
    
    echo ""
    echo "=== MONITORING RECOMMENDATIONS ==="
    echo "1. Regular Monitoring:"
    echo "   - Use 'mpstat -P ALL 5' for real-time monitoring"
    echo "   - Set up automated alerts for >80% sustained CPU usage"
    echo ""
    echo "2. Performance Optimization:"
    echo "   - Consider process CPU affinity for critical applications"
    echo "   - Monitor I/O wait times if >20% consistently"
    echo "   - Review process scheduling priorities"
    echo ""
    echo "3. Capacity Planning:"
    echo "   - Current peak utilization: ${MAX_UTIL}%"
    echo "   - Recommended threshold for scaling: 70%"
    echo "   - Consider additional cores if consistently above threshold"
    echo ""
    
    echo "=== APPENDIX: COMMAND REFERENCE ==="
    echo "Useful mpstat commands:"
    echo "- mpstat -P ALL          # Show all CPU statistics"
    echo "- mpstat -P ALL 5        # Monitor every 5 seconds"
    echo "- mpstat -P 0,1 2 10     # Monitor CPUs 0,1 for 20 seconds"
    echo "- mpstat -I SUM          # Show interrupt statistics"
    echo ""
    
    echo "Report generation completed: $(date)"
    
    # Cleanup temporary files
    rm -f temp_stress_results.log
    
} > "$REPORT_FILE"

echo "Report generated successfully: $REPORT_FILE"
echo ""
echo "Report summary:"
head -30 "$REPORT_FILE"
echo "..."
echo "(Full report saved to $REPORT_FILE)"
EOF

chmod +x generate_report.sh
./generate_report.sh
Subtask 5.3: Automated Monitoring Setup
# Create automated monitoring setup
cat > setup_monitoring.sh << 'EOF'
#!/bin/bash

echo "=== Setting up Automated CPU Monitoring ==="

# Create monitoring directory
MONITOR_DIR="$HOME/cpu_monitoring"
mkdir -p "$MONITOR_DIR"
cd "$MONITOR_DIR"

# Create continuous monitoring script
cat > continuous_monitor.sh << 'MONITOR_EOF'
#!/bin/bash

LOG_DIR="$HOME/cpu_monitoring/logs"
mkdir -p "$LOG_DIR"

DATE_STR=$(date +%Y%m%d)
LOG_FILE="$LOG_DIR/cpu_monitor_$DATE_STR.log"

# Function to log with timestamp
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check CPU thresholds
check_cpu_thresholds() {
    # Get current CPU utilization
    CPU_UTIL=$(mpstat 1 3 | grep "Average" | grep -v "CPU" | awk '{print $4+$6}')
    
    for util in $CPU_UTIL; do
        if (( $(echo "$util > 80" | bc -l) )); then
            log_with_timestamp "HIGH CPU ALERT: CPU utilization at ${util}%"
            
            # Log top processes
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Top CPU processes:" >> "$LOG_FILE"
            ps aux --sort=-%cpu | head -5 >> "$LOG_FILE"
        fi
    done
}

# Main monitoring loop
log_with_timestamp "CPU monitoring started"

while true; do
    # Log current CPU stats
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] CPU Statistics:" >> "$LOG_FILE"
    mpstat -P ALL 1 1 | grep -E "(Average|CPU)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    # Check thresholds
    check_cpu_thresholds
    
    # Sleep for 5 minutes
    sleep 300
done
MONITOR_EOF

chmod +x continuous_monitor.sh

# Create log rotation script
cat > rotate_logs.sh << 'ROTATE_EOF'
#!/bin/bash

LOG_DIR="$HOME/cpu_monitoring/logs"
ARCHIVE_DIR="$HOME/cpu_monitoring/archive"

mkdir -p "$ARCHIVE_DIR"

# Compress logs older than 7 days
find "$LOG_DIR" -name "cpu_monitor_*.log" -mtime +7 -exec gzip {} \;

# Move compressed logs to archive
find "$LOG_DIR" -name "cpu_monitor_*.log.gz" -exec mv {} "$ARCHIVE_DIR/" \;

# Remove archives older than 30 days
find "$ARCHIVE_DIR" -name "cpu_monitor_*.log.gz" -mtime +30 -delete

echo "Log rotation completed: $(date)"
ROTATE_EOF

chmod +x rotate_logs.sh

# Create systemd service file (optional)
cat > cpu-monitor.service << 'SERVICE_EOF'
[Unit]
Description=CPU Performance Monitor
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/cpu_monitoring
ExecStart=$HOME/cpu_monitoring/continuous_monitor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

echo "Monitoring setup completed!"
echo ""
echo "Files created in $MONITOR_DIR:"
ls -la "$MONITOR_DIR"
echo ""
echo "To start monitoring:"
echo "1. Manual: ./continuous_monitor.sh &"
echo "2. Background: nohup ./continuous_monitor.sh > /dev/null 2>&1 &"
echo ""
echo "To set up log rotation (run weekly):"
echo "   ./rotate_logs.sh"
echo ""
echo "Logs will be stored in: $MONITOR_DIR/logs/"
EOF

chmod +x setup_monitoring.sh
./setup_monitoring.sh
Troubleshooting Common Issues
Issue 1: mpstat Command Not Found
Problem: mpstat: command not found

Solution:

# Install sysstat package
sudo yum install -y sysstat    # RHEL/CentOS
# or
sudo apt install -y sysstat    # Ubuntu/Debian
Issue 2: No Data in Historical Analysis
Problem: SAR data not available

Solution:

# Enable sysstat data collection
sudo systemctl enable sysstat
sudo systemctl start sysstat

# Edit sysstat configuration
sudo vi /etc/default/sysstat
# Change ENABLED="false" to ENABLED="true"
Issue 3: Permission Denied Errors
Problem: Cannot access system statistics

Solution:

# Run with appropriate permissions
sudo mpstat -P ALL

# Or add user to appropriate group
sudo usermod -a -G adm $USER
Issue 4: High CPU Usage During Monitoring
Problem: Monitoring itself consuming too much CPU

Solution:

# Increase monitoring intervals
mpstat -P ALL 10 6    # Every 10 seconds instead of 1

# Use nice to lower priority
nice -n 10 mpstat -P ALL 5
Conclusion
In this comprehensive lab, you have successfully learned to use mpstat for multi-core system analysis and performance optimization. Here's what you accomplished:

Key Skills Developed:

System Analysis: You learned to examine multi-core CPU architecture and understand the relationship between physical cores, logical processors, and hyperthreading
Performance Monitoring: You mastered mpstat commands to monitor CPU utilization across individual cores and identify performance patterns
Load Distribution Analysis: You analyzed how workloads distribute across multiple CPU cores and identified load balancing issues
Resource Optimization: You implemented CPU affinity techniques and process distribution strategies to optimize system performance
Automated Monitoring: You created comprehensive monitoring solutions with alerting and historical analysis capabilities
Practical Applications:

System Administration: These skills are essential for managing production servers and identifying performance bottlenecks
Performance Tuning: You can now optimize applications and system configurations based on CPU utilization patterns
Capacity Planning: You learned to analyze current usage patterns to make informed decisions about hardware scaling
Troubleshooting: You developed systematic approaches to diagnose CPU-related performance issues
Real-World Impact: Understanding multi-core CPU performance is crucial in modern computing environments where applications must efficiently utilize available processing power. The techniques you learned help ensure optimal system performance, reduce response times, and maximize resource utilization in enterprise environments.

Next Steps:

Practice these techniques on different workload types (web servers, databases, computational tasks)
Integrate mpstat monitoring with other system monitoring tools
Explore advanced performance tuning techniques like NUMA optimization
Consider pursuing Red Hat Certified Specialist in Performance Tuning certification
The skills you've developed in this lab form a foundation for advanced system performance analysis and are directly applicable to real-world system administration and performance engineering roles.
