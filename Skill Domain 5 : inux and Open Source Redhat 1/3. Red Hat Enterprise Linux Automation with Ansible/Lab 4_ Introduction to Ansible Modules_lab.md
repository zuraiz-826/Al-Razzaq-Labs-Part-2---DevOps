Lab 4: Introduction to Ansible Modules
Objectives
By the end of this lab, students will be able to:

• Understand what Ansible modules are and their purpose in automation • Use common Ansible modules including yum, apt, and service • Write Ansible tasks using these modules to manage packages and services • Create playbooks that automate package installation and service management • Troubleshoot common issues when working with Ansible modules • Apply best practices for module usage in real-world scenarios

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with YAML syntax and structure • Completion of previous Ansible labs covering inventory and basic playbook creation • Basic knowledge of package managers (yum/dnf for Red Hat-based systems, apt for Debian-based systems) • Understanding of Linux services and systemd

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or install software.

Your lab environment includes: • One Ansible control node (CentOS/RHEL-based) • Two managed nodes (one CentOS/RHEL-based, one Ubuntu-based) • Pre-installed Ansible on the control node • SSH connectivity already configured between nodes

Task 1: Understanding Ansible Modules
Subtask 1.1: Explore Available Modules
First, let's understand what modules are available in your Ansible installation.

Connect to your control node and verify Ansible installation:
ansible --version
List all available modules to see the extensive library:
ansible-doc -l | head -20
Get detailed information about specific modules we'll use:
ansible-doc yum
ansible-doc apt
ansible-doc service
Subtask 1.2: Verify Your Inventory
Check your inventory file to ensure managed nodes are properly configured:
cat /etc/ansible/hosts
Test connectivity to all managed nodes:
ansible all -m ping
Expected output should show SUCCESS for all nodes.

Task 2: Working with Package Management Modules
Subtask 2.1: Using the YUM Module
The yum module manages packages on Red Hat-based systems (CentOS, RHEL, Fedora).

Create a new playbook for package management:
mkdir -p ~/ansible-labs/lab4
cd ~/ansible-labs/lab4
nano package-management.yml
Add the following content to manage packages on CentOS/RHEL nodes:
---
- name: Package Management with YUM Module
  hosts: centos_nodes
  become: yes
  tasks:
    - name: Install git package
      yum:
        name: git
        state: present
    
    - name: Install multiple packages
      yum:
        name:
          - wget
          - curl
          - vim
        state: present
    
    - name: Update all packages
      yum:
        name: "*"
        state: latest
        update_cache: yes
    
    - name: Remove a specific package
      yum:
        name: telnet
        state: absent
Run the playbook to execute package management tasks:
ansible-playbook package-management.yml
Subtask 2.2: Using the APT Module
The apt module manages packages on Debian-based systems (Ubuntu, Debian).

Create a playbook for Ubuntu package management:
nano apt-management.yml
Add the following content:
---
- name: Package Management with APT Module
  hosts: ubuntu_nodes
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
    
    - name: Install git package
      apt:
        name: git
        state: present
    
    - name: Install multiple packages
      apt:
        name:
          - wget
          - curl
          - vim
          - htop
        state: present
    
    - name: Upgrade all packages
      apt:
        upgrade: dist
        update_cache: yes
    
    - name: Remove unnecessary packages
      apt:
        autoremove: yes
    
    - name: Remove a specific package
      apt:
        name: nano
        state: absent
        purge: yes
Execute the APT playbook:
ansible-playbook apt-management.yml
Subtask 2.3: Cross-Platform Package Management
Create a playbook that works across different operating systems.

Create a universal package playbook:
nano universal-packages.yml
Add cross-platform logic:
---
- name: Universal Package Management
  hosts: all
  become: yes
  tasks:
    - name: Install git on Red Hat family
      yum:
        name: git
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Install git on Debian family
      apt:
        name: git
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: Install development tools on Red Hat family
      yum:
        name:
          - gcc
          - make
          - kernel-devel
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Install development tools on Debian family
      apt:
        name:
          - build-essential
          - linux-headers-generic
        state: present
      when: ansible_os_family == "Debian"
