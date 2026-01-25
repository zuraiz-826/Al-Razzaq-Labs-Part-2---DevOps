Lab 10: Managing SELinux Policies with Ansible
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of SELinux and its security contexts
Automate SELinux policy management using Ansible playbooks
Configure SELinux to run in enforcing mode through automation
Manage SELinux file contexts using Ansible's semanage module
Troubleshoot common SELinux issues using Ansible commands
Implement best practices for SELinux management in enterprise environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux system administration
Familiarity with Ansible fundamentals (playbooks, modules, tasks)
Knowledge of YAML syntax
Understanding of file permissions and security concepts
Experience with command-line interface operations
Basic knowledge of Red Hat Enterprise Linux or CentOS systems
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex setups.

Your lab environment includes:

Control Node: CentOS/RHEL 8 system with Ansible pre-installed
Managed Nodes: Two target systems for SELinux policy management
All necessary packages and dependencies pre-installed
Network connectivity between all systems configured
Task 1: Write a Playbook to Enforce SELinux in Enforcing Mode
Subtask 1.1: Understanding SELinux Modes
SELinux operates in three modes:

Enforcing: SELinux policy is enforced, violations are blocked and logged
Permissive: SELinux policy violations are logged but not blocked
Disabled: SELinux is completely disabled
Subtask 1.2: Create the SELinux Enforcement Playbook
Create a comprehensive playbook to manage SELinux enforcement:

---
- name: Manage SELinux Enforcement Mode
  hosts: managed_nodes
  become: yes
  vars:
    selinux_mode: enforcing
    selinux_policy: targeted
  
  tasks:
    - name: Check current SELinux status
      command: getenforce
      register: current_selinux_status
      changed_when: false
      
    - name: Display current SELinux status
      debug:
        msg: "Current SELinux status: {{ current_selinux_status.stdout }}"
    
    - name: Install SELinux management packages
      yum:
        name:
          - policycoreutils
          - policycoreutils-python-utils
          - selinux-policy
          - selinux-policy-targeted
          - setroubleshoot-server
          - setools-console
        state: present
    
    - name: Configure SELinux to enforcing mode
      selinux:
        policy: "{{ selinux_policy }}"
        state: "{{ selinux_mode }}"
      register: selinux_change
      notify: reboot_system
    
    - name: Verify SELinux configuration file
      lineinfile:
        path: /etc/selinux/config
        regexp: '^SELINUX='
        line: "SELINUX={{ selinux_mode }}"
        backup: yes
    
    - name: Check if reboot is required
      debug:
        msg: "System reboot required: {{ selinux_change.reboot_required | default(false) }}"
    
    - name: Wait for system to come back online (if rebooted)
      wait_for_connection:
        connect_timeout: 20
        sleep: 5
        delay: 5
        timeout: 300
      when: selinux_change.reboot_required | default(false)
  
  handlers:
    - name: reboot_system
      reboot:
        msg: "Rebooting system to apply SELinux changes"
        connect_timeout: 5
        reboot_timeout: 300
        pre_reboot_delay: 0
        post_reboot_delay: 30
      when: selinux_change.reboot_required | default(false)
Subtask 1.3: Execute the SELinux Enforcement Playbook
Save the playbook as selinux_enforce.yml and run it:

# Navigate to your playbook directory
cd /home/ansible/playbooks

# Create the playbook file
nano selinux_enforce.yml

# Execute the playbook
ansible-playbook -i inventory selinux_enforce.yml

# Verify SELinux status on managed nodes
ansible managed_nodes -i inventory -m command -a "sestatus" --become
Subtask 1.4: Create a Comprehensive SELinux Status Check Playbook
---
- name: Comprehensive SELinux Status Check
  hosts: managed_nodes
  become: yes
  
  tasks:
    - name: Get detailed SELinux status
      command: sestatus
      register: selinux_detailed_status
      changed_when: false
    
    - name: Display detailed SELinux information
      debug:
        var: selinux_detailed_status.stdout_lines
    
    - name: Check SELinux booleans status
      command: getsebool -a
      register: selinux_booleans
      changed_when: false
    
    - name: Count active SELinux booleans
      debug:
        msg: "Total SELinux booleans: {{ selinux_booleans.stdout_lines | length }}"
    
    - name: Check for SELinux denials in audit log
      shell: ausearch -m avc -ts recent | head -10
      register: recent_denials
      changed_when: false
      failed_when: false
    
    - name: Display recent SELinux denials (if any)
      debug:
        msg: "{{ recent_denials.stdout_lines if recent_denials.stdout_lines else 'No recent SELinux denials found' }}"
