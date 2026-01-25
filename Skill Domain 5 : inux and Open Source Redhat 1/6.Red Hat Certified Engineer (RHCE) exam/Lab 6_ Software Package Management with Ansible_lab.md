Lab 6: Software Package Management with Ansible
Objectives
By the end of this lab, you will be able to:

Automate software installation using Ansible playbooks and package management modules
Remove packages systematically through Ansible automation
Configure package repositories and manage GPG keys for secure package verification
Handle software dependencies automatically during package installation
Write reusable playbooks for consistent package management across multiple systems
Implement best practices for package management in enterprise environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and structure
Knowledge of Ansible fundamentals (inventory, playbooks, modules)
Understanding of package management concepts in Red Hat-based systems
Access to a text editor (vim, nano, or VS Code)
Technical Requirements:

Basic knowledge of yum/dnf package managers
Understanding of repository configuration
Familiarity with GPG key management concepts
Lab Environment Setup
Good News! Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab and you'll have access to:

Control Node: CentOS/RHEL 8+ with Ansible pre-installed
Managed Nodes: 2-3 target systems for package management
Network Configuration: All nodes properly configured for SSH connectivity
User Access: Sudo privileges on all systems
No need to build your own virtual machines or configure networking!

Task 1: Basic Package Installation and Removal
Subtask 1.1: Create Basic Package Management Playbook
First, let's create a simple playbook to install and remove packages using the dnf module.

Step 1: Create the lab directory structure

mkdir -p ~/ansible-lab6/playbooks
cd ~/ansible-lab6
Step 2: Create an inventory file

cat > inventory << EOF
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[databases]
node3 ansible_host=192.168.1.12

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Step 3: Create the basic package management playbook

cat > playbooks/package-management.yml << 'EOF'
---
- name: Basic Package Management with Ansible
  hosts: all
  become: yes
  vars:
    packages_to_install:
      - git
      - wget
      - curl
      - vim
    packages_to_remove:
      - telnet
      - rsh

  tasks:
    - name: Update package cache
      dnf:
        update_cache: yes
      when: ansible_os_family == "RedHat"

    - name: Install required packages
      dnf:
        name: "{{ packages_to_install }}"
        state: present
      register: install_result

    - name: Display installation results
      debug:
        msg: "Packages installed: {{ install_result.results | map(attribute='name') | list }}"
      when: install_result.changed

    - name: Remove unwanted packages
      dnf:
        name: "{{ packages_to_remove }}"
        state: absent
      register: remove_result

    - name: Display removal results
      debug:
        msg: "Packages removed: {{ remove_result.results | map(attribute='name') | list }}"
      when: remove_result.changed

    - name: Verify installed packages
      command: rpm -q {{ item }}
      loop: "{{ packages_to_install }}"
      register: verify_install
      failed_when: verify_install.rc != 0
      changed_when: false

    - name: Display verification results
      debug:
        msg: "{{ item.item }} is installed: {{ item.stdout }}"
      loop: "{{ verify_install.results }}"
EOF
Step 4: Run the basic package management playbook

ansible-playbook -i inventory playbooks/package-management.yml
Subtask 1.2: Advanced Package Management with Conditions
Create a more sophisticated playbook that handles different scenarios.

Step 1: Create an advanced package management playbook

cat > playbooks/advanced-package-management.yml << 'EOF'
---
- name: Advanced Package Management
  hosts: all
  become: yes
  vars:
    web_packages:
      - httpd
      - mod_ssl
      - php
      - php-mysql
    db_packages:
      - mariadb-server
      - mariadb
      - python3-PyMySQL
    dev_packages:
      - gcc
      - make
      - kernel-devel

  tasks:
    - name: Install web server packages on webservers
      dnf:
        name: "{{ web_packages }}"
        state: present
      when: inventory_hostname in groups['webservers']
      notify: restart httpd

    - name: Install database packages on database servers
      dnf:
        name: "{{ db_packages }}"
        state: present
      when: inventory_hostname in groups['databases']
      notify: start mariadb

    - name: Install development tools on all servers
      dnf:
        name: "{{ dev_packages }}"
        state: present

    - name: Ensure specific package versions
      dnf:
        name: "git-2.39*"
        state: present
      ignore_errors: yes

    - name: Remove packages with dependencies
      dnf:
        name: sendmail
        state: absent
        autoremove: yes

  handlers:
    - name: restart httpd
      systemd:
        name: httpd
        state: restarted
        enabled: yes

    - name: start mariadb
      systemd:
        name: mariadb
        state: started
        enabled: yes
