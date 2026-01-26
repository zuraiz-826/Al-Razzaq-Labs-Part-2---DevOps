Lab 10: Data Protection: Backup and Restore PVCs
Objectives
By the end of this lab, students will be able to:

Understand the importance of data protection in OpenShift Data Foundation (ODF)
Create and manage volume snapshots for PVC backup
Implement PVC cloning for data replication
Restore PVCs from snapshots and backups
Configure external backup solutions with ODF
Implement best practices for data protection strategies
Prerequisites
Before starting this lab, students should have:

Basic understanding of Kubernetes and OpenShift concepts
Familiarity with Persistent Volumes (PV) and Persistent Volume Claims (PVC)
Knowledge of OpenShift Data Foundation fundamentals
Experience with command-line interface (CLI) operations
Understanding of YAML configuration files
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and ODF already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

OpenShift cluster with ODF installed
Pre-configured storage classes
Command-line tools (oc, kubectl)
Sample applications for testing
Task 1: Use Snapshots and Clones for Backup
Subtask 1.1: Verify ODF Installation and Storage Classes
First, let's verify that ODF is properly installed and check available storage classes.

# Check ODF operator status
oc get csv -n openshift-storage | grep odf

# List available storage classes
oc get storageclass

# Check if snapshot classes are available
oc get volumesnapshotclass
Subtask 1.2: Create a Sample Application with Data
Create a sample application that will generate data for our backup scenarios.

# Create a new project for our lab
oc new-project data-protection-lab

# Create a PVC for our sample application
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sample-data-pvc
  namespace: data-protection-lab
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
# Create a sample pod that writes data to the PVC
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: data-writer
  namespace: data-protection-lab
spec:
  containers:
  - name: writer
    image: registry.redhat.io/ubi8/ubi:latest
    command:
      - /bin/bash
      - -c
      - |
        echo "Creating initial data..." > /data/initial-data.txt
        echo "Timestamp: $(date)" >> /data/initial-data.txt
        for i in {1..100}; do
          echo "Sample data line $i" >> /data/sample-data.txt
        done
        echo "Data creation completed"
        sleep 3600
    volumeMounts:
    - name: data-volume
      mountPath: /data
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: sample-data-pvc
  restartPolicy: Never
EOF
Subtask 1.3: Create Volume Snapshots
Now let's create snapshots of our PVC for backup purposes.

# Wait for the pod to create data
oc wait --for=condition=Ready pod/data-writer -n data-protection-lab --timeout=300s

# Verify data was created
oc exec data-writer -n data-protection-lab -- ls -la /data/
oc exec data-writer -n data-protection-lab -- head -5 /data/sample-data.txt
# Create a volume snapshot
cat << EOF | oc apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: sample-data-snapshot-1
  namespace: data-protection-lab
spec:
  volumeSnapshotClassName: ocs-storagecluster-rbdplugin-snapclass
  source:
    persistentVolumeClaimName: sample-data-pvc
EOF
# Check snapshot status
oc get volumesnapshot -n data-protection-lab
oc describe volumesnapshot sample-data-snapshot-1 -n data-protection-lab
Subtask 1.4: Create PVC Clones
Create clones of the PVC for additional backup scenarios.

# Create a clone of the original PVC
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sample-data-clone
  namespace: data-protection-lab
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: ocs-storagecluster-ceph-rbd
  dataSource:
    kind: PersistentVolumeClaim
    name: sample-data-pvc
EOF
# Verify the clone was created successfully
oc get pvc -n data-protection-lab
oc describe pvc sample-data-clone -n data-protection-lab
Subtask 1.5: Test Clone Data Integrity
Verify that the cloned PVC contains the same data as the original.

# Create a pod to verify clone data
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: clone-verifier
  namespace: data-protection-lab
spec:
  containers:
  - name: verifier
    image: registry.redhat.io/ubi8/ubi:latest
    command:
      - /bin/bash
      - -c
      - |
        echo "Verifying clone data..."
        ls -la /data/
        echo "First 5 lines of sample-data.txt:"
        head -5 /data/sample-data.txt
        echo "Last 5 lines of sample-data.txt:"
        tail -5 /data/sample-data.txt
        sleep 3600
    volumeMounts:
    - name: clone-volume
      mountPath: /data
  volumes:
  - name: clone-volume
    persistentVolumeClaim:
      claimName: sample-data-clone
  restartPolicy: Never
EOF
Task 2: Restore PVCs from Backups
Subtask 2.1: Simulate Data Loss
Let's simulate data loss by modifying the original data.

