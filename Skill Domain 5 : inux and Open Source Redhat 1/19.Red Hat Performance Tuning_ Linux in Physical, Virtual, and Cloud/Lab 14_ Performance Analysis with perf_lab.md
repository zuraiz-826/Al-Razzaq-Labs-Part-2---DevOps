Lab 14: Performance Analysis with perf
Objectives
By the end of this lab, students will be able to:

• Use the perf tool to analyze system performance metrics • Monitor and analyze CPU usage patterns for specific processes • Examine memory access patterns and identify performance bottlenecks • Analyze disk I/O operations and their impact on system performance • Interpret perf output data to make informed optimization decisions • Apply performance tuning techniques based on perf analysis results

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with process management concepts • Knowledge of system resources (CPU, memory, I/O) • Understanding of performance monitoring fundamentals • Access to a Linux system with root or sudo privileges

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your cloud machine comes pre-installed with: • perf tools package • Sample applications for testing • Monitoring utilities • Development tools

Task 1: CPU Performance Analysis with perf
Subtask 1.1: Install and Verify perf Tools
First, let's ensure perf is properly installed and functional on your system.

# Check if perf is installed
which perf

# If not installed, install perf tools
sudo apt update
sudo apt install linux-tools-common linux-tools-generic linux-tools-$(uname -r)

# Verify perf installation
perf --version
Subtask 1.2: Create a CPU-Intensive Test Program
Create a simple CPU-intensive program to analyze:

# Create a test directory
mkdir ~/perf-lab
cd ~/perf-lab

# Create a CPU-intensive C program
cat > cpu_intensive.c << 'EOF'
#include <stdio.h>
#include <unistd.h>

int main() {
    printf("Starting CPU-intensive task (PID: %d)\n", getpid());
    
    // CPU-intensive loop
    for (long i = 0; i < 1000000000; i++) {
        // Perform some calculations
        volatile double result = i * 3.14159 / 2.71828;
    }
    
    printf("CPU-intensive task completed\n");
    return 0;
}
EOF

# Compile the program
gcc -o cpu_intensive cpu_intensive.c
Subtask 1.3: Basic CPU Performance Monitoring
Run perf to monitor CPU usage of your test program:

# Run perf stat to get basic performance statistics
perf stat ./cpu_intensive

# Run perf stat with more detailed metrics
perf stat -e cycles,instructions,cache-references,cache-misses,branch-misses ./cpu_intensive
Expected Output Analysis: • cycles: Total CPU cycles consumed • instructions: Number of instructions executed • IPC (Instructions Per Cycle): Efficiency metric • cache-references/cache-misses: Memory access efficiency

Subtask 1.4: Advanced CPU Profiling
Perform detailed CPU profiling using perf record:

# Record CPU performance data
perf record -g ./cpu_intensive

# Analyze the recorded data
perf report

# Generate a detailed call graph
perf report --stdio > cpu_analysis.txt

# View the analysis file
less cpu_analysis.txt
Subtask 1.5: Real-time CPU Monitoring
Monitor CPU performance in real-time:

# Start the CPU-intensive program in background
./cpu_intensive &
CPU_PID=$!

# Monitor the specific process
perf top -p $CPU_PID

# Alternative: Monitor system-wide CPU usage
perf top

# Stop the background process
kill $CPU_PID
Task 2: Memory Access Pattern Analysis
Subtask 2.1: Create Memory-Intensive Test Program
Create a program that demonstrates different memory access patterns:

# Create memory-intensive test program
cat > memory_test.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define ARRAY_SIZE 10000000
#define ITERATIONS 100

int main() {
    printf("Starting memory access test (PID: %d)\n", getpid());
    
    // Allocate large array
    int *array = malloc(ARRAY_SIZE * sizeof(int));
    if (!array) {
        printf("Memory allocation failed\n");
        return 1;
    }
    
    // Sequential access pattern
    printf("Sequential access pattern...\n");
    for (int iter = 0; iter < ITERATIONS; iter++) {
        for (int i = 0; i < ARRAY_SIZE; i++) {
            array[i] = i * 2;
        }
    }
    
    // Random access pattern
    printf("Random access pattern...\n");
    for (int iter = 0; iter < ITERATIONS; iter++) {
        for (int i = 0; i < ARRAY_SIZE/10; i++) {
            int index = rand() % ARRAY_SIZE;
            array[index] = index * 3;
        }
    }
    
    free(array);
    printf("Memory test completed\n");
    return 0;
}
EOF