EOF
Step 2: Execute the advanced playbook

ansible-playbook -i inventory playbooks/advanced-package-management.yml
Task 2: Repository Management and GPG Key Configuration
Subtask 2.1: Add Custom Repositories
Step 1: Create a repository management playbook

cat > playbooks/repository-management.yml << 'EOF'
---
- name: Repository and GPG Key Management
  hosts: all
  become: yes
  vars:
    epel_gpg_key: "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8"
    remi_gpg_key: "https://rpms.remirepo.net/RPM-GPG-KEY-remi"

  tasks:
    - name: Import EPEL GPG key
      rpm_key:
        key: "{{ epel_gpg_key }}"
        state: present
      when: ansible_os_family == "RedHat"

    - name: Add EPEL repository
      dnf:
        name: epel-release
        state: present
      when: ansible_os_family == "RedHat"

    - name: Add custom repository with GPG key
      yum_repository:
        name: custom-repo
        description: Custom Repository for Lab
        baseurl: https://example.com/repo/el$releasever/$basearch/
        gpgcheck: yes
        gpgkey: https://example.com/repo/RPM-GPG-KEY-custom
        enabled: yes
        state: present
      ignore_errors: yes

    - name: Import custom GPG key
      rpm_key:
        key: https://example.com/repo/RPM-GPG-KEY-custom
        state: present
      ignore_errors: yes

    - name: Add Remi repository for PHP
      yum_repository:
        name: remi-php80
        description: Remi's PHP 8.0 RPM repository
        baseurl: https://rpms.remirepo.net/enterprise/8/php80/$basearch/
        gpgcheck: yes
        gpgkey: "{{ remi_gpg_key }}"
        enabled: no
        state: present

    - name: Import Remi GPG key
      rpm_key:
        key: "{{ remi_gpg_key }}"
        state: present

    - name: List all repositories
      command: dnf repolist all
      register: repo_list
      changed_when: false

    - name: Display repository information
      debug:
        var: repo_list.stdout_lines

    - name: Verify GPG keys are imported
      command: rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n'
      register: gpg_keys
      changed_when: false

    - name: Display imported GPG keys
      debug:
        var: gpg_keys.stdout_lines
EOF
Step 2: Run the repository management playbook

ansible-playbook -i inventory playbooks/repository-management.yml
Subtask 2.2: Repository Configuration with Templates
Step 1: Create a repository template

mkdir -p templates
cat > templates/custom.repo.j2 << 'EOF'
[{{ repo_name }}]
name={{ repo_description }}
baseurl={{ repo_baseurl }}
enabled={{ repo_enabled | default(1) }}
gpgcheck={{ repo_gpgcheck | default(1) }}
{% if repo_gpgkey is defined %}
gpgkey={{ repo_gpgkey }}
{% endif %}
{% if repo_priority is defined %}
priority={{ repo_priority }}
{% endif %}
EOF
Step 2: Create a playbook using the template

cat > playbooks/template-repository.yml << 'EOF'
---
- name: Configure Repositories Using Templates
  hosts: all
  become: yes
  vars:
    repositories:
      - name: "custom-app"
        description: "Custom Application Repository"
        baseurl: "https://repo.example.com/el8/$basearch/"
        gpgkey: "https://repo.example.com/RPM-GPG-KEY-custom"
        enabled: 1
        gpgcheck: 1
        priority: 10
      - name: "testing-repo"
        description: "Testing Repository"
        baseurl: "https://test.example.com/el8/$basearch/"
        enabled: 0
        gpgcheck: 0

  tasks:
    - name: Create repository files from template
      template:
        src: custom.repo.j2
        dest: "/etc/yum.repos.d/{{ item.name }}.repo"
        owner: root
        group: root
        mode: '0644'
      loop: "{{ repositories }}"
      vars:
        repo_name: "{{ item.name }}"
        repo_description: "{{ item.description }}"
        repo_baseurl: "{{ item.baseurl }}"
        repo_enabled: "{{ item.enabled }}"
        repo_gpgcheck: "{{ item.gpgcheck }}"
        repo_gpgkey: "{{ item.gpgkey | default(omit) }}"
        repo_priority: "{{ item.priority | default(omit) }}"

    - name: Update repository cache
      dnf:
        update_cache: yes

    - name: List configured repositories
      find:
        paths: /etc/yum.repos.d/
        patterns: "*.repo"
      register: repo_files

    - name: Display repository files
      debug:
        msg: "Repository file: {{ item.path }}"
      loop: "{{ repo_files.files }}"
