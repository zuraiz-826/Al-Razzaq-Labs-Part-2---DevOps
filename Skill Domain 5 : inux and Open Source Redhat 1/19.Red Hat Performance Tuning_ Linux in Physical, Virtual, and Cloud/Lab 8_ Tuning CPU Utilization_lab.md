Lab 8: Tuning CPU Utilization
Objectives
By the end of this lab, students will be able to:

Understand CPU scheduling concepts and parameters in Linux systems
Modify CPU scheduler parameters using sysctl to optimize system performance
Configure CPU affinity for processes to improve resource utilization
Monitor and analyze CPU utilization metrics effectively
Apply performance tuning techniques to optimize CPU-bound workloads
Troubleshoot common CPU performance issues in production environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line interface
Familiarity with process management concepts (ps, top, htop)
Knowledge of system administration fundamentals
Understanding of CPU architecture basics (cores, threads, scheduling)
Experience with text editors (vi/vim or nano)
Root or sudo access to perform system-level changes
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8+ or Ubuntu 20.04+ system
Multi-core CPU (minimum 4 cores recommended)
Administrative privileges
Pre-installed monitoring tools
Task 1: Understanding and Adjusting CPU Scheduler Parameters
Subtask 1.1: Examine Current CPU Scheduler Configuration
First, let's explore the current CPU scheduler settings and understand the baseline configuration.

Check current scheduler policy:
cat /sys/block/sda/queue/scheduler
View current CPU scheduler parameters:
sysctl -a | grep sched | head -20
Display detailed scheduler statistics:
cat /proc/schedstat
Check CPU information:
lscpu
cat /proc/cpuinfo | grep processor | wc -l
Subtask 1.2: Monitor Baseline CPU Performance
Before making changes, establish baseline performance metrics.

Install monitoring tools (if not already available):
# For RHEL/CentOS
sudo yum install -y htop stress-ng sysstat

# For Ubuntu/Debian
sudo apt update && sudo apt install -y htop stress-ng sysstat
Start system monitoring:
# Open a new terminal window and run:
htop

# In another terminal, start iostat:
iostat -x 1
Create a CPU stress test script:
cat > cpu_stress_test.sh << 'EOF'
#!/bin/bash
echo "Starting CPU stress test..."
echo "Cores available: $(nproc)"
echo "Starting stress test on all cores for 30 seconds"
stress-ng --cpu $(nproc) --timeout 30s --metrics-brief
EOF

chmod +x cpu_stress_test.sh
Run baseline test:
./cpu_stress_test.sh
Subtask 1.3: Adjust CPU Scheduler Parameters
Now we'll modify key scheduler parameters to optimize performance.

View current scheduler tunables:
sysctl kernel.sched_min_granularity_ns
sysctl kernel.sched_wakeup_granularity_ns
sysctl kernel.sched_migration_cost_ns
sysctl kernel.sched_latency_ns
Create a backup of current settings:
sysctl -a | grep sched > /tmp/original_sched_settings.txt
Adjust scheduler parameters for better throughput:
# Reduce minimum granularity for better responsiveness
sudo sysctl kernel.sched_min_granularity_ns=1000000

# Adjust wakeup granularity
sudo sysctl kernel.sched_wakeup_granularity_ns=2000000

# Reduce migration cost for better load balancing
sudo sysctl kernel.sched_migration_cost_ns=250000

# Adjust scheduling latency
sudo sysctl kernel.sched_latency_ns=6000000
Make changes persistent:
sudo tee -a /etc/sysctl.conf << 'EOF'
# CPU Scheduler Optimizations
kernel.sched_min_granularity_ns=1000000
kernel.sched_wakeup_granularity_ns=2000000
kernel.sched_migration_cost_ns=250000
kernel.sched_latency_ns=6000000
EOF
Verify changes:
sysctl kernel.sched_min_granularity_ns
sysctl kernel.sched_wakeup_granularity_ns
sysctl kernel.sched_migration_cost_ns
sysctl kernel.sched_latency_ns
Subtask 1.4: Test Performance After Scheduler Tuning
Run the stress test again:
./cpu_stress_test.sh
Compare performance metrics:
# Monitor context switches
vmstat 1 10

# Check load average
uptime
Task 2: Setting CPU Affinity for Process Optimization
Subtask 2.1: Understanding CPU Affinity Concepts
CPU affinity allows binding processes to specific CPU cores, reducing cache misses and improving performance.

