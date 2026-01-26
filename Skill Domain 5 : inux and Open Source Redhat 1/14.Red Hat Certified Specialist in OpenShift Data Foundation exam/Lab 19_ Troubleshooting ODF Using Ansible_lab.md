Lab 19: Troubleshooting ODF Using Ansible
Objectives
By the end of this lab, students will be able to:

Implement Ansible automation for troubleshooting OpenShift Data Foundation (ODF) storage issues
Create automated monitoring and alerting systems for storage health using Ansible
Utilize Ansible facts to verify and validate ODF system state
Develop playbooks for common ODF troubleshooting scenarios
Configure automated remediation workflows for storage-related problems
Prerequisites
Before starting this lab, students should have:

Basic understanding of OpenShift Container Platform concepts
Familiarity with OpenShift Data Foundation (ODF) components
Knowledge of Ansible fundamentals including playbooks, tasks, and modules
Experience with YAML syntax and structure
Understanding of Kubernetes/OpenShift CLI commands
Basic Linux command line skills
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to begin - no need to build your own VM or install software.

Your lab environment includes:

OpenShift cluster with ODF installed
Ansible control node with required collections
Pre-configured authentication and access
Sample storage workloads for testing
Task 1: Use Ansible to Automate the Troubleshooting of Storage Issues
Subtask 1.1: Set Up Ansible Environment for ODF Troubleshooting
First, let's prepare our Ansible environment with the necessary collections and configurations.

Install Required Ansible Collections
# Install OpenShift and Kubernetes collections
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install redhat.openshift
ansible-galaxy collection install community.general
Create Project Directory Structure
# Create organized directory structure
mkdir -p ~/odf-troubleshooting-lab/{playbooks,inventory,roles,vars,templates}
cd ~/odf-troubleshooting-lab
Configure Ansible Inventory
Create the inventory file:

cat > inventory/hosts.yml << 'EOF'
all:
  children:
    openshift:
      hosts:
        localhost:
          ansible_connection: local
          ansible_python_interpreter: "{{ ansible_playbook_python }}"
      vars:
        openshift_cluster_url: "https://api.cluster.example.com:6443"
        openshift_token: "{{ lookup('env', 'OPENSHIFT_TOKEN') }}"
        validate_certs: false
EOF
Subtask 1.2: Create Storage Health Check Playbook
Create Basic Storage Health Assessment Playbook
cat > playbooks/storage-health-check.yml << 'EOF'
---
- name: ODF Storage Health Check and Troubleshooting
  hosts: localhost
  gather_facts: yes
  vars:
    odf_namespace: "openshift-storage"
    
  tasks:
    - name: Authenticate to OpenShift cluster
      kubernetes.core.k8s_auth:
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ openshift_token }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: k8s_auth_results

    - name: Check ODF namespace status
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Namespace
        name: "{{ odf_namespace }}"
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: odf_namespace_status

    - name: Display namespace status
      debug:
        msg: "ODF Namespace Status: {{ odf_namespace_status.resources[0].status.phase }}"

    - name: Get all storage classes
      kubernetes.core.k8s_info:
        api_version: storage.k8s.io/v1
        kind: StorageClass
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: storage_classes

    - name: Check ODF-related storage classes
      debug:
        msg: "Found storage class: {{ item.metadata.name }}"
      loop: "{{ storage_classes.resources }}"
      when: "'ocs' in item.metadata.name or 'odf' in item.metadata.name"

    - name: Get Ceph cluster status
      kubernetes.core.k8s_info:
        api_version: ceph.rook.io/v1
        kind: CephCluster
        namespace: "{{ odf_namespace }}"
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: ceph_clusters

    - name: Display Ceph cluster health
      debug:
        msg: "Ceph Cluster {{ item.metadata.name }} Status: {{ item.status.phase | default('Unknown') }}"
      loop: "{{ ceph_clusters.resources }}"
      when: ceph_clusters.resources | length > 0