EOF
Step 3: Execute the template-based repository configuration

ansible-playbook -i inventory playbooks/template-repository.yml
Task 3: Software Dependencies Management
Subtask 3.1: Install Software with Complex Dependencies
Step 1: Create a comprehensive dependency management playbook

cat > playbooks/dependency-management.yml << 'EOF'
---
- name: Software Dependencies Management
  hosts: all
  become: yes
  vars:
    lamp_stack:
      - httpd
      - mariadb-server
      - php
      - php-mysqlnd
      - php-gd
      - php-xml
      - php-mbstring
      - php-json
    development_tools:
      - "@Development Tools"
      - cmake
      - git
      - nodejs
      - npm
    python_packages:
      - python3
      - python3-pip
      - python3-devel
      - python3-virtualenv

  tasks:
    - name: Install LAMP stack with dependencies
      dnf:
        name: "{{ lamp_stack }}"
        state: present
      when: inventory_hostname in groups['webservers']

    - name: Install development tools group
      dnf:
        name: "{{ development_tools }}"
        state: present
      register: dev_tools_result

    - name: Install Python and related packages
      dnf:
        name: "{{ python_packages }}"
        state: present

    - name: Install pip packages with dependencies
      pip:
        name:
          - flask
          - requests
          - sqlalchemy
        state: present
        executable: pip3
      become_user: ansible

    - name: Install Node.js packages globally
      npm:
        name: "{{ item }}"
        global: yes
        state: present
      loop:
        - express
        - lodash
        - moment
      ignore_errors: yes

    - name: Check for broken dependencies
      command: dnf check
      register: dependency_check
      changed_when: false
      failed_when: false

    - name: Display dependency check results
      debug:
        var: dependency_check.stdout_lines
      when: dependency_check.stdout_lines | length > 0

    - name: Fix broken dependencies if any
      dnf:
        name: "*"
        state: latest
        update_only: yes
      when: dependency_check.rc != 0

    - name: Verify critical services can start
      systemd:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - httpd
        - mariadb
      when: inventory_hostname in groups['webservers']
      ignore_errors: yes
EOF
Step 2: Run the dependency management playbook

ansible-playbook -i inventory playbooks/dependency-management.yml
Subtask 3.2: Create a Package Management Role
Step 1: Create a reusable role structure

mkdir -p roles/package-manager/{tasks,vars,templates,handlers,defaults}
Step 2: Create role defaults

cat > roles/package-manager/defaults/main.yml << 'EOF'
---
# Default variables for package-manager role
package_manager_update_cache: true
package_manager_autoremove: true
package_manager_install_recommends: true

# Default packages to install
default_packages:
  - curl
  - wget
  - git
  - vim

# Default packages to remove
unwanted_packages:
  - telnet
  - rsh-server

# Repository configuration
enable_epel: true
enable_custom_repos: false
custom_repositories: []
EOF
Step 3: Create role tasks

cat > roles/package-manager/tasks/main.yml << 'EOF'
---
- name: Update package cache
  dnf:
    update_cache: "{{ package_manager_update_cache }}"
  when: ansible_os_family == "RedHat"

- name: Import EPEL GPG key
  rpm_key:
    key: https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8
    state: present
  when: enable_epel and ansible_os_family == "RedHat"

- name: Install EPEL repository
  dnf:
    name: epel-release
    state: present
  when: enable_epel and ansible_os_family == "RedHat"

