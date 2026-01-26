Lab 15: Modifying Kernel Parameters with sysctl
Objectives
By the end of this lab, students will be able to:

Understand the purpose and functionality of the sysctl command
View and modify kernel parameters dynamically without rebooting
Configure virtual memory parameters to optimize system performance
Adjust network parameters for improved network performance
Make persistent kernel parameter changes across system reboots
Monitor and analyze the impact of kernel parameter modifications on system performance
Implement best practices for kernel parameter tuning in production environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and terminal operations
Knowledge of file system navigation and text editing
Understanding of basic networking concepts
Root or sudo access to a Linux system
Basic knowledge of system monitoring tools
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machine or install additional software.

Your cloud machine includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Root access via sudo
All necessary system monitoring tools pre-installed
Network connectivity for testing
Task 1: Understanding and Exploring sysctl
Subtask 1.1: Introduction to sysctl
The sysctl command is a powerful tool that allows administrators to view and modify kernel parameters at runtime without requiring a system reboot. These parameters control various aspects of system behavior including memory management, network stack, file system operations, and security settings.

First, let's explore the basic sysctl functionality:

# Display all available kernel parameters
sudo sysctl -a | head -20

# Count total number of kernel parameters
sudo sysctl -a | wc -l

# Display sysctl version and help
sysctl --help
Subtask 1.2: Viewing Current Kernel Parameters
Let's examine some important kernel parameters:

# View all virtual memory related parameters
sudo sysctl -a | grep vm

# View network related parameters
sudo sysctl -a | grep net

# View specific parameters
sudo sysctl vm.swappiness
sudo sysctl net.ipv4.ip_forward
sudo sysctl kernel.hostname
Subtask 1.3: Understanding Parameter Categories
Create a script to categorize and display key parameters:

# Create a parameter exploration script
cat > ~/explore_sysctl.sh << 'EOF'
#!/bin/bash

echo "=== SYSTEM INFORMATION ==="
echo "Hostname: $(sysctl -n kernel.hostname)"
echo "Kernel Version: $(sysctl -n kernel.version)"
echo "OS Type: $(sysctl -n kernel.ostype)"
echo

echo "=== MEMORY PARAMETERS ==="
echo "Swappiness: $(sysctl -n vm.swappiness)"
echo "Dirty Ratio: $(sysctl -n vm.dirty_ratio)"
echo "VFS Cache Pressure: $(sysctl -n vm.vfs_cache_pressure)"
echo

echo "=== NETWORK PARAMETERS ==="
echo "IP Forward: $(sysctl -n net.ipv4.ip_forward)"
echo "TCP Keepalive Time: $(sysctl -n net.ipv4.tcp_keepalive_time)"
echo "TCP Window Scaling: $(sysctl -n net.ipv4.tcp_window_scaling)"
echo

echo "=== SECURITY PARAMETERS ==="
echo "ASLR: $(sysctl -n kernel.randomize_va_space)"
echo "Core Pattern: $(sysctl -n kernel.core_pattern)"
EOF

chmod +x ~/explore_sysctl.sh
./explore_sysctl.sh
Task 2: Modifying Virtual Memory Parameters
Subtask 2.1: Understanding Virtual Memory Parameters
Virtual memory parameters control how the kernel manages memory allocation, swapping, and caching. Let's examine and modify key VM parameters:

# Check current memory usage
free -h
cat /proc/meminfo | grep -E "(MemTotal|MemFree|SwapTotal|SwapFree)"

# View current VM parameters
echo "Current VM Parameters:"
sysctl vm.swappiness
sysctl vm.dirty_ratio
sysctl vm.dirty_background_ratio
sysctl vm.vfs_cache_pressure
sysctl vm.overcommit_memory
Subtask 2.2: Modifying Swappiness
Swappiness controls how aggressively the kernel swaps memory pages to disk. Values range from 0-100:

# Check current swappiness
current_swappiness=$(sysctl -n vm.swappiness)
echo "Current swappiness: $current_swappiness"

# Create a memory monitoring script
cat > ~/monitor_memory.sh << 'EOF'
#!/bin/bash