Task 2: Manage SELinux File Contexts Using Semanage Module
Subtask 2.1: Understanding SELinux File Contexts
SELinux file contexts define the security attributes of files and directories. The format is: user:role:type:level

Common file context types:

httpd_exec_t: Web server executables
httpd_config_t: Web server configuration files
user_home_t: User home directories
admin_home_t: Administrator home directories
Subtask 2.2: Create File Context Management Playbook
---
- name: Manage SELinux File Contexts
  hosts: managed_nodes
  become: yes
  vars:
    web_root: /var/www/html
    custom_web_dir: /opt/webapp
    log_directory: /var/log/webapp
  
  tasks:
    - name: Create custom web application directory
      file:
        path: "{{ custom_web_dir }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
    
    - name: Create custom log directory
      file:
        path: "{{ log_directory }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
    
    - name: Set SELinux file context for custom web directory
      sefcontext:
        target: "{{ custom_web_dir }}(/.*)?"
        setype: httpd_exec_t
        state: present
      notify: restore_selinux_contexts
    
    - name: Set SELinux file context for log directory
      sefcontext:
        target: "{{ log_directory }}(/.*)?"
        setype: httpd_log_t
        state: present
      notify: restore_selinux_contexts
    
    - name: Create sample web files
      copy:
        content: |
          #!/bin/bash
          echo "Content-Type: text/html"
          echo ""
          echo "<h1>Custom Web Application</h1>"
          echo "<p>SELinux Context: $(ls -Z $0)</p>"
        dest: "{{ custom_web_dir }}/index.cgi"
        owner: apache
        group: apache
        mode: '0755'
    
    - name: Create sample log file
      copy:
        content: |
          [{{ ansible_date_time.iso8601 }}] Application started
          [{{ ansible_date_time.iso8601 }}] SELinux context applied
        dest: "{{ log_directory }}/app.log"
        owner: apache
        group: apache
        mode: '0644'
    
    - name: Verify current file contexts
      command: ls -Z {{ item }}
      register: file_contexts
      loop:
        - "{{ custom_web_dir }}"
        - "{{ log_directory }}"
      changed_when: false
    
    - name: Display file contexts
      debug:
        msg: "File context for {{ item.item }}: {{ item.stdout }}"
      loop: "{{ file_contexts.results }}"
    
    - name: List all custom SELinux file context rules
      command: semanage fcontext -l -C
      register: custom_contexts
      changed_when: false
    
    - name: Display custom SELinux contexts
      debug:
        var: custom_contexts.stdout_lines
  
  handlers:
    - name: restore_selinux_contexts
      command: restorecon -R {{ item }}
      loop:
        - "{{ custom_web_dir }}"
        - "{{ log_directory }}"
Subtask 2.3: Advanced File Context Management
Create a more advanced playbook for complex file context scenarios:

---
- name: Advanced SELinux File Context Management
  hosts: managed_nodes
  become: yes
  
  tasks:
    - name: Backup current SELinux file contexts
      shell: semanage fcontext -l > /tmp/selinux_contexts_backup_{{ ansible_date_time.epoch }}.txt
      changed_when: false
    
    - name: Define multiple file context mappings
      sefcontext:
        target: "{{ item.path }}"
        setype: "{{ item.type }}"
        state: present
      loop:
        - { path: "/opt/myapp(/.*)?", type: "httpd_exec_t" }
        - { path: "/opt/myapp/logs(/.*)?", type: "httpd_log_t" }
        - { path: "/opt/myapp/config(/.*)?", type: "httpd_config_t" }
        - { path: "/opt/myapp/tmp(/.*)?", type: "tmp_t" }
      notify: apply_contexts
    
    - name: Create directories for context testing
      file:
        path: "{{ item }}"
        state: directory
        owner: apache
        group: apache
        mode: '0755'
      loop:
        - /opt/myapp
        - /opt/myapp/logs
        - /opt/myapp/config
        - /opt/myapp/tmp
    
    - name: Generate test files with different contexts
      copy:
        content: "Test file for {{ item.split('/')[-1] }} context"
        dest: "{{ item }}/test.txt"
        owner: apache
        group: apache
        mode: '0644'
      loop:
        - /opt/myapp
        - /opt/myapp/logs
        - /opt/myapp/config
        - /opt/myapp/tmp
    
    - name: Verify applied contexts
      shell: ls -laZ {{ item }}
      register: context_verification
      loop:
        - /opt/myapp
        - /opt/myapp/logs
        - /opt/myapp/config
        - /opt/myapp/tmp
      changed_when: false
    
    - name: Display context verification results
      debug:
        msg: "{{ item.stdout_lines }}"
      loop: "{{ context_verification.results }}"
  
  handlers:
    - name: apply_contexts
      command: restorecon -R /opt/myapp
