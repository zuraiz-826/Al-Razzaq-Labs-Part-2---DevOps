Lab 7: Automating Storage Management
Objectives
By the end of this lab, you will be able to:

• Automate disk partitioning using Ansible playbooks • Create and manage logical volumes with the lvol module • Format and mount file systems automatically • Ensure persistent mounting across system reboots • Implement storage automation best practices for enterprise environments

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Linux file systems and storage concepts • Familiarity with Ansible playbooks and YAML syntax • Knowledge of LVM (Logical Volume Manager) fundamentals • Experience with basic Linux command-line operations • Understanding of mount points and /etc/fstab configuration

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes: • CentOS/RHEL 8 or 9 system with Ansible installed • Additional disk (/dev/sdb) for partitioning and LVM operations • Root access for storage management tasks • All necessary packages pre-installed

Task 1: Write a Playbook to Partition a Disk and Create Logical Volumes
Subtask 1.1: Create the Directory Structure
First, let's create a proper directory structure for our Ansible project.

mkdir -p ~/storage-automation/{playbooks,inventory,group_vars}
cd ~/storage-automation
Subtask 1.2: Create the Inventory File
Create an inventory file to define our target hosts:

cat > inventory/hosts << EOF
[storage_servers]
localhost ansible_connection=local
EOF
Subtask 1.3: Create the Main Storage Automation Playbook
Create the main playbook that will handle disk partitioning and logical volume creation:

cat > playbooks/storage-management.yml << 'EOF'
---
- name: Automate Storage Management
  hosts: storage_servers
  become: yes
  vars:
    target_disk: /dev/sdb
    volume_group_name: vg_data
    logical_volumes:
      - name: lv_web
        size: 2G
        mount_point: /var/www
        filesystem: ext4
      - name: lv_logs
        size: 1G
        mount_point: /var/log/apps
        filesystem: xfs
      - name: lv_backup
        size: 1G
        mount_point: /backup
        filesystem: ext4

  tasks:
    - name: Install required packages
      package:
        name:
          - lvm2
          - parted
          - xfsprogs
        state: present

    - name: Check if disk exists
      stat:
        path: "{{ target_disk }}"
      register: disk_check

    - name: Fail if disk doesn't exist
      fail:
        msg: "Target disk {{ target_disk }} does not exist"
      when: not disk_check.stat.exists

    - name: Create partition on target disk
      parted:
        device: "{{ target_disk }}"
        number: 1
        state: present
        part_type: primary
        part_start: 0%
        part_end: 100%
        flags: [lvm]

    - name: Create volume group
      lvg:
        vg: "{{ volume_group_name }}"
        pvs: "{{ target_disk }}1"
        state: present

    - name: Create logical volumes
      lvol:
        vg: "{{ volume_group_name }}"
        lv: "{{ item.name }}"
        size: "{{ item.size }}"
        state: present
      loop: "{{ logical_volumes }}"

    - name: Display created logical volumes
      command: lvdisplay
      register: lv_display
      changed_when: false

    - name: Show logical volume information
      debug:
        msg: "{{ lv_display.stdout_lines }}"
EOF
Subtask 1.4: Test the Partitioning and LVM Creation
Run the playbook to create partitions and logical volumes:

ansible-playbook -i inventory/hosts playbooks/storage-management.yml
Subtask 1.5: Verify the Logical Volumes
Check that the logical volumes were created successfully:

# Display volume groups
sudo vgdisplay

# Display logical volumes
sudo lvdisplay

# Show physical volumes
sudo pvdisplay
Task 2: Format the Logical Volumes and Mount Them
Subtask 2.1: Create the Filesystem and Mounting Playbook
Create a separate playbook for formatting and mounting operations:

