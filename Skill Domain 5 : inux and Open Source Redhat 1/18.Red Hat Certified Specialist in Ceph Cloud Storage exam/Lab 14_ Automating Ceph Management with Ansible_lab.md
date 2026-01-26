Lab 14: Automating Ceph Management with Ansible
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of automating Ceph cluster management using Ansible
Write and execute Ansible playbooks for common Ceph administrative tasks
Automate the addition of OSD (Object Storage Daemon) and MON (Monitor) nodes to existing Ceph clusters
Create and manage Ceph storage pools using Ansible automation
Implement best practices for Ceph infrastructure as code
Troubleshoot common issues in automated Ceph deployments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Ceph storage architecture and components
Familiarity with Linux command line operations
Knowledge of YAML syntax and structure
Basic understanding of Ansible concepts (playbooks, tasks, modules)
Experience with SSH key-based authentication
Understanding of storage concepts (pools, placement groups, replication)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes:

1 Ansible control node (Ubuntu 22.04 LTS)
3 Ceph cluster nodes (Ubuntu 22.04 LTS)
Pre-installed Ansible and required dependencies
SSH keys configured for passwordless access
Basic Ceph cluster already deployed
Task 1: Setting Up Ansible for Ceph Management
Subtask 1.1: Verify Lab Environment and Ansible Installation
First, let's verify that our lab environment is properly configured and Ansible is ready for use.

Connect to the Ansible control node:

# The lab environment will provide connection details
# Typically: ssh student@ansible-control-node
Verify Ansible installation:

ansible --version
Check Python and pip installation:

python3 --version
pip3 --version
Install required Python packages for Ceph management:

sudo pip3 install ceph-deploy
sudo pip3 install python-cephclient
Subtask 1.2: Configure Ansible Inventory
Create an inventory file that defines your Ceph cluster nodes.

Create the inventory directory:

mkdir -p ~/ceph-ansible
cd ~/ceph-ansible
Create the inventory file:

cat > inventory.ini << 'EOF'
[ceph-mon]
ceph-node1 ansible_host=10.0.1.10 ansible_user=student
ceph-node2 ansible_host=10.0.1.11 ansible_user=student
ceph-node3 ansible_host=10.0.1.12 ansible_user=student

[ceph-osd]
ceph-node1 ansible_host=10.0.1.10 ansible_user=student
ceph-node2 ansible_host=10.0.1.11 ansible_user=student
ceph-node3 ansible_host=10.0.1.12 ansible_user=student

[ceph-mgr]
ceph-node1 ansible_host=10.0.1.10 ansible_user=student

[ceph-cluster:children]
ceph-mon
ceph-osd
ceph-mgr

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
Test connectivity to all nodes:

ansible all -i inventory.ini -m ping
Subtask 1.3: Create Ansible Configuration
Set up Ansible configuration for optimal Ceph management.

Create ansible.cfg file:

cat > ansible.cfg << 'EOF'
[defaults]
inventory = inventory.ini
remote_user = student
private_key_file = ~/.ssh/id_rsa
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = memory
stdout_callback = yaml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
EOF
Verify configuration:

ansible-config dump --only-changed
Task 2: Writing Ansible Playbooks for Ceph Cluster Management
Subtask 2.1: Create Basic Ceph Status Playbook
Start with a simple playbook to check cluster status across all nodes.

Create the playbooks directory:

mkdir -p ~/ceph-ansible/playbooks
cd ~/ceph-ansible/playbooks
Create cluster status playbook: ```bash cat > ceph-status.yml << 'EOF'
name: Check Ceph Cluster Status hosts: ceph-mon[0] become: yes gather_facts: yes

tasks:

name: Check if Ceph is installed command: which ceph register: ceph_installed failed_when: false changed_when: false

name: Display Ceph installation status debug: msg: "Ceph is {{ 'installed' if ceph_installed.rc == 0 else 'not installed' }}"

name: Get cluster status command: ceph status register: cluster_status when: ceph_installed.rc == 0 changed_when: false

name: Display cluster status debug: var: cluster_status.stdout_lines when: ceph_installed.rc == 0

name: Get cluster health command: ceph health register: cluster_health when: ceph_installed.rc == 0 changed_when: false

name: Display cluster health debug: var: cluster_health.stdout when: ceph_installed.rc == 0

name: List OSDs command: ceph osd ls register: osd_list when: ceph_installed.rc == 0 changed_when: false

name: Display OSD list debug: var: osd_list.stdout_lines when: ceph_installed.rc == 0

EOF


Execute the status playbook:

cd ~/ceph-ansible
ansible-playbook playbooks/ceph-status.yml
Subtask 2.2: Create Ceph Configuration Management Playbook
Create a playbook to manage Ceph configuration files across the cluster.

Create configuration management playbook: ```bash cat > playbooks/ceph-config.yml << 'EOF'
name: Manage Ceph Configuration hosts: ceph-cluster become: yes gather_facts: yes