EOF
Run the Health Check Playbook
# Set your OpenShift token
export OPENSHIFT_TOKEN="your-token-here"

# Execute the health check
ansible-playbook -i inventory/hosts.yml playbooks/storage-health-check.yml
Subtask 1.3: Create Automated Storage Issue Detection
Create Advanced Troubleshooting Playbook
cat > playbooks/storage-troubleshooting.yml << 'EOF'
---
- name: Automated ODF Storage Issue Detection and Resolution
  hosts: localhost
  gather_facts: yes
  vars:
    odf_namespace: "openshift-storage"
    
  tasks:
    - name: Authenticate to OpenShift cluster
      kubernetes.core.k8s_auth:
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ openshift_token }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: k8s_auth_results

    - name: Check for failed PVCs
      kubernetes.core.k8s_info:
        api_version: v1
        kind: PersistentVolumeClaim
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: all_pvcs

    - name: Identify problematic PVCs
      set_fact:
        failed_pvcs: "{{ all_pvcs.resources | selectattr('status.phase', 'equalto', 'Pending') | list }}"

    - name: Report failed PVCs
      debug:
        msg: "Failed PVC: {{ item.metadata.name }} in namespace {{ item.metadata.namespace }} - Status: {{ item.status.phase }}"
      loop: "{{ failed_pvcs }}"
      when: failed_pvcs | length > 0

    - name: Check ODF operator pods
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Pod
        namespace: "{{ odf_namespace }}"
        label_selectors:
          - "app=odf-operator"
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: odf_operator_pods

    - name: Check operator pod status
      debug:
        msg: "ODF Operator Pod {{ item.metadata.name }} Status: {{ item.status.phase }}"
      loop: "{{ odf_operator_pods.resources }}"

    - name: Check Ceph OSD pods
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Pod
        namespace: "{{ odf_namespace }}"
        label_selectors:
          - "app=rook-ceph-osd"
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: ceph_osd_pods

    - name: Identify unhealthy OSD pods
      set_fact:
        unhealthy_osds: "{{ ceph_osd_pods.resources | rejectattr('status.phase', 'equalto', 'Running') | list }}"

    - name: Report unhealthy OSD pods
      debug:
        msg: "Unhealthy OSD Pod: {{ item.metadata.name }} - Status: {{ item.status.phase }}"
      loop: "{{ unhealthy_osds }}"
      when: unhealthy_osds | length > 0

    - name: Generate troubleshooting report
      template:
        src: troubleshooting-report.j2
        dest: "/tmp/odf-troubleshooting-report-{{ ansible_date_time.epoch }}.txt"
      vars:
        report_timestamp: "{{ ansible_date_time.iso8601 }}"
        failed_pvcs_count: "{{ failed_pvcs | length }}"
        unhealthy_osds_count: "{{ unhealthy_osds | length }}"
EOF
Create Report Template
cat > templates/troubleshooting-report.j2 << 'EOF'
ODF Storage Troubleshooting Report
Generated: {{ report_timestamp }}
=====================================

Summary:
- Failed PVCs: {{ failed_pvcs_count }}
- Unhealthy OSD Pods: {{ unhealthy_osds_count }}

{% if failed_pvcs | length > 0 %}
Failed PVCs:
{% for pvc in failed_pvcs %}
- Name: {{ pvc.metadata.name }}
  Namespace: {{ pvc.metadata.namespace }}
  Status: {{ pvc.status.phase }}
  Storage Class: {{ pvc.spec.storageClassName | default('N/A') }}
{% endfor %}
{% endif %}

{% if unhealthy_osds | length > 0 %}
Unhealthy OSD Pods:
{% for osd in unhealthy_osds %}
- Name: {{ osd.metadata.name }}
  Status: {{ osd.status.phase }}
  Node: {{ osd.spec.nodeName | default('N/A') }}
{% endfor %}
{% endif %}

