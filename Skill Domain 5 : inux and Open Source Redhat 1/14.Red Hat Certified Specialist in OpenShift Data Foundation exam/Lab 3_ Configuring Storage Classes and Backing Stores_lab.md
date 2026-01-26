Lab 3: Configuring Storage Classes and Backing Stores
Objectives
By the end of this lab, you will be able to:

Configure and deploy OpenShift Data Foundation (ODF) in internal (converged) mode
Set up and configure backing stores for persistent storage
Use OpenShift CLI to validate storage class configurations
Understand the relationship between storage classes, backing stores, and persistent volumes
Troubleshoot common storage configuration issues
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes and OpenShift concepts
Familiarity with persistent volumes and persistent volume claims
Knowledge of YAML configuration files
Experience with command-line interface operations
Understanding of storage concepts (block, file, and object storage)
Required Knowledge Areas
OpenShift cluster administration basics
Storage fundamentals in containerized environments
YAML syntax and structure
Linux command-line operations
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift cluster access. Simply click Start Lab to begin - no need to build your own virtual machine or install additional software.

What's Pre-Installed
OpenShift cluster (4.12 or later)
OpenShift CLI (oc) tool
Required operator catalogs
Administrative access credentials
Task 1: Configure and Deploy ODF in Internal (Converged) Mode
Subtask 1.1: Verify Cluster Prerequisites
First, let's verify that your OpenShift cluster meets the requirements for ODF deployment.

Login to your OpenShift cluster:
oc login --token=<your-token> --server=<your-server-url>
Check cluster nodes and their storage capacity:
oc get nodes
oc describe nodes | grep -A 5 "Capacity:"
Verify that you have at least 3 worker nodes:
oc get nodes --selector='node-role.kubernetes.io/worker'
Expected Output: You should see at least 3 worker nodes in Ready status.

Subtask 1.2: Install OpenShift Data Foundation Operator
Create the openshift-storage namespace:
oc create namespace openshift-storage
Label the namespace for monitoring:
oc label namespace openshift-storage "openshift.io/cluster-monitoring=true"
Create the OperatorGroup for ODF:
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-storage-operatorgroup
  namespace: openshift-storage
spec:
  targetNamespaces:
  - openshift-storage
EOF
Create the Subscription to install ODF operator:
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: odf-operator
  namespace: openshift-storage
spec:
  channel: "stable-4.12"
  installPlanApproval: Automatic
  name: odf-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
Wait for the operator to be installed:
oc get csv -n openshift-storage
Wait until you see: odf-operator.v4.12.x with status Succeeded

Subtask 1.3: Prepare Worker Nodes for Storage
Label worker nodes for ODF storage:
oc get nodes --selector='node-role.kubernetes.io/worker' --no-headers | awk '{print $1}' | xargs -I {} oc label node {} cluster.ocs.openshift.io/openshift-storage=""
Verify the labels were applied:
oc get nodes --show-labels | grep openshift-storage
Subtask 1.4: Create Storage Cluster in Internal Mode
Create a StorageCluster configuration file:
cat << EOF > storage-cluster.yaml
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
Apply the StorageCluster configuration:
oc apply -f storage-cluster.yaml
Monitor the deployment progress:
oc get storagecluster -n openshift-storage -w
Note: This process may take 10-15 minutes. Wait until the status shows Ready.

Task 2: Set Up Backing Stores
Subtask 2.1: Understand Backing Store Concepts
Backing stores are the underlying storage resources that provide the actual storage capacity for your applications. In ODF, backing stores can be:

PV Pool: Uses Persistent Volumes
AWS S3: Uses Amazon S3 buckets
Azure Blob: Uses Azure Blob storage
Google Cloud Storage: Uses GCS buckets
Subtask 2.2: Create a PV Pool Backing Store
Verify that ODF pods are running:
oc get pods -n openshift-storage
Create a BackingStore using PV Pool:
cat << EOF | oc apply -f -
apiVersion: noobaa.io/v1alpha1
kind: BackingStore
metadata:
  name: pv-pool-backing-store
  namespace: openshift-storage
spec:
  type: pv-pool
  pvPool:
    numVolumes: 3
    resources:
      requests:
        storage: 50Gi
    storageClass: ocs-storagecluster-ceph-rbd
EOF
Verify the backing store creation:
oc get backingstore -n openshift-storage
Subtask 2.3: Create Additional Backing Store (Optional)
For demonstration purposes, let's create another backing store:

cat << EOF | oc apply -f -
apiVersion: noobaa.io/v1alpha1
kind: BackingStore
metadata:
  name: additional-pv-backing-store
  namespace: openshift-storage
spec:
  type: pv-pool
  pvPool:
    numVolumes: 2
    resources:
      requests:
        storage: 30Gi
    storageClass: ocs-storagecluster-ceph-rbd
EOF
Subtask 2.4: Create a Bucket Class
Bucket classes define the data placement policy for object storage:

cat << EOF | oc apply -f -
apiVersion: noobaa.io/v1alpha1
kind: BucketClass
metadata:
  name: default-bucket-class
  namespace: openshift-storage
spec:
  placementPolicy:
    tiers:
    - backingStores:
      - pv-pool-backing-store
