Lab 11: Controlling the Boot Process
Objectives
By the end of this lab, students will be able to:

• Understand the systemd boot process and service management • View and analyze systemd services and targets • Modify boot parameters using GRUB2 bootloader • Access and utilize rescue mode for troubleshooting boot failures • Implement basic boot process troubleshooting techniques • Configure system startup behavior through systemd targets

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line interface • Familiarity with file system navigation and text editing • Knowledge of basic system administration concepts • Understanding of user privileges and sudo command usage • Completion of previous labs covering basic Linux operations

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install any software.

Your lab environment includes: • CentOS/RHEL 8 or 9 system with systemd • GRUB2 bootloader pre-installed • Root access for system-level operations • All necessary tools and utilities pre-configured

Task 1: View systemd Services and Targets
Subtask 1.1: Understanding systemd Basics
systemd is the init system used by modern Linux distributions to manage services and the boot process. Let's start by exploring the current system state.

Step 1: Check the current systemd version and system status

systemctl --version
Step 2: View the overall system status

systemctl status
This command shows you the current state of your system, including: • System uptime • Number of running services • System load • Recent log entries

Subtask 1.2: Exploring systemd Services
Step 3: List all active services

systemctl list-units --type=service --state=active
Step 4: List all services (active and inactive)

systemctl list-units --type=service --all
Step 5: Check the status of a specific service (SSH service)

systemctl status sshd
Step 6: View detailed information about a service

systemctl show sshd
Subtask 1.3: Working with systemd Targets
Targets in systemd are similar to runlevels in traditional init systems. They define what services should be running in different system states.

Step 7: List all available targets

systemctl list-units --type=target
Step 8: Check the current default target

systemctl get-default
Step 9: View what services are enabled for the current target

systemctl list-dependencies
Step 10: Check what services are required by the graphical target

systemctl list-dependencies graphical.target
Subtask 1.4: Managing Service States
Step 11: Practice starting and stopping a service (using chronyd as example)

# Check current status
systemctl status chronyd

# Stop the service
sudo systemctl stop chronyd

# Verify it's stopped
systemctl status chronyd

# Start the service again
sudo systemctl start chronyd

# Verify it's running
systemctl status chronyd
Step 12: Enable and disable services for automatic startup

# Check if service is enabled
systemctl is-enabled chronyd

# Disable the service (won't start at boot)
sudo systemctl disable chronyd

# Enable the service (will start at boot)
sudo systemctl enable chronyd
Task 2: Modify Boot Parameters with GRUB2
Subtask 2.1: Understanding GRUB2 Configuration
GRUB2 (Grand Unified Bootloader version 2) is the bootloader used by most modern Linux distributions. It allows you to modify how your system boots.

Step 13: Examine the main GRUB2 configuration file

sudo cat /etc/default/grub
Step 14: View the generated GRUB2 configuration

sudo cat /boot/grub2/grub.cfg | head -50
Subtask 2.2: Temporarily Modifying Boot Parameters
Step 15: Reboot the system to access GRUB2 menu

sudo reboot
Important: When the system reboots, you'll see the GRUB2 menu. Follow these steps:

Interrupt the boot process: Press any key when you see the GRUB2 menu (you have about 5 seconds)
Select the kernel: Highlight the default kernel entry
Edit boot parameters: Press e to edit the boot parameters
Find the linux line: Look for the line that starts with linux or linux16
Add boot parameter: At the end of the linux line, add: systemd.unit=multi-user.target
Boot with changes: Press Ctrl+X to boot with the modified parameters
This will boot your system into multi-user target (similar to runlevel 3) instead of the default graphical target.

Step 16: After the system boots, verify the current target

systemctl get-default
systemctl list-units --type=target --state=active
Subtask 2.3: Permanently Modifying Boot Parameters
Step 17: Edit the GRUB2 default configuration

sudo cp /etc/default/grub /etc/default/grub.backup
sudo nano /etc/default/grub
Step 18: Modify the GRUB_CMDLINE_LINUX line to add a parameter

Find the line that starts with GRUB_CMDLINE_LINUX and add quiet parameter if it's not already there:

GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=centos/root rd.lvm.lv=centos/swap rhgb quiet"
Step 19: Regenerate the GRUB2 configuration

# For BIOS systems
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# For UEFI systems (if applicable)
sudo grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
Step 20: Change the default systemd target permanently

# Set multi-user target as default
sudo systemctl set-default multi-user.target

