Lab 18: Automating ODF Deployment with Ansible
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of automating OpenShift Data Foundation (ODF) deployment using Ansible
Create and execute Ansible playbooks to deploy and configure ODF components
Automate the creation of Persistent Volume Claims (PVCs) and Object Bucket Claims (OBCs)
Implement automated backup and scaling solutions for ODF using Ansible
Integrate Ansible automation with ODF management workflows
Apply best practices for infrastructure as code in storage management
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift Container Platform concepts
Familiarity with Kubernetes storage concepts (PVs, PVCs, StorageClasses)
Basic knowledge of Ansible automation and YAML syntax
Understanding of OpenShift Data Foundation fundamentals
Experience with command-line interface operations
Knowledge of container orchestration principles
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment. No need to build your own VM or install additional software.

Your lab environment includes:

OpenShift Container Platform cluster (4.12+)
Ansible automation platform (2.12+)
Pre-installed OpenShift CLI (oc)
Ansible collections for OpenShift
Sample configuration files and templates
Task 1: Write Ansible Playbooks to Deploy and Configure ODF
Subtask 1.1: Set Up Ansible Environment for ODF
First, let's prepare our Ansible environment with the necessary collections and configurations.

Verify Ansible Installation
ansible --version
ansible-galaxy --version
Install Required Ansible Collections
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.general
ansible-galaxy collection install redhat.openshift
Create Project Directory Structure
mkdir -p ~/odf-ansible-lab
cd ~/odf-ansible-lab
mkdir -p {playbooks,inventory,vars,templates,roles}
Create Ansible Configuration File
cat > ansible.cfg << EOF
[defaults]
inventory = inventory/hosts
host_key_checking = False
stdout_callback = yaml
gathering = explicit
retry_files_enabled = False

[inventory]
enable_plugins = kubernetes.core.k8s
EOF
Subtask 1.2: Create Inventory Configuration
Create Dynamic Inventory for OpenShift
cat > inventory/hosts << EOF
[local]
localhost ansible_connection=local

[openshift:vars]
ansible_connection=local
ansible_python_interpreter=/usr/bin/python3
EOF
Create Variables File for ODF Configuration
cat > vars/odf-config.yml << EOF
---
# ODF Configuration Variables
odf_namespace: openshift-storage
odf_operator_namespace: openshift-storage
odf_subscription_name: odf-operator
odf_channel: stable-4.12
odf_source: redhat-operators

# Storage Configuration
storage_class_name: ocs-storagecluster-ceph-rbd
object_storage_class: ocs-storagecluster-ceph-rgw
storage_cluster_name: ocs-storagecluster

# Node Configuration
storage_nodes:
  - worker-1
  - worker-2
  - worker-3

# Storage Capacity
storage_capacity: 2Ti
replica_count: 3