Recommendations:
{% if failed_pvcs | length > 0 %}
- Check storage class availability and configuration
- Verify sufficient storage capacity
- Review PVC specifications
{% endif %}
{% if unhealthy_osds | length > 0 %}
- Check node health and disk availability
- Review OSD logs for specific errors
- Verify Ceph cluster configuration
{% endif %}
EOF
Task 2: Automate Monitoring and Alerting for Storage Health
Subtask 2.1: Create Continuous Monitoring Playbook
Create Storage Monitoring Playbook
cat > playbooks/storage-monitoring.yml << 'EOF'
---
- name: Continuous ODF Storage Monitoring
  hosts: localhost
  gather_facts: yes
  vars:
    odf_namespace: "openshift-storage"
    monitoring_interval: 300  # 5 minutes
    alert_thresholds:
      pvc_pending_threshold: 5  # minutes
      pod_restart_threshold: 3
      
  tasks:
    - name: Authenticate to OpenShift cluster
      kubernetes.core.k8s_auth:
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ openshift_token }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: k8s_auth_results

    - name: Monitor storage capacity
      kubernetes.core.k8s_info:
        api_version: v1
        kind: PersistentVolume
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: persistent_volumes

    - name: Calculate total storage capacity
      set_fact:
        total_capacity: "{{ persistent_volumes.resources | map(attribute='spec.capacity.storage') | map('regex_replace', 'Gi|Ti|Mi', '') | map('int') | sum }}"

    - name: Check Ceph cluster health status
      kubernetes.core.k8s_exec:
        namespace: "{{ odf_namespace }}"
        pod: "{{ ceph_tools_pod.metadata.name }}"
        command: ceph health
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: ceph_health_output
      vars:
        ceph_tools_pod: "{{ (ceph_tools_pods.resources | first) }}"
      when: ceph_tools_pods.resources | length > 0

    - name: Get Ceph tools pod
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Pod
        namespace: "{{ odf_namespace }}"
        label_selectors:
          - "app=rook-ceph-tools"
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: ceph_tools_pods

    - name: Monitor node storage usage
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Node
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: cluster_nodes

    - name: Create monitoring metrics file
      copy:
        content: |
          # ODF Storage Monitoring Metrics
          # Timestamp: {{ ansible_date_time.iso8601 }}
          
          total_pvs={{ persistent_volumes.resources | length }}
          total_capacity_gi={{ total_capacity }}
          cluster_nodes={{ cluster_nodes.resources | length }}
          {% if ceph_health_output is defined %}
          ceph_health={{ ceph_health_output.stdout | default('UNKNOWN') }}
          {% endif %}
        dest: "/tmp/odf-metrics-{{ ansible_date_time.epoch }}.txt"

    - name: Check for storage alerts
      set_fact:
        storage_alerts: []

    - name: Add capacity alert if needed
      set_fact:
        storage_alerts: "{{ storage_alerts + ['Low storage capacity detected'] }}"
      when: total_capacity | int < 100  # Less than 100Gi available

    - name: Send alert notification (simulated)
      debug:
        msg: "ALERT: {{ item }}"
      loop: "{{ storage_alerts }}"
      when: storage_alerts | length > 0