echo "Memory Usage Monitoring"
echo "======================="
echo "Timestamp: $(date)"
echo "Swappiness: $(sysctl -n vm.swappiness)"
echo

free -h
echo

echo "Swap Usage:"
cat /proc/swaps
echo

echo "Memory Statistics:"
cat /proc/meminfo | grep -E "(Active|Inactive|Dirty|Writeback)"
EOF

chmod +x ~/monitor_memory.sh

# Run initial monitoring
./monitor_memory.sh

# Modify swappiness for better performance (lower value = less swapping)
sudo sysctl vm.swappiness=10
echo "New swappiness: $(sysctl -n vm.swappiness)"
Subtask 2.3: Configuring Dirty Memory Parameters
Dirty memory parameters control when dirty pages are written to disk:

# View current dirty memory settings
echo "Current Dirty Memory Parameters:"
sysctl vm.dirty_ratio
sysctl vm.dirty_background_ratio
sysctl vm.dirty_expire_centisecs
sysctl vm.dirty_writeback_centisecs

# Optimize for better I/O performance
sudo sysctl vm.dirty_ratio=15
sudo sysctl vm.dirty_background_ratio=5
sudo sysctl vm.dirty_expire_centisecs=3000
sudo sysctl vm.dirty_writeback_centisecs=500

echo "Updated Dirty Memory Parameters:"
sysctl vm.dirty_ratio
sysctl vm.dirty_background_ratio
sysctl vm.dirty_expire_centisecs
sysctl vm.dirty_writeback_centisecs
Subtask 2.4: Adjusting Cache Pressure
The vfs_cache_pressure parameter controls the tendency of the kernel to reclaim memory used for caching:

# Check current cache pressure
echo "Current VFS cache pressure: $(sysctl -n vm.vfs_cache_pressure)"

# Create a cache monitoring script
cat > ~/monitor_cache.sh << 'EOF'
#!/bin/bash

echo "Cache Usage Monitoring"
echo "====================="
echo "VFS Cache Pressure: $(sysctl -n vm.vfs_cache_pressure)"
echo

echo "Cache Statistics:"
cat /proc/meminfo | grep -E "(Cached|Buffers|SReclaimable|SUnreclaim)"
echo

echo "Slab Information:"
cat /proc/slabinfo | head -5
EOF

chmod +x ~/monitor_cache.sh
./monitor_cache.sh

# Adjust cache pressure for better caching (lower value = keep more cache)
sudo sysctl vm.vfs_cache_pressure=50
echo "New VFS cache pressure: $(sysctl -n vm.vfs_cache_pressure)"
Task 3: Configuring Network Parameters
Subtask 3.1: Understanding Network Parameters
Network parameters control various aspects of the network stack including TCP/IP behavior, buffer sizes, and connection handling:

# Create a network parameter monitoring script
cat > ~/monitor_network.sh << 'EOF'
#!/bin/bash

echo "Network Parameter Monitoring"
echo "============================"
echo "Timestamp: $(date)"
echo

echo "=== IP FORWARDING ==="
echo "IPv4 Forward: $(sysctl -n net.ipv4.ip_forward)"
echo "IPv6 Forward: $(sysctl -n net.ipv6.conf.all.forwarding)"
echo

echo "=== TCP PARAMETERS ==="
echo "TCP Window Scaling: $(sysctl -n net.ipv4.tcp_window_scaling)"
echo "TCP Timestamps: $(sysctl -n net.ipv4.tcp_timestamps)"
echo "TCP SACK: $(sysctl -n net.ipv4.tcp_sack)"
echo "TCP Keepalive Time: $(sysctl -n net.ipv4.tcp_keepalive_time)"
echo "TCP Keepalive Probes: $(sysctl -n net.ipv4.tcp_keepalive_probes)"
echo "TCP Keepalive Interval: $(sysctl -n net.ipv4.tcp_keepalive_intvl)"
echo

echo "=== BUFFER SIZES ==="
echo "TCP Read Buffer Max: $(sysctl -n net.ipv4.tcp_rmem)"
echo "TCP Write Buffer Max: $(sysctl -n net.ipv4.tcp_wmem)"
echo "UDP Read Buffer: $(sysctl -n net.core.rmem_default)"
echo "UDP Write Buffer: $(sysctl -n net.core.wmem_default)"
echo

