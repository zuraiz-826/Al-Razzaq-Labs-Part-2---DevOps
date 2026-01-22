Lab 12: User and Group Management
Objectives
By the end of this lab, students will be able to:

• Create and manage user accounts using Ansible user module • Create and manage groups using Ansible group module • Modify user properties including shell, groups, and home directories • Understand the relationship between users and groups in Linux systems • Write Ansible playbooks for automated user and group management • Apply best practices for user account management in enterprise environments

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with YAML syntax and structure • Basic knowledge of Ansible concepts (playbooks, tasks, modules) • Understanding of Linux file permissions and ownership concepts • Access to a text editor (nano, vim, or similar)

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes: • CentOS/RHEL-based Linux system with Ansible pre-installed • Root access for administrative tasks • All necessary tools and utilities pre-configured

Task 1: Create Users and Groups Using Ansible Modules
Subtask 1.1: Create a Basic Inventory File
First, we'll create an inventory file to define our target hosts.

Create a new directory for your lab work:
mkdir ~/lab12-user-management
cd ~/lab12-user-management
Create an inventory file:
nano inventory.ini
Add the following content to the inventory file:
[local]
localhost ansible_connection=local

[webservers]
localhost ansible_connection=local
Save and exit the file (Ctrl+X, then Y, then Enter in nano).
Subtask 1.2: Create Groups Using the Group Module
Let's start by creating several groups that we'll use for organizing our users.

Create a playbook for group management:
nano create-groups.yml
Add the following content:
---
- name: Create Groups for User Management
  hosts: local
  become: yes
  tasks:
    - name: Create developers group
      group:
        name: developers
        state: present
        gid: 3001

    - name: Create testers group
      group:
        name: testers
        state: present
        gid: 3002

    - name: Create managers group
      group:
        name: managers
        state: present
        gid: 3003

    - name: Create contractors group
      group:
        name: contractors
        state: present
        gid: 3004

    - name: Display created groups
      shell: getent group | grep -E "(developers|testers|managers|contractors)"
      register: group_info

    - name: Show group information
      debug:
        msg: "{{ group_info.stdout_lines }}"
Save and exit the file.

Run the playbook to create the groups:

ansible-playbook -i inventory.ini create-groups.yml
Verify the groups were created:
getent group | grep -E "(developers|testers|managers|contractors)"
Subtask 1.3: Create Users Using the User Module
Now we'll create users and assign them to the groups we just created.

Create a playbook for user creation:
nano create-users.yml
Add the following comprehensive user creation playbook:
---
- name: Create Users with Different Configurations
  hosts: local
  become: yes
  tasks:
    - name: Create developer user - alice
      user:
        name: alice
        comment: "Alice Johnson - Senior Developer"
        uid: 2001
        group: developers
        groups: developers
        shell: /bin/bash
        home: /home/alice
        create_home: yes
        state: present

    - name: Create developer user - bob
      user:
        name: bob
        comment: "Bob Smith - Junior Developer"
        uid: 2002
        group: developers
        groups: developers
        shell: /bin/bash
        home: /home/bob
        create_home: yes
        state: present

    - name: Create tester user - carol
      user:
        name: carol
        comment: "Carol Davis - QA Tester"
        uid: 2003
        group: testers
        groups: testers
        shell: /bin/bash
        home: /home/carol
        create_home: yes
        state: present

    - name: Create manager user - david
      user:
        name: david
        comment: "David Wilson - Project Manager"
        uid: 2004
        group: managers
        groups: managers,developers,testers
        shell: /bin/bash
        home: /home/david
        create_home: yes
        state: present

    - name: Create contractor user - eve
      user:
        name: eve
        comment: "Eve Brown - External Contractor"
        uid: 2005
        group: contractors
        groups: contractors
        shell: /bin/sh
        home: /home/eve
        create_home: yes
        state: present

    - name: Display created users
      shell: getent passwd | grep -E "(alice|bob|carol|david|eve)"
      register: user_info

    - name: Show user information
      debug:
        msg: "{{ user_info.stdout_lines }}"
