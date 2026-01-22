Lab 11: Automating Software Packages
Objectives
By the end of this lab, students will be able to:

• Create Ansible playbooks to automate software package installation across multiple systems • Use package management modules (yum/dnf and apt) to install, update, and remove packages • Manage package repositories and dependencies using Ansible • Implement conditional package management based on operating system types • Configure package installation with specific versions and states • Troubleshoot common package management issues in Ansible automation

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with package managers (yum/dnf for Red Hat-based systems, apt for Debian-based systems) • Completed previous Ansible labs covering inventory management and basic playbook creation • Understanding of YAML syntax and Ansible playbook structure • Knowledge of SSH key-based authentication concepts

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes: • One Ansible control node (CentOS/RHEL 8 or Ubuntu 20.04) • Three managed nodes: two CentOS/RHEL systems and one Ubuntu system • Pre-configured SSH connectivity between all systems • Ansible already installed on the control node

Task 1: Creating Basic Package Installation Playbooks
Subtask 1.1: Setting Up the Lab Directory Structure
First, let's create a proper directory structure for our package management playbooks.

Connect to your control node and create the lab directory:
mkdir -p ~/ansible-lab11/playbooks
mkdir -p ~/ansible-lab11/inventory
cd ~/ansible-lab11
Create the inventory file to define your managed hosts:
cat > inventory/hosts << EOF
[rhel_servers]
node1 ansible_host=10.0.1.10
node2 ansible_host=10.0.1.11

[ubuntu_servers]
node3 ansible_host=10.0.1.12

[all_servers:children]
rhel_servers
ubuntu_servers