# Compile the memory test program
gcc -o memory_test memory_test.c
Subtask 2.2: Analyze Memory Performance
Use perf to analyze memory access patterns:

# Record memory-related events
perf record -e cache-misses,cache-references,page-faults ./memory_test

# Analyze memory performance
perf report --stdio > memory_analysis.txt

# View memory statistics
perf stat -e cache-misses,cache-references,LLC-loads,LLC-load-misses,page-faults ./memory_test
Subtask 2.3: Memory Bandwidth Analysis
Analyze memory bandwidth usage:

# Monitor memory bandwidth events
perf stat -e cpu/mem-loads/,cpu/mem-stores/ ./memory_test

# Record detailed memory access information
perf record -e cpu/mem-loads/,cpu/mem-stores/ -g ./memory_test

# Generate memory access report
perf report --stdio --sort=symbol,dso > memory_bandwidth.txt
Subtask 2.4: NUMA Memory Analysis
If your system supports NUMA, analyze NUMA memory access:

# Check NUMA topology
numactl --hardware

# Run memory test with NUMA monitoring
perf stat -e node-loads,node-load-misses,node-stores ./memory_test

# Analyze NUMA memory access patterns
perf record -e node-loads,node-stores ./memory_test
perf report --stdio > numa_analysis.txt
Task 3: Disk I/O Performance Analysis
Subtask 3.1: Create I/O-Intensive Test Program
Create a program that performs various I/O operations:

# Create I/O test program
cat > io_test.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#define BUFFER_SIZE 4096
#define NUM_FILES 100
#define WRITE_SIZE 1024*1024  // 1MB per file

int main() {
    printf("Starting I/O test (PID: %d)\n", getpid());
    
    char buffer[BUFFER_SIZE];
    char filename[256];
    
    // Fill buffer with test data
    memset(buffer, 'A', BUFFER_SIZE);
    
    // Sequential write test
    printf("Sequential write test...\n");
    for (int i = 0; i < NUM_FILES; i++) {
        sprintf(filename, "testfile_%d.dat", i);
        int fd = open(filename, O_CREAT | O_WRONLY | O_TRUNC, 0644);
        if (fd < 0) continue;
        
        for (int j = 0; j < WRITE_SIZE/BUFFER_SIZE; j++) {
            write(fd, buffer, BUFFER_SIZE);
        }
        close(fd);
    }
    
    // Sequential read test
    printf("Sequential read test...\n");
    for (int i = 0; i < NUM_FILES; i++) {
        sprintf(filename, "testfile_%d.dat", i);
        int fd = open(filename, O_RDONLY);
        if (fd < 0) continue;
        
        while (read(fd, buffer, BUFFER_SIZE) > 0) {
            // Process data
        }
        close(fd);
    }
    
    // Cleanup
    for (int i = 0; i < NUM_FILES; i++) {
        sprintf(filename, "testfile_%d.dat", i);
        unlink(filename);
    }
    
    printf("I/O test completed\n");
    return 0;
}
EOF

# Compile the I/O test program
gcc -o io_test io_test.c
Subtask 3.2: Monitor I/O Performance
Use perf to monitor I/O operations:

# Monitor basic I/O statistics
perf stat -e syscalls:sys_enter_read,syscalls:sys_enter_write,syscalls:sys_enter_open,syscalls:sys_enter_close ./io_test

# Record detailed I/O events
perf record -e syscalls:sys_enter_read,syscalls:sys_enter_write,syscalls:sys_enter_open ./io_test

# Analyze I/O patterns
perf report --stdio > io_analysis.txt
Subtask 3.3: Block I/O Analysis
Analyze block-level I/O operations:

# Monitor block I/O events (requires root privileges)
sudo perf record -e block:block_rq_issue,block:block_rq_complete ./io_test

# Analyze block I/O performance
sudo perf report --stdio > block_io_analysis.txt

# Monitor I/O wait time
perf stat -e sched:sched_stat_iowait ./io_test
Subtask 3.4: File System Performance
Analyze file system performance:

# Monitor file system operations
sudo perf record -e ext4:ext4_da_write_begin,ext4:ext4_da_write_end ./io_test

