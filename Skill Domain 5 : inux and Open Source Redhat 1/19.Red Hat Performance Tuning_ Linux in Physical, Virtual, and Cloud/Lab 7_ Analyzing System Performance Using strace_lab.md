Lab 7: Analyzing System Performance Using strace
Objectives
By the end of this lab, you will be able to:

• Use strace to trace system calls and signals of running processes • Analyze how applications interact with the Linux kernel • Identify performance bottlenecks related to system calls • Interpret strace output to diagnose system-level issues • Apply performance tuning techniques based on system call analysis

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Linux command line operations • Familiarity with process management concepts • Knowledge of file system operations • Understanding of basic system administration tasks • Experience with text editors like vi or nano

Lab Environment Setup
Al Nafi Cloud Machines: This lab uses Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your pre-configured environment. No need to build your own VM or install additional software.

Your cloud machine comes with: • CentOS/RHEL 8 or Ubuntu 20.04 LTS • strace utility pre-installed • Sample applications for testing • Administrative privileges

Task 1: Trace System Calls of a Running Process
Subtask 1.1: Understanding strace Basics
First, let's understand what strace does and verify it's available on your system.

Check if strace is installed:
which strace
strace --version
View the strace manual to understand its options:
man strace
Create a simple test program to trace:
cat > simple_program.c << 'EOF'
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

int main() {
    printf("Starting simple program...\n");
    
    // Open a file
    int fd = open("/etc/passwd", O_RDONLY);
    if (fd != -1) {
        char buffer[100];
        read(fd, buffer, sizeof(buffer));
        close(fd);
        printf("File operation completed\n");
    }
    
    // Sleep for demonstration
    sleep(2);
    
    printf("Program finished\n");
    return 0;
}
EOF
Compile the test program:
gcc -o simple_program simple_program.c
Subtask 1.2: Basic System Call Tracing
Run strace on the simple program:
strace ./simple_program
Expected Output Analysis:

execve(): Program execution
open(): File opening operations
read(): Reading file contents
write(): Output to stdout
close(): Closing file descriptors
nanosleep(): Sleep implementation
Save strace output to a file for analysis:
strace -o trace_output.txt ./simple_program
Examine the trace file:
cat trace_output.txt
Subtask 1.3: Tracing Running Processes
Start a long-running process in the background:
ping google.com > /dev/null &
PING_PID=$!
echo "Ping process PID: $PING_PID"
Attach strace to the running process:
strace -p $PING_PID
Note: Press Ctrl+C to stop tracing after observing the system calls.

Trace with timestamps:
strace -t -p $PING_PID
Stop the ping process:
kill $PING_PID
Task 2: Analyze How Applications Interact with the Kernel
Subtask 2.1: Detailed System Call Analysis
Create a more complex test application:
cat > file_operations.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <string.h>

int main() {
    char filename[] = "test_file.txt";
    char data[] = "Hello, World! This is test data.\n";
    char buffer[1024];
    int fd;
    struct stat file_stat;
    
    printf("Creating and writing to file...\n");
    
    // Create and write to file
    fd = open(filename, O_CREAT | O_WRONLY | O_TRUNC, 0644);
    if (fd == -1) {
        perror("open");
        exit(1);
    }
    
    write(fd, data, strlen(data));
    close(fd);
    
    // Read from file
    printf("Reading from file...\n");
    fd = open(filename, O_RDONLY);
    if (fd == -1) {
        perror("open");
        exit(1);
    }
    
    ssize_t bytes_read = read(fd, buffer, sizeof(buffer));
    close(fd);
    
    // Get file statistics
    if (stat(filename, &file_stat) == 0) {
        printf("File size: %ld bytes\n", file_stat.st_size);
    }
    
    // Clean up
    unlink(filename);
    
    printf("Operations completed\n");
    return 0;
}
EOF
Compile the program:
gcc -o file_operations file_operations.c
Trace with detailed output:
strace -v -s 100 ./file_operations
Key System Calls to Observe:

openat(): Modern file opening
write(): Data writing to file
read(): Data reading from file
fstat(): File status information
unlink(): File deletion
Subtask 2.2: Filtering and Focusing on Specific System Calls
Trace only file-related system calls:
strace -e trace=file ./file_operations
Trace only network-related system calls (using ping):
strace -e trace=network ping -c 3 google.com
Trace memory-related system calls:
strace -e trace=memory ./file_operations
Count system calls:
strace -c ./file_operations
Subtask 2.3: Advanced Tracing Techniques
Create a script that demonstrates various system interactions:
cat > system_interaction.sh << 'EOF'
#!/bin/bash

echo "Starting system interaction demo..."