echo "=== CONNECTION LIMITS ==="
echo "Max Connections: $(sysctl -n net.core.somaxconn)"
echo "SYN Backlog: $(sysctl -n net.ipv4.tcp_max_syn_backlog)"
EOF

chmod +x ~/monitor_network.sh
./monitor_network.sh
Subtask 3.2: Optimizing TCP Parameters
Configure TCP parameters for better network performance:

# Enable TCP window scaling for high-bandwidth networks
sudo sysctl net.ipv4.tcp_window_scaling=1

# Enable TCP timestamps for better RTT calculation
sudo sysctl net.ipv4.tcp_timestamps=1

# Enable SACK (Selective Acknowledgment)
sudo sysctl net.ipv4.tcp_sack=1

# Optimize TCP keepalive settings
sudo sysctl net.ipv4.tcp_keepalive_time=600
sudo sysctl net.ipv4.tcp_keepalive_probes=3
sudo sysctl net.ipv4.tcp_keepalive_intvl=60

# Configure TCP congestion control
echo "Available congestion control algorithms:"
sysctl net.ipv4.tcp_available_congestion_control

# Set BBR congestion control if available
if sysctl net.ipv4.tcp_available_congestion_control | grep -q bbr; then
    sudo sysctl net.ipv4.tcp_congestion_control=bbr
    echo "BBR congestion control enabled"
else
    sudo sysctl net.ipv4.tcp_congestion_control=cubic
    echo "CUBIC congestion control enabled"
fi
Subtask 3.3: Adjusting Buffer Sizes
Optimize network buffer sizes for better throughput:

# Check current buffer sizes
echo "Current Buffer Sizes:"
sysctl net.core.rmem_default
sysctl net.core.rmem_max
sysctl net.core.wmem_default
sysctl net.core.wmem_max

# Increase buffer sizes for high-performance networks
sudo sysctl net.core.rmem_default=262144
sudo sysctl net.core.rmem_max=16777216
sudo sysctl net.core.wmem_default=262144
sudo sysctl net.core.wmem_max=16777216

# Configure TCP buffer sizes
sudo sysctl net.ipv4.tcp_rmem="4096 65536 16777216"
sudo sysctl net.ipv4.tcp_wmem="4096 65536 16777216"

echo "Updated Buffer Sizes:"
sysctl net.core.rmem_default
sysctl net.core.rmem_max
sysctl net.core.wmem_default
sysctl net.core.wmem_max
Subtask 3.4: Configuring Connection Limits
Adjust connection handling parameters:

# Increase connection queue limits
sudo sysctl net.core.somaxconn=65535
sudo sysctl net.ipv4.tcp_max_syn_backlog=8192

# Configure SYN flood protection
sudo sysctl net.ipv4.tcp_syncookies=1
sudo sysctl net.ipv4.tcp_syn_retries=3
sudo sysctl net.ipv4.tcp_synack_retries=3

# Optimize connection recycling
sudo sysctl net.ipv4.tcp_tw_reuse=1
sudo sysctl net.ipv4.tcp_fin_timeout=30

echo "Connection parameters updated:"
sysctl net.core.somaxconn
sysctl net.ipv4.tcp_max_syn_backlog
sysctl net.ipv4.tcp_syncookies
Task 4: Monitoring System Performance Impact
Subtask 4.1: Creating Performance Monitoring Scripts
Create comprehensive monitoring tools to measure the impact of kernel parameter changes:

# Create a comprehensive performance monitoring script
cat > ~/performance_monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/tmp/performance_log_$(date +%Y%m%d_%H%M%S).txt"

echo "Performance Monitoring Started: $(date)" | tee $LOG_FILE
echo "=========================================" | tee -a $LOG_FILE
echo

# System Load
echo "=== SYSTEM LOAD ===" | tee -a $LOG_FILE
uptime | tee -a $LOG_FILE
echo | tee -a $LOG_FILE