# Create a larger I/O test for better analysis
dd if=/dev/zero of=large_test_file bs=1M count=100

# Monitor the dd operation
perf stat -e block:block_rq_issue,block:block_rq_complete dd if=/dev/zero of=large_test_file2 bs=1M count=100

# Cleanup
rm -f large_test_file large_test_file2
Task 4: Comprehensive Performance Analysis and Optimization
Subtask 4.1: Create Multi-Resource Test Application
Create an application that uses CPU, memory, and I/O simultaneously:

# Create comprehensive test application
cat > comprehensive_test.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <fcntl.h>
#include <string.h>

#define ARRAY_SIZE 1000000
#define NUM_THREADS 4

void* cpu_worker(void* arg) {
    int thread_id = *(int*)arg;
    printf("CPU worker %d started\n", thread_id);
    
    for (long i = 0; i < 100000000; i++) {
        volatile double result = i * 3.14159 / 2.71828;
    }
    
    return NULL;
}

void* memory_worker(void* arg) {
    int thread_id = *(int*)arg;
    printf("Memory worker %d started\n", thread_id);
    
    int* array = malloc(ARRAY_SIZE * sizeof(int));
    for (int i = 0; i < 1000; i++) {
        for (int j = 0; j < ARRAY_SIZE; j++) {
            array[j] = j * i;
        }
    }
    free(array);
    
    return NULL;
}

void* io_worker(void* arg) {
    int thread_id = *(int*)arg;
    printf("I/O worker %d started\n", thread_id);
    
    char filename[256];
    char buffer[4096];
    sprintf(filename, "worker_%d.dat", thread_id);
    
    int fd = open(filename, O_CREAT | O_WRONLY | O_TRUNC, 0644);
    for (int i = 0; i < 1000; i++) {
        write(fd, buffer, sizeof(buffer));
    }
    close(fd);
    unlink(filename);
    
    return NULL;
}

int main() {
    printf("Starting comprehensive performance test (PID: %d)\n", getpid());
    
    pthread_t threads[NUM_THREADS * 3];
    int thread_ids[NUM_THREADS * 3];
    
    // Create CPU workers
    for (int i = 0; i < NUM_THREADS; i++) {
        thread_ids[i] = i;
        pthread_create(&threads[i], NULL, cpu_worker, &thread_ids[i]);
    }
    
    // Create memory workers
    for (int i = 0; i < NUM_THREADS; i++) {
        thread_ids[NUM_THREADS + i] = i;
        pthread_create(&threads[NUM_THREADS + i], NULL, memory_worker, &thread_ids[NUM_THREADS + i]);
    }
    
    // Create I/O workers
    for (int i = 0; i < NUM_THREADS; i++) {
        thread_ids[2 * NUM_THREADS + i] = i;
        pthread_create(&threads[2 * NUM_THREADS + i], NULL, io_worker, &thread_ids[2 * NUM_THREADS + i]);
    }
    
    // Wait for all threads to complete
    for (int i = 0; i < NUM_THREADS * 3; i++) {
        pthread_join(threads[i], NULL);
    }
    
    printf("Comprehensive test completed\n");
    return 0;
}
EOF

# Compile with pthread support
gcc -pthread -o comprehensive_test comprehensive_test.c
Subtask 4.2: Comprehensive Performance Profiling
Perform complete system profiling:

# Record comprehensive performance data
perf record -g -e cycles,cache-misses,page-faults,syscalls:sys_enter_write,syscalls:sys_enter_read ./comprehensive_test

# Generate detailed performance report
perf report --stdio > comprehensive_analysis.txt

# Analyze performance by function
perf report --sort=symbol --stdio > function_analysis.txt

# Generate flame graph data (if available)
perf script > perf_script_output.txt
Subtask 4.3: Performance Bottleneck Identification
Identify and analyze performance bottlenecks:

# Analyze top CPU consumers
perf report --sort=overhead --stdio | head -20 > top_cpu_consumers.txt

# Analyze cache performance
perf stat -e L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses ./comprehensive_test > cache_performance.txt

# Analyze context switches and scheduling
perf stat -e context-switches,cpu-migrations,sched:sched_switch ./comprehensive_test > scheduling_analysis.txt
Subtask 4.4: Performance Optimization Recommendations
Based on the analysis, create optimization recommendations:

# Create performance summary script
cat > analyze_performance.sh << 'EOF'
#!/bin/bash

