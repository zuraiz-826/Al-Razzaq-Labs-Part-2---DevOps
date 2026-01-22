Lab 11: Introduction to SELinux
Objectives
By the end of this lab, you will be able to:

Install and configure SELinux on a Linux system.
Understand and switch between SELinux modes (Enforcing, Permissive, Disabled).
Check and modify the SELinux context of files and processes.
Prerequisites
A Linux system (preferably RHEL, CentOS, or Fedora).
Root or sudo privileges.
Basic familiarity with Linux command line.
Task 1: Install and Configure SELinux
Subtask 1.1: Verify SELinux Installation
Most modern Linux distributions come with SELinux pre-installed. Verify its presence:

# Check if SELinux is installed
rpm -qa | grep selinux
Expected Output:
Packages like libselinux, selinux-policy, etc., should appear.

Troubleshooting:
If SELinux is not installed, install it using:

sudo dnf install selinux-policy selinux-policy-targeted libselinux-utils
Subtask 1.2: Check SELinux Status
Check the current status of SELinux:

sestatus
Expected Output:

SELinux status: enabled
Current mode: enforcing, permissive, or disabled
Policy version: (e.g., targeted)
Task 2: Understand SELinux Modes
Subtask 2.1: Switch Between SELinux Modes
SELinux operates in three modes:

Enforcing: Policies are enforced (default).
Permissive: Policies are logged but not enforced (for troubleshooting).
Disabled: SELinux is turned off.
Check Current Mode
getenforce
Temporarily Change Mode
To switch to Permissive mode:

sudo setenforce 0
To switch back to Enforcing mode:

sudo setenforce 1
Note: These changes are temporary and revert after reboot.

Permanently Change Mode
Edit /etc/selinux/config:

sudo vi /etc/selinux/config
Change SELINUX= to one of:

enforcing
permissive
disabled
Reboot to apply changes:

sudo reboot
Expected Outcome:
After reboot, sestatus or getenforce reflects the new mode.

Task 3: Check and Modify SELinux Contexts
Subtask 3.1: View File Contexts
SELinux assigns security contexts to files, processes, and ports. Check a file's context:

ls -Z /etc/passwd
Expected Output:
Example: system_u:object_r:passwd_file_t:s0

Subtask 3.2: Change File Context
Use chcon to modify a file's context temporarily:

# Create a test file
sudo touch /var/www/html/testfile.html

# Check current context
ls -Z /var/www/html/testfile.html

# Change context to httpd_sys_content_t (default for web files)
sudo chcon -t httpd_sys_content_t /var/www/html/testfile.html

# Verify
ls -Z /var/www/html/testfile.html
Expected Outcome:
The context changes to httpd_sys_content_t.

Subtask 3.3: Restore Default Contexts
To reset contexts to default values (useful after misconfigurations):

sudo restorecon -v /var/www/html/testfile.html
Conclusion
In this lab, you:

Verified and installed SELinux.
Explored SELinux modes and switched between them.
Checked and modified SELinux file contexts.
Key Takeaways:

SELinux enhances security through mandatory access control (MAC).
Always test in Permissive mode before enforcing policies.
Use ls -Z, chcon, and restorecon for context management.
Next Steps:
Explore SELinux policies and boolean settings for fine-grained control.

Troubleshooting Tips
If a service fails to start, check SELinux logs:
sudo ausearch -m avc -ts recent
Use audit2allow to generate policy modules for denied actions:
sudo ausearch -m avc -ts recent | audit2allow -M mypolicy
sudo semodule -i mypolicy.pp
Additional Resources
SELinux Wiki
man selinux, man chcon, man sestatus

This lab provides a hands-on introduction to SELinux with clear steps, commands, and explanations. Let me know if you'd like any modifications!
