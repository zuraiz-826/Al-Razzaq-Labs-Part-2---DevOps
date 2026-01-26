Lab 18: SystemTap for Kernel Performance Analysis
Objectives
By the end of this lab, you will be able to:

Install and configure SystemTap on a Linux system
Write SystemTap scripts to trace I/O operations and system calls
Monitor kernel events and analyze system performance bottlenecks
Create custom probes for application and kernel debugging
Interpret SystemTap output to identify performance issues
Use SystemTap for real-time system monitoring and troubleshooting
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and shell scripting
Knowledge of system calls and kernel concepts
Understanding of I/O operations and file systems
Basic knowledge of performance monitoring concepts
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
SystemTap pre-installed with necessary kernel debugging symbols
Sample applications for testing
Performance monitoring tools
Task 1: SystemTap Installation and Setup
Subtask 1.1: Verify SystemTap Installation
First, let's verify that SystemTap is properly installed and configured on your system.

Check SystemTap installation:
# Check if SystemTap is installed
rpm -qa | grep systemtap

# Check SystemTap version
stap --version
Verify kernel debugging symbols:
# Check if kernel debuginfo is available
ls /usr/lib/debug/lib/modules/$(uname -r)/

# Verify SystemTap can access kernel symbols
stap -e 'probe begin { println("SystemTap is working!"); exit() }'
Subtask 1.2: Install Additional Components (if needed)
If SystemTap is not fully configured, install the required packages:

# Install SystemTap and related packages
sudo dnf install -y systemtap systemtap-runtime

# Install kernel debugging symbols
sudo dnf install -y kernel-debuginfo kernel-debuginfo-common-$(uname -m)

# Install development tools
sudo dnf install -y kernel-devel gcc
Subtask 1.3: Test Basic SystemTap Functionality
Create and run a simple SystemTap script to ensure everything is working:

# Create a simple test script
cat > hello_systemtap.stp << 'EOF'
#!/usr/bin/env stap

probe begin {
    println("Hello from SystemTap!")
    println("Kernel version: ", kernel_v)
    println("Current time: ", ctime(gettimeofday_s()))
}

probe end {
    println("SystemTap script finished")
}

probe timer.s(5) {
    println("Timer fired - SystemTap is monitoring")
    exit()
}
EOF

# Run the test script
sudo stap hello_systemtap.stp
Task 2: Writing SystemTap Scripts for I/O Operations Tracing
Subtask 2.1: Create Basic I/O Monitoring Script
Let's create a SystemTap script to monitor file I/O operations:

# Create I/O monitoring script
cat > io_monitor.stp << 'EOF'
#!/usr/bin/env stap

# Global variables to store statistics
global read_bytes, write_bytes, read_count, write_count
global file_operations

probe syscall.read {
    if (target() == 0 || target() == pid()) {
        read_count[execname()]++
    }
}

probe syscall.read.return {
    if (target() == 0 || target() == pid()) {
        if ($return > 0) {
            read_bytes[execname()] += $return
        }
    }
}

probe syscall.write {
    if (target() == 0 || target() == pid()) {
        write_count[execname()]++
    }
}

probe syscall.write.return {
    if (target() == 0 || target() == pid()) {
        if ($return > 0) {
            write_bytes[execname()] += $return
        }
    }
}

probe syscall.open {
    if (target() == 0 || target() == pid()) {
        file_operations[execname(), user_string($filename)]++
        printf("OPEN: %s opened %s\n", execname(), user_string($filename))
    }
}

probe timer.s(10) {
    printf("\n=== I/O Statistics (10 second interval) ===\n")
    printf("%-15s %10s %15s %10s %15s\n", 
           "PROCESS", "READS", "READ_BYTES", "WRITES", "WRITE_BYTES")
    
    foreach ([proc] in read_count) {
        printf("%-15s %10d %15d %10d %15d\n",
               proc, read_count[proc], read_bytes[proc],
               write_count[proc], write_bytes[proc])
    }
    
    printf("\n=== File Operations ===\n")
    foreach ([proc, file] in file_operations) {
        printf("%s: %s (%d times)\n", proc, file, file_operations[proc, file])
    }
    
    delete read_bytes
    delete write_bytes
    delete read_count
    delete write_count
    delete file_operations
}

probe end {
    printf("\nI/O monitoring completed\n")
}
EOF

