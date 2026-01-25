Lab 3: Automating User and Group Management
Objectives
By the end of this lab, you will be able to:

Create and execute Ansible playbooks to automate user and group management
Configure multiple users with specific group assignments using Ansible
Set user passwords and implement password expiration policies
Apply Access Control Lists (ACLs) to manage file and directory permissions
Understand best practices for automated user management in enterprise environments
Troubleshoot common issues in Ansible user management playbooks
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Knowledge of Linux user and group concepts
Understanding of file permissions and ownership
Basic Ansible concepts (playbooks, tasks, modules)
Access to a text editor (vim, nano, or similar)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ansible already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Ansible 2.9 or higher pre-installed
Python 3.6+ with required modules
Text editors (vim, nano)
All necessary system utilities
Task 1: Write a Playbook to Create Multiple Users and Assign Them to Groups
Subtask 1.1: Create the Lab Directory Structure
First, let's organize our work by creating a proper directory structure for our Ansible project.

mkdir -p ~/ansible-user-management
cd ~/ansible-user-management
mkdir -p group_vars host_vars roles
Subtask 1.2: Create the Inventory File
Create an inventory file to define our target hosts:

cat > inventory << 'EOF'
[webservers]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
Subtask 1.3: Create the Main User Management Playbook
Create the primary playbook that will handle user and group creation:

cat > user-management.yml << 'EOF'
---
- name: Automate User and Group Management
  hosts: webservers
  become: yes
  vars:
    # Define groups to be created
    user_groups:
      - name: developers
        gid: 3001
      - name: testers
        gid: 3002
      - name: admins
        gid: 3003
    
    # Define users with their properties
    system_users:
      - username: alice
        full_name: "Alice Johnson"
        primary_group: developers
        secondary_groups: 
          - admins
        shell: /bin/bash
        create_home: yes
        password: "$6$rounds=656000$salt$encrypted_password_here"
        
      - username: bob
        full_name: "Bob Smith"
        primary_group: testers
        secondary_groups: 
          - developers
        shell: /bin/bash
        create_home: yes
        password: "$6$rounds=656000$salt$encrypted_password_here"
        
      - username: charlie
        full_name: "Charlie Brown"
        primary_group: admins
        secondary_groups: []
        shell: /bin/bash
        create_home: yes
        password: "$6$rounds=656000$salt$encrypted_password_here"

  tasks:
    - name: Create system groups
      group:
        name: "{{ item.name }}"
        gid: "{{ item.gid }}"
        state: present
      loop: "{{ user_groups }}"
      tags: groups

    - name: Create system users
      user:
        name: "{{ item.username }}"
        comment: "{{ item.full_name }}"
        group: "{{ item.primary_group }}"
        groups: "{{ item.secondary_groups | join(',') if item.secondary_groups else omit }}"
        shell: "{{ item.shell }}"
        create_home: "{{ item.create_home }}"
        password: "{{ item.password }}"
        state: present
      loop: "{{ system_users }}"
      tags: users

    - name: Display created users information
      debug:
        msg: "User {{ item.username }} created with primary group {{ item.primary_group }}"
      loop: "{{ system_users }}"
      tags: info
EOF
Subtask 1.4: Generate Encrypted Passwords
Before running the playbook, we need to generate proper encrypted passwords. Use the following command to create encrypted passwords:

# Generate encrypted password for each user
python3 -c "import crypt; print(crypt.crypt('password123', crypt.mksalt(crypt.METHOD_SHA512)))"
Note: Replace 'password123' with your desired password. Copy the output and replace the placeholder encrypted passwords in the playbook.

Subtask 1.5: Run the User Creation Playbook
Execute the playbook to create users and groups:

ansible-playbook -i inventory user-management.yml --tags groups,users
Subtask 1.6: Verify User and Group Creation
Verify that users and groups were created successfully:

# Check created groups
getent group developers testers admins

# Check created users
getent passwd alice bob charlie

# Verify user group memberships
groups alice bob charlie
Task 2: Configure User Passwords and Expiration Dates
Subtask 2.1: Create Password Policy Playbook
Create a separate playbook to handle password policies and expiration dates:

cat > password-policy.yml << 'EOF'
---
- name: Configure User Password Policies and Expiration
  hosts: webservers
  become: yes
  vars:
    password_policies:
      - username: alice
        max_days: 90
        min_days: 7
        warn_days: 14
        expire_date: "2024-12-31"
        
      - username: bob
        max_days: 60
        min_days: 5
        warn_days: 10
        expire_date: "2024-11-30"
        
      - username: charlie
        max_days: 180
        min_days: 14
        warn_days: 21
        expire_date: "2025-06-30"

  tasks:
    - name: Set password aging policies
      shell: |
        chage -M {{ item.max_days }} {{ item.username }}
        chage -m {{ item.min_days }} {{ item.username }}
        chage -W {{ item.warn_days }} {{ item.username }}
      loop: "{{ password_policies }}"
      tags: password_aging

    - name: Set account expiration dates
      user:
        name: "{{ item.username }}"
        expires: "{{ (item.expire_date + ' 00:00:00') | to_datetime('%Y-%m-%d %H:%M:%S') | int }}"
      loop: "{{ password_policies }}"
      tags: account_expiry

    - name: Force password change on first login
      shell: chage -d 0 {{ item.username }}
      loop: "{{ password_policies }}"
      when: force_password_change | default(false)
      tags: force_change

    - name: Display password policy information
      shell: chage -l {{ item.username }}
      register: password_info
      loop: "{{ password_policies }}"
      tags: info

    - name: Show password policy details
      debug:
        msg: "{{ password_info.results }}"
      tags: info
EOF
Subtask 2.2: Create Advanced Password Configuration
Create a more comprehensive password configuration playbook:

cat > advanced-password-config.yml << 'EOF'
---
- name: Advanced Password Configuration
  hosts: webservers
  become: yes
  vars:
    users_with_temp_passwords:
      - alice
      - bob
      - charlie

  tasks:
    - name: Install required packages for password management
      package:
        name:
          - passwd
          - shadow-utils
        state: present

    - name: Generate temporary passwords for users
      set_fact:
        temp_passwords: "{{ temp_passwords | default({}) | combine({item: lookup('password', '/dev/null length=12 chars=ascii_letters,digits')}) }}"
      loop: "{{ users_with_temp_passwords }}"
      tags: temp_passwords

    - name: Set temporary passwords
      user:
        name: "{{ item }}"
        password: "{{ temp_passwords[item] | password_hash('sha512') }}"
        update_password: always
      loop: "{{ users_with_temp_passwords }}"
      tags: temp_passwords

    - name: Create password file for reference
      lineinfile:
        path: /tmp/user_passwords.txt
        line: "{{ item }}: {{ temp_passwords[item] }}"
        create: yes
        mode: '0600'
      loop: "{{ users_with_temp_passwords }}"
      tags: temp_passwords

    - name: Configure password complexity requirements
      lineinfile:
        path: /etc/security/pwquality.conf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        backup: yes
      loop:
        - { regexp: '^#?\s*minlen', line: 'minlen = 8' }
        - { regexp: '^#?\s*minclass', line: 'minclass = 3' }
        - { regexp: '^#?\s*maxrepeat', line: 'maxrepeat = 2' }
      tags: password_complexity
EOF
Subtask 2.3: Execute Password Policy Configuration
Run the password policy playbooks:

# Apply password policies
ansible-playbook -i inventory password-policy.yml

# Apply advanced password configuration
ansible-playbook -i inventory advanced-password-config.yml --tags temp_passwords,password_complexity
Subtask 2.4: Verify Password Policies
Check that password policies are correctly applied:

# Check password aging for each user
for user in alice bob charlie; do
    echo "Password policy for $user:"
    chage -l $user
    echo "---"
done

# Check temporary passwords (if generated)
sudo cat /tmp/user_passwords.txt
Task 3: Assign Specific Permissions Using ACL Module
Subtask 3.1: Create Directory Structure for ACL Testing
First, create directories and files for testing ACL permissions:

cat > acl-setup.yml << 'EOF'
---
- name: Setup Directory Structure for ACL Testing
  hosts: webservers
  become: yes
  vars:
    test_directories:
      - path: /opt/projects
        owner: root
        group: developers
        mode: '0755'
      - path: /opt/projects/web-app
        owner: alice
        group: developers
        mode: '0775'
      - path: /opt/projects/testing
        owner: bob
        group: testers
        mode: '0775'
      - path: /opt/projects/admin
        owner: charlie
        group: admins
        mode: '0770'

    test_files:
      - path: /opt/projects/web-app/index.html
        content: "<html><body>Web Application</body></html>"
        owner: alice
        group: developers
      - path: /opt/projects/testing/test-results.txt
        content: "Test Results: All tests passed"
        owner: bob
        group: testers
      - path: /opt/projects/admin/config.conf
        content: "admin_setting=true"
        owner: charlie
        group: admins

  tasks:
    - name: Install ACL package
      package:
        name: acl
        state: present

    - name: Create project directories
      file:
        path: "{{ item.path }}"
        state: directory
        owner: "{{ item.owner }}"
        group: "{{ item.group }}"
        mode: "{{ item.mode }}"
      loop: "{{ test_directories }}"

    - name: Create test files
      copy:
        content: "{{ item.content }}"
        dest: "{{ item.path }}"
        owner: "{{ item.owner }}"
        group: "{{ item.group }}"
        mode: '0644'
      loop: "{{ test_files }}"
EOF
Subtask 3.2: Create ACL Permissions Playbook
Create a comprehensive playbook for managing ACL permissions:

cat > acl-permissions.yml << 'EOF'
---
- name: Configure ACL Permissions
  hosts: webservers
  become: yes
  vars:
    acl_configurations:
      # Web application directory ACLs
      - path: /opt/projects/web-app
        acls:
          - entity: alice
            etype: user
            permissions: rwx
          - entity: developers
            etype: group
            permissions: rwx
          - entity: testers
            etype: group
            permissions: r-x
          - entity: admins
            etype: group
            permissions: rwx

      # Testing directory ACLs
      - path: /opt/projects/testing
        acls:
          - entity: bob
            etype: user
            permissions: rwx
          - entity: testers
            etype: group
            permissions: rwx
          - entity: developers
            etype: group
            permissions: r-x
          - entity: admins
            etype: group
            permissions: rwx

      # Admin directory ACLs
      - path: /opt/projects/admin
        acls:
          - entity: charlie
            etype: user
            permissions: rwx
          - entity: admins
            etype: group
            permissions: rwx
          - entity: alice
            etype: user
            permissions: r-x

    default_acl_configurations:
      # Default ACLs for new files/directories
      - path: /opt/projects/web-app
        default_acls:
          - entity: developers
            etype: group
            permissions: rwx
          - entity: testers
            etype: group
            permissions: r-x

  tasks:
    - name: Set ACL permissions on directories
      acl:
        path: "{{ item.0.path }}"
        entity: "{{ item.1.entity }}"
        etype: "{{ item.1.etype }}"
        permissions: "{{ item.1.permissions }}"
        state: present
      with_subelements:
        - "{{ acl_configurations }}"
        - acls
      tags: acl_permissions

    - name: Set default ACL permissions
      acl:
        path: "{{ item.0.path }}"
        entity: "{{ item.1.entity }}"
        etype: "{{ item.1.etype }}"
        permissions: "{{ item.1.permissions }}"
        default: yes
        state: present
      with_subelements:
        - "{{ default_acl_configurations }}"
        - default_acls
      tags: default_acls

    - name: Create shared workspace with specific ACLs
      file:
        path: /opt/shared-workspace
        state: directory
        owner: root
        group: root
        mode: '0755'
      tags: shared_workspace

    - name: Configure shared workspace ACLs
      acl:
        path: /opt/shared-workspace
        entity: "{{ item.entity }}"
        etype: "{{ item.etype }}"
        permissions: "{{ item.permissions }}"
        state: present
      loop:
        - { entity: developers, etype: group, permissions: rwx }
        - { entity: testers, etype: group, permissions: rwx }
        - { entity: admins, etype: group, permissions: rwx }
        - { entity: alice, etype: user, permissions: rwx }
        - { entity: bob, etype: user, permissions: rwx }
        - { entity: charlie, etype: user, permissions: rwx }
      tags: shared_workspace

    - name: Remove specific ACL entries (example)
      acl:
        path: /opt/projects/admin
        entity: bob
        etype: user
        state: absent
      tags: remove_acl