Check current CPU topology:
lscpu -e
numactl --hardware
View current process affinity:
# Check affinity of current shell
taskset -p $$

# Check affinity of init process
taskset -p 1
Subtask 2.2: Create Test Workloads
Let's create different types of workloads to demonstrate CPU affinity benefits.

Create a CPU-intensive calculation script:
cat > cpu_intensive.py << 'EOF'
#!/usr/bin/env python3
import time
import sys
import os

def cpu_intensive_task(duration=30):
    """CPU-intensive calculation task"""
    print(f"PID: {os.getpid()}")
    print(f"Running CPU-intensive task for {duration} seconds")
    
    start_time = time.time()
    counter = 0
    
    while time.time() - start_time < duration:
        # Perform CPU-intensive calculations
        for i in range(10000):
            counter += i ** 2
        
        if int(time.time() - start_time) % 5 == 0:
            elapsed = int(time.time() - start_time)
            if elapsed > 0:
                print(f"Elapsed: {elapsed}s, Counter: {counter}")
                time.sleep(0.1)  # Brief pause to see output
    
    print(f"Task completed. Final counter: {counter}")

if __name__ == "__main__":
    duration = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    cpu_intensive_task(duration)
EOF

chmod +x cpu_intensive.py
Create a memory-intensive script:
cat > memory_intensive.py << 'EOF'
#!/usr/bin/env python3
import time
import sys
import os

def memory_intensive_task(duration=30):
    """Memory-intensive task with frequent allocations"""
    print(f"PID: {os.getpid()}")
    print(f"Running memory-intensive task for {duration} seconds")
    
    start_time = time.time()
    data_arrays = []
    
    while time.time() - start_time < duration:
        # Create and manipulate large arrays
        array = list(range(100000))
        array.sort(reverse=True)
        data_arrays.append(array[:1000])  # Keep some data
        
        # Cleanup periodically
        if len(data_arrays) > 50:
            data_arrays = data_arrays[-25:]
        
        if int(time.time() - start_time) % 5 == 0:
            elapsed = int(time.time() - start_time)
            if elapsed > 0:
                print(f"Elapsed: {elapsed}s, Arrays: {len(data_arrays)}")
                time.sleep(0.1)
    
    print(f"Task completed. Final arrays: {len(data_arrays)}")

if __name__ == "__main__":
    duration = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    memory_intensive_task(duration)
EOF

chmod +x memory_intensive.py
Subtask 2.3: Test Default CPU Affinity Behavior
Run multiple processes without affinity control:
# Start multiple CPU-intensive processes
python3 cpu_intensive.py 60 &
PID1=$!
python3 cpu_intensive.py 60 &
PID2=$!
python3 memory_intensive.py 60 &
PID3=$!

echo "Started processes: $PID1, $PID2, $PID3"
Monitor CPU usage across cores:
# In a separate terminal
htop
# Press 'F2' -> Display options -> Detailed CPU time to see per-core usage
Check process affinity:
taskset -p $PID1
taskset -p $PID2
taskset -p $PID3
Wait for processes to complete:
wait $PID1 $PID2 $PID3
echo "All processes completed"
Subtask 2.4: Implement CPU Affinity Optimization
Now let's optimize performance by setting CPU affinity strategically.

Create an affinity management script:
cat > manage_affinity.sh << 'EOF'
#!/bin/bash

# Function to display CPU topology
show_topology() {
    echo "=== CPU Topology ==="
    lscpu | grep -E "(CPU\(s\)|Thread|Core|Socket)"
    echo ""
}

# Function to start process with specific affinity
start_with_affinity() {
    local script=$1
    local cores=$2
    local duration=$3
    
    echo "Starting $script on cores $cores for ${duration}s"
    taskset -c $cores python3 $script $duration &
    local pid=$!
    echo "PID: $pid, Affinity: $cores"
    return $pid
}

# Function to monitor process affinity
monitor_affinity() {
    local pid=$1
    echo "Process $pid affinity: $(taskset -p $pid 2>/dev/null | cut -d: -f2)"
}

show_topology

# Get number of CPUs
NCPUS=$(nproc)
echo "Available CPUs: $NCPUS"

if [ $NCPUS -ge 4 ]; then
    echo "Optimal configuration for 4+ cores"
    CORE_SET1="0,1"
    CORE_SET2="2,3"
    CORE_SET3="0-3"
