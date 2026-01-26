Lab 12: Applying RBAC to ODF Storage Resources
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of Role-Based Access Control (RBAC) in OpenShift Data Foundation
Create and configure RBAC policies for storage resources
Implement user-specific access controls for ODF storage components
Apply RBAC rules to restrict and grant storage resource access
Test and validate RBAC policies to ensure proper security implementation
Troubleshoot common RBAC configuration issues in storage environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes and OpenShift concepts
Familiarity with YAML configuration files
Knowledge of OpenShift CLI (oc) commands
Understanding of storage concepts in containerized environments
Completed previous ODF labs or equivalent experience
Basic Linux command line skills
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and ODF already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

OpenShift cluster with ODF installed
Multiple user accounts for testing
Pre-configured storage classes and persistent volumes
Administrative access for RBAC configuration
Task 1: Create and Manage RBAC Policies for Storage Access
Subtask 1.1: Examine Current RBAC Configuration
First, let's explore the existing RBAC setup in your ODF environment.

Login to your OpenShift cluster:
oc login -u admin -p admin123
Check current storage-related roles:
oc get clusterroles | grep -E "(storage|odf|ceph)"
Examine the default storage admin role:
oc describe clusterrole storage-admin
List current role bindings related to storage:
oc get rolebindings -A | grep -E "(storage|odf)"
Check ODF-specific service accounts:
oc get serviceaccounts -n openshift-storage
Subtask 1.2: Create Custom Storage Roles
Now we'll create custom roles for different levels of storage access.

