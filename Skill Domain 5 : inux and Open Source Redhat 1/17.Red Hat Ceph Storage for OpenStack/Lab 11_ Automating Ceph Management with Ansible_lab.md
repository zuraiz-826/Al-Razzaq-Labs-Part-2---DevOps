Lab 11: Automating Ceph Management with Ansible
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of Ansible automation for Ceph storage clusters
Write and execute Ansible playbooks for adding and removing OSDs (Object Storage Daemons)
Automate the deployment of new Ceph nodes using Ansible
Create automated workflows for pool creation and CRUSH map management
Implement best practices for Ceph cluster automation and configuration management
Troubleshoot common issues in automated Ceph deployments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph storage architecture and components
Familiarity with Linux command line operations
Knowledge of YAML syntax and structure
Understanding of SSH key-based authentication
Basic networking concepts (IP addressing, DNS)
Previous experience with Ceph cluster operations (manual deployment preferred)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or configure complex networking.

Your lab environment includes:

1 Ansible Control Node (Ubuntu 22.04 LTS)
3 Ceph Nodes (Ubuntu 22.04 LTS)
Pre-installed Ansible and required dependencies
SSH key authentication already configured
Basic Ceph cluster foundation ready for automation
Task 1: Setting Up Ansible for Ceph Management
Subtask 1.1: Verify Ansible Installation and Configuration
First, let's verify that Ansible is properly installed and configured on your control node.

Connect to the Ansible Control Node
# Check Ansible version
ansible --version

# Verify Python version compatibility
python3 --version
Configure Ansible Inventory
Create the inventory file that defines your Ceph cluster nodes:

# Create the inventory directory
sudo mkdir -p /etc/ansible/inventories/ceph

# Create the main inventory file
sudo tee /etc/ansible/inventories/ceph/hosts.yml << 'EOF'
all:
  children:
    ceph_cluster:
      children:
        mons:
          hosts:
            ceph-node1:
              ansible_host: 10.0.1.10
              monitor_address: 10.0.1.10
        osds:
          hosts:
            ceph-node1:
              ansible_host: 10.0.1.10
            ceph-node2:
              ansible_host: 10.0.1.11
            ceph-node3:
              ansible_host: 10.0.1.12
        mgrs:
          hosts:
            ceph-node1:
              ansible_host: 10.0.1.10
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF
Test Connectivity to All Nodes
# Test connection to all Ceph nodes
ansible -i /etc/ansible/inventories/ceph/hosts.yml all -m ping

# Verify sudo access
ansible -i /etc/ansible/inventories/ceph/hosts.yml all -m shell -a "sudo whoami" -b
Subtask 1.2: Install Ceph-Ansible Collection
Install the official Ceph-Ansible collection for advanced automation capabilities:

# Install the Ceph-Ansible collection
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix

# Create a requirements file for Ceph-specific roles
tee requirements.yml << 'EOF'
collections:
  - name: community.general
    version: ">=5.0.0"
  - name: ansible.posix
    version: ">=1.0.0"

roles:
  - name: geerlingguy.docker
    version: ">=4.0.0"
EOF

# Install the requirements
ansible-galaxy install -r requirements.yml
Subtask 1.3: Create Ansible Configuration
Set up a proper Ansible configuration for Ceph management:

# Create ansible.cfg in your working directory
tee ansible.cfg << 'EOF'
[defaults]
inventory = /etc/ansible/inventories/ceph/hosts.yml
remote_user = ubuntu
private_key_file = ~/.ssh/id_rsa
host_key_checking = False
gathering = smart
fact_caching = memory
stdout_callback = yaml
callback_whitelist = timer, profile_tasks

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
pipelining = True
EOF
Task 2: Writing Ansible Playbooks for OSD Management
Subtask 2.1: Create Playbook for Adding OSDs
Create a comprehensive playbook to automate OSD addition to your Ceph cluster:

# Create the playbooks directory
mkdir -p ~/ceph-ansible-playbooks/roles/osd-management/{tasks,templates,vars,handlers}