# Make the script executable
chmod +x io_monitor.stp
Subtask 2.2: Create Advanced I/O Latency Tracking Script
Now let's create a more advanced script that tracks I/O latency:

# Create I/O latency tracking script
cat > io_latency.stp << 'EOF'
#!/usr/bin/env stap

global io_start_time, io_latency
global read_latencies, write_latencies

# Track read system call start time
probe syscall.read {
    if (target() == 0 || target() == pid()) {
        io_start_time[tid(), "read"] = gettimeofday_us()
    }
}

# Calculate read latency
probe syscall.read.return {
    if (target() == 0 || target() == pid()) {
        start_time = io_start_time[tid(), "read"]
        if (start_time) {
            latency = gettimeofday_us() - start_time
            read_latencies <<< latency
            delete io_start_time[tid(), "read"]
            
            if (latency > 1000) {  # Log slow reads (>1ms)
                printf("SLOW READ: %s pid=%d latency=%d us bytes=%d\n",
                       execname(), pid(), latency, $return)
            }
        }
    }
}

# Track write system call start time
probe syscall.write {
    if (target() == 0 || target() == pid()) {
        io_start_time[tid(), "write"] = gettimeofday_us()
    }
}

# Calculate write latency
probe syscall.write.return {
    if (target() == 0 || target() == pid()) {
        start_time = io_start_time[tid(), "write"]
        if (start_time) {
            latency = gettimeofday_us() - start_time
            write_latencies <<< latency
            delete io_start_time[tid(), "write"]
            
            if (latency > 1000) {  # Log slow writes (>1ms)
                printf("SLOW WRITE: %s pid=%d latency=%d us bytes=%d\n",
                       execname(), pid(), latency, $return)
            }
        }
    }
}

# Print statistics every 15 seconds
probe timer.s(15) {
    printf("\n=== I/O Latency Statistics ===\n")
    printf("Read Operations:\n")
    if (@count(read_latencies) > 0) {
        printf("  Count: %d\n", @count(read_latencies))
        printf("  Average: %d us\n", @avg(read_latencies))
        printf("  Min: %d us\n", @min(read_latencies))
        printf("  Max: %d us\n", @max(read_latencies))
        print("  Histogram:")
        print(@hist_log(read_latencies))
    }
    
    printf("\nWrite Operations:\n")
    if (@count(write_latencies) > 0) {
        printf("  Count: %d\n", @count(write_latencies))
        printf("  Average: %d us\n", @avg(write_latencies))
        printf("  Min: %d us\n", @min(write_latencies))
        printf("  Max: %d us\n", @max(write_latencies))
        print("  Histogram:")
        print(@hist_log(write_latencies))
    }
    
    delete read_latencies
    delete write_latencies
}

probe end {
    printf("\nI/O latency monitoring completed\n")
}
EOF

# Make the script executable
chmod +x io_latency.stp
Subtask 2.3: Test I/O Monitoring Scripts
Let's test our I/O monitoring scripts with some file operations:

Start the I/O monitor in one terminal:
# Run the basic I/O monitor
sudo stap io_monitor.stp
In another terminal, generate some I/O activity:
# Create test files and perform I/O operations
dd if=/dev/zero of=/tmp/testfile bs=1M count=100
cp /tmp/testfile /tmp/testfile_copy
find /usr -name "*.conf" -type f | head -20 | xargs cat > /tmp/config_dump
rm /tmp/testfile /tmp/testfile_copy /tmp/config_dump
Test the latency monitoring script:
# Run the I/O latency monitor
sudo stap io_latency.stp
Task 3: System Call Tracing and Analysis
Subtask 3.1: Create Comprehensive System Call Tracer
Let's create a script to trace and analyze system calls:

# Create system call tracer
cat > syscall_tracer.stp << 'EOF'
#!/usr/bin/env stap

global syscall_count, syscall_time, syscall_errors
global process_syscalls, start_times

# Trace all system calls
probe syscall.* {
    if (target() == 0 || target() == pid()) {
        syscall_count[name]++
        process_syscalls[execname(), name]++
        start_times[tid(), name] = gettimeofday_us()
    }
}

