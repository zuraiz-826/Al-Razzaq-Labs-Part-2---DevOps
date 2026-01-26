Lab 19: Automating System Tuning with tuned
Objectives
By the end of this lab, students will be able to:

Understand the purpose and functionality of the tuned daemon for system performance optimization
Install and configure tuned profiles to optimize system performance for specific workloads
Create and customize tuned profiles based on system requirements
Automate the deployment and management of tuned profiles using Ansible
Verify and measure performance improvements using sysctl commands and system monitoring tools
Implement automated system tuning workflows in enterprise environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and text editors
Knowledge of system performance concepts (CPU, memory, I/O)
Basic understanding of Ansible automation concepts
Experience with YAML configuration files
Understanding of system monitoring and performance metrics
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 based systems
Pre-installed tuned package
Ansible automation platform
System monitoring tools
Root access for system configuration
Task 1: Install and Configure tuned Profiles for System Optimization
Subtask 1.1: Understanding tuned and Available Profiles
First, let's explore the tuned daemon and understand what profiles are available on your system.

Check if tuned is installed and running:
# Check tuned installation status
rpm -qa | grep tuned

# Check tuned service status
systemctl status tuned
Install tuned if not already present:
# Install tuned package
sudo dnf install tuned tuned-utils -y

# Enable and start tuned service
sudo systemctl enable tuned
sudo systemctl start tuned
List available tuned profiles:
# Display all available profiles
tuned-adm list

# Show currently active profile
tuned-adm active

# Get detailed information about current profile
tuned-adm profile_info
Subtask 1.2: Exploring Default Profiles
Let's examine some common tuned profiles and their purposes:

View profile details:
# Get information about the balanced profile
tuned-adm profile_info balanced

# Get information about the throughput-performance profile
tuned-adm profile_info throughput-performance

# Get information about the latency-performance profile
tuned-adm profile_info latency-performance
Check profile locations and configurations:
# List profile directories
ls -la /usr/lib/tuned/

# Examine a profile configuration
cat /usr/lib/tuned/balanced/tuned.conf

# Check for custom profiles
ls -la /etc/tuned/
Subtask 1.3: Applying and Testing Different Profiles
Now let's apply different profiles and observe their effects:

Apply the throughput-performance profile:
# Set throughput-performance profile
sudo tuned-adm profile throughput-performance

# Verify the profile is active
tuned-adm active

# Check current system settings
sysctl vm.swappiness
sysctl kernel.sched_min_granularity_ns
Apply the latency-performance profile:
# Set latency-performance profile
sudo tuned-adm profile latency-performance

# Verify the profile is active
tuned-adm active

# Check system settings changes
sysctl kernel.sched_min_granularity_ns
sysctl kernel.sched_wakeup_granularity_ns
Create a baseline measurement script:
# Create performance measurement script
cat > /tmp/performance_test.sh << 'EOF'
#!/bin/bash

echo "=== System Performance Baseline ==="
echo "Current tuned profile: $(tuned-adm active)"
echo "Date: $(date)"
echo ""

echo "=== CPU Information ==="
lscpu | grep -E "CPU\(s\)|Thread|Core|Socket"
echo ""

echo "=== Memory Information ==="
free -h
echo ""

echo "=== Key Kernel Parameters ==="
echo "vm.swappiness: $(sysctl -n vm.swappiness)"
echo "vm.dirty_ratio: $(sysctl -n vm.dirty_ratio)"
echo "kernel.sched_min_granularity_ns: $(sysctl -n kernel.sched_min_granularity_ns)"
echo "net.core.rmem_max: $(sysctl -n net.core.rmem_max)"
echo ""

echo "=== CPU Governor ==="
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "CPU governor info not available"
echo ""

echo "=== Load Average ==="
uptime
echo ""
EOF

chmod +x /tmp/performance_test.sh
Run baseline tests with different profiles:
# Test with balanced profile
sudo tuned-adm profile balanced
/tmp/performance_test.sh > /tmp/balanced_baseline.txt

# Test with throughput-performance profile
sudo tuned-adm profile throughput-performance
/tmp/performance_test.sh > /tmp/throughput_baseline.txt

# Test with latency-performance profile
sudo tuned-adm profile latency-performance
/tmp/performance_test.sh > /tmp/latency_baseline.txt