# Create the main OSD addition playbook
tee ~/ceph-ansible-playbooks/add-osd.yml << 'EOF'
---
- name: Add New OSDs to Ceph Cluster
  hosts: osds
  become: yes
  gather_facts: yes
  vars:
    ceph_release: quincy
    ceph_repository: community
    ceph_stable_release: quincy
    
  tasks:
    - name: Install required packages
      apt:
        name:
          - ceph-osd
          - ceph-common
          - gdisk
          - parted
        state: present
        update_cache: yes

    - name: Gather disk information
      setup:
        gather_subset:
          - hardware

    - name: Identify available disks for OSDs
      shell: |
        lsblk -dpno NAME,SIZE,TYPE | grep disk | grep -v $(df / | tail -1 | cut -d' ' -f1 | sed 's/[0-9]*$//')
      register: available_disks
      changed_when: false

    - name: Display available disks
      debug:
        msg: "Available disks: {{ available_disks.stdout_lines }}"

    - name: Create OSD data directories
      file:
        path: "/var/lib/ceph/osd/ceph-{{ item }}"
        state: directory
        owner: ceph
        group: ceph
        mode: '0755'
      loop: "{{ range(0, osd_count | default(1)) | list }}"
      when: create_directories | default(true)

    - name: Prepare disk for OSD (if disk specified)
      shell: |
        ceph-volume lvm prepare --data {{ osd_disk }}
      register: osd_prepare_result
      when: 
        - osd_disk is defined
        - osd_disk != ""
      failed_when: 
        - osd_prepare_result.rc != 0
        - "'already prepared' not in osd_prepare_result.stderr"

    - name: Activate prepared OSDs
      shell: |
        ceph-volume lvm activate --all
      register: osd_activate_result
      when: osd_prepare_result is succeeded

    - name: Wait for OSD to be up and in
      shell: |
        ceph osd tree | grep "{{ ansible_hostname }}"
      register: osd_status
      until: "'up' in osd_status.stdout"
      retries: 30
      delay: 10
      when: osd_activate_result is succeeded

    - name: Display OSD status
      debug:
        msg: "OSD Status: {{ osd_status.stdout_lines }}"
      when: osd_status is defined
EOF
Subtask 2.2: Create Playbook for Removing OSDs
Create a safe OSD removal playbook with proper data migration:

# Create OSD removal playbook
tee ~/ceph-ansible-playbooks/remove-osd.yml << 'EOF'
---
- name: Safely Remove OSDs from Ceph Cluster
  hosts: osds
  become: yes
  gather_facts: yes
  vars:
    osd_removal_timeout: 1800  # 30 minutes
    
  tasks:
    - name: Validate OSD ID is provided
      fail:
        msg: "osd_id variable must be defined"
      when: osd_id is not defined

    - name: Check if OSD exists
      shell: |
        ceph osd ls | grep "^{{ osd_id }}$"
      register: osd_exists
      failed_when: false
      changed_when: false

    - name: Fail if OSD doesn't exist
      fail:
        msg: "OSD {{ osd_id }} does not exist in the cluster"
      when: osd_exists.rc != 0

    - name: Get OSD status before removal
      shell: |
        ceph osd tree | grep "osd.{{ osd_id }}"
      register: osd_initial_status
      changed_when: false

    - name: Display initial OSD status
      debug:
        msg: "Initial OSD Status: {{ osd_initial_status.stdout }}"

    - name: Mark OSD as out (stop allocating data)
      shell: |
        ceph osd out {{ osd_id }}
      register: osd_out_result

    - name: Wait for data migration to complete
      shell: |
        ceph pg dump pgs | grep "{{ osd_id }}" | wc -l
      register: pg_count
      until: pg_count.stdout | int == 0
      retries: "{{ (osd_removal_timeout / 30) | int }}"
      delay: 30
      when: osd_out_result is succeeded

    - name: Stop OSD daemon
      systemd:
        name: "ceph-osd@{{ osd_id }}"
        state: stopped
        enabled: no
      when: pg_count.stdout | int == 0

    - name: Mark OSD as down
      shell: |
        ceph osd down {{ osd_id }}
      when: pg_count.stdout | int == 0

    - name: Remove OSD from CRUSH map
      shell: |
        ceph osd crush remove osd.{{ osd_id }}
      when: pg_count.stdout | int == 0

    - name: Delete OSD authentication key
      shell: |
        ceph auth del osd.{{ osd_id }}
      when: pg_count.stdout | int == 0

    - name: Remove OSD from cluster
      shell: |
        ceph osd rm {{ osd_id }}
      when: pg_count.stdout | int == 0

    - name: Clean up OSD data directory
      file:
        path: "/var/lib/ceph/osd/ceph-{{ osd_id }}"
        state: absent
      when: pg_count.stdout | int == 0

    - name: Verify OSD removal
      shell: |
        ceph osd tree | grep "osd.{{ osd_id }}" || echo "OSD successfully removed"
      register: removal_verification
      changed_when: false

    - name: Display removal status
      debug:
        msg: "{{ removal_verification.stdout }}"
