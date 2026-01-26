Lab 9: Power Consumption Monitoring with powertop
Objectives
By the end of this lab, students will be able to:

Install and configure powertop for comprehensive power consumption monitoring
Analyze system power usage patterns and identify power-hungry processes
Implement power optimization strategies to extend battery life
Configure automatic power management settings for optimal performance-to-power ratio
Generate detailed power consumption reports for system analysis
Apply advanced power tuning techniques for laptops and portable devices
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with system administration concepts
Knowledge of process management and system monitoring
Understanding of hardware components (CPU, disk, network interfaces)
Basic knowledge of systemd services and configuration files
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
Pre-installed development tools and utilities
Network connectivity for package installation
Simulated laptop environment for power testing
Task 1: Installing and Configuring powertop
Subtask 1.1: Install powertop Package
First, we'll install powertop and verify the installation.

# Update system packages
sudo dnf update -y

# Install powertop and required dependencies
sudo dnf install -y powertop kernel-tools

# Verify installation
powertop --version
Subtask 1.2: Initial System Preparation
Before running powertop, we need to ensure proper permissions and system state.

# Check if running on battery (for laptops)
cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo "AC Power detected"

# Ensure powertop can access hardware counters
sudo modprobe msr

# Check available power management features
ls /sys/class/power_supply/
Subtask 1.3: First powertop Execution
Run powertop for initial system analysis and calibration.

# Run powertop with calibration (takes 10-15 minutes)
sudo powertop --calibrate

# Run powertop in interactive mode
sudo powertop
Navigation in powertop interface:

Tab key: Switch between different tabs
Up/Down arrows: Navigate through lists
Enter: Toggle power-saving features
q: Quit the application
Task 2: Analyzing Power Consumption Patterns
Subtask 2.1: Understanding powertop Interface
Let's explore each tab in the powertop interface:

# Start powertop in interactive mode
sudo powertop
Tab Overview:

Overview Tab: Shows overall power consumption and top power consumers
Idle Stats Tab: Displays CPU idle state statistics
Frequency Stats Tab: Shows CPU frequency usage patterns
Device Stats Tab: Lists device-specific power consumption
Tunables Tab: Shows available power optimization settings
Subtask 2.2: Generate Detailed Power Report
Create comprehensive power consumption reports for analysis.

# Generate HTML report (run for 60 seconds)
sudo powertop --html=power_report.html --time=60

# Generate CSV report for data analysis
sudo powertop --csv=power_data.csv --time=30

# View the generated reports
ls -la power_report.html power_data.csv
Subtask 2.3: Analyze Top Power Consumers
Create a script to identify and log top power consumers:

# Create power analysis script
cat > analyze_power.sh << 'EOF'
#!/bin/bash

echo "=== Power Consumption Analysis ==="
echo "Date: $(date)"
echo

# Check battery status
if [ -f /sys/class/power_supply/BAT0/capacity ]; then
    echo "Battery Level: $(cat /sys/class/power_supply/BAT0/capacity)%"
    echo "Battery Status: $(cat /sys/class/power_supply/BAT0/status)"
else
    echo "System running on AC power"
fi

echo
echo "=== Top CPU Consuming Processes ==="
ps aux --sort=-%cpu | head -10

echo
echo "=== Current CPU Frequency ==="
cat /proc/cpuinfo | grep "cpu MHz" | head -4

echo
echo "=== Active Network Interfaces ==="
ip link show | grep "state UP"

echo
echo "=== Disk Activity ==="
iostat -x 1 1 | tail -n +4
EOF

chmod +x analyze_power.sh
./analyze_power.sh
Task 3: Implementing Power Optimization Strategies
Subtask 3.1: Apply Automatic Optimizations
Use powertop's built-in optimization suggestions:

# Generate optimization script
sudo powertop --auto-tune

# Create custom tuning script
cat > power_optimize.sh << 'EOF'
#!/bin/bash

echo "Applying power optimizations..."

# CPU Governor settings
echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Enable laptop mode
echo 5 | sudo tee /proc/sys/vm/laptop_mode

# Optimize disk settings
for disk in /sys/block/sd*; do
    if [ -f "$disk/queue/scheduler" ]; then
        echo "deadline" | sudo tee "$disk/queue/scheduler"
    fi
done

# Network interface power management
for interface in /sys/class/net/*/device/power/control; do
    if [ -f "$interface" ]; then
        echo "auto" | sudo tee "$interface"
    fi
done

# USB autosuspend
echo 'auto' | sudo tee /sys/bus/usb/devices/*/power/control 2>/dev/null