# File operations
echo "Performing file operations..."
ls -la /etc > file_list.txt
grep "passwd" file_list.txt > passwd_info.txt

# Network operations
echo "Testing network connectivity..."
ping -c 2 8.8.8.8 > /dev/null

# Process operations
echo "Checking processes..."
ps aux | head -5 > process_info.txt

# Memory information
echo "Checking memory..."
free -h > memory_info.txt

echo "Demo completed"

# Cleanup
rm -f file_list.txt passwd_info.txt process_info.txt memory_info.txt
EOF
Make the script executable:
chmod +x system_interaction.sh
Trace the script execution:
strace -f -o script_trace.txt ./system_interaction.sh
Analyze the trace output:
grep -E "(open|read|write|execve)" script_trace.txt | head -20
Task 3: Identify Performance Issues Related to System Calls
Subtask 3.1: Creating Performance Test Cases
Create a program with potential performance issues:
cat > performance_test.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

void inefficient_file_operations() {
    char filename[] = "perf_test.txt";
    int fd;
    char data[] = "X";
    
    printf("Starting inefficient file operations...\n");
    
    // Inefficient: Opening and closing file multiple times
    for (int i = 0; i < 1000; i++) {
        fd = open(filename, O_CREAT | O_WRONLY | O_APPEND, 0644);
        if (fd != -1) {
            write(fd, data, 1);
            close(fd);
        }
    }
    
    unlink(filename);
    printf("Inefficient operations completed\n");
}

void efficient_file_operations() {
    char filename[] = "perf_test_efficient.txt";
    int fd;
    char data[1000];
    
    printf("Starting efficient file operations...\n");
    
    // Efficient: Open once, write all data, close once
    memset(data, 'X', sizeof(data));
    fd = open(filename, O_CREAT | O_WRONLY | O_TRUNC, 0644);
    if (fd != -1) {
        write(fd, data, sizeof(data));
        close(fd);
    }
    
    unlink(filename);
    printf("Efficient operations completed\n");
}

int main() {
    printf("=== Performance Comparison ===\n");
    
    printf("\n1. Running inefficient version:\n");
    inefficient_file_operations();
    
    printf("\n2. Running efficient version:\n");
    efficient_file_operations();
    
    return 0;
}
EOF
Compile the performance test:
gcc -o performance_test performance_test.c
Subtask 3.2: Measuring System Call Performance
Trace the inefficient version with timing:
strace -c -o inefficient_trace.txt ./performance_test 2>&1 | grep "inefficient" -A 10
View the system call summary:
cat inefficient_trace.txt
Trace with detailed timing information:
strace -T -o detailed_trace.txt ./performance_test
Analyze the timing data:
grep -E "(open|write|close)" detailed_trace.txt | head -10
Subtask 3.3: Identifying Common Performance Issues
Create a script to analyze common performance problems:
cat > analyze_performance.sh << 'EOF'
#!/bin/bash

echo "=== System Call Performance Analysis ==="

# Function to analyze strace output
analyze_trace() {
    local trace_file=$1
    echo "Analyzing: $trace_file"
    echo "----------------------------------------"
    
    # Count system calls
    echo "Top 10 most frequent system calls:"
    grep -E "^[0-9]+" $trace_file | awk '{print $2}' | cut -d'(' -f1 | sort | uniq -c | sort -nr | head -10
    
    echo ""
    echo "File operations count:"
    grep -E "(open|read|write|close)" $trace_file | wc -l
    
    echo ""
    echo "Potential issues:"
    
    # Check for excessive file operations
    open_count=$(grep -c "open(" $trace_file)
    if [ $open_count -gt 100 ]; then
        echo "- WARNING: High number of open() calls ($open_count)"
    fi
    
    # Check for failed system calls
    failed_calls=$(grep -c "= -1" $trace_file)
    if [ $failed_calls -gt 0 ]; then
        echo "- WARNING: $failed_calls failed system calls detected"
    fi
    
    echo "----------------------------------------"
}

# Run performance test and analyze
echo "Running performance test with strace..."
strace -c -o perf_summary.txt ./performance_test

echo ""
echo "System call summary:"
cat perf_summary.txt

# Create detailed trace
strace -o detailed_perf.txt ./performance_test

# Analyze the trace
analyze_trace detailed_perf.txt
EOF
Make the analysis script executable:
chmod +x analyze_performance.sh
Run the performance analysis:
./analyze_performance.sh
Subtask 3.4: Real-World Performance Monitoring
Monitor a system service (example with sshd):
# Find sshd process ID
pgrep sshd | head -1
Create a monitoring script:
cat > monitor_service.sh << 'EOF'
#!/bin/bash

SERVICE_NAME=${1:-"httpd"}
DURATION=${2:-30}

