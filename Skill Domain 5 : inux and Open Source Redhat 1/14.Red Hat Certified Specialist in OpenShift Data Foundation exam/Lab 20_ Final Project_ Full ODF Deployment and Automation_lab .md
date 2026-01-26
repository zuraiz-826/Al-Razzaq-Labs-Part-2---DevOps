Lab 20: Final Project: Full ODF Deployment and Automation
Objectives
By the end of this lab, students will be able to:

Deploy a complete OpenShift Data Foundation (ODF) solution with multi-zone resilience
Implement automated storage provisioning and backup solutions using Ansible
Configure comprehensive monitoring, alerting, and auditing for ODF storage resources
Validate production-ready ODF deployment with high availability and disaster recovery capabilities
Demonstrate proficiency in enterprise-grade storage automation and management
Prerequisites
Before starting this lab, students should have:

Basic understanding of Kubernetes and OpenShift concepts
Familiarity with storage concepts (PVs, PVCs, StorageClasses)
Experience with YAML configuration files
Basic knowledge of Ansible automation
Understanding of monitoring and alerting concepts
Completion of previous ODF labs (Labs 1-19) or equivalent experience
Required Knowledge Areas
OpenShift cluster administration
Container storage fundamentals
Ansible playbook development
Prometheus and Grafana basics
Linux command line operations
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to begin - no need to build your own VM or install additional software.

Pre-installed Tools
Your lab environment includes:

OpenShift CLI (oc)
Ansible and ansible-playbook
Git for version control
Text editors (vim, nano)
Monitoring tools and utilities
Task 1: Install and Configure ODF with Multi-Zone Resilience
Subtask 1.1: Prepare the OpenShift Cluster for Multi-Zone ODF
First, verify your cluster has the necessary resources and node distribution across zones.

# Check cluster nodes and their zones
oc get nodes --show-labels | grep topology.kubernetes.io/zone

# Verify node resources
oc describe nodes | grep -E "Name:|cpu:|memory:"

# Check for existing storage classes
oc get storageclass
Create the namespace and operator group for ODF:

# Create the openshift-storage namespace
oc create namespace openshift-storage

# Label the namespace for monitoring
oc label namespace openshift-storage openshift.io/cluster-monitoring=true
Subtask 1.2: Install the ODF Operator
Create the operator subscription configuration:

# Create file: odf-operator-subscription.yaml
cat << 'EOF' > odf-operator-subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: odf-operator
  namespace: openshift-storage
spec:
  channel: stable-4.14
  installPlanApproval: Automatic
  name: odf-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-storage-operatorgroup
  namespace: openshift-storage
spec:
  targetNamespaces:
  - openshift-storage
EOF
Apply the operator subscription:

# Install the ODF operator
oc apply -f odf-operator-subscription.yaml

# Wait for the operator to be ready
oc get csv -n openshift-storage -w
Subtask 1.3: Configure Multi-Zone Storage Cluster
Create a storage cluster configuration with multi-zone resilience:

# Create file: storage-cluster-multizone.yaml
cat << 'EOF' > storage-cluster-multizone.yaml
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  arbiter: {}
  encryption:
    kms: {}
  externalStorage: {}
  flexibleScaling: true
  resources:
    mds:
      limits:
        cpu: "3"
        memory: "8Gi"
      requests:
        cpu: "1"
        memory: "8Gi"
    mgr:
      limits:
        cpu: "1"
        memory: "3Gi"
      requests:
        cpu: "1"
        memory: "3Gi"
    mon:
      limits:
        cpu: "1"
        memory: "2Gi"
      requests:
        cpu: "1"
        memory: "2Gi"
    noobaa-core:
      limits:
        cpu: "1"
        memory: "4Gi"
      requests:
        cpu: "1"
        memory: "4Gi"
    noobaa-db:
      limits:
        cpu: "1"
        memory: "4Gi"
      requests:
        cpu: "1"
        memory: "4Gi"
  storageDeviceSets:
  - count: 1
    dataPVCTemplate:
      metadata: {}
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: "100Gi"
        storageClassName: gp3-csi
        volumeMode: Block
    name: ocs-deviceset-gp3-csi
    placement:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: cluster.ocs.openshift.io/openshift-storage
              operator: In
              values:
              - ""
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - rook-ceph-osd
            topologyKey: topology.kubernetes.io/zone
          weight: 100
      tolerations:
      - effect: NoSchedule
        key: node.ocs.openshift.io/storage
        operator: Equal
        value: "true"
    portable: true
    replica: 3
    resources:
      limits:
        cpu: "2"
        memory: "5Gi"
      requests:
        cpu: "1"
        memory: "5Gi"