EOF
Subtask 2.2: Create Automated Alerting System
Create Alert Configuration Playbook
cat > playbooks/setup-alerting.yml << 'EOF'
---
- name: Setup ODF Storage Alerting System
  hosts: localhost
  gather_facts: yes
  vars:
    odf_namespace: "openshift-storage"
    alert_config_namespace: "openshift-monitoring"
    
  tasks:
    - name: Authenticate to OpenShift cluster
      kubernetes.core.k8s_auth:
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ openshift_token }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: k8s_auth_results

    - name: Create custom PrometheusRule for ODF monitoring
      kubernetes.core.k8s:
        state: present
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
        definition:
          apiVersion: monitoring.coreos.com/v1
          kind: PrometheusRule
          metadata:
            name: odf-storage-alerts
            namespace: "{{ odf_namespace }}"
            labels:
              prometheus: kube-prometheus
              role: alert-rules
          spec:
            groups:
              - name: odf.storage.rules
                rules:
                  - alert: ODFStorageCapacityLow
                    expr: |
                      (
                        sum(kubelet_volume_stats_capacity_bytes{namespace=~".*"}) -
                        sum(kubelet_volume_stats_used_bytes{namespace=~".*"})
                      ) / sum(kubelet_volume_stats_capacity_bytes{namespace=~".*"}) * 100 < 20
                    for: 5m
                    labels:
                      severity: warning
                    annotations:
                      summary: "ODF storage capacity is running low"
                      description: "Available storage capacity is below 20%"
                      
                  - alert: ODFCephClusterUnhealthy
                    expr: ceph_health_status != 0
                    for: 2m
                    labels:
                      severity: critical
                    annotations:
                      summary: "Ceph cluster is unhealthy"
                      description: "Ceph cluster health status indicates problems"

    - name: Create ServiceMonitor for custom metrics
      kubernetes.core.k8s:
        state: present
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
        definition:
          apiVersion: monitoring.coreos.com/v1
          kind: ServiceMonitor
          metadata:
            name: odf-custom-metrics
            namespace: "{{ odf_namespace }}"
            labels:
              app: odf-monitoring
          spec:
            selector:
              matchLabels:
                app: odf-metrics-exporter
            endpoints:
              - port: metrics
                interval: 30s
                path: /metrics

    - name: Verify PrometheusRule creation
      kubernetes.core.k8s_info:
        api_version: monitoring.coreos.com/v1
        kind: PrometheusRule
        name: odf-storage-alerts
        namespace: "{{ odf_namespace }}"
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: prometheus_rule_status

    - name: Display PrometheusRule status
      debug:
        msg: "PrometheusRule created successfully: {{ prometheus_rule_status.resources[0].metadata.name }}"
      when: prometheus_rule_status.resources | length > 0
EOF
Create Alert Handler Playbook
cat > playbooks/handle-alerts.yml << 'EOF'
---
- name: Handle ODF Storage Alerts
  hosts: localhost
  gather_facts: yes
  vars:
    odf_namespace: "openshift-storage"
    
  tasks:
    - name: Authenticate to OpenShift cluster
      kubernetes.core.k8s_auth:
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ openshift_token }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: k8s_auth_results

    - name: Check for active alerts
      uri:
        url: "{{ prometheus_url }}/api/v1/alerts"
        method: GET
        headers:
          Authorization: "Bearer {{ openshift_token }}"
        validate_certs: false
      register: active_alerts
      vars:
        prometheus_url: "https://prometheus-k8s-openshift-monitoring.apps.cluster.example.com"
      ignore_errors: yes

    - name: Process storage capacity alerts
      block:
        - name: Identify nodes with low disk space
          kubernetes.core.k8s_info:
            api_version: v1
            kind: Node
            host: "{{ openshift_cluster_url }}"
            api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
            validate_certs: "{{ validate_certs | default(false) }}"
          register: all_nodes

        - name: Create remediation task list
          set_fact:
            remediation_tasks:
              - "Clean up unused PVCs"
              - "Expand storage capacity"
              - "Review storage policies"
              - "Check for storage leaks"

        - name: Execute automated cleanup (simulation)
          debug:
            msg: "Executing remediation task: {{ item }}"
          loop: "{{ remediation_tasks }}"

    - name: Log alert handling actions
      copy:
        content: |
          Alert Handling Log
          Timestamp: {{ ansible_date_time.iso8601 }}
          
          Actions Taken:
          {% for task in remediation_tasks %}
          - {{ task }}
          {% endfor %}
          
          Status: Completed
        dest: "/tmp/alert-handling-{{ ansible_date_time.epoch }}.log"