vars: ceph_conf_path: /etc/ceph/ceph.conf ceph_keyring_path: /etc/ceph/ceph.client.admin.keyring

tasks:

name: Ensure Ceph configuration directory exists file: path: /etc/ceph state: directory owner: ceph group: ceph mode: '0755'

name: Check if ceph.conf exists stat: path: "{{ ceph_conf_path }}" register: ceph_conf_stat

name: Display configuration file status debug: msg: "Ceph configuration {{ 'exists' if ceph_conf_stat.stat.exists else 'does not exist' }}"

name: Backup existing configuration copy: src: "{{ ceph_conf_path }}" dest: "{{ ceph_conf_path }}.backup.{{ ansible_date_time.epoch }}" remote_src: yes when: ceph_conf_stat.stat.exists

name: Get current configuration content slurp: src: "{{ ceph_conf_path }}" register: current_config when: ceph_conf_stat.stat.exists

name: Display current configuration debug: msg: "{{ current_config.content | b64decode }}" when: ceph_conf_stat.stat.exists

EOF


Execute the configuration playbook:

ansible-playbook playbooks/ceph-config.yml
Task 3: Automating OSD and MON Node Addition
Subtask 3.1: Create OSD Addition Playbook
Develop a comprehensive playbook to add new OSD nodes to the cluster.

Create OSD addition playbook: ```bash cat > playbooks/add-osd.yml << 'EOF'
name: Add New OSD to Ceph Cluster hosts: ceph-osd become: yes gather_facts: yes serial: 1

vars: osd_device: /dev/sdb # Adjust based on your environment ceph_user: ceph

tasks:

name: Check if device exists stat: path: "{{ osd_device }}" register: device_stat

name: Fail if device doesn't exist fail: msg: "Device {{ osd_device }} does not exist on {{ inventory_hostname }}" when: not device_stat.stat.exists

name: Check if device is already in use command: lsblk {{ osd_device }} register: device_usage changed_when: false failed_when: false

name: Display device information debug: var: device_usage.stdout_lines

name: Check current OSD status command: ceph osd ls register: current_osds delegate_to: "{{ groups['ceph-mon'][0] }}" run_once: true changed_when: false

name: Display current OSDs debug: var: current_osds.stdout_lines run_once: true

name: Prepare OSD device (wipe existing data) command: ceph-volume lvm zap {{ osd_device }} --destroy register: zap_result failed_when: false when: device_stat.stat.exists

name: Create new OSD command: ceph-volume lvm create --data {{ osd_device }} register: osd_create_result when: device_stat.stat.exists

name: Display OSD creation result debug: var: osd_create_result.stdout_lines when: osd_create_result is defined

name: Wait for OSD to be up command: ceph osd stat register: osd_stat until: osd_stat.rc == 0 retries: 10 delay: 5 delegate_to: "{{ groups['ceph-mon'][0] }}"

name: Get updated OSD list command: ceph osd ls register: updated_osds delegate_to: "{{ groups['ceph-mon'][0] }}" changed_when: false

name: Display updated OSD list debug: var: updated_osds.stdout_lines delegate_to: "{{ groups['ceph-mon'][0] }}" run_once: true

name: Check cluster health after OSD addition command: ceph health register: health_check delegate_to: "{{ groups['ceph-mon'][0] }}" changed_when: false

name: Display cluster health debug: var: health_check.stdout delegate_to: "{{ groups['ceph-mon'][0] }}" run_once: true

EOF ```

Subtask 3.2: Create MON Addition Playbook
Create a playbook to add new Monitor nodes to the cluster.