- name: Configure custom repositories
  yum_repository:
    name: "{{ item.name }}"
    description: "{{ item.description }}"
    baseurl: "{{ item.baseurl }}"
    gpgcheck: "{{ item.gpgcheck | default(true) }}"
    gpgkey: "{{ item.gpgkey | default(omit) }}"
    enabled: "{{ item.enabled | default(true) }}"
    state: present
  loop: "{{ custom_repositories }}"
  when: enable_custom_repos

- name: Install default packages
  dnf:
    name: "{{ default_packages }}"
    state: present

- name: Install role-specific packages
  dnf:
    name: "{{ role_packages | default([]) }}"
    state: present
  when: role_packages is defined

- name: Remove unwanted packages
  dnf:
    name: "{{ unwanted_packages }}"
    state: absent
    autoremove: "{{ package_manager_autoremove }}"

- name: Clean package cache
  command: dnf clean all
  changed_when: false
EOF
Step 4: Create role handlers

cat > roles/package-manager/handlers/main.yml << 'EOF'
---
- name: update package cache
  dnf:
    update_cache: yes
EOF
Step 5: Create a playbook using the role

cat > playbooks/role-based-package-management.yml << 'EOF'
---
- name: Package Management Using Roles
  hosts: webservers
  become: yes
  vars:
    role_packages:
      - httpd
      - mod_ssl
      - php
      - php-mysql
    custom_repositories:
      - name: "nginx-stable"
        description: "nginx stable repo"
        baseurl: "http://nginx.org/packages/centos/$releasever/$basearch/"
        gpgkey: "https://nginx.org/keys/nginx_signing.key"
        gpgcheck: true
        enabled: false

  roles:
    - package-manager

  post_tasks:
    - name: Start and enable web services
      systemd:
        name: httpd
        state: started
        enabled: yes

- name: Package Management for Database Servers
  hosts: databases
  become: yes
  vars:
    role_packages:
      - mariadb-server
      - mariadb
      - python3-PyMySQL

  roles:
    - package-manager

  post_tasks:
    - name: Start and enable database service
      systemd:
        name: mariadb
        state: started
        enabled: yes
EOF
Step 6: Execute the role-based playbook

ansible-playbook -i inventory playbooks/role-based-package-management.yml
Task 4: Package Management Best Practices and Troubleshooting
Subtask 4.1: Implement Package Management Best Practices
Step 1: Create a comprehensive best practices playbook

cat > playbooks/package-best-practices.yml << 'EOF'
---
- name: Package Management Best Practices
  hosts: all
  become: yes
  vars:
    security_packages:
      - aide
      - fail2ban
      - firewalld
    monitoring_packages:
      - htop
      - iotop
      - nethogs
      - tcpdump

  tasks:
    - name: Create package management log directory
      file:
        path: /var/log/ansible-package-management
        state: directory
        owner: root
        group: root
        mode: '0755'

    - name: Check system resources before package operations
      setup:
        filter: ansible_memory_mb
      register: system_memory

    - name: Verify sufficient disk space
      setup:
        filter: ansible_mounts
      register: disk_info

    - name: Display system resources
      debug:
        msg: |
          Available Memory: {{ ansible_memory_mb.real.free }} MB
          Root Partition Free: {{ (ansible_mounts | selectattr('mount', 'equalto', '/') | first).size_available | human_readable }}

    - name: Create package backup before major changes
      command: rpm -qa --qf "%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n"
      register: installed_packages
      changed_when: false

    - name: Save package list to file
      copy:
        content: "{{ installed_packages.stdout }}"
        dest: "/var/log/ansible-package-management/packages-{{ ansible_date_time.epoch }}.txt"
        owner: root
        group: root
        mode: '0644'

    - name: Install security packages with verification
      dnf:
        name: "{{ security_packages }}"
        state: present
        validate_certs: yes
      register: security_install

    - name: Install monitoring packages
      dnf:
        name: "{{ monitoring_packages }}"
        state: present
      register: monitoring_install

    - name: Verify package integrity after installation
      command: rpm -V {{ item }}
      loop: "{{ security_packages + monitoring_packages }}"
      register: package_verification
      failed_when: package_verification.rc not in [0, 1]
      changed_when: false

    - name: Display verification results
      debug:
        msg: "Package {{ item.item }} verification: {{ 'PASSED' if item.rc == 0 else 'WARNINGS' }}"
      loop: "{{ package_verification.results }}"

    - name: Check for available security updates
      dnf:
        list: updates
        security: yes
      register: security_updates

    - name: Display available security updates
      debug:
        msg: "Security updates available: {{ security_updates.results | length }}"

    - name: Create package management report
      template:
        src: package-report.j2
        dest: "/var/log/ansible-package-management/report-{{ ansible_date_time.date }}.txt"
        owner: root
        group: root
        mode: '0644'
      vars:
        report_date: "{{ ansible_date_time.iso8601 }}"
        installed_security: "{{ security_install.results | default([]) }}"
        installed_monitoring: "{{ monitoring_install.results | default([]) }}"
        verification_results: "{{ package_verification.results | default([]) }}"
