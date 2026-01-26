Lab 5: Configuring and Managing File Storage
Objectives
By the end of this lab, you will be able to:

Configure and deploy NFSv4 file storage using OpenShift Data Foundation (ODF)
Create and manage file share policies for multi-pod access
Mount NFSv4 file systems on multiple OpenShift pods
Validate file storage configuration and test data persistence
Troubleshoot common NFSv4 storage issues in OpenShift environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift concepts (pods, services, persistent volumes)
Familiarity with Kubernetes storage concepts
Knowledge of Linux file systems and NFS fundamentals
Experience with command-line interface operations
Understanding of YAML configuration files
Required Knowledge Level: Intermediate Linux and OpenShift administration

Lab Environment Setup
Al Nafi Cloud Machines: This lab uses pre-configured Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your environment - no need to build your own virtual machines or install additional software.

Your lab environment includes:

OpenShift cluster with ODF pre-installed
Administrative access to the cluster
Pre-configured storage nodes
Command-line tools (oc, kubectl)
Task 1: Provision NFSv4 File Storage using ODF
Subtask 1.1: Verify ODF Installation and Storage Cluster
First, let's verify that OpenShift Data Foundation is properly installed and running.

Connect to your OpenShift cluster:
oc login -u admin -p admin https://api.cluster.local:6443
Verify ODF operator installation:
oc get csv -n openshift-storage | grep odf-operator
Check storage cluster status:
oc get storagecluster -n openshift-storage
Verify storage nodes are ready:
oc get nodes -l cluster.ocs.openshift.io/openshift-storage=
Subtask 1.2: Create Storage Class for NFSv4
Create a storage class specifically configured for NFSv4 file storage.

Create the NFSv4 storage class configuration:
cat > nfsv4-storageclass.yaml << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-storagecluster-cephfs-nfsv4
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: openshift-storage.cephfs.csi.ceph.com
parameters:
  clusterID: openshift-storage
  fsName: ocs-storagecluster-cephfilesystem
  pool: ocs-storagecluster-cephfilesystem-data0
  nfsv4: "true"
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
EOF
Apply the storage class:
oc apply -f nfsv4-storageclass.yaml
Verify storage class creation:
oc get storageclass | grep nfsv4
Subtask 1.3: Configure CephFS for NFSv4 Support
Enable NFSv4 support in the CephFS configuration.

Create CephFS NFS configuration:
cat > cephfs-nfs-config.yaml << EOF
apiVersion: ceph.rook.io/v1
kind: CephNFS
metadata:
  name: ceph-nfs
  namespace: openshift-storage
spec:
  rados:
    pool: ocs-storagecluster-cephfilesystem-metadata
    namespace: nfs-ns
  server:
    active: 2
    annotations:
      rook: nfs
    placement:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: cluster.ocs.openshift.io/openshift-storage
              operator: Exists
    resources:
      limits:
        cpu: 500m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 512Mi
EOF
Apply the NFS configuration:
oc apply -f cephfs-nfs-config.yaml
Wait for NFS pods to be ready:
oc get pods -n openshift-storage | grep nfs
Task 2: Set up File Share Policies and Mount File Systems
Subtask 2.1: Create Persistent Volume Claims
Create multiple PVCs that will use NFSv4 storage for shared access.

Create the first PVC for shared storage:
cat > shared-storage-pvc1.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-nfsv4-pvc1
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: ocs-storagecluster-cephfs-nfsv4
EOF
Create the second PVC for shared storage:
cat > shared-storage-pvc2.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-nfsv4-pvc2
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 3Gi
  storageClassName: ocs-storagecluster-cephfs-nfsv4
EOF
Apply both PVCs:
oc apply -f shared-storage-pvc1.yaml
oc apply -f shared-storage-pvc2.yaml
Verify PVC status:
oc get pvc | grep shared-nfsv4
Subtask 2.2: Configure File Share Policies
Create network policies and security contexts for proper file sharing.

Create a security context constraint for NFS access:
cat > nfs-scc.yaml << EOF
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: nfs-scc
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegedContainer: false
allowedCapabilities: null
defaultAddCapabilities: null
fsGroup:
  type: RunAsAny
readOnlyRootFilesystem: false
requiredDropCapabilities:
- KILL
- MKNOD
- SETUID
- SETGID
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: MustRunAs
supplementalGroups:
  type: RunAsAny
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
EOF
Apply the security context constraint:
oc apply -f nfs-scc.yaml
Create a service account for NFS access:
oc create serviceaccount nfs-service-account
oc adm policy add-scc-to-user nfs-scc -z nfs-service-account
Subtask 2.3: Deploy Multiple Pods with Shared Storage
Create multiple pods that will mount the same NFSv4 storage.