Save and exit the file.

Run the playbook to create the users:

ansible-playbook -i inventory.ini create-users.yml
Verify the users were created:
getent passwd | grep -E "(alice|bob|carol|david|eve)"
Task 2: Modify Users' Shell, Groups, and Home Directories
Subtask 2.1: Modify User Shells
Different users may require different shells based on their roles and requirements.

Create a playbook to modify user shells:
nano modify-shells.yml
Add the following content:
---
- name: Modify User Shells
  hosts: local
  become: yes
  tasks:
    - name: Change alice's shell to zsh (if available)
      user:
        name: alice
        shell: /bin/zsh
      ignore_errors: yes

    - name: Fallback - Change alice's shell to bash if zsh not available
      user:
        name: alice
        shell: /bin/bash
      when: ansible_failed_result is defined

    - name: Change eve's shell to restricted shell
      user:
        name: eve
        shell: /bin/sh

    - name: Change bob's shell to bash (confirm it's bash)
      user:
        name: bob
        shell: /bin/bash

    - name: Install zsh if not present
      package:
        name: zsh
        state: present
      ignore_errors: yes

    - name: Change alice's shell to zsh after installation
      user:
        name: alice
        shell: /bin/zsh

    - name: Display current shell information for all users
      shell: getent passwd | grep -E "(alice|bob|carol|david|eve)" | cut -d: -f1,7
      register: shell_info

    - name: Show shell information
      debug:
        msg: "User shells: {{ shell_info.stdout_lines }}"
Save and exit the file.

Run the playbook:

ansible-playbook -i inventory.ini modify-shells.yml
Subtask 2.2: Modify User Group Memberships
Let's modify group memberships to reflect changing organizational needs.

Create a playbook for group modifications:
nano modify-groups.yml
Add the following content:
---
- name: Modify User Group Memberships
  hosts: local
  become: yes
  tasks:
    - name: Add alice to testers group (cross-functional role)
      user:
        name: alice
        groups: developers,testers
        append: yes

    - name: Add bob to a temporary project group
      group:
        name: project-alpha
        state: present
        gid: 3005

    - name: Add bob to project-alpha group
      user:
        name: bob
        groups: developers,project-alpha
        append: yes

    - name: Remove eve from contractors and add to developers (conversion)
      user:
        name: eve
        groups: developers
        append: no

    - name: Create a special admin group
      group:
        name: sysadmins
        state: present
        gid: 3006

    - name: Add david to sysadmins group
      user:
        name: david
        groups: managers,developers,testers,sysadmins
        append: no

    - name: Display group memberships
      shell: |
        for user in alice bob carol david eve; do
          echo "User $user groups: $(groups $user)"
        done
      register: group_memberships

    - name: Show group membership information
      debug:
        msg: "{{ group_memberships.stdout_lines }}"
Save and exit the file.

Run the playbook:

ansible-playbook -i inventory.ini modify-groups.yml
Subtask 2.3: Modify Home Directories
Sometimes users need their home directories moved or reconfigured.