EOF
Label storage nodes for multi-zone deployment:

# Get worker nodes
WORKER_NODES=$(oc get nodes --no-headers -l node-role.kubernetes.io/worker | awk '{print $1}')

# Label nodes for storage (distribute across zones)
for node in $WORKER_NODES; do
  oc label node $node cluster.ocs.openshift.io/openshift-storage=""
  oc label node $node node.ocs.openshift.io/storage=""
done

# Apply taint to storage nodes
for node in $WORKER_NODES; do
  oc adm taint node $node node.ocs.openshift.io/storage=true:NoSchedule
done
Deploy the storage cluster:

# Create the storage cluster
oc apply -f storage-cluster-multizone.yaml

# Monitor the deployment progress
oc get pods -n openshift-storage -w
Subtask 1.4: Verify Multi-Zone Deployment
Validate that the ODF components are distributed across zones:

# Check pod distribution across zones
oc get pods -n openshift-storage -o wide | grep -E "rook-ceph|noobaa"

# Verify storage classes are created
oc get storageclass | grep ocs

# Check Ceph cluster health
oc rsh -n openshift-storage deployment/rook-ceph-tools
ceph status
ceph osd tree
exit
Task 2: Automate Storage Provisioning and Backups Using Ansible
Subtask 2.1: Set Up Ansible Environment
Create the Ansible project structure:

# Create Ansible project directory
mkdir -p ~/odf-automation/{playbooks,roles,inventory,vars}
cd ~/odf-automation

# Create Ansible configuration
cat << 'EOF' > ansible.cfg
[defaults]
inventory = inventory/hosts
host_key_checking = False
remote_user = root
roles_path = roles
stdout_callback = yaml
EOF
Create inventory file:

# Create inventory file
cat << 'EOF' > inventory/hosts
[openshift]
localhost ansible_connection=local

