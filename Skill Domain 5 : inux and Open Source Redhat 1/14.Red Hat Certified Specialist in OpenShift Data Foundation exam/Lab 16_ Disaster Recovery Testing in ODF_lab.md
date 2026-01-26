Lab 16: Disaster Recovery Testing in OpenShift Data Foundation (ODF)
Objectives
By the end of this lab, students will be able to:

Understand disaster recovery concepts and strategies in OpenShift Data Foundation
Implement and test disaster recovery procedures for ODF storage systems
Perform complete data restoration in multi-zone environments
Monitor recovery operations and validate data consistency post-recovery
Troubleshoot common disaster recovery scenarios in ODF deployments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Kubernetes and OpenShift concepts
Familiarity with OpenShift Data Foundation (ODF) architecture
Knowledge of storage concepts including persistent volumes and claims
Experience with command-line interface operations
Understanding of YAML configuration files
Completion of previous ODF labs or equivalent experience
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and ODF already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

OpenShift cluster with 3 master nodes and 3 worker nodes
OpenShift Data Foundation deployed across multiple zones
Pre-configured storage classes and sample applications
Monitoring and logging tools
Command-line tools (oc, kubectl, rook-ceph tools)
Task 1: Test Disaster Recovery Strategies for ODF
Subtask 1.1: Verify Current ODF Deployment Status
First, let's examine the current state of our ODF deployment to establish a baseline.

Connect to your lab environment and open a terminal

Check ODF operator status:

oc get csv -n openshift-storage | grep odf
Verify storage cluster health:
oc get storagecluster -n openshift-storage
Check Ceph cluster status:
oc get cephcluster -n openshift-storage
List all storage nodes:
oc get nodes -l cluster.ocs.openshift.io/openshift-storage=''
Subtask 1.2: Create Test Data for Disaster Recovery
Before testing disaster recovery, we need to create sample data that we can later restore.

Create a test namespace:
oc new-project dr-test
Create a persistent volume claim:
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: dr-test
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Deploy a test application with data:
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: dr-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: test-container
        image: registry.redhat.io/ubi8/ubi:latest
        command: ["/bin/bash"]
        args: ["-c", "while true; do echo 'Test data at $(date)' >> /data/test-file.txt; sleep 30; done"]
        volumeMounts:
        - name: test-volume
          mountPath: /data
      volumes:
      - name: test-volume
        persistentVolumeClaim:
          claimName: test-pvc
EOF
Verify the application is running:
oc get pods -n dr-test
Check that data is being written:
oc exec -n dr-test deployment/test-app -- cat /data/test-file.txt
Subtask 1.3: Configure Volume Snapshots
Volume snapshots are crucial for disaster recovery. Let's configure and test them.

Check available volume snapshot classes:
oc get volumesnapshotclass
Create a volume snapshot:
cat << EOF | oc apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: test-snapshot
  namespace: dr-test
spec:
  volumeSnapshotClassName: ocs-storagecluster-rbdplugin-snapclass
  source:
    persistentVolumeClaimName: test-pvc
EOF
Monitor snapshot creation:
oc get volumesnapshot -n dr-test -w
Verify snapshot is ready:
oc describe volumesnapshot test-snapshot -n dr-test
Subtask 1.4: Test Backup Strategies
Let's implement and test backup strategies using ODF capabilities.

Install OADP (OpenShift API for Data Protection) operator:
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: redhat-oadp-operator
  namespace: openshift-adp
spec:
  channel: stable-1.3
  installPlanApproval: Automatic
  name: redhat-oadp-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
Wait for operator installation:
oc get csv -n openshift-adp
Create a backup configuration:
cat << EOF | oc apply -f -
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: dpa-sample
  namespace: openshift-adp
spec:
  configuration:
    velero:
      defaultPlugins:
      - openshift
      - aws
      - csi
    restic:
      enable: true
  backupLocations:
  - velero:
      config:
        region: us-east-1
        s3ForcePathStyle: "true"
        s3Url: http://s3.openshift-storage.svc:80
        insecureSkipTLSVerify: "true"
      credential:
        key: cloud
        name: cloud-credentials
      default: true
      objectStorage:
        bucket: backup-bucket
        prefix: velero
      provider: aws