Create MON addition playbook: ```bash cat > playbooks/add-mon.yml << 'EOF'
name: Add New Monitor to Ceph Cluster hosts: localhost become: yes gather_facts: yes

vars: new_mon_host: "{{ target_host | default('ceph-node3') }}" new_mon_ip: "{{ target_ip | default('10.0.1.12') }}"

tasks:

name: Get current monitor status command: ceph mon stat register: current_mons delegate_to: "{{ groups['ceph-mon'][0] }}" changed_when: false

name: Display current monitors debug: var: current_mons.stdout

name: Get monitor map command: ceph mon dump register: mon_dump delegate_to: "{{ groups['ceph-mon'][0] }}" changed_when: false

name: Display monitor map debug: var: mon_dump.stdout_lines

name: Check if new monitor already exists command: ceph mon stat register: existing_mon_check delegate_to: "{{ groups['ceph-mon'][0] }}" changed_when: false

name: Add new monitor to cluster command: ceph mon add {{ new_mon_host }} {{ new_mon_ip }}:6789 register: mon_add_result delegate_to: "{{ groups['ceph-mon'][0] }}" when: new_mon_host not in existing_mon_check.stdout

name: Display monitor addition result debug: var: mon_add_result.stdout when: mon_add_result is defined and mon_add_result.stdout is defined

name: Wait for monitor to join command: ceph mon stat register: mon_join_check until: new_mon_host in mon_join_check.stdout retries: 10 delay: 5 delegate_to: "{{ groups['ceph-mon'][0] }}" when: mon_add_result is defined

name: Get updated monitor status command: ceph mon stat register: updated_mons delegate_to: "{{ groups['ceph-mon'][0] }}" changed_when: false

name: Display updated monitor status debug: var: updated_mons.stdout

name: Check quorum status command: ceph quorum_status register: quorum_status delegate_to: "{{ groups['ceph-mon'][0] }}" changed_when: false

name: Display quorum status debug: var: quorum_status.stdout

EOF


Execute the MON addition playbook:

ansible-playbook playbooks/add-mon.yml -e "target_host=ceph-node3 target_ip=10.0.1.12"
Subtask 3.3: Create Combined Node Addition Playbook
Create a comprehensive playbook that can add both MON and OSD services to new nodes.

Create combined addition playbook: ```bash cat > playbooks/add-node.yml << 'EOF'
name: Add New Node to Ceph Cluster hosts: localhost become: yes gather_facts: yes

vars: target_node: "{{ node_hostname | default('ceph-node4') }}" target_ip: "{{ node_ip | default('10.0.1.13') }}" add_monitor: "{{ include_mon | default(true) }}" add_osd: "{{ include_osd | default(true) }}" osd_device: "{{ osd_disk | default('/dev/sdb') }}"

tasks:

name: Display node addition parameters debug: msg: - "Target Node: {{ target_node }}" - "Target IP: {{ target_ip }}" - "Add Monitor: {{ add_monitor }}" - "Add OSD: {{ add_osd }}" - "OSD Device: {{ osd_device }}"

name: Check cluster status before addition command: ceph status register: pre_status delegate_to: "{{ groups['ceph-mon'][0] }}" changed_when: false

name: Display pre-addition cluster status debug: var: pre_status.stdout_lines

name: Add monitor service block:

name: Add new monitor command: ceph mon add {{ target_node }} {{ target_ip }}:6789 register: mon_add delegate_to: "{{ groups['ceph-mon'][0] }}"

name: Wait for monitor to be active command: ceph mon stat register: mon_check until: target_node in mon_check.stdout retries: 15 delay: 10 delegate_to: "{{ groups['ceph-mon'][0] }}"

name: Display monitor addition result debug: msg: "Monitor {{ target_node }} successfully added" when: add_monitor | bool

name: Add OSD service block:

name: Prepare OSD device on target node command: ceph-volume lvm zap {{ osd_device }} --destroy delegate_to: "{{ target_node }}" failed_when: false

name: Create OSD on target node command: ceph-volume lvm create --data {{ osd_device }} register: osd_create delegate_to: "{{ target_node }}"

name: Wait for OSD to be up command: ceph osd stat register: osd_check until: osd_check.rc == 0 retries: 15 delay: 10 delegate_to: "{{ groups['ceph-mon'][0] }}"

name: Display OSD addition result debug: msg: "OSD successfully created on {{ target_node }}" when: add_osd | bool

name: Final cluster status check command: ceph status register: post_status delegate_to: "{{ groups['ceph-mon'][0] }}" changed_when: false

name: Display post-addition cluster status debug: var: post_status.stdout_lines

name: Check cluster health command: ceph health detail register: health_detail delegate_to: "{{ groups['ceph-mon'][0] }}" changed_when: false

name: Display cluster health details debug: var: health_detail.stdout_lines

EOF ```

Task 4: Using Ansible for Creating and Managing Pools
Subtask 4.1: Create Pool Management Playbook
Develop a comprehensive playbook for creating and managing Ceph storage pools.

Create pool management playbook: ```bash cat > playbooks/manage-pools.yml << 'EOF'
name: Manage Ceph Storage Pools hosts: ceph-mon[0] become: yes gather_facts: yes