EOF
Subtask 3.3: Create ACL Verification Playbook
Create a playbook to verify and display ACL configurations:

cat > verify-acls.yml << 'EOF'
---
- name: Verify ACL Configurations
  hosts: webservers
  become: yes
  vars:
    paths_to_check:
      - /opt/projects/web-app
      - /opt/projects/testing
      - /opt/projects/admin
      - /opt/shared-workspace

  tasks:
    - name: Check ACL permissions on directories
      shell: getfacl {{ item }}
      register: acl_output
      loop: "{{ paths_to_check }}"
      tags: verify_acls

    - name: Display ACL information
      debug:
        msg: |
          ACL for {{ item.item }}:
          {{ item.stdout }}
      loop: "{{ acl_output.results }}"
      tags: verify_acls

    - name: Test file creation with ACLs
      file:
        path: "{{ item }}/test-acl-file.txt"
        state: touch
        owner: alice
        group: developers
      loop:
        - /opt/projects/web-app
        - /opt/shared-workspace
      tags: test_acls

    - name: Verify effective permissions
      shell: |
        echo "Testing access for user alice to {{ item }}:"
        sudo -u alice test -r {{ item }} && echo "Read: OK" || echo "Read: DENIED"
        sudo -u alice test -w {{ item }} && echo "Write: OK" || echo "Write: DENIED"
        sudo -u alice test -x {{ item }} && echo "Execute: OK" || echo "Execute: DENIED"
      register: permission_test
      loop: "{{ paths_to_check }}"
      tags: test_permissions

    - name: Display permission test results
      debug:
        msg: "{{ item.stdout_lines }}"
      loop: "{{ permission_test.results }}"
      tags: test_permissions
EOF
Subtask 3.4: Execute ACL Configuration
Run the ACL setup and configuration playbooks:

# Setup directory structure
ansible-playbook -i inventory acl-setup.yml

# Configure ACL permissions
ansible-playbook -i inventory acl-permissions.yml

# Verify ACL configurations
ansible-playbook -i inventory verify-acls.yml --tags verify_acls
Subtask 3.5: Manual ACL Verification
Perform manual verification of ACL configurations:

# Check ACLs on all configured directories
for dir in /opt/projects/web-app /opt/projects/testing /opt/projects/admin /opt/shared-workspace; do
    echo "=== ACL for $dir ==="
    getfacl $dir
    echo
done

# Test user access
echo "Testing alice's access to web-app directory:"
sudo -u alice ls -la /opt/projects/web-app/

echo "Testing bob's access to testing directory:"
sudo -u bob ls -la /opt/projects/testing/
Troubleshooting Common Issues
Issue 1: Permission Denied Errors
Problem: Users cannot access directories despite ACL configuration.

Solution:

# Check if ACL is enabled on the filesystem
mount | grep acl

# If not enabled, remount with ACL support
sudo mount -o remount,acl /
Issue 2: Encrypted Password Not Working
Problem: Users cannot login with the configured password.

Solution:

# Generate a new encrypted password
python3 -c "import crypt; print(crypt.crypt('newpassword', crypt.mksalt(crypt.METHOD_SHA512)))"

# Update the playbook with the new encrypted password and re-run
Issue 3: Group Membership Not Applied
Problem: Users are not showing up in secondary groups.

Solution:

# Check current group membership
groups username

# Force group membership update
sudo usermod -a -G groupname username

# Verify the change
groups username
Issue 4: ACL Module Not Found
Problem: Ansible cannot find the ACL module.

Solution:

# Install ACL utilities
sudo yum install acl -y  # For RHEL/CentOS
# or
sudo apt-get install acl -y  # For Ubuntu/Debian

# Verify ACL support
which setfacl getfacl
Best Practices and Security Considerations
Security Best Practices
Password Management:

Always use encrypted passwords in playbooks
Implement strong password policies
Force password changes on first login
Set appropriate password expiration dates
ACL Management:

Follow the principle of least privilege
Regularly audit ACL permissions
Use groups instead of individual user ACLs when possible
Document ACL configurations
Playbook Security:

Store sensitive data in Ansible Vault
Use variables for reusable configurations
Implement proper error handling
Tag tasks for selective execution
Performance Optimization
# Create an optimized playbook with error handling
cat > optimized-user-management.yml << 'EOF'
---
- name: Optimized User and Group Management
  hosts: webservers
  become: yes
  gather_facts: yes
  vars:
    ansible_ssh_pipelining: true
    
  tasks:
    - name: Ensure required packages are installed
      package:
        name:
          - shadow-utils
          - acl
          - passwd
        state: present
      tags: packages

    - name: Create groups in batch
      group:
        name: "{{ item.name }}"
        gid: "{{ item.gid | default(omit) }}"
        state: present
      loop: "{{ user_groups }}"
      register: group_creation
      failed_when: false
      tags: groups

    - name: Report group creation results
      debug:
        msg: "Group {{ item.item.name }}: {{ 'Created' if item.changed else 'Already exists' }}"
      loop: "{{ group_creation.results }}"
      tags: groups

    - name: Create users with error handling
      user:
        name: "{{ item.username }}"
        comment: "{{ item.full_name }}"
        group: "{{ item.primary_group }}"
        groups: "{{ item.secondary_groups | join(',') if item.secondary_groups else omit }}"
        shell: "{{ item.shell }}"
        create_home: "{{ item.create_home }}"
        password: "{{ item.password }}"
        state: present
      loop: "{{ system_users }}"
      register: user_creation
      failed_when: false
      tags: users

    - name: Report user creation results
      debug:
        msg: "User {{ item.item.username }}: {{ 'Created' if item.changed else 'Already exists' }}"
      loop: "{{ user_creation.results }}"
      tags: users
EOF
Conclusion
In this lab, you have successfully accomplished the following:

Key Achievements
Automated User Management: Created comprehensive Ansible playbooks that automate the creation of multiple users and groups, eliminating manual configuration errors and saving significant administrative time.

Password Policy Implementation: Configured sophisticated password policies including expiration dates, aging parameters, and complexity requirements that align with enterprise security standards.

Advanced Permission Management: Implemented Access Control Lists (ACLs) to provide granular file and directory permissions beyond traditional Unix permissions, enabling more flexible security models.

Infrastructure as Code: Developed reusable, version-controlled automation scripts that can be easily modified and deployed across multiple systems.

Why This Matters
For System Administrators: These skills are essential for managing large-scale Linux environments where manual user management becomes impractical and error-prone. Automation ensures consistency and compliance with security policies.

For DevOps Engineers: User and permission automation is a critical component of Infrastructure as Code (IaC) practices, enabling rapid environment provisioning and maintaining security standards across development, testing, and production systems.

For Security Professionals: Automated user management with proper ACLs and password policies helps maintain security compliance and reduces the risk of human error in permission assignments.

For RHCE Certification: This lab directly addresses key objectives in the Red Hat Certified Engineer exam, particularly around Ansible automation, user management, and system security configuration.

Next Steps
To further develop your skills:

Integrate with LDAP/Active Directory: Extend these playbooks to work with enterprise directory services
Implement Ansible Vault: Secure sensitive data like passwords using Ansible's encryption features
Create Custom Modules: Develop specialized Ansible modules for your organization's specific user management needs
Monitoring and Auditing: Add logging and monitoring capabilities to track user management changes
Role-Based Access Control: Implement more sophisticated RBAC systems using these foundational concepts
The automation techniques you've learned in this lab form the foundation for enterprise-scale system administration and are directly applicable to real-world scenarios in modern IT environments.