else
    echo "Configuration for fewer cores"
    CORE_SET1="0"
    CORE_SET2="1"
    CORE_SET3="0,1"
fi

echo "Core assignments:"
echo "  CPU-intensive task 1: $CORE_SET1"
echo "  CPU-intensive task 2: $CORE_SET2"
echo "  Memory-intensive task: $CORE_SET3"
echo ""
EOF

chmod +x manage_affinity.sh
Run optimized workload with CPU affinity:
# Source the script to use its functions
source manage_affinity.sh

# Start processes with specific CPU affinity
echo "=== Starting Optimized Workload ==="
taskset -c 0,1 python3 cpu_intensive.py 60 &
PID1=$!
echo "CPU-intensive task 1 (PID: $PID1) bound to cores 0,1"

taskset -c 2,3 python3 cpu_intensive.py 60 &
PID2=$!
echo "CPU-intensive task 2 (PID: $PID2) bound to cores 2,3"

taskset -c 0-3 python3 memory_intensive.py 60 &
PID3=$!
echo "Memory-intensive task (PID: $PID3) can use all cores"

# Verify affinity settings
echo ""
echo "=== Verifying Affinity Settings ==="
taskset -p $PID1
taskset -p $PID2
taskset -p $PID3
Monitor performance with affinity:
# Create a monitoring script
cat > monitor_performance.sh << 'EOF'
#!/bin/bash
echo "=== Performance Monitoring ==="
echo "Time: $(date)"
echo ""

echo "Load Average:"
uptime
echo ""

echo "Per-CPU Usage:"
mpstat -P ALL 1 1
echo ""

echo "Context Switches:"
vmstat 1 2 | tail -1
echo ""

echo "Memory Usage:"
free -h
echo ""
EOF

chmod +x monitor_performance.sh

# Run monitoring every 10 seconds
for i in {1..6}; do
    echo "=== Monitoring Round $i ==="
    ./monitor_performance.sh
    sleep 10
done
Wait for completion and analyze results:
wait $PID1 $PID2 $PID3
echo "All optimized processes completed"
Subtask 2.5: Advanced CPU Affinity Techniques
Dynamic affinity adjustment:
cat > dynamic_affinity.sh << 'EOF'
#!/bin/bash

# Start a long-running process
python3 cpu_intensive.py 120 &
PID=$!
echo "Started process PID: $PID"

# Initial affinity - single core
echo "Setting initial affinity to core 0"
taskset -cp 0 $PID
sleep 20

# Expand to two cores
echo "Expanding affinity to cores 0,1"
taskset -cp 0,1 $PID
sleep 20

# Move to different cores
echo "Moving to cores 2,3"
taskset -cp 2,3 $PID
sleep 20

# Allow all cores
echo "Allowing all cores"
taskset -cp 0-3 $PID
sleep 20

# Back to single core
echo "Restricting to core 1"
taskset -cp 1 $PID

wait $PID
echo "Dynamic affinity test completed"
EOF

chmod +x dynamic_affinity.sh
Run the dynamic affinity test:
./dynamic_affinity.sh
Task 3: Testing CPU Utilization and Optimization
Subtask 3.1: Comprehensive Performance Testing Framework
Create a comprehensive testing script:
cat > cpu_performance_test.sh << 'EOF'
#!/bin/bash

# Performance testing framework
LOG_FILE="cpu_performance_results.log"
TEST_DURATION=30

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a $LOG_FILE
}

run_baseline_test() {
    log_message "=== BASELINE TEST ==="
    log_message "System Information:"
    lscpu | grep -E "(Model name|CPU\(s\)|Thread|Core|Socket)" | tee -a $LOG_FILE
    
    log_message "Starting baseline CPU stress test"
    stress-ng --cpu $(nproc) --timeout ${TEST_DURATION}s --metrics-brief 2>&1 | tee -a $LOG_FILE
}

run_affinity_test() {
    log_message "=== AFFINITY OPTIMIZATION TEST ==="
    
    # Test 1: All processes on all cores (default)
    log_message "Test 1: Default affinity (all cores)"
    python3 cpu_intensive.py $TEST_DURATION &
    python3 cpu_intensive.py $TEST_DURATION &
    python3 memory_intensive.py $TEST_DURATION &
    wait
    
    sleep 5
    
    # Test 2: Optimized affinity
    log_message "Test 2: Optimized affinity"
    taskset -c 0,1 python3 cpu_intensive.py $TEST_DURATION &
    taskset -c 2,3 python3 cpu_intensive.py $TEST_DURATION &
    taskset -c 0-3 python3 memory_intensive.py $TEST_DURATION &
    wait
}

