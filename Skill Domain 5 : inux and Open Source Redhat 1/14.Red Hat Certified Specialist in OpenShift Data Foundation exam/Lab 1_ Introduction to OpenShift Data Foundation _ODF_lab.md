Lab 1: Introduction to OpenShift Data Foundation (ODF)
Lab Objectives
By the end of this lab, students will be able to:

Understand the fundamental concepts and architecture of OpenShift Data Foundation (ODF)
Explain the role of Ceph as the storage backend in ODF
Describe the Rook operator and its importance in managing storage
Identify various ODF use cases including persistent storage, object storage, block storage, and file storage
Navigate the ODF interface and understand its components
Recognize how ODF integrates with OpenShift Container Platform
Prerequisites
Before starting this lab, students should have:

Basic understanding of Kubernetes and OpenShift concepts
Familiarity with containerized applications and storage concepts
Knowledge of Linux command line operations
Understanding of YAML configuration files
Basic networking concepts
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and ODF already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

OpenShift Container Platform 4.12+
OpenShift Data Foundation 4.12+
Pre-configured storage nodes
Web console access
Command-line tools (oc, kubectl)
Task 1: Overview of Ceph Storage Backend
Subtask 1.1: Understanding Ceph Architecture
Ceph is the distributed storage system that powers OpenShift Data Foundation. Let's explore its components and architecture.

Step 1: Access the OpenShift Web Console
Open your web browser and navigate to the OpenShift console URL provided in your lab environment
Log in using the credentials provided:
Username: admin
Password: [provided in lab environment]
Step 2: Navigate to Storage Overview
In the OpenShift web console, click on Storage in the left navigation menu
Select Data Foundation from the dropdown
Click on the Storage Systems tab
Step 3: Examine Ceph Components
Look for the ocs-storagecluster entry
Click on it to view detailed information
Observe the following Ceph components:
Monitor (MON) Nodes: These maintain cluster state and provide consensus

# Connect to your terminal and run:
oc get pods -n openshift-storage | grep mon
Object Storage Daemon (OSD) Nodes: These store actual data

oc get pods -n openshift-storage | grep osd
Manager (MGR) Nodes: These provide additional monitoring and management

oc get pods -n openshift-storage | grep mgr
Step 4: Understanding Ceph Storage Types
Ceph provides three types of storage interfaces:

RADOS Block Device (RBD): Block storage for virtual machines and containers
CephFS: Distributed file system for shared file access
RADOS Gateway (RGW): Object storage compatible with S3 and Swift APIs
Subtask 1.2: Exploring Ceph Cluster Health
Step 1: Check Cluster Status via CLI
Open the terminal in your lab environment and execute:

# Set the namespace context
oc project openshift-storage

# Check the overall cluster health
oc get cephcluster -n openshift-storage

# View detailed cluster information
oc describe cephcluster ocs-storagecluster -n openshift-storage
Step 2: Monitor Storage Utilization
# Check storage capacity and usage
oc get cephblockpool -n openshift-storage

# View storage class information
oc get storageclass | grep ocs
Expected output should show storage classes like:

ocs-storagecluster-ceph-rbd
ocs-storagecluster-cephfs
ocs-storagecluster-ceph-rgw
Task 2: Understand Rook Operator and Its Role in ODF
Subtask 2.1: Introduction to Rook Operator
The Rook operator is a Kubernetes-native storage orchestrator that manages Ceph clusters within OpenShift.

Step 1: Examine Rook Operator Deployment
# Check if Rook operator is running
oc get pods -n openshift-storage | grep rook

# View Rook operator details
oc describe deployment rook-ceph-operator -n openshift-storage
Step 2: Understanding Rook Custom Resources
Rook uses Custom Resource Definitions (CRDs) to manage storage:

# List Rook-related CRDs
oc get crd | grep rook

# View specific CRDs
oc get crd cephclusters.ceph.rook.io -o yaml
Subtask 2.2: Rook Operator Functions
Step 1: Explore Rook Configuration
# View the main Ceph cluster configuration
oc get cephcluster ocs-storagecluster -n openshift-storage -o yaml > ceph-cluster-config.yaml

# Examine the configuration file
cat ceph-cluster-config.yaml
Key sections to observe:

spec.storage: Defines storage devices and configuration
spec.monitoring: Monitoring and alerting settings
spec.network: Network configuration for Ceph
Step 2: Monitor Rook Operator Logs
# View Rook operator logs
oc logs deployment/rook-ceph-operator -n openshift-storage --tail=50

# Monitor real-time logs
oc logs deployment/rook-ceph-operator -n openshift-storage -f
Subtask 2.3: Rook Operator Management Tasks
Step 1: Understanding Operator Lifecycle
The Rook operator performs several key functions:

Cluster Bootstrapping: Initial Ceph cluster setup
Node Management: Adding/removing storage nodes
Service Management: Managing Ceph services (MON, OSD, MGR)
Upgrade Management: Handling cluster upgrades
Step 2: View Operator Events
# Check recent events related to storage
oc get events -n openshift-storage --sort-by='.lastTimestamp' | tail -20

# Filter for Rook-specific events
oc get events -n openshift-storage --field-selector involvedObject.name=rook-ceph-operator
Task 3: Introduction to ODF Use Cases
Subtask 3.1: Persistent Storage for Applications
Step 1: Create a Sample Application with Persistent Storage
Create a test application that uses ODF for persistent storage:

# Create a new project for testing
oc new-project odf-demo

# Create a PVC using ODF storage class
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
  namespace: odf-demo
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Step 2: Deploy Application Using the PVC
# Create a deployment that uses the PVC
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: odf-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-container
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: demo-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: demo-storage
        persistentVolumeClaim:
          claimName: demo-pvc