echo "Power optimizations applied successfully!"
EOF

chmod +x power_optimize.sh
sudo ./power_optimize.sh
Subtask 3.2: Configure Persistent Power Settings
Create systemd service for automatic power optimization:

# Create systemd service file
sudo tee /etc/systemd/system/power-optimize.service << 'EOF'
[Unit]
Description=Power Optimization Service
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/power-optimize.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Copy optimization script to system location
sudo cp power_optimize.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/power-optimize.sh

# Enable and start the service
sudo systemctl enable power-optimize.service
sudo systemctl start power-optimize.service
sudo systemctl status power-optimize.service
Subtask 3.3: Advanced CPU Power Management
Configure advanced CPU power management features:

# Create CPU power management script
cat > cpu_power_mgmt.sh << 'EOF'
#!/bin/bash

echo "=== CPU Power Management Configuration ==="

# Check available CPU governors
echo "Available CPU governors:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors

# Set powersave governor for all CPUs
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "powersave" | sudo tee "$cpu"
done

# Configure CPU frequency scaling
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
    if [ -f "$cpu" ]; then
        # Reduce maximum frequency to 80% for power saving
        max_freq=$(cat "${cpu%/*}/cpuinfo_max_freq")
        new_max=$((max_freq * 80 / 100))
        echo "$new_max" | sudo tee "$cpu"
    fi
done

# Enable Intel P-State driver optimizations (if available)
if [ -f /sys/devices/system/cpu/intel_pstate/max_perf_pct ]; then
    echo 80 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct
    echo 20 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct
fi

echo "CPU power management configured successfully!"
EOF

chmod +x cpu_power_mgmt.sh
sudo ./cpu_power_mgmt.sh
Task 4: Monitoring and Measuring Power Improvements
Subtask 4.1: Create Power Monitoring Dashboard
Develop a comprehensive monitoring script:

# Create power monitoring dashboard
cat > power_dashboard.sh << 'EOF'
#!/bin/bash

# Function to get battery info
get_battery_info() {
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        capacity=$(cat /sys/class/power_supply/BAT0/capacity)
        status=$(cat /sys/class/power_supply/BAT0/status)
        echo "Battery: ${capacity}% (${status})"
    else
        echo "Battery: Not available (AC Power)"
    fi
}

# Function to get CPU frequency
get_cpu_freq() {
    freq=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}')
    echo "CPU Frequency: ${freq} MHz"
}

# Function to get power consumption estimate
get_power_estimate() {
    if command -v powertop >/dev/null 2>&1; then
        # Run powertop for 10 seconds and extract power estimate
        power=$(timeout 10 sudo powertop --csv=/tmp/power_temp.csv --time=5 2>/dev/null && \
                grep "The battery reports" /tmp/power_temp.csv 2>/dev/null | \
                tail -1 | cut -d',' -f2 | tr -d ' ')
        rm -f /tmp/power_temp.csv
        echo "Power Consumption: ${power:-"Calculating..."}"
    else
        echo "Power Consumption: powertop not available"
    fi
}

# Main dashboard loop
while true; do
    clear
    echo "======================================"
    echo "    POWER CONSUMPTION DASHBOARD"
    echo "======================================"
    echo "Time: $(date)"
    echo
    get_battery_info
    get_cpu_freq
    get_power_estimate
    echo
    echo "Top 5 CPU consumers:"
    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-20s %s%%\n", $11, $3}'
    echo
    echo "Press Ctrl+C to exit"
    echo "======================================"
    
    sleep 5
done
EOF

chmod +x power_dashboard.sh
Subtask 4.2: Benchmark Power Consumption
Create before/after power consumption comparison:

# Create power benchmarking script
cat > power_benchmark.sh << 'EOF'
#!/bin/bash

BENCHMARK_DIR="/tmp/power_benchmark"
mkdir -p "$BENCHMARK_DIR"

echo "=== Power Consumption Benchmark ==="

# Function to run power test
run_power_test() {
    local test_name="$1"
    local duration="$2"
    
    echo "Running $test_name test for $duration seconds..."
    
    # Start background monitoring
    (
        while true; do
            echo "$(date +%s),$(cat /proc/loadavg | cut -d' ' -f1)" >> "$BENCHMARK_DIR/${test_name}_load.csv"
            sleep 1
        done
    ) &
    monitor_pid=$!
    
    # Run powertop measurement
    sudo powertop --csv="$BENCHMARK_DIR/${test_name}_power.csv" --time="$duration" >/dev/null 2>&1
    
    # Stop monitoring
    kill $monitor_pid 2>/dev/null
    
    echo "$test_name test completed"
}