# Monitoring Configuration
enable_monitoring: true
enable_alerting: true
EOF
Subtask 1.3: Create ODF Deployment Playbook
Create Main ODF Deployment Playbook
cat > playbooks/deploy-odf.yml << EOF
---
- name: Deploy OpenShift Data Foundation
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../vars/odf-config.yml
  
  tasks:
    - name: Create ODF namespace
      kubernetes.core.k8s:
        name: "{{ odf_namespace }}"
        api_version: v1
        kind: Namespace
        state: present
        definition:
          metadata:
            labels:
              openshift.io/cluster-monitoring: "true"

    - name: Create OperatorGroup for ODF
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: operators.coreos.com/v1
          kind: OperatorGroup
          metadata:
            name: openshift-storage-operatorgroup
            namespace: "{{ odf_namespace }}"
          spec:
            targetNamespaces:
              - "{{ odf_namespace }}"

    - name: Create ODF Subscription
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: operators.coreos.com/v1alpha1
          kind: Subscription
          metadata:
            name: "{{ odf_subscription_name }}"
            namespace: "{{ odf_namespace }}"
          spec:
            channel: "{{ odf_channel }}"
            name: odf-operator
            source: "{{ odf_source }}"
            sourceNamespace: openshift-marketplace
            installPlanApproval: Automatic

    - name: Wait for ODF operator to be ready
      kubernetes.core.k8s_info:
        api_version: apps/v1
        kind: Deployment
        name: odf-operator-controller-manager
        namespace: "{{ odf_namespace }}"
        wait: true
        wait_condition:
          type: Available
          status: "True"
        wait_timeout: 600

    - name: Label storage nodes
      kubernetes.core.k8s:
        state: present
        api_version: v1
        kind: Node
        name: "{{ item }}"
        definition:
          metadata:
            labels:
              cluster.ocs.openshift.io/openshift-storage: ""
      loop: "{{ storage_nodes }}"

    - name: Create StorageSystem
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: odf.openshift.io/v1alpha1
          kind: StorageSystem
          metadata:
            name: ocs-storagecluster-storagesystem
            namespace: "{{ odf_namespace }}"
          spec:
            kind: storagecluster.ocs.openshift.io/v1
            name: "{{ storage_cluster_name }}"
            namespace: "{{ odf_namespace }}"

    - name: Create StorageCluster
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: ocs.openshift.io/v1
          kind: StorageCluster
          metadata:
            name: "{{ storage_cluster_name }}"
            namespace: "{{ odf_namespace }}"
          spec:
            arbiter: {}
            encryption:
              kms: {}
            externalStorage: {}
            managedResources:
              cephBlockPools: {}
              cephCluster: {}
              cephFilesystems: {}
              cephObjectStoreUsers: {}
              cephObjectStores: {}
            mirroring: {}
            nodeTopologies: {}
            storageDeviceSets:
              - count: "{{ replica_count }}"
                dataPVCTemplate:
                  metadata: {}
                  spec:
                    accessModes:
                      - ReadWriteOnce
                    resources:
                      requests:
                        storage: "{{ storage_capacity }}"
                    storageClassName: gp3-csi
                    volumeMode: Block
                  status: {}
                name: ocs-deviceset-gp3-csi
                placement: {}
                portable: true
                replica: 1
                resources: {}

    - name: Wait for StorageCluster to be ready
      kubernetes.core.k8s_info:
        api_version: ocs.openshift.io/v1
        kind: StorageCluster
        name: "{{ storage_cluster_name }}"
        namespace: "{{ odf_namespace }}"
        wait: true
        wait_condition:
          type: Available
          status: "True"
        wait_timeout: 1200
EOF
Create ODF Configuration Validation Playbook
cat > playbooks/validate-odf.yml << EOF
---
- name: Validate ODF Deployment
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../vars/odf-config.yml

  tasks:
    - name: Check ODF operator status
      kubernetes.core.k8s_info:
        api_version: apps/v1
        kind: Deployment
        namespace: "{{ odf_namespace }}"
      register: odf_deployments

    - name: Display ODF operator status
      debug:
        msg: "Deployment {{ item.metadata.name }} is {{ item.status.conditions[-1].type }}"
      loop: "{{ odf_deployments.resources }}"
      when: item.status.conditions is defined

    - name: Check StorageCluster status
      kubernetes.core.k8s_info:
        api_version: ocs.openshift.io/v1
        kind: StorageCluster
        name: "{{ storage_cluster_name }}"
        namespace: "{{ odf_namespace }}"
      register: storage_cluster_status

    - name: Display StorageCluster status
      debug:
        msg: "StorageCluster phase: {{ storage_cluster_status.resources[0].status.phase }}"
      when: storage_cluster_status.resources | length > 0

    - name: Check available StorageClasses
      kubernetes.core.k8s_info:
        api_version: storage.k8s.io/v1
        kind: StorageClass
      register: storage_classes

    - name: Display ODF StorageClasses
      debug:
        msg: "Found StorageClass: {{ item.metadata.name }}"
      loop: "{{ storage_classes.resources }}"
      when: "'ocs' in item.metadata.name"