EOF
Step 3: Verify Persistent Storage
# Check if PVC is bound
oc get pvc -n odf-demo

# Verify the pod is running
oc get pods -n odf-demo

# Test data persistence
oc exec -n odf-demo deployment/demo-app -- sh -c "echo 'Hello ODF!' > /usr/share/nginx/html/index.html"

# Verify the file was created
oc exec -n odf-demo deployment/demo-app -- cat /usr/share/nginx/html/index.html
Subtask 3.2: Object Storage Use Case
Step 1: Access Object Storage Service
# Check if NooBaa (Multi-Cloud Gateway) is running
oc get pods -n openshift-storage | grep noobaa

# Get the NooBaa management service
oc get route -n openshift-storage | grep noobaa-mgmt
Step 2: Create Object Bucket Claim
# Create an Object Bucket Claim for S3-compatible storage
cat << EOF | oc apply -f -
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: demo-bucket
  namespace: odf-demo
spec:
  generateBucketName: demo-bucket
  storageClassName: openshift-storage.noobaa.io
EOF
Step 3: Verify Object Storage Access
# Check the bucket claim status
oc get obc demo-bucket -n odf-demo

# Get the generated secret with access credentials
oc get secret demo-bucket -n odf-demo -o yaml
Subtask 3.3: File Storage Use Case
Step 1: Create Shared File Storage
# Create a PVC for shared file storage using CephFS
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-storage-pvc
  namespace: odf-demo
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: ocs-storagecluster-cephfs
EOF
Step 2: Deploy Multiple Pods Sharing Storage
# Create a deployment with multiple replicas sharing the same storage
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shared-storage-app
  namespace: odf-demo
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
      - name: shared-container
        image: busybox:latest
        command: ['sleep', '3600']
        volumeMounts:
        - name: shared-volume
          mountPath: /shared-data
      volumes:
      - name: shared-volume
        persistentVolumeClaim:
          claimName: shared-storage-pvc
EOF
Step 3: Test Shared File Access
# Get the pod names
oc get pods -n odf-demo -l app=shared-storage-app

# Write data from first pod
POD1=$(oc get pods -n odf-demo -l app=shared-storage-app -o jsonpath='{.items[0].metadata.name}')
oc exec -n odf-demo $POD1 -- sh -c "echo 'Data from pod 1' > /shared-data/test.txt"

# Read data from second pod
POD2=$(oc get pods -n odf-demo -l app=shared-storage-app -o jsonpath='{.items[1].metadata.name}')
oc exec -n odf-demo $POD2 -- cat /shared-data/test.txt
Subtask 3.4: Block Storage Use Case
Step 1: Understanding Block Storage Performance
# Create a high-performance block storage PVC
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: block-storage-pvc
  namespace: odf-demo
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: ocs-storagecluster-ceph-rbd
  volumeMode: Block
EOF
Step 2: Deploy Application with Block Storage
# Create a pod that uses raw block storage
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: block-storage-pod
  namespace: odf-demo
spec:
  containers:
  - name: block-container
    image: busybox:latest
    command: ['sleep', '3600']
    volumeDevices:
    - name: block-volume
      devicePath: /dev/xvda
  volumes:
  - name: block-volume
    persistentVolumeClaim:
      claimName: block-storage-pvc
EOF
Troubleshooting Tips
Common Issues and Solutions
PVC Stuck in Pending State

# Check storage class availability
oc get storageclass

# Check events for the PVC
oc describe pvc <pvc-name> -n <namespace>
Ceph Cluster Health Issues

# Check Ceph cluster status
oc get cephcluster -n openshift-storage

# View detailed cluster health
oc rsh -n openshift-storage deployment/rook-ceph-tools
ceph status
Rook Operator Not Responding

# Restart the Rook operator
oc delete pod -l app=rook-ceph-operator -n openshift-storage

# Check operator logs
oc logs deployment/rook-ceph-operator -n openshift-storage
Lab Cleanup
Before ending the lab, clean up the resources:

# Delete the demo project
oc delete project odf-demo

# Verify cleanup
oc get projects | grep odf-demo
Conclusion
In this lab, you have successfully:

Explored Ceph Storage Backend: You learned about Ceph's distributed architecture and its three main storage interfaces (RBD, CephFS, and RGW). You examined how Ceph components (MON, OSD, MGR) work together to provide reliable, scalable storage.

Understood the Rook Operator: You discovered how Rook acts as a Kubernetes-native orchestrator for Ceph, managing the entire lifecycle of storage clusters through Custom Resource Definitions and automated operations.

Implemented Various Storage Use Cases: You hands-on experience with:

Persistent Storage: Created PVCs for containerized applications
Object Storage: Set up S3-compatible bucket storage using NooBaa
File Storage: Implemented shared file systems using CephFS
Block Storage: Configured raw block devices for high-performance applications
Why This Matters: OpenShift Data Foundation provides a unified storage platform that eliminates storage silos and simplifies data management in containerized environments. Understanding ODF is crucial for:

Application Developers: Who need reliable persistent storage for stateful applications
Platform Engineers: Who must design scalable storage architectures
System Administrators: Who manage enterprise storage infrastructure
DevOps Teams: Who require automated storage provisioning and management
The knowledge gained in this lab forms the foundation for advanced ODF topics including disaster recovery, multi-cluster storage, and performance optimization. These skills are essential for the Red Hat Certified Specialist in OpenShift Data Foundation exam and real-world enterprise deployments.

By mastering ODF, you're equipped to handle modern storage challenges in cloud-native environments, ensuring applications have the persistent, scalable, and reliable storage they need to operate effectively.