# Memory Usage
echo "=== MEMORY USAGE ===" | tee -a $LOG_FILE
free -h | tee -a $LOG_FILE
echo | tee -a $LOG_FILE

# Disk I/O
echo "=== DISK I/O ===" | tee -a $LOG_FILE
iostat -x 1 1 | tee -a $LOG_FILE
echo | tee -a $LOG_FILE

# Network Statistics
echo "=== NETWORK STATISTICS ===" | tee -a $LOG_FILE
ss -tuln | wc -l | awk '{print "Active connections: " $1}' | tee -a $LOG_FILE
cat /proc/net/sockstat | tee -a $LOG_FILE
echo | tee -a $LOG_FILE

# Current sysctl settings
echo "=== CURRENT SYSCTL SETTINGS ===" | tee -a $LOG_FILE
echo "vm.swappiness = $(sysctl -n vm.swappiness)" | tee -a $LOG_FILE
echo "vm.dirty_ratio = $(sysctl -n vm.dirty_ratio)" | tee -a $LOG_FILE
echo "vm.vfs_cache_pressure = $(sysctl -n vm.vfs_cache_pressure)" | tee -a $LOG_FILE
echo "net.ipv4.tcp_congestion_control = $(sysctl -n net.ipv4.tcp_congestion_control)" | tee -a $LOG_FILE
echo "net.core.somaxconn = $(sysctl -n net.core.somaxconn)" | tee -a $LOG_FILE
echo | tee -a $LOG_FILE

echo "Log saved to: $LOG_FILE"
EOF

chmod +x ~/performance_monitor.sh
Subtask 4.2: Baseline Performance Measurement
Establish baseline performance metrics before and after changes:

# Create a baseline measurement
echo "Taking baseline measurements..."
./performance_monitor.sh

# Create a simple load test script
cat > ~/load_test.sh << 'EOF'
#!/bin/bash

echo "Starting load test..."

# Memory stress test
stress-ng --vm 2 --vm-bytes 512M --timeout 30s &

# I/O stress test  
dd if=/dev/zero of=/tmp/testfile bs=1M count=100 oflag=direct &

# Network test (if netcat is available)
if command -v nc >/dev/null 2>&1; then
    # Simple network load
    for i in {1..10}; do
        echo "Test connection $i" | nc -l -p $((8000+i)) &
    done
fi

wait
rm -f /tmp/testfile

echo "Load test completed"
EOF

chmod +x ~/load_test.sh
Subtask 4.3: Performance Testing with Modified Parameters
Test system performance with the modified kernel parameters:

# Run load test with current settings
echo "Running performance test with modified parameters..."
./load_test.sh

# Take measurements during load
./performance_monitor.sh

# Create a comparison script
cat > ~/compare_performance.sh << 'EOF'
#!/bin/bash

echo "Performance Comparison Report"
echo "============================="
echo "Generated: $(date)"
echo

echo "Modified Kernel Parameters:"
echo "---------------------------"
echo "Virtual Memory:"
echo "  vm.swappiness = $(sysctl -n vm.swappiness) (default: 60)"
echo "  vm.dirty_ratio = $(sysctl -n vm.dirty_ratio) (default: 20)"
echo "  vm.dirty_background_ratio = $(sysctl -n vm.dirty_background_ratio) (default: 10)"
echo "  vm.vfs_cache_pressure = $(sysctl -n vm.vfs_cache_pressure) (default: 100)"
echo

echo "Network Parameters:"
echo "  net.ipv4.tcp_congestion_control = $(sysctl -n net.ipv4.tcp_congestion_control)"
echo "  net.core.somaxconn = $(sysctl -n net.core.somaxconn) (default: 128)"
echo "  net.core.rmem_max = $(sysctl -n net.core.rmem_max)"
echo "  net.core.wmem_max = $(sysctl -n net.core.wmem_max)"
echo