EOF
Subtask 1.4: Execute ODF Deployment
Run the ODF Deployment Playbook
cd ~/odf-ansible-lab
ansible-playbook playbooks/deploy-odf.yml -v
Validate the Deployment
ansible-playbook playbooks/validate-odf.yml
Verify ODF Components Manually
oc get pods -n openshift-storage
oc get storagecluster -n openshift-storage
oc get storageclass | grep ocs
Task 2: Automate PVC and OBC Creation
Subtask 2.1: Create PVC Automation Playbook
Create PVC Templates Directory
mkdir -p templates/storage
Create PVC Template
cat > templates/storage/pvc-template.yml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "{{ pvc_name }}"
  namespace: "{{ pvc_namespace }}"
  labels:
    app: "{{ app_label | default('automated-storage') }}"
spec:
  accessModes:
    - "{{ access_mode | default('ReadWriteOnce') }}"
  resources:
    requests:
      storage: "{{ storage_size }}"
  storageClassName: "{{ storage_class }}"
EOF
Create PVC Automation Playbook
cat > playbooks/create-pvcs.yml << EOF
---
- name: Automate PVC Creation
  hosts: localhost
  gather_facts: false
  vars:
    pvcs_to_create:
      - name: app-data-pvc
        namespace: default
        size: 10Gi
        storage_class: ocs-storagecluster-ceph-rbd
        access_mode: ReadWriteOnce
        app_label: web-app
      - name: database-pvc
        namespace: default
        size: 50Gi
        storage_class: ocs-storagecluster-ceph-rbd
        access_mode: ReadWriteOnce
        app_label: database
      - name: shared-storage-pvc
        namespace: default
        size: 100Gi
        storage_class: ocs-storagecluster-cephfs
        access_mode: ReadWriteMany
        app_label: shared-app

  tasks:
    - name: Create namespace if it doesn't exist
      kubernetes.core.k8s:
        name: "{{ item.namespace }}"
        api_version: v1
        kind: Namespace
        state: present
      loop: "{{ pvcs_to_create }}"
      loop_control:
        label: "{{ item.namespace }}"

    - name: Create PVCs from template
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: PersistentVolumeClaim
          metadata:
            name: "{{ item.name }}"
            namespace: "{{ item.namespace }}"
            labels:
              app: "{{ item.app_label }}"
              created-by: ansible
          spec:
            accessModes:
              - "{{ item.access_mode }}"
            resources:
              requests:
                storage: "{{ item.size }}"
            storageClassName: "{{ item.storage_class }}"
      loop: "{{ pvcs_to_create }}"
      loop_control:
        label: "{{ item.name }}"

    - name: Wait for PVCs to be bound
      kubernetes.core.k8s_info:
        api_version: v1
        kind: PersistentVolumeClaim
        name: "{{ item.name }}"
        namespace: "{{ item.namespace }}"
        wait: true
        wait_condition:
          type: Bound
        wait_timeout: 300
      loop: "{{ pvcs_to_create }}"
      loop_control:
        label: "{{ item.name }}"

    - name: Display PVC status
      kubernetes.core.k8s_info:
        api_version: v1
        kind: PersistentVolumeClaim
        namespace: "{{ item.namespace }}"
        name: "{{ item.name }}"
      register: pvc_status
      loop: "{{ pvcs_to_create }}"
      loop_control:
        label: "{{ item.name }}"

    - name: Show PVC information
      debug:
        msg: "PVC {{ item.resources[0].metadata.name }} is {{ item.resources[0].status.phase }} with {{ item.resources[0].status.capacity.storage | default('pending') }} storage"
      loop: "{{ pvc_status.results }}"
      when: item.resources | length > 0
EOF
Subtask 2.2: Create OBC Automation Playbook
Create OBC Template
cat > templates/storage/obc-template.yml << EOF
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: "{{ obc_name }}"
  namespace: "{{ obc_namespace }}"
  labels:
    app: "{{ app_label | default('automated-object-storage') }}"
spec:
  generateBucketName: "{{ generate_name | default('true') }}"
  storageClassName: "{{ object_storage_class }}"