cat > playbooks/format-and-mount.yml << 'EOF'
---
- name: Format and Mount Logical Volumes
  hosts: storage_servers
  become: yes
  vars:
    volume_group_name: vg_data
    logical_volumes:
      - name: lv_web
        size: 2G
        mount_point: /var/www
        filesystem: ext4
        mount_options: defaults
      - name: lv_logs
        size: 1G
        mount_point: /var/log/apps
        filesystem: xfs
        mount_options: defaults,noatime
      - name: lv_backup
        size: 1G
        mount_point: /backup
        filesystem: ext4
        mount_options: defaults

  tasks:
    - name: Create mount point directories
      file:
        path: "{{ item.mount_point }}"
        state: directory
        mode: '0755'
      loop: "{{ logical_volumes }}"

    - name: Format logical volumes with specified filesystem
      filesystem:
        fstype: "{{ item.filesystem }}"
        dev: "/dev/{{ volume_group_name }}/{{ item.name }}"
        force: no
      loop: "{{ logical_volumes }}"

    - name: Mount logical volumes temporarily
      mount:
        path: "{{ item.mount_point }}"
        src: "/dev/{{ volume_group_name }}/{{ item.name }}"
        fstype: "{{ item.filesystem }}"
        opts: "{{ item.mount_options }}"
        state: mounted
      loop: "{{ logical_volumes }}"

    - name: Verify mounted filesystems
      command: df -h
      register: df_output
      changed_when: false

    - name: Display mounted filesystems
      debug:
        msg: "{{ df_output.stdout_lines }}"
EOF
Subtask 2.2: Execute the Formatting and Mounting Playbook
Run the playbook to format and mount the logical volumes:

ansible-playbook -i inventory/hosts playbooks/format-and-mount.yml
Subtask 2.3: Verify the Mounted Filesystems
Check that all filesystems are properly mounted:

# Check mounted filesystems
df -h

# Verify mount points
mount | grep vg_data

# Check filesystem types
lsblk -f
Task 3: Ensure Mounted Volumes are Persistent Across Reboots
Subtask 3.1: Create the Persistent Mounting Playbook
Create a playbook to ensure persistent mounting by updating /etc/fstab:

cat > playbooks/persistent-mounts.yml << 'EOF'
---
- name: Configure Persistent Mounts
  hosts: storage_servers
  become: yes
  vars:
    volume_group_name: vg_data
    logical_volumes:
      - name: lv_web
        mount_point: /var/www
        filesystem: ext4
        mount_options: defaults
        dump: 1
        passno: 2
      - name: lv_logs
        mount_point: /var/log/apps
        filesystem: xfs
        mount_options: defaults,noatime
        dump: 1
        passno: 2
      - name: lv_backup
        mount_point: /backup
        filesystem: ext4
        mount_options: defaults
        dump: 1
        passno: 2

  tasks:
    - name: Backup original fstab
      copy:
        src: /etc/fstab
        dest: /etc/fstab.backup.{{ ansible_date_time.epoch }}
        remote_src: yes

    - name: Add logical volumes to fstab for persistent mounting
      mount:
        path: "{{ item.mount_point }}"
        src: "/dev/{{ volume_group_name }}/{{ item.name }}"
        fstype: "{{ item.filesystem }}"
        opts: "{{ item.mount_options }}"
        dump: "{{ item.dump }}"
        passno: "{{ item.passno }}"
        state: present
      loop: "{{ logical_volumes }}"

    - name: Test fstab configuration
      command: mount -a
      register: mount_test
      changed_when: false

    - name: Display fstab entries for verification
      command: grep vg_data /etc/fstab
      register: fstab_entries
      changed_when: false

    - name: Show fstab entries
      debug:
        msg: "{{ fstab_entries.stdout_lines }}"

    - name: Create test files to verify write access
      file:
        path: "{{ item.mount_point }}/test_file_{{ item.name }}.txt"
        state: touch
        mode: '0644'
      loop: "{{ logical_volumes }}"

    - name: Verify write access by creating content
      copy:
        content: |
          This is a test file created on {{ item.name }}
          Mount point: {{ item.mount_point }}
          Filesystem: {{ item.filesystem }}
          Created: {{ ansible_date_time.iso8601 }}
        dest: "{{ item.mount_point }}/test_file_{{ item.name }}.txt"
      loop: "{{ logical_volumes }}"
