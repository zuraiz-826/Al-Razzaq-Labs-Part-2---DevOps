Lab 18: Managing Cloud-Integrated Ceph Storage
Objectives
By the end of this lab, students will be able to:

Set up and configure Ceph storage pools optimized for cloud environments
Integrate Ceph with cloud-based orchestration platforms like Kubernetes
Implement multi-tenancy and scalability features for cloud-native applications
Configure RADOS Block Device (RBD) and CephFS for cloud workloads
Monitor and optimize Ceph performance in cloud environments
Implement security and access controls for multi-tenant cloud storage
Prerequisites
Before starting this lab, students should have:

Basic understanding of distributed storage systems
Familiarity with Linux command line operations
Knowledge of containerization concepts (Docker, Kubernetes)
Understanding of cloud computing fundamentals
Experience with YAML configuration files
Basic networking concepts (IP addressing, ports, protocols)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own VM or install software - everything is ready to use.

Your lab environment includes:

3 Ubuntu 22.04 LTS nodes (ceph-node1, ceph-node2, ceph-node3)
1 Kubernetes master node (k8s-master)
1 Kubernetes worker node (k8s-worker)
Pre-installed Ceph Octopus release
Pre-configured Kubernetes cluster
All necessary networking and storage devices
Task 1: Set up and Configure Ceph Pools for Cloud Use
Subtask 1.1: Initialize Ceph Cluster for Cloud Environment
First, let's verify and configure our Ceph cluster for cloud integration.

Connect to the primary Ceph node:
ssh ceph-node1
Check Ceph cluster status:
sudo ceph status
sudo ceph health
Verify OSD (Object Storage Daemon) status:
sudo ceph osd status
sudo ceph osd tree
Create a configuration file for cloud-optimized settings:
sudo nano /etc/ceph/ceph.conf
Add the following cloud-optimized configurations:

[global]
fsid = your-cluster-fsid
mon_initial_members = ceph-node1, ceph-node2, ceph-node3
mon_host = 10.0.1.10, 10.0.1.11, 10.0.1.12
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx

# Cloud optimization settings
osd_pool_default_size = 3
osd_pool_default_min_size = 2
osd_pool_default_pg_num = 128
osd_pool_default_pgp_num = 128

# Performance tuning for cloud workloads
osd_max_write_size = 512
osd_client_message_size_cap = 2147483648
osd_deep_scrub_interval = 2419200
osd_scrub_max_interval = 604800

# Network optimization
ms_bind_ipv6 = false
public_network = 10.0.1.0/24
cluster_network = 10.0.2.0/24
Subtask 1.2: Create Cloud-Specific Storage Pools
Create a pool for block storage (RBD):
sudo ceph osd pool create rbd-cloud 128 128
sudo ceph osd pool application enable rbd-cloud rbd
Create a pool for object storage:
sudo ceph osd pool create rgw-cloud 64 64
sudo ceph osd pool application enable rgw-cloud rgw
Create a pool for file system metadata:
sudo ceph osd pool create cephfs-metadata-cloud 32 32
sudo ceph osd pool application enable cephfs-metadata-cloud cephfs
Create a pool for file system data:
sudo ceph osd pool create cephfs-data-cloud 128 128
sudo ceph osd pool application enable cephfs-data-cloud cephfs
Configure pool quotas for multi-tenancy:
# Set maximum objects per pool
sudo ceph osd pool set-quota rbd-cloud max_objects 1000000

# Set maximum bytes per pool (100GB)
sudo ceph osd pool set-quota rbd-cloud max_bytes 107374182400
Subtask 1.3: Configure Multi-Tenant Access Controls
Create client keys for different tenants:
# Create tenant-specific client keys
sudo ceph auth get-or-create client.tenant1 mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=rbd-cloud'
sudo ceph auth get-or-create client.tenant2 mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=rbd-cloud'
Export client keyrings:
sudo ceph auth get client.tenant1 -o /etc/ceph/ceph.client.tenant1.keyring
sudo ceph auth get client.tenant2 -o /etc/ceph/ceph.client.tenant2.keyring
Create namespace isolation within pools:
# Create RBD namespaces for tenant isolation
sudo rbd namespace create rbd-cloud/tenant1
sudo rbd namespace create rbd-cloud/tenant2
Task 2: Integrate with Cloud-Based Orchestration Platforms
Subtask 2.1: Install and Configure Rook-Ceph Operator
Switch to Kubernetes master node:
ssh k8s-master
Clone Rook repository:
git clone --single-branch --branch v1.12.0 https://github.com/rook/rook.git
cd rook/deploy/examples
Deploy Rook operator:
kubectl create -f crds.yaml
kubectl create -f common.yaml
kubectl create -f operator.yaml
Verify operator deployment:
kubectl -n rook-ceph get pods
Subtask 2.2: Create Ceph Cluster in Kubernetes
Create cluster configuration file:
nano cluster-cloud.yaml
Add the following configuration:

apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph-cloud
  namespace: rook-ceph
spec:
  cephVersion:
    image: quay.io/ceph/ceph:v17.2.6
    allowUnsupported: false
  dataDirHostPath: /var/lib/rook
  skipUpgradeChecks: false
  continueUpgradeAfterChecksEvenIfNotHealthy: false
  waitTimeoutForHealthyOSDInMinutes: 10
  mon:
    count: 3
    allowMultiplePerNode: false
  mgr:
    count: 2
    allowMultiplePerNode: false
  dashboard:
    enabled: true
    ssl: true
  monitoring:
    enabled: false
  network:
    connections:
      encryption:
        enabled: false
      compression:
        enabled: false
  crashCollector:
    disable: false
  logCollector:
    enabled: true
    periodicity: daily
    maxLogSize: 500M
  cleanupPolicy:
    confirmation: ""
    sanitizeDisks:
      method: quick
      dataSource: zero
      iteration: 1
  annotations:
  labels:
  placement:
  resources:
  removeOSDsIfOutAndSafeToRemove: false
  storage:
    useAllNodes: true
    useAllDevices: true
    config:
      osdsPerDevice: "1"
  disruptionManagement:
    managePodBudgets: true
    osdMaintenanceTimeout: 30
    pgHealthCheckTimeout: 0
  healthCheck:
    daemonHealth:
      mon:
        disabled: false
        interval: 45s
      osd:
        disabled: false
        interval: 60s
      status:
        disabled: false
        interval: 60s
    livenessProbe:
      mon:
        disabled: false
      mgr:
        disabled: false
      osd:
        disabled: false
Deploy the cluster:
kubectl create -f cluster-cloud.yaml
Monitor cluster deployment:
kubectl -n rook-ceph get pods -w
Subtask 2.3: Configure Storage Classes for Cloud Applications
Create RBD storage class:
nano storageclass-rbd-cloud.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-ceph-block-cloud
provisioner: rook-ceph.rbd.csi.ceph.com
parameters:
  clusterID: rook-ceph-cloud
  pool: replicapool
  imageFormat: "2"
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
  csi.storage.k8s.io/fstype: ext4
allowVolumeExpansion: true
reclaimPolicy: Delete
Create CephFS storage class:
nano storageclass-cephfs-cloud.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-cephfs-cloud
provisioner: rook-ceph.cephfs.csi.ceph.com
parameters:
  clusterID: rook-ceph-cloud
  fsName: myfs
  pool: myfs-replicated
  rootPath: /
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-cephfs-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-cephfs-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-cephfs-node
  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
allowVolumeExpansion: true
reclaimPolicy: Delete
Apply storage classes:
kubectl create -f storageclass-rbd-cloud.yaml
kubectl create -f storageclass-cephfs-cloud.yaml
Verify storage classes:
kubectl get storageclass
Task 3: Optimize Storage for Cloud-Native Applications
Subtask 3.1: Deploy Sample Cloud-Native Applications
Create a stateful application using RBD storage:
nano mysql-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-cloud
spec:
  serviceName: mysql-cloud
  replicas: 3
  selector:
    matchLabels:
      app: mysql-cloud
  template:
    metadata:
      labels:
        app: mysql-cloud
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "cloudpassword123"
        - name: MYSQL_DATABASE
          value: "cloudapp"
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
  volumeClaimTemplates:
  - metadata:
      name: mysql-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: rook-ceph-block-cloud
      resources:
        requests:
          storage: 10Gi
Deploy the StatefulSet:
kubectl create -f mysql-statefulset.yaml
Create a service for MySQL:
nano mysql-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-cloud
spec:
  ports:
  - port: 3306
  selector:
    app: mysql-cloud
  clusterIP: None
kubectl create -f mysql-service.yaml
Subtask 3.2: Configure Shared Storage for Multi-Pod Applications
Create CephFS filesystem:
nano filesystem-cloud.yaml
apiVersion: ceph.rook.io/v1
kind: CephFilesystem
metadata:
  name: myfs-cloud
  namespace: rook-ceph