Create the first pod with shared storage:
cat > nfs-pod1.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: nfs-writer-pod
  labels:
    app: nfs-test
spec:
  serviceAccountName: nfs-service-account
  containers:
  - name: writer
    image: registry.redhat.io/ubi8/ubi:latest
    command: ["/bin/bash"]
    args: ["-c", "while true; do echo 'Data from writer pod at $(date)' >> /shared-data/writer.log; sleep 30; done"]
    volumeMounts:
    - name: shared-volume
      mountPath: /shared-data
    securityContext:
      runAsUser: 1001
      runAsGroup: 1001
  volumes:
  - name: shared-volume
    persistentVolumeClaim:
      claimName: shared-nfsv4-pvc1
  restartPolicy: Always
EOF
Create the second pod with shared storage:
cat > nfs-pod2.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: nfs-reader-pod
  labels:
    app: nfs-test
spec:
  serviceAccountName: nfs-service-account
  containers:
  - name: reader
    image: registry.redhat.io/ubi8/ubi:latest
    command: ["/bin/bash"]
    args: ["-c", "while true; do echo 'Reading from reader pod:'; tail -5 /shared-data/writer.log 2>/dev/null || echo 'No data yet'; sleep 45; done"]
    volumeMounts:
    - name: shared-volume
      mountPath: /shared-data
    securityContext:
      runAsUser: 1002
      runAsGroup: 1002
  volumes:
  - name: shared-volume
    persistentVolumeClaim:
      claimName: shared-nfsv4-pvc1
  restartPolicy: Always
EOF
Create the third pod with different PVC:
cat > nfs-pod3.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: nfs-multi-pod
  labels:
    app: nfs-test
spec:
  serviceAccountName: nfs-service-account
  containers:
  - name: multi-access
    image: registry.redhat.io/ubi8/ubi:latest
    command: ["/bin/bash"]
    args: ["-c", "while true; do echo 'Multi-access pod data at $(date)' >> /data2/multi.log; sleep 60; done"]
    volumeMounts:
    - name: shared-volume2
      mountPath: /data2
    securityContext:
      runAsUser: 1003
      runAsGroup: 1003
  volumes:
  - name: shared-volume2
    persistentVolumeClaim:
      claimName: shared-nfsv4-pvc2
  restartPolicy: Always
EOF
Deploy all pods:
oc apply -f nfs-pod1.yaml
oc apply -f nfs-pod2.yaml
oc apply -f nfs-pod3.yaml
Verify pod deployment:
oc get pods -l app=nfs-test
Task 3: Validate File Storage Configuration
Subtask 3.1: Test File System Mounting
Verify that the NFSv4 file systems are properly mounted in all pods.

Check mount points in the writer pod:
oc exec nfs-writer-pod -- df -h /shared-data
Check mount points in the reader pod:
oc exec nfs-reader-pod -- df -h /shared-data
Verify mount type is NFSv4:
oc exec nfs-writer-pod -- mount | grep shared-data
Check file system permissions:
oc exec nfs-writer-pod -- ls -la /shared-data
Subtask 3.2: Test Data Sharing Between Pods
Validate that data written by one pod can be read by another pod.

Create a test file from the writer pod:
oc exec nfs-writer-pod -- bash -c "echo 'Test data from writer pod' > /shared-data/test-file.txt"
Read the test file from the reader pod:
oc exec nfs-reader-pod -- cat /shared-data/test-file.txt
Create a file from the reader pod:
oc exec nfs-reader-pod -- bash -c "echo 'Response from reader pod' >> /shared-data/test-file.txt"
Verify the updated content from the writer pod:
oc exec nfs-writer-pod -- cat /shared-data/test-file.txt
Test concurrent file access:
oc exec nfs-writer-pod -- bash -c "for i in {1..5}; do echo 'Writer line $i' >> /shared-data/concurrent-test.txt; sleep 1; done" &
oc exec nfs-reader-pod -- bash -c "for i in {1..5}; do echo 'Reader line $i' >> /shared-data/concurrent-test.txt; sleep 1; done" &
Check the concurrent test results:
sleep 10
oc exec nfs-writer-pod -- cat /shared-data/concurrent-test.txt
Subtask 3.3: Validate Storage Performance and Reliability
Test the performance and reliability of the NFSv4 storage.