[all_servers:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Test connectivity to all managed nodes:
ansible all -i inventory/hosts -m ping
Subtask 1.2: Creating Your First Package Installation Playbook
Now let's create a basic playbook to install common software packages.

Create a simple package installation playbook:
cat > playbooks/install-basic-packages.yml << 'EOF'
---
- name: Install Basic Software Packages
  hosts: all_servers
  become: yes
  vars:
    common_packages:
      - git
      - curl
      - wget
      - vim
      - htop
  
  tasks:
    - name: Install packages on Red Hat-based systems
      yum:
        name: "{{ common_packages }}"
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Install packages on Debian-based systems
      apt:
        name: "{{ common_packages }}"
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: Verify git installation
      command: git --version
      register: git_version
      changed_when: false
    
    - name: Display git version
      debug:
        msg: "Git version installed: {{ git_version.stdout }}"
EOF
Run the playbook to install basic packages:
ansible-playbook -i inventory/hosts playbooks/install-basic-packages.yml
Verify the installation by checking one of the installed packages:
ansible all -i inventory/hosts -m command -a "which git" --become
Subtask 1.3: Advanced Package Management with Specific Versions
Let's create a more advanced playbook that handles specific package versions and states.

Create an advanced package management playbook:
cat > playbooks/advanced-package-management.yml << 'EOF'
---
- name: Advanced Package Management
  hosts: all_servers
  become: yes
  vars:
    development_packages:
      rhel:
        - name: python3
          state: present
        - name: python3-pip
          state: present
        - name: nodejs
          state: present
        - name: npm
          state: present
      ubuntu:
        - name: python3
          state: present
        - name: python3-pip
          state: present
        - name: nodejs
          state: present
        - name: npm
          state: present
    
    packages_to_remove:
      - telnet
      - rsh
  
  tasks:
    - name: Install development packages on Red Hat systems
      yum:
        name: "{{ item.name }}"
        state: "{{ item.state }}"
      loop: "{{ development_packages.rhel }}"
      when: ansible_os_family == "RedHat"
    
    - name: Install development packages on Ubuntu systems
      apt:
        name: "{{ item.name }}"
        state: "{{ item.state }}"
        update_cache: yes
      loop: "{{ development_packages.ubuntu }}"
      when: ansible_os_family == "Debian"
    
    - name: Remove insecure packages from Red Hat systems
      yum:
        name: "{{ packages_to_remove }}"
        state: absent
      when: ansible_os_family == "RedHat"
    
    - name: Remove insecure packages from Ubuntu systems
      apt:
        name: "{{ packages_to_remove }}"
        state: absent
      when: ansible_os_family == "Debian"
    
    - name: Check Python version
      command: python3 --version
      register: python_version
      changed_when: false
    
    - name: Display Python version
      debug:
        msg: "Python version: {{ python_version.stdout }}"
EOF
Execute the advanced package management playbook:
ansible-playbook -i inventory/hosts playbooks/advanced-package-management.yml
Task 2: Using yum/apt to Manage Packages on Multiple Remote Hosts
Subtask 2.1: Creating OS-Specific Package Management Playbooks
Let's create separate playbooks for different operating systems to demonstrate platform-specific package management.

Create a Red Hat-specific package management playbook:
cat > playbooks/rhel-package-management.yml << 'EOF'
---
- name: Red Hat Package Management
  hosts: rhel_servers
  become: yes
  vars:
    rhel_packages:
      - epel-release
      - yum-utils
      - device-mapper-persistent-data
      - lvm2
      - tree
      - net-tools
      - bind-utils
  
  tasks:
    - name: Update all packages to latest version
      yum:
        name: '*'
        state: latest
        update_cache: yes
      tags: update
    
    - name: Install EPEL repository
      yum:
        name: epel-release
        state: present
    
    - name: Install system administration packages
      yum:
        name: "{{ rhel_packages }}"
        state: present
    
    - name: Install packages from EPEL repository
      yum:
        name:
          - htop
          - ncdu
          - iotop
        state: present
    
    - name: Check if Docker repository exists
      stat:
        path: /etc/yum.repos.d/docker-ce.repo
      register: docker_repo
    
    - name: Add Docker CE repository
      yum_repository:
        name: docker-ce-stable
        description: Docker CE Stable - $basearch
        baseurl: https://download.docker.com/linux/centos/8/$basearch/stable
        gpgcheck: yes
        gpgkey: https://download.docker.com/linux/centos/gpg
        enabled: yes
      when: not docker_repo.stat.exists
    
    - name: Install Docker CE
      yum:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
        state: present
    
    - name: Start and enable Docker service
      systemd:
        name: docker
        state: started
        enabled: yes
    
    - name: Verify installed packages
      command: rpm -qa | grep -E "(docker|epel|htop)"
      register: installed_packages
      changed_when: false
    
    - name: Display installed packages
      debug:
        msg: "Installed packages: {{ installed_packages.stdout_lines }}"
EOF
Create an Ubuntu-specific package management playbook:
cat > playbooks/ubuntu-package-management.yml << 'EOF'
---
- name: Ubuntu Package Management
  hosts: ubuntu_servers
  become: yes
  vars:
    ubuntu_packages:
      - software-properties-common
      - apt-transport-https
      - ca-certificates
      - gnupg
      - lsb-release
      - tree
      - net-tools
      - dnsutils
  
  tasks:
    - name: Update apt package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
    
    - name: Upgrade all packages
      apt:
        upgrade: dist
        autoremove: yes
        autoclean: yes
      tags: update
    
    - name: Install essential packages
      apt:
        name: "{{ ubuntu_packages }}"
        state: present
    
    - name: Install additional monitoring tools
      apt:
        name:
          - htop
          - iotop
          - ncdu
          - glances
        state: present
    
    - name: Add Docker GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present
    
    - name: Add Docker repository
      apt_repository:
        repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present
        update_cache: yes
    
    - name: Install Docker CE
      apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
        state: present
    
    - name: Start and enable Docker service
      systemd:
        name: docker
        state: started
        enabled: yes
    
    - name: Install Python packages using pip
      pip:
        name:
          - docker
          - requests
        state: present
    
    - name: Verify installed packages
      command: dpkg -l | grep -E "(docker|htop|python3-pip)"
      register: installed_packages
      changed_when: false
    
    - name: Display installed packages
      debug:
        msg: "Installed packages: {{ installed_packages.stdout_lines }}"
EOF
Run the Red Hat-specific playbook:
ansible-playbook -i inventory/hosts playbooks/rhel-package-management.yml
Run the Ubuntu-specific playbook:
ansible-playbook -i inventory/hosts playbooks/ubuntu-package-management.yml
Subtask 2.2: Creating a Universal Package Management Playbook
Now let's create a comprehensive playbook that handles both package managers intelligently.

Create a universal package management playbook:
cat > playbooks/universal-package-management.yml << 'EOF'
---
- name: Universal Package Management
  hosts: all_servers
  become: yes
  vars:
    web_server_packages:
      RedHat:
        - httpd
        - mod_ssl
        - httpd-tools
      Debian:
        - apache2
        - apache2-utils
        - ssl-cert
    
    database_packages:
      RedHat:
        - mariadb-server
        - mariadb
        - python3-PyMySQL
      Debian:
        - mariadb-server
        - mariadb-client
        - python3-pymysql
    
    monitoring_packages:
      RedHat:
        - nagios-plugins-all
        - nrpe
      Debian:
        - nagios-plugins
        - nagios-nrpe-server
  
  tasks:
    - name: Update package cache (Red Hat)
      yum:
        update_cache: yes
      when: ansible_os_family == "RedHat"
    
    - name: Update package cache (Debian)
      apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
    
    - name: Install web server packages
      package:
        name: "{{ web_server_packages[ansible_os_family] }}"
        state: present
    
    - name: Install database packages
      package:
        name: "{{ database_packages[ansible_os_family] }}"
        state: present
    
    - name: Start and enable web server (Red Hat)
      systemd:
        name: httpd
        state: started
        enabled: yes
      when: ansible_os_family == "RedHat"
    
    - name: Start and enable web server (Debian)
      systemd:
        name: apache2
        state: started
        enabled: yes
      when: ansible_os_family == "Debian"
    
    - name: Start and enable database server
      systemd:
        name: mariadb
        state: started
        enabled: yes
    
    - name: Install monitoring packages (ignore errors for unavailable packages)
      package:
        name: "{{ monitoring_packages[ansible_os_family] }}"
        state: present
      ignore_errors: yes
    
    - name: Create a simple index.html file
      copy:
        content: |
          <html>
          <head><title>Ansible Managed Server</title></head>
          <body>
          <h1>Welcome to {{ inventory_hostname }}</h1>
          <p>This server is managed by Ansible</p>
          <p>OS Family: {{ ansible_os_family }}</p>
          <p>Distribution: {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: root
        group: root
        mode: '0644'
    
    - name: Test web server connectivity
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      delegate_to: localhost
      register: web_test
    
    - name: Display web server test results
      debug:
        msg: "Web server is responding: {{ web_test.status == 200 }}"
EOF
Execute the universal package management playbook:
ansible-playbook -i inventory/hosts playbooks/universal-package-management.yml
Subtask 2.3: Package Management with Error Handling and Rollback
Let's create a robust playbook with proper error handling and rollback capabilities.

Create a robust package management playbook:
cat > playbooks/robust-package-management.yml << 'EOF'
---
- name: Robust Package Management with Error Handling
  hosts: all_servers
  become: yes
  vars:
    critical_packages:
      - openssh-server
      - sudo
      - systemd
    
    optional_packages:
      - vim-enhanced
      - emacs
      - nano
    
    backup_location: /tmp/package_backup
  
  tasks:
    - name: Create backup directory
      file:
        path: "{{ backup_location }}"
        state: directory
        mode: '0755'
    
    - name: Backup current package list (Red Hat)
      shell: rpm -qa > {{ backup_location }}/packages_before_{{ ansible_date_time.epoch }}.txt
      when: ansible_os_family == "RedHat"
    
    - name: Backup current package list (Debian)
      shell: dpkg -l > {{ backup_location }}/packages_before_{{ ansible_date_time.epoch }}.txt
      when: ansible_os_family == "Debian"
    
    - name: Install critical packages with error handling
      block:
        - name: Install critical packages (Red Hat)
          yum:
            name: "{{ critical_packages }}"
            state: present
          when: ansible_os_family == "RedHat"
        
        - name: Install critical packages (Debian)
          apt:
            name: "{{ critical_packages }}"
            state: present
          when: ansible_os_family == "Debian"
      
      rescue:
        - name: Log critical package installation failure
          lineinfile:
            path: "{{ backup_location }}/installation_errors.log"
            line: "{{ ansible_date_time.iso8601 }}: Failed to install critical packages on {{ inventory_hostname }}"
            create: yes
        
        - name: Fail the play for critical package errors
          fail:
            msg: "Critical package installation failed on {{ inventory_hostname }}"
    
    - name: Install optional packages with graceful failure handling
      block:
        - name: Install optional packages (Red Hat)
          yum:
            name: "{{ optional_packages }}"
            state: present
          when: ansible_os_family == "RedHat"
        
        - name: Install optional packages (Debian)
          apt:
            name: "{{ optional_packages }}"
            state: present
          when: ansible_os_family == "Debian"
      
      rescue:
        - name: Log optional package installation issues
          lineinfile:
            path: "{{ backup_location }}/installation_warnings.log"
            line: "{{ ansible_date_time.iso8601 }}: Some optional packages failed to install on {{ inventory_hostname }}"
            create: yes
        
        - name: Continue despite optional package failures
          debug:
            msg: "Optional package installation had issues, but continuing..."
    
    - name: Verify critical services are running
      systemd:
        name: "{{ item }}"
        state: started
      loop:
        - sshd
      ignore_errors: yes
    
    - name: Generate post-installation package list (Red Hat)
      shell: rpm -qa > {{ backup_location }}/packages_after_{{ ansible_date_time.epoch }}.txt
      when: ansible_os_family == "RedHat"
    
    - name: Generate post-installation package list (Debian)
      shell: dpkg -l > {{ backup_location }}/packages_after_{{ ansible_date_time.epoch }}.txt
      when: ansible_os_family == "Debian"
    
    - name: Create installation summary
      template:
        content: |
          Package Installation Summary for {{ inventory_hostname }}
          =========================================================
          Date: {{ ansible_date_time.iso8601 }}
          OS Family: {{ ansible_os_family }}
          Distribution: {{ ansible_distribution }} {{ ansible_distribution_version }}
          
          Critical Packages Installed:
          {% for package in critical_packages %}
          - {{ package }}
          {% endfor %}
          
          Optional Packages Attempted:
          {% for package in optional_packages %}
          - {{ package }}
          {% endfor %}
          
          Backup Location: {{ backup_location }}
        dest: "{{ backup_location }}/installation_summary_{{ inventory_hostname }}.txt"
    
    - name: Display installation summary
      debug:
        msg: "Package installation completed. Summary saved to {{ backup_location }}/installation_summary_{{ inventory_hostname }}.txt"
EOF
Run the robust package management playbook:
ansible-playbook -i inventory/hosts playbooks/robust-package-management.yml
Check the installation logs:
ansible all -i inventory/hosts -m command -a "ls -la /tmp/package_backup/" --become
Subtask 2.4: Creating a Package Management Dashboard
Let's create a playbook that generates a comprehensive report of package management across all systems.

Create a package reporting playbook:
cat > playbooks/package-reporting.yml << 'EOF'
---
- name: Package Management Reporting
  hosts: all_servers
  become: yes
  gather_facts: yes
  vars:
    report_dir: /tmp/ansible_reports
  
  tasks:
    - name: Create report directory
      file:
        path: "{{ report_dir }}"
        state: directory
        mode: '0755'
      delegate_to: localhost
      run_once: true
    
    - name: Get installed package count (Red Hat)
      shell: rpm -qa | wc -l
      register: rhel_package_count
      when: ansible_os_family == "RedHat"
    
    - name: Get installed package count (Debian)
      shell: dpkg -l | grep ^ii | wc -l
      register: debian_package_count
      when: ansible_os_family == "Debian"
    
    - name: Get system uptime
      command: uptime -p
      register: system_uptime
      changed_when: false
    
    - name: Get available updates (Red Hat)
      shell: yum check-update | grep -v "^$" | wc -l
      register: rhel_updates
      when: ansible_os_family == "RedHat"
      failed_when: false
    
    - name: Get available updates (Debian)
      shell: apt list --upgradable 2>/dev/null | grep -v "^Listing" | wc -l
      register: debian_updates
      when: ansible_os_family == "Debian"
      failed_when: false
    
    - name: Generate individual host report
      template:
        content: |
          System Package Report: {{ inventory_hostname }}
          =============================================
          Generated: {{ ansible_date_time.iso8601 }}
          
          System Information:
          - Hostname: {{ inventory_hostname }}
          - OS Family: {{ ansible_os_family }}
          - Distribution: {{ ansible_distribution }} {{ ansible_distribution_version }}
          - Architecture: {{ ansible_architecture }}
          - Uptime: {{ system_uptime.stdout }}
          
          Package Statistics:
          {% if ansible_os_family == "RedHat" %}
          - Total Packages Installed: {{ rhel_package_count.stdout }}
          - Available Updates: {{ rhel_updates.stdout | default('Unknown') }}
          {% elif ansible_os_family == "Debian" %}
          - Total Packages Installed: {{ debian_package_count.stdout }}
          - Available Updates: {{ debian_updates.stdout | default('Unknown') }}
          {% endif %}
          
          Key Services Status:
          - SSH Service: {{ ansible_service_mgr }}
          
          Memory Usage:
          - Total Memory: {{ ansible_memtotal_mb }} MB
          - Free Memory: {{ ansible_memfree_mb }} MB
          
          Disk Usage:
          - Root Filesystem: {{ ansible_mounts[0].size_total | filesizeformat }}
          - Root Available: {{ ansible_mounts[0].size_available | filesizeformat }}
        dest: "{{ report_dir }}/{{ inventory_hostname }}_package_report.txt"
      delegate_to: localhost
    
    - name: Collect Docker status if installed
      command: docker --version
      register: docker_status
      failed_when: false
      changed_when: false
    
    - name: Add Docker information to report
      lineinfile:
        path: "{{ report_dir }}/{{ inventory_hostname }}_package_report.txt"
        line: |
          
          Docker Status:
          {% if docker_status.rc == 0 %}
          - Docker Version: {{ docker_status.stdout }}
          - Docker Service: Installed
          {% else %}
          - Docker: Not Installed
          {% endif %}
        insertafter: EOF
      delegate_to: localhost
      when: docker_status is defined
EOF
Run the package reporting playbook:
ansible-playbook -i inventory/hosts playbooks/package-reporting.yml
View the generated reports:
ls -la /tmp/ansible_reports/
cat /tmp/ansible_reports/*_package_report.txt
Troubleshooting Common Issues
Issue 1: Package Not Found Errors
Problem: Package names differ between distributions or repositories are not configured.

Solution: Use conditional statements and verify repository configuration:

- name: Install package with fallback options
  package:
    name: "{{ item }}"
    state: present
  loop:
    - httpd        # Red Hat name
    - apache2      # Debian name
  ignore_errors: yes
Issue 2: Repository Access Issues
Problem: Cannot access package repositories due to network or authentication issues.

Solution: Add repository configuration and error handling:

- name: Configure repository with error handling
  block:
    - name: Add repository
      yum_repository:
        name: custom-repo
        description: Custom Repository
        baseurl: https://repo.example.com/
        gpgcheck: no
  rescue:
    - name: Use alternative repository
      debug:
        msg: "Primary repository failed, using alternative source"
Issue 3: Service Start Failures
Problem: Installed packages have services that fail to start.

Solution: Add service verification and troubleshooting:

- name: Start service with verification
  block:
    - name: Start the service
      systemd:
        name: "{{ service_name }}"
        state: started
        enabled: yes
  rescue:
    - name: Check service status
      command: systemctl status "{{ service_name }}"
      register: service_status
    - name: Display service status
      debug:
        msg: "Service status: {{ service_status.stdout }}"
Conclusion
In this lab, you have successfully learned how to:

• Automate software package installation across multiple Linux systems using Ansible playbooks • Manage packages efficiently using both yum/dnf (Red Hat-based) and apt (Debian-based) package managers • Create universal playbooks that work across different operating system families • Implement error handling and rollback strategies for robust package management • Generate comprehensive reports to track package installation and system status

Why This Matters: Package management automation is crucial in modern IT infrastructure because it:

Ensures consistent software deployment across multiple servers
Reduces manual errors and saves significant time
Provides standardized configurations for compliance and security
Enables rapid scaling and disaster recovery
Creates audit trails for change management
These skills are essential for system administrators, DevOps engineers, and anyone managing Linux infrastructure at scale. The techniques you've learned can be applied to manage hundreds or thousands of servers efficiently, making you more valuable in enterprise environments and helping you prepare for Red Hat Enterprise Linux Automation with Ansible certification.

Next Steps: Practice these playbooks in different scenarios, experiment with more complex package dependencies, and explore Ansible Galaxy roles for advanced package management patterns.