EOF
Create a backup of our test namespace:
cat << EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: dr-test-backup
  namespace: openshift-adp
spec:
  includedNamespaces:
  - dr-test
  storageLocation: default
  ttl: 720h0m0s
EOF
Monitor backup progress:
oc get backup -n openshift-adp
Task 2: Perform Complete Data Restore in Multi-Zone Setup
Subtask 2.1: Simulate Disaster Scenario
Now we'll simulate a disaster by deleting our test data and then restore it.

Record current data state:
oc exec -n dr-test deployment/test-app -- wc -l /data/test-file.txt
Delete the test namespace to simulate disaster:
oc delete project dr-test
Verify namespace is deleted:
oc get project dr-test
Check that PVC is also deleted:
oc get pvc -A | grep test-pvc
Subtask 2.2: Restore from Volume Snapshot
Let's restore our data using the volume snapshot we created earlier.

Recreate the test namespace:
oc new-project dr-test
Restore PVC from snapshot:
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-pvc
  namespace: dr-test
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ocs-storagecluster-ceph-rbd
  dataSource:
    name: test-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF
Deploy application using restored PVC:
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: restored-app
  namespace: dr-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: restored-app
  template:
    metadata:
      labels:
        app: restored-app
    spec:
      containers:
      - name: restored-container
        image: registry.redhat.io/ubi8/ubi:latest
        command: ["/bin/bash"]
        args: ["-c", "while true; do echo 'Restored data at $(date)' >> /data/restored-file.txt; sleep 30; done"]
        volumeMounts:
        - name: restored-volume
          mountPath: /data
      volumes:
      - name: restored-volume
        persistentVolumeClaim:
          claimName: restored-pvc
EOF
Verify restored data:
oc exec -n dr-test deployment/restored-app -- ls -la /data/
oc exec -n dr-test deployment/restored-app -- head -10 /data/test-file.txt
Subtask 2.3: Restore from OADP Backup
Now let's test restoration using OADP backup.

Delete the namespace again:
oc delete project dr-test
Create a restore operation:
cat << EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: dr-test-restore
  namespace: openshift-adp
spec:
  backupName: dr-test-backup
  includedNamespaces:
  - dr-test
EOF
Monitor restore progress:
oc get restore -n openshift-adp
oc describe restore dr-test-restore -n openshift-adp
Verify namespace and resources are restored:
oc get project dr-test
oc get all -n dr-test
oc get pvc -n dr-test
Subtask 2.4: Test Multi-Zone Recovery
Let's test recovery across multiple zones by simulating zone failure.

Check current zone distribution:
oc get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.'topology\.kubernetes\.io/zone'
Identify storage nodes in different zones:
oc get nodes -l cluster.ocs.openshift.io/openshift-storage='' -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.'topology\.kubernetes\.io/zone'
Check Ceph OSD distribution:
oc rsh -n openshift-storage deployment/rook-ceph-tools
ceph osd tree
exit
Simulate zone failure by cordoning nodes:
# Get nodes in zone-a (replace with actual zone name from your environment)
ZONE_A_NODES=$(oc get nodes -l topology.kubernetes.io/zone=zone-a -o jsonpath='{.items[*].metadata.name}')
for node in $ZONE_A_NODES; do
  oc adm cordon $node
done
Monitor cluster recovery:
oc get cephcluster -n openshift-storage -w
Check data accessibility during zone failure:
oc exec -n dr-test deployment/restored-app -- cat /data/test-file.txt | tail -5
Uncordon nodes to restore full capacity:
for node in $ZONE_A_NODES; do
  oc adm uncordon $node
done
Task 3: Monitor Recovery Status and Validate Data Consistency
Subtask 3.1: Monitor Ceph Cluster Health
Monitoring is crucial during disaster recovery operations.

