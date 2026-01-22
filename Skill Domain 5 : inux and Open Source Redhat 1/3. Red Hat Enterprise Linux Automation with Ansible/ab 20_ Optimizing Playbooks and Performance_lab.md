Lab 20: Optimizing Playbooks and Performance
Objectives
By the end of this lab, students will be able to:

• Understand playbook optimization principles and best practices for Ansible automation • Split large playbooks into modular roles to improve maintainability and reusability • Implement asynchronous execution and delegation to enhance task performance • Test and measure playbook efficiency in simulated large-scale environments • Apply performance tuning techniques to optimize Ansible playbook execution • Troubleshoot common performance bottlenecks in Ansible automation

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Ansible fundamentals (playbooks, tasks, modules) • Familiarity with YAML syntax and Ansible playbook structure • Knowledge of Linux command line operations • Understanding of SSH connectivity and remote system management • Completion of previous Ansible labs or equivalent experience • Basic understanding of system administration concepts

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or configure infrastructure.

Your lab environment includes: • Control Node: CentOS/RHEL 8 with Ansible pre-installed • Managed Nodes: 3 target systems for testing optimization techniques • Pre-configured SSH keys for seamless connectivity • Sample applications and services for performance testing

Task 1: Split Large Playbooks into Roles for Modularity
Subtask 1.1: Analyze a Monolithic Playbook
First, let's examine a large, unoptimized playbook to understand the problems with monolithic structures.

Connect to your control node and navigate to the lab directory:
cd /home/ansible/lab20
ls -la
Examine the monolithic playbook:
cat large-playbook.yml
This playbook contains multiple responsibilities mixed together - web server setup, database configuration, application deployment, and monitoring setup.

Identify the different functional areas in the playbook: • Web server configuration (Apache/Nginx) • Database setup (MySQL/PostgreSQL) • Application deployment • Monitoring and logging setup • Security hardening
Subtask 1.2: Create Role Structure
Now we'll break this monolithic playbook into organized roles.

Create the roles directory structure:
mkdir -p roles/{webserver,database,application,monitoring,security}/{tasks,handlers,templates,files,vars,defaults,meta}
Verify the role structure:
tree roles/
Subtask 1.3: Extract Web Server Role
Create the webserver role tasks:
cat > roles/webserver/tasks/main.yml << 'EOF'
---
- name: Install web server packages
  package:
    name: "{{ webserver_packages }}"
    state: present
  notify: restart webserver

- name: Configure web server
  template:
    src: "{{ webserver_config_template }}"
    dest: "{{ webserver_config_path }}"
    backup: yes
  notify: restart webserver

- name: Start and enable web server
  service:
    name: "{{ webserver_service }}"
    state: started
    enabled: yes

- name: Configure firewall for web server
  firewalld:
    service: "{{ item }}"
    permanent: yes
    state: enabled
    immediate: yes
  loop: "{{ webserver_firewall_services }}"
  when: ansible_facts['os_family'] == "RedHat"
EOF
Create webserver role defaults:
cat > roles/webserver/defaults/main.yml << 'EOF'
---
webserver_packages:
  - httpd
  - mod_ssl
webserver_service: httpd
webserver_config_template: httpd.conf.j2
webserver_config_path: /etc/httpd/conf/httpd.conf
webserver_firewall_services:
  - http
  - https
EOF
Create webserver role handlers:
cat > roles/webserver/handlers/main.yml << 'EOF'
---
- name: restart webserver
  service:
    name: "{{ webserver_service }}"
    state: restarted
EOF
Create a basic web server configuration template:
cat > roles/webserver/templates/httpd.conf.j2 << 'EOF'
ServerRoot /etc/httpd
Listen 80
Listen 443 ssl

User apache
Group apache

ServerAdmin admin@{{ ansible_fqdn }}
ServerName {{ ansible_fqdn }}

DocumentRoot /var/www/html

<Directory "/var/www/html">
    AllowOverride None
    Require all granted
</Directory>

ErrorLog logs/error_log
CustomLog logs/access_log combined