spec:
  metadataPool:
    replicated:
      size: 3
  dataPools:
  - name: replicated
    replicated:
      size: 3
  preserveFilesystemOnDelete: true
  metadataServer:
    activeCount: 1
    activeStandby: true
    resources:
      limits:
        cpu: "2000m"
        memory: "4Gi"
      requests:
        cpu: "1000m"
        memory: "4Gi"
    priorityClassName: system-cluster-critical
kubectl create -f filesystem-cloud.yaml
Create a shared storage application:
nano shared-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shared-storage-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shared-storage-app
  template:
    metadata:
      labels:
        app: shared-storage-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: shared-storage
          mountPath: /usr/share/nginx/html
        command: ["/bin/sh"]
        args: ["-c", "echo 'Pod: '$(hostname)' - '$(date) > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
      volumes:
      - name: shared-storage
        persistentVolumeClaim:
          claimName: shared-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: rook-cephfs-cloud
kubectl create -f shared-app.yaml
Subtask 3.3: Implement Performance Monitoring and Optimization
Enable Ceph dashboard access:
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
Create port-forward to access dashboard:
kubectl -n rook-ceph port-forward service/rook-ceph-mgr-dashboard 7000:7000 &
Create monitoring script for storage performance:
nano monitor-ceph-performance.sh
#!/bin/bash

echo "=== Ceph Cluster Health ==="
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph status

echo -e "\n=== Pool Statistics ==="
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph df

echo -e "\n=== OSD Performance ==="
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd perf

echo -e "\n=== PG Statistics ==="
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph pg stat

echo -e "\n=== Storage Utilization ==="
kubectl get pv
kubectl get pvc --all-namespaces

echo -e "\n=== Pod Storage Usage ==="
kubectl top pods --all-namespaces --containers
chmod +x monitor-ceph-performance.sh
./monitor-ceph-performance.sh
Configure automatic pool scaling:
nano pool-autoscaler.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pool-autoscaler-config
  namespace: rook-ceph
data:
  config.yaml: |
    pools:
      - name: replicapool
        target_ratio: 0.8
        min_pg_num: 32
        max_pg_num: 512
        scale_factor: 2
    monitoring:
      interval: 300
      threshold: 0.85
kubectl create -f pool-autoscaler.yaml
Subtask 3.4: Implement Backup and Disaster Recovery
Create snapshot class for RBD volumes:
nano volumesnapshotclass-rbd.yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-rbdplugin-snapclass
driver: rook-ceph.rbd.csi.ceph.com
deletionPolicy: Delete
parameters:
  clusterID: rook-ceph-cloud
  csi.storage.k8s.io/snapshotter-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/snapshotter-secret-namespace: rook-ceph
kubectl create -f volumesnapshotclass-rbd.yaml
Create a volume snapshot:
nano volume-snapshot.yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: mysql-snapshot-1
spec:
  volumeSnapshotClassName: csi-rbdplugin-snapclass
  source:
    persistentVolumeClaimName: mysql-storage-mysql-cloud-0
kubectl create -f volume-snapshot.yaml
Create backup script for Ceph configuration:
nano backup-ceph-config.sh
#!/bin/bash

BACKUP_DIR="/tmp/ceph-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Creating Ceph configuration backup..."

# Backup cluster configuration
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph config dump > $BACKUP_DIR/ceph-config.txt

# Backup auth keys
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph auth list > $BACKUP_DIR/ceph-auth.txt

# Backup pool information
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd pool ls detail > $BACKUP_DIR/ceph-pools.txt

# Backup Kubernetes resources
kubectl get cephcluster -n rook-ceph -o yaml > $BACKUP_DIR/cephcluster.yaml
kubectl get cephfilesystem -n rook-ceph -o yaml > $BACKUP_DIR/cephfilesystem.yaml
kubectl get storageclass -o yaml > $BACKUP_DIR/storageclasses.yaml

echo "Backup completed in: $BACKUP_DIR"
tar -czf $BACKUP_DIR.tar.gz -C /tmp $(basename $BACKUP_DIR)
echo "Compressed backup: $BACKUP_DIR.tar.gz"
chmod +x backup-ceph-config.sh
./backup-ceph-config.sh
Verification and Testing
Test 1: Verify Multi-Tenant Storage Access
Test tenant isolation:
# Create test images in different namespaces
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- rbd create --size 1G replicapool/tenant1/test-image1
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- rbd create --size 1G replicapool/tenant2/test-image2

# List images per namespace
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- rbd ls replicapool/tenant1
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- rbd ls replicapool/tenant2
Test 2: Verify Application Storage Performance
Run storage performance test:
nano storage-performance-test.yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-test
spec:
  containers:
  - name: storage-test
    image: ubuntu:20.04
    command: ["/bin/bash"]
    args: ["-c", "apt update && apt install -y fio && fio --name=test --ioengine=libaio --rw=randwrite --bs=4k --size=1G --numjobs=4 --runtime=60 --group_reporting --filename=/data/testfile"]
    volumeMounts:
    - name: test-storage
      mountPath: /data
  volumes:
  - name: test-storage
    persistentVolumeClaim:
      claimName: test-pvc
  restartPolicy: Never
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: rook-ceph-block-cloud
kubectl create -f storage-performance-test.yaml
kubectl logs storage-test -f
Test 3: Verify Snapshot and Recovery
Test snapshot restoration:
nano restore-from-snapshot.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-restore-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: rook-ceph-block-cloud
  dataSource:
    name: mysql-snapshot-1
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
kubectl create -f restore-from-snapshot.yaml
kubectl get pvc mysql-restore-pvc
Troubleshooting Common Issues
Issue 1: Pods Stuck in Pending State
Symptoms: Pods with PVCs remain in Pending state

Solution:

# Check storage class availability
kubectl get storageclass

# Check PVC status
kubectl describe pvc <pvc-name>

# Check Ceph cluster health
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph status

# Check CSI driver pods
kubectl -n rook-ceph get pods | grep csi
Issue 2: Poor Storage Performance
Symptoms: Slow I/O operations, high latency

Solution:

# Check OSD performance
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd perf

# Check network latency between nodes
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd perf

# Optimize pool settings
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd pool set replicapool size 2
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd pool set replicapool min_size 1
Issue 3: Snapshot Creation Failures
Symptoms: VolumeSnapshot objects fail to create

Solution:

# Check snapshot controller
kubectl get pods -n kube-system | grep snapshot

# Verify snapshot class
kubectl describe volumesnapshotclass csi-rbdplugin-snapclass

# Check CSI snapshotter logs
kubectl -n rook-ceph logs -l app=csi-rbdplugin | grep snapshot
Performance Optimization Tips
CPU and Memory Optimization
Optimize OSD resource allocation:
# Edit cluster configuration
kubectl -n rook-ceph edit cephcluster rook-ceph-cloud
Add resource limits:

spec:
  storage:
    config:
      osdsPerDevice: "1"
    nodes:
    - name: "node1"
      resources:
        limits:
          cpu: "2"
          memory: "4Gi"
        requests:
          cpu: "1"
          memory: "2Gi"
Network Optimization
Configure network settings for better performance:
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph config set osd osd_max_write_size 512
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph config set osd osd_client_message_size_cap 2147483648
Security Best Practices
Access Control Configuration
Implement RBAC for Ceph resources:
nano ceph-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ceph-storage-admin
rules:
- apiGroups: [""]
  resources: ["persistentvolumes", "persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["snapshot.storage.k8s.io"]
  resources: ["volumesnapshots", "volumesnapshotclasses"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ceph-storage-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ceph-storage-admin
subjects:
- kind: User
  name: storage-admin
  apiGroup: rbac.authorization.k8s.io
kubectl create -f ceph-rbac.yaml
Encryption Configuration
Enable encryption at rest:
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph config set osd osd_dmcrypt_key_size 512
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph config set osd osd_dmcrypt_type luks2
Conclusion
In this comprehensive lab, you have successfully:

Configured Ceph storage pools optimized for cloud environments with proper multi-tenancy and resource quotas
Integrated Ceph with Kubernetes using the Rook operator, enabling seamless orchestration of storage resources
Deployed cloud-native applications that leverage both block storage (RBD) and shared file storage (CephFS)
Implemented performance monitoring and optimization strategies for cloud workloads
Configured backup and disaster recovery mechanisms including volume snapshots and configuration backups
Applied security best practices including RBAC, encryption, and tenant isolation
This lab demonstrates the power of Ceph as a unified storage solution for cloud-native environments. The skills you've developed here are directly applicable to real-world cloud storage management scenarios and align with the Red Hat Certified Specialist in Ceph Cloud Storage exam objectives.

Key Takeaways:

Ceph provides scalable, resilient storage that integrates seamlessly with cloud orchestration platforms
Proper pool configuration and resource management are crucial for multi-tenant cloud environments
Monitoring and performance optimization are ongoing processes that require regular attention
Backup and disaster recovery planning should be implemented from the beginning of any storage deployment
Security considerations, including encryption and access controls, are essential for cloud storage systems
The knowledge gained from this lab will enable you to design, deploy, and manage enterprise-grade cloud storage solutions using open-source technologies, making you well-prepared for advanced cloud storage certifications and real-world implementations.
