Lab 12: Troubleshooting SELinux
Objectives
By the end of this lab, you will be able to:

Identify SELinux denials in system logs.
Create custom SELinux policies to resolve access issues.
Use audit2allow to generate and apply SELinux policy rules.
Prerequisites
A Linux system with SELinux enabled (preferably RHEL/CentOS/Fedora).
Root or sudo privileges.
Basic understanding of Linux commands and SELinux concepts.
The following packages installed:
sudo dnf install -y policycoreutils-python-utils setools-console audit
Task 1: Identify SELinux Denials Using Logs
Subtask 1.1: Check SELinux Status
Verify that SELinux is enabled and enforcing:

sestatus
Expected Output:

SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Current mode:                   enforcing
If SELinux is not enforcing, enable it:

sudo setenforce 1
Subtask 1.2: Analyze SELinux Denials in Audit Logs
Check the audit logs for SELinux denials:

sudo ausearch -m avc -ts recent
Expected Output:

time->[timestamp]
type=AVC msg=audit(1234567890.123:456): avc: denied { read } for pid=1234 comm="nginx" name="index.html" dev="sda1" ino=123456 scontext=system_u:system_r:httpd_t:s0 tcontext=unconfined_u:object_r:default_t:s0 tclass=file
Alternatively, check /var/log/audit/audit.log for AVC (Access Vector Cache) denials:

sudo grep "avc:.*denied" /var/log/audit/audit.log
Troubleshooting Tip:

If no denials appear, trigger a denial by attempting to access a restricted file (e.g., moving a file to /var/www/html without proper context).
Task 2: Create Custom SELinux Policies
Subtask 2.1: Generate a Custom Policy Module Using audit2allow
Extract the denial logs and generate a policy module:

sudo ausearch -m avc -ts recent | audit2allow -M mypolicy
Expected Output:

Generating type enforcement file: mypolicy.te
Compiling policy: checkmodule -M -m -o mypolicy.mod mypolicy.te
semodule_package -o mypolicy.pp -m mypolicy.mod
Apply the generated policy:

sudo semodule -i mypolicy.pp
Subtask 2.2: Verify the Policy is Loaded
List all SELinux modules to confirm:
sudo semodule -l | grep mypolicy
Expected Output:
mypolicy
Troubleshooting Tip:

If the policy does not resolve the issue, check for additional denials and refine the policy.
Task 3: Use audit2allow to Generate and Apply SELinux Rules
Subtask 3.1: Generate Rules from Audit Logs
Generate a readable rule set from audit logs:

sudo ausearch -m avc -ts recent | audit2allow
Expected Output:

#============= httpd_t ==============
allow httpd_t default_t:file read;
To automatically generate and apply a policy:

sudo ausearch -m avc -ts recent | audit2allow -M mynewpolicy
sudo semodule -i mynewpolicy.pp
Subtask 3.2: Test the Applied Policy
Retry the operation that caused the denial (e.g., accessing a file in a restricted directory).
Verify no new denials appear in logs:
sudo ausearch -m avc -ts recent
Troubleshooting Tip:

If issues persist, consider adjusting file contexts with chcon or restorecon.
Conclusion
In this lab, you learned how to:

Identify SELinux denials using ausearch and audit logs.
Generate and apply custom SELinux policies using audit2allow.
Verify and troubleshoot SELinux policy enforcement.
By mastering these techniques, you can effectively diagnose and resolve SELinux-related access issues in a secure and controlled manner.

Next Steps:

Explore SELinux Booleans (getsebool, setsebool) for fine-grained policy adjustments.
Practice restoring file contexts with restorecon for persistent fixes.
Lab Complete! 🎉