# Baseline test (system idle)
echo "Starting baseline measurement..."
run_power_test "baseline" 30

# Stress test
echo "Starting stress test..."
# Install stress tool if not available
if ! command -v stress >/dev/null 2>&1; then
    sudo dnf install -y stress
fi

stress --cpu 2 --timeout 30s &
run_power_test "stress" 30
wait

# Generate comparison report
echo
echo "=== Benchmark Results ==="
echo "Baseline power data saved to: $BENCHMARK_DIR/baseline_power.csv"
echo "Stress test power data saved to: $BENCHMARK_DIR/stress_power.csv"

# Simple analysis
if [ -f "$BENCHMARK_DIR/baseline_power.csv" ] && [ -f "$BENCHMARK_DIR/stress_power.csv" ]; then
    echo
    echo "Analysis complete. Check CSV files for detailed power consumption data."
fi
EOF

chmod +x power_benchmark.sh
./power_benchmark.sh
Subtask 4.3: Create Power Optimization Report
Generate a comprehensive optimization report:

# Create optimization report generator
cat > generate_power_report.sh << 'EOF'
#!/bin/bash

REPORT_FILE="power_optimization_report.txt"

echo "=== POWER OPTIMIZATION REPORT ===" > "$REPORT_FILE"
echo "Generated on: $(date)" >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

# System Information
echo "=== SYSTEM INFORMATION ===" >> "$REPORT_FILE"
echo "Hostname: $(hostname)" >> "$REPORT_FILE"
echo "Kernel: $(uname -r)" >> "$REPORT_FILE"
echo "CPU: $(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d':' -f2 | xargs)" >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

# Power Supply Information
echo "=== POWER SUPPLY STATUS ===" >> "$REPORT_FILE"
for supply in /sys/class/power_supply/*; do
    if [ -d "$supply" ]; then
        name=$(basename "$supply")
        if [ -f "$supply/type" ]; then
            type=$(cat "$supply/type")
            echo "$name ($type):" >> "$REPORT_FILE"
            
            [ -f "$supply/status" ] && echo "  Status: $(cat $supply/status)" >> "$REPORT_FILE"
            [ -f "$supply/capacity" ] && echo "  Capacity: $(cat $supply/capacity)%" >> "$REPORT_FILE"
            [ -f "$supply/voltage_now" ] && echo "  Voltage: $(cat $supply/voltage_now) µV" >> "$REPORT_FILE"
        fi
    fi
done
echo >> "$REPORT_FILE"

# CPU Governor Settings
echo "=== CPU GOVERNOR SETTINGS ===" >> "$REPORT_FILE"
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ -f "$cpu" ]; then
        cpu_num=$(echo "$cpu" | grep -o 'cpu[0-9]*' | head -1)
        governor=$(cat "$cpu")
        echo "$cpu_num: $governor" >> "$REPORT_FILE"
    fi
done
echo >> "$REPORT_FILE"

# Power Management Features
echo "=== POWER MANAGEMENT FEATURES ===" >> "$REPORT_FILE"
echo "Laptop Mode: $(cat /proc/sys/vm/laptop_mode 2>/dev/null || echo 'Not available')" >> "$REPORT_FILE"

# USB Power Management
echo "USB Autosuspend Status:" >> "$REPORT_FILE"
for usb in /sys/bus/usb/devices/*/power/control; do
    if [ -f "$usb" ]; then
        device=$(dirname "$usb" | xargs basename)
        control=$(cat "$usb")
        echo "  $device: $control" >> "$REPORT_FILE"
    fi
done 2>/dev/null
echo >> "$REPORT_FILE"

