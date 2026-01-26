Lab 9: Troubleshooting ODF Storage Issues
Objectives
By the end of this lab, you will be able to:

Diagnose and troubleshoot common PVC provisioning issues in OpenShift Data Foundation (ODF)
Utilize OpenShift logs and metrics to identify storage-related failures
Apply systematic troubleshooting methodologies to resolve storage problems
Validate fixes and ensure proper storage functionality
Understand common ODF storage failure patterns and their root causes
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes storage concepts (PVs, PVCs, StorageClasses)
Familiarity with OpenShift CLI (oc) commands
Knowledge of YAML file structure and editing
Understanding of container and pod concepts
Basic Linux command line skills
Completed previous ODF labs or equivalent experience
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and ODF already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

OpenShift cluster with ODF installed
Pre-configured storage classes
Monitoring and logging tools
Sample applications for testing
Task 1: Diagnose Issues with PVC Provisioning
Subtask 1.1: Create a Problematic PVC Scenario
First, let's create a scenario where PVC provisioning fails so we can practice troubleshooting.

Access your lab environment and open a terminal

Login to OpenShift using the provided credentials:

oc login -u admin -p admin123 https://api.cluster.local:6443
Create a new project for our troubleshooting exercises:
oc new-project storage-troubleshooting
Create a PVC with an invalid storage class to simulate a common issue:
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: problematic-pvc
  namespace: storage-troubleshooting
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: non-existent-storage-class
EOF
Create another PVC with excessive storage request:
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: oversized-pvc
  namespace: storage-troubleshooting
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1000Ti
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Subtask 1.2: Identify PVC Status Issues
Check the status of all PVCs in the namespace:
oc get pvc -n storage-troubleshooting
Examine detailed information about the problematic PVC:
oc describe pvc problematic-pvc -n storage-troubleshooting
Look for events related to the PVC:
oc get events -n storage-troubleshooting --sort-by='.lastTimestamp'
Check available storage classes:
oc get storageclass
Subtask 1.3: Analyze Storage Class Configuration
Examine the ODF storage classes in detail:
oc describe storageclass ocs-storagecluster-ceph-rbd
Check if the storage class provisioner is running:
oc get pods -n openshift-storage | grep provisioner
Verify ODF operator status:
oc get csv -n openshift-storage
Task 2: Use OpenShift Logs and Metrics to Identify Storage Failures
Subtask 2.1: Examine Container and Pod Logs
Create a pod that uses the problematic PVC:
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-with-pvc
  namespace: storage-troubleshooting
spec:
  containers:
  - name: test-container
    image: registry.redhat.io/ubi8/ubi:latest
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo 'Waiting for storage...'; sleep 30; done"]
    volumeMounts:
    - name: test-volume
      mountPath: /data
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: problematic-pvc
  restartPolicy: Never
EOF
Check the pod status:
oc get pods -n storage-troubleshooting
Examine pod events and logs:
oc describe pod test-pod-with-pvc -n storage-troubleshooting
Check ODF operator logs:
oc logs -n openshift-storage deployment/ocs-operator
Examine Ceph cluster logs:
oc logs -n openshift-storage -l app=rook-ceph-operator
Subtask 2.2: Use OpenShift Monitoring and Metrics
Access the OpenShift web console using the provided URL and credentials

Navigate to Monitoring > Metrics in the web console

Query storage-related metrics using PromQL:

# Check PVC status
kube_persistentvolumeclaim_status_phase

# Monitor storage capacity
kubelet_volume_stats_capacity_bytes

# Check storage provisioner errors
increase(storage_operation_errors_total[5m])
Use CLI to query metrics:
# Get storage cluster health
oc get cephcluster -n openshift-storage

# Check storage cluster status
oc get storagecluster -n openshift-storage

# Examine ODF dashboard metrics
oc get cephblockpool -n openshift-storage
Subtask 2.3: Analyze Storage System Health
Check Ceph cluster health:
oc rsh -n openshift-storage deployment/rook-ceph-tools
Inside the Ceph tools pod, run:

ceph status
ceph health detail
ceph osd status
exit
Examine storage node status:
oc get nodes -l cluster.ocs.openshift.io/openshift-storage=''
Check storage device status:
oc get localvolume -n openshift-local-storage
Task 3: Fix and Validate Identified Issues
Subtask 3.1: Fix PVC Provisioning Issues
Delete the problematic pod and PVC:
oc delete pod test-pod-with-pvc -n storage-troubleshooting
oc delete pvc problematic-pvc -n storage-troubleshooting
Create a corrected PVC with valid storage class:
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fixed-pvc
  namespace: storage-troubleshooting
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Verify the PVC is now bound:
oc get pvc fixed-pvc -n storage-troubleshooting
Fix the oversized PVC by reducing storage request:
oc delete pvc oversized-pvc -n storage-troubleshooting

cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: reasonable-pvc
  namespace: storage-troubleshooting
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Subtask 3.2: Resolve Storage System Issues
If Ceph cluster shows health warnings, check for common issues:
# Check if all OSDs are up
oc rsh -n openshift-storage deployment/rook-ceph-tools ceph osd tree