EOF
Subtask 2.3: Test OSD Management Playbooks
Execute the playbooks to test OSD management automation:

# Test the add-osd playbook (dry run first)
ansible-playbook ~/ceph-ansible-playbooks/add-osd.yml --check --diff

# Execute OSD addition (specify target disk)
ansible-playbook ~/ceph-ansible-playbooks/add-osd.yml -e "osd_disk=/dev/sdb"

# Verify cluster status after addition
ansible osds -m shell -a "ceph -s" --limit ceph-node1

# Test OSD removal (dry run)
ansible-playbook ~/ceph-ansible-playbooks/remove-osd.yml --check -e "osd_id=2"

# Note: Only execute removal in a test environment
# ansible-playbook ~/ceph-ansible-playbooks/remove-osd.yml -e "osd_id=2"
Task 3: Automating Deployment of New Ceph Nodes
Subtask 3.1: Create Node Preparation Playbook
Develop a comprehensive playbook for preparing new nodes to join the Ceph cluster:

# Create node deployment playbook
tee ~/ceph-ansible-playbooks/deploy-new-node.yml << 'EOF'
---
- name: Deploy New Ceph Node
  hosts: "{{ target_host | default('new_nodes') }}"
  become: yes
  gather_facts: yes
  vars:
    ceph_release: quincy
    ceph_stable_release: quincy
    ntp_service: chrony
    
  tasks:
    - name: Update system packages
      apt:
        update_cache: yes
        upgrade: dist
        autoremove: yes
        autoclean: yes

    - name: Install essential packages
      apt:
        name:
          - curl
          - wget
          - gnupg2
          - software-properties-common
          - apt-transport-https
          - ca-certificates
          - chrony
          - python3-pip
          - lvm2
        state: present

    - name: Configure NTP synchronization
      template:
        src: chrony.conf.j2
        dest: /etc/chrony/chrony.conf
        backup: yes
      notify: restart chrony

    - name: Start and enable chrony service
      systemd:
        name: chrony
        state: started
        enabled: yes

    - name: Add Ceph repository key
      apt_key:
        url: https://download.ceph.com/keys/release.asc
        state: present

    - name: Add Ceph repository
      apt_repository:
        repo: "deb https://download.ceph.com/debian-{{ ceph_stable_release }}/ {{ ansible_distribution_release }} main"
        state: present
        update_cache: yes

    - name: Install Ceph packages
      apt:
        name:
          - ceph-common
          - ceph-mon
          - ceph-mgr
          - ceph-osd
          - ceph-mds
          - radosgw
        state: present

    - name: Create ceph user and group
      group:
        name: ceph
        state: present

    - name: Create ceph user
      user:
        name: ceph
        group: ceph
        system: yes
        shell: /bin/bash
        home: /var/lib/ceph
        create_home: yes

    - name: Create Ceph directories
      file:
        path: "{{ item }}"
        state: directory
        owner: ceph
        group: ceph
        mode: '0755'
      loop:
        - /etc/ceph
        - /var/lib/ceph
        - /var/lib/ceph/mon
        - /var/lib/ceph/osd
        - /var/lib/ceph/mgr
        - /var/lib/ceph/mds
        - /var/log/ceph

    - name: Configure kernel parameters for Ceph
      sysctl:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
        state: present
        reload: yes
      loop:
        - { name: 'kernel.pid_max', value: '4194304' }
        - { name: 'fs.file-max', value: '26234859' }
        - { name: 'vm.zone_reclaim_mode', value: '0' }

    - name: Configure ulimits for Ceph
      pam_limits:
        domain: ceph
        limit_type: "{{ item.type }}"
        limit_item: "{{ item.item }}"
        value: "{{ item.value }}"
      loop:
        - { type: 'soft', item: 'nofile', value: '1048576' }
        - { type: 'hard', item: 'nofile', value: '1048576' }
        - { type: 'soft', item: 'nproc', value: '1048576' }
        - { type: 'hard', item: 'nproc', value: '1048576' }

  handlers:
    - name: restart chrony
      systemd:
        name: chrony
        state: restarted
EOF
Subtask 3.2: Create Chrony Configuration Template
Create the NTP configuration template for time synchronization:

# Create templates directory
mkdir -p ~/ceph-ansible-playbooks/templates