run_scheduler_test() {
    log_message "=== SCHEDULER OPTIMIZATION TEST ==="
    
    # Create mixed workload
    log_message "Running mixed workload with optimized scheduler"
    
    for i in {1..4}; do
        taskset -c $((i-1)) python3 cpu_intensive.py $TEST_DURATION &
    done
    
    wait
}

monitor_system_metrics() {
    log_message "=== SYSTEM METRICS COLLECTION ==="
    
    # Collect various metrics
    log_message "Load Average: $(uptime)"
    log_message "Memory Usage: $(free -h | grep Mem)"
    log_message "Context Switches: $(vmstat 1 2 | tail -1 | awk '{print $12}')"
    log_message "CPU Utilization: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"
}

# Main execution
log_message "Starting comprehensive CPU performance testing"
log_message "Test duration per scenario: ${TEST_DURATION} seconds"

run_baseline_test
sleep 10

run_affinity_test
sleep 10

run_scheduler_test
sleep 10

monitor_system_metrics

log_message "Performance testing completed. Results saved to $LOG_FILE"
EOF

chmod +x cpu_performance_test.sh
Execute comprehensive performance test:
./cpu_performance_test.sh
Subtask 3.2: Real-World Application Optimization
Create a web server simulation:
cat > web_server_sim.py << 'EOF'
#!/usr/bin/env python3
import time
import threading
import random
import os
import sys

class WebServerSimulator:
    def __init__(self, num_workers=4, duration=60):
        self.num_workers = num_workers
        self.duration = duration
        self.request_count = 0
        self.start_time = time.time()
        
    def process_request(self, worker_id):
        """Simulate processing a web request"""
        # Simulate CPU-intensive operations (parsing, computation)
        calculation_result = 0
        for i in range(random.randint(10000, 50000)):
            calculation_result += i ** 0.5
        
        # Simulate I/O operations (database queries, file access)
        time.sleep(random.uniform(0.001, 0.01))
        
        return calculation_result
    
    def worker_thread(self, worker_id):
        """Worker thread that processes requests"""
        local_count = 0
        print(f"Worker {worker_id} (PID: {os.getpid()}, TID: {threading.get_ident()}) started")
        
        while time.time() - self.start_time < self.duration:
            self.process_request(worker_id)
            local_count += 1
            self.request_count += 1
            
            if local_count % 100 == 0:
                elapsed = time.time() - self.start_time
                print(f"Worker {worker_id}: {local_count} requests, {elapsed:.1f}s elapsed")
        
        print(f"Worker {worker_id} completed {local_count} requests")
    
    def run(self):
        """Start the web server simulation"""
        print(f"Starting web server simulation with {self.num_workers} workers")
        print(f"Duration: {self.duration} seconds")
        
        threads = []
        for i in range(self.num_workers):
            thread = threading.Thread(target=self.worker_thread, args=(i,))
            threads.append(thread)
            thread.start()
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        
        total_time = time.time() - self.start_time
        print(f"\nSimulation completed:")
        print(f"Total requests processed: {self.request_count}")
        print(f"Total time: {total_time:.2f} seconds")
        print(f"Requests per second: {self.request_count / total_time:.2f}")

if __name__ == "__main__":
    workers = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    duration = int(sys.argv[2]) if len(sys.argv) > 2 else 60
    
    simulator = WebServerSimulator(workers, duration)
    simulator.run()
EOF

chmod +x web_server_sim.py
Test web server performance with different configurations:
# Test 1: Default configuration
echo "=== Test 1: Default Configuration ==="
python3 web_server_sim.py 4 30

sleep 5

# Test 2: With CPU affinity
echo "=== Test 2: With CPU Affinity ==="
taskset -c 0-3 python3 web_server_sim.py 4 30

sleep 5

# Test 3: Optimized for specific cores
echo "=== Test 3: Optimized Core Assignment ==="
taskset -c 0,2 python3 web_server_sim.py 4 30
Subtask 3.3: Performance Analysis and Optimization
Create performance analysis script:
cat > analyze_performance.sh << 'EOF'
#!/bin/bash

RESULTS_FILE="performance_analysis.txt"