Create a performance test script:
cat > performance-test.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: nfs-performance-test
spec:
  serviceAccountName: nfs-service-account
  containers:
  - name: perf-test
    image: registry.redhat.io/ubi8/ubi:latest
    command: ["/bin/bash"]
    args: ["-c", "sleep 3600"]
    volumeMounts:
    - name: shared-volume
      mountPath: /test-data
  volumes:
  - name: shared-volume
    persistentVolumeClaim:
      claimName: shared-nfsv4-pvc1
  restartPolicy: Never
EOF
Deploy the performance test pod:
oc apply -f performance-test.yaml
Run write performance test:
oc exec nfs-performance-test -- bash -c "time dd if=/dev/zero of=/test-data/write-test.dat bs=1M count=100"
Run read performance test:
oc exec nfs-performance-test -- bash -c "time dd if=/test-data/write-test.dat of=/dev/null bs=1M"
Test file locking capabilities:
oc exec nfs-performance-test -- bash -c "flock /test-data/lock-test.lock -c 'echo File locked successfully; sleep 5; echo Lock released'"
Subtask 3.4: Monitor Storage Usage and Health
Monitor the health and usage of your NFSv4 storage.

Check PV and PVC status:
oc get pv,pvc
Monitor storage usage:
oc exec nfs-writer-pod -- du -sh /shared-data
oc exec nfs-multi-pod -- du -sh /data2
Check CephFS health:
oc exec -n openshift-storage deployment/rook-ceph-tools -- ceph fs status
Monitor NFS server status:
oc get pods -n openshift-storage | grep nfs
oc logs -n openshift-storage -l app=rook-ceph-nfs
View storage metrics:
oc exec -n openshift-storage deployment/rook-ceph-tools -- ceph df
Troubleshooting Common Issues
Issue 1: PVC Stuck in Pending State
Symptoms: PVC remains in Pending status Solution:

# Check storage class availability
oc get storageclass

# Check available storage capacity
oc exec -n openshift-storage deployment/rook-ceph-tools -- ceph df

# Verify CephFS is healthy
oc exec -n openshift-storage deployment/rook-ceph-tools -- ceph fs status
Issue 2: Pod Cannot Mount Volume
Symptoms: Pod fails to start with mount errors Solution:

# Check pod events
oc describe pod <pod-name>

# Verify security context constraints
oc get scc nfs-scc

# Check service account permissions
oc describe sa nfs-service-account
Issue 3: File Permission Errors
Symptoms: Cannot write to mounted volume Solution:

# Check mount permissions
oc exec <pod-name> -- ls -la /mount-point

# Verify security context in pod spec
oc get pod <pod-name> -o yaml | grep -A 10 securityContext

# Test with different user ID
oc exec <pod-name> -- id
Lab Validation Checklist
Before completing this lab, ensure you have successfully:

 Deployed NFSv4 storage class with ODF
 Created multiple PVCs using NFSv4 storage
 Deployed pods that successfully mount shared storage
 Verified data sharing between multiple pods
 Tested concurrent file access
 Validated storage performance
 Monitored storage health and usage
 Resolved any mounting or permission issues
Cleanup Instructions
To clean up the lab environment:

Delete test pods:
oc delete pod nfs-writer-pod nfs-reader-pod nfs-multi-pod nfs-performance-test
Delete PVCs:
oc delete pvc shared-nfsv4-pvc1 shared-nfsv4-pvc2
Remove service account and SCC:
oc delete sa nfs-service-account
oc delete scc nfs-scc
Clean up configuration files:
rm -f *.yaml
Conclusion
In this lab, you have successfully configured and managed NFSv4 file storage using OpenShift Data Foundation. You accomplished the following key objectives:

What You Learned:

How to provision NFSv4 storage using ODF's CephFS backend
Configuration of storage classes for shared file access
Implementation of file share policies and security contexts
Deployment of multiple pods with shared storage access
Validation of data persistence and concurrent access capabilities
Performance testing and health monitoring of NFSv4 storage
Why This Matters: NFSv4 file storage is crucial for applications that require shared access to data across multiple pods or containers. This capability is essential for:

Stateful Applications: Applications that need persistent, shared data
Content Management: Systems requiring multiple writers and readers
Data Analytics: Workloads that process shared datasets
Development Environments: Shared code repositories and build artifacts
Real-World Applications: The skills you've developed in this lab directly apply to enterprise scenarios such as:

Implementing shared storage for microservices architectures
Supporting legacy applications that require NFS storage
Creating development and testing environments with shared data access
Building content delivery systems with multiple content producers
This lab has prepared you for the Red Hat Certified Specialist in OpenShift Data Foundation exam by providing hands-on experience with advanced storage configuration and management tasks that are commonly encountered in production OpenShift environments.