EOF
Create OBC Automation Playbook
cat > playbooks/create-obcs.yml << EOF
---
- name: Automate OBC Creation
  hosts: localhost
  gather_facts: false
  vars:
    obcs_to_create:
      - name: app-backup-obc
        namespace: default
        storage_class: ocs-storagecluster-ceph-rgw
        app_label: backup-service
        generate_name: true
      - name: media-storage-obc
        namespace: default
        storage_class: ocs-storagecluster-ceph-rgw
        app_label: media-app
        generate_name: true
      - name: log-archive-obc
        namespace: logging
        storage_class: ocs-storagecluster-ceph-rgw
        app_label: log-archiver
        generate_name: true

  tasks:
    - name: Create namespace if it doesn't exist
      kubernetes.core.k8s:
        name: "{{ item.namespace }}"
        api_version: v1
        kind: Namespace
        state: present
      loop: "{{ obcs_to_create }}"
      loop_control:
        label: "{{ item.namespace }}"

    - name: Create OBCs
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: objectbucket.io/v1alpha1
          kind: ObjectBucketClaim
          metadata:
            name: "{{ item.name }}"
            namespace: "{{ item.namespace }}"
            labels:
              app: "{{ item.app_label }}"
              created-by: ansible
          spec:
            generateBucketName: "{{ item.generate_name }}"
            storageClassName: "{{ item.storage_class }}"
      loop: "{{ obcs_to_create }}"
      loop_control:
        label: "{{ item.name }}"

    - name: Wait for OBCs to be bound
      kubernetes.core.k8s_info:
        api_version: objectbucket.io/v1alpha1
        kind: ObjectBucketClaim
        name: "{{ item.name }}"
        namespace: "{{ item.namespace }}"
        wait: true
        wait_condition:
          type: Bound
        wait_timeout: 300
      loop: "{{ obcs_to_create }}"
      loop_control:
        label: "{{ item.name }}"

    - name: Get OBC secrets and configmaps
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Secret
        namespace: "{{ item.namespace }}"
        label_selectors:
          - "bucket-provisioner=openshift-storage.ceph.rook.io-bucket"
      register: obc_secrets
      loop: "{{ obcs_to_create }}"
      loop_control:
        label: "{{ item.namespace }}"

    - name: Display OBC access information
      debug:
        msg: "OBC {{ item.name }} created successfully. Check secrets in namespace {{ item.namespace }}"
      loop: "{{ obcs_to_create }}"
EOF
Subtask 2.3: Execute Storage Automation
Run PVC Creation Playbook
ansible-playbook playbooks/create-pvcs.yml -v
Run OBC Creation Playbook
ansible-playbook playbooks/create-obcs.yml -v
Verify Created Storage Resources
oc get pvc --all-namespaces
oc get obc --all-namespaces
oc get secrets --all-namespaces | grep bucket
Task 3: Integrate Ansible with ODF to Automate Backups and Scaling
Subtask 3.1: Create Backup Automation Playbook
Create Backup Configuration Variables
cat > vars/backup-config.yml << EOF
---
# Backup Configuration
backup_namespace: openshift-adp
backup_storage_location: odf-backup-location
backup_schedule: "0 2 * * *"  # Daily at 2 AM

# Velero Configuration
velero_version: v1.11.0
velero_image: velero/velero:v1.11.0
velero_plugin_image: velero/velero-plugin-for-aws:v1.7.0

# Backup Targets
backup_namespaces:
  - default
  - logging
  - monitoring

# Retention Policy
backup_retention_days: 30
backup_retention_count: 10

