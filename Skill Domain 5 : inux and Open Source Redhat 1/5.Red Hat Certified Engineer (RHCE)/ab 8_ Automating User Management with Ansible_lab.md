Lab 8: Automating User Management with Ansible
Objectives
By the end of this lab, students will be able to:

Create Ansible playbooks to automate user creation and removal
Configure user account attributes including passwords and expiration dates
Implement automated group membership management using Ansible
Apply best practices for user management automation in enterprise environments
Understand the security implications of automated user provisioning
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux user management concepts (users, groups, permissions)
Familiarity with YAML syntax and structure
Basic knowledge of Ansible concepts (playbooks, tasks, modules)
Understanding of SSH key-based authentication
Experience with command-line interface operations
Lab Environment Setup
Al Nafi Cloud Machines: This lab uses pre-configured Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your environment - no VM setup required.

Your lab environment includes:

Control Node: CentOS/RHEL 8 with Ansible pre-installed
Managed Nodes: Two target servers (node1 and node2) for user management
Pre-configured SSH connectivity between control and managed nodes
Sudo privileges on all systems
Task 1: Creating Basic User Management Playbooks
Subtask 1.1: Create Directory Structure and Inventory
First, let's set up our working directory and inventory file.

Connect to your control node and create the lab directory structure:
mkdir -p ~/ansible-user-lab/{playbooks,inventory,group_vars,host_vars}
cd ~/ansible-user-lab
Create the inventory file to define our managed hosts:
cat > inventory/hosts << EOF
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Test connectivity to ensure Ansible can reach the managed nodes:
ansible -i inventory/hosts all -m ping
Subtask 1.2: Create User Addition Playbook
Now we'll create a comprehensive playbook for adding users with various attributes.

Create the user addition playbook:
cat > playbooks/add_users.yml << 'EOF'
---
- name: Add Users to Managed Systems
  hosts: all
  become: yes
  vars:
    users_to_add:
      - username: john_doe
        full_name: "John Doe"
        shell: /bin/bash
        groups: ["users", "developers"]
        password: "$6$salt$encrypted_password_hash"
        expires: -1
        create_home: yes
      - username: jane_smith
        full_name: "Jane Smith"
        shell: /bin/bash
        groups: ["users", "admins"]
        password: "$6$salt$another_encrypted_hash"
        expires: 1735689600  # Unix timestamp for future date
        create_home: yes
      - username: temp_user
        full_name: "Temporary User"
        shell: /bin/bash
        groups: ["users"]
        password: "$6$salt$temp_password_hash"
        expires: 1672531200  # Unix timestamp for past date (expired)
        create_home: yes

  tasks:
    - name: Ensure required groups exist
      group:
        name: "{{ item }}"
        state: present
      loop:
        - users
        - developers
        - admins

    - name: Create users with specified attributes
      user:
        name: "{{ item.username }}"
        comment: "{{ item.full_name }}"
        shell: "{{ item.shell }}"
        groups: "{{ item.groups | join(',') }}"
        password: "{{ item.password }}"
        expires: "{{ item.expires }}"
        createhome: "{{ item.create_home }}"
        state: present
      loop: "{{ users_to_add }}"
      register: user_creation_result

    - name: Display user creation results
      debug:
        msg: "User {{ item.item.username }} created successfully"
      loop: "{{ user_creation_result.results }}"
      when: item.changed

    - name: Set up SSH directory for users
      file:
        path: "/home/{{ item.username }}/.ssh"
        state: directory
        owner: "{{ item.username }}"
        group: "{{ item.username }}"
        mode: '0700'
      loop: "{{ users_to_add }}"
      when: item.create_home

    - name: Create authorized_keys file for users
      file:
        path: "/home/{{ item.username }}/.ssh/authorized_keys"
        state: touch
        owner: "{{ item.username }}"
        group: "{{ item.username }}"
        mode: '0600'
      loop: "{{ users_to_add }}"
      when: item.create_home
EOF
Generate password hashes for the users (replace the placeholder hashes):
# Generate password hash for john_doe (password: johnpass123)
python3 -c "import crypt; print(crypt.crypt('johnpass123', crypt.mksalt(crypt.METHOD_SHA512)))"