# Create chrony configuration template
tee ~/ceph-ansible-playbooks/templates/chrony.conf.j2 << 'EOF'
# Use public NTP servers from the pool.ntp.org project
pool 2.ubuntu.pool.ntp.org iburst maxsources 4
pool 1.ubuntu.pool.ntp.org iburst maxsources 1
pool 0.ubuntu.pool.ntp.org iburst maxsources 1
pool ntp.ubuntu.com iburst maxsources 4

# This directive specify the location of the file containing ID/key pairs for
# NTP authentication.
keyfile /etc/chrony/chrony.keys

# This directive specify the file into which chronyd will store the rate
# information.
driftfile /var/lib/chrony/chrony.drift

# Uncomment the following line to turn logging on.
#log tracking measurements statistics

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 100.0

# This directive enables kernel synchronisation (every 11 minutes) of the
# real-time clock. Note that it can't be used along with the 'rtcfile' directive.
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 1 3
EOF
Subtask 3.3: Create Monitor Deployment Playbook
Create a playbook specifically for deploying monitor daemons on new nodes:

# Create monitor deployment playbook
tee ~/ceph-ansible-playbooks/deploy-monitor.yml << 'EOF'
---
- name: Deploy Ceph Monitor on New Node
  hosts: "{{ target_host }}"
  become: yes
  gather_facts: yes
  vars:
    monitor_keyring_path: /tmp/ceph.mon.keyring
    
  tasks:
    - name: Check if node is already prepared
      stat:
        path: /etc/ceph/ceph.conf
      register: ceph_conf_exists

    - name: Fail if node is not prepared
      fail:
        msg: "Node must be prepared first. Run deploy-new-node.yml playbook first."
      when: not ceph_conf_exists.stat.exists

    - name: Get monitor keyring from existing monitor
      shell: |
        ceph auth get mon. -o {{ monitor_keyring_path }}
      delegate_to: "{{ groups['mons'][0] }}"
      run_once: true

    - name: Copy monitor keyring to new node
      copy:
        src: "{{ monitor_keyring_path }}"
        dest: "{{ monitor_keyring_path }}"
        owner: ceph
        group: ceph
        mode: '0600'

    - name: Get monitor map from existing cluster
      shell: |
        ceph mon getmap -o /tmp/monmap
      delegate_to: "{{ groups['mons'][0] }}"
      run_once: true

    - name: Copy monitor map to new node
      copy:
        src: /tmp/monmap
        dest: /tmp/monmap
        owner: ceph
        group: ceph
        mode: '0644'

    - name: Create monitor data directory
      file:
        path: "/var/lib/ceph/mon/ceph-{{ ansible_hostname }}"
        state: directory
        owner: ceph
        group: ceph
        mode: '0755'

    - name: Initialize monitor data directory
      shell: |
        ceph-mon --mkfs -i {{ ansible_hostname }} --monmap /tmp/monmap --keyring {{ monitor_keyring_path }}
      become_user: ceph
      args:
        creates: "/var/lib/ceph/mon/ceph-{{ ansible_hostname }}/store.db"

    - name: Create monitor systemd service file
      template:
        src: ceph-mon.service.j2
        dest: "/etc/systemd/system/ceph-mon@{{ ansible_hostname }}.service"
        mode: '0644'
      notify: reload systemd

    - name: Start and enable monitor service
      systemd:
        name: "ceph-mon@{{ ansible_hostname }}"
        state: started
        enabled: yes
        daemon_reload: yes

    - name: Add new monitor to cluster
      shell: |
        ceph mon add {{ ansible_hostname }} {{ ansible_default_ipv4.address }}:6789
      delegate_to: "{{ groups['mons'][0] }}"
      when: ansible_hostname not in groups['mons']

    - name: Verify monitor is running
      shell: |
        ceph mon stat
      register: mon_stat
      until: ansible_hostname in mon_stat.stdout
      retries: 10
      delay: 5

    - name: Clean up temporary files
      file:
        path: "{{ item }}"
        state: absent
      loop:
        - "{{ monitor_keyring_path }}"
        - /tmp/monmap

  handlers:
    - name: reload systemd
      systemd:
        daemon_reload: yes
EOF
Subtask 3.4: Test New Node Deployment
Execute the node deployment playbooks:

# First, add a new node to your inventory for testing
sudo tee -a /etc/ansible/inventories/ceph/hosts.yml << 'EOF'
        new_nodes:
          hosts:
            ceph-node4:
              ansible_host: 10.0.1.13
EOF