Access Ceph tools pod:
oc rsh -n openshift-storage deployment/rook-ceph-tools
Check overall cluster health:
ceph status
ceph health detail
Monitor OSD status:
ceph osd status
ceph osd df
Check placement group status:
ceph pg stat
ceph pg dump | grep -v "^pg_stat"
Exit the tools pod:
exit
Subtask 3.2: Validate Storage Performance
After recovery, we need to ensure storage performance is acceptable.

Create a performance test pod:
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: storage-test
  namespace: dr-test
spec:
  containers:
  - name: storage-test
    image: registry.redhat.io/ubi8/ubi:latest
    command: ["/bin/bash"]
    args: ["-c", "sleep 3600"]
    volumeMounts:
    - name: test-volume
      mountPath: /test
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: restored-pvc
EOF
Run write performance test:
oc exec -n dr-test storage-test -- dd if=/dev/zero of=/test/write-test bs=1M count=100 oflag=direct
Run read performance test:
oc exec -n dr-test storage-test -- dd if=/test/write-test of=/dev/null bs=1M iflag=direct
Test random I/O performance:
oc exec -n dr-test storage-test -- bash -c "for i in {1..10}; do dd if=/dev/urandom of=/test/random-\$i bs=1M count=10 oflag=direct; done"
Subtask 3.3: Validate Data Consistency
Data consistency validation is critical after disaster recovery.

Create checksum of original data:
oc exec -n dr-test deployment/restored-app -- md5sum /data/test-file.txt
Create a data validation script:
cat << 'EOF' | oc exec -i -n dr-test deployment/restored-app -- tee /tmp/validate.sh
#!/bin/bash
echo "Starting data consistency validation..."

# Check file integrity
if [ -f /data/test-file.txt ]; then
    echo "✓ Original test file exists"
    LINE_COUNT=$(wc -l < /data/test-file.txt)
    echo "✓ File contains $LINE_COUNT lines"
else
    echo "✗ Original test file missing"
    exit 1
fi

# Check for data corruption
if grep -q "Test data at" /data/test-file.txt; then
    echo "✓ Data format is correct"
else
    echo "✗ Data format appears corrupted"
    exit 1
fi

# Check timestamp consistency
FIRST_LINE=$(head -1 /data/test-file.txt)
LAST_LINE=$(tail -1 /data/test-file.txt)
echo "First entry: $FIRST_LINE"
echo "Last entry: $LAST_LINE"

echo "Data consistency validation completed successfully!"
EOF
Run validation script:
oc exec -n dr-test deployment/restored-app -- chmod +x /tmp/validate.sh
oc exec -n dr-test deployment/restored-app -- /tmp/validate.sh
Compare data before and after recovery:
# Create a comparison report
oc exec -n dr-test deployment/restored-app -- bash -c "
echo 'Data Recovery Report'
echo '==================='
echo 'Total lines in recovered file:' \$(wc -l < /data/test-file.txt)
echo 'File size:' \$(du -h /data/test-file.txt | cut -f1)
echo 'Last 5 entries:'
tail -5 /data/test-file.txt
"
Subtask 3.4: Monitor Recovery Metrics
Let's check various metrics to ensure the recovery was successful.

Check PVC status and usage:
oc get pvc -n dr-test
oc describe pvc restored-pvc -n dr-test
Monitor storage utilization:
oc rsh -n openshift-storage deployment/rook-ceph-tools
ceph df
ceph osd pool stats
exit
Check application logs for errors:
oc logs -n dr-test deployment/restored-app --tail=20
Verify backup and restore operations:
oc get backup -n openshift-adp
oc get restore -n openshift-adp
oc describe restore dr-test-restore -n openshift-adp
Create a final recovery status report:
cat << 'EOF' > recovery-report.sh
#!/bin/bash
echo "=== Disaster Recovery Test Report ==="
echo "Date: $(date)"
echo ""

echo "1. Cluster Health:"
oc get cephcluster -n openshift-storage -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,HEALTH:.status.ceph.health

