Lab 2: Understanding Playbooks
Objectives
By the end of this lab, students will be able to:

• Understand the basic structure and components of Ansible playbooks • Create a functional playbook to install packages on remote hosts • Define and configure hosts, tasks, and handlers within playbooks • Execute playbooks against target systems using ansible-playbook command • Implement basic error handling and task organization in playbooks • Understand the YAML syntax used in Ansible playbooks

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with YAML syntax fundamentals • Completion of Lab 1 or equivalent knowledge of Ansible basics • Understanding of SSH connectivity concepts • Basic knowledge of package management in Linux

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes: • Control Node: CentOS/RHEL 8 system with Ansible pre-installed • Managed Node: Target system for playbook execution • Pre-configured SSH connectivity between nodes • Sample inventory files and directory structure

Task 1: Understanding Playbook Structure and Creating Your First Playbook
Subtask 1.1: Explore the Playbook Directory Structure
First, let's examine the recommended directory structure for organizing playbooks.

Navigate to the ansible working directory:
cd /home/ansible
Create a structured directory for your playbooks:
mkdir -p playbooks/lab2
cd playbooks/lab2
Create the basic directory structure:
mkdir -p {group_vars,host_vars,roles,files,templates}
ls -la
Subtask 1.2: Create Your First Basic Playbook
Now we'll create a simple playbook to install a package on a remote host.

Create the main playbook file:
nano install-package.yml
Add the following content to create a basic playbook:
---
- name: Install and configure a package on remote hosts
  hosts: managed_nodes
  become: yes
  gather_facts: yes
  
  vars:
    package_name: httpd
    service_name: httpd
    
  tasks:
    - name: Install the specified package
      yum:
        name: "{{ package_name }}"
        state: present
      notify: start and enable service
      
    - name: Ensure the service is running
      service:
        name: "{{ service_name }}"
        state: started
        enabled: yes
        
    - name: Create a simple index.html file
      copy:
        content: |
          <html>
          <head><title>Ansible Lab 2</title></head>
          <body>
          <h1>Welcome to Ansible Playbook Lab!</h1>
          <p>This page was created by an Ansible playbook.</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: apache
        group: apache
        mode: '0644'
      notify: restart web service
        
  handlers:
    - name: start and enable service
      service:
        name: "{{ service_name }}"
        state: started
        enabled: yes
        
    - name: restart web service
      service:
        name: "{{ service_name }}"
        state: restarted
Save and exit the file (Ctrl+X, then Y, then Enter)
Subtask 1.3: Understanding Playbook Components
Let's break down the key components of our playbook:

Play Definition: • name: Descriptive name for the play • hosts: Target hosts or groups from inventory • become: Enables privilege escalation (sudo) • gather_facts: Collects system information

Variables Section: • vars: Defines variables used throughout the playbook • Variables can be referenced using Jinja2 templating syntax {{ variable_name }}

Tasks Section: • tasks: List of actions to perform on target hosts • Each task has a name and uses an Ansible module • notify: Triggers handlers when tasks make changes

Handlers Section: • handlers: Special tasks that run only when notified • Typically used for service restarts or configuration reloads

Task 2: Define Hosts and Create Inventory
Subtask 2.1: Create a Custom Inventory File
Create an inventory file for this lab:
nano inventory.ini
Add the following inventory configuration:
[managed_nodes]
node1 ansible_host=192.168.1.10 ansible_user=ansible
node2 ansible_host=192.168.1.11 ansible_user=ansible

[web_servers]
node1

[database_servers]
node2