# Generate password hash for jane_smith (password: janepass456)
python3 -c "import crypt; print(crypt.crypt('janepass456', crypt.mksalt(crypt.METHOD_SHA512)))"

# Generate password hash for temp_user (password: temppass789)
python3 -c "import crypt; print(crypt.crypt('temppass789', crypt.mksalt(crypt.METHOD_SHA512)))"
Update the playbook with the actual password hashes generated above.

Execute the user addition playbook:

ansible-playbook -i inventory/hosts playbooks/add_users.yml
Subtask 1.3: Create User Removal Playbook
Create a playbook to safely remove users from the system.

Create the user removal playbook:
cat > playbooks/remove_users.yml << 'EOF'
---
- name: Remove Users from Managed Systems
  hosts: all
  become: yes
  vars:
    users_to_remove:
      - username: temp_user
        remove_home: yes
        force_remove: yes
      - username: old_employee
        remove_home: no
        force_remove: no

  tasks:
    - name: Check if users exist before removal
      getent:
        database: passwd
        key: "{{ item.username }}"
      loop: "{{ users_to_remove }}"
      register: user_check
      failed_when: false

    - name: Display users found for removal
      debug:
        msg: "User {{ item.item.username }} exists and will be removed"
      loop: "{{ user_check.results }}"
      when: item.ansible_facts is defined

    - name: Backup user home directories before removal
      archive:
        path: "/home/{{ item.username }}"
        dest: "/tmp/{{ item.username }}_backup_{{ ansible_date_time.epoch }}.tar.gz"
        format: gz
      loop: "{{ users_to_remove }}"
      when: 
        - item.remove_home
        - user_check.results | selectattr('item.username', 'equalto', item.username) | selectattr('ansible_facts', 'defined') | list | length > 0

    - name: Remove users from system
      user:
        name: "{{ item.username }}"
        state: absent
        remove: "{{ item.remove_home }}"
        force: "{{ item.force_remove }}"
      loop: "{{ users_to_remove }}"
      register: user_removal_result

    - name: Display removal results
      debug:
        msg: "User {{ item.item.username }} removal status: {{ 'Success' if item.changed else 'User not found or already removed' }}"
      loop: "{{ user_removal_result.results }}"
EOF
Execute the user removal playbook:
ansible-playbook -i inventory/hosts playbooks/remove_users.yml
Task 2: Configuring Advanced User Account Attributes
Subtask 2.1: Password Policy and Expiration Management
Create a playbook that implements comprehensive password policies and account expiration.

Create the password policy playbook:
cat > playbooks/password_policy.yml << 'EOF'
---
- name: Configure Password Policies and Account Expiration
  hosts: all
  become: yes
  vars:
    password_policy_users:
      - username: security_admin
        full_name: "Security Administrator"
        password_max_age: 90
        password_min_age: 1
        password_warn_age: 7
        account_expires: "2024-12-31"
        must_change_password: yes
      - username: contractor
        full_name: "External Contractor"
        password_max_age: 30
        password_min_age: 1
        password_warn_age: 5
        account_expires: "2024-06-30"
        must_change_password: yes

  tasks:
    - name: Install required packages for password management
      package:
        name:
          - shadow-utils
          - passwd
        state: present

    - name: Create users with password policies
      user:
        name: "{{ item.username }}"
        comment: "{{ item.full_name }}"
        shell: /bin/bash
        groups: users
        password: "{{ '$6$salt$' + (item.username + 'defaultpass') | password_hash('sha512', 'salt') }}"
        state: present
        createhome: yes
      loop: "{{ password_policy_users }}"

    - name: Set password aging policies
      shell: |
        chage -M {{ item.password_max_age }} {{ item.username }}
        chage -m {{ item.password_min_age }} {{ item.username }}
        chage -W {{ item.password_warn_age }} {{ item.username }}
      loop: "{{ password_policy_users }}"
      register: chage_result

    - name: Set account expiration dates
      shell: |
        chage -E {{ item.account_expires }} {{ item.username }}
      loop: "{{ password_policy_users }}"
      when: item.account_expires is defined

    - name: Force password change on next login
      shell: |
        chage -d 0 {{ item.username }}
      loop: "{{ password_policy_users }}"
      when: item.must_change_password

    - name: Verify password policy settings
      shell: chage -l {{ item.username }}
      loop: "{{ password_policy_users }}"
      register: policy_verification

    - name: Display password policy verification
      debug:
        msg: "{{ item.stdout_lines }}"
      loop: "{{ policy_verification.results }}"