# Compare the results
echo "=== Comparison of Profiles ==="
diff /tmp/balanced_baseline.txt /tmp/throughput_baseline.txt
Subtask 1.4: Creating Custom tuned Profiles
Let's create a custom tuned profile for a specific workload:

Create a custom profile directory:
# Create custom profile directory
sudo mkdir -p /etc/tuned/web-server-optimized

# Create the profile configuration
sudo tee /etc/tuned/web-server-optimized/tuned.conf << 'EOF'
#
# Custom tuned profile for web server optimization
#

[main]
summary=Optimized profile for web server workloads
include=throughput-performance

[sysctl]
# Network optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 5000

# Memory optimizations for web workloads
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# File system optimizations
fs.file-max = 2097152

[cpu]
governor = performance
energy_perf_bias = performance

[disk]
# Optimize for web server I/O patterns
elevator = mq-deadline
EOF
Apply and test the custom profile:
# Apply the custom profile
sudo tuned-adm profile web-server-optimized

# Verify it's active
tuned-adm active

# Check the applied settings
echo "=== Custom Profile Settings ==="
sysctl net.core.rmem_max
sysctl net.ipv4.tcp_congestion_control
sysctl vm.swappiness
sysctl fs.file-max
Create a database-optimized profile:
# Create database profile directory
sudo mkdir -p /etc/tuned/database-optimized

# Create database-specific configuration
sudo tee /etc/tuned/database-optimized/tuned.conf << 'EOF'
#
# Custom tuned profile for database server optimization
#

[main]
summary=Optimized profile for database server workloads
include=latency-performance

[sysctl]
# Memory optimizations for database workloads
vm.swappiness = 1
vm.dirty_ratio = 3
vm.dirty_background_ratio = 1
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100

# Shared memory optimizations
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

# Network optimizations
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

[cpu]
governor = performance
energy_perf_bias = performance

[disk]
# Optimize for database I/O patterns
elevator = noop
EOF
Task 2: Automate the Application of tuned Profiles Using Ansible
Subtask 2.1: Setting Up Ansible for tuned Management
Let's create Ansible playbooks to automate tuned profile management:

Create Ansible project structure:
# Create project directory
mkdir -p ~/ansible-tuned-automation
cd ~/ansible-tuned-automation

# Create directory structure
mkdir -p {playbooks,roles,inventory,group_vars,host_vars}

# Create inventory file
cat > inventory/hosts << 'EOF'
[web_servers]
localhost ansible_connection=local

[database_servers]
# Add your database servers here
# db1.example.com
# db2.example.com

[all:vars]
ansible_user=root
EOF
Create group variables for different server types:
# Create web server variables
cat > group_vars/web_servers.yml << 'EOF'
---
tuned_profile: web-server-optimized
server_type: web
monitoring_enabled: true

# Web server specific tuning parameters
web_tuning:
  max_connections: 1000
  keepalive_timeout: 65
  worker_processes: auto
EOF

# Create database server variables
cat > group_vars/database_servers.yml << 'EOF'
---
tuned_profile: database-optimized
server_type: database
monitoring_enabled: true

# Database specific tuning parameters
db_tuning:
  shared_buffers: "256MB"
  effective_cache_size: "1GB"
  maintenance_work_mem: "64MB"
EOF
Subtask 2.2: Creating Ansible Roles for tuned Management
Create the tuned management role:
# Create role structure
mkdir -p roles/tuned_management/{tasks,templates,vars,handlers,files}

# Create main tasks file
cat > roles/tuned_management/tasks/main.yml << 'EOF'
---
- name: Install tuned package
  package:
    name: 
      - tuned
      - tuned-utils
    state: present
  become: yes

- name: Start and enable tuned service
  systemd:
    name: tuned
    state: started
    enabled: yes
  become: yes

- name: Create custom tuned profile directory
  file:
    path: "/etc/tuned/{{ tuned_profile }}"
    state: directory
    mode: '0755'
  become: yes
  when: tuned_profile not in ['balanced', 'throughput-performance', 'latency-performance', 'desktop', 'powersave']

- name: Deploy custom tuned profile configuration
  template:
    src: "{{ tuned_profile }}.conf.j2"
    dest: "/etc/tuned/{{ tuned_profile }}/tuned.conf"
    mode: '0644'
  become: yes
  when: tuned_profile not in ['balanced', 'throughput-performance', 'latency-performance', 'desktop', 'powersave']
  notify: restart tuned