Create a storage viewer role:
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: odf-storage-viewer
rules:
- apiGroups: [""]
  resources: ["persistentvolumes", "persistentvolumeclaims", "storageclasses"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses", "volumeattachments"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["ceph.rook.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["noobaa.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
EOF
Create a storage operator role:
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: odf-storage-operator
rules:
- apiGroups: [""]
  resources: ["persistentvolumes", "persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["ceph.rook.io"]
  resources: ["cephclusters", "cephblockpools", "cephfilesystems"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["noobaa.io"]
  resources: ["noobaas", "backingstores", "bucketclasses"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
EOF
Create a namespace-specific storage role:
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: namespace-storage-manager
rules:
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
  resourceNames: []
EOF
Subtask 1.3: Verify Role Creation
Confirm the roles were created:
oc get clusterroles | grep odf-storage
oc get roles -n default | grep storage
Examine the detailed permissions:
oc describe clusterrole odf-storage-viewer
oc describe clusterrole odf-storage-operator
Task 2: Apply RBAC Rules for Users Accessing Storage Resources
Subtask 2.1: Create Test Users
We'll create several test users to demonstrate different access levels.

Create user accounts:
# Create storage viewer user
htpasswd -c -B -b /tmp/htpasswd storage-viewer viewerpass123

# Add storage operator user
htpasswd -B -b /tmp/htpasswd storage-operator operatorpass123

# Add namespace storage manager user
htpasswd -B -b /tmp/htpasswd namespace-manager managerpass123

# Add regular user with no storage access
htpasswd -B -b /tmp/htpasswd regular-user regularpass123
Create the HTPasswd identity provider:
oc create secret generic htpass-secret --from-file=htpasswd=/tmp/htpasswd -n openshift-config

cat << EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd_provider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF
Wait for the authentication operator to restart:
sleep 30
oc get pods -n openshift-authentication
Subtask 2.2: Create Role Bindings
Now we'll bind our custom roles to the test users.

Bind the storage viewer role:
oc create clusterrolebinding storage-viewer-binding \
  --clusterrole=odf-storage-viewer \
  --user=storage-viewer
Bind the storage operator role:
oc create clusterrolebinding storage-operator-binding \
  --clusterrole=odf-storage-operator \
  --user=storage-operator
Bind the namespace storage manager role:
oc create rolebinding namespace-storage-binding \
  --role=namespace-storage-manager \
  --user=namespace-manager \
  --namespace=default
Give the namespace manager basic access to view the namespace:
oc create rolebinding namespace-view-binding \
  --clusterrole=view \
  --user=namespace-manager \
  --namespace=default
Subtask 2.3: Create Test Storage Resources
Let's create some storage resources to test our RBAC policies.

Create a test storage class:
cat << EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: test-rbd-storage
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
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
EOF
Create a test PVC:
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Task 3: Test RBAC Policies for Users
Subtask 3.1: Test Storage Viewer Access
Login as storage viewer:
oc login -u storage-viewer -p viewerpass123
Test viewing storage resources:
# Should work - viewing PVCs
oc get pvc -A

# Should work - viewing storage classes
oc get storageclass

# Should work - viewing persistent volumes
oc get pv
Test restricted operations:
# Should fail - creating PVC
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: viewer-test-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF

# Should fail - deleting PVC
oc delete pvc test-pvc -n default
Subtask 3.2: Test Storage Operator Access
Login as storage operator:
oc login -u storage-operator -p operatorpass123
Test operator capabilities:
# Should work - creating PVC
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: operator-test-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF

# Should work - viewing all storage resources
oc get pvc -A
oc get storageclass
Test creating storage class:
cat << EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: operator-created-sc
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
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
EOF
Subtask 3.3: Test Namespace Storage Manager Access
Login as namespace manager:
oc login -u namespace-manager -p managerpass123
Test namespace-specific access:
# Should work - managing PVCs in default namespace
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: namespace-manager-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF

# Should work - viewing PVCs in default namespace
oc get pvc -n default

# Should work - deleting PVC in default namespace
oc delete pvc namespace-manager-pvc -n default
Test restricted access:
# Should fail - accessing other namespaces
oc get pvc -n openshift-storage

# Should fail - creating storage classes
cat << EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: unauthorized-sc
provisioner: openshift-storage.rbd.csi.ceph.com
EOF
Subtask 3.4: Test Regular User Access
Login as regular user:
oc login -u regular-user -p regularpass123
Test lack of storage access:
# Should fail - no storage permissions
oc get pvc
oc get storageclass
oc get pv

# Should fail - creating PVC
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: unauthorized-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Subtask 3.5: Verify RBAC Audit and Monitoring
Login back as admin:
oc login -u admin -p admin123
Check audit logs for RBAC events:
# View recent authentication events
oc get events -A | grep -i "forbidden\|unauthorized"

# Check role binding status
oc get rolebindings -A
oc get clusterrolebindings | grep storage
Monitor storage resource access:
# Check PVC creation events
oc get events -n default --field-selector reason=SuccessfulCreate

# Verify current PVCs and their creators
oc get pvc -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,CREATED:.metadata.creationTimestamp
Troubleshooting Common Issues
Issue 1: User Cannot Login
Problem: Test users cannot authenticate Solution:

# Check OAuth configuration
oc get oauth cluster -o yaml

# Verify HTPasswd secret
oc get secret htpass-secret -n openshift-config -o yaml

# Check authentication pods
oc get pods -n openshift-authentication
Issue 2: Role Binding Not Working
Problem: User has role binding but still gets permission denied Solution:

# Verify role binding exists
oc get rolebindings -A | grep username
oc get clusterrolebindings | grep username

# Check role permissions
oc describe clusterrole role-name

# Test with can-i command
oc auth can-i create pvc --as=username
Issue 3: Storage Resources Not Accessible
Problem: Users cannot access expected storage resources Solution:

# Check if ODF is properly installed
oc get csv -n openshift-storage

# Verify storage classes exist
oc get storageclass

# Check Ceph cluster status
oc get cephcluster -n openshift-storage
Validation and Testing Scripts
Script 1: RBAC Validation Script
Create a comprehensive validation script:

cat << 'EOF' > validate-rbac.sh
#!/bin/bash

echo "=== RBAC Validation Script ==="

# Test storage-viewer permissions
echo "Testing storage-viewer permissions..."
oc login -u storage-viewer -p viewerpass123 --insecure-skip-tls-verify=true > /dev/null 2>&1

if oc get pvc -A > /dev/null 2>&1; then
    echo "✓ storage-viewer can view PVCs"
else
    echo "✗ storage-viewer cannot view PVCs"
fi

if oc create pvc test-fail --dry-run=client -o yaml > /dev/null 2>&1; then
    echo "✗ storage-viewer can create PVCs (should fail)"
else
    echo "✓ storage-viewer cannot create PVCs (correct)"
fi

# Test storage-operator permissions
echo "Testing storage-operator permissions..."
oc login -u storage-operator -p operatorpass123 --insecure-skip-tls-verify=true > /dev/null 2>&1

if oc auth can-i create pvc; then
    echo "✓ storage-operator can create PVCs"
else
    echo "✗ storage-operator cannot create PVCs"
fi

if oc auth can-i create storageclass; then
    echo "✓ storage-operator can create StorageClasses"
else
    echo "✗ storage-operator cannot create StorageClasses"
fi

# Test namespace-manager permissions
echo "Testing namespace-manager permissions..."
oc login -u namespace-manager -p managerpass123 --insecure-skip-tls-verify=true > /dev/null 2>&1

if oc auth can-i create pvc -n default; then
    echo "✓ namespace-manager can create PVCs in default namespace"
else
    echo "✗ namespace-manager cannot create PVCs in default namespace"
fi

if oc auth can-i create pvc -n openshift-storage; then
    echo "✗ namespace-manager can create PVCs in openshift-storage (should fail)"
else
    echo "✓ namespace-manager cannot create PVCs in openshift-storage (correct)"
fi

echo "=== Validation Complete ==="
EOF

chmod +x validate-rbac.sh
./validate-rbac.sh
Script 2: Cleanup Script
cat << 'EOF' > cleanup-rbac-lab.sh
#!/bin/bash

echo "=== Cleaning up RBAC Lab Resources ==="

# Login as admin
oc login -u admin -p admin123 --insecure-skip-tls-verify=true

# Remove test PVCs
oc delete pvc operator-test-pvc -n default --ignore-not-found=true
oc delete pvc test-pvc -n default --ignore-not-found=true

# Remove test storage classes
oc delete storageclass test-rbd-storage --ignore-not-found=true
oc delete storageclass operator-created-sc --ignore-not-found=true

# Remove role bindings
oc delete clusterrolebinding storage-viewer-binding --ignore-not-found=true
oc delete clusterrolebinding storage-operator-binding --ignore-not-found=true
oc delete rolebinding namespace-storage-binding -n default --ignore-not-found=true
oc delete rolebinding namespace-view-binding -n default --ignore-not-found=true

# Remove custom roles
oc delete clusterrole odf-storage-viewer --ignore-not-found=true
oc delete clusterrole odf-storage-operator --ignore-not-found=true
oc delete role namespace-storage-manager -n default --ignore-not-found=true

# Remove users (optional - comment out if you want to keep them)
# oc delete user storage-viewer storage-operator namespace-manager regular-user --ignore-not-found=true

echo "=== Cleanup Complete ==="
EOF

chmod +x cleanup-rbac-lab.sh
Advanced RBAC Scenarios
Scenario 1: Multi-Tenant Storage Access
For environments with multiple tenants requiring isolated storage access:

# Create tenant-specific roles
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: tenant-a
  name: tenant-storage-admin
rules:
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: tenant-b
  name: tenant-storage-admin
rules:
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
EOF
Scenario 2: Storage Quota Management
Implement storage quotas with RBAC:

# Create resource quota for storage
cat << EOF | oc apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: storage-quota
  namespace: default
spec:
  hard:
    requests.storage: "10Gi"
    persistentvolumeclaims: "5"
    count/storageclass.storage.k8s.io: "2"
EOF
Conclusion
In this comprehensive lab, you have successfully:

Implemented RBAC for ODF Storage Resources by creating custom roles with specific permissions for different user types, from read-only viewers to full storage operators.

Applied Granular Access Controls by configuring role bindings that restrict users to appropriate storage operations, ensuring security while maintaining functionality.

Tested Security Policies through comprehensive validation of user permissions, confirming that each role works as intended and unauthorized access is properly blocked.

Gained Practical Experience with real-world RBAC scenarios including multi-tenant environments, namespace isolation, and storage resource management.

Why This Matters
RBAC implementation for storage resources is crucial for:

Security: Preventing unauthorized access to sensitive storage systems and data
Compliance: Meeting regulatory requirements for access control and audit trails
Operational Safety: Reducing risk of accidental data loss or system misconfiguration
Multi-tenancy: Enabling secure shared storage infrastructure across different teams and applications
Resource Management: Controlling storage consumption and preventing resource exhaustion
Next Steps
To further enhance your ODF RBAC skills:

Explore integration with external identity providers (LDAP, Active Directory)
Implement automated RBAC policy management using GitOps
Study advanced Ceph RBAC features for fine-grained object storage access
Practice disaster recovery scenarios with RBAC considerations
Learn about RBAC monitoring and alerting best practices
This lab provides the foundation for implementing enterprise-grade storage security in OpenShift Data Foundation environments, preparing you for the Red Hat Certified Specialist in OpenShift Data Foundation exam and real-world storage administration challenges.