EOF
Execute the password policy playbook:
ansible-playbook -i inventory/hosts playbooks/password_policy.yml
Subtask 2.2: SSH Key Management for Users
Create a playbook to manage SSH keys for automated authentication.

Create the SSH key management playbook:
cat > playbooks/ssh_key_management.yml << 'EOF'
---
- name: Manage SSH Keys for Users
  hosts: all
  become: yes
  vars:
    ssh_key_users:
      - username: john_doe
        ssh_keys:
          - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7... john@workstation"
          - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... john@laptop"
      - username: jane_smith
        ssh_keys:
          - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD8... jane@desktop"

  tasks:
    - name: Ensure users exist
      user:
        name: "{{ item.username }}"
        state: present
      loop: "{{ ssh_key_users }}"

    - name: Ensure .ssh directory exists for users
      file:
        path: "/home/{{ item.username }}/.ssh"
        state: directory
        owner: "{{ item.username }}"
        group: "{{ item.username }}"
        mode: '0700'
      loop: "{{ ssh_key_users }}"

    - name: Add SSH public keys to authorized_keys
      authorized_key:
        user: "{{ item.0.username }}"
        key: "{{ item.1 }}"
        state: present
        manage_dir: yes
      with_subelements:
        - "{{ ssh_key_users }}"
        - ssh_keys

    - name: Set proper permissions on authorized_keys
      file:
        path: "/home/{{ item.username }}/.ssh/authorized_keys"
        owner: "{{ item.username }}"
        group: "{{ item.username }}"
        mode: '0600'
      loop: "{{ ssh_key_users }}"

    - name: Generate SSH key pairs for users (if needed)
      user:
        name: "{{ item.username }}"
        generate_ssh_key: yes
        ssh_key_bits: 2048
        ssh_key_file: "/home/{{ item.username }}/.ssh/id_rsa"
      loop: "{{ ssh_key_users }}"
EOF
Execute the SSH key management playbook:
ansible-playbook -i inventory/hosts playbooks/ssh_key_management.yml
Task 3: Automating Group Membership Management
Subtask 3.1: Dynamic Group Management
Create a comprehensive playbook for managing groups and user memberships.

Create the group management playbook:
cat > playbooks/group_management.yml << 'EOF'
---
- name: Comprehensive Group and Membership Management
  hosts: all
  become: yes
  vars:
    organizational_groups:
      - name: developers
        gid: 3001
        description: "Software Development Team"
        members: ["john_doe", "alice_dev", "bob_coder"]
      - name: sysadmins
        gid: 3002
        description: "System Administrators"
        members: ["jane_smith", "admin_user"]
      - name: database_admins
        gid: 3003
        description: "Database Administration Team"
        members: ["db_admin", "jane_smith"]
      - name: project_alpha
        gid: 3004
        description: "Project Alpha Team Members"
        members: ["john_doe", "jane_smith", "project_lead"]

    users_to_create:
      - username: alice_dev
        full_name: "Alice Developer"
        primary_group: developers
      - username: bob_coder
        full_name: "Bob Coder"
        primary_group: developers
      - username: admin_user
        full_name: "Admin User"
        primary_group: sysadmins
      - username: db_admin
        full_name: "Database Admin"
        primary_group: database_admins
      - username: project_lead
        full_name: "Project Lead"
        primary_group: project_alpha

  tasks:
    - name: Create organizational groups
      group:
        name: "{{ item.name }}"
        gid: "{{ item.gid }}"
        state: present
      loop: "{{ organizational_groups }}"

    - name: Create users with primary groups
      user:
        name: "{{ item.username }}"
        comment: "{{ item.full_name }}"
        group: "{{ item.primary_group }}"
        shell: /bin/bash
        createhome: yes
        password: "{{ '$6$salt$' + (item.username + 'pass123') | password_hash('sha512', 'salt') }}"
        state: present
      loop: "{{ users_to_create }}"

    - name: Add users to secondary groups
      user:
        name: "{{ item.1 }}"
        groups: "{{ item.0.name }}"
        append: yes
      with_subelements:
        - "{{ organizational_groups }}"
        - members
      ignore_errors: yes

    - name: Verify group memberships
      shell: groups {{ item.1 }}
      with_subelements:
        - "{{ organizational_groups }}"
        - members
      register: group_verification
      ignore_errors: yes

    - name: Display group membership verification
      debug:
        msg: "User {{ item.item.1 }} groups: {{ item.stdout }}"
      loop: "{{ group_verification.results }}"
      when: item.stdout is defined

    - name: Create group directories with proper permissions
      file:
        path: "/shared/{{ item.name }}"
        state: directory
        owner: root
        group: "{{ item.name }}"
        mode: '2775'
      loop: "{{ organizational_groups }}"

    - name: Set up sudo privileges for sysadmins group
      lineinfile:
        path: /etc/sudoers.d/sysadmins
        line: "%sysadmins ALL=(ALL) NOPASSWD: ALL"
        create: yes
        mode: '0440'
        validate: 'visudo -cf %s'