- name: Apply tuned profile
  command: "tuned-adm profile {{ tuned_profile }}"
  become: yes
  register: tuned_result
  changed_when: "'Tuned profile' in tuned_result.stdout"

- name: Verify tuned profile is active
  command: tuned-adm active
  register: active_profile
  changed_when: false

- name: Display active profile
  debug:
    msg: "Active tuned profile: {{ active_profile.stdout }}"
EOF
Create template files for custom profiles:
# Create web server profile template
cat > roles/tuned_management/templates/web-server-optimized.conf.j2 << 'EOF'
#
# Custom tuned profile for web server optimization
# Managed by Ansible
#

[main]
summary=Optimized profile for web server workloads
include=throughput-performance

[sysctl]
# Network optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 5000

# Memory optimizations for web workloads
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# File system optimizations
fs.file-max = 2097152
{% if web_tuning is defined %}
fs.nr_open = {{ web_tuning.max_connections * 10 }}
{% endif %}

[cpu]
governor = performance
energy_perf_bias = performance

[disk]
# Optimize for web server I/O patterns
elevator = mq-deadline
EOF

# Create database server profile template
cat > roles/tuned_management/templates/database-optimized.conf.j2 << 'EOF'
#
# Custom tuned profile for database server optimization
# Managed by Ansible
#

[main]
summary=Optimized profile for database server workloads
include=latency-performance

[sysctl]
# Memory optimizations for database workloads
vm.swappiness = 1
vm.dirty_ratio = 3
vm.dirty_background_ratio = 1
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100

# Shared memory optimizations
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

# Network optimizations
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

[cpu]
governor = performance
energy_perf_bias = performance

[disk]
# Optimize for database I/O patterns
elevator = noop
EOF
Create handlers for the role:
# Create handlers file
cat > roles/tuned_management/handlers/main.yml << 'EOF'
---
- name: restart tuned
  systemd:
    name: tuned
    state: restarted
  become: yes
EOF
Subtask 2.3: Creating Ansible Playbooks
Create the main deployment playbook:
# Create main playbook
cat > playbooks/deploy-tuned-profiles.yml << 'EOF'
---
- name: Deploy and Configure tuned Profiles
  hosts: all
  become: yes
  gather_facts: yes
  
  pre_tasks:
    - name: Update package cache
      package:
        update_cache: yes
      when: ansible_os_family == "RedHat"

  roles:
    - tuned_management

  post_tasks:
    - name: Collect system information after tuning
      setup:
        gather_subset:
          - hardware
          - network
      register: post_tuning_facts

    - name: Generate tuning report
      template:
        src: tuning_report.j2
        dest: "/tmp/tuning_report_{{ inventory_hostname }}.txt"
      delegate_to: localhost
EOF
Create a monitoring and verification playbook:
# Create monitoring playbook
cat > playbooks/verify-tuned-performance.yml << 'EOF'
---
- name: Verify tuned Profile Performance
  hosts: all
  become: yes
  gather_facts: yes

  tasks:
    - name: Check active tuned profile
      command: tuned-adm active
      register: current_profile
      changed_when: false

    - name: Collect current sysctl values
      shell: |
        echo "=== Current System Tuning Parameters ==="
        echo "Active Profile: {{ current_profile.stdout }}"
        echo "vm.swappiness: $(sysctl -n vm.swappiness)"
        echo "vm.dirty_ratio: $(sysctl -n vm.dirty_ratio)"
        echo "net.core.rmem_max: $(sysctl -n net.core.rmem_max)"
        echo "net.core.wmem_max: $(sysctl -n net.core.wmem_max)"
        echo "fs.file-max: $(sysctl -n fs.file-max)"
        echo ""
        echo "=== CPU Governor ==="
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A"
        echo ""
        echo "=== Memory Usage ==="
        free -h
        echo ""
        echo "=== Load Average ==="
        uptime
      register: system_status
      changed_when: false

    - name: Display system status
      debug:
        msg: "{{ system_status.stdout_lines }}"

    - name: Save performance metrics
      copy:
        content: "{{ system_status.stdout }}"
        dest: "/tmp/performance_metrics_{{ inventory_hostname }}_{{ ansible_date_time.epoch }}.txt"
      delegate_to: localhost