EOF
Subtask 3.2: Execute the Persistent Mounting Playbook
Run the playbook to configure persistent mounts:

ansible-playbook -i inventory/hosts playbooks/persistent-mounts.yml
Subtask 3.3: Create a Complete Storage Management Playbook
Create a comprehensive playbook that combines all tasks:

cat > playbooks/complete-storage-automation.yml << 'EOF'
---
- name: Complete Storage Management Automation
  hosts: storage_servers
  become: yes
  vars:
    target_disk: /dev/sdb
    volume_group_name: vg_data
    logical_volumes:
      - name: lv_web
        size: 2G
        mount_point: /var/www
        filesystem: ext4
        mount_options: defaults
        dump: 1
        passno: 2
      - name: lv_logs
        size: 1G
        mount_point: /var/log/apps
        filesystem: xfs
        mount_options: defaults,noatime
        dump: 1
        passno: 2
      - name: lv_backup
        size: 1G
        mount_point: /backup
        filesystem: ext4
        mount_options: defaults
        dump: 1
        passno: 2

  tasks:
    - name: Install required packages
      package:
        name:
          - lvm2
          - parted
          - xfsprogs
        state: present

    - name: Check if disk exists
      stat:
        path: "{{ target_disk }}"
      register: disk_check

    - name: Fail if disk doesn't exist
      fail:
        msg: "Target disk {{ target_disk }} does not exist"
      when: not disk_check.stat.exists

    - name: Create partition on target disk
      parted:
        device: "{{ target_disk }}"
        number: 1
        state: present
        part_type: primary
        part_start: 0%
        part_end: 100%
        flags: [lvm]

    - name: Create volume group
      lvg:
        vg: "{{ volume_group_name }}"
        pvs: "{{ target_disk }}1"
        state: present

    - name: Create logical volumes
      lvol:
        vg: "{{ volume_group_name }}"
        lv: "{{ item.name }}"
        size: "{{ item.size }}"
        state: present
      loop: "{{ logical_volumes }}"

    - name: Create mount point directories
      file:
        path: "{{ item.mount_point }}"
        state: directory
        mode: '0755'
      loop: "{{ logical_volumes }}"

    - name: Format logical volumes with specified filesystem
      filesystem:
        fstype: "{{ item.filesystem }}"
        dev: "/dev/{{ volume_group_name }}/{{ item.name }}"
        force: no
      loop: "{{ logical_volumes }}"

    - name: Backup original fstab
      copy:
        src: /etc/fstab
        dest: /etc/fstab.backup.{{ ansible_date_time.epoch }}
        remote_src: yes

    - name: Mount logical volumes and add to fstab
      mount:
        path: "{{ item.mount_point }}"
        src: "/dev/{{ volume_group_name }}/{{ item.name }}"
        fstype: "{{ item.filesystem }}"
        opts: "{{ item.mount_options }}"
        dump: "{{ item.dump }}"
        passno: "{{ item.passno }}"
        state: mounted
      loop: "{{ logical_volumes }}"

    - name: Create test files to verify functionality
      copy:
        content: |
          Storage automation test successful!
          Logical Volume: {{ item.name }}
          Mount Point: {{ item.mount_point }}
          Filesystem: {{ item.filesystem }}
          Created: {{ ansible_date_time.iso8601 }}
        dest: "{{ item.mount_point }}/storage_test.txt"
        mode: '0644'
      loop: "{{ logical_volumes }}"

    - name: Display final storage configuration
      shell: |
        echo "=== Volume Groups ==="
        vgdisplay --short
        echo "=== Logical Volumes ==="
        lvdisplay --short
        echo "=== Mounted Filesystems ==="
        df -h | grep vg_data
        echo "=== fstab Entries ==="
        grep vg_data /etc/fstab
      register: storage_summary
      changed_when: false

    - name: Show storage configuration summary
      debug:
        msg: "{{ storage_summary.stdout_lines }}"