# Test node preparation (dry run)
ansible-playbook ~/ceph-ansible-playbooks/deploy-new-node.yml --check --limit new_nodes

# Execute node preparation
ansible-playbook ~/ceph-ansible-playbooks/deploy-new-node.yml --limit new_nodes

# Copy ceph.conf from existing node
ansible mons[0] -m fetch -a "src=/etc/ceph/ceph.conf dest=/tmp/ceph.conf flat=yes"
ansible new_nodes -m copy -a "src=/tmp/ceph.conf dest=/etc/ceph/ceph.conf owner=ceph group=ceph mode=0644" -b

# Deploy monitor on new node (if needed)
# ansible-playbook ~/ceph-ansible-playbooks/deploy-monitor.yml -e "target_host=ceph-node4"
Task 4: Automating Pool Creation and CRUSH Map Management
Subtask 4.1: Create Pool Management Playbook
Develop a comprehensive playbook for automated pool creation and management:

# Create pool management playbook
tee ~/ceph-ansible-playbooks/manage-pools.yml << 'EOF'
---
- name: Manage Ceph Pools
  hosts: mons[0]
  become: yes
  gather_facts: no
  vars:
    default_pg_num: 128
    default_pgp_num: 128
    default_pool_type: replicated
    default_size: 3
    default_min_size: 2
    
  tasks:
    - name: Validate required variables
      fail:
        msg: "pool_name is required"
      when: pool_name is not defined

    - name: Get cluster status
      shell: ceph -s --format json
      register: cluster_status
      changed_when: false

    - name: Parse cluster status
      set_fact:
        cluster_health: "{{ (cluster_status.stdout | from_json).health.status }}"
        total_osds: "{{ (cluster_status.stdout | from_json).osdmap.num_osds }}"

    - name: Check if cluster is healthy
      fail:
        msg: "Cluster health is {{ cluster_health }}. Pools should only be created on healthy clusters."
      when: 
        - cluster_health != "HEALTH_OK"
        - force_create | default(false) == false

    - name: Calculate optimal PG numbers
      set_fact:
        calculated_pg_num: "{{ ((total_osds | int * 100) / (pool_size | default(default_size) | int)) | round | int }}"
      when: pg_num is not defined

    - name: Set PG numbers
      set_fact:
        final_pg_num: "{{ pg_num | default(calculated_pg_num) | default(default_pg_num) }}"
        final_pgp_num: "{{ pgp_num | default(calculated_pg_num) | default(default_pgp_num) }}"

    - name: Check if pool already exists
      shell: ceph osd pool ls | grep "^{{ pool_name }}$"
      register: pool_exists
      failed_when: false
      changed_when: false

    - name: Create replicated pool
      shell: |
        ceph osd pool create {{ pool_name }} {{ final_pg_num }} {{ final_pgp_num }} {{ pool_type | default(default_pool_type) }}
      when: 
        - pool_exists.rc != 0
        - pool_type | default(default_pool_type) == "replicated"

    - name: Create erasure coded pool
      shell: |
        ceph osd pool create {{ pool_name }} {{ final_pg_num }} {{ final_pgp_num }} erasure {{ ec_profile | default('default') }}
      when: 
        - pool_exists.rc != 0
        - pool_type | default(default_pool_type) == "erasure"

    - name: Set pool size (replicated pools only)
      shell: |
        ceph osd pool set {{ pool_name }} size {{ pool_size | default(default_size) }}
      when: 
        - pool_type | default(default_pool_type) == "replicated"
        - pool_size is defined

    - name: Set pool min_size (replicated pools only)
      shell: |
        ceph osd pool set {{ pool_name }} min_size {{ pool_min_size | default(default_min_size) }}
      when: 
        - pool_type | default(default_pool_type) == "replicated"
        - pool_min_size is defined

    - name: Enable application on pool
      shell: |
        ceph osd pool application enable {{ pool_name }} {{ pool_application }}
      when: pool_application is defined

    - name: Set pool quotas
      shell: |
        ceph osd pool set-quota {{ pool_name }} {{ item.key }} {{ item.value }}
      loop:
        - { key: "max_objects", value: "{{ pool_max_objects }}" }
        - { key: "max_bytes", value: "{{ pool_max_bytes }}" }
      when: 
        - item.value is defined
        - item.value != ""

    - name: Configure pool compression
      shell: |
        ceph osd pool set {{ pool_name }} compression_algorithm {{ compression_algorithm | default('snappy') }}
      when: enable_compression | default(false) == true

    - name: Enable compression on pool
      shell: |
        ceph osd pool set {{ pool_name }} compression_mode {{ compression_mode | default('aggressive') }}
      when: enable_compression | default(false) == true

    - name: Get final pool information
      shell: |
        ceph osd pool ls detail | grep -A 10 "pool {{ pool_name }}"
      register: pool_info
      changed_when: false

    - name: Display pool information
      debug:
        msg: "{{ pool_info.stdout_lines }}"