EOF
Create a rollback playbook:
# Create rollback playbook
cat > playbooks/rollback-tuned-profile.yml << 'EOF'
---
- name: Rollback to Default tuned Profile
  hosts: all
  become: yes
  
  vars:
    default_profile: balanced

  tasks:
    - name: Get current active profile
      command: tuned-adm active
      register: current_profile
      changed_when: false

    - name: Apply default profile
      command: "tuned-adm profile {{ default_profile }}"
      register: rollback_result
      when: default_profile not in current_profile.stdout

    - name: Verify rollback
      command: tuned-adm active
      register: new_profile
      changed_when: false

    - name: Display rollback status
      debug:
        msg: 
          - "Previous profile: {{ current_profile.stdout }}"
          - "Current profile: {{ new_profile.stdout }}"
          - "Rollback completed successfully"
      when: rollback_result is changed
EOF
Subtask 2.4: Running Ansible Playbooks
Execute the deployment playbook:
# Run the deployment playbook
cd ~/ansible-tuned-automation

# Check syntax first
ansible-playbook -i inventory/hosts playbooks/deploy-tuned-profiles.yml --syntax-check

# Run in check mode (dry run)
ansible-playbook -i inventory/hosts playbooks/deploy-tuned-profiles.yml --check

# Execute the playbook
ansible-playbook -i inventory/hosts playbooks/deploy-tuned-profiles.yml -v
Verify the deployment:
# Run verification playbook
ansible-playbook -i inventory/hosts playbooks/verify-tuned-performance.yml

# Check the generated reports
ls -la /tmp/performance_metrics_*
cat /tmp/performance_metrics_localhost_*.txt
Create an automated scheduling script:
# Create automated tuning script
cat > ~/automated_tuning.sh << 'EOF'
#!/bin/bash

# Automated tuned Profile Management Script
# This script can be scheduled via cron for regular tuning updates

ANSIBLE_DIR="$HOME/ansible-tuned-automation"
LOG_FILE="/var/log/automated_tuning.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting automated tuning process" >> $LOG_FILE

cd $ANSIBLE_DIR

# Run the deployment playbook
ansible-playbook -i inventory/hosts playbooks/deploy-tuned-profiles.yml >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "[$DATE] Tuning deployment completed successfully" >> $LOG_FILE
    
    # Run verification
    ansible-playbook -i inventory/hosts playbooks/verify-tuned-performance.yml >> $LOG_FILE 2>&1
    
    echo "[$DATE] Verification completed" >> $LOG_FILE
else
    echo "[$DATE] Tuning deployment failed" >> $LOG_FILE
    exit 1
fi

echo "[$DATE] Automated tuning process completed" >> $LOG_FILE
EOF

chmod +x ~/automated_tuning.sh
Task 3: Verify Performance Improvements with sysctl Commands
Subtask 3.1: Creating Performance Measurement Scripts
Let's create comprehensive scripts to measure and compare system performance:

Create a detailed system analysis script:
# Create comprehensive performance analysis script
cat > ~/performance_analyzer.sh << 'EOF'
#!/bin/bash

# Comprehensive System Performance Analyzer
# Usage: ./performance_analyzer.sh [profile_name]

PROFILE_NAME=${1:-"current"}
OUTPUT_DIR="/tmp/performance_analysis"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="$OUTPUT_DIR/performance_report_${PROFILE_NAME}_${TIMESTAMP}.txt"

# Create output directory
mkdir -p $OUTPUT_DIR

echo "=== System Performance Analysis Report ===" > $REPORT_FILE
echo "Profile: $PROFILE_NAME" >> $REPORT_FILE
echo "Timestamp: $(date)" >> $REPORT_FILE
echo "Hostname: $(hostname)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Current tuned profile
echo "=== Active tuned Profile ===" >> $REPORT_FILE
tuned-adm active >> $REPORT_FILE 2>&1
echo "" >> $REPORT_FILE

# System information
echo "=== System Information ===" >> $REPORT_FILE
uname -a >> $REPORT_FILE
echo "" >> $REPORT_FILE