EOF
Task 3: Use OpenShift CLI to Validate Storage Class Configuration
Subtask 3.1: List and Examine Storage Classes
List all available storage classes:
oc get storageclass
Get detailed information about ODF storage classes:
oc describe storageclass ocs-storagecluster-ceph-rbd
oc describe storageclass ocs-storagecluster-cephfs
oc describe storageclass openshift-storage.noobaa.io
Check which storage class is set as default:
oc get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'
Subtask 3.2: Validate Storage Class Functionality
Create a test PVC using RBD storage class:
cat << EOF | oc apply -f -
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
      storage: 5Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Create a test PVC using CephFS storage class:
cat << EOF | oc apply -f -
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
      storage: 5Gi
  storageClassName: ocs-storagecluster-cephfs
EOF
Verify PVC creation and binding:
oc get pvc -n default
oc describe pvc test-rbd-pvc -n default
oc describe pvc test-cephfs-pvc -n default
Subtask 3.3: Test Object Storage
Create an ObjectBucketClaim:
cat << EOF | oc apply -f -
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: test-bucket-claim
  namespace: default
spec:
  generateBucketName: test-bucket
  storageClassName: openshift-storage.noobaa.io
EOF
Verify the ObjectBucketClaim:
oc get obc -n default
oc describe obc test-bucket-claim -n default
Check the created ConfigMap and Secret:
oc get configmap test-bucket-claim -n default -o yaml
oc get secret test-bucket-claim -n default -o yaml
Subtask 3.4: Monitor Storage Cluster Health
Check the overall storage cluster status:
oc get storagecluster -n openshift-storage
Monitor Ceph cluster health:
oc get cephcluster -n openshift-storage
Check NooBaa system status:
oc get noobaa -n openshift-storage
View storage cluster events:
oc get events -n openshift-storage --sort-by='.lastTimestamp'
Subtask 3.5: Validate Backing Store Status
Check backing store status:
oc get backingstore -n openshift-storage
oc describe backingstore pv-pool-backing-store -n openshift-storage
Verify bucket class configuration:
oc get bucketclass -n openshift-storage
oc describe bucketclass default-bucket-class -n openshift-storage
Troubleshooting Common Issues
Issue 1: Storage Cluster Not Ready
Symptoms: StorageCluster status shows Progressing or Error

Solutions:

# Check pod status
oc get pods -n openshift-storage | grep -v Running

# Check events for errors
oc get events -n openshift-storage --field-selector type=Warning

# Verify node labels
oc get nodes --show-labels | grep openshift-storage
Issue 2: PVC Stuck in Pending State
Symptoms: PVC remains in Pending status

Solutions:

# Check PVC events
oc describe pvc <pvc-name>

# Verify storage class exists
oc get storageclass

# Check available storage capacity
oc get pv
Issue 3: Backing Store Creation Failed
Symptoms: BackingStore shows Error status

Solutions:

# Check backing store details
oc describe backingstore <backing-store-name> -n openshift-storage

# Verify underlying storage class
oc get storageclass ocs-storagecluster-ceph-rbd

# Check NooBaa operator logs
oc logs -n openshift-storage deployment/noobaa-operator
Verification Commands Summary
Use these commands to verify your lab completion:

# Verify ODF installation
oc get csv -n openshift-storage | grep odf-operator

# Check storage cluster
oc get storagecluster -n openshift-storage

# List storage classes
oc get storageclass | grep ocs

# Verify backing stores
oc get backingstore -n openshift-storage

# Check test PVCs
oc get pvc -n default

# Verify object bucket claim
oc get obc -n default
Cleanup (Optional)
If you want to clean up the test resources:

# Delete test PVCs
oc delete pvc test-rbd-pvc test-cephfs-pvc -n default

# Delete test ObjectBucketClaim
oc delete obc test-bucket-claim -n default

# Note: Do not delete the StorageCluster or BackingStores 
# as they may be needed for other labs
Conclusion
In this lab, you have successfully:

Deployed OpenShift Data Foundation in internal (converged) mode, which provides software-defined storage directly on your OpenShift cluster nodes
Configured backing stores using PV pools, which serve as the foundation for persistent storage in your cluster
Validated storage class configurations using OpenShift CLI, ensuring that your applications can request and use different types of storage (block, file, and object)
Tested the storage functionality by creating and verifying PVCs and ObjectBucketClaims
Why This Matters
Understanding storage classes and backing stores is crucial for:

Application Deployment: Different applications require different storage types and performance characteristics
Data Persistence: Ensuring that application data survives pod restarts and rescheduling
Storage Optimization: Matching storage resources to application requirements for cost and performance efficiency
Disaster Recovery: Implementing proper backup and recovery strategies for persistent data
Key Takeaways
Internal mode provides storage using the cluster's own nodes, eliminating the need for external storage systems
Backing stores abstract the underlying storage infrastructure and provide flexibility in storage management
Storage classes act as templates that define how storage should be provisioned for applications
Proper validation ensures that your storage configuration works correctly before deploying production applications
This knowledge prepares you for the Red Hat Certified Specialist in OpenShift Data Foundation exam and real-world storage management scenarios in OpenShift environments.