EOF
Step 2: Create the report template

cat > templates/package-report.j2 << 'EOF'
Package Management Report
Generated: {{ report_date }}
Host: {{ inventory_hostname }}

=== SYSTEM INFORMATION ===
OS Family: {{ ansible_os_family }}
Distribution: {{ ansible_distribution }} {{ ansible_distribution_version }}
Architecture: {{ ansible_architecture }}
Available Memory: {{ ansible_memory_mb.real.free }} MB

=== INSTALLED PACKAGES ===
Security Packages:
{% for result in installed_security %}
  - {{ result.name | default('N/A') }}: {{ result.state | default('N/A') }}
{% endfor %}

Monitoring Packages:
{% for result in installed_monitoring %}
  - {{ result.name | default('N/A') }}: {{ result.state | default('N/A') }}
{% endfor %}

=== VERIFICATION RESULTS ===
{% for result in verification_results %}
Package: {{ result.item }}
Status: {{ 'PASSED' if result.rc == 0 else 'WARNINGS' }}
{% if result.stdout %}
Output: {{ result.stdout }}
{% endif %}
{% endfor %}

=== RECOMMENDATIONS ===
- Regular security updates should be applied
- Package integrity should be verified periodically
- System resources should be monitored
- Package installation logs should be reviewed regularly
EOF
Step 3: Run the best practices playbook

ansible-playbook -i inventory playbooks/package-best-practices.yml
Subtask 4.2: Troubleshooting and Recovery
Step 1: Create a troubleshooting playbook

cat > playbooks/package-troubleshooting.yml << 'EOF'
---
- name: Package Management Troubleshooting
  hosts: all
  become: yes
  vars:
    troubleshoot_packages:
      - httpd
      - mariadb-server
      - php

  tasks:
    - name: Check for package manager locks
      stat:
        path: /var/lib/rpm/.rpm.lock
      register: rpm_lock

    - name: Display lock status
      debug:
        msg: "RPM database is {{ 'LOCKED' if rpm_lock.stat.exists else 'AVAILABLE' }}"

    - name: Check RPM database integrity
      command: rpm --rebuilddb
      register: rebuild_result
      changed_when: false
      failed_when: false

    - name: Verify package manager functionality
      dnf:
        list: installed
      register: dnf_test
      failed_when: false

    - name: Display package manager status
      debug:
        msg: "Package manager status: {{ 'WORKING' if dnf_test.rc == 0 else 'ERROR' }}"

    - name: Check for conflicting packages
      shell: |
        dnf list installed | grep -E "(conflict|obsolete)" || echo "No conflicts found"
      register: conflicts
      changed_when: false

    - name: Display conflict information
      debug:
        var: conflicts.stdout_lines

    - name: Attempt to fix broken dependencies
      command: dnf check
      register: dependency_check
      failed_when: false
      changed_when: false

    - name: Fix dependencies if broken
      dnf:
        name: "*"
        state: latest
        update_only: yes
      when: dependency_check.rc != 0

    - name: Verify specific package installations
      command: rpm -q {{ item }}
      loop: "{{ troubleshoot_packages }}"
      register: package_status
      failed_when: false
      changed_when: false

    - name: Display package status
      debug:
        msg: "{{ item.item }}: {{ 'INSTALLED' if item.rc == 0 else 'NOT INSTALLED' }}"
      loop: "{{ package_status.results }}"

    - name: Clean package cache and metadata
      command: "{{ item }}"
      loop:
        - dnf clean all
        - dnf makecache
      register: cleanup_result
      changed_when: false

    - name: Create recovery script
      copy:
        content: |
          #!/bin/bash
          # Package Management Recovery Script
          echo "Starting package management recovery..."
          
          # Clean package cache
          dnf clean all
          
          # Rebuild RPM database
          rpm --rebuilddb
          
          # Update package cache
          dnf makecache
          
          # Check for problems
          dnf check
          
          echo "Recovery script completed."
        dest: /usr/local/bin/package-recovery.sh
        owner: root
        group: root
        mode: '0755'

    - name: Test recovery script
      command: /usr/local/bin/package-recovery.sh
      register: recovery_test
      changed_when: false

    - name: Display recovery results
      debug:
        var: recovery_test.stdout_lines