# Network Interface Power Management
echo "=== NETWORK POWER MANAGEMENT ===" >> "$REPORT_FILE"
for iface in /sys/class/net/*/device/power/control; do
    if [ -f "$iface" ]; then
        interface=$(echo "$iface" | cut -d'/' -f5)
        control=$(cat "$iface")
        echo "$interface: $control" >> "$REPORT_FILE"
    fi
done 2>/dev/null
echo >> "$REPORT_FILE"

# Recommendations
echo "=== OPTIMIZATION RECOMMENDATIONS ===" >> "$REPORT_FILE"
echo "1. Ensure powersave governor is active during battery operation" >> "$REPORT_FILE"
echo "2. Enable laptop mode for better disk power management" >> "$REPORT_FILE"
echo "3. Configure USB autosuspend for unused devices" >> "$REPORT_FILE"
echo "4. Use powertop regularly to monitor power consumption" >> "$REPORT_FILE"
echo "5. Consider disabling unused hardware components" >> "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"
cat "$REPORT_FILE"
EOF

chmod +x generate_power_report.sh
./generate_power_report.sh
Task 5: Advanced Power Tuning Techniques
Subtask 5.1: Configure TLP for Advanced Power Management
Install and configure TLP (Advanced Power Management):

# Install TLP
sudo dnf install -y tlp tlp-rdw

# Enable TLP service
sudo systemctl enable tlp.service
sudo systemctl start tlp.service

# Configure TLP settings
sudo tee /etc/tlp.conf << 'EOF'
# TLP Configuration for Power Optimization

# CPU scaling governor
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# CPU energy performance policy
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# CPU frequency scaling
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=50

# Disk devices
DISK_DEVICES="sda sdb"
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"

# WiFi power saving
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# USB autosuspend
USB_AUTOSUSPEND=1
EOF

# Apply TLP settings
sudo tlp start

# Check TLP status
sudo tlp-stat -s
Subtask 5.2: Create Custom Power Profiles
Develop custom power profiles for different usage scenarios:

# Create power profile manager
cat > power_profiles.sh << 'EOF'
#!/bin/bash

PROFILE_DIR="/etc/power-profiles"
sudo mkdir -p "$PROFILE_DIR"

# Performance Profile
sudo tee "$PROFILE_DIR/performance.conf" << 'PERF_EOF'
# Performance Power Profile
CPU_GOVERNOR=performance
CPU_MAX_FREQ=100
LAPTOP_MODE=0
USB_AUTOSUSPEND=0
WIFI_POWER_SAVE=off
PERF_EOF

# Balanced Profile
sudo tee "$PROFILE_DIR/balanced.conf" << 'BAL_EOF'
# Balanced Power Profile
CPU_GOVERNOR=ondemand
CPU_MAX_FREQ=80
LAPTOP_MODE=1
USB_AUTOSUSPEND=1
WIFI_POWER_SAVE=on
BAL_EOF

# Power Save Profile
sudo tee "$PROFILE_DIR/powersave.conf" << 'SAVE_EOF'
# Power Save Profile
CPU_GOVERNOR=powersave
CPU_MAX_FREQ=50
LAPTOP_MODE=5
USB_AUTOSUSPEND=1
WIFI_POWER_SAVE=on
SAVE_EOF

# Profile switcher function
switch_profile() {
    local profile="$1"
    local config_file="$PROFILE_DIR/${profile}.conf"
    
    if [ ! -f "$config_file" ]; then
        echo "Profile $profile not found!"
        return 1
    fi
    
    echo "Switching to $profile profile..."
    source "$config_file"
    
    # Apply CPU governor
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$CPU_GOVERNOR" | sudo tee "$cpu" >/dev/null 2>&1
    done
    
    # Apply CPU frequency limit
    if [ -f /sys/devices/system/cpu/intel_pstate/max_perf_pct ]; then
        echo "$CPU_MAX_FREQ" | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null
    fi
    
    # Apply laptop mode
    echo "$LAPTOP_MODE" | sudo tee /proc/sys/vm/laptop_mode >/dev/null
    
    # Apply USB autosuspend
    if [ "$USB_AUTOSUSPEND" = "1" ]; then
        echo 'auto' | sudo tee /sys/bus/usb/devices/*/power/control >/dev/null 2>&1
    else
        echo 'on' | sudo tee /sys/bus/usb/devices/*/power/control >/dev/null 2>&1
    fi
    
    echo "Profile $profile applied successfully!"
}

# Command line interface
case "$1" in
    performance|balanced|powersave)
        switch_profile "$1"
        ;;
    list)
        echo "Available profiles:"
        ls "$PROFILE_DIR"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/.conf$//'
        ;;
    *)
        echo "Usage: $0 {performance|balanced|powersave|list}"
        echo "Current profile settings:"
        echo "CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
        echo "Laptop Mode: $(cat /proc/sys/vm/laptop_mode 2>/dev/null)"
        ;;
esac
EOF

chmod +x power_profiles.sh
sudo cp power_profiles.sh /usr/local/bin/

# Test profile switching
echo "Testing power profiles..."
sudo /usr/local/bin/power_profiles.sh list
sudo /usr/local/bin/power_profiles.sh balanced
Subtask 5.3: Implement Automated Power Management
Create an automated power management system based on battery level:

# Create automated power management script
cat > auto_power_mgmt.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/auto-power-mgmt.log"

log_message() {
    echo "$(date): $1" | sudo tee -a "$LOG_FILE"
}

get_battery_level() {
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        cat /sys/class/power_supply/BAT0/capacity
    else
        echo "100"  # Assume full if no battery
    fi
}

get_power_status() {
    if [ -f /sys/class/power_supply/ADP1/online ]; then
        cat /sys/class/power_supply/ADP1/online
    elif [ -f /sys/class/power_supply/AC/online ]; then
        cat /sys/class/power_supply/AC/online
    else
        echo "1"  # Assume AC power if unknown
    fi
}

apply_power_policy() {
    local battery_level="$1"
    local on_ac="$2"
    
    if [ "$on_ac" = "1" ]; then
        # On AC power - use performance profile
        log_message "On AC power - applying performance profile"
        /usr/local/bin/power_profiles.sh performance
    elif [ "$battery_level" -gt 50 ]; then
        # High battery - use balanced profile
        log_message "Battery level $battery_level% - applying balanced profile"
        /usr/local/bin/power_profiles.sh balanced
    elif [ "$battery_level" -gt 20 ]; then
        # Medium battery - use power save profile
        log_message "Battery level $battery_level% - applying power save profile"
        /usr/local/bin/power_profiles.sh powersave
    else
        # Low battery - aggressive power saving
        log_message "Low battery $battery_level% - applying aggressive power saving"
        /usr/local/bin/power_profiles.sh powersave
        
        # Additional aggressive measures
        echo 1 | sudo tee /sys/devices/system/cpu/cpu*/online >/dev/null 2>&1
        echo 30 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null 2>&1
    fi
}

