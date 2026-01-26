Lab 6: Creating and Managing Custom SELinux Policies
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of SELinux policy creation and management
Create custom SELinux policies using policy modules
Use audit2allow to generate policies from AVC denials
Test and validate custom SELinux policies in a controlled environment
Implement policy enforcement and monitoring strategies
Troubleshoot common SELinux policy issues
Apply best practices for custom policy deployment in production environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with SELinux concepts (contexts, domains, types)
Knowledge of file permissions and access control
Experience with command-line interface and text editors
Understanding of log file analysis
Completion of basic SELinux configuration labs
Required Knowledge Areas
SELinux modes (Enforcing, Permissive, Disabled)
SELinux contexts and labels
Basic understanding of security policies
File system navigation and manipulation
Process management concepts
Lab Environment Setup
Al Nafi Cloud Machine Access: This lab uses Al Nafi's pre-configured Linux-based cloud machines. Simply click Start Lab to access your dedicated environment - no VM setup required!

Your cloud machine includes:

CentOS/RHEL 8 or 9 with SELinux enabled
All necessary SELinux tools pre-installed
Sample applications for policy testing
Administrative privileges for policy management
Task 1: Define and Apply Custom SELinux Policies
Subtask 1.1: Understanding SELinux Policy Structure
First, let's examine the current SELinux policy structure and understand how custom policies integrate with the system.

Step 1: Check Current SELinux Status
# Check SELinux status
sestatus

# View current policy type
getenforce

# List available policy modules
semodule -l | head -20
Step 2: Examine Policy Module Structure
# Create a working directory for our custom policies
mkdir -p /root/selinux-lab
cd /root/selinux-lab

# View the structure of an existing policy module
semodule -l | grep ssh
Subtask 1.2: Creating a Simple Custom Application
Before creating policies, we need an application to secure. Let's create a simple web service.

Step 1: Create a Custom Web Application
# Create application directory
mkdir -p /opt/mywebapp
cd /opt/mywebapp

# Create a simple web server script
cat > mywebserver.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os

PORT = 8080
DIRECTORY = "/opt/mywebapp/content"

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

# Create content directory
os.makedirs(DIRECTORY, exist_ok=True)

# Create a simple HTML file
with open(f"{DIRECTORY}/index.html", "w") as f:
    f.write("<html><body><h1>My Custom Web App</h1></body></html>")

with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
    print(f"Server running on port {PORT}")
    httpd.serve_forever()
EOF

# Make the script executable
chmod +x mywebserver.py

# Create content directory and sample file
mkdir -p /opt/mywebapp/content
echo "<html><body><h1>My Custom Web App</h1><p>This is a test page.</p></body></html>" > /opt/mywebapp/content/index.html
Step 2: Create a Systemd Service
# Create systemd service file
cat > /etc/systemd/system/mywebapp.service << 'EOF'
[Unit]
Description=My Custom Web Application
After=network.target

[Service]
Type=simple
User=mywebapp
Group=mywebapp
WorkingDirectory=/opt/mywebapp
ExecStart=/opt/mywebapp/mywebserver.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Create dedicated user for the service
useradd -r -s /bin/false mywebapp
chown -R mywebapp:mywebapp /opt/mywebapp
Subtask 1.3: Creating the Custom SELinux Policy
Now we'll create a custom SELinux policy for our web application.

Step 1: Generate Initial Policy Template
# Change to our working directory
cd /root/selinux-lab

# Use sepolicy to generate a basic policy template
sepolicy generate --init /opt/mywebapp/mywebserver.py

# This creates several files - let's examine them
ls -la mywebserver.*
Step 2: Create Custom Policy Module Files
If sepolicy generate doesn't work as expected, we'll create the policy manually:

# Create the Type Enforcement (.te) file
cat > mywebapp.te << 'EOF'
policy_module(mywebapp, 1.0.0)

########################################
#
# Declarations
#

type mywebapp_t;
type mywebapp_exec_t;
init_daemon_domain(mywebapp_t, mywebapp_exec_t)

type mywebapp_content_t;
files_type(mywebapp_content_t)

type mywebapp_var_run_t;
files_pid_file(mywebapp_var_run_t)

########################################
#
# mywebapp local policy
#

allow mywebapp_t self:tcp_socket create_stream_socket_perms;
allow mywebapp_t self:process { fork signal_perms };