EOF
Execute the group management playbook:
ansible-playbook -i inventory/hosts playbooks/group_management.yml
Subtask 3.2: Role-Based Access Control Implementation
Create a playbook that implements role-based access control through group management.

Create the RBAC playbook:
cat > playbooks/rbac_implementation.yml << 'EOF'
---
- name: Implement Role-Based Access Control
  hosts: all
  become: yes
  vars:
    rbac_roles:
      - role_name: web_developers
        permissions:
          - "/var/www"
          - "/var/log/httpd"
        sudo_commands:
          - "/bin/systemctl restart httpd"
          - "/bin/systemctl reload httpd"
        members: ["john_doe", "alice_dev"]
      
      - role_name: database_operators
        permissions:
          - "/var/lib/mysql"
          - "/var/log/mysql"
        sudo_commands:
          - "/bin/systemctl restart mysqld"
          - "/usr/bin/mysql"
        members: ["db_admin", "jane_smith"]
      
      - role_name: system_monitors
        permissions:
          - "/var/log"
          - "/proc"
          - "/sys"
        sudo_commands:
          - "/bin/systemctl status *"
          - "/usr/bin/top"
          - "/usr/bin/htop"
        members: ["admin_user", "jane_smith"]

  tasks:
    - name: Create RBAC groups
      group:
        name: "{{ item.role_name }}"
        state: present
      loop: "{{ rbac_roles }}"

    - name: Add users to RBAC groups
      user:
        name: "{{ item.1 }}"
        groups: "{{ item.0.role_name }}"
        append: yes
      with_subelements:
        - "{{ rbac_roles }}"
        - members
      ignore_errors: yes

    - name: Create permission directories
      file:
        path: "{{ item.1 }}"
        state: directory
        owner: root
        group: "{{ item.0.role_name }}"
        mode: '2755'
      with_subelements:
        - "{{ rbac_roles }}"
        - permissions
      ignore_errors: yes

    - name: Configure sudo rules for RBAC roles
      template:
        src: rbac_sudo.j2
        dest: "/etc/sudoers.d/{{ item.role_name }}"
        mode: '0440'
        validate: 'visudo -cf %s'
      loop: "{{ rbac_roles }}"

    - name: Create RBAC sudo template
      copy:
        content: |
          # Sudo rules for {{ item.role_name }}
          %{{ item.role_name }} ALL=(ALL) NOPASSWD: {{ item.sudo_commands | join(', ') }}
        dest: "/etc/sudoers.d/{{ item.role_name }}"
        mode: '0440'
        validate: 'visudo -cf %s'
      loop: "{{ rbac_roles }}"

    - name: Verify RBAC implementation
      shell: |
        echo "=== {{ item.role_name }} Members ==="
        getent group {{ item.role_name }}
        echo "=== Sudo Rules ==="
        cat /etc/sudoers.d/{{ item.role_name }}
      loop: "{{ rbac_roles }}"
      register: rbac_verification

    - name: Display RBAC verification results
      debug:
        msg: "{{ item.stdout_lines }}"
      loop: "{{ rbac_verification.results }}"