vars: pools_to_create: - name: rbd-pool pg_num: 64 pgp_num: 64 type: replicated size: 3 min_size: 2 - name: cephfs-data pg_num: 128 pgp_num: 128 type: replicated size: 3 min_size: 2 - name: cephfs-metadata pg_num: 32 pgp_num: 32 type: replicated size: 3 min_size: 2 - name: rgw-buckets pg_num: 64 pgp_num: 64 type: replicated size: 3 min_size: 2
tasks:

name: Get current pool list command: ceph osd lspools register: current_pools changed_when: false

name: Display current pools debug: var: current_pools.stdout_lines

name: Create storage pools command: > ceph osd pool create {{ item.name }} {{ item.pg_num }} {{ item.pgp_num }} register: pool_creation loop: "{{ pools_to_create }}" when: item.name not in current_pools.stdout failed_when: false

name: Display pool creation results debug: msg: "Pool {{ item.item.name }}: {{ 'Created' if item.rc == 0 else 'Failed to create' }}" loop: "{{ pool_creation.results }}" when: item is not skipped

name: Set pool replication size command: ceph osd pool set {{ item.name }} size {{ item.size }} loop: "{{ pools_to_create }}" register: size_setting

name: Set pool minimum size command: ceph osd pool set {{ item.name }} min_size {{ item.min_size }} loop: "{{ pools_to_create }}" register: min_size_setting

name: Enable RBD application on RBD pool command: ceph osd pool application enable rbd-pool rbd when: "'rbd-pool' in pools_to_create | map(attribute='name') | list" failed_when: false

name: Enable CephFS application on CephFS pools command: ceph osd pool application enable {{ item }} cephfs loop:

cephfs-data
cephfs-metadata when: item in pools_to_create | map(attribute='name') | list failed_when: false
name: Enable RGW application on RGW pool command: ceph osd pool application enable rgw-buckets rgw when: "'rgw-buckets' in pools_to_create | map(attribute='name') | list" failed_when: false

name: Get updated pool list with details command: ceph osd pool ls detail register: detailed_pools changed_when: false

name: Display detailed pool information debug: var: detailed_pools.stdout_lines

name: Get pool statistics command: ceph df register: pool_stats changed_when: false

name: Display pool statistics debug: var: pool_stats.stdout_lines

EOF


Execute the pool management playbook:

ansible-playbook playbooks/manage-pools.yml
Subtask 4.2: Create Pool Monitoring Playbook
Create a playbook to monitor pool health and performance.

Create pool monitoring playbook: ```bash cat > playbooks/monitor-pools.yml << 'EOF'
name: Monitor Ceph Pool Health and Performance hosts: ceph-mon[0] become: yes gather_facts: yes

tasks:

name: Get pool usage statistics command: ceph df detail register: pool_usage changed_when: false

name: Display pool usage debug: var: pool_usage.stdout_lines

name: Get pool I/O statistics command: ceph osd pool stats register: pool_io_stats changed_when: false

name: Display pool I/O statistics debug: var: pool_io_stats.stdout_lines

name: Check pool health command: ceph health detail register: pool_health changed_when: false

name: Display pool health details debug: var: pool_health.stdout_lines

name: Get placement group statistics command: ceph pg stat register: pg_stats changed_when: false

name: Display placement group statistics debug: var: pg_stats.stdout

name: List pools with their properties command: ceph osd pool ls detail register: pool_properties changed_when: false

name: Display pool properties debug: var: pool_properties.stdout_lines

name: Check for any stuck placement groups command: ceph pg dump_stuck register: stuck_pgs changed_when: false failed_when: false

name: Display stuck placement groups (if any) debug: var: stuck_pgs.stdout_lines when: stuck_pgs.rc == 0 and stuck_pgs.stdout != ""

name: Generate pool health report debug: msg: - "=== POOL HEALTH SUMMARY ===" - "Total pools: {{ (pool_usage.stdout_lines | select('match', '.POOLS:.') | list | first).split()[1] if pool_usage.stdout_lines | select('match', '.POOLS:.') | list else 'Unknown' }}" - "Cluster health: {{ pool_health.stdout_lines[0] if pool_health.stdout_lines else 'Unknown' }}" - "PG status: {{ pg_stats.stdout if pg_stats.stdout else 'Unknown' }}"

EOF


Execute the pool monitoring playbook:

ansible-playbook playbooks/monitor-pools.yml
Subtask 4.3: Create Pool Cleanup Playbook
Create a playbook to safely remove pools when needed.

Create pool cleanup playbook: ```bash cat > playbooks/cleanup-pools.yml << 'EOF'
name: Safely Remove Ceph Storage Pools hosts: ceph-mon[0] become: yes gather_facts: yes

vars: pools_to_remove: [] # Define pools to remove as extra vars confirm_deletion: false # Safety flag