EOF
Step 2: Execute the troubleshooting playbook

ansible-playbook -i inventory playbooks/package-troubleshooting.yml
Verification and Testing
Final Verification Playbook
Create a comprehensive verification playbook to ensure all tasks completed successfully:

cat > playbooks/final-verification.yml << 'EOF'
---
- name: Final Package Management Verification
  hosts: all
  become: yes
  tasks:
    - name: Gather package facts
      package_facts:
        manager: auto

    - name: Verify essential packages are installed
      assert:
        that:
          - "'git' in ansible_facts.packages"
          - "'wget' in ansible_facts.packages"
          - "'curl' in ansible_facts.packages"
        fail_msg: "Essential packages are missing"
        success_msg: "All essential packages are installed"

    - name: Check repository configuration
      find:
        paths: /etc/yum.repos.d/
        patterns: "*.repo"
      register: repo_files

    - name: Verify repositories are configured
      debug:
        msg: "Found {{ repo_files.files | length }} repository files"

    - name: Test package manager functionality
      dnf:
        list: updates
      register: updates_check

    - name: Display verification summary
      debug:
        msg: |
          === PACKAGE MANAGEMENT VERIFICATION COMPLETE ===
          - Essential packages: INSTALLED
          - Repository files: {{ repo_files.files | length }} found
          - Package manager: FUNCTIONAL
          - Available updates: {{ updates_check.results | length }}
EOF
Run the final verification:

ansible-playbook -i inventory playbooks/final-verification.yml
Conclusion
Congratulations! You have successfully completed Lab 6: Software Package Management with Ansible. Throughout this comprehensive lab, you have accomplished the following:

Key Achievements
Package Management Mastery:

Automated software installation and removal using Ansible's dnf/yum modules
Implemented conditional package installation based on host groups and system requirements
Managed complex software dependencies and package groups effectively
Repository and Security Configuration:

Added and configured custom software repositories
Implemented GPG key management for secure package verification
Created reusable repository templates for consistent configuration
Advanced Automation Techniques:

Developed reusable roles for package management
Implemented best practices for enterprise package management
Created comprehensive troubleshooting and recovery procedures
Real-World Applications:

Built LAMP stack installations with proper dependency handling
Configured development environments with multiple package sources
Implemented security-focused package management with verification
Why This Matters
Package management automation is crucial in modern IT infrastructure because it:

Ensures Consistency: Identical software configurations across all systems
Reduces Human Error: Automated processes eliminate manual installation mistakes
Improves Security: Systematic updates and GPG verification protect against vulnerabilities
Saves Time: Bulk operations across multiple systems happen simultaneously
Enables Compliance: Standardized software versions meet regulatory requirements
Next Steps
With these skills, you're well-prepared for:

Red Hat Certified Engineer (RHCE) exam objectives related to package management
Enterprise automation projects requiring software deployment
Infrastructure as Code implementations using Ansible
DevOps practices involving automated software lifecycle management
The automation techniques you've learned here form the foundation for managing software at scale in production environments, making you a valuable asset in any organization using Red Hat-based systems.
