Lab 3: Initial Configuration of Red Hat Satellite
Objectives
By the end of this lab, students will be able to:

Perform the initial configuration of a Red Hat Satellite server
Configure authentication settings using HTPasswd method
Set up user roles and permissions for different access levels
Create and manage user accounts with appropriate privileges
Test access control with different user roles
Understand the security implications of user role management in Satellite
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface operations
Knowledge of user management concepts in Linux
Understanding of web-based administration interfaces
Completion of Lab 1 (Satellite Installation) and Lab 2 (Basic Setup)
Access to a Red Hat Satellite server (version 6.x or later)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Red Hat Satellite already installed. Simply click Start Lab to access your environment - no need to build your own virtual machine or install software.

Your lab environment includes:

Red Hat Enterprise Linux 8/9 server
Red Hat Satellite 6.x pre-installed
Administrative access to the system
Web browser access to Satellite web interface
Task 1: Configure Authentication Settings
Subtask 1.1: Access Satellite Web Interface
Open your web browser and navigate to your Satellite server:

https://your-satellite-server.example.com
Log in using the default admin credentials created during installation:

Username: admin
Password: [password set during installation]
Verify successful login by checking that you can see the Satellite dashboard with system overview information.

Subtask 1.2: Configure HTPasswd Authentication
Navigate to Authentication Settings:

Click on Administer in the top menu
Select Authentication Sources from the dropdown menu
Create a new HTPasswd authentication source:

Click the Create Authentication Source button
Fill in the following details:
Name: Local HTPasswd
Type: Select HTPasswd from dropdown
Server: Leave blank (local authentication)
Account: Leave blank
Base DN: Leave blank
Groups base DN: Leave blank
Configure HTPasswd settings:

On the fly registration: Check this box to allow automatic user creation
Usergroup sync: Uncheck this option for now
Click Submit to save the configuration
Subtask 1.3: Create HTPasswd File
Connect to your Satellite server via SSH:

ssh root@your-satellite-server.example.com
Create the HTPasswd file:

# Create directory for authentication files
mkdir -p /etc/satellite/auth

# Create HTPasswd file with first user
htpasswd -c /etc/satellite/auth/htpasswd testuser1
When prompted, enter a password for testuser1 (e.g., TestPass123!)

Add additional users to the HTPasswd file:

# Add second user
htpasswd /etc/satellite/auth/htpasswd testuser2

# Add third user for manager role
htpasswd /etc/satellite/auth/htpasswd manager1
Set proper permissions on the HTPasswd file:

chown foreman:foreman /etc/satellite/auth/htpasswd
chmod 640 /etc/satellite/auth/htpasswd
Verify the HTPasswd file contents:

cat /etc/satellite/auth/htpasswd
Task 2: Set Up User Roles and Permissions
Subtask 2.1: Understanding Default Roles
Navigate to User Roles:

In the Satellite web interface, click Administer
Select Roles from the dropdown menu
Review existing default roles:

Site Manager: Full administrative access
Manager: Can manage most resources
Viewer: Read-only access to most resources
Anonymous: Limited public access
Examine role permissions:

Click on Manager role to view its permissions
Note the different permission categories:
Host permissions: Managing individual hosts
Hostgroup permissions: Managing groups of hosts
Location permissions: Managing different locations
Organization permissions: Managing organizations
Subtask 2.2: Create Custom Roles
Create a Content Manager role:

Click Create Role button
Name: Content Manager
Description: Manages content repositories and packages
Assign permissions to Content Manager role:

Click on the Filters tab
Click Add Filter and configure:
Permission: Select view_products
Search: Leave blank (applies to all)
Click Submit
Add additional permissions for Content Manager:

Permission: edit_products
Permission: destroy_products
Permission: create_products
Permission: view_content_views
Permission: edit_content_views
Permission: create_content_views
Permission: destroy_content_views
Create a Host Administrator role:

Click Create Role button
Name: Host Administrator
Description: Manages host systems and configurations
Assign permissions to Host Administrator role:

Permission: view_hosts
Permission: edit_hosts
Permission: create_hosts
Permission: destroy_hosts
Permission: view_hostgroups
Permission: edit_hostgroups
Permission: create_hostgroups
Subtask 2.3: Create User Groups
Navigate to User Groups:

Click Administer
Select User Groups
Create Content Team user group:

Click Create User Group
Name: Content Team
Description: Team responsible for content management
Roles: Select Content Manager
Click Submit
Create System Administrators user group:

Click Create User Group
Name: System Administrators
Description: Team responsible for host management
Roles: Select Host Administrator
Click Submit
Task 3: Test Access with Different User Roles
Subtask 3.1: Create Users and Assign Roles
Create users in Satellite:

Navigate to Administer > Users
Click Create User
Create first test user:

Login: testuser1
Email: testuser1@example.com
First name: Test
Last name: User One
Authentication Source: Select Local HTPasswd
Roles: Select Content Manager
User Groups: Select Content Team
Click Submit
Create second test user:

Login: testuser2
Email: testuser2@example.com
First name: Test
Last name: User Two
Authentication Source: Select Local HTPasswd
Roles: Select Host Administrator
User Groups: Select System Administrators
Click Submit
Create manager user:

Login: manager1
Email: manager1@example.com
First name: Manager
Last name: One
Authentication Source: Select Local HTPasswd
Roles: Select Manager
Click Submit
Subtask 3.2: Test Content Manager Access
Log out of admin account:

Click on admin in the top-right corner
Select Logout
Log in as testuser1:

Username: testuser1
Password: TestPass123!
Test Content Manager permissions:

Navigate to Content > Products
Verify you can view existing products
Try to create a new product:
Click Create Product
Name: Test Product
Label: test-product
Description: Testing content manager access
Click Save
Test restricted access:

Try to navigate to Hosts > All Hosts
Verify that access is denied or limited
Try to access Administer menu
Note which options are available vs. restricted
Document your findings:

# Create a test log file
echo "Content Manager Test Results:" > /tmp/content_manager_test.log
echo "- Can access Content menu: YES" >> /tmp/content_manager_test.log
echo "- Can create products: YES" >> /tmp/content_manager_test.log
echo "- Can access Hosts menu: NO" >> /tmp/content_manager_test.log
echo "- Can access Administer menu: LIMITED" >> /tmp/content_manager_test.log
Subtask 3.3: Test Host Administrator Access
Log out and log in as testuser2:

Username: testuser2
Password: TestPass123!
Test Host Administrator permissions:

Navigate to Hosts > All Hosts
Verify you can view existing hosts
Try to create a new host group:
Navigate to Configure > Host Groups
Click Create Host Group
Name: Test Host Group
Description: Testing host admin access
Click Submit
Test content access restrictions:

Try to navigate to Content > Products
Verify access is denied or limited
Note any error messages or restrictions
Document Host Administrator test results:

echo "Host Administrator Test Results:" > /tmp/host_admin_test.log
echo "- Can access Hosts menu: YES" >> /tmp/host_admin_test.log
echo "- Can create host groups: YES" >> /tmp/host_admin_test.log
echo "- Can access Content menu: NO" >> /tmp/host_admin_test.log
echo "- Can manage host configurations: YES" >> /tmp/host_admin_test.log
Subtask 3.4: Test Manager Access
Log out and log in as manager1:

Username: manager1
Password: TestPass123!
Test Manager permissions:

Navigate through all main menu items:
Monitor - Dashboard access
Content - Full content management
Hosts - Full host management
Configure - Configuration management
Administer - Administrative functions
Verify comprehensive access:

Create a test content view:
Navigate to Content > Content Views
Click Create New View
Name: Manager Test View
Description: Testing manager access
Click Save
Test user management capabilities:

Navigate to Administer > Users
Verify you can view and potentially modify users
Check role assignment capabilities
Subtask 3.5: Compare Access Levels
Create a comparison matrix: ```bash # Log back in as admin to create comparison cat > /tmp/role_comparison.txt << EOF SATELLITE ROLE COMPARISON MATRIX
Feature/Menu	Content Manager	Host Administrator	Manager	Admin
Content Management	Full Access	No Access	Full	Full
Host Management	No Access	Full Access	Full	Full
User Management	No Access	No Access	Limited	Full
System Configuration	No Access	Limited	Full	Full
Reports & Monitoring	Read Only	Read Only	Full	Full
Authentication Setup	No Access	No Access	No	Full
EOF				

Verify role inheritance and conflicts:

Log back in as admin
Navigate to Administer > Users
Select testuser1 and try adding an additional role
Observe how multiple roles interact
Troubleshooting Common Issues
Authentication Problems
HTPasswd authentication not working:

# Check HTPasswd file permissions
ls -la /etc/satellite/auth/htpasswd

# Verify file format
cat /etc/satellite/auth/htpasswd

# Restart Satellite services if needed
satellite-maintain service restart
Users cannot log in:

Verify authentication source is properly configured
Check that user exists in both HTPasswd file and Satellite user database
Ensure passwords match between HTPasswd file and user expectations
Permission Issues
Users seeing "Access Denied" errors:

# Check user role assignments
# In Satellite web interface:
# Administer > Users > [select user] > Roles tab
Roles not working as expected:

Verify role permissions are correctly configured
Check for conflicting permissions
Ensure user groups are properly assigned
Performance Issues
Slow authentication response:
# Check Satellite service status
satellite-maintain service status

# Monitor system resources
top
df -h
Verification and Testing
Final Verification Steps
Test all created users:

# Create verification script
cat > /tmp/verify_users.sh << 'EOF'
#!/bin/bash
echo "=== User Access Verification ==="
echo "1. testuser1 (Content Manager): Should access Content menu only"
echo "2. testuser2 (Host Administrator): Should access Hosts menu only"
echo "3. manager1 (Manager): Should access most menus"
echo "4. admin: Should access all menus"
echo ""
echo "Test each user login and document results"
EOF

chmod +x /tmp/verify_users.sh
/tmp/verify_users.sh
Verify authentication source:

Check that HTPasswd authentication source is active
Confirm users can authenticate successfully
Test password changes work correctly
Validate role permissions:

Ensure each role has appropriate access levels
Verify security boundaries are maintained
Test that users cannot escalate privileges
Conclusion
In this lab, you have successfully completed the initial configuration of Red Hat Satellite authentication and user management. You have accomplished the following key tasks:

Authentication Configuration: You set up HTPasswd-based authentication, creating a local authentication source that allows Satellite to authenticate users against a local password file. This provides a secure, manageable way to control access without requiring external authentication systems.

User Role Management: You created custom roles (Content Manager and Host Administrator) tailored to specific job functions, demonstrating how to implement the principle of least privilege. This ensures users have only the permissions necessary for their responsibilities.

Access Control Testing: You verified that role-based access control works correctly by testing different user accounts and confirming that each role provides appropriate access levels while restricting unauthorized functions.

Security Implementation: You established a foundation for secure Satellite administration by implementing proper user management, role separation, and access controls that are essential for enterprise environments.

This configuration is crucial for production Satellite deployments because it:

Ensures security through proper access controls
Enables delegation of administrative tasks
Maintains audit trails for user actions
Provides scalable user management for growing organizations
The skills you've developed in this lab are directly applicable to Red Hat Satellite 6 Administration certification objectives and real-world enterprise scenarios where proper user management and security are paramount.

Your Satellite server is now configured with a robust authentication and authorization system that can be extended and customized as your organization's needs grow.