# Track system call completion and errors
probe syscall.*.return {
    if (target() == 0 || target() == pid()) {
        start_time = start_times[tid(), name]
        if (start_time) {
            duration = gettimeofday_us() - start_time
            syscall_time[name] += duration
            delete start_times[tid(), name]
            
            # Track errors
            if ($return < 0) {
                syscall_errors[name]++
                printf("ERROR: %s in %s (pid=%d) returned %d\n",
                       name, execname(), pid(), $return)
            }
            
            # Log slow system calls (>10ms)
            if (duration > 10000) {
                printf("SLOW SYSCALL: %s in %s took %d us\n",
                       name, execname(), duration)
            }
        }
    }
}

# Print statistics every 20 seconds
probe timer.s(20) {
    printf("\n=== System Call Statistics ===\n")
    printf("%-20s %10s %15s %10s %15s\n",
           "SYSCALL", "COUNT", "TOTAL_TIME_US", "ERRORS", "AVG_TIME_US")
    
    foreach (syscall in syscall_count- limit 20) {
        avg_time = (syscall_count[syscall] > 0) ? 
                   syscall_time[syscall] / syscall_count[syscall] : 0
        printf("%-20s %10d %15d %10d %15d\n",
               syscall, syscall_count[syscall], syscall_time[syscall],
               syscall_errors[syscall], avg_time)
    }
    
    printf("\n=== Top Processes by System Call Activity ===\n")
    foreach ([proc, syscall] in process_syscalls- limit 15) {
        printf("%s: %s (%d calls)\n", proc, syscall, process_syscalls[proc, syscall])
    }
    
    # Reset counters
    delete syscall_count
    delete syscall_time
    delete syscall_errors
    delete process_syscalls
}

probe end {
    printf("\nSystem call tracing completed\n")
}
EOF

# Make the script executable
chmod +x syscall_tracer.stp
Subtask 3.2: Create Process-Specific System Call Monitor
Create a script to monitor system calls for specific processes:

# Create process-specific monitor
cat > process_monitor.stp << 'EOF'
#!/usr/bin/env stap

global target_processes, monitored_pids
global syscall_stats, file_access, network_activity

# Define processes to monitor (can be modified)
probe begin {
    target_processes["httpd"] = 1
    target_processes["nginx"] = 1
    target_processes["mysql"] = 1
    target_processes["postgres"] = 1
    target_processes["sshd"] = 1
    printf("Monitoring system calls for specific processes...\n")
}

function is_target_process() {
    return (execname() in target_processes)
}

# Monitor file operations
probe syscall.open, syscall.openat {
    if (is_target_process()) {
        filename = user_string($filename)
        file_access[execname(), filename]++
        printf("FILE_OPEN: %s (pid=%d) opened %s\n", 
               execname(), pid(), filename)
    }
}

# Monitor network operations
probe syscall.socket {
    if (is_target_process()) {
        network_activity[execname(), "socket"]++
        printf("NETWORK: %s (pid=%d) created socket (family=%d, type=%d)\n",
               execname(), pid(), $family, $type)
    }
}

probe syscall.connect {
    if (is_target_process()) {
        network_activity[execname(), "connect"]++
        printf("NETWORK: %s (pid=%d) attempting connection\n",
               execname(), pid())
    }
}

probe syscall.bind {
    if (is_target_process()) {
        network_activity[execname(), "bind"]++
        printf("NETWORK: %s (pid=%d) binding socket\n",
               execname(), pid())
    }
}

# Monitor memory operations
probe syscall.mmap {
    if (is_target_process()) {
        syscall_stats[execname(), "mmap"]++
        if ($length > 1048576) {  # Log large allocations (>1MB)
            printf("MEMORY: %s (pid=%d) large mmap %d bytes\n",
                   execname(), pid(), $length)
        }
    }
}

probe syscall.brk {
    if (is_target_process()) {
        syscall_stats[execname(), "brk"]++
    }
}

# Print summary every 30 seconds
probe timer.s(30) {
    printf("\n=== Process-Specific Monitoring Summary ===\n")
    
    printf("\nFile Access Summary:\n")
    foreach ([proc, file] in file_access) {
        printf("  %s accessed %s (%d times)\n", proc, file, file_access[proc, file])
    }
    
    printf("\nNetwork Activity Summary:\n")
    foreach ([proc, activity] in network_activity) {
        printf("  %s: %s operations (%d times)\n", proc, activity, network_activity[proc, activity])
    }
    
    printf("\nSystem Call Summary:\n")
    foreach ([proc, syscall] in syscall_stats) {
        printf("  %s: %s (%d times)\n", proc, syscall, syscall_stats[proc, syscall])
    }
    
    # Clear statistics
    delete file_access
    delete network_activity
    delete syscall_stats
}