# S3 Configuration (using ODF RGW)
s3_bucket_name: velero-backups
s3_region: us-east-1
EOF
Create Backup Automation Playbook
cat > playbooks/setup-backups.yml << EOF
---
- name: Setup Automated Backups with ODF
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../vars/backup-config.yml

  tasks:
    - name: Create backup namespace
      kubernetes.core.k8s:
        name: "{{ backup_namespace }}"
        api_version: v1
        kind: Namespace
        state: present

    - name: Create backup storage OBC
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: objectbucket.io/v1alpha1
          kind: ObjectBucketClaim
          metadata:
            name: backup-storage-obc
            namespace: "{{ backup_namespace }}"
          spec:
            bucketName: "{{ s3_bucket_name }}"
            storageClassName: ocs-storagecluster-ceph-rgw

    - name: Wait for backup OBC to be ready
      kubernetes.core.k8s_info:
        api_version: objectbucket.io/v1alpha1
        kind: ObjectBucketClaim
        name: backup-storage-obc
        namespace: "{{ backup_namespace }}"
        wait: true
        wait_condition:
          type: Bound
        wait_timeout: 300

    - name: Get S3 credentials from secret
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Secret
        name: backup-storage-obc
        namespace: "{{ backup_namespace }}"
      register: s3_credentials

    - name: Create Velero credentials secret
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Secret
          metadata:
            name: cloud-credentials
            namespace: "{{ backup_namespace }}"
          type: Opaque
          data:
            cloud: "{{ ('[default]\naws_access_key_id=' + (s3_credentials.resources[0].data.AWS_ACCESS_KEY_ID | b64decode) + '\naws_secret_access_key=' + (s3_credentials.resources[0].data.AWS_SECRET_ACCESS_KEY | b64decode)) | b64encode }}"

    - name: Install Velero
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: velero
            namespace: "{{ backup_namespace }}"
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: velero
            template:
              metadata:
                labels:
                  app: velero
              spec:
                serviceAccountName: velero
                containers:
                - name: velero
                  image: "{{ velero_image }}"
                  command:
                    - /velero
                  args:
                    - server
                    - --default-backup-storage-location={{ backup_storage_location }}
                  env:
                  - name: AWS_SHARED_CREDENTIALS_FILE
                    value: /credentials/cloud
                  - name: VELERO_NAMESPACE
                    value: "{{ backup_namespace }}"
                  volumeMounts:
                  - name: credentials
                    mountPath: /credentials
                    readOnly: true
                volumes:
                - name: credentials
                  secret:
                    secretName: cloud-credentials

    - name: Create BackupStorageLocation
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: velero.io/v1
          kind: BackupStorageLocation
          metadata:
            name: "{{ backup_storage_location }}"
            namespace: "{{ backup_namespace }}"
          spec:
            provider: aws
            objectStorage:
              bucket: "{{ s3_bucket_name }}"
            config:
              region: "{{ s3_region }}"
              s3ForcePathStyle: "true"
              s3Url: "{{ 'http://' + (s3_credentials.resources[0].data.BUCKET_HOST | b64decode) }}"

    - name: Create scheduled backups
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: velero.io/v1
          kind: Schedule
          metadata:
            name: "daily-backup-{{ item | replace('_', '-') }}"
            namespace: "{{ backup_namespace }}"
          spec:
            schedule: "{{ backup_schedule }}"
            template:
              includedNamespaces:
                - "{{ item }}"
              storageLocation: "{{ backup_storage_location }}"
              ttl: "{{ backup_retention_days * 24 }}h0m0s"
      loop: "{{ backup_namespaces }}"
EOF
Subtask 3.2: Create Scaling Automation Playbook
Create Scaling Configuration Variables
cat > vars/scaling-config.yml << EOF
---
# Scaling Configuration
scaling_thresholds:
  storage_usage_high: 80  # Percentage
  storage_usage_low: 30   # Percentage
  
# Scaling Actions
scale_up_increment: 1
scale_down_decrement: 1
min_replicas: 3
max_replicas: 9

# Monitoring Configuration
prometheus_namespace: openshift-monitoring
alert_manager_namespace: openshift-monitoring

