Lab 3: Writing Simple Ansible Playbooks
Objectives
By the end of this lab, you will be able to:

Understand the structure and syntax of Ansible playbooks
Write a basic Ansible playbook to automate package installation and configuration
Execute playbooks using the ansible-playbook command
Verify and test playbook idempotency
Troubleshoot common playbook execution issues
Apply best practices for playbook organization and documentation
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with YAML syntax and formatting
Completion of previous Ansible labs covering inventory and ad-hoc commands
Basic knowledge of system administration concepts (packages, services, configuration files)
Understanding of SSH key-based authentication
Required Knowledge Areas
Linux file system navigation
Text editing using vi/vim or nano
Basic networking concepts
Package management concepts (yum, apt, dnf)
Lab Environment
Al Nafi Cloud Machines: This lab uses pre-configured Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your environment - no VM setup required!

Your lab environment includes:

Control Node: CentOS/RHEL 8 or 9 with Ansible pre-installed
Managed Nodes: 2-3 target systems for playbook execution
Pre-configured SSH connectivity between nodes
Sample inventory files and directory structure
Task 1: Create an Ansible Playbook to Install and Configure a Package
Subtask 1.1: Set Up the Playbook Directory Structure
First, let's create a proper directory structure for our Ansible project.

Navigate to your home directory and create the project structure:
cd ~
mkdir ansible-lab3
cd ansible-lab3
mkdir playbooks group_vars host_vars
Create the inventory file:
cat > inventory << 'EOF'
[webservers]
node1 ansible_host=192.168.1.10
node2 ansible_host=192.168.1.11

[dbservers]
node3 ansible_host=192.168.1.12

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
Verify connectivity to managed nodes:
ansible all -i inventory -m ping
Expected Output:

node1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
Subtask 1.2: Write Your First Playbook
Now we'll create a playbook to install and configure the Apache web server.

Create the main playbook file:
cat > playbooks/webserver-setup.yml << 'EOF'
---
- name: Install and Configure Apache Web Server
  hosts: webservers
  become: yes
  vars:
    http_port: 80
    max_clients: 200
    document_root: /var/www/html
    
  tasks:
    - name: Install Apache HTTP Server
      package:
        name: httpd
        state: present
      tags:
        - packages
        - apache
    
    - name: Install additional packages
      package:
        name:
          - wget
          - curl
          - vim
        state: present
      tags:
        - packages
    
    - name: Create custom index.html
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Welcome to {{ inventory_hostname }}</title>
          </head>
          <body>
              <h1>Hello from {{ inventory_hostname }}</h1>
              <p>This server was configured by Ansible!</p>
              <p>Server IP: {{ ansible_default_ipv4.address }}</p>
              <p>Configured on: {{ ansible_date_time.date }}</p>
          </body>
          </html>
        dest: "{{ document_root }}/index.html"
        owner: apache
        group: apache
        mode: '0644'
      tags:
        - content
    
    - name: Configure Apache main configuration
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        regexp: '^Listen '
        line: "Listen {{ http_port }}"
        backup: yes
      notify:
        - restart apache
      tags:
        - configuration
    
    - name: Configure MaxRequestWorkers
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        regexp: '^#?MaxRequestWorkers'
        line: "MaxRequestWorkers {{ max_clients }}"
        backup: yes
      notify:
        - restart apache
      tags:
        - configuration
    
    - name: Ensure Apache is started and enabled
      service:
        name: httpd
        state: started
        enabled: yes
      tags:
        - services
    
    - name: Open firewall for HTTP
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
      tags:
        - firewall
      ignore_errors: yes
  
  handlers:
    - name: restart apache
      service:
        name: httpd
        state: restarted
EOF
Subtask 1.3: Understanding Playbook Components
Let's break down the key components of our playbook:

Playbook Header:

name: Descriptive name for the playbook
hosts: Target group from inventory
become: Escalate privileges (sudo)
vars: Variables used throughout the playbook
Tasks Section:

Each task has a name for documentation
Uses Ansible modules (package, copy, lineinfile, etc.)
tags allow selective execution
notify triggers handlers when changes occur
Handlers Section:

Special tasks that run only when notified
Typically used for service restarts
Subtask 1.4: Create a Database Server Playbook
Let's create another playbook for database servers:

cat > playbooks/database-setup.yml << 'EOF'
---
- name: Install and Configure MariaDB Database Server
  hosts: dbservers
  become: yes
  vars:
    mysql_root_password: "SecurePassword123!"
    mysql_port: 3306
    
  tasks:
    - name: Install MariaDB server and client
      package:
        name:
          - mariadb-server
          - mariadb
          - python3-PyMySQL
        state: present
      tags:
        - packages
        - database
    
    - name: Start and enable MariaDB service
      service:
        name: mariadb
        state: started
        enabled: yes
      tags:
        - services
    
    - name: Set MariaDB root password
      mysql_user:
        name: root
        password: "{{ mysql_root_password }}"
        login_unix_socket: /var/lib/mysql/mysql.sock
        state: present
      tags:
        - security
    
    - name: Create database configuration file
      copy:
        content: |
          [mysql]
          port={{ mysql_port }}
          socket=/var/lib/mysql/mysql.sock
          
          [mysqld]
          port={{ mysql_port }}
          socket=/var/lib/mysql/mysql.sock
          datadir=/var/lib/mysql
          log-error=/var/log/mariadb/mariadb.log
          pid-file=/var/run/mariadb/mariadb.pid
        dest: /etc/my.cnf.d/custom.cnf
        owner: root
        group: root
        mode: '0644'
      notify:
        - restart mariadb
      tags:
        - configuration
    
    - name: Open firewall for MySQL
      firewalld:
        port: "{{ mysql_port }}/tcp"
        permanent: yes
        state: enabled
        immediate: yes
      tags:
        - firewall
      ignore_errors: yes
  
  handlers:
    - name: restart mariadb
      service:
        name: mariadb
        state: restarted
EOF
Task 2: Run the Playbook Using ansible-playbook
Subtask 2.1: Syntax Check and Dry Run
Before executing the playbook, let's perform validation checks:

Check playbook syntax:
ansible-playbook -i inventory playbooks/webserver-setup.yml --syntax-check
Expected Output:

playbook: playbooks/webserver-setup.yml
Perform a dry run (check mode):
ansible-playbook -i inventory playbooks/webserver-setup.yml --check
This shows what changes would be made without actually executing them.

Run with increased verbosity for troubleshooting:
ansible-playbook -i inventory playbooks/webserver-setup.yml --check -v
Subtask 2.2: Execute the Webserver Playbook
Run the complete webserver playbook:
ansible-playbook -i inventory playbooks/webserver-setup.yml
Expected Output:

PLAY [Install and Configure Apache Web Server] ********************************

TASK [Gathering Facts] *********************************************************
ok: [node1]
ok: [node2]

TASK [Install Apache HTTP Server] *********************************************
changed: [node1]
changed: [node2]

TASK [Install additional packages] ********************************************
changed: [node1]
changed: [node2]

TASK [Create custom index.html] ***********************************************
changed: [node1]
changed: [node2]

TASK [Configure Apache main configuration] ************************************
changed: [node1]
changed: [node2]

TASK [Configure MaxRequestWorkers] ********************************************
changed: [node1]
changed: [node2]

TASK [Ensure Apache is started and enabled] ***********************************
changed: [node1]
changed: [node2]

TASK [Open firewall for HTTP] *************************************************
changed: [node1]
changed: [node2]

RUNNING HANDLER [restart apache] **********************************************
changed: [node1]
changed: [node2]

PLAY RECAP *********************************************************************
node1                      : ok=9    changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node2                      : ok=9    changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Verify the web server is working:
# Test from the control node
curl http://node1
curl http://node2

# Or check service status
ansible webservers -i inventory -m service -a "name=httpd state=started" --become
Subtask 2.3: Execute the Database Playbook
Run the database server playbook:
ansible-playbook -i inventory playbooks/database-setup.yml
Verify database installation:
ansible dbservers -i inventory -m service -a "name=mariadb state=started" --become
Subtask 2.4: Using Tags for Selective Execution
Tags allow you to run specific parts of a playbook:

Run only package installation tasks:
ansible-playbook -i inventory playbooks/webserver-setup.yml --tags "packages"
Run only configuration tasks:
ansible-playbook -i inventory playbooks/webserver-setup.yml --tags "configuration"
Skip certain tasks:
ansible-playbook -i inventory playbooks/webserver-setup.yml --skip-tags "firewall"
List all available tags:
ansible-playbook -i inventory playbooks/webserver-setup.yml --list-tags
Task 3: Test Idempotency by Re-running the Playbook
Subtask 3.1: Understanding Idempotency
Idempotency means that running the same playbook multiple times produces the same result without making unnecessary changes.

Re-run the webserver playbook:
ansible-playbook -i inventory playbooks/webserver-setup.yml
Expected Output (Second Run):

PLAY [Install and Configure Apache Web Server] ********************************

TASK [Gathering Facts] *********************************************************
ok: [node1]
ok: [node2]

TASK [Install Apache HTTP Server] *********************************************
ok: [node1]
ok: [node2]

TASK [Install additional packages] ********************************************
ok: [node1]
ok: [node2]

TASK [Create custom index.html] ***********************************************
ok: [node1]
ok: [node2]

TASK [Configure Apache main configuration] ************************************
ok: [node1]
ok: [node2]

TASK [Configure MaxRequestWorkers] ********************************************
ok: [node1]
ok: [node2]

TASK [Ensure Apache is started and enabled] ***********************************
ok: [node1]
ok: [node2]

TASK [Open firewall for HTTP] *************************************************
ok: [node1]
ok: [node2]

PLAY RECAP *********************************************************************
node1                      : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node2                      : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Key Observations:

All tasks show ok status instead of changed
changed=0 in the PLAY RECAP
No handlers were triggered since no changes occurred
Subtask 3.2: Testing Idempotency with Modifications
Let's test what happens when we make a change:

Modify the index.html file manually on one node:
ansible node1 -i inventory -m shell -a "echo 'Modified manually' > /var/www/html/index.html" --become
Re-run the playbook:
ansible-playbook -i inventory playbooks/webserver-setup.yml
Expected Result:

The Create custom index.html task will show changed for node1
Other tasks will remain ok
This demonstrates Ansible's ability to detect and correct configuration drift
Subtask 3.3: Verifying Idempotency Best Practices
Create a test playbook to demonstrate non-idempotent vs idempotent tasks:
cat > playbooks/idempotency-test.yml << 'EOF'
---
- name: Idempotency Testing Examples
  hosts: webservers
  become: yes
  
  tasks:
    # NON-IDEMPOTENT EXAMPLE (avoid this)
    - name: Bad example - always runs command
      shell: echo "Current time: $(date)" >> /tmp/timestamps.log
      tags:
        - bad-example
    
    # IDEMPOTENT EXAMPLES (recommended)
    - name: Good example - create file with specific content
      copy:
        content: "This file was created by Ansible\n"
        dest: /tmp/ansible-managed.txt
        owner: root
        group: root
        mode: '0644'
      tags:
        - good-example
    
    - name: Good example - ensure directory exists
      file:
        path: /opt/myapp
        state: directory
        owner: root
        group: root
        mode: '0755'
      tags:
        - good-example
    
    - name: Good example - conditional command execution
      shell: echo "First run" > /tmp/first-run.txt
      args:
        creates: /tmp/first-run.txt
      tags:
        - good-example
EOF
Run the test playbook multiple times:
# First run
ansible-playbook -i inventory playbooks/idempotency-test.yml --tags "good-example"

# Second run - should show no changes
ansible-playbook -i inventory playbooks/idempotency-test.yml --tags "good-example"
Compare with non-idempotent task:
# Run the bad example twice
ansible-playbook -i inventory playbooks/idempotency-test.yml --tags "bad-example"
ansible-playbook -i inventory playbooks/idempotency-test.yml --tags "bad-example"

# Check the result
ansible webservers -i inventory -m shell -a "cat /tmp/timestamps.log" --become
Subtask 3.4: Advanced Idempotency Testing
Create a comprehensive test script:
cat > test-idempotency.sh << 'EOF'
#!/bin/bash