Run the universal playbook:
ansible-playbook universal-packages.yml
Task 3: Managing Services with the Service Module
Subtask 3.1: Basic Service Management
The service module controls system services across different Linux distributions.

Create a service management playbook:
nano service-management.yml
Add service management tasks:
---
- name: Service Management with Service Module
  hosts: all
  become: yes
  tasks:
    - name: Install httpd/apache2 based on OS family
      package:
        name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
        state: present
    
    - name: Start and enable web service
      service:
        name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
        state: started
        enabled: yes
    
    - name: Check if service is running
      service:
        name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
        state: started
      register: service_status
    
    - name: Display service status
      debug:
        msg: "Web service is {{ 'running' if service_status.state == 'started' else 'not running' }}"
Execute the service management playbook:
ansible-playbook service-management.yml
Subtask 3.2: Advanced Service Operations
Create an advanced service playbook:
nano advanced-services.yml
Add comprehensive service management:
---
- name: Advanced Service Management
  hosts: all
  become: yes
  tasks:
    - name: Install and configure SSH service
      block:
        - name: Ensure SSH is installed
          package:
            name: "{{ 'openssh-server' if ansible_os_family == 'Debian' else 'openssh-server' }}"
            state: present
        
        - name: Start SSH service
          service:
            name: "{{ 'ssh' if ansible_os_family == 'Debian' else 'sshd' }}"
            state: started
            enabled: yes
        
        - name: Reload SSH service configuration
          service:
            name: "{{ 'ssh' if ansible_os_family == 'Debian' else 'sshd' }}"
            state: reloaded
    
    - name: Manage firewall service
      block:
        - name: Install firewall on Red Hat family
          yum:
            name: firewalld
            state: present
          when: ansible_os_family == "RedHat"
        
        - name: Start firewall service on Red Hat family
          service:
            name: firewalld
            state: started
            enabled: yes
          when: ansible_os_family == "RedHat"
        
        - name: Install UFW on Debian family
          apt:
            name: ufw
            state: present
          when: ansible_os_family == "Debian"
        
        - name: Enable UFW on Debian family
          service:
            name: ufw
            state: started
            enabled: yes
          when: ansible_os_family == "Debian"
Run the advanced service playbook:
ansible-playbook advanced-services.yml
Task 4: Creating a Complete Infrastructure Playbook
Subtask 4.1: Combine All Modules
Create a comprehensive playbook that demonstrates all learned modules working together.

Create the master playbook:
nano infrastructure-setup.yml
Add comprehensive infrastructure setup:
---
- name: Complete Infrastructure Setup
  hosts: all
  become: yes
  vars:
    web_packages_redhat:
      - httpd
      - mod_ssl
      - firewalld
    web_packages_debian:
      - apache2
      - ssl-cert
      - ufw
    common_packages:
      - git
      - wget
      - curl
      - vim
      - htop
  
  tasks:
    - name: Update package cache
      package:
        name: "*"
        state: latest
      when: ansible_os_family == "RedHat"
    
    - name: Update apt cache
      apt:
        update_cache: yes
        upgrade: dist
      when: ansible_os_family == "Debian"
    
    - name: Install common packages
      package:
        name: "{{ common_packages }}"
        state: present
    
    - name: Install web server packages on Red Hat family
      yum:
        name: "{{ web_packages_redhat }}"
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Install web server packages on Debian family
      apt:
        name: "{{ web_packages_debian }}"
        state: present
      when: ansible_os_family == "Debian"
    
    - name: Start and enable web server
      service:
        name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
        state: started
        enabled: yes
    
    - name: Start and enable firewall
      service:
        name: "{{ 'firewalld' if ansible_os_family == 'RedHat' else 'ufw' }}"
        state: started
        enabled: yes
    
    - name: Create a simple index page
      copy:
        content: |
          <html>
          <head><title>Ansible Managed Server</title></head>
          <body>
          <h1>Welcome to {{ inventory_hostname }}</h1>
          <p>This server is managed by Ansible</p>
          <p>OS Family: {{ ansible_os_family }}</p>
          <p>Distribution: {{ ansible_distribution }}</p>
          </body>
          </html>
        dest: "{{ '/var/www/html/index.html' if ansible_os_family == 'RedHat' else '/var/www/html/index.html' }}"
        owner: "{{ 'apache' if ansible_os_family == 'RedHat' else 'www-data' }}"
        group: "{{ 'apache' if ansible_os_family == 'RedHat' else 'www-data' }}"
        mode: '0644'
      notify: restart web server
  
  handlers:
    - name: restart web server
      service:
        name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
        state: restarted