EOF
Subtask 3.4: Test the Complete Automation
Run the complete storage automation playbook:

ansible-playbook -i inventory/hosts playbooks/complete-storage-automation.yml
Subtask 3.5: Verify Persistent Mounting
Test that the mounts persist across reboots by simulating a mount/unmount cycle:

# Unmount all logical volumes
sudo umount /var/www /var/log/apps /backup

# Verify they're unmounted
df -h | grep vg_data

# Remount using fstab
sudo mount -a

# Verify they're mounted again
df -h | grep vg_data

# Check the test files are still accessible
ls -la /var/www/storage_test.txt
ls -la /var/log/apps/storage_test.txt
ls -la /backup/storage_test.txt
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Disk not found

# Check available disks
lsblk

# If /dev/sdb doesn't exist, use an available disk
# Update the target_disk variable in your playbook
Issue 2: Volume group already exists

# Remove existing volume group if needed
sudo vgremove vg_data
sudo pvremove /dev/sdb1
Issue 3: Mount point already in use

# Check what's using the mount point
sudo lsof /var/www

# Unmount if necessary
sudo umount /var/www
Issue 4: Filesystem already exists

# Check existing filesystems
sudo blkid /dev/vg_data/lv_web

# Use force: yes in filesystem module if needed
Verification Commands
Use these commands to verify your storage configuration:

# Check physical volumes
sudo pvs

# Check volume groups
sudo vgs

# Check logical volumes
sudo lvs

# Check mounted filesystems
mount | grep vg_data

# Check fstab entries
grep vg_data /etc/fstab

# Test filesystem write access
echo "test" | sudo tee /var/www/write_test.txt
Best Practices for Storage Automation
Security Considerations
• Always backup fstab before making changes • Use appropriate file permissions on mount points • Implement proper access controls for sensitive data directories • Monitor disk usage to prevent filesystem full conditions

Performance Optimization
• Choose appropriate filesystem types (ext4 for general use, xfs for large files) • Use optimal mount options (noatime for log directories) • Consider LVM striping for improved performance • Plan logical volume sizes based on expected growth

Maintenance and Monitoring
# Create a monitoring script
cat > ~/check-storage.sh << 'EOF'
#!/bin/bash
echo "=== Storage Health Check ==="
echo "Date: $(date)"
echo
echo "=== Disk Usage ==="
df -h | grep -E "(Filesystem|vg_data)"
echo
echo "=== LVM Status ==="
sudo vgs
sudo lvs
echo
echo "=== Mount Status ==="
mount | grep vg_data
EOF

chmod +x ~/check-storage.sh
Conclusion
In this lab, you have successfully accomplished the following:

• Automated disk partitioning using Ansible's parted module to prepare storage devices • Created logical volumes with the lvol module, providing flexible storage management • Formatted filesystems automatically with different filesystem types (ext4 and xfs) • Configured persistent mounting through /etc/fstab to ensure availability across reboots • Implemented comprehensive storage automation that can be reused across multiple systems

Why This Matters
Storage automation is crucial in enterprise environments because it:

• Reduces human error in storage configuration tasks • Ensures consistency across multiple servers • Saves time during system deployment and maintenance • Provides reproducible infrastructure that can be version-controlled • Enables rapid scaling of storage resources

Next Steps
To further enhance your storage automation skills:

• Explore LVM snapshots for backup automation • Implement storage monitoring with automated alerts • Learn about storage encryption automation • Practice disaster recovery scenarios with automated restoration • Study cloud storage automation with providers like AWS EBS or Azure Disks

This lab provides a solid foundation for the Red Hat Certified Engineer (RHCE) exam, specifically covering storage management automation objectives. The skills learned here are directly applicable to real-world enterprise storage management scenarios.