echo "=== Testing Playbook Idempotency ==="
echo "Running playbook first time..."
ansible-playbook -i inventory playbooks/webserver-setup.yml > first-run.log 2>&1

echo "Running playbook second time..."
ansible-playbook -i inventory playbooks/webserver-setup.yml > second-run.log 2>&1

echo "Checking for changes in second run..."
if grep -q "changed=0" second-run.log; then
    echo "✓ PASS: Playbook is idempotent"
else
    echo "✗ FAIL: Playbook made unexpected changes"
    echo "Changes detected:"
    grep "changed:" second-run.log
fi

echo "=== Summary ==="
echo "First run:"
grep "PLAY RECAP" -A 10 first-run.log
echo ""
echo "Second run:"
grep "PLAY RECAP" -A 10 second-run.log
EOF

chmod +x test-idempotency.sh
Execute the idempotency test:
./test-idempotency.sh
Troubleshooting Common Issues
Issue 1: SSH Connection Problems
Symptoms:

UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh"}
Solutions:

# Check SSH connectivity
ssh -i ~/.ssh/id_rsa ansible@node1

# Verify inventory configuration
ansible-inventory -i inventory --list

# Test with verbose output
ansible all -i inventory -m ping -vvv
Issue 2: Permission Denied Errors
Symptoms:

FAILED! => {"changed": false, "msg": "Could not create file"}
Solutions:

# Ensure become is enabled
ansible-playbook -i inventory playbooks/webserver-setup.yml --become

# Check sudo permissions
ansible all -i inventory -m shell -a "sudo whoami" --become
Issue 3: Package Installation Failures
Symptoms:

FAILED! => {"changed": false, "msg": "No package matching 'httpd' found available"}
Solutions:

# Check package manager and OS
ansible all -i inventory -m setup -a "filter=ansible_os_family"

# Use appropriate package names for different OS families
# For Ubuntu/Debian: apache2
# For RHEL/CentOS: httpd
Issue 4: Handler Not Triggering
Symptoms:

Service not restarting after configuration changes
Solutions:

# Ensure handler name matches notify exactly
# Check for syntax errors in handlers section
ansible-playbook -i inventory playbooks/webserver-setup.yml --syntax-check

# Force handler execution
ansible-playbook -i inventory playbooks/webserver-setup.yml --force-handlers
Best Practices Summary
Playbook Organization
Use descriptive names for plays and tasks
Organize playbooks in logical directory structures
Use tags for selective execution
Implement proper error handling
Idempotency Guidelines
Use appropriate modules (avoid shell/command when possible)
Implement conditional execution with creates, removes, or when
Test playbooks multiple times during development
Use changed_when and failed_when for custom conditions
Security Considerations
Store sensitive data in Ansible Vault
Use least privilege principle with become
Validate input parameters
Implement proper file permissions
Conclusion
In this lab, you have successfully:

Created comprehensive Ansible playbooks that automate the installation and configuration of web servers and database servers
Executed playbooks using ansible-playbook with various options including syntax checking, dry runs, and selective execution using tags
Tested and verified idempotency by running playbooks multiple times and confirming that no unnecessary changes occur on subsequent runs
Learned troubleshooting techniques for common playbook execution issues
Applied best practices for playbook organization, security, and maintainability
Why This Matters
Automation and Consistency: Ansible playbooks provide a reliable, repeatable way to configure systems, eliminating manual errors and ensuring consistent deployments across environments.

Infrastructure as Code: By writing playbooks, you're implementing Infrastructure as Code (IaC) principles, making your infrastructure configurations version-controlled, testable, and auditable.

Career Relevance: These skills are essential for the Red Hat Certified Engineer (RHCE) certification and are highly valued in DevOps, system administration, and cloud engineering roles.

Scalability: The techniques learned here scale from managing a few servers to orchestrating thousands of systems in enterprise environments.

You now have the foundational skills to create, execute, and maintain Ansible playbooks for automating complex system administration tasks. Continue practicing by creating playbooks for different scenarios and exploring advanced Ansible features like roles, variables, and conditionals.