Subtask 2.4: Execute File Context Management
# Save and execute the file context playbook
ansible-playbook -i inventory selinux_file_contexts.yml

# Verify the contexts were applied correctly
ansible managed_nodes -i inventory -m shell -a "semanage fcontext -l -C" --become

# Check specific directory contexts
ansible managed_nodes -i inventory -m shell -a "ls -laZ /opt/myapp" --become
Task 3: Troubleshoot SELinux Issues Using Ansible Commands
Subtask 3.1: Create SELinux Troubleshooting Playbook
---
- name: SELinux Troubleshooting and Diagnostics
  hosts: managed_nodes
  become: yes
  
  tasks:
    - name: Install SELinux troubleshooting tools
      yum:
        name:
          - setroubleshoot-server
          - setroubleshoot
          - policycoreutils-python-utils
          - setools-console
        state: present
    
    - name: Check for SELinux denials in audit log
      shell: ausearch -m avc -ts today
      register: selinux_denials
      changed_when: false
      failed_when: false
    
    - name: Count SELinux denials
      set_fact:
        denial_count: "{{ selinux_denials.stdout_lines | length }}"
    
    - name: Display denial summary
      debug:
        msg: "Found {{ denial_count }} SELinux denials today"
    
    - name: Generate SELinux denial report
      shell: sealert -a /var/log/audit/audit.log
      register: sealert_report
      changed_when: false
      failed_when: false
      when: denial_count | int > 0
    
    - name: Save denial report to file
      copy:
        content: "{{ sealert_report.stdout }}"
        dest: "/tmp/selinux_denial_report_{{ ansible_date_time.epoch }}.txt"
      when: denial_count | int > 0
    
    - name: Check SELinux boolean status
      shell: getsebool -a | grep -E "(httpd|ftp|samba|nfs)"
      register: important_booleans
      changed_when: false
      failed_when: false
    
    - name: Display important SELinux booleans
      debug:
        var: important_booleans.stdout_lines
    
    - name: Check for mislabeled files
      shell: find /var/www /etc/httpd -type f -exec ls -Z {} \; 2>/dev/null | head -20
      register: web_file_contexts
      changed_when: false
      failed_when: false
    
    - name: Display web file contexts
      debug:
        msg: "Web file contexts sample:"
        verbosity: 1
    
    - name: Display web file contexts details
      debug:
        var: web_file_contexts.stdout_lines
      when: web_file_contexts.stdout_lines is defined
Subtask 3.2: Create Automated SELinux Issue Resolution Playbook
---
- name: Automated SELinux Issue Resolution
  hosts: managed_nodes
  become: yes
  vars:
    common_selinux_booleans:
      - { name: "httpd_can_network_connect", value: "on" }
      - { name: "httpd_can_network_connect_db", value: "on" }
      - { name: "httpd_execmem", value: "off" }
      - { name: "httpd_enable_homedirs", value: "off" }
  
  tasks:
    - name: Create test scenario - Apache access issue
      block:
        - name: Create test web directory with wrong context
          file:
            path: /var/test_web
            state: directory
            owner: apache
            group: apache
            mode: '0755'
        
        - name: Create test file with wrong context
          copy:
            content: "<h1>Test Page</h1>"
            dest: /var/test_web/index.html
            owner: apache
            group: apache
            mode: '0644'
        
        - name: Intentionally set wrong SELinux context
          command: chcon -t admin_home_t /var/test_web/index.html
          changed_when: true
    
    - name: Diagnose the issue
      block:
        - name: Check current context of problematic file
          command: ls -Z /var/test_web/index.html
          register: wrong_context
          changed_when: false
        
        - name: Display problematic context
          debug:
            msg: "Current context: {{ wrong_context.stdout }}"
        
        - name: Check what the context should be
          command: matchpathcon /var/test_web/index.html
          register: correct_context
          changed_when: false
          failed_when: false
        
        - name: Display correct context
          debug:
            msg: "Expected context: {{ correct_context.stdout }}"
    
    - name: Resolve the issue
      block:
        - name: Fix file context using restorecon
          command: restorecon -v /var/test_web/index.html
          register: context_fix
          changed_when: "'restorecon reset' in context_fix.stdout"
        
        - name: Verify context fix
          command: ls -Z /var/test_web/index.html
          register: fixed_context
          changed_when: false
        
        - name: Display fixed context
          debug:
            msg: "Fixed context: {{ fixed_context.stdout }}"
    
    - name: Configure common SELinux booleans
      seboolean:
        name: "{{ item.name }}"
        state: "{{ item.value }}"
        persistent: yes
      loop: "{{ common_selinux_booleans }}"
    
    - name: Create SELinux monitoring script
      copy:
        content: |
          #!/bin/bash
          # SELinux Monitoring Script
          echo "=== SELinux Status ==="
          sestatus
          echo ""
          echo "=== Recent Denials ==="
          ausearch -m avc -ts recent 2>/dev/null | tail -5
          echo ""
          echo "=== Important Booleans ==="
          getsebool -a | grep -E "(httpd|ftp|samba)" | grep " on"
        dest: /usr/local/bin/selinux_monitor.sh
        mode: '0755'
        owner: root
        group: root
    
    - name: Run SELinux monitoring script
      command: /usr/local/bin/selinux_monitor.sh
      register: monitoring_output
      changed_when: false
    
    - name: Display monitoring results
      debug:
        var: monitoring_output.stdout_lines