# Main monitoring loop
while true; do
    battery_level=$(get_battery_level)
    on_ac=$(get_power_status)
    
    apply_power_policy "$battery_level" "$on_ac"
    
    # Check every 60 seconds
    sleep 60
done
EOF

chmod +x auto_power_mgmt.sh

# Create systemd service for automated power management
sudo tee /etc/systemd/system/auto-power-mgmt.service << 'EOF'
[Unit]
Description=Automated Power Management Service
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/auto_power_mgmt.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo cp auto_power_mgmt.sh /usr/local/bin/
sudo systemctl daemon-reload
sudo systemctl enable auto-power-mgmt.service
Troubleshooting Common Issues
Issue 1: powertop Requires Root Privileges
Problem: powertop shows permission errors when run as regular user.

Solution:

# Always run powertop with sudo
sudo powertop

# Or add user to appropriate groups
sudo usermod -a -G adm,dialout,plugdev $USER
Issue 2: Calibration Takes Too Long
Problem: powertop calibration process is taking excessive time.

Solution:

# Skip calibration and use existing data
sudo powertop --auto-tune

# Or run shorter calibration
sudo timeout 300 powertop --calibrate
Issue 3: Power Optimizations Not Persisting
Problem: Power settings reset after reboot.

Solution:

# Create persistent configuration
sudo tee /etc/systemd/system/power-settings.service << 'EOF'
[Unit]
Description=Apply Power Settings
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/power-optimize.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable power-settings.service
Conclusion
In this comprehensive lab, you have successfully:

Installed and configured powertop for detailed power consumption monitoring and analysis
Analyzed system power usage patterns using powertop's interactive interface and reporting capabilities
Implemented automated power optimization strategies including CPU governor settings, disk power management, and USB autosuspend
Created custom power profiles for different usage scenarios (performance, balanced, power save)
Developed automated power management systems that respond to battery level and AC power status
Generated comprehensive power consumption reports for ongoing system optimization
Why This Matters: Power consumption optimization is crucial for:

Extended battery life on laptops and portable devices
Reduced energy costs in data centers and enterprise environments
Environmental sustainability through lower power consumption
Improved system performance through intelligent power management
Professional certification preparation for Red Hat Performance Tuning specialization
The skills you've developed in this lab are directly applicable to real-world scenarios where power efficiency is critical, from managing laptop fleets in corporate environments to optimizing server power consumption in data centers. These techniques are essential for system administrators working with mobile devices, edge computing, and energy-conscious computing environments.

Next Steps: Continue practicing with different hardware configurations, explore integration with monitoring systems like Nagios or Zabbix, and consider implementing organization-wide power management policies using the automation techniques learned in this lab.