EOF
Task 3: Use Ansible Facts to Verify ODF System State
Subtask 3.1: Create System State Verification Playbook
Create Comprehensive State Verification Playbook
cat > playbooks/verify-odf-state.yml << 'EOF'
---
- name: Verify ODF System State Using Ansible Facts
  hosts: localhost
  gather_facts: yes
  vars:
    odf_namespace: "openshift-storage"
    
  tasks:
    - name: Authenticate to OpenShift cluster
      kubernetes.core.k8s_auth:
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ openshift_token }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: k8s_auth_results

    - name: Gather cluster facts
      kubernetes.core.k8s_cluster_info:
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: cluster_info

    - name: Set cluster facts
      set_fact:
        cluster_version: "{{ cluster_info.version.kubernetes }}"
        cluster_platform: "{{ cluster_info.version.platform | default('unknown') }}"

    - name: Gather ODF operator information
      kubernetes.core.k8s_info:
        api_version: apps/v1
        kind: Deployment
        namespace: "{{ odf_namespace }}"
        label_selectors:
          - "app.kubernetes.io/name=odf-operator"
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: odf_operator_deployments

    - name: Set ODF operator facts
      set_fact:
        odf_operator_ready: "{{ odf_operator_deployments.resources[0].status.readyReplicas | default(0) > 0 }}"
        odf_operator_version: "{{ odf_operator_deployments.resources[0].metadata.labels['app.kubernetes.io/version'] | default('unknown') }}"
      when: odf_operator_deployments.resources | length > 0

    - name: Gather storage class facts
      kubernetes.core.k8s_info:
        api_version: storage.k8s.io/v1
        kind: StorageClass
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: all_storage_classes

    - name: Set storage class facts
      set_fact:
        odf_storage_classes: "{{ all_storage_classes.resources | selectattr('provisioner', 'match', '.*ceph.*|.*ocs.*') | list }}"
        default_storage_class: "{{ all_storage_classes.resources | selectattr('metadata.annotations.storageclass.kubernetes.io/is-default-class', 'defined') | first | default({}) }}"

    - name: Gather Ceph cluster facts
      kubernetes.core.k8s_info:
        api_version: ceph.rook.io/v1
        kind: CephCluster
        namespace: "{{ odf_namespace }}"
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: ceph_clusters

    - name: Set Ceph cluster facts
      set_fact:
        ceph_cluster_count: "{{ ceph_clusters.resources | length }}"
        ceph_cluster_healthy: "{{ ceph_clusters.resources | selectattr('status.phase', 'equalto', 'Ready') | list | length > 0 }}"
        ceph_cluster_names: "{{ ceph_clusters.resources | map(attribute='metadata.name') | list }}"

    - name: Gather node facts for storage
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Node
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.k8s_auth.api_key }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: cluster_nodes

    - name: Set node facts
      set_fact:
        total_nodes: "{{ cluster_nodes.resources | length }}"
        storage_nodes: "{{ cluster_nodes.resources | selectattr('metadata.labels.cluster.ocs.openshift.io/openshift-storage', 'defined') | list }}"
        worker_nodes: "{{ cluster_nodes.resources | selectattr('metadata.labels.node-role.kubernetes.io/worker', 'defined') | list }}"

    - name: Create comprehensive system state report
      template:
        src: system-state-report.j2
        dest: "/tmp/odf-system-state-{{ ansible_date_time.epoch }}.txt"
      vars:
        report_facts:
          cluster_version: "{{ cluster_version }}"
          cluster_platform: "{{ cluster_platform }}"
          odf_operator_ready: "{{ odf_operator_ready | default(false) }}"
          odf_operator_version: "{{ odf_operator_version | default('unknown') }}"
          storage_classes_count: "{{ odf_storage_classes | length }}"
          ceph_cluster_count: "{{ ceph_cluster_count }}"
          ceph_cluster_healthy: "{{ ceph_cluster_healthy }}"
          total_nodes: "{{ total_nodes }}"
          storage_nodes_count: "{{ storage_nodes | length }}"

    - name: Display system state summary
      debug:
        msg: |
          ODF System State Summary:
          - Cluster Version: {{ cluster_version }}
          - ODF Operator Ready: {{ odf_operator_ready | default(false) }}
          - ODF Storage Classes: {{ odf_storage_classes | length }}
          - Ceph Clusters: {{ ceph_cluster_count }}
          - Ceph Healthy: {{ ceph_cluster_healthy }}
          - Storage Nodes: {{ storage_nodes | length }}
          - Total Nodes: {{ total_nodes }}