analyze_cpu_usage() {
    echo "=== CPU Usage Analysis ===" >> $RESULTS_FILE
    echo "Date: $(date)" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
    
    # Current CPU utilization
    echo "Current CPU Utilization:" >> $RESULTS_FILE
    top -bn1 | grep "Cpu(s)" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
    
    # Load average trends
    echo "Load Average:" >> $RESULTS_FILE
    uptime >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
    
    # Per-CPU statistics
    echo "Per-CPU Statistics:" >> $RESULTS_FILE
    mpstat -P ALL 1 1 >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
}

analyze_scheduler_performance() {
    echo "=== Scheduler Performance ===" >> $RESULTS_FILE
    
    # Context switches
    echo "Context Switches per second:" >> $RESULTS_FILE
    vmstat 1 5 | tail -1 | awk '{print "Context switches: " $12}' >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
    
    # Run queue length
    echo "Run Queue Statistics:" >> $RESULTS_FILE
    vmstat 1 5 | tail -1 | awk '{print "Processes waiting: " $1}' >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
}

generate_recommendations() {
    echo "=== Performance Recommendations ===" >> $RESULTS_FILE
    
    NCPUS=$(nproc)
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    echo "System Configuration:" >> $RESULTS_FILE
    echo "  CPU Cores: $NCPUS" >> $RESULTS_FILE
    echo "  Current Load: $LOAD_AVG" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
    
    echo "Recommendations:" >> $RESULTS_FILE
    
    # Load-based recommendations
    if (( $(echo "$LOAD_AVG > $NCPUS" | bc -l) )); then
        echo "  - System is overloaded (load > cores)" >> $RESULTS_FILE
        echo "  - Consider reducing concurrent processes" >> $RESULTS_FILE
        echo "  - Implement CPU affinity to reduce context switching" >> $RESULTS_FILE
    else
        echo "  - System load is acceptable" >> $RESULTS_FILE
        echo "  - Consider CPU affinity for CPU-intensive applications" >> $RESULTS_FILE
    fi
    
    echo "  - Monitor context switches - high values indicate scheduling overhead" >> $RESULTS_FILE
    echo "  - Use CPU affinity for processes with specific performance requirements" >> $RESULTS_FILE
    echo "  - Consider NUMA topology for multi-socket systems" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
}

# Main analysis
echo "Performing performance analysis..."
analyze_cpu_usage
analyze_scheduler_performance
generate_recommendations

echo "Analysis complete. Results saved to $RESULTS_FILE"
cat $RESULTS_FILE
EOF

chmod +x analyze_performance.sh
Run performance analysis:
./analyze_performance.sh
Subtask 3.4: Create Optimization Profiles
Create system optimization profiles:
cat > optimization_profiles.sh << 'EOF'
#!/bin/bash

# CPU Optimization Profiles

apply_throughput_profile() {
    echo "Applying THROUGHPUT optimization profile..."
    
    # Scheduler optimizations for throughput
    sudo sysctl kernel.sched_min_granularity_ns=10000000
    sudo sysctl kernel.sched_wakeup_granularity_ns=15000000
    sudo sysctl kernel.sched_migration_cost_ns=5000000
    sudo sysctl kernel.sched_latency_ns=24000000
    
    echo "Throughput profile applied"
}

apply_latency_profile() {
    echo "Applying LATENCY optimization profile..."
    
    # Scheduler optimizations for low latency
    sudo sysctl kernel.sched_min_granularity_ns=1000000
    sudo sysctl kernel.sched_wakeup_granularity_ns=2000000
    sudo sysctl kernel.sched_migration_cost_ns=250000
    sudo sysctl kernel.sched_latency_ns=6000000
    
    echo "Latency profile applied"
}

apply_balanced_profile() {
    echo "Applying BALANCED optimization profile..."
    
    # Balanced scheduler settings
    sudo sysctl kernel.sched_min_granularity_ns=3000000
    sudo sysctl kernel.sched_wakeup_granularity_ns=4000000
    sudo sysctl kernel.sched_migration_cost_ns=500000
    sudo sysctl kernel.sched_latency_ns=12000000
    
    echo "Balanced profile applied"
}

show_current_profile() {
    echo "Current scheduler settings:"
    echo "  sched_min_granularity_ns: $(sysctl -n kernel.sched_min_granularity_ns)"
    echo "  sched_wakeup_granularity_ns: $(sysctl -n kernel.sched_wakeup_granularity_ns)"
    echo "  sched_migration_cost_ns: $(sysctl -n kernel.sched_migration_cost_ns)"
    echo "  sched_latency_ns: $(sysctl -n kernel.sched_latency_ns)"
}

