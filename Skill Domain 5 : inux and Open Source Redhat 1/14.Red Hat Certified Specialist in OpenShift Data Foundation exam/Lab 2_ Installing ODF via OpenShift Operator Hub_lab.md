Lab 2: Installing ODF via OpenShift Operator Hub
Objectives
By the end of this lab, you will be able to:

Install OpenShift Data Foundation (ODF) operator using the OpenShift Operator Hub
Validate cluster prerequisites including CPU, memory, and disk requirements
Create and configure ODF storage classes for persistent storage
Understand the architecture and components of OpenShift Data Foundation
Verify successful ODF installation and functionality
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift Container Platform concepts
Familiarity with Kubernetes storage concepts (PVs, PVCs, Storage Classes)
Knowledge of OpenShift web console navigation
Understanding of Linux command line operations
Completed Lab 1 or equivalent OpenShift cluster access
Required Knowledge Areas
OpenShift Operators and Operator Lifecycle Manager (OLM)
Kubernetes storage architecture
Basic YAML configuration
OpenShift CLI (oc) commands
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift cluster access. Simply click Start Lab to begin - no need to build your own virtual machines or configure infrastructure.

Environment Specifications
OpenShift Container Platform 4.12 or later
Minimum 3 worker nodes
Each worker node: 16 vCPUs, 64GB RAM, 100GB+ available storage
Cluster administrator privileges
Internet connectivity for Operator Hub access
Task 1: Validate Cluster Prerequisites
Subtask 1.1: Check Cluster Node Resources
Before installing ODF, we need to ensure our cluster meets the minimum requirements.

Access the OpenShift CLI

Open your terminal and verify cluster connectivity:

oc whoami
oc cluster-info
Check Node Resources

Examine CPU and memory resources across all nodes:

oc get nodes -o wide
oc describe nodes | grep -E "Name:|cpu:|memory:"
Verify Worker Node Count

ODF requires at least 3 worker nodes for proper operation:

oc get nodes --selector='node-role.kubernetes.io/worker' --no-headers | wc -l
Expected output should show 3 or more worker nodes.

Subtask 1.2: Check Available Storage
Examine Node Storage Capacity

Check available disk space on each worker node:

for node in $(oc get nodes --selector='node-role.kubernetes.io/worker' -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== Node: $node ==="
  oc debug node/$node -- chroot /host df -h /
done
Verify Local Storage Availability

Check for additional block devices that can be used for ODF:

for node in $(oc get nodes --selector='node-role.kubernetes.io/worker' -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== Node: $node ==="
  oc debug node/$node -- chroot /host lsblk
done
Subtask 1.3: Validate Network Requirements
Check Cluster Network Configuration

Verify the cluster network is properly configured:

oc get network.config/cluster -o yaml
Verify DNS Resolution

Test internal DNS resolution:

oc run dns-test --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local
Task 2: Install ODF Operator via OpenShift Operator Hub
Subtask 2.1: Access OpenShift Web Console
Login to OpenShift Web Console

Open your web browser
Navigate to your OpenShift cluster console URL
Login with your cluster administrator credentials
Navigate to Operator Hub

Click on Operators in the left navigation menu
Select OperatorHub
You should see the Operator catalog with various operators available
Subtask 2.2: Search and Install ODF Operator
Search for OpenShift Data Foundation

In the OperatorHub search box, type: OpenShift Data Foundation
Click on the OpenShift Data Foundation operator tile
Review the operator description and supported features
Install the Operator

Click Install button
Configure installation settings:
Update Channel: Select stable-4.12 (or latest stable)
Installation Mode: Select All namespaces on the cluster
Installed Namespace: Select openshift-storage
Update Approval: Select Automatic
Confirm Installation

Click Install to begin the installation process
Wait for the installation to complete (typically 2-3 minutes)
Subtask 2.3: Verify Operator Installation
Check Operator Status via Web Console

Navigate to Operators → Installed Operators
Verify OpenShift Data Foundation appears with status Succeeded
Note the installed version and namespace
Verify Installation via CLI

oc get csv -n openshift-storage
oc get pods -n openshift-storage
Expected output should show ODF operator pods in Running state.

Check Operator Capabilities

oc get crd | grep -i odf
oc get crd | grep -i ceph
oc get crd | grep -i nooba
Task 3: Create ODF Storage System
Subtask 3.1: Create Storage System via Web Console
Navigate to ODF Console

In the OpenShift web console, go to Operators → Installed Operators
Click on OpenShift Data Foundation
Click Create StorageSystem under Storage System
Configure Storage System

Deployment Type: Select Internal - Attached devices
Node Selection: Choose worker nodes (minimum 3 nodes)
Storage Class: Select available storage class or create new one
Storage Capacity: Allocate minimum 100GB per node
Advanced Configuration

Encryption: Enable if required for your environment
Network: Use default cluster network
Resource Requirements: Use default settings for lab environment
Subtask 3.2: Alternative CLI-Based Installation
If you prefer CLI installation, create the following configuration:

Create Storage System YAML

cat << EOF > odf-storagesystem.yaml
apiVersion: odf.openshift.io/v1alpha1
kind: StorageSystem
metadata:
  name: ocs-storagecluster-storagesystem
  namespace: openshift-storage
spec:
  kind: storagecluster.ocs.openshift.io/v1
  name: ocs-storagecluster
  namespace: openshift-storage
EOF
Create Storage Cluster Configuration

cat << EOF > odf-storagecluster.yaml
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
  managedResources:
    cephBlockPools: {}
    cephConfig: {}
    cephDashboard: {}
    cephFilesystems: {}
    cephObjectStoreUsers: {}
    cephObjectStores: {}
  mirroring: {}
  nodeTopologies: {}
  storageDeviceSets:
  - count: 1
    dataPVCTemplate:
      metadata: {}
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi
        storageClassName: gp3-csi
        volumeMode: Block
      status: {}
    name: ocs-deviceset-gp3-csi
    placement: {}
    portable: true
    replica: 3
    resources: {}
EOF
Apply Configuration

oc apply -f odf-storagesystem.yaml
oc apply -f odf-storagecluster.yaml
Subtask 3.3: Monitor Installation Progress
Watch Pod Creation

watch oc get pods -n openshift-storage
Wait for all pods to reach Running or Completed state. This process typically takes 10-15 minutes.

Check Storage Cluster Status

oc get storagecluster -n openshift-storage
oc describe storagecluster ocs-storagecluster -n openshift-storage
Verify Ceph Cluster Health

oc get cephcluster -n openshift-storage
Task 4: Create and Validate ODF Storage Classes
Subtask 4.1: Examine Default Storage Classes
List Available Storage Classes

oc get storageclass
You should see several new storage classes created by ODF:

ocs-storagecluster-ceph-rbd - Block storage
ocs-storagecluster-cephfs - File storage
ocs-storagecluster-ceph-rgw - Object storage
Examine Storage Class Details

oc describe storageclass ocs-storagecluster-ceph-rbd
oc describe storageclass ocs-storagecluster-cephfs
Subtask 4.2: Create Custom Storage Classes
Create High-Performance Block Storage Class

cat << EOF > custom-rbd-storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-storagecluster-ceph-rbd-fast
provisioner: openshift-storage.rbd.csi.ceph.com
parameters:
  clusterID: openshift-storage
  pool: ocs-storagecluster-cephblockpool
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-storage
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-storage
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: openshift-storage
  csi.storage.k8s.io/fstype: ext4
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF
Apply Custom Storage Class

oc apply -f custom-rbd-storageclass.yaml
Verify Storage Class Creation

oc get storageclass ocs-storagecluster-ceph-rbd-fast
Subtask 4.3: Test Storage Classes
Create Test PVC for Block Storage

cat << EOF > test-rbd-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-rbd-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Create Test PVC for File Storage

cat << EOF > test-cephfs-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-cephfs-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: ocs-storagecluster-cephfs
EOF
Apply Test PVCs

oc apply -f test-rbd-pvc.yaml
oc apply -f test-cephfs-pvc.yaml
Verify PVC Status

oc get pvc -n default
Both PVCs should show Bound status.

Create Test Pods to Use Storage

cat << EOF > test-storage-pods.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-rbd-pod
  namespace: default
spec:
  containers:
  - name: test-container
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo $(date) >> /mnt/test-file; sleep 30; done"]
    volumeMounts:
    - name: test-volume
      mountPath: /mnt
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: test-rbd-pvc
---
apiVersion: v1
kind: Pod
metadata:
  name: test-cephfs-pod
  namespace: default
spec:
  containers:
  - name: test-container
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo $(date) >> /mnt/test-file; sleep 30; done"]
    volumeMounts:
    - name: test-volume
      mountPath: /mnt
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: test-cephfs-pvc
EOF
Deploy Test Pods

oc apply -f test-storage-pods.yaml
Verify Pod Status and Storage Access

oc get pods -n default
oc exec test-rbd-pod -- ls -la /mnt
oc exec test-cephfs-pod -- ls -la /mnt
Task 5: Validate ODF Installation and Configuration
Subtask 5.1: Check ODF Dashboard
Access Ceph Dashboard

oc get route -n openshift-storage | grep dashboard
Get Dashboard Credentials

oc get secret rook-ceph-dashboard-password -n openshift-storage -o jsonpath="{['data']['password']}" | base64 --decode
Verify Dashboard Access

Open the dashboard URL in your browser
Login with username: admin and the decoded password
Verify cluster health status shows HEALTH_OK
Subtask 5.2: Validate Storage System Health
Check Overall Cluster Health

oc get storagecluster -n openshift-storage -o yaml
Verify Ceph Status

oc rsh -n openshift-storage deployment/rook-ceph-tools
ceph status
ceph osd status
ceph df
exit
Check Storage System Metrics

oc get cephcluster -n openshift-storage -o jsonpath='{.items[0].status.ceph.health}'
Subtask 5.3: Performance and Capacity Validation
Check Storage Utilization

oc get pv | grep ocs-storagecluster
Verify Storage Pool Status

oc get cephblockpool -n openshift-storage
oc get cephfilesystem -n openshift-storage
Test Storage Performance

Create a performance test pod:

cat << EOF > storage-performance-test.yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-perf-test
  namespace: default
spec:
  containers:
  - name: fio-test
    image: quay.io/openshift/origin-tests:latest
    command: ["/bin/bash"]
    args: ["-c", "fio --name=test --ioengine=libaio --rw=randwrite --bs=4k --size=1G --numjobs=1 --runtime=60 --group_reporting --filename=/mnt/testfile"]
    volumeMounts:
    - name: test-volume
      mountPath: /mnt
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: test-rbd-pvc
  restartPolicy: Never
EOF
oc apply -f storage-performance-test.yaml
oc logs storage-perf-test
Troubleshooting Common Issues
Issue 1: Operator Installation Fails
Symptoms: Operator shows Failed status in web console

Solution:

oc get csv -n openshift-storage
oc describe csv <csv-name> -n openshift-storage
oc delete csv <csv-name> -n openshift-storage
# Reinstall operator via web console
Issue 2: Storage Cluster Not Ready
Symptoms: StorageCluster shows Progressing status for extended time

Solution:

oc get events -n openshift-storage --sort-by='.lastTimestamp'
oc logs -n openshift-storage -l app=rook-ceph-operator
Issue 3: PVCs Stuck in Pending State
Symptoms: PVCs remain in Pending status

Solution:

oc describe pvc <pvc-name>
oc get storageclass
oc get nodes --show-labels
Issue 4: Insufficient Resources
Symptoms: Pods fail to schedule due to resource constraints

Solution:

oc describe nodes
oc get pods -n openshift-storage -o wide
# Scale down non-essential workloads or add more nodes
Cleanup (Optional)
If you need to clean up the test resources:

oc delete pod test-rbd-pod test-cephfs-pod storage-perf-test -n default
oc delete pvc test-rbd-pvc test-cephfs-pvc -n default
oc delete storageclass ocs-storagecluster-ceph-rbd-fast
Conclusion
Congratulations! You have successfully completed Lab 2: Installing ODF via OpenShift Operator Hub. In this lab, you accomplished the following:

Key Achievements
Validated Cluster Prerequisites: You learned how to check CPU, memory, and disk requirements for ODF installation, ensuring your cluster meets the minimum specifications for reliable operation.

Installed ODF Operator: You successfully installed the OpenShift Data Foundation operator using the OpenShift Operator Hub, understanding both web console and CLI-based approaches.

Created Storage System: You configured and deployed a complete ODF storage system with Ceph backend, providing block, file, and object storage capabilities.

Configured Storage Classes: You created and tested multiple storage classes, understanding the differences between block storage (RBD) and file storage (CephFS) options.

Validated Installation: You performed comprehensive testing to ensure the ODF installation is working correctly, including performance testing and health monitoring.

Why This Matters
OpenShift Data Foundation provides enterprise-grade persistent storage for containerized applications. The skills you've learned in this lab are essential for:

Production Deployments: Understanding how to properly install and configure persistent storage for production OpenShift clusters
Storage Management: Managing different types of storage requirements for various application workloads
Troubleshooting: Identifying and resolving common storage-related issues in OpenShift environments
Performance Optimization: Configuring storage classes and parameters for optimal application performance
Next Steps
With ODF successfully installed and configured, you're now ready to:

Deploy stateful applications that require persistent storage
Configure backup and disaster recovery solutions
Implement storage monitoring and alerting
Explore advanced ODF features like encryption and multi-site replication
This foundation in OpenShift Data Foundation installation and configuration is crucial for the Red Hat Certified Specialist in OpenShift Data Foundation exam and real-world OpenShift storage management scenarios.
