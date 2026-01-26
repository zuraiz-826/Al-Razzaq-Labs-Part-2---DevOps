Lab 13: Tuning Virtualization Performance
Objectives
By the end of this lab, students will be able to:

Configure optimal vCPU allocation strategies for virtual machines
Implement memory ballooning techniques to maximize memory efficiency
Monitor and analyze virtual machine performance metrics
Apply performance tuning best practices for virtualized environments
Test and validate performance improvements under various load conditions
Troubleshoot common virtualization performance bottlenecks
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface operations
Knowledge of virtualization concepts (hypervisors, VMs, containers)
Understanding of system resources (CPU, memory, storage)
Experience with basic performance monitoring tools
Completion of previous labs in the Red Hat Performance Tuning series
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with KVM/QEMU virtualization stack already installed. Simply click Start Lab to access your environment - no need to build your own VM infrastructure.

Your lab environment includes:

Host system with 8 vCPUs and 16GB RAM
KVM hypervisor with libvirt management
Pre-installed performance monitoring tools
Sample virtual machines for testing
Task 1: Configure vCPU and Memory Settings for VMs
Subtask 1.1: Analyze Current VM Configuration
First, let's examine the existing virtual machine configurations to understand the baseline setup.

List all virtual machines:
sudo virsh list --all
Check detailed VM configuration:
sudo virsh dumpxml vm-test1 | grep -E "(vcpu|memory)"
View current resource allocation:
sudo virsh dominfo vm-test1
Subtask 1.2: Configure Optimal vCPU Settings
Understanding vCPU topology is crucial for performance. We'll configure vCPUs to match the physical CPU architecture.

Check host CPU information:
lscpu | grep -E "(CPU\(s\)|Thread|Core|Socket)"
cat /proc/cpuinfo | grep -E "(processor|physical id|core id)" | head -20
Create a performance-optimized VM configuration script:
cat > configure_vcpu.sh << 'EOF'
#!/bin/bash

VM_NAME="performance-vm"
VCPUS=4
MEMORY=4096

# Create new VM with optimized settings
sudo virt-install \
    --name $VM_NAME \
    --ram $MEMORY \
    --vcpus $VCPUS,maxvcpus=8,sockets=1,cores=4,threads=1 \
    --cpu host-passthrough \
    --disk path=/var/lib/libvirt/images/$VM_NAME.qcow2,size=20,format=qcow2 \
    --network bridge=virbr0 \
    --graphics none \
    --console pty,target_type=serial \
    --location 'http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/' \
    --extra-args 'console=ttyS0,115200n8 serial' \
    --noautoconsole

echo "VM $VM_NAME created with optimized vCPU configuration"
EOF

chmod +x configure_vcpu.sh
Apply CPU affinity for better performance:
# Pin vCPUs to specific physical CPUs
sudo virsh vcpupin performance-vm 0 0
sudo virsh vcpupin performance-vm 1 1
sudo virsh vcpupin performance-vm 2 2
sudo virsh vcpupin performance-vm 3 3

# Verify CPU pinning
sudo virsh vcpuinfo performance-vm
Subtask 1.3: Optimize Memory Configuration
Memory configuration significantly impacts VM performance. Let's implement advanced memory settings.

Configure NUMA-aware memory allocation:
cat > memory_config.xml << 'EOF'
<domain type='kvm'>
  <memory unit='KiB'>4194304</memory>
  <currentMemory unit='KiB'>2097152</currentMemory>
  <memoryBacking>
    <hugepages/>
    <nosharepages/>
    <locked/>
  </memoryBacking>
  <numatune>
    <memory mode='strict' nodeset='0'/>
  </numatune>
</domain>
EOF
Enable huge pages for better memory performance:
# Check current huge pages configuration
cat /proc/meminfo | grep -i huge

# Configure huge pages (requires root)
echo 1024 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# Verify huge pages allocation
cat /proc/meminfo | grep -i huge
Apply memory configuration to VM:
# Create script to update VM memory settings
cat > update_memory.sh << 'EOF'
#!/bin/bash