echo "=== Performance Analysis Summary ==="
echo

echo "1. CPU Performance:"
echo "   - Check IPC (Instructions Per Cycle) ratio"
echo "   - Look for high cache miss rates"
echo "   - Identify CPU-bound functions"
echo

echo "2. Memory Performance:"
echo "   - Analyze cache miss patterns"
echo "   - Check for memory bandwidth limitations"
echo "   - Look for NUMA effects"
echo

echo "3. I/O Performance:"
echo "   - Monitor I/O wait times"
echo "   - Check for I/O bottlenecks"
echo "   - Analyze file system performance"
echo

echo "4. Optimization Recommendations:"
if [ -f comprehensive_analysis.txt ]; then
    echo "   Based on perf analysis:"
    grep -E "(overhead|symbol)" comprehensive_analysis.txt | head -10
fi

echo
echo "=== Key Metrics to Monitor ==="
echo "- CPU utilization and IPC"
echo "- Cache miss rates (L1, L2, LLC)"
echo "- Memory bandwidth usage"
echo "- I/O wait time and throughput"
echo "- Context switch frequency"
EOF

chmod +x analyze_performance.sh
./analyze_performance.sh
Interpreting perf Output and Performance Optimization
Understanding Key Metrics
CPU Metrics: • Cycles: Total CPU cycles consumed • Instructions: Number of instructions executed • IPC: Instructions per cycle (higher is better) • Cache-misses: Memory access inefficiencies

Memory Metrics: • Page-faults: Memory management overhead • Cache-references: Total cache accesses • LLC-loads: Last Level Cache loads • Node-loads: NUMA memory accesses

I/O Metrics: • Syscalls: System call frequency • Block operations: Disk I/O operations • I/O wait: Time spent waiting for I/O

Performance Optimization Strategies
CPU Optimization:

# Identify CPU hotspots
perf record -g --call-graph=dwarf ./your_program
perf report --sort=overhead

# Optimize based on findings:
# - Reduce function call overhead
# - Improve algorithm efficiency
# - Use compiler optimizations
Memory Optimization:

# Analyze memory access patterns
perf record -e cache-misses,cache-references ./your_program
perf report --sort=symbol

# Optimization strategies:
# - Improve data locality
# - Reduce memory allocations
# - Use memory pools
I/O Optimization:

# Monitor I/O patterns
perf record -e syscalls:sys_enter_read,syscalls:sys_enter_write ./your_program

# Optimization strategies:
# - Use larger buffer sizes
# - Implement asynchronous I/O
# - Reduce system call frequency
Troubleshooting Common Issues
Permission Issues
# If you get permission denied errors
echo 0 | sudo tee /proc/sys/kernel/perf_event_paranoid

# Or run with sudo for system-wide profiling
sudo perf record -a -g ./your_program
Missing Events
# Check available events
perf list

# Use alternative events if specific ones aren't available
perf stat -e cpu-cycles,instructions ./your_program
Large Data Files
# Limit recording time
perf record -g --duration=10 ./your_program

# Compress perf data
perf record -g -z ./your_program
Conclusion
In this lab, you have successfully:

• Mastered perf fundamentals by learning to install, configure, and use the perf performance analysis tool • Analyzed CPU performance by monitoring cycles, instructions, cache behavior, and identifying CPU-intensive code sections • Examined memory access patterns by studying cache performance, memory bandwidth, and NUMA effects on application performance • Monitored I/O operations by tracking system calls, block I/O operations, and file system performance metrics • Interpreted complex performance data by analyzing perf output to identify bottlenecks and optimization opportunities • Applied optimization strategies based on performance analysis results to improve application efficiency

Why This Matters:

Performance analysis with perf is crucial for: • System optimization in production environments • Application tuning for better resource utilization • Capacity planning and scalability assessment • Troubleshooting performance issues in complex systems • Cost optimization in cloud environments where performance directly impacts costs

The skills you've developed in this lab are essential for system administrators, performance engineers, and developers working with high-performance Linux systems. Understanding how to use perf effectively enables you to make data-driven decisions about system optimization and ensures optimal performance in enterprise environments.

Next Steps: • Practice with real-world applications in your environment • Explore advanced perf features like custom events and scripting • Integrate perf analysis into your regular system monitoring workflow • Study performance optimization techniques specific to your application domain