Subtask 3.3: Create SELinux Policy Module Management Playbook
---
- name: SELinux Policy Module Management
  hosts: managed_nodes
  become: yes
  
  tasks:
    - name: List currently loaded SELinux modules
      command: semodule -l
      register: loaded_modules
      changed_when: false
    
    - name: Count loaded modules
      debug:
        msg: "Total loaded SELinux modules: {{ loaded_modules.stdout_lines | length }}"
    
    - name: Check for custom policy modules
      shell: semodule -l | grep -v "^[a-z]*\s*[0-9]" || echo "No custom modules found"
      register: custom_modules
      changed_when: false
    
    - name: Display custom modules
      debug:
        var: custom_modules.stdout_lines
    
    - name: Create a simple custom policy module
      copy:
        content: |
          module myapp 1.0;
          
          require {
              type httpd_t;
              type httpd_exec_t;
              class file { read execute };
          }
          
          # Allow httpd to read and execute files in custom location
          allow httpd_t httpd_exec_t:file { read execute };
        dest: /tmp/myapp.te
    
    - name: Compile custom policy module
      shell: |
        cd /tmp
        checkmodule -M -m -o myapp.mod myapp.te
        semodule_package -o myapp.pp -m myapp.mod
      register: module_compile
      changed_when: true
    
    - name: Install custom policy module
      command: semodule -i /tmp/myapp.pp
      register: module_install
      changed_when: true
    
    - name: Verify module installation
      shell: semodule -l | grep myapp
      register: module_verify
      changed_when: false
    
    - name: Display module verification
      debug:
        msg: "Custom module status: {{ module_verify.stdout if module_verify.stdout else 'Module not found' }}"
    
    - name: Clean up temporary files
      file:
        path: "{{ item }}"
        state: absent
      loop:
        - /tmp/myapp.te
        - /tmp/myapp.mod
        - /tmp/myapp.pp
Subtask 3.4: Execute Troubleshooting Playbooks
# Execute the troubleshooting playbook
ansible-playbook -i inventory selinux_troubleshooting.yml

# Execute the issue resolution playbook
ansible-playbook -i inventory selinux_issue_resolution.yml

# Execute the policy module management playbook
ansible-playbook -i inventory selinux_policy_modules.yml

# Verify all changes
ansible managed_nodes -i inventory -m shell -a "/usr/local/bin/selinux_monitor.sh" --become
Advanced SELinux Management Techniques
Creating a Comprehensive SELinux Management Role
Create an Ansible role structure for reusable SELinux management:

# Create role directory structure
mkdir -p roles/selinux_management/{tasks,handlers,vars,templates,files}
roles/selinux_management/tasks/main.yml:

---
- name: Include SELinux enforcement tasks
  include_tasks: enforce.yml
  tags: enforce

- name: Include file context management tasks
  include_tasks: contexts.yml
  tags: contexts

- name: Include troubleshooting tasks
  include_tasks: troubleshoot.yml
  tags: troubleshoot

- name: Include boolean management tasks
  include_tasks: booleans.yml
  tags: booleans
roles/selinux_management/vars/main.yml:

---
selinux_packages:
  - policycoreutils
  - policycoreutils-python-utils
  - selinux-policy
  - selinux-policy-targeted
  - setroubleshoot-server
  - setools-console

default_selinux_booleans:
  - { name: "httpd_can_network_connect", value: false }
  - { name: "httpd_can_network_connect_db", value: false }
  - { name: "httpd_execmem", value: false }
  - { name: "httpd_enable_homedirs", value: false }
  - { name: "httpd_use_nfs", value: false }