VM_NAME="performance-vm"

# Stop VM if running
sudo virsh shutdown $VM_NAME

# Wait for shutdown
sleep 10

# Edit VM configuration
sudo virsh edit $VM_NAME

echo "Memory configuration updated for $VM_NAME"
echo "Remember to add hugepages and NUMA settings manually in the editor"
EOF

chmod +x update_memory.sh
Task 2: Use Memory Ballooning to Optimize Memory Usage
Subtask 2.1: Enable Memory Ballooning
Memory ballooning allows dynamic memory allocation between host and guest systems, optimizing overall memory usage.

Install balloon driver in guest VM:
# Connect to guest VM
sudo virsh console performance-vm

# Inside guest VM, install balloon driver
sudo modprobe virtio_balloon
echo "virtio_balloon" | sudo tee -a /etc/modules

# Verify balloon driver is loaded
lsmod | grep virtio_balloon
Configure balloon device in VM XML:
cat > balloon_config.xml << 'EOF'
<memballoon model='virtio'>
  <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'/>
  <stats period='10'/>
</memballoon>
EOF
Add balloon device to VM:
# Create complete balloon configuration script
cat > setup_ballooning.sh << 'EOF'
#!/bin/bash

VM_NAME="performance-vm"

# Shutdown VM
sudo virsh shutdown $VM_NAME
sleep 15

# Add balloon device
sudo virsh attach-device $VM_NAME --file balloon_config.xml --config

# Start VM
sudo virsh start $VM_NAME

echo "Memory ballooning enabled for $VM_NAME"
EOF

chmod +x setup_ballooning.sh
./setup_ballooning.sh
Subtask 2.2: Monitor and Control Memory Ballooning
Create memory monitoring script:
cat > monitor_balloon.sh << 'EOF'
#!/bin/bash

VM_NAME="performance-vm"

echo "=== Memory Ballooning Status ==="
echo "Host Memory Usage:"
free -h

echo -e "\nVM Memory Statistics:"
sudo virsh dommemstat $VM_NAME

echo -e "\nBalloon Memory Info:"
sudo virsh dominfo $VM_NAME | grep -i memory

echo -e "\nDetailed Memory Stats:"
sudo virsh domstats --balloon $VM_NAME
EOF

chmod +x monitor_balloon.sh
Implement dynamic memory adjustment:
cat > adjust_memory.sh << 'EOF'
#!/bin/bash

VM_NAME="performance-vm"
NEW_MEMORY_KB=$1

if [ -z "$NEW_MEMORY_KB" ]; then
    echo "Usage: $0 <memory_in_KB>"
    echo "Example: $0 2097152  # for 2GB"
    exit 1
fi

echo "Adjusting memory for $VM_NAME to ${NEW_MEMORY_KB}KB"

# Set balloon target
sudo virsh setmem $VM_NAME $NEW_MEMORY_KB --live

# Monitor the change
sleep 5
sudo virsh dommemstat $VM_NAME

echo "Memory adjustment completed"
EOF

chmod +x adjust_memory.sh
Subtask 2.3: Implement Automatic Memory Balancing
Create intelligent memory balancing script:
cat > auto_balance.sh << 'EOF'
#!/bin/bash

VM_NAME="performance-vm"
LOG_FILE="/var/log/memory_balancing.log"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a $LOG_FILE
}

# Get host memory usage percentage
get_host_memory_usage() {
    free | awk 'NR==2{printf "%.0f", $3*100/$2}'
}

# Get VM memory usage
get_vm_memory_usage() {
    sudo virsh dommemstat $VM_NAME | awk '/actual/ {print $2}'
}