probe end {
    printf("\nProcess monitoring completed\n")
}
EOF

# Make the script executable
chmod +x process_monitor.stp
Subtask 3.3: Test System Call Monitoring
Let's test our system call monitoring scripts:

Run the comprehensive system call tracer:
# Start the system call tracer
sudo stap syscall_tracer.stp
In another terminal, generate system call activity:
# Generate various system calls
ls -la /etc/
find /var/log -name "*.log" | head -10
ps aux | grep systemd
netstat -tuln
df -h
Test process-specific monitoring:
# Start the process monitor
sudo stap process_monitor.stp

# In another terminal, start some services or processes
sudo systemctl status sshd
curl -I http://localhost
Task 4: Performance Analysis During I/O Bottlenecks
Subtask 4.1: Create I/O Bottleneck Detection Script
Let's create a script specifically designed to detect and analyze I/O bottlenecks:

# Create I/O bottleneck detector
cat > io_bottleneck_detector.stp << 'EOF'
#!/usr/bin/env stap

global io_queue_depth, io_wait_times, blocked_processes
global disk_utilization, slow_io_operations
global process_io_stats

# Track I/O queue depth and wait times
probe ioblock.request {
    io_queue_depth[devname]++
    io_wait_times[tid()] = gettimeofday_us()
}

probe ioblock.end {
    io_queue_depth[devname]--
    
    start_time = io_wait_times[tid()]
    if (start_time) {
        wait_time = gettimeofday_us() - start_time
        delete io_wait_times[tid()]
        
        # Track slow I/O operations (>50ms)
        if (wait_time > 50000) {
            slow_io_operations[devname]++
            printf("SLOW I/O: Device %s, wait time %d us, size %d bytes\n",
                   devname, wait_time, size)
        }
        
        disk_utilization[devname] += wait_time
    }
}

# Track processes waiting for I/O
probe scheduler.wakeup {
    if (task_state == 2) {  # TASK_UNINTERRUPTIBLE (waiting for I/O)
        blocked_processes[task_execname(task)]++
    }
}

# Monitor file system operations that might cause bottlenecks
probe vfs.read {
    process_io_stats[execname(), "read"]++
    if (size > 1048576) {  # Large reads (>1MB)
        printf("LARGE READ: %s reading %d bytes from %s\n",
               execname(), size, file_name)
    }
}

probe vfs.write {
    process_io_stats[execname(), "write"]++
    if (size > 1048576) {  # Large writes (>1MB)
        printf("LARGE WRITE: %s writing %d bytes to %s\n",
               execname(), size, file_name)
    }
}

# Check for I/O bottlenecks every 15 seconds
probe timer.s(15) {
    printf("\n=== I/O Bottleneck Analysis ===\n")
    printf("Timestamp: %s\n", ctime(gettimeofday_s()))
    
    printf("\nDisk Queue Depths:\n")
    foreach (device in io_queue_depth) {
        if (io_queue_depth[device] > 10) {
            printf("  WARNING: %s has high queue depth: %d\n",
                   device, io_queue_depth[device])
        } else {
            printf("  %s: %d\n", device, io_queue_depth[device])
        }
    }
    
    printf("\nSlow I/O Operations:\n")
    foreach (device in slow_io_operations) {
        printf("  %s: %d slow operations\n", device, slow_io_operations[device])
    }
    
    printf("\nProcesses Blocked on I/O:\n")
    foreach (process in blocked_processes) {
        if (blocked_processes[process] > 5) {
            printf("  WARNING: %s blocked %d times\n", process, blocked_processes[process])
        } else {
            printf("  %s: %d times\n", process, blocked_processes[process])
        }
    }
    
    printf("\nTop I/O Intensive Processes:\n")
    foreach ([proc, op] in process_io_stats- limit 10) {
        printf("  %s: %s operations (%d)\n", proc, op, process_io_stats[proc, op])
    }
    
    # Reset counters
    delete slow_io_operations
    delete blocked_processes
    delete process_io_stats
}

probe end {
    printf("\nI/O bottleneck detection completed\n")
}
EOF

# Make the script executable
chmod +x io_bottleneck_detector.stp
Subtask 4.2: Create Memory and CPU Performance Monitor
Create a script to monitor memory and CPU performance alongside I/O:

# Create comprehensive performance monitor
cat > performance_monitor.stp << 'EOF'
#!/usr/bin/env stap

global cpu_usage, memory_usage, context_switches
global page_faults, memory_allocations
global process_cpu_time, process_memory

# Track CPU usage
probe timer.profile {
    cpu_usage[cpu()]++
    process_cpu_time[execname()]++
}

# Track context switches
probe scheduler.ctxswitch {
    context_switches++
    if (prev_priority < 0 || next_priority < 0) {
        printf("HIGH PRIORITY SWITCH: %s -> %s\n", 
               prev_task_name, next_task_name)
    }
}

# Track memory operations
probe vm.pagefault {
    page_faults[execname()]++
    if (write_access) {
        printf("PAGE FAULT (WRITE): %s at address 0x%x\n", execname(), address)
    }
}

probe syscall.mmap.return {
    if ($return > 0) {
        memory_allocations[execname()] += $length
        if ($length > 10485760) {  # Log large allocations (>10MB)
            printf("LARGE ALLOCATION: %s allocated %d bytes\n", 
                   execname(), $length)
        }
    }
}

# Monitor system load
probe timer.s(10) {
    printf("\n=== System Performance Monitor ===\n")
    printf("Timestamp: %s\n", ctime(gettimeofday_s()))
    
    # CPU usage per core
    printf("\nCPU Usage by Core:\n")
    total_samples = 0
    foreach (core in cpu_usage) {
        total_samples += cpu_usage[core]
    }
    
    foreach (core in cpu_usage) {
        usage_percent = (cpu_usage[core] * 100) / total_samples
        printf("  CPU %d: %d%% (%d samples)\n", core, usage_percent, cpu_usage[core])
    }
    
    # Context switches
    printf("\nContext Switches: %d (last 10 seconds)\n", context_switches)
    if (context_switches > 10000) {
        printf("  WARNING: High context switch rate detected!\n")
    }
    
    # Top CPU consuming processes
    printf("\nTop CPU Consuming Processes:\n")
    foreach (proc in process_cpu_time- limit 10) {
        printf("  %s: %d samples\n", proc, process_cpu_time[proc])
    }
    
    # Page faults by process
    printf("\nPage Faults by Process:\n")
    foreach (proc in page_faults- limit 10) {
        if (page_faults[proc] > 100) {
            printf("  WARNING: %s has %d page faults\n", proc, page_faults[proc])
        } else {
            printf("  %s: %d page faults\n", proc, page_faults[proc])
        }
    }
    
    # Memory allocations
    printf("\nMemory Allocations:\n")
    foreach (proc in memory_allocations- limit 10) {
        mb_allocated = memory_allocations[proc] / 1048576
        printf("  %s: %d MB allocated\n", proc, mb_allocated)
    }
    
    # Reset counters
    delete cpu_usage
    delete process_cpu_time
    delete page_faults
    delete memory_allocations
    context_switches = 0
}

probe end {
    printf("\nPerformance monitoring completed\n")
}
EOF

# Make the script executable
chmod +x performance_monitor.stp
Subtask 4.3: Create I/O Bottleneck Simulation and Analysis
Let's create a test scenario to simulate I/O bottlenecks and analyze them:

Create a script to simulate I/O load:
# Create I/O load generator
cat > generate_io_load.sh << 'EOF'
#!/bin/bash

echo "Generating I/O load for testing..."

# Create multiple processes doing I/O
for i in {1..5}; do
    (
        echo "Starting I/O worker $i"
        # Generate random I/O
        dd if=/dev/urandom of=/tmp/iotest_$i bs=1M count=50 2>/dev/null &
        
        # Simulate database-like random access
        for j in {1..100}; do
            dd if=/tmp/iotest_$i of=/dev/null bs=4k skip=$((RANDOM % 1000)) count=1 2>/dev/null
            sleep 0.1
        done
        
        rm -f /tmp/iotest_$i
    ) &
done

# Generate file system stress
find /usr -type f -name "*.so" | head -50 | xargs -I {} cp {} /tmp/ 2>/dev/null &

# Wait for all background jobs
wait

echo "I/O load generation completed"
EOF

chmod +x generate_io_load.sh
Run bottleneck detection during I/O stress:
# Start the I/O bottleneck detector
sudo stap io_bottleneck_detector.stp &
STAP_PID=$!