echo "Monitoring $SERVICE_NAME for $DURATION seconds..."

# Find the service PID
PID=$(pgrep $SERVICE_NAME | head -1)

if [ -z "$PID" ]; then
    echo "Service $SERVICE_NAME not found. Starting a test process..."
    # Start a simple HTTP server for demonstration
    python3 -m http.server 8080 &
    PID=$!
    echo "Started test HTTP server with PID: $PID"
    sleep 2
fi

echo "Tracing PID: $PID"

# Monitor for specified duration
timeout $DURATION strace -c -p $PID 2> service_trace.txt

echo "Monitoring completed. Results:"
cat service_trace.txt

# Cleanup if we started the test server
if [ "$SERVICE_NAME" = "httpd" ] && jobs %1 2>/dev/null; then
    kill $PID 2>/dev/null
fi
EOF
Make the monitoring script executable:
chmod +x monitor_service.sh
Run the service monitor:
./monitor_service.sh python3 10
Advanced Analysis Techniques
Filtering and Advanced Options
Create a comprehensive analysis script:
cat > advanced_strace_analysis.sh << 'EOF'
#!/bin/bash

echo "=== Advanced strace Analysis ==="

# Test program for analysis
cat > test_app.c << 'TESTEOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main() {
    pid_t pid = fork();
    
    if (pid == 0) {
        // Child process
        execl("/bin/ls", "ls", "-la", "/tmp", NULL);
    } else {
        // Parent process
        wait(NULL);
        printf("Child process completed\n");
    }
    
    return 0;
}
TESTEOF

gcc -o test_app test_app.c

echo "1. Basic trace with timestamps:"
strace -t ./test_app > basic_trace.out 2>&1

echo "2. Trace with relative timestamps:"
strace -r ./test_app > relative_trace.out 2>&1

echo "3. Trace following forks:"
strace -f ./test_app > fork_trace.out 2>&1

echo "4. Trace specific system call categories:"
strace -e trace=process ./test_app > process_trace.out 2>&1

echo "5. Statistical summary:"
strace -c ./test_app > stats_trace.out 2>&1

echo "Analysis complete. Check the generated .out files for results."

# Cleanup
rm -f test_app test_app.c
EOF
Run the advanced analysis:
chmod +x advanced_strace_analysis.sh
./advanced_strace_analysis.sh
Troubleshooting Common Issues
Issue 1: Permission Denied
If you encounter permission issues when tracing processes:

# Check if you have necessary permissions
id

# If needed, use sudo (in real environments, be cautious)
sudo strace -p <PID>
Issue 2: Process Not Found
# Verify process is running
ps aux | grep <process_name>

# Use pgrep for better process finding
pgrep -f <process_name>
Issue 3: Too Much Output
# Limit output with specific filters
strace -e trace=file,network <command>

# Use summary mode for overview
strace -c <command>
Performance Optimization Tips
Based on your strace analysis, consider these optimization strategies:

1. Reduce System Call Frequency
Problem: Too many open/close operations Solution: Keep files open longer, use buffering

2. Optimize I/O Operations
Problem: Many small read/write operations Solution: Use larger buffers, batch operations

3. Minimize Failed System Calls
Problem: High number of failed calls (ENOENT, EACCES) Solution: Check file existence, validate permissions first

4. Use Efficient System Calls
Problem: Using deprecated or inefficient calls Solution: Use modern alternatives (openat vs open, etc.)

Lab Summary and Cleanup
Clean up all test files:
rm -f simple_program simple_program.c
rm -f file_operations file_operations.c
rm -f performance_test performance_test.c
rm -f system_interaction.sh
rm -f *.txt *.out
rm -f analyze_performance.sh monitor_service.sh advanced_strace_analysis.sh
Verify cleanup:
ls -la | grep -E "\.(txt|out|c)$"
Conclusion
In this lab, you have successfully:

• Mastered strace fundamentals - You learned how to use strace to trace system calls and understand how applications interact with the Linux kernel

• Analyzed application behavior - You traced various types of programs and interpreted their system call patterns to understand their kernel interactions

• Identified performance bottlenecks - You created test cases that demonstrate common performance issues and learned to spot inefficient system call patterns

• Applied real-world monitoring - You developed skills to monitor running services and analyze their system-level performance

• Developed analysis techniques - You created scripts and methodologies for systematic performance analysis using strace

Why This Matters:

Understanding system calls is crucial for:

Performance tuning in production environments
Debugging application issues at the system level
Security analysis to understand application behavior
Capacity planning by identifying resource usage patterns
Red Hat Performance Tuning certification preparation
The skills you've developed in this lab are directly applicable to real-world system administration and performance engineering tasks, making you more effective at diagnosing and resolving system-level performance issues.