# CPU information
echo "=== CPU Information ===" >> $REPORT_FILE
lscpu | grep -E "CPU\(s\)|Thread|Core|Socket|Model name|CPU MHz" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Memory information
echo "=== Memory Information ===" >> $REPORT_FILE
free -h >> $REPORT_FILE
echo "" >> $REPORT_FILE
cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Critical sysctl parameters
echo "=== Critical Kernel Parameters ===" >> $REPORT_FILE
echo "Memory Management:" >> $REPORT_FILE
sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio vm.dirty_expire_centisecs vm.dirty_writeback_centisecs >> $REPORT_FILE 2>&1
echo "" >> $REPORT_FILE

echo "Network Parameters:" >> $REPORT_FILE
sysctl net.core.rmem_max net.core.wmem_max net.core.netdev_max_backlog >> $REPORT_FILE 2>&1
sysctl net.ipv4.tcp_rmem net.ipv4.tcp_wmem net.ipv4.tcp_congestion_control >> $REPORT_FILE 2>&1
echo "" >> $REPORT_FILE

echo "File System Parameters:" >> $REPORT_FILE
sysctl fs.file-max fs.nr_open >> $REPORT_FILE 2>&1
echo "" >> $REPORT_FILE

echo "Scheduler Parameters:" >> $REPORT_FILE
sysctl kernel.sched_min_granularity_ns kernel.sched_wakeup_granularity_ns >> $REPORT_FILE 2>&1
echo "" >> $REPORT_FILE

# CPU governor and frequency
echo "=== CPU Governor and Frequency ===" >> $REPORT_FILE
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    echo "CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" >> $REPORT_FILE
    echo "Current CPU Frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo 'N/A')" >> $REPORT_FILE
    echo "Available Governors: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo 'N/A')" >> $REPORT_FILE
else
    echo "CPU frequency scaling information not available" >> $REPORT_FILE
fi
echo "" >> $REPORT_FILE

# Disk scheduler
echo "=== Disk Scheduler Information ===" >> $REPORT_FILE
for disk in $(lsblk -d -n -o NAME | grep -E '^(sd|nvme|vd)'); do
    if [ -f /sys/block/$disk/queue/scheduler ]; then
        echo "$disk scheduler: $(cat /sys/block/$disk/queue/scheduler)" >> $REPORT_FILE
    fi
done
echo "" >> $REPORT_FILE

# Network interface information
echo "=== Network Interface Information ===" >> $REPORT_FILE
ip link show | grep -E "^[0-9]+:" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Load average and uptime
echo "=== System Load ===" >> $REPORT_FILE
uptime >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Process information
echo "=== Top Processes by CPU ===" >> $REPORT_FILE
ps aux --sort=-%cpu | head -10 >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "=== Top Processes by Memory ===" >> $REPORT_FILE
ps aux --sort=-%mem | head -10 >> $REPORT_FILE
echo "" >> $REPORT_FILE

# I/O statistics
echo "=== I/O Statistics ===" >> $REPORT_FILE
if command -v iostat >/dev/null 2>&1; then
    iostat -x 1 3 >> $REPORT_FILE 2>&1
else
    echo "iostat not available - install sysstat package for detailed I/O statistics" >> $REPORT_FILE
fi
echo "" >> $REPORT_FILE

echo "Performance analysis completed. Report saved to: $REPORT_FILE"
echo "Report location: $REPORT_FILE"
EOF

chmod +x ~/performance_analyzer.sh
Create a performance comparison script:
# Create performance comparison script
cat > ~/compare_performance.sh << 'EOF'
#!/bin/bash

# Performance Comparison Script
# Usage: ./compare_performance.sh profile1 profile2