EOF
Create System State Report Template
cat > templates/system-state-report.j2 << 'EOF'
ODF System State Verification Report
Generated: {{ ansible_date_time.iso8601 }}
==========================================

CLUSTER INFORMATION:
- Kubernetes Version: {{ report_facts.cluster_version }}
- Platform: {{ report_facts.cluster_platform }}
- Total Nodes: {{ report_facts.total_nodes }}
- Storage Nodes: {{ report_facts.storage_nodes_count }}

ODF OPERATOR STATUS:
- Operator Ready: {{ report_facts.odf_operator_ready }}
- Operator Version: {{ report_facts.odf_operator_version }}

STORAGE CONFIGURATION:
- ODF Storage Classes: {{ report_facts.storage_classes_count }}
{% for sc in odf_storage_classes %}
  - {{ sc.metadata.name }} ({{ sc.provisioner }})
{% endfor %}

CEPH CLUSTER STATUS:
- Cluster Count: {{ report_facts.ceph_cluster_count }}
- Clusters Healthy: {{ report_facts.ceph_cluster_healthy }}
{% for name in ceph_cluster_names %}
  - Cluster: {{ name }}
{% endfor %}

SYSTEM HEALTH ASSESSMENT:
{% if report_facts.odf_operator_ready and report_facts.ceph_cluster_healthy %}
✓ System appears healthy
{% else %}
⚠ System issues detected:
{% if not report_facts.odf_operator_ready %}
  - ODF Operator not ready
{% endif %}
{% if not report_facts.ceph_cluster_healthy %}
  - Ceph cluster unhealthy
{% endif %}
{% endif %}

RECOMMENDATIONS:
{% if report_facts.storage_nodes_count < 3 %}
- Consider adding more storage nodes for better redundancy
{% endif %}
{% if report_facts.storage_classes_count == 0 %}
- No ODF storage classes found - check ODF installation
{% endif %}
EOF
Subtask 3.2: Create Automated State Validation
Create State Validation and Remediation Playbook
cat > playbooks/validate-and-remediate.yml << 'EOF'
---
- name: Validate ODF State and Apply Remediation
  hosts: localhost
  gather_facts: yes
  vars:
    odf_namespace: "openshift-storage"
    validation_rules:
      min_storage_nodes: 3
      required_storage_classes: ["ocs-storagecluster-ceph-rbd", "ocs-storagecluster-cephfs"]
      min_ceph_osds: 3
    
  tasks:
    - name: Authenticate to OpenShift cluster
      kubernetes.core.k8s_auth:
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ openshift_token }}"
        validate_certs: "{{ validate_certs | default(false) }}"
      register: k8s_auth_results

    - name: Include state verification tasks
      include_tasks: verify-odf-state.yml

    - name: Validate minimum storage nodes
      set_fact:
        storage_nodes_valid: "{{ storage_nodes | length >= validation_rules.min_storage_nodes }}"

    - name: Validate required storage classes
      set_fact:
        storage_classes_valid: "{{ validation_rules.required_storage_classes | difference(odf_storage_classes | map(attribute='metadata.name') | list) | length == 0 }}"

    - name: Check Ceph OSD count
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Pod
        namespace: "{{ odf_namespace }}"
        label_selectors:
          - "app=rook-ceph-osd"
        host: "{{ openshift_cluster_url }}"
        api_key: "{{ k8s_auth_results.