[all:vars]
ansible_ssh_private_key_file=/home/ansible/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
Save and exit the file
Subtask 2.2: Verify Inventory and Connectivity
Test the inventory file:
ansible-inventory -i inventory.ini --list
Verify connectivity to managed nodes:
ansible -i inventory.ini managed_nodes -m ping
Check if you can gather facts from the nodes:
ansible -i inventory.ini managed_nodes -m setup --tree /tmp/facts
Task 3: Enhance the Playbook with Advanced Tasks and Handlers
Subtask 3.1: Create an Enhanced Playbook
Create a more comprehensive playbook:
nano enhanced-playbook.yml
Add the following enhanced content:
---
- name: Enhanced package installation and configuration
  hosts: managed_nodes
  become: yes
  gather_facts: yes
  
  vars:
    packages:
      - httpd
      - firewalld
      - wget
    web_port: 80
    document_root: /var/www/html
    
  pre_tasks:
    - name: Update package cache
      yum:
        update_cache: yes
      tags: always
      
  tasks:
    - name: Install required packages
      yum:
        name: "{{ packages }}"
        state: present
      notify:
        - start httpd
        - start firewalld
      tags: packages
      
    - name: Configure firewall for web traffic
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      notify: reload firewall
      tags: firewall
      
    - name: Create custom web content
      template:
        src: index.html.j2
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      notify: restart httpd
      tags: content
      
    - name: Ensure web service is running and enabled
      service:
        name: httpd
        state: started
        enabled: yes
      tags: services
      
    - name: Verify web service is responding
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ web_port }}"
        method: GET
        status_code: 200
      delegate_to: localhost
      tags: verification
      
  handlers:
    - name: start httpd
      service:
        name: httpd
        state: started
        enabled: yes
        
    - name: restart httpd
      service:
        name: httpd
        state: restarted
        
    - name: start firewalld
      service:
        name: firewalld
        state: started
        enabled: yes
        
    - name: reload firewall
      service:
        name: firewalld
        state: reloaded
        
  post_tasks:
    - name: Display completion message
      debug:
        msg: "Playbook execution completed successfully on {{ inventory_hostname }}"