# Modify data in the original PVC to simulate corruption/loss
oc exec data-writer -n data-protection-lab -- bash -c "echo 'CORRUPTED DATA' > /data/sample-data.txt"
oc exec data-writer -n data-protection-lab -- bash -c "rm -f /data/initial-data.txt"

# Verify the data loss
oc exec data-writer -n data-protection-lab -- ls -la /data/
oc exec data-writer -n data-protection-lab -- cat /data/sample-data.txt
Subtask 2.2: Restore from Volume Snapshot
Create a new PVC from the snapshot to restore the data.

# Create a new PVC from the snapshot
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-from-snapshot
  namespace: data-protection-lab
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: ocs-storagecluster-ceph-rbd
  dataSource:
    kind: VolumeSnapshot
    name: sample-data-snapshot-1
    apiGroup: snapshot.storage.k8s.io
EOF
# Verify the restored PVC
oc get pvc restored-from-snapshot -n data-protection-lab
oc describe pvc restored-from-snapshot -n data-protection-lab
Subtask 2.3: Verify Restored Data
Create a pod to verify that the restored data is intact.

# Create a pod to verify restored data
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: restore-verifier
  namespace: data-protection-lab
spec:
  containers:
  - name: verifier
    image: registry.redhat.io/ubi8/ubi:latest
    command:
      - /bin/bash
      - -c
      - |
        echo "Verifying restored data..."
        ls -la /data/
        echo "Checking initial-data.txt:"
        cat /data/initial-data.txt
        echo "First 10 lines of sample-data.txt:"
        head -10 /data/sample-data.txt
        echo "Data restoration verification completed"
        sleep 3600
    volumeMounts:
    - name: restored-volume
      mountPath: /data
  volumes:
  - name: restored-volume
    persistentVolumeClaim:
      claimName: restored-from-snapshot
  restartPolicy: Never
EOF
Subtask 2.4: Create Scheduled Snapshots
Implement automated backup using scheduled snapshots.

# Create a snapshot schedule using a CronJob
cat << EOF | oc apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scheduled-snapshot
  namespace: data-protection-lab
spec:
  schedule: "0 */6 * * *"  # Every 6 hours
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: snapshot-creator
            image: registry.redhat.io/ubi8/ubi:latest
            command:
            - /bin/bash
            - -c
            - |
              TIMESTAMP=$(date +%Y%m%d-%H%M%S)
              cat << SNAPSHOT_EOF | oc apply -f -
              apiVersion: snapshot.storage.k8s.io/v1
              kind: VolumeSnapshot
              metadata:
                name: scheduled-snapshot-\$TIMESTAMP
                namespace: data-protection-lab
              spec:
                volumeSnapshotClassName: ocs-storagecluster-rbdplugin-snapclass
                source:
                  persistentVolumeClaimName: sample-data-pvc
              SNAPSHOT_EOF
          restartPolicy: OnFailure
          serviceAccountName: snapshot-creator
EOF
# Create service account and RBAC for the CronJob
cat << EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: snapshot-creator
  namespace: data-protection-lab
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: snapshot-creator
  namespace: data-protection-lab