# Main balancing logic
balance_memory() {
    HOST_MEM_USAGE=$(get_host_memory_usage)
    VM_CURRENT_MEM=$(get_vm_memory_usage)
    
    log_message "Host memory usage: ${HOST_MEM_USAGE}%"
    log_message "VM current memory: ${VM_CURRENT_MEM}KB"
    
    if [ $HOST_MEM_USAGE -gt 80 ]; then
        # High host memory usage - reduce VM memory
        NEW_MEM=$((VM_CURRENT_MEM - 524288))  # Reduce by 512MB
        if [ $NEW_MEM -gt 1048576 ]; then  # Don't go below 1GB
            sudo virsh setmem $VM_NAME $NEW_MEM --live
            log_message "Reduced VM memory to ${NEW_MEM}KB due to high host usage"
        fi
    elif [ $HOST_MEM_USAGE -lt 50 ]; then
        # Low host memory usage - can increase VM memory
        NEW_MEM=$((VM_CURRENT_MEM + 262144))  # Increase by 256MB
        if [ $NEW_MEM -lt 4194304 ]; then  # Don't exceed 4GB
            sudo virsh setmem $VM_NAME $NEW_MEM --live
            log_message "Increased VM memory to ${NEW_MEM}KB due to low host usage"
        fi
    fi
}

# Run balancing
balance_memory
EOF

chmod +x auto_balance.sh
Set up automated balancing with cron:
# Add cron job for automatic memory balancing every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/$(whoami)/auto_balance.sh") | crontab -

# Verify cron job
crontab -l
Task 3: Test Performance for Virtual Machines Under Load
Subtask 3.1: Install Performance Testing Tools
Install comprehensive testing suite:
# Install stress testing tools
sudo apt update
sudo apt install -y stress-ng sysbench iperf3 fio htop iotop

# Install additional monitoring tools
sudo apt install -y sysstat collectl nmon
Create performance testing toolkit script:
cat > install_perf_tools.sh << 'EOF'
#!/bin/bash

echo "Installing performance testing tools..."

# System stress testing
sudo apt install -y stress-ng

# Database/CPU benchmarking
sudo apt install -y sysbench

# Network performance testing
sudo apt install -y iperf3 netperf

# Disk I/O testing
sudo apt install -y fio

# System monitoring
sudo apt install -y htop iotop sysstat collectl

# Memory testing
sudo apt install -y memtester

echo "Performance tools installation completed"
EOF

chmod +x install_perf_tools.sh
./install_perf_tools.sh
Subtask 3.2: CPU Performance Testing
Create CPU stress test script:
cat > cpu_stress_test.sh << 'EOF'
#!/bin/bash

VM_NAME="performance-vm"
TEST_DURATION=300  # 5 minutes
LOG_DIR="/tmp/perf_logs"

mkdir -p $LOG_DIR

echo "Starting CPU performance test for $VM_NAME"

# Start monitoring in background
sudo virsh domstats --cpu $VM_NAME > $LOG_DIR/cpu_before.log

# Run CPU stress test
echo "Running CPU stress test for ${TEST_DURATION} seconds..."
stress-ng --cpu 4 --timeout ${TEST_DURATION}s --metrics-brief &
STRESS_PID=$!

# Monitor during test
while kill -0 $STRESS_PID 2>/dev/null; do
    echo "$(date): CPU Usage:" >> $LOG_DIR/cpu_during.log
    sudo virsh domstats --cpu $VM_NAME >> $LOG_DIR/cpu_during.log
    top -bn1 | grep "Cpu(s)" >> $LOG_DIR/cpu_during.log
    sleep 10
done

# Final measurements
sudo virsh domstats --cpu $VM_NAME > $LOG_DIR/cpu_after.log

echo "CPU stress test completed. Logs saved in $LOG_DIR"
EOF

chmod +x cpu_stress_test.sh
Execute CPU performance test:
# Run the CPU stress test
./cpu_stress_test.sh

# Analyze results
cat > analyze_cpu_results.sh << 'EOF'
#!/bin/bash

LOG_DIR="/tmp/perf_logs"

echo "=== CPU Performance Analysis ==="
echo "Before test:"
cat $LOG_DIR/cpu_before.log