# Verify the change
systemctl get-default
Task 3: Use Rescue Mode to Troubleshoot Boot Failures
Subtask 3.1: Understanding Rescue Mode
Rescue mode provides a minimal environment to troubleshoot system problems. It's similar to single-user mode in traditional init systems.

Step 21: Boot into rescue mode using GRUB2

Reboot your system:

sudo reboot
When the GRUB2 menu appears:

Select the kernel entry and press e to edit
Find the linux line and add systemd.unit=rescue.target at the end
Press Ctrl+X to boot
Step 22: Once in rescue mode, explore the environment

# Check current target
systemctl list-units --type=target --state=active

# Check what services are running
systemctl list-units --type=service --state=active

# Check mounted filesystems
df -h

# Check system logs
journalctl -b
Subtask 3.2: Simulating and Fixing Boot Problems
Step 23: Create a simulated boot problem (be careful with this step)

# First, mount the root filesystem as read-write
mount -o remount,rw /

# Create a backup of fstab
cp /etc/fstab /etc/fstab.backup

# Add an invalid entry to fstab (this will cause boot issues)
echo "/dev/nonexistent /mnt/fake ext4 defaults 0 2" >> /etc/fstab
Step 24: Exit rescue mode and attempt normal boot

# Try to boot normally
systemctl default
If the system hangs or shows errors, reboot and enter rescue mode again.

Step 25: Fix the boot problem from rescue mode

# Mount root filesystem as read-write
mount -o remount,rw /

# Remove the problematic line from fstab
sed -i '/nonexistent/d' /etc/fstab

# Verify the fix
cat /etc/fstab

# Or restore from backup
# cp /etc/fstab.backup /etc/fstab
Subtask 3.3: Using Emergency Mode
Emergency mode provides an even more minimal environment than rescue mode.

Step 26: Boot into emergency mode

Reboot and at the GRUB2 menu:

Edit the kernel parameters
Add systemd.unit=emergency.target
Boot with Ctrl+X
Step 27: Explore emergency mode

# Check active targets
systemctl list-units --type=target --state=active

# Check mounted filesystems (should be minimal)
mount

# Mount root as read-write if needed
mount -o remount,rw /
Subtask 3.4: Password Recovery Scenario
Step 28: Simulate password recovery using rescue mode

Boot into rescue mode and reset the root password:

# Mount root filesystem as read-write
mount -o remount,rw /

# Change root password
passwd root

# Create a new user account
useradd -m testuser
passwd testuser

# Add user to wheel group for sudo access
usermod -aG wheel testuser
Step 29: Return to normal operation

# Set default target back to graphical (if desired)
systemctl set-default graphical.target

# Reboot to normal mode
systemctl reboot
Troubleshooting Tips
Common Issues and Solutions
Issue 1: GRUB2 menu doesn't appear

Solution: The timeout might be set to 0. Edit /etc/default/grub and set GRUB_TIMEOUT=5
Issue 2: Can't edit GRUB2 parameters

Solution: Make sure you're pressing e (not Enter) when the kernel is highlighted
Issue 3: Changes to /etc/default/grub don't take effect

Solution: Remember to run grub2-mkconfig after making changes
Issue 4: System won't boot after changes

Solution: Use rescue mode to revert changes or restore backup files
Verification Commands
Use these commands to verify your work:

# Check current systemd target
systemctl get-default

# View boot messages
journalctl -b

# Check service status
systemctl status <service-name>

# View GRUB2 configuration
sudo cat /etc/default/grub
Conclusion
In this lab, you have successfully learned to control the Linux boot process through multiple methods:

Key Accomplishments: • systemd Management: You explored systemd services and targets, learning how to view, start, stop, enable, and disable services that control system behavior • GRUB2 Configuration: You modified boot parameters both temporarily and permanently, giving you control over how the system starts • Rescue Operations: You practiced using rescue and emergency modes to troubleshoot boot failures and recover from system problems

Why This Matters: These skills are essential for system administrators because: • System Recovery: When systems fail to boot properly, you can use rescue mode to diagnose and fix problems • Performance Optimization: Understanding systemd allows you to control which services run, improving system performance • Security Enhancement: You can modify boot parameters to enhance security or disable unnecessary services • Troubleshooting: These techniques are crucial for the Red Hat Certified System Administrator exam and real-world scenarios

Real-World Applications: • Recovering systems with corrupted configurations • Optimizing server startup times by managing services • Implementing security hardening through boot parameter modifications • Performing maintenance tasks in minimal system environments

You now have the fundamental skills needed to manage the Linux boot process effectively, which is a critical competency for any system administrator working with Red Hat Enterprise Linux or similar distributions.