Common SELinux Issues and Solutions
Issue 1: Web Server Cannot Access Files
Problem: Apache cannot serve files from custom directory Solution: Set correct file contexts

- name: Fix web server file access
  sefcontext:
    target: "/custom/web/path(/.*)?"
    setype: httpd_exec_t
    state: present
  notify: restore_contexts
Issue 2: Database Connection Denied
Problem: Web application cannot connect to database Solution: Enable appropriate boolean

- name: Allow web server database connections
  seboolean:
    name: httpd_can_network_connect_db
    state: yes
    persistent: yes
Issue 3: Home Directory Access
Problem: Web server cannot access user home directories Solution: Enable home directory access boolean

- name: Enable home directory access
  seboolean:
    name: httpd_enable_homedirs
    state: yes
    persistent: yes
Best Practices for SELinux Management
1. Always Use Persistent Boolean Changes
- name: Set SELinux boolean persistently
  seboolean:
    name: "{{ boolean_name }}"
    state: "{{ boolean_state }}"
    persistent: yes  # Always use persistent
2. Backup Before Making Changes
- name: Backup SELinux configuration
  copy:
    src: /etc/selinux/config
    dest: "/etc/selinux/config.backup.{{ ansible_date_time.epoch }}"
    remote_src: yes
3. Test in Permissive Mode First
- name: Test changes in permissive mode
  selinux:
    policy: targeted
    state: permissive
  when: selinux_test_mode | default(false)
4. Monitor and Log Changes
- name: Log SELinux changes
  lineinfile:
    path: /var/log/selinux_changes.log
    line: "{{ ansible_date_time.iso8601 }} - {{ ansible_hostname }} - {{ change_description }}"
    create: yes
Verification and Testing
Final Verification Playbook
---
- name: Final SELinux Configuration Verification
  hosts: managed_nodes
  become: yes
  
  tasks:
    - name: Comprehensive SELinux status check
      shell: |
        echo "=== SELinux Status ==="
        sestatus
        echo ""
        echo "=== Active Booleans ==="
        getsebool -a | grep " on" | wc -l
        echo ""
        echo "=== Custom File Contexts ==="
        semanage fcontext -l -C | wc -l
        echo ""
        echo "=== Recent Denials ==="
        ausearch -m avc -ts today 2>/dev/null | wc -l || echo "0"
      register: final_status
      changed_when: false
    
    - name: Display final verification results
      debug:
        var: final_status.stdout_lines
    
    - name: Generate final report
      copy:
        content: |
          SELinux Configuration Report
          Generated: {{ ansible_date_time.iso8601 }}
          Host: {{ ansible_hostname }}
          
          {{ final_status.stdout }}
          
          Configuration completed successfully.
        dest: "/tmp/selinux_final_report_{{ ansible_hostname }}.txt"
Conclusion
In this comprehensive lab, you have successfully learned to:

Key Accomplishments:

Automated SELinux Enforcement: Created robust playbooks to automatically configure SELinux in enforcing mode across multiple systems, ensuring consistent security policy enforcement.

File Context Management: Mastered the use of Ansible's semanage module to define and apply appropriate SELinux file contexts, enabling applications to function correctly within SELinux constraints.

Troubleshooting Expertise: Developed systematic approaches to identify, diagnose, and resolve SELinux-related issues using automated Ansible commands and scripts.

Best Practices Implementation: Applied enterprise-grade SELinux management practices including persistent configuration, proper backup procedures, and comprehensive monitoring.

Why This Matters:

SELinux is a critical security component in enterprise Linux environments, providing mandatory access control that significantly enhances system security. By automating SELinux management with Ansible, you ensure:

Consistency: Identical security policies across all managed systems
Scalability: Ability to manage SELinux on hundreds or thousands of systems
Reliability: Reduced human error through automation
Compliance: Systematic approach to meeting security requirements
Efficiency: Rapid deployment and troubleshooting of SELinux configurations
Real-World Applications:

The skills you've developed are directly applicable to:

Enterprise security hardening initiatives
Compliance auditing and remediation
DevOps security automation pipelines
Large-scale Linux infrastructure management
Red Hat Certified Engineer (RHCE) certification preparation
Next Steps:

Continue building on these skills by exploring advanced SELinux topics such as custom policy development, integration with configuration management systems, and automated security monitoring solutions.

Your mastery of SELinux automation with Ansible positions you as a valuable asset in any organization prioritizing Linux security and infrastructure automation.