Create a playbook for home directory modifications:
nano modify-home-dirs.yml
Add the following content:
---
- name: Modify User Home Directories
  hosts: local
  become: yes
  tasks:
    - name: Create custom home directory structure
      file:
        path: /opt/users
        state: directory
        mode: '0755'

    - name: Create new home directory for eve (contractor to employee)
      file:
        path: /opt/users/eve
        state: directory
        owner: eve
        group: developers
        mode: '0750'

    - name: Copy eve's existing home content to new location
      shell: |
        if [ -d /home/eve ]; then
          cp -r /home/eve/* /opt/users/eve/ 2>/dev/null || true
          cp -r /home/eve/.* /opt/users/eve/ 2>/dev/null || true
        fi
      ignore_errors: yes

    - name: Update eve's home directory
      user:
        name: eve
        home: /opt/users/eve
        move_home: yes

    - name: Create shared project directory
      file:
        path: /home/shared/project-alpha
        state: directory
        owner: root
        group: project-alpha
        mode: '0770'

    - name: Create symbolic link in bob's home to shared project
      file:
        src: /home/shared/project-alpha
        dest: /home/bob/project-alpha
        state: link
        owner: bob
        group: developers

    - name: Set proper permissions on alice's home directory
      file:
        path: /home/alice
        state: directory
        owner: alice
        group: developers
        mode: '0750'

    - name: Create development workspace in alice's home
      file:
        path: /home/alice/workspace
        state: directory
        owner: alice
        group: developers
        mode: '0755'

    - name: Display home directory information
      shell: |
        for user in alice bob carol david eve; do
          echo "User $user home: $(getent passwd $user | cut -d: -f6)"
          ls -ld $(getent passwd $user | cut -d: -f6) 2>/dev/null || echo "Directory not found"
        done
      register: home_info

    - name: Show home directory information
      debug:
        msg: "{{ home_info.stdout_lines }}"
Save and exit the file.

Run the playbook:

ansible-playbook -i inventory.ini modify-home-dirs.yml
Task 3: Advanced User Management Operations
Subtask 3.1: Create a Comprehensive User Management Playbook
Let's create a comprehensive playbook that demonstrates advanced user management techniques.

Create an advanced user management playbook:
nano advanced-user-management.yml
Add the following content:
---
- name: Advanced User Management Operations
  hosts: local
  become: yes
  vars:
    users_to_create:
      - name: frank
        comment: "Frank Miller - DevOps Engineer"
        uid: 2006
        primary_group: developers
        secondary_groups: ["sysadmins", "project-alpha"]
        shell: /bin/bash
        home_dir: /home/frank
      - name: grace
        comment: "Grace Lee - Security Analyst"
        uid: 2007
        primary_group: testers
        secondary_groups: ["sysadmins"]
        shell: /bin/bash
        home_dir: /home/grace

  tasks:
    - name: Create users from variable list
      user:
        name: "{{ item.name }}"
        comment: "{{ item.comment }}"
        uid: "{{ item.uid }}"
        group: "{{ item.primary_group }}"
        groups: "{{ item.secondary_groups | join(',') }}"
        shell: "{{ item.shell }}"
        home: "{{ item.home_dir }}"
        create_home: yes
        state: present
      loop: "{{ users_to_create }}"

    - name: Set password expiration for contractor accounts
      shell: chage -M 90 eve
      ignore_errors: yes

    - name: Lock temporarily unused accounts
      user:
        name: carol
        password_lock: yes

    - name: Create user-specific directories
      file:
        path: "/home/{{ item.name }}/{{ folder }}"
        state: directory
        owner: "{{ item.name }}"
        group: "{{ item.primary_group }}"
        mode: '0755'
      loop: "{{ users_to_create }}"
      loop_control:
        loop_var: item
      with_items:
        - Documents
        - Downloads
        - Projects
      vars:
        folder: "{{ item }}"

    - name: Generate user report
      shell: |
        echo "=== USER MANAGEMENT REPORT ===" > /tmp/user_report.txt
        echo "Date: $(date)" >> /tmp/user_report.txt
        echo "" >> /tmp/user_report.txt
        echo "Created Users:" >> /tmp/user_report.txt
        getent passwd | grep -E "(alice|bob|carol|david|eve|frank|grace)" >> /tmp/user_report.txt
        echo "" >> /tmp/user_report.txt
        echo "Created Groups:" >> /tmp/user_report.txt
        getent group | grep -E "(developers|testers|managers|contractors|project-alpha|sysadmins)" >> /tmp/user_report.txt

    - name: Display user report
      shell: cat /tmp/user_report.txt
      register: user_report

    - name: Show final user report
      debug:
        msg: "{{ user_report.stdout_lines }}"
Save and exit the file.

Run the advanced playbook:

ansible-playbook -i inventory.ini advanced-user-management.yml
Subtask 3.2: Verification and Testing
Let's create a verification playbook to ensure all our user management operations were successful.

Create a verification playbook:
nano verify-user-management.yml
Add the following content:
---
- name: Verify User and Group Management
  hosts: local
  become: yes
  tasks:
    - name: Check all created users exist
      shell: getent passwd {{ item }}
      register: user_check
      failed_when: user_check.rc != 0
      loop:
        - alice
        - bob
        - carol
        - david
        - eve
        - frank
        - grace

    - name: Check all created groups exist
      shell: getent group {{ item }}
      register: group_check
      failed_when: group_check.rc != 0
      loop:
        - developers
        - testers
        - managers
        - contractors
        - project-alpha
        - sysadmins

    - name: Verify user shells
      shell: getent passwd {{ item }} | cut -d: -f7
      register: shell_check
      loop:
        - alice
        - bob
        - eve
      
    - name: Display shell verification
      debug:
        msg: "User {{ item.item }} has shell: {{ item.stdout }}"
      loop: "{{ shell_check.results }}"

    - name: Check home directories exist
      stat:
        path: "{{ item }}"
      register: home_check
      loop:
        - /home/alice
        - /home/bob
        - /home/carol
        - /home/david
        - /opt/users/eve
        - /home/frank
        - /home/grace

    - name: Display home directory status
      debug:
        msg: "Directory {{ item.item }} exists: {{ item.stat.exists }}"
      loop: "{{ home_check.results }}"

    - name: Final verification summary
      debug:
        msg: 
          - "=== VERIFICATION COMPLETE ==="
          - "All users have been successfully created and configured"
          - "All groups have been established"
          - "User shells have been modified as requested"
          - "Home directories have been created and configured"
          - "Group memberships have been updated"
Save and exit the file.

Run the verification playbook:

ansible-playbook -i inventory.ini verify-user-management.yml
Troubleshooting Common Issues
Issue 1: Permission Denied Errors
If you encounter permission denied errors:

# Ensure you're running with sudo privileges
sudo ansible-playbook -i inventory.ini playbook-name.yml
Issue 2: User Already Exists
If a user already exists and you get conflicts:

- name: Remove existing user if needed
  user:
    name: username
    state: absent
    remove: yes
Issue 3: Group ID Conflicts
If you encounter GID conflicts:

# Check existing group IDs
getent group | sort -t: -k3 -n
Issue 4: Shell Not Available
If a shell is not available on the system:

# Check available shells
cat /etc/shells

# Install additional shells if needed
sudo yum install zsh  # For RHEL/CentOS
Key Concepts Summary
User Module Parameters: • name: Username • uid: User ID number • group: Primary group • groups: Secondary groups • shell: Login shell • home: Home directory path • create_home: Whether to create home directory • state: present/absent

Group Module Parameters: • name: Group name • gid: Group ID number • state: present/absent

Best Practices: • Use consistent UID/GID ranges for different user types • Always specify primary and secondary groups explicitly • Create home directories with appropriate permissions • Use descriptive comments for user accounts • Implement proper password policies • Regular auditing of user accounts and permissions

Conclusion
In this lab, you have successfully accomplished the following:

• Created users and groups using Ansible's user and group modules with proper configuration • Modified user properties including shells, group memberships, and home directories • Implemented advanced user management techniques using variables and loops • Applied enterprise-level practices for user account management • Verified configurations to ensure all changes were applied correctly

Why This Matters: User and group management is fundamental to Linux system administration and security. In enterprise environments, automated user management through Ansible ensures consistency, reduces errors, and saves significant time. The skills you've learned here are directly applicable to:

• Managing user accounts across multiple servers • Implementing role-based access control • Automating onboarding and offboarding processes • Maintaining security compliance • Scaling user management operations

These automation techniques are essential for Red Hat Enterprise Linux environments and form the foundation for more advanced system administration tasks. You now have the knowledge to manage users and groups efficiently using Ansible, which is a critical skill for Linux system administrators and DevOps engineers.