# Verify placement groups
oc rsh -n openshift-storage deployment/rook-ceph-tools ceph pg stat
Restart ODF components if necessary:
# Restart OCS operator
oc rollout restart deployment/ocs-operator -n openshift-storage

# Restart Rook operator
oc rollout restart deployment/rook-ceph-operator -n openshift-storage
Scale down and up problematic components:
# Scale down CSI provisioner
oc scale deployment csi-rbdplugin-provisioner --replicas=0 -n openshift-storage

# Wait a moment, then scale back up
sleep 30
oc scale deployment csi-rbdplugin-provisioner --replicas=2 -n openshift-storage
Subtask 3.3: Validate Fixes and Test Storage Functionality
Create a test application to validate storage works:
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storage-test-app
  namespace: storage-troubleshooting
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storage-test
  template:
    metadata:
      labels:
        app: storage-test
    spec:
      containers:
      - name: test-container
        image: registry.redhat.io/ubi8/ubi:latest
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo 'Testing storage at $(date)' >> /data/test.log; cat /data/test.log | tail -5; sleep 60; done"]
        volumeMounts:
        - name: test-storage
          mountPath: /data
      volumes:
      - name: test-storage
        persistentVolumeClaim:
          claimName: fixed-pvc
EOF
Verify the application is running:
oc get pods -n storage-troubleshooting -l app=storage-test
Check that data is being written to storage:
# Get the pod name
POD_NAME=$(oc get pods -n storage-troubleshooting -l app=storage-test -o jsonpath='{.items[0].metadata.name}')

# Check the log file content
oc exec -n storage-troubleshooting $POD_NAME -- cat /data/test.log
Test storage persistence by deleting and recreating the pod:
oc delete pod $POD_NAME -n storage-troubleshooting

# Wait for new pod to start
sleep 30

# Get new pod name
NEW_POD_NAME=$(oc get pods -n storage-troubleshooting -l app=storage-test -o jsonpath='{.items[0].metadata.name}')

# Verify data persisted
oc exec -n storage-troubleshooting $NEW_POD_NAME -- cat /data/test.log
Subtask 3.4: Create Monitoring and Alerting
Create a custom alert for storage issues:
cat << EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: storage-troubleshooting-alerts
  namespace: storage-troubleshooting
spec:
  groups:
  - name: storage.rules
    rules:
    - alert: PVCPendingTooLong
      expr: kube_persistentvolumeclaim_status_phase{phase="Pending"} == 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "PVC has been pending for too long"
        description: "PVC {{ \$labels.persistentvolumeclaim }} in namespace {{ \$labels.namespace }} has been pending for more than 5 minutes"
EOF
Verify monitoring is working:
# Check if the PrometheusRule was created
oc get prometheusrule -n storage-troubleshooting

# Query the metric directly
oc exec -n openshift-monitoring prometheus-k8s-0 -- promtool query instant 'kube_persistentvolumeclaim_status_phase'
Troubleshooting Tips
Common Issues and Solutions
Issue: PVC stuck in Pending state

Solution: Check storage class exists and provisioner is running
Command: oc get storageclass and oc get pods -n openshift-storage
Issue: Storage provisioner not responding

Solution: Restart CSI provisioner pods
Command: oc delete pods -n openshift-storage -l app=csi-rbdplugin-provisioner
Issue: Ceph cluster unhealthy

Solution: Check OSD status and restart if necessary
Command: oc rsh -n openshift-storage deployment/rook-ceph-tools ceph health detail
Issue: Node storage full

Solution: Clean up unused PVs or add more storage nodes
Command: oc get pv | grep Available
Best Practices for Storage Troubleshooting
Always check events first: oc get events --sort-by='.lastTimestamp'
Examine logs systematically: Start with application logs, then storage system logs
Use metrics for trend analysis: Monitor storage usage over time
Test fixes incrementally: Make one change at a time and validate
Document solutions: Keep track of what worked for future reference
Conclusion
In this lab, you have successfully learned how to troubleshoot common OpenShift Data Foundation storage issues. You practiced:

Diagnosing PVC provisioning problems by examining PVC status, events, and storage class configurations
Using OpenShift logs and metrics to identify root causes of storage failures through systematic analysis of operator logs, Ceph cluster status, and monitoring data
Implementing fixes for storage issues including correcting PVC configurations, restarting storage components, and validating solutions
Creating monitoring and alerting to proactively detect future storage problems
These troubleshooting skills are essential for maintaining reliable storage systems in production OpenShift environments. The systematic approach you learned - from problem identification through validation - will help you resolve storage issues efficiently and prevent similar problems in the future.

Understanding how to troubleshoot ODF storage issues is crucial for the Red Hat Certified Specialist in OpenShift Data Foundation exam and for real-world OpenShift administration. The hands-on experience gained in this lab provides you with practical skills that directly apply to production environments where storage reliability is critical for application availability.