rules:
- apiGroups: ["snapshot.storage.k8s.io"]
  resources: ["volumesnapshots"]
  verbs: ["create", "get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: snapshot-creator
  namespace: data-protection-lab
subjects:
- kind: ServiceAccount
  name: snapshot-creator
  namespace: data-protection-lab
roleRef:
  kind: Role
  name: snapshot-creator
  apiGroup: rbac.authorization.k8s.io
EOF
Task 3: Integrate ODF with External Backup Solutions
Subtask 3.1: Install and Configure Velero
Velero is a popular open-source backup solution for Kubernetes clusters.

# Download and install Velero CLI
curl -L https://github.com/vmware-tanzu/velero/releases/latest/download/velero-linux-amd64.tar.gz -o velero.tar.gz
tar -xzf velero.tar.gz
sudo mv velero-*/velero /usr/local/bin/
velero version --client-only
# Create credentials file for MinIO (as backup storage)
cat << EOF > credentials-velero
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
EOF
# Install Velero with MinIO backend
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.8.0 \
    --bucket velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=true \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000 \
    --snapshot-location-config region=minio
Subtask 3.2: Deploy MinIO for Backup Storage
Deploy MinIO as an S3-compatible storage backend for Velero.

# Create MinIO namespace
oc new-project velero

# Deploy MinIO
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: velero
spec:
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: minio/minio:latest
        args:
        - server
        - /storage
        - --console-address
        - ":9001"
        env:
        - name: MINIO_ACCESS_KEY
          value: "minio"
        - name: MINIO_SECRET_KEY
          value: "minio123"
        ports:
        - containerPort: 9000
        - containerPort: 9001
        volumeMounts:
        - name: storage
          mountPath: "/storage"
      volumes:
      - name: storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: velero
spec:
  ports:
  - port: 9000
    targetPort: 9000
    protocol: TCP
  selector:
    app: minio
EOF
# Create the velero bucket in MinIO
oc exec -n velero deployment/minio -- mc config host add myminio http://localhost:9000 minio minio123
oc exec -n velero deployment/minio -- mc mb myminio/velero
Subtask 3.3: Create Application Backup with Velero
Create a comprehensive backup of our application and data.

# Create a backup of the entire namespace
velero backup create data-protection-backup \
    --include-namespaces data-protection-lab \
    --storage-location default \
    --volume-snapshot-locations default

# Check backup status
velero backup describe data-protection-backup
velero backup get
Subtask 3.4: Simulate Disaster and Restore
Simulate a disaster scenario and restore from the external backup.

# Delete the entire namespace to simulate disaster
oc delete project data-protection-lab

# Verify the namespace is gone
oc get projects | grep data-protection-lab
# Restore from Velero backup
velero restore create data-protection-restore \
    --from-backup data-protection-backup

# Check restore status
velero restore describe data-protection-restore
velero restore get
# Verify restoration
oc get projects | grep data-protection-lab
oc get all -n data-protection-lab
oc get pvc -n data-protection-lab
Subtask 3.5: Verify Data Integrity After Restore
Check that all data was properly restored from the external backup.

# Wait for pods to be ready
oc wait --for=condition=Ready pod --all -n data-protection-lab --timeout=300s

# Verify data in restored PVCs
oc exec data-writer -n data-protection-lab -- ls -la /data/
oc exec data-writer -n data-protection-lab -- head -5 /data/sample-data.txt
Subtask 3.6: Configure Backup Retention Policies
Set up retention policies to manage backup storage efficiently.

# Create a backup with retention policy
velero backup create data-protection-backup-with-retention \
    --include-namespaces data-protection-lab \
    --ttl 720h0m0s  # 30 days retention

# Create a schedule for regular backups
velero schedule create daily-backup \
    --schedule="0 2 * * *" \
    --include-namespaces data-protection-lab \
    --ttl 168h0m0s  # 7 days retention
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Snapshot Creation Fails

# Check if snapshot class exists
oc get volumesnapshotclass

# Verify CSI driver is running
oc get pods -n openshift-storage | grep csi
Issue 2: PVC Clone Stuck in Pending

# Check storage class supports cloning
oc describe storageclass ocs-storagecluster-ceph-rbd

# Verify source PVC is bound
oc get pvc sample-data-pvc -n data-protection-lab
Issue 3: Velero Backup Fails

# Check Velero pod logs
oc logs -n velero deployment/velero

# Verify backup location configuration
velero backup-location get
Issue 4: Restore from Snapshot Fails

# Check snapshot content
oc get volumesnapshotcontent

# Verify snapshot is ready
oc describe volumesnapshot sample-data-snapshot-1 -n data-protection-lab
Lab Cleanup
Clean up the lab environment when finished.

# Delete the lab project
oc delete project data-protection-lab

# Uninstall Velero
velero uninstall

# Delete Velero namespace
oc delete project velero

# Remove Velero CLI and credentials
rm -f /usr/local/bin/velero
rm -f credentials-velero velero.tar.gz
Conclusion
In this comprehensive lab, you have successfully:

Implemented Volume Snapshots: Created point-in-time snapshots of PVCs for backup purposes, providing a quick and efficient way to protect data within the OpenShift cluster.

Mastered PVC Cloning: Learned how to create exact copies of PVCs, enabling data replication and testing scenarios without affecting production data.

Performed Data Restoration: Successfully restored data from snapshots after simulating data loss, demonstrating the effectiveness of snapshot-based backup strategies.

Integrated External Backup Solutions: Deployed and configured Velero with MinIO to create comprehensive backup solutions that protect against cluster-wide disasters.

Implemented Automation: Created scheduled snapshots and backup policies to ensure consistent data protection without manual intervention.

Validated Data Integrity: Verified that restored data maintains its integrity across different backup and restore scenarios.

Why This Matters: Data protection is critical in production environments where data loss can result in significant business impact. The skills learned in this lab provide multiple layers of data protection, from quick snapshot-based recovery to comprehensive disaster recovery using external backup solutions. Understanding these concepts is essential for the Red Hat Certified Specialist in OpenShift Data Foundation exam and real-world OpenShift operations.

The combination of ODF's native snapshot capabilities with external backup solutions like Velero provides a robust data protection strategy that can handle various failure scenarios, from simple data corruption to complete cluster disasters.