# Network permissions
corenet_tcp_bind_generic_node(mywebapp_t)
corenet_tcp_bind_http_port(mywebapp_t)
corenet_tcp_sendrecv_generic_if(mywebapp_t)
corenet_tcp_sendrecv_generic_node(mywebapp_t)

# File permissions
allow mywebapp_t mywebapp_content_t:dir list_dir_perms;
allow mywebapp_t mywebapp_content_t:file read_file_perms;

# System permissions
kernel_read_system_state(mywebapp_t)
dev_read_urand(mywebapp_t)

# Logging
logging_send_syslog_msg(mywebapp_t)

# Basic system permissions
files_read_etc_files(mywebapp_t)
libs_use_ld_so(mywebapp_t)
libs_use_shared_libs(mywebapp_t)
EOF
Step 3: Create File Context File
# Create the File Context (.fc) file
cat > mywebapp.fc << 'EOF'
/opt/mywebapp/mywebserver\.py    --    gen_context(system_u:object_r:mywebapp_exec_t,s0)
/opt/mywebapp/content(/.*)?           gen_context(system_u:object_r:mywebapp_content_t,s0)
/var/run/mywebapp\.pid           --    gen_context(system_u:object_r:mywebapp_var_run_t,s0)
EOF
Step 4: Create Interface File (Optional)
# Create the Interface (.if) file for other modules to use
cat > mywebapp.if << 'EOF'
## <summary>My custom web application policy</summary>

