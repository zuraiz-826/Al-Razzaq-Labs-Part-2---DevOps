Lab 14: Adjusting Process Priorities
Objectives
Understand Linux process priority concepts
Learn to launch processes with specific priorities using nice
Modify running process priorities using renice
Observe the impact of priority adjustments on system performance
Develop skills for optimizing system responsiveness through priority management
Prerequisites
Linux system (Fedora/RHEL/CentOS recommended)
Basic command line proficiency
Root or sudo privileges
System monitoring tools (htop/glances recommended)
Setup Requirements
Install monitoring tools:
sudo dnf install htop glances -y
Verify installation:
which htop glances
Task 1: Starting Processes with Different Priorities Using nice
Subtask 1.1: Understanding Nice Values
Linux priorities range from -20 (highest) to 19 (lowest)
Default priority is 0
Regular users can only lower priority (increase nice value)
Root can set any priority
Subtask 1.2: Launching Low-Priority Process
nice -n 19 sha1sum /dev/zero &
Expected Output:

[1] 12345  # Process ID will vary
Subtask 1.3: Launching High-Priority Process (requires sudo)
sudo nice -n -20 sha1sum /dev/zero &
Subtask 1.4: Verify Priorities
ps -l -p $(pgrep sha1sum)
Expected Output:

F S   UID     PID    PPID  C PRI  NI ADDR SZ WCHAN  TTY        TIME CMD
0 R     0   12346    4567 99  60 -20 -  1234 -      pts/0      0:10 sha1sum /dev/zero
0 R     0   12345    4567 99  80  19 -  1234 -      pts/0      0:10 sha1sum /dev/zero
Troubleshooting Tip: If you get "permission denied" for negative nice values, ensure you're using sudo.

Task 2: Modifying Running Process Priorities with renice
Subtask 2.1: Identify Target Process
pgrep sha1sum
Subtask 2.2: Increase Priority of Existing Process
sudo renice -n -10 -p 12345
Expected Output:

12345 (process ID) old priority 0, new priority -10
Subtask 2.3: Verify Priority Change
ps -o pid,ni,cmd -p 12345
Subtask 2.4: Decrease Priority of User Processes
renice -n 10 -u $(whoami)
Task 3: Monitoring Priority Impact on CPU Usage
Subtask 3.1: Launch Monitoring Tools
htop
Key Observation: Processes with lower nice values (higher priority) get more CPU time.

Subtask 3.2: Create CPU Load
for i in {1..4}; do nice -n $((i*5)) sha1sum /dev/zero & done
Subtask 3.3: Analyze in htop
Press F6 to sort by priority
Observe CPU% column differences
Note the NI (nice) values
Subtask 3.4: Cleanup Processes
pkill sha1sum
Conclusion
In this lab, you've learned:

How to assign priorities using nice at process launch
Techniques for adjusting priorities of running processes with renice
The observable impact of priority adjustments on system resource allocation
Best practices for managing process priorities to optimize system performance
Key Takeaways:

System-critical processes typically use negative nice values
User applications generally run with positive nice values
Proper priority management can prevent resource starvation
Monitoring tools are essential for verifying priority effects
Additional Exercises
Create a shell script that launches three processes with different priorities and logs their CPU usage
Experiment with cgroups for more advanced priority control
Configure a system service to always launch with specific priority
References
man nice
man renice
Linux Process Scheduling Documentation