[openshift:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
Subtask 2.2: Create Storage Provisioning Playbook
Create variables file for storage configuration:

# Create file: vars/storage-config.yml
cat << 'EOF' > vars/storage-config.yml
---
# ODF Storage Configuration
odf_namespace: openshift-storage
storage_classes:
  - name: ocs-storagecluster-ceph-rbd
    provisioner: openshift-storage.rbd.csi.ceph.com
    reclaim_policy: Delete
    volume_binding_mode: Immediate
  - name: ocs-storagecluster-cephfs
    provisioner: openshift-storage.cephfs.csi.ceph.com
    reclaim_policy: Delete
    volume_binding_mode: Immediate
  - name: openshift-storage.noobaa.io
    provisioner: openshift-storage.noobaa.io/obc
    reclaim_policy: Delete

# Application storage requirements
applications:
  - name: database-app
    namespace: production
    storage_class: ocs-storagecluster-ceph-rbd
    size: 50Gi
    access_mode: ReadWriteOnce
  - name: shared-storage
    namespace: production
    storage_class: ocs-storagecluster-cephfs
    size: 100Gi
    access_mode: ReadWriteMany
  - name: object-storage
    namespace: production
    storage_class: openshift-storage.noobaa.io
    size: 200Gi

# Backup configuration
backup_schedule: "0 2 * * *"  # Daily at 2 AM
backup_retention: "30d"
backup_location: "/backup/odf"
EOF
Create the main storage provisioning playbook:

# Create file: playbooks/provision-storage.yml
cat << 'EOF' > playbooks/provision-storage.yml
---
- name: Provision ODF Storage Resources
  hosts: openshift
  gather_facts: false
  vars_files:
    - ../vars/storage-config.yml
  
  tasks:
    - name: Create application namespaces
      kubernetes.core.k8s:
        name: "{{ item.namespace }}"
        api_version: v1
        kind: Namespace
        state: present
      loop: "{{ applications }}"
      loop_control:
        label: "{{ item.namespace }}"

    - name: Create PVCs for applications
      kubernetes.core.k8s:
        definition:
          apiVersion: v1
          kind: PersistentVolumeClaim
          metadata:
            name: "{{ item.name }}-pvc"
            namespace: "{{ item.namespace }}"
          spec:
            accessModes:
              - "{{ item.access_mode }}"
            resources:
              requests:
                storage: "{{ item.size }}"
            storageClassName: "{{ item.storage_class }}"
        state: present
      loop: "{{ applications }}"
      loop_control:
        label: "{{ item.name }}"

    - name: Verify PVC status
      kubernetes.core.k8s_info:
        api_version: v1
        kind: PersistentVolumeClaim
        name: "{{ item.name }}-pvc"
        namespace: "{{ item.namespace }}"
      register: pvc_status
      loop: "{{ applications }}"
      loop_control:
        label: "{{ item.name }}"

    - name: Display PVC status
      debug:
        msg: "PVC {{ item.item.name }}-pvc in namespace {{ item.item.namespace }} is {{ item.resources[0].status.phase }}"
      loop: "{{ pvc_status.results }}"
      loop_control:
        label: "{{ item.item.name }}"
EOF
Subtask 2.3: Create Backup Automation Playbook
Create a comprehensive backup playbook:

# Create file: playbooks/backup-storage.yml
cat << 'EOF' > playbooks/backup-storage.yml
---
- name: Backup ODF Storage Resources
  hosts: openshift
  gather_facts: false
  vars_files:
    - ../vars/storage-config.yml
  
  tasks:
    - name: Create backup namespace
      kubernetes.core.k8s:
        name: odf-backup
        api_version: v1
        kind: Namespace
        state: present

    - name: Create backup service account
      kubernetes.core.k8s:
        definition:
          apiVersion: v1
          kind: ServiceAccount
          metadata:
            name: backup-operator
            namespace: odf-backup

    - name: Create backup cluster role
      kubernetes.core.k8s:
        definition:
          apiVersion: rbac.authorization.k8s.io/v1
          kind: ClusterRole
          metadata:
            name: backup-operator
          rules:
          - apiGroups: [""]
            resources: ["persistentvolumes", "persistentvolumeclaims"]
            verbs: ["get", "list", "create", "update", "patch", "delete"]
          - apiGroups: ["snapshot.storage.k8s.io"]
            resources: ["volumesnapshots", "volumesnapshotclasses"]
            verbs: ["get", "list", "create", "update", "patch", "delete"]

    - name: Create backup cluster role binding
      kubernetes.core.k8s:
        definition:
          apiVersion: rbac.authorization.k8s.io/v1
          kind: ClusterRoleBinding
          metadata:
            name: backup-operator
          roleRef:
            apiGroup: rbac.authorization.k8s.io
            kind: ClusterRole
            name: backup-operator
          subjects:
          - kind: ServiceAccount
            name: backup-operator
            namespace: odf-backup

    - name: Create volume snapshot class
      kubernetes.core.k8s:
        definition:
          apiVersion: snapshot.storage.k8s.io/v1
          kind: VolumeSnapshotClass
          metadata:
            name: ocs-storagecluster-rbdplugin-snapclass
          driver: openshift-storage.rbd.csi.ceph.com
          deletionPolicy: Delete

    - name: Create backup CronJob
      kubernetes.core.k8s:
        definition:
          apiVersion: batch/v1
          kind: CronJob
          metadata:
            name: odf-backup-cronjob
            namespace: odf-backup
          spec:
            schedule: "{{ backup_schedule }}"
            jobTemplate:
              spec:
                template:
                  spec:
                    serviceAccountName: backup-operator
                    containers:
                    - name: backup-container
                      image: registry.redhat.io/ubi8/ubi:latest
                      command:
                      - /bin/bash
                      - -c
                      - |
                        # Install oc client
                        curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz | tar xz
                        mv oc /usr/local/bin/
                        
                        # Create snapshots for all PVCs
                        for pvc in $(oc get pvc --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}'); do
                          namespace=$(echo $pvc | awk '{print $1}')
                          pvc_name=$(echo $pvc | awk '{print $2}')
                          snapshot_name="${pvc_name}-snapshot-$(date +%Y%m%d-%H%M%S)"
                          
                          cat <<SNAPSHOT | oc apply -f -
                        apiVersion: snapshot.storage.k8s.io/v1
                        kind: VolumeSnapshot
                        metadata:
                          name: ${snapshot_name}
                          namespace: ${namespace}
                        spec:
                          volumeSnapshotClassName: ocs-storagecluster-rbdplugin-snapclass
                          source:
                            persistentVolumeClaimName: ${pvc_name}
                        SNAPSHOT
                        done
                        
                        # Clean up old snapshots
                        oc get volumesnapshots --all-namespaces -o json | jq -r '.items[] | select(.metadata.creationTimestamp < (now - 30*24*3600 | strftime("%Y-%m-%dT%H:%M:%SZ"))) | "\(.metadata.namespace) \(.metadata.name)"' | while read ns name; do
                          oc delete volumesnapshot $name -n $ns
                        done
                    restartPolicy: OnFailure
            successfulJobsHistoryLimit: 3
            failedJobsHistoryLimit: 1
EOF
Subtask 2.4: Execute Ansible Playbooks
Install required Ansible collections:

# Install Kubernetes collection
ansible-galaxy collection install kubernetes.core

# Install community general collection
ansible-galaxy collection install community.general
Run the storage provisioning playbook:

# Execute storage provisioning
cd ~/odf-automation
ansible-playbook playbooks/provision-storage.yml -v

# Verify PVC creation
oc get pvc --all-namespaces | grep -E "database-app|shared-storage"
Run the backup automation playbook:

# Execute backup setup
ansible-playbook playbooks/backup-storage.yml -v

# Verify backup resources
oc get cronjob -n odf-backup
oc get volumesnapshotclass
Task 3: Set Up Monitoring, Alerting, and Auditing for ODF Storage Resources
Subtask 3.1: Configure ODF Monitoring
Create monitoring configuration for ODF:

# Create file: monitoring-config.yaml
cat << 'EOF' > monitoring-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    enableUserWorkload: true
    prometheusK8s:
      retention: 15d
      volumeClaimTemplate:
        spec:
          storageClassName: ocs-storagecluster-ceph-rbd
          resources:
            requests:
              storage: 40Gi
    alertmanagerMain:
      volumeClaimTemplate:
        spec:
          storageClassName: ocs-storagecluster-ceph-rbd
          resources:
            requests:
              storage: 20Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-workload-monitoring-config
  namespace: openshift-user-workload-monitoring
data:
  config.yaml: |
    prometheus:
      retention: 15d
      volumeClaimTemplate:
        spec:
          storageClassName: ocs-storagecluster-ceph-rbd
          resources:
            requests:
              storage: 20Gi
EOF
Apply monitoring configuration:

# Create user workload monitoring namespace if it doesn't exist
oc create namespace openshift-user-workload-monitoring --dry-run=client -o yaml | oc apply -f -

# Apply monitoring configuration
oc apply -f monitoring-config.yaml

# Wait for monitoring pods to restart
oc get pods -n openshift-monitoring -w
Subtask 3.2: Create Custom ODF Alerts
Create custom alerting rules for ODF:

# Create file: odf-alerts.yaml
cat << 'EOF' > odf-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: odf-storage-alerts
  namespace: openshift-storage
  labels:
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  - name: odf-storage.rules
    rules:
    - alert: CephClusterErrorState
      expr: ceph_health_status == 2
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Ceph cluster is in error state"
        description: "Ceph cluster has been in error state for more than 5 minutes"
    
    - alert: CephClusterWarningState
      expr: ceph_health_status == 1
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Ceph cluster is in warning state"
        description: "Ceph cluster has been in warning state for more than 10 minutes"
    
    - alert: CephOSDDown
      expr: ceph_osd_up == 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Ceph OSD is down"
        description: "Ceph OSD {{ $labels.ceph_daemon }} has been down for more than 5 minutes"
    
    - alert: CephPGDegraded
      expr: ceph_pg_degraded > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Ceph placement groups degraded"
        description: "{{ $value }} Ceph placement groups are degraded"
    
    - alert: PersistentVolumeUsageHigh
      expr: (kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes) * 100 > 85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Persistent Volume usage is high"
        description: "PV {{ $labels.persistentvolumeclaim }} in namespace {{ $labels.namespace }} is {{ $value }}% full"
    
    - alert: PersistentVolumeUsageCritical
      expr: (kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes) * 100 > 95
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Persistent Volume usage is critical"
        description: "PV {{ $labels.persistentvolumeclaim }} in namespace {{ $labels.namespace }} is {{ $value }}% full"
    
    - alert: NooBaaSystemUnhealthy
      expr: NooBaa_system_info{system_phase!="Ready"} == 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "NooBaa system is unhealthy"
        description: "NooBaa system {{ $labels.system_name }} is in {{ $labels.system_phase }} state"
EOF
Apply the alerting rules:

# Apply ODF alerts
oc apply -f odf-alerts.yaml

# Verify alerts are loaded
oc get prometheusrule -n openshift-storage
Subtask 3.3: Configure AlertManager
Create AlertManager configuration for notifications:

# Create file: alertmanager-config.yaml
cat << 'EOF' > alertmanager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-main
  namespace: openshift-monitoring
type: Opaque
stringData:
  alertmanager.yaml: |
    global:
      smtp_smarthost: 'localhost:587'
      smtp_from: 'alerts@company.com'
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
      routes:
      - match:
          alertname: CephClusterErrorState
        receiver: 'critical-alerts'
      - match:
          severity: critical
        receiver: 'critical-alerts'
      - match:
          severity: warning
        receiver: 'warning-alerts'
    
    receivers:
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://webhook-service.monitoring.svc.cluster.local:5001/'
        send_resolved: true
    
    - name: 'critical-alerts'
      email_configs:
      - to: 'admin@company.com'
        subject: 'CRITICAL: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
      webhook_configs:
      - url: 'http://webhook-service.monitoring.svc.cluster.local:5001/critical'
        send_resolved: true
    
    - name: 'warning-alerts'
      email_configs:
      - to: 'team@company.com'
        subject: 'WARNING: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
EOF
Apply AlertManager configuration:

# Apply AlertManager config
oc apply -f alertmanager-config.yaml

# Restart AlertManager to pick up new config
oc delete pod -l app.kubernetes.io/name=alertmanager -n openshift-monitoring
Subtask 3.4: Set Up Grafana Dashboard for ODF
Create a custom Grafana dashboard for ODF monitoring:

# Create file: odf-grafana-dashboard.yaml
cat << 'EOF' > odf-grafana-dashboard.yaml
apiVersion: integreatly.org/v1alpha1
kind: GrafanaDashboard
metadata:
  name: odf-storage-dashboard
  namespace: openshift-storage
  labels:
    app: grafana
spec:
  json: |
    {
      "dashboard": {
        "id": null,
        "title": "ODF Storage Dashboard",
        "tags": ["odf", "storage"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Ceph Cluster Health",
            "type": "stat",
            "targets": [
              {
                "expr": "ceph_health_status",
                "legendFormat": "Health Status"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "mappings": [
                  {
                    "options": {
                      "0": {
                        "text": "OK",
                        "color": "green"
                      },
                      "1": {
                        "text": "WARN",
                        "color": "yellow"
                      },
                      "2": {
                        "text": "ERR",
                        "color": "red"
                      }
                    },
                    "type": "value"
                  }
                ]
              }
            },
            "gridPos": {
              "h": 8,
              "w": 12,
              "x": 0,
              "y": 0
            }
          },
          {
            "id": 2,
            "title": "Storage Utilization",
            "type": "graph",
            "targets": [
              {
                "expr": "ceph_cluster_total_used_bytes / ceph_cluster_total_bytes * 100",
                "legendFormat": "Used %"
              }
            ],
            "yAxes": [
              {
                "max": 100,
                "min": 0,
                "unit": "percent"
              }
            ],
            "gridPos": {
              "h": 8,
              "w": 12,
              "x": 12,
              "y": 0
            }
          },
          {
            "id": 3,
            "title": "OSD Status",
            "type": "table",
            "targets": [
              {
                "expr": "ceph_osd_up",
                "legendFormat": "OSD {{osd}}"
              }
            ],
            "gridPos": {
              "h": 8,
              "w": 24,
              "x": 0,
              "y": 8
            }
          },
          {
            "id": 4,
            "title": "PVC Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes * 100",
                "legendFormat": "{{namespace}}/{{persistentvolumeclaim}}"
              }
            ],
            "yAxes": [
              {
                "max": 100,
                "min": 0,
                "unit": "percent"
              }
            ],
            "gridPos": {
              "h": 8,
              "w": 24,
              "x": 0,
              "y": 16
            }
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
EOF
Subtask 3.5: Implement Audit Logging
Create audit logging configuration for ODF operations:

# Create file: odf-audit-config.yaml
cat << 'EOF' > odf-audit-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: odf-audit-policy
  namespace: openshift-storage
data:
  audit-policy.yaml: |
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    - level: Metadata
      namespaces: ["openshift-storage"]
      resources:
      - group: ""
        resources: ["persistentvolumes", "persistentvolumeclaims"]
      - group: "storage.k8s.io"
        resources: ["storageclasses"]
      - group: "snapshot.storage.k8s.io"
        resources: ["volumesnapshots", "volumesnapshotclasses"]
      - group: "ocs.openshift.io"
        resources: ["storageclusters"]
    - level: Request
      namespaces: ["openshift-storage"]
      resources:
      - group: "ocs.openshift.io"
        resources: ["storageclusters"]
      verbs: ["create", "update", "patch", "delete"]
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: odf-audit-logger
  namespace: openshift-storage
spec:
  selector:
    matchLabels:
      app: odf-audit-logger
  template:
    metadata:
      labels:
        app: odf-audit-logger
    spec:
      serviceAccountName: odf-audit-logger
      containers:
      - name: audit-logger
        image: registry.redhat.io/ubi8/ubi:latest
        command:
        - /bin/bash
        - -c
        - |
          # Install required tools
          yum install -y jq curl
          
          # Monitor ODF events
          while true; do
            oc get events -n openshift-storage --field-selector type=Warning -o json | \
            jq -r '.items[] | "\(.firstTimestamp) \(.reason) \(.message)"' | \
            while read line; do
              echo "$(date): ODF WARNING: $line" >> /var/log/odf-audit.log
            done
            sleep 30
          done
        volumeMounts:
        - name: audit-logs
          mountPath: /var/log
      volumes:
      - name: audit-logs
        hostPath:
          path: /var/log/odf-audit
          type: DirectoryOrCreate
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: odf-audit-logger
  namespace: openshift-storage
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: odf-audit-logger
rules:
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: odf-audit-logger
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Cluster