EOF
Subtask 4.2: Create CRUSH Map Management Playbook
Develop automation for CRUSH map customization:

# Create CRUSH map management playbook
tee ~/ceph-ansible-playbooks/manage-crush-map.yml << 'EOF'
---
- name: Manage Ceph CRUSH Map
  hosts: mons[0]
  become: yes
  gather_facts: no
  vars:
    crush_backup_dir: /tmp/crush-backups
    
  tasks:
    - name: Create backup directory
      file:
        path: "{{ crush_backup_dir }}"
        state: directory
        mode: '0755'

    - name: Backup current CRUSH map
      shell: |
        ceph osd getcrushmap -o {{ crush_backup_dir }}/crushmap-backup-{{ ansible_date_time.epoch }}
        ceph osd crush dump > {{ crush_backup_dir }}/crushmap-text-backup-{{ ansible_date_time.epoch }}.json
      register: backup_result

    - name: Display backup location
      debug:
        msg: "CRUSH map backed up to {{ crush_backup_dir }}"

    - name: Get current CRUSH map in text format
      shell: |
        ceph osd crush dump
      register: current_crush_map
      changed_when: false

    - name: Create custom CRUSH rule for SSD pool
      shell: |
        ceph osd crush rule create-replicated ssd_rule default host ssd
      when: 
        - create_ssd_rule | default(false) == true
        - "'ssd_rule' not in current_crush_map.stdout"

    - name: Create custom CRUSH rule for HDD pool
      shell: |
        ceph osd crush rule create-replicated hdd_rule default host hdd
      when: 
        - create_hdd_rule | default(false) == true
        - "'hdd_rule' not in current_crush_map.stdout"

    - name: Create rack-aware CRUSH rule
      shell: |
        ceph osd crush rule create-replicated rack_rule default rack
      when: 
        - create_rack_rule | default(false) == true
        - "'rack_rule' not in current_crush_map.stdout"

    - name: Set device class for OSDs (if specified)
      shell: |
        ceph osd crush rm-device-class {{ item.osd_id }}
        ceph osd crush set-device-class {{ item.device_class }} {{ item.osd_id }}
      loop: "{{ osd_device_classes | default([]) }}"
      when: osd_device_classes is defined

    - name: Move OSD to specific CRUSH location
      shell: |
        ceph osd crush set {{ item.osd_id }} {{ item.weight }} {{ item.location }}
      loop: "{{ osd_crush_locations | default([]) }}"
      when: osd_crush_locations is defined

    - name: Create custom CRUSH bucket
      shell: |
        ceph osd crush add-bucket {{ item.name }} {{ item.type }}
      loop: "{{ custom_crush_buckets | default([]) }}"
      when: custom_crush_buckets is defined

    - name: Move CRUSH bucket to location
      shell: |
        ceph osd crush move {{ item.name }} {{ item.location }}
      loop: "{{ crush_bucket_moves | default([]) }}"
      when: crush_bucket_moves is defined

    - name: Set CRUSH tunables
      shell: |
        ceph osd crush tunables {{ crush_tunables | default('optimal') }}
      when: set_crush_tunables | default(false) == true

    - name: Verify CRUSH map changes
      shell: |
        ceph osd crush tree
      register: crush_tree
      changed_when: false

    - name: Display CRUSH tree
      debug:
        msg: "{{ crush_tree.stdout_lines }}"

    - name: Test CRUSH rule (if specified)
      shell: |
        ceph osd crush rule ls
      register: crush_rules
      changed_when: false

    - name: Display available CRUSH rules
      debug:
        msg: "Available CRUSH rules: {{ crush_rules.stdout_lines }}"
EOF
Subtask 4.3: Create Combined Pool and CRUSH Management Playbook
Create a comprehensive playbook that combines pool creation with CRUSH map management:

# Create combined management playbook
tee ~/ceph-ansible-playbooks/deploy-storage-solution.yml << 'EOF'
---
- name: Deploy Complete Storage Solution
  hosts: mons[0]