tasks:

name: Safety check - confirm deletion intent fail: msg: "Pool deletion not confirmed. Set confirm_deletion=true to proceed." when: not confirm_deletion | bool

name: Display pools marked for deletion debug: msg: "Pools to be removed: {{ pools_to_remove }}" when: pools_to_remove | length > 0

name: Fail if no pools specified fail: msg: "No pools specified for deletion. Use -e pools_to_remove='["pool1","pool2"]'" when: pools_to_remove | length == 0

name: Get current pool list command: ceph osd lspools register: current_pools changed_when: false

name: Display current pools debug: var: current_pools.stdout_lines

name: Check if pools exist before deletion debug: msg: "Pool {{ item }} {{ 'exists' if item in current_pools.stdout else 'does not exist' }}" loop: "{{ pools_to_remove }}"

name: Get pool usage before deletion command: ceph df detail register: pre_deletion_usage changed_when: false

name: Display usage before deletion debug: var: pre_deletion_usage.stdout_lines

name: Remove specified pools command: ceph osd pool delete {{ item }} {{ item }} --yes-i-really-really-mean-it register: pool_deletion loop: "{{ pools_to_remove }}" when: item in current_pools.stdout failed_when: false

name: Display deletion results debug: msg: "Pool {{ item.item }}: {{ 'Deleted' if item.rc == 0 else 'Failed to delete' }}" loop: "{{ pool_deletion.results }}" when: item is not skipped

name: Get updated pool list command: ceph osd lspools register: updated_pools changed_when: false

name: Display updated pool list debug: var: updated_pools.stdout_lines

name: Get updated usage statistics command: ceph df detail register: post_deletion_usage changed_when: false

name: Display updated usage debug: var: post_deletion_usage.stdout_lines

name: Check cluster health after deletion command: ceph health register: post_deletion_health changed_when: false

name: Display cluster health debug: var: post_deletion_health.stdout

EOF ```

Task 5: Advanced Ceph Automation Scenarios
Subtask 5.1: Create Comprehensive Cluster Maintenance Playbook
Develop a playbook for routine cluster maintenance tasks.

Create maintenance playbook: ```bash cat > playbooks/cluster-maintenance.yml << 'EOF'
name: Ceph Cluster Maintenance Tasks hosts: ceph-cluster become: yes gather_facts: yes serial: 1

vars: maintenance_tasks: - check_disk_usage - update_packages - restart_services - cleanup_logs tasks:

name: Display maintenance tasks debug: msg: "Performing maintenance on {{ inventory_hostname }}"

name: Check disk usage command: df -h register: disk_usage changed_when: false when: "'check_disk_usage' in maintenance_tasks"

name: Display disk usage debug: var: disk_usage.stdout_lines when: "'check_disk_usage' in maintenance_tasks"

name: Check for available package updates command: apt list --upgradable register: available_updates changed_when: false when: "'update_packages' in maintenance_tasks"

name: Display available updates debug: var: available_updates.stdout_lines when: "'update_packages' in maintenance_tasks and available_updates.stdout_lines | length > 1"

name: Update package cache apt: update_cache: yes when: "'update_packages' in maintenance_tasks"

name: Upgrade packages (excluding Ceph packages) apt: upgrade: safe autoremove: yes when: "'update_packages' in maintenance_tasks"

name: Check Ceph service status systemd: name: "{{ item }}" state: started enabled: yes loop:

ceph-mon@{{ inventory_hostname }}
ceph-mgr@{{ inventory_hostname }}
ceph-osd@* when: "'restart_services' in maintenance_tasks" failed_when: false
name: Clean up old log files find: paths: /var/log/ceph age: 30d file_type: file register: old_logs when: "'cleanup_logs' in maintenance_tasks"

name: Remove old log files file: path: "{{ item.path }}" state: absent loop: "{{ old_logs.files }}" when: "'cleanup_logs' in maintenance_tasks and old_logs.files is defined"

name: Check cluster health from monitor node command: ceph health detail register: health_check delegate_to: "{{ groups['ceph-mon'][0] }}" run_once: true changed_when: false

name: Display cluster health debug: var: health_check.stdout_lines run_once: true

EOF ```

Subtask 5.2: Create Backup and Recovery Playbook
Create a playbook for backing up critical Ceph configuration and data.

Create backup playbook: ```bash cat > playbooks/backup-recovery.yml << 'EOF'
name: Ceph Backup and Recovery Operations hosts: ceph-mon[0] become: yes gather_facts: yes

vars: backup_dir: /opt/ceph-backups backup_timestamp: "{{ ansible_date_time.epoch }}"

tasks:

name: Create backup directory file
