Lab 15: Kernel Parameter Tuning
Objectives
Understand how to view and modify Linux kernel parameters using sysctl.
Tune kernel parameters for networking and memory management.
Test the effects of kernel parameter changes on system performance.
Prerequisites
A Linux-based system (e.g., CentOS, RHEL, Ubuntu).
Root or sudo privileges.
Basic familiarity with the Linux command line.
Task 1: View and Modify Kernel Parameters with sysctl
Subtask 1.1: View Current Kernel Parameters
Open a terminal and list all current kernel parameters:

sudo sysctl -a
Expected Outcome: A list of all active kernel parameters will be displayed.
View a specific parameter (e.g., vm.swappiness):

sudo sysctl vm.swappiness
Expected Outcome: The current value of vm.swappiness (default is usually 60).
Subtask 1.2: Temporarily Modify a Kernel Parameter
Change the vm.swappiness value temporarily (valid until reboot):

sudo sysctl -w vm.swappiness=10
Explanation: Reduces how aggressively the kernel swaps memory to disk.
Verify the change:

sudo sysctl vm.swappiness
Expected Outcome: The output should now show vm.swappiness = 10.
Subtask 1.3: Permanently Modify a Kernel Parameter
Open the sysctl configuration file:

sudo nano /etc/sysctl.conf
Add or modify a parameter (e.g., vm.swappiness=10):

vm.swappiness = 10
Apply changes without rebooting:

sudo sysctl -p
Expected Outcome: The new value will persist after reboot.
Task 2: Tune Parameters for Networking and Memory Management
Subtask 2.1: Optimize Network Performance
Increase the maximum number of open files (file descriptors) for networking:

sudo sysctl -w fs.file-max=100000
Enable TCP Fast Open for better connection speeds:

sudo sysctl -w net.ipv4.tcp_fastopen=3
Verify changes:

sudo sysctl fs.file-max net.ipv4.tcp_fastopen
Subtask 2.2: Adjust Memory Management Settings
Reduce kernel memory allocation for better performance:

sudo sysctl -w vm.overcommit_memory=1
Explanation: 1 allows overcommitment, useful for memory-intensive applications.
Disable transparent hugepages (can improve database performance):

sudo sysctl -w vm.nr_hugepages=0
Verify settings:

sudo sysctl vm.overcommit_memory vm.nr_hugepages
Task 3: Test the Effect of Kernel Changes
Subtask 3.1: Monitor System Performance
Check current memory usage:

free -h
Monitor network connections:

ss -s
Subtask 3.2: Simulate Workload and Observe Changes
Run a memory-intensive task (e.g., stress-ng):

sudo apt install stress-ng -y  # For Debian/Ubuntu
sudo yum install stress-ng -y  # For RHEL/CentOS
stress-ng --vm 2 --vm-bytes 2G --timeout 60s
Observe system behavior:

top
Expected Outcome: The system should handle memory pressure better with tuned vm.swappiness.
Test network performance (e.g., using iperf3):

iperf3 -c <server-ip>
Expected Outcome: Improved throughput if TCP optimizations are effective.
Conclusion
Successfully viewed and modified kernel parameters using sysctl.
Tuned networking and memory management settings for better performance.
Verified the impact of changes through testing.
Troubleshooting Tips
If changes don’t apply, ensure /etc/sysctl.conf syntax is correct.
Use dmesg to check for kernel-related errors.
Revert changes by removing entries from /etc/sysctl.conf and reloading (sudo sysctl -p).
Next Steps
Experiment with other kernel parameters (net.core.somaxconn, vm.dirty_ratio).
Automate tuning with Ansible or shell scripts for large-scale deployments.
End of Lab