echo -e "\nAfter test:"
cat $LOG_DIR/cpu_after.log

echo -e "\nDuring test (last 10 entries):"
tail -20 $LOG_DIR/cpu_during.log
EOF

chmod +x analyze_cpu_results.sh
./analyze_cpu_results.sh
Subtask 3.3: Memory Performance Testing
Create memory stress test script:
cat > memory_stress_test.sh << 'EOF'
#!/bin/bash

VM_NAME="performance-vm"
TEST_DURATION=300
LOG_DIR="/tmp/perf_logs"

mkdir -p $LOG_DIR

echo "Starting memory performance test for $VM_NAME"

# Baseline memory stats
sudo virsh dommemstat $VM_NAME > $LOG_DIR/memory_before.log
free -h > $LOG_DIR/host_memory_before.log

# Memory stress test with monitoring
echo "Running memory stress test..."
stress-ng --vm 2 --vm-bytes 1G --timeout ${TEST_DURATION}s --metrics-brief &
STRESS_PID=$!

# Monitor memory ballooning during test
while kill -0 $STRESS_PID 2>/dev/null; do
    echo "$(date): Memory Stats:" >> $LOG_DIR/memory_during.log
    sudo virsh dommemstat $VM_NAME >> $LOG_DIR/memory_during.log
    free -h >> $LOG_DIR/memory_during.log
    echo "---" >> $LOG_DIR/memory_during.log
    sleep 15
done

# Final memory stats
sudo virsh dommemstat $VM_NAME > $LOG_DIR/memory_after.log
free -h > $LOG_DIR/host_memory_after.log

echo "Memory stress test completed"
EOF

chmod +x memory_stress_test.sh
Run memory performance test:
./memory_stress_test.sh

# Create memory analysis script
cat > analyze_memory_results.sh << 'EOF'
#!/bin/bash

LOG_DIR="/tmp/perf_logs"

echo "=== Memory Performance Analysis ==="
echo "VM Memory - Before:"
cat $LOG_DIR/memory_before.log

echo -e "\nVM Memory - After:"
cat $LOG_DIR/memory_after.log

echo -e "\nHost Memory - Before:"
cat $LOG_DIR/host_memory_before.log

echo -e "\nHost Memory - After:"
cat $LOG_DIR/host_memory_after.log

echo -e "\nMemory Ballooning Activity (sample):"
grep -A 5 "Memory Stats:" $LOG_DIR/memory_during.log | head -20
EOF

chmod +x analyze_memory_results.sh
./analyze_memory_results.sh
Subtask 3.4: Comprehensive Performance Benchmark
Create comprehensive benchmark script:
cat > comprehensive_benchmark.sh << 'EOF'
#!/bin/bash

VM_NAME="performance-vm"
RESULTS_DIR="/tmp/benchmark_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $RESULTS_DIR

echo "Starting comprehensive performance benchmark - $TIMESTAMP"

# System information
echo "=== System Information ===" > $RESULTS_DIR/system_info_$TIMESTAMP.log
lscpu >> $RESULTS_DIR/system_info_$TIMESTAMP.log
free -h >> $RESULTS_DIR/system_info_$TIMESTAMP.log
sudo virsh dominfo $VM_NAME >> $RESULTS_DIR/system_info_$TIMESTAMP.log

# CPU Benchmark
echo "Running CPU benchmark..."
sysbench cpu --cpu-max-prime=20000 --threads=4 run > $RESULTS_DIR/cpu_benchmark_$TIMESTAMP.log

# Memory Benchmark
echo "Running memory benchmark..."
sysbench memory --memory-block-size=1K --memory-scope=global --memory-total-size=2G run > $RESULTS_DIR/memory_benchmark_$TIMESTAMP.log