Execute the complete infrastructure playbook:
ansible-playbook infrastructure-setup.yml
Subtask 4.2: Verify the Setup
Check service status across all nodes:
ansible all -m service -a "name=httpd state=started" --become
ansible all -m service -a "name=apache2 state=started" --become
Verify package installation:
ansible all -m package -a "name=git state=present" --become
Test web server accessibility:
ansible all -m uri -a "url=http://{{ inventory_hostname }} method=GET"
Task 5: Error Handling and Best Practices
Subtask 5.1: Implement Error Handling
Create a playbook with error handling:
nano error-handling.yml
Add error handling mechanisms:
---
- name: Error Handling in Ansible Modules
  hosts: all
  become: yes
  tasks:
    - name: Attempt to install a package that might not exist
      package:
        name: non-existent-package
        state: present
      ignore_errors: yes
      register: package_result
    
    - name: Display error message if package installation failed
      debug:
        msg: "Package installation failed: {{ package_result.msg }}"
      when: package_result.failed
    
    - name: Try to start a service with error handling
      service:
        name: non-existent-service
        state: started
      register: service_result
      failed_when: false
    
    - name: Handle service start failure
      debug:
        msg: "Service could not be started: {{ service_result.msg }}"
      when: service_result.rc != 0
    
    - name: Ensure critical package is installed
      package:
        name: curl
        state: present
      register: critical_package
      until: critical_package is succeeded
      retries: 3
      delay: 5
Run the error handling playbook:
ansible-playbook error-handling.yml
Troubleshooting Common Issues
Package Management Issues
Problem: Package installation fails with permission errors Solution: Ensure you're using become: yes in your playbook

Problem: YUM/APT cache is outdated Solution: Add update_cache: yes to your package tasks

Service Management Issues
Problem: Service fails to start Solution: Check service dependencies and ensure required packages are installed first

Problem: Service name differs between distributions Solution: Use conditional statements with ansible_os_family variable

General Module Issues
Problem: Module not found error Solution: Verify Ansible version and module availability using ansible-doc

Problem: Syntax errors in playbooks Solution: Use ansible-playbook --syntax-check playbook.yml to validate syntax

Verification Commands
Use these commands to verify your lab completion:

# Check installed packages
ansible all -m package -a "name=git state=present" --check

# Verify service status
ansible all -m service -a "name=httpd" --become
ansible all -m service -a "name=apache2" --become

# Test connectivity to web servers
ansible all -m uri -a "url=http://{{ inventory_hostname }}"

# Check playbook syntax
ansible-playbook --syntax-check infrastructure-setup.yml
Conclusion
In this lab, you have successfully:

• Mastered Ansible Modules: You learned how to use essential Ansible modules including yum, apt, and service to automate system administration tasks

• Cross-Platform Automation: You created playbooks that work across different Linux distributions, handling the differences between Red Hat and Debian-based systems

• Package Management: You automated the installation, updating, and removal of software packages using both yum and apt modules

• Service Management: You learned to start, stop, enable, and manage system services consistently across different platforms

• Error Handling: You implemented proper error handling and troubleshooting techniques for robust automation

• Best Practices: You applied Ansible best practices including the use of variables, conditionals, and handlers

This knowledge forms the foundation for more advanced Ansible automation scenarios. Understanding these core modules is essential for the Red Hat Enterprise Linux Automation with Ansible certification and real-world infrastructure automation. You can now confidently automate package installation, service management, and system configuration across diverse Linux environments.

The skills you've developed in this lab will enable you to create reliable, maintainable automation solutions that can scale across large infrastructure deployments while maintaining consistency and reducing manual intervention.