echo "Current System Status:"
echo "---------------------"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory Usage: $(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
echo "Swap Usage: $(free | awk 'NR==3{printf "%.1f%%", $3*100/$2}')"
echo "Active Connections: $(ss -tuln | wc -l)"
EOF

chmod +x ~/compare_performance.sh
./compare_performance.sh
Task 5: Making Persistent Changes
Subtask 5.1: Understanding Persistence Methods
Kernel parameter changes made with sysctl are temporary and will be lost after reboot. To make changes persistent, we need to configure them properly:

# Check the main sysctl configuration file
ls -la /etc/sysctl.conf
cat /etc/sysctl.conf

# Check for additional configuration directories
ls -la /etc/sysctl.d/
Subtask 5.2: Creating Persistent Configuration
Create persistent configuration files for our optimizations:

# Create a custom sysctl configuration file
sudo tee /etc/sysctl.d/99-performance-tuning.conf << 'EOF'
# Performance Tuning Configuration
# Created for Lab 15: Modifying Kernel Parameters with sysctl

# Virtual Memory Optimizations
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
vm.vfs_cache_pressure = 50

# Network Performance Optimizations
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 60

# Buffer Size Optimizations
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Connection Handling Optimizations
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
EOF

echo "Persistent configuration created in /etc/sysctl.d/99-performance-tuning.conf"
Subtask 5.3: Validating Persistent Configuration
Test and validate the persistent configuration:

# Test the configuration file syntax
sudo sysctl -p /etc/sysctl.d/99-performance-tuning.conf

# Apply all sysctl configurations
sudo sysctl --system

# Create a validation script
cat > ~/validate_config.sh << 'EOF'
#!/bin/bash

CONFIG_FILE="/etc/sysctl.d/99-performance-tuning.conf"
VALIDATION_LOG="/tmp/sysctl_validation.log"

echo "Validating sysctl configuration..." | tee $VALIDATION_LOG
echo "Configuration file: $CONFIG_FILE" | tee -a $VALIDATION_LOG
echo "Validation time: $(date)" | tee -a $VALIDATION_LOG
echo "=================================" | tee -a $VALIDATION_LOG

# Read each parameter from config file and validate
while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ $line =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
        continue
    fi
    
    # Extract parameter name and expected value
    if [[ $line =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
        param="${BASH_REMATCH[1]// /}"
        expected="${BASH_REMATCH[2]// /}"
        
        # Get current value
        current=$(sysctl -n "$param" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            if [ "$current" = "$expected" ]; then
                echo "✓ $param = $current (OK)" | tee -a $VALIDATION_LOG
            else
                echo "✗ $param = $current (Expected: $expected)" | tee -a $VALIDATION_LOG
            fi
        else
            echo "✗ $param = ERROR (Parameter not found)" | tee -a $VALIDATION_LOG
        fi
    fi
done < "$CONFIG_FILE"

echo | tee -a $VALIDATION_LOG
echo "Validation completed. Log saved to: $VALIDATION_LOG"
EOF

chmod +x ~/validate_config.sh
./validate_config.sh
Subtask 5.4: Creating Backup and Restore Scripts
Create scripts to backup and restore original settings:

# Create a backup of original settings
cat > ~/backup_sysctl.sh << 'EOF'
#!/bin/bash

BACKUP_FILE="/tmp/sysctl_backup_$(date +%Y%m%d_%H%M%S).conf"

echo "Creating sysctl backup..."
echo "# sysctl backup created on $(date)" > $BACKUP_FILE
echo "# Original system values before performance tuning" >> $BACKUP_FILE
echo >> $BACKUP_FILE

# Backup key parameters we modified
PARAMS=(
    "vm.swappiness"
    "vm.dirty_ratio"
    "vm.dirty_background_ratio"
    "vm.dirty_expire_centisecs"
    "vm.dirty_writeback_centisecs"
    "vm.vfs_cache_pressure"
    "net.ipv4.tcp_window_scaling"
    "net.ipv4.tcp_timestamps"
    "net.ipv4.tcp_sack"
    "net.ipv4.tcp_keepalive_time"
    "net.ipv4.tcp_keepalive_probes"
    "net.ipv4.tcp_keepalive_intvl"
    "net.core.rmem_default"
    "net.core.rmem_max"
    "net.core.wmem_default"
    "net.core.wmem_max"
    "net.core.somaxconn"
    "net.ipv4.tcp_max_syn_backlog"
    "net.ipv4.tcp_syncookies"
    "net.ipv4.tcp_syn_retries"
    "net.ipv4.tcp_synack_retries"
    "net.ipv4.tcp_tw_reuse"
    "net.ipv4.tcp_fin_timeout"
)

for param in "${PARAMS[@]}"; do
    value=$(sysctl -n "$param" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$param = $value" >> $BACKUP_FILE
    fi
done

echo "Backup created: $BACKUP_FILE"
EOF

chmod +x ~/backup_sysctl.sh

# Create restore script
cat > ~/restore_sysctl.sh << 'EOF'
#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <backup_file>"
    echo "Available backups:"
    ls -la /tmp/sysctl_backup_*.conf 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring sysctl settings from: $BACKUP_FILE"

# Apply settings from backup file
sudo sysctl -p "$BACKUP_FILE"

echo "Settings restored successfully"
EOF

chmod +x ~/restore_sysctl.sh
Task 6: Advanced Kernel Parameter Tuning
Subtask 6.1: Security-Related Parameters
Configure security-related kernel parameters:

# Create security tuning configuration
sudo tee /etc/sysctl.d/98-security-tuning.conf << 'EOF'
# Security Tuning Configuration

# Enable Address Space Layout Randomization (ASLR)
kernel.randomize_va_space = 2

# Disable IP forwarding (unless needed for routing)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Enable SYN flood protection
net.ipv4.tcp_syncookies = 1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable ping responses (optional)
# net.ipv4.icmp_echo_ignore_all = 1

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF

# Apply security settings
sudo sysctl -p /etc/sysctl.d/98-security-tuning.conf
Subtask 6.2: File System Parameters
Optimize file system related parameters:

# Create file system tuning configuration
sudo tee /etc/sysctl.d/97-filesystem-tuning.conf << 'EOF'
# File System Tuning Configuration

# Increase file handle limits
fs.file-max = 2097152

# Optimize inode and dentry cache
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 256

# AIO optimization
fs.aio-max-nr = 1048576
EOF

# Apply file system settings
sudo sysctl -p /etc/sysctl.d/97-filesystem-tuning.conf

# Check current file system limits
echo "Current file system parameters:"
sysctl fs.file-max
sysctl fs.inotify.max_user_watches
sysctl fs.aio-max-nr
Subtask 6.3: Creating a Comprehensive Tuning Profile
Create a script that applies different tuning profiles based on system role:

cat > ~/sysctl_profiles.sh << 'EOF'
#!/bin/bash

PROFILE_DIR="/etc/sysctl.d"

create_web_server_profile() {
    echo "Creating web server performance profile..."
    
    sudo tee ${PROFILE_DIR}/90-webserver-profile.conf << 'WEBEOF'
# Web Server Performance Profile

# Memory optimizations for web servers
vm.swappiness = 1
vm.dirty_ratio = 10
vm.dirty_background_ratio = 3
vm.vfs_cache_pressure = 50

# Network optimizations for high connection loads
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300

# Buffer optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# File handle limits
fs.file-max = 1000000
WEBEOF
}

create_database_profile() {
    echo "Creating database server performance profile..."
    
    sudo tee ${PROFILE_DIR}/90-database-profile.conf << 'DBEOF'
# Database Server Performance Profile

# Memory optimizations for databases
vm.swappiness = 1
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
vm.dirty_expire_centisecs = 1500
vm.dirty_writeback_centisecs = 250
vm.vfs_cache_pressure = 200

# Shared memory optimizations
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

# Network optimizations
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# File system optimizations
fs.file-max = 2097152
fs.aio-max-nr = 1048576
DBEOF
}

create_default_profile() {
    echo "Creating balanced default profile..."
    
    sudo tee ${PROFILE_DIR}/90-default-profile.conf << 'DEFEOF'
# Balanced Default Performance Profile

# Balanced memory settings
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 100

# Standard network settings
net.core.somaxconn = 1024
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30

# Standard buffer sizes
net.core.rmem_default = 212992
net.core.wmem_default = 212992
DEFEOF
}

case "$1" in
    "webserver")
        create_web_server_profile
        sudo sysctl --system
        ;;
    "database")
        create