########################################
## <summary>
##	Execute mywebapp_exec_t in the mywebapp domain.
## </summary>
## <param name="domain">
## <summary>
##	Domain allowed to transition.
## </summary>
## </param>
#
interface(`mywebapp_domtrans',`
    gen_require(`
        type mywebapp_t, mywebapp_exec_t;
    ')

    corecmd_search_bin($1)
    domtrans_pattern($1, mywebapp_exec_t, mywebapp_t)
')

########################################
## <summary>
##	Read mywebapp content files.
## </summary>
## <param name="domain">
## <summary>
##	Domain allowed access.
## </summary>
## </param>
#
interface(`mywebapp_read_content',`
    gen_require(`
        type mywebapp_content_t;
    ')

    files_search_var_lib($1)
    read_files_pattern($1, mywebapp_content_t, mywebapp_content_t)
')
EOF
Subtask 1.4: Compile and Install the Policy
Step 1: Compile the Policy Module
# Compile the policy module
make -f /usr/share/selinux/devel/Makefile mywebapp.pp

# Verify the compiled module
ls -la mywebapp.pp
Step 2: Install the Policy Module
# Install the policy module
semodule -i mywebapp.pp

# Verify installation
semodule -l | grep mywebapp
Step 3: Apply File Contexts
# Restore file contexts based on our policy
restorecon -Rv /opt/mywebapp/

# Verify the contexts are applied
ls -laZ /opt/mywebapp/
ls -laZ /opt/mywebapp/content/
Task 2: Test Policies with audit2allow
Subtask 2.1: Set Up Monitoring Environment
Step 1: Configure Audit Logging
# Ensure auditd is running
systemctl status auditd
systemctl start auditd 2>/dev/null || true

# Clear existing audit logs for clean testing
> /var/log/audit/audit.log

# Set SELinux to permissive mode for initial testing
setenforce 0
getenforce
Step 2: Start the Application and Generate Denials
# Start our web application
systemctl daemon-reload
systemctl start mywebapp

# Check if it's running
systemctl status mywebapp

# Test the application
curl http://localhost:8080/

# If there are issues, check the logs
journalctl -u mywebapp -f &
Subtask 2.2: Generate and Analyze AVC Denials
Step 1: Switch to Enforcing Mode
# Switch back to enforcing mode to generate denials
setenforce 1

# Stop and restart the service to trigger denials
systemctl stop mywebapp
systemctl start mywebapp

# Try to access the service
curl http://localhost:8080/ || echo "Expected failure in enforcing mode"
Step 2: Analyze Audit Logs
# Check for AVC denials
ausearch -m AVC -ts recent

# Use audit2allow to analyze denials
ausearch -m AVC -ts recent | audit2allow

# Generate a more detailed analysis
ausearch -m AVC -ts recent | audit2allow -w
Subtask 2.3: Use audit2allow to Refine Policy
Step 1: Generate Policy Additions
# Generate policy rules from denials
ausearch -m AVC -ts recent | audit2allow -m mywebapp_additions

# Save the additions to a file
ausearch -m AVC -ts recent | audit2allow -m mywebapp_additions > mywebapp_additions.te
Step 2: Review and Integrate Policy Additions
# Review the generated policy
cat mywebapp_additions.te

# Create an updated policy by combining original and additions
cat > mywebapp_v2.te << 'EOF'
policy_module(mywebapp, 2.0.0)

########################################
#
# Declarations
#

type mywebapp_t;
type mywebapp_exec_t;
init_daemon_domain(mywebapp_t, mywebapp_exec_t)

type mywebapp_content_t;
files_type(mywebapp_content_t)

type mywebapp_var_run_t;
files_pid_file(mywebapp_var_run_t)

########################################
#
# mywebapp local policy
#

allow mywebapp_t self:tcp_socket create_stream_socket_perms;
allow mywebapp_t self:process { fork signal_perms };

# Network permissions
corenet_tcp_bind_generic_node(mywebapp_t)
corenet_tcp_bind_http_port(mywebapp_t)
corenet_tcp_sendrecv_generic_if(mywebapp_t)
corenet_tcp_sendrecv_generic_node(mywebapp_t)

# File permissions
allow mywebapp_t mywebapp_content_t:dir list_dir_perms;
allow mywebapp_t mywebapp_content_t:file read_file_perms;

# System permissions
kernel_read_system_state(mywebapp_t)
dev_read_urand(mywebapp_t)

# Logging
logging_send_syslog_msg(mywebapp_t)

# Basic system permissions
files_read_etc_files(mywebapp_t)
libs_use_ld_so(mywebapp_t)
libs_use_shared_libs(mywebapp_t)

# Additional permissions from audit2allow
# (Add the rules generated by audit2allow here)
allow mywebapp_t self:netlink_route_socket { bind create getattr nlmsg_read };
allow mywebapp_t bin_t:file { execute execute_no_trans };
EOF
Step 3: Update the Policy
# Compile the updated policy
make -f /usr/share/selinux/devel/Makefile mywebapp_v2.pp

# Remove old policy and install new one
semodule -r mywebapp
semodule -i mywebapp_v2.pp

# Verify installation
semodule -l | grep mywebapp
Task 3: Enforce and Monitor Custom SELinux Policies
Subtask 3.1: Policy Enforcement Testing
Step 1: Test Policy Enforcement
# Ensure we're in enforcing mode
setenforce 1
getenforce

# Restart the service with new policy
systemctl restart mywebapp

# Test functionality
curl http://localhost:8080/
systemctl status mywebapp
Step 2: Test Policy Boundaries
# Test what happens when we try to access unauthorized files
# First, create a file outside our allowed context
echo "Unauthorized content" > /tmp/unauthorized.html

# Try to access it (this should be blocked)
# We'll simulate this by temporarily modifying our app
cp /opt/mywebapp/mywebserver.py /opt/mywebapp/mywebserver.py.backup

# Create a test that tries to read unauthorized files
cat > /opt/mywebapp/test_access.py << 'EOF'
#!/usr/bin/env python3
import os

# This should work - reading allowed content
try:
    with open('/opt/mywebapp/content/index.html', 'r') as f:
        print("SUCCESS: Read allowed file")
        print(f.read()[:50])
except Exception as e:
    print(f"FAILED: Could not read allowed file: {e}")

# This should fail - reading unauthorized content
try:
    with open('/tmp/unauthorized.html', 'r') as f:
        print("SECURITY ISSUE: Read unauthorized file")
        print(f.read())
except Exception as e:
    print(f"GOOD: Blocked unauthorized access: {e}")
EOF

chmod +x /opt/mywebapp/test_access.py
Step 3: Run Security Tests
# Run our security test
runcon -t mywebapp_t /opt/mywebapp/test_access.py

# Check for any new AVC denials
ausearch -m AVC -ts recent | tail -10
Subtask 3.2: Policy Monitoring and Logging
Step 1: Set Up Comprehensive Monitoring
# Create a monitoring script
cat > /root/selinux-monitor.sh << 'EOF'
#!/bin/bash

echo "=== SELinux Policy Monitoring Report ==="
echo "Generated: $(date)"
echo

echo "=== Current SELinux Status ==="
sestatus
echo

echo "=== Active Policy Modules ==="
semodule -l | grep -E "(mywebapp|custom)" || echo "No custom modules found"
echo

echo "=== Recent AVC Denials ==="
ausearch -m AVC -ts today 2>/dev/null | tail -20 || echo "No recent denials"
echo

echo "=== File Contexts for Our Application ==="
ls -laZ /opt/mywebapp/
echo

echo "=== Process Contexts ==="
ps auxZ | grep mywebapp || echo "Application not running"
echo

echo "=== Network Connections ==="
netstat -tlnp | grep :8080 || echo "No connections on port 8080"
echo

echo "=== Service Status ==="
systemctl status mywebapp --no-pager
EOF

chmod +x /root/selinux-monitor.sh
Step 2: Run Monitoring
# Execute monitoring script
/root/selinux-monitor.sh

# Set up automated monitoring (optional)
# Add to crontab for regular monitoring
echo "*/15 * * * * /root/selinux-monitor.sh >> /var/log/selinux-monitor.log 2>&1" | crontab -
Subtask 3.3: Policy Maintenance and Updates
Step 1: Create Policy Update Procedures
# Create a policy management script
cat > /root/manage-mywebapp-policy.sh << 'EOF'
#!/bin/bash

POLICY_NAME="mywebapp"
POLICY_DIR="/root/selinux-lab"
BACKUP_DIR="/root/selinux-backups"

# Create backup directory
mkdir -p $BACKUP_DIR

case "$1" in
    backup)
        echo "Backing up current policy..."
        semodule -E $POLICY_NAME -o $BACKUP_DIR/${POLICY_NAME}-$(date +%Y%m%d).pp
        echo "Backup completed: $BACKUP_DIR/${POLICY_NAME}-$(date +%Y%m%d).pp"
        ;;
    
    update)
        echo "Updating policy from source..."
        cd $POLICY_DIR
        make -f /usr/share/selinux/devel/Makefile ${POLICY_NAME}.pp
        semodule -u ${POLICY_NAME}.pp
        echo "Policy updated successfully"
        ;;
    
    remove)
        echo "Removing policy..."
        semodule -r $POLICY_NAME
        echo "Policy removed"
        ;;
    
    status)
        echo "Policy Status:"
        semodule -l | grep $POLICY_NAME
        echo "File contexts:"
        semanage fcontext -l | grep mywebapp
        ;;
    
    *)
        echo "Usage: $0 {backup|update|remove|status}"
        exit 1
        ;;
esac
EOF

chmod +x /root/manage-mywebapp-policy.sh
Step 2: Test Policy Management
# Test the management script
/root/manage-mywebapp-policy.sh status
/root/manage-mywebapp-policy.sh backup

# List backups
ls -la /root/selinux-backups/
Subtask 3.4: Advanced Policy Features
Step 1: Implement Policy Booleans
# Add a boolean to our policy for runtime configuration
cat > mywebapp_v3.te << 'EOF'
policy_module(mywebapp, 3.0.0)

########################################
#
# Declarations
#

## <desc>
## <p>
## Allow mywebapp to connect to external networks
## </p>
## </desc>
gen_tunable(mywebapp_can_network, false)

type mywebapp_t;
type mywebapp_exec_t;
init_daemon_domain(mywebapp_t, mywebapp_exec_t)

type mywebapp_content_t;
files_type(mywebapp_content_t)

type mywebapp_var_run_t;
files_pid_file(mywebapp_var_run_t)

########################################
#
# mywebapp local policy
#

allow mywebapp_t self:tcp_socket create_stream_socket_perms;
allow mywebapp_t self:process { fork signal_perms };

# Network permissions
corenet_tcp_bind_generic_node(mywebapp_t)
corenet_tcp_bind_http_port(mywebapp_t)
corenet_tcp_sendrecv_generic_if(mywebapp_t)
corenet_tcp_sendrecv_generic_node(mywebapp_t)

# Conditional network access
tunable_policy(`mywebapp_can_network',`
    corenet_tcp_connect_all_ports(mywebapp_t)
')

# File permissions
allow mywebapp_t mywebapp_content_t:dir list_dir_perms;
allow mywebapp_t mywebapp_content_t:file read_file_perms;

# System permissions
kernel_read_system_state(mywebapp_t)
dev_read_urand(mywebapp_t)

# Logging
logging_send_syslog_msg(mywebapp_t)

# Basic system permissions
files_read_etc_files(mywebapp_t)
libs_use_ld_so(mywebapp_t)
libs_use_shared_libs(mywebapp_t)

# Additional permissions
allow mywebapp_t self:netlink_route_socket { bind create getattr nlmsg_read };
allow mywebapp_t bin_t:file { execute execute_no_trans };
EOF
Step 2: Deploy and Test Advanced Policy
# Compile and install the new policy version
make -f /usr/share/selinux/devel/Makefile mywebapp_v3.pp
semodule -u mywebapp_v3.pp

# Check the boolean
getsebool mywebapp_can_network

# Test changing the boolean
setsebool mywebapp_can_network on
getsebool mywebapp_can_network

# Make it persistent
setsebool -P mywebapp_can_network on
Troubleshooting Common Issues
Issue 1: Policy Compilation Errors
# If you get compilation errors, check syntax
checkmodule -M -m -o mywebapp.mod mywebapp.te

# For more detailed error information
make -f /usr/share/selinux/devel/Makefile mywebapp.pp 2>&1 | grep -i error
Issue 2: File Context Not Applied
# Force relabeling
restorecon -RvF /opt/mywebapp/

# Check current contexts
ls -laZ /opt/mywebapp/

# Manually set context if needed
semanage fcontext -a -t mywebapp_exec_t "/opt/mywebapp/mywebserver\.py"
restorecon /opt/mywebapp/mywebserver.py
Issue 3: Service Won't Start
# Check for AVC denials
ausearch -m AVC -ts recent | grep mywebapp

# Check service logs
journalctl -u mywebapp -n 50

# Temporarily set to permissive for debugging
setenforce 0
systemctl restart mywebapp
setenforce 1
Issue 4: Policy Module Conflicts
# List all modules to check for conflicts
semodule -l | sort

# Remove conflicting module if necessary
semodule -r conflicting_module_name

# Reinstall our module
semodule -i mywebapp.pp
Verification and Testing
Final Verification Steps
# Complete system check
echo "=== Final Verification ==="

# 1. Check SELinux status
echo "SELinux Status:"
sestatus

# 2. Verify our policy is loaded
echo "Our Policy Module:"
semodule -l | grep mywebapp

# 3. Check file contexts
echo "File Contexts:"
ls -laZ /opt/mywebapp/

# 4. Test service functionality
echo "Service Test:"
systemctl status mywebapp
curl -s http://localhost:8080/ | head -1

# 5. Check for recent denials
echo "Recent Denials:"
ausearch -m AVC -ts recent | grep mywebapp || echo "No recent denials - Good!"

# 6. Verify boolean settings
echo "Policy Booleans:"
getsebool mywebapp_can_network

echo "=== Verification Complete ==="
Conclusion
In this comprehensive lab, you have successfully:

Key Accomplishments
Created Custom SELinux Policies: You learned how to design and implement custom SELinux policies from scratch, including Type Enforcement (.te), File Context (.fc), and Interface (.if) files.

Mastered audit2allow: You gained hands-on experience using audit2allow to analyze AVC denials and generate policy rules, making the policy development process more efficient and accurate.

Implemented Policy Enforcement: You successfully deployed and tested custom policies in enforcing mode, ensuring they provide the intended security controls without breaking application functionality.

Established Monitoring Procedures: You created comprehensive monitoring and management scripts to maintain your custom policies over time.

Why This Matters
Custom SELinux policies are crucial for:

Enhanced Security: Providing granular access control tailored to specific applications
Compliance Requirements: Meeting regulatory standards that require mandatory access controls
Risk Mitigation: Limiting the impact of potential security breaches through principle of least privilege
Production Readiness: Ensuring applications can run securely in enterprise environments
Next Steps
To further develop your SELinux expertise:

Practice with Complex Applications: Apply these techniques to multi-tier applications with databases and external services
Study Existing Policies: Examine system policies to understand advanced patterns and techniques
Automation Integration: Integrate policy management into CI/CD pipelines
Performance Optimization: Learn to optimize policies for minimal performance impact
Real-World Applications
The skills you've developed are directly applicable to:

Enterprise Application Deployment: Securing custom applications in production environments
Container Security: Creating policies for containerized applications
Compliance Auditing: Demonstrating security controls to auditors
Incident Response: Quickly implementing additional security controls during security incidents
This lab has provided you with practical, hands-on experience in one of the most powerful security features of modern Linux systems. The custom SELinux policies you've created represent a significant step toward advanced Linux security administration.