EOF
Execute the RBAC implementation playbook:
ansible-playbook -i inventory/hosts playbooks/rbac_implementation.yml
Subtask 3.3: User Audit and Compliance Reporting
Create a playbook to generate comprehensive user and group audit reports.

Create the audit reporting playbook:
cat > playbooks/user_audit.yml << 'EOF'
---
- name: Generate User and Group Audit Reports
  hosts: all
  become: yes
  vars:
    audit_date: "{{ ansible_date_time.date }}"
    report_path: "/tmp/user_audit_{{ inventory_hostname }}_{{ audit_date }}.txt"

  tasks:
    - name: Gather system user information
      shell: |
        echo "=== SYSTEM USER AUDIT REPORT ===" > {{ report_path }}
        echo "Generated on: {{ ansible_date_time.iso8601 }}" >> {{ report_path }}
        echo "Hostname: {{ inventory_hostname }}" >> {{ report_path }}
        echo "" >> {{ report_path }}
        
        echo "=== ALL USERS ===" >> {{ report_path }}
        getent passwd | awk -F: '$3 >= 1000 {print $1 ":" $3 ":" $4 ":" $5 ":" $6 ":" $7}' >> {{ report_path }}
        echo "" >> {{ report_path }}
        
        echo "=== ALL GROUPS ===" >> {{ report_path }}
        getent group | awk -F: '$3 >= 1000 {print $1 ":" $3 ":" $4}' >> {{ report_path }}
        echo "" >> {{ report_path }}
        
        echo "=== USERS WITH SUDO ACCESS ===" >> {{ report_path }}
        grep -r "%" /etc/sudoers.d/ 2>/dev/null | grep -v "^#" >> {{ report_path }} || echo "No sudo rules found" >> {{ report_path }}
        echo "" >> {{ report_path }}
        
        echo "=== PASSWORD AGING INFORMATION ===" >> {{ report_path }}
        for user in $(getent passwd | awk -F: '$3 >= 1000 {print $1}'); do
          echo "User: $user" >> {{ report_path }}
          chage -l $user >> {{ report_path }}
          echo "---" >> {{ report_path }}
        done
        
        echo "=== FAILED LOGIN ATTEMPTS ===" >> {{ report_path }}
        lastb | head -20 >> {{ report_path }} 2>/dev/null || echo "No failed login records" >> {{ report_path }}
        
        echo "=== RECENT SUCCESSFUL LOGINS ===" >> {{ report_path }}
        last | head -20 >> {{ report_path }}

    - name: Generate group membership matrix
      shell: |
        echo "" >> {{ report_path }}
        echo "=== GROUP MEMBERSHIP MATRIX ===" >> {{ report_path }}
        for group in $(getent group | awk -F: '$3 >= 1000 {print $1}'); do
          echo "Group: $group" >> {{ report_path }}
          getent group $group | cut -d: -f4 | tr ',' '\n' | sed 's/^/  - /' >> {{ report_path }}
          echo "" >> {{ report_path }}
        done

    - name: Check for security compliance issues
      shell: |
        echo "=== SECURITY COMPLIANCE CHECKS ===" >> {{ report_path }}
        
        echo "Users with empty passwords:" >> {{ report_path }}
        awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow >> {{ report_path }}
        
        echo "" >> {{ report_path }}
        echo "Users with UID 0 (root privileges):" >> {{ report_path }}
        awk -F: '$3 == 0 {print $1}' /etc/passwd >> {{ report_path }}
        
        echo "" >> {{ report_path }}
        echo "Users with no home directory:" >> {{ report_path }}
        getent passwd | awk -F: '$3 >= 1000 && $6 !~ /^\/home/ {print $1 ":" $6}' >> {{ report_path }}
        
        echo "" >> {{ report_path }}
        echo "Accounts that never expire:" >> {{ report_path }}
        awk -F: '$8 == "" || $8 == "99999" {print $1}' /etc/shadow >> {{ report_path }}

    - name: Fetch audit reports to control node
      fetch:
        src: "{{ report_path }}"
        dest: "./audit_reports/"
        flat: yes

    - name: Display audit report summary
      shell: |
        echo "Audit report generated: {{ report_path }}"
        echo "Total users: $(getent passwd | awk -F: '$3 >= 1000' | wc -l)"
        echo "Total groups: $(getent group | awk -F: '$3 >= 1000' | wc -l)"
        echo "Users with sudo access: $(grep -r "%" /etc/sudoers.d/ 2>/dev/null | grep -v "^#" | wc -l)"
      register: audit_summary

    - name: Show audit summary
      debug:
        msg: "{{ audit_summary.stdout_lines }}"