Subtask 3.2: Create a Template File
Create a templates directory:
mkdir -p templates
Create a Jinja2 template for the web page:
nano templates/index.html.j2
Add the following template content:
<!DOCTYPE html>
<html>
<head>
    <title>{{ inventory_hostname }} - Ansible Lab 2</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .info { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Welcome to {{ inventory_hostname }}</h1>
    <div class="info">
        <h2>System Information</h2>
        <p><strong>Hostname:</strong> {{ ansible_hostname }}</p>
        <p><strong>Operating System:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
        <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
        <p><strong>Architecture:</strong> {{ ansible_architecture }}</p>
        <p><strong>Memory:</strong> {{ ansible_memtotal_mb }} MB</p>
        <p><strong>Processor:</strong> {{ ansible_processor[2] }}</p>
    </div>
    <p><em>This page was generated by Ansible on {{ ansible_date_time.iso8601 }}</em></p>
</body>
</html>
Save and exit the file
Task 4: Run the Playbook on Target Systems
Subtask 4.1: Execute the Basic Playbook
Run the first playbook with verbose output:
ansible-playbook -i inventory.ini install-package.yml -v
Check the playbook syntax before running:
ansible-playbook -i inventory.ini install-package.yml --syntax-check
Perform a dry run to see what would change:
ansible-playbook -i inventory.ini install-package.yml --check
Subtask 4.2: Execute the Enhanced Playbook
Run the enhanced playbook:
ansible-playbook -i inventory.ini enhanced-playbook.yml
Run specific tags only:
ansible-playbook -i inventory.ini enhanced-playbook.yml --tags "packages,firewall"
Skip specific tags:
ansible-playbook -i inventory.ini enhanced-playbook.yml --skip-tags "verification"
Subtask 4.3: Verify Playbook Results
Check if the web service is running on managed nodes:
ansible -i inventory.ini managed_nodes -m service -a "name=httpd state=started" --become
Verify the web content is accessible:
ansible -i inventory.ini managed_nodes -m uri -a "url=http://{{ ansible_default_ipv4.address }} method=GET"
Check the created files:
ansible -i inventory.ini managed_nodes -m file -a "path=/var/www/html/index.html" --become
Task 5: Troubleshooting and Best Practices
Subtask 5.1: Common Troubleshooting Techniques
Check playbook execution with maximum verbosity:
ansible-playbook -i inventory.ini enhanced-playbook.yml -vvv
Use the debug module to inspect variables:
nano debug-playbook.yml
Add this content: ```yaml
name: Debug playbook variables hosts: managed_nodes gather_facts: yes

tasks:

name: Display all variables for the host debug: var: hostvars[inventory_hostname]

name: Display specific facts debug: msg: | Hostname: {{ ansible_hostname }} IP Address: {{ ansible_default_ipv4.address }} OS: {{ ansible_distribution }}


3. **Run the debug playbook**:
```bash
ansible-playbook -i inventory.ini debug-playbook.yml
Subtask 5.2: Implement Error Handling
Create a playbook with error handling:
nano error-handling-playbook.yml
Add error handling mechanisms:
---
- name: Playbook with error handling
  hosts: managed_nodes
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Attempt to install a package that might fail
      yum:
        name: non-existent-package
        state: present
      ignore_errors: yes
      register: package_result
      
    - name: Display error message if package installation failed
      debug:
        msg: "Package installation failed: {{ package_result.msg }}"
      when: package_result.failed
      
    - name: Continue with other tasks regardless of previous failure
      file:
        path: /tmp/ansible-lab2-test
        state: touch
        mode: '0644'
      
    - name: Use block/rescue for complex error handling
      block:
        - name: Try to start a service that might not exist
          service:
            name: non-existent-service
            state: started
      rescue:
        - name: Handle the error gracefully
          debug:
            msg: "Service start failed, but we're handling it gracefully"
      always:
        - name: This always runs
          debug:
            msg: "This task always executes"
Execute the error handling playbook:
ansible-playbook -i inventory.ini error-handling-playbook.yml
Advanced Configuration and Best Practices
Creating Reusable Playbooks
Create a playbook with external variable files:
nano vars.yml
Add variable definitions: ```yaml
web_packages:

httpd
mod_ssl
php
database_packages:

mariadb-server
mariadb
common_packages:

vim
wget
curl
git

2. **Create a playbook that uses external variables**:
```bash
nano variable-playbook.yml
---
- name: Playbook using external variables
  hosts: managed_nodes
  become: yes
  vars_files:
    - vars.yml
    
  tasks:
    - name: Install web packages
      yum:
        name: "{{ web_packages }}"
        state: present
      when: inventory_hostname in groups['web_servers']
      
    - name: Install database packages
      yum:
        name: "{{ database_packages }}"
        state: present
      when: inventory_hostname in groups['database_servers']
      
    - name: Install common packages on all hosts
      yum:
        name: "{{ common_packages }}"
        state: present
Run the variable-based playbook:
ansible-playbook -i inventory.ini variable-playbook.yml
Verification and Testing
Final Verification Steps
Create a comprehensive verification playbook:
nano verify-setup.yml
---
- name: Verify lab setup and configuration
  hosts: managed_nodes
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Check if httpd is installed
      yum:
        list: httpd
      register: httpd_check
      
    - name: Verify httpd service status
      service:
        name: httpd
      register: httpd_status
      
    - name: Check if web content exists
      stat:
        path: /var/www/html/index.html
      register: web_content
      
    - name: Display verification results
      debug:
        msg: |
          HTTPD Package: {{ 'Installed' if httpd_check.results else 'Not Installed' }}
          HTTPD Service: {{ httpd_status.status.ActiveState }}
          Web Content: {{ 'Present' if web_content.stat.exists else 'Missing' }}
          
    - name: Test web connectivity
      uri:
        url: "http://{{ ansible_default_ipv4.address }}"
        method: GET
        status_code: 200
      delegate_to: localhost
      register: web_test
      
    - name: Display web test results
      debug:
        msg: "Web service is {{ 'responding' if web_test.status == 200 else 'not responding' }}"
Run the verification playbook:
ansible-playbook -i inventory.ini verify-setup.yml
Conclusion
Congratulations! You have successfully completed Lab 2: Understanding Playbooks. In this comprehensive lab, you have accomplished the following:

Key Achievements: • Created functional Ansible playbooks with proper YAML syntax and structure • Implemented hosts, tasks, and handlers to manage system configuration effectively • Executed playbooks against target systems using various ansible-playbook options • Learned advanced playbook features including variables, templates, and error handling • Developed troubleshooting skills for debugging playbook execution issues

Technical Skills Gained: • Understanding of playbook anatomy and best practices • Proficiency in using Ansible modules for package management and service control • Knowledge of Jinja2 templating for dynamic content generation • Experience with inventory management and host targeting • Familiarity with playbook execution options and debugging techniques

Why This Matters: Ansible playbooks are the foundation of infrastructure automation and configuration management. The skills you've developed in this lab are essential for: • Automating repetitive system administration tasks • Ensuring consistent configuration across multiple systems • Implementing Infrastructure as Code (IaC) practices • Preparing for Red Hat Ansible certification exams • Building scalable and maintainable automation solutions

Next Steps: You are now ready to advance to more complex Ansible topics such as roles, advanced templating, and integration with other automation tools. The foundation you've built here will serve you well as you continue your journey in automation and DevOps practices.

Remember to practice these concepts regularly and experiment with different playbook structures to deepen your understanding of Ansible's capabilities.
