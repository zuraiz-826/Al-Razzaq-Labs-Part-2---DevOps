Lab 4: Run Basic Shell Commands
Objectives
By the end of this lab, students will be able to:

• Understand and use the ps command to view running processes • Utilize the top command to monitor system processes in real-time • Effectively use the kill command to terminate processes • Identify process IDs (PIDs) and understand process hierarchy • Monitor system resource usage and process performance • Apply process management skills relevant to network automation environments

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Familiarity with terminal navigation • Knowledge of basic Linux file system structure • Understanding of what processes are in a Linux environment • Access to a Linux terminal or shell environment

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machine or install additional software.

Your cloud machine includes: • CentOS/RHEL-based Linux distribution • Pre-installed system utilities • Terminal access with sudo privileges • Sample processes for practice

Task 1: Understanding and Using the ps Command
Subtask 1.1: Basic Process Viewing
The ps command displays information about running processes. Let's start with basic usage.

Step 1: Open your terminal and run the basic ps command:

ps
Expected Output: You'll see a simple list showing: • PID (Process ID) • TTY (Terminal type) • TIME (CPU time used) • CMD (Command name)

Step 2: View all processes for the current user:

ps -u $USER
Step 3: Display all running processes on the system:

ps aux
This command shows: • a: All processes • u: User-oriented format • x: Include processes not attached to a terminal

Subtask 1.2: Advanced Process Information
Step 4: View processes in a tree format to see parent-child relationships:

ps auxf
Step 5: Display processes with full command lines:

ps -ef
Step 6: Find specific processes using grep:

ps aux | grep ssh
This searches for all SSH-related processes.

Subtask 1.3: Understanding Process Information
Step 7: Create a sample script to generate a process for practice:

# Create a simple background process
cat > /tmp/sample_process.sh << 'EOF'
#!/bin/bash
while true; do
    echo "Sample process running at $(date)" >> /tmp/sample_log.txt
    sleep 5
done
EOF

chmod +x /tmp/sample_process.sh
Step 8: Run the script in the background:

/tmp/sample_process.sh &
Step 9: Find your new process:

ps aux | grep sample_process
Note the PID (Process ID) for later use.

Task 2: Real-Time Process Monitoring with top
Subtask 2.1: Basic top Usage
Step 10: Launch the top command:

top
Key Information Displayed: • Load average: System load over 1, 5, and 15 minutes • Tasks: Total, running, sleeping, stopped, and zombie processes • CPU usage: User, system, idle percentages • Memory usage: Total, used, free, and cached memory

Subtask 2.2: Interactive top Commands
While top is running, try these interactive commands:

Step 11: Press the following keys to interact with top:

• q: Quit top • k: Kill a process (you'll be prompted for PID) • r: Renice a process (change priority) • P: Sort by CPU usage • M: Sort by memory usage • T: Sort by running time • u: Show processes for specific user

Step 12: Filter processes by user:

top -u $USER
Subtask 2.3: Alternative Process Monitors
Step 13: Try htop (if available) for a more user-friendly interface:

# Install htop if not available
sudo yum install htop -y  # For RHEL/CentOS
# or
sudo apt install htop -y  # For Ubuntu/Debian

# Run htop
htop
Step 14: Use the watch command to monitor processes:

watch -n 2 'ps aux | head -20'
This updates every 2 seconds showing the top 20 processes.

Task 3: Process Termination with kill Command
Subtask 3.1: Understanding kill Signals
Step 15: View available kill signals:

kill -l
Common Signals: • SIGTERM (15): Graceful termination (default) • SIGKILL (9): Force kill (cannot be ignored) • SIGHUP (1): Hang up signal • SIGSTOP (19): Stop process • SIGCONT (18): Continue stopped process

Subtask 3.2: Graceful Process Termination
Step 16: Find the PID of your sample process:

ps aux | grep sample_process | grep -v grep
Step 17: Terminate the process gracefully:

kill [PID]
Replace [PID] with the actual process ID from Step 16.

Step 18: Verify the process is terminated:

ps aux | grep sample_process | grep -v grep
Subtask 3.3: Force Killing Processes
Step 19: Create another background process:

/tmp/sample_process.sh &
Step 20: Force kill the process:

kill -9 [PID]
Step 21: Kill processes by name using pkill:

pkill -f sample_process
Subtask 3.4: Managing Multiple Processes
Step 22: Start multiple background processes:

for i in {1..3}; do
    /tmp/sample_process.sh &
    echo "Started process $i"
done
Step 23: View all sample processes:

pgrep -f sample_process
Step 24: Kill all sample processes at once:

pkill -f sample_process
Task 4: Advanced Process Management
Subtask 4.1: Process Priority Management
Step 25: Start a process with specific priority:

nice -n 10 /tmp/sample_process.sh &
Step 26: Change priority of running process:

# Find the PID first
PID=$(pgrep -f sample_process)
# Change priority (renice)
sudo renice -n 5 $PID
Subtask 4.2: Background and Foreground Jobs
Step 27: Start a process in foreground:

/tmp/sample_process.sh
Step 28: Suspend the process with Ctrl+Z, then:

# View jobs
jobs

# Send to background
bg %1

# Bring back to foreground
fg %1
Subtask 4.3: Process Monitoring Script
Step 29: Create a monitoring script:

cat > /tmp/process_monitor.sh << 'EOF'
#!/bin/bash

echo "=== Process Monitoring Report ==="
echo "Date: $(date)"
echo ""

echo "=== Top 5 CPU Consuming Processes ==="
ps aux --sort=-%cpu | head -6

echo ""
echo "=== Top 5 Memory Consuming Processes ==="
ps aux --sort=-%mem | head -6

echo ""
echo "=== System Load ==="
uptime

echo ""
echo "=== Memory Usage ==="
free -h
EOF

chmod +x /tmp/process_monitor.sh
Step 30: Run the monitoring script:

/tmp/process_monitor.sh
Troubleshooting Common Issues
Issue 1: Permission Denied When Killing Processes
Problem: Cannot kill processes owned by other users Solution: Use sudo for system processes:

sudo kill [PID]
Issue 2: Process Won't Terminate
Problem: Process ignores SIGTERM signal Solution: Use SIGKILL:

kill -9 [PID]
Issue 3: Finding Processes by Name
Problem: Difficulty locating specific processes Solution: Use multiple search methods:

# Method 1: ps with grep
ps aux | grep process_name

# Method 2: pgrep
pgrep process_name

# Method 3: pidof
pidof process_name
Issue 4: Monitoring High Resource Usage
Problem: System running slowly Solution: Identify resource-heavy processes:

# Sort by CPU usage
ps aux --sort=-%cpu | head -10

# Sort by memory usage
ps aux --sort=-%mem | head -10
Verification and Testing
Test 1: Process Management Skills
Step 31: Complete this verification checklist:

# 1. List all processes
ps aux

# 2. Find a specific process
ps aux | grep bash

# 3. Monitor processes in real-time
top
# (Press 'q' to quit)

# 4. Create and kill a test process
sleep 300 &
SLEEP_PID=$!
kill $SLEEP_PID
Test 2: Advanced Commands
Step 32: Execute these advanced commands:

# View process tree
pstree

# Show processes with threads
ps -eLf

# Monitor specific user processes
watch -n 1 "ps -u $USER"
Lab Cleanup
Step 33: Clean up created files and processes:

# Kill any remaining sample processes
pkill -f sample_process

# Remove created files
rm -f /tmp/sample_process.sh
rm -f /tmp/process_monitor.sh
rm -f /tmp/sample_log.txt

# Verify cleanup
ps aux | grep sample_process
Conclusion
In this lab, you have successfully learned to:

• Master the ps command for viewing and analyzing running processes with various options and filters • Utilize top for real-time monitoring of system processes, CPU usage, and memory consumption • Effectively terminate processes using kill command with different signals for graceful and forced termination • Understand process hierarchy and parent-child relationships in Linux systems • Monitor system performance and identify resource-intensive processes • Apply process management techniques essential for system administration and automation tasks

These skills are fundamental for Red Hat Certified Specialist in Ansible Network Automation, as managing processes is crucial when: • Running automation scripts and playbooks • Monitoring network automation tasks • Troubleshooting hung or problematic automation processes • Managing system resources during large-scale network operations • Ensuring optimal performance of automation infrastructure

The process management skills you've developed will serve as a foundation for more advanced system administration tasks and are essential for maintaining healthy, efficient Linux systems in production environments.