EOF
Execute the audit reporting playbook:
ansible-playbook -i inventory/hosts playbooks/user_audit.yml
Review the generated audit reports:
ls -la audit_reports/
cat audit_reports/user_audit_node1_*.txt
Troubleshooting Common Issues
Issue 1: Permission Denied Errors
Problem: Ansible fails with permission denied errors when managing users.

Solution:

# Ensure the ansible user has sudo privileges
sudo visudo
# Add: ansible ALL=(ALL) NOPASSWD: ALL

# Verify sudo access
ansible -i inventory/hosts all -m shell -a "sudo whoami" --become
Issue 2: Password Hash Generation Failures
Problem: Users cannot login with generated password hashes.

Solution:

# Test password hash generation
python3 -c "import crypt; print(crypt.crypt('testpass', crypt.mksalt(crypt.METHOD_SHA512)))"

# Verify the hash works
sudo useradd testuser
echo 'testuser:generated_hash' | sudo chpasswd -e
Issue 3: Group Membership Not Applied
Problem: Users are not being added to specified groups.

Solution:

# Check if groups exist first
ansible -i inventory/hosts all -m shell -a "getent group developers"

# Verify user group membership
ansible -i inventory/hosts all -m shell -a "groups username"
Issue 4: SSH Key Authentication Issues
Problem: SSH keys are not working for user authentication.

Solution:

# Check SSH directory permissions
ansible -i inventory/hosts all -m shell -a "ls -la /home/username/.ssh/"

# Verify authorized_keys format
ansible -i inventory/hosts all -m shell -a "cat /home/username/.ssh/authorized_keys"
Best Practices and Security Considerations
Security Best Practices
Password Management:

Always use strong password hashes
Implement password aging policies
Force password changes for new accounts
SSH Key Management:

Use strong key types (RSA 2048+ or Ed25519)
Regularly rotate SSH keys
Implement key-based authentication where possible
Group Management:

Follow principle of least privilege
Regularly audit group memberships
Use role-based access control
Audit and Compliance:

Generate regular audit reports
Monitor failed login attempts
Track user account changes
Ansible Best Practices
Playbook Organization:

Use descriptive task names
Implement proper error handling
Use variables for reusability
Security:

Store sensitive data in Ansible Vault
Use become privileges judiciously
Validate sudo configurations
Testing:

Test playbooks in development environment
Use check mode for dry runs
Implement proper rollback procedures
Conclusion
In this comprehensive lab, you have successfully learned to automate user management tasks using Ansible. You have accomplished the following key objectives:

Technical Skills Developed:

Created sophisticated Ansible playbooks for user lifecycle management
Implemented automated password policies and account expiration controls
Developed role-based access control systems through group management
Built comprehensive audit and compliance reporting mechanisms
Practical Applications:

Enterprise User Provisioning: Your playbooks can now handle bulk user creation and removal across multiple systems simultaneously
Security Compliance: The password policies and audit reports ensure organizational security standards are maintained
Operational Efficiency: Automated group management reduces manual administrative overhead and human error
Real-World Impact: These automation skills are essential for modern IT operations, particularly in environments requiring:

Rapid user onboarding and offboarding
Consistent security policy enforcement
Regulatory compliance reporting
Scalable infrastructure management
Next Steps: Consider extending these concepts by integrating with identity management systems, implementing automated user lifecycle workflows, or developing custom Ansible modules for specialized user management requirements.

The automation techniques you've mastered in this lab form the foundation for advanced configuration management and are directly applicable to Red Hat Certified Engineer (RHCE) certification objectives and enterprise DevOps practices.