LoadModule ssl_module modules/mod_ssl.so
Include conf.d/*.conf
EOF
Subtask 1.4: Extract Database Role
Create the database role tasks:
cat > roles/database/tasks/main.yml << 'EOF'
---
- name: Install database packages
  package:
    name: "{{ database_packages }}"
    state: present

- name: Start and enable database service
  service:
    name: "{{ database_service }}"
    state: started
    enabled: yes

- name: Configure database
  template:
    src: "{{ database_config_template }}"
    dest: "{{ database_config_path }}"
    backup: yes
  notify: restart database

- name: Create application database
  mysql_db:
    name: "{{ app_database_name }}"
    state: present
  when: database_type == "mysql"

- name: Create database user
  mysql_user:
    name: "{{ app_database_user }}"
    password: "{{ app_database_password }}"
    priv: "{{ app_database_name }}.*:ALL"
    state: present
  when: database_type == "mysql"
EOF
Create database role defaults:
cat > roles/database/defaults/main.yml << 'EOF'
---
database_type: mysql
database_packages:
  - mariadb-server
  - mariadb
  - python3-PyMySQL
database_service: mariadb
database_config_template: my.cnf.j2
database_config_path: /etc/my.cnf.d/server.cnf
app_database_name: webapp
app_database_user: webuser
app_database_password: "{{ vault_db_password | default('changeme') }}"
EOF
Create database role handlers:
cat > roles/database/handlers/main.yml << 'EOF'
---
- name: restart database
  service:
    name: "{{ database_service }}"
    state: restarted
EOF
Subtask 1.5: Create Application Role
Create the application role tasks:
cat > roles/application/tasks/main.yml << 'EOF'
---
- name: Create application directory
  file:
    path: "{{ app_directory }}"
    state: directory
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0755'

- name: Deploy application files
  copy:
    src: "{{ item }}"
    dest: "{{ app_directory }}/"
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0644'
  loop: "{{ app_files }}"
  notify: restart webserver

- name: Configure application
  template:
    src: app-config.php.j2
    dest: "{{ app_directory }}/config.php"
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0640'
  notify: restart webserver
EOF
Create application role defaults:
cat > roles/application/defaults/main.yml << 'EOF'
---
app_directory: /var/www/html
app_user: apache
app_group: apache
app_files:
  - index.php
  - style.css
EOF
Subtask 1.6: Create the Optimized Main Playbook
Create the new modular playbook:
cat > optimized-playbook.yml << 'EOF'
---
- name: Deploy Web Application Infrastructure
  hosts: webservers
  become: yes
  gather_facts: yes
  
  roles:
    - role: security
      tags: security
    - role: database
      tags: database
    - role: webserver
      tags: webserver
    - role: application
      tags: application
    - role: monitoring
      tags: monitoring

  post_tasks:
    - name: Verify web service is accessible
      uri:
        url: "http://{{ ansible_fqdn }}"
        method: GET
        status_code: 200
      delegate_to: localhost
      tags: verification
EOF
Create a site.yml for orchestration:
cat > site.yml << 'EOF'
---
- import_playbook: optimized-playbook.yml

- name: Post-deployment tasks
  hosts: webservers
  become: yes
  tasks:
    - name: Display deployment summary
      debug:
        msg: |
          Deployment completed successfully!
          Web server: {{ ansible_fqdn }}
          Database: {{ database_type }}
          Application directory: {{ app_directory }}
EOF
Task 2: Use Asynchronous Execution and Delegation to Optimize Task Performance
Subtask 2.1: Implement Asynchronous Task Execution
Asynchronous execution allows long-running tasks to run in the background, improving overall playbook performance.

Create an async optimization playbook:
cat > async-optimization.yml << 'EOF'
---
- name: Demonstrate Asynchronous Task Execution
  hosts: all
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Start long-running package updates (async)
      yum:
        name: '*'
        state: latest
      async: 300  # Maximum time to wait (5 minutes)
      poll: 0     # Don't wait for completion
      register: package_update_job
      
    - name: Start service configuration (async)
      service:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - chronyd
        - rsyslog
      async: 60
      poll: 0
      register: service_jobs
      
    - name: Perform other tasks while async jobs run
      debug:
        msg: "Performing other configuration tasks..."
        
    - name: Configure system settings
      sysctl:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
        state: present
        reload: yes
      loop:
        - { name: 'net.ipv4.ip_forward', value: '0' }
        - { name: 'net.ipv4.conf.all.rp_filter', value: '1' }
        
    - name: Wait for package update to complete
      async_status:
        jid: "{{ package_update_job.ansible_job_id }}"
      register: package_result
      until: package_result.finished
      retries: 30
      delay: 10
      when: package_update_job.ansible_job_id is defined
      
    - name: Check async service jobs
      async_status:
        jid: "{{ item.ansible_job_id }}"
      register: service_results
      until: service_results.finished
      retries: 10
      delay: 5
      loop: "{{ service_jobs.results }}"
      when: item.ansible_job_id is defined
EOF
Subtask 2.2: Implement Task Delegation
Task delegation allows you to run tasks on different hosts than the current target, optimizing resource usage.

Create a delegation optimization playbook:
cat > delegation-optimization.yml << 'EOF'
---
- name: Demonstrate Task Delegation for Performance
  hosts: webservers
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Generate SSL certificate on control node
      command: >
        openssl req -x509 -nodes -days 365 -newkey rsa:2048
        -keyout /tmp/{{ inventory_hostname }}.key
        -out /tmp/{{ inventory_hostname }}.crt
        -subj "/C=US/ST=State/L=City/O=Organization/CN={{ ansible_fqdn }}"
      delegate_to: localhost
      run_once: true
      
    - name: Download large files on control node (once)
      get_url:
        url: "{{ item.url }}"
        dest: "/tmp/{{ item.name }}"
        mode: '0644'
      loop:
        - { url: 'https://releases.ubuntu.com/20.04/ubuntu-20.04.6-desktop-amd64.iso', name: 'ubuntu.iso' }
      delegate_to: localhost
      run_once: true
      when: download_large_files | default(false)
      
    - name: Perform DNS lookups on control node
      command: nslookup {{ ansible_fqdn }}
      delegate_to: localhost
      register: dns_result
      
    - name: Log deployment status to central server
      uri:
        url: "http://monitoring-server/api/deployments"
        method: POST
        body_format: json
        body:
          hostname: "{{ inventory_hostname }}"
          status: "deploying"
          timestamp: "{{ ansible_date_time.iso8601 }}"
      delegate_to: localhost
      ignore_errors: yes
      
    - name: Copy files from control node to targets
      copy:
        src: "/tmp/{{ inventory_hostname }}.crt"
        dest: "/etc/ssl/certs/server.crt"
        mode: '0644'
      notify: restart webserver
      
    - name: Verify connectivity from control node
      wait_for:
        host: "{{ ansible_fqdn }}"
        port: 80
        timeout: 30
      delegate_to: localhost
EOF
Subtask 2.3: Optimize with Parallel Execution
Create a parallel execution optimization playbook:
cat > parallel-optimization.yml << 'EOF'
---
- name: Parallel Execution Optimization
  hosts: all
  become: yes
  gather_facts: yes
  strategy: free  # Allow hosts to run independently
  
  tasks:
    - name: Update system packages (parallel across hosts)
      package:
        name: '*'
        state: latest
      async: 600
      poll: 0
      register: update_job
      
    - name: Configure multiple services in parallel
      service:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - firewalld
        - chronyd
        - rsyslog
      async: 30
      poll: 0
      register: service_jobs
      
    - name: Create multiple directories simultaneously
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - /opt/app1
        - /opt/app2
        - /opt/app3
        - /var/log/apps
        - /etc/apps
      
    - name: Wait for package updates to complete
      async_status:
        jid: "{{ update_job.ansible_job_id }}"
      register: update_result
      until: update_result.finished
      retries: 60
      delay: 10
      when: update_job.ansible_job_id is defined
      
    - name: Verify all services are running
      service:
        name: "{{ item }}"
        state: started
      loop:
        - firewalld
        - chronyd
        - rsyslog
EOF
Task 3: Test the Efficiency of Playbooks in Large Environments
Subtask 3.1: Create Performance Testing Framework
Create a performance testing playbook:
cat > performance-test.yml << 'EOF'
---
- name: Performance Testing Framework
  hosts: localhost
  gather_facts: no
  vars:
    test_results: []
    
  tasks:
    - name: Record test start time
      set_fact:
        test_start_time: "{{ ansible_date_time.epoch }}"
        
    - name: Test original monolithic playbook performance
      include_tasks: run-performance-test.yml
      vars:
        test_name: "Monolithic Playbook"
        playbook_to_test: "large-playbook.yml"
        
    - name: Test optimized role-based playbook performance
      include_tasks: run-performance-test.yml
      vars:
        test_name: "Role-based Playbook"
        playbook_to_test: "optimized-playbook.yml"
        
    - name: Test async optimization performance
      include_tasks: run-performance-test.yml
      vars:
        test_name: "Async Optimized"
        playbook_to_test: "async-optimization.yml"
        
    - name: Generate performance report
      template:
        src: performance-report.j2
        dest: "/tmp/performance-report-{{ ansible_date_time.epoch }}.html"
      vars:
        total_test_time: "{{ ansible_date_time.epoch | int - test_start_time | int }}"
EOF
Create the performance test task file:
cat > run-performance-test.yml << 'EOF'
---
- name: "Execute {{ test_name }}"
  block:
    - name: Record test start time
      set_fact:
        current_test_start: "{{ ansible_date_time.epoch }}"
        
    - name: Run playbook with timing
      command: >
        ansible-playbook {{ playbook_to_test }}
        -i inventory
        --check
        -v
      register: playbook_result
      ignore_errors: yes
      
    - name: Record test end time
      set_fact:
        current_test_end: "{{ ansible_date_time.epoch }}"
        
    - name: Calculate execution time
      set_fact:
        execution_time: "{{ current_test_end | int - current_test_start | int }}"
        
    - name: Store test results
      set_fact:
        test_results: "{{ test_results + [test_result] }}"
      vars:
        test_result:
          name: "{{ test_name }}"
          execution_time: "{{ execution_time }}"
          status: "{{ 'PASSED' if playbook_result.rc == 0 else 'FAILED' }}"
          output_lines: "{{ playbook_result.stdout_lines | length }}"
EOF
Subtask 3.2: Create Inventory for Large Environment Testing
Create a large inventory file for testing:
cat > large-inventory << 'EOF'
[webservers]
web01 ansible_host=192.168.1.10
web02 ansible_host=192.168.1.11
web03 ansible_host=192.168.1.12
web04 ansible_host=192.168.1.13
web05 ansible_host=192.168.1.14

[databases]
db01 ansible_host=192.168.1.20
db02 ansible_host=192.168.1.21

[loadbalancers]
lb01 ansible_host=192.168.1.30

[monitoring]
mon01 ansible_host=192.168.1.40

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
Create ansible.cfg for optimization:
cat > ansible.cfg << 'EOF'
[defaults]
inventory = large-inventory
remote_user = ansible
private_key_file = ~/.ssh/id_rsa
host_key_checking = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 3600
forks = 20
timeout = 30
retry_files_enabled = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
EOF
Subtask 3.3: Implement Performance Monitoring
Create a performance monitoring playbook:
cat > monitor-performance.yml << 'EOF'
---
- name: Monitor Playbook Performance
  hosts: localhost
  gather_facts: yes
  vars:
    performance_metrics: []
    
  tasks:
    - name: Create performance log directory
      file:
        path: /tmp/ansible-performance
        state: directory
        mode: '0755'
        
    - name: Start system resource monitoring
      shell: |
        (while true; do
          echo "$(date): CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1), MEM: $(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')" >> /tmp/ansible-performance/system-metrics.log
          sleep 5
        done) &
        echo $! > /tmp/ansible-performance/monitor.pid
      
    - name: Run performance test with different fork values
      include_tasks: fork-performance-test.yml
      loop:
        - 5
        - 10
        - 20
        - 50
      loop_control:
        loop_var: fork_count
        
    - name: Stop system monitoring
      shell: |
        if [ -f /tmp/ansible-performance/monitor.pid ]; then
          kill $(cat /tmp/ansible-performance/monitor.pid)
          rm /tmp/ansible-performance/monitor.pid
        fi
        
    - name: Generate performance comparison report
      template:
        src: fork-comparison-report.j2
        dest: /tmp/ansible-performance/fork-comparison.html
EOF
Create fork performance test tasks:
cat > fork-performance-test.yml << 'EOF'
---
- name: "Test with {{ fork_count }} forks"
  block:
    - name: Update ansible.cfg with current fork count
      lineinfile:
        path: ansible.cfg
        regexp: '^forks'
        line: "forks = {{ fork_count }}"
        
    - name: Record test start time
      set_fact:
        fork_test_start: "{{ ansible_date_time.epoch }}"
        
    - name: Run test playbook
      command: ansible-playbook optimized-playbook.yml --check -v
      register: fork_test_result
      ignore_errors: yes
      
    - name: Record test end time
      set_fact:
        fork_test_end: "{{ ansible_date_time.epoch }}"
        
    - name: Store fork test results
      set_fact:
        performance_metrics: "{{ performance_metrics + [metric] }}"
      vars:
        metric:
          forks: "{{ fork_count }}"
          execution_time: "{{ fork_test_end | int - fork_test_start | int }}"
          status: "{{ 'SUCCESS' if fork_test_result.rc == 0 else 'FAILED' }}"
          tasks_executed: "{{ fork_test_result.stdout_lines | select('match', '.*TASK.*') | list | length }}"
EOF
Subtask 3.4: Create Benchmarking Scripts
Create a comprehensive benchmarking script:
cat > benchmark-playbooks.sh << 'EOF'
#!/bin/bash

# Ansible Playbook Performance Benchmarking Script
set -e

RESULTS_DIR="/tmp/ansible-benchmarks"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${RESULTS_DIR}/benchmark_report_${TIMESTAMP}.txt"

# Create results directory
mkdir -p "$RESULTS_DIR"

echo "Ansible Playbook Performance Benchmark - $(date)" > "$REPORT_FILE"
echo "=================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Function to run benchmark
run_benchmark() {
    local playbook=$1
    local description=$2
    local iterations=${3:-3}
    
    echo "Testing: $description" | tee -a "$REPORT_FILE"
    echo "Playbook: $playbook" | tee -a "$REPORT_FILE"
    echo "Iterations: $iterations" | tee -a "$REPORT_FILE"
    echo "----------------------------------------" | tee -a "$REPORT_FILE"
    
    local total_time=0
    local successful_runs=0
    
    for i in $(seq 1 $iterations); do
        echo "  Run $i of $iterations..."
        start_time=$(date +%s)
        
        if ansible-playbook "$playbook" --check -v > "${RESULTS_DIR}/run_${i}_output.log" 2>&1; then
            end_time=$(date +%s)
            run_time=$((end_time - start_time))
            total_time=$((total_time + run_time))
            successful_runs=$((successful_runs + 1))
            echo "    Completed in ${run_time}s" | tee -a "$REPORT_FILE"
        else
            echo "    FAILED" | tee -a "$REPORT_FILE"
        fi
    done
    
    if [ $successful_runs -gt 0 ]; then
        avg_time=$((total_time / successful_runs))
        echo "  Average execution time: ${avg_time}s" | tee -a "$REPORT_FILE"
        echo "  Successful runs: $successful_runs/$iterations" | tee -a "$REPORT_FILE"
    else
        echo "  All runs failed!" | tee -a "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Run benchmarks
echo "Starting Ansible playbook benchmarks..."

run_benchmark "large-playbook.yml" "Original Monolithic Playbook" 3
run_benchmark "optimized-playbook.yml" "Role-based Optimized Playbook" 3
run_benchmark "async-optimization.yml" "Asynchronous Execution Playbook" 3

echo "Benchmark completed. Results saved to: $REPORT_FILE"
echo "Individual run logs saved to: $RESULTS_DIR"
EOF
Make the script executable and run it:
chmod +x benchmark-playbooks.sh
./benchmark-playbooks.sh
Subtask 3.5: Analyze Performance Results
Create a performance analysis playbook:
cat > analyze-performance.yml << 'EOF'
---
- name: Analyze Playbook Performance Results
  hosts: localhost
  gather_facts: yes
  vars:
    analysis_results: {}
    
  tasks:
    - name: Find benchmark result files
      find:
        paths: /tmp/ansible-benchmarks
        patterns: "benchmark_report_*.txt"
      register: benchmark_files
      
    - name: Read benchmark results
      slurp:
        src: "{{ item.path }}"
      register: benchmark_content
      loop: "{{ benchmark_files.files }}"
      
    - name: Parse performance data
      set_fact:
        performance_data: "{{ performance_data | default([]) + [parsed_data] }}"
      vars:
        parsed_data:
          file: "{{ item.item.path }}"
          content: "{{ item.content | b64decode }}"
          timestamp: "{{ item.item.path | regex_search('\\d{8}_\\d{6}') }}"
      loop: "{{ benchmark_content.results }}"
      
    - name: Generate performance summary
      debug:
        msg: |
          Performance Analysis Summary:
          ============================
          Total benchmark files analyzed: {{ performance_data | length }}
          Latest benchmark: {{ performance_data | map(attribute='timestamp') | max }}
          
          Recommendations:
          - Use role-based playbooks for better maintainability
          - Implement async execution for long-running tasks
          - Optimize fork count based on your infrastructure
          - Use fact caching to reduce gathering overhead
          - Implement proper error handling and retries
          
    - name: Create performance dashboard data
      copy:
        content: |
          {
            "benchmark_summary": {
              "total_files": {{ performance_data | length }},
              "latest_run": "{{ performance_data | map(attribute='timestamp') | max }}",
              "analysis_date": "{{ ansible_date_time.iso8601 }}",
              "recommendations": [
                "Use modular role-based playbooks",
                "Implement asynchronous execution",
                "Optimize fork count for your environment",
                "Enable fact caching",
                "Use proper error handling"
              ]
            }
          }
        dest: /tmp/ansible-benchmarks/dashboard-data.json
        
    - name: Display optimization recommendations
      debug:
        msg: |
          Key Performance Optimization Techniques Applied:
          
          1. MODULARITY: Split monolithic playbooks into roles
             - Improved maintainability and reusability
             - Better error isolation and debugging
             - Parallel development capabilities
          
          2. ASYNCHRONOUS EXECUTION: Used async and poll for long tasks
             - Reduced total execution time
             - Better resource utilization
             - Improved user experience
          
          3. TASK DELEGATION: Optimized task placement
             - Reduced network overhead
             - Centralized resource-intensive operations
             - Improved scalability
          
          4. PARALLEL PROCESSING: Optimized fork count and strategy
             - Faster execution across multiple hosts
             - Better resource utilization
             - Scalable to large environments
EOF
Run the performance analysis:
ansible-playbook analyze-performance.yml
Troubleshooting Common Issues
Issue 1: Async Tasks Not Completing
Problem: Async tasks appear to hang or never complete.

Solution:

# Check async job status manually
ansible all -m async_status -a "jid=<job_id>"

# Increase timeout values
async: 600  # Increase from 300 to 600 seconds
poll: 10    # Check every 10 seconds instead of 0
Issue 2: Role Dependencies Not Working
Problem: Roles are not executing in the correct order.

Solution: ```bash # Add role dependencies in meta/main.yml cat > roles/application/meta/main.yml << 'EOF'
dependencies:

role: webserver
role: database EOF

### Issue 3: Performance Degradation with High Fork Count

**Problem**: Increasing forks doesn't improve performance or makes it worse.

**Solution**:
```bash
# Test optimal fork count for your environment
# Start with 5 * number_of_CPU_cores
# Monitor system resources during execution
# Adjust based on network latency and target system capacity
Issue 4: Fact Gathering Taking Too Long
Problem: Fact gathering consumes significant time in large environments.

Solution:

# Enable fact caching in ansible.cfg
[defaults]
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 3600

# Or disable fact gathering when not needed
gather_facts: no
Conclusion
In this comprehensive lab, you have successfully learned and implemented advanced Ansible optimization techniques that are crucial for managing large-scale infrastructure efficiently. Here's what you accomplished:

Key Achievements
Modular Design Mastery: You transformed a monolithic playbook into a well-structured, role-based architecture. This approach provides better maintainability, reusability, and team collaboration capabilities - essential skills for enterprise automation.

Performance Optimization: You implemented asynchronous execution and task delegation strategies that significantly reduce playbook execution time. These techniques are vital when managing hundreds or thousands of systems in production environments.

Scalability Testing: You created comprehensive testing frameworks to measure and compare playbook performance across different optimization strategies. This data-driven approach ensures your automation scales effectively as your infrastructure