# Storage Device Set Configuration
device_set_name: ocs-deviceset-gp3-csi
device_set_storage_size: 2Ti
EOF
Create Scaling Automation Playbook
cat > playbooks/setup-scaling.yml << EOF
---
- name: Setup Automated Scaling for ODF
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../vars/scaling-config.yml
    - ../vars/odf-config.yml

  tasks:
    - name: Create scaling monitoring ServiceMonitor
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: monitoring.coreos.com/v1
          kind: ServiceMonitor
          metadata:
            name: odf-scaling-monitor
            namespace: "{{ odf_namespace }}"
            labels:
              app: odf-scaling
          spec:
            selector:
              matchLabels:
                app: ceph-mgr
            endpoints:
            - port: http-metrics
              interval: 30s
              path: /metrics

    - name: Create storage usage alert rule
      kubernetes.core.k8s:
        state: present
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
              - alert: ODFStorageUsageHigh
                expr: (ceph_cluster_total_used_bytes / ceph_cluster_total_bytes) * 100 > {{ scaling_thresholds.storage_usage_high }}
                for: 5m
                labels:
                  severity: warning
                  service: odf
                annotations:
                  summary: "ODF storage usage is high"
                  description: "Storage usage is {{ '{{ $value }}' }}% which is above the threshold of {{ scaling_thresholds.storage_usage_high }}%"
              
              - alert: ODFStorageUsageLow
                expr: (ceph_cluster_total_used_bytes / ceph_cluster_total_bytes) * 100 < {{ scaling_thresholds.storage_usage_low }}
                for: 15m
                labels:
                  severity: info
                  service: odf
                annotations:
                  summary: "ODF storage usage is low"
                  description: "Storage usage is {{ '{{ $value }}' }}% which is below the threshold of {{ scaling_thresholds.storage_usage_low }}%"

    - name: Create scaling webhook service
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Service
          metadata:
            name: odf-scaling-webhook
            namespace: "{{ odf_namespace }}"
          spec:
            selector:
              app: odf-scaling-webhook
            ports:
            - port: 8080
              targetPort: 8080
              protocol: TCP

    - name: Create scaling webhook deployment
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: odf-scaling-webhook
            namespace: "{{ odf_namespace }}"
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: odf-scaling-webhook
            template:
              metadata:
                labels:
                  app: odf-scaling-webhook
              spec:
                serviceAccountName: odf-scaling-sa
                containers:
                - name: webhook
                  image: quay.io/openshift/origin-cli:latest
                  command: ["/bin/bash"]
                  args:
                    - -c
                    - |
                      while true; do
                        echo "Scaling webhook listening on port 8080"
                        nc -l -p 8080 -e /bin/bash -c '
                          echo "HTTP/1.1 200 OK"
                          echo "Content-Type: application/json"
                          echo ""
                          echo "{\"status\": \"received\"}"
                          
                          # Get current storage cluster
                          CURRENT_COUNT=$(oc get storagecluster {{ storage_cluster_name }} -n {{ odf_namespace }} -o jsonpath="{.spec.storageDeviceSets[0].count}")
                          
                          # Scale up logic (simplified)
                          if [[ "$REQUEST_METHOD" == "POST" ]]; then
                            NEW_COUNT=$((CURRENT_COUNT + {{ scale_up_increment }}))
                            if [[ $NEW_COUNT -le {{ max_replicas }} ]]; then
                              oc patch storagecluster {{ storage_cluster_name }} -n {{ odf_namespace }} --type merge -p "{\"spec\":{\"storageDeviceSets\":[{\"name\":\"{{ device_set_name }}\",\"count\":$NEW_COUNT}]}}"
                            fi
                          fi
                        '
                      done
                  ports:
                  - containerPort: 8080

    - name: Create ServiceAccount for scaling
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: ServiceAccount
          metadata:
            name: odf-scaling-sa
            namespace: "{{ odf_namespace }}"

    - name: Create ClusterRole for scaling
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: rbac.authorization.k8s.io/v1
          kind: ClusterRole
          metadata:
            name: odf-scaling-role
          rules:
          - apiGroups: ["ocs.openshift.io"]
            resources: ["storageclusters"]
            verbs: ["get", "list", "patch", "update"]
          - apiGroups: [""]
            resources: ["nodes"]
            verbs: ["get", "list"]

    - name: Create ClusterRoleBinding for scaling
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: rbac.authorization.k8s.io/v1
          kind: ClusterRoleBinding
          metadata:
            name: odf-scaling-binding
          roleRef:
            apiGroup: rbac.authorization.k8s.io
            kind: ClusterRole
            name: odf-scaling-role
          subjects:
          - kind: ServiceAccount
            name: odf-scaling-sa
            namespace: "{{ odf_namespace }}"
EOF
Subtask 3.3: Create Comprehensive Management Playbook
Create Management Operations Playbook
cat > playbooks/manage-odf.yml << EOF
---
- name: Comprehensive ODF Management
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../vars/odf-config.yml
    - ../vars/backup-config.yml
    - ../vars/scaling-config.yml

  tasks:
    - name: Check ODF cluster health
      kubernetes.core.k8s_info:
        api_version: ocs.