echo ""
echo "2. Storage Nodes:"
oc get nodes -l cluster.ocs.openshift.io/openshift-storage='' --no-headers | wc -l | xargs echo "Active storage nodes:"

echo ""
echo "3. Restored Resources:"
echo "Namespaces: $(oc get project dr-test --no-headers | wc -l)"
echo "PVCs: $(oc get pvc -n dr-test --no-headers | wc -l)"
echo "Deployments: $(oc get deployment -n dr-test --no-headers | wc -l)"

echo ""
echo "4. Data Validation:"
if oc exec -n dr-test deployment/restored-app -- test -f /data/test-file.txt; then
    echo "✓ Data file exists and is accessible"
    echo "File size: $(oc exec -n dr-test deployment/restored-app -- du -h /data/test-file.txt | cut -f1)"
else
    echo "✗ Data file not found or inaccessible"
fi

echo ""
echo "=== Recovery Test Completed ==="
EOF

chmod +x recovery-report.sh
./recovery-report.sh
Troubleshooting Common Issues
Issue 1: Snapshot Creation Fails
Symptoms: VolumeSnapshot remains in "Pending" state

Solution:

# Check snapshot class
oc get volumesnapshotclass
oc describe volumesnapshotclass ocs-storagecluster-rbdplugin-snapclass

# Check CSI driver
oc get pods -n openshift-storage | grep csi
Issue 2: Backup Fails
Symptoms: OADP backup shows "Failed" status

Solution:

# Check OADP operator logs
oc logs -n openshift-adp deployment/velero

# Verify backup location configuration
oc describe backupstoragelocation -n openshift-adp
Issue 3: Restore Takes Too Long
Symptoms: Restore operation appears stuck

Solution:

# Check restore logs
oc describe restore dr-test-restore -n openshift-adp

# Monitor Ceph recovery
oc rsh -n openshift-storage deployment/rook-ceph-tools
ceph -w
Issue 4: Data Inconsistency After Recovery
Symptoms: Restored data appears corrupted or incomplete

Solution:

# Check PV and PVC binding
oc get pv,pvc -n dr-test

# Verify storage class configuration
oc describe storageclass ocs-storagecluster-ceph-rbd

# Check Ceph pool health
oc rsh -n openshift-storage deployment/rook-ceph-tools
ceph health detail
Cleanup
After completing the lab, clean up the resources:

# Delete test namespace
oc delete project dr-test

# Delete snapshots
oc delete volumesnapshot --all -A

# Delete backups and restores
oc delete backup --all -n openshift-adp
oc delete restore --all -n openshift-adp

# Remove test files
rm -f recovery-report.sh
Conclusion
In this comprehensive lab, you have successfully:

Implemented disaster recovery strategies for OpenShift Data Foundation, learning how to protect critical data using multiple approaches including volume snapshots and OADP backups
Performed complete data restoration in a multi-zone environment, demonstrating the ability to recover from various disaster scenarios including zone failures
Monitored recovery operations and validated data consistency, ensuring that restored data maintains integrity and applications function correctly post-recovery
Why This Matters: Disaster recovery is a critical aspect of enterprise storage management. In real-world scenarios, organizations depend on robust disaster recovery capabilities to:

Minimize downtime during system failures or natural disasters
Protect business-critical data from loss or corruption
Meet compliance requirements for data protection and business continuity
Maintain customer trust by ensuring service availability
The skills you've developed in this lab are directly applicable to production environments where data protection and business continuity are paramount. You now understand how to implement, test, and validate disaster recovery procedures using OpenShift Data Foundation, making you better prepared for the Red Hat Certified Specialist in OpenShift Data Foundation exam and real-world storage administration challenges.

Key Takeaways:

Always test your disaster recovery procedures regularly
Multiple backup strategies provide better protection than single approaches
Monitoring and validation are as important as the recovery process itself
Multi-zone deployments provide resilience against localized failures
Documentation and automation of recovery procedures reduce recovery time and human error