# File I/O Benchmark
echo "Running file I/O benchmark..."
sysbench fileio --file-total-size=2G prepare > /dev/null
sysbench fileio --file-total-size=2G --file-test-mode=rndrw --time=60 run > $RESULTS_DIR/fileio_benchmark_$TIMESTAMP.log
sysbench fileio --file-total-size=2G cleanup > /dev/null

# Combined stress test
echo "Running combined stress test..."
stress-ng --cpu 2 --vm 1 --vm-bytes 512M --io 1 --timeout 120s --metrics-brief > $RESULTS_DIR/combined_stress_$TIMESTAMP.log

echo "Comprehensive benchmark completed. Results in $RESULTS_DIR"
EOF

chmod +x comprehensive_benchmark.sh
Execute comprehensive benchmark:
./comprehensive_benchmark.sh

# Create results summary
cat > summarize_results.sh << 'EOF'
#!/bin/bash

RESULTS_DIR="/tmp/benchmark_results"
LATEST_TIMESTAMP=$(ls $RESULTS_DIR | grep system_info | tail -1 | cut -d'_' -f3-4 | cut -d'.' -f1)

echo "=== Performance Benchmark Summary ==="
echo "Timestamp: $LATEST_TIMESTAMP"
echo

echo "System Configuration:"
cat $RESULTS_DIR/system_info_$LATEST_TIMESTAMP.log
echo

echo "CPU Performance:"
grep -E "(events per second|total time)" $RESULTS_DIR/cpu_benchmark_$LATEST_TIMESTAMP.log
echo

echo "Memory Performance:"
grep -E "(transferred|total time)" $RESULTS_DIR/memory_benchmark_$LATEST_TIMESTAMP.log
echo

echo "File I/O Performance:"
grep -E "(read|written|total time)" $RESULTS_DIR/fileio_benchmark_$LATEST_TIMESTAMP.log
echo

echo "Combined Stress Test Results:"
grep -E "(successful runs|failed runs)" $RESULTS_DIR/combined_stress_$LATEST_TIMESTAMP.log
EOF

chmod +x summarize_results.sh
./summarize_results.sh
Subtask 3.5: Performance Optimization Validation
Create before/after comparison script:
cat > performance_comparison.sh << 'EOF'
#!/bin/bash

VM_NAME="performance-vm"
COMPARISON_DIR="/tmp/performance_comparison"

mkdir -p $COMPARISON_DIR

# Function to run quick performance test
run_quick_test() {
    local test_name=$1
    local output_file=$2
    
    echo "Running $test_name test..."
    
    # Quick CPU test
    echo "=== CPU Test ===" >> $output_file
    sysbench cpu --cpu-max-prime=10000 --threads=2 run | grep -E "(events per second|total time)" >> $output_file
    
    # Quick memory test
    echo "=== Memory Test ===" >> $output_file
    sysbench memory --memory-block-size=1K --memory-total-size=512M run | grep -E "(transferred|total time)" >> $output_file
    
    # VM resource usage
    echo "=== VM Resource Usage ===" >> $output_file
    sudo virsh domstats $VM_NAME >> $output_file
}

# Test with current configuration
echo "Testing current optimized configuration..."
run_quick_test "Optimized" "$COMPARISON_DIR/optimized_results.log"

echo "Performance comparison completed"
echo "Results saved in $COMPARISON_DIR"
EOF

chmod +x performance_comparison.sh
./performance_comparison.sh
Generate performance report:
cat > generate_report.sh << 'EOF'
#!/bin/bash

REPORT_FILE="/tmp/virtualization_performance_report.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

cat > $REPORT_FILE << EOL
=====================================
VIRTUALIZATION PERFORMANCE REPORT
=====================================
Generated: $TIMESTAMP

CONFIGURATION SUMMARY:
- VM Name: performance-vm
- vCPU Configuration: 4 vCPUs with host-passthrough
- Memory: 4GB with ballooning enabled
- CPU Pinning: Enabled
- Huge Pages: Configured
- NUMA Awareness: Enabled