case "$1" in
    throughput)
        apply_throughput_profile
        ;;
    latency)
        apply_latency_profile
        ;;
    balanced)
        apply_balanced_profile
        ;;
    show)
        show_current_profile
        ;;
    *)
        echo "Usage: $0 {throughput|latency|balanced|show}"
        echo ""
        echo "Profiles:"
        echo "  throughput - Optimize for maximum throughput"
        echo "  latency    - Optimize for low latency"
        echo "  balanced   - Balanced performance"
        echo "  show       - Show current settings"
        exit 1
        ;;
esac
EOF

chmod +x optimization_profiles.sh
Test different optimization profiles:
# Show current settings
./optimization_profiles.sh show

# Test latency profile
echo "Testing latency profile..."
./optimization_profiles.sh latency
python3 cpu_intensive.py 20

# Test throughput profile
echo "Testing throughput profile..."
./optimization_profiles.sh throughput
python3 cpu_intensive.py 20

# Apply balanced profile
echo "Applying balanced profile..."
./optimization_profiles.sh balanced
Troubleshooting Common Issues
Issue 1: Permission Denied When Modifying sysctl Parameters
Problem: Cannot modify kernel parameters due to insufficient privileges.

Solution:

# Ensure you have sudo privileges
sudo -v

# If still having issues, check if the parameter is read-only
ls -la /proc/sys/kernel/sched_*

# Some parameters may require specific kernel versions
uname -r
Issue 2: CPU Affinity Not Working as Expected
Problem: Process affinity settings don't seem to take effect.

Solution:

# Verify the process is still running
ps aux | grep python3

# Check if the process has child threads
ps -eLf | grep python3

# Use cpuset for more persistent affinity
sudo mkdir -p /sys/fs/cgroup/cpuset/myapp
echo "0,1" | sudo tee /sys/fs/cgroup/cpuset/myapp/cpuset.cpus
echo $PID | sudo tee /sys/fs/cgroup/cpuset/myapp/tasks
Issue 3: High Context Switching
Problem: System shows excessive context switches affecting performance.

Solution:

# Monitor context switches
vmstat 1 10

# Check for processes causing high context switches
pidstat -w 1 5

# Adjust scheduler parameters to reduce context switching
sudo sysctl kernel.sched_migration_cost_ns=5000000
Issue 4: Inconsistent Performance Results
Problem: Performance tests show inconsistent results.

Solution:

# Ensure system is idle before testing
top -bn1 | head -20

# Disable CPU frequency scaling for consistent results
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Clear system caches
sudo sync && sudo echo 3 > /proc/sys/vm/drop_caches
Conclusion
In this comprehensive lab, you have successfully learned and implemented advanced CPU utilization tuning techniques. Here's what you accomplished:

Key Achievements
CPU Scheduler Optimization: You modified critical kernel scheduler parameters using sysctl to optimize system performance for different workload types, learning how parameters like sched_min_granularity_ns and sched_migration_cost_ns affect system behavior.

CPU Affinity Management: You implemented CPU affinity strategies to bind processes to specific CPU cores, reducing cache misses and improving performance for CPU-intensive applications.

Performance Testing and Analysis: You created comprehensive testing frameworks to measure the impact of your optimizations, learning to use tools like stress-ng, htop, and vmstat for performance monitoring.

Real-World Application: You applied these concepts to practical scenarios like web server optimization, demonstrating how CPU tuning translates to improved application performance.

Why This Matters
CPU utilization tuning is crucial in production environments because:

Performance Optimization: Proper CPU scheduling and affinity can improve application response times by 20-40%
Resource Efficiency: Better CPU utilization means more work done with the same hardware resources
Cost Reduction: Optimized systems require fewer servers to handle the same workload
User Experience: Lower latency and higher throughput directly improve end-user experience
Next Steps
To continue building on this knowledge:

Explore NUMA Optimization: Learn about Non-Uniform Memory Access optimization for multi-socket systems
Container CPU Management: Apply these concepts to containerized environments using cgroups
Real-Time Systems: Study real-time scheduling for time-critical applications
Advanced Monitoring: Implement comprehensive monitoring solutions using tools like Prometheus and Grafana
The skills you've developed in this lab are directly applicable to Red Hat Performance Tuning certification objectives and are essential for system administrators managing high-performance Linux systems in production environments.