if [ $# -ne 2 ]; then
    echo "Usage: $0 <profile1> <profile2>"
    echo "Example: $0 balanced throughput-performance"
    exit 1
fi

PROFILE1=$1
PROFILE2=$2
COMPARISON_DIR="/tmp/performance_comparison"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

mkdir -p $COMPARISON_DIR

echo "=== Performance Comparison: $PROFILE1 vs $PROFILE2 ==="
echo "Starting comparison at $(date)"

# Test profile 1
echo "Testing profile: $PROFILE1"
sudo tuned-adm profile $PROFILE1
sleep 5  # Allow time for settings to take effect
~/performance_analyzer.sh $PROFILE1

# Test profile 2
echo "Testing profile: $PROFILE2"
sudo tuned-adm profile $PROFILE2
sleep 5  # Allow time for settings to take effect
~/performance_analyzer.sh $PROFILE2

# Create comparison report
REPORT1=$(ls -t /tmp/performance_analysis/performance_report_${PROFILE1}_*.txt | head -1)
REPORT2=$(ls -t /tmp/performance_analysis/performance_report_${PROFILE2}_*.txt | head -1)
COMPARISON_REPORT="$COMPARISON_DIR/comparison_${PROFILE1}_vs_${PROFILE2}_${TIMESTAMP}.txt"

echo "=== Performance Comparison Report ===" > $COMPARISON_REPORT
echo "Profile 1: $PROFILE1" >> $COMPARISON_REPORT
echo "Profile 2: $PROFILE2" >> $COMPARISON_REPORT
echo "Generated: $(date)" >> $COMPARISON_REPORT
echo "" >> $COMPARISON_REPORT

echo "=== Key Differences ===" >> $COMPARISON_REPORT
echo "Comparing critical parameters between profiles:" >> $COMPARISON_REPORT
echo "" >> $COMPARISON_REPORT

# Extract and compare key metrics
echo "Memory Management Parameters:" >> $COMPARISON_REPORT
echo "Parameter | $PROFILE1 | $PROFILE2" >> $COMPARISON_REPORT
echo "----------|----------|----------" >> $COMPARISON_REPORT

for param in vm.swappiness vm.dirty_ratio vm.dirty_background_ratio; do
    val1=$(grep "$param" "$REPORT1" | awk '{print $3}')
    val2=$(grep "$param" "$REPORT2" | awk '{print $3}')
    printf "%-20s | %-8s | %-8s\n" "$param" "$val1" "$val2" >> $COMPARISON_REPORT
done

echo "" >> $COMPARISON_REPORT
echo "Network Parameters:" >> $COMPARISON_REPORT
echo "Parameter | $PROFILE1 | $PROFILE2" >> $COMPARISON_REPORT
echo "----------|----------|----------" >> $COMPARISON_REPORT

for param in net.core.rmem_max net.core.wmem_max; do
    val1=$(grep "$param" "$REPORT1" | awk '{print $3}')
    val2=$(grep "$param" "$REPORT2" | awk '{print $3}')
    printf "%-20s | %-8s | %-8s\n" "$param" "$val1" "$val2" >> $COMPARISON_REPORT
done

echo "" >> $COMPARISON_REPORT
echo "CPU Governor:" >> $COMPARISON_REPORT
gov1=$(grep "CPU Governor:" "$REPORT1" | awk '{print $3}')
gov2=$(grep "CPU Governor:" "$REPORT2" | awk '{print $3}')
echo "$PROFILE1: $gov1" >> $COMPARISON_REPORT
echo "$PROFILE2: $gov2" >> $COMPARISON_REPORT

echo "" >> $COMPARISON_REPORT
echo "Full reports available at:" >> $COMPARISON_REPORT
echo "Profile 1 ($PROFILE1): $REPORT1" >> $COMPARISON_REPORT
echo "Profile 2 ($PROFILE2): $REPORT2" >> $COMPARISON_REPORT

echo "Comparison completed. Report saved to: $COMPARISON_REPORT"
cat $COMPARISON_REPORT
EOF

chmod +x ~/compare_performance.sh
Subtask 3.2: Benchmarking Different Profiles
Let's create benchmarking scripts to measure actual performance differences:

Create a CPU benchmark script:
# Create CPU benchmark script
cat > ~/cpu_benchmark.sh << 'EOF'
#!/bin/bash

# CPU Performance Benchmark Script
# Tests CPU performance under different tuned profiles

BENCHMARK_DIR="/tmp/cpu_benchmarks"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

mkdir -p $BENCHMARK_DIR

echo "=== CPU Benchmark Test ==="
echo "Profile: $(tuned-adm active)"
echo "Start time: $(date)"

# CPU intensive calculation benchmark
echo "Running CPU calculation benchmark..."
CALC_START=$(date +%s.%N)

# Calculate prime numbers (CPU intensive task)
python3 -c "
import time
start = time.time()
def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(n**0.5) + 1):
        if n % i == 0:
            return False
    return True

primes = [n for n in range(2, 10000) if is_prime(n)]
end = time.time()
print(f'Found {len(primes)} primes in {end - start:.4f} seconds')
" > $BENCHMARK_DIR/cpu_calc_${TIMESTAMP
