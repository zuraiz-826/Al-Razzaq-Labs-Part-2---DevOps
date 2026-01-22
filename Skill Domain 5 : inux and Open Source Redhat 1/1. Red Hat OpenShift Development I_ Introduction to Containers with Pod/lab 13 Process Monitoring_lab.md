Lab 13: Process Monitoring
Objectives
Monitor system processes using top, ps, and htop.
Identify resource-intensive processes causing performance bottlenecks.
Optimize system performance by killing or renicing processes.
Prerequisites
A Linux-based system (Ubuntu/CentOS/RHEL/Fedora).
Basic familiarity with the command line.
Administrative (sudo) privileges for process management tasks.
Installation of htop (if not pre-installed).
Lab Setup
Step 1: Install Required Tools
Ensure htop is installed (if not already present):

sudo apt update && sudo apt install htop  # For Debian/Ubuntu
sudo yum install epel-release && sudo yum install htop  # For CentOS/RHEL
sudo dnf install htop  # For Fedora
Expected Outcome:

htop is installed and ready for use.
Troubleshooting Tip:

If the package manager fails, check internet connectivity or repository configurations.
Task 1: View Running Processes
Step 1.1: Using top
Run the top command to monitor real-time system processes:

top
Key Observations:

CPU Usage: Check %CPU column for high-usage processes.
Memory Usage: Observe %MEM column.
Process ID (PID): Note PIDs of problematic processes.
Exit top: Press q.

Expected Outcome:

A dynamic view of running processes sorted by CPU usage.
Step 1.2: Using ps
List all processes with detailed information:

ps aux
Key Flags:

a = Show processes for all users.
u = Display user-oriented format.
x = Include processes not attached to a terminal.
Expected Outcome:

A static list of all running processes with resource usage.
Step 1.3: Using htop
Launch htop for an interactive process viewer:

htop
Key Features:

Color-coded CPU/memory usage.
Tree view (F5) to see parent-child process relationships.
Sort by CPU (F6 > %CPU).
Exit htop: Press F10 or q.

Expected Outcome:

An interactive, user-friendly process monitoring interface.
Task 2: Identify Resource Hogs and Bottlenecks
Step 2.1: Find High CPU Usage Processes
Using ps with sorting:

ps aux --sort=-%cpu | head -n 5
Expected Outcome:

Top 5 CPU-consuming processes.
Step 2.2: Find High Memory Usage Processes
Using ps with memory sorting:

ps aux --sort=-%mem | head -n 5
Expected Outcome:

Top 5 memory-consuming processes.
Step 2.3: Check System Load Average
Run:

uptime
Key Metric:

Load average (1m, 5m, 15m): Values above CPU core count indicate high load.
Expected Outcome:

System load averages displayed.
Task 3: Optimize System Performance
Step 3.1: Kill a Process
Identify a non-critical high-resource process and terminate it:

kill -9 <PID>  # Replace <PID> with actual process ID
Warning:

-9 (SIGKILL) forces termination; use cautiously.
Alternative (Graceful Termination):

kill <PID>  # Sends SIGTERM (allows cleanup)
Expected Outcome:

The specified process terminates.
Step 3.2: Renice a Process
Change priority of a CPU-intensive process:

sudo renice -n 10 -p <PID>  # Lower priority (higher niceness)
Niceness Range:

-20 (Highest priority) to 19 (Lowest priority).
Expected Outcome:

The process's scheduling priority is adjusted.
Conclusion
Successfully monitored processes using top, ps, and htop.
Identified CPU and memory bottlenecks.
Optimized system performance by killing or renicing processes.
Next Steps:

Automate monitoring with scripts (e.g., cron jobs for ps logging).
Explore advanced tools like glances or nmon for deeper insights.
Final Command Check:

echo "Lab 13 - Process Monitoring completed successfully!"
Expected Outcome:

Confirmation message indicating successful completion.
Troubleshooting Appendix
Permission Denied: Use sudo for killing/renicing system processes.
Process Not Found: Verify PID with ps aux | grep <process_name>.
High Load Persists: Investigate with dmesg or journalctl for system errors.
End of Lab 13