PERFORMANCE OPTIMIZATIONS APPLIED:
1. vCPU Topology Optimization
   - Matched physical CPU architecture
   - Enabled CPU pinning for better cache locality
   - Used host-passthrough for maximum performance

2. Memory Optimization
   - Implemented memory ballooning
   - Configured huge pages
   - NUMA-aware memory allocation

3. Performance Monitoring
   - Real-time resource monitoring
   - Automated memory balancing
   - Comprehensive benchmarking

BENCHMARK RESULTS:
EOL

# Add latest benchmark results
if [ -d "/tmp/benchmark_results" ]; then
    echo "Latest benchmark summary:" >> $REPORT_FILE
    ./summarize_results.sh >> $REPORT_FILE 2>/dev/null
fi

echo "" >> $REPORT_FILE
echo "RECOMMENDATIONS:" >> $REPORT_FILE
echo "1. Monitor memory ballooning effectiveness regularly" >> $REPORT_FILE
echo "2. Adjust vCPU pinning based on workload characteristics" >> $REPORT_FILE
echo "3. Fine-tune memory allocation based on application requirements" >> $REPORT_FILE
echo "4. Consider workload-specific optimizations" >> $REPORT_FILE

echo "Performance report generated: $REPORT_FILE"
cat $REPORT_FILE
EOF

chmod +x generate_report.sh
./generate_report.sh
Troubleshooting Common Issues
Issue 1: Memory Ballooning Not Working
Symptoms: Memory allocation doesn't change dynamically

Solutions:

# Check if balloon driver is loaded in guest
lsmod | grep virtio_balloon

# Verify balloon device in VM configuration
sudo virsh dumpxml performance-vm | grep balloon

# Restart balloon service if needed
sudo systemctl restart libvirtd
Issue 2: Poor CPU Performance
Symptoms: High CPU wait times, poor benchmark scores

Solutions:

# Check CPU pinning
sudo virsh vcpuinfo performance-vm

# Verify CPU topology
sudo virsh capabilities | grep -A 10 topology

# Re-apply CPU optimizations
sudo virsh vcpupin performance-vm --vcpu 0 --cpulist 0
Issue 3: Memory Allocation Issues
Symptoms: VM cannot allocate requested memory

Solutions:

# Check host memory availability
free -h

# Verify huge pages configuration
cat /proc/meminfo | grep -i huge

# Reset memory configuration
sudo virsh setmaxmem performance-vm 4194304 --config
Conclusion
In this comprehensive lab, you have successfully:

Configured Advanced vCPU Settings: You learned to optimize virtual CPU allocation by implementing CPU pinning, topology matching, and host-passthrough configuration. These techniques ensure maximum CPU performance by reducing virtualization overhead and improving cache locality.

Implemented Memory Ballooning: You mastered dynamic memory management through memory ballooning, enabling efficient memory utilization across multiple virtual machines. This technology allows the hypervisor to reclaim unused memory from VMs and allocate it where needed most.

Conducted Performance Testing: You performed comprehensive performance benchmarking using industry-standard tools like sysbench, stress-ng, and custom monitoring scripts. This testing validated the effectiveness of your optimization strategies.

Applied Real-World Optimization Techniques: The configurations you implemented mirror production virtualization environments, including NUMA awareness, huge pages, and automated resource balancing.

Why This Matters: Virtualization performance tuning is critical in modern IT infrastructure where organizations run hundreds or thousands of virtual machines. The techniques you've learned can:

Reduce Infrastructure Costs: Better resource utilization means fewer physical servers needed
Improve Application Performance: Optimized VMs provide better response times and throughput
Enable Scalability: Efficient resource management supports growing workloads
Enhance Reliability: Proper resource allocation prevents performance bottlenecks
These skills are essential for roles in cloud computing, DevOps, and enterprise IT infrastructure, directly supporting Red Hat Performance Tuning certification objectives and real-world virtualization challenges.

The automated scripts and monitoring tools you've created can be adapted for production environments, providing ongoing performance optimization and alerting capabilities.