# Wait a moment for SystemTap to initialize
sleep 5

# Generate I/O load
./generate_io_load.sh

# Let the monitoring run for a while
sleep 30

# Stop SystemTap
sudo kill $STAP_PID
Run comprehensive performance monitoring:
# Start performance monitor
sudo stap performance_monitor.stp &
PERF_PID=$!

# Generate mixed load (CPU + I/O + Memory)
(
    # CPU load
    yes > /dev/null &
    CPU_PID=$!
    
    # Memory load
    python3 -c "
import time
data = []
for i in range(1000):
    data.append('x' * 1024 * 1024)  # 1MB chunks
    time.sleep(0.01)
" &
    MEM_PID=$!
    
    # I/O load
    ./generate_io_load.sh &
    IO_PID=$!
    
    # Let it run for 60 seconds
    sleep 60
    
    # Clean up
    kill $CPU_PID $MEM_PID $IO_PID 2>/dev/null
) &

# Wait for the test to complete
wait

# Stop performance monitor
sudo kill $PERF_PID
Task 5: Advanced SystemTap Techniques
Subtask 5.1: Create Custom Kernel Event Tracer
Let's create an advanced script that traces custom kernel events:

# Create advanced kernel event tracer
cat > kernel_event_tracer.stp << 'EOF'
#!/usr/bin/env stap

global kernel_events, interrupt_stats, lock_contention
global memory_events, network_events

# Track kernel function calls
probe kernel.function("do_fork") {
    kernel_events["process_creation"]++
    printf("PROCESS_CREATION: %s (pid=%d) forking\n", execname(), pid())
}

probe kernel.function("do_exit") {
    kernel_events["process_exit"]++
    printf("PROCESS_EXIT: %s (pid=%d) exiting with code %d\n", 
           execname(), pid(), $code)
}

# Track interrupt handling
probe kernel.function("handle_irq_event") {
    interrupt_stats[irq]++
    if (irq == 0) {  # Timer interrupt
        kernel_events["timer_interrupt"]++
    }
}

# Track memory management events
probe kernel.function("__alloc_pages_nodemask") {
    memory_events["page_allocation"]++
    if ($gfp_mask & 0x10) {  # GFP_ATOMIC
        printf("ATOMIC_ALLOCATION: %s requesting %d pages\n", 
               execname(), 1 << $order)
    }
}

probe kernel.function("free_pages") {
    memory_events["page_free"]++
}

# Track network events
probe kernel.function("netif_rx") {
    network_events["packet_receive"]++
}

probe kernel.function("dev_queue_xmit") {
    network_events["packet_transmit"]++
}

# Track lock contention (simplified)
probe kernel.function("_raw_spin_lock") {
    lock_contention["spin_lock"]++
}

probe kernel.function("mutex_lock") {
    lock_contention["mutex_lock"]++
}

# Print kernel event statistics
probe timer.s(20) {
    printf("\n=== Kernel Event Analysis ===\n")
    printf("Timestamp: %s\n", ctime(gettimeofday_s()))
    
    printf("\nKernel Events:\n")
    foreach (event in kernel_events) {
        printf("  %s: %d\n", event, kernel_events[event])
    }
    
    printf("\nInterrupt Statistics:\n")
    foreach (irq in interrupt_stats- limit 10) {
        printf("  IRQ %d: %d interrupts\n", irq, interrupt_stats[irq])
    }
    
    printf("\nMemory Events:\n")
    foreach (event in memory_events) {
        printf("  %s: %d\n", event, memory_events[event])
    }
    
    printf("\nNetwork Events:\n")
    foreach (event in network_events) {
        printf("  %s: %d\n", event, network_events[event])
    }
    
    printf("\nLock Contention:\n")
    foreach (lock in lock_contention) {
        if (lock_contention[lock] > 1000) {
            printf("  WARNING: High contention on %s: %d\n", 
                   lock, lock_contention[lock])
        } else {
            printf("  %s: %d\n", lock, lock_contention[lock])
        }
    }
    
    # Reset counters
    delete kernel_events
    delete interrupt_stats
    delete memory_events
    delete network_events
    delete lock_contention
}

probe end {
    printf("\nKernel event tracing completed\n")
}
EOF

# Make the script executable
chmod +x kernel_event_tracer.stp
Subtask 5.2: Create Real-time Performance Dashboard
